-- ============================================================
--  DELTA TERRAIN BUILDER v3.0 — LIQUID GLASS PREMIUM
--  Executor Edition | Studio Lite Compatible
--  UI Portrait | Analog Joystick Build Control
-- ============================================================

-- cleanup
for _, n in ipairs({"DeltaTerrainBuilder","DTBrushPreview"}) do
	local o = game.CoreGui:FindFirstChild(n) or workspace:FindFirstChild(n)
	if o then o:Destroy() end
end

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UIS              = game:GetService("UserInputService")
local terrain          = workspace.Terrain
local player           = Players.LocalPlayer
local mouse            = player:GetMouse()
local camera           = workspace.CurrentCamera

-- ============================================================
--  STATE
-- ============================================================
local S = {
	tool       = "add",
	mat        = Enum.Material.Grass,
	brushSize  = 16,
	strength   = 0.5,
	shape      = "sphere",
	flatY      = nil,
	tab        = "tool",
	panelOpen  = true,
	-- analog
	analogActive = false,
	analogX      = 0,
	analogY      = 0,
	analogDist   = 0,
	buildPos     = nil,
	buildDir     = Vector3.new(0,0,0),
}

-- ============================================================
--  MATERIAL LIST (safe for Studio Lite — auto-filter)
-- ============================================================
local MAT_RAW = {
	{n="Grass",        m=Enum.Material.Grass,        c=Color3.fromRGB(85,120,50)},
	{n="Ground",       m=Enum.Material.Ground,       c=Color3.fromRGB(100,80,55)},
	{n="Sand",         m=Enum.Material.Sand,         c=Color3.fromRGB(210,195,130)},
	{n="Rock",         m=Enum.Material.Rock,         c=Color3.fromRGB(100,105,110)},
	{n="Sandstone",    m=Enum.Material.Sandstone,    c=Color3.fromRGB(140,95,70)},
	{n="Slate",        m=Enum.Material.Slate,        c=Color3.fromRGB(55,65,80)},
	{n="Basalt",       m=Enum.Material.Basalt,       c=Color3.fromRGB(28,28,35)},
	{n="Limestone",    m=Enum.Material.Limestone,    c=Color3.fromRGB(210,180,150)},
	{n="Pavement",     m=Enum.Material.Pavement,     c=Color3.fromRGB(145,145,138)},
	{n="Cobblestone",  m=Enum.Material.Cobblestone,  c=Color3.fromRGB(130,120,88)},
	{n="Brick",        m=Enum.Material.Brick,        c=Color3.fromRGB(155,88,60)},
	{n="Snow",         m=Enum.Material.Snow,         c=Color3.fromRGB(220,225,235)},
	{n="Ice",          m=Enum.Material.Ice,          c=Color3.fromRGB(130,200,230)},
	{n="Water",        m=Enum.Material.Water,        c=Color3.fromRGB(30,110,200)},
	{n="Wood",         m=Enum.Material.Wood,         c=Color3.fromRGB(120,82,52)},
	{n="WoodPlanks",   m=Enum.Material.WoodPlanks,   c=Color3.fromRGB(160,120,80)},
	{n="Concrete",     m=Enum.Material.Concrete,     c=Color3.fromRGB(115,115,115)},
	{n="SmoothPlastic",m=Enum.Material.SmoothPlastic,c=Color3.fromRGB(175,175,175)},
	{n="Neon",         m=Enum.Material.Neon,         c=Color3.fromRGB(0,200,255)},
	{n="DiamondPlate", m=Enum.Material.DiamondPlate, c=Color3.fromRGB(165,172,180)},
	{n="Foil",         m=Enum.Material.Foil,         c=Color3.fromRGB(205,205,185)},
	{n="Fabric",       m=Enum.Material.Fabric,       c=Color3.fromRGB(180,145,105)},
}

local MATS = {}
for _, m in ipairs(MAT_RAW) do
	local ok = pcall(function()
		terrain:FillBall(Vector3.new(0,-9999,0),1,m.m)
		terrain:FillBall(Vector3.new(0,-9999,0),1,Enum.Material.Air)
	end)
	if ok then table.insert(MATS, m) end
end
if #MATS == 0 then MATS = MAT_RAW end

local TOOLS = {
	{id="add",    label="Add",     icon="＋"},
	{id="sub",    label="Remove",  icon="－"},
	{id="paint",  label="Paint",   icon="◎"},
	{id="smooth", label="Smooth",  icon="≈"},
	{id="flat",   label="Flatten", icon="═"},
	{id="grow",   label="Grow",    icon="▲"},
	{id="erode",  label="Erode",   icon="▼"},
}

-- ============================================================
--  GLASS PREMIUM COLORS
-- ============================================================
local G = {
	-- glass panels
	glass      = Color3.fromRGB(255,255,255),
	glassDark  = Color3.fromRGB(20,24,36),
	glassBlue  = Color3.fromRGB(14,20,45),

	-- accents
	cyan       = Color3.fromRGB(0,220,255),
	blue       = Color3.fromRGB(50,130,255),
	purple     = Color3.fromRGB(140,80,255),
	pink       = Color3.fromRGB(255,80,180),
	green      = Color3.fromRGB(0,230,120),
	red        = Color3.fromRGB(255,60,60),
	orange     = Color3.fromRGB(255,150,0),

	-- text
	textW      = Color3.fromRGB(240,245,255),
	textDim    = Color3.fromRGB(140,160,200),
	textHint   = Color3.fromRGB(80,100,150),

	-- misc
	border     = Color3.fromRGB(60,80,140),
	borderGlow = Color3.fromRGB(0,180,255),
}

-- ============================================================
--  HELPERS
-- ============================================================
local function rnd(p,r) local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r or 8);c.Parent=p end
local function strk(p,col,th) local s=Instance.new("UIStroke");s.Color=col or G.border;s.Thickness=th or 1;s.Parent=p;return s end
local function pad(p,t,r,b,l) local u=Instance.new("UIPadding");u.PaddingTop=UDim.new(0,t);u.PaddingRight=UDim.new(0,r);u.PaddingBottom=UDim.new(0,b);u.PaddingLeft=UDim.new(0,l);u.Parent=p end
local function grad(p,c0,c1,rot)
	local g=Instance.new("UIGradient")
	g.Color=ColorSequence.new(c0,c1)
	g.Rotation=rot or 90
	g.Parent=p
end

local function glassFrame(parent, size, pos, alpha, zi)
	local f=Instance.new("Frame")
	f.Size=size f.Position=pos or UDim2.new(0,0,0,0)
	f.BackgroundColor3=G.glassBlue
	f.BackgroundTransparency=alpha or 0.3
	f.BorderSizePixel=0
	f.ZIndex=zi or 10
	f.Parent=parent
	rnd(f,12)
	strk(f,G.border,1)
	return f
end

local function mkBtn(parent, txt, size, pos, zi)
	local b=Instance.new("TextButton")
	b.Size=size b.Position=pos or UDim2.new(0,0,0,0)
	b.BackgroundColor3=G.glassBlue
	b.BackgroundTransparency=0.4
	b.BorderSizePixel=0
	b.Text=txt b.TextSize=12
	b.Font=Enum.Font.GothamBold
	b.TextColor3=G.textW
	b.ZIndex=zi or 11
	b.Parent=parent
	rnd(b,8)
	strk(b,G.border,1)
	b.MouseEnter:Connect(function() b.BackgroundTransparency=0.15 end)
	b.MouseLeave:Connect(function() b.BackgroundTransparency=0.4 end)
	return b
end

local function mkLabel(parent, txt, size, bold, col, xa)
	local l=Instance.new("TextLabel")
	l.BackgroundTransparency=1
	l.Text=txt l.TextSize=size or 12
	l.Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham
	l.TextColor3=col or G.textW
	l.TextXAlignment=xa or Enum.TextXAlignment.Left
	l.AutomaticSize=Enum.AutomaticSize.XY
	l.Parent=parent
	return l
end

-- ============================================================
--  GUI ROOT
-- ============================================================
local gui=Instance.new("ScreenGui")
gui.Name="DeltaTerrainBuilder"
gui.ResetOnSpawn=false
gui.IgnoreGuiInset=true
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.Parent=game.CoreGui

-- ============================================================
--  BACKGROUND BLUR OVERLAY (glass effect)
-- ============================================================
-- (Studio Lite tidak support BlurEffect di CoreGui, skip)

-- ============================================================
--  MAIN PANEL — Portrait, right side
-- ============================================================
local PANEL_W = 260
local PANEL_H = 580

local panel=Instance.new("Frame")
panel.Name="MainPanel"
panel.Size=UDim2.new(0,PANEL_W,0,PANEL_H)
panel.Position=UDim2.new(1,-PANEL_W-8,0.5,-PANEL_H/2)
panel.BackgroundColor3=G.glassBlue
panel.BackgroundTransparency=0.18
panel.BorderSizePixel=0
panel.ZIndex=20
panel.Visible=true
panel.Parent=gui
rnd(panel,16)
strk(panel,G.border,1.5)

-- glow border
local glowStroke=Instance.new("UIStroke")
glowStroke.Color=G.cyan
glowStroke.Thickness=0
glowStroke.Parent=panel

-- top gradient bar
local topBar=Instance.new("Frame")
topBar.Size=UDim2.new(1,0,0,3)
topBar.BackgroundColor3=G.cyan
topBar.BorderSizePixel=0
topBar.ZIndex=21
topBar.Parent=panel
rnd(topBar,2)
grad(topBar, G.cyan, G.purple, 0)

-- ============================================================
--  HEADER
-- ============================================================
local header=Instance.new("Frame")
header.Size=UDim2.new(1,0,0,48)
header.Position=UDim2.new(0,0,0,3)
header.BackgroundTransparency=1
header.BorderSizePixel=0
header.ZIndex=21
header.Parent=panel

local hIcon=Instance.new("TextLabel")
hIcon.Size=UDim2.new(0,36,0,36)
hIcon.Position=UDim2.new(0,10,0,6)
hIcon.BackgroundColor3=G.cyan
hIcon.BackgroundTransparency=0.6
hIcon.Text="▲"
hIcon.TextSize=18
hIcon.Font=Enum.Font.GothamBold
hIcon.TextColor3=G.cyan
hIcon.TextXAlignment=Enum.TextXAlignment.Center
hIcon.ZIndex=22
hIcon.Parent=header
rnd(hIcon,8)
strk(hIcon,G.cyan,1)

local hTitle=Instance.new("TextLabel")
hTitle.Size=UDim2.new(1,-90,0,20)
hTitle.Position=UDim2.new(0,52,0,6)
hTitle.BackgroundTransparency=1
hTitle.Text="Delta Terrain"
hTitle.TextSize=14
hTitle.Font=Enum.Font.GothamBold
hTitle.TextColor3=G.textW
hTitle.TextXAlignment=Enum.TextXAlignment.Left
hTitle.ZIndex=22
hTitle.Parent=header

local hSub=Instance.new("TextLabel")
hSub.Size=UDim2.new(1,-90,0,14)
hSub.Position=UDim2.new(0,52,0,24)
hSub.BackgroundTransparency=1
hSub.Text="Builder v3.0 · Liquid Glass"
hSub.TextSize=9
hSub.Font=Enum.Font.Gotham
hSub.TextColor3=G.textDim
hSub.TextXAlignment=Enum.TextXAlignment.Left
hSub.ZIndex=22
hSub.Parent=header

-- close btn
local closeBtn=Instance.new("TextButton")
closeBtn.Size=UDim2.new(0,28,0,28)
closeBtn.Position=UDim2.new(1,-36,0,10)
closeBtn.BackgroundColor3=G.red
closeBtn.BackgroundTransparency=0.3
closeBtn.BorderSizePixel=0
closeBtn.Text="✕"
closeBtn.TextSize=14
closeBtn.Font=Enum.Font.GothamBold
closeBtn.TextColor3=Color3.new(1,1,1)
closeBtn.ZIndex=22
closeBtn.Parent=header
rnd(closeBtn,8)

-- DRAG panel
do
	local drag,ds,sp
	header.InputBegan:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 then
			drag=true ds=i.Position sp=panel.Position
		end
	end)
	header.InputEnded:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
	end)
	UIS.InputChanged:Connect(function(i)
		if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
			local d=i.Position-ds
			panel.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
		end
	end)
end

-- ============================================================
--  TAB BAR (pill style)
-- ============================================================
local tabPill=Instance.new("Frame")
tabPill.Size=UDim2.new(1,-16,0,30)
tabPill.Position=UDim2.new(0,8,0,54)
tabPill.BackgroundColor3=Color3.fromRGB(10,15,35)
tabPill.BackgroundTransparency=0.3
tabPill.BorderSizePixel=0
tabPill.ZIndex=21
tabPill.Parent=panel
rnd(tabPill,10)
strk(tabPill,G.border,1)

local tabLL=Instance.new("UIListLayout")
tabLL.FillDirection=Enum.FillDirection.Horizontal
tabLL.SortOrder=Enum.SortOrder.LayoutOrder
tabLL.Padding=UDim.new(0,2)
tabLL.VerticalAlignment=Enum.VerticalAlignment.Center
tabLL.Parent=tabPill
pad(tabPill,3,3,3,3)

local TAB_DEFS={
	{id="tool",  label="Tools"},
	{id="mat",   label="Materials"},
	{id="set",   label="Settings"},
}
local tabBtns={}

for i,td in ipairs(TAB_DEFS) do
	local b=Instance.new("TextButton")
	b.Size=UDim2.new(0,76,0,24)
	b.BackgroundColor3=G.glassBlue
	b.BackgroundTransparency=1
	b.BorderSizePixel=0
	b.Text=td.label
	b.TextSize=11
	b.Font=Enum.Font.GothamBold
	b.TextColor3=G.textDim
	b.LayoutOrder=i
	b.ZIndex=22
	b.Parent=tabPill
	rnd(b,8)
	tabBtns[td.id]=b
end

-- ============================================================
--  CONTENT SCROLL
-- ============================================================
local scrollFrame=Instance.new("ScrollingFrame")
scrollFrame.Size=UDim2.new(1,-4,1,-200)
scrollFrame.Position=UDim2.new(0,2,0,88)
scrollFrame.BackgroundTransparency=1
scrollFrame.BorderSizePixel=0
scrollFrame.ScrollBarThickness=3
scrollFrame.ScrollBarImageColor3=G.cyan
scrollFrame.CanvasSize=UDim2.new(0,0,0,0)
scrollFrame.AutomaticCanvasSize=Enum.AutomaticSize.Y
scrollFrame.ZIndex=21
scrollFrame.Parent=panel

-- ============================================================
--  STATUS BAR
-- ============================================================
local statusBg=Instance.new("Frame")
statusBg.Size=UDim2.new(1,-16,0,20)
statusBg.Position=UDim2.new(0,8,1,-28)
statusBg.BackgroundColor3=Color3.fromRGB(0,180,255)
statusBg.BackgroundTransparency=0.75
statusBg.BorderSizePixel=0
statusBg.ZIndex=21
statusBg.Parent=panel
rnd(statusBg,6)

local statusLbl=Instance.new("TextLabel")
statusLbl.Size=UDim2.new(1,-8,1,0)
statusLbl.Position=UDim2.new(0,4,0,0)
statusLbl.BackgroundTransparency=1
statusLbl.Text="Ready"
statusLbl.TextSize=9
statusLbl.Font=Enum.Font.Gotham
statusLbl.TextColor3=G.textDim
statusLbl.TextXAlignment=Enum.TextXAlignment.Left
statusLbl.ZIndex=22
statusLbl.Parent=statusBg

local function setStat(msg) statusLbl.Text=msg end

-- ============================================================
--  PAGE BUILDER
-- ============================================================
local pages={}

local function makePage(id)
	local f=Instance.new("Frame")
	f.Size=UDim2.new(1,0,1,0)
	f.BackgroundTransparency=1
	f.BorderSizePixel=0
	f.Visible=false
	f.ZIndex=22
	f.Parent=scrollFrame
	local ll=Instance.new("UIListLayout")
	ll.SortOrder=Enum.SortOrder.LayoutOrder
	ll.Padding=UDim.new(0,4)
	ll.Parent=f
	pad(f,6,6,6,6)
	pages[id]=f
	return f
end

local function secTitle(parent, txt, order)
	local row=Instance.new("Frame")
	row.Size=UDim2.new(1,0,0,22)
	row.BackgroundTransparency=1
	row.LayoutOrder=order
	row.Parent=parent

	local line=Instance.new("Frame")
	line.Size=UDim2.new(1,0,0,1)
	line.Position=UDim2.new(0,0,0.5,0)
	line.BackgroundColor3=G.border
	line.BorderSizePixel=0
	line.Parent=row
	grad(line,G.cyan,Color3.fromRGB(0,0,0),0)

	local bg=Instance.new("Frame")
	bg.Size=UDim2.new(0,0,0,18)
	bg.AutomaticSize=Enum.AutomaticSize.X
	bg.BackgroundColor3=G.glassBlue
	bg.BorderSizePixel=0
	bg.Position=UDim2.new(0,0,0.5,-9)
	bg.Parent=row
	pad(bg,0,8,0,0)
	rnd(bg,4)

	local l=Instance.new("TextLabel")
	l.BackgroundTransparency=1
	l.Text=txt
	l.TextSize=10
	l.Font=Enum.Font.GothamBold
	l.TextColor3=G.cyan
	l.TextXAlignment=Enum.TextXAlignment.Left
	l.AutomaticSize=Enum.AutomaticSize.XY
	l.Parent=bg
end

-- ============================================================
--  TOOLS PAGE
-- ============================================================
local toolPage=makePage("tool")

secTitle(toolPage,"TOOL TYPE",1)

local toolGrid=Instance.new("Frame")
toolGrid.Size=UDim2.new(1,0,0,110)
toolGrid.BackgroundTransparency=1
toolGrid.LayoutOrder=2
toolGrid.Parent=toolPage

local tgGrid=Instance.new("UIGridLayout")
tgGrid.CellSize=UDim2.new(0,106,0,32)
tgGrid.CellPadding=UDim2.new(0,4,0,4)
tgGrid.Parent=toolGrid

local toolBtns={}
local toolColors={
	add=G.green, sub=G.red, paint=G.cyan, smooth=G.blue,
	flat=G.orange, grow=G.purple, erode=G.pink,
}

local function setTool(id)
	S.tool=id
	for tid,b in pairs(toolBtns) do
		local ac = tid==id
		b.BackgroundColor3 = ac and toolColors[tid] or G.glassBlue
		b.BackgroundTransparency = ac and 0.1 or 0.5
		b.TextColor3 = ac and Color3.new(1,1,1) or G.textDim
	end
	setStat("Tool: "..id)
end

for _,t in ipairs(TOOLS) do
	local b=Instance.new("TextButton")
	b.Size=UDim2.new(0,106,0,32)
	b.BackgroundColor3=G.glassBlue
	b.BackgroundTransparency=0.5
	b.BorderSizePixel=0
	b.Text=t.icon.." "..t.label
	b.TextSize=12
	b.Font=Enum.Font.GothamBold
	b.TextColor3=G.textDim
	b.ZIndex=23
	b.Parent=toolGrid
	rnd(b,8)
	strk(b,G.border,1)
	toolBtns[t.id]=b
	b.MouseButton1Click:Connect(function() setTool(t.id) end)
end
setTool("add")

-- Brush Shape
secTitle(toolPage,"BRUSH SHAPE",3)

local shapeRow=Instance.new("Frame")
shapeRow.Size=UDim2.new(1,0,0,32)
shapeRow.BackgroundTransparency=1
shapeRow.LayoutOrder=4
shapeRow.Parent=toolPage

local shLL=Instance.new("UIListLayout")
shLL.FillDirection=Enum.FillDirection.Horizontal
shLL.Padding=UDim.new(0,4)
shLL.Parent=shapeRow

local shapeBtns={}
local function setShape(id)
	S.shape=id
	for sid,b in pairs(shapeBtns) do
		local ac=sid==id
		b.BackgroundTransparency=ac and 0.1 or 0.5
		b.TextColor3=ac and G.cyan or G.textDim
	end
end

for _,s in ipairs({{id="sphere",l="● Sphere"},{id="cylinder",l="⬤ Cyl"},{id="box",l="■ Box"}}) do
	local b=Instance.new("TextButton")
	b.Size=UDim2.new(0,76,0,30)
	b.BackgroundColor3=G.cyan
	b.BackgroundTransparency=0.5
	b.BorderSizePixel=0
	b.Text=s.l b.TextSize=10
	b.Font=Enum.Font.GothamBold
	b.TextColor3=G.textDim
	b.ZIndex=23 b.Parent=shapeRow
	rnd(b,8) strk(b,G.border,1)
	shapeBtns[s.id]=b
	b.MouseButton1Click:Connect(function() setShape(s.id) end)
end
setShape("sphere")

-- Sliders
local function mkSlider(parent,order,pfx,mn,mx,def,fillC,sfx,cb)
	local wrap=Instance.new("Frame")
	wrap.Size=UDim2.new(1,0,0,48)
	wrap.BackgroundTransparency=1
	wrap.LayoutOrder=order
	wrap.Parent=parent

	local vLbl=Instance.new("TextLabel")
	vLbl.Size=UDim2.new(1,0,0,14)
	vLbl.BackgroundTransparency=1
	vLbl.Text=pfx..tostring(def)..sfx
	vLbl.TextSize=11
	vLbl.Font=Enum.Font.GothamBold
	vLbl.TextColor3=G.textW
	vLbl.TextXAlignment=Enum.TextXAlignment.Left
	vLbl.Parent=wrap

	local track=Instance.new("Frame")
	track.Size=UDim2.new(1,0,0,8)
	track.Position=UDim2.new(0,0,0,20)
	track.BackgroundColor3=Color3.fromRGB(15,20,45)
	track.BorderSizePixel=0
	track.Parent=wrap
	rnd(track,4) strk(track,G.border,1)

	local p0=(def-mn)/(mx-mn)
	local fill=Instance.new("Frame")
	fill.Size=UDim2.new(p0,0,1,0)
	fill.BackgroundColor3=fillC
	fill.BackgroundTransparency=0.1
	fill.BorderSizePixel=0
	fill.Parent=track
	rnd(fill,4)
	grad(fill,fillC,Color3.fromRGB(math.floor(fillC.R*100),math.floor(fillC.G*100),math.floor(fillC.B*100)),0)

	local knob=Instance.new("TextButton")
	knob.Size=UDim2.new(0,16,0,16)
	knob.Position=UDim2.new(p0,-8,0.5,-8)
	knob.BackgroundColor3=Color3.new(1,1,1)
	knob.BorderSizePixel=0
	knob.Text="" knob.ZIndex=25
	knob.Parent=track
	rnd(knob,8)
	strk(knob,fillC,2)

	local dragging=false
	local function upd(ax)
		local tx=track.AbsolutePosition.X
		local tw=track.AbsoluteSize.X
		local p=math.clamp((ax-tx)/tw,0,1)
		local v=math.floor(mn+p*(mx-mn))
		fill.Size=UDim2.new(p,0,1,0)
		knob.Position=UDim2.new(p,-8,0.5,-8)
		vLbl.Text=pfx..tostring(v)..sfx
		cb(v)
	end

	knob.MouseButton1Down:Connect(function() dragging=true end)
	UIS.InputEnded:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
			upd(i.Position.X)
		end
	end)
	track.InputBegan:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 then
			upd(UIS:GetMouseLocation().X)
		end
	end)
end

secTitle(toolPage,"BRUSH SIZE",5)
mkSlider(toolPage,6,"Size: ",2,64,16,G.cyan,"",function(v) S.brushSize=v end)

secTitle(toolPage,"STRENGTH",7)
mkSlider(toolPage,8,"Str: ",1,100,50,G.green,"%",function(v) S.strength=v/100 end)

-- Flatten pick
secTitle(toolPage,"FLATTEN HEIGHT",9)
local flatRow=Instance.new("Frame")
flatRow.Size=UDim2.new(1,0,0,32)
flatRow.BackgroundTransparency=1
flatRow.LayoutOrder=10
flatRow.Parent=toolPage
local frLL=Instance.new("UIListLayout")
frLL.FillDirection=Enum.FillDirection.Horizontal
frLL.Padding=UDim.new(0,6)
frLL.VerticalAlignment=Enum.VerticalAlignment.Center
frLL.Parent=flatRow

local pickBtn=Instance.new("TextButton")
pickBtn.Size=UDim2.new(0,148,0,28)
pickBtn.BackgroundColor3=G.orange
pickBtn.BackgroundTransparency=0.3
pickBtn.BorderSizePixel=0
pickBtn.Text="Pick Height"
pickBtn.TextSize=11
pickBtn.Font=Enum.Font.GothamBold
pickBtn.TextColor3=Color3.new(1,1,1)
pickBtn.ZIndex=23
pickBtn.Parent=flatRow
rnd(pickBtn,8)

local flatLbl=Instance.new("TextLabel")
flatLbl.Size=UDim2.new(0,80,0,28)
flatLbl.BackgroundTransparency=1
flatLbl.Text="Y: auto"
flatLbl.TextSize=11
flatLbl.Font=Enum.Font.Gotham
flatLbl.TextColor3=G.textDim
flatLbl.TextXAlignment=Enum.TextXAlignment.Left
flatLbl.Parent=flatRow

pickBtn.MouseButton1Click:Connect(function()
	pickBtn.Text="Click terrain..."
	local c c=mouse.Button1Down:Connect(function()
		c:Disconnect()
		S.flatY=mouse.Hit.Position.Y
		flatLbl.Text=string.format("Y: %.1f",S.flatY)
		pickBtn.Text="Pick Height"
	end)
end)

-- ============================================================
--  MATERIALS PAGE
-- ============================================================
local matPage=makePage("mat")

local matWrap=Instance.new("Frame")
matWrap.Size=UDim2.new(1,0,0,0)
matWrap.AutomaticSize=Enum.AutomaticSize.Y
matWrap.BackgroundTransparency=1
matWrap.LayoutOrder=1
matWrap.Parent=matPage

local mgGrid=Instance.new("UIGridLayout")
mgGrid.CellSize=UDim2.new(0,72,0,76)
mgGrid.CellPadding=UDim2.new(0,4,0,4)
mgGrid.Parent=matWrap

local matBtns={}
local function setMat(mat,ref)
	S.mat=mat
	for _,m in ipairs(matBtns) do
		m.cell.BackgroundTransparency=0.5
		local s=m.cell:FindFirstChildOfClass("UIStroke")
		if s then s.Color=G.border;s.Thickness=1 end
	end
	ref.cell.BackgroundTransparency=0.1
	local s=ref.cell:FindFirstChildOfClass("UIStroke")
	if s then s.Color=G.cyan;s.Thickness=2 end
	setStat("Mat: "..tostring(mat):gsub("Enum.Material.",""))
end

for i,m in ipairs(MATS) do
	local cell=Instance.new("Frame")
	cell.Size=UDim2.new(0,72,0,76)
	cell.BackgroundColor3=G.glassBlue
	cell.BackgroundTransparency=0.5
	cell.BorderSizePixel=0
	cell.ZIndex=23
	cell.Parent=matWrap
	rnd(cell,10)
	strk(cell,G.border,1)

	local swatch=Instance.new("Frame")
	swatch.Size=UDim2.new(1,-8,0,38)
	swatch.Position=UDim2.new(0,4,0,4)
	swatch.BackgroundColor3=m.c
	swatch.BorderSizePixel=0
	swatch.Parent=cell
	rnd(swatch,7)
	-- shimmer
	local sh=Instance.new("Frame")
	sh.Size=UDim2.new(1,0,0.4,0)
	sh.BackgroundColor3=Color3.new(1,1,1)
	sh.BackgroundTransparency=0.75
	sh.BorderSizePixel=0
	sh.Parent=swatch
	rnd(sh,7)

	local nl=Instance.new("TextLabel")
	nl.Size=UDim2.new(1,-2,0,28)
	nl.Position=UDim2.new(0,1,0,45)
	nl.BackgroundTransparency=1
	nl.Text=m.n
	nl.TextSize=9
	nl.Font=Enum.Font.Gotham
	nl.TextColor3=G.textDim
	nl.TextWrapped=true
	nl.TextXAlignment=Enum.TextXAlignment.Center
	nl.Parent=cell

	local ca=Instance.new("TextButton")
	ca.Size=UDim2.new(1,0,1,0)
	ca.BackgroundTransparency=1
	ca.Text="" ca.ZIndex=24
	ca.Parent=cell

	local ref={cell=cell,nl=nl}
	matBtns[i]=ref

	ca.MouseButton1Click:Connect(function() setMat(m.m,ref) end)
	ca.MouseEnter:Connect(function()
		if S.mat~=m.m then cell.BackgroundTransparency=0.3 end
	end)
	ca.MouseLeave:Connect(function()
		if S.mat~=m.m then cell.BackgroundTransparency=0.5 end
	end)
end
if #matBtns>0 then setMat(MATS[1].m,matBtns[1]) end

-- ============================================================
--  SETTINGS PAGE
-- ============================================================
local setPage=makePage("set")

secTitle(setPage,"HOTKEYS",1)
for i,hk in ipairs({
	{"T","Toggle panel"},{"[","Brush size -"},
	{"]","Brush size +"},{"M","Next material"},
	{"1","Add"},{"2","Remove"},{"3","Paint"},
	{"4","Smooth"},{"5","Flatten"},{"6","Grow"},{"7","Erode"},
}) do
	local row=Instance.new("Frame")
	row.Size=UDim2.new(1,0,0,26)
	row.BackgroundTransparency=1
	row.LayoutOrder=i+1
	row.Parent=setPage

	local badge=Instance.new("TextLabel")
	badge.Size=UDim2.new(0,26,0,20)
	badge.Position=UDim2.new(0,0,0.5,-10)
	badge.BackgroundColor3=G.glassBlue
	badge.BackgroundTransparency=0.2
	badge.BorderSizePixel=0
	badge.Text=hk[1]
	badge.TextSize=10
	badge.Font=Enum.Font.GothamBold
	badge.TextColor3=G.cyan
	badge.TextXAlignment=Enum.TextXAlignment.Center
	badge.Parent=row
	rnd(badge,4) strk(badge,G.cyan,1)

	local dl=Instance.new("TextLabel")
	dl.Size=UDim2.new(1,-36,1,0)
	dl.Position=UDim2.new(0,34,0,0)
	dl.BackgroundTransparency=1
	dl.Text=hk[2]
	dl.TextSize=11
	dl.Font=Enum.Font.Gotham
	dl.TextColor3=G.textDim
	dl.TextXAlignment=Enum.TextXAlignment.Left
	dl.Parent=row
end

secTitle(setPage,"INFO",15)
local iF=Instance.new("Frame")
iF.Size=UDim2.new(1,0,0,55)
iF.BackgroundTransparency=1
iF.LayoutOrder=16
iF.Parent=setPage
local iLL=Instance.new("UIListLayout")
iLL.SortOrder=Enum.SortOrder.LayoutOrder
iLL.Padding=UDim.new(0,3)
iLL.Parent=iF
for i,ln in ipairs({
	{"Delta Terrain Builder v3.0",true,G.textW},
	{"Liquid Glass · Executor Edition",false,G.textDim},
	{tostring(#MATS).." valid materials",false,G.textDim},
}) do
	local l=Instance.new("TextLabel")
	l.Size=UDim2.new(1,0,0,14)
	l.BackgroundTransparency=1
	l.Text=ln[1] l.TextSize=11
	l.Font=ln[2] and Enum.Font.GothamBold or Enum.Font.Gotham
	l.TextColor3=ln[3]
	l.TextXAlignment=Enum.TextXAlignment.Left
	l.LayoutOrder=i
	l.Parent=iF
end

-- ============================================================
--  TAB SWITCH
-- ============================================================
local function switchTab(id)
	S.tab=id
	for tid,b in pairs(tabBtns) do
		local ac=tid==id
		b.BackgroundTransparency=ac and 0.1 or 1
		b.BackgroundColor3=ac and G.cyan or G.glassBlue
		b.TextColor3=ac and Color3.fromRGB(10,10,30) or G.textDim
	end
	for pid,pg in pairs(pages) do pg.Visible=pid==id end
end

for _,td in ipairs(TAB_DEFS) do
	tabBtns[td.id].MouseButton1Click:Connect(function() switchTab(td.id) end)
end
switchTab("tool")

-- toggle
local function togglePanel()
	S.panelOpen=not S.panelOpen
	panel.Visible=S.panelOpen
end
closeBtn.MouseButton1Click:Connect(function()
	S.panelOpen=false panel.Visible=false
end)

-- ============================================================
--  TOGGLE BUTTON (floating)
-- ============================================================
local togBtn=Instance.new("TextButton")
togBtn.Size=UDim2.new(0,42,0,42)
togBtn.Position=UDim2.new(1,-54,0.5,-21)
togBtn.BackgroundColor3=G.cyan
togBtn.BackgroundTransparency=0.2
togBtn.BorderSizePixel=0
togBtn.Text="▲"
togBtn.TextSize=20
togBtn.Font=Enum.Font.GothamBold
togBtn.TextColor3=Color3.fromRGB(0,10,20)
togBtn.ZIndex=100
togBtn.Parent=gui
rnd(togBtn,12) strk(togBtn,G.cyan,2)
togBtn.Visible=false -- muncul kalo panel ditutup

closeBtn.MouseButton1Click:Connect(function() togBtn.Visible=true end)
togBtn.MouseButton1Click:Connect(function()
	panel.Visible=true S.panelOpen=true togBtn.Visible=false
end)

-- ============================================================
--  ANALOG JOYSTICK
-- ============================================================
local JOYSTICK_SIZE = 130
local KNOB_SIZE     = 50
local MAX_DIST      = (JOYSTICK_SIZE/2) - (KNOB_SIZE/2)

-- base
local joyBase=Instance.new("Frame")
joyBase.Name="JoyBase"
joyBase.Size=UDim2.new(0,JOYSTICK_SIZE,0,JOYSTICK_SIZE)
joyBase.Position=UDim2.new(0,20,1,-JOYSTICK_SIZE-20)
joyBase.BackgroundColor3=G.glassBlue
joyBase.BackgroundTransparency=0.25
joyBase.BorderSizePixel=0
joyBase.ZIndex=50
joyBase.Parent=gui
rnd(joyBase,JOYSTICK_SIZE//2)
strk(joyBase,G.border,1.5)

-- ring
local joyRing=Instance.new("Frame")
joyRing.Size=UDim2.new(1,-16,1,-16)
joyRing.Position=UDim2.new(0,8,0,8)
joyRing.BackgroundTransparency=1
joyRing.BorderSizePixel=0
joyRing.ZIndex=51
joyRing.Parent=joyBase
rnd(joyRing,(JOYSTICK_SIZE-16)//2)
strk(joyRing,G.cyan,1)

-- cross lines
for _,dir in ipairs({
	{UDim2.new(0.5,-1,0,8),UDim2.new(0,2,1,-16)},
	{UDim2.new(0,8,0.5,-1),UDim2.new(1,-16,0,2)},
}) do
	local l=Instance.new("Frame")
	l.Position=dir[1] l.Size=dir[2]
	l.BackgroundColor3=G.border
	l.BackgroundTransparency=0.5
	l.BorderSizePixel=0
	l.ZIndex=51
	l.Parent=joyBase
end

-- direction label
local dirLabel=Instance.new("TextLabel")
dirLabel.Size=UDim2.new(0,JOYSTICK_SIZE,0,18)
dirLabel.Position=UDim2.new(0,0,1,4)
dirLabel.BackgroundTransparency=1
dirLabel.Text="Joystick: Idle"
dirLabel.TextSize=9
dirLabel.Font=Enum.Font.Gotham
dirLabel.TextColor3=G.textDim
dirLabel.TextXAlignment=Enum.TextXAlignment.Center
dirLabel.ZIndex=51
dirLabel.Parent=joyBase

-- knob
local knob=Instance.new("TextButton")
knob.Size=UDim2.new(0,KNOB_SIZE,0,KNOB_SIZE)
knob.Position=UDim2.new(0.5,-KNOB_SIZE/2,0.5,-KNOB_SIZE/2)
knob.BackgroundColor3=G.cyan
knob.BackgroundTransparency=0.1
knob.BorderSizePixel=0
knob.Text=""
knob.ZIndex=52
knob.Parent=joyBase
rnd(knob,KNOB_SIZE//2)
strk(knob,G.cyan,2)

-- knob inner glow dot
local knobDot=Instance.new("Frame")
knobDot.Size=UDim2.new(0,14,0,14)
knobDot.Position=UDim2.new(0.5,-7,0.5,-7)
knobDot.BackgroundColor3=Color3.new(1,1,1)
knobDot.BackgroundTransparency=0.3
knobDot.BorderSizePixel=0
knobDot.ZIndex=53
knobDot.Parent=knob
rnd(knobDot,7)

-- analog drag logic
local joyDragging=false
local centerX=0 local centerY=0

local function resetKnob()
	knob.Position=UDim2.new(0.5,-KNOB_SIZE/2,0.5,-KNOB_SIZE/2)
	S.analogX=0 S.analogY=0 S.analogDist=0 S.analogActive=false
	dirLabel.Text="Joystick: Idle"
	knob.BackgroundColor3=G.cyan
end

knob.MouseButton1Down:Connect(function()
	joyDragging=true
	local ap=joyBase.AbsolutePosition
	local as=joyBase.AbsoluteSize
	centerX=ap.X+as.X/2
	centerY=ap.Y+as.Y/2
end)

UIS.InputEnded:Connect(function(i)
	if i.UserInputType==Enum.UserInputType.MouseButton1 then
		if joyDragging then
			joyDragging=false
			resetKnob()
		end
	end
end)

UIS.InputChanged:Connect(function(i)
	if joyDragging and i.UserInputType==Enum.UserInputType.MouseMovement then
		local mx=i.Position.X
		local my=i.Position.Y
		local dx=mx-centerX
		local dy=my-centerY
		local dist=math.sqrt(dx*dx+dy*dy)
		local clampDist=math.min(dist,MAX_DIST)
		local nx=dx/math.max(dist,0.001)
		local ny=dy/math.max(dist,0.001)

		local kx=JOYSTICK_SIZE/2 + nx*clampDist - KNOB_SIZE/2
		local ky=JOYSTICK_SIZE/2 + ny*clampDist - KNOB_SIZE/2
		knob.Position=UDim2.new(0,kx,0,ky)

		S.analogX=nx S.analogY=ny
		S.analogDist=clampDist/MAX_DIST
		S.analogActive=dist>8

		-- color feedback
		local t=math.clamp(S.analogDist,0,1)
		knob.BackgroundColor3=Color3.fromRGB(
			math.floor(0+t*255),
			math.floor(220-t*160),
			math.floor(255-t*255)
		)

		-- direction text
		local ang=math.atan2(ny,nx)*57.3
		local dirs
		if     ang>=-22.5  and ang<22.5   then dirs="→ East"
		elseif ang>=22.5   and ang<67.5   then dirs="↘ SE"
		elseif ang>=67.5   and ang<112.5  then dirs="↓ South"
		elseif ang>=112.5  and ang<157.5  then dirs="↙ SW"
		elseif ang>=157.5  or  ang<-157.5 then dirs="← West"
		elseif ang>=-157.5 and ang<-112.5 then dirs="↖ NW"
		elseif ang>=-112.5 and ang<-67.5  then dirs="↑ North"
		else                                    dirs="↗ NE"
		end
		dirLabel.Text=string.format("Dir: %s  |  %.0f%%",dirs,S.analogDist*100)
	end
end)

-- ============================================================
--  QUICK TOOL BUTTONS (above joystick)
-- ============================================================
local quickRow=Instance.new("Frame")
quickRow.Size=UDim2.new(0,JOYSTICK_SIZE,0,32)
quickRow.Position=UDim2.new(0,20,1,-JOYSTICK_SIZE-60)
quickRow.BackgroundTransparency=1
quickRow.ZIndex=50
quickRow.Parent=gui

local qrLL=Instance.new("UIListLayout")
qrLL.FillDirection=Enum.FillDirection.Horizontal
qrLL.Padding=UDim.new(0,4)
qrLL.Parent=quickRow

local quickTools={
	{id="add",c=G.green,l="＋"},
	{id="sub",c=G.red,l="－"},
	{id="paint",c=G.cyan,l="◎"},
	{id="flat",c=G.orange,l="═"},
}
for _,qt in ipairs(quickTools) do
	local b=Instance.new("TextButton")
	b.Size=UDim2.new(0,28,0,28)
	b.BackgroundColor3=qt.c
	b.BackgroundTransparency=0.3
	b.BorderSizePixel=0
	b.Text=qt.l b.TextSize=14
	b.Font=Enum.Font.GothamBold
	b.TextColor3=Color3.new(1,1,1)
	b.ZIndex=51 b.Parent=quickRow
	rnd(b,8) strk(b,qt.c,1)
	b.MouseButton1Click:Connect(function()
		setTool(qt.id)
		setStat("Quick: "..qt.id)
	end)
end

-- ============================================================
--  BRUSH PREVIEW
-- ============================================================
local brushPart=Instance.new("Part")
brushPart.Anchored=true brushPart.CanCollide=false
brushPart.Transparency=1 brushPart.CastShadow=false
brushPart.Name="DTBrushPreview" brushPart.Parent=workspace

local selBox=Instance.new("SelectionBox")
selBox.SurfaceTransparency=0.7
selBox.Color3=G.cyan selBox.LineThickness=0.04
selBox.Adornee=brushPart selBox.Parent=workspace

-- ============================================================
--  TERRAIN OPS
-- ============================================================
local function applyAt(pos)
	local r=S.brushSize
	local mat=S.mat
	local t=S.tool

	if t=="add" then
		if mat==Enum.Material.Water then
			terrain:FillBlock(CFrame.new(pos),Vector3.new(r*2,r*2,r*2),Enum.Material.Water)
		else
			terrain:FillBall(pos,r,mat)
		end
	elseif t=="sub" then
		terrain:FillBall(pos,r,Enum.Material.Air)
	elseif t=="paint" then
		local h=Vector3.new(r,r,r)
		local reg=Region3.new(pos-h,pos+h)
		local ok,occ,mats=pcall(function() return terrain:ReadVoxels(reg,4) end)
		if ok and occ then
			for x=1,#occ do for y=1,#occ[x] do for z=1,#occ[x][y] do
				if occ[x][y][z]>0.1 then mats[x][y][z]=mat end
			end end end
			pcall(function() terrain:WriteVoxels(reg,4,occ,mats) end)
		end
	elseif t=="smooth" then
		terrain:FillBall(pos,r,mat)
		for _=1,2 do
			terrain:FillBall(pos+Vector3.new(math.random(-2,2),0,math.random(-2,2)),math.max(2,r*0.3),Enum.Material.Air)
		end
	elseif t=="flat" then
		local hy=S.flatY or pos.Y
		terrain:FillBlock(CFrame.new(pos.X,hy,pos.Z),Vector3.new(r*2,4,r*2),mat)
		terrain:FillBlock(CFrame.new(pos.X,hy+r*0.8,pos.Z),Vector3.new(r*2,r*1.6,r*2),Enum.Material.Air)
	elseif t=="grow" then
		terrain:FillBall(pos+Vector3.new(0,r*0.5,0),r,mat)
	elseif t=="erode" then
		for _=1,4 do
			terrain:FillBall(
				pos+Vector3.new(math.random(-r,r)*0.7,math.random(-r,r)*0.7,math.random(-r,r)*0.7),
				math.max(1,r*0.25),Enum.Material.Air
			)
		end
	end
end

-- ============================================================
--  BUILD POSITION (from analog or mouse)
-- ============================================================
local buildHoldPos = nil  -- posisi anchor saat joystick aktif
local isPainting = false

mouse.Button1Down:Connect(function()
	if mouse.Target and mouse.Target:IsDescendantOf(gui) then return end
	isPainting=true

	-- simpan hit point sebagai anchor build
	local uRay=camera:ScreenPointToRay(mouse.X,mouse.Y)
	local ray=Ray.new(uRay.Origin,uRay.Direction*2000)
	local _,pos=workspace:FindPartOnRayWithIgnoreList(ray,{player.Character})
	if pos then buildHoldPos=pos end
end)
mouse.Button1Up:Connect(function()
	isPainting=false
	buildHoldPos=nil
end)

local cooldown=0
RunService.RenderStepped:Connect(function(dt)
	-- update brush preview selalu
	local uRay=camera:ScreenPointToRay(mouse.X,mouse.Y)
	local ray=Ray.new(uRay.Origin,uRay.Direction*2000)
	local _,mousePos=workspace:FindPartOnRayWithIgnoreList(ray,{player.Character})

	local buildTarget=nil

	if S.analogActive and buildHoldPos then
		-- mode analog: geser posisi dari anchor ke arah joystick
		local camCF=camera.CFrame
		local right=camCF.RightVector
		local forward=-camCF.LookVector
		-- flatten ke horizontal
		right=Vector3.new(right.X,0,right.Z).Unit
		forward=Vector3.new(forward.X,0,forward.Z).Unit

		local speed=S.brushSize * S.analogDist * 0.6
		local moveDir=right*S.analogX + forward*(-S.analogY)

		buildHoldPos=buildHoldPos + moveDir*speed*dt
		buildTarget=buildHoldPos

	elseif isPainting and mousePos then
		buildTarget=mousePos
		buildHoldPos=mousePos
	end

	-- brush preview
	if mousePos then
		brushPart.Position=buildHoldPos or mousePos
		brushPart.Size=Vector3.new(S.brushSize*2,S.brushSize*2,S.brushSize*2)
		selBox.Color3=S.tool=="sub" and G.red or G.cyan
	end

	if not isPainting then return end
	cooldown=cooldown-dt
	if cooldown>0 then return end
	cooldown=0.055

	if buildTarget then
		applyAt(buildTarget)
		setStat(string.format("[%s] %s | B:%d | %.0f %.0f %.0f",
			S.tool:upper(),
			tostring(S.mat):gsub("Enum.Material.",""),
			S.brushSize,
			buildTarget.X,buildTarget.Y,buildTarget.Z
		))
	end
end)

-- ============================================================
--  HOTKEYS
-- ============================================================
UIS.InputBegan:Connect(function(inp,gpe)
	if gpe then return end
	local k=inp.KeyCode
	if     k==Enum.KeyCode.LeftBracket  then S.brushSize=math.max(2,S.brushSize-2);setStat("Brush: "..S.brushSize)
	elseif k==Enum.KeyCode.RightBracket then S.brushSize=math.min(64,S.brushSize+2);setStat("Brush: "..S.brushSize)
	elseif k==Enum.KeyCode.T            then togglePanel()
	elseif k==Enum.KeyCode.M            then
		local cur=1
		for i,m in ipairs(MATS) do if m.m==S.mat then cur=i;break end end
		local nx=cur%#MATS+1
		setMat(MATS[nx].m,matBtns[nx])
	elseif k==Enum.KeyCode.One   then setTool("add")
	elseif k==Enum.KeyCode.Two   then setTool("sub")
	elseif k==Enum.KeyCode.Three then setTool("paint")
	elseif k==Enum.KeyCode.Four  then setTool("smooth")
	elseif k==Enum.KeyCode.Five  then setTool("flat")
	elseif k==Enum.KeyCode.Six   then setTool("grow")
	elseif k==Enum.KeyCode.Seven then setTool("erode")
	end
end)

-- ============================================================
--  INIT
-- ============================================================
setStat("Delta Terrain Builder v3.0 — Liquid Glass · Loaded")
print("[DTB v3.0] "..#MATS.." materials | Analog joystick active | CoreGui parent")
