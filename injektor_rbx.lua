-- =======================================================
-- BLUExCrown ENGINE v4.1 - FIXED EDITION
-- MENU: Splash | TOOLBOX ASSET | INSERT RBXM
-- Fix: syntax error + nil function guards
-- Toggle Asset ID: 102337382069600
-- =======================================================

local HttpService        = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local CoreGui            = game:GetService("CoreGui")
local Players            = game:GetService("Players")

local LP = Players.LocalPlayer
local ParentGui = (gethui and gethui()) or CoreGui or LP:WaitForChild("PlayerGui")

local httpRequest  = request or http_request or (syn and syn.request) or (http and http.request)
local clipFn       = setclipboard or toclipboard or (Clipboard and Clipboard.set)
local customAsset  = getcustomasset or getsynasset or nil
local listfilesFn  = listfiles or nil

if not httpRequest then
    warn("[BLUExCrown] Executor tidak support HTTP!")
    return
end

-- Bersihkan GUI lama
if ParentGui:FindFirstChild("BLUExCrownV4") then
    ParentGui.BLUExCrownV4:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BLUExCrownV4"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = ParentGui

-- ===================== HELPERS =====================
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

local tweenQuick  = TweenInfo.new(0.18, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local tweenBounce = TweenInfo.new(0.22, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)

-- ===================== TOGGLE BUTTON =====================
local ToggleBtn = Instance.new("ImageButton")
ToggleBtn.Size = UDim2.new(0, 42, 0, 42)
ToggleBtn.Position = UDim2.new(0.02, 0, 0.45, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(14, 14, 16)
ToggleBtn.Image = "rbxassetid://102337382069600"
ToggleBtn.ScaleType = Enum.ScaleType.Fit
ToggleBtn.Parent = ScreenGui
makeCorner(ToggleBtn, 8)
makeStroke(ToggleBtn, Color3.fromRGB(255,255,255), 1.4)

-- ===================== MAIN WINDOW =====================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.fromScale(0.5, 0.5)
MainFrame.Size = UDim2.new(0, 640, 0, 360)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
makeCorner(MainFrame, 10)
makeStroke(MainFrame, Color3.fromRGB(255,255,255), 1.4)

-- TOP BAR
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, -12, 0, 30)
TopBar.Position = UDim2.new(0, 6, 0, 6)
TopBar.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame
makeCorner(TopBar, 7)
makeStroke(TopBar, Color3.fromRGB(255,255,255), 1, 0.75)

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size = UDim2.new(1, -50, 1, 0)
TitleLbl.Position = UDim2.new(0, 12, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text = "BLUExCrown ENGINE v4.1"
TitleLbl.Font = Enum.Font.GothamBold
TitleLbl.TextSize = 11
TitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TitleLbl.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 22, 0, 22)
CloseBtn.Position = UDim2.new(1, -26, 0, 4)
CloseBtn.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 10
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Parent = TopBar
makeCorner(CloseBtn, 6)
makeStroke(CloseBtn, Color3.fromRGB(255,255,255), 1, 0.55)

-- CONTENT AREA
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -12, 1, -46)
Content.Position = UDim2.new(0, 6, 0, 40)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

-- =====================================================
-- PAGE CONTAINER
-- =====================================================
local PageSplash  = Instance.new("Frame")
local PageToolbox = Instance.new("Frame")
local PageRBXM    = Instance.new("Frame")

for _, pg in ipairs({PageSplash, PageToolbox, PageRBXM}) do
    pg.Size = UDim2.fromScale(1, 1)
    pg.BackgroundTransparency = 1
    pg.Visible = false
    pg.Parent = Content
end
PageSplash.Visible = true

-- =====================================================
-- PAGE 1: SPLASH SCREEN (HOME)
-- =====================================================

-- KIRI: Profil Player
local ProfileCard = Instance.new("Frame")
ProfileCard.Size = UDim2.new(0, 175, 1, 0)
ProfileCard.BackgroundColor3 = Color3.fromRGB(17, 17, 22)
ProfileCard.BorderSizePixel = 0
ProfileCard.Parent = PageSplash
makeCorner(ProfileCard, 8)
makeStroke(ProfileCard, Color3.fromRGB(255,255,255), 1, 0.75)

local AvatarImg = Instance.new("ImageLabel")
AvatarImg.Size = UDim2.new(0, 70, 0, 70)
AvatarImg.AnchorPoint = Vector2.new(0.5, 0)
AvatarImg.Position = UDim2.new(0.5, 0, 0, 14)
AvatarImg.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
AvatarImg.Image = ""
AvatarImg.Parent = ProfileCard
makeCorner(AvatarImg, 35)
makeStroke(AvatarImg, Color3.fromRGB(255,255,255), 1.5, 0.5)

local DispName = Instance.new("TextLabel")
DispName.Size = UDim2.new(1, -16, 0, 20)
DispName.Position = UDim2.new(0, 8, 0, 90)
DispName.BackgroundTransparency = 1
DispName.Text = "Loading..."
DispName.Font = Enum.Font.GothamBold
DispName.TextSize = 13
DispName.TextColor3 = Color3.fromRGB(255, 255, 255)
DispName.TextXAlignment = Enum.TextXAlignment.Center
DispName.TextTruncate = Enum.TextTruncate.AtEnd
DispName.Parent = ProfileCard

local UsernLabel = Instance.new("TextLabel")
UsernLabel.Size = UDim2.new(1, -16, 0, 16)
UsernLabel.Position = UDim2.new(0, 8, 0, 112)
UsernLabel.BackgroundTransparency = 1
UsernLabel.Text = "@..."
UsernLabel.Font = Enum.Font.Gotham
UsernLabel.TextSize = 10
UsernLabel.TextColor3 = Color3.fromRGB(160, 160, 170)
UsernLabel.TextXAlignment = Enum.TextXAlignment.Center
UsernLabel.Parent = ProfileCard

local SepLine = Instance.new("Frame")
SepLine.Size = UDim2.new(1, -20, 0, 1)
SepLine.Position = UDim2.new(0, 10, 0, 136)
SepLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SepLine.BackgroundTransparency = 0.85
SepLine.BorderSizePixel = 0
SepLine.Parent = ProfileCard

local StatsLbl = Instance.new("TextLabel")
StatsLbl.Size = UDim2.new(1, -16, 1, -148)
StatsLbl.Position = UDim2.new(0, 8, 0, 144)
StatsLbl.BackgroundTransparency = 1
StatsLbl.Text = "UserID: "..tostring(LP.UserId).."\nBLUExCrown ENGINE\nv4.1 — Delta Mobile"
StatsLbl.Font = Enum.Font.Gotham
StatsLbl.TextSize = 9
StatsLbl.TextColor3 = Color3.fromRGB(130, 130, 140)
StatsLbl.TextXAlignment = Enum.TextXAlignment.Center
StatsLbl.TextWrapped = true
StatsLbl.Parent = ProfileCard

-- KANAN: Menu Area
local MenuArea = Instance.new("Frame")
MenuArea.Size = UDim2.new(1, -183, 1, 0)
MenuArea.Position = UDim2.new(0, 183, 0, 0)
MenuArea.BackgroundTransparency = 1
MenuArea.Parent = PageSplash

local MenuTitle = Instance.new("TextLabel")
MenuTitle.Size = UDim2.new(1, 0, 0, 24)
MenuTitle.BackgroundTransparency = 1
MenuTitle.Text = "PILIH MENU"
MenuTitle.Font = Enum.Font.GothamBold
MenuTitle.TextSize = 10
MenuTitle.TextColor3 = Color3.fromRGB(180, 180, 190)
MenuTitle.TextXAlignment = Enum.TextXAlignment.Left
MenuTitle.Parent = MenuArea

local function makeMenuCard(parent, posY, icon, title, subtitle)
    local card = Instance.new("TextButton")
    card.Size = UDim2.new(1, 0, 0, 72)
    card.Position = UDim2.new(0, 0, 0, posY)
    card.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    card.Text = ""
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
    subL.Parent = card

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 20, 0, 20)
    arrow.Position = UDim2.new(1, -28, 0.5, -10)
    arrow.BackgroundTransparency = 1
    arrow.Text = ">"
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 18
    arrow.TextColor3 = Color3.fromRGB(200, 200, 210)
    arrow.Parent = card

    card.MouseEnter:Connect(function()
        TweenService:Create(card, tweenQuick, {BackgroundColor3 = Color3.fromRGB(28,28,34)}):Play()
    end)
    card.MouseLeave:Connect(function()
        TweenService:Create(card, tweenQuick, {BackgroundColor3 = Color3.fromRGB(20,20,25)}):Play()
    end)

    return card
end

local CardToolbox = makeMenuCard(MenuArea, 28,  "[T]", "TOOLBOX ASET",     "Cari & insert model dari Roblox Creator Store")
local CardRBXM    = makeMenuCard(MenuArea, 108, "[R]", "INSERT RBXM FILE", "Scan file .rbxm dari folder workspace Delta")

-- =====================================================
-- HELPER: Back Button
-- =====================================================
local function makeBackBtn(parent)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 64, 0, 22)
    b.Position = UDim2.new(1, -68, 0, 0)
    b.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    b.Text = "< BACK"
    b.Font = Enum.Font.GothamBold
    b.TextSize = 9
    b.TextColor3 = Color3.fromRGB(0, 0, 0)
    b.Parent = parent
    makeCorner(b, 5)
    return b
end

-- =====================================================
-- PAGE 2: TOOLBOX ASSET
-- =====================================================
local TbHeader = Instance.new("Frame")
TbHeader.Size = UDim2.new(1, 0, 0, 28)
TbHeader.BackgroundTransparency = 1
TbHeader.Parent = PageToolbox

local TbTitleLbl = Instance.new("TextLabel")
TbTitleLbl.Size = UDim2.new(1, -80, 1, 0)
TbTitleLbl.BackgroundTransparency = 1
TbTitleLbl.Text = "TOOLBOX ASET"
TbTitleLbl.Font = Enum.Font.GothamBold
TbTitleLbl.TextSize = 11
TbTitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
TbTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TbTitleLbl.Parent = TbHeader

local TbBack = makeBackBtn(TbHeader)

local TbContent = Instance.new("Frame")
TbContent.Size = UDim2.new(1, 0, 1, -34)
TbContent.Position = UDim2.new(0, 0, 0, 34)
TbContent.BackgroundTransparency = 1
TbContent.Parent = PageToolbox

-- LEFT PANEL
local TbLeft = Instance.new("Frame")
TbLeft.Size = UDim2.new(0, 220, 1, 0)
TbLeft.BackgroundTransparency = 1
TbLeft.Parent = TbContent

-- Search Section
local TbSearchSec = Instance.new("Frame")
TbSearchSec.Size = UDim2.new(1, 0, 0, 118)
TbSearchSec.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
TbSearchSec.Parent = TbLeft
makeCorner(TbSearchSec, 8)
makeStroke(TbSearchSec, Color3.fromRGB(255,255,255), 1, 0.78)

-- Asset ID input
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
TbInsertIdBtn.Parent = TbSearchSec
makeCorner(TbInsertIdBtn, 5)

-- Keyword search
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
TbSearchBtn.Parent = TbSearchSec
makeCorner(TbSearchBtn, 5)

-- Category Pills
local selectedCat = 10
local catBtns = {}
local cats = {
    {n="MODEL", id=10},
    {n="DECAL", id=13},
    {n="AUDIO", id=3},
    {n="MESH",  id=11}
}

local TbCatRow = Instance.new("Frame")
TbCatRow.Size = UDim2.new(1, -12, 0, 20)
TbCatRow.Position = UDim2.new(0, 6, 0, 65)
TbCatRow.BackgroundTransparency = 1
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
    cb.Text = c.n
    cb.Font = Enum.Font.GothamBold
    cb.TextSize = 8
    cb.TextColor3 = Color3.fromRGB(160, 160, 170)
    cb.Parent = TbCatRow
    makeCorner(cb, 4)
    makeStroke(cb, Color3.fromRGB(255,255,255), 1, 0.82)
    catBtns[c.id] = cb
    cb.MouseButton1Click:Connect(function()
        selectedCat = c.id
        updateCatTabs()
    end)
end
updateCatTabs()

local TbStatusLbl = Instance.new("TextLabel")
TbStatusLbl.Size = UDim2.new(1, -12, 0, 16)
TbStatusLbl.Position = UDim2.new(0, 6, 0, 90)
TbStatusLbl.BackgroundTransparency = 1
TbStatusLbl.Text = "[.] Siap"
TbStatusLbl.Font = Enum.Font.Gotham
TbStatusLbl.TextSize = 9
TbStatusLbl.TextColor3 = Color3.fromRGB(140, 140, 150)
TbStatusLbl.TextXAlignment = Enum.TextXAlignment.Left
TbStatusLbl.Parent = TbSearchSec

-- Detail Box
local TbDetailBox = Instance.new("Frame")
TbDetailBox.Size = UDim2.new(1, 0, 1, -124)
TbDetailBox.Position = UDim2.new(0, 0, 0, 124)
TbDetailBox.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
TbDetailBox.Parent = TbLeft
makeCorner(TbDetailBox, 8)
makeStroke(TbDetailBox, Color3.fromRGB(255,255,255), 1, 0.78)

local TbDetTitleLbl = Instance.new("TextLabel")
TbDetTitleLbl.Size = UDim2.new(1, -12, 0, 18)
TbDetTitleLbl.Position = UDim2.new(0, 8, 0, 4)
TbDetTitleLbl.BackgroundTransparency = 1
TbDetTitleLbl.Text = "DETAIL ASSET"
TbDetTitleLbl.Font = Enum.Font.GothamBold
TbDetTitleLbl.TextSize = 9
TbDetTitleLbl.TextColor3 = Color3.fromRGB(200, 200, 210)
TbDetTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TbDetTitleLbl.Parent = TbDetailBox

local TbDetThumb = Instance.new("ImageLabel")
TbDetThumb.Size = UDim2.new(0, 52, 0, 52)
TbDetThumb.Position = UDim2.new(0, 8, 0, 24)
TbDetThumb.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
TbDetThumb.Image = ""
TbDetThumb.Parent = TbDetailBox
makeCorner(TbDetThumb, 6)
makeStroke(TbDetThumb, Color3.fromRGB(255,255,255), 1, 0.82)

local TbDetName = Instance.new("TextLabel")
TbDetName.Size = UDim2.new(1, -70, 0, 26)
TbDetName.Position = UDim2.new(0, 66, 0, 22)
TbDetName.BackgroundTransparency = 1
TbDetName.Text = "Pilih aset dari grid"
TbDetName.Font = Enum.Font.GothamBold
TbDetName.TextSize = 10
TbDetName.TextColor3 = Color3.fromRGB(255, 255, 255)
TbDetName.TextXAlignment = Enum.TextXAlignment.Left
TbDetName.TextWrapped = true
TbDetName.Parent = TbDetailBox

local TbDetCreator = Instance.new("TextLabel")
TbDetCreator.Size = UDim2.new(1, -70, 0, 14)
TbDetCreator.Position = UDim2.new(0, 66, 0, 46)
TbDetCreator.BackgroundTransparency = 1
TbDetCreator.Text = "By: -"
TbDetCreator.Font = Enum.Font.Gotham
TbDetCreator.TextSize = 8
TbDetCreator.TextColor3 = Color3.fromRGB(150, 150, 160)
TbDetCreator.TextXAlignment = Enum.TextXAlignment.Left
TbDetCreator.Parent = TbDetailBox

local TbDetId = Instance.new("TextLabel")
TbDetId.Size = UDim2.new(1, -70, 0, 14)
TbDetId.Position = UDim2.new(0, 66, 0, 60)
TbDetId.BackgroundTransparency = 1
TbDetId.Text = "ID: -"
TbDetId.Font = Enum.Font.Gotham
TbDetId.TextSize = 8
TbDetId.TextColor3 = Color3.fromRGB(150, 150, 160)
TbDetId.TextXAlignment = Enum.TextXAlignment.Left
TbDetId.Parent = TbDetailBox

local currentInspId = ""

local TbDetRow = Instance.new("Frame")
TbDetRow.Size = UDim2.new(1, -16, 0, 26)
TbDetRow.Position = UDim2.new(0, 8, 1, -32)
TbDetRow.BackgroundTransparency = 1
TbDetRow.Parent = TbDetailBox

local TbDetInsert = Instance.new("TextButton")
TbDetInsert.Size = UDim2.new(0.5, -3, 1, 0)
TbDetInsert.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TbDetInsert.Text = "INSERT"
TbDetInsert.Font = Enum.Font.GothamBold
TbDetInsert.TextSize = 9
TbDetInsert.TextColor3 = Color3.fromRGB(0, 0, 0)
TbDetInsert.Parent = TbDetRow
makeCorner(TbDetInsert, 5)

local TbDetCopy = Instance.new("TextButton")
TbDetCopy.Size = UDim2.new(0.5, -3, 1, 0)
TbDetCopy.Position = UDim2.new(0.5, 3, 0, 0)
TbDetCopy.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TbDetCopy.Text = "COPY ID"
TbDetCopy.Font = Enum.Font.GothamBold
TbDetCopy.TextSize = 9
TbDetCopy.TextColor3 = Color3.fromRGB(0, 0, 0)
TbDetCopy.Parent = TbDetRow
makeCorner(TbDetCopy, 5)

-- RIGHT PANEL: Grid Browser
local TbRight = Instance.new("Frame")
TbRight.Size = UDim2.new(1, -228, 1, 0)
TbRight.Position = UDim2.new(0, 228, 0, 0)
TbRight.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
TbRight.Parent = TbContent
makeCorner(TbRight, 8)
makeStroke(TbRight, Color3.fromRGB(255,255,255), 1, 0.78)

local TbBrowserLbl = Instance.new("TextLabel")
TbBrowserLbl.Size = UDim2.new(1, -16, 0, 24)
TbBrowserLbl.Position = UDim2.new(0, 8, 0, 4)
TbBrowserLbl.BackgroundTransparency = 1
TbBrowserLbl.Text = "ASSET BROWSER"
TbBrowserLbl.Font = Enum.Font.GothamBold
TbBrowserLbl.TextSize = 10
TbBrowserLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
TbBrowserLbl.TextXAlignment = Enum.TextXAlignment.Left
TbBrowserLbl.Parent = TbRight

local TbGridScroll = Instance.new("ScrollingFrame")
TbGridScroll.Size = UDim2.new(1, -12, 1, -34)
TbGridScroll.Position = UDim2.new(0, 6, 0, 28)
TbGridScroll.BackgroundTransparency = 1
TbGridScroll.ScrollBarThickness = 3
TbGridScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
TbGridScroll.Parent = TbRight

local TbGrid = Instance.new("UIGridLayout")
TbGrid.CellSize = UDim2.new(0, 104, 0, 115)
TbGrid.CellPadding = UDim2.new(0, 6, 0, 6)
TbGrid.SortOrder = Enum.SortOrder.LayoutOrder
TbGrid.Parent = TbGridScroll

local TbGridStatus = Instance.new("TextLabel")
TbGridStatus.Size = UDim2.new(1, 0, 0, 40)
TbGridStatus.BackgroundTransparency = 1
TbGridStatus.Text = "Ketik kata kunci & klik CARI"
TbGridStatus.Font = Enum.Font.Gotham
TbGridStatus.TextSize = 10
TbGridStatus.TextColor3 = Color3.fromRGB(140, 140, 150)
TbGridStatus.Parent = TbGridScroll

-- =====================================================
-- PAGE 3: INSERT RBXM FILE
-- =====================================================
local RbxmHeader = Instance.new("Frame")
RbxmHeader.Size = UDim2.new(1, 0, 0, 28)
RbxmHeader.BackgroundTransparency = 1
RbxmHeader.Parent = PageRBXM

local RbxmTitleLbl = Instance.new("TextLabel")
RbxmTitleLbl.Size = UDim2.new(1, -80, 1, 0)
RbxmTitleLbl.BackgroundTransparency = 1
RbxmTitleLbl.Text = "INSERT RBXM FILE"
RbxmTitleLbl.Font = Enum.Font.GothamBold
RbxmTitleLbl.TextSize = 11
RbxmTitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
RbxmTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
RbxmTitleLbl.Parent = RbxmHeader

local RbxmBack = makeBackBtn(RbxmHeader)

local RbxmToolbar = Instance.new("Frame")
RbxmToolbar.Size = UDim2.new(1, 0, 0, 28)
RbxmToolbar.Position = UDim2.new(0, 0, 0, 32)
RbxmToolbar.BackgroundTransparency = 1
RbxmToolbar.Parent = PageRBXM

local RbxmScanBtn = Instance.new("TextButton")
RbxmScanBtn.Size = UDim2.new(0, 90, 0, 24)
RbxmScanBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
RbxmScanBtn.Text = "SCAN FILES"
RbxmScanBtn.Font = Enum.Font.GothamBold
RbxmScanBtn.TextSize = 10
RbxmScanBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
RbxmScanBtn.Parent = RbxmToolbar
makeCorner(RbxmScanBtn, 6)

local RbxmCountLbl = Instance.new("TextLabel")
RbxmCountLbl.Size = UDim2.new(1, -100, 1, 0)
RbxmCountLbl.Position = UDim2.new(0, 96, 0, 0)
RbxmCountLbl.BackgroundTransparency = 1
RbxmCountLbl.Text = "[.] Klik SCAN untuk mencari file .rbxm di workspace Delta"
RbxmCountLbl.Font = Enum.Font.Gotham
RbxmCountLbl.TextSize = 9
RbxmCountLbl.TextColor3 = Color3.fromRGB(140, 140, 150)
RbxmCountLbl.TextXAlignment = Enum.TextXAlignment.Left
RbxmCountLbl.Parent = RbxmToolbar

local RbxmScroll = Instance.new("ScrollingFrame")
RbxmScroll.Size = UDim2.new(1, 0, 1, -66)
RbxmScroll.Position = UDim2.new(0, 0, 0, 62)
RbxmScroll.BackgroundColor3 = Color3.fromRGB(17, 17, 22)
RbxmScroll.BorderSizePixel = 0
RbxmScroll.ScrollBarThickness = 3
RbxmScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
RbxmScroll.Parent = PageRBXM
makeCorner(RbxmScroll, 8)
makeStroke(RbxmScroll, Color3.fromRGB(255,255,255), 1, 0.78)

local RbxmList = Instance.new("UIListLayout")
RbxmList.Padding = UDim.new(0, 5)
RbxmList.SortOrder = Enum.SortOrder.LayoutOrder
RbxmList.Parent = RbxmScroll

local RbxmPad = Instance.new("UIPadding")
RbxmPad.PaddingTop = UDim.new(0, 6)
RbxmPad.PaddingLeft = UDim.new(0, 6)
RbxmPad.PaddingRight = UDim.new(0, 6)
RbxmPad.Parent = RbxmScroll

local RbxmEmpty = Instance.new("TextLabel")
RbxmEmpty.Size = UDim2.new(1, 0, 0, 40)
RbxmEmpty.BackgroundTransparency = 1
RbxmEmpty.Text = "Belum ada file .rbxm ditemukan. Klik SCAN FILES."
RbxmEmpty.Font = Enum.Font.Gotham
RbxmEmpty.TextSize = 10
RbxmEmpty.TextColor3 = Color3.fromRGB(140, 140, 150)
RbxmEmpty.Parent = RbxmScroll

-- =====================================================
-- LOGIC: DRAGGABLE
-- =====================================================
local function makeDraggable(frame, handle)
    local dragging = false
    local dragStart = nil
    local startPos = nil

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
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
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            local d = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
end

makeDraggable(MainFrame, TopBar)
makeDraggable(ToggleBtn, ToggleBtn)

-- =====================================================
-- LOGIC: TOGGLE WINDOW
-- =====================================================
local isOpen = true
local function toggleWindow()
    isOpen = not isOpen
    if isOpen then
        MainFrame.Visible = true
        MainFrame.Size = UDim2.new(0, 618, 0, 348)
        TweenService:Create(MainFrame, tweenBounce, {Size = UDim2.new(0, 640, 0, 360)}):Play()
    else
        local tw = TweenService:Create(MainFrame, tweenQuick, {Size = UDim2.new(0, 610, 0, 340)})
        tw:Play()
        tw.Completed:Connect(function()
            if not isOpen then
                MainFrame.Visible = false
            end
        end)
    end
end

ToggleBtn.MouseButton1Click:Connect(toggleWindow)
CloseBtn.MouseButton1Click:Connect(toggleWindow)

-- =====================================================
-- LOGIC: PAGE NAVIGATION
-- =====================================================
local function showPage(target)
    PageSplash.Visible  = false
    PageToolbox.Visible = false
    PageRBXM.Visible    = false
    target.Visible = true
end

CardToolbox.MouseButton1Click:Connect(function() showPage(PageToolbox) end)
CardRBXM.MouseButton1Click:Connect(function()    showPage(PageRBXM)    end)
TbBack.MouseButton1Click:Connect(function()      showPage(PageSplash)  end)
RbxmBack.MouseButton1Click:Connect(function()    showPage(PageSplash)  end)

-- =====================================================
-- LOGIC: SMART INSERT (ASSET ID)
-- =====================================================
local function smartInsert(assetId)
    local numId = tonumber(assetId)
    if not numId then
        return false, "ID tidak valid"
    end

    -- Always copy to clipboard as guaranteed fallback
    if clipFn then
        pcall(clipFn, tostring(numId))
    end

    local insertOk = false
    local method = ""

    -- METHOD 1: Cari & trigger UI bawaan Studio Lite
    pcall(function()
        for _, gui in ipairs(LP.PlayerGui:GetDescendants()) do
            if gui:IsA("TextBox") and not gui:IsDescendantOf(ScreenGui) then
                local ph = gui.PlaceholderText:lower()
                local nm = gui.Name:lower()
                if string.find(nm,"id") or string.find(nm,"asset")
                or string.find(ph,"id") or string.find(ph,"asset") then
                    gui.Text = tostring(numId)
                    local container = gui.Parent
                    if container then
                        for _, btn in ipairs(container:GetDescendants()) do
                            if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn ~= gui then
                                local bt = ""
                                if btn:IsA("TextButton") then
                                    bt = btn.Text:lower()
                                end
                                local bn = btn.Name:lower()
                                if string.find(bt,"get") or string.find(bt,"insert")
                                or string.find(bn,"get") or string.find(bn,"insert")
                                or string.find(bn,"load") then
                                    -- Fire button safely
                                    if firesignal then
                                        pcall(firesignal, btn.MouseButton1Click)
                                    elseif getconnections then
                                        pcall(function()
                                            for _, c in ipairs(getconnections(btn.MouseButton1Click)) do
                                                pcall(c.Function, c)
                                            end
                                        end)
                                    else
                                        btn:Activate()
                                    end
                                    insertOk = true
                                    method = "Native Studio Lite UI"
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    -- METHOD 2: RemoteEvent hunter
    if not insertOk then
        pcall(function()
            local repStorage = game:GetService("ReplicatedStorage")
            for _, rem in ipairs(repStorage:GetDescendants()) do
                if rem:IsA("RemoteEvent") or rem:IsA("RemoteFunction") then
                    local rn = rem.Name:lower()
                    if string.find(rn,"insert") or string.find(rn,"asset")
                    or string.find(rn,"toolbox") or string.find(rn,"load") then
                        if rem:IsA("RemoteEvent") then
                            rem:FireServer(numId)
                        else
                            rem:InvokeServer(numId)
                        end
                        insertOk = true
                        method = "Remote: "..rem.Name
                    end
                end
            end
        end)
    end

    -- METHOD 3: GetObjects executor bypass
    if not insertOk then
        pcall(function()
            local objs = game:GetObjects("rbxassetid://"..tostring(numId))
            if objs and #objs > 0 then
                for _, o in ipairs(objs) do
                    o.Parent = workspace
                    if o:IsA("Model") and LP.Character then
                        local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            o:MoveTo(hrp.Position + hrp.CFrame.LookVector * 7)
                        end
                    end
                end
                insertOk = true
                method = "GetObjects Spawn"
            end
        end)
    end

    return insertOk, (method ~= "" and method or "ID Disalin ke Clipboard")
end

-- =====================================================
-- LOGIC: SMART INSERT RBXM FILE
-- =====================================================
local function smartInsertRbxm(filePath, fileName)
    local insertOk = false

    -- Method 1: getcustomasset / getsynasset + GetObjects
    if customAsset then
        pcall(function()
            local url = customAsset(filePath)
            local objs = game:GetObjects(url)
            if objs and #objs > 0 then
                for _, o in ipairs(objs) do
                    o.Parent = workspace
                    if o:IsA("Model") and LP.Character then
                        local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            o:MoveTo(hrp.Position + hrp.CFrame.LookVector * 7)
                        end
                    end
                end
                insertOk = true
            end
        end)
    end

    -- Method 2: readfile + writefile tmp + getcustomasset
    if not insertOk and readfile and writefile and customAsset then
        pcall(function()
            local raw = readfile(filePath)
            if raw and #raw > 0 then
                local tmpName = "bluexcrown_tmp_"..fileName
                writefile(tmpName, raw)
                local url2 = customAsset(tmpName)
                local objs2 = game:GetObjects(url2)
                if objs2 and #objs2 > 0 then
                    for _, o in ipairs(objs2) do
                        o.Parent = workspace
                    end
                    insertOk = true
                end
            end
        end)
    end

    -- Method 3: Extract AssetId dari XML header rbxm lalu insert via ID
    if not insertOk and readfile then
        pcall(function()
            local raw = readfile(filePath)
            if raw then
                local extractedId = raw:match('AssetId="(%d+)"')
                    or raw:match('<int name="AssetId">(%d+)')
                    or raw:match('assetid="(%d+)"')
                if extractedId then
                    local ok2, _ = smartInsert(extractedId)
                    if ok2 then
                        insertOk = true
                    end
                end
            end
        end)
    end

    return insertOk
end

-- =====================================================
-- LOGIC: SCAN RBXM FILES
-- =====================================================
local function getAllRbxmFiles()
    local result = {}
    if not listfilesFn then
        return result
    end
    local folders = {"", "workspace", "Workspace", "models", "Models", "rbxm", "assets"}
    for _, folder in ipairs(folders) do
        pcall(function()
            local files = listfilesFn(folder)
            if files then
                for _, path in ipairs(files) do
                    local lp = path:lower()
                    if lp:sub(-5) == ".rbxm" or lp:sub(-6) == ".rbxmx" then
                        local fileName = path:match("([^/\\]+)$") or path
                        table.insert(result, {path = path, name = fileName})
                    end
                end
            end
        end)
    end
    return result
end

local function renderRbxmCards()
    for _, c in ipairs(RbxmScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    RbxmCountLbl.Text = "[.] Scanning..."

    local files = getAllRbxmFiles()
    RbxmEmpty.Visible = (#files == 0)

    if #files == 0 then
        if not listfilesFn then
            RbxmCountLbl.Text = "[!] Executor ini tidak support listfiles(). Taruh .rbxm di workspace Delta."
        else
            RbxmCountLbl.Text = "[!] Tidak ada file .rbxm di workspace"
        end
        return
    end

    RbxmCountLbl.Text = string.format("[OK] %d file ditemukan", #files)

    for _, file in ipairs(files) do
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -12, 0, 46)
        card.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        card.BorderSizePixel = 0
        card.Parent = RbxmScroll
        makeCorner(card, 7)
        makeStroke(card, Color3.fromRGB(255,255,255), 1, 0.85)

        local fileIcon = Instance.new("TextLabel")
        fileIcon.Size = UDim2.new(0, 36, 0, 36)
        fileIcon.Position = UDim2.new(0, 5, 0, 5)
        fileIcon.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
        fileIcon.Text = ".rbxm"
        fileIcon.Font = Enum.Font.GothamBold
        fileIcon.TextSize = 7
        fileIcon.TextColor3 = Color3.fromRGB(200, 200, 210)
        fileIcon.Parent = card
        makeCorner(fileIcon, 6)

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(1, -135, 0, 16)
        nameLbl.Position = UDim2.new(0, 48, 0, 6)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = file.name
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextSize = 11
        nameLbl.TextColor3 = Color3.fromRGB(240, 240, 245)
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        nameLbl.Parent = card

        local pathLbl = Instance.new("TextLabel")
        pathLbl.Size = UDim2.new(1, -135, 0, 13)
        pathLbl.Position = UDim2.new(0, 48, 0, 25)
        pathLbl.BackgroundTransparency = 1
        pathLbl.Text = file.path
        pathLbl.Font = Enum.Font.Gotham
        pathLbl.TextSize = 8
        pathLbl.TextColor3 = Color3.fromRGB(130, 130, 140)
        pathLbl.TextXAlignment = Enum.TextXAlignment.Left
        pathLbl.TextTruncate = Enum.TextTruncate.AtEnd
        pathLbl.Parent = card

        local insertBtn = Instance.new("TextButton")
        insertBtn.Size = UDim2.new(0, 62, 0, 28)
        insertBtn.Position = UDim2.new(1, -68, 0.5, -14)
        insertBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        insertBtn.Text = "INSERT"
        insertBtn.Font = Enum.Font.GothamBold
        insertBtn.TextSize = 9
        insertBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        insertBtn.Parent = card
        makeCorner(insertBtn, 6)

        insertBtn.MouseButton1Click:Connect(function()
            insertBtn.Text = "..."
            task.spawn(function()
                local ok = smartInsertRbxm(file.path, file.name)
                if insertBtn and insertBtn.Parent then
                    if ok then
                        insertBtn.Text = "OK!"
                        RbxmCountLbl.Text = "[OK] Inserted: "..file.name
                    else
                        insertBtn.Text = "COPY ID"
                        RbxmCountLbl.Text = "[!] Gunakan manual insert di Studio Lite"
                    end
                    task.delay(2, function()
                        if insertBtn and insertBtn.Parent then
                            insertBtn.Text = "INSERT"
                        end
                    end)
                end
            end)
        end)
    end

    RbxmScroll.CanvasSize = UDim2.new(0, 0, 0, RbxmList.AbsoluteContentSize.Y + 20)
end

RbxmScanBtn.MouseButton1Click:Connect(renderRbxmCards)

-- =====================================================
-- LOGIC: INSPECT ASSET (TOOLBOX)
-- =====================================================
local function inspectAsset(id, name, creator)
    currentInspId = tostring(id)
    TbDetThumb.Image = "rbxthumb://type=Asset&id="..currentInspId.."&w=150&h=150"
    TbDetName.Text = name or "Memuat..."
    TbDetCreator.Text = "By: @"..(creator or "?")
    TbDetId.Text = "ID: "..currentInspId

    local num = tonumber(currentInspId)
    if num and num > 0 then
        task.spawn(function()
            local s, info = pcall(function()
                return MarketplaceService:GetProductInfo(num)
            end)
            if s and info and info.Name and TbDetName and TbDetName.Parent then
                TbDetName.Text = info.Name
                local rc = (info.Creator and info.Creator.Name) or creator or "?"
                TbDetCreator.Text = "By: @"..rc
            end
        end)
    end
end

TbDetCopy.MouseButton1Click:Connect(function()
    if currentInspId ~= "" and clipFn then
        pcall(clipFn, currentInspId)
        TbDetCopy.Text = "COPIED!"
        task.delay(1.2, function()
            if TbDetCopy and TbDetCopy.Parent then
                TbDetCopy.Text = "COPY ID"
            end
        end)
    end
end)

TbDetInsert.MouseButton1Click:Connect(function()
    if currentInspId ~= "" then
        TbDetInsert.Text = "..."
        task.spawn(function()
            local ok, m = smartInsert(currentInspId)
            TbStatusLbl.Text = "[.] "..m
            if TbDetInsert and TbDetInsert.Parent then
                TbDetInsert.Text = ok and "OK!" or "COPIED"
                task.delay(1.5, function()
                    if TbDetInsert and TbDetInsert.Parent then
                        TbDetInsert.Text = "INSERT"
                    end
                end)
            end
        end)
    end
end)

-- =====================================================
-- LOGIC: QUERY & RENDER TOOLBOX GRID
-- =====================================================
local function queryMarketplace(catId, query)
    local enc = HttpService:UrlEncode(query)
    local urls = {
        ("https://apis.roproxy.com/toolbox-service/v1/marketplace/%d?keyword=%s&limit=30"):format(catId, enc),
        ("https://apis.roblox.com/toolbox-service/v1/marketplace/%d?keyword=%s&limit=30"):format(catId, enc),
    }
    for _, url in ipairs(urls) do
        local s, r = pcall(function()
            return httpRequest({
                Url = url,
                Method = "GET",
                Headers = {["User-Agent"] = "RobloxStudio/WinInet"}
            })
        end)
        if s and r and r.StatusCode == 200 then
            local ds, parsed = pcall(function()
                return HttpService:JSONDecode(r.Body)
            end)
            if ds and parsed and parsed.data and #parsed.data > 0 then
                return parsed.data
            end
        end
    end
    return nil
end

local function renderGrid(data)
    for _, c in ipairs(TbGridScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    if not data or #data == 0 then
        TbGridStatus.Visible = true
        TbGridStatus.Text = "Tidak ada aset ditemukan."
        return
    end

    TbGridStatus.Visible = false

    local first = data[1]
    if first then
        inspectAsset(
            first.id or (first.asset and first.asset.id) or "0",
            first.name or (first.asset and first.asset.name) or "Asset",
            (first.creator and first.creator.name) or "?"
        )
    end

    for _, item in ipairs(data) do
        local assetId   = tostring(item.id or (item.asset and item.asset.id) or "0")
        local assetName = item.name or (item.asset and item.asset.name) or "Asset"
        local creator   = (item.creator and item.creator.name) or "?"

        local card = Instance.new("Frame")
        card.BackgroundColor3 = Color3.fromRGB(22, 22, 27)
        card.BorderSizePixel = 0
        card.Parent = TbGridScroll
        makeCorner(card, 6)
        makeStroke(card, Color3.fromRGB(255,255,255), 1, 0.88)

        local thumb = Instance.new("ImageLabel")
        thumb.Size = UDim2.new(1, -8, 0, 50)
        thumb.Position = UDim2.new(0, 4, 0, 4)
        thumb.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
        thumb.Image = "rbxthumb://type=Asset&id="..assetId.."&w=150&h=150"
        thumb.Parent = card
        makeCorner(thumb, 5)

        local nameL = Instance.new("TextLabel")
        nameL.Size = UDim2.new(1, -8, 0, 14)
        nameL.Position = UDim2.new(0, 4, 0, 56)
        nameL.BackgroundTransparency = 1
        nameL.Text = assetName
        nameL.Font = Enum.Font.GothamBold
        nameL.TextSize = 8
        nameL.TextColor3 = Color3.fromRGB(240, 240, 240)
        nameL.TextXAlignment = Enum.TextXAlignment.Left
        nameL.TextTruncate = Enum.TextTruncate.AtEnd
        nameL.Parent = card

        local subL = Instance.new("TextLabel")
        subL.Size = UDim2.new(1, -8, 0, 12)
        subL.Position = UDim2.new(0, 4, 0, 70)
        subL.BackgroundTransparency = 1
        subL.Text = "@"..creator
        subL.Font = Enum.Font.Gotham
        subL.TextSize = 7
        subL.TextColor3 = Color3.fromRGB(140, 140, 150)
        subL.TextXAlignment = Enum.TextXAlignment.Left
        subL.TextTruncate = Enum.TextTruncate.AtEnd
        subL.Parent = card

        local btnRow = Instance.new("Frame")
        btnRow.Size = UDim2.new(1, -8, 0, 17)
        btnRow.Position = UDim2.new(0, 4, 1, -21)
        btnRow.BackgroundTransparency = 1
        btnRow.Parent = card

        local iBtn = Instance.new("TextButton")
        iBtn.Size = UDim2.new(0.5, -2, 1, 0)
        iBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        iBtn.Text = "INSERT"
        iBtn.Font = Enum.Font.GothamBold
        iBtn.TextSize = 8
        iBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        iBtn.Parent = btnRow
        makeCorner(iBtn, 4)

        local cBtn = Instance.new("TextButton")
        cBtn.Size = UDim2.new(0.5, -2, 1, 0)
        cBtn.Position = UDim2.new(0.5, 2, 0, 0)
        cBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        cBtn.Text = "COPY"
        cBtn.Font = Enum.Font.GothamBold
        cBtn.TextSize = 8
        cBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        cBtn.Parent = btnRow
        makeCorner(cBtn, 4)

        cBtn.MouseButton1Click:Connect(function()
            if clipFn then
                pcall(clipFn, assetId)
                cBtn.Text = "OK!"
                task.delay(1.2, function()
                    if cBtn and cBtn.Parent then cBtn.Text = "COPY" end
                end)
            end
        end)

        iBtn.MouseButton1Click:Connect(function()
            iBtn.Text = "..."
            TbStatusLbl.Text = "[.] Inserting "..assetId
            task.spawn(function()
                local ok, m = smartInsert(assetId)
                TbStatusLbl.Text = "[.] "..m
                if iBtn and iBtn.Parent then
                    iBtn.Text = ok and "OK!" or "COPY"
                    task.delay(1.2, function()
                        if iBtn and iBtn.Parent then iBtn.Text = "INSERT" end
                    end)
                end
            end)
        end)

        local hitbox = Instance.new("TextButton")
        hitbox.Size = UDim2.new(1, 0, 0, 86)
        hitbox.BackgroundTransparency = 1
        hitbox.Text = ""
        hitbox.Parent = card
        hitbox.MouseButton1Click:Connect(function()
            inspectAsset(assetId, nameL.Text, creator)
        end)

        task.spawn(function()
            local num = tonumber(assetId)
            if not num then return end
            local s, info = pcall(function()
                return MarketplaceService:GetProductInfo(num)
            end)
            if s and info and info.Name and nameL and nameL.Parent then
                nameL.Text = info.Name
                local rc = (info.Creator and info.Creator.Name) or creator
                subL.Text = "@"..rc
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
        TbGridStatus.Visible = true
        TbGridStatus.Text = "Searching..."
        TbStatusLbl.Text = "[.] Mencari: "..TbSearchBox.Text
        task.spawn(function()
            local data = queryMarketplace(selectedCat, TbSearchBox.Text)
            renderGrid(data)
            TbStatusLbl.Text = "[.] Selesai"
        end)
    end
end

TbSearchBtn.MouseButton1Click:Connect(execSearch)
TbSearchBox.FocusLost:Connect(function(enter)
    if enter then execSearch() end
end)

TbInsertIdBtn.MouseButton1Click:Connect(function()
    local id = TbIdBox.Text:gsub("%D+", "")
    if id ~= "" then
        inspectAsset(id, "Memuat...", "?")
        TbInsertIdBtn.Text = "..."
        task.spawn(function()
            local ok, m = smartInsert(id)
            TbStatusLbl.Text = "[.] "..m
            if TbInsertIdBtn and TbInsertIdBtn.Parent then
                TbInsertIdBtn.Text = ok and "OK!" or "COPIED"
                task.delay(1.5, function()
                    if TbInsertIdBtn and TbInsertIdBtn.Parent then
                        TbInsertIdBtn.Text = "INSERT"
                    end
                end)
            end
        end)
    end
end)

-- =====================================================
-- LOAD PLAYER PROFILE
-- =====================================================
task.spawn(function()
    -- Data dari engine langsung (selalu tersedia, tanpa HTTP)
    DispName.Text   = LP.DisplayName or LP.Name
    UsernLabel.Text = "@"..LP.Name

    -- Avatar headshot via RoProxy
    pcall(function()
        local url = ("https://thumbnails.roproxy.com/v1/users/avatar-headshot?userIds=%d&size=150x150&format=Png&isCircular=false"):format(LP.UserId)
        local res = httpRequest({
            Url = url,
            Method = "GET",
            Headers = {["User-Agent"] = "RobloxStudio/WinInet"}
        })
        if res and res.StatusCode == 200 then
            local data = HttpService:JSONDecode(res.Body)
            if data and data.data and data.data[1] and data.data[1].imageUrl then
                AvatarImg.Image = data.data[1].imageUrl
            end
        end
    end)
end)
