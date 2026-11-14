"""Mesin spoof (dipindah dari app.py web v9, tanpa ikatan ke request web)."""
import asyncio
import json
import os
import re
import shutil
import time
from datetime import datetime, timedelta, timezone

import logging

import aiohttp

from utils import roblox as rbx

import config, store

# ── Koneksi bersama ──
_CONNECTOR = None

def _connector() -> aiohttp.TCPConnector:
    global _CONNECTOR
    if _CONNECTOR is None or _CONNECTOR.closed:
        _CONNECTOR = aiohttp.TCPConnector(limit=100, limit_per_host=30, ttl_dns_cache=300, enable_cleanup_closed=True)
    return _CONNECTOR

def make_session() -> aiohttp.ClientSession:
    return aiohttp.ClientSession(connector=_connector(), connector_owner=False)

async def shutdown():
    if _CONNECTOR is not None and not _CONNECTOR.closed:
        await _CONNECTOR.close()

# ── 1 proses per user ──
BUSY = set()

def try_lock(uid: str) -> bool:
    if uid in BUSY:
        return False
    BUSY.add(uid)
    return True

def unlock(uid: str) -> None:
    BUSY.discard(uid)

# ── Cache place ID ──
_DEFAULT_SEEDS = [76077593225337, 119031818630096, 131528987147518, 125981614068947, 112742012181598]
_PLACE_LOCK = asyncio.Lock()

def _load_place_cache() -> list:
    cache = list(_DEFAULT_SEEDS)
    try:
        with open(config.PLACE_CACHE_FILE, 'r') as f:
            data = json.load(f)
        if isinstance(data, list):
            cache += [x for x in data if x not in cache]
    except Exception:
        pass
    return cache

_PLACE_CACHE = _load_place_cache()

async def _add_place_cache(place_id: int) -> None:
    async with _PLACE_LOCK:
        if place_id in _PLACE_CACHE:
            return
        _PLACE_CACHE.append(place_id)
        try:
            tmp = config.PLACE_CACHE_FILE + '.tmp'
            with open(tmp, 'w') as f:
                json.dump(_PLACE_CACHE, f)
            os.replace(tmp, config.PLACE_CACHE_FILE)
        except Exception:
            pass

# ── Util ──
KIND_EXT = {
    'Audio': {'mp3', 'ogg', 'wav'},
    'Decal': {'png', 'jpg', 'jpeg', 'gif', 'webp'},
    'Model': {'rbxm'},
    'Animation': {'rbxm'},
}
ASSET_TYPE_IDS = {1: 'Image', 3: 'Audio', 4: 'Mesh', 9: 'Place', 10: 'Model', 13: 'Decal', 24: 'Animation',
                  38: 'Plugin', 40: 'MeshPart', 62: 'Video'}
INFO_SEM = asyncio.Semaphore(3)
OP_RE = re.compile(r'^[A-Za-z0-9_\-]{6,120}$')

def parse_ids(text) -> list:
    out = []
    for tok in re.split(r'[\s,;]+', str(text or '')):
        tok = re.sub(r'^rbxassetid://', '', tok.strip(), flags=re.I)
        if tok.isdigit() and len(tok) <= 19:
            out.append(tok)
    return list(dict.fromkeys(out))

def _wib_stamp() -> str:
    return (datetime.now(timezone.utc) + timedelta(hours=7)).strftime('%Y%m%d-%H%M%S')

def result_filename() -> str:
    return f'hasil-spoof-massal-{_wib_stamp()}.txt'

def build_txt(rows: list):
    lines = [f"Id lama : {r['id']} id baru : {r['new_id']}"
             for r in rows if r.get('ok') and str(r.get('new_id', '')).isdigit() and str(r.get('id', '')).isdigit()]
    return ('\n'.join(lines) + '\n' if lines else ''), len(lines)

def build_failed_txt(rows: list):
    lines = []
    for r in rows:
        if r.get('ok') and str(r.get('new_id', '')).isdigit():
            continue
        if r.get('ok') and r.get('new_id') == 'pending':
            lines.append(f"{r['id']} : masih diproses/moderasi Roblox (operation {r.get('op', '?')})")
        else:
            lines.append(f"{r['id']} : {r.get('error') or 'gagal'}")
    return ('\n'.join(lines) + '\n' if lines else ''), len(lines)

# ── Download ──
async def plain_download(session, aid, save_dir):
    result = await rbx.download_asset(session, aid, save_dir, cookie=config.COOKIE, cached_place_ids=list(_PLACE_CACHE))
    if result.get('place_id'):
        await _add_place_cache(result['place_id'])
    info = result.get('asset_info') or {}
    if not result['success']:
        return None, info, result['error']
    return result['file_path'], info, None

async def asset_info(aid: str) -> dict:
    async with make_session() as s:
        return await rbx.fetch_asset_info(s, aid, config.COOKIE)

# ── Upload ──
async def _upload_with_retry(s, path, key, cfg, asset_name, info_type, description=''):
    up = None
    for attempt in range(1, config.UPLOAD_RETRY_MAX + 1):
        up = await rbx.upload_to_open_cloud(
            s, path, key, cfg['target_id'], cfg.get('target_type', 'user'),
            asset_name=asset_name, description=description, info_type=info_type)
        if up['success']:
            return up
        err = up.get('error', '')
        if attempt < config.UPLOAD_RETRY_MAX and ('429' in err or '500' in err or '503' in err or 'rate' in err.lower()):
            await asyncio.sleep(config.UPLOAD_RETRY_DELAY * attempt)
            continue
        return up
    return up

async def _economy_type(s, aid):
    try:
        async with s.get(f'https://economy.roblox.com/v1/assets/{aid}/details', headers=rbx.make_headers(config.COOKIE),
                         timeout=aiohttp.ClientTimeout(total=10)) as r:
            if r.status == 429:
                try:
                    await asyncio.sleep(min(float(r.headers.get('Retry-After') or 3), 10))
                except ValueError:
                    await asyncio.sleep(3)
                return None, None
            if r.status != 200:
                return None, None
            d = await r.json(content_type=None)
            return ASSET_TYPE_IDS.get(d.get('AssetTypeId')), d.get('Name')
    except Exception:
        return None, None

async def _ensure_info_type(s, aid, info, tries=4):
    for i in range(tries):
        if info.get('type') not in (None, '', 'Asset'):
            return info
        if i:
            await asyncio.sleep(1.5 * i)
        async with INFO_SEM:
            t, name = await _economy_type(s, aid)
        if t:
            info['type'] = t
            if name and (not info.get('name') or info['name'] == aid):
                info['name'] = name
    return info

async def op_check(s, op_id, key):
    op_id = str(op_id).strip().split('/')[-1]
    if not OP_RE.match(op_id):
        return {'state': 'fail', 'error': 'Operation ID tidak valid.'}
    url = f'https://apis.roblox.com/assets/v1/operations/{op_id}'
    try:
        async with s.get(url, headers={'x-api-key': key}, timeout=aiohttp.ClientTimeout(total=20)) as r:
            if r.status == 429 or r.status >= 500:
                return {'state': 'pending'}
            if r.status in (401, 403):
                return {'state': 'fail', 'error': 'API key ditolak Roblox saat cek status upload (cek izin Assets Read).'}
            if r.status == 404:
                return {'state': 'fail', 'error': 'Operasi upload tidak ditemukan di Roblox.'}
            data = await r.json(content_type=None)
    except Exception:
        return {'state': 'pending'}
    if not isinstance(data, dict) or not data.get('done'):
        return {'state': 'pending'}
    if data.get('error'):
        err = data['error']
        msg = err.get('message') if isinstance(err, dict) else str(err)
        return {'state': 'fail', 'error': f'Upload ditolak Roblox: {msg or "gagal"}'}
    resp = data.get('response') or {}
    aid = str(resp.get('assetId') or '')
    if not aid.isdigit():
        aid = str(resp.get('path') or '').rsplit('/', 1)[-1]
    if aid.isdigit():
        return {'state': 'done', 'asset_id': aid}
    return {'state': 'fail', 'error': 'Roblox selesai tapi tidak memberi Asset ID.'}

async def _op_wait(s, op_id, key, attempts=3, delay=1.5):
    st = {'state': 'pending'}
    for i in range(attempts):
        st = await op_check(s, op_id, key)
        if st['state'] != 'pending':
            return st
        if i < attempts - 1:
            await asyncio.sleep(delay)
    return st

def _rm(path):
    try:
        if path and os.path.isfile(path):
            os.remove(path)
    except Exception:
        pass

# ── Proses 1 asset ──
async def _process_one(s, aid, save_dir, key, cfg, asset_type, name, total, do_upload=True):
    row = {'id': aid, 'ok': False}
    path, info, err = await plain_download(s, aid, save_dir)
    row['name'] = info.get('name')
    row['type'] = info.get('type')
    row['creator'] = info.get('creator')
    if err:
        row['error'] = err
        return row
    row['file'] = os.path.basename(path)
    row['ok'] = True
    if not do_upload:
        return row

    asset_name = (name or info.get('name')) if total == 1 else info.get('name')
    ext = path.rsplit('.', 1)[-1].lower() if '.' in path else ''
    if asset_type in KIND_EXT:
        if ext not in KIND_EXT[asset_type]:
            row['ok'] = False
            row['error'] = f'File hasil download (.{ext}) bukan tipe {asset_type}. Pilih tipe lain atau Otomatis.'
            _rm(path)
            return row
        itype = asset_type
    else:
        info = await _ensure_info_type(s, aid, info)
        row['type'] = info.get('type')
        itype = info.get('type')
        if ext == 'rbxm' and itype in (None, '', 'Asset'):
            try:
                with open(path, 'rb') as fh:
                    head = fh.read(262144)
                    if b'KeyframeSequence' in head or b'CurveAnimation' in head:
                        itype = 'Animation'
                        row['type'] = 'Animation'
            except Exception:
                pass
        if ext == 'rbxm' and itype in (None, '', 'Asset'):
            row['ok'] = False
            row['error'] = 'Tipe asset belum bisa dipastikan (Roblox membatasi cek info). Coba lagi, atau pilih Animasi/Model manual.'
            _rm(path)
            return row

    asset_name = str(asset_name or f'Asset_{aid}')[:50]
    up = await _upload_with_retry(s, path, key, cfg, asset_name, itype,
                                  f'Uploaded via Med Studio Spoofer | Original ID: {aid}')
    if not up['success']:
        row['ok'] = False
        row['error'] = up['error']
    else:
        if up.get('asset_type'):
            row['type'] = up['asset_type']
        new_id = str(up.get('asset_id') or '')
        op_id = up.get('operation_id')
        if not new_id.isdigit() and op_id:
            st = await _op_wait(s, op_id, key, attempts=3, delay=1.5)
            if st['state'] == 'done':
                new_id = st['asset_id']
            elif st['state'] == 'fail':
                row['ok'] = False
                row['error'] = st['error']
            else:
                row['new_id'] = 'pending'
                row['op'] = str(op_id)
        if row['ok'] and row.get('new_id') != 'pending':
            if new_id.isdigit():
                row['new_id'] = new_id
            else:
                row['ok'] = False
                row['error'] = 'Roblox tidak mengembalikan Asset ID baru.'
    _rm(path)
    return row

async def run_spoof(uid: str, cfg: dict, ids: list, asset_type: str = 'auto', name: str = None, progress=None,
                    workers: int = None, do_upload: bool = True) -> list:
    key = store.dec_key(cfg)
    save_dir = os.path.join(config.DL_DIR, str(uid))
    os.makedirs(save_dir, mode=0o700, exist_ok=True)
    sem = asyncio.Semaphore(workers or (config.MANUAL_WORKERS if asset_type in KIND_EXT else config.PARALLEL_WORKERS))
    total = len(ids)
    done = 0

    async def one(aid):
        nonlocal done
        async with sem:
            async with make_session() as s:
                try:
                    row = await _process_one(s, aid, save_dir, key, cfg, asset_type, name, total, do_upload)
                except Exception:
                    logging.getLogger('engine.spoof').exception('Error tak terduga pada asset %s', aid)
                    row = {'id': aid, 'ok': False, 'error': 'Error tak terduga di server (sudah dicatat).'}
        done += 1
        if progress:
            try:
                await progress(done, total)
            except Exception:
                pass
        return row

    try:
        return list(await asyncio.gather(*[one(a) for a in ids]))
    finally:
        if do_upload:
            shutil.rmtree(save_dir, ignore_errors=True)

async def settle_pending(rows: list, key: str, max_wait: int = None, interval: float = 3.0, on_wait=None,
                         step: float = 1.5, cap: float = 8.0) -> list:
    max_wait = config.PENDING_WAIT_SEC if max_wait is None else max_wait
    deadline = time.monotonic() + max_wait
    pend = [r for r in rows if r.get('ok') and r.get('new_id') == 'pending' and r.get('op')]
    sem = asyncio.Semaphore(5)
    wait = interval

    async def check(r, s):
        async with sem:
            return await op_check(s, r['op'], key)

    while pend and time.monotonic() < deadline:
        if on_wait:
            try:
                await on_wait(len(pend))
            except Exception:
                pass
        await asyncio.sleep(wait)
        wait = min(wait + step, cap)
        async with make_session() as s:
            res = await asyncio.gather(*[check(r, s) for r in pend])
        still = []
        for r, st in zip(pend, res):
            if st['state'] == 'done':
                r['new_id'] = st['asset_id']
                r.pop('op', None)
            elif st['state'] == 'fail':
                r['ok'] = False
                r['error'] = st['error']
                r.pop('new_id', None)
                r.pop('op', None)
            else:
                still.append(r)
        pend = still
    return rows

CHUNK = 30
RETRY_PREFIX = 'Tipe asset belum bisa dipastikan'

async def run_batch(uid: str, cfg: dict, ids: list, asset_type: str = 'auto', progress=None, on_wait=None) -> list:
    key = store.dec_key(cfg)
    total = len(ids)
    rows = []
    base = 0
    for i in range(0, total, CHUNK):
        chunk = ids[i:i + CHUNK]

        async def prog(done, _t, base=base):
            if progress:
                await progress(base + done, total)

        part = await run_spoof(uid, cfg, chunk, asset_type=asset_type, progress=prog)
        await settle_pending(part, key, max_wait=600, on_wait=on_wait)
        rows.extend(part)
        base += len(chunk)
        if progress:
            await progress(base, total)

    if asset_type == 'auto':
        retry = [k for k, r in enumerate(rows) if not r.get('ok') and str(r.get('error', '')).startswith(RETRY_PREFIX)]
        if retry:
            await asyncio.sleep(10)
            again = await run_spoof(uid, cfg, [rows[k]['id'] for k in retry], asset_type, workers=2)
            await settle_pending(again, key, max_wait=600, on_wait=on_wait)
            for k, r in zip(retry, again):
                rows[k] = r
    return rows
