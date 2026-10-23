-- =======================================================
-- BLUExCrown ENGINE - MONOCHROME EDITION (LANDSCAPE)
-- Strictly Black & White | Modern Minimalist
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

-- Bersihkan versi sebelumnya
if ParentGui:FindFirstChild("BLUExCrownEngine") then
    ParentGui.BLUExCrownEngine:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BLUExCrownEngine"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = ParentGui

-- 1. CUSTOM IMAGE TOGGLE BUTTON (ID: 102337382069600)
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
ToggleStroke.Color = Color3.fromRGB(255, 255, 255)
ToggleStroke.Thickness = 1.5

-- 2. MAIN WINDOW FRAME (COMPACT LANDSCAPE: 420 x 245)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 420, 0, 245)
MainFrame.Position = UDim2.new(0.5, -210, 0.5, -122)
MainFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 16)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Color3.fromRGB(255, 255, 255)
MainStroke.Thickness = 1.5

-- Top Bar (Header)
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 32)
TopBar.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -45, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "BLUExCrown ENGINE"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -28, 0, 4)
CloseBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
CloseBtn.Text = "✕"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 11
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Parent = TopBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
local CloseStroke = Instance.new("UIStroke", CloseBtn)
CloseStroke.Color = Color3.fromRGB(255, 255, 255)
CloseStroke.Thickness = 1
CloseStroke.Transparency = 0.5

-- Control Area (Kategori & Search)
local selectedCategory = 10 -- 10: Models
local categoryButtons = {}

local categories = {
    {name = "Models", id = 10},
    {name = "Decals", id = 13},
    {name = "Audio", id = 3},
    {name = "Meshes", id = 11}
}

-- Row 1: Kategori Pills
local CategoryFrame = Instance.new("Frame")
CategoryFrame.Size = UDim2.new(1, -20, 0, 24)
CategoryFrame.Position = UDim2.new(0, 10, 0, 38)
CategoryFrame.BackgroundTransparency = 1
CategoryFrame.Parent = MainFrame

local CatLayout = Instance.new("UIListLayout")
CatLayout.FillDirection = Enum.FillDirection.Horizontal
CatLayout.Padding = UDim.new(0, 6)
CatLayout.Parent = CategoryFrame

local function updateTabs()
    for id, btn in pairs(categoryButtons) do
        if id == selectedCategory then
            -- Active Tab (Putih Text Hitam)
            btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            btn.TextColor3 = Color3.fromRGB(0, 0, 0)
        else
            -- Inactive Tab (Hitam Text Putih)
            btn.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
            btn.TextColor3 = Color3.fromRGB(180, 180, 180)
        end
    end
end

for _, cat in ipairs(categories) do
    local cBtn = Instance.new("TextButton")
    cBtn.Size = UDim2.new(0, 58, 1, 0)
    cBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
    cBtn.Text = cat.name
    cBtn.Font = Enum.Font.GothamBold
    cBtn.TextSize = 10
    cBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
    cBtn.Parent = CategoryFrame
    Instance.new("UICorner", cBtn).CornerRadius = UDim.new(0, 6)

    local cStroke = Instance.new("UIStroke", cBtn)
    cStroke.Color = Color3.fromRGB(255, 255, 255)
    cStroke.Thickness = 1
    cStroke.Transparency = 0.6

    categoryButtons[cat.id] = cBtn
    cBtn.MouseButton1Click:Connect(function()
        selectedCategory = cat.id
        updateTabs()
    end)
end
updateTabs()

-- Row 2: Search Input & Button
local SearchFrame = Instance.new("Frame")
SearchFrame.Size = UDim2.new(1, -20, 0, 28)
SearchFrame.Position = UDim2.new(0, 10, 0, 68)
SearchFrame.BackgroundTransparency = 1
SearchFrame.Parent = MainFrame

local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -66, 1, 0)
SearchBox.Position = UDim2.new(0, 0, 0, 0)
SearchBox.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
SearchBox.PlaceholderText = "Ketik aset yang ingin dicari..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(110, 110, 120)
SearchBox.Text = ""
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 11
SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBox.ClearTextOnFocus = false
SearchBox.Parent = SearchFrame
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 6)

local SearchBoxStroke = Instance.new("UIStroke", SearchBox)
SearchBoxStroke.Color = Color3.fromRGB(255, 255, 255)
SearchBoxStroke.Thickness = 1
SearchBoxStroke.Transparency = 0.7

-- Tombol Cari (Warna Putih, Teks Hitam)
local SearchBtn = Instance.new("TextButton")
SearchBtn.Size = UDim2.new(0, 58, 1, 0)
SearchBtn.Position = UDim2.new(1, -58, 0, 0)
SearchBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SearchBtn.Text = "CARI"
SearchBtn.Font = Enum.Font.GothamBold
SearchBtn.TextSize = 10
SearchBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
SearchBtn.Parent = SearchFrame
Instance.new("UICorner", SearchBtn).CornerRadius = UDim.new(0, 6)

-- Scroll Area (Cards)
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -20, 1, -108)
ScrollFrame.Position = UDim2.new(0, 10, 0, 102)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.ScrollBarThickness = 3
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
ScrollFrame.Parent = MainFrame

local UIList = Instance.new("UIListLayout")
UIList.Padding = UDim.new(0, 6)
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Parent = ScrollFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 30)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Pilih kategori & klik Cari"
StatusLabel.TextColor3 = Color3.fromRGB(140, 140, 150)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 11
StatusLabel.Parent = ScrollFrame

-- 3. TOUCH DRAG
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

-- 4. MARKETPLACE LOGIC
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
    StatusLabel.Text = "Searching..."

    local data = queryMarketplace(selectedCategory, query)
    if not data or #data == 0 then
        StatusLabel.Text = "Aset tidak ditemukan. Coba kata kunci lain."
        return
    end

    StatusLabel.Visible = false

    for _, item in ipairs(data) do
        local rawId = item.id or (item.asset and item.asset.id) or item.assetId or "0"
        local assetId = tostring(rawId)

        local rawName = item.name or item.Name or item.title or item.Title or item.assetName
        if (not rawName or rawName == "") and item.asset then
            rawName = item.asset.name or item.asset.Name or item.asset.title
        end

        local rawCreator = (item.creator and item.creator.name) or (item.asset and item.asset.creator and item.asset.creator.name) or "Unknown"

        -- Card Frame
        local Card = Instance.new("Frame")
        Card.Size = UDim2.new(1, -6, 0, 46)
        Card.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
        Card.BorderSizePixel = 0
        Card.Parent = ScrollFrame
        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 6)

        local CardStroke = Instance.new("UIStroke", Card)
        CardStroke.Color = Color3.fromRGB(255, 255, 255)
        CardStroke.Thickness = 1
        CardStroke.Transparency = 0.85

        -- Thumbnail
        local Thumb = Instance.new("ImageLabel")
        Thumb.Size = UDim2.new(0, 36, 0, 36)
        Thumb.Position = UDim2.new(0, 5, 0, 5)
        Thumb.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
        Thumb.Image = "rbxthumb://type=Asset&id=" .. assetId .. "&w=150&h=150"
        Thumb.Parent = Card
        Instance.new("UICorner", Thumb).CornerRadius = UDim.new(0, 5)

        -- Asset Name
        local NameLabel = Instance.new("TextLabel")
        NameLabel.Size = UDim2.new(1, -135, 0, 16)
        NameLabel.Position = UDim2.new(0, 48, 0, 6)
        NameLabel.BackgroundTransparency = 1
        NameLabel.Text = (rawName and rawName ~= "") and rawName or "Memuat nama..."
        NameLabel.Font = Enum.Font.GothamBold
        NameLabel.TextSize = 11
        NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        NameLabel.TextXAlignment = Enum.TextXAlignment.Left
        NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        NameLabel.Parent = Card

        -- Sub info
        local SubLabel = Instance.new("TextLabel")
        SubLabel.Size = UDim2.new(1, -135, 0, 14)
        SubLabel.Position = UDim2.new(0, 48, 0, 24)
        SubLabel.BackgroundTransparency = 1
        SubLabel.Text = "@" .. rawCreator .. " | ID: " .. assetId
        SubLabel.Font = Enum.Font.Gotham
        SubLabel.TextSize = 9
        SubLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
        SubLabel.TextXAlignment = Enum.TextXAlignment.Left
        SubLabel.TextTruncate = Enum.TextTruncate.AtEnd
        SubLabel.Parent = Card

        -- Tombol Copy ID (Warna Putih, Text Hitam)
        local CopyBtn = Instance.new("TextButton")
        CopyBtn.Size = UDim2.new(0, 62, 0, 26)
        CopyBtn.Position = UDim2.new(1, -68, 0.5, -13)
        CopyBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        CopyBtn.Text = "COPY ID"
        CopyBtn.Font = Enum.Font.GothamBold
        CopyBtn.TextSize = 10
        CopyBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        CopyBtn.Parent = Card
        Instance.new("UICorner", CopyBtn).CornerRadius = UDim.new(0, 6)

        CopyBtn.MouseButton1Click:Connect(function()
            if copyClipboard then
                copyClipboard(assetId)
                CopyBtn.Text = "COPIED ✓"
                task.delay(1.5, function()
                    if CopyBtn and CopyBtn.Parent then
                        CopyBtn.Text = "COPY ID"
                    end
                end)
            end
        end)

        -- Sync Nama Resmi Asli
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

    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y + 10)
end

-- Input Listeners
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
