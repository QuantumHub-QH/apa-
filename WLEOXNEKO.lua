--[[
============================================================
  MELSS x MEDI  |  RBXM / RBXL IMPORTER  +  TOOLBOX PC
  UI     : Liquid Glass (pink • violet)
  Engine : MxM Engine (modul) — parser biner & XML, bangun RBXL/RBXM,
           aktivasi layanan, runtime script, editor Studio Lite
============================================================
]]--

if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local AssetService = game:GetService("AssetService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local CoreDest = PlayerGui
pcall(function()
    local probe = Instance.new("Folder")
    probe.Name = "__MXM_PROBE"
    probe.Parent = CoreGui
    probe:Destroy()
    CoreDest = CoreGui
end)

-- =====================================================================
--                    MXM ENGINE  •  IMPORTER RBXL / RBXM
--   [1] util anchor  [2] parser biner  [3] bridge Studio Lite  [4] property
--   [5] bangun RBXL  [6] parser XML  [7] import RBXM  [8] runtime
--   [9] aktivasi  [10] pemindai file  [11] hook editor
-- =====================================================================
local Engine = (function()
-- penyimpanan isi script hasil import (disimpan di _G supaya tetap ada kalau script dijalankan ulang)
_G.MXM_SOURCES = _G.MXM_SOURCES or {}
_G.MXM_SOURCES_BY_REF = _G.MXM_SOURCES_BY_REF or {}
local SOURCES = _G.MXM_SOURCES
local SOURCES_BY_REF = _G.MXM_SOURCES_BY_REF

-- ─────────────── [1] UTIL • AUTO ANCHOR (hasil spawn / import) ───────────────
local function anchorPart(p)
    if not p or not p:IsA("BasePart") then return end
    pcall(function()
        if p:GetAttribute("MXM_FileAnchored") == nil then
            p:SetAttribute("MXM_FileAnchored", p.Anchored)
        end
        p:SetAttribute("MXM_AutoAnchored", true)
        p.Anchored = true
        p.AssemblyLinearVelocity = Vector3.zero
        p.AssemblyAngularVelocity = Vector3.zero
    end)
end
local function anchorTree(root)
    if typeof(root) ~= "Instance" then return 0 end
    local n = 0
    if root:IsA("BasePart") then anchorPart(root); n += 1 end
    local okD, desc = pcall(function() return root:GetDescendants() end)
    if okD and desc then
        for i, d in ipairs(desc) do
            if d:IsA("BasePart") then anchorPart(d); n += 1 end
            if i % 400 == 0 then task.wait() end
        end
    end
    return n
end
-- anchor sekarang + jaga terus: part baru yg muncul & re-check berkala
local function lockAnchored(root)
    if typeof(root) ~= "Instance" then return end
    anchorTree(root)
    pcall(function()
        root.DescendantAdded:Connect(function(d)
            if d:IsA("BasePart") then anchorPart(d) end
        end)
    end)
    task.spawn(function()
        for _, delay in ipairs({0.3, 1, 2.5}) do
            task.wait(delay)
            if not root.Parent then return end
            anchorTree(root)
        end
    end)
end

-- ─────────────── [2] PARSER BINER (RBXL / RBXM) ───────────────
if type(string.unpack) ~= "function" then
    warn("[MxM RBXL] string.unpack tidak tersedia. Binary RBXL tidak dapat dibaca.")
end
local BINARY_BIT32_OK = type(bit32) == "table"
local _rrotate = BINARY_BIT32_OK and bit32.rrotate or nil
if type(_rrotate) ~= "function" then
    _rrotate = function(x, n)
        x = x % 4294967296
        n = n % 32
        if n == 0 then return x end
        local p = 2 ^ n
        return (math.floor(x / p) + (x % p) * (2 ^ (32 - n))) % 4294967296
    end
end

local function Buffer(str, allowOverflows)
    local Stream = { Offset = 0, Source = str, Length = string.len(str), AllowOverflows = (allowOverflows == nil and true) or allowOverflows }
    function Stream:read(len, shift)
        len = len or 1; shift = (shift == nil and true) or shift
        local dat = string.sub(self.Source, self.Offset + 1, self.Offset + len)
        if shift then self:seek(len) end
        return dat
    end
    function Stream:seek(len) self.Offset = math.clamp(self.Offset + len, 0, self.Length) end
    function Stream:readNumber(fmt, shift)
        fmt = fmt or "I1"
        if type(string.unpack) ~= "function" then
            error("string.unpack tidak tersedia di environment ini")
        end
        local size
        if type(string.packsize) == "function" then
            size = string.packsize(fmt)
        else
            local f = tostring(fmt):gsub("^[<>!=@]", "")
            local sizes = {I1=1,i1=1,I2=2,i2=2,I4=4,i4=4,I8=8,i8=8,f=4,d=8}
            size = sizes[f]
            if not size then error("Unsupported pack format: "..tostring(fmt)) end
        end
        local chunk = self:read(size, shift)
        if #chunk ~= size then
            error(("Unexpected EOF while reading %s (%d/%d bytes)"):format(tostring(fmt), #chunk, size))
        end
        return string.unpack(fmt, chunk)
    end
    function Stream:append(s) self.Source = self.Source .. s; self.Length = #self.Source end
    function Stream:toEnd() self.Offset = self.Length end
    return Stream
end

local function transformInt(x) return (x % 2 == 0) and (x / 2) or (-(x + 1) / 2) end
local function rbxF32(x) x = _rrotate(x, 1); return string.unpack(">f", string.pack(">I4", x)) end
local basicTypes = {}
function basicTypes.String(buffer) return buffer:read(buffer:readNumber("<I4")) end
function basicTypes.Int32(buffer) return transformInt(buffer:readNumber(">I4")) end
function basicTypes.Int64(buffer) return transformInt(buffer:readNumber(">I8")) end
function basicTypes.Float32(buffer) return rbxF32(buffer:readNumber(">I4")) end
function basicTypes.Float64(buffer) return buffer:readNumber("<d") end
function basicTypes.InterleaveArrayWithSize(buffer, count, sizeof)
    if count < 0 then return Buffer("", false) end
    local stream = buffer:read(count * sizeof); local out = table.create(count)
    for i = 1, count do
        local chunk = table.create(sizeof)
        for s = 0, sizeof - 1 do
            local bitPos = i + (count * s); chunk[s+1] = string.sub(stream, bitPos, bitPos)
        end
        out[i] = table.concat(chunk)
    end
    return Buffer(table.concat(out), false)
end
function basicTypes.unsignedIntArray(buffer, count)
    if count < 1 then return {} end
    local o = table.create(count); local strings = basicTypes.InterleaveArrayWithSize(buffer, count, 4)
    for i = 1, count do o[i] = strings:readNumber("<I4") end
    return o
end
function basicTypes.Int32Array(buffer, count)
    if count < 1 then return {} end
    local o = table.create(count); local strings = basicTypes.InterleaveArrayWithSize(buffer, count, 4)
    for i = 1, count do o[i] = basicTypes.Int32(strings) end
    return o
end
function basicTypes.Int64Array(buffer, count)
    if count < 1 then return {} end
    local o = table.create(count); local strings = basicTypes.InterleaveArrayWithSize(buffer, count, 8)
    for i = 1, count do o[i] = basicTypes.Int64(strings) end
    return o
end
function basicTypes.RbxF32Array(buffer, count)
    if count < 1 then return {} end
    local o = table.create(count); local strings = basicTypes.InterleaveArrayWithSize(buffer, count, 4)
    for i = 1, count do o[i] = basicTypes.Float32(strings) end
    return o
end
function basicTypes.RefArray(buffer, count)
    if count < 1 then return {} end
    local o = table.create(count); local refs = basicTypes.Int32Array(buffer, count); local last = 0
    for i = 1, count do local ref = last + refs[i]; o[i] = ref; last = ref end
    return o
end

local function lz4(lz4data)
    local input = Buffer(lz4data, false)
    local compressedLen = input:readNumber("<I4")
    local decompressedLen = input:readNumber("<I4")
    local reserved = input:readNumber("<I4")
    if reserved ~= 0 then error("not lz4") end
    if compressedLen == 0 then return input:read(decompressedLen) end
    local raw = input:read(compressedLen)
    local pos = 1
    local out = table.create(decompressedLen)
    local outLen = 0
    local function readByte()
        if pos > #raw then error("LZ4 unexpected end") end
        local b = string.byte(raw, pos)
        pos += 1
        return b
    end
    local function extLen(base)
        local len = base
        if base == 15 then
            while true do
                local b = readByte()
                len += b
                if b ~= 255 then break end
            end
        end
        return len
    end
    while outLen < decompressedLen do
        local token = readByte()
        local literalLen = extLen(bit32.rshift(token, 4))
        for _ = 1, literalLen do
            outLen += 1
            out[outLen] = string.char(readByte())
        end
        if outLen >= decompressedLen then break end
        local offset = readByte() + bit32.lshift(readByte(), 8)
        if offset <= 0 or offset > outLen then error("LZ4 invalid match offset") end
        local matchLen = extLen(bit32.band(token, 15)) + 4
        local srcIndex = outLen - offset + 1
        for _ = 1, matchLen do
            outLen += 1
            out[outLen] = out[srcIndex]
            srcIndex += 1
            if outLen >= decompressedLen then break end
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
        local b0, b1, b2 = string.byte(str, i, i+2)
        local b = bit32.lshift(b0, 16) + bit32.lshift(b1 or 0, 8) + (b2 or 0)
        table.insert(out, chars:sub(bit32.extract(b, 18, 6)+1, bit32.extract(b, 18, 6)+1))
        table.insert(out, chars:sub(bit32.extract(b, 12, 6)+1, bit32.extract(b, 12, 6)+1))
        table.insert(out, b1 and chars:sub(bit32.extract(b, 6, 6)+1, bit32.extract(b, 6, 6)+1) or "=")
        table.insert(out, b2 and chars:sub(bit32.band(b, 63)+1, bit32.band(b, 63)+1) or "=")
    end
    return table.concat(out)
end
local function _bytesToString(v)
    if type(v) == "string" then return v end
    local ok, out = pcall(function()
        if type(buffer) == "table" and type(buffer.tostring) == "function" then return buffer.tostring(v) end
        return nil
    end)
    if ok and type(out) == "string" then return out end
    local ok2, out2 = pcall(function()
        if type(buffer) == "table" and type(buffer.len) == "function" and type(buffer.readu8) == "function" then
            local n = buffer.len(v)
            local parts = table.create(math.ceil(n / 4096))
            local k = 0
            for i = 0, n - 1, 4096 do
                local e = math.min(n - 1, i + 4095)
                local chars = table.create(e - i + 1)
                for j = i, e do chars[j - i + 1] = string.char(buffer.readu8(v, j)) end
                k += 1
                parts[k] = table.concat(chars)
            end
            return table.concat(parts)
        end
        return nil
    end)
    if ok2 and type(out2) == "string" then return out2 end
    return nil
end
local function _zstdViaEncodingService(data)
    local ok, result = pcall(function()
        local EncodingService = game:GetService("EncodingService")
        local CompressionAlgorithm = Enum.CompressionAlgorithm
        if type(buffer) ~= "table" or type(buffer.fromstring) ~= "function" then error("buffer API unavailable") end
        if not CompressionAlgorithm or not CompressionAlgorithm.Zstd then error("Zstd enum unavailable") end
        local compressed = buffer.fromstring(data)
        local decoded = EncodingService:DecompressBuffer(compressed, CompressionAlgorithm.Zstd)
        local text = _bytesToString(decoded)
        if not text then error("failed to convert decompressed buffer") end
        return text
    end)
    return ok and result or nil
end
local function _zstdViaJSON(data)
    local zbase64 = b64encode(data)
    local ok, result = pcall(function()
        local x = HttpService:JSONDecode('{"m":null,"t":"buffer","zbase64":"' .. zbase64 .. '"}')
        local text = _bytesToString(x)
        if not text then error("JSONDecode buffer bridge missing") end
        return text
    end)
    return ok and result or nil
end
local function zstd(stream)
    local out = _zstdViaEncodingService(stream)
    if out then return out end
    out = _zstdViaJSON(stream)
    if out then return out end
    error("ZSTD decompressor tidak tersedia/compatible di environment ini")
end

local function _readVector3(buffer, count)
    local xs = basicTypes.RbxF32Array(buffer, count)
    local ys = basicTypes.RbxF32Array(buffer, count)
    local zs = basicTypes.RbxF32Array(buffer, count)
    local out = table.create(count)
    for i = 1, count do out[i] = Vector3.new(xs[i], ys[i], zs[i]) end
    return out
end
local function _readColor3(buffer, count)
    local rs = basicTypes.RbxF32Array(buffer, count)
    local gs = basicTypes.RbxF32Array(buffer, count)
    local bs = basicTypes.RbxF32Array(buffer, count)
    local out = table.create(count)
    for i = 1, count do out[i] = Color3.new(rs[i], gs[i], bs[i]) end
    return out
end
local function _readVector2(buffer, count)
    local xs = basicTypes.RbxF32Array(buffer, count)
    local ys = basicTypes.RbxF32Array(buffer, count)
    local out = table.create(count)
    for i = 1, count do out[i] = Vector2.new(xs[i], ys[i]) end
    return out
end

local RBXL_ROTATION_MATRICES = {
    [0x02] = { 1, 0, 0,  0, 1, 0,  0, 0, 1},
    [0x03] = { 1, 0, 0,  0, 0,-1,  0, 1, 0},
    [0x05] = { 1, 0, 0,  0,-1, 0,  0, 0,-1},
    [0x06] = { 1, 0, 0,  0, 0, 1,  0,-1, 0},
    [0x07] = { 0, 1, 0,  1, 0, 0,  0, 0,-1},
    [0x09] = { 0, 0, 1,  1, 0, 0,  0, 1, 0},
    [0x0A] = { 0,-1, 0,  1, 0, 0,  0, 0, 1},
    [0x0C] = { 0, 0,-1,  1, 0, 0,  0,-1, 0},
    [0x0D] = { 0, 1, 0,  0, 0, 1,  1, 0, 0},
    [0x0E] = { 0, 0,-1,  0, 1, 0,  1, 0, 0},
    [0x10] = { 0,-1, 0,  0, 0,-1,  1, 0, 0},
    [0x11] = { 0, 0, 1,  0,-1, 0,  1, 0, 0},
    [0x14] = {-1, 0, 0,  0, 1, 0,  0, 0,-1},
    [0x15] = {-1, 0, 0,  0, 0, 1,  0, 1, 0},
    [0x17] = {-1, 0, 0,  0,-1, 0,  0, 0, 1},
    [0x18] = {-1, 0, 0,  0, 0,-1,  0,-1, 0},
    [0x19] = { 0, 1, 0, -1, 0, 0,  0, 0, 1},
    [0x1B] = { 0, 0,-1, -1, 0, 0,  0, 1, 0},
    [0x1C] = { 0,-1, 0, -1, 0, 0,  0, 0,-1},
    [0x1E] = { 0, 0, 1, -1, 0, 0,  0,-1, 0},
    [0x1F] = { 0, 1, 0,  0, 0,-1, -1, 0, 0},
    [0x20] = { 0, 0, 1,  0, 1, 0, -1, 0, 0},
    [0x22] = { 0,-1, 0,  0, 0, 1, -1, 0, 0},
    [0x23] = { 0, 0,-1,  0,-1, 0, -1, 0, 0},
}
local function _cframeFromRotationId(id, p)
    local m = RBXL_ROTATION_MATRICES[id]
    if not m then return nil end
    return CFrame.new(p.X, p.Y, p.Z, m[1],m[2],m[3], m[4],m[5],m[6], m[7],m[8],m[9])
end
local function _readCFrames(buffer, count)
    local ids = table.create(count)
    local rotations = table.create(count)
    for i = 1, count do
        local id = string.byte(buffer:read())
        if id == nil then error("CFrame rotation ID terpotong") end
        ids[i] = id
        if id == 0 then
            local m = table.create(9)
            for j = 1, 9 do m[j] = buffer:readNumber("<f") end
            rotations[i] = m
        elseif not RBXL_ROTATION_MATRICES[id] then
            error(("CFrame rotation ID tidak dikenal: 0x%02X"):format(id))
        end
    end
    local positions = _readVector3(buffer, count)
    local out = table.create(count)
    for i = 1, count do
        local p = positions[i]
        if ids[i] == 0 then
            local m = rotations[i]
            out[i] = CFrame.new(p.X,p.Y,p.Z, m[1],m[2],m[3], m[4],m[5],m[6], m[7],m[8],m[9])
        else
            out[i] = _cframeFromRotationId(ids[i], p)
        end
    end
    return out
end
local function _quatToCFrame(qx, qy, qz, qw, p)
    local xx, yy, zz = qx*qx, qy*qy, qz*qz
    local xy, xz, yz = qx*qy, qx*qz, qy*qz
    local wx, wy, wz = qw*qx, qw*qy, qw*qz
    return CFrame.new(
        p.X, p.Y, p.Z,
        1 - 2*(yy + zz), 2*(xy - wz),     2*(xz + wy),
        2*(xy + wz),     1 - 2*(xx + zz), 2*(yz - wx),
        2*(xz - wy),     2*(yz + wx),     1 - 2*(xx + yy)
    )
end
local function _readCFrameQuats(buffer, count)
    local ids = table.create(count)
    local quats = table.create(count)
    for i = 1, count do
        local id = string.byte(buffer:read())
        if id == nil then error("CFrameQuat ID terpotong") end
        ids[i] = id
        if id == 0 then
            quats[i] = { buffer:readNumber("<f"), buffer:readNumber("<f"), buffer:readNumber("<f"), buffer:readNumber("<f") }
        elseif not RBXL_ROTATION_MATRICES[id] then
            error(("CFrameQuat rotation ID tidak dikenal: 0x%02X"):format(id))
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
    if bit32.band(mask, 0x01) ~= 0 then table.insert(ids, Enum.NormalId.Right) end
    if bit32.band(mask, 0x02) ~= 0 then table.insert(ids, Enum.NormalId.Top) end
    if bit32.band(mask, 0x04) ~= 0 then table.insert(ids, Enum.NormalId.Back) end
    if bit32.band(mask, 0x08) ~= 0 then table.insert(ids, Enum.NormalId.Left) end
    if bit32.band(mask, 0x10) ~= 0 then table.insert(ids, Enum.NormalId.Bottom) end
    if bit32.band(mask, 0x20) ~= 0 then table.insert(ids, Enum.NormalId.Front) end
    local ok, value = pcall(function() return Faces.new(table.unpack(ids)) end)
    return ok and value or mask
end
local function _axesFromMask(mask)
    local ids = {}
    if bit32.band(mask, 0x01) ~= 0 then table.insert(ids, Enum.Axis.X) end
    if bit32.band(mask, 0x02) ~= 0 then table.insert(ids, Enum.Axis.Y) end
    if bit32.band(mask, 0x04) ~= 0 then table.insert(ids, Enum.Axis.Z) end
    local ok, value = pcall(function() return Axes.new(table.unpack(ids)) end)
    return ok and value or mask
end
local function _enumItemByValue(enumType, value)
    if not enumType then return nil end
    for _, item in ipairs(enumType:GetEnumItems()) do
        if item.Value == value then return item end
    end
    return nil
end

local function _decodePropertyArray(buffer, typeID, count, sharedStrings)
    if typeID == 0x01 then
        local a = table.create(count)
        for i=1,count do a[i]=basicTypes.String(buffer) end
        return a
    elseif typeID == 0x02 then
        local a=table.create(count)
        for i=1,count do a[i]=string.byte(buffer:read())~=0 end
        return a
    elseif typeID == 0x03 then
        return basicTypes.Int32Array(buffer,count)
    elseif typeID == 0x04 then
        return basicTypes.RbxF32Array(buffer,count)
    elseif typeID == 0x05 then
        local a=table.create(count)
        for i=1,count do a[i]=basicTypes.Float64(buffer) end
        return a
    elseif typeID == 0x06 then
        local scales = basicTypes.RbxF32Array(buffer, count)
        local offsets = basicTypes.Int32Array(buffer, count)
        local a = table.create(count)
        for i=1,count do a[i] = UDim.new(scales[i], offsets[i]) end
        return a
    elseif typeID == 0x07 then
        local sx = basicTypes.RbxF32Array(buffer, count)
        local sy = basicTypes.RbxF32Array(buffer, count)
        local ox = basicTypes.Int32Array(buffer, count)
        local oy = basicTypes.Int32Array(buffer, count)
        local a = table.create(count)
        for i=1,count do a[i] = UDim2.new(sx[i], ox[i], sy[i], oy[i]) end
        return a
    elseif typeID == 0x08 then
        local a = table.create(count)
        for i=1,count do
            local origin = Vector3.new(buffer:readNumber("<f"), buffer:readNumber("<f"), buffer:readNumber("<f"))
            local direction = Vector3.new(buffer:readNumber("<f"), buffer:readNumber("<f"), buffer:readNumber("<f"))
            a[i] = Ray.new(origin, direction)
        end
        return a
    elseif typeID == 0x09 then
        local a=table.create(count)
        for i=1,count do a[i]=_facesFromMask(string.byte(buffer:read()) or 0) end
        return a
    elseif typeID == 0x0A then
        local a=table.create(count)
        for i=1,count do a[i]=_axesFromMask(string.byte(buffer:read()) or 0) end
        return a
    elseif typeID == 0x0B then
        local raw = basicTypes.unsignedIntArray(buffer,count)
        local a = table.create(count)
        for i=1,count do
            local ok, bc = pcall(BrickColor.new, raw[i])
            a[i] = ok and bc or raw[i]
        end
        return a
    elseif typeID == 0x0C then
        return _readColor3(buffer,count)
    elseif typeID == 0x0D then
        return _readVector2(buffer,count)
    elseif typeID == 0x0E then
        return _readVector3(buffer,count)
    elseif typeID == 0x0F then
        local a=table.create(count)
        for i=1,count do a[i]=Vector2int16.new(buffer:readNumber("<i2"),buffer:readNumber("<i2")) end
        return a
    elseif typeID == 0x10 then
        return _readCFrames(buffer,count)
    elseif typeID == 0x11 then
        return _readCFrameQuats(buffer,count)
    elseif typeID == 0x12 then
        return basicTypes.unsignedIntArray(buffer,count)
    elseif typeID == 0x13 then
        return basicTypes.RefArray(buffer,count)
    elseif typeID == 0x14 then
        local a=table.create(count)
        for i=1,count do
            a[i]=Vector3int16.new(buffer:readNumber("<i2"),buffer:readNumber("<i2"),buffer:readNumber("<i2"))
        end
        return a
    elseif typeID == 0x15 then
        local a=table.create(count)
        for i=1,count do
            local n=buffer:readNumber("<I4")
            local points=table.create(n)
            for j=1,n do
                points[j]=NumberSequenceKeypoint.new(buffer:readNumber("<f"), buffer:readNumber("<f"), buffer:readNumber("<f"))
            end
            local ok, seq=pcall(NumberSequence.new, points)
            a[i]=ok and seq or nil
        end
        return a
    elseif typeID == 0x16 then
        local a=table.create(count)
        for i=1,count do
            local n=buffer:readNumber("<I4")
            local points=table.create(n)
            for j=1,n do
                local t=buffer:readNumber("<f")
                local c=Color3.new(buffer:readNumber("<f"), buffer:readNumber("<f"), buffer:readNumber("<f"))
                buffer:readNumber("<f")
                points[j]=ColorSequenceKeypoint.new(t,c)
            end
            local ok, seq=pcall(ColorSequence.new, points)
            a[i]=ok and seq or nil
        end
        return a
    elseif typeID == 0x17 then
        local a=table.create(count)
        for i=1,count do a[i]=NumberRange.new(buffer:readNumber("<f"),buffer:readNumber("<f")) end
        return a
    elseif typeID == 0x18 then
        local xmin=basicTypes.RbxF32Array(buffer,count)
        local ymin=basicTypes.RbxF32Array(buffer,count)
        local xmax=basicTypes.RbxF32Array(buffer,count)
        local ymax=basicTypes.RbxF32Array(buffer,count)
        local a=table.create(count)
        for i=1,count do a[i]=Rect.new(xmin[i],ymin[i],xmax[i],ymax[i]) end
        return a
    elseif typeID == 0x19 then
        local a=table.create(count)
        for i=1,count do
            local discriminator=string.byte(buffer:read()) or 0
            if discriminator == 0x01 or discriminator == 0x03 then
                local density=buffer:readNumber("<f")
                local friction=buffer:readNumber("<f")
                local elasticity=buffer:readNumber("<f")
                local frictionWeight=buffer:readNumber("<f")
                local elasticityWeight=buffer:readNumber("<f")
                if discriminator == 0x03 then buffer:readNumber("<f") end
                local ok, pp=pcall(PhysicalProperties.new, density, friction, elasticity, frictionWeight, elasticityWeight)
                a[i]=ok and pp or nil
            else
                a[i]=nil
            end
        end
        return a
    elseif typeID == 0x1A then
        local rs=table.create(count)
        local gs=table.create(count)
        local bs=table.create(count)
        for i=1,count do rs[i]=string.byte(buffer:read()) end
        for i=1,count do gs[i]=string.byte(buffer:read()) end
        for i=1,count do bs[i]=string.byte(buffer:read()) end
        local a=table.create(count)
        for i=1,count do a[i]=Color3.fromRGB(rs[i],gs[i],bs[i]) end
        return a
    elseif typeID == 0x1B then
        return basicTypes.Int64Array(buffer,count)
    elseif typeID == 0x1C then
        local idx=basicTypes.unsignedIntArray(buffer,count)
        local a=table.create(count)
        for i=1,count do a[i]=sharedStrings and sharedStrings[idx[i] + 1] or nil end
        return a
    elseif typeID == 0x1E then
        local innerType=string.byte(buffer:read())
        if innerType ~= 0x10 then error("Optional type tidak didukung: "..tostring(innerType)) end
        local values=_readCFrames(buffer,count)
        local presenceType=string.byte(buffer:read())
        if presenceType ~= 0x02 then error("Optional presence type invalid: "..tostring(presenceType)) end
        local a=table.create(count)
        for i=1,count do
            local present=(string.byte(buffer:read()) or 0) ~= 0
            if present then a[i]=values[i] end
        end
        return a
    elseif typeID == 0x1F then
        local values=basicTypes.InterleaveArrayWithSize(buffer,count,16)
        local a=table.create(count)
        for i=1,count do a[i]=values:read(16) end
        return a
    elseif typeID == 0x20 then
        local a=table.create(count)
        for i=1,count do
            local family=basicTypes.String(buffer)
            local weightValue=buffer:readNumber("<I2")
            local styleValue=string.byte(buffer:read()) or 0
            local cached=basicTypes.String(buffer)
            local weight=_enumItemByValue(Enum.FontWeight, weightValue) or Enum.FontWeight.Regular
            local style=_enumItemByValue(Enum.FontStyle, styleValue) or Enum.FontStyle.Normal
            local ok, font=pcall(Font.new, family, weight, style)
            a[i]=ok and font or {Family=family,Weight=weightValue,Style=styleValue,CachedFaceId=cached}
        end
        return a
    elseif typeID == 0x21 then
        return basicTypes.Int64Array(buffer,count)
    elseif typeID == 0x22 then
        local kinds=basicTypes.Int32Array(buffer,count)
        local uriCount=buffer:readNumber("<I4")
        local uris=table.create(uriCount)
        for i=1,uriCount do uris[i]=basicTypes.String(buffer) end
        local objectCount=buffer:readNumber("<I4")
        local objectRefs=basicTypes.RefArray(buffer,objectCount)
        local externalCount=buffer:readNumber("<I4")
        if externalCount > 0 then buffer:read(externalCount * 4) end
        local a=table.create(count)
        local ui, oi=1,1
        for i=1,count do
            if kinds[i] == 1 then
                a[i]=uris[ui]; ui += 1
            elseif kinds[i] == 2 then
                a[i]={__ContentObjectRef=objectRefs[oi]}; oi += 1
            else
                a[i]=""
            end
        end
        return a
    end
    return nil
end

local function parseRBXLBinary(data)
    local r = Buffer(data, false)
    if r:read(14) ~= "<roblox!" .. string.char(137,255,13,10,26,10) then return nil, "RBXL header tidak valid" end
    local version=r:readNumber("<I2")
    if version~=0 then return nil,"RBXL version tidak didukung: "..tostring(version) end
    local classCount=r:readNumber("<I4")
    local instCount=r:readNumber("<I4")
    r:read(8)
    if classCount > 100000 or instCount > 5000000 then return nil, "RBXL header count tidak masuk akal" end
    local chunks={META={},SSTR={},INST={},PROP={},PRNT={},SIGN={},["END\0"]={}}
    while r.Offset < r.Length do
        if r.Length - r.Offset < 16 then return nil, "RBXL chunk header terpotong" end
        local sig=r:read(4)
        local compressed=r:readNumber("<I4")
        local decompressed=r:readNumber("<I4")
        r:read(4)
        if sig=="END\0" then
            local payload=r:read(decompressed)
            chunks[sig][#chunks[sig]+1]={Data=payload}
            break
        end
        local payload
        if compressed==0 then
            payload=r:read(decompressed)
            if #payload ~= decompressed then return nil, "RBXL chunk "..sig.." terpotong" end
        else
            local raw=r:read(compressed)
            if #raw ~= compressed then return nil, "RBXL compressed chunk "..sig.." terpotong" end
            local magic=string.sub(raw,1,4)
            if magic==string.char(40,181,47,253) then
                payload=zstd(raw)
            else
                if type(string.pack) ~= "function" then return nil, "string.pack tidak tersedia untuk LZ4" end
                payload=lz4(string.pack("<I4I4I4", compressed, decompressed, 0) .. raw)
            end
            if #payload ~= decompressed then
                return nil, "RBXL chunk "..sig.." length mismatch: "..#payload.." / "..decompressed
            end
        end
        if chunks[sig] then
            chunks[sig][#chunks[sig]+1]={Data=payload}
        else
            return nil,"RBXL chunk tidak dikenal: "..tostring(sig)
        end
    end
    local shared={}
    for _,ch in ipairs(chunks.SSTR) do
        local b=Buffer(ch.Data,false)
        local ver=b:readNumber("<I4")
        if ver ~= 0 then return nil, "SSTR version tidak didukung: "..tostring(ver) end
        local n=b:readNumber("<I4")
        for i=1,n do
            b:read(16)
            shared[i]=basicTypes.String(b)
        end
    end
    local classes={}; local nodes={}; local serviceRefs={}
    for _,ch in ipairs(chunks.INST) do
        local b=Buffer(ch.Data,false); local cid=b:readNumber("<I4"); local cname=basicTypes.String(b)
        local format=string.byte(b:read()); local n=b:readNumber("<I4"); local refs=basicTypes.RefArray(b,n)
        classes[cid]={Name=cname,Count=n,Refs=refs,IsService=(format==1)}
        local marks={}
        if format==1 then for i=1,n do marks[i]=string.byte(b:read())~=0 end end
        for i,ref in ipairs(refs) do
            nodes[ref]={Ref=ref,ClassId=cid,ClassName=cname,IsService=(format==1),Properties={},PropertyTypes={},Children={},Service=marks[i] or false}
        end
        if format==1 then for _,ref in ipairs(refs) do serviceRefs[ref]=true end end
    end
    for _,ch in ipairs(chunks.PROP) do
        local b=Buffer(ch.Data,false); local cid=b:readNumber("<I4"); local cls=classes[cid]
        if not cls then return nil,"PROP class id tidak ditemukan: "..cid end
        local pname=basicTypes.String(b); local typeID=string.byte(b:read())
        local vals=_decodePropertyArray(b,typeID,cls.Count,shared)
        if vals then
            for i,ref in ipairs(cls.Refs) do
                if nodes[ref] then
                    nodes[ref].Properties[pname]=vals[i]
                    nodes[ref].PropertyTypes[pname]=typeID
                end
            end
        else
            warn(("[MxM RBXL] property skipped: %s (type 0x%02X)"):format(pname, typeID or 0))
        end
    end
    local childToParent={}
    for _,ch in ipairs(chunks.PRNT) do
        local b=Buffer(ch.Data,false); local ver=string.byte(b:read())
        if ver~=0 then return nil,"PRNT version tidak didukung" end
        local n=b:readNumber("<I4"); local children=basicTypes.RefArray(b,n); local parents=basicTypes.RefArray(b,n)
        for i=1,n do childToParent[children[i]]=parents[i] end
    end
    local roots={}
    for ref,node in pairs(nodes) do
        local p=childToParent[ref]
        if p and p~=-1 and nodes[p] then table.insert(nodes[p].Children,node) else table.insert(roots,node) end
    end
    return {Header={ClassCount=classCount,InstanceCount=instCount},Nodes=nodes,Roots=roots,Services=serviceRefs,SharedStrings=shared}, nil
end

-- ─────────────── [3] BRIDGE STUDIO LITE (mesh, editor script) ───────────────
local function getStudioLiteServerFuncs()
    local slFolder = ReplicatedStorage:FindFirstChild("StudioLiteFolder")
    return slFolder and slFolder:FindFirstChild("ServerFunctions")
end
local function triggerServerLoad(idStr)
    local serverFuncs = getStudioLiteServerFuncs()
    if not serverFuncs or not idStr or idStr == "" then return end
    local id = tostring(idStr):match("%d+")
    if id then pcall(function() serverFuncs:InvokeServer("LoadMeshToRuntimeMeshes", tonumber(id)) end) end
end
local FAST_IMPORT = true
local ASSET_WORKERS = 6
local ASSET_QUEUE = {}
local ASSET_SEEN = {}
local function queueServerLoad(value)
    if value == nil or value == "" then return end
    local id
    if type(value) == "number" then id = math.floor(value) else id = tonumber(tostring(value):match("%d+")) end
    if not id or id <= 0 or ASSET_SEEN[id] then return end
    ASSET_SEEN[id] = true
    ASSET_QUEUE[#ASSET_QUEUE + 1] = id
end
local function flushServerLoadsAsync()
    if #ASSET_QUEUE == 0 then return end
    local jobs = ASSET_QUEUE
    ASSET_QUEUE = {}
    ASSET_SEEN = {}
    local cursor = 0
    for _ = 1, math.min(ASSET_WORKERS, #jobs) do
        task.spawn(function()
            while true do
                cursor += 1
                local id = jobs[cursor]
                if not id then break end
                triggerServerLoad(id)
                task.wait()
            end
        end)
    end
end

local SL_CACHE = {}
local function injectStudioLiteUI(scr, sourceMap)
    if not scr:IsA("LuaSourceContainer") then return end
    local path = scr.ClassName .. ":" .. scr.Name
    local realSource = SOURCES[scr] or (sourceMap and sourceMap[path])
    if not realSource then pcall(function() realSource = scr.Source end) end
    if realSource and #realSource > 0 then
        realSource = realSource:gsub(string.char(0) .. "*$", "")
    else
        realSource = ""
    end
    SOURCES[scr] = realSource
    local UI_TEXT = realSource
    local existingTB = scr:FindFirstChild("SL_CodeTextBox")
    if existingTB then
        existingTB.Text = UI_TEXT
        if scr.ClassName == "ModuleScript" then
            local ro = scr:FindFirstChild("SL_1ReadOnly")
            if ro then ro.ContentText = UI_TEXT; ro.Text = UI_TEXT end
        end
        return
    end
    local serverFuncs = getStudioLiteServerFuncs()
    if not serverFuncs then return end
    local map = { Script = "InsertScriptScript", LocalScript = "InsertLocalScriptLocalScript", ModuleScript = "InsertModuleScriptModuleScript" }
    local assetName = map[scr.ClassName]
    if not assetName then return end
    if not SL_CACHE[assetName] then
        pcall(function()
            serverFuncs:InvokeServer("LoadAssetToPlayerGui", assetName)
            local guiF = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild(assetName, 3)
            if guiF then
                SL_CACHE[assetName] = {}
                for _, c in ipairs(guiF:GetChildren()) do table.insert(SL_CACHE[assetName], c:Clone()) end
                serverFuncs:InvokeServer("ClearAssetFromPlayerGui", assetName)
            end
        end)
    end
    if not SL_CACHE[assetName] then return end
    pcall(function()
        for _, c in ipairs(SL_CACHE[assetName]) do c:Clone().Parent = scr end
        local tb = scr:FindFirstChild("SL_CodeTextBox")
        if tb then
            tb.Text = UI_TEXT
            if scr.ClassName == "ModuleScript" then
                local ro = scr:FindFirstChild("SL_1ReadOnly")
                if ro then ro.ContentText = UI_TEXT; ro.Text = UI_TEXT end
            end
        end
    end)
end

-- ─────────────── [4] TERAPKAN PROPERTY + MESH / UNION ───────────────
local function setEnumFromValue(obj, propName, rawValue)
    local okCurrent, current = pcall(function() return obj[propName] end)
    if not okCurrent or typeof(current) ~= "EnumItem" then return false end
    local okType, enumType = pcall(function() return current.EnumType end)
    if not okType or not enumType then return false end
    for _, item in ipairs(enumType:GetEnumItems()) do
        if item.Value == rawValue then
            return pcall(function() obj[propName] = item end)
        end
    end
    return false
end
local READONLY_GEOMETRY_PROPS = {
    MeshId=true, MeshID=true, MeshContent=true, MeshSize=true, InitialSize=true,
    PhysicsData=true, PhysicalConfigData=true, EditableMeshString=true, AssetId=true,
    ChildData=true, ChildData2=true, MeshData=true, MeshData2=true,
}
local SERIALIZED_PROPERTY_ALIAS = {
    size="Size", shape="Shape", Color3uint8="Color", MaterialVariantSerialized="MaterialVariant",
}
local function runtimePropertyName(propName) return SERIALIZED_PROPERTY_ALIAS[propName] or propName end

local function applyDecodedProperty(obj, propName, value, typeID)
    if value == nil then return true end
    if propName == "Source" or propName == "ContentText" then
        if obj:IsA("LuaSourceContainer") and type(value) == "string" then
            local clean = value:gsub(string.char(0) .. "*$", "")
            SOURCES[obj] = clean
            local refKey = obj:GetAttribute("MXM_Ref")
            if refKey ~= nil then SOURCES_BY_REF[tostring(refKey)] = clean end
        end
        return true
    end
    if typeID == 0x13 then return true end
    if typeID == 0x1F or typeID == 0x21 then return true end
    if typeID == 0x22 and type(value) == "table" then return true end
    if READONLY_GEOMETRY_PROPS[propName] then return true end
    local runtimeName = runtimePropertyName(propName)
    if runtimeName == "MaterialVariant" and value == "" then return true end
    if typeID == 0x12 and type(value) == "number" then
        if setEnumFromValue(obj, runtimeName, value) then return true end
    end
    return pcall(function() obj[runtimeName] = value end)
end

local function assetIdFromValue(v)
    if v == nil then return nil end
    if type(v) == "number" then
        if v > 0 then return math.floor(v) end
        return nil
    end
    if type(v) == "string" then
        local id = v:match("rbxassetid://(%d+)") or v:match("[?&]id=(%d+)") or v:match("(%d+)")
        return id and tonumber(id) or nil
    end
    local okUri, uri = pcall(function()
        if typeof(v) == "Content" and v.Uri then return v.Uri end
        return tostring(v)
    end)
    if okUri and uri then
        local id = tostring(uri):match("(%d+)")
        return id and tonumber(id) or nil
    end
    return nil
end
local function contentFromAssetIdCompat(id)
    if not id then return nil end
    local okContent, content = pcall(function()
        if Content and type(Content.fromAssetId) == "function" then return Content.fromAssetId(id) end
        if Content and type(Content.fromUri) == "function" then return Content.fromUri("rbxassetid://" .. tostring(id)) end
        return nil
    end)
    if okContent and content then return content end
    return "rbxassetid://" .. tostring(id)
end
local function detachFirstGeometry(root, wantedClass)
    if not root then return nil end
    local candidate
    if root:IsA("BasePart") and (not wantedClass or root.ClassName == wantedClass) then candidate = root end
    if not candidate then
        for _, d in ipairs(root:GetDescendants()) do
            if d:IsA("BasePart") and (not wantedClass or d.ClassName == wantedClass) then candidate = d; break end
        end
    end
    if not candidate and root:IsA("BasePart") then candidate = root end
    if not candidate then
        for _, d in ipairs(root:GetDescendants()) do
            if d:IsA("BasePart") then candidate = d; break end
        end
    end
    if not candidate then return nil end
    candidate.Parent = nil
    if root ~= candidate then pcall(function() root:Destroy() end) end
    return candidate
end
local function tryGameGetObjectsGeometry(id, wantedClass)
    if not id then return nil end
    local ok, objects = pcall(function() return game:GetObjects("rbxassetid://" .. tostring(id)) end)
    if not ok or type(objects) ~= "table" then return nil end
    for _, root in ipairs(objects) do
        local geo = detachFirstGeometry(root, wantedClass)
        if geo then
            for _, other in ipairs(objects) do
                if other ~= geo and other.Parent == nil then pcall(function() other:Destroy() end) end
            end
            return geo
        end
    end
    for _, root in ipairs(objects) do pcall(function() root:Destroy() end) end
    return nil
end
local function tryAssetServiceMesh(id)
    if not id then return nil, "no mesh id" end
    local content = contentFromAssetIdCompat(id)
    local errors = {}
    local ok1, mesh1 = pcall(function() return AssetService:CreateMeshPartAsync(content, {}) end)
    if ok1 and mesh1 and mesh1:IsA("MeshPart") then return mesh1, "AssetService" end
    if not ok1 then table.insert(errors, tostring(mesh1)) end
    local ok2, mesh2 = pcall(function() return AssetService:CreateMeshPartAsync("rbxassetid://" .. tostring(id), {}) end)
    if ok2 and mesh2 and mesh2:IsA("MeshPart") then return mesh2, "AssetServiceLegacy" end
    if not ok2 then table.insert(errors, tostring(mesh2)) end
    local getObj = tryGameGetObjectsGeometry(id, "MeshPart")
    if getObj and getObj:IsA("BasePart") then return getObj, "GetObjects" end
    return nil, table.concat(errors, " | ")
end
local function serializedSize(p)
    if not p then return nil end
    local s = p.size or p.Size
    if typeof(s) == "Vector3" then
        return Vector3.new(math.max(math.abs(s.X), 0.001), math.max(math.abs(s.Y), 0.001), math.max(math.abs(s.Z), 0.001))
    end
    return nil
end
local function serializedColor(p)
    if not p then return nil end
    local c = p.Color3uint8 or p.Color
    if typeof(c) == "Color3" then return c end
    return nil
end
local function applyBaseVisualState(obj, p)
    if not obj or not obj:IsA("BasePart") or not p then return end
    local s = serializedSize(p)
    if s then pcall(function() obj.Size = s end) end
    if typeof(p.CFrame) == "CFrame" then pcall(function() obj.CFrame = p.CFrame end) end
    local c = serializedColor(p)
    if c then pcall(function() obj.Color = c end) end
    if p.Transparency ~= nil then pcall(function() obj.Transparency = p.Transparency end) end
    if p.Reflectance ~= nil then pcall(function() obj.Reflectance = p.Reflectance end) end
    if p.Material ~= nil and type(p.Material) == "number" then
        pcall(function() setEnumFromValue(obj, "Material", p.Material) end)
    end
    if type(p.Anchored) == "boolean" then pcall(function() obj.Anchored = p.Anchored end) end
end
local function configureSpecialMeshScale(mesh, p)
    if not mesh or not p then return end
    local wantedSize = serializedSize(p)
    local originalSize = p.InitialSize or p.MeshSize
    if wantedSize and typeof(originalSize) == "Vector3"
        and math.abs(originalSize.X) > 1e-6 and math.abs(originalSize.Y) > 1e-6 and math.abs(originalSize.Z) > 1e-6 then
        mesh.Scale = Vector3.new(wantedSize.X / originalSize.X, wantedSize.Y / originalSize.Y, wantedSize.Z / originalSize.Z)
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
    mesh.Name = "__MXM_MeshVisual"
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = "rbxassetid://" .. tostring(meshId)
    local texId = assetIdFromValue(p.TextureID or p.TextureId or p.TextureContent)
    if texId then pcall(function() mesh.TextureId = "rbxassetid://" .. tostring(texId) end) end
    configureSpecialMeshScale(mesh, p)
    mesh.Parent = part
    return part
end
local function isMeshPartOnlyChildClass(className)
    return className == "SurfaceAppearance" or className == "WrapLayer" or className == "WrapTarget"
end
local function nodeNeedsNativeMeshPart(node)
    for _, child in ipairs(node.Children or {}) do
        if child.ClassName == "WrapLayer" or child.ClassName == "WrapTarget" then return true end
    end
    return false
end
local function tryCreateMeshPartNode(node)
    local p = node.Properties or {}
    local meshId = assetIdFromValue(p.MeshId or p.MeshID or p.MeshContent)
    if not meshId then return nil, "unresolved", "MeshId missing" end
    queueServerLoad(meshId)
    queueServerLoad(p.TextureID or p.TextureId or p.TextureContent)
    local needsNative = nodeNeedsNativeMeshPart(node)
    if FAST_IMPORT and not needsNative then
        return makeSpecialMeshFallback(node, meshId), "fallback", "TurboSpecialMesh"
    end
    local native, method = tryAssetServiceMesh(meshId)
    if native then return native, "native", needsNative and "NativeForBaseWrap" or method end
    return makeSpecialMeshFallback(node, meshId), "fallback", needsNative and "BaseWrapFallback" or "SpecialMesh"
end
local function makeCSGVisualFallback(node, assetId)
    local p = node.Properties or {}
    local part = Instance.new("Part")
    part.Name = tostring(p.Name or node.ClassName)
    part.CanCollide = false
    applyBaseVisualState(part, p)
    if assetId then
        local mesh = Instance.new("SpecialMesh")
        mesh.Name = "__MXM_CSGVisual"
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
        if FAST_IMPORT then return makeCSGVisualFallback(node, assetId), "visual" end
        local obj = tryGameGetObjectsGeometry(assetId, node.ClassName)
        if obj then applyBaseVisualState(obj, p); return obj, "asset" end
        local meshPart = tryAssetServiceMesh(assetId)
        if meshPart and meshPart:IsA("BasePart") then applyBaseVisualState(meshPart, p); return meshPart, "mesh" end
        return makeCSGVisualFallback(node, assetId), "visual"
    end
    return makeCSGVisualFallback(node, nil), "proxy"
end
local function preloadNodeAssets(node)
    if not node or not node.Properties then return end
    local p = node.Properties
    local c = node.ClassName
    if c == "MeshPart" then
        queueServerLoad(p.MeshId or p.MeshContent); queueServerLoad(p.TextureID or p.TextureId or p.TextureContent)
    elseif c == "SpecialMesh" then
        queueServerLoad(p.MeshId); queueServerLoad(p.TextureId or p.TextureID)
    elseif c == "Decal" or c == "Texture" then queueServerLoad(p.Texture)
    elseif c == "Shirt" then queueServerLoad(p.ShirtTemplate)
    elseif c == "Pants" then queueServerLoad(p.PantsTemplate)
    elseif c == "ShirtGraphic" then queueServerLoad(p.Graphic)
    elseif c == "UnionOperation" or c == "PartOperation" or c == "IntersectOperation" then queueServerLoad(p.AssetId) end
end

local function setScriptEnabledState(obj, enabled)
    if not obj or not obj:IsA("LuaSourceContainer") then return false end
    enabled = enabled ~= false
    local wrote = false
    if pcall(function() obj.Enabled = enabled end) then wrote = true end
    if pcall(function() obj.Disabled = not enabled end) then wrote = true end
    return wrote
end
local function getOriginalScriptEnabled(obj, node)
    local p = node and node.Properties or {}
    if p.Enabled ~= nil then return p.Enabled == true end
    if p.Disabled ~= nil then return p.Disabled ~= true end
    local okE, e = pcall(function() return obj.Enabled end)
    if okE and type(e) == "boolean" then return e end
    local okD, d = pcall(function() return obj.Disabled end)
    if okD and type(d) == "boolean" then return not d end
    return true
end
local function importedScriptShouldRun(obj)
    if not obj or not obj:IsA("LuaSourceContainer") then return false end
    local o = obj:GetAttribute("MXM_OriginalEnabled")
    if o ~= nil then return o == true end
    local d = obj:GetAttribute("MXM_OriginalDisabled")
    if d ~= nil then return d == false end
    return true
end
local function importRootName(fileName)
    local base = tostring(fileName or "RBXL")
    base = base:gsub("%.[Rr][Bb][Xx][Ll][Xx]?$", "")
    base = base:gsub("[%c/\\:*?\"<>|]", "_")
    base = base:gsub("^%s+", ""):gsub("%s+$", "")
    if base == "" then base = "RBXL" end
    return base .. " IMPORTED"
end
local function reportImportProgress(value, message)
    local cb = _G.MXM_PROGRESS
    if type(cb) == "function" then pcall(cb, value, message) end
end

-- ─────────────── [5] BANGUN RBXL (place) ───────────────
local function buildRBXL(parsed, sourceFileName)
    local made = {}
    local skipped = 0
    local failedProperties = 0
    local progressTotal = math.max(tonumber(parsed.Header and parsed.Header.InstanceCount) or 1, 1)
    local progressMade = 0
    reportImportProgress(0.20, "BUILDING INSTANCES")
    local meshNative, meshFallback, meshUnresolved, csgAsset, csgProxy = 0, 0, 0, 0, 0
    local rootName = importRootName(sourceFileName)
    local oldRoot = workspace:FindFirstChild(rootName)
    if oldRoot then pcall(function() oldRoot:Destroy() end) end
    local importRoot = Instance.new("Folder")
    importRoot.Name = rootName
    importRoot:SetAttribute("MXM_RBXL_IMPORT", true)
    importRoot:SetAttribute("MXM_SourceFile", tostring(sourceFileName or ""))
    importRoot.Parent = nil
    local containers = {}
    local function newServiceFolder(key, displayName)
        local folder = Instance.new("Folder")
        folder.Name = displayName
        folder:SetAttribute("MXM_ServiceKey", key)
        folder.Parent = importRoot
        containers[key] = folder
        return folder
    end
    newServiceFolder("WS","workspace(ws)"); newServiceFolder("RS","replicate storage(rs)")
    newServiceFolder("RF","replicate first(rf)"); newServiceFolder("L","lighting(l)")
    newServiceFolder("P","players(p)"); newServiceFolder("SG","starter gui(sg)")
    newServiceFolder("STP","starter pack(stp)"); newServiceFolder("SP","starter player(sp)")
    newServiceFolder("SPS","starter player script(sps)"); newServiceFolder("SCS","starter character script(scs)")
    newServiceFolder("SSS","serverscriptservice(sss)"); newServiceFolder("SS","server storage(ss)")
    newServiceFolder("TEAM","teams(team)"); newServiceFolder("SND","sound service(sound)")
    newServiceFolder("MAT","material service(mat)"); newServiceFolder("TCS","text chat service(tcs)")
    newServiceFolder("CHAT","chat(chat)"); newServiceFolder("LOC","localization service(loc)")
    newServiceFolder("TEST","test service(test)"); newServiceFolder("HTTP","http service(http)")
    newServiceFolder("INS","insert service(ins)"); newServiceFolder("TWEEN","tween service(tween)")
    local serviceKeyByName = {
        Workspace="WS", ReplicatedStorage="RS", ReplicatedFirst="RF", Lighting="L", Players="P",
        StarterGui="SG", StarterPack="STP", StarterPlayer="SP", StarterPlayerScripts="SPS",
        StarterCharacterScripts="SCS", ServerScriptService="SSS", ServerStorage="SS", Teams="TEAM",
        SoundService="SND", MaterialService="MAT", TextChatService="TCS", Chat="CHAT",
        LocalizationService="LOC", TestService="TEST", HttpService="HTTP", InsertService="INS", TweenService="TWEEN",
    }
    local function routeForNode(node, inheritedKey)
        local className = tostring(node.ClassName or "")
        local nodeName = tostring((node.Properties and node.Properties.Name) or "")
        local direct = serviceKeyByName[className] or serviceKeyByName[nodeName]
        if direct then return direct end
        if inheritedKey == "SP" then
            if className == "StarterPlayerScripts" or nodeName == "StarterPlayerScripts" then return "SPS"
            elseif className == "StarterCharacterScripts" or nodeName == "StarterCharacterScripts" then return "SCS" end
        end
        return inheritedKey or "WS"
    end
    local function rememberStudioLiteState(obj, node)
        if not obj:IsA("BasePart") then return end
        local p = node.Properties or {}
        local originalAnchored
        if type(p.Anchored) == "boolean" then originalAnchored = p.Anchored else pcall(function() originalAnchored = obj.Anchored end) end
        if originalAnchored == nil then originalAnchored = false end
        local originalCanCollide
        if type(p.CanCollide) == "boolean" then originalCanCollide = p.CanCollide else pcall(function() originalCanCollide = obj.CanCollide end) end
        if originalCanCollide == nil then originalCanCollide = true end
        pcall(function()
            obj:SetAttribute("SL_Anchored", originalAnchored)
            obj:SetAttribute("MXM_FileAnchored", originalAnchored)
            obj:SetAttribute("SL_CanCollide", originalCanCollide)
            obj.Anchored = true
        end)
    end
    local function disableImportedScript(obj, node)
        if not obj:IsA("LuaSourceContainer") then return end
        local originalEnabled = getOriginalScriptEnabled(obj, node)
        pcall(function()
            obj:SetAttribute("MXM_OriginalEnabled", originalEnabled)
            obj:SetAttribute("MXM_OriginalDisabled", not originalEnabled)
            obj:SetAttribute("MXM_StagedDisabled", true)
        end)
        setScriptEnabledState(obj, false)
    end
    local function normalizePartGeometry(obj, node)
        if not obj:IsA("BasePart") then return end
        local p = node.Properties or {}
        applyBaseVisualState(obj, p)
        local special = obj:FindFirstChild("__MXM_MeshVisual") or obj:FindFirstChild("__MXM_CSGVisual")
        if special and special:IsA("SpecialMesh") then configureSpecialMeshScale(special, p) end
    end
    local function instantiateNode(node)
        if node.ClassName == "MeshPart" then
            local obj, mode = tryCreateMeshPartNode(node)
            if obj then
                if mode == "native" then meshNative += 1 elseif mode == "fallback" then meshFallback += 1 else meshUnresolved += 1 end
                return obj
            end
            meshUnresolved += 1
            return nil
        end
        if node.ClassName == "UnionOperation" or node.ClassName == "PartOperation" or node.ClassName == "IntersectOperation" then
            local obj, mode = tryLoadPartOperationNode(node)
            if obj then
                if mode == "asset" or mode == "mesh" or mode == "visual" then csgAsset += 1 else csgProxy += 1 end
                return obj
            end
            csgProxy += 1
            return nil
        end
        local ok, obj = pcall(Instance.new, node.ClassName)
        if ok then return obj end
        return nil
    end
    local buildBurstCount = 0
    local function createNode(node, parent, inheritedKey)
        local routeKey = routeForNode(node, inheritedKey)
        if isMeshPartOnlyChildClass(node.ClassName) and (not parent or not parent:IsA("MeshPart")) then
            skipped += 1
            return nil
        end
        local nodeName = tostring((node.Properties and node.Properties.Name) or "")
        local isServiceLike = node.IsService or node.Service or serviceKeyByName[node.ClassName] or serviceKeyByName[nodeName]
        if isServiceLike then
            local target = containers[routeKey] or containers.WS
            for _, child in ipairs(node.Children) do
                createNode(child, target, routeForNode(child, routeKey))
            end
            return nil
        end
        preloadNodeAssets(node)
        local obj = instantiateNode(node)
        if not obj then
            skipped += 1
            for _, child in ipairs(node.Children) do
                createNode(child, parent or containers[routeKey] or containers.WS, routeKey)
            end
            return nil
        end
        made[node.Ref] = obj
        pcall(function()
            obj:SetAttribute("MXM_ImportedObject", true)
            obj:SetAttribute("MXM_Ref", tostring(node.Ref))
        end)
        if node.Properties.Name ~= nil then
            if not pcall(function() obj.Name = tostring(node.Properties.Name) end) then failedProperties += 1 end
        end
        for propName, value in pairs(node.Properties) do
            if propName ~= "Name" then
                local okProp = applyDecodedProperty(obj, propName, value, node.PropertyTypes and node.PropertyTypes[propName])
                if not okProp then failedProperties += 1 end
            end
        end
        rememberStudioLiteState(obj, node)
        disableImportedScript(obj, node)
        normalizePartGeometry(obj, node)
        obj.Parent = parent or containers[routeKey] or containers.WS
        buildBurstCount += 1
        progressMade += 1
        if progressMade == 1 or progressMade % 120 == 0 then
            local ratio = math.min(progressMade / progressTotal, 1)
            reportImportProgress(0.20 + ratio * 0.55, ("GENERATING %d / %d"):format(progressMade, progressTotal))
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
                skipped += 1
            end
        end
        return obj
    end
    for _, root in ipairs(parsed.Roots) do
        local key = routeForNode(root, "WS")
        local rootNameProp = tostring((root.Properties and root.Properties.Name) or "")
        if root.IsService or root.Service or serviceKeyByName[root.ClassName] or serviceKeyByName[rootNameProp] then
            createNode(root, containers[key], key)
        else
            createNode(root, containers.WS, "WS")
        end
    end
    for ref, node in pairs(parsed.Nodes) do
        local obj = made[ref]
        if obj and node.PropertyTypes then
            for propName, typeID in pairs(node.PropertyTypes) do
                if typeID == 0x13 then
                    local targetObj = made[node.Properties[propName]]
                    if targetObj then
                        if not pcall(function() obj[propName] = targetObj end) then failedProperties += 1 end
                    end
                elseif typeID == 0x22 then
                    local cv = node.Properties[propName]
                    if type(cv) == "table" and cv.__ContentObjectRef then
                        local targetObj = made[cv.__ContentObjectRef]
                        if targetObj then
                            if not pcall(function() obj[propName] = targetObj end) then failedProperties += 1 end
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
        local n = 0
        for _, obj in pairs(made) do
            if obj and obj.Parent and obj:IsA("LuaSourceContainer") then
                pcall(function() injectStudioLiteUI(obj, {}) end)
                n += 1
                if n >= 40 then n = 0; task.wait() end
            end
        end
    end)
    flushServerLoadsAsync()
    do
        local lockTarget = importRoot
        for _, o in pairs(made) do
            if o and o:IsA("BasePart") then anchorPart(o) end
        end
        if lockTarget then lockAnchored(lockTarget) end
    end
    local madeCount = 0
    for _ in pairs(made) do madeCount += 1 end
    reportImportProgress(0.78, ("BUILD COMPLETE • %d INSTANCES"):format(madeCount))
    return madeCount, skipped, failedProperties, meshNative, meshFallback, meshUnresolved, csgAsset, csgProxy, importRoot
end

local function safeReadFile(path)
    if type(readfile) ~= "function" then return nil, "readfile tidak tersedia" end
    local ok, data = pcall(readfile, path)
    if not ok then return nil, tostring(data) end
    if type(data) ~= "string" or #data == 0 then return nil, "file kosong / tidak terbaca" end
    return data
end

-- ─────────────── [6] PARSER XML (RBXLX / RBXMX) ───────────────
local function xmlDecodeText(value)
    value = tostring(value or "")
    local cdata = value:match("^%s*<!%[CDATA%[(.*)%]%]>%s*$")
    if cdata ~= nil then return cdata end
    local function chr(n)
        if not n then return "" end
        if n <= 255 then return string.char(n) end
        if utf8 and utf8.char then
            local ok, ch = pcall(utf8.char, n)
            if ok then return ch end
        end
        return ""
    end
    value = value:gsub("&#x([%x]+);", function(h) return chr(tonumber(h, 16)) end)
    value = value:gsub("&#(%d+);", function(d) return chr(tonumber(d)) end)
    value = value:gsub("&quot;", '"'):gsub("&apos;", "'"):gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&amp;", "&")
    return value
end
local function xmlNumber(inner, tag)
    return tonumber(inner:match("<" .. tag .. ">%s*(.-)%s*</" .. tag .. ">"))
end
local function xmlPropertyValue(tag, inner)
    if tag == "string" or tag == "ProtectedString" or tag == "BinaryString" or tag == "SharedString" then
        return xmlDecodeText(inner)
    elseif tag == "bool" then
        local v = tostring(inner):match("^%s*(.-)%s*$")
        return v == "true" or v == "1"
    elseif tag == "int" or tag == "int64" or tag == "float" or tag == "double" then
        return tonumber(tostring(inner):match("^%s*(.-)%s*$"))
    elseif tag == "token" then
        return tonumber(tostring(inner):match("^%s*(.-)%s*$")), 0x12
    elseif tag == "Ref" then
        local target = xmlDecodeText(inner):match("^%s*(.-)%s*$")
        if target == "" or target == "null" then return nil, 0x13 end
        return {__XMLRef = target}, 0x13
    elseif tag == "Vector3" then
        return Vector3.new(xmlNumber(inner,"X") or 0, xmlNumber(inner,"Y") or 0, xmlNumber(inner,"Z") or 0)
    elseif tag == "Vector2" then
        return Vector2.new(xmlNumber(inner,"X") or 0, xmlNumber(inner,"Y") or 0)
    elseif tag == "Color3" then
        return Color3.new(xmlNumber(inner,"R") or 0, xmlNumber(inner,"G") or 0, xmlNumber(inner,"B") or 0)
    elseif tag == "Color3uint8" then
        local packed = tonumber(tostring(inner):match("^%s*(%d+)%s*$"))
        if not packed then return nil end
        return Color3.fromRGB(math.floor(packed / 65536) % 256, math.floor(packed / 256) % 256, packed % 256)
    elseif tag == "CoordinateFrame" or tag == "CFrame" then
        return CFrame.new(
            xmlNumber(inner,"X") or 0, xmlNumber(inner,"Y") or 0, xmlNumber(inner,"Z") or 0,
            xmlNumber(inner,"R00") or 1, xmlNumber(inner,"R01") or 0, xmlNumber(inner,"R02") or 0,
            xmlNumber(inner,"R10") or 0, xmlNumber(inner,"R11") or 1, xmlNumber(inner,"R12") or 0,
            xmlNumber(inner,"R20") or 0, xmlNumber(inner,"R21") or 0, xmlNumber(inner,"R22") or 1)
    elseif tag == "OptionalCoordinateFrame" then
        if inner:find("<CFrame>", 1, true) then
            local body = inner:match("<CFrame>(.-)</CFrame>") or inner
            return xmlPropertyValue("CFrame", body)
        end
        return nil
    elseif tag == "UDim" then
        return UDim.new(xmlNumber(inner,"S") or 0, xmlNumber(inner,"O") or 0)
    elseif tag == "UDim2" then
        return UDim2.new(xmlNumber(inner,"XS") or 0, xmlNumber(inner,"XO") or 0, xmlNumber(inner,"YS") or 0, xmlNumber(inner,"YO") or 0)
    elseif tag == "BrickColor" then
        local n = tonumber(tostring(inner):match("^%s*(%d+)%s*$"))
        if n then
            local ok, value = pcall(BrickColor.new, n)
            if ok then return value end
        end
        return nil
    elseif tag == "Content" then
        local url = inner:match("<url>(.-)</url>")
        if url then return xmlDecodeText(url) end
        if inner:find("<null", 1, true) then return "" end
        return xmlDecodeText((inner:gsub("<[^>]+>", "")))
    elseif tag == "NumberRange" then
        local mn, mx = xmlNumber(inner,"Min"), xmlNumber(inner,"Max")
        if mn ~= nil and mx ~= nil then return NumberRange.new(mn, mx) end
    elseif tag == "Rect2D" then
        local minB, maxB = inner:match("<min>(.-)</min>"), inner:match("<max>(.-)</max>")
        if minB and maxB then
            return Rect.new(xmlNumber(minB,"X") or 0, xmlNumber(minB,"Y") or 0, xmlNumber(maxB,"X") or 0, xmlNumber(maxB,"Y") or 0)
        end
    elseif tag == "NumberSequence" then
        local numbers = {}
        for n in xmlDecodeText(inner):gmatch("[-+]?[%d%.]+[eE]?[-+]?%d*") do
            local v = tonumber(n)
            if v then numbers[#numbers + 1] = v end
        end
        if #numbers >= 3 then
            local kps = {}
            for i = 1, #numbers - 2, 3 do
                local ok, kp = pcall(NumberSequenceKeypoint.new, numbers[i], numbers[i+1], numbers[i+2])
                if ok then kps[#kps + 1] = kp end
            end
            if #kps >= 2 then
                local ok, seq = pcall(NumberSequence.new, kps)
                if ok then return seq end
            end
        end
    elseif tag == "Font" then
        local family = inner:match("<Family>%s*<url>(.-)</url>%s*</Family>")
        local weight = tonumber(inner:match("<Weight>%s*(%d+)%s*</Weight>")) or 400
        local style = inner:match("<Style>%s*(.-)%s*</Style>") or "Normal"
        if family and Font then
            family = xmlDecodeText(family)
            local ew = _enumItemByValue(Enum.FontWeight, weight) or Enum.FontWeight.Regular
            local es = (style == "Italic") and Enum.FontStyle.Italic or Enum.FontStyle.Normal
            local ok, font = pcall(Font.new, family, ew, es)
            if ok then return font end
        end
    end
    return nil
end

local function parseRobloxXML(data)
    if type(data) ~= "string" then return nil, "XML data bukan string" end
    data = data:gsub("^\239\187\191", "")
    if not data:find("<roblox", 1, true) then return nil, "Roblox XML root <roblox> tidak ditemukan" end
    local nodes, roots, referentToRef = {}, {}, {}
    local nextRef = 1
    local function parseProperties(body, node)
        local pos = 1
        while true do
            local openStart, openEnd, tag, attrs = body:find("<([%w]+)(.-)>", pos)
            if not openStart then break end
            local propName = attrs:match('name="([^"]+)"')
            if not propName then
                pos = openEnd + 1
            else
                local closeStart, closeEnd = body:find("</" .. tag .. ">", openEnd + 1, true)
                if not closeStart then break end
                local inner = body:sub(openEnd + 1, closeStart - 1)
                local value, typeID = xmlPropertyValue(tag, inner)
                if value ~= nil then node.Properties[propName] = value end
                if typeID ~= nil then node.PropertyTypes[propName] = typeID end
                pos = closeEnd + 1
            end
        end
    end
    local parseItemAt
    parseItemAt = function(startPos)
        local openEnd = data:find(">", startPos, true)
        if not openEnd then return nil, startPos, "Item open tag tidak selesai" end
        local openTag = data:sub(startPos, openEnd)
        local className = openTag:match('class="([^"]+)"')
        local referent = openTag:match('referent="([^"]+)"')
        if not className then return nil, openEnd + 1, "Item tanpa class" end
        local ref = nextRef
        nextRef += 1
        local node = {
            Ref = ref, ClassName = xmlDecodeText(className), Properties = {}, PropertyTypes = {},
            Children = {}, Service = false, IsService = false, XMLReferent = referent,
        }
        nodes[ref] = node
        if referent and referent ~= "" then referentToRef[referent] = ref end
        local pos = openEnd + 1
        while pos <= #data do
            local nextTag = data:find("<", pos, true)
            if not nextTag then return nil, pos, "Item tidak memiliki closing tag" end
            if data:sub(nextTag, nextTag + 6) == "</Item>" then
                return node, nextTag + 7
            elseif data:sub(nextTag, nextTag + 11) == "<Properties>" then
                local closeStart, closeEnd = data:find("</Properties>", nextTag + 12, true)
                if not closeStart then return nil, nextTag, "Properties tidak memiliki closing tag" end
                parseProperties(data:sub(nextTag + 12, closeStart - 1), node)
                pos = closeEnd + 1
            elseif data:sub(nextTag, nextTag + 4) == "<Item" then
                local child, newPos, err = parseItemAt(nextTag)
                if not child then return nil, newPos, err end
                node.Children[#node.Children + 1] = child
                pos = newPos
            elseif data:sub(nextTag, nextTag + 3) == "<!--" then
                local commentEnd = data:find("-->", nextTag, true)
                pos = commentEnd and (commentEnd + 3) or (#data + 1)
            else
                local tagEnd = data:find(">", nextTag, true)
                pos = tagEnd and (tagEnd + 1) or (#data + 1)
            end
        end
        return nil, pos, "Unexpected end of XML"
    end
    local pos = 1
    while true do
        local itemStart = data:find("<Item", pos, true)
        if not itemStart then break end
        local node, newPos, err = parseItemAt(itemStart)
        if not node then return nil, "XML PARSE ERROR: " .. tostring(err) end
        roots[#roots + 1] = node
        pos = newPos
    end
    if #roots == 0 then return nil, "Roblox XML tidak memiliki Item" end
    for _, node in pairs(nodes) do
        for propName, typeID in pairs(node.PropertyTypes) do
            if typeID == 0x13 then
                local value = node.Properties[propName]
                if type(value) == "table" and value.__XMLRef then
                    node.Properties[propName] = referentToRef[value.__XMLRef] or -1
                end
            end
        end
    end
    local serviceNames = {
        Workspace=true, Players=true, Lighting=true, ReplicatedFirst=true, ReplicatedStorage=true,
        StarterGui=true, StarterPack=true, StarterPlayer=true, Teams=true, ServerScriptService=true,
        ServerStorage=true, SoundService=true, MaterialService=true, TextChatService=true, Chat=true,
        LocalizationService=true, TestService=true, HttpService=true, InsertService=true, TweenService=true,
    }
    for _, root in ipairs(roots) do
        local rn = tostring(root.Properties.Name or "")
        if serviceNames[root.ClassName] or serviceNames[rn] then
            root.Service = true
            root.IsService = true
        end
    end
    return {
        Header = { ClassCount = 0, InstanceCount = nextRef - 1, Format = "XML" },
        Nodes = nodes, Roots = roots, Services = {}, SharedStrings = {},
    }, nil
end

local function detectRobloxSerialization(data)
    if type(data) ~= "string" or #data == 0 then return nil end
    if data:sub(1, 14) == "<roblox!" .. string.char(137,255,13,10,26,10) then return "BINARY" end
    local sample = data:sub(1, 4096):gsub("^\239\187\191", "")
    if sample:find("<roblox", 1, true) then return "XML" end
    return nil
end

local function importRBXL(fileInfo)
    reportImportProgress(0.02, "READING PLACE FILE")
    local data, readErr = safeReadFile(fileInfo.path)
    reportImportProgress(0.08, "PLACE FILE LOADED")
    if not data then return false, "READ ERROR: " .. tostring(readErr) end
    local serialization = detectRobloxSerialization(data)
    if not serialization then return false, "File bukan RBXL/RBXLX Roblox yang valid" end
    local parsed, parseErr
    if serialization == "BINARY" then
        if type(string.unpack) ~= "function" then return false, "COMPAT ERROR: string.unpack tidak tersedia" end
        if type(bit32) ~= "table" then return false, "COMPAT ERROR: bit32 tidak tersedia" end
        reportImportProgress(0.12, "PARSING RBXL BINARY")
        local okParse, result, err = pcall(parseRBXLBinary, data)
        if not okParse then return false, "PARSER CRASH: " .. tostring(result) end
        parsed, parseErr = result, err
    else
        reportImportProgress(0.12, "PARSING RBXLX XML")
        local okParse, result, err = pcall(parseRobloxXML, data)
        if not okParse then return false, "XML PARSER CRASH: " .. tostring(result) end
        parsed, parseErr = result, err
    end
    if not parsed then return false, "PARSE ERROR: " .. tostring(parseErr or "unknown") end
    reportImportProgress(0.18, ("PARSED %s • %d INSTANCES"):format(serialization, tonumber(parsed.Header and parsed.Header.InstanceCount) or 0))
    local okBuild, madeCount, skipped, failedProperties, meshNative, meshFallback, meshUnresolved, csgAsset, csgProxy, importRoot =
        pcall(buildRBXL, parsed, fileInfo.name)
    if not okBuild then return false, "BUILD ERROR: " .. tostring(madeCount) end
    local rootLabel = importRoot and importRoot.Name or importRootName(fileInfo.name)
    return true, ("%s OK %d | %s | mesh N:%d F:%d U:%d | CSG A:%d P:%d | prop:%d"):format(
        serialization, madeCount or 0, rootLabel, meshNative or 0, meshFallback or 0, meshUnresolved or 0,
        csgAsset or 0, csgProxy or 0, failedProperties or 0), importRoot
end

-- ─────────────── [7] IMPORT RBXM (model) ───────────────
local function spawnInFrontOfCamera(root)
    pcall(function()
        local cam = workspace.CurrentCamera
        if not cam then return end
        local target = cam.CFrame * CFrame.new(0, 0, -10)
        anchorTree(root)
        if root:IsA("Model") then
            root:PivotTo(CFrame.new(target.Position))
        elseif root:IsA("BasePart") then
            root.CFrame = CFrame.new(target.Position)
        end
    end)
    lockAnchored(root)
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
        for _, child in ipairs(node.Children or {}) do add(child) end
    end
    for _, root in ipairs(parsed.Roots or {}) do add(root) end
    return queues
end
local function takeRBXMSource(sourceQueues, obj)
    local key = obj.ClassName .. "\0" .. obj.Name
    local queue = sourceQueues[key]
    if not queue or #queue == 0 then return nil end
    local source = queue[1]
    table.remove(queue, 1)
    return source
end
local function tryWriteRBXMSource(scr, source)
    if not scr or not scr:IsA("LuaSourceContainer") or type(source) ~= "string" or source == "" then return false end
    SOURCES[scr] = source
    local refKey = scr:GetAttribute("MXM_Ref")
    if refKey ~= nil then SOURCES_BY_REF[tostring(refKey)] = source end
    if type(setscriptable) == "function" then pcall(setscriptable, scr, "Source", true) end
    return pcall(function() scr.Source = source end)
end
local function queueAssetsFromRBXM(root)
    local all = {root}
    for _, d in ipairs(root:GetDescendants()) do all[#all + 1] = d end
    for _, obj in ipairs(all) do
        pcall(function()
            if obj:IsA("MeshPart") then queueServerLoad(obj.MeshId); queueServerLoad(obj.TextureID)
            elseif obj:IsA("SpecialMesh") then queueServerLoad(obj.MeshId); queueServerLoad(obj.TextureId)
            elseif obj:IsA("Decal") or obj:IsA("Texture") then queueServerLoad(obj.Texture)
            elseif obj:IsA("Shirt") then queueServerLoad(obj.ShirtTemplate)
            elseif obj:IsA("Pants") then queueServerLoad(obj.PantsTemplate)
            elseif obj:IsA("ShirtGraphic") then queueServerLoad(obj.Graphic)
            elseif obj:IsA("UnionOperation") or obj:IsA("PartOperation") or obj:IsA("IntersectOperation") then queueServerLoad(obj.AssetId) end
        end)
    end
end
local function buildRBXModelParsed(parsed, sourceFileName)
    local made, importedRoots = {}, {}
    local skipped, failedProperties = 0, 0
    local function instantiateModelNode(node)
        if node.ClassName == "MeshPart" then
            local obj = tryCreateMeshPartNode(node)
            if obj then return obj end
        elseif node.ClassName == "UnionOperation" or node.ClassName == "PartOperation" or node.ClassName == "IntersectOperation" then
            local obj = tryLoadPartOperationNode(node)
            if obj then return obj end
        end
        local ok, obj = pcall(Instance.new, node.ClassName)
        if ok then return obj end
        return nil
    end
    local function createNode(node, parent)
        preloadNodeAssets(node)
        local obj = instantiateModelNode(node)
        if not obj then
            skipped += 1
            for _, child in ipairs(node.Children or {}) do createNode(child, parent) end
            return nil
        end
        made[node.Ref] = obj
        pcall(function()
            obj:SetAttribute("MXM_ImportedObject", true)
            obj:SetAttribute("MXM_Ref", tostring(node.Ref))
            obj:SetAttribute("MXM_RBXMSource", tostring(sourceFileName or ""))
        end)
        if node.Properties and node.Properties.Name ~= nil then
            pcall(function() obj.Name = tostring(node.Properties.Name) end)
        end
        for propName, value in pairs(node.Properties or {}) do
            if propName ~= "Name" then
                local okProp = applyDecodedProperty(obj, propName, value, node.PropertyTypes and node.PropertyTypes[propName])
                if not okProp then failedProperties += 1 end
            end
        end
        if obj:IsA("BasePart") then
            local original = obj.Anchored
            if node.Properties and type(node.Properties.Anchored) == "boolean" then original = node.Properties.Anchored end
            pcall(function()
                obj:SetAttribute("MXM_FileAnchored", original)
                obj:SetAttribute("MXM_AutoAnchored", true)
                obj.Anchored = true
            end)
        end
        obj.Parent = parent
        for _, child in ipairs(node.Children or {}) do
            if not (isMeshPartOnlyChildClass(child.ClassName) and not obj:IsA("MeshPart")) then
                createNode(child, obj)
            else
                skipped += 1
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
                if typeID == 0x13 then
                    local target = made[node.Properties[propName]]
                    if target then pcall(function() obj[propName] = target end) end
                end
            end
        end
    end
    for ref, obj in pairs(made) do
        local node = parsed.Nodes and parsed.Nodes[ref]
        if obj:IsA("LuaSourceContainer") and node then
            local source = node.Properties and (node.Properties.Source or node.Properties.ContentText)
            if type(source) == "string" and source ~= "" then pcall(function() tryWriteRBXMSource(obj, source) end) end
            pcall(function() injectStudioLiteUI(obj, {}) end)
        end
        if obj:IsA("BasePart") then
            pcall(function() obj.Anchored = true; obj:SetAttribute("MXM_AutoAnchored", true) end)
        end
    end
    for _, root in ipairs(importedRoots) do pcall(function() queueAssetsFromRBXM(root) end) end
    flushServerLoadsAsync()
    local count = 0
    for _ in pairs(made) do count += 1 end
    return importedRoots, count, skipped, failedProperties
end

local function importRBXM(fileInfo)
    reportImportProgress(0.02, "READING RBXM")
    local data, readErr = safeReadFile(fileInfo.path)
    if not data then return false, "READ ERROR: " .. tostring(readErr) end
    reportImportProgress(0.10, "MODEL FILE LOADED")
    local serialization = detectRobloxSerialization(data)
    if not serialization then return false, "File bukan RBXM/RBXMX Roblox yang valid" end
    if serialization == "XML" then
        reportImportProgress(0.16, "PARSING RBXMX XML")
        local okParsed, parsed, parseErr = pcall(parseRobloxXML, data)
        if not okParsed then return false, "XML PARSER CRASH: " .. tostring(parsed) end
        if not parsed then return false, "RBXMX PARSE ERROR: " .. tostring(parseErr or "unknown") end
        reportImportProgress(0.34, "BUILDING RBXMX MODEL")
        local okBuild, roots, count, skipped, failedProperties = pcall(buildRBXModelParsed, parsed, fileInfo.name)
        if not okBuild then return false, "RBXMX BUILD ERROR: " .. tostring(roots) end
        if roots then for _, r in ipairs(roots) do lockAnchored(r) end end
        if roots and roots[1] then spawnInFrontOfCamera(roots[1]) end
        reportImportProgress(1.00, "RBXMX GENERATION COMPLETE")
        return true, ("RBXMX XML OK • %d object(s) • skipped:%d • prop:%d"):format(count or 0, skipped or 0, failedProperties or 0), roots and roots[1] or nil
    end
    local sourceQueues = {}
    reportImportProgress(0.15, "PARSING RBXM SOURCES")
    local okParsed, parsed = pcall(parseRBXLBinary, data)
    if okParsed and parsed then sourceQueues = collectRBXMSources(parsed) end
    reportImportProgress(0.24, "REGISTERING RBXM ASSET")
    local objects
    local loadMethod = "unknown"
    if type(getcustomasset) == "function" then
        local okAsset, customAsset = pcall(getcustomasset, fileInfo.path)
        if okAsset and customAsset then
            local okObjects, result = pcall(function() return game:GetObjects(customAsset) end)
            if okObjects and type(result) == "table" and #result > 0 then objects = result; loadMethod = "getcustomasset" end
        end
    end
    if not objects then
        local okObjects, result = pcall(function() return game:GetObjects("rbxasset://" .. tostring(fileInfo.path)) end)
        if okObjects and type(result) == "table" and #result > 0 then objects = result; loadMethod = "rbxasset" end
    end
    if not objects then return false, "RBXM LOAD ERROR: getcustomasset/game:GetObjects tidak dapat memuat model" end
    reportImportProgress(0.40, ("RBXM OPENED • %d ROOT"):format(#objects))
    local importedRoots = {}
    local totalObjects, sourceFound, sourceWritten, editorRestored, scriptCount = 0, 0, 0, 0, 0
    for rootIndex, root in ipairs(objects) do
        if typeof(root) == "Instance" then
            root:SetAttribute("MXM_ImportedObject", true)
            root:SetAttribute("MXM_RBXMSource", fileInfo.name)
            root.Parent = workspace
            importedRoots[#importedRoots + 1] = root
            local descendants = root:GetDescendants()
            local all = {root}
            for _, d in ipairs(descendants) do all[#all + 1] = d end
            totalObjects += #all
            for i, obj in ipairs(all) do
                obj:SetAttribute("MXM_ImportedObject", true)
                if obj:IsA("BasePart") then
                    local saved = obj.Anchored
                    obj:SetAttribute("MXM_FileAnchored", saved)
                    obj:SetAttribute("MXM_AutoAnchored", true)
                    obj.Anchored = true
                end
                if obj:IsA("LuaSourceContainer") then
                    scriptCount += 1
                    local source = takeRBXMSource(sourceQueues, obj)
                    if source then
                        sourceFound += 1
                        SOURCES[obj] = source
                        if tryWriteRBXMSource(obj, source) then sourceWritten += 1 end
                        if pcall(function() injectStudioLiteUI(obj, {}) end) then editorRestored += 1 end
                    end
                end
                if i % 180 == 0 then task.wait() end
            end
            queueAssetsFromRBXM(root)
            spawnInFrontOfCamera(root)
            lockAnchored(root)
        end
        reportImportProgress(0.40 + (rootIndex / math.max(#objects, 1)) * 0.45, ("IMPORTING RBXM ROOT %d / %d"):format(rootIndex, #objects))
    end
    flushServerLoadsAsync()
    reportImportProgress(1.00, "RBXM GENERATION COMPLETE")
    return true, ("RBXM OK • %d objects • %d scripts • source:%d/%d • editor:%d • %s"):format(
        totalObjects, scriptCount, sourceWritten, sourceFound, editorRestored, loadMethod), importedRoots[1]
end

-- ─────────────── [8] RUNTIME (jalankan LocalScript / ModuleScript) ───────────────
local MODULE_CACHE = setmetatable({}, {__mode = "k"})
local MODULE_LOADING = setmetatable({}, {__mode = "k"})
local function rawSourceFor(scr)
    if not scr or not scr:IsA("LuaSourceContainer") then return nil end
    local direct = SOURCES[scr]
    if type(direct) == "string" and direct ~= "" then return direct end
    local refKey = scr:GetAttribute("MXM_Ref")
    if refKey ~= nil then
        local byRef = SOURCES_BY_REF[tostring(refKey)]
        if type(byRef) == "string" and byRef ~= "" then return byRef end
    end
    return nil
end
local function canReadExecutableSource(scr)
    local ok, source = pcall(function() return scr.Source end)
    return ok and type(source) == "string" and #source > 0, source
end
local runtimeRequire
local function compileRuntimeSource(scr, source)
    if type(loadstring) ~= "function" then return nil, "loadstring tidak tersedia" end
    local wrapped = "return function(script, require, ...)\n" .. source .. "\nend"
    local okCompile, loaderOrErr = pcall(loadstring, wrapped, "=MXM_RBXL/" .. tostring(scr:GetFullName()))
    if not okCompile or type(loaderOrErr) ~= "function" then return nil, tostring(loaderOrErr) end
    local okFactory, runnerOrErr = pcall(loaderOrErr)
    if not okFactory or type(runnerOrErr) ~= "function" then return nil, tostring(runnerOrErr) end
    return runnerOrErr
end
runtimeRequire = function(target)
    if typeof(target) == "Instance" and target:IsA("ModuleScript") then
        if MODULE_CACHE[target] ~= nil then return MODULE_CACHE[target] end
        if MODULE_LOADING[target] then error("MxM runtime require circular dependency: " .. target:GetFullName()) end
        local source = rawSourceFor(target)
        if source then
            MODULE_LOADING[target] = true
            local runner, compileErr = compileRuntimeSource(target, source)
            if not runner then
                MODULE_LOADING[target] = nil
                error("Module compile failed: " .. tostring(compileErr))
            end
            local results = table.pack(pcall(runner, target, runtimeRequire))
            MODULE_LOADING[target] = nil
            if not results[1] then error(results[2]) end
            MODULE_CACHE[target] = results[2]
            return results[2]
        end
    end
    return require(target)
end
local function runLocalScriptBridge(scr)
    if not scr or not scr:IsA("LocalScript") then return false, "not_local_script" end
    if not importedScriptShouldRun(scr) then return false, "originally_disabled" end
    if scr:GetAttribute("MXM_RuntimeStarted") then return true, "already_started" end
    local source = rawSourceFor(scr)
    if not source then return false, "source_missing" end
    local runner, compileErr = compileRuntimeSource(scr, source)
    if not runner then return false, "compile: " .. tostring(compileErr) end
    scr:SetAttribute("MXM_RuntimeStarted", true)
    task.spawn(function()
        local ok, runtimeErr = pcall(runner, scr, runtimeRequire)
        if not ok then
            warn("[MxM LIVE SCRIPT ERROR] " .. scr:GetFullName() .. " :: " .. tostring(runtimeErr))
            scr:SetAttribute("MXM_RuntimeError", tostring(runtimeErr))
        end
    end)
    return true, "runtime_bridge"
end
local function prepareLocalScriptsForClone(root)
    if not root then return end
    if root:IsA("LocalScript") then setScriptEnabledState(root, false) end
    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("LocalScript") then setScriptEnabledState(obj, false) end
    end
end
local function activateLocalScriptsInLiveRoot(root)
    local stats = { native = 0, bridge = 0, failed = 0, skipped = 0 }
    if not root then return stats end
    local list = {}
    if root:IsA("LocalScript") then list[#list + 1] = root end
    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("LocalScript") then list[#list + 1] = obj end
    end
    for _, scr in ipairs(list) do
        if not importedScriptShouldRun(scr) then
            stats.skipped += 1
            setScriptEnabledState(scr, false)
        else
            if canReadExecutableSource(scr) then
                if setScriptEnabledState(scr, true) then stats.native += 1 else stats.failed += 1 end
            else
                setScriptEnabledState(scr, false)
                if runLocalScriptBridge(scr) then stats.bridge += 1 else stats.failed += 1 end
            end
        end
    end
    return stats
end
local function mergeLiveStats(dst, src)
    dst.native += src.native or 0
    dst.bridge += src.bridge or 0
    dst.failed += src.failed or 0
    dst.skipped += src.skipped or 0
end
local function findStudioLiteRemote(name)
    local sl = ReplicatedStorage:FindFirstChild("StudioLiteFolder")
    if not sl then return nil end
    return sl:FindFirstChild(name, true)
end
local function tryWriteRealScriptSource(scr)
    if not scr or not scr:IsA("LuaSourceContainer") then return false, "not_script" end
    local source = rawSourceFor(scr)
    if type(source) ~= "string" or source == "" then return false, "source_missing" end
    source = source:gsub(string.char(0) .. "*$", "")
    SOURCES[scr] = source
    if type(setscriptable) == "function" then pcall(setscriptable, scr, "Source", true) end
    if pcall(function() scr.Source = source end) then return true, "direct" end
    local saveRemote = findStudioLiteRemote("SaveScriptSourceServerFunction")
    if saveRemote and saveRemote:IsA("RemoteFunction") then
        if pcall(function() saveRemote:InvokeServer(scr.ClassName .. scr.Name, source) end) then return true, "studio_lite_remote" end
    elseif saveRemote and saveRemote:IsA("RemoteEvent") then
        if pcall(function() saveRemote:FireServer(scr.ClassName .. scr.Name, source) end) then return true, "studio_lite_remote" end
    end
    return false, "runtime_source_locked"
end
local function restoreImportedRuntimeState(root)
    local stats = { scripts = 0, scriptSourceOK = 0, scriptSourceFailed = 0, parts = 0 }
    local all = {root}
    for _, d in ipairs(root:GetDescendants()) do all[#all + 1] = d end
    for _, obj in ipairs(all) do
        if obj:IsA("LuaSourceContainer") then
            stats.scripts += 1
            if tryWriteRealScriptSource(obj) then stats.scriptSourceOK += 1 else stats.scriptSourceFailed += 1 end
        end
    end
    for _, obj in ipairs(all) do
        if obj:IsA("BasePart") then
            stats.parts += 1
            local cc = obj:GetAttribute("SL_CanCollide")
            if cc ~= nil then pcall(function() obj.CanCollide = cc end) end
            pcall(function() obj.Anchored = true; obj:SetAttribute("MXM_AutoAnchored", true) end)
        end
    end
    return stats
end
local function moveChildren(source, destination)
    if not source or not destination then return 0 end
    local moved = 0
    for _, child in ipairs(source:GetChildren()) do
        if pcall(function() child.Parent = destination end) then moved += 1 end
    end
    return moved
end

-- ─────────────── [9] AKTIVASI (pindah ke layanan asli + pulihkan script) ───────────────
local function activateImportRoot(importRoot)
    if not importRoot then return false, "Import root tidak ditemukan" end
    reportImportProgress(0.80, "PREPARING SERVICES")
    local reused, created, getsvc, failed = 0, 0, 0, 0
    local function topLevelNamed(serviceName)
        local matches = {}
        local ok, children = pcall(function() return game:GetChildren() end)
        if not ok then return matches end
        for _, c in ipairs(children) do
            local n = ""
            pcall(function() n = c.Name end)
            if n == serviceName then matches[#matches + 1] = c end
        end
        return matches
    end
    local function forceGetService(serviceName)
        local m = topLevelNamed(serviceName)
        if #m > 0 then reused += 1; return m[1] end
        local obj
        local okCreate = pcall(function()
            obj = Instance.new(serviceName)
            obj.Name = serviceName
            obj:SetAttribute("MXM_CreatedService", true)
            obj.Parent = game
        end)
        if okCreate and obj then created += 1; return obj end
        local okGet, svc = pcall(function() return game:GetService(serviceName) end)
        if okGet and svc then getsvc += 1; return svc end
        failed += 1
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
    local SSSvc = forceGetService("ServerScriptService")
    local SSvc = forceGetService("ServerStorage")
    local SoundSvc = forceGetService("SoundService")
    local MaterialSvc = forceGetService("MaterialService")
    local TextChatSvc = forceGetService("TextChatService")
    local ChatSvc = forceGetService("Chat")
    local LocSvc = forceGetService("LocalizationService")
    local TestSvc = forceGetService("TestService")
    local HttpSvc = forceGetService("HttpService")
    local InsertSvc = forceGetService("InsertService")
    local TweenSvc = forceGetService("TweenService")
    reportImportProgress(0.84, "SERVICES READY")

    local function ensureStarterContainer(parent, className, name)
        if not parent then return nil end
        local existing = parent:FindFirstChild(name)
        if existing then return existing end
        local c
        if pcall(function() c = Instance.new(className); c.Name = name; c.Parent = parent end) and c then return c end
        local f = Instance.new("Folder")
        f.Name = name
        f.Parent = parent
        return f
    end
    local starterPlayerScripts = ensureStarterContainer(StarterPlayerSvc, "StarterPlayerScripts", "StarterPlayerScripts")
    local starterCharacterScripts = ensureStarterContainer(StarterPlayerSvc, "StarterCharacterScripts", "StarterCharacterScripts")
    local destinationByKey = {
        WS=WorkspaceService, RS=ReplicatedStorageSvc, RF=ReplicatedFirstSvc, L=LightingSvc, P=PlayersSvc,
        SG=StarterGuiSvc, STP=StarterPackSvc, SP=StarterPlayerSvc, SPS=starterPlayerScripts, SCS=starterCharacterScripts,
        SSS=SSSvc, SS=SSvc, TEAM=TeamsSvc, SND=SoundSvc, MAT=MaterialSvc, TCS=TextChatSvc, CHAT=ChatSvc,
        LOC=LocSvc, TEST=TestSvc, HTTP=HttpSvc, INS=InsertSvc, TWEEN=TweenSvc,
    }
    local runtimeStats = restoreImportedRuntimeState(importRoot)
    reportImportProgress(0.87, "RESTORING SCRIPT SOURCES")
    local moved = 0
    for _, folder in ipairs(importRoot:GetChildren()) do
        if folder:IsA("Folder") then
            local dest = destinationByKey[folder:GetAttribute("MXM_ServiceKey")]
            if dest then moved += moveChildren(folder, dest) end
        end
    end
    reportImportProgress(0.91, ("DEPLOYED • %d OBJECTS"):format(moved))

    local activatedScripts = 0
    local function restoreOne(obj)
        if not obj:IsA("LuaSourceContainer") or not obj:GetAttribute("MXM_StagedDisabled") then return end
        local shouldRun = importedScriptShouldRun(obj)
        setScriptEnabledState(obj, shouldRun)
        pcall(function() obj:SetAttribute("MXM_StagedDisabled", nil) end)
        if shouldRun then activatedScripts += 1 end
    end
    for _, obj in ipairs(importRoot:GetDescendants()) do restoreOne(obj) end
    for _, service in pairs(destinationByKey) do
        if service then
            for _, obj in ipairs(service:GetDescendants()) do restoreOne(obj) end
        end
    end

    local liveStats = { native = 0, bridge = 0, failed = 0, skipped = 0 }
    local function cloneImportedChildren(src, dst)
        if not src or not dst then return end
        for _, child in ipairs(src:GetChildren()) do
            if child:GetAttribute("MXM_ImportedObject") == true then
                local existing = dst:FindFirstChild(child.Name)
                if existing and existing:GetAttribute("MXM_LiveClone") == true then
                    pcall(function() existing:Destroy() end)
                end
                local clone
                if pcall(function() clone = child:Clone() end) and clone then
                    clone:SetAttribute("MXM_LiveClone", true)
                    prepareLocalScriptsForClone(clone)
                    clone.Parent = dst
                    mergeLiveStats(liveStats, activateLocalScriptsInLiveRoot(clone))
                end
            end
        end
    end
    local playerGui = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if playerGui then cloneImportedChildren(StarterGuiSvc, playerGui) end
    local playerScripts = LocalPlayer and LocalPlayer:FindFirstChild("PlayerScripts")
    if playerScripts and starterPlayerScripts then cloneImportedChildren(starterPlayerScripts, playerScripts) end
    local character = LocalPlayer and LocalPlayer.Character
    if character and starterCharacterScripts then cloneImportedChildren(starterCharacterScripts, character) end
    local backpack = LocalPlayer and LocalPlayer:FindFirstChildOfClass("Backpack")
    if backpack then cloneImportedChildren(StarterPackSvc, backpack) end
    if ReplicatedFirstSvc then
        for _, obj in ipairs(ReplicatedFirstSvc:GetDescendants()) do
            if obj:IsA("LocalScript") and obj:GetAttribute("MXM_ImportedObject") == true then
                if canReadExecutableSource(obj) then
                    setScriptEnabledState(obj, true); liveStats.native += 1
                else
                    setScriptEnabledState(obj, false)
                    if runLocalScriptBridge(obj) then liveStats.bridge += 1 else liveStats.failed += 1 end
                end
            end
        end
    end

    reportImportProgress(0.95, "FINALIZING SCRIPT EDITORS")
    local editorInjected, sourceVisible, sssN, ssN = 0, 0, 0, 0
    local function restoreEditorForService(service, key)
        if not service then return end
        for _, obj in ipairs(service:GetDescendants()) do
            if obj:IsA("LuaSourceContainer") and obj:GetAttribute("MXM_ImportedObject") == true then
                if key == "SSS" then sssN += 1 elseif key == "SS" then ssN += 1 end
                local source = rawSourceFor(obj)
                if source then
                    SOURCES[obj] = source
                    sourceVisible += 1
                    pcall(function() tryWriteRealScriptSource(obj) end)
                    if pcall(function() injectStudioLiteUI(obj, {}) end) then editorInjected += 1 end
                end
            end
        end
    end
    restoreEditorForService(SSSvc, "SSS"); restoreEditorForService(SSvc, "SS")
    restoreEditorForService(ReplicatedStorageSvc, "RS"); restoreEditorForService(ReplicatedFirstSvc, "RF")
    restoreEditorForService(StarterGuiSvc, "SG"); restoreEditorForService(StarterPlayerSvc, "SP")
    restoreEditorForService(StarterPackSvc, "STP"); restoreEditorForService(WorkspaceService, "WS")
    for _, service in pairs(destinationByKey) do
        if service then
            for _, obj in ipairs(service:GetDescendants()) do
                if obj:GetAttribute("MXM_ImportedObject") == true then
                    if obj:IsA("LuaSourceContainer") then
                        setScriptEnabledState(obj, importedScriptShouldRun(obj))
                    elseif obj:IsA("BasePart") then
                        pcall(function() obj.Anchored = true; obj:SetAttribute("MXM_AutoAnchored", true) end)
                    end
                end
            end
        end
    end
    importRoot:SetAttribute("MXM_Activated", true)
    local remaining = 0
    for _, f in ipairs(importRoot:GetChildren()) do
        if f:IsA("Folder") then remaining += #f:GetChildren() end
    end
    if remaining == 0 then pcall(function() importRoot:Destroy() end) end
    reportImportProgress(1.00, "RBXL GENERATION COMPLETE")
    return true, ("ACTIVE • moved:%d • scripts:%d on:%d • src:%d/%d • SSS:%d SS:%d • editor:%d/%d • svc reuse:%d new:%d fail:%d"):format(
        moved, runtimeStats.scripts, activatedScripts, runtimeStats.scriptSourceOK, runtimeStats.scripts,
        sssN, ssN, editorInjected, sourceVisible, reused, created, failed)
end

-- ─────────────── [10] PEMINDAI FILE ───────────────
local function safeListFiles(path)
    if type(listfiles) ~= "function" then return nil end
    local ok, result = pcall(listfiles, path)
    return ok and result or nil
end
local function getFileName(path) return path:match("([^/\\]+)$") or path end
local function looksFolder(path) return not getFileName(path):match("%.[%a%d]+$") end
local SCAN_PATHS = {
    "workspace", "Delta/workspace", "delta/workspace", "Android/Delta/workspace",
    "/sdcard/Delta/workspace", "/sdcard/Android/Delta/workspace", "../workspace", ".", ""
}
local function normalizeFsPath(path)
    local p = tostring(path or ""):gsub("\\", "/"):lower()
    p = p:gsub("/+", "/"):gsub("^%./", ""):gsub("^%.%./", ""):gsub("/$", "")
    return p
end
local function canonicalWorkspacePath(path)
    local p = normalizeFsPath(path)
    local last
    local from = 1
    while true do
        local s, e = p:find("workspace/", from, true)
        if not s then break end
        last = e + 1
        from = e + 1
    end
    if last then return p:sub(last) end
    if p == "workspace" then return "" end
    return p
end
local function scanDeep(folder, depth, results, seenFolders, seenFiles)
    if depth > 4 then return end
    local folderKey = canonicalWorkspacePath(folder)
    if folderKey == "" then folderKey = "__workspace_root__" end
    if seenFolders[folderKey] then return end
    seenFolders[folderKey] = true
    local list = safeListFiles(folder)
    if not list then return end
    for _, path in ipairs(list) do
        local name = getFileName(path)
        local lower = name:lower()
        local ftype, ext
        if lower:match("%.rbxlx$") then ftype, ext = "RBXL", "rbxlx"
        elseif lower:match("%.rbxl$") then ftype, ext = "RBXL", "rbxl"
        elseif lower:match("%.rbxmx$") then ftype, ext = "RBXM", "rbxmx"
        elseif lower:match("%.rbxm$") then ftype, ext = "RBXM", "rbxm" end
        if ftype then
            local fileKey = canonicalWorkspacePath(path)
            if fileKey == "" then fileKey = lower end
            if not seenFiles[fileKey] then
                seenFiles[fileKey] = true
                table.insert(results, { name = name, path = path, folder = folder, ftype = ftype, ext = ext, canonicalKey = fileKey })
            end
        elseif looksFolder(path) then
            scanDeep(path, depth + 1, results, seenFolders, seenFiles)
        end
    end
end
local function scanAllSupported()
    local results, seenFolders, seenFiles = {}, {}, {}
    for _, path in ipairs(SCAN_PATHS) do
        if safeListFiles(path) then scanDeep(path, 0, results, seenFolders, seenFiles) end
    end
    table.sort(results, function(a, b)
        local an, bn = a.name:lower(), b.name:lower()
        if an == bn then return tostring(a.canonicalKey or a.path) < tostring(b.canonicalKey or b.path) end
        return an < bn
    end)
    return results
end

-- ─────────────── [11] HOOK EDITOR (isi script tampil di editor Studio Lite) ───────────────
task.spawn(function()
    pcall(function()
        if type(hookmetamethod) ~= "function" or type(getnamecallmethod) ~= "function" or type(checkcaller) ~= "function" then return end
        if _G.MXM_SRC_HOOKED then return end
        _G.MXM_SRC_HOOKED = true
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if not checkcaller() and method == "InvokeServer" then
                local nm = ""
                pcall(function() nm = self.Name end)
                if nm == "GetScriptSourceServerFunction" then
                    local target = tostring((...))
                    for obj, source in pairs(SOURCES) do
                        if typeof(obj) == "Instance" and (obj.ClassName .. obj.Name) == target and source and source ~= "" then
                            return source
                        end
                    end
                elseif nm == "SaveScriptSourceServerFunction" then
                    local args = {...}
                    local target, newSource = tostring(args[1]), tostring(args[2])
                    for obj in pairs(SOURCES) do
                        if typeof(obj) == "Instance" and (obj.ClassName .. obj.Name) == target then
                            SOURCES[obj] = newSource
                            break
                        end
                    end
                end
            end
            return oldNamecall(self, ...)
        end)
    end)
end)

-- ─────────────── API ENGINE ───────────────
return {
    -- importer
    scan = scanAllSupported,
    importRBXM = importRBXM,
    importRBXL = importRBXL,
    activate = activateImportRoot,
    onProgress = function(fn) _G.MXM_PROGRESS = fn end,
    -- util untuk toolbox
    anchorPart = anchorPart,
    anchorTree = anchorTree,
    lockAnchored = lockAnchored,
    spawnInFront = spawnInFrontOfCamera,
    queueAssets = queueAssetsFromRBXM,
    flushAssets = flushServerLoadsAsync,
    injectEditor = injectStudioLiteUI,
    meshFromId = tryAssetServiceMesh,
    loadToServer = triggerServerLoad,
    studioLite = getStudioLiteServerFuncs,
}
end)()

-- =====================================================================
--                    MELSS x MEDI  •  UI (Liquid Glass)
--              Importer RBXM / RBXMX / RBXL / RBXLX  +  Toolbox PC
-- =====================================================================
-- alias API engine yang dipakai UI
local scanAllSupported, importRBXM, importRBXL, activateImportRoot =
    Engine.scan, Engine.importRBXM, Engine.importRBXL, Engine.activate
local anchorPart, anchorTree, lockAnchored, spawnInFrontOfCamera =
    Engine.anchorPart, Engine.anchorTree, Engine.lockAnchored, Engine.spawnInFront
local queueAssetsFromRBXM, flushServerLoadsAsync, injectStudioLiteUI =
    Engine.queueAssets, Engine.flushAssets, Engine.injectEditor
local tryAssetServiceMesh, triggerServerLoad, getStudioLiteServerFuncs =
    Engine.meshFromId, Engine.loadToServer, Engine.studioLite

;(function()
local GUI_NAME = "MELSS_MEDI_IMPORTER"
do
    local old = CoreDest:FindFirstChild(GUI_NAME)
    if old then old:Destroy() end
end

-- ---------- palet ----------
local C = {
    bg0     = Color3.fromRGB(34, 26, 58),
    bg1     = Color3.fromRGB(13, 11, 24),
    text    = Color3.fromRGB(255, 255, 255),
    soft    = Color3.fromRGB(222, 214, 246),
    muted   = Color3.fromRGB(160, 152, 196),
    pink    = Color3.fromRGB(255, 104, 178),
    violet  = Color3.fromRGB(142, 112, 255),
    cyan    = Color3.fromRGB(92, 214, 255),
    ok      = Color3.fromRGB(84, 232, 160),
    warn    = Color3.fromRGB(255, 200, 92),
    bad     = Color3.fromRGB(255, 96, 128),
    ink     = Color3.fromRGB(18, 12, 34),
}
local WHITE = Color3.new(1, 1, 1)
local TYPE_COLOR = { RBXM = C.cyan, RBXMX = Color3.fromRGB(110, 170, 255), RBXL = C.pink, RBXLX = C.violet }

-- ---------- helper UI ----------
local function corner(o, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 10); c.Parent = o; return c end
local function pad(o, l, t, r, b)
    local p = Instance.new("UIPadding")
    p.PaddingLeft, p.PaddingTop = UDim.new(0, l or 0), UDim.new(0, t or 0)
    p.PaddingRight, p.PaddingBottom = UDim.new(0, r or l or 0), UDim.new(0, b or t or 0)
    p.Parent = o
    return p
end
local function grad(o, c0, c1, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(c0, c1)
    g.Rotation = rot or 0
    g.Parent = o
    return g
end
local function glassStroke(o, thick, strong)
    local s = Instance.new("UIStroke")
    s.Thickness = thick or 1
    s.Color = WHITE
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = o
    local g = Instance.new("UIGradient")
    g.Rotation = 60
    local a = strong and 0.1 or 0.5
    g.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, a), NumberSequenceKeypoint.new(0.4, 0.88),
        NumberSequenceKeypoint.new(0.75, 0.94), NumberSequenceKeypoint.new(1, strong and 0.45 or 0.7),
    })
    g.Parent = s
    return s
end
local function label(parent, str, size, font, color, xa)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = str
    l.TextSize = size or 12
    l.Font = font or Enum.Font.GothamMedium
    l.TextColor3 = color or C.text
    l.TextXAlignment = xa or Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.Parent = parent
    return l
end
local function glass(parent, alpha, r)
    local f = Instance.new("Frame")
    f.BackgroundColor3 = WHITE
    f.BackgroundTransparency = alpha or 0.92
    f.BorderSizePixel = 0
    f.Parent = parent
    corner(f, r or 12)
    glassStroke(f, 1)
    return f
end
local function tween(o, t, props, style, dir)
    local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end
-- tombol: style "accent" (gradient pink->violet), "glass", atau warna solid
local function button(parent, str, style, size)
    local b = Instance.new("TextButton")
    b.AutoButtonColor = false
    b.BorderSizePixel = 0
    b.Text = str
    b.TextSize = size or 11
    b.Font = Enum.Font.GothamBold
    b.Parent = parent
    corner(b, 10)
    local sc = Instance.new("UIScale")
    sc.Parent = b
    if style == "accent" then
        b.BackgroundColor3 = WHITE
        b.BackgroundTransparency = 0
        b.TextColor3 = WHITE
        grad(b, C.pink, C.violet, 0)
    elseif typeof(style) == "Color3" then
        b.BackgroundColor3 = style
        b.BackgroundTransparency = 0.05
        b.TextColor3 = C.ink
    else
        b.BackgroundColor3 = WHITE
        b.BackgroundTransparency = 0.9
        b.TextColor3 = C.text
        glassStroke(b, 1)
    end
    b.MouseButton1Down:Connect(function() tween(sc, 0.08, { Scale = 0.95 }) end)
    b.MouseButton1Up:Connect(function() tween(sc, 0.12, { Scale = 1 }) end)
    b.MouseLeave:Connect(function() tween(sc, 0.12, { Scale = 1 }) end)
    return b
end
local function inputBox(parent, placeholder)
    local tb = Instance.new("TextBox")
    tb.BackgroundColor3 = WHITE
    tb.BackgroundTransparency = 0.92
    tb.BorderSizePixel = 0
    tb.Text = ""
    tb.PlaceholderText = placeholder
    tb.PlaceholderColor3 = C.muted
    tb.TextColor3 = C.text
    tb.TextSize = 12
    tb.Font = Enum.Font.GothamMedium
    tb.ClearTextOnFocus = false
    tb.TextXAlignment = Enum.TextXAlignment.Left
    tb.Parent = parent
    corner(tb, 10)
    local s = glassStroke(tb, 1)
    pad(tb, 10, 0, 10, 0)
    tb.Focused:Connect(function() tween(tb, 0.15, { BackgroundTransparency = 0.86 }) s.Color = C.pink end)
    tb.FocusLost:Connect(function() tween(tb, 0.15, { BackgroundTransparency = 0.92 }) s.Color = WHITE end)
    return tb
end
local function notify(titleText, body)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", { Title = tostring(titleText), Text = tostring(body), Duration = 5 })
    end)
end
local function copyText(s)
    local fn = setclipboard or toclipboard or set_clipboard or (Clipboard and Clipboard.set)
    if type(fn) ~= "function" then return false end
    return (pcall(fn, tostring(s)))
end

-- =====================================================================
--                              KERANGKA
-- =====================================================================
local gui = Instance.new("ScreenGui")
gui.Name = GUI_NAME
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 800
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = CoreDest

-- ---------- tombol bulat (buka / tutup, bisa digeser) ----------
local toggle = Instance.new("TextButton")
toggle.Name = "Toggle"
toggle.AutoButtonColor = false
toggle.Size = UDim2.fromOffset(52, 52)
toggle.Position = UDim2.new(0, 12, 0, 74)
toggle.BackgroundColor3 = WHITE
toggle.Text = ""
toggle.ZIndex = 50
toggle.Parent = gui
corner(toggle, 18)
grad(toggle, C.pink, C.violet, 45)
glassStroke(toggle, 1.5, true)
do
    local t = label(toggle, "M×M", 14, Enum.Font.GothamBlack, WHITE, Enum.TextXAlignment.Center)
    t.Size = UDim2.fromScale(1, 1)
    t.ZIndex = 51
    local shine = Instance.new("Frame")
    shine.Size = UDim2.new(1, -8, 0.45, 0)
    shine.Position = UDim2.fromOffset(4, 3)
    shine.BackgroundColor3 = WHITE
    shine.BackgroundTransparency = 0.75
    shine.BorderSizePixel = 0
    shine.ZIndex = 51
    shine.Parent = toggle
    corner(shine, 14)
    local g = Instance.new("UIGradient")
    g.Rotation = 90
    g.Transparency = NumberSequence.new(0.2, 1)
    g.Parent = shine
end

-- ---------- panel utama ----------
local MAIN_W, MAIN_H = 600, 380
local main = Instance.new("Frame")
main.Name = "Main"
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.fromScale(0.5, 0.5)
main.Size = UDim2.fromOffset(MAIN_W, MAIN_H)
main.BackgroundColor3 = WHITE
main.BackgroundTransparency = 0.06
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Visible = false
main.ZIndex = 10
main.Parent = gui
corner(main, 22)
grad(main, C.bg0, C.bg1, 120)
glassStroke(main, 1.6, true)
local mainScale = Instance.new("UIScale")
mainScale.Parent = main
local function fitScale()
    local v = gui.AbsoluteSize
    if v.X <= 0 then v = Vector2.new(800, 420) end
    return math.clamp(math.min((v.X - 24) / MAIN_W, (v.Y - 24) / MAIN_H), 0.5, 1.2)
end
mainScale.Scale = fitScale()

-- cahaya lembut bergerak di belakang kaca
do
    local function blob(color, size, pos, alpha)
        local b = Instance.new("Frame")
        b.AnchorPoint = Vector2.new(0.5, 0.5)
        b.Size = UDim2.fromOffset(size, size)
        b.Position = pos
        b.BackgroundColor3 = color
        b.BackgroundTransparency = alpha
        b.BorderSizePixel = 0
        b.ZIndex = 10
        b.Parent = main
        corner(b, size)
        return b
    end
    local b1 = blob(C.pink, 300, UDim2.new(1, -40, 1, 10), 0.86)
    local b2 = blob(C.violet, 260, UDim2.new(0, 20, 0, 30), 0.88)
    local b3 = blob(C.cyan, 180, UDim2.new(0.55, 0, 1, 40), 0.92)
    local info = TweenInfo.new(7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
    TweenService:Create(b1, info, { Position = UDim2.new(1, -120, 1, -30) }):Play()
    TweenService:Create(b2, TweenInfo.new(9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        { Position = UDim2.new(0, 110, 0, 70) }):Play()
    TweenService:Create(b3, TweenInfo.new(11, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        { Position = UDim2.new(0.35, 0, 1, 10) }):Play()
    local shine = Instance.new("Frame")
    shine.Size = UDim2.new(1, 0, 0, 110)
    shine.BackgroundColor3 = WHITE
    shine.BackgroundTransparency = 0.93
    shine.BorderSizePixel = 0
    shine.ZIndex = 10
    shine.Parent = main
    local g = Instance.new("UIGradient")
    g.Rotation = 90
    g.Transparency = NumberSequence.new(0.3, 1)
    g.Parent = shine
end

-- ---------- header ----------
local header = Instance.new("Frame")
header.Size = UDim2.new(1, -28, 0, 46)
header.Position = UDim2.fromOffset(14, 10)
header.BackgroundTransparency = 1
header.ZIndex = 20
header.Parent = main
local closeBtn, minBtn
do
    local logo = Instance.new("Frame")
    logo.Size = UDim2.fromOffset(40, 40)
    logo.Position = UDim2.fromOffset(0, 3)
    logo.BackgroundColor3 = WHITE
    logo.ZIndex = 21
    logo.Parent = header
    corner(logo, 13)
    grad(logo, C.pink, C.violet, 45)
    glassStroke(logo, 1.2, true)
    local lt = label(logo, "M×M", 12, Enum.Font.GothamBlack, WHITE, Enum.TextXAlignment.Center)
    lt.Size = UDim2.fromScale(1, 1)
    lt.ZIndex = 22

    local title = label(header, 'Melss <font color="#FF68B2">x</font> Medi', 18, Enum.Font.GothamBlack, C.text)
    title.RichText = true
    title.Position = UDim2.fromOffset(52, 2)
    title.Size = UDim2.new(1, -150, 0, 22)
    title.ZIndex = 21
    local sub = label(header, "RBXM • RBXL IMPORTER   ·   TOOLBOX PC", 10, Enum.Font.GothamBold, C.muted)
    sub.Position = UDim2.fromOffset(52, 24)
    sub.Size = UDim2.new(1, -150, 0, 16)
    sub.ZIndex = 21

    closeBtn = button(header, "×", nil, 18)
    closeBtn.AnchorPoint = Vector2.new(1, 0)
    closeBtn.Position = UDim2.new(1, 0, 0, 6)
    closeBtn.Size = UDim2.fromOffset(32, 32)
    closeBtn.ZIndex = 22
    minBtn = button(header, "–", nil, 16)
    minBtn.AnchorPoint = Vector2.new(1, 0)
    minBtn.Position = UDim2.new(1, -38, 0, 6)
    minBtn.Size = UDim2.fromOffset(32, 32)
    minBtn.ZIndex = 22
end

-- ---------- tab atas (IMPORTER / TOOLBOX) ----------
local tabBar = glass(main, 0.93, 14)
tabBar.Position = UDim2.fromOffset(14, 62)
tabBar.Size = UDim2.fromOffset(280, 34)
tabBar.ZIndex = 20
local tabPill = Instance.new("Frame")
tabPill.Size = UDim2.new(0.5, -6, 1, -6)
tabPill.Position = UDim2.fromOffset(3, 3)
tabPill.BackgroundColor3 = WHITE
tabPill.BorderSizePixel = 0
tabPill.ZIndex = 21
tabPill.Parent = tabBar
corner(tabPill, 11)
grad(tabPill, C.pink, C.violet, 0)
local tabBtns = {}
for i, name in ipairs({ "IMPORTER", "TOOLBOX" }) do
    local b = Instance.new("TextButton")
    b.BackgroundTransparency = 1
    b.Size = UDim2.new(0.5, 0, 1, 0)
    b.Position = UDim2.new((i - 1) * 0.5, 0, 0, 0)
    b.Text = name == "IMPORTER" and "📦  IMPORTER" or "🧰  TOOLBOX PC"
    b.TextSize = 11
    b.Font = Enum.Font.GothamBold
    b.TextColor3 = C.text
    b.ZIndex = 22
    b.Parent = tabBar
    tabBtns[name] = b
end

-- ---------- status bar (bawah) ----------
local statusText, pctText, fill, dot
do
    local bar = glass(main, 0.93, 12)
    bar.AnchorPoint = Vector2.new(0, 1)
    bar.Position = UDim2.new(0, 14, 1, -10)
    bar.Size = UDim2.new(1, -28, 0, 30)
    bar.ZIndex = 20
    dot = Instance.new("Frame")
    dot.Size = UDim2.fromOffset(8, 8)
    dot.Position = UDim2.fromOffset(12, 8)
    dot.BackgroundColor3 = C.ok
    dot.BorderSizePixel = 0
    dot.ZIndex = 22
    dot.Parent = bar
    corner(dot, 4)
    statusText = label(bar, "SIAP", 10, Enum.Font.GothamMedium, C.soft)
    statusText.Position = UDim2.fromOffset(28, 2)
    statusText.Size = UDim2.new(1, -90, 0, 20)
    statusText.TextTruncate = Enum.TextTruncate.AtEnd
    statusText.ZIndex = 22
    pctText = label(bar, "", 10, Enum.Font.GothamBold, C.pink, Enum.TextXAlignment.Right)
    pctText.AnchorPoint = Vector2.new(1, 0)
    pctText.Position = UDim2.new(1, -10, 0, 2)
    pctText.Size = UDim2.fromOffset(50, 20)
    pctText.ZIndex = 22
    local track = Instance.new("Frame")
    track.Position = UDim2.new(0, 10, 1, -6)
    track.Size = UDim2.new(1, -20, 0, 3)
    track.BackgroundColor3 = WHITE
    track.BackgroundTransparency = 0.88
    track.BorderSizePixel = 0
    track.ZIndex = 22
    track.Parent = bar
    corner(track, 2)
    fill = Instance.new("Frame")
    fill.Size = UDim2.fromScale(0, 1)
    fill.BackgroundColor3 = WHITE
    fill.BorderSizePixel = 0
    fill.ZIndex = 23
    fill.Parent = track
    corner(fill, 2)
    grad(fill, C.pink, C.cyan, 0)
end
local busy = false
task.spawn(function()
    while gui.Parent do
        local period = busy and 0.3 or 1.4
        tween(dot, period / 2, { BackgroundTransparency = 0.75 }, Enum.EasingStyle.Sine)
        task.wait(period / 2)
        tween(dot, period / 2, { BackgroundTransparency = 0 }, Enum.EasingStyle.Sine)
        task.wait(period / 2)
    end
end)
local statusVersion = 0
local function setStatus(msg, color)
    statusText.Text = tostring(msg)
    dot.BackgroundColor3 = (color == C.bad and C.bad) or (color == C.warn and C.warn) or C.ok
    if color == C.bad then
        busy = false
        fill.Size = UDim2.fromScale(0, 1)
        pctText.Text = ""
    end
end
local function setProgress(v, msg)
    v = math.clamp(tonumber(v) or 0, 0, 1)
    tween(fill, 0.15, { Size = UDim2.fromScale(v, 1) })
    pctText.Text = v > 0 and ("%d%%"):format(math.floor(v * 100 + 0.5)) or ""
    busy = v > 0 and v < 1
    if msg and msg ~= "" then setStatus(msg, C.warn) end
    if v >= 1 then
        statusVersion += 1
        local mine = statusVersion
        task.delay(2.5, function()
            if mine == statusVersion then fill.Size = UDim2.fromScale(0, 1) pctText.Text = "" end
        end)
    end
end
Engine.onProgress(setProgress)

-- area konten
local body = Instance.new("Frame")
body.Position = UDim2.fromOffset(14, 104)
body.Size = UDim2.new(1, -28, 1, -150)
body.BackgroundTransparency = 1
body.ZIndex = 20
body.Parent = main

local function scrollList(parent, grid)
    local s = Instance.new("ScrollingFrame")
    s.BackgroundTransparency = 1
    s.BorderSizePixel = 0
    s.ScrollBarThickness = 3
    s.ScrollBarImageColor3 = C.pink
    s.AutomaticCanvasSize = Enum.AutomaticSize.Y
    s.CanvasSize = UDim2.new()
    s.ZIndex = 21
    s.Parent = parent
    if grid then
        local g = Instance.new("UIGridLayout")
        g.CellSize = UDim2.new(0.5, -4, 0, 70)
        g.CellPadding = UDim2.fromOffset(6, 6)
        g.SortOrder = Enum.SortOrder.LayoutOrder
        g.Parent = s
    else
        local l = Instance.new("UIListLayout")
        l.Padding = UDim.new(0, 6)
        l.SortOrder = Enum.SortOrder.LayoutOrder
        l.Parent = s
    end
    pad(s, 0, 0, 6, 6)
    return s
end
local function chipRow(parent, y)
    local r = Instance.new("Frame")
    r.BackgroundTransparency = 1
    r.Position = UDim2.fromOffset(0, y)
    r.Size = UDim2.new(1, 0, 0, 24)
    r.ZIndex = 21
    r.Parent = parent
    local l = Instance.new("UIListLayout")
    l.FillDirection = Enum.FillDirection.Horizontal
    l.Padding = UDim.new(0, 5)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = r
    return r
end
local function makeChip(row, str, order)
    local b = Instance.new("TextButton")
    b.AutoButtonColor = false
    b.AutomaticSize = Enum.AutomaticSize.X
    b.Size = UDim2.fromOffset(0, 24)
    b.LayoutOrder = order
    b.BackgroundColor3 = WHITE
    b.BackgroundTransparency = 0.9
    b.Text = str
    b.TextSize = 10
    b.Font = Enum.Font.GothamBold
    b.TextColor3 = C.text
    b.ZIndex = 22
    b.Parent = row
    corner(b, 12)
    pad(b, 12, 0, 12, 0)
    local s = glassStroke(b, 1)
    local function setOn(on)
        tween(b, 0.15, { BackgroundTransparency = on and 0.05 or 0.9, BackgroundColor3 = on and C.pink or WHITE })
        b.TextColor3 = on and WHITE or C.text
        s.Enabled = not on
    end
    return b, setOn
end

-- =====================================================================
--                          HALAMAN IMPORTER
-- =====================================================================
local importer = Instance.new("Frame")
importer.BackgroundTransparency = 1
importer.Size = UDim2.fromScale(1, 1)
importer.ZIndex = 20
importer.Parent = body

local searchBox = inputBox(importer, "🔍  Cari file…")
searchBox.Size = UDim2.new(1, -112, 0, 32)
searchBox.ZIndex = 21
local scanBtn = button(importer, "⟳  SCAN", "accent", 12)
scanBtn.AnchorPoint = Vector2.new(1, 0)
scanBtn.Position = UDim2.new(1, 0, 0, 0)
scanBtn.Size = UDim2.fromOffset(104, 32)
scanBtn.ZIndex = 21

local typeRow = chipRow(importer, 40)
local currentType = "ALL"
local typeChips = {}
for i, key in ipairs({ "ALL", "RBXM", "RBXMX", "RBXL", "RBXLX" }) do
    local b, setOn = makeChip(typeRow, key == "ALL" and "SEMUA" or key, i)
    typeChips[key] = { btn = b, setOn = setOn }
end

local fileList = scrollList(importer, false)
fileList.Position = UDim2.fromOffset(0, 72)
fileList.Size = UDim2.new(1, 0, 1, -72)
local emptyLbl = label(importer, "Tekan SCAN untuk mencari file .rbxm / .rbxl", 12, Enum.Font.GothamMedium, C.muted, Enum.TextXAlignment.Center)
emptyLbl.Position = UDim2.fromOffset(0, 110)
emptyLbl.Size = UDim2.new(1, 0, 0, 50)
emptyLbl.TextWrapped = true
emptyLbl.ZIndex = 22

local allFiles, fileState, scanning = {}, {}, false
local renderList

local function makeCard(info, order)
    local ext = info.ext:upper()
    local tc = TYPE_COLOR[ext] or C.cyan
    local card = glass(fileList, 0.92, 14)
    card.Size = UDim2.new(1, 0, 0, 54)
    card.LayoutOrder = order
    card.ZIndex = 22
    local badge = Instance.new("Frame")
    badge.Position = UDim2.fromOffset(8, 8)
    badge.Size = UDim2.fromOffset(38, 38)
    badge.BackgroundColor3 = tc
    badge.BackgroundTransparency = 0.15
    badge.BorderSizePixel = 0
    badge.ZIndex = 23
    badge.Parent = card
    corner(badge, 11)
    local bt = label(badge, ext, ext:len() > 4 and 8 or 9, Enum.Font.GothamBlack, C.ink, Enum.TextXAlignment.Center)
    bt.Size = UDim2.fromScale(1, 1)
    bt.ZIndex = 24
    local nm = label(card, info.name, 12, Enum.Font.GothamBold, C.text)
    nm.Position = UDim2.fromOffset(56, 8)
    nm.Size = UDim2.new(1, -150, 0, 18)
    nm.TextTruncate = Enum.TextTruncate.AtEnd
    nm.ZIndex = 23
    local pt = label(card, info.path, 9, Enum.Font.Gotham, C.muted)
    pt.Position = UDim2.fromOffset(56, 28)
    pt.Size = UDim2.new(1, -150, 0, 14)
    pt.TextTruncate = Enum.TextTruncate.AtEnd
    pt.ZIndex = 23

    local st = fileState[info.path]
    if not st then st = { label = "IMPORT", color = nil } fileState[info.path] = st end
    local btn = button(card, st.label, st.color or "accent", 10)
    btn.AnchorPoint = Vector2.new(1, 0.5)
    btn.Position = UDim2.new(1, -8, 0.5, 0)
    btn.Size = UDim2.fromOffset(84, 30)
    btn.ZIndex = 24
    local function setBtn(text, color)
        st.label, st.color = text, color
        if not btn.Parent then return end
        btn.Text = text
        local g = btn:FindFirstChildOfClass("UIGradient")
        if color then
            if g then g:Destroy() end
            btn.BackgroundColor3 = color
            btn.TextColor3 = C.ink
        elseif not g then
            btn.BackgroundColor3 = WHITE
            btn.TextColor3 = WHITE
            grad(btn, C.pink, C.violet, 0)
        end
    end
    if st.color then setBtn(st.label, st.color) end

    btn.MouseButton1Click:Connect(function()
        if st.label == "IMPORTING" or st.label == "ACTIVATING" then return end
        if st.label == "ACTIVE" or st.label == "DONE" then
            setStatus("SUDAH DI-IMPORT • " .. info.name, C.ok)
            return
        end
        if st.label == "ACTIVATE" and st.root then
            setBtn("ACTIVATING", C.warn)
            task.spawn(function()
                local ok, msg = activateImportRoot(st.root)
                if ok then
                    setBtn("ACTIVE", C.ok) setStatus(msg, C.ok)
                    notify("Melss x Medi", info.name .. " berhasil digenerate 100%.")
                else
                    setBtn("ACTIVATE", C.violet) setStatus("ACTIVATE ERROR: " .. tostring(msg), C.bad)
                end
            end)
            return
        end
        setBtn("IMPORTING", C.warn)
        setProgress(0.01, "MULAI IMPORT • " .. info.name)
        task.spawn(function()
            local ok, msg, root
            if info.ftype == "RBXM" then ok, msg, root = importRBXM(info) else ok, msg, root = importRBXL(info) end
            if not ok then
                setBtn("FAILED", C.bad) setStatus(msg, C.bad)
                notify("IMPORT GAGAL", tostring(msg))
                task.wait(2.2)
                setBtn("IMPORT", nil)
                return
            end
            st.root = root
            if info.ftype == "RBXM" then
                setBtn("DONE", C.ok) setProgress(1, "RBXM SELESAI") setStatus(msg, C.ok)
                notify("Melss x Medi", info.name .. " berhasil digenerate 100%.")
                return
            end
            setBtn("ACTIVATING", C.warn)
            setStatus(msg .. " • AUTO ACTIVATING", C.warn)
            local aok, amsg = activateImportRoot(root)
            if aok then
                setBtn("ACTIVE", C.ok) setProgress(1, "RBXL SELESAI") setStatus(amsg, C.ok)
                notify("Melss x Medi", info.name .. " berhasil digenerate 100%.")
            else
                setBtn("ACTIVATE", C.violet) setStatus("AUTO ACTIVATE ERROR: " .. tostring(amsg), C.bad)
            end
        end)
    end)
end

local function updateChips()
    local counts = { ALL = #allFiles }
    for _, f in ipairs(allFiles) do
        local k = f.ext:upper()
        counts[k] = (counts[k] or 0) + 1
    end
    for key, ch in pairs(typeChips) do
        ch.btn.Text = (key == "ALL" and "SEMUA" or key) .. "  " .. (counts[key] or 0)
        ch.setOn(key == currentType)
    end
end
renderList = function()
    for _, c in ipairs(fileList:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    local q = searchBox.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
    local shown = 0
    for _, info in ipairs(allFiles) do
        if currentType == "ALL" or info.ext:upper() == currentType then
            if q == "" or info.name:lower():find(q, 1, true) or info.path:lower():find(q, 1, true) then
                shown += 1
                makeCard(info, shown)
            end
        end
    end
    emptyLbl.Visible = shown == 0
    if shown == 0 then
        emptyLbl.Text = #allFiles == 0 and "Belum ada file.\nTekan SCAN untuk mencari di folder executor & Download."
            or "Tidak ada file yang cocok."
    end
end
for key, ch in pairs(typeChips) do
    ch.btn.MouseButton1Click:Connect(function()
        currentType = key
        updateChips()
        renderList()
    end)
end
searchBox:GetPropertyChangedSignal("Text"):Connect(function() renderList() end)

local function scanNow()
    if scanning then return end
    scanning = true
    scanBtn.Text = "SCANNING…"
    busy = true
    setStatus("MEMINDAI FILE…", C.warn)
    task.spawn(function()
        if type(listfiles) ~= "function" then
            setStatus("ERROR: listfiles tidak tersedia di executor ini", C.bad)
            scanBtn.Text = "⟳  SCAN" scanning = false
            return
        end
        local ok, results = pcall(scanAllSupported)
        if not ok then
            setStatus("SCAN ERROR: " .. tostring(results), C.bad)
            scanBtn.Text = "⟳  SCAN" scanning = false
            return
        end
        allFiles = results
        updateChips()
        renderList()
        local m, l = 0, 0
        for _, f in ipairs(results) do if f.ftype == "RBXM" then m += 1 else l += 1 end end
        busy = false
        setStatus(("SCAN SELESAI • RBXM %d • RBXL %d"):format(m, l), #results > 0 and C.ok or C.warn)
        scanBtn.Text = "⟳  SCAN"
        scanning = false
    end)
end
scanBtn.MouseButton1Click:Connect(scanNow)
updateChips()

-- =====================================================================
--                          HALAMAN TOOLBOX PC
-- =====================================================================
local toolbox = Instance.new("Frame")
toolbox.BackgroundTransparency = 1
toolbox.Size = UDim2.fromScale(1, 1)
toolbox.ZIndex = 20
toolbox.Visible = false
toolbox.Parent = body

local tbSearch = inputBox(toolbox, "🔍  Cari aset atau ketik ID…")
tbSearch.Size = UDim2.new(1, -112, 0, 32)
tbSearch.ZIndex = 21
local goBtn = button(toolbox, "CARI", "accent", 12)
goBtn.AnchorPoint = Vector2.new(1, 0)
goBtn.Position = UDim2.new(1, 0, 0, 0)
goBtn.Size = UDim2.fromOffset(104, 32)
goBtn.ZIndex = 21

local catRow = chipRow(toolbox, 40)
local TB_CATS = { { name = "MODEL", id = 10 }, { name = "MESH", id = 4 }, { name = "DECAL", id = 13 }, { name = "AUDIO", id = 3 } }
local tbCat = 10
local catChips = {}
for i, cat in ipairs(TB_CATS) do
    local b, setOn = makeChip(catRow, cat.name, i)
    catChips[cat.id] = setOn
    b.MouseButton1Click:Connect(function()
        tbCat = cat.id
        for id, f in pairs(catChips) do f(id == tbCat) end
    end)
end
for id, f in pairs(catChips) do f(id == tbCat) end

local tbList = scrollList(toolbox, true)
tbList.Position = UDim2.fromOffset(0, 72)
tbList.Size = UDim2.new(1, 0, 1, -72)
local tbEmpty = label(toolbox, "Ketik nama aset lalu tekan CARI", 12, Enum.Font.GothamMedium, C.muted, Enum.TextXAlignment.Center)
tbEmpty.Position = UDim2.fromOffset(0, 110)
tbEmpty.Size = UDim2.new(1, 0, 0, 50)
tbEmpty.TextWrapped = true
tbEmpty.ZIndex = 22

local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request)
local function httpGetJson(url)
    local body2
    if httpRequest then
        local ok, res = pcall(httpRequest, { Url = url, Method = "GET", Headers = { ["Accept"] = "application/json" } })
        if ok and type(res) == "table" and (res.Success or res.StatusCode == 200) and type(res.Body) == "string" then body2 = res.Body end
    end
    if not body2 then
        local ok, res = pcall(function() return game:HttpGet(url) end)
        if ok and type(res) == "string" then body2 = res end
    end
    if not body2 then return nil end
    local ok, data = pcall(function() return HttpService:JSONDecode(body2) end)
    return ok and data or nil
end

-- masukkan aset ke Studio Lite
local function importAsset(id, cat)
    busy = true
    setStatus("IMPORT ID " .. id .. " KE STUDIO LITE…", C.warn)
    local ok, info = false, ""
    if cat == 10 then
        local gok, objs = pcall(function() return game:GetObjects("rbxassetid://" .. id) end)
        if gok and type(objs) == "table" and #objs > 0 then
            for _, o in ipairs(objs) do
                pcall(function() o.Parent = workspace end)
                anchorTree(o)
                spawnInFrontOfCamera(o)
                lockAnchored(o)
                pcall(queueAssetsFromRBXM, o)
                local all = { o }
                for _, d in ipairs(o:GetDescendants()) do all[#all + 1] = d end
                for _, d in ipairs(all) do
                    if d:IsA("LuaSourceContainer") then pcall(injectStudioLiteUI, d, {}) end
                end
            end
            flushServerLoadsAsync()
            ok, info = true, ("MODEL %d • %d OBJEK MASUK WORKSPACE"):format(id, #objs)
        else
            info = "GetObjects gagal: " .. tostring(objs)
        end
    elseif cat == 4 then
        local mesh, how = tryAssetServiceMesh(id)
        triggerServerLoad(id)
        if mesh then
            mesh.Name = "Mesh_" .. id
            anchorPart(mesh)
            pcall(function() mesh.Parent = workspace end)
            spawnInFrontOfCamera(mesh)
            lockAnchored(mesh)
            ok, info = true, ("MESH %d MASUK WORKSPACE (%s)"):format(id, tostring(how))
        elseif getStudioLiteServerFuncs() then
            ok, info = true, ("MESH %d DIKIRIM KE STUDIO LITE"):format(id)
        else
            info = "Mesh gagal: " .. tostring(how)
        end
    else
        if getStudioLiteServerFuncs() then
            triggerServerLoad(id)
            ok, info = true, ("ID %d DIKIRIM KE STUDIO LITE"):format(id)
        else
            info = "StudioLiteFolder tidak ditemukan di game ini"
        end
    end
    busy = false
    setStatus(info, ok and C.ok or C.bad)
    return ok
end

local function makeTbCard(order, id, meta, cat)
    local card = glass(tbList, 0.92, 14)
    card.LayoutOrder = order
    card.ZIndex = 22
    local thumb = Instance.new("ImageLabel")
    thumb.Position = UDim2.fromOffset(7, 7)
    thumb.Size = UDim2.fromOffset(56, 56)
    thumb.BackgroundColor3 = WHITE
    thumb.BackgroundTransparency = 0.9
    thumb.Image = ("rbxthumb://type=Asset&id=%d&w=150&h=150"):format(id)
    thumb.ScaleType = Enum.ScaleType.Fit
    thumb.ZIndex = 23
    thumb.Parent = card
    corner(thumb, 10)
    local nameBtn = Instance.new("TextButton")
    nameBtn.BackgroundTransparency = 1
    nameBtn.Position = UDim2.fromOffset(70, 6)
    nameBtn.Size = UDim2.new(1, -76, 0, 16)
    nameBtn.Text = meta.name or ("Asset " .. id)
    nameBtn.TextSize = 11
    nameBtn.Font = Enum.Font.GothamBold
    nameBtn.TextColor3 = C.text
    nameBtn.TextXAlignment = Enum.TextXAlignment.Left
    nameBtn.TextTruncate = Enum.TextTruncate.AtEnd
    nameBtn.ZIndex = 24
    nameBtn.Parent = card
    local sub = label(card, "ID " .. id .. (meta.creator and ("  •  " .. meta.creator) or ""), 9, Enum.Font.GothamMedium, C.muted)
    sub.Position = UDim2.fromOffset(70, 22)
    sub.Size = UDim2.new(1, -76, 0, 14)
    sub.TextTruncate = Enum.TextTruncate.AtEnd
    sub.ZIndex = 23
    local copyB = button(card, "COPY ID", nil, 9)
    copyB.Position = UDim2.new(0, 70, 1, -27)
    copyB.Size = UDim2.new(0.5, -40, 0, 22)
    copyB.ZIndex = 24
    local impB = button(card, "IMPORT", "accent", 9)
    impB.AnchorPoint = Vector2.new(1, 0)
    impB.Position = UDim2.new(1, -7, 1, -27)
    impB.Size = UDim2.new(0.5, -40, 0, 22)
    impB.ZIndex = 24
    local function flash(b, text, back)
        b.Text = text
        task.delay(1.5, function() if b.Parent then b.Text = back end end)
    end
    nameBtn.MouseButton1Click:Connect(function()
        if copyText(nameBtn.Text) then setStatus("NAMA DISALIN • " .. nameBtn.Text, C.ok) end
    end)
    copyB.MouseButton1Click:Connect(function()
        if copyText(tostring(id)) then
            setStatus("ID DISALIN • " .. id, C.ok)
            flash(copyB, "✓ COPIED", "COPY ID")
        else
            setStatus("CLIPBOARD TIDAK TERSEDIA", C.bad)
        end
    end)
    local working = false
    impB.MouseButton1Click:Connect(function()
        if working then return end
        working = true
        impB.Text = "…"
        task.spawn(function()
            local ok = importAsset(id, cat)
            working = false
            flash(impB, ok and "✓ DONE" or "GAGAL", "IMPORT")
            if ok then notify("Melss x Medi", "ID " .. id .. " masuk Studio Lite.") end
        end)
    end)
    if not meta.name then
        task.spawn(function()
            local d = httpGetJson("https://economy.roblox.com/v2/assets/" .. id .. "/details")
            if d and nameBtn.Parent then
                if d.Name then nameBtn.Text = d.Name end
                if d.Creator and d.Creator.Name then sub.Text = "ID " .. id .. "  •  " .. d.Creator.Name end
            end
        end)
    end
end

-- paging: muat terus saat digulir ke bawah
local TB_PAGE = 30
local tbToken = 0
local tbS = { q = nil, cat = 10, page = 0, loading = false, done = true, count = 0, seen = {} }
local function tbMsg(m)
    tbEmpty.Text = m
    tbEmpty.Visible = m ~= ""
end
local function fetchIds(q, cat, page)
    local ids, total = {}, nil
    local enc = HttpService:UrlEncode(q)
    for _, url in ipairs({
        ("https://apis.roblox.com/toolbox-service/v1/marketplace/%d?limit=%d&pageNumber=%d&keyword=%s&sortType=Relevance"):format(cat, TB_PAGE, page, enc),
        ("https://apis.roblox.com/toolbox-service/v1/marketplace/%d?keyword=%s&num=%d&pageNumber=%d"):format(cat, enc, TB_PAGE, page),
    }) do
        local data = httpGetJson(url)
        if data and type(data.data) == "table" then
            total = tonumber(data.totalResults) or total
            for _, e in ipairs(data.data) do
                local rawId = tonumber((type(e) == "table") and (e.id or e.Id or e.assetId) or e)
                if rawId then ids[#ids + 1] = rawId end
            end
        end
        if #ids > 0 then break end
    end
    return ids, total
end
local function fetchMeta(ids)
    local metaById = {}
    for i = 1, #ids, 30 do
        local chunk = {}
        for j = i, math.min(i + 29, #ids) do chunk[#chunk + 1] = ids[j] end
        local det = httpGetJson("https://apis.roblox.com/toolbox-service/v1/items/details?assetIds=" .. table.concat(chunk, ","))
        if det and type(det.data) == "table" then
            for _, d in ipairs(det.data) do
                local a = d.asset or d
                local aid = tonumber(a.id or a.Id)
                if aid then
                    metaById[aid] = { name = a.name or a.Name, creator = d.creator and (d.creator.name or d.creator.Name) or nil }
                end
            end
        end
    end
    return metaById
end
local function loadPage()
    if tbS.loading or tbS.done or not tbS.q then return end
    tbS.loading = true
    local my = tbToken
    local q, cat, page = tbS.q, tbS.cat, tbS.page
    busy = true
    setStatus(("TOOLBOX • MEMUAT HALAMAN %d…"):format(page + 1), C.warn)
    task.spawn(function()
        local ids, total = fetchIds(q, cat, page)
        if my ~= tbToken then return end
        local fresh = {}
        for _, id in ipairs(ids) do
            if not tbS.seen[id] then tbS.seen[id] = true fresh[#fresh + 1] = id end
        end
        if #fresh == 0 then
            tbS.loading, tbS.done, busy = false, true, false
            if tbS.count == 0 then
                tbMsg(httpRequest and ("Tidak ada hasil untuk \"" .. q .. "\"") or "Executor tidak punya fungsi request()")
                setStatus("TOOLBOX • 0 HASIL", C.warn)
            else
                setStatus(("TOOLBOX • SEMUA DIMUAT • %d ASET"):format(tbS.count), C.ok)
            end
            return
        end
        local meta = fetchMeta(fresh)
        if my ~= tbToken then return end
        tbMsg("")
        for _, id in ipairs(fresh) do
            if my ~= tbToken then return end
            tbS.count += 1
            makeTbCard(tbS.count, id, meta[id] or {}, cat)
            if tbS.count % 6 == 0 then task.wait() end
        end
        tbS.page = page + 1
        tbS.loading, busy = false, false
        if total and tbS.count >= total then tbS.done = true end
        setStatus(("TOOLBOX • %d ASET%s"):format(tbS.count, tbS.done and "" or " • gulir untuk muat lagi"), C.ok)
    end)
end
local function tbSearchNow()
    local q = tbSearch.Text:gsub("^%s+", ""):gsub("%s+$", "")
    tbToken += 1
    local my = tbToken
    for _, c in ipairs(tbList:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    tbS = { q = nil, cat = tbCat, page = 0, loading = false, done = true, count = 0, seen = {} }
    if q == "" then tbMsg("Ketik nama aset atau ID lalu tekan CARI") return end
    pcall(function() tbList.CanvasPosition = Vector2.zero end)
    tbMsg("Mencari…")
    if q:match("^%d+$") then
        local id = tonumber(q)
        task.spawn(function()
            local meta = fetchMeta({ id })
            if my ~= tbToken then return end
            tbMsg("")
            tbS.count = 1
            makeTbCard(1, id, meta[id] or {}, tbCat)
            setStatus("TOOLBOX • ID " .. id, C.ok)
        end)
        return
    end
    tbS.q, tbS.done = q, false
    loadPage()
end
tbList:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
    if tbS.loading or tbS.done or not tbS.q then return end
    local remain = tbList.AbsoluteCanvasSize.Y - (tbList.CanvasPosition.Y + tbList.AbsoluteWindowSize.Y)
    if remain < 160 then loadPage() end
end)
goBtn.MouseButton1Click:Connect(tbSearchNow)
tbSearch.FocusLost:Connect(function(enter) if enter then tbSearchNow() end end)

-- =====================================================================
--                       PINDAH TAB, BUKA / TUTUP
-- =====================================================================
local currentTab = "IMPORTER"
local function setTab(name)
    currentTab = name
    importer.Visible = name == "IMPORTER"
    toolbox.Visible = name == "TOOLBOX"
    tween(tabPill, 0.25, { Position = name == "IMPORTER" and UDim2.fromOffset(3, 3) or UDim2.new(0.5, 3, 0, 3) },
        Enum.EasingStyle.Back)
    for n, b in pairs(tabBtns) do b.TextColor3 = n == name and WHITE or C.muted end
end
for n, b in pairs(tabBtns) do b.MouseButton1Click:Connect(function() setTab(n) end) end
setTab("IMPORTER")

local isOpen = false
local function setOpen(v)
    if v == isOpen then return end
    isOpen = v
    local target = fitScale()
    if v then
        main.Visible = true
        mainScale.Scale = target * 0.85
        main.BackgroundTransparency = 0.4
        tween(mainScale, 0.28, { Scale = target }, Enum.EasingStyle.Back)
        tween(main, 0.2, { BackgroundTransparency = 0.06 })
    else
        local tw = tween(mainScale, 0.16, { Scale = target * 0.85 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        tween(main, 0.16, { BackgroundTransparency = 0.4 })
        tw.Completed:Connect(function() if not isOpen then main.Visible = false end end)
    end
end
closeBtn.MouseButton1Click:Connect(function() setOpen(false) end)
minBtn.MouseButton1Click:Connect(function() setOpen(false) end)

-- geser panel lewat header
do
    local dragging, ds, sp = false, nil, nil
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, ds, sp = true, input.Position, main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - ds
            main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end)
end
-- tombol bulat: tap = buka/tutup, geser = pindah
do
    local dragging, moved, ds, sp = false, false, nil, nil
    toggle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, moved, ds, sp = true, false, input.Position, toggle.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if not moved then setOpen(not isOpen) end
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local d = input.Position - ds
            if math.abs(d.X) > 6 or math.abs(d.Y) > 6 then moved = true end
            if moved then toggle.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y) end
        end
    end)
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    if isOpen then mainScale.Scale = fitScale() end
end)

setOpen(true)
task.delay(0.4, scanNow)
print("[Melss x Medi] Importer RBXM/RBXL + Toolbox PC siap")
end)()
