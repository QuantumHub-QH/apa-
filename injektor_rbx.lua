-- =======================================================
-- STUDIO LITE TOOLBOX FINDER (MOBILE / DELTA EXECUTOR)
-- =======================================================

local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local ParentGui = (gethui and gethui()) or CoreGui or LocalPlayer:WaitForChild("PlayerGui")

-- Cek fungsi executor
local httpRequest = request or http_request or (syn and syn.request) or (http and http.request)
local copyClipboard = setclipboard or toclipboard or (Clipboard and Clipboard.set)

if not httpRequest then
    warn("Executor lu tidak mendukung fungsi HTTP Request!")
    return
end

-- Hapus GUI lama jika dijalankan ulang
if ParentGui:FindFirstChild("StudioLiteToolboxGui") then
    ParentGui.StudioLiteToolboxGui:Destroy()
end

-- ScreenGui Utama
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "StudioLiteToolboxGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = ParentGui

-- 1. FLOATING TOGGLE BUTTON (Buat buka/tutup GUI di HP)
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
ToggleBtn.Position = UDim2.new(0.02, 0, 0.4, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
ToggleBtn.Text = "🔍"
ToggleBtn.TextSize = 22
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0)
ToggleCorner.Parent = ToggleBtn

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = Color3.fromRGB(0, 162, 255)
ToggleStroke.Thickness = 2
ToggleStroke.Parent = ToggleBtn

-- 2. MAIN WINDOW FRAME
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 330, 0, 420)
MainFrame.Position = UDim2.new(0.5, -165, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(50, 50, 60)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

-- Top Bar (Header)
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "StudioLite Toolbox Finder"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextColor3 = Color3.fromRGB(240, 240, 240)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -36, 0, 4)
CloseBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
CloseBtn.Text = "✕"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
CloseBtn.Parent = TopBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

-- Search Input Bar
local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -85, 0, 36)
SearchBox.Position = UDim2.new(0, 10, 0, 50)
SearchBox.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
SearchBox.PlaceholderText = "Cari aset (contoh: car, tree)..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(130, 130, 140)
SearchBox.Text = ""
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 13
SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBox.ClearTextOnFocus = false
SearchBox.Parent = MainFrame
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 8)

local SearchBtn = Instance.new("TextButton")
SearchBtn.Size = UDim2.new(0, 60, 0, 36)
SearchBtn.Position = UDim2.new(1, -70, 0, 50)
SearchBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
SearchBtn.Text = "Cari"
SearchBtn.Font = Enum.Font.GothamBold
SearchBtn.TextSize = 13
SearchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBtn.Parent = MainFrame
Instance.new("UICorner", SearchBtn).CornerRadius = UDim.new(0, 8)

-- Scrolling Results Frame
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -20, 1, -100)
ScrollFrame.Position = UDim2.new(0, 10, 0, 95)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 95)
ScrollFrame.Parent = MainFrame

local UIList = Instance.new("UIListLayout")
UIList.Padding = UDim.new(0, 8)
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Parent = ScrollFrame

-- Status Label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 30)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Ketik sesuatu lalu klik Cari"
StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 13
StatusLabel.Parent = ScrollFrame

-- 3. FUNGSI DRAGGABLE UNTUK LAYAR SENTUH HP
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

-- Toggle Show/Hide
ToggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)
CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

-- 4. FUNGSI PENCARIAN VIA ROBLOX TOOLBOX API
local function searchRobloxAssets(query)
    -- Bersihkan list sebelumnya
    for _, item in ipairs(ScrollFrame:GetChildren()) do
        if item:IsA("Frame") or (item:IsA("TextLabel") and item ~= StatusLabel) then
            item:Destroy()
        end
    end
    StatusLabel.Visible = true
    StatusLabel.Text = "Mencari aset..."

    local encoded = HttpService:UrlEncode(query)
    local url = string.format("https://apis.roblox.com/toolbox-service/v2/assets:search?searchCategoryType=Model&query=%s&maxPageSize=20", encoded)

    local success, response = pcall(function()
        return httpRequest({
            Url = url,
            Method = "GET",
            Headers = {
                ["User-Agent"] = "Roblox/WinInet"
            }
        })
    end)

    if not success or not response or response.StatusCode ~= 200 then
        StatusLabel.Text = "Gagal mengambil data dari server Roblox."
        return
    end

    local decodeSuccess, resData = pcall(function()
        return HttpService:JSONDecode(response.Body)
    end)

    if not decodeSuccess or not resData or not resData.data or #resData.data == 0 then
        StatusLabel.Text = "Tidak ada aset yang ditemukan."
        return
    end

    StatusLabel.Visible = false

    -- Render Kartu Aset
    for _, item in ipairs(resData.data) do
        local asset = item.asset or item
        local assetId = tostring(asset.id or item.id)
        local assetName = asset.name or "Unnamed Model"
        local creatorName = (asset.creator and asset.creator.name) or "Unknown"

        local Card = Instance.new("Frame")
        Card.Size = UDim2.new(1, -6, 0, 65)
        Card.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
        Card.BorderSizePixel = 0
        Card.Parent = ScrollFrame
        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 8)

        -- Thumbnail preview
        local Thumb = Instance.new("ImageLabel")
        Thumb.Size = UDim2.new(0, 50, 0, 50)
        Thumb.Position = UDim2.new(0, 8, 0, 7.5)
        Thumb.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        Thumb.Image = "rbxthumb://type=Asset&id=" .. assetId .. "&w=150&h=150"
        Thumb.Parent = Card
        Instance.new("UICorner", Thumb).CornerRadius = UDim.new(0, 6)

        -- Info Nama & Creator
        local NameLabel = Instance.new("TextLabel")
        NameLabel.Size = UDim2.new(1, -150, 0, 20)
        NameLabel.Position = UDim2.new(0, 66, 0, 10)
        NameLabel.BackgroundTransparency = 1
        NameLabel.Text = assetName
        NameLabel.Font = Enum.Font.GothamBold
        NameLabel.TextSize = 13
        NameLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
        NameLabel.TextXAlignment = Enum.TextXAlignment.Left
        NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        NameLabel.Parent = Card

        local SubLabel = Instance.new("TextLabel")
        SubLabel.Size = UDim2.new(1, -150, 0, 16)
        SubLabel.Position = UDim2.new(0, 66, 0, 32)
        SubLabel.BackgroundTransparency = 1
        SubLabel.Text = "by @" .. creatorName .. " | ID: " .. assetId
        SubLabel.Font = Enum.Font.Gotham
        SubLabel.TextSize = 10
        SubLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
        SubLabel.TextXAlignment = Enum.TextXAlignment.Left
        SubLabel.TextTruncate = Enum.TextTruncate.AtEnd
        SubLabel.Parent = Card

        -- Tombol Copy ID
        local CopyBtn = Instance.new("TextButton")
        CopyBtn.Size = UDim2.new(0, 70, 0, 32)
        CopyBtn.Position = UDim2.new(1, -78, 0.5, -16)
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
            else
                CopyBtn.Text = "Error"
            end
        end)
    end

    -- Update tinggi scroll otomatis
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y + 20)
end

-- Event Klik Cari / Tekan Enter di Keyboard HP
SearchBtn.MouseButton1Click:Connect(function()
    if SearchBox.Text ~= "" then
        searchRobloxAssets(SearchBox.Text)
    end
end)

SearchBox.FocusLost:Connect(function(enterPressed)
    if enterPressed and SearchBox.Text ~= "" then
        searchRobloxAssets(SearchBox.Text)
    end
end)
