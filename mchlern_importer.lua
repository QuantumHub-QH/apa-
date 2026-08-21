--[[
                                                                            
       MCHLERN PROJECT IMPORTER v2.0 - Landscape Edition
       Features: Importer, Config, Replacer, Remake (GUI)
       Credits: MCHLERN PROJECT
       Supports: RBXM, RBXL, RBXLX, RBXMX
                                                                            
]]

if not game:IsLoaded() then game.Loaded:Wait() end

--                                                                        
-- WHITELIST GATE   MCHLERN PROJECT PAID SCRIPT
--                                                                        
local _WHITELIST = {
    10955292268,
}

local _userId  = game:GetService("Players").LocalPlayer.UserId
local _allowed = false
for _, id in ipairs(_WHITELIST) do
    if id == _userId then _allowed = true; break end
end

if not _allowed then
    warn("[MCHLERN PROJECT] Akses ditolak. Script ini hanya untuk pengguna yang sudah terdaftar.")
    return
end

--                                                                        
-- SERVICES & UTILITIES
--                                                                        
local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService      = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local InsertService    = game:GetService("InsertService")
local CoreGui          = game:GetService("CoreGui")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local CoreDest    = pcall(function() return CoreGui.Name end) and CoreGui or LocalPlayer:WaitForChild("PlayerGui")

_G.MCHLERN_RAW_SOURCES = _G.MCHLERN_RAW_SOURCES or {}

local ICONS = {
    PACKAGE       = "rbxassetid://10709791437",
    SEARCH        = "rbxassetid://10709796118",
    CLOSE         = "rbxassetid://10709790644",
    MINIMIZE      = "rbxassetid://10709790387",
    CHEVRON_RIGHT = "rbxassetid://10709782525",
    CHEVRON_LEFT  = "rbxassetid://10709782230",
    BELL          = "rbxassetid://10709791160",
    GAMEPAD       = "rbxassetid://10709790082",
    FILE          = "rbxassetid://10709790948",
    DOWNLOAD      = "rbxassetid://10709791283",
    CHECK         = "rbxassetid://10709790240",
    ALERT         = "rbxassetid://10709790520",
    FOLDER        = "rbxassetid://10709790172",
    REFRESH       = "rbxassetid://10709793382",
    SETTINGS      = "rbxassetid://10709780517",
    REPLACE       = "rbxassetid://10709793230",
    PAINT         = "rbxassetid://10709791334",
}

--                                                                        
-- HTTP REQUEST UTILITY
--                                                                        
local function httpRequest(url, method, headers, data)
    method  = method or "GET"
    headers = headers or {}
    headers["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    local requestFuncs = {
        function() if syn and syn.request then local r = syn.request({Url=url,Method=method,Headers=headers,Body=data}); return r.Body, r.StatusCode end end,
        function() if request then local r = request({Url=url,Method=method,Headers=headers,Body=data}); return r.Body, r.StatusCode end end,
        function() if http_request then local r = http_request({Url=url,Method=method,Headers=headers,Body=data}); return r.Body, r.StatusCode end end,
        function() if fluxus and fluxus.request then local r = fluxus.request({Url=url,Method=method,Headers=headers,Body=data}); return r.Body, r.StatusCode end end,
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
-- CORE IMPORTER LOGIC (Simplified Parser & Insertion)
--                                                                        
local function Buffer(str)
    local Stream = { Offset = 0, Source = str, Length = string.len(str) }
    function Stream:read(len)
        len = len or 1
        local dat = string.sub(self.Source, self.Offset + 1, self.Offset + len)
        self.Offset = math.clamp(self.Offset + len, 0, self.Length)
        return dat
    end
    function Stream:readNumber(fmt)
        local chunk = self:read(string.packsize(fmt))
        return string.unpack(fmt, chunk)
    end
    return Stream
end

local slFolder    = ReplicatedStorage:FindFirstChild("StudioLiteFolder")
local serverFuncs = slFolder and slFolder:FindFirstChild("ServerFunctions")

local function triggerServerLoad(idStr)
    if not serverFuncs or not idStr or idStr == "" then return end
    local id = tostring(idStr):match("%d+")
    if id then pcall(function() serverFuncs:InvokeServer("LoadMeshToRuntimeMeshes", tonumber(id)) end) end
end

local SVC_MAP = {
    Workspace = workspace, ReplicatedStorage = ReplicatedStorage,
    Lighting = game:GetService("Lighting"), ServerScriptService = ReplicatedStorage,
    ServerStorage = ReplicatedStorage
}

local function insertObjects(objects, isRbxl)
    local count = 0
    for _, obj in ipairs(objects) do
        pcall(function()
            if isRbxl then
                local target = SVC_MAP[obj.ClassName] or SVC_MAP[obj.Name] or workspace
                local children = obj:GetChildren()
                if #children > 0 then
                    for _, ch in ipairs(children) do ch.Parent = target; count = count + 1 end
                else
                    obj.Parent = workspace; count = count + 1
                end
            else
                obj.Parent = workspace; count = count + 1
            end
        end)
    end
    return count
end

local function loadFile(fileInfo)
    local isRbxl = fileInfo.ftype == "RBXL"
    if getcustomasset then
        local ok1, aid = pcall(getcustomasset, fileInfo.path)
        if ok1 and aid then
            local ok2, objs = pcall(function() return game:GetObjects(aid) end)
            if ok2 and objs and #objs > 0 then return true, insertObjects(objs, isRbxl) .. " object(s) loaded" end
        end
    end
    local ok3, o3 = pcall(function() return game:GetObjects("rbxasset://" .. fileInfo.path) end)
    if ok3 and o3 and #o3 > 0 then return true, insertObjects(o3, isRbxl) .. " object(s) loaded" end
    return false, "Gagal memuat file."
end

local function safeListFiles(p)
    if not listfiles then return nil end
    local ok, f = pcall(listfiles, p)
    return ok and f or nil
end

local function scanDeep(folder, depth, results, seen)
    if depth > 3 or seen[folder] then return end
    seen[folder] = true
    local list = safeListFiles(folder)
    if not list then return end
    for _, path in ipairs(list) do
        local name = path:match("([^/]+)$") or path
        local nLow = name:lower()
        if nLow:match("%.rbxlx?$") or nLow:match("%.rbxmx?$") then
            if not seen[path] then
                seen[path] = true
                table.insert(results, {name=name, path=path, ftype=nLow:match("%.rbxl") and "RBXL" or "RBXM", folder=folder})
            end
        elseif not name:match("%.[%a%d]+") then
            scanDeep(path, depth+1, results, seen)
        end
    end
end

local function scanAll()
    local results, seen = {}, {}
    local paths = {"workspace", "Delta/workspace", "delta/workspace", "Android/Delta/workspace", ".", ""}
    for _, p in ipairs(paths) do scanDeep(p, 0, results, seen) end
    return results
end

--                                                                        
-- UI CREATION (LANDSCAPE)
--                                                                        
if CoreDest:FindFirstChild("MCHLERNImporterUI") then CoreDest:FindFirstChild("MCHLERNImporterUI"):Destroy() end

local UI = Instance.new("ScreenGui", CoreDest)
UI.Name = "MCHLERNImporterUI"
UI.ResetOnSpawn = false
UI.IgnoreGuiInset = true

local Main = Instance.new("Frame", UI)
Main.Name = "MainFrame"
Main.Size = UDim2.new(0, 640, 0, 400)
Main.Position = UDim2.new(0.5, -320, 0.5, -200)
Main.BackgroundColor3 = Color3.fromRGB(6, 18, 11)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", Main).Color = Color3.fromRGB(75, 205, 105)

-- NOTIFICATION SYSTEM
local function notify(title, msg, color)
    color = color or Color3.fromRGB(200, 200, 210)
    local notif = Instance.new("Frame", UI)
    notif.Size = UDim2.new(0, 220, 0, 42); notif.Position = UDim2.new(1, -230, 1, -55)
    notif.BackgroundColor3 = Color3.fromRGB(7, 29, 14); notif.BorderSizePixel = 0
    Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", notif).Color = color
    
    local t = Instance.new("TextLabel", notif)
    t.Size = UDim2.new(1, -28, 0, 14); t.Position = UDim2.new(0, 26, 0, 4)
    t.BackgroundTransparency = 1; t.Text = title; t.TextColor3 = Color3.fromRGB(205, 255, 190)
    t.Font = Enum.Font.GothamBold; t.TextSize = 10; t.TextXAlignment = Enum.TextXAlignment.Left

    local d = Instance.new("TextLabel", notif)
    d.Size = UDim2.new(1, -12, 0, 16); d.Position = UDim2.new(0, 8, 0, 18)
    d.BackgroundTransparency = 1; d.Text = msg; d.TextColor3 = Color3.fromRGB(135, 195, 140)
    d.Font = Enum.Font.Gotham; d.TextSize = 8; d.TextXAlignment = Enum.TextXAlignment.Left; d.TextWrapped = true

    task.spawn(function()
        task.wait(2.5)
        for i = 1, 10 do notif.BackgroundTransparency = i/10; t.TextTransparency = i/10; d.TextTransparency = i/10; task.wait(0.02) end
        notif:Destroy()
    end)
end

-- TITLE BAR
local TitleBar = Instance.new("Frame", Main)
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = Color3.fromRGB(7, 45, 21)
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 8)

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

local TitleText = Instance.new("TextLabel", TitleBar)
TitleText.Size = UDim2.new(1, -90, 1, 0); TitleText.Position = UDim2.new(0, 12, 0, 0)
TitleText.BackgroundTransparency = 1; TitleText.Text = "MCHLERN PROJECT V2 - LANDSCAPE EDITION " .. string.char(240,159,145,145)
TitleText.TextColor3 = Color3.fromRGB(215, 255, 205); TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 12; TitleText.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size = UDim2.new(0, 30, 0, 30); CloseBtn.Position = UDim2.new(1, -35, 0.5, -15)
CloseBtn.BackgroundTransparency = 1; CloseBtn.Text = "X"; CloseBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextSize = 14
CloseBtn.MouseButton1Click:Connect(function() UI:Destroy() end)

-- SIDEBAR
local Sidebar = Instance.new("Frame", Main)
Sidebar.Size = UDim2.new(0, 130, 1, -36); Sidebar.Position = UDim2.new(0, 0, 0, 36)
Sidebar.BackgroundColor3 = Color3.fromRGB(8, 25, 14); Sidebar.BorderSizePixel = 0
Instance.new("UIStroke", Sidebar).Color = Color3.fromRGB(20, 60, 30)

-- CONTENT AREA
local ContentArea = Instance.new("Frame", Main)
ContentArea.Size = UDim2.new(1, -130, 1, -36); ContentArea.Position = UDim2.new(0, 130, 0, 36)
ContentArea.BackgroundTransparency = 1

local Tabs = {}
local function createTabBtn(name, iconId, yOffset)
    local btn = Instance.new("TextButton", Sidebar)
    btn.Size = UDim2.new(1, 0, 0, 45); btn.Position = UDim2.new(0, 0, 0, yOffset)
    btn.BackgroundColor3 = Color3.fromRGB(10, 35, 20); btn.BorderSizePixel = 0
    btn.Text = "      " .. name; btn.TextColor3 = Color3.fromRGB(180, 220, 180)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 10; btn.TextXAlignment = Enum.TextXAlignment.Left
    
    local icon = Instance.new("ImageLabel", btn)
    icon.Size = UDim2.new(0, 16, 0, 16); icon.Position = UDim2.new(0, 10, 0.5, -8)
    icon.BackgroundTransparency = 1; icon.Image = iconId; icon.ImageColor3 = Color3.fromRGB(150, 200, 150)
    
    local frame = Instance.new("Frame", ContentArea)
    frame.Size = UDim2.new(1, 0, 1, 0); frame.BackgroundTransparency = 1; frame.Visible = false
    
    table.insert(Tabs, {Btn = btn, Frame = frame})
    btn.MouseButton1Click:Connect(function()
        for _, t in ipairs(Tabs) do
            t.Frame.Visible = false
            t.Btn.BackgroundColor3 = Color3.fromRGB(10, 35, 20)
            t.Btn.TextColor3 = Color3.fromRGB(180, 220, 180)
        end
        frame.Visible = true
        btn.BackgroundColor3 = Color3.fromRGB(20, 65, 35)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
    return frame
end

local TabImporter = createTabBtn("IMPORTER", ICONS.DOWNLOAD, 0)
local TabConfig   = createTabBtn("CONFIG", ICONS.SETTINGS, 45)
local TabReplacer = createTabBtn("REPLACER", ICONS.REPLACE, 90)
local TabRemake   = createTabBtn("REMAKE GUI", ICONS.PAINT, 135)

-- =========================================================================
-- TAB 1: IMPORTER
-- =========================================================================
local ImporterScroll = Instance.new("ScrollingFrame", TabImporter)
ImporterScroll.Size = UDim2.new(1, -20, 1, -60); ImporterScroll.Position = UDim2.new(0, 10, 0, 50)
ImporterScroll.BackgroundTransparency = 1; ImporterScroll.ScrollBarThickness = 4
local IListLayout = Instance.new("UIListLayout", ImporterScroll)
IListLayout.Padding = UDim.new(0, 5)

local ScanFilesBtn = Instance.new("TextButton", TabImporter)
ScanFilesBtn.Size = UDim2.new(1, -20, 0, 30); ScanFilesBtn.Position = UDim2.new(0, 10, 0, 10)
ScanFilesBtn.BackgroundColor3 = Color3.fromRGB(30, 100, 50)
Instance.new("UICorner", ScanFilesBtn).CornerRadius = UDim.new(0, 6)
ScanFilesBtn.Text = "SCAN FILES"; ScanFilesBtn.TextColor3 = Color3.fromRGB(255,255,255); ScanFilesBtn.Font = Enum.Font.GothamBold

ScanFilesBtn.MouseButton1Click:Connect(function()
    ScanFilesBtn.Text = "SCANNING..."
    for _, c in ipairs(ImporterScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    task.spawn(function()
        local files = scanAll()
        for _, f in ipairs(files) do
            local card = Instance.new("Frame", ImporterScroll)
            card.Size = UDim2.new(1, 0, 0, 40); card.BackgroundColor3 = Color3.fromRGB(12, 35, 20)
            Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)
            
            local lbl = Instance.new("TextLabel", card)
            lbl.Size = UDim2.new(1, -80, 1, 0); lbl.Position = UDim2.new(0, 10, 0, 0)
            lbl.BackgroundTransparency = 1; lbl.Text = "["..f.ftype.."] " .. f.name
            lbl.TextColor3 = Color3.fromRGB(220, 255, 220); lbl.Font = Enum.Font.GothamBold; lbl.TextXAlignment = Enum.TextXAlignment.Left
            
            local ins = Instance.new("TextButton", card)
            ins.Size = UDim2.new(0, 60, 0, 24); ins.Position = UDim2.new(1, -70, 0.5, -12)
            ins.BackgroundColor3 = Color3.fromRGB(40, 120, 60); ins.Text = "INSERT"
            ins.TextColor3 = Color3.fromRGB(255,255,255); ins.Font = Enum.Font.GothamBold
            Instance.new("UICorner", ins).CornerRadius = UDim.new(0, 4)
            
            ins.MouseButton1Click:Connect(function()
                ins.Text = "..."
                local ok, msg = loadFile(f)
                if ok then ins.Text = "DONE"; notify("Success", f.name.." dimuat", Color3.fromRGB(100,255,100))
                else ins.Text = "FAIL"; notify("Error", msg, Color3.fromRGB(255,100,100)) end
                task.wait(2); ins.Text = "INSERT"
            end)
        end
        ScanFilesBtn.Text = "SCAN FILES"
        notify("Scan Complete", "Ditemukan " .. #files .. " file.", Color3.fromRGB(200,200,255))
    end)
end)

-- =========================================================================
-- TAB 2: CONFIG
-- =========================================================================
local function createConfigBtn(title, yOffset, callback)
    local btn = Instance.new("TextButton", TabConfig)
    btn.Size = UDim2.new(1, -20, 0, 40); btn.Position = UDim2.new(0, 10, 0, yOffset)
    btn.BackgroundColor3 = Color3.fromRGB(15, 45, 25)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.Text = title; btn.TextColor3 = Color3.fromRGB(220, 255, 220); btn.Font = Enum.Font.GothamBold
    btn.MouseButton1Click:Connect(callback)
end

createConfigBtn("DISABLE ALL SHADOWS", 20, function()
    local count = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("MeshPart") then
            if obj.CastShadow then obj.CastShadow = false; count = count + 1 end
        end
    end
    notify("Config", "Berhasil mematikan shadow pada " .. count .. " part.", Color3.fromRGB(100,255,100))
end)

createConfigBtn("ANCHOR ALL PARTS", 70, function()
    local count = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj.Anchored then
            obj.Anchored = true; count = count + 1
        end
    end
    notify("Config", "Berhasil meng-anchor " .. count .. " part.", Color3.fromRGB(100,255,100))
end)

-- =========================================================================
-- TAB 3: REPLACER
-- =========================================================================
local RepObjLbl = Instance.new("TextLabel", TabReplacer)
RepObjLbl.Size = UDim2.new(1, -20, 0, 20); RepObjLbl.Position = UDim2.new(0, 10, 0, 10)
RepObjLbl.BackgroundTransparency = 1; RepObjLbl.Text = "OBJECT REPLACER"; RepObjLbl.TextColor3 = Color3.fromRGB(200,255,200); RepObjLbl.Font = Enum.Font.GothamBold; RepObjLbl.TextXAlignment = Enum.TextXAlignment.Left

local TargetBox = Instance.new("TextBox", TabReplacer)
TargetBox.Size = UDim2.new(0.5, -15, 0, 30); TargetBox.Position = UDim2.new(0, 10, 0, 35)
TargetBox.BackgroundColor3 = Color3.fromRGB(10,30,15); TargetBox.TextColor3 = Color3.fromRGB(255,255,255)
TargetBox.PlaceholderText = "Target Name (Yang mau diganti)"; TargetBox.Font = Enum.Font.Gotham
Instance.new("UICorner", TargetBox).CornerRadius = UDim.new(0, 4)

local ReplaceBox = Instance.new("TextBox", TabReplacer)
ReplaceBox.Size = UDim2.new(0.5, -15, 0, 30); ReplaceBox.Position = UDim2.new(0.5, 5, 0, 35)
ReplaceBox.BackgroundColor3 = Color3.fromRGB(10,30,15); ReplaceBox.TextColor3 = Color3.fromRGB(255,255,255)
ReplaceBox.PlaceholderText = "Replacement Name (Pengganti)"; ReplaceBox.Font = Enum.Font.Gotham
Instance.new("UICorner", ReplaceBox).CornerRadius = UDim.new(0, 4)

local ExecRepBtn = Instance.new("TextButton", TabReplacer)
ExecRepBtn.Size = UDim2.new(1, -20, 0, 30); ExecRepBtn.Position = UDim2.new(0, 10, 0, 75)
ExecRepBtn.BackgroundColor3 = Color3.fromRGB(30, 100, 50); ExecRepBtn.Text = "REPLACE OBJECTS"
ExecRepBtn.TextColor3 = Color3.fromRGB(255,255,255); ExecRepBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", ExecRepBtn).CornerRadius = UDim.new(0, 6)

ExecRepBtn.MouseButton1Click:Connect(function()
    local tName = TargetBox.Text; local rName = ReplaceBox.Text
    if tName == "" or rName == "" then notify("Error", "Isi kedua kolom nama!", Color3.fromRGB(255,100,100)); return end
    
    local replacementTemp = nil
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == rName then replacementTemp = obj; break end
    end
    if not replacementTemp then notify("Error", "Object pengganti tidak ditemukan di workspace!", Color3.fromRGB(255,100,100)); return end

    local count = 0
    local targets = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == tName and obj ~= replacementTemp then table.insert(targets, obj) end
    end

    for _, target in ipairs(targets) do
        local clone = replacementTemp:Clone()
        if clone:IsA("BasePart") and target:IsA("BasePart") then
            clone.CFrame = target.CFrame
            clone.Size = target.Size
        elseif clone:IsA("Model") and target:IsA("Model") then
            if clone.PrimaryPart and target.PrimaryPart then
                clone:SetPrimaryPartCFrame(target.PrimaryPart.CFrame)
            else
                clone:MoveTo(target:GetModelCFrame().Position)
            end
        end
        clone.Parent = target.Parent
        target:Destroy()
        count = count + 1
    end
    notify("Replacer", "Berhasil mengganti " .. count .. " object.", Color3.fromRGB(100,255,100))
end)

local RepDecLbl = Instance.new("TextLabel", TabReplacer)
RepDecLbl.Size = UDim2.new(1, -20, 0, 20); RepDecLbl.Position = UDim2.new(0, 10, 0, 120)
RepDecLbl.BackgroundTransparency = 1; RepDecLbl.Text = "DECAL REPLACER"; RepDecLbl.TextColor3 = Color3.fromRGB(200,255,200); RepDecLbl.Font = Enum.Font.GothamBold; RepDecLbl.TextXAlignment = Enum.TextXAlignment.Left

local DecalBox = Instance.new("TextBox", TabReplacer)
DecalBox.Size = UDim2.new(1, -20, 0, 30); DecalBox.Position = UDim2.new(0, 10, 0, 145)
DecalBox.BackgroundColor3 = Color3.fromRGB(10,30,15); DecalBox.TextColor3 = Color3.fromRGB(255,255,255)
DecalBox.PlaceholderText = "New Decal ID (e.g. 1234567890)"; DecalBox.Font = Enum.Font.Gotham
Instance.new("UICorner", DecalBox).CornerRadius = UDim.new(0, 4)

local ExecDecBtn = Instance.new("TextButton", TabReplacer)
ExecDecBtn.Size = UDim2.new(0.5, -15, 0, 30); ExecDecBtn.Position = UDim2.new(0, 10, 0, 185)
ExecDecBtn.BackgroundColor3 = Color3.fromRGB(30, 100, 50); ExecDecBtn.Text = "REPLACE DECALS"
ExecDecBtn.TextColor3 = Color3.fromRGB(255,255,255); ExecDecBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", ExecDecBtn).CornerRadius = UDim.new(0, 6)

local DelDecBtn = Instance.new("TextButton", TabReplacer)
DelDecBtn.Size = UDim2.new(0.5, -15, 0, 30); DelDecBtn.Position = UDim2.new(0.5, 5, 0, 185)
DelDecBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40); DelDecBtn.Text = "DELETE ALL DECALS"
DelDecBtn.TextColor3 = Color3.fromRGB(255,255,255); DelDecBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", DelDecBtn).CornerRadius = UDim.new(0, 6)

ExecDecBtn.MouseButton1Click:Connect(function()
    local id = DecalBox.Text:match("%d+")
    if not id then notify("Error", "Masukkan ID Decal yang valid!", Color3.fromRGB(255,100,100)); return end
    local rbxId = "rbxassetid://" .. id
    local count = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Decal") or obj:IsA("Texture") then
            obj.Texture = rbxId; count = count + 1
        end
    end
    notify("Replacer", "Berhasil mengganti " .. count .. " decal.", Color3.fromRGB(100,255,100))
end)

DelDecBtn.MouseButton1Click:Connect(function()
    local count = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Decal") or obj:IsA("Texture") then
            obj:Destroy(); count = count + 1
        end
    end
    notify("Replacer", "Berhasil menghapus " .. count .. " decal.", Color3.fromRGB(100,255,100))
end)

-- =========================================================================
-- TAB 4: REMAKE GUI
-- =========================================================================
local RmkLbl = Instance.new("TextLabel", TabRemake)
RmkLbl.Size = UDim2.new(1, -20, 0, 20); RmkLbl.Position = UDim2.new(0, 10, 0, 10)
RmkLbl.BackgroundTransparency = 1; RmkLbl.Text = "GUI COLOR MODIFIER (PlayerGui & StarterGui)"; RmkLbl.TextColor3 = Color3.fromRGB(200,255,200); RmkLbl.Font = Enum.Font.GothamBold; RmkLbl.TextXAlignment = Enum.TextXAlignment.Left

local ColorBox = Instance.new("TextBox", TabRemake)
ColorBox.Size = UDim2.new(1, -20, 0, 30); ColorBox.Position = UDim2.new(0, 10, 0, 35)
ColorBox.BackgroundColor3 = Color3.fromRGB(10,30,15); ColorBox.TextColor3 = Color3.fromRGB(255,255,255)
ColorBox.PlaceholderText = "RGB Color (contoh: 255, 0, 0) atau Hex (#FF0000)"; ColorBox.Font = Enum.Font.Gotham
Instance.new("UICorner", ColorBox).CornerRadius = UDim.new(0, 4)

local function parseColor(txt)
    local r,g,b = txt:match("(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
    if r and g and b then return Color3.fromRGB(tonumber(r)/255, tonumber(g)/255, tonumber(b)/255) end
    if txt:match("^#") then
        local hex = txt:gsub("#","")
        if #hex == 6 then
            return Color3.fromRGB(tonumber(hex:sub(1,2),16)/255, tonumber(hex:sub(3,4),16)/255, tonumber(hex:sub(5,6),16)/255)
        end
    end
    return nil
end

local ApplyBgBtn = Instance.new("TextButton", TabRemake)
ApplyBgBtn.Size = UDim2.new(0.5, -15, 0, 30); ApplyBgBtn.Position = UDim2.new(0, 10, 0, 75)
ApplyBgBtn.BackgroundColor3 = Color3.fromRGB(30, 100, 50); ApplyBgBtn.Text = "UBAH SEMUA BACKGROUND"
ApplyBgBtn.TextColor3 = Color3.fromRGB(255,255,255); ApplyBgBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", ApplyBgBtn).CornerRadius = UDim.new(0, 6)

local ApplyTxtBtn = Instance.new("TextButton", TabRemake)
ApplyTxtBtn.Size = UDim2.new(0.5, -15, 0, 30); ApplyTxtBtn.Position = UDim2.new(0.5, 5, 0, 75)
ApplyTxtBtn.BackgroundColor3 = Color3.fromRGB(30, 100, 50); ApplyTxtBtn.Text = "UBAH SEMUA TEKS"
ApplyTxtBtn.TextColor3 = Color3.fromRGB(255,255,255); ApplyTxtBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", ApplyTxtBtn).CornerRadius = UDim.new(0, 6)

local function applyColorToGuis(propName)
    local col = parseColor(ColorBox.Text)
    if not col then notify("Error", "Format warna salah! Gunakan: 255, 0, 0", Color3.fromRGB(255,100,100)); return end
    
    local pgui = LocalPlayer:FindFirstChild("PlayerGui")
    local sgui = game:GetService("StarterGui")
    local count = 0

    local function scanAndApply(parent)
        if not parent then return end
        for _, obj in ipairs(parent:GetDescendants()) do
            if obj:IsA("GuiObject") then
                pcall(function()
                    if propName == "Background" and (obj:IsA("Frame") or obj:IsA("ScrollingFrame") or obj:IsA("TextButton") or obj:IsA("TextBox") or obj:IsA("TextLabel")) then
                        if obj.BackgroundTransparency < 1 then
                            obj.BackgroundColor3 = col; count = count + 1
                        end
                    elseif propName == "Text" and (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then
                        obj.TextColor3 = col; count = count + 1
                    end
                end)
            end
        end
    end

    scanAndApply(pgui)
    scanAndApply(sgui)
    
    notify("Remake GUI", "Berhasil mengubah " .. count .. " elemen GUI.", Color3.fromRGB(100,255,100))
end

ApplyBgBtn.MouseButton1Click:Connect(function() applyColorToGuis("Background") end)
ApplyTxtBtn.MouseButton1Click:Connect(function() applyColorToGuis("Text") end)

-- Set Default Tab
Tabs[1].Btn.BackgroundColor3 = Color3.fromRGB(20, 65, 35)
Tabs[1].Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
Tabs[1].Frame.Visible = true

print("[MCHLERN PROJECT] IMPORTER v2.0 LOADED")
