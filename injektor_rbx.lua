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

local LP = Players.LocalPlayer
local ParentGui = (gethui and gethui()) or CoreGui or LP:WaitForChild("PlayerGui")

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
if ParentGui:FindFirstChild("BLUExCrownV5") then
    ParentGui.BLUExCrownV5:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BLUExCrownV5"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 9999
ScreenGui.IgnoreGuiInset = true -- 100% TRUE FULLSCREEN EDGE-TO-EDGE
ScreenGui.Parent = ParentGui

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
local PageText3D   = Instance.new("Frame")
local PageReplacer = Instance.new("Frame")

for _, pg in ipairs({PageSplash, PageToolbox, PageRBXM, PageText3D, PageReplacer}) do
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
    PageText3D.Visible   = false
    PageReplacer.Visible = false
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
StatsLbl.Text = "UserID: "..tostring(LP.UserId).."\nBLUExCrown ENGINE\nv5.6 — Perfect Edition"
StatsLbl.Font = Enum.Font.Gotham
StatsLbl.TextSize = 9
StatsLbl.TextColor3 = Color3.fromRGB(130, 130, 140)
StatsLbl.TextXAlignment = Enum.TextXAlignment.Center
StatsLbl.TextWrapped = true
StatsLbl.ZIndex = 14
StatsLbl.Parent = ProfileCard

-- KANAN: Menu Cards
local MenuArea = Instance.new("Frame")
MenuArea.Size = UDim2.new(1, -183, 1, 0)
MenuArea.Position = UDim2.new(0, 183, 0, 0)
MenuArea.BackgroundTransparency = 1
MenuArea.ZIndex = 13
MenuArea.Parent = PageSplash

local MenuTitle = Instance.new("TextLabel")
MenuTitle.Size = UDim2.new(1, 0, 0, 24)
MenuTitle.BackgroundTransparency = 1
MenuTitle.Text = "PILIH MENU"
MenuTitle.Font = Enum.Font.GothamBold
MenuTitle.TextSize = 10
MenuTitle.TextColor3 = Color3.fromRGB(180, 180, 190)
MenuTitle.TextXAlignment = Enum.TextXAlignment.Left
MenuTitle.ZIndex = 14
MenuTitle.Parent = MenuArea

-- MENU CARD DENGAN TRANSPARENT FULL HITBOX (100% RESPONSIF)
local function makeMenuCard(parent, posY, icon, title, subtitle, onClick)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 72)
    card.Position = UDim2.new(0, 0, 0, posY)
    card.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    card.ZIndex = 14
    card.Parent = parent
    makeCorner(card, 8)
    makeStroke(card, Color3.fromRGB(255,255,255), 1, 0.78)

    local iconLbl = Instance.new("TextLabel")
    iconLbl.Size = UDim2.new(0, 44, 0, 44)
    iconLbl.Position = UDim2.new(0, 14, 0.5, -22)
    iconLbl.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
    iconLbl.Text = icon
    iconLbl.Font = Enum.Font.GothamBold
    iconLbl.TextSize = 18
    iconLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    iconLbl.ZIndex = 15
    iconLbl.Parent = card
    makeCorner(iconLbl, 8)

    local titleL = Instance.new("TextLabel")
    titleL.Size = UDim2.new(1, -80, 0, 20)
    titleL.Position = UDim2.new(0, 68, 0, 16)
    titleL.BackgroundTransparency = 1
    titleL.Text = title
    titleL.Font = Enum.Font.GothamBold
    titleL.TextSize = 13
    titleL.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleL.TextXAlignment = Enum.TextXAlignment.Left
    titleL.ZIndex = 15
    titleL.Parent = card

    local subL = Instance.new("TextLabel")
    subL.Size = UDim2.new(1, -80, 0, 16)
    subL.Position = UDim2.new(0, 68, 0, 37)
    subL.BackgroundTransparency = 1
    subL.Text = subtitle
    subL.Font = Enum.Font.Gotham
    subL.TextSize = 9
    subL.TextColor3 = Color3.fromRGB(150, 150, 160)
    subL.TextXAlignment = Enum.TextXAlignment.Left
    subL.ZIndex = 15
    subL.Parent = card

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 20, 0, 20)
    arrow.Position = UDim2.new(1, -28, 0.5, -10)
    arrow.BackgroundTransparency = 1
    arrow.Text = ">"
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 18
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

makeMenuCard(MenuArea, 20,  "[T]", "TOOLBOX ASET",     "Cari & insert model dari Creator Store", function()
    showPage(PageToolbox)
end)

makeMenuCard(MenuArea, 96,  "[R]", "INSERT RBXM FILE", "Scan & insert file .rbxm dengan Source Script", function()
    showPage(PageRBXM)
end)

makeMenuCard(MenuArea, 172, "[3D]", "GENE TEXT 3D", "Buat teks 3D (3D extruded parts) kustom langsung di map", function()
    showPage(PageText3D)
end)

makeMenuCard(MenuArea, 248, "[⟲]", "REPLACER TOOLS", "Ganti banyak objek target di map dengan 1 model/part pilihan", function()
    showPage(PageReplacer)
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
RbxmSearchBox.PlaceholderText = "🔍 Cari nama file .rbxm di sini..."
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
-- PAGE 4: 3D TEXT GENERATOR (GENE TEXT 3D)
-- Fitur pembuat teks 3D kustom langsung di map (Extruded Parts)
-- Layout Split: Kiri Realtime Viewport Preview, Kanan Kontrol & Warna Kotak-Kotak
-- =====================================================

-- ── 5x7 BITMAP FONT MATRIX ───────────────────────────
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

-- ── UI PAGE TEXT 3D BUILDER (SPLIT VIEW) ─────────────
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
PreviewTitle.TextXAlignment = Enum.TextXAlignment.Left; PreviewTitle.Text = "● REALTIME 3D PREVIEW"
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
ReplacerTitleLbl.TextXAlignment = Enum.TextXAlignment.Left; ReplacerTitleLbl.Text = "[⟲] OBJECT & MODEL REPLACER TOOLS"
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
ScanTargetBtn.Text = "🔍 SCAN TARGET"
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
PickSelBtn.Text = "📌 PILIH TARGET"
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
    btn.Text = (rep_options[optKey] and "[✓] " or "[ ] ") .. text
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 8.5; btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.ZIndex = 15; btn.Parent = parent; makeCorner(btn, 4)

    btn.MouseButton1Click:Connect(function()
        rep_options[optKey] = not rep_options[optKey]
        btn.BackgroundColor3 = rep_options[optKey] and Color3.fromRGB(0, 160, 100) or Color3.fromRGB(40, 40, 50)
        btn.Text = (rep_options[optKey] and "[✓] " or "[ ] ") .. text
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
ExecReplaceBtn.Text = "[⟲] EKSEKUSI REPLACE SEMUA TARGET"
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
                ExecReplaceBtn.Text = "[⟲] EKSEKUSI REPLACE SEMUA TARGET"
            end
        end)
    end)
end)

print("[BLUExCrown] ENGINE MCHLERN ENGINE v7.1 LOADED")
