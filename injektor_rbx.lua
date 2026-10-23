-- =======================================================
-- BLUExCrown ENGINE v3.5 - REAL INSERT ENGINE (STUDIO LITE)
-- Smart RemoteEvent Hunter + Studio Lite Native UI Trigger
-- Toggle Asset ID: 102337382069600
-- =======================================================

local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local ParentGui = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

local httpRequest = request or http_request or (syn and syn.request) or (http and http.request)
local copyClipboard = setclipboard or toclipboard or (Clipboard and Clipboard.set)

if not httpRequest then
    warn("Executor tidak mendukung HTTP request!")
    return
end

-- Bersihkan instance lama jika ada
if ParentGui:FindFirstChild("BLUExCrownEngine") then
    ParentGui.BLUExCrownEngine:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BLUExCrownEngine"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = ParentGui

-- 1. FLOATING TOGGLE BUTTON (Custom Asset ID: 102337382069600)
local ToggleBtn = Instance.new("ImageButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Size = UDim2.new(0, 44, 0, 44)
ToggleBtn.Position = UDim2.new(0.02, 0, 0.45, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
ToggleBtn.Image = "rbxassetid://102337382069600"
ToggleBtn.ScaleType = Enum.ScaleType.Fit
ToggleBtn.Parent = ScreenGui

Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 8)
local ToggleStroke = Instance.new("UIStroke", ToggleBtn)
ToggleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
ToggleStroke.Color = Color3.fromRGB(255, 255, 255)
ToggleStroke.Thickness = 1.4

-- 2. MAIN WINDOW FRAME (620 x 335)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.fromScale(0.5, 0.5)
MainFrame.Size = UDim2.new(0, 620, 0, 335)
MainFrame.BackgroundColor3 = Color3.fromRGB(13, 13, 16)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MainStroke.Color = Color3.fromRGB(255, 255, 255)
MainStroke.Thickness = 1.4

-- Top Header dengan UICorner Mandiri
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, -12, 0, 32)
TopBar.Position = UDim2.new(0, 6, 0, 6)
TopBar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 8)

local TopBarStroke = Instance.new("UIStroke", TopBar)
TopBarStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
TopBarStroke.Color = Color3.fromRGB(255, 255, 255)
TopBarStroke.Thickness = 1
TopBarStroke.Transparency = 0.75

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "BLUExCrown ENGINE v3.5"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 11
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

-- Tombol Close X
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -28, 0, 4)
CloseBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 11
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Parent = TopBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

local CloseStroke = Instance.new("UIStroke", CloseBtn)
CloseStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
CloseStroke.Color = Color3.fromRGB(255, 255, 255)
CloseStroke.Thickness = 1
CloseStroke.Transparency = 0.6

local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -12, 1, -48)
ContentContainer.Position = UDim2.new(0, 6, 0, 42)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = MainFrame

-- ========================================================
-- ADVANCED STUDIO LITE INSERT LOGIC
-- ========================================================
local function executeSmartInsert(assetId)
    local numId = tonumber(assetId)
    if not numId or numId <= 0 then 
        return false, "ID tidak valid" 
    end

    if copyClipboard then
        copyClipboard(tostring(numId))
    end

    local isInserted = false
    local resultMethod = ""

    -- 1. Deteksi & Trigger Otomatis UI Bawaan Studio Lite di PlayerGui
    pcall(function()
        for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
            if gui:IsA("TextBox") and not gui:IsDescendantOf(ScreenGui) then
                local gName = gui.Name:lower()
                local gHolder = gui.PlaceholderText:lower()
                if string.find(gName, "asset") or string.find(gName, "id") or string.find(gName, "toolbox") or string.find(gHolder, "id") or string.find(gHolder, "asset") or string.find(gHolder, "url") then
                    gui.Text = tostring(numId)
                    
                    -- Cari tombol Get / Insert terdekat di dalam parent frame
                    local container = gui.Parent
                    if container then
                        for _, btn in ipairs(container:GetDescendants()) do
                            if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn ~= gui then
                                local bText = (btn:IsA("TextButton") and btn.Text:lower()) or ""
                                local bName = btn.Name:lower()
                                if string.find(bText, "get") or string.find(bText, "insert") or string.find(bName, "get") or string.find(bName, "insert") or string.find(bName, "load") then
                                    if firesignal then
                                        firesignal(btn.MouseButton1Click)
                                        firesignal(btn.Activated)
                                    elseif getconnections then
                                        for _, c in ipairs(getconnections(btn.MouseButton1Click)) do c:Fire() end
                                        for _, c in ipairs(getconnections(btn.Activated)) do c:Fire() end
                                    end
                                    isInserted = true
                                    resultMethod = "Native UI Triggered"
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    -- 2. Scan & Fire RemoteEvent Resmi di ReplicatedStorage / Game
    if not isInserted then
        pcall(function()
            for _, rem in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
                if rem:IsA("RemoteEvent") or rem:IsA("RemoteFunction") then
                    local rName = rem.Name:lower()
                    if string.find(rName, "insert") or string.find(rName, "loadasset") or string.find(rName, "spawn") or string.find(rName, "toolbox") or string.find(rName, "asset") then
                        if rem:IsA("RemoteEvent") then
                            rem:FireServer(numId)
                            rem:FireServer("Insert", numId)
                            rem:FireServer({ AssetId = numId, Id = numId })
                        else
                            rem:InvokeServer(numId)
                            rem:InvokeServer("Insert", numId)
                        end
                        isInserted = true
                        resultMethod = "Remote: " .. rem.Name
                    end
                end
            end
        end)
    end

    -- 3. Executor Local Spawn (Bypass GetObjects)
    pcall(function()
        local objects = game:GetObjects("rbxassetid://" .. tostring(numId))
        if objects and #objects > 0 then
            for _, item in ipairs(objects) do
                item.Parent = workspace
                if item:IsA("Model") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    item:MoveTo(LocalPlayer.Character.HumanoidRootPart.Position + LocalPlayer.Character.HumanoidRootPart.CFrame.LookVector * 7)
                end
            end
            if not isInserted then
                isInserted = true
                resultMethod = "GetObjects Spawn"
            end
        end
    end)

    return isInserted, (resultMethod ~= "" and resultMethod or "ID Tersalin ke Clipboard")
end

-- ==========================================
-- SISI KIRI (WIDTH: 235px) - SEARCH & DETAIL
-- ==========================================
local LeftPanel = Instance.new("Frame")
LeftPanel.Size = UDim2.new(0, 235, 1, 0)
LeftPanel.BackgroundTransparency = 1
LeftPanel.Parent = ContentContainer

-- Box 1: Search & Direct Insert
local SearchSection = Instance.new("Frame")
SearchSection.Size = UDim2.new(1, 0, 0, 122)
SearchSection.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
SearchSection.Parent = LeftPanel
Instance.new("UICorner", SearchSection).CornerRadius = UDim.new(0, 8)
local SS_Stroke = Instance.new("UIStroke", SearchSection)
SS_Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
SS_Stroke.Color = Color3.fromRGB(255, 255, 255)
SS_Stroke.Thickness = 1
SS_Stroke.Transparency = 0.75

local IdBox = Instance.new("TextBox")
IdBox.Size = UDim2.new(1, -72, 0, 25)
IdBox.Position = UDim2.new(0, 6, 0, 8)
IdBox.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
IdBox.PlaceholderText = "Masukkan Asset ID..."
IdBox.PlaceholderColor3 = Color3.fromRGB(110, 110, 120)
IdBox.Text = ""
IdBox.Font = Enum.Font.Gotham
IdBox.TextSize = 10
IdBox.TextColor3 = Color3.fromRGB(255, 255, 255)
IdBox.ClearTextOnFocus = false
IdBox.Parent = SearchSection
Instance.new("UICorner", IdBox).CornerRadius = UDim.new(0, 5)

local InsertIdBtn = Instance.new("TextButton")
InsertIdBtn.Size = UDim2.new(0, 56, 0, 25)
InsertIdBtn.Position = UDim2.new(1, -62, 0, 8)
InsertIdBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
InsertIdBtn.Text = "INSERT"
InsertIdBtn.Font = Enum.Font.GothamBold
InsertIdBtn.TextSize = 9
InsertIdBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
InsertIdBtn.Parent = SearchSection
Instance.new("UICorner", InsertIdBtn).CornerRadius = UDim.new(0, 5)

-- Keyword Search
local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -72, 0, 25)
SearchBox.Position = UDim2.new(0, 6, 0, 38)
SearchBox.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
SearchBox.PlaceholderText = "Cari kata kunci..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(110, 110, 120)
SearchBox.Text = ""
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 10
SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBox.ClearTextOnFocus = false
SearchBox.Parent = SearchSection
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 5)

local SearchBtn = Instance.new("TextButton")
SearchBtn.Size = UDim2.new(0, 56, 0, 25)
SearchBtn.Position = UDim2.new(1, -62, 0, 38)
SearchBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SearchBtn.Text = "CARI"
SearchBtn.Font = Enum.Font.GothamBold
SearchBtn.TextSize = 9
SearchBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
SearchBtn.Parent = SearchSection
Instance.new("UICorner", SearchBtn).CornerRadius = UDim.new(0, 5)

-- Categories
local selectedCategory = 10
local categoryButtons = {}
local categories = {
    {name = "MODEL", id = 10},
    {name = "DECAL", id = 13},
    {name = "AUDIO", id = 3},
    {name = "MESH", id = 11}
}

local CatRow = Instance.new("Frame")
CatRow.Size = UDim2.new(1, -12, 0, 20)
CatRow.Position = UDim2.new(0, 6, 0, 68)
CatRow.BackgroundTransparency = 1
CatRow.Parent = SearchSection

local CatLayout = Instance.new("UIListLayout")
CatLayout.FillDirection = Enum.FillDirection.Horizontal
CatLayout.Padding = UDim.new(0, 4)
CatLayout.Parent = CatRow

local function updateTabs()
    for id, btn in pairs(categoryButtons) do
        if id == selectedCategory then
            btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            btn.TextColor3 = Color3.fromRGB(0, 0, 0)
        else
            btn.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
            btn.TextColor3 = Color3.fromRGB(160, 160, 170)
        end
    end
end

for _, cat in ipairs(categories) do
    local cBtn = Instance.new("TextButton")
    cBtn.Size = UDim2.new(0.25, -3, 1, 0)
    cBtn.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
    cBtn.Text = cat.name
    cBtn.Font = Enum.Font.GothamBold
    cBtn.TextSize = 8
    cBtn.TextColor3 = Color3.fromRGB(160, 160, 170)
    cBtn.Parent = CatRow
    Instance.new("UICorner", cBtn).CornerRadius = UDim.new(0, 4)

    local cStrk = Instance.new("UIStroke", cBtn)
    cStrk.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    cStrk.Color = Color3.fromRGB(255, 255, 255)
    cStrk.Thickness = 1
    cStrk.Transparency = 0.8

    categoryButtons[cat.id] = cBtn
    cBtn.MouseButton1Click:Connect(function()
        selectedCategory = cat.id
        updateTabs()
    end)
end
updateTabs()

local SearchStatus = Instance.new("TextLabel")
SearchStatus.Size = UDim2.new(1, -12, 0, 18)
SearchStatus.Position = UDim2.new(0, 6, 0, 94)
SearchStatus.BackgroundTransparency = 1
SearchStatus.Text = "[•] Mode: Model | Siap Insert"
SearchStatus.Font = Enum.Font.Gotham
SearchStatus.TextSize = 9
SearchStatus.TextColor3 = Color3.fromRGB(140, 140, 150)
SearchStatus.TextXAlignment = Enum.TextXAlignment.Left
SearchStatus.Parent = SearchSection

-- Box 2: Detail Asset Panel
local DetailBox = Instance.new("Frame")
DetailBox.Size = UDim2.new(1, 0, 1, -128)
DetailBox.Position = UDim2.new(0, 0, 0, 128)
DetailBox.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
DetailBox.Parent = LeftPanel
Instance.new("UICorner", DetailBox).CornerRadius = UDim.new(0, 8)
local DB_Stroke = Instance.new("UIStroke", DetailBox)
DB_Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
DB_Stroke.Color = Color3.fromRGB(255, 255, 255)
DB_Stroke.Thickness = 1
DB_Stroke.Transparency = 0.75

local DetailTitle = Instance.new("TextLabel")
DetailTitle.Size = UDim2.new(1, -12, 0, 18)
DetailTitle.Position = UDim2.new(0, 8, 0, 4)
DetailTitle.BackgroundTransparency = 1
DetailTitle.Text = "DETAIL ASSET"
DetailTitle.Font = Enum.Font.GothamBold
DetailTitle.TextSize = 9
DetailTitle.TextColor3 = Color3.fromRGB(200, 200, 210)
DetailTitle.TextXAlignment = Enum.TextXAlignment.Left
DetailTitle.Parent = DetailBox

local DetailThumb = Instance.new("ImageLabel")
DetailThumb.Size = UDim2.new(0, 54, 0, 54)
DetailThumb.Position = UDim2.new(0, 8, 0, 24)
DetailThumb.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
DetailThumb.Image = ""
DetailThumb.Parent = DetailBox
Instance.new("UICorner", DetailThumb).CornerRadius = UDim.new(0, 6)
local DT_Stroke = Instance.new("UIStroke", DetailThumb)
DT_Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
DT_Stroke.Color = Color3.fromRGB(255, 255, 255)
DT_Stroke.Thickness = 1
DT_Stroke.Transparency = 0.8

local DetailName = Instance.new("TextLabel")
DetailName.Size = UDim2.new(1, -72, 0, 26)
DetailName.Position = UDim2.new(0, 68, 0, 22)
DetailName.BackgroundTransparency = 1
DetailName.Text = "Pilih aset dari grid"
DetailName.Font = Enum.Font.GothamBold
DetailName.TextSize = 10
DetailName.TextColor3 = Color3.fromRGB(255, 255, 255)
DetailName.TextXAlignment = Enum.TextXAlignment.Left
DetailName.TextYAlignment = Enum.TextYAlignment.Top
DetailName.TextWrapped = true
DetailName.Parent = DetailBox

local DetailCreator = Instance.new("TextLabel")
DetailCreator.Size = UDim2.new(1, -72, 0, 14)
DetailCreator.Position = UDim2.new(0, 68, 0, 48)
DetailCreator.BackgroundTransparency = 1
DetailCreator.Text = "By: -"
DetailCreator.Font = Enum.Font.Gotham
DetailCreator.TextSize = 8
DetailCreator.TextColor3 = Color3.fromRGB(150, 150, 160)
DetailCreator.TextXAlignment = Enum.TextXAlignment.Left
DetailCreator.Parent = DetailBox

local DetailId = Instance.new("TextLabel")
DetailId.Size = UDim2.new(1, -72, 0, 14)
DetailId.Position = UDim2.new(0, 68, 0, 62)
DetailId.BackgroundTransparency = 1
DetailId.Text = "ID: -"
DetailId.Font = Enum.Font.Gotham
DetailId.TextSize = 8
DetailId.TextColor3 = Color3.fromRGB(150, 150, 160)
DetailId.TextXAlignment = Enum.TextXAlignment.Left
DetailId.Parent = DetailBox

local currentInspectedId = ""

local DetailBtnRow = Instance.new("Frame")
DetailBtnRow.Size = UDim2.new(1, -16, 0, 26)
DetailBtnRow.Position = UDim2.new(0, 8, 1, -32)
DetailBtnRow.BackgroundTransparency = 1
DetailBtnRow.Parent = DetailBox

local DetailInsertBtn = Instance.new("TextButton")
DetailInsertBtn.Size = UDim2.new(0.5, -3, 1, 0)
DetailInsertBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
DetailInsertBtn.Text = "INSERT"
DetailInsertBtn.Font = Enum.Font.GothamBold
DetailInsertBtn.TextSize = 9
DetailInsertBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
DetailInsertBtn.Parent = DetailBtnRow
Instance.new("UICorner", DetailInsertBtn).CornerRadius = UDim.new(0, 5)

local DetailCopyBtn = Instance.new("TextButton")
DetailCopyBtn.Size = UDim2.new(0.5, -3, 1, 0)
DetailCopyBtn.Position = UDim2.new(0.5, 3, 0, 0)
DetailCopyBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
DetailCopyBtn.Text = "COPY ID"
DetailCopyBtn.Font = Enum.Font.GothamBold
DetailCopyBtn.TextSize = 9
DetailCopyBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
DetailCopyBtn.Parent = DetailBtnRow
Instance.new("UICorner", DetailCopyBtn).CornerRadius = UDim.new(0, 5)

DetailCopyBtn.MouseButton1Click:Connect(function()
    if currentInspectedId ~= "" and copyClipboard then
        copyClipboard(currentInspectedId)
        DetailCopyBtn.Text = "COPIED ✓"
        task.delay(1.2, function()
            if DetailCopyBtn and DetailCopyBtn.Parent then
                DetailCopyBtn.Text = "COPY ID"
            end
        end)
    end
end)

DetailInsertBtn.MouseButton1Click:Connect(function()
    if currentInspectedId ~= "" then
        DetailInsertBtn.Text = "INSERTING..."
        SearchStatus.Text = "[•] Menghubungi Studio Lite..."
        task.spawn(function()
            local ok, method = executeSmartInsert(currentInspectedId)
            SearchStatus.Text = "[•] " .. method
            if DetailInsertBtn and DetailInsertBtn.Parent then
                DetailInsertBtn.Text = ok and "BERHASIL ✓" or "COPIED ✓"
                task.delay(1.5, function()
                    if DetailInsertBtn and DetailInsertBtn.Parent then
                        DetailInsertBtn.Text = "INSERT"
                    end
                end)
            end
        end)
    end
end)

local function inspectAsset(assetId, name, creator)
    currentInspectedId = tostring(assetId)
    DetailThumb.Image = "rbxthumb://type=Asset&id=" .. currentInspectedId .. "&w=150&h=150"
    DetailName.Text = name or "Memuat nama..."
    DetailCreator.Text = "By: @" .. (creator or "Unknown")
    DetailId.Text = "ID: " .. currentInspectedId

    local num = tonumber(currentInspectedId)
    if num and num > 0 then
        task.spawn(function()
            local s, info = pcall(function()
                return MarketplaceService:GetProductInfo(num)
            end)
            if s and info and info.Name and currentInspectedId == tostring(num) then
                DetailName.Text = info.Name
                local realCreator = (info.Creator and info.Creator.Name) or creator
                DetailCreator.Text = "By: @" .. realCreator
            end
        end)
    end
end

-- ========================================================
-- SISI KANAN - ASSET BROWSER GRID
-- ========================================================
local RightPanel = Instance.new("Frame")
RightPanel.Size = UDim2.new(1, -243, 1, 0)
RightPanel.Position = UDim2.new(0, 243, 0, 0)
RightPanel.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
RightPanel.Parent = ContentContainer
Instance.new("UICorner", RightPanel).CornerRadius = UDim.new(0, 8)
local RP_Stroke = Instance.new("UIStroke", RightPanel)
RP_Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
RP_Stroke.Color = Color3.fromRGB(255, 255, 255)
RP_Stroke.Thickness = 1
RP_Stroke.Transparency = 0.75

local BrowserHeader = Instance.new("TextLabel")
BrowserHeader.Size = UDim2.new(1, -16, 0, 24)
BrowserHeader.Position = UDim2.new(0, 8, 0, 4)
BrowserHeader.BackgroundTransparency = 1
BrowserHeader.Text = "ASSET BROWSER"
BrowserHeader.Font = Enum.Font.GothamBold
BrowserHeader.TextSize = 10
BrowserHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
BrowserHeader.TextXAlignment = Enum.TextXAlignment.Left
BrowserHeader.Parent = RightPanel

local GridScroll = Instance.new("ScrollingFrame")
GridScroll.Size = UDim2.new(1, -12, 1, -34)
GridScroll.Position = UDim2.new(0, 6, 0, 28)
GridScroll.BackgroundTransparency = 1
GridScroll.ScrollBarThickness = 3
GridScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
GridScroll.Parent = RightPanel

local UIGrid = Instance.new("UIGridLayout")
UIGrid.CellSize = UDim2.new(0, 108, 0, 118)
UIGrid.CellPadding = UDim2.new(0, 6, 0, 6)
UIGrid.SortOrder = Enum.SortOrder.LayoutOrder
UIGrid.Parent = GridScroll

local GridStatus = Instance.new("TextLabel")
GridStatus.Size = UDim2.new(1, 0, 0, 40)
GridStatus.BackgroundTransparency = 1
GridStatus.Text = "Ketik kata kunci lalu klik CARI"
GridStatus.Font = Enum.Font.Gotham
GridStatus.TextSize = 10
GridStatus.TextColor3 = Color3.fromRGB(140, 140, 150)
GridStatus.Parent = GridScroll

-- DRAGGABLE ENGINE
local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos = false, nil, nil

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
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
        MainFrame.Size = UDim2.new(0, 600, 0, 320)
        TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 620, 0, 335)
        }):Play()
    else
        local tween = TweenService:Create(MainFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 590, 0, 310)
        })
        tween:Play()
        tween.Completed:Connect(function()
            if not isOpen then MainFrame.Visible = false end
        end)
    end
end

ToggleBtn.MouseButton1Click:Connect(toggleWindow)
CloseBtn.MouseButton1Click:Connect(toggleWindow)

-- QUERY LOGIC (HTTP ROBLOX TOOLBOX MARKETPLACE)
local function queryMarketplace(category, query)
    local encoded = HttpService:UrlEncode(query)
    local endpoints = {
        string.format("https://apis.roproxy.com/toolbox-service/v1/marketplace/%d?keyword=%s&limit=30", category, encoded),
        string.format("https://apis.roblox.com/toolbox-service/v1/marketplace/%d?keyword=%s&limit=30", category, encoded)
    }

    for _, url in ipairs(endpoints) do
        local success, res = pcall(function()
            return httpRequest({
                Url = url,
                Method = "GET",
                Headers = {["User-Agent"] = "RobloxStudio/WinInet"}
            })
        end)

        if success and res and res.StatusCode == 200 then
            local decodeSuccess, parsed = pcall(function()
                return HttpService:JSONDecode(res.Body)
            end)
            if decodeSuccess and parsed and parsed.data and #parsed.data > 0 then
                return parsed.data
            end
        end
    end
    return nil
end

local function renderGrid(data)
    for _, item in ipairs(GridScroll:GetChildren()) do
        if item:IsA("Frame") then item:Destroy() end
    end

    if not data or #data == 0 then
        GridStatus.Visible = true
        GridStatus.Text = "Tidak ada aset ditemukan."
        return
    end

    GridStatus.Visible = false

    local first = data[1]
    if first then
        local fId = first.id or (first.asset and first.asset.id) or "0"
        local fName = first.name or (first.asset and first.asset.name) or "Asset"
        local fCreator = (first.creator and first.creator.name) or (first.asset and first.asset.creator and first.asset.creator.name) or "Unknown"
        inspectAsset(fId, fName, fCreator)
    end

    for _, item in ipairs(data) do
        local assetId = tostring(item.id or (item.asset and item.asset.id) or "0")
        local assetName = item.name or (item.asset and item.asset.name) or "Asset"
        local creatorName = (item.creator and item.creator.name) or (item.asset and item.asset.creator and item.asset.creator.name) or "Unknown"

        local Card = Instance.new("Frame")
        Card.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
        Card.BorderSizePixel = 0
        Card.Parent = GridScroll
        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 6)

        local C_Stroke = Instance.new("UIStroke", Card)
        C_Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        C_Stroke.Color = Color3.fromRGB(255, 255, 255)
        C_Stroke.Thickness = 1
        C_Stroke.Transparency = 0.85

        local Thumb = Instance.new("ImageLabel")
        Thumb.Size = UDim2.new(1, -8, 0, 52)
        Thumb.Position = UDim2.new(0, 4, 0, 4)
        Thumb.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
        Thumb.Image = "rbxthumb://type=Asset&id=" .. assetId .. "&w=150&h=150"
        Thumb.Parent = Card
        Instance.new("UICorner", Thumb).CornerRadius = UDim.new(0, 5)

        local NameLbl = Instance.new("TextLabel")
        NameLbl.Size = UDim2.new(1, -8, 0, 14)
        NameLbl.Position = UDim2.new(0, 4, 0, 58)
        NameLbl.BackgroundTransparency = 1
        NameLbl.Text = assetName
        NameLbl.Font = Enum.Font.GothamBold
        NameLbl.TextSize = 8
        NameLbl.TextColor3 = Color3.fromRGB(240, 240, 240)
        NameLbl.TextXAlignment = Enum.TextXAlignment.Left
        NameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        NameLbl.Parent = Card

        local SubLbl = Instance.new("TextLabel")
        SubLbl.Size = UDim2.new(1, -8, 0, 12)
        SubLbl.Position = UDim2.new(0, 4, 0, 72)
        SubLbl.BackgroundTransparency = 1
        SubLbl.Text = "@" .. creatorName
        SubLbl.Font = Enum.Font.Gotham
        SubLbl.TextSize = 7
        SubLbl.TextColor3 = Color3.fromRGB(140, 140, 150)
        SubLbl.TextXAlignment = Enum.TextXAlignment.Left
        SubLbl.TextTruncate = Enum.TextTruncate.AtEnd
        SubLbl.Parent = Card

        -- Tombol Aksi: INSERT & COPY
        local CardBtnRow = Instance.new("Frame")
        CardBtnRow.Size = UDim2.new(1, -8, 0, 18)
        CardBtnRow.Position = UDim2.new(0, 4, 1, -22)
        CardBtnRow.BackgroundTransparency = 1
        CardBtnRow.Parent = Card

        local CardInsert = Instance.new("TextButton")
        CardInsert.Size = UDim2.new(0.5, -2, 1, 0)
        CardInsert.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        CardInsert.Text = "INSERT"
        CardInsert.Font = Enum.Font.GothamBold
        CardInsert.TextSize = 8
        CardInsert.TextColor3 = Color3.fromRGB(0, 0, 0)
        CardInsert.Parent = CardBtnRow
        Instance.new("UICorner", CardInsert).CornerRadius = UDim.new(0, 4)

        local CardCopy = Instance.new("TextButton")
        CardCopy.Size = UDim2.new(0.5, -2, 1, 0)
        CardCopy.Position = UDim2.new(0.5, 2, 0, 0)
        CardCopy.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        CardCopy.Text = "COPY"
        CardCopy.Font = Enum.Font.GothamBold
        CardCopy.TextSize = 8
        CardCopy.TextColor3 = Color3.fromRGB(0, 0, 0)
        CardCopy.Parent = CardBtnRow
        Instance.new("UICorner", CardCopy).CornerRadius = UDim.new(0, 4)

        CardCopy.MouseButton1Click:Connect(function()
            if copyClipboard then
                copyClipboard(assetId)
                CardCopy.Text = "✓"
                task.delay(1.2, function()
                    if CardCopy and CardCopy.Parent then
                        CardCopy.Text = "COPY"
                    end
                end)
            end
        end)

        CardInsert.MouseButton1Click:Connect(function()
            CardInsert.Text = "..."
            SearchStatus.Text = "[•] Memproses: " .. assetId
            task.spawn(function()
                local ok, method = executeSmartInsert(assetId)
                SearchStatus.Text = "[•] " .. method
                if CardInsert and CardInsert.Parent then
                    CardInsert.Text = ok and "✓" or "COPY"
                    task.delay(1.2, function()
                        if CardInsert and CardInsert.Parent then
                            CardInsert.Text = "INSERT"
                        end
                    end)
                end
            end)
        end)

        local Hitbox = Instance.new("TextButton")
        Hitbox.Size = UDim2.new(1, 0, 0, 86)
        Hitbox.BackgroundTransparency = 1
        Hitbox.Text = ""
        Hitbox.Parent = Card
        Hitbox.MouseButton1Click:Connect(function()
            inspectAsset(assetId, NameLbl.Text, creatorName)
        end)

        local num = tonumber(assetId)
        if num and num > 0 then
            task.spawn(function()
                local s, info = pcall(function()
                    return MarketplaceService:GetProductInfo(num)
                end)
                if s and info and info.Name and NameLbl and NameLbl.Parent then
                    NameLbl.Text = info.Name
                    local realCreator = (info.Creator and info.Creator.Name) or creatorName
                    SubLbl.Text = "@" .. realCreator
                end
            end)
        end
    end

    UIGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        GridScroll.CanvasSize = UDim2.new(0, 0, 0, UIGrid.AbsoluteContentSize.Y + 10)
    end)
    GridScroll.CanvasSize = UDim2.new(0, 0, 0, UIGrid.AbsoluteContentSize.Y + 10)
end

-- Listener Search
local function executeSearch()
    if SearchBox.Text ~= "" then
        GridStatus.Visible = true
        GridStatus.Text = "Mencari di Roblox Toolbox..."
        SearchStatus.Text = "[•] Mencari: " .. SearchBox.Text
        task.spawn(function()
            local data = queryMarketplace(selectedCategory, SearchBox.Text)
            renderGrid(data)
            SearchStatus.Text = "[•] Selesai | Kategori: " .. selectedCategory
        end)
    end
end

SearchBtn.MouseButton1Click:Connect(executeSearch)
SearchBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then executeSearch() end
end)

-- Listener Direct ID Insert Button
InsertIdBtn.MouseButton1Click:Connect(function()
    local inputId = IdBox.Text:gsub("%D+", "")
    if inputId ~= "" then
        inspectAsset(inputId, "Memuat Asset ID...", "Mencari...")
        InsertIdBtn.Text = "..."
        SearchStatus.Text = "[•] Mengirim ke Studio Lite..."
        task.spawn(function()
            local ok, method = executeSmartInsert(inputId)
            SearchStatus.Text = "[•] " .. method
            if InsertIdBtn and InsertIdBtn.Parent then
                InsertIdBtn.Text = ok and "BERHASIL ✓" or "COPIED ✓"
                task.delay(1.5, function()
                    if InsertIdBtn and InsertIdBtn.Parent then
                        InsertIdBtn.Text = "INSERT"
                    end
                end)
            end
        end)
    end
end)
