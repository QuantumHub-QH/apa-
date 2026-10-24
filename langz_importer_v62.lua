-- ==========================================
-- 1. ANTI-CHEAT BYPASS & PHYSICS FIXER (Game ID: 10563114921)
-- ==========================================
if game.GameId == 10563114921 then 
    if not game:IsLoaded() then game.Loaded:Wait() end

    local environment = getgenv and getgenv() or _G
    if environment.OverflowNarrowBypass then return end
    
    local successGC, objects = pcall(function() return getgc(true) end)
    if successGC and type(objects) == "table" then
        local candidates = {}

        local function candidateSlot(value)
            local recursive = false
            local slot
            for _, item in next, value do
                if item == value then recursive = true end
                if type(item) == "number" and item >= 1 and item <= 3 and item % 1 == 0 then
                    if slot and slot ~= item then return nil end
                    slot = item
                end
            end
            if recursive and slot and rawget(value, slot) == nil then return slot end
        end

        for _, value in ipairs(objects) do
            if type(value) == "table" then
                local slot = candidateSlot(value)
                if slot then
                    local mt = getrawmetatable and getrawmetatable(value) or nil
                    if mt == nil then
                        candidates[value] = {Slot = slot, Identified = false, Shared = false}
                    elseif type(mt) == "table" and type(rawget(mt, "__newindex")) == "function" then
                        return
                    end
                end
            end
        end

        for _, callback in ipairs(objects) do
            if type(callback) == "function" and islclosure and islclosure(callback) then
                local ok, upvalues = pcall(debug.getupvalues, callback)
                if ok then
                    local referenced = {}
                    for _, value in pairs(upvalues) do
                        if type(value) == "table" and candidates[value] then referenced[value] = true end
                    end
                    if next(referenced) then
                        local source = debug.info(callback, "s")
                        local identified = false
                        if source == "ReplicatedFirst.LocalScript" then
                            local success, constants = pcall(debug.getconstants, callback)
                            if success then
                                for _, value in pairs(constants) do
                                    if value == "X-16" then identified = true break end
                                end
                            end
                        end
                        for value in pairs(referenced) do
                            local candidate = candidates[value]
                            if identified then candidate.Identified = true
                            else candidate.Shared = true end
                        end
                    end
                end
            end
        end

        local selected = {}
        for value, candidate in pairs(candidates) do
            if candidate.Identified and not candidate.Shared then selected[value] = candidate end
        end
        if next(selected) then
            local changes = {}
            local function restore()
                for value, installed in pairs(changes) do
                    if getrawmetatable and getrawmetatable(value) == installed then setmetatable(value, nil) end
                end
                table.clear(changes)
                environment.OverflowNarrowBypass = nil
            end
            local ok, err = pcall(function()
                for value, candidate in pairs(selected) do
                    if (getrawmetatable and getrawmetatable(value) ~= nil) or rawget(value, candidate.Slot) ~= nil then
                        error("Selected table changed during inspection")
                    end
                    local slot = candidate.Slot
                    local mt = {__newindex = function(self, key, newValue)
                        if key ~= slot then rawset(self, key, newValue) end
                    end}
                    setmetatable(value, mt)
                    changes[value] = mt
                end
            end)
            if not ok then
                restore()
            else
                environment.OverflowNarrowBypass = {Restore = restore}
            end
        end
    end
end

-- ==========================================
-- 2. PREMIUM DARK NEON GUI & AUTO FARM ENGINE
-- ==========================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

if CoreGui:FindFirstChild("StealAnEggUltimateGUI") then
    CoreGui.StealAnEggUltimateGUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "StealAnEggUltimateGUI"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false

-- Tombol Floating / Toggle Buka-Tutup GUI (Neon Blue Accent)
local ToggleOpenBtn = Instance.new("ImageButton")
ToggleOpenBtn.Name = "ToggleOpenBtn"
ToggleOpenBtn.Parent = ScreenGui
ToggleOpenBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
ToggleOpenBtn.Position = UDim2.new(0, 15, 0.4, 0)
ToggleOpenBtn.Size = UDim2.new(0, 45, 0, 45)
ToggleOpenBtn.Image = "rbxassetid://102337382069600"
ToggleOpenBtn.AutoButtonColor = false

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 10)
ToggleCorner.Parent = ToggleOpenBtn

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = Color3.fromRGB(0, 170, 255)
ToggleStroke.Thickness = 1.5
ToggleStroke.Parent = ToggleOpenBtn

-- Main Container (Dark Neon Interface)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
MainFrame.Position = UDim2.new(0.5, -160, 0.35, -180)
MainFrame.Size = UDim2.new(0, 320, 0, 380)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = true

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(0, 162, 255)
MainStroke.Thickness = 1.2
MainStroke.Parent = MainFrame

-- Animasi Buka/Tutup GUI
local isOpen = true
ToggleOpenBtn.MouseButton1Click:Connect(function()
    isOpen = not isOpen
    local targetPos = isOpen and UDim2.new(0.5, -160, 0.35, -180) or UDim2.new(0.5, -160, -0.6, 0)
    local targetAlpha = isOpen and 1 or 0
    
    TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = targetPos,
        BackgroundTransparency = 1 - targetAlpha
    }):Play()
end)

-- Header Bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Parent = MainFrame
TitleBar.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BorderSizePixel = 0

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = TitleBar

-- Memperbaiki bagian bawah TitleBar agar tidak melengkung tajam di dalam Frame
local TitleFix = Instance.new("Frame")
TitleFix.Parent = TitleBar
TitleFix.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
TitleFix.BorderSizePixel = 0
TitleFix.Position = UDim2.new(0, 0, 0.5, 0)
TitleFix.Size = UDim2.new(1, 0, 0.5, 0)

local TitleText = Instance.new("TextLabel")
TitleText.Parent = TitleBar
TitleText.BackgroundTransparency = 1
TitleText.Position = UDim2.new(0, 12, 0, 0)
TitleText.Size = UDim2.new(1, -90, 1, 0)
TitleText.Font = Enum.Font.GothamBold
TitleText.Text = "⚡ EGG RADAR & FARM"
TitleText.TextColor3 = Color3.fromRGB(0, 225, 255)
TitleText.TextSize = 13
TitleText.TextXAlignment = Enum.TextXAlignment.Left

-- Tombol Close / Minimize di Header
local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = TitleBar
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
CloseBtn.Position = UDim2.new(1, -32, 0.5, -12)
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 11

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Status Indicator / Counter Label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 12, 0, 45)
StatusLabel.Size = UDim2.new(1, -24, 0, 16)
StatusLabel.Font = Enum.Font.GothamMedium
StatusLabel.Text = "Status: Scanning... (0 Eggs Found)"
StatusLabel.TextColor3 = Color3.fromRGB(160, 170, 190)
StatusLabel.TextSize = 10
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Toggle Auto Farm Button (Neon Style)
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Parent = MainFrame
ToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 20, 25)
ToggleBtn.Position = UDim2.new(0, 12, 0, 68)
ToggleBtn.Size = UDim2.new(1, -24, 0, 34)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Text = "AUTO FARM: OFF"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 90, 90)
ToggleBtn.TextSize = 12
ToggleBtn.AutoButtonColor = false

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 8)
BtnCorner.Parent = ToggleBtn

local BtnStroke = Instance.new("UIStroke")
BtnStroke.Color = Color3.fromRGB(255, 70, 70)
BtnStroke.Thickness = 1.2
BtnStroke.Parent = ToggleBtn

-- Filter Rarity Header
local FilterTitle = Instance.new("TextLabel")
FilterTitle.Parent = MainFrame
FilterTitle.BackgroundTransparency = 1
FilterTitle.Position = UDim2.new(0, 12, 0, 108)
FilterTitle.Size = UDim2.new(1, -24, 0, 16)
FilterTitle.Font = Enum.Font.GothamBold
FilterTitle.Text = "RARITY FILTERS:"
FilterTitle.TextColor3 = Color3.fromRGB(120, 140, 170)
FilterTitle.TextSize = 10
FilterTitle.TextXAlignment = Enum.TextXAlignment.Left

-- Container Rarity Chips (Scrolling Horizontal / Vertical Compact)
local RarityContainer = Instance.new("ScrollingFrame")
RarityContainer.Name = "RarityContainer"
RarityContainer.Parent = MainFrame
RarityContainer.BackgroundColor3 = Color3.fromRGB(16, 16, 24)
RarityContainer.BorderSizePixel = 0
RarityContainer.Position = UDim2.new(0, 12, 0, 126)
RarityContainer.Size = UDim2.new(1, -24, 0, 62)
RarityContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
RarityContainer.ScrollBarThickness = 2

local RarityLayout = Instance.new("UIListLayout")
RarityLayout.Parent = RarityContainer
RarityLayout.FillDirection = Enum.FillDirection.Horizontal
RarityLayout.SortOrder = Enum.SortOrder.LayoutOrder
RarityLayout.Padding = UDim.new(0, 6)

-- Spawned Eggs Card Preview List
local EggsListFrame = Instance.new("ScrollingFrame")
EggsListFrame.Name = "EggsListFrame"
EggsListFrame.Parent = MainFrame
EggsListFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 24)
EggsListFrame.BorderSizePixel = 0
EggsListFrame.Position = UDim2.new(0, 12, 0, 196)
EggsListFrame.Size = UDim2.new(1, -24, 1, -206)
EggsListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
EggsListFrame.ScrollBarThickness = 3

local EggsLayout = Instance.new("UIListLayout")
EggsLayout.Parent = EggsListFrame
EggsLayout.SortOrder = Enum.SortOrder.LayoutOrder
EggsLayout.Padding = UDim.new(0, 5)

local EggsPadding = Instance.new("UIPadding")
EggsPadding.Parent = EggsListFrame
EggsPadding.PaddingTop = UDim.new(0, 2)
EggsPadding.PaddingBottom = UDim.new(0, 2)
EggsPadding.PaddingLeft = UDim.new(0, 2)
EggsPadding.PaddingRight = UDim.new(0, 2)

-- Konfigurasi Data & Rarity
local RarityWeights = {
    Transcendent = 8,
    Divine = 7,
    Prismatic = 6,
    Mythic = 5,
    Legendary = 4,
    Rare = 3,
    Uncommon = 2,
    Common = 1
}

local Config = {
    Enabled = false,
    Rarities = {
        Transcendent = true,
        Divine = true,
        Prismatic = true,
        Mythic = true,
        Legendary = true,
        Rare = true,
        Uncommon = false,
        Common = false
    }
}

local orderedRarities = {"Transcendent", "Divine", "Prismatic", "Mythic", "Legendary", "Rare", "Uncommon", "Common"}

-- Forward declaration fungsi Refresh & UI
local RefreshEggList

-- Pembuatan Tombol Filter Rarity (Chips)
for _, rarityName in ipairs(orderedRarities) do
    local state = Config.Rarities[rarityName]
    local rBtn = Instance.new("TextButton")
    rBtn.Name = "Filter_" .. rarityName
    rBtn.Size = UDim2.new(0, 72, 0, 26)
    rBtn.BackgroundColor3 = state and Color3.fromRGB(0, 120, 200) or Color3.fromRGB(24, 24, 36)
    rBtn.Font = Enum.Font.GothamBold
    rBtn.Text = rarityName
    rBtn.TextColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(140, 150, 170)
    rBtn.TextSize = 9
    rBtn.AutoButtonColor = false
    rBtn.Parent = RarityContainer

    local rCorner = Instance.new("UICorner")
    rCorner.CornerRadius = UDim.new(0, 6)
    rCorner.Parent = rBtn

    local rStroke = Instance.new("UIStroke")
    rStroke.Color = state and Color3.fromRGB(0, 200, 255) or Color3.fromRGB(40, 40, 60)
    rStroke.Thickness = 1
    rStroke.Parent = rBtn

    rBtn.MouseButton1Click:Connect(function()
        Config.Rarities[rarityName] = not Config.Rarities[rarityName]
        local newState = Config.Rarities[rarityName]
        
        rBtn.BackgroundColor3 = newState and Color3.fromRGB(0, 120, 200) or Color3.fromRGB(24, 24, 36)
        rBtn.TextColor3 = newState and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(140, 150, 170)
        rStroke.Color = newState and Color3.fromRGB(0, 200, 255) or Color3.fromRGB(40, 40, 60)
        
        if RefreshEggList then
            pcall(RefreshEggList)
        end
    end)
end
RarityContainer.CanvasSize = UDim2.new(0, RarityLayout.AbsoluteContentSize.X + 20, 0, 0)

-- Fungsi Helper Get Root Part Karakter
local function getRoot()
    local char = LocalPlayer.Character
    if char then return char:FindFirstChild("HumanoidRootPart") end
    return nil
end

-- Anti-Knock Hit / Physics Stabilizer Loop
RunService.Heartbeat:Connect(function()
    if Config.Enabled then
        local char = LocalPlayer.Character
        local humanoid = char and char:FindFirstChild("Humanoid")
        local rootPart = humanoid and humanoid.RootPart
        if humanoid and rootPart and humanoid:GetState() == Enum.HumanoidStateType.Physics then
            rootPart.AssemblyLinearVelocity = Vector3.zero
        end
    end
end)

-- Sistem Deteksi dan Refresh List Kartu Telur (Sesuai Spesifikasi Bagian 3 & 4)
local function ClearEggRows()
    for _, child in ipairs(EggsListFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
end

RefreshEggList = function()
    ClearEggRows()

    local folder = Workspace:FindFirstChild("PlacedEggRenders")

    if not folder then
        StatusLabel.Text = "Status: Folder PlacedEggRenders belum tersedia"
        EggsListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        return
    end

    local validEggsList = {}

    for _, eggModel in ipairs(folder:GetChildren()) do
        local rarity = eggModel:GetAttribute("Rarity")
        local imageId = eggModel:GetAttribute("ImageId")
        local rarityStr = (typeof(rarity) == "string") and rarity or "Common"

        if Config.Rarities[rarityStr] then
            local prompt = eggModel:FindFirstChildOfClass("ProximityPrompt") or eggModel:FindFirstDescendant("ProximityPrompt")
            local targetPart = eggModel:IsA("Model") and (eggModel.PrimaryPart or eggModel:FindFirstChildWhichIsA("BasePart")) or (eggModel:IsA("BasePart") and eggModel)

            table.insert(validEggsList, {
                Name = eggModel.Name,
                Rarity = rarityStr,
                ImageId = imageId ~= nil and tostring(imageId) or "",
                Object = eggModel,
                Prompt = prompt,
                Part = targetPart,
                Weight = RarityWeights[rarityStr] or 1
            })
        end
    end

    -- Urutkan berdasarkan Rarity Tertinggi
    table.sort(validEggsList, function(a, b)
        return a.Weight > b.Weight
    end)

    StatusLabel.Text = "Status: Active Radar (" .. #validEggsList .. " Eggs Found)"

    if #validEggsList == 0 then
        local emptyLabel = Instance.new("Frame")
        emptyLabel.Size = UDim2.new(1, -4, 0, 35)
        emptyLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
        emptyLabel.Parent = EggsListFrame

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = emptyLabel

        local txt = Instance.new("TextLabel")
        txt.Size = UDim2.new(1, 0, 1, 0)
        txt.BackgroundTransparency = 1
        txt.Font = Enum.Font.GothamMedium
        txt.Text = "Tidak ada telur terdeteksi filter"
        txt.TextColor3 = Color3.fromRGB(130, 140, 160)
        txt.TextSize = 10
        txt.Parent = emptyLabel
    else
        for _, data in ipairs(validEggsList) do
            local row = Instance.new("Frame")
            row.Name = "EggRow_" .. data.Name
            row.Size = UDim2.new(1, -4, 0, 38)
            row.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
            row.Parent = EggsListFrame

            local rCorner = Instance.new("UICorner")
            rCorner.CornerRadius = UDim.new(0, 6)
            rCorner.Parent = row

            local rStroke = Instance.new("UIStroke")
            rStroke.Color = Color3.fromRGB(35, 35, 55)
            rStroke.Thickness = 1
            rStroke.Parent = row

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Name = "EggName"
            nameLabel.Size = UDim2.new(1, -50, 1, 0)
            nameLabel.Position = UDim2.new(0, 8, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.Text = data.Name .. " [" .. data.Rarity .. "]"
            nameLabel.TextColor3 = Color3.fromRGB(235, 240, 255)
            nameLabel.TextSize = 10
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent = row

            local imageLabel = Instance.new("ImageLabel")
            imageLabel.Name = "EggImage"
            imageLabel.Size = UDim2.new(0, 28, 0, 28)
            imageLabel.Position = UDim2.new(1, -34, 0.5, -14)
            imageLabel.BackgroundTransparency = 1
            imageLabel.Image = (data.ImageId ~= "") and (tonumber(data.ImageId) and ("rbxassetid://" .. data.ImageId) or data.ImageId) or "rbxassetid://6031094678"
            imageLabel.Parent = row
        end
    end

    EggsListFrame.CanvasSize = UDim2.new(0, 0, 0, EggsLayout.AbsoluteContentSize.Y + 10)
end

-- Single Auto Refresh Background Task
local refreshRunning = true
task.spawn(function()
    while refreshRunning do
        local success, err = pcall(RefreshEggList)
        if not success then
            warn("[EggDetector] Refresh error:", err)
        end
        task.wait(2)
    end
end)

-- Tombol Auto Farm On/Off (Targeting PlacedEggRenders & ProximityPrompt "Steal")
ToggleBtn.MouseButton1Click:Connect(function()
    Config.Enabled = not Config.Enabled
    if Config.Enabled then
        ToggleBtn.Text = "AUTO FARM: ON"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 45, 30)
        ToggleBtn.TextColor3 = Color3.fromRGB(80, 255, 130)
        BtnStroke.Color = Color3.fromRGB(70, 255, 120)
        
        task.spawn(function()
            while Config.Enabled do
                pcall(function()
                    local rootPart = getRoot()
                    if not rootPart then return end

                    local validEggs = {}
                    local renderFolder = Workspace:FindFirstChild("PlacedEggRenders")
                    
                    if renderFolder then
                        for _, eggModel in ipairs(renderFolder:GetChildren()) do
                            local rarity = eggModel:GetAttribute("Rarity") or "Common"
                            if Config.Rarities[rarity] then
                                local prompt = eggModel:FindFirstChildOfClass("ProximityPrompt") or eggModel:FindFirstDescendant("ProximityPrompt")
                                local targetPart = eggModel:IsA("Model") and (eggModel.PrimaryPart or eggModel:FindFirstChildWhichIsA("BasePart")) or (eggModel:IsA("BasePart") and eggModel)
                                
                                if prompt and targetPart then
                                    table.insert(validEggs, {
                                        Prompt = prompt,
                                        Part = targetPart,
                                        Weight = RarityWeights[rarity] or 1
                                    })
                                end
                            end
                        end
                    end

                    -- Urutkan berdasarkan Rarity Tertinggi, lalu Jarak Terdekat
                    table.sort(validEggs, function(a, b)
                        if a.Weight ~= b.Weight then
                            return a.Weight > b.Weight
                        else
                            local distA = (rootPart.Position - a.Part.Position).Magnitude
                            local distB = (rootPart.Position - b.Part.Position).Magnitude
                            return distA < distB
                        end
                    end)

                    -- Eksekusi Teleport aman + Proteksi Anti-Knockback
                    for _, eggData in ipairs(validEggs) do
                        if not Config.Enabled then break end
                        if eggData.Part and eggData.Part.Parent then
                            rootPart.CFrame = eggData.Part.CFrame + Vector3.new(0, 3, 0)
                            rootPart.AssemblyLinearVelocity = Vector3.zero
                            task.wait(0.12)
                            
                            fireproximityprompt(eggData.Prompt)
                            task.wait(0.18)
                        end
                    end
                end)
                task.wait(0.6)
            end
        end)
    else
        ToggleBtn.Text = "AUTO FARM: OFF"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 20, 25)
        ToggleBtn.TextColor3 = Color3.fromRGB(255, 90, 90)
        BtnStroke.Color = Color3.fromRGB(255, 70, 70)
    end
end)
