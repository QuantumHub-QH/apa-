--[[
============================================================
  ENGINE STUDIO BYPASS  |  RBXL / RBXM IMPORTER + EXPORTER
  Engine : LANGZ RBXL core (restore source, runtime bridge,
           Studio Lite editor inject, GetScriptSource hook)
           + MedStudio Export Engine (binary RBXM/RBXL writer)
  Toggle : rbxassetid://137771867948384
  FIX    : blok DASHBOARD, TOOLBOX, AKUN dibungkus function
           supaya tidak melewati batas local per chunk.
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
    probe.Name = "__WN_PROBE"
    probe.Parent = CoreGui
    probe:Destroy()
    CoreDest = CoreGui
end)

_G.Langz_RAW_SOURCES = _G.Langz_RAW_SOURCES or {}
_G.Langz_RAW_SOURCE_BY_REF = _G.Langz_RAW_SOURCE_BY_REF or {}

-- ============ AUTO ANCHOR (semua hasil spawn / import) ============
local function anchorPart(p)
    if not p or not p:IsA("BasePart") then return end
    pcall(function()
        if p:GetAttribute("LANGZ_FileAnchored") == nil then
            p:SetAttribute("LANGZ_FileAnchored", p.Anchored)
        end
        p:SetAttribute("LANGZ_AutoAnchored", true)
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

if type(string.unpack) ~= "function" then
    warn("[WLEO RBXL] string.unpack tidak tersedia. Binary RBXL tidak dapat dibaca.")
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
            warn(("[WLEO RBXL] property skipped: %s (type 0x%02X)"):format(pname, typeID or 0))
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

-- ============ STUDIO LITE BRIDGE ============
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
    local realSource = _G.Langz_RAW_SOURCES[scr] or (sourceMap and sourceMap[path])
    if not realSource then pcall(function() realSource = scr.Source end) end
    if realSource and #realSource > 0 then
        realSource = realSource:gsub(string.char(0) .. "*$", "")
    else
        realSource = ""
    end
    _G.Langz_RAW_SOURCES[scr] = realSource
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

-- ============ PROPERTY APPLY ============
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
            _G.Langz_RAW_SOURCES[obj] = clean
            local refKey = obj:GetAttribute("LANGZ_Ref")
            if refKey ~= nil then _G.Langz_RAW_SOURCE_BY_REF[tostring(refKey)] = clean end
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
    mesh.Name = "__LANGZ_MeshVisual"
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
        mesh.Name = "__LANGZ_CSGVisual"
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
    local o = obj:GetAttribute("LANGZ_OriginalEnabled")
    if o ~= nil then return o == true end
    local d = obj:GetAttribute("LANGZ_OriginalDisabled")
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
    local cb = _G.WN_IMPORT_PROGRESS_CB
    if type(cb) == "function" then pcall(cb, value, message) end
end

-- ============ BUILD RBXL ============
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
    importRoot:SetAttribute("LANGZ_RBXL_IMPORT", true)
    importRoot:SetAttribute("LANGZ_SourceFile", tostring(sourceFileName or ""))
    importRoot.Parent = nil
    local containers = {}
    local function newServiceFolder(key, displayName)
        local folder = Instance.new("Folder")
        folder.Name = displayName
        folder:SetAttribute("LANGZ_ServiceKey", key)
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
            obj:SetAttribute("LANGZ_FileAnchored", originalAnchored)
            obj:SetAttribute("SL_CanCollide", originalCanCollide)
            obj.Anchored = true
        end)
    end
    local function disableImportedScript(obj, node)
        if not obj:IsA("LuaSourceContainer") then return end
        local originalEnabled = getOriginalScriptEnabled(obj, node)
        pcall(function()
            obj:SetAttribute("LANGZ_OriginalEnabled", originalEnabled)
            obj:SetAttribute("LANGZ_OriginalDisabled", not originalEnabled)
            obj:SetAttribute("LANGZ_StagedDisabled", true)
        end)
        setScriptEnabledState(obj, false)
    end
    local function normalizePartGeometry(obj, node)
        if not obj:IsA("BasePart") then return end
        local p = node.Properties or {}
        applyBaseVisualState(obj, p)
        local special = obj:FindFirstChild("__LANGZ_MeshVisual") or obj:FindFirstChild("__LANGZ_CSGVisual")
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
            obj:SetAttribute("LANGZ_ImportedObject", true)
            obj:SetAttribute("LANGZ_Ref", tostring(node.Ref))
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

-- ============ XML (RBXLX / RBXMX) ============
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

-- ============ RBXM ============
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
    _G.Langz_RAW_SOURCES[scr] = source
    local refKey = scr:GetAttribute("LANGZ_Ref")
    if refKey ~= nil then _G.Langz_RAW_SOURCE_BY_REF[tostring(refKey)] = source end
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
            obj:SetAttribute("LANGZ_ImportedObject", true)
            obj:SetAttribute("LANGZ_Ref", tostring(node.Ref))
            obj:SetAttribute("LANGZ_RBXMSource", tostring(sourceFileName or ""))
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
                obj:SetAttribute("LANGZ_FileAnchored", original)
                obj:SetAttribute("LANGZ_AutoAnchored", true)
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
            pcall(function() obj.Anchored = true; obj:SetAttribute("LANGZ_AutoAnchored", true) end)
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
            root:SetAttribute("LANGZ_ImportedObject", true)
            root:SetAttribute("LANGZ_RBXMSource", fileInfo.name)
            root.Parent = workspace
            importedRoots[#importedRoots + 1] = root
            local descendants = root:GetDescendants()
            local all = {root}
            for _, d in ipairs(descendants) do all[#all + 1] = d end
            totalObjects += #all
            for i, obj in ipairs(all) do
                obj:SetAttribute("LANGZ_ImportedObject", true)
                if obj:IsA("BasePart") then
                    local saved = obj.Anchored
                    obj:SetAttribute("LANGZ_FileAnchored", saved)
                    obj:SetAttribute("LANGZ_AutoAnchored", true)
                    obj.Anchored = true
                end
                if obj:IsA("LuaSourceContainer") then
                    scriptCount += 1
                    local source = takeRBXMSource(sourceQueues, obj)
                    if source then
                        sourceFound += 1
                        _G.Langz_RAW_SOURCES[obj] = source
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

-- ============ RUNTIME BRIDGE (LocalScript / ModuleScript) ============
local WN_MODULE_CACHE = setmetatable({}, {__mode = "k"})
local WN_MODULE_LOADING = setmetatable({}, {__mode = "k"})
local function rawSourceFor(scr)
    if not scr or not scr:IsA("LuaSourceContainer") then return nil end
    local direct = _G.Langz_RAW_SOURCES[scr]
    if type(direct) == "string" and direct ~= "" then return direct end
    local refKey = scr:GetAttribute("LANGZ_Ref")
    if refKey ~= nil then
        local byRef = _G.Langz_RAW_SOURCE_BY_REF[tostring(refKey)]
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
    local okCompile, loaderOrErr = pcall(loadstring, wrapped, "=WLEO_RBXL/" .. tostring(scr:GetFullName()))
    if not okCompile or type(loaderOrErr) ~= "function" then return nil, tostring(loaderOrErr) end
    local okFactory, runnerOrErr = pcall(loaderOrErr)
    if not okFactory or type(runnerOrErr) ~= "function" then return nil, tostring(runnerOrErr) end
    return runnerOrErr
end
runtimeRequire = function(target)
    if typeof(target) == "Instance" and target:IsA("ModuleScript") then
        if WN_MODULE_CACHE[target] ~= nil then return WN_MODULE_CACHE[target] end
        if WN_MODULE_LOADING[target] then error("WLEO runtime require circular dependency: " .. target:GetFullName()) end
        local source = rawSourceFor(target)
        if source then
            WN_MODULE_LOADING[target] = true
            local runner, compileErr = compileRuntimeSource(target, source)
            if not runner then
                WN_MODULE_LOADING[target] = nil
                error("Module compile failed: " .. tostring(compileErr))
            end
            local results = table.pack(pcall(runner, target, runtimeRequire))
            WN_MODULE_LOADING[target] = nil
            if not results[1] then error(results[2]) end
            WN_MODULE_CACHE[target] = results[2]
            return results[2]
        end
    end
    return require(target)
end
local function runLocalScriptBridge(scr)
    if not scr or not scr:IsA("LocalScript") then return false, "not_local_script" end
    if not importedScriptShouldRun(scr) then return false, "originally_disabled" end
    if scr:GetAttribute("LANGZ_RuntimeStarted") then return true, "already_started" end
    local source = rawSourceFor(scr)
    if not source then return false, "source_missing" end
    local runner, compileErr = compileRuntimeSource(scr, source)
    if not runner then return false, "compile: " .. tostring(compileErr) end
    scr:SetAttribute("LANGZ_RuntimeStarted", true)
    task.spawn(function()
        local ok, runtimeErr = pcall(runner, scr, runtimeRequire)
        if not ok then
            warn("[WLEO LIVE SCRIPT ERROR] " .. scr:GetFullName() .. " :: " .. tostring(runtimeErr))
            scr:SetAttribute("LANGZ_RuntimeError", tostring(runtimeErr))
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
    _G.Langz_RAW_SOURCES[scr] = source
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
            pcall(function() obj.Anchored = true; obj:SetAttribute("LANGZ_AutoAnchored", true) end)
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

-- ============ ACTIVATE (deploy ke service asli + restore script) ============
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
            obj:SetAttribute("LANGZ_CreatedService", true)
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
            local dest = destinationByKey[folder:GetAttribute("LANGZ_ServiceKey")]
            if dest then moved += moveChildren(folder, dest) end
        end
    end
    reportImportProgress(0.91, ("DEPLOYED • %d OBJECTS"):format(moved))

    local activatedScripts = 0
    local function restoreOne(obj)
        if not obj:IsA("LuaSourceContainer") or not obj:GetAttribute("LANGZ_StagedDisabled") then return end
        local shouldRun = importedScriptShouldRun(obj)
        setScriptEnabledState(obj, shouldRun)
        pcall(function() obj:SetAttribute("LANGZ_StagedDisabled", nil) end)
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
            if child:GetAttribute("LANGZ_ImportedObject") == true then
                local existing = dst:FindFirstChild(child.Name)
                if existing and existing:GetAttribute("LANGZ_LiveClone") == true then
                    pcall(function() existing:Destroy() end)
                end
                local clone
                if pcall(function() clone = child:Clone() end) and clone then
                    clone:SetAttribute("LANGZ_LiveClone", true)
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
            if obj:IsA("LocalScript") and obj:GetAttribute("LANGZ_ImportedObject") == true then
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
            if obj:IsA("LuaSourceContainer") and obj:GetAttribute("LANGZ_ImportedObject") == true then
                if key == "SSS" then sssN += 1 elseif key == "SS" then ssN += 1 end
                local source = rawSourceFor(obj)
                if source then
                    _G.Langz_RAW_SOURCES[obj] = source
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
                if obj:GetAttribute("LANGZ_ImportedObject") == true then
                    if obj:IsA("LuaSourceContainer") then
                        setScriptEnabledState(obj, importedScriptShouldRun(obj))
                    elseif obj:IsA("BasePart") then
                        pcall(function() obj.Anchored = true; obj:SetAttribute("LANGZ_AutoAnchored", true) end)
                    end
                end
            end
        end
    end
    importRoot:SetAttribute("LANGZ_Activated", true)
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

-- ============ FILE SCAN ============
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

-- ============ GetScriptSource hook (dipasang awal supaya editor SL tidak "not found") ============
task.spawn(function()
    pcall(function()
        if type(hookmetamethod) ~= "function" or type(getnamecallmethod) ~= "function" or type(checkcaller) ~= "function" then return end
        if _G.WN_SRC_HOOKED then return end
        _G.WN_SRC_HOOKED = true
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if not checkcaller() and method == "InvokeServer" then
                local nm = ""
                pcall(function() nm = self.Name end)
                if nm == "GetScriptSourceServerFunction" then
                    local target = tostring((...))
                    for obj, source in pairs(_G.Langz_RAW_SOURCES) do
                        if typeof(obj) == "Instance" and (obj.ClassName .. obj.Name) == target and source and source ~= "" then
                            return source
                        end
                    end
                elseif nm == "SaveScriptSourceServerFunction" then
                    local args = {...}
                    local target, newSource = tostring(args[1]), tostring(args[2])
                    for obj in pairs(_G.Langz_RAW_SOURCES) do
                        if typeof(obj) == "Instance" and (obj.ClassName .. obj.Name) == target then
                            _G.Langz_RAW_SOURCES[obj] = newSource
                            break
                        end
                    end
                end
            end
            return oldNamecall(self, ...)
        end)
    end)
end)

-- =====================================================================
--                        LIQUID GLASS UI
-- =====================================================================
local TOGGLE_ICON = "rbxassetid://92844638469747"
local GUI_NAME = "ENGINE_STUDIO_BYPASS"
do
    local old = CoreDest:FindFirstChild(GUI_NAME)
    if old then old:Destroy() end
end

local C = {
    text    = Color3.fromRGB(255, 255, 255),
    soft    = Color3.fromRGB(214, 224, 250),
    muted   = Color3.fromRGB(165, 180, 222),
    accent  = Color3.fromRGB(105, 205, 255),
    accent2 = Color3.fromRGB(160, 125, 255),
    ok      = Color3.fromRGB(95, 235, 175),
    warn    = Color3.fromRGB(255, 205, 100),
    bad     = Color3.fromRGB(255, 115, 140),
}

local gui = Instance.new("ScreenGui")
gui.Name = GUI_NAME
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 800
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = CoreDest

local function corner(o, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 10); c.Parent = o; return c end
local function grad(o, c0, c1, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(c0, c1)
    g.Rotation = rot or 90
    g.Parent = o
    return g
end
local function glassStroke(o, thick, strong)
    local s = Instance.new("UIStroke")
    s.Thickness = thick or 1.2
    s.Color = Color3.fromRGB(255, 255, 255)
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Transparency = 0
    s.Parent = o
    local g = Instance.new("UIGradient")
    g.Rotation = 90
    local a = strong and 0.15 or 0.35
    g.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, a),
        NumberSequenceKeypoint.new(0.5, 0.85),
        NumberSequenceKeypoint.new(1, 0.6),
    })
    g.Parent = s
    return s
end
local function text(parent, str, size, font, color, xa)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = str
    l.TextSize = size
    l.Font = font or Enum.Font.GothamMedium
    l.TextColor3 = color or C.text
    l.TextXAlignment = xa or Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.Parent = parent
    return l
end
-- kartu kaca: dasar terang transparan + kilau atas
local function glassPanel(parent, alpha, r)
    local f = Instance.new("Frame")
    f.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    f.BackgroundTransparency = alpha or 0.88
    f.BorderSizePixel = 0
    f.Parent = parent
    corner(f, r or 12)
    glassStroke(f, 1)
    return f
end

-- ---------- toggle ----------
local toggle = Instance.new("ImageButton")
toggle.Name = "Toggle"
toggle.Size = UDim2.fromOffset(46, 46)
toggle.Position = UDim2.new(0, 10, 0, 70)
toggle.BackgroundColor3 = Color3.fromRGB(40, 55, 110)
toggle.BackgroundTransparency = 0.25
toggle.Image = TOGGLE_ICON
toggle.ScaleType = Enum.ScaleType.Fit
toggle.AutoButtonColor = false
toggle.ZIndex = 50
toggle.Parent = gui
corner(toggle, 14)
glassStroke(toggle, 1.5, true)
do
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 5); pad.PaddingBottom = UDim.new(0, 5)
    pad.PaddingLeft = UDim.new(0, 5); pad.PaddingRight = UDim.new(0, 5)
    pad.Parent = toggle
end

-- ---------- main ----------
local MAIN_W, MAIN_H = 540, 345
local main = Instance.new("Frame")
main.Name = "Main"
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.fromScale(0.5, 0.5)
main.Size = UDim2.fromOffset(MAIN_W, MAIN_H)
main.BackgroundColor3 = Color3.fromRGB(34, 46, 92)
main.BackgroundTransparency = 0.12
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Visible = false
main.ZIndex = 10
main.Parent = gui
corner(main, 20)
grad(main, Color3.fromRGB(78, 96, 190), Color3.fromRGB(26, 34, 74), 55)
glassStroke(main, 1.8, true)

local mainScale = Instance.new("UIScale")
mainScale.Parent = main
local function fitScale()
    local v = gui.AbsoluteSize
    if v.X <= 0 then v = Vector2.new(800, 400) end
    return math.clamp(math.min((v.X - 24) / MAIN_W, (v.Y - 24) / MAIN_H), 0.5, 1.15)
end
mainScale.Scale = fitScale()

-- kilau kaca di atas
do
    local shine = Instance.new("Frame")
    shine.Size = UDim2.new(1, 0, 0, 120)
    shine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    shine.BackgroundTransparency = 0.9
    shine.BorderSizePixel = 0
    shine.ZIndex = 10
    shine.Parent = main
    local g = Instance.new("UIGradient")
    g.Rotation = 90
    g.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) })
    g.Parent = shine
    local blobA = Instance.new("Frame")
    blobA.Size = UDim2.fromOffset(220, 220)
    blobA.Position = UDim2.new(1, -120, 1, -110)
    blobA.BackgroundColor3 = C.accent2
    blobA.BackgroundTransparency = 0.8
    blobA.BorderSizePixel = 0
    blobA.ZIndex = 10
    blobA.Parent = main
    corner(blobA, 110)
    local blobB = Instance.new("Frame")
    blobB.Size = UDim2.fromOffset(180, 180)
    blobB.Position = UDim2.new(0, -70, 1, -90)
    blobB.BackgroundColor3 = C.accent
    blobB.BackgroundTransparency = 0.82
    blobB.BorderSizePixel = 0
    blobB.ZIndex = 10
    blobB.Parent = main
    corner(blobB, 90)
end

-- ---------- header ----------
local closeBtn, backBtn, hdrTitle, hdrSub
do
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, -24, 0, 42)
    header.Position = UDim2.fromOffset(12, 8)
    header.BackgroundTransparency = 1
    header.ZIndex = 20
    header.Parent = main

    local logo = Instance.new("ImageLabel")
    logo.Size = UDim2.fromOffset(34, 34)
    logo.Position = UDim2.fromOffset(0, 4)
    logo.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    logo.BackgroundTransparency = 0.85
    logo.Image = TOGGLE_ICON
    logo.ScaleType = Enum.ScaleType.Fit
    logo.ZIndex = 21
    logo.Parent = header
    corner(logo, 11)
    glassStroke(logo, 1)

    local title = text(header, "ENGINE STUDIO BYPASS", 16, Enum.Font.GothamBold, C.text)
    title.Position = UDim2.fromOffset(44, 2)
    title.Size = UDim2.new(1, -120, 0, 20)
    title.ZIndex = 21
    local subtitle = text(header, "IMPORT • EXPORT • TOOLBOX", 10, Enum.Font.GothamMedium, C.accent)
    subtitle.Position = UDim2.fromOffset(44, 22)
    subtitle.Size = UDim2.new(1, -120, 0, 14)
    subtitle.ZIndex = 21

    closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.fromOffset(28, 28)
    closeBtn.AnchorPoint = Vector2.new(1, 0)
    closeBtn.Position = UDim2.new(1, 0, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.BackgroundTransparency = 0.85
    closeBtn.Text = "×"
    closeBtn.TextSize = 20
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextColor3 = C.text
    closeBtn.AutoButtonColor = false
    closeBtn.ZIndex = 22
    closeBtn.Parent = header
    corner(closeBtn, 9)
    glassStroke(closeBtn, 1)

    hdrTitle, hdrSub = title, subtitle

    backBtn = Instance.new("TextButton")
    backBtn.Name = "BackBtn"
    backBtn.AnchorPoint = Vector2.new(1, 0)
    backBtn.Size = UDim2.fromOffset(66, 28)
    backBtn.Position = UDim2.new(1, -36, 0, 5)
    backBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    backBtn.BackgroundTransparency = 0.85
    backBtn.Text = "< BACK"
    backBtn.TextSize = 11
    backBtn.Font = Enum.Font.GothamBold
    backBtn.TextColor3 = C.accent
    backBtn.AutoButtonColor = false
    backBtn.Visible = false
    backBtn.ZIndex = 22
    backBtn.Parent = header
    corner(backBtn, 9)
    glassStroke(backBtn, 1)
end

-- ---------- icon format ----------
local ICONS = {
    RBXM    = "rbxassetid://106962661743892",
    RBXMX   = "rbxassetid://106962661743892",
    RBXL    = "rbxassetid://122982660526589",
    RBXLX   = "rbxassetid://122982660526589",
    TOOLBOX = "rbxassetid://121323758319527",
    HOME    = "rbxassetid://134003209888315",
    AKUN    = "rbxassetid://135151885033456",
    EXPORT  = "rbxassetid://106962661743892",
}

-- ---------- sidebar ----------
local SIDE_W = 120
local side = glassPanel(main, 0.9, 14)
side.Position = UDim2.fromOffset(12, 56)
side.Size = UDim2.fromOffset(SIDE_W, MAIN_H - 68)
side.ZIndex = 20

local sideScroll = Instance.new("ScrollingFrame")
sideScroll.Name = "SideScroll"
sideScroll.Position = UDim2.fromOffset(0, 2)
sideScroll.Size = UDim2.new(1, 0, 1, -36)
sideScroll.BackgroundTransparency = 1
sideScroll.BorderSizePixel = 0
sideScroll.ScrollBarThickness = 2
sideScroll.ScrollBarImageColor3 = C.accent
sideScroll.CanvasSize = UDim2.fromOffset(0, 290)
sideScroll.ZIndex = 20
sideScroll.Parent = side

local function sideCategory(labelText, y, withDivider)
    if withDivider then
        local div = Instance.new("Frame")
        div.Position = UDim2.fromOffset(10, y - 3)
        div.Size = UDim2.new(1, -20, 0, 1)
        div.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        div.BackgroundTransparency = 0.85
        div.BorderSizePixel = 0
        div.ZIndex = 21
        div.Parent = sideScroll
    end
    local l = text(sideScroll, labelText, 10, Enum.Font.GothamBold, C.muted)
    l.Position = UDim2.fromOffset(12, y)
    l.Size = UDim2.new(1, -24, 0, 14)
    l.ZIndex = 21
end

-- state dashboard / panel (dipakai banyak bagian)
local DASH = { mode = "dash", hooks = {}, tiles = {}, stat = {} }
local ACCT = { connected = false, data = {} }
local TAB_LABEL = { HOME = "HOME", TOOLBOX = "TOOLBOX PC", AKUN = "AKUN", EXPORT = "EXPORT" }
local function tabLabel(n) return TAB_LABEL[n] or n end

local tabButtons = {}
local function makeTab(name, y)
    local noBadge = (name == "TOOLBOX" or name == "HOME" or name == "AKUN" or name == "EXPORT")
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -12, 0, 26)
    b.Position = UDim2.fromOffset(6, y)
    b.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    b.BackgroundTransparency = 0.9
    b.Text = ""
    b.AutoButtonColor = false
    b.ZIndex = 21
    b.Parent = sideScroll
    corner(b, 10)
    glassStroke(b, 1)

    if ICONS[name] then
        local ic = Instance.new("ImageLabel")
        ic.Position = UDim2.fromOffset(6, 3)
        ic.Size = UDim2.fromOffset(20, 20)
        ic.BackgroundTransparency = 1
        ic.Image = ICONS[name]
        ic.ScaleType = Enum.ScaleType.Fit
        ic.ZIndex = 22
        ic.Parent = b
    else
        local ic = text(b, name:sub(1, 1), 10, Enum.Font.GothamBold, Color3.fromRGB(10, 20, 50), Enum.TextXAlignment.Center)
        ic.Position = UDim2.fromOffset(6, 3)
        ic.Size = UDim2.fromOffset(20, 20)
        ic.BackgroundTransparency = 0.1
        ic.BackgroundColor3 = (name == "AKUN") and C.accent2 or C.accent
        ic.ZIndex = 22
        corner(ic, 6)
    end

    local lbl = text(b, tabLabel(name), 10, Enum.Font.GothamBold, C.text)
    lbl.Position = UDim2.fromOffset(32, 0)
    lbl.Size = UDim2.new(1, noBadge and -36 or -62, 1, 0)
    lbl.TextTruncate = Enum.TextTruncate.AtEnd
    lbl.ZIndex = 22

    local badge
    if not noBadge then
        badge = text(b, "0", 10, Enum.Font.GothamBold, C.text, Enum.TextXAlignment.Center)
        badge.AnchorPoint = Vector2.new(1, 0.5)
        badge.Position = UDim2.new(1, -6, 0.5, 0)
        badge.Size = UDim2.fromOffset(24, 16)
        badge.BackgroundTransparency = 0.7
        badge.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        badge.ZIndex = 22
        corner(badge, 7)
    end
    tabButtons[name] = { btn = b, lbl = lbl, badge = badge }
end

sideCategory("MENU", 3, false)
makeTab("HOME", 17)
makeTab("EXPORT", 45)
makeTab("TOOLBOX", 73)
sideCategory("IMPORTER", 105, true)
makeTab("RBXM", 120)
makeTab("RBXMX", 147)
makeTab("RBXL", 174)
makeTab("RBXLX", 201)
sideCategory("GENERAL", 233, true)
makeTab("AKUN", 248)

local scanBtn = Instance.new("TextButton")
scanBtn.Size = UDim2.new(1, -12, 0, 24)
scanBtn.AnchorPoint = Vector2.new(0, 1)
scanBtn.Position = UDim2.new(0, 6, 1, -6)
scanBtn.BackgroundColor3 = C.accent
scanBtn.BackgroundTransparency = 0.15
scanBtn.Text = "SCAN"
scanBtn.TextSize = 11
scanBtn.Font = Enum.Font.GothamBold
scanBtn.TextColor3 = Color3.fromRGB(10, 20, 50)
scanBtn.AutoButtonColor = false
scanBtn.ZIndex = 22
scanBtn.Parent = side
corner(scanBtn, 10)
grad(scanBtn, Color3.fromRGB(150, 225, 255), Color3.fromRGB(110, 160, 255), 90)

-- ---------- content ----------
local content = glassPanel(main, 0.9, 14)
content.Position = UDim2.fromOffset(SIDE_W + 20, 56)
content.Size = UDim2.new(1, -(SIDE_W + 32), 1, -68)
content.ZIndex = 20

local contentTitle = text(content, "RBXM FILES", 13, Enum.Font.GothamBold, C.text)
contentTitle.Position = UDim2.fromOffset(12, 5)
contentTitle.Size = UDim2.new(1, -24, 0, 18)
contentTitle.ZIndex = 21

local searchBox = Instance.new("TextBox")
searchBox.Position = UDim2.fromOffset(8, 26)
searchBox.Size = UDim2.new(1, -16, 0, 26)
searchBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
searchBox.BackgroundTransparency = 0.82
searchBox.Text = ""
searchBox.PlaceholderText = "Cari file..."
searchBox.PlaceholderColor3 = C.muted
searchBox.TextColor3 = C.text
searchBox.TextSize = 12
searchBox.Font = Enum.Font.GothamMedium
searchBox.ClearTextOnFocus = false
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.ZIndex = 21
searchBox.Parent = content
corner(searchBox, 9)
glassStroke(searchBox, 1)
do
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 8)
    pad.Parent = searchBox
end

local list = Instance.new("ScrollingFrame")
list.Position = UDim2.fromOffset(6, 58)
list.Size = UDim2.new(1, -12, 1, -64)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 3
list.ScrollBarImageColor3 = C.accent
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
list.ZIndex = 21
list.Parent = content
do
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, 5)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = list
end

local emptyLbl = text(content, "Tekan SCAN untuk cari file", 12, Enum.Font.GothamMedium, C.soft, Enum.TextXAlignment.Center)
emptyLbl.Position = UDim2.fromOffset(10, 90)
emptyLbl.Size = UDim2.new(1, -20, 0, 60)
emptyLbl.TextWrapped = true
emptyLbl.ZIndex = 22

-- ---------- progress pill (kiri bawah layar) ----------
local fill, statusText, pctText, dot, halo
do
    local pill = Instance.new("Frame")
    pill.Name = "ProgressPill"
    pill.AnchorPoint = Vector2.new(0, 1)
    pill.Position = UDim2.new(0, 10, 1, -10)
    pill.Size = UDim2.fromOffset(190, 34)
    pill.BackgroundColor3 = Color3.fromRGB(22, 30, 66)
    pill.BackgroundTransparency = 0.2
    pill.BorderSizePixel = 0
    pill.ZIndex = 60
    pill.Parent = gui
    corner(pill, 10)
    glassStroke(pill, 1)

    halo = Instance.new("Frame")
    halo.Position = UDim2.fromOffset(7, 5)
    halo.Size = UDim2.fromOffset(14, 14)
    halo.BackgroundColor3 = C.ok
    halo.BackgroundTransparency = 0.65
    halo.BorderSizePixel = 0
    halo.ZIndex = 61
    halo.Parent = pill
    corner(halo, 7)

    dot = Instance.new("Frame")
    dot.Position = UDim2.fromOffset(10, 8)
    dot.Size = UDim2.fromOffset(8, 8)
    dot.BackgroundColor3 = C.ok
    dot.BorderSizePixel = 0
    dot.ZIndex = 62
    dot.Parent = pill
    corner(dot, 4)

    statusText = text(pill, "SIAP", 10, Enum.Font.GothamMedium, C.soft)
    statusText.Position = UDim2.fromOffset(26, 3)
    statusText.Size = UDim2.new(1, -66, 0, 18)
    statusText.TextTruncate = Enum.TextTruncate.AtEnd
    statusText.ZIndex = 62

    pctText = text(pill, "", 10, Enum.Font.GothamBold, C.ok, Enum.TextXAlignment.Right)
    pctText.AnchorPoint = Vector2.new(1, 0)
    pctText.Position = UDim2.new(1, -8, 0, 3)
    pctText.Size = UDim2.fromOffset(34, 18)
    pctText.ZIndex = 62

    local track = Instance.new("Frame")
    track.Position = UDim2.fromOffset(10, 25)
    track.Size = UDim2.new(1, -20, 0, 4)
    track.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    track.BackgroundTransparency = 0.82
    track.BorderSizePixel = 0
    track.ZIndex = 62
    track.Parent = pill
    corner(track, 2)

    fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = C.ok
    fill.BorderSizePixel = 0
    fill.ZIndex = 63
    fill.Parent = track
    corner(fill, 2)
    grad(fill, Color3.fromRGB(95, 235, 175), Color3.fromRGB(120, 225, 255), 0)
end

-- ---------- state ----------
local allFiles = {}
local currentTab = "RBXM"
local fileState = {}   -- path -> {label=, color=, root=}
local scanning = false
local statusVersion = 0
local ind = { busy = false }   -- busy = kedip cepat, idle/selesai = kedip pelan
local TB = {}                  -- toolbox handles

-- indikator ijo: kedip cepat saat proses, kedip pelan terus kalau sudah selesai
task.spawn(function()
    while gui.Parent do
        local period = ind.busy and 0.30 or 1.40
        local info = TweenInfo.new(period / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        TweenService:Create(dot, info, { BackgroundTransparency = 0.8 }):Play()
        TweenService:Create(halo, info, { BackgroundTransparency = 1 }):Play()
        task.wait(period / 2)
        TweenService:Create(dot, info, { BackgroundTransparency = 0 }):Play()
        TweenService:Create(halo, info, { BackgroundTransparency = 0.6 }):Play()
        task.wait(period / 2)
    end
end)

local function setStatus(msg, color)
    statusText.Text = tostring(msg)
    local c = (color == C.bad) and C.bad or C.ok
    dot.BackgroundColor3 = c
    halo.BackgroundColor3 = c
    if color == C.bad then
        ind.busy = false
        fill.Size = UDim2.new(0, 0, 1, 0)
        pctText.Text = ""
    end
end
local function setProgress(v, msg)
    v = math.clamp(tonumber(v) or 0, 0, 1)
    TweenService:Create(fill, TweenInfo.new(0.12), { Size = UDim2.new(v, 0, 1, 0) }):Play()
    pctText.Text = v > 0 and ("%d%%"):format(math.floor(v * 100 + 0.5)) or ""
    ind.busy = (v > 0 and v < 1)
    if msg and msg ~= "" then setStatus(msg, C.warn) end
    if v >= 1 then
        statusVersion += 1
        local myV = statusVersion
        task.delay(2, function()
            if myV == statusVersion and fill.Parent then
                fill.Size = UDim2.new(0, 0, 1, 0)
                pctText.Text = ""
            end
        end)
    end
end
_G.WN_IMPORT_PROGRESS_CB = setProgress

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
--                DASHBOARD  +  HOME (semua tombol jadi satu)
-- =====================================================================
;(function()
    local WHITE = Color3.fromRGB(255, 255, 255)
    local DARK = Color3.fromRGB(10, 20, 50)

    local function pressFx(btn, base)
        btn.MouseButton1Down:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.08), { BackgroundTransparency = math.max(base - 0.12, 0) }):Play()
        end)
        local function release()
            TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundTransparency = base }):Play()
        end
        btn.MouseButton1Up:Connect(release)
        btn.MouseLeave:Connect(release)
    end

    local function glassButton(parent, base)
        local b = Instance.new("TextButton")
        b.BackgroundColor3 = WHITE
        b.BackgroundTransparency = base
        b.BorderSizePixel = 0
        b.Text = ""
        b.AutoButtonColor = false
        b.ZIndex = 23
        b.Parent = parent
        corner(b, 12)
        glassStroke(b, 1)
        pressFx(b, base)
        return b
    end

    -- ================= DASHBOARD (sebelum panel utama) =================
    local dash = Instance.new("Frame")
    dash.Name = "Dashboard"
    dash.Position = UDim2.fromOffset(12, 56)
    dash.Size = UDim2.new(1, -24, 1, -68)
    dash.BackgroundTransparency = 1
    dash.BorderSizePixel = 0
    dash.ZIndex = 20
    dash.Parent = main
    DASH.dash = dash

    -- kartu kiri (hero)
    local hero = glassPanel(dash, 0.9, 16)
    hero.Position = UDim2.fromOffset(0, 0)
    hero.Size = UDim2.new(0, 272, 1, 0)
    hero.ZIndex = 21

    local badge = glassPanel(hero, 0.82, 11)
    badge.Position = UDim2.fromOffset(14, 14)
    badge.Size = UDim2.fromOffset(128, 22)
    badge.ZIndex = 22
    local bdot = Instance.new("Frame")
    bdot.Position = UDim2.fromOffset(10, 7)
    bdot.Size = UDim2.fromOffset(8, 8)
    bdot.BackgroundColor3 = C.ok
    bdot.BorderSizePixel = 0
    bdot.ZIndex = 23
    bdot.Parent = badge
    corner(bdot, 4)
    local btxt = text(badge, "Importer Ready", 10, Enum.Font.GothamMedium, C.soft)
    btxt.Position = UDim2.fromOffset(24, 0)
    btxt.Size = UDim2.new(1, -28, 1, 0)
    btxt.ZIndex = 23
    btxt.TextTruncate = Enum.TextTruncate.AtEnd
    DASH.badgeText = btxt

    local t1 = text(hero, "IMPORTER", 26, Enum.Font.GothamBold, C.text)
    t1.Position = UDim2.fromOffset(14, 44)
    t1.Size = UDim2.new(1, -28, 0, 28)
    t1.ZIndex = 22
    local t2 = text(hero, "DASHBOARD", 26, Enum.Font.GothamBold, C.accent)
    t2.Position = UDim2.fromOffset(14, 70)
    t2.Size = UDim2.new(1, -28, 0, 28)
    t2.ZIndex = 22

    local desc = text(hero, "Pilih file RBXM, RBXMX, RBXL & RBXLX langsung masuk ke game. Toolbox PC siap pakai, hasil spawn auto anchored.", 11, Enum.Font.GothamMedium, C.soft)
    desc.Position = UDim2.fromOffset(14, 106)
    desc.Size = UDim2.new(1, -28, 0, 50)
    desc.TextWrapped = true
    desc.TextYAlignment = Enum.TextYAlignment.Top
    desc.ZIndex = 22

    -- dua pill info: TOTAL & DIIMPOR
    local function infoPill(x, labelText, color)
        local p = glassPanel(hero, 0.86, 11)
        p.Position = UDim2.fromOffset(x, 164)
        p.Size = UDim2.fromOffset(118, 40)
        p.ZIndex = 22
        local l = text(p, labelText, 9, Enum.Font.GothamBold, C.muted)
        l.Position = UDim2.fromOffset(10, 5)
        l.Size = UDim2.new(1, -20, 0, 12)
        l.ZIndex = 23
        local v = text(p, "0", 16, Enum.Font.GothamBold, color)
        v.Position = UDim2.fromOffset(10, 17)
        v.Size = UDim2.new(1, -20, 0, 20)
        v.ZIndex = 23
        return v
    end
    local pillTotal = infoPill(14, "TOTAL FILE", C.accent)
    local pillImp = infoPill(140, "DIIMPOR", C.ok)

    local openBtn = Instance.new("TextButton")
    openBtn.Position = UDim2.fromOffset(14, 222)
    openBtn.Size = UDim2.fromOffset(150, 38)
    openBtn.BackgroundColor3 = C.accent
    openBtn.BackgroundTransparency = 0.15
    openBtn.BorderSizePixel = 0
    openBtn.Text = "OPEN PANEL"
    openBtn.TextSize = 12
    openBtn.Font = Enum.Font.GothamBold
    openBtn.TextColor3 = DARK
    openBtn.AutoButtonColor = false
    openBtn.ZIndex = 23
    openBtn.Parent = hero
    corner(openBtn, 11)
    grad(openBtn, Color3.fromRGB(150, 225, 255), Color3.fromRGB(110, 160, 255), 90)
    pressFx(openBtn, 0.15)
    openBtn.MouseButton1Click:Connect(function() DASH.hooks.openTab("HOME") end)

    local dScan = glassButton(hero, 0.84)
    dScan.Position = UDim2.fromOffset(172, 222)
    dScan.Size = UDim2.fromOffset(86, 38)
    dScan.Text = "SCAN ULANG"
    dScan.TextSize = 10
    dScan.Font = Enum.Font.GothamBold
    dScan.TextColor3 = C.text
    dScan.MouseButton1Click:Connect(function() DASH.hooks.scan() end)

    -- kartu kanan atas: statistik file (hanya tampilan, tidak bisa diklik)
    local stats = glassPanel(dash, 0.9, 16)
    stats.Position = UDim2.new(0, 282, 0, 0)
    stats.Size = UDim2.new(1, -282, 0, 150)
    stats.ZIndex = 21
    local sl = text(stats, "FILE TERDETEKSI", 10, Enum.Font.GothamBold, C.muted)
    sl.Position = UDim2.fromOffset(14, 8)
    sl.Size = UDim2.new(0.6, -14, 0, 16)
    sl.ZIndex = 22
    local statTotal = text(stats, "0 file", 10, Enum.Font.GothamMedium, C.soft, Enum.TextXAlignment.Right)
    statTotal.Position = UDim2.new(0.5, 0, 0, 8)
    statTotal.Size = UDim2.new(0.5, -14, 0, 16)
    statTotal.ZIndex = 22

    for _, spec in ipairs({
        { "RBXM", C.accent, 10, 28 }, { "RBXMX", C.accent, 118, 28 },
        { "RBXL", C.accent2, 10, 86 }, { "RBXLX", C.accent2, 118, 86 },
    }) do
        local name, col, x, y = spec[1], spec[2], spec[3], spec[4]
        local tile = glassPanel(stats, 0.86, 12)
        tile.Position = UDim2.fromOffset(x, y)
        tile.Size = UDim2.fromOffset(106, 52)
        tile.ZIndex = 22
        local nl = text(tile, name, 10, Enum.Font.GothamBold, C.muted)
        nl.Position = UDim2.fromOffset(10, 6)
        nl.Size = UDim2.new(1, -44, 0, 14)
        nl.ZIndex = 23
        local cl = text(tile, "0", 20, Enum.Font.GothamBold, col)
        cl.Position = UDim2.fromOffset(10, 20)
        cl.Size = UDim2.new(1, -44, 0, 26)
        cl.ZIndex = 23
        local ic = Instance.new("ImageLabel")
        ic.AnchorPoint = Vector2.new(1, 0.5)
        ic.Position = UDim2.new(1, -8, 0.5, 0)
        ic.Size = UDim2.fromOffset(24, 24)
        ic.BackgroundTransparency = 1
        ic.Image = ICONS[name]
        ic.ScaleType = Enum.ScaleType.Fit
        ic.ZIndex = 23
        ic.Parent = tile
        DASH.stat[name] = cl
    end

    -- kartu kanan bawah: status device live
    local quick = glassPanel(dash, 0.9, 16)
    quick.Position = UDim2.new(0, 282, 0, 160)
    quick.Size = UDim2.new(1, -282, 1, -160)
    quick.ZIndex = 21
    local ql = text(quick, "STATUS DEVICE", 10, Enum.Font.GothamBold, C.muted)
    ql.Position = UDim2.fromOffset(14, 6)
    ql.Size = UDim2.new(0.6, -14, 0, 16)
    ql.ZIndex = 22
    local liveTag = text(quick, "LIVE", 9, Enum.Font.GothamBold, C.ok, Enum.TextXAlignment.Right)
    liveTag.Position = UDim2.new(0.5, 0, 0, 6)
    liveTag.Size = UDim2.new(0.5, -14, 0, 16)
    liveTag.ZIndex = 22

    local function devTile(x, labelText, unitText)
        local t = glassPanel(quick, 0.86, 12)
        t.Position = UDim2.fromOffset(x, 26)
        t.Size = UDim2.fromOffset(68, 80)
        t.ZIndex = 22

        local l = text(t, labelText, 9, Enum.Font.GothamBold, C.muted)
        l.Position = UDim2.fromOffset(8, 7)
        l.Size = UDim2.new(1, -12, 0, 12)
        l.TextScaled = true
        l.ZIndex = 23
        local lc = Instance.new("UITextSizeConstraint")
        lc.MaxTextSize = 9; lc.MinTextSize = 6; lc.Parent = l

        local v = text(t, "--", 20, Enum.Font.GothamBold, C.ok)
        v.Position = UDim2.fromOffset(8, 21)
        v.Size = UDim2.new(1, -12, 0, 26)
        v.TextScaled = true
        v.ZIndex = 23
        local vc = Instance.new("UITextSizeConstraint")
        vc.MaxTextSize = 20; vc.MinTextSize = 11; vc.Parent = v

        local u = text(t, unitText, 9, Enum.Font.GothamMedium, C.muted)
        u.Position = UDim2.fromOffset(8, 48)
        u.Size = UDim2.new(1, -12, 0, 12)
        u.ZIndex = 23

        local track = Instance.new("Frame")
        track.Position = UDim2.fromOffset(8, 67)
        track.Size = UDim2.new(1, -16, 0, 4)
        track.BackgroundColor3 = WHITE
        track.BackgroundTransparency = 0.8
        track.BorderSizePixel = 0
        track.ZIndex = 23
        track.Parent = t
        corner(track, 2)
        local fillBar = Instance.new("Frame")
        fillBar.Size = UDim2.new(0, 0, 1, 0)
        fillBar.BackgroundColor3 = C.ok
        fillBar.BorderSizePixel = 0
        fillBar.ZIndex = 24
        fillBar.Parent = track
        corner(fillBar, 2)
        return { val = v, unit = u, fill = fillBar }
    end
    local devFps = devTile(10, "FPS", "frame/detik")
    local devPing = devTile(83, "SINYAL", "ms ping")
    local devSpeed = devTile(156, "KECEPATAN", "KB/s")

    local Stats = game:GetService("Stats")
    local function setDev(ref, valueText, color, ratio)
        ref.val.Text = valueText
        ref.val.TextColor3 = color
        ref.fill.BackgroundColor3 = color
        TweenService:Create(ref.fill, TweenInfo.new(0.3), { Size = UDim2.new(math.clamp(ratio, 0, 1), 0, 1, 0) }):Play()
    end
    local function readPing()
        local ok, v = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
        if ok and type(v) == "number" and v > 0 then return v end
        local ok2, p = pcall(function() return LocalPlayer:GetNetworkPing() * 1000 end)
        if ok2 and type(p) == "number" and p > 0 then return p end
        return nil
    end
    local function readSpeed()
        local ok, v = pcall(function() return Stats.DataReceiveKbps end)
        if ok and type(v) == "number" then return v end
        return nil
    end

    local frames = 0
    RunService.RenderStepped:Connect(function() frames += 1 end)
    task.spawn(function()
        local last = os.clock()
        while gui.Parent do
            task.wait(0.5)
            local now = os.clock()
            local fps = frames / math.max(now - last, 0.001)
            frames = 0
            last = now
            if main.Visible and DASH.mode == "dash" then
                local fc = (fps >= 50 and C.ok) or (fps >= 30 and C.warn) or C.bad
                setDev(devFps, tostring(math.floor(fps + 0.5)), fc, fps / 60)

                local ping = readPing()
                if ping then
                    local pc = (ping < 100 and C.ok) or (ping < 200 and C.warn) or C.bad
                    setDev(devPing, tostring(math.floor(ping + 0.5)), pc, 1 - ping / 300)
                else
                    setDev(devPing, "--", C.muted, 0)
                end

                local sp = readSpeed()
                if sp then
                    if sp >= 1024 then
                        setDev(devSpeed, ("%.1f"):format(sp / 1024), C.accent, sp / 4096)
                        devSpeed.unit.Text = "MB/s"
                    else
                        setDev(devSpeed, tostring(math.floor(sp + 0.5)), C.accent, sp / 512)
                        devSpeed.unit.Text = "KB/s"
                    end
                else
                    setDev(devSpeed, "--", C.muted, 0)
                end
            end
        end
    end)

    -- ================= HOME (di dalam panel, kategori MENU) =================
    local home = Instance.new("Frame")
    home.Name = "HomePage"
    home.BackgroundTransparency = 1
    home.Position = UDim2.fromOffset(6, 28)
    home.Size = UDim2.new(1, -12, 1, -34)
    home.ZIndex = 21
    home.Visible = false
    home.Parent = content
    DASH.home = home

    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.fromOffset(118, 108)
    grid.CellPadding = UDim2.fromOffset(8, 8)
    grid.SortOrder = Enum.SortOrder.LayoutOrder
    grid.Parent = home

    local function homeTile(order, key, title, iconId, accent, glyph, onClick)
        local t = Instance.new("TextButton")
        t.LayoutOrder = order
        t.Text = ""
        t.AutoButtonColor = false
        t.BackgroundColor3 = WHITE
        t.BackgroundTransparency = 0.86
        t.BorderSizePixel = 0
        t.ZIndex = 22
        t.Parent = home
        corner(t, 14)
        glassStroke(t, 1)
        pressFx(t, 0.86)

        if iconId then
            local ic = Instance.new("ImageLabel")
            ic.AnchorPoint = Vector2.new(0.5, 0)
            ic.Position = UDim2.new(0.5, 0, 0, 14)
            ic.Size = UDim2.fromOffset(38, 38)
            ic.BackgroundTransparency = 1
            ic.Image = iconId
            ic.ScaleType = Enum.ScaleType.Fit
            ic.ZIndex = 23
            ic.Parent = t
        else
            local ic = text(t, glyph, 11, Enum.Font.GothamBold, DARK, Enum.TextXAlignment.Center)
            ic.AnchorPoint = Vector2.new(0.5, 0)
            ic.Position = UDim2.new(0.5, 0, 0, 14)
            ic.Size = UDim2.fromOffset(38, 38)
            ic.BackgroundTransparency = 0.1
            ic.BackgroundColor3 = accent
            ic.ZIndex = 23
            corner(ic, 11)
        end

        local ttl = text(t, title, 11, Enum.Font.GothamBold, C.text, Enum.TextXAlignment.Center)
        ttl.Position = UDim2.fromOffset(0, 60)
        ttl.Size = UDim2.new(1, 0, 0, 16)
        ttl.ZIndex = 23
        local sub = text(t, "", 9, Enum.Font.GothamMedium, accent, Enum.TextXAlignment.Center)
        sub.Position = UDim2.fromOffset(0, 78)
        sub.Size = UDim2.new(1, 0, 0, 14)
        sub.ZIndex = 23
        DASH.tiles[key] = sub
        t.MouseButton1Click:Connect(onClick)
        return sub
    end

    homeTile(1, "EXPORT", "EXPORT", ICONS.EXPORT, C.ok, nil, function() DASH.hooks.setTab("EXPORT") end).Text = "Simpan RBXM/RBXL"
    homeTile(2, "TOOLBOX", "TOOLBOX PC", ICONS.TOOLBOX, C.accent, nil, function() DASH.hooks.setTab("TOOLBOX") end).Text = "Cari & spawn aset"
    homeTile(3, "RBXM", "RBXM", ICONS.RBXM, C.accent, nil, function() DASH.hooks.setTab("RBXM") end)
    homeTile(4, "RBXMX", "RBXMX", ICONS.RBXMX, C.accent, nil, function() DASH.hooks.setTab("RBXMX") end)
    homeTile(5, "RBXL", "RBXL", ICONS.RBXL, C.accent2, nil, function() DASH.hooks.setTab("RBXL") end)
    homeTile(6, "RBXLX", "RBXLX", ICONS.RBXLX, C.accent2, nil, function() DASH.hooks.setTab("RBXLX") end)
    homeTile(7, "AKUN", "AKUN", nil, C.accent2, "A", function() DASH.hooks.setTab("AKUN") end).Text = "Belum terhubung"

    -- sinkron tombol SCAN (sidebar) -> dashboard & home
    scanBtn:GetPropertyChangedSignal("Text"):Connect(function()
        local idle = (scanBtn.Text == "SCAN")
        dScan.Text = idle and "SCAN ULANG" or scanBtn.Text
        if DASH.tiles.SCAN then DASH.tiles.SCAN.Text = idle and "Cari ulang file" or scanBtn.Text end
    end)

    function DASH.refresh()
        local counts, total = {}, 0
        for _, f in ipairs(allFiles) do
            local k = f.ext:upper()
            counts[k] = (counts[k] or 0) + 1
            total += 1
        end
        local imported = 0
        for _, st in pairs(fileState) do
            if st.label == "DONE" or st.label == "ACTIVE" then imported += 1 end
        end
        for name, lbl in pairs(DASH.stat) do lbl.Text = tostring(counts[name] or 0) end
        for _, name in ipairs({ "RBXM", "RBXMX", "RBXL", "RBXLX" }) do
            local sub = DASH.tiles[name]
            if sub then sub.Text = (counts[name] or 0) .. " file" end
        end
        pillTotal.Text = tostring(total)
        pillImp.Text = tostring(imported)
        statTotal.Text = total .. " file"
    end
end)()

local renderList
local function updateBadges()
    local counts = {}
    for _, f in ipairs(allFiles) do
        local k = f.ext:upper()
        counts[k] = (counts[k] or 0) + 1
    end
    for name, t in pairs(tabButtons) do
        if t.badge then t.badge.Text = tostring(counts[name] or 0) end
    end
    if DASH.refresh then DASH.refresh() end
end
local function refreshTabs()
    for name, t in pairs(tabButtons) do
        local active = (name == currentTab)
        TweenService:Create(t.btn, TweenInfo.new(0.15), {
            BackgroundTransparency = active and 0.55 or 0.9,
            BackgroundColor3 = active and C.accent2 or Color3.fromRGB(255, 255, 255),
        }):Play()
    end
    if currentTab == "TOOLBOX" then
        contentTitle.Text = "TOOLBOX PC"
    elseif currentTab == "HOME" then
        contentTitle.Text = "HOME"
    elseif currentTab == "AKUN" then
        contentTitle.Text = "AKUN • GENERAL"
    elseif currentTab == "EXPORT" then
        contentTitle.Text = "EXPORT RBXM / RBXL"
    else
        contentTitle.Text = currentTab .. " FILES"
    end
    if DASH.mode == "panel" and hdrSub then hdrSub.Text = "PANEL • " .. tabLabel(currentTab) end
end

-- ---------- kartu file ----------
local function makeCard(info)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -4, 0, 44)
    card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    card.BackgroundTransparency = 0.86
    card.BorderSizePixel = 0
    card.ZIndex = 22
    card.Parent = list
    corner(card, 10)
    glassStroke(card, 1)

    local icon = Instance.new("ImageLabel")
    icon.Position = UDim2.fromOffset(7, 7)
    icon.Size = UDim2.fromOffset(30, 30)
    icon.BackgroundTransparency = 1
    icon.Image = ICONS[info.ext:upper()] or ICONS.RBXM
    icon.ScaleType = Enum.ScaleType.Fit
    icon.ZIndex = 23
    icon.Parent = card

    local nameLbl = text(card, info.name, 12, Enum.Font.GothamBold, C.text)
    nameLbl.Position = UDim2.fromOffset(44, 4)
    nameLbl.Size = UDim2.new(1, -118, 0, 18)
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
    nameLbl.ZIndex = 23

    local pathLbl = text(card, info.path, 9, Enum.Font.Gotham, C.muted)
    pathLbl.Position = UDim2.fromOffset(44, 23)
    pathLbl.Size = UDim2.new(1, -118, 0, 14)
    pathLbl.TextTruncate = Enum.TextTruncate.AtEnd
    pathLbl.ZIndex = 23

    local st = fileState[info.path]
    if not st then st = { label = "IMPORT", color = C.accent }; fileState[info.path] = st end

    local btn = Instance.new("TextButton")
    btn.AnchorPoint = Vector2.new(1, 0.5)
    btn.Position = UDim2.new(1, -6, 0.5, 0)
    btn.Size = UDim2.fromOffset(62, 24)
    btn.BackgroundColor3 = st.color
    btn.BackgroundTransparency = 0.1
    btn.Text = st.label
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.fromRGB(10, 20, 50)
    btn.AutoButtonColor = false
    btn.ZIndex = 24
    btn.Parent = card
    corner(btn, 8)
    do
        local tc = Instance.new("UITextSizeConstraint")
        tc.MaxTextSize = 10
        tc.MinTextSize = 7
        tc.Parent = btn
        local pd = Instance.new("UIPadding")
        pd.PaddingLeft = UDim.new(0, 3); pd.PaddingRight = UDim.new(0, 3)
        pd.Parent = btn
    end

    local function setBtn(label, color)
        st.label, st.color = label, color
        if btn.Parent then btn.Text = label; btn.BackgroundColor3 = color end
    end

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
                    setBtn("ACTIVE", C.ok); setStatus(msg, C.ok)
                    notify("WLEO x NEKO", info.name .. " berhasil digenerate 100%.")
                else
                    setBtn("ACTIVATE", C.accent2); setStatus("ACTIVATE ERROR: " .. tostring(msg), C.bad)
                end
            end)
            return
        end
        setBtn("IMPORTING", C.warn)
        setProgress(0.01, "MULAI IMPORT • " .. info.name)
        task.spawn(function()
            local ok, msg, root
            if info.ftype == "RBXM" then
                ok, msg, root = importRBXM(info)
            else
                ok, msg, root = importRBXL(info)
            end
            if not ok then
                setBtn("FAILED", C.bad); setStatus(msg, C.bad)
                notify("IMPORT GAGAL", tostring(msg))
                task.wait(2.2)
                setBtn("IMPORT", C.accent)
                return
            end
            st.root = root
            if info.ftype == "RBXM" then
                setBtn("DONE", C.ok); setProgress(1, "RBXM GENERATION COMPLETE"); setStatus(msg, C.ok)
                notify("WLEO x NEKO", info.name .. " berhasil digenerate 100%.")
                return
            end
            setBtn("ACTIVATING", C.warn)
            setStatus(msg .. " • AUTO ACTIVATING", C.warn)
            local aok, amsg = activateImportRoot(root)
            if aok then
                setBtn("ACTIVE", C.ok); setProgress(1, "RBXL GENERATION COMPLETE"); setStatus(amsg, C.ok)
                notify("WLEO x NEKO", info.name .. " berhasil digenerate 100%.")
            else
                setBtn("ACTIVATE", C.accent2); setStatus("AUTO ACTIVATE ERROR: " .. tostring(amsg), C.bad)
                notify("ACTIVATE GAGAL", tostring(amsg))
            end
        end)
    end)
end

renderList = function()
    if currentTab == "TOOLBOX" or currentTab == "HOME" or currentTab == "AKUN" then return end
    for _, c in ipairs(list:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    local q = searchBox.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
    local shown = 0
    for _, info in ipairs(allFiles) do
        if info.ext:upper() == currentTab then
            if q == "" or info.name:lower():find(q, 1, true) or info.path:lower():find(q, 1, true) then
                makeCard(info)
                shown += 1
            end
        end
    end
    emptyLbl.Visible = shown == 0
    if shown == 0 then
        emptyLbl.Text = #allFiles == 0 and "Belum ada file.\nTekan SCAN untuk cari di workspace" or ("Tidak ada file ." .. currentTab:lower())
    end
end

-- =====================================================================
--                      TOOLBOX PC (endpoint Roblox)
-- =====================================================================
;(function()
    local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request)

    local function rawGet(url, withKey)
        local body
        if httpRequest then
            local headers = { ["Accept"] = "application/json" }
            if withKey and ACCT.apiKey then headers["x-api-key"] = ACCT.apiKey end
            local ok, res = pcall(httpRequest, { Url = url, Method = "GET", Headers = headers })
            if ok and type(res) == "table" and (res.Success or res.StatusCode == 200) and type(res.Body) == "string" then
                body = res.Body
            end
        end
        if not body and not withKey then
            local ok, res = pcall(function() return game:HttpGet(url) end)
            if ok and type(res) == "string" then body = res end
        end
        if not body then return nil end
        local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
        return ok and data or nil
    end

    local function httpGetJson(url)
        local data = rawGet(url, false)
        -- kalau gagal & ada API key tersimpan: coba lagi sekali dengan x-api-key (hanya ke apis.roblox.com)
        if data == nil and ACCT.apiKey and httpRequest and url:find("^https://apis%.roblox%.com/") then
            data = rawGet(url, true)
        end
        return data
    end
    TB.httpGetJson = httpGetJson

    local TB_CATS = {
        { name = "MODEL", id = 10 },
        { name = "MESH",  id = 4 },
        { name = "DECAL", id = 13 },
        { name = "AUDIO", id = 3 },
    }
    local tbCat = 10
    local tbToken = 0

    -- toolbox list
    local tbList = Instance.new("ScrollingFrame")
    tbList.Position = UDim2.fromOffset(6, 80)
    tbList.Size = UDim2.new(1, -12, 1, -86)
    tbList.BackgroundTransparency = 1
    tbList.BorderSizePixel = 0
    tbList.ScrollBarThickness = 3
    tbList.ScrollBarImageColor3 = C.ok
    tbList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tbList.CanvasSize = UDim2.new()
    tbList.ZIndex = 21
    tbList.Visible = false
    tbList.Parent = content
    do
        local l = Instance.new("UIListLayout")
        l.Padding = UDim.new(0, 5)
        l.SortOrder = Enum.SortOrder.LayoutOrder
        l.Parent = tbList
    end
    TB.list = tbList

    -- tombol GO
    local goBtn = Instance.new("TextButton")
    goBtn.AnchorPoint = Vector2.new(1, 0)
    goBtn.Position = UDim2.new(1, -8, 0, 26)
    goBtn.Size = UDim2.fromOffset(40, 26)
    goBtn.BackgroundColor3 = C.ok
    goBtn.BackgroundTransparency = 0.1
    goBtn.Text = "GO"
    goBtn.TextSize = 11
    goBtn.Font = Enum.Font.GothamBold
    goBtn.TextColor3 = Color3.fromRGB(10, 20, 50)
    goBtn.AutoButtonColor = false
    goBtn.ZIndex = 22
    goBtn.Visible = false
    goBtn.Parent = content
    corner(goBtn, 9)
    TB.go = goBtn

    -- chip kategori
    local chipRow = Instance.new("Frame")
    chipRow.Position = UDim2.fromOffset(8, 56)
    chipRow.Size = UDim2.new(1, -16, 0, 20)
    chipRow.BackgroundTransparency = 1
    chipRow.ZIndex = 21
    chipRow.Visible = false
    chipRow.Parent = content
    do
        local l = Instance.new("UIListLayout")
        l.FillDirection = Enum.FillDirection.Horizontal
        l.Padding = UDim.new(0, 4)
        l.SortOrder = Enum.SortOrder.LayoutOrder
        l.Parent = chipRow
    end
    TB.chips = chipRow
    local chipBtns = {}
    local function refreshChips()
        for id, b in pairs(chipBtns) do
            local on = (id == tbCat)
            b.BackgroundColor3 = on and C.ok or Color3.fromRGB(255, 255, 255)
            b.BackgroundTransparency = on and 0.15 or 0.85
            b.TextColor3 = on and Color3.fromRGB(10, 20, 50) or C.text
        end
    end
    for i, cat in ipairs(TB_CATS) do
        local b = Instance.new("TextButton")
        b.LayoutOrder = i
        b.Size = UDim2.fromOffset(56, 20)
        b.Text = cat.name
        b.TextSize = 10
        b.Font = Enum.Font.GothamBold
        b.AutoButtonColor = false
        b.ZIndex = 22
        b.Parent = chipRow
        corner(b, 8)
        chipBtns[cat.id] = b
        b.MouseButton1Click:Connect(function()
            tbCat = cat.id
            refreshChips()
        end)
    end
    refreshChips()

    TB.msg = "Ketik nama aset lalu tekan GO"
    function TB.setMsg(m)
        TB.msg = m
        if currentTab == "TOOLBOX" then
            emptyLbl.Text = m
            emptyLbl.Visible = (m ~= "")
            emptyLbl.Position = UDim2.fromOffset(10, 110)
        end
    end

    local function clearTb()
        for _, c in ipairs(tbList:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
    end

    local function flashBtn(btn, label, color, back, backColor)
        btn.Text = label
        btn.BackgroundColor3 = color
        task.delay(1.6, function()
            if btn.Parent then btn.Text = back; btn.BackgroundColor3 = backColor end
        end)
    end

    -- import ID langsung ke StudioLite
    local function importAsset(id, cat)
        ind.busy = true
        setStatus("IMPORT ID " .. id .. " KE STUDIOLITE...", C.ok)
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
                ok, info = true, ("MODEL %d • %d OBJECT MASUK WORKSPACE"):format(id, #objs)
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
                ok, info = true, ("MESH %d DIKIRIM KE STUDIOLITE RUNTIME"):format(id)
            else
                info = "mesh gagal: " .. tostring(how)
            end
        else
            if getStudioLiteServerFuncs() then
                triggerServerLoad(id)
                ok, info = true, ("ID %d DIKIRIM KE STUDIOLITE"):format(id)
            else
                info = "StudioLiteFolder tidak ditemukan di game ini"
            end
        end
        ind.busy = false
        setStatus(info, ok and C.ok or C.bad)
        return ok
    end

    local function makeTbCard(order, id, meta, cat)
        local card = Instance.new("Frame")
        card.LayoutOrder = order
        card.Size = UDim2.new(1, -4, 0, 52)
        card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        card.BackgroundTransparency = 0.86
        card.BorderSizePixel = 0
        card.ZIndex = 22
        card.Parent = tbList
        corner(card, 10)
        glassStroke(card, 1)

        local thumb = Instance.new("ImageLabel")
        thumb.Position = UDim2.fromOffset(6, 6)
        thumb.Size = UDim2.fromOffset(40, 40)
        thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        thumb.BackgroundTransparency = 0.85
        thumb.Image = ("rbxthumb://type=Asset&id=%d&w=150&h=150"):format(id)
        thumb.ScaleType = Enum.ScaleType.Fit
        thumb.ZIndex = 23
        thumb.Parent = card
        corner(thumb, 8)

        local nameBtn = Instance.new("TextButton")
        nameBtn.BackgroundTransparency = 1
        nameBtn.Position = UDim2.fromOffset(54, 4)
        nameBtn.Size = UDim2.new(1, -122, 0, 16)
        nameBtn.Text = meta.name or ("Asset " .. id)
        nameBtn.TextSize = 11
        nameBtn.Font = Enum.Font.GothamBold
        nameBtn.TextColor3 = C.text
        nameBtn.TextXAlignment = Enum.TextXAlignment.Left
        nameBtn.TextTruncate = Enum.TextTruncate.AtEnd
        nameBtn.AutoButtonColor = false
        nameBtn.ZIndex = 24
        nameBtn.Parent = card

        local idBtn = Instance.new("TextButton")
        idBtn.BackgroundTransparency = 1
        idBtn.Position = UDim2.fromOffset(54, 21)
        idBtn.Size = UDim2.new(1, -122, 0, 14)
        idBtn.Text = "ID " .. id
        idBtn.TextSize = 10
        idBtn.Font = Enum.Font.GothamMedium
        idBtn.TextColor3 = C.accent
        idBtn.TextXAlignment = Enum.TextXAlignment.Left
        idBtn.AutoButtonColor = false
        idBtn.ZIndex = 24
        idBtn.Parent = card

        local byLbl = text(card, meta.creator and ("by " .. meta.creator) or "", 9, Enum.Font.Gotham, C.muted)
        byLbl.Position = UDim2.fromOffset(54, 36)
        byLbl.Size = UDim2.new(1, -122, 0, 12)
        byLbl.TextTruncate = Enum.TextTruncate.AtEnd
        byLbl.ZIndex = 23

        local function mini(label, y, color)
            local b = Instance.new("TextButton")
            b.AnchorPoint = Vector2.new(1, 0)
            b.Position = UDim2.new(1, -6, 0, y)
            b.Size = UDim2.fromOffset(56, 20)
            b.BackgroundColor3 = color
            b.BackgroundTransparency = 0.1
            b.Text = label
            b.TextSize = 10
            b.Font = Enum.Font.GothamBold
            b.TextColor3 = Color3.fromRGB(10, 20, 50)
            b.AutoButtonColor = false
            b.ZIndex = 24
            b.Parent = card
            corner(b, 7)
            return b
        end
        local copyBtn = mini("COPY ID", 5, C.accent)
        local impBtn = mini("IMPORT", 27, C.ok)

        local function doCopy(value, what)
            if copyText(value) then
                setStatus("COPIED " .. what .. " • " .. tostring(value), C.ok)
            else
                setStatus("CLIPBOARD TIDAK TERSEDIA DI EXECUTOR", C.bad)
            end
        end
        nameBtn.MouseButton1Click:Connect(function() doCopy(nameBtn.Text, "NAMA") end)
        idBtn.MouseButton1Click:Connect(function() doCopy(tostring(id), "ID") end)
        copyBtn.MouseButton1Click:Connect(function()
            doCopy(tostring(id), "ID")
            flashBtn(copyBtn, "COPIED", C.ok, "COPY ID", C.accent)
        end)

        local busy = false
        impBtn.MouseButton1Click:Connect(function()
            if busy then return end
            busy = true
            impBtn.Text = "..."
            impBtn.BackgroundColor3 = C.warn
            task.spawn(function()
                local ok = importAsset(id, cat)
                busy = false
                if ok then
                    flashBtn(impBtn, "DONE", C.ok, "IMPORT", C.ok)
                    notify("WLEO x NEKO", "ID " .. id .. " masuk StudioLite.")
                else
                    flashBtn(impBtn, "FAILED", C.bad, "IMPORT", C.ok)
                end
            end)
        end)

        if not meta.name then
            task.spawn(function()
                local d = httpGetJson("https://economy.roblox.com/v2/assets/" .. id .. "/details")
                if d and nameBtn.Parent then
                    if d.Name then nameBtn.Text = d.Name end
                    if d.Creator and d.Creator.Name then byLbl.Text = "by " .. d.Creator.Name end
                end
            end)
        end
    end

    -- ================= paging: muat terus sampai habis =================
    local TB_PAGE = 30
    local tbS = { q = nil, cat = 10, page = 0, loading = false, done = true, single = false, count = 0, seen = {} }

    local footer = Instance.new("TextButton")
    footer.Name = "TbFooter"
    footer.LayoutOrder = 1000000
    footer.Size = UDim2.new(1, -4, 0, 30)
    footer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    footer.BackgroundTransparency = 0.86
    footer.Text = ""
    footer.TextSize = 10
    footer.Font = Enum.Font.GothamBold
    footer.TextColor3 = C.text
    footer.AutoButtonColor = false
    footer.Visible = false
    footer.ZIndex = 22
    footer.Parent = tbList
    corner(footer, 10)
    glassStroke(footer, 1)

    local function setFooter()
        if tbS.q == nil or tbS.single or (tbS.count == 0 and not tbS.loading) then
            footer.Visible = false
            return
        end
        footer.Visible = true
        if tbS.loading then
            footer.Text = ("MEMUAT... • %d ASET"):format(tbS.count)
        elseif tbS.done then
            footer.Text = ("SEMUA HASIL DIMUAT • %d ASET"):format(tbS.count)
        else
            footer.Text = ("MUAT LAGI • %d ASET SEKARANG"):format(tbS.count)
        end
    end

    local function fetchIds(q, cat, page)
        local ids, total = {}, nil
        local enc = HttpService:UrlEncode(q)
        local urls = {
            ("https://apis.roblox.com/toolbox-service/v1/marketplace/%d?limit=%d&pageNumber=%d&keyword=%s&sortType=Relevance"):format(cat, TB_PAGE, page, enc),
            ("https://apis.roblox.com/toolbox-service/v1/marketplace/%d?keyword=%s&num=%d&pageNumber=%d"):format(cat, enc, TB_PAGE, page),
        }
        for _, url in ipairs(urls) do
            local data = httpGetJson(url)
            if data and type(data.data) == "table" then
                total = tonumber(data.totalResults) or total
                for _, e in ipairs(data.data) do
                    local rawId = (type(e) == "table") and (e.id or e.Id or e.assetId) or e
                    rawId = tonumber(rawId)
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
                        metaById[aid] = {
                            name = a.name or a.Name,
                            creator = d.creator and (d.creator.name or d.creator.Name) or nil,
                        }
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
        ind.busy = true
        setStatus(("TOOLBOX • MEMUAT HALAMAN %d..."):format(page + 1), C.ok)
        setFooter()
        task.spawn(function()
            local ids, total = fetchIds(q, cat, page)
            if my ~= tbToken then return end
            local fresh = {}
            for _, id in ipairs(ids) do
                if not tbS.seen[id] then
                    tbS.seen[id] = true
                    fresh[#fresh + 1] = id
                end
            end
            if #fresh == 0 then
                tbS.loading = false
                tbS.done = true
                ind.busy = false
                if tbS.count == 0 then
                    if not httpRequest then
                        TB.setMsg("Fungsi request tidak ada di executor ini")
                        setStatus("TOOLBOX • request tidak tersedia", C.bad)
                    else
                        TB.setMsg("Tidak ada hasil untuk \"" .. q .. "\"\n(atau endpoint tidak merespon)")
                        setStatus("TOOLBOX • 0 HASIL", C.warn)
                    end
                else
                    setStatus(("TOOLBOX • SELESAI • %d ASET"):format(tbS.count), C.ok)
                end
                setFooter()
                return
            end
            local meta = fetchMeta(fresh)
            if my ~= tbToken then return end
            TB.setMsg("")
            for _, id in ipairs(fresh) do
                if my ~= tbToken then return end
                tbS.count += 1
                makeTbCard(tbS.count, id, meta[id] or {}, cat)
                if tbS.count % 6 == 0 then task.wait() end
            end
            tbS.page = page + 1
            tbS.loading = false
            ind.busy = false
            if total and tbS.count >= total then tbS.done = true end
            setStatus(("TOOLBOX • %d ASET%s"):format(tbS.count, tbS.done and "" or " • scroll untuk muat lagi"), C.ok)
            setFooter()
        end)
    end

    function TB.search()
        local q = searchBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
        tbToken += 1
        local my = tbToken
        clearTb()
        tbS.q, tbS.cat, tbS.page = nil, tbCat, 0
        tbS.loading, tbS.done, tbS.single, tbS.count, tbS.seen = false, true, false, 0, {}
        setFooter()
        if q == "" then
            TB.setMsg("Ketik nama aset atau ID lalu tekan GO")
            return
        end
        pcall(function() tbList.CanvasPosition = Vector2.new(0, 0) end)
        TB.setMsg("Mencari...")
        ind.busy = true
        setStatus("TOOLBOX • MENCARI " .. q:upper(), C.ok)
        if q:match("^%d+$") then
            local id = tonumber(q)
            tbS.single = true
            tbS.seen[id] = true
            task.spawn(function()
                local meta = fetchMeta({ id })
                if my ~= tbToken then return end
                TB.setMsg("")
                tbS.count = 1
                makeTbCard(1, id, meta[id] or {}, tbCat)
                ind.busy = false
                setStatus("TOOLBOX • ID " .. id, C.ok)
                setFooter()
            end)
            return
        end
        tbS.q, tbS.done = q, false
        loadPage()
    end

    -- scroll sampai dekat bawah = muat halaman berikutnya otomatis
    tbList:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        if tbS.loading or tbS.done or not tbS.q then return end
        local remain = tbList.AbsoluteCanvasSize.Y - (tbList.CanvasPosition.Y + tbList.AbsoluteWindowSize.Y)
        if remain < 140 then loadPage() end
    end)
    footer.MouseButton1Click:Connect(function() loadPage() end)

    goBtn.MouseButton1Click:Connect(function() TB.search() end)
    searchBox.FocusLost:Connect(function(enter)
        if enter and currentTab == "TOOLBOX" then TB.search() end
    end)
end)()

-- =====================================================================
--                GENERAL • AKUN (API key, User ID, Group ID)
-- =====================================================================
;(function()
    local WHITE = Color3.fromRGB(255, 255, 255)
    local DARK = Color3.fromRGB(10, 20, 50)
    local ACCT_FILE = "WLEO_NEKO_ACCOUNT.json"   -- nama tetap, jangan diganti supaya akun aman saat script di-update
    local genv = (type(getgenv) == "function" and getgenv()) or _G
    local canFile = type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"

    local function loadSaved()
        if canFile then
            local ok, t = pcall(function()
                if isfile(ACCT_FILE) then return HttpService:JSONDecode(readfile(ACCT_FILE)) end
            end)
            if ok and type(t) == "table" and tonumber(t.userId) then return t end
        end
        local g = genv.WLEO_NEKO_ACCOUNT
        if type(g) == "table" and tonumber(g.userId) then return g end
        return nil
    end
    local function saveSaved(t)
        genv.WLEO_NEKO_ACCOUNT = t
        if canFile then
            pcall(function() writefile(ACCT_FILE, HttpService:JSONEncode(t)) end)
        end
    end
    local function clearSaved()
        genv.WLEO_NEKO_ACCOUNT = nil
        if canFile then
            local removed = false
            if type(delfile) == "function" then
                removed = pcall(function() if isfile(ACCT_FILE) then delfile(ACCT_FILE) end end)
            end
            if not removed then pcall(function() writefile(ACCT_FILE, "{}") end) end
        end
    end

    local page = Instance.new("Frame")
    page.Name = "AccountPage"
    page.BackgroundTransparency = 1
    page.Position = UDim2.fromOffset(6, 28)
    page.Size = UDim2.new(1, -12, 1, -34)
    page.ZIndex = 21
    page.Visible = false
    page.Parent = content
    ACCT.page = page

    -- ---------- form (belum konek) ----------
    local form = Instance.new("Frame")
    form.BackgroundTransparency = 1
    form.Size = UDim2.new(1, 0, 1, -44)
    form.ZIndex = 21
    form.Parent = page

    local function field(y, labelText, placeholder)
        local l = text(form, labelText, 9, Enum.Font.GothamBold, C.muted)
        l.Position = UDim2.fromOffset(2, y)
        l.Size = UDim2.new(1, -4, 0, 12)
        l.ZIndex = 22
        local tb = Instance.new("TextBox")
        tb.Position = UDim2.fromOffset(0, y + 14)
        tb.Size = UDim2.new(1, 0, 0, 26)
        tb.BackgroundColor3 = WHITE
        tb.BackgroundTransparency = 0.82
        tb.Text = ""
        tb.PlaceholderText = placeholder
        tb.PlaceholderColor3 = C.muted
        tb.TextColor3 = C.text
        tb.TextSize = 11
        tb.Font = Enum.Font.GothamMedium
        tb.ClearTextOnFocus = false
        tb.TextXAlignment = Enum.TextXAlignment.Left
        tb.ZIndex = 22
        tb.Parent = form
        corner(tb, 9)
        glassStroke(tb, 1)
        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 8)
        pad.PaddingRight = UDim.new(0, 8)
        pad.Parent = tb
        return tb
    end
    local apiBox = field(0, "API KEY (Open Cloud) • opsional", "Tempel API key...")
    local uidBox = field(46, "USER ID", "Kosong = pakai akun yang sedang bermain")
    local gidBox = field(92, "GROUP ID • untuk menautkan komunitas (opsional)", "Contoh: 1234567")

    local hint = text(form, "Data tersimpan di device ini dan tetap ada saat script di-update. Hanya hilang kalau kamu tekan DISCONNECT.", 9, Enum.Font.GothamMedium, C.muted)
    hint.Position = UDim2.fromOffset(2, 140)
    hint.Size = UDim2.new(1, -4, 0, 26)
    hint.TextWrapped = true
    hint.TextYAlignment = Enum.TextYAlignment.Top
    hint.ZIndex = 22

    local msg = text(form, "", 10, Enum.Font.GothamBold, C.muted)
    msg.Position = UDim2.fromOffset(2, 170)
    msg.Size = UDim2.new(1, -4, 0, 24)
    msg.TextWrapped = true
    msg.TextYAlignment = Enum.TextYAlignment.Top
    msg.ZIndex = 22
    local function setMsg(m, color)
        msg.Text = m or ""
        msg.TextColor3 = color or C.muted
    end

    -- ---------- kartu profil (sudah konek) ----------
    local card = Instance.new("Frame")
    card.BackgroundTransparency = 1
    card.Size = UDim2.new(1, 0, 1, -44)
    card.ZIndex = 21
    card.Visible = false
    card.Parent = page

    local prof = glassPanel(card, 0.86, 14)
    prof.Size = UDim2.new(1, 0, 0, 92)
    prof.ZIndex = 22
    local avatar = Instance.new("ImageLabel")
    avatar.Position = UDim2.fromOffset(12, 10)
    avatar.Size = UDim2.fromOffset(72, 72)
    avatar.BackgroundColor3 = WHITE
    avatar.BackgroundTransparency = 0.85
    avatar.ScaleType = Enum.ScaleType.Crop
    avatar.ZIndex = 23
    avatar.Parent = prof
    corner(avatar, 36)
    glassStroke(avatar, 1.5, true)
    local dispLbl = text(prof, "", 16, Enum.Font.GothamBold, C.text)
    dispLbl.Position = UDim2.fromOffset(96, 12)
    dispLbl.Size = UDim2.new(1, -108, 0, 22)
    dispLbl.TextTruncate = Enum.TextTruncate.AtEnd
    dispLbl.ZIndex = 23
    local userLbl = text(prof, "", 11, Enum.Font.GothamMedium, C.accent)
    userLbl.Position = UDim2.fromOffset(96, 35)
    userLbl.Size = UDim2.new(1, -108, 0, 16)
    userLbl.TextTruncate = Enum.TextTruncate.AtEnd
    userLbl.ZIndex = 23
    local idLbl = text(prof, "", 10, Enum.Font.GothamMedium, C.muted)
    idLbl.Position = UDim2.fromOffset(96, 53)
    idLbl.Size = UDim2.new(1, -108, 0, 14)
    idLbl.ZIndex = 23
    local stLbl = text(prof, "• TERHUBUNG", 9, Enum.Font.GothamBold, C.ok)
    stLbl.Position = UDim2.fromOffset(96, 68)
    stLbl.Size = UDim2.new(1, -108, 0, 14)
    stLbl.ZIndex = 23

    local grp = glassPanel(card, 0.86, 14)
    grp.Position = UDim2.fromOffset(0, 100)
    grp.Size = UDim2.new(1, 0, 0, 52)
    grp.ZIndex = 22
    local groupIcon = Instance.new("ImageLabel")
    groupIcon.Position = UDim2.fromOffset(10, 8)
    groupIcon.Size = UDim2.fromOffset(36, 36)
    groupIcon.BackgroundColor3 = WHITE
    groupIcon.BackgroundTransparency = 0.85
    groupIcon.ScaleType = Enum.ScaleType.Crop
    groupIcon.ZIndex = 23
    groupIcon.Visible = false
    groupIcon.Parent = grp
    corner(groupIcon, 9)
    local groupGlyph = text(grp, "G", 12, Enum.Font.GothamBold, DARK, Enum.TextXAlignment.Center)
    groupGlyph.Position = UDim2.fromOffset(10, 8)
    groupGlyph.Size = UDim2.fromOffset(36, 36)
    groupGlyph.BackgroundTransparency = 0.1
    groupGlyph.BackgroundColor3 = C.accent2
    groupGlyph.ZIndex = 23
    corner(groupGlyph, 9)
    local groupName = text(grp, "", 12, Enum.Font.GothamBold, C.text)
    groupName.Position = UDim2.fromOffset(56, 8)
    groupName.Size = UDim2.new(1, -66, 0, 18)
    groupName.TextTruncate = Enum.TextTruncate.AtEnd
    groupName.ZIndex = 23
    local groupSub = text(grp, "", 10, Enum.Font.GothamMedium, C.muted)
    groupSub.Position = UDim2.fromOffset(56, 27)
    groupSub.Size = UDim2.new(1, -66, 0, 14)
    groupSub.ZIndex = 23

    local api = glassPanel(card, 0.86, 12)
    api.Position = UDim2.fromOffset(0, 160)
    api.Size = UDim2.new(1, 0, 0, 30)
    api.ZIndex = 22
    local apiLbl = text(api, "", 10, Enum.Font.GothamMedium, C.soft)
    apiLbl.Position = UDim2.fromOffset(12, 0)
    apiLbl.Size = UDim2.new(1, -24, 1, 0)
    apiLbl.ZIndex = 23

    -- ---------- tombol KONEK / DISCONNECT ----------
    local acctBtn = Instance.new("TextButton")
    acctBtn.AnchorPoint = Vector2.new(0, 1)
    acctBtn.Position = UDim2.new(0, 0, 1, 0)
    acctBtn.Size = UDim2.new(1, 0, 0, 34)
    acctBtn.BackgroundColor3 = C.accent
    acctBtn.BackgroundTransparency = 0.15
    acctBtn.BorderSizePixel = 0
    acctBtn.Text = "KONEK"
    acctBtn.TextSize = 12
    acctBtn.Font = Enum.Font.GothamBold
    acctBtn.TextColor3 = DARK
    acctBtn.AutoButtonColor = false
    acctBtn.ZIndex = 23
    acctBtn.Parent = page
    corner(acctBtn, 11)
    local btnGrad = grad(acctBtn, Color3.fromRGB(150, 225, 255), Color3.fromRGB(110, 160, 255), 90)

    local function mask(k)
        if type(k) ~= "string" or k == "" then return "tidak diisi" end
        return "••••••••" .. (#k > 4 and k:sub(-4) or "")
    end

    local function render()
        local d = ACCT.data or {}
        local on = ACCT.connected
        form.Visible = not on
        card.Visible = on
        if on then
            local uid = math.floor(tonumber(d.userId) or 0)
            avatar.Image = ("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150"):format(uid)
            dispLbl.Text = d.displayName or d.name or ("User " .. uid)
            userLbl.Text = "@" .. (d.name or "?")
            idLbl.Text = "User ID " .. uid
            local gid = tonumber(d.groupId)
            if gid then
                gid = math.floor(gid)
                groupIcon.Image = ("rbxthumb://type=GroupIcon&id=%d&w=150&h=150"):format(gid)
                groupIcon.Visible = true
                groupGlyph.Visible = false
                groupName.Text = d.groupName or ("Group " .. gid)
                groupSub.Text = "Komunitas tertaut • ID " .. gid
            else
                groupIcon.Visible = false
                groupGlyph.Visible = true
                groupName.Text = "Komunitas"
                groupSub.Text = "Belum ditautkan"
            end
            apiLbl.Text = "API KEY    " .. mask(d.apiKey)
            acctBtn.Text = "DISCONNECT"
            btnGrad.Color = ColorSequence.new(Color3.fromRGB(255, 150, 170), Color3.fromRGB(255, 105, 135))
        else
            acctBtn.Text = "KONEK"
            btnGrad.Color = ColorSequence.new(Color3.fromRGB(150, 225, 255), Color3.fromRGB(110, 160, 255))
        end
        if DASH.tiles.AKUN then
            DASH.tiles.AKUN.Text = on and ("@" .. (d.name or "?")) or "Belum terhubung"
        end
        if DASH.badgeText then
            DASH.badgeText.Text = on and (d.displayName or d.name or "Terhubung") or "Importer Ready"
        end
    end

    local function fetchProfile(userId, groupId)
        local u = TB.httpGetJson("https://users.roblox.com/v1/users/" .. userId)
        if not (type(u) == "table" and u.name) then
            return nil, "User ID tidak ditemukan atau jaringan bermasalah"
        end
        local g
        if groupId then
            g = TB.httpGetJson("https://groups.roblox.com/v1/groups/" .. groupId)
            if not (type(g) == "table" and g.name) then
                return nil, "Group ID tidak ditemukan"
            end
        end
        return { name = u.name, displayName = u.displayName or u.name, groupName = g and g.name or nil }
    end

    local connecting = false
    local function doConnect()
        if connecting then return end
        local key = apiBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
        local uidText = uidBox.Text:gsub("%s", "")
        local gidText = gidBox.Text:gsub("%s", "")
        local uid = (uidText == "") and LocalPlayer.UserId or tonumber(uidText)
        if not uid or uid <= 0 or uid ~= math.floor(uid) then
            setMsg("User ID harus berupa angka", C.bad)
            return
        end
        local gid
        if gidText ~= "" then
            gid = tonumber(gidText)
            if not gid or gid <= 0 or gid ~= math.floor(gid) then
                setMsg("Group ID harus berupa angka", C.bad)
                return
            end
        end
        connecting = true
        acctBtn.Text = "MENGHUBUNGKAN..."
        setMsg("Mengambil profil Roblox...", C.warn)
        task.spawn(function()
            local p, err = fetchProfile(uid, gid)
            connecting = false
            if not p then
                setMsg(err, C.bad)
                render()
                return
            end
            ACCT.data = {
                userId = uid, groupId = gid, apiKey = (key ~= "") and key or nil,
                name = p.name, displayName = p.displayName, groupName = p.groupName,
            }
            ACCT.apiKey = ACCT.data.apiKey
            ACCT.connected = true
            saveSaved(ACCT.data)
            apiBox.Text = ""
            setMsg(canFile and "" or "Penyimpanan file tidak tersedia, akun hanya tersimpan selama sesi ini", C.warn)
            render()
            setStatus(("AKUN TERHUBUNG • @%s"):format(p.name), C.ok)
            notify("WLEO x NEKO", "Akun terhubung: " .. p.displayName)
        end)
    end

    local function doDisconnect()
        ACCT.connected = false
        ACCT.data = {}
        ACCT.apiKey = nil
        clearSaved()
        apiBox.Text, uidBox.Text, gidBox.Text = "", "", ""
        setMsg("Akun diputuskan dan data dihapus dari device", C.ok)
        render()
        setStatus("AKUN DIPUTUSKAN", C.warn)
    end

    local confirmAt = 0
    acctBtn.MouseButton1Click:Connect(function()
        if ACCT.connected then
            if os.clock() - confirmAt < 3 then
                confirmAt = 0
                doDisconnect()
            else
                confirmAt = os.clock()
                acctBtn.Text = "TAP LAGI UNTUK DISCONNECT"
                task.delay(3.1, function()
                    if ACCT.connected and confirmAt ~= 0 and os.clock() - confirmAt >= 3 then
                        confirmAt = 0
                        acctBtn.Text = "DISCONNECT"
                    end
                end)
            end
        else
            doConnect()
        end
    end)

    -- ---------- auto-konek dari data tersimpan ----------
    local saved = loadSaved()
    if saved then
        saved.userId = math.floor(tonumber(saved.userId))
        if tonumber(saved.groupId) then saved.groupId = math.floor(tonumber(saved.groupId)) else saved.groupId = nil end
        ACCT.data = saved
        ACCT.apiKey = saved.apiKey
        ACCT.connected = true
        render()
        task.spawn(function()
            local p = fetchProfile(saved.userId, saved.groupId)
            if p and ACCT.connected and ACCT.data == saved then
                saved.name, saved.displayName = p.name, p.displayName
                saved.groupName = p.groupName or saved.groupName
                saveSaved(saved)
                render()
            end
        end)
    else
        render()
    end
end)()

-- =====================================================================
--   EXPORT ENGINE  (ported from MedStudio by wleo)
--   Tulis file .rbxm / .rbxl biner langsung dari dalam game
-- =====================================================================
local Exporter = (function()
    local CollectionService = game:GetService("CollectionService")
    local ReplicatedStorageExp = game:GetService("ReplicatedStorage")

    -- ---------- ambil source script ----------
    local sourceRemote = nil
    local function findSourceRemote()
        if sourceRemote and sourceRemote.Parent then return sourceRemote end
        pcall(function()
            for _, d in ipairs(ReplicatedStorageExp:GetDescendants()) do
                if d.Name == "GetScriptSourceServerFunction" and d:IsA("RemoteFunction") then
                    sourceRemote = d; break
                end
            end
        end)
        return sourceRemote
    end
    local function cleanSrc(src)
        if type(src) ~= "string" then return nil end
        src = src:gsub("%z+$","")
        if src == "" or src == "-- [Langz] Source tidak ditemukan." then return nil end
        return src
    end
    local function scriptSource(scr)
        local raw = _G.Langz_RAW_SOURCES and _G.Langz_RAW_SOURCES[scr]
        if cleanSrc(raw) then return cleanSrc(raw),"import" end
        local tb = scr:FindFirstChild("SL_CodeTextBox")
        if tb then local ok,t=pcall(function()return tb.Text end) if ok and cleanSrc(t) then return cleanSrc(t),"editor" end end
        local ro = scr:FindFirstChild("SL_1ReadOnly")
        if ro then local ok,t=pcall(function()return ro.ContentText end) if ok and cleanSrc(t) then return cleanSrc(t),"editor" end end
        local rf = findSourceRemote()
        if rf then local ok,t=pcall(function()return rf:InvokeServer(scr.ClassName..scr.Name)end) if ok and cleanSrc(t) then return cleanSrc(t),"server" end end
        local ok,t=pcall(function()return scr.Source end) if ok and cleanSrc(t) then return cleanSrc(t),"source" end
        if type(gethiddenproperty)=="function" then ok,t=pcall(gethiddenproperty,scr,"Source") if ok and cleanSrc(t) then return cleanSrc(t),"source" end end
        if type(decompile)=="function" then ok,t=pcall(decompile,scr) if ok and cleanSrc(t) and not t:find("^%-%- ?[Ff]ailed") then return cleanSrc(t),"decompile" end end
        return nil,"kosong"
    end

    -- ---------- property defs ----------
    local PROPS = {
        {"BasePart",{{"CFrame"},{"Size","size"},{"Color","Color3uint8"},{"Material"},{"Transparency"},{"Reflectance"},{"Anchored"},{"CanCollide"},{"CanTouch"},{"CanQuery"},{"CastShadow"},{"Locked"},{"Massless"},{"CollisionGroup"},{"RootPriority",nil,"int"},{"CustomPhysicalProperties"},{"TopSurface"},{"BottomSurface"},{"LeftSurface"},{"RightSurface"},{"FrontSurface"},{"BackSurface"}}},
        {"Part",{{"Shape","shape"}}},
        {"MeshPart",{{"MeshId",nil,"content"},{"TextureID",nil,"content"},{"RenderFidelity"},{"CollisionFidelity"},{"DoubleSided"}}},
        {"PartOperation",{{"UsePartColor"},{"RenderFidelity"},{"CollisionFidelity"},{"SmoothingAngle"}}},
        {"Model",{{"PrimaryPart"},{"LevelOfDetail"},{"ModelStreamingMode"}}},
        {"Decal",{{"Texture",nil,"content"},{"Face"},{"Color3"},{"Transparency"},{"ZIndex",nil,"int"}}},
        {"Texture",{{"StudsPerTileU"},{"StudsPerTileV"}}},
        {"SpecialMesh",{{"MeshType"},{"MeshId",nil,"content"},{"TextureId",nil,"content"}}},
        {"DataModelMesh",{{"Scale"},{"Offset"},{"VertexColor"}}},
        {"SurfaceAppearance",{{"ColorMap",nil,"content"},{"NormalMap",nil,"content"},{"MetalnessMap",nil,"content"},{"RoughnessMap",nil,"content"},{"AlphaMode"},{"Color"}}},
        {"Light",{{"Brightness"},{"Color"},{"Enabled"},{"Shadows"}}},
        {"PointLight",{{"Range"}}},
        {"SpotLight",{{"Range"},{"Angle"},{"Face"}}},
        {"Attachment",{{"CFrame"},{"Visible"}}},
        {"WeldConstraint",{{"Part0"},{"Part1"},{"Enabled"}}},
        {"JointInstance",{{"Part0"},{"Part1"},{"C0"},{"C1"},{"Enabled"}}},
        {"Constraint",{{"Attachment0"},{"Attachment1"},{"Enabled"},{"Visible"},{"Color"}}},
        {"ValueBase",{{"Value"}}},
        {"LuaSourceContainer",{}},
        {"BaseScript",{{"RunContext"}}},
        {"Sound",{{"SoundId",nil,"content"},{"Volume"},{"Looped"},{"PlaybackSpeed"},{"Playing"}}},
        {"ParticleEmitter",{{"Texture",nil,"content"},{"Rate"},{"Lifetime"},{"Speed"},{"Size"},{"Transparency"},{"Color"},{"LightEmission"},{"Enabled"},{"Brightness"}}},
        {"Highlight",{{"FillColor"},{"OutlineColor"},{"FillTransparency"},{"OutlineTransparency"},{"DepthMode"},{"Enabled"}}},
        {"ProximityPrompt",{{"ActionText"},{"ObjectText"},{"HoldDuration"},{"MaxActivationDistance"},{"Enabled"}}},
        {"Tool",{{"CanBeDropped"},{"RequiresHandle"},{"ManualActivationOnly"},{"ToolTip"},{"Grip"},{"TextureId",nil,"content"},{"Enabled"}}},
        {"Humanoid",{{"DisplayDistanceType"},{"HealthDisplayType"},{"MaxHealth"},{"WalkSpeed"},{"JumpPower"},{"UseJumpPower"},{"HipHeight"},{"RigType"},{"DisplayName"}}},
        {"Animation",{{"AnimationId",nil,"content"}}},
        {"LayerCollector",{{"Enabled"},{"ResetOnSpawn"},{"ZIndexBehavior"}}},
        {"ScreenGui",{{"DisplayOrder",nil,"int"},{"IgnoreGuiInset"}}},
        {"SurfaceGui",{{"CanvasSize"},{"PixelsPerStud"},{"SizingMode"},{"AlwaysOnTop"},{"LightInfluence"},{"ClipsDescendants"},{"ZOffset"}}},
        {"GuiObject",{{"Size"},{"Position"},{"AnchorPoint"},{"BackgroundColor3"},{"BackgroundTransparency"},{"BorderColor3"},{"BorderSizePixel",nil,"int"},{"Visible"},{"ZIndex",nil,"int"},{"LayoutOrder",nil,"int"},{"Rotation"},{"ClipsDescendants"},{"AutomaticSize"},{"Active"}}},
        {"TextLabel",{{"Text"},{"TextColor3"},{"TextSize"},{"TextScaled"},{"TextWrapped"},{"TextXAlignment"},{"TextYAlignment"},{"FontFace"},{"RichText"},{"TextTransparency"},{"LineHeight"},{"TextTruncate"}}},
        {"TextButton",{{"Text"},{"TextColor3"},{"TextSize"},{"TextScaled"},{"TextWrapped"},{"TextXAlignment"},{"TextYAlignment"},{"FontFace"},{"RichText"},{"TextTransparency"}}},
        {"TextBox",{{"Text"},{"PlaceholderText"},{"PlaceholderColor3"},{"TextColor3"},{"TextSize"},{"TextScaled"},{"TextWrapped"},{"FontFace"},{"RichText"},{"ClearTextOnFocus"},{"MultiLine"}}},
        {"ImageLabel",{{"Image",nil,"content"},{"ImageColor3"},{"ImageTransparency"},{"ScaleType"},{"SliceCenter"},{"TileSize"},{"ImageRectOffset"},{"ImageRectSize"}}},
        {"ImageButton",{{"Image",nil,"content"},{"ImageColor3"},{"ImageTransparency"},{"ScaleType"}}},
        {"ScrollingFrame",{{"CanvasSize"},{"ScrollBarThickness",nil,"int"},{"ScrollBarImageColor3"},{"ScrollingDirection"},{"AutomaticCanvasSize"},{"ScrollingEnabled"}}},
        {"CanvasGroup",{{"GroupColor3"},{"GroupTransparency"}}},
        {"UICorner",{{"CornerRadius"}}},
        {"UIStroke",{{"Color"},{"Thickness"},{"Transparency"},{"ApplyStrokeMode"},{"Enabled"}}},
        {"UIGradient",{{"Color"},{"Transparency"},{"Rotation"},{"Offset"},{"Enabled"}}},
        {"UIPadding",{{"PaddingTop"},{"PaddingBottom"},{"PaddingLeft"},{"PaddingRight"}}},
        {"UIScale",{{"Scale"}}},
        {"UIListLayout",{{"Padding"},{"FillDirection"},{"HorizontalAlignment"},{"VerticalAlignment"},{"SortOrder"}}},
        {"UIGridLayout",{{"CellSize"},{"CellPadding"},{"SortOrder"}}},
        {"UIAspectRatioConstraint",{{"AspectRatio"},{"AspectType"},{"DominantAxis"}}},
        {"UISizeConstraint",{{"MinSize"},{"MaxSize"}}},
        {"Workspace",{{"Gravity"},{"FallenPartsDestroyHeight"}}},
        {"Lighting",{{"Ambient"},{"Brightness"},{"ClockTime"},{"ColorShift_Bottom"},{"ColorShift_Top"},{"FogColor"},{"FogEnd"},{"FogStart"},{"GlobalShadows"},{"OutdoorAmbient"},{"Technology"}}},
        {"Sky",{{"SkyboxBk",nil,"content"},{"SkyboxDn",nil,"content"},{"SkyboxFt",nil,"content"},{"SkyboxLf",nil,"content"},{"SkyboxRt",nil,"content"},{"SkyboxUp",nil,"content"}}},
        {"StarterPlayer",{{"CameraMaxZoomDistance"},{"CameraMinZoomDistance"},{"CharacterWalkSpeed"},{"CharacterJumpPower"},{"CharacterUseJumpPower"},{"AutoJumpEnabled"}}},
    }

    local TYPE_OF = {string="string",boolean="bool",EnumItem="token",Vector3="V3",Vector2="V2",CFrame="CF",Color3="C3",BrickColor="BC",UDim="UDim",UDim2="UDim2",Rect="Rect",NumberRange="NR",NumberSequence="NS",ColorSequence="CS",PhysicalProperties="Phys",Font="Font",Instance="Ref"}
    local function typedValue(pname,xname,kind,v)
        if kind=="content" then return "Content",tostring(v or "") end
        if xname=="Color3uint8" and typeof(v)=="Color3" then return "C3u8",v end
        local t=typeof(v)
        if t=="nil" then
            if pname=="CustomPhysicalProperties" then return "Phys",nil end
            return nil
        end
        if t=="number" then
            if kind=="int" then return "int",math.floor(v+0.5) end
            if kind=="int64" then return "int64",math.floor(v+0.5) end
            if kind=="double" then return "double",v end
            return "float",v
        end
        local tt=TYPE_OF[t]
        if not tt then return nil end
        return tt,v
    end

    local PlayersExp = game:GetService("Players")
    local SKIP_CLASS = {Terrain=true,Camera=true,Player=true,PlayerGui=true,Backpack=true,SelectionBox=true,SelectionSphere=true,Handles=true,ArcHandles=true}
    local SL_SYSTEM = {Workspace={FlyCameraFocus=true,ExplorerSelectionChanged=true},ReplicatedStorage={StudioLiteFolder=true,FlyCameraFocus=true},StarterGui={StudioGui=true}}
    local function shouldSkipExp(obj)
        if SKIP_CLASS[obj.ClassName] then return true end
        local okArc,arc=pcall(function()return obj.Archivable end)
        if okArc and arc==false then return true end
        if obj:IsA("Model") then
            local okP,plr=pcall(function()return PlayersExp:GetPlayerFromCharacter(obj)end)
            if okP and plr then return true end
        end
        local name=obj.Name
        local parent=obj.Parent
        if parent and parent.Parent==game then
            local deny=SL_SYSTEM[parent.ClassName]
            if deny and deny[name] then return true end
        end
        if name:sub(1,3)=="SL_" then return true end
        if name:find("^MedStudio") or name:find("^ENGINE_STUDIO") then return true end
        local low=name:lower()
        if low:find("studio%s*lite") or low:find("^studiolite") then return true end
        return false
    end

    local function packAttributes(obj)
        local ok,attrs=pcall(function()return obj:GetAttributes()end)
        if not ok or type(attrs)~="table" then return nil end
        local parts,n={},0
        for k,v in pairs(attrs) do
            if type(k)=="string" and not k:find("^LANGZ_") and not k:find("^SL_") and k~="MSClick" and k~="MSClickRoot" then
                local t,body=typeof(v),nil
                if t=="string" then body=string.pack("<Bs4",0x02,v)
                elseif t=="boolean" then body=string.pack("<BB",0x03,v and 1 or 0)
                elseif t=="number" then body=string.pack("<Bd",0x06,v)
                elseif t=="UDim" then body=string.pack("<Bfi4",0x09,v.Scale,v.Offset)
                elseif t=="UDim2" then body=string.pack("<Bfi4fi4",0x0A,v.X.Scale,v.X.Offset,v.Y.Scale,v.Y.Offset)
                elseif t=="Color3" then body=string.pack("<Bfff",0x0F,v.R,v.G,v.B)
                elseif t=="Vector3" then body=string.pack("<Bfff",0x11,v.X,v.Y,v.Z)
                end
                if body then n+=1 parts[n]=string.pack("<s4",k)..body end
            end
        end
        if n==0 then return nil end
        return string.pack("<I4",n)..table.concat(parts)
    end

    local function readPropsExp(obj,withScripts,stats)
        local out={{"Name","string",obj.Name}}
        local used={Name=true}
        local function add(name,t,v) if not used[name] then used[name]=true out[#out+1]={name,t,v} end end
        local override={}
        if obj:IsA("BasePart") then
            pcall(function()
                local a,c=obj:GetAttribute("SL_Anchored"),obj:GetAttribute("SL_CanCollide")
                if type(a)=="boolean" then override.Anchored=a end
                if type(c)=="boolean" then override.CanCollide=c end
            end)
        end
        for _,entry in ipairs(PROPS) do
            local okA,isA=pcall(function()return obj:IsA(entry[1])end)
            if okA and isA then
                for _,p in ipairs(entry[2]) do
                    local pname,xname,kind=p[1],p[2],p[3]
                    local key=xname or pname
                    if not used[key] then
                        local okV,v=pcall(function()return obj[pname]end)
                        if override[pname]~=nil then okV,v=true,override[pname] end
                        if okV then
                            local t,val=typedValue(pname,xname,kind,v)
                            if t then add(key,t,val) end
                        end
                    end
                end
            end
        end
        if obj:IsA("Model") then
            local okP,piv=pcall(function()return obj:GetPivot()end)
            if okP and piv then add("WorldPivotData","OptCF",piv) end
        end
        if obj:IsA("LuaSourceContainer") then
            stats.scripts+=1
            local src,from=nil,"kosong"
            if withScripts then src,from=scriptSource(obj) end
            if src then stats.withSource+=1 stats.from[from]=(stats.from[from] or 0)+1 end
            add("Source","string",src or "")
            if obj:IsA("BaseScript") then
                local okE,en=pcall(function()return obj.Enabled end)
                add("Disabled","bool",okE and not en or false)
            end
        end
        if type(gethiddenproperty)=="function" then
            if obj:IsA("MeshPart") then
                local okI,init=pcall(gethiddenproperty,obj,"InitialSize")
                if okI and typeof(init)=="Vector3" then add("InitialSize","V3",init) end
            elseif obj:IsA("PartOperation") then
                local okA2,aid=pcall(gethiddenproperty,obj,"AssetId")
                if okA2 and type(aid)=="string" and aid~="" then add("AssetId","Content",aid) end
                for _,key in ipairs({"MeshData","ChildData","PhysicsData"}) do
                    local okD,data=pcall(gethiddenproperty,obj,key)
                    if okD and type(data)=="string" and #data>0 then add(key,"bin",data) end
                end
            end
        end
        local attr=packAttributes(obj)
        if attr then add("AttributesSerialize","bin",attr) end
        local okT,tags=pcall(function()return CollectionService:GetTags(obj)end)
        if okT and type(tags)=="table" then
            local keep={}
            for _,tg in ipairs(tags) do if not tostring(tg):find("^MedStudio") and not tostring(tg):find("^ENGINE") then keep[#keep+1]=tg end end
            if #keep>0 then add("Tags","bin",table.concat(keep,"\0")) end
        end
        return out
    end

    -- binary writer
    local band,bor,lshift,rshift=bit32.band,bit32.bor,bit32.lshift,bit32.rshift
    local function zig32(x) x=math.floor(x) return x>=0 and x*2 or (-x*2-1) end
    local function be32(u) return string.char(rshift(u,24)%256,rshift(u,16)%256,rshift(u,8)%256,u%256) end
    local function interleaveExp(words,size)
        local n=#words if n==0 then return "" end
        local out={}
        for b=1,size do
            local col=table.create and table.create(n) or {}
            for i=1,n do col[i]=string.sub(words[i],b,b) end
            out[b]=table.concat(col)
        end
        return table.concat(out)
    end
    local function i32arr(vals) local w={} for i,v in ipairs(vals) do w[i]=be32(zig32(v)%4294967296) end return interleaveExp(w,4) end
    local function u32arr(vals) local w={} for i,v in ipairs(vals) do w[i]=be32(math.floor(v)%4294967296) end return interleaveExp(w,4) end
    local function f32bits(f) local u=string.unpack(">I4",string.pack(">f",f)) return bor(lshift(u,1),rshift(u,31)) end
    local function f32arr(vals) local w={} for i,v in ipairs(vals) do w[i]=be32(f32bits(v)) end return interleaveExp(w,4) end
    local function refArr(vals) local d,prev={},0 for i,v in ipairs(vals) do d[i]=v-prev prev=v end return i32arr(d) end
    local function i64arr(vals) local w={} for i,v in ipairs(vals) do local z=zig32(v) local hi,lo=math.floor(z/4294967296),z%4294967296 w[i]=be32(hi%4294967296)..be32(lo) end return interleaveExp(w,8) end
    local function strPack(s) return string.pack("<I4",#s)..s end

    local TYPE_ID={string=0x01,bin=0x01,Content=0x01,bool=0x02,int=0x03,float=0x04,double=0x05,UDim=0x06,UDim2=0x07,BC=0x0B,C3=0x0C,V2=0x0D,V3=0x0E,CF=0x10,token=0x12,Ref=0x13,NS=0x15,CS=0x16,NR=0x17,Rect=0x18,Phys=0x19,C3u8=0x1A,int64=0x1B,OptCF=0x1E,Font=0x20}
    local DEFAULT={string="",bin="",Content="",bool=false,int=0,float=0,double=0,int64=0,token=0,V3=Vector3.zero,V2=Vector2.zero,CF=CFrame.identity,OptCF=false,C3=Color3.new(),C3u8=Color3.new(),BC=BrickColor.new(194),UDim=UDim.new(),UDim2=UDim2.new(),Rect=Rect.new(0,0,0,0),NR=NumberRange.new(0),NS=NumberSequence.new(0),CS=ColorSequence.new(Color3.new()),Phys=false,Font=false,Ref=false}

    local function cframeValues(list)
        local head,xs,ys,zs={},{},{},{}
        for i,cf in ipairs(list) do
            local c={cf:GetComponents()}
            head[i]=string.pack("<Bfffffffff",0,c[4],c[5],c[6],c[7],c[8],c[9],c[10],c[11],c[12])
            xs[i],ys[i],zs[i]=c[1],c[2],c[3]
        end
        return table.concat(head)..f32arr(xs)..f32arr(ys)..f32arr(zs)
    end

    local function encodeValuesExp(t,list,refOf)
        if t=="string" or t=="bin" or t=="Content" then
            local o={} for i,v in ipairs(list) do o[i]=strPack(tostring(v)) end return table.concat(o)
        elseif t=="bool" then
            local o={} for i,v in ipairs(list) do o[i]=v and "\1" or "\0" end return table.concat(o)
        elseif t=="int" then return i32arr(list)
        elseif t=="float" then return f32arr(list)
        elseif t=="double" then local o={} for i,v in ipairs(list) do o[i]=string.pack("<d",v) end return table.concat(o)
        elseif t=="int64" then return i64arr(list)
        elseif t=="token" then local o={} for i,v in ipairs(list) do o[i]=type(v)=="number" and v or v.Value end return u32arr(o)
        elseif t=="UDim" then local s,of={},{} for i,v in ipairs(list) do s[i],of[i]=v.Scale,v.Offset end return f32arr(s)..i32arr(of)
        elseif t=="UDim2" then local sx,sy,ox,oy={},{},{},{} for i,v in ipairs(list) do sx[i],sy[i],ox[i],oy[i]=v.X.Scale,v.Y.Scale,v.X.Offset,v.Y.Offset end return f32arr(sx)..f32arr(sy)..i32arr(ox)..i32arr(oy)
        elseif t=="BC" then local o={} for i,v in ipairs(list) do o[i]=v.Number end return u32arr(o)
        elseif t=="C3" then local r,g,b={},{},{} for i,v in ipairs(list) do r[i],g[i],b[i]=v.R,v.G,v.B end return f32arr(r)..f32arr(g)..f32arr(b)
        elseif t=="C3u8" then local r,g,b={},{},{} local function u8c(x) return math.clamp(math.floor(x*255+0.5),0,255) end for i,v in ipairs(list) do r[i],g[i],b[i]=string.char(u8c(v.R)),string.char(u8c(v.G)),string.char(u8c(v.B)) end return table.concat(r)..table.concat(g)..table.concat(b)
        elseif t=="V2" then local x,y={},{} for i,v in ipairs(list) do x[i],y[i]=v.X,v.Y end return f32arr(x)..f32arr(y)
        elseif t=="V3" then local x,y,z={},{},{} for i,v in ipairs(list) do x[i],y[i],z[i]=v.X,v.Y,v.Z end return f32arr(x)..f32arr(y)..f32arr(z)
        elseif t=="CF" then return cframeValues(list)
        elseif t=="OptCF" then local cfs,has={},{} for i,v in ipairs(list) do cfs[i]=v or CFrame.identity has[i]=v and "\1" or "\0" end return "\16"..cframeValues(cfs).."\2"..table.concat(has)
        elseif t=="Ref" then local o={} for i,v in ipairs(list) do o[i]=(v and refOf[v]) or -1 end return refArr(o)
        elseif t=="NS" then local o={} for i,v in ipairs(list) do local kp=v.Keypoints local part={string.pack("<I4",#kp)} for _,k in ipairs(kp) do part[#part+1]=string.pack("<fff",k.Time,k.Value,k.Envelope) end o[i]=table.concat(part) end return table.concat(o)
        elseif t=="CS" then local o={} for i,v in ipairs(list) do local kp=v.Keypoints local part={string.pack("<I4",#kp)} for _,k in ipairs(kp) do part[#part+1]=string.pack("<fffff",k.Time,k.Value.R,k.Value.G,k.Value.B,0) end o[i]=table.concat(part) end return table.concat(o)
        elseif t=="NR" then local o={} for i,v in ipairs(list) do o[i]=string.pack("<ff",v.Min,v.Max) end return table.concat(o)
        elseif t=="Rect" then local a,b,c,d={},{},{},{} for i,v in ipairs(list) do a[i],b[i],c[i],d[i]=v.Min.X,v.Min.Y,v.Max.X,v.Max.Y end return f32arr(a)..f32arr(b)..f32arr(c)..f32arr(d)
        elseif t=="Phys" then local o={} for i,v in ipairs(list) do if v then o[i]="\1"..string.pack("<fffff",v.Density,v.Friction,v.Elasticity,v.FrictionWeight,v.ElasticityWeight) else o[i]="\0" end end return table.concat(o)
        elseif t=="Font" then local o={} for i,v in ipairs(list) do local fam,w,style="rbxasset://fonts/families/SourceSansPro.json",400,0 if v then fam=v.Family pcall(function()w=v.Weight.Value end) pcall(function()style=v.Style==Enum.FontStyle.Italic and 1 or 0 end) end o[i]=strPack(fam)..string.pack("<I2B",w,style)..strPack("") end return table.concat(o)
        end
        error("tipe tidak dikenal: "..tostring(t))
    end

    local function chunkExp(name,data) return name..string.pack("<I4I4I4",0,#data,0)..data end

    local function writeBinaryExp(nodes,refOf)
        local classes,classOf={},{}
        for _,node in ipairs(nodes) do
            local c=classOf[node.class]
            if not c then c={name=node.class,nodes={}} classOf[node.class]=c classes[#classes+1]=c end
            c.nodes[#c.nodes+1]=node
        end
        table.sort(classes,function(a,b)return a.name<b.name end)
        local out={"<roblox!\137\255\13\10\26\10",string.pack("<I2i4i4",0,#classes,#nodes),string.rep("\0",8)}
        out[#out+1]=chunkExp("META",string.pack("<I4",1)..strPack("ExplicitAutoJoints")..strPack("true"))
        for idx,c in ipairs(classes) do
            local refs={} for i,node in ipairs(c.nodes) do refs[i]=node.ref end
            c.index=idx-1
            local isSvc=c.nodes[1].service==true
            local data=string.pack("<I4",c.index)..strPack(c.name)..(isSvc and "\1" or "\0")..string.pack("<I4",#refs)..refArr(refs)
            if isSvc then data=data..string.rep("\1",#refs) end
            out[#out+1]=chunkExp("INST",data)
        end
        for _,c in ipairs(classes) do
            local order,typeOfProp={},{}
            for _,node in ipairs(c.nodes) do
                node.map={}
                for _,p in ipairs(node.props) do
                    node.map[p[1]]=p
                    if not typeOfProp[p[1]] then typeOfProp[p[1]]=p[2] order[#order+1]=p[1] end
                end
            end
            for _,pname in ipairs(order) do
                local t=typeOfProp[pname]
                local list={}
                for i,node in ipairs(c.nodes) do
                    local p=node.map[pname]
                    local v
                    if p and p[2]==t then v=p[3] else v=DEFAULT[t] end
                    if v==nil then v=DEFAULT[t] end
                    list[i]=v
                end
                local okE,data=pcall(encodeValuesExp,t,list,refOf)
                if okE then out[#out+1]=chunkExp("PROP",string.pack("<I4",c.index)..strPack(pname)..string.char(TYPE_ID[t])..data) end
            end
            task.wait()
        end
        local child,parent={},{}
        for i,node in ipairs(nodes) do child[i],parent[i]=node.ref,node.parent end
        out[#out+1]=chunkExp("PRNT","\0"..string.pack("<I4",#nodes)..refArr(child)..refArr(parent))
        out[#out+1]="END\0"..string.pack("<I4I4I4",0,9,0).."</roblox>"
        return table.concat(out)
    end

    local PLACE_SERVICES_EXP={"Workspace","Lighting","ReplicatedFirst","ReplicatedStorage","ServerScriptService","ServerStorage","StarterGui","StarterPack","StarterPlayer","SoundService","Teams"}
    local function containerOfExp(name)
        if name=="ServerScriptService" and typeof(_G.sss)=="Instance" and _G.sss.Parent then return _G.sss end
        if name=="ServerStorage" and typeof(_G.ss)=="Instance" and _G.ss.Parent then return _G.ss end
        local ok,svc=pcall(function()return game:GetService(name)end) if ok and svc then return svc end return nil
    end

    local function collectAllExp(roots,withScripts,onProgress)
        local nodes,refOf,count={},{},0
        local function walk(obj,parentRef)
            if shouldSkipExp(obj) or refOf[obj] then return end
            refOf[obj]=count count+=1
            local node={obj=obj,ref=refOf[obj],parent=parentRef,class=obj.ClassName}
            nodes[#nodes+1]=node
            local ok,kids=pcall(function()return obj:GetChildren()end)
            if ok then for _,c in ipairs(kids) do walk(c,node.ref) end end
        end
        if #roots==0 then return nil,"Pilih objek terlebih dahulu." end
        local function isNested(r)
            for _,other in ipairs(roots) do if other~=r and r:IsDescendantOf(other) then return true end end return false
        end
        for _,r in ipairs(roots) do if not isNested(r) then walk(r,-1) end end
        if count==0 then return nil,"Tidak ada objek yang bisa diekspor." end
        local stats={objects=count,scripts=0,withSource=0,from={}}
        for i,node in ipairs(nodes) do
            node.props=readPropsExp(node.obj,withScripts,stats)
            if i%40==0 then
                if onProgress then pcall(onProgress,i,count,node.obj.Name) end
                task.wait()
            end
        end
        return nodes,refOf,stats
    end

    local function exportExp(roots,withScripts,onProgress)
        local nodes,refOf,stats=collectAllExp(roots,withScripts,onProgress)
        if not nodes then return nil,refOf end
        if onProgress then pcall(onProgress,stats.objects,stats.objects,"menulis file") end
        task.wait()
        return writeBinaryExp(nodes,refOf),stats
    end

    local function saveExp(fileName,data,ext)
        ext=ext=="rbxl" and "rbxl" or "rbxm"
        fileName=tostring(fileName or "Export"):gsub("[^%w%-_%. ]","_"):gsub("^%s+",""):gsub("%s+$",""):gsub("%.rbx[ml]x?$","")
        if fileName=="" then fileName="Export" end
        fileName=fileName.."."..ext
        local saved={}
        pcall(function()
            if makefolder and isfolder then
                if not isfolder("EngineStudio") then makefolder("EngineStudio") end
                if not isfolder("EngineStudio/export") then makefolder("EngineStudio/export") end
            end
        end)
        local okW=pcall(writefile,"EngineStudio/export/"..fileName,data)
        if okW then saved[#saved+1]="workspace/EngineStudio/export/"..fileName end
        for _,dir in ipairs({"/storage/emulated/0/Download/EngineStudio","/sdcard/Download/EngineStudio"}) do
            local ok=pcall(function()
                if makefolder then pcall(makefolder,dir) end
                writefile(dir.."/"..fileName,data)
            end)
            if ok then saved[#saved+1]="Download/EngineStudio/"..fileName break end
        end
        return saved,fileName
    end

    return {export=exportExp,save=saveExp,shouldSkip=shouldSkipExp}
end)()

-- =====================================================================
--   EXPORT PANEL (tab EXPORT di dalam main UI)
-- =====================================================================
local EXPORT_PAGE
do
    -- panel ditempel ke content frame yang sudah ada
    local expPage = Instance.new("Frame")
    expPage.Name = "ExportPage"
    expPage.BackgroundTransparency = 1
    expPage.Size = UDim2.fromScale(1,1)
    expPage.Visible = false
    expPage.ZIndex = 21
    expPage.Parent = content
    EXPORT_PAGE = expPage

    -- scroll area
    local expScroll = Instance.new("ScrollingFrame")
    expScroll.Position = UDim2.fromOffset(8,34)
    expScroll.Size = UDim2.new(1,-16,1,-44)
    expScroll.BackgroundTransparency = 1
    expScroll.BorderSizePixel = 0
    expScroll.ScrollBarThickness = 3
    expScroll.ScrollBarImageColor3 = C.accent
    expScroll.CanvasSize = UDim2.fromOffset(0,0)
    expScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    expScroll.ScrollingDirection = Enum.ScrollingDirection.Y
    expScroll.ZIndex = 22
    expScroll.Parent = expPage
    local expList = Instance.new("UIListLayout")
    expList.Padding = UDim.new(0,6)
    expList.SortOrder = Enum.SortOrder.LayoutOrder
    expList.Parent = expScroll

    local function expText(parent,str,size,font,color,xa)
        local l=Instance.new("TextLabel")
        l.BackgroundTransparency=1
        l.Text=str l.TextSize=size
        l.Font=font or Enum.Font.GothamMedium
        l.TextColor3=color or C.text
        l.TextXAlignment=xa or Enum.TextXAlignment.Left
        l.TextYAlignment=Enum.TextYAlignment.Center
        l.TextWrapped=true
        l.AutomaticSize=Enum.AutomaticSize.Y
        l.Parent=parent
        return l
    end
    local function expCard(parent,h,order)
        local f=Instance.new("Frame")
        f.Size=UDim2.new(1,0,0,h or 36)
        if not h then f.AutomaticSize=Enum.AutomaticSize.Y end
        f.BackgroundColor3=Color3.fromRGB(255,255,255)
        f.BackgroundTransparency=0.88
        f.BorderSizePixel=0
        f.LayoutOrder=order or 0
        f.ZIndex=22
        f.Parent=parent
        corner(f,10)
        glassStroke(f,1)
        return f
    end

    -- label judul
    local lHdr=expText(expScroll,"PILIH OBJEK",10,Enum.Font.GothamBold,C.muted)
    lHdr.Size=UDim2.new(1,0,0,14)
    lHdr.LayoutOrder=0

    -- target display card
    local targetCard=expCard(expScroll,38,1)
    local targetLbl=expText(targetCard,"Target: belum dipilih",10,Enum.Font.GothamMedium,C.soft)
    targetLbl.Position=UDim2.fromOffset(10,0)
    targetLbl.Size=UDim2.new(1,-80,1,0)

    local clearBtn=Instance.new("TextButton")
    clearBtn.AutoButtonColor=false
    clearBtn.Size=UDim2.fromOffset(60,26)
    clearBtn.AnchorPoint=Vector2.new(1,0.5)
    clearBtn.Position=UDim2.new(1,-6,0.5,0)
    clearBtn.BackgroundColor3=C.accent2
    clearBtn.BackgroundTransparency=0.4
    clearBtn.Text="CLEAR"
    clearBtn.TextSize=10
    clearBtn.Font=Enum.Font.GothamBold
    clearBtn.TextColor3=Color3.fromRGB(10,20,50)
    clearBtn.AutoButtonColor=false
    clearBtn.ZIndex=23
    clearBtn.Parent=targetCard
    corner(clearBtn,8)

    -- pilih dengan ketuk 3D
    local tapCard=expCard(expScroll,34,2)
    local tapBtn=Instance.new("TextButton")
    tapBtn.AutoButtonColor=false
    tapBtn.Size=UDim2.fromScale(1,1)
    tapBtn.BackgroundTransparency=1
    tapBtn.Text="[+] PILIH DENGAN KETUK DI 3D"
    tapBtn.TextSize=11
    tapBtn.Font=Enum.Font.GothamBold
    tapBtn.TextColor3=C.ok
    tapBtn.ZIndex=23
    tapBtn.Parent=tapCard

    -- box seleksi 3D (tersimpan per objek)
    local expSelected={}
    local expSelOrder={}
    local expPickBoxes={}
    local expPicking=false

    local function updateTargetLbl()
        if #expSelOrder==0 then targetLbl.Text="Target: belum dipilih" targetLbl.TextColor3=C.soft return end
        local names={}
        for i,o in ipairs(expSelOrder) do
            if i>3 then names[#names+1]="+".. (#expSelOrder-3).." lagi" break end
            names[#names+1]=o.Name.." ["..o.ClassName.."]"
        end
        targetLbl.Text="Target: "..table.concat(names,", ")
        targetLbl.TextColor3=C.ok
    end

    local function expSetSelected(obj,on)
        if on and not expSelected[obj] then
            local box=false
            if obj:IsA("PVInstance") then
                box=Instance.new("SelectionBox")
                box.Adornee=obj
                box.Color3=C.ok
                box.LineThickness=0.05
                box.SurfaceColor3=C.ok
                box.SurfaceTransparency=0.88
                box.Parent=gui
            end
            expSelected[obj]=box
            table.insert(expSelOrder,obj)
        elseif not on and expSelected[obj]~=nil then
            if expSelected[obj] then expSelected[obj]:Destroy() end
            expSelected[obj]=nil
            for i,o in ipairs(expSelOrder) do if o==obj then table.remove(expSelOrder,i) break end end
        end
        updateTargetLbl()
    end

    clearBtn.MouseButton1Click:Connect(function()
        for _,o in ipairs(table.clone(expSelOrder)) do expSetSelected(o,false) end
    end)

    -- ketuk 3D untuk pilih objek
    local expBarGui=Instance.new("ScreenGui")
    expBarGui.Name="ESB_PickBar"
    expBarGui.ResetOnSpawn=false
    expBarGui.DisplayOrder=850
    expBarGui.IgnoreGuiInset=true
    expBarGui.Parent=CoreDest
    local expBarFrame=glassPanel(expBarGui,0.15,14)
    expBarFrame.AnchorPoint=Vector2.new(0.5,0)
    expBarFrame.Position=UDim2.new(0.5,0,0,8)
    expBarFrame.Size=UDim2.fromOffset(360,52)
    expBarFrame.Visible=false
    expBarFrame.ZIndex=850
    local expBarText=Instance.new("TextLabel")
    expBarText.BackgroundTransparency=1
    expBarText.Position=UDim2.fromOffset(14,0)
    expBarText.Size=UDim2.new(1,-150,1,0)
    expBarText.Text="Ketuk objek"
    expBarText.TextSize=12
    expBarText.Font=Enum.Font.GothamBold
    expBarText.TextColor3=C.text
    expBarText.TextXAlignment=Enum.TextXAlignment.Left
    expBarText.ZIndex=851
    expBarText.Parent=expBarFrame
    local expDoneBtn=Instance.new("TextButton")
    expDoneBtn.AutoButtonColor=false
    expDoneBtn.AnchorPoint=Vector2.new(1,0.5)
    expDoneBtn.Position=UDim2.new(1,-10,0.5,0)
    expDoneBtn.Size=UDim2.fromOffset(120,34)
    expDoneBtn.BackgroundColor3=C.ok
    expDoneBtn.BackgroundTransparency=0.25
    expDoneBtn.Text="SELESAI"
    expDoneBtn.TextSize=11
    expDoneBtn.Font=Enum.Font.GothamBold
    expDoneBtn.TextColor3=Color3.fromRGB(10,30,20)
    expDoneBtn.ZIndex=851
    expDoneBtn.Parent=expBarFrame
    corner(expDoneBtn,10)

    local function topContainerExp(part)
        local best,cur=part,part.Parent
        while cur and cur~=workspace and cur~=game do
            if cur:IsA("Model") or cur:IsA("Folder") then best=cur end
            cur=cur.Parent
        end
        return best
    end

    tapBtn.MouseButton1Click:Connect(function()
        expPicking=true
        expBarFrame.Visible=true
        expBarText.Text="Ketuk objek • "..#expSelOrder.." dipilih"
    end)
    expDoneBtn.MouseButton1Click:Connect(function()
        expPicking=false
        expBarFrame.Visible=false
    end)
    UserInputService.InputBegan:Connect(function(input,processed)
        if not expPicking or processed then return end
        if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
        local cam=workspace.CurrentCamera
        if not cam then return end
        local ray=cam:ScreenPointToRay(input.Position.X,input.Position.Y)
        local params=RaycastParams.new()
        params.FilterType=Enum.RaycastFilterType.Exclude
        local ex={}
        if LocalPlayer.Character then table.insert(ex,LocalPlayer.Character) end
        params.FilterDescendantsInstances=ex
        local hit=workspace:Raycast(ray.Origin,ray.Direction*2000,params)
        local part=hit and hit.Instance
        if part and part:IsA("BasePart") and part.Name~="MedStudioUI" and part~=workspace:FindFirstChildOfClass("Terrain") then
            local obj=topContainerExp(part)
            expSetSelected(obj,not expSelected[obj])
            expBarText.Text="Ketuk objek • "..#expSelOrder.." dipilih"
        end
    end)

    -- format segment
    local lFmt=expText(expScroll,"FORMAT OUTPUT",10,Enum.Font.GothamBold,C.muted)
    lFmt.Size=UDim2.new(1,0,0,14)
    lFmt.LayoutOrder=3
    local fmtCard=expCard(expScroll,34,4)
    local expFmt="rbxm"
    local fmtBtns={}
    for i,info in ipairs({{".RBXM","rbxm"},{".RBXL","rbxl"}}) do
        local b=Instance.new("TextButton")
        b.AutoButtonColor=false
        b.Size=UDim2.new(0.5,-4,1,-6)
        b.Position=UDim2.new((i-1)*0.5,(i==1 and 4 or 0),0,3)
        b.BackgroundColor3=Color3.fromRGB(255,255,255)
        b.BackgroundTransparency=i==1 and 0.65 or 0.9
        b.Text=info[1]
        b.TextSize=10
        b.Font=Enum.Font.GothamBold
        b.TextColor3=i==1 and C.text or C.muted
        b.ZIndex=23
        b.Parent=fmtCard
        corner(b,8)
        glassStroke(b,1)
        fmtBtns[info[2]]=b
    end
    for fmt,btn in pairs(fmtBtns) do
        btn.MouseButton1Click:Connect(function()
            expFmt=fmt
            for f2,b2 in pairs(fmtBtns) do
                b2.BackgroundTransparency=f2==fmt and 0.65 or 0.9
                b2.TextColor3=f2==fmt and C.text or C.muted
            end
        end)
    end

    -- nama file
    local lFile=expText(expScroll,"NAMA FILE (kosong = nama objek)",10,Enum.Font.GothamBold,C.muted)
    lFile.Size=UDim2.new(1,0,0,14)
    lFile.LayoutOrder=5
    local fileCard=expCard(expScroll,34,6)
    local fileInput=Instance.new("TextBox")
    fileInput.BackgroundTransparency=1
    fileInput.Size=UDim2.fromScale(1,1)
    fileInput.Text=""
    fileInput.PlaceholderText="Nama file..."
    fileInput.PlaceholderColor3=C.muted
    fileInput.TextColor3=C.text
    fileInput.TextSize=11
    fileInput.Font=Enum.Font.GothamMedium
    fileInput.TextXAlignment=Enum.TextXAlignment.Left
    fileInput.ClearTextOnFocus=false
    fileInput.ZIndex=23
    fileInput.Parent=fileCard
    local pad=Instance.new("UIPadding")
    pad.PaddingLeft=UDim.new(0,10)
    pad.Parent=fileInput

    -- toggle isi script
    local scriptTogCard=expCard(expScroll,36,7)
    local expWithScripts=true
    local stgLbl=expText(scriptTogCard,"Ikutkan isi script",11,Enum.Font.GothamBold,C.text)
    stgLbl.Position=UDim2.fromOffset(10,0)
    stgLbl.Size=UDim2.new(1,-60,1,0)
    local stgSwitch=Instance.new("TextButton")
    stgSwitch.AutoButtonColor=false
    stgSwitch.AnchorPoint=Vector2.new(1,0.5)
    stgSwitch.Position=UDim2.new(1,-8,0.5,0)
    stgSwitch.Size=UDim2.fromOffset(44,22)
    stgSwitch.BackgroundColor3=C.ok
    stgSwitch.BackgroundTransparency=0.3
    stgSwitch.Text=""
    stgSwitch.ZIndex=23
    stgSwitch.Parent=scriptTogCard
    corner(stgSwitch,11)
    local stgKnob=Instance.new("Frame")
    stgKnob.Size=UDim2.fromOffset(16,16)
    stgKnob.AnchorPoint=Vector2.new(1,0.5)
    stgKnob.Position=UDim2.new(1,-3,0.5,0)
    stgKnob.BackgroundColor3=Color3.new(1,1,1)
    stgKnob.BorderSizePixel=0
    stgKnob.ZIndex=24
    stgKnob.Parent=stgSwitch
    corner(stgKnob,8)
    stgSwitch.MouseButton1Click:Connect(function()
        expWithScripts=not expWithScripts
        TweenService:Create(stgSwitch,TweenInfo.new(0.15),{BackgroundColor3=expWithScripts and C.ok or C.soft,BackgroundTransparency=0.3}):Play()
        TweenService:Create(stgKnob,TweenInfo.new(0.15),{Position=expWithScripts and UDim2.new(1,-3,0.5,0) or UDim2.new(0,3,0.5,0)}):Play()
    end)

    -- tombol SIMPAN
    local goBtn=Instance.new("TextButton")
    goBtn.AutoButtonColor=false
    goBtn.Size=UDim2.new(1,0,0,36)
    goBtn.BackgroundColor3=C.accent2
    goBtn.BackgroundTransparency=0.25
    goBtn.Text="SIMPAN FILE"
    goBtn.TextSize=12
    goBtn.Font=Enum.Font.GothamBold
    goBtn.TextColor3=Color3.fromRGB(255,255,255)
    goBtn.ZIndex=23
    goBtn.LayoutOrder=8
    goBtn.Parent=expScroll
    corner(goBtn,10)
    glassStroke(goBtn,1.2,true)

    -- status card
    local statusCard=expCard(expScroll,nil,9)
    statusCard.AutomaticSize=Enum.AutomaticSize.Y
    local expStatusLbl=expText(statusCard,"Pilih objek lalu tekan SIMPAN FILE.",11,Enum.Font.GothamMedium,C.muted)
    expStatusLbl.Size=UDim2.new(1,-16,0,0)
    expStatusLbl.Position=UDim2.fromOffset(8,8)

    -- progress bar
    local expProgTrack=Instance.new("Frame")
    expProgTrack.Size=UDim2.new(1,-16,0,5)
    expProgTrack.Position=UDim2.fromOffset(8,0)
    expProgTrack.BackgroundColor3=Color3.fromRGB(255,255,255)
    expProgTrack.BackgroundTransparency=0.85
    expProgTrack.BorderSizePixel=0
    expProgTrack.ZIndex=23
    expProgTrack.Parent=statusCard
    corner(expProgTrack,3)
    local expProgFill=Instance.new("Frame")
    expProgFill.Size=UDim2.fromScale(0,1)
    expProgFill.BackgroundColor3=C.ok
    expProgFill.BackgroundTransparency=0.2
    expProgFill.BorderSizePixel=0
    expProgFill.ZIndex=24
    expProgFill.Parent=expProgTrack
    corner(expProgFill,3)
    local function setExpProg(v)
        TweenService:Create(expProgFill,TweenInfo.new(0.2),{Size=UDim2.fromScale(math.clamp(v,0,1),1)}):Play()
    end
    local function setExpStatus(msg,color)
        expStatusLbl.Text=tostring(msg)
        expStatusLbl.TextColor3=color or C.muted
    end

    -- result label
    local expResultLbl=expText(expScroll,"",10,Enum.Font.GothamMedium,C.ok)
    expResultLbl.Size=UDim2.new(1,0,0,0)
    expResultLbl.LayoutOrder=10
    expResultLbl.Visible=false

    local expRunning=false
    goBtn.MouseButton1Click:Connect(function()
        if expRunning then return end
        local roots={}
        for _,o in ipairs(expSelOrder) do if o.Parent then roots[#roots+1]=o end end
        if #roots==0 then setExpStatus("Belum ada yang dipilih!",C.bad) return end
        expRunning=true
        goBtn.Text="MENYIMPAN..."
        goBtn.BackgroundTransparency=0.55
        expResultLbl.Visible=false
        setExpProg(0)
        setExpStatus("Membaca objek & script...")
        task.spawn(function()
            local ok,data,stats=pcall(Exporter.export,roots,expWithScripts,function(done,total,name)
                setExpProg(done/math.max(total,1)*0.9)
                setExpStatus("Membaca "..done.." / "..total.." • "..tostring(name))
            end)
            if not ok or not data then
                setExpStatus("Gagal: "..tostring(ok and stats or data),C.bad)
            else
                local fname=fileInput.Text~="" and fileInput.Text
                    or (#roots==1 and roots[1].Name or "Export")
                setExpStatus("Menulis file...")
                local saved,finalName=Exporter.save(fname,data,expFmt)
                setExpProg(1)
                if #saved==0 then
                    setExpStatus("Gagal menulis — writefile tidak tersedia.",C.bad)
                else
                    local kb=math.floor(#data/102.4+0.5)/10
                    setExpStatus("Tersimpan: "..finalName.." ("..kb.." KB)",C.ok)
                    local lines={"Lokasi: "..table.concat(saved," | "),"Objek: "..stats.objects}
                    if stats.scripts>0 then
                        lines[#lines+1]="Script: "..stats.withSource.." / "..stats.scripts.." berisi source"
                    end
                    expResultLbl.Text=table.concat(lines,"\n")
                    expResultLbl.Visible=true
                end
            end
            expRunning=false
            goBtn.Text="SIMPAN FILE"
            goBtn.BackgroundTransparency=0.25
        end)
    end)
end

-- ---------- tab ----------
local function setTab(name)
    currentTab = name
    local isTB   = (name == "TOOLBOX")
    local isHome = (name == "HOME")
    local isAcct = (name == "AKUN")
    local isExp  = (name == "EXPORT")
    refreshTabs()
    DASH.home.Visible = isHome
    if ACCT.page then ACCT.page.Visible = isAcct end
    if EXPORT_PAGE then EXPORT_PAGE.Visible = isExp end
    searchBox.Visible = not (isHome or isAcct or isExp)
    if isHome or isAcct or isExp then
        list.Visible = false
        TB.list.Visible = false
        TB.chips.Visible = false
        TB.go.Visible = false
        emptyLbl.Visible = false
        if isHome then DASH.refresh() end
        return
    end
    list.Visible = not isTB
    TB.list.Visible = isTB
    TB.chips.Visible = isTB
    TB.go.Visible = isTB
    searchBox.Size = isTB and UDim2.new(1, -62, 0, 26) or UDim2.new(1, -16, 0, 26)
    searchBox.PlaceholderText = isTB and "Cari aset / ketik ID..." or "Cari file..."
    searchBox.Text = ""
    if isTB then
        TB.setMsg(TB.msg)
    else
        emptyLbl.Position = UDim2.fromOffset(10, 90)
        renderList()
    end
end
for name, t in pairs(tabButtons) do
    t.btn.MouseButton1Click:Connect(function() setTab(name) end)
end
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    if currentTab ~= "TOOLBOX" then renderList() end
end)

local function scanNow()
    if scanning then return end
    scanning = true
    scanBtn.Text = "SCANNING"
    ind.busy = true
    setStatus("SCANNING WORKSPACE...", C.warn)
    task.spawn(function()
        if type(listfiles) ~= "function" then
            setStatus("ERROR: listfiles tidak tersedia", C.bad)
            scanBtn.Text = "SCAN"; scanning = false
            return
        end
        local ok, results = pcall(scanAllSupported)
        if not ok then
            setStatus("SCAN ERROR: " .. tostring(results), C.bad)
            scanBtn.Text = "SCAN"; scanning = false
            return
        end
        allFiles = results
        updateBadges()
        renderList()
        local m, l = 0, 0
        for _, f in ipairs(results) do
            if f.ftype == "RBXM" then m += 1 else l += 1 end
        end
        ind.busy = false
        setStatus(("SCAN SELESAI • RBXM %d • RBXL %d"):format(m, l), (#results > 0) and C.ok or C.warn)
        scanBtn.Text = "SCAN"
        scanning = false
    end)
end
scanBtn.MouseButton1Click:Connect(scanNow)

-- ---------- dashboard <-> panel ----------
local function setHeaderMode(panel)
    backBtn.Visible = panel
end

local function showDashboard()
    DASH.mode = "dash"
    setHeaderMode(false)
    hdrSub.Text = "IMPORTER DASHBOARD"
    side.Visible = false
    content.Visible = false
    DASH.refresh()
    local d = DASH.dash
    d.Visible = true
    d.Position = UDim2.fromOffset(12, 66)
    TweenService:Create(d, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.fromOffset(12, 56),
    }):Play()
end

local function showPanel(tab)
    DASH.mode = "panel"
    setHeaderMode(true)
    DASH.dash.Visible = false
    side.Visible = true
    content.Visible = true
    setTab(tab or "HOME")
end

DASH.hooks.scan = scanNow
DASH.hooks.setTab = setTab
DASH.hooks.openTab = showPanel
backBtn.MouseButton1Click:Connect(showDashboard)

-- ---------- buka / tutup ----------
local isOpen = false
local function setOpen(v)
    if v == isOpen then return end
    isOpen = v
    local target = fitScale()
    if v then
        main.Visible = true
        mainScale.Scale = target * 0.85
        TweenService:Create(mainScale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = target }):Play()
    else
        local tw = TweenService:Create(mainScale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = target * 0.85 })
        tw:Play()
        tw.Completed:Connect(function()
            if not isOpen then main.Visible = false end
        end)
    end
end
closeBtn.MouseButton1Click:Connect(function() setOpen(false) end)

-- toggle bisa digeser, tap = buka/tutup
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
            if moved then
                toggle.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
            end
        end
    end)
end

gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    if isOpen then mainScale.Scale = fitScale() end
end)

refreshTabs()
renderList()
showDashboard()
setOpen(true)
task.delay(0.3, scanNow)
print("[ENGINE STUDIO BYPASS] RBXL/RBXM importer + exporter + toolbox loaded")
