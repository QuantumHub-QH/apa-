--[[
       MCHLERN TOOLS KIT v2.3
       Credits: MCHLERN PROJECT
       Supports: RBXM, RBXL, RBXLX, RBXMX
]]

if not game:IsLoaded() then game.Loaded:Wait() end

-- WHITELIST
local _WHITELIST = { 10955292268 }
local _userId = game:GetService("Players").LocalPlayer.UserId
local _allowed = false
for _, id in ipairs(_WHITELIST) do if id == _userId then _allowed = true; break end end
if not _allowed then warn("[MCHLERN] Akses ditolak."); return end

-- SERVICES
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local CoreGui           = game:GetService("CoreGui")
local TweenService      = game:GetService("TweenService")
local StarterGui        = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local CoreDest    = pcall(function() return CoreGui.Name end) and CoreGui or LocalPlayer:WaitForChild("PlayerGui")

_G.MCHLERN_RAW_SOURCES = _G.MCHLERN_RAW_SOURCES or {}

-- ICONS
local ICO = {
    DOWNLOAD  = "rbxassetid://10709791283",
    SETTINGS  = "rbxassetid://10709780517",
    REPLACE   = "rbxassetid://10709793230",
    PAINT     = "rbxassetid://10709791334",
    TOGGLE    = "rbxassetid://108255697601622",
    CHEVRON_L = "rbxassetid://10709782230",
    CHECK     = "rbxassetid://10709790240",
    ALERT     = "rbxassetid://10709790520",
    SEARCH    = "rbxassetid://10709796118",
    REFRESH   = "rbxassetid://10709793382",
    FOLDER    = "rbxassetid://10709790172",
}

-- COLORS (black/white theme)
local C_BG       = Color3.fromRGB(15, 15, 15)
local C_SIDEBAR  = Color3.fromRGB(10, 10, 10)
local C_TITLEBAR = Color3.fromRGB(20, 20, 20)
local C_CARD     = Color3.fromRGB(28, 28, 28)
local C_CARD2    = Color3.fromRGB(35, 35, 35)
local C_STROKE   = Color3.fromRGB(60, 60, 60)
local C_TAB_ACT  = Color3.fromRGB(50, 50, 50)
local C_ACCENT   = Color3.fromRGB(180, 180, 180)
local C_BTN      = Color3.fromRGB(60, 60, 60)
local C_BTN2     = Color3.fromRGB(40, 40, 40)
local C_RED      = Color3.fromRGB(150, 40, 40)
local C_BLUE     = Color3.fromRGB(40, 80, 140)
local C_WHITE    = Color3.fromRGB(255, 255, 255)
local C_SUBTEXT  = Color3.fromRGB(170, 170, 170)
local C_TOGBG    = Color3.fromRGB(20, 20, 20)

-- HELPERS
local function mkCorner(p, r) local c = Instance.new("UICorner", p); c.CornerRadius = UDim.new(0, r or 6); return c end
local function mkStroke(p, t, col) local s = Instance.new("UIStroke", p); s.Thickness = t or 1; s.Color = col or C_STROKE; return s end
local function mkPad(p, t, b, l, r) local pd = Instance.new("UIPadding", p); pd.PaddingTop=UDim.new(0,t or 0); pd.PaddingBottom=UDim.new(0,b or 0); pd.PaddingLeft=UDim.new(0,l or 0); pd.PaddingRight=UDim.new(0,r or 0); return pd end

-- IMPORTER CORE
local SVC_MAP = {Workspace=workspace, ReplicatedStorage=ReplicatedStorage, Lighting=game:GetService("Lighting"), ServerScriptService=ReplicatedStorage, ServerStorage=ReplicatedStorage}
local function insertObjects(objects, isRbxl)
    local n = 0
    for _, obj in ipairs(objects) do pcall(function()
        if isRbxl then
            local tgt = SVC_MAP[obj.ClassName] or SVC_MAP[obj.Name] or workspace
            local ch = obj:GetChildren()
            if #ch > 0 then for _, c in ipairs(ch) do c.Parent = tgt; n = n+1 end
            else obj.Parent = workspace; n = n+1 end
        else obj.Parent = workspace; n = n+1 end
    end) end
    return n
end
local function loadFile(fi)
    local isRbxl = fi.ftype == "RBXL"
    if getcustomasset then
        local ok1, aid = pcall(getcustomasset, fi.path)
        if ok1 and aid then
            local ok2, objs = pcall(function() return game:GetObjects(aid) end)
            if ok2 and objs and #objs > 0 then return true, insertObjects(objs, isRbxl).." inserted" end
        end
    end
    local ok3, o3 = pcall(function() return game:GetObjects("rbxasset://"..fi.path) end)
    if ok3 and o3 and #o3 > 0 then return true, insertObjects(o3, isRbxl).." inserted" end
    return false, "Gagal memuat file."
end
local function safeListFiles(p) if not listfiles then return nil end; local ok,f=pcall(listfiles,p); return ok and f or nil end
local function scanDeep(folder, depth, results, seen)
    if depth > 3 or seen[folder] then return end; seen[folder] = true
    local list = safeListFiles(folder); if not list then return end
    for _, path in ipairs(list) do
        local name = path:match("([^/]+)$") or path; local nLow = name:lower()
        if nLow:match("%.rbxlx?$") or nLow:match("%.rbxmx?$") then
            if not seen[path] then seen[path]=true; table.insert(results, {name=name, path=path, ftype=nLow:match("%.rbxl") and "RBXL" or "RBXM", folder=folder}) end
        elseif not name:match("%.[%a%d]+") then scanDeep(path, depth+1, results, seen) end
    end
end
local function scanAll()
    local results, seen = {}, {}
    for _, p in ipairs({"workspace","Delta/workspace","delta/workspace","Android/Delta/workspace",".","",}) do scanDeep(p, 0, results, seen) end
    return results
end

-- DESTROY OLD UI
if CoreDest:FindFirstChild("MCHLERNToolsKit") then CoreDest:FindFirstChild("MCHLERNToolsKit"):Destroy() end

local UI = Instance.new("ScreenGui", CoreDest)
UI.Name = "MCHLERNToolsKit"; UI.ResetOnSpawn = false; UI.IgnoreGuiInset = true

-- FLOATING TOGGLE BUTTON
local TF = Instance.new("Frame", UI)
TF.Size = UDim2.new(0, 38, 0, 38); TF.Position = UDim2.new(0, 12, 0, 50)
TF.BackgroundColor3 = C_TOGBG; TF.BorderSizePixel = 0; TF.Active = true
mkCorner(TF, 8); mkStroke(TF, 1, Color3.fromRGB(80,80,80))

local TFIcon = Instance.new("ImageLabel", TF)
TFIcon.Size = UDim2.new(0, 24, 0, 24); TFIcon.Position = UDim2.new(0.5,-12,0.5,-12)
TFIcon.BackgroundTransparency = 1; TFIcon.Image = ICO.TOGGLE; TFIcon.ImageColor3 = C_WHITE

local TFBtn = Instance.new("TextButton", TF)
TFBtn.Size = UDim2.new(1,0,1,0); TFBtn.BackgroundTransparency = 1; TFBtn.Text = ""

local tDrag, tDragStart, tStart
TF.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        tDrag = true; tDragStart = inp.Position; tStart = TF.Position end end)
UserInputService.InputChanged:Connect(function(inp)
    if tDrag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
        local d = inp.Position - tDragStart
        TF.Position = UDim2.new(tStart.X.Scale, tStart.X.Offset+d.X, tStart.Y.Scale, tStart.Y.Offset+d.Y) end end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then tDrag = false end end)

-- MAIN PANEL
local Main = Instance.new("Frame", UI)
Main.Name = "MainFrame"; Main.Size = UDim2.new(0, 570, 0, 370)
Main.Position = UDim2.new(0.5,-285,0.5,-185); Main.BackgroundColor3 = C_BG
Main.BorderSizePixel = 0; Main.ClipsDescendants = true
mkCorner(Main, 8); mkStroke(Main, 1, Color3.fromRGB(55,55,55))

TFBtn.MouseButton1Click:Connect(function()
    Main.Visible = not Main.Visible
    TFIcon.Image = Main.Visible and ICO.TOGGLE or ICO.CHEVRON_L
end)

-- NOTIFY
local function notify(title, msg, col)
    col = col or Color3.fromRGB(180,180,180)
    local N = Instance.new("Frame", UI)
    N.Size = UDim2.new(0,230,0,44); N.Position = UDim2.new(1,-240,1,-54)
    N.BackgroundColor3 = Color3.fromRGB(18,18,18); N.BorderSizePixel = 0
    mkCorner(N, 6); mkStroke(N, 1, col)
    local t = Instance.new("TextLabel", N)
    t.Size = UDim2.new(1,-10,0,16); t.Position = UDim2.new(0,8,0,4)
    t.BackgroundTransparency=1; t.Text=title; t.TextColor3=C_WHITE; t.Font=Enum.Font.GothamBold; t.TextSize=11; t.TextXAlignment=Enum.TextXAlignment.Left
    local d = Instance.new("TextLabel", N)
    d.Size = UDim2.new(1,-10,0,16); d.Position = UDim2.new(0,8,0,22)
    d.BackgroundTransparency=1; d.Text=msg; d.TextColor3=C_SUBTEXT; d.Font=Enum.Font.Gotham; d.TextSize=9; d.TextXAlignment=Enum.TextXAlignment.Left; d.TextWrapped=true
    task.spawn(function()
        task.wait(2.5)
        for i=1,10 do N.BackgroundTransparency=i/10; t.TextTransparency=i/10; d.TextTransparency=i/10; task.wait(0.02) end
        N:Destroy()
    end)
end

-- TITLE BAR
local TB = Instance.new("Frame", Main)
TB.Size = UDim2.new(1,0,0,38); TB.BackgroundColor3 = C_TITLEBAR; mkCorner(TB, 8)
local mkDrag = function(frame, target)
    local drag, ds, sp
    frame.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            drag=true; ds=inp.Position; sp=target.Position end end)
    UserInputService.InputChanged:Connect(function(inp)
        if drag and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
            local d=inp.Position-ds; target.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y) end end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then drag=false end end)
end
mkDrag(TB, Main)

local TitleL = Instance.new("TextLabel", TB)
TitleL.Size = UDim2.new(1,-80,1,0); TitleL.Position = UDim2.new(0,14,0,0)
TitleL.BackgroundTransparency=1; TitleL.Text="MCHLERN TOOLS KIT"
TitleL.TextColor3=C_WHITE; TitleL.Font=Enum.Font.GothamBold; TitleL.TextSize=13; TitleL.TextXAlignment=Enum.TextXAlignment.Left

local CloseB = Instance.new("TextButton", TB)
CloseB.Size=UDim2.new(0,28,0,28); CloseB.Position=UDim2.new(1,-34,0.5,-14)
CloseB.BackgroundColor3=Color3.fromRGB(45,45,45); CloseB.Text="✕"; CloseB.TextColor3=C_WHITE
CloseB.Font=Enum.Font.GothamBold; CloseB.TextSize=13; mkCorner(CloseB, 5)
CloseB.MouseButton1Click:Connect(function() Main.Visible=false; TFIcon.Image=ICO.TOGGLE end)

-- SIDEBAR
local SB = Instance.new("Frame", Main)
SB.Size=UDim2.new(0,115,1,-38); SB.Position=UDim2.new(0,0,0,38)
SB.BackgroundColor3=C_SIDEBAR; SB.BorderSizePixel=0; mkStroke(SB,1,Color3.fromRGB(40,40,40))

-- CONTENT
local CA = Instance.new("Frame", Main)
CA.Size=UDim2.new(1,-115,1,-38); CA.Position=UDim2.new(0,115,0,38)
CA.BackgroundTransparency=1

local Tabs = {}
local function mkTab(name, ico, y)
    local btn = Instance.new("TextButton", SB)
    btn.Size=UDim2.new(1,0,0,42); btn.Position=UDim2.new(0,0,0,y)
    btn.BackgroundColor3=C_SIDEBAR; btn.BorderSizePixel=0
    btn.Text="       "..name; btn.TextColor3=C_SUBTEXT; btn.Font=Enum.Font.GothamBold; btn.TextSize=10; btn.TextXAlignment=Enum.TextXAlignment.Left
    local ic = Instance.new("ImageLabel", btn)
    ic.Size=UDim2.new(0,15,0,15); ic.Position=UDim2.new(0,9,0.5,-7)
    ic.BackgroundTransparency=1; ic.Image=ico; ic.ImageColor3=C_SUBTEXT
    local frame = Instance.new("Frame", CA)
    frame.Size=UDim2.new(1,0,1,0); frame.BackgroundTransparency=1; frame.Visible=false
    table.insert(Tabs, {Btn=btn, Frame=frame, Ic=ic})
    btn.MouseButton1Click:Connect(function()
        for _, t in ipairs(Tabs) do
            t.Frame.Visible=false; t.Btn.BackgroundColor3=C_SIDEBAR; t.Btn.TextColor3=C_SUBTEXT; t.Ic.ImageColor3=C_SUBTEXT end
        frame.Visible=true; btn.BackgroundColor3=C_TAB_ACT; btn.TextColor3=C_WHITE; ic.ImageColor3=C_WHITE
    end)
    return frame
end

local TImport  = mkTab("IMPORTER", ICO.DOWNLOAD, 0)
local TConfig  = mkTab("CONFIG",   ICO.SETTINGS, 42)
local TReplace = mkTab("REPLACER", ICO.REPLACE,  84)
local TRemake  = mkTab("REMAKE GUI",ICO.PAINT,   126)

-- HELPER: Generic Button
local function mkBtn(parent, text, x, y, w, h, col)
    local f = Instance.new("Frame", parent)
    f.Size=UDim2.new(w or 1,-20,0,h or 28); f.Position=UDim2.new(x or 0,10,0,y or 0)
    f.BackgroundColor3=col or C_BTN; mkCorner(f,5)
    local b = Instance.new("TextButton", f)
    b.Size=UDim2.new(1,0,1,0); b.BackgroundTransparency=1; b.Text=text
    b.TextColor3=C_WHITE; b.Font=Enum.Font.GothamBold; b.TextSize=10
    return f, b
end

-- HELPER: Label
local function mkLabel(parent, text, x, y, w, h, sz)
    local l = Instance.new("TextLabel", parent)
    l.Size=UDim2.new(w or 1,-20,0,h or 16); l.Position=UDim2.new(x or 0,10,0,y or 0)
    l.BackgroundTransparency=1; l.Text=text; l.TextColor3=C_SUBTEXT
    l.Font=Enum.Font.Gotham; l.TextSize=sz or 10; l.TextXAlignment=Enum.TextXAlignment.Left
    return l
end

-- HELPER: TextBox
local function mkBox(parent, placeholder, x, y, w, h)
    local f = Instance.new("Frame", parent)
    f.Size=UDim2.new(w or 1,-20,0,h or 26); f.Position=UDim2.new(x or 0,10,0,y or 0)
    f.BackgroundColor3=C_CARD2; mkCorner(f,4); mkStroke(f,1,Color3.fromRGB(55,55,55))
    local b = Instance.new("TextBox", f)
    b.Size=UDim2.new(1,-10,1,0); b.Position=UDim2.new(0,6,0,0)
    b.BackgroundTransparency=1; b.Text=""; b.PlaceholderText=placeholder
    b.TextColor3=C_WHITE; b.PlaceholderColor3=C_SUBTEXT; b.Font=Enum.Font.Gotham; b.TextSize=11
    b.TextXAlignment=Enum.TextXAlignment.Left; b.ClearTextOnFocus=false
    return f, b
end

-- HELPER: Scroll
local function mkScroll(parent, x, y, w, h)
    local s = Instance.new("ScrollingFrame", parent)
    s.Size=UDim2.new(w or 1,-20,0,h); s.Position=UDim2.new(x or 0,10,0,y)
    s.BackgroundTransparency=1; s.ScrollBarThickness=4
    s.ScrollBarImageColor3=Color3.fromRGB(80,80,80); s.AutomaticCanvasSize=Enum.AutomaticSize.Y
    local l = Instance.new("UIListLayout", s); l.Padding=UDim.new(0,4)
    return s, l
end

-- HELPER: Row Card
local function mkRow(parent, bg)
    local f = Instance.new("Frame", parent)
    f.Size=UDim2.new(1,0,0,32); f.BackgroundColor3=bg or C_CARD; mkCorner(f,4)
    return f
end

-- =========================================================================
-- TAB 1: IMPORTER
-- =========================================================================
local allFiles = {}
local function buildImporterCards(scroll, files)
    for _, c in ipairs(scroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    for _, f in ipairs(files) do
        local card = mkRow(scroll)
        local typeBadge = Instance.new("Frame", card)
        typeBadge.Size=UDim2.new(0,46,0,18); typeBadge.Position=UDim2.new(0,6,0.5,-9)
        typeBadge.BackgroundColor3=f.ftype=="RBXL" and Color3.fromRGB(50,80,130) or Color3.fromRGB(50,50,50); mkCorner(typeBadge,3)
        local bt = Instance.new("TextLabel", typeBadge)
        bt.Size=UDim2.new(1,0,1,0); bt.BackgroundTransparency=1; bt.Text=f.ftype
        bt.TextColor3=C_WHITE; bt.Font=Enum.Font.GothamBold; bt.TextSize=9
        local lbl = Instance.new("TextLabel", card)
        lbl.Size=UDim2.new(1,-120,1,0); lbl.Position=UDim2.new(0,58,0,0)
        lbl.BackgroundTransparency=1; lbl.Text=f.name; lbl.TextColor3=C_WHITE
        lbl.Font=Enum.Font.GothamBold; lbl.TextSize=10; lbl.TextXAlignment=Enum.TextXAlignment.Left
        lbl.TextTruncate=Enum.TextTruncate.AtEnd
        local insF, insB = mkBtn(card, "INSERT", 1, 0.5, 0, 22, C_BTN)
        insF.Size=UDim2.new(0,60,0,22); insF.Position=UDim2.new(1,-68,0.5,-11); insF.AnchorPoint=Vector2.new(0,0)
        insB.MouseButton1Click:Connect(function()
            insB.Text="..."; local ok,msg=loadFile(f)
            if ok then insB.Text="DONE"; notify("Success", f.name.." dimuat", Color3.fromRGB(100,200,100))
            else insB.Text="FAIL"; notify("Error", msg, Color3.fromRGB(200,80,80)) end
            task.wait(2); insB.Text="INSERT"
        end)
    end
end

-- Search bar
local searchBarF, searchBox = mkBox(TImport, "Cari nama file...", 0, 8, 1, 26)
local searchIcon = Instance.new("ImageLabel", searchBarF)
searchIcon.Size=UDim2.new(0,14,0,14); searchIcon.Position=UDim2.new(1,-18,0.5,-7)
searchIcon.BackgroundTransparency=1; searchIcon.Image=ICO.SEARCH; searchIcon.ImageColor3=C_SUBTEXT

local _, scanBtnActual = mkBtn(TImport, "SCAN FILES", 0, 42, 1, 26, C_BTN)
local importScroll, _ = mkScroll(TImport, 0, 76, 1, 250)

scanBtnActual.MouseButton1Click:Connect(function()
    scanBtnActual.Text="SCANNING..."; allFiles = {}
    task.spawn(function()
        allFiles = scanAll()
        buildImporterCards(importScroll, allFiles)
        scanBtnActual.Text="SCAN FILES"
        notify("Scan", "Ditemukan "..#allFiles.." file.", Color3.fromRGB(180,180,255))
    end)
end)

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    local q = searchBox.Text:lower():gsub("^%s*",""):gsub("%s*$","")
    if q == "" then buildImporterCards(importScroll, allFiles); return end
    local filtered = {}
    for _, f in ipairs(allFiles) do if f.name:lower():find(q, 1, true) then table.insert(filtered, f) end end
    buildImporterCards(importScroll, filtered)
end)

-- =========================================================================
-- TAB 2: CONFIG
-- =========================================================================
local function mkCfgBtn(text, y, cb)
    local _, b = mkBtn(TConfig, text, 0, y, 1, 34, C_BTN)
    b.MouseButton1Click:Connect(cb)
end
mkCfgBtn("DISABLE ALL SHADOWS", 15, function()
    local n=0
    for _, o in ipairs(workspace:GetDescendants()) do
        if o:IsA("BasePart") and o.CastShadow then o.CastShadow=false; n=n+1 end
    end
    notify("Config", "Shadow dimatikan di "..n.." part.", Color3.fromRGB(180,180,255))
end)
mkCfgBtn("ANCHOR ALL PARTS", 58, function()
    local n=0
    for _, o in ipairs(workspace:GetDescendants()) do
        if o:IsA("BasePart") and not o.Anchored then o.Anchored=true; n=n+1 end
    end
    notify("Config", n.." part berhasil di-anchor.", Color3.fromRGB(180,180,255))
end)

-- =========================================================================
-- TAB 3: REPLACER
-- =========================================================================
mkLabel(TReplace, "OBJECT REPLACER", 0, 8, 1, 15, 11)
mkLabel(TReplace, "Nama Target (Folder/Model di Workspace):", 0, 26, 0.5, 14, 9)
local _, tgtBox = mkBox(TReplace, "Target Name...", 0, 40, 0.5, 24)
mkLabel(TReplace, "Nama Pengganti (Part/Mesh Baru):", 0.5, 26, 0.5, 14, 9)
local _, repBox = mkBox(TReplace, "Replacement Name...", 0.5, 40, 0.5, 24)
local _, execRepBtn = mkBtn(TReplace, "REPLACE SEMUA PARTS DALAM TARGET", 0, 72, 1, 26, C_BTN)
execRepBtn.MouseButton1Click:Connect(function()
    local tN=tgtBox.Text; local rN=repBox.Text
    if tN=="" or rN=="" then notify("Error","Isi kedua kolom!",Color3.fromRGB(200,80,80)); return end
    local tpl = nil
    for _, o in ipairs(workspace:GetDescendants()) do if o.Name==rN then tpl=o; break end end
    if not tpl then notify("Error","Pengganti '"..rN.."' tidak ditemukan!",Color3.fromRGB(200,80,80)); return end
    local containers={}
    for _, o in ipairs(workspace:GetDescendants()) do if o.Name==tN and o~=tpl then table.insert(containers,o) end end
    if #containers==0 then notify("Error","Target '"..tN.."' tidak ditemukan!",Color3.fromRGB(200,80,80)); return end
    local n=0
    for _, container in ipairs(containers) do
        local parts={}
        if container:IsA("BasePart") then table.insert(parts, container)
        else for _, d in ipairs(container:GetDescendants()) do if d:IsA("BasePart") and d~=tpl then table.insert(parts,d) end end end
        for _, part in ipairs(parts) do
            local clone=tpl:Clone()
            if clone:IsA("BasePart") then clone.CFrame=part.CFrame; clone.Size=part.Size end
            clone.Parent=part.Parent; part:Destroy(); n=n+1
        end
    end
    tpl:Destroy()
    notify("Replacer", n.." part diganti, template dihapus.", Color3.fromRGB(100,200,100))
end)

-- DECAL REPLACER
mkLabel(TReplace, "DECAL REPLACER", 0, 108, 1, 15, 11)
local _, scanDecBtn = mkBtn(TReplace, "SCAN DECALS", 0, 126, 0, 26, C_BLUE)
local scanDecFrame = scanDecBtn.Parent; scanDecFrame.Size=UDim2.new(0,105,0,26); scanDecFrame.Position=UDim2.new(0,10,0,126)
local decIdF, decIdBox = mkBox(TReplace, "ID Decal Baru...", 0, 126, 1, 26)
decIdF.Size=UDim2.new(1,-130,0,26); decIdF.Position=UDim2.new(0,122,0,126)

local decalScroll, _ = mkScroll(TReplace, 0, 160, 1, 100)
local selectedDecal = nil
scanDecBtn.MouseButton1Click:Connect(function()
    selectedDecal=nil
    for _, c in ipairs(decalScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    local n=0
    for _, o in ipairs(workspace:GetDescendants()) do
        if o:IsA("Decal") or o:IsA("Texture") then
            n=n+1
            local row = mkRow(decalScroll, C_CARD2)
            local lbl = Instance.new("TextLabel", row)
            lbl.Size=UDim2.new(1,-10,1,0); lbl.Position=UDim2.new(0,8,0,0)
            lbl.BackgroundTransparency=1; lbl.Text=o.Parent.Name.." ▶ "..o.Name
            lbl.TextColor3=C_SUBTEXT; lbl.Font=Enum.Font.Gotham; lbl.TextSize=10; lbl.TextXAlignment=Enum.TextXAlignment.Left
            lbl.TextTruncate=Enum.TextTruncate.AtEnd
            local clickZone = Instance.new("TextButton", row)
            clickZone.Size=UDim2.new(1,0,1,0); clickZone.BackgroundTransparency=1; clickZone.Text=""
            local ref = o
            clickZone.MouseButton1Click:Connect(function()
                for _, c in ipairs(decalScroll:GetChildren()) do if c:IsA("Frame") then c.BackgroundColor3=C_CARD2 end end
                row.BackgroundColor3=Color3.fromRGB(50,80,50)
                selectedDecal=ref
            end)
        end
    end
    notify("Scan", n.." Decal ditemukan.", Color3.fromRGB(180,180,255))
end)

local _, repSelDec = mkBtn(TReplace, "REPLACE TERPILIH", 0, 268, 0.33, 24, C_BTN)
repSelDec.Parent.Size=UDim2.new(0.33,-8,0,24); repSelDec.Parent.Position=UDim2.new(0,10,0,268)
local _, repAllDec = mkBtn(TReplace, "REPLACE SEMUA", 0.33, 268, 0.33, 24, C_BTN)
repAllDec.Parent.Size=UDim2.new(0.33,-8,0,24); repAllDec.Parent.Position=UDim2.new(0.33,5,0,268)
local _, delAllDec = mkBtn(TReplace, "HAPUS SEMUA", 0.66, 268, 0.34, 24, C_RED)
delAllDec.Parent.Size=UDim2.new(0.34,-15,0,24); delAllDec.Parent.Position=UDim2.new(0.66,10,0,268)

local function getDecalTex()
    local id=decIdBox.Text:match("%d+")
    if not id then notify("Error","ID Decal tidak valid!",Color3.fromRGB(200,80,80)); return nil end
    return "rbxassetid://"..id
end
repSelDec.MouseButton1Click:Connect(function()
    local tex=getDecalTex(); if not tex then return end
    if selectedDecal and selectedDecal.Parent then selectedDecal.Texture=tex; notify("OK","Decal terpilih diganti.",Color3.fromRGB(100,200,100))
    else notify("Error","Pilih decal dari list dulu!",Color3.fromRGB(200,80,80)) end
end)
repAllDec.MouseButton1Click:Connect(function()
    local tex=getDecalTex(); if not tex then return end
    local n=0
    for _, o in ipairs(workspace:GetDescendants()) do if o:IsA("Decal") or o:IsA("Texture") then o.Texture=tex; n=n+1 end end
    notify("OK", n.." decal diganti.", Color3.fromRGB(100,200,100))
end)
delAllDec.MouseButton1Click:Connect(function()
    local n=0
    for _, o in ipairs(workspace:GetDescendants()) do if o:IsA("Decal") or o:IsA("Texture") then o:Destroy(); n=n+1 end end
    for _, c in ipairs(decalScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    notify("OK", n.." decal dihapus.", Color3.fromRGB(200,80,80))
end)

-- =========================================================================
-- TAB 4: REMAKE GUI
-- =========================================================================
local activeColor = Color3.fromRGB(255,255,255)
local selectedGuiTarget = nil

-- Left side: GUI tree from StarterGui only
local guiTreeScroll, _ = mkScroll(TRemake, 0, 38, 0.42, 240)
local _, scanGuiBtn = mkBtn(TRemake, "SCAN STARTER GUI", 0, 8, 0.42, 26, C_BLUE)

local function clearScroll(scroll)
    for _, c in ipairs(scroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
end

-- Build collapsible tree
local function mkGuiNode(parent, obj, depth, scroll)
    local allowed = {ScreenGui=true,Frame=true,ScrollingFrame=true,TextLabel=true,TextButton=true,TextBox=true,ImageLabel=true,ImageButton=true,ViewportFrame=true}
    if not allowed[obj.ClassName] then return end
    local children = obj:GetChildren()
    local hasChildren = false
    for _, c in ipairs(children) do if allowed[c.ClassName] then hasChildren=true; break end end

    local rowH = 22
    local row = Instance.new("Frame", scroll)
    row.Size=UDim2.new(1,0,0,rowH); row.BackgroundColor3=depth==0 and C_CARD or C_CARD2; mkCorner(row, 3)

    local indent = depth * 12
    local arrow = Instance.new("TextLabel", row)
    arrow.Size=UDim2.new(0,14,1,0); arrow.Position=UDim2.new(0,indent+4,0,0)
    arrow.BackgroundTransparency=1; arrow.Text=hasChildren and "▶" or " "
    arrow.TextColor3=C_SUBTEXT; arrow.Font=Enum.Font.GothamBold; arrow.TextSize=9

    local lbl = Instance.new("TextLabel", row)
    lbl.Size=UDim2.new(1,-(indent+22),1,0); lbl.Position=UDim2.new(0,indent+20,0,0)
    lbl.BackgroundTransparency=1; lbl.Text="["..obj.ClassName.."] "..obj.Name
    lbl.TextColor3=C_WHITE; lbl.Font=Enum.Font.Gotham; lbl.TextSize=10; lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.TextTruncate=Enum.TextTruncate.AtEnd

    local hitbox = Instance.new("TextButton", row)
    hitbox.Size=UDim2.new(1,0,1,0); hitbox.BackgroundTransparency=1; hitbox.Text=""

    local childFrames = {}
    local expanded = false

    local function buildChildren()
        for _, c in ipairs(children) do
            mkGuiNode(parent, c, depth+1, scroll)
        end
    end

    hitbox.MouseButton1Click:Connect(function()
        -- Highlight selection
        for _, c in ipairs(scroll:GetChildren()) do if c:IsA("Frame") then c.BackgroundColor3=depth==0 and C_CARD or C_CARD2 end end
        row.BackgroundColor3=Color3.fromRGB(55,85,55)
        selectedGuiTarget=obj
        parent.SelectedLbl.Text="Target: "..obj.Name

        if hasChildren then
            expanded=not expanded
            arrow.Text=expanded and "▼" or "▶"
            if expanded then
                -- Find insertion index
                local myIdx=0
                for i, c in ipairs(scroll:GetChildren()) do if c==row then myIdx=i; break end end
                -- Insert children after this row
                for i=#children,1,-1 do
                    local ch=children[i]
                    local al={ScreenGui=true,Frame=true,ScrollingFrame=true,TextLabel=true,TextButton=true,TextBox=true,ImageLabel=true,ImageButton=true,ViewportFrame=true}
                    if al[ch.ClassName] then
                        local childRow=Instance.new("Frame",scroll); childRow.Size=UDim2.new(1,0,0,22)
                        childRow.BackgroundColor3=C_CARD2; mkCorner(childRow,3); childRow.LayoutOrder=myIdx+1
                        local iL=depth+1; local ind2=iL*12
                        local lbl2=Instance.new("TextLabel",childRow)
                        lbl2.Size=UDim2.new(1,-(ind2+22),1,0); lbl2.Position=UDim2.new(0,ind2+20,0,0)
                        lbl2.BackgroundTransparency=1; lbl2.Text="["..ch.ClassName.."] "..ch.Name
                        lbl2.TextColor3=C_SUBTEXT; lbl2.Font=Enum.Font.Gotham; lbl2.TextSize=9; lbl2.TextXAlignment=Enum.TextXAlignment.Left
                        lbl2.TextTruncate=Enum.TextTruncate.AtEnd
                        local hz2=Instance.new("TextButton",childRow); hz2.Size=UDim2.new(1,0,1,0); hz2.BackgroundTransparency=1; hz2.Text=""
                        local ref=ch
                        hz2.MouseButton1Click:Connect(function()
                            for _, cc in ipairs(scroll:GetChildren()) do if cc:IsA("Frame") then cc.BackgroundColor3=C_CARD2 end end
                            childRow.BackgroundColor3=Color3.fromRGB(55,85,55)
                            selectedGuiTarget=ref; parent.SelectedLbl.Text="Target: "..ref.Name
                        end)
                        table.insert(childFrames, childRow)
                    end
                end
            else
                for _, cf in ipairs(childFrames) do cf:Destroy() end
                table.remove(childFrames)
            end
        end
    end)
end

-- Attach selectedLbl reference to TRemake
TRemake.SelectedLbl = Instance.new("TextLabel", TRemake)
TRemake.SelectedLbl.Size=UDim2.new(0.58,-20,0,26); TRemake.SelectedLbl.Position=UDim2.new(0.42,10,0,8)
TRemake.SelectedLbl.BackgroundTransparency=1; TRemake.SelectedLbl.Text="Target: SEMUA"
TRemake.SelectedLbl.TextColor3=Color3.fromRGB(220,200,100); TRemake.SelectedLbl.Font=Enum.Font.GothamBold
TRemake.SelectedLbl.TextSize=10; TRemake.SelectedLbl.TextXAlignment=Enum.TextXAlignment.Left
TRemake.SelectedLbl.TextTruncate=Enum.TextTruncate.AtEnd

scanGuiBtn.MouseButton1Click:Connect(function()
    clearScroll(guiTreeScroll); selectedGuiTarget=nil; TRemake.SelectedLbl.Text="Target: SEMUA"
    -- "All" row
    local allRow=Instance.new("Frame",guiTreeScroll); allRow.Size=UDim2.new(1,0,0,24); allRow.BackgroundColor3=C_BTN; mkCorner(allRow,3)
    local allL=Instance.new("TextLabel",allRow); allL.Size=UDim2.new(1,-10,1,0); allL.Position=UDim2.new(0,8,0,0)
    allL.BackgroundTransparency=1; allL.Text="⊕ SEMUA GUI"; allL.TextColor3=C_WHITE; allL.Font=Enum.Font.GothamBold; allL.TextSize=10; allL.TextXAlignment=Enum.TextXAlignment.Left
    local allHz=Instance.new("TextButton",allRow); allHz.Size=UDim2.new(1,0,1,0); allHz.BackgroundTransparency=1; allHz.Text=""
    allHz.MouseButton1Click:Connect(function()
        for _, c in ipairs(guiTreeScroll:GetChildren()) do if c:IsA("Frame") then c.BackgroundColor3=C_CARD2 end end
        allRow.BackgroundColor3=Color3.fromRGB(55,85,55)
        selectedGuiTarget=nil; TRemake.SelectedLbl.Text="Target: SEMUA"
    end)
    for _, gui in ipairs(StarterGui:GetChildren()) do mkGuiNode(TRemake, gui, 0, guiTreeScroll) end
end)

-- Right side: Color Palette
local PaletteF = Instance.new("Frame", TRemake)
PaletteF.Size=UDim2.new(0.58,-20,0,240); PaletteF.Position=UDim2.new(0.42,10,0,38)
PaletteF.BackgroundTransparency=1

local colorPreview = Instance.new("Frame", PaletteF)
colorPreview.Size=UDim2.new(1,0,0,26); colorPreview.BackgroundColor3=activeColor; mkCorner(colorPreview,4)
local colorPreviewL = Instance.new("TextLabel", colorPreview)
colorPreviewL.Size=UDim2.new(1,0,1,0); colorPreviewL.BackgroundTransparency=1
colorPreviewL.Text="Warna Dipilih"; colorPreviewL.TextColor3=Color3.fromRGB(0,0,0); colorPreviewL.Font=Enum.Font.GothamBold; colorPreviewL.TextSize=10

local gridScroll = Instance.new("ScrollingFrame", PaletteF)
gridScroll.Size=UDim2.new(1,0,1,-32); gridScroll.Position=UDim2.new(0,0,0,32)
gridScroll.BackgroundTransparency=1; gridScroll.ScrollBarThickness=4; gridScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
local gridLayout = Instance.new("UIGridLayout", gridScroll)
gridLayout.CellSize=UDim2.new(0,34,0,28); gridLayout.CellPadding=UDim2.new(0,4,0,4)

local COLORS = {
    -- Reds
    Color3.fromRGB(255,0,0),Color3.fromRGB(200,0,0),Color3.fromRGB(255,80,80),Color3.fromRGB(255,150,150),
    -- Greens
    Color3.fromRGB(0,255,0),Color3.fromRGB(0,180,0),Color3.fromRGB(100,255,100),Color3.fromRGB(150,255,150),
    -- Blues
    Color3.fromRGB(0,0,255),Color3.fromRGB(0,0,180),Color3.fromRGB(80,80,255),Color3.fromRGB(150,150,255),
    -- Yellows/Oranges
    Color3.fromRGB(255,255,0),Color3.fromRGB(255,200,0),Color3.fromRGB(255,128,0),Color3.fromRGB(255,165,80),
    -- Purples/Pinks
    Color3.fromRGB(255,0,255),Color3.fromRGB(180,0,180),Color3.fromRGB(128,0,255),Color3.fromRGB(255,100,200),
    Color3.fromRGB(255,192,203),Color3.fromRGB(200,100,200),
    -- Cyans/Teals
    Color3.fromRGB(0,255,255),Color3.fromRGB(0,180,180),Color3.fromRGB(0,128,128),Color3.fromRGB(100,255,220),
    -- Browns
    Color3.fromRGB(139,69,19),Color3.fromRGB(160,100,50),Color3.fromRGB(200,150,100),
    -- Whites/Grays/Blacks
    Color3.fromRGB(255,255,255),Color3.fromRGB(200,200,200),Color3.fromRGB(150,150,150),Color3.fromRGB(100,100,100),Color3.fromRGB(50,50,50),Color3.fromRGB(15,15,15),
}
for _, col in ipairs(COLORS) do
    local cb=Instance.new("TextButton", gridScroll); cb.BackgroundColor3=col; cb.Text=""; mkCorner(cb,3)
    cb.MouseButton1Click:Connect(function()
        activeColor=col; colorPreview.BackgroundColor3=col
        colorPreviewL.TextColor3=(col.R+col.G+col.B)<1.5 and Color3.new(1,1,1) or Color3.new(0,0,0)
    end)
end

-- Apply buttons
local _, applyBgBtn = mkBtn(TRemake, "TERAPKAN KE BG", 0, 288, 0.5, 24, C_BTN)
applyBgBtn.Parent.Size=UDim2.new(0.5,-8,0,24); applyBgBtn.Parent.Position=UDim2.new(0,10,0,288)
local _, applyTxtBtn = mkBtn(TRemake, "TERAPKAN KE TEKS", 0.5, 288, 0.5, 24, C_BTN)
applyTxtBtn.Parent.Size=UDim2.new(0.5,-18,0,24); applyTxtBtn.Parent.Position=UDim2.new(0.5,8,0,288)

local function applyColor(prop)
    local roots={}
    if selectedGuiTarget then table.insert(roots, selectedGuiTarget)
    else for _, gui in ipairs(StarterGui:GetChildren()) do table.insert(roots, gui) end end
    local n=0
    for _, root in ipairs(roots) do
        local all=root:GetDescendants(); table.insert(all, root)
        for _, obj in ipairs(all) do
            if obj:IsA("GuiObject") then pcall(function()
                if prop=="bg" and obj.BackgroundTransparency<1 then obj.BackgroundColor3=activeColor; n=n+1
                elseif prop=="txt" and (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then obj.TextColor3=activeColor; n=n+1 end
            end) end
        end
    end
    notify("Remake GUI", n.." elemen berhasil diubah.", Color3.fromRGB(100,200,100))
end
applyBgBtn.MouseButton1Click:Connect(function() applyColor("bg") end)
applyTxtBtn.MouseButton1Click:Connect(function() applyColor("txt") end)

-- SET DEFAULT TAB
Tabs[1].Btn.BackgroundColor3=C_TAB_ACT; Tabs[1].Btn.TextColor3=C_WHITE; Tabs[1].Ic.ImageColor3=C_WHITE; Tabs[1].Frame.Visible=true

print("[MCHLERN TOOLS KIT] v2.3 LOADED")
