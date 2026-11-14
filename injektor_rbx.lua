-- =======================================================
-- MCHLERN ENGINE TOOLS ROBLOX STUDIO LITE (v7.1 CLEAN SERVICE DISTRIBUTOR)
-- Fix 1: Menu Card Hitbox 100% Responsif (Tombol Toolbox & RBXM PASTI Kebuka)
-- Fix 2: Togle Anti-Geser (Kunci permanen di sisi layar, aman dari swipe kamera)
-- Fix 3: In-Game Code Editor (Bisa ketik, edit, save & execute script di HP)
-- Fix 4: Studio Lite Toolbar [EDIT CODE], [SAVE], [RUN], [COPY]
-- Fix 5: Dual Layer Source Recovery (0% Script Not Found)
-- Toggle Image Asset ID: 102337382069600
-- =======================================================

local HttpService        = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local CoreGui            = game:GetService("CoreGui")
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

if not game:IsLoaded() then
    pcall(function() game.Loaded:Wait() end)
end

local LP = Players.LocalPlayer
if not LP then
    pcall(function()
        LP = Players.PlayerAdded:Wait()
    end)
    LP = LP or Players.LocalPlayer
end

local ParentGui = nil
if gethui then
    pcall(function() ParentGui = gethui() end)
end
if not ParentGui then
    local okCore = pcall(function() return CoreGui.Name end)
    if okCore then ParentGui = CoreGui end
end
if not ParentGui and LP then
    pcall(function() ParentGui = LP:FindFirstChild("PlayerGui") or LP:WaitForChild("PlayerGui", 5) end)
end

local httpRequest  = request or http_request or (syn and syn.request) or (http and http.request)
local clipFn       = setclipboard or toclipboard or (Clipboard and Clipboard.set)
local customAsset  = getcustomasset or getsynasset or nil
local listfilesFn  = listfiles or nil

-- Memory penyimpanan source code script
_G.BLUE_RAW_SOURCES  = _G.BLUE_RAW_SOURCES or {}
_G.LANGZ_RAW_SOURCES = _G.LANGZ_RAW_SOURCES or {}

-- =====================================================
-- RICHTEXT & HTML TAG STRIPPER
-- Menghilangkan semua <font color="...">, </font>, dan tag HTML
-- agar script 100% bersih dan nyaman diedit tanpa tag warna pengganggu!
-- =====================================================
local function stripRichText(s)
    if type(s) ~= "string" then return s end
    local clean = s:gsub("<%s*/?%s*font[^>]*>", "")
    clean = clean:gsub("<[^>]+>", "")
    clean = clean:gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&amp;", "&"):gsub("&quot;", '"'):gsub("&apos;", "'")
    return clean
end


local function parseRBXMSources(raw)
    local sources = {}
    if not raw or #raw < 30 then return sources end
    for src in raw:gmatch("([^\0\r\n][^\0]+[\r\n]+[^\0]+)") do
        if src:find("function") or src:find("local ") or src:find("return") or src:find("require") then
            local nameMatch = src:match("([%a_][%w_]*)%s*=%s*function") or src:match("local%s+([%a_][%w_]*)") or "Script"
            sources[nameMatch] = stripRichText(src)
        end
    end
    for name, code in raw:gmatch('<Item class="[%w]+" referent="[^"]+">%s*<Properties>%s*<string name="Name">([^<]+)</string>.-<ProtectedString name="Source"><%!%[CDATA%[(.-)%]%]></ProtectedString>') do
        sources[name] = stripRichText(code)
    end
    return sources
end

local function storeScriptSource(key, src)
    if not key or not src then return end
    local clean = stripRichText(src)
    _G.BLUE_RAW_SOURCES[key] = clean
    _G.LANGZ_RAW_SOURCES[key] = clean
    if typeof(key) == "Instance" then
        _G.BLUE_RAW_SOURCES[key.Name] = clean
        _G.LANGZ_RAW_SOURCES[key.Name] = clean
        _G.BLUE_RAW_SOURCES[key.ClassName .. key.Name] = clean
        _G.LANGZ_RAW_SOURCES[key.ClassName .. key.Name] = clean
    end
end

local function lookupScriptSource(searchKey)
    if not searchKey or searchKey == "" then return nil end
    local sKey = tostring(searchKey):lower():gsub("%s+", "")

    -- Exact match in memory tables
    for k, v in pairs(_G.BLUE_RAW_SOURCES) do
        local kname = typeof(k) == "Instance" and (k.ClassName .. k.Name) or tostring(k)
        if kname:lower():gsub("%s+", "") == sKey then
            if type(v) == "string" and #v > 0 then return stripRichText(v) end
        end
    end
    for k, v in pairs(_G.LANGZ_RAW_SOURCES) do
        local kname = typeof(k) == "Instance" and (k.ClassName .. k.Name) or tostring(k)
        if kname:lower():gsub("%s+", "") == sKey then
            if type(v) == "string" and #v > 0 then return stripRichText(v) end
        end
    end

    -- Match by instance name in hierarchy
    for _, place in ipairs({workspace, ReplicatedStorage, LP:FindFirstChild("PlayerGui")}) do
        if place then
            for _, obj in ipairs(place:GetDescendants()) do
                if obj:IsA("LuaSourceContainer") then
                    local fullId = (obj.ClassName .. obj.Name):lower():gsub("%s+", "")
                    local nameId = obj.Name:lower():gsub("%s+", "")
                    if fullId == sKey or nameId == sKey then
                        local src = _G.BLUE_RAW_SOURCES[obj] or _G.LANGZ_RAW_SOURCES[obj]
                        if src and #src > 0 then return stripRichText(src) end
                        local tb = obj:FindFirstChild("SL_CodeTextBox")
                        if tb and tb.Text and #tb.Text > 0 then return stripRichText(tb.Text) end
                        local ok, raw = pcall(function() return obj.Source end)
                        if ok and raw and #raw > 0 then return stripRichText(raw) end
                    end
                end
            end
        end
    end

    -- NEVER return random scripts from other objects!
    return nil
end

-- =====================================================
-- STUDIO LITE INTEGRATION & HOOKS
-- =====================================================
local slFolder    = ReplicatedStorage:FindFirstChild("StudioLiteFolder")
local serverFuncs = slFolder and slFolder:FindFirstChild("ServerFunctions")

local function triggerServerLoad(idStr)
    if not serverFuncs or not idStr or idStr == "" then return end
    local id = tostring(idStr):match("%d+")
    if id and tonumber(id) and tonumber(id) > 0 then
        task.spawn(function()
            pcall(function()
                serverFuncs:InvokeServer("LoadMeshToRuntimeMeshes", tonumber(id))
            end)
        end)
    end
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
    task.spawn(function()
        pcall(function()
            for _, node in ipairs(obj:GetDescendants()) do
                if node:IsA("MeshPart") then
                    triggerServerLoad(node.MeshId); triggerServerLoad(node.TextureID)
                elseif node:IsA("Decal") or node:IsA("Texture") then
                    triggerServerLoad(node.Texture)
                elseif node:IsA("SpecialMesh") then
                    triggerServerLoad(node.MeshId); triggerServerLoad(node.TextureId)
                elseif node:IsA("UnionOperation") or node:IsA("PartOperation") then
                    triggerServerLoad(node.AssetId)
                end
            end
        end)
    end)
end

-- Safe Metamethod Hook
task.spawn(function()
    pcall(function()
        if hookmetamethod then
            local oldNamecall
            oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                local method = getnamecallmethod()
                local args = {...}

                if not checkcaller() and method == "InvokeServer" then
                    if self.Name == "GetScriptSourceServerFunction" then
                        local target = tostring(args[1])
                        local found = lookupScriptSource(target)
                        if found and #found > 0 then return found end
                        
                        -- Search in hierarchy
                        for _, place in ipairs({workspace, ReplicatedStorage, LP:FindFirstChild("PlayerGui")}) do
                            if place then
                                for _, obj in ipairs(place:GetDescendants()) do
                                    if obj:IsA("LuaSourceContainer") and (obj.Name == target or (obj.ClassName .. obj.Name) == target) then
                                        local s = lookupScriptSource(obj)
                                        if s and #s > 0 then return s end
                                    end
                                end
                            end
                        end
                    elseif self.Name == "SaveScriptSourceServerFunction" then
                        local target = tostring(args[1])
                        local newSource = tostring(args[2])
                        storeScriptSource(target, newSource)
                        
                        -- Immediate synchronization to instance in workspace
                        pcall(function()
                            for _, place in ipairs({workspace, ReplicatedStorage, LP:FindFirstChild("PlayerGui")}) do
                                if place then
                                    for _, obj in ipairs(place:GetDescendants()) do
                                        if obj:IsA("LuaSourceContainer") and (obj.Name == target or (obj.ClassName .. obj.Name) == target) then
                                            storeScriptSource(obj, newSource)
                                            pcall(function() obj.Source = newSource end)
                                            local tb = obj:FindFirstChild("SL_CodeTextBox")
                                            if tb then tb.Text = newSource end
                                        end
                                    end
                                end
                            end
                        end)
                    end
                end
                return oldNamecall(self, ...)
            end)
        end
    end)
end)

-- =====================================================
-- GUI CREATION
-- =====================================================
pcall(function()
    if ParentGui then
        local old = ParentGui:FindFirstChild("BLUExCrownV5")
        if old then old:Destroy() end
    end
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BLUExCrownV5"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 9999
pcall(function() ScreenGui.IgnoreGuiInset = true end)

local parentedOk = false
if ParentGui then
    parentedOk = pcall(function() ScreenGui.Parent = ParentGui end)
end
if not parentedOk or not ScreenGui.Parent then
    pcall(function()
        local pg = LP and (LP:FindFirstChild("PlayerGui") or LP:WaitForChild("PlayerGui", 5))
        if pg then ScreenGui.Parent = pg end
    end)
end

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

local function bindBtn(btn, callback)
    btn.Activated:Connect(callback)
end

-- =====================================================
-- FULLSCREEN EPIC LOADING SCREEN (MCHLERN ENGINE)
-- Background hitam pekat, logo kiri, typewriter text,
-- progress bar sinematik bergantian (BOT PROGRES, PARSER PROGRES, SLEEP ENGINE -> DONE)
-- =====================================================
local LoadingScreen = Instance.new("Frame")
LoadingScreen.Name = "MCHLERN_LoadingScreen"
LoadingScreen.Size = UDim2.new(1, 0, 1, 0)
LoadingScreen.Position = UDim2.new(0, 0, 0, 0)
LoadingScreen.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
LoadingScreen.BorderSizePixel = 0
LoadingScreen.ZIndex = 5000
LoadingScreen.Active = true
LoadingScreen.Parent = ScreenGui

local LoadContainer = Instance.new("Frame")
LoadContainer.Size = UDim2.new(0.9, 0, 0, 200)
LoadContainer.AnchorPoint = Vector2.new(0.5, 0.5)
LoadContainer.Position = UDim2.fromScale(0.5, 0.5)
LoadContainer.BackgroundTransparency = 1
LoadContainer.ZIndex = 5001
LoadContainer.Parent = LoadingScreen

-- Left side: Logo & Typewriter
local LeftBox = Instance.new("Frame")
LeftBox.Size = UDim2.new(0.46, 0, 1, 0)
LeftBox.Position = UDim2.new(0, 0, 0, 0)
LeftBox.BackgroundTransparency = 1
LeftBox.ZIndex = 5002
LeftBox.Parent = LoadContainer

-- Logo (Enlarged)
local LogoImg = Instance.new("ImageLabel")
LogoImg.Size = UDim2.new(0, 96, 0, 96)
LogoImg.Position = UDim2.new(0.5, -48, 0, 6)
LogoImg.BackgroundTransparency = 1
LogoImg.Image = "rbxassetid://102337382069600"
LogoImg.ZIndex = 5003
LogoImg.Parent = LeftBox
makeCorner(LogoImg, 14)
makeStroke(LogoImg, Color3.fromRGB(255, 255, 255), 1.5, 0.6)

local BrandTitle = Instance.new("TextLabel")
BrandTitle.Size = UDim2.new(1, 0, 0, 46)
BrandTitle.Position = UDim2.new(0, 0, 0, 108)
BrandTitle.BackgroundTransparency = 1
BrandTitle.Font = Enum.Font.GothamBold
BrandTitle.TextSize = 11
BrandTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
BrandTitle.TextWrapped = true
BrandTitle.TextXAlignment = Enum.TextXAlignment.Center
BrandTitle.Text = ""
BrandTitle.ZIndex = 5003
BrandTitle.Parent = LeftBox

-- Vertical Divider Line in the Middle
local MidDivider = Instance.new("Frame")
MidDivider.Size = UDim2.new(0, 1, 0, 140)
MidDivider.AnchorPoint = Vector2.new(0.5, 0.5)
MidDivider.Position = UDim2.new(0.48, 0, 0.5, 0)
MidDivider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
MidDivider.BackgroundTransparency = 0.75
MidDivider.BorderSizePixel = 0
MidDivider.ZIndex = 5003
MidDivider.Parent = LoadContainer

-- Right side: Progress Bar & Status Text
local RightBox = Instance.new("Frame")
RightBox.Size = UDim2.new(0.5, 0, 1, 0)
RightBox.Position = UDim2.new(0.5, 10, 0, 0)
RightBox.BackgroundTransparency = 1
RightBox.ZIndex = 5002
RightBox.Parent = LoadContainer

local StatusStepLbl = Instance.new("TextLabel")
StatusStepLbl.Size = UDim2.new(0.75, 0, 0, 22)
StatusStepLbl.Position = UDim2.new(0, 0, 0, 38)
StatusStepLbl.BackgroundTransparency = 1
StatusStepLbl.Font = Enum.Font.GothamBold
StatusStepLbl.TextSize = 12
StatusStepLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusStepLbl.TextXAlignment = Enum.TextXAlignment.Left
StatusStepLbl.Text = "INITIALIZING KERNEL..."
StatusStepLbl.ZIndex = 5003
StatusStepLbl.Parent = RightBox

local PctLbl = Instance.new("TextLabel")
PctLbl.Size = UDim2.new(0.25, 0, 0, 22)
PctLbl.Position = UDim2.new(0.75, 0, 0, 38)
PctLbl.BackgroundTransparency = 1
PctLbl.Font = Enum.Font.GothamBold
PctLbl.TextSize = 12
PctLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
PctLbl.TextXAlignment = Enum.TextXAlignment.Right
PctLbl.Text = "0%"
PctLbl.ZIndex = 5003
PctLbl.Parent = RightBox

local BarBg = Instance.new("Frame")
BarBg.Size = UDim2.new(1, 0, 0, 10)
BarBg.Position = UDim2.new(0, 0, 0, 68)
BarBg.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
BarBg.BorderSizePixel = 0
BarBg.ZIndex = 5003
BarBg.Parent = RightBox
makeCorner(BarBg, 5)
makeStroke(BarBg, Color3.fromRGB(255, 255, 255), 1, 0.7)

local BarFill = Instance.new("Frame")
BarFill.Size = UDim2.new(0, 0, 1, 0)
BarFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
BarFill.BorderSizePixel = 0
BarFill.ZIndex = 5004
BarFill.Parent = BarBg
makeCorner(BarFill, 5)

local SubStatusLbl = Instance.new("TextLabel")
SubStatusLbl.Size = UDim2.new(1, 0, 0, 20)
SubStatusLbl.Position = UDim2.new(0, 0, 0, 86)
SubStatusLbl.BackgroundTransparency = 1
SubStatusLbl.Font = Enum.Font.Code
SubStatusLbl.TextSize = 9
SubStatusLbl.TextColor3 = Color3.fromRGB(160, 160, 175)
SubStatusLbl.TextXAlignment = Enum.TextXAlignment.Left
SubStatusLbl.Text = "Setting up Luau memory hooks..."
SubStatusLbl.ZIndex = 5003
SubStatusLbl.Parent = RightBox

-- Typewriter Effect
task.spawn(function()
    local targetText = "MCHLERN ENGINE TOOLS\nROBLOX STUDIO LITE"
    for i = 1, #targetText do
        if not LoadingScreen or not LoadingScreen.Parent then break end
        BrandTitle.Text = targetText:sub(1, i) .. "_"
        task.wait(0.04)
    end
    if BrandTitle and BrandTitle.Parent then
        BrandTitle.Text = targetText
    end
end)

-- Cinematic Progress Steps
task.spawn(function()
    local stages = {
        { pct = 18, text = "INITIALIZING KERNEL...", sub = "Setting up Roblox Luau memory hooks..." },
        { pct = 38, text = "BOT PROGRES...", sub = "Spawning anti-readonly bot watcher..." },
        { pct = 62, text = "PARSER PROGRES...", sub = "Loading LZ4 decompression binary modules..." },
        { pct = 85, text = "SLEEP ENGINE...", sub = "Optimizing Studio Lite render pipeline..." },
        { pct = 100, text = "DONE", sub = "Engine 100% ready. Enjoy pair programming!" }
    }

    for _, stg in ipairs(stages) do
        if not LoadingScreen or not LoadingScreen.Parent then break end
        StatusStepLbl.Text = stg.text
        SubStatusLbl.Text = stg.sub
        PctLbl.Text = tostring(stg.pct) .. "%"
        TweenService:Create(BarFill, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(stg.pct / 100, 0, 1, 0)
        }):Play()
        task.wait(0.65)
    end

    task.wait(0.5)
    -- Smooth Fade-out
    pcall(function()
        local fadeTween = TweenService:Create(LoadingScreen, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1
        })
        for _, d in ipairs(LoadingScreen:GetDescendants()) do
            pcall(function()
                if d:IsA("TextLabel") or d:IsA("TextBox") then
                    TweenService:Create(d, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 1 }):Play()
                elseif d:IsA("ImageLabel") then
                    TweenService:Create(d, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { ImageTransparency = 1 }):Play()
                elseif d:IsA("Frame") then
                    TweenService:Create(d, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
                elseif d:IsA("UIStroke") then
                    TweenService:Create(d, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Transparency = 1 }):Play()
                end
            end)
        end
        fadeTween:Play()
        fadeTween.Completed:Wait()
        LoadingScreen:Destroy()
    end)
end)


-- =====================================================
-- Active hook daemon consolidated into Non-Intrusive Editor Bridge
-- Core UI helpers already defined at top of ScreenGui

-- =====================================================
-- 1. TOGGLE BUTTON (PATEN DI KIRI - TIDAK GESER KARENA KAMERA)
-- =====================================================
local ToggleBtn = Instance.new("ImageButton")
ToggleBtn.Name = "BLUExToggleBtn"
ToggleBtn.Size = UDim2.new(0, 44, 0, 44)
ToggleBtn.Position = UDim2.new(0.015, 0, 0.45, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(14, 14, 16)
ToggleBtn.Image = "rbxassetid://102337382069600"
ToggleBtn.ScaleType = Enum.ScaleType.Fit
ToggleBtn.Active = true
ToggleBtn.ZIndex = 100
ToggleBtn.Parent = ScreenGui
makeCorner(ToggleBtn, 8)
makeStroke(ToggleBtn, Color3.fromRGB(255,255,255), 1.4)

-- =====================================================
-- 2. MAIN WINDOW
-- =====================================================


-- =====================================================
-- 2. QUANTUM MAIN WINDOW (SIDEBAR KIRI + TAB CONTAINER KANAN)
-- =====================================================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "QuantumMainFrame"
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.fromScale(0.5, 0.5)
MainFrame.Size = UDim2.fromOffset(580, 380)
MainFrame.BackgroundColor3 = Color3.fromRGB(13, 14, 18)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Active = true
MainFrame.ZIndex = 10
MainFrame.Parent = ScreenGui
makeCorner(MainFrame, 10)
makeStroke(MainFrame, Color3.fromRGB(48, 52, 72), 1.5)

-- Glow accent line at top
local TopAccent = Instance.new("Frame")
TopAccent.Size = UDim2.new(1, 0, 0, 2)
TopAccent.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
TopAccent.BorderSizePixel = 0
TopAccent.ZIndex = 25
TopAccent.Parent = MainFrame

-- TOP BAR (HEADER)
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, -12, 0, 32)
TopBar.Position = UDim2.new(0, 6, 0, 5)
TopBar.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
TopBar.BorderSizePixel = 0
TopBar.Active = true
TopBar.ZIndex = 11
TopBar.Parent = MainFrame
makeCorner(TopBar, 7)
makeStroke(TopBar, Color3.fromRGB(38, 42, 58), 1, 0)

-- Header Logo / Icon
local TitleIcon = Instance.new("TextLabel")
TitleIcon.Size = UDim2.new(0, 28, 1, 0)
TitleIcon.Position = UDim2.new(0, 8, 0, 0)
TitleIcon.BackgroundTransparency = 1
TitleIcon.Text = "⚛"
TitleIcon.Font = Enum.Font.GothamBold
TitleIcon.TextSize = 18
TitleIcon.TextColor3 = Color3.fromRGB(88, 101, 242)
TitleIcon.ZIndex = 12
TitleIcon.Parent = TopBar

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size = UDim2.new(0, 320, 1, 0)
TitleLbl.Position = UDim2.new(0, 36, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text = "MCHLERN ENGINE  <font color='#5865F2'>STUDIO LITE</font>  <font color='#8A92A6'>| Quantum PC</font>"
TitleLbl.RichText = true
TitleLbl.Font = Enum.Font.GothamBold
TitleLbl.TextSize = 11.5
TitleLbl.TextColor3 = Color3.fromRGB(240, 242, 250)
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TitleLbl.ZIndex = 12
TitleLbl.Parent = TopBar

-- Close Button (X)
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 26, 0, 24)
CloseBtn.Position = UDim2.new(1, -30, 0, 6)
CloseBtn.BackgroundColor3 = Color3.fromRGB(30, 33, 44)
CloseBtn.Text = "✕"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 11
CloseBtn.TextColor3 = Color3.fromRGB(200, 205, 220)
CloseBtn.ZIndex = 20
CloseBtn.Active = true
CloseBtn.Parent = TopBar
makeCorner(CloseBtn, 5)
makeStroke(CloseBtn, Color3.fromRGB(50, 55, 75), 1)

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    ToggleBtn.Visible = true
end)

ToggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Draggable via TopBar
local function makeSafeTopBarDraggable(frame, handle)
    local dragInput, dragStart, startPos = nil, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragStart and startPos then
            local delta = input.Position - dragStart
            local vp = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(800, 450)
            local newX = math.clamp(startPos.X.Offset + delta.X, -vp.X/2 + 200, vp.X/2 - 200)
            local newY = math.clamp(startPos.Y.Offset + delta.Y, -vp.Y/2 + 100, vp.Y/2 - 100)
            frame.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
        end
    end)
    handle.InputEnded:Connect(function(input)
        if input == dragInput then dragInput = nil end
    end)
end
makeSafeTopBarDraggable(MainFrame, TopBar)

-- =====================================================
-- 3. SIDEBAR (KIRI - SEMUA TOMBOL NAVIGASI DI SINI)
-- =====================================================
local Sidebar = Instance.new("Frame")
Sidebar.Name = "QuantumSidebar"
Sidebar.Size = UDim2.new(0, 132, 1, -44)
Sidebar.Position = UDim2.new(0, 6, 0, 39)
Sidebar.BackgroundColor3 = Color3.fromRGB(16, 17, 23)
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 11
Sidebar.Parent = MainFrame
makeCorner(Sidebar, 8)
makeStroke(Sidebar, Color3.fromRGB(34, 38, 52), 1)

-- User Mini Profile in Sidebar
local UserProfile = Instance.new("Frame")
UserProfile.Size = UDim2.new(1, -8, 0, 36)
UserProfile.Position = UDim2.new(0, 4, 0, 5)
UserProfile.BackgroundColor3 = Color3.fromRGB(22, 24, 32)
UserProfile.BorderSizePixel = 0
UserProfile.ZIndex = 12
UserProfile.Parent = Sidebar
makeCorner(UserProfile, 6)

local UserAvatarImg = Instance.new("ImageLabel")
UserAvatarImg.Size = UDim2.new(0, 24, 0, 24)
UserAvatarImg.Position = UDim2.new(0, 5, 0, 6)
UserAvatarImg.BackgroundColor3 = Color3.fromRGB(28, 30, 40)
UserAvatarImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LP.UserId) .. "&w=150&h=150"
UserAvatarImg.ZIndex = 13
UserAvatarImg.Parent = UserProfile
makeCorner(UserAvatarImg, 12)
makeStroke(UserAvatarImg, Color3.fromRGB(88, 101, 242), 1)

local UserDispName = Instance.new("TextLabel")
UserDispName.Size = UDim2.new(1, -38, 0, 14)
UserDispName.Position = UDim2.new(0, 34, 0, 5)
UserDispName.BackgroundTransparency = 1
UserDispName.Text = LP.DisplayName or LP.Name or "Player"
UserDispName.Font = Enum.Font.GothamBold
UserDispName.TextSize = 9
UserDispName.TextColor3 = Color3.fromRGB(255, 255, 255)
UserDispName.TextXAlignment = Enum.TextXAlignment.Left
UserDispName.TextTruncate = Enum.TextTruncate.AtEnd
UserDispName.ZIndex = 13
UserDispName.Parent = UserProfile

local UserHandle = Instance.new("TextLabel")
UserHandle.Size = UDim2.new(1, -38, 0, 12)
UserHandle.Position = UDim2.new(0, 34, 0, 18)
UserHandle.BackgroundTransparency = 1
UserHandle.Text = "@" .. (LP.Name or "user")
UserHandle.Font = Enum.Font.Gotham
UserHandle.TextSize = 7.5
UserHandle.TextColor3 = Color3.fromRGB(140, 145, 165)
UserHandle.TextXAlignment = Enum.TextXAlignment.Left
UserHandle.TextTruncate = Enum.TextTruncate.AtEnd
UserHandle.ZIndex = 13
UserHandle.Parent = UserProfile

-- Divider under profile
local SideDiv = Instance.new("Frame")
SideDiv.Size = UDim2.new(1, -16, 0, 1)
SideDiv.Position = UDim2.new(0, 6, 0, 46)
SideDiv.BackgroundColor3 = Color3.fromRGB(34, 38, 52)
SideDiv.BorderSizePixel = 0
SideDiv.ZIndex = 12
SideDiv.Parent = Sidebar

-- Navigation List
local NavScroll = Instance.new("ScrollingFrame")
NavScroll.Size = UDim2.new(1, -6, 1, -54)
NavScroll.Position = UDim2.new(0, 3, 0, 50)
NavScroll.BackgroundTransparency = 1
NavScroll.BorderSizePixel = 0
NavScroll.ScrollBarThickness = 2
NavScroll.ScrollBarImageColor3 = Color3.fromRGB(60, 65, 85)
NavScroll.CanvasSize = UDim2.new()
NavScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
NavScroll.ZIndex = 12
NavScroll.Parent = Sidebar

local NavLayout = Instance.new("UIListLayout")
NavLayout.Padding = UDim.new(0, 4)
NavLayout.SortOrder = Enum.SortOrder.LayoutOrder
NavLayout.Parent = NavScroll

-- =====================================================
-- 4. CONTENT AREA (KANAN - HALAMAN TAB AKTIF)
-- =====================================================
local Content = Instance.new("Frame")
Content.Name = "QuantumContent"
Content.Size = UDim2.new(1, -148, 1, -44)
Content.Position = UDim2.new(0, 142, 0, 39)
Content.BackgroundTransparency = 1
Content.ClipsDescendants = true
Content.ZIndex = 11
Content.Parent = MainFrame

local PageToolbox  = Instance.new("Frame")
local PageSplash   = PageToolbox -- Aliased to PageToolbox for backward compatibility
local PageAvatar   = Instance.new("Frame")
local PageRBXL     = Instance.new("Frame")
local PageRBXM     = Instance.new("Frame")
local PageText3D   = Instance.new("Frame")
local PageReplacer = Instance.new("Frame")

local ALL_PAGES = {
    Toolbox  = PageToolbox,
    Avatar   = PageAvatar,
    RBXL     = PageRBXL,
    RBXM     = PageRBXM,
    Text3D   = PageText3D,
    Replacer = PageReplacer,
}

for name, pg in pairs(ALL_PAGES) do
    pg.Name = "Page_" .. name
    pg.Size = UDim2.fromScale(1, 1)
    pg.BackgroundTransparency = 1
    pg.Visible = false
    pg.ZIndex = 12
    pg.Parent = Content
end

-- Navigation Button Builder
local navButtons = {}
local activeTabName = nil

local function switchTab(tabKey)
    activeTabName = tabKey
    for name, pg in pairs(ALL_PAGES) do
        pg.Visible = (name == tabKey)
    end
    for name, btnData in pairs(navButtons) do
        local isActive = (name == tabKey)
        btnData.Button.BackgroundColor3 = isActive and Color3.fromRGB(30, 36, 56) or Color3.fromRGB(18, 20, 26)
        btnData.Indicator.Visible = isActive
        btnData.Label.TextColor3 = isActive and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 155, 175)
        btnData.Label.Font = isActive and Enum.Font.GothamBold or Enum.Font.GothamMedium
        btnData.Stroke.Color = isActive and Color3.fromRGB(88, 101, 242) or Color3.fromRGB(28, 30, 40)
    end
end

local function addNavButton(tabKey, icon, labelText, order)
    local btn = Instance.new("TextButton")
    btn.Name = "Nav_" .. tabKey
    btn.Size = UDim2.new(1, 0, 0, 31)
    btn.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.LayoutOrder = order or 1
    btn.ZIndex = 13
    btn.Parent = NavScroll
    makeCorner(btn, 6)
    local btnStroke = makeStroke(btn, Color3.fromRGB(28, 30, 40), 1)

    -- Left glowing accent indicator bar (Quantum style)
    local ind = Instance.new("Frame")
    ind.Size = UDim2.new(0, 3, 0, 16)
    ind.Position = UDim2.new(0, 3, 0.5, -8)
    ind.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    ind.BorderSizePixel = 0
    ind.Visible = false
    ind.ZIndex = 14
    ind.Parent = btn
    makeCorner(ind, 2)

    -- Icon
    local ic = Instance.new("TextLabel")
    ic.Size = UDim2.new(0, 18, 1, 0)
    ic.Position = UDim2.new(0, 8, 0, 0)
    ic.BackgroundTransparency = 1
    ic.Text = icon
    ic.Font = Enum.Font.GothamBold
    ic.TextSize = 11
    ic.TextColor3 = Color3.fromRGB(88, 101, 242)
    ic.ZIndex = 14
    ic.Parent = btn

    -- Label
    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(1, -40, 1, 0)
    lb.Position = UDim2.new(0, 28, 0, 0)
    lb.BackgroundTransparency = 1
    lb.Text = labelText
    lb.Font = Enum.Font.GothamMedium
    lb.TextSize = 8.5
    lb.TextColor3 = Color3.fromRGB(150, 155, 175)
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.ZIndex = 14
    lb.Parent = btn

    btn.MouseEnter:Connect(function()
        if activeTabName ~= tabKey then
            btn.BackgroundColor3 = Color3.fromRGB(24, 27, 38)
            lb.TextColor3 = Color3.fromRGB(200, 205, 220)
        end
    end)
    btn.MouseLeave:Connect(function()
        if activeTabName ~= tabKey then
            btn.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
            lb.TextColor3 = Color3.fromRGB(150, 155, 175)
        end
    end)

    btn.MouseButton1Click:Connect(function()
        switchTab(tabKey)
    end)

    navButtons[tabKey] = {
        Button = btn,
        Indicator = ind,
        Label = lb,
        Stroke = btnStroke
    }
end

-- Add all tabs on the left
addNavButton("Toolbox",  "📦", "TOOLBOX ASET",     1)
addNavButton("Avatar",   "👤", "AVATAR CHANGER",   2)
addNavButton("RBXL",     "🏗️", "RBXL IMPORTER",    3)
addNavButton("RBXM",     "📁", "INSERT RBXM",      4)
addNavButton("Text3D",   "🔤", "GENE TEXT 3D",     5)
addNavButton("Replacer", "🔄", "REPLACER TOOLS",   6)

-- Compatibility helper for existing code that calls showPage
local function showPage(target)
    for name, pg in pairs(ALL_PAGES) do
        if pg == target then
            switchTab(name)
            return
        end
    end
end
local function makeBackBtn(parent, onBack)
    -- Hidden/stub in Quantum layout since sidebar is always visible!
    local b = Instance.new("Frame")
    b.Size = UDim2.new(0, 0, 0, 0)
    b.Visible = false
    b.Parent = parent
    return b
end

local TbHeader = Instance.new("Frame")
TbHeader.Size = UDim2.new(1, 0, 0, 28)
TbHeader.BackgroundTransparency = 1
TbHeader.ZIndex = 13
TbHeader.Parent = PageToolbox

local TbTitleLbl = Instance.new("TextLabel")
TbTitleLbl.Size = UDim2.new(1, -80, 1, 0)
TbTitleLbl.BackgroundTransparency = 1
TbTitleLbl.Text = "TOOLBOX ASET"
TbTitleLbl.Font = Enum.Font.GothamBold
TbTitleLbl.TextSize = 11
TbTitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
TbTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TbTitleLbl.ZIndex = 14
TbTitleLbl.Parent = TbHeader

makeBackBtn(TbHeader, function() showPage(PageSplash) end)

local TbContent = Instance.new("Frame")
TbContent.Size = UDim2.new(1, 0, 1, -34)
TbContent.Position = UDim2.new(0, 0, 0, 34)
TbContent.BackgroundTransparency = 1
TbContent.ZIndex = 13
TbContent.Parent = PageToolbox

local TbLeft = Instance.new("Frame")
TbLeft.Size = UDim2.new(0, 180, 1, 0)
TbLeft.BackgroundTransparency = 1
TbLeft.ZIndex = 14
TbLeft.Parent = TbContent

local TbSearchSec = Instance.new("Frame")
TbSearchSec.Size = UDim2.new(1, 0, 0, 118)
TbSearchSec.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
TbSearchSec.ZIndex = 14
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
TbIdBox.ZIndex = 15
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
TbInsertIdBtn.Active = true
TbInsertIdBtn.ZIndex = 15
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
TbSearchBox.ZIndex = 15
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
TbSearchBtn.Active = true
TbSearchBtn.ZIndex = 15
TbSearchBtn.Parent = TbSearchSec
makeCorner(TbSearchBtn, 5)

local selectedCat = 10
local catBtns = {}
local cats = {{n="MODEL",id=10},{n="DECAL",id=13},{n="AUDIO",id=3},{n="MESH",id=11}}
local TbCatRow = Instance.new("Frame")
TbCatRow.Size = UDim2.new(1, -12, 0, 20)
TbCatRow.Position = UDim2.new(0, 6, 0, 65)
TbCatRow.BackgroundTransparency = 1
TbCatRow.ZIndex = 14
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
    cb.Active = true
    cb.ZIndex = 15
    cb.Parent = TbCatRow
    makeCorner(cb, 4); makeStroke(cb, Color3.fromRGB(255,255,255), 1, 0.82)
    catBtns[c.id] = cb
    cb.Activated:Connect(function() selectedCat = c.id; updateCatTabs() end)
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
TbStatusLbl.ZIndex = 15
TbStatusLbl.Parent = TbSearchSec

local TbDetailBox = Instance.new("Frame")
TbDetailBox.Size = UDim2.new(1, 0, 1, -124)
TbDetailBox.Position = UDim2.new(0, 0, 0, 124)
TbDetailBox.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
TbDetailBox.ZIndex = 14
TbDetailBox.Parent = TbLeft
makeCorner(TbDetailBox, 8); makeStroke(TbDetailBox, Color3.fromRGB(255,255,255), 1, 0.78)

local TbDetTitleLbl = Instance.new("TextLabel")
TbDetTitleLbl.Size = UDim2.new(1, -12, 0, 18); TbDetTitleLbl.Position = UDim2.new(0, 8, 0, 4)
TbDetTitleLbl.BackgroundTransparency = 1; TbDetTitleLbl.Text = "DETAIL ASSET"
TbDetTitleLbl.Font = Enum.Font.GothamBold; TbDetTitleLbl.TextSize = 9
TbDetTitleLbl.TextColor3 = Color3.fromRGB(200, 200, 210)
TbDetTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TbDetTitleLbl.ZIndex = 15
TbDetTitleLbl.Parent = TbDetailBox

local TbDetThumb = Instance.new("ImageLabel")
TbDetThumb.Size = UDim2.new(0, 52, 0, 52); TbDetThumb.Position = UDim2.new(0, 8, 0, 24)
TbDetThumb.BackgroundColor3 = Color3.fromRGB(26, 26, 30); TbDetThumb.Image = ""
TbDetThumb.ZIndex = 15
TbDetThumb.Parent = TbDetailBox; makeCorner(TbDetThumb, 6); makeStroke(TbDetThumb, Color3.fromRGB(255,255,255), 1, 0.82)

local TbDetName = Instance.new("TextLabel")
TbDetName.Size = UDim2.new(1, -70, 0, 26); TbDetName.Position = UDim2.new(0, 66, 0, 22)
TbDetName.BackgroundTransparency = 1; TbDetName.Text = "Pilih aset dari grid"
TbDetName.Font = Enum.Font.GothamBold; TbDetName.TextSize = 10
TbDetName.TextColor3 = Color3.fromRGB(255, 255, 255)
TbDetName.TextXAlignment = Enum.TextXAlignment.Left; TbDetName.TextWrapped = true
TbDetName.ZIndex = 15
TbDetName.Parent = TbDetailBox

local TbDetCreator = Instance.new("TextLabel")
TbDetCreator.Size = UDim2.new(1, -70, 0, 14); TbDetCreator.Position = UDim2.new(0, 66, 0, 46)
TbDetCreator.BackgroundTransparency = 1; TbDetCreator.Text = "By: -"
TbDetCreator.Font = Enum.Font.Gotham; TbDetCreator.TextSize = 8
TbDetCreator.TextColor3 = Color3.fromRGB(150, 150, 160)
TbDetCreator.TextXAlignment = Enum.TextXAlignment.Left
TbDetCreator.ZIndex = 15
TbDetCreator.Parent = TbDetailBox

local TbDetId = Instance.new("TextLabel")
TbDetId.Size = UDim2.new(1, -70, 0, 14); TbDetId.Position = UDim2.new(0, 66, 0, 60)
TbDetId.BackgroundTransparency = 1; TbDetId.Text = "ID: -"
TbDetId.Font = Enum.Font.Gotham; TbDetId.TextSize = 8
TbDetId.TextColor3 = Color3.fromRGB(150, 150, 160)
TbDetId.TextXAlignment = Enum.TextXAlignment.Left
TbDetId.ZIndex = 15
TbDetId.Parent = TbDetailBox

local currentInspId = ""
local TbDetRow = Instance.new("Frame")
TbDetRow.Size = UDim2.new(1, -16, 0, 26); TbDetRow.Position = UDim2.new(0, 8, 1, -32)
TbDetRow.BackgroundTransparency = 1
TbDetRow.ZIndex = 14
TbDetRow.Parent = TbDetailBox

local TbDetInsert = Instance.new("TextButton")
TbDetInsert.Size = UDim2.new(0.5, -3, 1, 0); TbDetInsert.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TbDetInsert.Text = "INSERT"; TbDetInsert.Font = Enum.Font.GothamBold; TbDetInsert.TextSize = 9
TbDetInsert.TextColor3 = Color3.fromRGB(0, 0, 0); TbDetInsert.Active = true; TbDetInsert.ZIndex = 15
TbDetInsert.Parent = TbDetRow; makeCorner(TbDetInsert, 5)

local TbDetCopy = Instance.new("TextButton")
TbDetCopy.Size = UDim2.new(0.5, -3, 1, 0); TbDetCopy.Position = UDim2.new(0.5, 3, 0, 0)
TbDetCopy.BackgroundColor3 = Color3.fromRGB(255, 255, 255); TbDetCopy.Text = "COPY ID"
TbDetCopy.Font = Enum.Font.GothamBold; TbDetCopy.TextSize = 9
TbDetCopy.TextColor3 = Color3.fromRGB(0, 0, 0); TbDetCopy.Active = true; TbDetCopy.ZIndex = 15
TbDetCopy.Parent = TbDetRow; makeCorner(TbDetCopy, 5)

local TbRight = Instance.new("Frame")
TbRight.Size = UDim2.new(1, -186, 1, 0); TbRight.Position = UDim2.new(0, 186, 0, 0)
TbRight.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
TbRight.ZIndex = 14
TbRight.Parent = TbContent
makeCorner(TbRight, 8); makeStroke(TbRight, Color3.fromRGB(255,255,255), 1, 0.78)

local TbBrowserLbl = Instance.new("TextLabel")
TbBrowserLbl.Size = UDim2.new(1, -16, 0, 24); TbBrowserLbl.Position = UDim2.new(0, 8, 0, 4)
TbBrowserLbl.BackgroundTransparency = 1; TbBrowserLbl.Text = "ASSET BROWSER"
TbBrowserLbl.Font = Enum.Font.GothamBold; TbBrowserLbl.TextSize = 10
TbBrowserLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
TbBrowserLbl.TextXAlignment = Enum.TextXAlignment.Left
TbBrowserLbl.ZIndex = 15
TbBrowserLbl.Parent = TbRight

local TbGridScroll = Instance.new("ScrollingFrame")
TbGridScroll.Size = UDim2.new(1, -12, 1, -34); TbGridScroll.Position = UDim2.new(0, 6, 0, 28)
TbGridScroll.BackgroundTransparency = 1; TbGridScroll.ScrollBarThickness = 3
TbGridScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
TbGridScroll.ZIndex = 15
TbGridScroll.Parent = TbRight

local TbGrid = Instance.new("UIGridLayout")
TbGrid.CellSize = UDim2.new(0, 104, 0, 115); TbGrid.CellPadding = UDim2.new(0, 6, 0, 6)
TbGrid.SortOrder = Enum.SortOrder.LayoutOrder; TbGrid.Parent = TbGridScroll

local TbGridStatus = Instance.new("TextLabel")
TbGridStatus.Size = UDim2.new(1, 0, 0, 40); TbGridStatus.BackgroundTransparency = 1
TbGridStatus.Text = "Ketik kata kunci & klik CARI"
TbGridStatus.Font = Enum.Font.Gotham; TbGridStatus.TextSize = 10
TbGridStatus.TextColor3 = Color3.fromRGB(140, 140, 150)
TbGridStatus.ZIndex = 16
TbGridStatus.Parent = TbGridScroll

-- =====================================================
-- PAGE 3: INSERT RBXM FILE
-- =====================================================

local RbxmHeader = Instance.new("Frame")


-- ============================================================================
-- [PAGE: RBXL IMPORTER (STUDIO LITE)]
-- Universal RBXL Binary Engine (Decompress LZ4/ZSTD, Parse & Inject to Services)
-- ============================================================================
local function initPageRBXL()
    local function createRbxlEngine()
_G.Hyaz_RAW_SOURCES = _G.Hyaz_RAW_SOURCES or {}
_G.Hyaz_RAW_SOURCE_BY_REF = _G.Hyaz_RAW_SOURCE_BY_REF or {}
if type(string.unpack) ~= "function" then
    warn("[RBXL ENGINE] string.unpack tidak tersedia. Binary RBXL tidak dapat dibaca di executor ini.")
end
local BINARY_BIT32_OK = type(bit32) == "table"
if not BINARY_BIT32_OK then
    warn("[RBXL ENGINE] bit32 tidak tersedia. UI tetap dibuka, tetapi import binary tidak bisa berjalan.")
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
        pos = pos + (1)
        return b
    end
    local function extLen(base)
        local len = base
        if base == 15 then
            while true do
                local b = readByte()
                len = len + (b)
                if b ~= 255 then break end
            end
        end
        return len
    end
    while outLen < decompressedLen do
        local token = readByte()
        local literalLen = extLen(bit32.rshift(token, 4))
        for _ = 1, literalLen do
            outLen = outLen + (1)
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
            outLen = outLen + (1)
            out[outLen] = out[srcIndex]
            srcIndex = srcIndex + (1)
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
                k = k + (1)
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
                ui = ui + (1)
            elseif kinds[i] == 2 then
                a[i]={__ContentObjectRef=objectRefs[oi]}
                oi = oi + (1)
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
            warn(("[RBXL ENGINE] property skipped: %s (type 0x%02X)"):format(pname, typeID or 0))
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
                cursor = cursor + (1)
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
    if realSource and #realSource > 0 then
        local _nullpat = string.char(0)
        realSource = realSource:gsub(_nullpat .. "*$", "")
    else
        realSource = ""
    end
    _G.Hyaz_RAW_SOURCES[scr] = realSource
    local UI_TEXT = realSource
    if #UI_TEXT > 150000 then
        UI_TEXT = "-- [SOURCE CODE EXCEEDS PREVIEW LIMIT]"
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
    return base .. " IMPORTER"
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
                    meshNative = meshNative + (1)
                elseif mode == "fallback" then
                    meshFallback = meshFallback + (1)
                else
                    meshUnresolved = meshUnresolved + (1)
                end
                return obj
            end
            meshUnresolved = meshUnresolved + (1)
            return nil
        end
        if node.ClassName == "UnionOperation" or node.ClassName == "PartOperation" or node.ClassName == "IntersectOperation" then
            local obj, mode = tryLoadPartOperationNode(node)
            if obj then
                if mode == "asset" or mode == "mesh" or mode == "visual" then
                    csgAsset = csgAsset + (1)
                else
                    csgProxy = csgProxy + (1)
                end
                return obj
            end
            csgProxy = csgProxy + (1)
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
            skipped = skipped + (1)
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
            skipped = skipped + (1)
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
            if not okName then failedProperties = failedProperties + (1) end
        end
        for propName, value in pairs(node.Properties) do
            if propName ~= "Name" then
                local okProp = applyDecodedProperty(
                    obj,
                    propName,
                    value,
                    node.PropertyTypes and node.PropertyTypes[propName]
                )
                if not okProp then failedProperties = failedProperties + (1) end
            end
        end
        rememberStudioLiteState(obj, node)
        disableImportedScript(obj, node)
        normalizePartGeometry(obj, node)
        obj.Parent = parent or containers[routeKey] or containers.WS
        buildBurstCount = buildBurstCount + (1)
        progressMade = progressMade + (1)
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
                skipped = skipped + (1)
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
                        if not okRef then failedProperties = failedProperties + (1) end
                    end
                elseif typeID == 0x22 then
                    local contentValue = node.Properties[propName]
                    if type(contentValue) == "table" and contentValue.__ContentObjectRef then
                        local targetObj = made[contentValue.__ContentObjectRef]
                        if targetObj then
                            local okRef = pcall(function()
                                obj[propName] = targetObj
                            end)
                            if not okRef then failedProperties = failedProperties + (1) end
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
                scriptBatch = scriptBatch + (1)
                if scriptBatch >= 40 then
                    scriptBatch = 0
                    task.wait()
                end
            end
        end
    end)
    flushServerLoadsAsync()
    local madeCount = 0
    for _ in pairs(made) do madeCount = madeCount + (1) end
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
        "return function(script, require, ...)\n"
        .. source
        .. "\nend"
    local okCompile, loaderOrErr = pcall(
        loadstring,
        wrapped,
        "=RBXL/" .. tostring(scr:GetFullName())
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
            error("Runtime require circular dependency: " .. target:GetFullName())
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
                "[LIVE SCRIPT ERROR] "
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
            stats.skipped = stats.skipped + (1)
            setScriptEnabledState(scr, false)
        else
            local hasRealSource = canReadExecutableSource(scr)
            if hasRealSource then
                local ok = setScriptEnabledState(scr, true)
                if ok then
                    stats.native = stats.native + (1)
                else
                    stats.failed = stats.failed + (1)
                end
            else
                setScriptEnabledState(scr, false)
                local ok = runLocalScriptBridge(scr)
                if ok then
                    stats.bridge = stats.bridge + (1)
                else
                    stats.failed = stats.failed + (1)
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
            stats.scripts = stats.scripts + (1)
            local ok = tryWriteRealScriptSource(obj)
            if ok then
                stats.scriptSourceOK = stats.scriptSourceOK + (1)
            else
                stats.scriptSourceFailed = stats.scriptSourceFailed + (1)
            end
        end
    end
    for _, obj in ipairs(all) do
        if obj:IsA("BasePart") then
            stats.parts = stats.parts + (1)
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
            moved = moved + (1)
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
                moved = moved + (1)
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
            reusedServiceCount = reusedServiceCount + (1)
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
            createdServiceCount = createdServiceCount + (1)
            serviceModes[serviceName] = "CREATED_MISSING"
            return created
        end
        local okGet, service = pcall(function()
            return game:GetService(serviceName)
        end)
        if okGet and service then
            forcedServiceCount = forcedServiceCount + (1)
            serviceModes[serviceName] = "GETSERVICE_MISSING"
            pcall(function()
                service:SetAttribute("HYAZ_ServiceRole", serviceName)
            end)
            return service
        end
        missingRealServices = missingRealServices + (1)
        serviceModes[serviceName] = "FAILED"
        warn(
            "[RBXL] SERVICE FAILED: "
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
                        scriptCount = scriptCount + (1)
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
                moved = moved + (moveChildren(serviceFolder, destination))
            elseif #serviceFolder:GetChildren() > 0 then
                failedServices = failedServices + (1)
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
            activatedScripts = activatedScripts + (1)
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
        cloneImportedChildren(StarterGuiSvc, playerGui)
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
        cloneImportedChildren(StarterPackSvc, backpack)
    end
    if ReplicatedFirstSvc then
        for _, obj in ipairs(ReplicatedFirstSvc:GetDescendants()) do
        if obj:IsA("LocalScript")
            and obj:GetAttribute("HYAZ_ImportedObject") == true then
            local hasRealSource = canReadExecutableSource(obj)
            if hasRealSource then
                setScriptEnabledState(obj, true)
                liveStats.native = liveStats.native + (1)
            else
                setScriptEnabledState(obj, false)
                local ok = runLocalScriptBridge(obj)
                if ok then
                    liveStats.bridge = liveStats.bridge + (1)
                else
                    liveStats.failed = liveStats.failed + (1)
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
                deployedScriptCount = deployedScriptCount + (1)
                if serviceKey == "SSS" then
                    sssImportedScripts = sssImportedScripts + (1)
                elseif serviceKey == "SS" then
                    ssImportedScripts = ssImportedScripts + (1)
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
                    sourceVisibleCount = sourceVisibleCount + (1)
                    pcall(function()
                        tryWriteRealScriptSource(obj)
                    end)
                    local okEditor = pcall(function()
                        injectStudioLiteUI(obj, {})
                    end)
                    if okEditor then
                        editorInjectedCount = editorInjectedCount + (1)
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
            remainingStagedObjects = remainingStagedObjects + (#serviceFolder:GetChildren())
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


        return {
            scanAll = scanAllRBXL,
            import = importRBXL,
            activate = activateImportRoot,
        }
    end

    local RbxlEngine = createRbxlEngine()

    -- ------------------------------------------------------------------------
    -- UI Components for PageRBXL
    -- ------------------------------------------------------------------------
    local RbxlHeader = Instance.new("Frame")
    RbxlHeader.Size = UDim2.new(1, 0, 0, 28)
    RbxlHeader.BackgroundTransparency = 1
    RbxlHeader.ZIndex = 13
    RbxlHeader.Parent = PageRBXL

    local RbxlTitleLbl = Instance.new("TextLabel")
    RbxlTitleLbl.Size = UDim2.new(1, -80, 0, 16)
    RbxlTitleLbl.Position = UDim2.new(0, 0, 0, 0)
    RbxlTitleLbl.BackgroundTransparency = 1
    RbxlTitleLbl.Text = "RBXL IMPORTER (STUDIO LITE)"
    RbxlTitleLbl.Font = Enum.Font.GothamBold
    RbxlTitleLbl.TextSize = 11
    RbxlTitleLbl.TextColor3 = Color3.fromRGB(245, 245, 255)
    RbxlTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    RbxlTitleLbl.ZIndex = 14
    RbxlTitleLbl.Parent = RbxlHeader

    local RbxlSubLbl = Instance.new("TextLabel")
    RbxlSubLbl.Size = UDim2.new(1, -80, 0, 12)
    RbxlSubLbl.Position = UDim2.new(0, 0, 0, 16)
    RbxlSubLbl.BackgroundTransparency = 1
    RbxlSubLbl.Text = "Scan .rbxl files in executor workspace & auto-activate to services"
    RbxlSubLbl.Font = Enum.Font.Gotham
    RbxlSubLbl.TextSize = 7.5
    RbxlSubLbl.TextColor3 = Color3.fromRGB(130, 135, 155)
    RbxlSubLbl.TextXAlignment = Enum.TextXAlignment.Left
    RbxlSubLbl.ZIndex = 14
    RbxlSubLbl.Parent = RbxlHeader

    -- Toolbar
    local RbxlToolbar = Instance.new("Frame")
    RbxlToolbar.Size = UDim2.new(1, 0, 0, 26)
    RbxlToolbar.Position = UDim2.new(0, 0, 0, 32)
    RbxlToolbar.BackgroundTransparency = 1
    RbxlToolbar.ZIndex = 13
    RbxlToolbar.Parent = PageRBXL

    local RbxlSearchCard = Instance.new("Frame")
    RbxlSearchCard.Size = UDim2.new(1, -94, 0, 24)
    RbxlSearchCard.BackgroundColor3 = Color3.fromRGB(16, 18, 26)
    RbxlSearchCard.BorderSizePixel = 0
    RbxlSearchCard.ZIndex = 14
    RbxlSearchCard.Parent = RbxlToolbar
    makeCorner(RbxlSearchCard, 6)
    makeStroke(RbxlSearchCard, Color3.fromRGB(40, 44, 60), 1)

    local RbxlSearchBox = Instance.new("TextBox")
    RbxlSearchBox.Size = UDim2.new(1, -16, 1, 0)
    RbxlSearchBox.Position = UDim2.new(0, 8, 0, 0)
    RbxlSearchBox.BackgroundTransparency = 1
    RbxlSearchBox.PlaceholderText = "Search .rbxl file..."
    RbxlSearchBox.PlaceholderColor3 = Color3.fromRGB(100, 105, 125)
    RbxlSearchBox.Text = ""
    RbxlSearchBox.TextColor3 = Color3.fromRGB(240, 240, 250)
    RbxlSearchBox.Font = Enum.Font.Gotham
    RbxlSearchBox.TextSize = 8.5
    RbxlSearchBox.TextXAlignment = Enum.TextXAlignment.Left
    RbxlSearchBox.ClearTextOnFocus = false
    RbxlSearchBox.ZIndex = 15
    RbxlSearchBox.Parent = RbxlSearchCard

    local RbxlScanBtn = Instance.new("TextButton")
    RbxlScanBtn.Size = UDim2.new(0, 88, 0, 24)
    RbxlScanBtn.Position = UDim2.new(1, -88, 0, 0)
    RbxlScanBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    RbxlScanBtn.Text = "SCAN FILES"
    RbxlScanBtn.Font = Enum.Font.GothamBold
    RbxlScanBtn.TextSize = 9
    RbxlScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    RbxlScanBtn.AutoButtonColor = false
    RbxlScanBtn.ZIndex = 15
    RbxlScanBtn.Parent = RbxlToolbar
    makeCorner(RbxlScanBtn, 6)
    makeStroke(RbxlScanBtn, Color3.fromRGB(114, 137, 218), 1, 0.4)

    -- Status & Info Bar
    local RbxlInfoBar = Instance.new("Frame")
    RbxlInfoBar.Size = UDim2.new(1, 0, 0, 20)
    RbxlInfoBar.Position = UDim2.new(0, 0, 0, 60)
    RbxlInfoBar.BackgroundColor3 = Color3.fromRGB(13, 15, 22)
    RbxlInfoBar.BorderSizePixel = 0
    RbxlInfoBar.ZIndex = 13
    RbxlInfoBar.Parent = PageRBXL
    makeCorner(RbxlInfoBar, 5)
    makeStroke(RbxlInfoBar, Color3.fromRGB(30, 34, 48), 1)

    local RbxlStatusDot = Instance.new("Frame")
    RbxlStatusDot.Size = UDim2.fromOffset(5, 5)
    RbxlStatusDot.Position = UDim2.new(0, 8, 0.5, -2.5)
    RbxlStatusDot.BackgroundColor3 = Color3.fromRGB(79, 211, 145)
    RbxlStatusDot.BorderSizePixel = 0
    RbxlStatusDot.ZIndex = 14
    RbxlStatusDot.Parent = RbxlInfoBar
    makeCorner(RbxlStatusDot, 3)

    local RbxlStatusText = Instance.new("TextLabel")
    RbxlStatusText.Size = UDim2.new(1, -120, 1, 0)
    RbxlStatusText.Position = UDim2.new(0, 20, 0, 0)
    RbxlStatusText.BackgroundTransparency = 1
    RbxlStatusText.Text = "READY"
    RbxlStatusText.TextColor3 = Color3.fromRGB(160, 165, 185)
    RbxlStatusText.Font = Enum.Font.GothamMedium
    RbxlStatusText.TextSize = 7.5
    RbxlStatusText.TextXAlignment = Enum.TextXAlignment.Left
    RbxlStatusText.TextTruncate = Enum.TextTruncate.AtEnd
    RbxlStatusText.ZIndex = 14
    RbxlStatusText.Parent = RbxlInfoBar

    local RbxlCountText = Instance.new("TextLabel")
    RbxlCountText.Size = UDim2.new(0, 95, 1, 0)
    RbxlCountText.Position = UDim2.new(1, -100, 0, 0)
    RbxlCountText.BackgroundTransparency = 1
    RbxlCountText.Text = "FILES 0 • IMP 0"
    RbxlCountText.TextColor3 = Color3.fromRGB(140, 145, 165)
    RbxlCountText.Font = Enum.Font.GothamBold
    RbxlCountText.TextSize = 7.5
    RbxlCountText.TextXAlignment = Enum.TextXAlignment.Right
    RbxlCountText.ZIndex = 14
    RbxlCountText.Parent = RbxlInfoBar

    -- Inline Progress Bar
    local RbxlProgressTrack = Instance.new("Frame")
    RbxlProgressTrack.Name = "RbxlProgressTrack"
    RbxlProgressTrack.Size = UDim2.new(1, 0, 0, 3)
    RbxlProgressTrack.Position = UDim2.new(0, 0, 1, -3)
    RbxlProgressTrack.BackgroundColor3 = Color3.fromRGB(22, 24, 34)
    RbxlProgressTrack.BorderSizePixel = 0
    RbxlProgressTrack.Visible = false
    RbxlProgressTrack.ZIndex = 15
    RbxlProgressTrack.Parent = RbxlInfoBar
    makeCorner(RbxlProgressTrack, 2)

    local RbxlProgressFill = Instance.new("Frame")
    RbxlProgressFill.Size = UDim2.new(0, 0, 1, 0)
    RbxlProgressFill.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    RbxlProgressFill.BorderSizePixel = 0
    RbxlProgressFill.ZIndex = 16
    RbxlProgressFill.Parent = RbxlProgressTrack
    makeCorner(RbxlProgressFill, 2)

    -- Scroll Container
    local RbxlScroll = Instance.new("ScrollingFrame")
    RbxlScroll.Size = UDim2.new(1, 0, 1, -84)
    RbxlScroll.Position = UDim2.new(0, 0, 0, 84)
    RbxlScroll.BackgroundColor3 = Color3.fromRGB(12, 13, 19)
    RbxlScroll.BorderSizePixel = 0
    RbxlScroll.ScrollBarThickness = 2
    RbxlScroll.ScrollBarImageColor3 = Color3.fromRGB(88, 101, 242)
    RbxlScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    RbxlScroll.CanvasSize = UDim2.new()
    RbxlScroll.ZIndex = 13
    RbxlScroll.Parent = PageRBXL
    makeCorner(RbxlScroll, 6)
    makeStroke(RbxlScroll, Color3.fromRGB(28, 30, 44), 1)

    local RbxlPad = Instance.new("UIPadding")
    RbxlPad.PaddingTop = UDim.new(0, 5)
    RbxlPad.PaddingBottom = UDim.new(0, 5)
    RbxlPad.PaddingLeft = UDim.new(0, 5)
    RbxlPad.PaddingRight = UDim.new(0, 5)
    RbxlPad.Parent = RbxlScroll

    local RbxlLayout = Instance.new("UIListLayout")
    RbxlLayout.Padding = UDim.new(0, 4)
    RbxlLayout.SortOrder = Enum.SortOrder.LayoutOrder
    RbxlLayout.Parent = RbxlScroll

    local RbxlEmpty = Instance.new("TextLabel")
    RbxlEmpty.Size = UDim2.new(1, -10, 0, 80)
    RbxlEmpty.BackgroundTransparency = 1
    RbxlEmpty.Text = "NO .RBXL FILES FOUND\nClick 'SCAN FILES' to search workspace"
    RbxlEmpty.TextColor3 = Color3.fromRGB(120, 125, 145)
    RbxlEmpty.Font = Enum.Font.GothamMedium
    RbxlEmpty.TextSize = 8.5
    RbxlEmpty.TextWrapped = true
    RbxlEmpty.ZIndex = 14
    RbxlEmpty.Parent = RbxlScroll

    local rbxlCards = {}
    local rbxlFileCount = 0
    local rbxlImportedCount = 0

    local function setRbxlStatus(text, color)
        RbxlStatusText.Text = tostring(text)
        RbxlStatusDot.BackgroundColor3 = color or Color3.fromRGB(88, 101, 242)
    end

    local function setRbxlProgress(value, message)
        value = math.clamp(tonumber(value) or 0, 0, 1)
        RbxlProgressTrack.Visible = (value > 0 and value < 1)
        RbxlProgressFill.Size = UDim2.new(value, 0, 1, 0)
        if message and message ~= "" then
            RbxlStatusText.Text = ("[%d%%] %s"):format(math.floor(value * 100 + 0.5), tostring(message))
        end
        if value >= 1 then
            RbxlProgressFill.Size = UDim2.new(1, 0, 1, 0)
            task.delay(1.5, function()
                if RbxlProgressTrack and RbxlProgressTrack.Parent then
                    RbxlProgressTrack.Visible = false
                    RbxlProgressFill.Size = UDim2.new(0, 0, 1, 0)
                end
            end)
        end
    end
    _G.HYAZ_IMPORT_PROGRESS_CB = setRbxlProgress

    local function updateRbxlCount()
        RbxlCountText.Text = ("FILES %d • IMP %d"):format(rbxlFileCount, rbxlImportedCount)
    end

    local function clearRbxlCards()
        for _, item in ipairs(rbxlCards) do
            if item.card then item.card:Destroy() end
        end
        rbxlCards = {}
    end

    local function filterRbxlCards()
        local q = RbxlSearchBox.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
        for _, item in ipairs(rbxlCards) do
            local match = (q == "")
                or (item.info.name:lower():find(q, 1, true) ~= nil)
                or (item.info.path:lower():find(q, 1, true) ~= nil)
            item.card.Visible = match
        end
        RbxlEmpty.Visible = (#rbxlCards == 0)
    end

    local function makeRbxlCard(info)
        RbxlEmpty.Visible = false
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -2, 0, 36)
        card.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
        card.BorderSizePixel = 0
        card.ZIndex = 14
        card.Parent = RbxlScroll
        makeCorner(card, 6)
        makeStroke(card, Color3.fromRGB(36, 40, 54), 1)

        local badge = Instance.new("TextLabel")
        badge.Size = UDim2.fromOffset(34, 16)
        badge.Position = UDim2.fromOffset(6, 10)
        badge.BackgroundColor3 = Color3.fromRGB(44, 25, 35)
        badge.Text = "RBXL"
        badge.TextColor3 = Color3.fromRGB(255, 120, 140)
        badge.Font = Enum.Font.GothamBold
        badge.TextSize = 6.5
        badge.ZIndex = 15
        badge.Parent = card
        makeCorner(badge, 4)

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(1, -125, 0, 14)
        nameLbl.Position = UDim2.fromOffset(46, 4)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = info.name
        nameLbl.TextColor3 = Color3.fromRGB(240, 242, 250)
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextSize = 7.5
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        nameLbl.ZIndex = 15
        nameLbl.Parent = card

        local pathLbl = Instance.new("TextLabel")
        pathLbl.Size = UDim2.new(1, -125, 0, 11)
        pathLbl.Position = UDim2.fromOffset(46, 19)
        pathLbl.BackgroundTransparency = 1
        pathLbl.Text = info.path
        pathLbl.TextColor3 = Color3.fromRGB(125, 130, 150)
        pathLbl.Font = Enum.Font.Code
        pathLbl.TextSize = 6
        pathLbl.TextXAlignment = Enum.TextXAlignment.Left
        pathLbl.TextTruncate = Enum.TextTruncate.AtEnd
        pathLbl.ZIndex = 15
        pathLbl.Parent = card

        local importBtn = Instance.new("TextButton")
        importBtn.Size = UDim2.fromOffset(66, 22)
        importBtn.Position = UDim2.new(1, -72, 0.5, -11)
        importBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
        importBtn.Text = "IMPORT"
        importBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        importBtn.Font = Enum.Font.GothamBold
        importBtn.TextSize = 7.5
        importBtn.AutoButtonColor = false
        importBtn.ZIndex = 15
        importBtn.Parent = card
        makeCorner(importBtn, 5)
        makeStroke(importBtn, Color3.fromRGB(114, 137, 218), 1, 0.4)

        local importedRoot = nil
        importBtn.MouseButton1Click:Connect(function()
            if importBtn.Text == "IMPORTING" or importBtn.Text == "ACTIVATING" then
                return
            end
            if importBtn.Text == "ACTIVE" then
                setRbxlStatus("ALREADY ACTIVE • " .. info.name, Color3.fromRGB(79, 211, 145))
                return
            end
            importBtn.Text = "IMPORTING"
            importBtn.BackgroundColor3 = Color3.fromRGB(170, 100, 30)
            setRbxlProgress(0.01, "Reading file " .. info.name)
            setRbxlStatus("IMPORTING " .. info.name, Color3.fromRGB(241, 173, 74))

            task.spawn(function()
                local ok, message, root = RbxlEngine.import(info)
                if ok then
                    rbxlImportedCount = rbxlImportedCount + (1)
                    updateRbxlCount()
                    importedRoot = root
                    importBtn.Text = "ACTIVATING"
                    importBtn.BackgroundColor3 = Color3.fromRGB(130, 80, 25)
                    setRbxlStatus(message .. " • ACTIVATING", Color3.fromRGB(241, 173, 74))

                    local activateOK, activateMessage = RbxlEngine.activate(importedRoot)
                    if activateOK then
                        importBtn.Text = "ACTIVE"
                        importBtn.BackgroundColor3 = Color3.fromRGB(35, 120, 75)
                        setRbxlProgress(1.00, "RBXL GENERATION COMPLETE")
                        setRbxlStatus(activateMessage, Color3.fromRGB(79, 211, 145))
                        showToast("RBXL Loaded: " .. info.name, Color3.fromRGB(40, 160, 90))
                    else
                        importBtn.Text = "ACTIVATE"
                        importBtn.BackgroundColor3 = Color3.fromRGB(140, 60, 30)
                        setRbxlStatus("AUTO ACTIVATE ERROR: " .. tostring(activateMessage), Color3.fromRGB(255, 79, 99))
                        showToast("RBXL Activate Error", Color3.fromRGB(200, 50, 50))
                    end
                else
                    importBtn.Text = "FAILED"
                    importBtn.BackgroundColor3 = Color3.fromRGB(160, 40, 50)
                    setRbxlStatus(message, Color3.fromRGB(255, 79, 99))
                    showToast("RBXL Import Failed", Color3.fromRGB(200, 50, 50))
                    task.wait(2.5)
                    if importBtn and importBtn.Parent then
                        importBtn.Text = "IMPORT"
                        importBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
                    end
                end
            end)
        end)

        table.insert(rbxlCards, { info = info, card = card })
    end

    local function scanAllRbxlNow()
        RbxlScanBtn.Text = "SCANNING..."
        RbxlScanBtn.BackgroundColor3 = Color3.fromRGB(60, 70, 140)
        setRbxlStatus("SCANNING WORKSPACE...", Color3.fromRGB(241, 173, 74))
        clearRbxlCards()
        rbxlFileCount = 0
        rbxlImportedCount = 0
        updateRbxlCount()
        RbxlEmpty.Visible = true
        RbxlEmpty.Text = "SCANNING WORKSPACE FOLDERS..."

        task.spawn(function()
            if type(listfiles) ~= "function" then
                RbxlEmpty.Text = "listfiles() API tidak tersedia di executor ini"
                setRbxlStatus("ERROR: listfiles() not supported", Color3.fromRGB(255, 79, 99))
                RbxlScanBtn.Text = "SCAN FILES"
                RbxlScanBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
                return
            end
            local ok, results = pcall(RbxlEngine.scanAll)
            if not ok then
                RbxlEmpty.Text = "SCAN FAILED: " .. tostring(results)
                setRbxlStatus("SCAN ERROR: " .. tostring(results), Color3.fromRGB(255, 79, 99))
                RbxlScanBtn.Text = "SCAN FILES"
                RbxlScanBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
                return
            end
            for _, info in ipairs(results) do
                makeRbxlCard(info)
                task.wait()
            end
            rbxlFileCount = #results
            updateRbxlCount()
            if rbxlFileCount == 0 then
                RbxlEmpty.Visible = true
                RbxlEmpty.Text = "NO .RBXL FILES FOUND IN WORKSPACE\nPlace .rbxl in Delta/workspace or workspace/"
                setRbxlStatus("SCAN COMPLETE • 0 FILES", Color3.fromRGB(241, 173, 74))
            else
                RbxlEmpty.Visible = false
                setRbxlStatus(("SCAN COMPLETE • %d RBXL FILES FOUND"):format(rbxlFileCount), Color3.fromRGB(79, 211, 145))
            end
            RbxlScanBtn.Text = "SCAN FILES"
            RbxlScanBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
            filterRbxlCards()
        end)
    end

    RbxlSearchBox:GetPropertyChangedSignal("Text"):Connect(filterRbxlCards)
    RbxlScanBtn.MouseButton1Click:Connect(scanAllRbxlNow)

    -- Auto scan on first switch to RBXL tab
    local hasScannedRbxl = false
    local oldSwitchTab = switchTab
    switchTab = function(tabKey)
        oldSwitchTab(tabKey)
        if tabKey == "RBXL" and not hasScannedRbxl then
            hasScannedRbxl = true
            task.delay(0.2, scanAllRbxlNow)
        end
    end
end
initPageRBXL()



RbxmHeader.Size = UDim2.new(1, 0, 0, 28); RbxmHeader.BackgroundTransparency = 1; RbxmHeader.ZIndex = 13; RbxmHeader.Parent = PageRBXM

local RbxmTitleLbl = Instance.new("TextLabel")
RbxmTitleLbl.Size = UDim2.new(1, -80, 1, 0); RbxmTitleLbl.BackgroundTransparency = 1
RbxmTitleLbl.Text = "INSERT RBXM FILE"; RbxmTitleLbl.Font = Enum.Font.GothamBold; RbxmTitleLbl.TextSize = 11
RbxmTitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
RbxmTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
RbxmTitleLbl.ZIndex = 14
RbxmTitleLbl.Parent = RbxmHeader

makeBackBtn(RbxmHeader, function() showPage(PageSplash) end)

local RbxmToolbar = Instance.new("Frame")
RbxmToolbar.Size = UDim2.new(1, 0, 0, 28); RbxmToolbar.Position = UDim2.new(0, 0, 0, 32)
RbxmToolbar.BackgroundTransparency = 1; RbxmToolbar.ZIndex = 13; RbxmToolbar.Parent = PageRBXM

local RbxmScanBtn = Instance.new("TextButton")
RbxmScanBtn.Size = UDim2.new(0, 84, 0, 24); RbxmScanBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
RbxmScanBtn.Text = "SCAN FILES"; RbxmScanBtn.Font = Enum.Font.GothamBold; RbxmScanBtn.TextSize = 10
RbxmScanBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
RbxmScanBtn.Active = true; RbxmScanBtn.ZIndex = 15; RbxmScanBtn.Parent = RbxmToolbar; makeCorner(RbxmScanBtn, 6)

-- INLINE INSERT PROGRESS BAR (SEJAJAR DENGAN SCAN FILES BUTTON)
local RbxmProgressFrame = Instance.new("Frame")
RbxmProgressFrame.Size = UDim2.new(1, -92, 1, 0)
RbxmProgressFrame.Position = UDim2.new(0, 92, 0, 0)
RbxmProgressFrame.BackgroundTransparency = 1
RbxmProgressFrame.ZIndex = 14
RbxmProgressFrame.Parent = RbxmToolbar

local RbxmInsertStatus = Instance.new("TextLabel")
RbxmInsertStatus.Size = UDim2.new(0.68, 0, 0, 14)
RbxmInsertStatus.Position = UDim2.new(0, 0, 0, 0)
RbxmInsertStatus.BackgroundTransparency = 1
RbxmInsertStatus.Text = "READY | AUTO-SOURCE: ON"
RbxmInsertStatus.Font = Enum.Font.GothamBold
RbxmInsertStatus.TextSize = 8.5
RbxmInsertStatus.TextColor3 = Color3.fromRGB(160, 225, 160)
RbxmInsertStatus.TextXAlignment = Enum.TextXAlignment.Left
RbxmInsertStatus.ZIndex = 15
RbxmInsertStatus.Parent = RbxmProgressFrame

local RbxmInsertPct = Instance.new("TextLabel")
RbxmInsertPct.Size = UDim2.new(0.32, 0, 0, 14)
RbxmInsertPct.Position = UDim2.new(0.68, 0, 0, 0)
RbxmInsertPct.BackgroundTransparency = 1
RbxmInsertPct.Text = "[.] Klik SCAN FILES"
RbxmInsertPct.Font = Enum.Font.Code
RbxmInsertPct.TextSize = 8.5
RbxmInsertPct.TextColor3 = Color3.fromRGB(200, 200, 210)
RbxmInsertPct.TextXAlignment = Enum.TextXAlignment.Right
RbxmInsertPct.ZIndex = 15
RbxmInsertPct.Parent = RbxmProgressFrame

local RbxmBarBg = Instance.new("Frame")
RbxmBarBg.Size = UDim2.new(1, 0, 0, 5)
RbxmBarBg.Position = UDim2.new(0, 0, 0, 17)
RbxmBarBg.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
RbxmBarBg.BorderSizePixel = 0
RbxmBarBg.ZIndex = 15
RbxmBarBg.Parent = RbxmProgressFrame
makeCorner(RbxmBarBg, 3)

local RbxmBarFill = Instance.new("Frame")
RbxmBarFill.Size = UDim2.new(0, 0, 1, 0)
RbxmBarFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
RbxmBarFill.BorderSizePixel = 0
RbxmBarFill.ZIndex = 16
RbxmBarFill.Parent = RbxmBarBg
makeCorner(RbxmBarFill, 3)

local function updateInlineInsertProgress(pct, statusText)
    RbxmInsertStatus.Text = statusText
    RbxmInsertStatus.TextColor3 = Color3.fromRGB(255, 255, 255)
    RbxmInsertPct.Text = tostring(math.floor(pct)) .. "%"
    TweenService:Create(RbxmBarFill, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(pct / 100, 0, 1, 0)
    }):Play()
end

local function resetInlineInsertProgress(fileCount)
    task.delay(1.5, function()
        pcall(function()
            TweenService:Create(RbxmBarFill, TweenInfo.new(0.4), { Size = UDim2.new(0, 0, 1, 0) }):Play()
            RbxmInsertStatus.Text = "READY | AUTO-SOURCE: ON"
            RbxmInsertStatus.TextColor3 = Color3.fromRGB(160, 225, 160)
            RbxmInsertPct.Text = tostring(fileCount or 0) .. " files found"
        end)
    end)
end

local RbxmCountLbl = RbxmInsertPct

-- SEARCH BAR DIPALING ATAS RBXM
local RbxmSearchCard = Instance.new("Frame")
RbxmSearchCard.Size = UDim2.new(1, -12, 0, 32)
RbxmSearchCard.Position = UDim2.new(0, 6, 0, 62)
RbxmSearchCard.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
RbxmSearchCard.BorderSizePixel = 0
RbxmSearchCard.ZIndex = 14
RbxmSearchCard.Parent = PageRBXM
makeCorner(RbxmSearchCard, 6)
makeStroke(RbxmSearchCard, Color3.fromRGB(255, 255, 255), 1, 0.85)

local RbxmSearchBox = Instance.new("TextBox")
RbxmSearchBox.Size = UDim2.new(1, -16, 1, 0)
RbxmSearchBox.Position = UDim2.new(0, 8, 0, 0)
RbxmSearchBox.BackgroundTransparency = 1
RbxmSearchBox.Font = Enum.Font.Gotham
RbxmSearchBox.TextSize = 10
RbxmSearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
RbxmSearchBox.PlaceholderText = "[?] Cari nama file .rbxm di sini..."
RbxmSearchBox.PlaceholderColor3 = Color3.fromRGB(140, 140, 150)
RbxmSearchBox.TextXAlignment = Enum.TextXAlignment.Left
RbxmSearchBox.ClearTextOnFocus = false
RbxmSearchBox.ZIndex = 15
RbxmSearchBox.Parent = RbxmSearchCard

local currentRbxmFilter = ""
local renderedRbxmCards = {}

local function filterRbxmList()
    local filter = currentRbxmFilter:lower():gsub("%s+", "")
    local visibleCount = 0
    for _, item in ipairs(renderedRbxmCards) do
        local match = (filter == "") or item.name:lower():find(filter, 1, true) or item.path:lower():find(filter, 1, true)
        item.card.Visible = (match ~= nil)
        if match then visibleCount = visibleCount + 1 end
    end
    if RbxmEmpty then
        RbxmEmpty.Visible = (visibleCount == 0)
        if visibleCount == 0 and #renderedRbxmCards > 0 then
            RbxmEmpty.Text = "Tidak ada file yang cocok dengan '" .. currentRbxmFilter .. "'"
        end
    end
end

RbxmSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    currentRbxmFilter = RbxmSearchBox.Text
    filterRbxmList()
end)

local RbxmScroll = Instance.new("ScrollingFrame")
RbxmScroll.Size = UDim2.new(1, -12, 1, -102); RbxmScroll.Position = UDim2.new(0, 6, 0, 98)
RbxmScroll.BackgroundColor3 = Color3.fromRGB(17, 17, 22); RbxmScroll.BorderSizePixel = 0
RbxmScroll.ScrollBarThickness = 3; RbxmScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
RbxmScroll.ZIndex = 14
RbxmScroll.Parent = PageRBXM; makeCorner(RbxmScroll, 8); makeStroke(RbxmScroll, Color3.fromRGB(255,255,255), 1, 0.78)

local RbxmList = Instance.new("UIListLayout")
RbxmList.Padding = UDim.new(0, 5); RbxmList.SortOrder = Enum.SortOrder.LayoutOrder; RbxmList.Parent = RbxmScroll
local RbxmPad = Instance.new("UIPadding")
RbxmPad.PaddingTop = UDim.new(0, 6); RbxmPad.PaddingLeft = UDim.new(0, 6); RbxmPad.PaddingRight = UDim.new(0, 6); RbxmPad.Parent = RbxmScroll

local RbxmEmpty = Instance.new("TextLabel")
RbxmEmpty.Size = UDim2.new(1, 0, 0, 40); RbxmEmpty.BackgroundTransparency = 1
RbxmEmpty.Text = "Belum ada file .rbxm ditemukan. Klik SCAN FILES."
RbxmEmpty.Font = Enum.Font.Gotham; RbxmEmpty.TextSize = 10
RbxmEmpty.TextColor3 = Color3.fromRGB(140, 140, 150)
RbxmEmpty.ZIndex = 15
RbxmEmpty.Parent = RbxmScroll

-- =====================================================
-- LOGIC: SMART INSERT ASSET ID
-- =====================================================
-- =====================================================
-- SMART ASSET POSITIONING & AUTO-ANCHOR HELPER
-- Menghilangkan bug "spawn kejauhan" dan mencegah part jatuh / fling
-- Menempatkan model / part tepat di depan arah pandang Kamera Studio Lite
-- =====================================================
local function positionAndAnchorAsset(obj)
    if not obj then return end

    -- 1. RECURSIVE AUTO-ANCHOR & VELOCITY FREEZE
    pcall(function()
        if obj:IsA("BasePart") then
            obj.Anchored = true
            obj.Velocity = Vector3.zero
            obj.RotVelocity = Vector3.zero
            obj.AssemblyLinearVelocity = Vector3.zero
            obj.AssemblyAngularVelocity = Vector3.zero
        end
        for _, desc in ipairs(obj:GetDescendants()) do
            if desc:IsA("BasePart") then
                desc.Anchored = true
                desc.Velocity = Vector3.zero
                desc.RotVelocity = Vector3.zero
                desc.AssemblyLinearVelocity = Vector3.zero
                desc.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end)

    pcall(applyStudioLiteProps, obj)

    -- 2. TARGET POSITIONING DI DEPAN KAMERA AKTIF STUDIO LITE
    local targetPos = nil
    local cam = workspace.CurrentCamera

    if cam and cam.CFrame then
        local camCF = cam.CFrame
        local rayOrigin = camCF.Position
        local rayDir = camCF.LookVector * 28

        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        local filterList = {obj}
        if LP.Character then table.insert(filterList, LP.Character) end
        rayParams.FilterDescendantsInstances = filterList

        local rayResult = nil
        pcall(function() rayResult = workspace:Raycast(rayOrigin, rayDir, rayParams) end)

        if rayResult and rayResult.Position then
            targetPos = rayResult.Position + Vector3.new(0, 1.5, 0)
        else
            targetPos = camCF.Position + (camCF.LookVector * 12)
        end
    elseif LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LP.Character.HumanoidRootPart
        targetPos = hrp.Position + (hrp.CFrame.LookVector * 8) + Vector3.new(0, 1, 0)
    else
        targetPos = Vector3.new(0, 5, 0)
    end

    -- 3. PINDAHKAN OBJEK KE TARGET POS
    if targetPos then
        pcall(function()
            if obj:IsA("Model") then
                local cf, sz = obj:GetBoundingBox()
                local bottomOffset = sz.Y / 2
                obj:PivotTo(CFrame.new(targetPos + Vector3.new(0, bottomOffset, 0)))
            elseif obj:IsA("BasePart") then
                obj.CFrame = CFrame.new(targetPos + Vector3.new(0, obj.Size.Y / 2, 0))
            else
                local parts = {}
                for _, d in ipairs(obj:GetDescendants()) do
                    if d:IsA("BasePart") then table.insert(parts, d) end
                end
                if #parts > 0 then
                    local avgPos = Vector3.zero
                    for _, p in ipairs(parts) do avgPos = avgPos + p.Position end
                    avgPos = avgPos / #parts
                    local delta = targetPos - avgPos
                    for _, p in ipairs(parts) do
                        p.CFrame = p.CFrame + delta
                    end
                end
            end
        end)
    end
end

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
                positionAndAnchorAsset(o)
                loadAssetsToSLServer(o)
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
-- LOGIC: SMART INSERT RBXM DENGAN AUTO-EXTRACT
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

-- =====================================================
-- PURE LUA LZ4 & BINARY RBXM DECOMPRESSOR / PARSER
-- 100% LOSSLESS RECOVERY OF SCRIPT SOURCES
-- =====================================================

local function getPackSize(fmt)
    if not fmt then return 1 end
    if fmt == "<I4" or fmt == ">I4" or fmt == "<i4" or fmt == ">i4" or fmt == "I4" or fmt == "i4" or fmt == ">f" or fmt == "<f" then return 4 end
    if fmt == "<I2" or fmt == ">I2" or fmt == "<i2" or fmt == ">i2" or fmt == "I2" or fmt == "i2" then return 2 end
    if fmt == "<I8" or fmt == ">I8" or fmt == "<i8" or fmt == ">i8" or fmt == "I8" or fmt == "i8" or fmt == "<d" or fmt == ">d" then return 8 end
    if fmt == "I1" or fmt == "i1" or fmt == "B" or fmt == "b" then return 1 end
    local ok, sz = pcall(function() return #string.pack(fmt, 0) end)
    return (ok and sz) or 4
end
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

        fmt = fmt or "I1"; local sz = getPackSize(fmt); local chunk = self:read(sz, shift); if #chunk < sz then return 0 end; local ok, val = pcall(string.unpack, fmt, chunk); return ok and val or 0

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

    return (buffer and buffer.tostring and buffer.tostring(x)) or ""

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

        local classID = buffer:readNumber("<I4"); local className = basicTypes.String(buffer)

        if buffer:read() == "\1" then return sources, "Contains services" end

        local count = buffer:readNumber("<I4"); local refs = basicTypes.RefArray(buffer, count)

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


local function parseAllSources(data)
    local sources = {}
    if not data or #data < 20 then return sources end
    
    -- 1. If Binary format (<roblox!), use the lossless LZ4 parser
    if data:sub(1, 8) == "<roblox!" then
        local ok, res, err = pcall(parseRBXMForSources, data)
        if ok and res and type(res) == "table" then
            for k, v in pairs(res) do
                sources[k] = v
                local cleanName = k:match(":([%w_]+)$") or k:match("%.([%w_]+)$") or k
                sources[cleanName] = v
            end
        end
    end

    -- 2. If XML format or fallback, extract CDATA ProtectedString
    for class, name, code in data:gmatch('<Item class="([%w_]+)"[^>]*>%s*<Properties>%s*<string name="Name">([^<]+)</string>.-<ProtectedString name="Source"><%!%[CDATA%[(.-)%]%]></ProtectedString>') do
        sources[class .. ":" .. name] = code
        sources[name] = code
    end
    for name, code in data:gmatch('<string name="Name">([^<]+)</string>.-<ProtectedString name="Source"><%!%[CDATA%[(.-)%]%]></ProtectedString>') do
        sources[name] = code
    end

    return sources
end

-- =====================================================
-- STUDIO LITE SCRIPT UI INJECTOR & ANTI-READONLY LOGIC
-- =====================================================
local SL_CACHE = {}

local function injectStudioLiteUI(scr, sourceMap)
    if not scr or not scr:IsA("LuaSourceContainer") then return end
    
    local path = scr.ClassName .. ":" .. scr.Name
    local realSource = sourceMap and (sourceMap[path] or sourceMap[scr.Name])
    
    if not realSource and sourceMap then
        for k, v in pairs(sourceMap) do
            if k:sub(-#scr.Name) == scr.Name or k:find(scr.Name, 1, true) then
                realSource = v
                break
            end
        end
    end
    
    if not realSource then
        pcall(function() realSource = scr.Source end)
    end
    
    if realSource and #realSource > 0 then
        realSource = stripRichText(realSource:gsub("%z*$", ""))
    else
        realSource = "-- [BLUExCrown] Script source empty or unreadable."
    end

    -- Store into memory registries
    storeScriptSource(scr, realSource)
    storeScriptSource(scr.Name, realSource)
    storeScriptSource(scr.ClassName .. scr.Name, realSource)
    pcall(function() scr.Source = realSource end)

    -- CRITICAL ANTI-READONLY: Destroy any SL_1ReadOnly so Studio Lite NEVER enforces Read-Only!
    local ro = scr:FindFirstChild("SL_1ReadOnly")
    if ro then
        pcall(function() ro:Destroy() end)
    end

    -- Setup Studio Lite internal text box
    local existingTB = scr:FindFirstChild("SL_CodeTextBox")
    if existingTB then
        existingTB.Text = realSource
        return
    end

    if not serverFuncs then return end
    local map = {
        Script = "InsertScriptScript",
        LocalScript = "InsertLocalScriptLocalScript",
        ModuleScript = "InsertModuleScriptModuleScript"
    }
    local assetName = map[scr.ClassName]
    if not assetName then return end

    if not SL_CACHE[assetName] then
        pcall(function()
            serverFuncs:InvokeServer("LoadAssetToPlayerGui", assetName)
            local guiF = LP:WaitForChild("PlayerGui"):WaitForChild(assetName, 3)
            if guiF then
                SL_CACHE[assetName] = {}
                for _, c in ipairs(guiF:GetChildren()) do
                    table.insert(SL_CACHE[assetName], c:Clone())
                end
                serverFuncs:InvokeServer("ClearAssetFromPlayerGui", assetName)
            end
        end)
    end

    if not SL_CACHE[assetName] then return end

    pcall(function()
        for _, c in ipairs(SL_CACHE[assetName]) do
            -- NEVER attach SL_1ReadOnly so the script stays 100% editable!
            if c.Name ~= "SL_1ReadOnly" and not scr:FindFirstChild(c.Name) then
                c:Clone().Parent = scr
            end
        end
        local tb = scr:FindFirstChild("SL_CodeTextBox")
        if tb then
            tb.Text = realSource
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

-- =====================================================
-- SCRIPT RECREATOR LOGIC ("HOOK BOT RECREATE")
-- Completely replaces stubborn/locked scripts with clean native instances!
-- =====================================================
local function recreateScriptAsNative(oldScript, sourceCode)
    if not oldScript or not oldScript:IsA("LuaSourceContainer") then return nil end
    local parent = oldScript.Parent
    local name = oldScript.Name
    local className = oldScript.ClassName

    local src = sourceCode or lookupScriptSource(oldScript) or "-- Recreated Script"

    local newScript = Instance.new(className)
    newScript.Name = name

    -- Clone non-script children (skip SL_1ReadOnly)
    for _, ch in ipairs(oldScript:GetChildren()) do
        if not ch:IsA("LuaSourceContainer") and ch.Name ~= "SL_1ReadOnly" then
            pcall(function() ch:Clone().Parent = newScript end)
        end
    end

    -- Clone attributes
    for attr, val in pairs(oldScript:GetAttributes()) do
        pcall(function() newScript:SetAttribute(attr, val) end)
    end

    -- Assign source & register
    pcall(function() newScript.Source = src end)
    storeScriptSource(newScript, src)
    storeScriptSource(name, src)
    storeScriptSource(className .. name, src)

    -- Inject Studio Lite template
    injectStudioLiteUI(newScript, {[className .. ":" .. name] = src, [name] = src})

    -- Replace in hierarchy
    newScript.Parent = parent
    pcall(function() oldScript:Destroy() end)

    return newScript
end

local function smartInsertRbxm(filePath, fileName)
    if updateInlineInsertProgress then
        updateInlineInsertProgress(15, "[1/5] READING BINARY FILE...")
    end
    task.wait(0.3)

    local insertOk, statusMsg = false, ""
    local data = safeReadFile(filePath)
    local parsedSources = {}

    if data and #data > 0 then
        if updateInlineInsertProgress then
            updateInlineInsertProgress(38, "[2/5] DECOMPRESSING LZ4 CHUNKS...")
        end
        task.wait(0.35)

        parsedSources = parseAllSources(data)
        for k, v in pairs(parsedSources) do
            storeScriptSource(k, stripRichText(v))
        end
        local baseName = fileName:gsub("%.rbxm.*", "")
        for _, v in pairs(parsedSources) do
            storeScriptSource(baseName, stripRichText(v))
            break
        end

        if updateInlineInsertProgress then
            updateInlineInsertProgress(65, "[3/5] STRIPPING RICHTEXT TAGS...")
        end
        task.wait(0.3)
    end

    if updateInlineInsertProgress then
        updateInlineInsertProgress(82, "[4/5] INJECTING TO WORKSPACE...")
    end
    task.wait(0.35)

    local function setupObjects(objs)
        for _, o in ipairs(objs) do
            o.Parent = workspace
            applyStudioLiteProps(o)
            positionAndAnchorAsset(o)
            loadAssetsToSLServer(o)

            -- RECREATE SCRIPTS AS NATIVE ROBLOX INSTANCES
            -- Mengubah semua script menjadi instance fresh & native dengan SL_CodeTextBox terpasang
            -- dan SL_1ReadOnly dihancurkan agar Studio Lite mengenalinya sebagai script biasa yang bisa diedit!
            local scriptList = {}
            if o:IsA("LuaSourceContainer") then table.insert(scriptList, o) end
            for _, d in ipairs(o:GetDescendants()) do
                if d:IsA("LuaSourceContainer") then table.insert(scriptList, d) end
            end

            for _, scr in ipairs(scriptList) do
                local path = scr.ClassName .. ":" .. scr.Name
                local src = parsedSources[path] or parsedSources[scr.Name]
                if not src then
                    for k, v in pairs(parsedSources) do
                        if k:sub(-#scr.Name) == scr.Name or k:find(scr.Name, 1, true) then
                            src = v
                            break
                        end
                    end
                end
                if not src then
                    pcall(function() src = scr.Source end)
                end
                src = stripRichText(src or "-- Script source")

                -- Recreate fresh native script
                recreateScriptAsNative(scr, src)
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
                    insertOk = true; statusMsg = "customAsset OK"
                end
            end
        end)
    end

    if not insertOk then
        pcall(function()
            local objs = game:GetObjects("rbxasset://" .. filePath)
            if objs and #objs > 0 then
                setupObjects(objs)
                insertOk = true; statusMsg = "rbxasset:// OK"
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
                    insertOk = true; statusMsg = "readfile+tmp OK"
                end
            end
            pcall(function() if delfile then delfile(tmpName) end end)
        end)
    end

    if updateInlineInsertProgress then
        updateInlineInsertProgress(100, insertOk and "[5/5] SUCCESS! READY TO EDIT" or "[5/5] INSERT FINISHED")
        resetInlineInsertProgress()
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
    local lastYield = os.clock()
    local function scanDeep(folder, depth)
        if depth > 4 or seen[folder] then return end
        seen[folder] = true
        local files = safeListFiles(folder)
        if not files then return end
        for _, path in ipairs(files) do
            -- Anti-Lag Framerate Throttling ala FORKT (tetap 60 FPS saat scan)
            if os.clock() - lastYield > 0.015 then
                task.wait()
                lastYield = os.clock()
            end
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
    renderedRbxmCards = {}
    RbxmCountLbl.Text = "[.] Scanning..."
    local files = getAllRbxmFiles()
    RbxmEmpty.Visible = (#files == 0)
    if #files == 0 then
        RbxmCountLbl.Text = not listfilesFn and "[!] listfiles() tidak support" or "[!] Tidak ada file .rbxm"
        return
    end
    RbxmCountLbl.Text = string.format("[OK] %d file ditemukan", #files)
    for _, file in ipairs(files) do
        local card = Instance.new("Frame")
        table.insert(renderedRbxmCards, { card = card, name = file.name, path = file.path })
        card.Size = UDim2.new(1, -12, 0, 50); card.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        card.BorderSizePixel = 0; card.Parent = RbxmScroll; makeCorner(card, 7); makeStroke(card, Color3.fromRGB(255,255,255), 1, 0.85)

        local fileIcon = Instance.new("TextLabel")
        fileIcon.Size = UDim2.new(0, 36, 0, 36); fileIcon.Position = UDim2.new(0, 5, 0.5, -18)
        fileIcon.BackgroundColor3 = Color3.fromRGB(28, 28, 34); fileIcon.Text = ".rbxm"
        fileIcon.Font = Enum.Font.GothamBold; fileIcon.TextSize = 7
        fileIcon.TextColor3 = Color3.fromRGB(200, 200, 210); fileIcon.Parent = card; makeCorner(fileIcon, 6)

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(1, -195, 0, 18); nameLbl.Position = UDim2.new(0, 48, 0, 7)
        nameLbl.BackgroundTransparency = 1; nameLbl.Text = file.name
        nameLbl.Font = Enum.Font.GothamBold; nameLbl.TextSize = 11
        nameLbl.TextColor3 = Color3.fromRGB(240, 240, 245)
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left; nameLbl.TextTruncate = Enum.TextTruncate.AtEnd; nameLbl.Parent = card

        local pathLbl = Instance.new("TextLabel")
        pathLbl.Size = UDim2.new(1, -195, 0, 13); pathLbl.Position = UDim2.new(0, 48, 0, 28)
        pathLbl.BackgroundTransparency = 1; pathLbl.Text = file.path
        pathLbl.Font = Enum.Font.Gotham; pathLbl.TextSize = 8
        pathLbl.TextColor3 = Color3.fromRGB(130, 130, 140)
        pathLbl.TextXAlignment = Enum.TextXAlignment.Left; pathLbl.TextTruncate = Enum.TextTruncate.AtEnd; pathLbl.Parent = card

        -- Tombol Edit Langsung
        local edBtn = Instance.new("TextButton")
        edBtn.Size = UDim2.new(0, 50, 0, 30); edBtn.Position = UDim2.new(1, -135, 0.5, -15)
        edBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
        edBtn.Text = "EDIT"
        edBtn.Font = Enum.Font.GothamBold
        edBtn.TextSize = 9
        edBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        edBtn.Active = true
        edBtn.ZIndex = 16
        edBtn.Parent = card
        makeCorner(edBtn, 6)
        makeStroke(edBtn, Color3.fromRGB(255,255,255), 1, 0.7)

        edBtn.Activated:Connect(function()
            local code = lookupScriptSource(file.name:gsub("%.rbxm.*", ""))
            if not code or code == "" then
                local d = safeReadFile(file.path)
                if d then
                    local s = parseRBXMSources(d)
                    for _, v in pairs(s) do code = v; break end
                end
            end
            openInEditor(file.name:gsub("%.rbxm.*", ""), code or "-- Script tidak ditemukan")
        end)

        local insertBtn = Instance.new("TextButton")
        insertBtn.Size = UDim2.new(0, 70, 0, 30); insertBtn.Position = UDim2.new(1, -76, 0.5, -15)
        insertBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        insertBtn.Text = "INSERT"
        insertBtn.Font = Enum.Font.GothamBold
        insertBtn.TextSize = 9
        insertBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        insertBtn.Active = true
        insertBtn.ZIndex = 16
        insertBtn.Parent = card
        makeCorner(insertBtn, 6)

        insertBtn.Activated:Connect(function()
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

RbxmScanBtn.Activated:Connect(renderRbxmCards)

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

TbDetCopy.Activated:Connect(function()
    if currentInspId ~= "" and clipFn then
        pcall(clipFn, currentInspId); TbDetCopy.Text = "COPIED!"
        task.delay(1.2, function() if TbDetCopy and TbDetCopy.Parent then TbDetCopy.Text = "COPY ID" end end)
    end
end)

TbDetInsert.Activated:Connect(function()
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

local function httpFetch(url)
    -- 1. Universal executor GET (Delta, Codex, Arceus, Fluxus, etc.)
    local ok1, res1 = pcall(game.HttpGet, game, url)
    if ok1 and type(res1) == "string" and #res1 > 0 then
        return res1
    end
    -- 2. Executor request table call
    local reqFn = request or http_request or (syn and syn.request) or (http and http.request)
    if type(reqFn) == "function" then
        local ok2, res2 = pcall(reqFn, {
            Url = url,
            Method = "GET",
            Headers = { ["User-Agent"] = "RobloxStudio/WinInet" }
        })
        if ok2 and type(res2) == "table" and res2.Body and #res2.Body > 0 then
            return res2.Body
        end
    end
    -- 3. HttpService fallback
    local ok3, res3 = pcall(function() return HttpService:GetAsync(url) end)
    if ok3 and type(res3) == "string" and #res3 > 0 then
        return res3
    end
    return nil
end

local function queryMarketplace(catId, query)
    local enc = HttpService:UrlEncode(query)
    local baseUrls = {
        "https://apis.roproxy.com/toolbox-service/v1/marketplace/%d?keyword=%s&limit=30",
        "https://apis.roblox.com/toolbox-service/v1/marketplace/%d?keyword=%s&limit=30",
    }
    for _, bUrl in ipairs(baseUrls) do
        local url1 = bUrl:format(catId, enc)
        local raw1 = httpFetch(url1)
        if raw1 and #raw1 > 0 then
            local ds, parsed = pcall(function() return HttpService:JSONDecode(raw1) end)
            if ds and parsed and parsed.data and #parsed.data > 0 then
                local allItems = {}
                for _, item in ipairs(parsed.data) do table.insert(allItems, item) end
                
                -- AUTO MULTI-FETCH: Ambil halaman ke-2 otomatis jika cursor tersedia (Total 60 aset!)
                if parsed.nextPageCursor and tostring(parsed.nextPageCursor) ~= "" then
                    pcall(function()
                        local url2 = (bUrl .. "&cursor=%s"):format(catId, enc, HttpService:UrlEncode(tostring(parsed.nextPageCursor)))
                        local raw2 = httpFetch(url2)
                        if raw2 and #raw2 > 0 then
                            local ds2, parsed2 = pcall(function() return HttpService:JSONDecode(raw2) end)
                            if ds2 and parsed2 and parsed2.data and #parsed2.data > 0 then
                                for _, item2 in ipairs(parsed2.data) do table.insert(allItems, item2) end
                            end
                        end
                    end)
                end
                
                return allItems
            end
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
        iBtn.TextColor3 = Color3.fromRGB(0, 0, 0); iBtn.Active = true; iBtn.Parent = btnRow; makeCorner(iBtn, 4)
        local cBtn = Instance.new("TextButton")
        cBtn.Size = UDim2.new(0.5, -2, 1, 0); cBtn.Position = UDim2.new(0.5, 2, 0, 0)
        cBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255); cBtn.Text = "COPY"
        cBtn.Font = Enum.Font.GothamBold; cBtn.TextSize = 8
        cBtn.TextColor3 = Color3.fromRGB(0, 0, 0); cBtn.Active = true; cBtn.Parent = btnRow; makeCorner(cBtn, 4)

        cBtn.Activated:Connect(function()
            if clipFn then pcall(clipFn, assetId); cBtn.Text = "OK!"
                task.delay(1.2, function() if cBtn and cBtn.Parent then cBtn.Text = "COPY" end end) end
        end)
        iBtn.Activated:Connect(function()
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
        hitbox.Size = UDim2.new(1, 0, 0, 86); hitbox.BackgroundTransparency = 1; hitbox.Text = ""; hitbox.Active = true; hitbox.Parent = card
        hitbox.Activated:Connect(function() inspectAsset(assetId, nameL.Text, creator) end)

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
TbSearchBtn.Activated:Connect(execSearch)
TbSearchBox.FocusLost:Connect(function(enter) if enter then execSearch() end end)

TbInsertIdBtn.Activated:Connect(function()
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


-- =====================================================
-- =====================================================
-- =====================================================
-- =====================================================

-- PAGE 4: 3D TEXT GENERATOR (GENE TEXT 3D) [MODULAR SCOPE]
-- =====================================================
local function initText3DPage()
-- PAGE 4: 3D TEXT GENERATOR (GENE TEXT 3D)
-- Fitur pembuat teks 3D kustom langsung di map (Extruded Parts)
-- Layout Split: Kiri Realtime Viewport Preview, Kanan Kontrol & Warna Kotak-Kotak
-- =====================================================

-- ---- 5x7 BITMAP FONT MATRIX ------------------------------------------------------
local FONT_5X7 = {
    ["A"] = {"01110","10001","10001","11111","10001","10001","10001"},
    ["B"] = {"11110","10001","10001","11110","10001","10001","11110"},
    ["C"] = {"01111","10000","10000","10000","10000","10000","01111"},
    ["D"] = {"11110","10001","10001","10001","10001","10001","11110"},
    ["E"] = {"11111","10000","10000","11110","10000","10000","11111"},
    ["F"] = {"11111","10000","10000","11110","10000","10000","10000"},
    ["G"] = {"01111","10000","10000","10111","10001","10001","01111"},
    ["H"] = {"10001","10001","10001","11111","10001","10001","10001"},
    ["I"] = {"11111","00100","00100","00100","00100","00100","11111"},
    ["J"] = {"00111","00010","00010","00010","00010","10010","01100"},
    ["K"] = {"10001","10010","10100","11000","10100","10010","10001"},
    ["L"] = {"10000","10000","10000","10000","10000","10000","11111"},
    ["M"] = {"10001","11011","10101","10001","10001","10001","10001"},
    ["N"] = {"10001","11001","10101","10011","10001","10001","10001"},
    ["O"] = {"01110","10001","10001","10001","10001","10001","01110"},
    ["P"] = {"11110","10001","10001","11110","10000","10000","10000"},
    ["Q"] = {"01110","10001","10001","10001","10101","10010","01101"},
    ["R"] = {"11110","10001","10001","11110","10100","10010","10001"},
    ["S"] = {"01111","10000","10000","01110","00001","00001","11110"},
    ["T"] = {"11111","00100","00100","00100","00100","00100","00100"},
    ["U"] = {"10001","10001","10001","10001","10001","10001","01110"},
    ["V"] = {"10001","10001","10001","10001","10001","01010","00100"},
    ["W"] = {"10001","10001","10001","10101","10101","11011","10001"},
    ["X"] = {"10001","10001","01010","00100","01010","10001","10001"},
    ["Y"] = {"10001","10001","01010","00100","00100","00100","00100"},
    ["Z"] = {"11111","00001","00010","00100","01000","10000","11111"},
    ["0"] = {"01110","10011","10101","11001","10001","10001","01110"},
    ["1"] = {"00100","01100","00100","00100","00100","00100","01110"},
    ["2"] = {"01110","10001","00001","00110","01000","10000","11111"},
    ["3"] = {"11110","00001","00001","01110","00001","00001","11110"},
    ["4"] = {"10001","10001","10001","11111","00001","00001","00001"},
    ["5"] = {"11111","10000","10000","11110","00001","00001","11110"},
    ["6"] = {"01110","10000","10000","11110","10001","10001","01110"},
    ["7"] = {"11111","00001","00010","00100","01000","01000","01000"},
    ["8"] = {"01110","10001","10001","01110","10001","10001","01110"},
    ["9"] = {"01110","10001","10001","01111","00001","00001","01110"},
    [" "] = {"00000","00000","00000","00000","00000","00000","00000"},
    ["-"] = {"00000","00000","00000","11111","00000","00000","00000"},
    ["+"] = {"00000","00100","00100","11111","00100","00100","00000"},
    ["="] = {"00000","00000","11111","00000","11111","00000","00000"},
    [":"] = {"00000","00100","00000","00000","00100","00000","00000"},
    ["."] = {"00000","00000","00000","00000","00000","01100","01100"},
    ["!"] = {"00100","00100","00100","00100","00100","00000","00100"},
    ["?"] = {"01110","10001","00001","00010","00100","00000","00100"},
    ["_"] = {"00000","00000","00000","00000","00000","00000","11111"},
}

local function greedyMeshChar(charStr)
    local pat = FONT_5X7[charStr] or FONT_5X7["?"]
    local grid = {}
    for r = 1, 7 do
        grid[r] = {}
        local rowStr = pat[r] or "00000"
        for c = 1, 5 do
            grid[r][c] = (rowStr:sub(c, c) == "1") and 1 or 0
        end
    end

    local boxes = {}
    for r = 1, 7 do
        for c = 1, 5 do
            if grid[r][c] == 1 then
                local w = 1
                while c + w <= 5 and grid[r][c + w] == 1 do
                    w = w + 1
                end

                local h = 1
                while r + h <= 7 do
                    local fullRow = true
                    for dc = 0, w - 1 do
                        if grid[r + h][c + dc] ~= 1 then
                            fullRow = false
                            break
                        end
                    end
                    if fullRow then
                        h = h + 1
                    else
                        break
                    end
                end

                for dr = 0, h - 1 do
                    for dc = 0, w - 1 do
                        grid[r + dr][c + dc] = 0
                    end
                end

                table.insert(boxes, { col = c, row = r, w = w, h = h })
            end
        end
    end
    return boxes
end

-- Core Generator Function (Creates Model)
local function build3DTextModel(inputText, scale, depth, chosenColor, chosenMaterial)
    if not inputText or inputText == "" then return nil, 0 end
    scale = scale or 1.0
    depth = depth or 1.2
    chosenColor = chosenColor or Color3.fromRGB(0, 240, 255)
    chosenMaterial = chosenMaterial or Enum.Material.Neon

    local model = Instance.new("Model")
    model.Name = "3DText_" .. inputText:sub(1, 15)

    local upperText = inputText:upper()
    local charSpacing = 1.0 * scale
    local cursorX = 0
    local partCount = 0

    for i = 1, #upperText do
        local ch = upperText:sub(i, i)
        if ch == " " then
            cursorX = cursorX + 4 * scale
        else
            local boxes = greedyMeshChar(ch)
            for _, b in ipairs(boxes) do
                local part = Instance.new("Part")
                part.Name = ch .. "_" .. b.col .. "_" .. b.row
                part.Anchored = true
                part.CanCollide = true
                part.Material = chosenMaterial
                part.Color = chosenColor
                part.TopSurface = Enum.SurfaceType.Smooth
                part.BottomSurface = Enum.SurfaceType.Smooth

                local pw = b.w * scale
                local ph = b.h * scale
                part.Size = Vector3.new(pw, ph, depth)

                local posX = cursorX + (b.col - 1 + b.w / 2) * scale
                local posY = (7 - b.row - b.h / 2 + 0.5) * scale
                part.CFrame = CFrame.new(posX, posY, 0)
                part.Parent = model
                partCount = partCount + 1
            end
            cursorX = cursorX + (5 * scale) + charSpacing
        end
    end

    return model, partCount, cursorX
end

local function generate3DText(inputText, scale, depth, chosenColor, chosenMaterial)
    local model, partCount = build3DTextModel(inputText, scale, depth, chosenColor, chosenMaterial)
    if not model or partCount == 0 then
        if model then model:Destroy() end
        return false, "Masukkan teks yang valid!"
    end

    model.Parent = workspace
    pcall(applyStudioLiteProps, model)
    positionAndAnchorAsset(model)

    return true, "Sukses membuat 3D Text (" .. partCount .. " parts)!", model
end

-- ---- UI PAGE TEXT 3D BUILDER (SPLIT VIEW) --------------------------
local T3dHeader = Instance.new("Frame")
T3dHeader.Size = UDim2.new(1, 0, 0, 32); T3dHeader.BackgroundTransparency = 1
T3dHeader.ZIndex = 13; T3dHeader.Parent = PageText3D

local T3dTitleLbl = Instance.new("TextLabel")
T3dTitleLbl.Size = UDim2.new(1, -90, 1, 0); T3dTitleLbl.Position = UDim2.new(0, 8, 0, 0)
T3dTitleLbl.BackgroundTransparency = 1; T3dTitleLbl.Font = Enum.Font.GothamBold
T3dTitleLbl.TextSize = 13; T3dTitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
T3dTitleLbl.TextXAlignment = Enum.TextXAlignment.Left; T3dTitleLbl.Text = "[3D] GENERATOR TEKS 3D (SPLIT PREVIEW)"
T3dTitleLbl.ZIndex = 14; T3dTitleLbl.Parent = T3dHeader

makeBackBtn(T3dHeader, function() showPage(PageSplash) end)

-- State Variables
local t3d_scale = 1.0
local t3d_depth = 1.2
local t3d_color = Color3.fromRGB(0, 240, 255)
local t3d_material = Enum.Material.Neon

-- KIRI: PREVIEW REALTIME PANEL
local T3dLeftCard = Instance.new("Frame")
T3dLeftCard.Size = UDim2.new(0.42, 0, 1, -40); T3dLeftCard.Position = UDim2.new(0, 0, 0, 36)
T3dLeftCard.BackgroundColor3 = Color3.fromRGB(16, 16, 22); T3dLeftCard.BorderSizePixel = 0
T3dLeftCard.ZIndex = 13; T3dLeftCard.Parent = PageText3D
makeCorner(T3dLeftCard, 8); makeStroke(T3dLeftCard, Color3.fromRGB(255, 255, 255), 1, 0.85)

local PreviewTitle = Instance.new("TextLabel")
PreviewTitle.Size = UDim2.new(1, -16, 0, 22); PreviewTitle.Position = UDim2.new(0, 8, 0, 6)
PreviewTitle.BackgroundTransparency = 1; PreviewTitle.Font = Enum.Font.GothamBold
PreviewTitle.TextSize = 10; PreviewTitle.TextColor3 = Color3.fromRGB(0, 240, 255)
PreviewTitle.TextXAlignment = Enum.TextXAlignment.Left; PreviewTitle.Text = "[*] REALTIME 3D PREVIEW"
PreviewTitle.ZIndex = 14; PreviewTitle.Parent = T3dLeftCard

local T3dViewport = Instance.new("ViewportFrame")
T3dViewport.Size = UDim2.new(1, -16, 1, -78); T3dViewport.Position = UDim2.new(0, 8, 0, 30)
T3dViewport.BackgroundColor3 = Color3.fromRGB(10, 10, 14); T3dViewport.BorderSizePixel = 0
T3dViewport.ZIndex = 14; T3dViewport.Parent = T3dLeftCard
makeCorner(T3dViewport, 6); makeStroke(T3dViewport, Color3.fromRGB(60, 60, 75), 1)

local previewCam = Instance.new("Camera")
T3dViewport.CurrentCamera = previewCam
previewCam.Parent = T3dViewport

local PreviewStatsLbl = Instance.new("TextLabel")
PreviewStatsLbl.Size = UDim2.new(1, -16, 0, 36); PreviewStatsLbl.Position = UDim2.new(0, 8, 1, -42)
PreviewStatsLbl.BackgroundColor3 = Color3.fromRGB(22, 22, 28); PreviewStatsLbl.BorderSizePixel = 0
PreviewStatsLbl.Font = Enum.Font.Code; PreviewStatsLbl.TextSize = 9; PreviewStatsLbl.TextColor3 = Color3.fromRGB(180, 180, 195)
PreviewStatsLbl.Text = "Memuat preview..."
PreviewStatsLbl.ZIndex = 14; PreviewStatsLbl.Parent = T3dLeftCard
makeCorner(PreviewStatsLbl, 5)

local currentPreviewModel = nil

local function updateLivePreview(inputText)
    inputText = inputText or "MCHLERN"
    if currentPreviewModel then
        currentPreviewModel:Destroy()
        currentPreviewModel = nil
    end

    local model, count, totalWidth = build3DTextModel(inputText, t3d_scale, t3d_depth, t3d_color, t3d_material)
    if model and count > 0 then
        model.Parent = T3dViewport
        currentPreviewModel = model

        local cf, sz = model:GetBoundingBox()
        local dist = math.max(sz.X * 1.15, sz.Y * 1.6, 6)
        previewCam.CFrame = CFrame.new(cf.Position + Vector3.new(0, 0, dist), cf.Position)

        PreviewStatsLbl.Text = string.format(" Teks: %d huruf | %d parts\n Ukuran: %.1f x %.1f x %.1fs", #inputText, count, sz.X, sz.Y, sz.Z)
    else
        PreviewStatsLbl.Text = " Ketik teks untuk melihat preview"
    end
end

-- KANAN: KONTROL, WARNA KOTAK-KOTAK & GENERATE
local T3dRightScroll = Instance.new("ScrollingFrame")
T3dRightScroll.Size = UDim2.new(0.56, 0, 1, -40); T3dRightScroll.Position = UDim2.new(0.44, 0, 0, 36)
T3dRightScroll.BackgroundColor3 = Color3.fromRGB(16, 16, 22); T3dRightScroll.BorderSizePixel = 0
T3dRightScroll.ScrollBarThickness = 4; T3dRightScroll.CanvasSize = UDim2.new(0, 0, 0, 380)
T3dRightScroll.ZIndex = 13; T3dRightScroll.Parent = PageText3D
makeCorner(T3dRightScroll, 8); makeStroke(T3dRightScroll, Color3.fromRGB(255, 255, 255), 1, 0.85)

local T3dRightPad = Instance.new("UIPadding")
T3dRightPad.PaddingTop = UDim.new(0, 8); T3dRightPad.PaddingBottom = UDim.new(0, 8)
T3dRightPad.PaddingLeft = UDim.new(0, 8); T3dRightPad.PaddingRight = UDim.new(0, 8)
T3dRightPad.Parent = T3dRightScroll

local T3dRightList = Instance.new("UIListLayout")
T3dRightList.Padding = UDim.new(0, 6); T3dRightList.SortOrder = Enum.SortOrder.LayoutOrder; T3dRightList.Parent = T3dRightScroll

local function makeRLabel(text)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 16); l.BackgroundTransparency = 1
    l.Font = Enum.Font.GothamBold; l.TextSize = 9.5; l.TextColor3 = Color3.fromRGB(200, 200, 215)
    l.TextXAlignment = Enum.TextXAlignment.Left; l.Text = text; l.ZIndex = 14; l.Parent = T3dRightScroll
    return l
end

-- 1. Input Box
makeRLabel("TEKS KUSTOM:")
local T3dInputCard = Instance.new("Frame")
T3dInputCard.Size = UDim2.new(1, 0, 0, 32); T3dInputCard.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
T3dInputCard.BorderSizePixel = 0; T3dInputCard.ZIndex = 14; T3dInputCard.Parent = T3dRightScroll
makeCorner(T3dInputCard, 6); makeStroke(T3dInputCard, Color3.fromRGB(255, 255, 255), 1, 0.88)

local T3dTextBox = Instance.new("TextBox")
T3dTextBox.Size = UDim2.new(1, -12, 1, 0); T3dTextBox.Position = UDim2.new(0, 6, 0, 0)
T3dTextBox.BackgroundTransparency = 1; T3dTextBox.Font = Enum.Font.GothamBold
T3dTextBox.TextSize = 12; T3dTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
T3dTextBox.PlaceholderText = "Tulis teks (misal: MCHLERN, VIP, SHOP)..."
T3dTextBox.PlaceholderColor3 = Color3.fromRGB(130, 130, 145); T3dTextBox.Text = "MCHLERN"
T3dTextBox.TextXAlignment = Enum.TextXAlignment.Left; T3dTextBox.ClearTextOnFocus = false
T3dTextBox.ZIndex = 15; T3dTextBox.Parent = T3dInputCard

T3dTextBox:GetPropertyChangedSignal("Text"):Connect(function()
    updateLivePreview(T3dTextBox.Text)
end)

-- 2. Scale & Depth Row
makeRLabel("UKURAN (SCALE) & KETEBALAN (DEPTH):")
local ScaleRow = Instance.new("Frame")
ScaleRow.Size = UDim2.new(1, 0, 0, 24); ScaleRow.BackgroundTransparency = 1; ScaleRow.ZIndex = 14; ScaleRow.Parent = T3dRightScroll
local ScaleLayout = Instance.new("UIListLayout")
ScaleLayout.FillDirection = Enum.FillDirection.Horizontal; ScaleLayout.Padding = UDim.new(0, 4); ScaleLayout.Parent = ScaleRow

local scaleBtns = {}
local scaleOpts = {
    { label = "0.6x", val = 0.6 },
    { label = "1.0x", val = 1.0 },
    { label = "1.8x", val = 1.8 },
    { label = "3.0x", val = 3.0 },
}

for _, opt in ipairs(scaleOpts) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.25, -3, 1, 0); b.BackgroundColor3 = (opt.val == t3d_scale) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(28, 28, 36)
    b.Text = opt.label; b.Font = Enum.Font.GothamBold; b.TextSize = 9
    b.TextColor3 = (opt.val == t3d_scale) and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(200, 200, 215)
    b.ZIndex = 15; b.Parent = ScaleRow; makeCorner(b, 5)
    scaleBtns[opt.val] = b

    b.MouseButton1Click:Connect(function()
        t3d_scale = opt.val
        for v, btn in pairs(scaleBtns) do
            btn.BackgroundColor3 = (v == t3d_scale) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(28, 28, 36)
            btn.TextColor3 = (v == t3d_scale) and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(200, 200, 215)
        end
        updateLivePreview(T3dTextBox.Text)
    end)
end

-- 3. Material Row
makeRLabel("MATERIAL / EFEK:")
local MatRow = Instance.new("Frame")
MatRow.Size = UDim2.new(1, 0, 0, 24); MatRow.BackgroundTransparency = 1; MatRow.ZIndex = 14; MatRow.Parent = T3dRightScroll
local MatLayout = Instance.new("UIListLayout")
MatLayout.FillDirection = Enum.FillDirection.Horizontal; MatLayout.Padding = UDim.new(0, 4); MatLayout.Parent = MatRow

local matBtns = {}
local matOpts = {
    { label = "NEON", mat = Enum.Material.Neon },
    { label = "SMOOTH", mat = Enum.Material.SmoothPlastic },
    { label = "METAL", mat = Enum.Material.Metal },
    { label = "GLASS", mat = Enum.Material.Glass },
    { label = "WOOD", mat = Enum.Material.Wood },
}

for _, opt in ipairs(matOpts) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.2, -3, 1, 0); b.BackgroundColor3 = (opt.mat == t3d_material) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(28, 28, 36)
    b.Text = opt.label; b.Font = Enum.Font.GothamBold; b.TextSize = 8.5
    b.TextColor3 = (opt.mat == t3d_material) and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(200, 200, 215)
    b.ZIndex = 15; b.Parent = MatRow; makeCorner(b, 5)
    matBtns[opt.label] = { btn = b, mat = opt.mat }

    b.MouseButton1Click:Connect(function()
        t3d_material = opt.mat
        for _, item in pairs(matBtns) do
            item.btn.BackgroundColor3 = (item.mat == t3d_material) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(28, 28, 36)
            item.btn.TextColor3 = (item.mat == t3d_material) and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(200, 200, 215)
        end
        updateLivePreview(T3dTextBox.Text)
    end)
end

-- 4. Pilihan Warna Kotak-Kotak (Grid Swatches - Bersih & Rapi!)
makeRLabel("PILIH WARNA (KOTAK-KOTAK):")
local ColorGridFrame = Instance.new("Frame")
ColorGridFrame.Size = UDim2.new(1, 0, 0, 58); ColorGridFrame.BackgroundTransparency = 1; ColorGridFrame.ZIndex = 14; ColorGridFrame.Parent = T3dRightScroll

local ColorGrid = Instance.new("UIGridLayout")
ColorGrid.CellSize = UDim2.new(0, 24, 0, 24); ColorGrid.CellPadding = UDim2.new(0, 5, 0, 5)
ColorGrid.SortOrder = Enum.SortOrder.LayoutOrder; ColorGrid.Parent = ColorGridFrame

local colorTiles = {}
local paletteColors = {
    Color3.fromRGB(0, 240, 255),    -- Cyan Neon
    Color3.fromRGB(0, 168, 255),    -- Sky Blue
    Color3.fromRGB(46, 134, 222),   -- Cobalt Blue
    Color3.fromRGB(168, 85, 247),   -- Purple Neon
    Color3.fromRGB(224, 86, 253),   -- Magenta / Pink
    Color3.fromRGB(255, 45, 85),    -- Crimson Red
    Color3.fromRGB(255, 107, 107),  -- Sunset
    Color3.fromRGB(255, 120, 30),   -- Orange
    Color3.fromRGB(255, 215, 0),    -- Gold / Yellow
    Color3.fromRGB(46, 213, 115),   -- Lime Green
    Color3.fromRGB(0, 255, 127),    -- Spring Green
    Color3.fromRGB(255, 255, 255),  -- Pure White
    Color3.fromRGB(176, 176, 176),  -- Silver Grey
    Color3.fromRGB(40, 40, 50),     -- Dark Onyx
}

for idx, col in ipairs(paletteColors) do
    local tile = Instance.new("TextButton")
    tile.BackgroundColor3 = col; tile.Text = ""
    tile.ZIndex = 15; tile.Parent = ColorGridFrame; makeCorner(tile, 5)
    local st = makeStroke(tile, Color3.fromRGB(255, 255, 255), (col == t3d_color) and 2.5 or 0.5)
    colorTiles[idx] = { btn = tile, stroke = st, col = col }

    tile.MouseButton1Click:Connect(function()
        t3d_color = col
        for _, it in pairs(colorTiles) do
            it.stroke.Thickness = (it.col == t3d_color) and 2.5 or 0.5
            it.stroke.Color = (it.col == t3d_color) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(80, 80, 100)
        end
        updateLivePreview(T3dTextBox.Text)
    end)
end

-- 5. Tombol Generate & Status
local T3dStatusLbl = Instance.new("TextLabel")
T3dStatusLbl.Size = UDim2.new(1, 0, 0, 16); T3dStatusLbl.BackgroundTransparency = 1
T3dStatusLbl.Font = Enum.Font.Code; T3dStatusLbl.TextSize = 9.5; T3dStatusLbl.TextColor3 = Color3.fromRGB(160, 220, 160)
T3dStatusLbl.TextXAlignment = Enum.TextXAlignment.Center; T3dStatusLbl.Text = "Status: Siap membuat teks 3D"
T3dStatusLbl.ZIndex = 15; T3dStatusLbl.Parent = T3dRightScroll

local T3dGenBtn = Instance.new("TextButton")
T3dGenBtn.Size = UDim2.new(1, 0, 0, 36); T3dGenBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
T3dGenBtn.Text = "[+] GENERATE 3D TEXT KE WORKSPACE"
T3dGenBtn.Font = Enum.Font.GothamBold; T3dGenBtn.TextSize = 10.5; T3dGenBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
T3dGenBtn.ZIndex = 16; T3dGenBtn.Active = true; T3dGenBtn.Parent = T3dRightScroll
makeCorner(T3dGenBtn, 7)

T3dGenBtn.MouseButton1Click:Connect(function()
    local textToMake = T3dTextBox.Text
    if not textToMake or textToMake == "" then
        T3dStatusLbl.Text = "[ERR] Masukkan teks terlebih dahulu!"
        T3dStatusLbl.TextColor3 = Color3.fromRGB(255, 100, 100)
        return
    end

    T3dGenBtn.Text = "GENERATING 3D TEXT..."
    task.spawn(function()
        local ok, msg = generate3DText(textToMake, t3d_scale, t3d_depth, t3d_color, t3d_material)
        if ok then
            T3dStatusLbl.Text = "[OK] " .. msg
            T3dStatusLbl.TextColor3 = Color3.fromRGB(100, 255, 140)
            T3dGenBtn.Text = "SUKSES! DIBUAT DI DEPAN KAMERA"
        else
            T3dStatusLbl.Text = "[ERR] " .. tostring(msg)
            T3dStatusLbl.TextColor3 = Color3.fromRGB(255, 100, 100)
            T3dGenBtn.Text = "[!] GAGAL MEMBUAT TEKS"
        end
        task.delay(2.0, function()
            if T3dGenBtn and T3dGenBtn.Parent then
                T3dGenBtn.Text = "[+] GENERATE 3D TEXT KE WORKSPACE"
            end
        end)
    end)
end)

-- Initialize Preview on load
task.spawn(function()
    task.wait(0.5)
    updateLivePreview("MCHLERN")
end)


-- =====================================================

end
initText3DPage()

-- =====================================================

-- PAGE 5: REPLACER TOOLS [MODULAR SCOPE]
-- =====================================================
local function initReplacerPage()
-- PAGE 5: REPLACER TOOLS (OBJECT & MODEL REPLACER)
-- Plugin Pengganti Objek / Model Massal di Workspace
-- Mengganti semua target dengan 1 model/part template
-- =====================================================

local function executeObjectReplaceCore(targetName, replacementName, options)
    options = options or {}
    if not targetName or targetName == "" then
        return false, "Masukkan nama target yang ingin diganti!"
    end
    if not replacementName or replacementName == "" then
        return false, "Masukkan nama objek pengganti!"
    end

    -- 1. Cari objek template pengganti
    local replacementTpl = nil
    for _, place in ipairs({workspace, ReplicatedStorage}) do
        for _, obj in ipairs(place:GetDescendants()) do
            if obj.Name == replacementName then
                replacementTpl = obj
                break
            end
        end
        if replacementTpl then break end
    end

    if not replacementTpl then
        return false, "Objek pengganti '" .. replacementName .. "' tidak ditemukan!"
    end

    -- 2. Cari semua target di Workspace
    local targets = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == targetName and obj ~= replacementTpl and not obj:IsDescendantOf(replacementTpl) then
            table.insert(targets, obj)
        end
    end

    if #targets == 0 then
        return false, "Tidak ada target bernama '" .. targetName .. "' di Workspace!"
    end

    -- 3. Eksekusi Replace
    local replacedCount = 0
    for _, target in ipairs(targets) do
        pcall(function()
            local targetParent = target.Parent or workspace
            local targetCF = nil
            local targetSize = nil

            if target:IsA("Model") then
                targetCF, targetSize = target:GetBoundingBox()
            elseif target:IsA("BasePart") then
                targetCF = target.CFrame
                targetSize = target.Size
            end

            if targetCF then
                local clone = replacementTpl:Clone()

                if options.preserveName then
                    clone.Name = target.Name
                end

                if options.autoAnchor then
                    if clone:IsA("BasePart") then
                        clone.Anchored = true
                        clone.Velocity = Vector3.zero
                    end
                    for _, d in ipairs(clone:GetDescendants()) do
                        if d:IsA("BasePart") then
                            d.Anchored = true
                            d.Velocity = Vector3.zero
                        end
                    end
                end

                if clone:IsA("Model") then
                    if clone.PrimaryPart then
                        clone:SetPrimaryPartCFrame(targetCF)
                    else
                        clone:PivotTo(targetCF)
                    end
                elseif clone:IsA("BasePart") then
                    clone.CFrame = targetCF
                    if options.matchSize and targetSize then
                        clone.Size = targetSize
                    end
                end

                clone.Parent = targetParent
                target:Destroy()
                replacedCount = replacedCount + 1
            end
        end)
    end

    return true, "Sukses mereplace " .. replacedCount .. " objek dengan '" .. replacementTpl.Name .. "'!"
end

local ReplacerHeader = Instance.new("Frame")
ReplacerHeader.Size = UDim2.new(1, 0, 0, 32); ReplacerHeader.BackgroundTransparency = 1
ReplacerHeader.ZIndex = 13; ReplacerHeader.Parent = PageReplacer

local ReplacerTitleLbl = Instance.new("TextLabel")
ReplacerTitleLbl.Size = UDim2.new(1, -90, 1, 0); ReplacerTitleLbl.Position = UDim2.new(0, 8, 0, 0)
ReplacerTitleLbl.BackgroundTransparency = 1; ReplacerTitleLbl.Font = Enum.Font.GothamBold
ReplacerTitleLbl.TextSize = 13; ReplacerTitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
ReplacerTitleLbl.TextXAlignment = Enum.TextXAlignment.Left; ReplacerTitleLbl.Text = "[[REP]] OBJECT & MODEL REPLACER TOOLS"
ReplacerTitleLbl.ZIndex = 14; ReplacerTitleLbl.Parent = ReplacerHeader

makeBackBtn(ReplacerHeader, function() showPage(PageSplash) end)

local ReplacerScroll = Instance.new("ScrollingFrame")
ReplacerScroll.Size = UDim2.new(1, 0, 1, -40); ReplacerScroll.Position = UDim2.new(0, 0, 0, 36)
ReplacerScroll.BackgroundColor3 = Color3.fromRGB(16, 16, 22); ReplacerScroll.BorderSizePixel = 0
ReplacerScroll.ScrollBarThickness = 4; ReplacerScroll.CanvasSize = UDim2.new(0, 0, 0, 350)
ReplacerScroll.ZIndex = 13; ReplacerScroll.Parent = PageReplacer
makeCorner(ReplacerScroll, 8); makeStroke(ReplacerScroll, Color3.fromRGB(255, 255, 255), 1, 0.85)

local ReplacerList = Instance.new("UIListLayout")
ReplacerList.Padding = UDim.new(0, 8); ReplacerList.SortOrder = Enum.SortOrder.LayoutOrder; ReplacerList.Parent = ReplacerScroll

local ReplacerPad = Instance.new("UIPadding")
ReplacerPad.PaddingTop = UDim.new(0, 10); ReplacerPad.PaddingBottom = UDim.new(0, 10)
ReplacerPad.PaddingLeft = UDim.new(0, 10); ReplacerPad.PaddingRight = UDim.new(0, 10)
ReplacerPad.Parent = ReplacerScroll

-- Helper card
local function makeRepCard(title)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 70); card.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    card.BorderSizePixel = 0; card.ZIndex = 14; card.Parent = ReplacerScroll
    makeCorner(card, 7); makeStroke(card, Color3.fromRGB(255, 255, 255), 1, 0.88)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -16, 0, 16); lbl.Position = UDim2.new(0, 8, 0, 6)
    lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 10
    lbl.TextColor3 = Color3.fromRGB(0, 240, 255); lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = title; lbl.ZIndex = 15; lbl.Parent = card
    return card
end

-- 1. Card Target
local Card1 = makeRepCard("1. TARGET YANG AKAN DIGANTI (DI WORKSPACE):")
local TargetInput = Instance.new("TextBox")
TargetInput.Size = UDim2.new(1, -120, 0, 30); TargetInput.Position = UDim2.new(0, 8, 0, 28)
TargetInput.BackgroundColor3 = Color3.fromRGB(14, 14, 18); TargetInput.Font = Enum.Font.Gotham
TargetInput.TextSize = 11; TargetInput.TextColor3 = Color3.fromRGB(255, 255, 255)
TargetInput.PlaceholderText = "Ketik nama target (misal: Tree_Old, Part, Rock)..."
TargetInput.PlaceholderColor3 = Color3.fromRGB(130, 130, 140); TargetInput.TextXAlignment = Enum.TextXAlignment.Left
TargetInput.ClearTextOnFocus = false; TargetInput.ZIndex = 15; TargetInput.Parent = Card1
makeCorner(TargetInput, 5); makeStroke(TargetInput, Color3.fromRGB(255, 255, 255), 1, 0.8)

local ScanTargetBtn = Instance.new("TextButton")
ScanTargetBtn.Size = UDim2.new(0, 100, 0, 30); ScanTargetBtn.Position = UDim2.new(1, -108, 0, 28)
ScanTargetBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40); ScanTargetBtn.Font = Enum.Font.GothamBold
ScanTargetBtn.TextSize = 9.5; ScanTargetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanTargetBtn.Text = "[?] SCAN TARGET"
ScanTargetBtn.ZIndex = 15; ScanTargetBtn.Parent = Card1
makeCorner(ScanTargetBtn, 5)

-- 2. Card Replacement
local Card2 = makeRepCard("2. OBJEK PENGGANTI (TEMPLATE BARU):")
local ReplInput = Instance.new("TextBox")
ReplInput.Size = UDim2.new(1, -120, 0, 30); ReplInput.Position = UDim2.new(0, 8, 0, 28)
ReplInput.BackgroundColor3 = Color3.fromRGB(14, 14, 18); ReplInput.Font = Enum.Font.Gotham
ReplInput.TextSize = 11; ReplInput.TextColor3 = Color3.fromRGB(255, 255, 255)
ReplInput.PlaceholderText = "Ketik nama pengganti (misal: Tree_New, ModernLamp)..."
ReplInput.PlaceholderColor3 = Color3.fromRGB(130, 130, 140); ReplInput.TextXAlignment = Enum.TextXAlignment.Left
ReplInput.ClearTextOnFocus = false; ReplInput.ZIndex = 15; ReplInput.Parent = Card2
makeCorner(ReplInput, 5); makeStroke(ReplInput, Color3.fromRGB(255, 255, 255), 1, 0.8)

local PickSelBtn = Instance.new("TextButton")
PickSelBtn.Size = UDim2.new(0, 100, 0, 30); PickSelBtn.Position = UDim2.new(1, -108, 0, 28)
PickSelBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40); PickSelBtn.Font = Enum.Font.GothamBold
PickSelBtn.TextSize = 9.5; PickSelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PickSelBtn.Text = "[+] PILIH TARGET"
PickSelBtn.ZIndex = 15; PickSelBtn.Parent = Card2
makeCorner(PickSelBtn, 5)

-- 3. Options Card
local Card3 = Instance.new("Frame")
Card3.Size = UDim2.new(1, 0, 0, 72); Card3.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
Card3.BorderSizePixel = 0; Card3.ZIndex = 14; Card3.Parent = ReplacerScroll
makeCorner(Card3, 7); makeStroke(Card3, Color3.fromRGB(255, 255, 255), 1, 0.88)

local OptTitle = Instance.new("TextLabel")
OptTitle.Size = UDim2.new(1, -16, 0, 16); OptTitle.Position = UDim2.new(0, 8, 0, 6)
OptTitle.BackgroundTransparency = 1; OptTitle.Font = Enum.Font.GothamBold; OptTitle.TextSize = 10
OptTitle.TextColor3 = Color3.fromRGB(0, 240, 255); OptTitle.TextXAlignment = Enum.TextXAlignment.Left
OptTitle.Text = "3. PENGATURAN REPLACE:"; OptTitle.ZIndex = 15; OptTitle.Parent = Card3

local rep_options = {
    preserveName = true,
    autoAnchor = true,
    matchSize = false
}

local function makeToggleBtn(parent, posX, posY, text, optKey)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.48, -4, 0, 20); btn.Position = UDim2.new(posX, 0, posY, 0)
    btn.BackgroundColor3 = rep_options[optKey] and Color3.fromRGB(0, 160, 100) or Color3.fromRGB(40, 40, 50)
    btn.Text = (rep_options[optKey] and "[X] " or "[ ] ") .. text
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 8.5; btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.ZIndex = 15; btn.Parent = parent; makeCorner(btn, 4)

    btn.MouseButton1Click:Connect(function()
        rep_options[optKey] = not rep_options[optKey]
        btn.BackgroundColor3 = rep_options[optKey] and Color3.fromRGB(0, 160, 100) or Color3.fromRGB(40, 40, 50)
        btn.Text = (rep_options[optKey] and "[X] " or "[ ] ") .. text
    end)
    return btn
end

makeToggleBtn(Card3, 0.02, 0.36, "Pertahankan Nama Target", "preserveName")
makeToggleBtn(Card3, 0.52, 0.36, "Auto-Anchor Part Baru", "autoAnchor")
makeToggleBtn(Card3, 0.02, 0.68, "Samakan Ukuran Bounding", "matchSize")

-- 4. Status & Execution
local RepStatusLbl = Instance.new("TextLabel")
RepStatusLbl.Size = UDim2.new(1, 0, 0, 18); RepStatusLbl.BackgroundTransparency = 1
RepStatusLbl.Font = Enum.Font.Code; RepStatusLbl.TextSize = 9.5; RepStatusLbl.TextColor3 = Color3.fromRGB(160, 220, 160)
RepStatusLbl.TextXAlignment = Enum.TextXAlignment.Center; RepStatusLbl.Text = "Status: Siap mereplace objek"
RepStatusLbl.ZIndex = 15; RepStatusLbl.Parent = ReplacerScroll

ScanTargetBtn.MouseButton1Click:Connect(function()
    local tName = TargetInput.Text
    if not tName or tName == "" then
        RepStatusLbl.Text = "[!] Masukkan nama target untuk di-scan"
        RepStatusLbl.TextColor3 = Color3.fromRGB(255, 120, 120)
        return
    end
    local count = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == tName then count = count + 1 end
    end
    RepStatusLbl.Text = string.format("[SCAN] Ditemukan %d objek bernama '%s' di Workspace", count, tName)
    RepStatusLbl.TextColor3 = (count > 0) and Color3.fromRGB(100, 255, 140) or Color3.fromRGB(255, 120, 120)
end)

PickSelBtn.MouseButton1Click:Connect(function()
    -- Coba ambil objek pertama yang dipilih atau dicari di workspace
    local found = nil
    for _, d in ipairs(workspace:GetChildren()) do
        if d:IsA("Model") and d ~= LP.Character then found = d; break end
    end
    if found then
        ReplInput.Text = found.Name
        RepStatusLbl.Text = "[OK] Menggunakan '" .. found.Name .. "' sebagai pengganti"
        RepStatusLbl.TextColor3 = Color3.fromRGB(100, 255, 140)
    else
        RepStatusLbl.Text = "[!] Ketik langsung nama template pengganti"
        RepStatusLbl.TextColor3 = Color3.fromRGB(255, 120, 120)
    end
end)

local ExecReplaceBtn = Instance.new("TextButton")
ExecReplaceBtn.Size = UDim2.new(1, 0, 0, 36); ExecReplaceBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ExecReplaceBtn.Text = "[[REP]] EKSEKUSI REPLACE SEMUA TARGET"
ExecReplaceBtn.Font = Enum.Font.GothamBold; ExecReplaceBtn.TextSize = 10.5; ExecReplaceBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
ExecReplaceBtn.ZIndex = 16; ExecReplaceBtn.Active = true; ExecReplaceBtn.Parent = ReplacerScroll
makeCorner(ExecReplaceBtn, 7)

ExecReplaceBtn.MouseButton1Click:Connect(function()
    local tName = TargetInput.Text
    local rName = ReplInput.Text
    if not tName or tName == "" or not rName or rName == "" then
        RepStatusLbl.Text = "[ERR] Isi Target dan Pengganti terlebih dahulu!"
        RepStatusLbl.TextColor3 = Color3.fromRGB(255, 100, 100)
        return
    end

    ExecReplaceBtn.Text = "MEMPROSES REPLACEMENT..."
    task.spawn(function()
        local ok, msg = executeObjectReplaceCore(tName, rName, rep_options)
        if ok then
            RepStatusLbl.Text = "[OK] " .. msg
            RepStatusLbl.TextColor3 = Color3.fromRGB(100, 255, 140)
            ExecReplaceBtn.Text = "SELESAI DIREPLACE!"
        else
            RepStatusLbl.Text = "[ERR] " .. tostring(msg)
            RepStatusLbl.TextColor3 = Color3.fromRGB(255, 100, 100)
            ExecReplaceBtn.Text = "[!] GAGAL MEMPROSES"
        end
        task.delay(2.0, function()
            if ExecReplaceBtn and ExecReplaceBtn.Parent then
                ExecReplaceBtn.Text = "[[REP]] EKSEKUSI REPLACE SEMUA TARGET"
            end
        end)
    end)
end)


end
initReplacerPage()

-- =====================================================


-- =====================================================
-- PAGE 5: AVATAR CHANGER (AvatarStudio Embedded)
-- =====================================================
local function initAvatarPage()
    local old_avatar = PageAvatar:FindFirstChild("Body")
    if old_avatar then old_avatar:Destroy() end

--[[ =============================================================================
  Avatar Studio  -  Quantum Edition
  Visual-only: item, avatar, dan animasi yang dipilih langsung dipasang di
  karakter kamu.

  VERSI FULL (OPTIMAL v7): antrian render, katalog instan, tab ramping, bug UI fix.
    Tab: avatar | karakter | animasi | sepatu | favorit | dipakai
  UPDATE v7:
   - Kamera cermin sejajar tinggi kepala avatar. Tab karakter: bundle bagian tubuh dipasang kilat (tukar mesh + prefetch).
  UPDATE v6:
   - Cowo / Cewe jauh lebih cepat: gender dihitung di latar belakang untuk semua avatar (batch paralel).
   - Pencarian lebih cepat: 3 backend diadu bersamaan, hasil persis paralel, hasil teratas di-prefetch.
   - Kamera cermin menyesuaikan ukuran avatar (kecil / tinggi) dan ukuran panel.
  UPDATE v5:
   - CONFIG avatar: daftar avatar di tab avatar disimpan ke file (avatar_studio_avatars.json).
     Saat masuk lagi langsung muncul 100+ kartu sebelumnya lalu lanjut memuat. (butuh writefile/readfile)
   - Avatar yang diklik secepat mungkin terpasang: model donor 8 avatar teratas yang terlihat disiapkan
     lebih dulu (prefetch + cache), klik cepat berturut-turut diantre. Waktu pasang tampil di kartu & toast.
   - Tab DIPAKAI jauh lebih cepat: nama item diambil sekaligus (batch paralel), baris dipakai ulang.
  UPDATE v4 (SUPER CEPAT): 130 kartu avatar langsung muncul, jalur pasang cepat, cache + prefetch,
   bar loading, tab FAVORIT (tombol hati di kartu avatar & item, tersimpan ke file kalau ada writefile).
  UPDATE v2/v3: filter bacon / bacon cewe ketat, filter Cowo / Cewe sistem skor, kandidat dari teman/server.
  Tekan K untuk buka/tutup UI.
============================================================================= ]]

----------------------------------------------------------------------------
-- [1] SERVICES
----------------------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local AvatarEditorService = game:GetService("AvatarEditorService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("AvatarStudio")
if old then
	old:Destroy()
end

local GEN = (tonumber(playerGui:GetAttribute("avt_gen")) or 0) + 1
playerGui:SetAttribute("avt_gen", GEN)
local function stale()
	return playerGui:GetAttribute("avt_gen") ~= GEN
end

local REMOTE_NAME = "AvatarStudioApply"
local PAGE_SIZE = 120
local MAX_ITEMS = 1000
local TOGGLE_KEY = Enum.KeyCode.K

----------------------------------------------------------------------------
-- [2] TABEL TIPE ITEM
----------------------------------------------------------------------------
local CLASSIC = {
	[11] = "Shirt", [12] = "Pants", [2] = "GraphicTShirt", [18] = "Face",
	[17] = "Head", [27] = "Torso", [28] = "RightArm", [29] = "LeftArm",
	[30] = "LeftLeg", [31] = "RightLeg",
	[48] = "ClimbAnimation", [50] = "FallAnimation", [51] = "IdleAnimation",
	[52] = "JumpAnimation", [53] = "RunAnimation", [54] = "SwimAnimation",
	[55] = "WalkAnimation", [78] = "MoodAnimation",
}

local ACC = {
	[8] = { "Hat", false }, [41] = { "Hair", false }, [42] = { "Face", false },
	[43] = { "Neck", false }, [44] = { "Shoulder", false }, [45] = { "Front", false },
	[46] = { "Back", false }, [47] = { "Waist", false },
	[64] = { "TShirt", true }, [65] = { "Shirt", true }, [66] = { "Pants", true },
	[67] = { "Jacket", true }, [68] = { "Sweater", true }, [69] = { "Shorts", true },
	[70] = { "LeftShoe", true }, [71] = { "RightShoe", true }, [72] = { "DressSkirt", true },
	[76] = { "Eyebrow", false }, [77] = { "Eyelash", false },
}

local ANIM_SLOT = {
	[51] = { "idle", { "Animation1", "Animation2" } },
	[55] = { "walk", { "WalkAnim" } },
	[53] = { "run", { "RunAnim" } },
	[52] = { "jump", { "JumpAnim" } },
	[50] = { "fall", { "FallAnim" } },
	[48] = { "climb", { "ClimbAnim" } },
	[54] = { "swim", { "Swim" } },
}

local NAME2TID = {
	Hat = 8, HairAccessory = 41, FaceAccessory = 42, NeckAccessory = 43, ShoulderAccessory = 44,
	FrontAccessory = 45, BackAccessory = 46, WaistAccessory = 47, TShirtAccessory = 64, ShirtAccessory = 65,
	PantsAccessory = 66, JacketAccessory = 67, SweaterAccessory = 68, ShortsAccessory = 69,
	LeftShoeAccessory = 70, RightShoeAccessory = 71, DressSkirtAccessory = 72, EyebrowAccessory = 76,
	EyelashAccessory = 77, Shirt = 11, Pants = 12, TShirt = 2, Face = 18, Head = 17, Torso = 27,
	RightArm = 28, LeftArm = 29, LeftLeg = 30, RightLeg = 31, ClimbAnimation = 48, FallAnimation = 50,
	IdleAnimation = 51, JumpAnimation = 52, RunAnimation = 53, SwimAnimation = 54, WalkAnimation = 55,
	MoodAnimation = 78,
}

local SERIAL_PROPS = {
	"Shirt", "Pants", "GraphicTShirt", "Face", "Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg",
	"ClimbAnimation", "FallAnimation", "IdleAnimation", "JumpAnimation", "RunAnimation", "SwimAnimation",
	"WalkAnimation", "MoodAnimation",
	"HeadColor", "TorsoColor", "LeftArmColor", "RightArmColor", "LeftLegColor", "RightLegColor",
	"HeightScale", "WidthScale", "DepthScale", "HeadScale", "ProportionScale", "BodyTypeScale",
}

local SCALE_VALUES = {
	Height = "BodyHeightScale", Width = "BodyWidthScale", Depth = "BodyDepthScale",
	Head = "HeadScale", Proportion = "BodyProportionScale", BodyType = "BodyTypeScale",
}
local SCALE_DESC = {
	Height = "HeightScale", Width = "WidthScale", Depth = "DepthScale",
	Head = "HeadScale", Proportion = "ProportionScale", BodyType = "BodyTypeScale",
}
local SKIN_NAME = "AS_Skin"
local LIMBS = { "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm",
	"RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot", "Torso",
	"Left Arm", "Right Arm", "Left Leg", "Right Leg" }
local function isBodyPart(name)
	if name == "Head" then
		return true
	end
	for _, n in ipairs(LIMBS) do
		if n == name then
			return true
		end
	end
	return false
end
local BODY_COLOR_PROPS = {
	"HeadColor3", "TorsoColor3", "LeftArmColor3", "RightArmColor3", "LeftLegColor3", "RightLegColor3",
}

----------------------------------------------------------------------------
-- [3] TEMA + HELPER UI
----------------------------------------------------------------------------
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local T = {
	Bg = rgb(13, 14, 21), Surface = rgb(21, 23, 33), Surface2 = rgb(31, 34, 49),
	Hover = rgb(42, 46, 66), Stroke = rgb(46, 50, 70), Text = rgb(240, 242, 250),
	Dim = rgb(146, 152, 178), Accent = rgb(108, 118, 255), Ok = rgb(72, 199, 142),
	Danger = rgb(238, 84, 100), Warn = rgb(245, 184, 68),
}

local function mk(class, props, kids)
	local o = Instance.new(class)
	local parent
	for k, v in pairs(props or {}) do
		if k == "Parent" then
			parent = v
		else
			o[k] = v
		end
	end
	for _, c in ipairs(kids or {}) do
		c.Parent = o
	end
	if parent then
		o.Parent = parent
	end
	return o
end

local function tween(o, props, t, style)
	local tw = TweenService:Create(o, TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quint), props)
	tw:Play()
	return tw
end

local function corner(o, r)
	return mk("UICorner", { CornerRadius = UDim.new(0, r or 8), Parent = o })
end

local function stroke(o, color, th, tr)
	return mk("UIStroke", {
		Color = color or T.Stroke, Thickness = th or 1, Transparency = tr or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = o,
	})
end

local function pad(o, l, t, r, b)
	return mk("UIPadding", {
		PaddingLeft = UDim.new(0, l or 0), PaddingTop = UDim.new(0, t or l or 0),
		PaddingRight = UDim.new(0, r or l or 0), PaddingBottom = UDim.new(0, b or t or l or 0),
		Parent = o,
	})
end

local function vlist(o, gap)
	return mk("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, gap or 0), Parent = o,
	})
end

local function label(parent, text, size, color, font, xalign)
	return mk("TextLabel", {
		BackgroundTransparency = 1, Text = text or "", TextSize = size or 14, TextColor3 = color or T.Text,
		Font = font or Enum.Font.GothamMedium, TextXAlignment = xalign or Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 0, (size or 14) + 6), Parent = parent,
	})
end

local function button(parent, o)
	local bg = o.bg or T.Surface2
	local b = mk("TextButton", {
		AutoButtonColor = false, Text = o.text or "", TextSize = o.textSize or 14, Font = Enum.Font.GothamBold,
		TextColor3 = o.color or T.Text, BackgroundColor3 = bg, BorderSizePixel = 0,
		Size = o.size or UDim2.new(1, 0, 0, 36), Position = o.position or UDim2.new(),
		AnchorPoint = o.anchor or Vector2.zero, LayoutOrder = o.order or 0, Parent = parent,
	})
	corner(b, o.radius or 10)
	b:SetAttribute("Base", bg)
	b.MouseEnter:Connect(function()
		local base = b:GetAttribute("Base") or bg
		tween(b, { BackgroundColor3 = base:Lerp(Color3.new(1, 1, 1), 0.12) }, 0.12)
	end)
	b.MouseLeave:Connect(function()
		tween(b, { BackgroundColor3 = b:GetAttribute("Base") or bg }, 0.15)
	end)
	if o.onClick then
		b.Activated:Connect(o.onClick)
	end
	return b
end

local function makeScroll(parent, size, position)
	return mk("ScrollingFrame", {
		Size = size or UDim2.new(1, 0, 1, 0), Position = position or UDim2.new(), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = T.Dim,
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.Y, Parent = parent,
	})
end

local function thumbURL(kind, id, size)
	size = size or 150
	return "rbxthumb://type=" .. kind .. "&id=" .. string.format("%.0f", id) .. "&w=" .. size .. "&h=" .. size
end

local function commas(n)
	local s = tostring(math.floor(n))
	local r = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (r:gsub("^,", ""))
end

local function priceText(p)
	if p == false then
		return "…"
	elseif p == nil then
		return "Tidak dijual"
	elseif p == 0 then
		return "Gratis"
	end
	return "R$ " .. commas(p)
end

local function safeEnum(enumType, name)
	local ok, v = pcall(function()
		return enumType[name]
	end)
	if ok then
		return v
	end
	return nil
end

local function getProp(desc, key)
	local ok, v = pcall(function()
		return desc[key]
	end)
	if ok then
		return v
	end
	return nil
end

local function setProp(desc, key, value)
	pcall(function()
		desc[key] = value
	end)
end

----------------------------------------------------------------------------
-- [3b] KOMPATIBILITAS API  (Roblox v702, Des 2025: banyak fungsi diganti *Async)
----------------------------------------------------------------------------
local function callAny(obj, names, ...)
	local lastErr = "metode tidak ditemukan"
	local args = table.pack(...)
	for _, name in ipairs(names) do
		local okF, f = pcall(function()
			return obj[name]
		end)
		if okF and type(f) == "function" then
			local ok, res = pcall(function()
				return f(obj, table.unpack(args, 1, args.n))
			end)
			if ok then
				return true, res, name
			end
			lastErr = name .. ": " .. tostring(res)
		else
			lastErr = name .. " tidak ada"
		end
	end
	return false, lastErr
end

local function hasMember(obj, name)
	local ok, v = pcall(function()
		return obj[name]
	end)
	return ok and type(v) == "function"
end

local function productInfo(id, infoType)
	local ok, res = callAny(MarketplaceService, { "GetProductInfoAsync", "GetProductInfo" }, id, infoType)
	if ok then
		return res
	end
	return nil
end

local function descFromUser(uid)
	local ok, res = callAny(Players, { "GetHumanoidDescriptionFromUserIdAsync", "GetHumanoidDescriptionFromUserId" }, uid)
	if ok and res then
		return res
	end
	return nil, res
end

local function descFromOutfit(id)
	local ok, res = callAny(Players, { "GetHumanoidDescriptionFromOutfitIdAsync", "GetHumanoidDescriptionFromOutfitId" }, id)
	if ok and res then
		return res
	end
	return nil
end

local function batchDetails(ids, itemType)
	return callAny(AvatarEditorService, { "GetBatchItemDetailsAsync", "GetBatchItemDetails" }, ids, itemType)
end

local function appliedDesc(hum)
	local ok, d = callAny(hum, { "GetAppliedDescriptionAsync", "GetAppliedDescription" })
	if ok and d then
		return d
	end
	local d2 = descFromUser(player.UserId)
	if d2 then
		return d2
	end
	return Instance.new("HumanoidDescription")
end

local function urlenc(str)
	return (tostring(str):gsub("[^%w%-_%.~]", function(c)
		return string.format("%%%02X", string.byte(c))
	end))
end

-- ambil URL lewat: game:HttpGet (executor) -> request/http_request -> HttpService
local function httpGet(url)
	local why = {}
	local okG, body = pcall(function()
		return game:HttpGet(url)
	end)
	if okG and type(body) == "string" and #body > 0 then
		return body
	end
	table.insert(why, "HttpGet: " .. tostring(okG and "kosong" or body))
	local req = (syn and syn.request) or request or http_request or (http and http.request) or (fluxus and fluxus.request)
	if req then
		local okR, res = pcall(function()
			return req({ Url = url, Method = "GET" })
		end)
		if okR and type(res) == "table" and res.Body and (res.Success or res.StatusCode == 200) then
			return res.Body
		end
		table.insert(why, "request: " .. tostring(okR and ("status " .. tostring(res and res.StatusCode)) or res))
	else
		table.insert(why, "request: tidak ada")
	end
	local okH, b2 = pcall(function()
		return HttpService:GetAsync(url)
	end)
	if okH and type(b2) == "string" then
		return b2
	end
	table.insert(why, "HttpService: " .. tostring(b2))
	return nil, table.concat(why, " | ")
end

----------------------------------------------------------------------------
-- [4] TOAST
----------------------------------------------------------------------------
local LOG = {}
local logHook = nil

local function logf(fmt, ...)
	local line
	if select("#", ...) > 0 then
		local ok, r = pcall(string.format, fmt, ...)
		line = ok and r or tostring(fmt)
	else
		line = tostring(fmt)
	end
	line = os.date("%H:%M:%S") .. "  " .. line
	table.insert(LOG, line)
	while #LOG > 500 do
		table.remove(LOG, 1)
	end
	print("[AvatarStudio] " .. line)
	if logHook then
		pcall(logHook)
	end
end

local toastHolder

local function toast(text, kind)
	logf("%s", tostring(text))
	if not toastHolder then
		return
	end
	local col = ({ danger = T.Danger, warn = T.Warn, ok = T.Ok })[kind or ""] or T.Accent
	local f = mk("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.Surface2,
		BackgroundTransparency = 1, TextColor3 = T.Text, TextTransparency = 1, Font = Enum.Font.GothamMedium,
		TextSize = 14, TextWrapped = true, Text = tostring(text), Parent = toastHolder,
	})
	corner(f, 10)
	pad(f, 14, 9, 14, 9)
	local st = stroke(f, col, 2, 1)
	tween(f, { BackgroundTransparency = 0, TextTransparency = 0 }, 0.2)
	tween(st, { Transparency = 0 }, 0.2)
	task.delay((kind == "danger" or kind == "warn") and 7 or 3, function()
		if f.Parent then
			tween(f, { BackgroundTransparency = 1, TextTransparency = 1 }, 0.3)
			tween(st, { Transparency = 1 }, 0.3)
			task.wait(0.35)
			f:Destroy()
		end
	end)
end

----------------------------------------------------------------------------
-- [5] ENGINE AVATAR  (inti: membuat item benar-benar muncul di karakter)
----------------------------------------------------------------------------
local E = {
	look = nil,
	original = nil,
	failed = {},
	types = {}, names = {},
	history = {}, redo = {},
	busy = false, remote = nil, lastMethod = "", injectFirst = false, cap = {}, useSkin = true, skinMode = "puppet", directIds = {},
	scales = {}, skin = nil, origColors = nil,
	listeners = {},
	bundleCache = {}, loadingBundles = 0, pendingClicks = 0,
	preCache = {}, preOrder = {}, preJobs = {},
}

function E.onChanged(fn)
	table.insert(E.listeners, fn)
end

local function fire()
	for _, fn in ipairs(E.listeners) do
		task.spawn(fn)
	end
end

function E.humanoid()
	local char = player.Character or player.CharacterAdded:Wait()
	return char:WaitForChild("Humanoid"), char
end

function E.assetType(id)
	if E.types[id] then
		return E.types[id]
	end
	local info = productInfo(id, Enum.InfoType.Asset)
	if info then
		E.types[id] = info.AssetTypeId
		E.names[id] = E.names[id] or info.Name
		return info.AssetTypeId
	end
	return nil
end

function E.name(id)
	if not E.names[id] then
		E.assetType(id)
	end
	return E.names[id] or ("Item #" .. id)
end

local function needReady()
	if E.look and E.original then
		return true
	end
	toast("Karakter masih disiapkan, coba lagi sebentar...", "warn")
	return false
end

local function collect(desc)
	local set, list = {}, {}
	if not desc then
		return set, list
	end
	local ok, accs = pcall(function()
		return desc:GetAccessories(true)
	end)
	if ok then
		for _, a in ipairs(accs) do
			set[a.AssetId] = true
			table.insert(list, { Id = a.AssetId, Label = a.AccessoryType.Name .. (a.IsLayered and " (layered)" or "") })
		end
	end
	for _, prop in pairs(CLASSIC) do
		local v = getProp(desc, prop)
		if type(v) == "number" and v > 0 and not set[v] then
			set[v] = true
			table.insert(list, { Id = v, Label = prop })
		end
	end
	table.sort(list, function(a, b)
		return a.Id < b.Id
	end)
	return set, list
end

function E.isWorn(id)
	local set = collect(E.look)
	return set[id] == true
end

function E.wornList()
	local _, list = collect(E.look)
	return list
end

local function removeFromDesc(desc, id)
	local out = {}
	for _, a in ipairs(desc:GetAccessories(true)) do
		if a.AssetId ~= id then
			table.insert(out, a)
		end
	end
	desc:SetAccessories(out, true)
	for _, prop in pairs(CLASSIC) do
		if getProp(desc, prop) == id then
			setProp(desc, prop, 0)
		end
	end
end

local function addToDesc(desc, id, tid)
	local acc = ACC[tid]
	if acc then
		local typeName, layered = acc[1], acc[2]
		local enumVal = safeEnum(Enum.AccessoryType, typeName)
		if not enumVal then
			return false
		end
		local out, order = {}, 1
		for _, a in ipairs(desc:GetAccessories(true)) do
			local drop = a.AssetId == id
			if (layered or typeName == "Eyebrow" or typeName == "Eyelash") and a.AccessoryType == enumVal then
				drop = true
			end
			if not drop then
				table.insert(out, a)
				if a.Order and a.Order >= order then
					order = a.Order + 1
				end
			end
		end
		table.insert(out, { AssetId = id, AccessoryType = enumVal, IsLayered = layered, Order = order })
		desc:SetAccessories(out, true)
		return true
	end
	local prop = CLASSIC[tid]
	if prop then
		setProp(desc, prop, id)
		return true
	end
	return false
end

local function mergeDescription(base, other)
	for _, prop in pairs(CLASSIC) do
		local v = getProp(other, prop)
		if type(v) == "number" and v > 0 then
			setProp(base, prop, v)
		end
	end
	local okO, otherAccs = pcall(function()
		return other:GetAccessories(true)
	end)
	if not okO then
		return
	end
	local baseAccs = base:GetAccessories(true)
	for _, oa in ipairs(otherAccs) do
		local out = {}
		for _, ba in ipairs(baseAccs) do
			local sameSlot = oa.IsLayered and ba.IsLayered and ba.AccessoryType == oa.AccessoryType
			if ba.AssetId ~= oa.AssetId and not sameSlot then
				table.insert(out, ba)
			end
		end
		table.insert(out, oa)
		baseAccs = out
	end
	base:SetAccessories(baseAccs, true)
end

local function serialize(desc)
	local t = { props = {}, accs = {} }
	for _, k in ipairs(SERIAL_PROPS) do
		local v = getProp(desc, k)
		if v ~= nil then
			t.props[k] = v
		end
	end
	local ok, list = pcall(function()
		return desc:GetAccessories(true)
	end)
	if ok then
		for _, a in ipairs(list) do
			table.insert(t.accs, {
				AssetId = a.AssetId, AccessoryType = a.AccessoryType.Name,
				IsLayered = a.IsLayered, Order = a.Order or 1,
			})
		end
	end
	return t
end

function E.withoutFailed(desc)
	local d = desc:Clone()
	for id in pairs(E.failed) do
		removeFromDesc(d, id)
	end
	return d
end

------------------------------------------------------------------------
-- INJECTOR (jalur cadangan): muat aset lalu pasang langsung ke karakter
------------------------------------------------------------------------
local function buildDonor(desc)
	local hum = E.humanoid()
	local rig = (hum.RigType == Enum.HumanoidRigType.R6) and Enum.HumanoidRigType.R6 or Enum.HumanoidRigType.R15
	local ok, m = callAny(Players, { "CreateHumanoidModelFromDescriptionAsync", "CreateHumanoidModelFromDescription" }, desc, rig)
	if ok and m then
		return m
	end
	logf("donor rig gagal: %s", tostring(m))
	return nil
end

-- kalau model donor untuk desc ini sudah disiapkan lebih awal (prefetch), pakai langsung
local function donorModel(desc)
	for i, uid in ipairs(E.preOrder) do
		local rec = E.preCache[uid]
		if rec and rec.desc == desc then
			table.remove(E.preOrder, i)
			E.preCache[uid] = nil
			return rec.model
		end
	end
	return buildDonor(desc)
end

local function loadAsset(id, tid)
	if E.cap.getObjects ~= false then
		local ok, objs = pcall(function()
			return game:GetObjects("rbxassetid://" .. tostring(id))
		end)
		if ok and type(objs) == "table" and #objs > 0 then
			return objs, "GetObjects"
		end
		logf("GetObjects gagal untuk %s: %s", tostring(id), ok and "hasil kosong" or tostring(objs))
	end
	if E.cap.insert ~= false then
		local ok2, model = pcall(function()
			return InsertService:LoadAsset(id)
		end)
		if ok2 and model then
			return { model }, "LoadAsset"
		end
		logf("LoadAsset gagal untuk %s: %s", tostring(id), ok2 and "kosong" or tostring(model))
	end
	if E.cap.donor ~= false and tid then
		local d = Instance.new("HumanoidDescription")
		if addToDesc(d, id, tid) then
			local m = donorModel(d)
			if m then
				return { m }, "donor"
			end
		end
	end
	return nil
end

local function findIn(objs, class)
	for _, o in ipairs(objs) do
		if o:IsA(class) then
			return o
		end
		local d = o:FindFirstChildWhichIsA(class, true)
		if d then
			return d
		end
	end
	return nil
end

local function restartAnimate(char, hum)
	local animate = char:FindFirstChild("Animate")
	if not animate then
		return
	end
	pcall(function()
		animate.Disabled = true
		local animator = hum:FindFirstChildOfClass("Animator")
		if animator then
			for _, tr in ipairs(animator:GetPlayingAnimationTracks()) do
				tr:Stop(0)
			end
		end
		task.wait()
		animate.Disabled = false
	end)
end

local function findBodyAttachment(char, name)
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("Attachment") and d.Name == name and d.Parent and d.Parent:IsA("BasePart") then
			return d
		end
	end
	return nil
end

local function attachAccessory(acc, char)
	local handle = acc:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") then
		acc.Parent = char
		return false, "Accessory tidak punya Handle"
	end
	for _, w in ipairs(handle:GetChildren()) do
		if w.Name == "AccessoryWeld" then
			w:Destroy()
		end
	end
	handle.Anchored = false
	handle.CanCollide = false
	handle.Massless = true
	local part1, c0, c1
	for _, att in ipairs(handle:GetChildren()) do
		if att:IsA("Attachment") then
			local target = findBodyAttachment(char, att.Name)
			if target then
				part1, c0, c1 = target.Parent, att.CFrame, target.CFrame
				break
			end
		end
	end
	local how = "attachment"
	if not part1 then
		how = "cadangan"
		local layered = acc:FindFirstChildWhichIsA("WrapLayer", true) ~= nil
		if layered then
			part1 = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
			c0, c1 = CFrame.new(), CFrame.new()
		else
			part1 = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
			if part1 then
				c0, c1 = CFrame.new(), CFrame.new(0, part1.Size.Y / 2, 0)
			end
		end
		if not part1 then
			acc.Parent = char
			return false, "tidak ada bagian tubuh untuk dilas"
		end
	end
	local w = Instance.new("Weld")
	w.Name = "AccessoryWeld"
	w.Part0 = handle
	w.Part1 = part1
	w.C0 = c0
	w.C1 = c1
	handle.CFrame = part1.CFrame * c1 * c0:Inverse()
	acc.Parent = char
	w.Parent = handle
	return true, how
end

local function harvestAccessory(donorAcc, char)
	local c = donorAcc:Clone()
	c:SetAttribute("ASU", true)
	local dh, ch = donorAcc:FindFirstChild("Handle"), c:FindFirstChild("Handle")
	local wired = false
	if dh and ch then
		local dw = dh:FindFirstChild("AccessoryWeld") or dh:FindFirstChildWhichIsA("Weld")
		local cw = ch:FindFirstChild("AccessoryWeld") or ch:FindFirstChildWhichIsA("Weld")
		if dw and cw and dw.Part1 then
			local tgt = char:FindFirstChild(dw.Part1.Name) or char:FindFirstChild(dw.Part1.Name, true)
			if tgt and tgt:IsA("BasePart") then
				cw.Part0 = ch
				cw.Part1 = tgt
				wired = true
			end
		end
	end
	if wired then
		c.Parent = char
	else
		local ok, how = attachAccessory(c, char)
		if not ok then
			logf("las aksesori gagal: %s", tostring(how))
		end
	end
	return c
end

local function copyBodyParts(model, char)
	for _, dp in ipairs(model:GetChildren()) do
		if dp:IsA("MeshPart") and dp.Name ~= "HumanoidRootPart" then
			local cp = char:FindFirstChild(dp.Name)
			if cp and cp:IsA("MeshPart") then
				pcall(function()
					if dp.MeshId ~= "" and cp.MeshId ~= dp.MeshId then
						cp.MeshId = dp.MeshId
					end
					cp.TextureID = dp.TextureID
				end)
				pcall(function()
					for _, x in ipairs(cp:GetChildren()) do
						if x:IsA("SurfaceAppearance") then
							x:Destroy()
						end
					end
					local sa = dp:FindFirstChildOfClass("SurfaceAppearance")
					if sa then
						sa:Clone().Parent = cp
					end
				end)
			end
		end
	end
end

local function pickAnim(anims, name, i)
	local lname = string.lower(name)
	for _, a in ipairs(anims) do
		if string.lower(a.Name) == lname then
			return a
		end
	end
	return anims[i] or anims[1]
end

local function injectCore(id, tid, objs, kind)
	local hum, char = E.humanoid()
	local tag = "AS_" .. tostring(id)

	if ACC[tid] then
		local acc = findIn(objs, "Accessory")
		if not acc then
			E.lastInjectErr = "aset bukan Accessory"
			return false
		end
		local c
		if kind == "donor" then
			c = harvestAccessory(acc, char)
			c:SetAttribute("ASU", nil)
		else
			c = acc:Clone()
			local okA, how = attachAccessory(c, char)
			if not okA then
				E.lastInjectErr = tostring(how)
			end
		end
		c.Name = tag
		c:SetAttribute("AS", id)
		return c.Parent == char
	elseif tid == 11 or tid == 12 or tid == 2 then
		local class = (tid == 11 and "Shirt") or (tid == 12 and "Pants") or "ShirtGraphic"
		local inst = findIn(objs, class)
		if not inst then
			return false
		end
		for _, ch in ipairs(char:GetChildren()) do
			if ch:IsA(class) then
				ch:Destroy()
			end
		end
		local c = inst:Clone()
		c.Name = tag
		c:SetAttribute("AS", id)
		c.Parent = char
		return true
	elseif tid == 18 then
		local decal = findIn(objs, "Decal")
		local head = char:FindFirstChild("Head")
		if not decal or not head then
			return false
		end
		local face = head:FindFirstChild("face") or head:FindFirstChildOfClass("Decal")
		if not face then
			face = Instance.new("Decal")
			face.Name = "face"
			face.Parent = head
		end
		face.Texture = decal.Texture
		char:SetAttribute("ASX_" .. tostring(id), true)
		return true
	elseif ANIM_SLOT[tid] then
		local animate = char:FindFirstChild("Animate")
		if not animate then
			return false
		end
		local slot = ANIM_SLOT[tid]
		local folder = animate:FindFirstChild(slot[1])
		if not folder then
			E.lastInjectErr = "karakter tidak punya folder animasi '" .. slot[1] .. "'"
			return false
		end
		if kind == "donor" then
			local dan = objs[1]:FindFirstChild("Animate")
			local df = dan and dan:FindFirstChild(slot[1])
			if not df then
				E.lastInjectErr = "donor rig tanpa Animate"
				return false
			end
			E.animState = E.animState or {}
			local rec2 = {}
			for _, name in ipairs(slot[2]) do
				local src, target = df:FindFirstChild(name), folder:FindFirstChild(name)
				if src and target and src:IsA("Animation") then
					target.AnimationId = src.AnimationId
					table.insert(rec2, { target, src.AnimationId })
				end
			end
			if #rec2 == 0 then
				E.lastInjectErr = "slot animasi kosong"
				return false
			end
			E.animState[id] = rec2
			restartAnimate(char, hum)
			char:SetAttribute("ASX_" .. tostring(id), true)
			return true
		end
		local anims = {}
		for _, o in ipairs(objs) do
			if o:IsA("Animation") then
				table.insert(anims, o)
			end
			for _, d in ipairs(o:GetDescendants()) do
				if d:IsA("Animation") then
					table.insert(anims, d)
				end
			end
		end
		if #anims == 0 then
			return false
		end
		E.animState = E.animState or {}
		local rec = {}
		for i, name in ipairs(slot[2]) do
			local target = folder:FindFirstChild(name)
			local src = pickAnim(anims, name, i)
			if target and src then
				target.AnimationId = src.AnimationId
				table.insert(rec, { target, src.AnimationId })
			end
		end
		E.animState[id] = rec
		restartAnimate(char, hum)
		char:SetAttribute("ASX_" .. tostring(id), true)
		return true
	end
	E.lastInjectErr = "tipe item ini tidak bisa dipasang lewat injector (bodypart hanya native/server)"
	return false
end

function E.inject(id, tid)
	E.lastInjectErr = nil
	local objs, kind = loadAsset(id, tid)
	if not objs then
		E.lastInjectErr = "semua pemuat gagal (GetObjects, LoadAsset, donor rig)"
		logf("inject %s gagal: %s", tostring(id), E.lastInjectErr)
		return false
	end
	local ok, res = pcall(injectCore, id, tid, objs, kind)
	if kind == "donor" then
		pcall(function()
			objs[1]:Destroy()
		end)
	end
	if not ok then
		E.lastInjectErr = tostring(res)
		res = false
	end
	if not res and not E.lastInjectErr then
		E.lastInjectErr = "aset termuat tapi bentuknya tidak sesuai / tidak menempel di karakter"
	end
	logf("inject %s (tipe %s) via %s -> %s%s", tostring(id), tostring(tid), kind, res and "BERHASIL" or "GAGAL",
		(not res and E.lastInjectErr) and (" : " .. E.lastInjectErr) or "")
	return res and true or false
end

function E.cleanInjected(char)
	for _, ch in ipairs(char:GetChildren()) do
		if ch:GetAttribute("AS") then
			ch:Destroy()
		end
	end
	for name in pairs(char:GetAttributes()) do
		if string.sub(name, 1, 4) == "ASX_" then
			char:SetAttribute(name, nil)
		end
	end
end

function E.hookChar(char)
	local pending = false
	char.ChildRemoved:Connect(function(ch)
		if ch:GetAttribute("AS") and not pending then
			pending = true
			task.delay(0.15, function()
				pending = false
				if E.injectFirst and not E.remote and not E.busy then
					pcall(E.guard)
				end
			end)
		end
	end)
end

function E.guard()
	if stale() then
		return
	end
	local char = player.Character
	if E.busy or not char or not char:FindFirstChildOfClass("Humanoid") or not E.look then
		return
	end
	local nowSet = collect(E.look)
	local present = {}
	for _, ch in ipairs(char:GetChildren()) do
		local a = ch:GetAttribute("AS")
		if a then
			present[a] = true
		end
	end
	for id in pairs(E.failed) do
		local intact = present[id] or (char:GetAttribute("ASX_" .. tostring(id)) ~= nil)
		local rec = E.animState and E.animState[id]
		if rec and char:GetAttribute("ASX_" .. tostring(id)) then
			for _, r in ipairs(rec) do
				if not r[1]:IsDescendantOf(char) or r[1].AnimationId ~= r[2] then
					intact = false
					char:SetAttribute("ASX_" .. tostring(id), nil)
					break
				end
			end
		end
		if nowSet[id] and not intact then
			local tid = E.assetType(id)
			if tid then
				E.inject(id, tid)
			end
		end
	end
	if not E.remote and E.skinActive and not char:FindFirstChild(SKIN_NAME) and os.clock() - (E.lastRenderAt or 0) > 6 then
		E.lastRenderAt = os.clock()
		task.spawn(E.rerender)
	end
	if not E.remote and (E.rendered or 0) > 0 and os.clock() - (E.lastRenderAt or 0) > 6 then
		local have = 0
		for _, ch in ipairs(char:GetChildren()) do
			if ch:IsA("Accessory") and ch:GetAttribute("ASU") then
				have = have + 1
			end
		end
		if have < E.rendered then
			E.lastRenderAt = os.clock()
			task.spawn(E.rerender)
		end
	end
end

local function countAccessories(char)
	local n = 0
	for _, ch in ipairs(char:GetChildren()) do
		if ch:IsA("Accessory") and not ch:GetAttribute("AS") then
			n = n + 1
		end
	end
	return n
end

local function waitAccessories(char, expected, timeout)
	local t0 = os.clock()
	local have = countAccessories(char)
	while have < expected and os.clock() - t0 < timeout do
		task.wait(0.2)
		have = countAccessories(char)
	end
	return have
end

------------------------------------------------------------------------
-- COMMIT: terapkan "look" baru ke karakter + verifikasi
------------------------------------------------------------------------
local function serverApply(desc)
	local okI, r = pcall(function()
		return E.remote:InvokeServer(serialize(desc))
	end)
	if okI and type(r) == "table" and r.ok then
		if r.missing then
			for _, mid in ipairs(r.missing) do
				E.failed[mid] = true
			end
		end
		return true
	end
	return false, okI and (type(r) == "table" and r.err or tostring(r)) or tostring(r)
end

local function matchAttachment(cp, dp)
	for _, da in ipairs(dp:GetChildren()) do
		if da:IsA("Attachment") and string.sub(da.Name, -13) == "RigAttachment" then
			local ca = cp:FindFirstChild(da.Name)
			if ca and ca:IsA("Attachment") then
				return ca, da
			end
		end
	end
	for _, da in ipairs(dp:GetChildren()) do
		if da:IsA("Attachment") then
			local ca = cp:FindFirstChild(da.Name)
			if ca and ca:IsA("Attachment") then
				return ca, da
			end
		end
	end
	return nil
end

function E.snapAnim(char)
	E.animOrig = {}
	local an = char:FindFirstChild("Animate")
	if not an then
		return
	end
	for _, slot in pairs(ANIM_SLOT) do
		local f = an:FindFirstChild(slot[1])
		if f then
			for _, name in ipairs(slot[2]) do
				local a = f:FindFirstChild(name)
				if a and a:IsA("Animation") then
					E.animOrig[slot[1] .. "/" .. name] = a.AnimationId
				end
			end
		end
	end
end

local function copyAnimations(model, char, hum, desc)
	local dan, can = model:FindFirstChild("Animate"), char:FindFirstChild("Animate")
	if not (dan and can) then
		return
	end
	E.animChanged = E.animChanged or {}
	local changed = false
	for tid, slot in pairs(ANIM_SLOT) do
		local prop = CLASSIC[tid]
		local v = prop and getProp(desc, prop)
		local cf = can:FindFirstChild(slot[1])
		if cf then
			if type(v) == "number" and v > 0 then
				local df = dan:FindFirstChild(slot[1])
				if df then
					local srcList = {}
					for _, a in ipairs(df:GetChildren()) do
						if a:IsA("Animation") then
							table.insert(srcList, a)
						end
					end
					for i, name in ipairs(slot[2]) do
						local b = cf:FindFirstChild(name)
						local a = df:FindFirstChild(name)
						if not (a and a:IsA("Animation")) then
							a = srcList[i] or srcList[1]
						end
						if a and b and b:IsA("Animation") then
							b.AnimationId = a.AnimationId
							changed = true
						end
					end
					E.animChanged[slot[1]] = true
				end
			elseif E.animChanged[slot[1]] then
				for _, name in ipairs(slot[2]) do
					local b = cf:FindFirstChild(name)
					local orig = E.animOrig and E.animOrig[slot[1] .. "/" .. name]
					if b and orig and b:IsA("Animation") then
						b.AnimationId = orig
						changed = true
					end
				end
				E.animChanged[slot[1]] = nil
			end
		end
	end
	if changed then
		restartAnimate(char, hum)
	end
end

function E.removeSkin()
	if E.skinConn then
		E.skinConn:Disconnect()
		E.skinConn = nil
	end
	local char = player.Character
	if char then
		local sk = char:FindFirstChild(SKIN_NAME)
		if sk then
			sk:Destroy()
		end
	end
	for part, tr in pairs(E.hidden or {}) do
		pcall(function()
			part.Transparency = tr
		end)
	end
	if char then
		for _, d in ipairs(char:GetDescendants()) do
			local ot = d:GetAttribute("AS_OT")
			if ot ~= nil then
				pcall(function()
					d.Transparency = ot
				end)
				d:SetAttribute("AS_OT", nil)
			end
		end
	end
	E.hidden = {}
	E.skinActive = false
end

function E.renderSkinWeld(desc)
	local hum, char = E.humanoid()
	local model = donorModel(desc)
	if not model then
		return false, "donor rig gagal dibuat (CreateHumanoidModelFromDescriptionAsync ditolak/diblokir)"
	end
	copyAnimations(model, char, hum, desc)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Motor6D") or d:IsA("LuaSourceContainer") then
			d:Destroy()
		end
	end
	local nAcc = 0
	for _, ch in ipairs(model:GetChildren()) do
		if ch:IsA("Accessory") then
			nAcc = nAcc + 1
		end
	end
	local dh = model:FindFirstChildOfClass("Humanoid")
	if dh then
		pcall(function()
			dh.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			dh.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
			dh.RequiresNeck = false
			dh.BreakJointsOnDeath = false
			dh.EvaluateStateMachine = false
		end)
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
			d.Massless = true
		end
	end
	E.removeSkin()
	local welded = 0
	for _, dp in ipairs(model:GetChildren()) do
		if dp:IsA("BasePart") then
			local cp = char:FindFirstChild(dp.Name)
			if cp and cp:IsA("BasePart") then
				local c0, c1 = CFrame.new(), CFrame.new()
				local ca, da = matchAttachment(cp, dp)
				if ca then
					c0, c1 = ca.CFrame, da.CFrame
				end
				dp.CFrame = cp.CFrame * c0 * c1:Inverse()
				local w = Instance.new("Weld")
				w.Name = "AS_SkinWeld"
				w.Part0 = cp
				w.Part1 = dp
				w.C0 = c0
				w.C1 = c1
				w.Parent = dp
				welded = welded + 1
			else
				dp.Transparency = 1
			end
		end
	end
	if welded == 0 then
		model:Destroy()
		return false, "tidak ada bagian tubuh yang cocok untuk dilas (rig berbeda?)"
	end
	E.hidden = {}
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and not d:FindFirstAncestorOfClass("Tool") then
			local ot = d:GetAttribute("AS_OT")
			if ot == nil then
				ot = d.Transparency
				d:SetAttribute("AS_OT", ot)
			end
			E.hidden[d] = ot
			d.Transparency = 1
		end
	end
	model.Name = SKIN_NAME
	model.Parent = char
	E.skinActive = true
	E.skinAcc = nAcc
	E.rendered = 0
	E.lastRenderAt = os.clock()
	logf("skin overlay: %d bagian dilas, %d aksesori", welded, nAcc)
	task.delay(0.2, E.reapplyTweaks)
	return true
end

function E.attachDirect(id, host)
	if not host then
		return false
	end
	local objs
	local ok, o = pcall(function()
		return game:GetObjects("rbxassetid://" .. tostring(id))
	end)
	if ok and type(o) == "table" and #o > 0 then
		objs = o
	else
		local ok2, m = pcall(function()
			return InsertService:LoadAsset(id)
		end)
		if ok2 and m then
			objs = { m }
		end
	end
	if not objs then
		logf("muat langsung %s gagal (GetObjects & LoadAsset ditolak)", tostring(id))
		return false
	end
	local acc = findIn(objs, "Accessory")
	if not acc then
		logf("muat langsung %s: aset bukan Accessory", tostring(id))
		return false
	end
	local c = acc:Clone()
	c.Name = "AS_" .. tostring(id)
	local okA, how = attachAccessory(c, host)
	logf("muat langsung %s -> %s (%s)", tostring(id), tostring(okA), tostring(how))
	return okA
end

local function donorHas(id, tid)
	local d = Instance.new("HumanoidDescription")
	if not addToDesc(d, id, tid) then
		return false
	end
	local m = donorModel(d)
	if not m then
		return false
	end
	local has = m:FindFirstChildOfClass("Accessory") ~= nil
	pcall(function()
		m:Destroy()
	end)
	return has
end

local function directFallback(desc, added, model, nAcc)
	local expected = #desc:GetAccessories(true)
	if nAcc >= expected then
		return 0, {}
	end
	local dset = collect(desc)
	local cand = {}
	for id in pairs(E.directIds) do
		if dset[id] then
			cand[id] = true
		end
	end
	for _, id in ipairs(added or {}) do
		cand[id] = true
	end
	local n, failed = 0, {}
	for id in pairs(cand) do
		local tid = E.assetType(id)
		if tid and ACC[tid] then
			if not E.directIds[id] and donorHas(id, tid) then
				logf("aksesori %s dimuat donor sendiri", tostring(id))
			elseif E.attachDirect(id, model) then
				E.directIds[id] = true
				n = n + 1
			else
				logf("aksesori %s DITOLAK: donor membuangnya & muat langsung gagal", tostring(id))
				table.insert(failed, id)
			end
		end
	end
	return n, failed
end

function E.renderSkinPuppet(desc, added)
	local hum, char = E.humanoid()
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false, "karakter tanpa HumanoidRootPart"
	end
	local model = donorModel(desc)
	if not model then
		return false, "donor rig gagal dibuat (CreateHumanoidModelFromDescriptionAsync ditolak/diblokir)"
	end
	local dhrp = model:FindFirstChild("HumanoidRootPart")
	if not dhrp then
		model:Destroy()
		return false, "donor tanpa HumanoidRootPart"
	end
	copyAnimations(model, char, hum, desc)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("LuaSourceContainer") then
			d:Destroy()
		end
	end
	local nAcc = 0
	for _, ch in ipairs(model:GetChildren()) do
		if ch:IsA("Accessory") then
			nAcc = nAcc + 1
		end
	end
	local dh = model:FindFirstChildOfClass("Humanoid")
	if dh then
		pcall(function()
			dh.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			dh.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
			dh.BreakJointsOnDeath = false
			dh.EvaluateStateMachine = false
		end)
		pcall(function()
			dh:ChangeState(Enum.HumanoidStateType.Physics)
		end)
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
			d.Massless = true
		end
	end
	local offY = 0
	if hum.RigType == Enum.HumanoidRigType.R15 and dh then
		local okH, v = pcall(function()
			return (dh.HipHeight + dhrp.Size.Y / 2) - (hum.HipHeight + hrp.Size.Y / 2)
		end)
		if okH and type(v) == "number" and math.abs(v) <= 6 then
			offY = v
		end
	end
	E.removeSkin()
	if not model.PrimaryPart then
		model.PrimaryPart = dhrp
	end
	model:PivotTo(hrp.CFrame * CFrame.new(0, offY, 0))
	local w = Instance.new("Weld")
	w.Name = "AS_SkinWeld"
	w.Part0 = hrp
	w.Part1 = dhrp
	w.C0 = CFrame.new(0, offY, 0)
	w.C1 = CFrame.new()
	w.Parent = dhrp
	local ours = {}
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("Motor6D") and not ours[d.Name] then
			ours[d.Name] = d
		end
	end
	local links = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Motor6D") and ours[d.Name] then
			table.insert(links, { ours[d.Name], d })
		end
	end
	if #links == 0 then
		model:Destroy()
		return false, "tidak ada sendi (Motor6D) yang cocok antara karakter dan donor"
	end
	E.hidden = {}
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and not d:FindFirstAncestorOfClass("Tool") then
			local ot = d:GetAttribute("AS_OT")
			if ot == nil then
				ot = d.Transparency
				d:SetAttribute("AS_OT", ot)
			end
			E.hidden[d] = ot
			d.Transparency = 1
		end
	end
	model.Name = SKIN_NAME
	model.Parent = char
	E.skinConn = RunService.RenderStepped:Connect(function()
		for _, l in ipairs(links) do
			l[2].Transform = l[1].Transform
		end
	end)
	E.skinActive = true
	E.skinAcc = nAcc
	E.rendered = 0
	E.lastRenderAt = os.clock()
	local direct, bad = directFallback(desc, added, model, nAcc)
	E.lastFailedIds = bad
	E.skinAcc = nAcc + direct
	logf("skin boneka: %d sendi disalin, %d aksesori dari donor, %d dimuat langsung, offset tinggi %.2f", #links, nAcc, direct, offY)
	task.delay(0.2, E.reapplyTweaks)
	return true
end

function E.skinRender(desc, added)
	E.lastFailedIds = {}
	if E.skinMode == "weld" then
		return E.renderSkinWeld(desc)
	end
	local ok, err = E.renderSkinPuppet(desc, added)
	if ok then
		return true
	end
	logf("skin boneka gagal: %s -> coba las per-bagian", tostring(err))
	return E.renderSkinWeld(desc)
end

function E.apply(desc)
	if E.useSkin and E.cap.donor ~= false then
		local ok, err = E.skinRender(desc)
		if ok then
			return true
		end
		logf("skin gagal: %s -> pakai render donor biasa", tostring(err))
	end
	E.removeSkin()
	return E.renderLook(desc)
end

function E.scheduleRerender()
	E.rrToken = (E.rrToken or 0) + 1
	local t = E.rrToken
	task.delay(0.7, function()
		if t == E.rrToken then
			E.rerender()
		end
	end)
end

function E.renderLook(desc)
	local hum, char = E.humanoid()
	local model = donorModel(desc)
	if not model then
		return false, "donor rig gagal dibuat (CreateHumanoidModelFromDescriptionAsync ditolak/diblokir)"
	end
	E.cleanInjected(char)
	for _, ch in ipairs(char:GetChildren()) do
		if ch:IsA("Accessory") or ch:IsA("Shirt") or ch:IsA("Pants") or ch:IsA("ShirtGraphic") then
			ch:Destroy()
		end
	end
	local nAcc = 0
	for _, ch in ipairs(model:GetChildren()) do
		if ch:IsA("Accessory") then
			harvestAccessory(ch, char)
			nAcc = nAcc + 1
		elseif ch:IsA("Shirt") or ch:IsA("Pants") or ch:IsA("ShirtGraphic") or ch:IsA("BodyColors") then
			if ch:IsA("BodyColors") then
				local oldBC = char:FindFirstChildOfClass("BodyColors")
				if oldBC then
					oldBC:Destroy()
				end
			end
			local c = ch:Clone()
			c.Parent = char
		end
	end
	local faceId = getProp(desc, "Face")
	local mh, head = model:FindFirstChild("Head"), char:FindFirstChild("Head")
	if mh and head and type(faceId) == "number" and faceId > 0 then
		local mf, f = mh:FindFirstChildOfClass("Decal"), head:FindFirstChildOfClass("Decal")
		if mf and f then
			f.Texture = mf.Texture
		end
	end
	copyAnimations(model, char, hum, desc)
	if E.copyBody then
		copyBodyParts(model, char)
	end
	model:Destroy()
	E.rendered = nAcc
	E.lastRenderAt = os.clock()
	logf("render donor: %d aksesori dipasang", nAcc)
	return true
end

function E.rerender()
	if E.busy or not E.look or E.remote then
		return
	end
	E.busy = true
	local ok, err = pcall(function()
		local r, e = E.apply(E.look)
		if not r then
			logf("render ulang gagal: %s", tostring(e))
		end
		E.failed = {}
	end)
	if not ok then
		logf("render ulang error: %s", tostring(err))
	end
	E.busy = false
	E.reapplyTweaks()
end

local function isInjectable(t)
	return t and (ACC[t] or t == 11 or t == 12 or t == 2 or t == 18 or ANIM_SLOT[t])
end

local FAST_CLASS = { [11] = "Shirt", [12] = "Pants", [2] = "ShirtGraphic" }

-- pasang/lepas 1-3 item langsung di boneka skin (tanpa render ulang donor)
function E.fastApply(added, removed)
	local total = #added + #removed
	if not E.skinActive or not E.useSkin or total == 0 or total > 3 then
		return false
	end
	local char = player.Character
	local skin = char and char:FindFirstChild(SKIN_NAME)
	if not skin then
		return false
	end
	local plan = {}
	for _, id in ipairs(removed) do
		local tagged
		for _, ch in ipairs(skin:GetChildren()) do
			if ch:GetAttribute("ASF") == id then
				tagged = ch
				break
			end
		end
		local tid = E.types[id]
		if tagged then
			table.insert(plan, { "del", id, tagged })
		elseif tid and FAST_CLASS[tid] then
			table.insert(plan, { "delclass", id, FAST_CLASS[tid] })
		else
			return false -- item dari render donor: pakai render penuh
		end
	end
	for _, id in ipairs(added) do
		local tid = E.types[id] or E.assetType(id)
		local acc = tid and ACC[tid]
		if acc and not acc[2] and tid ~= 76 and tid ~= 77 then
			table.insert(plan, { "acc", id, tid })
		elseif tid and FAST_CLASS[tid] then
			table.insert(plan, { "cls", id, tid })
		else
			return false -- layered / alis / bulu mata / bodypart / animasi: render penuh
		end
	end
	for _, p in ipairs(plan) do
		local kind, id = p[1], p[2]
		if kind == "del" then
			p[3]:Destroy()
		elseif kind == "delclass" then
			for _, ch in ipairs(skin:GetChildren()) do
				if ch:IsA(p[3]) then
					ch:Destroy()
				end
			end
		elseif kind == "acc" then
			if not E.attachDirect(id, skin) then
				return false
			end
			local c = skin:FindFirstChild("AS_" .. id)
			if c then
				c:SetAttribute("ASF", id)
			end
		else
			local class = FAST_CLASS[p[3]]
			local objs, how = loadAsset(id, p[3])
			if not objs then
				return false
			end
			local inst = findIn(objs, class)
			if not inst then
				if how == "donor" then
					pcall(function()
						objs[1]:Destroy()
					end)
				end
				return false
			end
			for _, ch in ipairs(skin:GetChildren()) do
				if ch:IsA(class) then
					ch:Destroy()
				end
			end
			local c = inst:Clone()
			c.Name = "AS_" .. id
			c:SetAttribute("ASF", id)
			c.Parent = skin
			if how == "donor" then
				pcall(function()
					objs[1]:Destroy()
				end)
			end
		end
	end
	return true
end

-- pastikan aksesori benar-benar ada di boneka; kalau kurang, pasang langsung
function E.ensureWorn(id)
	if E.remote or not E.skinActive then
		return true
	end
	local char = player.Character
	local skin = char and char:FindFirstChild(SKIN_NAME)
	if not skin then
		return false
	end
	local tid = E.types[id]
	if not (tid and ACC[tid]) then
		return true
	end
	local n = 0
	for _, ch in ipairs(skin:GetChildren()) do
		if ch:IsA("Accessory") then
			n = n + 1
		end
	end
	if n >= #E.look:GetAccessories(true) then
		return true
	end
	if skin:FindFirstChild("AS_" .. id) then
		return true
	end
	if E.attachDirect(id, skin) then
		local c = skin:FindFirstChild("AS_" .. id)
		if c then
			c:SetAttribute("ASF", id)
		end
		return true
	end
	return false
end

function E._commit(newLook, text, skipHist, force)
	local hum, char = E.humanoid()
	local prevSet = collect(E.look)
	local nowSet = collect(newLook)
	local added, removed = {}, {}
	for id in pairs(nowSet) do
		if not prevSet[id] then
			table.insert(added, id)
		end
	end
	for id in pairs(prevSet) do
		if not nowSet[id] then
			table.insert(removed, id)
		end
	end

	if not force and not E.remote and E.fastApply(added, removed) then
		E.lastMethod = "cepat"
		if not skipHist and E.look then
			table.insert(E.history, E.look)
			while #E.history > 40 do
				table.remove(E.history, 1)
			end
			E.redo = {}
		end
		E.look = newLook
		E.failed = {}
		task.delay(0.1, E.reapplyTweaks)
		fire()
		return true
	end

	local how
	if E.remote then
		E.cleanInjected(char)
		local ok, err = serverApply(newLook)
		if ok then
			how = "server"
			for id in pairs(E.failed) do
				if nowSet[id] then
					local tid = E.assetType(id)
					if tid then
						E.inject(id, tid)
					end
				end
			end
		else
			logf("server menolak (%s) -> jalur klien", tostring(err))
		end
	end

	if not how and E.useSkin and E.cap.donor ~= false then
		local okS, errS = E.skinRender(newLook, added)
		if okS then
			how = "skin"
			E.failed = {}
			for _, bid in ipairs(E.lastFailedIds or {}) do
				removeFromDesc(newLook, bid)
				toast("\"" .. E.name(bid) .. "\" ditolak Roblox (sering: item off-sale/UGC terbatas di rig klien) dan muat langsung juga gagal. Coba item lain.", "warn")
			end
			local expected = #newLook:GetAccessories(true)
			if (E.skinAcc or 0) < expected then
				toast(string.format("Hanya %d dari %d aksesori yang berhasil dirender (sisanya diblokir Roblox/map).",
					E.skinAcc or 0, expected), "warn")
			end
		else
			logf("skin gagal: %s (pakai jalur cadangan)", tostring(errS))
		end
	end

	if not how then
		if not force and (#added + #removed) > 0 then
			local canInc = true
			for _, id in ipairs(removed) do
				if not E.failed[id] then
					canInc = false
				end
			end
			for _, id in ipairs(added) do
				if not isInjectable(E.assetType(id)) then
					canInc = false
				end
			end
			if canInc then
				for _, id in ipairs(removed) do
					E.failed[id] = nil
					for _, ch in ipairs(char:GetChildren()) do
						if ch:GetAttribute("AS") == id then
							ch:Destroy()
						end
					end
					char:SetAttribute("ASX_" .. tostring(id), nil)
				end
				local bad = 0
				for _, id in ipairs(added) do
					E.failed[id] = true
					if not E.inject(id, E.assetType(id)) then
						E.failed[id] = nil
						bad = bad + 1
					end
				end
				if bad == 0 then
					how = "injector"
				else
					logf("injector gagal untuk %d item -> coba render donor", bad)
				end
			end
		end
		if not how then
			local ok, err = E.renderLook(newLook)
			if not ok then
				toast("Gagal memasang: " .. tostring(err) .. (E.lastInjectErr and (" | injector: " .. E.lastInjectErr) or ""), "danger")
				return false
			end
			E.failed = {}
			how = "donor-render"
			local expected = #newLook:GetAccessories(true)
			if (E.rendered or 0) < expected then
				toast(string.format("Hanya %d dari %d aksesori yang berhasil dirender (sisanya diblokir Roblox/map).",
					E.rendered or 0, expected), "warn")
			end
		end
	end

	E.lastMethod = how
	if not skipHist and E.look then
		table.insert(E.history, E.look)
		while #E.history > 40 do
			table.remove(E.history, 1)
		end
		E.redo = {}
	end
	E.look = newLook
	task.delay(0.3, E.reapplyTweaks)
	fire()
	return true
end

function E.commit(newLook, text, skipHist, force)
	if E.busy then
		toast("Tunggu sebentar, avatar masih diproses...", "warn")
		return false
	end
	E.busy = true
	local ok, res = pcall(E._commit, newLook, text, skipHist, force)
	E.busy = false
	if not ok then
		toast("Error: " .. tostring(res), "danger")
		return false
	end
	return res
end

------------------------------------------------------------------------
-- ANTRIAN RENDER: klik beruntun digabung, hanya hasil akhir yang dirender
------------------------------------------------------------------------
E.pending, E.pendingCbs, E.worker = nil, {}, false

function E.queueLook(nl, onDone)
	E.pending = nl
	if onDone then
		table.insert(E.pendingCbs, onDone)
	end
	if E.worker then
		return
	end
	E.worker = true
	task.spawn(function()
		while E.pending do
			local l, cbs = E.pending, E.pendingCbs
			E.pending, E.pendingCbs = nil, {}
			while E.busy do
				task.wait(0.05)
			end
			local ok = E.commit(l, "queue")
			for _, cb in ipairs(cbs) do
				pcall(cb, ok)
			end
		end
		E.worker = false
	end)
end

------------------------------------------------------------------------
-- API tingkat tinggi
------------------------------------------------------------------------
function E.toggleAsset(id, itemName, onDone)
	local function finish(ok)
		if onDone then
			onDone(ok)
		end
		return ok
	end
	if not needReady() then
		return finish(false)
	end
	local tid = E.assetType(id)
	if not tid then
		toast("Tidak bisa membaca info item ini", "danger")
		return finish(false)
	end
	if not ACC[tid] and not CLASSIC[tid] then
		toast("Tipe item ini belum didukung", "warn")
		return finish(false)
	end
	local t0 = os.clock()
	local base = E.pending or E.look
	local worn = (collect(base))[id] == true
	local nl = base:Clone()
	if worn then
		removeFromDesc(nl, id)
	else
		addToDesc(nl, id, tid)
	end
	E.queueLook(nl, function(ok)
		if ok then
			if worn then
				toast("Dilepas: " .. tostring(itemName or id), "warn")
			elseif E.isWorn(id) then
				local okW = E.ensureWorn(id)
				toast(string.format("Dipakai: %s  (%s, %.1f dtk)", tostring(itemName or id), E.lastMethod, os.clock() - t0), okW and "ok" or "warn")
			end
		end
		finish(ok)
	end)
	return true
end

function E.removeAsset(id)
	if not needReady() then
		return false
	end
	local nl = (E.pending or E.look):Clone()
	removeFromDesc(nl, id)
	E.queueLook(nl)
	return true
end

local BODY_PARTS = {
	[17] = { "Head" },
	[27] = { "UpperTorso", "LowerTorso" },
	[28] = { "RightUpperArm", "RightLowerArm", "RightHand" },
	[29] = { "LeftUpperArm", "LeftLowerArm", "LeftHand" },
	[30] = { "LeftUpperLeg", "LeftLowerLeg", "LeftFoot" },
	[31] = { "RightUpperLeg", "RightLowerLeg", "RightFoot" },
}
E.bodyPre, E.bodyPreOrder = {}, {}

local function bodyDesc(assets)
	local d = Instance.new("HumanoidDescription")
	for _, a in ipairs(assets) do
		addToDesc(d, a.id, a.tid)
	end
	return d
end

-- tukar mesh bagian tubuh langsung di boneka skin (tanpa render ulang seluruh avatar)
function E.fastBody(bundleId, assets)
	if E.remote or not E.skinActive then
		return false
	end
	local char = player.Character
	local skin = char and char:FindFirstChild(SKIN_NAME)
	local hum = E.humanoid()
	if not skin or hum.RigType ~= Enum.HumanoidRigType.R15 then
		return false
	end
	local model = E.bodyPre[bundleId]
	if model then
		E.bodyPre[bundleId] = nil
		for i, id in ipairs(E.bodyPreOrder) do
			if id == bundleId then
				table.remove(E.bodyPreOrder, i)
				break
			end
		end
	else
		model = buildDonor(bodyDesc(assets))
	end
	if not model then
		return false
	end
	local changed, n = {}, 0
	for _, a in ipairs(assets) do
		for _, pn in ipairs(BODY_PARTS[a.tid] or {}) do
			local dp, cp = model:FindFirstChild(pn), skin:FindFirstChild(pn)
			if dp and cp and dp:IsA("MeshPart") and cp:IsA("MeshPart") then
				pcall(function()
					cp.MeshId = dp.MeshId
					cp.TextureID = dp.TextureID
					cp.Size = dp.Size
				end)
				pcall(function()
					for _, x in ipairs(cp:GetChildren()) do
						if x:IsA("SurfaceAppearance") then
							x:Destroy()
						end
					end
					local sa = dp:FindFirstChildOfClass("SurfaceAppearance")
					if sa then
						sa:Clone().Parent = cp
					end
				end)
				for _, da in ipairs(dp:GetChildren()) do
					if da:IsA("Attachment") then
						local ca = cp:FindFirstChild(da.Name)
						if ca and ca:IsA("Attachment") then
							ca.CFrame = da.CFrame
						end
					end
				end
				changed[pn] = true
				n = n + 1
			end
		end
	end
	if n > 0 then
		local ours = {}
		for _, d in ipairs(skin:GetDescendants()) do
			if d:IsA("Motor6D") and not ours[d.Name] then
				ours[d.Name] = d
			end
		end
		for _, m in ipairs(model:GetDescendants()) do
			if m:IsA("Motor6D") and ours[m.Name] and m.Part0 and m.Part1 and (changed[m.Part0.Name] or changed[m.Part1.Name]) then
				pcall(function()
					ours[m.Name].C0 = m.C0
					ours[m.Name].C1 = m.C1
				end)
			end
		end
	end
	pcall(function()
		model:Destroy()
	end)
	return n > 0
end

function E.resolveBundle(bundleId)
	local c = E.bundleCache[bundleId]
	if c then
		local t0 = os.clock()
		while not c.done and os.clock() - t0 < 12 do
			task.wait()
		end
		if c.done and not c.failed then
			return c.results, c.n
		end
		return nil
	end
	c = { done = false }
	E.bundleCache[bundleId] = c
	local info = productInfo(bundleId, Enum.InfoType.Bundle)
	if not info or not info.Items then
		c.done, c.failed = true, true
		E.bundleCache[bundleId] = nil
		return nil
	end
	local n = #info.Items
	local results, left = {}, n
	for i, item in ipairs(info.Items) do
		task.spawn(function()
			pcall(function()
				if item.Type == "UserOutfit" then
					results[i] = { kind = "outfit", d = descFromOutfit(item.Id) }
				elseif item.Type == "Asset" then
					results[i] = { kind = "asset", id = item.Id, tid = E.assetType(item.Id) }
				end
			end)
			left = left - 1
		end)
	end
	local t0 = os.clock()
	while left > 0 and os.clock() - t0 < 12 do
		task.wait()
	end
	c.results, c.n, c.done = results, n, true
	return results, n
end

-- antrean prefetch bundle (3 paralel). Bundle bagian tubuh juga disiapkan model donornya (maks 6)
E.bQ, E.bWorkers = {}, 0
function E.prefetchBundle(id)
	if E.bundleCache[id] then
		return
	end
	table.insert(E.bQ, 1, id)
	while E.bWorkers < 3 and #E.bQ > 0 do
		E.bWorkers = E.bWorkers + 1
		task.spawn(function()
			while #E.bQ > 0 and not stale() do
				local b = table.remove(E.bQ, 1)
				if not E.bundleCache[b] then
					pcall(function()
						local results, n = E.resolveBundle(b)
						if results and not E.remote and E.skinActive and #E.bodyPreOrder < 6 and not E.bodyPre[b] then
							local assets, only = {}, true
							for i = 1, n do
								local r = results[i]
								if r and r.kind == "asset" and r.tid and BODY_PARTS[r.tid] then
									assets[#assets + 1] = { id = r.id, tid = r.tid }
								elseif r then
									only = false
								end
							end
							if only and #assets > 0 then
								local m = buildDonor(bodyDesc(assets))
								if m then
									E.bodyPre[b] = m
									table.insert(E.bodyPreOrder, b)
								end
							end
						end
					end)
				end
			end
			E.bWorkers = E.bWorkers - 1
		end)
	end
end

function E.equipBundle(bundleId, bundleName, onDone, slot, slotName)
	local function finish(ok)
		if onDone then
			onDone(ok)
		end
		return ok
	end
	if not needReady() then
		return finish(false)
	end
	local results, n = E.resolveBundle(bundleId)
	if not results then
		toast("Gagal membaca isi bundle", "danger")
		return finish(false)
	end
	local nl = (E.pending or E.look):Clone()
	local applied = 0
	local bodyAssets, onlyBody = {}, true
	for i = 1, n do
		local r = results[i]
		if r then
			if r.kind == "outfit" and r.d and not slot then
				mergeDescription(nl, r.d)
				applied = applied + 1
				onlyBody = false
			elseif r.kind == "asset" and r.tid and (not slot or r.tid == slot) then
				addToDesc(nl, r.id, r.tid)
				applied = applied + 1
				if BODY_PARTS[r.tid] then
					bodyAssets[#bodyAssets + 1] = { id = r.id, tid = r.tid }
				else
					onlyBody = false
				end
			end
		end
	end
	-- jalur kilat: bundle hanya berisi bagian tubuh -> tukar mesh di boneka (target ~2 detik)
	if applied > 0 and onlyBody and #bodyAssets > 0 and not E.remote and E.skinActive and not E.busy and not E.pending then
		local t0 = os.clock()
		E.busy = true
		local okF, resF = pcall(E.fastBody, bundleId, bodyAssets)
		E.busy = false
		if okF and resF then
			if E.look then
				table.insert(E.history, E.look)
				E.redo = {}
			end
			E.look = nl
			E.failed = {}
			E.lastMethod = "badan-cepat"
			fire()
			toast(string.format("%s dipakai: %s  (%.1f dtk)", tostring(slotName or "Bundle"), tostring(bundleName or bundleId), os.clock() - t0), "ok")
			return finish(true)
		end
	end
	if slot and applied == 0 then
		toast("Paket ini tidak punya " .. tostring(slotName or "bagian itu") .. ", coba paket lain", "warn")
		return finish(false)
	end
	E.queueLook(nl, function(ok)
		if ok then
			toast((slot and (tostring(slotName) .. " dipakai dari: ") or "Bundle dipakai: ") .. tostring(bundleName or bundleId), "ok")
		end
		finish(ok)
	end)
	return true
end

E.descCache, E.descOrder = {}, {}

function E.cacheDesc(uid, desc)
	if E.descCache[uid] then
		return
	end
	E.descCache[uid] = desc
	table.insert(E.descOrder, uid)
	if #E.descOrder > 250 then
		local oldId = table.remove(E.descOrder, 1)
		local d = E.descCache[oldId]
		E.descCache[oldId] = nil
		pcall(function()
			d:Destroy()
		end)
	end
end

function E.getDesc(uid)
	local c = E.descCache[uid]
	if c then
		return c:Clone()
	end
	local d, err = descFromUser(uid)
	if d then
		E.cacheDesc(uid, d)
		return d:Clone()
	end
	return nil, err
end

------------------------------------------------------------------------
-- PREFETCH AVATAR: boneka donor disiapkan lebih dulu, jadi saat kartu diklik
-- avatar langsung terpasang (tinggal pasang, tidak perlu menunggu download lagi)
------------------------------------------------------------------------
local PRE_MAX = 10

function E.preEvict()
	while #E.preOrder > PRE_MAX do
		local uid = table.remove(E.preOrder, 1)
		local rec = E.preCache[uid]
		E.preCache[uid] = nil
		if rec then
			pcall(function()
				rec.model:Destroy()
			end)
		end
	end
end

function E.prefetchUser(uid)
	if E.remote or E.preCache[uid] or E.preJobs[uid] then
		return
	end
	E.preJobs[uid] = true
	task.spawn(function()
		pcall(function()
			local d = E.getDesc(uid)
			if not d then
				return
			end
			local m = buildDonor(d)
			if not m then
				return
			end
			if E.preCache[uid] then
				pcall(function()
					m:Destroy()
				end)
				return
			end
			E.preCache[uid] = { desc = d, model = m }
			table.insert(E.preOrder, uid)
			E.preEvict()
		end)
		E.preJobs[uid] = nil
	end)
end

-- antrean prefetch latar belakang (maks 2 paralel) untuk kartu yang sedang terlihat
E.bgQ, E.bgWorkers = {}, 0
function E.prefetchBg(uid)
	if E.remote or E.preCache[uid] or E.preJobs[uid] then
		return
	end
	for _, q in ipairs(E.bgQ) do
		if q == uid then
			return
		end
	end
	table.insert(E.bgQ, uid)
	while E.bgWorkers < 2 and #E.bgQ > 0 do
		E.bgWorkers = E.bgWorkers + 1
		task.spawn(function()
			while #E.bgQ > 0 and not stale() do
				local u = table.remove(E.bgQ, 1)
				if not E.preCache[u] and not E.preJobs[u] then
					E.prefetchUser(u)
					local t0 = os.clock()
					while E.preJobs[u] and os.clock() - t0 < 10 do
						task.wait(0.05)
					end
				end
			end
			E.bgWorkers = E.bgWorkers - 1
		end)
	end
end

-- foto profil: antrean preload paralel (3 pekerja x 24 gambar) supaya semua kartu terisi secepat mungkin
E.thumbQ, E.thumbWorkers = {}, 0
function E.preloadImg(img)
	table.insert(E.thumbQ, img)
	while E.thumbWorkers < 3 and #E.thumbQ > 0 do
		E.thumbWorkers = E.thumbWorkers + 1
		task.spawn(function()
			local CP = game:GetService("ContentProvider")
			while #E.thumbQ > 0 and not stale() do
				local batch = {}
				for _ = 1, 24 do
					local im = table.remove(E.thumbQ, 1)
					if not im then
						break
					end
					if im.Parent and not im.IsLoaded then
						batch[#batch + 1] = im
					end
				end
				if #batch > 0 then
					pcall(function()
						CP:PreloadAsync(batch)
					end)
				end
			end
			E.thumbWorkers = E.thumbWorkers - 1
		end)
	end
end

function E.applyUserVisual(userId, displayName, keepLook)
	local desc, derr
	local rec = E.preCache[userId]
	if not rec and E.preJobs[userId] then
		local t0 = os.clock()
		while E.preJobs[userId] and os.clock() - t0 < 8 do
			task.wait(0.03)
		end
		rec = E.preCache[userId]
	end
	if rec then
		desc = rec.desc
	else
		desc, derr = E.getDesc(userId)
	end
	if not desc then
		logf("ambil avatar %s gagal: %s", tostring(userId), tostring(derr))
		return false, "gagal mengambil avatar: " .. tostring(derr)
	end
	local ok, err = E.apply(desc)
	if not ok then
		logf("render avatar %s gagal: %s", tostring(userId), tostring(err))
		return false, err
	end
	if not keepLook then
		if E.look then
			table.insert(E.history, E.look)
			E.redo = {}
		end
		E.look = desc
		E.failed = {}
		E.userVisual = userId
		fire()
	end
	task.delay(0.3, E.reapplyTweaks)
	return true
end

function E.applyUser(userId, displayName)
	if E.busy then
		E.nextUser = { userId, displayName } -- klik terakhir dipasang begitu yang sekarang selesai
		toast("Antre: " .. tostring(displayName or userId) .. " dipasang sesudah proses ini", "warn")
		return false
	end
	if E.remote then
		local desc = E.getDesc(userId)
		if not desc then
			toast("Avatar pemain tidak bisa dimuat", "danger")
			return false
		end
		local done = E.commit(desc, displayName)
		if done then
			toast("Avatar dipakai: " .. tostring(displayName or userId), "ok")
		end
		return done
	end
	local t0 = os.clock()
	E.busy = true
	local ok, res, why = pcall(E.applyUserVisual, userId, displayName)
	E.busy = false
	local nx = E.nextUser
	E.nextUser = nil
	if ok and res then
		E.lastMethod = "donor-render"
		toast(string.format("Avatar dipakai: %s  (%.1f dtk)", tostring(displayName or userId), os.clock() - t0), "ok")
	else
		toast("Avatar tidak bisa dipasang: " .. tostring(ok and why or res) .. "  (lihat output/console)", "danger")
	end
	if nx and nx[1] ~= userId then
		task.spawn(E.applyUser, nx[1], nx[2])
	end
	return ok and res and true or false
end

function E.removeAll()
	if not needReady() then
		return false
	end
	local nl = (E.pending or E.look):Clone()
	nl:SetAccessories({}, true)
	E.failed = {}
	E.queueLook(nl)
	return true
end

function E.undo()
	local entry = table.remove(E.history)
	if not entry then
		toast("Tidak ada yang bisa di-undo", "warn")
		return
	end
	table.insert(E.redo, E.look)
	E.commit(entry, "undo", true)
end

function E.doRedo()
	local entry = table.remove(E.redo)
	if not entry then
		toast("Tidak ada yang bisa di-redo", "warn")
		return
	end
	table.insert(E.history, E.look)
	E.commit(entry, "redo", true)
end

function E.reset()
	if not needReady() then
		return
	end
	E.pending = nil
	if E.skinActive then
		E.removeSkin()
		E.userVisual = nil
		E.failed = {}
		E.resetScales()
		E.resetSkin()
		E.look = E.original:Clone()
		E.history, E.redo = {}, {}
		fire()
		toast("Avatar dikembalikan seperti semula", "ok")
		return
	end
	pcall(E.restoreBody)
	E.userVisual = nil
	E.failed = {}
	E.resetScales()
	E.resetSkin()
	E.commit(E.original:Clone(), "reset")
	toast("Avatar dikembalikan seperti semula", "ok")
end

function E.setScale(key, value, noRender)
	E.scales[key] = value
	local hum = E.humanoid()
	local nv = hum:FindFirstChild(SCALE_VALUES[key])
	if nv and nv:IsA("NumberValue") then
		nv.Value = value
	end
	if E.skinActive and E.look and not noRender then
		setProp(E.look, SCALE_DESC[key], value)
		E.scheduleRerender()
	end
end

function E.resetScales()
	E.scales = {}
	if E.original then
		local hum = E.humanoid()
		for key, prop in pairs(SCALE_DESC) do
			local v = getProp(E.original, prop)
			local nv = hum:FindFirstChild(SCALE_VALUES[key])
			if v and nv and nv:IsA("NumberValue") then
				nv.Value = v
			end
			if E.skinActive and E.look and v then
				setProp(E.look, prop, v)
			end
		end
		if E.skinActive then
			E.scheduleRerender()
		end
	end
end

function E.setSkin(color)
	E.skin = color
	local _, char = E.humanoid()
	local bc = char:FindFirstChildOfClass("BodyColors")
	if bc then
		for _, prop in ipairs(BODY_COLOR_PROPS) do
			bc[prop] = color
		end
	end
	local sk = char:FindFirstChild(SKIN_NAME)
	if sk then
		for _, p in ipairs(sk:GetChildren()) do
			if p:IsA("BasePart") and isBodyPart(p.Name) then
				p.Color = color
			end
		end
	end
end

function E.resetSkin()
	E.skin = nil
	if E.skinActive then
		E.scheduleRerender()
	end
	if E.origColors then
		local _, char = E.humanoid()
		local bc = char:FindFirstChildOfClass("BodyColors")
		if bc then
			for _, prop in ipairs(BODY_COLOR_PROPS) do
				bc[prop] = E.origColors[prop]
			end
		end
	end
end

function E.reapplyTweaks()
	for k, v in pairs(E.scales) do
		E.setScale(k, v, true)
	end
	if E.skin then
		E.setSkin(E.skin)
	end
end

function E.diagnose()
	local hum = E.humanoid()
	toast("Rig: " .. hum.RigType.Name .. "  |  Server script: " .. (E.remote and "ADA" or "tidak ada"), "info")
	local ok = pcall(function()
		return game:GetObjects("rbxassetid://1028606")
	end)
	toast("Mode inject-first: " .. (E.injectFirst and "AKTIF" or "mati") .. "  |  game:GetObjects: " .. (ok and "tersedia" or "tidak tersedia")
		.. "  |  Mode terakhir: " .. (E.lastMethod ~= "" and E.lastMethod or "-"), "info")
end

function E.probe()
	local cap = {}
	local pending = 3
	task.spawn(function()
		local ok, r = pcall(function()
			return game:GetObjects("rbxassetid://1028606")
		end)
		if not ok then
			cap.getObjects = false
		elseif type(r) == "table" and #r > 0 then
			cap.getObjects = true
		end
		pending = pending - 1
	end)
	task.spawn(function()
		local ok2, m2 = pcall(function()
			return InsertService:LoadAsset(1028606)
		end)
		if not ok2 then
			cap.insert = false
		elseif m2 then
			cap.insert = true
			pcall(function()
				m2:Destroy()
			end)
		end
		pending = pending - 1
	end)
	task.spawn(function()
		local okD = pcall(function()
			local d = Instance.new("HumanoidDescription")
			addToDesc(d, 1028606, 8)
			local dm = donorModel(d)
			if dm then
				cap.donor = dm:FindFirstChildOfClass("Accessory") ~= nil or nil
				pcall(function()
					dm:Destroy()
				end)
			else
				cap.donor = false
			end
		end)
		if not okD then
			cap.donor = false
		end
		pending = pending - 1
	end)
	local t0 = os.clock()
	while pending > 0 and os.clock() - t0 < 5 do
		task.wait(0.05)
	end
	E.cap = cap
	E.injectFirst = (cap.getObjects ~= false) or (cap.insert ~= false) or (cap.donor ~= false)
	logf("probe: GetObjects=%s LoadAsset=%s Donor=%s -> inject-first=%s", tostring(cap.getObjects), tostring(cap.insert),
		tostring(cap.donor), tostring(E.injectFirst))
end

function E.snapBody(char)
	E.bodySnap = {}
	for _, n in ipairs(LIMBS) do
		local p = char:FindFirstChild(n)
		if p and p:IsA("BasePart") then
			local rec = { Transparency = p.Transparency }
			if p:IsA("MeshPart") then
				rec.MeshId = p.MeshId
				rec.TextureID = p.TextureID
			end
			local sa = p:FindFirstChildOfClass("SurfaceAppearance")
			if sa then
				rec.SA = sa:Clone()
			end
			E.bodySnap[n] = rec
		end
	end
end

function E.restoreBody()
	local _, char = E.humanoid()
	for n, rec in pairs(E.bodySnap or {}) do
		local p = char:FindFirstChild(n)
		if p and p:IsA("BasePart") then
			pcall(function()
				p.Transparency = rec.Transparency
				if rec.MeshId and p:IsA("MeshPart") then
					p.MeshId = rec.MeshId
					p.TextureID = rec.TextureID
				end
				for _, x in ipairs(p:GetChildren()) do
					if x:IsA("SurfaceAppearance") then
						x:Destroy()
					end
				end
				if rec.SA then
					rec.SA:Clone().Parent = p
				end
			end)
		end
	end
	toast("Badan/tangan/kaki dipulihkan ke bentuk awal", "ok")
end

function E.init()
	local hum, char = E.humanoid()
	E.snapBody(char)
	E.snapAnim(char)
	E.hookChar(char)
	E.remote = ReplicatedStorage:FindFirstChild(REMOTE_NAME) or ReplicatedStorage:WaitForChild(REMOTE_NAME, 1)
	local d, gotDesc = nil, false
	task.spawn(function()
		d = appliedDesc(hum)
		gotDesc = true
	end)
	E.probe()
	local tw = os.clock()
	while not gotDesc and os.clock() - tw < 10 do
		task.wait(0.05)
	end
	d = d or Instance.new("HumanoidDescription")
	E.original = d:Clone()
	E.look = d:Clone()
	E.origColors = {}
	local bc = char:FindFirstChildOfClass("BodyColors")
	if bc then
		for _, prop in ipairs(BODY_COLOR_PROPS) do
			E.origColors[prop] = bc[prop]
		end
	end
	player.CharacterAdded:Connect(function(newChar)
		newChar:WaitForChild("Humanoid")
		if stale() then
			return
		end
		E.hookChar(newChar)
		E.skinActive = false
		E.hidden = {}
		task.wait(1)
		if E.look then
			if E.remote then
				E.commit(E.look:Clone(), "respawn", true, true)
			elseif not E.busy then
				E.busy = true
				pcall(function()
					E.apply(E.look)
					E.failed = {}
				end)
				E.busy = false
				E.reapplyTweaks()
			end
		end
	end)
	task.spawn(function()
		while task.wait(1.2) do
			if stale() then
				break
			end
			if E.injectFirst and not E.remote and not E.busy then
				pcall(E.guard)
			end
		end
	end)
	fire()
end

----------------------------------------------------------------------------
-- [6] KATALOG  (Karakter/Tubuh, Animasi, Sepatu)
----------------------------------------------------------------------------
pcall(function()
	math.randomseed(os.time())
end)

local CATEGORIES = {}
-- variants (hanya untuk bundle, jalur web cadangan): { Category, Subcategory, kataKunciBawaan }
local function C(group, id, name, kind, list, variants, slot)
	table.insert(CATEGORIES, { group = group, id = id, name = name, kind = kind, list = list, httpVariants = variants, slot = slot })
end

C("KARAKTER / TUBUH", "b_body", "Paket Karakter", "bundle", { "BodyParts" }, { { 4, 37 }, { 4 } })
C("KARAKTER / TUBUH", "face", "Ekspresi Wajah", "asset", { "Face" })
C("KARAKTER / TUBUH", "head", "Kepala", "bundle", { "BodyParts" }, { { 4, 37 }, { 4 } }, 17)
C("KARAKTER / TUBUH", "torso", "Badan", "bundle", { "BodyParts" }, { { 4, 37 }, { 4 } }, 27)
C("KARAKTER / TUBUH", "rarm", "Lengan Kanan", "bundle", { "BodyParts" }, { { 4, 37 }, { 4 } }, 28)
C("KARAKTER / TUBUH", "larm", "Lengan Kiri", "bundle", { "BodyParts" }, { { 4, 37 }, { 4 } }, 29)
C("KARAKTER / TUBUH", "rleg", "Kaki Kanan", "bundle", { "BodyParts" }, { { 4, 37 }, { 4 } }, 31)
C("KARAKTER / TUBUH", "lleg", "Kaki Kiri", "bundle", { "BodyParts" }, { { 4, 37 }, { 4 } }, 30)
C("KARAKTER / TUBUH", "brow", "Alis", "asset", { "EyebrowAccessory" })
C("KARAKTER / TUBUH", "lash", "Bulu Mata", "asset", { "EyelashAccessory" })

C("ANIMASI", "b_anim", "Paket Animasi", "bundle", { "Animations" }, { { 12, 38 }, { 12 } })
C("ANIMASI", "a_idle", "Idle", "bundle", { "Animations" }, { { 12, 38 }, { 12 } }, 51)
C("ANIMASI", "a_walk", "Jalan", "bundle", { "Animations" }, { { 12, 38 }, { 12 } }, 55)
C("ANIMASI", "a_run", "Lari", "bundle", { "Animations" }, { { 12, 38 }, { 12 } }, 53)
C("ANIMASI", "a_jump", "Lompat", "bundle", { "Animations" }, { { 12, 38 }, { 12 } }, 52)
C("ANIMASI", "a_fall", "Jatuh", "bundle", { "Animations" }, { { 12, 38 }, { 12 } }, 50)
C("ANIMASI", "a_climb", "Panjat", "bundle", { "Animations" }, { { 12, 38 }, { 12 } }, 48)
C("ANIMASI", "a_swim", "Renang", "bundle", { "Animations" }, { { 12, 38 }, { 12 } }, 54)
C("ANIMASI", "a_mood", "Mood", "asset", { "MoodAnimation" })

C("SEPATU", "b_shoes", "Set Sepatu", "bundle", { "Shoes" }, { { 4, 37, "shoes" }, { 3, nil, "shoes" }, { 1, 37, "shoes" } })
C("SEPATU", "lshoe", "Sepatu Kiri", "asset", { "LeftShoeAccessory" })
C("SEPATU", "rshoe", "Sepatu Kanan", "asset", { "RightShoeAccessory" })

local SORTS = {
	{ name = "Relevansi", enum = "Relevance" },
	{ name = "Terfavorit", enum = "MostFavorited" },
	{ name = "Terlaris", enum = "Bestselling" },
	{ name = "Terbaru", enum = "RecentlyCreated" },
	{ name = "Termurah", enum = "PriceLowToHigh" },
	{ name = "Termahal", enum = "PriceHighToLow" },
}

local HOSTS = { "https://catalog.roblox.com", "https://catalog.roproxy.com" }

-- tipe aset -> Category katalog web (dipakai jalur HTTP v1 sebagai cadangan)
local function httpCategoryFor(tid)
	if tid == 8 or (tid and tid >= 41 and tid <= 47) or tid == 76 or tid == 77 then
		return 11
	elseif tid == 11 or tid == 12 or tid == 2 or (tid and tid >= 64 and tid <= 72) then
		return 3
	elseif tid == 18 or tid == 17 or (tid and tid >= 27 and tid <= 31) then
		return 4
	elseif tid and (tid >= 48 and tid <= 55 or tid == 78) then
		return 12
	end
	return 1
end

local function fetchDetails(ids, itemType)
	local out = {}
	if #ids == 0 then
		return out
	end
	local ok, res = batchDetails(ids, itemType)
	if ok and type(res) == "table" then
		for _, d in ipairs(res) do
			out[d.Id] = d
		end
	end
	return out
end

local Query = {}
Query.__index = Query

local function newQuery(cat, keyword, sortIdx, freeOnly)
	local okP, params = pcall(function()
		return CatalogSearchParams.new()
	end)
	if not okP then
		params = nil
	end
	setProp(params, "SearchKeyword", keyword or "")
	local se = safeEnum(Enum.CatalogSortType, SORTS[sortIdx].enum)
	if se then
		setProp(params, "SortType", se)
	end
	local assetTypes, bundleTypes = {}, {}
	if cat.kind == "asset" then
		for _, n in ipairs(cat.list) do
			local e = safeEnum(Enum.AvatarAssetType, n)
			if e then
				table.insert(assetTypes, e)
			end
		end
	elseif cat.kind == "bundle" then
		for _, n in ipairs(cat.list) do
			local e = safeEnum(Enum.BundleType, n)
			if e then
				table.insert(bundleTypes, e)
			end
		end
	end
	setProp(params, "AssetTypes", assetTypes)
	setProp(params, "BundleTypes", bundleTypes)
	setProp(params, "IncludeOffSale", false)
	if freeOnly then
		setProp(params, "MaxPrice", 0)
	end
	setProp(params, "Limit", PAGE_SIZE)
	local tid = (cat.kind == "asset" and cat.list and #cat.list == 1) and NAME2TID[cat.list[1]] or nil
	return setmetatable({ params = params, finished = false, pages = nil, total = 0, tid = tid, cat = cat,
		keyword = keyword or "", sortNum = (sortIdx or 1) - 1, freeOnly = freeOnly }, Query)
end

function Query:aesPage()
	if self.finished then
		return {}
	end
	if not self.params then
		return nil, "CatalogSearchParams tidak tersedia di lingkungan ini"
	end
	local ok, res = pcall(function()
		if not self.pages then
			local okS, r = callAny(AvatarEditorService, { "SearchCatalogAsync", "SearchCatalog" }, self.params)
			if not okS then
				local p2 = CatalogSearchParams.new()
				setProp(p2, "SearchKeyword", getProp(self.params, "SearchKeyword") or "")
				setProp(p2, "AssetTypes", getProp(self.params, "AssetTypes") or {})
				setProp(p2, "BundleTypes", getProp(self.params, "BundleTypes") or {})
				local ok2, r2 = callAny(AvatarEditorService, { "SearchCatalogAsync", "SearchCatalog" }, p2)
				if not ok2 then
					error(tostring(r) .. " | ulang: " .. tostring(r2))
				end
				r = r2
			end
			self.pages = r
		else
			self.pages:AdvanceToNextPageAsync()
		end
		return self.pages:GetCurrentPage()
	end)
	if not ok then
		return nil, tostring(res)
	end
	if self.pages.IsFinished then
		self.finished = true
	end
	-- daftar langsung ditampilkan; nama & harga menyusul di latar belakang
	local assetIds, bundleIds, items, byId = {}, {}, {}, {}
	for _, it in ipairs(res) do
		local isBundle = it.ItemType == "Bundle" or it.ItemType == Enum.AvatarItemType.Bundle
		table.insert(isBundle and bundleIds or assetIds, it.Id)
		self.total = self.total + 1
		local nm = it.Name or ("Item #" .. it.Id)
		local row = { Id = it.Id, Type = isBundle and "Bundle" or "Asset", Name = nm, Price = false, Order = self.total }
		byId[(isBundle and "B" or "A") .. it.Id] = row
		table.insert(items, row)
		if not isBundle then
			E.names[it.Id] = E.names[it.Id] or nm
			if self.tid then
				E.types[it.Id] = self.tid
			end
		end
	end
	local function fill(ids, itemType, prefix)
		if #ids == 0 then
			return
		end
		task.spawn(function()
			local det = fetchDetails(ids, itemType)
			for id, d in pairs(det) do
				local row = byId[prefix .. id]
				if row then
					row.Name = d.Name or row.Name
					row.Price = d.PriceInRobux
					if prefix == "A" and d.Name then
						E.names[id] = d.Name
					end
					if row.onUpdate then
						pcall(row.onUpdate)
					end
				end
			end
			for _, id in ipairs(ids) do
				local row = byId[prefix .. id]
				if row and row.Price == false then
					row.Price = nil
					if row.onUpdate then
						pcall(row.onUpdate)
					end
				end
			end
		end)
	end
	fill(assetIds, Enum.AvatarItemType.Asset, "A")
	fill(bundleIds, Enum.AvatarItemType.Bundle, "B")
	return items
end

-- jalur web cadangan. Bundle memakai Category + Subcategory (37 = Bundles, 38 = AnimationBundles)
function Query:httpPage()
	local cat = self.cat
	local base = "&Limit=" .. PAGE_SIZE .. "&SortType=" .. tostring(self.sortNum or 0)
	if self.freeOnly then
		base = base .. "&MaxPrice=0"
	end
	if self.cursor then
		base = base .. "&cursor=" .. urlenc(self.cursor)
	end
	local function withKeyword(kw)
		if kw and kw ~= "" then
			return base .. "&Keyword=" .. urlenc(kw)
		end
		return base
	end
	local urls = {}
	for _, host in ipairs(HOSTS) do
		if cat.kind == "asset" and self.tid then
			local c = withKeyword(self.keyword)
			table.insert(urls, host .. "/v2/search/items/details?assetTypeIds=" .. self.tid .. c)
			table.insert(urls, host .. "/v1/search/items/details?Category=" .. httpCategoryFor(self.tid) .. c)
		else
			for _, v in ipairs(cat.httpVariants or { { 1, 37 } }) do
				local q = "Category=" .. tostring(v[1])
				if v[2] then
					q = q .. "&Subcategory=" .. tostring(v[2])
				end
				local kw = (self.keyword ~= "") and self.keyword or v[3]
				table.insert(urls, host .. "/v1/search/items/details?" .. q .. withKeyword(kw))
			end
		end
	end
	local a, b = 1, #urls
	if self.httpIdx then
		a, b = self.httpIdx, self.httpIdx
	end
	local lastErr = "tidak ada URL"
	for i = a, b do
		local body, herr = httpGet(urls[i])
		if body then
			local okJ, data = pcall(function()
				return HttpService:JSONDecode(body)
			end)
			if okJ and type(data) == "table" and type(data.data) == "table" then
				local items = {}
				for _, d in ipairs(data.data) do
					local at = tonumber(d.assetType)
					local isBundle = d.itemType == "Bundle"
					local keep
					if cat.kind == "bundle" then
						keep = isBundle
					else
						keep = (not isBundle) and (at == nil or self.tid == nil or at == self.tid)
					end
					if keep and tonumber(d.id) then
						self.total = self.total + 1
						local price = d.price
						if price == nil then
							price = d.lowestPrice
						end
						table.insert(items, {
							Id = tonumber(d.id), Type = isBundle and "Bundle" or "Asset", Name = tostring(d.name or ("Item #" .. d.id)),
							Price = price, Order = self.total,
						})
						if not isBundle then
							E.names[tonumber(d.id)] = E.names[tonumber(d.id)] or tostring(d.name)
							E.types[tonumber(d.id)] = at or self.tid or E.types[tonumber(d.id)]
						end
					end
				end
				if #items > 0 or data.nextPageCursor or self.total > 0 or i == b then
					self.httpIdx = i
					self.cursor = data.nextPageCursor
					if not self.cursor then
						self.finished = true
					end
					return items
				end
				lastErr = "hasil kosong dari " .. urls[i]
			else
				lastErr = "JSON tidak valid dari " .. urls[i]
			end
		else
			lastErr = tostring(herr)
		end
	end
	return nil, lastErr
end

function Query:nextPage()
	if self.finished then
		return {}
	end
	local errs = {}
	if self.backend ~= "http" then
		local items, err = self:aesPage()
		if items and not (#items == 0 and self.total == 0 and self.backend == nil) then
			self.backend = "aes"
			return items
		end
		if self.backend == "aes" then
			return nil, err
		end
		table.insert(errs, "AvatarEditorService: " .. tostring(err or "hasil kosong"))
		self.finished = false
	end
	local items2, err2 = self:httpPage()
	if items2 then
		self.backend = "http"
		return items2
	end
	table.insert(errs, "Web: " .. tostring(err2))
	return nil, table.concat(errs, "\n")
end

----------------------------------------------------------------------------
-- [7] TEMA + FILTER BACON / BACON CEWE + ANALISIS (jumlah item, cowo/cewe)
----------------------------------------------------------------------------
-- ===== PENGATURAN FILTER (ubah angka ini kalau mau lebih longgar / lebih ketat) =====
local FILTER_POLOSAN = true  -- true = sembunyikan avatar bawaan Roblox (bacon / bacon cewe / dll) dari tab avatar. false = tampilkan semua
local MIN_REAL_ITEMS = 4     -- avatar dengan item kurang dari ini SELALU dianggap bacon (tersembunyi)
local MIN_FOREIGN_ITEMS = 2  -- avatar asli minimal punya segini item BUKAN buatan Roblox (kalau kurang = bacon / bacon cewe)
local ROBLOX_ONLY_MAX = 16   -- avatar dengan item sebanyak ini atau kurang yang cuma pakai item Roblox = bacon. Di atas ini langsung dianggap asli
local MOST_MIN_ITEMS = 6     -- mode "Item terbanyak": hanya avatar dengan minimal segini item yang tampil
local GENDER_MIN_DIFF = 2    -- selisih skor minimal untuk memastikan cowo/cewe (makin besar = makin teliti, hasil makin sedikit)
local ROBLOX_CREATORS = { [1] = true, [1200769] = true } -- ID akun / grup resmi Roblox

local PREWARM_SKIN = true -- render boneka sekali di awal supaya klik pertama sudah cepat (set false kalau avatar terlihat berubah di awal)
local FEED_FIRST = 130    -- kartu avatar yang langsung muncul
local FEED_MORE = 60      -- tambahan tiap gulir
local FEED_CONC = 24      -- pengecekan avatar paralel
local FEED_KEEP = 160     -- jumlah kartu avatar minimal yang dijaga tetap terisi di latar belakang
local AV_SAVE_MAX = 400   -- maksimal avatar yang disimpan ke file config (supaya saat masuk lagi langsung tampil)
local AV_FILE = "avatar_studio_avatars.json"

local Theme = {
	Background = rgb(7, 10, 17), CardBg = rgb(14, 20, 32), CardBorder = rgb(34, 48, 73),
	Accent = rgb(0, 122, 255), TabActiveBg = rgb(18, 32, 54), TabActiveBorder = rgb(0, 122, 255),
	TextPrimary = rgb(245, 247, 255), TextMuted = rgb(130, 145, 175),
	WaGreen = rgb(37, 211, 102), WaDarkGreen = rgb(18, 38, 28),
}
local WA_CHANNEL_LINK = "https://whatsapp.com/channel/0029VbDq74VHgZWbi0AdSa1L"

-- samakan warna helper lama (button, label, toast, kartu) dengan tema baru
T.Bg = Theme.Background
T.Surface = Theme.CardBg
T.Surface2 = rgb(22, 32, 50)
T.Hover = rgb(30, 44, 70)
T.Stroke = Theme.CardBorder
T.Text = Theme.TextPrimary
T.Dim = Theme.TextMuted
T.Accent = Theme.Accent

-- cache info item: nama (huruf kecil) + apakah buatan Roblox. Item default berulang, jadi cache menghemat banyak request
local itemInfo = {}
local itemMiss = {}
local plainCache = {}
local analysisCache = {}

local PLAIN_PROPS = {
	"Shirt", "Pants", "GraphicTShirt", "ClimbAnimation", "FallAnimation", "IdleAnimation",
	"JumpAnimation", "RunAnimation", "SwimAnimation", "WalkAnimation", "MoodAnimation",
}

local function robloxMade(creatorId, creatorName)
	local cid = tonumber(creatorId)
	if cid and ROBLOX_CREATORS[cid] then
		return true
	end
	return tostring(creatorName or "") == "Roblox"
end

-- nama dinormalkan: "bow tie" & "tie dye" dibuang supaya tidak salah dikira kata gender
local function normName(name)
	local s = string.lower(tostring(name or ""))
	s = s:gsub("bow%s*tie", " "):gsub("tie%s*%-?%s*dye", " ")
	return s
end

local function storeInfo(id, name, creatorId, creatorName)
	itemInfo[id] = { name = normName(name), roblox = robloxMade(creatorId, creatorName) }
end

-- isi itemInfo untuk semua id. Coba batch 2x, lalu cadangan GetProductInfo per item. return true kalau SEMUA id terisi
local function ensureDetails(ids)
	local function missing()
		local need, now = {}, os.clock()
		for _, id in ipairs(ids) do
			if itemInfo[id] == nil and (now - (itemMiss[id] or -100)) > 15 then
				table.insert(need, id)
			end
		end
		return need
	end
	for attempt = 1, 2 do
		local need = missing()
		if #need == 0 then
			break
		end
		for i = 1, #need, 50 do
			local chunk = {}
			for j = i, math.min(i + 49, #need) do
				table.insert(chunk, need[j])
			end
			local det = fetchDetails(chunk, Enum.AvatarItemType.Asset)
			for _, id in ipairs(chunk) do
				local dd = det[id]
				if dd then
					storeInfo(id, dd.Name, dd.CreatorTargetId, dd.CreatorName)
				end
			end
		end
		if attempt == 1 and #missing() > 0 then
			task.wait(0.4)
		end
	end
	local need = missing()
	for k, id in ipairs(need) do
		if k > 16 then
			break
		end
		local info = productInfo(id, Enum.InfoType.Asset)
		if info then
			local c = info.Creator or {}
			storeInfo(id, info.Name, c.Id or c.TargetId, c.Name)
		else
			itemMiss[id] = os.clock()
		end
	end
	for _, id in ipairs(ids) do
		if itemInfo[id] == nil then
			return false
		end
	end
	return true
end

-- hitung item pada avatar (aksesori + baju/celana/animasi), tentukan bacon / bacon cewe atau avatar asli.
-- Bagian tubuh klasik (kepala, badan, tangan, kaki, wajah) tidak dihitung, karena itu bawaan semua akun.
-- Aturan (semua harus lolos agar dianggap AVATAR ASLI):
--   1) item >= MIN_REAL_ITEMS
--   2) item > ROBLOX_ONLY_MAX  ATAU  minimal MIN_FOREIGN_ITEMS item buatan selain Roblox
-- Kalau info item gagal dimuat dan belum terbukti asli -> dianggap bacon + ditandai unsure (disembunyikan, aman).
local function analyzeDesc(desc)
	local ids, types, seen = {}, {}, {}
	local okA, accs = pcall(function()
		return desc:GetAccessories(true)
	end)
	if okA then
		for _, a in ipairs(accs) do
			if not seen[a.AssetId] then
				seen[a.AssetId] = true
				table.insert(ids, a.AssetId)
				types[a.AssetId] = a.AccessoryType.Name
			end
		end
	end
	for _, prop in ipairs(PLAIN_PROPS) do
		local v = getProp(desc, prop)
		if type(v) == "number" and v > 0 and not seen[v] then
			seen[v] = true
			table.insert(ids, v)
		end
	end
	local count = #ids
	local a = { count = count, ids = ids, types = types, plain = false, unsure = false, foreign = 0 }
	if count < MIN_REAL_ITEMS then
		a.plain = true
		return a
	end
	if count > ROBLOX_ONLY_MAX then
		a.foreign = count
		return a
	end
	local complete = ensureDetails(ids)
	local foreign = 0
	for _, id in ipairs(ids) do
		local inf = itemInfo[id]
		if inf and not inf.roblox then
			foreign = foreign + 1
		end
	end
	a.foreign = foreign
	if foreign >= MIN_FOREIGN_ITEMS then
		a.plain = false
	elseif complete then
		a.plain = true
	else
		a.plain = true
		a.unsure = true
	end
	return a
end

----------------------------------------------------------------------------
-- DETEKSI COWO / CEWE (sistem skor)
-- Roblox tidak menyimpan gender akun, jadi dinilai dari NAMA item + tipe aksesori.
-- {kata, bobot}: bobot 2 = petunjuk kuat, 1 = petunjuk lemah. Skor per item dibatasi maks 3.
-- Kalau selisih skor < GENDER_MIN_DIFF -> avatar dianggap "tidak jelas" dan TIDAK muncul di filter Cowo / Cewe.
----------------------------------------------------------------------------
local FEMALE_WORDS = {
	{ "girl", 2 }, { "female", 2 }, { "woman", 2 }, { "women", 2 }, { "lady", 2 }, { "dress", 2 }, { "skirt", 2 },
	{ "miniskirt", 2 }, { "sundress", 2 }, { "bikini", 2 }, { "ponytail", 2 }, { "pigtail", 2 }, { "twintail", 2 },
	{ "twin tail", 2 }, { "heel", 2 }, { "lipstick", 2 }, { "makeup", 2 }, { "princess", 2 }, { "braid", 2 },
	{ "blouse", 2 }, { "kawaii", 2 }, { "gyaru", 2 }, { "cewek", 2 }, { "wanita", 2 }, { "maid", 2 }, { "hime", 2 },
	{ "mermaid", 2 }, { "fairy", 2 }, { "queen", 2 }, { "bride", 2 }, { "lolita", 2 }, { "bra", 2 }, { "stocking", 2 },
	{ "tutu", 2 }, { "gown", 2 }, { "crop top", 2 }, { "corset", 2 }, { "babydoll", 2 }, { "waifu", 2 },
	{ "bunny", 1 }, { "legging", 1 }, { "lash", 1 }, { "eyelash", 1 }, { "bangs", 1 }, { "bun", 1 }, { "bob", 1 },
	{ "ribbon", 1 }, { "bow", 1 }, { "pink", 1 }, { "cute", 1 }, { "heart", 1 }, { "kitty", 1 }, { "pastel", 1 },
	{ "sparkle", 1 }, { "glitter", 1 }, { "floral", 1 }, { "flower", 1 }, { "angel", 1 }, { "idol", 1 },
}
local MALE_WORDS = {
	{ "boy", 2 }, { "male", 2 }, { "man", 2 }, { "men", 2 }, { "guy", 2 }, { "beard", 2 }, { "mustache", 2 },
	{ "moustache", 2 }, { "stubble", 2 }, { "dude", 2 }, { "gentleman", 2 }, { "king", 2 }, { "cowok", 2 },
	{ "pria", 2 }, { "goatee", 2 }, { "sideburn", 2 }, { "buzz cut", 2 }, { "crew cut", 2 }, { "undercut", 2 },
	{ "mohawk", 2 }, { "pompadour", 2 }, { "tuxedo", 2 },
	{ "bro", 1 }, { "suit", 1 }, { "necktie", 1 }, { "tie", 1 }, { "hoodie", 1 }, { "beanie", 1 }, { "cap", 1 },
	{ "snapback", 1 }, { "jeans", 1 }, { "jersey", 1 }, { "tracksuit", 1 }, { "muscle", 1 }, { "bandana", 1 },
	{ "skater", 1 }, { "streetwear", 1 }, { "sneaker", 1 }, { "bald", 1 }, { "spiky", 1 }, { "slick", 1 },
}

local function scoreWords(name, list)
	local s = 0
	for _, w in ipairs(list) do
		if string.find(name, "%f[%a]" .. w[1] .. "e?s?%f[%A]") then
			s = s + w[2]
		end
	end
	return s
end

-- return "cewe" / "cowo" / nil (tidak jelas)
local function genderOf(a)
	ensureDetails(a.ids)
	local f, m = 0, 0
	for _, id in ipairs(a.ids) do
		local inf = itemInfo[id]
		local fi, mi = 0, 0
		if inf then
			fi = scoreWords(inf.name, FEMALE_WORDS)
			mi = scoreWords(inf.name, MALE_WORDS)
		end
		local t = a.types[id]
		if t == "DressSkirt" then
			fi = fi + 3
		elseif t == "Eyelash" then
			fi = fi + 1
		end
		f = f + math.min(fi, 3)
		m = m + math.min(mi, 3)
	end
	if f - m >= GENDER_MIN_DIFF then
		return "cewe"
	end
	if m - f >= GENDER_MIN_DIFF then
		return "cowo"
	end
	return nil
end

-- return: polosan (bacon / bacon cewe)?, sudah-pasti?
local function isPlainAvatar(userId)
	if not FILTER_POLOSAN then
		return false, true
	end
	if plainCache[userId] ~= nil then
		return plainCache[userId], true
	end
	local desc = descFromUser(userId)
	if not desc then
		return false, false
	end
	local a = analyzeDesc(desc)
	pcall(function()
		desc:Destroy()
	end)
	if a.unsure then
		return true, false
	end
	plainCache[userId] = a.plain
	analysisCache[userId] = a
	return a.plain, true
end

----------------------------------------------------------------------------
-- [7b] FAVORIT + CONFIG AVATAR (tersimpan ke file kalau executor punya writefile)
----------------------------------------------------------------------------
local FAV_FILE = "avatar_studio_fav.json"
local FAV = { avatars = {}, items = {}, listeners = {} }

local function favSave()
	if type(writefile) ~= "function" then
		return
	end
	pcall(function()
		writefile(FAV_FILE, HttpService:JSONEncode({ avatars = FAV.avatars, items = FAV.items }))
	end)
end
pcall(function()
	if type(readfile) == "function" and type(isfile) == "function" and isfile(FAV_FILE) then
		local d = HttpService:JSONDecode(readfile(FAV_FILE))
		if type(d) == "table" then
			FAV.avatars = type(d.avatars) == "table" and d.avatars or {}
			FAV.items = type(d.items) == "table" and d.items or {}
		end
	end
end)

function FAV.listen(fn)
	table.insert(FAV.listeners, fn)
end
function FAV.fire()
	local i = 1
	while i <= #FAV.listeners do
		local ok, keep = pcall(FAV.listeners[i])
		if ok and keep == false then
			table.remove(FAV.listeners, i)
		else
			i = i + 1
		end
	end
end
function FAV.itemKey(item)
	return (item.Type == "Bundle" and "B" or "A") .. tostring(item.Id) .. ":" .. tostring(item.slot or 0)
end
function FAV.toggleAvatar(id, name)
	local k = tostring(id)
	if FAV.avatars[k] then
		FAV.avatars[k] = nil
	else
		FAV.avatars[k] = { id = id, name = tostring(name), t = os.time() }
	end
	favSave()
	FAV.fire()
end
function FAV.toggleItem(item)
	local k = FAV.itemKey(item)
	if FAV.items[k] then
		FAV.items[k] = nil
	else
		FAV.items[k] = {
			Id = item.Id, Type = item.Type, Name = item.Name, slot = item.slot, slotName = item.slotName,
			tid = item.Type == "Asset" and E.types[item.Id] or nil, t = os.time(),
		}
	end
	favSave()
	FAV.fire()
end

-- config daftar avatar: daftar kartu di tab avatar disimpan, saat masuk lagi langsung muncul & lanjut memuat
local function avLoad()
	local out = {}
	pcall(function()
		if type(readfile) == "function" and type(isfile) == "function" and isfile(AV_FILE) then
			local d = HttpService:JSONDecode(readfile(AV_FILE))
			if type(d) == "table" and type(d.list) == "table" then
				out = d.list
			end
		end
	end)
	return out
end
local function avSave(list)
	if type(writefile) ~= "function" then
		return
	end
	pcall(function()
		writefile(AV_FILE, HttpService:JSONEncode({ v = 1, list = list }))
	end)
end

local function addHeart(card, isFav, onToggle)
	local h = mk("TextButton", {
		Size = UDim2.fromOffset(20, 20), Position = UDim2.fromOffset(4, 4), BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45, BorderSizePixel = 0, Text = "♡", TextSize = 14, Font = Enum.Font.GothamBold,
		TextColor3 = T.Text, AutoButtonColor = false, ZIndex = 5, Parent = card,
	})
	corner(h, 10)
	local function paint()
		local f = isFav()
		h.Text = f and "♥" or "♡"
		h.TextColor3 = f and T.Danger or T.Text
	end
	paint()
	h.Activated:Connect(function()
		onToggle()
		paint()
	end)
	return paint
end

----------------------------------------------------------------------------
-- [8] KARTU KATALOG
----------------------------------------------------------------------------
local function makeCard(parent, item)
	local isBundle = item.Type == "Bundle"
	local card = mk("TextButton", {
		AutoButtonColor = false, Text = "", BackgroundColor3 = T.Surface, BorderSizePixel = 0,
		LayoutOrder = item.Order or 0, Parent = parent,
	})
	corner(card, 10)
	local st = stroke(card, T.Stroke, 1.5, 0.3)
	local img = mk("ImageLabel", {
		Size = UDim2.new(1, -8, 0, 64), Position = UDim2.fromOffset(4, 4), BackgroundColor3 = T.Surface2,
		BorderSizePixel = 0, ScaleType = Enum.ScaleType.Fit, Parent = card,
	})
	corner(img, 8)
	local nm = label(card, item.Name, 11, T.Text, Enum.Font.GothamBold)
	nm.Position = UDim2.fromOffset(5, 71)
	nm.Size = UDim2.new(1, -10, 0, 14)
	nm.TextTruncate = Enum.TextTruncate.AtEnd
	local pr = label(card, priceText(item.Price), 10, item.Price == 0 and T.Ok or T.Dim, Enum.Font.GothamMedium)
	pr.Position = UDim2.fromOffset(5, 88)
	pr.Size = UDim2.new(1, -10, 0, 12)
	item.onUpdate = function()
		if not card.Parent then
			return
		end
		nm.Text = item.Name
		pr.Text = priceText(item.Price)
		pr.TextColor3 = item.Price == 0 and T.Ok or T.Dim
	end
	local badge = mk("TextLabel", {
		Size = UDim2.fromOffset(18, 18), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 8),
		BackgroundColor3 = T.Ok, Text = "✓", TextColor3 = Color3.new(1, 1, 1), TextSize = 12, Font = Enum.Font.GothamBold,
		BorderSizePixel = 0, Visible = false, ZIndex = 3, Parent = card,
	})
	corner(badge, 9)
	local overlay = mk("TextLabel", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45,
		Text = "⏳", TextSize = 22, Visible = false, ZIndex = 6, Parent = card,
	})
	corner(overlay, 10)

	local obj = { card = card, item = item, loading = false, imgLoaded = false }
	function obj.loadImg()
		obj.imgLoaded = true
		img.Image = thumbURL(isBundle and "BundleThumbnail" or "Asset", item.Id, 150)
	end
	function obj.update(set)
		local worn = false
		if not isBundle then
			if set then
				worn = set[item.Id] == true
			else
				worn = E.isWorn(item.Id)
			end
		end
		badge.Text = "✓"
		badge.BackgroundColor3 = T.Ok
		badge.Visible = worn
		st.Color = worn and T.Ok or T.Stroke
		st.Transparency = worn and 0 or 0.3
	end
	obj.update()
	local paintHeart = addHeart(card, function() return FAV.items[FAV.itemKey(item)] ~= nil end, function() FAV.toggleItem(item) end)
	FAV.listen(function()
		if not card.Parent then
			return false
		end
		paintHeart()
	end)
	card.MouseEnter:Connect(function()
		tween(card, { BackgroundColor3 = T.Surface2 }, 0.12)
		if isBundle then
			E.prefetchBundle(item.Id)
		end
	end)
	card.MouseLeave:Connect(function() tween(card, { BackgroundColor3 = T.Surface }, 0.15) end)
	card.InputBegan:Connect(function(input)
		if isBundle and input.UserInputType == Enum.UserInputType.Touch then
			E.prefetchBundle(item.Id)
		end
	end)
	card.Activated:Connect(function()
		if isBundle then
			if obj.loading then
				return
			end
			obj.loading = true
			overlay.Visible = true
			E.loadingBundles = E.loadingBundles + 1
			task.spawn(E.equipBundle, item.Id, item.Name, function()
				overlay.Visible = false
				obj.loading = false
				E.loadingBundles = math.max(0, E.loadingBundles - 1)
			end, item.slot, item.slotName)
		else
			badge.Text = "⏳"
			badge.BackgroundColor3 = T.Warn
			badge.Visible = true
			E.pendingClicks = E.pendingClicks + 1
			task.spawn(E.toggleAsset, item.Id, item.Name, function()
				E.pendingClicks = math.max(0, E.pendingClicks - 1)
				obj.update()
			end)
		end
	end)
	return obj
end

-- satu halaman katalog untuk satu grup kategori (KARAKTER / TUBUH, ANIMASI, SEPATU)
local function buildCatalog(page, group)
	local cats = {}
	for _, c in ipairs(CATEGORIES) do
		if c.group == group then
			table.insert(cats, c)
		end
	end
	local st = { cat = cats[1], keyword = "", sortIdx = 1, freeOnly = false, token = 0 }
	local cards, loading, currentQuery = {}, false, nil

	-- baris kategori (chip, geser kiri-kanan)
	local chipBar = mk("ScrollingFrame", {
		Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.new(), ScrollingDirection = Enum.ScrollingDirection.X,
		Parent = page,
	})
	mk("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center, Parent = chipBar,
	})

	-- baris cari | urut | gratis | refresh
	local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, 32), BackgroundTransparency = 1, Parent = page })
	local sbFrame = mk("Frame", { Size = UDim2.new(1, -202, 1, 0), BackgroundColor3 = T.Surface, BorderSizePixel = 0, Parent = row })
	corner(sbFrame, 8)
	stroke(sbFrame, T.Stroke, 1)
	local sbBox = mk("TextBox", {
		Size = UDim2.new(1, -14, 1, 0), Position = UDim2.fromOffset(8, 0), BackgroundTransparency = 1, Text = "",
		PlaceholderText = "🔍 Cari (Enter)", PlaceholderColor3 = T.Dim, TextColor3 = T.Text, ClearTextOnFocus = false,
		TextSize = 12, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left, Parent = sbFrame,
	})
	local startQuery
	sbBox.FocusLost:Connect(function(enter)
		if enter then
			st.keyword = sbBox.Text
			startQuery()
		end
	end)
	local sortBtn = button(row, { text = "↕ " .. SORTS[1].name, size = UDim2.fromOffset(84, 30), anchor = Vector2.new(1, 0),
		position = UDim2.new(1, -110, 0, 0), textSize = 10,
		onClick = function()
			st.sortIdx = st.sortIdx % #SORTS + 1
			startQuery()
		end })
	local freeBtn = button(row, { text = "Gratis", size = UDim2.fromOffset(52, 30), anchor = Vector2.new(1, 0),
		position = UDim2.new(1, -52, 0, 0), textSize = 11,
		onClick = function()
			st.freeOnly = not st.freeOnly
			startQuery()
		end })
	button(row, { text = "Ulang", size = UDim2.fromOffset(46, 30), anchor = Vector2.new(1, 0), position = UDim2.new(1, 0, 0, 0),
		textSize = 11, onClick = function() startQuery() end })

	-- grid
	local grid = makeScroll(page, UDim2.new(1, 0, 1, -68), UDim2.fromOffset(0, 68))
	mk("UIGridLayout", {
		CellSize = UDim2.fromOffset(84, 110), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = grid,
	})
	pad(grid, 0, 2, 0, 10)
	local msg = mk("TextLabel", {
		Size = UDim2.new(1, -16, 0, 90), Position = UDim2.fromOffset(8, 90), BackgroundTransparency = 1, Text = "",
		TextColor3 = T.Dim, TextSize = 12, Font = Enum.Font.GothamMedium, TextWrapped = true, Visible = false,
		ZIndex = 5, Parent = page,
	})

	local function clearGrid()
		msg.Visible = false
		cards = {}
		for _, c in ipairs(grid:GetChildren()) do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		grid.CanvasPosition = Vector2.new(0, 0)
	end
	local function showMsg(text)
		msg.Text = text
		msg.Visible = true
	end

	local function loadPage(token)
		if loading or not currentQuery or currentQuery.finished then
			return
		end
		loading = true
		local q = currentQuery
		local target = q.total + MAX_ITEMS
		task.spawn(function()
			while token == st.token and not q.finished and q.total < target do
				local items, err = q:nextPage()
				if token ~= st.token then
					return
				end
				if not items then
					logf("katalog gagal: %s", tostring(err))
					if q.total == 0 then
						showMsg("⚠ Gagal memuat katalog:\n" .. tostring(err))
					end
					break
				end
				msg.Visible = false
				for i, it in ipairs(items) do
					it.slot = st.cat.slot
					it.slotName = st.cat.name
					table.insert(cards, makeCard(grid, it))
					if i % 30 == 0 then
						task.wait()
						if token ~= st.token then
							return
						end
					end
				end
				if q.total == 0 then
					showMsg("🔎 Tidak ada hasil. Coba kata kunci lain atau matikan filter Gratis.")
					break
				end
			end
			if token == st.token then
				loading = false
			end
		end)
	end

	-- gambar kartu dimuat hanya yang dekat layar (supaya 1000 item tetap ringan)
	local function refreshImages()
		local top = grid.AbsolutePosition.Y
		local h = grid.AbsoluteWindowSize.Y
		if h <= 0 then
			return
		end
		for _, c in ipairs(cards) do
			if not c.imgLoaded and c.card.AbsoluteSize.Y > 0 then
				local y = c.card.AbsolutePosition.Y
				if y + 120 > top - 600 and y < top + h + 600 then
					c.loadImg()
				end
			end
			if c.item.Type == "Bundle" and not c.pf and c.card.AbsoluteSize.Y > 0 then
				local y = c.card.AbsolutePosition.Y
				if y + 120 > top and y < top + h + 120 then
					c.pf = true
					E.prefetchBundle(c.item.Id)
				end
			end
		end
	end
	task.spawn(function()
		while not stale() and page.Parent do
			task.wait(0.15)
			if page.Visible then
				pcall(refreshImages)
			end
		end
	end)

	startQuery = function()
		st.token = st.token + 1
		local token = st.token
		loading = false
		clearGrid()
		sortBtn.Text = "↕ " .. SORTS[st.sortIdx].name
		local fc = st.freeOnly and T.Ok or T.Surface2
		freeBtn.BackgroundColor3 = fc
		freeBtn:SetAttribute("Base", fc)
		freeBtn.Text = (st.freeOnly and "✓ " or "") .. "Gratis"
		showMsg("⏳ Memuat...")
		currentQuery = newQuery(st.cat, st.keyword, st.sortIdx, st.freeOnly)
		loadPage(token)
	end

	grid:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		if grid.CanvasPosition.Y + grid.AbsoluteWindowSize.Y >= grid.AbsoluteCanvasSize.Y - 600 then
			loadPage(st.token)
		end
	end)

	local chipRefs = {}
	local function markChips()
		for id, c in pairs(chipRefs) do
			local active = id == st.cat.id
			c.BackgroundColor3 = active and Theme.TabActiveBg or T.Surface2
			c.TextColor3 = active and T.Accent or T.Text
		end
	end
	local function selectCat(cat)
		st.cat = cat
		st.keyword = ""
		sbBox.Text = ""
		markChips()
		startQuery()
	end
	for i, cat in ipairs(cats) do
		local c = mk("TextButton", {
			Size = UDim2.fromOffset(0, 24), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = T.Surface2,
			BorderSizePixel = 0, Text = cat.name, TextSize = 11, Font = Enum.Font.GothamBold, TextColor3 = T.Text,
			AutoButtonColor = false, LayoutOrder = i, Parent = chipBar,
		})
		corner(c, 8)
		pad(c, 10, 0, 10, 0)
		chipRefs[cat.id] = c
		c.Activated:Connect(function()
			selectCat(cat)
		end)
	end

	selectCat(cats[1])
	return function()
		local set = collect(E.look)
		for _, c in ipairs(cards) do
			c.update(set)
		end
	end
end

----------------------------------------------------------------------------
-- [9] KARTU PEMAIN + PENCARIAN (halaman AVATAR)
----------------------------------------------------------------------------
local PRESETS = { { "Roblox", 1 }, { "builderman", 156 }, { "Shedletsky", 261 }, { "Aku (asli)", player.UserId } }

-- apakah GUI benar-benar terlihat (semua induk Visible)
local function UI_SHOWN(g)
	while g and g:IsA("GuiObject") do
		if not g.Visible then
			return false
		end
		g = g.Parent
	end
	return g ~= nil
end

local function userCard(parent, userId, name, order, sub)
	local card = mk("TextButton", { BackgroundColor3 = T.Surface, BorderSizePixel = 0, AutoButtonColor = false, Text = "", LayoutOrder = order or 0, Parent = parent })
	corner(card, 10)
	local img = mk("ImageLabel", { Size = UDim2.fromOffset(54, 54), Position = UDim2.new(0.5, -27, 0, 5), BackgroundColor3 = T.Surface2,
		BorderSizePixel = 0, Parent = card })
	corner(img, 27)
	-- foto profil: ukuran kecil (cepat) + preload paralel + huruf pengganti selagi memuat
	local initial = mk("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		Text = string.upper(string.sub(tostring(name), 1, 1)), TextColor3 = T.Dim, TextSize = 20, Font = Enum.Font.GothamBold, Parent = img })
	img.Image = thumbURL("AvatarHeadShot", userId, 100)
	img:GetPropertyChangedSignal("IsLoaded"):Connect(function()
		if img.IsLoaded then
			initial.Visible = false
		end
	end)
	E.preloadImg(img)
	task.spawn(function()
		-- cadangan: kalau belum jadi, ulangi dengan ukuran lain
		local sizes = { 150, 60, 180, 100, 352 }
		local tries, lastSet = 0, os.clock()
		while img.Parent and not img.IsLoaded and tries < #sizes do
			task.wait(0.5)
			if img.Parent and not img.IsLoaded then
				if UI_SHOWN(img) then
					if os.clock() - lastSet > 2.5 then
						tries = tries + 1
						img.Image = thumbURL("AvatarHeadShot", userId, sizes[tries])
						lastSet = os.clock()
						E.preloadImg(img)
					end
				else
					lastSet = os.clock() -- tab tersembunyi: tunggu sampai terlihat
				end
			end
		end
		if img.IsLoaded then
			initial.Visible = false
		end
	end)
	local nm = label(card, name, 11, T.Text, Enum.Font.GothamBold, Enum.TextXAlignment.Center)
	nm.Position = UDim2.fromOffset(3, 61)
	nm.Size = UDim2.new(1, -6, 0, 14)
	nm.TextTruncate = Enum.TextTruncate.AtEnd
	local idleText = sub or "klik untuk pakai"
	local hint = label(card, idleText, 9, T.Dim, Enum.Font.Gotham, Enum.TextXAlignment.Center)
	hint.Position = UDim2.fromOffset(3, 76)
	hint.Size = UDim2.new(1, -6, 0, 12)
	hint.TextTruncate = Enum.TextTruncate.AtEnd
	hint.Name = "HintLbl"
	card:SetAttribute("Idle", idleText)

	local paintHeart = addHeart(card, function() return FAV.avatars[tostring(userId)] ~= nil end, function() FAV.toggleAvatar(userId, name) end)
	FAV.listen(function()
		if not card.Parent then
			return false
		end
		paintHeart()
	end)

	local hoverTok = 0
	card.MouseEnter:Connect(function()
		tween(card, { BackgroundColor3 = T.Surface2 }, 0.12)
		if userId ~= player.UserId then
			hoverTok = hoverTok + 1
			local t = hoverTok
			task.delay(0.05, function()
				if t == hoverTok then
					E.prefetchUser(userId)
				end
			end)
		end
	end)
	card.MouseLeave:Connect(function()
		hoverTok = hoverTok + 1
		tween(card, { BackgroundColor3 = T.Surface }, 0.15)
	end)
	card.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch and userId ~= player.UserId then
			E.prefetchUser(userId)
		end
	end)

	local busyCard = false
	card.Activated:Connect(function()
		if busyCard then
			return
		end
		busyCard = true
		local t0 = os.clock()
		task.spawn(function()
			while busyCard do
				hint.Text = string.format("memuat %.1f dtk", os.clock() - t0)
				task.wait(0.1)
			end
		end)
		task.spawn(function()
			local ok = true
			if userId == player.UserId then
				E.reset()
			else
				ok = E.applyUser(userId, name)
			end
			busyCard = false
			hint.Text = ok and string.format("✓ %.1f dtk", os.clock() - t0) or (card:GetAttribute("Idle") or idleText)
			task.delay(1.5, function()
				if card.Parent and not busyCard then
					hint.Text = card:GetAttribute("Idle") or idleText
				end
			end)
		end)
	end)
	return card
end

local function nameFromId(uid)
	local ok, n = callAny(Players, { "GetNameFromUserIdAsync" }, uid)
	if ok and type(n) == "string" then
		return n
	end
	return nil
end

local function idFromName(name)
	local ok, id = callAny(Players, { "GetUserIdFromNameAsync" }, name)
	if ok and type(id) == "number" and id > 0 then
		return id
	end
	return nil
end

local SESSION_ID = "avt-" .. tostring(os.time())
pcall(function()
	SESSION_ID = HttpService:GenerateGUID(false)
end)

local SEARCH_BUILDERS = {
	function(kw, cur)
		return "https://users.roblox.com/v1/users/search?keyword=" .. urlenc(kw) .. "&limit=25" .. (cur and ("&cursor=" .. urlenc(cur)) or "")
	end,
	function(kw, cur)
		return "https://users.roproxy.com/v1/users/search?keyword=" .. urlenc(kw) .. "&limit=25" .. (cur and ("&cursor=" .. urlenc(cur)) or "")
	end,
	function(kw, cur)
		return "https://apis.roblox.com/search-api/omni-search?searchQuery=" .. urlenc(kw) .. "&pageType=all&sessionId="
			.. urlenc(SESSION_ID) .. (cur and ("&pageToken=" .. urlenc(cur)) or "")
	end,
}

local function parseUserList(bodyTxt)
	local ok, data = pcall(function()
		return HttpService:JSONDecode(bodyTxt)
	end)
	if not ok or type(data) ~= "table" then
		return nil
	end
	local out = {}
	if type(data.data) == "table" then
		for _, u in ipairs(data.data) do
			if tonumber(u.id) then
				table.insert(out, { id = tonumber(u.id), name = tostring(u.name), display = tostring(u.displayName or u.name) })
			end
		end
		return out, data.nextPageCursor
	end
	if type(data.searchResults) == "table" then
		for _, grp in ipairs(data.searchResults) do
			if type(grp.contents) == "table" then
				for _, c in ipairs(grp.contents) do
					if (c.contentType == "User" or grp.contentGroupType == "User") and tonumber(c.contentId) then
						table.insert(out, {
							id = tonumber(c.contentId), name = tostring(c.username or c.contentId),
							display = tostring(c.displayName or c.username or c.contentId),
						})
					end
				end
			end
		end
		return out, data.nextPageToken
	end
	return nil
end

-- 3 backend diadu bersamaan untuk halaman pertama (yang tercepat dipakai); halaman berikutnya pakai backend yang sama
local function searchUsersWeb(keyword, state)
	state = state or {}
	if state.idx then
		local bodyTxt, err = httpGet(SEARCH_BUILDERS[state.idx](keyword, state.cursor))
		if bodyTxt then
			local list, nextCur = parseUserList(bodyTxt)
			if list then
				return list, { idx = state.idx, cursor = nextCur }
			end
			return nil, "balasan tidak dikenali"
		end
		return nil, tostring(err)
	end
	local result, left, lastErr = nil, #SEARCH_BUILDERS, "tidak ada hasil"
	for i = 1, #SEARCH_BUILDERS do
		task.spawn(function()
			local bodyTxt, err = httpGet(SEARCH_BUILDERS[i](keyword, nil))
			if bodyTxt then
				local list, nextCur = parseUserList(bodyTxt)
				if list and #list > 0 and not result then
					result = { list, { idx = i, cursor = nextCur } }
				elseif not list then
					lastErr = "balasan backend " .. i .. " tidak dikenali"
				end
			else
				lastErr = tostring(err)
			end
			left = left - 1
		end)
	end
	local t0 = os.clock()
	while not result and left > 0 and os.clock() - t0 < 10 do
		task.wait(0.03)
	end
	if result then
		return result[1], result[2]
	end
	return nil, lastErr
end

local function buildAvatars(page)
	local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Parent = page })
	local sbFrame = mk("Frame", { Size = UDim2.new(1, -120, 1, 0), BackgroundColor3 = T.Surface, BorderSizePixel = 0, Parent = row })
	corner(sbFrame, 8)
	stroke(sbFrame, T.Stroke, 1)
	local box = mk("TextBox", {
		Size = UDim2.new(1, -16, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1, Text = "",
		PlaceholderText = "🔍 Username / nama / UserId", PlaceholderColor3 = T.Dim, TextColor3 = T.Text,
		ClearTextOnFocus = false, TextSize = 12, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left,
		Parent = sbFrame,
	})
	local searchBtn = button(row, { text = "Cari", size = UDim2.fromOffset(60, 30), anchor = Vector2.new(1, 0),
		position = UDim2.new(1, -50, 0, 0), bg = T.Accent, textSize = 12 })
	local randBtn = button(row, { text = "Acak", size = UDim2.fromOffset(44, 30), anchor = Vector2.new(1, 0),
		position = UDim2.new(1, 0, 0, 0), textSize = 11 })

	local status = label(page, "", 10, T.Dim, Enum.Font.Gotham, Enum.TextXAlignment.Right)
	status.Position = UDim2.fromOffset(248, 34)
	status.Size = UDim2.new(1, -248, 0, 24)
	status.TextTruncate = Enum.TextTruncate.AtEnd
	local chipRow = mk("Frame", { Size = UDim2.new(0, 240, 0, 24), Position = UDim2.fromOffset(0, 34), BackgroundTransparency = 1, ZIndex = 2, Parent = page })
	mk("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = chipRow,
	})

	-- baris filter urutan (hanya untuk tab "Semua"): item terbanyak / cowo / cewe
	local sortMode = "most" -- "most" | "cowo" | "cewe"
	local entries, seqN = {}, 0
	local modeRow = mk("Frame", { Size = UDim2.new(1, 0, 0, 24), Position = UDim2.fromOffset(0, 62), BackgroundTransparency = 1, ZIndex = 2, Parent = page })
	mk("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = modeRow,
	})
	local modeChips = {}
	local MODE_DEFS = { { "most", "🏆 Item terbanyak" }, { "cowo", "♂ Cowo" }, { "cewe", "♀ Cewe" } }
	local function markModes()
		for k, c in pairs(modeChips) do
			local active = k == sortMode
			c.BackgroundColor3 = active and Theme.TabActiveBg or T.Surface2
			c.TextColor3 = active and T.Accent or T.Text
		end
	end
	for i, d in ipairs(MODE_DEFS) do
		local c = mk("TextButton", {
			Size = UDim2.fromOffset(0, 24), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = T.Surface2,
			BorderSizePixel = 0, Text = d[2], TextSize = 11, Font = Enum.Font.GothamBold, TextColor3 = T.Text,
			AutoButtonColor = false, LayoutOrder = i, Parent = modeRow,
		})
		corner(c, 8)
		pad(c, 10, 0, 10, 0)
		modeChips[d[1]] = c
	end
	markModes()

	local secs, chips = {}, {}
	local function makeSection(key)
		local sc = makeScroll(page, UDim2.new(1, 0, 1, -64), UDim2.fromOffset(0, 64))
		mk("UIGridLayout", {
			CellSize = UDim2.fromOffset(84, 96), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = sc,
		})
		pad(sc, 0, 2, 0, 10)
		sc.Visible = false
		secs[key] = sc
		return sc
	end
	local allSc = makeSection("all")
	allSc.Position = UDim2.fromOffset(0, 90)
	allSc.Size = UDim2.new(1, 0, 1, -90)
	local presetSc = makeSection("preset")
	local serverSc = makeSection("server")
	local friendSc = makeSection("friends")

	local refreshServer, loadFriends
	local function showSection(key)
		for k, sc in pairs(secs) do
			sc.Visible = k == key
		end
		for k, c in pairs(chips) do
			c.BackgroundColor3 = (k == key) and T.Accent or T.Surface2
		end
		status.Visible = key == "all"
		modeRow.Visible = key == "all"
		if key == "server" and refreshServer then
			refreshServer()
		elseif key == "friends" and loadFriends then
			loadFriends()
		end
	end
	local chipDefs = { { "all", "Semua" }, { "preset", "Preset" }, { "server", "Server" }, { "friends", "Teman" } }
	for i, d in ipairs(chipDefs) do
		local c = mk("TextButton", {
			Size = UDim2.fromOffset(58, 24), BackgroundColor3 = T.Surface2, BorderSizePixel = 0, Text = d[2], TextSize = 11,
			Font = Enum.Font.GothamBold, TextColor3 = T.Text, AutoButtonColor = false, LayoutOrder = i, Parent = chipRow,
		})
		corner(c, 8)
		chips[d[1]] = c
		c.Activated:Connect(function()
			showSection(d[1])
		end)
	end

	-- ===== SEMUA PEMAIN ROBLOX (bacon & bacon cewe disaring, urut item terbanyak) =====
	local token, loading, mode, searchState, keyword = 0, false, "feed", nil, ""
	local count, seen = 0, {}

	local function setStatus(t)
		status.Text = t
	end
	local function clearAll()
		for _, c in ipairs(allSc:GetChildren()) do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		allSc.CanvasPosition = Vector2.new(0, 0)
		count, seen = 0, {}
		entries, seqN = {}, 0
	end
	-- mode "most": hanya avatar dengan item >= MOST_MIN_ITEMS. mode cowo/cewe: hanya yang gendernya pasti cocok
	local function visibleFor(g, cnt, pending)
		if pending then
			return sortMode == "most"
		end
		if sortMode == "most" then
			return (cnt or 0) >= MOST_MIN_ITEMS
		end
		return g == sortMode
	end
	local function countVisible()
		local n = 0
		for _, e in pairs(entries) do
			if e.card and e.card.Parent and visibleFor(e.gender, e.count, e.pending) then
				n = n + 1
			end
		end
		return n
	end
	-- info (opsional): { count = jumlah item, gender = "cowo"/"cewe"/nil } -> dipakai untuk urutan + filter
	local function addUser(id, name, sub, front, info)
		if seen[id] then
			return false
		end
		seen[id] = true
		count = count + 1
		local ord = front and (-1000 + count) or count
		local e
		if info then
			seqN = seqN + 1
			e = { count = info.count or 0, gender = info.gender, seq = seqN, pending = info.pending, name = name }
			ord = -(e.count) * 100000 + e.seq
		end
		local card = userCard(allSc, id, name, ord, sub)
		if e then
			e.card = card
			entries[id] = e
			card.Visible = visibleFor(e.gender, e.count, e.pending)
		end
		return true
	end
	-- urutkan ulang kartu sesuai mode: terbanyak di atas, cowo/cewe hanya yang cocok
	local function applyMode()
		for _, e in pairs(entries) do
			if e.card and e.card.Parent then
				e.card.Visible = visibleFor(e.gender, e.count, e.pending)
				e.card.LayoutOrder = -(e.count) * 100000 + e.seq
			end
		end
		allSc.CanvasPosition = Vector2.new(0, 0)
	end

	-- hasil pencarian: tampilkan semua (tidak disaring, bacon / bacon cewe tetap muncul di sini)
	local function addAll(list, myToken)
		for _, u in ipairs(list) do
			if myToken ~= token then
				return
			end
			addUser(u.id, u.display, "@" .. u.name)
		end
	end

	local tried = {}

	-- ===== POOL KANDIDAT (jalur cepat) =====
	-- Dipakai duluan: teman akun ini, pemain di server, lalu teman-dari-teman avatar yang lolos filter.
	-- Hampir semuanya akun asli + nama sudah ada (tanpa tebak ID acak yang banyak kosong), jadi kartu muncul jauh lebih cepat.
	local pool, poolSeen, expanded, expanding = {}, {}, {}, 0
	local feedConc = 24

	local function poolPush(id, name)
		id = tonumber(id)
		if not id or poolSeen[id] or tried[id] or #pool > 1500 then
			return
		end
		poolSeen[id] = true
		pool[#pool + 1] = { id = id, name = tostring(name or "") }
	end
	local function poolPop()
		local n = #pool
		if n == 0 then
			return nil
		end
		local i = math.random(1, n)
		local v = pool[i]
		pool[i] = pool[n]
		pool[n] = nil
		return v
	end
	local function expandFriends(uid, force)
		if expanded[uid] or (not force and (expanding >= 6 or #pool > 600)) then
			return
		end
		expanded[uid] = true
		expanding = expanding + 1
		task.spawn(function()
			local ok, pages = pcall(function()
				return Players:GetFriendsAsync(uid)
			end)
			local n = 0
			while ok and pages and n < 3 do
				n = n + 1
				local okP, cur = pcall(function()
					return pages:GetCurrentPage()
				end)
				if okP and type(cur) == "table" then
					for _, f in ipairs(cur) do
						poolPush(f.Id, f.DisplayName or f.Username)
					end
				end
				if pages.IsFinished or not pcall(function() pages:AdvanceToNextPageAsync() end) then
					break
				end
			end
			expanding = expanding - 1
		end)
	end
	local function seedPool()
		local n = 0
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player then
				poolPush(p.UserId, p.DisplayName)
				if n < 6 then
					n = n + 1
					expandFriends(p.UserId, true)
				end
			end
		end
		expandFriends(player.UserId, true)
	end

	local function setSub(card, text)
		card:SetAttribute("Idle", text)
		local h = card:FindFirstChild("HintLbl")
		if h and h.Text ~= "memuat..." then
			h.Text = text
		end
	end
	local function genderSym(g)
		return (g == "cewe" and "♀") or (g == "cowo" and "♂") or "•"
	end

	-- deklarasi awal: dipakai feedBatchRandom, diisi di bagian pipeline di bawah
	local queueGender

	-- kartu langsung tampil begitu lolos filter bacon; gender dihitung menyusul di latar belakang (batch paralel)
	local function feedBatchRandom(myToken, n)
		loading = true
		setStatus("Memuat pemain Roblox...")
		local found, attempts, inflight, throttled = 0, 0, 0, 0
		local maxAttempts = n * 40
		while myToken == token and found < n and attempts < maxAttempts do
			if throttled >= 5 then
				setStatus("Roblox membatasi permintaan, menunggu...")
				feedConc = math.max(8, feedConc - 6)
				task.wait(2)
				throttled = 0
			end
			while myToken == token and inflight < feedConc and found < n and attempts < maxAttempts do
				attempts = attempts + 1
				inflight = inflight + 1
				task.spawn(function()
					local cand = (math.random() < 0.92) and poolPop() or nil
					local id = cand and cand.id or (math.floor(math.random() * 5000000000) + 100000)
					if not tried[id] then
						tried[id] = true
						-- cek avatar dulu (gagal cepat untuk akun tidak ada / bacon), nama hanya untuk yang lolos
						local desc, derr = descFromUser(id)
						if desc then
							local a = analyzeDesc(desc)
							local plain = FILTER_POLOSAN and a.plain or false
							if plain then
								pcall(function()
									desc:Destroy()
								end)
							else
								E.cacheDesc(id, desc)
							end
							if not a.unsure then
								plainCache[id] = plain
							end
							if not plain and myToken == token then
								expandFriends(id)
								local nm = (cand and cand.name ~= "" and cand.name) or nil
								if not nm then
									nm = nameFromId(id)
								end
								if nm and myToken == token then
									analysisCache[id] = a
									if addUser(id, nm, a.count .. " item •", nil, { count = a.count, gender = nil }) then
										found = found + 1
										local e = entries[id]
										if e then
											e.a = a
										end
										queueGender(id)
										setStatus(countVisible() .. " pemain • memuat...")
									end
								end
							end
						else
							local sErr = string.lower(tostring(derr))
							if sErr:find("429") or sErr:find("too many") or sErr:find("throttl") or sErr:find("limit") then
								throttled = throttled + 1
							end
						end
					end
					inflight = inflight - 1
				end)
			end
			task.wait(0.03)
		end
		local t0 = os.clock()
		while inflight > 0 and os.clock() - t0 < 1.5 and myToken == token do
			task.wait(0.05)
		end
		if myToken == token then
			loading = false
			local vis = countVisible()
			if found == 0 and vis == 0 then
				setStatus("Belum ketemu avatar yang cocok, tekan Acak / gulir")
			else
				setStatus(vis .. " pemain • gulir untuk lagi")
			end
		end
	end

	-- ===== PIPELINE CEPAT: kartu tampil dulu, dicek di latar belakang =====
	local aQueue, aWorkers = {}, 0
	local gQueue, gWorkers = {}, 0

	-- gender: 6 pekerja, tiap pekerja mengambil detail item banyak avatar sekaligus (1 panggilan batch)
	local function genderPump()
		while gWorkers < 6 and #gQueue > 0 do
			gWorkers = gWorkers + 1
			task.spawn(function()
				while #gQueue > 0 and not stale() do
					local batch, ids, idSeen = {}, {}, {}
					while #gQueue > 0 and #batch < 8 do
						local id = table.remove(gQueue, 1)
						local e = entries[id]
						if e and e.a and not e.gdone and e.card and e.card.Parent then
							e.gdone = true
							batch[#batch + 1] = id
							for _, iid in ipairs(e.a.ids) do
								if not idSeen[iid] and itemInfo[iid] == nil then
									idSeen[iid] = true
									ids[#ids + 1] = iid
								end
							end
						end
					end
					if #ids > 0 then
						pcall(ensureDetails, ids) -- 1 panggilan untuk banyak avatar
					end
					for _, id in ipairs(batch) do
						local e = entries[id]
						if e and e.card and e.card.Parent then
							e.gender = genderOf(e.a)
							e.a.gender = e.gender
							e.card.Visible = visibleFor(e.gender, e.count, e.pending)
							setSub(e.card, e.count .. " item " .. genderSym(e.gender))
						end
					end
				end
				gWorkers = gWorkers - 1
			end)
		end
	end
	queueGender = function(id)
		table.insert(gQueue, id)
		genderPump()
	end

	local function settleEntry(id, a)
		local e = entries[id]
		if not e or not e.card or not e.card.Parent then
			return
		end
		if FILTER_POLOSAN and a.plain then
			e.card:Destroy()
			entries[id] = nil
			return
		end
		e.pending, e.count, e.a = false, a.count, a
		if a.gender ~= nil then
			e.gender, e.gdone = a.gender, true
		end
		e.card.LayoutOrder = -(a.count) * 100000 + e.seq
		e.card.Visible = visibleFor(e.gender, e.count, false)
		setSub(e.card, a.count .. " item " .. genderSym(e.gender))
		expandFriends(id)
		if not e.gdone then
			queueGender(id)
		end
	end

	local function analyzeWorker(myToken)
		while myToken == token do
			local id = table.remove(aQueue, 1)
			if not id then
				break
			end
			local a = analysisCache[id]
			if not a then
				local desc, derr = descFromUser(id)
				if desc then
					a = analyzeDesc(desc)
					if not a.unsure then
						analysisCache[id] = a
						plainCache[id] = a.plain
					end
					if a.plain then
						pcall(function()
							desc:Destroy()
						end)
					else
						E.cacheDesc(id, desc) -- klik nanti tidak perlu download lagi
					end
				else
					local s = string.lower(tostring(derr))
					if s:find("429") or s:find("too many") or s:find("throttl") or s:find("limit") then
						table.insert(aQueue, id)
						feedConc = math.max(8, feedConc - 4)
						task.wait(1.5)
					else
						local e = entries[id]
						if e and e.card then
							e.card:Destroy()
						end
						entries[id] = nil
					end
				end
			end
			if a and myToken == token then
				settleEntry(id, a)
				setStatus(countVisible() .. " pemain • gulir untuk lagi")
			end
		end
		aWorkers = aWorkers - 1
	end
	local function pumpAnalysis(myToken)
		while aWorkers < feedConc and #aQueue > 0 do
			aWorkers = aWorkers + 1
			task.spawn(analyzeWorker, myToken)
		end
	end

	local function feedBatch(myToken, n)
		if myToken ~= token then
			return
		end
		local added, guard = 0, 0
		while added < n and #pool > 0 and guard < n * 4 do
			guard = guard + 1
			local c = poolPop()
			if c and not tried[c.id] then
				tried[c.id] = true
				local nm = (c.name ~= "" and c.name) or tostring(c.id)
				if addUser(c.id, nm, "memeriksa...", nil, { count = 0, pending = true }) then
					added = added + 1
					table.insert(aQueue, c.id)
					if added % 40 == 0 then
						pumpAnalysis(myToken)
						task.wait()
						if myToken ~= token then
							return
						end
					end
				end
			end
		end
		pumpAnalysis(myToken)
		if added == 0 and #pool == 0 and not loading then
			task.spawn(feedBatchRandom, myToken, 8)
		end
		setStatus(countVisible() .. " pemain • memeriksa...")
	end

	-- ===== CONFIG: pulihkan daftar avatar dari file (langsung tampil tanpa dicek ulang) =====
	local function restoreFeed(myToken)
		local list = avLoad()
		local n = 0
		for _, r in ipairs(list) do
			if myToken ~= token then
				return n
			end
			local id, cnt = tonumber(r.id), tonumber(r.count)
			if id and cnt and r.name and not seen[id] then
				tried[id] = true
				plainCache[id] = false
				if addUser(id, tostring(r.name), cnt .. " item " .. genderSym(r.gender), nil, { count = cnt, gender = r.gender }) then
					n = n + 1
					if n % 40 == 0 then
						task.wait()
					end
				end
			end
		end
		return n
	end

	local function startFeed(keep)
		token = token + 1
		local myToken = token
		clearAll()
		mode, searchState, keyword = "feed", nil, ""
		feedConc = FEED_CONC
		aQueue, gQueue = {}, {}
		showSection("all")
		local restoredN = 0
		if keep then
			restoredN = restoreFeed(myToken)
			if restoredN > 0 and myToken == token then
				setStatus(countVisible() .. " pemain (tersimpan) • memuat lagi...")
			end
		end
		seedPool()
		task.spawn(function()
			local t0 = os.clock()
			while myToken == token and restoredN == 0 and #pool < 20 and os.clock() - t0 < 1.5 do
				task.wait(0.05)
			end
			feedBatch(myToken, restoredN > 0 and 40 or FEED_FIRST)
			-- pengisi otomatis: jaga minimal FEED_KEEP kartu tampil dan terus berlanjut
			while myToken == token and mode == "feed" and not stale() do
				task.wait(0.3)
				if count < 900 and countVisible() < FEED_KEEP then
					if #pool > 0 then
						feedBatch(myToken, sortMode ~= "most" and 90 or 50)
					elseif not loading then
						task.spawn(feedBatchRandom, myToken, 8)
					end
				end
				if #pool < 60 then
					local n = 0
					for id in pairs(entries) do
						if n >= 3 then
							break
						end
						if not expanded[id] then
							expandFriends(id, true)
							n = n + 1
						end
					end
				end
			end
		end)
	end

	local function setSortMode(m)
		if sortMode == m then
			return
		end
		sortMode = m
		markModes()
		if m ~= "most" then
			for id, e in pairs(entries) do
				if e.a and not e.gdone then
					queueGender(id)
				end
			end
		end
		if mode == "feed" then
			applyMode()
			local vis = countVisible()
			setStatus(vis .. " pemain • gulir untuk lagi")
			if vis < 12 and not loading then
				task.spawn(feedBatch, token, 12)
			end
		else
			startFeed(true)
		end
	end
	for k, c in pairs(modeChips) do
		c.Activated:Connect(function()
			setSortMode(k)
		end)
	end

	local function doSearch()
		local kw = box.Text:match("^%s*(.-)%s*$")
		if kw == "" then
			startFeed(true)
			return
		end
		token = token + 1
		local myToken = token
		clearAll()
		mode, searchState, keyword, loading = "search", nil, kw, true
		showSection("all")
		setStatus("Mencari \"" .. kw .. "\"...")
		local jobs, errMsg = 2, nil
		local function jobDone()
			jobs = jobs - 1
			if jobs == 0 and myToken == token then
				loading = false
				if count > 0 then
					setStatus(count .. " pemain" .. ((searchState and searchState.cursor) and "+" or "") .. " hasil")
				else
					setStatus("⚠ " .. string.sub(tostring(errMsg or "tidak ada hasil"), 1, 60))
				end
			end
		end
		task.spawn(function() -- hasil persis (paralel)
			pcall(function()
				local exactId = tonumber(kw)
				local exactName
				if exactId then
					exactName = nameFromId(exactId)
				else
					exactId = idFromName(kw)
					if exactId then
						exactName = nameFromId(exactId) or kw
					end
				end
				if exactId and exactName and myToken == token then
					addUser(exactId, exactName, "ID " .. exactId, true) -- hasil persis tidak disaring
					E.prefetchUser(exactId)
				end
			end)
			jobDone()
		end)
		task.spawn(function() -- pencarian luas (paralel)
			local list, st = searchUsersWeb(kw, nil)
			if myToken == token then
				if list then
					searchState = st
					addAll(list, myToken)
					for i = 1, math.min(6, #list) do
						E.prefetchBg(list[i].id)
					end
				else
					errMsg = st
				end
			end
			jobDone()
		end)
	end

	local function loadMore()
		if loading then
			return
		end
		local myToken = token
		if mode == "feed" then
			task.spawn(feedBatch, myToken, FEED_MORE)
		elseif mode == "search" and searchState and searchState.cursor then
			loading = true
			task.spawn(function()
				local list, st = searchUsersWeb(keyword, searchState)
				if myToken ~= token then
					return
				end
				if list then
					searchState = st
					addAll(list, myToken)
					if myToken ~= token then
						return
					end
					setStatus(count .. " pemain" .. (st.cursor and "+" or "") .. " hasil")
				else
					searchState = nil
				end
				loading = false
			end)
		end
	end

	allSc:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		if allSc.Visible and allSc.CanvasPosition.Y + allSc.AbsoluteWindowSize.Y >= allSc.AbsoluteCanvasSize.Y - 120 then
			loadMore()
		end
	end)
	searchBtn.Activated:Connect(doSearch)
	box.FocusLost:Connect(function(enter)
		if enter then
			doSearch()
		end
	end)
	randBtn.Activated:Connect(function()
		box.Text = ""
		startFeed(false)
	end)

	-- ===== PRESET =====
	for i, p in ipairs(PRESETS) do
		userCard(presetSc, p[2], p[1], i, p[2] == player.UserId and "avatar asli" or nil)
	end

	-- ===== DAFTAR SERVER & TEMAN: dimuat sejak awal, kartu langsung tampil =====
	local listCards = { server = {}, friends = {} }
	local listCount = { server = 0, friends = 0 }
	local listSc = { server = serverSc, friends = friendSc }
	local listInfo = {}
	local listState = { server = "", friends = "Memuat teman..." }
	local listSeq = 0

	local function syncInfo(key)
		local lbl = listInfo[key]
		if not lbl then
			return
		end
		lbl.Text = listState[key]
		lbl.Visible = listSc[key].Visible and listCount[key] == 0 and listState[key] ~= ""
	end
	for key, sc in pairs(listSc) do
		listInfo[key] = mk("TextLabel", {
			Size = UDim2.new(1, -16, 0, 30), Position = UDim2.fromOffset(8, 72), BackgroundTransparency = 1, Text = "",
			TextColor3 = T.Dim, TextSize = 12, Font = Enum.Font.GothamMedium, TextWrapped = true, Visible = false,
			ZIndex = 5, Parent = page,
		})
		sc:GetPropertyChangedSignal("Visible"):Connect(function()
			syncInfo(key)
		end)
	end

	-- pemeriksa bacon di latar belakang (server didahulukan, paralel, hasil dicache)
	local checkQ, checkWorkers = {}, 0
	local function dropCard(key, id)
		local c = listCards[key][id]
		if c then
			listCards[key][id] = nil
			listCount[key] = listCount[key] - 1
			if c.Parent then
				c:Destroy()
			end
			syncInfo(key)
		end
	end
	local function checkWorker()
		while #checkQ > 0 and not stale() do
			local job = table.remove(checkQ, 1)
			local key, id = job[1], job[2]
			if listCards[key][id] then
				local plain
				if plainCache[id] ~= nil then
					plain = plainCache[id]
				else
					local desc, derr = descFromUser(id)
					if desc then
						local a = analyzeDesc(desc)
						if not a.unsure then
							plainCache[id] = a.plain
							analysisCache[id] = a
						end
						plain = a.plain and not a.unsure -- info gagal dimuat -> jangan disembunyikan
						if plain then
							pcall(function()
								desc:Destroy()
							end)
						else
							E.cacheDesc(id, desc)
						end
					else
						local se = string.lower(tostring(derr))
						if se:find("429") or se:find("too many") or se:find("throttl") or se:find("limit") then
							table.insert(checkQ, job)
							task.wait(1.5)
						end
					end
				end
				if plain then
					dropCard(key, id)
				end
			end
		end
		checkWorkers = checkWorkers - 1
	end
	local function queueCheck(key, id)
		if not FILTER_POLOSAN then
			return
		end
		local job = { key, id }
		if key == "server" then
			table.insert(checkQ, 1, job)
		else
			table.insert(checkQ, job)
		end
		while checkWorkers < 20 and #checkQ > 0 do
			checkWorkers = checkWorkers + 1
			task.spawn(checkWorker)
		end
	end

	local function listAdd(key, id, name)
		if listCards[key][id] then
			return
		end
		listSeq = listSeq + 1
		listCards[key][id] = userCard(listSc[key], id, name, listSeq)
		listCount[key] = listCount[key] + 1
		syncInfo(key)
		queueCheck(key, id)
	end

	-- ===== PEMAIN DI SERVER (live: ikut berubah saat ada yang masuk / keluar) =====
	listState.server = "Tidak ada pemain lain di server ini."
	local function addServerPlayer(p)
		if p ~= player and not stale() then
			listAdd("server", p.UserId, p.DisplayName)
		end
	end
	for _, p in ipairs(Players:GetPlayers()) do
		addServerPlayer(p)
	end
	Players.PlayerAdded:Connect(addServerPlayer)
	Players.PlayerRemoving:Connect(function(p)
		if not stale() then
			dropCard("server", p.UserId)
		end
	end)
	refreshServer = function()
		syncInfo("server")
	end

	-- ===== TEMAN (dimuat di latar belakang sejak script jalan, bukan saat tab dibuka) =====
	loadFriends = function()
		syncInfo("friends")
	end
	task.spawn(function()
		local ok, pages = pcall(function()
			return Players:GetFriendsAsync(player.UserId)
		end)
		if not ok or not pages then
			listState.friends = "Daftar teman tidak bisa dimuat."
			syncInfo("friends")
			return
		end
		local n = 0
		while not stale() and n < 4 do
			n = n + 1
			local okP, cur = pcall(function()
				return pages:GetCurrentPage()
			end)
			if okP and type(cur) == "table" then
				for i, f in ipairs(cur) do
					listAdd("friends", f.Id, f.DisplayName or f.Username)
					if i % 40 == 0 then
						task.wait()
					end
				end
			end
			if pages.IsFinished or not pcall(function() pages:AdvanceToNextPageAsync() end) then
				break
			end
		end
		listState.friends = "Belum ada teman di akun ini."
		syncInfo("friends")
	end)

	-- ===== CONFIG: simpan daftar avatar ke file secara berkala (hanya saat mode feed, bukan hasil pencarian) =====
	local savedSig = ""
	task.spawn(function()
		while not stale() and page.Parent do
			task.wait(5)
			if mode == "feed" then
				local list, g = {}, 0
				for id, e in pairs(entries) do
					if e.card and e.card.Parent and not e.pending and (e.count or 0) > 0 and e.name then
						list[#list + 1] = { id = id, name = e.name, count = e.count, gender = e.gender, seq = e.seq }
						if e.gender then
							g = g + 1
						end
					end
				end
				local sig = #list .. ":" .. g
				if #list >= 5 and sig ~= savedSig then
					savedSig = sig
					table.sort(list, function(a, b)
						if a.count ~= b.count then
							return a.count > b.count
						end
						return a.seq < b.seq
					end)
					while #list > AV_SAVE_MAX do
						list[#list] = nil
					end
					for _, r in ipairs(list) do
						r.seq = nil
					end
					avSave(list)
				end
			end
		end
	end)

	-- ===== PREFETCH: 8 avatar paling atas yang terlihat disiapkan lebih dulu, jadi klik langsung terpasang =====
	task.spawn(function()
		while not stale() and page.Parent do
			task.wait(1)
			if not E.remote and UI_SHOWN(allSc) then
				local top = allSc.AbsolutePosition.Y
				local h = allSc.AbsoluteWindowSize.Y
				local vis = {}
				for id, e in pairs(entries) do
					local c = e.card
					if c and c.Parent and c.Visible and not e.pending then
						local pos = c.AbsolutePosition
						if pos.Y >= top - 20 and pos.Y < top + h then
							vis[#vis + 1] = { id = id, y = pos.Y, x = pos.X }
						end
					end
				end
				table.sort(vis, function(a, b)
					if math.abs(a.y - b.y) > 5 then
						return a.y < b.y
					end
					return a.x < b.x
				end)
				for i = 1, math.min(8, #vis) do
					E.prefetchBg(vis[i].id)
				end
			end
		end
	end)

	startFeed(true)
end

----------------------------------------------------------------------------
-- [10] HALAMAN SEDANG DI PAKAI (nama item diambil sekaligus, baris dipakai ulang = cepat)
----------------------------------------------------------------------------
-- isi nama banyak item sekaligus (batch paralel, cadangan GetProductInfo)
function E.fillNames(ids)
	local need = {}
	for _, id in ipairs(ids) do
		if not E.names[id] then
			need[#need + 1] = id
		end
	end
	if #need == 0 then
		return
	end
	local left = 0
	for i = 1, #need, 50 do
		left = left + 1
		local chunk = table.move(need, i, math.min(i + 49, #need), 1, {})
		task.spawn(function()
			local det = fetchDetails(chunk, Enum.AvatarItemType.Asset)
			for id, d in pairs(det) do
				if d.Name then
					E.names[id] = d.Name
				end
			end
			left = left - 1
		end)
	end
	local t0 = os.clock()
	while left > 0 and os.clock() - t0 < 8 do
		task.wait()
	end
	local rest = {}
	for _, id in ipairs(need) do
		if not E.names[id] then
			rest[#rest + 1] = id
		end
	end
	local left2 = math.min(#rest, 12)
	for k = 1, left2 do
		local id = rest[k]
		task.spawn(function()
			local info = productInfo(id, Enum.InfoType.Asset)
			if info then
				E.names[id] = info.Name
				E.types[id] = E.types[id] or info.AssetTypeId
			end
			left2 = left2 - 1
		end)
	end
	t0 = os.clock()
	while left2 > 0 and os.clock() - t0 < 6 do
		task.wait()
	end
end

local function buildWorn(page)
	local head = mk("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, Parent = page })
	label(head, "Sedang dipakai", 15, T.Text, Enum.Font.GothamBold).Size = UDim2.new(0.5, 0, 0, 22)
	local sub = label(head, "", 11, T.Dim, Enum.Font.Gotham)
	sub.Position = UDim2.fromOffset(0, 20)
	sub.Size = UDim2.new(0.5, 0, 0, 14)
	button(head, { text = "Lepas semua", size = UDim2.fromOffset(96, 28), anchor = Vector2.new(1, 0),
		position = UDim2.new(1, 0, 0, 2), bg = T.Danger, textSize = 12,
		onClick = function() task.spawn(E.removeAll) end })
	button(head, { text = "Reset", size = UDim2.fromOffset(72, 28), anchor = Vector2.new(1, 0),
		position = UDim2.new(1, -102, 0, 2), textSize = 12, onClick = function() task.spawn(E.reset) end })

	local list = makeScroll(page, UDim2.new(1, 0, 1, -42), UDim2.fromOffset(0, 42))
	vlist(list, 6)
	pad(list, 0, 0, 8, 10)

	local rows = {}

	local function makeRow(e)
		local r = mk("Frame", { Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = T.Surface, BorderSizePixel = 0, Parent = list })
		corner(r, 10)
		local img = mk("ImageLabel", { Size = UDim2.fromOffset(36, 36), Position = UDim2.fromOffset(6, 6), BackgroundColor3 = T.Surface2,
			BorderSizePixel = 0, Image = thumbURL("Asset", e.Id, 150), Parent = r })
		corner(img, 8)
		local nameL = label(r, E.names[e.Id] or "Memuat nama...", 12, T.Text, Enum.Font.GothamBold)
		nameL.Position = UDim2.fromOffset(50, 6)
		nameL.Size = UDim2.new(1, -124, 0, 18)
		nameL.TextTruncate = Enum.TextTruncate.AtEnd
		local typeL = label(r, e.Label, 10, T.Dim, Enum.Font.Gotham)
		typeL.Position = UDim2.fromOffset(50, 26)
		typeL.Size = UDim2.new(1, -124, 0, 14)
		button(r, { text = "Lepas", size = UDim2.fromOffset(60, 28), anchor = Vector2.new(1, 0.5), position = UDim2.new(1, -8, 0.5, 0),
			textSize = 12, onClick = function() task.spawn(E.removeAsset, e.Id) end })
		return { frame = r, nameL = nameL, typeL = typeL }
	end

	local function refresh()
		local items = E.wornList()
		sub.Text = #items .. " item aktif pada karakter"
		local want = {}
		for _, e in ipairs(items) do
			want[e.Id] = true
		end
		for id, r in pairs(rows) do
			if not want[id] then
				r.frame:Destroy()
				rows[id] = nil
			end
		end
		local need = {}
		for n, e in ipairs(items) do
			local r = rows[e.Id]
			if not r then
				r = makeRow(e)
				rows[e.Id] = r
			end
			r.frame.LayoutOrder = n
			r.typeL.Text = e.Label .. (E.failed[e.Id] and "  •  injector" or "")
			if E.names[e.Id] then
				r.nameL.Text = E.names[e.Id]
			else
				need[#need + 1] = e.Id
			end
		end
		if #need > 0 then
			task.spawn(function()
				E.fillNames(need)
				for _, id in ipairs(need) do
					local r = rows[id]
					if r and r.frame.Parent then
						r.nameL.Text = E.names[id] or ("Item #" .. id)
					end
				end
			end)
		end
	end
	refresh()
	return refresh
end

----------------------------------------------------------------------------
-- [10b] HALAMAN FAVORIT
----------------------------------------------------------------------------
local function buildFavorites(page)
	local chipRow = mk("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Parent = page })
	mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = chipRow })
	local function newGrid(cell)
		local sc = makeScroll(page, UDim2.new(1, 0, 1, -30), UDim2.fromOffset(0, 30))
		mk("UIGridLayout", { CellSize = cell, CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = sc })
		pad(sc, 0, 2, 0, 10)
		return sc
	end
	local avSc, itSc = newGrid(UDim2.fromOffset(84, 96)), newGrid(UDim2.fromOffset(84, 110))
	local emptyMsg = mk("TextLabel", { Size = UDim2.new(1, -16, 0, 60), Position = UDim2.fromOffset(8, 60), BackgroundTransparency = 1,
		TextColor3 = T.Dim, TextSize = 12, Font = Enum.Font.GothamMedium, TextWrapped = true, Visible = false, Parent = page })
	local cur, dirty, cards, chips = "avatar", true, {}, {}
	local nAv, nIt = 0, 0

	local function show(k)
		cur = k
		avSc.Visible, itSc.Visible = k == "avatar", k == "item"
		for kk, c in pairs(chips) do
			c.BackgroundColor3 = kk == k and Theme.TabActiveBg or T.Surface2
			c.TextColor3 = kk == k and T.Accent or T.Text
		end
		local empty = (k == "avatar" and nAv == 0) or (k == "item" and nIt == 0)
		emptyMsg.Visible = empty
		emptyMsg.Text = k == "avatar" and "Belum ada avatar favorit.\nTekan ♡ di kartu avatar."
			or "Belum ada item favorit.\nTekan ♡ di kartu item (karakter / animasi / sepatu)."
	end
	for i, d in ipairs({ { "avatar", "Avatar" }, { "item", "Item" } }) do
		local c = mk("TextButton", { Size = UDim2.fromOffset(0, 24), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = T.Surface2,
			BorderSizePixel = 0, Text = d[2], TextSize = 11, Font = Enum.Font.GothamBold, TextColor3 = T.Text, AutoButtonColor = false,
			LayoutOrder = i, Parent = chipRow })
		corner(c, 8)
		pad(c, 10, 0, 10, 0)
		chips[d[1]] = c
		c.Activated:Connect(function()
			show(d[1])
		end)
	end

	local function clear(sc)
		for _, c in ipairs(sc:GetChildren()) do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
	end
	local function sorted(map)
		local l = {}
		for _, r in pairs(map) do
			table.insert(l, r)
		end
		table.sort(l, function(a, b)
			return (a.t or 0) > (b.t or 0)
		end)
		return l
	end

	local function rebuild()
		dirty = false
		clear(avSc)
		clear(itSc)
		cards = {}
		local avs, its = sorted(FAV.avatars), sorted(FAV.items)
		nAv, nIt = #avs, #its
		chips.avatar.Text = "Avatar (" .. nAv .. ")"
		chips.item.Text = "Item (" .. nIt .. ")"
		for i, r in ipairs(avs) do
			userCard(avSc, r.id, r.name, i, "favorit")
		end
		local rows = {}
		for i, r in ipairs(its) do
			local row = { Id = r.Id, Type = r.Type, Name = r.Name, Price = false, Order = i, slot = r.slot, slotName = r.slotName }
			if r.Type == "Asset" then
				E.names[r.Id] = E.names[r.Id] or r.Name
				if r.tid then
					E.types[r.Id] = r.tid
				end
			end
			table.insert(rows, row)
			local c = makeCard(itSc, row)
			c.loadImg()
			table.insert(cards, c)
		end
		show(cur)
		-- harga & nama terbaru di latar belakang
		task.spawn(function()
			local packs = { A = { ids = {}, type = Enum.AvatarItemType.Asset }, B = { ids = {}, type = Enum.AvatarItemType.Bundle } }
			local byKey = {}
			for _, row in ipairs(rows) do
				local p = row.Type == "Bundle" and "B" or "A"
				table.insert(packs[p].ids, row.Id)
				byKey[p .. row.Id] = row
			end
			for p, pack in pairs(packs) do
				for i = 1, #pack.ids, 50 do
					local chunk = table.move(pack.ids, i, math.min(i + 49, #pack.ids), 1, {})
					local det = fetchDetails(chunk, pack.type)
					for _, id in ipairs(chunk) do
						local row, d = byKey[p .. id], det[id]
						if row then
							if d then
								row.Name = d.Name or row.Name
								row.Price = d.PriceInRobux
							else
								row.Price = nil
							end
							if row.onUpdate then
								pcall(row.onUpdate)
							end
						end
					end
				end
			end
		end)
	end

	FAV.listen(function()
		if not page.Parent then
			return false
		end
		if page.Visible then
			rebuild()
		else
			dirty = true
		end
	end)
	show("avatar")
	rebuild()
	return function()
		if dirty then
			if page.Visible then
				rebuild()
			end
			return
		end
		local set = collect(E.look)
		for _, c in ipairs(cards) do
			c.update(set)
		end
	end
end

----------------------------------------------------------------------------
-- [11] SHELL UI (gaya AVATAR CHANGER v2): header, sidebar 5 tab, drag, resize
----------------------------------------------------------------------------
local MAIN_W, MAIN_H = 660, 360
local State = { tab = "avatars", open = true, sbw = 60 }
local MIRROR_W = 115
local UI = { builders = {}, built = {}, pages = {}, refreshers = {} }

UI.gui = ScreenGui

toastHolder = mk("Frame", {
	AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 14), Size = UDim2.fromOffset(420, 300),
	BackgroundTransparency = 1, ZIndex = 200, Parent = ScreenGui,
})
mk("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
	HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = toastHolder,
})

local mainFrame = PageAvatar
local mainScale = { Scale = 1 }

local function computeScale()
	local cam = Workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	return math.clamp(math.min((vp.X - 20) / MAIN_W, (vp.Y - 20) / MAIN_H), 0.4, 1)
end

-- logo "F"
local function createLogo(size, rotation)
	local box = mk("Frame", { Size = size, BackgroundTransparency = 1, Rotation = rotation or -12 })
	local function bar(sz, pos)
		local f = mk("Frame", { Size = sz, Position = pos, BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = box })
		corner(f, 2)
	end
	bar(UDim2.new(1, 0, 0, math.floor(size.Y.Offset * 0.28)), UDim2.new())
	bar(UDim2.new(0.68, 0, 0, math.floor(size.Y.Offset * 0.24)), UDim2.new(0.2, 0, 0.4, 0))
	bar(UDim2.new(0, math.floor(size.X.Offset * 0.28), 1, 0), UDim2.new(0.08, 0, 0, 0))
	return box
end

-- header
local header = mk("Frame", { Name = "Header", Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, Active = true, Parent = mainFrame })
local logo = createLogo(UDim2.fromOffset(26, 26), -12)
logo.Position = UDim2.new(0, 16, 0, 13)
logo.Parent = header
local logBtn = mk("TextButton", { Size = UDim2.fromOffset(30, 30), Position = UDim2.new(0, 14, 0, 11), BackgroundTransparency = 1, Text = "", ZIndex = 5, Parent = header })
logBtn.Activated:Connect(function()
	local okC = pcall(function()
		local txt = table.concat(LOG, "\n")
		if setclipboard then
			setclipboard(txt)
		elseif toclipboard then
			toclipboard(txt)
		else
			error("tidak ada clipboard")
		end
	end)
	toast(okC and "Log disalin ke clipboard (tempel ke chat kalau ada error)" or "Clipboard tidak ada di executor ini, lihat Output/F9", okC and "ok" or "warn")
end)
mk("TextLabel", {
	Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = Theme.Accent, BackgroundTransparency = 1,
	Size = UDim2.new(0, 200, 0, 26), Position = UDim2.new(0, 50, 0, 13), TextXAlignment = Enum.TextXAlignment.Left,
	Text = "AVATAR CHANGER", Parent = header,
})

local ToggleMainUI

local closeBtn = mk("TextButton", {
	Size = UDim2.fromOffset(36, 36), Position = UDim2.new(1, -44, 0, 8), BackgroundColor3 = Theme.CardBg, Text = "X",
	Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Theme.TextPrimary, AutoButtonColor = false, Parent = header,
})
corner(closeBtn, 10)
stroke(closeBtn, Theme.CardBorder, 1.5)
closeBtn.Activated:Connect(function()
	ToggleMainUI(false)
end)

local waBtn = mk("TextButton", {
	Size = UDim2.fromOffset(120, 26), Position = UDim2.new(1, -175, 0, 13), BackgroundColor3 = Theme.WaGreen,
	Text = "💬 SALURAN WA", Font = Enum.Font.GothamBold, TextSize = 9, TextColor3 = Theme.TextPrimary,
	AutoButtonColor = false, Parent = header,
})
corner(waBtn, 8)
stroke(waBtn, Theme.WaDarkGreen, 1.5)
waBtn.Activated:Connect(function()
	pcall(function()
		if setclipboard then
			setclipboard(WA_CHANNEL_LINK)
		elseif toclipboard then
			toclipboard(WA_CHANNEL_LINK)
		end
	end)
	local orig = "💬 SALURAN WA"
	waBtn.Text = "✓ COPIED!"
	task.delay(1.5, function()
		if waBtn.Parent then
			waBtn.Text = orig
		end
	end)
end)

mk("Frame", { Size = UDim2.new(1, -32, 0, 1), Position = UDim2.new(0, 16, 0, 48), BackgroundColor3 = Theme.CardBorder, BorderSizePixel = 0, Parent = mainFrame })
-- bar loading di bawah header (aktif saat avatar / item sedang diproses)
local loadTrack = mk("Frame", { Size = UDim2.new(1, -32, 0, 3), Position = UDim2.new(0, 16, 0, 47), BackgroundTransparency = 1,
	ClipsDescendants = true, ZIndex = 8, Parent = mainFrame })
local loadBar = mk("Frame", { Size = UDim2.fromScale(0.35, 1), Position = UDim2.fromScale(-0.35, 0), BackgroundColor3 = Theme.Accent,
	BorderSizePixel = 0, Visible = false, ZIndex = 8, Parent = loadTrack })
corner(loadBar, 2)
task.spawn(function()
	local x = -0.35
	while not stale() and UI.gui.Parent do
		if E.busy or E.worker or E.pending ~= nil or E.loadingBundles > 0 or E.pendingClicks > 0 then
			loadBar.Visible = true
			x = x + 0.045
			if x > 1 then
				x = -0.35
			end
			loadBar.Position = UDim2.fromScale(x, 0)
			task.wait(0.016)
		else
			loadBar.Visible = false
			task.wait(0.1)
		end
	end
end)

-- body: sidebar + content
local bodyFrame = mk("Frame", { Name = "Body", Size = UDim2.new(1, -12, 1, -8), Position = UDim2.new(0, 6, 0, 4), BackgroundTransparency = 1, Parent = PageAvatar })
local sidebar = mk("ScrollingFrame", {
	Name = "Sidebar", Size = UDim2.new(0, State.sbw, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0,
	AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Parent = bodyFrame,
})
mk("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = sidebar })

local contentFrame = mk("Frame", {
	Name = "Content", Size = UDim2.new(1, -(State.sbw + 6) - (MIRROR_W + 6), 1, 0), Position = UDim2.new(0, State.sbw + 6, 0, 0),
	BackgroundTransparency = 1, ClipsDescendants = true, Parent = bodyFrame,
})
local contentTitle = mk("TextLabel", {
	Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Theme.TextPrimary, BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 20), TextXAlignment = Enum.TextXAlignment.Left, Text = "AVATAR", Parent = contentFrame,
})
local contentSub = mk("TextLabel", {
	Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = Theme.TextMuted, BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 0, 22), TextXAlignment = Enum.TextXAlignment.Left,
	Text = "", Parent = contentFrame,
})
local pageHolder = mk("Frame", { Size = UDim2.new(1, 0, 1, -46), Position = UDim2.fromOffset(0, 46), BackgroundTransparency = 1, Parent = contentFrame })

local function updateSub()
	local n = #E.wornList()
	contentSub.Text = n .. " item dipakai  •  mode: " .. (E.lastMethod ~= "" and E.lastMethod or (E.remote and "server" or "native"))
end

-- daftar tab
local TABS = {
	{ key = "avatars", name = "avatar" },
	{ key = "karakter", name = "karakter", group = "KARAKTER / TUBUH" },
	{ key = "animasi", name = "animasi", group = "ANIMASI" },
	{ key = "sepatu", name = "sepatu", group = "SEPATU" },
	{ key = "favorit", name = "favorit", title = "FAVORIT" },
	{ key = "worn", name = "dipakai", title = "SEDANG DI PAKAI" },
}

UI.builders.avatars = buildAvatars
UI.builders.favorit = function(p)
	UI.refreshers.favorit = buildFavorites(p)
end
UI.builders.worn = function(p)
	UI.refreshers.worn = buildWorn(p)
end
for _, tab in ipairs(TABS) do
	if tab.group then
		UI.builders[tab.key] = function(p)
			UI.refreshers[tab.key] = buildCatalog(p, tab.group)
		end
	end
end

local tabBtns = {}
local function setTab(index)
	local tab = TABS[index]
	State.tab = tab.key
	for i, b in ipairs(tabBtns) do
		local active = i == index
		b.frame.BackgroundTransparency = active and 0 or 1
		b.frame.BackgroundColor3 = Theme.TabActiveBg
		b.stroke.Enabled = active
		b.label.TextColor3 = active and Theme.TextPrimary or Theme.TextMuted
		b.indicator.Visible = active
	end
	for k, p in pairs(UI.pages) do
		p.Visible = k == tab.key
	end
	contentTitle.Text = tab.title or string.upper(tab.name)
	updateSub()
	if not UI.built[tab.key] then
		UI.built[tab.key] = true
		local okB, errB = pcall(UI.builders[tab.key], UI.pages[tab.key])
		if not okB then
			logf("GAGAL membuat halaman %s: %s", tab.key, tostring(errB))
			mk("TextLabel", {
				Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, TextWrapped = true, TextColor3 = T.Danger,
				TextSize = 12, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top, Text = "⚠ Halaman gagal dibuat:\n" .. tostring(errB),
				Parent = UI.pages[tab.key],
			})
		end
	elseif UI.refreshers[tab.key] then
		pcall(UI.refreshers[tab.key])
	end
end

for i, tab in ipairs(TABS) do
	local b = mk("TextButton", {
		Name = "Tab_" .. tab.key, Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Theme.TabActiveBg, BackgroundTransparency = 1,
		Text = "", AutoButtonColor = false, LayoutOrder = i, Parent = sidebar,
	})
	corner(b, 8)
	local sk = stroke(b, Theme.TabActiveBorder, 1)
	sk.Enabled = false
	local ind = mk("Frame", {
		Size = UDim2.new(0, 3, 0, 16), Position = UDim2.new(0, 4, 0.5, -8), BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0, Visible = false, Parent = b,
	})
	corner(ind, 99)
	local lb = mk("TextLabel", {
		Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = Theme.TextMuted, BackgroundTransparency = 1,
		Size = UDim2.new(1, -14, 1, 0), Position = UDim2.new(0, 12, 0, 0), TextXAlignment = Enum.TextXAlignment.Left,
		Text = string.upper(tab.name), Parent = b,
	})
	table.insert(tabBtns, { frame = b, stroke = sk, label = lb, indicator = ind })
	b.Activated:Connect(function()
		setTab(i)
	end)
	UI.pages[tab.key] = mk("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, Parent = pageHolder })
end

----------------------------------------------------------------------------
-- [11b] CERMIN  -  pratinjau karakter (ViewportFrame) seperti etalase avatar shop
--   Menyalin karakter yang SEDANG tampil di layar, jadi isi cermin = yang kamu lihat.
--   Otomatis ikut berubah saat item/avatar dipilih. Geser untuk memutar.
--   Kamera otomatis menyesuaikan ukuran avatar (kecil / tinggi) dan ukuran panel.
----------------------------------------------------------------------------
do
-- MIRROR_W defined above
local Mirror = { on = true, spin = 0, auto = true, dragging = false, pauseUntil = 0, sig = nil, stage = nil, model = nil, token = 0 }

local mirrorPanel = mk("Frame", {
	Name = "Mirror", Size = UDim2.new(0, MIRROR_W, 1, 0), Position = UDim2.new(1, -MIRROR_W, 0, 0),
	BackgroundColor3 = Theme.CardBg, BorderSizePixel = 0, ClipsDescendants = true, Parent = bodyFrame,
})
corner(mirrorPanel, 14)
stroke(mirrorPanel, Theme.Accent, 2)
mk("UIGradient", {
	Color = ColorSequence.new(Color3.fromRGB(36, 40, 66), Color3.fromRGB(14, 15, 26)),
	Rotation = 90, Parent = mirrorPanel,
})

mk("TextLabel", {
	Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Theme.Accent, BackgroundTransparency = 1,
	Size = UDim2.new(1, -16, 0, 20), Position = UDim2.new(0, 10, 0, 6), TextXAlignment = Enum.TextXAlignment.Left,
	Text = "CERMIN", Parent = mirrorPanel,
})

local mirrorVP = mk("ViewportFrame", {
	Name = "MirrorVP", Size = UDim2.new(1, -12, 1, -72), Position = UDim2.new(0, 6, 0, 28),
	BackgroundTransparency = 1, Active = true,
	Ambient = Color3.fromRGB(175, 175, 190), LightColor = Color3.fromRGB(255, 255, 255),
	LightDirection = Vector3.new(-0.5, -0.8, -0.6), Parent = mirrorPanel,
})
local mirrorCam = mk("Camera", { FieldOfView = 40, Parent = mirrorVP })
mirrorVP.CurrentCamera = mirrorCam

local mirrorMsg = mk("TextLabel", {
	Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = Theme.TextMuted, BackgroundTransparency = 1,
	Size = UDim2.new(1, -20, 0, 40), Position = UDim2.new(0, 10, 0.5, -20), TextWrapped = true,
	Text = "Memuat karakter...", Parent = mirrorPanel,
})


local function charSignature()
	local char = player.Character
	if not char then
		return "none"
	end
	local n = 0
	for _ in ipairs(char:GetDescendants()) do
		n = n + 1
	end
	local ext = ""
	pcall(function()
		local s = char:GetExtentsSize()
		ext = string.format("%.1f,%.1f", s.Y, math.max(s.X, s.Z))
	end)
	return n .. "|" .. tostring(char:FindFirstChild(SKIN_NAME) ~= nil) .. "|" .. tostring(E.lastMethod) .. "|" .. ext
end

-- ukur bagian yang TERLIHAT saja: tinggi + radius putar dari sumbu tengah
local function measure(model)
	local minY, maxY, rad = math.huge, -math.huge, 0
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and d.Transparency < 0.95 then
			local cf, h = d.CFrame, d.Size / 2
			for sx = -1, 1, 2 do
				for sy = -1, 1, 2 do
					for sz = -1, 1, 2 do
						local p = cf:PointToWorldSpace(Vector3.new(h.X * sx, h.Y * sy, h.Z * sz))
						minY = math.min(minY, p.Y)
						maxY = math.max(maxY, p.Y)
						rad = math.max(rad, math.sqrt(p.X * p.X + p.Z * p.Z))
					end
				end
			end
		end
	end
	if minY == math.huge then
		local cf, size = model:GetBoundingBox()
		minY, maxY = cf.Position.Y - size.Y / 2, cf.Position.Y + size.Y / 2
		rad = math.max(size.X, size.Z) / 2
	end
	local headY, headH
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d.Name == "Head" and d.Transparency < 0.95 then
			headY, headH = d.Position.Y, d.Size.Y
			break
		end
	end
	if not headY then
		headY, headH = maxY - 0.6, 1.2
	end
	return { minY = minY, maxY = maxY, height = math.max(maxY - minY, 0.5), cy = (minY + maxY) / 2,
		radius = math.max(rad, 0.5), headY = headY, headH = headH }
end

local function mirrorBuild()
	local char = player.Character
	if not char or not char.Parent then
		return nil, "karakter belum siap"
	end
	local wasArch = char.Archivable
	char.Archivable = true
	local okC, clone = pcall(function()
		return char:Clone()
	end)
	char.Archivable = wasArch
	if not okC or not clone then
		return nil, "gagal menyalin karakter"
	end
	for _, d in ipairs(clone:GetDescendants()) do
		pcall(function()
			if d:IsA("LuaSourceContainer") or d:IsA("Sound") or d:IsA("BillboardGui") then
				d:Destroy()
			elseif d:IsA("BasePart") then
				d.Anchored = true
				d.CanCollide = false
			end
		end)
	end
	local hum = clone:FindFirstChildOfClass("Humanoid")
	if hum then
		pcall(function()
			hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		end)
	end
	local hrp = clone:FindFirstChild("HumanoidRootPart")
	if hrp and not clone.PrimaryPart then
		clone.PrimaryPart = hrp
	end
	clone:PivotTo(CFrame.new())

	local b = measure(clone)

	local stage = Instance.new("Folder")
	stage.Name = "Stage"
	local d = math.max(b.radius * 2 * 1.15, 2)
	local base = Instance.new("Part")
	base.Name = "Platform"
	base.Shape = Enum.PartType.Cylinder
	base.Size = Vector3.new(0.2, d, d)
	base.CFrame = CFrame.new(0, b.minY - 0.1, 0) * CFrame.Angles(0, 0, math.pi / 2)
	base.Anchored = true
	base.CanCollide = false
	base.Material = Enum.Material.Neon
	base.Color = Theme.Accent
	base.Transparency = 0.55
	base.Parent = stage
	clone.Parent = stage
	return stage, clone, b
end

-- atur jarak kamera supaya seluruh avatar (kecil / tinggi) pas di panel
function Mirror.fit()
	local b = Mirror.bounds
	if not b then
		return
	end
	local vs = mirrorVP.AbsoluteSize
	local aspect = math.max(vs.X, 1) / math.max(vs.Y, 1)
	local tanV = math.tan(math.rad(mirrorCam.FieldOfView) / 2)
	local tanH = tanV * aspect
	-- kamera sejajar tinggi kepala; titik pandang di antara kepala & tengah badan supaya seluruh avatar tetap masuk
	local camY = b.headY
	local lookY = (b.headY + b.cy) / 2
	local halfH = math.max(b.maxY - lookY, lookY - b.minY, b.headH) * 1.12
	local dist = math.max(halfH / tanV, (b.radius * 1.12) / tanH) + b.radius
	local target = CFrame.lookAt(Vector3.new(0, camY, dist), Vector3.new(0, lookY, 0))
	if Mirror.fitted then
		tween(mirrorCam, { CFrame = target }, 0.25)
	else
		mirrorCam.CFrame = target
		Mirror.fitted = true
	end
end
mirrorVP:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	Mirror.fit()
end)

function Mirror.refresh()
	if stale() or not mirrorVP.Parent then
		return
	end
	local ok, stage, model, bounds = pcall(mirrorBuild)
	if not ok then
		logf("cermin gagal: %s", tostring(stage))
		mirrorMsg.Text = "Cermin gagal: " .. tostring(stage)
		mirrorMsg.Visible = true
		return
	end
	if not stage then
		mirrorMsg.Text = tostring(model)
		mirrorMsg.Visible = true
		return
	end
	local old = Mirror.stage
	stage.Parent = mirrorVP
	Mirror.stage, Mirror.model, Mirror.bounds = stage, model, bounds
	Mirror.sig = charSignature()
	Mirror.fit()
	mirrorMsg.Visible = false
	if old then
		old:Destroy()
	end
end

function Mirror.queue(delay)
	Mirror.token = Mirror.token + 1
	local t = Mirror.token
	task.delay(delay or 0.6, function()
		if t == Mirror.token then
			Mirror.refresh()
		end
	end)
end

-- geser untuk memutar
mirrorVP.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		Mirror.dragging = true
		Mirror.lastX = input.Position.X
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				Mirror.dragging = false
				Mirror.pauseUntil = os.clock() + 2
			end
		end)
	end
end)
mirrorVP.InputChanged:Connect(function(input)
	if Mirror.dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local x = input.Position.X
		Mirror.spin = Mirror.spin + (x - (Mirror.lastX or x)) * 0.012
		Mirror.lastX = x
	end
end)

-- tombol bawah: putar otomatis
local mirrorAutoBtn = button(mirrorPanel, {
	text = "⏸ Putar", textSize = 11, bg = Theme.CardBg, size = UDim2.new(1, -12, 0, 26),
	position = UDim2.new(0, 6, 1, -32), radius = 8, onClick = function() end,
})
mirrorAutoBtn.Activated:Connect(function()
	Mirror.auto = not Mirror.auto
	mirrorAutoBtn.Text = Mirror.auto and "⏸ Putar" or "▶ Putar"
end)


-- animasi putar
do
	local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		if stale() or not UI.gui.Parent then
			conn:Disconnect()
			return
		end
		if not Mirror.model or not Mirror.model.Parent or not mirrorPanel.Visible or not State.open then
			return
		end
		if Mirror.auto and not Mirror.dragging and os.clock() > Mirror.pauseUntil then
			Mirror.spin = Mirror.spin + dt * 0.8
		end
		pcall(function()
			Mirror.model:PivotTo(CFrame.Angles(0, math.pi + Mirror.spin, 0))
		end)
	end)
end

-- ikuti perubahan avatar
E.onChanged(function()
	Mirror.queue(0.8)
end)
player.CharacterAdded:Connect(function()
	Mirror.sig = nil
	Mirror.queue(2)
end)

-- pemeriksa berkala (menangkap perubahan susulan: aksesori yang baru selesai dimuat, dll)
task.spawn(function()
	local last = 0
	while not stale() and UI.gui.Parent do
		task.wait(2)
		if State.open and mirrorPanel.Visible then
			if charSignature() ~= Mirror.sig or os.clock() - last > 8 then
				last = os.clock()
				Mirror.refresh()
			end
		end
	end
end)
Mirror.queue(1.5)
end

-- tombol mengambang (muncul saat UI ditutup)
local fab = mk("TextButton", {
	Name = "FloatingToggleBtn", Size = UDim2.fromOffset(44, 44), AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 20, 0.4, 0), BackgroundColor3 = Theme.Background, BorderSizePixel = 0,
	Visible = false, Active = true, Text = "", ZIndex = 20, Parent = ScreenGui,
})
corner(fab, 11)
stroke(fab, Theme.Accent, 1.5)
local fabLogo = createLogo(UDim2.fromOffset(20, 20), -12)
fabLogo.Position = UDim2.new(0.5, -10, 0.5, -10)
fabLogo.Parent = fab

-- resize handle
local resizeHandle = mk("TextButton", {
	Name = "ResizeHandle", Size = UDim2.fromOffset(18, 18), AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = Theme.Accent, Text = "◢", Font = Enum.Font.GothamBold, TextSize = 9, TextColor3 = Theme.Background,
	AutoButtonColor = false, ZIndex = 10, Parent = mainFrame,
})
corner(resizeHandle, 5)

-- drag / resize / drag tombol mengambang
local dragging, dragStart, dragOrigin
local resizing, resizeStart, sizeOrigin
local floating, floatStart, floatOrigin, floatMoved = false, nil, nil, false

header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging, dragStart, dragOrigin = true, input.Position, mainFrame.Position
	end
end)
resizeHandle.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		resizing, resizeStart, sizeOrigin = true, input.Position, mainFrame.Size
	end
end)
fab.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		floating, floatStart, floatOrigin, floatMoved = true, input.Position, fab.Position, false
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if stale() then
		return
	end
	local moveType = input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
	if not moveType then
		return
	end
	if dragging then
		local d = input.Position - dragStart
		mainFrame.Position = UDim2.new(dragOrigin.X.Scale, dragOrigin.X.Offset + d.X, dragOrigin.Y.Scale, dragOrigin.Y.Offset + d.Y)
	end
	if resizing then
		local d = (input.Position - resizeStart) / math.max(mainScale.Scale, 0.1)
		mainFrame.Size = UDim2.fromOffset(
			math.clamp(sizeOrigin.X.Offset + d.X, 560, 1000),
			math.clamp(sizeOrigin.Y.Offset + d.Y, 300, 650)
		)
	end
	if floating then
		local d = input.Position - floatStart
		if math.abs(d.X) + math.abs(d.Y) > 8 then
			floatMoved = true
		end
		if floatMoved then
			fab.Position = UDim2.new(floatOrigin.X.Scale, floatOrigin.X.Offset + d.X, floatOrigin.Y.Scale, floatOrigin.Y.Offset + d.Y)
		end
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging, resizing, floating = false, false, false
	end
end)
fab.Activated:Connect(function()
	if not floatMoved then
		-- embedded in PageAvatar
	end
end)

ToggleMainUI = function(show) end
local _unused_ToggleMainUI = function(show)
	State.open = show
	if show then
		mainFrame.Visible = true
		mainScale.Scale = 0
		fab.Visible = false
		tween(mainScale, { Scale = computeScale() }, 0.22, Enum.EasingStyle.Back)
	else
		mainScale.Scale = 0
		mainFrame.Visible = false
		fab.Visible = true
	end
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp or E.uiDestroyed or stale() then
		return
	end
	if input.KeyCode == TOGGLE_KEY then
		ToggleMainUI(not State.open)
		return
	end
	local ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
	if ctrl and State.open then
		if input.KeyCode == Enum.KeyCode.Z then
			task.spawn(E.undo)
		elseif input.KeyCode == Enum.KeyCode.Y then
			task.spawn(E.doRedo)
		end
	end
end)

do
	local cam = Workspace.CurrentCamera
	if cam then
		cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			if State.open then
				mainScale.Scale = computeScale()
			end
		end)
	end
end

-- segarkan kartu/daftar saat avatar berubah
E.onChanged(function()
	updateSub()
	-- nama item yang dipakai disiapkan lebih awal supaya tab DIPAKAI langsung terisi
	task.spawn(function()
		local ids = {}
		for _, e in ipairs(E.wornList()) do
			if not E.names[e.Id] then
				ids[#ids + 1] = e.Id
			end
		end
		if #ids > 0 then
			pcall(E.fillNames, ids)
		end
	end)
	for key, fn in pairs(UI.refreshers) do
		if key == State.tab or key ~= "worn" then
			pcall(fn)
		end
	end
end)

----------------------------------------------------------------------------
-- [12] BOOT + START
----------------------------------------------------------------------------
setTab(1)
-- embedded in PageAvatar

task.spawn(function()
	local ok, err = pcall(E.init)
	if not ok then
		toast("Gagal menyiapkan karakter: " .. tostring(err), "danger")
		return
	end
	toast("Avatar Changer siap! K = buka/tutup  •  mode: " .. (E.remote and "SERVER" or (E.injectFirst and "INJECTOR (visual klien)" or "native")), "ok")
	if PREWARM_SKIN and not E.remote and E.useSkin and E.cap.donor ~= false and E.look then
		E.busy = true
		pcall(E.apply, E.look)
		E.busy = false
		E.reapplyTweaks()
	end
end)

-- muat tab katalog lain diam-diam supaya saat dibuka sudah terisi
task.delay(3, function()
	for _, tab in ipairs(TABS) do
		if stale() then
			return
		end
		if tab.group and not UI.built[tab.key] then
			UI.built[tab.key] = true
			pcall(UI.builders[tab.key], UI.pages[tab.key])
			task.wait(0.8)
		end
	end
end)

end
initAvatarPage()


-- Set default open tab to Toolbox
switchTab("Toolbox")
print("[Quantum Engine] Studio Lite PC Loaded Successfully!")
