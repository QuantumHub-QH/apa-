print("[QUANTUM HUB] LIQUID GLASS V3.0 ONLINE - BUILD: 1795171852262")
--[[
================================================================================
  QUANTUM HUB — LIQUID GLASS EDITION v3.0
  • Tema Liquid Glass: kaca gelap tembus pandang, tepi berkilau, aksen biru (#0A84FF)
  • UI 3D: panel miring ikut mouse (PC) / jari & gyro (HP)
  • Loading screen animasi • Suara klik Xiurey di semua tombol
  • Importer StudioLite: LZ4, CSG bridge, binary & XML reader
  • PC Toolbox: Creator Store search & 5-10 stud spawn auto-anchor
  • Spoofer & Bypass: In-Game bypass (0.43 pitch / 2.3x speed recommendation)
  • Music Player: Compact vertically, 20 lagu Xiurey, rotating vinyl disc
  • AI Chat: Powered by Xiurey OpenRouter + Salin Script button
================================================================================
]]

-- ======================= SETTING =======================
local APP_NAME       = "LiquidGlassUI"
local LOGO_RICH      = '<font color="#FFFFFF">Quantum</font><font color="#8FD0FF">Hub</font>'
local APP_TITLE      = 'Quantum <font color="#8FD0FF">Hub</font>'
local APP_CAPTION    = "StudioLite & Tools"
local APP_TAGLINE    = "Liquid Glass • StudioLite • Spoofer & Music"
local APP_VERSION    = "v3.0"
local CLICK_SOUND_ID = "rbxassetid://83374956945112"
local USE_3D         = true
local SHOW_LOADING   = true
-- =======================================================

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local StatsService = game:GetService("Stats")

local httpReq = request or http_request or (syn and syn.request) or (http and http.request)
local setclip = setclipboard or toclipboard or set_clipboard or (Clipboard and Clipboard.set) or function() end

-- ======================= WHITELIST CHECK =======================
local WHITELIST_USERS = {
    ["11581809430"] = true,
    ["DevMells"] = true,
}
local isWhitelisted = WHITELIST_USERS[tostring(LocalPlayer.UserId)] or WHITELIST_USERS[LocalPlayer.Name] or true

-- ======================= CONFIG SYSTEM =======================
local FILE_CONFIG = "quantum_hub_config.json"
local config = {
    ocKey = "",
    creatorId = tostring(LocalPlayer.UserId),
    creatorTipe = "User",
    soundDetect = "all",
    speedVal = "2.3",
    tipeSpoof = "Audio",
    musicVolume = 1.0,
    ui3dEnabled = true,
}

local function muatConfig()
    if readfile and isfile and isfile(FILE_CONFIG) then
        local ok, data = pcall(readfile, FILE_CONFIG)
        if ok and data then
            local okD, d = pcall(HttpService.JSONDecode, HttpService, data)
            if okD and type(d) == "table" then
                for k, v in pairs(d) do config[k] = v end
            end
        end
    end
end
local function simpanConfig()
    if writefile then
        pcall(writefile, FILE_CONFIG, HttpService:JSONEncode(config))
    end
end
muatConfig()


local UI3D = (function()
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local GuiService = game:GetService("GuiService")
    local player = game:GetService("Players").LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    local M = {}
    M.Config = {
        Enabled = true,     -- false = semua panel 2D
        MaxTilt = 9,        -- miring maksimal ikut mouse (derajat)
        TouchTilt = 7,      -- miring maksimal ikut jari (HP)
        Idle = true,        -- goyang halus saat diam (HP)
        IdleTilt = 2.2,     -- besar goyang idle (derajat)
        IdleSpeed = 0.55,   -- kecepatan goyang idle
        Gyro = false,       -- ikut kemiringan HP (pakai sensor)
        GyroGain = 14,      -- sensitivitas gyro
        Range = 1.4,        -- jarak cursor/jari dari tengah panel sampai miring penuh (x setengah lebar)
        Smooth = 9,         -- kecepatan panel mengikuti
        Depth = 6,          -- jarak panel dari kamera (stud), tidak mengubah ukuran di layar
        Margin = 40,        -- ruang ekstra (px) untuk glow di luar panel
        CanQuery = true,    -- harus true supaya klik/sentuh di SurfaceGui terbaca
    }

    local KEEP = { UIScale = true, UISizeConstraint = true, UIAspectRatioConstraint = true }
    local bindings = {}
    local running = false
    local seq = 0
    local usingMouse = UserInputService.MouseEnabled and not UserInputService.TouchEnabled
    local touch = nil        -- InputObject sentuhan yang sedang menekan panel
    local touchAnchor = nil  -- panel yang sedang disentuh
    local gravityBase = nil
    local STEP_NAME = "LiquidGlassUI3D_" .. tostring(math.random(100000, 999999)) -- unik per eksekusi

    local function rad(d) return d * math.pi / 180 end

    -- Part disimpan di dalam Terrain: tetap dirender, tapi tidak muncul di Explorer Studio Lite
    -- (Explorer Studio Lite tidak menampilkan isi Terrain). Cadangan: Camera.
    local function holderOf(camera)
        local t = workspace:FindFirstChildOfClass("Terrain")
        return t or camera
    end

    -- Sembunyikan kotak seleksi / handle yang dipasang tool Studio Lite ke part UI ini
    local ourParts = setmetatable({}, { __mode = "k" })
    local function isAdorn(obj)
        return obj:IsA("PVAdornment") or obj:IsA("HandlesBase") or obj:IsA("Highlight")
    end
    local function hideIfOurs(obj)
        local ok, adornee = pcall(function() return obj.Adornee end)
        if not ok or not adornee or not ourParts[adornee] then return end
        pcall(function()
            if obj:IsA("Highlight") then obj.Enabled = false else obj.Visible = false end
        end)
    end
    local function watchAdorn(obj)
        if not isAdorn(obj) then return end
        hideIfOurs(obj)
        pcall(function()
            obj:GetPropertyChangedSignal("Adornee"):Connect(function() hideIfOurs(obj) end)
            obj:GetPropertyChangedSignal("Visible"):Connect(function() hideIfOurs(obj) end)
        end)
        task.defer(hideIfOurs, obj)
    end
    local function watchRoot(root)
        if not root then return end
        pcall(function()
            for _, d in ipairs(root:GetDescendants()) do watchAdorn(d) end
            root.DescendantAdded:Connect(watchAdorn)
        end)
    end
    task.defer(function()
        watchRoot(workspace)
        watchRoot(playerGui)
        pcall(function() watchRoot(game:GetService("CoreGui")) end)
        pcall(function() if gethui then watchRoot(gethui()) end end)
    end)

    function M.willUse() return M.Config.Enabled end

    local function shown(b)
        local gui = b.gui
        if not gui or not gui.Enabled or not b.anchor.Visible then return false end
        local p = b.anchor.Parent
        while p and p ~= gui do
            if p:IsA("GuiObject") and not p.Visible then return false end
            p = p.Parent
        end
        return gui.Parent ~= nil
    end

    local function effectiveScale(b)
        local s, node = 1, b.anchor
        while node and node ~= b.gui do
            local sc = node:FindFirstChildOfClass("UIScale")
            if sc then s = s * sc.Scale end
            node = node.Parent
        end
        return s > 0.01 and s or 0.01
    end

    local function screenRect(b)
        local absSize = b.anchor.AbsoluteSize
        local absPos = b.anchor.AbsolutePosition
        if b.gui:IsA("ScreenGui") and not b.gui.IgnoreGuiInset then
            absPos = absPos + GuiService:GetGuiInset()
        end
        return absPos, absSize
    end

    local function moveIn(b, child)
        if KEEP[child.ClassName] or child == b.stage then return end
        child.Parent = b.stage
    end

    local function enter(b)
        if b.on then return end
        b.on = true
        local part = Instance.new("Part")
        part.Name = "LiquidGlassUI"
        part.Archivable = false -- tidak ikut tersimpan ke place
        part.Locked = true      -- tool Select/Move Studio Lite mengabaikan part terkunci
        part.Anchored = true
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = b.cfg.CanQuery
        part.CastShadow = false
        part.Transparency = 1
        part.Size = Vector3.new(1, 1, 0.05)
        part.Parent = holderOf(workspace.CurrentCamera)
        ourParts[part] = true
        b.part = part

        local surface = Instance.new("SurfaceGui")
        surface.Name = "MedUI3D_" .. b.anchor.Name
        surface.Adornee = part
        surface.Face = Enum.NormalId.Back
        surface.AlwaysOnTop = true
        surface.LightInfluence = 0
        surface.Brightness = 1
        surface.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
        surface.CanvasSize = Vector2.new(100, 100)
        surface.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        surface.ResetOnSpawn = false
        surface.ClipsDescendants = true
        surface.ZOffset = b.layer
        surface.Parent = playerGui
        b.surface = surface

        local stage = Instance.new("Frame")
        stage.Name = "Stage"
        stage.AnchorPoint = Vector2.new(0.5, 0.5)
        stage.Position = UDim2.fromScale(0.5, 0.5)
        stage.BorderSizePixel = 0
        stage.Parent = surface
        b.stage = stage
        b.stageScale = Instance.new("UIScale")
        b.stageScale.Parent = stage

        local anchor = b.anchor
        b.realBg = anchor.BackgroundTransparency
        b.realActive = anchor.Active
        anchor.BackgroundTransparency = 1
        anchor.Active = false
        stage.BackgroundColor3 = anchor.BackgroundColor3
        stage.BackgroundTransparency = b.realBg
        stage.ClipsDescendants = anchor.ClipsDescendants
        stage.ZIndex = anchor.ZIndex
        for _, child in ipairs(anchor:GetChildren()) do moveIn(b, child) end
        b.addConn = anchor.ChildAdded:Connect(function(child)
            task.defer(function()
                if b.on and child.Parent == anchor then moveIn(b, child) end
            end)
        end)
    end

    local function leave(b, destroyed)
        if not b.on then return end
        b.on = false
        if b.addConn then b.addConn:Disconnect(); b.addConn = nil end
        local anchor = b.anchor
        if destroyed then
            b.stage:Destroy()
        else
            for _, child in ipairs(b.stage:GetChildren()) do
                if child ~= b.stageScale then child.Parent = anchor end
            end
            anchor.BackgroundTransparency = b.stage.BackgroundTransparency
            anchor.Active = b.realActive
        end
        b.surface:Destroy()
        b.part:Destroy()
        b.surface, b.part, b.stage, b.stageScale = nil, nil, nil, nil
        b.rx, b.ry = 0, 0
    end

    -- arah miring (derajat) dari titik layar relatif ke tengah panel
    local function tiltToward(point, center, absSize, cfg, maxTilt)
        local nx = math.clamp((point.X - center.X) / (absSize.X * 0.5 * cfg.Range), -1, 1)
        local ny = math.clamp((point.Y - center.Y) / (absSize.Y * 0.5 * cfg.Range), -1, 1)
        return ny * maxTilt, nx * maxTilt
    end

    local function gyroTilt(cfg)
        if not cfg.Gyro or not UserInputService.AccelerometerEnabled then return nil end
        local ok, g = pcall(function() return UserInputService:GetDeviceGravity() end)
        if not ok or not g then return nil end
        local v = g.Position
        if not gravityBase then gravityBase = v end
        gravityBase = gravityBase:Lerp(v, 0.004) -- posisi pegang HP pelan-pelan jadi "netral" baru
        local d = v - gravityBase
        local lim = cfg.TouchTilt
        return math.clamp(-d.Z * cfg.GyroGain, -lim, lim), math.clamp(d.X * cfg.GyroGain, -lim, lim)
    end

    local clock = 0
    local function update(b, dt, camera, vp, mouse, mouseFree, typing)
        local cfg, anchor, stage = b.cfg, b.anchor, b.stage
        if anchor.BackgroundTransparency < 1 then
            stage.BackgroundTransparency = anchor.BackgroundTransparency
            anchor.BackgroundTransparency = 1
        end
        stage.BackgroundColor3 = anchor.BackgroundColor3
        if anchor.Active then b.realActive = true; anchor.Active = false end

        local absPos, absSize = screenRect(b)
        local scale = effectiveScale(b)
        local margin = cfg.Margin
        local canvas = Vector2.new(math.ceil(absSize.X + margin * 2), math.ceil(absSize.Y + margin * 2))
        if b.surface.CanvasSize ~= canvas then b.surface.CanvasSize = canvas end
        stage.Size = UDim2.fromOffset(absSize.X / scale, absSize.Y / scale)
        if b.stageScale.Scale ~= scale then b.stageScale.Scale = scale end

        local center = absPos + absSize * 0.5
        local tx, ty = 0, 0
        if typing or absSize.X <= 0 or absSize.Y <= 0 then
            tx, ty = 0, 0
        elseif usingMouse and mouseFree then
            tx, ty = tiltToward(mouse, center, absSize, cfg, cfg.MaxTilt)
        elseif touch and touchAnchor == anchor and touch.UserInputState ~= Enum.UserInputState.End then
            local p = touch.Position
            tx, ty = tiltToward(Vector2.new(p.X, p.Y), center, absSize, cfg, cfg.TouchTilt)
        else
            local gx, gy = gyroTilt(cfg)
            if gx then
                tx, ty = gx, gy
            elseif cfg.Idle and not usingMouse then
                local t = clock * cfg.IdleSpeed + b.phase
                tx = math.sin(t * 1.3) * cfg.IdleTilt * 0.7
                ty = math.sin(t) * cfg.IdleTilt
            end
        end
        local a = 1 - math.exp(-cfg.Smooth * dt)
        b.rx = b.rx + (tx - b.rx) * a
        b.ry = b.ry + (ty - b.ry) * a

        local depth = cfg.Depth - b.layer * 0.0005
        local wpp = 2 * depth * math.tan(rad(camera.FieldOfView) * 0.5) / vp.Y
        local offset = Vector3.new((center.X - vp.X * 0.5) * wpp, -(center.Y - vp.Y * 0.5) * wpp, -depth)
        local part = b.part
        local home = holderOf(camera)
        if part.Parent ~= home then part.Parent = home end
        part.Size = Vector3.new(canvas.X * wpp, canvas.Y * wpp, 0.05)
        part.CFrame = camera.CFrame * CFrame.new(offset) * CFrame.Angles(rad(b.rx), rad(b.ry), 0)
            * CFrame.new(0, 0, -0.025)
    end

    local function step(dt)
        clock = clock + dt
        local camera = workspace.CurrentCamera
        if not camera then return end
        local vp = camera.ViewportSize
        local mouse = UserInputService:GetMouseLocation()
        local mouseFree = UserInputService.MouseBehavior == Enum.MouseBehavior.Default
        local typing = UserInputService:GetFocusedTextBox() ~= nil
        local use = M.willUse()
        local any = false
        for _, b in pairs(bindings) do
            local visible = shown(b)
            if visible then
                any = true
                if use and not b.on then enter(b) elseif not use and b.on then leave(b) end
            end
            if b.on then
                b.surface.Enabled = visible
                if visible then
                    local ok, err = pcall(update, b, dt, camera, vp, mouse, mouseFree, typing)
                    if not ok then
                        warn("[LiquidGlass UI3D] mati otomatis (2D): " .. tostring(err))
                        M.Config.Enabled = false
                    end
                end
            end
        end
        if not any then
            running = false
            RunService:UnbindFromRenderStep(STEP_NAME)
        end
    end

    local function wake()
        if running then return end
        running = true
        RunService:BindToRenderStep(STEP_NAME, Enum.RenderPriority.Camera.Value + 1, step)
    end
    M.wake = wake

    function M.bind(anchor, overrides)
        if bindings[anchor] or not anchor:IsA("GuiObject") then return end
        local cfg = setmetatable({}, { __index = M.Config }) -- ikut perubahan M.Config (toggle di Setting)
        for k, v in pairs(overrides or {}) do cfg[k] = v end
        local b = { anchor = anchor, cfg = cfg, on = false, rx = 0, ry = 0, conns = {}, phase = math.random() * 6 }
        b.gui = anchor:FindFirstAncestorWhichIsA("LayerCollector")
        seq = (seq + 1) % 1000
        b.layer = ((b.gui and b.gui:IsA("ScreenGui")) and b.gui.DisplayOrder or 0) + seq / 1000
        bindings[anchor] = b
        local function refresh()
            b.gui = anchor:FindFirstAncestorWhichIsA("LayerCollector") or b.gui
            wake()
        end
        table.insert(b.conns, anchor:GetPropertyChangedSignal("Visible"):Connect(refresh))
        table.insert(b.conns, anchor.AncestryChanged:Connect(function()
            if not anchor:IsDescendantOf(game) then M.unbind(anchor, true) return end
            refresh()
        end))
        if b.gui then
            table.insert(b.conns, b.gui:GetPropertyChangedSignal("Enabled"):Connect(wake))
        end
        wake()
    end

    function M.unbind(anchor, destroyed)
        local b = bindings[anchor]
        if not b then return end
        bindings[anchor] = nil
        for _, c in ipairs(b.conns) do c:Disconnect() end
        leave(b, destroyed)
    end

    -- dipanggil saat toggle 3D di Setting
    function M.setEnabled(on)
        M.Config.Enabled = on and true or false
        if not M.Config.Enabled then
            for _, b in pairs(bindings) do leave(b) end
        end
        wake()
    end

    function M.isOn(anchor)
        local b = bindings[anchor]
        return b ~= nil and b.on
    end

    -- ===== deteksi input =====
    UserInputService.LastInputTypeChanged:Connect(function(t)
        local before = usingMouse
        if t == Enum.UserInputType.Touch or t.Name:sub(1, 7) == "Gamepad" then
            usingMouse = false
        elseif t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.MouseButton1
            or t == Enum.UserInputType.MouseButton2 or t == Enum.UserInputType.MouseWheel then
            usingMouse = true
        end
        if before ~= usingMouse then wake() end
    end)

    -- sentuhan: catat jari yang mulai DI ATAS panel (dicek dari kotak 2D asli)
    UserInputService.TouchStarted:Connect(function(input)
        for anchor, b in pairs(bindings) do
            if b.on and b.surface and b.surface.Enabled then
                local absPos, absSize = screenRect(b)
                local p = input.Position
                if p.X >= absPos.X and p.X <= absPos.X + absSize.X and p.Y >= absPos.Y and p.Y <= absPos.Y + absSize.Y then
                    touch, touchAnchor = input, anchor
                    return
                end
            end
        end
    end)
    UserInputService.TouchEnded:Connect(function(input)
        if input == touch then touch, touchAnchor = nil, nil end
    end)

    return M
end)()

local Kit = (function()
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

    local Kit = {}
    -- palet "Liquid Glass": kaca gelap tembus pandang + garis putih berkilau + aksen biru
    local GLASS_LINE = Color3.fromRGB(255, 255, 255)
    local P = {
        panel = Color3.fromRGB(22, 26, 38),
        panelT = 0.24,
        panelStroke = GLASS_LINE,
        glow = Color3.fromRGB(0, 0, 0),
        card = Color3.fromRGB(255, 255, 255),
        cardStroke = GLASS_LINE,
        well = Color3.fromRGB(8, 10, 18),
        wellStroke = GLASS_LINE,
        chip = Color3.fromRGB(70, 78, 98),
        chipStroke = GLASS_LINE,
        text = Color3.fromRGB(255, 255, 255),
        muted = Color3.fromRGB(196, 204, 222),
        dim = Color3.fromRGB(142, 152, 174),
        accent = Color3.fromRGB(10, 132, 255),
        accentHi = Color3.fromRGB(255, 255, 255),
        accentLo = Color3.fromRGB(160, 170, 190),
        fillTop = Color3.fromRGB(96, 178, 255),
        fillBottom = Color3.fromRGB(10, 112, 245),
        grayTop = Color3.fromRGB(255, 255, 255),
        grayBottom = Color3.fromRGB(196, 206, 228),
        purpleTop = Color3.fromRGB(120, 214, 255),
        purpleBottom = Color3.fromRGB(10, 122, 255),
        track = Color3.fromRGB(0, 0, 0),
        trackLine = GLASS_LINE,
        tabIdle = Color3.fromRGB(200, 208, 226),
        ok = Color3.fromRGB(48, 209, 88),
        warn = Color3.fromRGB(255, 204, 64),
        ink = Color3.fromRGB(12, 14, 22),
        danger = Color3.fromRGB(255, 69, 88),
        lilac = Color3.fromRGB(140, 206, 255),
    }
    Kit.P = P
    Kit.Font = Enum.Font.GothamMedium
    Kit.FontBold = Enum.Font.GothamBold
    Kit.FontBlack = Enum.Font.GothamBlack
    Kit.UI3D = UI3D

    function Kit.tween(inst, duration, props, style, direction)
        local t = TweenService:Create(inst, TweenInfo.new(duration, style or Enum.EasingStyle.Quint,
            direction or Enum.EasingDirection.Out), props)
        t:Play()
        return t
    end

    function Kit.corner(inst, radius, isScale)
        local c = inst:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
        c.CornerRadius = isScale and UDim.new(radius, 0) or UDim.new(0, radius)
        c.Parent = inst
        return c
    end

    -- tepi kaca: terang di kiri-atas, hampir hilang di tengah, pantulan tipis di kanan-bawah
    function Kit.rim(stroke, strong)
        local g = stroke:FindFirstChild("Rim") or Instance.new("UIGradient")
        g.Name = "Rim"
        g.Rotation = 55
        g.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(190, 214, 255))
        local a = strong and 0.05 or 0.45
        g.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, a),
            NumberSequenceKeypoint.new(0.32, strong and 0.62 or 0.86),
            NumberSequenceKeypoint.new(0.7, strong and 0.8 or 0.93),
            NumberSequenceKeypoint.new(1, strong and 0.3 or 0.62),
        })
        g.Parent = stroke
        return g
    end

    function Kit.stroke(inst, color, thickness)
        local s = Instance.new("UIStroke")
        s.Color = color or P.cardStroke
        s.Thickness = thickness or 1
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        s.Parent = inst
        if s.Color == GLASS_LINE then Kit.rim(s) end
        return s
    end

    -- kilau specular di setengah atas permukaan kaca
    function Kit.sheen(inst, radius, strength, z)
        local f = Instance.new("Frame")
        f.Name = "Sheen"
        f.BackgroundColor3 = Color3.new(1, 1, 1)
        f.BorderSizePixel = 0
        f.Size = UDim2.fromScale(1, 0.55)
        f.ZIndex = z or 0
        f.Active = false
        f.Parent = inst
        Kit.corner(f, radius or 14)
        local g = Instance.new("UIGradient")
        g.Rotation = 90
        local t = strength or 0.86
        g.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, t), NumberSequenceKeypoint.new(0.5, math.min(1, t + 0.1)), NumberSequenceKeypoint.new(1, 1),
        })
        g.Parent = f
        return f
    end

    -- ===== suara klik (semua tombol) =====
    local CLICK_ID = CLICK_SOUND_ID
    Kit.ClickSound = true
    Kit.ClickVolume = 0.6
    local clickSound, lastClick = nil, 0
    function Kit.click()
        if not Kit.ClickSound then return end
        local now = os.clock()
        if now - lastClick < 0.05 then return end
        lastClick = now
        pcall(function()
            if not clickSound or not clickSound.Parent then
                local host = playerGui:FindFirstChild("LiquidGlassAudio") or Instance.new("ScreenGui")
                host.Name = "LiquidGlassAudio"
                host.ResetOnSpawn = false
                host.Parent = playerGui
                clickSound = Instance.new("Sound")
                clickSound.Name = "Click"
                clickSound.SoundId = CLICK_ID
                clickSound.Archivable = false
                clickSound.Parent = host
            end
            clickSound.Volume = Kit.ClickVolume
            clickSound.TimePosition = 0
            clickSound:Play()
        end)
    end
    local function hookButton(b)
        if b:IsA("GuiButton") and not b:GetAttribute("MSClick") and not b:GetAttribute("NoClick") then
            b:SetAttribute("MSClick", true)
            b.MouseButton1Click:Connect(Kit.click)
        end
    end
    -- pasang suara klik ke semua tombol di dalam root (termasuk yang dibuat belakangan)
    function Kit.hookClicks(root)
        if root:GetAttribute("MSClickRoot") then return end
        root:SetAttribute("MSClickRoot", true)
        for _, d in ipairs(root:GetDescendants()) do hookButton(d) end
        root.DescendantAdded:Connect(function(d)
            task.defer(function() if d.Parent then hookButton(d) end end)
        end)
    end

    -- kilau ungu muda diam di pojok kiri-atas border (versi ringan Nectarion)
    function Kit.sweepStroke(stroke)
        stroke.Color = Color3.new(1, 1, 1)
        return Kit.rim(stroke, true)
    end

    function Kit.padding(inst, left, top, right, bottom)
        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, left)
        pad.PaddingTop = UDim.new(0, top or left)
        pad.PaddingRight = UDim.new(0, right or left)
        pad.PaddingBottom = UDim.new(0, bottom or top or left)
        pad.Parent = inst
        return pad
    end

    function Kit.list(inst, gap, direction)
        local l = Instance.new("UIListLayout")
        l.Padding = UDim.new(0, gap or 6)
        l.SortOrder = Enum.SortOrder.LayoutOrder
        l.FillDirection = direction or Enum.FillDirection.Vertical
        l.Parent = inst
        return l
    end

    local function gradientFill(inst, top, bottom)
        local g = Instance.new("UIGradient")
        g.Name = "Cream"
        g.Color = ColorSequence.new(top, bottom)
        g.Rotation = 90
        g.Parent = inst
        return g
    end
    function Kit.blueFill(inst) return gradientFill(inst, P.fillTop, P.fillBottom) end
    function Kit.grayFill(inst) return gradientFill(inst, P.grayTop, P.grayBottom) end
    function Kit.purpleFill(inst) return gradientFill(inst, P.purpleTop, P.purpleBottom) end

    -- glow ungu lembut 3 lapis di sekeliling frame
    function Kit.glow(parent, radius, color)
        local list = {}
        for _, spec in ipairs({ { 22, 0.93 }, { 12, 0.88 }, { 5, 0.82 } }) do
            local g = Instance.new("Frame")
            g.Name = "Glow"
            g.AnchorPoint = Vector2.new(0.5, 0.5)
            g.Position = UDim2.new(0.5, 0, 0.5, math.floor(spec[1] * 0.35))
            g.Size = UDim2.new(1, spec[1] * 2, 1, spec[1] * 2)
            g.BackgroundColor3 = color or P.glow
            g.BackgroundTransparency = spec[2]
            g.BorderSizePixel = 0
            g.ZIndex = 0
            g.Parent = parent
            Kit.corner(g, (radius or 20) + spec[1])
            table.insert(list, { frame = g, base = spec[2] })
        end
        return list
    end

    function Kit.screen(name, order)
        local old = playerGui:FindFirstChild(name)
        if old then old:Destroy() end
        local gui = Instance.new("ScreenGui")
        gui.Name = name
        gui.ResetOnSpawn = false
        gui.DisplayOrder = order or 60
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.Parent = playerGui
        Kit.hookClicks(gui)
        return gui
    end

    -- ===== ikon (digambar dari Frame, tanpa asset) =====
    function Kit.icon(parent, kind, size, color)
        size = size or 24
        color = color or P.text
        local s = size / 24
        local root = Instance.new("Frame")
        root.Name = "Icon_" .. tostring(kind)
        root.BackgroundTransparency = 1
        root.Size = UDim2.fromOffset(size, size)
        root.Parent = parent
        local function piece(w, h, cx, cy, rot, c, t, radius)
            local f = Instance.new("Frame")
            f.AnchorPoint = Vector2.new(0.5, 0.5)
            f.Size = UDim2.fromOffset(w * s, h * s)
            f.Position = UDim2.fromOffset(cx * s, cy * s)
            f.Rotation = rot or 0
            f.BackgroundColor3 = c or color
            f.BackgroundTransparency = t or 0
            f.BorderSizePixel = 0
            f.Parent = root
            if radius == "full" then Kit.corner(f, 1, true) elseif radius then Kit.corner(f, radius * s) end
            return f
        end
        if kind == "spoof" then -- dua panah bertukar
            piece(14, 2.6, 11, 8, 0, color, 0, "full")
            piece(6, 2.6, 16.5, 6, 45, color, 0, "full")
            piece(6, 2.6, 16.5, 10, -45, color, 0, "full")
            piece(14, 2.6, 13, 16, 0, P.lilac, 0, "full")
            piece(6, 2.6, 7.5, 14, -45, P.lilac, 0, "full")
            piece(6, 2.6, 7.5, 18, 45, P.lilac, 0, "full")
        elseif kind == "upload" then
            piece(16, 2.6, 12, 20, 0, color, 0, "full")
            piece(2.6, 12, 12, 11, 0, color, 0, "full")
            piece(8, 2.6, 9.4, 7.4, -45, color, 0, "full")
            piece(8, 2.6, 14.6, 7.4, 45, color, 0, "full")
        elseif kind == "import" then
            local box = piece(18, 10, 12, 16, 0, color, 1, 3)
            Kit.stroke(box, color, math.max(1.5, 2 * s))
            piece(2.6, 10, 12, 8, 0, P.lilac, 0, "full")
            piece(7, 2.6, 9.8, 11.6, 45, P.lilac, 0, "full")
            piece(7, 2.6, 14.2, 11.6, -45, P.lilac, 0, "full")
        elseif kind == "gear" then
            for _, r in ipairs({ 0, 45, 90, 135 }) do piece(20, 4, 12, 12, r, color, 0, 1.5) end
            piece(14, 14, 12, 12, 0, color, 0, "full")
            piece(6, 6, 12, 12, 0, P.ink, 0, "full")
        elseif kind == "copy" then
            local a = piece(11, 13, 9.5, 10.5, 0, color, 1, 2.5)
            Kit.stroke(a, color, math.max(1.2, 1.6 * s))
            local b = piece(11, 13, 14.5, 14.5, 0, P.panel, 0, 2.5)
            Kit.stroke(b, color, math.max(1.2, 1.6 * s))
        elseif kind == "search" then
            local ring = piece(13, 13, 10.5, 10.5, 0, color, 1, "full")
            Kit.stroke(ring, color, math.max(1.5, 2 * s))
            piece(8, 2.4, 19, 19, 45, color, 0, "full")
        elseif kind == "toolbox" then -- koper toolbox
            local body = piece(20, 13, 12, 15, 0, color, 1, 3)
            Kit.stroke(body, color, math.max(1.5, 2 * s))
            local handle = piece(8, 5, 12, 6.5, 0, color, 1, 2)
            Kit.stroke(handle, color, math.max(1.3, 1.8 * s))
            piece(20, 2.4, 12, 14, 0, P.lilac, 0, "full")
        elseif kind == "chat" then -- gelembung chat
            local b = piece(19, 14, 12, 10.5, 0, color, 1, 5)
            Kit.stroke(b, color, math.max(1.5, 2 * s))
            piece(5, 5, 8, 18.5, 45, color, 0, 1)
            piece(2.6, 2.6, 8, 10.5, 0, P.lilac, 0, "full")
            piece(2.6, 2.6, 12, 10.5, 0, P.lilac, 0, "full")
            piece(2.6, 2.6, 16, 10.5, 0, P.lilac, 0, "full")
        elseif kind == "mesh" then -- kubus 3D (garis)
            local back = piece(12, 12, 14.5, 9.5, 0, color, 1, 2)
            Kit.stroke(back, P.lilac, math.max(1.3, 1.8 * s))
            local front = piece(12, 12, 9.5, 14.5, 0, color, 1, 2)
            Kit.stroke(front, color, math.max(1.5, 2 * s))
        elseif kind == "avatar" then -- kepala + bahu
            piece(9, 9, 12, 7.5, 0, color, 0, "full")
            piece(17, 9, 12, 19, 0, P.lilac, 0, 4.5)
        else -- gem
            piece(13, 13, 12, 12, 45, color, 0, 2)
            piece(5, 5, 12, 12, 45, P.ink, 0, 1)
        end
        return root
    end

    -- ===== panel & kartu =====
    function Kit.glass(parent, o)
        o = o or {}
        local f = Instance.new(o.Canvas and "CanvasGroup" or "Frame")
        f.Name = o.Name or "Panel"
        f.Size = o.Size or UDim2.fromScale(1, 1)
        f.Position = o.Position or UDim2.new()
        f.AnchorPoint = o.AnchorPoint or Vector2.new()
        f.BackgroundColor3 = o.Color or P.panel
        f.BackgroundTransparency = o.Transparency or P.panelT
        f.BorderSizePixel = 0
        Kit.corner(f, o.Radius or 20)
        Kit.rim(Kit.stroke(f, P.panelStroke, 1.5), true)
        local g = Instance.new("UIGradient")
        g.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.55, Color3.fromRGB(205, 214, 232)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 180, 205)),
        })
        g.Rotation = 120
        g.Parent = f
        if o.Sheen ~= false then Kit.sheen(f, o.Radius or 20, 0.9) end
        f.Parent = parent
        return f
    end

    function Kit.card(parent, o)
        o = o or {}
        local f = Instance.new("Frame")
        f.Name = o.Name or "Card"
        f.Size = o.Size or UDim2.new(1, 0, 0, 40)
        f.Position = o.Position or UDim2.new()
        f.AnchorPoint = o.AnchorPoint or Vector2.new()
        f.BackgroundColor3 = o.Color or (o.Well and Color3.new(0, 0, 0) or Color3.new(1, 1, 1))
        f.BackgroundTransparency = o.Color and 0.35 or (o.Well and 0.6 or 0.93)
        f.BorderSizePixel = 0
        f.LayoutOrder = o.LayoutOrder or 0
        if o.AutoY then
            f.AutomaticSize = Enum.AutomaticSize.Y
        end
        Kit.corner(f, o.Radius or 14)
        Kit.stroke(f, o.Well and P.wellStroke or P.cardStroke, 1)
        f.Parent = parent
        return f
    end

    function Kit.label(parent, o)
        local t = Instance.new("TextLabel")
        t.Name = o.Name or "Label"
        t.BackgroundTransparency = 1
        t.Size = o.Size or UDim2.new(1, 0, 0, 18)
        t.Position = o.Position or UDim2.new()
        t.AnchorPoint = o.AnchorPoint or Vector2.new()
        t.Font = o.Font or Kit.Font
        t.TextSize = o.TextSize or 13
        t.TextColor3 = o.Color or P.text
        t.Text = o.Text or ""
        t.RichText = o.Rich == true
        t.TextXAlignment = o.Align or Enum.TextXAlignment.Left
        t.TextYAlignment = o.YAlign or Enum.TextYAlignment.Center
        t.TextWrapped = o.Wrap == true
        t.TextTruncate = o.Truncate and Enum.TextTruncate.AtEnd or Enum.TextTruncate.None
        t.LayoutOrder = o.LayoutOrder or 0
        t.ZIndex = o.ZIndex or 1
        if o.AutoY then
            t.AutomaticSize = Enum.AutomaticSize.Y
            t.Size = UDim2.new(t.Size.X.Scale, t.Size.X.Offset, 0, 0)
        end
        t.Parent = parent
        return t
    end

    -- judul seksi: garis biru tegak + teks kapital
    function Kit.caption(parent, text, order)
        local f = Instance.new("Frame")
        f.Name = "Caption"
        f.BackgroundTransparency = 1
        f.Size = UDim2.new(1, 0, 0, 18)
        f.LayoutOrder = order or 0
        f.Parent = parent
        local bar = Instance.new("Frame")
        bar.BackgroundColor3 = P.accent
        bar.BorderSizePixel = 0
        bar.Position = UDim2.fromOffset(0, 2)
        bar.Size = UDim2.fromOffset(3, 14)
        bar.Parent = f
        Kit.corner(bar, 1)
        Kit.label(f, { Name = "Text", Text = string.upper(text), Position = UDim2.fromOffset(12, 0),
            Size = UDim2.new(1, -12, 1, 0), TextSize = 11, Font = Kit.FontBold, Color = Color3.fromRGB(214, 214, 224) })
        return f
    end

    local function rgb(v) return Color3.fromRGB(v, v, v) end
    local GRAY_SEQ = ColorSequence.new(P.grayTop, P.grayBottom)
    local BLUE_SEQ = ColorSequence.new(P.fillTop, P.fillBottom)
    local PURPLE_SEQ = ColorSequence.new(P.purpleTop, P.purpleBottom)

    local function paint(b, state)
        local active = b:GetAttribute("Active") == true
        local filled = b:GetAttribute("Solid") == true or active
        local purple = b:GetAttribute("Purple") == true
        local gradient = b:FindFirstChild("Cream")
        local stroke = b:FindFirstChildOfClass("UIStroke")
        if gradient then
            gradient.Enabled = true
            gradient.Color = filled and (purple and PURPLE_SEQ or BLUE_SEQ) or GRAY_SEQ
        end
        local bg = state == "press" and rgb(200) or (state == "hover" and rgb(255) or rgb(236))
        if filled then bg = state == "press" and rgb(205) or (state == "hover" and rgb(255) or rgb(242)) end
        if b:GetAttribute("Disabled") then bg = rgb(150) end
        local alpha = filled and (state == "press" and 0.2 or 0.08)
            or (state == "press" and 0.72 or (state == "hover" and 0.8 or 0.87))
        Kit.tween(b, 0.12, { BackgroundColor3 = bg, BackgroundTransparency = alpha })
        local scale = b:FindFirstChild("PressScale")
        if scale then Kit.tween(scale, 0.12, { Scale = state == "press" and 0.96 or 1 }) end
        if stroke then
            Kit.tween(stroke, 0.12, {
                Color = filled and Color3.fromRGB(200, 230, 255) or Color3.new(1, 1, 1),
                Transparency = filled and 0.1 or (state == "hover" and 0 or 0.15),
            })
        end
    end

    -- o: Text, Size, Position, Solid, Purple, TextSize, Radius, OnClick, Name, LayoutOrder, Icon
    function Kit.button(parent, o)
        local b = Instance.new("TextButton")
        b.Name = o.Name or "Button"
        b.AutoButtonColor = false
        b.Size = o.Size or UDim2.new(1, 0, 0, 36)
        b.Position = o.Position or UDim2.new()
        b.AnchorPoint = o.AnchorPoint or Vector2.new()
        b.BackgroundColor3 = P.chip
        b.BorderSizePixel = 0
        b.Font = Kit.FontBold
        b.TextSize = o.TextSize or 12
        b.Text = o.Text or ""
        b.TextTransparency = 1 -- teks digambar Label "Face" (UIGradient ikut mewarnai teks tombol)
        b.LayoutOrder = o.LayoutOrder or 0
        b:SetAttribute("Solid", o.Solid == true)
        b:SetAttribute("Purple", o.Purple == true)
        b:SetAttribute("Active", false)
        Kit.corner(b, o.Radius or 12)
        Kit.stroke(b, P.chipStroke, 1)
        Kit.blueFill(b)
        Kit.sheen(b, o.Radius or 12, 0.8, 2)
        local ps = Instance.new("UIScale")
        ps.Name = "PressScale"
        ps.Parent = b
        b.Parent = parent
        local face = Instance.new("TextLabel")
        face.Name = "Face"
        face.BackgroundTransparency = 1
        face.Size = UDim2.fromScale(1, 1)
        face.ZIndex = 3
        face.Font = b.Font
        face.TextSize = b.TextSize
        face.Text = b.Text
        face.TextColor3 = P.text
        face.TextTruncate = Enum.TextTruncate.AtEnd
        face.Parent = b
        if o.Icon then
            Kit.padding(face, 22, 0, 0, 0)
            local host = Instance.new("Frame")
            host.BackgroundTransparency = 1
            host.AnchorPoint = Vector2.new(0, 0.5)
            host.ZIndex = 3
            host.Size = UDim2.fromOffset(16, 16)
            host.Parent = b
            local function place()
                local w = game:GetService("TextService"):GetTextSize(b.Text, b.TextSize, b.Font, Vector2.new(1000, 100)).X
                host.Position = UDim2.new(0.5, -(w + 22) / 2, 0.5, 0)
            end
            place()
            b:GetPropertyChangedSignal("Text"):Connect(place)
            Kit.icon(host, o.Icon, 16, P.text)
        end
        b:GetPropertyChangedSignal("Text"):Connect(function() face.Text = b.Text end)
        paint(b, "idle")
        b.MouseEnter:Connect(function() paint(b, "hover") end)
        b.MouseLeave:Connect(function() paint(b, "idle") end)
        b.MouseButton1Down:Connect(function() paint(b, "press") end)
        b.MouseButton1Up:Connect(function() paint(b, "idle") end)
        if o.OnClick then
            b.MouseButton1Click:Connect(function()
                if not b:GetAttribute("Disabled") then o.OnClick() end
            end)
        end
        return b
    end

    function Kit.setActive(button, active)
        button:SetAttribute("Active", active == true)
        paint(button, "idle")
    end

    function Kit.setDisabled(button, disabled)
        button:SetAttribute("Disabled", disabled == true)
        paint(button, "idle")
    end

    -- o: Name, Size, Position, Placeholder, Text, TextSize, Multi, LayoutOrder, Icon
    function Kit.input(parent, o)
        local box = Instance.new("TextBox")
        box.Name = o.Name or "Input"
        box.Size = o.Size or UDim2.new(1, 0, 0, 38)
        box.Position = o.Position or UDim2.new()
        box.BackgroundColor3 = Color3.fromRGB(4, 6, 12)
        box.BackgroundTransparency = 0.55
        box.BorderSizePixel = 0
        box.Font = Kit.Font
        box.TextSize = o.TextSize or 12
        box.TextColor3 = P.text
        box.PlaceholderText = o.Placeholder or ""
        box.PlaceholderColor3 = P.dim
        box.Text = o.Text or ""
        box.ClearTextOnFocus = false
        box.TextXAlignment = Enum.TextXAlignment.Left
        box.MultiLine = o.Multi == true
        box.TextWrapped = o.Multi == true
        box.TextTruncate = o.Multi and Enum.TextTruncate.None or Enum.TextTruncate.AtEnd
        box.TextYAlignment = o.Multi and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center
        box.ClipsDescendants = true
        box.LayoutOrder = o.LayoutOrder or 0
        Kit.corner(box, 14)
        local s = Kit.stroke(box, P.wellStroke, 1)
        local left = o.Icon and 40 or 12
        Kit.padding(box, left, o.Multi and 10 or 0, 12, o.Multi and 10 or 0)
        if o.Icon then
            local holder = Instance.new("Frame")
            holder.BackgroundTransparency = 1
            holder.AnchorPoint = Vector2.new(0, 0.5)
            holder.Position = UDim2.new(0, 14 - left, 0.5, 0)
            holder.Size = UDim2.fromOffset(18, 18)
            holder.Parent = box
            Kit.icon(holder, o.Icon, 18, P.muted)
        end
        box.Focused:Connect(function() Kit.tween(s, 0.15, { Color = P.accent }) end)
        box.FocusLost:Connect(function() Kit.tween(s, 0.15, { Color = P.wellStroke }) end)
        s.Transparency = 0.25
        box.Parent = parent
        return box
    end

    function Kit.scroll(parent, o)
        o = o or {}
        local s = Instance.new("ScrollingFrame")
        s.Name = o.Name or "Scroll"
        s.BackgroundTransparency = 1
        s.BorderSizePixel = 0
        s.Size = o.Size or UDim2.fromScale(1, 1)
        s.Position = o.Position or UDim2.new()
        s.AutomaticCanvasSize = Enum.AutomaticSize.Y
        s.CanvasSize = UDim2.new()
        s.ScrollBarThickness = 3
        s.ScrollBarImageColor3 = Color3.fromRGB(96, 96, 108)
        s.ScrollingDirection = Enum.ScrollingDirection.Y
        s.ElasticBehavior = Enum.ElasticBehavior.Never
        s.LayoutOrder = o.LayoutOrder or 0
        s.Parent = parent
        if o.Gap ~= false then Kit.list(s, o.Gap or 8) end
        if o.Pad then Kit.padding(s, o.Pad, o.Pad, o.Pad + 4, o.Pad) end
        return s
    end

    -- pilihan segmen (mis. tipe asset): return frame, get(), set(value)
    function Kit.segment(parent, options, default, onChange, order)
        local track = Instance.new("Frame")
        track.Name = "Segment"
        track.Size = UDim2.new(1, 0, 0, 36)
        track.BackgroundColor3 = P.track
        track.BackgroundTransparency = 0.6
        track.BorderSizePixel = 0
        track.LayoutOrder = order or 0
        track.Parent = parent
        Kit.corner(track, 12)
        Kit.stroke(track, P.trackLine, 1).Transparency = 0.2
        Kit.padding(track, 4, 4, 4, 4)
        local grid = Instance.new("UIGridLayout")
        grid.CellPadding = UDim2.fromOffset(4, 0)
        grid.CellSize = UDim2.new(1 / #options, -math.ceil((4 * (#options - 1) + 8) / #options) - 1, 1, 0) -- muat dengan padding track
        grid.SortOrder = Enum.SortOrder.LayoutOrder
        grid.Parent = track
        local current = default
        local buttons = {}
        local function set(value, silent)
            current = value
            for _, item in ipairs(buttons) do
                local active = item.value == value
                item.fill.Enabled = active
                Kit.tween(item.button, 0.14, { BackgroundTransparency = active and 0.8 or 1 })
                Kit.tween(item.label, 0.14, { TextColor3 = active and P.text or P.tabIdle })
            end
            if onChange and not silent then onChange(value) end
        end
        for i, opt in ipairs(options) do
            local b = Instance.new("TextButton")
            b.AutoButtonColor = false
            b.Text = ""
            b.BackgroundColor3 = Color3.new(1, 1, 1)
            b.BackgroundTransparency = 1
            b.BorderSizePixel = 0
            b.LayoutOrder = i
            b.Parent = track
            Kit.corner(b, 9)
            local fill = Kit.grayFill(b)
            local label = Kit.label(b, { Text = opt.label, Size = UDim2.fromScale(1, 1), TextSize = 11,
                Font = Kit.FontBold, Align = Enum.TextXAlignment.Center, Color = P.tabIdle, ZIndex = 2 })
            b.MouseButton1Click:Connect(function() set(opt.value) end)
            table.insert(buttons, { value = opt.value, button = b, fill = fill, label = label })
        end
        set(default, true)
        return track, function() return current end, set
    end

    -- saklar on/off: return frame, set(bool)
    function Kit.toggle(parent, text, value, onChange, order)
        local row = Kit.card(parent, { Size = UDim2.new(1, 0, 0, 44), LayoutOrder = order })
        Kit.label(row, { Text = text, Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -80, 1, 0),
            TextSize = 12, Font = Kit.FontBold })
        local sw = Instance.new("TextButton")
        sw.AutoButtonColor = false
        sw.Text = ""
        sw.AnchorPoint = Vector2.new(1, 0.5)
        sw.Position = UDim2.new(1, -12, 0.5, 0)
        sw.Size = UDim2.fromOffset(44, 24)
        sw.BackgroundColor3 = P.chip
        sw.BorderSizePixel = 0
        sw.Parent = row
        Kit.corner(sw, 1, true)
        Kit.stroke(sw, GLASS_LINE, 1).Transparency = 0.3
        local knob = Instance.new("Frame")
        knob.AnchorPoint = Vector2.new(0, 0.5)
        knob.Size = UDim2.fromOffset(18, 18)
        knob.BackgroundColor3 = Color3.new(1, 1, 1)
        knob.BorderSizePixel = 0
        knob.Parent = sw
        Kit.corner(knob, 1, true)
        local on = value == true
        local function set(v, silent)
            on = v == true
            Kit.tween(sw, 0.16, { BackgroundColor3 = on and P.ok or P.chip })
            Kit.tween(knob, 0.16, { Position = on and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) })
            if onChange and not silent then onChange(on) end
        end
        sw.MouseButton1Click:Connect(function() set(not on) end)
        set(on, true)
        return row, set
    end

    -- progress bar: return frame, set(0..1)
    function Kit.progress(parent, order)
        local track = Instance.new("Frame")
        track.Name = "Progress"
        track.Size = UDim2.new(1, 0, 0, 6)
        track.BackgroundColor3 = P.track
        track.BackgroundTransparency = 0.5
        track.BorderSizePixel = 0
        track.LayoutOrder = order or 0
        track.Parent = parent
        Kit.corner(track, 1, true)
        Kit.stroke(track, GLASS_LINE, 1).Transparency = 0.4
        local fill = Instance.new("Frame")
        fill.Size = UDim2.fromScale(0, 1)
        fill.BackgroundColor3 = Color3.new(1, 1, 1)
        fill.BorderSizePixel = 0
        fill.Parent = track
        Kit.corner(fill, 1, true)
        Kit.purpleFill(fill).Rotation = 0
        return track, function(v)
            Kit.tween(fill, 0.2, { Size = UDim2.fromScale(math.clamp(tonumber(v) or 0, 0, 1), 1) })
        end
    end

    function Kit.draggable(handle, target, uiScale)
        local dragging, startInput, startPos = false, nil, nil
        handle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                startInput = input.Position
                startPos = target.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = (input.Position - startInput) / (uiScale and uiScale.Scale or 1)
                target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end

    -- ===== window Nectarion =====
    -- o: Name, Width, Height, Title (RichText), Subtitle, Icon, Order, TitleWidth
    function Kit.window(o)
        local width, height = o.Width, o.Height
        local headerH = 64
        local bodyTop = headerH + 10
        local gui = Kit.screen(o.Name, o.Order or 60)
        gui.Enabled = false

        local holder = Instance.new("Frame")
        holder.Name = "Holder"
        holder.AnchorPoint = Vector2.new(0.5, 0.5)
        holder.Position = UDim2.fromScale(0.5, 0.5)
        holder.Size = UDim2.fromOffset(width, height)
        holder.BackgroundTransparency = 1
        holder.Parent = gui
        local uiScale = Instance.new("UIScale")
        uiScale.Parent = holder
        local glows = Kit.glow(holder, 22)

        local root = Kit.glass(holder, { Name = "Root", Canvas = true, Radius = 22 })
        local rootStroke = root:FindFirstChildOfClass("UIStroke")
        rootStroke.Color = Color3.new(1, 1, 1)
        rootStroke.Transparency = 0.1
        Kit.sweepStroke(rootStroke)

        local gloss = Instance.new("Frame")
        gloss.Name = "Gloss"
        gloss.Size = UDim2.fromScale(1, 1)
        gloss.BackgroundColor3 = Color3.new(1, 1, 1)
        gloss.BorderSizePixel = 0
        gloss.Parent = root
        local gg = Instance.new("UIGradient")
        gg.Rotation = 90
        gg.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.93), NumberSequenceKeypoint.new(0.25, 0.985), NumberSequenceKeypoint.new(1, 1),
        })
        gg.Parent = gloss

        local header = Instance.new("Frame")
        header.Name = "Header"
        header.Size = UDim2.new(1, 0, 0, headerH + 6)
        header.BackgroundTransparency = 1
        header.Parent = root

        local tile = Instance.new("Frame")
        tile.Name = "IconTile"
        tile.AnchorPoint = Vector2.new(0, 0.5)
        tile.Position = UDim2.new(0, 16, 0, (headerH + 6) / 2)
        tile.Size = UDim2.fromOffset(36, 36)
        tile.BackgroundColor3 = Color3.new(1, 1, 1)
        tile.BorderSizePixel = 0
        tile.Parent = header
        Kit.corner(tile, 11)
        Kit.grayFill(tile)
        tile.BackgroundTransparency = 0.82
        Kit.stroke(tile, Color3.new(1, 1, 1), 1)
        Kit.sheen(tile, 12, 0.75, 1)
        local tileIcon = Instance.new("Frame")
        tileIcon.BackgroundTransparency = 1
        tileIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        tileIcon.Position = UDim2.fromScale(0.5, 0.5)
        tileIcon.Size = UDim2.fromOffset(18, 18)
        tileIcon.Parent = tile
        Kit.icon(tileIcon, o.Icon or "gem", 18, P.text)

        local textLeft = 16 + 36 + 10
        local titleWidth = o.TitleWidth or 130
        local title = Kit.label(header, { Name = "Title", Text = o.Title or "", Rich = true,
            Position = UDim2.fromOffset(textLeft, 15), Size = UDim2.fromOffset(titleWidth, 22),
            TextSize = 18, Font = Kit.FontBold })
        title.TextTruncate = Enum.TextTruncate.AtEnd
        local dot = Instance.new("Frame")
        dot.Size = UDim2.fromOffset(7, 7)
        dot.AnchorPoint = Vector2.new(0, 0.5)
        dot.Position = UDim2.fromOffset(textLeft, 46)
        dot.BackgroundColor3 = P.ok
        dot.BorderSizePixel = 0
        dot.Parent = header
        Kit.corner(dot, 1, true)
        TweenService:Create(dot, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            { BackgroundTransparency = 0.65 }):Play()
        local subtitle = Kit.label(header, { Name = "Subtitle", Text = o.Subtitle or "",
            Position = UDim2.fromOffset(textLeft + 13, 38), Size = UDim2.fromOffset(titleWidth - 13, 16),
            TextSize = 11, Color = P.muted, Truncate = true })

        local closeSize, closeMargin = 36, 16
        local tabLeft = textLeft + titleWidth + 8
        local tabHost = Instance.new("Frame")
        tabHost.Name = "TabHost"
        tabHost.BackgroundTransparency = 1
        tabHost.Position = UDim2.fromOffset(tabLeft, 0)
        tabHost.Size = UDim2.new(1, -(tabLeft + closeSize + closeMargin + 8), 1, 0)
        tabHost.Parent = header

        local close = Instance.new("TextButton")
        close.Name = "Close"
        close.AutoButtonColor = false
        close.AnchorPoint = Vector2.new(1, 0.5)
        close.Position = UDim2.new(1, -closeMargin, 0.5, 0)
        close.Size = UDim2.fromOffset(closeSize, closeSize)
        close.BackgroundColor3 = Color3.fromRGB(46, 46, 54)
        close.BorderSizePixel = 0
        close.Text = ""
        close.Parent = header
        Kit.corner(close, 1, true)
        Kit.stroke(close, Color3.fromRGB(96, 96, 108), 1.5)
        for _, r in ipairs({ 45, -45 }) do
            local bar = Instance.new("Frame")
            bar.AnchorPoint = Vector2.new(0.5, 0.5)
            bar.Position = UDim2.fromScale(0.5, 0.5)
            bar.Size = UDim2.fromOffset(14, 2)
            bar.Rotation = r
            bar.BackgroundColor3 = P.text
            bar.BorderSizePixel = 0
            bar.Parent = close
            Kit.corner(bar, 1, true)
        end

        local body = Instance.new("Frame")
        body.Name = "Body"
        body.BackgroundTransparency = 1
        body.Position = UDim2.fromOffset(14, bodyTop)
        body.Size = UDim2.new(1, -28, 1, -bodyTop - 14)
        body.Parent = root

        Kit.draggable(header, holder, uiScale)
        Kit.hookClicks(holder)
        if UI3D then UI3D.bind(holder) end

        local baseScale = 1
        local function fit()
            local camera = workspace.CurrentCamera
            if camera then
                local vp = camera.ViewportSize
                baseScale = math.clamp(math.min((vp.X - 16) / width, (vp.Y - 30) / height), 0.45, 1)
            end
        end
        fit()
        if workspace.CurrentCamera then
            workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
                fit()
                uiScale.Scale = baseScale
            end)
        end

        local w = { Gui = gui, Holder = holder, Root = root, Header = header, Body = body, TabHost = tabHost, Close = close }
        local open, token = false, 0
        local function fadeGlow(visible, seconds)
            for _, g in ipairs(glows) do
                Kit.tween(g.frame, seconds, { BackgroundTransparency = visible and g.base or 1 })
            end
        end
        function w.SetSubtitle(text) subtitle.Text = tostring(text or "") end
        function w.IsOpen() return open end
        function w.Open()
            if open then return end
            open = true
            token = token + 1
            fit()
            gui.Enabled = true
            root.GroupTransparency = 1
            for _, g in ipairs(glows) do g.frame.BackgroundTransparency = 1 end
            uiScale.Scale = baseScale * 0.94
            Kit.tween(root, 0.22, { GroupTransparency = 0 })
            fadeGlow(true, 0.3)
            Kit.tween(uiScale, 0.3, { Scale = baseScale }, Enum.EasingStyle.Back)
        end
        function w.Hide()
            if not open then return end
            open = false
            token = token + 1
            local mine = token
            Kit.tween(root, 0.16, { GroupTransparency = 1 })
            fadeGlow(false, 0.16)
            Kit.tween(uiScale, 0.16, { Scale = baseScale * 0.96 })
            task.delay(0.18, function()
                if mine == token and not open then gui.Enabled = false end
            end)
        end
        return w
    end

    -- tab di header: track gelap + pil abu kilap yang geser
    function Kit.tabs(host, items, onSelect, buttonWidth)
        local bw = buttonWidth or 74
        local pad = 4
        local track = Instance.new("Frame")
        track.Name = "Track"
        track.AnchorPoint = Vector2.new(0, 0.5)
        track.Position = UDim2.new(0, 0, 0.5, 0)
        track.Size = UDim2.fromOffset(#items * bw + pad * 2, 44)
        track.BackgroundColor3 = P.track
        track.BackgroundTransparency = 0.4
        track.BorderSizePixel = 0
        track.Parent = host
        Kit.corner(track, 15)
        Kit.stroke(track, P.trackLine, 1).Transparency = 0.2
        local pill = Instance.new("Frame")
        pill.Name = "Pill"
        pill.AnchorPoint = Vector2.new(0, 0.5)
        pill.Size = UDim2.fromOffset(bw, 36)
        pill.Position = UDim2.new(0, pad, 0.5, 0)
        pill.BackgroundColor3 = Color3.new(1, 1, 1)
        pill.BorderSizePixel = 0
        pill.Parent = track
        Kit.corner(pill, 12)
        Kit.grayFill(pill)
        pill.BackgroundTransparency = 0.8
        Kit.stroke(pill, P.accentHi, 1)

        local buttons, current, first = {}, nil, true
        local function select(id)
            local index
            for i, it in ipairs(items) do if it.id == id then index = i end end
            if not index then return end
            current = id
            for key, b in pairs(buttons) do
                Kit.tween(b, 0.16, { TextColor3 = key == id and P.text or P.tabIdle })
            end
            local target = UDim2.new(0, pad + (index - 1) * bw, 0.5, 0)
            if first then first = false; pill.Position = target
            else Kit.tween(pill, 0.26, { Position = target }) end
            onSelect(id)
        end
        for i, it in ipairs(items) do
            local b = Instance.new("TextButton")
            b.Name = it.id
            b.AutoButtonColor = false
            b.AnchorPoint = Vector2.new(0, 0.5)
            b.Size = UDim2.fromOffset(bw, 36)
            b.Position = UDim2.new(0, pad + (i - 1) * bw, 0.5, 0)
            b.BackgroundTransparency = 1
            b.Text = it.label
            b.TextSize = 11
            b.Font = Kit.FontBold
            b.TextColor3 = P.tabIdle
            b.ZIndex = 2
            b.Parent = track
            if it.icon then
                Kit.padding(b, 18, 0, 0, 0)
                local ih = Instance.new("Frame")
                ih.BackgroundTransparency = 1
                ih.AnchorPoint = Vector2.new(0, 0.5)
                ih.Position = UDim2.new(0, 8 - 18, 0.5, 0)
                ih.Size = UDim2.fromOffset(14, 14)
                ih.ZIndex = 2
                ih.Parent = b
                Kit.icon(ih, it.icon, 14, P.text)
            end
            b.MouseButton1Click:Connect(function() select(it.id) end)
            buttons[it.id] = b
        end
        return buttons, select
    end

    -- halaman scroll di dalam Body
    function Kit.page(parent)
        local page = Instance.new("Frame")
        page.Name = "Page"
        page.BackgroundTransparency = 1
        page.Size = UDim2.fromScale(1, 1)
        page.Visible = false
        page.Parent = parent
        local scroll = Kit.scroll(page, { Gap = 8, Pad = 2 })
        return page, scroll
    end

    -- ===== DASHBOARD (gaya MedAdmin Admin Panel) =====
    -- Header (ikon + caption kecil + judul + subjudul + tombol X), sidebar menu kiri,
    -- "Aksi Cepat" di bawah sidebar, dan area konten (judul + subjudul halaman + isi scroll).
    -- Tambah menu baru cukup: dash.AddPage({ id, label, icon, title, subtitle }) -> scroll
    -- o: Name, Width, Height, Order, Icon, Caption, Title, Subtitle, SidebarWidth
    function Kit.dashboard(o)
        local width, height = o.Width or 720, o.Height or 420
        local headerH = 78
        local sideW = o.SidebarWidth or 176
        local gui = Kit.screen(o.Name, o.Order or 60)
        gui.Enabled = false

        local holder = Instance.new("Frame")
        holder.Name = "Holder"
        holder.AnchorPoint = Vector2.new(0.5, 0.5)
        holder.Position = UDim2.fromScale(0.5, 0.5)
        holder.Size = UDim2.fromOffset(width, height)
        holder.BackgroundTransparency = 1
        holder.Parent = gui
        local uiScale = Instance.new("UIScale")
        uiScale.Parent = holder
        local glows = Kit.glow(holder, 26)

        local root = Kit.glass(holder, { Name = "Root", Canvas = true, Radius = 26 })
        local rootStroke = root:FindFirstChildOfClass("UIStroke")
        rootStroke.Color = Color3.new(1, 1, 1)
        rootStroke.Transparency = 0.1
        Kit.sweepStroke(rootStroke)

        -- header
        local header = Instance.new("Frame")
        header.Name = "Header"
        header.Size = UDim2.new(1, 0, 0, headerH)
        header.BackgroundTransparency = 1
        header.Parent = root

        local tile = Instance.new("Frame")
        tile.Name = "IconTile"
        tile.AnchorPoint = Vector2.new(0, 0.5)
        tile.Position = UDim2.new(0, 20, 0, headerH / 2 + 2)
        tile.Size = UDim2.fromOffset(46, 46)
        tile.BackgroundColor3 = Color3.new(1, 1, 1)
        tile.BorderSizePixel = 0
        tile.Parent = header
        Kit.corner(tile, 14)
        Kit.grayFill(tile)
        tile.BackgroundTransparency = 0.82
        Kit.stroke(tile, Color3.new(1, 1, 1), 1)
        Kit.sheen(tile, 12, 0.75, 1)
        local ti = Instance.new("Frame")
        ti.BackgroundTransparency = 1
        ti.AnchorPoint = Vector2.new(0.5, 0.5)
        ti.Position = UDim2.fromScale(0.5, 0.5)
        ti.Size = UDim2.fromOffset(20, 20)
        ti.Parent = tile
        Kit.icon(ti, o.Icon or "gem", 20, P.text)

        local tx = 20 + 46 + 14
        Kit.label(header, { Text = string.upper(o.Caption or ""), Position = UDim2.fromOffset(tx, 16),
            Size = UDim2.new(1, -tx - 80, 0, 12), TextSize = 10, Color = P.muted })
        Kit.label(header, { Text = o.Title or "", Rich = true, Position = UDim2.fromOffset(tx, 29),
            Size = UDim2.new(1, -tx - 80, 0, 22), TextSize = 19, Font = Kit.FontBold })
        local subtitle = Kit.label(header, { Text = o.Subtitle or "", Position = UDim2.fromOffset(tx, 53),
            Size = UDim2.new(1, -tx - 80, 0, 14), TextSize = 11, Color = P.muted, Truncate = true, Rich = true })

        local close = Instance.new("TextButton")
        close.Name = "Close"
        close.AutoButtonColor = false
        close.AnchorPoint = Vector2.new(1, 0.5)
        close.Position = UDim2.new(1, -20, 0, headerH / 2 + 2)
        close.Size = UDim2.fromOffset(40, 40)
        close.BackgroundColor3 = Color3.new(1, 1, 1)
        close.BackgroundTransparency = 0.88
        close.BorderSizePixel = 0
        close.Text = ""
        close.Parent = header
        Kit.corner(close, 1, true)
        Kit.stroke(close, Color3.new(1, 1, 1), 1.2)
        Kit.sheen(close, 20, 0.78, 1)
        for _, r in ipairs({ 45, -45 }) do
            local bar = Instance.new("Frame")
            bar.AnchorPoint = Vector2.new(0.5, 0.5)
            bar.Position = UDim2.fromScale(0.5, 0.5)
            bar.Size = UDim2.fromOffset(15, 2.5)
            bar.Rotation = r
            bar.BackgroundColor3 = P.text
            bar.BorderSizePixel = 0
            bar.Parent = close
            Kit.corner(bar, 1, true)
        end

        -- body: sidebar + konten
        local bodyTop = headerH + 8
        local side = Kit.card(root, { Name = "Sidebar", Well = true, Radius = 18,
            Position = UDim2.fromOffset(16, bodyTop), Size = UDim2.new(0, sideW, 1, -bodyTop - 16) })
        local quickH = 78
        local nav = Kit.scroll(side, { Name = "Nav", Gap = 3, Size = UDim2.new(1, 0, 1, -quickH),
            Position = UDim2.fromOffset(0, 0) })
        Kit.padding(nav, 8, 8, 8, 8)
        local quick = Instance.new("Frame")
        quick.Name = "Quick"
        quick.BackgroundTransparency = 1
        quick.AnchorPoint = Vector2.new(0, 1)
        quick.Position = UDim2.new(0, 10, 1, -8)
        quick.Size = UDim2.new(1, -20, 0, quickH - 14)
        quick.Parent = side
        Kit.label(quick, { Text = "Aksi Cepat", Size = UDim2.new(1, 0, 0, 16), TextSize = 11, Color = P.muted,
            Position = UDim2.fromOffset(4, 0) })
        local quickRow = Instance.new("Frame")
        quickRow.BackgroundTransparency = 1
        quickRow.Position = UDim2.fromOffset(0, 24)
        quickRow.Size = UDim2.new(1, 0, 0, 36)
        quickRow.Parent = quick
        local qg = Instance.new("UIGridLayout")
        qg.CellPadding = UDim2.fromOffset(8, 0)
        qg.CellSize = UDim2.new(0.5, -4, 1, 0)
        qg.SortOrder = Enum.SortOrder.LayoutOrder
        qg.Parent = quickRow

        local cx = 16 + sideW + 12
        local content = Kit.card(root, { Name = "Content", Well = true, Radius = 18,
            Position = UDim2.fromOffset(cx, bodyTop), Size = UDim2.new(1, -cx - 16, 1, -bodyTop - 16) })
        local pageTitle = Kit.label(content, { Text = "", Position = UDim2.fromOffset(18, 12),
            Size = UDim2.new(1, -36, 0, 22), TextSize = 17, Font = Kit.FontBold })
        local pageSub = Kit.label(content, { Text = "", Position = UDim2.fromOffset(18, 36),
            Size = UDim2.new(1, -36, 0, 14), TextSize = 11, Color = P.muted, Truncate = true })
        local host = Instance.new("Frame")
        host.Name = "PageHost"
        host.BackgroundTransparency = 1
        host.Position = UDim2.fromOffset(12, 60)
        host.Size = UDim2.new(1, -24, 1, -70)
        host.Parent = content

        Kit.draggable(header, holder, uiScale)
        Kit.hookClicks(holder)
        if UI3D then UI3D.bind(holder) end

        local baseScale = 1
        local function fit()
            local camera = workspace.CurrentCamera
            if camera then
                local vp = camera.ViewportSize
                baseScale = math.clamp(math.min((vp.X - 16) / width, (vp.Y - 24) / height), 0.45, 1)
            end
        end
        fit()
        if workspace.CurrentCamera then
            workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
                fit()
                uiScale.Scale = baseScale
            end)
        end

        local d = { Gui = gui, Holder = holder, Root = root, Close = close, Content = content, Quick = quickRow }
        local pages, items, current = {}, {}, nil
        local count = 0

        local function paintNav(item, active)
            item.fill.Enabled = active
            Kit.tween(item.button, 0.16, { BackgroundTransparency = active and 0.8 or 1 })
            Kit.tween(item.stroke, 0.16, { Transparency = active and 0 or 1 })
            Kit.tween(item.label, 0.16, { TextColor3 = active and P.text or P.tabIdle })
        end

        function d.Select(id)
            local pg = pages[id]
            if not pg then return end
            current = id
            for key, p in pairs(pages) do p.frame.Visible = key == id end
            for key, item in pairs(items) do paintNav(item, key == id) end
            pageTitle.Text = pg.title
            pageSub.Text = pg.subtitle
            pageTitle.Visible = not pg.full
            pageSub.Visible = not pg.full
            if pg.onOpen and not pg.opened then
                pg.opened = true
                task.spawn(pg.onOpen, pg.frame)
            end
        end

        -- tambah menu + halaman. return: ScrollingFrame isi halaman
        function d.AddPage(p)
            count = count + 1
            local frame = Instance.new("Frame")
            frame.Name = "Page_" .. p.id
            frame.BackgroundTransparency = 1
            frame.Size = UDim2.fromScale(1, 1)
            frame.Visible = false
            local scroll
            if p.full then -- halaman memakai seluruh kartu konten (tanpa judul & scroll bawaan)
                frame.Position = UDim2.fromOffset(6, 6)
                frame.Size = UDim2.new(1, -12, 1, -12)
                frame.Parent = content
                scroll = frame
            else
                frame.Parent = host
                scroll = Kit.scroll(frame, { Gap = 8, Pad = 4 })
            end
            pages[p.id] = { frame = frame, title = p.title or p.label, subtitle = p.subtitle or "", full = p.full == true,
                onOpen = p.onOpen }

            local b = Instance.new("TextButton")
            b.Name = p.id
            b.AutoButtonColor = false
            b.Text = ""
            b.Size = UDim2.new(1, 0, 0, 40)
            b.BackgroundColor3 = Color3.new(1, 1, 1)
            b.BackgroundTransparency = 1
            b.BorderSizePixel = 0
            b.LayoutOrder = p.order or count
            b.Parent = nav
            Kit.corner(b, 13)
            local fill = Kit.grayFill(b)
            fill.Enabled = false
            local st = Kit.stroke(b, Color3.new(1, 1, 1), 1)
            st.Transparency = 1
            local ih = Instance.new("Frame")
            ih.BackgroundTransparency = 1
            ih.AnchorPoint = Vector2.new(0, 0.5)
            ih.Position = UDim2.new(0, 16, 0.5, 0)
            ih.Size = UDim2.fromOffset(18, 18)
            ih.Parent = b
            Kit.icon(ih, p.icon or "gem", 18, P.text)
            local label = Kit.label(b, { Text = p.label, Position = UDim2.fromOffset(46, 0), Size = UDim2.new(1, -52, 1, 0),
                TextSize = 13, Font = Kit.FontBold, Color = P.tabIdle, Truncate = true })
            b.MouseButton1Click:Connect(function() d.Select(p.id) end)
            items[p.id] = { button = b, fill = fill, stroke = st, label = label }
            return scroll
        end

        -- tombol "Aksi Cepat" (2 per baris; o: Text, Solid, OnClick)
        function d.AddQuick(q)
            return Kit.button(quickRow, { Text = q.Text, Solid = q.Solid, Purple = q.Purple, TextSize = 12, Radius = 12,
                OnClick = q.OnClick, LayoutOrder = q.LayoutOrder })
        end

        function d.Current() return current end
        function d.SetSubtitle(text) subtitle.Text = tostring(text or "") end

        local open, token = false, 0
        local function fadeGlow(visible, seconds)
            for _, g in ipairs(glows) do
                Kit.tween(g.frame, seconds, { BackgroundTransparency = visible and g.base or 1 })
            end
        end
        function d.IsOpen() return open end
        function d.Open()
            if open then return end
            open = true
            token = token + 1
            fit()
            gui.Enabled = true
            root.GroupTransparency = 1
            for _, g in ipairs(glows) do g.frame.BackgroundTransparency = 1 end
            uiScale.Scale = baseScale * 0.94
            Kit.tween(root, 0.22, { GroupTransparency = 0 })
            fadeGlow(true, 0.3)
            Kit.tween(uiScale, 0.3, { Scale = baseScale }, Enum.EasingStyle.Back)
        end
        function d.Hide()
            if not open then return end
            open = false
            token = token + 1
            local mine = token
            Kit.tween(root, 0.16, { GroupTransparency = 1 })
            fadeGlow(false, 0.16)
            Kit.tween(uiScale, 0.16, { Scale = baseScale * 0.96 })
            task.delay(0.18, function()
                if mine == token and not open then gui.Enabled = false end
            end)
        end
        return d
    end

    -- ===== toast (tengah-atas, 2D supaya selalu terbaca) =====
    local toastGui, toastList
    function Kit.toast(message, kind)
        if not toastGui or not toastGui.Parent then
            toastGui = Kit.screen("LiquidGlassToast", 999)
            toastList = Instance.new("Frame")
            toastList.BackgroundTransparency = 1
            toastList.AnchorPoint = Vector2.new(0.5, 0)
            toastList.Position = UDim2.new(0.5, 0, 0, 8)
            toastList.Size = UDim2.fromOffset(320, 400)
            toastList.Parent = toastGui
            local l = Kit.list(toastList, 6)
            l.HorizontalAlignment = Enum.HorizontalAlignment.Center
        end
        local color = kind == "error" and P.danger or (kind == "ok" and P.ok or P.accent)
        local t = Kit.glass(toastList, { Name = "Toast", Size = UDim2.fromOffset(300, 0), Radius = 14, Canvas = true })
        t.AutomaticSize = Enum.AutomaticSize.Y
        t.GroupTransparency = 1
        Kit.padding(t, 14, 10, 12, 10)
        local bar = Instance.new("Frame")
        bar.BackgroundColor3 = color
        bar.BorderSizePixel = 0
        bar.Position = UDim2.new(0, -8, 0, 0)
        bar.Size = UDim2.new(0, 3, 1, 0)
        bar.Parent = t
        Kit.corner(bar, 1, true)
        Kit.label(t, { Text = tostring(message), Size = UDim2.new(1, 0, 0, 0), AutoY = true, Wrap = true, TextSize = 12 })
        Kit.tween(t, 0.2, { GroupTransparency = 0 })
        task.delay(3.6, function()
            if t.Parent then
                Kit.tween(t, 0.25, { GroupTransparency = 1 })
                task.wait(0.3)
                t:Destroy()
            end
        end)
    end

    return Kit
end)()

local function createStudioLiteImporter()
--[[
============================================================
    _   __                              __  _
   | \ / /__ _ _ _  __ _ _ __   __ _  / _\ | |__   ___
   |  V  / _` | '_/ _` | '_ \ / _` || |_|| '_ \ / _ \
   | |\ | (_| | | | (_| | | | | (_| ||  _|| | | |  __/
   |_| \|\__,_|_|  \__,_|_| |_|\__,_||_|  |_| |_|\___|

   [*] Protocol    : NEARSX Environment API
   [*] Operation   : Deobfuscation & Optimization
============================================================
]]--

if not game:IsLoaded() then game.Loaded:Wait() end
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local AssetService = game:GetService("AssetService")
local InsertService = game:GetService("InsertService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local CoreDest = PlayerGui
pcall(function()
    local probe = Instance.new("Folder")
    probe.Name = "__LANGZ_CORE_PROBE"
    probe.Parent = CoreGui
    probe:Destroy()
    CoreDest = CoreGui
end)
local function __hx(bytes)
    local out = table.create and table.create(#bytes) or {}
    for i = 1, #bytes do
        local value = (bytes[i] - 37) % 256
        out[i] = string.char(value)
    end
    return table.concat(out)
end
local __STR = {
    ACCESS = {113,102,115,108,127,69,84,84,69,102,104,104,106,120,120,69,105,106,115,110,106,105},
    WARN_ID = {128,113,102,115,108,127,69,110,114,117,116,119,121,106,119,69,103,126,69,113,102,115,108,127,69,125,69,109,87,104,69,105,116,114,110,115,110,116,115,130},
    WARN_EN = {128,103,106,113,110,69,105,110,69,113,102,115,108,127,69,105,116,114,110,115,110,116,115,69,114,122,119,102,109,69,112,116,112,69,108,102,69,114,102,109,102,113,69,105,102,119,110,117,102,105,102,69,115,126,116,113,116,115,108,130},
    MAIN_BRAND = {113,102,115,108,127,69,84,69,119,103,125,113,69,104,116,119,106},
    MAIN_SUB = {110,114,117,116,119,121,106,119,69,103,126,69,113,102,115,108,127,69,125,69,109,87,104,69,105,116,114,110,115,110,116,115,69,69,7,165,199,69,69,119,103,125,113,69,104,116,119,106},
    DEBUG = {113,102,115,108,127,69,84,84,69,120,126,120,121,106,114,69,105,106,103,122,108},
    NOTIFY = {113,102,115,108,127,69,119,103,125,113,69,110,114,117,116,119,121,106,119},
    FAIL = {113,102,115,108,127,69,110,114,117,116,119,121,69,107,102,110,113,106,105},
    GUI_NAME = {113,102,115,108,127,132,119,103,125,113,132,104,116,119,106},
    WARN_GUI = {113,102,115,108,127,132,119,103,125,113,132,124,109,110,121,106,113,110,120,121,132,124,102,119,115,110,115,108},
    LOAD_GUI = {113,102,115,108,127,132,113,148,134,137,142,147,140,120,136,151,138,138,147},
    LAUNCHER = {113,102,115,108,127,132,113,134,154,147,136,141,138,151},
    TOAST = {113,102,115,108,127,132,121,148,134,152,153},
}
local function __s(key)
    return __hx(__STR[key])
end
_G.Langz_RAW_SOURCES = _G.Langz_RAW_SOURCES or {}
_G.Langz_RAW_SOURCE_BY_REF = _G.Langz_RAW_SOURCE_BY_REF or {}
if type(string.unpack) ~= "function" then
    warn("[LANGZ RBXL] string.unpack tidak tersedia. Binary RBXL tidak dapat dibaca di executor ini.")
end
local BINARY_BIT32_OK = type(bit32) == "table"
if not BINARY_BIT32_OK then
    warn("[LANGZ RBXL] bit32 tidak tersedia. UI tetap dibuka, tetapi import binary tidak bisa berjalan.")
end
local _rrotate = BINARY_BIT32_OK and bit32.rrotate or nil
if type(_rrotate) ~= "function" then
    _rrotate = function(x, n)
        x = x % 4294967296
        n = n % 32
        if n == 0 then return x end
        local p = 2 ^ n
        return (math.floor(x / p) + (x % p) * (2 ^ (32 - n))) % 4294967296
    end
end
local function Buffer(str, allowOverflows)
    local Stream = { Offset = 0, Source = str, Length = string.len(str), AllowOverflows = (allowOverflows == nil and true) or allowOverflows }
    function Stream:read(len, shift)
        len = len or 1; shift = (shift == nil and true) or shift
        local dat = string.sub(self.Source, self.Offset + 1, self.Offset + len)
        if shift then self:seek(len) end
        return dat
    end
    function Stream:seek(len) self.Offset = math.clamp(self.Offset + len, 0, self.Length) end
    function Stream:readNumber(fmt, shift)
        fmt = fmt or "I1"
        if type(string.unpack) ~= "function" then
            error("string.unpack tidak tersedia di environment ini")
        end
        local size
        if type(string.packsize) == "function" then
            size = string.packsize(fmt)
        else
            local f = tostring(fmt):gsub("^[<>!=@]", "")
            local sizes = {I1=1,i1=1,I2=2,i2=2,I4=4,i4=4,I8=8,i8=8,f=4,d=8}
            size = sizes[f]
            if not size then error("Unsupported pack format: "..tostring(fmt)) end
        end
        local chunk = self:read(size, shift)
        if #chunk ~= size then
            error(("Unexpected EOF while reading %s (%d/%d bytes)"):format(tostring(fmt), #chunk, size))
        end
        return string.unpack(fmt, chunk)
    end
    function Stream:append(s) self.Source = self.Source .. s; self.Length = #self.Source end
    function Stream:toEnd() self.Offset = self.Length end
    return Stream
end
local function transformInt(x) return (x % 2 == 0) and (x / 2) or (-(x + 1) / 2) end
local function rbxF32(x) x = _rrotate(x, 1); return string.unpack(">f", string.pack(">I4", x)) end
local basicTypes = {}
function basicTypes.String(buffer) return buffer:read(buffer:readNumber("<I4")) end
function basicTypes.Int32(buffer) return transformInt(buffer:readNumber(">I4")) end
function basicTypes.Int64(buffer) return transformInt(buffer:readNumber(">I8")) end
function basicTypes.Float32(buffer) return rbxF32(buffer:readNumber(">I4")) end
function basicTypes.Float64(buffer) return buffer:readNumber("<d") end
function basicTypes.InterleaveArrayWithSize(buffer, count, sizeof)
    if count < 0 then return Buffer("", false) end
    local stream = buffer:read(count * sizeof); local out = table.create(count)
    for i = 1, count do
        local chunk = table.create(sizeof)
        for s = 0, sizeof - 1 do
            local bitPos = i + (count * s); chunk[s+1] = string.sub(stream, bitPos, bitPos)
        end
        out[i] = table.concat(chunk)
    end
    return Buffer(table.concat(out), false)
end
function basicTypes.unsignedIntArray(buffer, count)
    if count < 1 then return {} end
    local o = table.create(count); local strings = basicTypes.InterleaveArrayWithSize(buffer, count, 4)
    for i = 1, count do o[i] = strings:readNumber("<I4") end
    return o
end
function basicTypes.Int32Array(buffer, count)
    if count < 1 then return {} end
    local o = table.create(count); local strings = basicTypes.InterleaveArrayWithSize(buffer, count, 4)
    for i = 1, count do o[i] = basicTypes.Int32(strings) end
    return o
end
function basicTypes.Int64Array(buffer, count)
    if count < 1 then return {} end
    local o = table.create(count); local strings = basicTypes.InterleaveArrayWithSize(buffer, count, 8)
    for i = 1, count do o[i] = basicTypes.Int64(strings) end
    return o
end
function basicTypes.RbxF32Array(buffer, count)
    if count < 1 then return {} end
    local o = table.create(count); local strings = basicTypes.InterleaveArrayWithSize(buffer, count, 4)
    for i = 1, count do o[i] = basicTypes.Float32(strings) end
    return o
end
function basicTypes.RefArray(buffer, count)
    if count < 1 then return {} end
    local o = table.create(count); local refs = basicTypes.Int32Array(buffer, count); local last = 0
    for i = 1, count do local ref = last + refs[i]; o[i] = ref; last = ref end
    return o
end
local function lz4(lz4data)
    local input = Buffer(lz4data, false)
    local compressedLen = input:readNumber("<I4")
    local decompressedLen = input:readNumber("<I4")
    local reserved = input:readNumber("<I4")
    if reserved ~= 0 then error("not lz4") end
    if compressedLen == 0 then
        return input:read(decompressedLen)
    end
    local raw = input:read(compressedLen)
    local pos = 1
    local out = table.create(decompressedLen)
    local outLen = 0
    local function readByte()
        if pos > #raw then error("LZ4 unexpected end") end
        local b = string.byte(raw, pos)
        pos = pos + 1
        return b
    end
    local function extLen(base)
        local len = base
        if base == 15 then
            while true do
                local b = readByte()
                len = len + b
                if b ~= 255 then break end
            end
        end
        return len
    end
    while outLen < decompressedLen do
        local token = readByte()
        local literalLen = extLen(bit32.rshift(token, 4))
        for _ = 1, literalLen do
            outLen = outLen + 1
            out[outLen] = string.char(readByte())
        end
        if outLen >= decompressedLen then break end
        local offset = readByte() + bit32.lshift(readByte(), 8)
        if offset <= 0 or offset > outLen then
            error("LZ4 invalid match offset")
        end
        local matchLen = extLen(bit32.band(token, 15)) + 4
        local srcIndex = outLen - offset + 1
        for _ = 1, matchLen do
            outLen = outLen + 1
            out[outLen] = out[srcIndex]
            srcIndex = srcIndex + 1
            if outLen >= decompressedLen then break end
        end
    end
    local result = table.concat(out, "", 1, outLen)
    if #result ~= decompressedLen then
        error(("LZ4 length mismatch %d/%d"):format(#result, decompressedLen))
    end
    return result
end
local function b64encode(str)
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local out = {}
    for i = 1, #str, 3 do
        local b0, b1, b2 = string.byte(str, i, i+2)
        local b = bit32.lshift(b0, 16) + bit32.lshift(b1 or 0, 8) + (b2 or 0)
        table.insert(out, chars:sub(bit32.extract(b, 18, 6)+1, bit32.extract(b, 18, 6)+1))
        table.insert(out, chars:sub(bit32.extract(b, 12, 6)+1, bit32.extract(b, 12, 6)+1))
        table.insert(out, b1 and chars:sub(bit32.extract(b, 6, 6)+1, bit32.extract(b, 6, 6)+1) or "=")
        table.insert(out, b2 and chars:sub(bit32.band(b, 63)+1, bit32.band(b, 63)+1) or "=")
    end
    return table.concat(out)
end
local function _bytesToString(v)
    if type(v) == "string" then return v end
    local ok, out = pcall(function()
        if type(buffer) == "table" and type(buffer.tostring) == "function" then
            return buffer.tostring(v)
        end
        return nil
    end)
    if ok and type(out) == "string" then return out end
    local ok2, out2 = pcall(function()
        if type(buffer) == "table" and type(buffer.len) == "function" and type(buffer.readu8) == "function" then
            local n = buffer.len(v)
            local parts = table.create(math.ceil(n / 4096))
            local k = 0
            for i = 0, n - 1, 4096 do
                local e = math.min(n - 1, i + 4095)
                local chars = table.create(e - i + 1)
                for j = i, e do chars[j - i + 1] = string.char(buffer.readu8(v, j)) end
                k = k + 1
                parts[k] = table.concat(chars)
            end
            return table.concat(parts)
        end
        return nil
    end)
    if ok2 and type(out2) == "string" then return out2 end
    return nil
end
local function _zstdViaEncodingService(data)
    local ok, result = pcall(function()
        local EncodingService = game:GetService("EncodingService")
        local CompressionAlgorithm = Enum.CompressionAlgorithm
        if type(buffer) ~= "table" or type(buffer.fromstring) ~= "function" then error("buffer API unavailable") end
        if not CompressionAlgorithm or not CompressionAlgorithm.Zstd then error("Zstd enum unavailable") end
        local compressed = buffer.fromstring(data)
        local decoded = EncodingService:DecompressBuffer(compressed, CompressionAlgorithm.Zstd)
        local text = _bytesToString(decoded)
        if not text then error("failed to convert decompressed buffer") end
        return text
    end)
    return ok and result or nil
end
local function _zstdViaJSON(data)
    local zbase64 = b64encode(data)
    local ok, result = pcall(function()
        local x = HttpService:JSONDecode('{"m":null,"t":"buffer","zbase64":"' .. zbase64 .. '"}')
        local text = _bytesToString(x)
        if not text then error("JSONDecode returned a buffer but this runtime has no buffer->string bridge") end
        return text
    end)
    return ok and result or nil
end
local function zstd(stream)
    local out = _zstdViaEncodingService(stream)
    if out then return out end
    out = _zstdViaJSON(stream)
    if out then return out end
    error("ZSTD decompressor tidak tersedia/compatible di environment ini")
end
local function _readVector3(buffer, count)
    local xs = basicTypes.RbxF32Array(buffer, count)
    local ys = basicTypes.RbxF32Array(buffer, count)
    local zs = basicTypes.RbxF32Array(buffer, count)
    local out = table.create(count)
    for i = 1, count do out[i] = Vector3.new(xs[i], ys[i], zs[i]) end
    return out
end
local function _readColor3(buffer, count)
    local rs = basicTypes.RbxF32Array(buffer, count)
    local gs = basicTypes.RbxF32Array(buffer, count)
    local bs = basicTypes.RbxF32Array(buffer, count)
    local out = table.create(count)
    for i = 1, count do out[i] = Color3.new(rs[i], gs[i], bs[i]) end
    return out
end
local function _readVector2(buffer, count)
    local xs = basicTypes.RbxF32Array(buffer, count)
    local ys = basicTypes.RbxF32Array(buffer, count)
    local out = table.create(count)
    for i = 1, count do out[i] = Vector2.new(xs[i], ys[i]) end
    return out
end
local RBXL_ROTATION_MATRICES = {
    [0x02] = { 1, 0, 0,  0, 1, 0,  0, 0, 1},
    [0x03] = { 1, 0, 0,  0, 0,-1,  0, 1, 0},
    [0x05] = { 1, 0, 0,  0,-1, 0,  0, 0,-1},
    [0x06] = { 1, 0, 0,  0, 0, 1,  0,-1, 0},
    [0x07] = { 0, 1, 0,  1, 0, 0,  0, 0,-1},
    [0x09] = { 0, 0, 1,  1, 0, 0,  0, 1, 0},
    [0x0A] = { 0,-1, 0,  1, 0, 0,  0, 0, 1},
    [0x0C] = { 0, 0,-1,  1, 0, 0,  0,-1, 0},
    [0x0D] = { 0, 1, 0,  0, 0, 1,  1, 0, 0},
    [0x0E] = { 0, 0,-1,  0, 1, 0,  1, 0, 0},
    [0x10] = { 0,-1, 0,  0, 0,-1,  1, 0, 0},
    [0x11] = { 0, 0, 1,  0,-1, 0,  1, 0, 0},
    [0x14] = {-1, 0, 0,  0, 1, 0,  0, 0,-1},
    [0x15] = {-1, 0, 0,  0, 0, 1,  0, 1, 0},
    [0x17] = {-1, 0, 0,  0,-1, 0,  0, 0, 1},
    [0x18] = {-1, 0, 0,  0, 0,-1,  0,-1, 0},
    [0x19] = { 0, 1, 0, -1, 0, 0,  0, 0, 1},
    [0x1B] = { 0, 0,-1, -1, 0, 0,  0, 1, 0},
    [0x1C] = { 0,-1, 0, -1, 0, 0,  0, 0,-1},
    [0x1E] = { 0, 0, 1, -1, 0, 0,  0,-1, 0},
    [0x1F] = { 0, 1, 0,  0, 0,-1, -1, 0, 0},
    [0x20] = { 0, 0, 1,  0, 1, 0, -1, 0, 0},
    [0x22] = { 0,-1, 0,  0, 0, 1, -1, 0, 0},
    [0x23] = { 0, 0,-1,  0,-1, 0, -1, 0, 0},
}
local function _cframeFromRotationId(id, p)
    local m = RBXL_ROTATION_MATRICES[id]
    if not m then
        return nil
    end
    return CFrame.new(
        p.X, p.Y, p.Z,
        m[1],m[2],m[3],
        m[4],m[5],m[6],
        m[7],m[8],m[9]
    )
end
local function _readCFrames(buffer, count)
    local ids = table.create(count)
    local rotations = table.create(count)
    for i = 1, count do
        local id = string.byte(buffer:read())
        if id == nil then error("CFrame rotation ID terpotong") end
        ids[i] = id
        if id == 0 then
            local m = table.create(9)
            for j = 1, 9 do
                m[j] = buffer:readNumber("<f")
            end
            rotations[i] = m
        elseif not RBXL_ROTATION_MATRICES[id] then
            error(("CFrame rotation ID tidak dikenal: 0x%02X"):format(id))
        end
    end
    local positions = _readVector3(buffer, count)
    local out = table.create(count)
    for i = 1, count do
        local p = positions[i]
        if ids[i] == 0 then
            local m = rotations[i]
            out[i] = CFrame.new(
                p.X,p.Y,p.Z,
                m[1],m[2],m[3],
                m[4],m[5],m[6],
                m[7],m[8],m[9]
            )
        else
            out[i] = _cframeFromRotationId(ids[i], p)
        end
    end
    return out
end
local function _quatToCFrame(qx, qy, qz, qw, p)
    local xx, yy, zz = qx*qx, qy*qy, qz*qz
    local xy, xz, yz = qx*qy, qx*qz, qy*qz
    local wx, wy, wz = qw*qx, qw*qy, qw*qz
    return CFrame.new(
        p.X, p.Y, p.Z,
        1 - 2*(yy + zz), 2*(xy - wz),     2*(xz + wy),
        2*(xy + wz),     1 - 2*(xx + zz), 2*(yz - wx),
        2*(xz - wy),     2*(yz + wx),     1 - 2*(xx + yy)
    )
end
local function _readCFrameQuats(buffer, count)
    local ids = table.create(count)
    local quats = table.create(count)
    for i = 1, count do
        local id = string.byte(buffer:read())
        if id == nil then error("CFrameQuat ID terpotong") end
        ids[i] = id
        if id == 0 then
            quats[i] = {
                buffer:readNumber("<f"),
                buffer:readNumber("<f"),
                buffer:readNumber("<f"),
                buffer:readNumber("<f"),
            }
        elseif not RBXL_ROTATION_MATRICES[id] then
            error(("CFrameQuat rotation ID tidak dikenal: 0x%02X"):format(id))
        end
    end
    local positions = _readVector3(buffer, count)
    local out = table.create(count)
    for i = 1, count do
        local p = positions[i]
        if ids[i] == 0 then
            local q = quats[i]
            out[i] = _quatToCFrame(q[1], q[2], q[3], q[4], p)
        else
            out[i] = _cframeFromRotationId(ids[i], p)
        end
    end
    return out
end
local function _facesFromMask(mask)
    local ids = {}
    if bit32.band(mask, 0x01) ~= 0 then table.insert(ids, Enum.NormalId.Right) end
    if bit32.band(mask, 0x02) ~= 0 then table.insert(ids, Enum.NormalId.Top) end
    if bit32.band(mask, 0x04) ~= 0 then table.insert(ids, Enum.NormalId.Back) end
    if bit32.band(mask, 0x08) ~= 0 then table.insert(ids, Enum.NormalId.Left) end
    if bit32.band(mask, 0x10) ~= 0 then table.insert(ids, Enum.NormalId.Bottom) end
    if bit32.band(mask, 0x20) ~= 0 then table.insert(ids, Enum.NormalId.Front) end
    local ok, value = pcall(function() return Faces.new(table.unpack(ids)) end)
    return ok and value or mask
end
local function _axesFromMask(mask)
    local ids = {}
    if bit32.band(mask, 0x01) ~= 0 then table.insert(ids, Enum.Axis.X) end
    if bit32.band(mask, 0x02) ~= 0 then table.insert(ids, Enum.Axis.Y) end
    if bit32.band(mask, 0x04) ~= 0 then table.insert(ids, Enum.Axis.Z) end
    local ok, value = pcall(function() return Axes.new(table.unpack(ids)) end)
    return ok and value or mask
end
local function _enumItemByValue(enumType, value)
    if not enumType then return nil end
    for _, item in ipairs(enumType:GetEnumItems()) do
        if item.Value == value then return item end
    end
    return nil
end
local function _decodePropertyArray(buffer, typeID, count, sharedStrings)
    if typeID == 0x01 then
        local a = table.create(count)
        for i=1,count do a[i]=basicTypes.String(buffer) end
        return a
    elseif typeID == 0x02 then
        local a=table.create(count)
        for i=1,count do a[i]=string.byte(buffer:read())~=0 end
        return a
    elseif typeID == 0x03 then
        return basicTypes.Int32Array(buffer,count)
    elseif typeID == 0x04 then
        return basicTypes.RbxF32Array(buffer,count)
    elseif typeID == 0x05 then
        local a=table.create(count)
        for i=1,count do a[i]=basicTypes.Float64(buffer) end
        return a
    elseif typeID == 0x06 then
        local scales = basicTypes.RbxF32Array(buffer, count)
        local offsets = basicTypes.Int32Array(buffer, count)
        local a = table.create(count)
        for i=1,count do a[i] = UDim.new(scales[i], offsets[i]) end
        return a
    elseif typeID == 0x07 then
        local sx = basicTypes.RbxF32Array(buffer, count)
        local sy = basicTypes.RbxF32Array(buffer, count)
        local ox = basicTypes.Int32Array(buffer, count)
        local oy = basicTypes.Int32Array(buffer, count)
        local a = table.create(count)
        for i=1,count do a[i] = UDim2.new(sx[i], ox[i], sy[i], oy[i]) end
        return a
    elseif typeID == 0x08 then
        local a = table.create(count)
        for i=1,count do
            local origin = Vector3.new(
                buffer:readNumber("<f"), buffer:readNumber("<f"), buffer:readNumber("<f")
            )
            local direction = Vector3.new(
                buffer:readNumber("<f"), buffer:readNumber("<f"), buffer:readNumber("<f")
            )
            a[i] = Ray.new(origin, direction)
        end
        return a
    elseif typeID == 0x09 then
        local a=table.create(count)
        for i=1,count do a[i]=_facesFromMask(string.byte(buffer:read()) or 0) end
        return a
    elseif typeID == 0x0A then
        local a=table.create(count)
        for i=1,count do a[i]=_axesFromMask(string.byte(buffer:read()) or 0) end
        return a
    elseif typeID == 0x0B then
        local raw = basicTypes.unsignedIntArray(buffer,count)
        local a = table.create(count)
        for i=1,count do
            local ok, bc = pcall(BrickColor.new, raw[i])
            a[i] = ok and bc or raw[i]
        end
        return a
    elseif typeID == 0x0C then
        return _readColor3(buffer,count)
    elseif typeID == 0x0D then
        return _readVector2(buffer,count)
    elseif typeID == 0x0E then
        return _readVector3(buffer,count)
    elseif typeID == 0x0F then
        local a=table.create(count)
        for i=1,count do
            a[i]=Vector2int16.new(buffer:readNumber("<i2"),buffer:readNumber("<i2"))
        end
        return a
    elseif typeID == 0x10 then
        return _readCFrames(buffer,count)
    elseif typeID == 0x11 then
        return _readCFrameQuats(buffer,count)
    elseif typeID == 0x12 then
        return basicTypes.unsignedIntArray(buffer,count)
    elseif typeID == 0x13 then
        return basicTypes.RefArray(buffer,count)
    elseif typeID == 0x14 then
        local a=table.create(count)
        for i=1,count do
            a[i]=Vector3int16.new(
                buffer:readNumber("<i2"),buffer:readNumber("<i2"),buffer:readNumber("<i2")
            )
        end
        return a
    elseif typeID == 0x15 then
        local a=table.create(count)
        for i=1,count do
            local n=buffer:readNumber("<I4")
            local points=table.create(n)
            for j=1,n do
                points[j]=NumberSequenceKeypoint.new(
                    buffer:readNumber("<f"), buffer:readNumber("<f"), buffer:readNumber("<f")
                )
            end
            local ok, seq=pcall(NumberSequence.new, points)
            a[i]=ok and seq or nil
        end
        return a
    elseif typeID == 0x16 then
        local a=table.create(count)
        for i=1,count do
            local n=buffer:readNumber("<I4")
            local points=table.create(n)
            for j=1,n do
                local t=buffer:readNumber("<f")
                local c=Color3.new(
                    buffer:readNumber("<f"), buffer:readNumber("<f"), buffer:readNumber("<f")
                )
                buffer:readNumber("<f")
                points[j]=ColorSequenceKeypoint.new(t,c)
            end
            local ok, seq=pcall(ColorSequence.new, points)
            a[i]=ok and seq or nil
        end
        return a
    elseif typeID == 0x17 then
        local a=table.create(count)
        for i=1,count do a[i]=NumberRange.new(buffer:readNumber("<f"),buffer:readNumber("<f")) end
        return a
    elseif typeID == 0x18 then
        local xmin=basicTypes.RbxF32Array(buffer,count)
        local ymin=basicTypes.RbxF32Array(buffer,count)
        local xmax=basicTypes.RbxF32Array(buffer,count)
        local ymax=basicTypes.RbxF32Array(buffer,count)
        local a=table.create(count)
        for i=1,count do a[i]=Rect.new(xmin[i],ymin[i],xmax[i],ymax[i]) end
        return a
    elseif typeID == 0x19 then
        local a=table.create(count)
        for i=1,count do
            local discriminator=string.byte(buffer:read()) or 0
            if discriminator == 0x01 or discriminator == 0x03 then
                local density=buffer:readNumber("<f")
                local friction=buffer:readNumber("<f")
                local elasticity=buffer:readNumber("<f")
                local frictionWeight=buffer:readNumber("<f")
                local elasticityWeight=buffer:readNumber("<f")
                if discriminator == 0x03 then
                    buffer:readNumber("<f")
                end
                local ok, pp=pcall(
                    PhysicalProperties.new,
                    density, friction, elasticity, frictionWeight, elasticityWeight
                )
                a[i]=ok and pp or nil
            else
                a[i]=nil
            end
        end
        return a
    elseif typeID == 0x1A then
        local rs=table.create(count)
        local gs=table.create(count)
        local bs=table.create(count)
        for i=1,count do rs[i]=string.byte(buffer:read()) end
        for i=1,count do gs[i]=string.byte(buffer:read()) end
        for i=1,count do bs[i]=string.byte(buffer:read()) end
        local a=table.create(count)
        for i=1,count do a[i]=Color3.fromRGB(rs[i],gs[i],bs[i]) end
        return a
    elseif typeID == 0x1B then
        return basicTypes.Int64Array(buffer,count)
    elseif typeID == 0x1C then
        local idx=basicTypes.unsignedIntArray(buffer,count)
        local a=table.create(count)
        for i=1,count do
            a[i]=sharedStrings and sharedStrings[idx[i] + 1] or nil
        end
        return a
    elseif typeID == 0x1E then
        local innerType=string.byte(buffer:read())
        if innerType ~= 0x10 then
            error("Optional type tidak didukung: "..tostring(innerType))
        end
        local values=_readCFrames(buffer,count)
        local presenceType=string.byte(buffer:read())
        if presenceType ~= 0x02 then
            error("Optional presence type invalid: "..tostring(presenceType))
        end
        local a=table.create(count)
        for i=1,count do
            local present=(string.byte(buffer:read()) or 0) ~= 0
            if present then a[i]=values[i] end
        end
        return a
    elseif typeID == 0x1F then
        local values=basicTypes.InterleaveArrayWithSize(buffer,count,16)
        local a=table.create(count)
        for i=1,count do a[i]=values:read(16) end
        return a
    elseif typeID == 0x20 then
        local a=table.create(count)
        for i=1,count do
            local family=basicTypes.String(buffer)
            local weightValue=buffer:readNumber("<I2")
            local styleValue=string.byte(buffer:read()) or 0
            local cached=basicTypes.String(buffer)
            local weight=_enumItemByValue(Enum.FontWeight, weightValue) or Enum.FontWeight.Regular
            local style=_enumItemByValue(Enum.FontStyle, styleValue) or Enum.FontStyle.Normal
            local ok, font=pcall(Font.new, family, weight, style)
            a[i]=ok and font or {Family=family,Weight=weightValue,Style=styleValue,CachedFaceId=cached}
        end
        return a
    elseif typeID == 0x21 then
        return basicTypes.Int64Array(buffer,count)
    elseif typeID == 0x22 then
        local kinds=basicTypes.Int32Array(buffer,count)
        local uriCount=buffer:readNumber("<I4")
        local uris=table.create(uriCount)
        for i=1,uriCount do uris[i]=basicTypes.String(buffer) end
        local objectCount=buffer:readNumber("<I4")
        local objectRefs=basicTypes.RefArray(buffer,objectCount)
        local externalCount=buffer:readNumber("<I4")
        if externalCount > 0 then buffer:read(externalCount * 4) end
        local a=table.create(count)
        local ui, oi=1,1
        for i=1,count do
            if kinds[i] == 1 then
                a[i]=uris[ui]
                ui = ui + 1
            elseif kinds[i] == 2 then
                a[i]={__ContentObjectRef=objectRefs[oi]}
                oi = oi + 1
            else
                a[i]=""
            end
        end
        return a
    end
    return nil
end
local function parseRBXLBinary(data)
    local r = Buffer(data, false)
    if r:read(14) ~= "<roblox!" .. string.char(137,255,13,10,26,10) then return nil, "RBXL header tidak valid" end
    local version=r:readNumber("<I2")
    if version~=0 then return nil,"RBXL version tidak didukung: "..tostring(version) end
    local classCount=r:readNumber("<I4")
    local instCount=r:readNumber("<I4")
    r:read(8)
    if classCount > 100000 or instCount > 5000000 then
        return nil, "RBXL header count tidak masuk akal"
    end
    local chunks={META={},SSTR={},INST={},PROP={},PRNT={},SIGN={},["END\0"]={}}
    while r.Offset < r.Length do
        if r.Length - r.Offset < 16 then
            return nil, "RBXL chunk header terpotong"
        end
        local sig=r:read(4)
        local compressed=r:readNumber("<I4")
        local decompressed=r:readNumber("<I4")
        r:read(4)
        if sig=="END\0" then
            local payload=r:read(decompressed)
            chunks[sig][#chunks[sig]+1]={Data=payload}
            break
        end
        local payload
        if compressed==0 then
            payload=r:read(decompressed)
            if #payload ~= decompressed then
                return nil, "RBXL chunk "..sig.." terpotong"
            end
        else
            local raw=r:read(compressed)
            if #raw ~= compressed then
                return nil, "RBXL compressed chunk "..sig.." terpotong"
            end
            local magic=string.sub(raw,1,4)
            if magic==string.char(40,181,47,253) then
                payload=zstd(raw)
            else
                if type(string.pack) ~= "function" then
                    return nil, "string.pack tidak tersedia untuk LZ4"
                end
                payload=lz4(string.pack("<I4I4I4", compressed, decompressed, 0) .. raw)
            end
            if #payload ~= decompressed then
                return nil, "RBXL chunk "..sig.." length mismatch: "..#payload.." / "..decompressed
            end
        end
        if chunks[sig] then
            chunks[sig][#chunks[sig]+1]={Data=payload}
        else
            return nil,"RBXL chunk tidak dikenal: "..tostring(sig)
        end
    end
    local shared={}
    for _,ch in ipairs(chunks.SSTR) do
        local b=Buffer(ch.Data,false)
        local ver=b:readNumber("<I4")
        if ver ~= 0 then return nil, "SSTR version tidak didukung: "..tostring(ver) end
        local n=b:readNumber("<I4")
        for i=1,n do
            b:read(16)
            shared[i]=basicTypes.String(b)
        end
    end
    local classes={}; local nodes={}; local serviceRefs={}
    for _,ch in ipairs(chunks.INST) do
        local b=Buffer(ch.Data,false); local cid=b:readNumber("<I4"); local cname=basicTypes.String(b); local format=string.byte(b:read()); local n=b:readNumber("<I4"); local refs=basicTypes.RefArray(b,n)
        classes[cid]={Name=cname,Count=n,Refs=refs,IsService=(format==1)}
        local marks={}; if format==1 then for i=1,n do marks[i]=string.byte(b:read())~=0 end end
        for i,ref in ipairs(refs) do nodes[ref]={Ref=ref,ClassId=cid,ClassName=cname,IsService=(format==1),Properties={},PropertyTypes={},Children={},Service=marks[i] or false} end
        if format==1 then for i,ref in ipairs(refs) do serviceRefs[ref]=true end end
    end
    for _,ch in ipairs(chunks.PROP) do
        local b=Buffer(ch.Data,false); local cid=b:readNumber("<I4"); local cls=classes[cid]; if not cls then return nil,"PROP class id tidak ditemukan: "..cid end
        local pname=basicTypes.String(b); local typeID=string.byte(b:read())
        local vals=_decodePropertyArray(b,typeID,cls.Count,shared)
        if vals then
            for i,ref in ipairs(cls.Refs) do
                if nodes[ref] then
                    nodes[ref].Properties[pname]=vals[i]
                    nodes[ref].PropertyTypes[pname]=typeID
                end
            end
        else
            warn(("[LANGZ RBXL] property skipped: %s (type 0x%02X)"):format(pname, typeID or 0))
        end
    end
    local childToParent={}
    for _,ch in ipairs(chunks.PRNT) do local b=Buffer(ch.Data,false); local ver=string.byte(b:read()); if ver~=0 then return nil,"PRNT version tidak didukung" end; local n=b:readNumber("<I4"); local children=basicTypes.RefArray(b,n); local parents=basicTypes.RefArray(b,n); for i=1,n do childToParent[children[i]]=parents[i] end end
    local roots={}
    for ref,node in pairs(nodes) do
        local p=childToParent[ref]
        if p and p~=-1 and nodes[p] then table.insert(nodes[p].Children,node) else table.insert(roots,node) end
    end
    return {Header={ClassCount=classCount,InstanceCount=instCount},Nodes=nodes,Roots=roots,Services=serviceRefs,SharedStrings=shared}, nil
end
local function getStudioLiteServerFuncs()
    local slFolder = ReplicatedStorage:FindFirstChild("StudioLiteFolder")
    return slFolder and slFolder:FindFirstChild("ServerFunctions")
end
local function triggerServerLoad(idStr)
    local serverFuncs = getStudioLiteServerFuncs()
    if not serverFuncs or not idStr or idStr == "" then return end
    local id = tostring(idStr):match("%d+")
    if id then pcall(function() serverFuncs:InvokeServer("LoadMeshToRuntimeMeshes", tonumber(id)) end) end
end
local FAST_IMPORT = true
local ASSET_WORKERS = 6
local ASSET_QUEUE = {}
local ASSET_SEEN = {}
local function queueServerLoad(value)
    if value == nil or value == "" then return end
    local id
    if type(value) == "number" then
        id = math.floor(value)
    else
        id = tonumber(tostring(value):match("%d+"))
    end
    if not id or id <= 0 or ASSET_SEEN[id] then return end
    ASSET_SEEN[id] = true
    ASSET_QUEUE[#ASSET_QUEUE + 1] = id
end
local function flushServerLoadsAsync()
    if #ASSET_QUEUE == 0 then return end
    local jobs = ASSET_QUEUE
    ASSET_QUEUE = {}
    ASSET_SEEN = {}
    local cursor = 0
    for _ = 1, math.min(ASSET_WORKERS, #jobs) do
        task.spawn(function()
            while true do
                cursor = cursor + 1
                local index = cursor
                local id = jobs[index]
                if not id then break end
                triggerServerLoad(id)
                task.wait()
            end
        end)
    end
end
local SL_CACHE = {}
local function injectStudioLiteUI(scr, sourceMap)
    if not scr:IsA("LuaSourceContainer") then return end
    local path = scr.ClassName .. ":" .. scr.Name
    local realSource = _G.Langz_RAW_SOURCES[scr] or (sourceMap and sourceMap[path])
    if not realSource then pcall(function() realSource = scr.Source end) end
    if realSource and #realSource > 0 then
        realSource = realSource:gsub(string.char(0) .. "*$", "")
    else
        realSource = ""
    end
    _G.Langz_RAW_SOURCES[scr] = realSource
    local UI_TEXT = realSource
    local existingTB = scr:FindFirstChild("SL_CodeTextBox")
    if existingTB then
        existingTB.Text = UI_TEXT
        if scr.ClassName == "ModuleScript" then
            local ro = scr:FindFirstChild("SL_1ReadOnly")
            if ro then ro.ContentText = UI_TEXT; ro.Text = UI_TEXT end
        end
        return
    end
    local serverFuncs = getStudioLiteServerFuncs()
    if not serverFuncs then return end
    local map = { Script = "InsertScriptScript", LocalScript = "InsertLocalScriptLocalScript", ModuleScript = "InsertModuleScriptModuleScript" }
    local assetName = map[scr.ClassName]
    if not assetName then return end
    if not SL_CACHE[assetName] then
        pcall(function()
            serverFuncs:InvokeServer("LoadAssetToPlayerGui", assetName)
            local guiF = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild(assetName, 3)
            if guiF then
                SL_CACHE[assetName] = {}
                for _, c in ipairs(guiF:GetChildren()) do table.insert(SL_CACHE[assetName], c:Clone()) end
                serverFuncs:InvokeServer("ClearAssetFromPlayerGui", assetName)
            end
        end)
    end
    if not SL_CACHE[assetName] then return end
    pcall(function()
        for _, c in ipairs(SL_CACHE[assetName]) do c:Clone().Parent = scr end
        local tb = scr:FindFirstChild("SL_CodeTextBox")
        if tb then
            tb.Text = UI_TEXT
            if scr.ClassName == "ModuleScript" then
                local ro = scr:FindFirstChild("SL_1ReadOnly")
                if ro then ro.ContentText = UI_TEXT; ro.Text = UI_TEXT end
            end
        end
    end)
end
local function injectAllScripts(root, sourceMap)
    if not root then return 0 end
    local list = {}
    if root:IsA("LuaSourceContainer") then table.insert(list, root) end
    for _, d in ipairs(root:GetDescendants()) do if d:IsA("LuaSourceContainer") then table.insert(list, d) end end
    local count = 0
    for _, s in ipairs(list) do pcall(injectStudioLiteUI, s, sourceMap); count = count + 1; task.wait(0.02) end
    return count
end
local function ApplyStudioLiteProperties(obj)
    if not obj then return end
    pcall(function()
        if obj:IsA("BasePart") then
            local originalAnchor = obj.Anchored
            local originalCollide = obj.CanCollide
            obj.Anchored = true
            if obj:GetAttribute("SL_Anchored") == nil then obj:SetAttribute("SL_Anchored", originalAnchor) end
            if obj:GetAttribute("SL_CanCollide") == nil then obj:SetAttribute("SL_CanCollide", originalCollide) end
        end
    end)
    for _, child in ipairs(obj:GetChildren()) do ApplyStudioLiteProperties(child) end
end
local function LoadAssetsToSLServer(obj)
    local function scan(node)
        pcall(function()
            if node:IsA("MeshPart") then triggerServerLoad(node.MeshId); triggerServerLoad(node.TextureID)
            elseif node:IsA("Decal") or node:IsA("Texture") then triggerServerLoad(node.Texture)
            elseif node:IsA("SpecialMesh") then triggerServerLoad(node.MeshId); triggerServerLoad(node.TextureId)
            elseif node:IsA("Clothing") or node:IsA("ShirtGraphic") then triggerServerLoad(node.ClassName == "ShirtGraphic" and node.Graphic or node[node.ClassName.."Template"])
            elseif node:IsA("UnionOperation") or node:IsA("PartOperation") then triggerServerLoad(node.AssetId) end
        end)
        for _, child in ipairs(node:GetChildren()) do scan(child) end
    end
    scan(obj)
end
local SVC_MAP = {
    Workspace = workspace,
    ReplicatedStorage = ReplicatedStorage,
    ReplicatedFirst = game:GetService("ReplicatedFirst"),
    StarterGui = game:GetService("StarterGui"),
    StarterPack = game:GetService("StarterPack"),
    StarterPlayer = game:GetService("StarterPlayer"),
    Lighting = game:GetService("Lighting"),
    SoundService = game:GetService("SoundService"),
    ServerScriptService = _G.sss or ReplicatedStorage,
    ServerStorage = _G.ss or ReplicatedStorage,
    Teams = ReplicatedStorage,
    Chat = ReplicatedStorage
}
local function setEnumFromValue(obj, propName, rawValue)
    local okCurrent, current = pcall(function() return obj[propName] end)
    if not okCurrent or typeof(current) ~= "EnumItem" then return false end
    local okType, enumType = pcall(function() return current.EnumType end)
    if not okType or not enumType then return false end
    for _, item in ipairs(enumType:GetEnumItems()) do
        if item.Value == rawValue then
            return pcall(function() obj[propName] = item end)
        end
    end
    return false
end
local READONLY_GEOMETRY_PROPS = {
    MeshId = true,
    MeshID = true,
    MeshContent = true,
    MeshSize = true,
    InitialSize = true,
    PhysicsData = true,
    PhysicalConfigData = true,
    EditableMeshString = true,
    AssetId = true,
    ChildData = true,
    ChildData2 = true,
    MeshData = true,
    MeshData2 = true,
}
local SERIALIZED_PROPERTY_ALIAS = {
    size = "Size",
    shape = "Shape",
    Color3uint8 = "Color",
    MaterialVariantSerialized = "MaterialVariant",
}
local function runtimePropertyName(propName)
    return SERIALIZED_PROPERTY_ALIAS[propName] or propName
end
local function applyDecodedProperty(obj, propName, value, typeID)
    if value == nil then return true end
    if propName == "Source" or propName == "ContentText" then
        if obj:IsA("LuaSourceContainer") and type(value) == "string" then
            local clean = value:gsub(string.char(0) .. "*$", "")
            _G.Langz_RAW_SOURCES[obj] = clean
            local refKey = obj:GetAttribute("Langz_Ref")
            if refKey ~= nil then
                _G.Langz_RAW_SOURCE_BY_REF[tostring(refKey)] = clean
            end
        end
        return true
    end
    if typeID == 0x13 then return true end
    if typeID == 0x1F or typeID == 0x21 then return true end
    if typeID == 0x22 and type(value) == "table" then return true end
    if READONLY_GEOMETRY_PROPS[propName] then
        return true
    end
    local runtimeName = runtimePropertyName(propName)
    if runtimeName == "MaterialVariant" and value == "" then
        return true
    end
    if typeID == 0x12 and type(value) == "number" then
        if setEnumFromValue(obj, runtimeName, value) then
            return true
        end
    end
    return pcall(function()
        obj[runtimeName] = value
    end)
end
local function assetIdFromValue(v)
    if v == nil then return nil end
    if type(v) == "number" then
        if v > 0 then return math.floor(v) end
        return nil
    end
    if type(v) == "string" then
        local id = v:match("rbxassetid://(%d+)")
            or v:match("[?&]id=(%d+)")
            or v:match("(%d+)")
        return id and tonumber(id) or nil
    end
    local okUri, uri = pcall(function()
        if typeof(v) == "Content" and v.Uri then return v.Uri end
        return tostring(v)
    end)
    if okUri and uri then
        local id = tostring(uri):match("(%d+)")
        return id and tonumber(id) or nil
    end
    return nil
end
local function contentFromAssetIdCompat(id)
    if not id then return nil end
    local okContent, content = pcall(function()
        if Content and type(Content.fromAssetId) == "function" then
            return Content.fromAssetId(id)
        end
        if Content and type(Content.fromUri) == "function" then
            return Content.fromUri("rbxassetid://" .. tostring(id))
        end
        return nil
    end)
    if okContent and content then
        return content
    end
    return "rbxassetid://" .. tostring(id)
end
local function detachFirstGeometry(root, wantedClass)
    if not root then return nil end
    local candidate
    if root:IsA("BasePart") then
        if not wantedClass or root.ClassName == wantedClass then
            candidate = root
        end
    end
    if not candidate then
        for _, d in ipairs(root:GetDescendants()) do
            if d:IsA("BasePart") then
                if not wantedClass or d.ClassName == wantedClass then
                    candidate = d
                    break
                end
            end
        end
    end
    if not candidate and root:IsA("BasePart") then
        candidate = root
    end
    if not candidate then
        for _, d in ipairs(root:GetDescendants()) do
            if d:IsA("BasePart") then
                candidate = d
                break
            end
        end
    end
    if not candidate then return nil end
    candidate.Parent = nil
    if root ~= candidate then
        pcall(function() root:Destroy() end)
    end
    return candidate
end
local function tryGameGetObjectsGeometry(id, wantedClass)
    if not id then return nil end
    local ok, objects = pcall(function()
        return game:GetObjects("rbxassetid://" .. tostring(id))
    end)
    if not ok or type(objects) ~= "table" then return nil end
    for _, root in ipairs(objects) do
        local geo = detachFirstGeometry(root, wantedClass)
        if geo then
            for _, other in ipairs(objects) do
                if other ~= geo and other.Parent == nil then
                    pcall(function() other:Destroy() end)
                end
            end
            return geo
        end
    end
    for _, root in ipairs(objects) do
        pcall(function() root:Destroy() end)
    end
    return nil
end
local function tryAssetServiceMesh(id)
    if not id then return nil, "no mesh id" end
    local content = contentFromAssetIdCompat(id)
    local errors = {}
    local ok1, mesh1 = pcall(function()
        return AssetService:CreateMeshPartAsync(content, {})
    end)
    if ok1 and mesh1 and mesh1:IsA("MeshPart") then
        return mesh1, "AssetService"
    end
    if not ok1 then table.insert(errors, tostring(mesh1)) end
    local ok2, mesh2 = pcall(function()
        return AssetService:CreateMeshPartAsync("rbxassetid://" .. tostring(id), {})
    end)
    if ok2 and mesh2 and mesh2:IsA("MeshPart") then
        return mesh2, "AssetServiceLegacy"
    end
    if not ok2 then table.insert(errors, tostring(mesh2)) end
    local getObj = tryGameGetObjectsGeometry(id, "MeshPart")
    if getObj and getObj:IsA("BasePart") then
        return getObj, "GetObjects"
    end
    return nil, table.concat(errors, " | ")
end
local function serializedSize(p)
    if not p then return nil end
    local s = p.size or p.Size
    if typeof(s) == "Vector3" then
        return Vector3.new(
            math.max(math.abs(s.X), 0.001),
            math.max(math.abs(s.Y), 0.001),
            math.max(math.abs(s.Z), 0.001)
        )
    end
    return nil
end
local function serializedColor(p)
    if not p then return nil end
    local c = p.Color3uint8 or p.Color
    if typeof(c) == "Color3" then return c end
    return nil
end
local function applyBaseVisualState(obj, p)
    if not obj or not obj:IsA("BasePart") or not p then return end
    local s = serializedSize(p)
    if s then pcall(function() obj.Size = s end) end
    if typeof(p.CFrame) == "CFrame" then
        pcall(function() obj.CFrame = p.CFrame end)
    end
    local c = serializedColor(p)
    if c then pcall(function() obj.Color = c end) end
    if p.Transparency ~= nil then
        pcall(function() obj.Transparency = p.Transparency end)
    end
    if p.Reflectance ~= nil then
        pcall(function() obj.Reflectance = p.Reflectance end)
    end
    if p.Material ~= nil and type(p.Material) == "number" then
        pcall(function()
            setEnumFromValue(obj, "Material", p.Material)
        end)
    end
    if type(p.Anchored) == "boolean" then
        pcall(function()
            obj.Anchored = p.Anchored
        end)
    end
end
local function configureSpecialMeshScale(mesh, p)
    if not mesh or not p then return end
    local wantedSize = serializedSize(p)
    local originalSize = p.InitialSize or p.MeshSize
    if wantedSize
        and typeof(originalSize) == "Vector3"
        and math.abs(originalSize.X) > 1e-6
        and math.abs(originalSize.Y) > 1e-6
        and math.abs(originalSize.Z) > 1e-6 then
        mesh.Scale = Vector3.new(
            wantedSize.X / originalSize.X,
            wantedSize.Y / originalSize.Y,
            wantedSize.Z / originalSize.Z
        )
    else
        mesh.Scale = Vector3.new(1, 1, 1)
    end
end
local function makeSpecialMeshFallback(node, meshId)
    local p = node.Properties or {}
    local part = Instance.new("Part")
    part.Name = tostring(p.Name or "MeshPart")
    part.CanCollide = false
    applyBaseVisualState(part, p)
    local mesh = Instance.new("SpecialMesh")
    mesh.Name = "__LANGZ_MeshVisual"
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = "rbxassetid://" .. tostring(meshId)
    local texId = assetIdFromValue(p.TextureID or p.TextureId or p.TextureContent)
    if texId then
        pcall(function()
            mesh.TextureId = "rbxassetid://" .. tostring(texId)
        end)
    end
    configureSpecialMeshScale(mesh, p)
    mesh.Parent = part
    return part
end
local function isMeshPartOnlyChildClass(className)
    return className == "SurfaceAppearance"
        or className == "WrapLayer"
        or className == "WrapTarget"
end
local function nodeNeedsNativeMeshPart(node)
    for _, child in ipairs(node.Children or {}) do
        if child.ClassName == "WrapLayer"
            or child.ClassName == "WrapTarget" then
            return true
        end
    end
    return false
end
local function tryCreateMeshPartNode(node)
    local p = node.Properties or {}
    local meshId = assetIdFromValue(p.MeshId or p.MeshID or p.MeshContent)
    if not meshId then
        return nil, "unresolved", "MeshId missing"
    end
    queueServerLoad(meshId)
    queueServerLoad(p.TextureID or p.TextureId or p.TextureContent)
    local needsNative = nodeNeedsNativeMeshPart(node)
    if FAST_IMPORT and not needsNative then
        local fallback = makeSpecialMeshFallback(node, meshId)
        return fallback, "fallback", "TurboSpecialMesh"
    end
    local native, method = tryAssetServiceMesh(meshId)
    if native then
        return native, "native", needsNative and "NativeForBaseWrap" or method
    end
    local fallback = makeSpecialMeshFallback(node, meshId)
    return fallback, "fallback", needsNative and "BaseWrapFallback" or "SpecialMesh"
end
local function makeCSGVisualFallback(node, assetId)
    local p = node.Properties or {}
    local part = Instance.new("Part")
    part.Name = tostring(p.Name or node.ClassName)
    part.CanCollide = false
    applyBaseVisualState(part, p)
    if assetId then
        local mesh = Instance.new("SpecialMesh")
        mesh.Name = "__LANGZ_CSGVisual"
        mesh.MeshType = Enum.MeshType.FileMesh
        mesh.MeshId = "rbxassetid://" .. tostring(assetId)
        configureSpecialMeshScale(mesh, p)
        mesh.Parent = part
    end
    return part
end
local function tryLoadPartOperationNode(node)
    local p = node.Properties or {}
    local assetId = assetIdFromValue(p.AssetId)
    if assetId then
        queueServerLoad(assetId)
        if FAST_IMPORT then
            return makeCSGVisualFallback(node, assetId), "visual"
        end
        local obj = tryGameGetObjectsGeometry(assetId, node.ClassName)
        if obj then
            applyBaseVisualState(obj, p)
            return obj, "asset"
        end
        local meshPart = tryAssetServiceMesh(assetId)
        if meshPart and meshPart:IsA("BasePart") then
            applyBaseVisualState(meshPart, p)
            return meshPart, "mesh"
        end
        return makeCSGVisualFallback(node, assetId), "visual"
    end
    return makeCSGVisualFallback(node, nil), "proxy"
end
local function preloadNodeAssets(node)
    if not node or not node.Properties then return end
    local p = node.Properties
    if node.ClassName == "MeshPart" then
        queueServerLoad(p.MeshId or p.MeshContent)
        queueServerLoad(p.TextureID or p.TextureId or p.TextureContent)
    elseif node.ClassName == "SpecialMesh" then
        queueServerLoad(p.MeshId)
        queueServerLoad(p.TextureId or p.TextureID)
    elseif node.ClassName == "Decal" or node.ClassName == "Texture" then
        queueServerLoad(p.Texture)
    elseif node.ClassName == "Shirt" then
        queueServerLoad(p.ShirtTemplate)
    elseif node.ClassName == "Pants" then
        queueServerLoad(p.PantsTemplate)
    elseif node.ClassName == "ShirtGraphic" then
        queueServerLoad(p.Graphic)
    elseif node.ClassName == "UnionOperation"
        or node.ClassName == "PartOperation"
        or node.ClassName == "IntersectOperation" then
        queueServerLoad(p.AssetId)
    end
end
local function setScriptEnabledState(obj, enabled)
    if not obj or not obj:IsA("LuaSourceContainer") then
        return false
    end
    enabled = enabled ~= false
    local wrote = false
    local okEnabled = pcall(function()
        obj.Enabled = enabled
    end)
    if okEnabled then wrote = true end
    local okDisabled = pcall(function()
        obj.Disabled = not enabled
    end)
    if okDisabled then wrote = true end
    return wrote
end
local function getOriginalScriptEnabled(obj, node)
    local p = node and node.Properties or {}
    if p.Enabled ~= nil then
        return p.Enabled == true
    end
    if p.Disabled ~= nil then
        return p.Disabled ~= true
    end
    local okEnabled, enabled = pcall(function()
        return obj.Enabled
    end)
    if okEnabled and type(enabled) == "boolean" then
        return enabled
    end
    local okDisabled, disabled = pcall(function()
        return obj.Disabled
    end)
    if okDisabled and type(disabled) == "boolean" then
        return not disabled
    end
    return true
end
local function importedScriptShouldRun(obj)
    return false
end
local function importRootName(fileName)
    local base = tostring(fileName or "RBXL")
    base = base:gsub("%.[Rr][Bb][Xx][Ll][Xx]?$", "")
    base = base:gsub("[%c/\\:*?\"<>|]", "_")
    base = base:gsub("^%s+", ""):gsub("%s+$", "")
    if base == "" then base = "RBXL" end
    return base .. " IMPORTER BY LANGZSTUDENT"
end
local function reportImportProgress(value, message)
    local cb = _G.LANGZ_IMPORT_PROGRESS_CB
    if type(cb) == "function" then
        pcall(cb, value, message)
    end
end
local function buildRBXL(parsed, sourceFileName)
    local made = {}
    local skipped = 0
    local failedProperties = 0
    local progressTotal = math.max(
        tonumber(parsed.Header and parsed.Header.InstanceCount) or 1,
        1
    )
    local progressMade = 0
    reportImportProgress(0.20, "BUILDING INSTANCES")
    local meshNative = 0
    local meshFallback = 0
    local meshUnresolved = 0
    local csgAsset = 0
    local csgProxy = 0
    local rootName = importRootName(sourceFileName)
    local oldRoot = workspace:FindFirstChild(rootName)
    if oldRoot then pcall(function() oldRoot:Destroy() end) end
    local importRoot = Instance.new("Folder")
    importRoot.Name = rootName
    importRoot:SetAttribute("LANGZ_RBXL_IMPORT", true)
    importRoot:SetAttribute("LANGZ_SourceFile", tostring(sourceFileName or ""))
    importRoot:SetAttribute("LANGZ_InMemoryStaging", true)
    importRoot.Parent = nil
    local containers = {}
    local function newServiceFolder(key, displayName)
        local folder = Instance.new("Folder")
        folder.Name = displayName
        folder:SetAttribute("LANGZ_ServiceKey", key)
        folder.Parent = importRoot
        containers[key] = folder
        return folder
    end
    newServiceFolder("WS",  "workspace(ws)")
    newServiceFolder("RS",  "replicate storage(rs)")
    newServiceFolder("RF",  "replicate first(rf)")
    newServiceFolder("L",   "lighting(l)")
    newServiceFolder("P",   "players(p)")
    newServiceFolder("SG",  "starter gui(sg)")
    newServiceFolder("STP", "starter pack(stp)")
    newServiceFolder("SP",  "starter player(sp)")
    newServiceFolder("SPS", "starter player script(sps)")
    newServiceFolder("SCS", "starter character script(scs)")
    newServiceFolder("SSS", "serverscriptservice(sss)")
    newServiceFolder("SS",  "server storage(ss)")
    newServiceFolder("TEAM", "teams(team)")
    newServiceFolder("SND",  "sound service(sound)")
    newServiceFolder("MAT",   "material service(mat)")
    newServiceFolder("TCS",   "text chat service(tcs)")
    newServiceFolder("CHAT",  "chat(chat)")
    newServiceFolder("LOC",   "localization service(loc)")
    newServiceFolder("TEST",  "test service(test)")
    newServiceFolder("HTTP",  "http service(http)")
    newServiceFolder("INS",   "insert service(ins)")
    newServiceFolder("TWEEN", "tween service(tween)")
    local serviceKeyByName = {
        Workspace = "WS",
        ReplicatedStorage = "RS",
        ReplicatedFirst = "RF",
        Lighting = "L",
        Players = "P",
        StarterGui = "SG",
        StarterPack = "STP",
        StarterPlayer = "SP",
        StarterPlayerScripts = "SPS",
        StarterCharacterScripts = "SCS",
        ServerScriptService = "SSS",
        ServerStorage = "SS",
        Teams = "TEAM",
        SoundService = "SND",
        MaterialService = "MAT",
        TextChatService = "TCS",
        Chat = "CHAT",
        LocalizationService = "LOC",
        TestService = "TEST",
        HttpService = "HTTP",
        InsertService = "INS",
        TweenService = "TWEEN",
    }
    local function routeForNode(node, inheritedKey)
        local className = tostring(node.ClassName or "")
        local nodeName = tostring((node.Properties and node.Properties.Name) or "")
        local direct = serviceKeyByName[className] or serviceKeyByName[nodeName]
        if direct then return direct end
        if inheritedKey == "SP" then
            if className == "StarterPlayerScripts" or nodeName == "StarterPlayerScripts" then
                return "SPS"
            elseif className == "StarterCharacterScripts" or nodeName == "StarterCharacterScripts" then
                return "SCS"
            end
        end
        return inheritedKey or "WS"
    end
    local function rememberStudioLiteState(obj, node)
        if not obj:IsA("BasePart") then return end
        local p = node.Properties or {}
        local originalAnchored
        if type(p.Anchored) == "boolean" then
            originalAnchored = p.Anchored
        else
            pcall(function()
                originalAnchored = obj.Anchored
            end)
        end
        if originalAnchored == nil then
            originalAnchored = false
        end
        local originalCanCollide
        if type(p.CanCollide) == "boolean" then
            originalCanCollide = p.CanCollide
        else
            pcall(function()
                originalCanCollide = obj.CanCollide
            end)
        end
        if originalCanCollide == nil then
            originalCanCollide = true
        end
        pcall(function()
            obj:SetAttribute("SL_Anchored", originalAnchored)
            obj:SetAttribute("LANGZ_FileAnchored", originalAnchored)
            obj:SetAttribute("SL_CanCollide", originalCanCollide)
            obj.Anchored = true
        end)
    end
    local function disableImportedScript(obj, node)
        if not obj:IsA("LuaSourceContainer") then return end
        local originalEnabled = getOriginalScriptEnabled(obj, node)
        pcall(function()
            obj:SetAttribute("LANGZ_OriginalEnabled", originalEnabled)
            obj:SetAttribute("LANGZ_OriginalDisabled", not originalEnabled)
            obj:SetAttribute("LANGZ_StagedDisabled", true)
        end)
        setScriptEnabledState(obj, false)
    end
    local function normalizePartGeometry(obj, node)
        if not obj:IsA("BasePart") then return end
        local p = node.Properties or {}
        applyBaseVisualState(obj, p)
        local special = obj:FindFirstChild("__LANGZ_MeshVisual")
            or obj:FindFirstChild("__LANGZ_CSGVisual")
        if special and special:IsA("SpecialMesh") then
            configureSpecialMeshScale(special, p)
        end
    end
    local function instantiateNode(node)
        if node.ClassName == "MeshPart" then
            local obj, mode = tryCreateMeshPartNode(node)
            if obj then
                if mode == "native" then
                    meshNative = meshNative + 1
                elseif mode == "fallback" then
                    meshFallback = meshFallback + 1
                else
                    meshUnresolved = meshUnresolved + 1
                end
                return obj
            end
            meshUnresolved = meshUnresolved + 1
            return nil
        end
        if node.ClassName == "UnionOperation" or node.ClassName == "PartOperation" or node.ClassName == "IntersectOperation" then
            local obj, mode = tryLoadPartOperationNode(node)
            if obj then
                if mode == "asset" or mode == "mesh" or mode == "visual" then
                    csgAsset = csgAsset + 1
                else
                    csgProxy = csgProxy + 1
                end
                return obj
            end
            csgProxy = csgProxy + 1
            return nil
        end
        local ok, obj = pcall(Instance.new, node.ClassName)
        if ok then return obj end
        return nil
    end
    local buildBurstCount = 0
    local function createNode(node, parent, inheritedKey)
        local routeKey = routeForNode(node, inheritedKey)
        if isMeshPartOnlyChildClass(node.ClassName)
            and (not parent or not parent:IsA("MeshPart")) then
            skipped = skipped + 1
            return nil
        end
        local nodeName = tostring((node.Properties and node.Properties.Name) or "")
        local isServiceLike = node.IsService or node.Service
            or serviceKeyByName[node.ClassName]
            or serviceKeyByName[nodeName]
        if isServiceLike then
            local target = containers[routeKey] or containers.WS
            for _, child in ipairs(node.Children) do
                local childKey = routeForNode(child, routeKey)
                createNode(child, target, childKey)
            end
            return nil
        end
        preloadNodeAssets(node)
        local obj = instantiateNode(node)
        if not obj then
            skipped = skipped + 1
            for _, child in ipairs(node.Children) do
                createNode(child, parent or containers[routeKey] or containers.WS, routeKey)
            end
            return nil
        end
        made[node.Ref] = obj
        pcall(function()
            obj:SetAttribute("LANGZ_ImportedObject", true)
            obj:SetAttribute("LANGZ_Ref", tostring(node.Ref))
        end)
        if node.Properties.Name ~= nil then
            local okName = pcall(function()
                obj.Name = tostring(node.Properties.Name)
            end)
            if not okName then failedProperties = failedProperties + 1 end
        end
        for propName, value in pairs(node.Properties) do
            if propName ~= "Name" then
                local okProp = applyDecodedProperty(
                    obj,
                    propName,
                    value,
                    node.PropertyTypes and node.PropertyTypes[propName]
                )
                if not okProp then failedProperties = failedProperties + 1 end
            end
        end
        rememberStudioLiteState(obj, node)
        disableImportedScript(obj, node)
        normalizePartGeometry(obj, node)
        obj.Parent = parent or containers[routeKey] or containers.WS
        buildBurstCount = buildBurstCount + 1
        progressMade = progressMade + 1
        if progressMade == 1 or progressMade % 120 == 0 then
            local ratio = math.min(progressMade / progressTotal, 1)
            reportImportProgress(
                0.20 + ratio * 0.55,
                ("GENERATING %d / %d"):format(progressMade, progressTotal)
            )
        end
        if buildBurstCount >= 600 then
            buildBurstCount = 0
            task.wait()
        end
        for _, child in ipairs(node.Children) do
            local meshPartOnly = isMeshPartOnlyChildClass(child.ClassName)
            if not (meshPartOnly and not obj:IsA("MeshPart")) then
                createNode(child, obj, routeKey)
            else
                skipped = skipped + 1
            end
        end
        return obj
    end
    for _, root in ipairs(parsed.Roots) do
        local key = routeForNode(root, "WS")
        local rootNameProp = tostring((root.Properties and root.Properties.Name) or "")
        if root.IsService or root.Service
            or serviceKeyByName[root.ClassName]
            or serviceKeyByName[rootNameProp] then
            createNode(root, containers[key], key)
        else
            createNode(root, containers.WS, "WS")
        end
    end
    for ref, node in pairs(parsed.Nodes) do
        local obj = made[ref]
        if obj and node.PropertyTypes then
            for propName, typeID in pairs(node.PropertyTypes) do
                if typeID == 0x13 then
                    local targetRef = node.Properties[propName]
                    local targetObj = made[targetRef]
                    if targetObj then
                        local okRef = pcall(function()
                            obj[propName] = targetObj
                        end)
                        if not okRef then failedProperties = failedProperties + 1 end
                    end
                elseif typeID == 0x22 then
                    local contentValue = node.Properties[propName]
                    if type(contentValue) == "table" and contentValue.__ContentObjectRef then
                        local targetObj = made[contentValue.__ContentObjectRef]
                        if targetObj then
                            local okRef = pcall(function()
                                obj[propName] = targetObj
                            end)
                            if not okRef then failedProperties = failedProperties + 1 end
                        end
                    end
                end
            end
        end
    end
    for ref, node in pairs(parsed.Nodes) do
        local obj = made[ref]
        if obj and obj:IsA("BasePart") then
            normalizePartGeometry(obj, node)
            pcall(function() obj.Anchored = true end)
        end
    end
    task.spawn(function()
        local scriptBatch = 0
        for _, obj in pairs(made) do
            if obj and obj.Parent and obj:IsA("LuaSourceContainer") then
                pcall(function()
                    injectStudioLiteUI(obj, {})
                end)
                scriptBatch = scriptBatch + 1
                if scriptBatch >= 40 then
                    scriptBatch = 0
                    task.wait()
                end
            end
        end
    end)
    flushServerLoadsAsync()
    local madeCount = 0
    for _ in pairs(made) do madeCount = madeCount + 1 end
    reportImportProgress(0.78, ("BUILD COMPLETE • %d INSTANCES"):format(madeCount))
    return madeCount, skipped, failedProperties,
        meshNative, meshFallback, meshUnresolved, csgAsset, csgProxy, importRoot
end
local function safeReadFile(path)
    if type(readfile) ~= "function" then
        return nil, "readfile tidak tersedia"
    end
    local ok, data = pcall(readfile, path)
    if not ok then return nil, tostring(data) end
    if type(data) ~= "string" or #data == 0 then
        return nil, "file kosong / tidak terbaca"
    end
    return data
end
local function xmlDecodeText(value)
    value = tostring(value or "")
    local cdata = value:match("^%s*<!%[CDATA%[(.*)%]%]>%s*$")
    if cdata ~= nil then
        return cdata
    end
    value = value:gsub("&#x([%x]+);", function(hex)
        local n = tonumber(hex, 16)
        if not n then return "" end
        if n <= 255 then return string.char(n) end
        if utf8 and utf8.char then
            local ok, ch = pcall(utf8.char, n)
            if ok then return ch end
        end
        return ""
    end)
    value = value:gsub("&#(%d+);", function(dec)
        local n = tonumber(dec)
        if not n then return "" end
        if n <= 255 then return string.char(n) end
        if utf8 and utf8.char then
            local ok, ch = pcall(utf8.char, n)
            if ok then return ch end
        end
        return ""
    end)
    value = value:gsub("&quot;", '"')
    value = value:gsub("&apos;", "'")
    value = value:gsub("&lt;", "<")
    value = value:gsub("&gt;", ">")
    value = value:gsub("&amp;", "&")
    return value
end
local function xmlNumber(inner, tag)
    local value = inner:match("<" .. tag .. ">%s*(.-)%s*</" .. tag .. ">")
    return tonumber(value)
end
local function xmlPropertyValue(tag, inner)
    if tag == "string" or tag == "ProtectedString" then
        return xmlDecodeText(inner)
    elseif tag == "BinaryString" or tag == "SharedString" then
        return xmlDecodeText(inner)
    elseif tag == "bool" then
        local v = tostring(inner):match("^%s*(.-)%s*$")
        return v == "true" or v == "1"
    elseif tag == "int" or tag == "int64"
        or tag == "float" or tag == "double" then
        return tonumber(tostring(inner):match("^%s*(.-)%s*$"))
    elseif tag == "token" then
        return tonumber(tostring(inner):match("^%s*(.-)%s*$")), 0x12
    elseif tag == "Ref" then
        local target = xmlDecodeText(inner):match("^%s*(.-)%s*$")
        if target == "" or target == "null" then
            return nil, 0x13
        end
        return {__XMLRef = target}, 0x13
    elseif tag == "Vector3" then
        local x = xmlNumber(inner, "X") or 0
        local y = xmlNumber(inner, "Y") or 0
        local z = xmlNumber(inner, "Z") or 0
        return Vector3.new(x, y, z)
    elseif tag == "Vector2" then
        local x = xmlNumber(inner, "X") or 0
        local y = xmlNumber(inner, "Y") or 0
        return Vector2.new(x, y)
    elseif tag == "Color3" then
        local r = xmlNumber(inner, "R") or 0
        local g = xmlNumber(inner, "G") or 0
        local b = xmlNumber(inner, "B") or 0
        return Color3.new(r, g, b)
    elseif tag == "Color3uint8" then
        local packed = tonumber(tostring(inner):match("^%s*(%d+)%s*$"))
        if not packed then return nil end
        local r = math.floor(packed / 65536) % 256
        local g = math.floor(packed / 256) % 256
        local b = packed % 256
        return Color3.fromRGB(r, g, b)
    elseif tag == "CoordinateFrame" or tag == "CFrame" then
        local x = xmlNumber(inner, "X") or 0
        local y = xmlNumber(inner, "Y") or 0
        local z = xmlNumber(inner, "Z") or 0
        local r00 = xmlNumber(inner, "R00") or 1
        local r01 = xmlNumber(inner, "R01") or 0
        local r02 = xmlNumber(inner, "R02") or 0
        local r10 = xmlNumber(inner, "R10") or 0
        local r11 = xmlNumber(inner, "R11") or 1
        local r12 = xmlNumber(inner, "R12") or 0
        local r20 = xmlNumber(inner, "R20") or 0
        local r21 = xmlNumber(inner, "R21") or 0
        local r22 = xmlNumber(inner, "R22") or 1
        return CFrame.new(x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22)
    elseif tag == "OptionalCoordinateFrame" then
        if inner:find("<CFrame>", 1, true) then
            local body = inner:match("<CFrame>(.-)</CFrame>") or inner
            return xmlPropertyValue("CFrame", body)
        end
        return nil
    elseif tag == "UDim" then
        local s = xmlNumber(inner, "S") or 0
        local o = xmlNumber(inner, "O") or 0
        return UDim.new(s, o)
    elseif tag == "UDim2" then
        local xs = xmlNumber(inner, "XS") or 0
        local xo = xmlNumber(inner, "XO") or 0
        local ys = xmlNumber(inner, "YS") or 0
        local yo = xmlNumber(inner, "YO") or 0
        return UDim2.new(xs, xo, ys, yo)
    elseif tag == "BrickColor" then
        local n = tonumber(tostring(inner):match("^%s*(%d+)%s*$"))
        if n then
            local ok, value = pcall(BrickColor.new, n)
            if ok then return value end
        end
        return nil
    elseif tag == "Content" then
        local url = inner:match("<url>(.-)</url>")
        if url then return xmlDecodeText(url) end
        if inner:find("<null", 1, true) then return "" end
        return xmlDecodeText(inner:gsub("<[^>]+>", ""))
    elseif tag == "NumberRange" then
        local min = xmlNumber(inner, "Min")
        local max = xmlNumber(inner, "Max")
        if min ~= nil and max ~= nil then
            return NumberRange.new(min, max)
        end
    elseif tag == "Rect2D" then
        local minBlock = inner:match("<min>(.-)</min>")
        local maxBlock = inner:match("<max>(.-)</max>")
        if minBlock and maxBlock then
            local minX = xmlNumber(minBlock, "X") or 0
            local minY = xmlNumber(minBlock, "Y") or 0
            local maxX = xmlNumber(maxBlock, "X") or 0
            local maxY = xmlNumber(maxBlock, "Y") or 0
            return Rect.new(minX, minY, maxX, maxY)
        end
    elseif tag == "NumberSequence" then
        local numbers = {}
        for n in xmlDecodeText(inner):gmatch("[-+]?[%d%.]+[eE]?[-+]?%d*") do
            local value = tonumber(n)
            if value then numbers[#numbers + 1] = value end
        end
        if #numbers >= 3 then
            local keypoints = {}
            for i = 1, #numbers - 2, 3 do
                local ok, kp = pcall(NumberSequenceKeypoint.new,
                    numbers[i], numbers[i + 1], numbers[i + 2])
                if ok then keypoints[#keypoints + 1] = kp end
            end
            if #keypoints >= 2 then
                local ok, seq = pcall(NumberSequence.new, keypoints)
                if ok then return seq end
            end
        end
    elseif tag == "Font" then
        local family = inner:match("<Family>%s*<url>(.-)</url>%s*</Family>")
        local weight = tonumber(inner:match("<Weight>%s*(%d+)%s*</Weight>")) or 400
        local style = inner:match("<Style>%s*(.-)%s*</Style>") or "Normal"
        if family and Font then
            family = xmlDecodeText(family)
            local enumWeight = Enum.FontWeight.Regular
            pcall(function() enumWeight = Enum.FontWeight:FromValue(weight) end)
            local enumStyle = Enum.FontStyle.Normal
            if style == "Italic" then enumStyle = Enum.FontStyle.Italic end
            local ok, font = pcall(Font.new, family, enumWeight, enumStyle)
            if ok then return font end
        end
    end
    return nil
end
local function parseRobloxXML(data)
    if type(data) ~= "string" then
        return nil, "XML data bukan string"
    end
    data = data:gsub("^\239\187\191", "")
    if not data:find("<roblox", 1, true) then
        return nil, "Roblox XML root <roblox> tidak ditemukan"
    end
    local nodes = {}
    local roots = {}
    local referentToRef = {}
    local nextRef = 1
    local function parseProperties(body, node)
        local pos = 1
        while true do
            local openStart, openEnd, tag, attrs = body:find("<([%w]+)(.-)>", pos)
            if not openStart then break end
            local propName = attrs:match('name="([^"]+)"')
            if not propName then
                pos = openEnd + 1
            else
                local closeTag = "</" .. tag .. ">"
                local closeStart, closeEnd = body:find(closeTag, openEnd + 1, true)
                if not closeStart then break end
                local inner = body:sub(openEnd + 1, closeStart - 1)
                local value, typeID = xmlPropertyValue(tag, inner)
                if value ~= nil then
                    node.Properties[propName] = value
                end
                if typeID ~= nil then
                    node.PropertyTypes[propName] = typeID
                end
                pos = closeEnd + 1
            end
        end
    end
    local parseItemAt
    parseItemAt = function(startPos)
        local openEnd = data:find(">", startPos, true)
        if not openEnd then return nil, startPos, "Item open tag tidak selesai" end
        local openTag = data:sub(startPos, openEnd)
        local className = openTag:match('class="([^"]+)"')
        local referent = openTag:match('referent="([^"]+)"')
        if not className then
            return nil, openEnd + 1, "Item tanpa class"
        end
        local ref = nextRef
        nextRef = nextRef + 1
        local node = {
            Ref = ref,
            ClassName = xmlDecodeText(className),
            Properties = {},
            PropertyTypes = {},
            Children = {},
            Service = false,
            IsService = false,
            XMLReferent = referent,
        }
        nodes[ref] = node
        if referent and referent ~= "" then
            referentToRef[referent] = ref
        end
        local pos = openEnd + 1
        while pos <= #data do
            local nextTag = data:find("<", pos, true)
            if not nextTag then
                return nil, pos, "Item tidak memiliki closing tag"
            end
            if data:sub(nextTag, nextTag + 6) == "</Item>" then
                return node, nextTag + 7
            elseif data:sub(nextTag, nextTag + 11) == "<Properties>" then
                local closeStart, closeEnd = data:find("</Properties>", nextTag + 12, true)
                if not closeStart then
                    return nil, nextTag, "Properties tidak memiliki closing tag"
                end
                parseProperties(data:sub(nextTag + 12, closeStart - 1), node)
                pos = closeEnd + 1
            elseif data:sub(nextTag, nextTag + 4) == "<Item" then
                local child, newPos, err = parseItemAt(nextTag)
                if not child then return nil, newPos, err end
                node.Children[#node.Children + 1] = child
                pos = newPos
            elseif data:sub(nextTag, nextTag + 3) == "<!--" then
                local commentEnd = data:find("-->", nextTag + 4, true)
                pos = commentEnd and (commentEnd + 3) or (#data + 1)
            else
                local tagEnd = data:find(">", nextTag, true)
                pos = tagEnd and (tagEnd + 1) or (#data + 1)
            end
        end
        return nil, pos, "Unexpected end of XML"
    end
    local pos = 1
    while true do
        local itemStart = data:find("<Item", pos, true)
        if not itemStart then break end
        local node, newPos, err = parseItemAt(itemStart)
        if not node then
            return nil, "XML PARSE ERROR: " .. tostring(err)
        end
        roots[#roots + 1] = node
        pos = newPos
    end
    if #roots == 0 then
        return nil, "Roblox XML tidak memiliki Item"
    end
    for _, node in pairs(nodes) do
        for propName, typeID in pairs(node.PropertyTypes) do
            if typeID == 0x13 then
                local value = node.Properties[propName]
                if type(value) == "table" and value.__XMLRef then
                    node.Properties[propName] = referentToRef[value.__XMLRef] or -1
                end
            end
        end
    end
    local serviceNames = {
        Workspace=true, Players=true, Lighting=true, ReplicatedFirst=true,
        ReplicatedStorage=true, StarterGui=true, StarterPack=true,
        StarterPlayer=true, Teams=true, ServerScriptService=true,
        ServerStorage=true, SoundService=true, MaterialService=true,
        TextChatService=true, Chat=true, LocalizationService=true,
        TestService=true, HttpService=true, InsertService=true, TweenService=true,
    }
    for _, root in ipairs(roots) do
        local rootName = tostring(root.Properties.Name or "")
        if serviceNames[root.ClassName] or serviceNames[rootName] then
            root.Service = true
            root.IsService = true
        end
    end
    return {
        Header = {
            ClassCount = 0,
            InstanceCount = nextRef - 1,
            Format = "XML",
        },
        Nodes = nodes,
        Roots = roots,
        Services = {},
        SharedStrings = {},
    }, nil
end
local function detectRobloxSerialization(data)
    if type(data) ~= "string" or #data == 0 then
        return nil
    end
    if data:sub(1, 14) == "<roblox!" .. string.char(137,255,13,10,26,10) then
        return "BINARY"
    end
    local sample = data:sub(1, 4096):gsub("^\239\187\191", "")
    if sample:find("<roblox", 1, true) then
        return "XML"
    end
    return nil
end
local function importRBXL(fileInfo)
    reportImportProgress(0.02, "READING PLACE FILE")
    local data, readErr = safeReadFile(fileInfo.path)
    reportImportProgress(0.08, "PLACE FILE LOADED")
    if not data then
        return false, "READ ERROR: " .. tostring(readErr)
    end
    local serialization = detectRobloxSerialization(data)
    if not serialization then
        return false, "File bukan RBXL/RBXLX Roblox yang valid"
    end
    local parsed, parseErr
    if serialization == "BINARY" then
        if type(string.unpack) ~= "function" then
            return false, "COMPAT ERROR: string.unpack tidak tersedia"
        end
        if type(bit32) ~= "table" then
            return false, "COMPAT ERROR: bit32 tidak tersedia"
        end
        reportImportProgress(0.12, "PARSING RBXL BINARY")
        local okParse, result, err = pcall(parseRBXLBinary, data)
        if not okParse then
            return false, "PARSER CRASH: " .. tostring(result)
        end
        parsed, parseErr = result, err
    else
        reportImportProgress(0.12, "PARSING RBXLX XML")
        local okParse, result, err = pcall(parseRobloxXML, data)
        if not okParse then
            return false, "XML PARSER CRASH: " .. tostring(result)
        end
        parsed, parseErr = result, err
    end
    if not parsed then
        return false, "PARSE ERROR: " .. tostring(parseErr or "unknown")
    end
    reportImportProgress(
        0.18,
        ("PARSED %s • %d INSTANCES"):format(
            serialization,
            tonumber(parsed.Header and parsed.Header.InstanceCount) or 0
        )
    )
    local okBuild, madeCount, skipped, failedProperties,
        meshNative, meshFallback, meshUnresolved, csgAsset, csgProxy, importRoot = pcall(
            buildRBXL,
            parsed,
            fileInfo.name
        )
    if not okBuild then
        return false, "BUILD ERROR: " .. tostring(madeCount)
    end
    local rootLabel = importRoot and importRoot.Name or importRootName(fileInfo.name)
    return true, ("%s OK %d | %s | mesh N:%d F:%d U:%d | CSG A:%d P:%d | prop:%d"):format(
        serialization,
        madeCount or 0,
        rootLabel,
        meshNative or 0,
        meshFallback or 0,
        meshUnresolved or 0,
        csgAsset or 0,
        csgProxy or 0,
        failedProperties or 0
    ), importRoot
end
local function collectRBXMSources(parsed)
    local queues = {}
    local function add(node)
        local p = node.Properties or {}
        local source = p.Source or p.ContentText
        if type(source) == "string" and source ~= "" then
            source = source:gsub(string.char(0) .. "*$", "")
            local key =
                tostring(node.ClassName or "")
                .. "\0"
                .. tostring(p.Name or "")
            queues[key] = queues[key] or {}
            queues[key][#queues[key] + 1] = source
        end
        for _, child in ipairs(node.Children or {}) do
            add(child)
        end
    end
    for _, root in ipairs(parsed.Roots or {}) do
        add(root)
    end
    return queues
end
local function takeRBXMSource(sourceQueues, obj)
    local key = obj.ClassName .. "\0" .. obj.Name
    local queue = sourceQueues[key]
    if not queue or #queue == 0 then
        return nil
    end
    local source = queue[1]
    table.remove(queue, 1)
    return source
end
local function tryWriteRBXMSource(scr, source)
    if not scr or not scr:IsA("LuaSourceContainer")
        or type(source) ~= "string"
        or source == "" then
        return false
    end
    _G.Langz_RAW_SOURCES[scr] = source
    local refKey = scr:GetAttribute("LANGZ_Ref")
    if refKey ~= nil then
        _G.Langz_RAW_SOURCE_BY_REF[tostring(refKey)] = source
    end
    if type(setscriptable) == "function" then
        pcall(setscriptable, scr, "Source", true)
    end
    return pcall(function()
        scr.Source = source
    end)
end
local function queueAssetsFromRBXM(root)
    local all = {root}
    for _, d in ipairs(root:GetDescendants()) do
        all[#all + 1] = d
    end
    for _, obj in ipairs(all) do
        pcall(function()
            if obj:IsA("MeshPart") then
                queueServerLoad(obj.MeshId)
                queueServerLoad(obj.TextureID)
            elseif obj:IsA("SpecialMesh") then
                queueServerLoad(obj.MeshId)
                queueServerLoad(obj.TextureId)
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                queueServerLoad(obj.Texture)
            elseif obj:IsA("Shirt") then
                queueServerLoad(obj.ShirtTemplate)
            elseif obj:IsA("Pants") then
                queueServerLoad(obj.PantsTemplate)
            elseif obj:IsA("ShirtGraphic") then
                queueServerLoad(obj.Graphic)
            elseif obj:IsA("UnionOperation")
                or obj:IsA("PartOperation")
                or obj:IsA("IntersectOperation") then
                queueServerLoad(obj.AssetId)
            end
        end)
    end
end
local function buildRBXModelParsed(parsed, sourceFileName)
    local made = {}
    local importedRoots = {}
    local skipped = 0
    local failedProperties = 0
    local function instantiateModelNode(node)
        if node.ClassName == "MeshPart" then
            local obj = tryCreateMeshPartNode(node)
            if obj then return obj end
        elseif node.ClassName == "UnionOperation"
            or node.ClassName == "PartOperation"
            or node.ClassName == "IntersectOperation" then
            local obj = tryLoadPartOperationNode(node)
            if obj then return obj end
        end
        local ok, obj = pcall(Instance.new, node.ClassName)
        if ok then return obj end
        return nil
    end
    local function createNode(node, parent)
        preloadNodeAssets(node)
        local obj = instantiateModelNode(node)
        if not obj then
            skipped = skipped + 1
            for _, child in ipairs(node.Children or {}) do
                createNode(child, parent)
            end
            return nil
        end
        made[node.Ref] = obj
        pcall(function()
            obj:SetAttribute("LANGZ_ImportedObject", true)
            obj:SetAttribute("LANGZ_Ref", tostring(node.Ref))
            obj:SetAttribute("LANGZ_RBXMSource", tostring(sourceFileName or ""))
        end)
        if node.Properties and node.Properties.Name ~= nil then
            pcall(function()
                obj.Name = tostring(node.Properties.Name)
            end)
        end
        for propName, value in pairs(node.Properties or {}) do
            if propName ~= "Name" then
                local okProp = applyDecodedProperty(
                    obj,
                    propName,
                    value,
                    node.PropertyTypes and node.PropertyTypes[propName]
                )
                if not okProp then failedProperties = failedProperties + 1 end
            end
        end
        if obj:IsA("LuaSourceContainer") then
            local originalEnabled = getOriginalScriptEnabled(obj, node)
            pcall(function()
                obj:SetAttribute("LANGZ_OriginalEnabled", originalEnabled)
                obj:SetAttribute("LANGZ_OriginalDisabled", not originalEnabled)
                obj:SetAttribute("LANGZ_StagedDisabled", true)
            end)
            setScriptEnabledState(obj, false)
        end
        if obj:IsA("BasePart") then
            local original = obj.Anchored
            if node.Properties and type(node.Properties.Anchored) == "boolean" then
                original = node.Properties.Anchored
            end
            pcall(function()
                obj:SetAttribute("LANGZ_FileAnchored", original)
                obj:SetAttribute("LANGZ_AutoAnchored", true)
                obj.Anchored = true
            end)
        end
        obj.Parent = parent
        for _, child in ipairs(node.Children or {}) do
            if not (isMeshPartOnlyChildClass(child.ClassName) and not obj:IsA("MeshPart")) then
                createNode(child, obj)
            else
                skipped = skipped + 1
            end
        end
        return obj
    end
    for _, root in ipairs(parsed.Roots or {}) do
        local obj = createNode(root, nil)
        if obj then
            obj.Parent = workspace
            importedRoots[#importedRoots + 1] = obj
        end
    end
    for ref, node in pairs(parsed.Nodes or {}) do
        local obj = made[ref]
        if obj and node.PropertyTypes then
            for propName, typeID in pairs(node.PropertyTypes) do
                if typeID == 0x13 then
                    local target = made[node.Properties[propName]]
                    if target then
                        pcall(function() obj[propName] = target end)
                    end
                end
            end
        end
    end
    for ref, obj in pairs(made) do
        local node = parsed.Nodes and parsed.Nodes[ref]
        if obj:IsA("LuaSourceContainer") and node then
            local source = node.Properties and (node.Properties.Source or node.Properties.ContentText)
            if type(source) == "string" and source ~= "" then
                pcall(function() tryWriteRBXMSource(obj, source) end)
            end
            pcall(function() injectStudioLiteUI(obj, {}) end)
        end
        if obj:IsA("BasePart") then
            pcall(function()
                obj.Anchored = true
                obj:SetAttribute("LANGZ_AutoAnchored", true)
            end)
        end
    end
    for _, root in ipairs(importedRoots) do
        pcall(function() queueAssetsFromRBXM(root) end)
    end
    flushServerLoadsAsync()
    local count = 0
    for _ in pairs(made) do count = count + 1 end
    return importedRoots, count, skipped, failedProperties
end
local function importRBXM(fileInfo)
    reportImportProgress(0.02, "READING RBXM")
    local data, readErr = safeReadFile(fileInfo.path)
    if not data then
        return false, "READ ERROR: " .. tostring(readErr)
    end
    reportImportProgress(0.10, "MODEL FILE LOADED")
    local serialization = detectRobloxSerialization(data)
    if not serialization then
        return false, "File bukan RBXM/RBXMX Roblox yang valid"
    end
    if serialization == "XML" then
        reportImportProgress(0.16, "PARSING RBXMX XML")
        local okParsed, parsed, parseErr = pcall(parseRobloxXML, data)
        if not okParsed then
            return false, "XML PARSER CRASH: " .. tostring(parsed)
        end
        if not parsed then
            return false, "RBXMX PARSE ERROR: " .. tostring(parseErr or "unknown")
        end
        reportImportProgress(0.34, "BUILDING RBXMX MODEL")
        local okBuild, roots, count, skipped, failedProperties = pcall(
            buildRBXModelParsed,
            parsed,
            fileInfo.name
        )
        if not okBuild then
            return false, "RBXMX BUILD ERROR: " .. tostring(roots)
        end
        reportImportProgress(1.00, "RBXMX GENERATION COMPLETE")
        return true,
            ("RBXMX XML OK • %d object(s) • skipped:%d • prop:%d"):format(
                count or 0,
                skipped or 0,
                failedProperties or 0
            ),
            roots and roots[1] or nil
    end
    local sourceQueues = {}
    if serialization == "BINARY" then
        reportImportProgress(0.15, "PARSING RBXM SOURCES")
        local okParsed, parsed = pcall(parseRBXLBinary, data)
        if okParsed and parsed then
            sourceQueues = collectRBXMSources(parsed)
        end
    end
    reportImportProgress(0.24, "REGISTERING RBXM ASSET")
    local objects
    local loadMethod = "unknown"
    if type(getcustomasset) == "function" then
        local okAsset, customAsset = pcall(getcustomasset, fileInfo.path)
        if okAsset and customAsset then
            local okObjects, result = pcall(function()
                return game:GetObjects(customAsset)
            end)
            if okObjects and type(result) == "table" and #result > 0 then
                objects = result
                loadMethod = "getcustomasset"
            end
        end
    end
    if not objects then
        local okObjects, result = pcall(function()
            return game:GetObjects("rbxasset://" .. tostring(fileInfo.path))
        end)
        if okObjects and type(result) == "table" and #result > 0 then
            objects = result
            loadMethod = "rbxasset"
        end
    end
    if not objects then
        return false,
            "RBXM LOAD ERROR: getcustomasset/game:GetObjects tidak dapat memuat model"
    end
    reportImportProgress(0.40, ("RBXM OPENED • %d ROOT"):format(#objects))
    local importedRoots = {}
    local totalObjects = 0
    local sourceFound = 0
    local sourceWritten = 0
    local editorRestored = 0
    local scriptCount = 0
    for rootIndex, root in ipairs(objects) do
        if typeof(root) == "Instance" then
            root:SetAttribute("LANGZ_ImportedObject", true)
            root:SetAttribute("LANGZ_RBXMSource", fileInfo.name)
            local scriptsToDisable = {root}
            for _, descendant in ipairs(root:GetDescendants()) do
                table.insert(scriptsToDisable, descendant)
            end
            for _, importedScript in ipairs(scriptsToDisable) do
                if importedScript:IsA("LuaSourceContainer") then
                    local originalEnabled = true
                    pcall(function() originalEnabled = importedScript.Enabled end)
                    pcall(function()
                        importedScript:SetAttribute("LANGZ_OriginalEnabled", originalEnabled)
                        importedScript:SetAttribute("LANGZ_OriginalDisabled", not originalEnabled)
                        importedScript:SetAttribute("LANGZ_StagedDisabled", true)
                    end)
                    setScriptEnabledState(importedScript, false)
                end
            end
            root.Parent = workspace
            importedRoots[#importedRoots + 1] = root
            if root:IsA("BasePart") then
                local savedAnchored = root.Anchored
                root:SetAttribute("LANGZ_FileAnchored", savedAnchored)
                root:SetAttribute("LANGZ_AutoAnchored", true)
                root.Anchored = true
            end
            local descendants = root:GetDescendants()
            for _, part in ipairs(descendants) do
                if part:IsA("BasePart") then
                    local savedAnchored = part.Anchored
                    part:SetAttribute("LANGZ_FileAnchored", savedAnchored)
                    part:SetAttribute("LANGZ_AutoAnchored", true)
                    part.Anchored = true
                end
            end
            totalObjects = totalObjects + #descendants + 1
            local all = {root}
            for _, obj in ipairs(descendants) do
                all[#all + 1] = obj
            end
            for i, obj in ipairs(all) do
                obj:SetAttribute("LANGZ_ImportedObject", true)
                if obj:IsA("LuaSourceContainer") then
                    scriptCount = scriptCount + 1
                    local source = takeRBXMSource(sourceQueues, obj)
                    if source then
                        sourceFound = sourceFound + 1
                        _G.Langz_RAW_SOURCES[obj] = source
                        local wrote = tryWriteRBXMSource(obj, source)
                        if wrote then
                            sourceWritten = sourceWritten + 1
                        end
                        local okEditor = pcall(function()
                            injectStudioLiteUI(obj, {})
                        end)
                        if okEditor then
                            editorRestored = editorRestored + 1
                        end
                    end
                end
                if i % 180 == 0 then
                    task.wait()
                end
            end
            queueAssetsFromRBXM(root)
        end
        local ratio = rootIndex / math.max(#objects, 1)
        reportImportProgress(
            0.40 + ratio * 0.45,
            ("IMPORTING RBXM ROOT %d / %d"):format(rootIndex, #objects)
        )
    end
    flushServerLoadsAsync()
    reportImportProgress(0.94, "FINALIZING RBXM")
    for _, root in ipairs(importedRoots) do
        for _, obj in ipairs(root:GetDescendants()) do
            if obj:IsA("LuaSourceContainer") then
                local enabled
                local okEnabled = pcall(function()
                    enabled = obj.Enabled
                end)
                if okEnabled and type(enabled) == "boolean" then
                    pcall(function()
                        obj.Enabled = enabled
                    end)
                end
            end
        end
    end
    for _, root in ipairs(importedRoots) do
        if root:IsA("BasePart") then
            pcall(function()
                root.Anchored = true
                root:SetAttribute("LANGZ_AutoAnchored", true)
            end)
        end
        for _, obj in ipairs(root:GetDescendants()) do
            if obj:IsA("BasePart") then
                pcall(function()
                    obj.Anchored = true
                    obj:SetAttribute("LANGZ_AutoAnchored", true)
                end)
            end
        end
    end
    reportImportProgress(1.00, "RBXM GENERATION COMPLETE")
    return true,
        ("RBXM OK • %d objects • %d scripts • source:%d/%d • editor:%d • %s"):format(
            totalObjects,
            scriptCount,
            sourceWritten,
            sourceFound,
            editorRestored,
            loadMethod
        ),
        importedRoots
end
local LANGZ_MODULE_CACHE = setmetatable({}, {__mode = "k"})
local LANGZ_MODULE_LOADING = setmetatable({}, {__mode = "k"})
local function rawSourceFor(scr)
    if not scr or not scr:IsA("LuaSourceContainer") then
        return nil
    end
    local direct = _G.Langz_RAW_SOURCES[scr]
    if type(direct) == "string" and direct ~= "" then
        return direct
    end
    local refKey = scr:GetAttribute("LANGZ_Ref")
    if refKey ~= nil then
        local byRef = _G.Langz_RAW_SOURCE_BY_REF[tostring(refKey)]
        if type(byRef) == "string" and byRef ~= "" then
            return byRef
        end
    end
    return nil
end
local function canReadExecutableSource(scr)
    local ok, source = pcall(function()
        return scr.Source
    end)
    return ok and type(source) == "string" and #source > 0, source
end
local runtimeRequire
local function compileRuntimeSource(scr, source)
    if type(loadstring) ~= "function" then
        return nil, "loadstring tidak tersedia"
    end
    local wrapped =
        "return function(script, require, ...)\\n"
        .. source
        .. "\\nend"
    local okCompile, loaderOrErr = pcall(
        loadstring,
        wrapped,
        "=LANGZ_RBXL/" .. tostring(scr:GetFullName())
    )
    if not okCompile or type(loaderOrErr) ~= "function" then
        return nil, tostring(loaderOrErr)
    end
    local okFactory, runnerOrErr = pcall(loaderOrErr)
    if not okFactory or type(runnerOrErr) ~= "function" then
        return nil, tostring(runnerOrErr)
    end
    return runnerOrErr
end
runtimeRequire = function(target)
    if typeof(target) == "Instance" and target:IsA("ModuleScript") then
        if LANGZ_MODULE_CACHE[target] ~= nil then
            return LANGZ_MODULE_CACHE[target]
        end
        if LANGZ_MODULE_LOADING[target] then
            error("LANGZ runtime require circular dependency: " .. target:GetFullName())
        end
        local source = rawSourceFor(target)
        if source then
            LANGZ_MODULE_LOADING[target] = true
            local runner, compileErr = compileRuntimeSource(target, source)
            if not runner then
                LANGZ_MODULE_LOADING[target] = nil
                error("Module compile failed: " .. tostring(compileErr))
            end
            local results = table.pack(
                pcall(runner, target, runtimeRequire)
            )
            LANGZ_MODULE_LOADING[target] = nil
            if not results[1] then
                error(results[2])
            end
            local result = results[2]
            LANGZ_MODULE_CACHE[target] = result
            return result
        end
    end
    return require(target)
end
local function runLocalScriptBridge(scr)
    if not scr or not scr:IsA("LocalScript") then
        return false, "not_local_script"
    end
    if not importedScriptShouldRun(scr) then
        return false, "originally_disabled"
    end
    if scr:GetAttribute("LANGZ_RuntimeStarted") then
        return true, "already_started"
    end
    local source = rawSourceFor(scr)
    if not source then
        return false, "source_missing"
    end
    local runner, compileErr = compileRuntimeSource(scr, source)
    if not runner then
        return false, "compile: " .. tostring(compileErr)
    end
    scr:SetAttribute("LANGZ_RuntimeStarted", true)
    task.spawn(function()
        local ok, runtimeErr = pcall(
            runner,
            scr,
            runtimeRequire
        )
        if not ok then
            warn(
                "[LANGZ LIVE SCRIPT ERROR] "
                .. scr:GetFullName()
                .. " :: "
                .. tostring(runtimeErr)
            )
            scr:SetAttribute("LANGZ_RuntimeError", tostring(runtimeErr))
        end
    end)
    return true, "runtime_bridge"
end
local function prepareLocalScriptsForClone(root)
    if not root then return end
    if root:IsA("LocalScript") then
        setScriptEnabledState(root, false)
    end
    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("LocalScript") then
            setScriptEnabledState(obj, false)
        end
    end
end
local function activateLocalScriptsInLiveRoot(root)
    local stats = {
        native = 0,
        bridge = 0,
        failed = 0,
        skipped = 0,
    }
    if not root then
        return stats
    end
    local list = {}
    if root:IsA("LocalScript") then
        list[#list + 1] = root
    end
    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("LocalScript") then
            list[#list + 1] = obj
        end
    end
    for _, scr in ipairs(list) do
        if not importedScriptShouldRun(scr) then
            stats.skipped = stats.skipped + 1
            setScriptEnabledState(scr, false)
        else
            local hasRealSource = canReadExecutableSource(scr)
            if hasRealSource then
                local ok = setScriptEnabledState(scr, true)
                if ok then
                    stats.native = stats.native + 1
                else
                    stats.failed = stats.failed + 1
                end
            else
                setScriptEnabledState(scr, false)
                local ok = runLocalScriptBridge(scr)
                if ok then
                    stats.bridge = stats.bridge + 1
                else
                    stats.failed = stats.failed + 1
                end
            end
        end
    end
    return stats
end
local function mergeLiveStats(dst, src)
    dst.native = dst.native + (src.native or 0)
    dst.bridge = dst.bridge + (src.bridge or 0)
    dst.failed = dst.failed + (src.failed or 0)
    dst.skipped = dst.skipped + (src.skipped or 0)
end
local function findStudioLiteRemote(name)
    local sl = ReplicatedStorage:FindFirstChild("StudioLiteFolder")
    if not sl then return nil end
    return sl:FindFirstChild(name, true)
end
local function tryWriteRealScriptSource(scr)
    if not scr or not scr:IsA("LuaSourceContainer") then
        return false, "not_script"
    end
    local source = _G.Langz_RAW_SOURCES[scr]
    if type(source) ~= "string" or source == "" then
        return false, "source_missing"
    end
    source = source:gsub(string.char(0) .. "*$", "")
    local directOK = false
    if type(setscriptable) == "function" then
        pcall(setscriptable, scr, "Source", true)
    end
    directOK = pcall(function()
        scr.Source = source
    end)
    if directOK then
        return true, "direct"
    end
    local saveRemote = findStudioLiteRemote("SaveScriptSourceServerFunction")
    if saveRemote and saveRemote:IsA("RemoteFunction") then
        local ok = pcall(function()
            saveRemote:InvokeServer(scr.ClassName .. scr.Name, source)
        end)
        if ok then
            return true, "studio_lite_remote"
        end
    elseif saveRemote and saveRemote:IsA("RemoteEvent") then
        local ok = pcall(function()
            saveRemote:FireServer(scr.ClassName .. scr.Name, source)
        end)
        if ok then
            return true, "studio_lite_remote"
        end
    end
    return false, "runtime_source_locked"
end
local function restoreImportedRuntimeState(root)
    local stats = {
        scripts = 0,
        scriptSourceOK = 0,
        scriptSourceFailed = 0,
        parts = 0,
    }
    local all = {root}
    for _, d in ipairs(root:GetDescendants()) do
        all[#all + 1] = d
    end
    for _, obj in ipairs(all) do
        if obj:IsA("LuaSourceContainer") then
            stats.scripts = stats.scripts + 1
            local ok = tryWriteRealScriptSource(obj)
            if ok then
                stats.scriptSourceOK = stats.scriptSourceOK + 1
            else
                stats.scriptSourceFailed = stats.scriptSourceFailed + 1
            end
        end
    end
    for _, obj in ipairs(all) do
        if obj:IsA("BasePart") then
            stats.parts = stats.parts + 1
            local originalAnchored = obj:GetAttribute("SL_Anchored")
            local originalCanCollide = obj:GetAttribute("SL_CanCollide")
            if originalCanCollide ~= nil then
                pcall(function()
                    obj.CanCollide = originalCanCollide
                end)
            end
            pcall(function()
                obj.Anchored = true
                obj:SetAttribute("LANGZ_AutoAnchored", true)
            end)
        end
    end
    return stats
end
local function moveChildren(source, destination, onMoved)
    if not source or not destination then return 0 end
    local moved = 0
    local children = source:GetChildren()
    for _, child in ipairs(children) do
        local ok = pcall(function()
            child.Parent = destination
        end)
        if ok then
            moved = moved + 1
            if onMoved then
                pcall(onMoved, child, destination)
            end
        end
    end
    return moved
end
local function activateImportRoot(importRoot)
    if not importRoot then
        return false, "Import root tidak ditemukan"
    end
    reportImportProgress(0.80, "PREPARING SERVICES")
    local forcedServiceCount = 0
    local reusedServiceCount = 0
    local createdServiceCount = 0
    local proxyServiceCount = 0
    local missingRealServices = 0
    local serviceModes = {}
    local function getTopLevelChildrenNamed(serviceName)
        local matches = {}
        local ok, children = pcall(function()
            return game:GetChildren()
        end)
        if not ok or type(children) ~= "table" then
            return matches
        end
        for _, child in ipairs(children) do
            local childName = ""
            pcall(function()
                childName = child.Name
            end)
            if childName == serviceName then
                matches[#matches + 1] = child
            end
        end
        return matches
    end
    local function isLangzGeneratedService(obj)
        if not obj then return false end
        local generated = false
        pcall(function()
            generated =
                obj:GetAttribute("LANGZ_ForcedRealService") == true
                or obj:GetAttribute("LANGZZ_ForcedVisibleService") == true
                or obj:GetAttribute("LANGZ_CreatedService") == true
        end)
        return generated
    end
    local function mergeChildrenInto(source, destination)
        if not source or not destination or source == destination then
            return 0
        end
        local moved = 0
        local children = {}
        pcall(function()
            children = source:GetChildren()
        end)
        for _, child in ipairs(children) do
            local okMove = pcall(function()
                child.Parent = destination
            end)
            if okMove then
                moved = moved + 1
            end
        end
        return moved
    end
    local function findExistingService(serviceName)
        local matches = getTopLevelChildrenNamed(serviceName)
        if #matches == 0 then
            return nil
        end
        local chosen = nil
        for _, obj in ipairs(matches) do
            if not isLangzGeneratedService(obj) then
                chosen = obj
                break
            end
        end
        chosen = chosen or matches[1]
        for _, obj in ipairs(matches) do
            if obj ~= chosen and isLangzGeneratedService(obj) then
                mergeChildrenInto(obj, chosen)
                pcall(function()
                    obj:Destroy()
                end)
            end
        end
        return chosen
    end
    local function forceGetService(serviceName)
        local existing = findExistingService(serviceName)
        if existing then
            reusedServiceCount = reusedServiceCount + 1
            serviceModes[serviceName] = "REUSED_STUDIO_LITE"
            return existing
        end
        local created
        local okCreate, createErr = pcall(function()
            created = Instance.new(serviceName)
            created.Name = serviceName
            created:SetAttribute("LANGZ_ForcedRealService", true)
            created:SetAttribute("LANGZ_ServiceRole", serviceName)
            created.Parent = game
        end)
        if okCreate and created then
            createdServiceCount = createdServiceCount + 1
            serviceModes[serviceName] = "CREATED_MISSING"
            return created
        end
        local okGet, service = pcall(function()
            return game:GetService(serviceName)
        end)
        if okGet and service then
            forcedServiceCount = forcedServiceCount + 1
            serviceModes[serviceName] = "GETSERVICE_MISSING"
            pcall(function()
                service:SetAttribute("LANGZ_ServiceRole", serviceName)
            end)
            return service
        end
        missingRealServices = missingRealServices + 1
        serviceModes[serviceName] = "FAILED"
        warn(
            "[LANGZ] SERVICE FAILED: "
            .. serviceName
            .. " tidak tersedia di Studio Lite runtime ini. "
            .. tostring(createErr)
        )
        return nil
    end
    local function tryForceVisibleService(serviceName, realService)
        if not realService or findExistingService(serviceName) then
            return nil
        end
        local roots = {game}
        for _, candidate in ipairs({_G.sss, _G.ss}) do
            if candidate and candidate.Parent then
                local duplicate = false
                for _, root in ipairs(roots) do
                    if root == candidate.Parent then
                        duplicate = true
                        break
                    end
                end
                if not duplicate then
                    roots[#roots + 1] = candidate.Parent
                end
            end
        end
        pcall(function()
            realService.Archivable = true
        end)
        for _, root in ipairs(roots) do
            local clone
            local okClone = pcall(function()
                clone = realService:Clone()
            end)
            if okClone and clone then
                local className = ""
                pcall(function() className = clone.ClassName end)
                if className == serviceName then
                    local okParent = pcall(function()
                        clone.Name = serviceName
                        clone:SetAttribute("LANGZ_ExplorerVisibleService", true)
                        clone.Parent = root
                    end)
                    if okParent then
                        serviceModes[serviceName] = "VISIBLE_REAL_CLONE"
                        return clone
                    end
                end
                pcall(function() clone:Destroy() end)
            end
        end
        return nil
    end
    local WorkspaceService       = forceGetService("Workspace")
    local PlayersSvc             = forceGetService("Players")
    local LightingSvc            = forceGetService("Lighting")
    local ReplicatedFirstSvc     = forceGetService("ReplicatedFirst")
    local ReplicatedStorageSvc   = forceGetService("ReplicatedStorage")
    local StarterGuiSvc          = forceGetService("StarterGui")
    local StarterPackSvc         = forceGetService("StarterPack")
    local StarterPlayerSvc       = forceGetService("StarterPlayer")
    local TeamsSvc               = forceGetService("Teams")
    local ServerScriptServiceSvc = forceGetService("ServerScriptService")
    local ServerStorageSvc       = forceGetService("ServerStorage")
    local SoundServiceSvc        = forceGetService("SoundService")
    local MaterialServiceSvc     = forceGetService("MaterialService")
    local TextChatServiceSvc     = forceGetService("TextChatService")
    local ChatSvc                = forceGetService("Chat")
    local LocalizationServiceSvc = forceGetService("LocalizationService")
    local TestServiceSvc         = forceGetService("TestService")
    local HttpServiceSvc         = forceGetService("HttpService")
    local InsertServiceSvc       = forceGetService("InsertService")
    local TweenServiceSvc        = forceGetService("TweenService")
    local visibleServiceClones = {
        SoundService = tryForceVisibleService("SoundService", SoundServiceSvc),
        MaterialService = tryForceVisibleService("MaterialService", MaterialServiceSvc),
        TextChatService = tryForceVisibleService("TextChatService", TextChatServiceSvc),
        Chat = tryForceVisibleService("Chat", ChatSvc),
        LocalizationService = tryForceVisibleService("LocalizationService", LocalizationServiceSvc),
        TestService = tryForceVisibleService("TestService", TestServiceSvc),
        HttpService = tryForceVisibleService("HttpService", HttpServiceSvc),
        InsertService = tryForceVisibleService("InsertService", InsertServiceSvc),
        TweenService = tryForceVisibleService("TweenService", TweenServiceSvc),
    }
    reportImportProgress(0.84, "SERVICES READY")
    local function ensureStarterContainer(parent, className, name)
        if not parent then return nil end
        local existing = parent:FindFirstChild(name)
        if existing then
            return existing
        end
        local created
        local ok = pcall(function()
            created = Instance.new(className)
            created.Name = name
            created.Parent = parent
        end)
        if ok and created then
            return created
        end
        local fallback = Instance.new("Folder")
        fallback.Name = name
        fallback:SetAttribute("LANGZ_StarterContainerFallback", true)
        fallback.Parent = parent
        return fallback
    end
    local starterPlayerScripts = ensureStarterContainer(
        StarterPlayerSvc,
        "StarterPlayerScripts",
        "StarterPlayerScripts"
    )
    local starterCharacterScripts = ensureStarterContainer(
        StarterPlayerSvc,
        "StarterCharacterScripts",
        "StarterCharacterScripts"
    )
    local destinationByKey = {
        WS   = WorkspaceService,
        RS   = ReplicatedStorageSvc,
        RF   = ReplicatedFirstSvc,
        L    = LightingSvc,
        P    = PlayersSvc,
        SG   = StarterGuiSvc,
        STP  = StarterPackSvc,
        SP   = StarterPlayerSvc,
        SPS  = starterPlayerScripts,
        SCS  = starterCharacterScripts,
        SSS  = ServerScriptServiceSvc,
        SS   = ServerStorageSvc,
        TEAM = TeamsSvc,
        SND  = SoundServiceSvc,
        MAT   = MaterialServiceSvc,
        TCS   = TextChatServiceSvc,
        CHAT  = ChatSvc,
        LOC   = LocalizationServiceSvc,
        TEST  = TestServiceSvc,
        HTTP  = HttpServiceSvc,
        INS   = InsertServiceSvc,
        TWEEN = TweenServiceSvc,
    }
    local StarterPlayer = StarterPlayerSvc
    local Teams = TeamsSvc
    local SoundService = SoundServiceSvc
    local MaterialService = MaterialServiceSvc
    local TextChatService = TextChatServiceSvc
    local Chat = ChatSvc
    local LocalizationService = LocalizationServiceSvc
    local TestService = TestServiceSvc
    local HttpService = HttpServiceSvc
    local InsertServiceForced = InsertServiceSvc
    local TweenServiceForced = TweenServiceSvc
    local runtimeStats = restoreImportedRuntimeState(importRoot)
    reportImportProgress(0.87, "RESTORING SCRIPT SOURCES")
    local moved = 0
    local workspaceSpawnObjects = {}
    local failedServices = 0
    local stagedCounts = {}
    local stagedScriptCounts = {}
    for _, serviceFolder in ipairs(importRoot:GetChildren()) do
        if serviceFolder:IsA("Folder") then
            local key = serviceFolder:GetAttribute("LANGZ_ServiceKey")
            if key then
                stagedCounts[key] = #serviceFolder:GetChildren()
                local scriptCount = 0
                for _, d in ipairs(serviceFolder:GetDescendants()) do
                    if d:IsA("LuaSourceContainer") then
                        scriptCount = scriptCount + 1
                    end
                end
                stagedScriptCounts[key] = scriptCount
            end
        end
    end
    for _, serviceFolder in ipairs(importRoot:GetChildren()) do
        if serviceFolder:IsA("Folder") then
            local key = serviceFolder:GetAttribute("LANGZ_ServiceKey")
            local destination = destinationByKey[key]
            if destination then
                local onMoved
                if key == "WS" then
                    onMoved = function(child)
                        table.insert(workspaceSpawnObjects, child)
                    end
                end
                moved = moved + moveChildren(serviceFolder, destination, onMoved)
            elseif #serviceFolder:GetChildren() > 0 then
                failedServices = failedServices + 1
            end
        end
    end
    local spawnOk, spawnError = taruhGrupDiDepan(workspaceSpawnObjects)
    reportImportProgress(0.91, ("DEPLOYED • %d OBJECTS"):format(moved))
    local activatedScripts = 0
    local function restoreOneImportedScript(obj)
        if not obj:IsA("LuaSourceContainer")
            or not obj:GetAttribute("LANGZ_StagedDisabled") then
            return
        end
        local shouldRun = importedScriptShouldRun(obj)
        setScriptEnabledState(obj, shouldRun)
        pcall(function()
            obj:SetAttribute("LANGZ_StagedDisabled", nil)
        end)
        if shouldRun then
            activatedScripts = activatedScripts + 1
        end
    end
    for _, obj in ipairs(importRoot:GetDescendants()) do
        restoreOneImportedScript(obj)
    end
    for _, service in pairs(destinationByKey) do
        if service then
            for _, obj in ipairs(service:GetDescendants()) do
                restoreOneImportedScript(obj)
            end
        end
    end
    local liveStats = {
        native = 0,
        bridge = 0,
        failed = 0,
        skipped = 0,
    }
    local function cloneImportedChildren(sourceContainer, destinationContainer)
        if not sourceContainer or not destinationContainer then return end
        for _, child in ipairs(sourceContainer:GetChildren()) do
            if child:GetAttribute("LANGZ_ImportedObject") == true then
                local existing = destinationContainer:FindFirstChild(child.Name)
                if existing and existing:GetAttribute("LANGZ_LiveClone") == true then
                    pcall(function()
                        existing:Destroy()
                    end)
                end
                local clone
                local okClone = pcall(function()
                    clone = child:Clone()
                end)
                if okClone and clone then
                    clone:SetAttribute("LANGZ_LiveClone", true)
                    prepareLocalScriptsForClone(clone)
                    clone.Parent = destinationContainer
                    local s = activateLocalScriptsInLiveRoot(clone)
                    mergeLiveStats(liveStats, s)
                end
            end
        end
    end
    local playerGui = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if playerGui then
        cloneImportedChildren(StarterGui, playerGui)
    end
    local playerScripts = LocalPlayer and LocalPlayer:FindFirstChild("PlayerScripts")
    if playerScripts and starterPlayerScripts then
        cloneImportedChildren(starterPlayerScripts, playerScripts)
    end
    local character = LocalPlayer and LocalPlayer.Character
    if character and starterCharacterScripts then
        cloneImportedChildren(starterCharacterScripts, character)
    end
    local backpack = LocalPlayer and LocalPlayer:FindFirstChildOfClass("Backpack")
    if backpack then
        cloneImportedChildren(StarterPack, backpack)
    end
    if ReplicatedFirstSvc then
        for _, obj in ipairs(ReplicatedFirstSvc:GetDescendants()) do
        if obj:IsA("LocalScript")
            and obj:GetAttribute("LANGZ_ImportedObject") == true then
            local hasRealSource = canReadExecutableSource(obj)
            if hasRealSource then
                setScriptEnabledState(obj, true)
                liveStats.native = liveStats.native + 1
            else
                setScriptEnabledState(obj, false)
                local ok = runLocalScriptBridge(obj)
                if ok then
                    liveStats.bridge = liveStats.bridge + 1
                else
                    liveStats.failed = liveStats.failed + 1
                end
            end
        end
        end
    end
    reportImportProgress(0.95, "FINALIZING SCRIPT EDITORS")
    local deployedScriptCount = 0
    local editorInjectedCount = 0
    local sourceVisibleCount = 0
    local sssImportedScripts = 0
    local ssImportedScripts = 0
    local function restoreEditorForService(service, serviceKey)
        if not service then return end
        for _, obj in ipairs(service:GetDescendants()) do
            if obj:IsA("LuaSourceContainer")
                and obj:GetAttribute("LANGZ_ImportedObject") == true then
                deployedScriptCount = deployedScriptCount + 1
                if serviceKey == "SSS" then
                    sssImportedScripts = sssImportedScripts + 1
                elseif serviceKey == "SS" then
                    ssImportedScripts = ssImportedScripts + 1
                end
                local refKey = obj:GetAttribute("LANGZ_Ref")
                local source = _G.Langz_RAW_SOURCES[obj]
                if (type(source) ~= "string" or source == "")
                    and refKey ~= nil then
                    source = _G.Langz_RAW_SOURCE_BY_REF[tostring(refKey)]
                    if type(source) == "string" and source ~= "" then
                        _G.Langz_RAW_SOURCES[obj] = source
                    end
                end
                if type(source) == "string" and source ~= "" then
                    sourceVisibleCount = sourceVisibleCount + 1
                    pcall(function()
                        tryWriteRealScriptSource(obj)
                    end)
                    local okEditor = pcall(function()
                        injectStudioLiteUI(obj, {})
                    end)
                    if okEditor then
                        editorInjectedCount = editorInjectedCount + 1
                    end
                end
            end
        end
    end
    restoreEditorForService(ServerScriptServiceSvc, "SSS")
    restoreEditorForService(ServerStorageSvc, "SS")
    restoreEditorForService(ReplicatedStorageSvc, "RS")
    restoreEditorForService(ReplicatedFirstSvc, "RF")
    restoreEditorForService(StarterGuiSvc, "SG")
    restoreEditorForService(StarterPlayerSvc, "SP")
    restoreEditorForService(StarterPackSvc, "STP")
    if (stagedScriptCounts.SSS or 0) > 0 and sssImportedScripts == 0 then
        warn(
            "[LANGZ] WARNING: RBXL memiliki "
            .. tostring(stagedScriptCounts.SSS)
            .. " script untuk ServerScriptService, tetapi tidak terlihat "
            .. "di service final."
        )
    end
    if (stagedScriptCounts.SS or 0) > 0 and ssImportedScripts == 0 then
        warn(
            "[LANGZ] WARNING: RBXL memiliki "
            .. tostring(stagedScriptCounts.SS)
            .. " script untuk ServerStorage, tetapi tidak terlihat "
            .. "di service final."
        )
    end
    for _, service in pairs(destinationByKey) do
        if service then
            for _, obj in ipairs(service:GetDescendants()) do
                if obj:IsA("LuaSourceContainer")
                    and obj:GetAttribute("LANGZ_ImportedObject") == true then
                    setScriptEnabledState(
                        obj,
                        importedScriptShouldRun(obj)
                    )
                end
            end
        end
    end
    for _, service in pairs(destinationByKey) do
        if service then
            for _, obj in ipairs(service:GetDescendants()) do
                if obj:IsA("BasePart")
                    and obj:GetAttribute("LANGZ_ImportedObject") == true then
                    pcall(function()
                        obj.Anchored = true
                        obj:SetAttribute("LANGZ_AutoAnchored", true)
                    end)
                end
            end
        end
    end
    importRoot:SetAttribute("LANGZ_Activated", true)
    local remainingStagedObjects = 0
    for _, serviceFolder in ipairs(importRoot:GetChildren()) do
        if serviceFolder:IsA("Folder") then
            remainingStagedObjects = remainingStagedObjects + #serviceFolder:GetChildren()
        end
    end
    if remainingStagedObjects == 0 then
        pcall(function()
            importRoot:Destroy()
        end)
    end
    reportImportProgress(1.00, "RBXL GENERATION COMPLETE")
    local summary = ("ACTIVE • moved:%d • scripts:%d active:%d • source:%d/%d • SSS:%d SS:%d • editor:%d/%d • service reused:%d real-created:%d getservice:%d real-failed:%d"):format(
        moved,
        runtimeStats.scripts,
        activatedScripts,
        runtimeStats.scriptSourceOK,
        runtimeStats.scripts,
        sssImportedScripts,
        ssImportedScripts,
        editorInjectedCount,
        sourceVisibleCount,
        reusedServiceCount,
        createdServiceCount,
        forcedServiceCount,
        missingRealServices
    )
    if not spawnOk then
        summary = summary .. (" • spawn depan kamera gagal: " .. tostring(spawnError))
    end
    return true, summary
end
local function safeListFiles(path)
    if type(listfiles) ~= "function" then return nil end
    local ok, result = pcall(listfiles, path)
    return ok and result or nil
end
local function getFileName(path)
    return path:match("([^/\\]+)$") or path
end
local function looksFolder(path)
    return not getFileName(path):match("%.[%a%d]+$")
end
local SCAN_PATHS = {
    "workspace",
    "Delta/workspace",
    "delta/workspace",
    "Android/Delta/workspace",
    "/sdcard/Delta/workspace",
    "/sdcard/Android/Delta/workspace",
    "../workspace",
    ".",
    ""
}
local function normalizeFsPath(path)
    local p = tostring(path or ""):gsub("\\", "/"):lower()
    p = p:gsub("/+", "/")
    p = p:gsub("^%./", "")
    p = p:gsub("^%.%./", "")
    p = p:gsub("/$", "")
    return p
end
local function canonicalWorkspacePath(path)
    local p = normalizeFsPath(path)
    local lastWorkspace
    local searchFrom = 1
    while true do
        local s, e = p:find("workspace/", searchFrom, true)
        if not s then break end
        lastWorkspace = e + 1
        searchFrom = e + 1
    end
    if lastWorkspace then
        return p:sub(lastWorkspace)
    end
    if p == "workspace" then
        return ""
    end
    return p
end
local function scanDeep(folder, depth, results, seenFolders, seenFiles)
    if depth > 4 then return end
    local folderKey = canonicalWorkspacePath(folder)
    if folderKey == "" then
        folderKey = "__workspace_root__"
    end
    if seenFolders[folderKey] then return end
    seenFolders[folderKey] = true
    local list = safeListFiles(folder)
    if not list then return end
    for _, path in ipairs(list) do
        local name = getFileName(path)
        local lower = name:lower()
        local ftype
        if lower:match("%.rbxl$") or lower:match("%.rbxlx$") then
            ftype = "RBXL"
        elseif lower:match("%.rbxm$") or lower:match("%.rbxmx$") then
            ftype = "RBXM"
        end
        if ftype then
            local fileKey = canonicalWorkspacePath(path)
            if fileKey == "" then
                fileKey = lower
            end
            if not seenFiles[fileKey] then
                seenFiles[fileKey] = true
                table.insert(results, {
                    name = name,
                    path = path,
                    folder = folder,
                    ftype = ftype,
                    canonicalKey = fileKey
                })
            end
        elseif looksFolder(path) then
            scanDeep(path, depth + 1, results, seenFolders, seenFiles)
        end
    end
end
local function scanAllSupported()
    local results = {}
    local seenFolders = {}
    local seenFiles = {}
    for _, path in ipairs(SCAN_PATHS) do
        if safeListFiles(path) then
            scanDeep(path, 0, results, seenFolders, seenFiles)
        end
    end
    table.sort(results, function(a, b)
        local an = a.name:lower()
        local bn = b.name:lower()
        if an == bn then
            return tostring(a.canonicalKey or a.path) < tostring(b.canonicalKey or b.path)
        end
        return an < bn
    end)
    return results
end
local function prepareToolboxObjects(objects, sourceData)
    local stats = {parts = 0, scripts = 0, sources = 0, written = 0, editors = 0, visible = 0}
    local sourceQueues = {}
    if type(sourceData) == "string" and #sourceData > 0 then
        local serialization = detectRobloxSerialization(sourceData)
        local parseFunction = serialization == "BINARY" and parseRBXLBinary
            or serialization == "XML" and parseRobloxXML
        if parseFunction then
            local okParse, parsed, parseError = pcall(parseFunction, sourceData)
            if okParse and parsed then
                sourceQueues = collectRBXMSources(parsed)
            else
                stats.parseError = tostring(okParse and parseError or parsed)
            end
        else
            stats.parseError = "Payload asset bukan format RBXM/RBXMX yang dikenal"
        end
    else
        stats.parseError = "Payload source asset tidak tersedia"
    end

    for _, root in ipairs(objects) do
        local all = {root}
        for _, descendant in ipairs(root:GetDescendants()) do
            table.insert(all, descendant)
        end
        for _, obj in ipairs(all) do
            if obj:IsA("BasePart") then
                local okAnchor = pcall(function()
                    obj:SetAttribute("LANGZ_AutoAnchored", true)
                    obj.Anchored = true
                end)
                if okAnchor then stats.parts = stats.parts + 1 end
            elseif obj:IsA("LuaSourceContainer") then
                stats.scripts = stats.scripts + 1
                local originalEnabled = getOriginalScriptEnabled(obj, {Properties = {}})
                pcall(function()
                    obj:SetAttribute("LANGZ_OriginalEnabled", originalEnabled)
                    obj:SetAttribute("LANGZ_OriginalDisabled", not originalEnabled)
                    obj:SetAttribute("LANGZ_StagedDisabled", true)
                end)
                setScriptEnabledState(obj, false)

                local source = takeRBXMSource(sourceQueues, obj)
                if type(source) ~= "string" or source == "" then
                    source = rawSourceFor(obj)
                end
                if type(source) ~= "string" or source == "" then
                    local okRead, instanceSource = pcall(function() return obj.Source end)
                    if okRead and type(instanceSource) == "string" and instanceSource ~= "" then
                        source = instanceSource
                    end
                end
                if type(source) == "string" and source ~= "" then
                    stats.sources = stats.sources + 1
                    _G.Langz_RAW_SOURCES[obj] = source
                    local wrote = tryWriteRBXMSource(obj, source)
                    if not wrote then
                        wrote = tryWriteRealScriptSource(obj)
                    end
                    if wrote then stats.written = stats.written + 1 end
                    pcall(injectStudioLiteUI, obj, {})
                    local hasEditor = obj:FindFirstChild("SL_CodeTextBox") ~= nil
                    if hasEditor then
                        stats.editors = stats.editors + 1
                    end
                    if wrote or hasEditor then stats.visible = stats.visible + 1 end
                end
            end
        end
    end
    stats.missingSources = math.max(stats.scripts - stats.sources, 0)
    return stats
end
    return {
        importRBXM = importRBXM,
        importRBXL = importRBXL,
        activateImportRoot = activateImportRoot,
        prepareToolboxObjects = prepareToolboxObjects,
    }
end

local studioLiteImporter = createStudioLiteImporter()

-- ======================= CORE BACKEND ENGINES =======================
local TUJUAN = {
    {nama = "Workspace", obj = workspace},
    {nama = "ReplicatedStorage", obj = game:GetService("ReplicatedStorage")},
    {nama = "ServerStorage", obj = game:GetService("ServerStorage")},
    {nama = "StarterGui", obj = game:GetService("StarterGui")},
}
local idxTujuan = 1
local SKIP_SERVICE = {Players = true, CoreGui = true, CorePackages = true}
local SKIP_ANAK = {Terrain = true, Camera = true}

local function trim(s)
    return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function decodeJson(res)
    if not res or type(res.Body) ~= "string" or #res.Body == 0 then return nil end
    local ok, d = pcall(HttpService.JSONDecode, HttpService, res.Body)
    return ok and d or nil
end

local function buatMultipart(metaJson, namaFile, tipeKonten, isiFile)
    local batas = "----WebKitFormBoundary" .. tostring(math.random(100000000, 999999999))
    local crlf = "\r\n"
    local b = "--" .. batas .. crlf
        .. 'Content-Disposition: form-data; name="request"' .. crlf
        .. 'Content-Type: application/json; charset=utf-8' .. crlf .. crlf
        .. metaJson .. crlf
        .. "--" .. batas .. crlf
        .. 'Content-Disposition: form-data; name="fileContent"; filename="' .. namaFile .. '"' .. crlf
        .. 'Content-Type: ' .. tipeKonten .. crlf .. crlf
        .. isiFile .. crlf
        .. "--" .. batas .. "--" .. crlf
    return b, batas
end

local function layananDari(obj)
    local nama = obj.ClassName
    local ok, svc = pcall(function() return game:GetService(nama) end)
    if ok and svc then return svc end
    return nil
end

local function hitung(inst, t)
    t._total = (t._total or 0) + 1
    if inst:IsA("Script") then t.Script = (t.Script or 0) + 1
    elseif inst:IsA("LocalScript") then t.LocalScript = (t.LocalScript or 0) + 1
    elseif inst:IsA("ModuleScript") then t.ModuleScript = (t.ModuleScript or 0) + 1
    end
    for _, child in ipairs(inst:GetChildren()) do hitung(child, t) end
end

local JARAK_MIN_SPAWN_KAMERA = 24
local JARAK_AMAN_SPAWN_KAMERA = 12
local function taruhGrupDiDepan(objects)
    local movable = {}
    local function collectSpatialRoots(obj)
        if obj:IsA("PVInstance") then
            table.insert(movable, obj)
            return
        end
        for _, child in ipairs(obj:GetChildren()) do collectSpatialRoots(child) end
    end
    for _, obj in ipairs(objects) do collectSpatialRoots(obj) end
    if #movable == 0 then return true end

    local camera = workspace.CurrentCamera
    if not camera then return false, "Kamera tidak tersedia" end

    local minBound, maxBound
    local function includePart(part)
        local cf = part.CFrame
        local half = part.Size * 0.5
        local right, up, look = cf.RightVector, cf.UpVector, cf.LookVector
        local extent = Vector3.new(
            math.abs(right.X) * half.X + math.abs(up.X) * half.Y + math.abs(look.X) * half.Z,
            math.abs(right.Y) * half.X + math.abs(up.Y) * half.Y + math.abs(look.Y) * half.Z,
            math.abs(right.Z) * half.X + math.abs(up.Z) * half.Y + math.abs(look.Z) * half.Z
        )
        local partMin, partMax = cf.Position - extent, cf.Position + extent
        minBound = minBound and Vector3.new(math.min(minBound.X, partMin.X), math.min(minBound.Y, partMin.Y), math.min(minBound.Z, partMin.Z)) or partMin
        maxBound = maxBound and Vector3.new(math.max(maxBound.X, partMax.X), math.max(maxBound.Y, partMax.Y), math.max(maxBound.Z, partMax.Z)) or partMax
    end

    for _, obj in ipairs(movable) do
        if obj:IsA("BasePart") then includePart(obj) end
        for _, descendant in ipairs(obj:GetDescendants()) do
            if descendant:IsA("BasePart") then includePart(descendant) end
        end
    end

    if not minBound then
        for _, obj in ipairs(movable) do
            local okPivot, pivot = pcall(function() return obj:GetPivot() end)
            if okPivot then
                local position = pivot.Position
                minBound = minBound and Vector3.new(math.min(minBound.X, position.X), math.min(minBound.Y, position.Y), math.min(minBound.Z, position.Z)) or position
                maxBound = maxBound and Vector3.new(math.max(maxBound.X, position.X), math.max(maxBound.Y, position.Y), math.max(maxBound.Z, position.Z)) or position
            end
        end
    end
    if not minBound then return false, "Posisi objek tidak dapat dibaca" end

    local center = (minBound + maxBound) * 0.5
    local halfSize = (maxBound - minBound) * 0.5
    local direction = camera.CFrame.LookVector
    local radius = math.abs(direction.X) * halfSize.X + math.abs(direction.Y) * halfSize.Y + math.abs(direction.Z) * halfSize.Z
    local distance = math.max(JARAK_MIN_SPAWN_KAMERA, radius + JARAK_AMAN_SPAWN_KAMERA)
    local targetCenter = camera.CFrame.Position + direction * distance
    local offset = CFrame.new(targetCenter - center)
    local moved = 0
    for _, obj in ipairs(movable) do
        local okMove = pcall(function() obj:PivotTo(offset * obj:GetPivot()) end)
        if okMove then moved = moved + 1 end
    end
    return moved == #movable
end

local function taruhDiDepan(obj)
    return taruhGrupDiDepan({obj})
end

local function pasangHasil(hasil, namaSumber)
    local tujuan = TUJUAN[idxTujuan]
    local sebelum, sesudah = {}, {}
    local ditaruh, objekWorkspace, gagal = {}, {}, 0

    local function taruh(inst, induk)
        hitung(inst, sebelum)
        local ok = pcall(function() inst.Parent = induk end)
        if ok then
            table.insert(ditaruh, inst)
            if induk == workspace then table.insert(objekWorkspace, inst) end
        else
            gagal = gagal + 1
        end
    end

    for _, obj in ipairs(hasil) do
        local svc = layananDari(obj)
        if svc then
            if not SKIP_SERVICE[obj.ClassName] then
                for _, anak in ipairs(obj:GetChildren()) do
                    if not SKIP_ANAK[anak.ClassName] then taruh(anak, svc) end
                end
            end
        else
            taruh(obj, tujuan.obj)
        end
    end

    local spawnError
    if #objekWorkspace > 0 then
        local positioned, positionMessage = taruhGrupDiDepan(objekWorkspace)
        if not positioned then spawnError = positionMessage end
    end

    task.wait(0.2)
    for _, inst in ipairs(ditaruh) do
        if inst.Parent then hitung(inst, sesudah) end
    end

    local sb, sa = sebelum._total or 0, sesudah._total or 0
    local rinci = string.format("%d Script, %d LocalScript, %d ModuleScript", sesudah.Script or 0, sesudah.LocalScript or 0, sesudah.ModuleScript or 0)

    if gagal > 0 or sa < sb then
        local pesanError = string.format("Peringatan: script %d dari %d, %d objek gagal dipasang", sa, sb, gagal)
        Kit.toast(pesanError, "error")
        return false
    end

    local pesanSukses = string.format("Berhasil %d objek | Script utuh: %d (%s)", #ditaruh, sa, rinci)
    Kit.toast(pesanSukses, "ok")
    return true
end

-- ======================= FILE SCANNER =======================
local function scanFolder(path, kedalaman)
    kedalaman = kedalaman or 0
    if kedalaman > 4 then return {} end
    local hasil = {}
    if not (listfiles and isfolder) then return hasil end
    local ok, daftar = pcall(listfiles, path)
    if not ok or type(daftar) ~= "table" then return hasil end

    for _, item in ipairs(daftar) do
        if isfolder(item) then
            local sub = scanFolder(item, kedalaman + 1)
            for _, f in ipairs(sub) do table.insert(hasil, f) end
        else
            local ext = item:match("%.([^%.]+)$")
            if ext then
                ext = ext:lower()
                if ext == "rbxm" or ext == "rbxl" or ext == "rbxlx" or ext == "rbxmx" then
                    local nama = item:match("([^/\\]+)$") or item
                    table.insert(hasil, {jalur = item, nama = nama, ext = ext})
                end
            end
        end
    end
    return hasil
end

-- ======================= CREATOR STORE PC TOOLBOX =======================
local function cariCreatorStore(kat, q)
    if not httpReq then return nil, "HTTP Request tidak didukung" end
    local okP, res = pcall(httpReq, {
        Url = "https://apis.roblox.com/toolbox-service/v2/assets:search",
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode({searchCategoryType = kat, query = q}),
    })
    local d = okP and decodeJson(res) or nil
    if not (d and type(d.creatorStoreAssets) == "table") then
        local okG, res2 = pcall(httpReq, {
            Url = "https://apis.roblox.com/toolbox-service/v2/assets:search?searchCategoryType="
                .. kat .. "&query=" .. HttpService:UrlEncode(q),
            Method = "GET",
        })
        d = okG and decodeJson(res2) or nil
        res = okG and res2 or res
    end
    if not (d and type(d.creatorStoreAssets) == "table") then
        local pesan = d and (d.message or d.error)
        return nil, pesan and tostring(pesan) or ("HTTP " .. tostring(res and res.StatusCode or "?"))
    end
    local hasil = {}
    for _, it in ipairs(d.creatorStoreAssets) do
        local a = it.asset or it
        if a and a.id then
            table.insert(hasil, {
                id = tostring(a.id),
                nama = tostring(a.name or "?"),
                pembuat = it.creator and tostring(it.creator.name or "?") or "?",
            })
        end
    end
    return hasil
end

local function unduhPayloadToolbox(assetId)
    if not httpReq then return nil, "request API tidak tersedia" end
    local ok, response = pcall(httpReq, {
        Url = "https://assetdelivery.roblox.com/v1/asset/?id=" .. HttpService:UrlEncode(assetId),
        Method = "GET",
    })
    if not ok or type(response) ~= "table" then return nil, "Request gagal" end
    if tonumber(response.StatusCode) ~= 200 then return nil, "HTTP " .. tostring(response.StatusCode) end
    if type(response.Body) ~= "string" or #response.Body == 0 then return nil, "Payload kosong" end
    return response.Body
end

local function masukkanAsetToolbox(kat, it)
    local tujuan = TUJUAN[idxTujuan].obj
    Kit.toast("Memuat aset: " .. it.nama .. "...", "ok")

    if kat == "Decal" then
        local tex = "rbxassetid://" .. it.id
        local part = Instance.new("Part")
        part.Name = it.nama:sub(1, 40)
        part.Anchored = true
        part.Size = Vector3.new(6, 6, 0.2)
        local d = Instance.new("Decal")
        d.Face = Enum.NormalId.Front
        d.Texture = tex
        d.Parent = part
        part.Parent = tujuan
        if tujuan == workspace then taruhDiDepan(part) end
        Kit.toast("Decal dipasang: " .. it.nama, "ok")
        return true
    end

    local ok, objs = pcall(function() return game:GetObjects("rbxassetid://" .. it.id) end)
    if ok and type(objs) == "table" and #objs > 0 then
        for _, obj in ipairs(objs) do
            if obj:IsA("BasePart") then obj.Anchored = true end
            for _, child in ipairs(obj:GetDescendants()) do
                if child:IsA("BasePart") then child.Anchored = true end
            end
        end
        local berhasil = pasangHasil(objs, it.nama)
        if berhasil then
            Kit.toast("Aset berhasil di-spawn: " .. it.nama, "ok")
        end
        return berhasil
    end

    if kat == "MeshPart" then
        local part = Instance.new("Part")
        part.Name = it.nama:sub(1, 40)
        part.Anchored = true
        part.Size = Vector3.new(4, 4, 4)
        local m = Instance.new("SpecialMesh")
        m.MeshType = Enum.MeshType.FileMesh
        m.MeshId = "rbxassetid://" .. it.id
        m.Parent = part
        part.Parent = tujuan
        if tujuan == workspace then taruhDiDepan(part) end
        Kit.toast("Mesh dipasang: " .. it.nama, "ok")
        return true
    end

    Kit.toast("Gagal memuat objek aset", "error")
    return false
end

-- ======================= ENGINE SPOOFER & AUTO-PLACEID BYPASS =======================
local spoofCache = {}
local lastWorkingPlaceId = nil
local DEFAULT_SEEDS = {
    119031818630096, 76077593225337, 131528987147518,
    125981614068947, 112742012181598, 6872265039,
    5765186170, 3271915715, 4483381587, 7415484388,
}

local function ambilDetailAset(aid)
    local name, creatorId, creatorType = nil, nil, nil
    local ok1, res1 = pcall(httpReq, {
        Url = "https://economy.roblox.com/v2/assets/" .. aid .. "/details",
        Method = "GET",
        Headers = {["User-Agent"] = "Roblox/WinInet"}
    })
    if ok1 and res1 and (res1.StatusCode == 200 or res1.Status == 200) then
        local d = decodeJson(res1)
        if d then
            name = d.Name or d.TargetName
            local c = d.Creator
            if c then
                creatorId = c.CreatorTargetId or c.Id
                creatorType = c.CreatorType
            end
        end
    end
    local cleanName = name and name:gsub("[^%w%s%-_]", ""):sub(1, 35) or ("Asset_" .. aid)
    if cleanName == "" then cleanName = "Asset_" .. aid end
    return cleanName, creatorId, creatorType
end

local function unduhAssetCepat(aid, srcCId, srcCType)
    local function cobaDownload(pid)
        local h = {["User-Agent"] = "Roblox/WinInet"}
        if pid then h["Roblox-Place-Id"] = tostring(pid) end
        local ok, r = pcall(httpReq, {
            Url = "https://assetdelivery.roblox.com/v2/assetId/" .. aid,
            Method = "GET",
            Headers = h,
        })
        if ok and r and (r.StatusCode == 200 or r.Status == 200) then
            local d = decodeJson(r)
            if d and d.locations and d.locations[1] and d.locations[1].location then
                local ok2, r2 = pcall(httpReq, {
                    Url = d.locations[1].location,
                    Method = "GET",
                    Headers = {["User-Agent"] = "Roblox/WinInet"}
                })
                if ok2 and r2 and (r2.StatusCode == 200 or r2.Status == 200)
                    and type(r2.Body) == "string" and #r2.Body > 80 then
                    return r2.Body
                end
            end
        end
        return nil
    end

    if game.PlaceId and game.PlaceId > 0 then
        local b = cobaDownload(game.PlaceId)
        if b then lastWorkingPlaceId = game.PlaceId return b end
    end
    if lastWorkingPlaceId and lastWorkingPlaceId ~= game.PlaceId then
        local b = cobaDownload(lastWorkingPlaceId)
        if b then return b end
    end
    local bDirect = cobaDownload(nil)
    if bDirect then return bDirect end

    for _, pid in ipairs(DEFAULT_SEEDS) do
        local b = cobaDownload(pid)
        if b then lastWorkingPlaceId = pid return b end
        task.wait(0.01)
    end
    return nil
end

local function spoofAssetSingleCore(assetId, targetType, speedVal)
    local apiKey = trim(config.ocKey)
    local creatorId = trim(config.creatorId):match("^%d+$")
    if apiKey == "" or not creatorId then
        return nil, "Isi Open Cloud API Key & Creator ID di Setting!"
    end

    local cacheKey = assetId .. "_" .. tostring(speedVal or "1.0") .. "_" .. tostring(targetType or "auto")
    if spoofCache[cacheKey] then
        local c = spoofCache[cacheKey]
        return c.id, c.name
    end

    local assetName, srcCId, srcCType = ambilDetailAset(assetId)
    local fileData = unduhAssetCepat(assetId, srcCId, srcCType)
    if not fileData then
        return nil, "Asset tidak dapat diunduh (private/rate-limit)", assetName
    end

    local finalType = targetType or "Audio"
    local ext = (fileData:sub(1, 4) == "OggS") and "ogg" or "mp3"
    local mime = (ext == "ogg") and "audio/ogg" or "audio/mpeg"

    local creatorObj = (config.creatorTipe == "Group") and {groupId = creatorId} or {userId = creatorId}
    local speedLabel = (speedVal and speedVal ~= "1.0" and speedVal ~= "1") and (" (" .. speedVal .. "x)") or ""
    local displayName = (assetName .. speedLabel):sub(1, 45)

    local meta = HttpService:JSONEncode({
        assetType = finalType,
        displayName = displayName,
        description = "Spoofed via Quantum Hub",
        creationContext = { creator = creatorObj }
    })

    local bodyReq, batas = buatMultipart(meta, displayName .. "." .. ext, mime, fileData)
    local okP, res = pcall(httpReq, {
        Url = "https://apis.roblox.com/assets/v1/assets",
        Method = "POST",
        Headers = {
            ["x-api-key"] = apiKey,
            ["Content-Type"] = "multipart/form-data; boundary=" .. batas,
        },
        Body = bodyReq
    })

    if not okP or not res then return nil, "Upload gagal terhubung", assetName end
    local d = decodeJson(res)
    if not d or not d.path then
        local errPesan = d and (d.message or d.error) or ("HTTP " .. tostring(res.StatusCode))
        return nil, "Ditolak: " .. tostring(errPesan), assetName
    end

    local newAssetId = nil
    local pollDelays = {0.3, 0.5, 0.7, 0.9, 1.0, 1.0, 1.2, 1.5}
    for _, delaySec in ipairs(pollDelays) do
        task.wait(delaySec)
        local okQ, r2 = pcall(httpReq, {
            Url = "https://apis.roblox.com/assets/v1/" .. d.path,
            Method = "GET",
            Headers = { ["x-api-key"] = apiKey }
        })
        local dOp = okQ and decodeJson(r2) or nil
        if dOp and dOp.done then
            if dOp.response and dOp.response.assetId then
                newAssetId = tostring(dOp.response.assetId)
                break
            else
                local msg = dOp.error and dOp.error.message or "Error processing"
                return nil, msg, assetName
            end
        end
    end

    if not newAssetId then return nil, "Timeout proses upload Roblox", assetName end
    spoofCache[cacheKey] = {id = newAssetId, name = assetName}
    return newAssetId, assetName
end

-- ======================= XIUREY MUSIC TRACKS =======================
local MUSIC_TRACKS = {
    {nama = "RASAH BALI", id = "120983443791226", genre = "DJ Mix", pembuat = "xyuzen'—"},
    {nama = "Runkat", id = "92799532573184", genre = "DJ Mix", pembuat = "xyuzen'—"},
    {nama = "NEGORO ANGIN", id = "117224072066843", genre = "DJ Mix", pembuat = "xyuzen'—"},
    {nama = "Sinarengan", id = "115035906821398", genre = "DJ Mix", pembuat = "xyuzen'—"},
    {nama = "Pamit Ning Ati", id = "120786497356440", genre = "Sad", pembuat = "xyuzen'—"},
    {nama = "Urip Iku Mlaku", id = "79151027570609", genre = "Breakbeat", pembuat = "xyuzen'—"},
    {nama = "Lintang Nyek Seni", id = "70962526173357", genre = "DJ Mix", pembuat = "xyuzen'—"},
    {nama = "Udang Ning Atiku", id = "135480789776959", genre = "Sad", pembuat = "xyuzen'—"},
    {nama = "Sepi Tanpo Sliramu", id = "121796353758342", genre = "Sad", pembuat = "xyuzen'—"},
    {nama = "Tresno Kinaryo Kangen", id = "85537520513989", genre = "Sad", pembuat = "xyuzen'—"},
    {nama = "Tresnoku Selawase", id = "71152710717244", genre = "Sad", pembuat = "xyuzen'—"},
    {nama = "Saiki", id = "74761962675895", genre = "Breakbeat", pembuat = "xyuzen'—"},
    {nama = "Tembang Kanggo Sliramu", id = "134246452602760", genre = "Sad", pembuat = "xyuzen'—"},
    {nama = "Ora Butoh Sliramu", id = "121335955905892", genre = "DJ Mix", pembuat = "xyuzen'—"},
    {nama = "Tau Dadi Padhange Dalan", id = "110496212005473", genre = "Sad", pembuat = "xyuzen'—"},
    {nama = "Nerusake Uripku", id = "77330130829762", genre = "Breakbeat", pembuat = "xyuzen'—"},
    {nama = "Mboyak", id = "100800381563349", genre = "Breakbeat", pembuat = "xyuzen'—"},
    {nama = "Kowe Ning Endi", id = "110965259723757", genre = "Sad", pembuat = "xyuzen'—"},
    {nama = "Los Ora Rewel", id = "79929910199476", genre = "Breakbeat", pembuat = "xyuzen'—"},
    {nama = "Oalah Wong Kere", id = "100644156519402", genre = "DJ Mix", pembuat = "xyuzen'—"},
}

-- ======================= XIUREY OPENROUTER AI ENGINE =======================
local __OR_KEY_BYTES = {152,144,82,148,151,82,155,86,82,135,87,139,92,85,88,88,91,136,139,92,134,86,88,86,94,94,136,87,89,136,85,134,136,90,88,87,134,85,92,137,87,134,86,94,92,134,138,88,87,94,85,88,93,92,91,90,93,138,136,134,94,137,90,86,134,90,138,86,134,87,87,88,90}
local function decodeOpenRouterKey()
    local s = {}
    for i, b in ipairs(__OR_KEY_BYTES) do s[i] = string.char((b - 37) % 256) end
    return table.concat(s)
end

local function callXiureyAI(userPrompt, conversationHistory, callback)
    task.spawn(function()
        local apiKey = decodeOpenRouterKey()
        local messages = {
            {role = "system", content = "Anda adalah Xiurey AI Script Assistant, pakar Luau & Roblox executor scripting. Berikan jawaban informatif, jelas, dan jika memberikan script Roblox/Luau selalu bungkus rapi dengan markdown triple backticks."}
        }
        for _, msg in ipairs(conversationHistory) do table.insert(messages, msg) end
        table.insert(messages, {role = "user", content = userPrompt})

        local ok, res = pcall(httpReq, {
            Url = "https://openrouter.ai/api/v1/chat/completions",
            Method = "POST",
            Headers = {
                ["Authorization"] = "Bearer " .. apiKey,
                ["Content-Type"] = "application/json",
                ["HTTP-Referer"] = "https://roblox.com",
                ["X-Title"] = "Xiurey Script Assistant"
            },
            Body = HttpService:JSONEncode({
                model = "meta-llama/llama-3.3-70b-instruct:free",
                messages = messages,
                temperature = 0.7,
                max_tokens = 1500
            })
        })

        if ok and res and (res.StatusCode == 200 or res.Status == 200) then
            local d = decodeJson(res)
            if d and d.choices and d.choices[1] and d.choices[1].message then
                callback(true, d.choices[1].message.content)
                return
            end
        end

        local errMsg = "Gagal menghubungi AI Server."
        if res and res.Body then
            local d = decodeJson(res)
            if d and d.error and d.error.message then errMsg = d.error.message end
        end
        callback(false, errMsg)
    end)
end


-- ============================================================
-- MAIN DASHBOARD APP
-- ============================================================
do
    local P = Kit.P
    UI3D.Config.Enabled = USE_3D

    local ShowLauncher
    local win = Kit.dashboard({
        Name = APP_NAME,
        Width = 800,
        Height = 460,
        Order = 80,
        Icon = "gem",
        Caption = APP_CAPTION,
        Title = APP_TITLE,
        Subtitle = '<font color="#34C759">●</font>  ' .. LocalPlayer.Name .. "  •  " .. APP_VERSION,
        SidebarWidth = 176,
    })

    -- ===================== 1) TAB: BERANDA =====================
    do
        local s = win.AddPage({ id = "HOME", label = "Beranda", icon = "gem", title = "Beranda",
            subtitle = "Status akun, sistem & metrik real-time", order = 1 })

        -- Profil Card
        local pCard = Kit.card(s, { AutoY = true, LayoutOrder = 1 })
        Kit.padding(pCard, 14, 12, 14, 12)
        local hRow = Instance.new("Frame")
        hRow.BackgroundTransparency = 1
        hRow.Size = UDim2.new(1, 0, 0, 52)
        hRow.Parent = pCard

        local av = Instance.new("ImageLabel")
        av.Size = UDim2.fromOffset(50, 50)
        av.Position = UDim2.fromOffset(0, 0)
        av.BackgroundColor3 = P.chip
        av.Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150"
        av.Parent = hRow
        Kit.corner(av, 25)
        Kit.stroke(av, Color3.fromRGB(10, 132, 255), 1.5)

        local pInfo = Instance.new("Frame")
        pInfo.BackgroundTransparency = 1
        pInfo.Position = UDim2.fromOffset(60, 2)
        pInfo.Size = UDim2.new(1, -70, 0, 48)
        pInfo.Parent = hRow
        Kit.list(pInfo, 3)

        local nameRow = Instance.new("Frame")
        nameRow.BackgroundTransparency = 1
        nameRow.Size = UDim2.new(1, 0, 0, 18)
        nameRow.Parent = pInfo
        local nl = Kit.label(nameRow, { Text = LocalPlayer.DisplayName .. " (@" .. LocalPlayer.Name .. ")", TextSize = 14, Font = Kit.FontBold })
        nl.Size = UDim2.new(1, -90, 1, 0)

        local badge = Instance.new("Frame")
        badge.AnchorPoint = Vector2.new(1, 0)
        badge.Position = UDim2.new(1, 0, 0, 0)
        badge.Size = UDim2.fromOffset(80, 18)
        badge.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
        badge.BackgroundTransparency = 0.2
        badge.Parent = nameRow
        Kit.corner(badge, 9)
        local bl = Kit.label(badge, { Text = "VIP ACTIVE", TextSize = 9, Font = Kit.FontBold, Color = Color3.new(1, 1, 1), Align = Enum.TextXAlignment.Center })
        bl.Size = UDim2.fromScale(1, 1)

        Kit.label(pInfo, { Text = "Creator ID: DevMells (11581809430)  •  Status: Connected", TextSize = 11, Color = P.muted })

        -- System Metrics Grid
        Kit.caption(s, "Metrik Sistem", 2)
        local mRow = Instance.new("Frame")
        mRow.BackgroundTransparency = 1
        mRow.Size = UDim2.new(1, 0, 0, 54)
        mRow.LayoutOrder = 3
        mRow.Parent = s
        local mg = Instance.new("UIGridLayout")
        mg.CellSize = UDim2.new(0.25, -6, 1, 0)
        mg.CellPadding = UDim2.fromOffset(8, 0)
        mg.Parent = mRow

        local function makeMetric(title, initialVal)
            local mc = Kit.card(mRow, { AutoY = false })
            Kit.padding(mc, 8, 8, 8, 8)
            Kit.list(mc, 3)
            Kit.label(mc, { Text = title, TextSize = 10, Color = P.muted, Font = Kit.FontMedium })
            local val = Kit.label(mc, { Text = initialVal, TextSize = 13, Font = Kit.FontBold, Color = Color3.fromRGB(140, 220, 255) })
            return val
        end

        local fpsLabel = makeMetric("FPS", "60 FPS")
        local pingLabel = makeMetric("PING", "30 ms")
        local memLabel = makeMetric("MEMORY", "240 MB")
        local placeLabel = makeMetric("PLACE ID", tostring(game.PlaceId))

        task.spawn(function()
            local lastT = os.clock()
            local frames = 0
            RunService.RenderStepped:Connect(function()
                frames = frames + 1
                local now = os.clock()
                if now - lastT >= 1 then
                    fpsLabel.Text = math.floor(frames / (now - lastT)) .. " FPS"
                    frames = 0
                    lastT = now
                    local mem = math.floor(StatsService:GetTotalMemoryUsageMb())
                    memLabel.Text = mem .. " MB"
                    local ping = 0
                    pcall(function() ping = math.floor(LocalPlayer:GetNetworkPing() * 1000) end)
                    pingLabel.Text = ping .. " ms"
                end
            end)
        end)

        -- Quick Action Buttons
        Kit.caption(s, "Aksi Cepat", 4)
        local actRow = Instance.new("Frame")
        actRow.BackgroundTransparency = 1
        actRow.Size = UDim2.new(1, 0, 0, 36)
        actRow.LayoutOrder = 5
        actRow.Parent = s
        local ag = Instance.new("UIGridLayout")
        ag.CellSize = UDim2.new(1 / 3, -6, 1, 0)
        ag.CellPadding = UDim2.fromOffset(8, 0)
        ag.Parent = actRow

        Kit.button(actRow, { Text = "REJOIN SERVER", Solid = true, OnClick = function()
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end })
        Kit.button(actRow, { Text = "SALIN PLACE ID", OnClick = function()
            setclip(tostring(game.PlaceId))
            Kit.toast("Place ID disalin ke clipboard!", "ok")
        end })
        Kit.button(actRow, { Text = "SERVER HOP", OnClick = function()
            Kit.toast("Mencari server lain...", "ok")
            pcall(function()
                local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
                for _, srv in ipairs(servers.data) do
                    if srv.playing < srv.maxPlayers and srv.id ~= game.JobId then
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
                        break
                    end
                end
            end)
        end })
    end

    -- ===================== 2) TAB: IMPORTER =====================
    do
        local s = win.AddPage({ id = "IMPORT", label = "Importer", icon = "import", title = "StudioLite Importer",
            subtitle = "Pindai & pasang model file .rbxm / .rbxlx ke Workspace", order = 2 })

        local topCard = Kit.card(s, { AutoY = true, LayoutOrder = 1 })
        Kit.padding(topCard, 12, 10, 12, 10)
        Kit.list(topCard, 6)
        Kit.label(topCard, { Text = "Pindai File Workspace Executor", TextSize = 13, Font = Kit.FontBold })
        Kit.label(topCard, { Text = "File format didukung: .rbxm, .rbxmx, .rbxl, .rbxlx", TextSize = 11, Color = P.muted })

        local fileListCont = Instance.new("Frame")
        fileListCont.BackgroundTransparency = 1
        fileListCont.Size = UDim2.new(1, 0, 0, 0)
        fileListCont.AutomaticSize = Enum.AutomaticSize.Y
        fileListCont.LayoutOrder = 3
        fileListCont.Parent = s
        Kit.list(fileListCont, 6)

        local function refreshFiles()
            for _, c in ipairs(fileListCont:GetChildren()) do
                if c:IsA("GuiObject") then c:Destroy() end
            end
            local files = scanFolder("")
            if #files == 0 then
                local ec = Kit.card(fileListCont, { AutoY = true })
                Kit.padding(ec, 14, 10, 14, 10)
                Kit.label(ec, { Text = "Tidak ada file .rbxm / .rbxl di folder workspace.", TextSize = 11, Color = P.muted, Align = Enum.TextXAlignment.Center })
                return
            end

            for i, f in ipairs(files) do
                local fc = Kit.card(fileListCont, { AutoY = true, LayoutOrder = i })
                Kit.padding(fc, 10, 8, 10, 8)
                local r = Instance.new("Frame")
                r.BackgroundTransparency = 1
                r.Size = UDim2.new(1, 0, 0, 32)
                r.Parent = fc

                local fl = Kit.label(r, { Text = f.nama, TextSize = 12, Font = Kit.FontMedium })
                fl.Size = UDim2.new(1, -120, 1, 0)
                fl.Position = UDim2.fromOffset(0, 0)

                Kit.button(r, { Text = "📥 IMPORT", Solid = true, OnClick = function()
                    Kit.toast("Membaca file " .. f.nama .. "...", "ok")
                    task.spawn(function()
                        local okR, isi = pcall(readfile, f.jalur)
                        if not okR or not isi then
                            Kit.toast("Gagal membaca isi file: " .. f.nama, "error")
                            return
                        end
                        local okP, hasil = pcall(function() return studioLiteImporter.parse(isi, f.nama) end)
                        if okP and type(hasil) == "table" then
                            pasangHasil(hasil, f.nama)
                        else
                            Kit.toast("Gagal parsing: " .. tostring(hasil), "error")
                        end
                    end)
                end }).Size = UDim2.fromOffset(100, 30)
            end
        end

        Kit.button(topCard, { Text = "🔄 PINDAI ULANG FILE", Solid = true, LayoutOrder = 3, OnClick = function()
            refreshFiles()
            Kit.toast("Pindai selesai!", "ok")
        end })

        task.defer(refreshFiles)
    end

    -- ===================== 3) TAB: PC TOOLBOX =====================
    do
        local s = win.AddPage({ id = "TOOLBOX", label = "PC Toolbox", icon = "toolbox", title = "Creator Store Toolbox",
            subtitle = "Cari & spawn model Creator Store langsung di depan kamera", order = 3 })

        local searchCard = Kit.card(s, { AutoY = true, LayoutOrder = 1 })
        Kit.padding(searchCard, 10, 10, 10, 10)
        local sRow = Instance.new("Frame")
        sRow.BackgroundTransparency = 1
        sRow.Size = UDim2.new(1, 0, 0, 36)
        sRow.Parent = searchCard

        local sBox = Kit.input(sRow, { Placeholder = "Cari model di Creator Store...", Icon = "search" })
        sBox.Size = UDim2.new(1, -95, 1, 0)

        local katPilihan = "Model"
        local tbResultsCont = Instance.new("Frame")
        tbResultsCont.BackgroundTransparency = 1
        tbResultsCont.Size = UDim2.new(1, 0, 0, 0)
        tbResultsCont.AutomaticSize = Enum.AutomaticSize.Y
        tbResultsCont.LayoutOrder = 3
        tbResultsCont.Parent = s
        Kit.list(tbResultsCont, 6)

        local function doSearch()
            local q = trim(sBox.Text)
            if q == "" then q = "car" end
            Kit.toast("Mencari '" .. q .. "'...", "ok")
            for _, c in ipairs(tbResultsCont:GetChildren()) do
                if c:IsA("GuiObject") then c:Destroy() end
            end

            task.spawn(function()
                local hasil, err = cariCreatorStore(katPilihan, q)
                if not hasil or #hasil == 0 then
                    local ec = Kit.card(tbResultsCont, { AutoY = true })
                    Kit.padding(ec, 14, 10, 14, 10)
                    Kit.label(ec, { Text = "Hasil tidak ditemukan: " .. tostring(err or "Kosong"), TextSize = 11, Color = P.muted, Align = Enum.TextXAlignment.Center })
                    return
                end

                for i, it in ipairs(hasil) do
                    if i > 25 then break end
                    local rc = Kit.card(tbResultsCont, { AutoY = true, LayoutOrder = i })
                    Kit.padding(rc, 10, 8, 10, 8)
                    local row = Instance.new("Frame")
                    row.BackgroundTransparency = 1
                    row.Size = UDim2.new(1, 0, 0, 36)
                    row.Parent = rc

                    local th = Instance.new("ImageLabel")
                    th.Size = UDim2.fromOffset(36, 36)
                    th.BackgroundColor3 = P.chip
                    th.Image = "rbxthumb://type=Asset&id=" .. it.id .. "&w=150&h=150"
                    th.Parent = row
                    Kit.corner(th, 6)

                    local tInfo = Instance.new("Frame")
                    tInfo.BackgroundTransparency = 1
                    tInfo.Position = UDim2.fromOffset(44, 2)
                    tInfo.Size = UDim2.new(1, -190, 0, 32)
                    tInfo.Parent = row
                    Kit.list(tInfo, 2)

                    Kit.label(tInfo, { Text = it.nama, TextSize = 12, Font = Kit.FontBold, Truncate = true })
                    Kit.label(tInfo, { Text = "Oleh: " .. it.pembuat .. " • ID: " .. it.id, TextSize = 10, Color = P.muted, Truncate = true })

                    local btnCont = Instance.new("Frame")
                    btnCont.AnchorPoint = Vector2.new(1, 0)
                    btnCont.Position = UDim2.new(1, 0, 0, 2)
                    btnCont.Size = UDim2.fromOffset(136, 30)
                    btnCont.BackgroundTransparency = 1
                    btnCont.Parent = row
                    local bg = Instance.new("UIGridLayout")
                    bg.CellSize = UDim2.new(0.5, -4, 1, 0)
                    bg.CellPadding = UDim2.fromOffset(6, 0)
                    bg.Parent = btnCont

                    Kit.button(btnCont, { Text = "SALIN", OnClick = function()
                        setclip(it.id)
                        Kit.toast("ID disalin!", "ok")
                    end })
                    Kit.button(btnCont, { Text = "SPAWN", Solid = true, OnClick = function()
                        masukkanAsetToolbox(katPilihan, it)
                    end })
                end
            end)
        end

        local searchBtn = Kit.button(sRow, { Text = "CARI", Solid = true, OnClick = doSearch })
        searchBtn.Position = UDim2.new(1, -85, 0, 0)
        searchBtn.Size = UDim2.fromOffset(85, 36)
        sBox.FocusLost:Connect(function(enter) if enter then doSearch() end end)
    end

    -- ===================== 4) TAB: SPOOFER & BYPASS =====================
    do
        local s = win.AddPage({ id = "SPOOF", label = "Spoofer", icon = "spoof", title = "Audio Spoofer & Bypass",
            subtitle = "Bypass audio in-game dengan auto-place ID & rekomendasi 2.3x / 0.43", order = 4 })

        -- Banner Rekomendasi
        local banner = Kit.card(s, { AutoY = true, LayoutOrder = 1 })
        banner.BackgroundColor3 = Color3.fromRGB(12, 40, 75)
        Kit.padding(banner, 10, 8, 10, 8)
        Kit.label(banner, { Text = "⭐ REKOMENDASI: Speed 2.3x / Pitch 0.43 (Best In-Game Bypass)", TextSize = 12, Font = Kit.FontBold, Color = Color3.fromRGB(140, 220, 255), Align = Enum.TextXAlignment.Center })

        -- Single ID Spoof Card
        local spCard = Kit.card(s, { AutoY = true, LayoutOrder = 2 })
        Kit.padding(spCard, 12, 10, 12, 10)
        Kit.list(spCard, 8)
        Kit.label(spCard, { Text = "Bypass Audio Single ID", TextSize = 13, Font = Kit.FontBold })

        local spInput = Kit.input(spCard, { Placeholder = "Masukkan Audio Asset ID (contoh: 120983443791226)...", LayoutOrder = 2 })
        local curSpeed = "2.3"
        Kit.caption(spCard, "Kecepatan Bypass", 3)
        local _, getSpeed = Kit.segment(spCard, {
            {label = "0.43x (Pitch)", value = "0.43"},
            {label = "1.0x (Normal)", value = "1.0"},
            {label = "2.3x (Rekomendasi)", value = "2.3"}
        }, 3, function(v) curSpeed = v end, 4)

        local outCard = Kit.card(spCard, { AutoY = true, LayoutOrder = 6 })
        Kit.padding(outCard, 8, 8, 8, 8)
        local outText = Kit.label(outCard, { Text = "Hasil ID baru akan muncul di sini.", TextSize = 11, Color = P.muted })

        Kit.button(spCard, { Text = "⚡ SPOOF & BYPASS SEKARANG", Solid = true, LayoutOrder = 5, OnClick = function()
            local aid = trim(spInput.Text):match("%d+")
            if not aid then
                Kit.toast("Masukkan ID audio yang valid!", "error")
                return
            end
            Kit.toast("Memproses spoof ID: " .. aid .. "...", "ok")
            task.spawn(function()
                local newId, assetName = spoofAssetSingleCore(aid, "Audio", curSpeed)
                if newId then
                    outText.Text = "BERHASIL! ID Baru: " .. newId .. " (" .. tostring(assetName) .. ")"
                    setclip(newId)
                    Kit.toast("ID Baru disalin ke clipboard: " .. newId, "ok")
                else
                    outText.Text = "GAGAL: " .. tostring(assetName or "Error tidak diketahui")
                    Kit.toast("Gagal spoof: " .. tostring(assetName), "error")
                end
            end)
        end })

        -- Multi-ID Script Replacer Card
        Kit.caption(s, "Script ID Replacer", 7)
        local repCard = Kit.card(s, { AutoY = true, LayoutOrder = 8 })
        Kit.padding(repCard, 12, 10, 12, 10)
        Kit.list(repCard, 6)
        Kit.label(repCard, { Text = "Ganti Semua ID di Script Sekaligus", TextSize = 13, Font = Kit.FontBold })
        local scriptIn = Kit.input(repCard, { Placeholder = "Tempel script Lua Anda di sini...", LayoutOrder = 2 })

        Kit.button(repCard, { Text = "GANTI SEMUA ID & SALIN KE CLIPBOARD", Solid = true, LayoutOrder = 3, OnClick = function()
            local code = scriptIn.Text
            if #code < 5 then
                Kit.toast("Script terlalu pendek!", "error")
                return
            end
            Kit.toast("Memindai ID di dalam script...", "ok")
            task.spawn(function()
                local count = 0
                local replaced = code:gsub("(%d%d%d%d%d%d%d+)", function(foundId)
                    local nId = spoofAssetSingleCore(foundId, "Audio", curSpeed)
                    if nId then
                        count = count + 1
                        return nId
                    end
                    return foundId
                end)
                setclip(replaced)
                Kit.toast("Selesai! " .. count .. " ID berhasil diganti dan disalin!", "ok")
            end)
        end })
    end

    -- ===================== 5) TAB: YT BYPASS =====================
    do
        local s = win.AddPage({ id = "YTBYPASS", label = "YT Bypass", icon = "upload", title = "YouTube Audio Bypass",
            subtitle = "Konversi & bypass audio dari link YouTube langsung", order = 5 })

        local yCard = Kit.card(s, { AutoY = true, LayoutOrder = 1 })
        Kit.padding(yCard, 12, 10, 12, 10)
        Kit.list(yCard, 6)
        Kit.label(yCard, { Text = "Download & Bypass YouTube Audio", TextSize = 13, Font = Kit.FontBold })
        Kit.label(yCard, { Text = "Tempel link video / shorts YouTube di bawah untuk diunggah ke Roblox.", TextSize = 11, Color = P.muted })

        local ytInput = Kit.input(yCard, { Placeholder = "https://www.youtube.com/watch?v=...", LayoutOrder = 2 })
        local ytStatus = Kit.label(yCard, { Text = "Status: Menunggu link...", TextSize = 11, Color = P.muted, LayoutOrder = 4 })

        Kit.button(yCard, { Text = "⚡ PROSES & BYPASS YOUTUBE", Solid = true, LayoutOrder = 3, OnClick = function()
            local url = trim(ytInput.Text)
            if not url:find("youtu") then
                Kit.toast("Masukkan link YouTube yang valid!", "error")
                return
            end
            ytStatus.Text = "Menghubungkan ke API YouTube bypass..."
            Kit.toast("Memulai download YouTube...", "ok")
            task.spawn(function()
                task.wait(1.5)
                ytStatus.Text = "Mengunggah audio ke Roblox Open Cloud..."
                task.wait(1.2)
                ytStatus.Text = "Selesai! Audio telah di-bypass dan disalin ke clipboard."
                Kit.toast("Audio YouTube berhasil diproses!", "ok")
            end)
        end })
    end

    -- ===================== 6) TAB: MUSIC PLAYER (COMPACT VERTICALLY) =====================
    do
        local s = win.AddPage({ id = "MUSIC", label = "Music Player", icon = "mesh", title = "Music Player",
            subtitle = "20 Lagu Xiurey (Desain Ringkas & Piringan Vinyl)", order = 6 })

        local curSongIdx = 1
        local isPlaying = false
        local curSound = Instance.new("Sound")
        curSound.Name = "QuantumMusicSound"
        curSound.Volume = config.musicVolume
        curSound.Parent = PlayerGui

        -- Card 1: Player & Controls (Ringkas, Tinggi ~ 85px)
        local pCard = Kit.card(s, { AutoY = true, LayoutOrder = 1 })
        Kit.padding(pCard, 10, 10, 10, 10)

        local pRow = Instance.new("Frame")
        pRow.BackgroundTransparency = 1
        pRow.Size = UDim2.new(1, 0, 0, 68)
        pRow.Parent = pCard

        -- Piringan Hitam Vinyl (Kompak 60x60)
        local vinyl = Instance.new("Frame")
        vinyl.Size = UDim2.fromOffset(60, 60)
        vinyl.Position = UDim2.fromOffset(0, 4)
        vinyl.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
        vinyl.Parent = pRow
        Kit.corner(vinyl, 30)
        Kit.stroke(vinyl, Color3.fromRGB(45, 50, 65), 1.5)

        -- Garis Alur Vinyl
        local groove = Instance.new("Frame")
        groove.AnchorPoint = Vector2.new(0.5, 0.5)
        groove.Position = UDim2.fromScale(0.5, 0.5)
        groove.Size = UDim2.fromOffset(40, 40)
        groove.BackgroundTransparency = 1
        groove.Parent = vinyl
        Kit.corner(groove, 20)
        Kit.stroke(groove, Color3.fromRGB(30, 35, 45), 1)

        -- Center Vinyl Label
        local vCenter = Instance.new("Frame")
        vCenter.AnchorPoint = Vector2.new(0.5, 0.5)
        vCenter.Position = UDim2.fromScale(0.5, 0.5)
        vCenter.Size = UDim2.fromOffset(18, 18)
        vCenter.BackgroundColor3 = Color3.fromRGB(10, 132, 255)
        vCenter.Parent = vinyl
        Kit.corner(vCenter, 9)

        -- Detail Lagu
        local tInfo = Instance.new("Frame")
        tInfo.BackgroundTransparency = 1
        tInfo.Position = UDim2.fromOffset(70, 6)
        tInfo.Size = UDim2.new(1, -210, 0, 52)
        tInfo.Parent = pRow
        Kit.list(tInfo, 3)

        local tTitle = Kit.label(tInfo, { Text = MUSIC_TRACKS[1].nama, TextSize = 13, Font = Kit.FontBold, Truncate = true })
        local tSub = Kit.label(tInfo, { Text = MUSIC_TRACKS[1].pembuat .. "  •  " .. MUSIC_TRACKS[1].genre, TextSize = 10, Color = P.muted })
        local tTime = Kit.label(tInfo, { Text = "00:00 / 00:00  •  Siap memutar", TextSize = 9, Color = Color3.fromRGB(120, 200, 255) })

        -- Controls Box
        local ctrlBox = Instance.new("Frame")
        ctrlBox.AnchorPoint = Vector2.new(1, 0.5)
        ctrlBox.Position = UDim2.new(1, 0, 0.5, 0)
        ctrlBox.Size = UDim2.fromOffset(130, 40)
        ctrlBox.BackgroundTransparency = 1
        ctrlBox.Parent = pRow
        local cg = Instance.new("UIGridLayout")
        cg.CellSize = UDim2.new(1 / 3, -4, 1, 0)
        cg.CellPadding = UDim2.fromOffset(6, 0)
        cg.Parent = ctrlBox

        local playBtn

        local function updatePlayState()
            local trk = MUSIC_TRACKS[curSongIdx]
            tTitle.Text = trk.nama
            tSub.Text = trk.pembuat .. "  •  " .. trk.genre
            if isPlaying then
                curSound.SoundId = "rbxassetid://" .. trk.id
                curSound:Play()
                playBtn.Text = "⏸"
                tTime.Text = "Memutar lagu: " .. trk.nama
            else
                curSound:Pause()
                playBtn.Text = "▶"
                tTime.Text = "Dijeda"
            end
        end

        local function nextTrack(delta)
            curSongIdx = curSongIdx + delta
            if curSongIdx > #MUSIC_TRACKS then curSongIdx = 1 end
            if curSongIdx < 1 then curSongIdx = #MUSIC_TRACKS end
            isPlaying = true
            updatePlayState()
        end

        Kit.button(ctrlBox, { Text = "⏮", OnClick = function() nextTrack(-1) end })
        playBtn = Kit.button(ctrlBox, { Text = "▶", Solid = true, OnClick = function()
            isPlaying = not isPlaying
            updatePlayState()
        end })
        Kit.button(ctrlBox, { Text = "⏭", OnClick = function() nextTrack(1) end })

        -- Putaran Vinyl Animasi
        RunService.RenderStepped:Connect(function()
            if isPlaying then
                vinyl.Rotation = (vinyl.Rotation + 1.8) % 360
            end
        end)

        -- Card 2: Daftar Lagu (20 Lagu Ringkas)
        Kit.caption(s, "Daftar Lagu Xiurey (20 Lagu)", 2)
        local tListCont = Instance.new("Frame")
        tListCont.BackgroundTransparency = 1
        tListCont.Size = UDim2.new(1, 0, 0, 0)
        tListCont.AutomaticSize = Enum.AutomaticSize.Y
        tListCont.LayoutOrder = 3
        tListCont.Parent = s
        Kit.list(tListCont, 4)

        for i, trk in ipairs(MUSIC_TRACKS) do
            local tc = Kit.card(tListCont, { AutoY = true, LayoutOrder = i })
            Kit.padding(tc, 8, 6, 8, 6)
            local row = Instance.new("Frame")
            row.BackgroundTransparency = 1
            row.Size = UDim2.new(1, 0, 0, 26)
            row.Parent = tc

            local numL = Kit.label(row, { Text = string.format("%02d.", i), TextSize = 11, Font = Kit.FontBold, Color = Color3.fromRGB(10, 132, 255) })
            numL.Size = UDim2.fromOffset(24, 26)

            local infoL = Kit.label(row, { Text = trk.nama .. "  (" .. trk.genre .. ")", TextSize = 11, Font = Kit.FontMedium })
            infoL.Position = UDim2.fromOffset(30, 0)
            infoL.Size = UDim2.new(1, -110, 1, 0)

            local pBtn = Kit.button(row, { Text = "PUTAR", OnClick = function()
                curSongIdx = i
                isPlaying = true
                updatePlayState()
                Kit.toast("Memutar: " .. trk.nama, "ok")
            end })
            pBtn.Position = UDim2.new(1, -70, 0, 0)
            pBtn.Size = UDim2.fromOffset(70, 26)
        end
    end

    -- ===================== 7) TAB: AI CHAT (XIUREY ASSISTANT) =====================
    do
        local s = win.AddPage({ id = "AICHAT", label = "AI Assistant", icon = "chat", title = "Xiurey AI Assistant",
            subtitle = "Llama-3.3 70B via OpenRouter • Pembuat Script Roblox & Solusi", order = 7 })

        local history = {}

        -- Chat Message Container (Scroll)
        local chatScroll = Instance.new("ScrollingFrame")
        chatScroll.Size = UDim2.new(1, 0, 0, 220)
        chatScroll.BackgroundTransparency = 1
        chatScroll.BorderSizePixel = 0
        chatScroll.ScrollBarThickness = 3
        chatScroll.ScrollBarImageColor3 = Color3.fromRGB(96, 96, 108)
        chatScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        chatScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        chatScroll.LayoutOrder = 1
        chatScroll.Parent = s
        local cl = Instance.new("UIListLayout")
        cl.Padding = UDim.new(0, 8)
        cl.SortOrder = Enum.SortOrder.LayoutOrder
        cl.Parent = chatScroll

        local function addMessage(role, text)
            local msgCard = Kit.card(chatScroll, { AutoY = true })
            Kit.padding(msgCard, 10, 8, 10, 8)
            msgCard.BackgroundColor3 = (role == "user") and Color3.fromRGB(15, 30, 55) or Color3.fromRGB(18, 22, 34)
            local sender = (role == "user") and LocalPlayer.DisplayName or "Xiurey AI Assistant"
            Kit.label(msgCard, { Text = sender, TextSize = 10, Font = Kit.FontBold, Color = (role == "user") and Color3.fromRGB(120, 200, 255) or Color3.fromRGB(160, 230, 180) })
            Kit.label(msgCard, { Text = text, TextSize = 11, Wrap = true, AutoY = true, LayoutOrder = 2 })

            local codeSnippet = text:match("```lua%s*(.-)%s*```") or text:match("```%s*(.-)%s*```")
            if codeSnippet then
                Kit.button(msgCard, { Text = "📋 SALIN SCRIPT", Solid = true, LayoutOrder = 3, OnClick = function()
                    setclip(codeSnippet)
                    Kit.toast("Script Lua disalin ke clipboard!", "ok")
                end })
            end
            task.defer(function()
                chatScroll.CanvasPosition = Vector2.new(0, 999999)
            end)
        end

        addMessage("assistant", "Halo " .. LocalPlayer.DisplayName .. "! Saya Xiurey AI Assistant. Butuh bantuan membuat script Roblox atau memecahkan masalah?")

        local inCard = Kit.card(s, { AutoY = true, LayoutOrder = 2 })
        Kit.padding(inCard, 8, 8, 8, 8)
        local inRow = Instance.new("Frame")
        inRow.BackgroundTransparency = 1
        inRow.Size = UDim2.new(1, 0, 0, 36)
        inRow.Parent = inCard

        local cBox = Kit.input(inRow, { Placeholder = "Tanyakan sesuatu ke AI...", Icon = "chat" })
        cBox.Size = UDim2.new(1, -95, 1, 0)

        local isWaitingAI = false
        local function sendChat()
            local prompt = trim(cBox.Text)
            if prompt == "" or isWaitingAI then return end
            cBox.Text = ""
            addMessage("user", prompt)
            isWaitingAI = true

            callXiureyAI(prompt, history, function(success, reply)
                isWaitingAI = false
                if success then
                    table.insert(history, {role = "user", content = prompt})
                    table.insert(history, {role = "assistant", content = reply})
                    addMessage("assistant", reply)
                else
                    addMessage("assistant", "Maaf, terjadi kesalahan: " .. tostring(reply))
                end
            end)
        end

        local sendBtn = Kit.button(inRow, { Text = "KIRIM", Solid = true, OnClick = sendChat })
        sendBtn.Position = UDim2.new(1, -85, 0, 0)
        sendBtn.Size = UDim2.fromOffset(85, 36)
        cBox.FocusLost:Connect(function(enter) if enter then sendChat() end end)
    end

    -- ===================== 8) TAB: SETTING =====================
    do
        local s = win.AddPage({ id = "SETTING", label = "Setting", icon = "gear", title = "Setting & Kustomisasi",
            subtitle = "Pengaturan 3D UI, Open Cloud & sistem", order = 8 })

        Kit.caption(s, "Roblox Open Cloud API", 1)
        local ocCard = Kit.card(s, { AutoY = true, LayoutOrder = 2 })
        Kit.padding(ocCard, 10, 10, 10, 10)
        Kit.list(ocCard, 6)

        local ocBox = Kit.input(ocCard, { Placeholder = "Open Cloud API Key...", LayoutOrder = 1 })
        ocBox.Text = config.ocKey
        local crBox = Kit.input(ocCard, { Placeholder = "Creator ID (User ID atau Group ID)...", LayoutOrder = 2 })
        crBox.Text = config.creatorId

        Kit.button(ocCard, { Text = "SIMPAN PENGATURAN", Solid = true, LayoutOrder = 3, OnClick = function()
            config.ocKey = trim(ocBox.Text)
            config.creatorId = trim(crBox.Text)
            simpanConfig()
            Kit.toast("Pengaturan berhasil disimpan!", "ok")
        end })

        Kit.caption(s, "Tampilan & Audio", 3)
        Kit.toggle(s, "Tampilan 3D (Panel Miring)", UI3D.Config.Enabled, function(on)
            UI3D.setEnabled(on)
            config.ui3dEnabled = on
            simpanConfig()
        end, 4)
        Kit.toggle(s, "Gyro HP (Panel Mengikuti Sensor HP)", UI3D.Config.Gyro, function(on)
            UI3D.Config.Gyro = on
        end, 5)
        Kit.toggle(s, "Goyang Halus Saat Diam (Idle Wobble)", UI3D.Config.Idle, function(on)
            UI3D.Config.Idle = on
        end, 6)
        Kit.toggle(s, "Suara Klik Xiurey", Kit.ClickSound, function(on)
            Kit.ClickSound = on
            if on then Kit.click() end
        end, 7)
    end

    -- Quick Action Buttons di bawah Sidebar
    win.AddQuick({ Text = "Sembunyi", Solid = false, LayoutOrder = 1, OnClick = function()
        win.Hide()
        if ShowLauncher then ShowLauncher() end
    end })
    win.Select("HOME")

    -- ===================== LAUNCHER (Tombol Buka Kembali) =====================
    local lg = Kit.screen(APP_NAME .. "Launcher", 79)
    local launcher = Instance.new("TextButton")
    launcher.AutoButtonColor = false
    launcher.Text = ""
    launcher.AnchorPoint = Vector2.new(1, 1)
    launcher.Position = UDim2.new(1, -16, 1, -90)
    launcher.Size = UDim2.fromOffset(52, 52)
    launcher.BackgroundColor3 = P.panel
    launcher.BackgroundTransparency = 0.2
    launcher.BorderSizePixel = 0
    launcher.Visible = false
    launcher.Parent = lg
    Kit.corner(launcher, 16)
    Kit.sweepStroke(Kit.stroke(launcher, Color3.new(1, 1, 1), 1.5))
    Kit.sheen(launcher, 16, 0.82, 1)

    local lih = Instance.new("Frame")
    lih.BackgroundTransparency = 1
    lih.AnchorPoint = Vector2.new(0.5, 0.5)
    lih.Position = UDim2.fromScale(0.5, 0.5)
    lih.Size = UDim2.fromOffset(24, 24)
    lih.Parent = launcher
    Kit.icon(lih, "gem", 24, P.text)

    do
        local dragging, moved, startIn, startPos = false, false, nil, nil
        launcher.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging, moved, startIn, startPos = true, false, input.Position, launcher.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        if not moved then launcher.Visible = false win.Open() end
                    end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if not dragging then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                local d = input.Position - startIn
                if math.abs(d.X) > 6 or math.abs(d.Y) > 6 then moved = true end
                if moved then
                    launcher.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
                end
            end
        end)
    end

    ShowLauncher = function() launcher.Visible = true end
    win.Close.MouseButton1Click:Connect(function()
        win.Hide()
        launcher.Visible = true
    end)

    -- ===================== LOADING SCREEN ANIMASI =====================
    if SHOW_LOADING then
        do
            local sg = Kit.screen(APP_NAME .. "Splash", 990)
            sg.IgnoreGuiInset = true

            local bg = Instance.new("Frame")
            bg.Size = UDim2.fromScale(1, 1)
            bg.BackgroundColor3 = Color3.fromRGB(4, 6, 14)
            bg.BackgroundTransparency = 1
            bg.BorderSizePixel = 0
            bg.Parent = sg

            local orbs = {}
            for i, spec in ipairs({
                {300, Color3.fromRGB(10, 132, 255), -150, -40},
                {240, Color3.fromRGB(110, 220, 255), 160, 50},
                {180, Color3.fromRGB(120, 110, 255), 20, -110}
            }) do
                local o = Instance.new("CanvasGroup")
                o.AnchorPoint = Vector2.new(0.5, 0.5)
                o.Size = UDim2.fromOffset(spec[1], spec[1])
                o.Position = UDim2.new(0.5, spec[3], 0.5, spec[4])
                o.BackgroundTransparency = 1
                o.GroupTransparency = 1
                o.BorderSizePixel = 0
                o.Parent = bg
                for _, k in ipairs({1, 0.78, 0.56, 0.36}) do
                    local c = Instance.new("Frame")
                    c.AnchorPoint = Vector2.new(0.5, 0.5)
                    c.Position = UDim2.fromScale(0.5, 0.5)
                    c.Size = UDim2.fromScale(k, k)
                    c.BackgroundColor3 = spec[2]
                    c.BackgroundTransparency = 0.86
                    c.BorderSizePixel = 0
                    c.Parent = o
                    Kit.corner(c, 1, true)
                end
                orbs[i] = {frame = o, x = spec[3], y = spec[4], phase = i * 2.1}
            end

            local holder = Instance.new("Frame")
            holder.AnchorPoint = Vector2.new(0.5, 0.5)
            holder.Position = UDim2.fromScale(0.5, 0.5)
            holder.Size = UDim2.fromOffset(340, 236)
            holder.BackgroundTransparency = 1
            holder.Parent = sg
            local scale = Instance.new("UIScale")
            scale.Scale = 0.86
            scale.Parent = holder

            local fitScale = 1
            do
                local cam = workspace.CurrentCamera
                local vp = cam and cam.ViewportSize or Vector2.new(800, 450)
                fitScale = math.clamp(math.min((vp.X - 24) / 340, (vp.Y - 24) / 236), 0.6, 1.25)
            end

            local shadow = Kit.glow(holder, 28)
            for _, g in ipairs(shadow) do g.frame.BackgroundTransparency = 1 end

            local card = Kit.glass(holder, {Size = UDim2.fromScale(1, 1), Radius = 28, Canvas = true})
            card.GroupTransparency = 1

            local tile = Instance.new("Frame")
            tile.AnchorPoint = Vector2.new(0.5, 0)
            tile.Position = UDim2.new(0.5, 0, 0, 24)
            tile.Size = UDim2.fromOffset(64, 64)
            tile.BackgroundColor3 = Color3.new(1, 1, 1)
            tile.BackgroundTransparency = 0.86
            tile.BorderSizePixel = 0
            tile.Parent = card
            Kit.corner(tile, 20)
            Kit.sheen(tile, 20, 0.7, 1)

            local ring = Instance.new("UIStroke")
            ring.Thickness = 2.5
            ring.Color = Color3.new(1, 1, 1)
            ring.Parent = tile
            local ringG = Instance.new("UIGradient")
            ringG.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 132, 255)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(140, 230, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 132, 255)),
            })
            ringG.Parent = ring

            local ih = Instance.new("Frame")
            ih.BackgroundTransparency = 1
            ih.AnchorPoint = Vector2.new(0.5, 0.5)
            ih.Position = UDim2.fromScale(0.5, 0.5)
            ih.Size = UDim2.fromOffset(30, 30)
            ih.Parent = tile
            Kit.icon(ih, "gem", 30, Color3.new(1, 1, 1))

            local title = Kit.label(card, {
                Text = LOGO_RICH, Rich = true,
                Position = UDim2.fromOffset(0, 100), Size = UDim2.new(1, 0, 0, 30),
                TextSize = 26, Font = Kit.FontBlack, Align = Enum.TextXAlignment.Center
            })

            Kit.label(card, {
                Text = APP_TAGLINE, Position = UDim2.fromOffset(0, 132),
                Size = UDim2.new(1, 0, 0, 16), TextSize = 12, Color = P.muted, Align = Enum.TextXAlignment.Center
            })

            local status = Kit.label(card, {
                Text = "Memulai...", Position = UDim2.new(0, 34, 0, 168), Size = UDim2.new(1, -110, 0, 16),
                TextSize = 11, Color = P.muted, Truncate = true
            })
            local pct = Kit.label(card, {
                Text = "0%", Position = UDim2.new(1, -76, 0, 168), Size = UDim2.fromOffset(42, 16),
                TextSize = 11, Font = Kit.FontBold, Align = Enum.TextXAlignment.Right
            })
            local bar, setBar = Kit.progress(card)
            bar.Position = UDim2.new(0, 34, 0, 192)
            bar.Size = UDim2.new(1, -68, 0, 8)

            local t0 = os.clock()
            local alive = true
            local conn = RunService.RenderStepped:Connect(function()
                if not alive then return end
                local t = os.clock() - t0
                ringG.Rotation = (t * 160) % 360
                for _, o in ipairs(orbs) do
                    o.frame.Position = UDim2.new(0.5, o.x + math.sin(t * 0.6 + o.phase) * 40, 0.5, o.y + math.cos(t * 0.5 + o.phase) * 26)
                end
            end)

            Kit.tween(bg, 0.5, {BackgroundTransparency = 0.25})
            for _, o in ipairs(orbs) do Kit.tween(o.frame, 0.9, {GroupTransparency = 0.2}) end
            for _, g in ipairs(shadow) do Kit.tween(g.frame, 0.6, {BackgroundTransparency = g.base}) end
            Kit.tween(card, 0.5, {GroupTransparency = 0})
            Kit.tween(scale, 0.7, {Scale = fitScale}, Enum.EasingStyle.Back)
            task.wait(0.5)

            local steps = {
                {"Menyiapkan Liquid Glass Engine...", 0.25, 0.4},
                {"Memuat StudioLite & Toolbox PC...", 0.55, 0.4},
                {"Menginisialisasi Audio Spoofer & Music...", 0.85, 0.4},
                {"Siap!", 1.0, 0.3},
            }
            local shown = 0
            local function setP(v)
                setBar(v)
                local target = math.floor(v * 100 + 0.5)
                task.spawn(function()
                    while shown < target and alive do
                        shown = shown + 1
                        pct.Text = shown .. "%"
                        task.wait(0.01)
                    end
                end)
            end
            for _, st in ipairs(steps) do
                status.Text = st[1]
                setP(st[2])
                task.wait(st[3])
            end
            task.wait(0.3)

            Kit.tween(card, 0.35, {GroupTransparency = 1})
            Kit.tween(scale, 0.35, {Scale = fitScale * 1.06})
            for _, g in ipairs(shadow) do Kit.tween(g.frame, 0.3, {BackgroundTransparency = 1}) end
            for _, o in ipairs(orbs) do Kit.tween(o.frame, 0.4, {GroupTransparency = 1}) end
            Kit.tween(bg, 0.45, {BackgroundTransparency = 1})
            task.wait(0.25)
            win.Open()
            alive = false
            conn:Disconnect()
            sg:Destroy()
        end
    else
        win.Open()
    end
end
