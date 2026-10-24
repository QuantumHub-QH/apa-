-- ==========================================
-- 1. ANTI-CHEAT BYPASS & PHYSICS FIXER (Game ID: 10563114921)
-- ==========================================
if game.GameId == 10563114921 then 
    if not game:IsLoaded() then game.Loaded:Wait() end

    local environment = getgenv and getgenv() or _G
    if environment.OverflowNarrowBypass then return end
    local objects = getgc(true)
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
                local mt = getrawmetatable(value)
                if mt == nil then
                    candidates[value] = {Slot = slot, Identified = false, Shared = false}
                elseif type(mt) == "table" and type(rawget(mt, "__newindex")) == "function" then
                    return
                end
            end
        end
    end

    for _, callback in ipairs(objects) do
        if type(callback) == "function" and islclosure(callback) then
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
                if getrawmetatable(value) == installed then setmetatable(value, nil) end
            end
            table.clear(changes)
            environment.OverflowNarrowBypass = nil
        end
        local ok, err = pcall(function()
            for value, candidate in pairs(selected) do
                if getrawmetatable(value) ~= nil or rawget(value, candidate.Slot) ~= nil then
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
            return
        end
        environment.OverflowNarrowBypass = {Restore = restore}
    end
end

-- ==========================================
-- 2. ULTIMATE GUI & PLACED RENDER AUTO FARM
-- ==========================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

if CoreGui:FindFirstChild("StealAnEggUltimateGUI") then
    CoreGui.StealAnEggUltimateGUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "StealAnEggUltimateGUI"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Tombol Toggle Buka/Tutup GUI (ID: 102337382069600)
local ToggleOpenBtn = Instance.new("ImageButton")
ToggleOpenBtn.Name = "ToggleOpenBtn"
ToggleOpenBtn.Parent = ScreenGui
ToggleOpenBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
ToggleOpenBtn.Position = UDim2.new(0, 15, 0.4, 0)
ToggleOpenBtn.Size = UDim2.new(0, 42, 0, 42)
ToggleOpenBtn.Image = "rbxassetid://102337382069600"
local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 8)
ToggleCorner.Parent = ToggleOpenBtn

-- Main Frame GUI Utama
local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
MainFrame.Position = UDim2.new(0.5, -150, 0.35, -165)
MainFrame.Size = UDim2.new(0, 300, 0, 350)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = true

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

ToggleOpenBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

local TitleBar = Instance.new("TextLabel")
TitleBar.Parent = MainFrame
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
TitleBar.Size = UDim2.new(1, 0, 0, 35)
TitleBar.Font = Enum.Font.GothamBold
TitleBar.Text = "  🥚 PlacedEggRenders Radar & Farm"
TitleBar.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleBar.TextSize = 11
TitleBar.TextXAlignment = Enum.TextXAlignment.Left

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleBar

-- Toggle Auto Farm Button
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Parent = MainFrame
ToggleBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
ToggleBtn.Position = UDim2.new(0, 10, 0, 45)
ToggleBtn.Size = UDim2.new(1, -20, 0, 32)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Text = "Auto Farm: OFF"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 12

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 6)
BtnCorner.Parent = ToggleBtn

-- Rarity Filter Label
local FilterLabel = Instance.new("TextLabel")
FilterLabel.Parent = MainFrame
FilterLabel.BackgroundTransparency = 1
FilterLabel.Position = UDim2.new(0, 10, 0, 82)
FilterLabel.Size = UDim2.new(1, -20, 0, 18)
FilterLabel.Font = Enum.Font.GothamBold
FilterLabel.Text = "Filter Rarity (Placed Renders):"
FilterLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
FilterLabel.TextSize = 10
FilterLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Container Rarity Filter
local RarityContainer = Instance.new("ScrollingFrame")
RarityContainer.Parent = MainFrame
RarityContainer.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
RarityContainer.BorderSizePixel = 0
RarityContainer.Position = UDim2.new(0, 10, 0, 102)
RarityContainer.Size = UDim2.new(1, -20, 0, 75)
RarityContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
RarityContainer.ScrollBarThickness = 4

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = RarityContainer
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 3)

-- Spawned Eggs Card Preview List
local EggsListFrame = Instance.new("ScrollingFrame")
EggsListFrame.Parent = MainFrame
EggsListFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
EggsListFrame.BorderSizePixel = 0
EggsListFrame.Position = UDim2.new(0, 10, 0, 185)
EggsListFrame.Size = UDim2.new(1, -20, 1, -195)
EggsListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
EggsListFrame.ScrollBarThickness = 4

local UIListLayout2 = Instance.new("UIListLayout")
UIListLayout2.Parent = EggsListFrame
UIListLayout2.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout2.Padding = UDim.new(0, 4)

-- Bobot & Urutan Rarity Resmi Game (Tertinggi ke Terendah)[cite: 7]
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

-- Buat Tombol Rarity Sesuai Urutan
local orderedRarities = {"Transcendent", "Divine", "Prismatic", "Mythic", "Legendary", "Rare", "Uncommon", "Common"}
for _, rarityName in ipairs(orderedRarities) do
    local state = Config.Rarities[rarityName]
    local rBtn = Instance.new("TextButton")
    rBtn.Size = UDim2.new(1, -4, 0, 20)
    rBtn.BackgroundColor3 = state and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(40, 40, 55)
    rBtn.Font = Enum.Font.GothamBold
    rBtn.Text = rarityName .. " : " .. (state and "ON" or "OFF")
    rBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    rBtn.TextSize = 9
    rBtn.Parent = RarityContainer

    local rCorner = Instance.new("UICorner")
    rCorner.CornerRadius = UDim.new(0, 4)
    rCorner.Parent = rBtn

    rBtn.MouseButton1Click:Connect(function()
        Config.Rarities[rarityName] = not Config.Rarities[rarityName]
        local newState = Config.Rarities[rarityName]
        rBtn.Text = rarityName .. " : " .. (newState and "ON" or "OFF")
        rBtn.BackgroundColor3 = newState and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(40, 40, 55)
    end)
end
RarityContainer.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 10)

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

-- Fungsi Update List Card Preview dari Folder PlacedEggRenders
local function updateEggCards()
    for _, child in ipairs(EggsListFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local validEggsList = {}
    local renderFolder = Workspace:FindFirstChild("PlacedEggRenders")
    
    if renderFolder then
        for _, eggModel in ipairs(renderFolder:GetChildren()) do
            local rarity = eggModel:GetAttribute("Rarity") or "Common"
            local imageId = eggModel:GetAttribute("ImageId")

            if Config.Rarities[rarity] then
                table.insert(validEggsList, {
                    Name = eggModel.Name,
                    Rarity = rarity,
                    ImageId = imageId,
                    Weight = RarityWeights[rarity] or 1
                })
            end
        end
    end

    -- Sorting list GUI dari rarity paling tinggi ke terendah
    table.sort(validEggsList, function(a, b)
        return a.Weight > b.Weight
    end)

    for _, eggData in ipairs(validEggsList) do
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -4, 0, 28)
        card.BackgroundColor3 = Color3.fromRGB(25, 25, 36)
        card.Parent = EggsListFrame

        local cCorner = Instance.new("UICorner")
        cCorner.CornerRadius = UDim.new(0, 5)
        cCorner.Parent = card

        local icon = Instance.new("ImageLabel")
        icon.Size = UDim2.new(0, 20, 0, 20)
        icon.Position = UDim2.new(0, 4, 0.5, -10)
        icon.BackgroundTransparency = 1
        if eggData.ImageId then
            icon.Image = type(eggData.ImageId) == "number" and ("rbxassetid://" .. tostring(eggData.ImageId)) or eggData.ImageId
        else
            icon.Image = "rbxassetid://6031094678"
        end
        icon.Parent = card

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -30, 1, 0)
        label.Position = UDim2.new(0, 28, 0, 0)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamBold
        label.Text = eggData.Name .. " [" .. eggData.Rarity .. "]"
        label.TextColor3 = Color3.fromRGB(230, 230, 230)
        label.TextSize = 10
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = card
    end
    EggsListFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout2.AbsoluteContentSize.Y + 10)
end

-- Tombol Auto Farm On/Off (Targeting PlacedEggRenders & ProximityPrompt "Steal")
ToggleBtn.MouseButton1Click:Connect(function()
    Config.Enabled = not Config.Enabled
    if Config.Enabled then
        ToggleBtn.Text = "Auto Farm: ON"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        task.spawn(function()
            while Config.Enabled do
                pcall(function()
                    updateEggCards()
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
        ToggleBtn.Text = "Auto Farm: OFF"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
    end
end)
