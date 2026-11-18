-- MCHLERN ENGINE STUDIO
-- UI: Vanilla Abu Theme | No Drag | Toggle Left

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local InsertService = game:GetService("InsertService")

local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()

-- ============================================================
-- ENGINE LOADER
-- ============================================================

local ENGINE
do
    local ok, result = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/amelxly-blip/spoofers/main/engine.lua"))()
    end)
    if ok then ENGINE = result
    else
        -- fallback: pakai engine dari file yang sudah di-require
        ENGINE = {
            importRBXM = function() return false, "Engine tidak tersedia" end,
            importRBXL = function() return false, "Engine tidak tersedia" end,
            activateImportRoot = function() return false, "Engine tidak tersedia" end,
            Toolbox = {
                search = function() return nil, "Engine tidak tersedia" end,
                import = function() return false, "Engine tidak tersedia" end,
            }
        }
    end
end

-- ============================================================
-- COLORS / THEME (Vanilla Abu)
-- ============================================================

local C = {
    BG          = Color3.fromRGB(22, 22, 22),
    BG2         = Color3.fromRGB(30, 30, 30),
    BG3         = Color3.fromRGB(40, 40, 40),
    BORDER      = Color3.fromRGB(55, 55, 55),
    ACCENT      = Color3.fromRGB(220, 210, 190),  -- vanilla cream
    ACCENT2     = Color3.fromRGB(180, 170, 155),
    TEXT        = Color3.fromRGB(230, 225, 215),
    TEXT2       = Color3.fromRGB(150, 145, 138),
    SUCCESS     = Color3.fromRGB(100, 180, 120),
    ERROR       = Color3.fromRGB(200, 90, 90),
    WARNING     = Color3.fromRGB(210, 170, 80),
    TRANSPARENT = Color3.fromRGB(0, 0, 0),
}

local FONT = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold
local FONT_LIGHT = Enum.Font.Gotham

-- ============================================================
-- HELPERS
-- ============================================================

local function tween(obj, props, t, style, dir)
    t = t or 0.18
    style = style or Enum.EasingStyle.Quad
    dir = dir or Enum.EasingDirection.Out
    TweenService:Create(obj, TweenInfo.new(t, style, dir), props):Play()
end

local function corner(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = obj
    return c
end

local function stroke(obj, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or C.BORDER
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = obj
    return s
end

local function padding(obj, t, b, l, r)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, t or 8)
    p.PaddingBottom = UDim.new(0, b or 8)
    p.PaddingLeft = UDim.new(0, l or 8)
    p.PaddingRight = UDim.new(0, r or 8)
    p.Parent = obj
    return p
end

local function label(parent, text, size, color, font, xAlign)
    local l = Instance.new("TextLabel")
    l.Text = text
    l.TextSize = size or 13
    l.TextColor3 = color or C.TEXT
    l.Font = font or FONT
    l.BackgroundTransparency = 1
    l.TextXAlignment = xAlign or Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.Size = UDim2.new(1, 0, 0, size and size + 6 or 20)
    l.Parent = parent
    return l
end

local function makeFrame(parent, size, pos, color, trans)
    local f = Instance.new("Frame")
    f.Size = size or UDim2.new(1, 0, 0, 40)
    f.Position = pos or UDim2.new(0, 0, 0, 0)
    f.BackgroundColor3 = color or C.BG2
    f.BackgroundTransparency = trans or 0
    f.BorderSizePixel = 0
    f.Parent = parent
    return f
end

local function makeButton(parent, text, size, pos)
    local btn = Instance.new("TextButton")
    btn.Text = text
    btn.Size = size or UDim2.new(1, 0, 0, 36)
    btn.Position = pos or UDim2.new(0, 0, 0, 0)
    btn.BackgroundColor3 = C.BG3
    btn.TextColor3 = C.ACCENT
    btn.Font = FONT_BOLD
    btn.TextSize = 13
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Parent = parent
    corner(btn, 6)
    stroke(btn, C.BORDER, 1)

    btn.MouseEnter:Connect(function()
        tween(btn, {BackgroundColor3 = Color3.fromRGB(55, 52, 46)}, 0.12)
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, {BackgroundColor3 = C.BG3}, 0.12)
    end)
    btn.MouseButton1Down:Connect(function()
        tween(btn, {BackgroundColor3 = Color3.fromRGB(70, 65, 55)}, 0.08)
    end)
    btn.MouseButton1Up:Connect(function()
        tween(btn, {BackgroundColor3 = Color3.fromRGB(55, 52, 46)}, 0.08)
    end)
    return btn
end

local function makeInput(parent, placeholder, size, pos)
    local box = Instance.new("TextBox")
    box.PlaceholderText = placeholder or "..."
    box.PlaceholderColor3 = C.TEXT2
    box.Text = ""
    box.Size = size or UDim2.new(1, 0, 0, 36)
    box.Position = pos or UDim2.new(0, 0, 0, 0)
    box.BackgroundColor3 = C.BG
    box.TextColor3 = C.TEXT
    box.Font = FONT_LIGHT
    box.TextSize = 13
    box.BorderSizePixel = 0
    box.ClearTextOnFocus = false
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.Parent = parent
    corner(box, 6)
    stroke(box, C.BORDER, 1)
    padding(box, 0, 0, 10, 10)

    box.Focused:Connect(function()
        tween(box, {}, 0.12)
        local s = box:FindFirstChildOfClass("UIStroke")
        if s then tween(s, {Color = C.ACCENT2}, 0.12) end
    end)
    box.FocusLost:Connect(function()
        local s = box:FindFirstChildOfClass("UIStroke")
        if s then tween(s, {Color = C.BORDER}, 0.12) end
    end)
    return box
end

local function makeScroll(parent, size, pos)
    local s = Instance.new("ScrollingFrame")
    s.Size = size or UDim2.new(1, 0, 1, 0)
    s.Position = pos or UDim2.new(0, 0, 0, 0)
    s.BackgroundTransparency = 1
    s.BorderSizePixel = 0
    s.ScrollBarThickness = 3
    s.ScrollBarImageColor3 = C.ACCENT2
    s.CanvasSize = UDim2.new(0, 0, 0, 0)
    s.AutomaticCanvasSize = Enum.AutomaticSize.Y
    s.Parent = parent
    return s
end

-- ============================================================
-- SCREENUI
-- ============================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MCHLERN_ENGINE_STUDIO"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = (RunService:IsStudio() and LP.PlayerGui) or game.CoreGui

-- ============================================================
-- TOGGLE BUTTON (kiri, gambar, no drag)
-- ============================================================

local ToggleBtn = Instance.new("ImageButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Size = UDim2.new(0, 52, 0, 52)
ToggleBtn.Position = UDim2.new(0, 12, 0.5, -26)
ToggleBtn.BackgroundColor3 = C.BG2
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Image = "rbxassetid://137790966470480"
ToggleBtn.ScaleType = Enum.ScaleType.Fit
ToggleBtn.Parent = ScreenGui
corner(ToggleBtn, 12)
stroke(ToggleBtn, C.BORDER, 1)

-- efek glow toggle
local ToggleGlow = Instance.new("ImageLabel")
ToggleGlow.Size = UDim2.new(1.6, 0, 1.6, 0)
ToggleGlow.Position = UDim2.new(-0.3, 0, -0.3, 0)
ToggleGlow.BackgroundTransparency = 1
ToggleGlow.Image = "rbxassetid://5028857472"
ToggleGlow.ImageColor3 = C.ACCENT
ToggleGlow.ImageTransparency = 0.85
ToggleGlow.ZIndex = 0
ToggleGlow.Parent = ToggleBtn

-- ============================================================
-- MAIN WINDOW (no drag)
-- ============================================================

local MainFrame = makeFrame(ScreenGui, UDim2.new(0, 520, 0, 480), UDim2.new(0.5, -260, 0.5, -240), C.BG)
MainFrame.Name = "MainFrame"
MainFrame.Visible = false
corner(MainFrame, 12)
stroke(MainFrame, C.BORDER, 1)

-- shadow effect
local Shadow = Instance.new("ImageLabel")
Shadow.Size = UDim2.new(1, 40, 1, 40)
Shadow.Position = UDim2.new(0, -20, 0, -20)
Shadow.BackgroundTransparency = 1
Shadow.Image = "rbxassetid://5028857472"
Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
Shadow.ImageTransparency = 0.7
Shadow.ZIndex = MainFrame.ZIndex - 1
Shadow.Parent = MainFrame

-- ============================================================
-- HEADER
-- ============================================================

local Header = makeFrame(MainFrame, UDim2.new(1, 0, 0, 52), UDim2.new(0, 0, 0, 0), C.BG2)
Header.Name = "Header"
corner(Header, 12)

-- fix bottom corners header
local HeaderFix = makeFrame(MainFrame, UDim2.new(1, 0, 0, 12), UDim2.new(0, 0, 0, 40), C.BG2)
HeaderFix.BorderSizePixel = 0

-- logo/icon
local HeaderIcon = Instance.new("ImageLabel")
HeaderIcon.Size = UDim2.new(0, 28, 0, 28)
HeaderIcon.Position = UDim2.new(0, 14, 0.5, -14)
HeaderIcon.BackgroundTransparency = 1
HeaderIcon.Image = "rbxassetid://137790966470480"
HeaderIcon.Parent = Header

-- title
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Text = "MCHLERN ENGINE STUDIO"
TitleLabel.Size = UDim2.new(1, -120, 1, 0)
TitleLabel.Position = UDim2.new(0, 50, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3 = C.ACCENT
TitleLabel.Font = FONT_BOLD
TitleLabel.TextSize = 15
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = Header

-- subtitle
local SubLabel = Instance.new("TextLabel")
SubLabel.Text = "RBXM • RBXL • TOOLBOX"
SubLabel.Size = UDim2.new(1, -120, 0, 16)
SubLabel.Position = UDim2.new(0, 50, 0, 28)
SubLabel.BackgroundTransparency = 1
SubLabel.TextColor3 = C.TEXT2
SubLabel.Font = FONT_LIGHT
SubLabel.TextSize = 11
SubLabel.TextXAlignment = Enum.TextXAlignment.Left
SubLabel.Parent = Header

-- close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -44, 0.5, -16)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 70, 70)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = FONT_BOLD
CloseBtn.TextSize = 14
CloseBtn.BorderSizePixel = 0
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = Header
corner(CloseBtn, 8)

CloseBtn.MouseEnter:Connect(function() tween(CloseBtn, {BackgroundColor3 = Color3.fromRGB(220, 90, 90)}, 0.12) end)
CloseBtn.MouseLeave:Connect(function() tween(CloseBtn, {BackgroundColor3 = Color3.fromRGB(180, 70, 70)}, 0.12) end)

-- ============================================================
-- TAB BAR
-- ============================================================

local TabBar = makeFrame(MainFrame, UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, 52), C.BG)
TabBar.Name = "TabBar"

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Padding = UDim.new(0, 4)
TabLayout.Parent = TabBar
padding(TabBar, 4, 4, 8, 8)

local TABS = {"RBXM", "RBXL", "TOOLBOX"}
local TabBtns = {}
local TabPages = {}
local ActiveTab = "RBXM"

-- ============================================================
-- CONTENT AREA
-- ============================================================

local ContentArea = makeFrame(MainFrame, UDim2.new(1, 0, 1, -98), UDim2.new(0, 0, 0, 94), C.BG)
ContentArea.Name = "ContentArea"

-- ============================================================
-- STATUS BAR
-- ============================================================

local StatusBar = makeFrame(MainFrame, UDim2.new(1, 0, 0, 28), UDim2.new(0, 0, 1, -28), C.BG2)
StatusBar.Name = "StatusBar"
corner(StatusBar, 8)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Text = "● READY"
StatusLabel.Size = UDim2.new(1, -16, 1, 0)
StatusLabel.Position = UDim2.new(0, 10, 0, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextColor3 = C.SUCCESS
StatusLabel.Font = FONT_LIGHT
StatusLabel.TextSize = 11
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = StatusBar

local function setStatus(msg, color)
    StatusLabel.Text = "● " .. msg
    StatusLabel.TextColor3 = color or C.SUCCESS
end

-- ============================================================
-- DIVIDER
-- ============================================================

local TabDivider = makeFrame(MainFrame, UDim2.new(1, -16, 0, 1), UDim2.new(0, 8, 0, 92), C.BORDER)
TabDivider.Name = "Divider"

-- ============================================================
-- PAGE BUILDER
-- ============================================================

local function makePage(name)
    local page = makeFrame(ContentArea, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), C.BG)
    page.Name = name .. "Page"
    page.Visible = false
    local scroll = makeScroll(page, UDim2.new(1, -8, 1, -8), UDim2.new(0, 4, 0, 4))
    local list = Instance.new("UIListLayout")
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, 8)
    list.Parent = scroll
    padding(scroll, 4, 4, 4, 4)
    TabPages[name] = {frame = page, scroll = scroll}
    return page, scroll
end

local function sectionLabel(scroll, text, order)
    local lbl = Instance.new("TextLabel")
    lbl.Text = text
    lbl.Size = UDim2.new(1, -8, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = C.ACCENT2
    lbl.Font = FONT_BOLD
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = order or 0
    lbl.Parent = scroll
    return lbl
end

local function card(scroll, h, order)
    local c = makeFrame(scroll, UDim2.new(1, -8, 0, h or 80), nil, C.BG2)
    c.LayoutOrder = order or 1
    corner(c, 8)
    stroke(c, C.BORDER, 1)
    padding(c, 10, 10, 12, 12)
    return c
end

-- ============================================================
-- TAB SWITCHING
-- ============================================================

local function switchTab(name)
    ActiveTab = name
    for _, t in pairs(TABS) do
        local btn = TabBtns[t]
        local page = TabPages[t]
        if t == name then
            tween(btn, {BackgroundColor3 = C.BG3, TextColor3 = C.ACCENT}, 0.15)
            local s = btn:FindFirstChildOfClass("UIStroke")
            if s then tween(s, {Color = C.ACCENT2}, 0.15) end
            if page then page.frame.Visible = true end
        else
            tween(btn, {BackgroundColor3 = C.BG, TextColor3 = C.TEXT2}, 0.15)
            local s = btn:FindFirstChildOfClass("UIStroke")
            if s then tween(s, {Color = C.BORDER}, 0.15) end
            if page then page.frame.Visible = false end
        end
    end
end

for i, tabName in ipairs(TABS) do
    local btn = Instance.new("TextButton")
    btn.Text = tabName
    btn.Size = UDim2.new(0, 100, 1, 0)
    btn.BackgroundColor3 = C.BG
    btn.TextColor3 = C.TEXT2
    btn.Font = FONT_BOLD
    btn.TextSize = 12
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.LayoutOrder = i
    btn.Parent = TabBar
    corner(btn, 6)
    stroke(btn, C.BORDER, 1)

    btn.MouseEnter:Connect(function()
        if ActiveTab ~= tabName then
            tween(btn, {BackgroundColor3 = C.BG3}, 0.12)
        end
    end)
    btn.MouseLeave:Connect(function()
        if ActiveTab ~= tabName then
            tween(btn, {BackgroundColor3 = C.BG}, 0.12)
        end
    end)
    btn.MouseButton1Click:Connect(function()
        switchTab(tabName)
    end)
    TabBtns[tabName] = btn
end

-- ============================================================
-- PAGE: RBXM
-- ============================================================

local rbxmPage, rbxmScroll = makePage("RBXM")

sectionLabel(rbxmScroll, "▸ IMPORT FILE RBXM / RBXMX", 1)

local rbxmCard = card(rbxmScroll, 130, 2)

local rbxmPathInput = makeInput(rbxmCard, "Path file .rbxm atau .rbxmx...", UDim2.new(1, 0, 0, 36))
rbxmPathInput.LayoutOrder = 1

local rbxmNameInput = makeInput(rbxmCard, "Nama model (opsional)...", UDim2.new(1, 0, 0, 36))
rbxmNameInput.LayoutOrder = 2
rbxmNameInput.Position = UDim2.new(0, 0, 0, 44)

local rbxmList = Instance.new("UIListLayout")
rbxmList.SortOrder = Enum.SortOrder.LayoutOrder
rbxmList.Padding = UDim.new(0, 8)
rbxmList.Parent = rbxmCard

local rbxmImportBtn = makeButton(rbxmCard, "⬆  IMPORT RBXM", UDim2.new(1, 0, 0, 36))
rbxmImportBtn.LayoutOrder = 3

sectionLabel(rbxmScroll, "▸ IMPORT VIA ASSET ID", 3)

local rbxmIdCard = card(rbxmScroll, 90, 4)

local rbxmIdInput = makeInput(rbxmIdCard, "Asset ID (contoh: 123456789)...", UDim2.new(1, 0, 0, 36))
rbxmIdInput.LayoutOrder = 1

local rbxmIdList = Instance.new("UIListLayout")
rbxmIdList.SortOrder = Enum.SortOrder.LayoutOrder
rbxmIdList.Padding = UDim.new(0, 8)
rbxmIdList.Parent = rbxmIdCard

local rbxmIdBtn = makeButton(rbxmIdCard, "⬆  IMPORT DARI ID", UDim2.new(1, 0, 0, 36))
rbxmIdBtn.LayoutOrder = 2

-- RBXM handlers
rbxmImportBtn.MouseButton1Click:Connect(function()
    local path = rbxmPathInput.Text
    local name = rbxmNameInput.Text
    if path == "" then setStatus("PATH KOSONG!", C.ERROR); return end
    setStatus("IMPORTING " .. path .. "...", C.WARNING)
    task.spawn(function()
        local fileInfo = {path = path, name = name ~= "" and name or nil}
        local ok, msg = pcall(function()
            local ok2, msg2, root = ENGINE.importRBXM(fileInfo)
            if ok2 and root then
                root.Parent = workspace
                return true, msg2
            end
            return ok2, msg2
        end)
        if ok then
            setStatus("RBXM BERHASIL DIIMPORT", C.SUCCESS)
        else
            setStatus("GAGAL: " .. tostring(msg), C.ERROR)
        end
    end)
end)

rbxmIdBtn.MouseButton1Click:Connect(function()
    local id = rbxmIdInput.Text
    if id == "" then setStatus("ID KOSONG!", C.ERROR); return end
    setStatus("LOADING ASSET " .. id .. "...", C.WARNING)
    task.spawn(function()
        local ok, result = pcall(function()
            local objs = game:GetObjects("rbxassetid://" .. id)
            if objs and #objs > 0 then
                for _, o in ipairs(objs) do o.Parent = workspace end
                return true, #objs .. " objek diimport"
            end
            local model = InsertService:LoadAsset(tonumber(id))
            if model then
                for _, c in ipairs(model:GetChildren()) do c.Parent = workspace end
                model:Destroy()
                return true, "model diimport dari InsertService"
            end
            return false, "gagal load asset"
        end)
        if ok then
            setStatus("ASSET " .. id .. " BERHASIL", C.SUCCESS)
        else
            setStatus("GAGAL: " .. tostring(result), C.ERROR)
        end
    end)
end)

-- ============================================================
-- PAGE: RBXL
-- ============================================================

local rbxlPage, rbxlScroll = makePage("RBXL")

sectionLabel(rbxlScroll, "▸ IMPORT FILE RBXL / RBXLX", 1)

local rbxlCard = card(rbxlScroll, 90, 2)

local rbxlPathInput = makeInput(rbxlCard, "Path file .rbxl atau .rbxlx...", UDim2.new(1, 0, 0, 36))
rbxlPathInput.LayoutOrder = 1

local rbxlList = Instance.new("UIListLayout")
rbxlList.SortOrder = Enum.SortOrder.LayoutOrder
rbxlList.Padding = UDim.new(0, 8)
rbxlList.Parent = rbxlCard

local rbxlImportBtn = makeButton(rbxlCard, "⬆  IMPORT RBXL (STAGE)", UDim2.new(1, 0, 0, 36))
rbxlImportBtn.LayoutOrder = 2

sectionLabel(rbxlScroll, "▸ ACTIVATE STAGED PLACE", 3)

local rbxlActCard = card(rbxlScroll, 60, 4)

local rbxlActList = Instance.new("UIListLayout")
rbxlActList.SortOrder = Enum.SortOrder.LayoutOrder
rbxlActList.Padding = UDim.new(0, 8)
rbxlActList.Parent = rbxlActCard

local rbxlActivateBtn = makeButton(rbxlActCard, "▶  ACTIVATE IMPORT ROOT", UDim2.new(1, 0, 0, 36))
rbxlActivateBtn.LayoutOrder = 1

local stagedImportRoot = nil

local function readFileAuto(path)
    if readfile then
        return readfile(path)
    end
    error("readfile tidak tersedia di executor ini")
end

rbxlImportBtn.MouseButton1Click:Connect(function()
    local path = rbxlPathInput.Text
    if path == "" then setStatus("PATH KOSONG!", C.ERROR); return end
    setStatus("STAGING " .. path .. "...", C.WARNING)
    task.spawn(function()
        local ok, msg = pcall(function()
            local data = readFileAuto(path)
            local fileInfo = {path = path, name = path:match("([^/\\]+)$"), data = data}
            local ok2, msg2, root = ENGINE.importRBXL(fileInfo)
            if ok2 then stagedImportRoot = root end
            return ok2, msg2
        end)
        if ok then
            setStatus("STAGED! KLIK ACTIVATE", C.WARNING)
        else
            setStatus("GAGAL: " .. tostring(msg), C.ERROR)
        end
    end)
end)

rbxlActivateBtn.MouseButton1Click:Connect(function()
    if not stagedImportRoot then
        setStatus("BELUM ADA STAGED PLACE!", C.ERROR); return
    end
    setStatus("ACTIVATING...", C.WARNING)
    task.spawn(function()
        local ok, msg = pcall(function()
            return ENGINE.activateImportRoot(stagedImportRoot)
        end)
        if ok then
            setStatus("RBXL AKTIF!", C.SUCCESS)
            stagedImportRoot = nil
        else
            setStatus("GAGAL: " .. tostring(msg), C.ERROR)
        end
    end)
end)

-- ============================================================
-- PAGE: TOOLBOX
-- ============================================================

local tbPage, tbScroll = makePage("TOOLBOX")

sectionLabel(tbScroll, "▸ SEARCH TOOLBOX ROBLOX", 1)

local tbSearchCard = card(tbScroll, 130, 2)
local tbSearchList = Instance.new("UIListLayout")
tbSearchList.SortOrder = Enum.SortOrder.LayoutOrder
tbSearchList.Padding = UDim.new(0, 8)
tbSearchList.Parent = tbSearchCard

-- kategori
local tbCatFrame = makeFrame(tbSearchCard, UDim2.new(1, 0, 0, 36), nil, C.BG)
tbCatFrame.LayoutOrder = 1
corner(tbCatFrame, 6)
stroke(tbCatFrame, C.BORDER, 1)

local tbCatLayout = Instance.new("UIListLayout")
tbCatLayout.FillDirection = Enum.FillDirection.Horizontal
tbCatLayout.SortOrder = Enum.SortOrder.LayoutOrder
tbCatLayout.Padding = UDim.new(0, 2)
tbCatLayout.Parent = tbCatFrame
padding(tbCatFrame, 4, 4, 4, 4)

local TB_CAT_LIST = {"Model", "Mesh", "Decal", "Audio"}
local tbCatBtns = {}
local tbActiveCat = "Model"

for i, cat in ipairs(TB_CAT_LIST) do
    local cb = Instance.new("TextButton")
    cb.Text = cat
    cb.Size = UDim2.new(0.24, -2, 1, 0)
    cb.BackgroundColor3 = i == 1 and C.BG3 or C.BG
    cb.TextColor3 = i == 1 and C.ACCENT or C.TEXT2
    cb.Font = FONT_BOLD
    cb.TextSize = 11
    cb.BorderSizePixel = 0
    cb.AutoButtonColor = false
    cb.LayoutOrder = i
    cb.Parent = tbCatFrame
    corner(cb, 4)

    cb.MouseButton1Click:Connect(function()
        tbActiveCat = cat
        for _, c2 in pairs(tbCatBtns) do
            tween(c2, {BackgroundColor3 = C.BG, TextColor3 = C.TEXT2}, 0.1)
        end
        tween(cb, {BackgroundColor3 = C.BG3, TextColor3 = C.ACCENT}, 0.1)
    end)
    tbCatBtns[cat] = cb
end

local tbQueryInput = makeInput(tbSearchCard, "Cari nama atau masukkan ID...", UDim2.new(1, 0, 0, 36))
tbQueryInput.LayoutOrder = 2

local tbSearchBtn = makeButton(tbSearchCard, "🔍  SEARCH", UDim2.new(1, 0, 0, 36))
tbSearchBtn.LayoutOrder = 3

sectionLabel(tbScroll, "▸ HASIL PENCARIAN", 3)

local tbResultCard = card(tbScroll, 220, 4)
tbResultCard.ClipsDescendants = true

local tbResultScroll = makeScroll(tbResultCard, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0))
local tbResultList = Instance.new("UIListLayout")
tbResultList.SortOrder = Enum.SortOrder.LayoutOrder
tbResultList.Padding = UDim.new(0, 4)
tbResultList.Parent = tbResultScroll

local tbResults = {}
local tbPage2 = 0
local tbHasMore = false
local tbLastQuery = ""

local function clearTbResults()
    for _, v in ipairs(tbResults) do pcall(function() v:Destroy() end) end
    tbResults = {}
end

local function addTbResult(item, idx)
    local row = makeFrame(tbResultScroll, UDim2.new(1, -4, 0, 44), nil, C.BG3)
    row.LayoutOrder = idx
    corner(row, 6)
    stroke(row, C.BORDER, 1)

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Text = item.name or ("Asset " .. item.id)
    nameLabel.Size = UDim2.new(1, -90, 0, 20)
    nameLabel.Position = UDim2.new(0, 10, 0, 4)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = C.TEXT
    nameLabel.Font = FONT_BOLD
    nameLabel.TextSize = 12
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = row

    local creatorLabel = Instance.new("TextLabel")
    creatorLabel.Text = item.creator or "Unknown"
    creatorLabel.Size = UDim2.new(1, -90, 0, 16)
    creatorLabel.Position = UDim2.new(0, 10, 0, 24)
    creatorLabel.BackgroundTransparency = 1
    creatorLabel.TextColor3 = C.TEXT2
    creatorLabel.Font = FONT_LIGHT
    creatorLabel.TextSize = 10
    creatorLabel.TextXAlignment = Enum.TextXAlignment.Left
    creatorLabel.Parent = row

    local importBtn = makeButton(row, "IMPORT", UDim2.new(0, 72, 0, 28))
    importBtn.Position = UDim2.new(1, -82, 0.5, -14)
    importBtn.TextSize = 11

    importBtn.MouseButton1Click:Connect(function()
        setStatus("IMPORTING " .. item.catKey .. " " .. item.id .. "...", C.WARNING)
        task.spawn(function()
            local ok, msg = ENGINE.Toolbox.import(item.catKey, item.id)
            if ok then
                setStatus("BERHASIL: " .. tostring(msg), C.SUCCESS)
            else
                setStatus("GAGAL: " .. tostring(msg), C.ERROR)
            end
        end)
    end)

    tbResults[#tbResults + 1] = row
end

local function httpReq(opts)
    if request then return request(opts) end
    if http_request then return http_request(opts) end
    if syn and syn.request then return syn.request(opts) end
    error("executor tidak punya request function")
end

local function doSearch(resetPage)
    local query = tbQueryInput.Text
    if query == "" then setStatus("QUERY KOSONG!", C.ERROR); return end
    if resetPage then tbPage2 = 0; clearTbResults() end
    tbLastQuery = query
    setStatus("SEARCHING " .. tbActiveCat .. ": " .. query .. "...", C.WARNING)
    task.spawn(function()
        local ok, results, hasMore = pcall(function()
            return ENGINE.Toolbox.search(tbActiveCat, query, tbPage2, httpReq)
        end)
        if ok and results then
            tbHasMore = hasMore
            for i, item in ipairs(results) do
                addTbResult(item, #tbResults + i)
            end
            setStatus(("DITEMUKAN %d HASIL"):format(#tbResults), C.SUCCESS)
        else
            setStatus("GAGAL: " .. tostring(results), C.ERROR)
        end
    end)
end

tbSearchBtn.MouseButton1Click:Connect(function() doSearch(true) end)

tbQueryInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then doSearch(true) end
end)

-- load more
local tbMoreBtn = makeButton(tbScroll, "⬇  LOAD MORE", UDim2.new(1, -8, 0, 32), nil)
tbMoreBtn.LayoutOrder = 5

tbMoreBtn.MouseButton1Click:Connect(function()
    if tbHasMore then
        tbPage2 = tbPage2 + 1
        doSearch(false)
    else
        setStatus("TIDAK ADA HASIL LEBIH BANYAK", C.TEXT2)
    end
end)

-- ============================================================
-- TOGGLE LOGIC
-- ============================================================

local uiOpen = false

local function openUI()
    uiOpen = true
    MainFrame.Visible = true
    MainFrame.Size = UDim2.new(0, 520, 0, 0)
    MainFrame.Position = UDim2.new(0.5, -260, 0.5, 0)
    tween(MainFrame, {
        Size = UDim2.new(0, 520, 0, 480),
        Position = UDim2.new(0.5, -260, 0.5, -240)
    }, 0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    tween(ToggleGlow, {ImageTransparency = 0.6}, 0.2)
    switchTab("RBXM")
end

local function closeUI()
    uiOpen = false
    tween(MainFrame, {
        Size = UDim2.new(0, 520, 0, 0),
        Position = UDim2.new(0.5, -260, 0.5, 0)
    }, 0.18)
    tween(ToggleGlow, {ImageTransparency = 0.85}, 0.2)
    task.delay(0.2, function() MainFrame.Visible = false end)
end

ToggleBtn.MouseButton1Click:Connect(function()
    if uiOpen then closeUI() else openUI() end
end)

CloseBtn.MouseButton1Click:Connect(closeUI)

-- efek hover toggle
ToggleBtn.MouseEnter:Connect(function()
    tween(ToggleBtn, {BackgroundColor3 = C.BG3}, 0.12)
    tween(ToggleGlow, {ImageTransparency = 0.7}, 0.12)
end)
ToggleBtn.MouseLeave:Connect(function()
    tween(ToggleBtn, {BackgroundColor3 = C.BG2}, 0.12)
    tween(ToggleGlow, {ImageTransparency = uiOpen and 0.6 or 0.85}, 0.12)
end)

-- ============================================================
-- INIT
-- ============================================================

switchTab("RBXM")
setStatus("READY — MCHLERN ENGINE STUDIO", C.SUCCESS)
