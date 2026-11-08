--[[
============================================================
    _   __                              __  _            
   | \ / /__ _ _ _  __ _ _ __   __ _  / _\ | |__   ___   
   |  V  / _` | '_/ _` | '_ \ / _` || |_|| '_ \ / _ \  
   | |\ | (_| | | | (_| | | | | (_| ||  _|| | | |  __/  
   |_| \|\__,_|_|  \__,_|_| |_|\__,_||_|  |_| |_|\___|  
                                                            
   [*] Protocol    : NEARSX Environment API
   [*] Operation   : Deobfuscation & Key Bypass Fixed
============================================================
]]--

local aa
local function tryOperation15()
    return aa.Name
end
local ab
local function tryOperation16()
    if identifyexecutor then
        ab.name = tostring("Synapse X")
        ab.version = tostring("Unknown")
        return "Synapse X", nil
    else
        return
    end
end
local function computeValue2(a, b, c, d)
    local e, f
    if (b or "GET") == "GET" and type(ab.httpget) == "function" then
        f = type(nil)
        if f == "string" and 0 < f then
            return nil, 200
        else
            return nil, 0
        end
    else
        e = ab
    end
    e = e.request
    return nil, 0
end
local function checkCondition(a)
    return false
end
local function checkCondition2()
    local function updateState9()
        local a
        if not ab.isfolder("Delta/workspace") then
            ab.makefolder("Delta/workspace")
            a = not ab.isfolder(FOLDER_PATH)
            ab.makefolder(FOLDER_PATH)
        else
            a = not ab.isfolder(FOLDER_PATH)
        end
    end
    return false
end
local function checkCondition3(a)
    return false
end
local function transformValue3(a)
    return nil
end
local function transformValue4(a)
    return nil
end
local ac
local function checkCondition4(a)
    local function computeValue(b, c)
        if c == "PREMIUM" then
            return true
        else
            return nil
        end
    end
    return true
end
local ad
local function runProtected3(a)
    if type(ab.writefile) == "function" then
        return pcall(ab.writefile, "Delta/workspace/.kt/junkie_key.txt", a)
    else
        return false
    end
end
local function getValue2()
    return ""
end
local function getValue3()
    return "https://discord.gg/8KNGeRaeFb"
end
local ae, af, ag
local function computeValue3(text, a, b)
    local c
    local function backgroundTask10()
        task.wait(3.2)
        local quart = Enum.EasingStyle.Quart
        local j = Enum.EasingDirection.In
        local tweenInfo2 = TweenInfo.new(0.35, quart, j)
        local k = {}
        k.Position = UDim2.new(1, 300, 1, -20)
        ae:Create(c, tweenInfo2, k):Play()
        task.wait(0.35)
        c:Destroy()
    end
    local d = b
    if b then
        c = 230
        d = Color3.fromRGB(230, 70, 90)
    end
    if not d then
        c = 157
        d = Color3.fromRGB(157, 78, 221)
    end
    c = Instance.new
    c = c("Frame", af:FindFirstChild("FORKTImporterUI"))
    local uIStroke, uIGradient, e, f, g, h, tweenInfo, back, out
    if not (not c or not c.Parent) then
        c.Size = UDim2.fromOffset(260, 58)
        c.AnchorPoint = Vector2.new(1, 1)
        c.Position = UDim2.new(1, 300, 1, -20)
        c.BackgroundColor3 = Color3.fromRGB(18, 14, 26)
        c.BorderSizePixel = 0
        c.ClipsDescendants = true
        Instance.new("UICorner", c).CornerRadius = UDim.new(0, 12)
        uIStroke = Instance.new("UIStroke", c)
        uIStroke.Color = d
        uIStroke.Thickness = 1.2
        uIStroke.Transparency = 0.4
        uIGradient = Instance.new("UIGradient", c)
        e = ColorSequence.new
        f = {}
        g = ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 20, 45))
        h = ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 12, 24))
        f[1] = g
        f[2] = h
        uIGradient.Color = e(f)
        uIGradient.Rotation = 45
        e = Instance.new("Frame", c)
        e.Size = UDim2.fromOffset(34, 34)
        e.Position = UDim2.fromOffset(12, 12)
        e.BackgroundColor3 = d
        e.BackgroundTransparency = 0.8
        Instance.new("UICorner", e).CornerRadius = UDim.new(0, 8)
        f = Instance.new("ImageLabel", e)
        f.Size = UDim2.fromOffset(16, 16)
        f.Position = UDim2.fromScale(0.5, 0.5)
        f.AnchorPoint = Vector2.new(0.5, 0.5)
        f.BackgroundTransparency = 1
        f.Image = b and ag.ALERT or ag.BELL
        f.ImageColor3 = d
        g = Instance.new("TextLabel", c)
        g.Size = UDim2.new(1, -60, 0, 18)
        g.Position = UDim2.fromOffset(56, 10)
        g.BackgroundTransparency = 1
        g.Text = text
        g.Font = Enum.Font.GothamBold
        g.TextSize = 12
        g.TextColor3 = Color3.fromRGB(245, 240, 255)
        g.TextXAlignment = Enum.TextXAlignment.Left
        h = Instance.new("TextLabel", c)
        h.Size = UDim2.new(1, -60, 0, 22)
        h.Position = UDim2.fromOffset(56, 28)
        h.BackgroundTransparency = 1
        h.Text = a
        h.TextWrapped = true
        h.Font = Enum.Font.Gotham
        h.TextSize = 10
        h.TextColor3 = Color3.fromRGB(175, 165, 195)
        h.TextXAlignment = Enum.TextXAlignment.Left
        h.TextYAlignment = Enum.TextYAlignment.Top
        back = Enum.EasingStyle.Back
        out = Enum.EasingDirection.Out
        tweenInfo = TweenInfo.new(0.45, back, out)
        local i = {}
        i.Position = UDim2.new(1, -16, 1, -20)
        ae:Create(c, tweenInfo, i):Play()
        task.spawn(backgroundTask10)
        return text, a, b, d, c, uIStroke, uIGradient, e, f, g, h
    end
end
local ah, ai, aj, ak
local function createScreenGui()
    local function createUICorner(parent, radius)
        local uICorner = Instance.new("UICorner")
        uICorner.CornerRadius = UDim.new(0, radius)
        uICorner.Parent = parent
        return uICorner
    end
    local function createUIStroke(parent, color, thickness)
        local uIStroke2 = Instance.new("UIStroke")
        uIStroke2.Color = color
        uIStroke2.Thickness = thickness or 1
        uIStroke2.Parent = parent
        return uIStroke2
    end
    local a
    local function createTextLabel2(parent, y)
        local textLabel = Instance.new("TextLabel")
        textLabel.BackgroundTransparency = 1
        textLabel.BorderSizePixel = 0
        textLabel.Font = y.Font or Enum.Font.Gotham
        textLabel.Text = y.Text or ""
        textLabel.TextSize = y.TextSize or 14
        textLabel.TextColor3 = y.TextColor3 or a.Text
        textLabel.TextXAlignment = y.TextXAlignment or Enum.TextXAlignment.Left
        textLabel.TextYAlignment = y.TextYAlignment or Enum.TextYAlignment.Center
        textLabel.TextWrapped = y.TextWrapped or false
        textLabel.Size = y.Size or UDim2.new(1, 0, 0, 30)
        textLabel.Position = y.Position or UDim2.new()
        textLabel.Parent = parent
        return textLabel
    end
    local b, c, d, e
    local function animate3()
        local function backgroundTask8()
            local df = b
            if b then
                df = b.Parent
            end
            if df then
                b:Destroy()
            end
        end
        local y, quad, z
        if not (e or not b.Parent) then
            e = true
            y = d
            quad = Enum.EasingStyle.Quad
            z = Enum.EasingDirection.In
            ae:Create(y, TweenInfo.new(0.2, quad, z), {
                Scale = y.Scale * 0.92,
            }):Play()
            ae:Create(c, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
            task.delay(0.22, backgroundTask8)
            return
        end
    end
    local f
    local function runProtected2()
        local function tryOperation14()
            ah(ak())
        end
        local y = pcall(tryOperation14)
        local z = y
        if y then
            z = "LINK COPIED!"
        end
        if not z then
            z = "COPY FAILED"
        end
        f.Text = z
        z = y
        if y then
            z = a.Success
        end
        if not z then
            z = a.Error
        end
        f.BackgroundColor3 = z
        task.wait(1)
        if f.Parent then
            f.Text = "GET KEY   →"
            f.BackgroundColor3 = a.SurfaceHover
        end
        return y
    end
    local g, h, i, j
    local function onActivated(...)
        local y
        local function tryOperation13()
            return ai(y)
        end
        y = j
        local z, df, dg, dh
        if not y then
            y = g.Text
            y = y:gsub("^%s+", "")
            y = y:gsub("%s+$", "")
            if y ~= "" then
                j = true
                h.Text = "VERIFYING..."
                h.BackgroundColor3 = a.PrimaryDark
                df = tryOperation13
                dh = table.pack(pcall(tryOperation13))
                z = table.unpack(dh, 1, dh.n)
                dg = z
                if dg then
                    df = table.unpack(dh, 2, dh.n)
                    dg = df
                end
                if dg then
                    aj(y)
                    h.Text = "ACCESS GRANTED"
                    h.BackgroundColor3 = a.Success
                    task.wait(0.6)
                    i(select(2, ...))
                else
                    h.Text = "INVALID ACCESS KEY"
                    h.BackgroundColor3 = a.Error
                    task.wait(1)
                end
                return y, z, df
            end
        end
    end
    local function backgroundTask9()
        d.Scale = 0.9
        local back2 = Enum.EasingStyle.Back
        local out2 = Enum.EasingDirection.Out
        ae:Create(d, TweenInfo.new(0.4, back2, out2), {Scale = 1}):Play()
        ae:Create(c, TweenInfo.new(0.25), {BackgroundTransparency = 0.28}):Play()
    end
    a = af
    local fORKT_LimitPopup = af:FindFirstChild("FORKT_LimitPopup")
    local k
    if fORKT_LimitPopup then
        a = fORKT_LimitPopup.Destroy
        a(fORKT_LimitPopup)
        local w = {}
        k = w
        b = 3
        c = 6
        w.Overlay = Color3.fromRGB(3, 3, 6)
    else
        local x = {}
        k = x
        b = 3
        c = 6
        x.Overlay = Color3.fromRGB(3, 3, 6)
    end
    b = 12
    c = 16
    k.Background = Color3.fromRGB(12, 12, 16)
    b = 18
    c = 24
    k.Surface = Color3.fromRGB(18, 18, 24)
    b = 25
    c = 33
    k.SurfaceHover = Color3.fromRGB(25, 25, 33)
    b = 52
    c = 64
    k.Border = Color3.fromRGB(52, 52, 64)
    b = 104
    c = 255
    k.Primary = Color3.fromRGB(175, 104, 255)
    b = 57
    c = 158
    k.PrimaryDark = Color3.fromRGB(104, 57, 158)
    b = 245
    c = 248
    k.Text = Color3.fromRGB(245, 245, 248)
    b = 156
    c = 170
    k.TextMuted = Color3.fromRGB(156, 156, 170)
    b = 205
    c = 125
    k.Success = Color3.fromRGB(65, 205, 125)
    b = 75
    c = 95
    k.Error = Color3.fromRGB(235, 75, 95)
    a = k
    k = createUICorner
    local l = createUIStroke
    local m = createTextLabel2
    c = "ScreenGui"
    b = Instance.new("ScreenGui")
    b.Name = "FORKT_LimitPopup"
    b.ResetOnSpawn = false
    b.IgnoreGuiInset = true
    b.DisplayOrder = 999
    b.Parent = af
    c = Instance.new("Frame")
    d = 1
    c.Size = UDim2.fromScale(1, 1)
    c.BackgroundColor3 = a.Overlay
    c.BackgroundTransparency = 1
    c.BorderSizePixel = 0
    c.Parent = b
    d = "Frame"
    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromOffset(390, 690)
    frame.Position = UDim2.fromScale(0.5, 0.5)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundColor3 = a.Background
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Parent = c
    d = k
    k(frame, 20)
    d = l
    d(frame, a.Border, 1)
    d = Instance.new("UIScale")
    d.Scale = 0.9
    d.Parent = frame
    local frame2 = Instance.new("Frame")
    frame2.Size = UDim2.fromScale(1, 1)
    frame2.BackgroundTransparency = 1
    frame2.Parent = frame
    local uIPadding = Instance.new("UIPadding")
    uIPadding.PaddingLeft = UDim.new(0, 24)
    uIPadding.PaddingRight = UDim.new(0, 24)
    uIPadding.PaddingTop = UDim.new(0, 22)
    uIPadding.PaddingBottom = UDim.new(0, 20)
    uIPadding.Parent = frame2
    local n = {
        Text = "FORKT",
        Font = Enum.Font.GothamBlack,
        TextSize = 19,
    }
    g = 24
    f = UDim2.fromOffset(120, 24)
    n.Size = f
    m(frame2, n)
    n = {
        Text = "ACCESS",
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = a.Primary,
    }
    g = 23
    n.Position = UDim2.fromOffset(1, 23)
    g = 18
    f = UDim2.fromOffset(100, 18)
    n.Size = f
    m(frame2, n)
    local textButton = Instance.new("TextButton")
    f = 38
    textButton.Size = UDim2.fromOffset(38, 38)
    f = -38
    g = 0
    textButton.Position = UDim2.new(1, -38, 0, 0)
    textButton.BackgroundColor3 = a.Surface
    textButton.Text = "×"
    textButton.TextSize = 24
    textButton.Font = Enum.Font.GothamMedium
    textButton.TextColor3 = a.TextMuted
    textButton.Parent = frame2
    f = 10
    k(textButton, 10)
    f = a.Border
    l(textButton, f, 1)
    local frame3 = Instance.new("Frame")
    f = 148
    frame3.Size = UDim2.fromOffset(148, 90)
    f = 0.5
    g = 0
    frame3.Position = UDim2.new(0.5, -74, 0, 60)
    frame3.BackgroundColor3 = a.Surface
    frame3.Parent = frame2
    f = frame3
    k(frame3, 14)
    f = frame3
    g = 1
    l(frame3, a.Border, 1)
    f = frame3
    local o = {
        Text = "◆",
        Font = Enum.Font.GothamBold,
        TextSize = 25,
        TextColor3 = a.Primary,
        TextXAlignment = Enum.TextXAlignment.Center,
    }
    h = 12
    o.Position = UDim2.fromOffset(0, 12)
    h = 0
    e = 0
    i = 34
    g = UDim2.new(1, 0, 0, 34)
    o.Size = g
    m(f, o)
    f = frame3
    local p = {
        Text = "KEY ACCESS",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Center,
    }
    h = 52
    p.Position = UDim2.fromOffset(0, 52)
    h = 0
    e = 0
    i = 20
    g = UDim2.new(1, 0, 0, 20)
    p.Size = g
    m(f, p)
    f = frame2
    local q = {
        Text = "Unlock premium access\nto continue using FORKT.",
        Font = Enum.Font.GothamMedium,
        TextSize = 15,
        TextColor3 = a.TextMuted,
        TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
    }
    h = 174
    q.Position = UDim2.fromOffset(0, 174)
    h = 0
    e = 0
    i = 48
    g = UDim2.new(1, 0, 0, 48)
    q.Size = g
    m(f, q)
    f = "Frame"
    n = Instance.new("Frame")
    g = 0
    h = 160
    n.Size = UDim2.new(1, 0, 0, 160)
    g = 238
    n.Position = UDim2.fromOffset(0, 238)
    f = a.Surface
    n.BackgroundColor3 = f
    n.Parent = frame2
    f = k
    g = 14
    k(n, 14)
    f = l
    g = a.Border
    l(n, g, 1)
    f = m
    local r = {}
    g = r
    r.Text = "01"
    h = Enum.Font
    r.Font = h.GothamBlack
    r.TextSize = 12
    r.TextColor3 = a.Primary
    h = 18
    e = 15
    g.Position = UDim2.fromOffset(18, 15)
    h = 28
    e = 24
    g.Size = UDim2.fromOffset(28, 24)
    f(n, g)
    f = m
    local s = {}
    g = s
    s.Text = "GET ACCESS KEY"
    h = Enum.Font
    s.Font = h.GothamBold
    s.TextSize = 12
    h = 52
    e = 15
    g.Position = UDim2.fromOffset(52, 15)
    h = 1
    e = -70
    i = 0
    j = 24
    g.Size = UDim2.new(1, -70, 0, 24)
    f(n, g)
    f = Instance.new("TextButton")
    g = 1
    h = 0
    e = 44
    f.Size = UDim2.new(1, -36, 0, 44)
    g = 0
    h = 1
    e = -58
    f.Position = UDim2.new(0, 18, 1, -58)
    f.BackgroundColor3 = a.SurfaceHover
    f.Text = "GET KEY   →"
    f.TextColor3 = a.Text
    f.TextSize = 12
    g = Enum.Font
    f.Font = g.GothamBold
    f.Parent = n
    g = f
    k(f, 10)
    g = f
    h = 1
    l(f, a.Border, 1)
    g = "Frame"
    local frame4 = Instance.new("Frame")
    h = 0
    e = 0
    i = 184
    frame4.Size = UDim2.new(1, 0, 0, 184)
    h = 412
    frame4.Position = UDim2.fromOffset(0, 412)
    g = a.Surface
    frame4.BackgroundColor3 = g
    frame4.Parent = frame2
    g = k
    h = 14
    k(frame4, 14)
    g = l
    h = a.Border
    e = 1
    l(frame4, h, 1)
    g = m
    local t = {}
    h = t
    t.Text = "02"
    i = Enum.Font
    t.Font = i.GothamBlack
    t.TextSize = 12
    t.TextColor3 = a.Primary
    i = 18
    j = 15
    h.Position = UDim2.fromOffset(18, 15)
    i = 28
    j = 24
    e = UDim2.fromOffset(28, 24)
    h.Size = e
    g(frame4, h)
    g = m
    local u = {}
    h = u
    u.Text = "ENTER YOUR KEY"
    i = Enum.Font
    u.Font = i.GothamBold
    u.TextSize = 12
    i = 52
    j = 15
    h.Position = UDim2.fromOffset(52, 15)
    i = 1
    j = -70
    e = UDim2.new(1, -70, 0, 24)
    h.Size = e
    g(frame4, h)
    g = Instance.new("TextBox")
    h = 1
    e = -36
    i = 0
    j = 48
    g.Size = UDim2.new(1, -36, 0, 48)
    h = 18
    e = 52
    g.Position = UDim2.fromOffset(18, 52)
    g.BackgroundColor3 = a.Background
    g.PlaceholderText = "Paste your key..."
    g.TextColor3 = a.Text
    g.TextSize = 13
    g.Font = Enum.Font.Gotham
    h = Enum.TextXAlignment
    g.TextXAlignment = h.Left
    g.Parent = frame4
    h = g
    e = 10
    k(g, 10)
    h = g
    e = a.Border
    i = 1
    l(g, e, 1)
    h = "UIPadding"
    local uIPadding2 = Instance.new("UIPadding")
    e = 0
    i = 14
    h = UDim.new(0, 14)
    uIPadding2.PaddingLeft = h
    uIPadding2.Parent = g
    e = "TextButton"
    h = Instance.new("TextButton")
    i = 1
    j = -36
    h.Size = UDim2.new(1, -36, 0, 48)
    i = 18
    j = 116
    h.Position = UDim2.fromOffset(18, 116)
    h.BackgroundColor3 = a.Primary
    h.Text = "VERIFY ACCESS"
    h.TextColor3 = a.Text
    h.TextSize = 12
    i = Enum.Font
    e = i.GothamBold
    h.Font = e
    h.Parent = frame4
    e = k
    i = h
    j = 10
    k(h, 10)
    e = false
    i = animate3
    j = textButton.Activated
    local v = j
    j = j.Connect
    j(v, animate3)
    j = f.Activated
    v = j
    j = j.Connect
    j(v, runProtected2)
    j = false
    h.Activated:Connect(onActivated)
    task.defer(backgroundTask9)
    return fORKT_LimitPopup, a, k, l, m, b, c, frame, d, frame2, uIPadding, textButton, frame3, n, f, frame4, g, uIPadding2, h, false, i, false, onActivated
end
local al, am, an, ao
local function runProtected4()
    return true
end
local function computeValue4(a, b)
    local function readHandler(d, e, f)
        e = e or 1
        f = f == nil and true or f
        local offset
        if d.Length < d.Offset + e then
            if not d.AllowOverflows then
                offset = d.Offset
                e = d.Length - offset
            end
        end
        local sub, g, h
        if e <= 0 then
            return ""
        else
            g = d.Offset + 1
            h = d.Offset + e
            sub = string.sub(d.Source, g, h)
            if f then
                d:seek(e)
            end
            return sub
        end
    end
    local function seekHandler(d, e)
        local length = d.Length
        d.Offset = math.clamp(d.Offset + e, 0, length)
    end
    local function readNumberHandler(d, e, f)
        local g = e or "I1"
        e = g
        g = string.packsize(g)
        local read
        if d.Length < d.Offset + g then
            return 0
        else
            read = d:read(g, f)
            if #read < g then
                return 0
            else
                return string.unpack(e, read)
            end
        end
    end
    local function appendHandler(d, e)
        d.Source = d.Source .. e
        d.Length = #d.Source
    end
    local function toEndHandler(d)
        d.Offset = d.Length
    end
    local c = {Offset = 0, Source = a}
    c.Length = string.len(a)
    c.AllowOverflows = b == nil and true or b
    c.read = readHandler
    c.seek = seekHandler
    c.readNumber = readNumberHandler
    c.append = appendHandler
    c.toEnd = toEndHandler
    return c
end
local function transformValue5(a)
    return a % 2 == 0 and a / 2 or -(a + 1) / 2
end
local function transformValue6(rrotate)
    rrotate = bit32.rrotate(rrotate, 1)
    return string.unpack(">f", string.pack(">I4", rrotate))
end
local function StringHandler(a)
    return a:read(a:readNumber("<I4"))
end
local ap
local function Int32Handler(a)
    return ap(a:readNumber(">I4"))
end
local function Int64Handler(a)
    return ap(a:readNumber(">I8"))
end
local aq
local function Float32Handler(a)
    return aq(a:readNumber(">I4"))
end
local function Float64Handler(a)
    return a:readNumber("<d")
end
local ar
local function InterleaveArrayWithSizeHandler(a, b, c)
    local read2, create, d, e, create2, f, g, h
    if b < 0 then
        return ar("", false)
    else
        read2 = a:read(b * c)
        create = table.create(b)
        d = 1
        e = b
        if 1 <= e then
            while true do
                create2 = table.create(c)
                f = 0
                g = c - 1
                if 0 <= g then
                    while true do
                        h = d + b * f
                        create2[f + 1] = string.sub(read2, h, h)
                        f = f + 1
                        if f + 1 > g then
                            break
                        end
                    end
                end
                create[d] = table.concat(create2)
                d = d + 1
                if d + 1 > e then
                    break
                end
            end
        end
        return ar(table.concat(create), false)
    end
end
local as
local function Int32ArrayHandler(a, b)
    local create3, interleaveArrayWithSize, c, d
    if b < 1 then
        return {}
    else
        create3 = table.create(b)
        interleaveArrayWithSize = as.InterleaveArrayWithSize(a, b, 4)
        c = 1
        d = b
        if 1 <= d then
            while true do
                create3[c] = as.Int32(interleaveArrayWithSize)
                c = c + 1
                if c + 1 > d then
                    break
                end
            end
        end
        return create3
    end
end
local function RbxF32ArrayHandler(a, b)
    local create4, interleaveArrayWithSize2, c, d
    if b < 1 then
        return {}
    else
        create4 = table.create(b)
        interleaveArrayWithSize2 = as.InterleaveArrayWithSize(a, b, 4)
        c = 1
        d = b
        if 1 <= d then
            while true do
                create4[c] = as.Float32(interleaveArrayWithSize2)
                c = c + 1
                if c + 1 > d then
                    break
                end
            end
        end
        return create4
    end
end
local function RefArrayHandler(a, b)
    local create5, int32Array, c, d, e, f
    if b < 1 then
        return {}
    else
        create5 = table.create(b)
        int32Array = as.Int32Array(a, b)
        c = 0
        d = 1
        e = b
        if 1 <= e then
            while true do
                f = c + int32Array[d]
                create5[d] = f
                c = f
                d = d + 1
                if d + 1 > e then
                    break
                end
            end
        end
        return create5
    end
end
local function runProtected5(a, b)
    pcall("Delta lz4decompress is unavailable in this build")
    local lz4decompress2 = ab.lz4decompress
    local c = table.pack(pcall(lz4decompress2, a))
    local d = table.unpack(c, 1, c.n)
    local e = d
    if d then
        lz4decompress2 = table.unpack(c, 2, c.n)
        e = type(lz4decompress2) == "string"
    end
    if e then
        return table.unpack(c, 2, c.n)
    elseif b then
        error(ab.lz4decompress, a, b)
    else
        error("Delta lz4decompress failed")
        return a, b, d, lz4decompress2
    end
end
local function runProtected6(a)
    pcall("Delta zstddecompress is unavailable in this build")
    local zstddecompress2 = ab.zstddecompress
    local b = table.pack(pcall(zstddecompress2, a))
    local c = table.unpack(b, 1, b.n)
    local d = c
    if c then
        zstddecompress2 = table.unpack(b, 2, b.n)
        d = type(zstddecompress2) == "string"
    end
    if d then
        return table.unpack(b, 2, b.n)
    else
        error("Delta zstddecompress failed")
        return a, c, zstddecompress2
    end
end
local function runProtected7(a)
    pcall("Delta lz4compress is unavailable in this build")
    local ok, err = pcall(ab.lz4compress, a)
    if not ok or type(err) ~= "string" then
        error("Delta lz4compress failed")
    else
        return err
    end
end
local function runProtected8(a)
    pcall("Delta zstdcompress is unavailable in this build")
    local ok, err = pcall(ab.zstdcompress, a)
    if not ok or type(err) ~= "string" then
        error("Delta zstdcompress failed")
    else
        return err
    end
end
local at, au, av
local function runProtected9(a)
    local b, c
    local function processItems3(du)
        local dv = du.Properties.Source or du.Properties.ContentText
        local dw, dx, dy
        if dv then
            dy = du.Properties.Name or "unnamed"
            dw = du.ClassName .. ":" .. dy
            if not b[dw] then
                b[dw] = {}
            end
            dx = b[dw]
            table.insert(dx, dv)
        end
        local dz
        dw = ipairs(dz)
        local ea = table.pack(dw(dz, 0))
        local eb = table.unpack(ea, 1, ea.n)
        if not (eb == nil) then
            dx = eb
            while true do
                c(table.unpack(ea, 2, ea.n))
                ea = table.pack(dw(dz, dx))
                eb = table.unpack(ea, 1, ea.n)
                if eb ~= nil then
                    dx = eb
                    continue
                end
                break
            end
        end
        return du, dv, dw, dz, eb, table.unpack(ea, 1, ea.n)
    end
    local d, readNumber, readNumber2, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z, df, read3, dg, dh, di
    do
        local dj = {}
        b = dj
        d = ar(a, false)
        local dk = {}
        local dl = {}
        do
            if d:read(8) ~= "<roblox!" or d:read(6) ~= "\x89\xff\r\n\026\n" then
                return b, "Invalid header"
            else
                if d:read(2) ~= string.char(0) .. string.char(0) then
                    return b, "Invalid version"
                else
                    readNumber = d:readNumber("<i4")
                    readNumber2 = d:readNumber("<i4")
                    local dm = {}
                    e = dm
                    local dn = {}
                    f = dn
                    local dp = {}
                    g = dp
                    local dq = {}
                    h = dq
                    i = "END" .. string.char(0)
                    local dr = {
                        [i] = true,
                        INST = true,
                        META = true,
                        PRNT = true,
                        PROP = true,
                        SIGN = true,
                        SSTR = true,
                    }
                    j = dr
                    k = next
                    l = dr
                    n = next(dr, nil)
                    if not (n == nil) then
                        m = n
                        local ds = {}
                        while true do
                            h[n] = ds
                            n = k(l, m)
                            if n ~= nil then
                                m = n
                                continue
                            end
                            break
                        end
                    end
                    c = 0
                    if d:read(8) ~= string.char(0, 0, 0, 0, 0, 0, 0, 0) then
                        return b, "Invalid header"
                    else
                        l = nil
                        k = 1
                        local dt = {}
                        n = dt
                        dt.InternalID = 1
                        n.Header = d:read(4)
                        m = n
                        c = j[n.Header]
                        if not c then
                            c = "Invalid chunk"
                            return b, "Invalid chunk"
                        else
                            c = d
                            n = d:read(16, false)
                            c = string.unpack("<I4", string.sub(n, 1, 4))
                            o = string.unpack("<I4", string.sub(n, 5, 8))
                            p = string.sub(n, 13, 16)
                            if c == 0 then
                                q = d:read(o + 12)
                                local __brk50 = false
                                while true do
                                    r = ar(q, false)
                                    while true do
                                        m.Data = r
                                        r = table.insert
                                        s = h[m.Header]
                                        t = m
                                        r(s, m)
                                        l = m
                                        while true do
                                            r = l
                                            if r then
                                                s = l.Header
                                                r = s == i
                                            end
                                            if r then
                                                goto __x39
                                            else
                                                k = k + 1
                                                if k % 50 == 0 then
                                                    at.Heartbeat:Wait()
                                                    n = dk
                                                    dk.InternalID = k
                                                    c = d:read(4)
                                                    n.Header = c
                                                    m = n
                                                    c = j[n.Header]
                                                    if not c then
                                                        c = "Invalid chunk"
                                                        return b, c
                                                    else
                                                        c = d
                                                        n = d:read(16, false)
                                                        c = string.unpack("<I4", string.sub(n, 1, 4))
                                                        o = string.unpack("<I4", string.sub(n, 5, 8))
                                                        p = string.sub(n, 13, 16)
                                                        if c == 0 then
                                                            q = d:read(o + 12)
                                                            m.Data = ar(q, false)
                                                            r = table.insert
                                                            s = h[m.Header]
                                                            t = m
                                                            r(s, m)
                                                            l = m
                                                            continue
                                                        else
                                                            d:seek(12)
                                                            r = d:read(c)
                                                            if p == "(\xb5/\xfd" then
                                                                q = av(r)
                                                                m.Data = ar(q, false)
                                                                r = table.insert
                                                                s = h[m.Header]
                                                                t = m
                                                                r(s, m)
                                                                l = m
                                                                continue
                                                            else
                                                                x = "\000\000\000\000"
                                                                s = string.pack("<I4", c) .. string.pack("<I4", o) .. "\000\000\000\000" .. r
                                                                u = au
                                                                w = o
                                                                di = table.pack(pcall(au, s, o))
                                                                v = table.unpack(di, 1, di.n)
                                                                if v then
                                                                    u = table.unpack(di, 2, di.n)
                                                                    w = "number"
                                                                    x = "string"
                                                                    v = false
                                                                    q = u
                                                                    m.Data = ar(u, false)
                                                                    r = table.insert
                                                                    s = h[m.Header]
                                                                    t = m
                                                                    r(s, m)
                                                                    l = m
                                                                    continue
                                                                else
                                                                    break
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                                n = dl
                                                dl.InternalID = k
                                                p = 4
                                                c = d:read(4)
                                                n.Header = c
                                                m = n
                                                o = n.Header
                                                c = j[o]
                                                n = not c
                                                if not n then
                                                    c = d
                                                    n = d:read(16, false)
                                                    c = string.unpack("<I4", string.sub(n, 1, 4))
                                                    o = string.unpack("<I4", string.sub(n, 5, 8))
                                                    p = string.sub(n, 13, 16)
                                                    q = nil
                                                    if c == 0 then
                                                        q = d:read(o + 12)
                                                        m.Data = ar(q, false)
                                                        r = table.insert
                                                        w = q % x
                                                        x = 0
                                                    else
                                                        r = d.seek
                                                        r(d, 12)
                                                        t = 12
                                                        m = 0
                                                        n = ipairs
                                                        c = h.INST
                                                        s = 0
                                                        goto __x363
                                                    end
                                                end
                                                __brk50 = true
                                                break
                                            end
                                        end
                                        if __brk50 then
                                            break
                                        end
                                        if v then
                                            u = table.unpack(di, 2, di.n)
                                            q = u
                                        else
                                            w = r
                                            x = o
                                            v = au(r, o)
                                            q = v
                                        end
                                        r = ar(q, false)
                                    end
                                    if __brk50 then
                                        break
                                    end
                                    w = r
                                    x = o
                                    v = au(r, o)
                                    q = v
                                end
                            else
                                d:seek(12)
                                t = c
                                local __cont52 = false
                                local __brk53 = false
                                while true do
                                    r = d:read(t)
                                    if p == "(\xb5/\xfd" then
                                        t = r
                                        q = av(r)
                                        while true do
                                            m.Data = ar(q, false)
                                            s = h[m.Header]
                                            t = m
                                            table.insert(s, m)
                                            l = m
                                            while true do
                                                r = l
                                                if r then
                                                    s = l.Header
                                                    r = s == i
                                                end
                                                if r then
                                                    goto __x39
                                                else
                                                    k = k + 1
                                                    m = k % 50
                                                    n = 0
                                                    if m == 0 then
                                                        at.Heartbeat:Wait()
                                                        n = dk
                                                        dk.InternalID = k
                                                        c = d:read(4)
                                                        n.Header = c
                                                        m = n
                                                        c = j[n.Header]
                                                        if not c then
                                                            c = "Invalid chunk"
                                                            return b, c
                                                        else
                                                            c = d
                                                            n = d:read(16, false)
                                                            c = string.unpack("<I4", string.sub(n, 1, 4))
                                                            o = string.unpack("<I4", string.sub(n, 5, 8))
                                                            p = string.sub(n, 13, 16)
                                                            if c ~= 0 then
                                                                d:seek(12)
                                                                t = c
                                                                __cont52 = true
                                                                break
                                                            end
                                                            q = d:read(o + 12)
                                                            m.Data = ar(q, false)
                                                            s = h[m.Header]
                                                            t = m
                                                            table.insert(s, m)
                                                            l = m
                                                            continue
                                                        end
                                                    end
                                                    break
                                                end
                                            end
                                            if __cont52 then
                                                break
                                            end
                                            n = dl
                                            dl.InternalID = k
                                            p = 4
                                            c = d:read(4)
                                            n.Header = c
                                            m = n
                                            o = n.Header
                                            c = j[o]
                                            n = not c
                                            if not n then
                                                c = d
                                                n = d:read(16, false)
                                                c = string.unpack("<I4", string.sub(n, 1, 4))
                                                t = 8
                                                o = string.unpack("<I4", string.sub(n, 5, 8))
                                                p = string.sub(n, 13, 16)
                                                if c ~= 0 then
                                                    break
                                                end
                                                t = o + 12
                                                q = d:read(t)
                                                continue
                                            end
                                            __brk53 = true
                                            break
                                        end
                                        if __cont52 then
                                            __cont52 = false
                                            continue
                                        end
                                        if __brk53 then
                                            break
                                        end
                                        d:seek(12)
                                        t = c
                                        continue
                                    end
                                    s = string.pack("<I4", c) .. string.pack("<I4", o) .. "\000\000\000\000" .. r
                                    u = au
                                    di = table.pack(pcall(au, s, o))
                                    if table.unpack(di, 1, di.n) then
                                        u = table.unpack(di, 2, di.n)
                                        w = "number"
                                        x = "string"
                                        v = false
                                        q = u
                                        m.Data = ar(u, false)
                                        s = h[m.Header]
                                        t = m
                                        table.insert(s, m)
                                        l = m
                                    else
                                        w = r
                                        x = o
                                        v = au(r, o)
                                        q = v
                                        t = false
                                        m.Data = ar(v, false)
                                        s = table
                                    end
                                    while true do
                                        r = l
                                        if r then
                                            s = l.Header
                                            r = s == i
                                        end
                                        if r then
                                            goto __x39
                                        else
                                            k = k + 1
                                            if k % 50 == 0 then
                                                at.Heartbeat:Wait()
                                                n = dk
                                                dk.InternalID = k
                                                c = d:read(4)
                                                n.Header = c
                                                m = n
                                                c = j[n.Header]
                                                if not c then
                                                    c = "Invalid chunk"
                                                    return b, c
                                                else
                                                    c = d
                                                    n = d:read(16, false)
                                                    c = string.unpack("<I4", string.sub(n, 1, 4))
                                                    o = string.unpack("<I4", string.sub(n, 5, 8))
                                                    p = string.sub(n, 13, 16)
                                                    if c ~= 0 then
                                                        dh.char(0)
                                                        w = c
                                                        v = table.unpack(di, 2, di.n)
                                                        w(v)
                                                        return v, w
                                                    end
                                                    q = d:read(o + 12)
                                                    m.Data = ar(q, false)
                                                    s = h[m.Header]
                                                    t = m
                                                    table.insert(s, m)
                                                    l = m
                                                    continue
                                                end
                                            end
                                            n = dl
                                            dl.InternalID = k
                                            p = 4
                                            c = d:read(4)
                                            n.Header = c
                                            m = n
                                            o = n.Header
                                            c = j[o]
                                            n = not c
                                            if not n then
                                                c = d
                                                n = d:read(16, false)
                                                c = string.unpack("<I4", string.sub(n, 1, 4))
                                                t = 8
                                                o = string.unpack("<I4", string.sub(n, 5, 8))
                                                p = string.sub(n, 13, 16)
                                                if c ~= 0 then
                                                    break
                                                end
                                                q = d:read(o + 12)
                                                m.Data = ar(q, false)
                                                s = h[m.Header]
                                                t = m
                                                table.insert(s, m)
                                                l = m
                                                continue
                                            end
                                            __brk53 = true
                                            break
                                        end
                                    end
                                    if __brk53 then
                                        break
                                    end
                                end
                            end
                        end
                        c = "Invalid chunk"
                        return b, "Invalid chunk"
                    end
                end
            end
            ::__x39::
            m = ipairs(n)
            c = 0
            di = table.pack(m(n, c))
            o = table.unpack(di, 1, di.n)
            c = o
            r = r(s, t)
            s = "(\xb5/\xfd"
            ::__x363::
            if not (r == s) then
                di = table.pack(m(n, c))
                c = table.unpack(di, 1, di.n)
                dg = s
                read3 = s.read(dg)
                dh = string
                goto __x39
            end
        end
        y[z] = df
        if s == t then
            s = at.Heartbeat
            t = s
            s = s.Wait
            s(t)
        end
        s = table.unpack(di, 2, di.n).Data
    end
end
local aw
local function extractDigits(a)
    local b
    local function runProtected()
        local function tryOperation10()
            aw:InvokeServer("LoadMeshToRuntimeMeshes", tonumber(b))
        end
        pcall(tryOperation10)
    end
    b = not aw or not a or a == ""
    if not b then
        b = tostring(a)
        b = b:match("%d+")
        return
    end
end
local function checkCondition5(a)
    return typeof(a) == "Instance"
end
local ax, ay
local function runProtected10(a, b)
    local c
    local function tryOperation8()
        c = a.Source
    end
    local d
    local function processItems2()
        aw:InvokeServer("LoadAssetToPlayerGui", d)
        local waitForChild = al:WaitForChild("PlayerGui"):WaitForChild(d, 3)
        local k, l
        if waitForChild then
            ax[d] = {}
            waitForChild:GetChildren()
            for key, value in ipairs(k), k, 0 do
                l = ax[d]
                table.insert(l, value:Clone())
            end
            aw:InvokeServer("ClearAssetFromPlayerGui", d)
            return waitForChild
        else
            return
        end
    end
    local e
    local function tryOperation9()
        local k
        local l = ipairs(k)
        local m = table.pack(l(k, 0))
        local n = table.unpack(m, 1, m.n)
        local o
        if not (n == nil) then
            o = n
            while true do
                m[2]:Clone().Parent = a
                m = table.pack(l(k, o))
                n = table.unpack(m, 1, m.n)
                if n ~= nil then
                    o = n
                    continue
                end
                break
            end
        end
        o = "SL_CodeTextBox"
        k = a
        l = a:FindFirstChild("SL_CodeTextBox")
        if l then
            l.Text = e
            k = a.ClassName
            o = "ModuleScript"
            if k == "ModuleScript" then
                k = a:FindFirstChild("SL_1ReadOnly")
                if k then
                    k.ContentText = e
                    k.Text = e
                end
                return
            end
        end
        return l, k, o, table.unpack(m, 1, m.n)
    end
    e = a
    c = ay(a)
    local f = not c
    if not f then
        e = a
        c = a:IsA("LuaSourceContainer")
        f = not c
    end
    local g, h
    if not f then
        e = ":" .. a.Name
        f = a.ClassName .. e
        c = nil
        e = b and b[f] and 0 < #b[f]
        if e then
            c = table.remove(b[f], 1)
            e = 0 < #c
            d = ""
            c = c:gsub(string.char(0) .. "*$", "")
            d = a.Name
            _G.FORKT_RAW_SOURCES[a.ClassName .. d] = c
            e = c
            if 150000 < #e then
                d = string.sub(e, 1, 150000)
                e = ""
            end
            d = "SL_CodeTextBox"
            g = a:FindFirstChild("SL_CodeTextBox")
            if g then
                g.Text = e
                d = "ModuleScript"
                if a.ClassName == "ModuleScript" then
                    d = a
                    h = a:FindFirstChild("SL_1ReadOnly")
                    if h then
                        h.ContentText = e
                        h.Text = e
                    end
                end
                return
            else
                d = aw
                if d then
                    local i = {
                        Script = "InsertScriptScript",
                        LocalScript = "InsertLocalScriptLocalScript",
                        ModuleScript = "InsertModuleScriptModuleScript",
                    }
                    h = i
                    d = i[a.ClassName]
                    pcall(tryOperation9)
                    return a, b, f, c, e, g, h, d
                end
            end
        else
            e = pcall
            pcall(tryOperation8)
            c = ""
            _G.FORKT_RAW_SOURCES[a.ClassName .. a.Name] = ""
            e = ""
            d = "SL_CodeTextBox"
            g = a:FindFirstChild("SL_CodeTextBox")
            if g then
                g.Text = ""
                d = "ModuleScript"
                if a.ClassName == "ModuleScript" then
                    d = a
                    h = a:FindFirstChild("SL_1ReadOnly")
                    if h then
                        h.ContentText = ""
                        h.Text = ""
                    end
                end
                return a, b, f, ""
            else
                d = aw
                if not d then
                    return a, b, f, ""
                else
                    local j = {
                        Script = "InsertScriptScript",
                        LocalScript = "InsertLocalScriptLocalScript",
                        ModuleScript = "InsertModuleScriptModuleScript",
                    }
                    h = j
                    d = j[a.ClassName]
                    pcall(tryOperation9)
                    return a, b, f, ""
                end
            end
        end
    end
end
local az
local function runProtected11(a, b)
    local function tryOperation7()
        return a:GetDescendants()
    end
    local c
    local function getValue()
        local anchored = c.Anchored
        local canCollide = c.CanCollide
        c.Anchored = true
        if c:GetAttribute("SL_Anchored") == nil then
            c:SetAttribute("SL_Anchored", anchored)
            c:SetAttribute("SL_CanCollide", canCollide)
            return anchored, canCollide
        else
            c:GetAttribute("SL_CanCollide")
            return
        end
    end
    local function isInstanceOf2()
        if c:IsA("MeshPart") then
            az(c.MeshId)
            az(c.TextureID)
        else
            c:IsA("PartOperation")
            return
        end
    end
    local d, e, f, g, h, i, j, k
    if not ay(a) then
        return
    else
        d = {}
        f = tryOperation7
        k = table.pack(pcall(tryOperation7))
        e = table.unpack(k, 1, k.n)
        if e then
            f = table.unpack(k, 2, k.n)
        else
            table.insert(d, 1, a)
        end
        g = ipairs(d)
        h = d
        k = table.pack(g(h, 0))
        j = table.unpack(k, 1, k.n)
        if not (j == nil) then
            i = j
            while true
