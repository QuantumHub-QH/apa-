-- =======================================================
-- 👑 BLUExCrown ENGINE - TOOLBOX ASSET FINDER (LANDSCAPE)
-- Optimized for Delta Mobile / Studio Lite
-- =======================================================

local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local ParentGui = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

-- Cek executor
local httpRequest = request or http_request or (syn and syn.request) or (http and http.request)
local copyClipboard = setclipboard or toclipboard or (Clipboard and Clipboard.set)

if not httpRequest then
    warn("Executor tidak mendukung HTTP request!")
    return
end

-- Bersihkan versi lama jika ada
if ParentGui:FindFirstChild("BLUExCrownEngine") then
    ParentGui.BLUExCrownEngine:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BLUExCrownEngine"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = ParentGui

-- 1. FLOATING TOGGLE BUTTON (👑)
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Size = UDim2.new(0, 44, 0, 44)
ToggleBtn.Position = UDim2.new(0.02, 0, 0.4, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
ToggleBtn.Text = "👑"
ToggleBtn.TextSize = 20
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Parent = ScreenGui

Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)
local ToggleStroke = Instance.new("UIStroke", ToggleBtn)
ToggleStroke.Color = Color3.fromRGB(0, 150, 255)
ToggleStroke.Thickness = 2

-- 2. MAIN WINDOW FRAME (LANDSCAPE: 520 x 265)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 520, 0, 265)
MainFrame.Position = UDim2.new(0.5, -260, 0.5, -132)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 17, 24)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Color3.fromRGB(30, 80, 160)
MainStroke.Thickness = 1.5

-- Top Bar (Header)
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 34)
TopBar.BackgroundColor3 = Color3.fromRGB(22, 26, 38)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "👑 BLUExCrown ENGINE"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextColor3 = Color3.fromRGB(0, 170, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -30, 0, 4)
CloseBtn.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
CloseBtn.Text = "✕"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
CloseBtn.Parent = TopBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

-- Kategori & Search Bar (Didesain 1 Baris Landscape)
local ControlBar = Instance.new("Frame")
ControlBar.Size = UDim2.new(1, -20, 0, 32)
ControlBar.Position = UDim2.new(0, 10, 0, 40)
ControlBar.BackgroundTransparency = 1
ControlBar.Parent = MainFrame

-- Kategori Selector
local selectedCategory = 10 -- 10: Models
local categoryButtons = {}

local categories = {
    {name = "Models", id = 10},
    {name = "Decals", id = 13},
    {name = "Audio", id = 3},
    {name = "Meshes", id = 11}
}

local CatFrame = Instance.new("Frame")
CatFrame.Size = UDim2.new(0, 240, 1, 0)
CatFrame.BackgroundTransparency = 1
CatFrame.Parent = ControlBar

local CatLayout = Instance.new("UIListLayout")
CatLayout.FillDirection = Enum.FillDirection.Horizontal
CatLayout.Padding = UDim.new(0, 4)
CatLayout.Parent = CatFrame

local function updateCategoryTabs()
    for id, btn in pairs(categoryButtons) do
        if id == selectedCategory then
            btn.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            btn.BackgroundColor3 = Color3.fromRGB(25, 30, 42)
            btn.TextColor3 = Color3.fromRGB(150, 160, 180)
        end
    end
end

for _, cat in ipairs(categories) do
    local cBtn = Instance.new("TextButton")
    cBtn.Size = UDim2.new(0, 56, 1, 0)
    cBtn.BackgroundColor3 = Color3.fromRGB(25, 30, 42)
    cBtn.Text = cat.name
    cBtn.Font = Enum.Font.GothamBold
    cBtn.TextSize = 10
    cBtn.TextColor3 = Color3.fromRGB(150, 160, 180)
    cBtn.Parent = CatFrame
    Instance.new("UICorner", cBtn).CornerRadius = UDim.new(0, 6)

    categoryButtons[cat.id] = cBtn
    cBtn.MouseButton1Click:Connect(function()
        selectedCategory = cat.id
        updateCategoryTabs()
    end)
end
updateCategoryTabs()

-- Search Input & Button
local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -305, 1, 0)
SearchBox.Position = UDim2.new(0, 246, 0, 0)
SearchBox.BackgroundColor3 = Color3.fromRGB(22, 26, 36)
SearchBox.PlaceholderText = "Cari aset di sini..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(110, 120, 140)
SearchBox.Text = ""
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 11
SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBox.ClearTextOnFocus = false
SearchBox.Parent = ControlBar
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 6)

local SearchBtn = Instance.new("TextButton")
SearchBtn.Size = UDim2.new(0, 52, 1, 0)
SearchBtn.Position = UDim2.new(1, -52, 0, 0)
SearchBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
SearchBtn.Text = "Cari"
SearchBtn.Font = Enum.Font.GothamBold
SearchBtn.TextSize = 11
SearchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBtn.Parent = ControlBar
Instance.new("UICorner", SearchBtn).CornerRadius = UDim.new(0, 6)

-- Scroll Area (Widescreen Results)
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -20, 1, -82)
ScrollFrame.Position = UDim2.new(0, 10, 0, 76)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(40, 80, 150)
ScrollFrame.Parent = MainFrame

local UIList = Instance.new("UIListLayout")
UIList.Padding = UDim.new(0, 6)
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Parent = ScrollFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 30)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Pilih kategori & ketik kata kunci lalu tekan Cari"
StatusLabel.TextColor3 = Color3.fromRGB(130, 140, 160)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 11
StatusLabel.Parent = ScrollFrame

-- 3. TOUCH DRAG SUPPORT
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

ToggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)
CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

-- 4. PENCARIAN & PARSER NAMA ASET LENGKAP
local function queryMarketplace(category, query)
    local encoded = HttpService:UrlEncode(query)
    local endpoints = {
        string.format("https://apis.roproxy.com/toolbox-service/v1/marketplace/%d?keyword=%s&limit=25", category, encoded),
        string.format("https://apis.roblox.com/toolbox-service/v1/marketplace/%d?keyword=%s&limit=25", category, encoded)
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

local function searchAssets(query)
    for _, item in ipairs(ScrollFrame:GetChildren()) do
        if item:IsA("Frame") then
            item:Destroy()
        end
    end

    StatusLabel.Visible = true
    StatusLabel.Text = "👑 BLUExCrown sedang mencari aset..."

    local data = queryMarketplace(selectedCategory, query)
    if not data or #data == 0 then
        StatusLabel.Text = "Aset tidak ditemukan. Coba kata kunci lain."
        return
    end

    StatusLabel.Visible = false

    for _, item in ipairs(data) do
        -- 1. Ekstrak ID
        local rawId = item.id or (item.asset and item.asset.id) or item.assetId or "0"
        local assetId = tostring(rawId)

        -- 2. Ekstrak Nama dari JSON
        local rawName = item.name or item.Name or item.title or item.Title or item.assetName
        if (not rawName or rawName == "") and item.asset then
            rawName = item.asset.name or item.asset.Name or item.asset.title
        end

        -- 3. Ekstrak Creator
        local rawCreator = (item.creator and item.creator.name) or (item.asset and item.asset.creator and item.asset.creator.name) or "Unknown"

        -- Landscape Card (Widescreen)
        local Card = Instance.new("Frame")
        Card.Size = UDim2.new(1, -6, 0, 50)
        Card.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
        Card.BorderSizePixel = 0
        Card.Parent = ScrollFrame
        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 6)

        -- Thumbnail
        local Thumb = Instance.new("ImageLabel")
        Thumb.Size = UDim2.new(0, 40, 0, 40)
        Thumb.Position = UDim2.new(0, 5, 0, 5)
        Thumb.BackgroundColor3 = Color3.fromRGB(30, 35, 48)
        Thumb.Image = "rbxthumb://type=Asset&id=" .. assetId .. "&w=150&h=150"
        Thumb.Parent = Card
        Instance.new("UICorner", Thumb).CornerRadius = UDim.new(0, 5)

        -- Nama Aset
        local NameLabel = Instance.new("TextLabel")
        NameLabel.Size = UDim2.new(1, -145, 0, 18)
        NameLabel.Position = UDim2.new(0, 52, 0, 7)
        NameLabel.BackgroundTransparency = 1
        NameLabel.Text = (rawName and rawName ~= "") and rawName or "Memuat nama..."
        NameLabel.Font = Enum.Font.GothamBold
        NameLabel.TextSize = 12
        NameLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
        NameLabel.TextXAlignment = Enum.TextXAlignment.Left
        NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        NameLabel.Parent = Card

        -- Sub info (Creator & ID)
        local SubLabel = Instance.new("TextLabel")
        SubLabel.Size = UDim2.new(1, -145, 0, 14)
        SubLabel.Position = UDim2.new(0, 52, 0, 26)
        SubLabel.BackgroundTransparency = 1
        SubLabel.Text = "@" .. rawCreator .. " | ID: " .. assetId
        SubLabel.Font = Enum.Font.Gotham
        SubLabel.TextSize = 10
        SubLabel.TextColor3 = Color3.fromRGB(120, 140, 175)
        SubLabel.TextXAlignment = Enum.TextXAlignment.Left
        SubLabel.TextTruncate = Enum.TextTruncate.AtEnd
        SubLabel.Parent = Card

        -- Tombol Copy ID
        local CopyBtn = Instance.new("TextButton")
        CopyBtn.Size = UDim2.new(0, 68, 0, 28)
        CopyBtn.Position = UDim2.new(1, -74, 0.5, -14)
        CopyBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
        CopyBtn.Text = "Copy ID"
        CopyBtn.Font = Enum.Font.GothamBold
        CopyBtn.TextSize = 11
        CopyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        CopyBtn.Parent = Card
        Instance.new("UICorner", CopyBtn).CornerRadius = UDim.new(0, 6)

        CopyBtn.MouseButton1Click:Connect(function()
            if copyClipboard then
                copyClipboard(assetId)
                CopyBtn.Text = "Copied! ✓"
                CopyBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
                task.delay(1.5, function()
                    if CopyBtn and CopyBtn.Parent then
                        CopyBtn.Text = "Copy ID"
                        CopyBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
                    end
                end)
            end
        end)

        -- 5. FALLBACK RESMI VIA MARKETPLACESERVICE (Nama 100% Asli)
        local numId = tonumber(assetId)
        if numId and numId > 0 then
            task.spawn(function()
                local s, info = pcall(function()
                    return MarketplaceService:GetProductInfo(numId)
                end)
                if s and info and info.Name and NameLabel and NameLabel.Parent then
                    NameLabel.Text = info.Name
                    local finalCreator = (info.Creator and info.Creator.Name) or rawCreator
                    SubLabel.Text = "@" .. finalCreator .. " | ID: " .. assetId
                end
            end)
        end
    end

    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y + 15)
end

-- Listener Input
SearchBtn.MouseButton1Click:Connect(function()
    if SearchBox.Text ~= "" then
        searchAssets(SearchBox.Text)
    end
end)

SearchBox.FocusLost:Connect(function(enterPressed)
    if enterPressed and SearchBox.Text ~= "" then
        searchAssets(SearchBox.Text)
    end
end)
