--[[
                                                                            
       LANGZ IMPORTER v62.0 - Dynamic Animated Gradient & Vector Icons     
       Features: Real-time UI Animations, Verified Asset Mapping            
       Supports: RBXM, RBXL, RBXLX, RBXMX                                   
       [PATCHED VERSION: RBXL Script Extraction Enabled]
                                                                            
]]

if not game:IsLoaded() then game.Loaded:Wait() end

--                                                                        
-- WHITELIST GATE   LANGZ PAID SCRIPT
--                                                                        
local _WHITELIST = {
    -- Masukkan UserId yang boleh akses di sini
    10955292268,
    -- 987654321,
}

local _userId = game:GetService("Players").LocalPlayer.UserId
local _allowed = false
for _, id in ipairs(_WHITELIST) do
    if id == _userId then _allowed = true; break end
end

if not _allowed then
    warn(string.char(104,97,118,101,32,121,111,117,32,116,114,105,101,100,32,111,112,101,110,105)..string.char(110,103,32,116,104,105,115,32,115,99,114,105,112,116,32,105,116,39,115,32)..string.char(110,111,116,32,101,97,115,121,32,109,121,32,102,114,105,101,110,100,32,240)..string.char(159,152,136,240,159,152,136,240,159,152,136,240,159,152,136))
    warn(string.char(75,65,76,79,32,75,65,76,73,65,78,32,77,65,85,32,66,69,76,73)..string.char(32,73,77,80,79,82,84,32,82,66,88,77,32,78,89,65,32,76,65,78)..string.char(71,83,85,78,71,32,65,74,65,32,72,85,66,85,78,71,73,32,76,65)..string.char(78,71,90,32,68,73,32,78,79,77,79,82,32,73,78,73,44,32,48,56)..string.char(56,49,48,50,50,57,52,55,50,51,50,32,75,73,78,71,32,76,65,78)..string.char(71,90,32,240,159,145,145))
    return
end


--                                                                        
-- SERVICES & UTILITIES
--                                                                        
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local InsertService = game:GetService("InsertService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local CoreDest = pcall(function() return CoreGui.Name end) and CoreGui or LocalPlayer:WaitForChild("PlayerGui")

_G.LANGZ_RAW_SOURCES = _G.LANGZ_RAW_SOURCES or {}

-- Pemetaan Icon Vektor Lucide (High Resolution & Clean Vector Mask)
local ICONS = {
    PACKAGE        = "rbxassetid://10709791437",
    SEARCH         = "rbxassetid://10709796118",
    CLOSE          = "rbxassetid://10709790644",
    MINIMIZE       = "rbxassetid://10709790387",
    CHEVRON_RIGHT  = "rbxassetid://10709782525",
    CHEVRON_LEFT   = "rbxassetid://10709782230",
    BELL           = "rbxassetid://10709791160",
    GAMEPAD        = "rbxassetid://10709790082",
    FILE           = "rbxassetid://10709790948",
    DOWNLOAD       = "rbxassetid://10709791283",
    CHECK          = "rbxassetid://10709790240",
    ALERT          = "rbxassetid://10709790520",
    FOLDER         = "rbxassetid://10709790172",
    REFRESH        = "rbxassetid://10709793382"
}

--                                                                        
-- HTTP REQUEST UTILITY
--                                                                        
local function httpRequest(url, method, headers, data)
    method = method or "GET"
    headers = headers or {}
    headers["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"

    local requestFuncs = {
        function() if syn and syn.request then local r = syn.request({Url = url, Method = method, Headers = headers, Body = data}); return r.Body, r.StatusCode end end,
        function() if request then local r = request({Url = url, Method = method, Headers = headers, Body = data}); return r.Body, r.StatusCode end end,
        function() if http_request then local r = http_request({Url = url, Method = method, Headers = headers, Body = data}); return r.Body, r.StatusCode end end,
        function() if fluxus and fluxus.request then local r = fluxus.request({Url = url, Method = method, Headers = headers, Body = data}); return r.Body, r.StatusCode end end,
        function() return game:HttpGet(url, true), 200 end
    }
    for _, fn in ipairs(requestFuncs) do
        local ok, body, status = pcall(fn)
        if ok and body and type(body) == "string" and #body > 0 then
            return body, status or 200
        end
    end
    return nil, nil
end

--                                                                        
-- RBXM FILE PARSER (LZ4 + Binary Format)
--                                                                        
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
    local instCount = rbxmBuffer:readNumber("<i4")
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
        local buffer = chunk.Data
        if buffer:readNumber("<I4") == 0 then
            for i = 1, buffer:readNumber("<I4") do buffer:read(16); strings[i] = basicTypes.String(buffer) end
        end
    end

    for _, chunk in ipairs(chunkInfo["INST"] or {}) do
        local buffer = chunk.Data
        local classID = buffer:readNumber("<I4"); 
        local className = basicTypes.String(buffer)
        
        -- DI-PATCH: Mengizinkan file berisi "Services" (RBXL) agar tetap di-parse
        local isService = buffer:read() == "\1"
        
        local count = buffer:readNumber("<I4"); 
        local refs = basicTypes.RefArray(buffer, count)
        classRefs[classID] = { Name = className, Sizeof = count, Refs = refs }
        for _, ref in ipairs(refs) do virtualInstances[ref] = { ClassId = classID, ClassName = className, Ref = ref, Properties = {}, Children = {} } end
    end

    for _, chunk in ipairs(chunkInfo["PROP"] or {}) do
        local buffer = chunk.Data
        local classID = buffer:readNumber("<I4"); local classref = classRefs[classID]
        if not classref then return sources, "Missing classref" end
        local refs = classref.Refs; local sizeof = classref.Sizeof; local name = basicTypes.String(buffer)
        if string.byte(buffer:read(1, false)) == 0x1E then buffer:seek(1) end
        local typeID = string.byte(buffer:read()); local props = {}
        if typeID == 0x01 or typeID == 0x1D then
            for i = 1, sizeof do props[i] = basicTypes.String(buffer) end
        elseif typeID == 0x02 then
            for i = 1, sizeof do props[i] = buffer:read() ~= string.char(0) end
        elseif typeID == 0x03 then props = basicTypes.Int32Array(buffer, sizeof)
        elseif typeID == 0x04 then props = basicTypes.RbxF32Array(buffer, sizeof)
        elseif typeID == 0x05 then
            for i = 1, sizeof do props[i] = basicTypes.Float64(buffer) end
        else
            for i = 1, sizeof do
                if typeID == 0x13 then props = basicTypes.RefArray(buffer, sizeof); break else buffer:read(4) end
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
        for _, child in ipairs(node.Children or {}) do buildSourceMap(child, path .. "." .. child.ClassName .. ":" .. (child.Properties["Name"] or "unnamed")) end
    end

    for _, chunk in ipairs(chunkInfo["PRNT"] or {}) do
        local buffer = chunk.Data
        if buffer:read() ~= string.char(0) then return sources, "Invalid PRNT" end
        local count = buffer:readNumber("<I4")
        local child_refs = basicTypes.RefArray(buffer, count); local parent_refs = basicTypes.RefArray(buffer, count)
        for i = 1, count do
            local child = virtualInstances[child_refs[i]]; local parent = virtualInstances[parent_refs[i]]
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

--                                                                        
-- STUDIO LITE INTEGRATION
--                                                                        
local slFolder = ReplicatedStorage:FindFirstChild("StudioLiteFolder")
local serverFuncs = slFolder and slFolder:FindFirstChild("ServerFunctions")

local function triggerServerLoad(idStr)
    if not serverFuncs or not idStr or idStr == "" then return end
    local id = tostring(idStr):match("%d+")
    if id then pcall(function() serverFuncs:InvokeServer("LoadMeshToRuntimeMeshes", tonumber(id)) end) end
end

local SL_CACHE = {}
local function injectStudioLiteUI(scr, sourceMap)
    if not scr:IsA("LuaSourceContainer") then return end
    local path = scr.ClassName .. ":" .. scr.Name
    local realSource = sourceMap and sourceMap[path]
    if not realSource then pcall(function() realSource = scr.Source end) end
    if realSource and #realSource > 0 then local _nullpat = string.char(0); realSource = realSource:gsub(_nullpat .. "*$", "") else realSource = "-- [LANGZ] Source tidak ditemukan." end

    _G.LANGZ_RAW_SOURCES[scr] = realSource

    local UI_TEXT = realSource
    if #UI_TEXT > 150000 then UI_TEXT = "-- [LANGZ Warning] Source terlalu panjang.\n\n" .. string.sub(UI_TEXT, 1, 150000) .. "\n\n... [TERPOTONG]" end

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

local function insertObjects(objects, isRbxl, sourceMap)
    local count = 0
    for _, obj in ipairs(objects) do
        pcall(function()
            local target = (isRbxl and (SVC_MAP[obj.ClassName] or SVC_MAP[obj.Name])) or workspace
            if target == workspace and obj:IsA("Service") then target = ReplicatedStorage end

            if isRbxl and target ~= workspace then
                for _, ch in ipairs(obj:GetChildren()) do
                    pcall(function() 
                        ch.Parent = target; 
                        injectAllScripts(ch, sourceMap); 
                        ApplyStudioLiteProperties(ch); 
                        LoadAssetsToSLServer(ch); 
                        count = count + 1 
                    end)
                    task.wait(0.01)
                end
            else
                obj.Parent = target; 
                injectAllScripts(obj, sourceMap); 
                ApplyStudioLiteProperties(obj); 
                LoadAssetsToSLServer(obj); 
                count = count + 1
            end
        end)
    end
    return count
end

local function safeReadFile(p) if not readfile then return nil end; local ok, d = pcall(readfile, p); return ok and d or nil end

local function loadFile(fileInfo)
    local isRbxl = fileInfo.ftype == "RBXL"
    local data = safeReadFile(fileInfo.path)
    if not data or #data == 0 then return false, "readfile gagal" end

    local sourceMap = {}
    
    -- DI-PATCH: Parser sekarang membaca RBXL untuk menyelamatkan script di dalamnya
    local ok, sources, err = pcall(parseRBXMForSources, data)
    if ok and sources then 
        sourceMap = sources 
    end

    if getcustomasset then
        local ok1, aid = pcall(getcustomasset, fileInfo.path)
        if ok1 and aid then
            local ok2, objs = pcall(function() return game:GetObjects(aid) end)
            if ok2 and objs and #objs > 0 then return true, insertObjects(objs, isRbxl, sourceMap) .. " object(s) loaded" end
        end
    end

    local ok3, o3 = pcall(function() return game:GetObjects("rbxasset://" .. fileInfo.path) end)
    if ok3 and o3 and #o3 > 0 then return true, insertObjects(o3, isRbxl, sourceMap) .. " object(s) loaded" end

    return false, "Semua metode load gagal"
end

--                                                                        
-- FILE SCANNER
--                                                                        
local function safeListFiles(p) if not listfiles then return nil end; local ok, f = pcall(listfiles, p); return ok and f or nil end
local function getFileName(p) return p:match("([^/]+)$") or p end
local function getFileType(n) 
    n = n:lower(); 
    if n:match("%.rbxl") or n:match("%.rbxlx") then return "RBXL" 
    elseif n:match("%.rbxm") or n:match("%.rbxmx") then return "RBXM" end; 
    return nil 
end
local function looksFolder(p) return not getFileName(p):match("%.[%a%d]+") end

local SCAN_PATHS = { "workspace", "Delta/workspace", "delta/workspace", "Android/Delta/workspace", "/sdcard/Delta/workspace", "/sdcard/Android/Delta/workspace", "../workspace", ".", "" }

local function scanDeep(folder, depth, results, seen)
    if depth > 4 or seen[folder] then return end
    seen[folder] = true
    local list = safeListFiles(folder)
    if not list then return end
    for _, path in ipairs(list) do
        local name = getFileName(path); local ftype = getFileType(name)
        if ftype and not seen[path] then
            seen[path] = true; table.insert(results, { name=name, path=path, ftype=ftype, folder=folder })
        elseif looksFolder(path) then scanDeep(path, depth+1, results, seen) end
    end
end

local function scanAll()
    local results, seen = {}, {}; 
    for _, p in ipairs(SCAN_PATHS) do 
        if safeListFiles(p) then scanDeep(p, 0, results, seen) end 
    end
    return results
end

--                                                                        
-- DESTROY OLD UI
--                                                                        
if CoreDest:FindFirstChild("LANGZImporterUI") then CoreDest:FindFirstChild("LANGZImporterUI"):Destroy() end
if CoreDest:FindFirstChild("LANGZImporterUI") then CoreDest:FindFirstChild("LANGZImporterUI"):Destroy() end

local UI = Instance.new("ScreenGui", CoreDest)
UI.Name = "LANGZImporterUI"; UI.ResetOnSpawn = false; UI.DisplayOrder = 100; UI.IgnoreGuiInset = true

-- Persistent hacker atmosphere: the green tint remains after the loading screen closes.
local HackerAtmosphere = Instance.new("Frame", UI)
HackerAtmosphere.Name = "HackerAtmosphere"
HackerAtmosphere.Size = UDim2.new(1, 0, 1, 0)
HackerAtmosphere.Position = UDim2.new(0, 0, 0, 0)
HackerAtmosphere.BackgroundColor3 = Color3.fromRGB(3, 24, 12)
HackerAtmosphere.BackgroundTransparency = 0.84
HackerAtmosphere.BorderSizePixel = 0
HackerAtmosphere.ZIndex = 0
HackerAtmosphere.Active = false

-- Table untuk menampung UIGradient yang akan dianimasikan secara real-time
local AnimatedGradients = {}

local function registerGradientAnimation(gradient, speed, mode)
    table.insert(AnimatedGradients, {
        Gradient = gradient,
        Speed = speed or 60,
        Mode = mode or "rotate"
    })
end

--                                                                        
-- LOADING SCREEN (HACKER MATRIX RAIN + KING LANGZ CENTER TEXT)
--                                                                        
local LoadingScreen = Instance.new("Frame", UI)
LoadingScreen.Name = "LoadingScreen"
LoadingScreen.Size = UDim2.new(1, 0, 1, 0)
LoadingScreen.Position = UDim2.new(0, 0, 0, 0)
LoadingScreen.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
LoadingScreen.BorderSizePixel = 0
LoadingScreen.ZIndex = 999

-- Matrix rain canvas
local MatrixCanvas = Instance.new("Frame", LoadingScreen)
MatrixCanvas.Name = "MatrixCanvas"
MatrixCanvas.Size = UDim2.new(1, 0, 1, 0)
MatrixCanvas.BackgroundTransparency = 1
MatrixCanvas.ZIndex = 999

-- Characters used for matrix rain
local matrixChars = {"0","1","0","1","A","B","C","D","E","F","$","#","%","@","!","&","*","X","Z","0","1"}

-- Spawn multiple falling text columns
local COLUMN_COUNT = 28
local columns = {}

for col = 1, COLUMN_COUNT do
    local xPos = (col - 1) / COLUMN_COUNT
    local columnFrame = Instance.new("Frame", MatrixCanvas)
    columnFrame.Size = UDim2.new(1 / COLUMN_COUNT, 0, 1, 0)
    columnFrame.Position = UDim2.new(xPos, 0, 0, 0)
    columnFrame.BackgroundTransparency = 1
    columnFrame.ZIndex = 999
    columnFrame.ClipsDescendants = true

    -- Each column has a stream of characters
    local streamLength = math.random(6, 16)
    local charLabels = {}
    for row = 1, streamLength do
        local charLabel = Instance.new("TextLabel", columnFrame)
        charLabel.Size = UDim2.new(1, 0, 0, 18)
        charLabel.Position = UDim2.new(0, 0, 0, (row - 1) * 18)
        charLabel.BackgroundTransparency = 1
        charLabel.Font = Enum.Font.Code
        charLabel.TextSize = 14
        charLabel.TextXAlignment = Enum.TextXAlignment.Center
        -- Head char is bright green, tail fades
        if row == 1 then
            charLabel.TextColor3 = Color3.fromRGB(180, 255, 180)
        elseif row <= 3 then
            charLabel.TextColor3 = Color3.fromRGB(0, 220, 0)
        elseif row <= 6 then
            charLabel.TextColor3 = Color3.fromRGB(0, 160, 0)
        else
            charLabel.TextColor3 = Color3.fromRGB(0, 90, 0)
        end
        charLabel.Text = matrixChars[math.random(1, #matrixChars)]
        charLabel.ZIndex = 999
        table.insert(charLabels, charLabel)
    end

    -- Randomize start offset and speed
    local startY = math.random(-800, -100)
    local speed = math.random(180, 420)
    local currentY = startY

    table.insert(columns, {
        frame = columnFrame,
        labels = charLabels,
        y = currentY,
        speed = speed,
        streamLength = streamLength,
        charTimer = 0,
        charInterval = math.random(3, 8) * 0.05
    })
end

-- CENTER: KING LANGZ text   no stroke, no background, text only + decorative elements
local CenterContainer = Instance.new("Frame", LoadingScreen)
CenterContainer.Size = UDim2.new(0, 500, 0, 220)
CenterContainer.Position = UDim2.new(0.5, -250, 0.5, -110)
CenterContainer.BackgroundTransparency = 1
CenterContainer.ZIndex = 1001

-- Top decorative line
local TopLine = Instance.new("TextLabel", CenterContainer)
TopLine.Size = UDim2.new(1, 0, 0, 20)
TopLine.Position = UDim2.new(0, 0, 0, 0)
TopLine.BackgroundTransparency = 1
TopLine.Text = string.char(226,148,128,226,148,128,32,226,151,136,32,226,148,128,226,148,128,226,148,128)..string.char(226,148,128,226,148,128,226,148,128,226,148,128,226,148,128,226,148,128,226,148)..string.char(128,226,148,128,226,148,128,226,148,128,226,148,128,226,148,128,226,148,128,226)..string.char(148,128,226,148,128,226,148,128,226,148,128,226,148,128,226,148,128,32,226,151)..string.char(136,32,226,148,128,226,148,128)
TopLine.TextColor3 = Color3.fromRGB(0, 200, 0)
TopLine.Font = Enum.Font.Code
TopLine.TextSize = 13
TopLine.ZIndex = 1001

-- Hacker terminal boot marker
local BootMarker = Instance.new("TextLabel", CenterContainer)
BootMarker.Size = UDim2.new(1, 0, 0, 38)
BootMarker.Position = UDim2.new(0, 0, 0, 22)
BootMarker.BackgroundTransparency = 1
BootMarker.Text = "[ SECURE BOOT // LANGZ NODE ]"
BootMarker.TextColor3 = Color3.fromRGB(100, 255, 145)
BootMarker.Font = Enum.Font.Code
BootMarker.TextSize = 12
BootMarker.ZIndex = 1001

-- Main KING LANGZ text   GothamBold, no stroke
local KingText = Instance.new("TextLabel", CenterContainer)
KingText.Size = UDim2.new(1, 0, 0, 62)
KingText.Position = UDim2.new(0, 0, 0, 62)
KingText.BackgroundTransparency = 1
KingText.Text = "KING LANGZ V62"
KingText.TextColor3 = Color3.fromRGB(0, 255, 70)
KingText.Font = Enum.Font.GothamBold
KingText.TextSize = 54
KingText.ZIndex = 1001

-- Tagline below
local TagLine = Instance.new("TextLabel", CenterContainer)
TagLine.Size = UDim2.new(1, 0, 0, 22)
TagLine.Position = UDim2.new(0, 0, 0, 126)
TagLine.BackgroundTransparency = 1
TagLine.Text = "[ RBXM/RBXL IMPORTER SYSTEM INITIALIZED ]"
TagLine.TextColor3 = Color3.fromRGB(0, 180, 0)
TagLine.Font = Enum.Font.Code
TagLine.TextSize = 13
TagLine.ZIndex = 1001

-- Progress dots / loading indicator
local LoadDots = Instance.new("TextLabel", CenterContainer)
LoadDots.Size = UDim2.new(1, 0, 0, 20)
LoadDots.Position = UDim2.new(0, 0, 0, 152)
LoadDots.BackgroundTransparency = 1
LoadDots.Text = "loading . . ."
LoadDots.TextColor3 = Color3.fromRGB(0, 140, 0)
LoadDots.Font = Enum.Font.Code
LoadDots.TextSize = 12
LoadDots.ZIndex = 1001

-- Bottom decorative line
local BotLine = Instance.new("TextLabel", CenterContainer)
BotLine.Size = UDim2.new(1, 0, 0, 20)
BotLine.Position = UDim2.new(0, 0, 0, 196)
BotLine.BackgroundTransparency = 1
BotLine.Text = string.char(226,148,128,226,148,128,32,226,151,136,32,226,148,128,226,148,128,226,148,128)..string.char(226,148,128,226,148,128,226,148,128,226,148,128,226,148,128,226,148,128,226,148)..string.char(128,226,148,128,226,148,128,226,148,128,226,148,128,226,148,128,226,148,128,226)..string.char(148,128,226,148,128,226,148,128,226,148,128,226,148,128,226,148,128,32,226,151)..string.char(136,32,226,148,128,226,148,128)
BotLine.TextColor3 = Color3.fromRGB(0, 200, 0)
BotLine.Font = Enum.Font.Code
BotLine.TextSize = 13
BotLine.ZIndex = 1001

-- Animate matrix rain + loading dots in a single loop
local loadingActive = true
local dotStates = {"loading .     ", "loading . .   ", "loading . . . "}
local dotIndex = 0

local matrixConnection
matrixConnection = RunService.RenderStepped:Connect(function(dt)
    if not loadingActive then
        matrixConnection:Disconnect()
        return
    end

    -- Update matrix columns
    for _, col in ipairs(columns) do
        col.y = col.y + col.speed * dt
        -- Reposition frame
        col.frame.Position = UDim2.new(col.frame.Position.X.Scale, 0, 0, col.y)
        -- Reset when fully off bottom
        if col.y > 700 + col.streamLength * 18 then
            col.y = math.random(-600, -80)
            col.speed = math.random(180, 420)
        end
        -- Randomize characters periodically
        col.charTimer = col.charTimer + dt
        if col.charTimer >= col.charInterval then
            col.charTimer = 0
            col.charInterval = math.random(3, 8) * 0.05
            for _, lbl in ipairs(col.labels) do
                lbl.Text = matrixChars[math.random(1, #matrixChars)]
            end
        end
    end
end)

-- Loading dot animation + pulse on KING LANGZ text
task.spawn(function()
    local pulseUp = true
    local r, g, b = 0, 255, 70
    local tick = 0
    while loadingActive do
        task.wait(0.35)
        dotIndex = (dotIndex % 3) + 1
        LoadDots.Text = dotStates[dotIndex]
        -- Pulse green hue on main text
        tick = tick + 1
        if tick % 2 == 0 then
            KingText.TextColor3 = Color3.fromRGB(0, 255, 70)
        else
            KingText.TextColor3 = Color3.fromRGB(40, 255, 100)
        end
    end
end)

-- Auto-dismiss loading screen after 2.8 seconds
task.spawn(function()
    task.wait(2.8)
    loadingActive = false
    -- Fade out loading screen
    for i = 1, 20 do
        LoadingScreen.BackgroundTransparency = i / 20
        for _, obj in ipairs(LoadingScreen:GetDescendants()) do
            if obj:IsA("TextLabel") then
                obj.TextTransparency = i / 20
            end
        end
        task.wait(0.025)
    end
    LoadingScreen:Destroy()
end)

--                                                                        
-- RenderStepped Animation Engine (60 FPS Smooth Movement)
--                                                                        
RunService.RenderStepped:Connect(function(deltaTime)
    for _, anim in ipairs(AnimatedGradients) do
        if anim.Gradient and anim.Gradient.Parent then
            if anim.Mode == "rotate" then
                anim.Gradient.Rotation = (anim.Gradient.Rotation + (anim.Speed * deltaTime)) % 360
            elseif anim.Mode == "shift" then
                local currentX = anim.Gradient.Offset.X
                local newX = currentX + (anim.Speed * deltaTime)
                if newX > 1 then newX = -1 end
                anim.Gradient.Offset = Vector2.new(newX, anim.Gradient.Offset.Y)
            end
        end
    end
end)

--                                                                        
-- FLOATING TOGGLE BUTTON WITH VECTOR CHEVRON ICON
--                                                                        
local ToggleFrame = Instance.new("Frame", UI)
ToggleFrame.Name = "ToggleFrame"
ToggleFrame.Size = UDim2.new(0, 36, 0, 36)
-- Keep the only toggle directly below the Roblox menu.
ToggleFrame.Position = UDim2.new(0, 8, 0, 48)
ToggleFrame.BackgroundColor3 = Color3.fromRGB(5, 30, 16)
ToggleFrame.BackgroundTransparency = 0.08
ToggleFrame.BorderSizePixel = 0
ToggleFrame.Active = true

local ToggleCorner = Instance.new("UICorner", ToggleFrame)
ToggleCorner.CornerRadius = UDim.new(0, 10)

local ToggleGrad = Instance.new("UIGradient", ToggleFrame)
ToggleGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 65, 30)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 150, 55)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(3, 28, 14))
})
ToggleGrad.Rotation = 45
registerGradientAnimation(ToggleGrad, 40, "rotate")

local ToggleStroke = Instance.new("UIStroke", ToggleFrame)
ToggleStroke.Thickness = 1.2
ToggleStroke.Color = Color3.fromRGB(100, 255, 145)
ToggleStroke.Transparency = 0.18

local ToggleIcon = Instance.new("ImageLabel", ToggleFrame)
ToggleIcon.Size = UDim2.new(0, 20, 0, 20)
ToggleIcon.Position = UDim2.new(0.5, -10, 0.5, -10)
ToggleIcon.BackgroundTransparency = 1
ToggleIcon.Image = ICONS.CHEVRON_RIGHT
ToggleIcon.ImageColor3 = Color3.fromRGB(205, 255, 190)

local ToggleBtn = Instance.new("TextButton", ToggleFrame)
ToggleBtn.Size = UDim2.new(1, 0, 1, 0)
ToggleBtn.BackgroundTransparency = 1
ToggleBtn.Text = ""

-- Dragging System Toggle Button
local tDragToggle, tDragStart, tStartPos
ToggleFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        tDragToggle = true; tDragStart = input.Position; tStartPos = ToggleFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if tDragToggle and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - tDragStart
        ToggleFrame.Position = UDim2.new(tStartPos.X.Scale, tStartPos.X.Offset + delta.X, tStartPos.Y.Scale, tStartPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        tDragToggle = false
    end
end)

-- MAIN CONTAINER
local Main = Instance.new("Frame", UI)
Main.Name = "MainFrame"
Main.Size = UDim2.new(0, 300, 0, 350)
Main.Position = UDim2.new(0.5, -150, 0.5, -175)
Main.BackgroundColor3 = Color3.fromRGB(6, 18, 11)
Main.BackgroundTransparency = 0.05
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Visible = true

local MainCorner = Instance.new("UICorner", Main)
MainCorner.CornerRadius = UDim.new(0, 10)

local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Thickness = 1.2
MainStroke.Color = Color3.fromRGB(75, 205, 105)
MainStroke.Transparency = 0.2

-- TITLE BAR WITH VECTOR PACKAGE ICON
local TitleBar = Instance.new("Frame", Main)
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = Color3.fromRGB(7, 45, 21)
TitleBar.BorderSizePixel = 0
TitleBar.ClipsDescendants = true

-- Round the upper panel corners so the header matches the rounded body.
local TitleCorner = Instance.new("UICorner", TitleBar)
TitleCorner.CornerRadius = UDim.new(0, 10)

local TitleGrad = Instance.new("UIGradient", TitleBar)
TitleGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(3, 24, 12)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(13, 90, 35)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 35, 17))
})
registerGradientAnimation(TitleGrad, 0.8, "shift")

local TitleIcon = Instance.new("ImageLabel", TitleBar)
TitleIcon.Size = UDim2.new(0, 18, 0, 18)
TitleIcon.Position = UDim2.new(0, 10, 0.5, -9)
TitleIcon.BackgroundTransparency = 1
TitleIcon.Image = ICONS.PACKAGE
TitleIcon.ImageColor3 = Color3.fromRGB(170, 255, 150)

local TitleText = Instance.new("TextLabel", TitleBar)
TitleText.Size = UDim2.new(1, -90, 1, 0)
TitleText.Position = UDim2.new(0, 34, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = string.char(75,73,78,71,32,76,65,78,71,90,32,82,66,88,77,32,86,54,50,32)..string.char(240,159,145,145)
TitleText.TextColor3 = Color3.fromRGB(215, 255, 205)
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 12
TitleText.TextXAlignment = Enum.TextXAlignment.Left

-- CLOSE BUTTON WITH CLEAR X ICON
local CloseBtn = Instance.new("Frame", TitleBar)
CloseBtn.Size = UDim2.new(0, 22, 0, 22)
CloseBtn.Position = UDim2.new(1, -28, 0.5, -11)
CloseBtn.BackgroundColor3 = Color3.fromRGB(10, 54, 26)
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 5)

local CloseIcon = Instance.new("TextLabel", CloseBtn)
CloseIcon.Size = UDim2.new(0, 12, 0, 12)
CloseIcon.Position = UDim2.new(0.5, -6, 0.5, -6)
CloseIcon.BackgroundTransparency = 1
CloseIcon.Text = "X"
CloseIcon.TextColor3 = Color3.fromRGB(185, 255, 170)
CloseIcon.Font = Enum.Font.GothamBold
CloseIcon.TextSize = 12
CloseIcon.TextXAlignment = Enum.TextXAlignment.Center
CloseIcon.TextYAlignment = Enum.TextYAlignment.Center

local CloseClick = Instance.new("TextButton", CloseBtn)
CloseClick.Size = UDim2.new(1, 0, 1, 0)
CloseClick.BackgroundTransparency = 1
CloseClick.Text = ""

-- MINIMIZE BUTTON WITH VECTOR MINIMIZE ICON
local MinBtn = Instance.new("Frame", TitleBar)
MinBtn.Size = UDim2.new(0, 22, 0, 22)
MinBtn.Position = UDim2.new(1, -54, 0.5, -11)
MinBtn.BackgroundColor3 = Color3.fromRGB(10, 54, 26)
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 5)

local MinIcon = Instance.new("ImageLabel", MinBtn)
MinIcon.Size = UDim2.new(0, 12, 0, 12)
MinIcon.Position = UDim2.new(0.5, -6, 0.5, -6)
MinIcon.BackgroundTransparency = 1
MinIcon.Image = ICONS.MINIMIZE
MinIcon.ImageColor3 = Color3.fromRGB(185, 255, 170)

local MinClick = Instance.new("TextButton", MinBtn)
MinClick.Size = UDim2.new(1, 0, 1, 0)
MinClick.BackgroundTransparency = 1
MinClick.Text = ""

-- Dragging System Main UI
local dragToggle, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
        dragToggle = true; dragStart = input.Position; startPos = Main.Position 
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragToggle and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragToggle = false end
end)

-- Toggle panel visibility   the single toggle below the Roblox menu opens/closes Main
local function toggleMain()
    Main.Visible = not Main.Visible
    ToggleIcon.Image = Main.Visible and ICONS.CHEVRON_RIGHT or ICONS.CHEVRON_LEFT
end

ToggleBtn.MouseButton1Click:Connect(toggleMain)

-- CONTENT AREA
local Content = Instance.new("Frame", Main)
Content.Size = UDim2.new(1, -16, 1, -74)
Content.Position = UDim2.new(0, 8, 0, 42)
Content.BackgroundColor3 = Color3.fromRGB(8, 27, 15)
Content.BorderSizePixel = 0
Instance.new("UICorner", Content).CornerRadius = UDim.new(0, 8)

local ContentStroke = Instance.new("UIStroke", Content)
ContentStroke.Thickness = 1
ContentStroke.Color = Color3.fromRGB(34, 112, 55)

-- SCAN BUTTON WITH ANIMATED GRADIENT & VECTOR SEARCH ICON
local ScanBtn = Instance.new("Frame", Content)
ScanBtn.Size = UDim2.new(1, -12, 0, 30)
ScanBtn.Position = UDim2.new(0, 6, 0, 6)
ScanBtn.BackgroundColor3 = Color3.fromRGB(174, 245, 145)
Instance.new("UICorner", ScanBtn).CornerRadius = UDim.new(0, 6)

local ScanGrad = Instance.new("UIGradient", ScanBtn)
ScanGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 255, 190)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 205, 105)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 245, 140))
})
registerGradientAnimation(ScanGrad, 50, "rotate")

local ScanIcon = Instance.new("ImageLabel", ScanBtn)
ScanIcon.Size = UDim2.new(0, 14, 0, 14)
ScanIcon.Position = UDim2.new(0.5, -48, 0.5, -7)
ScanIcon.BackgroundTransparency = 1
ScanIcon.Image = ICONS.SEARCH
ScanIcon.ImageColor3 = Color3.fromRGB(3, 35, 14)

local ScanText = Instance.new("TextLabel", ScanBtn)
ScanText.Size = UDim2.new(0, 80, 1, 0)
ScanText.Position = UDim2.new(0.5, -28, 0, 0)
ScanText.BackgroundTransparency = 1
ScanText.Text = "SCAN FILES"
ScanText.TextColor3 = Color3.fromRGB(3, 35, 14)
ScanText.Font = Enum.Font.GothamBold
ScanText.TextSize = 11
ScanText.TextXAlignment = Enum.TextXAlignment.Left

local ScanClick = Instance.new("TextButton", ScanBtn)
ScanClick.Size = UDim2.new(1, 0, 1, 0)
ScanClick.BackgroundTransparency = 1
ScanClick.Text = ""


-- SEARCH / MANUAL INPUT BAR
local SearchBar = Instance.new("Frame", Content)
SearchBar.Size = UDim2.new(1, -12, 0, 26)
SearchBar.Position = UDim2.new(0, 6, 0, 40)
SearchBar.BackgroundColor3 = Color3.fromRGB(10, 38, 18)
SearchBar.BorderSizePixel = 0
Instance.new("UICorner", SearchBar).CornerRadius = UDim.new(0, 5)
local SearchStroke = Instance.new("UIStroke", SearchBar)
SearchStroke.Thickness = 1
SearchStroke.Color = Color3.fromRGB(45, 130, 60)

local SearchIcon = Instance.new("ImageLabel", SearchBar)
SearchIcon.Size = UDim2.new(0, 12, 0, 12)
SearchIcon.Position = UDim2.new(0, 6, 0.5, -6)
SearchIcon.BackgroundTransparency = 1
SearchIcon.Image = ICONS.SEARCH
SearchIcon.ImageColor3 = Color3.fromRGB(130, 210, 130)

local SearchInput = Instance.new("TextBox", SearchBar)
SearchInput.Size = UDim2.new(1, -48, 1, 0)
SearchInput.Position = UDim2.new(0, 22, 0, 0)
SearchInput.BackgroundTransparency = 1
SearchInput.Text = ""
SearchInput.PlaceholderText = "Cari file / ketik nama (Enter = insert)"
SearchInput.PlaceholderColor3 = Color3.fromRGB(70, 130, 75)
SearchInput.TextColor3 = Color3.fromRGB(200, 255, 190)
SearchInput.Font = Enum.Font.Gotham
SearchInput.TextSize = 9
SearchInput.TextXAlignment = Enum.TextXAlignment.Left
SearchInput.ClearTextOnFocus = false

local SearchClearBtn = Instance.new("TextButton", SearchBar)
SearchClearBtn.Size = UDim2.new(0, 20, 0, 20)
SearchClearBtn.Position = UDim2.new(1, -22, 0.5, -10)
SearchClearBtn.BackgroundTransparency = 1
SearchClearBtn.Text = "x"
SearchClearBtn.TextColor3 = Color3.fromRGB(100, 180, 100)
SearchClearBtn.Font = Enum.Font.GothamBold
SearchClearBtn.TextSize = 10

-- SCROLL LIST
local Scroll = Instance.new("ScrollingFrame", Content)
Scroll.Size = UDim2.new(1, -12, 1, -80)
Scroll.Position = UDim2.new(0, 6, 0, 72)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = Color3.fromRGB(92, 208, 105)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local Layout = Instance.new("UIListLayout", Scroll)
Layout.Padding = UDim.new(0, 5)
Layout.SortOrder = Enum.SortOrder.LayoutOrder

-- EMPTY STATE FRAME WITH VECTOR FOLDER ICON
local EmptyFrame = Instance.new("Frame", Scroll)
EmptyFrame.Size = UDim2.new(1, 0, 0, 100)
EmptyFrame.BackgroundTransparency = 1

local EmptyIcon = Instance.new("ImageLabel", EmptyFrame)
EmptyIcon.Size = UDim2.new(0, 26, 0, 26)
EmptyIcon.Position = UDim2.new(0.5, -13, 0, 16)
EmptyIcon.BackgroundTransparency = 1
EmptyIcon.Image = ICONS.FOLDER
EmptyIcon.ImageColor3 = Color3.fromRGB(90, 220, 110)

local EmptyLabel = Instance.new("TextLabel", EmptyFrame)
EmptyLabel.Size = UDim2.new(1, -20, 0, 36)
EmptyLabel.Position = UDim2.new(0, 10, 0, 48)
EmptyLabel.BackgroundTransparency = 1
EmptyLabel.Text = "Belum ada file terdeteksi.\nTekan 'SCAN FILES' untuk mencari file RBXM/RBXL."
EmptyLabel.TextColor3 = Color3.fromRGB(125, 190, 130)
EmptyLabel.Font = Enum.Font.Gotham
EmptyLabel.TextSize = 10
EmptyLabel.TextWrapped = true

-- STATS BAR
local StatsBar = Instance.new("Frame", Main)
StatsBar.Size = UDim2.new(1, -16, 0, 22)
StatsBar.Position = UDim2.new(0, 8, 1, -26)
StatsBar.BackgroundColor3 = Color3.fromRGB(8, 27, 15)
StatsBar.BorderSizePixel = 0
Instance.new("UICorner", StatsBar).CornerRadius = UDim.new(0, 5)

local StatsText = Instance.new("TextLabel", StatsBar)
StatsText.Size = UDim2.new(1, -10, 1, 0)
StatsText.Position = UDim2.new(0, 6, 0, 0)
StatsText.BackgroundTransparency = 1
StatsText.Text = "Status: Ready  |  Files: 0"
StatsText.TextColor3 = Color3.fromRGB(140, 220, 145)
StatsText.Font = Enum.Font.Gotham
StatsText.TextSize = 9
StatsText.TextXAlignment = Enum.TextXAlignment.Left

-- NOTIFICATION SYSTEM WITH VECTOR BELL ICON
local function notify(title, msg, color)
    color = color or Color3.fromRGB(200, 200, 210)
    local notif = Instance.new("Frame", UI)
    notif.Size = UDim2.new(0, 220, 0, 42)
    notif.Position = UDim2.new(1, -230, 1, -55)
    notif.BackgroundColor3 = Color3.fromRGB(7, 29, 14)
    notif.BorderSizePixel = 0
    Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 6)

    local notifStroke = Instance.new("UIStroke", notif)
    notifStroke.Thickness = 1
    notifStroke.Color = color

    local icon = Instance.new("ImageLabel", notif)
    icon.Size = UDim2.new(0, 14, 0, 14)
    icon.Position = UDim2.new(0, 8, 0, 6)
    icon.BackgroundTransparency = 1
    icon.Image = ICONS.BELL
    icon.ImageColor3 = color

    local t = Instance.new("TextLabel", notif)
    t.Size = UDim2.new(1, -28, 0, 14); t.Position = UDim2.new(0, 26, 0, 4)
    t.BackgroundTransparency = 1; t.Text = title
    t.TextColor3 = Color3.fromRGB(205, 255, 190); t.Font = Enum.Font.GothamBold
    t.TextSize = 10; t.TextXAlignment = Enum.TextXAlignment.Left

    local d = Instance.new("TextLabel", notif)
    d.Size = UDim2.new(1, -12, 0, 16); d.Position = UDim2.new(0, 8, 0, 18)
    d.BackgroundTransparency = 1; d.Text = msg
    d.TextColor3 = Color3.fromRGB(135, 195, 140); d.Font = Enum.Font.Gotham
    d.TextSize = 8; d.TextXAlignment = Enum.TextXAlignment.Left
    d.TextWrapped = true

    task.spawn(function()
        task.wait(2.5)
        for i = 1, 12 do
            notif.BackgroundTransparency = i / 12
            icon.ImageTransparency = i / 12
            t.TextTransparency = i / 12
            d.TextTransparency = i / 12
            task.wait(0.02)
        end
        notif:Destroy()
    end)
end

-- SEARCH STATE (declared before buildFileCard so upvalue resolves correctly)
local allFileCards = {}
local currentQuery = ""

-- CARD BUILDER WITH VECTOR BADGES & DOWNLOAD ICON
local totalLoaded = 0

local function buildFileCard(fileInfo)
    EmptyFrame.Visible = false

    local card = Instance.new("Frame", Scroll)
    table.insert(allFileCards, {fileInfo=fileInfo, card=card})
    card.Size = UDim2.new(1, 0, 0, 44)
    card.BackgroundColor3 = Color3.fromRGB(12, 34, 19)
    card.BorderSizePixel = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)

    local cardStroke = Instance.new("UIStroke", card)
    cardStroke.Thickness = 1
    cardStroke.Color = Color3.fromRGB(35, 105, 48)

    local isRbxl = fileInfo.ftype == "RBXL"

    local typeBadge = Instance.new("Frame", card)
    typeBadge.Size = UDim2.new(0, 48, 0, 16); typeBadge.Position = UDim2.new(0, 6, 0, 6)
    typeBadge.BackgroundColor3 = isRbxl and Color3.fromRGB(115, 220, 120) or Color3.fromRGB(43, 110, 55)
    typeBadge.BorderSizePixel = 0
    Instance.new("UICorner", typeBadge).CornerRadius = UDim.new(0, 4)

    local badgeIcon = Instance.new("ImageLabel", typeBadge)
    badgeIcon.Size = UDim2.new(0, 10, 0, 10)
    badgeIcon.Position = UDim2.new(0, 4, 0.5, -5)
    badgeIcon.BackgroundTransparency = 1
    badgeIcon.Image = isRbxl and ICONS.GAMEPAD or ICONS.FILE
    badgeIcon.ImageColor3 = Color3.fromRGB(4, 30, 13)

    local typeText = Instance.new("TextLabel", typeBadge)
    typeText.Size = UDim2.new(1, -16, 1, 0); typeText.Position = UDim2.new(0, 16, 0, 0)
    typeText.BackgroundTransparency = 1
    typeText.Text = fileInfo.ftype
    typeText.TextColor3 = Color3.fromRGB(4, 30, 13)
    typeText.Font = Enum.Font.GothamBold; typeText.TextSize = 8

    local nameLbl = Instance.new("TextLabel", card)
    nameLbl.Size = UDim2.new(1, -135, 0, 16); nameLbl.Position = UDim2.new(0, 60, 0, 6)
    nameLbl.BackgroundTransparency = 1; nameLbl.Text = fileInfo.name
    nameLbl.TextColor3 = Color3.fromRGB(210, 244, 205); nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 10; nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd

    local pathLbl = Instance.new("TextLabel", card)
    pathLbl.Size = UDim2.new(1, -135, 0, 12); pathLbl.Position = UDim2.new(0, 60, 0, 22)
    pathLbl.BackgroundTransparency = 1; pathLbl.Text = fileInfo.path
    pathLbl.TextColor3 = Color3.fromRGB(105, 170, 110); pathLbl.Font = Enum.Font.Gotham
    pathLbl.TextSize = 8; pathLbl.TextXAlignment = Enum.TextXAlignment.Left
    pathLbl.TextTruncate = Enum.TextTruncate.AtEnd

    local insertFrame = Instance.new("Frame", card)
    insertFrame.Size = UDim2.new(0, 66, 0, 24); insertFrame.Position = UDim2.new(1, -72, 0.5, -12)
    insertFrame.BackgroundColor3 = Color3.fromRGB(18, 58, 27)
    Instance.new("UICorner", insertFrame).CornerRadius = UDim.new(0, 4)

    local btnStroke = Instance.new("UIStroke", insertFrame)
    btnStroke.Thickness = 1
    btnStroke.Color = Color3.fromRGB(100, 205, 105)

    local insertIcon = Instance.new("ImageLabel", insertFrame)
    insertIcon.Size = UDim2.new(0, 10, 0, 10)
    insertIcon.Position = UDim2.new(0, 6, 0.5, -5)
    insertIcon.BackgroundTransparency = 1
    insertIcon.Image = ICONS.DOWNLOAD
    insertIcon.ImageColor3 = Color3.fromRGB(190, 255, 180)

    local insertText = Instance.new("TextLabel", insertFrame)
    insertText.Size = UDim2.new(1, -18, 1, 0); insertText.Position = UDim2.new(0, 18, 0, 0)
    insertText.BackgroundTransparency = 1; insertText.Text = "INSERT"
    insertText.TextColor3 = Color3.fromRGB(190, 255, 180)
    insertText.Font = Enum.Font.GothamBold; insertText.TextSize = 8

    local insertBtn = Instance.new("TextButton", insertFrame)
    insertBtn.Size = UDim2.new(1, 0, 1, 0)
    insertBtn.BackgroundTransparency = 1
    insertBtn.Text = ""

    insertBtn.MouseEnter:Connect(function() TweenService:Create(insertFrame, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 100, 42)}):Play() end)
    insertBtn.MouseLeave:Connect(function() TweenService:Create(insertFrame, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(18, 58, 27)}):Play() end)

    insertBtn.MouseButton1Click:Connect(function()
        if insertText.Text == "LOADING" then return end
        insertText.Text = "LOADING"; insertIcon.Image = ICONS.REFRESH
        insertFrame.BackgroundColor3 = Color3.fromRGB(20, 76, 30)

        task.spawn(function()
            local ok, msg = loadFile(fileInfo)
            if ok then
                insertText.Text = "DONE"; insertIcon.Image = ICONS.CHECK
                insertFrame.BackgroundColor3 = Color3.fromRGB(95, 220, 105)
                totalLoaded = totalLoaded + 1
                StatsText.Text = string.format("Status: Ready  |  Files: %d  |  Loaded: %d", #Scroll:GetChildren() - 1, totalLoaded)
                notify("Success", fileInfo.name .. " dimuat!", Color3.fromRGB(200, 200, 210))
            else
                insertText.Text = "FAIL"; insertIcon.Image = ICONS.ALERT
                insertFrame.BackgroundColor3 = Color3.fromRGB(150, 45, 45)
                notify("Gagal", msg, Color3.fromRGB(220, 80, 80))
            end
            task.wait(2)
            insertText.Text = "INSERT"; insertIcon.Image = ICONS.DOWNLOAD
            insertFrame.BackgroundColor3 = Color3.fromRGB(18, 58, 27)
        end)
    end)
end


-- SEARCH & FILTER LOGIC

local function filterCards(query)
    currentQuery = query:lower():gsub("^%s*", ""):gsub("%s*$", "")
    local anyVisible = false
    for _, entry in ipairs(allFileCards) do
        local name = entry.fileInfo.name:lower()
        local path = entry.fileInfo.path:lower()
        local visible = currentQuery == "" or name:find(currentQuery, 1, true) or path:find(currentQuery, 1, true)
        entry.card.Visible = visible
        if visible then anyVisible = true end
    end
    EmptyFrame.Visible = not anyVisible and #allFileCards == 0
end

local function tryManualInsert(input)
    local query = input:gsub("^%s*", ""):gsub("%s*$", "")
    if query == "" then return end
    -- Check against known files first
    for _, entry in ipairs(allFileCards) do
        if entry.fileInfo.name:lower() == query:lower() or entry.fileInfo.path:lower() == query:lower() then
            notify("Memuat", entry.fileInfo.name, Color3.fromRGB(200, 230, 210))
            task.spawn(function()
                local ok, msg = loadFile(entry.fileInfo)
                if ok then
                    totalLoaded = totalLoaded + 1
                    StatsText.Text = string.format("Status: Ready  |  Files: %d  |  Loaded: %d", #allFileCards, totalLoaded)
                    notify("Success", entry.fileInfo.name .. " dimuat!", Color3.fromRGB(200, 200, 210))
                else
                    notify("Gagal", msg, Color3.fromRGB(220, 80, 80))
                end
            end)
            return
        end
    end
    -- Manual path: try direct paths in scan folders
    local tryPaths = {
        query,
        "Delta/workspace/" .. query,
        "workspace/" .. query,
        "delta/workspace/" .. query,
        "Android/Delta/workspace/" .. query,
    }
    -- Add extensions if missing
    local withExt = {}
    for _, p in ipairs(tryPaths) do
        table.insert(withExt, p)
        if not p:lower():match("%.rbx") then
            table.insert(withExt, p .. ".rbxm")
            table.insert(withExt, p .. ".rbxmx")
            table.insert(withExt, p .. ".rbxl")
        end
    end
    for _, path in ipairs(withExt) do
        local name = path:match("([^/]+)$") or path
        local ftype = name:lower():match("%.rbxlx?$") and "RBXL" or (name:lower():match("%.rbxmx?$") and "RBXM" or nil)
        if ftype then
            local fi = {name=name, path=path, ftype=ftype, folder="manual"}
            local ok, msg = loadFile(fi)
            if ok then
                totalLoaded = totalLoaded + 1
                notify("Manual Insert OK", name .. " dimuat!", Color3.fromRGB(200, 200, 210))
                return
            end
        end
    end
    notify("Tidak Ditemukan", query .. " tidak ada di folder manapun", Color3.fromRGB(220, 80, 80))
end

SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
    filterCards(SearchInput.Text)
end)

SearchInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local query = SearchInput.Text:gsub("^%s*", ""):gsub("%s*$", "")
        if query ~= "" then
            tryManualInsert(query)
        end
    end
end)

SearchClearBtn.MouseButton1Click:Connect(function()
    SearchInput.Text = ""
    filterCards("")
end)

-- SCAN LOGIC
ScanClick.MouseButton1Click:Connect(function()
    ScanText.Text = "SCANNING..."
    ScanIcon.Image = ICONS.REFRESH

    for _, c in ipairs(Scroll:GetChildren()) do 
        if c:IsA("Frame") and c ~= EmptyFrame then c:Destroy() end 
    end
    allFileCards = {}
    EmptyFrame.Visible = true
    totalLoaded = 0

    task.spawn(function()
        local foundFiles = scanAll()
        for _, f in ipairs(foundFiles) do buildFileCard(f) end

        StatsText.Text = string.format("Status: Ready  |  Files: %d", #foundFiles)
        ScanText.Text = "SCAN FILES"
        ScanIcon.Image = ICONS.SEARCH

        if #foundFiles == 0 then
            EmptyLabel.Text = "Tidak ada file RBXM/RBXL terdeteksi.\nPeriksa folder workspace executor."
        else
            notify("Scan Selesai", #foundFiles .. " file terdeteksi", Color3.fromRGB(220, 220, 230))
        end
    end)
end)

-- MINIMIZE / CLOSE
-- Close only hides the panel; the toggle below the Roblox menu stays available.
CloseClick.MouseButton1Click:Connect(function()
    if Main.Visible then
        toggleMain()
    end
end)

local minimized = false
MinClick.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        Content.Visible = false
        StatsBar.Visible = false
        Main.Size = UDim2.new(0, 300, 0, 36)
    else
        Content.Visible = true
        StatsBar.Visible = true
        Main.Size = UDim2.new(0, 300, 0, 350)
    end
end)

--                                                                        
-- HOOKS (Anti-Putus Studio Lite)
--                                                                        
task.spawn(function()
    if hookmetamethod then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            local args = {...}

            if not checkcaller() and method == "InvokeServer" then
                if self.Name == "GetScriptSourceServerFunction" then
                    local target = tostring(args[1])
                    for obj, src in pairs(_G.LANGZ_RAW_SOURCES) do
                        if typeof(obj) == "Instance" and (obj.ClassName .. obj.Name) == target then
                            if src and src ~= "" then return src end
                        end
                    end
                    for _, place in ipairs({workspace, ReplicatedStorage, _G.sss, _G.ss, game:GetService("StarterGui"), game:GetService("StarterPlayer"), LocalPlayer:FindFirstChild("PlayerGui"), LocalPlayer:FindFirstChild("Backpack")}) do
                        if place then
                            for _, obj in ipairs(place:GetDescendants()) do
                                if obj:IsA("LuaSourceContainer") and (obj.ClassName .. obj.Name) == target then
                                    local src = _G.LANGZ_RAW_SOURCES[obj]
                                    if src and src ~= "" then return src end
                                end
                           end
                        end
                    end
                end

                if self.Name == "SaveScriptSourceServerFunction" then
                    local target = tostring(args[1])
                    local newSource = tostring(args[2])
                    for obj, _ in pairs(_G.LANGZ_RAW_SOURCES) do
                        if typeof(obj) == "Instance" and (obj.ClassName .. obj.Name) == target then
                            _G.LANGZ_RAW_SOURCES[obj] = newSource
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
                local src = _G.LANGZ_RAW_SOURCES[module]
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
                    pcall(function() ApplyStudioLiteProperties(obj) end)
                    pcall(function() LoadAssetsToSLServer(obj) end)
                end
            end
            return objects
        end)

        local oldLoadAsset
        oldLoadAsset = hookfunction(InsertService.LoadAsset, function(self, assetId, ...)
            triggerServerLoad(tostring(assetId))
            local obj = oldLoadAsset(self, assetId, ...)
            if obj then
                pcall(function() injectAllScripts(obj, {}) end)
                pcall(function() ApplyStudioLiteProperties(obj) end)
                pcall(function() LoadAssetsToSLServer(obj) end)
            end
            return obj
        end)
    end
end)

print("[LANGZ] IMPORTER v62.0 LOADED (RBXL PATCHED)")