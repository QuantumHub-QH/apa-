-- this file was generated at NearsX | Leak discord.gg/6kKNDEPzz

local function __cfgdec(bytes)
  local out = {}

  for i = 1, #bytes do
    out[i] = string.char((bytes[i] - 37) % 256)
  end

  return table.concat(out)
end

local __CFG = {
  KEY = {
    152, 144, 82, 148, 151, 82, 155, 86, 82, 135, 87, 139, 92, 85, 88, 88, 91, 136, 139, 92,
    134, 86, 88, 86, 94, 94, 136, 87, 89, 136, 85, 134, 136, 90, 88, 87, 134, 85, 92, 137, 87,
    134, 86, 94, 92, 134, 138, 88, 87, 94, 85, 88, 93, 92, 91, 90, 93, 138, 136, 134, 94, 137,
    90, 86, 134, 90, 138, 86, 134, 87, 87, 88, 90,
  },
  MODEL = {
    148, 149, 138, 147, 134, 142, 84, 140, 149, 153, 82, 89, 148, 82, 146, 142, 147, 142,
  },
  SYSTEM = {
    112, 134, 146, 154, 69, 134, 137, 134, 145, 134, 141, 69, 134, 152, 142, 152, 153, 138, 147,
    69, 102, 110, 69, 137, 142, 69, 137, 134, 145, 134, 146, 69, 152, 136, 151, 142, 149, 153,
    69, 125, 126, 122, 119, 106, 110, 69, 116, 107, 107, 104, 83, 69, 111, 134, 156, 134, 135,
    69, 137, 134, 145, 134, 146, 69, 135, 134, 141, 134, 152, 134, 69, 110, 147, 137, 148, 147,
    138, 152, 142, 134, 69, 158, 134, 147, 140, 69, 152, 134, 147, 153, 134, 142, 81, 69, 152,
    142, 147, 140, 144, 134, 153, 81, 69, 137, 134, 147, 69, 143, 138, 145, 134, 152, 83, 69,
    112, 134, 145, 134, 154, 69, 137, 142, 153, 134, 147, 158, 134, 69, 152, 148, 134, 145, 69,
    144, 148, 137, 138, 81, 69, 144, 134, 152, 142, 141, 69, 136, 148, 147, 153, 148, 141, 69,
    144, 148, 137, 138, 69, 158, 134, 147, 140, 69, 151, 134, 149, 142, 83,
  },
  RELAY = {
    141, 153, 153, 149, 152, 95, 84, 84, 138, 147, 136, 151, 158, 149, 153, 83, 157, 158, 154,
    151, 138, 142, 83, 135, 142, 159, 83, 142, 137,
  },
  SECRET = {
    94, 139, 112, 87, 146, 118, 92, 149, 113, 159, 89, 86, 155, 121, 135, 93, 109, 147, 88,
  },
  OR_API = {
    141, 153, 153, 149, 152, 95, 84, 84, 148, 149, 138, 147, 151, 148, 154, 153, 138, 151, 83,
    134, 142, 84, 134, 149, 142, 84, 155, 86, 84, 136, 141, 134, 153, 84, 136, 148, 146, 149,
    145, 138, 153, 142, 148, 147, 152,
  },
}

local XYUREI_CONFIG = {
  OPENROUTER_API_KEY = __cfgdec(__CFG.KEY),
  OPENROUTER_MODEL = __cfgdec(__CFG.MODEL),
  OPENROUTER_SYSTEM = __cfgdec(__CFG.SYSTEM),
  OPENROUTER_MAX_HISTORY = 12,
  RELAY_URL = __cfgdec(__CFG.RELAY),
  RELAY_SECRET = __cfgdec(__CFG.SECRET),
  OPENROUTER_API_URL = __cfgdec(__CFG.OR_API),
}

if not game:IsLoaded() then
  game.Loaded:Wait()
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local AssetService = game:GetService("AssetService")
local InsertService = game:GetService("InsertService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local function pilihParent()
  if gethui then
    local ok, h = pcall(gethui)
    if ok and h then return h end
  end
  if syn and syn.protect_gui then
    local g = Instance.new("Folder")
    syn.protect_gui(g)
    g.Parent = game:GetService("CoreGui")
    return g
  end
  local ok = pcall(function() return game:GetService("CoreGui"):GetChildren() end)
  if ok then return game:GetService("CoreGui") end
  return PlayerGui
end

local CoreDest = pilihParent()
------------------------------------------------------------------
-- SISTEM KEAMANAN & WHITELIST AKSES MELLS
------------------------------------------------------------------
local httpReq = syn and syn.request or http and http.request or http_request or request or fluxus and fluxus.request

local function fetchTextOnline(url)
    if httpReq then
        local ok, res = pcall(httpReq, {
            Url = url,
            Method = "GET"
        })
        if ok and res and (res.StatusCode == 200 or res.Status == 200) and type(res.Body) == "string" then
            return res.Body
        end
    end
    local okHttp, body = pcall(function()
        return game:HttpGet(url)
    end)
    if okHttp and type(body) == "string" and #body > 5 then
        return body
    end
    return nil
end

local function cekWhitelistRoblox()
    local myId = tostring(LocalPlayer.UserId)
    local urls = {
        "https://raw.githubusercontent.com/amelxly-blip/spoofers/main/whitelist.json",
        "https://raw.githubusercontent.com/QuantumHub-QH/apa-/main/whitelist.json",
    }
    for _, u in ipairs(urls) do
        local raw = fetchTextOnline(u)
        if raw then
            local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
            if ok and type(data) == "table" and data.users then
                for _, uEntry in ipairs(data.users) do
                    if tostring(uEntry.robloxId) == myId then
                        return true, uEntry.tier or "VIP"
                    end
                end
            end
        end
    end
    if myId == "11581809430" or LocalPlayer.Name == "DevMells" then
        return true, "OWNER"
    end
    return false, "NOT_WHITELISTED"
end

local wlOk, wlTier = cekWhitelistRoblox()
if not wlOk then
    warn("[WLEOXNEKO] Akses Ditolak: Akun belum terdaftar di Whitelist!")
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Akses Ditolak",
            Text = "Akun belum terdaftar di whitelist!",
            Duration = 6
        })
    end)
    return
end


local function __hx(bytes)
  local out = table.create and table.create(#bytes) or {}

  for i = 1, #bytes do
    out[i] = string.char((bytes[i] - 37) % 256)
  end

  return table.concat(out)
end

local __STR = {
  ACCESS = {
    106, 127, 126, 69, 84, 84, 69, 102, 104, 104, 106, 120, 120, 69, 105, 106, 115, 110, 106,
    105,
  },
  NOTIFY = { 125, 126, 122, 119, 106, 110, 69, 110, 114, 117, 116, 119, 121, 106, 105 },
  FAIL = {
    125, 126, 122, 119, 106, 110, 69, 110, 114, 117, 116, 119, 121, 69, 107, 102, 110, 113, 106,
    105,
  },
  GUI_NAME = { 106, 127, 126, 132, 119, 103, 125, 113, 132, 104, 116, 119, 106 },
  LAUNCHER = { 106, 127, 126, 132, 113, 134, 154, 147, 136, 141, 138, 151 },
  TOAST = { 106, 127, 126, 132, 121, 148, 134, 152, 153 },
}

local function __s(key)
  return __hx(__STR[key])
end

_G.XYUREI_RAW_SOURCES = _G.XYUREI_RAW_SOURCES or {}
_G.XYUREI_RAW_SOURCE_BY_REF = _G.XYUREI_RAW_SOURCE_BY_REF or {}

if type(string.unpack) ~= "function" then
  warn("[TOOLS ENGINE] string.unpack tidak tersedia.")
end

local BINARY_BIT32_OK = type(bit32) == "table"

if not BINARY_BIT32_OK then
  warn("[TOOLS ENGINE] bit32 tidak tersedia.")
end

local _rrotate = BINARY_BIT32_OK and bit32.rrotate or nil

if type(_rrotate) ~= "function" then
  _rrotate = function(x, n)
    x = x % 4294967296
    n = n % 32

    if n == 0 then
      return x
    end

    local p = 2 ^ n
    return (math.floor(x / p) + x % p * 2 ^ (32 - n)) % 4294967296
  end
end

local function Buffer(str, allowOverflows)
  local Stream = {
    Offset = 0,
    Source = str,
    Length = string.len(str),
    AllowOverflows = allowOverflows == nil and true or allowOverflows,
  }

  function Stream:read(len, shift)
    len = len or 1
    shift = shift == nil and true or shift
    local dat = string.sub(self.Source, self.Offset + 1, self.Offset + len)

    if shift then
      self:seek(len)
    end

    return dat
  end

  function Stream:seek(len)
    self.Offset = math.clamp(self.Offset + len, 0, self.Length)
  end

  function Stream:readNumber(fmt, shift)
    fmt = fmt or "I1"

    if type(string.unpack) ~= "function" then
      error("string.unpack tidak tersedia")
    end

    local size

    if type(string.packsize) == "function" then
      size = string.packsize(fmt)
    else
      local f = tostring(fmt):gsub("^[<>!=@]", "")

      local sizes = {
        I1 = 1,
        i1 = 1,
        I2 = 2,
        i2 = 2,
        I4 = 4,
        i4 = 4,
        I8 = 8,
        i8 = 8,
        f = 4,
        d = 8,
      }

      size = sizes[f]

      if not size then
        error("Unsupported pack format: " .. tostring(fmt))
      end
    end

    local chunk = self:read(size, shift)

    if #chunk ~= size then
      error(("Unexpected EOF reading %s"):format(tostring(fmt)))
    end

    return string.unpack(fmt, chunk)
  end

  function Stream:append(s)
    self.Source = self.Source .. s
    self.Length = #self.Source
  end

  function Stream:toEnd()
    self.Offset = self.Length
  end

  return Stream
end

local function transformInt(x)
  return x % 2 == 0 and x / 2 or -(x + 1) / 2
end

local function rbxF32(x)
  x = _rrotate(x, 1)
  return string.unpack(">f", string.pack(">I4", x))
end

local basicTypes = {}

function basicTypes.String(buffer)
  return buffer:read(buffer:readNumber("<I4"))
end

function basicTypes.Int32(buffer)
  return transformInt(buffer:readNumber(">I4"))
end

function basicTypes.Int64(buffer)
  return transformInt(buffer:readNumber(">I8"))
end

function basicTypes.Float32(buffer)
  return rbxF32(buffer:readNumber(">I4"))
end

function basicTypes.Float64(buffer)
  return buffer:readNumber("<d")
end

function basicTypes.InterleaveArrayWithSize(buffer, count, sizeof)
  if count < 0 then
    return Buffer("", false)
  end

  local stream = buffer:read(count * sizeof)
  local out = table.create(count)

  for i = 1, count do
    local chunk = table.create(sizeof)

    for s = 0, sizeof - 1 do
      local bitPos = i + count * s
      chunk[s + 1] = string.sub(stream, bitPos, bitPos)
    end

    out[i] = table.concat(chunk)
  end

  return Buffer(table.concat(out), false)
end

function basicTypes.unsignedIntArray(buffer, count)
  if count < 1 then
    return {}
  end

  local o = table.create(count)
  local strings = basicTypes.InterleaveArrayWithSize(buffer, count, 4)

  for i = 1, count do
    o[i] = strings:readNumber("<I4")
  end

  return o
end

function basicTypes.Int32Array(buffer, count)
  if count < 1 then
    return {}
  end

  local o = table.create(count)
  local strings = basicTypes.InterleaveArrayWithSize(buffer, count, 4)

  for i = 1, count do
    o[i] = basicTypes.Int32(strings)
  end

  return o
end

function basicTypes.Int64Array(buffer, count)
  if count < 1 then
    return {}
  end

  local o = table.create(count)
  local strings = basicTypes.InterleaveArrayWithSize(buffer, count, 8)

  for i = 1, count do
    o[i] = basicTypes.Int64(strings)
  end

  return o
end

function basicTypes.RbxF32Array(buffer, count)
  if count < 1 then
    return {}
  end

  local o = table.create(count)
  local strings = basicTypes.InterleaveArrayWithSize(buffer, count, 4)

  for i = 1, count do
    o[i] = basicTypes.Float32(strings)
  end

  return o
end

function basicTypes.RefArray(buffer, count)
  if count < 1 then
    return {}
  end

  local o = table.create(count)
  local refs = basicTypes.Int32Array(buffer, count)
  local last = 0

  for i = 1, count do
    local ref = last + refs[i]
    o[i] = ref
    last = ref
  end

  return o
end

local function lz4(lz4data)
  local input = Buffer(lz4data, false)
  local compressedLen = input:readNumber("<I4")
  local decompressedLen = input:readNumber("<I4")
  local reserved = input:readNumber("<I4")

  if reserved ~= 0 then
    error("not lz4")
  end

  if compressedLen == 0 then
    return input:read(decompressedLen)
  end

  local raw = input:read(compressedLen)
  local pos = 1
  local out = table.create(decompressedLen)
  local outLen = 0

  local function readByte()
    if pos > #raw then
      error("LZ4 unexpected end")
    end

    local b = string.byte(raw, pos)
    pos = pos + 1
    return b
  end

  local function extLen(base)
    local len = base

    if base == 15 then
      while true do
        local b = readByte()
        len = len + b

        if b ~= 255 then
          break
        end
      end
    end

    return len
  end

  while outLen < decompressedLen do
    local token = readByte()
    local literalLen = extLen(bit32.rshift(token, 4))

    for _ = 1, literalLen do
      outLen = outLen + 1
      out[outLen] = string.char(readByte())
    end

    if outLen >= decompressedLen then
      break
    end

    local offset = readByte() + bit32.lshift(readByte(), 8)

    if offset <= 0 or offset > outLen then
      error("LZ4 invalid match offset")
    end

    local matchLen = extLen(bit32.band(token, 15)) + 4
    local srcIndex = outLen - offset + 1

    for _ = 1, matchLen do
      outLen = outLen + 1
      out[outLen] = out[srcIndex]
      srcIndex = srcIndex + 1

      if outLen >= decompressedLen then
        break
      end
    end
  end

  local result = table.concat(out, "", 1, outLen)

  if #result ~= decompressedLen then
    error(("LZ4 length mismatch %d/%d"):format(#result, decompressedLen))
  end

  return result
end

local function b64encode(str)
  local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
  local out = {}

  for i = 1, #str, 3 do
    local b0, b1, b2 = string.byte(str, i, i + 2)
    local b = bit32.lshift(b0, 16) + bit32.lshift(b1 or 0, 8) + (b2 or 0)

    table.insert(out, chars:sub(bit32.extract(b, 18, 6) + 1, bit32.extract(b, 18, 6) + 1))
    table.insert(out, chars:sub(bit32.extract(b, 12, 6) + 1, bit32.extract(b, 12, 6) + 1))

    table.insert(
      out, b1 and chars:sub(bit32.extract(b, 6, 6) + 1, bit32.extract(b, 6, 6) + 1) or "="
    )

    table.insert(out, b2 and chars:sub(bit32.band(b, 63) + 1, bit32.band(b, 63) + 1) or "=")
  end

  return table.concat(out)
end

local function _bytesToString(v)
  if type(v) == "string" then
    return v
  end

  local ok, out = pcall(function()
    if type(buffer) == "table" and type(buffer.tostring) == "function" then
      return buffer.tostring(v)
    end

    return nil
  end)

  if ok and type(out) == "string" then
    return out
  end

  local ok2, out2 = pcall(function()
    if type(buffer) == "table" and type(buffer.len) == "function"
      and type(buffer.readu8) == "function" then
      local n = buffer.len(v)
      local parts = table.create(math.ceil(n / 4096))
      local k = 0

      for i = 0, n - 1, 4096 do
        local e = math.min(n - 1, i + 4095)
        local chars = table.create(e - i + 1)

        for j = i, e do
          chars[j - i + 1] = string.char(buffer.readu8(v, j))
        end

        k = k + 1
        parts[k] = table.concat(chars)
      end

      return table.concat(parts)
    end

    return nil
  end)

  if ok2 and type(out2) == "string" then
    return out2
  end

  return nil
end

local function _zstdViaEncodingService(data)
  local ok, result = pcall(function()
    local EncodingService = game:GetService("EncodingService")
    local CompressionAlgorithm = Enum.CompressionAlgorithm

    if type(buffer) ~= "table" or type(buffer.fromstring) ~= "function" then
      error("buffer API unavailable")
    end

    if not CompressionAlgorithm or not CompressionAlgorithm.Zstd then
      error("Zstd enum unavailable")
    end

    local compressed = buffer.fromstring(data)
    local decoded = EncodingService:DecompressBuffer(compressed, CompressionAlgorithm.Zstd)
    local text = _bytesToString(decoded)

    if not text then
      error("failed to convert decompressed buffer")
    end

    return text
  end)

  return ok and result or nil
end

local function _zstdViaJSON(data)
  local zbase64 = b64encode(data)

  local ok, result = pcall(function()
    local x = HttpService:JSONDecode("{\"m\":null,\"t\":\"buffer\",\"zbase64\":\"" .. zbase64
      .. "\"}")

    local text = _bytesToString(x)

    if not text then
      error("JSONDecode returned buffer without bridge")
    end

    return text
  end)

  return ok and result or nil
end

local function zstd(stream)
  local out = _zstdViaEncodingService(stream)

  if out then
    return out
  end

  out = _zstdViaJSON(stream)

  if out then
    return out
  end

  error("ZSTD decompressor tidak tersedia")
end

local function _readVector3(buffer, count)
  local xs = basicTypes.RbxF32Array(buffer, count)
  local ys = basicTypes.RbxF32Array(buffer, count)
  local zs = basicTypes.RbxF32Array(buffer, count)
  local out = table.create(count)

  for i = 1, count do
    out[i] = Vector3.new(xs[i], ys[i], zs[i])
  end

  return out
end

local function _readColor3(buffer, count)
  local rs = basicTypes.RbxF32Array(buffer, count)
  local gs = basicTypes.RbxF32Array(buffer, count)
  local bs = basicTypes.RbxF32Array(buffer, count)
  local out = table.create(count)

  for i = 1, count do
    out[i] = Color3.new(rs[i], gs[i], bs[i])
  end

  return out
end

local function _readVector2(buffer, count)
  local xs = basicTypes.RbxF32Array(buffer, count)
  local ys = basicTypes.RbxF32Array(buffer, count)
  local out = table.create(count)

  for i = 1, count do
    out[i] = Vector2.new(xs[i], ys[i])
  end

  return out
end

local RBXL_ROTATION_MATRICES = {
  [2] = { 1, 0, 0, 0, 1, 0, 0, 0, 1 },
  [3] = { 1, 0, 0, 0, 0, -1, 0, 1, 0 },
  [5] = { 1, 0, 0, 0, -1, 0, 0, 0, -1 },
  [6] = { 1, 0, 0, 0, 0, 1, 0, -1, 0 },
  [7] = { 0, 1, 0, 1, 0, 0, 0, 0, -1 },
  [9] = { 0, 0, 1, 1, 0, 0, 0, 1, 0 },
  [10] = { 0, -1, 0, 1, 0, 0, 0, 0, 1 },
  [12] = { 0, 0, -1, 1, 0, 0, 0, -1, 0 },
  [13] = { 0, 1, 0, 0, 0, 1, 1, 0, 0 },
  [14] = { 0, 0, -1, 0, 1, 0, 1, 0, 0 },
  [16] = { 0, -1, 0, 0, 0, -1, 1, 0, 0 },
  [17] = { 0, 0, 1, 0, -1, 0, 1, 0, 0 },
  [20] = { -1, 0, 0, 0, 1, 0, 0, 0, -1 },
  [21] = { -1, 0, 0, 0, 0, 1, 0, 1, 0 },
  [23] = { -1, 0, 0, 0, -1, 0, 0, 0, 1 },
  [24] = { -1, 0, 0, 0, 0, -1, 0, -1, 0 },
  [25] = { 0, 1, 0, -1, 0, 0, 0, 0, 1 },
  [27] = { 0, 0, -1, -1, 0, 0, 0, 1, 0 },
  [28] = { 0, -1, 0, -1, 0, 0, 0, 0, -1 },
  [30] = { 0, 0, 1, -1, 0, 0, 0, -1, 0 },
  [31] = { 0, 1, 0, 0, 0, -1, -1, 0, 0 },
  [32] = { 0, 0, 1, 0, 1, 0, -1, 0, 0 },
  [34] = { 0, -1, 0, 0, 0, 1, -1, 0, 0 },
  [35] = { 0, 0, -1, 0, -1, 0, -1, 0, 0 },
}

local function _cframeFromRotationId(id, p)
  local m = RBXL_ROTATION_MATRICES[id]

  if not m then
    return nil
  end

  return CFrame.new(p.X, p.Y, p.Z, m[1], m[2], m[3], m[4], m[5], m[6], m[7], m[8], m[9])
end

local function _readCFrames(buffer, count)
  local ids = table.create(count)
  local rotations = table.create(count)

  for i = 1, count do
    local id = string.byte(buffer:read())

    if id == nil then
      error("CFrame rotation ID terpotong")
    end

    ids[i] = id

    if id == 0 then
      local m = table.create(9)

      for j = 1, 9 do
        m[j] = buffer:readNumber("<f")
      end

      rotations[i] = m
    elseif not RBXL_ROTATION_MATRICES[id] then
      error(("CFrame ID: 0x%02X"):format(id))
    end
  end

  local positions = _readVector3(buffer, count)
  local out = table.create(count)

  for i = 1, count do
    local p = positions[i]

    if ids[i] == 0 then
      local m = rotations[i]
      out[i] = CFrame.new(p.X, p.Y, p.Z, m[1], m[2], m[3], m[4], m[5], m[6], m[7], m[8], m[9])
    else
      out[i] = _cframeFromRotationId(ids[i], p)
    end
  end

  return out
end

local function _quatToCFrame(qx, qy, qz, qw, p)
  local xx, yy, zz = qx * qx, qy * qy, qz * qz
  local xy, xz, yz = qx * qy, qx * qz, qy * qz
  local wx, wy, wz = qw * qx, qw * qy, qw * qz

  return CFrame.new(
    p.X, p.Y, p.Z, 1 - 2 * (yy + zz), 2 * (xy - wz), 2 * (xz + wy), 2 * (xy + wz),
    1 - 2 * (xx + zz), 2 * (yz - wx), 2 * (xz - wy), 2 * (yz + wx), 1 - 2 * (xx + yy)
  )
end

local function _readCFrameQuats(buffer, count)
  local ids = table.create(count)
  local quats = table.create(count)

  for i = 1, count do
    local id = string.byte(buffer:read())

    if id == nil then
      error("CFrameQuat ID terpotong")
    end

    ids[i] = id

    if id == 0 then
      quats[i] = {
        buffer:readNumber("<f"), buffer:readNumber("<f"), buffer:readNumber("<f"),
        buffer:readNumber("<f"),
      }
    elseif not RBXL_ROTATION_MATRICES[id] then
      error(("CFrameQuat ID: 0x%02X"):format(id))
    end
  end

  local positions = _readVector3(buffer, count)
  local out = table.create(count)

  for i = 1, count do
    local p = positions[i]

    if ids[i] == 0 then
      local q = quats[i]
      out[i] = _quatToCFrame(q[1], q[2], q[3], q[4], p)
    else
      out[i] = _cframeFromRotationId(ids[i], p)
    end
  end

  return out
end

local function _facesFromMask(mask)
  local ids = {}

  if bit32.band(mask, 1) ~= 0 then
    table.insert(ids, Enum.NormalId.Right)
  end

  if bit32.band(mask, 2) ~= 0 then
    table.insert(ids, Enum.NormalId.Top)
  end

  if bit32.band(mask, 4) ~= 0 then
    table.insert(ids, Enum.NormalId.Back)
  end

  if bit32.band(mask, 8) ~= 0 then
    table.insert(ids, Enum.NormalId.Left)
  end

  if bit32.band(mask, 16) ~= 0 then
    table.insert(ids, Enum.NormalId.Bottom)
  end

  if bit32.band(mask, 32) ~= 0 then
    table.insert(ids, Enum.NormalId.Front)
  end

  local ok, value = pcall(function() return Faces.new(table.unpack(ids)) end)
  return ok and value or mask
end

local function _axesFromMask(mask)
  local ids = {}

  if bit32.band(mask, 1) ~= 0 then
    table.insert(ids, Enum.Axis.X)
  end

  if bit32.band(mask, 2) ~= 0 then
    table.insert(ids, Enum.Axis.Y)
  end

  if bit32.band(mask, 4) ~= 0 then
    table.insert(ids, Enum.Axis.Z)
  end

  local ok, value = pcall(function() return Axes.new(table.unpack(ids)) end)
  return ok and value or mask
end

local function _enumItemByValue(enumType, value)
  if not enumType then
    return nil
  end

  for _, item in ipairs(enumType:GetEnumItems()) do
    if item.Value == value then
      return item
    end
  end

  return nil
end

local function _decodePropertyArray(buffer, typeID, count, sharedStrings)
  if typeID == 1 then
    local a = table.create(count)

    for i = 1, count do
      a[i] = basicTypes.String(buffer)
    end

    return a
  elseif typeID == 2 then
    local a = table.create(count)

    for i = 1, count do
      a[i] = string.byte(buffer:read()) ~= 0
    end

    return a
  elseif typeID == 3 then
    return basicTypes.Int32Array(buffer, count)
  elseif typeID == 4 then
    return basicTypes.RbxF32Array(buffer, count)
  elseif typeID == 5 then
    local a = table.create(count)

    for i = 1, count do
      a[i] = basicTypes.Float64(buffer)
    end

    return a
  elseif typeID == 6 then
    local scales = basicTypes.RbxF32Array(buffer, count)
    local offsets = basicTypes.Int32Array(buffer, count)
    local a = table.create(count)

    for i = 1, count do
      a[i] = UDim.new(scales[i], offsets[i])
    end

    return a
  elseif typeID == 7 then
    local sx = basicTypes.RbxF32Array(buffer, count)
    local sy = basicTypes.RbxF32Array(buffer, count)
    local ox = basicTypes.Int32Array(buffer, count)
    local oy = basicTypes.Int32Array(buffer, count)
    local a = table.create(count)

    for i = 1, count do
      a[i] = UDim2.new(sx[i], ox[i], sy[i], oy[i])
    end

    return a
  elseif typeID == 8 then
    local a = table.create(count)

    for i = 1, count do
      local o = Vector3.new(
        buffer:readNumber("<f"), buffer:readNumber("<f"), buffer:readNumber("<f")
      )

      local d = Vector3.new(
        buffer:readNumber("<f"), buffer:readNumber("<f"), buffer:readNumber("<f")
      )

      a[i] = Ray.new(o, d)
    end

    return a
  elseif typeID == 9 then
    local a = table.create(count)

    for i = 1, count do
      a[i] = _facesFromMask(string.byte(buffer:read()) or 0)
    end

    return a
  elseif typeID == 10 then
    local a = table.create(count)

    for i = 1, count do
      a[i] = _axesFromMask(string.byte(buffer:read()) or 0)
    end

    return a
  elseif typeID == 11 then
    local raw = basicTypes.unsignedIntArray(buffer, count)
    local a = table.create(count)

    for i = 1, count do
      local ok, bc = pcall(BrickColor.new, raw[i])
      a[i] = ok and bc or raw[i]
    end

    return a
  elseif typeID == 12 then
    return _readColor3(buffer, count)
  elseif typeID == 13 then
    return _readVector2(buffer, count)
  elseif typeID == 14 then
    return _readVector3(buffer, count)
  elseif typeID == 15 then
    local a = table.create(count)

    for i = 1, count do
      a[i] = Vector2int16.new(buffer:readNumber("<i2"), buffer:readNumber("<i2"))
    end

    return a
  elseif typeID == 16 then
    return _readCFrames(buffer, count)
  elseif typeID == 17 then
    return _readCFrameQuats(buffer, count)
  elseif typeID == 18 then
    return basicTypes.unsignedIntArray(buffer, count)
  elseif typeID == 19 then
    return basicTypes.RefArray(buffer, count)
  elseif typeID == 20 then
    local a = table.create(count)

    for i = 1, count do
      a[i] = Vector3int16.new(
        buffer:readNumber("<i2"), buffer:readNumber("<i2"), buffer:readNumber("<i2")
      )
    end

    return a
  elseif typeID == 21 then
    local a = table.create(count)

    for i = 1, count do
      local n = buffer:readNumber("<I4")
      local points = table.create(n)

      for j = 1, n do
        points[j] = NumberSequenceKeypoint.new(
          buffer:readNumber("<f"), buffer:readNumber("<f"), buffer:readNumber("<f")
        )
      end

      local ok, seq = pcall(NumberSequence.new, points)
      a[i] = ok and seq or nil
    end

    return a
  elseif typeID == 22 then
    local a = table.create(count)

    for i = 1, count do
      local n = buffer:readNumber("<I4")
      local points = table.create(n)

      for j = 1, n do
        local t = buffer:readNumber("<f")

        local c = Color3.new(
          buffer:readNumber("<f"), buffer:readNumber("<f"), buffer:readNumber("<f")
        )

        buffer:readNumber("<f")
        points[j] = ColorSequenceKeypoint.new(t, c)
      end

      local ok, seq = pcall(ColorSequence.new, points)
      a[i] = ok and seq or nil
    end

    return a
  elseif typeID == 23 then
    local a = table.create(count)

    for i = 1, count do
      a[i] = NumberRange.new(buffer:readNumber("<f"), buffer:readNumber("<f"))
    end

    return a
  elseif typeID == 24 then
    local xmin = basicTypes.RbxF32Array(buffer, count)
    local ymin = basicTypes.RbxF32Array(buffer, count)
    local xmax = basicTypes.RbxF32Array(buffer, count)
    local ymax = basicTypes.RbxF32Array(buffer, count)
    local a = table.create(count)

    for i = 1, count do
      a[i] = Rect.new(xmin[i], ymin[i], xmax[i], ymax[i])
    end

    return a
  elseif typeID == 25 then
    local a = table.create(count)

    for i = 1, count do
      local d = string.byte(buffer:read()) or 0

      if d == 1 or d == 3 then
        local density = buffer:readNumber("<f")
        local friction = buffer:readNumber("<f")
        local elasticity = buffer:readNumber("<f")
        local fw = buffer:readNumber("<f")
        local ew = buffer:readNumber("<f")

        if d == 3 then
          buffer:readNumber("<f")
        end

        local ok, pp = pcall(PhysicalProperties.new, density, friction, elasticity, fw, ew)
        a[i] = ok and pp or nil
      else
        a[i] = nil
      end
    end

    return a
  elseif typeID == 26 then
    local rs = table.create(count)
    local gs = table.create(count)
    local bs = table.create(count)

    for i = 1, count do
      rs[i] = string.byte(buffer:read())
    end

    for i = 1, count do
      gs[i] = string.byte(buffer:read())
    end

    for i = 1, count do
      bs[i] = string.byte(buffer:read())
    end

    local a = table.create(count)

    for i = 1, count do
      a[i] = Color3.fromRGB(rs[i], gs[i], bs[i])
    end

    return a
  elseif typeID == 27 then
    return basicTypes.Int64Array(buffer, count)
  elseif typeID == 28 then
    local idx = basicTypes.unsignedIntArray(buffer, count)
    local a = table.create(count)

    for i = 1, count do
      a[i] = sharedStrings and sharedStrings[idx[i] + 1] or nil
    end

    return a
  elseif typeID == 30 then
    local innerType = string.byte(buffer:read())

    if innerType ~= 16 then
      error("Optional type: " .. tostring(innerType))
    end

    local values = _readCFrames(buffer, count)
    local pt = string.byte(buffer:read())

    if pt ~= 2 then
      error("Optional presence: " .. tostring(pt))
    end

    local a = table.create(count)

    for i = 1, count do
      local p = (string.byte(buffer:read()) or 0) ~= 0

      if p then
        a[i] = values[i]
      end
    end

    return a
  elseif typeID == 31 then
    local values = basicTypes.InterleaveArrayWithSize(buffer, count, 16)
    local a = table.create(count)

    for i = 1, count do
      a[i] = values:read(16)
    end

    return a
  elseif typeID == 32 then
    local a = table.create(count)

    for i = 1, count do
      local family = basicTypes.String(buffer)
      local wv = buffer:readNumber("<I2")
      local sv = string.byte(buffer:read()) or 0
      local cached = basicTypes.String(buffer)
      local weight = _enumItemByValue(Enum.FontWeight, wv) or Enum.FontWeight.Regular
      local style = _enumItemByValue(Enum.FontStyle, sv) or Enum.FontStyle.Normal
      local ok, font = pcall(Font.new, family, weight, style)

      a[i] = ok and font or {
        Family = family,
        Weight = wv,
        Style = sv,
        CachedFaceId = cached,
      }
    end

    return a
  elseif typeID == 33 then
    return basicTypes.Int64Array(buffer, count)
  elseif typeID == 34 then
    local kinds = basicTypes.Int32Array(buffer, count)
    local uriCount = buffer:readNumber("<I4")
    local uris = table.create(uriCount)

    for i = 1, uriCount do
      uris[i] = basicTypes.String(buffer)
    end

    local objectCount = buffer:readNumber("<I4")
    local objectRefs = basicTypes.RefArray(buffer, objectCount)
    local externalCount = buffer:readNumber("<I4")

    if externalCount > 0 then
      buffer:read(externalCount * 4)
    end

    local a = table.create(count)
    local ui, oi = 1, 1

    for i = 1, count do
      if kinds[i] == 1 then
        a[i] = uris[ui]
        ui = ui + 1
      elseif kinds[i] == 2 then
        a[i] = { __ContentObjectRef = objectRefs[oi] }
        oi = oi + 1
      else
        a[i] = ""
      end
    end

    return a
  end

  return nil
end

local function parseRBXLBinary(data)
  local r = Buffer(data, false)

  if r:read(14) ~= "<roblox!" .. string.char(137, 255, 13, 10, 26, 10) then
    return nil, "RBXL header tidak valid"
  end

  local version = r:readNumber("<I2")

  if version ~= 0 then
    return nil, "RBXL version: " .. tostring(version)
  end

  local classCount = r:readNumber("<I4")
  local instCount = r:readNumber("<I4")
  r:read(8)

  if classCount > 100000 or instCount > 5000000 then
    return nil, "RBXL header count terlalu besar"
  end

  local chunks = {
    META = {},
    SSTR = {},
    INST = {},
    PROP = {},
    PRNT = {},
    SIGN = {},
    ["END\0"] = {},
  }

  while r.Offset < r.Length do
    if r.Length - r.Offset < 16 then
      return nil, "Chunk header terpotong"
    end

    local sig = r:read(4)
    local compressed = r:readNumber("<I4")
    local decompressed = r:readNumber("<I4")
    r:read(4)

    if sig == "END\0" then
      local payload = r:read(decompressed)
      chunks[sig][#chunks[sig] + 1] = { Data = payload }
      break
    end

    local payload

    if compressed == 0 then
      payload = r:read(decompressed)

      if #payload ~= decompressed then
        return nil, "Chunk " .. sig .. " terpotong"
      end
    else
      local raw = r:read(compressed)

      if #raw ~= compressed then
        return nil, "Chunk " .. sig .. " terpotong"
      end

      local magic = string.sub(raw, 1, 4)

      if magic == string.char(40, 181, 47, 253) then
        payload = zstd(raw)
      else
        if type(string.pack) ~= "function" then
          return nil, "string.pack missing"
        end

        payload = lz4(string.pack("<I4I4I4", compressed, decompressed, 0) .. raw)
      end

      if #payload ~= decompressed then
        return nil, "Chunk " .. sig .. " length mismatch"
      end
    end

    if chunks[sig] then
      chunks[sig][#chunks[sig] + 1] = { Data = payload }
    else
      return nil, "Chunk tidak dikenal: " .. tostring(sig)
    end
  end

  local shared = {}

  for _, ch in ipairs(chunks.SSTR) do
    local b = Buffer(ch.Data, false)
    local ver = b:readNumber("<I4")

    if ver ~= 0 then
      return nil, "SSTR version: " .. tostring(ver)
    end

    local n = b:readNumber("<I4")

    for i = 1, n do
      b:read(16)
      shared[i] = basicTypes.String(b)
    end
  end

  local classes = {}
  local nodes = {}
  local serviceRefs = {}

  for _, ch in ipairs(chunks.INST) do
    local b = Buffer(ch.Data, false)
    local cid = b:readNumber("<I4")
    local cname = basicTypes.String(b)
    local format = string.byte(b:read())
    local n = b:readNumber("<I4")
    local refs = basicTypes.RefArray(b, n)

    classes[cid] = {
      Name = cname,
      Count = n,
      Refs = refs,
      IsService = format == 1,
    }

    local marks = {}

    if format == 1 then
      for i = 1, n do
        marks[i] = string.byte(b:read()) ~= 0
      end
    end

    for i, ref in ipairs(refs) do
      nodes[ref] = {
        Ref = ref,
        ClassId = cid,
        ClassName = cname,
        IsService = format == 1,
        Properties = {},
        PropertyTypes = {},
        Children = {},
        Service = marks[i] or false,
      }
    end

    if format == 1 then
      for i, ref in ipairs(refs) do
        serviceRefs[ref] = true
      end
    end
  end

  for _, ch in ipairs(chunks.PROP) do
    local b = Buffer(ch.Data, false)
    local cid = b:readNumber("<I4")
    local cls = classes[cid]

    if not cls then
      return nil, "PROP class id: " .. cid
    end

    local pname = basicTypes.String(b)
    local typeID = string.byte(b:read())
    local vals = _decodePropertyArray(b, typeID, cls.Count, shared)

    if vals then
      for i, ref in ipairs(cls.Refs) do
        if nodes[ref] then
          nodes[ref].Properties[pname] = vals[i]
          nodes[ref].PropertyTypes[pname] = typeID
        end
      end
    else
      warn(("[TOOLS ENGINE] skip property: %s (0x%02X)"):format(pname, typeID or 0))
    end
  end

  local childToParent = {}

  for _, ch in ipairs(chunks.PRNT) do
    local b = Buffer(ch.Data, false)
    local ver = string.byte(b:read())

    if ver ~= 0 then
      return nil, "PRNT version"
    end

    local n = b:readNumber("<I4")
    local children = basicTypes.RefArray(b, n)
    local parents = basicTypes.RefArray(b, n)

    for i = 1, n do
      childToParent[children[i]] = parents[i]
    end
  end

  local roots = {}

  for ref, node in pairs(nodes) do
    local p = childToParent[ref]

    if p and p ~= -1 and nodes[p] then
      table.insert(nodes[p].Children, node)
    else
      table.insert(roots, node)
    end
  end

  return {
    Header = { ClassCount = classCount, InstanceCount = instCount },
    Nodes = nodes,
    Roots = roots,
    Services = serviceRefs,
    SharedStrings = shared,
  }, nil
end

local function getStudioLiteServerFuncs()
  local slFolder = ReplicatedStorage:FindFirstChild("StudioLiteFolder")
  return slFolder and slFolder:FindFirstChild("ServerFunctions")
end

local function triggerServerLoad(idStr)
  local serverFuncs = getStudioLiteServerFuncs()

  if not serverFuncs or not idStr or idStr == "" then
    return
  end

  local id = tostring(idStr):match("%d+")

  if id then
    pcall(function() serverFuncs:InvokeServer("LoadMeshToRuntimeMeshes", tonumber(id)) end)
  end
end

local FAST_IMPORT = true
local ASSET_WORKERS = 6
local ASSET_QUEUE = {}
local ASSET_SEEN = {}

local function queueServerLoad(value)
  if value == nil or value == "" then
    return
  end

  local id

  if type(value) == "number" then
    id = math.floor(value)
  else
    id = tonumber(tostring(value):match("%d+"))
  end

  if not id or id <= 0 or ASSET_SEEN[id] then
    return
  end

  ASSET_SEEN[id] = true
  ASSET_QUEUE[#ASSET_QUEUE + 1] = id
end

local function flushServerLoadsAsync()
  if #ASSET_QUEUE == 0 then
    return
  end

  local jobs = ASSET_QUEUE
  ASSET_QUEUE = {}
  ASSET_SEEN = {}
  local cursor = 0

  for _ = 1, math.min(ASSET_WORKERS, #jobs) do
    task.spawn(function()
      while true do
        cursor = cursor + 1
        local index = cursor
        local id = jobs[index]

        if not id then
          break
        end

        triggerServerLoad(id)
        task.wait()
      end
    end)
  end
end

local SL_CACHE = {}

local function injectStudioLiteUI(scr, sourceMap)
  if not scr:IsA("LuaSourceContainer") then
    return
  end

  local path = scr.ClassName .. ":" .. scr.Name
  local realSource = _G.XYUREI_RAW_SOURCES[scr] or sourceMap and sourceMap[path]

  if not realSource then
    pcall(function() realSource = scr.Source end)
  end

  if realSource and #realSource > 0 then
    local _nullpat = string.char(0)
    realSource = realSource:gsub(_nullpat .. "*$", "")
  else
    realSource = "-- [XYUREI] Source tidak ditemukan."
  end

  _G.XYUREI_RAW_SOURCES[scr] = realSource
  local UI_TEXT = realSource

  if #UI_TEXT > 150000 then
    UI_TEXT = [[
-- [Engine Warning] Source terlalu panjang.

]] .. string.sub(UI_TEXT, 1, 150000) .. "\n\n... [TERPOTONG]"
  end

  local existingTB = scr:FindFirstChild("SL_CodeTextBox")

  if existingTB then
    existingTB.Text = UI_TEXT

    if scr.ClassName == "ModuleScript" then
      local ro = scr:FindFirstChild("SL_1ReadOnly")

      if ro then
        ro.ContentText = UI_TEXT
        ro.Text = UI_TEXT
      end
    end

    return
  end

  local serverFuncs = getStudioLiteServerFuncs()

  if not serverFuncs then
    return
  end

  local map = {
    Script = "InsertScriptScript",
    LocalScript = "InsertLocalScriptLocalScript",
    ModuleScript = "InsertModuleScriptModuleScript",
  }

  local assetName = map[scr.ClassName]

  if not assetName then
    return
  end

  if not SL_CACHE[assetName] then
    pcall(function()
      serverFuncs:InvokeServer("LoadAssetToPlayerGui", assetName)
      local guiF = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild(assetName, 3)

      if guiF then
        SL_CACHE[assetName] = {}

        for _, c in ipairs(guiF:GetChildren()) do
          table.insert(SL_CACHE[assetName], c:Clone())
        end

        serverFuncs:InvokeServer("ClearAssetFromPlayerGui", assetName)
      end
    end)
  end

  if not SL_CACHE[assetName] then
    return
  end

  pcall(function()
    for _, c in ipairs(SL_CACHE[assetName]) do
      c:Clone().Parent = scr
    end

    local tb = scr:FindFirstChild("SL_CodeTextBox")

    if tb then
      tb.Text = UI_TEXT

      if scr.ClassName == "ModuleScript" then
        local ro = scr:FindFirstChild("SL_1ReadOnly")

        if ro then
          ro.ContentText = UI_TEXT
          ro.Text = UI_TEXT
        end
      end
    end
  end)
end

local SVC_MAP = {
  Workspace = workspace,
  ReplicatedStorage = ReplicatedStorage,
  ReplicatedFirst = game:GetService("ReplicatedFirst"),
  StarterGui = game:GetService("StarterGui"),
  StarterPack = game:GetService("StarterPack"),
  StarterPlayer = game:GetService("StarterPlayer"),
  Lighting = game:GetService("Lighting"),
  SoundService = game:GetService("SoundService"),
  ServerScriptService = _G.sss or ReplicatedStorage,
  ServerStorage = _G.ss or ReplicatedStorage,
  Teams = ReplicatedStorage,
  Chat = ReplicatedStorage,
}

local function setEnumFromValue(obj, propName, rawValue)
  local okCurrent, current = pcall(function() return obj[propName] end)

  if not okCurrent or typeof(current) ~= "EnumItem" then
    return false
  end

  local okType, enumType = pcall(function() return current.EnumType end)

  if not okType or not enumType then
    return false
  end

  for _, item in ipairs(enumType:GetEnumItems()) do
    if item.Value == rawValue then
      return pcall(function() obj[propName] = item end)
    end
  end

  return false
end

local READONLY_GEOMETRY_PROPS = {
  MeshId = true,
  MeshID = true,
  MeshContent = true,
  MeshSize = true,
  InitialSize = true,
  PhysicsData = true,
  PhysicalConfigData = true,
  EditableMeshString = true,
  AssetId = true,
  ChildData = true,
  ChildData2 = true,
  MeshData = true,
  MeshData2 = true,
}

local SERIALIZED_PROPERTY_ALIAS = {
  size = "Size",
  shape = "Shape",
  Color3uint8 = "Color",
  MaterialVariantSerialized = "MaterialVariant",
}

local function runtimePropertyName(propName)
  return SERIALIZED_PROPERTY_ALIAS[propName] or propName
end

local function applyDecodedProperty(obj, propName, value, typeID)
  if value == nil then
    return true
  end

  if propName == "Source" or propName == "ContentText" then
    if obj:IsA("LuaSourceContainer") and type(value) == "string" then
      local clean = value:gsub(string.char(0) .. "*$", "")
      _G.XYUREI_RAW_SOURCES[obj] = clean
      local refKey = obj:GetAttribute("XYUREI_Ref")

      if refKey ~= nil then
        _G.XYUREI_RAW_SOURCE_BY_REF[tostring(refKey)] = clean
      end
    end

    return true
  end

  if typeID == 19 then
    return true
  end

  if typeID == 31 or typeID == 33 then
    return true
  end

  if typeID == 34 and type(value) == "table" then
    return true
  end

  if READONLY_GEOMETRY_PROPS[propName] then
    return true
  end

  local runtimeName = runtimePropertyName(propName)

  if runtimeName == "MaterialVariant" and value == "" then
    return true
  end

  if typeID == 18 and type(value) == "number" then
    if setEnumFromValue(obj, runtimeName, value) then
      return true
    end
  end

  return pcall(function() obj[runtimeName] = value end)
end

local function assetIdFromValue(v)
  if v == nil then
    return nil
  end

  if type(v) == "number" then
    if v > 0 then
      return math.floor(v)
    end

    return nil
  end

  if type(v) == "string" then
    local id = v:match("rbxassetid://(%d+)") or v:match("[?&]id=(%d+)") or v:match("(%d+)")
    return id and tonumber(id) or nil
  end

  local okUri, uri = pcall(function()
    if typeof(v) == "Content" and v.Uri then
      return v.Uri
    end

    return tostring(v)
  end)

  if okUri and uri then
    local id = tostring(uri):match("(%d+)")
    return id and tonumber(id) or nil
  end

  return nil
end

local function contentFromAssetIdCompat(id)
  if not id then
    return nil
  end

  local okContent, content = pcall(function()
    if Content and type(Content.fromAssetId) == "function" then
      return Content.fromAssetId(id)
    end

    if Content and type(Content.fromUri) == "function" then
      return Content.fromUri("rbxassetid://" .. tostring(id))
    end

    return nil
  end)

  if okContent and content then
    return content
  end

  return "rbxassetid://" .. tostring(id)
end

local function detachFirstGeometry(root, wantedClass)
  if not root then
    return nil
  end

  local candidate

  if root:IsA("BasePart") then
    if not wantedClass or root.ClassName == wantedClass then
      candidate = root
    end
  end

  if not candidate then
    for _, d in ipairs(root:GetDescendants()) do
      if d:IsA("BasePart") then
        if not wantedClass or d.ClassName == wantedClass then
          candidate = d
          break
        end
      end
    end
  end

  if not candidate and root:IsA("BasePart") then
    candidate = root
  end

  if not candidate then
    for _, d in ipairs(root:GetDescendants()) do
      if d:IsA("BasePart") then
        candidate = d
        break
      end
    end
  end

  if not candidate then
    return nil
  end

  candidate.Parent = nil

  if root ~= candidate then
    pcall(function() root:Destroy() end)
  end

  return candidate
end

local function tryGameGetObjectsGeometry(id, wantedClass)
  if not id then
    return nil
  end

  local ok, objects = pcall(function()
    return game:GetObjects("rbxassetid://" .. tostring(id))
  end)

  if not ok or type(objects) ~= "table" then
    return nil
  end

  for _, root in ipairs(objects) do
    local geo = detachFirstGeometry(root, wantedClass)

    if geo then
      for _, other in ipairs(objects) do
        if other ~= geo and other.Parent == nil then
          pcall(function() other:Destroy() end)
        end
      end

      return geo
    end
  end

  for _, root in ipairs(objects) do
    pcall(function() root:Destroy() end)
  end

  return nil
end

local function tryAssetServiceMesh(id)
  if not id then
    return nil, "no mesh id"
  end

  local content = contentFromAssetIdCompat(id)
  local errors = {}
  local ok1, mesh1 = pcall(function() return AssetService:CreateMeshPartAsync(content, {}) end)

  if ok1 and mesh1 and mesh1:IsA("MeshPart") then
    return mesh1, "AssetService"
  end

  if not ok1 then
    table.insert(errors, tostring(mesh1))
  end

  local ok2, mesh2 = pcall(function()
    return AssetService:CreateMeshPartAsync("rbxassetid://" .. tostring(id), {})
  end)

  if ok2 and mesh2 and mesh2:IsA("MeshPart") then
    return mesh2, "AssetServiceLegacy"
  end

  if not ok2 then
    table.insert(errors, tostring(mesh2))
  end

  local getObj = tryGameGetObjectsGeometry(id, "MeshPart")

  if getObj and getObj:IsA("BasePart") then
    return getObj, "GetObjects"
  end

  return nil, table.concat(errors, " | ")
end

local function serializedSize(p)
  if not p then
    return nil
  end

  local s = p.size or p.Size

  if typeof(s) == "Vector3" then
    return Vector3.new(
      math.max(math.abs(s.X), 0.001), math.max(math.abs(s.Y), 0.001),
      math.max(math.abs(s.Z), 0.001)
    )
  end

  return nil
end

local function serializedColor(p)
  if not p then
    return nil
  end

  local c = p.Color3uint8 or p.Color

  if typeof(c) == "Color3" then
    return c
  end

  return nil
end

local function applyBaseVisualState(obj, p)
  if not obj or not obj:IsA("BasePart") or not p then
    return
  end

  local s = serializedSize(p)

  if s then
    pcall(function() obj.Size = s end)
  end

  if typeof(p.CFrame) == "CFrame" then
    pcall(function() obj.CFrame = p.CFrame end)
  end

  local c = serializedColor(p)

  if c then
    pcall(function() obj.Color = c end)
  end

  if p.Transparency ~= nil then
    pcall(function() obj.Transparency = p.Transparency end)
  end

  if p.Reflectance ~= nil then
    pcall(function() obj.Reflectance = p.Reflectance end)
  end

  if p.Material ~= nil and type(p.Material) == "number" then
    pcall(function() setEnumFromValue(obj, "Material", p.Material) end)
  end

  if type(p.Anchored) == "boolean" then
    pcall(function() obj.Anchored = p.Anchored end)
  end
end

local function configureSpecialMeshScale(mesh, p)
  if not mesh or not p then
    return
  end

  local wantedSize = serializedSize(p)
  local originalSize = p.InitialSize or p.MeshSize

  if wantedSize and typeof(originalSize) == "Vector3" and math.abs(originalSize.X) > 0.000001
    and math.abs(originalSize.Y) > 0.000001 and math.abs(originalSize.Z) > 0.000001 then
    mesh.Scale = Vector3.new(
      wantedSize.X / originalSize.X, wantedSize.Y / originalSize.Y,
      wantedSize.Z / originalSize.Z
    )
  else
    mesh.Scale = Vector3.new(1, 1, 1)
  end
end

local function makeSpecialMeshFallback(node, meshId)
  local p = node.Properties or {}

  local part = Instance.new("Part")
  part.Name = tostring(p.Name or "MeshPart")
  part.CanCollide = false

  applyBaseVisualState(part, p)

  local mesh = Instance.new("SpecialMesh")
  mesh.Name = "__XYUREI_MeshVisual"
  mesh.MeshType = Enum.MeshType.FileMesh
  mesh.MeshId = "rbxassetid://" .. tostring(meshId)

  local texId = assetIdFromValue(p.TextureID or p.TextureId or p.TextureContent)

  if texId then
    pcall(function() mesh.TextureId = "rbxassetid://" .. tostring(texId) end)
  end

  configureSpecialMeshScale(mesh, p)
  mesh.Parent = part
  return part
end

local function isMeshPartOnlyChildClass(className)
  return className == "SurfaceAppearance" or className == "WrapLayer"
    or className == "WrapTarget"
end

local function nodeNeedsNativeMeshPart(node)
  for _, child in ipairs(node.Children or {}) do
    if child.ClassName == "WrapLayer" or child.ClassName == "WrapTarget" then
      return true
    end
  end

  return false
end

local function tryCreateMeshPartNode(node)
  local p = node.Properties or {}
  local meshId = assetIdFromValue(p.MeshId or p.MeshID or p.MeshContent)

  if not meshId then
    return nil, "unresolved", "MeshId missing"
  end

  queueServerLoad(meshId)
  queueServerLoad(p.TextureID or p.TextureId or p.TextureContent)

  local needsNative = nodeNeedsNativeMeshPart(node)

  if FAST_IMPORT and not needsNative then
    return makeSpecialMeshFallback(node, meshId), "fallback", "TurboSpecialMesh"
  end

  local native, method = tryAssetServiceMesh(meshId)

  if native then
    return native, "native", needsNative and "NativeForBaseWrap" or method
  end

  local fallback = makeSpecialMeshFallback(node, meshId)
  return fallback, "fallback", needsNative and "BaseWrapFallback" or "SpecialMesh"
end

local function makeCSGVisualFallback(node, assetId)
  local p = node.Properties or {}

  local part = Instance.new("Part")
  part.Name = tostring(p.Name or node.ClassName)
  part.CanCollide = false

  applyBaseVisualState(part, p)

  if assetId then
    local mesh = Instance.new("SpecialMesh")
    mesh.Name = "__XYUREI_CSGVisual"
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = "rbxassetid://" .. tostring(assetId)

    configureSpecialMeshScale(mesh, p)
    mesh.Parent = part
  end

  return part
end

local function tryLoadPartOperationNode(node)
  local p = node.Properties or {}
  local assetId = assetIdFromValue(p.AssetId)

  if assetId then
    queueServerLoad(assetId)

    if FAST_IMPORT then
      return makeCSGVisualFallback(node, assetId), "visual"
    end

    local obj = tryGameGetObjectsGeometry(assetId, node.ClassName)

    if obj then
      applyBaseVisualState(obj, p)
      return obj, "asset"
    end

    local meshPart = tryAssetServiceMesh(assetId)

    if meshPart and meshPart:IsA("BasePart") then
      applyBaseVisualState(meshPart, p)
      return meshPart, "mesh"
    end

    return makeCSGVisualFallback(node, assetId), "visual"
  end

  return makeCSGVisualFallback(node, nil), "proxy"
end

local function preloadNodeAssets(node)
  if not node or not node.Properties then
    return
  end

  local p = node.Properties

  if node.ClassName == "MeshPart" then
    queueServerLoad(p.MeshId or p.MeshContent)
    queueServerLoad(p.TextureID or p.TextureId or p.TextureContent)
  elseif node.ClassName == "SpecialMesh" then
    queueServerLoad(p.MeshId)
    queueServerLoad(p.TextureId or p.TextureID)
  elseif node.ClassName == "Decal" or node.ClassName == "Texture" then
    queueServerLoad(p.Texture)
  elseif node.ClassName == "Shirt" then
    queueServerLoad(p.ShirtTemplate)
  elseif node.ClassName == "Pants" then
    queueServerLoad(p.PantsTemplate)
  elseif node.ClassName == "ShirtGraphic" then
    queueServerLoad(p.Graphic)
  elseif node.ClassName == "UnionOperation" or node.ClassName == "PartOperation"
    or node.ClassName == "IntersectOperation" then
    queueServerLoad(p.AssetId)
  end
end

local function setScriptEnabledState(obj, enabled)
  if not obj or not obj:IsA("LuaSourceContainer") then
    return false
  end

  enabled = enabled ~= false
  local wrote = false
  local okEnabled = pcall(function() obj.Enabled = enabled end)

  if okEnabled then
    wrote = true
  end

  local okDisabled = pcall(function() obj.Disabled = not enabled end)

  if okDisabled then
    wrote = true
  end

  return wrote
end

local function getOriginalScriptEnabled(obj, node)
  local p = node and node.Properties or {}

  if p.Enabled ~= nil then
    return p.Enabled == true
  end

  if p.Disabled ~= nil then
    return p.Disabled ~= true
  end

  local okEnabled, enabled = pcall(function() return obj.Enabled end)

  if okEnabled and type(enabled) == "boolean" then
    return enabled
  end

  local okDisabled, disabled = pcall(function() return obj.Disabled end)

  if okDisabled and type(disabled) == "boolean" then
    return not disabled
  end

  return true
end

local function importedScriptShouldRun(obj)
  if not obj or not obj:IsA("LuaSourceContainer") then
    return false
  end

  local originalEnabled = obj:GetAttribute("XYUREI_OriginalEnabled")

  if originalEnabled ~= nil then
    return originalEnabled == true
  end

  local legacyDisabled = obj:GetAttribute("XYUREI_OriginalDisabled")

  if legacyDisabled ~= nil then
    return legacyDisabled == false
  end

  return true
end

local function importRootName(fileName)
  local base = tostring(fileName or "RBXL")
  base = base:gsub("%.[Rr][Bb][Xx][Ll][Xx]?$", "")
  base = base:gsub("[%c/\\:*?\"<>|]", "_")
  base = base:gsub("^%s+", ""):gsub("%s+$", "")

  if base == "" then
    base = "RBXL"
  end

  return base .. " IMPORTER"
end

local function reportImportProgress(value, message)
  local cb = _G.XYUREI_IMPORT_PROGRESS_CB

  if type(cb) == "function" then
    pcall(cb, value, message)
  end
end

local function buildRBXL(parsed, sourceFileName)
  local made = {}
  local skipped = 0
  local failedProperties = 0

  local progressTotal = math.max(
    tonumber(parsed.Header and parsed.Header.InstanceCount) or 1, 1
  )

  local progressMade = 0
  reportImportProgress(0.2, "BUILDING INSTANCES")
  local meshNative = 0
  local meshFallback = 0
  local meshUnresolved = 0
  local csgAsset = 0
  local csgProxy = 0
  local rootName = importRootName(sourceFileName)
  local oldRoot = workspace:FindFirstChild(rootName)

  if oldRoot then
    pcall(function() oldRoot:Destroy() end)
  end

  local importRoot = Instance.new("Folder")
  importRoot.Name = rootName
  importRoot:SetAttribute("XYUREI_RBXL_IMPORT", true)
  importRoot:SetAttribute("XYUREI_SourceFile", tostring(sourceFileName or ""))
  importRoot:SetAttribute("XYUREI_InMemoryStaging", true)
  importRoot.Parent = nil

  local containers = {}

  local function newServiceFolder(key, displayName)
    local folder = Instance.new("Folder")
    folder.Name = displayName
    folder:SetAttribute("XYUREI_ServiceKey", key)
    folder.Parent = importRoot

    containers[key] = folder
    return folder
  end

  newServiceFolder("WS", "workspace(ws)")
  newServiceFolder("RS", "replicate storage(rs)")
  newServiceFolder("RF", "replicate first(rf)")
  newServiceFolder("L", "lighting(l)")
  newServiceFolder("P", "players(p)")
  newServiceFolder("SG", "starter gui(sg)")
  newServiceFolder("STP", "starter pack(stp)")
  newServiceFolder("SP", "starter player(sp)")
  newServiceFolder("SPS", "starter player script(sps)")
  newServiceFolder("SCS", "starter character script(scs)")
  newServiceFolder("SSS", "serverscriptservice(sss)")
  newServiceFolder("SS", "server storage(ss)")
  newServiceFolder("TEAM", "teams(team)")
  newServiceFolder("SND", "sound service(sound)")
  newServiceFolder("MAT", "material service(mat)")
  newServiceFolder("TCS", "text chat service(tcs)")
  newServiceFolder("CHAT", "chat(chat)")
  newServiceFolder("LOC", "localization service(loc)")
  newServiceFolder("TEST", "test service(test)")
  newServiceFolder("HTTP", "http service(http)")
  newServiceFolder("INS", "insert service(ins)")
  newServiceFolder("TWEEN", "tween service(tween)")

  local serviceKeyByName = {
    Workspace = "WS",
    ReplicatedStorage = "RS",
    ReplicatedFirst = "RF",
    Lighting = "L",
    Players = "P",
    StarterGui = "SG",
    StarterPack = "STP",
    StarterPlayer = "SP",
    StarterPlayerScripts = "SPS",
    StarterCharacterScripts = "SCS",
    ServerScriptService = "SSS",
    ServerStorage = "SS",
    Teams = "TEAM",
    SoundService = "SND",
    MaterialService = "MAT",
    TextChatService = "TCS",
    Chat = "CHAT",
    LocalizationService = "LOC",
    TestService = "TEST",
    HttpService = "HTTP",
    InsertService = "INS",
    TweenService = "TWEEN",
  }

  local function routeForNode(node, inheritedKey)
    local className = tostring(node.ClassName or "")
    local nodeName = tostring(node.Properties and node.Properties.Name or "")
    local direct = serviceKeyByName[className] or serviceKeyByName[nodeName]

    if direct then
      return direct
    end

    if inheritedKey == "SP" then
      if className == "StarterPlayerScripts" or nodeName == "StarterPlayerScripts" then
        return "SPS"
      elseif className == "StarterCharacterScripts" or nodeName == "StarterCharacterScripts" then
        return "SCS"
      end
    end

    return inheritedKey or "WS"
  end

  local function rememberStudioLiteState(obj, node)
    if not obj:IsA("BasePart") then
      return
    end

    local p = node.Properties or {}
    local originalAnchored

    if type(p.Anchored) == "boolean" then
      originalAnchored = p.Anchored
    else
      pcall(function() originalAnchored = obj.Anchored end)
    end

    if originalAnchored == nil then
      originalAnchored = false
    end

    local originalCanCollide

    if type(p.CanCollide) == "boolean" then
      originalCanCollide = p.CanCollide
    else
      pcall(function() originalCanCollide = obj.CanCollide end)
    end

    if originalCanCollide == nil then
      originalCanCollide = true
    end

    pcall(function()
      obj:SetAttribute("SL_Anchored", originalAnchored)
      obj:SetAttribute("XYUREI_FileAnchored", originalAnchored)
      obj:SetAttribute("SL_CanCollide", originalCanCollide)
      obj.Anchored = true
    end)
  end

  local function disableImportedScript(obj, node)
    if not obj:IsA("LuaSourceContainer") then
      return
    end

    local originalEnabled = getOriginalScriptEnabled(obj, node)

    pcall(function()
      obj:SetAttribute("XYUREI_OriginalEnabled", originalEnabled)
      obj:SetAttribute("XYUREI_OriginalDisabled", not originalEnabled)
      obj:SetAttribute("XYUREI_StagedDisabled", true)
    end)

    setScriptEnabledState(obj, false)
  end

  local function normalizePartGeometry(obj, node)
    if not obj:IsA("BasePart") then
      return
    end

    local p = node.Properties or {}
    applyBaseVisualState(obj, p)

    local special = obj:FindFirstChild("__XYUREI_MeshVisual")
      or obj:FindFirstChild("__XYUREI_CSGVisual")

    if special and special:IsA("SpecialMesh") then
      configureSpecialMeshScale(special, p)
    end
  end

  local function instantiateNode(node)
    if node.ClassName == "MeshPart" then
      local obj, mode = tryCreateMeshPartNode(node)

      if obj then
        if mode == "native" then
          meshNative = meshNative + 1
        elseif mode == "fallback" then
          meshFallback = meshFallback + 1
        else
          meshUnresolved = meshUnresolved + 1
        end

        return obj
      end

      meshUnresolved = meshUnresolved + 1
      return nil
    end

    if node.ClassName == "UnionOperation" or node.ClassName == "PartOperation"
      or node.ClassName == "IntersectOperation" then
      local obj, mode = tryLoadPartOperationNode(node)

      if obj then
        if mode == "asset" or mode == "mesh" or mode == "visual" then
          csgAsset = csgAsset + 1
        else
          csgProxy = csgProxy + 1
        end

        return obj
      end

      csgProxy = csgProxy + 1
      return nil
    end

    local ok, obj = pcall(Instance.new, node.ClassName)

    if ok then
      return obj
    end

    return nil
  end

  local buildBurstCount = 0

  local function createNode(node, parent, inheritedKey)
    local routeKey = routeForNode(node, inheritedKey)

    if isMeshPartOnlyChildClass(node.ClassName) and (not parent or not parent:IsA("MeshPart")) then
      skipped = skipped + 1
      return nil
    end

    local nodeName = tostring(node.Properties and node.Properties.Name or "")

    local isServiceLike = node.IsService or node.Service or serviceKeyByName[node.ClassName]
      or serviceKeyByName[nodeName]

    if isServiceLike then
      local target = containers[routeKey] or containers.WS

      for _, child in ipairs(node.Children) do
        local childKey = routeForNode(child, routeKey)
        createNode(child, target, childKey)
      end

      return nil
    end

    preloadNodeAssets(node)
    local obj = instantiateNode(node)

    if not obj then
      skipped = skipped + 1

      for _, child in ipairs(node.Children) do
        createNode(child, parent or containers[routeKey] or containers.WS, routeKey)
      end

      return nil
    end

    made[node.Ref] = obj

    pcall(function()
      obj:SetAttribute("XYUREI_ImportedObject", true)
      obj:SetAttribute("XYUREI_Ref", tostring(node.Ref))
    end)

    if node.Properties.Name ~= nil then
      local okName = pcall(function() obj.Name = tostring(node.Properties.Name) end)

      if not okName then
        failedProperties = failedProperties + 1
      end
    end

    for propName, value in pairs(node.Properties) do
      if propName ~= "Name" then
        local okProp = applyDecodedProperty(
          obj, propName, value, node.PropertyTypes and node.PropertyTypes[propName]
        )

        if not okProp then
          failedProperties = failedProperties + 1
        end
      end
    end

    rememberStudioLiteState(obj, node)
    disableImportedScript(obj, node)
    normalizePartGeometry(obj, node)
    obj.Parent = parent or containers[routeKey] or containers.WS
    buildBurstCount = buildBurstCount + 1
    progressMade = progressMade + 1

    if progressMade == 1 or progressMade % 120 == 0 then
      local ratio = math.min(progressMade / progressTotal, 1)

      reportImportProgress(
        0.2 + ratio * 0.55, ("GENERATING %d / %d"):format(progressMade, progressTotal)
      )
    end

    if buildBurstCount >= 600 then
      buildBurstCount = 0
      task.wait()
    end

    for _, child in ipairs(node.Children) do
      local meshPartOnly = isMeshPartOnlyChildClass(child.ClassName)

      if not (meshPartOnly and not obj:IsA("MeshPart")) then
        createNode(child, obj, routeKey)
      else
        skipped = skipped + 1
      end
    end

    return obj
  end

  for _, root in ipairs(parsed.Roots) do
    local key = routeForNode(root, "WS")
    local rootNameProp = tostring(root.Properties and root.Properties.Name or "")

    if root.IsService or root.Service or serviceKeyByName[root.ClassName]
      or serviceKeyByName[rootNameProp] then
      createNode(root, containers[key], key)
    else
      createNode(root, containers.WS, "WS")
    end
  end

  for ref, node in pairs(parsed.Nodes) do
    local obj = made[ref]

    if obj and node.PropertyTypes then
      for propName, typeID in pairs(node.PropertyTypes) do
        if typeID == 19 then
          local targetRef = node.Properties[propName]
          local targetObj = made[targetRef]

          if targetObj then
            local okRef = pcall(function() obj[propName] = targetObj end)

            if not okRef then
              failedProperties = failedProperties + 1
            end
          end
        elseif typeID == 34 then
          local contentValue = node.Properties[propName]

          if type(contentValue) == "table" and contentValue.__ContentObjectRef then
            local targetObj = made[contentValue.__ContentObjectRef]

            if targetObj then
              local okRef = pcall(function() obj[propName] = targetObj end)

              if not okRef then
                failedProperties = failedProperties + 1
              end
            end
          end
        end
      end
    end
  end

  for ref, node in pairs(parsed.Nodes) do
    local obj = made[ref]

    if obj and obj:IsA("BasePart") then
      normalizePartGeometry(obj, node)
      pcall(function() obj.Anchored = true end)
    end
  end

  task.spawn(function()
    local scriptBatch = 0

    for _, obj in pairs(made) do
      if obj and obj.Parent and obj:IsA("LuaSourceContainer") then
        pcall(function() injectStudioLiteUI(obj, {}) end)
        scriptBatch = scriptBatch + 1

        if scriptBatch >= 40 then
          scriptBatch = 0
          task.wait()
        end
      end
    end
  end)

  flushServerLoadsAsync()
  local madeCount = 0

  for _ in pairs(made) do
    madeCount = madeCount + 1
  end

  reportImportProgress(0.78, ("BUILD COMPLETE • %d INSTANCES"):format(madeCount))
  return madeCount, skipped, failedProperties, meshNative, meshFallback, meshUnresolved, csgAsset, csgProxy, importRoot
end

local function safeReadFile(path)
  if type(readfile) ~= "function" then
    return nil, "readfile tidak tersedia"
  end

  local ok, data = pcall(readfile, path)

  if not ok then
    return nil, tostring(data)
  end

  if type(data) ~= "string" or #data == 0 then
    return nil, "file kosong / tidak terbaca"
  end

  return data
end

local function xmlDecodeText(value)
  value = tostring(value or "")
  local cdata = value:match("^%s*<!%[CDATA%[(.*)%]%]>%s*$")

  if cdata ~= nil then
    return cdata
  end

  value = value:gsub("&#x([%x]+);", function(hex)
    local n = tonumber(hex, 16)

    if not n then
      return ""
    end

    if n <= 255 then
      return string.char(n)
    end

    if utf8 and utf8.char then
      local ok, ch = pcall(utf8.char, n)

      if ok then
        return ch
      end
    end

    return ""
  end)

  value = value:gsub("&#(%d+);", function(dec)
    local n = tonumber(dec)

    if not n then
      return ""
    end

    if n <= 255 then
      return string.char(n)
    end

    if utf8 and utf8.char then
      local ok, ch = pcall(utf8.char, n)

      if ok then
        return ch
      end
    end

    return ""
  end)

  value = value:gsub("&quot;", "\"")
  value = value:gsub("&apos;", "'")
  value = value:gsub("&lt;", "<")
  value = value:gsub("&gt;", ">")
  value = value:gsub("&amp;", "&")

  return value
end

local function xmlNumber(inner, tag)
  local value = inner:match("<" .. tag .. ">%s*(.-)%s*</" .. tag .. ">")
  return tonumber(value)
end

local function xmlPropertyValue(tag, inner)
  if tag == "string" or tag == "ProtectedString" then
    return xmlDecodeText(inner)
  elseif tag == "BinaryString" or tag == "SharedString" then
    return xmlDecodeText(inner)
  elseif tag == "bool" then
    local v = tostring(inner):match("^%s*(.-)%s*$")
    return v == "true" or v == "1"
  elseif tag == "int" or tag == "int64" or tag == "float" or tag == "double" then
    return tonumber(tostring(inner):match("^%s*(.-)%s*$"))
  elseif tag == "token" then
    return tonumber(tostring(inner):match("^%s*(.-)%s*$")), 18
  elseif tag == "Ref" then
    local target = xmlDecodeText(inner):match("^%s*(.-)%s*$")

    if target == "" or target == "null" then
      return nil, 19
    end

    return { __XMLRef = target }, 19
  elseif tag == "Vector3" then
    local x = xmlNumber(inner, "X") or 0
    local y = xmlNumber(inner, "Y") or 0
    local z = xmlNumber(inner, "Z") or 0
    return Vector3.new(x, y, z)
  elseif tag == "Vector2" then
    local x = xmlNumber(inner, "X") or 0
    local y = xmlNumber(inner, "Y") or 0
    return Vector2.new(x, y)
  elseif tag == "Color3" then
    local r = xmlNumber(inner, "R") or 0
    local g = xmlNumber(inner, "G") or 0
    local b = xmlNumber(inner, "B") or 0
    return Color3.new(r, g, b)
  elseif tag == "Color3uint8" then
    local packed = tonumber(tostring(inner):match("^%s*(%d+)%s*$"))

    if not packed then
      return nil
    end

    local r = math.floor(packed / 65536) % 256
    local g = math.floor(packed / 256) % 256
    local b = packed % 256
    return Color3.fromRGB(r, g, b)
  elseif tag == "CoordinateFrame" or tag == "CFrame" then
    local x = xmlNumber(inner, "X") or 0
    local y = xmlNumber(inner, "Y") or 0
    local z = xmlNumber(inner, "Z") or 0
    local r00 = xmlNumber(inner, "R00") or 1
    local r01 = xmlNumber(inner, "R01") or 0
    local r02 = xmlNumber(inner, "R02") or 0
    local r10 = xmlNumber(inner, "R10") or 0
    local r11 = xmlNumber(inner, "R11") or 1
    local r12 = xmlNumber(inner, "R12") or 0
    local r20 = xmlNumber(inner, "R20") or 0
    local r21 = xmlNumber(inner, "R21") or 0
    local r22 = xmlNumber(inner, "R22") or 1
    return CFrame.new(x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22)
  elseif tag == "OptionalCoordinateFrame" then
    if inner:find("<CFrame>", 1, true) then
      local body = inner:match("<CFrame>(.-)</CFrame>") or inner
      return xmlPropertyValue("CFrame", body)
    end

    return nil
  elseif tag == "UDim" then
    local s = xmlNumber(inner, "S") or 0
    local o = xmlNumber(inner, "O") or 0
    return UDim.new(s, o)
  elseif tag == "UDim2" then
    local xs = xmlNumber(inner, "XS") or 0
    local xo = xmlNumber(inner, "XO") or 0
    local ys = xmlNumber(inner, "YS") or 0
    local yo = xmlNumber(inner, "YO") or 0
    return UDim2.new(xs, xo, ys, yo)
  elseif tag == "BrickColor" then
    local n = tonumber(tostring(inner):match("^%s*(%d+)%s*$"))

    if n then
      local ok, value = pcall(BrickColor.new, n)

      if ok then
        return value
      end
    end

    return nil
  elseif tag == "Content" then
    local url = inner:match("<url>(.-)</url>")

    if url then
      return xmlDecodeText(url)
    end

    if inner:find("<null", 1, true) then
      return ""
    end

    return xmlDecodeText(inner:gsub("<[^>]+>", ""))
  elseif tag == "NumberRange" then
    local min = xmlNumber(inner, "Min")
    local max = xmlNumber(inner, "Max")

    if min ~= nil and max ~= nil then
      return NumberRange.new(min, max)
    end
  elseif tag == "Rect2D" then
    local minBlock = inner:match("<min>(.-)</min>")
    local maxBlock = inner:match("<max>(.-)</max>")

    if minBlock and maxBlock then
      local minX = xmlNumber(minBlock, "X") or 0
      local minY = xmlNumber(minBlock, "Y") or 0
      local maxX = xmlNumber(maxBlock, "X") or 0
      local maxY = xmlNumber(maxBlock, "Y") or 0
      return Rect.new(minX, minY, maxX, maxY)
    end
  elseif tag == "NumberSequence" then
    local numbers = {}

    for n in xmlDecodeText(inner):gmatch("[-+]?[%d%.]+[eE]?[-+]?%d*") do
      local v = tonumber(n)

      if v then
        numbers[#numbers + 1] = v
      end
    end

    if #numbers >= 3 then
      local keypoints = {}

      for i = 1, #numbers - 2, 3 do
        local ok, kp = pcall(
          NumberSequenceKeypoint.new, numbers[i], numbers[i + 1], numbers[i + 2]
        )

        if ok then
          keypoints[#keypoints + 1] = kp
        end
      end

      if #keypoints >= 2 then
        local ok, seq = pcall(NumberSequence.new, keypoints)

        if ok then
          return seq
        end
      end
    end
  elseif tag == "Font" then
    local family = inner:match("<Family>%s*<url>(.-)</url>%s*</Family>")
    local weight = tonumber(inner:match("<Weight>%s*(%d+)%s*</Weight>")) or 400
    local style = inner:match("<Style>%s*(.-)%s*</Style>") or "Normal"

    if family and Font then
      family = xmlDecodeText(family)
      local ew = Enum.FontWeight.Regular
      pcall(function() ew = Enum.FontWeight:FromValue(weight) end)
      local es = Enum.FontStyle.Normal

      if style == "Italic" then
        es = Enum.FontStyle.Italic
      end

      local ok, font = pcall(Font.new, family, ew, es)

      if ok then
        return font
      end
    end
  end

  return nil
end

local function parseRobloxXML(data)
  if type(data) ~= "string" then
    return nil, "XML data bukan string"
  end

  data = data:gsub("^\239\187\191", "")

  if not data:find("<roblox", 1, true) then
    return nil, "XML root <roblox> tidak ditemukan"
  end

  local nodes = {}
  local roots = {}
  local referentToRef = {}
  local nextRef = 1

  local function parseProperties(body, node)
    local pos = 1

    while true do
      local openStart, openEnd, tag, attrs = body:find("<([%w]+)(.-)>", pos)

      if not openStart then
        break
      end

      local propName = attrs:match("name=\"([^\"]+)\"")

      if not propName then
        pos = openEnd + 1
      else
        local closeTag = "</" .. tag .. ">"
        local closeStart, closeEnd = body:find(closeTag, openEnd + 1, true)

        if not closeStart then
          break
        end

        local inner = body:sub(openEnd + 1, closeStart - 1)
        local value, typeID = xmlPropertyValue(tag, inner)

        if value ~= nil then
          node.Properties[propName] = value
        end

        if typeID ~= nil then
          node.PropertyTypes[propName] = typeID
        end

        pos = closeEnd + 1
      end
    end
  end

  local parseItemAt

  parseItemAt = function(startPos)
    local openEnd = data:find(">", startPos, true)

    if not openEnd then
      return nil, startPos, "Item open tag"
    end

    local openTag = data:sub(startPos, openEnd)
    local className = openTag:match("class=\"([^\"]+)\"")
    local referent = openTag:match("referent=\"([^\"]+)\"")

    if not className then
      return nil, openEnd + 1, "Item tanpa class"
    end

    local ref = nextRef
    nextRef = nextRef + 1

    local node = {
      Ref = ref,
      ClassName = xmlDecodeText(className),
      Properties = {},
      PropertyTypes = {},
      Children = {},
      Service = false,
      IsService = false,
      XMLReferent = referent,
    }

    nodes[ref] = node

    if referent and referent ~= "" then
      referentToRef[referent] = ref
    end

    local pos = openEnd + 1

    while pos <= #data do
      local nextTag = data:find("<", pos, true)

      if not nextTag then
        return nil, pos, "Item tidak closing"
      end

      if data:sub(nextTag, nextTag + 6) == "</Item>" then
        return node, nextTag + 7
      elseif data:sub(nextTag, nextTag + 11) == "<Properties>" then
        local closeStart, closeEnd = data:find("</Properties>", nextTag + 12, true)

        if not closeStart then
          return nil, nextTag, "Properties no closing"
        end

        parseProperties(data:sub(nextTag + 12, closeStart - 1), node)
        pos = closeEnd + 1
      elseif data:sub(nextTag, nextTag + 4) == "<Item" then
        local child, newPos, err = parseItemAt(nextTag)

        if not child then
          return nil, newPos, err
        end

        node.Children[#node.Children + 1] = child
        pos = newPos
      elseif data:sub(nextTag, nextTag + 3) == "<!--" then
        local commentEnd = data:find("-->", nextTag + 4, true)
        pos = commentEnd and commentEnd + 3 or #data + 1
      else
        local tagEnd = data:find(">", nextTag, true)
        pos = tagEnd and tagEnd + 1 or #data + 1
      end
    end

    return nil, pos, "Unexpected end of XML"
  end

  local pos = 1

  while true do
    local itemStart = data:find("<Item", pos, true)

    if not itemStart then
      break
    end

    local node, newPos, err = parseItemAt(itemStart)

    if not node then
      return nil, "XML PARSE ERROR: " .. tostring(err)
    end

    roots[#roots + 1] = node
    pos = newPos
  end

  if #roots == 0 then
    return nil, "Roblox XML tidak memiliki Item"
  end

  for _, node in pairs(nodes) do
    for propName, typeID in pairs(node.PropertyTypes) do
      if typeID == 19 then
        local value = node.Properties[propName]

        if type(value) == "table" and value.__XMLRef then
          node.Properties[propName] = referentToRef[value.__XMLRef] or -1
        end
      end
    end
  end

  local serviceNames = {
    Workspace = true,
    Players = true,
    Lighting = true,
    ReplicatedFirst = true,
    ReplicatedStorage = true,
    StarterGui = true,
    StarterPack = true,
    StarterPlayer = true,
    Teams = true,
    ServerScriptService = true,
    ServerStorage = true,
    SoundService = true,
    MaterialService = true,
    TextChatService = true,
    Chat = true,
    LocalizationService = true,
    TestService = true,
    HttpService = true,
    InsertService = true,
    TweenService = true,
  }

  for _, root in ipairs(roots) do
    local rootName = tostring(root.Properties.Name or "")

    if serviceNames[root.ClassName] or serviceNames[rootName] then
      root.Service = true
      root.IsService = true
    end
  end

  return {
    Header = { ClassCount = 0, InstanceCount = nextRef - 1, Format = "XML" },
    Nodes = nodes,
    Roots = roots,
    Services = {},
    SharedStrings = {},
  }, nil
end

local function detectRobloxSerialization(data)
  if type(data) ~= "string" or #data == 0 then
    return nil
  end

  if data:sub(1, 14) == "<roblox!" .. string.char(137, 255, 13, 10, 26, 10) then
    return "BINARY"
  end

  local sample = data:sub(1, 4096):gsub("^\239\187\191", "")

  if sample:find("<roblox", 1, true) then
    return "XML"
  end

  return nil
end

local function importRBXL(fileInfo)
  reportImportProgress(0.02, "READING PLACE FILE")
  local data, readErr = safeReadFile(fileInfo.path)
  reportImportProgress(0.08, "PLACE FILE LOADED")

  if not data then
    return false, "READ ERROR: " .. tostring(readErr)
  end

  local serialization = detectRobloxSerialization(data)

  if not serialization then
    return false, "File bukan RBXL/RBXLX yang valid"
  end

  local parsed, parseErr

  if serialization == "BINARY" then
    if type(string.unpack) ~= "function" then
      return false, "COMPAT: string.unpack tidak ada"
    end

    if type(bit32) ~= "table" then
      return false, "COMPAT: bit32 tidak ada"
    end

    reportImportProgress(0.12, "PARSING RBXL BINARY")
    local okParse, result, err = pcall(parseRBXLBinary, data)

    if not okParse then
      return false, "PARSER CRASH: " .. tostring(result)
    end

    parsed, parseErr = result, err
  else
    reportImportProgress(0.12, "PARSING RBXLX XML")
    local okParse, result, err = pcall(parseRobloxXML, data)

    if not okParse then
      return false, "XML PARSER CRASH: " .. tostring(result)
    end

    parsed, parseErr = result, err
  end

  if not parsed then
    return false, "PARSE ERROR: " .. tostring(parseErr or "unknown")
  end

  reportImportProgress(0.18, ("PARSED %s • %d INSTANCES"):format(serialization, tonumber(parsed.Header
      and parsed.Header.InstanceCount)
    or 0))

  local okBuild, madeCount, skipped, failedProperties, meshNative, meshFallback, meshUnresolved, csgAsset, csgProxy, importRoot = pcall(
    buildRBXL, parsed, fileInfo.name
  )

  if not okBuild then
    return false, "BUILD ERROR: " .. tostring(madeCount)
  end

  local rootLabel = importRoot and importRoot.Name or importRootName(fileInfo.name)

  return true, ("%s OK %d | %s | mesh N:%d F:%d U:%d | CSG A:%d P:%d | prop:%d"):format(serialization, madeCount or 0, rootLabel, meshNative or 0, meshFallback
    or 0, meshUnresolved
    or 0, csgAsset or 0, csgProxy or 0, failedProperties
    or 0), importRoot
end

local function collectRBXMSources(parsed)
  local queues = {}

  local function add(node)
    local p = node.Properties or {}
    local source = p.Source or p.ContentText

    if type(source) == "string" and source ~= "" then
      source = source:gsub(string.char(0) .. "*$", "")
      local key = tostring(node.ClassName or "") .. "\0" .. tostring(p.Name or "")

      queues[key] = queues[key] or {}
      queues[key][#queues[key] + 1] = source
    end

    for _, child in ipairs(node.Children or {}) do
      add(child)
    end
  end

  for _, root in ipairs(parsed.Roots or {}) do
    add(root)
  end

  return queues
end

local function takeRBXMSource(sourceQueues, obj)
  local key = obj.ClassName .. "\0" .. obj.Name
  local queue = sourceQueues[key]

  if not queue or #queue == 0 then
    return nil
  end

  local source = queue[1]
  table.remove(queue, 1)
  return source
end

local function tryWriteRBXMSource(scr, source)
  if not scr or not scr:IsA("LuaSourceContainer") or type(source) ~= "string" or source == "" then
    return false
  end

  _G.XYUREI_RAW_SOURCES[scr] = source
  local refKey = scr:GetAttribute("XYUREI_Ref")

  if refKey ~= nil then
    _G.XYUREI_RAW_SOURCE_BY_REF[tostring(refKey)] = source
  end

  if type(setscriptable) == "function" then
    pcall(setscriptable, scr, "Source", true)
  end

  return pcall(function() scr.Source = source end)
end

local function queueAssetsFromRBXM(root)
  local all = { root }

  for _, d in ipairs(root:GetDescendants()) do
    all[#all + 1] = d
  end

  for _, obj in ipairs(all) do
    pcall(function()
      if obj:IsA("MeshPart") then
        queueServerLoad(obj.MeshId)
        queueServerLoad(obj.TextureID)
      elseif obj:IsA("SpecialMesh") then
        queueServerLoad(obj.MeshId)
        queueServerLoad(obj.TextureId)
      elseif obj:IsA("Decal") or obj:IsA("Texture") then
        queueServerLoad(obj.Texture)
      elseif obj:IsA("Shirt") then
        queueServerLoad(obj.ShirtTemplate)
      elseif obj:IsA("Pants") then
        queueServerLoad(obj.PantsTemplate)
      elseif obj:IsA("ShirtGraphic") then
        queueServerLoad(obj.Graphic)
      elseif obj:IsA("UnionOperation") or obj:IsA("PartOperation")
        or obj:IsA("IntersectOperation") then
        queueServerLoad(obj.AssetId)
      end
    end)
  end
end

local function buildRBXModelParsed(parsed, sourceFileName)
  local made = {}
  local importedRoots = {}
  local skipped = 0
  local failedProperties = 0

  local function instantiateModelNode(node)
    if node.ClassName == "MeshPart" then
      local obj = tryCreateMeshPartNode(node)

      if obj then
        return obj
      end
    elseif node.ClassName == "UnionOperation" or node.ClassName == "PartOperation"
      or node.ClassName == "IntersectOperation" then
      local obj = tryLoadPartOperationNode(node)

      if obj then
        return obj
      end
    end

    local ok, obj = pcall(Instance.new, node.ClassName)

    if ok then
      return obj
    end

    return nil
  end

  local function createNode(node, parent)
    preloadNodeAssets(node)
    local obj = instantiateModelNode(node)

    if not obj then
      skipped = skipped + 1

      for _, child in ipairs(node.Children or {}) do
        createNode(child, parent)
      end

      return nil
    end

    made[node.Ref] = obj

    pcall(function()
      obj:SetAttribute("XYUREI_ImportedObject", true)
      obj:SetAttribute("XYUREI_Ref", tostring(node.Ref))
      obj:SetAttribute("XYUREI_RBXMSource", tostring(sourceFileName or ""))
    end)

    if node.Properties and node.Properties.Name ~= nil then
      pcall(function() obj.Name = tostring(node.Properties.Name) end)
    end

    for propName, value in pairs(node.Properties or {}) do
      if propName ~= "Name" then
        local okProp = applyDecodedProperty(
          obj, propName, value, node.PropertyTypes and node.PropertyTypes[propName]
        )

        if not okProp then
          failedProperties = failedProperties + 1
        end
      end
    end

    if obj:IsA("BasePart") then
      local original = obj.Anchored

      if node.Properties and type(node.Properties.Anchored) == "boolean" then
        original = node.Properties.Anchored
      end

      pcall(function()
        obj:SetAttribute("XYUREI_FileAnchored", original)
        obj:SetAttribute("XYUREI_AutoAnchored", true)
        obj.Anchored = true
      end)
    end

    obj.Parent = parent

    for _, child in ipairs(node.Children or {}) do
      if not (isMeshPartOnlyChildClass(child.ClassName) and not obj:IsA("MeshPart")) then
        createNode(child, obj)
      else
        skipped = skipped + 1
      end
    end

    return obj
  end

  for _, root in ipairs(parsed.Roots or {}) do
    local obj = createNode(root, nil)

    if obj then
      obj.Parent = workspace
      importedRoots[#importedRoots + 1] = obj
    end
  end

  for ref, node in pairs(parsed.Nodes or {}) do
    local obj = made[ref]

    if obj and node.PropertyTypes then
      for propName, typeID in pairs(node.PropertyTypes) do
        if typeID == 19 then
          local target = made[node.Properties[propName]]

          if target then
            pcall(function() obj[propName] = target end)
          end
        end
      end
    end
  end

  for ref, obj in pairs(made) do
    local node = parsed.Nodes and parsed.Nodes[ref]

    if obj:IsA("LuaSourceContainer") and node then
      local source = node.Properties and (node.Properties.Source or node.Properties.ContentText)

      if type(source) == "string" and source ~= "" then
        pcall(function() tryWriteRBXMSource(obj, source) end)
      end

      pcall(function() injectStudioLiteUI(obj, {}) end)
    end

    if obj:IsA("BasePart") then
      pcall(function()
        obj.Anchored = true
        obj:SetAttribute("XYUREI_AutoAnchored", true)
      end)
    end
  end

  for _, root in ipairs(importedRoots) do
    pcall(function() queueAssetsFromRBXM(root) end)
  end

  flushServerLoadsAsync()
  local count = 0

  for _ in pairs(made) do
    count = count + 1
  end

  return importedRoots, count, skipped, failedProperties
end

local function importRBXM(fileInfo)
  reportImportProgress(0.02, "READING RBXM")
  local data, readErr = safeReadFile(fileInfo.path)

  if not data then
    return false, "READ ERROR: " .. tostring(readErr)
  end

  reportImportProgress(0.1, "MODEL FILE LOADED")
  local serialization = detectRobloxSerialization(data)

  if not serialization then
    return false, "File bukan RBXM/RBXMX yang valid"
  end

  if serialization == "XML" then
    reportImportProgress(0.16, "PARSING RBXMX XML")
    local okParsed, parsed, parseErr = pcall(parseRobloxXML, data)

    if not okParsed then
      return false, "XML PARSER CRASH: " .. tostring(parsed)
    end

    if not parsed then
      return false, "RBXMX PARSE ERROR: " .. tostring(parseErr or "unknown")
    end

    reportImportProgress(0.34, "BUILDING RBXMX MODEL")

    local okBuild, roots, count, skipped, failedProperties = pcall(
      buildRBXModelParsed, parsed, fileInfo.name
    )

    if not okBuild then
      return false, "RBXMX BUILD ERROR: " .. tostring(roots)
    end

    reportImportProgress(1, "RBXMX GENERATION COMPLETE")

    return true, ("RBXMX XML OK • %d object(s) • skipped:%d • prop:%d"):format(count or 0, skipped or 0, failedProperties
      or 0), roots and roots[1] or nil
  end

  local sourceQueues = {}
  local parsedBin, parsedBinErr

  if serialization == "BINARY" then
    reportImportProgress(0.15, "PARSING RBXM SOURCES")
    local okParsed, parsed, perr = pcall(parseRBXLBinary, data)

    if okParsed and parsed then
      parsedBin = parsed
      sourceQueues = collectRBXMSources(parsed)
    else
      parsedBinErr = tostring(okParsed and perr or parsed)
    end
  end

  reportImportProgress(0.24, "REGISTERING RBXM ASSET")
  local objects
  local loadMethod = "unknown"

  if type(getcustomasset) == "function" then
    local okAsset, customAsset = pcall(getcustomasset, fileInfo.path)

    if okAsset and customAsset then
      local okObjects, result = pcall(function() return game:GetObjects(customAsset) end)

      if okObjects and type(result) == "table" and #result > 0 then
        objects = result
        loadMethod = "getcustomasset"
      end
    end
  end

  if not objects then
    local okObjects, result = pcall(function()
      return game:GetObjects("rbxasset://" .. tostring(fileInfo.path))
    end)

    if okObjects and type(result) == "table" and #result > 0 then
      objects = result
      loadMethod = "rbxasset"
    end
  end

  if not objects then
    if parsedBin then
      reportImportProgress(0.3, "FALLBACK PARSER BAWAAN")

      local okBuild, roots, count, skipped, failedProperties = pcall(
        buildRBXModelParsed, parsedBin, fileInfo.name
      )

      if okBuild and type(roots) == "table" and #roots > 0 then
        reportImportProgress(1, "RBXM GENERATION COMPLETE")

        return true, ("RBXM OK (parser bawaan) • %d object(s) • skipped:%d • prop:%d"):format(count
          or 0, skipped
          or 0, failedProperties
          or 0), roots[1]
      end

      return false, "RBXM BUILD ERROR: "
        .. tostring(okBuild and "tidak ada objek yang terbuat" or roots)
    end

    return false, "RBXM LOAD ERROR: getcustomasset/GetObjects gagal, parser bawaan juga gagal ("
      .. tostring(parsedBinErr or "?") .. ")"
  end

  reportImportProgress(0.4, ("RBXM OPENED • %d ROOT"):format(#objects))
  local importedRoots = {}
  local totalObjects = 0
  local sourceFound = 0
  local sourceWritten = 0
  local editorRestored = 0
  local scriptCount = 0

  for rootIndex, root in ipairs(objects) do
    if typeof(root) == "Instance" then
      root:SetAttribute("XYUREI_ImportedObject", true)
      root:SetAttribute("XYUREI_RBXMSource", fileInfo.name)
      root.Parent = workspace

      importedRoots[#importedRoots + 1] = root

      if root:IsA("BasePart") then
        local savedAnchored = root.Anchored

        root:SetAttribute("XYUREI_FileAnchored", savedAnchored)
        root:SetAttribute("XYUREI_AutoAnchored", true)
        root.Anchored = true
      end

      local descendants = root:GetDescendants()

      for _, part in ipairs(descendants) do
        if part:IsA("BasePart") then
          local savedAnchored = part.Anchored

          part:SetAttribute("XYUREI_FileAnchored", savedAnchored)
          part:SetAttribute("XYUREI_AutoAnchored", true)
          part.Anchored = true
        end
      end

      totalObjects = totalObjects + (#descendants + 1)
      local all = { root }

      for _, obj in ipairs(descendants) do
        all[#all + 1] = obj
      end

      for i, obj in ipairs(all) do
        obj:SetAttribute("XYUREI_ImportedObject", true)

        if obj:IsA("LuaSourceContainer") then
          scriptCount = scriptCount + 1
          local source = takeRBXMSource(sourceQueues, obj)

          if source then
            sourceFound = sourceFound + 1
            _G.XYUREI_RAW_SOURCES[obj] = source
            local wrote = tryWriteRBXMSource(obj, source)

            if wrote then
              sourceWritten = sourceWritten + 1
            end

            local okEditor = pcall(function() injectStudioLiteUI(obj, {}) end)

            if okEditor then
              editorRestored = editorRestored + 1
            end
          end
        end

        if i % 180 == 0 then
          task.wait()
        end
      end

      queueAssetsFromRBXM(root)
    end

    local ratio = rootIndex / math.max(#objects, 1)

    reportImportProgress(
      0.4 + ratio * 0.45, ("IMPORTING RBXM ROOT %d / %d"):format(rootIndex, #objects)
    )
  end

  flushServerLoadsAsync()
  reportImportProgress(0.94, "FINALIZING RBXM")

  for _, root in ipairs(importedRoots) do
    for _, obj in ipairs(root:GetDescendants()) do
      if obj:IsA("LuaSourceContainer") then
        local enabled
        local okEnabled = pcall(function() enabled = obj.Enabled end)

        if okEnabled and type(enabled) == "boolean" then
          pcall(function() obj.Enabled = enabled end)
        end
      end
    end
  end

  for _, root in ipairs(importedRoots) do
    if root:IsA("BasePart") then
      pcall(function()
        root.Anchored = true
        root:SetAttribute("XYUREI_AutoAnchored", true)
      end)
    end

    for _, obj in ipairs(root:GetDescendants()) do
      if obj:IsA("BasePart") then
        pcall(function()
          obj.Anchored = true
          obj:SetAttribute("XYUREI_AutoAnchored", true)
        end)
      end
    end
  end

  reportImportProgress(1, "RBXM GENERATION COMPLETE")

  return true, ("RBXM OK • %d objects • %d scripts • source:%d/%d • editor:%d • %s"):format(
    totalObjects, scriptCount, sourceWritten, sourceFound, editorRestored, loadMethod
  ), importedRoots
end

local XYUREI_MODULE_CACHE = setmetatable({}, { __mode = "k" })
local XYUREI_MODULE_LOADING = setmetatable({}, { __mode = "k" })

local function rawSourceFor(scr)
  if not scr or not scr:IsA("LuaSourceContainer") then
    return nil
  end

  local direct = _G.XYUREI_RAW_SOURCES[scr]

  if type(direct) == "string" and direct ~= "" then
    return direct
  end

  local refKey = scr:GetAttribute("XYUREI_Ref")

  if refKey ~= nil then
    local byRef = _G.XYUREI_RAW_SOURCE_BY_REF[tostring(refKey)]

    if type(byRef) == "string" and byRef ~= "" then
      return byRef
    end
  end

  return nil
end

local function canReadExecutableSource(scr)
  local ok, source = pcall(function() return scr.Source end)
  return ok and type(source) == "string" and #source > 0, source
end

local runtimeRequire

local function compileRuntimeSource(scr, source)
  if type(loadstring) ~= "function" then
    return nil, "loadstring tidak tersedia"
  end

  local wrapped = [[
return function(script, require, ...)
]] .. source .. "\nend"

  local okCompile, loaderOrErr = pcall(
    loadstring, wrapped, "=XYUREI_RBXL/" .. tostring(scr:GetFullName())
  )

  if not okCompile or type(loaderOrErr) ~= "function" then
    return nil, tostring(loaderOrErr)
  end

  local okFactory, runnerOrErr = pcall(loaderOrErr)

  if not okFactory or type(runnerOrErr) ~= "function" then
    return nil, tostring(runnerOrErr)
  end

  return runnerOrErr
end

runtimeRequire = function(target)
  if typeof(target) == "Instance" and target:IsA("ModuleScript") then
    if XYUREI_MODULE_CACHE[target] ~= nil then
      return XYUREI_MODULE_CACHE[target]
    end

    if XYUREI_MODULE_LOADING[target] then
      error("XYUREI runtime circular: " .. target:GetFullName())
    end

    local source = rawSourceFor(target)

    if source then
      XYUREI_MODULE_LOADING[target] = true
      local runner, compileErr = compileRuntimeSource(target, source)

      if not runner then
        XYUREI_MODULE_LOADING[target] = nil
        error("Module compile failed: " .. tostring(compileErr))
      end

      local results = table.pack(pcall(runner, target, runtimeRequire))
      XYUREI_MODULE_LOADING[target] = nil

      if not results[1] then
        error(results[2])
      end

      local result = results[2]
      XYUREI_MODULE_CACHE[target] = result
      return result
    end
  end

  return require(target)
end

local function runLocalScriptBridge(scr)
  if not scr or not scr:IsA("LocalScript") then
    return false, "not_local_script"
  end

  if not importedScriptShouldRun(scr) then
    return false, "originally_disabled"
  end

  if scr:GetAttribute("XYUREI_RuntimeStarted") then
    return true, "already_started"
  end

  local source = rawSourceFor(scr)

  if not source then
    return false, "source_missing"
  end

  local runner, compileErr = compileRuntimeSource(scr, source)

  if not runner then
    return false, "compile: " .. tostring(compileErr)
  end

  scr:SetAttribute("XYUREI_RuntimeStarted", true)

  task.spawn(function()
    local ok, runtimeErr = pcall(runner, scr, runtimeRequire)

    if not ok then
      warn("[XYUREI LIVE ERROR] " .. scr:GetFullName() .. " :: " .. tostring(runtimeErr))
      scr:SetAttribute("XYUREI_RuntimeError", tostring(runtimeErr))
    end
  end)

  return true, "runtime_bridge"
end

local function prepareLocalScriptsForClone(root)
  if not root then
    return
  end

  if root:IsA("LocalScript") then
    setScriptEnabledState(root, false)
  end

  for _, obj in ipairs(root:GetDescendants()) do
    if obj:IsA("LocalScript") then
      setScriptEnabledState(obj, false)
    end
  end
end

local function activateLocalScriptsInLiveRoot(root)
  local stats = {
    native = 0,
    bridge = 0,
    failed = 0,
    skipped = 0,
  }

  if not root then
    return stats
  end

  local list = {}

  if root:IsA("LocalScript") then
    list[#list + 1] = root
  end

  for _, obj in ipairs(root:GetDescendants()) do
    if obj:IsA("LocalScript") then
      list[#list + 1] = obj
    end
  end

  for _, scr in ipairs(list) do
    if not importedScriptShouldRun(scr) then
      stats.skipped = stats.skipped + 1
      setScriptEnabledState(scr, false)
    else
      local hasRealSource = canReadExecutableSource(scr)

      if hasRealSource then
        local ok = setScriptEnabledState(scr, true)

        if ok then
          stats.native = stats.native + 1
        else
          stats.failed = stats.failed + 1
        end
      else
        setScriptEnabledState(scr, false)
        local ok = runLocalScriptBridge(scr)

        if ok then
          stats.bridge = stats.bridge + 1
        else
          stats.failed = stats.failed + 1
        end
      end
    end
  end

  return stats
end

local function mergeLiveStats(dst, src)
  dst.native = dst.native + (src.native or 0)
  dst.bridge = dst.bridge + (src.bridge or 0)
  dst.failed = dst.failed + (src.failed or 0)
  dst.skipped = dst.skipped + (src.skipped or 0)
end

local function findStudioLiteRemote(name)
  local sl = ReplicatedStorage:FindFirstChild("StudioLiteFolder")

  if not sl then
    return nil
  end

  return sl:FindFirstChild(name, true)
end

local function tryWriteRealScriptSource(scr)
  if not scr or not scr:IsA("LuaSourceContainer") then
    return false, "not_script"
  end

  local source = _G.XYUREI_RAW_SOURCES[scr]

  if type(source) ~= "string" or source == "" then
    return false, "source_missing"
  end

  source = source:gsub(string.char(0) .. "*$", "")

  if type(setscriptable) == "function" then
    pcall(setscriptable, scr, "Source", true)
  end

  local directOK = pcall(function() scr.Source = source end)

  if directOK then
    return true, "direct"
  end

  local saveRemote = findStudioLiteRemote("SaveScriptSourceServerFunction")

  if saveRemote and saveRemote:IsA("RemoteFunction") then
    local ok = pcall(function() saveRemote:InvokeServer(scr.ClassName .. scr.Name, source) end)

    if ok then
      return true, "studio_lite_remote"
    end
  elseif saveRemote and saveRemote:IsA("RemoteEvent") then
    local ok = pcall(function() saveRemote:FireServer(scr.ClassName .. scr.Name, source) end)

    if ok then
      return true, "studio_lite_remote"
    end
  end

  return false, "runtime_source_locked"
end

local function restoreImportedRuntimeState(root)
  local stats = {
    scripts = 0,
    scriptSourceOK = 0,
    scriptSourceFailed = 0,
    parts = 0,
  }

  local all = { root }

  for _, d in ipairs(root:GetDescendants()) do
    all[#all + 1] = d
  end

  for _, obj in ipairs(all) do
    if obj:IsA("LuaSourceContainer") then
      stats.scripts = stats.scripts + 1
      local ok = tryWriteRealScriptSource(obj)

      if ok then
        stats.scriptSourceOK = stats.scriptSourceOK + 1
      else
        stats.scriptSourceFailed = stats.scriptSourceFailed + 1
      end
    end
  end

  for _, obj in ipairs(all) do
    if obj:IsA("BasePart") then
      stats.parts = stats.parts + 1
      local originalCanCollide = obj:GetAttribute("SL_CanCollide")

      if originalCanCollide ~= nil then
        pcall(function() obj.CanCollide = originalCanCollide end)
      end

      pcall(function()
        obj.Anchored = true
        obj:SetAttribute("XYUREI_AutoAnchored", true)
      end)
    end
  end

  return stats
end

local function moveChildren(source, destination, onMoved)
  if not source or not destination then
    return 0
  end

  local moved = 0
  local children = source:GetChildren()

  for _, child in ipairs(children) do
    local ok = pcall(function() child.Parent = destination end)

    if ok then
      moved = moved + 1

      if onMoved then
        pcall(onMoved, child, destination)
      end
    end
  end

  return moved
end

local function activateImportRoot(importRoot)
  if not importRoot then
    return false, "Import root tidak ditemukan"
  end

  reportImportProgress(0.8, "PREPARING SERVICES")
  local forcedServiceCount = 0
  local reusedServiceCount = 0
  local createdServiceCount = 0
  local proxyServiceCount = 0
  local missingRealServices = 0
  local serviceModes = {}

  local function getTopLevelChildrenNamed(serviceName)
    local matches = {}
    local ok, children = pcall(function() return game:GetChildren() end)

    if not ok or type(children) ~= "table" then
      return matches
    end

    for _, child in ipairs(children) do
      local childName = ""
      pcall(function() childName = child.Name end)

      if childName == serviceName then
        matches[#matches + 1] = child
      end
    end

    return matches
  end

  local function isXYUREIGeneratedService(obj)
    if not obj then
      return false
    end

    local generated = false

    pcall(function()
      generated = obj:GetAttribute("XYUREI_ForcedRealService") == true
        or obj:GetAttribute("XYUREI_ForcedVisibleService") == true
        or obj:GetAttribute("XYUREI_CreatedService") == true
    end)

    return generated
  end

  local function mergeChildrenInto(source, destination)
    if not source or not destination or source == destination then
      return 0
    end

    local moved = 0
    local children = {}
    pcall(function() children = source:GetChildren() end)

    for _, child in ipairs(children) do
      local okMove = pcall(function() child.Parent = destination end)

      if okMove then
        moved = moved + 1
      end
    end

    return moved
  end

  local function findExistingService(serviceName)
    local matches = getTopLevelChildrenNamed(serviceName)

    if #matches == 0 then
      return nil
    end

    local chosen = nil

    for _, obj in ipairs(matches) do
      if not isXYUREIGeneratedService(obj) then
        chosen = obj
        break
      end
    end

    chosen = chosen or matches[1]

    for _, obj in ipairs(matches) do
      if obj ~= chosen and isXYUREIGeneratedService(obj) then
        mergeChildrenInto(obj, chosen)
        pcall(function() obj:Destroy() end)
      end
    end

    return chosen
  end

  local function forceGetService(serviceName)
    local existing = findExistingService(serviceName)

    if existing then
      reusedServiceCount = reusedServiceCount + 1
      serviceModes[serviceName] = "REUSED"
      return existing
    end

    local created

    local okCreate, createErr = pcall(function()
      created = Instance.new(serviceName)
      created.Name = serviceName
      created:SetAttribute("XYUREI_ForcedRealService", true)
      created:SetAttribute("XYUREI_ServiceRole", serviceName)
      created.Parent = game
    end)

    if okCreate and created then
      createdServiceCount = createdServiceCount + 1
      serviceModes[serviceName] = "CREATED"
      return created
    end

    local okGet, service = pcall(function() return game:GetService(serviceName) end)

    if okGet and service then
      forcedServiceCount = forcedServiceCount + 1
      serviceModes[serviceName] = "GETSERVICE"
      pcall(function() service:SetAttribute("XYUREI_ServiceRole", serviceName) end)
      return service
    end

    missingRealServices = missingRealServices + 1
    serviceModes[serviceName] = "FAILED"
    warn("[XYUREI] SERVICE FAILED: " .. serviceName .. " :: " .. tostring(createErr))
    return nil
  end

  local function tryForceVisibleService(serviceName, realService)
    if not realService or findExistingService(serviceName) then
      return nil
    end

    local roots = { game }

    for _, candidate in ipairs({ _G.sss, _G.ss }) do
      if candidate and candidate.Parent then
        local duplicate = false

        for _, root in ipairs(roots) do
          if root == candidate.Parent then
            duplicate = true
            break
          end
        end

        if not duplicate then
          roots[#roots + 1] = candidate.Parent
        end
      end
    end

    pcall(function() realService.Archivable = true end)

    for _, root in ipairs(roots) do
      local clone
      local okClone = pcall(function() clone = realService:Clone() end)

      if okClone and clone then
        local className = ""
        pcall(function() className = clone.ClassName end)

        if className == serviceName then
          local okParent = pcall(function()
            clone.Name = serviceName
            clone:SetAttribute("XYUREI_ExplorerVisibleService", true)
            clone.Parent = root
          end)

          if okParent then
            serviceModes[serviceName] = "VISIBLE_CLONE"
            return clone
          end
        end

        pcall(function() clone:Destroy() end)
      end
    end

    return nil
  end

  local WorkspaceService = forceGetService("Workspace")
  local PlayersSvc = forceGetService("Players")
  local LightingSvc = forceGetService("Lighting")
  local ReplicatedFirstSvc = forceGetService("ReplicatedFirst")
  local ReplicatedStorageSvc = forceGetService("ReplicatedStorage")
  local StarterGuiSvc = forceGetService("StarterGui")
  local StarterPackSvc = forceGetService("StarterPack")
  local StarterPlayerSvc = forceGetService("StarterPlayer")
  local TeamsSvc = forceGetService("Teams")
  local ServerScriptServiceSvc = forceGetService("ServerScriptService")
  local ServerStorageSvc = forceGetService("ServerStorage")
  local SoundServiceSvc = forceGetService("SoundService")
  local MaterialServiceSvc = forceGetService("MaterialService")
  local TextChatServiceSvc = forceGetService("TextChatService")
  local ChatSvc = forceGetService("Chat")
  local LocalizationServiceSvc = forceGetService("LocalizationService")
  local TestServiceSvc = forceGetService("TestService")
  local HttpServiceSvc = forceGetService("HttpService")
  local InsertServiceSvc = forceGetService("InsertService")
  local TweenServiceSvc = forceGetService("TweenService")

  local visibleServiceClones = {
    SoundService = tryForceVisibleService("SoundService", SoundServiceSvc),
    MaterialService = tryForceVisibleService("MaterialService", MaterialServiceSvc),
    TextChatService = tryForceVisibleService("TextChatService", TextChatServiceSvc),
    Chat = tryForceVisibleService("Chat", ChatSvc),
    LocalizationService = tryForceVisibleService("LocalizationService", LocalizationServiceSvc),
    TestService = tryForceVisibleService("TestService", TestServiceSvc),
    HttpService = tryForceVisibleService("HttpService", HttpServiceSvc),
    InsertService = tryForceVisibleService("InsertService", InsertServiceSvc),
    TweenService = tryForceVisibleService("TweenService", TweenServiceSvc),
  }

  reportImportProgress(0.84, "SERVICES READY")

  local function ensureStarterContainer(parent, className, name)
    if not parent then
      return nil
    end

    local existing = parent:FindFirstChild(name)

    if existing then
      return existing
    end

    local created

    local ok = pcall(function()
      created = Instance.new(className)
      created.Name = name
      created.Parent = parent
    end)

    if ok and created then
      return created
    end

    local fallback = Instance.new("Folder")
    fallback.Name = name
    fallback:SetAttribute("XYUREI_StarterContainerFallback", true)
    fallback.Parent = parent

    return fallback
  end

  local starterPlayerScripts = ensureStarterContainer(
    StarterPlayerSvc, "StarterPlayerScripts", "StarterPlayerScripts"
  )

  local starterCharacterScripts = ensureStarterContainer(
    StarterPlayerSvc, "StarterCharacterScripts", "StarterCharacterScripts"
  )

  local destinationByKey = {
    WS = WorkspaceService,
    RS = ReplicatedStorageSvc,
    RF = ReplicatedFirstSvc,
    L = LightingSvc,
    P = PlayersSvc,
    SG = StarterGuiSvc,
    STP = StarterPackSvc,
    SP = StarterPlayerSvc,
    SPS = starterPlayerScripts,
    SCS = starterCharacterScripts,
    SSS = ServerScriptServiceSvc,
    SS = ServerStorageSvc,
    TEAM = TeamsSvc,
    SND = SoundServiceSvc,
    MAT = MaterialServiceSvc,
    TCS = TextChatServiceSvc,
    CHAT = ChatSvc,
    LOC = LocalizationServiceSvc,
    TEST = TestServiceSvc,
    HTTP = HttpServiceSvc,
    INS = InsertServiceSvc,
    TWEEN = TweenServiceSvc,
  }

  local runtimeStats = restoreImportedRuntimeState(importRoot)
  reportImportProgress(0.87, "RESTORING SCRIPT SOURCES")
  local moved = 0
  local failedServices = 0
  local stagedCounts = {}
  local stagedScriptCounts = {}

  for _, serviceFolder in ipairs(importRoot:GetChildren()) do
    if serviceFolder:IsA("Folder") then
      local key = serviceFolder:GetAttribute("XYUREI_ServiceKey")

      if key then
        stagedCounts[key] = #serviceFolder:GetChildren()
        local scriptCount = 0

        for _, d in ipairs(serviceFolder:GetDescendants()) do
          if d:IsA("LuaSourceContainer") then
            scriptCount = scriptCount + 1
          end
        end

        stagedScriptCounts[key] = scriptCount
      end
    end
  end

  for _, serviceFolder in ipairs(importRoot:GetChildren()) do
    if serviceFolder:IsA("Folder") then
      local key = serviceFolder:GetAttribute("XYUREI_ServiceKey")
      local destination = destinationByKey[key]

      if destination then
        moved = moved + moveChildren(serviceFolder, destination)
      elseif #serviceFolder:GetChildren() > 0 then
        failedServices = failedServices + 1
      end
    end
  end

  reportImportProgress(0.91, ("DEPLOYED • %d OBJECTS"):format(moved))
  local activatedScripts = 0

  local function restoreOneImportedScript(obj)
    if not obj:IsA("LuaSourceContainer") or not obj:GetAttribute("XYUREI_StagedDisabled") then
      return
    end

    local shouldRun = importedScriptShouldRun(obj)
    setScriptEnabledState(obj, shouldRun)
    pcall(function() obj:SetAttribute("XYUREI_StagedDisabled", nil) end)

    if shouldRun then
      activatedScripts = activatedScripts + 1
    end
  end

  for _, obj in ipairs(importRoot:GetDescendants()) do
    restoreOneImportedScript(obj)
  end

  for _, service in pairs(destinationByKey) do
    if service then
      for _, obj in ipairs(service:GetDescendants()) do
        restoreOneImportedScript(obj)
      end
    end
  end

  local liveStats = {
    native = 0,
    bridge = 0,
    failed = 0,
    skipped = 0,
  }

  local function cloneImportedChildren(sourceContainer, destinationContainer)
    if not sourceContainer or not destinationContainer then
      return
    end

    for _, child in ipairs(sourceContainer:GetChildren()) do
      if child:GetAttribute("XYUREI_ImportedObject") == true then
        local existing = destinationContainer:FindFirstChild(child.Name)

        if existing and existing:GetAttribute("XYUREI_LiveClone") == true then
          pcall(function() existing:Destroy() end)
        end

        local clone
        local okClone = pcall(function() clone = child:Clone() end)

        if okClone and clone then
          clone:SetAttribute("XYUREI_LiveClone", true)
          prepareLocalScriptsForClone(clone)
          clone.Parent = destinationContainer
          local s = activateLocalScriptsInLiveRoot(clone)
          mergeLiveStats(liveStats, s)
        end
      end
    end
  end

  local playerGui = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")

  if playerGui then
    cloneImportedChildren(StarterGui, playerGui)
  end

  local playerScripts = LocalPlayer and LocalPlayer:FindFirstChild("PlayerScripts")

  if playerScripts and starterPlayerScripts then
    cloneImportedChildren(starterPlayerScripts, playerScripts)
  end

  local character = LocalPlayer and LocalPlayer.Character

  if character and starterCharacterScripts then
    cloneImportedChildren(starterCharacterScripts, character)
  end

  local backpack = LocalPlayer and LocalPlayer:FindFirstChildOfClass("Backpack")

  if backpack then
    cloneImportedChildren(StarterPack, backpack)
  end

  if ReplicatedFirstSvc then
    for _, obj in ipairs(ReplicatedFirstSvc:GetDescendants()) do
      if obj:IsA("LocalScript") and obj:GetAttribute("XYUREI_ImportedObject") == true then
        local hasRealSource = canReadExecutableSource(obj)

        if hasRealSource then
          setScriptEnabledState(obj, true)
          liveStats.native = liveStats.native + 1
        else
          setScriptEnabledState(obj, false)
          local ok = runLocalScriptBridge(obj)

          if ok then
            liveStats.bridge = liveStats.bridge + 1
          else
            liveStats.failed = liveStats.failed + 1
          end
        end
      end
    end
  end

  reportImportProgress(0.95, "FINALIZING SCRIPT EDITORS")
  local deployedScriptCount = 0
  local editorInjectedCount = 0
  local sourceVisibleCount = 0
  local sssImportedScripts = 0
  local ssImportedScripts = 0

  local function restoreEditorForService(service, serviceKey)
    if not service then
      return
    end

    for _, obj in ipairs(service:GetDescendants()) do
      if obj:IsA("LuaSourceContainer") and obj:GetAttribute("XYUREI_ImportedObject") == true then
        deployedScriptCount = deployedScriptCount + 1

        if serviceKey == "SSS" then
          sssImportedScripts = sssImportedScripts + 1
        elseif serviceKey == "SS" then
          ssImportedScripts = ssImportedScripts + 1
        end

        local refKey = obj:GetAttribute("XYUREI_Ref")
        local source = _G.XYUREI_RAW_SOURCES[obj]

        if (type(source) ~= "string" or source == "") and refKey ~= nil then
          source = _G.XYUREI_RAW_SOURCE_BY_REF[tostring(refKey)]

          if type(source) == "string" and source ~= "" then
            _G.XYUREI_RAW_SOURCES[obj] = source
          end
        end

        if type(source) == "string" and source ~= "" then
          sourceVisibleCount = sourceVisibleCount + 1
          pcall(function() tryWriteRealScriptSource(obj) end)
          local okEditor = pcall(function() injectStudioLiteUI(obj, {}) end)

          if okEditor then
            editorInjectedCount = editorInjectedCount + 1
          end
        end
      end
    end
  end

  restoreEditorForService(ServerScriptServiceSvc, "SSS")
  restoreEditorForService(ServerStorageSvc, "SS")
  restoreEditorForService(ReplicatedStorageSvc, "RS")
  restoreEditorForService(ReplicatedFirstSvc, "RF")
  restoreEditorForService(StarterGuiSvc, "SG")
  restoreEditorForService(StarterPlayerSvc, "SP")
  restoreEditorForService(StarterPackSvc, "STP")

  if (stagedScriptCounts.SSS or 0) > 0 and sssImportedScripts == 0 then
    warn("[XYUREI] WARNING: " .. tostring(stagedScriptCounts.SSS)
      .. " script SSS tidak terlihat di final.")
  end

  if (stagedScriptCounts.SS or 0) > 0 and ssImportedScripts == 0 then
    warn("[XYUREI] WARNING: " .. tostring(stagedScriptCounts.SS)
      .. " script SS tidak terlihat di final.")
  end

  for _, service in pairs(destinationByKey) do
    if service then
      for _, obj in ipairs(service:GetDescendants()) do
        if obj:IsA("LuaSourceContainer") and obj:GetAttribute("XYUREI_ImportedObject") == true then
          setScriptEnabledState(obj, importedScriptShouldRun(obj))
        end
      end
    end
  end

  for _, service in pairs(destinationByKey) do
    if service then
      for _, obj in ipairs(service:GetDescendants()) do
        if obj:IsA("BasePart") and obj:GetAttribute("XYUREI_ImportedObject") == true then
          pcall(function()
            obj.Anchored = true
            obj:SetAttribute("XYUREI_AutoAnchored", true)
          end)
        end
      end
    end
  end

  importRoot:SetAttribute("XYUREI_Activated", true)
  local remainingStagedObjects = 0

  for _, serviceFolder in ipairs(importRoot:GetChildren()) do
    if serviceFolder:IsA("Folder") then
      remainingStagedObjects = remainingStagedObjects + #serviceFolder:GetChildren()
    end
  end

  if remainingStagedObjects == 0 then
    pcall(function() importRoot:Destroy() end)
  end

  reportImportProgress(1, "RBXL GENERATION COMPLETE")

  return true, ("ACTIVE • moved:%d • scripts:%d active:%d • source:%d/%d • SSS:%d SS:%d • editor:%d/%d • service reused:%d real-created:%d getservice:%d real-failed:%d"):format(
    moved, runtimeStats.scripts, activatedScripts, runtimeStats.scriptSourceOK,
    runtimeStats.scripts, sssImportedScripts, ssImportedScripts, editorInjectedCount,
    sourceVisibleCount, reusedServiceCount, createdServiceCount, forcedServiceCount,
    missingRealServices
  )
end

local function safeListFiles(path)
  if type(listfiles) ~= "function" then
    return nil
  end

  local ok, result = pcall(listfiles, path)
  return ok and result or nil
end

local function getFileName(path)
  return path:match("([^/\\]+)$") or path
end

local function looksFolder(path)
  return not getFileName(path):match("%.[%a%d]+$")
end

local SCAN_PATHS = {
  "workspace", "Delta/workspace", "delta/workspace", "Android/Delta/workspace",
  "/sdcard/Delta/workspace", "/sdcard/Android/Delta/workspace", "../workspace", ".", "",
}

local function normalizeFsPath(path)
  local p = tostring(path or ""):gsub("\\", "/"):lower()
  p = p:gsub("/+", "/"):gsub("^%./", ""):gsub("^%.%./", ""):gsub("/$", "")
  return p
end

local function canonicalWorkspacePath(path)
  local p = normalizeFsPath(path)
  local lastWorkspace
  local searchFrom = 1

  while true do
    local s, e = p:find("workspace/", searchFrom, true)

    if not s then
      break
    end

    lastWorkspace = e + 1
    searchFrom = e + 1
  end

  if lastWorkspace then
    return p:sub(lastWorkspace)
  end

  if p == "workspace" then
    return ""
  end

  return p
end

local function scanDeep(folder, depth, results, seenFolders, seenFiles)
  if depth > 4 then
    return
  end

  local folderKey = canonicalWorkspacePath(folder)

  if folderKey == "" then
    folderKey = "__root__"
  end

  if seenFolders[folderKey] then
    return
  end

  seenFolders[folderKey] = true
  local list = safeListFiles(folder)

  if not list then
    return
  end

  for _, path in ipairs(list) do
    local name = getFileName(path)
    local lower = name:lower()
    local ftype

    if lower:match("%.rbxl$") or lower:match("%.rbxlx$") then
      ftype = "RBXL"
    elseif lower:match("%.rbxm$") or lower:match("%.rbxmx$") then
      ftype = "RBXM"
    end

    if ftype then
      local fileKey = canonicalWorkspacePath(path)

      if fileKey == "" then
        fileKey = lower
      end

      if not seenFiles[fileKey] then
        seenFiles[fileKey] = true

        table.insert(results, {
          name = name,
          path = path,
          folder = folder,
          ftype = ftype,
          canonicalKey = fileKey,
        })
      end
    elseif looksFolder(path) then
      scanDeep(path, depth + 1, results, seenFolders, seenFiles)
    end
  end
end

local function scanAllSupported()
  local results = {}
  local seenFolders = {}
  local seenFiles = {}

  for _, path in ipairs(SCAN_PATHS) do
    if safeListFiles(path) then
      scanDeep(path, 0, results, seenFolders, seenFiles)
    end
  end

  table.sort(results, function(a, b)
    local an = a.name:lower()
    local bn = b.name:lower()

    if an == bn then
      return tostring(a.canonicalKey or a.path) < tostring(b.canonicalKey or b.path)
    end

    return an < bn
  end)

  return results
end

local function __buildMusicPage(env)
  local mk, round, stroke, gradient, label, glass, C = env.mk, env.round, env.stroke, env.gradient, env.label, env.glass, env.C
  local content, gui, setStatus, notify = env.content, env.gui, env.setStatus, env.notify
  local COMPACT = env.compact == true
  local RunService = game:GetService("RunService")
  local HS = game:GetService("HttpService")
  local MPS = game:GetService("MarketplaceService")

  local PLAYLIST = {
    {
      AssetId = 120983443791226,
      Name = "RASAH BALI",
      Duration = 0,
      ImageUrl = "",
      Creator = "xyuzen’—",
    },
    {
      AssetId = 92799532573184,
      Name = "Runkat",
      Duration = 0,
      ImageUrl = "",
      Creator = "xyuzen’—",
    },
    {
      AssetId = 117224072066843,
      Name = "NEGORO ANGIN",
      Duration = 0,
      ImageUrl = "",
      Creator = "xyuzen’—",
    },
    {
      AssetId = 115035906821398,
      Name = "Sinarengan",
      Duration = 0,
      ImageUrl = "",
      Creator = "xyuzen’—",
    },
    {
      AssetId = 120786497356440,
      Name = "Pamit Ning Ati",
      Duration = 0,
      ImageUrl = "",
      Creator = "xyuzen’—",
    },
    {
      AssetId = 79151027570609,
      Name = "Urip Iku Mlaku",
      Duration = 0,
      ImageUrl = "",
      Creator = "xyuzen’—",
    },
    {
      AssetId = 70962526173357,
      Name = "Lintang Nyek Seni",
      Duration = 0,
      ImageUrl = "",
      Creator = "xyuzen’—",
    },
    {
      AssetId = 135480789776959,
      Name = "Udang Ning Atiku",
      Duration = 0,
      ImageUrl = "",
      Creator = "xyuzen’—",
    },
    {
      AssetId = 121796353758342,
      Name = "Sepi Tanpo Sliramu",
      Duration = 0,
      ImageUrl = "",
      Creator = "xyuzen’—",
    },
    {
      AssetId = 85537520513989,
      Name = "Tresno Kinaryo Kangen",
      Duration = 0,
      ImageUrl = "",
      Creator = "xyuzen’—",
    },
    {
      AssetId = 71152710717244,
      Name = "Tresnoku Selawase",
      Duration = 0,
      ImageUrl = "",
      Creator = "xyuzen’—",
    },
    {
      AssetId = 74761962675895,
      Name = "Saiki",
      Duration = 0,
      ImageUrl = "",
      Creator = "xyuzen’—",
    },
    {
      AssetId = 134246452602760,
      Name = "Tembang Kanggo Sliramu",
      Duration = 0,
      ImageUrl = "",
      Creator = "xyuzen’—",
    },
    {
      AssetId = 121335955905892,
      Name = "Ora Butoh Sliramu",
      Duration = 0,
      ImageUrl = "",
      Creator = "xyuzen’—",
    },
    {
      AssetId = 110496212005473,
      Name = "Tau Dadi Padhange Dalan",
      Duration = 0,
      ImageUrl = "",
      Creator = "xyuzen’—",
    },
    {
      AssetId = 77330130829762,
      Name = "Nerusake Uripku",
      Duration = 0,
      ImageUrl = "",
      Creator = "xyuzen’—",
    },
    {
      AssetId = 100800381563349,
      Name = "Mboyak",
      Duration = 0,
      ImageUrl = "",
      Creator = "xyuzen’—",
    },
    {
      AssetId = 110965259723757,
      Name = "Kowe Ning Endi",
      Duration = 0,
      ImageUrl = "",
      Creator = "xyuzen’—",
    },
    {
      AssetId = 79929910199476,
      Name = "Los Ora Rewel",
      Duration = 0,
      ImageUrl = "",
      Creator = "xyuzen’—",
    },
    {
      AssetId = 100644156519402,
      Name = "Oalah Wong Kere",
      Duration = 0,
      ImageUrl = "",
      Creator = "xyuzen’—",
    },
  }

  local FOLDER = "xyurei_music"
  local USER_FILE = FOLDER .. "/playlist_user.json"

  local canSave = type(writefile) == "function" and type(readfile) == "function"
    and type(isfile) == "function"

  if canSave and type(makefolder) == "function" then
    pcall(function()
      if not (type(isfolder) == "function" and isfolder(FOLDER)) then
        makefolder(FOLDER)
      end
    end)
  end

  local function trim(s)
    return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
  end

  local function fmt(t)
    t = math.max(0, math.floor(t or 0))
    return ("%d:%02d"):format(math.floor(t / 60), t % 60)
  end

  local function hasId(id)
    for _, s in ipairs(PLAYLIST) do
      if s.AssetId == id then
        return true
      end
    end

    return false
  end

  local function saveUser()
    if not canSave then
      return
    end

    local out = {}

    for _, s in ipairs(PLAYLIST) do
      if s.Custom then
        out[#out + 1] = { AssetId = s.AssetId, Name = s.Name, Creator = s.Creator }
      end
    end

    pcall(function() writefile(USER_FILE, HS:JSONEncode(out)) end)
  end

  if canSave then
    pcall(function()
      if not isfile(USER_FILE) then
        return
      end

      local data = HS:JSONDecode(readfile(USER_FILE))

      for _, s in ipairs(data) do
        local id = tonumber(s.AssetId)

        if id and not hasId(id) then
          PLAYLIST[#PLAYLIST + 1] = {
            AssetId = id,
            Name = tostring(s.Name or "Lagu " .. id),
            Duration = 0,
            ImageUrl = "",
            Creator = tostring(s.Creator or "-"),
            Custom = true,
          }
        end
      end
    end)
  end

  local page = mk("Frame", {
    Name = "Page_MUSIC",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Visible = false,
    ZIndex = 12,
  }, content)

  local left = mk("ScrollingFrame", {
    Name = "Player",
    Size = COMPACT and UDim2.new(1, 0, 0, 176) or UDim2.new(0, 244, 1, 0),
    BackgroundColor3 = C.card,
    BackgroundTransparency = 0.42,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = C.white,
    ScrollBarImageTransparency = 0.4,
    CanvasSize = UDim2.fromOffset(0, COMPACT and 176 or 300),
    ZIndex = 13,
  }, page)

  round(left, 16)
  stroke(left, C.white, 1, 0.85)

  local discBox = mk("Frame", {
    Size = UDim2.fromOffset(160, 160),
    Position = COMPACT and UDim2.fromOffset(12, 14) or UDim2.new(0.5, -80, 0, 10),
    BackgroundTransparency = 1,
    ZIndex = 14,
  }, left)

  if COMPACT then
    mk("UIScale", { Scale = 0.62 }, discBox)
  end

  local disc = mk("Frame", {
    Name = "Disc",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.fromRGB(8, 8, 12),
    BorderSizePixel = 0,
    ZIndex = 14,
  }, discBox)

  round(disc, 80)
  local discStroke = stroke(disc, C.cyan, 2, 0.2)

  gradient(discStroke, {
    ColorSequenceKeypoint.new(0, C.cyan), ColorSequenceKeypoint.new(0.5, C.purple),
    ColorSequenceKeypoint.new(1, C.pink),
  }, 0)

  for _, s in ipairs({ 142, 124, 106, 90 }) do
    local g = mk("Frame", {
      AnchorPoint = Vector2.new(0.5, 0.5),
      Position = UDim2.fromScale(0.5, 0.5),
      Size = UDim2.fromOffset(s, s),
      BackgroundTransparency = 1,
      ZIndex = 15,
    }, disc)

    round(g, s / 2)
    stroke(g, C.faint, 1, 0.8)
  end

  local ringW = mk("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(70, 70),
    BackgroundColor3 = C.white,
    BorderSizePixel = 0,
    ZIndex = 16,
  }, disc)

  round(ringW, 35)

  local labelBlack = mk("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(54, 54),
    BackgroundColor3 = Color3.fromRGB(10, 12, 18),
    BorderSizePixel = 0,
    ZIndex = 17,
  }, disc)

  round(labelBlack, 27)
  stroke(labelBlack, C.cyan, 1, 0.5)

  local brandTxt = label(labelBlack, {
    Size = UDim2.fromScale(1, 1),
    Text = [[
VIP
MUSIC]],
    TextColor3 = C.cyan,
    Font = Enum.Font.GothamBlack,
    TextSize = 8,
    TextXAlignment = Enum.TextXAlignment.Center,
    ZIndex = 18,
  })

  local coverImg = mk("ImageLabel", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Image = "",
    ScaleType = Enum.ScaleType.Crop,
    ZIndex = 19,
  }, labelBlack)

  round(coverImg, 27)

  local hole = mk("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(9, 9),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
    ZIndex = 20,
  }, disc)

  round(hole, 5)

  local nowTitle = label(left, {
    Size = COMPACT and UDim2.new(1, -134, 0, 18) or UDim2.new(1, -24, 0, 18),
    Position = COMPACT and UDim2.fromOffset(122, 16) or UDim2.fromOffset(12, 178),
    Text = "Belum ada lagu",
    TextSize = 13,
    Font = Enum.Font.GothamBlack,
    TextXAlignment = COMPACT and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center,
    TextTruncate = Enum.TextTruncate.AtEnd,
    ZIndex = 14,
  })

  local nowArtist = label(left, {
    Size = COMPACT and UDim2.new(1, -134, 0, 14) or UDim2.new(1, -24, 0, 14),
    Position = COMPACT and UDim2.fromOffset(122, 36) or UDim2.fromOffset(12, 197),
    Text = COMPACT and "Pilih lagu di daftar bawah" or "Pilih lagu di sebelah kanan",
    TextColor3 = C.faint,
    Font = Enum.Font.GothamMedium,
    TextSize = 11,
    TextXAlignment = COMPACT and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center,
    TextTruncate = Enum.TextTruncate.AtEnd,
    ZIndex = 14,
  })

  local track = mk("Frame", {
    Size = COMPACT and UDim2.new(1, -134, 0, 5) or UDim2.new(1, -28, 0, 5),
    Position = COMPACT and UDim2.fromOffset(122, 76) or UDim2.fromOffset(14, 220),
    BackgroundColor3 = C.card2,
    BorderSizePixel = 0,
    ZIndex = 14,
  }, left)

  round(track, 3)

  local fill = mk("Frame", {
    Size = UDim2.new(0, 0, 1, 0),
    BackgroundColor3 = C.cyan,
    BorderSizePixel = 0,
    ZIndex = 15,
  }, track)

  round(fill, 3)

  gradient(
    fill, { ColorSequenceKeypoint.new(0, C.cyan), ColorSequenceKeypoint.new(1, C.pink) }, 0
  )

  local seek = mk("TextButton", {
    Size = COMPACT and UDim2.new(1, -134, 0, 16) or UDim2.new(1, -28, 0, 16),
    Position = COMPACT and UDim2.fromOffset(122, 70) or UDim2.fromOffset(14, 214),
    BackgroundTransparency = 1,
    Text = "",
    AutoButtonColor = false,
    ZIndex = 16,
  }, left)

  local timeL = label(left, {
    Size = UDim2.fromOffset(60, 12),
    Position = COMPACT and UDim2.fromOffset(122, 88) or UDim2.fromOffset(14, 229),
    Text = "0:00",
    TextColor3 = C.faint,
    TextSize = 10,
    ZIndex = 14,
  })

  local timeR = label(left, {
    Size = UDim2.fromOffset(60, 12),
    Position = COMPACT and UDim2.new(1, -72, 0, 88) or UDim2.new(1, -74, 0, 229),
    Text = "0:00",
    TextColor3 = C.faint,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Right,
    ZIndex = 14,
  })

  local function ctl(text, x, color, size)
    local b = mk("TextButton", {
      Size = COMPACT and UDim2.fromOffset(62, 34) or UDim2.fromOffset(48, 36),
      Position = UDim2.fromOffset(COMPACT and x * 1.25 - 3.5 or x, COMPACT and 126 or 248),
      BackgroundColor3 = color or C.card2,
      Text = text,
      TextColor3 = C.white,
      Font = Enum.Font.GothamBlack,
      TextSize = size or 13,
      AutoButtonColor = false,
      ZIndex = 15,
    }, left)

    round(b, 11)
    stroke(b, C.white, 1, 0.8)
    return b
  end

  local loopBtn = ctl("LOOP", 14, C.card2, 10)
  local stopBtn = ctl("■", 70, C.card2, 14)
  local playBtn = ctl("▶", 126, C.purple, 15)
  local nextBtn = ctl("»", 182, C.card2, 18)

  local right = mk("Frame", {
    Size = COMPACT and UDim2.new(1, 0, 1, -184) or UDim2.new(1, -256, 1, 0),
    Position = COMPACT and UDim2.fromOffset(0, 184) or UDim2.fromOffset(256, 0),
    BackgroundTransparency = 1,
    ZIndex = 13,
  }, page)

  local tool = mk(
    "Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, ZIndex = 13 }, right
  )

  local function inputBox(ph, size, pos)
    local w = mk("Frame", {
      Size = size,
      Position = pos,
      BackgroundColor3 = C.card,
      BackgroundTransparency = 0.38,
      BorderSizePixel = 0,
      ZIndex = 14,
    }, tool)

    round(w, 11)
    stroke(w, C.white, 1, 0.85)
    glass(w)

    return mk("TextBox", {
      Size = UDim2.new(1, -20, 1, 0),
      Position = UDim2.fromOffset(10, 0),
      BackgroundTransparency = 1,
      PlaceholderText = ph,
      PlaceholderColor3 = C.faint,
      Text = "",
      TextColor3 = C.white,
      Font = Enum.Font.GothamMedium,
      TextSize = 12,
      TextXAlignment = Enum.TextXAlignment.Left,
      ClearTextOnFocus = false,
      ZIndex = 15,
    }, w)
  end

  local idBox = inputBox(
    "ID audio Roblox", UDim2.new(0, COMPACT and 96 or 128, 1, 0), UDim2.fromOffset(0, 0)
  )

  local nameBox = inputBox(
    COMPACT and "Nama (ops.)" or "Nama lagu (opsional)",
    COMPACT and UDim2.new(1, -188, 1, 0) or UDim2.new(1, -228, 1, 0),
    COMPACT and UDim2.fromOffset(102, 0) or UDim2.fromOffset(134, 0)
  )

  local addBtn = mk("TextButton", {
    Size = UDim2.fromOffset(COMPACT and 82 or 88, 40),
    Position = UDim2.new(1, COMPACT and -82 or -88, 0, 0),
    BackgroundColor3 = C.purple,
    Text = "+ TAMBAH",
    TextColor3 = C.white,
    Font = Enum.Font.GothamBlack,
    TextSize = 11,
    AutoButtonColor = false,
    ZIndex = 14,
  }, tool)

  round(addBtn, 10)
  stroke(addBtn, C.white, 1, 0.7)

  label(right, {
    Size = UDim2.new(1, 0, 0, 14),
    Position = UDim2.fromOffset(2, 46),
    Text = "Tempel ID audio Roblox, lalu tekan TAMBAH. Nama boleh dikosongkan (otomatis).",
    TextColor3 = C.faint,
    Font = Enum.Font.GothamMedium,
    TextSize = 10,
    TextTruncate = Enum.TextTruncate.AtEnd,
    ZIndex = 13,
  })

  local list = mk("ScrollingFrame", {
    Name = "MusicList",
    Size = UDim2.new(1, 0, 1, -66),
    Position = UDim2.fromOffset(0, 66),
    BackgroundColor3 = C.card,
    BackgroundTransparency = 0.55,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = C.white,
    ScrollBarImageTransparency = 0.35,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.new(),
    ZIndex = 13,
  }, right)

  round(list, 12)
  stroke(list, C.white, 1, 0.88)

  do
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, 8)
    p.PaddingBottom = UDim.new(0, 8)
    p.PaddingLeft = UDim.new(0, 8)
    p.PaddingRight = UDim.new(0, 8)
    p.Parent = list
  end

  mk("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, list)

  local sound = Instance.new("Sound")
  sound.Name = "XyureiMusic"
  sound.Volume = 1
  sound.Parent = gui

  local current, qIndex = nil, 0
  local loopOn = false
  local playToken = 0
  local ignoreEndUntil = 0
  local cards = {}
  local playEntry, renderList

  local function setCover(url)
    coverImg.Image = ""

    local ok = type(url) == "string" and url ~= ""
      and (url:find("^rbxassetid://") or url:find("roblox%.com"))

    brandTxt.Visible = not ok

    if ok then
      coverImg.Image = url
    end
  end

  local function fail(msg)
    setStatus("MUSIC ERROR: " .. tostring(msg), C.danger)
    notify("MUSIC", tostring(msg), false)
  end

  local function refreshActive()
    for e, c in pairs(cards) do
      local on = e == current

      c.stroke.Color = on and C.cyan or C.white
      c.stroke.Transparency = on and 0.35 or 0.85
      c.badge.TextColor3 = on and C.white or C.cyan
    end
  end

  playEntry = function(entry)
    playToken = playToken + 1
    local token = playToken
    current = entry
    qIndex = table.find(PLAYLIST, entry) or qIndex
    nowTitle.Text = entry.Name
    nowArtist.Text = entry.Creator and entry.Creator ~= "" and entry.Creator or "-"
    setCover(entry.ImageUrl)
    refreshActive()
    ignoreEndUntil = os.clock() + 0.6
    pcall(function() sound:Stop() end)
    setStatus("MEMUAT " .. entry.Name, C.warn)

    task.spawn(function()
      sound.SoundId = ""
      task.wait()

      if token ~= playToken then
        return
      end

      sound.SoundId = "rbxassetid://" .. tostring(entry.AssetId)
      local t0 = os.clock()

      while not (sound.IsLoaded and sound.TimeLength > 0) and os.clock() - t0 < 12 do
        task.wait(0.1)
      end

      if token ~= playToken then
        return
      end

      if not sound.IsLoaded or sound.TimeLength <= 0 then
        return fail("ID " .. tostring(entry.AssetId)
          .. " gagal dimuat (ID salah / audio private)")
      end

      entry.Duration = sound.TimeLength

      sound.Looped = loopOn
      sound.TimePosition = 0
      sound:Play()

      setStatus("MEMUTAR " .. entry.Name, C.ok)
    end)
  end

  local function nextTrack()
    if #PLAYLIST == 0 then
      setStatus("PLAYLIST KOSONG", C.warn)
      return
    end

    qIndex = qIndex % #PLAYLIST + 1
    playEntry(PLAYLIST[qIndex])
  end

  sound.Ended:Connect(function()
    if os.clock() < ignoreEndUntil or loopOn then
      return
    end

    nextTrack()
  end)

  playBtn.Activated:Connect(function()
    if sound.IsPlaying then
      sound:Pause()
    elseif current and sound.IsLoaded and sound.TimeLength > 0 then
      sound:Play()
    elseif current then
      playEntry(current)
    elseif #PLAYLIST > 0 then
      playEntry(PLAYLIST[math.max(qIndex, 1)])
    else
      setStatus("PILIH LAGU DULU", C.warn)
    end
  end)

  stopBtn.Activated:Connect(function()
    ignoreEndUntil = os.clock() + 0.6

    sound:Stop()
    sound.TimePosition = 0

    setStatus("MUSIK DIHENTIKAN", C.sub)
  end)

  nextBtn.Activated:Connect(nextTrack)

  loopBtn.Activated:Connect(function()
    loopOn = not loopOn
    sound.Looped = loopOn
    loopBtn.BackgroundColor3 = loopOn and C.purple or C.card2
    setStatus(loopOn and "LOOP: ON" or "LOOP: OFF", loopOn and C.ok or C.sub)
  end)

  seek.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
      or input.UserInputType == Enum.UserInputType.Touch then
      local len = sound.TimeLength

      if len > 0 then
        local ratio = math.clamp((input.Position.X - track.AbsolutePosition.X)
          / math.max(1, track.AbsoluteSize.X), 0, 1)

        sound.TimePosition = ratio * len
      end
    end
  end)

  local lastPlaying

  local conn = RunService.Heartbeat:Connect(function(dt)
    local playing = sound.IsPlaying

    if playing then
      disc.Rotation = (disc.Rotation + dt * 45) % 360
    end

    if playing ~= lastPlaying then
      lastPlaying = playing
      playBtn.Text = playing and "II" or "▶"
    end

    local len = sound.TimeLength

    if len > 0 then
      fill.Size = UDim2.new(math.clamp(sound.TimePosition / len, 0, 1), 0, 1, 0)
      timeL.Text = fmt(sound.TimePosition)
      timeR.Text = fmt(len)
    end
  end)

  gui.Destroying:Connect(function()
    conn:Disconnect()
    pcall(function() sound:Stop() end)
  end)

  local function entryCard(e, order)
    local card = mk("Frame", {
      Size = UDim2.new(1, -4, 0, 54),
      BackgroundColor3 = C.card2,
      BackgroundTransparency = 0.42,
      BorderSizePixel = 0,
      LayoutOrder = order,
      ZIndex = 14,
    }, list)

    round(card, 13)
    local cs = stroke(card, C.white, 1, 0.85)

    local badge = mk("TextLabel", {
      Size = UDim2.fromOffset(40, 40),
      Position = UDim2.fromOffset(8, 7),
      BackgroundColor3 = C.bg,
      Text = tostring(order),
      TextColor3 = C.cyan,
      Font = Enum.Font.GothamBlack,
      TextSize = 13,
      ZIndex = 15,
    }, card)

    round(badge, 8)
    local pad = e.Custom and 200 or 160

    label(card, {
      Size = UDim2.new(1, -pad, 0, 14),
      Position = UDim2.fromOffset(56, 10),
      Text = e.Name,
      TextSize = 11,
      TextTruncate = Enum.TextTruncate.AtEnd,
    })

    label(card, {
      Size = UDim2.new(1, -pad, 0, 12),
      Position = UDim2.fromOffset(56, 28),
      Text = (e.Creator and e.Creator ~= "" and e.Creator .. " · " or "") .. "ID "
        .. tostring(e.AssetId),
      TextColor3 = C.faint,
      Font = Enum.Font.GothamMedium,
      TextSize = 10,
      TextTruncate = Enum.TextTruncate.AtEnd,
    })

    local btn = mk("TextButton", {
      Size = UDim2.fromOffset(72, 28),
      Position = UDim2.new(1, -80, 0.5, -14),
      BackgroundColor3 = C.purple,
      Text = "PUTAR",
      TextColor3 = C.white,
      Font = Enum.Font.GothamBlack,
      TextSize = 10,
      AutoButtonColor = false,
      ZIndex = 15,
    }, card)

    round(btn, 8)
    stroke(btn, C.white, 1, 0.7)
    btn.Activated:Connect(function() playEntry(e) end)

    if e.Custom then
      local del = mk("TextButton", {
        Size = UDim2.fromOffset(32, 28),
        Position = UDim2.new(1, -118, 0.5, -14),
        BackgroundColor3 = C.card,
        Text = "✕",
        TextColor3 = C.danger,
        Font = Enum.Font.GothamBlack,
        TextSize = 12,
        AutoButtonColor = false,
        ZIndex = 15,
      }, card)

      round(del, 8)
      stroke(del, C.danger, 1, 0.65)

      del.Activated:Connect(function()
        local idx = table.find(PLAYLIST, e)

        if not idx then
          return
        end

        table.remove(PLAYLIST, idx)

        if current == e then
          playToken = playToken + 1
          ignoreEndUntil = os.clock() + 0.6
          pcall(function() sound:Stop() end)
          current = nil
          nowTitle.Text = "Belum ada lagu"
          nowArtist.Text = "Pilih lagu di sebelah kanan"
          setCover(nil)
        end

        saveUser()
        renderList()
        setStatus("LAGU DIHAPUS " .. e.Name, C.sub)
      end)
    end

    cards[e] = { stroke = cs, badge = badge }
  end

  renderList = function()
    for _, c in ipairs(list:GetChildren()) do
      if c:IsA("GuiObject") then
        c:Destroy()
      end
    end

    table.clear(cards)

    if #PLAYLIST == 0 then
      label(list, {
        Name = "Msg",
        Size = UDim2.new(1, -16, 0, 100),
        Text = [[
PLAYLIST KOSONG
Tambah lagu pakai ID di atas]],
        TextColor3 = C.faint,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Center,
        LayoutOrder = 1,
        ZIndex = 14,
      })

      return
    end

    for i, e in ipairs(PLAYLIST) do
      entryCard(e, i)
    end

    refreshActive()
  end

  local adding = false

  local function addSong()
    if adding then
      return
    end

    local id = tonumber(trim(idBox.Text):match("%d+"))

    if not id or #tostring(id) < 5 then
      setStatus("ID AUDIO TIDAK VALID", C.danger)
      notify("MUSIC", "ID audio tidak valid", false)
      return
    end

    if hasId(id) then
      setStatus("LAGU SUDAH ADA DI LIST", C.warn)
      notify("MUSIC", "Lagu itu sudah ada di list", false)
      return
    end

    adding = true
    addBtn.Text = "..."
    local typed = trim(nameBox.Text)

    task.spawn(function()
      local name, creator = typed, "-"
      local okI, info = pcall(function() return MPS:GetProductInfo(id, Enum.InfoType.Asset) end)

      if okI and type(info) == "table" then
        if info.AssetTypeId and info.AssetTypeId ~= 3 then
          adding = false
          addBtn.Text = "+ TAMBAH"
          setStatus("ID BUKAN AUDIO", C.danger)
          notify("MUSIC", "ID itu bukan asset audio", false)
          return
        end

        if name == "" then
          name = tostring(info.Name or "")
        end

        if type(info.Creator) == "table" and info.Creator.Name then
          creator = tostring(info.Creator.Name)
        end
      end

      if name == "" then
        name = "Lagu " .. id
      end

      PLAYLIST[#PLAYLIST + 1] = {
        AssetId = id,
        Name = name,
        Duration = 0,
        ImageUrl = "",
        Creator = creator,
        Custom = true,
      }

      saveUser()
      renderList()
      idBox.Text = ""
      nameBox.Text = ""
      adding = false
      addBtn.Text = "+ TAMBAH"
      setStatus("DITAMBAHKAN " .. name, C.ok)

      task.defer(function()
        pcall(function() list.CanvasPosition = Vector2.new(0, 100000) end)
      end)
    end)
  end

  addBtn.Activated:Connect(addSong)

  idBox.FocusLost:Connect(function(enter)
    if enter then
      addSong()
    end
  end)

  nameBox.FocusLost:Connect(function(enter)
    if enter then
      addSong()
    end
  end)

  renderList()
  return page
end

local function __buildChatPage(env)
  local mk, round, stroke, label, glass, C = env.mk, env.round, env.stroke, env.label, env.glass, env.C
  local content, httpReq = env.content, env.httpReq
  local HS = game:GetService("HttpService")
  local CFG = XYUREI_CONFIG

  local function getKey()
    local k = CFG.OPENROUTER_API_KEY
    local okG, g = pcall(function() return getgenv and getgenv().XYUREI_OPENROUTER_KEY end)

    if okG and type(g) == "string" and g ~= "" then
      k = g
    end

    if type(k) ~= "string" then
      return nil
    end

    k = k:gsub("^%s+", ""):gsub("%s+$", "")

    if k == "" or k:find("ISI_API_KEY", 1, true) then
      return nil
    end

    return k
  end

  local function getModel()
    local m = CFG.OPENROUTER_MODEL
    local okG, g = pcall(function() return getgenv and getgenv().XYUREI_OPENROUTER_MODEL end)

    if okG and type(g) == "string" and g ~= "" then
      m = g
    end

    return type(m) == "string" and m ~= "" and m or "openai/gpt-4o-mini"
  end

  local function pad(o, t, b, l, r)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, t)
    p.PaddingBottom = UDim.new(0, b)
    p.PaddingLeft = UDim.new(0, l)
    p.PaddingRight = UDim.new(0, r)
    p.Parent = o
  end

  local function fmt(text)
    local s = tostring(text or "")
    s = s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
    s = s:gsub("%*%*(.-)%*%*", "<b>%1</b>")
    s = s:gsub("\n#+%s*([^\n]+)", "\n<b>%1</b>")

    s = s:gsub([[
^#+%s*([^
]+)]], "<b>%1</b>")

    return s
  end

  local page = mk("Frame", {
    Name = "Page_CHAT",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Visible = false,
    ZIndex = 12,
  }, content)

  local bar = mk(
    "Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, ZIndex = 13 }, page
  )

  label(bar, {
    Size = UDim2.new(1, -170, 1, 0),
    Text = "MODEL · " .. getModel(),
    TextColor3 = C.faint,
    TextSize = 11,
    TextTruncate = Enum.TextTruncate.AtEnd,
    ZIndex = 14,
  })

  local function barBtn(text, xOff, col)
    local b = mk("TextButton", {
      Size = UDim2.fromOffset(78, 28),
      Position = UDim2.new(1, xOff, 0, 1),
      BackgroundColor3 = col,
      Text = text,
      TextColor3 = C.white,
      Font = Enum.Font.GothamBlack,
      TextSize = 11,
      AutoButtonColor = false,
      ZIndex = 14,
    }, bar)

    round(b, 9)
    stroke(b, C.white, 1, 0.7)
    return b
  end

  local copyBtn = barBtn("SALIN", -162, C.purple)
  local clearBtn = barBtn("HAPUS", -80, C.card2)

  local list = mk("ScrollingFrame", {
    Name = "ChatList",
    Size = UDim2.new(1, 0, 1, -82),
    Position = UDim2.fromOffset(0, 36),
    BackgroundColor3 = C.card,
    BackgroundTransparency = 0.55,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = C.white,
    ScrollBarImageTransparency = 0.35,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.new(),
    ZIndex = 13,
  }, page)

  round(list, 12)
  stroke(list, C.white, 1, 0.88)
  pad(list, 8, 8, 8, 8)
  mk("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, list)

  local inputRow = mk("Frame", {
    Size = UDim2.new(1, 0, 0, 40),
    Position = UDim2.new(0, 0, 1, -40),
    BackgroundTransparency = 1,
    ZIndex = 13,
  }, page)

  local sw = mk("Frame", {
    Size = UDim2.new(1, -98, 1, 0),
    BackgroundColor3 = C.card,
    BackgroundTransparency = 0.38,
    BorderSizePixel = 0,
    ZIndex = 14,
  }, inputRow)

  round(sw, 11)
  stroke(sw, C.white, 1, 0.85)
  glass(sw)

  local box = mk("TextBox", {
    Name = "ChatInput",
    Size = UDim2.new(1, -20, 1, 0),
    Position = UDim2.fromOffset(12, 0),
    BackgroundTransparency = 1,
    PlaceholderText = "Tulis pesan untuk AI...",
    PlaceholderColor3 = C.faint,
    Text = "",
    TextColor3 = C.white,
    Font = Enum.Font.GothamMedium,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false,
    ZIndex = 15,
  }, sw)

  local sendBtn = mk("TextButton", {
    Name = "Send",
    Size = UDim2.fromOffset(88, 40),
    Position = UDim2.new(1, -88, 0, 0),
    BackgroundColor3 = C.purple,
    Text = "KIRIM",
    TextColor3 = C.white,
    Font = Enum.Font.GothamBlack,
    TextSize = 12,
    AutoButtonColor = false,
    ZIndex = 14,
  }, inputRow)

  round(sendBtn, 10)
  stroke(sendBtn, C.white, 1, 0.7)
  local order = 0

  local function scrollDown()
    task.defer(function()
      task.wait()
      list.CanvasPosition = Vector2.new(0, math.max(0, list.AbsoluteCanvasSize.Y))
    end)
  end

  local function addBubble(role, text)
    local isUser = role == "user"
    order = order + 1

    local row = mk("Frame", {
      Name = "Msg",
      Size = UDim2.new(1, 0, 0, 0),
      AutomaticSize = Enum.AutomaticSize.Y,
      BackgroundTransparency = 1,
      LayoutOrder = order,
      ZIndex = 14,
    }, list)

    local bubble = mk("Frame", {
      Size = UDim2.new(0.88, 0, 0, 0),
      AutomaticSize = Enum.AutomaticSize.Y,
      AnchorPoint = Vector2.new(isUser and 1 or 0, 0),
      Position = UDim2.new(isUser and 1 or 0, 0, 0, 0),
      BackgroundColor3 = isUser and C.purple or C.card2,
      BackgroundTransparency = isUser and 0.18 or 0.22,
      BorderSizePixel = 0,
      ZIndex = 15,
    }, row)

    round(bubble, 12)
    stroke(bubble, isUser and C.white or C.cyan, 1, 0.8)
    pad(bubble, 8, 8, 10, 10)

    local tl = mk("TextLabel", {
      Size = UDim2.new(1, 0, 0, 0),
      AutomaticSize = Enum.AutomaticSize.Y,
      BackgroundTransparency = 1,
      Text = fmt(text),
      RichText = true,
      TextWrapped = true,
      TextColor3 = C.white,
      Font = Enum.Font.GothamMedium,
      TextSize = 12,
      TextXAlignment = Enum.TextXAlignment.Left,
      TextYAlignment = Enum.TextYAlignment.Top,
      ZIndex = 16,
    }, bubble)

    scrollDown()
    return tl, row
  end

  local history = {}
  local lastReply = nil
  local busy = false

  local function welcome()
    addBubble(
      "ai",
      "Halo! Aku asisten AI Tools Engine MCP. Tanya apa aja, misalnya script Roblox, Lua, atau hal lain."
    )

    if not getKey() then
      addBubble(
        "ai",
        "⚠ API key OpenRouter belum diisi.\nBuka script, cari XYUREI_CONFIG di paling atas, lalu isi OPENROUTER_API_KEY (ambil di openrouter.ai/keys)."
      )
    end
  end

  local function ask()
    local key = getKey()

    if not key then
      return nil, "API key OpenRouter belum diisi di XYUREI_CONFIG"
    end

    if not httpReq then
      return nil, "executor tidak punya fungsi request()"
    end

    local msgs = {
      {
        role = "system",
        content = tostring(CFG.OPENROUTER_SYSTEM or "Jawab dalam bahasa Indonesia."),
      },
    }

    local maxH = tonumber(CFG.OPENROUTER_MAX_HISTORY) or 12

    for i = math.max(1, #history - maxH + 1), #history do
      msgs[#msgs + 1] = history[i]
    end

    local ok, res = pcall(httpReq, {
      Url = XYUREI_CONFIG.OPENROUTER_API_URL,
      Method = "POST",
      Headers = {
        ["Content-Type"] = "application/json",
        Authorization = "Bearer " .. key,
        ["X-Title"] = "Tools Engine",
      },
      Body = HS:JSONEncode({ model = getModel(), messages = msgs }),
    })

    if not ok or type(res) ~= "table" then
      return nil, "request gagal: " .. tostring(res)
    end

    local okJ, data = pcall(function() return HS:JSONDecode(res.Body or "") end)
    local code = tonumber(res.StatusCode)

    if okJ and type(data) == "table" and type(data.error) == "table" then
      local m = tostring(data.error.message or data.error.code or "error")

      if code == 401 then
        m = "API key salah / tidak valid (" .. m .. ")"
      elseif code == 402 then
        m = "saldo OpenRouter tidak cukup (" .. m .. ")"
      elseif code == 429 then
        m = "kena rate limit, coba lagi sebentar (" .. m .. ")"
      end

      return nil, m
    end

    if code and code ~= 200 then
      return nil, "HTTP " .. tostring(code)
    end

    if not okJ or type(data) ~= "table" then
      return nil, "respons bukan JSON"
    end

    local ch = type(data.choices) == "table" and data.choices[1] or nil
    local msg = type(ch) == "table" and ch.message or nil
    local text = type(msg) == "table" and msg.content or nil

    if type(text) == "table" then
      local parts = {}

      for _, p in ipairs(text) do
        if type(p) == "table" and type(p.text) == "string" then
          parts[#parts + 1] = p.text
        end
      end

      text = table.concat(parts)
    end

    if type(text) ~= "string" or text == "" then
      return nil, "AI tidak mengirim jawaban (coba model lain)"
    end

    return text
  end

  local function send()
    local text = tostring(box.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")

    if text == "" or busy then
      return
    end

    box.Text = ""
    addBubble("user", text)

    if not getKey() then
      addBubble(
        "ai",
        "⚠ API key OpenRouter belum diisi. Isi OPENROUTER_API_KEY di XYUREI_CONFIG (paling atas script)."
      )

      return
    end

    history[#history + 1] = { role = "user", content = text }
    busy = true
    sendBtn.Text = "..."
    local typing = addBubble("ai", "Mengetik...")

    task.spawn(function()
      local reply, err = ask()
      busy = false
      sendBtn.Text = "KIRIM"

      if reply then
        history[#history + 1] = { role = "assistant", content = reply }
        lastReply = reply
        typing.Text = fmt(reply)
      else
        history[#history] = nil
        typing.Text = "⚠ " .. fmt(err)
      end

      scrollDown()
    end)
  end

  sendBtn.Activated:Connect(send)

  box.FocusLost:Connect(function(enter)
    if enter then
      send()
    end
  end)

  clearBtn.Activated:Connect(function()
    if busy then
      return
    end

    history = {}
    lastReply = nil

    for _, o in ipairs(list:GetChildren()) do
      if o:IsA("Frame") then
        o:Destroy()
      end
    end

    welcome()
  end)

  copyBtn.Activated:Connect(function()
    if lastReply and type(setclipboard) == "function" then
      pcall(setclipboard, lastReply)
      copyBtn.Text = "TERSALIN"
      task.delay(1.2, function() copyBtn.Text = "SALIN" end)
    end
  end)

  welcome()
  return page
end

local function __buildBypassPage(env)
  local mk, round, stroke, gradient, label, glass, C = env.mk, env.round, env.stroke, env.gradient, env.label, env.glass, env.C
  local content, gui, setStatus, notify, httpReq = env.content, env.gui, env.setStatus, env.notify, env.httpReq
  local HS = game:GetService("HttpService")
  local UIS = game:GetService("UserInputService")
  local ORANGE = Color3.fromRGB(235, 236, 242)
  local FOLDER = "xyurei_music"
  local CFG_FILE = FOLDER .. "/bypass_cfg.json"

  local canSave = type(writefile) == "function" and type(readfile) == "function"
    and type(isfile) == "function"

  if canSave and type(makefolder) == "function" then
    pcall(function()
      if not (type(isfolder) == "function" and isfolder(FOLDER)) then
        makefolder(FOLDER)
      end
    end)
  end

  local cfg = {
    key = "",
    uid = "",
    name = "",
    saved = false,
    relay = "",
    secret = "",
  }

  if canSave then
    pcall(function()
      if not isfile(CFG_FILE) then
        return
      end

      local d = HS:JSONDecode(readfile(CFG_FILE))

      if type(d) == "table" and type(d.key) == "string" and tostring(d.uid or "") ~= "" then
        cfg.key = d.key
        cfg.uid = tostring(d.uid)
        cfg.name = tostring(d.name or "")
        cfg.saved = d.valid == true
        cfg.relay = tostring(d.relay or "")
        cfg.secret = tostring(d.secret or "")
      end
    end)
  end

  local CFG_RELAY, CFG_SECRET = "", ""

  do
    local url, sec = XYUREI_CONFIG.RELAY_URL, XYUREI_CONFIG.RELAY_SECRET
    local okG, gu = pcall(function() return getgenv and getgenv().XYUREI_RELAY_URL end)

    if okG and type(gu) == "string" and gu ~= "" then
      url = gu
    end

    local okS, gs = pcall(function() return getgenv and getgenv().XYUREI_RELAY_SECRET end)

    if okS and type(gs) == "string" and gs ~= "" then
      sec = gs
    end

    url = tostring(url or ""):gsub("^%s+", ""):gsub("%s+$", ""):gsub("/+$", "")

    if url ~= "" and not url:find("ISI%-URL", 1) and url:match("^https?://") then
      CFG_RELAY = url
      CFG_SECRET = tostring(sec or "")
    end
  end

  local RELAY_LOCKED = CFG_RELAY ~= ""

  if RELAY_LOCKED then
    cfg.relay = CFG_RELAY
    cfg.secret = CFG_SECRET
  end

  local function saveCfg()
    if not canSave then
      return false
    end

    return pcall(function()
      writefile(CFG_FILE, HS:JSONEncode({
        key = cfg.key,
        uid = cfg.uid,
        name = cfg.name,
        valid = cfg.saved,
        relay = cfg.relay,
        secret = cfg.secret,
      }))
    end)
  end

  local function trim(s)
    return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
  end

  local function copy(text)
    local fn = setclipboard or toclipboard or syn and syn.write_clipboard
      or Clipboard and Clipboard.set

    if fn then
      return (pcall(fn, tostring(text)))
    end

    return false
  end

  local function pad(o, t, b, l, r)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, t)
    p.PaddingBottom = UDim.new(0, b)
    p.PaddingLeft = UDim.new(0, l)
    p.PaddingRight = UDim.new(0, r)
    p.Parent = o
  end

  local function buildMultipart(reqJson, ext, mime, data, opts)
    opts = opts or {}

    local boundary = "xyureiform" .. tostring(math.random(100000000, 999999999)) .. "x"
      .. tostring(math.random(100000000, 999999999))

    local fname = opts.filename or "audio." .. ext

    local reqPart = "--" .. boundary
      .. "\r\nContent-Disposition: form-data; name=\"request\"\r\nContent-Type: application/json\r\n\r\n"
      .. reqJson .. "\r\n"

    local filePart = "--" .. boundary
      .. "\r\nContent-Disposition: form-data; name=\"fileContent\"; filename=\"" .. fname
      .. "\"\r\nContent-Type: " .. mime .. "\r\n\r\n" .. data .. "\r\n"

    local body = (opts.fileFirst and filePart .. reqPart or reqPart .. filePart) .. "--"
      .. boundary .. "--\r\n"

    return body, "multipart/form-data; boundary=" .. boundary
  end

  local function press(i)
    return i.UserInputType == Enum.UserInputType.MouseButton1
      or i.UserInputType == Enum.UserInputType.Touch
  end

  local function button(parent, text, size, pos, color, ts)
    local b = mk("TextButton", {
      Size = size,
      Position = pos,
      BackgroundColor3 = color,
      Text = text,
      TextColor3 = C.white,
      Font = Enum.Font.GothamBlack,
      TextSize = ts or 11,
      AutoButtonColor = false,
      ZIndex = 15,
    }, parent)

    round(b, 10)
    stroke(b, C.white, 1, 0.7)
    return b
  end

  local function inputBox(parent, ph, size, pos)
    local w = mk("Frame", {
      Size = size,
      Position = pos,
      BackgroundColor3 = C.card,
      BackgroundTransparency = 0.38,
      BorderSizePixel = 0,
      ZIndex = 14,
    }, parent)

    round(w, 11)
    stroke(w, C.white, 1, 0.85)
    glass(w)

    return mk("TextBox", {
      Size = UDim2.new(1, -20, 1, 0),
      Position = UDim2.fromOffset(10, 0),
      BackgroundTransparency = 1,
      PlaceholderText = ph,
      PlaceholderColor3 = C.faint,
      Text = "",
      TextColor3 = C.white,
      Font = Enum.Font.GothamMedium,
      TextSize = 12,
      TextXAlignment = Enum.TextXAlignment.Left,
      ClearTextOnFocus = false,
      TextTruncate = Enum.TextTruncate.AtEnd,
      ZIndex = 15,
    }, w)
  end

  local page = mk("Frame", {
    Name = "Page_BYPASS",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Visible = false,
    ZIndex = 12,
  }, content)

  local viewList = mk("Frame", {
    Name = "ViewList",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    ZIndex = 13,
  }, page)

  local viewEdit = mk("ScrollingFrame", {
    Name = "ViewEdit",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Visible = false,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = C.white,
    ScrollBarImageTransparency = 0.4,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.new(),
    ZIndex = 13,
  }, page)

  local viewSet = mk("ScrollingFrame", {
    Name = "ViewSet",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Visible = false,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = C.white,
    ScrollBarImageTransparency = 0.4,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.new(),
    ZIndex = 13,
  }, page)

  local currentView, prevView = "list", "list"

  local function showView(v)
    if v == "settings" and currentView ~= "settings" then
      prevView = currentView
    end

    currentView = v
    viewList.Visible = v == "list"
    viewEdit.Visible = v == "edit"
    viewSet.Visible = v == "settings"
  end

  local searchBox = inputBox(
    viewList, "Cari file audio...", UDim2.new(1, -114, 0, 38), UDim2.fromOffset(0, 0)
  )

  local scanBtn = button(
    viewList, "SCAN", UDim2.fromOffset(64, 38), UDim2.new(1, -108, 0, 0), C.purple
  )

  local gearBtn = button(
    viewList, "⚙", UDim2.fromOffset(38, 38), UDim2.new(1, -38, 0, 0), C.card2, 16
  )

  local apiInfo = label(viewList, {
    Size = UDim2.new(1, 0, 0, 14),
    Position = UDim2.fromOffset(2, 42),
    Text = "",
    TextSize = 10,
    TextColor3 = C.faint,
    Font = Enum.Font.GothamMedium,
    TextTruncate = Enum.TextTruncate.AtEnd,
  })

  local list = mk("ScrollingFrame", {
    Name = "AudioList",
    Size = UDim2.new(1, 0, 1, -62),
    Position = UDim2.fromOffset(0, 62),
    BackgroundColor3 = C.card,
    BackgroundTransparency = 0.55,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = C.white,
    ScrollBarImageTransparency = 0.35,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.new(),
    ZIndex = 13,
  }, viewList)

  round(list, 12)
  stroke(list, C.white, 1, 0.88)
  pad(list, 8, 8, 8, 8)
  mk("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, list)

  local EMPTY_TXT = [[
BELUM ADA FILE AUDIO

Tempel file .mp3 / .ogg / .wav
ke folder workspace Delta,
lalu tekan SCAN]]

  local emptyLbl = label(list, {
    Size = UDim2.new(1, -16, 0, 120),
    Text = EMPTY_TXT,
    TextColor3 = C.faint,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Center,
    ZIndex = 14,
  })

  local function refreshApiInfo()
    if cfg.saved then
      apiInfo.Text = "UPLOAD: SIAP · " .. (cfg.name ~= "" and cfg.name or "User") .. " · ID "
        .. cfg.uid .. (cfg.relay ~= "" and " · VIA WEBSITE" or " · LANGSUNG")

      apiInfo.TextColor3 = C.ok
    else
      apiInfo.Text = "UPLOAD: BELUM DIATUR · tekan ⚙ untuk isi API Key & User ID"
      apiInfo.TextColor3 = C.warn
    end
  end

  refreshApiInfo()

  local selected = nil
  local P = { vol = 1, pitch = 0, speed = 1 }

  local backEdit = button(
    viewEdit, "‹", UDim2.fromOffset(34, 34), UDim2.fromOffset(0, 0), C.card2, 20
  )

  local fileTitle = label(viewEdit, {
    Size = UDim2.new(1, -44, 0, 18),
    Position = UDim2.fromOffset(42, 2),
    Text = "-",
    TextSize = 13,
    Font = Enum.Font.GothamBlack,
    TextTruncate = Enum.TextTruncate.AtEnd,
  })

  local fileSub = label(viewEdit, {
    Size = UDim2.new(1, -44, 0, 12),
    Position = UDim2.fromOffset(42, 21),
    Text = "",
    TextSize = 9,
    TextColor3 = ORANGE,
    TextTruncate = Enum.TextTruncate.AtEnd,
  })

  local sound = Instance.new("Sound")
  sound.Name = "XyureiBypassPreview"
  sound.Volume = 1
  sound.Parent = gui

  local pitchFx = Instance.new("PitchShiftSoundEffect")
  pitchFx.Octave = 1
  pitchFx.Parent = sound

  local function applyFx()
    sound.Volume = math.clamp(P.vol, 0, 10)
    sound.PlaybackSpeed = P.speed
    pitchFx.Octave = math.clamp(2 ^ (P.pitch / 12), 0.5, 2)
  end

  local function makeSlider(y, title, min, max, step, def, fmtFn, onChange)
    local row = mk("Frame", {
      Size = UDim2.new(1, -4, 0, 46),
      Position = UDim2.fromOffset(0, y),
      BackgroundTransparency = 1,
      ZIndex = 14,
    }, viewEdit)

    label(row, {
      Size = UDim2.new(0.5, 0, 0, 16),
      Text = title,
      TextColor3 = C.sub,
      TextSize = 11,
      ZIndex = 15,
    })

    local val = label(row, {
      Size = UDim2.new(0.5, 0, 0, 16),
      Position = UDim2.fromScale(0.5, 0),
      Text = "",
      TextColor3 = C.cyan,
      Font = Enum.Font.GothamBlack,
      TextSize = 12,
      TextXAlignment = Enum.TextXAlignment.Right,
      ZIndex = 15,
    })

    local track = mk("Frame", {
      Size = UDim2.new(1, -16, 0, 6),
      Position = UDim2.fromOffset(8, 28),
      BackgroundColor3 = C.card2,
      BorderSizePixel = 0,
      ZIndex = 15,
    }, row)

    round(track, 3)

    local fill = mk("Frame", {
      Size = UDim2.new(0, 0, 1, 0),
      BackgroundColor3 = C.cyan,
      BorderSizePixel = 0,
      ZIndex = 16,
    }, track)

    round(fill, 3)

    gradient(
      fill, { ColorSequenceKeypoint.new(0, C.cyan), ColorSequenceKeypoint.new(1, C.pink) }, 0
    )

    local knob = mk("Frame", {
      Size = UDim2.fromOffset(16, 16),
      AnchorPoint = Vector2.new(0.5, 0.5),
      Position = UDim2.new(0, 0, 0.5, 0),
      BackgroundColor3 = C.white,
      BorderSizePixel = 0,
      ZIndex = 17,
    }, track)

    round(knob, 8)
    stroke(knob, C.cyan, 1.5, 0.2)

    local hit = mk("TextButton", {
      Size = UDim2.new(1, 0, 0, 30),
      Position = UDim2.fromOffset(0, 16),
      BackgroundTransparency = 1,
      Text = "",
      AutoButtonColor = false,
      ZIndex = 18,
    }, row)

    local value = def

    local function setValue(v, silent)
      v = math.clamp(math.floor(v / step + 0.5) * step, min, max)
      value = v
      local r = (v - min) / (max - min)
      fill.Size = UDim2.new(r, 0, 1, 0)
      knob.Position = UDim2.new(r, 0, 0.5, 0)
      val.Text = fmtFn(v)

      if not silent then
        onChange(v)
      end
    end

    local function fromX(x)
      local r = math.clamp(
        (x - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1
      )

      setValue(min + r * (max - min))
    end

    local dragging, dragInput = false, nil

    hit.InputBegan:Connect(function(i)
      if not press(i) then
        return
      end

      dragging = true
      dragInput = i
      viewEdit.ScrollingEnabled = false
      fromX(i.Position.X)

      i.Changed:Connect(function()
        if i.UserInputState == Enum.UserInputState.End then
          dragging = false
          viewEdit.ScrollingEnabled = true
        end
      end)
    end)

    UIS.InputChanged:Connect(function(i)
      if dragging and (i == dragInput or i.UserInputType == Enum.UserInputType.MouseMovement) then
        fromX(i.Position.X)
      end
    end)

    setValue(def, true)
    return { set = setValue }
  end

  local volS = makeSlider(44, "VOLUME", 0, 2, 0.05, 1, function(v) return ("%d%%"):format(math.floor(v * 100 + 0.5)) end, function(v)
    P.vol = v
    applyFx()
  end)

  local pitchS = makeSlider(92, "PITCH", -12, 12, 1, 0, function(v) return ("%+d semitone"):format(v) end, function(v)
    P.pitch = v
    applyFx()
  end)

  local speedS = makeSlider(140, "SPEED", 0.5, 2, 0.05, 1, function(v) return ("%.2fx"):format(v) end, function(v)
    P.speed = v
    applyFx()
  end)

  local previewBtn = button(
    viewEdit, "▶ PREVIEW", UDim2.new(0.62, -4, 0, 34), UDim2.fromOffset(0, 192), C.purple
  )

  local resetBtn = button(
    viewEdit, "RESET", UDim2.new(0.38, -4, 0, 34), UDim2.new(0.62, 4, 0, 192), C.card2
  )

  label(viewEdit, {
    Size = UDim2.new(1, -4, 0, 30),
    Position = UDim2.fromOffset(2, 232),
    TextWrapped = true,
    TextColor3 = C.faint,
    Font = Enum.Font.GothamMedium,
    TextSize = 9,
    TextYAlignment = Enum.TextYAlignment.Top,
    Text = "File .wav 16-bit: volume & speed ikut diproses ke file yang diupload. mp3/ogg diupload apa adanya; pitch (dan setelan lain) disediakan sebagai kode Sound setelah upload.",
  })

  local uploadBtn = button(
    viewEdit, "UPLOAD TO ROBLOX", UDim2.new(1, -4, 0, 42), UDim2.fromOffset(0, 270), C.purple,
    13
  )

  gradient(uploadBtn, {
    ColorSequenceKeypoint.new(0, Color3.fromRGB(104, 106, 118)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(38, 39, 46)),
  }, 0)

  local resMsg = label(viewEdit, {
    Size = UDim2.new(1, -4, 0, 90),
    Position = UDim2.fromOffset(2, 318),
    TextWrapped = true,
    TextColor3 = C.sub,
    Font = Enum.Font.GothamMedium,
    TextSize = 10,
    TextYAlignment = Enum.TextYAlignment.Top,
    Text = "",
  })

  local copyIdBtn = button(
    viewEdit, "SALIN ID", UDim2.new(0.5, -4, 0, 30), UDim2.fromOffset(0, 366), C.card, 10
  )

  local copySetBtn = button(
    viewEdit, "SALIN KODE SOUND", UDim2.new(0.5, -4, 0, 30), UDim2.new(0.5, 4, 0, 366), C.card,
    10
  )

  copyIdBtn.Visible = false
  copySetBtn.Visible = false

  mk("Frame", {
    Size = UDim2.fromOffset(1, 10),
    Position = UDim2.fromOffset(0, 404),
    BackgroundTransparency = 1,
  }, viewEdit)

  local function setMsg(text, color)
    resMsg.Text = tostring(text)
    resMsg.TextColor3 = color or C.sub
  end

  local previewToken = 0

  local function stopPreview()
    previewToken = previewToken + 1
    pcall(function() sound:Stop() end)
    previewBtn.Text = "▶ PREVIEW"
  end

  sound.Ended:Connect(function() previewBtn.Text = "▶ PREVIEW" end)

  previewBtn.Activated:Connect(function()
    if not selected then
      return
    end

    if sound.IsPlaying then
      stopPreview()
      return
    end

    if type(getcustomasset) ~= "function" then
      setMsg("Executor tidak punya getcustomasset — preview lokal tidak bisa.", C.danger)
      return
    end

    previewToken = previewToken + 1
    local token = previewToken
    previewBtn.Text = "..."

    task.spawn(function()
      local path = selected.path
      local cands = { path }
      local stripped = path:gsub("^%.?/?[Ww]orkspace/", "")

      if stripped ~= path then
        cands[#cands + 1] = stripped
      end

      local last = "tidak ada path yang bisa dimuat"
      local loaded = false

      for _, cand in ipairs(cands) do
        if token ~= previewToken then
          return
        end

        local ok, asset = pcall(getcustomasset, cand)

        if ok and asset and asset ~= "" then
          sound.SoundId = asset
          local t0 = os.clock()

          while not (sound.IsLoaded and sound.TimeLength > 0) and os.clock() - t0 < 6 do
            task.wait(0.1)
          end

          if sound.IsLoaded and sound.TimeLength > 0 then
            loaded = true
            break
          end

          last = "path '" .. cand .. "' terbaca tapi audio tidak termuat"
        else
          last = "getcustomasset gagal untuk '" .. cand .. "': " .. tostring(asset)
        end
      end

      if token ~= previewToken then
        return
      end

      if not loaded then
        previewBtn.Text = "▶ PREVIEW"

        local hint = selected.ext == "wav"
            and " (Roblox sering tidak memutar .wav, coba mp3/ogg)"
          or ""

        setMsg("Preview gagal: " .. last .. hint, C.danger)
        return
      end

      applyFx()

      sound.TimePosition = 0
      sound:Play()

      previewBtn.Text = "■ STOP"
    end)
  end)

  local function resetFx()
    P.vol, P.pitch, P.speed = 1, 0, 1
    volS.set(1, true)
    pitchS.set(0, true)
    speedS.set(1, true)
    applyFx()
  end

  resetBtn.Activated:Connect(resetFx)

  local backSet = button(
    viewSet, "‹", UDim2.fromOffset(34, 34), UDim2.fromOffset(0, 0), C.card2, 20
  )

  label(viewSet, {
    Size = UDim2.new(1, -44, 0, 18),
    Position = UDim2.fromOffset(42, 2),
    Text = "Pengaturan Upload",
    TextSize = 13,
    Font = Enum.Font.GothamBlack,
  })

  label(viewSet, {
    Size = UDim2.new(1, -44, 0, 12),
    Position = UDim2.fromOffset(42, 21),
    Text = "ROBLOX OPEN CLOUD",
    TextSize = 9,
    TextColor3 = ORANGE,
  })

  label(viewSet, {
    Size = UDim2.new(1, 0, 0, 14),
    Position = UDim2.fromOffset(2, 46),
    Text = "API KEY",
    TextColor3 = C.faint,
    TextSize = 10,
  })

  local keyBox = inputBox(
    viewSet, "Tempel API Key (Open Cloud)", UDim2.new(1, -4, 0, 38), UDim2.fromOffset(0, 62)
  )

  label(viewSet, {
    Size = UDim2.new(1, 0, 0, 14),
    Position = UDim2.fromOffset(2, 108),
    Text = "USER ID",
    TextColor3 = C.faint,
    TextSize = 10,
  })

  local uidBox = inputBox(
    viewSet, "User ID Roblox pemilik asset", UDim2.new(1, -4, 0, 38), UDim2.fromOffset(0, 124)
  )

  local relayBox = inputBox(viewSet, "", UDim2.new(1, -4, 0, 38), UDim2.fromOffset(0, 186))
  relayBox.Parent.Visible = false

  if RELAY_LOCKED then
    relayBox.Text = CFG_RELAY
    relayBox.TextEditable = false
    relayBox.ClearTextOnFocus = false
  end

  local valBtn = button(
    viewSet, "VALIDASI", UDim2.new(0.5, -4, 0, 38), UDim2.fromOffset(0, 172), C.purple
  )

  local saveBtn = button(
    viewSet, "SIMPAN", UDim2.new(0.5, -4, 0, 38), UDim2.new(0.5, 4, 0, 172), C.card2
  )

  local setMsgLbl = label(viewSet, {
    Size = UDim2.new(1, -4, 0, 44),
    Position = UDim2.fromOffset(2, 218),
    TextWrapped = true,
    TextColor3 = C.sub,
    Font = Enum.Font.GothamMedium,
    TextSize = 10,
    TextYAlignment = Enum.TextYAlignment.Top,
    Text = "",
  })

  label(viewSet, {
    Size = UDim2.new(1, -4, 0, 96),
    Position = UDim2.fromOffset(2, 266),
    TextWrapped = true,
    TextColor3 = C.faint,
    Font = Enum.Font.GothamMedium,
    TextSize = 9,
    TextYAlignment = Enum.TextYAlignment.Top,
    Text = "Cara: create.roblox.com > Credentials > buat API Key, tambahkan sistem 'Assets' dengan izin Read + Write. Kalau key dibatasi IP, kosongkan batas IP supaya bisa dipakai dari HP/PC ini. User ID = ID akun pemilik asset. Key disimpan di file workspace executor (xyurei_music/bypass_cfg.json), jangan dibagikan. URL Relay diisi kalau kamu hosting server relay: file dikirim per potongan ke website lalu website yang upload ke Roblox. Kosongkan untuk upload langsung dari executor.",
  })

  local testBtn = button(
    viewSet, "TES BINARY EXECUTOR", UDim2.new(1, -4, 0, 34), UDim2.fromOffset(0, 368), C.card2,
    10
  )

  local testMsg = label(viewSet, {
    Size = UDim2.new(1, -4, 0, 60),
    Position = UDim2.fromOffset(2, 408),
    TextWrapped = true,
    TextColor3 = C.faint,
    Font = Enum.Font.GothamMedium,
    TextSize = 9,
    TextYAlignment = Enum.TextYAlignment.Top,
    Text = "Kalau upload error 'FileContent field is required', tekan ini untuk cek apakah executor mengirim data biner dengan utuh.",
  })

  local testing = false

  testBtn.Activated:Connect(function()
    if testing then
      return
    end

    if not httpReq then
      testMsg.Text = "Executor tidak punya fungsi request()."
      testMsg.TextColor3 = C.danger
      return
    end

    testing = true
    testBtn.Text = "MENGETES..."

    task.spawn(function()
      local bytes = table.create(256)

      for i = 0, 255 do
        bytes[i + 1] = string.char(i)
      end

      local payload = table.concat(bytes)

      local ok, res = pcall(httpReq, {
        Url = "https://httpbin.org/post",
        Method = "POST",
        Headers = { ["Content-Type"] = "application/octet-stream" },
        Body = payload,
      })

      testing = false
      testBtn.Text = "TES BINARY EXECUTOR"

      if not ok or type(res) ~= "table" or tonumber(res.StatusCode) ~= 200 then
        testMsg.Text = "Tes gagal terkirim: " .. tostring(ok and res and res.StatusCode or res)
        testMsg.TextColor3 = C.warn
        return
      end

      local okJ, d = pcall(function() return HS:JSONDecode(res.Body) end)
      local got

      if okJ and type(d) == "table" then
        if type(d.headers) == "table" then
          got = tonumber(d.headers["Content-Length"])
        end

        if not got and type(d.data) == "string" then
          local b64 = d.data:match("base64,(.*)$")

          if b64 then
            local pad = #(b64:match("=*$") or "")
            got = #b64 / 4 * 3 - pad
          else
            got = #d.data
          end
        end
      end

      if not got then
        testMsg.Text = "Tes tidak bisa dibaca hasilnya."
        testMsg.TextColor3 = C.warn
        return
      end

      if got == 256 then
        testMsg.Text = "OK ✓ data biner terkirim utuh (256/256 byte). Kalau upload masih gagal, coba file yang lebih kecil."
        testMsg.TextColor3 = C.ok
      elseif got < 256 then
        testMsg.Text = ("GAGAL: executor memotong data biner (server hanya terima %d dari 256 byte). Upload mp3/ogg/wav tidak bisa lewat executor ini."):format(got)
        testMsg.TextColor3 = C.danger
      else
        testMsg.Text = ("GAGAL: executor mengubah data biner ke UTF-8 (256 byte jadi %d). Upload file tidak bisa lewat executor ini."):format(got)
        testMsg.TextColor3 = C.danger
      end
    end)
  end)

  local mpBtn = button(
    viewSet, "TES MULTIPART", UDim2.new(1, -4, 0, 34), UDim2.fromOffset(0, 536), C.card2, 10
  )

  local mpMsg = label(viewSet, {
    Size = UDim2.new(1, -4, 0, 80),
    Position = UDim2.fromOffset(2, 576),
    TextWrapped = true,
    TextColor3 = C.faint,
    Font = Enum.Font.GothamMedium,
    TextSize = 9,
    TextYAlignment = Enum.TextYAlignment.Top,
    Text = "Mengirim multipart (data palsu 1 KB dan 3 MB) ke httpbin untuk cek apakah bagian file terbaca server.",
  })

  local mping = false

  mpBtn.Activated:Connect(function()
    if mping then
      return
    end

    if not httpReq then
      mpMsg.Text = "Executor tidak punya fungsi request()."
      mpMsg.TextColor3 = C.danger
      return
    end

    mping = true
    mpBtn.Text = "MENGETES..."

    task.spawn(function()
      local chunk = {}

      for i = 0, 255 do
        chunk[i + 1] = string.char(i)
      end

      chunk = table.concat(chunk)
      local lines, allOk = {}, true

      for _, kb in ipairs({ 1, 3072 }) do
        local data = string.rep(chunk, kb * 4)

        local body, ctype = buildMultipart(
          HS:JSONEncode({ assetType = "Audio" }), "mp3", "audio/mpeg", data
        )

        local ok, res = pcall(httpReq, {
          Url = "https://httpbin.org/post",
          Method = "POST",
          Headers = { ["Content-Type"] = ctype },
          Body = body,
        })

        if not ok or type(res) ~= "table" or tonumber(res.StatusCode) ~= 200 then
          allOk = false

          lines[#lines + 1] = ("%d KB: gagal (%s)"):format(kb, tostring(ok and res and res.StatusCode
            or res))
        else
          local okJ, d = pcall(function() return HS:JSONDecode(res.Body) end)

          local fileOK = okJ and type(d) == "table" and type(d.files) == "table"
            and d.files.fileContent ~= nil

          local reqOK = okJ and type(d) == "table" and type(d.form) == "table"
            and d.form.request ~= nil

          if not (fileOK and reqOK) then
            allOk = false
          end

          lines[#lines + 1] = ("%d KB: file %s · request %s"):format(kb, fileOK and "✓"
            or "✗ HILANG", reqOK and "✓"
            or "✗ HILANG")
        end
      end

      mping = false
      mpBtn.Text = "TES MULTIPART"

      mpMsg.Text = table.concat(lines, "\n")
        .. (allOk and "\nFormat multipart OK di server standar."
          or "\nAda yang gagal — kirim hasil ini ke Claude.")

      mpMsg.TextColor3 = allOk and C.ok or C.danger
    end)
  end)

  local validated = false
  local validatedKey, validatedUid, validatedName, validatedRelay = nil, nil, "", ""

  local function normRelay(s)
    s = trim(s):gsub("/+$", "")
    return s
  end

  local function setSetMsg(text, color)
    setMsgLbl.Text = tostring(text)
    setMsgLbl.TextColor3 = color or C.sub
  end

  local function refreshSaveBtn()
    saveBtn.BackgroundColor3 = validated and C.ok or C.card2
    saveBtn.TextColor3 = validated and C.bg or C.faint
  end

  local function onEdited()
    local k, u, r = trim(keyBox.Text), trim(uidBox.Text), normRelay(relayBox.Text)

    if validated and (k ~= validatedKey or u ~= validatedUid or r ~= validatedRelay) then
      validated = false
      setSetMsg("Data berubah — tekan VALIDASI lagi.", C.warn)
      refreshSaveBtn()
    end
  end

  keyBox:GetPropertyChangedSignal("Text"):Connect(onEdited)
  uidBox:GetPropertyChangedSignal("Text"):Connect(onEdited)
  relayBox:GetPropertyChangedSignal("Text"):Connect(onEdited)

  local function loadSettingsView()
    keyBox.Text = cfg.key
    uidBox.Text = cfg.uid
    relayBox.Text = cfg.relay
    validated = cfg.saved
    validatedKey, validatedUid, validatedName, validatedRelay = cfg.key, cfg.uid, cfg.name, cfg.relay
    refreshSaveBtn()

    if cfg.saved then
      setSetMsg("Tersimpan & valid (" .. (cfg.name ~= "" and cfg.name or "User")
        .. "). Siap upload.", C.ok)
    else
      setSetMsg("Isi API Key + User ID, tekan VALIDASI, lalu SIMPAN.", C.sub)
    end
  end

  local validating = false

  valBtn.Activated:Connect(function()
    if validating then
      return
    end

    local key, uidText, relayUrl = trim(keyBox.Text), trim(uidBox.Text), normRelay(relayBox.Text)
    local uid = uidText:match("^%d+$")

    if key == "" then
      setSetMsg("API Key masih kosong.", C.danger)
      return
    end

    if not uid then
      setSetMsg("User ID harus angka.", C.danger)
      return
    end

    if relayUrl ~= "" and not relayUrl:match("^https?://") then
      setSetMsg("URL relay harus diawali http:// atau https://", C.danger)
      return
    end

    if not httpReq then
      setSetMsg("Executor tidak punya fungsi request().", C.danger)
      return
    end

    validating = true
    valBtn.Text = "..."
    validated = false
    refreshSaveBtn()
    setSetMsg("Memeriksa User ID & API Key...", C.warn)

    task.spawn(function()
      local function finish(text, color, ok)
        validating = false
        valBtn.Text = "VALIDASI"
        setSetMsg(text, color)
        validated = ok == true

        if ok then
          validatedKey, validatedUid, validatedRelay = key, uidText, relayUrl
        end

        refreshSaveBtn()
      end

      if relayUrl ~= "" then
        setSetMsg(
          "Menghubungi website relay (server gratis bisa butuh ~30 detik untuk bangun)...",
          C.warn
        )

        local okR, resR = pcall(httpReq, {
          Url = relayUrl .. "/ping",
          Method = "GET",
          Headers = cfg.secret ~= "" and { ["x-relay-secret"] = cfg.secret } or nil,
        })

        local relayOk = false

        if okR and type(resR) == "table" and tonumber(resR.StatusCode) == 200 then
          local okJ, dR = pcall(function() return HS:JSONDecode(resR.Body or "") end)
          relayOk = okJ and type(dR) == "table" and dR.ok == true
        end

        if not relayOk then
          return finish("Relay tidak menjawab di " .. relayUrl
            .. " (cek URL / server belum jalan). Kosongkan kolom relay untuk upload langsung.", C.danger, false)
        end
      end

      local okU, resU = pcall(httpReq, {
        Url = "https://users.roblox.com/v1/users/" .. uid,
        Method = "GET",
      })

      local uname = ""

      if okU and type(resU) == "table" then
        local code = tonumber(resU.StatusCode)

        if code == 200 then
          local okJ, d = pcall(function() return HS:JSONDecode(resU.Body) end)

          if okJ and type(d) == "table" then
            uname = tostring(d.name or d.displayName or "")
          end
        elseif code == 404 or code == 400 then
          return finish("User ID " .. uid .. " tidak ditemukan.", C.danger, false)
        else
          return finish("Gagal cek User ID (HTTP " .. tostring(code) .. ").", C.danger, false)
        end
      else
        return finish("Gagal cek User ID: " .. tostring(resU), C.danger, false)
      end

      local okK, resK = pcall(httpReq, {
        Url = "https://apis.roblox.com/assets/v1/operations/xyurei-validate-probe",
        Method = "GET",
        Headers = { ["x-api-key"] = key },
      })

      if not okK or type(resK) ~= "table" then
        return finish("Gagal cek API Key: " .. tostring(resK), C.danger, false)
      end

      local code = tonumber(resK.StatusCode)

      if code == 401 then
        return finish("API Key tidak valid (401). Cek lagi key-nya.", C.danger, false)
      elseif code == 403 then
        return finish(
          "Key dikenali tapi ditolak (403): pastikan ada izin Assets Read+Write dan batas IP kosong.",
          C.danger, false
        )
      elseif code == 429 then
        return finish("Kena rate limit (429), coba lagi sebentar.", C.warn, false)
      elseif code == 404 or code == 400 or code == 200 then
        validatedName = uname

        return finish(
          "VALID ✓ User: " .. (uname ~= "" and uname or uid) .. ". Tekan SIMPAN.", C.ok, true
        )
      end

      finish("Respons tak terduga (HTTP " .. tostring(code) .. ").", C.danger, false)
    end)
  end)

  saveBtn.Activated:Connect(function()
    if not validated then
      setSetMsg("Validasi dulu sebelum menyimpan.", C.warn)
      return
    end

    cfg.key, cfg.uid, cfg.name, cfg.saved = validatedKey, validatedUid, validatedName or "", true
    cfg.relay = RELAY_LOCKED and CFG_RELAY or validatedRelay or ""

    if RELAY_LOCKED then
      cfg.secret = CFG_SECRET
    end

    local ok = saveCfg()
    refreshApiInfo()

    setSetMsg(ok and "Tersimpan ✓ Sekarang bisa UPLOAD TO ROBLOX."
      or "Dipakai untuk sesi ini (executor tidak bisa menyimpan file).", C.ok)

    setStatus("API UPLOAD TERSIMPAN", C.ok)
  end)

  gearBtn.Activated:Connect(function()
    loadSettingsView()
    showView("settings")
  end)

  backSet.Activated:Connect(function()
    showView(prevView == "edit" and selected and "edit" or "list")
  end)

  local MIME = { mp3 = "audio/mpeg", ogg = "audio/ogg", wav = "audio/wav" }

  local function bakeWav(data, vol, speed, progress)
    if #data < 44 or data:sub(1, 4) ~= "RIFF" or data:sub(9, 12) ~= "WAVE" then
      return nil, "bukan WAV valid"
    end

    local pos, fmtOK, ch, rate, dataStart, dataLen = 13, false, 0, 0, nil, 0

    while pos + 8 <= #data + 1 do
      local id = data:sub(pos, pos + 3)
      local size = string.unpack("<I4", data, pos + 4)

      if id == "fmt " then
        local tag, c, r, _, _, bits = string.unpack("<I2I2I4I4I2I2", data, pos + 8)

        if tag == 1 and bits == 16 and c >= 1 and c <= 8 then
          fmtOK = true
          ch = c
          rate = r
        end
      elseif id == "data" then
        dataStart = pos + 8
        dataLen = math.min(size, #data - dataStart + 1)
        break
      end

      pos = pos + 8 + size + size % 2
    end

    if not fmtOK then
      return nil, "WAV bukan PCM 16-bit"
    end

    if not dataStart then
      return nil, "chunk data WAV tidak ditemukan"
    end

    local frameSize = ch * 2
    local inFrames = math.floor(dataLen / frameSize)
    local outFrames = math.floor(inFrames / speed)

    if outFrames < 1 then
      return nil, "audio terlalu pendek"
    end

    local fmtStr = "<" .. string.rep("i2", ch)
    local parts, buf, nbuf = {}, {}, 0

    for j = 0, outFrames - 1 do
      local p = j * speed
      local i0 = math.floor(p)
      local fr = p - i0
      local i1 = math.min(i0 + 1, inFrames - 1)
      local vals = table.create(ch)

      for c = 0, ch - 1 do
        local a = string.unpack("<i2", data, dataStart + i0 * frameSize + c * 2)
        local b = a

        if fr > 0 and i1 ~= i0 then
          b = string.unpack("<i2", data, dataStart + i1 * frameSize + c * 2)
        end

        local v = (a + (b - a) * fr) * vol
        vals[c + 1] = math.floor(math.clamp(v, -32768, 32767) + 0.5)
      end

      nbuf = nbuf + 1
      buf[nbuf] = string.pack(fmtStr, table.unpack(vals))

      if nbuf >= 20000 then
        parts[#parts + 1] = table.concat(buf, "", 1, nbuf)
        buf, nbuf = {}, 0
        progress(j / outFrames)
        task.wait()
      end
    end

    if nbuf > 0 then
      parts[#parts + 1] = table.concat(buf, "", 1, nbuf)
    end

    local pcm = table.concat(parts)

    local header = "RIFF" .. string.pack("<I4", 36 + #pcm) .. "WAVE" .. "fmt " .. string.pack(
      "<I4I2I2I4I4I2I2", 16, 1, ch, rate, rate * frameSize, frameSize, 16
    ) .. "data" .. string.pack("<I4", #pcm)

    return header .. pcm
  end

  local lastId, lastBaked = nil, false

  local function soundSnippet(id, baked)
    local lines = {
      "local s = Instance.new(\"Sound\")", "s.SoundId = \"rbxassetid://" .. id .. "\"",
      ("s.Volume = %.2f"):format(baked and 1 or P.vol),
      ("s.PlaybackSpeed = %.2f"):format(baked and 1 or P.speed),
    }

    if P.pitch ~= 0 then
      lines[#lines + 1] = "local fx = Instance.new(\"PitchShiftSoundEffect\", s)"
      lines[#lines + 1] = ("fx.Octave = %.4f"):format(math.clamp(2 ^ (P.pitch / 12), 0.5, 2))
    end

    lines[#lines + 1] = "s.Parent = workspace"
    lines[#lines + 1] = "s:Play()"

    return table.concat(lines, "\n")
  end

  local uploading = false

  uploadBtn.Activated:Connect(function()
    if uploading or not selected then
      return
    end

    copyIdBtn.Visible = false
    copySetBtn.Visible = false

    if not cfg.saved then
      setMsg("API Key / User ID belum diatur. Buka ⚙ → VALIDASI → SIMPAN dulu.", C.warn)
      loadSettingsView()
      showView("settings")
      return
    end

    if not httpReq then
      setMsg("Executor tidak punya fungsi request().", C.danger)
      return
    end

    uploading = true
    uploadBtn.Text = "MEMPROSES..."
    stopPreview()
    local snap = { vol = P.vol, pitch = P.pitch, speed = P.speed }
    local file = selected

    task.spawn(function()
      local function done(text, color)
        uploading = false
        uploadBtn.Text = "UPLOAD TO ROBLOX"
        setMsg(text, color)
      end

      local okR, data = pcall(readfile, file.path)

      if not okR or type(data) ~= "string" or #data == 0 then
        return done("Gagal membaca file: " .. tostring(data), C.danger)
      end

      local baked = false

      if file.ext == "wav" and (snap.vol ~= 1 or snap.speed ~= 1) then
        setMsg("Memproses WAV (volume/speed)...", C.warn)

        local out, err = bakeWav(data, snap.vol, snap.speed, function(r)
          uploadBtn.Text = ("MEMPROSES %d%%"):format(math.floor(r * 100))
        end)

        if out then
          data = out
          baked = true
        else
          setMsg("WAV tidak diproses (" .. tostring(err) .. "), diupload apa adanya.", C.warn)
        end
      end

      if #data > 20 * 1024 * 1024 then
        return done("File > 20 MB, melebihi batas upload Roblox.", C.danger)
      end

      uploadBtn.Text = "UPLOADING..."
      setMsg("Mengirim ke Roblox (" .. math.floor(#data / 1024) .. " KB)...", C.warn)
      setStatus("UPLOADING " .. file.name, C.warn)
      local displayName = file.name:gsub("%.[^%.]+$", ""):sub(1, 50)

      if displayName == "" then
        displayName = "Tools Engine Audio"
      end

      local reqJson = HS:JSONEncode({
        assetType = "Audio",
        displayName = displayName,
        description = "Uploaded via Tools Engine",
        creationContext = { creator = { userId = tostring(cfg.uid) } },
      })

      local assetId, errText
      local useRelay = cfg.relay ~= ""

      if useRelay then
        local base = cfg.relay:gsub("/+$", "")
        local CH = 1024 * 1024
        local total = math.ceil(#data / CH)
        local jobId = ("x%d%d"):format(os.time(), math.random(100000, 999999))

        local function relayHeaders(extra)
          local h = extra or {}

          if cfg.secret ~= "" then
            h["x-relay-secret"] = cfg.secret
          end

          return h
        end

        for i = 1, total do
          local piece = data:sub((i - 1) * CH + 1, i * CH)
          uploadBtn.Text = ("KIRIM KE WEBSITE %d/%d"):format(i, total)
          local sent, lastErr = false, "?"

          for attempt = 1, 3 do
            local okC, rC = pcall(httpReq, {
              Url = base .. "/chunk",
              Method = "POST",
              Headers = relayHeaders({
                ["Content-Type"] = "application/octet-stream",
                ["x-upload-id"] = jobId,
                ["x-chunk-index"] = tostring(i),
                ["x-chunk-total"] = tostring(total),
              }),
              Body = piece,
            })

            if okC and type(rC) == "table" and tonumber(rC.StatusCode) == 200 then
              sent = true
              break
            end

            lastErr = okC
                and type(rC) == "table"
                and "HTTP " .. tostring(rC.StatusCode) .. " "
                  .. tostring(rC.Body or ""):sub(1, 120)
              or tostring(rC)

            task.wait(1.5)
          end

          if not sent then
            return done(
              ("Gagal kirim bagian %d/%d ke website: %s"):format(i, total, lastErr), C.danger
            )
          end

          task.wait()
        end

        uploadBtn.Text = "WEBSITE UPLOAD KE ROBLOX..."

        local okF, rF = pcall(httpReq, {
          Url = base .. "/finish",
          Method = "POST",
          Headers = relayHeaders({ ["Content-Type"] = "application/json" }),
          Body = HS:JSONEncode({
            id = jobId,
            key = cfg.key,
            uid = tostring(cfg.uid),
            displayName = displayName,
            ext = file.ext,
            total = total,
            size = #data,
          }),
        })

        if not okF or type(rF) ~= "table" then
          return done("Gagal menghubungi website: " .. tostring(rF), C.danger)
        end

        if tonumber(rF.StatusCode) ~= 200 then
          local okE, dE = pcall(function() return HS:JSONDecode(rF.Body or "") end)

          return done("Website menolak: "
            .. (okE and type(dE) == "table" and dE.error or "HTTP " .. tostring(rF.StatusCode)), C.danger)
        end

        for attempt = 1, 70 do
          task.wait(2)
          uploadBtn.Text = ("MENUNGGU ROBLOX %d"):format(attempt)

          local okJ2, rJ = pcall(httpReq, {
            Url = base .. "/job?id=" .. jobId,
            Method = "GET",
            Headers = relayHeaders(),
          })

          if okJ2 and type(rJ) == "table" and tonumber(rJ.StatusCode) == 200 then
            local okD, job = pcall(function() return HS:JSONDecode(rJ.Body or "") end)

            if okD and type(job) == "table" then
              if job.status == "done" and job.assetId then
                assetId = tostring(job.assetId)
                break
              end

              if job.status == "error" then
                errText = tostring(job.message or "upload gagal")
                break
              end
            end
          end
        end
      else
        local variants = {
          { name = "standar", mime = MIME[file.ext], opts = {} },
          {
            name = "octet-stream",
            mime = "application/octet-stream",
            opts = { filename = displayName:gsub("[^%w_%-]", "_") .. "." .. file.ext },
          },
          { name = "file-duluan", mime = MIME[file.ext], opts = { fileFirst = true } },
        }

        local body, ctype, ok, res, code, okJ, d
        local usedVariant = ""

        for vi, v in ipairs(variants) do
          body, ctype = buildMultipart(reqJson, file.ext, v.mime, data, v.opts)
          usedVariant = v.name

          if vi > 1 then
            uploadBtn.Text = ("UPLOADING (%d/%d)"):format(vi, #variants)

            setMsg(("Format %s ditolak, coba varian '%s'..."):format(
              variants[vi - 1].name, v.name
            ), C.warn)
          end

          ok, res = pcall(httpReq, {
            Url = "https://apis.roblox.com/assets/v1/assets",
            Method = "POST",
            Headers = { ["x-api-key"] = cfg.key, ["Content-Type"] = ctype },
            Body = body,
          })

          if not ok or type(res) ~= "table" then
            return done("Request gagal: " .. tostring(res), C.danger)
          end

          code = tonumber(res.StatusCode)
          okJ, d = pcall(function() return HS:JSONDecode(res.Body or "") end)
          local rawBody = tostring(res.Body or "")

          if not (code == 400 and rawBody:find("FileContent", 1, true)) then
            break
          end
        end

        if code == 400 and tostring(res.Body or ""):find("FileContent", 1, true) then
          uploadBtn.Text = "MENGECEK EXECUTOR..."
          local diag

          local okE, rE = pcall(httpReq, {
            Url = "https://httpbin.org/post",
            Method = "POST",
            Headers = { ["Content-Type"] = ctype },
            Body = body,
          })

          if okE and type(rE) == "table" then
            local got = tonumber(tostring(rE.Body or ""):match("\"Content%-Length\":%s*\"(%d+)\""))

            if got and got < #body then
              diag = ("DIAGNOSA: executor hanya mengirim %d dari %d byte (terpotong). File %d KB terlalu besar untuk executor ini; coba mp3 yang lebih kecil/bitrate lebih rendah."):format(got, #body, math.floor(#data
                / 1024))
            elseif got then
              diag = ("DIAGNOSA: executor mengirim utuh (%d byte), jadi masalah ada di sisi Roblox (cek key/izin Assets, atau coba file lebih kecil)."):format(got)
            else
              diag = "DIAGNOSA: respons tes echo tidak terbaca (HTTP "
                .. tostring(rE.StatusCode) .. ")."
            end
          else
            diag = "DIAGNOSA: tes echo gagal terkirim (" .. tostring(rE)
              .. ") — kemungkinan body terlalu besar untuk executor."
          end

          return done(("Gagal (HTTP 400): FileContent tidak terbaca di semua varian format.\n[uid %s · %d KB · %s]\n%s"):format(tostring(cfg.uid), math.floor(#data
            / 1024), file.ext, diag), C.danger)
        end

        if code == 401 then
          return done("API Key ditolak (401). Cek di ⚙ lalu validasi ulang.", C.danger)
        end

        if code == 403 then
          return done(
            "Ditolak (403): izin Assets Read+Write kurang / batas IP / user bukan pemilik key.",
            C.danger
          )
        end

        if code == 429 then
          return done("Kena limit upload (429). Batas bulanan / rate limit tercapai.", C.danger)
        end

        if not okJ or type(d) ~= "table" then
          return done("Respons tak terduga (HTTP " .. tostring(code) .. ").", C.danger)
        end

        if code and code >= 400 then
          local detail = d.message or d.code

          if not detail then
            detail = tostring(res.Body or ""):sub(1, 300)
          end

          local hint = tostring(detail):find("FileContent", 1, true)
              and "\nPetunjuk: buka ⚙ lalu tekan TES BINARY EXECUTOR."
            or ""

          return done(("Gagal (HTTP %s): %s\n[uid %s · %d KB · %s]"):format(
            tostring(code), tostring(detail), tostring(cfg.uid), math.floor(#data / 1024),
            file.ext
          ) .. hint, C.danger)
        end

        local opPath = d.path

        if type(opPath) ~= "string" then
          return done("Roblox tidak memberi operation ID.", C.danger)
        end

        for attempt = 1, 40 do
          task.wait(1.5)
          uploadBtn.Text = ("MENUNGGU ROBLOX %d"):format(attempt)

          local okP, rp = pcall(httpReq, {
            Url = "https://apis.roblox.com/assets/v1/" .. opPath,
            Method = "GET",
            Headers = { ["x-api-key"] = cfg.key },
          })

          if okP and type(rp) == "table" then
            local okD, op = pcall(function() return HS:JSONDecode(rp.Body or "") end)

            if okD and type(op) == "table" then
              if op.done == true then
                if type(op.response) == "table" and op.response.assetId then
                  assetId = tostring(op.response.assetId)
                elseif type(op.error) == "table" then
                  errText = tostring(op.error.message or op.error.code or "upload ditolak")
                else
                  errText = "operasi selesai tanpa asset ID"
                end

                break
              end
            end
          end
        end
      end

      if errText then
        return done("Upload gagal: " .. errText, C.danger)
      end

      if not assetId then
        return done("Timeout menunggu Roblox. Cek di Creator Hub > Creations > Audio.", C.warn)
      end

      lastId, lastBaked = assetId, baked
      copyIdBtn.Visible = true
      copySetBtn.Visible = true

      done("BERHASIL ✓ ID: " .. assetId .. " (rbxassetid://" .. assetId .. ")"
        .. (baked and "\nVolume/speed sudah dibakar ke file." or "")
        .. "\nAudio bisa butuh moderasi sebentar sebelum bisa diputar.", C.ok)

      setStatus("UPLOAD SELESAI • ID " .. assetId, C.ok)
      notify("BYPASS MUSIC", file.name .. " terupload. ID " .. assetId, true)
    end)
  end)

  copyIdBtn.Activated:Connect(function()
    if not lastId then
      return
    end

    copyIdBtn.Text = copy(lastId) and "TERSALIN ✓" or "ID " .. lastId
    task.delay(1.5, function() copyIdBtn.Text = "SALIN ID" end)
  end)

  copySetBtn.Activated:Connect(function()
    if not lastId then
      return
    end

    copySetBtn.Text = copy(soundSnippet(lastId, lastBaked)) and "TERSALIN ✓"
      or "CLIPBOARD ✕"

    task.delay(1.5, function() copySetBtn.Text = "SALIN KODE SOUND" end)
  end)

  local function openEditor(file)
    stopPreview()
    selected = file
    fileTitle.Text = file.name
    fileSub.Text = file.ext:upper() .. " · " .. file.path
    resetFx()
    lastId = nil
    copyIdBtn.Visible = false
    copySetBtn.Visible = false

    setMsg(cfg.saved and "Atur setelan lalu tekan UPLOAD TO ROBLOX."
      or "Upload butuh API Key & User ID — atur dulu lewat ⚙ di daftar lagu.", cfg.saved and C.sub or C.warn)

    viewEdit.CanvasPosition = Vector2.new(0, 0)
    showView("edit")
  end

  backEdit.Activated:Connect(function()
    stopPreview()
    showView("list")
  end)

  local cards = {}

  local function audioExt(name)
    local e = name:lower():match("%.(%w+)$")

    if e == "mp3" or e == "ogg" or e == "wav" then
      return e
    end

    return nil
  end

  local function scanDeepAudio(folder, depth, results, seenF, seenFiles)
    if depth > 4 then
      return
    end

    local fk = canonicalWorkspacePath(folder)

    if fk == "" then
      fk = "__root__"
    end

    if seenF[fk] then
      return
    end

    seenF[fk] = true
    local items = safeListFiles(folder)

    if not items then
      return
    end

    for _, path in ipairs(items) do
      local name = getFileName(path)
      local ext = audioExt(name)

      if ext then
        local key = canonicalWorkspacePath(path)

        if key == "" then
          key = name:lower()
        end

        if not seenFiles[key] then
          seenFiles[key] = true
          results[#results + 1] = { name = name, path = path, ext = ext }
        end
      elseif looksFolder(path) then
        scanDeepAudio(path, depth + 1, results, seenF, seenFiles)
      end
    end
  end

  local function applyFilter()
    local q = trim(searchBox.Text):lower()
    local shown = 0

    for _, c in ipairs(cards) do
      local m = q == "" or c.file.name:lower():find(q, 1, true) ~= nil
      c.card.Visible = m

      if m then
        shown = shown + 1
      end
    end

    emptyLbl.Visible = shown == 0

    if #cards > 0 and shown == 0 then
      emptyLbl.Text = "TIDAK ADA YANG COCOK"
    else
      emptyLbl.Text = EMPTY_TXT
    end
  end

  local function makeAudioCard(file, order)
    local card = mk("TextButton", {
      Size = UDim2.new(1, -4, 0, 48),
      BackgroundColor3 = C.card2,
      BackgroundTransparency = 0.42,
      BorderSizePixel = 0,
      Text = "",
      AutoButtonColor = false,
      LayoutOrder = order,
      ZIndex = 14,
    }, list)

    round(card, 13)
    stroke(card, C.white, 1, 0.85)
    glass(card)

    local bar = mk("Frame", {
      Size = UDim2.new(0, 3, 0.6, 0),
      Position = UDim2.new(0, 0, 0.2, 0),
      BackgroundColor3 = ORANGE,
      BorderSizePixel = 0,
      ZIndex = 15,
    }, card)

    round(bar, 2)

    local badge = label(card, {
      Size = UDim2.fromOffset(40, 16),
      Position = UDim2.fromOffset(12, 8),
      BackgroundTransparency = 0.1,
      BackgroundColor3 = C.bg,
      Text = file.ext:upper(),
      TextColor3 = ORANGE,
      Font = Enum.Font.GothamBlack,
      TextSize = 10,
      TextXAlignment = Enum.TextXAlignment.Center,
    })

    round(badge, 5)
    stroke(badge, ORANGE, 1, 0.6)

    label(card, {
      Size = UDim2.new(1, -112, 0, 14),
      Position = UDim2.fromOffset(60, 8),
      Text = file.name,
      TextSize = 11,
      TextTruncate = Enum.TextTruncate.AtEnd,
    })

    label(card, {
      Size = UDim2.new(1, -112, 0, 12),
      Position = UDim2.fromOffset(60, 26),
      Text = file.path,
      TextColor3 = C.faint,
      Font = Enum.Font.Code,
      TextSize = 9,
      TextTruncate = Enum.TextTruncate.AtEnd,
    })

    label(card, {
      Size = UDim2.fromOffset(30, 48),
      Position = UDim2.new(1, -38, 0, 0),
      Text = "›",
      TextColor3 = C.sub,
      TextSize = 22,
      Font = Enum.Font.GothamBlack,
      TextXAlignment = Enum.TextXAlignment.Center,
    })

    card.Activated:Connect(function() openEditor(file) end)
    cards[#cards + 1] = { card = card, file = file }
  end

  local scanning = false

  local function scanAudio()
    if scanning then
      return
    end

    if type(listfiles) ~= "function" then
      emptyLbl.Text = "LISTFILES TIDAK TERSEDIA DI EXECUTOR"
      emptyLbl.Visible = true
      return
    end

    scanning = true
    scanBtn.Text = "..."

    for _, c in ipairs(cards) do
      c.card:Destroy()
    end

    cards = {}

    emptyLbl.Text = "SCANNING..."
    emptyLbl.Visible = true

    task.spawn(function()
      local results, seenF, seenFiles = {}, {}, {}

      for _, p in ipairs(SCAN_PATHS) do
        if safeListFiles(p) then
          scanDeepAudio(p, 0, results, seenF, seenFiles)
        end
      end

      table.sort(results, function(a, b) return a.name:lower() < b.name:lower() end)

      for i, f in ipairs(results) do
        makeAudioCard(f, i)

        if i % 15 == 0 then
          task.wait()
        end
      end

      scanning = false
      scanBtn.Text = "SCAN"
      applyFilter()

      setStatus(
        ("BYPASS MUSIC • %d FILE AUDIO"):format(#results), #results > 0 and C.ok or C.warn
      )
    end)
  end

  scanBtn.Activated:Connect(scanAudio)
  searchBox:GetPropertyChangedSignal("Text"):Connect(applyFilter)
  gui.Destroying:Connect(function() pcall(function() sound:Stop() end) end)
  task.defer(scanAudio)
  return page
end

do
  local function __buildSpoofPage(env)
  local mk, round, stroke, gradient, label, glass, C = env.mk, env.round, env.stroke, env.gradient, env.label, env.glass, env.C
  local content, gui, setStatus, notify, httpReq = env.content, env.gui, env.setStatus, env.notify, env.httpReq
  local HS = game:GetService("HttpService")
  local UIS = game:GetService("UserInputService")
  local FOLDER = "xyurei_music"
  local CFG_FILE = FOLDER .. "/bypass_cfg.json"

  local cfg = {
    key = "",
    uid = "",
    name = "",
    saved = false,
    relay = "https://encrypt.xyurei.biz.id",
    secret = "9fK2mQ7pLz41vTb8Hn3",
    tipe = "User"
  }

  if type(readfile) == "function" and type(isfile) == "function" and isfile(CFG_FILE) then
    pcall(function()
      local d = HS:JSONDecode(readfile(CFG_FILE))
      if type(d) == "table" then
        if d.key then cfg.key = tostring(d.key) end
        if d.uid then cfg.uid = tostring(d.uid) end
        if d.name then cfg.name = tostring(d.name) end
        if d.valid then cfg.saved = d.valid == true end
        if d.tipe then cfg.tipe = tostring(d.tipe) end
      end
    end)
  end

  local function trim(s)
    return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
  end

  local function copy(text)
    local fn = setclipboard or toclipboard or (syn and syn.write_clipboard) or (Clipboard and Clipboard.set)
    if fn then
      return pcall(fn, tostring(text))
    end
    return false
  end

  -- =====================================================================
  -- ENGINE UTAMA: 60FPS SPOOFER + AUTO PLACE ID BYPASS
  -- =====================================================================
  local spoofCache = {}
  local lastWorkingPlaceId = nil
  local DEFAULT_SEEDS = {
    119031818630096, 76077593225337, 131528987147518,
    125981614068947, 112742012181598, 6872265039,
    5765186170, 3271915715, 4483381587, 7415484388,
  }

  local function decodeJson(res)
    if not res or not res.Body then return nil end
    local ok, d = pcall(function() return HS:JSONDecode(res.Body) end)
    return ok and d or nil
  end

  local function buatMultipart(reqJson, namaFile, mime, dataFile)
    local batas = "----WebKitFormBoundary" .. tostring(math.random(10000000, 99999999))
    local body = "--" .. batas .. "\\r\\n"
        .. 'Content-Disposition: form-data; name="request"\\r\\n'
        .. "Content-Type: application/json\\r\\n\\r\\n"
        .. reqJson .. "\\r\\n"
        .. "--" .. batas .. "\\r\\n"
        .. 'Content-Disposition: form-data; name="fileContent"; filename="' .. namaFile .. '"\\r\\n'
        .. "Content-Type: " .. mime .. "\\r\\n\\r\\n"
        .. dataFile .. "\\r\\n"
        .. "--" .. batas .. "--\\r\\n"
    return body, batas
  end

  local function ambilDetailAset(aid)
    local name, creatorId, creatorType = nil, nil, nil
    local ok1, res1 = pcall(httpReq, {
      Url = "https://economy.roblox.com/v2/assets/" .. aid .. "/details",
      Method = "GET",
      Headers = {["User-Agent"] = "Roblox/WinInet"}
    })
    if ok1 and res1 and (res1.StatusCode == 200 or res1.Status == 200) then
      local d = decodeJson(res1)
      if d then
        name = d.Name or d.TargetName
        local c = d.Creator
        if c then
          creatorId = c.CreatorTargetId or c.Id
          creatorType = c.CreatorType
        end
      end
    end

    if not name then
      local ok2, res2 = pcall(httpReq, {
        Url = "https://develop.roblox.com/v1/assets?assetIds=" .. aid,
        Method = "GET",
        Headers = {["User-Agent"] = "Roblox/WinInet"}
      })
      if ok2 and res2 and (res2.StatusCode == 200 or res2.Status == 200) then
        local d = decodeJson(res2)
        if d and d.data and d.data[1] then
          name = d.data[1].name
          local c = d.data[1].creator
          if c then
            creatorId = c.id
            creatorType = c.type
          end
        end
      end
    end

    local cleanName = name and name:gsub("[^%w%s%-_]", ""):sub(1, 35) or ("Asset_" .. aid)
    if cleanName == "" then cleanName = "Asset_" .. aid end
    return cleanName, creatorId, creatorType
  end

  local function unduhAssetCepat(aid, srcCId, srcCType)
    local function cobaDownload(pid)
      local h = {["User-Agent"] = "Roblox/WinInet"}
      if pid then h["Roblox-Place-Id"] = tostring(pid) end
      local ok, r = pcall(httpReq, {
        Url = "https://assetdelivery.roblox.com/v2/assetId/" .. aid,
        Method = "GET",
        Headers = h,
      })
      if ok and r and (r.StatusCode == 200 or r.Status == 200) then
        local d = decodeJson(r)
        if d and d.locations and d.locations[1] and d.locations[1].location then
          local ok2, r2 = pcall(httpReq, {
            Url = d.locations[1].location,
            Method = "GET",
            Headers = {["User-Agent"] = "Roblox/WinInet"}
          })
          if ok2 and r2 and (r2.StatusCode == 200 or r2.Status == 200)
            and type(r2.Body) == "string" and #r2.Body > 80 then
            return r2.Body
          end
        end
      end
      return nil
    end

    -- 1. game.PlaceId (Current game di Delta)
    if game.PlaceId and game.PlaceId > 0 then
      local b = cobaDownload(game.PlaceId)
      if b then
        lastWorkingPlaceId = game.PlaceId
        return b
      end
    end

    -- 2. lastWorkingPlaceId
    if lastWorkingPlaceId and lastWorkingPlaceId ~= game.PlaceId then
      local b = cobaDownload(lastWorkingPlaceId)
      if b then return b end
    end

    -- 3. Direct tanpa PlaceId
    local bDirect = cobaDownload(nil)
    if bDirect then return bDirect end

    -- 4. Auto detect game creator
    local placeList = {}
    if srcCId and srcCType == "User" then
      local okU, resU = pcall(httpReq, {
        Url = "https://games.roblox.com/v2/users/" .. srcCId .. "/games?accessFilter=Public&limit=6&sortOrder=Asc",
        Method = "GET",
        Headers = {["User-Agent"] = "Roblox/WinInet"}
      })
      if okU and resU and (resU.StatusCode == 200 or resU.Status == 200) then
        local dU = decodeJson(resU)
        if dU and dU.data then
          for _, g in ipairs(dU.data) do
            if g.rootPlace and g.rootPlace.id then table.insert(placeList, g.rootPlace.id) end
          end
        end
      end
    elseif srcCId and srcCType == "Group" then
      local okGrp, resGrp = pcall(httpReq, {
        Url = "https://games.roblox.com/v2/groups/" .. srcCId .. "/games?accessFilter=Public&limit=6&sortOrder=Asc",
        Method = "GET",
        Headers = {["User-Agent"] = "Roblox/WinInet"}
      })
      if okGrp and resGrp and (resGrp.StatusCode == 200 or resGrp.Status == 200) then
        local dG = decodeJson(resGrp)
        if dG and dG.data then
          for _, g in ipairs(dG.data) do
            if g.rootPlace and g.rootPlace.id then table.insert(placeList, g.rootPlace.id) end
          end
        end
      end
    end

    for _, pid in ipairs(placeList) do
      local b = cobaDownload(pid)
      if b then
        lastWorkingPlaceId = pid
        return b
      end
      task.wait(0.01)
    end

    -- 5. Bypass seeds
    for _, pid in ipairs(DEFAULT_SEEDS) do
      local b = cobaDownload(pid)
      if b then
        lastWorkingPlaceId = pid
        return b
      end
      task.wait(0.01)
    end

    -- 6. v1 fallback
    local okV1, rV1 = pcall(httpReq, {
      Url = "https://assetdelivery.roblox.com/v1/asset/?id=" .. aid,
      Method = "GET",
      Headers = {
        ["User-Agent"] = "Roblox/WinInet",
        ["Roblox-Place-Id"] = tostring(lastWorkingPlaceId or game.PlaceId or 6872265039)
      }
    })
    if okV1 and rV1 and (rV1.StatusCode == 200 or rV1.Status == 200)
      and type(rV1.Body) == "string" and #rV1.Body > 80 then
      local b = rV1.Body
      if not b:find('^{\\"errors\\"') and not b:find('^{\\"message\\"') and not b:find('^<') then
        return b
      end
    end

    -- 7. game:HttpGet client
    if game.HttpGet then
      local okG, bodyG = pcall(function()
        return game:HttpGet("https://assetdelivery.roblox.com/v1/asset/?id=" .. aid)
      end)
      if okG and type(bodyG) == "string" and #bodyG > 80 and not bodyG:find('^{\\"errors\\"') then
        return bodyG
      end
    end

    return nil
  end

  local function spoofAssetSingleCore(assetId, targetType, speedVal)
    local apiKey = trim(cfg.key)
    local creatorId = trim(cfg.uid):match("^%d+$")
    if apiKey == "" or not creatorId then
      return nil, "Isi Open Cloud API Key & Creator ID di bagian Pengaturan!"
    end

    local cacheKey = assetId .. "_" .. tostring(speedVal or "1.0") .. "_" .. tostring(targetType or "auto")
    if spoofCache[cacheKey] then
      local c = spoofCache[cacheKey]
      return c.id, c.name
    end

    local assetName, srcCId, srcCType = ambilDetailAset(assetId)
    local fileData = unduhAssetCepat(assetId, srcCId, srcCType)
    if not fileData then
      return nil, "Asset tidak dapat diunduh (private/rate-limit)", assetName
    end

    local finalType = targetType or "Audio"
    local ext = "mp3"
    local mime = "audio/mpeg"
    if finalType == "Animation" then
      ext = "rbxm"
      mime = "model/x-rbxm"
    elseif finalType == "Decal" then
      ext = "png"
      mime = "image/png"
    else
      finalType = "Audio"
      if fileData:sub(1, 4) == "OggS" then
        ext = "ogg"
        mime = "audio/ogg"
      else
        ext = "mp3"
        mime = "audio/mpeg"
      end
    end

    local creatorObj = {}
    if cfg.tipe == "Group" then
      creatorObj.groupId = creatorId
    else
      creatorObj.userId = creatorId
    end

    local speedLabel = (speedVal and speedVal ~= "1.0" and speedVal ~= "1") and (" (" .. speedVal .. "x)") or ""
    local displayName = (assetName .. speedLabel):sub(1, 45)

    local meta = HS:JSONEncode({
      assetType = finalType,
      displayName = displayName,
      description = "Spoofed via Importer Hub",
      creationContext = { creator = creatorObj }
    })

    local bodyReq, batas = buatMultipart(meta, displayName .. "." .. ext, mime, fileData)
    local okP, res = pcall(httpReq, {
      Url = "https://apis.roblox.com/assets/v1/assets",
      Method = "POST",
      Headers = {
        ["x-api-key"] = apiKey,
        ["Content-Type"] = "multipart/form-data; boundary=" .. batas,
      },
      Body = bodyReq
    })

    if not okP or not res then
      return nil, "Koneksi upload Open Cloud gagal", assetName
    end

    local d = decodeJson(res)
    if not d or not d.path then
      local errPesan = d and (d.message or d.error) or ("HTTP " .. tostring(res.StatusCode))
      return nil, "Ditolak Roblox: " .. tostring(errPesan), assetName
    end

    -- Polling adaptif cepat
    local newAssetId = nil
    local pollDelays = {0.3, 0.5, 0.7, 0.9, 0.9, 1.0, 1.0, 1.0, 1.2, 1.2, 1.5, 1.5}
    for _, delaySec in ipairs(pollDelays) do
      task.wait(delaySec)
      local okQ, r2 = pcall(httpReq, {
        Url = "https://apis.roblox.com/assets/v1/" .. d.path,
        Method = "GET",
        Headers = { ["x-api-key"] = apiKey }
      })
      local dOp = okQ and decodeJson(r2) or nil
      if dOp and dOp.done then
        if dOp.response and dOp.response.assetId then
          newAssetId = tostring(dOp.response.assetId)
          break
        else
          local msg = dOp.error and dOp.error.message or "Error processing"
          return nil, msg, assetName
        end
      end
    end

    if not newAssetId then
      return nil, "Proses upload timeout di server Roblox", assetName
    end

    spoofCache[cacheKey] = {id = newAssetId, name = assetName}
    return newAssetId, assetName
  end

  -- =====================================================================
  -- TAMPILAN UI SPOOFER & BYPASS (Mobile-Perfect Xiurey Style)
  -- =====================================================================
  local page = mk("ScrollingFrame", {
    Name = "Page_SPOOF",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = C.white,
    ScrollBarImageTransparency = 0.35,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.new(),
    ZIndex = 12,
  }, content)

  local listLayout = mk("UIListLayout", {
    Padding = UDim.new(0, 10),
    SortOrder = Enum.SortOrder.LayoutOrder,
  }, page)

  local pad = Instance.new("UIPadding")
  pad.PaddingTop = UDim.new(0, 8)
  pad.PaddingBottom = UDim.new(0, 24)
  pad.PaddingLeft = UDim.new(0, 8)
  pad.PaddingRight = UDim.new(0, 8)
  pad.Parent = page

  local function cardBox(order)
    local f = mk("Frame", {
      Size = UDim2.new(1, 0, 0, 0),
      AutomaticSize = Enum.AutomaticSize.Y,
      BackgroundColor3 = C.card,
      BackgroundTransparency = 0.35,
      BorderSizePixel = 0,
      LayoutOrder = order,
      ZIndex = 13,
    }, page)
    round(f, 12)
    stroke(f, C.white, 1, 0.85)
    glass(f)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, 10)
    p.PaddingBottom = UDim.new(0, 10)
    p.PaddingLeft = UDim.new(0, 10)
    p.PaddingRight = UDim.new(0, 10)
    p.Parent = f
    mk("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, f)
    return f
  end

  local function buatKotakKode(parent, order, ph, editable)
    local outer = mk("Frame", {
      Size = UDim2.new(1, 0, 0, editable and 80 or 70),
      BackgroundColor3 = Color3.fromRGB(8, 8, 12),
      BorderSizePixel = 0,
      ClipsDescendants = true,
      LayoutOrder = order,
      ZIndex = 14,
    }, parent)
    round(outer, 8)
    stroke(outer, C.cyan, 1, 0.75)

    local scroll = mk("ScrollingFrame", {
      Size = UDim2.new(1, -8, 1, -8),
      Position = UDim2.fromOffset(4, 4),
      BackgroundTransparency = 1,
      BorderSizePixel = 0,
      ScrollBarThickness = 4,
      ScrollBarImageColor3 = C.cyan,
      ScrollBarImageTransparency = 0.4,
      AutomaticCanvasSize = Enum.AutomaticSize.XY,
      CanvasSize = UDim2.new(),
      ZIndex = 15,
    }, outer)

    local tb = mk("TextBox", {
      Size = UDim2.new(1, 0, 1, 0),
      AutomaticSize = Enum.AutomaticSize.XY,
      BackgroundTransparency = 1,
      Font = Enum.Font.Code,
      TextSize = 11,
      TextColor3 = editable and C.white or Color3.fromRGB(70, 244, 176),
      PlaceholderText = ph or "",
      PlaceholderColor3 = C.faint,
      Text = "",
      ClearTextOnFocus = false,
      MultiLine = true,
      TextWrapped = true,
      TextEditable = editable ~= false,
      TextXAlignment = Enum.TextXAlignment.Left,
      TextYAlignment = Enum.TextYAlignment.Top,
      ZIndex = 16,
    }, scroll)
    return tb, outer
  end

  local function tombolAksi(parent, order, text, color)
    local b = mk("TextButton", {
      Size = UDim2.new(1, 0, 0, 32),
      BackgroundColor3 = color or C.purple,
      Text = text,
      TextColor3 = C.white,
      Font = Enum.Font.GothamBlack,
      TextSize = 11,
      AutoButtonColor = false,
      LayoutOrder = order,
      ZIndex = 14,
    }, parent)
    round(b, 8)
    stroke(b, C.white, 1, 0.7)
    return b
  end

  -- =====================================================================
  -- CARD 1: SPOOF MANUAL ASSET ID
  -- =====================================================================
  local c1 = cardBox(1)
  label(c1, {Text = "⚡ Spoof Asset ID (Auto Place ID Bypass)", Font = Enum.Font.GothamBlack, TextSize = 12, LayoutOrder = 1})
  label(c1, {Text = "Unduh aset private & upload ulang ke akun Anda secara otomatis.", TextColor3 = C.faint, TextSize = 10, LayoutOrder = 2})

  local inputIds, _ = buatKotakKode(c1, 3, "Tempel ID aset di sini (bisa banyak baris)...", true)

  -- Speed Selector Row
  local speedRow = mk("Frame", {Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, LayoutOrder = 4, ZIndex = 14}, c1)
  mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4)}, speedRow)

  local speedTerpilih = "1.0"
  local speedButtons = {}
  local daftarSpeed = {"0.8", "1.0", "1.2", "1.5", "1.8", "2.0", "2.5", "3.0"}
  local recLbl = label(c1, {
    Text = "💡 Rekomendasi Sound.PlaybackSpeed: 1.0 (Asli)",
    TextColor3 = Color3.fromRGB(255, 216, 70),
    TextSize = 10,
    LayoutOrder = 5
  })

  local function updateRecLabel()
    local spNum = tonumber(speedTerpilih) or 1.0
    local recSpeed = (spNum > 0) and string.format("%.4f", 1.0 / spNum) or "1.0"
    recLbl.Text = "💡 Rekomendasi Sound.PlaybackSpeed: " .. recSpeed .. (spNum ~= 1 and " (agar tempo lagu normal)" or " (Normal)")
  end

  for _, sp in ipairs(daftarSpeed) do
    local b = mk("TextButton", {
      Size = UDim2.new(0, 32, 1, 0),
      BackgroundColor3 = sp == "1.0" and C.cyan or C.card2,
      Text = sp .. "x",
      TextColor3 = sp == "1.0" and C.bg or C.white,
      Font = Enum.Font.GothamBold,
      TextSize = 9,
      AutoButtonColor = false,
      ZIndex = 15,
    }, speedRow)
    round(b, 6)
    speedButtons[sp] = b
    b.MouseButton1Click:Connect(function()
      speedTerpilih = sp
      for sKey, sBtn in pairs(speedButtons) do
        local on = sKey == sp
        sBtn.BackgroundColor3 = on and C.cyan or C.card2
        sBtn.TextColor3 = on and C.bg or C.white
      end
      updateRecLabel()
    end)
  end

  local btnSpoofId = tombolAksi(c1, 6, "⚡ SPOOF ID SEKARANG", C.purple)
  local outSpoofId, _ = buatKotakKode(c1, 7, "Hasil ID spoof akan muncul di sini (Read-only)...", false)

  local copyIdBtn = tombolAksi(c1, 8, "📋 Salin Semua ID Baru", C.card2)
  copyIdBtn.MouseButton1Click:Connect(function()
    local t = trim(outSpoofId.Text)
    if t ~= "" then
      copy(t)
      copyIdBtn.Text = "✔ ID Berhasil Disalin!"
      task.delay(1.5, function() copyIdBtn.Text = "📋 Salin Semua ID Baru" end)
    end
  end)

  btnSpoofId.MouseButton1Click:Connect(function()
    local txt = trim(inputIds.Text)
    if txt == "" then
      setStatus("Masukkan minimal satu ID aset!", C.danger)
      return
    end

    local ids = {}
    for id in txt:gmatch("%d%d%d%d%d%d+") do
      table.insert(ids, id)
    end
    if #ids == 0 then
      setStatus("Tidak ditemukan ID yang valid!", C.danger)
      return
    end

    btnSpoofId.Text = "⏳ Sedang Memproses (0/" .. #ids .. ")..."
    outSpoofId.Text = "Memproses " .. #ids .. " ID..."

    task.spawn(function()
      local lines = {}
      local cleanIds = {}
      for idx, aid in ipairs(ids) do
        setStatus("Spoofing ID " .. aid .. " (" .. idx .. "/" .. #ids .. ")...", C.warn)
        local newId, optTitle = spoofAssetSingleCore(aid, "Audio", speedTerpilih)
        local titleClean = optTitle or ("Asset_" .. aid)
        if newId then
          table.insert(lines, titleClean .. " | ID: " .. newId)
          table.insert(cleanIds, newId)
        else
          table.insert(lines, "❌ " .. titleClean .. " | Gagal")
        end
        btnSpoofId.Text = "⏳ Sedang Memproses (" .. idx .. "/" .. #ids .. ")..."
        task.wait(0.08)
      end

      outSpoofId.Text = table.concat(lines, "\\n")
      btnSpoofId.Text = "⚡ SPOOF ID SEKARANG"
      setStatus("Spoofing selesai!", C.ok)
      if #cleanIds > 0 then copy(table.concat(cleanIds, "\\n")) end
    end)
  end)

  -- =====================================================================
  -- CARD 2: SPOOF FULL SCRIPT (AnimModule / ModuleScript 146+ IDs)
  -- =====================================================================
  local c2 = cardBox(2)
  label(c2, {Text = "📜 Spoof Script Lengkap (AnimModule)", Font = Enum.Font.GothamBlack, TextSize = 12, LayoutOrder = 1})
  label(c2, {Text = "Otomatis ganti semua ID animasi/audio di dalam kode tanpa drop FPS.", TextColor3 = C.faint, TextSize = 10, LayoutOrder = 2})

  local inputScript, _ = buatKotakKode(c2, 3, "Tempel script Lua / AnimModule di sini...", true)
  local btnSpoofScript = tombolAksi(c2, 4, "🚀 SPOOF SEMUA ID DI SCRIPT (60 FPS)", Color3.fromRGB(58, 60, 70))
  local outScript, _ = buatKotakKode(c2, 5, "Script hasil spoof akan muncul di sini (Read-only)...", false)

  local copyScriptBtn = tombolAksi(c2, 6, "📋 Salin Script Hasil", C.card2)
  copyScriptBtn.MouseButton1Click:Connect(function()
    local t = trim(outScript.Text)
    if t ~= "" then
      copy(t)
      copyScriptBtn.Text = "✔ Script Berhasil Disalin!"
      task.delay(1.5, function() copyScriptBtn.Text = "📋 Salin Script Hasil" end)
    end
  end)

  btnSpoofScript.MouseButton1Click:Connect(function()
    local scr = inputScript.Text
    if trim(scr) == "" then
      setStatus("Tempel isi script terlebih dahulu!", C.danger)
      return
    end

    local listIds = {}
    local seen = {}
    for id in scr:gmatch("%d%d%d%d%d%d+") do
      if not seen[id] then
        seen[id] = true
        table.insert(listIds, id)
      end
    end

    if #listIds == 0 then
      setStatus("Tidak ditemukan ID dalam script!", C.danger)
      return
    end

    btnSpoofScript.Text = "⏳ Sedang Memproses (0/" .. #listIds .. ")..."
    outScript.Text = "Memproses " .. #listIds .. " ID di dalam script..."

    task.spawn(function()
      local replacements = {}
      local suksesCount = 0
      for i, aid in ipairs(listIds) do
        setStatus("Spoofing ID script: " .. aid .. " (" .. i .. "/" .. #listIds .. ")...", C.warn)
        local newId = spoofAssetSingleCore(aid, "Animation", speedTerpilih)
        if newId then
          replacements[aid] = newId
          suksesCount = suksesCount + 1
        end
        btnSpoofScript.Text = "⏳ Sedang Memproses (" .. i .. "/" .. #listIds .. ")..."
        task.wait(0.08) -- 60 FPS yielding on mobile Delta
      end

      local finalScript = scr
      for oldId, newId in pairs(replacements) do
        finalScript = finalScript:gsub(oldId, newId)
      end

      outScript.Text = finalScript
      btnSpoofScript.Text = "🚀 SPOOF SEMUA ID DI SCRIPT"
      setStatus("Script berhasil dispoof! (" .. suksesCount .. "/" .. #listIds .. " ID diperbarui)", C.ok)
      copy(finalScript)
    end)
  end)

  -- =====================================================================
  -- CARD 3: BYPASS AUDIO YOUTUBE
  -- =====================================================================
  local c3 = cardBox(3)
  label(c3, {Text = "▶ Bypass Audio YouTube", Font = Enum.Font.GothamBlack, TextSize = 12, LayoutOrder = 1})
  label(c3, {Text = "Unduh audio YouTube (320kbps) & upload ke Roblox via bot Discord / bridge.", TextColor3 = C.faint, TextSize = 10, LayoutOrder = 2})

  local inputYt, _ = buatKotakKode(c3, 3, "Masukkan Link YouTube...", true)
  local btnYtNow = tombolAksi(c3, 4, "🚀 UPLOAD & BYPASS YT SEKARANG", C.purple)
  local outYt, _ = buatKotakKode(c3, 5, "Status hasil upload YouTube...", false)

  local copyYtBtn = tombolAksi(c3, 6, "📋 Salin ID Audio YT", C.card2)
  copyYtBtn.MouseButton1Click:Connect(function()
    local t = trim(outYt.Text)
    local idM = t:match("(%d%d%d%d%d%d+)")
    if idM then
      copy(idM)
      copyYtBtn.Text = "✔ ID Disalin: " .. idM
      task.delay(1.5, function() copyYtBtn.Text = "📋 Salin ID Audio YT" end)
    end
  end)

  btnYtNow.MouseButton1Click:Connect(function()
    local u = trim(inputYt.Text)
    if u == "" then
      setStatus("Masukkan URL YouTube!", C.danger)
      return
    end

    btnYtNow.Text = "⏳ Memproses Audio YouTube..."
    setStatus("Memproses audio YouTube...", C.warn)

    task.spawn(function()
      local bridgeOk = false
      local bridgeUrls = {"http://127.0.0.1:3000/ytupload", "http://localhost:3000/ytupload"}
      for _, bUrl in ipairs(bridgeUrls) do
        local ok, r = pcall(httpReq, {
          Url = bUrl,
          Method = "POST",
          Headers = {["Content-Type"] = "application/json"},
          Body = HS:JSONEncode({url = u, speed = speedTerpilih, ocKey = cfg.key, creatorId = cfg.uid})
        })
        if ok and r and (r.StatusCode == 200 or r.Status == 200) then
          local resData = decodeJson(r)
          if resData and resData.assetId then
            outYt.Text = (resData.title or "YouTube Audio") .. " | ID: " .. tostring(resData.assetId)
            bridgeOk = true
            copy(tostring(resData.assetId))
            break
          end
        end
      end

      btnYtNow.Text = "🚀 UPLOAD & BYPASS YT SEKARANG"
      if bridgeOk then
        setStatus("Upload YouTube berhasil! ID disalin.", C.ok)
      else
        outYt.Text = "Bisa gunakan /ytupload di Discord Bot untuk hasil instan, atau nyalakan Termux bridge. URL: " .. u
        setStatus("Gunakan bot Discord /ytupload untuk instant upload!", C.sub)
      end
    end)
  end)

  -- =====================================================================
  -- CARD 4: SETELAN API OPEN CLOUD
  -- =====================================================================
  local c4 = cardBox(4)
  label(c4, {Text = "⚙ Pengaturan Akun & Open Cloud", Font = Enum.Font.GothamBlack, TextSize = 12, LayoutOrder = 1})
  label(c4, {Text = "API Key Open Cloud dan Creator ID (User/Group)", TextColor3 = C.faint, TextSize = 10, LayoutOrder = 2})

  label(c4, {Text = "API Key Open Cloud:", TextSize = 10, TextColor3 = C.cyan, LayoutOrder = 3})
  local fKey, _ = buatKotakKode(c4, 4, "Tempel API Key Open Cloud di sini...", true)
  fKey.Text = cfg.key

  label(c4, {Text = "Creator ID (User ID / Group ID):", TextSize = 10, TextColor3 = C.cyan, LayoutOrder = 5})
  local fUid, _ = buatKotakKode(c4, 6, "User ID / Group ID...", true)
  fUid.Text = cfg.uid

  local btnTipe = tombolAksi(c4, 7, "Tipe Creator: " .. cfg.tipe, C.card2)
  btnTipe.MouseButton1Click:Connect(function()
    cfg.tipe = (cfg.tipe == "User") and "Group" or "User"
    btnTipe.Text = "Tipe Creator: " .. cfg.tipe
  end)

  local btnSaveCfg = tombolAksi(c4, 8, "💾 SIMPAN SETELAN", C.purple)
  btnSaveCfg.MouseButton1Click:Connect(function()
    cfg.key = trim(fKey.Text)
    cfg.uid = trim(fUid.Text)
    cfg.saved = true

    if type(writefile) == "function" and type(makefolder) == "function" then
      pcall(function()
        if not (type(isfolder) == "function" and isfolder(FOLDER)) then makefolder(FOLDER) end
        writefile(CFG_FILE, HS:JSONEncode(cfg))
      end)
    end

    btnSaveCfg.Text = "✔ Tersimpan!"
    setStatus("Setelan tersimpan!", C.ok)
    task.delay(1.5, function() btnSaveCfg.Text = "💾 SIMPAN SETELAN" end)
  end)

  return page
end

local function __buildUploadPage(env)
    local mk, round, stroke, gradient, label, glass, C = env.mk, env.round, env.stroke, env.gradient, env.label, env.glass, env.C
    local content, gui, setStatus, notify, httpReq = env.content, env.gui, env.setStatus, env.notify, env.httpReq
    local K = env.kind
    local HS = game:GetService("HttpService")
    local ACC = K.color
    local FOLDER = "xyurei_music"
    local CFG_FILE = FOLDER .. "/bypass_cfg.json"
    local HIST_FILE = K.folder .. "/history.json"

    local canSave = type(writefile) == "function" and type(readfile) == "function"
      and type(isfile) == "function"

    local function ensureFolder(f)
      if canSave and type(makefolder) == "function" then
        pcall(function()
          if not (type(isfolder) == "function" and isfolder(f)) then
            makefolder(f)
          end
        end)
      end
    end

    ensureFolder(FOLDER)
    ensureFolder(K.folder)

    local function trim(s)
      return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
    end

    local CFG_RELAY, CFG_SECRET = "", ""

    do
      local url, sec = XYUREI_CONFIG.RELAY_URL, XYUREI_CONFIG.RELAY_SECRET
      local okG, gu = pcall(function() return getgenv and getgenv().XYUREI_RELAY_URL end)

      if okG and type(gu) == "string" and gu ~= "" then
        url = gu
      end

      local okS, gs = pcall(function() return getgenv and getgenv().XYUREI_RELAY_SECRET end)

      if okS and type(gs) == "string" and gs ~= "" then
        sec = gs
      end

      url = (tostring(url or ""):gsub("^%s+", ""):gsub("%s+$", ""):gsub("/+$", ""))

      if url ~= "" and not url:find("ISI%-URL", 1) and url:match("^https?://") then
        CFG_RELAY = url
        CFG_SECRET = tostring(sec or "")
      end
    end

    local RELAY_LOCKED = CFG_RELAY ~= ""

    local cfg = {
      key = "",
      uid = "",
      name = "",
      saved = false,
      relay = "",
      secret = "",
    }

    local function loadCfg()
      if canSave then
        pcall(function()
          if not isfile(CFG_FILE) then
            return
          end

          local d = HS:JSONDecode(readfile(CFG_FILE))

          if type(d) == "table" and type(d.key) == "string" and tostring(d.uid or "") ~= "" then
            cfg.key = d.key
            cfg.uid = tostring(d.uid)
            cfg.name = tostring(d.name or "")
            cfg.saved = d.valid == true
            cfg.relay = tostring(d.relay or "")
            cfg.secret = tostring(d.secret or "")
          end
        end)
      end

      if RELAY_LOCKED then
        cfg.relay = CFG_RELAY
        cfg.secret = CFG_SECRET
      end
    end

    loadCfg()

    local function saveCfg()
      if not canSave then
        return false
      end

      return pcall(function()
        writefile(CFG_FILE, HS:JSONEncode({
          key = cfg.key,
          uid = cfg.uid,
          name = cfg.name,
          valid = cfg.saved,
          relay = cfg.relay,
          secret = cfg.secret,
        }))
      end)
    end

    local function addHistory(name, id)
      if not canSave then
        return
      end

      pcall(function()
        local list = {}

        if isfile(HIST_FILE) then
          local d = HS:JSONDecode(readfile(HIST_FILE))

          if type(d) == "table" then
            list = d
          end
        end

        list[#list + 1] = { name = name, id = tostring(id), time = os.time() }

        while #list > 200 do
          table.remove(list, 1)
        end

        writefile(HIST_FILE, HS:JSONEncode(list))
      end)
    end

    local function copy(text)
      local fn = setclipboard or toclipboard or syn and syn.write_clipboard
        or Clipboard and Clipboard.set

      if fn then
        return (pcall(fn, tostring(text)))
      end

      return false
    end

    local function pad(o, t, b, l, r)
      local p = Instance.new("UIPadding")
      p.PaddingTop = UDim.new(0, t)
      p.PaddingBottom = UDim.new(0, b)
      p.PaddingLeft = UDim.new(0, l)
      p.PaddingRight = UDim.new(0, r)
      p.Parent = o
    end

    local function buildMultipart(reqJson, mime, data, opts)
      opts = opts or {}

      local boundary = "xyureiform" .. tostring(math.random(100000000, 999999999)) .. "x"
        .. tostring(math.random(100000000, 999999999))

      local fname = opts.filename or "file." .. (opts.ext or "bin")

      local reqPart = "--" .. boundary
        .. "\r\nContent-Disposition: form-data; name=\"request\"\r\nContent-Type: application/json\r\n\r\n"
        .. reqJson .. "\r\n"

      local filePart = "--" .. boundary
        .. "\r\nContent-Disposition: form-data; name=\"fileContent\"; filename=\"" .. fname
        .. "\"\r\nContent-Type: " .. mime .. "\r\n\r\n" .. data .. "\r\n"

      local body = (opts.fileFirst and filePart .. reqPart or reqPart .. filePart) .. "--"
        .. boundary .. "--\r\n"

      return body, "multipart/form-data; boundary=" .. boundary
    end

    local function button(parent, text, size, pos, color, ts)
      local b = mk("TextButton", {
        Size = size,
        Position = pos,
        BackgroundColor3 = color,
        Text = text,
        TextColor3 = C.white,
        Font = Enum.Font.GothamBlack,
        TextSize = ts or 11,
        AutoButtonColor = false,
        ZIndex = 15,
      }, parent)

      round(b, 10)
      stroke(b, C.white, 1, 0.7)
      return b
    end

    local function inputBox(parent, ph, size, pos)
      local w = mk("Frame", {
        Size = size,
        Position = pos,
        BackgroundColor3 = C.card,
        BackgroundTransparency = 0.38,
        BorderSizePixel = 0,
        ZIndex = 14,
      }, parent)

      round(w, 11)
      stroke(w, C.white, 1, 0.85)
      glass(w)

      return mk("TextBox", {
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.fromOffset(10, 0),
        BackgroundTransparency = 1,
        PlaceholderText = ph,
        PlaceholderColor3 = C.faint,
        Text = "",
        TextColor3 = C.white,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 15,
      }, w)
    end

    local page = mk("Frame", {
      Name = "Page_" .. K.key,
      Size = UDim2.fromScale(1, 1),
      BackgroundTransparency = 1,
      Visible = false,
      ZIndex = 12,
    }, content)

    local viewList = mk("Frame", {
      Name = "ViewList",
      Size = UDim2.fromScale(1, 1),
      BackgroundTransparency = 1,
      ZIndex = 13,
    }, page)

    local viewEdit = mk("ScrollingFrame", {
      Name = "ViewEdit",
      Size = UDim2.fromScale(1, 1),
      BackgroundTransparency = 1,
      BorderSizePixel = 0,
      Visible = false,
      ScrollBarThickness = 3,
      ScrollBarImageColor3 = C.white,
      ScrollBarImageTransparency = 0.4,
      AutomaticCanvasSize = Enum.AutomaticSize.Y,
      CanvasSize = UDim2.new(),
      ZIndex = 13,
    }, page)

    local viewSet = mk("ScrollingFrame", {
      Name = "ViewSet",
      Size = UDim2.fromScale(1, 1),
      BackgroundTransparency = 1,
      BorderSizePixel = 0,
      Visible = false,
      ScrollBarThickness = 3,
      ScrollBarImageColor3 = C.white,
      ScrollBarImageTransparency = 0.4,
      AutomaticCanvasSize = Enum.AutomaticSize.Y,
      CanvasSize = UDim2.new(),
      ZIndex = 13,
    }, page)

    if K.maintenance then
      local cover = mk("Frame", {
        Name = "MaintenanceCover",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = C.bg,
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        Active = true,
        ZIndex = 60,
      }, page)

      round(cover, 14)
      stroke(cover, C.white, 1, 0.5)

      label(cover, {
        Size = UDim2.new(1, -24, 0, 16),
        Position = UDim2.new(0, 12, 0.5, -64),
        Text = "● STATUS",
        TextColor3 = C.faint,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 61,
      })

      label(cover, {
        Size = UDim2.new(1, -24, 0, 34),
        Position = UDim2.new(0, 12, 0.5, -44),
        Text = "MAINTENANCE",
        TextColor3 = C.white,
        TextSize = 24,
        Font = Enum.Font.GothamBlack,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 61,
      })

      label(cover, {
        Size = UDim2.new(1, -24, 0, 44),
        Position = UDim2.new(0, 12, 0.5, -6),
        TextWrapped = true,
        TextColor3 = C.sub,
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 61,
        Text = "Upload " .. K.noun .. [[
 ditutup sementara.
Sedang dalam perbaikan, coba lagi nanti.]],
      })
    end

    local currentView, prevView = "list", "list"

    local function showView(v)
      if v == "settings" and currentView ~= "settings" then
        prevView = currentView
      end

      currentView = v
      viewList.Visible = v == "list"
      viewEdit.Visible = v == "edit"
      viewSet.Visible = v == "settings"
    end

    local searchBox = inputBox(
      viewList, "Cari file " .. K.noun .. "...", UDim2.new(1, -114, 0, 38),
      UDim2.fromOffset(0, 0)
    )

    local scanBtn = button(
      viewList, "SCAN", UDim2.fromOffset(64, 38), UDim2.new(1, -108, 0, 0), C.purple
    )

    local gearBtn = button(
      viewList, "⚙", UDim2.fromOffset(38, 38), UDim2.new(1, -38, 0, 0), C.card2, 16
    )

    local apiInfo = label(viewList, {
      Size = UDim2.new(1, 0, 0, 14),
      Position = UDim2.fromOffset(2, 42),
      Text = "",
      TextSize = 10,
      TextColor3 = C.faint,
      Font = Enum.Font.GothamMedium,
      TextTruncate = Enum.TextTruncate.AtEnd,
    })

    local list = mk("ScrollingFrame", {
      Name = "FileList",
      Size = UDim2.new(1, 0, 1, -62),
      Position = UDim2.fromOffset(0, 62),
      BackgroundColor3 = C.card,
      BackgroundTransparency = 0.55,
      BorderSizePixel = 0,
      ScrollBarThickness = 4,
      ScrollBarImageColor3 = C.white,
      ScrollBarImageTransparency = 0.35,
      AutomaticCanvasSize = Enum.AutomaticSize.Y,
      CanvasSize = UDim2.new(),
      ZIndex = 13,
    }, viewList)

    round(list, 12)
    stroke(list, C.white, 1, 0.88)
    pad(list, 8, 8, 8, 8)

    mk(
      "UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, list
    )

    local EMPTY_TXT = K.emptyText

    local emptyLbl = label(list, {
      Size = UDim2.new(1, -16, 0, 120),
      Text = EMPTY_TXT,
      TextColor3 = C.faint,
      TextWrapped = true,
      TextXAlignment = Enum.TextXAlignment.Center,
      ZIndex = 14,
    })

    local function refreshApiInfo()
      if cfg.saved then
        apiInfo.Text = "UPLOAD: SIAP · " .. (cfg.name ~= "" and cfg.name or "User")
          .. " · ID " .. cfg.uid .. (cfg.relay ~= "" and " · VIA WEBSITE" or " · LANGSUNG")

        apiInfo.TextColor3 = C.ok
      else
        apiInfo.Text = "UPLOAD: BELUM DIATUR · tekan ⚙ untuk isi API Key & User ID"
        apiInfo.TextColor3 = C.warn
      end
    end

    refreshApiInfo()

    local selected = nil
    local lastId = nil

    local backEdit = button(
      viewEdit, "‹", UDim2.fromOffset(34, 34), UDim2.fromOffset(0, 0), C.card2, 20
    )

    local fileTitle = label(viewEdit, {
      Size = UDim2.new(1, -44, 0, 18),
      Position = UDim2.fromOffset(42, 2),
      Text = "-",
      TextSize = 13,
      Font = Enum.Font.GothamBlack,
      TextTruncate = Enum.TextTruncate.AtEnd,
    })

    local fileSub = label(viewEdit, {
      Size = UDim2.new(1, -44, 0, 12),
      Position = UDim2.fromOffset(42, 21),
      Text = "",
      TextSize = 9,
      TextColor3 = ACC,
      TextTruncate = Enum.TextTruncate.AtEnd,
    })

    local previewBox = mk("Frame", {
      Size = UDim2.new(1, -4, 0, 150),
      Position = UDim2.fromOffset(0, 44),
      BackgroundColor3 = C.card,
      BackgroundTransparency = 0.45,
      BorderSizePixel = 0,
      ClipsDescendants = true,
      ZIndex = 14,
    }, viewEdit)

    round(previewBox, 12)
    stroke(previewBox, C.white, 1, 0.85)

    local previewImg = mk("ImageLabel", {
      Size = UDim2.new(1, -12, 1, -12),
      Position = UDim2.fromOffset(6, 6),
      BackgroundTransparency = 1,
      Image = "",
      ScaleType = Enum.ScaleType.Fit,
      ZIndex = 15,
    }, previewBox)

    local previewHint = label(previewBox, {
      Size = UDim2.new(1, -20, 1, 0),
      Position = UDim2.fromOffset(10, 0),
      Text = "",
      TextColor3 = C.faint,
      TextWrapped = true,
      TextXAlignment = Enum.TextXAlignment.Center,
      TextSize = 10,
      ZIndex = 16,
    })

    label(viewEdit, {
      Size = UDim2.new(1, 0, 0, 14),
      Position = UDim2.fromOffset(2, 204),
      Text = "NAMA ASSET DI ROBLOX",
      TextColor3 = C.faint,
      TextSize = 10,
    })

    local nameBox = inputBox(
      viewEdit, "Nama asset (boleh diganti)", UDim2.new(1, -4, 0, 38), UDim2.fromOffset(0, 220)
    )

    local uploadBtn = button(
      viewEdit, "UPLOAD TO ROBLOX", UDim2.new(1, -4, 0, 42), UDim2.fromOffset(0, 270), C.purple,
      13
    )

    gradient(uploadBtn, {
      ColorSequenceKeypoint.new(0, Color3.fromRGB(104, 106, 118)),
      ColorSequenceKeypoint.new(1, Color3.fromRGB(38, 39, 46)),
    }, 0)

    local resMsg = label(viewEdit, {
      Size = UDim2.new(1, -4, 0, 90),
      Position = UDim2.fromOffset(2, 318),
      TextWrapped = true,
      TextColor3 = C.sub,
      Font = Enum.Font.GothamMedium,
      TextSize = 10,
      TextYAlignment = Enum.TextYAlignment.Top,
      Text = "",
    })

    local copyIdBtn = button(
      viewEdit, "SALIN ID", UDim2.new(0.4, -4, 0, 34), UDim2.fromOffset(0, 412), C.card2, 10
    )

    local copySetBtn = button(
      viewEdit, "SALIN KODE", UDim2.new(0.6, -4, 0, 34), UDim2.new(0.4, 4, 0, 412), C.card2, 10
    )

    copyIdBtn.Visible = false
    copySetBtn.Visible = false

    local function setMsg(text, color)
      resMsg.Text = tostring(text)
      resMsg.TextColor3 = color or C.sub
    end

    local function tryPreview(file)
      previewImg.Image = ""
      previewHint.Visible = true

      if not K.canPreview then
        previewHint.Text = K.previewHint
        return
      end

      local fn = getcustomasset or getsynasset

      if not fn then
        previewHint.Text = "Preview tidak didukung executor ini"
        return
      end

      if file.ext ~= "png" and file.ext ~= "jpg" and file.ext ~= "jpeg" then
        previewHint.Text = "Preview hanya untuk png / jpg"
        return
      end

      local ok, asset = pcall(fn, file.path)

      if ok and asset then
        previewImg.Image = asset
        previewHint.Visible = false
      else
        previewHint.Text = "Preview gagal dimuat (file tetap bisa diupload)"
      end
    end

    local backSet = button(
      viewSet, "‹", UDim2.fromOffset(34, 34), UDim2.fromOffset(0, 0), C.card2, 20
    )

    label(viewSet, {
      Size = UDim2.new(1, -44, 0, 18),
      Position = UDim2.fromOffset(42, 2),
      Text = "Pengaturan Upload",
      TextSize = 13,
      Font = Enum.Font.GothamBlack,
    })

    label(viewSet, {
      Size = UDim2.new(1, -44, 0, 12),
      Position = UDim2.fromOffset(42, 21),
      Text = "ROBLOX OPEN CLOUD · dipakai bersama Bypass Music",
      TextSize = 9,
      TextColor3 = ACC,
    })

    label(viewSet, {
      Size = UDim2.new(1, 0, 0, 14),
      Position = UDim2.fromOffset(2, 46),
      Text = "API KEY",
      TextColor3 = C.faint,
      TextSize = 10,
    })

    local keyBox = inputBox(
      viewSet, "Tempel API Key (Open Cloud)", UDim2.new(1, -4, 0, 38), UDim2.fromOffset(0, 62)
    )

    label(viewSet, {
      Size = UDim2.new(1, 0, 0, 14),
      Position = UDim2.fromOffset(2, 108),
      Text = "USER ID",
      TextColor3 = C.faint,
      TextSize = 10,
    })

    local uidBox = inputBox(
      viewSet, "User ID Roblox pemilik asset", UDim2.new(1, -4, 0, 38), UDim2.fromOffset(0, 124)
    )

    local relayBox = inputBox(viewSet, "", UDim2.new(1, -4, 0, 38), UDim2.fromOffset(0, 186))
    relayBox.Parent.Visible = false

    if RELAY_LOCKED then
      relayBox.Text = CFG_RELAY
      relayBox.TextEditable = false
      relayBox.ClearTextOnFocus = false
    end

    local valBtn = button(
      viewSet, "VALIDASI", UDim2.new(0.5, -4, 0, 38), UDim2.fromOffset(0, 172), C.purple
    )

    local saveBtn = button(
      viewSet, "SIMPAN", UDim2.new(0.5, -4, 0, 38), UDim2.new(0.5, 4, 0, 172), C.card2
    )

    local setMsgLbl = label(viewSet, {
      Size = UDim2.new(1, -4, 0, 44),
      Position = UDim2.fromOffset(2, 218),
      TextWrapped = true,
      TextColor3 = C.sub,
      Font = Enum.Font.GothamMedium,
      TextSize = 10,
      TextYAlignment = Enum.TextYAlignment.Top,
      Text = "",
    })

    label(viewSet, {
      Size = UDim2.new(1, -4, 0, 96),
      Position = UDim2.fromOffset(2, 266),
      TextWrapped = true,
      TextColor3 = C.faint,
      Font = Enum.Font.GothamMedium,
      TextSize = 9,
      TextYAlignment = Enum.TextYAlignment.Top,
      Text = "Cara: create.roblox.com > Credentials > buat API Key, tambahkan sistem 'Assets' dengan izin Read + Write. Kalau key dibatasi IP, kosongkan batas IP supaya bisa dipakai dari HP/PC ini. User ID = ID akun pemilik asset. Key disimpan di file workspace dan dipakai bersama Bypass Music.",
    })

    local validated = false
    local validatedKey, validatedUid, validatedName, validatedRelay = nil, nil, "", ""

    local function normRelay(s)
      return (trim(s):gsub("/+$", ""))
    end

    local function setSetMsg(text, color)
      setMsgLbl.Text = tostring(text)
      setMsgLbl.TextColor3 = color or C.sub
    end

    local function refreshSaveBtn()
      saveBtn.BackgroundColor3 = validated and C.ok or C.card2
      saveBtn.TextColor3 = validated and C.bg or C.faint
    end

    local function onEdited()
      local k, u, r = trim(keyBox.Text), trim(uidBox.Text), normRelay(relayBox.Text)

      if validated and (k ~= validatedKey or u ~= validatedUid or r ~= validatedRelay) then
        validated = false
        setSetMsg("Data berubah — tekan VALIDASI lagi.", C.warn)
        refreshSaveBtn()
      end
    end

    keyBox:GetPropertyChangedSignal("Text"):Connect(onEdited)
    uidBox:GetPropertyChangedSignal("Text"):Connect(onEdited)
    relayBox:GetPropertyChangedSignal("Text"):Connect(onEdited)

    local function loadSettingsView()
      loadCfg()
      refreshApiInfo()
      keyBox.Text = cfg.key
      uidBox.Text = cfg.uid
      relayBox.Text = cfg.relay
      validated = cfg.saved
      validatedKey, validatedUid, validatedName, validatedRelay = cfg.key, cfg.uid, cfg.name, cfg.relay
      refreshSaveBtn()

      if cfg.saved then
        setSetMsg("Tersimpan & valid (" .. (cfg.name ~= "" and cfg.name or "User")
          .. "). Siap upload.", C.ok)
      else
        setSetMsg("Isi API Key + User ID, tekan VALIDASI, lalu SIMPAN.", C.sub)
      end
    end

    local validating = false

    valBtn.Activated:Connect(function()
      if validating then
        return
      end

      local key, uidText, relayUrl = trim(keyBox.Text), trim(uidBox.Text), normRelay(relayBox.Text)
      local uid = uidText:match("^%d+$")

      if key == "" then
        setSetMsg("API Key masih kosong.", C.danger)
        return
      end

      if not uid then
        setSetMsg("User ID harus angka.", C.danger)
        return
      end

      if relayUrl ~= "" and not relayUrl:match("^https?://") then
        setSetMsg("URL relay harus diawali http:// atau https://", C.danger)
        return
      end

      if not httpReq then
        setSetMsg("Executor tidak punya fungsi request().", C.danger)
        return
      end

      validating = true
      valBtn.Text = "..."
      validated = false
      refreshSaveBtn()
      setSetMsg("Memeriksa User ID & API Key...", C.warn)

      task.spawn(function()
        local function finish(text, color, ok)
          validating = false
          valBtn.Text = "VALIDASI"
          setSetMsg(text, color)
          validated = ok == true

          if ok then
            validatedKey, validatedUid, validatedRelay = key, uidText, relayUrl
          end

          refreshSaveBtn()
        end

        if relayUrl ~= "" then
          setSetMsg(
            "Menghubungi website relay (server gratis bisa butuh ~30 detik untuk bangun)...",
            C.warn
          )

          local okR, resR = pcall(httpReq, {
            Url = relayUrl .. "/ping",
            Method = "GET",
            Headers = cfg.secret ~= "" and { ["x-relay-secret"] = cfg.secret } or nil,
          })

          local relayOk = false

          if okR and type(resR) == "table" and tonumber(resR.StatusCode) == 200 then
            local okJ, dR = pcall(function() return HS:JSONDecode(resR.Body or "") end)
            relayOk = okJ and type(dR) == "table" and dR.ok == true
          end

          if not relayOk then
            return finish("Relay tidak menjawab di " .. relayUrl
              .. " (cek URL / server belum jalan). Kosongkan kolom relay untuk upload langsung.", C.danger, false)
          end
        end

        local okU, resU = pcall(httpReq, {
          Url = "https://users.roblox.com/v1/users/" .. uid,
          Method = "GET",
        })

        local uname = ""

        if okU and type(resU) == "table" then
          local code = tonumber(resU.StatusCode)

          if code == 200 then
            local okJ, d = pcall(function() return HS:JSONDecode(resU.Body) end)

            if okJ and type(d) == "table" then
              uname = tostring(d.name or d.displayName or "")
            end
          elseif code == 404 or code == 400 then
            return finish("User ID " .. uid .. " tidak ditemukan.", C.danger, false)
          else
            return finish("Gagal cek User ID (HTTP " .. tostring(code) .. ").", C.danger, false)
          end
        else
          return finish("Gagal cek User ID: " .. tostring(resU), C.danger, false)
        end

        local okK, resK = pcall(httpReq, {
          Url = "https://apis.roblox.com/assets/v1/operations/xyurei-validate-probe",
          Method = "GET",
          Headers = { ["x-api-key"] = key },
        })

        if not okK or type(resK) ~= "table" then
          return finish("Gagal cek API Key: " .. tostring(resK), C.danger, false)
        end

        local code = tonumber(resK.StatusCode)

        if code == 401 then
          return finish("API Key tidak valid (401). Cek lagi key-nya.", C.danger, false)
        elseif code == 403 then
          return finish(
            "Key dikenali tapi ditolak (403): pastikan ada izin Assets Read+Write dan batas IP kosong.",
            C.danger, false
          )
        elseif code == 429 then
          return finish("Kena rate limit (429), coba lagi sebentar.", C.warn, false)
        elseif code == 404 or code == 400 or code == 200 then
          validatedName = uname

          return finish(
            "VALID ✓ User: " .. (uname ~= "" and uname or uid) .. ". Tekan SIMPAN.", C.ok,
            true
          )
        end

        finish("Respons tak terduga (HTTP " .. tostring(code) .. ").", C.danger, false)
      end)
    end)

    saveBtn.Activated:Connect(function()
      if not validated then
        setSetMsg("Validasi dulu sebelum menyimpan.", C.warn)
        return
      end

      cfg.key, cfg.uid, cfg.name, cfg.saved = validatedKey, validatedUid, validatedName or "", true
      cfg.relay = RELAY_LOCKED and CFG_RELAY or validatedRelay or ""

      if RELAY_LOCKED then
        cfg.secret = CFG_SECRET
      end

      local ok = saveCfg()
      refreshApiInfo()

      setSetMsg(ok and "Tersimpan ✓ Sekarang bisa UPLOAD TO ROBLOX."
        or "Dipakai untuk sesi ini (executor tidak bisa menyimpan file).", C.ok)

      setStatus("API UPLOAD TERSIMPAN", C.ok)
    end)

    gearBtn.Activated:Connect(function()
      loadSettingsView()
      showView("settings")
    end)

    backSet.Activated:Connect(function()
      showView(prevView == "edit" and selected and "edit" or "list")
    end)

    local uploading = false

    uploadBtn.Activated:Connect(function()
      if K.maintenance then
        setMsg("Upload " .. K.noun .. " sedang MAINTENANCE.", C.warn)
        return
      end

      if uploading or not selected then
        return
      end

      copyIdBtn.Visible = false
      copySetBtn.Visible = false
      loadCfg()
      refreshApiInfo()

      if not cfg.saved then
        setMsg("API Key / User ID belum diatur. Buka ⚙ → VALIDASI → SIMPAN dulu.", C.warn)
        loadSettingsView()
        showView("settings")
        return
      end

      if not httpReq then
        setMsg("Executor tidak punya fungsi request().", C.danger)
        return
      end

      uploading = true
      uploadBtn.Text = "MEMBACA FILE..."
      local file = selected
      local typedName = trim(nameBox.Text)

      task.spawn(function()
        local function done(text, color)
          uploading = false
          uploadBtn.Text = "UPLOAD TO ROBLOX"
          setMsg(text, color)
        end

        local okR, data = pcall(readfile, file.path)

        if not okR or type(data) ~= "string" or #data == 0 then
          return done("Gagal membaca file: " .. tostring(data), C.danger)
        end

        if #data > 20 * 1024 * 1024 then
          return done("File > 20 MB, melebihi batas upload Roblox.", C.danger)
        end

        uploadBtn.Text = "UPLOADING..."
        setMsg("Mengirim ke Roblox (" .. math.floor(#data / 1024) .. " KB)...", C.warn)
        setStatus("UPLOADING " .. file.name, C.warn)
        local displayName = typedName

        if displayName == "" then
          displayName = file.name:gsub("%.[^%.]+$", "")
        end

        displayName = displayName:sub(1, 50)

        if displayName == "" then
          displayName = K.defaultName
        end

        local mime = K.mime[file.ext] or "application/octet-stream"

        local reqJson = HS:JSONEncode({
          assetType = K.assetType,
          displayName = displayName,
          description = "Uploaded via Tools Engine",
          creationContext = { creator = { userId = tostring(cfg.uid) } },
        })

        local assetId, errText
        local relayWhy

        local function viaRelay()
          local base = cfg.relay:gsub("/+$", "")
          local CH = 1024 * 1024
          local total = math.ceil(#data / CH)
          local jobId = ("x%d%d"):format(os.time(), math.random(100000, 999999))

          local function relayHeaders(extra)
            local h = extra or {}

            if cfg.secret ~= "" then
              h["x-relay-secret"] = cfg.secret
            end

            return h
          end

          for i = 1, total do
            local piece = data:sub((i - 1) * CH + 1, i * CH)
            uploadBtn.Text = ("KIRIM KE WEBSITE %d/%d"):format(i, total)
            local sent, lastErr = false, "?"

            for attempt = 1, 3 do
              local okC, rC = pcall(httpReq, {
                Url = base .. "/chunk",
                Method = "POST",
                Headers = relayHeaders({
                  ["Content-Type"] = "application/octet-stream",
                  ["x-upload-id"] = jobId,
                  ["x-chunk-index"] = tostring(i),
                  ["x-chunk-total"] = tostring(total),
                }),
                Body = piece,
              })

              if okC and type(rC) == "table" and tonumber(rC.StatusCode) == 200 then
                sent = true
                break
              end

              lastErr = okC
                  and type(rC) == "table"
                  and "HTTP " .. tostring(rC.StatusCode) .. " "
                    .. tostring(rC.Body or ""):sub(1, 120)
                or tostring(rC)

              task.wait(1.5)
            end

            if not sent then
              return ("gagal kirim bagian %d/%d: %s"):format(i, total, lastErr)
            end

            task.wait()
          end

          uploadBtn.Text = "WEBSITE UPLOAD KE ROBLOX..."

          local okF, rF = pcall(httpReq, {
            Url = base .. "/finish",
            Method = "POST",
            Headers = relayHeaders({ ["Content-Type"] = "application/json" }),
            Body = HS:JSONEncode({
              id = jobId,
              key = cfg.key,
              uid = tostring(cfg.uid),
              displayName = displayName,
              ext = file.ext,
              total = total,
              size = #data,
              assetType = K.assetType,
              mime = mime,
            }),
          })

          if not okF or type(rF) ~= "table" then
            return "tidak bisa menghubungi website: " .. tostring(rF)
          end

          if tonumber(rF.StatusCode) ~= 200 then
            local okE, dE = pcall(function() return HS:JSONDecode(rF.Body or "") end)

            return "website menolak: "
              .. tostring(okE and type(dE) == "table" and dE.error
                or "HTTP " .. tostring(rF.StatusCode))
          end

          for attempt = 1, 70 do
            task.wait(2)
            uploadBtn.Text = ("MENUNGGU ROBLOX %d"):format(attempt)

            local okJ2, rJ = pcall(httpReq, {
              Url = base .. "/job?id=" .. jobId,
              Method = "GET",
              Headers = relayHeaders(),
            })

            if okJ2 and type(rJ) == "table" and tonumber(rJ.StatusCode) == 200 then
              local okD, job = pcall(function() return HS:JSONDecode(rJ.Body or "") end)

              if okD and type(job) == "table" then
                if job.status == "done" and job.assetId then
                  assetId = tostring(job.assetId)
                  break
                end

                if job.status == "error" then
                  errText = tostring(job.message or "upload gagal")
                  break
                end
              end
            end
          end

          if errText then
            local e = errText
            errText = nil
            return e
          end

          return nil
        end

        if cfg.relay ~= "" then
          local okV, r = pcall(viaRelay)

          if not okV then
            relayWhy = tostring(r)
          elseif r then
            relayWhy = tostring(r)
          end

          if relayWhy then
            setMsg("Website relay gagal (" .. relayWhy:sub(1, 120)
              .. "). Mencoba upload langsung ke Roblox...", C.warn)

            task.wait(0.5)
          end
        end

        if cfg.relay == "" or relayWhy then
          local safeName = displayName:gsub("[^%w_%-]", "_")

          local variants = {
            { name = "standar", mime = mime, opts = { ext = file.ext } },
            {
              name = "octet-stream",
              mime = "application/octet-stream",
              opts = { filename = safeName .. "." .. file.ext },
            },
            { name = "file-duluan", mime = mime, opts = { fileFirst = true, ext = file.ext } },
          }

          if mime ~= "model/x-rbxm" and (file.ext == "rbxmx" or file.ext == "rbxm") then
            table.insert(variants, 2, {
              name = "mime rbxm",
              mime = "model/x-rbxm",
              opts = { ext = file.ext },
            })
          end

          local body, ctype, ok, res, code, okJ, d

          for vi, v in ipairs(variants) do
            body, ctype = buildMultipart(reqJson, v.mime, data, v.opts)

            if vi > 1 then
              uploadBtn.Text = ("UPLOADING (%d/%d)"):format(vi, #variants)

              setMsg(("Format %s ditolak, coba varian '%s'..."):format(
                variants[vi - 1].name, v.name
              ), C.warn)
            end

            ok, res = pcall(httpReq, {
              Url = "https://apis.roblox.com/assets/v1/assets",
              Method = "POST",
              Headers = { ["x-api-key"] = cfg.key, ["Content-Type"] = ctype },
              Body = body,
            })

            if not ok or type(res) ~= "table" then
              return done("Request gagal: " .. tostring(res), C.danger)
            end

            code = tonumber(res.StatusCode)
            okJ, d = pcall(function() return HS:JSONDecode(res.Body or "") end)
            local rawBody = tostring(res.Body or "")
            local rl = rawBody:lower()

            if not (code == 400
              and (rl:find("filecontent", 1, true) or rl:find("not supported", 1, true)
                or rl:find("content type", 1, true))) then
              break
            end
          end

          if code == 400 and tostring(res.Body or ""):find("FileContent", 1, true) then
            return done(
              "Gagal (HTTP 400): file biner tidak terbaca Roblox. Executor kemungkinan merusak data biner — pakai website relay (XYUREI_CONFIG.RELAY_URL) atau cek TES BINARY EXECUTOR di Bypass Music.",
              C.danger
            )
          end

          if code == 401 then
            return done("API Key ditolak (401). Cek di ⚙ lalu validasi ulang.", C.danger)
          end

          if code == 403 then
            return done(
              "Ditolak (403): izin Assets Read+Write kurang / batas IP / user bukan pemilik key.",
              C.danger
            )
          end

          if code == 429 then
            return done(
              "Kena limit upload (429). Batas bulanan / rate limit tercapai.", C.danger
            )
          end

          if not okJ or type(d) ~= "table" then
            return done("Respons tak terduga (HTTP " .. tostring(code) .. ").", C.danger)
          end

          if code and code >= 400 then
            local detail = d.message or d.code

            if not detail then
              detail = tostring(res.Body or ""):sub(1, 300)
            end

            return done(("Gagal (HTTP %s): %s\n[uid %s · %d KB · %s]"):format(tostring(code), tostring(detail), tostring(cfg.uid), math.floor(#data
              / 1024), file.ext), C.danger)
          end

          local opPath = d.path

          if type(opPath) ~= "string" then
            return done("Roblox tidak memberi operation ID.", C.danger)
          end

          for attempt = 1, 40 do
            task.wait(1.5)
            uploadBtn.Text = ("MENUNGGU ROBLOX %d"):format(attempt)

            local okP, rp = pcall(httpReq, {
              Url = "https://apis.roblox.com/assets/v1/" .. opPath,
              Method = "GET",
              Headers = { ["x-api-key"] = cfg.key },
            })

            if okP and type(rp) == "table" then
              local okD, op = pcall(function() return HS:JSONDecode(rp.Body or "") end)

              if okD and type(op) == "table" and op.done == true then
                if type(op.response) == "table" and op.response.assetId then
                  assetId = tostring(op.response.assetId)
                elseif type(op.error) == "table" then
                  errText = tostring(op.error.message or op.error.code or "upload ditolak")
                else
                  errText = "operasi selesai tanpa asset ID"
                end

                break
              end
            end
          end
        end

        if errText then
          return done("Upload gagal: " .. errText, C.danger)
        end

        if not assetId then
          return done("Timeout menunggu Roblox. Cek di Creator Hub > Creations > " .. K.assetType
            .. ".", C.warn)
        end

        lastId = assetId
        addHistory(displayName, assetId)
        copyIdBtn.Visible = true
        copySetBtn.Visible = true

        done("BERHASIL ✓ ID: " .. assetId .. " (rbxassetid://" .. assetId .. [[
)
]] .. K.afterNote, C.ok)

        setStatus("UPLOAD SELESAI • ID " .. assetId, C.ok)
        notify(K.title, file.name .. " terupload. ID " .. assetId, true)
      end)
    end)

    copyIdBtn.Activated:Connect(function()
      if not lastId then
        return
      end

      copyIdBtn.Text = copy(lastId) and "TERSALIN ✓" or "ID " .. lastId
      task.delay(1.5, function() copyIdBtn.Text = "SALIN ID" end)
    end)

    copySetBtn.Activated:Connect(function()
      if not lastId then
        return
      end

      copySetBtn.Text = copy(K.snippet(lastId)) and "TERSALIN ✓" or "CLIPBOARD ✕"
      task.delay(1.5, function() copySetBtn.Text = "SALIN KODE" end)
    end)

    local function openEditor(file)
      selected = file
      fileTitle.Text = file.name
      fileSub.Text = file.ext:upper() .. " · " .. file.path
      nameBox.Text = (file.name:gsub("%.[^%.]+$", ""))
      lastId = nil
      copyIdBtn.Visible = false
      copySetBtn.Visible = false
      tryPreview(file)

      setMsg(cfg.saved and "Cek nama lalu tekan UPLOAD TO ROBLOX."
        or "Upload butuh API Key & User ID — atur dulu lewat ⚙ di daftar file.", cfg.saved and C.sub or C.warn)

      viewEdit.CanvasPosition = Vector2.new(0, 0)
      showView("edit")
    end

    backEdit.Activated:Connect(function() showView("list") end)
    local cards = {}

    local function fileExt(name)
      local e = name:lower():match("%.(%w+)$")

      if e and K.mime[e] then
        return e
      end

      return nil
    end

    local function scanDeep(folder, depth, results, seenF, seenFiles)
      if depth > 4 then
        return
      end

      local fk = canonicalWorkspacePath(folder)

      if fk == "" then
        fk = "__root__"
      end

      if seenF[fk] then
        return
      end

      seenF[fk] = true
      local items = safeListFiles(folder)

      if not items then
        return
      end

      for _, path in ipairs(items) do
        local name = getFileName(path)
        local ext = fileExt(name)

        if ext then
          local key = canonicalWorkspacePath(path)

          if key == "" then
            key = name:lower()
          end

          if not seenFiles[key] then
            seenFiles[key] = true
            results[#results + 1] = { name = name, path = path, ext = ext }
          end
        elseif looksFolder(path) then
          scanDeep(path, depth + 1, results, seenF, seenFiles)
        end
      end
    end

    local function applyFilter()
      local q = trim(searchBox.Text):lower()
      local shown = 0

      for _, c in ipairs(cards) do
        local m = q == "" or c.file.name:lower():find(q, 1, true) ~= nil
        c.card.Visible = m

        if m then
          shown = shown + 1
        end
      end

      emptyLbl.Visible = shown == 0

      if #cards > 0 and shown == 0 then
        emptyLbl.Text = "TIDAK ADA YANG COCOK"
      else
        emptyLbl.Text = EMPTY_TXT
      end
    end

    local function makeCard(file, order)
      local card = mk("TextButton", {
        Size = UDim2.new(1, -4, 0, 48),
        BackgroundColor3 = C.card2,
        BackgroundTransparency = 0.42,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = order,
        ZIndex = 14,
      }, list)

      round(card, 13)
      stroke(card, C.white, 1, 0.85)
      glass(card)

      local bar = mk("Frame", {
        Size = UDim2.new(0, 3, 0.6, 0),
        Position = UDim2.new(0, 0, 0.2, 0),
        BackgroundColor3 = ACC,
        BorderSizePixel = 0,
        ZIndex = 15,
      }, card)

      round(bar, 2)

      local badge = label(card, {
        Size = UDim2.fromOffset(40, 16),
        Position = UDim2.fromOffset(12, 8),
        BackgroundTransparency = 0.1,
        BackgroundColor3 = C.bg,
        Text = file.ext:upper(),
        TextColor3 = ACC,
        Font = Enum.Font.GothamBlack,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Center,
      })

      round(badge, 5)
      stroke(badge, ACC, 1, 0.6)

      label(card, {
        Size = UDim2.new(1, -112, 0, 14),
        Position = UDim2.fromOffset(60, 8),
        Text = file.name,
        TextSize = 11,
        TextTruncate = Enum.TextTruncate.AtEnd,
      })

      label(card, {
        Size = UDim2.new(1, -112, 0, 12),
        Position = UDim2.fromOffset(60, 26),
        Text = file.path,
        TextColor3 = C.faint,
        Font = Enum.Font.Code,
        TextSize = 9,
        TextTruncate = Enum.TextTruncate.AtEnd,
      })

      label(card, {
        Size = UDim2.fromOffset(30, 48),
        Position = UDim2.new(1, -38, 0, 0),
        Text = "›",
        TextColor3 = C.sub,
        TextSize = 22,
        Font = Enum.Font.GothamBlack,
        TextXAlignment = Enum.TextXAlignment.Center,
      })

      card.Activated:Connect(function() openEditor(file) end)
      cards[#cards + 1] = { card = card, file = file }
    end

    local scanning = false

    local function scanFiles()
      if scanning then
        return
      end

      if type(listfiles) ~= "function" then
        emptyLbl.Text = "LISTFILES TIDAK TERSEDIA DI EXECUTOR"
        emptyLbl.Visible = true
        return
      end

      scanning = true
      scanBtn.Text = "..."

      for _, c in ipairs(cards) do
        c.card:Destroy()
      end

      cards = {}

      emptyLbl.Text = "SCANNING..."
      emptyLbl.Visible = true

      task.spawn(function()
        local results, seenF, seenFiles = {}, {}, {}

        for _, p in ipairs(SCAN_PATHS) do
          if safeListFiles(p) then
            scanDeep(p, 0, results, seenF, seenFiles)
          end
        end

        table.sort(results, function(a, b) return a.name:lower() < b.name:lower() end)

        for i, f in ipairs(results) do
          makeCard(f, i)

          if i % 15 == 0 then
            task.wait()
          end
        end

        scanning = false
        scanBtn.Text = "SCAN"
        applyFilter()
        setStatus((K.title .. " • %d FILE"):format(#results), #results > 0 and C.ok or C.warn)
      end)
    end

    scanBtn.Activated:Connect(scanFiles)
    searchBox:GetPropertyChangedSignal("Text"):Connect(applyFilter)
    task.defer(scanFiles)
    return page
  end

  local __UPLOAD_KINDS = {
    IMAGE = {
      key = "IMAGE",
      title = "UPLOAD IMAGE",
      noun = "gambar",
      folder = "xyurei_image",
      color = Color3.fromRGB(220, 222, 230),
      assetType = "Decal",
      defaultName = "Engine Image",
      canPreview = true,
      previewHint = "",
      mime = {
        png = "image/png",
        jpg = "image/jpeg",
        jpeg = "image/jpeg",
        bmp = "image/bmp",
        tga = "image/tga",
      },
      emptyText = [[
BELUM ADA FILE GAMBAR

Tempel file .png / .jpg / .bmp / .tga
ke folder workspace Delta,
lalu tekan SCAN]],
      afterNote = "Gambar bisa butuh moderasi sebentar. ID ini adalah Decal ID (pakai di Decal.Texture / ImageLabel.Image).",
      snippet = function(id)
        return [[
local img = Instance.new("ImageLabel")
img.Image = "rbxassetid://]] .. id .. [[
"
img.Size = UDim2.fromOffset(200, 200)
img.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChildOfClass("ScreenGui")]]
      end,
    },
    MODEL = {
      key = "MODEL",
      title = "UPLOAD RBXM",
      noun = "model",
      folder = "xyurei_model",
      color = Color3.fromRGB(235, 236, 242),
      assetType = "Model",
      defaultName = "Engine Model",
      canPreview = false,
      previewHint = [[
MODEL

File .rbxm / .rbxmx (Model, bukan Place).
Preview tidak tersedia.]],
      mime = { rbxm = "model/x-rbxm", rbxmx = "model/x-rbxmx" },
      emptyText = [[
BELUM ADA FILE MODEL

Tempel file .rbxm / .rbxmx
ke folder workspace Delta,
lalu tekan SCAN]],
      afterNote = "Setelah sukses, Asset ID ini bisa dipakai lewat InsertService:LoadAsset(id) di game milik akun/grup yang mengupload.",
      snippet = function(id)
        return [[
local ok, model = pcall(function()
	return game:GetService("InsertService"):LoadAsset(]] .. id .. [[
)
end)
if ok then
	model.Parent = workspace
end]]
      end,
    },
    ANIM = {
      key = "ANIM",
      title = "UPLOAD ANIMASI",
      noun = "animasi",
      folder = "xyurei_anim",
      color = Color3.fromRGB(200, 202, 212),
      assetType = "Animation",
      defaultName = "Engine Animation",
      canPreview = false,
      maintenance = true,
      previewHint = [[
ANIMASI

File .rbxm / .rbxmx berisi KeyframeSequence
(export dari Animation Editor di Studio).
Preview tidak tersedia.]],
      mime = { rbxm = "model/x-rbxm", rbxmx = "model/x-rbxmx" },
      emptyText = [[
BELUM ADA FILE ANIMASI

Tempel file .rbxm / .rbxmx (KeyframeSequence)
ke folder workspace Delta,
lalu tekan SCAN]],
      afterNote = "Animasi hanya bisa dimainkan di game milik akun/grup yang mengupload.",
      snippet = function(id)
        return [[
local anim = Instance.new("Animation")
anim.AnimationId = "rbxassetid://]] .. id .. [[
"
local hum = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
hum:LoadAnimation(anim):Play()]]
      end,
    },
  }

  XYUREI_CONFIG.__UPLOAD = { build = __buildUploadPage, kinds = __UPLOAD_KINDS }
end

do
  local IMG3D_CORE = (function()
    local Core = {}
    local sbyte, schar, sfloor, smin, smax = string.byte, string.char, math.floor, math.min, math.max
    local unpack = table.unpack or unpack
    local POW2 = {}

    for i = 0, 52 do
      POW2[i] = 2 ^ i
    end

    function Core.newAcc(sw, sh, detail)
      detail = smax(4, detail)
      local mx = smax(sw, sh)
      local scale = detail / mx

      if scale > 1 then
        scale = 1
      end

      local tw = smax(1, sfloor(sw * scale + 0.5))
      local th = smax(1, sfloor(sh * scale + 0.5))
      local step = smax(1, sfloor(mx / (detail * 4)))

      local acc = {
        sw = sw,
        sh = sh,
        tw = tw,
        th = th,
        step = step,
      }

      local xl, xi, n = {}, {}, 0

      for x = 0, sw - 1, step do
        n = n + 1
        xl[n] = x
        xi[n] = sfloor(x * tw / sw) + 1
      end

      acc.xl, acc.xi, acc.nx = xl, xi, n
      local ym = {}

      for y = 0, sh - 1, step do
        ym[y] = sfloor(y * th / sh) * tw
      end

      acc.ym = ym
      local R, G, B, A, N = {}, {}, {}, {}, {}

      for i = 1, tw * th do
        R[i] = 0
        G[i] = 0
        B[i] = 0
        A[i] = 0
        N[i] = 0
      end

      acc.R, acc.G, acc.B, acc.A, acc.N = R, G, B, A, N
      return acc
    end

    function Core.finish(acc)
      local tw, th = acc.tw, acc.th

      local g = {
        w = tw,
        h = th,
        r = {},
        g = {},
        b = {},
        a = {},
        srcW = acc.sw,
        srcH = acc.sh,
      }

      local R, G, B, A, N = acc.R, acc.G, acc.B, acc.A, acc.N

      for i = 1, tw * th do
        local as, n = A[i], N[i]

        if n > 0 and as > 0 then
          g.r[i] = sfloor(R[i] / as + 0.5)
          g.g[i] = sfloor(G[i] / as + 0.5)
          g.b[i] = sfloor(B[i] / as + 0.5)
          g.a[i] = sfloor(as / n + 0.5)
        else
          g.r[i] = 0
          g.g[i] = 0
          g.b[i] = 0
          g.a[i] = 0
        end
      end

      return g
    end

    local LBASE = {
      3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43, 51, 59, 67, 83, 99, 115,
      131, 163, 195, 227, 258,
    }

    local LEXT = {
      0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0,
    }

    local DBASE = {
      1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385, 513, 769, 1025, 1537,
      2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577,
    }

    local DEXT = {
      0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12,
      13, 13,
    }

    local CLORDER = { 16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15 }

    local function buildHuff(lens, n)
      local count = {}

      for i = 0, 15 do
        count[i] = 0
      end

      local maxb = 0

      for s = 0, n - 1 do
        local l = lens[s] or 0
        count[l] = count[l] + 1

        if l > maxb then
          maxb = l
        end
      end

      if maxb == 0 then
        return {}, 1
      end

      count[0] = 0
      local nextcode, code = {}, 0

      for l = 1, 15 do
        code = (code + count[l - 1]) * 2
        nextcode[l] = code
      end

      local tab, size = {}, POW2[maxb]

      for s = 0, n - 1 do
        local l = lens[s] or 0

        if l > 0 then
          local c = nextcode[l]
          nextcode[l] = c + 1
          local r, cc = 0, c

          for _ = 1, l do
            r = r * 2 + cc % 2
            cc = (cc - cc % 2) / 2
          end

          local e, stp = s * 16 + l, POW2[l]

          for idx = r, size - 1, stp do
            tab[idx] = e
          end
        end
      end

      return tab, maxb
    end

    local FIXED_LIT, FIXED_LITB, FIXED_DIST, FIXED_DISTB

    do
      local ll = {}

      for i = 0, 143 do
        ll[i] = 8
      end

      for i = 144, 255 do
        ll[i] = 9
      end

      for i = 256, 279 do
        ll[i] = 7
      end

      for i = 280, 287 do
        ll[i] = 8
      end

      FIXED_LIT, FIXED_LITB = buildHuff(ll, 288)
      local dl = {}

      for i = 0, 29 do
        dl[i] = 5
      end

      FIXED_DIST, FIXED_DISTB = buildHuff(dl, 30)
    end

    function Core.inflate(data, startPos, sink, yieldFn)
      local pos, dlen = startPos or 1, #data
      local bitbuf, bitcnt = 0, 0
      local win, wi = {}, 0
      local cb, cn = {}, 0
      local outTotal, lastY = 0, 0

      local function flush()
        if cn > 0 then
          sink(schar(unpack(cb, 1, cn)))
          outTotal = outTotal + cn
          cn = 0

          if yieldFn and outTotal - lastY > 150000 then
            lastY = outTotal
            yieldFn()
          end
        end
      end

      local function fill(n)
        while bitcnt < n do
          local b = sbyte(data, pos)

          if b then
            pos = pos + 1
          else
            b = 0
            pos = pos + 1

            if pos > dlen + 16 then
              error("data PNG terpotong (inflate)")
            end
          end

          bitbuf = bitbuf + b * POW2[bitcnt]
          bitcnt = bitcnt + 8
        end
      end

      local function bits(n)
        if n == 0 then
          return 0
        end

        fill(n)
        local p = POW2[n]
        local v = bitbuf % p
        bitbuf = (bitbuf - v) / p
        bitcnt = bitcnt - n
        return v
      end

      local cmf, flg = sbyte(data, pos), sbyte(data, pos + 1)

      if not cmf or cmf % 16 ~= 8 then
        error("header zlib tidak valid")
      end

      pos = pos + 2

      if flg and flg >= 32 and math.floor(flg / 32) % 2 == 1 then
        error("zlib FDICT tidak didukung")
      end

      local final = 0

      while final == 0 do
        final = bits(1)
        local btype = bits(2)

        if btype == 0 then
          local drop = bitcnt % 8

          if drop > 0 then
            bits(drop)
          end

          pos = pos - bitcnt / 8
          bitbuf = 0
          bitcnt = 0
          local len = sbyte(data, pos) + sbyte(data, pos + 1) * 256
          pos = pos + 4
          local i = 0

          while i < len do
            local take = smin(len - i, 2000)
            local s = data:sub(pos, pos + take - 1)

            if #s < take then
              error("blok stored terpotong")
            end

            for k = 1, take do
              local b = sbyte(s, k)
              cn = cn + 1
              cb[cn] = b
              win[wi] = b
              wi = wi + 1

              if wi == 32768 then
                wi = 0
              end
            end

            flush()
            pos = pos + take
            i = i + take
          end
        elseif btype == 1 or btype == 2 then
          local litT, litB, distT, distB

          if btype == 1 then
            litT, litB, distT, distB = FIXED_LIT, FIXED_LITB, FIXED_DIST, FIXED_DISTB
          else
            local hlit, hdist, hclen = bits(5) + 257, bits(5) + 1, bits(4) + 4
            local cl = {}

            for i = 0, 18 do
              cl[i] = 0
            end

            for i = 1, hclen do
              cl[CLORDER[i]] = bits(3)
            end

            local clT, clB = buildHuff(cl, 19)
            local lens, total, i = {}, hlit + hdist, 0
            local clMod = POW2[clB]

            while i < total do
              fill(clB)
              local e = clT[bitbuf % clMod]

              if not e then
                error("tabel huffman rusak")
              end

              local l = e % 16
              local sym = (e - l) / 16
              bits(l)

              if sym < 16 then
                lens[i] = sym
                i = i + 1
              else
                local rep, val

                if sym == 16 then
                  if i == 0 then
                    error("tabel huffman rusak")
                  end

                  val = lens[i - 1]
                  rep = 3 + bits(2)
                elseif sym == 17 then
                  val = 0
                  rep = 3 + bits(3)
                else
                  val = 0
                  rep = 11 + bits(7)
                end

                for _ = 1, rep do
                  lens[i] = val
                  i = i + 1
                end
              end
            end

            local ll, dl = {}, {}

            for k = 0, hlit - 1 do
              ll[k] = lens[k]
            end

            for k = 0, hdist - 1 do
              dl[k] = lens[hlit + k]
            end

            litT, litB = buildHuff(ll, hlit)
            distT, distB = buildHuff(dl, hdist)
          end

          local litMod, distMod = POW2[litB], POW2[distB]

          while true do
            fill(litB)
            local e = litT[bitbuf % litMod]

            if not e then
              error("kode literal rusak")
            end

            local l = e % 16
            local sym = (e - l) / 16
            local p = POW2[l]
            bitbuf = (bitbuf - bitbuf % p) / p
            bitcnt = bitcnt - l

            if sym < 256 then
              cn = cn + 1
              cb[cn] = sym
              win[wi] = sym
              wi = wi + 1

              if wi == 32768 then
                wi = 0
              end

              if cn >= 2000 then
                flush()
              end
            elseif sym == 256 then
              break
            else
              local li = sym - 256
              local length = LBASE[li]

              if not length then
                error("kode panjang rusak")
              end

              local eb = LEXT[li]

              if eb > 0 then
                length = length + bits(eb)
              end

              fill(distB)
              local de = distT[bitbuf % distMod]

              if not de then
                error("kode jarak rusak")
              end

              local dl2 = de % 16
              local dsym = (de - dl2) / 16
              local p2 = POW2[dl2]
              bitbuf = (bitbuf - bitbuf % p2) / p2
              bitcnt = bitcnt - dl2
              local dist = DBASE[dsym + 1]

              if not dist then
                error("kode jarak rusak")
              end

              local deb = DEXT[dsym + 1]

              if deb > 0 then
                dist = dist + bits(deb)
              end

              local si = wi - dist

              if si < 0 then
                si = si + 32768
              end

              for _ = 1, length do
                local b = win[si]

                if not b then
                  error("referensi kompres rusak")
                end

                cn = cn + 1
                cb[cn] = b
                win[wi] = b
                wi = wi + 1

                if wi == 32768 then
                  wi = 0
                end

                si = si + 1

                if si == 32768 then
                  si = 0
                end
              end

              if cn >= 2000 then
                flush()
              end
            end
          end
        else
          error("blok deflate tidak valid")
        end
      end

      flush()
    end

    local function be32(s, p)
      local a, b, c, d = sbyte(s, p, p + 3)
      return ((a * 256 + b) * 256 + c) * 256 + d
    end

    function Core.decodePNG(data, detail, yieldFn, progress)
      if data:sub(1, 8) ~= "\137PNG\r\n\26\n" then
        error("bukan file PNG")
      end

      local pos = 9
      local w, h, bd, ct, interlace
      local plte, trns, idat = nil, nil, {}

      while pos + 8 <= #data do
        local len = be32(data, pos)
        local typ = data:sub(pos + 4, pos + 7)
        local body = data:sub(pos + 8, pos + 7 + len)

        if typ == "IHDR" then
          w, h = be32(body, 1), be32(body, 5)
          bd, ct = sbyte(body, 9), sbyte(body, 10)
          interlace = sbyte(body, 13)
        elseif typ == "PLTE" then
          plte = body
        elseif typ == "tRNS" then
          trns = body
        elseif typ == "IDAT" then
          idat[#idat + 1] = body
        elseif typ == "IEND" then
          break
        end

        pos = pos + 12 + len
      end

      if not w then
        error("PNG tidak punya IHDR")
      end

      if interlace and interlace ~= 0 then
        error("PNG interlaced (Adam7) belum didukung")
      end

      local chans = ({
        [0] = 1,
        [2] = 3,
        [3] = 1,
        [4] = 2,
        [6] = 4,
      })[ct]

      if not chans then
        error("tipe warna PNG tidak dikenal")
      end

      if ct == 3 and not plte then
        error("PNG palette tanpa PLTE")
      end

      if w * h > 64000000 then
        error("gambar terlalu besar")
      end

      local bitsPP = chans * bd
      local rowBytes = sfloor((w * bitsPP + 7) / 8)
      local bpp = smax(1, sfloor((bitsPP + 7) / 8))
      local need = rowBytes + 1
      local acc = Core.newAcc(w, h, detail)
      local xl, nx, ym = acc.xl, acc.nx, acc.ym
      local xi = acc.xi
      local R, G, B, A, N = acc.R, acc.G, acc.B, acc.A, acc.N
      local pr, pg, pb, pa = {}, {}, {}, {}

      if plte then
        for i = 0, sfloor(#plte / 3) - 1 do
          pr[i], pg[i], pb[i] = sbyte(plte, i * 3 + 1, i * 3 + 3)
          pa[i] = 255
        end

        if trns and ct == 3 then
          for i = 1, #trns do
            pa[i - 1] = sbyte(trns, i)
          end
        end
      end

      local keyR, keyG, keyB, keyY

      if trns and ct == 2 and #trns >= 6 then
        keyR, keyG, keyB = be32("\0\0" .. trns:sub(1, 2), 1), be32("\0\0" .. trns:sub(3, 4), 1), be32("\0\0" .. trns:sub(5, 6), 1)
      elseif trns and ct == 0 and #trns >= 2 then
        keyY = be32("\0\0" .. trns:sub(1, 2), 1)
      end

      local prev, cur = {}, {}

      for i = 1, rowBytes + 8 do
        prev[i] = 0
        cur[i] = 0
      end

      local y = 0
      local pending = ""
      local maxv = POW2[bd] - 1

      local function pixel(x)
        if bd == 8 then
          if ct == 6 then
            local o = x * 4
            return cur[o + 1], cur[o + 2], cur[o + 3], cur[o + 4]
          elseif ct == 2 then
            local o = x * 3
            local r, g, b = cur[o + 1], cur[o + 2], cur[o + 3]

            if keyR and r == keyR and g == keyG and b == keyB then
              return r, g, b, 0
            end

            return r, g, b, 255
          elseif ct == 0 then
            local v = cur[x + 1]

            if keyY and v == keyY then
              return v, v, v, 0
            end

            return v, v, v, 255
          elseif ct == 4 then
            local v = cur[x * 2 + 1]
            return v, v, v, cur[x * 2 + 2]
          else
            local i = cur[x + 1]
            return pr[i] or 0, pg[i] or 0, pb[i] or 0, pa[i] or 255
          end
        elseif bd == 16 then
          if ct == 6 then
            local o = x * 8
            return cur[o + 1], cur[o + 3], cur[o + 5], cur[o + 7]
          elseif ct == 2 then
            local o = x * 6
            return cur[o + 1], cur[o + 3], cur[o + 5], 255
          elseif ct == 0 then
            local v = cur[x * 2 + 1]
            return v, v, v, 255
          else
            local v = cur[x * 4 + 1]
            return v, v, v, cur[x * 4 + 3]
          end
        else
          local bitpos = x * bd
          local byte = cur[sfloor(bitpos / 8) + 1]
          local sh = 8 - bd - bitpos % 8
          local v = sfloor(byte / POW2[sh]) % (maxv + 1)

          if ct == 3 then
            return pr[v] or 0, pg[v] or 0, pb[v] or 0, pa[v] or 255
          end

          local g = sfloor(v * 255 / maxv + 0.5)
          return g, g, g, 255
        end
      end

      local function processRow(s, p)
        local f = sbyte(s, p)
        local o = p

        if f == 0 then
          for i = 1, rowBytes do
            cur[i] = sbyte(s, o + i)
          end
        elseif f == 1 then
          for i = 1, bpp do
            cur[i] = sbyte(s, o + i)
          end

          for i = bpp + 1, rowBytes do
            cur[i] = (sbyte(s, o + i) + cur[i - bpp]) % 256
          end
        elseif f == 2 then
          for i = 1, rowBytes do
            cur[i] = (sbyte(s, o + i) + prev[i]) % 256
          end
        elseif f == 3 then
          for i = 1, bpp do
            cur[i] = (sbyte(s, o + i) + sfloor(prev[i] / 2)) % 256
          end

          for i = bpp + 1, rowBytes do
            cur[i] = (sbyte(s, o + i) + sfloor((cur[i - bpp] + prev[i]) / 2)) % 256
          end
        elseif f == 4 then
          for i = 1, bpp do
            cur[i] = (sbyte(s, o + i) + prev[i]) % 256
          end

          for i = bpp + 1, rowBytes do
            local a, b, c = cur[i - bpp], prev[i], prev[i - bpp]
            local pp = a + b - c
            local pa_, pb_, pc_ = pp - a, pp - b, pp - c

            if pa_ < 0 then
              pa_ = -pa_
            end

            if pb_ < 0 then
              pb_ = -pb_
            end

            if pc_ < 0 then
              pc_ = -pc_
            end

            local pr_

            if pa_ <= pb_ and pa_ <= pc_ then
              pr_ = a
            elseif pb_ <= pc_ then
              pr_ = b
            else
              pr_ = c
            end

            cur[i] = (sbyte(s, o + i) + pr_) % 256
          end
        else
          error("filter PNG tidak dikenal")
        end

        local base = ym[y]

        if base then
          for k = 1, nx do
            local r, g, b, a = pixel(xl[k])
            local i = base + xi[k]
            R[i] = R[i] + r * a
            G[i] = G[i] + g * a
            B[i] = B[i] + b * a
            A[i] = A[i] + a
            N[i] = N[i] + 1
          end
        end

        prev, cur = cur, prev
      end

      local function sink(chunk)
        pending = pending .. chunk
        local p, pl = 1, #pending

        while y < h and pl - p + 1 >= need do
          processRow(pending, p)
          p = p + need
          y = y + 1
        end

        if p > 1 then
          pending = pending:sub(p)
        end

        if progress and h > 0 then
          progress(y / h)
        end
      end

      Core.inflate(table.concat(idat), 1, sink, yieldFn)

      if y < h then
        error("data PNG tidak lengkap (" .. y .. "/" .. h .. " baris)")
      end

      return Core.finish(acc)
    end

    local ZZ = {
      0, 1, 8, 16, 9, 2, 3, 10, 17, 24, 32, 25, 18, 11, 4, 5, 12, 19, 26, 33, 40, 48, 41, 34,
      27, 20, 13, 6, 7, 14, 21, 28, 35, 42, 49, 56, 57, 50, 43, 36, 29, 22, 15, 23, 30, 37, 44,
      51, 58, 59, 52, 45, 38, 31, 39, 46, 53, 60, 61, 54, 47, 55, 62, 63,
    }

    local IC = {}

    for x = 0, 7 do
      IC[x] = {}

      for u = 0, 7 do
        local cu = u == 0 and 1 / math.sqrt(2) or 1
        IC[x][u] = cu * math.cos((2 * x + 1) * u * math.pi / 16) / 2
      end
    end

    function Core.decodeJPEG(data, detail, yieldFn, progress)
      if sbyte(data, 1) ~= 255 or sbyte(data, 2) ~= 216 then
        error("bukan file JPEG")
      end

      local len = #data
      local p = 3
      local qt, dcT, acT = {}, {}, {}
      local frame, ri, adobe = nil, 0, nil
      local scanStart

      local function buildJ(counts, vals)
        local mincode, maxcode, valptr = {}, {}, {}
        local code, k = 0, 0

        for l = 1, 16 do
          if counts[l] == 0 then
            maxcode[l] = -1
            mincode[l] = 0
            valptr[l] = 0
          else
            valptr[l] = k
            mincode[l] = code
            code = code + counts[l]
            k = k + counts[l]
            maxcode[l] = code - 1
          end

          code = code * 2
        end

        return {
          mincode = mincode,
          maxcode = maxcode,
          valptr = valptr,
          vals = vals,
        }
      end

      while p < len do
        if sbyte(data, p) ~= 255 then
          p = p + 1
        else
          local m = sbyte(data, p + 1)

          if m == 255 then
            p = p + 1
          elseif m == 0 or m == 1 or m >= 208 and m <= 216 then
            p = p + 2
          elseif m == 217 then
            break
          else
            local L = sbyte(data, p + 2) * 256 + sbyte(data, p + 3)
            local s0, s1 = p + 4, p + 1 + L

            if m == 219 then
              local q = s0

              while q < s1 do
                local pq = sbyte(data, q)
                local prec, id = sfloor(pq / 16), pq % 16
                q = q + 1
                local t = {}

                for i = 0, 63 do
                  if prec == 0 then
                    t[i] = sbyte(data, q)
                    q = q + 1
                  else
                    t[i] = sbyte(data, q) * 256 + sbyte(data, q + 1)
                    q = q + 2
                  end
                end

                qt[id] = t
              end
            elseif m == 196 then
              local q = s0

              while q < s1 do
                local tc = sbyte(data, q)
                local cls, id = sfloor(tc / 16), tc % 16
                q = q + 1
                local counts, total = {}, 0

                for l = 1, 16 do
                  counts[l] = sbyte(data, q + l - 1)
                  total = total + counts[l]
                end

                q = q + 16
                local vals = {}

                for i = 0, total - 1 do
                  vals[i] = sbyte(data, q + i)
                end

                q = q + total
                local ht = buildJ(counts, vals)

                if cls == 0 then
                  dcT[id] = ht
                else
                  acT[id] = ht
                end
              end
            elseif m == 192 or m == 193 then
              local prec = sbyte(data, s0)

              if prec ~= 8 then
                error("JPEG presisi " .. prec .. " bit tidak didukung")
              end

              local fh = sbyte(data, s0 + 1) * 256 + sbyte(data, s0 + 2)
              local fw = sbyte(data, s0 + 3) * 256 + sbyte(data, s0 + 4)
              local nc = sbyte(data, s0 + 5)
              local comps = {}

              for i = 1, nc do
                local o = s0 + 6 + (i - 1) * 3
                local hv = sbyte(data, o + 1)

                comps[i] = {
                  id = sbyte(data, o),
                  h = sfloor(hv / 16),
                  v = hv % 16,
                  tq = sbyte(data, o + 2),
                }
              end

              frame = { w = fw, h = fh, comps = comps }
            elseif m == 194 or m == 195 or m >= 197 and m <= 207 and m ~= 200 and m ~= 204 then
              error("JPEG progressive/lossless belum didukung — simpan ulang sebagai PNG")
            elseif m == 221 then
              ri = sbyte(data, s0) * 256 + sbyte(data, s0 + 1)
            elseif m == 238 then
              if data:sub(s0, s0 + 4) == "Adobe" then
                adobe = sbyte(data, s0 + 11)
              end
            elseif m == 218 then
              local ns = sbyte(data, s0)

              if not frame then
                error("JPEG: SOS sebelum SOF")
              end

              if ns ~= #frame.comps then
                error("JPEG multi-scan belum didukung")
              end

              for i = 1, ns do
                local cid, tt = sbyte(data, s0 + 1 + (i - 1) * 2), sbyte(data, s0 + 2 + (i - 1) * 2)
                local found

                for _, c in ipairs(frame.comps) do
                  if c.id == cid then
                    found = c
                  end
                end

                if not found then
                  error("JPEG: komponen scan tidak dikenal")
                end

                found.dc, found.ac = sfloor(tt / 16), tt % 16
              end

              scanStart = p + 2 + L
              break
            end

            p = p + 2 + L
          end
        end
      end

      if not frame or not scanStart then
        error("JPEG tidak lengkap")
      end

      local W, H, comps = frame.w, frame.h, frame.comps
      local nc = #comps

      if nc ~= 1 and nc ~= 3 then
        error("JPEG " .. nc .. " komponen (CMYK) tidak didukung")
      end

      if nc == 1 then
        comps[1].h = 1
        comps[1].v = 1
      end

      local hmax, vmax = 1, 1

      for _, c in ipairs(comps) do
        hmax = smax(hmax, c.h)
        vmax = smax(vmax, c.v)
      end

      local mcuW, mcuH = 8 * hmax, 8 * vmax
      local mcusX, mcusY = math.ceil(W / mcuW), math.ceil(H / mcuH)

      for _, c in ipairs(comps) do
        c.stripW = mcusX * c.h * 8
        c.strip = {}
        c.pred = 0
        c.q = qt[c.tq]
        c.dct, c.act = dcT[c.dc], acT[c.ac]

        if not c.q or not c.dct or not c.act then
          error("JPEG: tabel kuantisasi/huffman hilang")
        end
      end

      local acc = Core.newAcc(W, H, detail)
      local xl, nx, ym = acc.xl, acc.nx, acc.ym
      local R, G, B, A, N = acc.R, acc.G, acc.B, acc.A, acc.N
      local xi = acc.xi
      local ss, sp = data, scanStart
      local bbuf, bcnt = 0, 0

      local function getBit()
        if bcnt == 0 then
          local b = sbyte(ss, sp)

          if b == nil then
            b = 0
          elseif b == 255 then
            local nb = sbyte(ss, sp + 1)

            if nb == 0 then
              sp = sp + 2
            else
              b = 0
            end
          else
            sp = sp + 1
          end

          bbuf = b
          bcnt = 8
        end

        bcnt = bcnt - 1
        return sfloor(bbuf / POW2[bcnt]) % 2
      end

      local function receive(n)
        local v = 0

        for _ = 1, n do
          v = v * 2 + getBit()
        end

        return v
      end

      local function decodeHuff(ht)
        local code, mincode, maxcode = 0, ht.mincode, ht.maxcode

        for l = 1, 16 do
          code = code * 2 + getBit()
          local mc = maxcode[l]

          if mc >= 0 and code <= mc then
            return ht.vals[ht.valptr[l] + code - mincode[l]]
          end
        end

        error("kode huffman JPEG rusak")
      end

      local coef = {}
      local tmp = {}

      local function idctBlock(c, ox, oy)
        local strip, sw = c.strip, c.stripW
        local acZero = true

        for i = 1, 63 do
          if coef[i] ~= 0 then
            acZero = false
            break
          end
        end

        if acZero then
          local v = coef[0] / 8 + 128

          for yy = 0, 7 do
            local o = (oy + yy) * sw + ox + 1

            for xx = 0, 7 do
              strip[o + xx] = v
            end
          end

          return
        end

        for v = 0, 7 do
          local rv = v * 8
          local any = false

          for u = 0, 7 do
            if coef[rv + u] ~= 0 then
              any = true
              break
            end
          end

          if any then
            local c0, c1, c2, c3, c4, c5, c6, c7 = coef[rv], coef[rv + 1], coef[rv + 2], coef[rv + 3], coef[rv + 4], coef[rv + 5], coef[rv + 6], coef[rv + 7]

            for x = 0, 7 do
              local t = IC[x]

              tmp[rv + x] = t[0] * c0 + t[1] * c1 + t[2] * c2 + t[3] * c3 + t[4] * c4
                + t[5] * c5 + t[6] * c6 + t[7] * c7
            end
          else
            for x = 0, 7 do
              tmp[rv + x] = 0
            end
          end
        end

        for yy = 0, 7 do
          local t = IC[yy]
          local o = (oy + yy) * sw + ox + 1

          for x = 0, 7 do
            strip[o + x] = t[0] * tmp[x] + t[1] * tmp[8 + x] + t[2] * tmp[16 + x]
              + t[3] * tmp[24 + x] + t[4] * tmp[32 + x] + t[5] * tmp[40 + x]
              + t[6] * tmp[48 + x] + t[7] * tmp[56 + x] + 128
          end
        end
      end

      local function decodeBlock(c, ox, oy)
        for i = 0, 63 do
          coef[i] = 0
        end

        local q = c.q
        local t = decodeHuff(c.dct)
        local diff = 0

        if t > 0 then
          diff = receive(t)

          if diff < POW2[t - 1] then
            diff = diff - POW2[t] + 1
          end
        end

        c.pred = c.pred + diff
        coef[0] = c.pred * q[0]
        local k = 1
        local act = c.act

        while k < 64 do
          local rs = decodeHuff(act)
          local r, s = sfloor(rs / 16), rs % 16

          if s == 0 then
            if r == 15 then
              k = k + 16
            else
              break
            end
          else
            k = k + r

            if k > 63 then
              break
            end

            local v = receive(s)

            if v < POW2[s - 1] then
              v = v - POW2[s] + 1
            end

            coef[ZZ[k + 1]] = v * q[k]
            k = k + 1
          end
        end

        idctBlock(c, ox, oy)
      end

      local rgbDirect = nc == 3 and adobe == 0
      local mcuCount = 0

      for my = 0, mcusY - 1 do
        for mx = 0, mcusX - 1 do
          if ri > 0 and mcuCount > 0 and mcuCount % ri == 0 then
            bcnt = 0

            while true do
              local b, nb = sbyte(ss, sp), sbyte(ss, sp + 1)

              if b == nil then
                break
              end

              if b == 255 and nb and nb >= 208 and nb <= 215 then
                sp = sp + 2
                break
              end

              sp = sp + 1
            end

            for _, c in ipairs(comps) do
              c.pred = 0
            end
          end

          for _, c in ipairs(comps) do
            for by = 0, c.v - 1 do
              for bx = 0, c.h - 1 do
                decodeBlock(c, (mx * c.h + bx) * 8, by * 8)
              end
            end
          end

          mcuCount = mcuCount + 1
        end

        local y0 = my * mcuH
        local y1 = smin(H, y0 + mcuH) - 1

        for y = y0, y1 do
          local base = ym[y]

          if base then
            local ly = y - y0

            for k = 1, nx do
              local x = xl[k]
              local r, g, b

              if nc == 1 then
                local c = comps[1]
                r = c.strip[ly * c.stripW + x + 1]
                g = r
                b = r
              else
                local c1, c2, c3 = comps[1], comps[2], comps[3]
                local Y = c1.strip[sfloor(ly * c1.v / vmax) * c1.stripW + sfloor(x * c1.h / hmax) + 1]
                local Cb = c2.strip[sfloor(ly * c2.v / vmax) * c2.stripW + sfloor(x * c2.h / hmax) + 1]
                local Cr = c3.strip[sfloor(ly * c3.v / vmax) * c3.stripW + sfloor(x * c3.h / hmax) + 1]

                if rgbDirect then
                  r, g, b = Y, Cb, Cr
                else
                  r = Y + 1.402 * (Cr - 128)
                  g = Y - 0.344136 * (Cb - 128) - 0.714136 * (Cr - 128)
                  b = Y + 1.772 * (Cb - 128)
                end
              end

              if r < 0 then
                r = 0
              elseif r > 255 then
                r = 255
              end

              if g < 0 then
                g = 0
              elseif g > 255 then
                g = 255
              end

              if b < 0 then
                b = 0
              elseif b > 255 then
                b = 255
              end

              local i = base + xi[k]
              R[i] = R[i] + r * 255
              G[i] = G[i] + g * 255
              B[i] = B[i] + b * 255
              A[i] = A[i] + 255
              N[i] = N[i] + 1
            end
          end
        end

        if yieldFn and my % 4 == 3 then
          yieldFn()
        end

        if progress then
          progress((my + 1) / mcusY)
        end
      end

      return Core.finish(acc)
    end

    function Core.detect(data)
      if data:sub(1, 8) == "\137PNG\r\n\26\n" then
        return "png"
      end

      if sbyte(data, 1) == 255 and sbyte(data, 2) == 216 then
        return "jpg"
      end

      if data:sub(1, 4) == "RIFF" and data:sub(9, 12) == "WEBP" then
        return "webp"
      end

      if data:sub(1, 3) == "GIF" then
        return "gif"
      end

      if data:sub(1, 2) == "BM" then
        return "bmp"
      end

      return nil
    end

    function Core.decode(data, detail, yieldFn, progress)
      local kind = Core.detect(data)

      if kind == "png" then
        return Core.decodePNG(data, detail, yieldFn, progress), kind
      end

      if kind == "jpg" then
        return Core.decodeJPEG(data, detail, yieldFn, progress), kind
      end

      error("format gambar " .. tostring(kind or "tidak dikenal")
        .. " belum didukung (pakai PNG / JPG)")
    end

    function Core.mesh(grid, opts)
      opts = opts or {}
      local w, h = grid.w, grid.h
      local levels = smax(2, smin(256, opts.levels or 16))
      local cut = opts.alphaCut or 128
      local gr, gg, gb, ga = grid.r, grid.g, grid.b, grid.a
      local solid = {}
      local anyTransparent = false

      for i = 1, w * h do
        if ga[i] >= cut then
          solid[i] = true
        else
          solid[i] = false
          anyTransparent = true
        end
      end

      local bgInfo = nil

      if opts.removeBG and not anyTransparent then
        local corners = { 1, w, (h - 1) * w + 1, h * w }
        local cr, cg, cb = 0, 0, 0

        for _, i in ipairs(corners) do
          cr = cr + gr[i]
          cg = cg + gg[i]
          cb = cb + gb[i]
        end

        cr, cg, cb = cr / 4, cg / 4, cb / 4
        local tol = opts.bgTol or 48
        local okc = true

        for _, i in ipairs(corners) do
          if math.abs(gr[i] - cr) + math.abs(gg[i] - cg) + math.abs(gb[i] - cb) > tol * 2 then
            okc = false
          end
        end

        if okc then
          bgInfo = { cr, cg, cb }
          local stack, sn = {}, 0
          local seen = {}

          local function push(x, y)
            local i = y * w + x + 1

            if not seen[i] and solid[i] then
              local d = math.abs(gr[i] - cr) + math.abs(gg[i] - cg) + math.abs(gb[i] - cb)

              if d <= tol * 2 then
                seen[i] = true
                sn = sn + 1
                stack[sn] = i
              end
            end
          end

          for x = 0, w - 1 do
            push(x, 0)
            push(x, h - 1)
          end

          for y = 0, h - 1 do
            push(0, y)
            push(w - 1, y)
          end

          while sn > 0 do
            local i = stack[sn]
            stack[sn] = nil
            sn = sn - 1
            solid[i] = false
            local x, y = (i - 1) % w, sfloor((i - 1) / w)

            if x > 0 then
              push(x - 1, y)
            end

            if x < w - 1 then
              push(x + 1, y)
            end

            if y > 0 then
              push(x, y - 1)
            end

            if y < h - 1 then
              push(x, y + 1)
            end
          end
        end
      end

      local key, qr, qg, qb = {}, {}, {}, {}
      local lm1 = levels - 1

      local function q(c)
        return sfloor(c / 255 * lm1 + 0.5)
      end

      local function dq(v)
        return sfloor(v * 255 / lm1 + 0.5)
      end

      for i = 1, w * h do
        if solid[i] then
          local a, b, c = q(gr[i]), q(gg[i]), q(gb[i])
          key[i] = (a * levels + b) * levels + c + 1
          qr[i], qg[i], qb[i] = a, b, c
        else
          key[i] = 0
        end
      end

      local used = {}
      local rects, rn = {}, 0

      for y = 0, h - 1 do
        local row = y * w

        for x = 0, w - 1 do
          local i = row + x + 1
          local k = key[i]

          if k ~= 0 and not used[i] then
            local rw = 1

            while x + rw < w do
              local j = row + x + rw + 1

              if key[j] == k and not used[j] then
                rw = rw + 1
              else
                break
              end
            end

            local rh = 1
            local going = true

            while going and y + rh < h do
              local r2 = (y + rh) * w

              for xx = x, x + rw - 1 do
                local j = r2 + xx + 1

                if key[j] ~= k or used[j] then
                  going = false
                  break
                end
              end

              if going then
                rh = rh + 1
              end
            end

            for yy = y, y + rh - 1 do
              local r2 = yy * w

              for xx = x, x + rw - 1 do
                used[r2 + xx + 1] = true
              end
            end

            rn = rn + 1

            rects[rn] = {
              x = x,
              y = y,
              w = rw,
              h = rh,
              r = dq(qr[i]),
              g = dq(qg[i]),
              b = dq(qb[i]),
            }
          end
        end
      end

      return rects, { bg = bgInfo, cells = w * h }
    end

    function Core.info(data)
      local kind = Core.detect(data)

      if kind == "png" then
        return kind, be32(data, 17), be32(data, 21)
      end

      if kind == "jpg" then
        local p = 3

        while p < #data do
          if sbyte(data, p) ~= 255 then
            p = p + 1
          else
            local m = sbyte(data, p + 1)

            if m == 255 then
              p = p + 1
            elseif m == 0 or m == 1 or m >= 208 and m <= 216 then
              p = p + 2
            elseif m == 217 or m == 218 then
              break
            else
              local L = sbyte(data, p + 2) * 256 + sbyte(data, p + 3)

              if m >= 192 and m <= 207 and m ~= 196 and m ~= 200 and m ~= 204 then
                return kind, sbyte(data, p + 7) * 256 + sbyte(data, p + 8), sbyte(data, p + 5) * 256 + sbyte(data, p + 6)
              end

              p = p + 2 + L
            end
          end
        end
      end

      return kind, nil, nil
    end

    return Core
  end)()

  local function buildImg3D(env)
    local mk, round, stroke, gradient, label, glass, C = env.mk, env.round, env.stroke, env.gradient, env.label, env.glass, env.C
    local content, setStatus, notify, httpReq = env.content, env.setStatus, env.notify, env.httpReq
    local Core = IMG3D_CORE
    local Players = game:GetService("Players")
    local ACC = Color3.fromRGB(235, 237, 245)
    local FOLDER = "xyurei_img3d"
    local SCAN_FOLDERS = { FOLDER, "xyurei_image", "" }
    local MAX_PARTS = 20000
    local canFS = type(writefile) == "function" and type(readfile) == "function"

    local function ensureFolder(f)
      if type(makefolder) ~= "function" then
        return
      end

      pcall(function()
        if not (type(isfolder) == "function" and isfolder(f)) then
          makefolder(f)
        end
      end)
    end

    ensureFolder(FOLDER)

    local function trim(s)
      return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
    end

    local function baseName(p)
      return tostring(p):match("([^/\\]+)$") or tostring(p)
    end

    local function fileExists(p)
      if type(isfile) ~= "function" then
        return false
      end

      local ok, r = pcall(isfile, p)
      return ok and r == true
    end

    local function readBin(p)
      if type(readfile) ~= "function" then
        return nil
      end

      local ok, d = pcall(readfile, p)

      if ok and type(d) == "string" and #d > 0 then
        return d
      end

      return nil
    end

    local function fmtBytes(n)
      if n >= 1048576 then
        return string.format("%.1f MB", n / 1048576)
      end

      return string.format("%d KB", math.max(1, math.floor(n / 1024 + 0.5)))
    end

    local function button(parent, text, size, pos, color, ts)
      local b = mk("TextButton", {
        Size = size,
        Position = pos,
        BackgroundColor3 = color,
        Text = text,
        TextColor3 = C.white,
        Font = Enum.Font.GothamBlack,
        TextSize = ts or 11,
        AutoButtonColor = false,
        ZIndex = 15,
      }, parent)

      round(b, 10)
      stroke(b, C.white, 1, 0.7)
      return b
    end

    local function inputBox(parent, ph, size, pos, default)
      local w = mk("Frame", {
        Size = size,
        Position = pos,
        BackgroundColor3 = C.card,
        BackgroundTransparency = 0.38,
        BorderSizePixel = 0,
        ZIndex = 14,
      }, parent)

      round(w, 10)
      stroke(w, C.white, 1, 0.85)
      glass(w)

      return mk("TextBox", {
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.fromOffset(8, 0),
        BackgroundTransparency = 1,
        PlaceholderText = ph,
        PlaceholderColor3 = C.faint,
        Text = default or "",
        TextColor3 = C.white,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 15,
      }, w)
    end

    local page = mk("ScrollingFrame", {
      Name = "Page_IMG3D",
      Size = UDim2.fromScale(1, 1),
      BackgroundTransparency = 1,
      BorderSizePixel = 0,
      ScrollBarThickness = 3,
      ScrollBarImageColor3 = C.white,
      ScrollBarImageTransparency = 0.4,
      AutomaticCanvasSize = Enum.AutomaticSize.Y,
      CanvasSize = UDim2.new(),
      ZIndex = 12,
      Visible = true,
    }, content)

    mk(
      "UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, page
    )

    local order = 0

    local function block(h)
      order = order + 1

      return mk("Frame", {
        Size = UDim2.new(1, -6, 0, h),
        BackgroundTransparency = 1,
        LayoutOrder = order,
        ZIndex = 13,
      }, page)
    end

    local b1 = block(38)

    local srcBox = inputBox(
      b1, "Paste Image ID / nama file", UDim2.new(1, -76, 1, 0), UDim2.fromOffset(0, 0)
    )

    local loadBtn = button(
      b1, "LOAD", UDim2.fromOffset(70, 38), UDim2.new(1, -70, 0, 0), C.purple, 11
    )

    local b2 = block(100)

    label(b2, {
      Size = UDim2.new(1, -70, 0, 16),
      Text = "FILE DI WORKSPACE (png / jpg)",
      TextColor3 = C.faint,
      TextSize = 9,
    })

    local scanBtn = button(
      b2, "SCAN", UDim2.fromOffset(60, 18), UDim2.new(1, -60, 0, 0), C.card2, 9
    )

    local fileList = mk("ScrollingFrame", {
      Size = UDim2.new(1, 0, 1, -22),
      Position = UDim2.fromOffset(0, 22),
      BackgroundColor3 = C.card,
      BackgroundTransparency = 0.55,
      BorderSizePixel = 0,
      ScrollBarThickness = 3,
      ScrollBarImageColor3 = C.white,
      ScrollBarImageTransparency = 0.35,
      AutomaticCanvasSize = Enum.AutomaticSize.Y,
      CanvasSize = UDim2.new(),
      ZIndex = 13,
    }, b2)

    round(fileList, 10)
    stroke(fileList, C.white, 1, 0.88)

    mk(
      "UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder },
      fileList
    )

    mk("UIPadding", {
      PaddingTop = UDim.new(0, 4),
      PaddingBottom = UDim.new(0, 4),
      PaddingLeft = UDim.new(0, 4),
      PaddingRight = UDim.new(0, 4),
    }, fileList)

    local b3 = block(132)

    local pv = mk("Frame", {
      Size = UDim2.fromScale(1, 1),
      BackgroundColor3 = C.card,
      BackgroundTransparency = 0.45,
      BorderSizePixel = 0,
      ZIndex = 13,
    }, b3)

    round(pv, 12)
    stroke(pv, ACC, 1, 0.7)

    local pvImg = mk("ImageLabel", {
      Size = UDim2.new(1, -12, 1, -34),
      Position = UDim2.fromOffset(6, 6),
      BackgroundTransparency = 1,
      Image = "",
      ScaleType = Enum.ScaleType.Fit,
      ZIndex = 14,
    }, pv)

    local pvHint = label(pv, {
      Size = UDim2.new(1, -16, 1, -34),
      Position = UDim2.fromOffset(8, 6),
      Text = [[
Belum ada gambar.
Paste ID atau pilih file.]],
      TextColor3 = C.faint,
      TextSize = 10,
      TextWrapped = true,
      TextXAlignment = Enum.TextXAlignment.Center,
      ZIndex = 15,
    })

    local pvInfo = label(pv, {
      Size = UDim2.new(1, -16, 0, 22),
      Position = UDim2.new(0, 8, 1, -26),
      Text = "",
      TextColor3 = ACC,
      TextSize = 9,
      Font = Enum.Font.GothamMedium,
      TextTruncate = Enum.TextTruncate.AtEnd,
      ZIndex = 15,
    })

    local b4 = block(96)

    local function setting(xScale, y, title, default)
      label(b4, {
        Size = UDim2.new(0.5, -6, 0, 12),
        Position = UDim2.new(xScale, 0, 0, y),
        Text = title,
        TextColor3 = C.faint,
        TextSize = 9,
      })

      return inputBox(
        b4, default, UDim2.new(0.5, -6, 0, 30), UDim2.new(xScale, 0, 0, y + 14), default
      )
    end

    local detailBox = setting(0, 0, "DETAIL (px)", "96")
    local widthBox = setting(0.5, 0, "LEBAR (studs)", "24")
    local thickBox = setting(0, 50, "TEBAL (studs)", "0.5")
    local colorBox = setting(0.5, 50, "WARNA (level)", "16")
    local b5 = block(30)
    local state = { removeBG = true, busy = false, cancel = false }

    local bgBtn = button(
      b5, "HAPUS BG: ON", UDim2.fromScale(1, 1), UDim2.fromOffset(0, 0), C.card2, 10
    )

    local b6 = block(38)

    local toModelBtn = button(
      b6, "IMAGE TO MODEL", UDim2.fromScale(1, 1), UDim2.fromOffset(0, 0), C.purple, 12
    )

    gradient(toModelBtn, {
      ColorSequenceKeypoint.new(0, Color3.fromRGB(86, 88, 100)),
      ColorSequenceKeypoint.new(1, Color3.fromRGB(38, 39, 46)),
    }, 0)

    local b8 = block(30)

    local clearBtn = button(
      b8, "HAPUS HASIL", UDim2.new(0.5, -4, 1, 0), UDim2.fromOffset(0, 0),
      Color3.fromRGB(36, 36, 44), 10
    )

    local stopBtn = button(
      b8, "STOP", UDim2.new(0.5, -4, 1, 0), UDim2.new(0.5, 4, 0, 0), C.card2, 10
    )

    local b9 = block(8)

    local track = mk("Frame", {
      Size = UDim2.fromScale(1, 1),
      BackgroundColor3 = C.card2,
      BorderSizePixel = 0,
      ZIndex = 13,
    }, b9)

    round(track, 4)

    local fill = mk("Frame", {
      Size = UDim2.new(0, 0, 1, 0),
      BackgroundColor3 = ACC,
      BorderSizePixel = 0,
      ZIndex = 14,
    }, track)

    round(fill, 4)

    gradient(
      fill, { ColorSequenceKeypoint.new(0, C.cyan), ColorSequenceKeypoint.new(1, C.purple) }, 0
    )

    local b10 = block(70)

    local msgLbl = label(b10, {
      Size = UDim2.fromScale(1, 1),
      Text = "Tempel Image ID (atau pilih file), lalu tekan LOAD.",
      TextColor3 = C.sub,
      Font = Enum.Font.GothamMedium,
      TextSize = 10,
      TextWrapped = true,
      TextYAlignment = Enum.TextYAlignment.Top,
    })

    local b11 = block(54)

    label(b11, {
      Size = UDim2.fromScale(1, 1),
      TextColor3 = C.faint,
      Font = Enum.Font.GothamMedium,
      TextSize = 8,
      TextWrapped = true,
      TextYAlignment = Enum.TextYAlignment.Top,
      Text = "Gambar dari ID disimpan di folder workspace: " .. FOLDER .. [[
/
Semua part otomatis Anchored. Hasil model hanya terlihat di sisi kamu (client).]],
    })

    local function setMsg(text, color)
      msgLbl.Text = tostring(text)
      msgLbl.TextColor3 = color or C.sub
    end

    local function setProg(f)
      f = math.max(0, math.min(1, f or 0))
      fill.Size = UDim2.new(f, 0, 1, 0)
    end

    local function setBusy(on)
      state.busy = on

      if not on then
        state.cancel = false
      end

      toModelBtn.Active = not on
      loadBtn.Active = not on
    end

    local HOSTS = {
      "https://assetdelivery.roblox.com/v1/asset/?id=",
      "https://assetdelivery.roproxy.com/v1/asset/?id=",
    }

    local function httpGet(url)
      if httpReq then
        local ok, res = pcall(httpReq, { Url = url, Method = "GET" })

        if ok and type(res) == "table" and type(res.Body) == "string" and #res.Body > 0 then
          local code = res.StatusCode or res.Status

          if res.Success ~= false and (code == nil or code == 200) then
            return res.Body
          end
        end
      end

      local ok, body = pcall(function() return game:HttpGet(url) end)

      if ok and type(body) == "string" and #body > 0 then
        return body
      end

      return nil
    end

    local fetchById

    fetchById = function(id, depth)
      for _, host in ipairs(HOSTS) do
        local body = httpGet(host .. id)

        if body then
          local kind = Core.detect(body)

          if kind then
            return body, kind, tostring(id)
          end

          if depth < 3 then
            local ref = body:match("<url>[^<]-id=(%d+)") or body:match("rbxassetid://(%d+)")
              or body:match("<url>[^<]-/(%d+)</url>")

            if ref and tostring(ref) ~= tostring(id) then
              local b2_, k2, id2 = fetchById(ref, depth + 1)

              if b2_ then
                return b2_, k2, id2
              end
            end
          end
        end
      end

      return nil
    end

    local src = nil

    local function showPreview(path, kind)
      pvImg.Image = ""
      pvHint.Visible = true
      local fn = getcustomasset or getsynasset

      if path and fn then
        local ok, asset = pcall(fn, path)

        if ok and asset then
          pvImg.Image = asset
          pvHint.Visible = false
          return
        end
      end

      pvHint.Text = [[
Preview tidak tersedia di executor ini
(gambar tetap bisa dikonversi)]]
    end

    local function acceptData(data, name, path, idLabel)
      local kind, w, h = Core.info(data)

      if not kind then
        return false, "File bukan gambar yang dikenali (pakai PNG / JPG)."
      end

      src = {
        data = data,
        kind = kind,
        w = w,
        h = h,
        path = path,
        name = name,
      }

      showPreview(path, kind)

      pvInfo.Text = string.format(
        "%s · %s · %s%s", kind:upper(), w and h and w .. "×" .. h or "?", fmtBytes(#data),
        path and " · " .. path or ""
      )

      return true
    end

    local function guessPath(name)
      local tries = { name, FOLDER .. "/" .. name, "xyurei_image/" .. name }

      for _, p in ipairs(tries) do
        local d = readBin(p)

        if d then
          return d, p
        end
      end

      return nil
    end

    local function doLoad()
      if state.busy then
        return
      end

      local t = trim(srcBox.Text)

      if t == "" then
        setMsg("Isi dulu Image ID atau nama file.", C.warn)
        return
      end

      local id = t:match("^(%d+)$") or t:match("rbxassetid://(%d+)") or t:match("[?&]id=(%d+)")
        or t:match("/library/(%d+)") or t:match("/catalog/(%d+)") or t:match("/asset/(%d+)")

      setBusy(true)
      setProg(0.05)

      task.spawn(function()
        local okAll, err = pcall(function()
          if id then
            local cachedPath

            for _, ext in ipairs({ "png", "jpg" }) do
              local p = FOLDER .. "/" .. id .. "." .. ext

              if fileExists(p) then
                cachedPath = p
                break
              end
            end

            if cachedPath then
              local d = readBin(cachedPath)

              if d then
                local ok, e = acceptData(d, id, cachedPath)

                if ok then
                  setMsg("Gambar " .. id .. " dimuat dari folder workspace.", C.ok)
                else
                  setMsg(e, C.danger)
                end

                return
              end
            end

            setMsg("Mengunduh asset " .. id .. " ...", C.warn)
            local data, kind, realId = fetchById(id, 0)

            if not data then
              setMsg("Gagal mengunduh ID " .. id
                .. ". Pastikan itu Image/Decal publik (bukan audio/model), atau taruh file gambar di folder workspace lalu pilih dari daftar.", C.danger)

              return
            end

            local path

            if canFS then
              ensureFolder(FOLDER)
              path = FOLDER .. "/" .. realId .. "." .. (kind == "jpg" and "jpg" or "png")

              if kind ~= "png" and kind ~= "jpg" then
                path = nil
              end

              if path then
                local okW = pcall(writefile, path, data)

                if not okW then
                  path = nil
                end
              end
            end

            local ok, e = acceptData(data, realId, path)

            if ok then
              setMsg("Gambar dimuat"
                .. (path and " & disimpan di " .. path or " (tidak bisa menyimpan file)")
                .. ". Tekan IMAGE TO MODEL.", C.ok)
            else
              setMsg(e, C.danger)
            end
          else
            local d, p = guessPath(t)

            if not d then
              setMsg("File '" .. t
                .. "' tidak ditemukan di workspace. Cek nama / ekstensinya, atau pilih dari daftar.", C.danger)

              return
            end

            local ok, e = acceptData(d, baseName(p), p)

            if ok then
              setMsg("File dimuat: " .. p .. ". Tekan IMAGE TO MODEL.", C.ok)
            else
              setMsg(e, C.danger)
            end
          end
        end)

        if not okAll then
          setMsg("Error: " .. tostring(err):gsub("^[^:]*:%d+: ", ""), C.danger)
        end

        setProg(0)
        setBusy(false)
      end)
    end

    local function clearList()
      for _, c in ipairs(fileList:GetChildren()) do
        if c:IsA("TextButton") or c:IsA("TextLabel") then
          c:Destroy()
        end
      end
    end

    local function scan()
      clearList()
      local seen, found = {}, {}

      for _, folder in ipairs(SCAN_FOLDERS) do
        if type(listfiles) == "function" then
          local ok, list = pcall(listfiles, folder == "" and "." or folder)

          if (not ok or type(list) ~= "table") and folder == "" then
            ok, list = pcall(listfiles, "")
          end

          if ok and type(list) == "table" then
            for _, p in ipairs(list) do
              local ext = tostring(p):lower():match("%.(%w+)$")

              if (ext == "png" or ext == "jpg" or ext == "jpeg") and not seen[p] then
                seen[p] = true
                found[#found + 1] = p
              end
            end
          end
        end
      end

      if type(listfiles) ~= "function" then
        label(fileList, {
          Size = UDim2.new(1, 0, 0, 40),
          Text = [[
listfiles tidak tersedia.
Ketik nama file di kolom atas.]],
          TextColor3 = C.faint,
          TextSize = 9,
          TextWrapped = true,
          TextXAlignment = Enum.TextXAlignment.Center,
          ZIndex = 14,
        })

        return
      end

      if #found == 0 then
        label(fileList, {
          Size = UDim2.new(1, 0, 0, 40),
          Text = [[
Belum ada gambar.
Taruh .png/.jpg di folder workspace Delta,
lalu tekan SCAN.]],
          TextColor3 = C.faint,
          TextSize = 9,
          TextWrapped = true,
          TextXAlignment = Enum.TextXAlignment.Center,
          ZIndex = 14,
        })

        return
      end

      table.sort(found)

      for i, p in ipairs(found) do
        local b = mk("TextButton", {
          Size = UDim2.new(1, 0, 0, 24),
          BackgroundColor3 = C.card2,
          BackgroundTransparency = 0.4,
          Text = baseName(p),
          TextColor3 = C.white,
          Font = Enum.Font.GothamMedium,
          TextSize = 10,
          TextXAlignment = Enum.TextXAlignment.Left,
          TextTruncate = Enum.TextTruncate.AtEnd,
          AutoButtonColor = false,
          LayoutOrder = i,
          ZIndex = 14,
        }, fileList)

        round(b, 7)
        mk("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, b)

        b.Activated:Connect(function()
          srcBox.Text = p
          doLoad()
        end)
      end
    end

    local function editableGrid(path, detail)
      local AS = game:GetService("AssetService")

      if not (path and getcustomasset and Content and Content.fromUri and AS.CreateEditableImageAsync) then
        error("EditableImage tidak tersedia di executor ini")
      end

      local img = AS:CreateEditableImageAsync(Content.fromUri(getcustomasset(path)))
      local size = img.Size
      local sw, sh = size.X, size.Y
      local buf = img:ReadPixelsBuffer(Vector2.new(0, 0), size)
      local acc = Core.newAcc(sw, sh, detail)

      for y = 0, sh - 1 do
        local base = acc.ym[y]

        if base then
          for k = 1, acc.nx do
            local x = acc.xl[k]
            local o = (y * sw + x) * 4
            local r, g, b, a = buffer.readu8(buf, o), buffer.readu8(buf, o + 1), buffer.readu8(buf, o + 2), buffer.readu8(buf, o + 3)
            local i = base + acc.xi[k]

            acc.R[i] = acc.R[i] + r * a
            acc.G[i] = acc.G[i] + g * a
            acc.B[i] = acc.B[i] + b * a
            acc.A[i] = acc.A[i] + a
            acc.N[i] = acc.N[i] + 1
          end
        end

        if y % 64 == 0 then
          task.wait()
        end
      end

      pcall(function() img:Destroy() end)
      return Core.finish(acc)
    end

    local function num(box, def, lo, hi)
      local v = tonumber(trim(box.Text))

      if not v then
        v = def
      end

      return math.max(lo, math.min(hi, v))
    end

    local function clearModel()
      if state.model then
        pcall(function() state.model:Destroy() end)
      end

      state.model, state.parts = nil, nil
    end

    local function doConvert()
      if state.busy then
        return
      end

      if not src then
        setMsg("Belum ada gambar. Tekan LOAD dulu.", C.warn)
        return
      end

      local detail = math.floor(num(detailBox, 96, 8, 256))
      local width = num(widthBox, 24, 1, 500)
      local thick = num(thickBox, 0.5, 0.05, 100)
      local levels = math.floor(num(colorBox, 16, 2, 256))
      setBusy(true)
      setProg(0.02)
      setMsg("Membaca piksel gambar ...", C.warn)

      task.spawn(function()
        local okAll, err = pcall(function()
          local lastP = 0

          local function progress(f)
            if f - lastP > 0.02 then
              lastP = f
              setProg(0.02 + f * 0.5)
            end
          end

          local grid

          local okD, eD = pcall(function()
            grid = Core.decode(src.data, detail, function() task.wait() end, progress)
          end)

          if not okD then
            local ok2, g2 = pcall(editableGrid, src.path, detail)

            if ok2 then
              grid = g2
            else
              setMsg("Gagal decode: " .. tostring(eD):gsub("^[^:]*:%d+: ", ""), C.danger)
              return
            end
          end

          setProg(0.55)
          setMsg("Membuat blok warna ...", C.warn)
          task.wait()
          local rects, info = Core.mesh(grid, { levels = levels, removeBG = state.removeBG })

          if #rects == 0 then
            setMsg("Tidak ada piksel yang terlihat (semua transparan?).", C.danger)
            return
          end

          if #rects > MAX_PARTS then
            setMsg(
              string.format("Terlalu banyak part (%d). Turunkan DETAIL atau WARNA.", #rects),
              C.danger
            )

            return
          end

          clearModel()
          local tw, th = grid.w, grid.h
          local s = width / tw
          local height = s * th
          local lp = Players.LocalPlayer
          local char = lp and lp.Character
          local hrp = char and char:FindFirstChild("HumanoidRootPart")
          local cam = workspace.CurrentCamera

          local origin = hrp and hrp.Position or cam and cam.CFrame.Position
            or Vector3.new(0, 5, 0)

          local look = cam and cam.CFrame.LookVector or Vector3.new(0, 0, -1)
          local flat = Vector3.new(look.X, 0, look.Z)

          if flat.Magnitude < 0.05 then
            flat = Vector3.new(0, 0, -1)
          end

          flat = flat.Unit

          local pos = origin + flat * math.max(12, width * 0.5 + 8)
            + Vector3.new(0, height / 2 + (hrp and -2.5 or 0), 0)

          local baseCF = CFrame.lookAt(pos, pos + flat)

          local model = Instance.new("Model")
          model.Name = "XYUREI_IMG3D_" .. tostring(src.name or "image")
          model.Parent = workspace

          local parts = {}

          for i, r in ipairs(rects) do
            local p = Instance.new("Part")
            p.Name = "Px"
            p.Anchored = true
            p.CanCollide = false
            p.CastShadow = false
            p.Material = Enum.Material.SmoothPlastic
            p.Color = Color3.fromRGB(r.r, r.g, r.b)
            p.Size = Vector3.new(r.w * s, r.h * s, thick)

            p.CFrame = baseCF * CFrame.new(
              (r.x + r.w / 2 - tw / 2) * s, -(r.y + r.h / 2 - th / 2) * s, 0
            )

            p.Parent = model
            p.Anchored = true

            parts[i] = p

            if i % 150 == 0 then
              setProg(0.6 + 0.4 * i / #rects)
              task.wait()

              if state.cancel then
                break
              end
            end
          end

          state.model, state.parts = model, parts

          local function anchorAll()
            for k, p in ipairs(parts) do
              if p.Parent and not p.Anchored then
                pcall(function() p.Anchored = true end)
              end

              if k % 400 == 0 then
                task.wait()
              end
            end
          end

          anchorAll()

          task.spawn(function()
            while model.Parent and state.model == model do
              task.wait(1.5)
              pcall(anchorAll)
            end
          end)

          setProg(1)

          local msg = string.format(
            "Selesai: %d part (%d×%d sel, %.1f×%.1f studs)%s. Semua part Anchored. Model ada di depan karaktermu.",
            #parts, tw, th, width, height, info.bg and ", background dihapus" or ""
          )

          setMsg(msg, C.ok)

          if setStatus then
            setStatus("IMAGE TO MODEL • " .. #parts .. " PART", C.ok)
          end

          if notify then
            notify("IMAGE 3D", "Model dibuat: " .. #parts .. " part", true)
          end
        end)

        if not okAll then
          setMsg("Error: " .. tostring(err):gsub("^[^:]*:%d+: ", ""), C.danger)
        end

        task.wait(0.4)
        setProg(0)
        setBusy(false)
      end)
    end

    loadBtn.Activated:Connect(doLoad)

    srcBox.FocusLost:Connect(function(enter)
      if enter then
        doLoad()
      end
    end)

    scanBtn.Activated:Connect(scan)
    toModelBtn.Activated:Connect(doConvert)

    clearBtn.Activated:Connect(function()
      if state.busy then
        state.cancel = true
      end

      clearModel()
      setProg(0)
      setMsg("Hasil dihapus.", C.sub)
    end)

    stopBtn.Activated:Connect(function()
      if state.busy then
        state.cancel = true
        setMsg("Menghentikan ...", C.warn)
      end
    end)

    bgBtn.Activated:Connect(function()
      state.removeBG = not state.removeBG
      bgBtn.Text = "HAPUS BG: " .. (state.removeBG and "ON" or "OFF")
    end)

    task.defer(scan)
    return page
  end

  XYUREI_CONFIG.__IMG3D = { build = buildImg3D, core = IMG3D_CORE }
  XYUREI_CONFIG.__REPLACE = {}

  function XYUREI_CONFIG.__REPLACE.build(env)
    local mk, round, stroke, label, C = env.mk, env.round, env.stroke, env.label, env.C
    local content, setStatus = env.content, env.setStatus
    local LP = game:GetService("Players").LocalPlayer
    local RS = game:GetService("ReplicatedStorage")
    local SEL = Color3.fromRGB(96, 99, 112)
    local OFF = Color3.fromRGB(34, 35, 41)
    local statusLbl

    local function say(t, col)
      if statusLbl then
        statusLbl.Text = tostring(t)
        statusLbl.TextColor3 = col or C.sub
      end

      if setStatus then
        pcall(setStatus, tostring(t), col or C.sub)
      end
    end

    local orders = {}

    local function btn(parent, text, size, pos, color, ts)
      local b = mk("TextButton", {
        Size = size,
        Position = pos or UDim2.new(),
        BackgroundColor3 = color or C.purple,
        Text = text,
        TextColor3 = C.white,
        Font = Enum.Font.GothamBlack,
        TextSize = ts or 10,
        AutoButtonColor = false,
        ZIndex = 16,
      }, parent)

      round(b, 9)
      stroke(b, C.white, 1, 0.75)
      return b
    end

    local function field(parent, ph, text, size, pos)
      local w = mk("Frame", {
        Size = size,
        Position = pos or UDim2.new(),
        BackgroundColor3 = C.card2,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        ZIndex = 15,
      }, parent)

      round(w, 8)
      stroke(w, C.white, 1, 0.85)

      local t = mk("TextBox", {
        Size = UDim2.new(1, -8, 1, 0),
        Position = UDim2.fromOffset(4, 0),
        BackgroundTransparency = 1,
        PlaceholderText = ph,
        PlaceholderColor3 = C.faint,
        Text = text or "",
        TextColor3 = C.white,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        ClearTextOnFocus = false,
        ZIndex = 16,
      }, w)

      return t
    end

    local function card(parent, h, titleText)
      local o = (orders[parent] or 0) + 1
      orders[parent] = o

      local f = mk("Frame", {
        Size = UDim2.new(1, -6, 0, h),
        BackgroundColor3 = C.card,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        LayoutOrder = o,
        ZIndex = 14,
      }, parent)

      round(f, 11)
      stroke(f, C.white, 1, 0.85)

      if titleText then
        label(f, {
          Size = UDim2.new(1, -16, 0, 14),
          Position = UDim2.fromOffset(8, 6),
          Text = titleText,
          TextSize = 9,
          TextColor3 = C.faint,
        })
      end

      return f
    end

    local function bigBtn(parent, text, h, color)
      local o = (orders[parent] or 0) + 1
      orders[parent] = o

      local b = btn(parent, text, UDim2.new(1, -6, 0, h), nil, color or C.purple, 11)
      b.LayoutOrder = o

      return b
    end

    local function infoBox(parent, y, h)
      local w = mk("Frame", {
        Size = UDim2.new(1, -16, 0, h),
        Position = UDim2.fromOffset(8, y),
        BackgroundColor3 = C.card2,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        ZIndex = 15,
      }, parent)

      round(w, 8)

      return label(w, {
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.fromOffset(5, 0),
        Text = "(belum dipilih)",
        TextSize = 9,
        Font = Enum.Font.GothamMedium,
        TextColor3 = C.sub,
        TextWrapped = true,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextYAlignment = Enum.TextYAlignment.Center,
      })
    end

    local function newScroll(parent)
      local s = mk("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, -54),
        Position = UDim2.fromOffset(0, 32),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = C.white,
        ScrollBarImageTransparency = 0.4,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        Visible = false,
        ZIndex = 13,
      }, parent)

      mk(
        "UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, s
      )

      mk("UIPadding", { PaddingBottom = UDim.new(0, 8) }, s)

      return s
    end

    local function toggleRow(parent, y, text, default)
      local b = btn(parent, "", UDim2.new(1, -16, 0, 26), UDim2.fromOffset(8, y), OFF, 9)
      local state = default

      local function paint()
        b.Text = (state and "ON · " or "OFF · ") .. text
        b.BackgroundColor3 = state and SEL or OFF
      end

      b.Activated:Connect(function()
        state = not state
        paint()
      end)

      paint()
      return function() return state end
    end

    local page = mk("Frame", {
      Name = "Page_REPLACE",
      Size = UDim2.fromScale(1, 1),
      BackgroundTransparency = 1,
      Visible = false,
      ZIndex = 12,
    }, content)

    local tabBar = mk(
      "Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, ZIndex = 13 }, page
    )

    local tabC = btn(tabBar, "WARNA & MATERIAL", UDim2.new(0.5, -3, 1, 0), UDim2.new(), SEL, 9)

    local tabM = btn(
      tabBar, "GANTI MODEL / PART", UDim2.new(0.5, -3, 1, 0), UDim2.new(0.5, 3, 0, 0), OFF, 9
    )

    local sc, sm = newScroll(page), newScroll(page)

    statusLbl = label(page, {
      Size = UDim2.new(1, 0, 0, 16),
      Position = UDim2.new(0, 0, 1, -18),
      Text = "Siap. Pilih target dulu.",
      TextSize = 9,
      Font = Enum.Font.GothamMedium,
      TextColor3 = C.sub,
      TextTruncate = Enum.TextTruncate.AtEnd,
      ZIndex = 14,
    })

    local stopClickRef

    local function showTab(which)
      if stopClickRef then
        stopClickRef()
      end

      sc.Visible = which == "C"
      sm.Visible = which == "M"
      tabC.BackgroundColor3 = which == "C" and SEL or OFF
      tabM.BackgroundColor3 = which == "M" and SEL or OFF
    end

    tabC.Activated:Connect(function() showTab("C") end)
    tabM.Activated:Connect(function() showTab("M") end)
    showTab("C")
    local undoStack = {}

    local function pushUndo(text, fn)
      undoStack[#undoStack + 1] = { text = text, fn = fn }

      if #undoStack > 8 then
        table.remove(undoStack, 1)
      end
    end

    local function doUndo()
      local u = table.remove(undoStack)

      if not u then
        say("Tidak ada yang bisa di-undo.", C.warn)
        return
      end

      local ok, err = pcall(u.fn)

      if ok then
        say("Undo: " .. u.text, C.ok)
      else
        say("Undo gagal: " .. tostring(err), C.danger)
      end
    end

    local clickLevel = "MODEL"
    local levelChips = {}

    local function refreshLevels()
      for lv, chip in pairs(levelChips) do
        for _, c in ipairs(chip) do
          c.BackgroundColor3 = lv == clickLevel and SEL or OFF
        end
      end
    end

    local function levelRow(parent, y)
      label(parent, {
        Size = UDim2.fromOffset(52, 22),
        Position = UDim2.fromOffset(8, y),
        Text = "KLIK =",
        TextSize = 9,
        TextColor3 = C.faint,
      })

      for i, nm in ipairs({ "PART", "MODEL", "FOLDER" }) do
        local c = btn(
          parent, nm, UDim2.new(0.24, 0, 0, 22), UDim2.new(0.22 + (i - 1) * 0.25, 0, 0, y), OFF,
          8
        )

        levelChips[nm] = levelChips[nm] or {}
        table.insert(levelChips[nm], c)

        c.Activated:Connect(function()
          clickLevel = nm
          refreshLevels()
        end)
      end

      refreshLevels()
    end

    local function resolveLevel(part)
      if clickLevel == "PART" then
        return part
      end

      if clickLevel == "MODEL" then
        return part:FindFirstAncestorOfClass("Model") or part
      end

      return part:FindFirstAncestorOfClass("Folder") or part:FindFirstAncestorOfClass("Model")
        or part
    end

    local clickConn

    local function stopClick()
      if clickConn then
        clickConn:Disconnect()
        clickConn = nil
      end
    end

    stopClickRef = stopClick

    local function startClick(cb, hint)
      stopClick()
      local mouse = LP:GetMouse()
      say(hint or "Tap sebuah part di workspace...", C.warn)

      clickConn = mouse.Button1Down:Connect(function()
        local t = mouse.Target

        if t then
          stopClick()
          cb(t)
        end
      end)
    end

    local function isUnit(o)
      return o:IsA("BasePart") and not o:IsA("Terrain") or o:IsA("Model")
    end

    local function describe(o)
      if not o then
        return "(belum dipilih)"
      end

      local tag = o:IsA("Folder") and "FOLDER" or o:IsA("Model") and "MODEL"
        or o:IsA("BasePart") and "PART" or o.ClassName

      return tag .. " · " .. o.Name
    end

    local cur, browseMode = workspace, "color"

    local overlay = mk("Frame", {
      Size = UDim2.fromScale(1, 1),
      BackgroundColor3 = C.bg,
      BackgroundTransparency = 0.04,
      BorderSizePixel = 0,
      Visible = false,
      ZIndex = 40,
    }, page)

    round(overlay, 11)
    stroke(overlay, C.white, 1, 0.8)

    local ovTitle = label(overlay, {
      Size = UDim2.new(1, -16, 0, 14),
      Position = UDim2.fromOffset(8, 6),
      Text = "PILIH",
      TextSize = 10,
      ZIndex = 41,
    })

    local pathLbl = label(overlay, {
      Size = UDim2.new(1, -16, 0, 12),
      Position = UDim2.fromOffset(8, 22),
      Text = "Workspace",
      TextSize = 8,
      Font = Enum.Font.GothamMedium,
      TextColor3 = C.faint,
      TextTruncate = Enum.TextTruncate.AtEnd,
      ZIndex = 41,
    })

    local list = mk("ScrollingFrame", {
      Size = UDim2.new(1, -16, 1, -86),
      Position = UDim2.fromOffset(8, 38),
      BackgroundTransparency = 1,
      BorderSizePixel = 0,
      ScrollBarThickness = 3,
      ScrollBarImageColor3 = C.white,
      ScrollBarImageTransparency = 0.4,
      AutomaticCanvasSize = Enum.AutomaticSize.Y,
      CanvasSize = UDim2.new(),
      ZIndex = 41,
    }, overlay)

    mk(
      "UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, list
    )

    local upBtn = btn(
      overlay, "NAIK", UDim2.new(0.25, -4, 0, 28), UDim2.new(0, 8, 1, -36), OFF, 9
    )

    upBtn.ZIndex = 41

    local hereBtn = btn(
      overlay, "PILIH ISI FOLDER INI", UDim2.new(0.5, -4, 0, 28), UDim2.new(0.25, 4, 1, -36),
      SEL, 9
    )

    hereBtn.ZIndex = 41

    local closeBtn = btn(
      overlay, "TUTUP", UDim2.new(0.25, -12, 0, 28), UDim2.new(0.75, 4, 1, -36), OFF, 9
    )

    closeBtn.ZIndex = 41

    local choose

    local function rank(o)
      if o:IsA("Folder") or o.Parent == game then
        return 1
      end

      if o:IsA("Model") then
        return 2
      end

      return 3
    end

    local function canEnter(o)
      if o.Parent == game then
        return true
      end

      if not (o:IsA("Folder") or o:IsA("Model")) then
        return false
      end

      for _, ch in ipairs(o:GetChildren()) do
        if ch:IsA("Folder") or ch:IsA("Model") or ch:IsA("BasePart") and not ch:IsA("Terrain") then
          return true
        end
      end

      return false
    end

    local fillList

    local function makeRow(o, order)
      local row = mk("Frame", {
        Size = UDim2.new(1, -4, 0, 28),
        BackgroundTransparency = 1,
        LayoutOrder = order,
        ZIndex = 41,
      }, list)

      local tag = o.Parent == game and "SVC" or o:IsA("Folder") and "FLD"
        or o:IsA("Model") and "MDL" or "PRT"

      local main = btn(row, "", UDim2.new(1, -60, 1, 0), UDim2.new(), C.card2, 9)
      main.ZIndex = 41

      label(main, {
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.fromOffset(6, 0),
        Text = tag,
        TextSize = 8,
        TextColor3 = C.faint,
        ZIndex = 42,
      })

      label(main, {
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.fromOffset(34, 0),
        Text = o.Name .. (canEnter(o) and " ›" or ""),
        TextSize = 10,
        Font = Enum.Font.GothamMedium,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 42,
      })

      local pick = btn(row, "PILIH", UDim2.new(0, 54, 1, 0), UDim2.new(1, -54, 0, 0), SEL, 9)
      pick.ZIndex = 41

      main.Activated:Connect(function()
        if canEnter(o) then
          cur = o
          fillList()
        else
          choose(o)
        end
      end)

      pick.Activated:Connect(function() choose(o) end)
    end

    fillList = function()
      for _, ch in ipairs(list:GetChildren()) do
        if not ch:IsA("UIListLayout") then
          ch:Destroy()
        end
      end

      pathLbl.Text = cur == game and "game" or cur:GetFullName()
      local items = {}

      if cur == game then
        items = { workspace, RS }
      else
        for _, ch in ipairs(cur:GetChildren()) do
          if ch:IsA("Folder") or ch:IsA("Model") or ch:IsA("BasePart") and not ch:IsA("Terrain") then
            items[#items + 1] = ch
          end
        end
      end

      table.sort(items, function(a, b)
        local ra, rb = rank(a), rank(b)

        if ra ~= rb then
          return ra < rb
        end

        return a.Name:lower() < b.Name:lower()
      end)

      local shown = math.min(#items, 250)

      for i = 1, shown do
        makeRow(items[i], i)
      end

      if #items > shown then
        label(list, {
          Size = UDim2.new(1, -4, 0, 18),
          Text = ("+%d item lain tidak ditampilkan (masuk ke folder/model lebih dalam)"):format(#items
            - shown),
          TextSize = 8,
          TextColor3 = C.faint,
          LayoutOrder = 9999,
          ZIndex = 41,
        })
      end

      if #items == 0 then
        label(list, {
          Size = UDim2.new(1, -4, 0, 18),
          Text = "(kosong)",
          TextSize = 9,
          TextColor3 = C.faint,
          ZIndex = 41,
        })
      end
    end

    local function openBrowser(mode, titleText)
      browseMode = mode
      ovTitle.Text = titleText
      hereBtn.Visible = mode ~= "source"

      if not cur or cur ~= game and not cur.Parent then
        cur = workspace
      end

      overlay.Visible = true
      fillList()
    end

    upBtn.Activated:Connect(function()
      if cur ~= game and cur.Parent then
        cur = cur.Parent
        fillList()
      end
    end)

    closeBtn.Activated:Connect(function() overlay.Visible = false end)

    hereBtn.Activated:Connect(function()
      if cur == game or cur == workspace or cur == RS then
        say("Masuk dulu ke sebuah folder/model, lalu tekan tombol ini.", C.warn)
      else
        choose(cur)
      end
    end)

    local colorTarget
    local ctInfo

    local function setColorTarget(o)
      colorTarget = o
      ctInfo.Text = describe(o)
      say("Target warna: " .. describe(o), C.ok)
    end

    do
      local c = card(sc, 112, "TARGET")
      ctInfo = infoBox(c, 22, 22)
      local pb = btn(c, "PILIH", UDim2.new(0.5, -12, 0, 26), UDim2.fromOffset(8, 48), SEL, 10)

      local kb = btn(
        c, "KLIK PART", UDim2.new(0.5, -12, 0, 26), UDim2.new(0.5, 4, 0, 48), OFF, 10
      )

      pb.Activated:Connect(function() openBrowser("color", "PILIH TARGET WARNA") end)

      kb.Activated:Connect(function()
        startClick(function(p) setColorTarget(resolveLevel(p)) end)
      end)

      levelRow(c, 82)
    end

    local function rgbRow(parent, y, r, g, b)
      local holder = mk("Frame", {
        Size = UDim2.new(1, -16, 0, 28),
        Position = UDim2.fromOffset(8, y),
        BackgroundTransparency = 1,
        ZIndex = 15,
      }, parent)

      local R = field(holder, "R", tostring(r), UDim2.new(0.21, 0, 1, 0), UDim2.new(0, 0, 0, 0))

      local G = field(
        holder, "G", tostring(g), UDim2.new(0.21, 0, 1, 0), UDim2.new(0.225, 0, 0, 0)
      )

      local B = field(
        holder, "B", tostring(b), UDim2.new(0.21, 0, 1, 0), UDim2.new(0.45, 0, 0, 0)
      )

      local pick = btn(
        holder, "AMBIL", UDim2.new(0.3, 0, 1, 0), UDim2.new(0.7, 0, 0, 0), OFF, 9
      )

      return R, G, B, pick
    end

    local function c255(v)
      return math.clamp(math.floor((tonumber(v) or 0) + 0.5), 0, 255)
    end

    local function boxColor(R, G, B)
      return Color3.fromRGB(c255(R.Text), c255(G.Text), c255(B.Text))
    end

    local function setBoxes(R, G, B, col)
      R.Text = tostring(math.floor(col.R * 255 + 0.5))
      G.Text = tostring(math.floor(col.G * 255 + 0.5))
      B.Text = tostring(math.floor(col.B * 255 + 0.5))
    end

    local fR, fG, fB, fPrev, rR, rG, rB, rPrev

    do
      local c = card(sc, 100, "CARI WARNA")
      local pick
      fR, fG, fB, pick = rgbRow(c, 24, 0, 0, 255)

      fPrev = mk("Frame", {
        Size = UDim2.new(1, -16, 0, 16),
        Position = UDim2.fromOffset(8, 58),
        BackgroundColor3 = Color3.fromRGB(0, 0, 255),
        BorderSizePixel = 0,
        ZIndex = 15,
      }, c)

      round(fPrev, 6)

      label(c, {
        Size = UDim2.new(1, -16, 0, 14),
        Position = UDim2.fromOffset(8, 80),
        Text = "AMBIL = tap part untuk salin warnanya",
        TextSize = 8,
        Font = Enum.Font.GothamMedium,
        TextColor3 = C.faint,
      })

      local function upd()
        fPrev.BackgroundColor3 = boxColor(fR, fG, fB)
      end

      for _, t in ipairs({ fR, fG, fB }) do
        t.FocusLost:Connect(upd)
      end

      pick.Activated:Connect(function()
        startClick(function(p)
          setBoxes(fR, fG, fB, p.Color)
          upd()
          say("Warna cari diambil dari " .. p.Name, C.ok)
        end, "Tap part untuk ambil warna CARI...")
      end)
    end

    do
      local c = card(sc, 100, "GANTI KE WARNA")
      local pick
      rR, rG, rB, pick = rgbRow(c, 24, 255, 0, 0)

      rPrev = mk("Frame", {
        Size = UDim2.new(1, -16, 0, 16),
        Position = UDim2.fromOffset(8, 58),
        BackgroundColor3 = Color3.fromRGB(255, 0, 0),
        BorderSizePixel = 0,
        ZIndex = 15,
      }, c)

      round(rPrev, 6)

      label(c, {
        Size = UDim2.fromOffset(70, 18),
        Position = UDim2.fromOffset(8, 78),
        Text = "TOLERANSI",
        TextSize = 8,
        TextColor3 = C.faint,
      })

      local tolBox = field(c, "5", "5", UDim2.new(0, 56, 0, 18), UDim2.fromOffset(80, 78))

      label(c, {
        Size = UDim2.new(1, -150, 0, 18),
        Position = UDim2.fromOffset(142, 78),
        Text = "(0-255, makin besar makin longgar)",
        TextSize = 7,
        Font = Enum.Font.GothamMedium,
        TextColor3 = C.faint,
        TextTruncate = Enum.TextTruncate.AtEnd,
      })

      rPrev:SetAttribute("tol", 5)

      tolBox.FocusLost:Connect(function()
        rPrev:SetAttribute("tol", math.clamp(tonumber(tolBox.Text) or 5, 0, 255))
      end)

      local function upd()
        rPrev.BackgroundColor3 = boxColor(rR, rG, rB)
      end

      for _, t in ipairs({ rR, rG, rB }) do
        t.FocusLost:Connect(upd)
      end

      pick.Activated:Connect(function()
        startClick(function(p)
          setBoxes(rR, rG, rB, p.Color)
          upd()
          say("Warna ganti diambil dari " .. p.Name, C.ok)
        end, "Tap part untuk ambil warna GANTI...")
      end)
    end

    local MATS = {
      "Plastic", "SmoothPlastic", "Wood", "WoodPlanks", "Metal", "DiamondPlate", "Concrete",
      "Brick", "Marble", "Granite", "Neon", "Glass",
    }

    local selectedMat = Enum.Material.Plastic
    local matChips = {}

    do
      local c = card(sc, 28 + 6 * 30, "MATERIAL")

      for i, nm in ipairs(MATS) do
        local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
        local ok, mat = pcall(function() return Enum.Material[nm] end)

        if ok and mat then
          local b = btn(
            c, nm, UDim2.new(0.5, -12, 0, 26),
            UDim2.new(col * 0.5, col == 0 and 8 or 4, 0, 24 + row * 30), i == 1 and SEL or OFF,
            9
          )

          matChips[#matChips + 1] = { b = b, m = mat }

          b.Activated:Connect(function()
            selectedMat = mat

            for _, d in ipairs(matChips) do
              d.b.BackgroundColor3 = d.m == mat and SEL or OFF
            end
          end)
        end
      end
    end

    local function collectParts(root)
      local out = {}

      if root:IsA("BasePart") then
        out[1] = root
      end

      for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("BasePart") then
          out[#out + 1] = d
        end
      end

      return out
    end

    local btnColor = bigBtn(sc, "GANTI WARNA", 36, SEL)
    local btnMat = bigBtn(sc, "UBAH MATERIAL", 36, C.purple)
    local btnUndo1 = bigBtn(sc, "UNDO TERAKHIR", 28, OFF)

    btnColor.Activated:Connect(function()
      if not colorTarget or not colorTarget.Parent then
        say("Pilih target dulu (PILIH / KLIK PART).", C.danger)
        return
      end

      local fc, rc = boxColor(fR, fG, fB), boxColor(rR, rG, rB)
      local tol = (tonumber(rPrev:GetAttribute("tol")) or 5) / 255
      local parts = collectParts(colorTarget)
      local old, changed = {}, 0

      for i, p in ipairs(parts) do
        local c = p.Color

        if math.abs(c.R - fc.R) <= tol and math.abs(c.G - fc.G) <= tol
          and math.abs(c.B - fc.B) <= tol then
          old[p] = c
          p.Color = rc
          changed = changed + 1
        end

        if i % 400 == 0 then
          task.wait()
        end
      end

      if changed > 0 then
        pushUndo("warna " .. changed .. " part", function()
          for p, c in pairs(old) do
            if p.Parent then
              p.Color = c
            end
          end
        end)

        say(("Berhasil: %d dari %d part diganti warnanya."):format(changed, #parts), C.ok)
      else
        say(
          ("Tidak ada part yang cocok (total %d part). Coba naikkan toleransi."):format(#parts),
          C.warn
        )
      end
    end)

    btnMat.Activated:Connect(function()
      if not colorTarget or not colorTarget.Parent then
        say("Pilih target dulu (PILIH / KLIK PART).", C.danger)
        return
      end

      local parts = collectParts(colorTarget)
      local old = {}

      for i, p in ipairs(parts) do
        old[p] = p.Material
        p.Material = selectedMat

        if i % 400 == 0 then
          task.wait()
        end
      end

      pushUndo("material " .. #parts .. " part", function()
        for p, m in pairs(old) do
          if p.Parent then
            p.Material = m
          end
        end
      end)

      say(("Material diubah ke %s di %d part."):format(selectedMat.Name, #parts), C.ok)
    end)

    btnUndo1.Activated:Connect(doUndo)
    local targets, targetSet = {}, {}
    local source
    local tInfo, sInfo

    local function refreshTargets()
      local alive = {}

      for _, t in ipairs(targets) do
        if t.Parent then
          alive[#alive + 1] = t
        else
          targetSet[t] = nil
        end
      end

      targets = alive

      if #targets == 0 then
        tInfo.Text = "(belum ada target — tambah part / model / folder)"
        return
      end

      local names = {}

      for i = 1, math.min(3, #targets) do
        names[#names + 1] = targets[i].Name
      end

      tInfo.Text = ("%d target: %s%s"):format(
        #targets, table.concat(names, ", "), #targets > 3 and ", ..." or ""
      )
    end

    local function hasAncestorIn(o)
      local p = o.Parent

      while p do
        if targetSet[p] then
          return true
        end

        p = p.Parent
      end

      return false
    end

    local function expand(o, out)
      if o:IsA("Folder") then
        for _, ch in ipairs(o:GetChildren()) do
          expand(ch, out)
        end
      elseif isUnit(o) then
        out[#out + 1] = o
      end
    end

    local function addTarget(o)
      local found = {}
      expand(o, found)

      if #found == 0 then
        say("Tidak ada part/model di " .. o.Name .. ".", C.warn)
        return 0
      end

      local added = 0

      for _, f in ipairs(found) do
        if not targetSet[f] and not hasAncestorIn(f) then
          for i = #targets, 1, -1 do
            if targets[i]:IsDescendantOf(f) then
              targetSet[targets[i]] = nil
              table.remove(targets, i)
            end
          end

          targets[#targets + 1] = f
          targetSet[f] = true
          added = added + 1
        end
      end

      refreshTargets()
      return added
    end

    local function setSource(o)
      if not isUnit(o) then
        say("Model pengganti harus Model atau Part.", C.danger)
        return
      end

      source = o
      sInfo.Text = describe(o)
      say("Model pengganti: " .. describe(o), C.ok)
    end

    choose = function(o)
      if browseMode == "targets" then
        local n = addTarget(o)

        say(("+%d target ditambahkan (total %d). Lanjut pilih lagi atau TUTUP."):format(
          n, #targets
        ), n > 0 and C.ok or C.warn)
      elseif browseMode == "source" then
        setSource(o)
        overlay.Visible = false
      else
        setColorTarget(o)
        overlay.Visible = false
      end
    end

    do
      local c = card(sm, 138, "1 · PART / FOLDER YANG MAU DIGANTI")
      tInfo = infoBox(c, 22, 34)
      local pb = btn(c, "PILIH", UDim2.new(0.34, -8, 0, 26), UDim2.fromOffset(8, 62), SEL, 9)

      local kb = btn(
        c, "KLIK PART", UDim2.new(0.33, -4, 0, 26), UDim2.new(0.34, 0, 0, 62), OFF, 9
      )

      local cb = btn(
        c, "KOSONGKAN", UDim2.new(0.33, -8, 0, 26), UDim2.new(0.67, 0, 0, 62), OFF, 9
      )

      pb.Activated:Connect(function()
        openBrowser("targets", "TAMBAH TARGET (folder = semua isinya)")
      end)

      kb.Activated:Connect(function()
        startClick(function(p)
          local n = addTarget(resolveLevel(p))

          say(
            ("+%d target (total %d). Tap KLIK PART lagi untuk tambah."):format(n, #targets),
            n > 0 and C.ok or C.warn
          )
        end)
      end)

      cb.Activated:Connect(function()
        targets, targetSet = {}, {}
        refreshTargets()
        say("Daftar target dikosongkan.", C.sub)
      end)

      levelRow(c, 96)

      label(c, {
        Size = UDim2.new(1, -16, 0, 12),
        Position = UDim2.fromOffset(8, 120),
        Text = "Pilih FOLDER → semua model/part di dalamnya ikut jadi target.",
        TextSize = 7,
        Font = Enum.Font.GothamMedium,
        TextColor3 = C.faint,
        TextTruncate = Enum.TextTruncate.AtEnd,
      })

      refreshTargets()
    end

    do
      local c = card(sm, 84, "2 · MODEL PENGGANTI")
      sInfo = infoBox(c, 22, 22)
      local pb = btn(c, "PILIH", UDim2.new(0.5, -12, 0, 26), UDim2.fromOffset(8, 50), SEL, 10)

      local kb = btn(
        c, "KLIK PART", UDim2.new(0.5, -12, 0, 26), UDim2.new(0.5, 4, 0, 50), OFF, 10
      )

      pb.Activated:Connect(function() openBrowser("source", "PILIH MODEL PENGGANTI") end)

      kb.Activated:Connect(function()
        startClick(
          function(p) setSource(resolveLevel(p)) end, "Tap part dari model pengganti..."
        )
      end)
    end

    local optFit, optDel, optAnchor, rotBox

    do
      local c = card(sm, 150, "OPSI")
      optFit = toggleRow(c, 22, "SESUAIKAN UKURAN KE TARGET", false)
      optDel = toggleRow(c, 52, "HAPUS TARGET LAMA (bisa UNDO)", true)
      optAnchor = toggleRow(c, 82, "ANCHOR HASIL", true)

      label(c, {
        Size = UDim2.fromOffset(110, 26),
        Position = UDim2.fromOffset(8, 114),
        Text = "PUTAR Y (derajat)",
        TextSize = 8,
        TextColor3 = C.faint,
      })

      rotBox = field(c, "0", "0", UDim2.new(0, 70, 0, 26), UDim2.fromOffset(120, 114))
    end

    local btnRep = bigBtn(sm, "REPLACE SEKARANG", 40, SEL)
    local btnUndo2 = bigBtn(sm, "UNDO TERAKHIR", 28, OFF)

    local function sizeOf(o)
      if o:IsA("Model") then
        return o:GetExtentsSize()
      end

      return o.Size
    end

    btnRep.Activated:Connect(function()
      refreshTargets()

      if not source or not source.Parent then
        say("Pilih model pengganti dulu (langkah 2).", C.danger)
        return
      end

      local list2 = {}

      for _, t in ipairs(targets) do
        if t ~= source and not t:IsDescendantOf(source) and not source:IsDescendantOf(t) then
          list2[#list2 + 1] = t
        end
      end

      if #list2 == 0 then
        say(
          "Belum ada target yang valid (target tidak boleh sama dengan model pengganti).",
          C.danger
        )

        return
      end

      local fit, del, anc = optFit(), optDel(), optAnchor()
      local rotY = tonumber(rotBox.Text) or 0
      local rec = { new = {}, old = {} }
      local fail = 0
      say(("Mengganti %d target..."):format(#list2), C.warn)

      for i, t in ipairs(list2) do
        local ok = pcall(function()
          local clone = source:Clone()

          if not clone then
            error("tidak bisa di-clone")
          end

          local pivot = t:GetPivot()

          if rotY ~= 0 then
            pivot = pivot * CFrame.Angles(0, math.rad(rotY), 0)
          end

          if fit then
            pcall(function()
              local ts, ms = sizeOf(t), sizeOf(clone)

              if clone:IsA("Model") then
                local r = math.min(
                  ts.X / math.max(ms.X, 0.001), ts.Y / math.max(ms.Y, 0.001),
                  ts.Z / math.max(ms.Z, 0.001)
                )

                if r > 0 and r == r and r ~= math.huge then
                  clone:ScaleTo(clone:GetScale() * r)
                end
              else
                clone.Size = ts
              end
            end)
          end

          clone:PivotTo(pivot)

          if anc then
            if clone:IsA("BasePart") then
              clone.Anchored = true
            end

            for _, d in ipairs(clone:GetDescendants()) do
              if d:IsA("BasePart") then
                d.Anchored = true
              end
            end
          end

          local parent = t.Parent
          clone.Parent = parent
          rec.new[#rec.new + 1] = clone

          if del then
            rec.old[#rec.old + 1] = { obj = t, parent = parent }
            t.Parent = nil
            targetSet[t] = nil
          end
        end)

        if not ok then
          fail = fail + 1
        end

        if i % 15 == 0 then
          task.wait()
        end
      end

      if del then
        refreshTargets()
      end

      pushUndo("replace " .. #rec.new .. " item", function()
        for _, n in ipairs(rec.new) do
          pcall(function() n:Destroy() end)
        end

        for _, o in ipairs(rec.old) do
          pcall(function() o.obj.Parent = o.parent end)
        end
      end)

      say(("Selesai: %d diganti%s. Tekan UNDO kalau salah."):format(#rec.new, fail > 0
          and ", " .. fail .. " gagal"
        or ""), fail > 0 and C.warn or C.ok)
    end)

    btnUndo2.Activated:Connect(doUndo)
    return page
  end
end

local function __buildXyureiGui()
  local old1 = CoreDest:FindFirstChild("ImporterHub")
  if old1 then pcall(function() old1:Destroy() end) end
  local old2 = CoreDest:FindFirstChild("ImporterHubToggle")
  if old2 then pcall(function() old2:Destroy() end) end
  local old3 = CoreDest:FindFirstChild("EZY_RBXL_CORE")
  if old3 then pcall(function() old3:Destroy() end) end

  local gui = Instance.new("ScreenGui")
  gui.Name = "ImporterHub"
  gui.ResetOnSpawn = false
  gui.IgnoreGuiInset = true
  gui.DisplayOrder = 999
  gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
  gui.Parent = CoreDest

  local C = {
    bg = Color3.fromRGB(4, 4, 6),
    card = Color3.fromRGB(12, 12, 15),
    card2 = Color3.fromRGB(26, 26, 31),
    white = Color3.fromRGB(255, 255, 255),
    sub = Color3.fromRGB(214, 214, 220),
    faint = Color3.fromRGB(132, 132, 142),
    cyan = Color3.fromRGB(230, 232, 240),
    purple = Color3.fromRGB(58, 60, 70),
    pink = Color3.fromRGB(150, 154, 166),
    ok = Color3.fromRGB(70, 244, 176),
    warn = Color3.fromRGB(255, 216, 70),
    danger = Color3.fromRGB(255, 122, 122),
  }

  local UI_SCALE = 0.95
  local GLASS_BLUR = true
  local BLUR_SIZE = 8

  local function mk(class, props, parent)
    local o = Instance.new(class)

    for k, v in pairs(props) do
      o[k] = v
    end

    if parent then
      o.Parent = parent
    end

    return o
  end

  local function round(o, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 10)
    c.Parent = o

    return c
  end

  local function stroke(o, col, thick, trans)
    local s = Instance.new("UIStroke")
    s.Color = col or C.white
    s.Thickness = thick or 1

    local t = trans == nil and 0 or trans

    if (col or C.white) == C.white and t >= 0.5 then
      t = t - 0.25
    end

    s.Transparency = t
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = o

    return s
  end

  local function gradient(o, colors, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(colors)
    g.Rotation = rot or 0
    g.Parent = o

    return g
  end

  local function padding(o, t, b, l, r)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, t or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.PaddingLeft = UDim.new(0, l or 0)
    p.PaddingRight = UDim.new(0, r or 0)
    p.Parent = o

    return p
  end

  local function label(parent, props)
    local d = {
      BackgroundTransparency = 1,
      TextColor3 = C.white,
      Font = Enum.Font.GothamBold,
      TextSize = 12,
      TextXAlignment = Enum.TextXAlignment.Left,
      ZIndex = 15,
    }

    for k, v in pairs(props) do
      d[k] = v
    end

    return mk("TextLabel", d, parent)
  end

  local function gradBtn(btn, text, textSize, radius)
    btn.Text = ""
    btn.BackgroundTransparency = 1

    local bg = mk("Frame", {
      Name = "GBg", Active = false,
      Size = UDim2.fromScale(1, 1),
      BackgroundColor3 = C.white,
      BorderSizePixel = 0,
      ZIndex = btn.ZIndex,
    }, btn)

    round(bg, radius or 10)

    gradient(bg, {
      ColorSequenceKeypoint.new(0, Color3.fromRGB(86, 88, 100)),
      ColorSequenceKeypoint.new(1, Color3.fromRGB(38, 39, 46)),
    }, 0)

    return label(btn, {
      Name = "GTxt", Active = false,
      Size = UDim2.fromScale(1, 1),
      Text = text,
      TextSize = textSize or 12,
      Font = Enum.Font.GothamBlack,
      TextXAlignment = Enum.TextXAlignment.Center,
      ZIndex = btn.ZIndex + 1,
    })
  end

  local GLOW_IMG = "rbxassetid://6014261993"

  local function glass(o, shine)
    local g = Instance.new("UIGradient")
    g.Name = "GlassTint"

    g.Color = ColorSequence.new({
      ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
      ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 206)),
    })

    g.Rotation = 90
    g.Parent = o

    mk("Frame", {
      Name = "Shine",
      Size = UDim2.new(1, -24, 0, 1),
      Position = UDim2.fromOffset(12, 1),
      BackgroundColor3 = Color3.fromRGB(255, 255, 255),
      BackgroundTransparency = shine or 0.4,
      BorderSizePixel = 0,
      ZIndex = o.ZIndex + 1,
    }, o)

    return g
  end

  local launcher = mk("TextButton", {
    Name = "ImporterHubToggle",
    Size = UDim2.fromOffset(46, 46),
    Position = UDim2.new(0, 10, 0.5, -23),
    BackgroundColor3 = C.card,
    BackgroundTransparency = 0.3,
    BorderSizePixel = 0,
    AutoButtonColor = false,
    Text = "",
    ZIndex = 100000,
  }, gui)

  round(launcher, 20)
  local launcherStroke = stroke(launcher, C.cyan, 2, 0.15)
  glass(launcher, 1)

  TweenService:Create(launcherStroke, TweenInfo.new(
    1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true
  ), { Transparency = 0.7 }):Play()

  local launcherIcon = mk("ImageLabel", {
    Name = "Icon",
    Size = UDim2.fromOffset(22, 22),
    Position = UDim2.new(0.5, -11, 0.5, -11),
    BackgroundTransparency = 1,
    Image = "rbxassetid://116910178994061",
    ImageColor3 = C.white,
    ScaleType = Enum.ScaleType.Fit,
    ZIndex = 7,
  }, launcher)

  local launcherFallback = mk("TextLabel", {
    Name = "FB",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text = "»",
    TextColor3 = C.white,
    Font = Enum.Font.GothamBlack,
    TextSize = 22,
    ZIndex = 6,
  }, launcher)

  local MIN_W, MIN_H = 440, 290
  local MAX_W, MAX_H = 900, 620
  local DEF_W, DEF_H = 580, 350

  do
    local cam = workspace.CurrentCamera

    if cam then
      local vp = cam.ViewportSize

      UI_SCALE = math.clamp(
        math.min(UI_SCALE, (vp.X - 24) / MIN_W, (vp.Y - 24) / MIN_H), 0.6, UI_SCALE
      )

      DEF_W = math.min(DEF_W, math.max(MIN_W, (vp.X - 24) / UI_SCALE))
      DEF_H = math.min(DEF_H, math.max(MIN_H, (vp.Y - 24) / UI_SCALE))
    end
  end

  local main = mk("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(DEF_W, DEF_H),
    Position = UDim2.new(0.5, -DEF_W * UI_SCALE / 2, 0.5, -DEF_H * UI_SCALE / 2),
    BackgroundColor3 = C.bg,
    BackgroundTransparency = 0.08,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    ZIndex = 10,
  }, gui)

  round(main, 26)
  local mainStroke = stroke(main, C.white, 1.8, 0.2)

  local mainStrokeGrad = Instance.new("UIGradient")

  mainStrokeGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, C.cyan), ColorSequenceKeypoint.new(0.33, C.purple),
    ColorSequenceKeypoint.new(0.66, C.pink), ColorSequenceKeypoint.new(1, C.cyan),
  })

  mainStrokeGrad.Parent = mainStroke

  TweenService:Create(
    mainStrokeGrad, TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
    { Rotation = 360 }
  ):Play()

  gradient(main, {
    ColorSequenceKeypoint.new(0, Color3.fromRGB(14, 14, 18)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(2, 2, 4)),
  }, 120)

  local mainScale = mk("UIScale", { Scale = UI_SCALE }, main)

  do
    local sheen = mk("Frame", {
      Name = "Sheen",
      Size = UDim2.new(1, 0, 0, 160),
      BackgroundColor3 = Color3.fromRGB(255, 255, 255),
      BorderSizePixel = 0,
      ZIndex = 11,
    }, main)

    local sg = Instance.new("UIGradient")
    sg.Rotation = 90

    sg.Transparency = NumberSequence.new({
      NumberSequenceKeypoint.new(0, 0.93), NumberSequenceKeypoint.new(1, 1),
    })

    sg.Parent = sheen

    round(sheen, 26)
  end

  local glowPad = 30

  local mainGlow = mk("ImageLabel", {
    Name = "MainGlow",
    BackgroundTransparency = 1,
    Image = GLOW_IMG,
    ImageColor3 = C.white,
    ImageTransparency = 0.72,
    ScaleType = Enum.ScaleType.Slice,
    SliceCenter = Rect.new(49, 49, 450, 450),
    ZIndex = 9,
  }, gui)

  round(mainGlow, 36)
  local glowScale = mk("UIScale", { Scale = UI_SCALE }, mainGlow)

  local function syncGlow()
    local p, s, sc = main.Position, main.Size, mainScale.Scale
    glowScale.Scale = sc

    mainGlow.Size = UDim2.new(
      s.X.Scale, s.X.Offset + glowPad * 2, s.Y.Scale, s.Y.Offset + glowPad * 2
    )

    mainGlow.Position = UDim2.new(
      p.X.Scale, p.X.Offset - glowPad * sc, p.Y.Scale, p.Y.Offset - glowPad * sc
    )

    mainGlow.Visible = main.Visible
  end

  syncGlow()

  for _, prop in ipairs({ "Position", "Size", "Visible" }) do
    main:GetPropertyChangedSignal(prop):Connect(syncGlow)
  end

  mainScale:GetPropertyChangedSignal("Scale"):Connect(syncGlow)

  TweenService:Create(mainGlow, TweenInfo.new(
    4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true
  ), { ImageColor3 = C.cyan }):Play()

  local glassBlur

  if GLASS_BLUR then
    pcall(function()
      local Lighting = game:GetService("Lighting")
      local oldB = Lighting:FindFirstChild("XyureiGlassBlur")

      if oldB then
        oldB:Destroy()
      end

      glassBlur = Instance.new("BlurEffect")
      glassBlur.Name = "XyureiGlassBlur"
      glassBlur.Size = 0
      glassBlur.Parent = Lighting

      TweenService:Create(glassBlur, TweenInfo.new(0.5), { Size = BLUR_SIZE }):Play()
    end)
  end

  local function setBlur(sz)
    if glassBlur and glassBlur.Parent then
      TweenService:Create(glassBlur, TweenInfo.new(0.25), { Size = sz }):Play()
    end
  end

  gui.Destroying:Connect(function()
    if glassBlur then
      pcall(function() glassBlur:Destroy() end)
    end
  end)

  do
    local scan = mk("Frame", {
      Name = "ScanLine",
      Size = UDim2.new(1, 0, 0, 2),
      Position = UDim2.new(0, 0, 0, 0),
      BackgroundColor3 = C.cyan,
      BackgroundTransparency = 0.5,
      BorderSizePixel = 0,
      ZIndex = 11,
    }, main)

    local sgr = Instance.new("UIGradient")

    sgr.Transparency = NumberSequence.new({
      NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0),
      NumberSequenceKeypoint.new(1, 1),
    })

    sgr.Parent = scan

    TweenService:Create(
      scan, TweenInfo.new(5.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1),
      { Position = UDim2.new(0, 0, 1, -2) }
    ):Play()

    for i = 1, 16 do
      local sz = math.random(2, 4)

      local p = mk("Frame", {
        Name = "Particle",
        Size = UDim2.fromOffset(sz, sz),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = i % 3 == 0 and C.white or C.cyan,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 11,
      }, main)

      round(p, sz)

      task.spawn(function()
        task.wait(math.random() * 6)

        while p.Parent do
          local x = 0.08 + math.random() * 0.84
          local dur = 6 + math.random() * 6

          p.Position = UDim2.new(x, 0, 1.02, 0)
          p.BackgroundTransparency = 1

          TweenService:Create(p, TweenInfo.new(dur, Enum.EasingStyle.Linear), {
            Position = UDim2.new(x + (math.random() - 0.5) * 0.1, 0, -0.02, 0),
          }):Play()

          TweenService:Create(p, TweenInfo.new(dur * 0.2), { BackgroundTransparency = 0.35 }):Play()

          task.wait(dur * 0.8)
          TweenService:Create(p, TweenInfo.new(dur * 0.2), { BackgroundTransparency = 1 }):Play()
          task.wait(dur * 0.2)
        end
      end)
    end
  end

  local header = mk("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 46),
    BackgroundTransparency = 1,
    ZIndex = 12,
  }, main)

  local headerLine = mk("Frame", {
    Size = UDim2.new(1, -28, 0, 1),
    Position = UDim2.new(0, 14, 1, -1),
    BackgroundColor3 = C.cyan,
    BackgroundTransparency = 0.7,
    BorderSizePixel = 0,
    ZIndex = 12,
  }, header)

  do
    local hg = Instance.new("UIGradient")

    hg.Transparency = NumberSequence.new({
      NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0),
      NumberSequenceKeypoint.new(1, 1),
    })

    hg.Parent = headerLine

    TweenService:Create(headerLine, TweenInfo.new(
      1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true
    ), { BackgroundTransparency = 0.25 }):Play()
  end

  local headerIcon = mk("ImageLabel", {
    Name = "HeaderIcon",
    Size = UDim2.fromOffset(28, 28),
    Position = UDim2.fromOffset(14, 9),
    BackgroundTransparency = 1,
    Image = "rbxassetid://116910178994061",
    ScaleType = Enum.ScaleType.Fit,
    ZIndex = 14,
  }, header)

  local backBtn = mk("TextButton", {
    Name = "Back",
    Size = UDim2.fromOffset(28, 28),
    Position = UDim2.fromOffset(14, 9),
    BackgroundColor3 = C.card,
    BackgroundTransparency = 0.38,
    Text = "‹",
    TextColor3 = C.white,
    Font = Enum.Font.GothamBlack,
    TextSize = 18,
    AutoButtonColor = false,
    Visible = false,
    ZIndex = 15,
  }, header)

  round(backBtn, 12)
  stroke(backBtn, C.white, 1, 0.8)

  local pageTitle = label(header, {
    Name = "PageTitle",
    Size = UDim2.new(1, -140, 0, 20),
    Position = UDim2.fromOffset(48, 5),
    Text = "TOOLS ENGINE MCP STUDIOLITE",
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextTruncate = Enum.TextTruncate.AtEnd,
  })

  local brandSub = label(header, {
    Name = "BrandSub",
    Size = UDim2.new(1, -140, 0, 12),
    Position = UDim2.fromOffset(48, 26),
    Text = "IMPORT · TOOLBOX · AI · UPLOAD",
    TextColor3 = C.cyan,
    TextSize = 8,
    TextTruncate = Enum.TextTruncate.AtEnd,
  })

  local minBtn = mk("TextButton", {
    Name = "Minimize",
    Size = UDim2.fromOffset(24, 24),
    Position = UDim2.new(1, -60, 0, 11),
    BackgroundColor3 = C.card,
    BackgroundTransparency = 0.38,
    Text = "–",
    TextColor3 = C.sub,
    Font = Enum.Font.GothamBold,
    TextSize = 15,
    AutoButtonColor = false,
    ZIndex = 15,
  }, header)

  round(minBtn, 8)
  stroke(minBtn, C.white, 1, 0.85)

  local closeBtn = mk("TextButton", {
    Name = "Close",
    Size = UDim2.fromOffset(24, 24),
    Position = UDim2.new(1, -32, 0, 11),
    BackgroundColor3 = Color3.fromRGB(36, 36, 44),
    BackgroundTransparency = 0.3,
    Text = "×",
    TextColor3 = Color3.fromRGB(235, 235, 242),
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    AutoButtonColor = false,
    ZIndex = 15,
  }, header)

  round(closeBtn, 8)
  stroke(closeBtn, Color3.fromRGB(235, 235, 242), 1.2, 0.35)

  local content = mk("Frame", {
    Name = "Content",
    Size = UDim2.new(1, -24, 1, -96),
    Position = UDim2.fromOffset(12, 52),
    BackgroundTransparency = 1,
    ZIndex = 12,
  }, main)

  local function newScroll(name)
    return mk("ScrollingFrame", {
      Name = name,
      Size = UDim2.fromScale(1, 1),
      BackgroundTransparency = 1,
      BorderSizePixel = 0,
      ScrollBarThickness = 4,
      ScrollBarImageColor3 = C.white,
      ScrollBarImageTransparency = 0.35,
      AutomaticCanvasSize = Enum.AutomaticSize.Y,
      CanvasSize = UDim2.new(),
      ZIndex = 12,
    }, content)
  end

  local totalLbl

  local landing = newScroll("Page_Landing")
  landing.ScrollBarThickness = 0
  landing.AutomaticCanvasSize = Enum.AutomaticSize.None
  landing.CanvasSize = UDim2.new()
  landing.ScrollingEnabled = false

  local betaPill = mk("Frame", {
    Name = "Beta",
    Size = UDim2.fromOffset(132, 20),
    Position = UDim2.fromOffset(2, 2),
    BackgroundColor3 = C.card,
    BackgroundTransparency = 0.15,
    BorderSizePixel = 0,
    ZIndex = 14,
  }, landing)

  round(betaPill, 10)
  stroke(betaPill, C.cyan, 1, 0.7)

  local betaDot = mk("Frame", {
    Size = UDim2.fromOffset(6, 6),
    Position = UDim2.new(0, 9, 0.5, -3),
    BackgroundColor3 = C.ok,
    BorderSizePixel = 0,
    ZIndex = 15,
  }, betaPill)

  round(betaDot, 3)

  TweenService:Create(betaDot, TweenInfo.new(
    0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true
  ), { BackgroundTransparency = 0.75 }):Play()

  label(betaPill, {
    Size = UDim2.new(1, -24, 1, 0),
    Position = UDim2.fromOffset(22, 0),
    Text = "Now in Public Beta",
    TextColor3 = C.sub,
    TextSize = 10,
    Font = Enum.Font.GothamMedium,
  })

  label(landing, {
    Name = "Headline",
    Size = UDim2.new(0.68, 0, 0, 88),
    Position = UDim2.fromOffset(2, 30),
    RichText = true,
    Text = [[
ENGINE TOOLS
<font color="rgb(120,150,255)">DESKTOP</font> FOR MOBILE]],
    Font = Enum.Font.GothamBlack,
    TextSize = 24,
    LineHeight = 0.95,
    TextYAlignment = Enum.TextYAlignment.Top,
  })

  label(landing, {
    Name = "Sub",
    Size = UDim2.new(0.5, 0, 0, 30),
    Position = UDim2.fromOffset(2, 124),
    TextWrapped = true,
    Text = "Pilih file RBXM, RBXL, RBXLX & RBXMX, langsung masuk ke game. Cepat & siap pakai.",
    TextColor3 = C.faint,
    Font = Enum.Font.GothamMedium,
    TextSize = 10,
    TextYAlignment = Enum.TextYAlignment.Top,
  })

  local exploreBtn = mk("TextButton", {
    Name = "Explore",
    Size = UDim2.fromOffset(122, 32),
    Position = UDim2.fromOffset(2, 162),
    BackgroundColor3 = C.white,
    Text = "OPEN PANEL",
    TextColor3 = C.white,
    Font = Enum.Font.GothamBlack,
    TextSize = 12,
    AutoButtonColor = false,
    ZIndex = 14,
  }, landing)

  round(exploreBtn, 9)
  local exploreStroke = stroke(exploreBtn, C.cyan, 1.2, 0.45)

  TweenService:Create(exploreStroke, TweenInfo.new(
    1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true
  ), { Transparency = 0.9 }):Play()

  gradBtn(exploreBtn, "OPEN PANEL", 12, 9)

  local landingScan = mk("TextButton", {
    Name = "LandingScan",
    Size = UDim2.fromOffset(104, 32),
    Position = UDim2.fromOffset(132, 162),
    BackgroundColor3 = C.card,
    BackgroundTransparency = 0.25,
    Text = "SCAN FILE",
    TextColor3 = C.white,
    Font = Enum.Font.GothamMedium,
    TextSize = 11,
    AutoButtonColor = false,
    ZIndex = 14,
  }, landing)

  round(landingScan, 9)
  stroke(landingScan, C.white, 1, 0.85)

  do
    local row = mk("Frame", {
      Name = "Social",
      Size = UDim2.new(0.54, 0, 0, 26),
      Position = UDim2.fromOffset(2, 206),
      BackgroundTransparency = 1,
      ZIndex = 14,
    }, landing)

    local cols = {
      Color3.fromRGB(70, 72, 82), Color3.fromRGB(110, 112, 124), Color3.fromRGB(150, 153, 166),
    }

    for i = 1, 3 do
      local av = mk("Frame", {
        Size = UDim2.fromOffset(24, 24),
        Position = UDim2.fromOffset((i - 1) * 16, 1),
        BackgroundColor3 = cols[i],
        BorderSizePixel = 0,
        ZIndex = 14 + i,
      }, row)

      round(av, 12)
      stroke(av, C.bg, 1.5, 0)

      if i == 1 then
        local im = mk("ImageLabel", {
          Size = UDim2.fromScale(1, 1),
          BackgroundTransparency = 1,
          ZIndex = 20,
          Image = ("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150&filters=circular"):format(LocalPlayer.UserId),
        }, av)

        round(im, 12)
      end
    end

    totalLbl = label(row, {
      Size = UDim2.new(1, -62, 1, 0),
      Position = UDim2.fromOffset(60, 0),
      Text = "TOTAL 0",
      TextColor3 = C.sub,
      Font = Enum.Font.GothamMedium,
      TextSize = 9,
      TextTruncate = Enum.TextTruncate.AtEnd,
    })
  end

  local statNum = {}

  do
    local mock = mk("Frame", {
      Name = "Mock",
      Size = UDim2.new(0.43, 0, 1, 0),
      Position = UDim2.new(0.57, 0, 0, 0),
      BackgroundTransparency = 1,
      ZIndex = 13,
    }, landing)

    local pw = mk("Frame", {
      Name = "PromptWin",
      Size = UDim2.new(1, 0, 0, 66),
      Position = UDim2.fromOffset(0, 6),
      BackgroundColor3 = C.card,
      BackgroundTransparency = 0.12,
      BorderSizePixel = 0,
      ZIndex = 14,
    }, mock)

    round(pw, 10)
    stroke(pw, C.cyan, 1, 0.7)
    glass(pw)

    for i, col in ipairs({
      Color3.fromRGB(230, 230, 235), Color3.fromRGB(150, 150, 160), Color3.fromRGB(90, 90, 100),
    }) do
      local d = mk("Frame", {
        Size = UDim2.fromOffset(7, 7),
        Position = UDim2.fromOffset(8 + (i - 1) * 11, 8),
        BackgroundColor3 = col,
        BorderSizePixel = 0,
        ZIndex = 15,
      }, pw)

      round(d, 4)
    end

    label(pw, {
      Size = UDim2.new(1, -60, 0, 10),
      Position = UDim2.fromOffset(46, 7),
      Text = "engine scan",
      TextColor3 = C.faint,
      TextSize = 8,
      Font = Enum.Font.GothamMedium,
    })

    local ic = mk("Frame", {
      Size = UDim2.fromOffset(20, 20),
      Position = UDim2.fromOffset(8, 28),
      BackgroundColor3 = C.purple,
      BorderSizePixel = 0,
      ZIndex = 15,
    }, pw)

    round(ic, 6)

    label(ic, {
      Size = UDim2.fromScale(1, 1),
      Text = "⚡",
      TextSize = 10,
      TextXAlignment = Enum.TextXAlignment.Center,
      ZIndex = 16,
    })

    local typed = label(pw, {
      Size = UDim2.new(1, -40, 0, 30),
      Position = UDim2.fromOffset(34, 26),
      TextWrapped = true,
      Text = "scan workspace: *.rbxl *.rbxm ...",
      TextColor3 = C.white,
      Font = Enum.Font.Code,
      TextSize = 8,
      TextYAlignment = Enum.TextYAlignment.Top,
    })

    task.spawn(function()
      local on = true

      while typed.Parent do
        typed.Text = "scan workspace: *.rbxl *.rbxm ..." .. (on and "|" or "")
        on = not on
        task.wait(0.55)
      end
    end)

    local vw = mk("Frame", {
      Name = "PreviewWin",
      Size = UDim2.new(0.96, 0, 0, 142),
      Position = UDim2.new(0.04, 0, 0, 80),
      BackgroundColor3 = C.card,
      BackgroundTransparency = 0.12,
      BorderSizePixel = 0,
      ZIndex = 14,
    }, mock)

    round(vw, 10)
    stroke(vw, C.cyan, 1, 0.7)
    glass(vw)

    label(vw, {
      Size = UDim2.new(0.5, 0, 0, 10),
      Position = UDim2.fromOffset(8, 6),
      Text = "Preview",
      TextColor3 = C.faint,
      TextSize = 8,
      Font = Enum.Font.GothamMedium,
    })

    local live = mk("Frame", {
      Size = UDim2.fromOffset(34, 12),
      Position = UDim2.new(1, -42, 0, 5),
      BackgroundColor3 = Color3.fromRGB(40, 40, 48),
      BorderSizePixel = 0,
      ZIndex = 15,
    }, vw)

    round(live, 6)

    label(live, {
      Size = UDim2.fromScale(1, 1),
      Text = "● Live",
      TextColor3 = C.ok,
      TextSize = 7,
      TextXAlignment = Enum.TextXAlignment.Center,
      ZIndex = 16,
    })

    for i = 1, 5 do
      local d = mk("Frame", {
        Size = UDim2.fromOffset(10, 10),
        Position = UDim2.fromOffset(8, 24 + (i - 1) * 16),
        BackgroundColor3 = i == 1 and C.purple or C.card2,
        BorderSizePixel = 0,
        ZIndex = 15,
      }, vw)

      round(d, 5)
    end

    local tiles = mk("Frame", {
      Size = UDim2.new(1, -34, 0, 34),
      Position = UDim2.fromOffset(26, 22),
      BackgroundTransparency = 1,
      ZIndex = 15,
    }, vw)

    mk("UIGridLayout", {
      CellSize = UDim2.new(0.25, -3, 1, 0),
      CellPadding = UDim2.fromOffset(4, 0),
      SortOrder = Enum.SortOrder.LayoutOrder,
    }, tiles)

    local function statTile(key, caption, color, order)
      local t = mk("Frame", {
        BackgroundColor3 = C.card2,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        LayoutOrder = order,
        ZIndex = 16,
      }, tiles)

      round(t, 6)
      stroke(t, color, 1, 0.5)

      label(t, {
        Size = UDim2.new(1, -8, 0, 10),
        Position = UDim2.fromOffset(5, 3),
        Text = caption,
        TextColor3 = C.faint,
        TextSize = 7,
        ZIndex = 17,
      })

      statNum[key] = label(t, {
        Size = UDim2.new(1, -8, 0, 16),
        Position = UDim2.fromOffset(5, 15),
        Text = "0",
        TextColor3 = color,
        Font = Enum.Font.GothamBlack,
        TextSize = 13,
        ZIndex = 17,
      })
    end

    statTile("RBXL", "RBXL", C.purple, 1)
    statTile("RBXLX", "RBXLX", C.pink, 2)
    statTile("RBXM", "RBXM", C.cyan, 3)
    statTile("RBXMX", "RBXMX", Color3.fromRGB(225, 228, 236), 4)

    local barBox = mk("Frame", {
      Size = UDim2.new(1, -34, 0, 62),
      Position = UDim2.fromOffset(26, 62),
      BackgroundTransparency = 1,
      ZIndex = 15,
    }, vw)

    local bars = {}
    local hs = { 0.45, 0.7, 0.5, 0.9, 0.6, 0.8, 0.7, 1 }

    for i, h in ipairs(hs) do
      local b = mk("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Size = UDim2.new(0.1, 0, h, 0),
        Position = UDim2.new((i - 1) * 0.128, 0, 1, 0),
        BackgroundColor3 = C.purple,
        BorderSizePixel = 0,
        ZIndex = 16,
      }, barBox)

      round(b, 3)

      gradient(b, {
        ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 122, 134)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 31, 38)),
      }, 90)

      bars[i] = b
    end

    task.spawn(function()
      while barBox.Parent do
        task.wait(2.2)

        for _, b in ipairs(bars) do
          if b.Parent then
            TweenService:Create(b, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {
              Size = UDim2.new(0.1, 0, 0.3 + math.random() * 0.7, 0),
            }):Play()
          end
        end
      end
    end)

    local chip = mk("Frame", {
      AnchorPoint = Vector2.new(1, 1),
      Size = UDim2.fromOffset(74, 14),
      Position = UDim2.new(1, -6, 1, -6),
      BackgroundColor3 = C.bg,
      BackgroundTransparency = 0.1,
      BorderSizePixel = 0,
      ZIndex = 17,
    }, vw)

    round(chip, 7)
    stroke(chip, C.cyan, 1, 0.7)

    label(chip, {
      Size = UDim2.fromScale(1, 1),
      Text = "Scan 1.2s",
      TextColor3 = C.sub,
      TextSize = 7,
      TextXAlignment = Enum.TextXAlignment.Center,
      ZIndex = 18,
    })
  end

  local dash = mk("Frame", {
    Name = "Page_Dash",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Visible = false,
    ZIndex = 12,
  }, content)

  local dashBadges = {}
  local dashButtons = {}
  local navButtons = {}
  local navOpen = {}
  local dashStat = {}
  local dashBars = {}

  local dashGlyph = {
    TB = "TB",
    RBXM = "M",
    RBXL = "L",
    RBXLX = "LX",
    RBXMX = "MX",
    SPOOF = "SP",
    MUSIC = "MP",
    CHAT = "AI",
    BYPASS = "BP",
    IMAGE = "IM",
    ANIM = "AN",
    MODEL = "UP",
    IMG3D = "3D",
    REPLACE = "RP",
  }

  local side = mk("Frame", {
    Name = "Sidebar",
    Size = UDim2.new(0, 108, 1, 0),
    BackgroundColor3 = C.card,
    BackgroundTransparency = 0.2,
    BorderSizePixel = 0,
    ZIndex = 13,
  }, dash)

  round(side, 12)
  stroke(side, C.cyan, 1, 0.75)
  glass(side)

  do
    local lg = mk("Frame", {
      Size = UDim2.fromOffset(20, 20),
      Position = UDim2.fromOffset(10, 8),
      BackgroundColor3 = C.cyan,
      BorderSizePixel = 0,
      ZIndex = 14,
    }, side)

    round(lg, 10)

    gradient(lg, {
      ColorSequenceKeypoint.new(0, Color3.fromRGB(235, 237, 245)),
      ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 154, 166)),
    }, 45)

    label(lg, {
      Size = UDim2.fromScale(1, 1),
      Text = "X",
      TextSize = 10,
      Font = Enum.Font.GothamBlack,
      TextXAlignment = Enum.TextXAlignment.Center,
      ZIndex = 15,
    })

    label(side, {
      Size = UDim2.new(1, -40, 0, 20),
      Position = UDim2.fromOffset(36, 8),
      Text = "ENGINE",
      TextSize = 13,
      Font = Enum.Font.GothamBlack,
    })
  end

  local nav = mk("ScrollingFrame", {
    Name = "Nav",
    Size = UDim2.new(1, 0, 1, -34),
    Position = UDim2.fromOffset(0, 34),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 0,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.new(),
    ZIndex = 14,
  }, side)

  mk("UIListLayout", {
    Padding = UDim.new(0, 2),
    SortOrder = Enum.SortOrder.LayoutOrder,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
  }, nav)

  padding(nav, 0, 6, 0, 0)
  local navN = 0

  local function navCaption(text)
    navN = navN + 1

    label(nav, {
      Size = UDim2.new(1, -20, 0, 16),
      Text = text,
      TextColor3 = C.faint,
      TextSize = 8,
      LayoutOrder = navN,
      ZIndex = 15,
    })
  end

  local function navItem(text, glyph, key, active)
    navN = navN + 1

    local b = mk("TextButton", {
      Name = "Nav_" .. key,
      Size = UDim2.new(1, -12, 0, 22),
      BackgroundColor3 = active and C.white or C.purple,
      BackgroundTransparency = active and 0.05 or 1,
      Text = "",
      AutoButtonColor = false,
      LayoutOrder = navN,
      ZIndex = 15,
    }, nav)

    round(b, 8)

    if active then
      gradient(b, {
        ColorSequenceKeypoint.new(0, Color3.fromRGB(86, 88, 100)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(38, 39, 46)),
      }, 0)
    end

    label(b, {
      Size = UDim2.fromOffset(18, 22),
      Position = UDim2.fromOffset(6, 0),
      Text = glyph,
      TextSize = 10,
      TextColor3 = active and C.white or C.cyan,
      TextXAlignment = Enum.TextXAlignment.Center,
      ZIndex = 16,
    })

    label(b, {
      Size = UDim2.new(1, -28, 1, 0),
      Position = UDim2.fromOffset(26, 0),
      Text = text,
      TextSize = 9,
      Font = Enum.Font.GothamMedium,
      TextColor3 = active and C.white or C.sub,
      TextTruncate = Enum.TextTruncate.AtEnd,
      ZIndex = 16,
    })

    navButtons[key] = b

    if not active then
      b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), { BackgroundTransparency = 0.8 }):Play()
      end)

      b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {
          BackgroundTransparency = navOpen[key] and 0.15 or 1,
        }):Play()
      end)
    end
  end

  navCaption("MENU")

  navItem("Dashboard", "D", "dash", true)
  navItem("Toolbox", "+", "TB")
  navItem("Spoof & Bypass", "⚡", "SPOOF")
  navItem("Music", "M", "MUSIC")
  navItem("AI Chat", "AI", "CHAT")
  navItem("Bypass", "B", "BYPASS")

  navCaption("GENERAL")

  navItem("Upload Gambar", "I", "IMAGE")
  navItem("Upload Animasi", "A", "ANIM")
  navItem("Upload RBXM", "U", "MODEL")
  navItem("Image to 3D", "3", "IMG3D")
  navItem("Replace Tool", "R", "REPLACE")
  navItem("Beranda", "H", "landing")

  local mainArea = mk("Frame", {
    Name = "MainArea",
    Size = UDim2.new(1, -116, 1, 0),
    Position = UDim2.fromOffset(116, 0),
    BackgroundTransparency = 1,
    ZIndex = 13,
  }, dash)

  local topBar = mk(
    "Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, ZIndex = 14 },
    mainArea
  )

  local sBox = mk("Frame", {
    Size = UDim2.new(1, -112, 1, 0),
    BackgroundColor3 = C.card,
    BackgroundTransparency = 0.2,
    BorderSizePixel = 0,
    ZIndex = 14,
  }, topBar)

  round(sBox, 14)
  stroke(sBox, C.white, 1, 0.88)

  label(sBox, {
    Size = UDim2.fromOffset(18, 28),
    Position = UDim2.fromOffset(8, 0),
    Text = "Q",
    TextColor3 = C.faint,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Center,
    ZIndex = 15,
  })

  local dashSearch = mk("TextBox", {
    Name = "DashSearch",
    Size = UDim2.new(1, -34, 1, 0),
    Position = UDim2.fromOffset(28, 0),
    BackgroundTransparency = 1,
    PlaceholderText = "Cari fitur...",
    PlaceholderColor3 = C.faint,
    Text = "",
    TextColor3 = C.white,
    Font = Enum.Font.GothamMedium,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false,
    ZIndex = 15,
  }, sBox)

  local prof = mk("Frame", {
    Size = UDim2.fromOffset(104, 28),
    Position = UDim2.new(1, -104, 0, 0),
    BackgroundColor3 = C.card,
    BackgroundTransparency = 0.2,
    BorderSizePixel = 0,
    ZIndex = 14,
  }, topBar)

  round(prof, 14)
  stroke(prof, C.white, 1, 0.88)

  do
    local av = mk("ImageLabel", {
      Size = UDim2.fromOffset(22, 22),
      Position = UDim2.fromOffset(4, 3),
      BackgroundColor3 = C.card2,
      ZIndex = 15,
      Image = ("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150&filters=circular"):format(LocalPlayer.UserId),
    }, prof)

    round(av, 11)

    label(prof, {
      Size = UDim2.new(1, -32, 0, 12),
      Position = UDim2.fromOffset(30, 3),
      Text = tostring(LocalPlayer.DisplayName),
      TextSize = 8,
      TextTruncate = Enum.TextTruncate.AtEnd,
    })

    label(prof, {
      Size = UDim2.new(1, -32, 0, 10),
      Position = UDim2.fromOffset(30, 15),
      Text = "@" .. tostring(LocalPlayer.Name),
      TextSize = 7,
      TextColor3 = C.faint,
      Font = Enum.Font.GothamMedium,
      TextTruncate = Enum.TextTruncate.AtEnd,
    })
  end

  local dashScroll = mk("ScrollingFrame", {
    Name = "DashScroll",
    Size = UDim2.new(1, 0, 1, -34),
    Position = UDim2.fromOffset(0, 34),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = C.cyan,
    ScrollBarImageTransparency = 0.4,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.new(),
    ZIndex = 13,
  }, mainArea)

  mk(
    "UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder },
    dashScroll
  )

  padding(dashScroll, 0, 4, 0, 4)

  local titleRow = mk("Frame", {
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundTransparency = 1,
    LayoutOrder = 1,
    ZIndex = 14,
  }, dashScroll)

  label(titleRow, {
    Size = UDim2.new(1, 0, 0, 20),
    Text = "Dashboard",
    TextSize = 17,
    Font = Enum.Font.GothamBlack,
  })

  label(titleRow, {
    Size = UDim2.new(1, 0, 0, 12),
    Position = UDim2.fromOffset(0, 22),
    Text = "Import, kelola & jalankan semua tools dengan mudah.",
    TextSize = 8,
    TextColor3 = C.faint,
    Font = Enum.Font.GothamMedium,
    TextTruncate = Enum.TextTruncate.AtEnd,
  })

  local dashScanBtn = mk("TextButton", {
    Name = "DashScan",
    Size = UDim2.fromOffset(72, 22),
    Position = UDim2.new(1, -72, 0, 9),
    BackgroundColor3 = C.card,
    BackgroundTransparency = 0.2,
    Text = "Scan Ulang",
    TextColor3 = C.sub,
    Font = Enum.Font.GothamMedium,
    TextSize = 9,
    AutoButtonColor = false,
    ZIndex = 15,
  }, titleRow)

  round(dashScanBtn, 11)
  stroke(dashScanBtn, C.white, 1, 0.85)

  local statRow = mk("Frame", {
    Size = UDim2.new(1, 0, 0, 64),
    BackgroundTransparency = 1,
    LayoutOrder = 2,
    ZIndex = 14,
  }, dashScroll)

  mk("UIGridLayout", {
    CellSize = UDim2.new(0.25, -5, 1, 0),
    CellPadding = UDim2.fromOffset(6, 0),
    SortOrder = Enum.SortOrder.LayoutOrder,
  }, statRow)

  local function bigStat(key, title, cap, order, hot)
    local c = mk("Frame", {
      BackgroundColor3 = hot and C.white or C.card,
      BackgroundTransparency = hot and 0.05 or 0.18,
      BorderSizePixel = 0,
      LayoutOrder = order,
      ZIndex = 14,
    }, statRow)

    round(c, 11)
    stroke(c, hot and C.cyan or C.white, 1, hot and 0.4 or 0.88)

    if hot then
      gradient(c, {
        ColorSequenceKeypoint.new(0, Color3.fromRGB(86, 88, 100)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(38, 39, 46)),
      }, 135)
    end

    label(c, {
      Size = UDim2.new(1, -26, 0, 10),
      Position = UDim2.fromOffset(7, 6),
      Text = title,
      TextSize = 8,
      TextTruncate = Enum.TextTruncate.AtEnd,
      ZIndex = 15,
    })

    local ar = mk("Frame", {
      Size = UDim2.fromOffset(13, 13),
      Position = UDim2.new(1, -18, 0, 5),
      BackgroundColor3 = C.purple,
      BackgroundTransparency = hot and 0.3 or 0.1,
      BorderSizePixel = 0,
      ZIndex = 15,
    }, c)

    round(ar, 7)

    label(ar, {
      Size = UDim2.fromScale(1, 1),
      Text = ">",
      TextSize = 8,
      TextXAlignment = Enum.TextXAlignment.Center,
      ZIndex = 16,
    })

    dashStat[key] = label(c, {
      Size = UDim2.new(1, -12, 0, 22),
      Position = UDim2.fromOffset(7, 20),
      Text = "0",
      TextSize = 19,
      Font = Enum.Font.GothamBlack,
      ZIndex = 15,
    })

    label(c, {
      Size = UDim2.new(1, -12, 0, 10),
      Position = UDim2.fromOffset(7, 48),
      Text = cap,
      TextSize = 6,
      TextColor3 = hot and C.sub or C.faint,
      Font = Enum.Font.GothamMedium,
      TextTruncate = Enum.TextTruncate.AtEnd,
      ZIndex = 15,
    })
  end

  bigStat("total", "Total File", "Semua file terdeteksi", 1, true)
  bigStat("model", "Model", "RBXM + RBXMX", 2)
  bigStat("place", "Place", "RBXL + RBXLX", 3)
  bigStat("imported", "Diimpor", "Sudah masuk ke game", 4)

  local panelRow = mk("Frame", {
    Size = UDim2.new(1, 0, 0, 118),
    BackgroundTransparency = 1,
    LayoutOrder = 3,
    ZIndex = 14,
  }, dashScroll)

  local anCard = mk("Frame", {
    Size = UDim2.new(0.6, -4, 1, 0),
    BackgroundColor3 = C.card,
    BackgroundTransparency = 0.18,
    BorderSizePixel = 0,
    ZIndex = 14,
  }, panelRow)

  round(anCard, 12)
  stroke(anCard, C.white, 1, 0.88)

  label(anCard, {
    Size = UDim2.new(0.6, 0, 0, 14),
    Position = UDim2.fromOffset(10, 8),
    Text = "File Analytics",
    TextSize = 11,
    Font = Enum.Font.GothamBlack,
    ZIndex = 15,
  })

  label(anCard, {
    Size = UDim2.new(0.4, -10, 0, 12),
    Position = UDim2.new(0.6, 0, 0, 9),
    Text = "● Per tipe",
    TextSize = 7,
    TextColor3 = C.ok,
    TextXAlignment = Enum.TextXAlignment.Right,
    ZIndex = 15,
  })

  local chartBox = mk("Frame", {
    Size = UDim2.new(1, -20, 1, -50),
    Position = UDim2.fromOffset(10, 28),
    BackgroundTransparency = 1,
    ZIndex = 15,
  }, anCard)

  local axisBox = mk("Frame", {
    Size = UDim2.new(1, -20, 0, 12),
    Position = UDim2.new(0, 10, 1, -18),
    BackgroundTransparency = 1,
    ZIndex = 15,
  }, anCard)

  for i, ext in ipairs({ "RBXL", "RBXLX", "RBXM", "RBXMX" }) do
    local col = ({
      RBXL = C.purple,
      RBXLX = C.pink,
      RBXM = C.cyan,
      RBXMX = Color3.fromRGB(225, 228, 236),
    })[ext]

    local slot = mk("Frame", {
      Size = UDim2.new(0.25, -6, 1, 0),
      Position = UDim2.new((i - 1) * 0.25, 3, 0, 0),
      BackgroundTransparency = 1,
      ZIndex = 16,
    }, chartBox)

    local bar = mk("Frame", {
      AnchorPoint = Vector2.new(0.5, 1),
      Size = UDim2.new(0.7, 0, 0.08, 0),
      Position = UDim2.new(0.5, 0, 1, 0),
      BackgroundColor3 = col,
      BorderSizePixel = 0,
      ZIndex = 17,
    }, slot)

    round(bar, 5)

    gradient(bar, {
      ColorSequenceKeypoint.new(0, col),
      ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 24, 30)),
    }, 90)

    dashBars[ext] = bar

    label(axisBox, {
      Size = UDim2.new(0.25, -6, 1, 0),
      Position = UDim2.new((i - 1) * 0.25, 3, 0, 0),
      Text = ext,
      TextSize = 7,
      TextColor3 = C.faint,
      TextXAlignment = Enum.TextXAlignment.Center,
      ZIndex = 16,
    })
  end

  local remCard = mk("Frame", {
    Size = UDim2.new(0.4, -4, 1, 0),
    Position = UDim2.new(0.6, 4, 0, 0),
    BackgroundColor3 = C.card,
    BackgroundTransparency = 0.18,
    BorderSizePixel = 0,
    ZIndex = 14,
  }, panelRow)

  round(remCard, 12)
  stroke(remCard, C.white, 1, 0.88)

  label(remCard, {
    Size = UDim2.new(1, -16, 0, 14),
    Position = UDim2.fromOffset(10, 8),
    Text = "Quick Access",
    TextSize = 11,
    Font = Enum.Font.GothamBlack,
    ZIndex = 15,
  })

  local qa = mk("Frame", {
    Size = UDim2.new(1, -16, 0, 56),
    Position = UDim2.fromOffset(8, 30),
    BackgroundColor3 = C.bg,
    BackgroundTransparency = 0.35,
    BorderSizePixel = 0,
    ZIndex = 15,
  }, remCard)

  round(qa, 9)
  stroke(qa, C.cyan, 1, 0.75)

  label(qa, {
    Size = UDim2.new(1, -12, 0, 12),
    Position = UDim2.fromOffset(6, 5),
    Text = "Music Player",
    TextSize = 9,
    ZIndex = 16,
  })

  label(qa, {
    Size = UDim2.new(1, -12, 0, 10),
    Position = UDim2.fromOffset(6, 18),
    Text = "Putar lagu pakai ID audio",
    TextSize = 7,
    TextColor3 = C.faint,
    Font = Enum.Font.GothamMedium,
    TextTruncate = Enum.TextTruncate.AtEnd,
    ZIndex = 16,
  })

  local dashMusicBtn = mk("TextButton", {
    Name = "DashMusic",
    Size = UDim2.new(1, -12, 0, 18),
    Position = UDim2.fromOffset(6, 32),
    BackgroundColor3 = C.white,
    Text = "▶ Buka Music",
    TextColor3 = C.white,
    Font = Enum.Font.GothamBold,
    TextSize = 8,
    AutoButtonColor = false,
    ZIndex = 16,
  }, qa)

  round(dashMusicBtn, 9)
  gradBtn(dashMusicBtn, "Buka Music", 8, 9)

  label(remCard, {
    Size = UDim2.new(1, -16, 0, 14),
    Position = UDim2.new(0, 10, 1, -20),
    Text = "Toolbox · Chat · Upload di bawah",
    TextSize = 7,
    TextColor3 = C.faint,
    Font = Enum.Font.GothamMedium,
    TextTruncate = Enum.TextTruncate.AtEnd,
    ZIndex = 15,
  })

  local toolsPanel = mk("Frame", {
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundColor3 = C.card,
    BackgroundTransparency = 0.18,
    BorderSizePixel = 0,
    LayoutOrder = 4,
    ZIndex = 14,
  }, dashScroll)

  round(toolsPanel, 12)
  stroke(toolsPanel, C.white, 1, 0.88)
  padding(toolsPanel, 8, 8, 8, 8)

  mk(
    "UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder },
    toolsPanel
  )

  label(toolsPanel, {
    Size = UDim2.new(1, 0, 0, 14),
    Text = "Fitur & Tools",
    TextSize = 11,
    Font = Enum.Font.GothamBlack,
    LayoutOrder = 1,
    ZIndex = 15,
  })

  local gridHolder = mk("Frame", {
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    LayoutOrder = 2,
    ZIndex = 15,
  }, toolsPanel)

  local dashGrid = mk("UIGridLayout", {
    CellSize = UDim2.new(1 / 3, -4, 0, 46),
    CellPadding = UDim2.fromOffset(6, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
  }, gridHolder)

  local function dashCard(key, title, desc, color, order)
    local b = mk("TextButton", {
      Name = "Dash_" .. key,
      BackgroundColor3 = C.card2,
      BackgroundTransparency = 0.38,
      Text = "",
      AutoButtonColor = false,
      LayoutOrder = order,
      ClipsDescendants = true,
      ZIndex = 16,
    }, gridHolder)

    round(b, 10)
    stroke(b, color, 1.2, 0.5)
    mk("UIScale", { Scale = 1 }, b)

    local icon = mk("Frame", {
      Size = UDim2.fromOffset(28, 28),
      Position = UDim2.fromOffset(7, 9),
      BackgroundColor3 = color,
      BackgroundTransparency = 0.7,
      BorderSizePixel = 0,
      ZIndex = 17,
    }, b)

    round(icon, 8)
    stroke(icon, color, 1, 0.55)

    label(icon, {
      Size = UDim2.fromScale(1, 1),
      Text = dashGlyph[key] or "?",
      TextColor3 = color,
      Font = Enum.Font.GothamBlack,
      TextSize = 10,
      TextXAlignment = Enum.TextXAlignment.Center,
      ZIndex = 18,
    })

    local badge = label(b, {
      Size = UDim2.fromOffset(34, 14),
      Position = UDim2.new(1, -38, 0, 4),
      Text = "",
      TextColor3 = color,
      Font = Enum.Font.GothamBlack,
      TextSize = 8,
      TextXAlignment = Enum.TextXAlignment.Center,
      BackgroundTransparency = 0.25,
      BackgroundColor3 = C.bg,
      ZIndex = 17,
    })

    round(badge, 7)
    badge.Visible = false

    label(b, {
      Size = UDim2.new(1, -46, 0, 13),
      Position = UDim2.fromOffset(40, 8),
      Text = title,
      TextSize = 9,
      Font = Enum.Font.GothamBlack,
      TextTruncate = Enum.TextTruncate.AtEnd,
      ZIndex = 17,
    })

    label(b, {
      Size = UDim2.new(1, -46, 0, 22),
      Position = UDim2.fromOffset(40, 21),
      Text = desc,
      TextColor3 = C.faint,
      Font = Enum.Font.GothamMedium,
      TextSize = 7,
      TextWrapped = true,
      TextYAlignment = Enum.TextYAlignment.Top,
      ZIndex = 17,
    })

    dashBadges[key] = badge
    dashButtons[key] = b
    return b
  end

  dashCard("TB", "Toolbox", "Cari & import Model, Mesh, Decal, Audio", C.cyan, 1)
  dashCard("RBXM", "Import RBXM", "Model binary (.rbxm)", C.cyan, 2)
  dashCard("RBXL", "Import RBXL", "Place binary (.rbxl)", C.purple, 3)
  dashCard("RBXLX", "Import RBXLX", "Place XML (.rbxlx)", C.pink, 4)
  dashCard("RBXMX", "Import RBXMX", "Model XML (.rbxmx)", Color3.fromRGB(225, 228, 236), 5)

  dashCard(
    "MUSIC", "Music Player", "Putar lagu pakai ID audio Roblox", Color3.fromRGB(210, 212, 222),
    6
  )

  dashCard(
    "CHAT", "AI Chat", "Ngobrol dengan AI via OpenRouter", Color3.fromRGB(190, 192, 202), 7
  )

  dashCard(
    "SPOOF", "Spoofer & Bypass", "Ultra-Fast 60FPS · Auto Place ID Bypass", Color3.fromRGB(245, 175, 45), 5
  )
  dashCard(
    "BYPASS", "Bypass Music", "Upload mp3/ogg/wav + atur pitch/speed",
    Color3.fromRGB(235, 236, 242), 8
  )

  dashCard(
    "IMAGE", "Upload Image", "Upload gambar ke Roblox (Decal)", Color3.fromRGB(220, 222, 230), 9
  )

  dashCard(
    "ANIM", "Upload Animasi", "MAINTENANCE · ditutup sementara", Color3.fromRGB(200, 202, 212),
    10
  )

  dashCard(
    "MODEL", "Upload RBXM", "Upload model .rbxm/.rbxmx jadi Asset ID",
    Color3.fromRGB(235, 236, 242), 11
  )

  dashCard(
    "IMG3D", "Image to 3D", "Gambar ID/file jadi model part 3D", Color3.fromRGB(240, 242, 248),
    12
  )

  dashCard(
    "REPLACE", "Replace Tool", "Ganti warna, material & model/part sekaligus",
    Color3.fromRGB(228, 230, 238), 13
  )

  dashSearch:GetPropertyChangedSignal("Text"):Connect(function()
    local q = dashSearch.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")

    for key, b in pairs(dashButtons) do
      local hay = (key .. " " .. (b.Name or "")):lower()

      for _, d in ipairs(b:GetDescendants()) do
        if d:IsA("TextLabel") and d.Text ~= "" then
          hay = hay .. " " .. d.Text:lower()
        end
      end

      b.Visible = q == "" or hay:find(q, 1, true) ~= nil
    end
  end)

  local function buildImportPage(ext, emptyText)
    local frame = mk("Frame", {
      Name = "Page_" .. ext,
      Size = UDim2.fromScale(1, 1),
      BackgroundTransparency = 1,
      Visible = false,
      ZIndex = 12,
    }, content)

    local tool = mk(
      "Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, ZIndex = 13 }, frame
    )

    local sw = mk("Frame", {
      Size = UDim2.new(1, -98, 1, 0),
      BackgroundColor3 = C.card,
      BackgroundTransparency = 0.38,
      BorderSizePixel = 0,
      ZIndex = 14,
    }, tool)

    round(sw, 11)
    stroke(sw, C.white, 1, 0.85)
    glass(sw)

    local box = mk("TextBox", {
      Name = "Search",
      Size = UDim2.new(1, -20, 1, 0),
      Position = UDim2.fromOffset(12, 0),
      BackgroundTransparency = 1,
      PlaceholderText = "Cari file " .. ext:lower() .. "...",
      PlaceholderColor3 = C.faint,
      Text = "",
      TextColor3 = C.white,
      Font = Enum.Font.GothamMedium,
      TextSize = 12,
      TextXAlignment = Enum.TextXAlignment.Left,
      ClearTextOnFocus = false,
      ZIndex = 15,
    }, sw)

    local scan = mk("TextButton", {
      Name = "Scan",
      Size = UDim2.fromOffset(88, 40),
      Position = UDim2.new(1, -88, 0, 0),
      BackgroundColor3 = C.purple,
      Text = "SCAN",
      TextColor3 = C.white,
      Font = Enum.Font.GothamBlack,
      TextSize = 12,
      AutoButtonColor = false,
      ZIndex = 14,
    }, tool)

    round(scan, 10)
    stroke(scan, C.white, 1, 0.7)

    local list = mk("ScrollingFrame", {
      Name = "FileList",
      Size = UDim2.new(1, 0, 1, -50),
      Position = UDim2.fromOffset(0, 50),
      BackgroundColor3 = C.card,
      BackgroundTransparency = 0.55,
      BorderSizePixel = 0,
      ScrollBarThickness = 4,
      ScrollBarImageColor3 = C.white,
      ScrollBarImageTransparency = 0.35,
      AutomaticCanvasSize = Enum.AutomaticSize.Y,
      CanvasSize = UDim2.new(),
      ZIndex = 13,
    }, frame)

    round(list, 12)
    stroke(list, C.white, 1, 0.88)
    padding(list, 8, 8, 8, 8)

    mk(
      "UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, list
    )

    local empty = label(list, {
      Name = "Empty",
      Size = UDim2.new(1, -16, 0, 100),
      Text = emptyText,
      TextColor3 = C.faint,
      TextWrapped = true,
      TextXAlignment = Enum.TextXAlignment.Center,
      ZIndex = 14,
    })

    return {
      frame = frame,
      list = list,
      empty = empty,
      search = box,
      scan = scan,
      emptyText = emptyText,
    }
  end

  local pageOf = {
    RBXM = buildImportPage("RBXM", [[
BELUM ADA FILE .RBXM

TEKAN SCAN]]),
    RBXL = buildImportPage("RBXL", [[
BELUM ADA FILE .RBXL

TEKAN SCAN]]),
    RBXLX = buildImportPage("RBXLX", [[
BELUM ADA FILE .RBXLX

TEKAN SCAN]]),
    RBXMX = buildImportPage("RBXMX", [[
BELUM ADA FILE .RBXMX

TEKAN SCAN]]),
  }

  local importProgressTrack = mk("Frame", {
    Name = "Track",
    Size = UDim2.new(1, -24, 0, 3),
    Position = UDim2.new(0, 12, 1, -42),
    BackgroundColor3 = C.card2,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 12,
  }, main)

  round(importProgressTrack, 2)

  local importProgressFill = mk("Frame", {
    Size = UDim2.new(0, 0, 1, 0),
    BackgroundColor3 = C.cyan,
    BorderSizePixel = 0,
    ZIndex = 13,
  }, importProgressTrack)

  round(importProgressFill, 2)

  gradient(importProgressFill, {
    ColorSequenceKeypoint.new(0, C.cyan), ColorSequenceKeypoint.new(0.5, C.purple),
    ColorSequenceKeypoint.new(1, C.pink),
  }, 0)

  local footer = mk("Frame", {
    Name = "Footer",
    Size = UDim2.new(1, -24, 0, 28),
    Position = UDim2.new(0, 12, 1, -36),
    BackgroundColor3 = C.card,
    BackgroundTransparency = 0.45,
    BorderSizePixel = 0,
    ZIndex = 12,
  }, main)

  round(footer, 12)
  stroke(footer, C.white, 1, 0.85)
  glass(footer)

  local statusDot = mk("Frame", {
    Size = UDim2.fromOffset(8, 8),
    Position = UDim2.new(0, 14, 0.5, -4),
    BackgroundColor3 = C.ok,
    BorderSizePixel = 0,
    ZIndex = 14,
  }, footer)

  round(statusDot, 4)

  local statusText = label(footer, {
    Size = UDim2.new(1, -110, 1, 0),
    Position = UDim2.fromOffset(30, 0),
    Text = "SIAP",
    TextColor3 = C.sub,
    TextSize = 10,
    TextTruncate = Enum.TextTruncate.AtEnd,
    ZIndex = 14,
  })

  local importProgressPct = label(footer, {
    Size = UDim2.fromOffset(56, 28),
    Position = UDim2.new(1, -92, 0, 0),
    Text = "",
    TextColor3 = C.cyan,
    Font = Enum.Font.GothamBlack,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Right,
    ZIndex = 14,
  })

  local resizeGrip = mk("TextButton", {
    Name = "ResizeGrip",
    Size = UDim2.fromOffset(20, 20),
    Position = UDim2.new(1, -24, 1, -24),
    BackgroundTransparency = 1,
    Text = "",
    AutoButtonColor = false,
    ZIndex = 45,
  }, main)

  for _, off in ipairs({ 6, 10, 14 }) do
    mk("Frame", {
      Size = UDim2.fromOffset(2, 8),
      Position = UDim2.fromOffset(off, 8),
      Rotation = 45,
      BackgroundColor3 = C.white,
      BackgroundTransparency = 0.5,
      BorderSizePixel = 0,
      ZIndex = 46,
    }, resizeGrip)
  end

  local allCards = {}

  local counts = {
    RBXM = 0,
    RBXMX = 0,
    RBXL = 0,
    RBXLX = 0,
  }

  local importedCount = 0
  local mainVisible = true
  local expandedPosition = main.Position
  local currentPage = "landing"
  local WS = {}
  local windowsToggle
  local pages = { landing = landing, dash = dash, TB = nil }

  for k, pg in pairs(pageOf) do
    pages[k] = pg.frame
  end

  local titles = {
    landing = "TOOLS ENGINE MCP STUDIOLITE",
    dash = "Dashboard",
    TB = "Toolbox",
    SPOOF = "Spoof & Bypass Hub",
    MUSIC = "Music Player",
    CHAT = "AI Chat",
    RBXM = "Import RBXM",
    RBXL = "Import RBXL",
    RBXLX = "Import RBXLX",
    RBXMX = "Import RBXMX",
    IMAGE = "Upload Image",
    ANIM = "Upload Animasi",
    IMG3D = "Image to 3D",
    REPLACE = "Replace Tool",
  }

  local function showPage(key)
    currentPage = key

    for k, f in pairs(pages) do
      if f then
        f.Visible = k == key
      end
    end

    pageTitle.Text = titles[key] or "TOOLS ENGINE MCP STUDIOLITE"
    backBtn.Visible = key ~= "landing"
    headerIcon.Visible = key == "landing"
    local tx = 48
    pageTitle.Position = UDim2.fromOffset(tx, 5)
    brandSub.Position = UDim2.fromOffset(tx, 26)
    brandSub.Text = key == "landing" and "IMPORT · TOOLBOX · AI · UPLOAD" or "TOOLS ENGINE MCP STUDIOLITE"

    if WS.pageFx then
      WS.pageFx(key)
    end
  end

  local function updateCount()
    local total = 0

    for ext, n in pairs(counts) do
      total = total + n

      if statNum[ext] then
        statNum[ext].Text = tostring(n)
      end

      local b = dashBadges[ext]

      if b then
        b.Text = tostring(n)
        b.Visible = true
      end
    end

    totalLbl.Text = ("TOTAL %d · DIIMPOR %d"):format(total, importedCount)

    dashStat.total.Text = tostring(total)
    dashStat.model.Text = tostring((counts.RBXM or 0) + (counts.RBXMX or 0))
    dashStat.place.Text = tostring((counts.RBXL or 0) + (counts.RBXLX or 0))
    dashStat.imported.Text = tostring(importedCount)

    local mx = 1

    for _, n in pairs(counts) do
      mx = math.max(mx, n)
    end

    for ext, bar in pairs(dashBars) do
      TweenService:Create(bar, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {
        Size = UDim2.new(0.7, 0, math.max(0.08, (counts[ext] or 0) / mx), 0),
      }):Play()
    end
  end

  local function setStatus(text, color)
    statusText.Text = tostring(text)
    statusDot.BackgroundColor3 = color or C.purple
  end

  local function setImportProgress(value, message)
    value = math.clamp(tonumber(value) or 0, 0, 1)
    importProgressTrack.Visible = value > 0
    importProgressFill.Size = UDim2.new(value, 0, 1, 0)
    importProgressPct.Text = ("%d%%"):format(math.floor(value * 100 + 0.5))

    if message and message ~= "" then
      statusText.Text = tostring(message)
    end

    if value >= 1 then
      task.delay(2, function()
        if importProgressTrack and importProgressTrack.Parent then
          importProgressTrack.Visible = false
          importProgressPct.Text = ""
          importProgressFill.Size = UDim2.new(0, 0, 1, 0)
        end
      end)
    end
  end

  _G.XYUREI_IMPORT_PROGRESS_CB = setImportProgress

  local function notify(titleText, bodyText, success)
    local okCore = pcall(function()
      game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = tostring(titleText),
        Text = tostring(bodyText),
        Duration = 6,
      })
    end)

    if okCore then
      return
    end

    local oldToast = gui:FindFirstChild(__s("TOAST"))

    if oldToast then
      oldToast:Destroy()
    end

    local toast = mk("Frame", {
      Name = __s("TOAST"),
      Size = UDim2.fromOffset(280, 68),
      Position = UDim2.new(1, -296, 0, 20),
      BackgroundColor3 = C.card,
      BackgroundTransparency = 0.3,
      BorderSizePixel = 0,
      ZIndex = 100002,
    }, gui)

    round(toast, 16)
    stroke(toast, success and C.cyan or C.pink, 1.6, 0.15)
    glass(toast)

    label(toast, {
      Size = UDim2.new(1, -22, 0, 20),
      Position = UDim2.fromOffset(11, 8),
      Text = tostring(titleText),
      Font = Enum.Font.GothamBlack,
      TextSize = 12,
      ZIndex = 501,
    })

    label(toast, {
      Size = UDim2.new(1, -22, 0, 30),
      Position = UDim2.fromOffset(11, 30),
      Text = tostring(bodyText),
      TextColor3 = C.sub,
      Font = Enum.Font.GothamMedium,
      TextSize = 10,
      TextWrapped = true,
      TextYAlignment = Enum.TextYAlignment.Top,
      ZIndex = 501,
    })

    task.delay(5.5, function()
      if toast and toast.Parent then
        toast:Destroy()
      end
    end)
  end

  local function setMainVisible(visible)
    if visible == mainVisible then
      return
    end

    mainVisible = visible

    if windowsToggle then
      windowsToggle(visible)
    end

    if visible then
      main.Visible = true
      setBlur(BLUR_SIZE)
      launcherIcon.Image = "rbxassetid://10709791437"
      launcherFallback.Text = "»"
      mainScale.Scale = UI_SCALE * 0.92

      main.Position = UDim2.new(
        expandedPosition.X.Scale, expandedPosition.X.Offset - 12, expandedPosition.Y.Scale,
        expandedPosition.Y.Offset
      )

      TweenService:Create(
        mainScale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Scale = UI_SCALE }
      ):Play()

      TweenService:Create(
        main, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Position = expandedPosition }
      ):Play()
    else
      expandedPosition = main.Position
      setBlur(0)
      launcherIcon.Image = "rbxassetid://10709791281"
      launcherFallback.Text = "«"

      TweenService:Create(
        mainScale, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { Scale = UI_SCALE * 0.92 }
      ):Play()

      task.delay(0.16, function()
        if gui.Parent and not mainVisible then
          main.Visible = false
          mainScale.Scale = UI_SCALE
        end
      end)
    end
  end

  local function clearCards()
    for _, item in ipairs(allCards) do
      if item.card then
        item.card:Destroy()
      end
    end

    allCards = {}
  end

  local function filterCards()
    local have = {}

    for _, item in ipairs(allCards) do
      local pg = pageOf[item.ext]

      if pg then
        local q = pg.search.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")

        local match = q == "" or item.info.name:lower():find(q, 1, true)
          or item.info.path:lower():find(q, 1, true)

        item.card.Visible = match and true or false
        have[item.ext] = (have[item.ext] or 0) + 1
      end
    end

    for ext, pg in pairs(pageOf) do
      pg.empty.Visible = (have[ext] or 0) == 0
    end
  end

  WS.list = {}
  WS.z = 30
  WS.top = "MAIN"
  WS.s = UI_SCALE
  WS.base = UI_SCALE
  WS.savedMain = nil
  WS.compact = false
  WS.gap = 14
  WS.minScale = 0.6
  WS.compactW = 400
  WS.sideW = 300
  WS.sideMinW = 260
  WS.sideMinH = 280
  WS.stackOff = 22
  WS.seqN = 0

  function WS.viewport()
    local cam = workspace.CurrentCamera
    return cam and cam.ViewportSize or Vector2.new(960, 540)
  end

  function WS.tw(o, t, props, style, dir)
    local tw = TweenService:Create(o, TweenInfo.new(
      t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out
    ), props)

    tw:Play()
    return tw
  end

  function WS.mainCenter()
    return main.AbsolutePosition + main.AbsoluteSize / 2
  end

  function WS.front(who)
    if WS.top == who then
      return
    end

    WS.top = who
    WS.z = WS.z + 2

    if who == "MAIN" then
      mainGlow.ZIndex = WS.z - 1
      main.ZIndex = WS.z
    elseif type(who) == "table" and who.root then
      who.root.ZIndex = WS.z
    end
  end

  function WS.lift(who, on)
    if who == "MAIN" then
      if not mainVisible then
        return
      end

      WS.tw(mainScale, 0.18, { Scale = on and UI_SCALE * 1.025 or UI_SCALE })
      WS.tw(mainGlow, 0.18, { ImageTransparency = on and 0.4 or 0.6 })
      WS.tw(mainStroke, 0.18, { Thickness = on and 2.6 or 1.8 })
    else
      WS.tw(who.scale, 0.18, { Scale = on and WS.s * 1.025 or WS.s })
      WS.tw(who.glow, 0.18, { ImageTransparency = on and 0.4 or 0.62 })
      WS.tw(who.stroke, 0.18, { Thickness = on and 2.6 or 1.8 })
    end
  end

  WS.drag = nil

  function WS.beginDrag(kind, win, input)
    WS.drag = {
      kind = kind,
      win = win,
      input = input,
      start = input.Position,
      pos = Vector2.new(win.root.Position.X.Offset, win.root.Position.Y.Offset),
      size = Vector2.new(win.W, win.H),
    }

    if kind == "move" then
      WS.lift(win, true)
    end

    input.Changed:Connect(function()
      if input.UserInputState == Enum.UserInputState.End then
        WS.endDrag(input)
      end
    end)
  end

  function WS.endDrag(input)
    local d = WS.drag

    if not d or input and d.input ~= input then
      return
    end

    WS.drag = nil

    if d.kind == "move" then
      WS.lift(d.win, false)
    end
  end

  UserInputService.InputChanged:Connect(function(input)
    local d = WS.drag

    if not d then
      return
    end

    local t = d.input.UserInputType

    local okInput = t == Enum.UserInputType.Touch and input == d.input
      or t ~= Enum.UserInputType.Touch
        and input.UserInputType == Enum.UserInputType.MouseMovement

    if not okInput then
      return
    end

    local delta = input.Position - d.start
    local win = d.win

    if d.kind == "move" then
      local v = WS.viewport()

      win.root.Position = UDim2.fromOffset(
        math.clamp(d.pos.X + delta.X, 50, v.X - 50), math.clamp(d.pos.Y + delta.Y, 36, v.Y - 36)
      )
    else
      local s = WS.s
      local nw = math.clamp(d.size.X + delta.X / s, WS.sideMinW, 640)
      local nh = math.clamp(d.size.Y + delta.Y / s, WS.sideMinH, 760)
      local tlx = d.pos.X - d.size.X * s / 2
      local tly = d.pos.Y - d.size.Y * s / 2

      win.W, win.H = nw, nh
      win.root.Size = UDim2.fromOffset(nw, nh)
      win.root.Position = UDim2.fromOffset(tlx + nw * s / 2, tly + nh * s / 2)
    end
  end)

  function WS.make(key, title, sub, accent, tag, W, H, side)
    local win = {
      key = key,
      title = title,
      accent = accent,
      tag = tag,
      open = false,
      W = W,
      H = H,
      side = side or "R",
      seq = 0,
    }

    local root = mk("Frame", {
      Name = "Win_" .. key,
      AnchorPoint = Vector2.new(0.5, 0.5),
      Size = UDim2.fromOffset(W, H),
      Position = UDim2.fromOffset(0, 0),
      BackgroundTransparency = 1,
      Visible = false,
      ZIndex = WS.z,
    }, gui)

    local scale = mk("UIScale", { Scale = UI_SCALE }, root)

    local glow = mk("ImageLabel", {
      Name = "Glow",
      BackgroundTransparency = 1,
      Image = GLOW_IMG,
      ImageColor3 = accent,
      ImageTransparency = 0.62,
      ScaleType = Enum.ScaleType.Slice,
      SliceCenter = Rect.new(49, 49, 450, 450),
      Size = UDim2.new(1, 60, 1, 60),
      Position = UDim2.fromOffset(-30, -30),
      ZIndex = 1,
    }, root)

    round(glow, 36)

    local shell = mk("Frame", {
      Name = "Shell",
      Size = UDim2.fromScale(1, 1),
      BackgroundColor3 = C.bg,
      BackgroundTransparency = 0.16,
      BorderSizePixel = 0,
      ClipsDescendants = true,
      Active = true,
      ZIndex = 2,
    }, root)

    round(shell, 24)
    local sStroke = stroke(shell, C.white, 1.8, 0.2)

    local sGrad = Instance.new("UIGradient")

    sGrad.Color = ColorSequence.new({
      ColorSequenceKeypoint.new(0, accent), ColorSequenceKeypoint.new(0.35, C.purple),
      ColorSequenceKeypoint.new(0.7, C.pink), ColorSequenceKeypoint.new(1, accent),
    })

    sGrad.Parent = sStroke

    TweenService:Create(
      sGrad, TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
      { Rotation = 360 }
    ):Play()

    gradient(shell, {
      ColorSequenceKeypoint.new(0, Color3.fromRGB(26, 26, 32)),
      ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 6, 9)),
    }, 120)

    local sheen = mk("Frame", {
      Name = "Sheen",
      Size = UDim2.new(1, 0, 0, 120),
      BackgroundColor3 = Color3.fromRGB(255, 255, 255),
      BorderSizePixel = 0,
      ZIndex = 3,
    }, shell)

    local sg = Instance.new("UIGradient")
    sg.Rotation = 90

    sg.Transparency = NumberSequence.new({
      NumberSequenceKeypoint.new(0, 0.93), NumberSequenceKeypoint.new(1, 1),
    })

    sg.Parent = sheen

    local header = mk("Frame", {
      Name = "Header",
      Size = UDim2.new(1, 0, 0, 52),
      BackgroundTransparency = 1,
      Active = true,
      ZIndex = 6,
    }, shell)

    mk("Frame", {
      Size = UDim2.new(1, -24, 0, 1),
      Position = UDim2.new(0, 12, 1, -1),
      BackgroundColor3 = C.white,
      BackgroundTransparency = 0.9,
      BorderSizePixel = 0,
      ZIndex = 6,
    }, header)

    local dot = mk("Frame", {
      Size = UDim2.fromOffset(10, 10),
      Position = UDim2.fromOffset(16, 21),
      BackgroundColor3 = accent,
      BorderSizePixel = 0,
      ZIndex = 7,
    }, header)

    round(dot, 5)

    TweenService:Create(dot, TweenInfo.new(
      1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true
    ), { BackgroundTransparency = 0.65 }):Play()

    label(header, {
      Size = UDim2.new(1, -150, 0, 20),
      Position = UDim2.fromOffset(34, 8),
      Text = title,
      Font = Enum.Font.GothamBlack,
      TextSize = 15,
      TextTruncate = Enum.TextTruncate.AtEnd,
      ZIndex = 7,
    })

    label(header, {
      Size = UDim2.new(1, -150, 0, 14),
      Position = UDim2.fromOffset(34, 28),
      Text = sub,
      TextColor3 = accent,
      TextSize = 9,
      TextTruncate = Enum.TextTruncate.AtEnd,
      ZIndex = 7,
    })

    local closeB = mk("TextButton", {
      Name = "Close",
      Size = UDim2.fromOffset(30, 30),
      Position = UDim2.new(1, -40, 0, 11),
      BackgroundColor3 = Color3.fromRGB(36, 36, 44),
      BackgroundTransparency = 0.3,
      Text = "×",
      TextColor3 = Color3.fromRGB(235, 235, 242),
      Font = Enum.Font.GothamBold,
      TextSize = 18,
      AutoButtonColor = false,
      ZIndex = 8,
    }, header)

    round(closeB, 9)
    stroke(closeB, Color3.fromRGB(235, 235, 242), 1.2, 0.35)

    local dockB = mk("TextButton", {
      Name = "Dock",
      Size = UDim2.fromOffset(50, 30),
      Position = UDim2.new(1, -96, 0, 11),
      BackgroundColor3 = C.card,
      BackgroundTransparency = 0.38,
      Text = "DOCK",
      TextColor3 = C.sub,
      Font = Enum.Font.GothamBlack,
      TextSize = 10,
      AutoButtonColor = false,
      ZIndex = 8,
    }, header)

    round(dockB, 9)
    stroke(dockB, C.white, 1, 0.85)

    local body = mk("Frame", {
      Name = "Body",
      Size = UDim2.new(1, -24, 1, -66),
      Position = UDim2.fromOffset(12, 58),
      BackgroundTransparency = 1,
      ZIndex = 5,
    }, shell)

    local grip = mk("TextButton", {
      Name = "Grip",
      Size = UDim2.fromOffset(22, 22),
      Position = UDim2.new(1, -24, 1, -24),
      BackgroundTransparency = 1,
      Text = "",
      AutoButtonColor = false,
      ZIndex = 30,
    }, shell)

    for _, off in ipairs({ 6, 10, 14 }) do
      mk("Frame", {
        Size = UDim2.fromOffset(2, 8),
        Position = UDim2.fromOffset(off, 8),
        Rotation = 45,
        BackgroundColor3 = C.white,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        ZIndex = 31,
      }, grip)
    end

    win.root, win.scale, win.glow, win.stroke, win.body = root, scale, glow, sStroke, body
    win.closeB, win.dockB = closeB, dockB

    local function isPress(i)
      return i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch
    end

    local function inside(btn, pos)
      local p, s = btn.AbsolutePosition, btn.AbsoluteSize
      return pos.X >= p.X and pos.X <= p.X + s.X and pos.Y >= p.Y and pos.Y <= p.Y + s.Y
    end

    root.InputBegan:Connect(function(i)
      if isPress(i) then
        WS.front(win)
      end
    end)

    header.InputBegan:Connect(function(i)
      if not isPress(i) then
        return
      end

      if inside(closeB, i.Position) or inside(dockB, i.Position) then
        return
      end

      WS.beginDrag("move", win, i)
    end)

    grip.InputBegan:Connect(function(i)
      if isPress(i) then
        WS.beginDrag("size", win, i)
      end
    end)

    closeB.Activated:Connect(function() WS.close(key) end)
    dockB.Activated:Connect(function() WS.layout(true) end)

    for _, b in ipairs({
      { closeB, Color3.fromRGB(36, 36, 44), Color3.fromRGB(70, 70, 82) },
      { dockB, C.card, C.card2 },
    }) do
      b[1].MouseEnter:Connect(function() WS.tw(b[1], 0.15, { BackgroundColor3 = b[3] }) end)
      b[1].MouseLeave:Connect(function() WS.tw(b[1], 0.15, { BackgroundColor3 = b[2] }) end)
    end

    task.delay(math.random() * 1.5, function()
      if root.Parent then
        TweenService:Create(root, TweenInfo.new(
          2.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true
        ), { AnchorPoint = Vector2.new(0.5, 0.508) }):Play()
      end
    end)

    WS.list[key] = win
    return win
  end

  function WS.setCompact(on)
    if WS.compact == on then
      return
    end

    WS.compact = on

    if dashGrid then
      dashGrid.CellSize = on and UDim2.new(0.5, -3, 0, 46) or UDim2.new(1 / 3, -4, 0, 46)
    end
  end

  function WS.layout(animate)
    local v = WS.viewport()
    local groups = { L = {}, R = {} }

    for _, win in pairs(WS.list) do
      if win.open then
        table.insert(groups[win.side], win)
      end
    end

    for _, g in pairs(groups) do
      table.sort(g, function(x, y) return x.seq < y.seq end)
    end

    local n = #groups.L + #groups.R
    local mW, mH = main.Size.X.Offset, main.Size.Y.Offset

    if n > 0 then
      if not WS.savedMain then
        WS.savedMain = Vector2.new(mW, mH)
      end

      mW = math.min(WS.savedMain.X, WS.compactW)
      mH = math.min(WS.savedMain.Y, 400)
    elseif WS.savedMain then
      mW, mH = WS.savedMain.X, WS.savedMain.Y
      WS.savedMain = nil
    end

    local off = WS.stackOff

    local function groupW(g)
      local m = 0

      for _, w in ipairs(g) do
        m = math.max(m, w.W)
      end

      return m + off * math.max(0, #g - 1)
    end

    local items = {}

    if #groups.L > 0 then
      items[#items + 1] = { g = groups.L, w = groupW(groups.L), side = "L" }
    end

    items[#items + 1] = { main = true, w = mW }

    if #groups.R > 0 then
      items[#items + 1] = { g = groups.R, w = groupW(groups.R), side = "R" }
    end

    local sumW = 0

    for _, it in ipairs(items) do
      sumW = sumW + it.w
    end

    local margin, gap = 12, WS.gap
    local fitW = (v.X - margin * 2 - gap * (#items - 1)) / sumW
    local fitH = (v.Y - 24) / mH
    local s = math.clamp(math.min(WS.base, fitW, fitH), WS.minScale, WS.base)
    WS.s = s
    UI_SCALE = s
    local total = sumW * s + gap * (#items - 1)
    local avail = v.X - margin * 2

    if total > avail and #items > 1 then
      gap = (avail - sumW * s) / (#items - 1)
      total = avail
    end

    local cx, cy = (v.X - total) / 2, v.Y / 2
    local dur = animate and 0.55 or 0

    for _, it in ipairs(items) do
      local gw = it.w * s

      if it.main then
        local pos = UDim2.fromOffset(cx, cy - mH * s / 2)
        local size = UDim2.fromOffset(mW, mH)
        expandedPosition = pos

        if animate and mainVisible then
          WS.tw(main, dur, { Position = pos, Size = size })
          WS.tw(mainScale, dur, { Scale = s }, Enum.EasingStyle.Back)
        else
          main.Position = pos
          main.Size = size
          mainScale.Scale = s
        end
      else
        for i, win in ipairs(it.g) do
          win.H = mH
          local ww = win.W * s
          local cenX

          if it.side == "L" then
            cenX = cx + (i - 1) * off * s + ww / 2
          else
            cenX = cx + gw - (i - 1) * off * s - ww / 2
          end

          local pos = UDim2.fromOffset(cenX, cy)
          local size = UDim2.fromOffset(win.W, win.H)

          if animate then
            WS.tw(win.root, dur, { Position = pos, Size = size })
            WS.tw(win.scale, dur, { Scale = s }, Enum.EasingStyle.Back)
          else
            win.root.Position = pos
            win.root.Size = size
            win.scale.Scale = s
          end
        end
      end

      cx = cx + (gw + gap)
    end

    WS.setCompact(mW < 500)
  end

  function WS.setActive(key, on)
    local b = dashButtons[key]

    if not b then
      return
    end

    local st = b:FindFirstChildOfClass("UIStroke")

    if st then
      WS.tw(st, 0.25, { Thickness = on and 2 or 1.2, Transparency = on and 0 or 0.5 })
    end

    navOpen[key] = on and true or nil

    WS.tw(b, 0.25, {
      BackgroundColor3 = on and Color3.fromRGB(70, 72, 82) or C.card2,
      BackgroundTransparency = on and 0.12 or 0.38,
    })

    local nb = navButtons[key]

    if nb then
      WS.tw(nb, 0.25, { BackgroundTransparency = on and 0.15 or 1 })
    end

    local win = WS.list[key]
    local badge = dashBadges[key]

    if badge and win and counts[key] == nil then
      badge.Text = "AKTIF"
      badge.TextColor3 = C.ok
      badge.Visible = on
    end
  end

  function WS.open(key)
    local win = WS.list[key]

    if not win then
      return
    end

    if win.open then
      WS.front(win)
      return
    end

    local nL, nR = 0, 0

    for _, w in pairs(WS.list) do
      if w.open then
        if w.side == "L" then
          nL = nL + 1
        else
          nR = nR + 1
        end
      end
    end

    if nL < nR then
      win.side = "L"
    elseif nR < nL then
      win.side = "R"
    else
      win.side = WS.lastSide == "L" and "R" or "L"
    end

    WS.lastSide = win.side
    win.open = true
    WS.seqN = WS.seqN + 1
    win.seq = WS.seqN
    local c = WS.mainCenter()

    win.root.Size = UDim2.fromOffset(win.W, win.H)
    win.root.Position = UDim2.fromOffset(c.X, c.Y)
    win.scale.Scale = WS.s * 0.55
    win.root.ZIndex = main.ZIndex - 2
    win.root.Visible = true

    WS.setActive(key, true)
    WS.layout(true)

    task.delay(0.35, function()
      if win.open then
        WS.front(win)
      end
    end)

    setStatus(win.title:upper() .. " DIBUKA", win.accent)
  end

  function WS.close(key)
    local win = WS.list[key]

    if not win or not win.open then
      return
    end

    win.open = false

    WS.drag = nil
    WS.setActive(key, false)

    local c = WS.mainCenter()

    WS.tw(
      win.root, 0.32, { Position = UDim2.fromOffset(c.X, c.Y) }, Enum.EasingStyle.Quint,
      Enum.EasingDirection.In
    )

    WS.tw(
      win.scale, 0.32, { Scale = WS.s * 0.55 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In
    )

    task.delay(0.33, function()
      if not win.open and win.root.Parent then
        win.root.Visible = false
      end
    end)

    WS.layout(true)
  end

  function WS.toggle(key)
    local win = WS.list[key]

    if not win then
      return
    end

    if win.open then
      WS.close(key)
    else
      WS.open(key)
    end
  end

  windowsToggle = function(vis)
    for _, win in pairs(WS.list) do
      if win.open then
        if vis then
          win.root.Visible = true
          win.scale.Scale = WS.s * 0.9
          WS.tw(win.scale, 0.24, { Scale = WS.s }, Enum.EasingStyle.Back)
        else
          WS.tw(
            win.scale, 0.16, { Scale = WS.s * 0.9 }, Enum.EasingStyle.Quad,
            Enum.EasingDirection.In
          )

          task.delay(0.16, function()
            if not mainVisible and win.open then
              win.root.Visible = false
              win.scale.Scale = WS.s
            end
          end)
        end
      end
    end
  end

  function WS.stagger()
    local cards = {}

    for _, b in pairs(dashButtons) do
      cards[#cards + 1] = b
    end

    table.sort(cards, function(a, b) return a.LayoutOrder < b.LayoutOrder end)

    for i, b in ipairs(cards) do
      local pop = b:FindFirstChildOfClass("UIScale")

      if pop then
        pop.Scale = 0.86

        task.delay((i - 1) * 0.045, function()
          if pop.Parent then
            WS.tw(pop, 0.38, { Scale = 1 }, Enum.EasingStyle.Back)
          end
        end)
      end
    end
  end

  function WS.pageFx(key)
    content.Position = UDim2.fromOffset(12, 62)
    WS.tw(content, 0.35, { Position = UDim2.fromOffset(12, 52) })

    if key == "dash" then
      WS.stagger()
    end
  end

  main.Active = true
  header.Active = true

  main.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
      or i.UserInputType == Enum.UserInputType.Touch then
      WS.front("MAIN")
    end
  end)

  do
    exploreBtn.ClipsDescendants = true

    local glint = mk("Frame", {
      Name = "Glint",
      Size = UDim2.new(0.16, 0, 1.8, 0),
      Position = UDim2.new(-0.3, 0, -0.4, 0),
      Rotation = 18,
      BackgroundColor3 = C.white,
      BackgroundTransparency = 0.8,
      BorderSizePixel = 0,
      ZIndex = 17,
    }, exploreBtn)

    task.spawn(function()
      while glint.Parent do
        glint.Position = UDim2.new(-0.3, 0, -0.4, 0)

        local t = WS.tw(
          glint, 1.1, { Position = UDim2.new(1.2, 0, -0.4, 0) }, Enum.EasingStyle.Sine,
          Enum.EasingDirection.InOut
        )

        t.Completed:Wait()

        task.wait(2.4)
      end
    end)
  end

  task.delay(0.6, function()
    if main.Parent then
      TweenService:Create(main, TweenInfo.new(
        2.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true
      ), { AnchorPoint = Vector2.new(0, 0.008) }):Play()
    end
  end)

  local spoofWin = WS.make(
    "SPOOF", "Spoof & Bypass", "ULTRA-FAST 60FPS · AUTO PLACE ID", Color3.fromRGB(245, 175, 45), nil,
    WS.sideW + 60, DEF_H, "R"
  )

  local musicWin = WS.make(
    "MUSIC", "Music Player", "MUSIC PLAYER · PUTAR LAGU", Color3.fromRGB(210, 212, 222), nil,
    WS.sideW, DEF_H, "L"
  )

  local chatWin = WS.make(
    "CHAT", "AI Chat", "OPENROUTER", Color3.fromRGB(190, 192, 202), nil, WS.sideW, DEF_H, "L"
  )

  local bypassWin = WS.make(
    "BYPASS", "Bypass Music", "UPLOAD AUDIO KE ROBLOX", Color3.fromRGB(235, 236, 242), nil,
    WS.sideW, DEF_H, "R"
  )

  WS.upWin = {
    IMAGE = WS.make(
      "IMAGE", "Upload Image", "UPLOAD GAMBAR KE ROBLOX", Color3.fromRGB(220, 222, 230), nil,
      WS.sideW, DEF_H, "R"
    ),
    ANIM = WS.make(
      "ANIM", "Upload Animasi", "UPLOAD ANIMASI KE ROBLOX", Color3.fromRGB(200, 202, 212), nil,
      WS.sideW, DEF_H, "R"
    ),
    MODEL = WS.make(
      "MODEL", "Upload RBXM", "UPLOAD MODEL KE ROBLOX", Color3.fromRGB(235, 236, 242), nil,
      WS.sideW, DEF_H, "R"
    ),
    IMG3D = WS.make(
      "IMG3D", "Image to 3D", "GAMBAR → MODEL 3D", Color3.fromRGB(240, 242, 248), nil,
      WS.sideW, DEF_H, "R"
    ),
    REPLACE = WS.make(
      "REPLACE", "Replace Tool", "WARNA · MATERIAL · MODEL / PART",
      Color3.fromRGB(228, 230, 238), nil, WS.sideW, DEF_H, "R"
    ),
  }

  local tbWin = WS.make(
    "TB", "Toolbox", "MODEL · MESH · DECAL · AUDIO", C.cyan, nil, WS.sideW, DEF_H, "R"
  )

  local impWin = {
    RBXM = WS.make(
      "RBXM", "Import RBXM", "MODEL BINARY (.RBXM)", C.cyan, nil, WS.sideW, DEF_H, "R"
    ),
    RBXL = WS.make(
      "RBXL", "Import RBXL", "PLACE BINARY (.RBXL)", C.purple, nil, WS.sideW, DEF_H, "R"
    ),
    RBXLX = WS.make(
      "RBXLX", "Import RBXLX", "PLACE XML (.RBXLX)", C.pink, nil, WS.sideW, DEF_H, "R"
    ),
    RBXMX = WS.make(
      "RBXMX", "Import RBXMX", "MODEL XML (.RBXMX)", Color3.fromRGB(225, 228, 236), nil,
      WS.sideW, DEF_H, "R"
    ),
  }

  for ext, win in pairs(impWin) do
    local pg = pageOf[ext]
    pg.frame.Parent = win.body
    pg.frame.Visible = true

    pages[ext] = nil
  end

  for key, win in pairs(WS.list) do
    local badge = dashBadges[key]

    if badge and counts[key] == nil then
      badge.Size = UDim2.fromOffset(34, 14)
      badge.Position = UDim2.new(1, -38, 0, 4)
      badge.TextSize = 8
      badge.Text = "AKTIF"
      badge.TextColor3 = C.ok
      badge.Visible = false
    end
  end

  local function makeCard(info, ext)
    local pg = pageOf[ext]

    if not pg then
      return
    end

    pg.empty.Visible = false

    local card = mk("Frame", {
      Size = UDim2.new(1, -4, 0, 48),
      BackgroundColor3 = C.card2,
      BackgroundTransparency = 0.42,
      BorderSizePixel = 0,
      ZIndex = 14,
    }, pg.list)

    round(card, 13)
    stroke(card, C.white, 1, 0.85)
    glass(card)

    local accent = mk("Frame", {
      Size = UDim2.new(0, 3, 0.6, 0),
      Position = UDim2.new(0, 0, 0.2, 0),
      BackgroundColor3 = C.cyan,
      BorderSizePixel = 0,
      ZIndex = 15,
    }, card)

    round(accent, 2)

    local badge = label(card, {
      Size = UDim2.fromOffset(46, 16),
      Position = UDim2.fromOffset(12, 8),
      BackgroundTransparency = 0.1,
      BackgroundColor3 = C.bg,
      Text = ext,
      TextColor3 = C.cyan,
      Font = Enum.Font.GothamBlack,
      TextSize = 10,
      TextXAlignment = Enum.TextXAlignment.Center,
    })

    round(badge, 5)
    stroke(badge, C.cyan, 1, 0.6)

    label(card, {
      Size = UDim2.new(1, -170, 0, 14),
      Position = UDim2.fromOffset(66, 8),
      Text = info.name,
      TextSize = 11,
      TextTruncate = Enum.TextTruncate.AtEnd,
    })

    label(card, {
      Size = UDim2.new(1, -170, 0, 12),
      Position = UDim2.fromOffset(66, 26),
      Text = info.path,
      TextColor3 = C.faint,
      Font = Enum.Font.Code,
      TextSize = 10,
      TextTruncate = Enum.TextTruncate.AtEnd,
    })

    local importBtn = mk("TextButton", {
      Size = UDim2.fromOffset(78, 28),
      Position = UDim2.new(1, -88, 0.5, -14),
      BackgroundColor3 = C.purple,
      Text = "IMPORT",
      TextColor3 = C.white,
      Font = Enum.Font.GothamBlack,
      TextSize = 10,
      AutoButtonColor = false,
      ZIndex = 15,
    }, card)

    round(importBtn, 8)
    stroke(importBtn, C.white, 1, 0.7)
    local importedRoot = nil
    local isModel = ext == "RBXM" or ext == "RBXMX"

    importBtn.Activated:Connect(function()
      if importBtn.Text == "IMPORTING" or importBtn.Text == "ACTIVATING" then
        return
      end

      if importBtn.Text == "ACTIVATE" and importedRoot then
        importBtn.Text = "ACTIVATING"
        setStatus("ACTIVATING " .. info.name, C.warn)

        task.spawn(function()
          local ok, message = activateImportRoot(importedRoot)

          if ok then
            importBtn.Text = "ACTIVE"
            setImportProgress(1, "RBXL GENERATION COMPLETE")
            setStatus(message, C.ok)
            notify(__s("NOTIFY"), info.name .. " berhasil digenerate 100%.", true)
          else
            importBtn.Text = "ACTIVATE"
            setStatus("ACTIVATE ERROR: " .. tostring(message), C.danger)
          end
        end)

        return
      end

      if importBtn.Text == "ACTIVE" or importBtn.Text == "DONE" then
        setStatus("ALREADY IMPORTED • " .. info.name, C.ok)
        return
      end

      importBtn.Text = "IMPORTING"
      setImportProgress(0.01, "STARTING IMPORT • " .. info.name)
      setStatus("IMPORTING " .. info.name, C.warn)

      task.spawn(function()
        local ok, message, root

        if isModel then
          ok, message, root = importRBXM(info)
        else
          ok, message, root = importRBXL(info)
        end

        if ok then
          importedCount = importedCount + 1
          updateCount()
          importedRoot = root

          if isModel then
            importBtn.Text = "DONE"
            setImportProgress(1, "RBXM GENERATION COMPLETE")
            setStatus(message, C.ok)
            notify(__s("NOTIFY"), info.name .. " berhasil digenerate 100%.", true)
            return
          end

          importBtn.Text = "ACTIVATING"
          setStatus(message .. " • AUTO ACTIVATING", C.warn)
          local activateOK, activateMessage = activateImportRoot(importedRoot)

          if activateOK then
            importBtn.Text = "ACTIVE"
            setImportProgress(1, "RBXL GENERATION COMPLETE")
            setStatus(activateMessage, C.ok)
            notify(__s("NOTIFY"), info.name .. " berhasil digenerate 100%.", true)
          else
            importBtn.Text = "ACTIVATE"
            setStatus("AUTO ACTIVATE ERROR: " .. tostring(activateMessage), C.danger)
            notify(__s("FAIL"), tostring(activateMessage), false)
          end
        else
          importBtn.Text = "FAILED"
          setStatus(message, C.danger)
          notify(__s("FAIL"), tostring(message), false)
          task.wait(2.2)

          if importBtn and importBtn.Parent then
            importBtn.Text = "IMPORT"
          end
        end
      end)
    end)

    card.MouseEnter:Connect(function()
      TweenService:Create(card, TweenInfo.new(0.15), { BackgroundTransparency = 0.26 }):Play()
    end)

    card.MouseLeave:Connect(function()
      TweenService:Create(card, TweenInfo.new(0.15), { BackgroundTransparency = 0.42 }):Play()
    end)

    table.insert(allCards, { info = info, ext = ext, card = card })
  end

  local scanButtons = {}

  for _, pg in pairs(pageOf) do
    table.insert(scanButtons, pg.scan)
  end

  local function setScanUi(text, color)
    for _, b in ipairs(scanButtons) do
      b.Text = text
      b.BackgroundColor3 = color
    end

    landingScan.Text = text == "SCAN" and "Scan Ulang" or "Scanning..."
    dashScanBtn.Text = text == "SCAN" and "Scan Ulang" or "Scanning..."
  end

  local function scanNow()
    setScanUi("SCANNING", C.warn)
    setStatus("SCANNING WORKSPACE", C.warn)
    clearCards()

    for k in pairs(counts) do
      counts[k] = 0
    end

    importedCount = 0
    updateCount()

    for _, pg in pairs(pageOf) do
      pg.empty.Visible = true
      pg.empty.Text = "SCANNING..."
    end

    task.spawn(function()
      if type(listfiles) ~= "function" then
        for _, pg in pairs(pageOf) do
          pg.empty.Text = "LISTFILES API NOT AVAILABLE"
        end

        setStatus("ERROR: listfiles tidak tersedia", C.danger)
        setScanUi("SCAN", C.purple)
        return
      end

      local ok, results = pcall(scanAllSupported)

      if not ok then
        for _, pg in pairs(pageOf) do
          pg.empty.Text = "SCAN FAILED"
        end

        setStatus("SCAN ERROR: " .. tostring(results), C.danger)
        setScanUi("SCAN", C.purple)
        return
      end

      local extOf = {}

      for _, info in ipairs(results) do
        local ext = (info.name:lower():match("%.(%w+)$") or ""):upper()

        if counts[ext] ~= nil then
          counts[ext] = counts[ext] + 1
          extOf[info] = ext
        end
      end

      for _, pg in pairs(pageOf) do
        pg.empty.Text = pg.emptyText
      end

      updateCount()

      for _, info in ipairs(results) do
        if extOf[info] then
          makeCard(info, extOf[info])
          task.wait()
        end
      end

      local total = counts.RBXM + counts.RBXMX + counts.RBXL + counts.RBXLX

      if total == 0 then
        setStatus("SCAN COMPLETE • 0 FILES", C.warn)
      else
        setStatus(("SCAN COMPLETE • RBXL %d • RBXLX %d • RBXM %d • RBXMX %d"):format(
          counts.RBXL, counts.RBXLX, counts.RBXM, counts.RBXMX
        ), C.ok)
      end

      setScanUi("SCAN", C.purple)
      filterCards()
    end)
  end

  for _, pg in pairs(pageOf) do
    pg.search:GetPropertyChangedSignal("Text"):Connect(filterCards)
    pg.scan.Activated:Connect(scanNow)
  end

  landingScan.Activated:Connect(scanNow)

  local TB_CATS = {
    { key = "Model", id = 10 }, { key = "Mesh", id = 4 }, { key = "Decal", id = 13 },
    { key = "Audio", id = 3 },
  }

  local tbCat = TB_CATS[1]
  local tbToken, tbOrder, tbPageNum, tbQuery = 0, 0, 0, ""
  local tbMoreBtn = nil

  local tbFrame = mk("Frame", {
    Name = "Page_TB",
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Visible = true,
    ZIndex = 12,
  }, tbWin.body)

  local chipRow = mk(
    "Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, ZIndex = 13 }, tbFrame
  )

  mk("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
  }, chipRow)

  local chips = {}

  local function refreshChips()
    for key, b in pairs(chips) do
      local active = key == tbCat.key
      b.BackgroundColor3 = active and C.purple or C.card2
      b.TextColor3 = active and C.white or C.sub
    end
  end

  for i, cat in ipairs(TB_CATS) do
    local b = mk("TextButton", {
      Size = UDim2.new(0.25, -5, 0, 30),
      BackgroundColor3 = C.card2,
      Text = cat.key:upper(),
      TextColor3 = C.sub,
      Font = Enum.Font.GothamBlack,
      TextSize = 10,
      AutoButtonColor = false,
      LayoutOrder = i,
      ZIndex = 14,
    }, chipRow)

    round(b, 8)
    stroke(b, C.white, 1, 0.88)
    chips[cat.key] = b
  end

  local tbTool = mk("Frame", {
    Size = UDim2.new(1, 0, 0, 40),
    Position = UDim2.fromOffset(0, 38),
    BackgroundTransparency = 1,
    ZIndex = 13,
  }, tbFrame)

  local tbSw = mk("Frame", {
    Size = UDim2.new(1, -98, 1, 0),
    BackgroundColor3 = C.card,
    BackgroundTransparency = 0.38,
    BorderSizePixel = 0,
    ZIndex = 14,
  }, tbTool)

  round(tbSw, 11)
  stroke(tbSw, C.white, 1, 0.85)
  glass(tbSw)

  local tbBox = mk("TextBox", {
    Name = "Search",
    Size = UDim2.new(1, -20, 1, 0),
    Position = UDim2.fromOffset(12, 0),
    BackgroundTransparency = 1,
    PlaceholderText = "Cari kata kunci atau tempel ID...",
    PlaceholderColor3 = C.faint,
    Text = "",
    TextColor3 = C.white,
    Font = Enum.Font.GothamMedium,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false,
    ZIndex = 15,
  }, tbSw)

  local tbGo = mk("TextButton", {
    Size = UDim2.fromOffset(88, 40),
    Position = UDim2.new(1, -88, 0, 0),
    BackgroundColor3 = C.purple,
    Text = "CARI",
    TextColor3 = C.white,
    Font = Enum.Font.GothamBlack,
    TextSize = 12,
    AutoButtonColor = false,
    ZIndex = 14,
  }, tbTool)

  round(tbGo, 10)
  stroke(tbGo, C.white, 1, 0.7)

  local tbList = mk("ScrollingFrame", {
    Name = "TBList",
    Size = UDim2.new(1, 0, 1, -86),
    Position = UDim2.fromOffset(0, 86),
    BackgroundColor3 = C.card,
    BackgroundTransparency = 0.55,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = C.white,
    ScrollBarImageTransparency = 0.35,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.new(),
    ZIndex = 13,
  }, tbFrame)

  round(tbList, 12)
  stroke(tbList, C.white, 1, 0.88)
  padding(tbList, 8, 8, 8, 8)

  mk(
    "UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, tbList
  )

  local tbEmpty = label(tbList, {
    Size = UDim2.new(1, -16, 0, 100),
    Text = [[
KETIK KATA KUNCI ATAU ID
LALU TEKAN CARI]],
    TextColor3 = C.faint,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Center,
    ZIndex = 14,
    LayoutOrder = 0,
  })

  local httpReq = syn and syn.request or http and http.request or http_request or request
    or fluxus and fluxus.request

  local function tbHttpJson(url)
    if not httpReq then
      return nil, "executor tidak punya fungsi request()"
    end

    local ok, res = pcall(httpReq, { Url = url, Method = "GET" })

    if not ok or type(res) ~= "table" then
      return nil, tostring(res)
    end

    if res.StatusCode and res.StatusCode ~= 200 then
      return nil, "HTTP " .. tostring(res.StatusCode)
    end

    local okJ, data = pcall(function() return HttpService:JSONDecode(res.Body) end)

    if not okJ then
      return nil, "JSON error"
    end

    return data
  end

  local function tbClearList()
    for _, c in ipairs(tbList:GetChildren()) do
      if c:IsA("Frame") or c:IsA("TextButton") then
        c:Destroy()
      end
    end

    tbMoreBtn = nil
    tbOrder = 0
  end

  local function tbCopy(text)
    local fn = setclipboard or toclipboard or syn and syn.write_clipboard
      or Clipboard and Clipboard.set

    if fn then
      local ok = pcall(fn, tostring(text))

      if ok then
        return true
      end
    end

    return false
  end

  local function tbSpawnCF()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")

    if root then
      return root.CFrame * CFrame.new(0, 2, -10)
    end

    return CFrame.new(0, 10, 0)
  end

  local tbPreview

  local function tbImport(cat, id)
    local cf = tbSpawnCF()
    local url = "rbxassetid://" .. tostring(id)

    local function mark(o)
      pcall(function()
        o:SetAttribute("XYUREI_ImportedObject", true)
        o:SetAttribute("XYUREI_Toolbox", true)
      end)
    end

    if cat.key == "Model" then
      local objs
      local ok, res = pcall(function() return game:GetObjects(url) end)

      if ok and type(res) == "table" and #res > 0 then
        objs = res
      end

      if not objs then
        local ok2, model = pcall(function() return InsertService:LoadAsset(id) end)

        if ok2 and model then
          objs = model:GetChildren()
          model:Destroy()
        end
      end

      if not objs or #objs == 0 then
        return false, "gagal memuat model " .. id
      end

      for _, o in ipairs(objs) do
        mark(o)
        o.Parent = workspace

        pcall(function()
          if o:IsA("Model") then
            o:PivotTo(cf)
          elseif o:IsA("BasePart") then
            o.CFrame = cf
          end
        end)
      end

      return true, ("model %d dimasukkan (%d objek)"):format(id, #objs)
    elseif cat.key == "Mesh" then
      local part = Instance.new("Part")
      part.Name = "Mesh_" .. id
      part.Size = Vector3.new(4, 4, 4)
      part.Anchored = true
      part.CFrame = cf

      local m = Instance.new("SpecialMesh")
      m.MeshType = Enum.MeshType.FileMesh
      m.MeshId = url
      m.Parent = part

      mark(part)
      part.Parent = workspace
      return true, ("mesh %d dimasukkan"):format(id)
    elseif cat.key == "Decal" then
      local part = Instance.new("Part")
      part.Name = "Decal_" .. id
      part.Size = Vector3.new(6, 6, 0.4)
      part.Anchored = true
      part.CFrame = cf

      local decal
      local ok, res = pcall(function() return game:GetObjects(url) end)

      if ok and type(res) == "table" and res[1]
        and (res[1]:IsA("Decal") or res[1]:IsA("Texture")) then
        decal = res[1]
      else
        decal = Instance.new("Decal")
        decal.Texture = url
      end

      decal.Face = Enum.NormalId.Front
      decal.Parent = part

      mark(part)
      part.Parent = workspace
      return true, ("decal %d dimasukkan"):format(id)
    elseif cat.key == "Audio" then
      local s = Instance.new("Sound")
      s.Name = "Audio_" .. id
      s.SoundId = url
      s.Looped = false
      s.Volume = 1

      mark(s)

      s.Parent = workspace
      s:Play()

      return true, ("audio %d dimasukkan & diputar"):format(id)
    end

    return false, "kategori tidak dikenal"
  end

  local function tbTogglePreview(id)
    if not tbPreview then
      tbPreview = Instance.new("Sound")
      tbPreview.Name = "XYUREI_TBPreview"
      tbPreview.Parent = gui
    end

    local url = "rbxassetid://" .. tostring(id)

    if tbPreview.IsPlaying and tbPreview.SoundId == url then
      tbPreview:Stop()
      return false
    end

    tbPreview.SoundId = url
    tbPreview:Play()

    return true
  end

  local function tbMakeCard(entry)
    tbEmpty.Visible = false
    tbOrder = tbOrder + 1

    local card = mk("Frame", {
      Size = UDim2.new(1, -4, 0, 56),
      BackgroundColor3 = C.card2,
      BackgroundTransparency = 0.42,
      BorderSizePixel = 0,
      LayoutOrder = tbOrder,
      ZIndex = 14,
    }, tbList)

    round(card, 13)
    stroke(card, C.white, 1, 0.85)
    glass(card)

    local thumb = mk("ImageLabel", {
      Size = UDim2.fromOffset(40, 40),
      Position = UDim2.fromOffset(8, 8),
      BackgroundColor3 = C.bg,
      Image = ("rbxthumb://type=Asset&id=%d&w=150&h=150"):format(entry.id),
      ScaleType = Enum.ScaleType.Fit,
      ZIndex = 15,
    }, card)

    round(thumb, 8)

    label(card, {
      Size = UDim2.new(1, -190, 0, 14),
      Position = UDim2.fromOffset(56, 10),
      Text = entry.name,
      TextSize = 11,
      TextTruncate = Enum.TextTruncate.AtEnd,
    })

    label(card, {
      Size = UDim2.new(1, -190, 0, 12),
      Position = UDim2.fromOffset(56, 28),
      Text = "ID " .. entry.id .. (entry.creator and " · " .. entry.creator or ""),
      TextColor3 = C.faint,
      Font = Enum.Font.Code,
      TextSize = 10,
      TextTruncate = Enum.TextTruncate.AtEnd,
    })

    local copyBtn = mk("TextButton", {
      Size = UDim2.fromOffset(52, 28),
      Position = UDim2.new(1, -128, 0.5, -14),
      BackgroundColor3 = C.card,
      Text = "SALIN",
      TextColor3 = C.cyan,
      Font = Enum.Font.GothamBlack,
      TextSize = 10,
      AutoButtonColor = false,
      ZIndex = 15,
    }, card)

    round(copyBtn, 8)
    stroke(copyBtn, C.cyan, 1, 0.6)

    local actBtn = mk("TextButton", {
      Size = UDim2.fromOffset(66, 28),
      Position = UDim2.new(1, -72, 0.5, -14),
      BackgroundColor3 = C.purple,
      Text = "IMPORT",
      TextColor3 = C.white,
      Font = Enum.Font.GothamBlack,
      TextSize = 10,
      AutoButtonColor = false,
      ZIndex = 15,
    }, card)

    round(actBtn, 8)
    stroke(actBtn, C.white, 1, 0.7)

    copyBtn.Activated:Connect(function()
      if tbCopy(entry.id) then
        copyBtn.Text = "OK ✓"
        setStatus("ID " .. entry.id .. " disalin", C.ok)
      else
        copyBtn.Text = "ID: " .. entry.id
        setStatus("clipboard tidak tersedia • ID " .. entry.id, C.warn)
      end

      task.delay(1.6, function()
        if copyBtn and copyBtn.Parent then
          copyBtn.Text = "SALIN"
        end
      end)
    end)

    if entry.catKey == "Audio" then
      local playBtn = mk("TextButton", {
        Size = UDim2.fromOffset(34, 28),
        Position = UDim2.new(1, -166, 0.5, -14),
        BackgroundColor3 = C.card,
        Text = "▶",
        TextColor3 = C.ok,
        Font = Enum.Font.GothamBlack,
        TextSize = 12,
        AutoButtonColor = false,
        ZIndex = 15,
      }, card)

      round(playBtn, 8)
      stroke(playBtn, C.ok, 1, 0.6)

      playBtn.Activated:Connect(function()
        local playing = tbTogglePreview(entry.id)
        playBtn.Text = playing and "■" or "▶"
      end)
    end

    actBtn.Activated:Connect(function()
      if actBtn.Text ~= "IMPORT" then
        return
      end

      actBtn.Text = "..."
      setStatus("IMPORT " .. entry.catKey:upper() .. " " .. entry.id, C.warn)

      task.spawn(function()
        local cat

        for _, c in ipairs(TB_CATS) do
          if c.key == entry.catKey then
            cat = c
          end
        end

        local ok, msg = tbImport(cat or tbCat, entry.id)
        actBtn.Text = ok and "DONE" or "GAGAL"
        setStatus(tostring(msg), ok and C.ok or C.danger)

        if not ok then
          notify(__s("FAIL"), tostring(msg), false)
        end

        task.wait(1.8)

        if actBtn and actBtn.Parent then
          actBtn.Text = "IMPORT"
        end
      end)
    end)
  end

  local function tbFetchDetails(ids)
    local map = {}

    if #ids == 0 then
      return map
    end

    local data = tbHttpJson("https://apis.roblox.com/toolbox-service/v1/items/details?assetIds="
      .. table.concat(ids, ","))

    if data and type(data.data) == "table" then
      for _, it in ipairs(data.data) do
        local a = it.asset or {}

        if a.id then
          map[a.id] = { name = a.name, creator = it.creator and it.creator.name }
        end
      end
    end

    return map
  end

  local function tbSearch(append)
    local q = tbBox.Text:gsub("^%s+", ""):gsub("%s+$", "")

    if not append then
      tbQuery = q
      tbPageNum = 0
      tbClearList()
    end

    tbToken = tbToken + 1
    local token = tbToken
    tbEmpty.Visible = false
    tbGo.Text = "..."

    setStatus("MENCARI " .. tbCat.key:upper() .. " • "
      .. (tbQuery ~= "" and tbQuery or "populer"), C.warn)

    task.spawn(function()
      local directId = not append and tbQuery:match("^%d+$") and tonumber(tbQuery)

      if directId then
        local det = tbFetchDetails({ directId })

        if token ~= tbToken then
          return
        end

        local d = det[directId]

        tbMakeCard({
          id = directId,
          name = d and d.name or "Asset " .. directId,
          creator = d and d.creator,
          catKey = tbCat.key,
        })

        setStatus("ID " .. directId .. " • " .. tbCat.key, C.ok)
        tbGo.Text = "CARI"
        return
      end

      local url = ("https://apis.roblox.com/toolbox-service/v1/marketplace/%d?limit=30&pageNumber=%d&keyword=%s&sortType=0"):format(
        tbCat.id, tbPageNum, HttpService:UrlEncode(tbQuery)
      )

      local data, err = tbHttpJson(url)

      if token ~= tbToken then
        return
      end

      tbGo.Text = "CARI"

      if not data or type(data.data) ~= "table" then
        tbEmpty.Text = [[
PENCARIAN GAGAL
]] .. tostring(err)

        tbEmpty.Visible = true

        setStatus("TOOLBOX ERROR: " .. tostring(err), C.danger)
        return
      end

      local ids = {}

      for _, it in ipairs(data.data) do
        if it.id then
          ids[#ids + 1] = it.id
        end
      end

      local det = tbFetchDetails(ids)

      if token ~= tbToken then
        return
      end

      if tbMoreBtn then
        tbMoreBtn:Destroy()
        tbMoreBtn = nil
      end

      for _, id in ipairs(ids) do
        local d = det[id]

        tbMakeCard({
          id = id,
          name = d and d.name or "Asset " .. id,
          creator = d and d.creator,
          catKey = tbCat.key,
        })
      end

      if #ids == 0 and tbOrder == 0 then
        tbEmpty.Text = "TIDAK ADA HASIL"
        tbEmpty.Visible = true
      end

      if #ids >= 30 then
        tbOrder = tbOrder + 1

        tbMoreBtn = mk("TextButton", {
          Size = UDim2.new(1, -4, 0, 30),
          BackgroundColor3 = C.card2,
          BackgroundTransparency = 0.42,
          Text = "MUAT LEBIH BANYAK",
          TextColor3 = C.cyan,
          Font = Enum.Font.GothamBlack,
          TextSize = 10,
          AutoButtonColor = false,
          LayoutOrder = 999999,
          ZIndex = 14,
        }, tbList)

        round(tbMoreBtn, 10)
        stroke(tbMoreBtn, C.cyan, 1, 0.6)

        tbMoreBtn.Activated:Connect(function()
          tbPageNum = tbPageNum + 1
          tbSearch(true)
        end)
      end

      setStatus(("TOOLBOX • %s • %d HASIL"):format(tbCat.key:upper(), tbOrder), C.ok)
    end)
  end

  for _, cat in ipairs(TB_CATS) do
    chips[cat.key].Activated:Connect(function()
      tbCat = cat
      refreshChips()
      tbSearch(false)
    end)
  end

  tbGo.Activated:Connect(function() tbSearch(false) end)

  tbBox.FocusLost:Connect(function(enter)
    if enter then
      tbSearch(false)
    end
  end)

  refreshChips()

  local spoofPage = __buildSpoofPage({
    mk = mk,
    round = round,
    stroke = stroke,
    gradient = gradient,
    label = label,
    glass = glass,
    C = C,
    content = spoofWin.body,
    gui = gui,
    setStatus = setStatus,
    notify = notify,
    httpReq = httpReq,
  })
  spoofPage.Visible = true

  local musicPage = __buildMusicPage({
    mk = mk,
    round = round,
    stroke = stroke,
    gradient = gradient,
    label = label,
    glass = glass,
    C = C,
    content = musicWin.body,
    gui = gui,
    setStatus = setStatus,
    notify = notify,
    httpReq = httpReq,
    compact = true,
  })

  musicPage.Visible = true

  local chatPage = __buildChatPage({
    mk = mk,
    round = round,
    stroke = stroke,
    gradient = gradient,
    label = label,
    glass = glass,
    C = C,
    content = chatWin.body,
    gui = gui,
    setStatus = setStatus,
    notify = notify,
    httpReq = httpReq,
  })

  chatPage.Visible = true

  local bypassPage = __buildBypassPage({
    mk = mk,
    round = round,
    stroke = stroke,
    gradient = gradient,
    label = label,
    glass = glass,
    C = C,
    content = bypassWin.body,
    gui = gui,
    setStatus = setStatus,
    notify = notify,
    httpReq = httpReq,
  })

  bypassPage.Visible = true

  for _, k in ipairs({ "IMAGE", "ANIM", "MODEL" }) do
    local upPage = XYUREI_CONFIG.__UPLOAD.build({
      mk = mk,
      round = round,
      stroke = stroke,
      gradient = gradient,
      label = label,
      glass = glass,
      C = C,
      content = WS.upWin[k].body,
      gui = gui,
      setStatus = setStatus,
      notify = notify,
      httpReq = httpReq,
      kind = XYUREI_CONFIG.__UPLOAD.kinds[k],
    })

    upPage.Visible = true
  end

  XYUREI_CONFIG.__IMG3D.build({
    mk = mk,
    round = round,
    stroke = stroke,
    gradient = gradient,
    label = label,
    glass = glass,
    C = C,
    content = WS.upWin.IMG3D.body,
    gui = gui,
    setStatus = setStatus,
    notify = notify,
    httpReq = httpReq,
  })

  do
    local okRp, rpPage = pcall(XYUREI_CONFIG.__REPLACE.build, {
      mk = mk,
      round = round,
      stroke = stroke,
      gradient = gradient,
      label = label,
      glass = glass,
      C = C,
      content = WS.upWin.REPLACE.body,
      gui = gui,
      setStatus = setStatus,
      notify = notify,
      httpReq = httpReq,
    })

    if okRp and rpPage then
      rpPage.Visible = true
    else
      warn("[XYUREI] Replace Tool gagal dibuat: " .. tostring(rpPage))
    end
  end

  exploreBtn.Activated:Connect(function() showPage("dash") end)

  for key, nb in pairs(navButtons) do
    if key == "landing" then
      nb.Activated:Connect(function() showPage("landing") end)
    elseif key ~= "dash" then
      nb.Activated:Connect(function()
        if WS.list[key] then
          WS.toggle(key)
        else
          showPage(key)
        end
      end)
    end
  end

  dashMusicBtn.Activated:Connect(function() WS.toggle("MUSIC") end)
  dashScanBtn.Activated:Connect(scanNow)

  for key, b in pairs(dashButtons) do
    local pop = b:FindFirstChildOfClass("UIScale")

    b.Activated:Connect(function()
      if WS.list[key] then
        WS.toggle(key)
      else
        showPage(key)
      end
    end)

    b.MouseEnter:Connect(function()
      TweenService:Create(b, TweenInfo.new(0.15), {
        BackgroundTransparency = navOpen[key] and 0.05 or 0.24,
      }):Play()

      if pop then
        WS.tw(pop, 0.18, { Scale = 1.03 })
      end
    end)

    b.MouseLeave:Connect(function()
      TweenService:Create(b, TweenInfo.new(0.15), {
        BackgroundTransparency = navOpen[key] and 0.12 or 0.38,
      }):Play()

      if pop then
        WS.tw(pop, 0.18, { Scale = 1 })
      end
    end)

    b.MouseButton1Down:Connect(function()
      if pop then
        WS.tw(pop, 0.08, { Scale = 0.95 })
      end
    end)

    b.MouseButton1Up:Connect(function()
      if pop then
        WS.tw(pop, 0.2, { Scale = 1.03 }, Enum.EasingStyle.Back)
      end
    end)
  end

  backBtn.Activated:Connect(function()
    if currentPage == "dash" then
      showPage("landing")
    else
      showPage("dash")
    end
  end)

  do
    local resizing = false
    local resizeStart, resizeStartSize

    resizeGrip.InputBegan:Connect(function(input)
      if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        resizing = true
        resizeStart = input.Position
        resizeStartSize = main.Size
      end
    end)

    resizeGrip.InputEnded:Connect(function(input)
      if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        resizing = false
      end
    end)

    UserInputService.InputChanged:Connect(function(input)
      if not resizing then
        return
      end

      if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - resizeStart
        local newW = math.clamp(resizeStartSize.X.Offset + delta.X / UI_SCALE, MIN_W, MAX_W)
        local newH = math.clamp(resizeStartSize.Y.Offset + delta.Y / UI_SCALE, MIN_H, MAX_H)
        main.Size = UDim2.fromOffset(newW, newH)
        expandedPosition = main.Position
      end
    end)
  end

  do
    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil

    local function inside(btn, pos)
      if not btn.Visible then
        return false
      end

      local p, s = btn.AbsolutePosition, btn.AbsoluteSize
      return pos.X >= p.X and pos.X <= p.X + s.X and pos.Y >= p.Y and pos.Y <= p.Y + s.Y
    end

    header.InputBegan:Connect(function(input)
      if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        if inside(closeBtn, input.Position) or inside(minBtn, input.Position)
          or inside(backBtn, input.Position) then
          return
        end

        dragging = true
        dragStart = input.Position
        startPos = main.Position

        WS.front("MAIN")
        WS.lift("MAIN", true)

        input.Changed:Connect(function()
          if input.UserInputState == Enum.UserInputState.End then
            dragging = false
            WS.lift("MAIN", false)
          end
        end)
      end
    end)

    header.InputChanged:Connect(function(input)
      if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
      end
    end)

    UserInputService.InputChanged:Connect(function(input)
      if dragging and input == dragInput and mainVisible then
        local delta = input.Position - dragStart

        main.Position = UDim2.new(
          startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale,
          startPos.Y.Offset + delta.Y
        )

        expandedPosition = main.Position
      end
    end)
  end

  do
    local ldrag, lmoved, lstart, lpos = false, false, nil, nil

    launcher.InputBegan:Connect(function(input)
      if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        ldrag = true
        lmoved = false
        lstart = input.Position
        lpos = launcher.Position

        input.Changed:Connect(function()
          if input.UserInputState == Enum.UserInputState.End then
            ldrag = false

            if not lmoved then
              setMainVisible(not mainVisible)
            end
          end
        end)
      end
    end)

    UserInputService.InputChanged:Connect(function(input)
      if not ldrag then
        return
      end

      if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - lstart

        if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then
          lmoved = true
        end

        if lmoved then
          launcher.Position = UDim2.new(
            lpos.X.Scale, lpos.X.Offset + delta.X, lpos.Y.Scale, lpos.Y.Offset + delta.Y
          )
        end
      end
    end)
  end

  minBtn.Activated:Connect(function() setMainVisible(false) end)
  closeBtn.Activated:Connect(function() gui:Destroy() end)

  local function hoverable(btn, baseCol, hoverCol)
    btn.MouseEnter:Connect(function()
      TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = hoverCol }):Play()
    end)

    btn.MouseLeave:Connect(function()
      TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = baseCol }):Play()
    end)
  end

  hoverable(minBtn, C.card, C.card2)
  hoverable(backBtn, C.card, C.card2)
  hoverable(closeBtn, Color3.fromRGB(36, 36, 44), Color3.fromRGB(70, 70, 82))

  local CLICK_SOUND_ID = "rbxassetid://83374956945112"
  local CLICK_VOLUME = 0.8

  local clickSound = mk(
    "Sound", { Name = "XyureiClick", SoundId = CLICK_SOUND_ID, Volume = CLICK_VOLUME }, gui
  )

  task.spawn(function()
    pcall(function() game:GetService("ContentProvider"):PreloadAsync({ clickSound }) end)
  end)

  local function playClick()
    pcall(function()
      clickSound.TimePosition = 0
      clickSound:Play()
    end)
  end

  local hooked = setmetatable({}, { __mode = "k" })

  local function hookClick(o)
    if hooked[o] then
      return
    end

    if o:IsA("GuiButton") then
      hooked[o] = true
      o.Activated:Connect(playClick)
    elseif o:IsA("TextBox") then
      hooked[o] = true
      o.Focused:Connect(playClick)
    end
  end

  for _, d in ipairs(gui:GetDescendants()) do
    hookClick(d)
  end

  gui.DescendantAdded:Connect(hookClick)
  setStatus("SIAP • TEKAN MULAI IMPORT", C.ok)
  updateCount()
  showPage("landing")

  task.delay(0.3, function()
    if gui and gui.Parent then
      scanNow()
    end
  end)

  print("[TOOLS ENGINE] StudioLite Engine v2 loaded")
end

__buildXyureiGui()