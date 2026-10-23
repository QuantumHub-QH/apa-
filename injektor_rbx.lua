-- =======================================================
-- BLUExCrown ENGINE v5.1 - FULL STUDIO LITE SCRIPT FIX
-- MENU: Splash | TOOLBOX ASSET | INSERT RBXM
-- Fix: Binary RBXM Parser + Script Source Injector + Studio Lite Hooks
-- Solves: "Not found." error when opening scripts in Studio Lite
-- Design: Strictly Black & White Modern Landscape
-- Toggle Asset ID: 102337382069600
-- =======================================================

local HttpService        = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local CoreGui            = game:GetService("CoreGui")
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local RunService         = game:GetService("RunService")
local InsertService      = game:GetService("InsertService")

local LP = Players.LocalPlayer
local ParentGui = (gethui and gethui()) or CoreGui or LP:WaitForChild("PlayerGui")

local httpRequest  = request or http_request or (syn and syn.request) or (http and http.request)
local clipFn       = setclipboard or toclipboard or (Clipboard and Clipboard.set)
local customAsset  = getcustomasset or getsynasset or nil
local listfilesFn  = listfiles or nil

if not httpRequest then
    warn("[BLUExCrown] Executor tidak support HTTP!")
    return
end

-- Storage global untuk source code script yang di-import
_G.BLUE_RAW_SOURCES = _G.BLUE_RAW_SOURCES or {}

-- =====================================================
-- STUDIO LITE INTEGRATION & SERVER HOOKS
-- =====================================================
local slFolder    = ReplicatedStorage:FindFirstChild("StudioLiteFolder")
local serverFuncs = slFolder and slFolder:FindFirstChild("ServerFunctions")

local function triggerServerLoad(idStr)
    if not serverFuncs or not idStr or idStr == "" then return end
    local id = tostring(idStr):match("%d+")
    if id and tonumber(id) and tonumber(id) > 0 then
        pcall(function()
            serverFuncs:InvokeServer("LoadMeshToRuntimeMeshes", tonumber(id))
        end)
    end
end

-- =====================================================
-- RBXM BINARY PARSER (LZ4 + ZSTD + Property Extractor)
-- Membaca source code asli dari file .rbxm tanpa "Not found"
-- =====================================================
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
        fmt = fmt or "I1"; local chunk = self:read(string.packsize(fmt), shift); return string.unpack(fmt, chunk)
    end
    function Stream:append(s) self.Source = self.Source .. s; self.Length = #self.Source end
    function Stream:toEnd() self.Offset = self.Length end
    return Stream
end

local function transformInt(x) return (x % 2 == 0) and (x / 2) or (-(x + 1) / 2) end
local function rbxF32(x) x = bit32.rrotate(x, 1); return string.unpack(">f", string.pack(">I4", x)) end

local basicTypes = {}
function basicTypes.String(buf) return buf:read(buf:readNumber("<I4")) end
function basicTypes.Int32(buf) return transformInt(buf:readNumber(">I4")) end
function basicTypes.Int64(buf) return transformInt(buf:readNumber(">I8")) end
function basicTypes.Float32(buf) return rbxF32(buf:readNumber(">I4")) end
function basicTypes.Float64(buf) return buf:readNumber("<d") end

function basicTypes.InterleaveArrayWithSize(buf, count, sizeof)
    if count < 0 then return Buffer("", false) end
    local stream = buf:read(count * sizeof); local out = table.create(count)
    for i = 1, count do
        local chunk = table.create(sizeof)
        for s = 0, sizeof - 1 do
            local bitPos = i + (count * s); chunk[s+1] = string.sub(stream, bitPos, bitPos)
        end
        out[i] = table.concat(chunk)
    end
    return Buffer(table.concat(out), false)
end

function basicTypes.unsignedIntArray(buf, count)
    if count < 1 then return {} end
    local o = table.create(count); local strings = basicTypes.InterleaveArrayWithSize(buf, count, 4)
    for i = 1, count do o[i] = strings:readNumber("<I4") end
    return o
end

function basicTypes.Int32Array(buf, count)
    if count < 1 then return {} end
    local o = table.create(count); local strings = basicTypes.InterleaveArrayWithSize(buf, count, 4)
    for i = 1, count do o[i] = basicTypes.Int32(strings) end
    return o
end

function basicTypes.Int64Array(buf, count)
    if count < 1 then return {} end
    local o = table.create(count); local strings = basicTypes.InterleaveArrayWithSize(buf, count, 8)
    for i = 1, count do o[i] = basicTypes.Int64(strings) end
    return o
end

function basicTypes.RbxF32Array(buf, count)
    if count < 1 then return {} end
    local o = table.create(count); local strings = basicTypes.InterleaveArrayWithSize(buf, count, 4)
    for i = 1, count do o[i] = basicTypes.Float32(strings) end
    return o
end

function basicTypes.RefArray(buf, count)
    if count < 1 then return {} end
    local o = table.create(count); local refs = basicTypes.Int32Array(buf, count); local last = 0
    for i = 1, count do local ref = last + refs[i]; o[i] = ref; last = ref end
    return o
end

local function lz4(lz4data)
    local inputStream = Buffer(lz4data)
    local compressedLen = string.unpack("<I4", inputStream:read(4))
    local decompressedLen = string.unpack("<I4", inputStream:read(4))
    local reserved = string.unpack("<I4", inputStream:read(4))
    if reserved ~= 0 then error("not lz4") end
    if compressedLen == 0 then return inputStream:read(decompressedLen) end
    local outputStream = Buffer("")
    repeat
        local token = string.byte(inputStream:read())
        local litLen = bit32.rshift(token, 4)
        local matLen = bit32.band(token, 15) + 4
        if litLen >= 15 then
            repeat local nextByte = string.byte(inputStream:read()); litLen = litLen + nextByte until nextByte ~= 0xFF
        end
        local literal = inputStream:read(litLen); outputStream:append(literal); outputStream:toEnd()
        if outputStream.Length < decompressedLen then
            local offset = string.unpack("<I2", inputStream:read(2))
            if matLen >= 19 then
                repeat local nextByte = string.byte(inputStream:read()); matLen = matLen + nextByte until nextByte ~= 0xFF
            end
            outputStream:seek(-offset)
            local pos = outputStream.Offset; local match = outputStream:read(matLen)
            local unreadBytes = outputStream.LastUnreadBytes or 0
            local extra
            if unreadBytes then
                repeat
                    outputStream.Offset = pos; extra = outputStream:read(unreadBytes)
                    unreadBytes = outputStream.LastUnreadBytes or 0; match = match .. extra
                until unreadBytes <= 0
            end
            outputStream:append(match); outputStream:toEnd()
        end
    until outputStream.Length >= decompressedLen
    return outputStream.Source
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

local function zstd(stream)
    local zbase64 = b64encode(stream)
    local json = '{"m":null,"t":"buffer","zbase64":"' .. zbase64 .. '"}'
    local x = HttpService:JSONDecode(json)
    return buffer.tostring(x)
end

local function parseRBXMForSources(data)
    local sources = {}
    local rbxmBuffer = Buffer(data, false)
    if rbxmBuffer:read(8) ~= "<roblox!" or rbxmBuffer:read(6) ~= string.char(137,255,13,10,26,10) then return sources, "Invalid header" end
    if rbxmBuffer:read(2) ~= (string.char(0)..string.char(0)) then return sources, "Invalid version" end
    local classCount = rbxmBuffer:readNumber("<i4")
    local instCount  = rbxmBuffer:readNumber("<i4")
    local classRefs, virtualInstances, strings, chunkInfo = {}, {}, {}, {}
    local _EC = "END"..string.char(0)
    local valid = {[_EC]=true, ["INST"]=true, ["META"]=true, ["PRNT"]=true, ["PROP"]=true, ["SIGN"]=true, ["SSTR"]=true}
    for k in pairs(valid) do chunkInfo[k] = {} end
    if rbxmBuffer:read(8) ~= string.char(0,0,0,0,0,0,0,0) then return sources, "Invalid header" end

    local index, last_chunk = 0, nil
    repeat
        index = index + 1
        local chunk = {InternalID = index, Header = rbxmBuffer:read(4)}
        if not valid[chunk.Header] then return sources, "Invalid chunk" end
        local lz4Header = rbxmBuffer:read(16, false)
        local compressed = string.unpack("<I4", string.sub(lz4Header, 1, 4))
        local decompressed = string.unpack("<I4", string.sub(lz4Header, 5, 8))
        local reserved = string.sub(lz4Header, 9, 12)
        local zstd_check = string.sub(lz4Header, 13, 16)
        local dataChunk
        if compressed == 0 then
            dataChunk = rbxmBuffer:read(decompressed + 12)
        else
            if zstd_check == string.char(40,181,47,253) then rbxmBuffer:seek(12); dataChunk = zstd(rbxmBuffer:read(compressed))
            else dataChunk = lz4(rbxmBuffer:read(compressed + 12)) end
        end
        chunk.Data = Buffer(dataChunk, false); table.insert(chunkInfo[chunk.Header], chunk); last_chunk = chunk
    until last_chunk and last_chunk.Header == _EC

    for _, chunk in ipairs(chunkInfo["SSTR"] or {}) do
        local buf = chunk.Data
        if buf:readNumber("<I4") == 0 then
            for i = 1, buf:readNumber("<I4") do buf:read(16); strings[i] = basicTypes.String(buf) end
        end
    end

    for _, chunk in ipairs(chunkInfo["INST"] or {}) do
        local buf = chunk.Data
        local classID = buf:readNumber("<I4"); local className = basicTypes.String(buf)
        if buf:read() == "\1" then return sources, "Contains services" end
        local count = buf:readNumber("<I4"); local refs = basicTypes.RefArray(buf, count)
        classRefs[classID] = { Name = className, Sizeof = count, Refs = refs }
        for _, ref in ipairs(refs) do virtualInstances[ref] = { ClassId = classID, ClassName = className, Ref = ref, Properties = {}, Children = {} } end
    end

    for _, chunk in ipairs(chunkInfo["PROP"] or {}) do
        local buf = chunk.Data
        local classID = buf:readNumber("<I4"); local classref = classRefs[classID]
        if not classref then return sources, "Missing classref" end
        local refs = classref.Refs; local sizeof = classref.Sizeof; local name = basicTypes.String(buf)
        if string.byte(buf:read(1, false)) == 0x1E then buf:seek(1) end
        local typeID = string.byte(buf:read()); local props = {}
        if typeID == 0x01 or typeID == 0x1D then
            for i = 1, sizeof do props[i] = basicTypes.String(buf) end
        elseif typeID == 0x02 then
            for i = 1, sizeof do props[i] = buf:read() ~= string.char(0) end
        elseif typeID == 0x03 then props = basicTypes.Int32Array(buf, sizeof)
        elseif typeID == 0x04 then props = basicTypes.RbxF32Array(buf, sizeof)
        elseif typeID == 0x05 then
            for i = 1, sizeof do props[i] = basicTypes.Float64(buf) end
        else
            for i = 1, sizeof do
                if typeID == 0x13 then props = basicTypes.RefArray(buf, sizeof); break else buf:read(4) end
            end
        end
        if name == "Source" or name == "ContentText" then
            for i, v in ipairs(refs) do
                if virtualInstances[v] and props[i] then virtualInstances[v].Properties[name] = props[i] end
            end
        end
    end

    local function buildSourceMap(node, path)
        local src = node.Properties["Source"] or node.Properties["ContentText"]
        if src and type(src) == "string" and #src > 0 then sources[path] = src end
        for _, child in ipairs(node.Children or {}) do
            buildSourceMap(child, path .. "." .. child.ClassName .. ":" .. (child.Properties["Name"] or "unnamed"))
        end
    end

    for _, chunk in ipairs(chunkInfo["PRNT"] or {}) do
        local buf = chunk.Data
        if buf:read() ~= string.char(0) then return sources, "Invalid PRNT" end
        local count = buf:readNumber("<I4")
        local child_refs = basicTypes.RefArray(buf, count); local parent_refs = basicTypes.RefArray(buf, count)
        for i = 1, count do
            local child  = virtualInstances[child_refs[i]]; local parent = virtualInstances[parent_refs[i]]
            if child and parent then table.insert(parent.Children, child) end
        end
    end

    local roots = {}
    for _, inst in pairs(virtualInstances) do
        local hasParent = false
        for _, other in pairs(virtualInstances) do
            for _, child in ipairs(other.Children or {}) do if child.Ref == inst.Ref then hasParent = true; break end end
            if hasParent then break end
        end
        if not hasParent then table.insert(roots, inst) end
    end
    for _, root in ipairs(roots) do buildSourceMap(root, root.ClassName .. ":" .. (root.Properties["Name"] or "root")) end

    return sources, nil
end

-- =====================================================
-- STUDIO LITE SCRIPT UI INJECTOR
-- =====================================================
local SL_CACHE = {}

local function injectStudioLiteUI(scr, sourceMap)
    if not scr:IsA("LuaSourceContainer") then return end
    local path = scr.ClassName .. ":" .. scr.Name
    local realSource = sourceMap and (sourceMap[path] or sourceMap[scr.Name])
    
    if not realSource and sourceMap then
        for k, v in pairs(sourceMap) do
            if k:find(scr.Name, 1, true) then
                realSource = v
                break
            end
        end
    end

    if not realSource then
        pcall(function() realSource = scr.Source end)
    end

    if realSource and #realSource > 0 then
        local _nullpat = string.char(0)
        realSource = realSource:gsub(_nullpat .. "*$", "")
    else
        realSource = "-- [BLUExCrown] Source code belum dimuat."
    end

    _G.BLUE_RAW_SOURCES[scr] = realSource

    local UI_TEXT = realSource
    if #UI_TEXT > 150000 then
        UI_TEXT = "-- [BLUExCrown Warning] Source terlalu panjang.\n\n" .. string.sub(UI_TEXT, 1, 150000) .. "\n\n... [TERPOTONG]"
    end

    local existingTB = scr:FindFirstChild("SL_CodeTextBox")
    if existingTB then
        existingTB.Text = UI_TEXT
        if scr.ClassName == "ModuleScript" then
            local ro = scr:FindFirstChild("SL_1ReadOnly")
            if ro then ro.ContentText = UI_TEXT; ro.Text = UI_TEXT end
        end
        return
    end

    if not serverFuncs then return end
    local map = { Script = "InsertScriptScript", LocalScript = "InsertLocalScriptLocalScript", ModuleScript = "InsertModuleScriptModuleScript" }
    local assetName = map[scr.ClassName]
    if not assetName then return end

    if not SL_CACHE[assetName] then
        pcall(function()
            serverFuncs:InvokeServer("LoadAssetToPlayerGui", assetName)
            local guiF = LP:WaitForChild("PlayerGui"):WaitForChild(assetName, 3)
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
    for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("LuaSourceContainer") then table.insert(list, d) end
    end
    local count = 0
    for _, s in ipairs(list) do
        pcall(injectStudioLiteUI, s, sourceMap)
        count = count + 1
        task.wait(0.01)
    end
    return count
end

local function applyStudioLiteProps(obj)
    if not obj then return end
    pcall(function()
        if obj:IsA("BasePart") then
            local origAnchor  = obj.Anchored
            local origCollide = obj.CanCollide
            obj.Anchored = true
            if obj:GetAttribute("SL_Anchored") == nil then obj:SetAttribute("SL_Anchored", origAnchor) end
            if obj:GetAttribute("SL_CanCollide") == nil then obj:SetAttribute("SL_CanCollide", origCollide) end
        end
    end)
    for _, child in ipairs(obj:GetChildren()) do applyStudioLiteProps(child) end
end

local function loadAssetsToSLServer(obj)
    local function scan(node)
        pcall(function()
            if node:IsA("MeshPart") then
                triggerServerLoad(node.MeshId); triggerServerLoad(node.TextureID)
            elseif node:IsA("Decal") or node:IsA("Texture") then
                triggerServerLoad(node.Texture)
            elseif node:IsA("SpecialMesh") then
                triggerServerLoad(node.MeshId); triggerServerLoad(node.TextureId)
            elseif node:IsA("Clothing") or node:IsA("ShirtGraphic") then
                triggerServerLoad(node.ClassName == "ShirtGraphic" and node.Graphic or node[node.ClassName.."Template"])
            elseif node:IsA("UnionOperation") or node:IsA("PartOperation") then
                triggerServerLoad(node.AssetId)
            end
        end)
        for _, child in ipairs(node:GetChildren()) do scan(child) end
    end
    scan(obj)
end

-- =====================================================
-- HOOKS: CEGAH STUDIO LITE MENGELUARKAN "NOT FOUND"
-- =====================================================
task.spawn(function()
    if hookmetamethod then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            local args = {...}

            if not checkcaller() and method == "InvokeServer" then
                if self.Name == "GetScriptSourceServerFunction" then
                    local target = tostring(args[1])
                    for obj, src in pairs(_G.BLUE_RAW_SOURCES) do
                        if typeof(obj) == "Instance" and (obj.ClassName .. obj.Name == target or obj.Name == target) then
                            if src and src ~= "" then return src end
                        end
                    end
                    for _, place in ipairs({workspace, ReplicatedStorage, LP:FindFirstChild("PlayerGui"), LP:FindFirstChild("Backpack")}) do
                        if place then
                            for _, obj in ipairs(place:GetDescendants()) do
                                if obj:IsA("LuaSourceContainer") and (obj.ClassName .. obj.Name == target or obj.Name == target) then
                                    local src = _G.BLUE_RAW_SOURCES[obj]
                                    if src and src ~= "" then return src end
                                end
                            end
                        end
                    end
                end

                if self.Name == "SaveScriptSourceServerFunction" then
                    local target = tostring(args[1])
                    local newSource = tostring(args[2])
                    for obj, _ in pairs(_G.BLUE_RAW_SOURCES) do
                        if typeof(obj) == "Instance" and (obj.ClassName .. obj.Name == target or obj.Name == target) then
                            _G.BLUE_RAW_SOURCES[obj] = newSource
                            break
                        end
                    end
                end
            end
            return oldNamecall(self, ...)
        end)
    end

    if hookfunction then
        local oldRequire
        oldRequire = hookfunction(getrenv().require or require, function(module)
            if typeof(module) == "Instance" and module:IsA("ModuleScript") then
                local src = _G.BLUE_RAW_SOURCES[module]
                if src and src ~= "" then
                    local func, err = loadstring(src)
                    if func then
                        local success, result = pcall(func)
                        if success then return result end
                    end
                end
            end
            return oldRequire(module)
        end)

        local oldGetObjects
        oldGetObjects = hookfunction(game.GetObjects, function(self, url, ...)
            local assetId = tostring(url):match("%d+")
            if assetId then triggerServerLoad(assetId) end
            local objects = oldGetObjects(self, url, ...)
            if objects then
                for _, obj in ipairs(objects) do
                    pcall(function() injectAllScripts(obj, {}) end)
                    pcall(function() applyStudioLiteProps(obj) end)
                    pcall(function() loadAssetsToSLServer(obj) end)
                end
            end
            return objects
        end)
    end
end)

-- =====================================================
-- DESTROY OLD UI
-- =====================================================
if ParentGui:FindFirstChild("BLUExCrownV5") then
    ParentGui.BLUExCrownV5:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BLUExCrownV5"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = ParentGui

-- ===================== HELPERS =====================
local function makeCorner(parent, radius)
    local c = Instance.new("UICorner", parent)
    c.CornerRadius = UDim.new(0, radius or 8)
    return c
end

local function makeStroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke", parent)
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Color = color or Color3.fromRGB(255,255,255)
    s.Thickness = thickness or 1.2
    s.Transparency = transparency or 0
    return s
end

local tweenQuick  = TweenInfo.new(0.18, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local tweenBounce = TweenInfo.new(0.22, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)

-- ===================== TOGGLE BUTTON =====================
local ToggleBtn = Instance.new("ImageButton")
ToggleBtn.Size = UDim2.new(0, 42, 0, 42)
ToggleBtn.Position = UDim2.new(0.02, 0, 0.45, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(14, 14, 16)
ToggleBtn.Image = "rbxassetid://102337382069600"
ToggleBtn.ScaleType = Enum.ScaleType.Fit
ToggleBtn.Parent = ScreenGui
makeCorner(ToggleBtn, 8)
makeStroke(ToggleBtn, Color3.fromRGB(255,255,255), 1.4)

-- ===================== MAIN WINDOW =====================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.fromScale(0.5, 0.5)
MainFrame.Size = UDim2.new(0, 640, 0, 360)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
makeCorner(MainFrame, 10)
makeStroke(MainFrame, Color3.fromRGB(255,255,255), 1.4)

-- TOP BAR
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, -12, 0, 30)
TopBar.Position = UDim2.new(0, 6, 0, 6)
TopBar.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame
makeCorner(TopBar, 7)
makeStroke(TopBar, Color3.fromRGB(255,255,255), 1, 0.75)

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size = UDim2.new(1, -50, 1, 0)
TitleLbl.Position = UDim2.new(0, 12, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text = "BLUExCrown ENGINE v5.1"
TitleLbl.Font = Enum.Font.GothamBold
TitleLbl.TextSize = 11
TitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TitleLbl.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 22, 0, 22)
CloseBtn.Position = UDim2.new(1, -26, 0, 4)
CloseBtn.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 10
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Parent = TopBar
makeCorner(CloseBtn, 6)
makeStroke(CloseBtn, Color3.fromRGB(255,255,255), 1, 0.55)

-- CONTENT AREA
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -12, 1, -46)
Content.Position = UDim2.new(0, 6, 0, 40)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

-- PAGE CONTAINER
local PageSplash  = Instance.new("Frame")
local PageToolbox = Instance.new("Frame")
local PageRBXM    = Instance.new("Frame")

for _, pg in ipairs({PageSplash, PageToolbox, PageRBXM}) do
    pg.Size = UDim2.fromScale(1, 1)
    pg.BackgroundTransparency = 1
    pg.Visible = false
    pg.Parent = Content
end
PageSplash.Visible = true

-- =====================================================
-- PAGE 1: SPLASH SCREEN (HOME)
-- =====================================================
local ProfileCard = Instance.new("Frame")
ProfileCard.Size = UDim2.new(0, 175, 1, 0)
ProfileCard.BackgroundColor3 = Color3.fromRGB(17, 17, 22)
ProfileCard.BorderSizePixel = 0
ProfileCard.Parent = PageSplash
makeCorner(ProfileCard, 8)
makeStroke(ProfileCard, Color3.fromRGB(255,255,255), 1, 0.75)

local AvatarImg = Instance.new("ImageLabel")
AvatarImg.Size = UDim2.new(0, 70, 0, 70)
AvatarImg.AnchorPoint = Vector2.new(0.5, 0)
AvatarImg.Position = UDim2.new(0.5, 0, 0, 14)
AvatarImg.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
AvatarImg.Image = ""
AvatarImg.Parent = ProfileCard
makeCorner(AvatarImg, 35)
makeStroke(AvatarImg, Color3.fromRGB(255,255,255), 1.5, 0.5)

local DispName = Instance.new("TextLabel")
DispName.Size = UDim2.new(1, -16, 0, 20)
DispName.Position = UDim2.new(0, 8, 0, 90)
DispName.BackgroundTransparency = 1
DispName.Text = "Loading..."
DispName.Font = Enum.Font.GothamBold
DispName.TextSize = 13
DispName.TextColor3 = Color3.fromRGB(255, 255, 255)
DispName.TextXAlignment = Enum.TextXAlignment.Center
DispName.TextTruncate = Enum.TextTruncate.AtEnd
DispName.Parent = ProfileCard

local UsernLabel = Instance.new("TextLabel")
UsernLabel.Size = UDim2.new(1, -16, 0, 16)
UsernLabel.Position = UDim2.new(0, 8, 0, 112)
UsernLabel.BackgroundTransparency = 1
UsernLabel.Text = "@..."
UsernLabel.Font = Enum.Font.Gotham
UsernLabel.TextSize = 10
UsernLabel.TextColor3 = Color3.fromRGB(160, 160, 170)
UsernLabel.TextXAlignment = Enum.TextXAlignment.Center
UsernLabel.Parent = ProfileCard

local SepLine = Instance.new("Frame")
SepLine.Size = UDim2.new(1, -20, 0, 1)
SepLine.Position = UDim2.new(0, 10, 0, 136)
SepLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SepLine.BackgroundTransparency = 0.85
SepLine.BorderSizePixel = 0
SepLine.Parent = ProfileCard

local SLStatusLbl = Instance.new("TextLabel")
SLStatusLbl.Size = UDim2.new(1, -16, 0, 14)
SLStatusLbl.Position = UDim2.new(0, 8, 0, 144)
SLStatusLbl.BackgroundTransparency = 1
SLStatusLbl.Text = serverFuncs and "[OK] Studio Lite Hook Active" or "[!] Studio Lite: Standalone"
SLStatusLbl.Font = Enum.Font.Gotham
SLStatusLbl.TextSize = 8
SLStatusLbl.TextColor3 = serverFuncs and Color3.fromRGB(120, 220, 120) or Color3.fromRGB(220, 120, 120)
SLStatusLbl.TextXAlignment = Enum.TextXAlignment.Center
SLStatusLbl.TextWrapped = true
SLStatusLbl.Parent = ProfileCard

local StatsLbl = Instance.new("TextLabel")
StatsLbl.Size = UDim2.new(1, -16, 1, -168)
StatsLbl.Position = UDim2.new(0, 8, 0, 162)
StatsLbl.BackgroundTransparency = 1
StatsLbl.Text = "UserID: "..tostring(LP.UserId).."\nBLUExCrown ENGINE\nv5.1 — Delta Mobile"
StatsLbl.Font = Enum.Font.Gotham
StatsLbl.TextSize = 9
StatsLbl.TextColor3 = Color3.fromRGB(130, 130, 140)
StatsLbl.TextXAlignment = Enum.TextXAlignment.Center
StatsLbl.TextWrapped = true
StatsLbl.Parent = ProfileCard

local MenuArea = Instance.new("Frame")
MenuArea.Size = UDim2.new(1, -183, 1, 0)
MenuArea.Position = UDim2.new(0, 183, 0, 0)
MenuArea.BackgroundTransparency = 1
MenuArea.Parent = PageSplash

local MenuTitle = Instance.new("TextLabel")
MenuTitle.Size = UDim2.new(1, 0, 0, 24)
MenuTitle.BackgroundTransparency = 1
MenuTitle.Text = "PILIH MENU"
MenuTitle.Font = Enum.Font.GothamBold
MenuTitle.TextSize = 10
MenuTitle.TextColor3 = Color3.fromRGB(180, 180, 190)
MenuTitle.TextXAlignment = Enum.TextXAlignment.Left
MenuTitle.Parent = MenuArea

local CardToolbox = makeMenuCard(MenuArea, 28,  "[T]", "TOOLBOX ASET",     "Cari & insert model dari Creator Store")
local CardRBXM    = makeMenuCard(MenuArea, 108, "[R]", "INSERT RBXM FILE", "Scan & insert file .rbxm dengan Source Script")

-- =====================================================
-- PAGE 2: TOOLBOX ASSET
-- =====================================================
local TbHeader = Instance.new("Frame")
TbHeader.Size = UDim2.new(1, 0, 0, 28)
TbHeader.BackgroundTransparency = 1
TbHeader.Parent = PageToolbox
local TbTitleLbl = Instance.new("TextLabel")
TbTitleLbl.Size = UDim2.new(1, -80, 1, 0)
TbTitleLbl.BackgroundTransparency = 1
TbTitleLbl.Text = "TOOLBOX ASET"
TbTitleLbl.Font = Enum.Font.GothamBold
TbTitleLbl.TextSize = 11
TbTitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
TbTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TbTitleLbl.Parent = TbHeader
local TbBack = makeBackBtn(TbHeader)

local TbContent = Instance.new("Frame")
TbContent.Size = UDim2.new(1, 0, 1, -34)
TbContent.Position = UDim2.new(0, 0, 0, 34)
TbContent.BackgroundTransparency = 1
TbContent.Parent = PageToolbox

local TbLeft = Instance.new("Frame")
TbLeft.Size = UDim2.new(0, 220, 1, 0)
TbLeft.BackgroundTransparency = 1
TbLeft.Parent = TbContent

local TbSearchSec = Instance.new("Frame")
TbSearchSec.Size = UDim2.new(1, 0, 0, 118)
TbSearchSec.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
TbSearchSec.Parent = TbLeft
makeCorner(TbSearchSec, 8)
makeStroke(TbSearchSec, Color3.fromRGB(255,255,255), 1, 0.78)

local TbIdBox = Instance.new("TextBox")
TbIdBox.Size = UDim2.new(1, -70, 0, 24)
TbIdBox.Position = UDim2.new(0, 6, 0, 8)
TbIdBox.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
TbIdBox.PlaceholderText = "Asset ID langsung..."
TbIdBox.PlaceholderColor3 = Color3.fromRGB(110, 110, 120)
TbIdBox.Text = ""
TbIdBox.Font = Enum.Font.Gotham
TbIdBox.TextSize = 10
TbIdBox.TextColor3 = Color3.fromRGB(255, 255, 255)
TbIdBox.ClearTextOnFocus = false
TbIdBox.Parent = TbSearchSec
makeCorner(TbIdBox, 5)

local TbInsertIdBtn = Instance.new("TextButton")
TbInsertIdBtn.Size = UDim2.new(0, 54, 0, 24)
TbInsertIdBtn.Position = UDim2.new(1, -60, 0, 8)
TbInsertIdBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TbInsertIdBtn.Text = "INSERT"
TbInsertIdBtn.Font = Enum.Font.GothamBold
TbInsertIdBtn.TextSize = 9
TbInsertIdBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
TbInsertIdBtn.Parent = TbSearchSec
makeCorner(TbInsertIdBtn, 5)

local TbSearchBox = Instance.new("TextBox")
TbSearchBox.Size = UDim2.new(1, -70, 0, 24)
TbSearchBox.Position = UDim2.new(0, 6, 0, 36)
TbSearchBox.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
TbSearchBox.PlaceholderText = "Cari kata kunci..."
TbSearchBox.PlaceholderColor3 = Color3.fromRGB(110, 110, 120)
TbSearchBox.Text = ""
TbSearchBox.Font = Enum.Font.Gotham
TbSearchBox.TextSize = 10
TbSearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
TbSearchBox.ClearTextOnFocus = false
TbSearchBox.Parent = TbSearchSec
makeCorner(TbSearchBox, 5)

local TbSearchBtn = Instance.new("TextButton")
TbSearchBtn.Size = UDim2.new(0, 54, 0, 24)
TbSearchBtn.Position = UDim2.new(1, -60, 0, 36)
TbSearchBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TbSearchBtn.Text = "CARI"
TbSearchBtn.Font = Enum.Font.GothamBold
TbSearchBtn.TextSize = 9
TbSearchBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
TbSearchBtn.Parent = TbSearchSec
makeCorner(TbSearchBtn, 5)

local selectedCat = 10
local catBtns = {}
local cats = {{n="MODEL",id=10},{n="DECAL",id=13},{n="AUDIO",id=3},{n="MESH",id=11}}
local TbCatRow = Instance.new("Frame")
TbCatRow.Size = UDim2.new(1, -12, 0, 20)
TbCatRow.Position = UDim2.new(0, 6, 0, 65)
TbCatRow.BackgroundTransparency = 1
TbCatRow.Parent = TbSearchSec
local catUL = Instance.new("UIListLayout")
catUL.FillDirection = Enum.FillDirection.Horizontal
catUL.Padding = UDim.new(0, 4)
catUL.Parent = TbCatRow

local function updateCatTabs()
    for id, btn in pairs(catBtns) do
        if id == selectedCat then
            btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            btn.TextColor3 = Color3.fromRGB(0, 0, 0)
        else
            btn.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
            btn.TextColor3 = Color3.fromRGB(160, 160, 170)
        end
    end
end

for _, c in ipairs(cats) do
    local cb = Instance.new("TextButton")
    cb.Size = UDim2.new(0.25, -3, 1, 0)
    cb.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
    cb.Text = c.n; cb.Font = Enum.Font.GothamBold; cb.TextSize = 8
    cb.TextColor3 = Color3.fromRGB(160, 160, 170)
    cb.Parent = TbCatRow
    makeCorner(cb, 4); makeStroke(cb, Color3.fromRGB(255,255,255), 1, 0.82)
    catBtns[c.id] = cb
    cb.MouseButton1Click:Connect(function() selectedCat = c.id; updateCatTabs() end)
end
updateCatTabs()

local TbStatusLbl = Instance.new("TextLabel")
TbStatusLbl.Size = UDim2.new(1, -12, 0, 16)
TbStatusLbl.Position = UDim2.new(0, 6, 0, 90)
TbStatusLbl.BackgroundTransparency = 1
TbStatusLbl.Text = "[.] Siap"
TbStatusLbl.Font = Enum.Font.Gotham; TbStatusLbl.TextSize = 9
TbStatusLbl.TextColor3 = Color3.fromRGB(140, 140, 150)
TbStatusLbl.TextXAlignment = Enum.TextXAlignment.Left
TbStatusLbl.Parent = TbSearchSec

local TbDetailBox = Instance.new("Frame")
TbDetailBox.Size = UDim2.new(1, 0, 1, -124)
TbDetailBox.Position = UDim2.new(0, 0, 0, 124)
TbDetailBox.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
TbDetailBox.Parent = TbLeft
makeCorner(TbDetailBox, 8); makeStroke(TbDetailBox, Color3.fromRGB(255,255,255), 1, 0.78)

local TbDetTitleLbl = Instance.new("TextLabel")
TbDetTitleLbl.Size = UDim2.new(1, -12, 0, 18); TbDetTitleLbl.Position = UDim2.new(0, 8, 0, 4)
TbDetTitleLbl.BackgroundTransparency = 1; TbDetTitleLbl.Text = "DETAIL ASSET"
TbDetTitleLbl.Font = Enum.Font.GothamBold; TbDetTitleLbl.TextSize = 9
TbDetTitleLbl.TextColor3 = Color3.fromRGB(200, 200, 210)
TbDetTitleLbl.TextXAlignment = Enum.TextXAlignment.Left; TbDetTitleLbl.Parent = TbDetailBox

local TbDetThumb = Instance.new("ImageLabel")
TbDetThumb.Size = UDim2.new(0, 52, 0, 52); TbDetThumb.Position = UDim2.new(0, 8, 0, 24)
TbDetThumb.BackgroundColor3 = Color3.fromRGB(26, 26, 30); TbDetThumb.Image = ""
TbDetThumb.Parent = TbDetailBox; makeCorner(TbDetThumb, 6); makeStroke(TbDetThumb, Color3.fromRGB(255,255,255), 1, 0.82)

local TbDetName = Instance.new("TextLabel")
TbDetName.Size = UDim2.new(1, -70, 0, 26); TbDetName.Position = UDim2.new(0, 66, 0, 22)
TbDetName.BackgroundTransparency = 1; TbDetName.Text = "Pilih aset dari grid"
TbDetName.Font = Enum.Font.GothamBold; TbDetName.TextSize = 10
TbDetName.TextColor3 = Color3.fromRGB(255, 255, 255)
TbDetName.TextXAlignment = Enum.TextXAlignment.Left; TbDetName.TextWrapped = true; TbDetName.Parent = TbDetailBox

local TbDetCreator = Instance.new("TextLabel")
TbDetCreator.Size = UDim2.new(1, -70, 0, 14); TbDetCreator.Position = UDim2.new(0, 66, 0, 46)
TbDetCreator.BackgroundTransparency = 1; TbDetCreator.Text = "By: -"
TbDetCreator.Font = Enum.Font.Gotham; TbDetCreator.TextSize = 8
TbDetCreator.TextColor3 = Color3.fromRGB(150, 150, 160)
TbDetCreator.TextXAlignment = Enum.TextXAlignment.Left; TbDetCreator.Parent = TbDetailBox

local TbDetId = Instance.new("TextLabel")
TbDetId.Size = UDim2.new(1, -70, 0, 14); TbDetId.Position = UDim2.new(0, 66, 0, 60)
TbDetId.BackgroundTransparency = 1; TbDetId.Text = "ID: -"
TbDetId.Font = Enum.Font.Gotham; TbDetId.TextSize = 8
TbDetId.TextColor3 = Color3.fromRGB(150, 150, 160)
TbDetId.TextXAlignment = Enum.TextXAlignment.Left; TbDetId.Parent = TbDetailBox

local currentInspId = ""
local TbDetRow = Instance.new("Frame")
TbDetRow.Size = UDim2.new(1, -16, 0, 26); TbDetRow.Position = UDim2.new(0, 8, 1, -32)
TbDetRow.BackgroundTransparency = 1; TbDetRow.Parent = TbDetailBox

local TbDetInsert = Instance.new("TextButton")
TbDetInsert.Size = UDim2.new(0.5, -3, 1, 0); TbDetInsert.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TbDetInsert.Text = "INSERT"; TbDetInsert.Font = Enum.Font.GothamBold; TbDetInsert.TextSize = 9
TbDetInsert.TextColor3 = Color3.fromRGB(0, 0, 0); TbDetInsert.Parent = TbDetRow; makeCorner(TbDetInsert, 5)

local TbDetCopy = Instance.new("TextButton")
TbDetCopy.Size = UDim2.new(0.5, -3, 1, 0); TbDetCopy.Position = UDim2.new(0.5, 3, 0, 0)
TbDetCopy.BackgroundColor3 = Color3.fromRGB(255, 255, 255); TbDetCopy.Text = "COPY ID"
TbDetCopy.Font = Enum.Font.GothamBold; TbDetCopy.TextSize = 9
TbDetCopy.TextColor3 = Color3.fromRGB(0, 0, 0); TbDetCopy.Parent = TbDetRow; makeCorner(TbDetCopy, 5)

local TbRight = Instance.new("Frame")
TbRight.Size = UDim2.new(1, -228, 1, 0); TbRight.Position = UDim2.new(0, 228, 0, 0)
TbRight.BackgroundColor3 = Color3.fromRGB(18, 18, 22); TbRight.Parent = TbContent
makeCorner(TbRight, 8); makeStroke(TbRight, Color3.fromRGB(255,255,255), 1, 0.78)

local TbBrowserLbl = Instance.new("TextLabel")
TbBrowserLbl.Size = UDim2.new(1, -16, 0, 24); TbBrowserLbl.Position = UDim2.new(0, 8, 0, 4)
TbBrowserLbl.BackgroundTransparency = 1; TbBrowserLbl.Text = "ASSET BROWSER"
TbBrowserLbl.Font = Enum.Font.GothamBold; TbBrowserLbl.TextSize = 10
TbBrowserLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
TbBrowserLbl.TextXAlignment = Enum.TextXAlignment.Left; TbBrowserLbl.Parent = TbRight

local TbGridScroll = Instance.new("ScrollingFrame")
TbGridScroll.Size = UDim2.new(1, -12, 1, -34); TbGridScroll.Position = UDim2.new(0, 6, 0, 28)
TbGridScroll.BackgroundTransparency = 1; TbGridScroll.ScrollBarThickness = 3
TbGridScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255); TbGridScroll.Parent = TbRight

local TbGrid = Instance.new("UIGridLayout")
TbGrid.CellSize = UDim2.new(0, 104, 0, 115); TbGrid.CellPadding = UDim2.new(0, 6, 0, 6)
TbGrid.SortOrder = Enum.SortOrder.LayoutOrder; TbGrid.Parent = TbGridScroll

local TbGridStatus = Instance.new("TextLabel")
TbGridStatus.Size = UDim2.new(1, 0, 0, 40); TbGridStatus.BackgroundTransparency = 1
TbGridStatus.Text = "Ketik kata kunci & klik CARI"
TbGridStatus.Font = Enum.Font.Gotham; TbGridStatus.TextSize = 10
TbGridStatus.TextColor3 = Color3.fromRGB(140, 140, 150); TbGridStatus.Parent = TbGridScroll

-- =====================================================
-- PAGE 3: INSERT RBXM FILE
-- =====================================================
local RbxmHeader = Instance.new("Frame")
RbxmHeader.Size = UDim2.new(1, 0, 0, 28); RbxmHeader.BackgroundTransparency = 1; RbxmHeader.Parent = PageRBXM
local RbxmTitleLbl = Instance.new("TextLabel")
RbxmTitleLbl.Size = UDim2.new(1, -80, 1, 0); RbxmTitleLbl.BackgroundTransparency = 1
RbxmTitleLbl.Text = "INSERT RBXM FILE"; RbxmTitleLbl.Font = Enum.Font.GothamBold; RbxmTitleLbl.TextSize = 11
RbxmTitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
RbxmTitleLbl.TextXAlignment = Enum.TextXAlignment.Left; RbxmTitleLbl.Parent = RbxmHeader
local RbxmBack = makeBackBtn(RbxmHeader)

local RbxmToolbar = Instance.new("Frame")
RbxmToolbar.Size = UDim2.new(1, 0, 0, 28); RbxmToolbar.Position = UDim2.new(0, 0, 0, 32)
RbxmToolbar.BackgroundTransparency = 1; RbxmToolbar.Parent = PageRBXM

local RbxmScanBtn = Instance.new("TextButton")
RbxmScanBtn.Size = UDim2.new(0, 90, 0, 24); RbxmScanBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
RbxmScanBtn.Text = "SCAN FILES"; RbxmScanBtn.Font = Enum.Font.GothamBold; RbxmScanBtn.TextSize = 10
RbxmScanBtn.TextColor3 = Color3.fromRGB(0, 0, 0); RbxmScanBtn.Parent = RbxmToolbar; makeCorner(RbxmScanBtn, 6)

local RbxmSLStatus = Instance.new("TextLabel")
RbxmSLStatus.Size = UDim2.new(0, 120, 1, 0); RbxmSLStatus.Position = UDim2.new(0, 96, 0, 0)
RbxmSLStatus.BackgroundTransparency = 1
RbxmSLStatus.Text = serverFuncs and "[HOOK: ACTIVE]" or "[STANDALONE]"
RbxmSLStatus.Font = Enum.Font.GothamBold; RbxmSLStatus.TextSize = 9
RbxmSLStatus.TextColor3 = serverFuncs and Color3.fromRGB(120, 220, 120) or Color3.fromRGB(220, 120, 120)
RbxmSLStatus.TextXAlignment = Enum.TextXAlignment.Left; RbxmSLStatus.Parent = RbxmToolbar

local RbxmCountLbl = Instance.new("TextLabel")
RbxmCountLbl.Size = UDim2.new(1, -230, 1, 0); RbxmCountLbl.Position = UDim2.new(0, 220, 0, 0)
RbxmCountLbl.BackgroundTransparency = 1
RbxmCountLbl.Text = "[.] Klik SCAN untuk mencari file .rbxm"
RbxmCountLbl.Font = Enum.Font.Gotham; RbxmCountLbl.TextSize = 9
RbxmCountLbl.TextColor3 = Color3.fromRGB(140, 140, 150)
RbxmCountLbl.TextXAlignment = Enum.TextXAlignment.Left; RbxmCountLbl.Parent = RbxmToolbar

local RbxmScroll = Instance.new("ScrollingFrame")
RbxmScroll.Size = UDim2.new(1, -12, 1, -66); RbxmScroll.Position = UDim2.new(0, 6, 0, 62)
RbxmScroll.BackgroundColor3 = Color3.fromRGB(17, 17, 22); RbxmScroll.BorderSizePixel = 0
RbxmScroll.ScrollBarThickness = 3; RbxmScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
RbxmScroll.Parent = PageRBXM; makeCorner(RbxmScroll, 8); makeStroke(RbxmScroll, Color3.fromRGB(255,255,255), 1, 0.78)

local RbxmList = Instance.new("UIListLayout")
RbxmList.Padding = UDim.new(0, 5); RbxmList.SortOrder = Enum.SortOrder.LayoutOrder; RbxmList.Parent = RbxmScroll
local RbxmPad = Instance.new("UIPadding")
RbxmPad.PaddingTop = UDim.new(0, 6); RbxmPad.PaddingLeft = UDim.new(0, 6); RbxmPad.PaddingRight = UDim.new(0, 6); RbxmPad.Parent = RbxmScroll

local RbxmEmpty = Instance.new("TextLabel")
RbxmEmpty.Size = UDim2.new(1, 0, 0, 40); RbxmEmpty.BackgroundTransparency = 1
RbxmEmpty.Text = "Belum ada file .rbxm ditemukan. Klik SCAN FILES."
RbxmEmpty.Font = Enum.Font.Gotham; RbxmEmpty.TextSize = 10
RbxmEmpty.TextColor3 = Color3.fromRGB(140, 140, 150); RbxmEmpty.Parent = RbxmScroll

-- =====================================================
-- LOGIC: DRAGGABLE & TOGGLE
-- =====================================================
local function makeDraggable(frame, handle)
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end
makeDraggable(MainFrame, TopBar)
makeDraggable(ToggleBtn, ToggleBtn)

local isOpen = true
local function toggleWindow()
    isOpen = not isOpen
    if isOpen then
        MainFrame.Visible = true
        MainFrame.Size = UDim2.new(0, 618, 0, 348)
        TweenService:Create(MainFrame, tweenBounce, {Size = UDim2.new(0, 640, 0, 360)}):Play()
    else
        local tw = TweenService:Create(MainFrame, tweenQuick, {Size = UDim2.new(0, 610, 0, 340)})
        tw:Play()
        tw.Completed:Connect(function() if not isOpen then MainFrame.Visible = false end end)
    end
end
ToggleBtn.MouseButton1Click:Connect(toggleWindow)
CloseBtn.MouseButton1Click:Connect(toggleWindow)

local function showPage(target)
    PageSplash.Visible = false; PageToolbox.Visible = false; PageRBXM.Visible = false
    target.Visible = true
end
CardToolbox.MouseButton1Click:Connect(function() showPage(PageToolbox) end)
CardRBXM.MouseButton1Click:Connect(function() showPage(PageRBXM) end)
TbBack.MouseButton1Click:Connect(function() showPage(PageSplash) end)
RbxmBack.MouseButton1Click:Connect(function() showPage(PageSplash) end)

-- =====================================================
-- LOGIC: SMART INSERT ASSET ID
-- =====================================================
local function smartInsert(assetId)
    local numId = tonumber(assetId)
    if not numId then return false, "ID tidak valid" end
    if clipFn then pcall(clipFn, tostring(numId)) end
    local insertOk, method = false, ""

    pcall(function()
        local objs = game:GetObjects("rbxassetid://"..tostring(numId))
        if objs and #objs > 0 then
            for _, o in ipairs(objs) do
                o.Parent = workspace
                applyStudioLiteProps(o)
                loadAssetsToSLServer(o)
                injectAllScripts(o, {})
                if o:IsA("Model") and LP.Character then
                    local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then pcall(function() o:MoveTo(hrp.Position + hrp.CFrame.LookVector * 7) end) end
                end
            end
            insertOk = true; method = "GetObjects + SL Props"
        end
    end)

    if serverFuncs then
        pcall(function()
            serverFuncs:InvokeServer("LoadMeshToRuntimeMeshes", numId)
            if not insertOk then insertOk = true; method = "SL ServerFunctions"
            else method = method .. " + SL Server" end
        end)
    end

    return insertOk, (method ~= "" and method or "ID Disalin ke Clipboard")
end

-- =====================================================
-- LOGIC: SMART INSERT RBXM DENGAN SOURCE CODE INJECTION
-- =====================================================
local SCAN_PATHS = {
    "workspace",
    "Delta/workspace",
    "delta/workspace",
    "Android/Delta/workspace",
    "/sdcard/Delta/workspace",
    "../workspace",
    "."
}

local function safeReadFile(p)
    if not readfile then return nil end
    local ok, d = pcall(readfile, p)
    return ok and d or nil
end

local function smartInsertRbxm(filePath, fileName)
    local insertOk, statusMsg = false, ""
    local data = safeReadFile(filePath)
    local sourceMap = {}

    if data and #data > 0 then
        local okParse, sources = pcall(parseRBXMForSources, data)
        if okParse and sources then
            sourceMap = sources
        end
    end

    local function setupObjects(objs)
        for _, o in ipairs(objs) do
            o.Parent = workspace
            applyStudioLiteProps(o)
            loadAssetsToSLServer(o)
            injectAllScripts(o, sourceMap)
            if o:IsA("Model") and LP.Character then
                local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
                if hrp then pcall(function() o:MoveTo(hrp.Position + hrp.CFrame.LookVector * 6) end) end
            end
        end
    end

    if customAsset then
        pcall(function()
            local url = customAsset(filePath)
            if url then
                local objs = game:GetObjects(url)
                if objs and #objs > 0 then
                    setupObjects(objs)
                    insertOk = true; statusMsg = "customAsset + Source OK"
                end
            end
        end)
    end

    if not insertOk then
        pcall(function()
            local objs = game:GetObjects("rbxasset://" .. filePath)
            if objs and #objs > 0 then
                setupObjects(objs)
                insertOk = true; statusMsg = "rbxasset:// + Source OK"
            end
        end)
    end

    if not insertOk and data and writefile and customAsset then
        pcall(function()
            local tmpName = "bce_tmp_" .. fileName
            writefile(tmpName, data)
            local url2 = customAsset(tmpName)
            if url2 then
                local objs2 = game:GetObjects(url2)
                if objs2 and #objs2 > 0 then
                    setupObjects(objs2)
                    insertOk = true; statusMsg = "readfile+tmp + Source OK"
                end
            end
            pcall(function() if delfile then delfile(tmpName) end end)
        end)
    end

    return insertOk, statusMsg
end

local function safeListFiles(p)
    if not listfilesFn then return nil end
    local ok, f = pcall(listfilesFn, p); return ok and f or nil
end
local function getFileName(p) return p:match("([^/\\]+)$") or p end

local function getAllRbxmFiles()
    local result, seen = {}, {}
    if not listfilesFn then return result end
    local function scanDeep(folder, depth)
        if depth > 4 or seen[folder] then return end
        seen[folder] = true
        local files = safeListFiles(folder)
        if not files then return end
        for _, path in ipairs(files) do
            local lp = path:lower()
            if (lp:sub(-5) == ".rbxm" or lp:sub(-6) == ".rbxmx") and not seen[path] then
                seen[path] = true; table.insert(result, {path=path, name=getFileName(path)})
            elseif not path:lower():match("%.[%a%d]+$") then
                scanDeep(path, depth + 1)
            end
        end
    end
    for _, p in ipairs(SCAN_PATHS) do if safeListFiles(p) then scanDeep(p, 0) end end
    return result
end

local function renderRbxmCards()
    for _, c in ipairs(RbxmScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    RbxmCountLbl.Text = "[.] Scanning..."
    local files = getAllRbxmFiles()
    RbxmEmpty.Visible = (#files == 0)
    if #files == 0 then
        RbxmCountLbl.Text = not listfilesFn and "[!] listfiles() tidak support" or "[!] Tidak ada file .rbxm di workspace"
        return
    end
    RbxmCountLbl.Text = string.format("[OK] %d file ditemukan", #files)
    for _, file in ipairs(files) do
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -12, 0, 50); card.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        card.BorderSizePixel = 0; card.Parent = RbxmScroll; makeCorner(card, 7); makeStroke(card, Color3.fromRGB(255,255,255), 1, 0.85)

        local fileIcon = Instance.new("TextLabel")
        fileIcon.Size = UDim2.new(0, 36, 0, 36); fileIcon.Position = UDim2.new(0, 5, 0.5, -18)
        fileIcon.BackgroundColor3 = Color3.fromRGB(28, 28, 34); fileIcon.Text = ".rbxm"
        fileIcon.Font = Enum.Font.GothamBold; fileIcon.TextSize = 7
        fileIcon.TextColor3 = Color3.fromRGB(200, 200, 210); fileIcon.Parent = card; makeCorner(fileIcon, 6)

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(1, -145, 0, 18); nameLbl.Position = UDim2.new(0, 48, 0, 7)
        nameLbl.BackgroundTransparency = 1; nameLbl.Text = file.name
        nameLbl.Font = Enum.Font.GothamBold; nameLbl.TextSize = 11
        nameLbl.TextColor3 = Color3.fromRGB(240, 240, 245)
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left; nameLbl.TextTruncate = Enum.TextTruncate.AtEnd; nameLbl.Parent = card

        local pathLbl = Instance.new("TextLabel")
        pathLbl.Size = UDim2.new(1, -145, 0, 13); pathLbl.Position = UDim2.new(0, 48, 0, 28)
        pathLbl.BackgroundTransparency = 1; pathLbl.Text = file.path
        pathLbl.Font = Enum.Font.Gotham; pathLbl.TextSize = 8
        pathLbl.TextColor3 = Color3.fromRGB(130, 130, 140)
        pathLbl.TextXAlignment = Enum.TextXAlignment.Left; pathLbl.TextTruncate = Enum.TextTruncate.AtEnd; pathLbl.Parent = card

        local insertBtn = Instance.new("TextButton")
        insertBtn.Size = UDim2.new(0, 70, 0, 30); insertBtn.Position = UDim2.new(1, -76, 0.5, -15)
        insertBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255); insertBtn.Text = "INSERT"
        insertBtn.Font = Enum.Font.GothamBold; insertBtn.TextSize = 9
        insertBtn.TextColor3 = Color3.fromRGB(0, 0, 0); insertBtn.Parent = card; makeCorner(insertBtn, 6)

        insertBtn.MouseButton1Click:Connect(function()
            if insertBtn.Text == "..." then return end
            insertBtn.Text = "..."
            task.spawn(function()
                local ok, msg = smartInsertRbxm(file.path, file.name)
                if insertBtn and insertBtn.Parent then
                    if ok then
                        insertBtn.Text = "OK!"; insertBtn.BackgroundColor3 = Color3.fromRGB(180, 255, 180)
                        RbxmCountLbl.Text = "[OK] "..file.name.." ("..msg..")"
                    else
                        insertBtn.Text = "GAGAL"; insertBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 180)
                        RbxmCountLbl.Text = "[!] Gagal load RBXM"
                    end
                    task.delay(2.5, function()
                        if insertBtn and insertBtn.Parent then
                            insertBtn.Text = "INSERT"; insertBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        end
                    end)
                end
            end)
        end)
    end
    RbxmScroll.CanvasSize = UDim2.new(0, 0, 0, RbxmList.AbsoluteContentSize.Y + 20)
end
RbxmScanBtn.MouseButton1Click:Connect(renderRbxmCards)

local function inspectAsset(id, name, creator)
    currentInspId = tostring(id)
    TbDetThumb.Image = "rbxthumb://type=Asset&id="..currentInspId.."&w=150&h=150"
    TbDetName.Text = name or "Memuat..."; TbDetCreator.Text = "By: @"..(creator or "?"); TbDetId.Text = "ID: "..currentInspId
    local num = tonumber(currentInspId)
    if num and num > 0 then
        task.spawn(function()
            local s, info = pcall(function() return MarketplaceService:GetProductInfo(num) end)
            if s and info and info.Name and TbDetName and TbDetName.Parent then
                TbDetName.Text = info.Name
                TbDetCreator.Text = "By: @"..((info.Creator and info.Creator.Name) or creator or "?")
            end
        end)
    end
end

TbDetCopy.MouseButton1Click:Connect(function()
    if currentInspId ~= "" and clipFn then
        pcall(clipFn, currentInspId); TbDetCopy.Text = "COPIED!"
        task.delay(1.2, function() if TbDetCopy and TbDetCopy.Parent then TbDetCopy.Text = "COPY ID" end end)
    end
end)

TbDetInsert.MouseButton1Click:Connect(function()
    if currentInspId ~= "" then
        TbDetInsert.Text = "..."
        task.spawn(function()
            local ok, m = smartInsert(currentInspId)
            TbStatusLbl.Text = "[.] "..m
            if TbDetInsert and TbDetInsert.Parent then
                TbDetInsert.Text = ok and "OK!" or "COPIED"
                task.delay(1.5, function() if TbDetInsert and TbDetInsert.Parent then TbDetInsert.Text = "INSERT" end end)
            end
        end)
    end
end)

local function queryMarketplace(catId, query)
    local enc = HttpService:UrlEncode(query)
    local urls = {
        ("https://apis.roproxy.com/toolbox-service/v1/marketplace/%d?keyword=%s&limit=30"):format(catId, enc),
        ("https://apis.roblox.com/toolbox-service/v1/marketplace/%d?keyword=%s&limit=30"):format(catId, enc),
    }
    for _, url in ipairs(urls) do
        local s, r = pcall(function() return httpRequest({Url=url,Method="GET",Headers={["User-Agent"]="RobloxStudio/WinInet"}}) end)
        if s and r and r.StatusCode == 200 then
            local ds, parsed = pcall(function() return HttpService:JSONDecode(r.Body) end)
            if ds and parsed and parsed.data and #parsed.data > 0 then return parsed.data end
        end
    end
    return nil
end

local function renderGrid(data)
    for _, c in ipairs(TbGridScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    if not data or #data == 0 then TbGridStatus.Visible = true; TbGridStatus.Text = "Tidak ada aset ditemukan."; return end
    TbGridStatus.Visible = false
    local first = data[1]
    if first then inspectAsset(first.id or (first.asset and first.asset.id) or "0", first.name or (first.asset and first.asset.name) or "Asset", (first.creator and first.creator.name) or "?") end
    for _, item in ipairs(data) do
        local assetId = tostring(item.id or (item.asset and item.asset.id) or "0")
        local assetName = item.name or (item.asset and item.asset.name) or "Asset"
        local creator = (item.creator and item.creator.name) or "?"
        local card = Instance.new("Frame")
        card.BackgroundColor3 = Color3.fromRGB(22, 22, 27); card.BorderSizePixel = 0; card.Parent = TbGridScroll
        makeCorner(card, 6); makeStroke(card, Color3.fromRGB(255,255,255), 1, 0.88)
        local thumb = Instance.new("ImageLabel")
        thumb.Size = UDim2.new(1, -8, 0, 50); thumb.Position = UDim2.new(0, 4, 0, 4)
        thumb.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
        thumb.Image = "rbxthumb://type=Asset&id="..assetId.."&w=150&h=150"; thumb.Parent = card; makeCorner(thumb, 5)
        local nameL = Instance.new("TextLabel")
        nameL.Size = UDim2.new(1, -8, 0, 14); nameL.Position = UDim2.new(0, 4, 0, 56)
        nameL.BackgroundTransparency = 1; nameL.Text = assetName
        nameL.Font = Enum.Font.GothamBold; nameL.TextSize = 8; nameL.TextColor3 = Color3.fromRGB(240, 240, 240)
        nameL.TextXAlignment = Enum.TextXAlignment.Left; nameL.TextTruncate = Enum.TextTruncate.AtEnd; nameL.Parent = card
        local subL = Instance.new("TextLabel")
        subL.Size = UDim2.new(1, -8, 0, 12); subL.Position = UDim2.new(0, 4, 0, 70)
        subL.BackgroundTransparency = 1; subL.Text = "@"..creator
        subL.Font = Enum.Font.Gotham; subL.TextSize = 7; subL.TextColor3 = Color3.fromRGB(140, 140, 150)
        subL.TextXAlignment = Enum.TextXAlignment.Left; subL.TextTruncate = Enum.TextTruncate.AtEnd; subL.Parent = card
        local btnRow = Instance.new("Frame")
        btnRow.Size = UDim2.new(1, -8, 0, 17); btnRow.Position = UDim2.new(0, 4, 1, -21); btnRow.BackgroundTransparency = 1; btnRow.Parent = card
        local iBtn = Instance.new("TextButton")
        iBtn.Size = UDim2.new(0.5, -2, 1, 0); iBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        iBtn.Text = "INSERT"; iBtn.Font = Enum.Font.GothamBold; iBtn.TextSize = 8
        iBtn.TextColor3 = Color3.fromRGB(0, 0, 0); iBtn.Parent = btnRow; makeCorner(iBtn, 4)
        local cBtn = Instance.new("TextButton")
        cBtn.Size = UDim2.new(0.5, -2, 1, 0); cBtn.Position = UDim2.new(0.5, 2, 0, 0)
        cBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255); cBtn.Text = "COPY"
        cBtn.Font = Enum.Font.GothamBold; cBtn.TextSize = 8
        cBtn.TextColor3 = Color3.fromRGB(0, 0, 0); cBtn.Parent = btnRow; makeCorner(cBtn, 4)
        cBtn.MouseButton1Click:Connect(function()
            if clipFn then pcall(clipFn, assetId); cBtn.Text = "OK!"
                task.delay(1.2, function() if cBtn and cBtn.Parent then cBtn.Text = "COPY" end end) end
        end)
        iBtn.MouseButton1Click:Connect(function()
            iBtn.Text = "..."; TbStatusLbl.Text = "[.] Inserting "..assetId
            task.spawn(function()
                local ok, m = smartInsert(assetId); TbStatusLbl.Text = "[.] "..m
                if iBtn and iBtn.Parent then
                    iBtn.Text = ok and "OK!" or "COPY"
                    task.delay(1.2, function() if iBtn and iBtn.Parent then iBtn.Text = "INSERT" end end)
                end
            end)
        end)
        local hitbox = Instance.new("TextButton")
        hitbox.Size = UDim2.new(1, 0, 0, 86); hitbox.BackgroundTransparency = 1; hitbox.Text = ""; hitbox.Parent = card
        hitbox.MouseButton1Click:Connect(function() inspectAsset(assetId, nameL.Text, creator) end)
        task.spawn(function()
            local num = tonumber(assetId); if not num then return end
            local s, info = pcall(function() return MarketplaceService:GetProductInfo(num) end)
            if s and info and info.Name and nameL and nameL.Parent then
                nameL.Text = info.Name; subL.Text = "@"..((info.Creator and info.Creator.Name) or creator)
            end
        end)
    end
    TbGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TbGridScroll.CanvasSize = UDim2.new(0, 0, 0, TbGrid.AbsoluteContentSize.Y + 10)
    end)
    TbGridScroll.CanvasSize = UDim2.new(0, 0, 0, TbGrid.AbsoluteContentSize.Y + 10)
end

local function execSearch()
    if TbSearchBox.Text ~= "" then
        TbGridStatus.Visible = true; TbGridStatus.Text = "Searching..."
        TbStatusLbl.Text = "[.] Mencari: "..TbSearchBox.Text
        task.spawn(function()
            local data = queryMarketplace(selectedCat, TbSearchBox.Text)
            renderGrid(data); TbStatusLbl.Text = "[.] Selesai"
        end)
    end
end
TbSearchBtn.MouseButton1Click:Connect(execSearch)
TbSearchBox.FocusLost:Connect(function(enter) if enter then execSearch() end end)

TbInsertIdBtn.MouseButton1Click:Connect(function()
    local id = TbIdBox.Text:gsub("%D+", "")
    if id ~= "" then
        inspectAsset(id, "Memuat...", "?"); TbInsertIdBtn.Text = "..."
        task.spawn(function()
            local ok, m = smartInsert(id); TbStatusLbl.Text = "[.] "..m
            if TbInsertIdBtn and TbInsertIdBtn.Parent then
                TbInsertIdBtn.Text = ok and "OK!" or "COPIED"
                task.delay(1.5, function() if TbInsertIdBtn and TbInsertIdBtn.Parent then TbInsertIdBtn.Text = "INSERT" end end)
            end
        end)
    end
end)

task.spawn(function()
    DispName.Text = LP.DisplayName or LP.Name
    UsernLabel.Text = "@"..LP.Name
    pcall(function()
        local url = ("https://thumbnails.roproxy.com/v1/users/avatar-headshot?userIds=%d&size=150x150&format=Png&isCircular=false"):format(LP.UserId)
        local res = httpRequest({Url=url,Method="GET",Headers={["User-Agent"]="RobloxStudio/WinInet"}})
        if res and res.StatusCode == 200 then
            local data = HttpService:JSONDecode(res.Body)
            if data and data.data and data.data[1] and data.data[1].imageUrl then
                AvatarImg.Image = data.data[1].imageUrl
            end
        end
    end)
    task.wait(3)
    local slFolder2 = ReplicatedStorage:FindFirstChild("StudioLiteFolder")
    local serverFuncs2 = slFolder2 and slFolder2:FindFirstChild("ServerFunctions")
    if serverFuncs2 and not serverFuncs then
        serverFuncs = serverFuncs2
        SLStatusLbl.Text = "[OK] Studio Lite Hook Active"; SLStatusLbl.TextColor3 = Color3.fromRGB(120, 220, 120)
        RbxmSLStatus.Text = "[HOOK: ACTIVE]"; RbxmSLStatus.TextColor3 = Color3.fromRGB(120, 220, 120)
    end
end)

print("[BLUExCrown] ENGINE v5.1 SCRIPT FIX LOADED")
