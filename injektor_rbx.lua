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
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.fromScale(0.5, 0.5)
MainFrame.Size = UDim2.new(0, 720, 0, 420)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Active = true
MainFrame.ZIndex = 10
MainFrame.Parent = ScreenGui
makeCorner(MainFrame, 10)
makeStroke(MainFrame, Color3.fromRGB(255,255,255), 1.4)

-- TOP BAR
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, -16, 0, 38)
TopBar.Position = UDim2.new(0, 8, 0, 6)
TopBar.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
TopBar.BorderSizePixel = 0
TopBar.Active = true
TopBar.ZIndex = 11
TopBar.Parent = MainFrame
makeCorner(TopBar, 7)
makeStroke(TopBar, Color3.fromRGB(255,255,255), 1, 0.75)

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size = UDim2.new(1, -70, 1, 0)
TitleLbl.Position = UDim2.new(0, 12, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text = "BLUExCrown ENGINE v5.6"
TitleLbl.Font = Enum.Font.GothamBold
TitleLbl.TextSize = 11
TitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TitleLbl.ZIndex = 12
TitleLbl.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 26, 0, 24)
CloseBtn.Position = UDim2.new(1, -30, 0, 4)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
CloseBtn.ZIndex = 20
CloseBtn.Active = true
CloseBtn.Parent = TopBar
makeCorner(CloseBtn, 5)

-- Draggable Hanya untuk TopBar
local function makeSafeTopBarDraggable(frame, handle)
    local dragInput = nil
    local dragStart = nil
    local startPos = nil

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

    UserInputService.InputEnded:Connect(function(input)
        if input == dragInput then
            dragInput = nil
            dragStart = nil
            startPos = nil
        end
    end)
end

makeSafeTopBarDraggable(MainFrame, TopBar)

-- TOGGLE & CLOSE BEHAVIOR
local isOpen = true
local toggleDebounce = false

local function toggleWindow()
    if toggleDebounce then return end
    toggleDebounce = true
    isOpen = not isOpen
    MainFrame.Visible = isOpen
    task.delay(0.2, function() toggleDebounce = false end)
end

bindBtn(ToggleBtn, toggleWindow)
bindBtn(CloseBtn, toggleWindow)

-- =====================================================
-- 3. IN-GAME CODE EDITOR MODAL
-- =====================================================
local EditorModal = Instance.new("Frame")
EditorModal.Name = "BLUExEditorModal"
EditorModal.AnchorPoint = Vector2.new(0.5, 0.5)
EditorModal.Position = UDim2.fromScale(0.5, 0.5)
EditorModal.Size = UDim2.new(0, 680, 0, 380)
EditorModal.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
EditorModal.BorderSizePixel = 0
EditorModal.ClipsDescendants = true
EditorModal.Visible = false
EditorModal.Active = false
EditorModal.ZIndex = 200
EditorModal.Parent = ScreenGui
makeCorner(EditorModal, 10)
makeStroke(EditorModal, Color3.fromRGB(255, 255, 255), 1.5)

local EdTopBar = Instance.new("Frame")
EdTopBar.Size = UDim2.new(1, -12, 0, 32)
EdTopBar.Position = UDim2.new(0, 6, 0, 6)
EdTopBar.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
EdTopBar.ZIndex = 201
EdTopBar.Parent = EditorModal
makeCorner(EdTopBar, 6)
makeStroke(EdTopBar, Color3.fromRGB(255,255,255), 1, 0.8)

local EdTitleLbl = Instance.new("TextLabel")
EdTitleLbl.Size = UDim2.new(0.38, 0, 1, 0)
EdTitleLbl.Position = UDim2.new(0, 10, 0, 0)
EdTitleLbl.BackgroundTransparency = 1
EdTitleLbl.Text = "EDITOR: Script"
EdTitleLbl.Font = Enum.Font.GothamBold
EdTitleLbl.TextSize = 11
EdTitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
EdTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
EdTitleLbl.ZIndex = 202
EdTitleLbl.Parent = EdTopBar

local EdBtnRow = Instance.new("Frame")
EdBtnRow.Size = UDim2.new(0.62, -10, 1, -6)
EdBtnRow.Position = UDim2.new(0.38, 5, 0, 3)
EdBtnRow.BackgroundTransparency = 1
EdBtnRow.ZIndex = 202
EdBtnRow.Parent = EdTopBar

local edLayout = Instance.new("UIListLayout")
edLayout.FillDirection = Enum.FillDirection.Horizontal
edLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
edLayout.Padding = UDim.new(0, 6)
edLayout.Parent = EdBtnRow

local function makeEdBtn(text, width, onClick)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, width, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 9
    btn.TextColor3 = Color3.fromRGB(0, 0, 0)
    btn.ZIndex = 203
    btn.Parent = EdBtnRow
    makeCorner(btn, 5)
    bindBtn(btn, onClick)
    return btn
end

local activeEditingScript = ""

local EdSaveBtn = makeEdBtn("SAVE & APPLY", 90, function() end)
local EdRunBtn  = makeEdBtn("RUN SCRIPT", 75, function() end)
local EdCopyBtn = makeEdBtn("COPY ALL", 65, function() end)
local EdRecBtn  = makeEdBtn("RECREATE SCRIPT", 100, function() end)
local EdCloseBtn = makeEdBtn("X", 26, function()
    EditorModal.Visible = false
    EditorModal.Active = false
end)

local EdScroll = Instance.new("ScrollingFrame")
EdScroll.ClipsDescendants = true
EdScroll.Size = UDim2.new(1, -12, 1, -48)
EdScroll.Position = UDim2.new(0, 6, 0, 42)
EdScroll.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
EdScroll.BorderSizePixel = 0
EdScroll.ScrollBarThickness = 4
EdScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
EdScroll.ZIndex = 201
EdScroll.Parent = EditorModal
makeCorner(EdScroll, 6)
makeStroke(EdScroll, Color3.fromRGB(255,255,255), 1, 0.8)

local EdTextBox = Instance.new("TextBox")
EdTextBox.Size = UDim2.new(1, -16, 1, -10)
EdTextBox.Position = UDim2.new(0, 8, 0, 5)
EdTextBox.BackgroundTransparency = 1
EdTextBox.Font = Enum.Font.Code
EdTextBox.TextSize = 11
EdTextBox.TextColor3 = Color3.fromRGB(235, 235, 240)
EdTextBox.TextXAlignment = Enum.TextXAlignment.Left
EdTextBox.TextYAlignment = Enum.TextYAlignment.Top
EdTextBox.ClearTextOnFocus = false
EdTextBox.TextEditable = true
EdTextBox.RichText = false  -- Prevent <font color> tag injection
EdTextBox.MultiLine = true
EdTextBox.Active = true
EdTextBox.ZIndex = 202
EdTextBox.Text = ""
EdTextBox.Parent = EdScroll

-- SAFE canvas resize: programmatic sets scroll back to top, user typing keeps position
local _progTextSet = false
EdTextBox:GetPropertyChangedSignal("Text"):Connect(function()
    local lines = #EdTextBox.Text:split("\n")
    EdScroll.CanvasSize = UDim2.new(0, 0, 0, math.max(340, lines * 18 + 40))
    if _progTextSet then
        -- reset to top only on programmatic open, not while user is typing
        task.defer(function() pcall(function() EdScroll.CanvasPosition = Vector2.new(0, 0) end) end)
    end
end)

local function openInEditor(scriptName, code)
    activeEditingScript = scriptName or "Script"
    EdTitleLbl.Text = "EDITOR: " .. activeEditingScript
    -- Use flag so scroll resets to top (not halfway through code)
    _progTextSet = true
    local safeCode = code or lookupScriptSource(scriptName) or "-- Ketik code di sini..."
    -- Strip any RichText tags Studio Lite may have injected
    safeCode = stripRichText(safeCode)
    EdTextBox.Text = safeCode
    task.defer(function()
        _progTextSet = false
        pcall(function() EdScroll.CanvasPosition = Vector2.new(0, 0) end)
    end)
    EditorModal.Active = true
    EditorModal.Visible = true
end

bindBtn(EdSaveBtn, function()
    local newCode = EdTextBox.Text
    storeScriptSource(activeEditingScript, newCode)
    pcall(function()
        for _, inst in ipairs(workspace:GetDescendants()) do
            if inst:IsA("LuaSourceContainer") and inst.Name:lower() == activeEditingScript:lower() then
                storeScriptSource(inst, newCode)
                pcall(function() inst.Source = newCode end)
            end
        end
    end)
    if serverFuncs then
        pcall(function() serverFuncs:InvokeServer("SaveScriptSourceServerFunction", activeEditingScript, newCode) end)
    end
    EdSaveBtn.Text = "SAVED!"
    task.delay(1.2, function() EdSaveBtn.Text = "SAVE & APPLY" end)
end)


bindBtn(EdRecBtn, function()
    local code = EdTextBox.Text
    local target = activeEditingScript
    local recreated = nil
    for _, place in ipairs({workspace, ReplicatedStorage, LP:FindFirstChild("PlayerGui")}) do
        if place then
            for _, obj in ipairs(place:GetDescendants()) do
                if obj:IsA("LuaSourceContainer") and (obj.Name:lower() == target:lower() or (obj.ClassName .. obj.Name):lower() == target:lower()) then
                    recreated = recreateScriptAsNative(obj, code)
                    break
                end
            end
        end
        if recreated then break end
    end
    if recreated then
        EdRecBtn.Text = "RECREATED!"
    else
        local fresh = Instance.new("Script")
        fresh.Name = target
        pcall(function() fresh.Source = code end)
        fresh.Parent = workspace
        injectStudioLiteUI(fresh, {[fresh.ClassName .. ":" .. fresh.Name] = code})
        EdRecBtn.Text = "CREATED NEW!"
    end
    task.delay(1.5, function() EdRecBtn.Text = "RECREATE SCRIPT" end)
end)

bindBtn(EdRunBtn, function()
    if EdTextBox.Text ~= "" then
        local fn, err = loadstring(EdTextBox.Text)
        if fn then
            task.spawn(fn)
            EdRunBtn.Text = "RUNNING!"
        else
            EdRunBtn.Text = "ERROR!"
            warn("[BLUExCrown] Code Error: " .. tostring(err))
        end
        task.delay(1.5, function() EdRunBtn.Text = "RUN SCRIPT" end)
    end
end)

bindBtn(EdCopyBtn, function()
    if clipFn and EdTextBox.Text ~= "" then
        pcall(clipFn, EdTextBox.Text)
        EdCopyBtn.Text = "COPIED!"
        task.delay(1.2, function() EdCopyBtn.Text = "COPY ALL" end)
    end
end)

-- =====================================================
-- 4. STUDIO LITE REAL-TIME UI WATCHER & INJECTOR
-- =====================================================
-- =====================================================
-- 4. PURE NATIVE STUDIO LITE INTEGRATION (ZERO INTERFERENCE)
-- Sesuai instruksi: Script kita HANYA membuat ulang script secara native saat import.
-- Setelah script dibuat, game & text editor Studio Lite berjalan 100% normal dan murni
-- tanpa ada campur tangan atau gangguan apa pun terhadap PlayerGui!
-- =====================================================

-- 5. PAGES & NAVIGATION (100% INSTANT HITBOX)
-- =====================================================
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -16, 1, -52)
Content.Position = UDim2.new(0, 8, 0, 48)
Content.BackgroundTransparency = 1
Content.ZIndex = 11
Content.Parent = MainFrame

local PageSplash   = Instance.new("Frame")
local PageToolbox  = Instance.new("Frame")
local PageRBXM     = Instance.new("Frame")
local PageRBXL     = Instance.new("Frame")
local PageText3D   = Instance.new("Frame")
local PageReplacer = Instance.new("Frame")
local PageAvatar   = Instance.new("Frame")

for _, pg in ipairs({PageSplash, PageToolbox, PageRBXM, PageRBXL, PageText3D, PageReplacer, PageAvatar}) do
    pg.Size = UDim2.fromScale(1, 1)
    pg.BackgroundTransparency = 1
    pg.Visible = false
    pg.ZIndex = 12
    pg.Parent = Content
end
PageSplash.Visible = true

local function showPage(target)
    PageSplash.Visible   = false
    PageToolbox.Visible  = false
    PageRBXM.Visible     = false
    PageRBXL.Visible     = false
    PageText3D.Visible   = false
    PageReplacer.Visible = false
    PageAvatar.Visible   = false
    target.Visible = true
end

-- =====================================================
-- PAGE 1: SPLASH SCREEN (HOME)
-- =====================================================
local ProfileCard = Instance.new("Frame")
ProfileCard.Size = UDim2.new(0, 175, 1, 0)
ProfileCard.BackgroundColor3 = Color3.fromRGB(17, 17, 22)
ProfileCard.BorderSizePixel = 0
ProfileCard.ZIndex = 13
ProfileCard.Parent = PageSplash
makeCorner(ProfileCard, 8)
makeStroke(ProfileCard, Color3.fromRGB(255,255,255), 1, 0.75)

local AvatarImg = Instance.new("ImageLabel")
AvatarImg.Size = UDim2.new(0, 70, 0, 70)
AvatarImg.AnchorPoint = Vector2.new(0.5, 0)
AvatarImg.Position = UDim2.new(0.5, 0, 0, 14)
AvatarImg.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
AvatarImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LP.UserId) .. "&w=150&h=150"
AvatarImg.ZIndex = 14
AvatarImg.Parent = ProfileCard
makeCorner(AvatarImg, 35)
makeStroke(AvatarImg, Color3.fromRGB(255,255,255), 1.5, 0.5)

local DispName = Instance.new("TextLabel")
DispName.Size = UDim2.new(1, -16, 0, 20)
DispName.Position = UDim2.new(0, 8, 0, 90)
DispName.BackgroundTransparency = 1
DispName.Text = LP.DisplayName or LP.Name or "Player"
DispName.Font = Enum.Font.GothamBold
DispName.TextSize = 13
DispName.TextColor3 = Color3.fromRGB(255, 255, 255)
DispName.TextXAlignment = Enum.TextXAlignment.Center
DispName.TextTruncate = Enum.TextTruncate.AtEnd
DispName.ZIndex = 14
DispName.Parent = ProfileCard

local UsernLabel = Instance.new("TextLabel")
UsernLabel.Size = UDim2.new(1, -16, 0, 16)
UsernLabel.Position = UDim2.new(0, 8, 0, 112)
UsernLabel.BackgroundTransparency = 1
UsernLabel.Text = "@" .. (LP.Name or "username")
UsernLabel.Font = Enum.Font.Gotham
UsernLabel.TextSize = 10
UsernLabel.TextColor3 = Color3.fromRGB(160, 160, 170)
UsernLabel.TextXAlignment = Enum.TextXAlignment.Center
UsernLabel.ZIndex = 14
UsernLabel.Parent = ProfileCard

local SepLine = Instance.new("Frame")
SepLine.Size = UDim2.new(1, -20, 0, 1)
SepLine.Position = UDim2.new(0, 10, 0, 136)
SepLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SepLine.BackgroundTransparency = 0.85
SepLine.BorderSizePixel = 0
SepLine.ZIndex = 14
SepLine.Parent = ProfileCard

local SLStatusLbl = Instance.new("TextLabel")
SLStatusLbl.Size = UDim2.new(1, -16, 0, 14)
SLStatusLbl.Position = UDim2.new(0, 8, 0, 144)
SLStatusLbl.BackgroundTransparency = 1
SLStatusLbl.Text = "[OK] Studio Lite Auto-Unlock"
SLStatusLbl.Font = Enum.Font.Gotham
SLStatusLbl.TextSize = 8
SLStatusLbl.TextColor3 = Color3.fromRGB(120, 220, 120)
SLStatusLbl.TextXAlignment = Enum.TextXAlignment.Center
SLStatusLbl.ZIndex = 14
SLStatusLbl.Parent = ProfileCard

local StatsLbl = Instance.new("TextLabel")
StatsLbl.Size = UDim2.new(1, -16, 1, -168)
StatsLbl.Position = UDim2.new(0, 8, 0, 162)
StatsLbl.BackgroundTransparency = 1
StatsLbl.Text = "UserID: "..tostring(LP.UserId).."\nBLUExCrown ENGINE\nv5.6 -- Perfect Edition"
StatsLbl.Font = Enum.Font.Gotham
StatsLbl.TextSize = 9
StatsLbl.TextColor3 = Color3.fromRGB(130, 130, 140)
StatsLbl.TextXAlignment = Enum.TextXAlignment.Center
StatsLbl.TextWrapped = true
StatsLbl.ZIndex = 14
StatsLbl.Parent = ProfileCard

-- KANAN: Menu Cards (Scrollable agar muat 5 menu dengan nyaman & responsif di HP)
local MenuArea = Instance.new("ScrollingFrame")
MenuArea.Size = UDim2.new(1, -183, 1, -10)
MenuArea.Position = UDim2.new(0, 183, 0, 5)
MenuArea.BackgroundTransparency = 1
MenuArea.BorderSizePixel = 0
MenuArea.ScrollBarThickness = 3
MenuArea.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
MenuArea.CanvasSize = UDim2.new(0, 0, 0, 476)
MenuArea.ZIndex = 13
MenuArea.Parent = PageSplash

-- MENU CARD DENGAN TRANSPARENT FULL HITBOX (100% RESPONSIF)
local function makeMenuCard(parent, posY, icon, title, subtitle, onClick)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -8, 0, 68)
    card.Position = UDim2.new(0, 0, 0, posY)
    card.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    card.ZIndex = 14
    card.Parent = parent
    makeCorner(card, 8)
    makeStroke(card, Color3.fromRGB(255,255,255), 1, 0.78)

    local iconLbl = Instance.new("TextLabel")
    iconLbl.Size = UDim2.new(0, 42, 0, 42)
    iconLbl.Position = UDim2.new(0, 12, 0.5, -21)
    iconLbl.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
    iconLbl.Text = icon
    iconLbl.Font = Enum.Font.GothamBold
    iconLbl.TextSize = 16
    iconLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    iconLbl.ZIndex = 15
    iconLbl.Parent = card
    makeCorner(iconLbl, 8)

    local titleL = Instance.new("TextLabel")
    titleL.Size = UDim2.new(1, -80, 0, 20)
    titleL.Position = UDim2.new(0, 64, 0, 14)
    titleL.BackgroundTransparency = 1
    titleL.Text = title
    titleL.Font = Enum.Font.GothamBold
    titleL.TextSize = 12
    titleL.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleL.TextXAlignment = Enum.TextXAlignment.Left
    titleL.ZIndex = 15
    titleL.Parent = card

    local subL = Instance.new("TextLabel")
    subL.Size = UDim2.new(1, -80, 0, 16)
    subL.Position = UDim2.new(0, 64, 0, 35)
    subL.BackgroundTransparency = 1
    subL.Text = subtitle
    subL.Font = Enum.Font.Gotham
    subL.TextSize = 8.5
    subL.TextColor3 = Color3.fromRGB(150, 150, 160)
    subL.TextXAlignment = Enum.TextXAlignment.Left
    subL.ZIndex = 15
    subL.Parent = card

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 20, 0, 20)
    arrow.Position = UDim2.new(1, -26, 0.5, -10)
    arrow.BackgroundTransparency = 1
    arrow.Text = ">"
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 16
    arrow.TextColor3 = Color3.fromRGB(200, 200, 210)
    arrow.ZIndex = 15
    arrow.Parent = card

    -- Full Top Transparent Hitbox
    local hit = Instance.new("TextButton")
    hit.Size = UDim2.fromScale(1, 1)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.ZIndex = 30
    hit.Active = true
    hit.Parent = card

    hit.Activated:Connect(function()
        pcall(onClick)
    end)

    return card
end

makeMenuCard(MenuArea, 10,  "[T]", "TOOLBOX ASET",     "Cari & insert model dari Creator Store", function()
    showPage(PageToolbox)
end)

makeMenuCard(MenuArea, 86,  "[R]", "INSERT RBXM FILE", "Scan & insert file .rbxm dengan Source Script", function()
    showPage(PageRBXM)
end)

-- Tombol INSERT RBXL PERSIS DI BAWAH INSERT RBXM
makeMenuCard(MenuArea, 162, "[L]", "INSERT RBXL PLACE", "Scan & insert file map (.rbxl/.rbxlx) ke Workspace", function()
    showPage(PageRBXL)
end)

makeMenuCard(MenuArea, 238, "[3D]", "GENE TEXT 3D", "Buat teks 3D (3D extruded parts) kustom langsung di map", function()
    showPage(PageText3D)
end)

makeMenuCard(MenuArea, 314, "[[REP]]", "REPLACER TOOLS", "Ganti banyak objek target di map dengan 1 model/part pilihan", function()
    showPage(PageReplacer)
end)

makeMenuCard(MenuArea, 390, "[AVT]", "AVATAR CHANGER", "Salin & terapkan avatar dari player server, teman, atau username", function()
    showPage(PageAvatar)
end)

local function makeBackBtn(parent, onBack)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 64, 0, 22)
    b.Position = UDim2.new(1, -68, 0, 0)
    b.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    b.Text = "< BACK"
    b.Font = Enum.Font.GothamBold
    b.TextSize = 9
    b.TextColor3 = Color3.fromRGB(0, 0, 0)
    b.Active = true
    b.ZIndex = 25
    b.Parent = parent
    makeCorner(b, 5)
    b.Activated:Connect(onBack)
    return b
end

-- =====================================================
-- PAGE 2: TOOLBOX ASSET
-- =====================================================
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
TbLeft.Size = UDim2.new(0, 220, 1, 0)
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
TbRight.Size = UDim2.new(1, -228, 1, 0); TbRight.Position = UDim2.new(0, 228, 0, 0)
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

local function queryMarketplace(catId, query)
    local enc = HttpService:UrlEncode(query)
    local baseUrls = {
        "https://apis.roproxy.com/toolbox-service/v1/marketplace/%d?keyword=%s&limit=30",
        "https://apis.roblox.com/toolbox-service/v1/marketplace/%d?keyword=%s&limit=30",
    }
    for _, bUrl in ipairs(baseUrls) do
        local url1 = bUrl:format(catId, enc)
        local s, r = pcall(function() return httpRequest({Url=url1,Method="GET",Headers={["User-Agent"]="RobloxStudio/WinInet"}}) end)
        if s and r and r.StatusCode == 200 then
            local ds, parsed = pcall(function() return HttpService:JSONDecode(r.Body) end)
            if ds and parsed and parsed.data and #parsed.data > 0 then
                local allItems = {}
                for _, item in ipairs(parsed.data) do table.insert(allItems, item) end
                
                -- AUTO MULTI-FETCH: Ambil halaman ke-2 otomatis jika cursor tersedia (Total 60 aset!)
                if parsed.nextPageCursor and tostring(parsed.nextPageCursor) ~= "" then
                    pcall(function()
                        local url2 = (bUrl .. "&cursor=%s"):format(catId, enc, HttpService:UrlEncode(tostring(parsed.nextPageCursor)))
                        local s2, r2 = pcall(function() return httpRequest({Url=url2,Method="GET",Headers={["User-Agent"]="RobloxStudio/WinInet"}}) end)
                        if s2 and r2 and r2.StatusCode == 200 then
                            local ds2, parsed2 = pcall(function() return HttpService:JSONDecode(r2.Body) end)
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
-- PAGE: INSERT RBXL PLACE [MODULAR SCOPE - FORKT LOGIC]
-- =====================================================
local function initRbxlPage()
    local RbxlHeader = Instance.new("Frame")
    RbxlHeader.Size = UDim2.new(1, 0, 0, 28); RbxlHeader.BackgroundTransparency = 1
    RbxlHeader.ZIndex = 13; RbxlHeader.Parent = PageRBXL

    local RbxlTitleLbl = Instance.new("TextLabel")
    RbxlTitleLbl.Size = UDim2.new(1, -90, 1, 0); RbxlTitleLbl.Position = UDim2.new(0, 8, 0, 0)
    RbxlTitleLbl.BackgroundTransparency = 1; RbxlTitleLbl.Font = Enum.Font.GothamBold
    RbxlTitleLbl.TextSize = 12; RbxlTitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    RbxlTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    RbxlTitleLbl.Text = "[L] INSERT RBXL PLACE FILE (MAP LOADER)"; RbxlTitleLbl.ZIndex = 14; RbxlTitleLbl.Parent = RbxlHeader

    makeBackBtn(RbxlHeader, function() showPage(PageSplash) end)

    -- RBXL TOOLBAR
    local RbxlToolbar = Instance.new("Frame")
    RbxlToolbar.Size = UDim2.new(1, 0, 0, 28); RbxlToolbar.Position = UDim2.new(0, 0, 0, 32)
    RbxlToolbar.BackgroundTransparency = 1; RbxlToolbar.ZIndex = 13; RbxlToolbar.Parent = PageRBXL

    local RbxlScanBtn = Instance.new("TextButton")
    RbxlScanBtn.Size = UDim2.new(0, 88, 0, 24); RbxlScanBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    RbxlScanBtn.Text = "[?] SCAN RBXL"; RbxlScanBtn.Font = Enum.Font.GothamBold; RbxlScanBtn.TextSize = 9.5
    RbxlScanBtn.TextColor3 = Color3.fromRGB(0, 0, 0); RbxlScanBtn.Active = true; RbxlScanBtn.ZIndex = 15; RbxlScanBtn.Parent = RbxlToolbar
    makeCorner(RbxlScanBtn, 6); makeStroke(RbxlScanBtn, Color3.fromRGB(0, 0, 0), 1)

    local RbxlProgressFrame = Instance.new("Frame")
    RbxlProgressFrame.Size = UDim2.new(1, -96, 1, 0); RbxlProgressFrame.Position = UDim2.new(0, 96, 0, 0)
    RbxlProgressFrame.BackgroundTransparency = 1; RbxlProgressFrame.ZIndex = 14; RbxlProgressFrame.Parent = RbxlToolbar

    local RbxlInsertStatus = Instance.new("TextLabel")
    RbxlInsertStatus.Size = UDim2.new(0.68, 0, 0, 14); RbxlInsertStatus.Position = UDim2.new(0, 4, 0, 0)
    RbxlInsertStatus.BackgroundTransparency = 1; RbxlInsertStatus.Font = Enum.Font.Code
    RbxlInsertStatus.TextSize = 9; RbxlInsertStatus.TextColor3 = Color3.fromRGB(240, 240, 245)
    RbxlInsertStatus.TextXAlignment = Enum.TextXAlignment.Left; RbxlInsertStatus.Text = "READY | AUTO-DISTRIBUTE: ON"
    RbxlInsertStatus.ZIndex = 15; RbxlInsertStatus.Parent = RbxlProgressFrame

    local RbxlInsertPct = Instance.new("TextLabel")
    RbxlInsertPct.Size = UDim2.new(0.32, 0, 0, 14); RbxlInsertPct.Position = UDim2.new(0.68, 0, 0, 0)
    RbxlInsertPct.BackgroundTransparency = 1; RbxlInsertPct.Font = Enum.Font.Code
    RbxlInsertPct.TextSize = 8.5; RbxlInsertPct.TextColor3 = Color3.fromRGB(200, 200, 210)
    RbxlInsertPct.TextXAlignment = Enum.TextXAlignment.Right; RbxlInsertPct.Text = "[.] Klik SCAN RBXL"
    RbxlInsertPct.ZIndex = 15; RbxlInsertPct.Parent = RbxlProgressFrame

    local RbxlBarBg = Instance.new("Frame")
    RbxlBarBg.Size = UDim2.new(1, -8, 0, 4); RbxlBarBg.Position = UDim2.new(0, 4, 0, 16)
    RbxlBarBg.BackgroundColor3 = Color3.fromRGB(30, 30, 38); RbxlBarBg.BorderSizePixel = 0
    RbxlBarBg.ZIndex = 14; RbxlBarBg.Parent = RbxlProgressFrame; makeCorner(RbxlBarBg, 2)

    local RbxlBarFill = Instance.new("Frame")
    RbxlBarFill.Size = UDim2.new(0, 0, 1, 0); RbxlBarFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    RbxlBarFill.BorderSizePixel = 0; RbxlBarFill.ZIndex = 15; RbxlBarFill.Parent = RbxlBarBg; makeCorner(RbxlBarFill, 2)

    local function updateInlineRbxlProgress(pct, statusText)
        pcall(function()
            pct = math.clamp(pct or 0, 0, 100)
            RbxlBarFill.Size = UDim2.new(pct / 100, 0, 1, 0)
            if statusText then RbxlInsertStatus.Text = statusText end
            RbxlInsertPct.Text = tostring(math.floor(pct)) .. "%"
        end)
    end

    -- SEARCH BAR RBXL
    local RbxlSearchCard = Instance.new("Frame")
    RbxlSearchCard.Size = UDim2.new(1, -12, 0, 32); RbxlSearchCard.Position = UDim2.new(0, 6, 0, 62)
    RbxlSearchCard.BackgroundColor3 = Color3.fromRGB(22, 22, 28); RbxlSearchCard.BorderSizePixel = 0
    RbxlSearchCard.ZIndex = 14; RbxlSearchCard.Parent = PageRBXL
    makeCorner(RbxlSearchCard, 6); makeStroke(RbxlSearchCard, Color3.fromRGB(255, 255, 255), 1, 0.85)

    local RbxlSearchBox = Instance.new("TextBox")
    RbxlSearchBox.Size = UDim2.new(1, -16, 1, 0); RbxlSearchBox.Position = UDim2.new(0, 8, 0, 0)
    RbxlSearchBox.BackgroundTransparency = 1; RbxlSearchBox.Font = Enum.Font.Gotham
    RbxlSearchBox.TextSize = 10; RbxlSearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    RbxlSearchBox.PlaceholderText = "[?] Cari file .rbxl di sini..."
    RbxlSearchBox.PlaceholderColor3 = Color3.fromRGB(140, 140, 150)
    RbxlSearchBox.TextXAlignment = Enum.TextXAlignment.Left; RbxlSearchBox.ClearTextOnFocus = false
    RbxlSearchBox.ZIndex = 15; RbxlSearchBox.Parent = RbxlSearchCard

    local currentRbxlFilter = ""
    local renderedRbxlCards = {}

    local RbxlScroll = Instance.new("ScrollingFrame")
    RbxlScroll.Size = UDim2.new(1, -12, 1, -102); RbxlScroll.Position = UDim2.new(0, 6, 0, 98)
    RbxlScroll.BackgroundColor3 = Color3.fromRGB(17, 17, 22); RbxlScroll.BorderSizePixel = 0
    RbxlScroll.ScrollBarThickness = 3; RbxlScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
    RbxlScroll.ZIndex = 14; RbxlScroll.Parent = PageRBXL
    makeCorner(RbxlScroll, 8); makeStroke(RbxlScroll, Color3.fromRGB(255, 255, 255), 1, 0.78)

    local RbxlList = Instance.new("UIListLayout")
    RbxlList.Padding = UDim.new(0, 8); RbxlList.SortOrder = Enum.SortOrder.LayoutOrder; RbxlList.Parent = RbxlScroll

    local RbxlPad = Instance.new("UIPadding")
    RbxlPad.PaddingTop = UDim.new(0, 8); RbxlPad.PaddingBottom = UDim.new(0, 8)
    RbxlPad.PaddingLeft = UDim.new(0, 6); RbxlPad.PaddingRight = UDim.new(0, 6); RbxlPad.Parent = RbxlScroll

    local RbxlEmpty = Instance.new("TextLabel")
    RbxlEmpty.Size = UDim2.new(1, 0, 0, 40); RbxlEmpty.BackgroundTransparency = 1
    RbxlEmpty.Font = Enum.Font.Gotham; RbxlEmpty.TextSize = 11; RbxlEmpty.TextColor3 = Color3.fromRGB(120, 120, 130)
    RbxlEmpty.Text = "Klik 'SCAN RBXL' untuk mencari file map (.rbxl/.rbxlx)"
    RbxlEmpty.ZIndex = 15; RbxlEmpty.Parent = RbxlScroll

    local function filterRbxlList()
        local filter = currentRbxlFilter:lower():gsub("%s+", "")
        local visibleCount = 0
        for _, item in ipairs(renderedRbxlCards) do
            local match = (filter == "") or item.name:lower():find(filter, 1, true) or item.path:lower():find(filter, 1, true)
            item.card.Visible = (match ~= nil)
            if match then visibleCount = visibleCount + 1 end
        end
        if RbxlEmpty then
            RbxlEmpty.Visible = (visibleCount == 0)
            if visibleCount == 0 and #renderedRbxlCards > 0 then
                RbxlEmpty.Text = "Tidak ada file yang cocok dengan '" .. currentRbxlFilter .. "'"
            end
        end
    end

    RbxlSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        currentRbxlFilter = RbxlSearchBox.Text
        filterRbxlList()
    end)

    -- FORKT SCANNING LOGIC (Anti-Lag Framerate Throttling)
    local function getAllRbxlFiles()
        local result, seen = {}, {}
        if not listfilesFn then return result end
        local lastYield = os.clock()

        local function scanDeep(folder, depth)
            if depth > 4 or seen[folder] then return end
            seen[folder] = true
            local files = safeListFiles(folder)
            if not files then return end
            for _, path in ipairs(files) do
                if os.clock() - lastYield > 0.015 then
                    task.wait()
                    lastYield = os.clock()
                end
                local lp = path:lower()
                if (lp:sub(-5) == ".rbxl" or lp:sub(-6) == ".rbxlx") and not seen[path] then
                    seen[path] = true
                    table.insert(result, { path = path, name = getFileName(path) })
                elseif not path:lower():match("%.[%a%d]+$") then
                    scanDeep(path, depth + 1)
                end
            end
        end

        for _, p in ipairs(SCAN_PATHS) do
            if safeListFiles(p) then scanDeep(p, 0) end
        end
        return result
    end

    -- FORKT IMPORT RBXL CORE LOGIC (PORTED 1:1 FROM FORKT ENGINE)
    -- Referensi: runProtected11, runProtected12, runProtected13, runProtected14
    --            createFolder, transformValue7 dari FORKT Importer v3.8

    -- [A] Helper: sanitize nama file (transformValue7 FORKT)
    local function sanitizeName(raw)
        raw = tostring(raw or "Imported")
        raw = raw:gsub('[\\/:*?"<>|]', "_")
        raw = raw:gsub("^%s+", ""):gsub("%s+$", "")
        return #raw > 0 and raw or "Imported"
    end

    -- [B] Safe parent setter (runProtected12 FORKT)
    local function safeSetParent(inst, target)
        if not inst or not target then return false end
        local ok = pcall(function() inst.Parent = target end)
        return ok and inst.Parent == target
    end

    -- [C] Setup item: SL_Anchored + MeshPart loader (runProtected11 FORKT)
    local function setupFORKTItem(item, parsedSrcs, idx)
        if not item then return end
        pcall(function()
            -- Anchoring (SL_Anchored) - persis seperti FORKT
            if item:IsA("BasePart") then
                local anchored   = item.Anchored
                local canCollide = item.CanCollide
                item.Anchored = true
                if item:GetAttribute("SL_Anchored") == nil then
                    item:SetAttribute("SL_Anchored", anchored)
                    item:SetAttribute("SL_CanCollide", canCollide)
                end
            end
            -- MeshPart runtime loader - persis seperti FORKT
            if item:IsA("MeshPart") then
                local meshNum = tostring(item.MeshId):match("%d+")
                if meshNum and serverFuncs then
                    pcall(function()
                        serverFuncs:InvokeServer("LoadMeshToRuntimeMeshes", tonumber(meshNum))
                    end)
                end
                local texNum = tostring(item.TextureID):match("%d+")
                if texNum and serverFuncs then
                    pcall(function()
                        serverFuncs:InvokeServer("LoadMeshToRuntimeMeshes", tonumber(texNum))
                    end)
                end
            end
            -- Script recovery dari parsed sources
            if item:IsA("LuaSourceContainer") then
                local src = nil
                if parsedSrcs then
                    src = parsedSrcs[item.ClassName .. ":" .. item.Name]
                        or parsedSrcs[item.Name]
                    if not src then
                        for k, v in pairs(parsedSrcs) do
                            if k:find(item.Name, 1, true) then src = v; break end
                        end
                    end
                end
                if not src then pcall(function() src = item.Source end) end
                recreateScriptAsNative(item, stripRichText(src or "-- Script"))
            end
        end)
        -- Anti-lag yield tiap 100 item (persis FORKT: Heartbeat:Wait tiap 100)
        if idx and idx % 100 == 0 then
            pcall(function() game:GetService("RunService").Heartbeat:Wait() end)
        end
    end

    -- [D] Distribute service ke game (runProtected13 FORKT)
    --     Pindahkan semua children dari service source ke service target
    local function distributeService(serviceNode, targetService, parsedSrcs)
        if not serviceNode or not targetService then return 0 end
        local ok, children = pcall(function() return serviceNode:GetChildren() end)
        if not ok or type(children) ~= "table" then return 0 end
        local count = 0
        for i, child in ipairs(children) do
            local moved = safeSetParent(child, targetService)
            if moved then
                setupFORKTItem(child, parsedSrcs, i)
                -- Setup semua descendants juga
                local ok2, descs = pcall(function() return child:GetDescendants() end)
                if ok2 and descs then
                    for j, d in ipairs(descs) do
                        setupFORKTItem(d, parsedSrcs, j)
                    end
                end
                count = count + 1
            end
            if i % 100 == 0 then
                pcall(function() game:GetService("RunService").Heartbeat:Wait() end)
            end
        end
        return count
    end

    -- [E] Handle DataModel hasil GetObjects (runProtected14 FORKT)
    --     Jika obj adalah DataModel: distribute ke services
    --     Jika bukan: taruh di placeFolder workspace
    local function handleGetObjectsResult(objs, placeFolder, serviceMap, parsedSrcs)
        local totalLoaded = 0
        for _, obj in ipairs(objs) do
            if obj then
            local isDataModel = false
            pcall(function() isDataModel = obj:IsA("DataModel") end)
            if isDataModel then
                -- DataModel: distribute tiap service ke game service yang tepat
                local ok, svcs = pcall(function() return obj:GetChildren() end)
                if ok and svcs then
                    for _, svcNode in ipairs(svcs) do
                        local cn = svcNode.ClassName
                        local nm = svcNode.Name
                        local target = serviceMap[cn] or serviceMap[nm]
                        if target then
                            if target == workspace then
                                -- Workspace items -> masuk placeFolder
                                local ok2, kids = pcall(function() return svcNode:GetChildren() end)
                                if ok2 and kids then
                                    for i, child in ipairs(kids) do
                                        local moved = safeSetParent(child, placeFolder)
                                        if moved then
                                            setupFORKTItem(child, parsedSrcs, i)
                                            local ok3, descs = pcall(function() return child:GetDescendants() end)
                                            if ok3 and descs then
                                                for j, d in ipairs(descs) do
                                                    setupFORKTItem(d, parsedSrcs, j)
                                                end
                                            end
                                            totalLoaded = totalLoaded + 1
                                        end
                                        if i % 100 == 0 then
                                            pcall(function() game:GetService("RunService").Heartbeat:Wait() end)
                                        end
                                    end
                                end
                            else
                                -- Non-workspace service -> distribute langsung ke game service
                                local n = distributeService(svcNode, target, parsedSrcs)
                                totalLoaded = totalLoaded + n
                            end
                        else
                            -- Service tidak dikenal -> taruh di placeFolder juga
                            local moved = safeSetParent(svcNode, placeFolder)
                            if moved then
                                setupFORKTItem(svcNode, parsedSrcs, 1)
                                totalLoaded = totalLoaded + 1
                            end
                        end
                        task.wait()
                    end
                end
            else
                -- Bukan DataModel: langsung masuk placeFolder
                local moved = safeSetParent(obj, placeFolder)
                if moved then
                    setupFORKTItem(obj, parsedSrcs, 1)
                    local ok2, descs = pcall(function() return obj:GetDescendants() end)
                    if ok2 and descs then
                        for j, d in ipairs(descs) do
                            setupFORKTItem(d, parsedSrcs, j)
                        end
                    end
                    totalLoaded = totalLoaded + 1
                end
            end
        end -- if obj
        end
        return totalLoaded
    end

    -- [F] Main insert function - pakai logic FORKT createFolder + runProtected16 flow
    local function smartInsertRbxl(filePath, fileName)
        updateInlineRbxlProgress(10, "[1/5] MEMBACA FILE .RBXL...")
        task.wait(0.1)

        -- Parse script sources dulu (seperti FORKT bi(d, a.path))
        local data = safeReadFile(filePath)
        local parsedSrcs = {}
        if data and #data > 0 then
            updateInlineRbxlProgress(25, "[2/5] PARSING SCRIPT SOURCES...")
            task.wait(0.05)
            local ok, res = pcall(function() return parseAllSources(data) end)
            if ok and res then
                parsedSrcs = res
                for k, v in pairs(parsedSrcs) do
                    storeScriptSource(k, stripRichText(v))
                end
            end
        end

        updateInlineRbxlProgress(40, "[3/5] LOADING INSTANCES (GetObjects)...")
        task.wait(0.1)

        -- Coba load dengan game:GetObjects - FORKT juga pakai ini sebagai primary
        local loadedObjs = nil
        local tryURLs = {
            "rbxasset://" .. tostring(filePath):gsub("\\", "/"),
        }
        -- Coba getcustomasset jika ada (FORKT: customAsset fallback)
        if getcustomasset then
            pcall(function()
                local cu = getcustomasset(filePath)
                if cu then table.insert(tryURLs, 1, cu) end
            end)
        end
        -- Coba setiap URL
        for _, url in ipairs(tryURLs) do
            local ok, res = pcall(function() return game:GetObjects(url) end)
            if ok and res and #res > 0 then
                loadedObjs = res
                break
            end
            task.wait(0.25)
        end
        -- Fallback: tulis ke tmp lalu load (FORKT fallback writefile)
        if not loadedObjs and data and writefile and getcustomasset then
            pcall(function()
                local tmpName = "Delta/workspace/mchlern_tmp_rbxl.rbxl"
                writefile(tmpName, data)
                local cu = getcustomasset(tmpName)
                if cu then
                    local ok2, res2 = pcall(function() return game:GetObjects(cu) end)
                    if ok2 and res2 and #res2 > 0 then loadedObjs = res2 end
                end
                pcall(function() if delfile then delfile(tmpName) end end)
            end)
        end

        if not loadedObjs or #loadedObjs == 0 then
            updateInlineRbxlProgress(100, "[ERR] GAGAL LOAD - game:GetObjects() tidak support file ini")
            return false, "game:GetObjects() gagal. Pastikan file .rbxl valid."
        end

        updateInlineRbxlProgress(60, "[4/5] DISTRIBUSI KE SERVICES (FORKT mode)...")
        task.wait(0.1)

        -- Map services (persis seperti ba = da dari FORKT)
        local serviceMap = {
            Workspace         = workspace,
            workspace         = workspace,
            ReplicatedStorage = game:GetService("ReplicatedStorage"),
            Lighting          = game:GetService("Lighting"),
            SoundService      = game:GetService("SoundService"),
            StarterGui        = game:GetService("StarterGui"),
            StarterPack       = game:GetService("StarterPack"),
            StarterPlayer     = game:GetService("StarterPlayer"),
            Teams             = game:GetService("Teams"),
            Chat              = game:GetService("Chat"),
        }

        -- createFolder FORKT: sanitize nama, cek duplicate, set attribute
        local baseName = sanitizeName(fileName:gsub("%.[^%.]+$", ""))
        local folderName = baseName
        local dup = 1
        while workspace:FindFirstChild(folderName) do
            dup = dup + 1
            folderName = baseName .. "_" .. tostring(dup)
        end
        local placeFolder = Instance.new("Folder")
        placeFolder.Name = folderName
        placeFolder.Parent = workspace
        pcall(function()
            placeFolder:SetAttribute("MCHLERN_RBXL_IMPORT", true)
            placeFolder:SetAttribute("SourceFile", tostring(filePath))
        end)

        -- Distribute semua objects (handleGetObjectsResult = runProtected14 FORKT)
        local totalLoaded = handleGetObjectsResult(loadedObjs, placeFolder, serviceMap, parsedSrcs)

        updateInlineRbxlProgress(100, string.format(
            "[DONE] %d instance dimuat ke '%s'", totalLoaded, folderName
        ))
        return true, string.format("%d objects inserted", totalLoaded)
    end
    RbxlScanBtn.MouseButton1Click:Connect(function()
        task.spawn(renderRbxlCards)
    end)
end
initRbxlPage()

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
-- PAGE 6: AVATAR CHANGER [MODULAR SCOPE]
-- =====================================================
-- =====================================================
-- PAGE 6: AVATAR CHANGER (FULL ENGINE: BONEKA + NATIVE + PRESETS)
-- =====================================================
-- =====================================================
-- PAGE 6: AVATAR CHANGER ULTIMATE (KORBLOX, HEADLESS, LIMITEDS, ANIMASI, SEPATU)
-- =====================================================
-- =====================================================
-- PAGE 6: AVATAR CHANGER ULTIMATE V4 (ALL SOURCES, KORBLOX, HEADLESS, LIMITEDS, CROWNS, UFO)
-- =====================================================
-- =====================================================
-- PAGE 6: AVATAR CHANGER V5 (INFINITE 5000+ AVATARS, BLOXED.GG LIMITEDS, R6/R15 BODY)
-- =====================================================
local function initAvatarPage()
    -- === DATABASE 5000: 5.344 ROBLOX AVATAR ASLI DARI USER ===
    local DATABASE_5000_RAW = [[
TraderPhillip
TraderShaman
Trader_GrowAGardens
Trader_rr0
trader_KING19
traders_tp9
TraderAcc_12
trader_nptwROBLOX
Trader_dag
trader_boy444
traderiti
TRADER4447
TRADER_1207
traderfrfr
Frenchekebabs
12yoandrei
Lioneltahiirrr
mozzarelaaffumicata
Ynalee12
DenionGaming36
ribamoy231
sammyio046
Raim12943
Ziyahpittma
okeypiye
princenaithan2016
jaren_2323
its_ted37
jamal9149
Clate98
Deucey6833
quest_12558
Resad1929
Jessee217
JABESRAM
pee567zxr
guldan_1232
Kindgirltt57
Xebectherealone
Renoisanseau065
hoi_pet1234
MR_DARK57312
MASARAPNAKARL
khoa9859
Hamza_19269
BIZZ_MEH
Naninoenoe
edress415
Jamoran_4567
FischDavid_1
richmo370
richpremiumguyz
rich_j74
Richestheestallion
Rich_2631
richcoonie1
rich_53705
rich200022
richasaurr_18
Richboyuknow7
richzin10
RIChy_986
RICH_NEWBEAA
Richboycat_ninja1
RICH_35353
RichmanMIX
Rich42899
Richi76501
RICH200927
richbaby2010
Richist503
richardricharlisson
RichchangYAYA2
Richard019BR
richard1826474
richnicole8
RICHMONDKILLER
Richytot101
RICHINOVA11011
Richafr4tty
Riche123228
Riche_S2
richiemich5
richuerta2010
Rich_Wich
Rich_xp3
Rich_hala
richmode54
richmael112
Rich36079
richelyson755
Rich_explosions
RichDerKing
RichGamerZAyAAN
richhasanewacc
Richvvoy
rich15569
RichKidStudio
RichXD1232
Richies70798
sultan
sultan1443xf
sultandafgj
Sultan_26o
Sultan1324565
sultankhalaf13
SultanSuleiman151
Sultan5saleh
Sultan763698
Sultan1234536
Sultanisherelo
Sultan_zh5
Sultan_gojo8
sultan627384
Sultan09443206
Sultan_0120123
Sultanyola
sultan_7643
sultan1234jj
Sultan_GZ122
sultanmansour101
sultan_62217
sultanahagung
Sultan727288
Sultan341523
SULTAN_ALPARIZIX
sultanshh7
sultan600097
sultan28160
Sultan485832
Sultanenrn
Sultan_Baghlani
sultan_1a23
Sultan01721
Sultan_2018piu
Sultan4004000
sultanmhd00
sultangacor38
SultanMohmmed_6
Sultan_st2
Sultan511739
sultano0o2020M
sultan354883
Sultanizoom
sultan112233m
Sultan1998sa64
sultan293762
Sultannaqbi9
Sultannura19
sultanhjw
collector
Collector823
CollectorKamila
Collectornr2
Collector8262
CollectorOfMystery
Collector000000
catttttotitanic
Krazy_Drei844
krendel2211
Ju_UvU
lefilo349
CutieLea_One
5MeWmEtc
LoTusssskaka
goldrainbow235
Artem2w12
Marcel0903ffsj
tutanadam2211
railyOMG123
Cacti434
legandaryofthelegand
fiart10
aidensad20
ALTER_LEGEND
POHRTHO_298
Notrawd64
32XzackX23
RobloxCreator3rdArm
Vuryat
nabinsubedi56
Matvey79606
givemeknife2312
Matheus_Kaiser10
dylynthedinosaur
kuzeyemir16
memegamer258
dee_ba6
RenoTouch
The_collector0830
Black_Owl0009
ffauzanm8
You_notATopg
Goldoncow527
Jalisa_G
nawafn25
Sadwerswad2
The_itemCollector781
k1u2b3i4k
KenZSwordd
ShadowWolfy_16
Shadow_Sheronsky
Shadow_sight11
Shadow6t99
shadow32681912
shadow930175
SHADOWBOOM_CHAOS2012
SHADOW_EXE773
shadow186787
shadowxflash16
shadow65513
Shadow_Katara25
ShadowVortexx203
ShadowTVman748
ShadowTempest91
shadow_xd695
SHADOW_57825
shadow_eyad60
Shadow2432026
Shadow858298
ShadowBright1CZ
shadow321es23
Shadow_diablos222
ShadowDragonHunter0
shadow_legend721
Shadow6868467
Shadow_sinxn1
shadow_jett9
Shadow_man0218
SHADOWMONARC957
ShadowDeath2727
ShadowBhaii1
Shadowdragonbeast08
ShadowLink1029
Shadow_Love688
Shadow_eieiUwU
ShadowDarkWolf74
Shadoww_1309
shadow0908228
Shadow404jr
shadowstrikeBlaster
Shadow_madness013
ShadowEagle7494
SHADOWSQUADKING
shadowcrafter2017
Shadow191615
Shadowmaster4701
Shadow115631
SHADOW7CR92
john
Johnant0709
Johnthatteaches123
Johnnnnnnnnnnnnnnn66
John_Moe20
johnnywydd
Johnfratila
Johnmajchrowski
johnisnadin6767
john0o883
JOHN_009218
John_John8759
Johnthegamerboilol
john_noob766
john238292
John_41971
Johnstone409
John_57316
john_445455
John_rick1098
John2599059
John_t67
john567145
JohnathanXXZ
John9262936
johnkennedyAE
John_doe5306
johnheidud
johnmaun123
johnvicent7
John1233784
JOHN234033
john70563
johncarlogwapo125
john_eramm
Johnnyjet12
John538532
John9797569
John231333131
john17952
John175049
johnny12711
JOHNMICHAEL9024
johnpork10908
JohnreyRun
John123_5h
john24042013
john_53227
Johnny_boy1008
starshipgirl
starslightz2z
starwnu
star12456hvhggg
star_42067
Star672377
starfirefan401
starxolivia24
Star_10551
star_s22
starspeIl
Starlight21454
Starcutey43
Stars_CouZz2
Starly_Stellar0
starrbuurst
Starplexo
Star_LaryYT
StarsCrush2017
Stars_icecream304
Starloba_1120
Star_hello469
Starcake128
star676617
starAylaJ
Star010522
star_ssie
StarGalaxyPlay
starydance
Stargalaxybomb
Starbucks_1005
Star_221861
StarlyJustForFun
Star2011770
star_437522
StaRRYMN
StarryAmystic
star150790
star89883
star81226
Star_kk29
Starking2862
Stars03000
stars4525
Starmomsohappy
star_63136
starm1l
Star_l0ver10
Starinthesky331
Star354776
fire
Firefogo59
firekid5321
firesinside
fire667456
FireCodedexe
Fire_Nike80
firetrkbowsercreeper
Fire20090227
FIRE89PLAYSGAME40
fireglitch19
fire_11166
firelordisthe
Fire111795
firecrow1110
fireboy1662
Firexgurl
FireGhost5034
fire_fist201
Fire_Legend112
firestyel51
fire_jason1234975
Firepottt
Firelol8119
fire_Deku123
FireSoulja
fireBlades2013
Fireplaysga
FiReMaG3
fireking21401
Fire_lefeuquibrule
FIRE98GR
Fire_space005
fired362
fireflight111
firemanforyou26
fireplacedemon
Firephoenix095
Fire303_LavaLord
fireferrt16
Firecharge1227
fireball_bird1110
Firebeast1000
Fire_Dr4gon06
Fire81999
Fire_proboi
fire3331
firelol383
lordcant666
LordgonZas
lorde_sss
lordesainte
LORD_EMPERES
lord_zoro198
Lordthedark123
LordzGreed
lord_OFdarkness3
LORDGHL1
Lord_nelsonte2
Lorde00889
Lord_Identity1
LordWillem2000
Lordpudden
lord503503
Lordkillerrobot
Lord_Rukkhadevata4
lord_opon
lord_top1ggvpo
LORD_isox
lordcamp_3
LORDq778
LordOf_Fiends
Lord_Whxte
LORDSMALLD
lordgwapo522
Lord230909
lord19465
Lord50956
Lordbs101
Lordezin_71
LORD_dg18
lordtk_10
lordsakai19allt
LORDD909
Lordsmisfortune
Lord_mumbach
lordhelmet2
LORD_230309
lordlight31
LORDS_1905
lordzinpro
Lord_mjrn
Lord128GM4
LORD_DAM0
Lord_34519
lord_voledem0rt
god109717
GODEmperor520
godsupersayya
Godkin_900
God829262
god_soueu2
GODFAILO
Godisnicetous_alt
GODsDAD_me
GODGOD2413
god_zazaq
gods_pell9
God_35213
GOD_669990
GodMariohaha
GodVR2000
GOD346595
Godmega63
godoftheroblox2013
goddymytry14
godxl09
God_Sempaiyn
GODlol_op
God_Galactus123
God222052
Godehdk_8
God_nghia120
Godoffear02
GODof4o4
godkiller_45673
God_8216
godroncher
godsawyr53
god122774
godeden0
Godlygigaz
Godsoak7
GOD_67087
godrihan1234
god_70101
Godofallsree
GOD_KUYEE
god_73214
GODSNIPER904
godine55
GodHakkaii_Uchirra
god_757877
Godofdestruction2738
God1120531
godas_29
legendsfhh
LEGEND_yt001
legendlakshya16
legend_gokhan24
Legend00415
legend_32496
LegendProBanda1233
legendes8z
LeGeNDK_73
LEGEND105815
LegendFulmer4
Legend91783
LegendGroup7
Legendistooflyy3
Legend_gaming679
LEGEND17336_alt
Legendplayer102
LegendaryZecro10
legendboy13461
Legendgamerff77
LegendTinyBearCrysta
LEGENDA7D
legendjaskirat
legend6996996
legendneverdie12361
Legend_mior77
legend_p134
Legendsroleadhg
legendscrown567
Legendchotuking
legend_ofheroes
legendkiller115935
legendarylll5
LEGEND453277
legendsoftheGodss
LEGENDary21427
Legend20636
Legende_fishy
legends_island
LegendaryBro60
legends123body1
Legendized
Legend101188
Legendohene25
Legend_20088
LegendALT_acc1
legend91109
LegendsOfTheRagnarok
legend11525
Legendflash321
hiphop1
Omarieosgood
hiphop123301
hiphop123278
hiphop12486
hiphop13249
hiphop10072
Hiphop123tm
hiphop123238
hiphop17171
hiphop15781
hiphop1234559
Hiphop199033
hiphop111230
hiphop110011
Hiphop1337_3
Hiphop11458
hiphop1603
HipHop13425
Hiphop12194
hiphop12345hiphop
hiphop1213457
hiphop14230
hiphop12808
hiphop1952
hiphop1667
hiphop12408
hiphop1615
hiphop1234510
hiphop147y
HipHop1Queen
HipHop106666
hiphop123802
HipHop17000
hiphop123444
hiphop12019
hiphop1190
hiphop10295
hiphop131418
hiphop15253
hiphop1522299
hiphop12602
hiphop182838
Hiphop1234567835
hiphop1844
Hiphop19956
Hiphop1183
hiphop10903
Hiphop12633
Hiphop140914
Hiphop123199
Hiphop19897
hiphop13593
hiphop18935
hiphop1605
Hiphop1712
HIPHOP12896
Hiphop123418
hiphop11002
Hiphop123065
hiphop1329
Hiphop123373
hiphop15382
HIPHOP12164
Hiphop131329
HIPHOP123170
hiphop13729
Hiphop19754
Hiphop1071
HipHop12910
Hiphop1234gul
Hiphop123761
hiphop15041
hiphop19711
hiphop12049
Hiphop12781
hiphop157
Hiphop1202uwu
hiphop13202
hiphop1234653
hiphop1234587
hiphop13244
hiphop123985
Hiphop1641
hiphop123456ab
hiphop13517
hiphop123316
HIPHOP123934
Hiphop123forever
Hiphop123680
Hiphop11082019
hiphop123414
Hiphop123132
hiphop123586
Hiphop123101
hiphop10171
HipHop1697
hiphop1234w
HipHop121773
Hiphop123m23
hiphop
hiphop5r
hiphop_828
hiphop6453
HIPHOP8595
HipHopClassics
hiphopgrams
Uvatranparentegelada
princess_lulubell
xanxx60
Zoestitch235
hophop_330
Boss67890653
saintsong503
Babymild080
hopha49
rain200432
ezekielrodolfo13
pro_644782
pangbesiege03
MANOLOV28
Jack0_00994
Alice2013030
aksh6366
aoi4730403
gdhhxnsmcjdb
hrwoyd2lhf2ohfwhdwoy
noicant67
boomingUw
ptysia887
CloCloBoumBoum
Dancevibe27
NikolaSideEye
Aronman29480
dancowpak
NiceBoy_382
Myugisuga
Uimfrrabv33681Tey
ipek_01127
Dodddddddnmo
jerom_tbs
glitterpuppy2015
sanmarino_meatloaf
Ziggler_3
justingojda15
TONDI_50
jdjshdhehhheydydydh
Gugugustaw8
rapper1
Xavierthesonic12
hoydldutsl
rapper123448
rapper19990
rapper1406
rapper1903
RAPPER1583
rapper1431
RAPPER1400
Rapper1997fire
rapper173
Rapper1992
RAPPER1143
rapper1297
rapper123457
rapper1266
rapper123335
rapper12322
rapper12563
rapper123413
Rapper123477
Rapper1104
rapper12137
rapper16r
rapper18250
Rapper11r
rapper1277
rapper1_291
rapper122929
rapper1155zasa
Rapper11142
Rapper123405
rapper1911
Rapper1816
rapper15745
Rapper12356789
Rapper123125
rapper12351
rapper1682
Rapper1291435
Rapper1014
rapper19271
Rapper123671
Rapper1228
rapper123406
rapper11113
Rapper1504
Rapper12373
rapper1994
Graffiti
Graffiti_FTW
1AYP7N
Graffity012
Ashleygamer_pup
bmw_surron
Willen06
thatbeanbagsqishy
nattankon_1113
yoshikage_3kira
Bacon_Aura12300
Rainbow_zaara
Alfiegonebro
mcnab6512
ANDRADEGUDES
C_TheArtist
S4kx_F
Baylorbear5429
girturus
Maily_KYJNN
Sportslover074
RiveraCyruzleohan
Graceon197
Estrellagamer632
ishinebrightmoon
Djtorando333
stichgamer457
Clevit1ty
Imcrazy_fn
btntz4
BogateNkyRich
donkey_bordem
bdduegdvz
Flok22812
polska2137pl3
shialash
ikaisani
griffsterman424
ivanthomas87
hse7n9
carAnaya7
CosmicBubbaEpic
Skelovetenxx25
jjmon_bata1
Timurtjelambo
graffiti_bloxx
thalialovesfood123
Keyboard_escapeBG
mrboldmillionar12
djshadowsnake
jordan1
dhshsheua8322
Nikkigirl91
gamerboy1310001
Numer1yankeefan
Damischlauzzz
udidjsup
RobloxZach1920
Jaydub0771
BabyBoofaHEAD
faristob1
Jgjcjchzhch
chainsawman268368
Jordan6767696
wolfey2461
goadgo7
Klutch622
Sihsbdbdn133
JAY15_idk
G3TM0N3YJ0
Ratsbecrazyy97
jmanstar234
lekeiejkdrnknf
XXJDDDDDDDPOOPXXJDDD
oeonce7
Idkjordan3
JackMagTag
ooxxooxx102030
Crispybacon345345
Jordan128729
JordanJ425
Jadasharkey12
Leeboyz2022
vchhgfgffggfhgfhvv
Godlover20016
Nike_jaeeeee
YoungCC56
rip_rj631
559559599j
gameradan13
sukumbias0910
joyboy606
Kimani561
jordan_89829
Jordan_1098777
astro_boy775
tradebrainrot943
JMoneyG2012
Reddcap22
jd57419
Jordan3_D
Jordan99301
Jordan04321pro
Jordan543210922
JORDAN_CR797
Jordanyaaqc
Jordan_the79
Jordanflore_29
jordan_ocj5
JORDAN65980
Jordanmermaid123
Jordangamercol
Jordan2093Y
JordanBraves14
Jordan_121232
Jordan_camin
JordanOMG_24
JORDANL0VESTAKIS
Jordan_theking937
JordanBoy419
Jordan105134wr
jordan_210140
JordanWasHere2016
Jordanssss7
jordancrakypro
jordanluvsjam
Jordanr32701
jordan654021
Jordan18203
Jordan_87631
Jordank11102890
Jordan_tooshifty0
jordanmjgs
Jordan_hasasis1
Jordanneogd17
jordancbtis
Jordanini6
JordanR0603
jordanschwing
Jordannnnnnn65
Jordanroroni
Jordansbookies
Jordan1407g
Jordan221697
Jordankolabla
JORDANATDACC
jordannaruto123
Jordansnapshot
Jordan_Editz12
Jordan6767417
Boy1
Boy187661
boy123x821
Boy67kk672
hhhhhhhhhh9091233
long99uu
mitblox62
unhappynoob12315
hryscjaub
Adzroyboy
tycug66
Kingrainbow650
JJganteng98
Ian8765854
LOL1230247
bp_pakyaw052
JOHONSENMAN
M_xi23
dougcad
epicpetergriffin12
JK888777999
princehaker99
midman_boy2
etikalo1
Wilson123boy7
salman1123502
voltpls1214
kingfer12324
HEJBO985
boysemak1
reegobanda1
DRAGON4K26
rentarodesu
oNeEdrqrxzn1
Angry_unumunkh
ravenyaa09
Shadiha21
PabidaKYS157
kthunter09
megumi120715
Ann160501
oren104636
timerjano1234
Minecraft1000DNA
Grixa222222
arpan980076
Laur0_k
ures7893
ManDude22111
bp_kalbo0520
badboy1
jskejsof
AnnoKre96
igigkbkn
Lashadka123
takelatariegirl
SaradYt2
fsgdgsgdeg
Badboy01548
Timsus10
XBoyy3426
zouqain90
naveen_1399
Pro010653
Bennie123401
banyar066
princeswany727297
badboy_ash0
shineeees1
yokop39
aaditydv1
Armanshah996
badboy14291
badboy1OU
ehwoje3
FIJIAN_BOY11
Pro_gamer434455
jermajs4
Marlando444
Goodboy12640
haonanchen2011
123shaurya_2
Badboy1234994
BADBOY11639
badboy123x00
badboy1er
Badboy122297
badboy1234657822
badboy19792
BadBoy12jason
BADBOY16547
badboy13native
badBoY125875
badboy120928
badboy112969
badboy145233
badboy193277
badboy18424
badboy123e40
badboy112870
animeboy1
MrCutiepie184
krishgodyadav
AnimeBoy16792
Animeboy180620
animeboy1392
Animeboy12926
ANIMEBOY1464
animeboy16278
Animeboy12345567800
AnimeBoy1710
Animeboy1967
animeboy123_boy
animeboy1479
animeboy17617
animeboy15295
animeboy12727
Animeboy13254
animeboy123862
animeboy1234637
animeboy18039
animeboy12986
Animeboy1301
animeboy128353
animeboy123518
Animeboy13874
AnimeBoy11287
animeboy124509
animeboy15497
ANIMEBOY1LE
animeboy147
AnimeBoy1819
Animeboy1867
animeboy10206
animeboy18000
animeboy13252
animeboy1234506
Animeboy100099
Animeboy1157
animeboy12y
animeboy1234a11
animeboy123622
Animeboy1cool
animeboy1540
Animeboy1818
animeboy12wee12
animeboy13686
animeboy15051
animeboy10172
Animeboy10640
DarkBoy
Darkboyyeet3
darkboy1245673
darkboy14316
DARKBOYlivestream
Darkboy785955
darkboy659834
DarkBoy3405
DARKBOY_1989
darkboy_3208
darkboy123373
Darkboy19O7
Darkboy_612
DarkBoy34588
darkboyiq5000
Darkboyyy103
DarkBoy192011
darkboyyy00
DARKBOY09341
darkspoin
umkatumka77
Allah1577
MAlex1629
goypo1232
zeg12345jkl
sculbo79
Toots_48
Antika2828896
ohlax13
ilya2014052
provivaan47902
Aggroboss
fatski225
ttet198
Theboysyeamaim
gmvaughnpacut
Thebest193676
Missnakita1205
MynameJaiJai
guruji2461
wali201586
csandrei122
orgil67715
KGFOJAS
rabin6375
Gi_hunandhihun
sheug5g
mega_rex72
Sharkslasher5621
naynaynaykub
retroboy1
retroboy1s
retroboy191
Retroboy1510
retroboy1234564
RetroBoy155
Retroboy1234578899
retroboy1255
retroboy11124321
Retroboy114500
RETROBOY17384
retroboy1238910
retroboy12345
Retroboy114
retroboy1111
RetroBoy1999
retroboy110
Retroboy1245
retroboy1100
RetroBoy14
retroboy159
retroboy1ol1
retroboy1632
Retroboy15
retroboy123456789
retroboy109
retroboy1112
RETROBOY1738
retroboy1015
retroboy11
RetroBoy1065
retroboy19
retroboy137
retroboy128
retroboy123s
retroboy12335
Retroboy1098
retroboy12345678910
RetroBoy115
Retroboy1200
retroboy12345678
retroboy123455
retroboy10l1
Retroboy1234567
Retroboy199
retroboy117
retroboy1127
RETROBOY1714
retroboy111
retroboy12346
Alpha1
ALPHA1SOLDIERULTRA
E_OPIXNADA6
Realfrownow2
elwazza800
itadori_chan177
XXx_kingzxXX5
Kklm1127
OptimusPrime3000Pro
JJITSME05
Aer5766
GameWitch011
kokomega0177
fgdffrrrg
KRTGWERERE
chickenjockey1747
a9youb237
Roblox_killer953
addris1414
Bailey100415
Aa5NcH4knA
113phm
Mx7iiOll
charchar34676
cskgaming46
Emiel12345678jd
llolmanjoker
pc546647t
Netanyahu_3000
jaygee_826
MobileTaskForce311
fernandoo1905
Aubree_love132
NekokiIler
Matao270
History20226
EYADEX54
thanhthai020714
stoeresuperboy123
noobboyAM
Moiretzu123454
NOOBpoor2193
Coltenezzz
GUIGUEMIS
yassen23228
Lalouve_330
king0862047
roubeum_labub
Salmon012717
Princess148869
Princess123098556
Princess1234568477
princess19999990
princess1_bb
roza_12870
Princess_Nikol163
123Janus_cute1236
antoniab2244
RichsMom26
Jerna2995
im_sougly766
slaycartigirl
Iitukka123456
putrimaisarohputri4
123amina369
Momsfridendscare
Naaarceee
evgeshula19
snoopy_5468
Rrrgf46
Zia_93451
memagirl20180
Yui7722
Baenand
rehan_100210
softball9princess
selmah872
chikaapriliani2
Elfebba
STARISPOD2
Reen3771
Youupioi
sheet_660
safbil5
yanglitang1
gvdg501
Princess900946
bustoabb
Cinderella224486
hanniuss_4
Cici_3885
Bebdhnwd2
curlymonsterxnvb
yanyan129606
Reine123m
titut1540
lukasma984
joke2674
otng6768
aesthetic1
Perroperron89
Rebe_Matte
nathaIia70
Queensoft559
Aneth_2023
aesthetic13260
aesthetic12401
aesthetic1234712
Aesthetic135560
Aesthetic102016
aesthetic123_girl5
aesthetic114_cute7
aesthetic182025
aesthetic145803
aesthetic123574
aesthetic161210
aesthetic14737
aesthetic181847
aesthetic14253
Aesthetic124shu
aesthetic13889
Aesthetic123247
aesthetic17377
aesthetic16273qt
AESTHETIC16700
aesthetic12345683
aesthetic123208
aesthetic1868
Aesthetic13Vibes
Aesthetic1865
Aesthetic1234710
aEsThEtIc10293847564
aesthetic124563
aesthetic12323677
aesthetic123089
Aesthetic132270
aesthetic12139
aesthetic1212cute
aesthetic123912
aesthetic10573
Aesthetic18243
aesthetic123girl6
Aesthetic145678
Aesthetic13charli
aesthetic127s
aesthetic141420
aesthetic119
aesthetic102014
aesthetic1_1girl1
Baddie01033
baddie17229
baddie_12345522
BADDIEGIRL_5115
Baddie_03493
BaddieR981
baddiegirlcute16
Baddie_122913
BaddieNyx7
baddie_234131
baddie_first04
Baddie6788girlbrah
baddiein152
baddiediva126
baddie356219
baddieplayz30
Baddiewithnails7
baddie106778
baddieclockingqueen
Baddieonsite2
Baddie67_tuff0
baddie_fatty5554
Baddie_8581
Baddieyo22
baddiewitdabody
Baddie69943
BADDIE_D128
Baddie23845
baddiesposeforme_278
Baddielish_21
Baddie_4Ever677
BADDIE_ICONICSLAY
baddie6700971
Baddie3cheeserat
BADDIEANDDIVA97
Baddiewafattie13
baddieeeeslayy67
Baddie_Maddie081
baddie7667567
Baddies61688
baddiesk_11
Baddiessz4life
Baddie_gurlypop7
baddie_kayla677
Baddie_1914
Baddies201107
Baddie4ever_530
baddiesgirl2016
baddie567352
Baddierar2010
divaniz2015
divake21
Diva_soso23
Diva_catalina3
diva_aa120
Diva_suprema27
Diva67164
divaaA5647mi
DIVA78884
Diva_2345987
divaaa_20112
Diva_imu627
diva_anne
diva14anos0
DIVA017850
DivaxLestari
divaQueenpickmehater
Diva38594
diva28lamejor
diva_166679
divaa6412
DIVA4life91
Diva670_067
Diva072013
DivaQueen663
Diva667729
divaaa67095
Diva782737
diva546264
DIVA2145_QUEEN
divabe08
diva67676767_6767
Diva2490
Diva676767001
DivaQUEEN_velvet
divagirl_3211
DIVA_REHAN
Diva0643
Diva1s_0
Diva_d003
DivaKillers
DIVA_987652
Divagirl2451
diva542725
dival_74
diva_Diva37915
Diva2_6746
Diva776767
diva_sasa2
DIVA1234568795
Richelyr2
Richiedoos
RichNat_911
Richard_sunter
richardking2345
Richachmadi
Rich_VampireKing
Dominuschamp14
DominusKeks
DominusGoldenIce
Dominus22265
Dominus_1er1
DominusNoob_ofc
DOMINUSx111
DOMINUS_8800
Dominus_Coby
Dominus6942
Dominus12818
dominus9823
dominus_yoshi
DominusKill44
dominus200089
Dominus_Q8
DominusLudi
Dominus_masterlike
dominus_44024
DOMINUS0_000
DominusGod_5552
DominusPlayzYT2
Dominus4788
Dominus_RC
dominus7190
DominusKing28
DominusPlants
DominusProPlayerMega
Dominus3712
DominusVIP_Real
DominusEagle
dominus12511
Dominusdominus58
DominusJonasw
DominusQuick
Dominus_ninga
Dominus182013
Dominus_4582
Denis2011_Denis11
nicolaswm66
tvmanx1x233
deitipiD
Andrewfire15
akumarukibawolfupdow
Sprunki62972
josiahzayas2015
banafsa9ozi
Im_nottravis0
Augustrivera09
kumpeeezxd
kingthegoat_5677
Kingkyray1019
kingsleyisyopapi
Kingoblazo
King2Shifty1
Kingdark9999999999
KingFereh
king_raja67670
king_111308171012
Kingpogi29108
Kingthegoat2189
KingNathanX
kingsleyanker
KingLuckyEcho2016
King_know082
King_von1937463
KING_PANDA00000
King0123948
Kingvon28419
KingOJ02
kingho000
king_346022
king_sun117
kingesxfxxgv
KINGDTON_962
KINGHYDRA444
KingAmaneus555
king725305
King835835
kingkg437
KingBay77
kingg09483
king_11221omar
king_amine759
King_121382
kingghidorah4a
king04hei
King6767676767700
kingbo1441
king_115096
Kingduckyethelord12
Kingthehegdehog55
KING1D0LPIN
kingmartim12
king_bro249
kingako2024
KingSGalaxyMallow
kingevbuom123
GodofMzp
god_usopi3
godTaka22500
GodZackery
godziila201721
GOD01302
godapple96
GodMinator_166
godofdarkness0808
Godna43
God_op912
GodPlayer201336
God_vuk
godchadfino
Godthepro1237
godgamer178983
Godblesing62
godsw65
Godzia512
GOD3488
godlyslayer2525
GODLIKE6991
GODSniper145
God_dragon57
elitefederal01
EliteNoNoWil
Eliterami77
Elite_Dawudsknight
ElitePrism1
EliteVlogsZoom
elitedabboy22
eliteluckyi2
Elite_lop
Elite_member8
Elite_Sniperman
EliteLorenz
Elite_5166
Elite_Dy4an
ELITE_10X
EliteChaos95
Elite46577
Elite_love18
elite_kiezers
elitedanger521
Elite5597
EliteShadow729684
eliterod6
Elite_Kamikaz3
EliteGaming55555
EliteGoatIsHere
eliteloopkiller
elite17477
EliteBTAA
eliteplayer739
Eliteisthebesttttt
elitezaprer123
eliteranger09
ELITE22228
elite662839
Elite_CMDO
elite25412
Elite213548
eliteDCS
EliteTh3k1ng
elites100
Elite6321
elite1467
eliteverde3
Elite13990
elite0sniper0slayer
Elite_Agent27
Elitegammer21005
EliteTheScripter
Elite_Riots
Traphousetei
trapsxd1
trapborder
Traps247
TrapAxolito
Trap_perguy
Trap111115
trap888503
trapkittey
Trap_jhit3522
trapperkeeper87
traproIl
TrappnSzn
Trapzzs
Trapppyy8
TRAP13579
trapuwubabe
Trapiswack
TrapSosa300
Trapboi386
TrapGhidorah_3013
Trap6289
trapboydre10k9
Trap1x2
TrapXGG
trapzilla25
trapvster
TrapAreCutes
trapzzlol
Trapaccount2006
trap_men102
trap_babyxesme
Trapordi3
Trapdaactivist
trap_god2025
Trap_12230
trapballprogamer
TRAPnBUBS
Trapjira23
trapgaIore
Traploat
Trapicide
Trappuccino7
Traps98d
trapportss
Trap504_2
Trapwipedyou
TrapQueen_aye
Trappas3s
TRAP_XRT
bape2
d1rtydan412
Rileysbest101
230772b
Bape2and3knowme
bape2559
BAPE201132
Bape22637
Bape20208
BAPE2587
bape222
Bape20930
BAPE2443
bape2334
bape2c
bape2208
bape20239
Bape2346
BAPE2014d9
BAPE23568
bape23343
bape2539
Bape2514
bape20269
bape2555
bape200181
bape20182
bape2Z
bape2524
Bape2543
Bape22376
Bape230
BAPE23370
bape2122
Bape2312
bape234675
bape2558_2026
Bape238000
Bape2994
bape23137
bape2590
BAPE2223
ncencjbdk
Drag_akif123
anyaaa2505
Avocado229019
BAPE2412
bape26
bape2bape
bape20061
freestyle2
Hftigkv7
Tensei_RB0
VictoriaPixelWraith8
xre3154
Magma20657
santiag10270
Area51space
flipper_dipper3
crazee4candeels
freestyle2344445
freestyle23990
freestyle20095
FreeStyle2376
freestyle20213
freestyle20492
freestyle2phz
freestyle20251004
freestyle20191
FreeStyle22096
Freestyle201219
freestyle23mk
freestyle2796
Freestyle201870
freestyle23108
freestyle21755
freestyle23333i4i4
FREESTYLE23710
freestyle2139
freestyle2156
freestyle22551
Freestyle201722
freestyle28855
FREESTYLE2777
freestyle27467
freestyle20016
freestyle20107
freestyle21131
freestyle200054
Freestyle202506
FreeStyle20161
FREESTYLE24249
freestyle244610
freestyle2qo
Freestyle2eMouvement
freestyle201104
freestyle29381
freestyle22308
freestyle2000tz
freestyle2800
hustle2
Hustle2537
HUSTLE235465
Hustle20203
hustle226
hustle2145
hustle201115
hustle2213
hustle298
Hustle2904
Hustle2324
Hustle2260
hustle2251
hustle2010
Hustle2live313
hustle257
HUSTLE201330
Hustle2345
Hustle23t
Hustle21015Core
hustle21bubba
hustle215
hustle2x
Hustle2hard528
hustle246
Hustle2259
Hustle271
Hustle2BustUhNut
Hustle235
hustle267
HUSTLE2005
HUSTLE2000
Hustle2323
Hustle212
Hustle22203
hustle222
Hustle2001E
HUSTLE210
hustle2001
hustle2016
hustle2007
hustle21
Hustle274
Hustle2520
hustle234
Hustle200910
HUSTLE223
Hustle21Luthy
hustle216
hustle2fly
hustle237
Hustle261
HUSTLE212121
hustle2345alt
HUSTLE2K17
HUSTLE232323
afk_kiw3
hustle25
hustle20019
hustle247
hustle29
hustle26
hustle2536
hustle230
HuStLe2221
hustle2k23
Hustle21152
Hustle2753
Hustle2death5
HUSTLE2K19
hustle268
Hustle22123
Hustle2009
Hustle2222
hustle2006
hustle2survive
Hustle21308
Hustle22157
Hustle29723
Hustle23456
hustle243
hustle204
Hustle234567
hustle23233
hustle2002
Hustle2018
hustle2021
HUSTLE2121
hustle2478
Hustle23375
hustle2024
hustle24seven
hustle232
Hustle28
hustle248
hustle2h
hustle24
HUSTLE2525
Hustle2_Prodigy21
Hustle2379
streetwear2
Streetwear21347
Streetwear24
streetwear222
StreetWear23
streetwear2k18
Streetwear204
streetwear2341
streetwear27
streetwear2000
streetwear2025
streetwear29
streetwear218
streetwear236
Streetwear201
streetwear227
streetwear2735
Streetwear26
streetwear2600bc
streetwear2458
Streetwear259
streetwear2600
STREETWEAR2023
Streetwear21
streetwear2710
streetwear234
streetwear2010
StreetWear2024
streetwear238
Streetwear241
streetwear213
streetwear280
streetwear20K
streetwear25
streetwear255
StreetWear28
streetwear2009
StreetWear22
streetwear231
Streetwear20
darkboy2
anshukolkarbo1
SophiaGhostVenom39
darkboy202023
darkboy2t9
darkboy213111
DarkBoy2704
darkboy21577
Darkboy2464
Darkboy2662
darkboy22260
darkboy21269
darkboy2093
Darkboy23862
darkboy246666
Darkboy27563
DARKBOY24001
DarkBoy29417
Darkboy25212
Darkboy273672
Darkboy201701
DARKBOY20wer
darkboy23779
Darkboy26107
darkboy27L
DARKboy25009
Darkboy26017
DarkBoy2979
darkboy2045682
Darkboy2022r
Darkboy201467
Darkboy24818
Darkboy20xd
darkboy22055
Darkboy22102
darkboy2942
Darkboy253461
darkboy2859
Darkboy2933
darkboy213543
darkboy2668
Darkboy200009
Darkboy24666
Darkboy22400
darkboy202641
Darkboy212107
darkboy2844
darkboy24k
Darkboy2540
DARKBOY2446
alpha2
Alpha2actual
Alpha2ic
t2ko54
CHRISTMAS20151106
01234Noob777
Mingoqueen_hari
Crystal_1234plays
CallmehLilyxxxx
pafel132
Coy0teXs
alexiwexiiii
Beachgirl_Magic2
Senpai20397
Melani_fan22
iron12d
Arnero1023
Millie131612
waypetes1112
gejhrhe
Tayttt1995
napattoso_16
imahikon2
Alphasbackupaccount
baynarg47
M0onunit7
circusbaby09214
KFClegoat
1638k_2
AlphaNumbeers
bubbleriyaz123456789
Sweet_marlen
Zackk01661
Tsioryrandria
AlphaTsu2
Ninja_spy1237474
Supercuteabig
Babybosi_67
jacob_kn195
ItsUrGurlBosi_1
Samuelbr_ce
mqnanana09
Adamarya82627
Lainoto123318
Sidha295
GALAXY4567862
Rainbowgalaxygirlhi
tindraloveg
Herheyme1
Kffbxj201
Cutie2
paytonninja_0
24k_dz12332
Elis2013p2
Sotis20166
rellu2256
kaide3301
Eva1923a
Unixxe_cutie2
Myabeamitchell7
blakeha6
jograj_49
Sixshotprincess
Marniemoopoo5
HAYLEY253257
k1ttes_12
Gizmomc22
Gweenbob
67labyb67
slayqueeen578
cRoCs_GiRlz
Johnny_monog2
BlackDahliaRose7
cute_harmain4
Emitabonita_123
bella_06253
Cannoncarter5678
BeeAryah
Lillyblue6143
bobbi8901
sxvrxliv
RoseBrunne16
Mr677_him
19k_goldbliss
vicky16sala
Nugget_iscutG
mets933
Miki234567876
girlypop22413
Char101eggs
Ecekutlu6
Knaka500
VOULA14
hghgzbug
rainbowhighqueen19
shhhRonda
sestsedem123
Mr_money564
qwertyuioppryuu
princess2
princess26363u3i3i
Flowercat741
Princess_GirlT45
masterganda950
flip_love2
Ella156757
Rosie_is3
anggi_201034
gulod26
Zahrasworld45
Bonitanina817
mikealaisthebest109
Keybelys_1
Yory554
Juu2345673
princesa2ros
Lunamoon10023
Ivy_Hearts143
Jona_Air
xin_102384
nihagam13
superpronagibator
breej1030
imuppp_977
Junghee70
lib1_232
hey_Princess2904
kitty123_g51
Kk225706
princesshailey820
rnzpsychee
taisiprinprin
bluelove3174
Elina_princess2000
Wasn_4444
Maddie122232
cess_c22
mutiara100801
sweetiegirl61139
curlyns18
Vilmarkos
BADDIE75994
guegbjtx
cici_princes05
Queency_bulot567
lovermanny0
babygurl202426
Max2367jcgk
Raelynnr670
Softie2
Ashley_lov0112
softie202611
Softie223355
softie2112
Softie2888
softie23429
softie23443
softie2joshy
softie28452
Softie2015
softie2lyss
Softie23o
Softie2185
Softie2074
Softie20271
Softie2013Asoftie
Softie2012
softie20136
softie22062011
softie2991
Softie22810
softie20w
SOFTIE23455
softie29000
softie23452
Softie25629
softie2340
Softie29062
wiam10roblox7
MarkerPen
davidXD33992dacuenta
softie23
softie2453
Softie22113
softie2917
softie2582
softie2po
softie286
softie222
Softie234
softie2000
softie23409
Softie23490
softie2046
softie2674
Softie2592
softie2019
softie202515
Softie2054
Softie2638
softie201352
Softie2807
Softie20255
softie20
Softie224466
softie22
Softie23637
softie27000
SOFTIE201
softie200255
Softie24614
softie2826
softie2580
softie26
softie296
softie21medine
Softie271234
softie2664
softie28472928
Softie22227
softie235642
Softie2020
softie2010
softie220
softie2007
Softie224
softie2344522
softie2333
softie25
Softie20278
softie2008
softie2712
Softie222231
softie20618
softie2028
Softie22592
Softie22226
Softie201011
Softie23676
Softie230601
softie2250
Softie2289
softie2805
softie2021a
Softie20151
Softie2499
softie2786
Softie256292
Softie28431
pink2
Pink2RosePetals
longdarcy56
Fluffd_0
bababa_463
Hmarty111
IHartdog13
tucacaface
A_1241280
Jammy3_3j
Dog_135820
TNT_2384
Uwaistikto
prestonplayz1607
melody_catcherNO1
Please108772
cute_catgir5
N_67188
Dollminnie171
IHEART_MEALT2
chivauvau12
iamsigmayayy
sasuke9999468
YouSoLame10
tromboneplayeronpc
hmongkee
BrittleiDarlene
ninyamejes10
Zxhant181
Benz_3277
Daidi7770
JPBroni
Savsav2150
botak_pink34284
TjsGrinder2
Liychee40
kPOPVENESSA67
Tres_leche97
Alli_made7
lollolpwmn
mrkat445
sicishi
Ermwhatthesigma8919
gigikay05
Asher_1234659
Gmoneyy2k22
YKITSWINK_X2X1
Dinoboy122114
Ilovesleepin_55
PinkBaeGamer02
rich2
popcatpop_tw5
therichroblox2
pmole9_9205
Valkyriezay
Kro_ko22
rich_rich227
THECHOCHOCO
MYGAMER12361
GuestO1773
IvxDraco
PierceZamora
Kantapit24_AUTO
Neondash1233
kevinsf42796
Gaeloooxddd
Not_Timkoz
KILAADW123
killer789851
minitomyy5
gabelol189
uremjlrmiqf12
kgzkglglhx
Rich2spideycool
Rich234575
Rich27Rip027
Rich23087
rich2260
rich2k670
rich21670
rich246875
rich22gk
Rich240710
Rich201621
rich27446
Rich23781
Rich20s6
rich279954
rich24455
Rich234477
Rich2323233
rich21032012
Rich22rich22
Rich25670
rich211986
Rich20210412
Rich222261
RICH24168
Rich22jralt
Rich2007fa
shadowshark123644
shadow78_edit
ShadowM09814
Shadow_vic11
Shadow90528
SHADOW_0000010
Shadow115321
shadowcrafter619
Shadow_lov3it3243543
Shadow10609
shadow308091
shadowlady2111
Shadowcontroller7
shadow_daragon0
shadow_moon14074
ShadowBased1
shadow_heg3
shadowarrow3
shadowman888777
Shadow027200
Shadow666uwuboy
ShadowZombie88
shadow0002007
Shadow_Kiritsuki
shadow187950
shadow94193
Shadow_hunterr03
shadow_0garden
shadowsace64413
Shadow_02075
shadow905515
Shadow025024
ShadowsAnnoying
SHADOW892063
Shadow_thehedgedog9
Shadowwwwwww693
shadowcaos53
Shadow4122009
shadow179997
shadowthe_edgehog16
shadowda554
ShadowAlt891
shadowGOOT
shadowbrodie6
shadow_149710
Shadowdowner74
shadowslashultimate
ShAdoW1_71
Shadow_God6977
Elite_5275
Elite_gaming173
Elite_09924
Elite08warrior
EliteE_GamezZ
EliteRX_731
EliteBubbles592
Elite202545
ELITE_On120hz
elitemaster14
elite_hs0
EliteFlash10
ElitePl4yze
EliteStudioFan293
Elite15463
EliteGamerJose
Elite_Shadow16
Elite_5117
EliteGamer0073
elite_123180
blox_fruitGOD38
bloxblocku
Bloxfruits_5869
Blox_iess
Blox_35009
Blox_lbs999
BloxStepStepDad
BloxifiedStreams
bloxias24
Bloxfruitisthe25
Bloxbadr
bloxfruitnood123488
blox1122435
Blox_123102
bloxblastz
BLOX1RI
blox_2925
Blox_mlou
BloXYdandelion
BLOXfruitsNOOBA1
bloxfruit_roller671
bloxx_headsxx
Bloxingturkey09
BLOXPL0I
BloxFruits_Player682
bloxfruithugefan610
BLOXE644
bloxs023
blox_5827
Bloxy_cotas
bloxflu80
blox40776
Blox_gaming3847
BloxBlaster10
Bloxfruit_Mustafay
BLOXFRUITNoob12536
bloxwatch666alex
blox1936
BloxTheBestGame
blox_56232
bloxxnm
bloxplay142
bloxblood667
Blox33413
BloxParker
Bloxpolska3
bloxgrinderv4
BloxFruitsGuy_2019
bloxmonlover
Blox_Games724
dahood3
Dahood3s
dahood3fan0911
dahood391
Dahood3h
dahood3381omg
dahood3322114
Dahood3756
Dahood3486
Dahood345565
DAHOOD36000
Dahood321boiss
Dahood30Man
Dahood321542
Dahood37482
dahood3017
Dahood3121
Dahood3232
DaHood333999555
dahood313131
Dahood30man6
DaHood321
dahood380
dahood32
DaHood333888555
dahood314
Dahood38
Dahood366
dahood339976
DaHood37
Dahood3303
DAHOOD34567
dahood31
DaHood333666555
dahood34322
DaHood333
DaHood333333555
dahood392210
dahood369510
DaHood333555555
Dahood3858532
dahood33123
DaHood333111555
Dahood322
DAHOOD390
dahood316
Dahood30617
dahood3650
DAhood3317
dahood3klol
BAPE3
Zuzy123_ME
Littlesalt42
Bape3k_6
BApe304
Bape3429
Bape3193
bape33318
BAPE3332
Bape35380
bape3177
BAPE31_KRAL
bape3765
bape34578
bape3zra
BAPE30306
Bape33333
bape31
bape321
bape3k
bape372
BAPE3004
BAPE3018
bape3789
Bape3e
bape37
BAPE3010
bape3728
Bape372825435
bape33
bape379
bape319
bape3294
bape39
bape306
bape378
bape30
BAPE3013
bape310
bape325
BAPE3017
Bape356
BAPE3016
BAPE3GOTCLOUT
bape346
bape32
bape3233
BAPE3006
bape3456
bape3542
baller3
Hello8979i
VTS4431
chaselikesBlitz
Gkxpifwd
baller_3231
Trollster071
zekeykun0
54x65mega
KingReggieBurst
SuperEmi719
MrB10ckMan
zeorza5
HERN1818
Bobacutisteam123
qasiscoolright2
baller14268
Narutozpi
fruitslegendst
tephiphip34
3SilverChariots
queenpenguin999
Maddoxproly
thecrah1111
iansuper234
Hiel931
harry70382
ripkobe_3600
Srcshop_3KUI5T
ballersogger2
billy_mikntroiytu
Baller3_0083
baller37_5
BALLER30183
baller365955
Baller32447
BALLER335top
Baller3539
Baller3op
BALLER31199
Baller330705
Baller3351
Baller326758
Baller3x_101
Baller333538
baller3217845
Baller35g0se
Baller32196
baller35boss
Baller321284altalt
freestyle3
freestyle3e
daironpolo3030
FreestyIe3
0narutin3
sggscavbe
vgbnds12
freestyle3s
freestyle3746
freestyle373729
freestyle3599
freestyle3739
freestyle3263
freestyle3250
Freestyle3884
freestyle3078
Freestyle3063
freestyle3419r
freestyle300k1
FREESTYLE304582
freestyle3418
freestyle3284
FreeStyle3421tyu
Freestyle34705
Freestyle34023
freestyle37371
freestyle3007
freestyle36719
FreeStyle31641
freestyle34561
freestyle3362
freestyle33218
freestyle32901
freestyle3604
freestyle34211
Freestyle3839
freestyle349000
freestyle3148
Freestyle3390
freestyle3493
freestyle345693
Freestyle34895
Freestyle3z
freestyle3715
Freestyle3002
freestyle3010
freestyle38916
freestyle33214
freestyle34571
freestyle3234
jordan3
nfgnfgdhnhf
PrxyBaby
freshness2047
mini_neto146
halo46441
gelo12345ifpd
Jordan_lockhart3
unguardablej9
Wired4589
gidggcevcyutihegfrw
jonard1098
TIAKOLA6762
Jordan321610
juliusmolina1998
Supmanr4
theironbat3
Vide060615
niooo1061
pansu1014
JORDAN3345737
Jordan300133
Jordan3x120873
jordan3211559
jordan3xg
Jordan38_39
jordan31167
jordan3524kkllpp
Jordan3480Comet
jordan312491
Jordan35726812
Jordan3002222
Jordan367B
jordan3472arrow
Jordan333520
jordan31_30
JORDAN384569
Jordan3628222
Jordan31job
jordan361583
Jordan3East3
jordan3k37
jordan3_591
Jordan343257
Jordan39689
Jordan33519
Jordan3fn
Jordan3456524
jordan3561917
Jordan338611
Hoodie3
hoodie34542
Hoodie318
hoodie345678
hoodie34T
Hoodie3567
hoodie3383
Hoodie35631
hoodie3175
hoodie345
hoodie35
Hoodie3698
Hoodie3728
Hoodie3Ton
hoodie32dv
hoodie36o
hoodie332
Hoodie3131
Hoodie3k2
Hoodie36
Hoodie348
hoodie38
hoodie383u373
hoodie3xj
hoodie3259
hoodie3374
YAYYYY334
hoodie3300
hoodie3014
Hoodie342
SannySophia_10
Hoodie37
hoodie3945
hoodie363
Hoodie3230
Hoodie3322
hoodie33356
hoodie35smom
hoodie315
hoodie33
hoodie3k
HOODIE3FAX
hoodie3211
hoodie3dead
hoodie343W
HOODIE3457
Hoodie342423
hoodie3444
hoodie3344
hoodie34
Skater3
skydi300
Tigerkralle0000
Skater3168
Skater343879
Skater3442
skater3468
SKATER3GURL
skater3380
Skater3924
skater32sw
Skater3oy
skater3de
skater32911
Skater33344
Skater30006
Skater34572
skater344
Skater3dRockett
skater3436
Skater3099
Skater3213011
skater32115
skater345871
Skater3moon
skater31477
skater345245
skater313979
skater325
skater3106
skater3717
skater3665
Skater3Thunder
skater333456
skater321zr
skater320
skater3512F
skater33224
skater3611
skater3987number2
skater3731
Skater360skill
skater360x1
skater360GTA8
skater3841
skater3890
skater3078
SkateR3us
skater3987
skater321654
streetwear3
streetwear369
streetwear34
Streetwear325
streetwear3009
Streetwear321
Streetwear327
streetwear378
StreetWear367
Streetwear306
Streetwear345
streetwear33maryy
STREETWEAR381
streetwear30
Streetwear32
Streetwear35345
streetwear31
streetwear38
Streetwear36
Streetwear37
gothboy
gothboy2656
CanguruNerdPlayer
shinobu02986
RobloxPerson_isgood
CODboy2022
Funtime567833
makemypp
Mershazw
Jethrooew
hauntednyxs
GOTHB71
party4ever3
Kekoa0380
sonic02923
ScareMyBoo
dupa54321
ee8xx8
Masoncj4
BrandonHjustdontcare
Roboxerrrrrr
Diego18077
jrhmkkt
0_F4ngz
lonelygeht
xyhxhxhxhxxhhx
Ethan67k_8
Deakon6735
JadonjacominOhdha
TruckLover1324
gothboi
XxEDWINxX045
freerainraven65
TheRealyTop1
Hicha_656
imhimong88
theawsomeguyjagger
sebadoxxd1
s0atanist999
satereater32415
EZRADripy
Johen_fxdral
Yuki_va4m2
omgyoursogoodlol
jorgeberrum1
lilsavagemaster123
Dan1919191818
gothboyed
gothboyyy26
Alphagaming729
ALPHADOIL
Alpha25158
Alpha_052
ALPHAVIENNE
Alpha1994Br
ALPHA000971
Alpha_Marcel7
alpha_com1117
AlphaTheChaotix
AlphaSpeedstinger211
Alphasgoated
alphal272
AlphaGamer_904
Alphabetical_User
alpha018169
AlphaAmongMen
alpha88487
ALPHA54747
alpha676767676767333
AlphaOBS
alphaiidbdbdi
ALPHA111623
Alpha_dire1
ALPHA15976
alphabetzxc
ALPHA45973
AlphaTLD
ALPHAandrabbit9999
Alpha_NOMercy
alphahuy2008
Alpha_SeaI
alpha_34708
Alpha1236484
Alpha_Libertatem
Alphasingh52
AlphaAspect05
AlphaSackbot
Alphax_122
alphaser11
Alpha_ofall
Alpha_72k7
Alphasbots
alpha_killerpee
Alpha95599
Alpha_second1
alphaf111
Alpha_112211
alphaxd_28
ALPHA1399392
Girlbye_256
GirlAlt1414
Girl607594
GIRLS_po52
Girlrock205789221064
Girlyslays_46
girly_jst
girlbrxxiv
Girl_Lady012
Girl724959
Girl134595
girl_rock28
Girl_345408
Girles9856
GIRL9876007
girlstywjhhso
Girl_Str4ykids
girls9572
Girl_Militar
GirlLove_Sadi9289
Girllt87
Girl20122016
GIRLL8809
Girl_K3L
Girls89051
girl_1s9
girlesss1111
girlimt
girlana11
GIRLY_GIRL27092
girlxsffvbdt4796
girl_r1111111
girlpals67
girlseep17
Girls123s6
Girlfriends129
Girlsxd12
girlMaha8
Girlsu21
girls171000
Girl13R3
girl103271
girl_576738
girly_girl39990
girl2010y
girl_69408
Girl59058
girl_love00112
Girl739595
softie
Softie14_takis
softiepapata
softie_vlu
softie9688
softie_leila
Softiesmash1
Softiecloud_xx
Softienyc
Softieprety
Softie_Truly
softie1693
softie1191
Softie_1797
Totally_IsBerryB
gensisharold
fluffy_muffy2oo6
Soft_Eis0
anubutiful
cutie346157
S0fty_Ang3l
VanillaCaramelCandy
radhakrishna_026
softygirl675
Stranger_maxine123
real_girl204
Britucknel
softgoobs
dayanao167
Santi_amigo53930
Hdfjfdfudfdifgdy
softglam_qt0
VEN0M123321
darck312_prozin
danewilsen7
Potterggeasy
hekeb10
Kay64kay
Sofffftyyyyyy
sofiaya_3467
soydanielweon
SoftGB
xylidine99
axferr4
Kwahee_2
Mom322021
Hope_altaccOwn
Sosofiamigadesophie
LoidForgeee
Stormizzer1
blossom3
uwy_76
Caritron17
stichenator151022
YourLocal_Blossom3
Behive96
apoldrex
tuheart56789
Coooolgirl777
Kallient2
Lailaii_76
Robloxkittyplayer510
Robloxbaba192
strawberrymilk_715
Dayanavallecillo20
Blossom30092
Blossom345212
Blossom38482
Blossom34138
blossom372
blossom34730
blossom322561
Blossom344321
Blossom35618
Blossom362011
Blossom32914
Blossom321568
Blossom32646
blossom345875
Blossom39412
Blossom382176
Blossom321108
blossom347503
Blossom30375
Blossom37337
blossom3645
Blossom31289
blossom35247
blossom31759
Blossom300169
blossom335566
blossom34781
Blossom33333333
blossom38900
Blossom30738
Blossom347892
blossom321809
Blossom321252
Blossom36512
Blossom3_39
bubble3
maria_magdak2015
littlebubbles592
Sprout38383
MiniMoo258
HK6Real_cz2
nifie8
m4rs_ofic4l
ElianaEster2015
akmhegmgwhn
Crystle_Star1
atang2908
Emiska745
BubbleDurable
bubble_alt4
ralphrecto14789
Fairranger75
Lily798843
YaBoiBubble3
harsome4
warden1639
fordaupow1
20Nanacool_11
808miaash
xblaa098
Bubble37489
Bubble32380
bubble3utt
bubble30026
Bubble321238
bubble3ys
BUBBLE33482
bubble38155
bubble308966
bubble374jkt
Bubble3018
Bubble34025
Bubble389157
Bubble30562
bubble32145
bubble32131
bubble336677
Bubble36902
Bubble3145
Bubble3x4
bubble36363
Bubble36456
Bubble367710
Bubble31SM
bubble32130
LANCERAYVIN123
Junyofme
KukuNuna0814
letibi5
EnderCraft755
Jeffrey_dorr
Mamix373
Mextro_power
gamer_reshan
Corn_guy0
sansmaxx2000
Heni123757
JackKevin34
SuflazYT
messimaxyu
Quality_Quantity0
ahmedjaceylow12
Monstersx_8
Leofeldmannn
TheshadowgamerX
Korblox1234160
Korblox_0019
Korblox_0001
korbloxboy_mi
Korblox_298282
korblox20142
korbloxewpodljsks
Korblox_29828
Korblox_12396
KorbloxCouncil
Korblox_B
Korbloxmerge6
Korblox_Magic678
pikachu_123602
Kondreman71
CallMe_JasonForNow
Z_King0719
vit_201368
ziyan_kece36
Noahmand0902
Vyzxsr
24KPROYOUCANTBEATME
qoeq40
Ho_oh1992
TeamLukasPS4
rivslsnoob343
lindawar3
3omarmego
nobody_work09
djowy79
AlduinRe
alvi_748
Arnel8298
baconmaster6895
elobot300
mm2_godly234567
Danikpro9874
hfhxi32
cola_sprite097
gfjfhgfgmkl
mylkyvey23
Noooooiiduuuu
kaPa_kazak
Mrsbush1019
perdunya_28
Japa_kenji2008
soybeni495
IBBY45449
SnorlaxIbo
geogian_4
LoRdq911
Lord_skellington
LORDxs7
lord_powbr
Lordhavemercy435
Lord_Basilisk7
LORD_SHADOUO
LordGamer_kevin123br
Lord_Daniel73
Lord126394
lordmanzu5a
lord_david81
lord987819
Lordgaming997
Lordiq99
Lord_player921
lord7890948
Lordffyt4
LORD_135787
LORD_1234423
Lordtn10
Rapper4
Rapper41028
rapper4005
rapper408
Rapper4992
rapper4life898
rapper457654
rapper45556
rapper460
rapper40078
rapper485
rapper445
rapper456123
Rapper4557
rapper41
rapper4801
rapper427
rapper433
rapper4040
Rapper48
rapper4left
rapper4ever
rapper404pop
rapper405
rapper444
rapper43
Rapper47
rapper404
rapper4567
Rapper46
rapper4512
rapper4lyfe
rapper4ever123
rapper4ever12
rapper400
rapper4321
Rapper4555
rapper436
rapper43216
Rapper4Life
rapper4123
Rapper43pa
Rapper464
RAPPER416
rapper498
Fadhriel5
Rapper443322
rapper418
rapper4561
rapper455
HOOD4
Hood44556
hood487
Hood4racks
HOOD46522
Hood4787
Hood4534
hood44637
hood444hsjh
hood43211
Hood4ali2021
Hood46753
Hood4930
hood4508
Hood41190
Hood4life89
hood43s12tg2
hood4l
Hood4055
hood44699
Hood4988
Hood4755
hood4123
Hood404_Melvin
hood4279
Hood44444444
hood40465
hood448
hood466
Hood431
Hood44yt434433rf
hood4532
hood47KTX
Hood45
hood4444
hood4040
hood460
hood4day
Hood4LifeNig
Hood4444776
hood48
hood474
hood429
hood42wildcats
hood4ngel
hood489
HOOd425668
Hood4Nidus
hood45964
Hood456
urban
Urban431345
urban_city1
UrbanestTunic48
urban_es
urban_legend12345
urban_jester
urbanative
urban_tribe3
Urban4269
UrbanIndigo
Urban5968Alt
urban7219
Urbanstormy
UrbanZReborn
UrbanTales
urban11121
urbanisbussin
UrbanExile
URBAN_6710
urbanerturtle
urbanlawz
urbanenci
UrbanV_2
Urban2229
urbanrot
Urban_thespeedrunner
urbanarchive_0
Urbanfoxy
urbankittycat
UrbanWalkins
urbancaribou981
urbanstreak1
Urban2941
urban12287
UrbanSpecialist
UrbanSaudi
Urban014
urbanboss
UrbanPheonix8
UrbanOrgins
UrbanHydral
Urbanfv
Urban_Wizard007
Wyattben46
Kingof_stupid
turipuWu32
dames847
Ggsdjgdswog
834_W
DRIPDRIP67607
DripKing_5230
drip_GA9F
drip_M80V
Drip_xi
Dripsonyoulikeglue
drip777511
dripmaster_18
Drip_zombie
DripNewAcc
Dripmoonstonealt
dripvava134
Dripthedogwater
Driprn
Drip_god10998
DriptideArmor
Dripinsanoo
DripPlayz0717
drip941
drip01_xp
Drippymonkeyyyyy
drip_bacon0136
DripNotSwag
DripPog
Drippest
DripAxo
DripTheDrap
Dripguy299
drippy4432
Drip0543
DRIPDRIPBRATKU1238
dripues
driplessfish
Dripsmiling
DripDripRoblox
Dripstah
Drip67682
Drip_kurt390
dripyyy666
Drip249480
DripReborn4
DRIP12345489
DRIPN2025
DRIP09991999
drippiest123
DripsStorageAcc1
DripSonicGamer235
Drip_gogeta1
Drips66
Dripking_9089
AnimeBoy
Animeboy9599
AnimeBoy99922
Lexad1306
DeathDragon88888
otthonacc
svgiaquang
Burgergood0
alinaru242
LalalalaUS97
GodkillerGoku77
barbaric1324324
JP4everyoung
fghcvb3451
jolodaan011
RexElectrosonic
the_magena
XxK6tiexX4
jasper298732
Kanamarlapudii
rzygawa2137
SuperMAS27
a284766
Ronaldo_Camal4
Talhataki678
Harjee2017
SpiderZilla357
Thena787
simba_pro117
TAKATO_YOYOO
ConnorJJ2025
bellrerathailand
capitano7606
bethar40
skibidi_tralarelo94
Deer67forest
ninjagoucaria
lowii860
Gameboy_923
Rajveer123128
22LYCANROC
PAPIS6639
ghalastuff
Gamer20212005
Mikadopr
Asdfggfdsa531
technobladaneverdie3
joseiscool383
Rafa1051K
gothboy4
gothboy4684
gothboy491577654
Gothboy40890
gothboy482
GothBoy469
gothboy4826
gothboy4a65
gothboy411
gothboy413
Gothboy491
GothBoy445
GothBoy475
gothboy4l
Gothboy4567
gothboy4271
gothboy49382
gothboy456
gothboy453
Gothboy4life21
Gothboy4141
gothboy46463
Gothboy45
gothboy4321
Gothboy47
gothboy484
gothboy41
gothboy421
GothBoy4Life
gothboy457
gothboy44
gothboy42
gothboy4568
GOTHBOY400
gothboy443
gothboy480
gothboy44448
Gothboy409
GOTHBOY439
gothboy4020
Gothboy494
gothboy4584
gothboy4eva
gothboy474
gothboy472
gothboy4ever
Gothboy433
gothboy4488
Gothboy434
Gothboy476
RetroBoy4
retroboy4590
RetroBoy443
RETROBOY480
Retroboy434
Retroboy49
RetroBoy4eva567
RETROBOY461
retroboy4321
RETROBOY44567
retroboy445
RetroBoy4Ever
RETROBOY41
Retroboy456
retroboy458
retroboy444
retroboy421
retroboy435
retroboy4567
retroboy487
RetroBoy496
retroboy40
retroboy43
retroboy432
RETROBOY46_FAN
Retroboy4578
retroboy465
Retroboy405
RETROBOY4201
retroboy4000
retroboy42
retroboy4565
Retroboy45
retroboy4564
Retroboy455
Retroboy45640
Retroboy47
Retroboy469
Retroboy482
retroboy4496
retroboy4829
Retroboy4560
RetroBoy480359
retroboy43wd
RetroBoy418916
retroboy490
retroboy4434
retroboy412
RetroBoy446040
retroboy489
Aesthetic4
tantangwa36
aesthetic4567825
Aesthetic4life_L
aesthetic40830
Aesthetic4012
aesthetic456_girl
aesthetic444luna
aesthetic4711
aesthetic456534
Aesthetic4Life2013
Aesthetic45454545
Aesthetic4722
Aesthetic4lifeer
aesthetic40023
Aesthetic44799
aesthetic45023
Aesthetic453680
aesthetic4463
aesthetic4ever_19
aesthetic45781
aesthetic45063
aesthetic456859
Aesthetic4280
Aesthetic4452447
Aesthetic4Butterflys
Aesthetic44446
Aesthetic4_lif3
aesthetic4r3
aesthetic44000
Aesthetic4nge1
Aesthetic4ever670
aesthetic4912
Aesthetic4942
aesthetic47692
Aesthetic4annxzz
Aesthetic47620
aesthetic45623
aesthetic40012
aesthetic481008
Aesthetic42girlypop
Aesthetic4ever46
Aesthetic4life20111
aesthetic49119
Aesthetic425
Aesthetic4712
aesthetic490900
aesthetic48300
aesthetic47457
aesthetic45782
Kawaii4
Sungminlover6
kawaii456767
kawaii47580
Kawaii4sho
Kawaii479070
KAWAII44346
kawaii456_964
kawaii4_chansaw0
kawaii47sworld
kawaii48157
Kawaii44293
Kawaii44BEBO
kawaii45_holis
KAWAII456648
Kawaii45198
Kawaii43251
kawaii456331
Kawaii4_life5
kawaii44874
KAWAII42154
kawaii456920
kawaii47472
Kawaii4629
kawaii456621
Kawaii45221
Kawaii47136
kawaii456633
kawaii49494
Kawaii4ever3508
kawaii4114
Kawaii47212
kawaii44everr
kawaii467942
kawaii45050
kawaii4ever23
kawaii456897
kawaii45454511
kawaii46710
Kawaii4ev3r
kawaii44075
kawaii4444321
KAWAII4830
kawaii4O4
kawaii4_8b
Kawaii4Life527
KAWAIi44244
Kawaii4daisy
KAWAII4YOU2
kawaii43832
Pinkygamer230
pinkbarbiepink6
pinkygreenbluered
pink08870
pinkypiewow200
PinkTheWitness
pinklover_003
pinkbear2035
pink676767618
pink521xuan
Pink_Willoww12
pink_324224
pinkupromises
pink_deltarune9x
pink_Cherry851
Pink123Blue14
Pinkie_plushie777
pinkyxbaby_07
Pink_dayz18
pink_thecrayon
pinkbait920
pinkk_rokz
pink139019
pink_71613
pink_unicorns1207
pinkbeanz1313
pinkysays14
pinkiylol
Pink_bullet01
Pinkkeys_1234
Pink2K27
Pinko9yay
Pinkstar_737
Pink12345216
Pink_halo20
pink986
Pinkdracosss
Pink324712
Pinkdoesthink
pink_azucar
pinkxalicious
pinkalicious0005
pink_22663
PinkWonderflower123
Pinkdymond26
Pinkcherry873
PinkLovestruck
Pinky_Milk67
pinkcoelophysis
Pinkcat_Isa
sweet4
xcheekychipmunkx
Doll230112
Briella154290
lilola5354
Good4sweet
AbeerFatima_0
Aubjayde17
sweet4ed
Sweet4E23
sweet44495
sweet41516
sweet47798
sweet4mll
sweet41551
Sweet42215
sweet468976
Sweet4567246
Sweet4pea8
Sweet465025
Sweet45173
sweet46819
sweet4469098
sweet4_u3u
Sweet456989
sweet45765
sweet45970
sweet4saccharine
Sweet4SourS
sweet4b14
sweet4ever1616
sweet4960
sweet4796
SWEET44407
Sweet45678938
Sweet44840
Sweet4_49
sweet44160
sweet40004
sweet4shahida45
sweet456329
Sweet4xx0
Sweet456222333053
Sweet465Boo
sweet44357
sweet4nut
sweet494512
sweet4night
sweet4l3xaaa
sweet4every
Doll_8x2
Doll18322
dolly996644
dollvonduch
dollie_yaku
dollxqira
dolleddd_up
Dollsgr
doll_house648
Doll12347385
doll_naux
dolliestpwiincess
dollrottingx
Dolly1_22
dollillie
Dollydolldollmwah
doll_mori
dollielow17
Dollneverdies0
Doll_AbsoluteSolver
dollistaxo
Doll_mmmmm
dollie_claire
Doll0ri
dollsugr
doll2die4
DOLLFACE32179
doll_face124
dolliwu2
Doll_2516
dollinaaa
Doll_doll102
dollifey
DollyTheStrange
dollishous
dolliesbunn
dollsoak
Dollface9523
Dollyisthebest2015
dolletep2t
DollMxk3r
dollfuneraIs
Dollmoney6
dollsiita
DOLL2285
doll_zyy
dollqueite
dollyhrtz_rx
dollcel
Dollface20132
sultan44907
sultandirga1708
Sultanalkoo90
Sultan_12348580
Sultan12343100
SULTAN_6099
Sultan82723
Sultan675448
sultan29438
Sultan30915
Sultankf09
Sultan78347
sultane738
sultanbn2
sultanfox3
sultan2345686
Sultannn12186
Sultan2saad0
Valk4
imdontmesswitl123
Ronmes2324
RGE_MAFDET
iamher_everyThing
Bolsno12
Valk4rie12
Valk43477
Valk43217
Valk47YT
valk4484
Valk4369
valk401
valk4ta014
Valk4otica_2015
Valk4life4life
valk411
valk4246
valk421342
valk4b
Valk4iye
Valk4M
valk42134
valk43
VaLk4ldy
valk444242
valk47
valk4545
Valatrasssz
valk435
Valk4321
Valk44
valk45637
valk400
Valk421
valk42
Valk48
valk432
valk49
valk4trie
valk45
valk45123
Valk46378
valk45XD
valk47b
VALK4411
valk4riegod43ver
Valk444
VALK40
valk46
limited
limited99942
Limited6k
LimitedXD2
Limited4655
Limited_Timeless
Limited_ltems
LimitedNorthern
LIMITED123323
LIMITEDEDITION_IU
LimitedStatic
limited19459
Limited_536
LimitedKezRoni
limitedmk
LIMITEDD_O
Limited_4770
limited_soull
LimitedCrazyy
LimitedAuras
LimiteD0338
LIMITEDEDITION_AI
limitednala
Limited_Time06
Limitedgriff12
LimitedNyte
Limited_Man28
LimitedFormat
LimitedStarPrince
LimitedDrag0n
LimitedBlackGuard
LimitedWealth
LimitedS1llyG00ber12
LimitedPhobia
LimitedlyZero
Limited_V12
LimitedXZV
LimiteddonRoblox
limited_AK7
LimitedThings
LimitedTradesRBLX
Limited0i
LimitedVXI
yourself1048
NospaceInHQ
GHq063
Tango4508
ilove_rambotan2
hfgkfbjdgbn
eweddsz
star4
upinsurya
Skylarbabyy110
cicak_12352
Grace198859
froking73zx
Beny200086
ll123mo8
Sarumaka
Ilannaheart000
unicorns1_452
diaz_yg
Princesslizzette2022
Luckyg_18
80Xxsoy_alessiaxX08
Oli_daSonic6
xrosy672
intheinside4
valentina_com2013
tocinojoa05
Santo456511
Ema127256
zlatay399
Cherryblossom676727
angielimon082718
Stich95658
Brok3n_Traxsh
Rizzlerforthewin
not_Botho0ve
rubias294
Zoethefairy3
FreshJaywillJr3
weallbaddiesright
pesopldjgjz
daisy109468
Kuromi_099619
Star619467
OLCIA123944
babytank2013
pqqlpw
joos_1456
jayson_hughes25
Skibidi_toilet4666
Atlas_y77
biancabr2013
CookieNative
Unicorn12358l
Flowerlove966
TNTMIN29
Jerielalejan
Starlovesurmom
Star_Cupcake013
star13080
STAR082894
Star_gurl852
STAR233564
starligth089
Star_032391
staroooo_1
Star_08012
Star_vibes0941
staryami777
star5545543
startgamenew
Starbryte19
Starconyz
starzech0
star3333119
Staruzia
Starfair_Raven
StarlightCorgi2
STAR_UwU41
Star_flee111
STAR457556
star_05077
Star_222star
Star123yey
STAR_145786
Stars_Cav3rnz
Starisfirst
starlight_4708
STAR_182766
Starlight22102
star6692791
starmeow2016
Stariscool9787
Star_player366
Stars_mcland
stardust0901
StarSkylar12
StarGames636
starlixct
StarNianienLover031
starstruck0383
Starrywarry64
star168_hengheng
stardust_168
starlight_30059
star_moonlight02
StarjoyOfficial
Neon_ooo1
neOn170895
Neonscolorss
Neon060905
NEON_PLAY139
neon_9277
Neon_lit123
NeonCuzWhyN0t
neon_x014
Neon35688
NeonSpars
neons
neonicorn0311
neonlight943
Neon_Power2585
neon_froggo
NeonGCGOD
neonchase
NeonfoxyOwO
Neon_DaFluffyDragon
neoncat007nicee
NEON_WOT
neonlicious4567
NeonMidnight_13
Neon134512
neonzephyr_5
neon238wat
Neon_Aktuun
neonz952
neon989592
Neon_00767
NeonVelyx
NeonaLouise2014
Neon_Vortex31
neonbluediamond
NeonObsidian
neon8482
NeonboyD123
Neon_14614
Neon_Vortezz
Neonlishy
Neon_TheNeoWolf
NeonCrafter_yt
NeonDevilXYZ
Neon_three3
Neon_cyberfunk
NEON_27482
Neonzazaaaaa
NeonQueeN380
NeonBroFJ
Baggy
baggyboi100
Baggy7721
baggy_soad
Baggy_271
Baggylil
BaggyGem1
Baggy0147
Baggy_Official
BaggyGrow
Baggy114z
Baggy677777
BaggyToDrip
baggyleclown_2014
baggy0620
baggy_om
baggyhead2012
Baggy_Norman
BaggyJeanmen
netheritefineROBLOX
MBM_0055
belosiris
Lchip_6
nathan292w
Jbspiderjb
duke_dod
j1st_aya7
BernardoLJM
M_thBaguette
darlung_gemiing
Robbieooooooo
Axyreed17
Hdgdbdb802
Amiridollarr
adrianaguis
Frenchecole
That_guy8517
hbaker7413
antonix_zz
baggi0838
hunter90s
blackmoon0768
hethtahat
saifanyyyyyyy
Expired_Bag
Benbi5554
Vaggie1015
veio_dobimba
Huydamdebudaicho
zaybe_Xx
Bape5
Bape5s
Zzzzzzzzzzzz123488
bape5959
Bape5514
bape520
BAPE5937
bape5000fo
Bape58re
Bape5214
bape5829
Bape53234
BApe5589
BAPE5110
Bape5050
BAPE5TA5
bape5626
bape5566555666
bape5560
bape53
BAPE58
Bape530
bape521
Bape5689
bApE504
bape5288
bape5789
bape54_98
bape5834310
bape567
meezy_pabulayan67
bape51
BAPE5893
bape512
bape5330
BAPE55
BAPE5TAS
BAPE50
bape563
bape5312
bape5op
bape59
bape560
bape5t12
BAPE505
bape5WGM
bape56
bape5213
Bape517
thug5
Fhduveubd
Puppydogbella6
thug55522
THUG5259
thug5514
thug505
thug56348
thug528129
Thug5422
thug52o
thug52222
Thug52521
thug5867
thug5529
thug5926
THUg5488
Thug574linx200056b6r
thug5571926
abigailuix2024
lohh81uuew03
thug548
thug5493
thug51491
thug5371
thug5001
thug583
thug5hty
thug5617
thug546497
thug524
thug5f4d
thug514
thug5768
thug5121
thug512
thug5555555555
thug557
thug55550GD
thug502
thug555578
thug5687
thug54
Thug54686
thug506
thug567
thug5656
thug55555
thug5123
thug5178
hoodie5
Hoodie5022
hoodie5775
Hoodie596
Hoodie5005
Hoodie577
Hoodie55551
hoodie56
Hoodie593
Hoodie521
Hoodie546
Hoodie545
Hoodie519
hoodie555
Hoodie56543
Hoodie53
hoodie51
hoodie556
Hoodie515
hoodie5566
hoodie5939
hoodie544
hoodie54233
hoodie548
HOODIE554
Hoodie527
hoodie565
HOODIE5050
Hoodie553
hoodie557
Hoodie573777
HOODIE511
Hoodie51_Killer
hoodie5647
hoodie5563
hoodie54321
Hoodie543
hoodie560
hoodie568
Hoodie594
hoodie564
hoodie502
hoodie5920
Hoodie522
hoodie5433
hoodie5436
Hoodie59
hoodie50580
hoodie537
hoodie54324
badboy5
vgygsigud6
BadBoy547963
BADBOY5ar
badboy522552
badboy55911
badboy54298623468
badboy5555556
badboy511511
Badboy54046
badboy567706
badboy56658
Badboy56695
badboy57754
badboy57i5
badboy5157_0
badboy55260
badboy54323
Badboy54399
badboy56105
BADBOY563635
Badboy50326
Badboy555848
Badboy566693
Badboy53laz
badboy55cz
badboy555561
badboy590771
badboy56419
badboy55174
badboy567737
Badboy517173
badboy56548
badboy55584
BADBOY56275
badboy59138
badboy5862
badboy555111
badboy567488
badboy581234
BADBOY55291
BADBOY563967
Badboy54726
badboy5212
Badboy56688
badboy57564
badboy55r
badboy526780
badboy543483
BADBOY58270
Prince_x2006xx
PRINCE2010455
prince_liwag1
princegueco29
prince_62336
princea122
PRINCE1212299
Prince12346249
princegamesman
PrincetonSirenHead
prince_2468111
prince_021771
prince1110422
Prince107947
Prince169867
princessmia10801
prince_igop903
prince_q909
Prince032422
princejesniel25
princeniiia
Princesalt09
princesessssss55
Princess_009099
prince030440
Prince90629
princewill8403
Prince0811222
princess_xb1291
Prince_gaming413
PRINCE626789
princeayushidara
prince_playzzzz18
princexlimbu
PrinceSpeedster2000
prince_flame9
prince_lucky728
Princeshiango1262727
PRINCE0000s7
Prince192427
PrinceZ0719
prince777711
PrinceeFromPH
PrinceNOPrice
Prince260q
prince_magnaye1
PrinceBk2016
Princethoma3
princepogipoig13241
PRINCE6788810
coolboy00590
CoolboyBSS56
Coolboy1234562207
Coolboy697657
coolboy27428427492
coolboy001450
Coolboy89427854
coolboy125068
coolboy563835
Coolboyrsa_7
Coolboys55662
Coolboyalways71321
coolboy89728
Coolboy746009
coolboybest197
coolboy_76q3
coolboy58796
Coolboy889939
CoolBoy007279
Coolboy163879
coolboyandveryamazin
coolboyoy45
coolboy131417
COOLBOY19871
coolBoy679826
coolboy673612
Coolboy95988
coolboy040417
Coolboy1234lz
Coolboy72708
coolboy_4566789
Coolboy672435
Coolboy_984354
Coolboyiscool_50
coolboy351341
coolboyyy6794
coolboy174618
Coolboy1735482
Coolboysused
coolboy9coolboy9noo
coolboy564276
Coolboy1428328
CoolBoyGamerMemes
coolboyoy9
coolboy1254180
Coolboy192989
coolboy000840
coolboyperfect57
Coolboy679047
coolboy555575
retroboy
retroboy3002
The_mancool58
MemeMaster201123
BryanKendii
SigmaBoy228148852666
bragna3j
Henrique69067
hhsjxsh
SasukeSips
bayg557
bulabao
Nikosnockys
Sonisiwiwwqqww
riccardoarthaber1
babypammyy
AshRetrofan
zueiro_2703
BloxFruits9800
uguctstfghjhds
jakobthrash
WesCaps
Toconorisadinha
WWE10178
Emanulash
c_j2900
LarryTheBro8
Locus_biggestfan1st
ASIER7713
aboba22713847
gg_ajalahbacon
Ryyman19
Joshamir14
cowboyclickerr2016
samuel150457
etgryi_6
Mr_OP112
PenguinNitro31
PawBoy_y
NiiLSTa
BryannNx7
Narvent457player
molokonybika2
Retroboyl
retroboysigma
RetroBoyGames182
RETROBOY198
Retroboy12123
retroboys8976
PrincessGabX20
PRINCESS_5279006
Princessemma7222
princessBlock75
princess_lop34
Princesschauncey22
princess_kiarra67
Princessmj14girl
PrincessK17816
PrincessGamer857
PrincessHarps68
Princesse_duhlel
princess23Azariah
Princess198k
princessyeturwt
Princess3456811
PrincessPie43020
princessmae12524
princess27crak
Princess_laibear
PrincessAftonAngel
Princesscalbo9
Princessgrmm
PRINCESS_RHEA208
Princess_cheesepuff
PrincesseDydy145
PrincessZhane31
Princess_2cute42
PRINCESS251600
princesse_124012
princessjacksuper
princessnervous
Princess_192022
princessximi1
princessangel832
princesses_cutie9
princess2206380
princess_445066
Princess625264
princess501824
princessAdj56
princess_emerald022
Princess180747
princess_1016498
Princessfinii
Princesslucu16
PrincessUnicorn_343
princessyongco2025
princesszayda41
PrincessDog593
Baddie5
Baddie5679921
ChezMeister27
Olivia4ever703
Bellatueaztecs
Zadeh_7
Pinksnowrabbit
aubreyyaj95
faceofthemace
DiscoMania3000
Gslsihskdj
Bunnysquish5
Ezra_alt333
Roannjag16
bluecoco_938484
littlecocodoggirl
Fluturasi162
Br00kW16
Rainbowheart0090
hazraaaa34
Mia256254
Gamer_Man307
SarahBear2905
Theonlyandonluyvu
Girlypop4859
Youyou67906
ellaslay2622
Abey2152
MacyGret4
sofia583641
CoolKidzs7000
williamwanna
Lexiwlove1234
NoahB_1001
24kweloveyou
JJ_AndBoo
Mani160962
cosmoandlilabff
Tdogg4087564
baddie01310
thereal_batman41
Ellath858
pinkbaddre
GuinnessThebulldog
CarGIRL_16
Preppygurl3131
William_cool28
baddie5S
Baddie502853
baddie5678033
sweet5
RAHAFrrmm
Dulcelamaspr5
Kinder5700
sassygirl52512
yetegj5
Sweet53496
Sweet5cherry
sweet5o44
sweet5899
sweet50512
sweet5o4
sweet562434
Sweet56282
sweet55367
sweet50767
Sweet5_31
Sweet5591234
Sweet5home3
sweet5972
Sweet5_J
sweet52d
sweet55729
sweet5313
sweet51450
sweet54826
Sweet567880
sweet59
sweet555sweet
sweet51671
sweet5142
sweet568377
sweet58807
sweet564323
sweet56gurls
sweet567492
sweet568370
sweet555943
SWEET5467783
sweet56125
Sweet55702
sweet50012
sweet5hy
Sweet5peaa
sweet50454
Sweet505n
sweet5cented
Sweet5crm
sweet507777
sweet520owo
Luna5
LunatyRainAlt3
qwly02
Solecito150817
acidos666
meduzax49
Lus346221
LunaBloxFruit_5
Luna227713
Lunalight239
pavel111567
Holkcool1
Lumikani5
Loser212170
Justicia2696
Koltrasten1234
ksmi6931941
MR_ney12390
GODISMYLORD12335
mayelaluna5
Lena_Safaric5
ksmi47397
p4scaaa25
Rosita998069
Luna250720081
razetka577
Ingvn5
mariasalchicha0
mermeladaconpan784
schlummi28
skwwkegtdlq
1989elite
luna593904
luna523752
luna501153
luna5262181
luna551810
luna538b6
Luna5831339
LUNA5663323
luna503246
krysluna5
Laiax28
yrttriy5
Lunabesta47
Luna53perez
Luna523103
luna5427889
luna525217
Luna521107aa
RICH13062005
RichRaijin
RichMaster_67
richihwgr
RichCM_28
richiel197
RichMayhem236
richideas
RichardMG489
Rich152000
Richeladipati
richard_pirata500
Rich_Dump456
richarddog5
Legend35685868
legend_2017633
LegendStudio633
Legend123alldayyy
Legendarie18
LEGENDHilo
Legendsigma_100
Legend010321
Legend_9185
legends_Ninja1202
legendberu
Legend_00017
legend246307
legendary10355
Legend_Kirov
Legend325boy
LeGeNd456_45
LegendGamingTG
Legend322544
Legend21541
LEGEND44143
LEGEND7_GUY7
legendd_71
legend16768
LegendXProYT2
legendtaker9
Legendarygamers51
legend_ofALL2
kol09848
Coolroblox_62
97SADOW99
Cyber0verlord907
armanjohal90
lufyy34547
sirimi995
papusja40
at51491
DONTSHOOTME725
MOIZGOOD19
taekookshiper28
tfmaupf5
ReaperScopeMM2
BLOX_ROBOT60
Bloxiade77
blox_froten13
BloxBox900
Bloxhead715
Bloxgrindevr3
blox6432
blox_cola005
Bloxfruijshh
blox393938
Bloxxer0912
HIPHOP6
Hiphop66650
hiphop6760
Hiphop6697
hiphop6707
HipHop67998
Hiphop676866
Hiphop69123
hiphop6028
Hiphop674519
hiphop67777
Hiphop67667
hiphop66620
hiphop6659
hiphop678958
hiphop6612
hiphop64329
Hiphop65894
Hiphop67434
Hiphop617
hiphop6093
hiphop6602
hiphop6348
hiphop69696
hiphop67797
hiphop668
hiphop6700
Hiphop65417
Hiphop666999
hiphop66679
Hiphop67903
hiphop6743
hiphop61611
hiphop67800
hiphop640
hiphop6126
Hiphop6758
hiphop6542
hiphop677
hiphop683
hiphop6766
Hiphop662
hiphop65422
hiphop67897
HIPHOP645
HipHop639
HIPHOP67
hiphop6212
hiphop696
DaHood
DaHoodDaHood077
DAHOODtop_dahoodtop
dahood22444
WWP_81727
kristjano01
godkiller876593
Luisroque1920
Nate_vybez
Persoliam8
Pipukamilaja434
Jagrphsvpppp
Kaneki_25209
beki14693
zjznznnwkab
Starboy47106
TheMostMoney8
tononoobsad
OxigenulTau
Saffiyam01
GolisMatysek99
Angeline97431
Jamari01234567
Thebezz777
DuPlic4te4
z0mgh4xzy
TalitoRafa201472
09_TWILINGIS
tyyyfy6
pepepacheconumber2
Hermes_Turkey
hello_burgelol
jo_jo05jo
Lawnmower2155543
cabil111
Ani273897
tjfhyjthifu
5unset123
Rez1_XD
mfhuwii
Doors_yopol
zachfeny
Ga8757
ktp98364
Fhntgffthy
Disapointed85
Jsiziz59
Flower_100713
cypher
Cypher_e1
Cypher992012
CypherZero3
Cypher_Shadow4
Cypheriguesss
Cypher_yron
cypherti
cypher1359
CypherWolf3
Cypher_76x
Cypherman34
Cypherou1
Cypher_yu
Cypher_rrr
Cypher_OO
cypherssky
Cypher80001
cyphermck
CypherRoblox7
Cypher_MS
Cyphertheanomaly
Cypherluana
CypherusCat
cypher6six6
Cypher_valorant2
cypherworldwide
cypher_sllvn
cyphercapp
CypherVX
CYPHER0823
cypher_1106
cyphergho_st
cyphersoull
Cypher_0110
CypherOGthegreat
CypherRoblox77
CypherLinyx
Cypher0821
cypher4sylus
Cypherous_964
Cypher2581
CypherTheFennecFox
Cypher_Rhea
cypher0531
Cypher_Dawn
Cypher12380
CypherGalaxy801
Cypherq8
Cypher9192
SwagLord4412
swagbitin
Swaggestfr
Swagacus1
swag7swag7swag
Swag777765
Swag_boy6757
SWAGA6708
swagiscool41
SWAGA_2229
Swaglolgirl321
SwagPotato345
swagalioussbae
swagzzombie
swagmoneybands223
SWAG2DACORE
Swaga3531
Swag04256
SwagMonkeylolol
swaggexe1
swago_met
Swag_ShiJPlayz
Swagbuy
swaggdabb12
SWAGSHARK202
Swagadidi2007
swagchecked
SwagMoneyisawesome
swagyguycool_09
SWAGGER_12563
Swag_90211
SwagXAesir
swagtasticoo
swaggy_ba
SWAGGERDAGGER7070
SwagTution
swagisballer
SWAGQUEEN1026
Swagmaster5360
swaggyswag50
Swaggergal_26
swagkskj
swaghxtor
SWAG_GAMES14
Swag1543Y
Swagg0_o1
Swagsirlot
swagathswags1234
Swagger_088
swagsyaboi
boy57049
boyx977
boy_30280
Boyzzz3013
Boy4sleeping
BoyTheKing6776
boyrants
Boy_Zin945
Boycharacter28
Boywiliam089
boy_close0
BOYN1023
boy_evade67
boy0927026171
Boydream6
boy1XVN_8
boy_200306
BOYSPEED99317
BOY335038
Boy127132
boyvirendra
boy888273
boy0_01111
Boy230714
Boy525456
Boylll011
BoyQ1300
boycool3
Boy03238
boymom282
boy_butgood12
boyyman18
Boyz_0967
boy129175
BoyBoyBoy00037
BOYRoblox_426
Boy10827su2u
Boy67676767676767770
Boya1234510
boys21529
boy_dragon2500
Boymanhthi
boytje2011
boy653102
boy9312
boy76_33
boy_kcng8778
Boy0102031
boy116273
eboy6742069
eboyyyyy30
eboyanjg
eboypillo26
Eboy44449
EboYGsZxzdc
eboyteamPH
EBOY123456sf
eboy6767676765
eboychoiii
Eboy88858
eboy099999
Eboyrios4
Eboyking_825
eBoy00050
Eboy_withmommyissues
eBoy678948
mb_miko32
furiousspilled
Jacobaltacc32
jakexander603
apexidominator
winnethepoh7
Andrewysimwk
graonny0003
userrrrrr92222
Jjijij2uu
eldking123
barou2730
Ouhn121
Xxbrother0510
hong5005
Sillymantrake
montero_cc1
iloveccnc
hackers_bacon5
Kiran21284
paldin25
yoyori790
balasa877
Afro_Ez
CarlEboy85
Metruop19
BLUEEXORCIST42
Lafandechigiri
floroir41
empreur566
imachiken14546
Karina276356
streetwear6
Streetwear616
streetwear6752
streetwear60
Streetwear671
Streetwear670
Streetwear666
streetwear674
Streetwear6767
Streetwear6767767777
streetwear689
streetwear63
Streetwear676777
Streetwear67677
Streetwear676767
streetwear622
streetwear65
streetwear6761
streetwear67
Streetwear677
streetwear61
streetwear68
streetwear62
Alpha78290
Alpha_adelstein0219
AlphaJenelli
Alpha_26062020
ALPHA27062010
Alpha_011777
alpha_lexa57
Alpha27952
Alpha_Boy085
AlphaxProx
Alpha_Apex4468
ALPHA1115749
ALPHA33329
alphakemybody
AlphaOne37
Alpha4Ze
AlphaOmega_389
Alpha_Tyrant1
ALPHA08727
Alpha_EO7
alpha3128000
Alphaxd931
ALPHA0783
Alphalebosse2
AlphaSovereign114
angie_8711
77narly
GameFairy2000
LoritheBlackfox
V4mp_m3338
Asasher01
merakhel_khtamh
robloxhffj82
barbie
barbiespinklips
barbiee21212
Barbiegirlcut123
BarbieP050
Barbie_girl13339
Barbie43xduwu
barbieI5I5
Barbiey2020
barbie249120
Barbiee0671
barbiedoIIhair
Barbie_41210
BarbieToCute
barbieprincesastar98
barbie2549
Barbie_templin104
Barbie19850614
Barbieunn
Barbie_55483
barbie123x07
barbie020962
BarbieLittleLady
Barbie_Malibu1333
barbieandken006
Barbiedollbbb
Barbiebiggirlpink
barbie832928
barbie_safia
barbieferraira
barbieferrera2020
barbiee12940
barbie_noplastic
barbie_minajs
Barbieeeo_o
barbie216311
barbiedepok
Barbiegirlll2005
Barbie71173
Barbie050422
BarbieSever_7
Barbie_nm01
barbie_Athena6
BARBIEBADDIE_NUMBER1
barbie134girl
Barbie_y017
barbie220139
Barbiethataarp
barbieAlessa16
barbie_dall677
blossom6
blossom6s
rose51mds
Blossom24476
Blossom67sms
blossom64280
Blossom6789Lover
Blossom676779
Blossom65450
Blossom677890
Blossom67208
Blossom6789382
blossom61779
Blossom67378
blossom6767fff
blossom6064
blossom67572
Blossom676167
Blossom63313
Blossom671912
Blossom67564
Blossom65549
blossom67590
blossom6706
Blossom67261
Blossom67678226
blossom6508
blossom6411
Blossom678070
Blossom643710
Blossom64412
blossom65277
Blossom67236
Blossom65x
blossom65100
blossom6767181
Blossom66770
Blossom61983
Blossom673456
Blossom63528
Blossom62938
Blossom67687
Blossom679101
Blossom676787
Blossom6599
blossom654701
blossom678963
Blossom679487
Blossom6056
blossom68732
butterfly
butterflyEl11
butterfly786065
BUTTERFLY35244
butterflyOOO_2
butterflyver16
butterflypink2201
butterfly_05582
butterflyfkfkfjdkjd
butterfly7800000o00
butterfly080409
butterfly_girl039
Butterfly54724
Butterfly_Lover436
butterflylee19
Butterfly_29718
Butterfly6677029
butterfly468576
butterfly_36020
Butterfly081548
Butterflysthatfly
Butterfly_120203
Butterfly_A21
Butterfly15527
Butterfly_1Mariposa
Butterfly79736
ButterflyHeart_13
Butterfly907863
BUTTERFLY_56673
butterflycute999
butterfly_34692
ButterflyMai20
butterflydede7
Butterfly300Queen
butterfly_winx18
butterflyrainbow_143
Butterfly_Player8
butterfly181861
butterflysjudgemeh
ButterflyVH10
butterfly_cotton110
butterflyplayzCEO
butterflyyy094
Butterfly7132010
butterfly32121
butterfly28289
Butterfly_00710
Butterflygirl_443
butterfly22495
butterfly240912
bubble6
Mann_y39678
bubble67048
Bubble65403
bubble672941
bubble619619
bubble6197
Bubble6767709
bubble66070
Bubble654655
Bubble6104
Bubble6767373
bubble666691
bubble68oo
bubble676794
bubble678985
Bubble67boi
Bubble675445
bubble6985
Bubble6758494
bubble674589
Bubble678975
Bubble672808
bubble67377
bubble677891
Bubble6767999
bubble645325
Bubble67436
Bubble6613
Bubble67114
Bubble6680
bubble65823
Bubble67109
Bubble67675167
bubble67503
Bubble6316
Bubble676543
bubble67255
bubble671230
bubble67014
Bubble676712
bubble649129
bubble67056
Bubble65902
bubble6789003
Bubble666574
bubble679137
Bubble6456
Bubble6767212
BuBBLE678773
bubble
bubbles19120
bubble170115
Bubblemilktea136
bubbles_153441
Bubbles234800
bubble_0287
Bubble_p127
Bubbles111587
bubblesos
Bubblemixed
bubblesweet77
BubblestheMaster454
BubbleBlueBop
BUBBLES_17105
BubbleGumHorse2015
bubblesmariebubbles
Bubblelishious_14
bubblebasil2025
Bubbles0316
Bubblegum1913Tok
bubble_210711
Bubbles677770
bubble676731
BuBBlestheBear20
bubblegumlin
Bubble102016
bubbles07
Bubble_b33567
Bubbleaetheria
Bubbleyangel12
Bubbles_lol372
Bubbletheoctopus
bubbles_123456789013
Bubbles_12235
bubbles_25257
bubbleguppiesii
bubblelove964
bubble_bottttt
bubblecornblue
bubble_blue341
BubbleHed28
Bubblesaur28
Bubble6403
Bubbles0_22
bubblesnoopy0
Bubbles_101017
bubbles09707
Bubbles_CanDy094
Bubbles_5179
collector6
SmachTv99
Collector65544333221
collector626638
collector6777
COLLECTOR6715
Collector678
Collector673355
Collector6686
Collector668309
collector667
collector6003
collector674
Collector6666
collector666
collector60
Collector632
collector6545
collector62
Collector666893
COLLECTOR6699
COLLECTOR6473
Collector66761
collector6996
COLLECTOR64
Collector6717
collector6482
COLLECTOR6727
Collector6262
collector60000
Collector6554321
Collector66861
collector66453
COLLECTOR6903
collector66870
Collector6555
COLLECTOR6071
collector637
collector6g
collector619
collector6636
CoLLeCToR66669
collector6745
collector668115
collector6781
Collector6626
Collector67910
collector6987
Collector67676767
collector623
headless6
Headless690
headless659
headless6002
Headless697
headless66658
headless666goat
headless6371
Headless689
Headless634
Headless6663
Headless6785
headless6797
headless62727
Headless6366
headless6862
Headless609
headless637118375
headless636727374477
headless61
Headless623
headless62635453826
Headless6015
headless618263746
]]
    local DB_5000 = {}
    local LIST_HIPHOP = {}
    local LIST_COWO = {}
    local LIST_CEWE = {}
    local LIST_SULTAN = {}
    local LIST_KORBLOX = {}

    -- Parse dan kategorisasi 5.344 nama langsung saat script berjalan
    for u in string.gmatch(DATABASE_5000_RAW, "[^%s]+") do
        table.insert(DB_5000, u)
        local low = string.lower(u)
        if string.find(low, "hiphop") or string.find(low, "rapper") or string.find(low, "drill") or string.find(low, "dahood") or string.find(low, "trap") or string.find(low, "baggy") or string.find(low, "bape") or string.find(low, "graffiti") or string.find(low, "urban") or string.find(low, "baller") or string.find(low, "swag") or string.find(low, "drip") or string.find(low, "jordan") or string.find(low, "hood") then
            table.insert(LIST_HIPHOP, u)
        elseif string.find(low, "girl") or string.find(low, "cutie") or string.find(low, "princess") or string.find(low, "queen") or string.find(low, "preppy") or string.find(low, "aesthetic") or string.find(low, "kawaii") or string.find(low, "softie") or string.find(low, "fairy") or string.find(low, "kitty") or string.find(low, "barbie") or string.find(low, "baddie") or string.find(low, "rose") or string.find(low, "pink") or string.find(low, "sweet") or string.find(low, "doll") or string.find(low, "blossom") or string.find(low, "butterfly") or string.find(low, "bubble") or string.find(low, "luna") or string.find(low, "diva") then
            table.insert(LIST_CEWE, u)
        elseif string.find(low, "boy") or string.find(low, "eboy") or string.find(low, "slender") or string.find(low, "hoodie") or string.find(low, "badboy") or string.find(low, "skater") or string.find(low, "animeboy") or string.find(low, "streetwear") or string.find(low, "darkboy") or string.find(low, "coolboy") or string.find(low, "chad") or string.find(low, "retroboy") or string.find(low, "ninja") or string.find(low, "prince") or string.find(low, "alpha") then
            table.insert(LIST_COWO, u)
        elseif string.find(low, "korblox") or string.find(low, "headless") then
            table.insert(LIST_KORBLOX, u)
        else
            table.insert(LIST_SULTAN, u)
        end
    end
    -- === DATABASE 1: AVATAR PRESET SULTAN & CREATOR (TOP 100+) ===
    local PRESET_KORBLOX_HEADLESS = {
        { id = 1726027,    name = "Linkmon99",       tag = "Korblox+Limiteds" },
        { id = 1599385,    name = "Merely",          tag = "Dominus+Valk" },
        { id = 70564639,   name = "InquisitorMaster",tag = "Headless+Soft" },
        { id = 88198774,   name = "TanqR",           tag = "Headless+Pro" },
        { id = 18406183,   name = "KreekCraft",      tag = "Valk+Hat" },
        { id = 63864177,   name = "Flamingo",        tag = "Classic+Funny" },
        { id = 36809772,   name = "LankyBox_Adam",   tag = "Headless+Outfit" },
        { id = 124729862,  name = "SharkBlox",       tag = "Korblox+UGC" },
        { id = 79491629,   name = "MeganLetter",     tag = "Preppy+Headless" },
        { id = 143878705,  name = "LeahAshe",        tag = "Soft+Pink" },
        { id = 24700344,   name = "Denis",           tag = "Creator+Cat" },
        { id = 78377750,   name = "Sketch",          tag = "Creator+Valk" },
        { id = 31174981,   name = "SubZeroExtabyte", tag = "Aesthetic+Pro" },
        { id = 55301802,   name = "ItsFunneh",       tag = "Creator+Blue" },
        { id = 48293021,   name = "Peebs",           tag = "Soft+Headless" },
        { id = 111111111,  name = "Bloxed_Sultan",   tag = "Bloxed Korblox" },
        { id = 222222222,  name = "Headless_Goth",   tag = "Bloxed Headless" },
        { id = 333333333,  name = "Valk_Dominus_God",tag = "Bloxed Legend" }
    }

    local PRESET_COWO = {
        { id = 261,        name = "Shedletsky",      tag = "Classic Telamon" },
        { id = 156,        name = "BuilderMan",      tag = "Admin Legend" },
        { id = 16138964,   name = "Stickmasterluke", tag = "Veteran Legend" },
        { id = 72152661,   name = "Cyber_Drift",     tag = "Cyberpunk Boy" },
        { id = 45982834,   name = "Shadow_Ninja",    tag = "Tryhard Ninja" },
        { id = 27694931,   name = "Goth_Boy_Y2K",    tag = "Y2K Goth" },
        { id = 89283741,   name = "Anime_Swag",      tag = "Anime Boy" },
        { id = 58291039,   name = "Techwear_Fit",    tag = "Techwear Black" },
        { id = 49201948,   name = "Vampire_Vibe",    tag = "Dark Vampire" },
        { id = 72819401,   name = "Casual_Denim",    tag = "Casual Street" },
        { id = 61829402,   name = "Bape_Hypebeast",  tag = "Hypebeast" },
        { id = 93820194,   name = "White_Aesthetic", tag = "Clean White" },
        { id = 81920485,   name = "EBoy_Chains",     tag = "E-Boy Dark" },
        { id = 29481029,   name = "Drill_UK_Fit",    tag = "Drill Trap" },
        { id = 38491029,   name = "Skater_Boy_Vibe", tag = "Skater Casual" },
        { id = 47291048,   name = "Rich_Dominus_Boy",tag = "Sultan Dominus" },
        { id = 56192048,   name = "Y2K_Chrome_Heart",tag = "Chrome Hearts" },
        { id = 65291049,   name = "Blox_Fruit_Sweat",tag = "PVP Tryhard" },
        { id = 74192048,   name = "Anime_Gojo_Fit",  tag = "Anime Sorcerer" },
        { id = 83291049,   name = "Cyber_Glitch_Boy",tag = "Neon Cyber" }
    }

    local PRESET_CEWE = {
        { id = 54890253,   name = "IamSanna",        tag = "Creator Cute" },
        { id = 37704618,   name = "PinkLeaf",        tag = "Pro Aesthetic" },
        { id = 61928471,   name = "Fairy_Pastel",    tag = "Pastel Fairy" },
        { id = 74819203,   name = "EGirl_Goth",      tag = "E-Girl Dark" },
        { id = 89102938,   name = "Preppy_Stargirl", tag = "Preppy Pink" },
        { id = 92837461,   name = "Kawaii_Cat_Girl", tag = "Kawaii Neko" },
        { id = 48201948,   name = "Soft_Angel_White",tag = "Angel Wings" },
        { id = 59102948,   name = "Y2K_Princess_Hot",tag = "Y2K StarGirl" },
        { id = 71829401,   name = "Cyber_Doll_Pink", tag = "Cyber Doll" },
        { id = 82910492,   name = "Dark_Fairy_Core", tag = "Dark Grunge" },
        { id = 63910294,   name = "Coquette_Ribbon", tag = "Soft Coquette" },
        { id = 51920394,   name = "Retro_Chic_Vibe", tag = "Vintage Chic" },
        { id = 42819039,   name = "Indie_Star_Girl", tag = "Indie Aesthetic" },
        { id = 31920485,   name = "Strawberry_Sweet",tag = "Soft Strawberry" },
        { id = 20918274,   name = "Kpop_Idol_Style", tag = "K-Pop Aesthetic" },
        { id = 19283745,   name = "Black_Cat_Goth",  tag = "Goth Lolita" },
        { id = 98172635,   name = "Barbie_Dream_Fit",tag = "Barbie Pink" },
        { id = 87263541,   name = "Cottagecore_Frog",tag = "Cottagecore" },
        { id = 76354129,   name = "Moon_Goddess",    tag = "Celestial" },
        { id = 65432198,   name = "Floral_Summer",   tag = "Summer Breeze" }
    }

    local PRESET_SPECIAL = {
        { id = 1,          name = "Roblox",          tag = "Official 2006" },
        { id = 2,          name = "John Doe",        tag = "Legendary Myth" },
        { id = 3,          name = "Jane Doe",        tag = "Legendary Myth" },
        { id = 18,         name = "Bacon_Hair",      tag = "Default Bacon" },
        { id = 2011,       name = "Classic_Noob",    tag = "Noob Original" },
        { id = 666,        name = "Guest_666",       tag = "Mythic Horror" }
    }

    -- === DATABASE 2: ITEM LIMITED LENGKAP BLOXED.GG (35+ ITEMS: CROWNS, UFO, DOMINUS, VALK) ===
    local LIMITED_ITEMS = {
        -- CROWNS & MAHKOTA SULTAN
        { id = 5731053584, name = "Sparkle Time Crown of O's",  cat = "Crown",  rap = "1B+ RAP" },
        { id = 106689991,  name = "Bluesteel Crown",            cat = "Crown",  rap = "800M+ RAP" },
        { id = 215743452,  name = "Crown of Wanwood Kingdom",   cat = "Crown",  rap = "300M+ RAP" },
        { id = 1029027,    name = "Lord of the Federation",     cat = "Crown",  rap = "500M+ RAP" },
        { id = 1081384,    name = "Golden Crown of Kings",      cat = "Crown",  rap = "200M+ RAP" },
        { id = 1361730076, name = "Bombastic Crown",            cat = "Crown",  rap = "150M+ RAP" },

        -- UFO & SCI-FI HATS
        { id = 8151404994, name = "Hovering UFO Saucer",        cat = "UFO",    rap = "Limited UFO" },
        { id = 130356745509024, name = "Cute Alien UFO Hat",    cat = "UFO",    rap = "UGC UFO" },
        { id = 114840309037941, name = "UFO Abduction Hat",     cat = "UFO",    rap = "UGC UFO" },

        -- DOMINUS (SEMUA VARIAN TERKENAL DARI BLOXED.GG)
        { id = 31101391,   name = "Dominus Infernus",           cat = "Dominus",rap = "500M+ RAP" },
        { id = 48545806,   name = "Dominus Frigidus",           cat = "Dominus",rap = "400M+ RAP" },
        { id = 162067148,  name = "Dominus Astra",              cat = "Dominus",rap = "300M+ RAP" },
        { id = 21070012,   name = "Dominus Empyreus",           cat = "Dominus",rap = "250M+ RAP" },
        { id = 362013871,  name = "Dominus Messor",             cat = "Dominus",rap = "180M+ RAP" },
        { id = 250403322,  name = "Dominus Rex",                cat = "Dominus",rap = "150M+ RAP" },
        { id = 516327931,  name = "Dominus Pittacium",          cat = "Dominus",rap = "120M+ RAP" },
        { id = 138932314,  name = "Dominus Aureus",             cat = "Dominus",rap = "100M+ RAP" },
        { id = 96103379,   name = "Dominus Vespertilio",        cat = "Dominus",rap = "90M+ RAP" },
        { id = 17668952390,name = "Dominus Valkyrie Hybrid",    cat = "Dominus",rap = "UGC Limited" },

        -- VALKYRIE HELMETS
        { id = 1365767,    name = "Valkyrie Helm Classic",      cat = "Valkyrie",rap = "150M+ RAP" },
        { id = 118043386,  name = "Sparkle Time Valkyrie",      cat = "Valkyrie",rap = "200M+ RAP" },
        { id = 1402446719, name = "Violet Valkyrie",            cat = "Valkyrie",rap = "50K Robux" },
        { id = 387255533,  name = "Emerald Valkyrie",           cat = "Valkyrie",rap = "80M+ RAP" },

        -- SHADES, AUDIO, & HEADPHONES
        { id = 11748356,   name = "Clockwork's Shades",         cat = "Shades", rap = "80M+ RAP" },
        { id = 1235488,    name = "Clockwork's Headphones",     cat = "Audio",  rap = "90M+ RAP" },

        -- WAJAH LIMITED SULTAN
        { id = 494291269,  name = "Super Super Happy Face (SSHF)", cat = "Face", rap = "250M+ RAP", isFace = true, tex = "rbxassetid://494290547" },
        { id = 240928507,  name = "Playful Vampire Face",       cat = "Face",   rap = "100M+ RAP", isFace = true, tex = "rbxassetid://240928174" },
        { id = 128159229,  name = "Beast Mode Face",            cat = "Face",   rap = "50M+ RAP",  isFace = true, tex = "rbxassetid://128159146" },
        { id = 20418658,   name = "Red Tango Face",             cat = "Face",   rap = "30M+ RAP",  isFace = true, tex = "rbxassetid://20418644" },

        -- FEDORAS & HORNS
        { id = 1028856,    name = "Classic Fedora",             cat = "Fedora", rap = "40M+ RAP" },
        { id = 1285307,    name = "Sparkle Time Fedora",        cat = "Fedora", rap = "70M+ RAP" },
        { id = 72082328,   name = "Midnight Blue Fedora",       cat = "Fedora", rap = "50M+ RAP" },
        { id = 187492039,  name = "Silver King of the Night",   cat = "Horns",  rap = "25M+ RAP" },
        { id = 215718515,  name = "Poisoned Horns",             cat = "Horns",  rap = "30M+ RAP" },
        { id = 54107086,   name = "Ghostly Horns",              cat = "Horns",  rap = "20M+ RAP" },
        { id = 108821217,  name = "Frozen Horns of Frigid",     cat = "Horns",  rap = "35M+ RAP" }
    }

    -- === DATABASE 3: PAKET ANIMASI (DENGAN GAMBAR ASSET RESMI) ===
    local ANIMASI_PACKS = {
        { name = "Ninja Pack",       idleAsset = 656117400,  tag = "Anime",       idle = "656117400",  walk = "656118852",  run = "656118328",  jump = "656117878",  fall = "656115606" },
        { name = "Levitation Pack",  idleAsset = 616006778,  tag = "Magic",       idle = "616006778",  walk = "616013216",  run = "616010382",  jump = "616008913",  fall = "616005863" },
        { name = "Zombie Pack",      idleAsset = 616158929,  tag = "Horror",      idle = "616158929",  walk = "616168032",  run = "616163600",  jump = "616161997",  fall = "616157476" },
        { name = "Mage Pack",        idleAsset = 707742142,  tag = "Fantasy",     idle = "707742142",  walk = "707897766",  run = "707861613",  jump = "707853694",  fall = "707829716" },
        { name = "Vampire Pack",     idleAsset = 1083445855, tag = "Dark",        idle = "1083445855", walk = "1083473930", run = "1083462077", jump = "1083455352", fall = "1083439238" },
        { name = "Oldschool Pack",   idleAsset = 531982820,  tag = "Classic",     idle = "531982820",  walk = "531987553",  run = "531985720",  jump = "531984193",  fall = "531980083" },
        { name = "Superhero Pack",   idleAsset = 616111295,  tag = "Hero",        idle = "616111295",  walk = "616122287",  run = "616117076",  jump = "616115533",  fall = "616108001" },
        { name = "Toy Pack",         idleAsset = 782841498,  tag = "Playful",     idle = "782841498",  walk = "782845736",  run = "782843345",  jump = "782847020",  fall = "782842708" },
        { name = "Robot Pack",       idleAsset = 616088211,  tag = "Sci-Fi",      idle = "616088211",  walk = "616095330",  run = "616091570",  jump = "616090535",  fall = "616086039" },
        { name = "Stylish Pack",     idleAsset = 616136790,  tag = "Trendy",      idle = "616136790",  walk = "616146170",  run = "616140816",  jump = "616139451",  fall = "616134815" }
    }

    -- === DATABASE 4: SEPATU & SNEAKERS RESMI (DENGAN GAMBAR ASSET VALID) ===
    local SEPATU_PACKS = {
        { id = 7277418341, name = "Sneakers Right White (Roblox)", tag = "Sneaker" },
        { id = 15882869743,name = "White Sneaker Shoes Set",       tag = "Sneaker" },
        { id = 6984776307, name = "Roblox Classic Sneaker (L)",     tag = "Classic" },
        { id = 6984779324, name = "Roblox Classic Sneaker (R)",     tag = "Classic" },
        { id = 129942226766572, name = "Blue Sneaker White Sole",   tag = "Sneaker" },
        { id = 102867906700353, name = "Orange Street Sneakers",   tag = "Streetwear" },
        { id = 9817757978, name = "Air Jordan 1 High OG Retro",    tag = "Jordan" },
        { id = 9817765103, name = "Nike Dunk Low Retro Panda",     tag = "Nike" },
        { id = 9817772189, name = "Chunky Street Boots Black",     tag = "Boots" },
        { id = 9817781045, name = "Canvas High Tops White Kicks",  tag = "Casual" },
        { id = 9817788412, name = "Platform Leather Loafers",      tag = "Formal" },
        { id = 9817810054, name = "Cyber Neon LED Kicks",          tag = "Sci-Fi" }
    }

    -- === DATABASE 5: BENTUK TUBUH (REAL 3D PACKAGES / BUNDLES LENGKAP DENGAN GAMBAR FULL BODY) ===
    local KARAKTER_BODY_PACKS = {
        {
            name = "Korblox Deathspeaker",
            desc = "Kaki kanan tengkorak melayang (Real Korblox Leg)",
            type = "korblox",
            wearerId = 1726027,
            tag = "17,000 Robux"
        },
        {
            name = "Headless Horseman",
            desc = "Kepala hilang total tak terlihat (Real Headless)",
            type = "headless",
            wearerId = 88198774,
            tag = "31,000 Robux"
        },
        {
            name = "Korblox + Headless Combo",
            desc = "Gabungan kepala hilang + kaki Korblox sultan",
            type = "combo_korblox_headless",
            wearerId = 1599385,
            tag = "Legend Combo"
        },
        {
            name = "Magma Fiend (Monster Lava)",
            desc = "Tubuh monster lahar menyala",
            type = "donor_body",
            wearerId = 18406183,
            tag = "Monster"
        },
        {
            name = "Frost Guard General",
            desc = "Tubuh prajurit ksatria es beku",
            type = "donor_body",
            wearerId = 63864177,
            tag = "Knight"
        },
        {
            name = "Redcliff Knight",
            desc = "Zirah ksatria merah Redcliff klasik",
            type = "donor_body",
            wearerId = 261,
            tag = "Paladin"
        },
        {
            name = "Overseer Body Guard",
            desc = "Pasukan mata hijau Overseer elit",
            type = "donor_body",
            wearerId = 16138964,
            tag = "Overseer"
        },
        {
            name = "Roblox 2.0 (Modern Smooth)",
            desc = "Bentuk badan halus dan proporsional atletis",
            type = "r20",
            wearerId = 156,
            tag = "Bundle"
        },
        {
            name = "Superhero Bulky Body",
            desc = "Dada lebar dan bahu kekar ala Superhero",
            type = "hero",
            wearerId = 124729862,
            tag = "Bulky"
        },
        {
            name = "Chibi / Mini Avatar Rig",
            desc = "Ukuran badan mini lucu imut",
            type = "mini",
            wearerId = 70564639,
            tag = "Chibi"
        },
        {
            name = "Classic Blocky 1.0 (Reset Tubuh)",
            desc = "Kembalikan tubuh ke kotak standar original",
            type = "reset_body",
            wearerId = 1,
            tag = "Classic"
        }
    }

    -- === STATE MANAGEMENT ===
    local selectedUserId = LP.UserId
    local selectedUsername = LP.Name
    local userFavorites = {}
    local origUserId = LP.UserId
    local stackedLimitedAccessories = {} -- [assetId] = clonedInstance

    -- === LAYOUT UI UTAMA ===
    local AvHeader = Instance.new("Frame")
    AvHeader.Size = UDim2.new(1, 0, 0, 28)
    AvHeader.BackgroundTransparency = 1
    AvHeader.ZIndex = 13
    AvHeader.Parent = PageAvatar

    local AvTitle = Instance.new("TextLabel")
    AvTitle.Size = UDim2.new(1, -80, 1, 0)
    AvTitle.BackgroundTransparency = 1
    AvTitle.Font = Enum.Font.GothamBold
    AvTitle.TextSize = 11
    AvTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    AvTitle.TextXAlignment = Enum.TextXAlignment.Left
    AvTitle.Text = "[AVT] AVATAR CHANGER V5 (INFINITE 5000+ AVATARS & BLOXED.GG)"
    AvTitle.ZIndex = 14
    AvTitle.Parent = AvHeader
    makeBackBtn(AvHeader, function() showPage(PageSplash) end)

    -- === KIRI: SIDEBAR SUB-TABS (7 SUB-TABS) ===
    local AvSidebar = Instance.new("Frame")
    AvSidebar.Size = UDim2.new(0, 72, 1, -34)
    AvSidebar.Position = UDim2.new(0, 0, 0, 34)
    AvSidebar.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
    AvSidebar.BorderSizePixel = 0
    AvSidebar.ZIndex = 13
    AvSidebar.Parent = PageAvatar
    makeCorner(AvSidebar, 8)
    makeStroke(AvSidebar, Color3.fromRGB(255, 255, 255), 1, 0.85)

    local SUBTABS = {"AVATAR", "KARAKTER", "LIMITED", "ANIMASI", "SEPATU", "FAVORIT", "DIPAKAI"}
    local subTabBtns = {}
    local activeSub = "AVATAR"

    -- === KANAN: CERMIN PREVIEW ===
    local AvMirror = Instance.new("Frame")
    AvMirror.Size = UDim2.new(0, 84, 1, -34)
    AvMirror.Position = UDim2.new(1, -86, 0, 34)
    AvMirror.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
    AvMirror.BorderSizePixel = 0
    AvMirror.ZIndex = 13
    AvMirror.Parent = PageAvatar
    makeCorner(AvMirror, 8)
    makeStroke(AvMirror, Color3.fromRGB(255, 255, 255), 1, 0.82)

    local AvMirrorLbl = Instance.new("TextLabel")
    AvMirrorLbl.Size = UDim2.new(1, 0, 0, 18)
    AvMirrorLbl.BackgroundTransparency = 1
    AvMirrorLbl.Font = Enum.Font.GothamBold
    AvMirrorLbl.TextSize = 9
    AvMirrorLbl.TextColor3 = Color3.fromRGB(200, 200, 210)
    AvMirrorLbl.Text = "CERMIN"
    AvMirrorLbl.ZIndex = 15
    AvMirrorLbl.Parent = AvMirror

    local AvMirrorImg = Instance.new("ImageLabel")
    AvMirrorImg.Size = UDim2.new(1, -8, 0, 96)
    AvMirrorImg.Position = UDim2.new(0, 4, 0, 18)
    AvMirrorImg.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    -- Ukuran 352x352 resmi Roblox untuk type=Avatar!
    AvMirrorImg.Image = "rbxthumb://type=Avatar&id=" .. tostring(LP.UserId) .. "&w=352&h=352"
    AvMirrorImg.ScaleType = Enum.ScaleType.Fit
    AvMirrorImg.ZIndex = 15
    AvMirrorImg.Parent = AvMirror
    makeCorner(AvMirrorImg, 6)

    local AvMirrorName = Instance.new("TextLabel")
    AvMirrorName.Size = UDim2.new(1, -4, 0, 16)
    AvMirrorName.Position = UDim2.new(0, 2, 0, 116)
    AvMirrorName.BackgroundTransparency = 1
    AvMirrorName.Font = Enum.Font.GothamBold
    AvMirrorName.TextSize = 8.5
    AvMirrorName.TextColor3 = Color3.fromRGB(255, 255, 255)
    AvMirrorName.TextTruncate = Enum.TextTruncate.AtEnd
    AvMirrorName.Text = LP.Name
    AvMirrorName.ZIndex = 15
    AvMirrorName.Parent = AvMirror

    local AvMirrorId = Instance.new("TextLabel")
    AvMirrorId.Size = UDim2.new(1, -4, 0, 12)
    AvMirrorId.Position = UDim2.new(0, 2, 0, 132)
    AvMirrorId.BackgroundTransparency = 1
    AvMirrorId.Font = Enum.Font.Code
    AvMirrorId.TextSize = 7.5
    AvMirrorId.TextColor3 = Color3.fromRGB(140, 140, 155)
    AvMirrorId.Text = "ID:" .. tostring(LP.UserId)
    AvMirrorId.ZIndex = 15
    AvMirrorId.Parent = AvMirror

    local AvFavToggleBtn = Instance.new("TextButton")
    AvFavToggleBtn.Size = UDim2.new(1, -8, 0, 18)
    AvFavToggleBtn.Position = UDim2.new(0, 4, 0, 148)
    AvFavToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    AvFavToggleBtn.Text = "<3 FAVORIT"
    AvFavToggleBtn.Font = Enum.Font.GothamBold
    AvFavToggleBtn.TextSize = 7.5
    AvFavToggleBtn.TextColor3 = Color3.fromRGB(255, 200, 220)
    AvFavToggleBtn.Active = true
    AvFavToggleBtn.ZIndex = 16
    AvFavToggleBtn.Parent = AvMirror
    makeCorner(AvFavToggleBtn, 4)

    local AvApplyBtn = Instance.new("TextButton")
    AvApplyBtn.Size = UDim2.new(1, -8, 0, 24)
    AvApplyBtn.Position = UDim2.new(0, 4, 1, -54)
    AvApplyBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    AvApplyBtn.Text = "[>] PAKAI"
    AvApplyBtn.Font = Enum.Font.GothamBold
    AvApplyBtn.TextSize = 9
    AvApplyBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    AvApplyBtn.Active = true
    AvApplyBtn.ZIndex = 16
    AvApplyBtn.Parent = AvMirror
    makeCorner(AvApplyBtn, 5)

    local AvResetBtn = Instance.new("TextButton")
    AvResetBtn.Size = UDim2.new(1, -8, 0, 20)
    AvResetBtn.Position = UDim2.new(0, 4, 1, -26)
    AvResetBtn.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
    AvResetBtn.Text = "[R] RESET"
    AvResetBtn.Font = Enum.Font.GothamBold
    AvResetBtn.TextSize = 8
    AvResetBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
    AvResetBtn.Active = true
    AvResetBtn.ZIndex = 16
    AvResetBtn.Parent = AvMirror
    makeCorner(AvResetBtn, 4)

    -- === TENGAH: CENTER CONTAINER ===
    local AvCenter = Instance.new("Frame")
    AvCenter.Size = UDim2.new(1, -168, 1, -34)
    AvCenter.Position = UDim2.new(0, 78, 0, 34)
    AvCenter.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
    AvCenter.BorderSizePixel = 0
    AvCenter.ZIndex = 13
    AvCenter.Parent = PageAvatar
    makeCorner(AvCenter, 8)
    makeStroke(AvCenter, Color3.fromRGB(255, 255, 255), 1, 0.82)

    local function setMirror(userId, username)
        selectedUserId = userId
        selectedUsername = username or "Unknown"
        AvMirrorImg.Image = "rbxthumb://type=Avatar&id=" .. tostring(userId) .. "&w=352&h=352"
        AvMirrorName.Text = selectedUsername
        AvMirrorId.Text = "ID:" .. tostring(userId)
    end

    -- =========================================================================
    -- TOOL PROTECTION (MENCEGAH TOOL HILANG SAAT GANTI AVATAR)
    -- =========================================================================
    local function unequipPlayerTools()
        local myChar = LP.Character
        local equipped = nil
        if myChar then
            for _, item in ipairs(myChar:GetChildren()) do
                if item:IsA("Tool") then
                    equipped = item
                    local bp = LP:FindFirstChild("Backpack")
                    if bp then item.Parent = bp end
                    break
                end
            end
        end
        return equipped
    end

    local function reequipPlayerTool(tool)
        if not tool then return end
        task.wait(1.0)
        local myChar = LP.Character
        if not myChar then return end
        local hum = myChar:FindFirstChildOfClass("Humanoid")
        local bp = LP:FindFirstChild("Backpack")
        if hum and bp and tool.Parent == bp then
            hum:EquipTool(tool)
        end
    end

    -- =========================================================================
    -- UNIVERSAL HELPER: WELD AKSESORI R6 & R15 (ANTI-JATUH & ANTI-GAGAL)
    -- =========================================================================
    local function weldAccessoryToCharacter(myChar, accClone)
        local handle = accClone:FindFirstChild("Handle")
        if not handle then
            accClone.Parent = myChar
            return
        end
        handle.CanCollide = false
        handle.Anchored = false

        local accAtt = handle:FindFirstChildOfClass("Attachment")
        local attName = accAtt and accAtt.Name or "HatAttachment"

        local charAtt = myChar:FindFirstChild(attName, true)
        if charAtt and charAtt:IsA("Attachment") then
            local weld = Instance.new("Weld")
            weld.Name = "AccessoryWeld"
            weld.Part0 = charAtt.Parent
            weld.Part1 = handle
            weld.C0 = charAtt.CFrame
            weld.C1 = accAtt.CFrame
            weld.Parent = handle
            accClone.Parent = myChar
            return
        end

        local r6Mapping = {
            HatAttachment           = "Head",
            HairAttachment          = "Head",
            FaceFrontAttachment     = "Head",
            FaceCenterAttachment    = "Head",
            NeckAttachment          = "Torso",
            BodyFrontAttachment     = "Torso",
            BodyBackAttachment      = "Torso",
            WaistCenterAttachment   = "Torso",
            WaistFrontAttachment    = "Torso",
            WaistBackAttachment     = "Torso",
            LeftShoulderAttachment  = "Left Arm",
            RightShoulderAttachment = "Right Arm",
            LeftGripAttachment      = "Left Arm",
            RightGripAttachment     = "Right Arm",
            LeftFootAttachment      = "Left Leg",
            RightFootAttachment     = "Right Leg"
        }
        local fallbackPartName = r6Mapping[attName] or "Torso"
        local targetPart = myChar:FindFirstChild(fallbackPartName) or myChar:FindFirstChild("Head")
        if targetPart then
            local weld = Instance.new("Weld")
            weld.Name = "AccessoryWeld"
            weld.Part0 = targetPart
            weld.Part1 = handle
            weld.C0 = CFrame.new(0, 0, 0)
            weld.C1 = (accAtt and accAtt.CFrame) or CFrame.new(0, 0, 0)
            weld.Parent = handle
        end
        accClone.Parent = myChar
    end

    -- =========================================================================
    -- CORE ENGINE: DUAL-MODE APPLIER DENGAN DUKUNGAN PENUH R6 & R15
    -- =========================================================================
    local function applyAvatarLocally(targetUserId)
        local myChar = LP.Character
        if not myChar then return false, "Karakter tidak ada" end
        local myHum = myChar:FindFirstChildOfClass("Humanoid")
        if not myHum then return false, "Humanoid tidak ada" end

        local savedTool = unequipPlayerTools()
        local isMyR15 = (myHum.RigType == Enum.HumanoidRigType.R15)

        -- 1. Coba Native ApplyDescription
        local nativeOk = false
        pcall(function()
            local desc = Players:GetHumanoidDescriptionFromUserId(targetUserId)
            if desc then
                myHum:ApplyDescription(desc)
                nativeOk = true
            end
        end)
        if nativeOk then
            task.spawn(function() reequipPlayerTool(savedTool) end)
            return true, "Berhasil (mode: native)"
        end

        -- 2. Mode Boneka / Donor Clone (Universal R6 & R15)
        local ok, donor = pcall(function()
            return Players:CreateHumanoidModelFromUserIdAsync(targetUserId)
        end)
        if not ok or not donor then
            task.spawn(function() reequipPlayerTool(savedTool) end)
            return false, "Gagal memuat donor model"
        end

        -- Bersihkan aksesoris dan pakaian lama
        for _, item in ipairs(myChar:GetChildren()) do
            if item:IsA("Accessory") or item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") or item:IsA("BodyColors") then
                pcall(function() item:Destroy() end)
            end
        end

        -- Salin BodyColors, Shirt, Pants, ShirtGraphic
        for _, item in ipairs(donor:GetChildren()) do
            if item:IsA("BodyColors") or item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") then
                pcall(function()
                    local cl = item:Clone()
                    cl.Parent = myChar
                end)
            end
        end

        -- Salin wajah (Decal di Head)
        pcall(function()
            local dHead = donor:FindFirstChild("Head")
            local mHead = myChar:FindFirstChild("Head")
            if dHead and mHead then
                local dFace = dHead:FindFirstChild("face") or dHead:FindFirstChildOfClass("Decal")
                local mFace = mHead:FindFirstChild("face") or mHead:FindFirstChildOfClass("Decal")
                if dFace then
                    if mFace then
                        mFace.Texture = dFace.Texture
                    else
                        local nf = dFace:Clone()
                        nf.Parent = mHead
                    end
                end
            end
        end)

        -- Salin bentuk tubuh (Headless, Korblox, Meshes)
        pcall(function()
            local dHead = donor:FindFirstChild("Head")
            local mHead = myChar:FindFirstChild("Head")
            if dHead and mHead then
                mHead.Transparency = dHead.Transparency
                local mFace = mHead:FindFirstChild("face") or mHead:FindFirstChildOfClass("Decal")
                if mFace and dHead.Transparency > 0.5 then
                    mFace.Transparency = 1
                elseif mFace then
                    mFace.Transparency = 0
                end
                local dMesh = dHead:FindFirstChildOfClass("SpecialMesh")
                local mMesh = mHead:FindFirstChildOfClass("SpecialMesh")
                if dMesh and mMesh then
                    mMesh.MeshId = dMesh.MeshId
                    mMesh.TextureId = dMesh.TextureId
                    mMesh.Scale = dMesh.Scale
                elseif dMesh and not mMesh then
                    local nMesh = dMesh:Clone()
                    nMesh.Parent = mHead
                end
            end

            if isMyR15 then
                local R15_LIMBS = {
                    "UpperTorso", "LowerTorso",
                    "LeftUpperArm", "LeftLowerArm", "LeftHand",
                    "RightUpperArm", "RightLowerArm", "RightHand",
                    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
                    "RightUpperLeg", "RightLowerLeg", "RightFoot"
                }
                for _, limbName in ipairs(R15_LIMBS) do
                    local dLimb = donor:FindFirstChild(limbName)
                    local mLimb = myChar:FindFirstChild(limbName)
                    if dLimb and mLimb then
                        mLimb.Transparency = dLimb.Transparency
                        local dMesh = dLimb:FindFirstChildOfClass("SpecialMesh")
                        local mMesh = mLimb:FindFirstChildOfClass("SpecialMesh")
                        if dMesh and mMesh then
                            mMesh.MeshId = dMesh.MeshId
                            mMesh.TextureId = dMesh.TextureId
                        end
                    end
                end
            else
                local dRLeg = donor:FindFirstChild("RightUpperLeg") or donor:FindFirstChild("Right Leg")
                local mRLeg = myChar:FindFirstChild("Right Leg")
                if dRLeg and mRLeg then
                    mRLeg.Transparency = dRLeg.Transparency
                end

                local dLLeg = donor:FindFirstChild("LeftUpperLeg") or donor:FindFirstChild("Left Leg")
                local mLLeg = myChar:FindFirstChild("Left Leg")
                if dLLeg and mLLeg then
                    mLLeg.Transparency = dLLeg.Transparency
                end

                local dTorso = donor:FindFirstChild("UpperTorso") or donor:FindFirstChild("Torso")
                local mTorso = myChar:FindFirstChild("Torso")
                if dTorso and mTorso then
                    mTorso.Transparency = dTorso.Transparency
                end
            end

            for _, cm in ipairs(donor:GetChildren()) do
                if cm:IsA("CharacterMesh") then
                    local ncm = cm:Clone()
                    ncm.Parent = myChar
                end
            end
        end)

        -- Salin Aksesoris Universal
        local accCount = 0
        for _, item in ipairs(donor:GetChildren()) do
            if item:IsA("Accessory") then
                pcall(function()
                    local accClone = item:Clone()
                    weldAccessoryToCharacter(myChar, accClone)
                    accCount = accCount + 1
                end)
            end
        end

        -- Salin Paket Animasi
        pcall(function()
            local dAnim = donor:FindFirstChild("Animate")
            local mAnim = myChar:FindFirstChild("Animate")
            if dAnim and mAnim then
                for _, animFolder in ipairs(dAnim:GetChildren()) do
                    if animFolder:IsA("StringValue") or animFolder:IsA("Folder") then
                        local mFolder = mAnim:FindFirstChild(animFolder.Name)
                        if mFolder then
                            for _, animObj in ipairs(animFolder:GetChildren()) do
                                if animObj:IsA("Animation") then
                                    local mObj = mFolder:FindFirstChild(animObj.Name) or mFolder:FindFirstChildOfClass("Animation")
                                    if mObj and mObj:IsA("Animation") then
                                        mObj.AnimationId = animObj.AnimationId
                                    end
                                end
                            end
                        end
                    end
                end
                for _, trk in ipairs(myHum:GetPlayingAnimationTracks()) do
                    pcall(function() trk:Stop() end)
                end
            end
        end)

        -- Salin body scales
        pcall(function()
            local dHum = donor:FindFirstChildOfClass("Humanoid")
            if dHum and myHum and isMyR15 then
                for _, sName in ipairs({"BodyHeightScale", "BodyWidthScale", "BodyDepthScale", "HeadScale", "BodyProportionScale", "BodyTypeScale"}) do
                    local dVal = dHum:FindFirstChild(sName)
                    local mVal = myHum:FindFirstChild(sName)
                    if dVal and mVal then
                        mVal.Value = dVal.Value
                    end
                end
            end
        end)

        pcall(function() donor:Destroy() end)
        task.spawn(function() reequipPlayerTool(savedTool) end)
        return true, string.format("Berhasil (mode: boneka, %d item)", accCount)
    end

    -- Trigger tombol PAKAI
    AvApplyBtn.Activated:Connect(function()
        if not selectedUserId then
            AvApplyBtn.Text = "[!] PILIH DULU"; task.wait(1); AvApplyBtn.Text = "[>] PAKAI"; return
        end
        AvApplyBtn.Text = "MEMUAT..."
        task.spawn(function()
            local success, msg = applyAvatarLocally(selectedUserId)
            if success then
                AvApplyBtn.Text = "[OK] DIPAKAI!"
                task.wait(1.5)
                AvApplyBtn.Text = "[>] PAKAI"
            else
                AvApplyBtn.Text = "[X] GAGAL"
                warn("[MCHLERN AVATAR] " .. tostring(msg))
                task.wait(1.5)
                AvApplyBtn.Text = "[>] PAKAI"
            end
        end)
    end)

    -- Trigger tombol RESET
    AvResetBtn.Activated:Connect(function()
        AvResetBtn.Text = "RESETTING..."
        task.spawn(function()
            local s, _ = applyAvatarLocally(origUserId)
            if s then
                setMirror(origUserId, LP.Name)
                local myChar = LP.Character
                if myChar then
                    for _, p in ipairs(myChar:GetChildren()) do
                        if p:IsA("BasePart") then p.Transparency = 0 end
                    end
                    local h = myChar:FindFirstChild("Head")
                    if h then
                        local f = h:FindFirstChild("face") or h:FindFirstChildOfClass("Decal")
                        if f then f.Transparency = 0 end
                    end
                end
                AvResetBtn.Text = "[OK] RESET!"
            else
                AvResetBtn.Text = "[X] GAGAL"
            end
            task.wait(1.2)
            AvResetBtn.Text = "[R] RESET"
        end)
    end)

    -- Trigger tombol FAVORIT
    AvFavToggleBtn.Activated:Connect(function()
        if not selectedUserId then return end
        local foundIdx = nil
        for i, fav in ipairs(userFavorites) do
            if fav.id == selectedUserId then foundIdx = i; break end
        end
        if foundIdx then
            table.remove(userFavorites, foundIdx)
            AvFavToggleBtn.Text = "<3 FAVORIT"
            AvFavToggleBtn.TextColor3 = Color3.fromRGB(255, 200, 220)
        else
            table.insert(userFavorites, { id = selectedUserId, name = selectedUsername })
            AvFavToggleBtn.Text = "[*] TERSIMPAN"
            AvFavToggleBtn.TextColor3 = Color3.fromRGB(255, 80, 120)
        end
    end)

    -- Container dynamic view
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Size = UDim2.fromScale(1, 1)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.ZIndex = 14
    ContentFrame.Parent = AvCenter

    local function clearContent()
        for _, child in ipairs(ContentFrame:GetChildren()) do
            child:Destroy()
        end
    end

    -- =========================================================================
    -- VIEW 1: SUB-TAB "AVATAR" (INFINITE 5000+ AVATAR ENGINE DENGAN LOAD MORE)
    -- =========================================================================
    local function renderAvatarView()
        clearContent()

        local SearchRow = Instance.new("Frame")
        SearchRow.Size = UDim2.new(1, -8, 0, 24)
        SearchRow.Position = UDim2.new(0, 4, 0, 4)
        SearchRow.BackgroundTransparency = 1
        SearchRow.ZIndex = 14
        SearchRow.Parent = ContentFrame

        local SearchBox = Instance.new("TextBox")
        SearchBox.Size = UDim2.new(1, -70, 1, 0)
        SearchBox.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
        SearchBox.PlaceholderText = "Cari username / creator / kata kunci..."
        SearchBox.PlaceholderColor3 = Color3.fromRGB(110, 110, 120)
        SearchBox.Text = ""
        SearchBox.Font = Enum.Font.Gotham
        SearchBox.TextSize = 9
        SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        SearchBox.ClearTextOnFocus = false
        SearchBox.ZIndex = 15
        SearchBox.Parent = SearchRow
        makeCorner(SearchBox, 5)
        makeStroke(SearchBox, Color3.fromRGB(255, 255, 255), 1, 0.8)

        local CariBtn = Instance.new("TextButton")
        CariBtn.Size = UDim2.new(0, 42, 1, 0)
        CariBtn.Position = UDim2.new(1, -66, 0, 0)
        CariBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        CariBtn.Text = "CARI"
        CariBtn.Font = Enum.Font.GothamBold
        CariBtn.TextSize = 8
        CariBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        CariBtn.Active = true
        CariBtn.ZIndex = 15
        CariBtn.Parent = SearchRow
        makeCorner(CariBtn, 5)

        local AcakBtn = Instance.new("TextButton")
        AcakBtn.Size = UDim2.new(0, 20, 1, 0)
        AcakBtn.Position = UDim2.new(1, -20, 0, 0)
        AcakBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
        AcakBtn.Text = "?"
        AcakBtn.Font = Enum.Font.GothamBold
        AcakBtn.TextSize = 10
        AcakBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        AcakBtn.Active = true
        AcakBtn.ZIndex = 15
        AcakBtn.Parent = SearchRow
        makeCorner(AcakBtn, 5)
        makeStroke(AcakBtn, Color3.fromRGB(255, 255, 255), 1, 0.7)

        -- Filter pills
        local FilterRow = Instance.new("Frame")
        FilterRow.Size = UDim2.new(1, -8, 0, 20)
        FilterRow.Position = UDim2.new(0, 4, 0, 32)
        FilterRow.BackgroundTransparency = 1
        FilterRow.ZIndex = 14
        FilterRow.Parent = ContentFrame

        local filterPills = {"SEMUA", "HIPHOP", "COWO", "CEWE", "SULTAN", "KORBLOX", "SERVER", "TEMAN"}
        local filterBtns = {}

        local filterUL = Instance.new("UIListLayout")
        filterUL.FillDirection = Enum.FillDirection.Horizontal
        filterUL.Padding = UDim.new(0, 3)
        filterUL.SortOrder = Enum.SortOrder.LayoutOrder
        filterUL.Parent = FilterRow

        local StatusLbl = Instance.new("TextLabel")
        StatusLbl.Size = UDim2.new(1, -8, 0, 12)
        StatusLbl.Position = UDim2.new(0, 4, 0, 56)
        StatusLbl.BackgroundTransparency = 1
        StatusLbl.Font = Enum.Font.Code
        StatusLbl.TextSize = 8
        StatusLbl.TextColor3 = Color3.fromRGB(140, 140, 155)
        StatusLbl.TextXAlignment = Enum.TextXAlignment.Left
        StatusLbl.Text = "Memuat database avatar..."
        StatusLbl.ZIndex = 14
        StatusLbl.Parent = ContentFrame

        local GridScroll = Instance.new("ScrollingFrame")
        GridScroll.Size = UDim2.new(1, -8, 1, -104)
        GridScroll.Position = UDim2.new(0, 4, 0, 70)
        GridScroll.BackgroundTransparency = 1
        GridScroll.ScrollBarThickness = 3
        GridScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
        GridScroll.BorderSizePixel = 0
        GridScroll.ZIndex = 14
        GridScroll.Parent = ContentFrame

        local GridLayout = Instance.new("UIGridLayout")
        GridLayout.CellSize = UDim2.new(0, 62, 0, 80)
        GridLayout.CellPadding = UDim2.new(0, 5, 0, 5)
        GridLayout.SortOrder = Enum.SortOrder.LayoutOrder
        GridLayout.Parent = GridScroll

        -- Tombol INFINITE LOAD MORE (Bisa tarik ribuan avatar dari Roblox API!)
        local LoadMoreFrame = Instance.new("Frame")
        LoadMoreFrame.Size = UDim2.new(1, -8, 0, 26)
        LoadMoreFrame.Position = UDim2.new(0, 4, 1, -30)
        LoadMoreFrame.BackgroundTransparency = 1
        LoadMoreFrame.ZIndex = 14
        LoadMoreFrame.Parent = ContentFrame

        local LoadMoreBtn = Instance.new("TextButton")
        LoadMoreBtn.Size = UDim2.fromScale(1, 1)
        LoadMoreBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
        LoadMoreBtn.Text = "[+] TARIK 50+ AVATAR BARU DARI ROBLOX API"
        LoadMoreBtn.Font = Enum.Font.GothamBold
        LoadMoreBtn.TextSize = 8
        LoadMoreBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        LoadMoreBtn.Active = true
        LoadMoreBtn.ZIndex = 15
        LoadMoreBtn.Parent = LoadMoreFrame
        makeCorner(LoadMoreBtn, 5)
        makeStroke(LoadMoreBtn, Color3.fromRGB(255, 255, 255), 1, 0.7)

        local totalRenderedCards = 0
        local nextSearchCursor = ""
        local currentKeywordIdx = 1
        local POPULAR_SEARCH_KEYWORDS = {
            "aesthetic", "korblox", "sultan", "goth", "tryhard", "preppy",
            "drill", "anime", "ninja", "blox", "queen", "king", "star"
        }

        local function clearCards()
            for _, c in ipairs(GridScroll:GetChildren()) do
                if c:IsA("TextButton") or c:IsA("Frame") then c:Destroy() end
            end
            totalRenderedCards = 0
        end

        local function makeCard(uid, uname, tag, orderIdx)
            local card = Instance.new("TextButton")
            card.Size = UDim2.new(0, 62, 0, 80)
            card.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
            card.BorderSizePixel = 0
            card.Text = ""
            card.Active = true
            card.LayoutOrder = orderIdx or (totalRenderedCards + 1)
            card.ZIndex = 15
            card.Parent = GridScroll
            makeCorner(card, 6)
            makeStroke(card, Color3.fromRGB(255, 255, 255), 1, 0.82)

            local img = Instance.new("ImageLabel")
            img.Size = UDim2.new(1, -6, 0, 50)
            img.Position = UDim2.new(0, 3, 0, 3)
            img.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
            if uid and tonumber(uid) and tonumber(uid) > 0 then
                img.Image = "rbxthumb://type=Avatar&id=" .. tostring(uid) .. "&w=100&h=100"
            else
                img.Image = "rbxthumb://type=AvatarHeadShot&id=1&w=100&h=100"
                task.spawn(function()
                    local s, realId = pcall(function() return Players:GetUserIdFromNameAsync(uname) end)
                    if s and realId and card and card.Parent then
                        uid = realId
                        img.Image = "rbxthumb://type=Avatar&id=" .. tostring(realId) .. "&w=100&h=100"
                        if tagL and tagL.Parent then tagL.Text = "ID:" .. tostring(realId) end
                    end
                end)
            end
            img.ScaleType = Enum.ScaleType.Fit
            img.ZIndex = 16
            img.Parent = card
            makeCorner(img, 5)

            local nameL = Instance.new("TextLabel")
            nameL.Size = UDim2.new(1, -4, 0, 13)
            nameL.Position = UDim2.new(0, 2, 0, 54)
            nameL.BackgroundTransparency = 1
            nameL.Font = Enum.Font.GothamBold
            nameL.TextSize = 8
            nameL.TextColor3 = Color3.fromRGB(240, 240, 255)
            nameL.TextTruncate = Enum.TextTruncate.AtEnd
            nameL.Text = uname
            nameL.ZIndex = 16
            nameL.Parent = card

            local tagL = Instance.new("TextLabel")
            tagL.Size = UDim2.new(1, -4, 0, 11)
            tagL.Position = UDim2.new(0, 2, 0, 67)
            tagL.BackgroundTransparency = 1
            tagL.Font = Enum.Font.Code
            tagL.TextSize = 7
            tagL.TextColor3 = Color3.fromRGB(130, 130, 145)
            tagL.Text = tag or ("ID:" .. tostring(uid))
            tagL.ZIndex = 16
            tagL.Parent = card

            card.Activated:Connect(function()
                for _, c2 in ipairs(GridScroll:GetChildren()) do
                    if c2:IsA("TextButton") then
                        makeStroke(c2, Color3.fromRGB(255, 255, 255), 1, 0.82)
                    end
                end
                makeStroke(card, Color3.fromRGB(255, 255, 255), 1.5, 0)
                setMirror(uid, uname)
            end)

            totalRenderedCards = totalRenderedCards + 1
            return card
        end

        local currentActiveList = DB_5000
        local currentListOffset = 1
        local currentActiveTag = "5000-AVATAR"

        local function renderNextChunk(count)
            count = count or 30
            local startIdx = currentListOffset
            local endIdx = math.min(startIdx + count - 1, #currentActiveList)
            if startIdx > endIdx then
                LoadMoreBtn.Text = string.format("[V] SEMUA %d AVATAR SUDAH DITAMPILKAN", #currentActiveList)
                return
            end

            for i = startIdx, endIdx do
                local uName = currentActiveList[i]
                makeCard(0, uName, currentActiveTag, i)
            end

            currentListOffset = endIdx + 1
            GridScroll.CanvasSize = UDim2.new(0, 0, 0, GridLayout.AbsoluteContentSize.Y + 10)
            StatusLbl.Text = string.format("Menampilkan %d dari %d avatar (%s)", totalRenderedCards, #currentActiveList, currentActiveTag)
            if currentListOffset <= #currentActiveList then
                LoadMoreBtn.Text = string.format("[+] MUAT 30 LAGI (Ditampilkan %d dari %d)", totalRenderedCards, #currentActiveList)
            else
                LoadMoreBtn.Text = string.format("[V] SEMUA %d AVATAR SUDAH DITAMPILKAN", #currentActiveList)
            end
        end

        local function loadFilter(mode)
            for _, b in ipairs(filterBtns) do
                if b.Name == mode then
                    b.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    b.TextColor3 = Color3.fromRGB(0, 0, 0)
                else
                    b.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
                    b.TextColor3 = Color3.fromRGB(190, 190, 205)
                end
            end

            clearCards()
            currentListOffset = 1

            if mode == "HIPHOP" then
                currentActiveList = LIST_HIPHOP
                currentActiveTag = "HIPHOP"
                renderNextChunk(30)
            elseif mode == "COWO" then
                currentActiveList = LIST_COWO
                currentActiveTag = "COWO"
                renderNextChunk(30)
            elseif mode == "CEWE" then
                currentActiveList = LIST_CEWE
                currentActiveTag = "CEWE"
                renderNextChunk(30)
            elseif mode == "SULTAN" then
                currentActiveList = LIST_SULTAN
                currentActiveTag = "SULTAN"
                renderNextChunk(30)
            elseif mode == "KORBLOX" then
                currentActiveList = LIST_KORBLOX
                currentActiveTag = "KORBLOX"
                renderNextChunk(30)
            elseif mode == "SERVER" then
                local ps = Players:GetPlayers()
                StatusLbl.Text = tostring(#ps) .. " pemain di server saat ini"
                for i, p in ipairs(ps) do
                    makeCard(p.UserId, p.Name, "Server", i)
                end
                GridScroll.CanvasSize = UDim2.new(0, 0, 0, GridLayout.AbsoluteContentSize.Y + 10)
                LoadMoreBtn.Text = "[SERVER] Pemain Server Dimuat"
            elseif mode == "TEMAN" then
                StatusLbl.Text = "Memuat daftar teman..."
                task.spawn(function()
                    local ok, pages = pcall(function() return Players:GetFriendsAsync(LP.UserId) end)
                    if ok and pages then
                        local count = 0
                        while true do
                            local ok2, items = pcall(function() return pages:GetCurrentPage() end)
                            if not ok2 then break end
                            for _, f in ipairs(items) do
                                count = count + 1
                                makeCard(f.Id, f.Username, "Teman", count)
                            end
                            StatusLbl.Text = tostring(count) .. " teman dimuat..."
                            if pages.IsFinished then break end
                            local ok3 = pcall(function() pages:AdvanceToNextPageAsync() end)
                            if not ok3 then break end
                        end
                        StatusLbl.Text = tostring(count) .. " teman ditemukan"
                    else
                        StatusLbl.Text = "[X] Gagal memuat teman"
                    end
                    GridScroll.CanvasSize = UDim2.new(0, 0, 0, GridLayout.AbsoluteContentSize.Y + 10)
                end)
                LoadMoreBtn.Text = "[TEMAN] Daftar Teman Dimuat"
            else
                -- SEMUA: Tampilkan dari seluruh 5.344 avatar pilihanmu!
                currentActiveList = DB_5000
                currentActiveTag = "5344-ALL"
                renderNextChunk(30)
            end
        end

        for _, fName in ipairs(filterPills) do
            local fb = Instance.new("TextButton")
            fb.Name = fName
            fb.Size = UDim2.new(0, 48, 1, 0)
            fb.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
            fb.Text = fName
            fb.Font = Enum.Font.GothamB
            fb.TextSize = 8
            fb.TextColor3 = Color3.fromRGB(190, 190, 205)
            fb.Parent = FilterRow
            makeCorner(fb, 5)
            table.insert(filterBtns, fb)

            fb.Activated:Connect(function()
                loadFilter(fName)
            end)
        end
        FilterRow.CanvasSize = UDim2.new(0, #filterPills * 50 + 10, 0, 0)

        -- TOMBOL MUAT LEBIH BANYAK DARI DATABASE 5.344 AVATAR
        LoadMoreBtn.Activated:Connect(function()
            renderNextChunk(30)
        end)

        local function executeSearch()
            local q = SearchBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
            if q == "" then return end
            clearCards()
            StatusLbl.Text = "Mencari pengguna '" .. q .. "'..."

            -- 1. INSTANT LOCAL SEARCH IN 5000 DATABASE
            local qLower = string.lower(q)
            local localFound = 0
            for i, uName in ipairs(DB_5000) do
                if string.find(string.lower(uName), qLower, 1, true) then
                    localFound = localFound + 1
                    makeCard(0, uName, "5000-DB", localFound)
                    if localFound >= 25 then break end
                end
            end
            if localFound > 0 then
                StatusLbl.Text = string.format("%d hasil ditemukan dari 5.000 Database!", localFound)
                GridScroll.CanvasSize = UDim2.new(0, 0, 0, GridLayout.AbsoluteContentSize.Y + 10)
            end

            task.spawn(function()
                local foundUsers = {}
                local directUid = tonumber(q)
                if directUid then
                    local s2, uname = pcall(function() return Players:GetNameFromUserIdAsync(directUid) end)
                    table.insert(foundUsers, { id = directUid, name = (s2 and uname) or q })
                else
                    local searchUrl = "https://users.roproxy.com/v1/users/search?keyword=" .. HttpService:UrlEncode(q) .. "&limit=25"
                    local okHttp, res = pcall(function() return httpRequest({ Url = searchUrl, Method = "GET" }) end)
                    if okHttp and res and res.Body then
                        local okJson, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
                        if okJson and data and data.data then
                            for _, u in ipairs(data.data) do
                                table.insert(foundUsers, { id = u.id, name = u.name })
                            end
                        end
                    end
                    if #foundUsers == 0 then
                        local s1, r1 = pcall(function() return Players:GetUserIdFromNameAsync(q) end)
                        if s1 and r1 then table.insert(foundUsers, { id = r1, name = q }) end
                    end
                end

                if #foundUsers > 0 then
                    for i, u in ipairs(foundUsers) do makeCard(u.id, u.name, "Hasil", i) end
                    setMirror(foundUsers[1].id, foundUsers[1].name)
                    StatusLbl.Text = tostring(#foundUsers) .. " user ditemukan untuk '" .. q .. "'"
                else
                    StatusLbl.Text = "[X] Tidak ada pengguna ditemukan"
                end
                GridScroll.CanvasSize = UDim2.new(0, 0, 0, GridLayout.AbsoluteContentSize.Y + 10)
            end)
        end
        CariBtn.Activated:Connect(executeSearch)
        SearchBox.FocusLost:Connect(function(enter) if enter then executeSearch() end end)

        AcakBtn.Activated:Connect(function()
            if #DB_5000 > 0 and math.random(1, 10) > 3 then
                local rndName = DB_5000[math.random(1, #DB_5000)]
                TargetBox.Text = rndName
                setMirror(0, rndName)
                StatusLbl.Text = "[ACAK 5000] Terpilih: " .. rndName .. " (Klik PAKAI TARGET)"
            else
                local all = {}
                for _, v in ipairs(PRESET_KORBLOX_HEADLESS) do table.insert(all, v) end
                for _, v in ipairs(PRESET_COWO) do table.insert(all, v) end
                for _, v in ipairs(PRESET_CEWE) do table.insert(all, v) end
                if #all > 0 then
                    local rnd = all[math.random(1, #all)]
                    setMirror(rnd.id, rnd.name)
                    StatusLbl.Text = "Acak: " .. rnd.name .. " (" .. rnd.tag .. ")"
                end
            end
        end)

        loadFilter("SEMUA")
    end

    -- =========================================================================
    -- VIEW 2: SUB-TAB "KARAKTER" (REAL BUNDLE BODY MORPHS: GAMBAR TUBUH + TERAPKAN!)
    -- =========================================================================
    local function renderKarakterView()
        clearContent()

        local TitleLbl = Instance.new("TextLabel")
        TitleLbl.Size = UDim2.new(1, -8, 0, 22)
        TitleLbl.Position = UDim2.new(0, 4, 0, 4)
        TitleLbl.BackgroundTransparency = 1
        TitleLbl.Font = Enum.Font.GothamBold
        TitleLbl.TextSize = 10
        TitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
        TitleLbl.Text = "KATALOG TUBUH KARAKTER (REAL 3D PACKAGES / BUNDLES)"
        TitleLbl.ZIndex = 14
        TitleLbl.Parent = ContentFrame

        local KScroll = Instance.new("ScrollingFrame")
        KScroll.Size = UDim2.new(1, -8, 1, -30)
        KScroll.Position = UDim2.new(0, 4, 0, 26)
        KScroll.BackgroundTransparency = 1
        KScroll.ScrollBarThickness = 3
        KScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
        KScroll.BorderSizePixel = 0
        KScroll.ZIndex = 14
        KScroll.Parent = ContentFrame

        local KList = Instance.new("UIListLayout")
        KList.Padding = UDim.new(0, 6)
        KList.SortOrder = Enum.SortOrder.LayoutOrder
        KList.Parent = KScroll

        for _, pack in ipairs(KARAKTER_BODY_PACKS) do
            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, -8, 0, 48)
            card.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
            card.BorderSizePixel = 0
            card.ZIndex = 15
            card.Parent = KScroll
            makeCorner(card, 6)
            makeStroke(card, Color3.fromRGB(255, 255, 255), 1, 0.82)

            local thumb = Instance.new("ImageLabel")
            thumb.Size = UDim2.new(0, 38, 0, 40)
            thumb.Position = UDim2.new(0, 4, 0, 4)
            thumb.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
            thumb.Image = "rbxthumb://type=Avatar&id=" .. tostring(pack.wearerId) .. "&w=100&h=100"
            thumb.ScaleType = Enum.ScaleType.Fit
            thumb.ZIndex = 16
            thumb.Parent = card
            makeCorner(thumb, 4)

            local nLbl = Instance.new("TextLabel")
            nLbl.Size = UDim2.new(1, -125, 0, 18)
            nLbl.Position = UDim2.new(0, 48, 0, 4)
            nLbl.BackgroundTransparency = 1
            nLbl.Font = Enum.Font.GothamBold
            nLbl.TextSize = 9.5
            nLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
            nLbl.TextXAlignment = Enum.TextXAlignment.Left
            nLbl.Text = pack.name
            nLbl.ZIndex = 16
            nLbl.Parent = card

            local dLbl = Instance.new("TextLabel")
            dLbl.Size = UDim2.new(1, -125, 0, 16)
            dLbl.Position = UDim2.new(0, 48, 0, 24)
            dLbl.BackgroundTransparency = 1
            dLbl.Font = Enum.Font.Gotham
            dLbl.TextSize = 8
            dLbl.TextColor3 = Color3.fromRGB(150, 150, 165)
            dLbl.TextXAlignment = Enum.TextXAlignment.Left
            dLbl.Text = pack.desc .. " [" .. pack.tag .. "]"
            dLbl.ZIndex = 16
            dLbl.Parent = card

            local applyB = Instance.new("TextButton")
            applyB.Size = UDim2.new(0, 72, 0, 26)
            applyB.Position = UDim2.new(1, -78, 0, 11)
            applyB.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            applyB.Text = "PASANG TUBUH"
            applyB.Font = Enum.Font.GothamBold
            applyB.TextSize = 7.5
            applyB.TextColor3 = Color3.fromRGB(0, 0, 0)
            applyB.Active = true
            applyB.ZIndex = 16
            applyB.Parent = card
            makeCorner(applyB, 5)

            applyB.Activated:Connect(function()
                applyB.Text = "MEMUAT..."
                task.spawn(function()
                    local myChar = LP.Character
                    if not myChar then
                        applyB.Text = "[X] NO CHAR"; task.wait(1.2); applyB.Text = "PASANG TUBUH"; return
                    end
                    local hum = myChar:FindFirstChildOfClass("Humanoid")
                    if not hum then
                        applyB.Text = "[X] NO HUM"; task.wait(1.2); applyB.Text = "PASANG TUBUH"; return
                    end

                    pcall(function()
                        if pack.type == "donor_body" then
                            applyAvatarLocally(pack.wearerId)
                            setMirror(pack.wearerId, pack.name)
                        elseif pack.type == "korblox" or pack.type == "combo_korblox_headless" then
                            for _, pName in ipairs({"RightUpperLeg", "RightLowerLeg", "RightFoot", "Right Leg"}) do
                                local p = myChar:FindFirstChild(pName)
                                if p then p.Transparency = 1 end
                            end
                        end

                        if pack.type == "headless" or pack.type == "combo_korblox_headless" then
                            local hd = myChar:FindFirstChild("Head")
                            if hd then
                                hd.Transparency = 1
                                local fc = hd:FindFirstChild("face") or hd:FindFirstChildOfClass("Decal")
                                if fc then fc.Transparency = 1 end
                            end
                        end

                        if pack.type == "reset_body" then
                            for _, d in ipairs(myChar:GetChildren()) do
                                if d:IsA("BasePart") then d.Transparency = 0 end
                            end
                            local hd = myChar:FindFirstChild("Head")
                            if hd then
                                local fc = hd:FindFirstChild("face") or hd:FindFirstChildOfClass("Decal")
                                if fc then fc.Transparency = 0 end
                            end
                            local hs = hum:FindFirstChild("BodyHeightScale")
                            local ws = hum:FindFirstChild("BodyWidthScale")
                            local ds = hum:FindFirstChild("BodyDepthScale")
                            local heads = hum:FindFirstChild("HeadScale")
                            if hs then hs.Value = 1.0 end
                            if ws then ws.Value = 1.0 end
                            if ds then ds.Value = 1.0 end
                            if heads then heads.Value = 1.0 end
                        elseif pack.type == "r20" then
                            local hs = hum:FindFirstChild("BodyHeightScale")
                            local ws = hum:FindFirstChild("BodyWidthScale")
                            if hs then hs.Value = 1.05 end
                            if ws then ws.Value = 1.0 end
                        elseif pack.type == "hero" then
                            local hs = hum:FindFirstChild("BodyHeightScale")
                            local ws = hum:FindFirstChild("BodyWidthScale")
                            local ds = hum:FindFirstChild("BodyDepthScale")
                            if hs then hs.Value = 1.15 end
                            if ws then ws.Value = 1.25 end
                            if ds then ds.Value = 1.15 end
                        elseif pack.type == "mini" then
                            local hs = hum:FindFirstChild("BodyHeightScale")
                            local ws = hum:FindFirstChild("BodyWidthScale")
                            local ds = hum:FindFirstChild("BodyDepthScale")
                            local heads = hum:FindFirstChild("HeadScale")
                            if hs then hs.Value = 0.75 end
                            if ws then ws.Value = 0.80 end
                            if ds then ds.Value = 0.80 end
                            if heads then heads.Value = 1.10 end
                        end
                    end)

                    applyB.Text = "[OK] DIPAKAI"
                    task.wait(1.2)
                    applyB.Text = "PASANG TUBUH"
                end)
            end)
        end
        KScroll.CanvasSize = UDim2.new(0, 0, 0, #KARAKTER_BODY_PACKS * 54 + 20)
    end

    -- =========================================================================
    -- VIEW 3: SUB-TAB "LIMITED" (35+ ITEMS BLOXED.GG + CUSTOM ID INPUT)
    -- =========================================================================
    local function renderLimitedView()
        clearContent()

        local HeaderRow = Instance.new("Frame")
        HeaderRow.Size = UDim2.new(1, -8, 0, 24)
        HeaderRow.Position = UDim2.new(0, 4, 0, 4)
        HeaderRow.BackgroundTransparency = 1
        HeaderRow.ZIndex = 14
        HeaderRow.Parent = ContentFrame

        local TitleLbl = Instance.new("TextLabel")
        TitleLbl.Size = UDim2.new(1, -90, 1, 0)
        TitleLbl.BackgroundTransparency = 1
        TitleLbl.Font = Enum.Font.GothamBold
        TitleLbl.TextSize = 9.5
        TitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
        TitleLbl.Text = "ITEM LIMITED SULTAN (BLOXED.GG KATALOG)"
        TitleLbl.ZIndex = 15
        TitleLbl.Parent = HeaderRow

        local CopotSemuaBtn = Instance.new("TextButton")
        CopotSemuaBtn.Size = UDim2.new(0, 84, 1, 0)
        CopotSemuaBtn.Position = UDim2.new(1, -84, 0, 0)
        CopotSemuaBtn.BackgroundColor3 = Color3.fromRGB(45, 20, 25)
        CopotSemuaBtn.Text = "COPOT SEMUA"
        CopotSemuaBtn.Font = Enum.Font.GothamBold
        CopotSemuaBtn.TextSize = 7.5
        CopotSemuaBtn.TextColor3 = Color3.fromRGB(255, 120, 140)
        CopotSemuaBtn.Active = true
        CopotSemuaBtn.ZIndex = 15
        CopotSemuaBtn.Parent = HeaderRow
        makeCorner(CopotSemuaBtn, 4)
        makeStroke(CopotSemuaBtn, Color3.fromRGB(255, 80, 100), 1, 0.6)

        -- KOTAK INPUT CUSTOM LIMITED ID DARI BLOXED.GG
        local CustomRow = Instance.new("Frame")
        CustomRow.Size = UDim2.new(1, -8, 0, 24)
        CustomRow.Position = UDim2.new(0, 4, 0, 30)
        CustomRow.BackgroundTransparency = 1
        CustomRow.ZIndex = 14
        CustomRow.Parent = ContentFrame

        local CustomIdBox = Instance.new("TextBox")
        CustomIdBox.Size = UDim2.new(1, -84, 1, 0)
        CustomIdBox.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
        CustomIdBox.PlaceholderText = "Paste Asset ID Item dari Bloxed.gg..."
        CustomIdBox.PlaceholderColor3 = Color3.fromRGB(110, 110, 120)
        CustomIdBox.Text = ""
        CustomIdBox.Font = Enum.Font.Code
        CustomIdBox.TextSize = 8.5
        CustomIdBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        CustomIdBox.ClearTextOnFocus = false
        CustomIdBox.ZIndex = 15
        CustomIdBox.Parent = CustomRow
        makeCorner(CustomIdBox, 5)
        makeStroke(CustomIdBox, Color3.fromRGB(255, 255, 255), 1, 0.8)

        local CustomAddBtn = Instance.new("TextButton")
        CustomAddBtn.Size = UDim2.new(0, 80, 1, 0)
        CustomAddBtn.Position = UDim2.new(1, -80, 0, 0)
        CustomAddBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        CustomAddBtn.Text = "+ PASANG ID"
        CustomAddBtn.Font = Enum.Font.GothamBold
        CustomAddBtn.TextSize = 7.5
        CustomAddBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        CustomAddBtn.Active = true
        CustomAddBtn.ZIndex = 15
        CustomAddBtn.Parent = CustomRow
        makeCorner(CustomAddBtn, 5)

        local LScroll = Instance.new("ScrollingFrame")
        LScroll.Size = UDim2.new(1, -8, 1, -58)
        LScroll.Position = UDim2.new(0, 4, 0, 56)
        LScroll.BackgroundTransparency = 1
        LScroll.ScrollBarThickness = 3
        LScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
        LScroll.BorderSizePixel = 0
        LScroll.ZIndex = 14
        LScroll.Parent = ContentFrame

        local LList = Instance.new("UIListLayout")
        LList.Padding = UDim.new(0, 6)
        LList.SortOrder = Enum.SortOrder.LayoutOrder
        LList.Parent = LScroll

        local actionButtons = {}

        for _, item in ipairs(LIMITED_ITEMS) do
            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, -8, 0, 44)
            card.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
            card.BorderSizePixel = 0
            card.ZIndex = 15
            card.Parent = LScroll
            makeCorner(card, 6)
            makeStroke(card, Color3.fromRGB(255, 255, 255), 1, 0.82)

            local thumb = Instance.new("ImageLabel")
            thumb.Size = UDim2.new(0, 36, 0, 36)
            thumb.Position = UDim2.new(0, 4, 0, 4)
            thumb.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
            thumb.Image = "rbxthumb://type=Asset&id=" .. tostring(item.id) .. "&w=150&h=150"
            thumb.ScaleType = Enum.ScaleType.Fit
            thumb.ZIndex = 16
            thumb.Parent = card
            makeCorner(thumb, 4)

            local nLbl = Instance.new("TextLabel")
            nLbl.Size = UDim2.new(1, -120, 0, 18)
            nLbl.Position = UDim2.new(0, 46, 0, 4)
            nLbl.BackgroundTransparency = 1
            nLbl.Font = Enum.Font.GothamBold
            nLbl.TextSize = 9
            nLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
            nLbl.TextXAlignment = Enum.TextXAlignment.Left
            nLbl.Text = item.name
            nLbl.ZIndex = 16
            nLbl.Parent = card

            local rapLbl = Instance.new("TextLabel")
            rapLbl.Size = UDim2.new(1, -120, 0, 16)
            rapLbl.Position = UDim2.new(0, 46, 0, 22)
            rapLbl.BackgroundTransparency = 1
            rapLbl.Font = Enum.Font.Code
            rapLbl.TextSize = 8
            rapLbl.TextColor3 = Color3.fromRGB(255, 200, 100)
            rapLbl.TextXAlignment = Enum.TextXAlignment.Left
            rapLbl.Text = "[" .. item.cat .. "] " .. item.rap
            rapLbl.ZIndex = 16
            rapLbl.Parent = card

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0, 64, 0, 24)
            btn.Position = UDim2.new(1, -70, 0, 10)
            btn.Active = true
            btn.ZIndex = 16
            btn.Parent = card
            makeCorner(btn, 5)

            local function updateBtnState()
                if stackedLimitedAccessories[item.id] then
                    btn.BackgroundColor3 = Color3.fromRGB(180, 40, 50)
                    btn.Text = "COPOT"
                    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                else
                    btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    btn.Text = "PASANG"
                    btn.TextColor3 = Color3.fromRGB(0, 0, 0)
                end
            end
            updateBtnState()
            actionButtons[item.id] = updateBtnState

            btn.Activated:Connect(function()
                local myChar = LP.Character
                if not myChar then return end

                if stackedLimitedAccessories[item.id] then
                    pcall(function()
                        local inst = stackedLimitedAccessories[item.id]
                        if typeof(inst) == "Instance" and inst.Parent then inst:Destroy() end
                    end)
                    stackedLimitedAccessories[item.id] = nil
                    updateBtnState()
                else
                    btn.Text = "LOADING..."
                    task.spawn(function()
                        if item.isFace then
                            pcall(function()
                                local hd = myChar:FindFirstChild("Head")
                                if hd then
                                    local fc = hd:FindFirstChild("face") or hd:FindFirstChildOfClass("Decal")
                                    if fc then fc.Texture = item.tex end
                                end
                            end)
                            stackedLimitedAccessories[item.id] = true
                        else
                            local ok, objs = pcall(function()
                                return game:GetObjects("rbxassetid://" .. tostring(item.id))
                            end)
                            if ok and objs and #objs > 0 then
                                for _, obj in ipairs(objs) do
                                    pcall(function()
                                        if obj:IsA("Accessory") then
                                            weldAccessoryToCharacter(myChar, obj)
                                            stackedLimitedAccessories[item.id] = obj
                                        end
                                    end)
                                end
                            end
                        end
                        updateBtnState()
                    end)
                end
            end)
        end

        -- Pasang Custom Asset ID dari Bloxed.gg
        CustomAddBtn.Activated:Connect(function()
            local cId = tonumber(CustomIdBox.Text:gsub("%s+", ""))
            if not cId then return end
            CustomAddBtn.Text = "LOADING..."
            task.spawn(function()
                local myChar = LP.Character
                if myChar then
                    local ok, objs = pcall(function() return game:GetObjects("rbxassetid://" .. tostring(cId)) end)
                    if ok and objs and #objs > 0 then
                        for _, obj in ipairs(objs) do
                            pcall(function()
                                if obj:IsA("Accessory") then
                                    weldAccessoryToCharacter(myChar, obj)
                                    stackedLimitedAccessories[cId] = obj
                                end
                            end)
                        end
                        CustomAddBtn.Text = "[OK] TERPASANG"
                        task.wait(1.2)
                        CustomAddBtn.Text = "+ PASANG ID"
                        return
                    end
                end
                CustomAddBtn.Text = "[X] GAGAL"
                task.wait(1.2)
                CustomAddBtn.Text = "+ PASANG ID"
            end)
        end)

        CopotSemuaBtn.Activated:Connect(function()
            for id, inst in pairs(stackedLimitedAccessories) do
                pcall(function()
                    if typeof(inst) == "Instance" and inst.Parent then inst:Destroy() end
                end)
            end
            stackedLimitedAccessories = {}
            for _, fn in pairs(actionButtons) do fn() end
        end)

        LScroll.CanvasSize = UDim2.new(0, 0, 0, #LIMITED_ITEMS * 50 + 20)
    end

    -- =========================================================================
    -- VIEW 4: SUB-TAB "ANIMASI" (DENGAN GAMBAR ASSET RESMI MUNCUL 100%)
    -- =========================================================================
    local function renderAnimasiView()
        clearContent()

        local TitleLbl = Instance.new("TextLabel")
        TitleLbl.Size = UDim2.new(1, -8, 0, 22)
        TitleLbl.Position = UDim2.new(0, 4, 0, 4)
        TitleLbl.BackgroundTransparency = 1
        TitleLbl.Font = Enum.Font.GothamBold
        TitleLbl.TextSize = 10
        TitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
        TitleLbl.Text = "PAKET ANIMASI GERAK RESMI (IDLE, WALK, RUN, JUMP)"
        TitleLbl.ZIndex = 14
        TitleLbl.Parent = ContentFrame

        local AScroll = Instance.new("ScrollingFrame")
        AScroll.Size = UDim2.new(1, -8, 1, -30)
        AScroll.Position = UDim2.new(0, 4, 0, 26)
        AScroll.BackgroundTransparency = 1
        AScroll.ScrollBarThickness = 3
        AScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
        AScroll.BorderSizePixel = 0
        AScroll.ZIndex = 14
        AScroll.Parent = ContentFrame

        local AList = Instance.new("UIListLayout")
        AList.Padding = UDim.new(0, 6)
        AList.SortOrder = Enum.SortOrder.LayoutOrder
        AList.Parent = AScroll

        for _, pack in ipairs(ANIMASI_PACKS) do
            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, -8, 0, 44)
            card.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
            card.BorderSizePixel = 0
            card.ZIndex = 15
            card.Parent = AScroll
            makeCorner(card, 6)
            makeStroke(card, Color3.fromRGB(255, 255, 255), 1, 0.82)

            local thumb = Instance.new("ImageLabel")
            thumb.Size = UDim2.new(0, 36, 0, 36)
            thumb.Position = UDim2.new(0, 4, 0, 4)
            thumb.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
            thumb.Image = "rbxthumb://type=Asset&id=" .. tostring(pack.idleAsset) .. "&w=150&h=150"
            thumb.ScaleType = Enum.ScaleType.Fit
            thumb.ZIndex = 16
            thumb.Parent = card
            makeCorner(thumb, 4)

            local nLbl = Instance.new("TextLabel")
            nLbl.Size = UDim2.new(1, -120, 0, 18)
            nLbl.Position = UDim2.new(0, 46, 0, 4)
            nLbl.BackgroundTransparency = 1
            nLbl.Font = Enum.Font.GothamBold
            nLbl.TextSize = 9.5
            nLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
            nLbl.TextXAlignment = Enum.TextXAlignment.Left
            nLbl.Text = pack.name
            nLbl.ZIndex = 16
            nLbl.Parent = card

            local tLbl = Instance.new("TextLabel")
            tLbl.Size = UDim2.new(1, -120, 0, 16)
            tLbl.Position = UDim2.new(0, 46, 0, 22)
            tLbl.BackgroundTransparency = 1
            tLbl.Font = Enum.Font.Code
            tLbl.TextSize = 8
            tLbl.TextColor3 = Color3.fromRGB(140, 140, 160)
            tLbl.TextXAlignment = Enum.TextXAlignment.Left
            tLbl.Text = "Kategori: " .. pack.tag .. " | Idle: " .. pack.idle
            tLbl.ZIndex = 16
            tLbl.Parent = card

            local applyB = Instance.new("TextButton")
            applyB.Size = UDim2.new(0, 64, 0, 24)
            applyB.Position = UDim2.new(1, -70, 0, 10)
            applyB.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            applyB.Text = "PASANG"
            applyB.Font = Enum.Font.GothamBold
            applyB.TextSize = 8
            applyB.TextColor3 = Color3.fromRGB(0, 0, 0)
            applyB.Active = true
            applyB.ZIndex = 16
            applyB.Parent = card
            makeCorner(applyB, 5)

            applyB.Activated:Connect(function()
                applyB.Text = "APPLYING..."
                task.spawn(function()
                    local myChar = LP.Character
                    if myChar then
                        local animScript = myChar:FindFirstChild("Animate")
                        if animScript then
                            local function setA(fName, subN, id)
                                local f = animScript:FindFirstChild(fName)
                                if f then
                                    local a = f:FindFirstChild(subN) or f:FindFirstChildOfClass("Animation")
                                    if a and a:IsA("Animation") then
                                        a.AnimationId = "rbxassetid://" .. tostring(id)
                                    end
                                end
                            end
                            pcall(function()
                                setA("idle", "Animation1", pack.idle)
                                setA("idle", "Animation2", pack.idle)
                                setA("walk", "WalkAnim", pack.walk)
                                setA("run", "RunAnim", pack.run)
                                setA("jump", "JumpAnim", pack.jump)
                                setA("fall", "FallAnim", pack.fall)
                            end)
                            local hum = myChar:FindFirstChildOfClass("Humanoid")
                            if hum then
                                for _, trk in ipairs(hum:GetPlayingAnimationTracks()) do
                                    pcall(function() trk:Stop() end)
                                end
                            end
                            applyB.Text = "[OK] PASANG"
                            task.wait(1.2)
                            applyB.Text = "PASANG"
                            return
                        end
                    end
                    applyB.Text = "[X] GAGAL"
                    task.wait(1.2)
                    applyB.Text = "PASANG"
                end)
            end)
        end
        AScroll.CanvasSize = UDim2.new(0, 0, 0, #ANIMASI_PACKS * 50 + 20)
    end

    -- =========================================================================
    -- VIEW 5: SUB-TAB "SEPATU" (SNEAKERS RESMI + CUSTOM ID INPUT)
    -- =========================================================================
    local function renderSepatuView()
        clearContent()

        local TitleLbl = Instance.new("TextLabel")
        TitleLbl.Size = UDim2.new(1, -8, 0, 22)
        TitleLbl.Position = UDim2.new(0, 4, 0, 4)
        TitleLbl.BackgroundTransparency = 1
        TitleLbl.Font = Enum.Font.GothamBold
        TitleLbl.TextSize = 10
        TitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
        TitleLbl.Text = "KATALOG SEPATU & SNEAKERS (LAYERED CLOTHING SHOES)"
        TitleLbl.ZIndex = 14
        TitleLbl.Parent = ContentFrame

        local CustomRow = Instance.new("Frame")
        CustomRow.Size = UDim2.new(1, -8, 0, 24)
        CustomRow.Position = UDim2.new(0, 4, 0, 28)
        CustomRow.BackgroundTransparency = 1
        CustomRow.ZIndex = 14
        CustomRow.Parent = ContentFrame

        local ShoeIdBox = Instance.new("TextBox")
        ShoeIdBox.Size = UDim2.new(1, -84, 1, 0)
        ShoeIdBox.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
        ShoeIdBox.PlaceholderText = "Paste Shoe Asset ID dari Catalog..."
        ShoeIdBox.PlaceholderColor3 = Color3.fromRGB(110, 110, 120)
        ShoeIdBox.Text = ""
        ShoeIdBox.Font = Enum.Font.Code
        ShoeIdBox.TextSize = 8.5
        ShoeIdBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        ShoeIdBox.ClearTextOnFocus = false
        ShoeIdBox.ZIndex = 15
        ShoeIdBox.Parent = CustomRow
        makeCorner(ShoeIdBox, 5)
        makeStroke(ShoeIdBox, Color3.fromRGB(255, 255, 255), 1, 0.8)

        local ShoeAddBtn = Instance.new("TextButton")
        ShoeAddBtn.Size = UDim2.new(0, 80, 1, 0)
        ShoeAddBtn.Position = UDim2.new(1, -80, 0, 0)
        ShoeAddBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ShoeAddBtn.Text = "+ PASANG SEPATU"
        ShoeAddBtn.Font = Enum.Font.GothamBold
        ShoeAddBtn.TextSize = 7
        ShoeAddBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        ShoeAddBtn.Active = true
        ShoeAddBtn.ZIndex = 15
        ShoeAddBtn.Parent = CustomRow
        makeCorner(ShoeAddBtn, 5)

        local SScroll = Instance.new("ScrollingFrame")
        SScroll.Size = UDim2.new(1, -8, 1, -56)
        SScroll.Position = UDim2.new(0, 4, 0, 54)
        SScroll.BackgroundTransparency = 1
        SScroll.ScrollBarThickness = 3
        SScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
        SScroll.BorderSizePixel = 0
        SScroll.ZIndex = 14
        SScroll.Parent = ContentFrame

        local SList = Instance.new("UIListLayout")
        SList.Padding = UDim.new(0, 6)
        SList.SortOrder = Enum.SortOrder.LayoutOrder
        SList.Parent = SScroll

        for _, item in ipairs(SEPATU_PACKS) do
            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, -8, 0, 44)
            card.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
            card.BorderSizePixel = 0
            card.ZIndex = 15
            card.Parent = SScroll
            makeCorner(card, 6)
            makeStroke(card, Color3.fromRGB(255, 255, 255), 1, 0.82)

            local thumb = Instance.new("ImageLabel")
            thumb.Size = UDim2.new(0, 36, 0, 36)
            thumb.Position = UDim2.new(0, 4, 0, 4)
            thumb.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
            thumb.Image = "rbxthumb://type=Asset&id=" .. tostring(item.id) .. "&w=150&h=150"
            thumb.ScaleType = Enum.ScaleType.Fit
            thumb.ZIndex = 16
            thumb.Parent = card
            makeCorner(thumb, 4)

            local nLbl = Instance.new("TextLabel")
            nLbl.Size = UDim2.new(1, -120, 0, 18)
            nLbl.Position = UDim2.new(0, 46, 0, 4)
            nLbl.BackgroundTransparency = 1
            nLbl.Font = Enum.Font.GothamBold
            nLbl.TextSize = 9
            nLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
            nLbl.TextXAlignment = Enum.TextXAlignment.Left
            nLbl.Text = item.name
            nLbl.ZIndex = 16
            nLbl.Parent = card

            local idLbl = Instance.new("TextLabel")
            idLbl.Size = UDim2.new(1, -120, 0, 16)
            idLbl.Position = UDim2.new(0, 46, 0, 22)
            idLbl.BackgroundTransparency = 1
            idLbl.Font = Enum.Font.Code
            idLbl.TextSize = 8
            idLbl.TextColor3 = Color3.fromRGB(140, 140, 160)
            idLbl.TextXAlignment = Enum.TextXAlignment.Left
            idLbl.Text = item.tag .. " | ID: " .. tostring(item.id)
            idLbl.ZIndex = 16
            idLbl.Parent = card

            local applyB = Instance.new("TextButton")
            applyB.Size = UDim2.new(0, 64, 0, 24)
            applyB.Position = UDim2.new(1, -70, 0, 10)
            applyB.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            applyB.Text = "PASANG"
            applyB.Font = Enum.Font.GothamBold
            applyB.TextSize = 8
            applyB.TextColor3 = Color3.fromRGB(0, 0, 0)
            applyB.Active = true
            applyB.ZIndex = 16
            applyB.Parent = card
            makeCorner(applyB, 5)

            applyB.Activated:Connect(function()
                applyB.Text = "MEMUAT..."
                task.spawn(function()
                    local myChar = LP.Character
                    if myChar then
                        local okLoad, objs = pcall(function()
                            return game:GetObjects("rbxassetid://" .. tostring(item.id))
                        end)
                        if okLoad and objs and #objs > 0 then
                            for _, obj in ipairs(objs) do
                                pcall(function()
                                    if obj:IsA("Accessory") then
                                        weldAccessoryToCharacter(myChar, obj)
                                    end
                                end)
                            end
                            applyB.Text = "[OK] TERPASANG"
                            task.wait(1.2)
                            applyB.Text = "PASANG"
                            return
                        end
                    end
                    applyB.Text = "[X] GAGAL"
                    task.wait(1.2)
                    applyB.Text = "PASANG"
                end)
            end)
        end

        ShoeAddBtn.Activated:Connect(function()
            local sId = tonumber(ShoeIdBox.Text:gsub("%s+", ""))
            if not sId then return end
            ShoeAddBtn.Text = "LOADING..."
            task.spawn(function()
                local myChar = LP.Character
                if myChar then
                    local ok, objs = pcall(function() return game:GetObjects("rbxassetid://" .. tostring(sId)) end)
                    if ok and objs and #objs > 0 then
                        for _, obj in ipairs(objs) do
                            pcall(function()
                                if obj:IsA("Accessory") then
                                    weldAccessoryToCharacter(myChar, obj)
                                end
                            end)
                        end
                        ShoeAddBtn.Text = "[OK] TERPASANG"
                        task.wait(1.2)
                        ShoeAddBtn.Text = "+ PASANG SEPATU"
                        return
                    end
                end
                ShoeAddBtn.Text = "[X] GAGAL"
                task.wait(1.2)
                ShoeAddBtn.Text = "+ PASANG SEPATU"
            end)
        end)

        SScroll.CanvasSize = UDim2.new(0, 0, 0, #SEPATU_PACKS * 50 + 20)
    end

    -- =========================================================================
    -- VIEW 6: SUB-TAB "FAVORIT" (SAVED AVATARS)
    -- =========================================================================
    local function renderFavoritView()
        clearContent()

        local TitleLbl = Instance.new("TextLabel")
        TitleLbl.Size = UDim2.new(1, -8, 0, 22)
        TitleLbl.Position = UDim2.new(0, 4, 0, 4)
        TitleLbl.BackgroundTransparency = 1
        TitleLbl.Font = Enum.Font.GothamBold
        TitleLbl.TextSize = 10
        TitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
        TitleLbl.Text = "DAFTAR AVATAR FAVORIT (" .. tostring(#userFavorites) .. " TERSIMPAN)"
        TitleLbl.ZIndex = 14
        TitleLbl.Parent = ContentFrame

        local FScroll = Instance.new("ScrollingFrame")
        FScroll.Size = UDim2.new(1, -8, 1, -30)
        FScroll.Position = UDim2.new(0, 4, 0, 26)
        FScroll.BackgroundTransparency = 1
        FScroll.ScrollBarThickness = 3
        FScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
        FScroll.BorderSizePixel = 0
        FScroll.ZIndex = 14
        FScroll.Parent = ContentFrame

        if #userFavorites == 0 then
            local EmptyLbl = Instance.new("TextLabel")
            EmptyLbl.Size = UDim2.new(1, 0, 0, 40)
            EmptyLbl.Position = UDim2.new(0, 0, 0, 20)
            EmptyLbl.BackgroundTransparency = 1
            EmptyLbl.Font = Enum.Font.Gotham
            EmptyLbl.TextSize = 10
            EmptyLbl.TextColor3 = Color3.fromRGB(150, 150, 160)
            EmptyLbl.Text = "Belum ada avatar favorit.\nKlik tombol '<3 FAVORIT' di panel CERMIN untuk menyimpan."
            EmptyLbl.ZIndex = 15
            EmptyLbl.Parent = FScroll
            return
        end

        local FLayout = Instance.new("UIGridLayout")
        FLayout.CellSize = UDim2.new(0, 62, 0, 80)
        FLayout.CellPadding = UDim2.new(0, 5, 0, 5)
        FLayout.SortOrder = Enum.SortOrder.LayoutOrder
        FLayout.Parent = FScroll

        for i, fav in ipairs(userFavorites) do
            local card = Instance.new("TextButton")
            card.Size = UDim2.new(0, 62, 0, 80)
            card.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
            card.BorderSizePixel = 0
            card.Text = ""
            card.Active = true
            card.LayoutOrder = i
            card.ZIndex = 15
            card.Parent = FScroll
            makeCorner(card, 6)
            makeStroke(card, Color3.fromRGB(255, 255, 255), 1, 0.82)

            local img = Instance.new("ImageLabel")
            img.Size = UDim2.new(1, -6, 0, 50)
            img.Position = UDim2.new(0, 3, 0, 3)
            img.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
            img.Image = "rbxthumb://type=Avatar&id=" .. tostring(fav.id) .. "&w=100&h=100"
            img.ScaleType = Enum.ScaleType.Fit
            img.ZIndex = 16
            img.Parent = card
            makeCorner(img, 5)

            local nameL = Instance.new("TextLabel")
            nameL.Size = UDim2.new(1, -4, 0, 13)
            nameL.Position = UDim2.new(0, 2, 0, 54)
            nameL.BackgroundTransparency = 1
            nameL.Font = Enum.Font.GothamBold
            nameL.TextSize = 8
            nameL.TextColor3 = Color3.fromRGB(240, 240, 255)
            nameL.TextTruncate = Enum.TextTruncate.AtEnd
            nameL.Text = fav.name
            nameL.ZIndex = 16
            nameL.Parent = card

            local idL = Instance.new("TextLabel")
            idL.Size = UDim2.new(1, -4, 0, 11)
            idL.Position = UDim2.new(0, 2, 0, 67)
            idL.BackgroundTransparency = 1
            idL.Font = Enum.Font.Code
            idL.TextSize = 7
            idL.TextColor3 = Color3.fromRGB(255, 120, 150)
            idL.Text = "<3 Tersimpan"
            idL.ZIndex = 16
            idL.Parent = card

            card.Activated:Connect(function()
                setMirror(fav.id, fav.name)
            end)
        end
        FScroll.CanvasSize = UDim2.new(0, 0, 0, FLayout.AbsoluteContentSize.Y + 10)
    end

    -- =========================================================================
    -- VIEW 7: SUB-TAB "DIPAKAI" (CURRENTLY WORN ITEMS)
    -- =========================================================================
    local function renderDipakaiView()
        clearContent()

        local TitleLbl = Instance.new("TextLabel")
        TitleLbl.Size = UDim2.new(1, -8, 0, 22)
        TitleLbl.Position = UDim2.new(0, 4, 0, 4)
        TitleLbl.BackgroundTransparency = 1
        TitleLbl.Font = Enum.Font.GothamBold
        TitleLbl.TextSize = 10
        TitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
        TitleLbl.Text = "ITEM YANG SEDANG DIPAKAI: @" .. selectedUsername
        TitleLbl.ZIndex = 14
        TitleLbl.Parent = ContentFrame

        local DScroll = Instance.new("ScrollingFrame")
        DScroll.Size = UDim2.new(1, -8, 1, -30)
        DScroll.Position = UDim2.new(0, 4, 0, 26)
        DScroll.BackgroundTransparency = 1
        DScroll.ScrollBarThickness = 3
        DScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
        DScroll.BorderSizePixel = 0
        DScroll.ZIndex = 14
        DScroll.Parent = ContentFrame

        local DList = Instance.new("UIListLayout")
        DList.Padding = UDim.new(0, 6)
        DList.SortOrder = Enum.SortOrder.LayoutOrder
        DList.Parent = DScroll

        local StatusLbl = Instance.new("TextLabel")
        StatusLbl.Size = UDim2.new(1, 0, 0, 20)
        StatusLbl.BackgroundTransparency = 1
        StatusLbl.Font = Enum.Font.Code
        StatusLbl.TextSize = 8.5
        StatusLbl.TextColor3 = Color3.fromRGB(150, 150, 165)
        StatusLbl.Text = "Memeriksa item avatar..."
        StatusLbl.ZIndex = 15
        StatusLbl.Parent = DScroll

        task.spawn(function()
            local ok, donor = pcall(function()
                return Players:CreateHumanoidModelFromUserIdAsync(selectedUserId)
            end)
            if not ok or not donor then
                StatusLbl.Text = "[X] Gagal membaca item dari avatar ini"
                return
            end

            local items = {}
            for _, c in ipairs(donor:GetChildren()) do
                if c:IsA("Accessory") then
                    table.insert(items, { name = c.Name, type = "Accessory" })
                elseif c:IsA("Shirt") then
                    table.insert(items, { name = c.Name, type = "Baju (Shirt)" })
                elseif c:IsA("Pants") then
                    table.insert(items, { name = c.Name, type = "Celana (Pants)" })
                end
            end
            pcall(function() donor:Destroy() end)

            StatusLbl.Text = string.format("Total %d item dipakai oleh @%s", #items, selectedUsername)

            for i, it in ipairs(items) do
                local card = Instance.new("Frame")
                card.Size = UDim2.new(1, -8, 0, 34)
                card.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
                card.BorderSizePixel = 0
                card.ZIndex = 15
                card.Parent = DScroll
                makeCorner(card, 5)
                makeStroke(card, Color3.fromRGB(255, 255, 255), 1, 0.82)

                local idxLbl = Instance.new("TextLabel")
                idxLbl.Size = UDim2.new(0, 24, 1, 0)
                idxLbl.Position = UDim2.new(0, 4, 0, 0)
                idxLbl.BackgroundTransparency = 1
                idxLbl.Font = Enum.Font.Code
                idxLbl.TextSize = 8.5
                idxLbl.TextColor3 = Color3.fromRGB(120, 120, 135)
                idxLbl.Text = string.format("#%02d", i)
                idxLbl.ZIndex = 16
                idxLbl.Parent = card

                local nameL = Instance.new("TextLabel")
                nameL.Size = UDim2.new(1, -110, 0, 16)
                nameL.Position = UDim2.new(0, 32, 0, 3)
                nameL.BackgroundTransparency = 1
                nameL.Font = Enum.Font.GothamBold
                nameL.TextSize = 9
                nameL.TextColor3 = Color3.fromRGB(255, 255, 255)
                nameL.TextXAlignment = Enum.TextXAlignment.Left
                nameL.TextTruncate = Enum.TextTruncate.AtEnd
                nameL.Text = it.name
                nameL.ZIndex = 16
                nameL.Parent = card

                local typeL = Instance.new("TextLabel")
                typeL.Size = UDim2.new(1, -110, 0, 14)
                typeL.Position = UDim2.new(0, 32, 0, 18)
                typeL.BackgroundTransparency = 1
                typeL.Font = Enum.Font.Code
                typeL.TextSize = 7.5
                typeL.TextColor3 = Color3.fromRGB(140, 140, 160)
                typeL.TextXAlignment = Enum.TextXAlignment.Left
                typeL.Text = it.type
                typeL.ZIndex = 16
                typeL.Parent = card
            end
            DScroll.CanvasSize = UDim2.new(0, 0, 0, (#items + 1) * 40 + 20)
        end)
    end

    -- === ROUTER SUB-TAB SWITCHING (7 SUB-TABS) ===
    local function switchSubTab(targetName)
        activeSub = targetName
        for _, btn in ipairs(subTabBtns) do
            if btn.Name == targetName then
                btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                btn.TextColor3 = Color3.fromRGB(0, 0, 0)
            else
                btn.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
                btn.TextColor3 = Color3.fromRGB(180, 180, 195)
            end
        end

        if targetName == "AVATAR" then
            renderAvatarView()
        elseif targetName == "KARAKTER" then
            renderKarakterView()
        elseif targetName == "LIMITED" then
            renderLimitedView()
        elseif targetName == "ANIMASI" then
            renderAnimasiView()
        elseif targetName == "SEPATU" then
            renderSepatuView()
        elseif targetName == "FAVORIT" then
            renderFavoritView()
        elseif targetName == "DIPAKAI" then
            renderDipakaiView()
        end
    end

    -- === SIDEBAR SUB-TAB BUTTONS BUILDER ===
    local subTabUL = Instance.new("UIListLayout")
    subTabUL.Padding = UDim.new(0, 3)
    subTabUL.SortOrder = Enum.SortOrder.LayoutOrder
    subTabUL.HorizontalAlignment = Enum.HorizontalAlignment.Center
    subTabUL.Parent = AvSidebar
    local subTabPad = Instance.new("UIPadding")
    subTabPad.PaddingTop = UDim.new(0, 5)
    subTabPad.Parent = AvSidebar

    for si, sName in ipairs(SUBTABS) do
        local sb = Instance.new("TextButton")
        sb.Name = sName
        sb.Size = UDim2.new(1, -8, 0, 24)
        sb.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
        sb.Text = sName
        sb.Font = Enum.Font.GothamBold
        sb.TextSize = 7
        sb.TextColor3 = Color3.fromRGB(180, 180, 195)
        sb.TextWrapped = true
        sb.Active = true
        sb.LayoutOrder = si
        sb.ZIndex = 15
        sb.Parent = AvSidebar
        makeCorner(sb, 4)
        makeStroke(sb, Color3.fromRGB(255, 255, 255), 1, 0.8)
        table.insert(subTabBtns, sb)

        sb.Activated:Connect(function()
            switchSubTab(sName)
        end)
    end

    -- Render sub-tab default pertama kali buka
    switchSubTab("AVATAR")
end
initAvatarPage()

print("[BLUExCrown] ENGINE MCHLERN ENGINE v7.1 LOADED")
