-- ============================================================
--  DELTA TERRAIN BUILDER v2.0 - EXECUTOR EDITION
--  Paste langsung di Delta Executor console
--  Jalan di Roblox Studio Lite mode Edit
--  No LocalScript wrapper needed
-- ============================================================

-- cleanup dulu kalo udah ada instance sebelumnya
local oldGui = game.CoreGui:FindFirstChild("DeltaTerrainBuilder")
if oldGui then oldGui:Destroy() end

local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UserInputService= game:GetService("UserInputService")
local Workspace       = game:GetService("Workspace")
local terrain         = Workspace.Terrain

-- di executor context kita pakai mouse dari Players.LocalPlayer
local player = Players.LocalPlayer
local mouse  = player:GetMouse()
local camera = Workspace.CurrentCamera

-- ============================================================
--  STATE
-- ============================================================
local state = {
	panelOpen    = true,
	activeTool   = "add",
	activeMat    = Enum.Material.Grass,
	brushSize    = 12,
	brushStrength= 0.4,
	brushShape   = "sphere",
	isPainting   = false,
	flatHeight   = nil,
	tab          = "tools",
}

-- ============================================================
--  MATERIALS
-- ============================================================
local MATERIALS = {
	{name="Grass",       mat=Enum.Material.Grass,       color=Color3.fromRGB(106,127,63),  icon="🌿"},
	{name="Ground",      mat=Enum.Material.Ground,      color=Color3.fromRGB(106,95,76),   icon="🟫"},
	{name="Sand",        mat=Enum.Material.Sand,        color=Color3.fromRGB(198,189,128), icon="🏜"},
	{name="Rock",        mat=Enum.Material.Rock,        color=Color3.fromRGB(102,108,111), icon="🪨"},
	{name="Sandstone",   mat=Enum.Material.Sandstone,   color=Color3.fromRGB(137,90,71),   icon="🧱"},
	{name="Slate",       mat=Enum.Material.Slate,       color=Color3.fromRGB(63,75,86),    icon="⬛"},
	{name="Basalt",      mat=Enum.Material.Basalt,      color=Color3.fromRGB(30,30,37),    icon="🌑"},
	{name="Limestone",   mat=Enum.Material.Limestone,   color=Color3.fromRGB(206,173,148), icon="🔲"},
	{name="Pavement",    mat=Enum.Material.Pavement,    color=Color3.fromRGB(148,148,140), icon="🛣"},
	{name="Cobblestone", mat=Enum.Material.Cobblestone, color=Color3.fromRGB(132,123,90),  icon="🪵"},
	{name="Brick",       mat=Enum.Material.Brick,       color=Color3.fromRGB(150,85,59),   icon="🧱"},
	{name="Snow",        mat=Enum.Material.Snow,        color=Color3.fromRGB(195,199,218), icon="❄"},
	{name="Ice",         mat=Enum.Material.Ice,         color=Color3.fromRGB(129,194,224), icon="🧊"},
	{name="Glacier",     mat=Enum.Material.Glacier,     color=Color3.fromRGB(159,195,232), icon="🏔"},
	{name="Water",       mat=Enum.Material.Water,       color=Color3.fromRGB(40,120,196),  icon="💧"},
	{name="Mud",         mat=Enum.Material.Mud,         color=Color3.fromRGB(58,46,36),    icon="🌑"},
	{name="LeafyGrass",  mat=Enum.Material.LeafyGrass,  color=Color3.fromRGB(96,150,42),   icon="🍃"},
	{name="WoodPlanks",  mat=Enum.Material.WoodPlanks,  color=Color3.fromRGB(159,118,82),  icon="🪵"},
	{name="Wood",        mat=Enum.Material.Wood,        color=Color3.fromRGB(122,85,55),   icon="🌳"},
	{name="Lava",        mat=Enum.Material.Lava,        color=Color3.fromRGB(220,60,0),    icon="🌋"},
	{name="Asphalt",     mat=Enum.Material.Asphalt,     color=Color3.fromRGB(50,50,50),    icon="🛤"},
	{name="CrackedLava", mat=Enum.Material.CrackedLava, color=Color3.fromRGB(90,25,0),     icon="🔥"},
}

local TOOLS = {
	{id="add",    name="Add",     key="1"},
	{id="sub",    name="Remove",  key="2"},
	{id="paint",  name="Paint",   key="3"},
	{id="smooth", name="Smooth",  key="4"},
	{id="flat",   name="Flatten", key="5"},
	{id="grow",   name="Grow",    key="6"},
	{id="erode",  name="Erode",   key="7"},
}

-- ============================================================
--  COLOR PALETTE
-- ============================================================
local C = {
	bg       = Color3.fromRGB(37,37,37),
	panel    = Color3.fromRGB(46,46,46),
	sidebar  = Color3.fromRGB(30,30,30),
	header   = Color3.fromRGB(27,27,27),
	border   = Color3.fromRGB(60,60,60),
	accent   = Color3.fromRGB(0,162,255),
	accentH  = Color3.fromRGB(30,180,255),
	text     = Color3.fromRGB(220,220,220),
	textDim  = Color3.fromRGB(140,140,140),
	btnN     = Color3.fromRGB(55,55,55),
	btnH     = Color3.fromRGB(70,70,70),
	btnAct   = Color3.fromRGB(0,120,215),
	matSel   = Color3.fromRGB(0,100,180),
	danger   = Color3.fromRGB(200,60,60),
	success  = Color3.fromRGB(60,180,80),
	slider   = Color3.fromRGB(80,80,80),
}

-- ============================================================
--  HELPERS
-- ============================================================
local function corner(p, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 4)
	c.Parent = p
end

local function pad(p,t,r,b,l)
	local u = Instance.new("UIPadding")
	u.PaddingTop=UDim.new(0,t) u.PaddingRight=UDim.new(0,r)
	u.PaddingBottom=UDim.new(0,b) u.PaddingLeft=UDim.new(0,l)
	u.Parent=p
end

local function lbl(parent,txt,size,bold,col,xalign)
	local l=Instance.new("TextLabel")
	l.Text=txt l.TextSize=size or 13
	l.Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham
	l.TextColor3=col or C.text
	l.BackgroundTransparency=1
	l.TextXAlignment=xalign or Enum.TextXAlignment.Left
	l.AutomaticSize=Enum.AutomaticSize.XY
	l.Parent=parent
	return l
end

local function hover(btn,n,h)
	btn.MouseEnter:Connect(function() btn.BackgroundColor3=h end)
	btn.MouseLeave:Connect(function() btn.BackgroundColor3=n end)
end

local function stroke(p, col, thick)
	local s=Instance.new("UIStroke")
	s.Color=col or C.border s.Thickness=thick or 1
	s.Parent=p return s
end

local function secHeader(parent, title, order)
	local f=Instance.new("Frame")
	f.Size=UDim2.new(1,0,0,26) f.BackgroundColor3=C.header
	f.BorderSizePixel=0 f.LayoutOrder=order f.Parent=parent
	local l=Instance.new("TextLabel")
	l.Size=UDim2.new(1,0,1,0) l.BackgroundTransparency=1
	l.Text="  "..title l.TextSize=10 l.Font=Enum.Font.GothamBold
	l.TextColor3=C.textDim l.TextXAlignment=Enum.TextXAlignment.Left
	l.Parent=f
	return f
end

-- ============================================================
--  GUI ROOT — pakai CoreGui supaya muncul di Studio Lite edit mode
-- ============================================================
local gui = Instance.new("ScreenGui")
gui.Name="DeltaTerrainBuilder"
gui.ResetOnSpawn=false
gui.IgnoreGuiInset=true
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.Parent=game.CoreGui   -- <-- kunci buat executor

-- ============================================================
--  TOGGLE BUTTON
-- ============================================================
local toggleBtn=Instance.new("TextButton")
toggleBtn.Size=UDim2.new(0,44,0,44)
toggleBtn.Position=UDim2.new(0,12,0.5,-22)
toggleBtn.BackgroundColor3=C.accentH
toggleBtn.BorderSizePixel=0
toggleBtn.Text="🏔" toggleBtn.TextSize=22
toggleBtn.Font=Enum.Font.GothamBold
toggleBtn.TextColor3=Color3.new(1,1,1)
toggleBtn.ZIndex=100 toggleBtn.Parent=gui
corner(toggleBtn,10)

-- ============================================================
--  MAIN PANEL
-- ============================================================
local panel=Instance.new("Frame")
panel.Name="MainPanel"
panel.Size=UDim2.new(0,320,0,540)
panel.Position=UDim2.new(0,64,0.5,-270)
panel.BackgroundColor3=C.bg
panel.BorderSizePixel=0
panel.ZIndex=50
panel.Visible=true
panel.Parent=gui
corner(panel,8)
stroke(panel)

-- HEADER
local hdr=Instance.new("Frame")
hdr.Size=UDim2.new(1,0,0,38)
hdr.BackgroundColor3=C.header
hdr.BorderSizePixel=0 hdr.ZIndex=51 hdr.Parent=panel
stroke(hdr)

local hTitle=Instance.new("TextLabel")
hTitle.Size=UDim2.new(1,-80,1,0) hTitle.Position=UDim2.new(0,38,0,0)
hTitle.Text="🏔  Delta Terrain Builder" hTitle.TextSize=13
hTitle.Font=Enum.Font.GothamBold hTitle.TextColor3=C.text
hTitle.BackgroundTransparency=1 hTitle.TextXAlignment=Enum.TextXAlignment.Left
hTitle.Parent=hdr

local closeBtn=Instance.new("TextButton")
closeBtn.Size=UDim2.new(0,26,0,26) closeBtn.Position=UDim2.new(1,-32,0,6)
closeBtn.BackgroundColor3=Color3.fromRGB(196,43,28)
closeBtn.BorderSizePixel=0 closeBtn.Text="×" closeBtn.TextSize=18
closeBtn.Font=Enum.Font.GothamBold closeBtn.TextColor3=Color3.new(1,1,1)
closeBtn.ZIndex=52 closeBtn.Parent=hdr
corner(closeBtn,5)
hover(closeBtn,Color3.fromRGB(196,43,28),Color3.fromRGB(230,60,45))

-- DRAG
do
	local drag,ds,sp
	hdr.InputBegan:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 then
			drag=true ds=i.Position sp=panel.Position
		end
	end)
	hdr.InputEnded:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
			local d=i.Position-ds
			panel.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
		end
	end)
end

-- TAB BAR
local tabBar=Instance.new("Frame")
tabBar.Size=UDim2.new(1,0,0,30) tabBar.Position=UDim2.new(0,0,0,38)
tabBar.BackgroundColor3=C.sidebar tabBar.BorderSizePixel=0
tabBar.ZIndex=51 tabBar.Parent=panel

local tabLL=Instance.new("UIListLayout")
tabLL.FillDirection=Enum.FillDirection.Horizontal
tabLL.SortOrder=Enum.SortOrder.LayoutOrder tabLL.Parent=tabBar

local tabDefs={
	{id="tools",label="Tools"},
	{id="materials",label="Materials"},
	{id="settings",label="Settings"},
}
local tabBtns={}

for i,td in ipairs(tabDefs) do
	local b=Instance.new("TextButton")
	b.Size=UDim2.new(0,106,0,30) b.BackgroundColor3=C.sidebar
	b.BorderSizePixel=0 b.Text=td.label b.TextSize=12
	b.Font=Enum.Font.GothamBold b.TextColor3=C.textDim
	b.LayoutOrder=i b.ZIndex=52 b.Parent=tabBar
	tabBtns[td.id]=b
end

local tabLine=Instance.new("Frame")
tabLine.Size=UDim2.new(0,106,0,2) tabLine.Position=UDim2.new(0,0,1,-2)
tabLine.BackgroundColor3=C.accent tabLine.BorderSizePixel=0
tabLine.ZIndex=53 tabLine.Parent=tabBar

-- CONTENT
local content=Instance.new("Frame")
content.Size=UDim2.new(1,0,1,-92)
content.Position=UDim2.new(0,0,0,68)
content.BackgroundColor3=C.panel
content.BorderSizePixel=0 content.ClipsDescendants=true
content.ZIndex=51 content.Parent=panel

-- STATUS BAR
local statusBar=Instance.new("Frame")
statusBar.Size=UDim2.new(1,0,0,24)
statusBar.Position=UDim2.new(0,0,1,-24)
statusBar.BackgroundColor3=C.header
statusBar.BorderSizePixel=0 statusBar.ZIndex=51 statusBar.Parent=panel

local statusLbl=Instance.new("TextLabel")
statusLbl.Size=UDim2.new(1,-8,1,0) statusLbl.Position=UDim2.new(0,8,0,0)
statusLbl.BackgroundTransparency=1 statusLbl.Text="Ready"
statusLbl.TextSize=10 statusLbl.Font=Enum.Font.Gotham
statusLbl.TextColor3=C.textDim statusLbl.TextXAlignment=Enum.TextXAlignment.Left
statusLbl.Parent=statusBar

local function setStatus(msg) statusLbl.Text=msg end

-- ============================================================
--  TOOLS PAGE
-- ============================================================
local toolsPage=Instance.new("ScrollingFrame")
toolsPage.Size=UDim2.new(1,0,1,0)
toolsPage.BackgroundTransparency=1 toolsPage.BorderSizePixel=0
toolsPage.ScrollBarThickness=4 toolsPage.ScrollBarImageColor3=C.accent
toolsPage.CanvasSize=UDim2.new(0,0,0,0)
toolsPage.AutomaticCanvasSize=Enum.AutomaticSize.Y
toolsPage.ZIndex=52 toolsPage.Visible=true toolsPage.Parent=content

local tpLL=Instance.new("UIListLayout")
tpLL.SortOrder=Enum.SortOrder.LayoutOrder
tpLL.Padding=UDim.new(0,0) tpLL.Parent=toolsPage

-- Tool Buttons
secHeader(toolsPage,"TOOL TYPE",1)

local toolGrid=Instance.new("Frame")
toolGrid.Size=UDim2.new(1,0,0,88) toolGrid.BackgroundTransparency=1
toolGrid.LayoutOrder=2 toolGrid.Parent=toolsPage
pad(toolGrid,6,6,6,8)

local tgLL=Instance.new("UIGridLayout")
tgLL.CellSize=UDim2.new(0,86,0,32)
tgLL.CellPadding=UDim2.new(0,4,0,4) tgLL.Parent=toolGrid

local toolBtns={}
local function setTool(id)
	state.activeTool=id
	for tid,b in pairs(toolBtns) do
		b.BackgroundColor3=tid==id and C.btnAct or C.btnN
		b.TextColor3=tid==id and Color3.new(1,1,1) or C.text
	end
	setStatus("Tool: "..id)
end

local toolIcons={add="+",sub="−",paint="P",smooth="~",flat="=",grow="↑",erode="↓"}
for _,t in ipairs(TOOLS) do
	local b=Instance.new("TextButton")
	b.Size=UDim2.new(0,86,0,32) b.BackgroundColor3=C.btnN
	b.BorderSizePixel=0
	b.Text=(toolIcons[t.id] or "")..  "  "..t.name.."  ["..t.key.."]"
	b.TextSize=11 b.Font=Enum.Font.Gotham
	b.TextColor3=C.text b.ZIndex=53 b.Parent=toolGrid
	corner(b,4) hover(b,C.btnN,C.btnH)
	toolBtns[t.id]=b
	b.MouseButton1Click:Connect(function() setTool(t.id) end)
end
setTool("add")

-- Brush Shape
secHeader(toolsPage,"BRUSH SHAPE",3)
local shapeRow=Instance.new("Frame")
shapeRow.Size=UDim2.new(1,0,0,42) shapeRow.BackgroundTransparency=1
shapeRow.LayoutOrder=4 shapeRow.Parent=toolsPage
pad(shapeRow,6,6,6,8)
local srLL=Instance.new("UIListLayout")
srLL.FillDirection=Enum.FillDirection.Horizontal
srLL.Padding=UDim.new(0,6) srLL.VerticalAlignment=Enum.VerticalAlignment.Center
srLL.Parent=shapeRow

local shapeBtns={}
local function setShape(id)
	state.brushShape=id
	for sid,b in pairs(shapeBtns) do
		b.BackgroundColor3=sid==id and C.btnAct or C.btnN
	end
end
for _,s in ipairs({{id="sphere",label="● Sphere"},{id="cylinder",label="⬤ Cylinder"},{id="box",label="■ Box"}}) do
	local b=Instance.new("TextButton")
	b.Size=UDim2.new(0,88,0,28) b.BackgroundColor3=C.btnN
	b.BorderSizePixel=0 b.Text=s.label b.TextSize=11
	b.Font=Enum.Font.Gotham b.TextColor3=C.text b.ZIndex=53 b.Parent=shapeRow
	corner(b,4) shapeBtns[s.id]=b
	b.MouseButton1Click:Connect(function() setShape(s.id) end)
end
setShape("sphere")

-- Slider helper
local function makeSlider(parent, order, labelTxt, minV, maxV, defV, colorFill, suffix, onChange)
	local sec=Instance.new("Frame")
	sec.Size=UDim2.new(1,0,0,52) sec.BackgroundTransparency=1
	sec.LayoutOrder=order sec.Parent=parent
	pad(sec,8,14,4,12)

	local valLbl=Instance.new("TextLabel")
	valLbl.Size=UDim2.new(1,0,0,16) valLbl.BackgroundTransparency=1
	valLbl.Text=labelTxt..tostring(defV)..suffix
	valLbl.TextSize=12 valLbl.Font=Enum.Font.Gotham
	valLbl.TextColor3=C.text valLbl.TextXAlignment=Enum.TextXAlignment.Left
	valLbl.Parent=sec

	local track=Instance.new("Frame")
	track.Size=UDim2.new(1,0,0,6)
	track.Position=UDim2.new(0,0,0,24)
	track.BackgroundColor3=C.slider track.BorderSizePixel=0
	track.Parent=sec corner(track,3)

	local pct0=(defV-minV)/(maxV-minV)

	local fill=Instance.new("Frame")
	fill.Size=UDim2.new(pct0,0,1,0)
	fill.BackgroundColor3=colorFill fill.BorderSizePixel=0
	fill.Parent=track corner(fill,3)

	local knob=Instance.new("TextButton")
	knob.Size=UDim2.new(0,14,0,14)
	knob.Position=UDim2.new(pct0,-7,0.5,-7)
	knob.BackgroundColor3=Color3.new(1,1,1)
	knob.BorderSizePixel=0 knob.Text="" knob.ZIndex=54
	knob.Parent=track corner(knob,7)

	local value=defV
	local dragging=false

	local function updateX(absX)
		local tx=track.AbsolutePosition.X
		local tw=track.AbsoluteSize.X
		local p=math.clamp((absX-tx)/tw,0,1)
		value=math.floor(minV+p*(maxV-minV))
		fill.Size=UDim2.new(p,0,1,0)
		knob.Position=UDim2.new(p,-7,0.5,-7)
		valLbl.Text=labelTxt..tostring(value)..suffix
		onChange(value)
	end

	knob.MouseButton1Down:Connect(function() dragging=true end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
			updateX(i.Position.X)
		end
	end)
	track.InputBegan:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 then
			updateX(UserInputService:GetMouseLocation().X)
		end
	end)

	return sec,valLbl
end

secHeader(toolsPage,"BRUSH SIZE",5)
makeSlider(toolsPage,6,"Size: ",2,64,12,C.accent,"",function(v)
	state.brushSize=v
end)

secHeader(toolsPage,"BRUSH STRENGTH",7)
makeSlider(toolsPage,8,"Strength: ",1,100,40,C.success,"%",function(v)
	state.brushStrength=v/100
end)

-- Flatten Height
secHeader(toolsPage,"FLATTEN HEIGHT",9)
local flatSec=Instance.new("Frame")
flatSec.Size=UDim2.new(1,0,0,42) flatSec.BackgroundTransparency=1
flatSec.LayoutOrder=10 flatSec.Parent=toolsPage
pad(flatSec,6,8,6,8)
local flatLL=Instance.new("UIListLayout")
flatLL.FillDirection=Enum.FillDirection.Horizontal
flatLL.Padding=UDim.new(0,8) flatLL.VerticalAlignment=Enum.VerticalAlignment.Center
flatLL.Parent=flatSec

local pickBtn=Instance.new("TextButton")
pickBtn.Size=UDim2.new(0,160,0,28) pickBtn.BackgroundColor3=C.btnN
pickBtn.BorderSizePixel=0 pickBtn.Text="Pick Height From Terrain"
pickBtn.TextSize=11 pickBtn.Font=Enum.Font.Gotham
pickBtn.TextColor3=C.text pickBtn.ZIndex=53 pickBtn.Parent=flatSec
corner(pickBtn,4) hover(pickBtn,C.btnN,C.btnH)

local flatHLbl=lbl(flatSec,"Y: auto",11,false,C.textDim)

pickBtn.MouseButton1Click:Connect(function()
	pickBtn.Text="Click on terrain..."
	pickBtn.BackgroundColor3=C.accentH
	local conn
	conn=mouse.Button1Down:Connect(function()
		conn:Disconnect()
		local pos=mouse.Hit.Position
		state.flatHeight=pos.Y
		flatHLbl.Text=string.format("Y: %.1f",pos.Y)
		pickBtn.Text="Pick Height From Terrain"
		pickBtn.BackgroundColor3=C.btnN
	end)
end)

-- ============================================================
--  MATERIALS PAGE
-- ============================================================
local matsPage=Instance.new("ScrollingFrame")
matsPage.Size=UDim2.new(1,0,1,0)
matsPage.BackgroundTransparency=1 matsPage.BorderSizePixel=0
matsPage.ScrollBarThickness=4 matsPage.ScrollBarImageColor3=C.accent
matsPage.CanvasSize=UDim2.new(0,0,0,0)
matsPage.AutomaticCanvasSize=Enum.AutomaticSize.Y
matsPage.ZIndex=52 matsPage.Visible=false matsPage.Parent=content

local mpWrapper=Instance.new("Frame")
mpWrapper.Size=UDim2.new(1,0,0,0) mpWrapper.AutomaticSize=Enum.AutomaticSize.Y
mpWrapper.BackgroundTransparency=1 mpWrapper.Parent=matsPage
pad(mpWrapper,8,8,8,8)

local mpGrid=Instance.new("UIGridLayout")
mpGrid.CellSize=UDim2.new(0,66,0,70)
mpGrid.CellPadding=UDim2.new(0,5,0,5) mpGrid.Parent=mpWrapper

local matBtns={}
local function setMat(mat,ref)
	state.activeMat=mat
	for _,m in ipairs(matBtns) do
		m.cell.BackgroundColor3=C.panel
		m.nameLbl.TextColor3=C.textDim
		local s=m.cell:FindFirstChildOfClass("UIStroke")
		if s then s.Color=C.border end
	end
	ref.cell.BackgroundColor3=C.matSel
	ref.nameLbl.TextColor3=Color3.new(1,1,1)
	local s=ref.cell:FindFirstChildOfClass("UIStroke")
	if s then s.Color=C.accent end
	setStatus("Material: "..tostring(mat):gsub("Enum.Material.",""))
end

for i,m in ipairs(MATERIALS) do
	local cell=Instance.new("Frame")
	cell.Size=UDim2.new(0,66,0,70) cell.BackgroundColor3=C.panel
	cell.BorderSizePixel=0 cell.ZIndex=53 cell.Parent=mpWrapper
	corner(cell,6) stroke(cell)

	local swatch=Instance.new("Frame")
	swatch.Size=UDim2.new(1,-6,0,34) swatch.Position=UDim2.new(0,3,0,3)
	swatch.BackgroundColor3=m.color swatch.BorderSizePixel=0
	swatch.Parent=cell corner(swatch,4)

	local ico=Instance.new("TextLabel")
	ico.Size=UDim2.new(1,0,1,0) ico.BackgroundTransparency=1
	ico.Text=m.icon ico.TextSize=18 ico.Font=Enum.Font.GothamBold
	ico.TextColor3=Color3.new(1,1,1) ico.Parent=swatch

	local nl=Instance.new("TextLabel")
	nl.Size=UDim2.new(1,-2,0,26) nl.Position=UDim2.new(0,1,0,38)
	nl.BackgroundTransparency=1 nl.Text=m.name
	nl.TextSize=9 nl.Font=Enum.Font.Gotham
	nl.TextColor3=C.textDim nl.TextWrapped=true nl.Parent=cell

	local ca=Instance.new("TextButton")
	ca.Size=UDim2.new(1,0,1,0) ca.BackgroundTransparency=1
	ca.Text="" ca.ZIndex=54 ca.Parent=cell

	local ref={cell=cell,nameLbl=nl}
	matBtns[i]=ref

	ca.MouseButton1Click:Connect(function() setMat(m.mat,ref) end)
	ca.MouseEnter:Connect(function()
		if state.activeMat~=m.mat then cell.BackgroundColor3=C.btnH end
	end)
	ca.MouseLeave:Connect(function()
		if state.activeMat~=m.mat then cell.BackgroundColor3=C.panel end
	end)
end
setMat(Enum.Material.Grass,matBtns[1])

-- ============================================================
--  SETTINGS PAGE
-- ============================================================
local settPage=Instance.new("ScrollingFrame")
settPage.Size=UDim2.new(1,0,1,0)
settPage.BackgroundTransparency=1 settPage.BorderSizePixel=0
settPage.ScrollBarThickness=4 settPage.ScrollBarImageColor3=C.accent
settPage.CanvasSize=UDim2.new(0,0,0,0)
settPage.AutomaticCanvasSize=Enum.AutomaticSize.Y
settPage.ZIndex=52 settPage.Visible=false settPage.Parent=content

local spLL=Instance.new("UIListLayout")
spLL.SortOrder=Enum.SortOrder.LayoutOrder
spLL.Padding=UDim.new(0,0) spLL.Parent=settPage

secHeader(settPage,"HOTKEYS",1)

local hotkeys={
	{"T","Toggle panel buka/tutup"},
	{"[","Brush size kurangin"},
	{"]","Brush size tambah"},
	{"M","Cycle material berikutnya"},
	{"1","Tool: Add"},
	{"2","Tool: Remove"},
	{"3","Tool: Paint"},
	{"4","Tool: Smooth"},
	{"5","Tool: Flatten"},
	{"6","Tool: Grow"},
	{"7","Tool: Erode"},
}

for i,hk in ipairs(hotkeys) do
	local row=Instance.new("Frame")
	row.Size=UDim2.new(1,0,0,32) row.BackgroundTransparency=1
	row.LayoutOrder=i+1 row.Parent=settPage
	pad(row,0,12,0,12)

	local badge=Instance.new("TextLabel")
	badge.Size=UDim2.new(0,24,0,20) badge.Position=UDim2.new(0,0,0.5,-10)
	badge.BackgroundColor3=C.btnN badge.BorderSizePixel=0
	badge.Text=hk[1] badge.TextSize=11 badge.Font=Enum.Font.GothamBold
	badge.TextColor3=C.text badge.Parent=row corner(badge,3)

	local dl=Instance.new("TextLabel")
	dl.Size=UDim2.new(1,-34,1,0) dl.Position=UDim2.new(0,32,0,0)
	dl.BackgroundTransparency=1 dl.Text=hk[2]
	dl.TextSize=11 dl.Font=Enum.Font.Gotham
	dl.TextColor3=C.textDim dl.TextXAlignment=Enum.TextXAlignment.Left
	dl.Parent=row
end

secHeader(settPage,"ABOUT",20)
local aboutF=Instance.new("Frame")
aboutF.Size=UDim2.new(1,0,0,70) aboutF.BackgroundTransparency=1
aboutF.LayoutOrder=21 aboutF.Parent=settPage
pad(aboutF,8,12,8,12)
local aboutLL=Instance.new("UIListLayout")
aboutLL.SortOrder=Enum.SortOrder.LayoutOrder
aboutLL.Padding=UDim.new(0,4) aboutLL.Parent=aboutF
local al1=lbl(aboutF,"Delta Terrain Builder v2.0",12,true,C.text)
al1.LayoutOrder=1
local al2=lbl(aboutF,"22 materials  •  7 tools  •  3 brush shapes",11,false,C.textDim)
al2.LayoutOrder=2
local al3=lbl(aboutF,"Build di mana aja — bukan cuma Baseplate",11,false,C.textDim)
al3.LayoutOrder=3

-- ============================================================
--  TAB SWITCH
-- ============================================================
local pages={tools=toolsPage,materials=matsPage,settings=settPage}

local function switchTab(id)
	state.tab=id
	for tid,b in pairs(tabBtns) do
		b.TextColor3=tid==id and C.text or C.textDim
		b.BackgroundColor3=tid==id and C.panel or C.sidebar
	end
	for _,p in pairs(pages) do p.Visible=false end
	pages[id].Visible=true
	local idx=0
	for i,td in ipairs(tabDefs) do if td.id==id then idx=i-1 break end end
	tabLine.Position=UDim2.new(0,idx*106,1,-2)
end

for _,td in ipairs(tabDefs) do
	tabBtns[td.id].MouseButton1Click:Connect(function() switchTab(td.id) end)
end

-- ============================================================
--  TOGGLE
-- ============================================================
local function togglePanel()
	state.panelOpen=not state.panelOpen
	panel.Visible=state.panelOpen
	toggleBtn.BackgroundColor3=state.panelOpen and C.accentH or C.btnAct
end

toggleBtn.MouseButton1Click:Connect(togglePanel)
closeBtn.MouseButton1Click:Connect(function()
	state.panelOpen=false panel.Visible=false
	toggleBtn.BackgroundColor3=C.btnAct
end)

-- ============================================================
--  TERRAIN OPS
-- ============================================================
local function applyTerrain(pos)
	local r  = state.brushSize
	local str= state.brushStrength
	local mat= state.activeMat
	local tool=state.activeTool

	if tool=="add" then
		if mat==Enum.Material.Water then
			terrain:FillBlock(CFrame.new(pos),Vector3.new(r*2,r*2,r*2),Enum.Material.Water)
		else
			terrain:FillBall(pos,r,mat)
		end

	elseif tool=="sub" then
		terrain:FillBall(pos,r,Enum.Material.Air)

	elseif tool=="paint" then
		-- paint: replace material di bola radius
		local half=Vector3.new(r,r,r)
		local reg=Region3.new(pos-half,pos+half)
		local ok,occ,mats=pcall(function()
			return terrain:ReadVoxels(reg,4)
		end)
		if ok and occ then
			for x=1,#occ do
				for y=1,#occ[x] do
					for z=1,#occ[x][y] do
						if occ[x][y][z]>0.1 then
							mats[x][y][z]=mat
						end
					end
				end
			end
			pcall(function() terrain:WriteVoxels(reg,4,occ,mats) end)
		end

	elseif tool=="smooth" then
		-- smooth: fill + erode ringan
		terrain:FillBall(pos,r,mat)
		for _=1,2 do
			local off=Vector3.new(
				math.random(-2,2),
				math.random(-1,1),
				math.random(-2,2)
			)
			terrain:FillBall(pos+off,math.max(2,r*0.4),Enum.Material.Air)
		end

	elseif tool=="flat" then
		local hy=state.flatHeight or pos.Y
		terrain:FillBlock(
			CFrame.new(pos.X,hy,pos.Z),
			Vector3.new(r*2,4,r*2),
			mat
		)
		terrain:FillBlock(
			CFrame.new(pos.X,hy+r,pos.Z),
			Vector3.new(r*2,r*2,r*2),
			Enum.Material.Air
		)

	elseif tool=="grow" then
		terrain:FillBall(pos+Vector3.new(0,r*0.5,0),r,mat)

	elseif tool=="erode" then
		for _=1,4 do
			local off=Vector3.new(
				math.random(-r,r)*0.7,
				math.random(-r,r)*0.7,
				math.random(-r,r)*0.7
			)
			terrain:FillBall(pos+off,math.max(1,r*0.25),Enum.Material.Air)
		end
	end
end

-- ============================================================
--  PAINT LOOP
-- ============================================================
local isPainting=false

mouse.Button1Down:Connect(function()
	-- cek apakah klik di GUI
	local gp=game:GetService("GuiService"):GetGuiInset()
	-- kalau target bukan terrain/workspace part, skip
	if mouse.Target and mouse.Target:IsDescendantOf(gui) then return end
	isPainting=true
end)
mouse.Button1Up:Connect(function() isPainting=false end)

local cooldown=0
RunService.RenderStepped:Connect(function(dt)
	if not isPainting then return end
	cooldown=cooldown-dt
	if cooldown>0 then return end
	cooldown=0.06

	local unitRay=camera:ScreenPointToRay(mouse.X,mouse.Y)
	local ray=Ray.new(unitRay.Origin,unitRay.Direction*2000)

	-- raycast semua object, bukan cuma baseplate
	local hit,pos=workspace:FindPartOnRayWithIgnoreList(ray,{
		player.Character,
		gui
	})

	if pos then
		applyTerrain(pos)
		setStatus(string.format("[%s] %s | Brush:%d Str:%.0f%% | %.0f,%.0f,%.0f",
			state.activeTool:upper(),
			tostring(state.activeMat):gsub("Enum.Material.",""),
			state.brushSize, state.brushStrength*100,
			pos.X, pos.Y, pos.Z
		))
	end
end)

-- ============================================================
--  BRUSH PREVIEW
-- ============================================================
local brushPart=Instance.new("Part")
brushPart.Anchored=true brushPart.CanCollide=false
brushPart.Transparency=1 brushPart.CastShadow=false
brushPart.Name="DTBrushPreview" brushPart.Parent=workspace

local selBox=Instance.new("SelectionBox")
selBox.SurfaceTransparency=0.75
selBox.Color3=C.accent selBox.LineThickness=0.04
selBox.Adornee=brushPart selBox.Parent=workspace

RunService.RenderStepped:Connect(function()
	local unitRay=camera:ScreenPointToRay(mouse.X,mouse.Y)
	local ray=Ray.new(unitRay.Origin,unitRay.Direction*2000)
	local _,pos=workspace:FindPartOnRayWithIgnoreList(ray,{player.Character,gui})
	if pos then
		brushPart.Position=pos
		brushPart.Size=Vector3.new(state.brushSize*2,state.brushSize*2,state.brushSize*2)
		selBox.Color3=state.activeTool=="sub" and C.danger or C.accent
	end
end)

-- ============================================================
--  HOTKEYS
-- ============================================================
UserInputService.InputBegan:Connect(function(inp,gpe)
	if gpe then return end
	local k=inp.KeyCode
	if     k==Enum.KeyCode.LeftBracket  then state.brushSize=math.max(2,state.brushSize-2);   setStatus("Brush size: "..state.brushSize)
	elseif k==Enum.KeyCode.RightBracket then state.brushSize=math.min(64,state.brushSize+2);  setStatus("Brush size: "..state.brushSize)
	elseif k==Enum.KeyCode.T            then togglePanel()
	elseif k==Enum.KeyCode.M            then
		local cur=1
		for i,m in ipairs(MATERIALS) do if m.mat==state.activeMat then cur=i break end end
		local nx=cur%#MATERIALS+1
		setMat(MATERIALS[nx].mat,matBtns[nx])
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
switchTab("tools")
setStatus("Delta Terrain Builder ready — T: toggle | [ ]: brush size")
print("[DTB] Delta Terrain Builder v2.0 loaded via executor ✅")
print("[DTB] CoreGui parent = jalan di edit mode Studio Lite")
