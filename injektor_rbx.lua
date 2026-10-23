-- =======================================================
-- BLUExCrown ENGINE - PRO SPLIT-GRID EDITION (LANDSCAPE)
-- Inspired by Toolbox Riza Layout | Strictly Black & White
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

-- 1. FLOATING TOGGLE BUTTON (Asset ID: 102337382069600)
local ToggleBtn = Instance.new("ImageButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Size = UDim2.new(0, 42, 0, 42)
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

-- 2. MAIN WINDOW FRAME (PRO LANDSCAPE: 580 x 310)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.fromScale(0.5, 0.5)
MainFrame.Size = UDim2.new(0, 580, 0, 310)
MainFrame.BackgroundColor3 = Color3.fromRGB(13, 13, 15)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MainStroke.Color = Color3.fromRGB(255, 255, 255)
MainStroke.Thickness = 1.4

-- Top Header
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 32)
TopBar.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "BLUExCrown ENGINE v3.3"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 11
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 22, 0, 22)
CloseBtn.Position = UDim2.new(1, -28, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
CloseBtn.Text = "✕"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 10
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Parent = TopBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 5)
local CloseStroke = Instance.new("UIStroke", CloseBtn)
CloseStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
CloseStroke.Color = Color3.fromRGB(255, 255, 255)
CloseStroke.Thickness = 1
CloseStroke.Transparency = 0.5

-- Container Pembagi Kiri & Kanan
local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -16, 1, -40)
ContentContainer.Position = UDim2.new(0, 8, 0, 34)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = MainFrame

-- ==========================================
-- SISI KIRI (WIDTH: 220px) - SEARCH & DETAIL
-- ==========================================
local LeftPanel = Instance.new("Frame")
LeftPanel.Size = UDim2.new(0, 220, 1, 0)
LeftPanel.BackgroundTransparency = 1
LeftPanel.Parent = ContentContainer

-- Box 1: Search & Direct ID
local SearchSection = Instance.new("Frame")
SearchSection.Size = UDim2.new(1, 0, 0, 118)
SearchSection.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
SearchSection.Parent = LeftPanel
Instance.new("UICorner", SearchSection).CornerRadius = UDim.new(0, 8)
local SS_Stroke = Instance.new("UIStroke", SearchSection)
SS_Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
SS_Stroke.Color = Color3.fromRGB(255, 255, 255)
SS_Stroke.Thickness = 1
SS_Stroke.Transparency = 0.75

-- Row 1: Direct Load ID
local IdBox = Instance.new("TextBox")
IdBox.Size = UDim2.new(1, -66, 0, 24)
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

local LoadIdBtn = Instance.new("TextButton")
LoadIdBtn.Size = UDim2.new(0, 50, 0, 24)
LoadIdBtn.Position = UDim2.new(1, -56, 0, 8)
LoadIdBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
LoadIdBtn.Text = "LOAD"
LoadIdBtn.Font = Enum.Font.GothamBold
LoadIdBtn.TextSize = 9
LoadIdBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
LoadIdBtn.Parent = SearchSection
Instance.new("UICorner", LoadIdBtn).CornerRadius = UDim.new(0, 5)

-- Row 2: Keyword Search
local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -66, 0, 24)
SearchBox.Position = UDim2.new(0, 6, 0, 36)
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
SearchBtn.Size = UDim2.new(0, 50, 0, 24)
SearchBtn.Position = UDim2.new(1, -56, 0, 36)
SearchBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SearchBtn.Text = "CARI"
SearchBtn.Font = Enum.Font.GothamBold
SearchBtn.TextSize = 9
SearchBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
SearchBtn.Parent = SearchSection
Instance.new("UICorner", SearchBtn).CornerRadius = UDim.new(0, 5)

-- Row 3: Category Selector Pills
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
CatRow.Position = UDim2.new(0, 6, 0, 65)
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

-- Status Text
local SearchStatus = Instance.new("TextLabel")
SearchStatus.Size = UDim2.new(1, -12, 0, 20)
SearchStatus.Position = UDim2.new(0, 6, 0, 90)
SearchStatus.BackgroundTransparency = 1
SearchStatus.Text = "[•] Mode: Model | Siap cari"
SearchStatus.Font = Enum.Font.Gotham
SearchStatus.TextSize = 9
SearchStatus.TextColor3 = Color3.fromRGB(140, 140, 150)
SearchStatus.TextXAlignment = Enum.TextXAlignment.Left
SearchStatus.Parent = SearchSection

-- Box 2: Detail Asset Panel (Inspector)
local DetailBox = Instance.new("Frame")
DetailBox.Size = UDim2.new(1, 0, 1, -124)
DetailBox.Position = UDim2.new(0, 0, 0, 124)
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
DetailThumb.Size = UDim2.new(0, 50, 0, 50)
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
DetailName.Size = UDim2.new(1, -68, 0, 24)
DetailName.Position = UDim2.new(0, 64, 0, 22)
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
DetailCreator.Size = UDim2.new(1, -68, 0, 14)
DetailCreator.Position = UDim2.new(0, 64, 0, 46)
DetailCreator.BackgroundTransparency = 1
DetailCreator.Text = "By: -"
DetailCreator.Font = Enum.Font.Gotham
DetailCreator.TextSize = 8
DetailCreator.TextColor3 = Color3.fromRGB(150, 150, 160)
DetailCreator.TextXAlignment = Enum.TextXAlignment.Left
DetailCreator.Parent = DetailBox

local DetailId = Instance.new("TextLabel")
DetailId.Size = UDim2.new(1, -68, 0, 14)
DetailId.Position = UDim2.new(0, 64, 0, 58)
DetailId.BackgroundTransparency = 1
DetailId.Text = "ID: -"
DetailId.Font = Enum.Font.Gotham
DetailId.TextSize = 8
DetailId.TextColor3 = Color3.fromRGB(150, 150, 160)
DetailId.TextXAlignment = Enum.TextXAlignment.Left
DetailId.Parent = DetailBox

local DetailWarning = Instance.new("TextLabel")
DetailWarning.Size = UDim2.new(1, -16, 0, 20)
DetailWarning.Position = UDim2.new(0, 8, 0, 78)
DetailWarning.BackgroundTransparency = 1
DetailWarning.Text = "[!] Siap dimasukkan ke Studio Lite"
DetailWarning.Font = Enum.Font.Gotham
DetailWarning.TextSize = 8
DetailWarning.TextColor3 = Color3.fromRGB(180, 180, 190)
DetailWarning.TextXAlignment = Enum.TextXAlignment.Left
DetailWarning.Parent = DetailBox

-- Tombol Copy ID di Inspector
local DetailCopyBtn = Instance.new("TextButton")
DetailCopyBtn.Size = UDim2.new(1, -16, 0, 26)
DetailCopyBtn.Position = UDim2.new(0, 8, 1, -32)
DetailCopyBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
DetailCopyBtn.Text = "COPY ASSET ID"
DetailCopyBtn.Font = Enum.Font.GothamBold
DetailCopyBtn.TextSize = 9
DetailCopyBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
DetailCopyBtn.Parent = DetailBox
Instance.new("UICorner", DetailCopyBtn).CornerRadius = UDim.new(0, 6)

local currentInspectedId = ""
DetailCopyBtn.MouseButton1Click:Connect(function()
    if currentInspectedId ~= "" and copyClipboard then
        copyClipboard(currentInspectedId)
        DetailCopyBtn.Text = "ID TERSALIN ✓"
        task.delay(1.5, function()
            if DetailCopyBtn and DetailCopyBtn.Parent then
                DetailCopyBtn.Text = "COPY ASSET ID"
            end
        end)
    end
end)

-- Fungsi untuk update isi Detail Inspector
local function inspectAsset(assetId, name, creator)
    currentInspectedId = tostring(assetId)
    DetailThumb.Image = "rbxthumb://type=Asset&id=" .. currentInspectedId .. "&w=150&h=150"
    DetailName.Text = name or "Memuat nama..."
    DetailCreator.Text = "By: @" .. (creator or "Unknown")
    DetailId.Text = "ID: " .. currentInspectedId

    -- Fetch nama resmi
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
-- SISI KANAN (WIDTH: Sisa ~336px) - ASSET BROWSER GRID (3-COL)
-- ========================================================
local RightPanel = Instance.new("Frame")
RightPanel.Size = UDim2.new(1, -228, 1, 0)
RightPanel.Position = UDim2.new(0, 228, 0, 0)
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
UIGrid.CellSize = UDim2.new(0, 98, 0, 110)
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

-- Toggle Open/Close Window
local isOpen = true
local function toggleWindow()
    isOpen = not isOpen
    if isOpen then
        MainFrame.Visible = true
        MainFrame.Size = UDim2.new(0, 560, 0, 295)
        TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 580, 0, 310)
        }):Play()
    else
        local tween = TweenService:Create(MainFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 550, 0, 285)
        })
        tween:Play()
        tween.Completed:Connect(function()
            if not isOpen then MainFrame.Visible = false end
        end)
    end
end

ToggleBtn.MouseButton1Click:Connect(toggleWindow)
CloseBtn.MouseButton1Click:Connect(toggleWindow)

-- QUERY LOGIC
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

    -- Set preview pertama kali ke item pertama
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

        -- Card Box
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

        -- Thumbnail
        local Thumb = Instance.new("ImageLabel")
        Thumb.Size = UDim2.new(1, -8, 0, 50)
        Thumb.Position = UDim2.new(0, 4, 0, 4)
        Thumb.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
        Thumb.Image = "rbxthumb://type=Asset&id=" .. assetId .. "&w=150&h=150"
        Thumb.Parent = Card
        Instance.new("UICorner", Thumb).CornerRadius = UDim.new(0, 5)

        -- Title
        local NameLbl = Instance.new("TextLabel")
        NameLbl.Size = UDim2.new(1, -8, 0, 14)
        NameLbl.Position = UDim2.new(0, 4, 0, 56)
        NameLbl.BackgroundTransparency = 1
        NameLbl.Text = assetName
        NameLbl.Font = Enum.Font.GothamBold
        NameLbl.TextSize = 8
        NameLbl.TextColor3 = Color3.fromRGB(240, 240, 240)
        NameLbl.TextXAlignment = Enum.TextXAlignment.Left
        NameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        NameLbl.Parent = Card

        -- Creator / ID
        local SubLbl = Instance.new("TextLabel")
        SubLbl.Size = UDim2.new(1, -8, 0, 12)
        SubLbl.Position = UDim2.new(0, 4, 0, 70)
        SubLbl.BackgroundTransparency = 1
        SubLbl.Text = "@" .. creatorName
        SubLbl.Font = Enum.Font.Gotham
        SubLbl.TextSize = 7
        SubLbl.TextColor3 = Color3.fromRGB(140, 140, 150)
        SubLbl.TextXAlignment = Enum.TextXAlignment.Left
        SubLbl.TextTruncate = Enum.TextTruncate.AtEnd
        SubLbl.Parent = Card

        -- Copy Button
        local CardCopy = Instance.new("TextButton")
        CardCopy.Size = UDim2.new(1, -8, 0, 18)
        CardCopy.Position = UDim2.new(0, 4, 1, -22)
        CardCopy.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        CardCopy.Text = "COPY"
        CardCopy.Font = Enum.Font.GothamBold
        CardCopy.TextSize = 8
        CardCopy.TextColor3 = Color3.fromRGB(0, 0, 0)
        CardCopy.Parent = Card
        Instance.new("UICorner", CardCopy).CornerRadius = UDim.new(0, 4)

        CardCopy.MouseButton1Click:Connect(function()
            if copyClipboard then
                copyClipboard(assetId)
                CardCopy.Text = "COPIED ✓"
                task.delay(1.2, function()
                    if CardCopy and CardCopy.Parent then
                        CardCopy.Text = "COPY"
                    end
                end)
            end
        end)

        -- Klik kartu untuk inspeksi di detail panel kiri
        local Hitbox = Instance.new("TextButton")
        Hitbox.Size = UDim2.new(1, 0, 0, 84)
        Hitbox.Position = UDim2.new(0, 0, 0, 0)
        Hitbox.BackgroundTransparency = 1
        Hitbox.Text = ""
        Hitbox.Parent = Card
        Hitbox.MouseButton1Click:Connect(function()
            inspectAsset(assetId, NameLbl.Text, creatorName)
        end)

        -- Fetch nama resmi di background
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
        SearchStatus.Text = "[•] Sedang mencari: " .. SearchBox.Text
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

-- Listener Direct ID Load
LoadIdBtn.MouseButton1Click:Connect(function()
    local inputId = IdBox.Text:gsub("%D+", "")
    if inputId ~= "" then
        inspectAsset(inputId, "Memuat Asset ID...", "Mencari...")
        if copyClipboard then
            copyClipboard(inputId)
            LoadIdBtn.Text = "COPIED"
            task.delay(1.2, function()
                if LoadIdBtn and LoadIdBtn.Parent then
                    LoadIdBtn.Text = "LOAD"
                end
            end)
        end
    end
end)
