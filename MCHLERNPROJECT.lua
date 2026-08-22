-- ===================================================
-- MAP COPIER V2 (UPGRADED) - MCHLERN PROJECT
-- Features: RBXL / RBXM Mode, Progress Bar, Anti-Kick Preloader
-- Supported Executor: Delta & Standard UNC Executors
-- ===================================================

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

-- 1. Metadata Game
local placeName = "Unknown Map"
pcall(function()
    local info = MarketplaceService:GetProductInfo(game.PlaceId)
    placeName = info.Name
end)

local cleanMapName = placeName:gsub('[%p%c%s]', "_")
local baseFileName = "MCHLERN_" .. cleanMapName

-- 2. GUI Creation (Black & White Elegant UI)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MchlernMapCopierV2"
ScreenGui.ResetOnSpawn = false

if gethui then
    ScreenGui.Parent = gethui()
elseif syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = CoreGui
else
    ScreenGui.Parent = CoreGui
end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 340, 0, 260)
MainFrame.Position = UDim2.new(0.5, -170, 0.4, -130)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(255, 255, 255)
UIStroke.Thickness = 1
UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke.Parent = MainFrame

-- Header Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundTransparency = 1
Title.Text = "MCHLERN PROJECT V2"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

-- Subtitle
local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(1, -20, 0, 15)
SubTitle.Position = UDim2.new(0, 10, 0, 30)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "Advanced Map Copier & Asset Extractor"
SubTitle.TextColor3 = Color3.fromRGB(150, 150, 150)
SubTitle.TextSize = 11
SubTitle.Font = Enum.Font.Gotham
SubTitle.Parent = MainFrame

-- Mode Selection Title
local ModeLabel = Instance.new("TextLabel")
ModeLabel.Size = UDim2.new(1, -20, 0, 20)
ModeLabel.Position = UDim2.new(0, 10, 0, 52)
ModeLabel.BackgroundTransparency = 1
ModeLabel.Text = "Select Save Mode:"
ModeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
ModeLabel.TextSize = 11
ModeLabel.Font = Enum.Font.GothamSemibold
ModeLabel.TextXAlignment = Enum.TextXAlignment.Left
ModeLabel.Parent = MainFrame

-- Mode Buttons
local selectedMode = "full" -- Default "full" (.rbxl) atau "workspace" (.rbxm)

local FullBtn = Instance.new("TextButton")
FullBtn.Size = UDim2.new(0, 150, 0, 30)
FullBtn.Position = UDim2.new(0, 15, 0, 75)
FullBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
FullBtn.Text = "Full Copy (.rbxl)"
FullBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
FullBtn.TextSize = 12
FullBtn.Font = Enum.Font.GothamBold
FullBtn.Parent = MainFrame

local FullCorner = Instance.new("UICorner")
FullCorner.CornerRadius = UDim.new(0, 5)
FullCorner.Parent = FullBtn

local WorkspaceBtn = Instance.new("TextButton")
WorkspaceBtn.Size = UDim2.new(0, 150, 0, 30)
WorkspaceBtn.Position = UDim2.new(0, 175, 0, 75)
WorkspaceBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
WorkspaceBtn.Text = "Workspace Only (.rbxm)"
WorkspaceBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
WorkspaceBtn.TextSize = 12
WorkspaceBtn.Font = Enum.Font.GothamBold
WorkspaceBtn.Parent = MainFrame

local WsCorner = Instance.new("UICorner")
WsCorner.CornerRadius = UDim.new(0, 5)
WsCorner.Parent = WorkspaceBtn

-- Update Selection Visual
local function updateModeUI()
    if selectedMode == "full" then
        FullBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        FullBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        WorkspaceBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        WorkspaceBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    else
        WorkspaceBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        WorkspaceBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        FullBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        FullBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
end

FullBtn.MouseButton1Click:Connect(function()
    selectedMode = "full"
    updateModeUI()
end)

WorkspaceBtn.MouseButton1Click:Connect(function()
    selectedMode = "workspace"
    updateModeUI()
end)

-- Status Label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 25)
StatusLabel.Position = UDim2.new(0, 10, 0, 112)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Status: Ready"
StatusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
StatusLabel.TextSize = 11
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Parent = MainFrame

-- Progress Bar Background
local ProgressBarBg = Instance.new("Frame")
ProgressBarBg.Size = UDim2.new(1, -30, 0, 8)
ProgressBarBg.Position = UDim2.new(0, 15, 0, 140)
ProgressBarBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ProgressBarBg.BorderSizePixel = 0
ProgressBarBg.Parent = MainFrame

local ProgressCorner = Instance.new("UICorner")
ProgressCorner.CornerRadius = UDim.new(0, 4)
ProgressCorner.Parent = ProgressBarBg

-- Progress Bar Fill
local ProgressBarFill = Instance.new("Frame")
ProgressBarFill.Size = UDim2.new(0, 0, 1, 0)
ProgressBarFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ProgressBarFill.BorderSizePixel = 0
ProgressBarFill.Parent = ProgressBarBg

local FillCorner = Instance.new("UICorner")
FillCorner.CornerRadius = UDim.new(0, 4)
FillCorner.Parent = ProgressBarFill

-- Start Button
local StartBtn = Instance.new("TextButton")
StartBtn.Size = UDim2.new(1, -30, 0, 38)
StartBtn.Position = UDim2.new(0, 15, 0, 160)
StartBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
StartBtn.Text = "START COPY"
StartBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
StartBtn.TextSize = 13
StartBtn.Font = Enum.Font.GothamBold
StartBtn.Parent = MainFrame

local StartCorner = Instance.new("UICorner")
StartCorner.CornerRadius = UDim.new(0, 6)
StartCorner.Parent = StartBtn

-- Footer
local CreditText = Instance.new("TextLabel")
CreditText.Size = UDim2.new(1, 0, 0, 20)
CreditText.Position = UDim2.new(0, 0, 1, -22)
CreditText.BackgroundTransparency = 1
CreditText.Text = "COPY BY MCHLERN PROJECT"
CreditText.TextColor3 = Color3.fromRGB(90, 90, 90)
CreditText.TextSize = 10
CreditText.Font = Enum.Font.Gotham
CreditText.Parent = MainFrame

-- 3. Helpers & Core Logic

local function setProgress(percent, statusText)
    percent = math.clamp(percent, 0, 1)
    TweenService:Create(ProgressBarFill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(percent, 0, 1, 0)
    }):Play()
    if statusText then
        StatusLabel.Text = "Status: " .. statusText .. " (" .. math.floor(percent * 100) .. "%)"
    end
end

-- Safely preload StreamingEnabled maps without network kick
local function safePreloadMap()
    if not Workspace.StreamingEnabled then
        setProgress(0.3, "Preloading map...")
        task.wait(0.5)
        return
    end

    setProgress(0.1, "Bypassing Streaming (Grid Preload)...")
    
    -- Scan map in grid pattern rather than every single part to avoid kick
    local boundingBox = Workspace:GetModelBoundingBox()
    local boundsSize = boundingBox and boundingBox.Size or Vector3.new(2000, 500, 2000)
    local minX, maxX = -boundsSize.X/2, boundsSize.X/2
    local minZ, maxZ = -boundsSize.Z/2, boundsSize.Z/2
    
    local step = 300 -- Jump 300 studs at a time
    local totalSteps = math.ceil((maxX - minX) / step) * math.ceil((maxZ - minZ) / step)
    local currentStep = 0

    for x = minX, maxX, step do
        for z = minZ, maxZ, step do
            currentStep = currentStep + 1
            local targetPos = Vector3.new(x, 50, z)
            
            pcall(function()
                Workspace:RequestInstanceAroundAsync(targetPos)
            end)
            
            local progress = 0.1 + (currentStep / totalSteps) * 0.3
            setProgress(progress, "Preloading map regions...")
            task.wait(0.05) -- Safe yield to avoid high CPU usage / crash
        end
    end
end

-- Inject Credits Function
local function injectCredits()
    setProgress(0.45, "Injecting credits into scripts...")
    local count = 0
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
            pcall(function()
                local originalSource = obj.Source or ""
                if not originalSource:find("COPY BY MCHLERN PROJECT") then
                    obj.Source = "-- COPY BY MCHLERN PROJECT\n\n" .. originalSource
                end
            end)
            count = count + 1
            if count % 50 == 0 then
                task.wait() -- Prevent lag spike
            end
        end
    end
end

-- Execute Save
local function startCopyProcess()
    StartBtn.Active = false
    StartBtn.AutoButtonColor = false
    FullBtn.Active = false
    WorkspaceBtn.Active = false
    StartBtn.Text = "PROCESSING..."

    task.spawn(function()
        -- Step 1: Preload Streaming
        safePreloadMap()
        task.wait(0.2)

        -- Step 2: Inject Credits
        injectCredits()
        task.wait(0.2)

        -- Step 3: Configure Save Params
        setProgress(0.6, "Preparing Save Engine...")
        
        local finalFileName = baseFileName
        if selectedMode == "workspace" then
            finalFileName = finalFileName .. "_Workspace.rbxm"
        else
            finalFileName = finalFileName .. "_Full.rbxl"
        end

        local Params = {
            RepoURL = "https://raw.githubusercontent.com/luau/SynSaveInstance/main/",
            FilePath = finalFileName,
            Mode = selectedMode, -- "full" atau "workspace"
            IsolateLocalPlayer = false,
            RemovePlayers = true,
            Decompile = false, -- Dynamic Decompile diset false agar RAM stabil dan TIDAK KENA KICK
            DecompileTimeout = 5,
            SaveUnloadedAssets = true,
            NilInstances = true
        }

        if selectedMode == "workspace" then
            Params.Object = Workspace
        end

        setProgress(0.75, "Saving file to workspace folder...")
        
        local success, err = pcall(function()
            local saveinstance = loadstring(game:HttpGet(Params.RepoURL .. "saveinstance.luau"))()
            saveinstance(Params)
        end)

        if success then
            setProgress(1.0, "SUCCESS! Saved as " .. (selectedMode == "workspace" and ".rbxm" or ".rbxl"))
            StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        else
            -- Fallback Method
            local fallbackSuccess = pcall(function()
                if saveinstance then
                    saveinstance({
                        FileName = finalFileName,
                        Object = (selectedMode == "workspace" and Workspace or nil)
                    })
                end
            end)
            
            if fallbackSuccess then
                setProgress(1.0, "SUCCESS (Fallback)! Saved file.")
                StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            else
                setProgress(0, "FAILED: " .. tostring(err))
                StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            end
        end

        task.wait(4)
        
        -- Reset UI Status
        StartBtn.Text = "START COPY"
        StartBtn.Active = true
        StartBtn.AutoButtonColor = true
        FullBtn.Active = true
        WorkspaceBtn.Active = true
        StatusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
        setProgress(0, "Ready")
    end)
end

-- Button Trigger
StartBtn.MouseButton1Click:Connect(function()
    if StartBtn.Active then
        startCopyProcess()
    end
end)