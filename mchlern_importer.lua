--[[
                                                                            
       MCHLERN PROJECT IMPORTER v2.1 - Landscape Edition
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
-- CORE IMPORTER LOGIC (Simplified Parser & Insertion)
--                                                                        
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
-- UI CREATION
--                                                                        
if CoreDest:FindFirstChild("MCHLERNImporterUI") then CoreDest:FindFirstChild("MCHLERNImporterUI"):Destroy() end

local UI = Instance.new("ScreenGui", CoreDest)
UI.Name = "MCHLERNImporterUI"
UI.ResetOnSpawn = false
UI.IgnoreGuiInset = true

-- FLOATING TOGGLE BUTTON (Untuk buka/tutup panel)
local ToggleFrame = Instance.new("Frame", UI)
ToggleFrame.Name = "ToggleFrame"
ToggleFrame.Size = UDim2.new(0, 36, 0, 36)
ToggleFrame.Position = UDim2.new(0, 10, 0, 50)
ToggleFrame.BackgroundColor3 = Color3.fromRGB(10, 50, 25)
ToggleFrame.BorderSizePixel = 0
ToggleFrame.Active = true
Instance.new("UICorner", ToggleFrame).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", ToggleFrame).Color = Color3.fromRGB(100, 255, 145)

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


local Main = Instance.new("Frame", UI)
Main.Name = "MainFrame"
Main.Size = UDim2.new(0, 640, 0, 420)
Main.Position = UDim2.new(0.5, -320, 0.5, -210)
Main.BackgroundColor3 = Color3.fromRGB(6, 18, 11)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", Main).Color = Color3.fromRGB(75, 205, 105)

ToggleBtn.MouseButton1Click:Connect(function()
    Main.Visible = not Main.Visible
    ToggleIcon.Image = Main.Visible and ICONS.CHEVRON_RIGHT or ICONS.CHEVRON_LEFT
end)

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

local dragToggleM, dragStartM, startPosM
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragToggleM = true; dragStartM = input.Position; startPosM = Main.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragToggleM and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStartM
        Main.Position = UDim2.new(startPosM.X.Scale, startPosM.X.Offset + delta.X, startPosM.Y.Scale, startPosM.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragToggleM = false end
end)

local TitleText = Instance.new("TextLabel", TitleBar)
TitleText.Size = UDim2.new(1, -90, 1, 0); TitleText.Position = UDim2.new(0, 12, 0, 0)
TitleText.BackgroundTransparency = 1; TitleText.Text = "MCHLERN PROJECT V2.1 - LANDSCAPE EDITION " .. string.char(240,159,145,145)
TitleText.TextColor3 = Color3.fromRGB(215, 255, 205); TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 12; TitleText.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size = UDim2.new(0, 30, 0, 30); CloseBtn.Position = UDim2.new(1, -35, 0.5, -15)
CloseBtn.BackgroundTransparency = 1; CloseBtn.Text = "X"; CloseBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextSize = 14
CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false; ToggleIcon.Image = ICONS.CHEVRON_RIGHT end)

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
RepObjLbl.Size = UDim2.new(1, -20, 0, 20); RepObjLbl.Position = UDim2.new(0, 10, 0, 5)
RepObjLbl.BackgroundTransparency = 1; RepObjLbl.Text = "OBJECT REPLACER"; RepObjLbl.TextColor3 = Color3.fromRGB(200,255,200); RepObjLbl.Font = Enum.Font.GothamBold; RepObjLbl.TextXAlignment = Enum.TextXAlignment.Left

-- Target Label & Box
local TgtLbl = Instance.new("TextLabel", TabReplacer)
TgtLbl.Size = UDim2.new(0.5, -15, 0, 15); TgtLbl.Position = UDim2.new(0, 10, 0, 30)
TgtLbl.BackgroundTransparency = 1; TgtLbl.Text = "Ketik Nama Target (Yang akan diganti):"; TgtLbl.TextColor3 = Color3.fromRGB(150,200,150)
TgtLbl.Font = Enum.Font.Gotham; TgtLbl.TextSize = 10; TgtLbl.TextXAlignment = Enum.TextXAlignment.Left

local TargetBox = Instance.new("TextBox", TabReplacer)
TargetBox.Size = UDim2.new(0.5, -15, 0, 26); TargetBox.Position = UDim2.new(0, 10, 0, 47)
TargetBox.BackgroundColor3 = Color3.fromRGB(10,30,15); TargetBox.TextColor3 = Color3.fromRGB(255,255,255)
TargetBox.PlaceholderText = "Target Name..."; TargetBox.Font = Enum.Font.Gotham; TargetBox.TextSize = 11
Instance.new("UICorner", TargetBox).CornerRadius = UDim.new(0, 4)

-- Replace Label & Box
local RepLbl = Instance.new("TextLabel", TabReplacer)
RepLbl.Size = UDim2.new(0.5, -15, 0, 15); RepLbl.Position = UDim2.new(0.5, 5, 0, 30)
RepLbl.BackgroundTransparency = 1; RepLbl.Text = "Ketik Nama Pengganti (Part/Mesh Baru):"; RepLbl.TextColor3 = Color3.fromRGB(150,200,150)
RepLbl.Font = Enum.Font.Gotham; RepLbl.TextSize = 10; RepLbl.TextXAlignment = Enum.TextXAlignment.Left

local ReplaceBox = Instance.new("TextBox", TabReplacer)
ReplaceBox.Size = UDim2.new(0.5, -15, 0, 26); ReplaceBox.Position = UDim2.new(0.5, 5, 0, 47)
ReplaceBox.BackgroundColor3 = Color3.fromRGB(10,30,15); ReplaceBox.TextColor3 = Color3.fromRGB(255,255,255)
ReplaceBox.PlaceholderText = "Replacement Name..."; ReplaceBox.Font = Enum.Font.Gotham; ReplaceBox.TextSize = 11
Instance.new("UICorner", ReplaceBox).CornerRadius = UDim.new(0, 4)

local ExecRepBtn = Instance.new("TextButton", TabReplacer)
ExecRepBtn.Size = UDim2.new(1, -20, 0, 28); ExecRepBtn.Position = UDim2.new(0, 10, 0, 80)
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
            clone.CFrame = target.CFrame; clone.Size = target.Size
        elseif clone:IsA("Model") and target:IsA("Model") then
            if clone.PrimaryPart and target.PrimaryPart then clone:SetPrimaryPartCFrame(target.PrimaryPart.CFrame)
            else clone:MoveTo(target:GetModelCFrame().Position) end
        end
        clone.Parent = target.Parent; target:Destroy(); count = count + 1
    end
    notify("Replacer", "Berhasil mengganti " .. count .. " object.", Color3.fromRGB(100,255,100))
end)

-- DECAL REPLACER
local RepDecLbl = Instance.new("TextLabel", TabReplacer)
RepDecLbl.Size = UDim2.new(1, -20, 0, 20); RepDecLbl.Position = UDim2.new(0, 10, 0, 125)
RepDecLbl.BackgroundTransparency = 1; RepDecLbl.Text = "DECAL REPLACER"; RepDecLbl.TextColor3 = Color3.fromRGB(200,255,200); RepDecLbl.Font = Enum.Font.GothamBold; RepDecLbl.TextXAlignment = Enum.TextXAlignment.Left

local ScanDecBtn = Instance.new("TextButton", TabReplacer)
ScanDecBtn.Size = UDim2.new(0.4, 0, 0, 26); ScanDecBtn.Position = UDim2.new(0, 10, 0, 150)
ScanDecBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 120); ScanDecBtn.Text = "SCAN DECALS"
ScanDecBtn.TextColor3 = Color3.fromRGB(255,255,255); ScanDecBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", ScanDecBtn).CornerRadius = UDim.new(0, 4)

local DecInfoLbl = Instance.new("TextLabel", TabReplacer)
DecInfoLbl.Size = UDim2.new(0.6, -20, 0, 26); DecInfoLbl.Position = UDim2.new(0.4, 15, 0, 150)
DecInfoLbl.BackgroundTransparency = 1; DecInfoLbl.Text = "Belum discan (0 Decal ditemukan)"
DecInfoLbl.TextColor3 = Color3.fromRGB(150, 200, 255); DecInfoLbl.Font = Enum.Font.Gotham; DecInfoLbl.TextXAlignment = Enum.TextXAlignment.Left

local totalDecalsScanned = 0
ScanDecBtn.MouseButton1Click:Connect(function()
    totalDecalsScanned = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Decal") or obj:IsA("Texture") then totalDecalsScanned = totalDecalsScanned + 1 end
    end
    DecInfoLbl.Text = "Ditemukan " .. totalDecalsScanned .. " Decal/Texture di Workspace."
    notify("Scan Selesai", totalDecalsScanned .. " Decal terdeteksi.", Color3.fromRGB(150, 200, 255))
end)

local DecalInputLbl = Instance.new("TextLabel", TabReplacer)
DecalInputLbl.Size = UDim2.new(1, -20, 0, 15); DecalInputLbl.Position = UDim2.new(0, 10, 0, 185)
DecalInputLbl.BackgroundTransparency = 1; DecalInputLbl.Text = "Masukkan ID Decal Baru:"; DecalInputLbl.TextColor3 = Color3.fromRGB(150,200,150)
DecalInputLbl.Font = Enum.Font.Gotham; DecalInputLbl.TextSize = 10; DecalInputLbl.TextXAlignment = Enum.TextXAlignment.Left

local DecalBox = Instance.new("TextBox", TabReplacer)
DecalBox.Size = UDim2.new(1, -20, 0, 26); DecalBox.Position = UDim2.new(0, 10, 0, 205)
DecalBox.BackgroundColor3 = Color3.fromRGB(10,30,15); DecalBox.TextColor3 = Color3.fromRGB(255,255,255)
DecalBox.PlaceholderText = "ID Decal (contoh: 1234567890)"; DecalBox.Font = Enum.Font.Gotham
Instance.new("UICorner", DecalBox).CornerRadius = UDim.new(0, 4)

local ExecDecBtn = Instance.new("TextButton", TabReplacer)
ExecDecBtn.Size = UDim2.new(0.5, -15, 0, 28); ExecDecBtn.Position = UDim2.new(0, 10, 0, 240)
ExecDecBtn.BackgroundColor3 = Color3.fromRGB(30, 100, 50); ExecDecBtn.Text = "REPLACE DECALS"
ExecDecBtn.TextColor3 = Color3.fromRGB(255,255,255); ExecDecBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", ExecDecBtn).CornerRadius = UDim.new(0, 6)

local DelDecBtn = Instance.new("TextButton", TabReplacer)
DelDecBtn.Size = UDim2.new(0.5, -15, 0, 28); DelDecBtn.Position = UDim2.new(0.5, 5, 0, 240)
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
local selectedGuiObj = nil
local activeColor    = Color3.fromRGB(255, 255, 255)

local ScanGuiBtn = Instance.new("TextButton", TabRemake)
ScanGuiBtn.Size = UDim2.new(0.4, 0, 0, 26); ScanGuiBtn.Position = UDim2.new(0, 10, 0, 10)
ScanGuiBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 120); ScanGuiBtn.Text = "SCAN GUI (PLAYERGUI)"
ScanGuiBtn.TextColor3 = Color3.fromRGB(255,255,255); ScanGuiBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", ScanGuiBtn).CornerRadius = UDim.new(0, 4)

local SelectedGuiLbl = Instance.new("TextLabel", TabRemake)
SelectedGuiLbl.Size = UDim2.new(0.6, -20, 0, 26); SelectedGuiLbl.Position = UDim2.new(0.4, 15, 0, 10)
SelectedGuiLbl.BackgroundTransparency = 1; SelectedGuiLbl.Text = "Target GUI: SEMUA GUI"
SelectedGuiLbl.TextColor3 = Color3.fromRGB(255, 200, 150); SelectedGuiLbl.Font = Enum.Font.GothamBold; SelectedGuiLbl.TextXAlignment = Enum.TextXAlignment.Left

-- Left Area: Scroll List for GUIs
local GuiScroll = Instance.new("ScrollingFrame", TabRemake)
GuiScroll.Size = UDim2.new(0.4, 0, 0, 190); GuiScroll.Position = UDim2.new(0, 10, 0, 45)
GuiScroll.BackgroundTransparency = 1; GuiScroll.ScrollBarThickness = 4
local GListLayout = Instance.new("UIListLayout", GuiScroll)
GListLayout.Padding = UDim.new(0, 5)

ScanGuiBtn.MouseButton1Click:Connect(function()
    for _, c in ipairs(GuiScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    
    local allBtn = Instance.new("Frame", GuiScroll)
    allBtn.Size = UDim2.new(1, 0, 0, 25); allBtn.BackgroundColor3 = Color3.fromRGB(20, 50, 30)
    local allTxt = Instance.new("TextButton", allBtn)
    allTxt.Size = UDim2.new(1, 0, 1, 0); allTxt.BackgroundTransparency = 1; allTxt.Text = "  > SEMUA GUI"
    allTxt.TextColor3 = Color3.fromRGB(200, 255, 200); allTxt.Font = Enum.Font.GothamBold; allTxt.TextXAlignment = Enum.TextXAlignment.Left
    allTxt.MouseButton1Click:Connect(function()
        selectedGuiObj = nil
        SelectedGuiLbl.Text = "Target GUI: SEMUA GUI"
    end)

    local pgui = LocalPlayer:FindFirstChild("PlayerGui")
    if pgui then
        for _, gui in ipairs(pgui:GetChildren()) do
            if gui:IsA("ScreenGui") or gui:IsA("GuiObject") then
                local gBtn = Instance.new("Frame", GuiScroll)
                gBtn.Size = UDim2.new(1, 0, 0, 25); gBtn.BackgroundColor3 = Color3.fromRGB(15, 30, 20)
                local gTxt = Instance.new("TextButton", gBtn)
                gTxt.Size = UDim2.new(1, 0, 1, 0); gTxt.BackgroundTransparency = 1; gTxt.Text = "  " .. gui.Name
                gTxt.TextColor3 = Color3.fromRGB(255, 255, 255); gTxt.Font = Enum.Font.Gotham; gTxt.TextXAlignment = Enum.TextXAlignment.Left
                gTxt.TextTruncate = Enum.TextTruncate.AtEnd
                gTxt.MouseButton1Click:Connect(function()
                    selectedGuiObj = gui
                    SelectedGuiLbl.Text = "Target GUI: " .. gui.Name
                end)
            end
        end
    end
end)

-- Right Area: Color Palette
local PaletteArea = Instance.new("Frame", TabRemake)
PaletteArea.Size = UDim2.new(0.6, -20, 0, 190); PaletteArea.Position = UDim2.new(0.4, 15, 0, 45)
PaletteArea.BackgroundTransparency = 1

local ActiveColorViewer = Instance.new("Frame", PaletteArea)
ActiveColorViewer.Size = UDim2.new(1, 0, 0, 30); ActiveColorViewer.Position = UDim2.new(0, 0, 0, 0)
ActiveColorViewer.BackgroundColor3 = activeColor
Instance.new("UICorner", ActiveColorViewer).CornerRadius = UDim.new(0, 4)
local ActiveColorTxt = Instance.new("TextLabel", ActiveColorViewer)
ActiveColorTxt.Size = UDim2.new(1, 0, 1, 0); ActiveColorTxt.BackgroundTransparency = 1
ActiveColorTxt.Text = "Warna Terpilih"; ActiveColorTxt.TextColor3 = Color3.fromRGB(0,0,0); ActiveColorTxt.Font = Enum.Font.GothamBold

local GridFrame = Instance.new("ScrollingFrame", PaletteArea)
GridFrame.Size = UDim2.new(1, 0, 1, -40); GridFrame.Position = UDim2.new(0, 0, 0, 40)
GridFrame.BackgroundTransparency = 1; GridFrame.ScrollBarThickness = 4
local UIGrid = Instance.new("UIGridLayout", GridFrame)
UIGrid.CellSize = UDim2.new(0, 40, 0, 30)
UIGrid.CellPadding = UDim2.new(0, 5, 0, 5)
UIGrid.SortOrder = Enum.SortOrder.LayoutOrder

local PREDEFINED_COLORS = {
    Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 255, 0), Color3.fromRGB(0, 0, 255),
    Color3.fromRGB(255, 255, 0), Color3.fromRGB(0, 255, 255), Color3.fromRGB(255, 0, 255),
    Color3.fromRGB(255, 255, 255), Color3.fromRGB(150, 150, 150), Color3.fromRGB(30, 30, 30),
    Color3.fromRGB(255, 128, 0), Color3.fromRGB(255, 128, 255), Color3.fromRGB(128, 0, 255),
    Color3.fromRGB(128, 255, 0), Color3.fromRGB(0, 128, 128), Color3.fromRGB(139, 69, 19),
    Color3.fromRGB(255, 192, 203), Color3.fromRGB(0, 100, 0), Color3.fromRGB(0, 0, 128),
    Color3.fromRGB(50, 50, 50), Color3.fromRGB(100, 100, 255), Color3.fromRGB(255, 100, 100)
}

for i, col in ipairs(PREDEFINED_COLORS) do
    local cBtn = Instance.new("TextButton", GridFrame)
    cBtn.BackgroundColor3 = col; cBtn.Text = ""
    Instance.new("UICorner", cBtn).CornerRadius = UDim.new(0, 4)
    cBtn.MouseButton1Click:Connect(function()
        activeColor = col
        ActiveColorViewer.BackgroundColor3 = activeColor
        ActiveColorTxt.TextColor3 = (col.R + col.G + col.B) < 1.5 and Color3.new(1,1,1) or Color3.new(0,0,0)
    end)
end

-- Apply Buttons
local ApplyBgBtn = Instance.new("TextButton", TabRemake)
ApplyBgBtn.Size = UDim2.new(0.5, -15, 0, 30); ApplyBgBtn.Position = UDim2.new(0, 10, 0, 250)
ApplyBgBtn.BackgroundColor3 = Color3.fromRGB(30, 100, 50); ApplyBgBtn.Text = "TERAPKAN KE BACKGROUND"
ApplyBgBtn.TextColor3 = Color3.fromRGB(255,255,255); ApplyBgBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", ApplyBgBtn).CornerRadius = UDim.new(0, 6)

local ApplyTxtBtn = Instance.new("TextButton", TabRemake)
ApplyTxtBtn.Size = UDim2.new(0.5, -15, 0, 30); ApplyTxtBtn.Position = UDim2.new(0.5, 5, 0, 250)
ApplyTxtBtn.BackgroundColor3 = Color3.fromRGB(30, 100, 50); ApplyTxtBtn.Text = "TERAPKAN KE TEKS"
ApplyTxtBtn.TextColor3 = Color3.fromRGB(255,255,255); ApplyTxtBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", ApplyTxtBtn).CornerRadius = UDim.new(0, 6)

local function applyColorToTarget(propName)
    local targets = {}
    if selectedGuiObj then
        table.insert(targets, selectedGuiObj)
    else
        local pgui = LocalPlayer:FindFirstChild("PlayerGui")
        local sgui = game:GetService("StarterGui")
        if pgui then table.insert(targets, pgui) end
        if sgui then table.insert(targets, sgui) end
    end

    local count = 0
    for _, root in ipairs(targets) do
        for _, obj in ipairs(root:GetDescendants()) do
            if obj:IsA("GuiObject") then
                pcall(function()
                    if propName == "Background" and (obj:IsA("Frame") or obj:IsA("ScrollingFrame") or obj:IsA("TextButton") or obj:IsA("TextBox") or obj:IsA("TextLabel")) then
                        if obj.BackgroundTransparency < 1 then obj.BackgroundColor3 = activeColor; count = count + 1 end
                    elseif propName == "Text" and (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then
                        obj.TextColor3 = activeColor; count = count + 1
                    end
                end)
            end
        end
    end
    notify("Remake GUI", "Berhasil mewarnai " .. count .. " elemen.", Color3.fromRGB(100,255,100))
end

ApplyBgBtn.MouseButton1Click:Connect(function() applyColorToTarget("Background") end)
ApplyTxtBtn.MouseButton1Click:Connect(function() applyColorToTarget("Text") end)

-- Set Default Tab
Tabs[1].Btn.BackgroundColor3 = Color3.fromRGB(20, 65, 35)
Tabs[1].Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
Tabs[1].Frame.Visible = true

print("[MCHLERN PROJECT] IMPORTER v2.1 LOADED")
