-- =======================================================
-- STUDIO LITE TOOLBOX FINDER v2.0 (DELTA MOBILE)
-- Endpoint: Roblox Toolbox Service v1 via RoProxy
-- =======================================================

local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local ParentGui = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

-- Cek fungsi HTTP executor
local httpRequest = request or http_request or (syn and syn.request) or (http and http.request)
local copyClipboard = setclipboard or toclipboard or (Clipboard and Clipboard.set)

if not httpRequest then
    warn("Executor lu tidak mendukung fungsi HTTP request!")
    return
end

-- Bersihkan instance lama jika ada
if ParentGui:FindFirstChild("StudioLiteToolboxGui") then
    ParentGui.StudioLiteToolboxGui:Destroy()
end

-- ScreenGui Utama
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "StudioLiteToolboxGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = ParentGui

-- 1. FLOATING TOGGLE BUTTON (Icon 🔍)
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Size = UDim2.new(0, 48, 0, 48)
ToggleBtn.Position = UDim2.new(0.02, 0, 0.45, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
ToggleBtn.Text = "🔍"
ToggleBtn.TextSize = 22
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner", ToggleBtn)
ToggleCorner.CornerRadius = UDim.new(1, 0)

local ToggleStroke = Instance.new("UIStroke", ToggleBtn)
ToggleStroke.Color = Color3.fromRGB(0, 162, 255)
ToggleStroke.Thickness = 2

-- 2. MAIN WINDOW FRAME
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 340, 0, 430)
MainFrame.Position = UDim2.new(0.5, -170, 0.5, -215)
MainFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner", MainFrame)
MainCorner.CornerRadius = UDim.new(0, 12)

local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Color3.fromRGB(45, 45, 55)
MainStroke.Thickness = 1.5

-- Top Bar (Header)
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "StudioLite Toolbox v2"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextColor3 = Color3.fromRGB(240, 240, 240)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
CloseBtn.Text = "✕"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 13
CloseBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
CloseBtn.Parent = TopBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

-- Tab Kategori (Models, Decals, Audio, Meshes)
local selectedCategory = 10 -- Default: 10 (Models)
local categoryButtons = {}

local CategoryBar = Instance.new("Frame")
CategoryBar.Size = UDim2.new(1, -20, 0, 28)
CategoryBar.Position = UDim2.new(0, 10, 0, 48)
CategoryBar.BackgroundTransparency = 1
CategoryBar.Parent = MainFrame

local CatLayout = Instance.new("UIListLayout")
CatLayout.FillDirection = Enum.FillDirection.Horizontal
CatLayout.Padding = UDim.new(0, 5)
CatLayout.Parent = CategoryBar

local categories = {
    {name = "Models", id = 10},
    {name = "Decals", id = 13},
    {name = "Audio", id = 3},
    {name = "Meshes", id = 11}
}

local function updateCategoryTabs()
    for id, btn in pairs(categoryButtons) do
        if id == selectedCategory then
            btn.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            btn.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
            btn.TextColor3 = Color3.fromRGB(160, 160, 170)
        end
    end
end

for _, cat in ipairs(categories) do
    local cBtn = Instance.new("TextButton")
    cBtn.Size = UDim2.new(0, 72, 1, 0)
    cBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    cBtn.Text = cat.name
    cBtn.Font = Enum.Font.GothamBold
    cBtn.TextSize = 11
    cBtn.TextColor3 = Color3.fromRGB(160, 160, 170)
    cBtn.Parent = CategoryBar
    Instance.new("UICorner", cBtn).CornerRadius = UDim.new(0, 6)

    categoryButtons[cat.id] = cBtn

    cBtn.MouseButton1Click:Connect(function()
        selectedCategory = cat.id
        updateCategoryTabs()
    end)
end
updateCategoryTabs()

-- Search Bar
local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -85, 0, 36)
SearchBox.Position = UDim2.new(0, 10, 0, 84)
SearchBox.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
SearchBox.PlaceholderText = "Cari aset (contoh: car, gun, tree)..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 130)
SearchBox.Text = ""
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 12
SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBox.ClearTextOnFocus = false
SearchBox.Parent = MainFrame
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 8)

local SearchBtn = Instance.new("TextButton")
SearchBtn.Size = UDim2.new(0, 60, 0, 36)
SearchBtn.Position = UDim2.new(1, -70, 0, 84)
SearchBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
SearchBtn.Text = "Cari"
SearchBtn.Font = Enum.Font.GothamBold
SearchBtn.TextSize = 12
SearchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBtn.Parent = MainFrame
Instance.new("UICorner", SearchBtn).CornerRadius = UDim.new(0, 8)

-- Scrolling Results
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -20, 1, -135)
ScrollFrame.Position = UDim2.new(0, 10, 0, 128)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(70, 70, 85)
ScrollFrame.Parent = MainFrame

local UIList = Instance.new("UIListLayout")
UIList.Padding = UDim.new(0, 8)
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Parent = ScrollFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 35)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Pilih kategori & klik Cari"
StatusLabel.TextColor3 = Color3.fromRGB(140, 140, 150)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 12
StatusLabel.Parent = ScrollFrame

-- 3. TOUCH DRAG SUPPORT (HP)
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

-- 4. LOGIC QUERY DENGAN MULTI-ENDPOINT FALLBACK
local function queryMarketplace(category, query)
    local encodedQuery = HttpService:UrlEncode(query)
    
    -- Daftar endpoint yang dicoba secara berurutan
    local endpoints = {
        string.format("https://apis.roproxy.com/toolbox-service/v1/marketplace/%d?keyword=%s&limit=25", category, encodedQuery),
        string.format("https://apis.roblox.com/toolbox-service/v1/marketplace/%d?keyword=%s&limit=25", category, encodedQuery)
    }

    for _, url in ipairs(endpoints) do
        local success, res = pcall(function()
            return httpRequest({
                Url = url,
                Method = "GET",
                Headers = {
                    ["User-Agent"] = "RobloxStudio/WinInet"
                }
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

-- 5. RENDER HASIL PENCARIAN
local function searchAssets(query)
    -- Bersihkan kartu lama
    for _, item in ipairs(ScrollFrame:GetChildren()) do
        if item:IsA("Frame") then
            item:Destroy()
        end
    end

    StatusLabel.Visible = true
    StatusLabel.Text = "Menghubungi server Toolbox..."

    local data = queryMarketplace(selectedCategory, query)

    if not data or #data == 0 then
        StatusLabel.Text = "Aset tidak ditemukan. Coba kata kunci lain."
        return
    end

    StatusLabel.Visible = false

    for _, item in ipairs(data) do
        -- Ekstrak data (mendukung struktur v1 maupun v2)
        local assetId = tostring(item.id or (item.asset and item.asset.id) or "0")
        local assetName = item.name or (item.asset and item.asset.name) or "Tanpa Nama"
        local creatorName = (item.creator and item.creator.name) or (item.asset and item.asset.creator and item.asset.creator.name) or "Unknown"

        local Card = Instance.new("Frame")
        Card.Size = UDim2.new(1, -6, 0, 62)
        Card.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
        Card.BorderSizePixel = 0
        Card.Parent = ScrollFrame
        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 8)

        -- Thumbnail
        local Thumb = Instance.new("ImageLabel")
        Thumb.Size = UDim2.new(0, 48, 0, 48)
        Thumb.Position = UDim2.new(0, 7, 0, 7)
        Thumb.BackgroundColor3 = Color3.fromRGB(42, 42, 50)
        Thumb.Image = "rbxthumb://type=Asset&id=" .. assetId .. "&w=150&h=150"
        Thumb.Parent = Card
        Instance.new("UICorner", Thumb).CornerRadius = UDim.new(0, 6)

        -- Info Nama & Creator
        local NameLabel = Instance.new("TextLabel")
        NameLabel.Size = UDim2.new(1, -150, 0, 18)
        NameLabel.Position = UDim2.new(0, 62, 0, 10)
        NameLabel.BackgroundTransparency = 1
        NameLabel.Text = assetName
        NameLabel.Font = Enum.Font.GothamBold
        NameLabel.TextSize = 12
        NameLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
        NameLabel.TextXAlignment = Enum.TextXAlignment.Left
        NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        NameLabel.Parent = Card

        local SubLabel = Instance.new("TextLabel")
        SubLabel.Size = UDim2.new(1, -150, 0, 15)
        SubLabel.Position = UDim2.new(0, 62, 0, 31)
        SubLabel.BackgroundTransparency = 1
        SubLabel.Text = "@" .. creatorName .. " | ID: " .. assetId
        SubLabel.Font = Enum.Font.Gotham
        SubLabel.TextSize = 10
        SubLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
        SubLabel.TextXAlignment = Enum.TextXAlignment.Left
        SubLabel.TextTruncate = Enum.TextTruncate.AtEnd
        SubLabel.Parent = Card

        -- Tombol Copy ID
        local CopyBtn = Instance.new("TextButton")
        CopyBtn.Size = UDim2.new(0, 68, 0, 30)
        CopyBtn.Position = UDim2.new(1, -76, 0.5, -15)
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
    end

    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y + 20)
end

-- Listener Pencarian
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
