-- =======================================================
-- BLUExCrown ENGINE v5.2 - TURBO STABLE (MOBILE FIX)
-- 100% Anti-Freeze: Tanpa metamethod hook berbahaya
-- Auto-Fix: Mengganti "Not found." di Studio Lite secara real-time
-- Mobile Friendly: Tombol responsif dengan .Activated + .MouseButton1Click
-- Avatar: Native rbxthumb (Instan tanpa delay HTTP)
-- Toggle Asset ID: 102337382069600
-- =======================================================

local HttpService        = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local CoreGui            = game:GetService("CoreGui")
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

local LP = Players.LocalPlayer
local ParentGui = (gethui and gethui()) or CoreGui or LP:WaitForChild("PlayerGui")

local httpRequest  = request or http_request or (syn and syn.request) or (http and http.request)
local clipFn       = setclipboard or toclipboard or (Clipboard and Clipboard.set)
local customAsset  = getcustomasset or getsynasset or nil
local listfilesFn  = listfiles or nil

-- Memory penyimpanan source code script hasil ekstrak .rbxm
_G.BLUE_RAW_SOURCES = _G.BLUE_RAW_SOURCES or {}

-- =====================================================
-- STUDIO LITE INTEGRATION (AMAN & RINGAN)
-- =====================================================
local slFolder    = ReplicatedStorage:FindFirstChild("StudioLiteFolder")
local serverFuncs = slFolder and slFolder:FindFirstChild("ServerFunctions")

local function triggerServerLoad(idStr)
    if not serverFuncs or not idStr or idStr == "" then return end
    local id = tostring(idStr):match("%d+")
    if id and tonumber(id) and tonumber(id) > 0 then
        task.spawn(function()
            pcall(function()
                serverFuncs:InvokeServer("LoadMeshToRuntimeMeshes", tonumber(id))
            end)
        end)
    end
end

local function applyStudioLiteProps(obj)
    if not obj then return end
    pcall(function()
        if obj:IsA("BasePart") then
            local origAnchor  = obj.Anchored
            local origCollide = obj.CanCollide
            obj.Anchored = true
            if obj:GetAttribute("SL_Anchored") == nil then obj:SetAttribute("SL_Anchored", origAnchor) end
            if obj:GetAttribute("SL_CanCollide") == nil then obj:SetAttribute("SL_CanCollide", origCollide) end
        end
    end)
    for _, child in ipairs(obj:GetChildren()) do applyStudioLiteProps(child) end
end

local function loadAssetsToSLServer(obj)
    task.spawn(function()
        pcall(function()
            for _, node in ipairs(obj:GetDescendants()) do
                if node:IsA("MeshPart") then
                    triggerServerLoad(node.MeshId); triggerServerLoad(node.TextureID)
                elseif node:IsA("Decal") or node:IsA("Texture") then
                    triggerServerLoad(node.Texture)
                elseif node:IsA("SpecialMesh") then
                    triggerServerLoad(node.MeshId); triggerServerLoad(node.TextureId)
                elseif node:IsA("UnionOperation") or node:IsA("PartOperation") then
                    triggerServerLoad(node.AssetId)
                end
            end
        end)
    end)
end

-- =====================================================
-- AUTO-REPLACE "NOT FOUND." DI EDITOR STUDIO LITE
-- =====================================================
local function fixEditorText(txtObj)
    if not (txtObj:IsA("TextBox") or txtObj:IsA("TextLabel")) then return end
    local cur = txtObj.Text
    if cur == "Not found." or cur == "Not found" or cur == "-- [LANGZ] Source tidak ditemukan." then
        local win = txtObj:FindFirstAncestorWhichIsA("Frame") or txtObj.Parent
        local title = ""
        if win then
            for _, d in ipairs(win:GetDescendants()) do
                if (d:IsA("TextLabel") or d:IsA("TextBox")) and d ~= txtObj then
                    local t = d.Text
                    if t:find("%(read only%)") or t:find("Config") or t:find("Script") or #t > 2 then
                        title = t:gsub("%s*%(read only%)%s*", ""):gsub("%s+", "")
                        break
                    end
                end
            end
        end

        local foundSource = nil
        if title ~= "" then
            for k, v in pairs(_G.BLUE_RAW_SOURCES) do
                local name = typeof(k) == "Instance" and k.Name or tostring(k)
                if name:lower() == title:lower() or name:lower():find(title:lower(), 1, true) then
                    foundSource = v
                    break
                end
            end
        end

        if not foundSource then
            for _, v in pairs(_G.BLUE_RAW_SOURCES) do
                if v and #v > 10 then
                    foundSource = v
                    break
                end
            end
        end

        if foundSource then
            txtObj.Text = foundSource
        end
    end
end

task.spawn(function()
    pcall(function()
        local pg = LP:WaitForChild("PlayerGui", 5)
        if pg then
            pg.DescendantAdded:Connect(function(desc)
                task.delay(0.1, function()
                    fixEditorText(desc)
                end)
            end)
            for _, d in ipairs(pg:GetDescendants()) do
                fixEditorText(d)
            end
        end
    end)
end)

-- =====================================================
-- RBXM RAW SCANNER (RINGAN & TANPA MEMBEBANI MEMORI)
-- =====================================================
local function parseRBXMSourcesSimple(raw)
    local sources = {}
    if not raw or #raw < 30 then return sources end
    for src in raw:gmatch("([^\0\r\n][^\0]+[\r\n]+[^\0]+)") do
        if src:find("function") or src:find("local ") or src:find("return") or src:find("require") then
            local nameMatch = src:match("([%a_][%w_]*)%s*=%s*function") or src:match("local%s+([%a_][%w_]*)") or "Script"
            sources[nameMatch] = src
        end
    end
    for name, code in raw:gmatch('<Item class="[%w]+" referent="[^"]+">%s*<Properties>%s*<string name="Name">([^<]+)</string>.-<ProtectedString name="Source"><%!%[CDATA%[(.-)%]%]></ProtectedString>') do
        sources[name] = code
    end
    return sources
end

-- =====================================================
-- GUI CREATION
-- =====================================================
if ParentGui:FindFirstChild("BLUExCrownV5") then
    ParentGui.BLUExCrownV5:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BLUExCrownV5"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = ParentGui

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

local function bindClick(btn, callback)
    btn.Activated:Connect(callback)
    btn.MouseButton1Click:Connect(callback)
end

-- ===================== TOGGLE BUTTON =====================
local ToggleBtn = Instance.new("ImageButton")
ToggleBtn.Size = UDim2.new(0, 44, 0, 44)
ToggleBtn.Position = UDim2.new(0.02, 0, 0.45, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(14, 14, 16)
ToggleBtn.Image = "rbxassetid://102337382069600"
ToggleBtn.ScaleType = Enum.ScaleType.Fit
ToggleBtn.Active = true
ToggleBtn.ZIndex = 50
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
MainFrame.Active = true
MainFrame.ZIndex = 10
MainFrame.Parent = ScreenGui
makeCorner(MainFrame, 10)
makeStroke(MainFrame, Color3.fromRGB(255,255,255), 1.4)

-- TOP BAR
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, -12, 0, 30)
TopBar.Position = UDim2.new(0, 6, 0, 6)
TopBar.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
TopBar.BorderSizePixel = 0
TopBar.Active = true
TopBar.ZIndex = 11
TopBar.Parent = MainFrame
makeCorner(TopBar, 7)
makeStroke(TopBar, Color3.fromRGB(255,255,255), 1, 0.75)

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size = UDim2.new(1, -50, 1, 0)
TitleLbl.Position = UDim2.new(0, 12, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text = "BLUExCrown ENGINE v5.2"
TitleLbl.Font = Enum.Font.GothamBold
TitleLbl.TextSize = 11
TitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TitleLbl.ZIndex = 12
TitleLbl.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -28, 0, 3)
CloseBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 11
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.ZIndex = 15
CloseBtn.Active = true
CloseBtn.Parent = TopBar
makeCorner(CloseBtn, 6)
makeStroke(CloseBtn, Color3.fromRGB(255,255,255), 1, 0.5)

-- CONTENT CONTAINER
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -12, 1, -44)
Content.Position = UDim2.new(0, 6, 0, 38)
Content.BackgroundTransparency = 1
Content.ZIndex = 11
Content.Parent = MainFrame

local PageSplash  = Instance.new("Frame")
local PageToolbox = Instance.new("Frame")
local PageRBXM    = Instance.new("Frame")

for _, pg in ipairs({PageSplash, PageToolbox, PageRBXM}) do
    pg.Size = UDim2.fromScale(1, 1)
    pg.BackgroundTransparency = 1
    pg.Visible = false
    pg.ZIndex = 12
    pg.Parent = Content
end
PageSplash.Visible = true

-- =====================================================
-- PAGE 1: SPLASH SCREEN (HOME)
-- =====================================================
local ProfileCard = Instance.new("Frame")
ProfileCard.Size = UDim2.new(0, 175, 1, 0)
ProfileCard.BackgroundColor3 = Color3.fromRGB(17, 17, 22)
ProfileCard.BorderSizePixel = 0
ProfileCard.ZIndex = 13
ProfileCard.Parent = PageSplash
makeCorner(ProfileCard, 8)
makeStroke(ProfileCard, Color3.fromRGB(255,255,255), 1, 0.75)

local AvatarImg = Instance.new("ImageLabel")
AvatarImg.Size = UDim2.new(0, 70, 0, 70)
AvatarImg.AnchorPoint = Vector2.new(0.5, 0)
AvatarImg.Position = UDim2.new(0.5, 0, 0, 14)
AvatarImg.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
AvatarImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LP.UserId) .. "&w=150&h=150"
AvatarImg.ZIndex = 14
AvatarImg.Parent = ProfileCard
makeCorner(AvatarImg, 35)
makeStroke(AvatarImg, Color3.fromRGB(255,255,255), 1.5, 0.5)

local DispName = Instance.new("TextLabel")
DispName.Size = UDim2.new(1, -16, 0, 20)
DispName.Position = UDim2.new(0, 8, 0, 90)
DispName.BackgroundTransparency = 1
DispName.Text = LP.DisplayName or LP.Name or "Player"
DispName.Font = Enum.Font.GothamBold
DispName.TextSize = 13
DispName.TextColor3 = Color3.fromRGB(255, 255, 255)
DispName.TextXAlignment = Enum.TextXAlignment.Center
DispName.TextTruncate = Enum.TextTruncate.AtEnd
DispName.ZIndex = 14
DispName.Parent = ProfileCard

local UsernLabel = Instance.new("TextLabel")
UsernLabel.Size = UDim2.new(1, -16, 0, 16)
UsernLabel.Position = UDim2.new(0, 8, 0, 112)
UsernLabel.BackgroundTransparency = 1
UsernLabel.Text = "@" .. (LP.Name or "username")
UsernLabel.Font = Enum.Font.Gotham
UsernLabel.TextSize = 10
UsernLabel.TextColor3 = Color3.fromRGB(160, 160, 170)
UsernLabel.TextXAlignment = Enum.TextXAlignment.Center
UsernLabel.ZIndex = 14
UsernLabel.Parent = ProfileCard

local SepLine = Instance.new("Frame")
SepLine.Size = UDim2.new(1, -20, 0, 1)
SepLine.Position = UDim2.new(0, 10, 0, 136)
SepLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SepLine.BackgroundTransparency = 0.85
SepLine.BorderSizePixel = 0
SepLine.ZIndex = 14
SepLine.Parent = ProfileCard

local SLStatusLbl = Instance.new("TextLabel")
SLStatusLbl.Size = UDim2.new(1, -16, 0, 14)
SLStatusLbl.Position = UDim2.new(0, 8, 0, 144)
SLStatusLbl.BackgroundTransparency = 1
SLStatusLbl.Text = serverFuncs and "[OK] Studio Lite Connected" or "[OK] Engine Standalone"
SLStatusLbl.Font = Enum.Font.Gotham
SLStatusLbl.TextSize = 8
SLStatusLbl.TextColor3 = Color3.fromRGB(120, 220, 120)
SLStatusLbl.TextXAlignment = Enum.TextXAlignment.Center
SLStatusLbl.ZIndex = 14
SLStatusLbl.Parent = ProfileCard

local StatsLbl = Instance.new("TextLabel")
StatsLbl.Size = UDim2.new(1, -16, 1, -168)
StatsLbl.Position = UDim2.new(0, 8, 0, 162)
StatsLbl.BackgroundTransparency = 1
StatsLbl.Text = "UserID: "..tostring(LP.UserId).."\nBLUExCrown ENGINE\nv5.2 — Turbo Edition"
StatsLbl.Font = Enum.Font.Gotham
StatsLbl.TextSize = 9
StatsLbl.TextColor3 = Color3.fromRGB(130, 130, 140)
StatsLbl.TextXAlignment = Enum.TextXAlignment.Center
StatsLbl.TextWrapped = true
StatsLbl.ZIndex = 14
StatsLbl.Parent = ProfileCard

-- KANAN: Menu Cards
local MenuArea = Instance.new("Frame")
MenuArea.Size = UDim2.new(1, -183, 1, 0)
MenuArea.Position = UDim2.new(0, 183, 0, 0)
MenuArea.BackgroundTransparency = 1
MenuArea.ZIndex = 13
MenuArea.Parent = PageSplash

local MenuTitle = Instance.new("TextLabel")
MenuTitle.Size = UDim2.new(1, 0, 0, 24)
MenuTitle.BackgroundTransparency = 1
MenuTitle.Text = "PILIH MENU"
MenuTitle.Font = Enum.Font.GothamBold
MenuTitle.TextSize = 10
MenuTitle.TextColor3 = Color3.fromRGB(180, 180, 190)
MenuTitle.TextXAlignment = Enum.TextXAlignment.Left
MenuTitle.ZIndex = 14
MenuTitle.Parent = MenuArea

local function makeMenuCard(parent, posY, icon, title, subtitle)
    local card = Instance.new("TextButton")
    card.Size = UDim2.new(1, 0, 0, 72)
    card.Position = UDim2.new(0, 0, 0, posY)
    card.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    card.Text = ""
    card.Active = true
    card.ZIndex = 14
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
    iconLbl.ZIndex = 15
    iconLbl.Active = false
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
    titleL.ZIndex = 15
    titleL.Active = false
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
    subL.ZIndex = 15
    subL.Active = false
    subL.Parent = card

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 20, 0, 20)
    arrow.Position = UDim2.new(1, -28, 0.5, -10)
    arrow.BackgroundTransparency = 1
    arrow.Text = ">"
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 18
    arrow.TextColor3 = Color3.fromRGB(200, 200, 210)
    arrow.ZIndex = 15
    arrow.Active = false
    arrow.Parent = card

    return card
end

local CardToolbox = makeMenuCard(MenuArea, 28,  "[T]", "TOOLBOX ASET",     "Cari & insert model dari Creator Store")
local CardRBXM    = makeMenuCard(MenuArea, 108, "[R]", "INSERT RBXM FILE", "Scan & insert file .rbxm dengan Source Script")

local function makeBackBtn(parent)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 64, 0, 22)
    b.Position = UDim2.new(1, -68, 0, 0)
    b.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    b.Text = "< BACK"
    b.Font = Enum.Font.GothamBold
    b.TextSize = 9
    b.TextColor3 = Color3.fromRGB(0, 0, 0)
    b.Active = true
    b.ZIndex = 15
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
TbHeader.ZIndex = 13
TbHeader.Parent = PageToolbox
local TbTitleLbl = Instance.new("TextLabel")
TbTitleLbl.Size = UDim2.new(1, -80, 1, 0)
TbTitleLbl.BackgroundTransparency = 1
TbTitleLbl.Text = "TOOLBOX ASET"
TbTitleLbl.Font = Enum.Font.GothamBold
TbTitleLbl.TextSize = 11
TbTitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
TbTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TbTitleLbl.ZIndex = 14
TbTitleLbl.Parent = TbHeader
local TbBack = makeBackBtn(TbHeader)

local TbContent = Instance.new("Frame")
TbContent.Size = UDim2.new(1, 0, 1, -34)
TbContent.Position = UDim2.new(0, 0, 0, 34)
TbContent.BackgroundTransparency = 1
TbContent.ZIndex = 13
TbContent.Parent = PageToolbox

local TbLeft = Instance.new("Frame")
TbLeft.Size = UDim2.new(0, 220, 1, 0)
TbLeft.BackgroundTransparency = 1
TbLeft.ZIndex = 14
TbLeft.Parent = TbContent

local TbSearchSec = Instance.new("Frame")
TbSearchSec.Size = UDim2.new(1, 0, 0, 118)
TbSearchSec.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
TbSearchSec.ZIndex = 14
TbSearchSec.Parent = TbLeft
makeCorner(TbSearchSec, 8)
makeStroke(TbSearchSec, Color3.fromRGB(255,255,255), 1, 0.78)

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
TbIdBox.ZIndex = 15
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
TbInsertIdBtn.Active = true
TbInsertIdBtn.ZIndex = 15
TbInsertIdBtn.Parent = TbSearchSec
makeCorner(TbInsertIdBtn, 5)

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
TbSearchBox.ZIndex = 15
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
TbSearchBtn.Active = true
TbSearchBtn.ZIndex = 15
TbSearchBtn.Parent = TbSearchSec
makeCorner(TbSearchBtn, 5)

local selectedCat = 10
local catBtns = {}
local cats = {{n="MODEL",id=10},{n="DECAL",id=13},{n="AUDIO",id=3},{n="MESH",id=11}}
local TbCatRow = Instance.new("Frame")
TbCatRow.Size = UDim2.new(1, -12, 0, 20)
TbCatRow.Position = UDim2.new(0, 6, 0, 65)
TbCatRow.BackgroundTransparency = 1
TbCatRow.ZIndex = 14
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
    cb.Text = c.n; cb.Font = Enum.Font.GothamBold; cb.TextSize = 8
    cb.TextColor3 = Color3.fromRGB(160, 160, 170)
    cb.Active = true
    cb.ZIndex = 15
    cb.Parent = TbCatRow
    makeCorner(cb, 4); makeStroke(cb, Color3.fromRGB(255,255,255), 1, 0.82)
    catBtns[c.id] = cb
    bindClick(cb, function() selectedCat = c.id; updateCatTabs() end)
end
updateCatTabs()

local TbStatusLbl = Instance.new("TextLabel")
TbStatusLbl.Size = UDim2.new(1, -12, 0, 16)
TbStatusLbl.Position = UDim2.new(0, 6, 0, 90)
TbStatusLbl.BackgroundTransparency = 1
TbStatusLbl.Text = "[.] Siap"
TbStatusLbl.Font = Enum.Font.Gotham; TbStatusLbl.TextSize = 9
TbStatusLbl.TextColor3 = Color3.fromRGB(140, 140, 150)
TbStatusLbl.TextXAlignment = Enum.TextXAlignment.Left
TbStatusLbl.ZIndex = 15
TbStatusLbl.Parent = TbSearchSec

local TbDetailBox = Instance.new("Frame")
TbDetailBox.Size = UDim2.new(1, 0, 1, -124)
TbDetailBox.Position = UDim2.new(0, 0, 0, 124)
TbDetailBox.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
TbDetailBox.ZIndex = 14
TbDetailBox.Parent = TbLeft
makeCorner(TbDetailBox, 8); makeStroke(TbDetailBox, Color3.fromRGB(255,255,255), 1, 0.78)

local TbDetTitleLbl = Instance.new("TextLabel")
TbDetTitleLbl.Size = UDim2.new(1, -12, 0, 18); TbDetTitleLbl.Position = UDim2.new(0, 8, 0, 4)
TbDetTitleLbl.BackgroundTransparency = 1; TbDetTitleLbl.Text = "DETAIL ASSET"
TbDetTitleLbl.Font = Enum.Font.GothamBold; TbDetTitleLbl.TextSize = 9
TbDetTitleLbl.TextColor3 = Color3.fromRGB(200, 200, 210)
TbDetTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TbDetTitleLbl.ZIndex = 15
TbDetTitleLbl.Parent = TbDetailBox

local TbDetThumb = Instance.new("ImageLabel")
TbDetThumb.Size = UDim2.new(0, 52, 0, 52); TbDetThumb.Position = UDim2.new(0, 8, 0, 24)
TbDetThumb.BackgroundColor3 = Color3.fromRGB(26, 26, 30); TbDetThumb.Image = ""
TbDetThumb.ZIndex = 15
TbDetThumb.Parent = TbDetailBox; makeCorner(TbDetThumb, 6); makeStroke(TbDetThumb, Color3.fromRGB(255,255,255), 1, 0.82)

local TbDetName = Instance.new("TextLabel")
TbDetName.Size = UDim2.new(1, -70, 0, 26); TbDetName.Position = UDim2.new(0, 66, 0, 22)
TbDetName.BackgroundTransparency = 1; TbDetName.Text = "Pilih aset dari grid"
TbDetName.Font = Enum.Font.GothamBold; TbDetName.TextSize = 10
TbDetName.TextColor3 = Color3.fromRGB(255, 255, 255)
TbDetName.TextXAlignment = Enum.TextXAlignment.Left; TbDetName.TextWrapped = true
TbDetName.ZIndex = 15
TbDetName.Parent = TbDetailBox

local TbDetCreator = Instance.new("TextLabel")
TbDetCreator.Size = UDim2.new(1, -70, 0, 14); TbDetCreator.Position = UDim2.new(0, 66, 0, 46)
TbDetCreator.BackgroundTransparency = 1; TbDetCreator.Text = "By: -"
TbDetCreator.Font = Enum.Font.Gotham; TbDetCreator.TextSize = 8
TbDetCreator.TextColor3 = Color3.fromRGB(150, 150, 160)
TbDetCreator.TextXAlignment = Enum.TextXAlignment.Left
TbDetCreator.ZIndex = 15
TbDetCreator.Parent = TbDetailBox

local TbDetId = Instance.new("TextLabel")
TbDetId.Size = UDim2.new(1, -70, 0, 14); TbDetId.Position = UDim2.new(0, 66, 0, 60)
TbDetId.BackgroundTransparency = 1; TbDetId.Text = "ID: -"
TbDetId.Font = Enum.Font.Gotham; TbDetId.TextSize = 8
TbDetId.TextColor3 = Color3.fromRGB(150, 150, 160)
TbDetId.TextXAlignment = Enum.TextXAlignment.Left
TbDetId.ZIndex = 15
TbDetId.Parent = TbDetailBox

local currentInspId = ""
local TbDetRow = Instance.new("Frame")
TbDetRow.Size = UDim2.new(1, -16, 0, 26); TbDetRow.Position = UDim2.new(0, 8, 1, -32)
TbDetRow.BackgroundTransparency = 1
TbDetRow.ZIndex = 14
TbDetRow.Parent = TbDetailBox

local TbDetInsert = Instance.new("TextButton")
TbDetInsert.Size = UDim2.new(0.5, -3, 1, 0); TbDetInsert.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TbDetInsert.Text = "INSERT"; TbDetInsert.Font = Enum.Font.GothamBold; TbDetInsert.TextSize = 9
TbDetInsert.TextColor3 = Color3.fromRGB(0, 0, 0); TbDetInsert.Active = true; TbDetInsert.ZIndex = 15
TbDetInsert.Parent = TbDetRow; makeCorner(TbDetInsert, 5)

local TbDetCopy = Instance.new("TextButton")
TbDetCopy.Size = UDim2.new(0.5, -3, 1, 0); TbDetCopy.Position = UDim2.new(0.5, 3, 0, 0)
TbDetCopy.BackgroundColor3 = Color3.fromRGB(255, 255, 255); TbDetCopy.Text = "COPY ID"
TbDetCopy.Font = Enum.Font.GothamBold; TbDetCopy.TextSize = 9
TbDetCopy.TextColor3 = Color3.fromRGB(0, 0, 0); TbDetCopy.Active = true; TbDetCopy.ZIndex = 15
TbDetCopy.Parent = TbDetRow; makeCorner(TbDetCopy, 5)

local TbRight = Instance.new("Frame")
TbRight.Size = UDim2.new(1, -228, 1, 0); TbRight.Position = UDim2.new(0, 228, 0, 0)
TbRight.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
TbRight.ZIndex = 14
TbRight.Parent = TbContent
makeCorner(TbRight, 8); makeStroke(TbRight, Color3.fromRGB(255,255,255), 1, 0.78)

local TbBrowserLbl = Instance.new("TextLabel")
TbBrowserLbl.Size = UDim2.new(1, -16, 0, 24); TbBrowserLbl.Position = UDim2.new(0, 8, 0, 4)
TbBrowserLbl.BackgroundTransparency = 1; TbBrowserLbl.Text = "ASSET BROWSER"
TbBrowserLbl.Font = Enum.Font.GothamBold; TbBrowserLbl.TextSize = 10
TbBrowserLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
TbBrowserLbl.TextXAlignment = Enum.TextXAlignment.Left
TbBrowserLbl.ZIndex = 15
TbBrowserLbl.Parent = TbRight

local TbGridScroll = Instance.new("ScrollingFrame")
TbGridScroll.Size = UDim2.new(1, -12, 1, -34); TbGridScroll.Position = UDim2.new(0, 6, 0, 28)
TbGridScroll.BackgroundTransparency = 1; TbGridScroll.ScrollBarThickness = 3
TbGridScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
TbGridScroll.ZIndex = 15
TbGridScroll.Parent = TbRight

local TbGrid = Instance.new("UIGridLayout")
TbGrid.CellSize = UDim2.new(0, 104, 0, 115); TbGrid.CellPadding = UDim2.new(0, 6, 0, 6)
TbGrid.SortOrder = Enum.SortOrder.LayoutOrder; TbGrid.Parent = TbGridScroll

local TbGridStatus = Instance.new("TextLabel")
TbGridStatus.Size = UDim2.new(1, 0, 0, 40); TbGridStatus.BackgroundTransparency = 1
TbGridStatus.Text = "Ketik kata kunci & klik CARI"
TbGridStatus.Font = Enum.Font.Gotham; TbGridStatus.TextSize = 10
TbGridStatus.TextColor3 = Color3.fromRGB(140, 140, 150)
TbGridStatus.ZIndex = 16
TbGridStatus.Parent = TbGridScroll

-- =====================================================
-- PAGE 3: INSERT RBXM FILE
-- =====================================================
local RbxmHeader = Instance.new("Frame")
RbxmHeader.Size = UDim2.new(1, 0, 0, 28); RbxmHeader.BackgroundTransparency = 1; RbxmHeader.ZIndex = 13; RbxmHeader.Parent = PageRBXM
local RbxmTitleLbl = Instance.new("TextLabel")
RbxmTitleLbl.Size = UDim2.new(1, -80, 1, 0); RbxmTitleLbl.BackgroundTransparency = 1
RbxmTitleLbl.Text = "INSERT RBXM FILE"; RbxmTitleLbl.Font = Enum.Font.GothamBold; RbxmTitleLbl.TextSize = 11
RbxmTitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
RbxmTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
RbxmTitleLbl.ZIndex = 14
RbxmTitleLbl.Parent = RbxmHeader
local RbxmBack = makeBackBtn(RbxmHeader)

local RbxmToolbar = Instance.new("Frame")
RbxmToolbar.Size = UDim2.new(1, 0, 0, 28); RbxmToolbar.Position = UDim2.new(0, 0, 0, 32)
RbxmToolbar.BackgroundTransparency = 1; RbxmToolbar.ZIndex = 13; RbxmToolbar.Parent = PageRBXM

local RbxmScanBtn = Instance.new("TextButton")
RbxmScanBtn.Size = UDim2.new(0, 90, 0, 24); RbxmScanBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
RbxmScanBtn.Text = "SCAN FILES"; RbxmScanBtn.Font = Enum.Font.GothamBold; RbxmScanBtn.TextSize = 10
RbxmScanBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
RbxmScanBtn.Active = true; RbxmScanBtn.ZIndex = 15; RbxmScanBtn.Parent = RbxmToolbar; makeCorner(RbxmScanBtn, 6)

local RbxmSLStatus = Instance.new("TextLabel")
RbxmSLStatus.Size = UDim2.new(0, 120, 1, 0); RbxmSLStatus.Position = UDim2.new(0, 96, 0, 0)
RbxmSLStatus.BackgroundTransparency = 1
RbxmSLStatus.Text = "[AUTO-SOURCE: ON]"
RbxmSLStatus.Font = Enum.Font.GothamBold; RbxmSLStatus.TextSize = 9
RbxmSLStatus.TextColor3 = Color3.fromRGB(120, 220, 120)
RbxmSLStatus.TextXAlignment = Enum.TextXAlignment.Left
RbxmSLStatus.ZIndex = 14
RbxmSLStatus.Parent = RbxmToolbar

local RbxmCountLbl = Instance.new("TextLabel")
RbxmCountLbl.Size = UDim2.new(1, -230, 1, 0); RbxmCountLbl.Position = UDim2.new(0, 220, 0, 0)
RbxmCountLbl.BackgroundTransparency = 1
RbxmCountLbl.Text = "[.] Klik SCAN untuk mencari file .rbxm"
RbxmCountLbl.Font = Enum.Font.Gotham; RbxmCountLbl.TextSize = 9
RbxmCountLbl.TextColor3 = Color3.fromRGB(140, 140, 150)
RbxmCountLbl.TextXAlignment = Enum.TextXAlignment.Left
RbxmCountLbl.ZIndex = 14
RbxmCountLbl.Parent = RbxmToolbar

local RbxmScroll = Instance.new("ScrollingFrame")
RbxmScroll.Size = UDim2.new(1, -12, 1, -66); RbxmScroll.Position = UDim2.new(0, 6, 0, 62)
RbxmScroll.BackgroundColor3 = Color3.fromRGB(17, 17, 22); RbxmScroll.BorderSizePixel = 0
RbxmScroll.ScrollBarThickness = 3; RbxmScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
RbxmScroll.ZIndex = 14
RbxmScroll.Parent = PageRBXM; makeCorner(RbxmScroll, 8); makeStroke(RbxmScroll, Color3.fromRGB(255,255,255), 1, 0.78)

local RbxmList = Instance.new("UIListLayout")
RbxmList.Padding = UDim.new(0, 5); RbxmList.SortOrder = Enum.SortOrder.LayoutOrder; RbxmList.Parent = RbxmScroll
local RbxmPad = Instance.new("UIPadding")
RbxmPad.PaddingTop = UDim.new(0, 6); RbxmPad.PaddingLeft = UDim.new(0, 6); RbxmPad.PaddingRight = UDim.new(0, 6); RbxmPad.Parent = RbxmScroll

local RbxmEmpty = Instance.new("TextLabel")
RbxmEmpty.Size = UDim2.new(1, 0, 0, 40); RbxmEmpty.BackgroundTransparency = 1
RbxmEmpty.Text = "Belum ada file .rbxm ditemukan. Klik SCAN FILES."
RbxmEmpty.Font = Enum.Font.Gotham; RbxmEmpty.TextSize = 10
RbxmEmpty.TextColor3 = Color3.fromRGB(140, 140, 150)
RbxmEmpty.ZIndex = 15
RbxmEmpty.Parent = RbxmScroll

-- =====================================================
-- SAFE MOBILE DRAGGING (HANYA DRAG JIKA GESER > 12px)
-- =====================================================
local function makeSafeDraggable(frame, handle)
    local dragging = false
    local dragStart = nil
    local startPos = nil

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragStart = input.Position
            startPos = frame.Position
            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    conn:Disconnect()
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragStart and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            if delta.Magnitude > 12 then
                dragging = true
            end
            if dragging and startPos then
                frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end
    end)
end

makeSafeDraggable(MainFrame, TopBar)
makeSafeDraggable(ToggleBtn, ToggleBtn)

-- =====================================================
-- TOGGLE & NAVIGATION
-- =====================================================
local isOpen = true
local function toggleWindow()
    isOpen = not isOpen
    MainFrame.Visible = isOpen
end

bindClick(ToggleBtn, toggleWindow)
bindClick(CloseBtn, toggleWindow)

local function showPage(target)
    PageSplash.Visible  = false
    PageToolbox.Visible = false
    PageRBXM.Visible    = false
    target.Visible = true
end

bindClick(CardToolbox, function() showPage(PageToolbox) end)
bindClick(CardRBXM,    function() showPage(PageRBXM)    end)
bindClick(TbBack,      function() showPage(PageSplash)  end)
bindClick(RbxmBack,    function() showPage(PageSplash)  end)

-- =====================================================
-- LOGIC: SMART INSERT ASSET ID
-- =====================================================
local function smartInsert(assetId)
    local numId = tonumber(assetId)
    if not numId then return false, "ID tidak valid" end
    if clipFn then pcall(clipFn, tostring(numId)) end
    local insertOk, method = false, ""

    pcall(function()
        local objs = game:GetObjects("rbxassetid://"..tostring(numId))
        if objs and #objs > 0 then
            for _, o in ipairs(objs) do
                o.Parent = workspace
                applyStudioLiteProps(o)
                loadAssetsToSLServer(o)
                if o:IsA("Model") and LP.Character then
                    local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then pcall(function() o:MoveTo(hrp.Position + hrp.CFrame.LookVector * 7) end) end
                end
            end
            insertOk = true; method = "GetObjects + SL Props"
        end
    end)

    if serverFuncs then
        pcall(function()
            serverFuncs:InvokeServer("LoadMeshToRuntimeMeshes", numId)
            if not insertOk then insertOk = true; method = "SL ServerFunctions"
            else method = method .. " + SL Server" end
        end)
    end

    return insertOk, (method ~= "" and method or "ID Disalin ke Clipboard")
end

-- =====================================================
-- LOGIC: SMART INSERT RBXM DENGAN AUTO-EXTRACT
-- =====================================================
local SCAN_PATHS = {
    "workspace",
    "Delta/workspace",
    "delta/workspace",
    "Android/Delta/workspace",
    "/sdcard/Delta/workspace",
    "../workspace",
    "."
}

local function safeReadFile(p)
    if not readfile then return nil end
    local ok, d = pcall(readfile, p)
    return ok and d or nil
end

local function smartInsertRbxm(filePath, fileName)
    local insertOk, statusMsg = false, ""
    local data = safeReadFile(filePath)

    if data and #data > 0 then
        task.spawn(function()
            local sources = parseRBXMSourcesSimple(data)
            for k, v in pairs(sources) do
                _G.BLUE_RAW_SOURCES[k] = v
            end
        end)
    end

    local function setupObjects(objs)
        for _, o in ipairs(objs) do
            o.Parent = workspace
            applyStudioLiteProps(o)
            loadAssetsToSLServer(o)

            for _, s in ipairs(o:GetDescendants()) do
                if s:IsA("LuaSourceContainer") then
                    pcall(function()
                        if not _G.BLUE_RAW_SOURCES[s] and s.Source and #s.Source > 0 then
                            _G.BLUE_RAW_SOURCES[s] = s.Source
                        end
                        if not _G.BLUE_RAW_SOURCES[s.Name] and _G.BLUE_RAW_SOURCES[s] then
                            _G.BLUE_RAW_SOURCES[s.Name] = _G.BLUE_RAW_SOURCES[s]
                        end
                    end)
                end
            end

            if o:IsA("Model") and LP.Character then
                local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
                if hrp then pcall(function() o:MoveTo(hrp.Position + hrp.CFrame.LookVector * 6) end) end
            end
        end
    end

    if customAsset then
        pcall(function()
            local url = customAsset(filePath)
            if url then
                local objs = game:GetObjects(url)
                if objs and #objs > 0 then
                    setupObjects(objs)
                    insertOk = true; statusMsg = "customAsset OK"
                end
            end
        end)
    end

    if not insertOk then
        pcall(function()
            local objs = game:GetObjects("rbxasset://" .. filePath)
            if objs and #objs > 0 then
                setupObjects(objs)
                insertOk = true; statusMsg = "rbxasset:// OK"
            end
        end)
    end

    if not insertOk and data and writefile and customAsset then
        pcall(function()
            local tmpName = "bce_tmp_" .. fileName
            writefile(tmpName, data)
            local url2 = customAsset(tmpName)
            if url2 then
                local objs2 = game:GetObjects(url2)
                if objs2 and #objs2 > 0 then
                    setupObjects(objs2)
                    insertOk = true; statusMsg = "readfile+tmp OK"
                end
            end
            pcall(function() if delfile then delfile(tmpName) end end)
        end)
    end

    return insertOk, statusMsg
end

local function safeListFiles(p)
    if not listfilesFn then return nil end
    local ok, f = pcall(listfilesFn, p); return ok and f or nil
end
local function getFileName(p) return p:match("([^/\\]+)$") or p end

local function getAllRbxmFiles()
    local result, seen = {}, {}
    if not listfilesFn then return result end
    local function scanDeep(folder, depth)
        if depth > 4 or seen[folder] then return end
        seen[folder] = true
        local files = safeListFiles(folder)
        if not files then return end
        for _, path in ipairs(files) do
            local lp = path:lower()
            if (lp:sub(-5) == ".rbxm" or lp:sub(-6) == ".rbxmx") and not seen[path] then
                seen[path] = true; table.insert(result, {path=path, name=getFileName(path)})
            elseif not path:lower():match("%.[%a%d]+$") then
                scanDeep(path, depth + 1)
            end
        end
    end
    for _, p in ipairs(SCAN_PATHS) do if safeListFiles(p) then scanDeep(p, 0) end end
    return result
end

local function renderRbxmCards()
    for _, c in ipairs(RbxmScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    RbxmCountLbl.Text = "[.] Scanning..."
    local files = getAllRbxmFiles()
    RbxmEmpty.Visible = (#files == 0)
    if #files == 0 then
        RbxmCountLbl.Text = not listfilesFn and "[!] listfiles() tidak support" or "[!] Tidak ada file .rbxm"
        return
    end
    RbxmCountLbl.Text = string.format("[OK] %d file ditemukan", #files)
    for _, file in ipairs(files) do
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -12, 0, 50); card.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        card.BorderSizePixel = 0; card.Parent = RbxmScroll; makeCorner(card, 7); makeStroke(card, Color3.fromRGB(255,255,255), 1, 0.85)

        local fileIcon = Instance.new("TextLabel")
        fileIcon.Size = UDim2.new(0, 36, 0, 36); fileIcon.Position = UDim2.new(0, 5, 0.5, -18)
        fileIcon.BackgroundColor3 = Color3.fromRGB(28, 28, 34); fileIcon.Text = ".rbxm"
        fileIcon.Font = Enum.Font.GothamBold; fileIcon.TextSize = 7
        fileIcon.TextColor3 = Color3.fromRGB(200, 200, 210); fileIcon.Parent = card; makeCorner(fileIcon, 6)

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(1, -145, 0, 18); nameLbl.Position = UDim2.new(0, 48, 0, 7)
        nameLbl.BackgroundTransparency = 1; nameLbl.Text = file.name
        nameLbl.Font = Enum.Font.GothamBold; nameLbl.TextSize = 11
        nameLbl.TextColor3 = Color3.fromRGB(240, 240, 245)
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left; nameLbl.TextTruncate = Enum.TextTruncate.AtEnd; nameLbl.Parent = card

        local pathLbl = Instance.new("TextLabel")
        pathLbl.Size = UDim2.new(1, -145, 0, 13); pathLbl.Position = UDim2.new(0, 48, 0, 28)
        pathLbl.BackgroundTransparency = 1; pathLbl.Text = file.path
        pathLbl.Font = Enum.Font.Gotham; pathLbl.TextSize = 8
        pathLbl.TextColor3 = Color3.fromRGB(130, 130, 140)
        pathLbl.TextXAlignment = Enum.TextXAlignment.Left; pathLbl.TextTruncate = Enum.TextTruncate.AtEnd; pathLbl.Parent = card

        local insertBtn = Instance.new("TextButton")
        insertBtn.Size = UDim2.new(0, 70, 0, 30); insertBtn.Position = UDim2.new(1, -76, 0.5, -15)
        insertBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255); insertBtn.Text = "INSERT"
        insertBtn.Font = Enum.Font.GothamBold; insertBtn.TextSize = 9
        insertBtn.TextColor3 = Color3.fromRGB(0, 0, 0); insertBtn.Active = true; insertBtn.Parent = card; makeCorner(insertBtn, 6)

        bindClick(insertBtn, function()
            if insertBtn.Text == "..." then return end
            insertBtn.Text = "..."
            task.spawn(function()
                local ok, msg = smartInsertRbxm(file.path, file.name)
                if insertBtn and insertBtn.Parent then
                    if ok then
                        insertBtn.Text = "OK!"; insertBtn.BackgroundColor3 = Color3.fromRGB(180, 255, 180)
                        RbxmCountLbl.Text = "[OK] "..file.name.." ("..msg..")"
                    else
                        insertBtn.Text = "GAGAL"; insertBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 180)
                        RbxmCountLbl.Text = "[!] Gagal load RBXM"
                    end
                    task.delay(2.5, function()
                        if insertBtn and insertBtn.Parent then
                            insertBtn.Text = "INSERT"; insertBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        end
                    end)
                end
            end)
        end)
    end
    RbxmScroll.CanvasSize = UDim2.new(0, 0, 0, RbxmList.AbsoluteContentSize.Y + 20)
end
bindClick(RbxmScanBtn, renderRbxmCards)

local function inspectAsset(id, name, creator)
    currentInspId = tostring(id)
    TbDetThumb.Image = "rbxthumb://type=Asset&id="..currentInspId.."&w=150&h=150"
    TbDetName.Text = name or "Memuat..."; TbDetCreator.Text = "By: @"..(creator or "?"); TbDetId.Text = "ID: "..currentInspId
    local num = tonumber(currentInspId)
    if num and num > 0 then
        task.spawn(function()
            local s, info = pcall(function() return MarketplaceService:GetProductInfo(num) end)
            if s and info and info.Name and TbDetName and TbDetName.Parent then
                TbDetName.Text = info.Name
                TbDetCreator.Text = "By: @"..((info.Creator and info.Creator.Name) or creator or "?")
            end
        end)
    end
end

bindClick(TbDetCopy, function()
    if currentInspId ~= "" and clipFn then
        pcall(clipFn, currentInspId); TbDetCopy.Text = "COPIED!"
        task.delay(1.2, function() if TbDetCopy and TbDetCopy.Parent then TbDetCopy.Text = "COPY ID" end end)
    end
end)

bindClick(TbDetInsert, function()
    if currentInspId ~= "" then
        TbDetInsert.Text = "..."
        task.spawn(function()
            local ok, m = smartInsert(currentInspId)
            TbStatusLbl.Text = "[.] "..m
            if TbDetInsert and TbDetInsert.Parent then
                TbDetInsert.Text = ok and "OK!" or "COPIED"
                task.delay(1.5, function() if TbDetInsert and TbDetInsert.Parent then TbDetInsert.Text = "INSERT" end end)
            end
        end)
    end
end)

local function queryMarketplace(catId, query)
    local enc = HttpService:UrlEncode(query)
    local urls = {
        ("https://apis.roproxy.com/toolbox-service/v1/marketplace/%d?keyword=%s&limit=30"):format(catId, enc),
        ("https://apis.roblox.com/toolbox-service/v1/marketplace/%d?keyword=%s&limit=30"):format(catId, enc),
    }
    for _, url in ipairs(urls) do
        local s, r = pcall(function() return httpRequest({Url=url,Method="GET",Headers={["User-Agent"]="RobloxStudio/WinInet"}}) end)
        if s and r and r.StatusCode == 200 then
            local ds, parsed = pcall(function() return HttpService:JSONDecode(r.Body) end)
            if ds and parsed and parsed.data and #parsed.data > 0 then return parsed.data end
        end
    end
    return nil
end

local function renderGrid(data)
    for _, c in ipairs(TbGridScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    if not data or #data == 0 then TbGridStatus.Visible = true; TbGridStatus.Text = "Tidak ada aset ditemukan."; return end
    TbGridStatus.Visible = false
    local first = data[1]
    if first then inspectAsset(first.id or (first.asset and first.asset.id) or "0", first.name or (first.asset and first.asset.name) or "Asset", (first.creator and first.creator.name) or "?") end
    for _, item in ipairs(data) do
        local assetId = tostring(item.id or (item.asset and item.asset.id) or "0")
        local assetName = item.name or (item.asset and item.asset.name) or "Asset"
        local creator = (item.creator and item.creator.name) or "?"
        local card = Instance.new("Frame")
        card.BackgroundColor3 = Color3.fromRGB(22, 22, 27); card.BorderSizePixel = 0; card.Parent = TbGridScroll
        makeCorner(card, 6); makeStroke(card, Color3.fromRGB(255,255,255), 1, 0.88)
        local thumb = Instance.new("ImageLabel")
        thumb.Size = UDim2.new(1, -8, 0, 50); thumb.Position = UDim2.new(0, 4, 0, 4)
        thumb.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
        thumb.Image = "rbxthumb://type=Asset&id="..assetId.."&w=150&h=150"; thumb.Parent = card; makeCorner(thumb, 5)
        local nameL = Instance.new("TextLabel")
        nameL.Size = UDim2.new(1, -8, 0, 14); nameL.Position = UDim2.new(0, 4, 0, 56)
        nameL.BackgroundTransparency = 1; nameL.Text = assetName
        nameL.Font = Enum.Font.GothamBold; nameL.TextSize = 8; nameL.TextColor3 = Color3.fromRGB(240, 240, 240)
        nameL.TextXAlignment = Enum.TextXAlignment.Left; nameL.TextTruncate = Enum.TextTruncate.AtEnd; nameL.Parent = card
        local subL = Instance.new("TextLabel")
        subL.Size = UDim2.new(1, -8, 0, 12); subL.Position = UDim2.new(0, 4, 0, 70)
        subL.BackgroundTransparency = 1; subL.Text = "@"..creator
        subL.Font = Enum.Font.Gotham; subL.TextSize = 7; subL.TextColor3 = Color3.fromRGB(140, 140, 150)
        subL.TextXAlignment = Enum.TextXAlignment.Left; subL.TextTruncate = Enum.TextTruncate.AtEnd; subL.Parent = card
        local btnRow = Instance.new("Frame")
        btnRow.Size = UDim2.new(1, -8, 0, 17); btnRow.Position = UDim2.new(0, 4, 1, -21); btnRow.BackgroundTransparency = 1; btnRow.Parent = card
        local iBtn = Instance.new("TextButton")
        iBtn.Size = UDim2.new(0.5, -2, 1, 0); iBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        iBtn.Text = "INSERT"; iBtn.Font = Enum.Font.GothamBold; iBtn.TextSize = 8
        iBtn.TextColor3 = Color3.fromRGB(0, 0, 0); iBtn.Active = true; iBtn.Parent = btnRow; makeCorner(iBtn, 4)
        local cBtn = Instance.new("TextButton")
        cBtn.Size = UDim2.new(0.5, -2, 1, 0); cBtn.Position = UDim2.new(0.5, 2, 0, 0)
        cBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255); cBtn.Text = "COPY"
        cBtn.Font = Enum.Font.GothamBold; cBtn.TextSize = 8
        cBtn.TextColor3 = Color3.fromRGB(0, 0, 0); cBtn.Active = true; cBtn.Parent = btnRow; makeCorner(cBtn, 4)

        bindClick(cBtn, function()
            if clipFn then pcall(clipFn, assetId); cBtn.Text = "OK!"
                task.delay(1.2, function() if cBtn and cBtn.Parent then cBtn.Text = "COPY" end end) end
        end)
        bindClick(iBtn, function()
            iBtn.Text = "..."; TbStatusLbl.Text = "[.] Inserting "..assetId
            task.spawn(function()
                local ok, m = smartInsert(assetId); TbStatusLbl.Text = "[.] "..m
                if iBtn and iBtn.Parent then
                    iBtn.Text = ok and "OK!" or "COPY"
                    task.delay(1.2, function() if iBtn and iBtn.Parent then iBtn.Text = "INSERT" end end)
                end
            end)
        end)

        local hitbox = Instance.new("TextButton")
        hitbox.Size = UDim2.new(1, 0, 0, 86); hitbox.BackgroundTransparency = 1; hitbox.Text = ""; hitbox.Active = true; hitbox.Parent = card
        bindClick(hitbox, function() inspectAsset(assetId, nameL.Text, creator) end)

        task.spawn(function()
            local num = tonumber(assetId); if not num then return end
            local s, info = pcall(function() return MarketplaceService:GetProductInfo(num) end)
            if s and info and info.Name and nameL and nameL.Parent then
                nameL.Text = info.Name; subL.Text = "@"..((info.Creator and info.Creator.Name) or creator)
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
        TbGridStatus.Visible = true; TbGridStatus.Text = "Searching..."
        TbStatusLbl.Text = "[.] Mencari: "..TbSearchBox.Text
        task.spawn(function()
            local data = queryMarketplace(selectedCat, TbSearchBox.Text)
            renderGrid(data); TbStatusLbl.Text = "[.] Selesai"
        end)
    end
end
bindClick(TbSearchBtn, execSearch)
TbSearchBox.FocusLost:Connect(function(enter) if enter then execSearch() end end)

bindClick(TbInsertIdBtn, function()
    local id = TbIdBox.Text:gsub("%D+", "")
    if id ~= "" then
        inspectAsset(id, "Memuat...", "?"); TbInsertIdBtn.Text = "..."
        task.spawn(function()
            local ok, m = smartInsert(id); TbStatusLbl.Text = "[.] "..m
            if TbInsertIdBtn and TbInsertIdBtn.Parent then
                TbInsertIdBtn.Text = ok and "OK!" or "COPIED"
                task.delay(1.5, function() if TbInsertIdBtn and TbInsertIdBtn.Parent then TbInsertIdBtn.Text = "INSERT" end end)
            end
        end)
    end
end)

print("[BLUExCrown] ENGINE v5.2 TURBO STABLE LOADED")
