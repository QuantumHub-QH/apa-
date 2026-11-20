--[[
============================================================
   ENGINE DESKTOP FOR MOBILE SUPPORT
   UI: Liquid Glass · Green Horror Theme
   Toggle ID : 92844638469747
   Logo ID   : 92844638469747
   RBXM icon : 106962661743892
   RBXL icon : 122982660526589
   Spawn      : 10 studs in front of camera · Auto-Anchored
============================================================
]]--

if not game:IsLoaded() then game.Loaded:Wait() end

-- ══════════════════════════════════════════════
-- SERVICES
-- ══════════════════════════════════════════════
local Players          = game:GetService("Players")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local HttpService      = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local AssetService     = game:GetService("AssetService")
local InsertService    = game:GetService("InsertService")
local LocalPlayer      = Players.LocalPlayer
local PlayerGui        = LocalPlayer:WaitForChild("PlayerGui")
local CoreDest         = PlayerGui
pcall(function()
    local p = Instance.new("Folder")
    p.Name  = "__PROBE"
    p.Parent = game:GetService("CoreGui")
    p:Destroy()
    CoreDest = game:GetService("CoreGui")
end)

-- ══════════════════════════════════════════════
-- BINARY / COMPAT CHECKS
-- ══════════════════════════════════════════════
if type(string.unpack) ~= "function" then
    warn("[ENGINE] string.unpack tidak tersedia. Binary RBXL tidak bisa dibaca.")
end
local BINARY_BIT32_OK = type(bit32) == "table"
if not BINARY_BIT32_OK then
    warn("[ENGINE] bit32 tidak tersedia. Import binary mungkin gagal.")
end
local _rrotate = BINARY_BIT32_OK and bit32.rrotate or nil
if type(_rrotate) ~= "function" then
    _rrotate = function(x,n)
        x = x%4294967296; n = n%32
        if n==0 then return x end
        local p = 2^n
        return (math.floor(x/p)+(x%p)*(2^(32-n)))%4294967296
    end
end

-- ══════════════════════════════════════════════
-- BUFFER / STREAM
-- ══════════════════════════════════════════════
local function Buffer(str, allowOverflows)
    local S = {Offset=0,Source=str,Length=#str,AllowOverflows=(allowOverflows==nil and true) or allowOverflows}
    function S:read(len,shift) len=len or 1;shift=(shift==nil and true) or shift;local d=string.sub(self.Source,self.Offset+1,self.Offset+len);if shift then self:seek(len) end;return d end
    function S:seek(len) self.Offset=math.clamp(self.Offset+len,0,self.Length) end
    function S:readNumber(fmt,shift)
        fmt=fmt or "I1"
        if type(string.unpack)~="function" then error("string.unpack unavailable") end
        local size
        if type(string.packsize)=="function" then size=string.packsize(fmt)
        else local f=tostring(fmt):gsub("^[<>!=@]","");local sz={I1=1,i1=1,I2=2,i2=2,I4=4,i4=4,I8=8,i8=8,f=4,d=8};size=sz[f] or error("bad fmt:"..fmt) end
        local chunk=self:read(size,shift)
        if #chunk~=size then error(("EOF reading %s"):format(fmt)) end
        return string.unpack(fmt,chunk)
    end
    function S:append(s) self.Source=self.Source..s;self.Length=#self.Source end
    function S:toEnd() self.Offset=self.Length end
    return S
end

local function transformInt(x) return (x%2==0) and (x/2) or (-(x+1)/2) end
local function rbxF32(x) x=_rrotate(x,1);return string.unpack(">f",string.pack(">I4",x)) end

local bt={}
function bt.String(b) return b:read(b:readNumber("<I4")) end
function bt.Int32(b) return transformInt(b:readNumber(">I4")) end
function bt.Int64(b) return transformInt(b:readNumber(">I8")) end
function bt.Float32(b) return rbxF32(b:readNumber(">I4")) end
function bt.Float64(b) return b:readNumber("<d") end
function bt.InterleaveArrayWithSize(b,count,sizeof)
    if count<0 then return Buffer("",false) end
    local stream=b:read(count*sizeof);local out=table.create(count)
    for i=1,count do
        local chunk=table.create(sizeof)
        for s=0,sizeof-1 do local bp=i+(count*s);chunk[s+1]=string.sub(stream,bp,bp) end
        out[i]=table.concat(chunk)
    end
    return Buffer(table.concat(out),false)
end
function bt.unsignedIntArray(b,count)
    if count<1 then return {} end
    local o=table.create(count);local s=bt.InterleaveArrayWithSize(b,count,4)
    for i=1,count do o[i]=s:readNumber("<I4") end;return o
end
function bt.Int32Array(b,count)
    if count<1 then return {} end
    local o=table.create(count);local s=bt.InterleaveArrayWithSize(b,count,4)
    for i=1,count do o[i]=bt.Int32(s) end;return o
end
function bt.Int64Array(b,count)
    if count<1 then return {} end
    local o=table.create(count);local s=bt.InterleaveArrayWithSize(b,count,8)
    for i=1,count do o[i]=bt.Int64(s) end;return o
end
function bt.RbxF32Array(b,count)
    if count<1 then return {} end
    local o=table.create(count);local s=bt.InterleaveArrayWithSize(b,count,4)
    for i=1,count do o[i]=bt.Float32(s) end;return o
end
function bt.RefArray(b,count)
    if count<1 then return {} end
    local o=table.create(count);local refs=bt.Int32Array(b,count);local last=0
    for i=1,count do local r=last+refs[i];o[i]=r;last=r end;return o
end

-- ══════════════════════════════════════════════
-- LZ4
-- ══════════════════════════════════════════════
local function lz4(data)
    local input=Buffer(data,false)
    local cLen=input:readNumber("<I4");local dLen=input:readNumber("<I4");local rsv=input:readNumber("<I4")
    if rsv~=0 then error("not lz4") end
    if cLen==0 then return input:read(dLen) end
    local raw=input:read(cLen);local pos=1;local out=table.create(dLen);local outLen=0
    local function rb() if pos>#raw then error("LZ4 EOF") end;local b=string.byte(raw,pos);pos=pos+1;return b end
    local function el(base) local len=base;if base==15 then while true do local b=rb();len=len+b;if b~=255 then break end end end;return len end
    while outLen<dLen do
        local token=rb();local lLen=el(bit32.rshift(token,4))
        for _=1,lLen do outLen=outLen+1;out[outLen]=string.char(rb()) end
        if outLen>=dLen then break end
        local offset=rb()+bit32.lshift(rb(),8)
        if offset<=0 or offset>outLen then error("LZ4 bad offset") end
        local mLen=el(bit32.band(token,15))+4;local src=outLen-offset+1
        for _=1,mLen do outLen=outLen+1;out[outLen]=out[src];src=src+1;if outLen>=dLen then break end end
    end
    local result=table.concat(out,"",1,outLen)
    if #result~=dLen then error(("LZ4 mismatch %d/%d"):format(#result,dLen)) end
    return result
end

-- ══════════════════════════════════════════════
-- B64 / ZSTD
-- ══════════════════════════════════════════════
local function b64encode(str)
    local chars="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local out={}
    for i=1,#str,3 do
        local b0,b1,b2=string.byte(str,i,i+2)
        local b=bit32.lshift(b0,16)+bit32.lshift(b1 or 0,8)+(b2 or 0)
        table.insert(out,chars:sub(bit32.extract(b,18,6)+1,bit32.extract(b,18,6)+1))
        table.insert(out,chars:sub(bit32.extract(b,12,6)+1,bit32.extract(b,12,6)+1))
        table.insert(out,b1 and chars:sub(bit32.extract(b,6,6)+1,bit32.extract(b,6,6)+1) or "=")
        table.insert(out,b2 and chars:sub(bit32.band(b,63)+1,bit32.band(b,63)+1) or "=")
    end
    return table.concat(out)
end
local function _bytesToString(v)
    if type(v)=="string" then return v end
    local ok,out=pcall(function() if type(buffer)=="table" and type(buffer.tostring)=="function" then return buffer.tostring(v) end;return nil end)
    if ok and type(out)=="string" then return out end
    local ok2,out2=pcall(function()
        if type(buffer)=="table" and type(buffer.len)=="function" and type(buffer.readu8)=="function" then
            local n=buffer.len(v);local parts=table.create(math.ceil(n/4096));local k=0
            for i=0,n-1,4096 do local e=math.min(n-1,i+4095);local chars=table.create(e-i+1);for j=i,e do chars[j-i+1]=string.char(buffer.readu8(v,j)) end;k=k+1;parts[k]=table.concat(chars) end
            return table.concat(parts)
        end;return nil
    end)
    if ok2 and type(out2)=="string" then return out2 end
    return nil
end
local function zstd(stream)
    local ok,r=pcall(function()
        local ES=game:GetService("EncodingService")
        local CA=Enum.CompressionAlgorithm
        if type(buffer)~="table" or type(buffer.fromstring)~="function" then error("buffer unavail") end
        if not CA or not CA.Zstd then error("Zstd enum unavail") end
        local c=buffer.fromstring(stream);local d=ES:DecompressBuffer(c,CA.Zstd);local t=_bytesToString(d)
        if not t then error("buf->str fail") end;return t
    end)
    if ok then return r end
    local zb=b64encode(stream)
    local ok2,r2=pcall(function()
        local x=HttpService:JSONDecode('{"m":null,"t":"buffer","zbase64":"'..zb..'"}')
        local t=_bytesToString(x);if not t then error("bridge fail") end;return t
    end)
    if ok2 then return r2 end
    error("ZSTD unavailable in this environment")
end

-- ══════════════════════════════════════════════
-- VECTOR / CFRAME HELPERS
-- ══════════════════════════════════════════════
local function _readV3(b,count)
    local xs=bt.RbxF32Array(b,count);local ys=bt.RbxF32Array(b,count);local zs=bt.RbxF32Array(b,count)
    local out=table.create(count);for i=1,count do out[i]=Vector3.new(xs[i],ys[i],zs[i]) end;return out
end
local function _readColor3(b,count)
    local rs=bt.RbxF32Array(b,count);local gs=bt.RbxF32Array(b,count);local bs=bt.RbxF32Array(b,count)
    local out=table.create(count);for i=1,count do out[i]=Color3.new(rs[i],gs[i],bs[i]) end;return out
end
local ROT_MATS={[0x02]={1,0,0,0,1,0,0,0,1},[0x03]={1,0,0,0,0,-1,0,1,0},[0x05]={1,0,0,0,-1,0,0,0,-1},[0x06]={1,0,0,0,0,1,0,-1,0},[0x07]={0,1,0,1,0,0,0,0,-1},[0x09]={0,0,1,1,0,0,0,1,0},[0x0A]={0,-1,0,1,0,0,0,0,1},[0x0C]={0,0,-1,1,0,0,0,-1,0},[0x0D]={0,1,0,0,0,1,1,0,0},[0x0E]={0,0,-1,0,1,0,1,0,0},[0x10]={0,-1,0,0,0,-1,1,0,0},[0x11]={0,0,1,0,-1,0,1,0,0},[0x14]={-1,0,0,0,1,0,0,0,-1},[0x15]={-1,0,0,0,0,1,0,1,0},[0x17]={-1,0,0,0,-1,0,0,0,1},[0x18]={-1,0,0,0,0,-1,0,-1,0},[0x19]={0,1,0,-1,0,0,0,0,1},[0x1B]={0,0,-1,-1,0,0,0,1,0},[0x1C]={0,-1,0,-1,0,0,0,0,-1},[0x1E]={0,0,1,-1,0,0,0,-1,0},[0x1F]={0,1,0,0,0,-1,-1,0,0},[0x20]={0,0,1,0,1,0,-1,0,0},[0x22]={0,-1,0,0,0,1,-1,0,0},[0x23]={0,0,-1,0,-1,0,-1,0,0}}
local function _readCFrames(b,count)
    local ids=table.create(count);local rots=table.create(count)
    for i=1,count do
        local id=string.byte(b:read());ids[i]=id
        if id==0 then local m=table.create(9);for j=1,9 do m[j]=b:readNumber("<f") end;rots[i]=m
        elseif not ROT_MATS[id] then error(("bad CF id:0x%02X"):format(id)) end
    end
    local positions=_readV3(b,count);local out=table.create(count)
    for i=1,count do
        local p=positions[i]
        if ids[i]==0 then local m=rots[i];out[i]=CFrame.new(p.X,p.Y,p.Z,m[1],m[2],m[3],m[4],m[5],m[6],m[7],m[8],m[9])
        else local m=ROT_MATS[ids[i]];out[i]=CFrame.new(p.X,p.Y,p.Z,m[1],m[2],m[3],m[4],m[5],m[6],m[7],m[8],m[9]) end
    end
    return out
end

local function _enumItemByValue(enumType,v)
    for _,item in ipairs(enumType:GetEnumItems()) do if item.Value==v then return item end end
    return nil
end

-- ══════════════════════════════════════════════
-- PROPERTY DECODER
-- ══════════════════════════════════════════════
local function _decodePropertyArray(b,typeID,count,shared)
    if typeID==0x01 then local a=table.create(count);for i=1,count do a[i]=bt.String(b) end;return a
    elseif typeID==0x02 then local a=table.create(count);for i=1,count do a[i]=(string.byte(b:read())~=0) end;return a
    elseif typeID==0x03 then return bt.Int32Array(b,count)
    elseif typeID==0x04 then return bt.RbxF32Array(b,count)
    elseif typeID==0x05 then return bt.Int64Array(b,count)
    elseif typeID==0x06 then local a=table.create(count);for i=1,count do a[i]=bt.Float64(b) end;return a
    elseif typeID==0x07 then local a=table.create(count);for i=1,count do a[i]=UDim.new(bt.Float32(b),bt.Int32(b)) end;return a
    elseif typeID==0x08 then
        local xs=bt.RbxF32Array(b,count);local ys=bt.RbxF32Array(b,count)
        local aw=bt.Int32Array(b,count);local ao=bt.Int32Array(b,count)
        local bw=bt.Int32Array(b,count);local bo2=bt.Int32Array(b,count)
        local a=table.create(count)
        for i=1,count do a[i]=UDim2.new(xs[i],aw[i],ys[i],ao[i]) end;return a
    elseif typeID==0x09 then
        local mi=bt.RbxF32Array(b,count);local ma=bt.RbxF32Array(b,count)
        local a=table.create(count);for i=1,count do a[i]=Ray.new(Vector3.new(),Vector3.new()) end;return a
    elseif typeID==0x0B then local a=table.create(count);for i=1,count do a[i]=bt.Float32(b) end;return a
    elseif typeID==0x0D then return _readColor3(b,count)
    elseif typeID==0x0E then
        local a=table.create(count)
        for i=1,count do
            local n=b:readNumber("<I4");local kps=table.create(n)
            for j=1,n do local t=bt.Float32(b);local r=bt.Float32(b);local g=bt.Float32(b);local bv=bt.Float32(b);kps[j]=ColorSequenceKeypoint.new(t,Color3.new(r,g,bv)) end
            a[i]=ColorSequence.new(kps)
        end;return a
    elseif typeID==0x0F then
        local a=table.create(count)
        for i=1,count do
            local n=b:readNumber("<I4");local kps=table.create(n)
            for j=1,n do local t=bt.Float32(b);local v=bt.Float32(b);local ei=bt.Float32(b);local eo=bt.Float32(b);kps[j]=NumberSequenceKeypoint.new(t,v,ei) end
            a[i]=NumberSequence.new(kps)
        end;return a
    elseif typeID==0x10 then return _readCFrames(b,count)
    elseif typeID==0x12 then return bt.Int32Array(b,count)
    elseif typeID==0x13 then return bt.Int32Array(b,count)
    elseif typeID==0x14 then
        local a=table.create(count);for i=1,count do a[i]="rbxassetid://"..tostring(math.max(0,bt.Int64(b))) end;return a
    elseif typeID==0x15 then
        local a=table.create(count)
        local xs=bt.RbxF32Array(b,count);local ys=bt.RbxF32Array(b,count)
        for i=1,count do a[i]=Vector2.new(xs[i],ys[i]) end;return a
    elseif typeID==0x16 then
        local a=table.create(count)
        local xs=bt.RbxF32Array(b,count);local ys=bt.RbxF32Array(b,count);local zs=bt.RbxF32Array(b,count)
        for i=1,count do a[i]=Vector3.new(xs[i],ys[i],zs[i]) end;return a
    elseif typeID==0x17 then local a=table.create(count);for i=1,count do a[i]=CFrame.new() end;return a
    elseif typeID==0x19 then
        local rs=table.create(count);local gs=table.create(count);local bs=table.create(count)
        for i=1,count do rs[i]=string.byte(b:read()) end
        for i=1,count do gs[i]=string.byte(b:read()) end
        for i=1,count do bs[i]=string.byte(b:read()) end
        local a=table.create(count);for i=1,count do a[i]=Color3.fromRGB(rs[i],gs[i],bs[i]) end;return a
    elseif typeID==0x1B then return bt.Int64Array(b,count)
    elseif typeID==0x1C then
        local idx=bt.unsignedIntArray(b,count);local a=table.create(count)
        for i=1,count do a[i]=shared and shared[idx[i]+1] or nil end;return a
    end
    return nil
end

-- ══════════════════════════════════════════════
-- BINARY RBXL PARSER
-- ══════════════════════════════════════════════
local function parseRBXLBinary(data)
    local r=Buffer(data,false)
    if r:read(14)~="<roblox!"..string.char(137,255,13,10,26,10) then return nil,"invalid header" end
    local ver=r:readNumber("<I2");if ver~=0 then return nil,"unsupported version:"..ver end
    local classCount=r:readNumber("<I4");local instCount=r:readNumber("<I4");r:read(8)
    local chunks={META={},SSTR={},INST={},PROP={},PRNT={},SIGN={},["END\0"]={}}
    while r.Offset<r.Length do
        if r.Length-r.Offset<16 then return nil,"chunk header truncated" end
        local sig=r:read(4);local compressed=r:readNumber("<I4");local decompressed=r:readNumber("<I4");r:read(4)
        if sig=="END\0" then local payload=r:read(decompressed);chunks[sig][#chunks[sig]+1]={Data=payload};break end
        local payload
        if compressed==0 then
            payload=r:read(decompressed)
        else
            local raw=r:read(compressed);local magic=string.sub(raw,1,4)
            if magic==string.char(40,181,47,253) then payload=zstd(raw)
            else
                if type(string.pack)~="function" then return nil,"string.pack unavailable" end
                payload=lz4(string.pack("<I4I4I4",compressed,decompressed,0)..raw)
            end
        end
        if chunks[sig] then chunks[sig][#chunks[sig]+1]={Data=payload}
        else return nil,"unknown chunk:"..sig end
    end
    local shared={}
    for _,ch in ipairs(chunks.SSTR) do
        local b=Buffer(ch.Data,false);local ver2=b:readNumber("<I4");if ver2~=0 then return nil,"SSTR ver" end
        local n=b:readNumber("<I4");for i=1,n do b:read(16);shared[i]=bt.String(b) end
    end
    local classes={};local nodes={};local serviceRefs={}
    for _,ch in ipairs(chunks.INST) do
        local b=Buffer(ch.Data,false);local cid=b:readNumber("<I4");local cname=bt.String(b);local format=string.byte(b:read());local n=b:readNumber("<I4");local refs=bt.RefArray(b,n)
        classes[cid]={Name=cname,Count=n,Refs=refs,IsService=(format==1)};local marks={}
        if format==1 then for i=1,n do marks[i]=string.byte(b:read())~=0 end end
        for i,ref in ipairs(refs) do nodes[ref]={Ref=ref,ClassId=cid,ClassName=cname,IsService=(format==1),Properties={},PropertyTypes={},Children={},Service=marks[i] or false} end
        if format==1 then for _,ref in ipairs(refs) do serviceRefs[ref]=true end end
    end
    for _,ch in ipairs(chunks.PROP) do
        local b=Buffer(ch.Data,false);local cid=b:readNumber("<I4");local cls=classes[cid];if not cls then return nil,"PROP class not found:"..cid end
        local pname=bt.String(b);local typeID=string.byte(b:read())
        local vals=_decodePropertyArray(b,typeID,cls.Count,shared)
        if vals then for i,ref in ipairs(cls.Refs) do if nodes[ref] then nodes[ref].Properties[pname]=vals[i];nodes[ref].PropertyTypes[pname]=typeID end end
        else warn(("[ENGINE] skip prop %s type 0x%02X"):format(pname,typeID or 0)) end
    end
    local ctp={}
    for _,ch in ipairs(chunks.PRNT) do local b=Buffer(ch.Data,false);string.byte(b:read());local n=b:readNumber("<I4");local ch2=bt.RefArray(b,n);local pa=bt.RefArray(b,n);for i=1,n do ctp[ch2[i]]=pa[i] end end
    local roots={}
    for ref,node in pairs(nodes) do local p=ctp[ref];if p and p~=-1 and nodes[p] then table.insert(nodes[p].Children,node) else table.insert(roots,node) end end
    return {Header={ClassCount=classCount,InstanceCount=instCount},Nodes=nodes,Roots=roots,Services=serviceRefs,SharedStrings=shared},nil
end

-- ══════════════════════════════════════════════
-- XML PARSER (RBXLX / RBXMX)
-- ══════════════════════════════════════════════
local function parseRobloxXML(data)
    local sample=data:sub(1,4096):gsub("^\239\187\191","")
    if not sample:find("<roblox",1,true) then return nil,"not roblox XML" end
    local nodes={};local nextRef=1
    local function newNode(cname)
        local n={ClassName=cname,Ref=nextRef,Properties={},PropertyTypes={},Children={}}
        nodes[nextRef]=n;nextRef=nextRef+1;return n
    end
    local roots={}
    local function parseItem(xml,parentNode)
        for cls,inner in xml:gmatch('<Item%s+class="([^"]+)"[^>]*>(.-)</Item>') do
            local node=newNode(cls)
            for ptype,pname,pval in inner:gmatch('<(%a[%w_]*)%s+name="([^"]+)"%s*>(.-)</%1>') do
                local v=pval:gsub("^%s+",""):gsub("%s+$","")
                if ptype=="string" or ptype=="ProtectedString" then node.Properties[pname]=v
                elseif ptype=="bool" then node.Properties[pname]=(v=="true")
                elseif ptype=="int" or ptype=="int64" then node.Properties[pname]=tonumber(v) or 0
                elseif ptype=="float" or ptype=="double" then node.Properties[pname]=tonumber(v) or 0
                elseif ptype=="CoordinateFrame" or ptype=="CFrame" then
                    local nums={}; for n2 in v:gmatch("[-%d%.e]+") do table.insert(nums,tonumber(n2) or 0) end
                    if #nums>=12 then node.Properties[pname]=CFrame.new(nums[1],nums[2],nums[3],nums[4],nums[5],nums[6],nums[7],nums[8],nums[9],nums[10],nums[11],nums[12]) end
                elseif ptype=="Vector3" then
                    local nums={}; for n2 in v:gmatch("[-%d%.e]+") do table.insert(nums,tonumber(n2) or 0) end
                    if #nums>=3 then node.Properties[pname]=Vector3.new(nums[1],nums[2],nums[3]) end
                elseif ptype=="Color3" or ptype=="Color3uint8" then
                    local nums={}; for n2 in v:gmatch("[-%d%.e]+") do table.insert(nums,tonumber(n2) or 0) end
                    if #nums>=3 then
                        if ptype=="Color3uint8" then node.Properties[pname]=Color3.fromRGB(nums[1],nums[2],nums[3])
                        else node.Properties[pname]=Color3.new(nums[1],nums[2],nums[3]) end
                    end
                elseif ptype=="Content" then
                    local url=v:match("<url>(.-)</url>") or v
                    node.Properties[pname]=url
                end
            end
            if parentNode then table.insert(parentNode.Children,node) else table.insert(roots,node) end
            parseItem(inner,node)
        end
    end
    parseItem(data,nil)
    local svcNames={Workspace=true,ReplicatedStorage=true,ReplicatedFirst=true,Lighting=true,Players=true,StarterGui=true,StarterPack=true,StarterPlayer=true,StarterPlayerScripts=true,StarterCharacterScripts=true,ServerScriptService=true,ServerStorage=true,Teams=true,SoundService=true,MaterialService=true,TextChatService=true,Chat=true,LocalizationService=true,TestService=true,HttpService=true,InsertService=true,TweenService=true}
    for _,root in ipairs(roots) do
        local rn=tostring(root.Properties.Name or "")
        if svcNames[root.ClassName] or svcNames[rn] then root.Service=true;root.IsService=true end
    end
    return {Header={ClassCount=0,InstanceCount=nextRef-1,Format="XML"},Nodes=nodes,Roots=roots,Services={},SharedStrings={}},nil
end

-- ══════════════════════════════════════════════
-- DETECT FORMAT
-- ══════════════════════════════════════════════
local function detectFormat(data)
    if type(data)~="string" or #data==0 then return nil end
    if data:sub(1,14)=="<roblox!"..string.char(137,255,13,10,26,10) then return "BINARY" end
    local s=data:sub(1,4096):gsub("^\239\187\191","")
    if s:find("<roblox",1,true) then return "XML" end
    return nil
end

-- ══════════════════════════════════════════════
-- GLOBALS
-- ══════════════════════════════════════════════
_G.Langz_RAW_SOURCES       = _G.Langz_RAW_SOURCES or {}
_G.Langz_RAW_SOURCE_BY_REF = _G.Langz_RAW_SOURCE_BY_REF or {}

-- ══════════════════════════════════════════════
-- STUDIO LITE INTEGRATION
-- ══════════════════════════════════════════════
local SL_CACHE={}
local function getStudioLiteFuncs()
    local f=ReplicatedStorage:FindFirstChild("StudioLiteFolder")
    return f and f:FindFirstChild("ServerFunctions")
end
local function triggerServerLoad(idStr)
    local sf=getStudioLiteFuncs();if not sf or not idStr or idStr=="" then return end
    local id=tostring(idStr):match("%d+");if id then pcall(function() sf:InvokeServer("LoadMeshToRuntimeMeshes",tonumber(id)) end) end
end
local FAST_IMPORT=true;local ASSET_WORKERS=6;local ASSET_QUEUE={};local ASSET_SEEN={}
local function queueServerLoad(value)
    if value==nil or value=="" then return end
    local id;if type(value)=="number" then id=math.floor(value) else id=tonumber(tostring(value):match("%d+")) end
    if not id or id<=0 or ASSET_SEEN[id] then return end;ASSET_SEEN[id]=true;ASSET_QUEUE[#ASSET_QUEUE+1]=id
end
local function flushServerLoadsAsync()
    if #ASSET_QUEUE==0 then return end;local jobs=ASSET_QUEUE;ASSET_QUEUE={};ASSET_SEEN={};local cursor=0
    for _=1,math.min(ASSET_WORKERS,#jobs) do task.spawn(function() while true do cursor=cursor+1;local id=jobs[cursor];if not id then break end;triggerServerLoad(id);task.wait() end end) end
end
local function injectStudioLiteUI(scr,sourceMap)
    if not scr:IsA("LuaSourceContainer") then return end
    local path=scr.ClassName..":"..scr.Name
    local realSource=_G.Langz_RAW_SOURCES[scr] or (sourceMap and sourceMap[path])
    if not realSource then pcall(function() realSource=scr.Source end) end
    if realSource and #realSource>0 then realSource=realSource:gsub(string.char(0).."*$","") else realSource="" end
    _G.Langz_RAW_SOURCES[scr]=realSource
    local existing=scr:FindFirstChild("SL_CodeTextBox")
    if existing then existing.Text=realSource;return end
    local sf=getStudioLiteFuncs();if not sf then return end
    local map={Script="InsertScriptScript",LocalScript="InsertLocalScriptLocalScript",ModuleScript="InsertModuleScriptModuleScript"}
    local an=map[scr.ClassName];if not an then return end
    if not SL_CACHE[an] then
        pcall(function()
            sf:InvokeServer("LoadAssetToPlayerGui",an)
            local gf=LocalPlayer:WaitForChild("PlayerGui"):WaitForChild(an,3)
            if gf then SL_CACHE[an]={};for _,c in ipairs(gf:GetChildren()) do table.insert(SL_CACHE[an],c:Clone()) end;sf:InvokeServer("ClearAssetFromPlayerGui",an) end
        end)
    end
    if not SL_CACHE[an] then return end
    pcall(function() for _,c in ipairs(SL_CACHE[an]) do c:Clone().Parent=scr end;local tb=scr:FindFirstChild("SL_CodeTextBox");if tb then tb.Text=realSource end end)
end

-- ══════════════════════════════════════════════
-- SAFE READ FILE
-- ══════════════════════════════════════════════
local function safeReadFile(path)
    if type(readfile)=="function" then
        local ok,data=pcall(readfile,path)
        if ok and type(data)=="string" and #data>0 then return data,nil end
        return nil,tostring(data)
    end
    return nil,"readfile API not available"
end
local function safeListFiles(path)
    if type(listfiles)~="function" then return nil end
    local ok,r=pcall(listfiles,path)
    return ok and r or nil
end

-- ══════════════════════════════════════════════
-- SPAWN IN FRONT OF CAMERA (10 studs)
-- ══════════════════════════════════════════════
local function spawnInFrontOfCamera(obj)
    local cam=workspace.CurrentCamera
    if not cam then return end
    local cf=cam.CFrame
    local spawnCF=cf*CFrame.new(0,0,-10)
    -- anchor all baseparts first, then move
    local function anchorAll(root)
        for _,v in ipairs(root:GetDescendants()) do
            if v:IsA("BasePart") then
                pcall(function()
                    v:SetAttribute("LANGZ_FileAnchored",v.Anchored)
                    v:SetAttribute("LANGZ_AutoAnchored",true)
                    v.Anchored=true
                end)
            end
        end
        if obj:IsA("BasePart") then
            pcall(function()
                obj:SetAttribute("LANGZ_FileAnchored",obj.Anchored)
                obj:SetAttribute("LANGZ_AutoAnchored",true)
                obj.Anchored=true
            end)
        end
    end
    anchorAll(obj)
    -- compute bounding to pivot correctly
    local function getBoundingCenter(root)
        local minP=Vector3.new(math.huge,math.huge,math.huge)
        local maxP=Vector3.new(-math.huge,-math.huge,-math.huge)
        local found=false
        local parts={}
        if root:IsA("BasePart") then table.insert(parts,root) end
        for _,v in ipairs(root:GetDescendants()) do if v:IsA("BasePart") then table.insert(parts,v) end end
        for _,p in ipairs(parts) do
            found=true
            local sz=p.Size/2
            local pos=p.Position
            minP=Vector3.new(math.min(minP.X,pos.X-sz.X),math.min(minP.Y,pos.Y-sz.Y),math.min(minP.Z,pos.Z-sz.Z))
            maxP=Vector3.new(math.max(maxP.X,pos.X+sz.X),math.max(maxP.Y,pos.Y+sz.Y),math.max(maxP.Z,pos.Z+sz.Z))
        end
        if not found then return Vector3.new(0,0,0),Vector3.new(0,0,0) end
        return (minP+maxP)/2,maxP-minP
    end
    local center,size=getBoundingCenter(obj)
    local offsetY=size.Y/2
    local targetPos=spawnCF.Position+Vector3.new(0,offsetY,0)
    local delta=targetPos-center
    local function moveAll(root)
        if root:IsA("BasePart") then pcall(function() root.CFrame=root.CFrame+delta end) end
        for _,v in ipairs(root:GetDescendants()) do
            if v:IsA("BasePart") then pcall(function() v.CFrame=v.CFrame+delta end) end
        end
    end
    if obj:IsA("Model") and obj.PrimaryPart then
        pcall(function() obj:SetPrimaryPartCFrame(obj.PrimaryPart.CFrame+delta) end)
    else
        moveAll(obj)
    end
end

-- ══════════════════════════════════════════════
-- APPLY PROPERTIES
-- ══════════════════════════════════════════════
local READONLY_PROPS={MeshId=true,MeshID=true,MeshContent=true,MeshSize=true,InitialSize=true,PhysicsData=true,PhysicalConfigData=true,EditableMeshString=true,AssetId=true,ChildData=true,ChildData2=true,MeshData=true,MeshData2=true}
local PROP_ALIAS={size="Size",shape="Shape",Color3uint8="Color",MaterialVariantSerialized="MaterialVariant"}
local function runtimePropName(n) return PROP_ALIAS[n] or n end
local function setEnumFromValue(obj,propName,rawValue)
    local ok,cur=pcall(function() return obj[propName] end)
    if not ok or typeof(cur)~="EnumItem" then return false end
    local ok2,eType=pcall(function() return cur.EnumType end)
    if not ok2 or not eType then return false end
    for _,item in ipairs(eType:GetEnumItems()) do if item.Value==rawValue then return pcall(function() obj[propName]=item end) end end
    return false
end
local function applyDecodedProperty(obj,propName,value,typeID)
    if value==nil then return true end
    if propName=="Source" or propName=="ContentText" then
        if obj:IsA("LuaSourceContainer") and type(value)=="string" then
            local clean=value:gsub(string.char(0).."*$","")
            _G.Langz_RAW_SOURCES[obj]=clean
            local refKey=obj:GetAttribute("LANGZ_Ref")
            if refKey~=nil then _G.Langz_RAW_SOURCE_BY_REF[tostring(refKey)]=clean end
        end;return true
    end
    if typeID==0x13 then return true end
    if READONLY_PROPS[propName] then return true end
    local rn=runtimePropName(propName)
    if rn=="MaterialVariant" and value=="" then return true end
    if typeID==0x12 and type(value)=="number" then if setEnumFromValue(obj,rn,value) then return true end end
    return pcall(function() obj[rn]=value end)
end

-- ══════════════════════════════════════════════
-- ASSET ID RESOLVER
-- ══════════════════════════════════════════════
local function assetIdFromValue(v)
    if v==nil then return nil end
    if type(v)=="number" then if v>0 then return math.floor(v) end;return nil end
    if type(v)=="string" then
        local id=v:match("rbxassetid://(%d+)") or v:match("[?&]id=(%d+)") or v:match("(%d+)")
        return id and tonumber(id) or nil
    end
    local ok,uri=pcall(function() if typeof(v)=="Content" and v.Uri then return v.Uri end;return tostring(v) end)
    if ok and uri then local id=uri:match("rbxassetid://(%d+)") or uri:match("(%d+)");return id and tonumber(id) or nil end
    return nil
end

-- ══════════════════════════════════════════════
-- MESH HELPERS
-- ══════════════════════════════════════════════
local function applyBaseVisualState(part,p)
    pcall(function()
        if p.Color then part.Color=p.Color elseif p.Color3uint8 then part.Color=p.Color3uint8 end
        if p.Material then pcall(function() part.Material=p.Material end) end
        if p.Transparency then part.Transparency=math.clamp(tonumber(p.Transparency) or 0,0,1) end
        if p.Size and typeof(p.Size)=="Vector3" then pcall(function() part.Size=p.Size end) end
        if p.CFrame and typeof(p.CFrame)=="CFrame" then pcall(function() part.CFrame=p.CFrame end) end
    end)
end
local function configureSpecialMeshScale(mesh,p)
    local sf=p.InitialSize or p.Size;if typeof(sf)~="Vector3" then sf=Vector3.new(1,1,1) end
    local ofs=p.MeshOffset or Vector3.new(0,0,0)
    pcall(function() mesh.Scale=sf;mesh.Offset=ofs end)
end
local function tryAssetServiceMesh(meshId)
    if not meshId then return nil end
    local ok,obj=pcall(function()
        local m=AssetService:CreateEditableMeshAsync(Content.fromAssetId and Content.fromAssetId(meshId) or ("rbxassetid://"..meshId))
        if m then local p=Instance.new("MeshPart");p.MeshId="rbxassetid://"..meshId;return p end
    end)
    if ok and obj then return obj end
    local ok2,obj2=pcall(function() local objs=game:GetObjects("rbxassetid://"..meshId);return objs and objs[1] end)
    if ok2 and obj2 and obj2:IsA("BasePart") then return obj2 end
    return nil
end
local function makeSpecialMeshFallback(node,meshId)
    local p=node.Properties or {};local part=Instance.new("Part");part.Name=tostring(p.Name or node.ClassName);part.CanCollide=false
    applyBaseVisualState(part,p)
    local mesh=Instance.new("SpecialMesh");mesh.Name="__LANGZ_MeshVisual";mesh.MeshType=Enum.MeshType.FileMesh
    if meshId then mesh.MeshId="rbxassetid://"..tostring(meshId) end
    local texId=assetIdFromValue(p.TextureID or p.TextureId or p.TextureContent)
    if texId then pcall(function() mesh.TextureId="rbxassetid://"..tostring(texId) end) end
    configureSpecialMeshScale(mesh,p);mesh.Parent=part;return part
end
local function isMeshPartOnlyChildClass(c) return c=="SurfaceAppearance" or c=="WrapLayer" or c=="WrapTarget" end
local function tryCreateMeshPartNode(node)
    local p=node.Properties or {};local meshId=assetIdFromValue(p.MeshId or p.MeshID or p.MeshContent)
    if not meshId then return nil,"unresolved","MeshId missing" end
    queueServerLoad(meshId);queueServerLoad(p.TextureID or p.TextureId or p.TextureContent)
    if FAST_IMPORT then return makeSpecialMeshFallback(node,meshId),"fallback","TurboSpecialMesh" end
    local native=tryAssetServiceMesh(meshId);if native then return native,"native","AssetService" end
    return makeSpecialMeshFallback(node,meshId),"fallback","SpecialMesh"
end
local function makeCSGVisualFallback(node,assetId)
    local p=node.Properties or {};local part=Instance.new("Part");part.Name=tostring(p.Name or node.ClassName);part.CanCollide=false
    applyBaseVisualState(part,p)
    if assetId then local mesh=Instance.new("SpecialMesh");mesh.Name="__LANGZ_CSGVisual";mesh.MeshType=Enum.MeshType.FileMesh;mesh.MeshId="rbxassetid://"..tostring(assetId);configureSpecialMeshScale(mesh,p);mesh.Parent=part end
    return part
end
local function tryLoadPartOperationNode(node)
    local p=node.Properties or {};local assetId=assetIdFromValue(p.AssetId)
    if assetId then queueServerLoad(assetId);return makeCSGVisualFallback(node,assetId),"visual" end
    return makeCSGVisualFallback(node,nil),"proxy"
end
local function preloadNodeAssets(node)
    if not node or not node.Properties then return end;local p=node.Properties
    if node.ClassName=="MeshPart" then queueServerLoad(p.MeshId or p.MeshContent);queueServerLoad(p.TextureID or p.TextureId or p.TextureContent)
    elseif node.ClassName=="SpecialMesh" then queueServerLoad(p.MeshId);queueServerLoad(p.TextureId or p.TextureID)
    elseif node.ClassName=="Decal" or node.ClassName=="Texture" then queueServerLoad(p.Texture)
    elseif node.ClassName=="Shirt" then queueServerLoad(p.ShirtTemplate)
    elseif node.ClassName=="Pants" then queueServerLoad(p.PantsTemplate)
    elseif node.ClassName=="ShirtGraphic" then queueServerLoad(p.Graphic)
    elseif node.ClassName=="UnionOperation" or node.ClassName=="PartOperation" or node.ClassName=="IntersectOperation" then queueServerLoad(p.AssetId) end
end
local function queueAssetsFromObj(root)
    local all={root};for _,d in ipairs(root:GetDescendants()) do all[#all+1]=d end
    for _,obj in ipairs(all) do pcall(function()
        if obj:IsA("MeshPart") then queueServerLoad(obj.MeshId);queueServerLoad(obj.TextureID)
        elseif obj:IsA("SpecialMesh") then queueServerLoad(obj.MeshId);queueServerLoad(obj.TextureId)
        elseif obj:IsA("Decal") or obj:IsA("Texture") then queueServerLoad(obj.Texture)
        elseif obj:IsA("Shirt") then queueServerLoad(obj.ShirtTemplate)
        elseif obj:IsA("Pants") then queueServerLoad(obj.PantsTemplate)
        elseif obj:IsA("ShirtGraphic") then queueServerLoad(obj.Graphic)
        elseif obj:IsA("UnionOperation") or obj:IsA("PartOperation") or obj:IsA("IntersectOperation") then queueServerLoad(obj.AssetId) end
    end) end
end

-- ══════════════════════════════════════════════
-- SCRIPT HELPERS
-- ══════════════════════════════════════════════
local function setScriptEnabled(obj,enabled)
    if not obj or not obj:IsA("LuaSourceContainer") then return false end
    enabled=enabled~=false
    local wrote=false
    local ok=pcall(function() obj.Enabled=enabled end);if ok then wrote=true end
    local ok2=pcall(function() obj.Disabled=not enabled end);if ok2 then wrote=true end
    return wrote
end
local function disableImportedScript(obj,node)
    if not obj:IsA("LuaSourceContainer") then return end
    local p=node and node.Properties or {}
    local origEnabled=true
    if type(p.Enabled)=="boolean" then origEnabled=p.Enabled
    elseif type(p.Disabled)=="boolean" then origEnabled=not p.Disabled end
    pcall(function()
        obj:SetAttribute("LANGZ_OriginalEnabled",origEnabled)
        obj:SetAttribute("LANGZ_StagedDisabled",true)
    end)
    setScriptEnabled(obj,false)
end
local function tryWriteSource(scr,source)
    if not scr or not scr:IsA("LuaSourceContainer") or type(source)~="string" or source=="" then return false end
    _G.Langz_RAW_SOURCES[scr]=source
    local refKey=scr:GetAttribute("LANGZ_Ref")
    if refKey~=nil then _G.Langz_RAW_SOURCE_BY_REF[tostring(refKey)]=source end
    if type(setscriptable)=="function" then pcall(setscriptable,scr,"Source",true) end
    return pcall(function() scr.Source=source end)
end

-- ══════════════════════════════════════════════
-- BUILD RBXM (parsed)
-- ══════════════════════════════════════════════
local function buildRBXModelParsed(parsed,sourceFileName)
    local made={};local importedRoots={};local skipped=0;local failedProperties=0
    local function instantiateModelNode(node)
        if node.ClassName=="MeshPart" then local obj=tryCreateMeshPartNode(node);if obj then return obj end
        elseif node.ClassName=="UnionOperation" or node.ClassName=="PartOperation" or node.ClassName=="IntersectOperation" then local obj=tryLoadPartOperationNode(node);if obj then return obj end end
        local ok,obj=pcall(Instance.new,node.ClassName);if ok then return obj end;return nil
    end
    local function createNode(node,parent)
        preloadNodeAssets(node)
        local obj=instantiateModelNode(node)
        if not obj then skipped=skipped+1;for _,child in ipairs(node.Children or {}) do createNode(child,parent) end;return nil end
        made[node.Ref]=obj
        pcall(function() obj:SetAttribute("LANGZ_ImportedObject",true);obj:SetAttribute("LANGZ_Ref",tostring(node.Ref));obj:SetAttribute("LANGZ_RBXMSource",tostring(sourceFileName or "")) end)
        if node.Properties and node.Properties.Name~=nil then pcall(function() obj.Name=tostring(node.Properties.Name) end) end
        for propName,value in pairs(node.Properties or {}) do
            if propName~="Name" then
                local ok2=applyDecodedProperty(obj,propName,value,node.PropertyTypes and node.PropertyTypes[propName])
                if not ok2 then failedProperties=failedProperties+1 end
            end
        end
        if obj:IsA("BasePart") then
            local orig=obj.Anchored
            if node.Properties and type(node.Properties.Anchored)=="boolean" then orig=node.Properties.Anchored end
            pcall(function() obj:SetAttribute("LANGZ_FileAnchored",orig);obj:SetAttribute("LANGZ_AutoAnchored",true);obj.Anchored=true end)
        end
        disableImportedScript(obj,node)
        obj.Parent=parent
        for _,child in ipairs(node.Children or {}) do
            if not (isMeshPartOnlyChildClass(child.ClassName) and not obj:IsA("MeshPart")) then createNode(child,obj) else skipped=skipped+1 end
        end
        return obj
    end
    for _,root in ipairs(parsed.Roots or {}) do
        local obj=createNode(root,nil)
        if obj then obj.Parent=workspace;importedRoots[#importedRoots+1]=obj end
    end
    for ref,node in pairs(parsed.Nodes or {}) do
        local obj=made[ref]
        if obj and node.PropertyTypes then
            for propName,typeID in pairs(node.PropertyTypes) do
                if typeID==0x13 then local target=made[node.Properties[propName]];if target then pcall(function() obj[propName]=target end) end end
            end
        end
    end
    for ref,obj in pairs(made) do
        local node=parsed.Nodes and parsed.Nodes[ref]
        if obj:IsA("LuaSourceContainer") and node then
            local source=node.Properties and (node.Properties.Source or node.Properties.ContentText)
            if type(source)=="string" and source~="" then pcall(function() tryWriteSource(obj,source) end) end
            pcall(function() injectStudioLiteUI(obj,{}) end)
        end
        if obj:IsA("BasePart") then pcall(function() obj.Anchored=true;obj:SetAttribute("LANGZ_AutoAnchored",true) end) end
    end
    for _,root in ipairs(importedRoots) do pcall(function() queueAssetsFromObj(root) end) end
    flushServerLoadsAsync()
    local count=0;for _ in pairs(made) do count=count+1 end
    return importedRoots,count,skipped,failedProperties
end

-- ══════════════════════════════════════════════
-- COLLECT RBXM SOURCES (binary)
-- ══════════════════════════════════════════════
local function collectRBXMSources(parsed)
    local queues={}
    local function add(node)
        local p=node.Properties or {};local source=p.Source or p.ContentText
        if type(source)=="string" and source~="" then
            source=source:gsub(string.char(0).."*$","")
            local key=tostring(node.ClassName or "").."\0"..tostring(p.Name or "")
            queues[key]=queues[key] or {};queues[key][#queues[key]+1]=source
        end
        for _,child in ipairs(node.Children or {}) do add(child) end
    end
    for _,root in ipairs(parsed.Roots or {}) do add(root) end
    return queues
end
local function takeRBXMSource(sq,obj)
    local key=obj.ClassName.."\0"..obj.Name;local q=sq[key]
    if not q or #q==0 then return nil end;local s=q[1];table.remove(q,1);return s
end

-- ══════════════════════════════════════════════
-- IMPORT RBXM
-- ══════════════════════════════════════════════
local function importRBXM(fileInfo,progressCb)
    local function rep(v,m) if progressCb then pcall(progressCb,v,m) end end
    rep(0.02,"READING RBXM")
    local data,readErr=safeReadFile(fileInfo.path)
    if not data then return false,"READ ERROR: "..tostring(readErr) end
    rep(0.10,"FILE LOADED")
    local fmt=detectFormat(data)
    if not fmt then return false,"Bukan RBXM/RBXMX yang valid" end
    if fmt=="XML" then
        rep(0.16,"PARSING RBXMX XML")
        local ok,parsed,perr=pcall(parseRobloxXML,data)
        if not ok then return false,"XML PARSER CRASH: "..tostring(parsed) end
        if not parsed then return false,"RBXMX PARSE ERROR: "..tostring(perr or "?") end
        rep(0.34,"BUILDING RBXMX")
        local ok2,roots,count,sk,fp=pcall(buildRBXModelParsed,parsed,fileInfo.name)
        if not ok2 then return false,"RBXMX BUILD ERROR: "..tostring(roots) end
        if roots and roots[1] then spawnInFrontOfCamera(roots[1]) end
        rep(1.00,"RBXMX DONE")
        return true,("RBXMX XML OK • %d obj • skip:%d • prop:%d"):format(count or 0,sk or 0,fp or 0),roots and roots[1] or nil
    end
    -- BINARY RBXM
    local sourceQueues={}
    rep(0.15,"PARSING RBXM SOURCES")
    local okp,parsedB=pcall(parseRBXLBinary,data)
    if okp and parsedB then sourceQueues=collectRBXMSources(parsedB) end
    rep(0.24,"REGISTERING RBXM ASSET")
    local objects;local loadMethod="unknown"
    if type(getcustomasset)=="function" then
        local okA,ca=pcall(getcustomasset,fileInfo.path)
        if okA and ca then
            local okO,res=pcall(function() return game:GetObjects(ca) end)
            if okO and type(res)=="table" and #res>0 then objects=res;loadMethod="getcustomasset" end
        end
    end
    if not objects then
        local okO,res=pcall(function() return game:GetObjects("rbxasset://"..tostring(fileInfo.path)) end)
        if okO and type(res)=="table" and #res>0 then objects=res;loadMethod="rbxasset" end
    end
    if not objects then return false,"RBXM LOAD ERROR: getcustomasset/GetObjects gagal" end
    rep(0.40,("RBXM OPENED • %d ROOT"):format(#objects))
    local importedRoots={};local totalObjects=0;local sourceFound=0;local sourceWritten=0;local scriptCount=0
    for rootIndex,root in ipairs(objects) do
        if typeof(root)=="Instance" then
            root:SetAttribute("LANGZ_ImportedObject",true);root:SetAttribute("LANGZ_RBXMSource",fileInfo.name)
            root.Parent=workspace;importedRoots[#importedRoots+1]=root
            if root:IsA("BasePart") then local sa=root.Anchored;root:SetAttribute("LANGZ_FileAnchored",sa);root:SetAttribute("LANGZ_AutoAnchored",true);root.Anchored=true end
            local desc=root:GetDescendants()
            for _,part in ipairs(desc) do if part:IsA("BasePart") then local sa=part.Anchored;part:SetAttribute("LANGZ_FileAnchored",sa);part:SetAttribute("LANGZ_AutoAnchored",true);part.Anchored=true end end
            totalObjects=totalObjects+#desc+1
            local all={root};for _,o in ipairs(desc) do all[#all+1]=o end
            for i,obj in ipairs(all) do
                obj:SetAttribute("LANGZ_ImportedObject",true)
                if obj:IsA("LuaSourceContainer") then
                    scriptCount=scriptCount+1
                    local source=takeRBXMSource(sourceQueues,obj)
                    if source then
                        sourceFound=sourceFound+1;_G.Langz_RAW_SOURCES[obj]=source
                        local wrote=tryWriteSource(obj,source);if wrote then sourceWritten=sourceWritten+1 end
                        pcall(function() injectStudioLiteUI(obj,{}) end)
                    end
                end
                if i%180==0 then task.wait() end
            end
            queueAssetsFromObj(root)
            if root then spawnInFrontOfCamera(root) end
        end
        rep(0.40+(rootIndex/#objects)*0.55,("IMPORTING %d/%d"):format(rootIndex,#objects))
    end
    flushServerLoadsAsync()
    rep(1.00,"RBXM DONE")
    return true,("RBXM OK • %d obj • scripts:%d src:%d/%d • method:%s"):format(totalObjects,scriptCount,sourceWritten,sourceFound,loadMethod),importedRoots[1]
end

-- ══════════════════════════════════════════════
-- SERVICE MAP FOR RBXL
-- ══════════════════════════════════════════════
local SVC_MAP={Workspace=workspace,ReplicatedStorage=ReplicatedStorage,ReplicatedFirst=game:GetService("ReplicatedFirst"),StarterGui=game:GetService("StarterGui"),StarterPack=game:GetService("StarterPack"),StarterPlayer=game:GetService("StarterPlayer"),Lighting=game:GetService("Lighting"),SoundService=game:GetService("SoundService"),ServerScriptService=_G.sss or ReplicatedStorage,ServerStorage=_G.ss or ReplicatedStorage,Teams=ReplicatedStorage,Chat=ReplicatedStorage}
local SVC_KEY_BY_NAME={Workspace="WS",ReplicatedStorage="RS",ReplicatedFirst="RF",Lighting="L",Players="P",StarterGui="SG",StarterPack="STP",StarterPlayer="SP",StarterPlayerScripts="SPS",StarterCharacterScripts="SCS",ServerScriptService="SSS",ServerStorage="SS",Teams="TEAM",SoundService="SND",MaterialService="MAT",TextChatService="TCS",Chat="CHAT",LocalizationService="LOC",TestService="TEST",HttpService="HTTP",InsertService="INS",TweenService="TWEEN"}

-- ══════════════════════════════════════════════
-- BUILD RBXL
-- ══════════════════════════════════════════════
local function importRootName(fileName)
    local base=tostring(fileName or "RBXL"):gsub("%.[Rr][Bb][Xx][Ll][Xx]?$",""):gsub("[%c/\\:*?\"<>|]","_"):gsub("^%s+",""):gsub("%s+$","")
    if base=="" then base="RBXL" end;return base.." ENGINE STUDIO"
end
local function buildRBXL(parsed,sourceFileName,progressCb)
    local function rep(v,m) if progressCb then pcall(progressCb,v,m) end end
    local made={};local skipped=0;local failedProperties=0
    local progressTotal=math.max(tonumber(parsed.Header and parsed.Header.InstanceCount) or 1,1)
    local progressMade=0;rep(0.20,"BUILDING INSTANCES")
    local rootName=importRootName(sourceFileName)
    local oldRoot=workspace:FindFirstChild(rootName);if oldRoot then pcall(function() oldRoot:Destroy() end) end
    local importRoot=Instance.new("Folder");importRoot.Name=rootName;importRoot:SetAttribute("LANGZ_RBXL_IMPORT",true);importRoot:SetAttribute("LANGZ_SourceFile",tostring(sourceFileName or ""));importRoot.Parent=nil
    local containers={}
    local function nf(key,dispName) local f=Instance.new("Folder");f.Name=dispName;f:SetAttribute("LANGZ_ServiceKey",key);f.Parent=importRoot;containers[key]=f;return f end
    nf("WS","workspace(ws)");nf("RS","replicate storage(rs)");nf("RF","replicate first(rf)");nf("L","lighting(l)");nf("P","players(p)");nf("SG","starter gui(sg)");nf("STP","starter pack(stp)");nf("SP","starter player(sp)");nf("SPS","starter player script(sps)");nf("SCS","starter character script(scs)");nf("SSS","serverscriptservice(sss)");nf("SS","server storage(ss)");nf("TEAM","teams(team)");nf("SND","sound service(sound)");nf("MAT","material service(mat)");nf("TCS","text chat service(tcs)");nf("CHAT","chat(chat)");nf("LOC","localization service(loc)")
    local function routeForNode(node,inheritedKey)
        local cn=tostring(node.ClassName or "");local nn=tostring((node.Properties and node.Properties.Name) or "")
        local direct=SVC_KEY_BY_NAME[cn] or SVC_KEY_BY_NAME[nn];if direct then return direct end
        if inheritedKey=="SP" then
            if cn=="StarterPlayerScripts" or nn=="StarterPlayerScripts" then return "SPS"
            elseif cn=="StarterCharacterScripts" or nn=="StarterCharacterScripts" then return "SCS" end
        end
        return inheritedKey or "WS"
    end
    local function instantiateNode(node)
        if node.ClassName=="MeshPart" then local obj=tryCreateMeshPartNode(node);if obj then return obj end
        elseif node.ClassName=="UnionOperation" or node.ClassName=="PartOperation" or node.ClassName=="IntersectOperation" then local obj=tryLoadPartOperationNode(node);if obj then return obj end end
        local ok,obj=pcall(Instance.new,node.ClassName);if ok then return obj end;return nil
    end
    local buildBurstCount=0
    local function createNode(node,parent,inheritedKey)
        local routeKey=routeForNode(node,inheritedKey)
        if isMeshPartOnlyChildClass(node.ClassName) and (not parent or not parent:IsA("MeshPart")) then skipped=skipped+1;return nil end
        local nn=tostring((node.Properties and node.Properties.Name) or "")
        local isServiceLike=node.IsService or node.Service or SVC_KEY_BY_NAME[node.ClassName] or SVC_KEY_BY_NAME[nn]
        if isServiceLike then
            local target=containers[routeKey] or containers.WS
            for _,child in ipairs(node.Children) do createNode(child,target,routeForNode(child,routeKey)) end;return nil
        end
        preloadNodeAssets(node)
        local obj=instantiateNode(node)
        if not obj then skipped=skipped+1;for _,child in ipairs(node.Children) do createNode(child,parent or containers[routeKey] or containers.WS,routeKey) end;return nil end
        made[node.Ref]=obj
        pcall(function() obj:SetAttribute("LANGZ_ImportedObject",true);obj:SetAttribute("LANGZ_Ref",tostring(node.Ref)) end)
        if node.Properties.Name~=nil then pcall(function() obj.Name=tostring(node.Properties.Name) end) end
        for propName,value in pairs(node.Properties) do
            if propName~="Name" then
                local ok2=applyDecodedProperty(obj,propName,value,node.PropertyTypes and node.PropertyTypes[propName])
                if not ok2 then failedProperties=failedProperties+1 end
            end
        end
        if obj:IsA("BasePart") then
            local orig=obj.Anchored
            if node.Properties and type(node.Properties.Anchored)=="boolean" then orig=node.Properties.Anchored end
            pcall(function() obj:SetAttribute("LANGZ_FileAnchored",orig);obj:SetAttribute("LANGZ_AutoAnchored",true);obj.Anchored=true end)
        end
        disableImportedScript(obj,node)
        obj.Parent=parent or containers[routeKey] or containers.WS
        buildBurstCount=buildBurstCount+1;progressMade=progressMade+1
        if progressMade==1 or progressMade%120==0 then rep(0.20+math.min(progressMade/progressTotal,1)*0.55,("GEN %d/%d"):format(progressMade,progressTotal)) end
        if buildBurstCount>=600 then buildBurstCount=0;task.wait() end
        for _,child in ipairs(node.Children) do
            if not (isMeshPartOnlyChildClass(child.ClassName) and not obj:IsA("MeshPart")) then createNode(child,obj,routeKey) else skipped=skipped+1 end
        end
        return obj
    end
    for _,root in ipairs(parsed.Roots) do
        local key=routeForNode(root,"WS")
        local rn=tostring((root.Properties and root.Properties.Name) or "")
        local isServiceLike=root.IsService or root.Service or SVC_KEY_BY_NAME[root.ClassName] or SVC_KEY_BY_NAME[rn]
        if isServiceLike then
            local target=containers[key] or containers.WS
            for _,child in ipairs(root.Children) do createNode(child,target,routeForNode(child,key)) end
        else createNode(root,containers[key] or containers.WS,key) end
    end
    for ref,node in pairs(parsed.Nodes) do
        local obj=made[ref]
        if obj and node.PropertyTypes then
            for propName,typeID in pairs(node.PropertyTypes) do
                if typeID==0x13 then local target=made[node.Properties[propName]];if target then pcall(function() obj[propName]=target end) end end
            end
        end
    end
    local madeCount=0;for _ in pairs(made) do madeCount=madeCount+1 end
    importRoot.Parent=workspace
    -- spawn ws folder in front of camera
    local wsFolder=containers["WS"]
    if wsFolder then
        for _,child in ipairs(wsFolder:GetChildren()) do
            if child:IsA("BasePart") or child:IsA("Model") then spawnInFrontOfCamera(child) end
        end
    end
    return madeCount,skipped,failedProperties,importRoot
end

local function importRBXL(fileInfo,progressCb)
    local function rep(v,m) if progressCb then pcall(progressCb,v,m) end end
    rep(0.02,"READING PLACE FILE")
    local data,readErr=safeReadFile(fileInfo.path)
    if not data then return false,"READ ERROR: "..tostring(readErr) end
    rep(0.08,"PLACE FILE LOADED")
    local fmt=detectFormat(data)
    if not fmt then return false,"Bukan RBXL/RBXLX yang valid" end
    local parsed,parseErr
    if fmt=="BINARY" then
        if type(string.unpack)~="function" then return false,"COMPAT: string.unpack unavailable" end
        if type(bit32)~="table" then return false,"COMPAT: bit32 unavailable" end
        rep(0.12,"PARSING RBXL BINARY")
        local ok,res,err=pcall(parseRBXLBinary,data)
        if not ok then return false,"PARSER CRASH: "..tostring(res) end
        parsed,parseErr=res,err
    else
        rep(0.12,"PARSING RBXLX XML")
        local ok,res,err=pcall(parseRobloxXML,data)
        if not ok then return false,"XML PARSER CRASH: "..tostring(res) end
        parsed,parseErr=res,err
    end
    if not parsed then return false,"PARSE ERROR: "..tostring(parseErr or "?") end
    rep(0.18,("PARSED %s • %d INST"):format(fmt,tonumber(parsed.Header and parsed.Header.InstanceCount) or 0))
    local ok2,madeCount,sk,fp,importRoot=pcall(buildRBXL,parsed,fileInfo.name,rep)
    if not ok2 then return false,"BUILD ERROR: "..tostring(madeCount) end
    return true,("%s OK • %d obj • skip:%d • prop:%d"):format(fmt,madeCount or 0,sk or 0,fp or 0),importRoot
end

-- ══════════════════════════════════════════════
-- FILE SCANNER
-- ══════════════════════════════════════════════
local SCAN_PATHS={"workspace","Delta/workspace","delta/workspace","Android/Delta/workspace","/sdcard/Delta/workspace","/sdcard/Android/Delta/workspace","../workspace",".",""}
local function getFileName(path) return path:match("([^/\\]+)$") or path end
local function looksFolder(path) return not getFileName(path):match("%.[%a%d]+$") end
local function normalizeFsPath(path) local p=tostring(path or ""):gsub("\\","/"):lower():gsub("/+","/"):gsub("^%./",""):gsub("^%.%./",""):gsub("/$","");return p end
local function canonicalWorkspacePath(path)
    local p=normalizeFsPath(path);local lastWs
    local searchFrom=1
    while true do local s,e=p:find("workspace/",searchFrom,true);if not s then break end;lastWs=e+1;searchFrom=e+1 end
    if lastWs then return p:sub(lastWs) end;if p=="workspace" then return "" end;return p
end
local function scanDeep(folder,depth,results,seenFolders,seenFiles)
    if depth>4 then return end
    local fk=canonicalWorkspacePath(folder);if fk=="" then fk="__root__" end
    if seenFolders[fk] then return end;seenFolders[fk]=true
    local list=safeListFiles(folder);if not list then return end
    for _,path in ipairs(list) do
        local name=getFileName(path);local lower=name:lower();local ftype
        if lower:match("%.rbxl$") or lower:match("%.rbxlx$") then ftype="RBXL"
        elseif lower:match("%.rbxm$") or lower:match("%.rbxmx$") then ftype="RBXM" end
        if ftype then
            local fileKey=canonicalWorkspacePath(path);if fileKey=="" then fileKey=lower end
            if not seenFiles[fileKey] then
                seenFiles[fileKey]=true
                table.insert(results,{name=name,path=path,folder=folder,ftype=ftype,canonicalKey=fileKey,
                    ext=lower:match("%.([%a]+)$") or ""})
            end
        elseif looksFolder(path) then scanDeep(path,depth+1,results,seenFolders,seenFiles) end
    end
end
local function scanAllSupported()
    local results={};local seenFolders={};local seenFiles={}
    for _,path in ipairs(SCAN_PATHS) do if safeListFiles(path) then scanDeep(path,0,results,seenFolders,seenFiles) end end
    table.sort(results,function(a,b) local an=a.name:lower();local bn=b.name:lower();if an==bn then return tostring(a.canonicalKey)<tostring(b.canonicalKey) end;return an<bn end)
    return results
end
local function countByType(results)
    local rbxm,rbxmx,rbxl,rbxlx=0,0,0,0
    for _,f in ipairs(results) do
        if f.ext=="rbxm" then rbxm=rbxm+1
        elseif f.ext=="rbxmx" then rbxmx=rbxmx+1
        elseif f.ext=="rbxl" then rbxl=rbxl+1
        elseif f.ext=="rbxlx" then rbxlx=rbxlx+1 end
    end
    return rbxm,rbxmx,rbxl,rbxlx
end

-- ══════════════════════════════════════════════
-- FPS / SIGNAL MONITOR
-- ══════════════════════════════════════════════
local currentFPS=60
local currentSignal=5
task.spawn(function()
    while true do
        local t0=os.clock();RunService.Heartbeat:Wait();local dt=os.clock()-t0
        currentFPS=math.floor(1/math.max(dt,0.001))
        task.wait(0.5)
    end
end)
task.spawn(function()
    while true do
        local ok,ping=pcall(function() return Players.LocalPlayer:GetNetworkPing() end)
        if ok and ping then
            if ping<0.05 then currentSignal=5
            elseif ping<0.1 then currentSignal=4
            elseif ping<0.2 then currentSignal=3
            elseif ping<0.4 then currentSignal=2
            else currentSignal=1 end
        end
        task.wait(2)
    end
end)

-- ══════════════════════════════════════════════
-- ══════════════════════════════════════════════
-- UI SYSTEM — LIQUID GLASS GREEN HORROR
-- ══════════════════════════════════════════════
-- ══════════════════════════════════════════════

local TOGGLE_ICON_ID = "92844638469747"
local LOGO_ICON_ID   = "92844638469747"
local RBXM_ICON_ID   = "106962661743892"
local RBXL_ICON_ID   = "122982660526589"

-- destroy old
local oldGui=CoreDest:FindFirstChild("EngineStudioForMobile")
if oldGui then oldGui:Destroy() end

local ScreenGui=Instance.new("ScreenGui")
ScreenGui.Name="EngineStudioForMobile"
ScreenGui.ResetOnSpawn=false
ScreenGui.IgnoreGuiInset=true
ScreenGui.DisplayOrder=750
ScreenGui.ZIndexBehavior=Enum.ZIndexBehavior.Global
ScreenGui.Parent=CoreDest

-- ── COLORS ──────────────────────────────────
local C={
    -- liquid glass base
    glass        = Color3.fromRGB(8,22,12),
    glassBorder  = Color3.fromRGB(0,180,60),
    glassBorder2 = Color3.fromRGB(0,100,30),
    glassHighlight=Color3.fromRGB(80,255,120),
    -- panel
    panel        = Color3.fromRGB(5,14,8),
    panel2       = Color3.fromRGB(10,24,14),
    panel3       = Color3.fromRGB(14,32,18),
    -- text
    text         = Color3.fromRGB(220,255,230),
    textDim      = Color3.fromRGB(90,160,100),
    textBright   = Color3.fromRGB(0,255,80),
    -- status
    success      = Color3.fromRGB(0,230,80),
    warning      = Color3.fromRGB(220,180,0),
    danger       = Color3.fromRGB(220,40,40),
    -- accent
    accent       = Color3.fromRGB(0,200,70),
    accent2      = Color3.fromRGB(0,120,40),
    dark         = Color3.fromRGB(2,8,4),
    black        = Color3.fromRGB(1,4,2),
}

-- ── UI HELPERS ───────────────────────────────
local function corner(obj,r) local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r or 10);c.Parent=obj;return c end
local function stroke(obj,color,thickness,trans)
    local s=Instance.new("UIStroke");s.Color=color or C.glassBorder;s.Thickness=thickness or 1;s.Transparency=trans or 0
    s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;s.Parent=obj;return s
end
local function gradient(obj,colors,rot)
    local g=Instance.new("UIGradient");g.Color=ColorSequence.new(colors);g.Rotation=rot or 0;g.Parent=obj;return g
end
local function label(parent,text,size,font,color,xalign)
    local l=Instance.new("TextLabel");l.BackgroundTransparency=1;l.Text=text;l.TextSize=size or 12
    l.Font=font or Enum.Font.GothamBold;l.TextColor3=color or C.text
    l.TextXAlignment=xalign or Enum.TextXAlignment.Left;l.TextYAlignment=Enum.TextYAlignment.Center
    l.Parent=parent;return l
end
local function btn(parent,text,size,font,color)
    local b=Instance.new("TextButton");b.BackgroundColor3=color or C.panel2;b.BorderSizePixel=0
    b.Text=text;b.TextSize=size or 11;b.Font=font or Enum.Font.GothamBold;b.TextColor3=C.text
    b.AutoButtonColor=false;b.Parent=parent;return b
end
local function image(parent,id,size)
    local i=Instance.new("ImageLabel");i.BackgroundTransparency=1
    i.Image="rbxassetid://"..id;i.Size=size or UDim2.fromOffset(20,20);i.Parent=parent;return i
end

-- animated green glow stroke
local function glowStroke(obj,thickness)
    local s=Instance.new("UIStroke");s.Name="GlowStroke";s.Thickness=thickness or 1.5;s.Transparency=0
    s.Color=Color3.fromRGB(0,255,80);s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;s.Parent=obj
    local g=Instance.new("UIGradient");g.Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,30,10)),
        ColorSequenceKeypoint.new(0.2, Color3.fromRGB(0,180,50)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80,255,120)),
        ColorSequenceKeypoint.new(0.8, Color3.fromRGB(0,180,50)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,30,10)),
    });g.Offset=Vector2.new(-1,0);g.Parent=s
    TweenService:Create(g,TweenInfo.new(1.2,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,-1,true),{Offset=Vector2.new(1,0)}):Play()
    return s
end

-- glass frame factory
local function glassFrame(parent,size,pos,alpha,r)
    alpha=alpha or 0.60;r=r or 12
    local f=Instance.new("Frame");f.Size=size;f.Position=pos or UDim2.fromOffset(0,0)
    f.BackgroundColor3=C.glass;f.BackgroundTransparency=alpha;f.BorderSizePixel=0;f.Parent=parent
    corner(f,r)
    gradient(f,{ColorSequenceKeypoint.new(0,Color3.fromRGB(0,60,20)),ColorSequenceKeypoint.new(0.5,Color3.fromRGB(0,30,10)),ColorSequenceKeypoint.new(1,Color3.fromRGB(0,10,4))},90)
    return f
end

-- ══════════════════════════════════════════════
-- TOGGLE BUTTON (bottom right)
-- ══════════════════════════════════════════════
local toggleBtn=Instance.new("TextButton")
toggleBtn.Name="ToggleBtn"
toggleBtn.Size=UDim2.fromOffset(44,44)
toggleBtn.Position=UDim2.new(1,-58,1,-58)
toggleBtn.BackgroundColor3=C.dark
toggleBtn.BackgroundTransparency=0.3
toggleBtn.BorderSizePixel=0
toggleBtn.Text=""
toggleBtn.AutoButtonColor=false
toggleBtn.ZIndex=200
toggleBtn.Parent=ScreenGui
corner(toggleBtn,10)
glowStroke(toggleBtn,1.5)
local toggleImg=image(toggleBtn,TOGGLE_ICON_ID,UDim2.fromOffset(32,32))
toggleImg.AnchorPoint=Vector2.new(0.5,0.5)
toggleImg.Position=UDim2.fromScale(0.5,0.5)
toggleImg.ScaleType=Enum.ScaleType.Fit
-- drag toggle
do
    local dragging=false;local moved=false;local ds;local sp
    toggleBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            dragging=true;moved=false;ds=inp.Position;sp=toggleBtn.Position
            inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then dragging=false end end)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch then
            local delta=inp.Position-ds
            if math.abs(delta.X)>5 or math.abs(delta.Y)>5 then moved=true end
            if moved then toggleBtn.Position=UDim2.new(sp.X.Scale,sp.X.Offset+delta.X,sp.Y.Scale,sp.Y.Offset+delta.Y) end
        end
    end)
end

-- ══════════════════════════════════════════════
-- MAIN CONTAINER (resizable)
-- ══════════════════════════════════════════════
local mainW,mainH=580,420
local mainVisible=false

local mainFrame=Instance.new("Frame")
mainFrame.Name="MainFrame"
mainFrame.Size=UDim2.fromOffset(mainW,mainH)
mainFrame.Position=UDim2.new(0.5,-mainW/2,0.5,-mainH/2)
mainFrame.BackgroundColor3=C.glass
mainFrame.BackgroundTransparency=0.18
mainFrame.BorderSizePixel=0
mainFrame.Visible=false
mainFrame.ZIndex=100
mainFrame.ClipsDescendants=true
mainFrame.Parent=ScreenGui
corner(mainFrame,16)
glowStroke(mainFrame,2)
gradient(mainFrame,{ColorSequenceKeypoint.new(0,Color3.fromRGB(0,80,25)),ColorSequenceKeypoint.new(0.4,Color3.fromRGB(0,30,10)),ColorSequenceKeypoint.new(1,Color3.fromRGB(0,10,4))},130)

-- ── RESIZE HANDLE (bottom right) ─────────────
local resizeHandle=Instance.new("TextButton")
resizeHandle.Name="ResizeHandle"
resizeHandle.Size=UDim2.fromOffset(18,18)
resizeHandle.AnchorPoint=Vector2.new(1,1)
resizeHandle.Position=UDim2.new(1,0,1,0)
resizeHandle.BackgroundColor3=C.accent2
resizeHandle.BackgroundTransparency=0.4
resizeHandle.BorderSizePixel=0
resizeHandle.Text="⤡"
resizeHandle.TextColor3=C.textBright
resizeHandle.TextSize=10
resizeHandle.Font=Enum.Font.GothamBold
resizeHandle.AutoButtonColor=false
resizeHandle.ZIndex=300
resizeHandle.Parent=mainFrame
corner(resizeHandle,4)
do
    local resizing=false;local resizeStart;local startSize
    resizeHandle.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            resizing=true;resizeStart=inp.Position;startSize=mainFrame.Size
            inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then resizing=false end end)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not resizing then return end
        if inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch then
            local delta=inp.Position-resizeStart
            local newW=math.max(400,startSize.X.Offset+delta.X)
            local newH=math.max(300,startSize.Y.Offset+delta.Y)
            mainFrame.Size=UDim2.fromOffset(newW,newH)
        end
    end)
end

-- ── HEADER BAR ───────────────────────────────
local headerBar=Instance.new("Frame")
headerBar.Size=UDim2.new(1,0,0,42)
headerBar.BackgroundColor3=C.dark
headerBar.BackgroundTransparency=0.4
headerBar.BorderSizePixel=0
headerBar.ZIndex=110
headerBar.Parent=mainFrame
corner(headerBar,0)
-- bottom border line
local headerLine=Instance.new("Frame");headerLine.Size=UDim2.new(1,0,0,1);headerLine.Position=UDim2.new(0,0,1,-1);headerLine.BackgroundColor3=C.glassBorder;headerLine.BackgroundTransparency=0;headerLine.BorderSizePixel=0;headerLine.Parent=headerBar

-- Logo
local logoBox=Instance.new("Frame");logoBox.Size=UDim2.fromOffset(32,32);logoBox.Position=UDim2.fromOffset(8,5);logoBox.BackgroundColor3=C.dark;logoBox.BackgroundTransparency=0.2;logoBox.BorderSizePixel=0;logoBox.ZIndex=120;logoBox.Parent=headerBar;corner(logoBox,8)
local logoImg=image(logoBox,LOGO_ICON_ID,UDim2.fromScale(1,1));logoImg.ScaleType=Enum.ScaleType.Fit;logoImg.ZIndex=121

-- Title
local titleLabel=label(headerBar,"ENGINE DESKTOP FOR MOBILE SUPPORT",13,Enum.Font.GothamBold,C.textBright,Enum.TextXAlignment.Left)
titleLabel.Position=UDim2.fromOffset(48,0);titleLabel.Size=UDim2.new(1,-180,1,0);titleLabel.ZIndex=120

-- Close btn
local closeBtn=btn(headerBar,"×",18,Enum.Font.GothamBold,C.dark)
closeBtn.AnchorPoint=Vector2.new(1,0.5);closeBtn.Position=UDim2.new(1,-8,0.5,0);closeBtn.Size=UDim2.fromOffset(28,28);closeBtn.TextColor3=C.danger;closeBtn.BackgroundTransparency=0.4;closeBtn.ZIndex=120;corner(closeBtn,8);stroke(closeBtn,C.danger,1,0.4)

-- drag main via header
do
    local dragging=false;local ds;local sp
    headerBar.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            dragging=true;ds=inp.Position;sp=mainFrame.Position
            inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then dragging=false end end)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch then
            local delta=inp.Position-ds
            mainFrame.Position=UDim2.new(sp.X.Scale,sp.X.Offset+delta.X,sp.Y.Scale,sp.Y.Offset+delta.Y)
        end
    end)
end

-- ══════════════════════════════════════════════
-- BODY (below header)
-- ══════════════════════════════════════════════
local bodyFrame=Instance.new("Frame")
bodyFrame.Position=UDim2.fromOffset(0,42)
bodyFrame.Size=UDim2.new(1,0,1,-42)
bodyFrame.BackgroundTransparency=1
bodyFrame.BorderSizePixel=0
bodyFrame.ZIndex=105
bodyFrame.Parent=mainFrame

-- ═══════════════════════════════════════
-- VIEW SYSTEM: "dashboard" or "main_ui"
-- ═══════════════════════════════════════
local currentView="dashboard"  -- starts at dashboard

-- ══════════════════════════════════════════════
-- ══════════════════════════════════════════════
-- DASHBOARD VIEW
-- ══════════════════════════════════════════════
-- ══════════════════════════════════════════════
local dashView=Instance.new("Frame")
dashView.Size=UDim2.fromScale(1,1)
dashView.BackgroundTransparency=1
dashView.BorderSizePixel=0
dashView.ZIndex=106
dashView.Visible=true
dashView.Parent=bodyFrame

-- ── LEFT SIDE (scan + open) ──────────────────
local dashLeft=glassFrame(dashView,UDim2.fromOffset(140,0),UDim2.fromOffset(6,6),0.55,10)
dashLeft.Size=UDim2.new(0,140,1,-12)

-- scan btn
local scanFileBtn=btn(dashLeft,"SCAN FILES",10,Enum.Font.GothamBold,C.panel2)
scanFileBtn.Size=UDim2.new(1,-12,0,34);scanFileBtn.Position=UDim2.fromOffset(6,8);scanFileBtn.BackgroundTransparency=0.4
corner(scanFileBtn,8);glowStroke(scanFileBtn,1.2)

-- open panel btn
local openPanelBtn=btn(dashLeft,"OPEN PANEL",10,Enum.Font.GothamBold,C.panel2)
openPanelBtn.Size=UDim2.new(1,-12,0,34);openPanelBtn.Position=UDim2.fromOffset(6,48);openPanelBtn.BackgroundTransparency=0.4
corner(openPanelBtn,8);glowStroke(openPanelBtn,1.2)

-- ── RIGHT SIDE (stats grid) ──────────────────
local dashRight=glassFrame(dashView,UDim2.new(1,-156,1,-12),UDim2.fromOffset(152,6),0.50,12)

local statsLabel=label(dashRight,"DASHBOARD",11,Enum.Font.GothamBold,C.textBright)
statsLabel.Size=UDim2.new(1,0,0,22);statsLabel.Position=UDim2.fromOffset(10,4);statsLabel.TextXAlignment=Enum.TextXAlignment.Left

local statsGrid=Instance.new("Frame")
statsGrid.Size=UDim2.new(1,-12,1,-36)
statsGrid.Position=UDim2.fromOffset(6,30)
statsGrid.BackgroundTransparency=1
statsGrid.Parent=dashRight
local gridLayout=Instance.new("UIGridLayout")
gridLayout.CellSize=UDim2.fromOffset(120,56)
gridLayout.CellPadding=UDim2.fromOffset(6,6)
gridLayout.FillDirectionMaxCells=3
gridLayout.SortOrder=Enum.SortOrder.LayoutOrder
gridLayout.Parent=statsGrid

local statCards={}
local function makeStatCard(title,value,icon)
    local card=glassFrame(statsGrid,UDim2.fromOffset(120,56),nil,0.45,10)
    card.LayoutOrder=#statCards+1
    local lIcon=label(card,icon or "",16,Enum.Font.GothamBold,C.accent,Enum.TextXAlignment.Center)
    lIcon.Position=UDim2.fromOffset(4,2);lIcon.Size=UDim2.fromOffset(28,22)
    local lTitle=label(card,title,7,Enum.Font.Gotham,C.textDim,Enum.TextXAlignment.Left)
    lTitle.Position=UDim2.fromOffset(6,24);lTitle.Size=UDim2.new(1,-8,0,14)
    local lValue=label(card,value,13,Enum.Font.GothamBold,C.textBright,Enum.TextXAlignment.Left)
    lValue.Position=UDim2.fromOffset(6,36);lValue.Size=UDim2.new(1,-8,0,16)
    table.insert(statCards,{card=card,valueLabel=lValue,title=title})
    return lValue
end

local rbxmStat  = makeStatCard("RBXM","0","[M]")
local rbxmxStat = makeStatCard("RBXMX","0","[X]")
local rbxlStat  = makeStatCard("RBXL","0","[L]")
local rbxlxStat = makeStatCard("RBXLX","0","[LX]")
local fpsStat   = makeStatCard("FPS","60","FPS")
local sigStat   = makeStatCard("SIGNAL","5/5","SIG")

-- update stats every second
local lastFileCounts={rbxm=0,rbxmx=0,rbxl=0,rbxlx=0}
local function updateDashStats()
    fpsStat.Text=tostring(math.min(currentFPS,999))
    sigStat.Text=tostring(currentSignal).."/5"
    rbxmStat.Text=tostring(lastFileCounts.rbxm)
    rbxmxStat.Text=tostring(lastFileCounts.rbxmx)
    rbxlStat.Text=tostring(lastFileCounts.rbxl)
    rbxlxStat.Text=tostring(lastFileCounts.rbxlx)
end
task.spawn(function()
    while ScreenGui.Parent do
        updateDashStats()
        task.wait(1)
    end
end)

-- ══════════════════════════════════════════════
-- ══════════════════════════════════════════════
-- MAIN UI VIEW (sidebar + content)
-- ══════════════════════════════════════════════
-- ══════════════════════════════════════════════
local mainUIView=Instance.new("Frame")
mainUIView.Size=UDim2.fromScale(1,1)
mainUIView.BackgroundTransparency=1
mainUIView.BorderSizePixel=0
mainUIView.ZIndex=106
mainUIView.Visible=false
mainUIView.Parent=bodyFrame

-- ── SIDEBAR ──────────────────────────────────
local sidebar=glassFrame(mainUIView,UDim2.new(0,145,1,-6),UDim2.fromOffset(5,3),0.52,10)
local sidebarLayout=Instance.new("UIListLayout");sidebarLayout.Padding=UDim.new(0,4);sidebarLayout.SortOrder=Enum.SortOrder.LayoutOrder;sidebarLayout.Parent=sidebar

local function sidebarCategoryLabel(text)
    local l=label(sidebar,text,8,Enum.Font.GothamBold,C.textDim,Enum.TextXAlignment.Left)
    l.Size=UDim2.new(1,0,0,18);l.LayoutOrder=#sidebar:GetChildren()+1
    local pad=Instance.new("UIPadding");pad.PaddingLeft=UDim.new(0,8);pad.Parent=l
    return l
end

local function sidebarButton(text,order)
    local b=btn(sidebar,text,10,Enum.Font.GothamBold,C.panel2)
    b.Size=UDim2.new(1,-8,0,30);b.LayoutOrder=order or #sidebar:GetChildren()+1;b.BackgroundTransparency=0.5
    b.TextXAlignment=Enum.TextXAlignment.Left
    local pad=Instance.new("UIPadding");pad.PaddingLeft=UDim.new(0,10);pad.Parent=b
    corner(b,8);stroke(b,C.glassBorder2,1,0.5)
    b.MouseEnter:Connect(function() TweenService:Create(b,TweenInfo.new(0.1),{BackgroundTransparency=0.2}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b,TweenInfo.new(0.1),{BackgroundTransparency=0.5}):Play() end)
    return b
end

-- BACK button (top of sidebar, below header)
local backBtn=btn(sidebar,"< BACK",10,Enum.Font.GothamBold,C.dark)
backBtn.Size=UDim2.new(1,-8,0,28);backBtn.LayoutOrder=1;backBtn.TextColor3=C.textBright;backBtn.BackgroundTransparency=0.4
corner(backBtn,8);glowStroke(backBtn,1.2)

-- spacer
local spacer0=Instance.new("Frame");spacer0.Size=UDim2.new(1,0,0,2);spacer0.BackgroundTransparency=1;spacer0.LayoutOrder=2;spacer0.Parent=sidebar

-- ── DASHBOARD CATEGORY ───────────────────────
local catDash=sidebarCategoryLabel("DASHBOARD")
catDash.LayoutOrder=3
local dashBtn=sidebarButton("Dashboard",4)

-- ── IMPORTER CATEGORY ────────────────────────
local catImporter=sidebarCategoryLabel("IMPORTER")
catImporter.LayoutOrder=5

local rbxmBtn   = sidebarButton("Import RBXM",6)
local rbxmxBtn  = sidebarButton("Import RBXMX",7)
local rbxlBtn   = sidebarButton("Import RBXL",8)
local rbxlxBtn  = sidebarButton("Import RBXLX",9)

-- add icons to sidebar import buttons
local function addIconToSideBtn(b,iconId)
    local ico=Instance.new("ImageLabel");ico.BackgroundTransparency=1
    ico.Image="rbxassetid://"..iconId;ico.Size=UDim2.fromOffset(16,16)
    ico.AnchorPoint=Vector2.new(1,0.5);ico.Position=UDim2.new(1,-6,0.5,0);ico.ScaleType=Enum.ScaleType.Fit
    ico.ZIndex=b.ZIndex+1;ico.Parent=b
end
addIconToSideBtn(rbxmBtn,RBXM_ICON_ID);addIconToSideBtn(rbxmxBtn,RBXM_ICON_ID)
addIconToSideBtn(rbxlBtn,RBXL_ICON_ID);addIconToSideBtn(rbxlxBtn,RBXL_ICON_ID)

-- ── CONTENT AREA ─────────────────────────────
local contentArea=Instance.new("Frame")
contentArea.Position=UDim2.fromOffset(154,3)
contentArea.Size=UDim2.new(1,-158,1,-6)
contentArea.BackgroundTransparency=1
contentArea.BorderSizePixel=0
contentArea.ZIndex=107
contentArea.Parent=mainUIView

-- panels inside content (swapped by tab)
local activeContentPanel=nil

local function clearContent()
    if activeContentPanel then activeContentPanel:Destroy();activeContentPanel=nil end
end
local function newContentPanel()
    clearContent()
    local p=glassFrame(contentArea,UDim2.fromScale(1,1),UDim2.fromOffset(0,0),0.52,12)
    activeContentPanel=p;return p
end

-- ── DASHBOARD CONTENT ────────────────────────
local function showDashboardContent()
    local p=newContentPanel()
    local t=label(p,"DASHBOARD",13,Enum.Font.GothamBold,C.textBright)
    t.Size=UDim2.new(1,-12,0,24);t.Position=UDim2.fromOffset(10,8)

    -- feature buttons grid
    local featureGrid=Instance.new("Frame");featureGrid.Size=UDim2.new(1,-12,1,-40);featureGrid.Position=UDim2.fromOffset(6,38);featureGrid.BackgroundTransparency=1;featureGrid.Parent=p
    local gl=Instance.new("UIGridLayout");gl.CellSize=UDim2.fromOffset(100,38);gl.CellPadding=UDim2.fromOffset(6,6);gl.FillDirectionMaxCells=3;gl.SortOrder=Enum.SortOrder.LayoutOrder;gl.Parent=featureGrid

    local features={"Auto-Anchor","Decompile","Script View","Asset Queue","StudioLite","Flush Assets","Clear Workspace","Re-Scan","About Engine"}
    for i,name in ipairs(features) do
        local fb=btn(featureGrid,name,9,Enum.Font.GothamBold,C.panel2)
        fb.Size=UDim2.fromOffset(100,38);fb.LayoutOrder=i;fb.BackgroundTransparency=0.4
        fb.TextXAlignment=Enum.TextXAlignment.Center;corner(fb,8);stroke(fb,C.glassBorder2,1,0.4)
        fb.MouseEnter:Connect(function() TweenService:Create(fb,TweenInfo.new(0.1),{BackgroundTransparency=0.15}):Play() end)
        fb.MouseLeave:Connect(function() TweenService:Create(fb,TweenInfo.new(0.1),{BackgroundTransparency=0.4}):Play() end)
        if name=="Clear Workspace" then
            fb.MouseButton1Click:Connect(function()
                for _,obj in ipairs(workspace:GetChildren()) do
                    if obj:GetAttribute("LANGZ_ImportedObject") or obj:GetAttribute("LANGZ_RBXL_IMPORT") then pcall(function() obj:Destroy() end) end
                end
                lastFileCounts={rbxm=0,rbxmx=0,rbxl=0,rbxlx=0}
            end)
        elseif name=="Flush Assets" then
            fb.MouseButton1Click:Connect(function() flushServerLoadsAsync() end)
        end
    end
end

-- ── FILE LIST CONTENT (shared for all 4 types)
local currentImportFilter="ALL"
local allScannedFiles={}

local function makeFileCard(parent,info,progressCallback)
    local card=glassFrame(parent,UDim2.new(1,-8,0,46),nil,0.50,8)
    local iconId=("rbxm"==info.ext or "rbxmx"==info.ext) and RBXM_ICON_ID or RBXL_ICON_ID
    local ico=image(card,"rbxassetid://"..iconId,UDim2.fromOffset(28,28))
    -- fix: just use the id string directly
    local ico2=Instance.new("ImageLabel");ico2.BackgroundTransparency=1
    ico2.Image="rbxassetid://"..iconId;ico2.Size=UDim2.fromOffset(28,28);ico2.AnchorPoint=Vector2.new(0,0.5);ico2.Position=UDim2.new(0,4,0.5,0);ico2.ScaleType=Enum.ScaleType.Fit;ico2.Parent=card
    ico:Destroy()
    local nameLbl=label(card,info.name,8,Enum.Font.GothamBold,C.text)
    nameLbl.Position=UDim2.fromOffset(36,4);nameLbl.Size=UDim2.new(1,-120,0,16);nameLbl.TextTruncate=Enum.TextTruncate.AtEnd
    local typeLbl=label(card,info.ext:upper(),7,Enum.Font.Gotham,C.textDim)
    typeLbl.Position=UDim2.fromOffset(36,20);typeLbl.Size=UDim2.new(1,-120,0,14)
    local importBtn=btn(card,"IMPORT",9,Enum.Font.GothamBold,C.accent2)
    importBtn.AnchorPoint=Vector2.new(1,0.5);importBtn.Position=UDim2.new(1,-4,0.5,0);importBtn.Size=UDim2.fromOffset(60,28);importBtn.TextColor3=C.textBright
    corner(importBtn,7);glowStroke(importBtn,1)
    importBtn.MouseButton1Click:Connect(function()
        importBtn.Text="...";importBtn.BackgroundColor3=C.glassBorder2
        local progressBar=Instance.new("Frame");progressBar.Size=UDim2.new(0,0,0,2);progressBar.Position=UDim2.new(0,0,1,-2);progressBar.BackgroundColor3=C.accent;progressBar.BorderSizePixel=0;progressBar.Parent=card
        local function cb(v,m)
            progressBar.Size=UDim2.new(math.clamp(v,0,1),0,0,2)
            if m then typeLbl.Text=m:sub(1,30) end
        end
        task.spawn(function()
            local ok,msg
            if info.ftype=="RBXM" then
                ok,msg=importRBXM(info,cb)
            else
                ok,msg=importRBXL(info,cb)
            end
            if ok then
                importBtn.Text="DONE";importBtn.BackgroundColor3=C.success
                typeLbl.Text="OK"
            else
                importBtn.Text="FAIL";importBtn.BackgroundColor3=C.danger
                typeLbl.Text=(msg or "err"):sub(1,28)
            end
            task.wait(2)
            if importBtn and importBtn.Parent then importBtn.Text="IMPORT";importBtn.BackgroundColor3=C.accent2;typeLbl.Text=info.ext:upper() end
            if progressBar and progressBar.Parent then progressBar:Destroy() end
        end)
    end)
    return card
end

local function showImporterContent(filterExt)
    currentImportFilter=filterExt or "ALL"
    local p=newContentPanel()
    local titleStr=(filterExt=="ALL") and "FILE LIBRARY" or ("IMPORT "..filterExt:upper())
    local t=label(p,titleStr,13,Enum.Font.GothamBold,C.textBright)
    t.Size=UDim2.new(1,-80,0,24);t.Position=UDim2.fromOffset(10,8)
    local rescanBtn=btn(p,"RESCAN",9,Enum.Font.GothamBold,C.panel2)
    rescanBtn.AnchorPoint=Vector2.new(1,0);rescanBtn.Position=UDim2.new(1,-6,0,6);rescanBtn.Size=UDim2.fromOffset(60,22)
    rescanBtn.BackgroundTransparency=0.4;corner(rescanBtn,7);stroke(rescanBtn,C.glassBorder,1,0.4)

    local scrollFrame=Instance.new("ScrollingFrame")
    scrollFrame.Position=UDim2.fromOffset(4,36);scrollFrame.Size=UDim2.new(1,-8,1,-42)
    scrollFrame.BackgroundTransparency=1;scrollFrame.BorderSizePixel=0
    scrollFrame.ScrollBarThickness=4;scrollFrame.ScrollBarImageColor3=C.accent
    scrollFrame.AutomaticCanvasSize=Enum.AutomaticSize.Y;scrollFrame.CanvasSize=UDim2.new(0,0,0,0)
    scrollFrame.Parent=p
    local listLayout=Instance.new("UIListLayout");listLayout.Padding=UDim.new(0,4);listLayout.SortOrder=Enum.SortOrder.LayoutOrder;listLayout.Parent=scrollFrame

    local emptyLabel=label(scrollFrame,"NO FILES FOUND — PRESS RESCAN",9,Enum.Font.GothamBold,C.textDim,Enum.TextXAlignment.Center)
    emptyLabel.Size=UDim2.new(1,0,0,40)

    local function populate(files)
        for _,child in ipairs(scrollFrame:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
        emptyLabel.Visible=true
        local shown=0
        for _,info in ipairs(files) do
            local match=(filterExt=="ALL") or (info.ext==filterExt:lower())
            if match then
                makeFileCard(scrollFrame,info)
                shown=shown+1
            end
        end
        emptyLabel.Visible=(shown==0)
    end

    populate(allScannedFiles)

    rescanBtn.MouseButton1Click:Connect(function()
        rescanBtn.Text="...";rescanBtn.BackgroundColor3=C.warning
        task.spawn(function()
            if type(listfiles)~="function" then rescanBtn.Text="ERR";return end
            allScannedFiles=scanAllSupported()
            local rm,rmx,rl,rlx=countByType(allScannedFiles)
            lastFileCounts={rbxm=rm,rbxmx=rmx,rbxl=rl,rbxlx=rlx}
            populate(allScannedFiles)
            rescanBtn.Text="RESCAN";rescanBtn.BackgroundColor3=C.panel2
        end)
    end)
end

-- ── WIRE SIDEBAR BUTTONS ─────────────────────
dashBtn.MouseButton1Click:Connect(function() showDashboardContent() end)
rbxmBtn.MouseButton1Click:Connect(function() showImporterContent("rbxm") end)
rbxmxBtn.MouseButton1Click:Connect(function() showImporterContent("rbxmx") end)
rbxlBtn.MouseButton1Click:Connect(function() showImporterContent("rbxl") end)
rbxlxBtn.MouseButton1Click:Connect(function() showImporterContent("rbxlx") end)

-- ── BACK BUTTON ──────────────────────────────
local function switchView(view)
    currentView=view
    if view=="dashboard" then
        dashView.Visible=true;mainUIView.Visible=false
        -- update header title
        titleLabel.Text="ENGINE DESKTOP FOR MOBILE SUPPORT"
    elseif view=="main_ui" then
        dashView.Visible=false;mainUIView.Visible=true
        showDashboardContent()
        titleLabel.Text="ENGINE DESKTOP FOR MOBILE SUPPORT"
    end
end

openPanelBtn.MouseButton1Click:Connect(function()
    -- rescan on open
    task.spawn(function()
        if type(listfiles)=="function" then
            allScannedFiles=scanAllSupported()
            local rm,rmx,rl,rlx=countByType(allScannedFiles)
            lastFileCounts={rbxm=rm,rbxmx=rmx,rbxl=rl,rbxlx=rlx}
        end
    end)
    switchView("main_ui")
end)
backBtn.MouseButton1Click:Connect(function() switchView("dashboard") end)
scanFileBtn.MouseButton1Click:Connect(function()
    scanFileBtn.Text="SCANNING..."
    task.spawn(function()
        if type(listfiles)=="function" then
            allScannedFiles=scanAllSupported()
            local rm,rmx,rl,rlx=countByType(allScannedFiles)
            lastFileCounts={rbxm=rm,rbxmx=rmx,rbxl=rl,rbxlx=rlx}
            updateDashStats()
        end
        scanFileBtn.Text="SCAN FILES"
    end)
end)

-- ══════════════════════════════════════════════
-- TOGGLE SHOW / HIDE
-- ══════════════════════════════════════════════
local function setMainVisible(v)
    mainVisible=v
    if v then
        mainFrame.Visible=true
        mainFrame.BackgroundTransparency=1
        TweenService:Create(mainFrame,TweenInfo.new(0.22,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=0.18}):Play()
    else
        TweenService:Create(mainFrame,TweenInfo.new(0.18,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{BackgroundTransparency=1}):Play()
        task.delay(0.2,function() if not mainVisible then mainFrame.Visible=false end end)
    end
end

toggleBtn.MouseButton1Click:Connect(function()
    -- if toggle dragged, don't toggle
    setMainVisible(not mainVisible)
end)
closeBtn.MouseButton1Click:Connect(function() setMainVisible(false) end)

-- ══════════════════════════════════════════════
-- BOOT: auto scan and show toggle
-- ══════════════════════════════════════════════
task.delay(0.5,function()
    if type(listfiles)=="function" then
        task.spawn(function()
            allScannedFiles=scanAllSupported()
            local rm,rmx,rl,rlx=countByType(allScannedFiles)
            lastFileCounts={rbxm=rm,rbxmx=rmx,rbxl=rl,rbxlx=rlx}
            updateDashStats()
        end)
    end
    -- show toggle
    toggleBtn.Visible=true
end)

-- init view
switchView("dashboard")

print("[ENGINE STUDIO FOR MOBILE] Loaded — toggle ID 92844638469747")
