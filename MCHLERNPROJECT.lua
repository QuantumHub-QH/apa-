--[[
============================================================
    _   __                              __  _            
   | \ / /__ _ _ _  __ _ _ __   __ _  / _\ | |__   ___   
   |  V  / _` | '_/ _` | '_ \ / _` || |_|| '_ \ / _ \  
   | |\ | (_| | | | (_| | | | | (_| ||  _|| | | |  __/  
   |_| \|\__,_|_|  \__,_|_| |_|\__,_||_|  |_| |_|\___|  
                                                            
   [*] Protocol    : NEARSX Environment API
   [*] Operation   : Deobfuscation & Optimization
============================================================
]]--

if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local AssetService = game:GetService("AssetService")
local InsertService = game:GetService("InsertService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local CoreDest = PlayerGui
pcall(function()
    local probe = Instance.new("Folder")
    probe.Name = "__HYAZ_CORE_PROBE"
    probe.Parent = CoreGui
    probe:Destroy()
    CoreDest = CoreGui
end)
local function __hx(bytes)
    local out = table.create and table.create(#bytes) or {}
    for i = 1, #bytes do
        local value = (bytes[i] - 37) % 256
        out[i] = string.char(value)
    end
    return table.concat(out)
end
local __STR = {
    ACCESS = {109,126,102,127,69,84,84,69,102,104,104,106,120,120,69,105,106,115,110,106,105},
    WARN_ID = {128,109,126,102,127,69,110,114,117,116,119,121,106,119,69,103,126,69,109,126,102,127,69,125,69,123,126,127,106,115,69,105,116,114,110,115,110,116,115,130},
    WARN_EN = {128,103,106,113,110,69,105,110,69,123,126,127,106,115,69,105,116,114,110,115,110,116,115,69,114,122,119,102,109,69,112,116,112,69,108,102,69,114,102,109,102,113,69,105,102,119,110,117,102,105,102,69,115,126,116,113,116,115,108,130},
    MAIN_BRAND = {109,126,102,127,69,84,69,119,103,125,113,69,104,116,119,106},
    MAIN_SUB = {110,114,117,116,119,121,106,119,69,103,126,69,109,126,102,127,69,125,69,123,126,127,106,115,69,105,116,114,110,115,110,116,115,69,69,7,165,199,69,69,119,103,125,113,69,104,116,119,106},
    DEBUG = {109,126,102,127,69,84,84,69,120,126,120,121,106,114,69,105,106,103,122,108},
    NOTIFY = {109,126,102,127,69,119,103,125,113,69,110,114,117,116,119,121,106,119},
    FAIL = {109,126,102,127,69,110,114,117,116,119,121,69,107,102,110,113,106,105},
    GUI_NAME = {109,126,102,127,132,119,103,125,113,132,104,116,119,106},
    WARN_GUI = {109,126,102,127,132,119,103,125,113,132,124,109,110,121,106,113,110,120,121,132,124,102,119,115,110,115,108},
    LOAD_GUI = {109,126,102,127,132,113,148,134,137,142,147,140,120,136,151,138,138,147},
    LAUNCHER = {109,126,102,127,132,113,134,154,147,136,141,138,151},
    TOAST = {109,126,102,127,132,121,148,134,152,153},
}
local function __s(key)
    return __hx(__STR[key])
end
local HYAZ_WHITELIST = {
    8901569536,
    8958292798, -- ID kamu
    -- tambah ID pembeli di bawah ini, satu per baris, pakai koma
}
local function isHYAZWhitelisted(userId)
    userId = tonumber(userId)
    for _, allowedId in ipairs(HYAZ_WHITELIST) do
        if tonumber(allowedId) == userId then
            return true
        end
    end
    return false
end
local function showWhitelistWarning()
    local oldWarning = CoreDest:FindFirstChild(__s("WARN_GUI"))
    if oldWarning then
        oldWarning:Destroy()
    end
    local warningGui = Instance.new("ScreenGui")
    warningGui.Name = __s("WARN_GUI")
    warningGui.ResetOnSpawn = false
    warningGui.IgnoreGuiInset = true
    warningGui.DisplayOrder = 999999
    warningGui.Parent = CoreDest
    local dim = Instance.new("Frame")
    dim.Size = UDim2.fromScale(1, 1)
    dim.BackgroundColor3 = Color3.fromRGB(2, 3, 5)
    dim.BackgroundTransparency = 0.12
    dim.BorderSizePixel = 0
    dim.Parent = warningGui
    local panel = Instance.new("Frame")
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.Size = UDim2.new(0.78, 0, 0, 235)
    panel.BackgroundColor3 = Color3.fromRGB(8, 8, 11)
    panel.BorderSizePixel = 0
    panel.Parent = dim
    local maxSize = Instance.new("UISizeConstraint")
    maxSize.MaxSize = Vector2.new(760, 235)
    maxSize.MinSize = Vector2.new(300, 225)
    maxSize.Parent = panel
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = panel
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(155, 25, 44)
    stroke.Thickness = 1.3
    stroke.Transparency = 0.12
    stroke.Parent = panel
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(56, 7, 15)),
        ColorSequenceKeypoint.new(0.34, Color3.fromRGB(17, 8, 12)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 6, 9)),
    })
    grad.Rotation = 135
    grad.Parent = panel
    local topLine = Instance.new("Frame")
    topLine.Size = UDim2.new(1, 0, 0, 3)
    topLine.BackgroundColor3 = Color3.fromRGB(238, 48, 76)
    topLine.BorderSizePixel = 0
    topLine.Parent = panel
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -36, 0, 35)
    title.Position = UDim2.fromOffset(18, 17)
    title.BackgroundTransparency = 1
    title.Text = __s("ACCESS")
    title.TextColor3 = Color3.fromRGB(255, 224, 229)
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 17
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = panel
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -36, 0, 18)
    status.Position = UDim2.fromOffset(19, 52)
    status.BackgroundTransparency = 1
    status.Text = ("USER ID %s  •  NOT WHITELISTED"):format(tostring(LocalPlayer.UserId))
    status.TextColor3 = Color3.fromRGB(181, 86, 102)
    status.Font = Enum.Font.Code
    status.TextSize = 9
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Parent = panel
    local separator = Instance.new("Frame")
    separator.Size = UDim2.new(1, -36, 0, 1)
    separator.Position = UDim2.fromOffset(18, 79)
    separator.BackgroundColor3 = Color3.fromRGB(94, 27, 39)
    separator.BackgroundTransparency = 0.25
    separator.BorderSizePixel = 0
    separator.Parent = panel
    local indo = Instance.new("TextLabel")
    indo.Size = UDim2.new(1, -36, 0, 48)
    indo.Position = UDim2.fromOffset(18, 92)
    indo.BackgroundTransparency = 1
    indo.Text = __s("WARN_ID")
    indo.TextColor3 = Color3.fromRGB(255, 237, 240)
    indo.Font = Enum.Font.GothamBold
    indo.TextSize = 12
    indo.TextWrapped = true
    indo.TextXAlignment = Enum.TextXAlignment.Left
    indo.TextYAlignment = Enum.TextYAlignment.Center
    indo.Parent = panel
    local english = Instance.new("TextLabel")
    english.Size = UDim2.new(1, -36, 0, 48)
    english.Position = UDim2.fromOffset(18, 145)
    english.BackgroundTransparency = 1
    english.Text = __s("WARN_EN")
    english.TextColor3 = Color3.fromRGB(174, 169, 177)
    english.Font = Enum.Font.GothamMedium
    english.TextSize = 11
    english.TextWrapped = true
    english.TextXAlignment = Enum.TextXAlignment.Left
    english.TextYAlignment = Enum.TextYAlignment.Center
    english.Parent = panel
    local locked = Instance.new("TextLabel")
    locked.Size = UDim2.new(1, -36, 0, 18)
    locked.Position = UDim2.new(0, 18, 1, -28)
    locked.BackgroundTransparency = 1
    locked.Text = "EXECUTION LOCKED // WHITELIST REQUIRED"
    locked.TextColor3 = Color3.fromRGB(226, 55, 82)
    locked.Font = Enum.Font.Code
    locked.TextSize = 9
    locked.TextXAlignment = Enum.TextXAlignment.Left
    locked.Parent = panel
end
if not isHYAZWhitelisted(LocalPlayer.UserId) then
    local ID_WARNING = __s("WARN_ID")
    local EN_WARNING = __s("WARN_EN")
    warn(ID_WARNING)
    warn(EN_WARNING)
    showWhitelistWarning()
    return
end
_G.Hyaz_RAW_SOURCES = _G.Hyaz_RAW_SOURCES or {}
_G.Hyaz_RAW_SOURCE_BY_REF = _G.Hyaz_RAW_SOURCE_BY_REF or {}
if type(string.unpack) ~= "function" then
    warn("[HYAZ RBXL] string.unpack tidak tersedia. Binary RBXL tidak dapat dibaca di executor ini.")
end
local BINARY_BIT32_OK = type(bit32) == "table"
if not BINARY_BIT32_OK then
    warn("[HYAZ RBXL] bit32 tidak tersedia. UI tetap dibuka, tetapi import binary tidak bisa berjalan.")
end
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
    if compressedLen == 0 then
        return input:read(decompressedLen)
    end
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
        if offset <= 0 or offset > outLen then
            error("LZ4 invalid match offset")
        end
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
        if type(buffer) == "table" and type(buffer.tostring) == "function" then
            return buffer.tostring(v)
        end
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
        if not text then error("JSONDecode returned a buffer but this runtime has no buffer->string bridge") end
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
    if not m then
        return nil
    end
    return CFrame.new(
        p.X, p.Y, p.Z,
        m[1],m[2],m[3],
        m[4],m[5],m[6],
        m[7],m[8],m[9]
    )
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
            for j = 1, 9 do
                m[j] = buffer:readNumber("<f")
            end
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
            out[i] = CFrame.new(
                p.X,p.Y,p.Z,
                m[1],m[2],m[3],
                m[4],m[5],m[6],
                m[7],m[8],m[9]
            )
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
            quats[i] = {
                buffer:readNumber("<f"),
                buffer:readNumber("<f"),
                buffer:readNumber("<f"),
                buffer:readNumber("<f"),
            }
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
            local origin = Vector3.new(
                buffer:readNumber("<f"), buffer:readNumber("<f"), buffer:readNumber("<f")
            )
            local direction = Vector3.new(
                buffer:readNumber("<f"), buffer:readNumber("<f"), buffer:readNumber("<f")
            )
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
        for i=1,count do
            a[i]=Vector2int16.new(buffer:readNumber("<i2"),buffer:readNumber("<i2"))
        end
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
            a[i]=Vector3int16.new(
                buffer:readNumber("<i2"),buffer:readNumber("<i2"),buffer:readNumber("<i2")
            )
        end
        return a
    elseif typeID == 0x15 then
        local a=table.create(count)
        for i=1,count do
            local n=buffer:readNumber("<I4")
            local points=table.create(n)
            for j=1,n do
                points[j]=NumberSequenceKeypoint.new(
                    buffer:readNumber("<f"), buffer:readNumber("<f"), buffer:readNumber("<f")
                )
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
                local c=Color3.new(
                    buffer:readNumber("<f"), buffer:readNumber("<f"), buffer:readNumber("<f")
                )
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
                if discriminator == 0x03 then
                    buffer:readNumber("<f")
                end
                local ok, pp=pcall(
                    PhysicalProperties.new,
                    density, friction, elasticity, frictionWeight, elasticityWeight
                )
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
        for i=1,count do
            a[i]=sharedStrings and sharedStrings[idx[i] + 1] or nil
        end
        return a
    elseif typeID == 0x1E then
        local innerType=string.byte(buffer:read())
        if innerType ~= 0x10 then
            error("Optional type tidak didukung: "..tostring(innerType))
        end
        local values=_readCFrames(buffer,count)
        local presenceType=string.byte(buffer:read())
        if presenceType ~= 0x02 then
            error("Optional presence type invalid: "..tostring(presenceType))
        end
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
                a[i]=uris[ui]
                ui += 1
            elseif kinds[i] == 2 then
                a[i]={__ContentObjectRef=objectRefs[oi]}
                oi += 1
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
    if classCount > 100000 or instCount > 5000000 then
        return nil, "RBXL header count tidak masuk akal"
    end
    local chunks={META={},SSTR={},INST={},PROP={},PRNT={},SIGN={},["END\0"]={}}
    while r.Offset < r.Length do
        if r.Length - r.Offset < 16 then
            return nil, "RBXL chunk header terpotong"
        end
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
            if #payload ~= decompressed then
                return nil, "RBXL chunk "..sig.." terpotong"
            end
        else
            local raw=r:read(compressed)
            if #raw ~= compressed then
                return nil, "RBXL compressed chunk "..sig.." terpotong"
            end
            local magic=string.sub(raw,1,4)
            if magic==string.char(40,181,47,253) then
                payload=zstd(raw)
            else
                if type(string.pack) ~= "function" then
                    return nil, "string.pack tidak tersedia untuk LZ4"
                end
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
        local b=Buffer(ch.Data,false); local cid=b:readNumber("<I4"); local cname=basicTypes.String(b); local format=string.byte(b:read()); local n=b:readNumber("<I4"); local refs=basicTypes.RefArray(b,n)
        classes[cid]={Name=cname,Count=n,Refs=refs,IsService=(format==1)}
        local marks={}; if format==1 then for i=1,n do marks[i]=string.byte(b:read())~=0 end end
        for i,ref in ipairs(refs) do nodes[ref]={Ref=ref,ClassId=cid,ClassName=cname,IsService=(format==1),Properties={},PropertyTypes={},Children={},Service=marks[i] or false} end
        if format==1 then for i,ref in ipairs(refs) do serviceRefs[ref]=true end end
    end
    for _,ch in ipairs(chunks.PROP) do
        local b=Buffer(ch.Data,false); local cid=b:readNumber("<I4"); local cls=classes[cid]; if not cls then return nil,"PROP class id tidak ditemukan: "..cid end
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
            warn(("[HYAZ RBXL] property skipped: %s (type 0x%02X)"):format(pname, typeID or 0))
        end
    end
    local childToParent={}
    for _,ch in ipairs(chunks.PRNT) do local b=Buffer(ch.Data,false); local ver=string.byte(b:read()); if ver~=0 then return nil,"PRNT version tidak didukung" end; local n=b:readNumber("<I4"); local children=basicTypes.RefArray(b,n); local parents=basicTypes.RefArray(b,n); for i=1,n do childToParent[children[i]]=parents[i] end end
    local roots={}
    for ref,node in pairs(nodes) do
        local p=childToParent[ref]
        if p and p~=-1 and nodes[p] then table.insert(nodes[p].Children,node) else table.insert(roots,node) end
    end
    return {Header={ClassCount=classCount,InstanceCount=instCount},Nodes=nodes,Roots=roots,Services=serviceRefs,SharedStrings=shared}, nil
end
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
    if type(value) == "number" then
        id = math.floor(value)
    else
        id = tonumber(tostring(value):match("%d+"))
    end
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
                local index = cursor
                local id = jobs[index]
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
    local realSource = _G.Hyaz_RAW_SOURCES[scr] or (sourceMap and sourceMap[path])
    if not realSource then pcall(function() realSource = scr.Source end) end
    if realSource and #realSource > 0 then local _nullpat = string.char(0); realSource = realSource:gsub(_nullpat .. "*$", "") else realSource = "" end
    _G.Hyaz_RAW_SOURCES[scr] = realSource
    local UI_TEXT = realSource
    if #UI_TEXT > 150000 then UI_TEXT = "-- [source terlalu besar untuk ditampilkan]" end
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
local function injectAllScripts(root, sourceMap)
    if not root then return 0 end
    local list = {}
    if root:IsA("LuaSourceContainer") then table.insert(list, root) end
    for _, d in ipairs(root:GetDescendants()) do if d:IsA("LuaSourceContainer") then table.insert(list, d) end end
    local count = 0
    for _, s in ipairs(list) do pcall(injectStudioLiteUI, s, sourceMap); count = count + 1; task.wait(0.02) end
    return count
end
local function ApplyStudioLiteProperties(obj)
    if not obj then return end
    pcall(function()
        if obj:IsA("BasePart") then
            local originalAnchor = obj.Anchored
            local originalCollide = obj.CanCollide
            obj.Anchored = true
            if obj:GetAttribute("SL_Anchored") == nil then obj:SetAttribute("SL_Anchored", originalAnchor) end
            if obj:GetAttribute("SL_CanCollide") == nil then obj:SetAttribute("SL_CanCollide", originalCollide) end
        end
    end)
    for _, child in ipairs(obj:GetChildren()) do ApplyStudioLiteProperties(child) end
end
local function LoadAssetsToSLServer(obj)
    local function scan(node)
        pcall(function()
            if node:IsA("MeshPart") then triggerServerLoad(node.MeshId); triggerServerLoad(node.TextureID)
            elseif node:IsA("Decal") or node:IsA("Texture") then triggerServerLoad(node.Texture)
            elseif node:IsA("SpecialMesh") then triggerServerLoad(node.MeshId); triggerServerLoad(node.TextureId)
            elseif node:IsA("Clothing") or node:IsA("ShirtGraphic") then triggerServerLoad(node.ClassName == "ShirtGraphic" and node.Graphic or node[node.ClassName.."Template"])
            elseif node:IsA("UnionOperation") or node:IsA("PartOperation") then triggerServerLoad(node.AssetId) end
        end)
        for _, child in ipairs(node:GetChildren()) do scan(child) end
    end
    scan(obj)
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
    Chat = ReplicatedStorage
}
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
    if value == nil then return true end
    if propName == "Source" or propName == "ContentText" then
        if obj:IsA("LuaSourceContainer") and type(value) == "string" then
            local clean = value:gsub(string.char(0) .. "*$", "")
            _G.Hyaz_RAW_SOURCES[obj] = clean
            local refKey = obj:GetAttribute("HYAZ_Ref")
            if refKey ~= nil then
                _G.Hyaz_RAW_SOURCE_BY_REF[tostring(refKey)] = clean
            end
        end
        return true
    end
    if typeID == 0x13 then return true end
    if typeID == 0x1F or typeID == 0x21 then return true end
    if typeID == 0x22 and type(value) == "table" then return true end
    if READONLY_GEOMETRY_PROPS[propName] then
        return true
    end
    local runtimeName = runtimePropertyName(propName)
    if runtimeName == "MaterialVariant" and value == "" then
        return true
    end
    if typeID == 0x12 and type(value) == "number" then
        if setEnumFromValue(obj, runtimeName, value) then
            return true
        end
    end
    return pcall(function()
        obj[runtimeName] = value
    end)
end
local function assetIdFromValue(v)
    if v == nil then return nil end
    if type(v) == "number" then
        if v > 0 then return math.floor(v) end
        return nil
    end
    if type(v) == "string" then
        local id = v:match("rbxassetid://(%d+)")
            or v:match("[?&]id=(%d+)")
            or v:match("(%d+)")
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
    if not root then return nil end
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
    if not candidate then return nil end
    candidate.Parent = nil
    if root ~= candidate then
        pcall(function() root:Destroy() end)
    end
    return candidate
end
local function tryGameGetObjectsGeometry(id, wantedClass)
    if not id then return nil end
    local ok, objects = pcall(function()
        return game:GetObjects("rbxassetid://" .. tostring(id))
    end)
    if not ok or type(objects) ~= "table" then return nil end
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
    if not id then return nil, "no mesh id" end
    local content = contentFromAssetIdCompat(id)
    local errors = {}
    local ok1, mesh1 = pcall(function()
        return AssetService:CreateMeshPartAsync(content, {})
    end)
    if ok1 and mesh1 and mesh1:IsA("MeshPart") then
        return mesh1, "AssetService"
    end
    if not ok1 then table.insert(errors, tostring(mesh1)) end
    local ok2, mesh2 = pcall(function()
        return AssetService:CreateMeshPartAsync("rbxassetid://" .. tostring(id), {})
    end)
    if ok2 and mesh2 and mesh2:IsA("MeshPart") then
        return mesh2, "AssetServiceLegacy"
    end
    if not ok2 then table.insert(errors, tostring(mesh2)) end
    local getObj = tryGameGetObjectsGeometry(id, "MeshPart")
    if getObj and getObj:IsA("BasePart") then
        return getObj, "GetObjects"
    end
    return nil, table.concat(errors, " | ")
end
local function serializedSize(p)
    if not p then return nil end
    local s = p.size or p.Size
    if typeof(s) == "Vector3" then
        return Vector3.new(
            math.max(math.abs(s.X), 0.001),
            math.max(math.abs(s.Y), 0.001),
            math.max(math.abs(s.Z), 0.001)
        )
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
    if typeof(p.CFrame) == "CFrame" then
        pcall(function() obj.CFrame = p.CFrame end)
    end
    local c = serializedColor(p)
    if c then pcall(function() obj.Color = c end) end
    if p.Transparency ~= nil then
        pcall(function() obj.Transparency = p.Transparency end)
    end
    if p.Reflectance ~= nil then
        pcall(function() obj.Reflectance = p.Reflectance end)
    end
    if p.Material ~= nil and type(p.Material) == "number" then
        pcall(function()
            setEnumFromValue(obj, "Material", p.Material)
        end)
    end
    pcall(function() obj.Anchored = true end)
end
local function configureSpecialMeshScale(mesh, p)
    if not mesh or not p then return end
    local wantedSize = serializedSize(p)
    local originalSize = p.InitialSize or p.MeshSize
    if wantedSize
        and typeof(originalSize) == "Vector3"
        and math.abs(originalSize.X) > 1e-6
        and math.abs(originalSize.Y) > 1e-6
        and math.abs(originalSize.Z) > 1e-6 then
        mesh.Scale = Vector3.new(
            wantedSize.X / originalSize.X,
            wantedSize.Y / originalSize.Y,
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
    mesh.Name = "__HYAZ_MeshVisual"
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = "rbxassetid://" .. tostring(meshId)
    local texId = assetIdFromValue(p.TextureID or p.TextureId or p.TextureContent)
    if texId then
        pcall(function()
            mesh.TextureId = "rbxassetid://" .. tostring(texId)
        end)
    end
    configureSpecialMeshScale(mesh, p)
    mesh.Parent = part
    return part
end
local function isMeshPartOnlyChildClass(className)
    return className == "SurfaceAppearance"
        or className == "WrapLayer"
        or className == "WrapTarget"
end
local function nodeNeedsNativeMeshPart(node)
    for _, child in ipairs(node.Children or {}) do
        if child.ClassName == "WrapLayer"
            or child.ClassName == "WrapTarget" then
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
        local fallback = makeSpecialMeshFallback(node, meshId)
        return fallback, "fallback", "TurboSpecialMesh"
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
        mesh.Name = "__HYAZ_CSGVisual"
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
    if not node or not node.Properties then return end
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
    elseif node.ClassName == "UnionOperation"
        or node.ClassName == "PartOperation"
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
    local okEnabled = pcall(function()
        obj.Enabled = enabled
    end)
    if okEnabled then wrote = true end
    local okDisabled = pcall(function()
        obj.Disabled = not enabled
    end)
    if okDisabled then wrote = true end
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
    local okEnabled, enabled = pcall(function()
        return obj.Enabled
    end)
    if okEnabled and type(enabled) == "boolean" then
        return enabled
    end
    local okDisabled, disabled = pcall(function()
        return obj.Disabled
    end)
    if okDisabled and type(disabled) == "boolean" then
        return not disabled
    end
    return true
end
local function importedScriptShouldRun(obj)
    if not obj or not obj:IsA("LuaSourceContainer") then
        return false
    end
    local originalEnabled = obj:GetAttribute("HYAZ_OriginalEnabled")
    if originalEnabled ~= nil then
        return originalEnabled == true
    end
    local legacyDisabled = obj:GetAttribute("HYAZ_OriginalDisabled")
    if legacyDisabled ~= nil then
        return legacyDisabled == false
    end
    return true
end
local function importRootName(fileName)
    local base = tostring(fileName or "RBXL")
    base = base:gsub("%.rbxl$", "")
    base = base:gsub("%.RBXL$", "")
    base = base:gsub("[%c/\\:*?\"<>|]", "_")
    base = base:gsub("^%s+", ""):gsub("%s+$", "")
    if base == "" then base = "RBXL" end
    return base .. " IMPORTER BY YAZZ"
end
local function reportImportProgress(value, message)
    local cb = _G.HYAZ_IMPORT_PROGRESS_CB
    if type(cb) == "function" then
        pcall(cb, value, message)
    end
end
local function buildRBXL(parsed, sourceFileName)
    local made = {}
    local skipped = 0
    local failedProperties = 0
    local progressTotal = math.max(
        tonumber(parsed.Header and parsed.Header.InstanceCount) or 1,
        1
    )
    local progressMade = 0
    reportImportProgress(0.20, "BUILDING INSTANCES")
    local meshNative = 0
    local meshFallback = 0
    local meshUnresolved = 0
    local csgAsset = 0
    local csgProxy = 0
    local rootName = importRootName(sourceFileName)
    local oldRoot = workspace:FindFirstChild(rootName)
    if oldRoot then pcall(function() oldRoot:Destroy() end) end
    local importRoot = Instance.new("Folder")
    importRoot.Name = rootName
    importRoot:SetAttribute("HYAZ_RBXL_IMPORT", true)
    importRoot:SetAttribute("HYAZ_SourceFile", tostring(sourceFileName or ""))
    importRoot:SetAttribute("HYAZ_InMemoryStaging", true)
    importRoot.Parent = nil
    local containers = {}
    local function newServiceFolder(key, displayName)
        local folder = Instance.new("Folder")
        folder.Name = displayName
        folder:SetAttribute("HYAZ_ServiceKey", key)
        folder.Parent = importRoot
        containers[key] = folder
        return folder
    end
    newServiceFolder("WS",  "workspace(ws)")
    newServiceFolder("RS",  "replicate storage(rs)")
    newServiceFolder("RF",  "replicate first(rf)")
    newServiceFolder("L",   "lighting(l)")
    newServiceFolder("P",   "players(p)")
    newServiceFolder("SG",  "starter gui(sg)")
    newServiceFolder("STP", "starter pack(stp)")
    newServiceFolder("SP",  "starter player(sp)")
    newServiceFolder("SPS", "starter player script(sps)")
    newServiceFolder("SCS", "starter character script(scs)")
    newServiceFolder("SSS", "serverscriptservice(sss)")
    newServiceFolder("SS",  "server storage(ss)")
    newServiceFolder("TEAM", "teams(team)")
    newServiceFolder("SND",  "sound service(sound)")
    newServiceFolder("MAT",   "material service(mat)")
    newServiceFolder("TCS",   "text chat service(tcs)")
    newServiceFolder("CHAT",  "chat(chat)")
    newServiceFolder("LOC",   "localization service(loc)")
    newServiceFolder("TEST",  "test service(test)")
    newServiceFolder("HTTP",  "http service(http)")
    newServiceFolder("INS",   "insert service(ins)")
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
        local nodeName = tostring((node.Properties and node.Properties.Name) or "")
        local direct = serviceKeyByName[className] or serviceKeyByName[nodeName]
        if direct then return direct end
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
        if not obj:IsA("BasePart") then return end
        local originalAnchored = false
        local originalCanCollide = true
        if node.Properties.Anchored ~= nil then
            originalAnchored = node.Properties.Anchored
        else
            pcall(function() originalAnchored = obj.Anchored end)
        end
        if node.Properties.CanCollide ~= nil then
            originalCanCollide = node.Properties.CanCollide
        else
            pcall(function() originalCanCollide = obj.CanCollide end)
        end
        pcall(function()
            obj:SetAttribute("SL_Anchored", originalAnchored)
            obj:SetAttribute("SL_CanCollide", originalCanCollide)
            obj.Anchored = true
        end)
    end
    local function disableImportedScript(obj, node)
        if not obj:IsA("LuaSourceContainer") then return end
        local originalEnabled = getOriginalScriptEnabled(obj, node)
        pcall(function()
            obj:SetAttribute("HYAZ_OriginalEnabled", originalEnabled)
            obj:SetAttribute("HYAZ_OriginalDisabled", not originalEnabled)
            obj:SetAttribute("HYAZ_StagedDisabled", true)
        end)
        setScriptEnabledState(obj, false)
    end
    local function normalizePartGeometry(obj, node)
        if not obj:IsA("BasePart") then return end
        local p = node.Properties or {}
        applyBaseVisualState(obj, p)
        local special = obj:FindFirstChild("__HYAZ_MeshVisual")
            or obj:FindFirstChild("__HYAZ_CSGVisual")
        if special and special:IsA("SpecialMesh") then
            configureSpecialMeshScale(special, p)
        end
    end
    local function instantiateNode(node)
        if node.ClassName == "MeshPart" then
            local obj, mode = tryCreateMeshPartNode(node)
            if obj then
                if mode == "native" then
                    meshNative += 1
                elseif mode == "fallback" then
                    meshFallback += 1
                else
                    meshUnresolved += 1
                end
                return obj
            end
            meshUnresolved += 1
            return nil
        end
        if node.ClassName == "UnionOperation" or node.ClassName == "PartOperation" or node.ClassName == "IntersectOperation" then
            local obj, mode = tryLoadPartOperationNode(node)
            if obj then
                if mode == "asset" or mode == "mesh" or mode == "visual" then
                    csgAsset += 1
                else
                    csgProxy += 1
                end
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
        if isMeshPartOnlyChildClass(node.ClassName)
            and (not parent or not parent:IsA("MeshPart")) then
            skipped += 1
            return nil
        end
        local nodeName = tostring((node.Properties and node.Properties.Name) or "")
        local isServiceLike = node.IsService or node.Service
            or serviceKeyByName[node.ClassName]
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
            skipped += 1
            for _, child in ipairs(node.Children) do
                createNode(child, parent or containers[routeKey] or containers.WS, routeKey)
            end
            return nil
        end
        made[node.Ref] = obj
        pcall(function()
            obj:SetAttribute("HYAZ_ImportedObject", true)
            obj:SetAttribute("HYAZ_Ref", tostring(node.Ref))
        end)
        if node.Properties.Name ~= nil then
            local okName = pcall(function()
                obj.Name = tostring(node.Properties.Name)
            end)
            if not okName then failedProperties += 1 end
        end
        for propName, value in pairs(node.Properties) do
            if propName ~= "Name" then
                local okProp = applyDecodedProperty(
                    obj,
                    propName,
                    value,
                    node.PropertyTypes and node.PropertyTypes[propName]
                )
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
            reportImportProgress(
                0.20 + ratio * 0.55,
                ("GENERATING %d / %d"):format(progressMade, progressTotal)
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
                skipped += 1
            end
        end
        return obj
    end
    for _, root in ipairs(parsed.Roots) do
        local key = routeForNode(root, "WS")
        local rootNameProp = tostring((root.Properties and root.Properties.Name) or "")
        if root.IsService or root.Service
            or serviceKeyByName[root.ClassName]
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
                if typeID == 0x13 then
                    local targetRef = node.Properties[propName]
                    local targetObj = made[targetRef]
                    if targetObj then
                        local okRef = pcall(function()
                            obj[propName] = targetObj
                        end)
                        if not okRef then failedProperties += 1 end
                    end
                elseif typeID == 0x22 then
                    local contentValue = node.Properties[propName]
                    if type(contentValue) == "table" and contentValue.__ContentObjectRef then
                        local targetObj = made[contentValue.__ContentObjectRef]
                        if targetObj then
                            local okRef = pcall(function()
                                obj[propName] = targetObj
                            end)
                            if not okRef then failedProperties += 1 end
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
                pcall(function()
                    injectStudioLiteUI(obj, {})
                end)
                scriptBatch += 1
                if scriptBatch >= 40 then
                    scriptBatch = 0
                    task.wait()
                end
            end
        end
    end)
    flushServerLoadsAsync()
    local madeCount = 0
    for _ in pairs(made) do madeCount += 1 end
    reportImportProgress(0.78, ("BUILD COMPLETE • %d INSTANCES"):format(madeCount))
    return madeCount, skipped, failedProperties,
        meshNative, meshFallback, meshUnresolved, csgAsset, csgProxy, importRoot
end
local function safeReadFile(path)
    if type(readfile) ~= "function" then
        return nil, "readfile tidak tersedia"
    end
    local ok, data = pcall(readfile, path)
    if not ok then return nil, tostring(data) end
    if type(data) ~= "string" or #data == 0 then
        return nil, "file kosong / tidak terbaca"
    end
    return data
end
local function importRBXL(fileInfo)
    reportImportProgress(0.02, "READING RBXL")
    if type(string.unpack) ~= "function" then
        return false, "COMPAT ERROR: string.unpack tidak tersedia"
    end
    if type(bit32) ~= "table" then
        return false, "COMPAT ERROR: bit32 tidak tersedia"
    end
    local data, readErr = safeReadFile(fileInfo.path)
    reportImportProgress(0.08, "RBXL LOADED")
    if not data then
        return false, "READ ERROR: " .. tostring(readErr)
    end
    if data:sub(1, 8) ~= "<roblox!" then
        return false, "File bukan RBXL binary yang valid"
    end
    reportImportProgress(0.12, "PARSING RBXL")
    local okParse, parsed, parseErr = pcall(parseRBXLBinary, data)
    if not okParse then
        return false, "PARSER CRASH: " .. tostring(parsed)
    end
    if not parsed then
        return false, "PARSE ERROR: " .. tostring(parseErr or "unknown")
    end
    reportImportProgress(
        0.18,
        ("PARSED • %d INSTANCES"):format(
            tonumber(parsed.Header and parsed.Header.InstanceCount) or 0
        )
    )
    local okBuild, madeCount, skipped, failedProperties,
        meshNative, meshFallback, meshUnresolved, csgAsset, csgProxy, importRoot = pcall(
            buildRBXL,
            parsed,
            fileInfo.name
        )
    if not okBuild then
        return false, "BUILD ERROR: " .. tostring(madeCount)
    end
    local rootLabel = importRoot and importRoot.Name or importRootName(fileInfo.name)
    return true, ("TURBO OK %d | %s | mesh N:%d F:%d U:%d | CSG A:%d P:%d | prop:%d"):format(
        madeCount or 0,
        rootLabel,
        meshNative or 0,
        meshFallback or 0,
        meshUnresolved or 0,
        csgAsset or 0,
        csgProxy or 0,
        failedProperties or 0
    ), importRoot
end
local HYAZ_MODULE_CACHE = setmetatable({}, {__mode = "k"})
local HYAZ_MODULE_LOADING = setmetatable({}, {__mode = "k"})
local function rawSourceFor(scr)
    if not scr or not scr:IsA("LuaSourceContainer") then
        return nil
    end
    local direct = _G.Hyaz_RAW_SOURCES[scr]
    if type(direct) == "string" and direct ~= "" then
        return direct
    end
    local refKey = scr:GetAttribute("HYAZ_Ref")
    if refKey ~= nil then
        local byRef = _G.Hyaz_RAW_SOURCE_BY_REF[tostring(refKey)]
        if type(byRef) == "string" and byRef ~= "" then
            return byRef
        end
    end
    return nil
end
local function canReadExecutableSource(scr)
    local ok, source = pcall(function()
        return scr.Source
    end)
    return ok and type(source) == "string" and #source > 0, source
end
local runtimeRequire
local function compileRuntimeSource(scr, source)
    if type(loadstring) ~= "function" then
        return nil, "loadstring tidak tersedia"
    end
    local wrapped =
        "return function(script, require, ...)\\n"
        .. source
        .. "\\nend"
    local okCompile, loaderOrErr = pcall(
        loadstring,
        wrapped,
        "=HYAZ_RBXL/" .. tostring(scr:GetFullName())
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
        if HYAZ_MODULE_CACHE[target] ~= nil then
            return HYAZ_MODULE_CACHE[target]
        end
        if HYAZ_MODULE_LOADING[target] then
            error("HYAZ runtime require circular dependency: " .. target:GetFullName())
        end
        local source = rawSourceFor(target)
        if source then
            HYAZ_MODULE_LOADING[target] = true
            local runner, compileErr = compileRuntimeSource(target, source)
            if not runner then
                HYAZ_MODULE_LOADING[target] = nil
                error("Module compile failed: " .. tostring(compileErr))
            end
            local results = table.pack(
                pcall(runner, target, runtimeRequire)
            )
            HYAZ_MODULE_LOADING[target] = nil
            if not results[1] then
                error(results[2])
            end
            local result = results[2]
            HYAZ_MODULE_CACHE[target] = result
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
    if scr:GetAttribute("HYAZ_RuntimeStarted") then
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
    scr:SetAttribute("HYAZ_RuntimeStarted", true)
    task.spawn(function()
        local ok, runtimeErr = pcall(
            runner,
            scr,
            runtimeRequire
        )
        if not ok then
            warn(
                "[HYAZ LIVE SCRIPT ERROR] "
                .. scr:GetFullName()
                .. " :: "
                .. tostring(runtimeErr)
            )
            scr:SetAttribute("HYAZ_RuntimeError", tostring(runtimeErr))
        end
    end)
    return true, "runtime_bridge"
end
local function prepareLocalScriptsForClone(root)
    if not root then return end
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
            stats.skipped += 1
            setScriptEnabledState(scr, false)
        else
            local hasRealSource = canReadExecutableSource(scr)
            if hasRealSource then
                local ok = setScriptEnabledState(scr, true)
                if ok then
                    stats.native += 1
                else
                    stats.failed += 1
                end
            else
                setScriptEnabledState(scr, false)
                local ok = runLocalScriptBridge(scr)
                if ok then
                    stats.bridge += 1
                else
                    stats.failed += 1
                end
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
    if not scr or not scr:IsA("LuaSourceContainer") then
        return false, "not_script"
    end
    local source = _G.Hyaz_RAW_SOURCES[scr]
    if type(source) ~= "string" or source == "" then
        return false, "source_missing"
    end
    source = source:gsub(string.char(0) .. "*$", "")
    local directOK = false
    if type(setscriptable) == "function" then
        pcall(setscriptable, scr, "Source", true)
    end
    directOK = pcall(function()
        scr.Source = source
    end)
    if directOK then
        return true, "direct"
    end
    local saveRemote = findStudioLiteRemote("SaveScriptSourceServerFunction")
    if saveRemote and saveRemote:IsA("RemoteFunction") then
        local ok = pcall(function()
            saveRemote:InvokeServer(scr.ClassName .. scr.Name, source)
        end)
        if ok then
            return true, "studio_lite_remote"
        end
    elseif saveRemote and saveRemote:IsA("RemoteEvent") then
        local ok = pcall(function()
            saveRemote:FireServer(scr.ClassName .. scr.Name, source)
        end)
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
    local all = {root}
    for _, d in ipairs(root:GetDescendants()) do
        all[#all + 1] = d
    end
    for _, obj in ipairs(all) do
        if obj:IsA("LuaSourceContainer") then
            stats.scripts += 1
            local ok = tryWriteRealScriptSource(obj)
            if ok then
                stats.scriptSourceOK += 1
            else
                stats.scriptSourceFailed += 1
            end
        end
    end
    for _, obj in ipairs(all) do
        if obj:IsA("BasePart") then
            stats.parts += 1
            local originalAnchored = obj:GetAttribute("SL_Anchored")
            local originalCanCollide = obj:GetAttribute("SL_CanCollide")
            if originalCanCollide ~= nil then
                pcall(function()
                    obj.CanCollide = originalCanCollide
                end)
            end
            pcall(function()
                obj.Anchored = true
                obj:SetAttribute("HYAZ_AutoAnchored", true)
            end)
        end
    end
    return stats
end
local function moveChildren(source, destination, onMoved)
    if not source or not destination then return 0 end
    local moved = 0
    local children = source:GetChildren()
    for _, child in ipairs(children) do
        local ok = pcall(function()
            child.Parent = destination
        end)
        if ok then
            moved += 1
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
    reportImportProgress(0.80, "PREPARING SERVICES")
    local forcedServiceCount = 0
    local reusedServiceCount = 0
    local createdServiceCount = 0
    local proxyServiceCount = 0
    local missingRealServices = 0
    local serviceModes = {}
    local function getTopLevelChildrenNamed(serviceName)
        local matches = {}
        local ok, children = pcall(function()
            return game:GetChildren()
        end)
        if not ok or type(children) ~= "table" then
            return matches
        end
        for _, child in ipairs(children) do
            local childName = ""
            pcall(function()
                childName = child.Name
            end)
            if childName == serviceName then
                matches[#matches + 1] = child
            end
        end
        return matches
    end
    local function isHyazGeneratedService(obj)
        if not obj then return false end
        local generated = false
        pcall(function()
            generated =
                obj:GetAttribute("HYAZ_ForcedRealService") == true
                or obj:GetAttribute("HYAZ_ForcedVisibleService") == true
                or obj:GetAttribute("HYAZ_CreatedService") == true
        end)
        return generated
    end
    local function mergeChildrenInto(source, destination)
        if not source or not destination or source == destination then
            return 0
        end
        local moved = 0
        local children = {}
        pcall(function()
            children = source:GetChildren()
        end)
        for _, child in ipairs(children) do
            local okMove = pcall(function()
                child.Parent = destination
            end)
            if okMove then
                moved += 1
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
            if not isHyazGeneratedService(obj) then
                chosen = obj
                break
            end
        end
        chosen = chosen or matches[1]
        for _, obj in ipairs(matches) do
            if obj ~= chosen and isHyazGeneratedService(obj) then
                mergeChildrenInto(obj, chosen)
                pcall(function()
                    obj:Destroy()
                end)
            end
        end
        return chosen
    end
    local function forceGetService(serviceName)
        local existing = findExistingService(serviceName)
        if existing then
            reusedServiceCount += 1
            serviceModes[serviceName] = "REUSED_STUDIO_LITE"
            return existing
        end
        local created
        local okCreate, createErr = pcall(function()
            created = Instance.new(serviceName)
            created.Name = serviceName
            created:SetAttribute("HYAZ_ForcedRealService", true)
            created:SetAttribute("HYAZ_ServiceRole", serviceName)
            created.Parent = game
        end)
        if okCreate and created then
            createdServiceCount += 1
            serviceModes[serviceName] = "CREATED_MISSING"
            return created
        end
        local okGet, service = pcall(function()
            return game:GetService(serviceName)
        end)
        if okGet and service then
            forcedServiceCount += 1
            serviceModes[serviceName] = "GETSERVICE_MISSING"
            pcall(function()
                service:SetAttribute("HYAZ_ServiceRole", serviceName)
            end)
            return service
        end
        missingRealServices += 1
        serviceModes[serviceName] = "FAILED"
        warn(
            "[HYAZ] SERVICE FAILED: "
            .. serviceName
            .. " tidak tersedia di Studio Lite runtime ini. "
            .. tostring(createErr)
        )
        return nil
    end
    local function tryForceVisibleService(serviceName, realService)
        if not realService or findExistingService(serviceName) then
            return nil
        end
        local roots = {game}
        for _, candidate in ipairs({_G.sss, _G.ss}) do
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
        pcall(function()
            realService.Archivable = true
        end)
        for _, root in ipairs(roots) do
            local clone
            local okClone = pcall(function()
                clone = realService:Clone()
            end)
            if okClone and clone then
                local className = ""
                pcall(function() className = clone.ClassName end)
                if className == serviceName then
                    local okParent = pcall(function()
                        clone.Name = serviceName
                        clone:SetAttribute("HYAZ_ExplorerVisibleService", true)
                        clone.Parent = root
                    end)
                    if okParent then
                        serviceModes[serviceName] = "VISIBLE_REAL_CLONE"
                        return clone
                    end
                end
                pcall(function() clone:Destroy() end)
            end
        end
        return nil
    end
    local WorkspaceService       = forceGetService("Workspace")
    local PlayersSvc             = forceGetService("Players")
    local LightingSvc            = forceGetService("Lighting")
    local ReplicatedFirstSvc     = forceGetService("ReplicatedFirst")
    local ReplicatedStorageSvc   = forceGetService("ReplicatedStorage")
    local StarterGuiSvc          = forceGetService("StarterGui")
    local StarterPackSvc         = forceGetService("StarterPack")
    local StarterPlayerSvc       = forceGetService("StarterPlayer")
    local TeamsSvc               = forceGetService("Teams")
    local ServerScriptServiceSvc = forceGetService("ServerScriptService")
    local ServerStorageSvc       = forceGetService("ServerStorage")
    local SoundServiceSvc        = forceGetService("SoundService")
    local MaterialServiceSvc     = forceGetService("MaterialService")
    local TextChatServiceSvc     = forceGetService("TextChatService")
    local ChatSvc                = forceGetService("Chat")
    local LocalizationServiceSvc = forceGetService("LocalizationService")
    local TestServiceSvc         = forceGetService("TestService")
    local HttpServiceSvc         = forceGetService("HttpService")
    local InsertServiceSvc       = forceGetService("InsertService")
    local TweenServiceSvc        = forceGetService("TweenService")
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
        if not parent then return nil end
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
        fallback:SetAttribute("HYAZ_StarterContainerFallback", true)
        fallback.Parent = parent
        return fallback
    end
    local starterPlayerScripts = ensureStarterContainer(
        StarterPlayerSvc,
        "StarterPlayerScripts",
        "StarterPlayerScripts"
    )
    local starterCharacterScripts = ensureStarterContainer(
        StarterPlayerSvc,
        "StarterCharacterScripts",
        "StarterCharacterScripts"
    )
    local destinationByKey = {
        WS   = WorkspaceService,
        RS   = ReplicatedStorageSvc,
        RF   = ReplicatedFirstSvc,
        L    = LightingSvc,
        P    = PlayersSvc,
        SG   = StarterGuiSvc,
        STP  = StarterPackSvc,
        SP   = StarterPlayerSvc,
        SPS  = starterPlayerScripts,
        SCS  = starterCharacterScripts,
        SSS  = ServerScriptServiceSvc,
        SS   = ServerStorageSvc,
        TEAM = TeamsSvc,
        SND  = SoundServiceSvc,
        MAT   = MaterialServiceSvc,
        TCS   = TextChatServiceSvc,
        CHAT  = ChatSvc,
        LOC   = LocalizationServiceSvc,
        TEST  = TestServiceSvc,
        HTTP  = HttpServiceSvc,
        INS   = InsertServiceSvc,
        TWEEN = TweenServiceSvc,
    }
    local StarterPlayer = StarterPlayerSvc
    local Teams = TeamsSvc
    local SoundService = SoundServiceSvc
    local MaterialService = MaterialServiceSvc
    local TextChatService = TextChatServiceSvc
    local Chat = ChatSvc
    local LocalizationService = LocalizationServiceSvc
    local TestService = TestServiceSvc
    local HttpService = HttpServiceSvc
    local InsertServiceForced = InsertServiceSvc
    local TweenServiceForced = TweenServiceSvc
    local runtimeStats = restoreImportedRuntimeState(importRoot)
    reportImportProgress(0.87, "RESTORING SCRIPT SOURCES")
    local moved = 0
    local failedServices = 0
    local stagedCounts = {}
    local stagedScriptCounts = {}
    for _, serviceFolder in ipairs(importRoot:GetChildren()) do
        if serviceFolder:IsA("Folder") then
            local key = serviceFolder:GetAttribute("HYAZ_ServiceKey")
            if key then
                stagedCounts[key] = #serviceFolder:GetChildren()
                local scriptCount = 0
                for _, d in ipairs(serviceFolder:GetDescendants()) do
                    if d:IsA("LuaSourceContainer") then
                        scriptCount += 1
                    end
                end
                stagedScriptCounts[key] = scriptCount
            end
        end
    end
    for _, serviceFolder in ipairs(importRoot:GetChildren()) do
        if serviceFolder:IsA("Folder") then
            local key = serviceFolder:GetAttribute("HYAZ_ServiceKey")
            local destination = destinationByKey[key]
            if destination then
                moved += moveChildren(serviceFolder, destination)
            elseif #serviceFolder:GetChildren() > 0 then
                failedServices += 1
            end
        end
    end
    reportImportProgress(0.91, ("DEPLOYED • %d OBJECTS"):format(moved))
    local activatedScripts = 0
    local function restoreOneImportedScript(obj)
        if not obj:IsA("LuaSourceContainer")
            or not obj:GetAttribute("HYAZ_StagedDisabled") then
            return
        end
        local shouldRun = importedScriptShouldRun(obj)
        setScriptEnabledState(obj, shouldRun)
        pcall(function()
            obj:SetAttribute("HYAZ_StagedDisabled", nil)
        end)
        if shouldRun then
            activatedScripts += 1
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
        if not sourceContainer or not destinationContainer then return end
        for _, child in ipairs(sourceContainer:GetChildren()) do
            if child:GetAttribute("HYAZ_ImportedObject") == true then
                local existing = destinationContainer:FindFirstChild(child.Name)
                if existing and existing:GetAttribute("HYAZ_LiveClone") == true then
                    pcall(function()
                        existing:Destroy()
                    end)
                end
                local clone
                local okClone = pcall(function()
                    clone = child:Clone()
                end)
                if okClone and clone then
                    clone:SetAttribute("HYAZ_LiveClone", true)
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
        if obj:IsA("LocalScript")
            and obj:GetAttribute("HYAZ_ImportedObject") == true then
            local hasRealSource = canReadExecutableSource(obj)
            if hasRealSource then
                setScriptEnabledState(obj, true)
                liveStats.native += 1
            else
                setScriptEnabledState(obj, false)
                local ok = runLocalScriptBridge(obj)
                if ok then
                    liveStats.bridge += 1
                else
                    liveStats.failed += 1
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
        if not service then return end
        for _, obj in ipairs(service:GetDescendants()) do
            if obj:IsA("LuaSourceContainer")
                and obj:GetAttribute("HYAZ_ImportedObject") == true then
                deployedScriptCount += 1
                if serviceKey == "SSS" then
                    sssImportedScripts += 1
                elseif serviceKey == "SS" then
                    ssImportedScripts += 1
                end
                local refKey = obj:GetAttribute("HYAZ_Ref")
                local source = _G.Hyaz_RAW_SOURCES[obj]
                if (type(source) ~= "string" or source == "")
                    and refKey ~= nil then
                    source = _G.Hyaz_RAW_SOURCE_BY_REF[tostring(refKey)]
                    if type(source) == "string" and source ~= "" then
                        _G.Hyaz_RAW_SOURCES[obj] = source
                    end
                end
                if type(source) == "string" and source ~= "" then
                    sourceVisibleCount += 1
                    pcall(function()
                        tryWriteRealScriptSource(obj)
                    end)
                    local okEditor = pcall(function()
                        injectStudioLiteUI(obj, {})
                    end)
                    if okEditor then
                        editorInjectedCount += 1
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
        warn(
            "[HYAZ] WARNING: RBXL memiliki "
            .. tostring(stagedScriptCounts.SSS)
            .. " script untuk ServerScriptService, tetapi tidak terlihat "
            .. "di service final."
        )
    end
    if (stagedScriptCounts.SS or 0) > 0 and ssImportedScripts == 0 then
        warn(
            "[HYAZ] WARNING: RBXL memiliki "
            .. tostring(stagedScriptCounts.SS)
            .. " script untuk ServerStorage, tetapi tidak terlihat "
            .. "di service final."
        )
    end
    for _, service in pairs(destinationByKey) do
        if service then
            for _, obj in ipairs(service:GetDescendants()) do
                if obj:IsA("LuaSourceContainer")
                    and obj:GetAttribute("HYAZ_ImportedObject") == true then
                    setScriptEnabledState(
                        obj,
                        importedScriptShouldRun(obj)
                    )
                end
            end
        end
    end
    for _, service in pairs(destinationByKey) do
        if service then
            for _, obj in ipairs(service:GetDescendants()) do
                if obj:IsA("BasePart")
                    and obj:GetAttribute("HYAZ_ImportedObject") == true then
                    pcall(function()
                        obj.Anchored = true
                        obj:SetAttribute("HYAZ_AutoAnchored", true)
                    end)
                end
            end
        end
    end
    importRoot:SetAttribute("HYAZ_Activated", true)
    local remainingStagedObjects = 0
    for _, serviceFolder in ipairs(importRoot:GetChildren()) do
        if serviceFolder:IsA("Folder") then
            remainingStagedObjects += #serviceFolder:GetChildren()
        end
    end
    if remainingStagedObjects == 0 then
        pcall(function()
            importRoot:Destroy()
        end)
    end
    reportImportProgress(1.00, "RBXL GENERATION COMPLETE")
    return true, ("ACTIVE • moved:%d • scripts:%d active:%d • source:%d/%d • SSS:%d SS:%d • editor:%d/%d • service reused:%d real-created:%d getservice:%d real-failed:%d"):format(
        moved,
        runtimeStats.scripts,
        activatedScripts,
        runtimeStats.scriptSourceOK,
        runtimeStats.scripts,
        sssImportedScripts,
        ssImportedScripts,
        editorInjectedCount,
        sourceVisibleCount,
        reusedServiceCount,
        createdServiceCount,
        forcedServiceCount,
        missingRealServices
    )
end
local function safeListFiles(path)
    if type(listfiles) ~= "function" then return nil end
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
    "workspace",
    "Delta/workspace",
    "delta/workspace",
    "Android/Delta/workspace",
    "/sdcard/Delta/workspace",
    "/sdcard/Android/Delta/workspace",
    "../workspace",
    ".",
    ""
}
local function normalizeFsPath(path)
    local p = tostring(path or ""):gsub("\\", "/"):lower()
    p = p:gsub("/+", "/")
    p = p:gsub("^%./", "")
    p = p:gsub("^%.%./", "")
    p = p:gsub("/$", "")
    return p
end
local function canonicalWorkspacePath(path)
    local p = normalizeFsPath(path)
    local lastWorkspace
    local searchFrom = 1
    while true do
        local s, e = p:find("workspace/", searchFrom, true)
        if not s then break end
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
    if depth > 4 then return end
    local folderKey = canonicalWorkspacePath(folder)
    if folderKey == "" then
        folderKey = "__workspace_root__"
    end
    if seenFolders[folderKey] then return end
    seenFolders[folderKey] = true
    local list = safeListFiles(folder)
    if not list then return end
    for _, path in ipairs(list) do
        local name = getFileName(path)
        local lower = name:lower()
        if lower:match("%.rbxl$") then
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
                    ftype = "RBXL",
                    canonicalKey = fileKey
                })
            end
        elseif looksFolder(path) then
            scanDeep(path, depth + 1, results, seenFolders, seenFiles)
        end
    end
end
local function scanAllRBXL()
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
local old = CoreDest:FindFirstChild(__s("GUI_NAME"))
if old then old:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = __s("GUI_NAME")
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 700
gui.Parent = CoreDest
local LoadingScreen = Instance.new("Frame")
LoadingScreen.Name = __s("LOAD_GUI")
LoadingScreen.Size = UDim2.fromScale(1, 1)
LoadingScreen.Position = UDim2.fromScale(0, 0)
LoadingScreen.BackgroundColor3 = Color3.fromRGB(3, 4, 7)
LoadingScreen.BorderSizePixel = 0
LoadingScreen.ZIndex = 900
LoadingScreen.Parent = gui
local LoadingBG = Instance.new("ImageLabel")
LoadingBG.Name = "Background"
LoadingBG.Size = UDim2.fromScale(1, 1)
LoadingBG.Position = UDim2.fromScale(0, 0)
LoadingBG.BackgroundTransparency = 1
LoadingBG.Image = "rbxassetid://96261746551768"
LoadingBG.ScaleType = Enum.ScaleType.Crop
LoadingBG.ImageTransparency = 0.08
LoadingBG.ZIndex = 901
LoadingBG.Parent = LoadingScreen
local DarkOverlay = Instance.new("Frame")
DarkOverlay.Size = UDim2.fromScale(1, 1)
DarkOverlay.BackgroundColor3 = Color3.fromRGB(4, 5, 8)
DarkOverlay.BackgroundTransparency = 0.28
DarkOverlay.BorderSizePixel = 0
DarkOverlay.ZIndex = 902
DarkOverlay.Parent = LoadingScreen
local OverlayGrad = Instance.new("UIGradient")
OverlayGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(2, 3, 6)),
    ColorSequenceKeypoint.new(0.45, Color3.fromRGB(18, 4, 9)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(2, 3, 6)),
})
OverlayGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.05),
    NumberSequenceKeypoint.new(0.45, 0.28),
    NumberSequenceKeypoint.new(1, 0.08),
})
OverlayGrad.Rotation = 0
OverlayGrad.Parent = DarkOverlay
local Scanlines = Instance.new("Frame")
Scanlines.Size = UDim2.fromScale(1, 1)
Scanlines.BackgroundTransparency = 1
Scanlines.ZIndex = 903
Scanlines.Parent = LoadingScreen
for y = 0, 18 do
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Position = UDim2.new(0, 0, y / 18, 0)
    line.BackgroundColor3 = Color3.fromRGB(255, 70, 95)
    line.BackgroundTransparency = 0.92
    line.BorderSizePixel = 0
    line.ZIndex = 903
    line.Parent = Scanlines
end
local AccentLine = Instance.new("Frame")
AccentLine.Size = UDim2.new(0, 3, 0.72, 0)
AccentLine.Position = UDim2.new(0.61, 0, 0.14, 0)
AccentLine.BackgroundColor3 = Color3.fromRGB(228, 48, 74)
AccentLine.BackgroundTransparency = 0.18
AccentLine.BorderSizePixel = 0
AccentLine.ZIndex = 904
AccentLine.Parent = LoadingScreen
local RightPanel = Instance.new("Frame")
RightPanel.Size = UDim2.new(0.34, 0, 0.55, 0)
RightPanel.Position = UDim2.new(0.635, 0, 0.18, 0)
RightPanel.BackgroundColor3 = Color3.fromRGB(7, 8, 12)
RightPanel.BackgroundTransparency = 0.26
RightPanel.BorderSizePixel = 0
RightPanel.ZIndex = 904
RightPanel.Parent = LoadingScreen
local RP_Corner = Instance.new("UICorner")
RP_Corner.CornerRadius = UDim.new(0, 14)
RP_Corner.Parent = RightPanel
local RP_Stroke = Instance.new("UIStroke")
RP_Stroke.Color = Color3.fromRGB(120, 28, 42)
RP_Stroke.Thickness = 1
RP_Stroke.Transparency = 0.35
RP_Stroke.Parent = RightPanel
local RP_Gradient = Instance.new("UIGradient")
RP_Gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(27, 8, 13)),
    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(9, 10, 14)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(3, 4, 7)),
})
RP_Gradient.Rotation = 135
RP_Gradient.Parent = RightPanel
local DebugTitle = Instance.new("TextLabel")
DebugTitle.Size = UDim2.new(1, -28, 0, 24)
DebugTitle.Position = UDim2.new(0, 14, 0, 14)
DebugTitle.BackgroundTransparency = 1
DebugTitle.Text = __s("DEBUG")
DebugTitle.TextColor3 = Color3.fromRGB(245, 242, 244)
DebugTitle.Font = Enum.Font.GothamBold
DebugTitle.TextSize = 11
DebugTitle.TextXAlignment = Enum.TextXAlignment.Left
DebugTitle.ZIndex = 905
DebugTitle.Parent = RightPanel
local DebugSub = Instance.new("TextLabel")
DebugSub.Size = UDim2.new(1, -28, 0, 18)
DebugSub.Position = UDim2.new(0, 14, 0, 39)
DebugSub.BackgroundTransparency = 1
DebugSub.Text = "RBXL CORE INITIALIZATION"
DebugSub.TextColor3 = Color3.fromRGB(170, 83, 99)
DebugSub.Font = Enum.Font.Code
DebugSub.TextSize = 8
DebugSub.TextXAlignment = Enum.TextXAlignment.Left
DebugSub.ZIndex = 905
DebugSub.Parent = RightPanel
local DebugLog = Instance.new("TextLabel")
DebugLog.Size = UDim2.new(1, -28, 1, -80)
DebugLog.Position = UDim2.new(0, 14, 0, 66)
DebugLog.BackgroundTransparency = 1
DebugLog.Text = ""
DebugLog.TextColor3 = Color3.fromRGB(176, 181, 192)
DebugLog.Font = Enum.Font.Code
DebugLog.TextSize = 8
DebugLog.TextWrapped = true
DebugLog.TextXAlignment = Enum.TextXAlignment.Left
DebugLog.TextYAlignment = Enum.TextYAlignment.Top
DebugLog.ZIndex = 905
DebugLog.Parent = RightPanel
local BottomBar = Instance.new("Frame")
BottomBar.Size = UDim2.new(0.74, 0, 0, 7)
BottomBar.Position = UDim2.new(0.13, 0, 0.86, 0)
BottomBar.BackgroundColor3 = Color3.fromRGB(22, 23, 30)
BottomBar.BorderSizePixel = 0
BottomBar.ZIndex = 904
BottomBar.Parent = LoadingScreen
local BB_Corner = Instance.new("UICorner")
BB_Corner.CornerRadius = UDim.new(1, 0)
BB_Corner.Parent = BottomBar
local Fill = Instance.new("Frame")
Fill.Size = UDim2.new(0, 0, 1, 0)
Fill.BackgroundColor3 = Color3.fromRGB(213, 42, 67)
Fill.BorderSizePixel = 0
Fill.ZIndex = 905
Fill.Parent = BottomBar
local FillCorner = Instance.new("UICorner")
FillCorner.CornerRadius = UDim.new(1, 0)
FillCorner.Parent = Fill
local FillGradient = Instance.new("UIGradient")
FillGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(111, 14, 29)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(242, 61, 89)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 126, 144)),
})
FillGradient.Parent = Fill
local BottomStatus = Instance.new("TextLabel")
BottomStatus.Size = UDim2.new(0.74, 0, 0, 18)
BottomStatus.Position = UDim2.new(0.13, 0, 0.82, 0)
BottomStatus.BackgroundTransparency = 1
BottomStatus.Text = "INITIALIZING..."
BottomStatus.TextColor3 = Color3.fromRGB(218, 218, 224)
BottomStatus.Font = Enum.Font.Code
BottomStatus.TextSize = 8
BottomStatus.TextXAlignment = Enum.TextXAlignment.Left
BottomStatus.ZIndex = 905
BottomStatus.Parent = LoadingScreen
local Percent = Instance.new("TextLabel")
Percent.Size = UDim2.new(0, 70, 0, 18)
Percent.Position = UDim2.new(0.87, -70, 0.82, 0)
Percent.BackgroundTransparency = 1
Percent.Text = "00%"
Percent.TextColor3 = Color3.fromRGB(255, 95, 120)
Percent.Font = Enum.Font.GothamBold
Percent.TextSize = 8
Percent.TextXAlignment = Enum.TextXAlignment.Right
Percent.ZIndex = 905
Percent.Parent = LoadingScreen
local loadingSteps = {
    {"BOOTSTRAP CORE", "mounting runtime modules", 0.14},
    {"READING EXECUTOR ENV", "checking file APIs / http bridge", 0.28},
    {"PARSER LINK", "attaching RBXL binary parser", 0.44},
    {"MESH BRIDGE", "preparing runtime geometry handlers", 0.61},
    {"SERVICE MAP", "building importer workspace routes", 0.76},
    {"UI KERNEL", "mounting HYAZ interface", 0.90},
    {"READY", "system online", 1.00},
}
local debugLines = {}
local function appendDebug(line)
    table.insert(debugLines, "> " .. line)
    if #debugLines > 8 then
        table.remove(debugLines, 1)
    end
    DebugLog.Text = table.concat(debugLines, "\n")
end
task.spawn(function()
    appendDebug("boot sequence started")
    for _, step in ipairs(loadingSteps) do
        local label = step[1]
        local detail = step[2]
        local target = step[3]
        BottomStatus.Text = label .. " // " .. detail
        appendDebug(label:lower() .. " ... ok")
        local current = Fill.Size.X.Scale
        for i = 1, 14 do
            local a = i / 14
            local eased = a * a * (3 - 2 * a)
            local value = current + (target - current) * eased
            Fill.Size = UDim2.new(value, 0, 1, 0)
            Percent.Text = string.format("%02d%%", math.floor(value * 100 + 0.5))
            task.wait(0.035)
        end
        Fill.Size = UDim2.new(target, 0, 1, 0)
        Percent.Text = string.format("%02d%%", math.floor(target * 100 + 0.5))
        task.wait(0.08)
    end
    task.wait(0.18)
    local fadeInfo = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    for _, obj in ipairs(LoadingScreen:GetDescendants()) do
        pcall(function()
            if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                TweenService:Create(obj, fadeInfo, {TextTransparency = 1}):Play()
            elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
                TweenService:Create(obj, fadeInfo, {ImageTransparency = 1}):Play()
            elseif obj:IsA("Frame") then
                TweenService:Create(obj, fadeInfo, {BackgroundTransparency = 1}):Play()
            elseif obj:IsA("UIStroke") then
                TweenService:Create(obj, fadeInfo, {Transparency = 1}):Play()
            end
        end)
    end
    pcall(function()
        TweenService:Create(LoadingScreen, fadeInfo, {BackgroundTransparency = 1}):Play()
    end)
    task.wait(0.5)
    if LoadingScreen and LoadingScreen.Parent then
        LoadingScreen:Destroy()
    end
end)
local CHEVRON_RIGHT = "rbxassetid://10709791437"
local CHEVRON_LEFT  = "rbxassetid://10709791281"
local Theme = {
    bg = Color3.fromRGB(6, 7, 10),
    deepRed = Color3.fromRGB(38, 7, 12),
    red = Color3.fromRGB(108, 20, 34),
    red2 = Color3.fromRGB(173, 35, 55),
    panel = Color3.fromRGB(11, 12, 16),
    panel2 = Color3.fromRGB(17, 18, 24),
    panel3 = Color3.fromRGB(26, 22, 28),
    border = Color3.fromRGB(91, 42, 51),
    text = Color3.fromRGB(245, 241, 243),
    muted = Color3.fromRGB(145, 137, 143),
    success = Color3.fromRGB(79, 211, 145),
    warning = Color3.fromRGB(241, 173, 74),
    danger = Color3.fromRGB(255, 79, 99)
}
local function round(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = obj
    return c
end
local function stroke(obj, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.border
    s.Thickness = thickness or 1
    s.Transparency = transparency == nil and 0 or transparency
    s.Parent = obj
    return s
end
local function gradient(obj, colors, rotation)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(colors)
    g.Rotation = rotation or 0
    g.Parent = obj
    return g
end
local launcherShadow = Instance.new("Frame")
launcherShadow.Size = UDim2.fromOffset(40, 40)
launcherShadow.Position = UDim2.new(0, 12, 0.5, -20)
launcherShadow.BackgroundColor3 = Color3.new(0,0,0)
launcherShadow.BackgroundTransparency = 0.42
launcherShadow.BorderSizePixel = 0
launcherShadow.Parent = gui
round(launcherShadow, 20)
local launcher = Instance.new("TextButton")
launcher.Name = __s("LAUNCHER")
launcher.Size = UDim2.fromOffset(36, 36)
launcher.Position = UDim2.new(0, 14, 0.5, -18)
launcher.BackgroundColor3 = Theme.deepRed
launcher.BorderSizePixel = 0
launcher.AutoButtonColor = false
launcher.Text = ""
launcher.Parent = gui
round(launcher, 18)
stroke(launcher, Theme.red2, 1, 0.12)
gradient(launcher, {
    ColorSequenceKeypoint.new(0, Color3.fromRGB(122, 22, 38)),
    ColorSequenceKeypoint.new(0.55, Color3.fromRGB(49, 8, 15)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 9, 12))
}, 135)
local launcherIcon = Instance.new("ImageLabel")
launcherIcon.Name = "Chevron"
launcherIcon.Size = UDim2.fromOffset(16, 16)
launcherIcon.Position = UDim2.new(0.5, -8, 0.5, -8)
launcherIcon.BackgroundTransparency = 1
launcherIcon.Image = CHEVRON_RIGHT
launcherIcon.ImageColor3 = Theme.text
launcherIcon.ScaleType = Enum.ScaleType.Fit
launcherIcon.ZIndex = launcher.ZIndex + 1
launcherIcon.Parent = launcher
local launcherFallback = Instance.new("TextLabel")
launcherFallback.Name = "ChevronFallback"
launcherFallback.Size = UDim2.fromScale(1, 1)
launcherFallback.BackgroundTransparency = 1
launcherFallback.Text = ">"
launcherFallback.TextColor3 = Theme.text
launcherFallback.TextSize = 17
launcherFallback.Font = Enum.Font.GothamBold
launcherFallback.ZIndex = launcherIcon.ZIndex - 1
launcherFallback.Parent = launcher
local shadow = Instance.new("Frame")
shadow.Size = UDim2.fromOffset(382, 306)
shadow.Position = UDim2.new(0.5, -191, 0.5, -153)
shadow.BackgroundColor3 = Color3.new(0,0,0)
shadow.BackgroundTransparency = 0.45
shadow.BorderSizePixel = 0
shadow.Parent = gui
round(shadow, 17)
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(370, 294)
main.Position = UDim2.new(0.5, -185, 0.5, -147)
main.BackgroundColor3 = Theme.bg
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = gui
round(main, 15)
stroke(main, Theme.border, 1, 0.12)
gradient(main, {
    ColorSequenceKeypoint.new(0, Color3.fromRGB(69, 10, 20)),
    ColorSequenceKeypoint.new(0.28, Color3.fromRGB(29, 8, 13)),
    ColorSequenceKeypoint.new(0.64, Color3.fromRGB(8, 9, 12)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 7, 13))
}, 135)
local mainScale = Instance.new("UIScale")
mainScale.Scale = 1
mainScale.Parent = main
local topAccent = Instance.new("Frame")
topAccent.Size = UDim2.new(1, 0, 0, 2)
topAccent.BackgroundColor3 = Theme.red2
topAccent.BorderSizePixel = 0
topAccent.Parent = main
gradient(topAccent, {
    ColorSequenceKeypoint.new(0, Color3.fromRGB(74, 9, 18)),
    ColorSequenceKeypoint.new(0.48, Color3.fromRGB(238, 54, 79)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(74, 9, 18))
}, 0)
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 50)
header.Position = UDim2.new(0, 0, 0, 2)
header.BackgroundColor3 = Color3.fromRGB(9, 10, 14)
header.BackgroundTransparency = 0.12
header.BorderSizePixel = 0
header.Parent = main
local headerGradient = gradient(header, {
    ColorSequenceKeypoint.new(0, Color3.fromRGB(39, 8, 14)),
    ColorSequenceKeypoint.new(0.55, Color3.fromRGB(13, 12, 16)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 9, 12))
}, 0)
local brand = Instance.new("TextLabel")
brand.Size = UDim2.new(1, -150, 0, 21)
brand.Position = UDim2.fromOffset(14, 7)
brand.BackgroundTransparency = 1
brand.Text = __s("MAIN_BRAND")
brand.TextColor3 = Theme.text
brand.Font = Enum.Font.GothamBlack
brand.TextSize = 13
brand.TextXAlignment = Enum.TextXAlignment.Left
brand.Parent = header
local sub = Instance.new("TextLabel")
sub.Size = UDim2.new(1, -155, 0, 14)
sub.Position = UDim2.fromOffset(15, 27)
sub.BackgroundTransparency = 1
sub.Text = __s("MAIN_SUB")
sub.TextColor3 = Theme.muted
sub.Font = Enum.Font.GothamMedium
sub.TextSize = 6
sub.TextXAlignment = Enum.TextXAlignment.Left
sub.Parent = header
local versionBadge = Instance.new("TextLabel")
versionBadge.Size = UDim2.fromOffset(50, 20)
versionBadge.Position = UDim2.new(1, -110, 0, 13)
versionBadge.BackgroundColor3 = Color3.fromRGB(62, 16, 26)
versionBadge.Text = "V8.8"
versionBadge.TextColor3 = Color3.fromRGB(255, 127, 145)
versionBadge.Font = Enum.Font.GothamBold
versionBadge.TextSize = 7
versionBadge.Parent = header
round(versionBadge, 7)
stroke(versionBadge, Theme.red2, 1, 0.4)
local minBtn = Instance.new("TextButton")
minBtn.Name = "Minimize"
minBtn.Size = UDim2.fromOffset(24, 24)
minBtn.Position = UDim2.new(1, -55, 0, 12)
minBtn.BackgroundColor3 = Color3.fromRGB(28, 25, 30)
minBtn.Text = "—"
minBtn.TextColor3 = Theme.muted
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 13
minBtn.AutoButtonColor = false
minBtn.Parent = header
round(minBtn, 8)
stroke(minBtn, Theme.border, 1, 0.45)
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "Close"
closeBtn.Size = UDim2.fromOffset(24, 24)
closeBtn.Position = UDim2.new(1, -28, 0, 12)
closeBtn.BackgroundColor3 = Color3.fromRGB(64, 17, 27)
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.fromRGB(255, 113, 132)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 15
closeBtn.AutoButtonColor = false
closeBtn.Parent = header
round(closeBtn, 8)
stroke(closeBtn, Theme.red2, 1, 0.4)
local toolbar = Instance.new("Frame")
toolbar.Size = UDim2.new(1, -20, 0, 31)
toolbar.Position = UDim2.fromOffset(10, 59)
toolbar.BackgroundTransparency = 1
toolbar.Parent = main
local searchWrap = Instance.new("Frame")
searchWrap.Size = UDim2.new(1, -92, 1, 0)
searchWrap.BackgroundColor3 = Color3.fromRGB(12, 13, 18)
searchWrap.BackgroundTransparency = 0.08
searchWrap.BorderSizePixel = 0
searchWrap.Parent = toolbar
round(searchWrap, 9)
stroke(searchWrap, Theme.border, 1, 0.33)
local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -20, 1, 0)
searchBox.Position = UDim2.fromOffset(10, 0)
searchBox.BackgroundTransparency = 1
searchBox.PlaceholderText = "Search .rbxl..."
searchBox.PlaceholderColor3 = Color3.fromRGB(92, 88, 94)
searchBox.Text = ""
searchBox.TextColor3 = Theme.text
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 9
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.ClearTextOnFocus = false
searchBox.Parent = searchWrap
local scanBtn = Instance.new("TextButton")
scanBtn.Size = UDim2.fromOffset(84, 31)
scanBtn.Position = UDim2.new(1, -84, 0, 0)
scanBtn.BackgroundColor3 = Color3.fromRGB(92, 20, 33)
scanBtn.Text = "SCAN"
scanBtn.TextColor3 = Theme.text
scanBtn.Font = Enum.Font.GothamBold
scanBtn.TextSize = 9
scanBtn.AutoButtonColor = false
scanBtn.Parent = toolbar
round(scanBtn, 9)
stroke(scanBtn, Theme.red2, 1, 0.22)
gradient(scanBtn, {
    ColorSequenceKeypoint.new(0, Color3.fromRGB(121, 25, 41)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(67, 13, 24))
}, 90)
local infoBar = Instance.new("Frame")
infoBar.Size = UDim2.new(1, -20, 0, 24)
infoBar.Position = UDim2.fromOffset(10, 97)
infoBar.BackgroundColor3 = Color3.fromRGB(10, 11, 15)
infoBar.BackgroundTransparency = 0.1
infoBar.BorderSizePixel = 0
infoBar.Parent = main
round(infoBar, 8)
stroke(infoBar, Theme.border, 1, 0.58)
local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.fromOffset(6, 6)
statusDot.Position = UDim2.new(0, 10, 0.5, -3)
statusDot.BackgroundColor3 = Theme.success
statusDot.BorderSizePixel = 0
statusDot.Parent = infoBar
round(statusDot, 3)
local statusText = Instance.new("TextLabel")
statusText.Size = UDim2.new(1, -130, 1, 0)
statusText.Position = UDim2.fromOffset(24, 0)
statusText.BackgroundTransparency = 1
statusText.Text = "READY"
statusText.TextColor3 = Theme.muted
statusText.Font = Enum.Font.GothamMedium
statusText.TextSize = 7
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.TextTruncate = Enum.TextTruncate.AtEnd
statusText.Parent = infoBar
local countText = Instance.new("TextLabel")
countText.Size = UDim2.fromOffset(105, 29)
countText.Position = UDim2.new(1, -114, 0, 0)
countText.BackgroundTransparency = 1
countText.Text = "FILES 0 • IMP 0"
countText.TextColor3 = Theme.muted
countText.Font = Enum.Font.GothamBold
countText.TextSize = 7
countText.TextXAlignment = Enum.TextXAlignment.Right
countText.Parent = infoBar
local importProgressTrack = Instance.new("Frame")
importProgressTrack.Name = "ImportProgressTrack"
importProgressTrack.Size = UDim2.new(1, -20, 0, 5)
importProgressTrack.Position = UDim2.fromOffset(10, 124)
importProgressTrack.BackgroundColor3 = Color3.fromRGB(27, 20, 24)
importProgressTrack.BorderSizePixel = 0
importProgressTrack.Visible = false
importProgressTrack.Parent = main
round(importProgressTrack, 3)
local importProgressFill = Instance.new("Frame")
importProgressFill.Size = UDim2.new(0, 0, 1, 0)
importProgressFill.BackgroundColor3 = Color3.fromRGB(212, 42, 67)
importProgressFill.BorderSizePixel = 0
importProgressFill.Parent = importProgressTrack
round(importProgressFill, 3)
local importProgressPct = Instance.new("TextLabel")
importProgressPct.Size = UDim2.fromOffset(42, 13)
importProgressPct.Position = UDim2.new(1, -50, 0, 108)
importProgressPct.BackgroundTransparency = 1
importProgressPct.Text = ""
importProgressPct.TextColor3 = Color3.fromRGB(255, 108, 130)
importProgressPct.Font = Enum.Font.GothamBold
importProgressPct.TextSize = 7
importProgressPct.TextXAlignment = Enum.TextXAlignment.Right
importProgressPct.Parent = main
local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1, -20, 0, 117)
list.Position = UDim2.fromOffset(10, 133)
list.BackgroundColor3 = Color3.fromRGB(9, 10, 14)
list.BackgroundTransparency = 0.08
list.BorderSizePixel = 0
list.ScrollBarThickness = 2
list.ScrollBarImageColor3 = Theme.red2
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
list.Parent = main
round(list, 9)
stroke(list, Theme.border, 1, 0.4)
local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 7)
pad.PaddingBottom = UDim.new(0, 7)
pad.PaddingLeft = UDim.new(0, 7)
pad.PaddingRight = UDim.new(0, 7)
pad.Parent = list
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list
local empty = Instance.new("TextLabel")
empty.Size = UDim2.new(1, -14, 0, 90)
empty.BackgroundTransparency = 1
empty.Text = "NO RBXL FILES\nPRESS SCAN"
empty.TextColor3 = Theme.muted
empty.Font = Enum.Font.GothamBold
empty.TextSize = 8
empty.TextWrapped = true
empty.Parent = list
local logWrap = Instance.new("Frame")
logWrap.Size = UDim2.new(1, -20, 0, 22)
logWrap.Position = UDim2.new(0, 10, 1, -29)
logWrap.BackgroundColor3 = Color3.fromRGB(7, 8, 11)
logWrap.BackgroundTransparency = 0.06
logWrap.BorderSizePixel = 0
logWrap.Parent = main
round(logWrap, 7)
stroke(logWrap, Theme.border, 1, 0.5)
local logText = Instance.new("TextLabel")
logText.Size = UDim2.new(1, -14, 1, 0)
logText.Position = UDim2.fromOffset(7, 0)
logText.BackgroundTransparency = 1
logText.Text = "> engine ready"
logText.TextColor3 = Theme.muted
logText.Font = Enum.Font.Code
logText.TextSize = 7
logText.TextXAlignment = Enum.TextXAlignment.Left
logText.TextTruncate = Enum.TextTruncate.AtEnd
logText.Parent = logWrap
local allCards = {}
local fileCount = 0
local importedCount = 0
local mainVisible = true
local expandedPosition = main.Position
local function setStatus(text, color)
    statusText.Text = tostring(text)
    logText.Text = "> " .. tostring(text)
    statusDot.BackgroundColor3 = color or Theme.red2
end
local function setImportProgress(value, message)
    value = math.clamp(tonumber(value) or 0, 0, 1)
    importProgressTrack.Visible = value > 0
    importProgressFill.Size = UDim2.new(value, 0, 1, 0)
    importProgressPct.Text = ("%d%%"):format(math.floor(value * 100 + 0.5))
    if message and message ~= "" then
        statusText.Text = tostring(message)
        logText.Text = "> " .. tostring(message)
    end
    if value >= 1 then
        task.delay(1.8, function()
            if importProgressTrack and importProgressTrack.Parent then
                importProgressTrack.Visible = false
                importProgressPct.Text = ""
                importProgressFill.Size = UDim2.new(0, 0, 1, 0)
            end
        end)
    end
end
_G.HYAZ_IMPORT_PROGRESS_CB = setImportProgress
local function showHYAZNotification(titleText, bodyText, success)
    local okCore = pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = tostring(titleText),
            Text = tostring(bodyText),
            Duration = 6,
        })
    end)
    if okCore then return end
    local oldToast = gui:FindFirstChild(__s("TOAST"))
    if oldToast then oldToast:Destroy() end
    local toast = Instance.new("Frame")
    toast.Name = __s("TOAST")
    toast.Size = UDim2.fromOffset(255, 64)
    toast.Position = UDim2.new(1, -268, 0, 18)
    toast.BackgroundColor3 = success and Color3.fromRGB(15, 43, 32)
        or Color3.fromRGB(58, 15, 24)
    toast.BorderSizePixel = 0
    toast.ZIndex = 980
    toast.Parent = gui
    round(toast, 10)
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -18, 0, 20)
    title.Position = UDim2.fromOffset(9, 7)
    title.BackgroundTransparency = 1
    title.Text = tostring(titleText)
    title.TextColor3 = Theme.text
    title.Font = Enum.Font.GothamBold
    title.TextSize = 10
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 981
    title.Parent = toast
    local body = Instance.new("TextLabel")
    body.Size = UDim2.new(1, -18, 0, 28)
    body.Position = UDim2.fromOffset(9, 29)
    body.BackgroundTransparency = 1
    body.Text = tostring(bodyText)
    body.TextColor3 = Theme.muted
    body.Font = Enum.Font.Gotham
    body.TextSize = 8
    body.TextWrapped = true
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.ZIndex = 981
    body.Parent = toast
    task.delay(5.5, function()
        if toast and toast.Parent then toast:Destroy() end
    end)
end
local function updateCount()
    countText.Text = ("FILES %d  •  IMP %d"):format(fileCount, importedCount)
end
local function setMainVisible(visible)
    if visible == mainVisible then return end
    mainVisible = visible
    if visible then
        main.Visible = true
        shadow.Visible = true
        launcherIcon.Image = CHEVRON_RIGHT
        launcherFallback.Text = ">"
        mainScale.Scale = 0.92
        main.Position = UDim2.new(
            expandedPosition.X.Scale, expandedPosition.X.Offset - 10,
            expandedPosition.Y.Scale, expandedPosition.Y.Offset
        )
        TweenService:Create(
            mainScale,
            TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Scale = 1}
        ):Play()
        TweenService:Create(
            main,
            TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Position = expandedPosition}
        ):Play()
    else
        expandedPosition = main.Position
        launcherIcon.Image = CHEVRON_LEFT
        launcherFallback.Text = "<"
        local hideTween = TweenService:Create(
            mainScale,
            TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Scale = 0.92}
        )
        hideTween:Play()
        task.delay(0.14, function()
            if gui.Parent and not mainVisible then
                main.Visible = false
                shadow.Visible = false
                mainScale.Scale = 1
            end
        end)
    end
end
local function clearCards()
    for _, item in ipairs(allCards) do
        if item.card then item.card:Destroy() end
    end
    allCards = {}
end
local function filterCards()
    local q = searchBox.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
    for _, item in ipairs(allCards) do
        local match = q == ""
            or item.info.name:lower():find(q, 1, true)
            or item.info.path:lower():find(q, 1, true)
        item.card.Visible = match
    end
    empty.Visible = (#allCards == 0)
end
local function makeCard(info)
    empty.Visible = false
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -2, 0, 38)
    card.BackgroundColor3 = Color3.fromRGB(17, 17, 22)
    card.BackgroundTransparency = 0.04
    card.BorderSizePixel = 0
    card.Parent = list
    round(card, 8)
    stroke(card, Theme.border, 1, 0.43)
    local badge = Instance.new("TextLabel")
    badge.Size = UDim2.fromOffset(35, 15)
    badge.Position = UDim2.fromOffset(6, 6)
    badge.BackgroundColor3 = Color3.fromRGB(67, 15, 25)
    badge.Text = "RBXL"
    badge.TextColor3 = Color3.fromRGB(255, 118, 138)
    badge.Font = Enum.Font.GothamBold
    badge.TextSize = 6
    badge.Parent = card
    round(badge, 5)
    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -128, 0, 14)
    name.Position = UDim2.fromOffset(48, 4)
    name.BackgroundTransparency = 1
    name.Text = info.name
    name.TextColor3 = Theme.text
    name.Font = Enum.Font.GothamBold
    name.TextSize = 7
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.TextTruncate = Enum.TextTruncate.AtEnd
    name.Parent = card
    local path = Instance.new("TextLabel")
    path.Size = UDim2.new(1, -128, 0, 11)
    path.Position = UDim2.fromOffset(48, 21)
    path.BackgroundTransparency = 1
    path.Text = info.path
    path.TextColor3 = Theme.muted
    path.Font = Enum.Font.Gotham
    path.TextSize = 6
    path.TextXAlignment = Enum.TextXAlignment.Left
    path.TextTruncate = Enum.TextTruncate.AtEnd
    path.Parent = card
    local importBtn = Instance.new("TextButton")
    importBtn.Size = UDim2.fromOffset(70, 24)
    importBtn.Position = UDim2.new(1, -76, 0.5, -12)
    importBtn.BackgroundColor3 = Color3.fromRGB(87, 19, 31)
    importBtn.Text = "IMPORT"
    importBtn.TextColor3 = Theme.text
    importBtn.Font = Enum.Font.GothamBold
    importBtn.TextSize = 7
    importBtn.AutoButtonColor = false
    importBtn.Parent = card
    round(importBtn, 7)
    stroke(importBtn, Theme.red2, 1, 0.3)
    local importedRoot = nil
    importBtn.MouseButton1Click:Connect(function()
        if importBtn.Text == "IMPORTING" or importBtn.Text == "ACTIVATING" then
            return
        end
        if importBtn.Text == "ACTIVATE" and importedRoot then
            importBtn.Text = "ACTIVATING"
            importBtn.BackgroundColor3 = Color3.fromRGB(74, 53, 24)
            setStatus("ACTIVATING  " .. info.name, Theme.warning)
            task.spawn(function()
                local ok, message = activateImportRoot(importedRoot)
                if ok then
                    importBtn.Text = "ACTIVE"
                    importBtn.BackgroundColor3 = Color3.fromRGB(30, 82, 58)
                    setImportProgress(1.00, "RBXL GENERATION COMPLETE")
                    setStatus(message, Theme.success)
                    showHYAZNotification(
                        __s("NOTIFY"),
                        info.name .. " berhasil digenerate 100%.",
                        true
                    )
                else
                    importBtn.Text = "ACTIVATE"
                    importBtn.BackgroundColor3 = Color3.fromRGB(82, 43, 20)
                    setStatus("ACTIVATE ERROR: " .. tostring(message), Theme.danger)
                end
            end)
            return
        end
        if importBtn.Text == "ACTIVE" then
            setStatus("ALREADY ACTIVE • " .. info.name, Theme.success)
            return
        end
        importBtn.Text = "IMPORTING"
        importBtn.BackgroundColor3 = Color3.fromRGB(84, 54, 28)
        setImportProgress(0.01, "STARTING IMPORT • " .. info.name)
        setStatus("IMPORTING  " .. info.name, Theme.warning)
        task.spawn(function()
            local ok, message, root = importRBXL(info)
            if ok then
                importedCount += 1
                updateCount()
                importedRoot = root
                importBtn.Text = "ACTIVATING"
                importBtn.BackgroundColor3 = Color3.fromRGB(74, 53, 24)
                setStatus(message .. " • AUTO ACTIVATING", Theme.warning)
                local activateOK, activateMessage = activateImportRoot(importedRoot)
                if activateOK then
                    importBtn.Text = "ACTIVE"
                    importBtn.BackgroundColor3 = Color3.fromRGB(30, 82, 58)
                    setImportProgress(1.00, "RBXL GENERATION COMPLETE")
                    setStatus(activateMessage, Theme.success)
                    showHYAZNotification(
                        __s("NOTIFY"),
                        info.name .. " berhasil digenerate 100%.",
                        true
                    )
                else
                    importBtn.Text = "ACTIVATE"
                    importBtn.BackgroundColor3 = Color3.fromRGB(82, 43, 20)
                    setStatus("AUTO ACTIVATE ERROR: " .. tostring(activateMessage), Theme.danger)
                    showHYAZNotification(
                        __s("FAIL"),
                        tostring(activateMessage),
                        false
                    )
                end
            else
                importBtn.Text = "FAILED"
                importBtn.BackgroundColor3 = Color3.fromRGB(91, 26, 39)
                setStatus(message, Theme.danger)
                showHYAZNotification(
                    __s("FAIL"),
                    tostring(message),
                    false
                )
                task.wait(2.2)
                if importBtn and importBtn.Parent then
                    importBtn.Text = "IMPORT"
                    importBtn.BackgroundColor3 = Color3.fromRGB(87, 19, 31)
                end
            end
        end)
    end)
    table.insert(allCards, {info = info, card = card})
end
local function scanNow()
    scanBtn.Text = "SCANNING"
    scanBtn.BackgroundColor3 = Color3.fromRGB(82, 51, 27)
    setStatus("SCANNING WORKSPACE", Theme.warning)
    clearCards()
    fileCount = 0
    importedCount = 0
    updateCount()
    empty.Visible = true
    empty.Text = "SCANNING..."
    task.spawn(function()
        if type(listfiles) ~= "function" then
            empty.Text = "LISTFILES API NOT AVAILABLE"
            setStatus("ERROR: listfiles tidak tersedia", Theme.danger)
            scanBtn.Text = "SCAN"
            scanBtn.BackgroundColor3 = Color3.fromRGB(92, 20, 33)
            return
        end
        local ok, results = pcall(scanAllRBXL)
        if not ok then
            empty.Text = "SCAN FAILED"
            setStatus("SCAN ERROR: " .. tostring(results), Theme.danger)
            scanBtn.Text = "SCAN"
            scanBtn.BackgroundColor3 = Color3.fromRGB(92, 20, 33)
            return
        end
        for _, info in ipairs(results) do
            makeCard(info)
            task.wait()
        end
        fileCount = #results
        updateCount()
        if fileCount == 0 then
            empty.Visible = true
            empty.Text = "NO .RBXL FILES FOUND"
            setStatus("SCAN COMPLETE • 0 FILES", Theme.warning)
        else
            empty.Visible = false
            setStatus(("SCAN COMPLETE • %d RBXL"):format(fileCount), Theme.success)
        end
        scanBtn.Text = "SCAN"
        scanBtn.BackgroundColor3 = Color3.fromRGB(92, 20, 33)
        filterCards()
    end)
end
searchBox:GetPropertyChangedSignal("Text"):Connect(filterCards)
scanBtn.MouseButton1Click:Connect(scanNow)
do
    local launcherDragging = false
    local launcherMoved = false
    local launcherDragStart
    local launcherStartPos
    local launcherInput
    launcher.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            launcherDragging = true
            launcherMoved = false
            launcherDragStart = input.Position
            launcherStartPos = launcher.Position
            launcherInput = input
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    launcherDragging = false
                    if not launcherMoved then
                        setMainVisible(not mainVisible)
                    end
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not launcherDragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - launcherDragStart
            if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then
                launcherMoved = true
            end
            if launcherMoved then
                local newPos = UDim2.new(
                    launcherStartPos.X.Scale,
                    launcherStartPos.X.Offset + delta.X,
                    launcherStartPos.Y.Scale,
                    launcherStartPos.Y.Offset + delta.Y
                )
                launcher.Position = newPos
                launcherShadow.Position = UDim2.new(
                    newPos.X.Scale,
                    newPos.X.Offset - 2,
                    newPos.Y.Scale,
                    newPos.Y.Offset - 2
                )
            end
        end
    end)
end
minBtn.MouseButton1Click:Connect(function()
    setMainVisible(false)
end)
closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)
launcher.MouseEnter:Connect(function()
    TweenService:Create(
        launcher,
        TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = UDim2.fromOffset(38,38)}
    ):Play()
end)
launcher.MouseLeave:Connect(function()
    TweenService:Create(
        launcher,
        TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = UDim2.fromOffset(36,36)}
    ):Play()
end)
do
    local dragging = false
    local dragInput
    local dragStart
    local startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
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
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
            expandedPosition = main.Position
            shadow.Position = UDim2.new(
                main.Position.X.Scale,
                main.Position.X.Offset - 6,
                main.Position.Y.Scale,
                main.Position.Y.Offset - 6
            )
        end
    end)
end
setStatus("READY • PRESS SCAN", Theme.success)
updateCount()
task.delay(0.25, function()
    if gui and gui.Parent then
        scanNow()
    end
end)
print("[HYAZ] RBXL CORE V8.8 Protected Build loaded")
task.spawn(function()
    pcall(function()
        if type(hookmetamethod) ~= "function"
            or type(getnamecallmethod) ~= "function"
            or type(checkcaller) ~= "function" then
            return
        end
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            if not checkcaller() and method == "InvokeServer" then
                if self.Name == "GetScriptSourceServerFunction" then
                    local target = tostring(args[1])
                    for obj, source in pairs(_G.Hyaz_RAW_SOURCES) do
                        if typeof(obj) == "Instance"
                            and (obj.ClassName .. obj.Name) == target
                            and source and source ~= "" then
                            return source
                        end
                    end
                elseif self.Name == "SaveScriptSourceServerFunction" then
                    local target = tostring(args[1])
                    local newSource = tostring(args[2])
                    for obj in pairs(_G.Hyaz_RAW_SOURCES) do
                        if typeof(obj) == "Instance"
                            and (obj.ClassName .. obj.Name) == target then
                            _G.Hyaz_RAW_SOURCES[obj] = newSource
                            break
                        end
                    end
                end
            end
            return oldNamecall(self, ...)
        end)
    end)
end)
setStatus("READY  •  PRESS SCAN RBXL", Theme.success)
updateCount()
task.delay(0.25, function()
    if gui and gui.Parent then
        scanNow()
    end
end)
print("[HYAZ] RBXL CORE V2 STABILITY loaded")
