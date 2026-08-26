--[[
    LANGZ IMPORTER v62.0 - Dark Purple Theme
    GUI: Landscape 520x270, Black + Purple + White
    Topbar: slim toggle buka/tutup animasi tween
    Progress: live bar saat import berlangsung
    Parser: Binary LZ4 + RBXM/RBXL
    Supports: RBXM, RBXL, RBXLX, RBXMX
]]

if not game:IsLoaded() then game.Loaded:Wait() end

-- WHITELIST
local _WL = { 10955292268 }
local _uid = game:GetService("Players").LocalPlayer.UserId
local _ok = false
for _,id in ipairs(_WL) do if id == _uid then _ok=true; break end end
if not _ok then
    warn("have you tried opening this script its not easy my friend")
    warn("KALO KALIAN MAU BELI IMPORT RBXM NYA LANGSUNG AJA HUBUNGI LANGZ, 088102294723 KING LANGZ")
    return
end

-- SERVICES
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService       = game:GetService("HttpService")
local UserInputService  = game:GetService("UserInputService")
local InsertService     = game:GetService("InsertService")
local CoreGui           = game:GetService("CoreGui")
local TweenService      = game:GetService("TweenService")
local LocalPlayer       = Players.LocalPlayer
local CoreDest          = pcall(function() return CoreGui.Name end) and CoreGui or LocalPlayer:WaitForChild("PlayerGui")
_G.LANGZ_RAW_SOURCES    = _G.LANGZ_RAW_SOURCES or {}

-- THEME
local C = {
    BG      = Color3.fromRGB(8,8,12),      PANEL  = Color3.fromRGB(13,11,20),
    CARD    = Color3.fromRGB(18,14,28),    TOPBAR = Color3.fromRGB(10,8,18),
    ACCENT  = Color3.fromRGB(130,60,220),  ACCENT2= Color3.fromRGB(185,115,255),
    STROKE  = Color3.fromRGB(95,45,185),   STROKE2= Color3.fromRGB(55,28,100),
    TEXT    = Color3.fromRGB(240,235,255), TEXTDIM= Color3.fromRGB(155,140,190),
    TEXTMUTE= Color3.fromRGB(95,80,135),   SUCCESS= Color3.fromRGB(110,225,135),
    FAIL    = Color3.fromRGB(225,75,75),   BADGEL = Color3.fromRGB(125,55,215),
    BADGEM  = Color3.fromRGB(55,38,85),    SCROLL = Color3.fromRGB(115,55,195),
}
local ICONS = {
    PACKAGE ="rbxassetid://10709791437", SEARCH  ="rbxassetid://10709796118",
    FILE    ="rbxassetid://10709790948", GAMEPAD ="rbxassetid://10709790082",
    DOWNLOAD="rbxassetid://10709791283", CHECK   ="rbxassetid://10709790240",
    ALERT   ="rbxassetid://10709790520", REFRESH ="rbxassetid://10709793382",
    BELL    ="rbxassetid://10709791160",
}
local TI_F = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TI_M = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local function tw(o,ti,p) TweenService:Create(o,ti,p):Play() end
local function mkC(p,r) local c=Instance.new("UICorner",p); c.CornerRadius=UDim.new(0,r or 6) end
local function mkS(p,col,th,tr) local s=Instance.new("UIStroke",p); s.Color=col or C.STROKE2; s.Thickness=th or 1; s.Transparency=tr or 0.15 end
﻿
-- ===== BINARY PARSER LZ4 + RBXM =====
local function Buffer(str)
    local S={Offset=0,Source=str,Length=#str}
    function S:read(len,shift) len=len or 1;shift=(shift==nil and true) or shift;local d=string.sub(self.Source,self.Offset+1,self.Offset+len);if shift then self.Offset=math.clamp(self.Offset+len,0,self.Length) end;return d end
    function S:seek(len) self.Offset=math.clamp(self.Offset+len,0,self.Length) end
    function S:rN(fmt,shift) fmt=fmt or "I1";local c=self:read(string.packsize(fmt),shift);return string.unpack(fmt,c) end
    function S:append(s) self.Source=self.Source..s;self.Length=#self.Source end
    function S:toEnd() self.Offset=self.Length end
    return S
end
local function tInt(x) return(x%2==0)and(x/2)or(-(x+1)/2) end
local function rbxF32(x) x=bit32.rrotate(x,1);return string.unpack(">f",string.pack(">I4",x)) end
local bT={}
function bT.Str(b) return b:read(b:rN("<I4")) end
function bT.I32(b) return tInt(b:rN(">I4")) end
function bT.F32(b) return rbxF32(b:rN(">I4")) end
function bT.F64(b) return b:rN("<d") end
function bT.Ilv(b,count,sz)
    if count<0 then return Buffer("") end
    local stream=b:read(count*sz);local out=table.create(count)
    for i=1,count do local chunk=table.create(sz);for s=0,sz-1 do local bp=i+(count*s);chunk[s+1]=string.sub(stream,bp,bp) end;out[i]=table.concat(chunk) end
    return Buffer(table.concat(out))
end
function bT.I32Arr(b,n) if n<1 then return {} end;local o=table.create(n);local s=bT.Ilv(b,n,4);for i=1,n do o[i]=bT.I32(s) end;return o end
function bT.F32Arr(b,n) if n<1 then return {} end;local o=table.create(n);local s=bT.Ilv(b,n,4);for i=1,n do o[i]=bT.F32(s) end;return o end
function bT.RefArr(b,n)
    if n<1 then return {} end;local o=table.create(n);local refs=bT.I32Arr(b,n);local last=0
    for i=1,n do local r=last+refs[i];o[i]=r;last=r end;return o
end
local function lz4(data)
    local inp=Buffer(data)
    local cL=string.unpack("<I4",inp:read(4));local dL=string.unpack("<I4",inp:read(4));local rsv=string.unpack("<I4",inp:read(4))
    if rsv~=0 then error("not lz4") end
    if cL==0 then return inp:read(dL) end
    local out=Buffer("")
    repeat
        local tok=string.byte(inp:read());local litL=bit32.rshift(tok,4);local matL=bit32.band(tok,15)+4
        if litL>=15 then repeat local nb=string.byte(inp:read());litL=litL+nb until nb~=0xFF end
        out:append(inp:read(litL));out:toEnd()
        if out.Length<dL then
            local off=string.unpack("<I2",inp:read(2))
            if matL>=19 then repeat local nb=string.byte(inp:read());matL=matL+nb until nb~=0xFF end
            out:seek(-off);local pos=out.Offset;local match=out:read(matL)
            local unread=out.LastUnreadBytes or 0
            if unread then repeat out.Offset=pos;local ex=out:read(unread);unread=out.LastUnreadBytes or 0;match=match..ex until unread<=0 end
            out:append(match);out:toEnd()
        end
    until out.Length>=dL
    return out.Source
end
local function b64enc(str)
    local chars="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local out={}
    for i=1,#str,3 do
        local b0,b1,b2=string.byte(str,i,i+2);local b=bit32.lshift(b0,16)+bit32.lshift(b1 or 0,8)+(b2 or 0)
        table.insert(out,chars:sub(bit32.extract(b,18,6)+1,bit32.extract(b,18,6)+1))
        table.insert(out,chars:sub(bit32.extract(b,12,6)+1,bit32.extract(b,12,6)+1))
        table.insert(out,b1 and chars:sub(bit32.extract(b,6,6)+1,bit32.extract(b,6,6)+1) or "=")
        table.insert(out,b2 and chars:sub(bit32.band(b,63)+1,bit32.band(b,63)+1) or "=")
    end
    return table.concat(out)
end
local function zstd(s) local x=HttpService:JSONDecode('{"m":null,"t":"buffer","zbase64":"'..b64enc(s)..'"}'); return buffer.tostring(x) end
local function parseRBXM(data)
    local sources={};local buf=Buffer(data)
    if buf:read(8)~="<roblox!" or buf:read(6)~=string.char(137,255,13,10,26,10) then return sources,"Invalid header" end
    if buf:read(2)~=(string.char(0)..string.char(0)) then return sources,"Invalid version" end
    buf:rN("<i4");buf:rN("<i4")
    local cRefs,vI,chunks={},{},{}
    local _EC="END"..string.char(0)
    local valid={[_EC]=true,["INST"]=true,["META"]=true,["PRNT"]=true,["PROP"]=true,["SIGN"]=true,["SSTR"]=true}
    for k in pairs(valid) do chunks[k]={} end
    if buf:read(8)~=string.char(0,0,0,0,0,0,0,0) then return sources,"Bad header2" end
    local last=nil
    repeat
        local ch={Header=buf:read(4)};if not valid[ch.Header] then return sources,"Bad chunk" end
        local lzH=buf:read(16,false)
        local comp=string.unpack("<I4",string.sub(lzH,1,4));local decomp=string.unpack("<I4",string.sub(lzH,5,8))
        local zc=string.sub(lzH,13,16);local dc
        if comp==0 then dc=buf:read(decomp+12)
        elseif zc==string.char(40,181,47,253) then buf:seek(12);dc=zstd(buf:read(comp))
        else dc=lz4(buf:read(comp+12)) end
        ch.Data=Buffer(dc);table.insert(chunks[ch.Header],ch);last=ch
    until last and last.Header==_EC
    local strings={}
    for _,ch in ipairs(chunks["SSTR"] or {}) do
        local b=ch.Data;if b:rN("<I4")==0 then for i=1,b:rN("<I4") do b:read(16);strings[i]=bT.Str(b) end end
    end
    for _,ch in ipairs(chunks["INST"] or {}) do
        local b=ch.Data;local cid=b:rN("<I4");local cname=bT.Str(b)
        if b:read()=="\1" then return sources,"Contains services" end
        local count=b:rN("<I4");local refs=bT.RefArr(b,count)
        cRefs[cid]={Name=cname,Sizeof=count,Refs=refs}
        for _,ref in ipairs(refs) do vI[ref]={ClassName=cname,Ref=ref,Properties={},Children={}} end
    end
    for _,ch in ipairs(chunks["PROP"] or {}) do
        local b=ch.Data;local cid=b:rN("<I4");local cr=cRefs[cid]
        if not cr then return sources,"Missing classref" end
        local refs=cr.Refs;local sizeof=cr.Sizeof;local name=bT.Str(b)
        if string.byte(b:read(1,false))==0x1E then b:seek(1) end
        local typeID=string.byte(b:read());local props={}
        if typeID==0x01 or typeID==0x1D then for i=1,sizeof do props[i]=bT.Str(b) end
        elseif typeID==0x02 then for i=1,sizeof do props[i]=b:read()~=string.char(0) end
        elseif typeID==0x03 then props=bT.I32Arr(b,sizeof)
        elseif typeID==0x04 then props=bT.F32Arr(b,sizeof)
        elseif typeID==0x05 then for i=1,sizeof do props[i]=bT.F64(b) end
        else for i=1,sizeof do if typeID==0x13 then props=bT.RefArr(b,sizeof);break else b:read(4) end end end
        if name=="Source" or name=="ContentText" then
            for i,v in ipairs(refs) do if vI[v] and props[i] then vI[v].Properties[name]=props[i] end end
        end
    end
    local function bldMap(node,path)
        local src=node.Properties["Source"] or node.Properties["ContentText"]
        if src and type(src)=="string" and #src>0 then sources[path]=src end
        for _,child in ipairs(node.Children or {}) do bldMap(child,path.."."..child.ClassName..":"..(child.Properties["Name"] or "unnamed")) end
    end
    for _,ch in ipairs(chunks["PRNT"] or {}) do
        local b=ch.Data;if b:read()~=string.char(0) then return sources,"Bad PRNT" end
        local count=b:rN("<I4");local cr=bT.RefArr(b,count);local pr=bT.RefArr(b,count)
        for i=1,count do local child=vI[cr[i]];local parent=vI[pr[i]];if child and parent then table.insert(parent.Children,child) end end
    end
    local roots={}
    for _,inst in pairs(vI) do
        local hp=false
        for _,other in pairs(vI) do for _,child in ipairs(other.Children or {}) do if child.Ref==inst.Ref then hp=true;break end end;if hp then break end end
        if not hp then table.insert(roots,inst) end
    end
    for _,root in ipairs(roots) do bldMap(root,root.ClassName..":"..(root.Properties["Name"] or "root")) end
    return sources,nil
end
﻿
-- ===== STUDIO LITE INTEGRATION =====
local slF=ReplicatedStorage:FindFirstChild("StudioLiteFolder")
local sF=slF and slF:FindFirstChild("ServerFunctions")
local function tSL(idStr) if not sF or not idStr or idStr=="" then return end;local id=tostring(idStr):match("%d+");if id then pcall(function() sF:InvokeServer("LoadMeshToRuntimeMeshes",tonumber(id)) end) end end
local SL_CACHE={}
local function injectSL(scr,srcMap)
    if not scr:IsA("LuaSourceContainer") then return end
    local path=scr.ClassName..":"..scr.Name;local rS=srcMap and srcMap[path]
    if not rS then pcall(function() rS=scr.Source end) end
    if rS and #rS>0 then rS=rS:gsub(string.char(0).."*$","") else rS="-- [LANGZ] Source tidak ditemukan." end
    _G.LANGZ_RAW_SOURCES[scr]=rS
    local UT=rS;if #UT>150000 then UT="-- [LANGZ] Terlalu panjang.\n"..string.sub(UT,1,150000).."\n-- [TERPOTONG]" end
    local eTB=scr:FindFirstChild("SL_CodeTextBox")
    if eTB then eTB.Text=UT;if scr.ClassName=="ModuleScript" then local ro=scr:FindFirstChild("SL_1ReadOnly");if ro then ro.ContentText=UT;ro.Text=UT end end;return end
    if not sF then return end
    local map={Script="InsertScriptScript",LocalScript="InsertLocalScriptLocalScript",ModuleScript="InsertModuleScriptModuleScript"}
    local aN=map[scr.ClassName];if not aN then return end
    if not SL_CACHE[aN] then
        pcall(function()
            sF:InvokeServer("LoadAssetToPlayerGui",aN)
            local gF=LocalPlayer:WaitForChild("PlayerGui"):WaitForChild(aN,3)
            if gF then SL_CACHE[aN]={};for _,c in ipairs(gF:GetChildren()) do table.insert(SL_CACHE[aN],c:Clone()) end;sF:InvokeServer("ClearAssetFromPlayerGui",aN) end
        end)
    end
    if not SL_CACHE[aN] then return end
    pcall(function()
        for _,c in ipairs(SL_CACHE[aN]) do c:Clone().Parent=scr end
        local tb=scr:FindFirstChild("SL_CodeTextBox")
        if tb then tb.Text=UT;if scr.ClassName=="ModuleScript" then local ro=scr:FindFirstChild("SL_1ReadOnly");if ro then ro.ContentText=UT;ro.Text=UT end end end
    end)
end
local function injScripts(root,srcMap)
    if not root then return 0 end;local list={}
    if root:IsA("LuaSourceContainer") then table.insert(list,root) end
    for _,d in ipairs(root:GetDescendants()) do if d:IsA("LuaSourceContainer") then table.insert(list,d) end end
    local n=0;for _,s in ipairs(list) do pcall(injectSL,s,srcMap);n=n+1;task.wait(0.02) end;return n
end
local function applySLP(obj)
    if not obj then return end;pcall(function() if obj:IsA("BasePart") then obj.Anchored=true end end)
    for _,ch in ipairs(obj:GetChildren()) do applySLP(ch) end
end
local function ldAssets(obj)
    local function sc(n)
        pcall(function()
            if n:IsA("MeshPart") then tSL(n.MeshId);tSL(n.TextureID)
            elseif n:IsA("Decal") or n:IsA("Texture") then tSL(n.Texture)
            elseif n:IsA("SpecialMesh") then tSL(n.MeshId);tSL(n.TextureId)
            elseif n:IsA("UnionOperation") or n:IsA("PartOperation") then tSL(n.AssetId) end
        end)
        for _,ch in ipairs(n:GetChildren()) do sc(ch) end
    end;sc(obj)
end
local SVC={Workspace=workspace,ReplicatedStorage=ReplicatedStorage,ReplicatedFirst=game:GetService("ReplicatedFirst"),
    StarterGui=game:GetService("StarterGui"),StarterPack=game:GetService("StarterPack"),StarterPlayer=game:GetService("StarterPlayer"),
    Lighting=game:GetService("Lighting"),SoundService=game:GetService("SoundService"),
    ServerScriptService=_G.sss or ReplicatedStorage,ServerStorage=_G.ss or ReplicatedStorage,Teams=ReplicatedStorage,Chat=ReplicatedStorage}
local function insObjs(objects,isL,srcMap)
    local n=0
    for _,obj in ipairs(objects) do
        pcall(function()
            local tgt=(isL and(SVC[obj.ClassName] or SVC[obj.Name])) or workspace
            if tgt==workspace and obj:IsA("Service") then tgt=ReplicatedStorage end
            if isL and tgt~=workspace then
                for _,ch in ipairs(obj:GetChildren()) do pcall(function() ch.Parent=tgt;injScripts(ch,srcMap);applySLP(ch);ldAssets(ch);n=n+1 end);task.wait(0.01) end
            else obj.Parent=tgt;injScripts(obj,srcMap);applySLP(obj);ldAssets(obj);n=n+1 end
        end)
    end;return n
end
local function safeRead(p) if not readfile then return nil end;local ok,d=pcall(readfile,p);return ok and d or nil end

-- ===== FILE SCANNER =====
local function safeList(p) if not listfiles then return nil end;local ok,f=pcall(listfiles,p);return ok and f or nil end
local function fname(p) return p:match("([^/]+)$") or p end
local function ftype(n) n=n:lower();if n:match("%.rbxlx?$") then return "RBXL" elseif n:match("%.rbxmx?$") then return "RBXM" end;return nil end
local function isDir(p) return not fname(p):match("%.[%a%d]+") end
local PATHS={"workspace","Delta/workspace","delta/workspace","Android/Delta/workspace","/sdcard/Delta/workspace","/sdcard/Android/Delta/workspace","../workspace",".",""}
local function deepScan(folder,depth,res,seen)
    if depth>4 or seen[folder] then return end;seen[folder]=true
    local list=safeList(folder);if not list then return end
    for _,path in ipairs(list) do
        local n=fname(path);local ft=ftype(n)
        if ft and not seen[path] then seen[path]=true;table.insert(res,{name=n,path=path,ftype=ft})
        elseif isDir(path) then deepScan(path,depth+1,res,seen) end
    end
end
local function scanAll() local res,seen={},{};for _,p in ipairs(PATHS) do if safeList(p) then deepScan(p,0,res,seen) end end;return res end

-- ===== DESTROY OLD =====
if CoreDest:FindFirstChild("LANGZv62UI") then CoreDest.LANGZv62UI:Destroy() end
﻿
-- ===== GUI BUILD =====
local UI=Instance.new("ScreenGui",CoreDest)
UI.Name="LANGZv62UI";UI.ResetOnSpawn=false;UI.DisplayOrder=100;UI.IgnoreGuiInset=true

-- TOPBAR slim (265x26) tengah atas, bisa di-drag
local TB=Instance.new("Frame",UI)
TB.Size=UDim2.new(0,265,0,26);TB.Position=UDim2.new(0.5,-132,0,5)
TB.BackgroundColor3=C.TOPBAR;TB.BorderSizePixel=0;mkC(TB,8);mkS(TB,C.STROKE,1.2,0.1)
local tbGrad=Instance.new("UIGradient",TB)
tbGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(18,8,32)),ColorSequenceKeypoint.new(0.5,Color3.fromRGB(45,18,80)),ColorSequenceKeypoint.new(1,Color3.fromRGB(18,8,32))})
local tbIco=Instance.new("ImageLabel",TB)
tbIco.Size=UDim2.new(0,13,0,13);tbIco.Position=UDim2.new(0,8,0.5,-6);tbIco.BackgroundTransparency=1;tbIco.Image=ICONS.PACKAGE;tbIco.ImageColor3=C.ACCENT2
local tbLbl=Instance.new("TextLabel",TB)
tbLbl.Size=UDim2.new(1,-70,1,0);tbLbl.Position=UDim2.new(0,26,0,0);tbLbl.BackgroundTransparency=1
tbLbl.Text="LANGZ IMPORTER v62";tbLbl.TextColor3=C.TEXT;tbLbl.Font=Enum.Font.GothamBold;tbLbl.TextSize=11;tbLbl.TextXAlignment=Enum.TextXAlignment.Left
local TogBtn=Instance.new("TextButton",TB)
TogBtn.Size=UDim2.new(0,56,0,18);TogBtn.Position=UDim2.new(1,-60,0.5,-9);TogBtn.BackgroundColor3=C.ACCENT;TogBtn.BorderSizePixel=0
TogBtn.Text="HIDE";TogBtn.TextColor3=Color3.fromRGB(255,255,255);TogBtn.Font=Enum.Font.GothamBold;TogBtn.TextSize=9;mkC(TogBtn,5)
-- Drag topbar
local tDrg,tDS,tSP
TB.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then tDrg=true;tDS=inp.Position;tSP=TB.Position end end)
UserInputService.InputChanged:Connect(function(inp) if tDrg and(inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then local d=inp.Position-tDS;TB.Position=UDim2.new(tSP.X.Scale,tSP.X.Offset+d.X,tSP.Y.Scale,tSP.Y.Offset+d.Y) end end)
UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then tDrg=false end end)

-- MAIN PANEL landscape 520x270
local Main=Instance.new("Frame",UI)
Main.Name="MainPanel";Main.Size=UDim2.new(0,520,0,270);Main.Position=UDim2.new(0.5,-260,0.5,-135)
Main.BackgroundColor3=C.BG;Main.BorderSizePixel=0;Main.ClipsDescendants=true;mkC(Main,10);mkS(Main,C.STROKE,1.5,0.05)
local mGrad=Instance.new("UIGradient",Main)
mGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(10,6,20)),ColorSequenceKeypoint.new(1,Color3.fromRGB(5,4,12))});mGrad.Rotation=120
-- Purple accent strip top (drag zone for main)
local Strip=Instance.new("Frame",Main)
Strip.Size=UDim2.new(1,0,0,2);Strip.BackgroundColor3=C.ACCENT;Strip.BorderSizePixel=0
local sGrad=Instance.new("UIGradient",Strip)
sGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(90,25,185)),ColorSequenceKeypoint.new(0.5,Color3.fromRGB(205,125,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(90,25,185))})
local dDrg,dS,dP
Strip.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then dDrg=true;dS=inp.Position;dP=Main.Position end end)
UserInputService.InputChanged:Connect(function(inp) if dDrg and(inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then local d=inp.Position-dS;Main.Position=UDim2.new(dP.X.Scale,dP.X.Offset+d.X,dP.Y.Scale,dP.Y.Offset+d.Y) end end)
UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then dDrg=false end end)

-- LEFT PANEL 152px - controls
local LP=Instance.new("Frame",Main)
LP.Size=UDim2.new(0,152,1,-10);LP.Position=UDim2.new(0,5,0,5);LP.BackgroundColor3=C.PANEL;LP.BorderSizePixel=0;mkC(LP,8);mkS(LP,C.STROKE2,1,0.2)
local lpPad=Instance.new("UIPadding",LP);lpPad.PaddingTop=UDim.new(0,8);lpPad.PaddingBottom=UDim.new(0,8);lpPad.PaddingLeft=UDim.new(0,8);lpPad.PaddingRight=UDim.new(0,8)
local lpL=Instance.new("UIListLayout",LP);lpL.Padding=UDim.new(0,6);lpL.SortOrder=Enum.SortOrder.LayoutOrder

local pT=Instance.new("TextLabel",LP);pT.Size=UDim2.new(1,0,0,16);pT.BackgroundTransparency=1;pT.Text="LANGZ v62"
pT.TextColor3=C.ACCENT2;pT.Font=Enum.Font.GothamBold;pT.TextSize=11;pT.TextXAlignment=Enum.TextXAlignment.Left;pT.LayoutOrder=0

-- Search box
local SW=Instance.new("Frame",LP);SW.Size=UDim2.new(1,0,0,26);SW.BackgroundColor3=C.CARD;SW.BorderSizePixel=0;SW.LayoutOrder=1;mkC(SW,5);mkS(SW,C.STROKE2,1,0.3)
local sIco=Instance.new("ImageLabel",SW);sIco.Size=UDim2.new(0,11,0,11);sIco.Position=UDim2.new(0,5,0.5,-5);sIco.BackgroundTransparency=1;sIco.Image=ICONS.SEARCH;sIco.ImageColor3=C.TEXTMUTE
local SearchBox=Instance.new("TextBox",SW);SearchBox.Size=UDim2.new(1,-20,1,0);SearchBox.Position=UDim2.new(0,19,0,0)
SearchBox.BackgroundTransparency=1;SearchBox.Text="";SearchBox.PlaceholderText="Cari file...";SearchBox.PlaceholderColor3=C.TEXTMUTE
SearchBox.TextColor3=C.TEXT;SearchBox.Font=Enum.Font.Gotham;SearchBox.TextSize=9;SearchBox.TextXAlignment=Enum.TextXAlignment.Left;SearchBox.ClearTextOnFocus=false

-- Scan button
local ScanBtn=Instance.new("TextButton",LP);ScanBtn.Size=UDim2.new(1,0,0,28);ScanBtn.BackgroundColor3=C.ACCENT;ScanBtn.BorderSizePixel=0
ScanBtn.Text="SCAN FILES";ScanBtn.TextColor3=Color3.fromRGB(255,255,255);ScanBtn.Font=Enum.Font.GothamBold;ScanBtn.TextSize=10;ScanBtn.LayoutOrder=2;mkC(ScanBtn,5)
local scGrad=Instance.new("UIGradient",ScanBtn);scGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(115,45,215)),ColorSequenceKeypoint.new(1,Color3.fromRGB(75,18,155))});scGrad.Rotation=90

-- Stats
local StatsLbl=Instance.new("TextLabel",LP);StatsLbl.Size=UDim2.new(1,0,0,26);StatsLbl.BackgroundTransparency=1
StatsLbl.Text="Files: 0  |  Loaded: 0";StatsLbl.TextColor3=C.TEXTDIM;StatsLbl.Font=Enum.Font.Gotham;StatsLbl.TextSize=8
StatsLbl.TextWrapped=true;StatsLbl.TextXAlignment=Enum.TextXAlignment.Left;StatsLbl.LayoutOrder=3

-- Progress bar
local PBG=Instance.new("Frame",LP);PBG.Size=UDim2.new(1,0,0,14);PBG.BackgroundColor3=C.CARD;PBG.BorderSizePixel=0;PBG.LayoutOrder=4;mkC(PBG,5);mkS(PBG,C.STROKE2,1,0.4)
local PFill=Instance.new("Frame",PBG);PFill.Size=UDim2.new(0,0,1,0);PFill.BackgroundColor3=C.ACCENT;PFill.BorderSizePixel=0;mkC(PFill,5)
local pfG=Instance.new("UIGradient",PFill);pfG.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(145,65,250)),ColorSequenceKeypoint.new(1,Color3.fromRGB(195,135,255))})
local PLbl=Instance.new("TextLabel",PBG);PLbl.Size=UDim2.new(1,0,1,0);PLbl.BackgroundTransparency=1;PLbl.Text="0%"
PLbl.TextColor3=Color3.fromRGB(255,255,255);PLbl.Font=Enum.Font.GothamBold;PLbl.TextSize=8;PLbl.ZIndex=3

-- Status
local StatusLbl=Instance.new("TextLabel",LP);StatusLbl.Size=UDim2.new(1,0,0,22);StatusLbl.BackgroundTransparency=1
StatusLbl.Text="Status: Ready";StatusLbl.TextColor3=C.TEXTMUTE;StatusLbl.Font=Enum.Font.Gotham;StatusLbl.TextSize=8
StatusLbl.TextWrapped=true;StatusLbl.TextXAlignment=Enum.TextXAlignment.Left;StatusLbl.LayoutOrder=5

-- RIGHT PANEL file list
local RP=Instance.new("Frame",Main);RP.Size=UDim2.new(1,-162,1,-10);RP.Position=UDim2.new(0,160,0,5)
RP.BackgroundColor3=C.PANEL;RP.BorderSizePixel=0;mkC(RP,8);mkS(RP,C.STROKE2,1,0.2)
local RPT=Instance.new("TextLabel",RP);RPT.Size=UDim2.new(1,-10,0,20);RPT.Position=UDim2.new(0,8,0,4)
RPT.BackgroundTransparency=1;RPT.Text="File List";RPT.TextColor3=C.TEXTDIM;RPT.Font=Enum.Font.GothamBold;RPT.TextSize=9;RPT.TextXAlignment=Enum.TextXAlignment.Left
local Scroll=Instance.new("ScrollingFrame",RP);Scroll.Size=UDim2.new(1,-10,1,-28);Scroll.Position=UDim2.new(0,5,0,24)
Scroll.BackgroundTransparency=1;Scroll.ScrollBarThickness=3;Scroll.ScrollBarImageColor3=C.SCROLL;Scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y;Scroll.BorderSizePixel=0
local SLay=Instance.new("UIListLayout",Scroll);SLay.Padding=UDim.new(0,4);SLay.SortOrder=Enum.SortOrder.LayoutOrder
local EmptyLbl=Instance.new("TextLabel",Scroll);EmptyLbl.Size=UDim2.new(1,0,0,60);EmptyLbl.BackgroundTransparency=1
EmptyLbl.Text="Belum ada file.\nTekan SCAN FILES untuk mulai.";EmptyLbl.TextColor3=C.TEXTMUTE;EmptyLbl.Font=Enum.Font.Gotham;EmptyLbl.TextSize=9;EmptyLbl.TextWrapped=true
﻿
-- ===== LOGIC & NOTIFICATION =====
local function notify(title,msg,col)
    col=col or C.ACCENT
    local nf=Instance.new("Frame",UI)
    nf.Size=UDim2.new(0,210,0,44);nf.Position=UDim2.new(1,-218,1,-52)
    nf.BackgroundColor3=C.PANEL;nf.BorderSizePixel=0;nf.ZIndex=200
    mkC(nf,7);mkS(nf,col,1.2,0.05)
    local nb=Instance.new("Frame",nf);nb.Size=UDim2.new(0,3,1,0);nb.BackgroundColor3=col;nb.BorderSizePixel=0;mkC(nb,3)
    local nt=Instance.new("TextLabel",nf)
    nt.Size=UDim2.new(1,-14,0,14);nt.Position=UDim2.new(0,10,0,5);nt.BackgroundTransparency=1
    nt.Text=title;nt.TextColor3=C.TEXT;nt.Font=Enum.Font.GothamBold;nt.TextSize=10;nt.TextXAlignment=Enum.TextXAlignment.Left;nt.ZIndex=201
    local nd=Instance.new("TextLabel",nf)
    nd.Size=UDim2.new(1,-14,0,18);nd.Position=UDim2.new(0,10,0,20);nd.BackgroundTransparency=1
    nd.Text=msg;nd.TextColor3=C.TEXTDIM;nd.Font=Enum.Font.Gotham;nd.TextSize=8;nd.TextXAlignment=Enum.TextXAlignment.Left;nd.TextWrapped=true;nd.ZIndex=201
    task.spawn(function()
        task.wait(2.8)
        for i=1,10 do nf.BackgroundTransparency=i/10;nt.TextTransparency=i/10;nd.TextTransparency=i/10;task.wait(0.02) end
        nf:Destroy()
    end)
end
local function setProgress(pct,st)
    pct=math.clamp(pct,0,1);tw(PFill,TI_M,{Size=UDim2.new(pct,0,1,0)})
    PLbl.Text=math.floor(pct*100).."%"
    if st then StatusLbl.Text="Status: "..st end
end

-- CARD
local allCards={};local totalLoaded=0
local function buildCard(fi)
    EmptyLbl.Visible=false
    local card=Instance.new("Frame",Scroll)
    table.insert(allCards,{info=fi,card=card})
    card.Size=UDim2.new(1,-2,0,42);card.BackgroundColor3=C.CARD;card.BorderSizePixel=0;mkC(card,6);mkS(card,C.STROKE2,1,0.35)
    local isL=fi.ftype=="RBXL"
    local badge=Instance.new("Frame",card);badge.Size=UDim2.new(0,44,0,14);badge.Position=UDim2.new(0,5,0,5);badge.BackgroundColor3=isL and C.BADGEL or C.BADGEM;badge.BorderSizePixel=0;mkC(badge,3)
    local bt=Instance.new("TextLabel",badge);bt.Size=UDim2.new(1,0,1,0);bt.BackgroundTransparency=1;bt.Text=fi.ftype;bt.TextColor3=Color3.fromRGB(255,255,255);bt.Font=Enum.Font.GothamBold;bt.TextSize=8
    local nl=Instance.new("TextLabel",card);nl.Size=UDim2.new(1,-108,0,14);nl.Position=UDim2.new(0,54,0,5);nl.BackgroundTransparency=1;nl.Text=fi.name;nl.TextColor3=C.TEXT;nl.Font=Enum.Font.GothamBold;nl.TextSize=9;nl.TextXAlignment=Enum.TextXAlignment.Left;nl.TextTruncate=Enum.TextTruncate.AtEnd
    local pl=Instance.new("TextLabel",card);pl.Size=UDim2.new(1,-108,0,12);pl.Position=UDim2.new(0,54,0,20);pl.BackgroundTransparency=1;pl.Text=fi.path;pl.TextColor3=C.TEXTMUTE;pl.Font=Enum.Font.Gotham;pl.TextSize=7;pl.TextXAlignment=Enum.TextXAlignment.Left;pl.TextTruncate=Enum.TextTruncate.AtEnd
    local ib=Instance.new("TextButton",card);ib.Size=UDim2.new(0,56,0,20);ib.Position=UDim2.new(1,-62,0.5,-10);ib.BackgroundColor3=Color3.fromRGB(38,16,72);ib.BorderSizePixel=0;ib.Text="INSERT";ib.TextColor3=C.ACCENT2;ib.Font=Enum.Font.GothamBold;ib.TextSize=8;mkC(ib,4);mkS(ib,C.STROKE,1,0.2)
    ib.MouseEnter:Connect(function() tw(ib,TI_F,{BackgroundColor3=C.ACCENT}) end);ib.MouseLeave:Connect(function() tw(ib,TI_F,{BackgroundColor3=Color3.fromRGB(38,16,72)}) end)
    ib.MouseButton1Click:Connect(function()
        if ib.Text=="LOADING..." then return end
        ib.Text="LOADING...";ib.TextColor3=Color3.fromRGB(200,200,200);tw(ib,TI_F,{BackgroundColor3=Color3.fromRGB(52,28,88)})
        setProgress(0,"Membaca "..fi.name)
        task.spawn(function()
            local data=safeRead(fi.path);setProgress(0.15,"Parsing binary...")
            if not data or #data==0 then
                ib.Text="FAIL";ib.TextColor3=C.FAIL;setProgress(0,"Gagal baca file");notify("Gagal","readfile() kosong / error",C.FAIL)
                task.wait(2);ib.Text="INSERT";ib.TextColor3=C.ACCENT2;tw(ib,TI_F,{BackgroundColor3=Color3.fromRGB(38,16,72)});return
            end
            setProgress(0.3,"Extracting sources...");local srcMap={}
            if fi.ftype=="RBXM" then local ok,s=pcall(parseRBXM,data);if ok and s then srcMap=s end end
            setProgress(0.5,"Loading ke StudioLite...");local ok,result,errMsg
            if getcustomasset then
                local ok1,aid=pcall(getcustomasset,fi.path)
                if ok1 and aid then
                    local ok2,objs=pcall(function() return game:GetObjects(aid) end)
                    if ok2 and objs and #objs>0 then setProgress(0.7,"Injecting objects...");ok=true;result=insObjs(objs,fi.ftype=="RBXL",srcMap).." obj loaded" end
                end
            end
            if not ok then
                local ok3,o3=pcall(function() return game:GetObjects("rbxasset://"..fi.path) end)
                if ok3 and o3 and #o3>0 then setProgress(0.7,"Injecting objects...");ok=true;result=insObjs(o3,fi.ftype=="RBXL",srcMap).." obj loaded" else ok=false;errMsg="Semua metode load gagal" end
            end
            setProgress(0.9,"Finalizing...");task.wait(0.3)
            if ok then
                setProgress(1,"Selesai!");ib.Text="DONE";ib.TextColor3=C.SUCCESS;tw(ib,TI_F,{BackgroundColor3=Color3.fromRGB(18,48,26)})
                totalLoaded=totalLoaded+1;StatsLbl.Text=string.format("Files: %d  |  Loaded: %d",#allCards,totalLoaded)
                notify("Berhasil!",fi.name.." -> "..tostring(result),C.SUCCESS);task.wait(2)
            else
                setProgress(0,"Error");ib.Text="FAIL";ib.TextColor3=C.FAIL;tw(ib,TI_F,{BackgroundColor3=Color3.fromRGB(58,13,13)})
                notify("Gagal",tostring(errMsg),C.FAIL);task.wait(2)
            end
            ib.Text="INSERT";ib.TextColor3=C.ACCENT2;tw(ib,TI_F,{BackgroundColor3=Color3.fromRGB(38,16,72)})
        end)
    end)
end

local function filterCards(q)
    q=q:lower();local any=false
    for _,e in ipairs(allCards) do
        local v=q=="" or e.info.name:lower():find(q,1,true) or e.info.path:lower():find(q,1,true)
        e.card.Visible=v;if v then any=true end
    end
    EmptyLbl.Visible=not any and #allCards==0
end
SearchBox:GetPropertyChangedSignal("Text"):Connect(function() filterCards(SearchBox.Text) end)

ScanBtn.MouseButton1Click:Connect(function()
    ScanBtn.Text="Scanning...";for _,e in ipairs(allCards) do e.card:Destroy() end
    allCards={};EmptyLbl.Visible=true;totalLoaded=0;setProgress(0,"Scanning...")
    task.spawn(function()
        local found=scanAll()
        for i,f in ipairs(found) do buildCard(f);setProgress(i/math.max(#found,1)*0.85,"Menemukan "..f.name);task.wait(0.01) end
        setProgress(1,"Scan selesai!");StatsLbl.Text=string.format("Files: %d  |  Loaded: %d",#found,totalLoaded)
        RPT.Text="File List  ("..#found.." file)";ScanBtn.Text="SCAN FILES";filterCards(SearchBox.Text)
        if #found==0 then notify("Tidak Ada File","Tidak ada RBXM/RBXL di workspace",C.ACCENT) else notify("Scan Selesai",#found.." file ditemukan",C.SUCCESS) end
        task.wait(1.5);setProgress(0,"Ready")
    end)
end)
﻿
-- ===== TOGGLE & HOOKS =====
local guiOpen=true
TogBtn.MouseButton1Click:Connect(function()
    guiOpen=not guiOpen
    if guiOpen then
        Main.Visible=true;tw(Main,TI_M,{Size=UDim2.new(0,520,0,270)})
        TogBtn.Text="HIDE";tw(TogBtn,TI_F,{BackgroundColor3=C.ACCENT})
    else
        tw(Main,TI_M,{Size=UDim2.new(0,520,0,0)});task.delay(0.3,function() Main.Visible=false end)
        TogBtn.Text="SHOW";tw(TogBtn,TI_F,{BackgroundColor3=Color3.fromRGB(55,28,95)})
    end
end)

task.spawn(function()
    if hookmetamethod then
        local oldNC
        oldNC=hookmetamethod(game,"__namecall",function(self,...)
            local method=getnamecallmethod();local args={...}
            if not checkcaller() and method=="InvokeServer" then
                if self.Name=="GetScriptSourceServerFunction" then
                    local tgt=tostring(args[1])
                    for obj,src in pairs(_G.LANGZ_RAW_SOURCES) do
                        if typeof(obj)=="Instance" and(obj.ClassName..obj.Name)==tgt and src and src~="" then return src end
                    end
                end
                if self.Name=="SaveScriptSourceServerFunction" then
                    local tgt=tostring(args[1]);local ns=tostring(args[2])
                    for obj in pairs(_G.LANGZ_RAW_SOURCES) do
                        if typeof(obj)=="Instance" and(obj.ClassName..obj.Name)==tgt then _G.LANGZ_RAW_SOURCES[obj]=ns;break end
                    end
                end
            end
            return oldNC(self,...)
        end)
    end
    if hookfunction then
        local oldReq
        oldReq=hookfunction(getrenv().require or require,function(module)
            if typeof(module)=="Instance" and module:IsA("ModuleScript") then
                local src=_G.LANGZ_RAW_SOURCES[module]
                if src and src~="" then local f=loadstring(src);if f then local ok,res=pcall(f);if ok then return res end end end
            end
            return oldReq(module)
        end)
        local oldGO
        oldGO=hookfunction(game.GetObjects,function(self,url,...)
            local aid=tostring(url):match("%d+");if aid then tSL(aid) end
            local objects=oldGO(self,url,...)
            if objects then for _,obj in ipairs(objects) do pcall(injScripts,obj,{});pcall(applySLP,obj);pcall(ldAssets,obj) end end
            return objects
        end)
        local oldLA
        oldLA=hookfunction(InsertService.LoadAsset,function(self,assetId,...)
            tSL(tostring(assetId))
            local obj=oldLA(self,assetId,...)
            if obj then pcall(injScripts,obj,{});pcall(applySLP,obj);pcall(ldAssets,obj) end
            return obj
        end)
    end
end)

print("[LANGZ] IMPORTER v62.0 loaded - Dark Purple Theme")
