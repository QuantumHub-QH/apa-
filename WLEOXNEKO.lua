--[[
    IMPORTER HUB (Delta, ramah mobile)

    Fitur:
    - Import RBXM / RBXL / RBXLX / RBXMX dari folder Workspace Delta
    - Toolbox: cari & import Model, Decal, Mesh dari Creator Store
    - Music Player: putar audio publik breakbeat, EDM, dan sad
    - AI Chat: ngobrol dengan AI lewat OpenRouter (butuh API key)
    - Upload Gambar / Animasi / RBXM lewat Roblox Open Cloud (butuh API key)
    - Dashboard: jumlah file, CPU/FPS, dan grafik performa
    - Pengaturan: tema warna, API key & Creator ID

    Soal script di dalam file:
    Isi file tidak pernah dihapus, difilter, atau diubah. Semua Script,
    LocalScript, dan ModuleScript ikut masuk apa adanya. Setelah dipasang,
    jumlah script dibandingkan dengan sebelumnya dan ditampilkan di status bar.
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local StatsService = game:GetService("Stats")
local lp = Players.LocalPlayer

local getAsset = getcustomasset or getsynasset
if not (getAsset and listfiles) then
    warn("Executor kamu belum support listfiles/getcustomasset")
    return
end
local adaFolder = isfolder or function() return false end
local httpReq = request or http_request or (syn and syn.request) or (http and http.request)

------------------------------------------------------------------
-- KONFIGURASI (disimpan lokal kalau tekan SIMPAN di Pengaturan)
------------------------------------------------------------------
local FILE_CONFIG = "importer_config.json"
local config = {
    ocKey = "",
    creatorId = "",
    creatorTipe = "User",
    orKey = "",
    orModel = "openai/gpt-4o-mini",
    tema = "Abu",
}

local function muatConfig()
    if isfile and readfile and isfile(FILE_CONFIG) then
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(FILE_CONFIG))
        end)
        if ok and type(data) == "table" then
            for k, v in pairs(data) do
                if config[k] ~= nil and type(v) == "string" then config[k] = v end
            end
        end
    end
end

local function simpanConfig()
    if not writefile then return false end
    return (pcall(function()
        writefile(FILE_CONFIG, HttpService:JSONEncode(config))
    end))
end

muatConfig()

------------------------------------------------------------------
-- DATA
------------------------------------------------------------------
local JENIS = {
    {kunci = "rbxm",  judul = "Import RBXM",  ket = "Model binary (.rbxm)", ikon = "M"},
    {kunci = "rbxl",  judul = "Import RBXL",  ket = "Place binary (.rbxl)", ikon = "L"},
    {kunci = "rbxlx", judul = "Import RBXLX", ket = "Place XML (.rbxlx)",   ikon = "LX"},
    {kunci = "rbxmx", judul = "Import RBXMX", ket = "Model XML (.rbxmx)",   ikon = "MX"},
}
local JENIS_KUNCI = {}
for _, j in ipairs(JENIS) do JENIS_KUNCI[j.kunci] = j end

local UPLOAD = {
    up_model = {judul = "Upload RBXM", ket = "model .rbxm jadi Model",
        ext = {"rbxm"}, tipe = "Model"},
}

local CONTENT_TYPE = {
    png = "image/png", jpg = "image/jpeg", jpeg = "image/jpeg",
    bmp = "image/bmp", tga = "image/tga",
    rbxm = "model/x-rbxm", rbxmx = "model/x-rbxm",
}

local EXT_DICARI = {"rbxm", "rbxl", "rbxlx", "rbxmx", "png", "jpg", "jpeg", "bmp", "tga"}

local TUJUAN = {
    {nama = "Workspace", obj = workspace},
    {nama = "ReplicatedStorage", obj = game:GetService("ReplicatedStorage")},
}
local idxTujuan = 1

-- Untuk file place: isi service dipindah ke service yang sama di game
local SKIP_SERVICE = {Players = true, CoreGui = true, CorePackages = true}
local SKIP_ANAK = {Terrain = true, Camera = true}

local fileTersedia = {}
for _, e in ipairs(EXT_DICARI) do fileTersedia[e] = {} end

------------------------------------------------------------------
-- SCAN FILE
------------------------------------------------------------------
local function scanFolder(path, kedalaman)
    local ok, isi = pcall(listfiles, path)
    if not ok or type(isi) ~= "table" then return end
    for _, p in ipairs(isi) do
        local nama = p:match("[^/\\]+$") or p
        local okF, folder = pcall(adaFolder, p)
        if okF and folder then
            if kedalaman < 2 then scanFolder(p, kedalaman + 1) end
        else
            local ext = nama:lower():match("%.(%w+)$")
            if ext and fileTersedia[ext] then
                table.insert(fileTersedia[ext], {nama = nama, path = p, ext = ext})
            end
        end
    end
end

local function scanSemua()
    for _, e in ipairs(EXT_DICARI) do fileTersedia[e] = {} end
    scanFolder("", 0)
    local total = 0
    for _, e in ipairs(EXT_DICARI) do total = total + #fileTersedia[e] end
    if total == 0 then scanFolder(".", 0) end
    for _, e in ipairs(EXT_DICARI) do
        table.sort(fileTersedia[e], function(a, b)
            return a.nama:lower() < b.nama:lower()
        end)
    end
end

------------------------------------------------------------------
-- HELPER UMUM
------------------------------------------------------------------
local function muatObjek(f)
    local kandidat = {f.path, (f.path:gsub("^%./", "")), f.nama}
    local errTerakhir = "tidak diketahui"
    for _, p in ipairs(kandidat) do
        local ok, res = pcall(function()
            return game:GetObjects(getAsset(p))
        end)
        if ok and type(res) == "table" and #res > 0 then
            return res
        end
        errTerakhir = ok and "file kosong" or tostring(res)
    end
    return nil, errTerakhir
end

local function layananDari(obj)
    local ok, svc = pcall(game.GetService, game, obj.ClassName)
    if ok and svc and svc ~= obj then return svc end
    return nil
end

-- Hitung semua script (Script, LocalScript, ModuleScript) di satu objek
local function hitung(inst, t)
    local function cek(i)
        if i:IsA("LuaSourceContainer") then
            t[i.ClassName] = (t[i.ClassName] or 0) + 1
            t._total = (t._total or 0) + 1
        end
    end
    cek(inst)
    for _, d in ipairs(inst:GetDescendants()) do cek(d) end
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
        for _, child in ipairs(obj:GetChildren()) do
            collectSpatialRoots(child)
        end
    end

    for _, obj in ipairs(objects) do
        collectSpatialRoots(obj)
    end
    if #movable == 0 then return true end

    local camera = workspace.CurrentCamera
    if not camera then
        return false, "Kamera tidak tersedia"
    end

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
        minBound = minBound and Vector3.new(
            math.min(minBound.X, partMin.X),
            math.min(minBound.Y, partMin.Y),
            math.min(minBound.Z, partMin.Z)
        ) or partMin
        maxBound = maxBound and Vector3.new(
            math.max(maxBound.X, partMax.X),
            math.max(maxBound.Y, partMax.Y),
            math.max(maxBound.Z, partMax.Z)
        ) or partMax
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
                minBound = minBound and Vector3.new(
                    math.min(minBound.X, position.X),
                    math.min(minBound.Y, position.Y),
                    math.min(minBound.Z, position.Z)
                ) or position
                maxBound = maxBound and Vector3.new(
                    math.max(maxBound.X, position.X),
                    math.max(maxBound.Y, position.Y),
                    math.max(maxBound.Z, position.Z)
                ) or position
            end
        end
    end
    if not minBound then return false, "Posisi objek tidak dapat dibaca" end

    local center = (minBound + maxBound) * 0.5
    local halfSize = (maxBound - minBound) * 0.5
    local direction = camera.CFrame.LookVector
    local radius = math.abs(direction.X) * halfSize.X
        + math.abs(direction.Y) * halfSize.Y
        + math.abs(direction.Z) * halfSize.Z
    local distance = math.max(JARAK_MIN_SPAWN_KAMERA, radius + JARAK_AMAN_SPAWN_KAMERA)
    local targetCenter = camera.CFrame.Position + direction * distance
    local offset = CFrame.new(targetCenter - center)
    local moved = 0
    for _, obj in ipairs(movable) do
        local okMove = pcall(function()
            obj:PivotTo(offset * obj:GetPivot())
        end)
        if okMove then moved += 1 end
    end
    if moved ~= #movable then
        return false, "Sebagian objek tidak dapat dipindahkan"
    end
    return true
end

local function taruhDiDepan(obj)
    return taruhGrupDiDepan({obj})
end

local function decodeJson(res)
    if res and type(res.Body) == "string" then
        local ok, d = pcall(function() return HttpService:JSONDecode(res.Body) end)
        if ok and type(d) == "table" then return d end
    end
    return nil
end

local function trim(s)
    return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

------------------------------------------------------------------
-- GUI DASAR
------------------------------------------------------------------
local C = {}

local TEMA = {
    Abu = {
        bg = Color3.fromRGB(26, 28, 32), panel = Color3.fromRGB(34, 37, 43),
        kartu = Color3.fromRGB(44, 48, 56), aktif = Color3.fromRGB(72, 81, 96),
        teks = Color3.fromRGB(242, 244, 247), redup = Color3.fromRGB(157, 166, 179),
        aksen = Color3.fromRGB(172, 190, 207), hijau = Color3.fromRGB(58, 181, 121),
        merah = Color3.fromRGB(197, 64, 76),
    },
    Pink = {
        bg = Color3.fromRGB(33, 19, 29), panel = Color3.fromRGB(46, 26, 40),
        kartu = Color3.fromRGB(61, 34, 52), aktif = Color3.fromRGB(104, 39, 72),
        teks = Color3.fromRGB(255, 242, 249), redup = Color3.fromRGB(202, 163, 183),
        aksen = Color3.fromRGB(231, 103, 158), hijau = Color3.fromRGB(58, 181, 121),
        merah = Color3.fromRGB(197, 64, 76),
    },
    Putih = {
        bg = Color3.fromRGB(238, 242, 247), panel = Color3.fromRGB(250, 252, 255),
        kartu = Color3.fromRGB(226, 232, 240), aktif = Color3.fromRGB(191, 210, 231),
        teks = Color3.fromRGB(28, 36, 48), redup = Color3.fromRGB(91, 103, 120),
        aksen = Color3.fromRGB(35, 126, 112), hijau = Color3.fromRGB(22, 112, 81),
        merah = Color3.fromRGB(197, 64, 76),
    },
    Merah = {
        bg = Color3.fromRGB(29, 17, 20), panel = Color3.fromRGB(43, 24, 28),
        kartu = Color3.fromRGB(58, 31, 36), aktif = Color3.fromRGB(112, 39, 49),
        teks = Color3.fromRGB(255, 243, 244), redup = Color3.fromRGB(194, 151, 156),
        aksen = Color3.fromRGB(235, 79, 97), hijau = Color3.fromRGB(58, 181, 121),
        merah = Color3.fromRGB(197, 64, 76),
    },
    Biru = {
        bg = Color3.fromRGB(17, 25, 39), panel = Color3.fromRGB(24, 36, 54),
        kartu = Color3.fromRGB(33, 48, 70), aktif = Color3.fromRGB(42, 87, 139),
        teks = Color3.fromRGB(237, 245, 255), redup = Color3.fromRGB(151, 174, 204),
        aksen = Color3.fromRGB(83, 157, 222), hijau = Color3.fromRGB(58, 181, 121),
        merah = Color3.fromRGB(197, 64, 76),
    },
    Ungu = {
        bg = Color3.fromRGB(22, 18, 34), panel = Color3.fromRGB(32, 26, 47),
        kartu = Color3.fromRGB(43, 34, 62), aktif = Color3.fromRGB(78, 47, 114),
        teks = Color3.fromRGB(246, 241, 255), redup = Color3.fromRGB(178, 164, 203),
        aksen = Color3.fromRGB(173, 125, 255), hijau = Color3.fromRGB(58, 181, 121),
        merah = Color3.fromRGB(197, 64, 76),
    },
    Toska = {
        bg = Color3.fromRGB(15, 30, 34), panel = Color3.fromRGB(23, 42, 47),
        kartu = Color3.fromRGB(31, 55, 61), aktif = Color3.fromRGB(35, 91, 94),
        teks = Color3.fromRGB(236, 252, 251), redup = Color3.fromRGB(145, 188, 189),
        aksen = Color3.fromRGB(66, 203, 186), hijau = Color3.fromRGB(58, 181, 121),
        merah = Color3.fromRGB(197, 64, 76),
    },
    Hijau = {
        bg = Color3.fromRGB(17, 29, 22), panel = Color3.fromRGB(25, 41, 31),
        kartu = Color3.fromRGB(34, 54, 41), aktif = Color3.fromRGB(38, 83, 57),
        teks = Color3.fromRGB(239, 251, 242), redup = Color3.fromRGB(157, 190, 166),
        aksen = Color3.fromRGB(91, 203, 132), hijau = Color3.fromRGB(58, 181, 121),
        merah = Color3.fromRGB(197, 64, 76),
    },
    Emas = {
        bg = Color3.fromRGB(34, 27, 18), panel = Color3.fromRGB(46, 37, 24),
        kartu = Color3.fromRGB(62, 49, 30), aktif = Color3.fromRGB(111, 79, 35),
        teks = Color3.fromRGB(255, 247, 230), redup = Color3.fromRGB(197, 177, 139),
        aksen = Color3.fromRGB(235, 181, 83), hijau = Color3.fromRGB(58, 181, 121),
        merah = Color3.fromRGB(197, 64, 76),
    },
    Midnight = {
        bg = Color3.fromRGB(14, 19, 34), panel = Color3.fromRGB(21, 29, 49),
        kartu = Color3.fromRGB(30, 40, 65), aktif = Color3.fromRGB(43, 61, 104),
        teks = Color3.fromRGB(240, 244, 255), redup = Color3.fromRGB(150, 165, 201),
        aksen = Color3.fromRGB(126, 160, 255), hijau = Color3.fromRGB(58, 181, 121),
        merah = Color3.fromRGB(197, 64, 76),
    },
}

local temaAktif = TEMA[config.tema] and config.tema or "Abu"
config.tema = temaAktif
for k, v in pairs(TEMA[temaAktif]) do C[k] = v end

local FONT_MONTSERRAT = {
    regular = Font.fromName("Montserrat", Enum.FontWeight.Regular),
    medium = Font.fromName("Montserrat", Enum.FontWeight.Medium),
    bold = Font.fromName("Montserrat", Enum.FontWeight.Bold),
}

local function buat(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    if class == "TextLabel" or class == "TextButton" or class == "TextBox" then
        local face = FONT_MONTSERRAT.regular
        if props.Font == Enum.Font.GothamBold or props.Font == Enum.Font.GothamBlack then
            face = FONT_MONTSERRAT.bold
        elseif props.Font == Enum.Font.GothamMedium then
            face = FONT_MONTSERRAT.medium
        end
        o.FontFace = face
    elseif class == "ScrollingFrame" and props.ScrollBarImageColor3 == nil then
        o.ScrollBarImageColor3 = C.redup
    end
    o.Parent = parent
    return o
end

local function sudut(o, r)
    buat("UICorner", {CornerRadius = UDim.new(0, r or 8)}, o)
    return o
end

local function label(props, parent)
    props.BackgroundTransparency = 1
    props.Font = props.Font or Enum.Font.Gotham
    props.TextColor3 = props.TextColor3 or C.teks
    props.TextSize = props.TextSize or 12
    props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    return buat("TextLabel", props, parent)
end

local function tombol(props, parent)
    props.BorderSizePixel = 0
    props.Font = props.Font or Enum.Font.GothamBold
    props.TextColor3 = props.TextColor3 or C.teks
    props.TextSize = props.TextSize or 12
    return sudut(buat("TextButton", props, parent), 8)
end

local function kotakTeks(props, parent)
    props.BackgroundColor3 = C.panel
    props.BorderSizePixel = 0
    props.TextColor3 = C.teks
    props.PlaceholderColor3 = C.redup
    props.Font = Enum.Font.Gotham
    props.TextSize = 12
    props.TextXAlignment = Enum.TextXAlignment.Left
    props.ClearTextOnFocus = false
    local tb = sudut(buat("TextBox", props, parent), 8)
    buat("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, tb)
    return tb
end

local function pilihParent()
    if gethui then
        local ok, h = pcall(gethui)
        if ok and h then return h end
    end
    local ok = pcall(function() return game:GetService("CoreGui"):GetChildren() end)
    if ok then return game:GetService("CoreGui") end
    return lp:WaitForChild("PlayerGui")
end

local parentGui = pilihParent()
local lama = parentGui:FindFirstChild("ImporterHub")
if lama then lama:Destroy() end

------------------------------------------------------------------
-- SISTEM KEAMANAN & WHITELIST AKSES MELLS
------------------------------------------------------------------
local function fetchTextOnline(url)
    if httpReq then
        local ok, res = pcall(httpReq, {
            Url = url,
            Method = "GET"
        })
        if ok and res and (res.StatusCode == 200 or res.Status == 200) and type(res.Body) == "string" then
            return res.Body
        end
    end
    local okHttp, body = pcall(function()
        return game:HttpGet(url)
    end)
    if okHttp and type(body) == "string" and #body > 5 then
        return body
    end
    return nil
end

local function cekWhitelistRoblox()
    local myId = tostring(lp.UserId)
    local urls = {
        "https://raw.githubusercontent.com/amelxly-blip/spoofers/main/whitelist.json",
        "https://raw.githubusercontent.com/QuantumHub-QH/apa-/main/whitelist.json"
    }
    for _, u in ipairs(urls) do
        local body = fetchTextOnline(u .. "?cb=" .. tostring(os.time()))
        if body and #body > 5 then
            local okJ, d = pcall(function() return HttpService:JSONDecode(body) end)
            if okJ and type(d) == "table" and d.users then
                local userEntry = d.users[myId]
                if userEntry then
                    local exp = tonumber(userEntry["until"]) or 0
                    if exp > os.time() then
                        return true, userEntry
                    end
                end
            end
        end
    end
    return false, nil
end

local aksesDiizinkan, infoAkses = cekWhitelistRoblox()
if not aksesDiizinkan then
    local lamaLockout = parentGui:FindFirstChild("MellsLockout")
    if lamaLockout then lamaLockout:Destroy() end
    local lamaToggle = parentGui:FindFirstChild("ImporterHubToggle")
    if lamaToggle then lamaToggle:Destroy() end

    local lockoutGui = buat("ScreenGui", {
        Name = "MellsLockout",
        ResetOnSpawn = false,
        DisplayOrder = 9999999,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, parentGui)

    -- Background Fullscreen Image
    local bgImg = buat("ImageLabel", {
        Name = "Background",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Image = "rbxassetid://92844638469747",
        ScaleType = Enum.ScaleType.Crop,
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Active = true,
    }, lockoutGui)

    -- Overlay Gelap
    local overlay = buat("Frame", {
        Name = "DarkOverlay",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        Active = true,
    }, bgImg)

    -- Modal Box Tengah
    local modal = sudut(buat("Frame", {
        Name = "Card",
        Size = UDim2.new(0.9, 0, 0, 310),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(15, 15, 20),
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Active = true,
    }, overlay), 14)
    buat("UIStroke", {
        Color = Color3.fromRGB(230, 50, 50),
        Thickness = 2,
    }, modal)
    buat("UISizeConstraint", {
        MaxSize = Vector2.new(500, 340),
        MinSize = Vector2.new(300, 280),
    }, modal)

    local isiModal = buat("Frame", {
        Size = UDim2.new(1, -28, 1, -28),
        Position = UDim2.new(0, 14, 0, 14),
        BackgroundTransparency = 1,
    }, modal)
    buat("UIListLayout", {
        Padding = UDim.new(0, 10),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, isiModal)

    buat("TextLabel", {
        Text = "🔒",
        TextSize = 28,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 32),
        LayoutOrder = 1,
    }, isiModal)

    buat("TextLabel", {
        Text = "DARIPADA CRACK MENDING BUY\nLEBIH MURAH KE MELLS CANTIK AJA",
        Font = Enum.Font.GothamBlack,
        TextSize = 16,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextWrapped = true,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 42),
        LayoutOrder = 2,
    }, isiModal)

    buat("TextLabel", {
        Text = "JOIN DC KESINI:\nhttps://discord.gg/HkEhxrjVMk",
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Color3.fromRGB(88, 101, 242),
        TextWrapped = true,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 34),
        LayoutOrder = 3,
    }, isiModal)

    buat("TextLabel", {
        Text = "ID Roblox Kamu: " .. tostring(lp.UserId) .. " (Tidak Terdaftar / Habis)",
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextColor3 = Color3.fromRGB(180, 180, 180),
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        LayoutOrder = 4,
    }, isiModal)

    local btnSalinDc = sudut(buat("TextButton", {
        Text = "📋 Salin Link Discord",
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundColor3 = Color3.fromRGB(88, 101, 242),
        Size = UDim2.new(1, -20, 0, 34),
        BorderSizePixel = 0,
        LayoutOrder = 5,
    }, isiModal), 8)
    btnSalinDc.Activated:Connect(function()
        if setclipboard then
            setclipboard("https://discord.gg/HkEhxrjVMk")
            btnSalinDc.Text = "✔ Link Discord Berhasil Disalin!"
            task.delay(2, function()
                btnSalinDc.Text = "📋 Salin Link Discord"
            end)
        end
    end)

    local btnOwner = sudut(buat("TextButton", {
        Text = "💬 Hubungi Owner (1309112913331748915)",
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundColor3 = Color3.fromRGB(45, 45, 55),
        Size = UDim2.new(1, -20, 0, 32),
        BorderSizePixel = 0,
        LayoutOrder = 6,
    }, isiModal), 8)
    btnOwner.Activated:Connect(function()
        if setclipboard then
            setclipboard("1309112913331748915")
            btnOwner.Text = "✔ ID Discord Owner Disalin!"
            task.delay(2, function()
                btnOwner.Text = "💬 Hubungi Owner (1309112913331748915)"
            end)
        end
        local openUrlFn = openurl or (syn and syn.openurl)
        if openUrlFn then
            pcall(openUrlFn, "https://discord.com/users/1309112913331748915")
        end
    end)

    return
end

local gui = buat("ScreenGui", {
    Name = "ImporterHub",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, parentGui)

local LEBAR, TINGGI = 560, 360
local frame = sudut(buat("Frame", {
    Size = UDim2.new(0, LEBAR, 0, TINGGI),
    Position = UDim2.new(0.5, -LEBAR / 2, 0.5, -TINGGI / 2),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
    Active = true,
}, gui), 12)

-- Header
local TOGGLE_IMAGE = "rbxassetid://116910178994061"
local header = buat("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1}, frame)
buat("ImageLabel", {
    Name = "HeaderLogo",
    BackgroundTransparency = 1,
    Image = TOGGLE_IMAGE,
    Position = UDim2.new(0, 10, 0, 7),
    Size = UDim2.new(0, 26, 0, 26),
    ScaleType = Enum.ScaleType.Fit,
}, header)
label({Text = "TOOLS ENGINE MCP STUDIOLITE", Font = Enum.Font.GothamBold, TextSize = 15,
    Position = UDim2.new(0, 44, 0, 3), Size = UDim2.new(0, 390, 0, 20)}, header)
label({Text = "IMPORT · TOOLBOX · AI · UPLOAD", TextColor3 = C.redup, TextSize = 10,
    Position = UDim2.new(0, 44, 0, 23), Size = UDim2.new(0, 300, 0, 14)}, header)
local btnMin = tombol({Text = "-", Size = UDim2.new(0, 30, 0, 28),
    Position = UDim2.new(1, -72, 0, 6), BackgroundColor3 = C.kartu}, header)
local btnTutup = tombol({Text = "X", Size = UDim2.new(0, 30, 0, 28),
    Position = UDim2.new(1, -38, 0, 6), BackgroundColor3 = Color3.fromRGB(190, 60, 60)}, header)

local body = buat("Frame", {
    Size = UDim2.new(1, 0, 1, -40),
    Position = UDim2.new(0, 0, 0, 40),
    BackgroundTransparency = 1,
}, frame)

-- Status bar
local statusBar = sudut(buat("Frame", {
    Size = UDim2.new(1, -16, 0, 28),
    Position = UDim2.new(0, 8, 1, -36),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
}, body), 8)
local dot = sudut(buat("Frame", {
    Size = UDim2.new(0, 10, 0, 10),
    Position = UDim2.new(0, 10, 0.5, -5),
    BackgroundColor3 = C.hijau,
    BorderSizePixel = 0,
}, statusBar), 5)
local statusLabel = label({
    Text = "Siap",
    TextSize = 11,
    Position = UDim2.new(0, 28, 0, 0),
    Size = UDim2.new(1, -36, 1, 0),
    TextTruncate = Enum.TextTruncate.AtEnd,
}, statusBar)

local function setStatus(teks, merah)
    statusLabel.Text = teks
    dot.BackgroundColor3 = merah and C.merah or C.hijau
end

-- Sidebar & area isi
local sidebar = sudut(buat("Frame", {
    Size = UDim2.new(0, 140, 1, -44),
    Position = UDim2.new(0, 8, 0, 0),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
}, body), 10)
label({Text = lp.DisplayName, Font = Enum.Font.GothamBold, TextSize = 13,
    Position = UDim2.new(0, 12, 0, 6), Size = UDim2.new(1, -24, 0, 18),
    TextTruncate = Enum.TextTruncate.AtEnd}, sidebar)
label({Text = "@" .. lp.Name, TextColor3 = C.redup, TextSize = 10,
    Position = UDim2.new(0, 12, 0, 24), Size = UDim2.new(1, -24, 0, 14),
    TextTruncate = Enum.TextTruncate.AtEnd}, sidebar)

local isi = buat("Frame", {
    Size = UDim2.new(1, -164, 1, -44),
    Position = UDim2.new(0, 156, 0, 0),
    BackgroundTransparency = 1,
}, body)

local pageSweep = buat("Frame", {
    Name = "PageSweep",
    Size = UDim2.new(0, 108, 1, 0),
    Position = UDim2.new(0, -120, 0, 0),
    BackgroundColor3 = Color3.new(1, 1, 1),
    BackgroundTransparency = 0.65,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 100,
}, isi)
buat("UIGradient", {
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0.25),
        NumberSequenceKeypoint.new(1, 1),
    }),
}, pageSweep)
local pageSweepTween
local function jalankanSapuan()
    if pageSweepTween then pageSweepTween:Cancel() end
    pageSweep.Visible = true
    pageSweep.Position = UDim2.new(0, -120, 0, 0)
    local tween = TweenService:Create(
        pageSweep,
        TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, 12, 0, 0)}
    )
    pageSweepTween = tween
    tween.Completed:Connect(function()
        if pageSweepTween == tween then
            pageSweepTween = nil
            pageSweep.Visible = false
        end
    end)
    tween:Play()
end

local halaman = {}
local halamanAktif
local badgeMenu, badgeKartu, menuBtn = {}, {}, {}
local tombolTujuan = {}
local bukaHalaman, lakukanScan
local bukaToolboxPanel, tutupToolboxPanel
local bukaMusicPanel, tutupMusicPanel
local sorotMenu

local function perbaruiTujuan()
    for _, b in ipairs(tombolTujuan) do
        b.Text = "Tujuan: " .. TUJUAN[idxTujuan].nama
    end
end

local function gantiTujuan()
    idxTujuan = idxTujuan % #TUJUAN + 1
    perbaruiTujuan()
end

------------------------------------------------------------------
-- INTI: PASANG HASIL IMPORT (script tidak pernah dibuang)
------------------------------------------------------------------
local function pasangHasil(hasil, namaSumber)
    local tujuan = TUJUAN[idxTujuan]
    local sebelum, sesudah = {}, {}
    local ditaruh, objekWorkspace, gagal = {}, {}, 0

    local function taruh(inst, induk)
        hitung(inst, sebelum)
        local ok = pcall(function() inst.Parent = induk end)
        if ok then
            table.insert(ditaruh, inst)
            if induk == workspace then
                table.insert(objekWorkspace, inst)
            end
        else
            gagal = gagal + 1
        end
    end

    for _, obj in ipairs(hasil) do
        local svc = layananDari(obj)
        if svc then
            -- isi service (Workspace, ServerScriptService, dst) ke service yang sama
            if not SKIP_SERVICE[obj.ClassName] then
                for _, anak in ipairs(obj:GetChildren()) do
                    if not SKIP_ANAK[anak.ClassName] then
                        taruh(anak, svc)
                    end
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

    -- Cek ulang jumlah script setelah dipasang
    task.wait(0.2)
    for _, inst in ipairs(ditaruh) do
        if inst.Parent then hitung(inst, sesudah) end
    end

    local sb, sa = sebelum._total or 0, sesudah._total or 0
    local rinci = string.format("%d Script, %d LocalScript, %d ModuleScript",
        sesudah.Script or 0, sesudah.LocalScript or 0, sesudah.ModuleScript or 0)

    if gagal > 0 or sa < sb then
        local pesanError = string.format(
            "Peringatan: script %d dari %d, %d objek gagal dipasang",
            sa, sb, gagal
        )
        if spawnError then
            pesanError ..= " | spawn depan kamera gagal: " .. tostring(spawnError)
        end
        setStatus(pesanError, true)
        warn(string.format("[Importer] %s: %s", namaSumber, pesanError))
        return false
    end

    local pesanSukses = string.format(
        "Berhasil %d objek | Script utuh: %d (%s)",
        #ditaruh, sa, rinci
    )
    if spawnError then
        pesanSukses ..= " | spawn depan kamera gagal: " .. tostring(spawnError)
        setStatus(pesanSukses, true)
    else
        setStatus(pesanSukses)
    end
    print(string.format("[Importer] %s: %d objek, script utuh %d (%s)", namaSumber, #ditaruh, sa, rinci))
    return true, spawnError
end

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
        pos += 1
        return b
    end
    local function extLen(base)
        local len = base
        if base == 15 then
            while true do
                local b = readByte()
                len += b
                if b ~= 255 then break end
            end
        end
        return len
    end
    while outLen < decompressedLen do
        local token = readByte()
        local literalLen = extLen(bit32.rshift(token, 4))
        for _ = 1, literalLen do
            outLen += 1
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
            outLen += 1
            out[outLen] = out[srcIndex]
            srcIndex += 1
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
                k += 1
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
                ui += 1
            elseif kinds[i] == 2 then
                a[i]={__ContentObjectRef=objectRefs[oi]}
                oi += 1
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
                cursor += 1
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
                    meshNative += 1
                elseif mode == "fallback" then
                    meshFallback += 1
                else
                    meshUnresolved += 1
                end
                return obj
            end
            meshUnresolved += 1
            return nil
        end
        if node.ClassName == "UnionOperation" or node.ClassName == "PartOperation" or node.ClassName == "IntersectOperation" then
            local obj, mode = tryLoadPartOperationNode(node)
            if obj then
                if mode == "asset" or mode == "mesh" or mode == "visual" then
                    csgAsset += 1
                else
                    csgProxy += 1
                end
                return obj
            end
            csgProxy += 1
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
            skipped += 1
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
            skipped += 1
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
            if not okName then failedProperties += 1 end
        end
        for propName, value in pairs(node.Properties) do
            if propName ~= "Name" then
                local okProp = applyDecodedProperty(
                    obj,
                    propName,
                    value,
                    node.PropertyTypes and node.PropertyTypes[propName]
                )
                if not okProp then failedProperties += 1 end
            end
        end
        rememberStudioLiteState(obj, node)
        disableImportedScript(obj, node)
        normalizePartGeometry(obj, node)
        obj.Parent = parent or containers[routeKey] or containers.WS
        buildBurstCount += 1
        progressMade += 1
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
                skipped += 1
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
                        if not okRef then failedProperties += 1 end
                    end
                elseif typeID == 0x22 then
                    local contentValue = node.Properties[propName]
                    if type(contentValue) == "table" and contentValue.__ContentObjectRef then
                        local targetObj = made[contentValue.__ContentObjectRef]
                        if targetObj then
                            local okRef = pcall(function()
                                obj[propName] = targetObj
                            end)
                            if not okRef then failedProperties += 1 end
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
                scriptBatch += 1
                if scriptBatch >= 40 then
                    scriptBatch = 0
                    task.wait()
                end
            end
        end
    end)
    flushServerLoadsAsync()
    local madeCount = 0
    for _ in pairs(made) do madeCount += 1 end
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
        nextRef += 1
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
            skipped += 1
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
                if not okProp then failedProperties += 1 end
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
                skipped += 1
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
    for _ in pairs(made) do count += 1 end
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
            totalObjects += #descendants + 1
            local all = {root}
            for _, obj in ipairs(descendants) do
                all[#all + 1] = obj
            end
            for i, obj in ipairs(all) do
                obj:SetAttribute("LANGZ_ImportedObject", true)
                if obj:IsA("LuaSourceContainer") then
                    scriptCount += 1
                    local source = takeRBXMSource(sourceQueues, obj)
                    if source then
                        sourceFound += 1
                        _G.Langz_RAW_SOURCES[obj] = source
                        local wrote = tryWriteRBXMSource(obj, source)
                        if wrote then
                            sourceWritten += 1
                        end
                        local okEditor = pcall(function()
                            injectStudioLiteUI(obj, {})
                        end)
                        if okEditor then
                            editorRestored += 1
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
            stats.skipped += 1
            setScriptEnabledState(scr, false)
        else
            local hasRealSource = canReadExecutableSource(scr)
            if hasRealSource then
                local ok = setScriptEnabledState(scr, true)
                if ok then
                    stats.native += 1
                else
                    stats.failed += 1
                end
            else
                setScriptEnabledState(scr, false)
                local ok = runLocalScriptBridge(scr)
                if ok then
                    stats.bridge += 1
                else
                    stats.failed += 1
                end
            end
        end
    end
    return stats
end
local function mergeLiveStats(dst, src)
    dst.native += src.native or 0
    dst.bridge += src.bridge or 0
    dst.failed += src.failed or 0
    dst.skipped += src.skipped or 0
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
            stats.scripts += 1
            local ok = tryWriteRealScriptSource(obj)
            if ok then
                stats.scriptSourceOK += 1
            else
                stats.scriptSourceFailed += 1
            end
        end
    end
    for _, obj in ipairs(all) do
        if obj:IsA("BasePart") then
            stats.parts += 1
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
            moved += 1
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
                moved += 1
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
            reusedServiceCount += 1
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
            createdServiceCount += 1
            serviceModes[serviceName] = "CREATED_MISSING"
            return created
        end
        local okGet, service = pcall(function()
            return game:GetService(serviceName)
        end)
        if okGet and service then
            forcedServiceCount += 1
            serviceModes[serviceName] = "GETSERVICE_MISSING"
            pcall(function()
                service:SetAttribute("LANGZ_ServiceRole", serviceName)
            end)
            return service
        end
        missingRealServices += 1
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
                        scriptCount += 1
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
                moved += moveChildren(serviceFolder, destination, onMoved)
            elseif #serviceFolder:GetChildren() > 0 then
                failedServices += 1
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
            activatedScripts += 1
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
                liveStats.native += 1
            else
                setScriptEnabledState(obj, false)
                local ok = runLocalScriptBridge(obj)
                if ok then
                    liveStats.bridge += 1
                else
                    liveStats.failed += 1
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
                deployedScriptCount += 1
                if serviceKey == "SSS" then
                    sssImportedScripts += 1
                elseif serviceKey == "SS" then
                    ssImportedScripts += 1
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
                    sourceVisibleCount += 1
                    pcall(function()
                        tryWriteRealScriptSource(obj)
                    end)
                    local okEditor = pcall(function()
                        injectStudioLiteUI(obj, {})
                    end)
                    if okEditor then
                        editorInjectedCount += 1
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
            remainingStagedObjects += #serviceFolder:GetChildren()
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
        summary ..= " • spawn depan kamera gagal: " .. tostring(spawnError)
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
                if okAnchor then stats.parts += 1 end
            elseif obj:IsA("LuaSourceContainer") then
                stats.scripts += 1
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
                    stats.sources += 1
                    _G.Langz_RAW_SOURCES[obj] = source
                    local wrote = tryWriteRBXMSource(obj, source)
                    if not wrote then
                        wrote = tryWriteRealScriptSource(obj)
                    end
                    if wrote then stats.written += 1 end
                    pcall(injectStudioLiteUI, obj, {})
                    local hasEditor = obj:FindFirstChild("SL_CodeTextBox") ~= nil
                    if hasEditor then
                        stats.editors += 1
                    end
                    if wrote or hasEditor then stats.visible += 1 end
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

local function importFile(f)
    local tujuanModel = TUJUAN[idxTujuan]
    local oldProgressCallback = _G.LANGZ_IMPORT_PROGRESS_CB
    _G.LANGZ_IMPORT_PROGRESS_CB = function(_, message)
        if type(message) == "string" then setStatus(message) end
    end

    local ok, berhasil, pesan = pcall(function()
        local info = {path = f.path, name = f.nama}
        if f.ext == "rbxl" or f.ext == "rbxlx" then
            local importOk, importMessage, importRoot = studioLiteImporter.importRBXL(info)
            if not importOk then return false, importMessage end
            if not importRoot then return false, "Engine tidak menghasilkan root import" end

            local activateOk, activateMessage = studioLiteImporter.activateImportRoot(importRoot)
            if not activateOk then return false, activateMessage end
            return true, tostring(importMessage) .. " | " .. tostring(activateMessage)
        end
        local importOk, importMessage, importedRoots = studioLiteImporter.importRBXM(info)
        if importOk and type(importedRoots) == "table" then
            for _, root in ipairs(importedRoots) do
                root.Parent = tujuanModel.obj
            end
            if tujuanModel.obj == workspace then
                local positioned, positionMessage = taruhGrupDiDepan(importedRoots)
                if not positioned then
                    importMessage = tostring(importMessage)
                        .. " | spawn depan kamera gagal: " .. tostring(positionMessage)
                end
            end
        end
        return importOk, importMessage
    end)

    _G.LANGZ_IMPORT_PROGRESS_CB = oldProgressCallback
    if not ok then
        setStatus("Gagal import: " .. tostring(berhasil), true)
        return false
    end
    if not berhasil then
        setStatus("Gagal import: " .. tostring(pesan), true)
        return false
    end

    setStatus(tostring(pesan))
    print("[Importer] " .. f.nama .. ": " .. tostring(pesan))
    return true
end

------------------------------------------------------------------
-- INTI: UPLOAD LEWAT ROBLOX OPEN CLOUD
------------------------------------------------------------------
local function buatMultipart(metaJson, namaFile, tipeKonten, isiFile)
    local batas = "----ImporterHub" .. tostring(math.random(100000, 999999)) .. tostring(os.time())
    local sep = "--" .. batas
    local aman = namaFile:gsub("[^%w%._%-]", "_")
    local bagian = {
        sep,
        'Content-Disposition: form-data; name="request"',
        "",
        metaJson,
        sep,
        'Content-Disposition: form-data; name="fileContent"; filename="' .. aman .. '"',
        "Content-Type: " .. tipeKonten,
        "",
        isiFile,
        sep .. "--",
        "",
    }
    return table.concat(bagian, "\r\n"), batas
end

local function unggahFile(f, jenis)
    if not httpReq then
        setStatus("Executor kamu tidak support request / http_request", true)
        return false
    end
    local idPembuat = trim(config.creatorId):match("^%d+$")
    if trim(config.ocKey) == "" or not idPembuat then
        setStatus("Isi Open Cloud API Key & Creator ID di menu Pengaturan dulu", true)
        return false
    end
    if not readfile then
        setStatus("Executor kamu tidak support readfile", true)
        return false
    end

    setStatus("Membaca " .. f.nama .. "...")
    local okR, isiFile = pcall(readfile, f.path)
    if not okR or type(isiFile) ~= "string" or #isiFile == 0 then
        setStatus("Gagal membaca file", true)
        return false
    end
    if #isiFile > 20 * 1024 * 1024 then
        setStatus("File lebih dari 20 MB, tidak bisa diunggah", true)
        return false
    end

    local tipeKonten = CONTENT_TYPE[f.ext]
    if not tipeKonten then
        setStatus("Format file tidak didukung: ." .. tostring(f.ext), true)
        return false
    end

    local nama = f.nama:gsub("%.[^%.]+$", "")
    nama = nama:sub(1, 50)

    local pembuat = {}
    if config.creatorTipe == "Group" then pembuat.groupId = idPembuat else pembuat.userId = idPembuat end

    local meta = HttpService:JSONEncode({
        assetType = jenis.tipe,
        displayName = nama,
        description = "Diunggah lewat Importer Hub",
        creationContext = {creator = pembuat},
    })
    local bodyReq, batas = buatMultipart(meta, f.nama, tipeKonten, isiFile)

    setStatus("Mengunggah " .. f.nama .. " sebagai " .. jenis.tipe .. "...")
    local okP, res = pcall(httpReq, {
        Url = "https://apis.roblox.com/assets/v1/assets",
        Method = "POST",
        Headers = {
            ["x-api-key"] = trim(config.ocKey),
            ["Content-Type"] = "multipart/form-data; boundary=" .. batas,
        },
        Body = bodyReq,
    })
    if not okP or not res then
        setStatus("Request gagal: " .. tostring(res), true)
        return false
    end

    local d = decodeJson(res)
    if not d or not d.path then
        local pesan = d and (d.message or d.error) or ("HTTP " .. tostring(res.StatusCode))
        setStatus("Upload ditolak (HTTP " .. tostring(res.StatusCode) .. "): " .. tostring(pesan), true)
        return false
    end

    -- Tunggu operasi selesai
    local hasilId
    for _ = 1, 40 do
        local dOp = d
        if not dOp.done then
            task.wait(1.5)
            local okQ, r2 = pcall(httpReq, {
                Url = "https://apis.roblox.com/assets/v1/" .. d.path,
                Method = "GET",
                Headers = {["x-api-key"] = trim(config.ocKey)},
            })
            dOp = okQ and decodeJson(r2) or nil
        end
        if dOp and dOp.done then
            if dOp.response and dOp.response.assetId then
                hasilId = tostring(dOp.response.assetId)
            else
                local pesan = dOp.error and dOp.error.message or "tidak diketahui"
                setStatus("Upload gagal: " .. tostring(pesan), true)
                return false
            end
            break
        end
    end

    if not hasilId then
        setStatus("Upload masih diproses, cek lagi nanti di Creator Hub", true)
        return false
    end

    if setclipboard then pcall(setclipboard, hasilId) end
    setStatus("Upload berhasil! Asset ID: " .. hasilId .. (setclipboard and " (disalin)" or ""))
    print("[Importer] Upload berhasil: " .. f.nama .. " -> asset ID " .. hasilId)
    return true
end

------------------------------------------------------------------
-- KOMPONEN: ITEM DAFTAR & PANEL DAFTAR FILE
------------------------------------------------------------------
local sedangKerja = false

local function buatItem(listFrame, urut, tagTeks, nama, sub, teksTombol, aksi)
    local item = sudut(buat("Frame", {
        Name = "Item", Size = UDim2.new(1, -8, 0, 44),
        BackgroundColor3 = C.kartu, BorderSizePixel = 0, LayoutOrder = urut,
    }, listFrame), 8)
    local tag = sudut(buat("Frame", {
        Size = UDim2.new(0, 52, 0, 26), Position = UDim2.new(0, 8, 0.5, -13),
        BackgroundColor3 = C.bg, BorderSizePixel = 0,
    }, item), 6)
    label({Text = tagTeks, Font = Enum.Font.GothamBold, TextSize = 10,
        Size = UDim2.new(1, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Center}, tag)
    label({Text = nama, Font = Enum.Font.GothamBold, TextSize = 12,
        Position = UDim2.new(0, 68, 0, sub and 4 or 0),
        Size = UDim2.new(1, -160, 0, sub and 20 or 44),
        TextTruncate = Enum.TextTruncate.AtEnd}, item)
    if sub then
        label({Text = sub, TextColor3 = C.redup, TextSize = 10,
            Position = UDim2.new(0, 68, 0, 24), Size = UDim2.new(1, -160, 0, 16),
            TextTruncate = Enum.TextTruncate.AtEnd}, item)
    end
    local btn = tombol({Text = teksTombol, TextSize = 11, Size = UDim2.new(0, 76, 0, 28),
        Position = UDim2.new(1, -84, 0.5, -14), BackgroundColor3 = C.aktif}, item)

    btn.Activated:Connect(function()
        if sedangKerja then return end
        sedangKerja = true
        btn.Text = "..."
        task.spawn(function()
            local ok, hasil = pcall(aksi)
            if not ok then
                setStatus("Error: " .. tostring(hasil), true)
                hasil = false
            end
            btn.Text = hasil and "DONE" or "ULANG"
            sedangKerja = false
        end)
    end)
    return item
end

local function buatItemToolbox(listFrame, urut, tagTeks, aset, teksTombol, aksi)
    local item = sudut(buat("Frame", {
        Name = "Item",
        Size = UDim2.new(1, -8, 0, 200),
        BackgroundColor3 = C.kartu,
        BorderSizePixel = 0,
        LayoutOrder = urut,
    }, listFrame), 10)

    local thumbnail = buat("ImageLabel", {
        Size = UDim2.new(0, 64, 0, 64),
        Position = UDim2.new(0.5, -32, 0, 8),
        BackgroundColor3 = C.bg,
        BorderSizePixel = 0,
        Image = "rbxthumb://type=Asset&id=" .. aset.id .. "&w=420&h=420",
        ScaleType = Enum.ScaleType.Crop,
    }, item)
    sudut(thumbnail, 8)

    local tag = sudut(buat("Frame", {
        Size = UDim2.new(0, 52, 0, 14),
        Position = UDim2.new(0.5, -26, 0, 58),
        BackgroundColor3 = C.bg,
        BorderSizePixel = 0,
    }, item), 4)
    label({Text = tagTeks, Font = Enum.Font.GothamBold, TextSize = 8,
        Size = UDim2.new(1, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Center}, tag)

    label({Text = aset.nama, Font = Enum.Font.GothamBold, TextSize = 13,
        Position = UDim2.new(0, 8, 0, 78),
        Size = UDim2.new(1, -16, 0, 30),
        TextXAlignment = Enum.TextXAlignment.Center,
        TextWrapped = true,
        TextTruncate = Enum.TextTruncate.AtEnd}, item)
    label({Text = "Creator: " .. tostring(aset.pembuat or "?"),
        TextColor3 = C.redup, TextSize = 10,
        Position = UDim2.new(0, 8, 0, 110),
        Size = UDim2.new(1, -16, 0, 18),
        TextXAlignment = Enum.TextXAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd}, item)

    label({Text = "ID: " .. tostring(aset.id), TextColor3 = C.teks, TextSize = 10,
        Position = UDim2.new(0, 8, 0, 132),
        Size = UDim2.new(1, -16, 0, 18),
        TextXAlignment = Enum.TextXAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd}, item)

    local copyButton = tombol({
        Name = "CopyAssetId",
        Text = "SALIN",
        TextSize = 9,
        Size = UDim2.new(0, 52, 0, 28),
        Position = UDim2.new(0, 8, 1, -36),
        BackgroundColor3 = C.kartu,
    }, item)
    copyButton.Activated:Connect(function()
        if type(setclipboard) ~= "function" then
            setStatus("Executor tidak mendukung salin ke clipboard", true)
            return
        end
        local ok, err = pcall(setclipboard, tostring(aset.id))
        if ok then
            setStatus("ID " .. tostring(aset.id) .. " disalin")
        else
            setStatus("Gagal menyalin ID: " .. tostring(err), true)
        end
    end)

    local btn = tombol({Text = teksTombol, TextSize = 10,
        Size = UDim2.new(1, -74, 0, 28),
        Position = UDim2.new(0, 66, 1, -36),
        BackgroundColor3 = C.aktif}, item)
    btn.Activated:Connect(function()
        if sedangKerja then return end
        sedangKerja = true
        btn.Text = "..."
        task.spawn(function()
            local ok, hasil = pcall(aksi)
            if not ok then
                setStatus("Error: " .. tostring(hasil), true)
                hasil = false
            end
            btn.Text = hasil and "DONE" or "ULANG"
            sedangKerja = false
        end)
    end)
    return item
end

local function pesanKosong(listFrame, teks)
    label({Name = "Item", Text = "  " .. teks, TextColor3 = C.redup, TextWrapped = true,
        Size = UDim2.new(1, -8, 0, 40), LayoutOrder = 1}, listFrame)
end

local function buatDaftarScroll(induk, posisi, ukuran, duaKolom)
    local list = sudut(buat("ScrollingFrame", {
        Size = ukuran,
        Position = posisi,
        BackgroundColor3 = C.panel,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, induk), 8)
    if duaKolom then
        buat("UIGridLayout", {
            CellSize = UDim2.new(0.5, -6, 0, 200),
            CellPadding = UDim2.new(0, 8, 0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, list)
    else
        buat("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, list)
    end
    buat("UIPadding", {PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4)}, list)
    return list
end

local function buatPanelDaftar(cfg)
    local p = {konteks = nil}
    p.frame = buat("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false}, isi)
    p.judul = label({Text = "", Font = Enum.Font.GothamBold, TextSize = 13,
        Size = UDim2.new(1, 0, 0, 22)}, p.frame)
    p.search = kotakTeks({
        Size = UDim2.new(1, -90, 0, 30), Position = UDim2.new(0, 0, 0, 26),
        Text = "", PlaceholderText = "Cari file...",
    }, p.frame)
    p.scan = tombol({Text = "SCAN", Size = UDim2.new(0, 82, 0, 30),
        Position = UDim2.new(1, -82, 0, 26), BackgroundColor3 = C.aktif}, p.frame)
    p.list = buatDaftarScroll(p.frame, UDim2.new(0, 0, 0, 62), UDim2.new(1, 0, 1, -100))
    p.kembali = tombol({Text = "< Kembali", Size = UDim2.new(0, 90, 0, 28),
        Position = UDim2.new(0, 0, 1, -28), BackgroundColor3 = C.kartu}, p.frame)
    p.extra = tombol({Text = "", Size = UDim2.new(0, 190, 0, 28),
        Position = UDim2.new(1, -190, 1, -28), BackgroundColor3 = C.kartu, TextSize = 11}, p.frame)

    function p.render()
        for _, c in ipairs(p.list:GetChildren()) do
            if c.Name == "Item" then c:Destroy() end
        end
        local konteks = p.konteks
        local q = p.search.Text:lower()
        local urut = 0
        for _, f in ipairs(cfg.ambil(konteks)) do
            if q == "" or f.nama:lower():find(q, 1, true) then
                urut = urut + 1
                buatItem(p.list, urut, string.upper(f.ext or ""), f.nama, nil, cfg.tombol,
                    function() return cfg.aksi(f, konteks) end)
            end
        end
        if urut == 0 then
            pesanKosong(p.list, "Belum ada file. Taruh file di folder Workspace Delta lalu tekan SCAN.")
        end
    end

    p.search:GetPropertyChangedSignal("Text"):Connect(p.render)
    p.scan.Activated:Connect(function() lakukanScan() end)
    p.kembali.Activated:Connect(function() bukaHalaman("dashboard") end)
    halaman[cfg.nama] = p.frame
    return p
end

------------------------------------------------------------------
-- HALAMAN: DASHBOARD
------------------------------------------------------------------
local halDash = buat("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, isi)
halaman.dashboard = halDash
buat("UIListLayout", {
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, halDash)

local ICON_BY_KEY = {
    dashboard = "134003209888315",
    spoof = "124837118008108",
    ytupload = "128502300590884",
    toolbox = "121323758319527",
    music = "96724400016066",
    rbxm = "106962661743892",
    rbxmx = "106962661743892",
    rbxl = "122982660526589",
    rbxlx = "122982660526589",
    up_model = "106962661743892",
    ai = "120498354657105",
    setelan = "92592867988128",
}

local dashboardMetrics = {}
local dashboardMetricSegments = {}
local dashboardMetricHistory = {}
local dashboardMetricCharts = {}
local dashboardMetricAngles = {}
local metricsRow = buat("Frame", {
    Size = UDim2.new(1, -4, 0, 82),
    BackgroundTransparency = 1,
    LayoutOrder = 1,
}, halDash)
buat("UIGridLayout", {
    CellSize = UDim2.new(0.25, -5, 1, 0),
    CellPadding = UDim2.new(0, 5, 0, 0),
    FillDirectionMaxCells = 4,
    SortOrder = Enum.SortOrder.LayoutOrder,
}, metricsRow)

local metricOrder = 0
local function buatMetrikDashboard(key, judul)
    metricOrder += 1
    local card = sudut(buat("Frame", {
        BackgroundColor3 = C.panel,
        BorderSizePixel = 0,
        LayoutOrder = metricOrder,
    }, metricsRow), 8)
    local chart = buat("Frame", {
        Name = "MetricRing",
        Size = UDim2.new(0, 44, 0, 44),
        Position = UDim2.new(0.5, 0, 0, 2),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundTransparency = 1,
        ZIndex = 1,
    }, card)
    dashboardMetricCharts[key] = chart
    dashboardMetricAngles[key] = 0
    dashboardMetricSegments[key] = {}
    dashboardMetricHistory[key] = {}
    for i = 1, 8 do
        local angle = (i - 1) * 45 - 90
        local length = 3
        local radius = 12 + length / 2
        local radians = math.rad(angle)
        local segment = sudut(buat("Frame", {
            Name = "MetricSegment",
            Size = UDim2.new(0, 3, 0, length),
            Position = UDim2.new(
                0, 22 + math.cos(radians) * radius - 1.5,
                0, 22 + math.sin(radians) * radius - length / 2
            ),
            Rotation = angle + 90,
            BackgroundColor3 = C.aksen,
            BackgroundTransparency = 0.82,
            BorderSizePixel = 0,
            ZIndex = 2,
        }, chart), 2)
        table.insert(dashboardMetricSegments[key], segment)
    end
    dashboardMetrics[key] = label({
        Text = "--",
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Center,
        Position = UDim2.new(0, 2, 0, 14),
        Size = UDim2.new(1, -4, 0, 20),
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 3,
    }, card)
    label({
        Text = judul,
        Font = Enum.Font.GothamBold,
        TextColor3 = C.redup,
        TextSize = 7,
        TextXAlignment = Enum.TextXAlignment.Center,
        Position = UDim2.new(0, 2, 0, 55),
        Size = UDim2.new(1, -4, 0, 14),
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 3,
    }, card)
end

local function tambahSampelMetrik(key, nilai)
    if type(nilai) ~= "number" or nilai ~= nilai then return end
    local history = dashboardMetricHistory[key]
    local segments = dashboardMetricSegments[key]
    local chart = dashboardMetricCharts[key]
    if not history or not segments or not chart then return end

    table.insert(history, math.max(0, nilai))
    while #history > #segments do table.remove(history, 1) end

    local maximum = 1
    for _, sample in ipairs(history) do
        if sample > maximum then maximum = sample end
    end
    for i, segment in ipairs(segments) do
        local sample = history[i]
        local length = sample and math.max(3, math.floor(sample / maximum * 9 + 0.5)) or 3
        local angle = (i - 1) * 45 - 90
        local radians = math.rad(angle)
        local radius = 12 + length / 2
        local position = UDim2.new(
            0, 22 + math.cos(radians) * radius - 1.5,
            0, 22 + math.sin(radians) * radius - length / 2
        )
        segment.BackgroundTransparency = sample and (0.12 + (1 - sample / maximum) * 0.45) or 0.82
        TweenService:Create(
            segment,
            TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 3, 0, length), Position = position}
        ):Play()
    end
    dashboardMetricAngles[key] = dashboardMetricAngles[key] + 30
    TweenService:Create(
        chart,
        TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
        {Rotation = dashboardMetricAngles[key]}
    ):Play()
end

buatMetrikDashboard("rbxm", "TOTAL RBXM")
buatMetrikDashboard("rbxl", "TOTAL RBXL")
buatMetrikDashboard("cpu", "CPU / FRAME")
buatMetrikDashboard("fps", "FPS")

label({
    Text = "Import dan fitur",
    Font = Enum.Font.GothamBold,
    TextColor3 = C.redup,
    TextSize = 10,
    Size = UDim2.new(1, 0, 0, 16),
    LayoutOrder = 2,
}, halDash)

local dashGrid = buat("Frame", {
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    LayoutOrder = 3,
}, halDash)
buat("UIGridLayout", {
    CellSize = UDim2.new(0.5, -8, 0, 72),
    CellPadding = UDim2.new(0, 8, 0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, dashGrid)

local KARTU = {
    {kunci = "spoof", ikon = "SP", judul = "Spoof & Bypass", ket = "Bypass audio, animasi, decal & script"},
    {kunci = "ytupload", ikon = "YT", judul = "Bypass Audio YT", ket = "Upload & bypass audio YouTube"},
    {kunci = "rbxm", ikon = "M", judul = "Import RBXM", ket = "Model binary (.rbxm)", badge = true},
    {kunci = "rbxl", ikon = "L", judul = "Import RBXL", ket = "Place binary (.rbxl)", badge = true},
    {kunci = "rbxlx", ikon = "LX", judul = "Import RBXLX", ket = "Place XML (.rbxlx)", badge = true},
    {kunci = "rbxmx", ikon = "MX", judul = "Import RBXMX", ket = "Model XML (.rbxmx)", badge = true},
    {kunci = "toolbox", ikon = "TB", judul = "Toolbox", ket = "Cari dan import aset"},
    {kunci = "ai", ikon = "AI", judul = "AI Chat", ket = "Ngobrol dengan AI via OpenRouter"},
    {kunci = "up_model", ikon = "UM", judul = "Upload RBXM", ket = "Unggah model .rbxm"},
    {kunci = "setelan", ikon = "ST", judul = "Pengaturan", ket = "API key & Creator ID"},
}

for i, k in ipairs(KARTU) do
    local kartu = tombol({Text = "", BackgroundColor3 = C.kartu, LayoutOrder = i}, dashGrid)
    local ikon = sudut(buat("Frame", {
        Size = UDim2.new(0, 40, 0, 40), Position = UDim2.new(0, 10, 0.5, -20),
        BackgroundColor3 = C.aktif, BorderSizePixel = 0,
    }, kartu), 10)
    local iconAsset = ICON_BY_KEY[k.kunci]
    if iconAsset then
        buat("ImageLabel", {
            BackgroundTransparency = 1,
            Image = "rbxassetid://" .. iconAsset,
            Position = UDim2.new(0, 4, 0, 4),
            Size = UDim2.new(1, -8, 1, -8),
            ScaleType = Enum.ScaleType.Fit,
        }, ikon)
    else
        label({Text = k.ikon, Font = Enum.Font.GothamBold, TextSize = 14,
            Size = UDim2.new(1, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Center}, ikon)
    end
    label({Text = k.judul, Font = Enum.Font.GothamBold, TextSize = 13,
        Position = UDim2.new(0, 58, 0, 10), Size = UDim2.new(1, -100, 0, 18),
        TextTruncate = Enum.TextTruncate.AtEnd}, kartu)
    label({Text = k.ket, TextColor3 = C.redup, TextSize = 10, TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top,
        Position = UDim2.new(0, 58, 0, 30), Size = UDim2.new(1, -64, 0, 32)}, kartu)
    if k.badge then
        badgeKartu[k.kunci] = label({Text = "0", TextColor3 = C.hijau, Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Right,
            Position = UDim2.new(1, -40, 0, 8), Size = UDim2.new(0, 32, 0, 16)}, kartu)
    end
    kartu.Activated:Connect(function() bukaHalaman(k.kunci) end)
end

------------------------------------------------------------------
-- HALAMAN: PANEL IMPORT & PANEL UPLOAD
------------------------------------------------------------------
local panelImport = buatPanelDaftar({
    nama = "_import",
    tombol = "ACTIVE",
    ambil = function(jenis)
        return jenis and fileTersedia[jenis.kunci] or {}
    end,
    aksi = function(f) return importFile(f) end,
})
table.insert(tombolTujuan, panelImport.extra)
panelImport.extra.Activated:Connect(gantiTujuan)

local panelUpload = buatPanelDaftar({
    nama = "_upload",
    tombol = "UPLOAD",
    ambil = function(jenis)
        local hasil = {}
        if jenis then
            for _, e in ipairs(jenis.ext) do
                for _, f in ipairs(fileTersedia[e] or {}) do table.insert(hasil, f) end
            end
            table.sort(hasil, function(a, b) return a.nama:lower() < b.nama:lower() end)
        end
        return hasil
    end,
    aksi = function(f, jenis) return unggahFile(f, jenis) end,
})
panelUpload.extra.Text = "Atur API Key >"
panelUpload.extra.Activated:Connect(function() bukaHalaman("setelan") end)

------------------------------------------------------------------
-- PANEL SAMPING: TOOLBOX
------------------------------------------------------------------
local TOOLBOX_WIDTH, TOOLBOX_HEIGHT, TOOLBOX_GAP = 340, 480, 12
local MUSIC_WIDTH, MUSIC_HEIGHT = 340, 520
local toolboxTerbuka, musicTerbuka = false, false
local halMusic
local halToolbox = sudut(buat("Frame", {
    Name = "ToolboxPanel",
    Size = UDim2.new(0, TOOLBOX_WIDTH, 0, TOOLBOX_HEIGHT),
    Position = UDim2.new(0.5, 0, 0.5, -TOOLBOX_HEIGHT / 2),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
    Active = true,
    Visible = false,
    ZIndex = 2,
}, gui), 12)
buat("Frame", {
    Size = UDim2.new(0, 3, 1, -24),
    Position = UDim2.new(0, 0, 0, 12),
    BackgroundColor3 = C.aktif,
    BorderSizePixel = 0,
    ZIndex = 3,
}, halToolbox)

local tbHeader = buat("Frame", {
    Size = UDim2.new(1, 0, 0, 42),
    BackgroundTransparency = 1,
}, halToolbox)
label({
    Text = "Toolbox",
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    Position = UDim2.new(0, 14, 0, 4),
    Size = UDim2.new(1, -64, 0, 18),
}, tbHeader)
label({
    Text = "Cari dan import aset",
    TextColor3 = C.redup,
    TextSize = 10,
    Position = UDim2.new(0, 14, 0, 22),
    Size = UDim2.new(1, -64, 0, 14),
}, tbHeader)
local tbClose = tombol({
    Text = "X",
    Size = UDim2.new(0, 28, 0, 28),
    Position = UDim2.new(1, -38, 0, 6),
    BackgroundColor3 = C.kartu,
}, tbHeader)
buat("Frame", {
    Size = UDim2.new(1, -24, 0, 1),
    Position = UDim2.new(0, 12, 0, 41),
    BackgroundColor3 = C.redup,
    BackgroundTransparency = 0.55,
    BorderSizePixel = 0,
}, halToolbox)

local function ubahPosisiPanel(panel, posisi, halus)
    if halus and panel.Visible then
        TweenService:Create(
            panel,
            TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {Position = posisi}
        ):Play()
    else
        panel.Position = posisi
    end
end

local function posisikanPanelSamping(halus, posisiFrame)
    local posisiUtama = posisiFrame or frame.Position
    if musicTerbuka and halMusic then
        ubahPosisiPanel(halMusic, UDim2.new(
            posisiUtama.X.Scale, posisiUtama.X.Offset - MUSIC_WIDTH - TOOLBOX_GAP,
            posisiUtama.Y.Scale, posisiUtama.Y.Offset + (TINGGI - MUSIC_HEIGHT) / 2
        ), halus)
    end
    if toolboxTerbuka then
        ubahPosisiPanel(halToolbox, UDim2.new(
            posisiUtama.X.Scale, posisiUtama.X.Offset + LEBAR + TOOLBOX_GAP,
            posisiUtama.Y.Scale, posisiUtama.Y.Offset + (TINGGI - TOOLBOX_HEIGHT) / 2
        ), halus)
    end
end

local function aturLayoutPanelSamping(halus)
    local ruangKiri = musicTerbuka and (MUSIC_WIDTH + TOOLBOX_GAP) or 0
    local ruangKanan = toolboxTerbuka and (TOOLBOX_WIDTH + TOOLBOX_GAP) or 0
    local lebarGrup = ruangKiri + LEBAR + ruangKanan
    local posisiFrame = UDim2.new(0.5, -lebarGrup / 2 + ruangKiri, 0.5, -TINGGI / 2)
    if halus then
        TweenService:Create(
            frame,
            TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            {Position = posisiFrame}
        ):Play()
    else
        frame.Position = posisiFrame
    end
    posisikanPanelSamping(halus, posisiFrame)
end

bukaToolboxPanel = function()
    if toolboxTerbuka then return end
    toolboxTerbuka = true
    halToolbox.Visible = true
    aturLayoutPanelSamping(true)
    if sorotMenu then sorotMenu("toolbox") end
    jalankanSapuan()
end

tutupToolboxPanel = function()
    if not toolboxTerbuka then return end
    toolboxTerbuka = false
    halToolbox.Visible = false
    aturLayoutPanelSamping(true)
    if sorotMenu then sorotMenu(halamanAktif) end
end
tbClose.Activated:Connect(tutupToolboxPanel)

local KAT = {
    {kunci = "Model", teks = "Model", tag = "MODEL"},
    {kunci = "Decal", teks = "Decal", tag = "DECAL"},
    {kunci = "MeshPart", teks = "Mesh", tag = "MESH"},
}
local katAktif = "Model"
local tombolKat = {}

local barisKat = buat("Frame", {
    Size = UDim2.new(1, -24, 0, 28),
    Position = UDim2.new(0, 12, 0, 46),
    BackgroundTransparency = 1,
}, halToolbox)
buat("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4),
    SortOrder = Enum.SortOrder.LayoutOrder}, barisKat)

local function sorotKat()
    for k, b in pairs(tombolKat) do
        b.BackgroundColor3 = (k == katAktif) and C.aktif or C.kartu
    end
end

for i, k in ipairs(KAT) do
    local b = tombol({Text = k.teks, Size = UDim2.new(1 / #KAT, -3, 1, 0), LayoutOrder = i,
        BackgroundColor3 = C.kartu}, barisKat)
    tombolKat[k.kunci] = b
    b.Activated:Connect(function()
        katAktif = k.kunci
        sorotKat()
    end)
end
sorotKat()

local tbInput = kotakTeks({
    Size = UDim2.new(1, -114, 0, 30), Position = UDim2.new(0, 12, 0, 80),
    Text = "", PlaceholderText = "Kata kunci, contoh: sword",
}, halToolbox)
local tbCari = tombol({Text = "CARI", Size = UDim2.new(0, 82, 0, 30),
    Position = UDim2.new(1, -94, 0, 80), BackgroundColor3 = C.aktif}, halToolbox)
local tbList = buatDaftarScroll(
    halToolbox,
    UDim2.new(0, 12, 0, 116),
    UDim2.new(1, -24, 1, -150),
    true
)
local tbInfo = label({Text = "", TextColor3 = C.redup, TextSize = 11,
    Position = UDim2.new(0, 12, 1, -28), Size = UDim2.new(1, -222, 0, 28),
    TextTruncate = Enum.TextTruncate.AtEnd}, halToolbox)
local tbTujuan = tombol({Text = "", Size = UDim2.new(0, 190, 0, 28),
    Position = UDim2.new(1, -202, 1, -28), BackgroundColor3 = C.kartu, TextSize = 11}, halToolbox)
table.insert(tombolTujuan, tbTujuan)
tbTujuan.Activated:Connect(gantiTujuan)

local function cariCreatorStore(kat, q)
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
    if not httpReq then
        return nil, "request API tidak tersedia untuk membaca source asset"
    end
    local ok, response = pcall(httpReq, {
        Url = "https://assetdelivery.roblox.com/v1/asset/?id=" .. HttpService:UrlEncode(assetId),
        Method = "GET",
    })
    if not ok or type(response) ~= "table" then
        return nil, "Asset Delivery request gagal: " .. tostring(response)
    end
    if tonumber(response.StatusCode) ~= 200 then
        return nil, "Asset Delivery HTTP " .. tostring(response.StatusCode)
    end
    if type(response.Body) ~= "string" or #response.Body == 0 then
        return nil, "Asset Delivery mengembalikan payload kosong"
    end
    if #response.Body > 20 * 1024 * 1024 then
        return nil, "Payload asset lebih dari 20 MB"
    end
    return response.Body
end

local function memilikiScriptToolbox(objects)
    for _, root in ipairs(objects) do
        if root:IsA("LuaSourceContainer") then return true end
        for _, descendant in ipairs(root:GetDescendants()) do
            if descendant:IsA("LuaSourceContainer") then return true end
        end
    end
    return false
end

local function masukkanAsetToolbox(kat, it)
    local tujuan = TUJUAN[idxTujuan].obj
    setStatus("Memuat " .. it.nama .. "...")

    if kat == "Decal" then
        local tex = "rbxassetid://" .. it.id
        local ok, objs = pcall(function() return game:GetObjects(tex) end)
        if ok and type(objs) == "table" and objs[1] and objs[1]:IsA("Decal") then
            tex = objs[1].Texture
        end
        local part = Instance.new("Part")
        part.Name = it.nama:sub(1, 40)
        part.Anchored = true
        part.Size = Vector3.new(6, 6, 0.2)
        local d = Instance.new("Decal")
        d.Face = Enum.NormalId.Front
        d.Texture = tex
        d.Parent = part
        part.Parent = tujuan
        local positioned, positionMessage = true, nil
        if tujuan == workspace then positioned, positionMessage = taruhDiDepan(part) end
        if positioned then
            setStatus("Decal dipasang: " .. it.nama)
        else
            setStatus("Decal dipasang, tapi spawn depan kamera gagal: " .. tostring(positionMessage), true)
        end
        return true
    end

    local ok, objs = pcall(function() return game:GetObjects("rbxassetid://" .. it.id) end)
    if ok and type(objs) == "table" and #objs > 0 then
        local sourceData, sourceError
        local sourceStats
        if kat == "Model" and memilikiScriptToolbox(objs) then
            setStatus("Membaca source script dari asset...")
            sourceData, sourceError = unduhPayloadToolbox(it.id)
        end
        if kat == "Model" then
            sourceStats = studioLiteImporter.prepareToolboxObjects(objs, sourceData)
        end
        local berhasil, spawnError = pasangHasil(objs, it.nama)
        if not berhasil then return false end
        if sourceStats and sourceStats.scripts > 0 then
            local terlihat = sourceStats.visible
            if sourceStats.missingSources > 0 or terlihat < sourceStats.sources or spawnError then
                local alasan = sourceError or sourceStats.parseError
                if spawnError then
                    alasan = (alasan and tostring(alasan) .. "; " or "")
                        .. "spawn dekat gagal: " .. tostring(spawnError)
                elseif not alasan then
                    alasan = "source tidak dapat dipulihkan"
                end
                setStatus(string.format(
                    "Aset masuk; source %d/%d, script hilang %d. %s",
                    terlihat, sourceStats.scripts, sourceStats.missingSources, tostring(alasan)
                ), true)
            else
                setStatus(string.format(
                    "Aset masuk; source %d/%d dipulihkan dan script nonaktif untuk diperiksa",
                    terlihat, sourceStats.scripts
                ))
            end
        elseif spawnError then
            setStatus("Aset masuk, tapi spawn dekat gagal: " .. tostring(spawnError), true)
        end
        return true
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
        local positioned, positionMessage = true, nil
        if tujuan == workspace then positioned, positionMessage = taruhDiDepan(part) end
        if positioned then
            setStatus("Mesh dipasang: " .. it.nama)
        else
            setStatus("Mesh dipasang, tapi spawn depan kamera gagal: " .. tostring(positionMessage), true)
        end
        return true
    end

    setStatus("Gagal memuat asset: " .. tostring(objs), true)
    return false
end

local function cariToolbox()
    local q = trim(tbInput.Text)
    if q == "" then
        setStatus("Ketik kata kunci dulu", true)
        return
    end
    if not httpReq then
        setStatus("Executor kamu tidak support request / http_request", true)
        return
    end
    local kat = katAktif
    local tagKat
    for _, k in ipairs(KAT) do if k.kunci == kat then tagKat = k.tag end end
    setStatus("Mencari " .. kat .. ": " .. q .. "...")
    tbInfo.Text = "Mencari..."

    task.spawn(function()
        local hasil, err = cariCreatorStore(kat, q)
        for _, c in ipairs(tbList:GetChildren()) do
            if c.Name == "Item" then c:Destroy() end
        end
        if not hasil then
            setStatus("Pencarian gagal: " .. tostring(err), true)
            tbInfo.Text = "Gagal"
            pesanKosong(tbList, "Pencarian gagal. Coba lagi.")
            return
        end
        if #hasil == 0 then
            tbInfo.Text = "0 hasil"
            setStatus("Tidak ada hasil untuk: " .. q, true)
            pesanKosong(tbList, "Tidak ada hasil.")
            return
        end
        for i, it in ipairs(hasil) do
            buatItemToolbox(tbList, i, tagKat, it, "IMPORT",
                function() return masukkanAsetToolbox(kat, it) end)
        end
        tbInfo.Text = #hasil .. " hasil"
        setStatus(#hasil .. " hasil " .. kat .. " untuk: " .. q)
    end)
end

tbCari.Activated:Connect(cariToolbox)
tbInput.FocusLost:Connect(function(enter) if enter then cariToolbox() end end)

------------------------------------------------------------------
-- PANEL SAMPING: MUSIC PLAYER
------------------------------------------------------------------
local MUSIC_LOGO = "rbxassetid://102337382069600"
local MUSIC_TRACKS = {
    {nama = "DJ BREAKBEAT BARAT, Vol. 1", id = "115153624060642", genre = "Breakbeat", pembuat = "DistrokidOfficial"},
    {nama = "DJ Phut Hon Indo Full Bass", id = "85427648559465", genre = "Breakbeat", pembuat = "DistrokidOfficial"},
    {nama = "DJ STAY THE SAME BREAKBEAT", id = "74088514222709", genre = "Breakbeat", pembuat = "DistrokidOfficial"},
    {nama = "DJ MISSING YOU BREAKBEAT", id = "119116468910055", genre = "Breakbeat", pembuat = "DistrokidOfficial"},
    {nama = "DJ LAST GOODBYE BREAKBEAT", id = "139065609615135", genre = "Breakbeat", pembuat = "DistrokidOfficial"},
    {nama = "DJ WHERE DID YOUR LOVE GO BREAKBEAT", id = "91342380026565", genre = "Breakbeat", pembuat = "DistrokidOfficial"},
    {nama = "DJ ALL OF ME IS YOURS BREAKBEAT", id = "104593616947405", genre = "Breakbeat", pembuat = "DistrokidOfficial"},
    {nama = "DJ NO EXPIRATION DATE BREAKBEAT", id = "88762074202384", genre = "Breakbeat", pembuat = "DistrokidOfficial"},
    {nama = "Aku Suka Jedag Jedug Full Bass", id = "100787734732008", genre = "Breakbeat", pembuat = "DistrokidOfficial"},
    {nama = "CELAWZE I BIARKAN KU PERGI BREAKBEAT", id = "81426876012759", genre = "Breakbeat", pembuat = "DistrokidOfficial"},
    {nama = "Breakbeat Mansion", id = "1838727070", genre = "Breakbeat", pembuat = "APMOfficial"},
    {nama = "Latin Breakbeat - Instrumental", id = "9039703049", genre = "Breakbeat", pembuat = "APMOfficial"},
    {nama = "JAY | Blackhole Breakbeat", id = "117574079633196", genre = "Breakbeat", pembuat = "DistrokidOfficial"},
    {nama = "Electronic EDM Rhythm", id = "85837065623863", genre = "EDM", pembuat = "DistrokidOfficial"},
    {nama = "Funky Disco Beats", id = "9038367768", genre = "EDM", pembuat = "APMOfficial"},
    {nama = "Deep House Techno Pulse", id = "80225919436233", genre = "EDM", pembuat = "DistrokidOfficial"},
    {nama = "Predator (EDM, electronic dance)", id = "75075980497523", genre = "EDM", pembuat = "DistrokidOfficial"},
    {nama = "Night Drive Gravity EDM Remix", id = "90723418714244", genre = "EDM", pembuat = "DistrokidOfficial"},
    {nama = "Midnight Engine EDM Club Remix", id = "77208158074918", genre = "EDM", pembuat = "DistrokidOfficial"},
    {nama = "Neon Run", id = "104498304463922", genre = "EDM", pembuat = "DistrokidOfficial"},
    {nama = "Skyline Bounce", id = "132588706181756", genre = "EDM", pembuat = "DistrokidOfficial"},
    {nama = "Run the Night", id = "129158012324844", genre = "EDM", pembuat = "DistrokidOfficial"},
    {nama = "Digital Flames", id = "101278896981200", genre = "EDM", pembuat = "DistrokidOfficial"},
    {nama = "Life Here Now Forever (a) (30)", id = "9045594726", genre = "EDM", pembuat = "APMOfficial"},
    {nama = "How Hyped How Hot (a) (30)", id = "1838051027", genre = "EDM", pembuat = "APMOfficial"},
    {nama = "Floating Through Deeper Thoughts (15 sec)", id = "9038366905", genre = "EDM", pembuat = "APMOfficial"},
    {nama = "Life Here Now Forever (b) (30)", id = "9045595952", genre = "EDM", pembuat = "APMOfficial"},
    {nama = "DJ IRONVEIN - Anthem House Remix", id = "137443947685209", genre = "DJ Mix", pembuat = "DistrokidOfficial"},
    {nama = "Feel Only Love (Dance)", id = "104177688386014", genre = "DJ Mix", pembuat = "DistrokidOfficial"},
    {nama = "digidi digidi hey stay in my rom dj remix", id = "108919662663242", genre = "DJ Mix", pembuat = "DistrokidOfficial"},
    {nama = "Let Love Happen X Tchu Tcha Tcha (Dance)", id = "103765309710247", genre = "DJ Mix", pembuat = "DistrokidOfficial"},
    {nama = "Good Love (Dance)", id = "93966344127430", genre = "DJ Mix", pembuat = "DistrokidOfficial"},
    {nama = "Remix by DJ Superviel", id = "81599443446781", genre = "DJ Mix", pembuat = "DistrokidOfficial"},
    {nama = "Cumbia DJ Mix", id = "70489315110582", genre = "DJ Mix", pembuat = "DistrokidOfficial"},
    {nama = "Party House Mix | DJ Linuxxx", id = "80314545116582", genre = "DJ Mix", pembuat = "DistrokidOfficial"},
    {nama = "Rock the Phunky Beats", id = "70707928734875", genre = "DJ Mix", pembuat = "DistrokidOfficial"},
    {nama = "Happy DJ (Rhythm Mix)", id = "1839075254", genre = "DJ Mix", pembuat = "APMOfficial"},
    {nama = "DJ / Pop Track Concept (Dance-Pop Mix)", id = "82028519579865", genre = "DJ Mix", pembuat = "DistrokidOfficial"},
    {nama = "We Raise Up Again", id = "73521953281663", genre = "DJ Mix", pembuat = "DistrokidOfficial"},
    {nama = "You Got to Have Faith", id = "82571224785601", genre = "DJ Mix", pembuat = "DistrokidOfficial"},
    {nama = "Keep Going", id = "106628268112826", genre = "DJ Mix", pembuat = "DistrokidOfficial"},
    {nama = "Welcome to My House", id = "86078342485207", genre = "DJ Mix", pembuat = "DistrokidOfficial"},
    {nama = "Baila Lento", id = "112179327038508", genre = "DJ Mix", pembuat = "DistrokidOfficial"},
    {nama = "Skyline Riot", id = "106661367200367", genre = "EDM", pembuat = "DistrokidOfficial"},
    {nama = "After the Fall", id = "78224983844766", genre = "EDM", pembuat = "DistrokidOfficial"},
    {nama = "Pulse After Midnight", id = "116687923706682", genre = "EDM", pembuat = "DistrokidOfficial"},
    {nama = "Ghosts in the Neon", id = "130827383001969", genre = "EDM", pembuat = "DistrokidOfficial"},
    {nama = "Sky of Sound", id = "94699879620769", genre = "EDM", pembuat = "DistrokidOfficial"},
    {nama = "Twinkle Twinkle Little Star (EDM-Pop Remix)", id = "133792227976953", genre = "EDM", pembuat = "DistrokidOfficial"},
    {nama = "I Miss You", id = "140627598377770", genre = "Sad", pembuat = "DistrokidOfficial"},
    {nama = "Sad End (Solo Piano)", id = "1838635121", genre = "Sad", pembuat = "APMOfficial"},
    {nama = "The Loneliest Hour", id = "114213622974713", genre = "Sad", pembuat = "DistrokidOfficial"},
    {nama = "The Still, Sad Music Of Humanity", id = "9046435309", genre = "Sad", pembuat = "APMOfficial"},
    {nama = "Sad Emotional Piano Instrumental", id = "122979340200406", genre = "Sad", pembuat = "DistrokidOfficial"},
    {nama = "Sad Midnight Touch", id = "123156844134737", genre = "Sad", pembuat = "DistrokidOfficial"},
    {nama = "That Old Red Radio Played", id = "140471301437637", genre = "Sad", pembuat = "DistrokidOfficial"},
    {nama = "You Were My Safe Place", id = "138108296865882", genre = "Sad", pembuat = "DistrokidOfficial"},
    {nama = "Sad Songs Same Story", id = "140031636344247", genre = "Sad", pembuat = "DistrokidOfficial"},
    {nama = "You Loved Me Until You Didn't", id = "126333704664658", genre = "Sad", pembuat = "DistrokidOfficial"},
    {nama = "Past Lives", id = "124836999167090", genre = "Sad", pembuat = "DistrokidOfficial"},
    {nama = "When You Said Goodbye", id = "96332574400847", genre = "Sad", pembuat = "DistrokidOfficial"},
    {nama = "We Almost Had Forever", id = "139085431440194", genre = "Sad", pembuat = "DistrokidOfficial"},
    {nama = "Spring of Deception", id = "102450285837527", genre = "Sad", pembuat = "DistrokidOfficial"},
    {nama = "After The Rain We Rise", id = "135159252018449", genre = "Sad", pembuat = "DistrokidOfficial"},
    {nama = "Reflections", id = "140636167703930", genre = "Sad", pembuat = "DistrokidOfficial"},
    {nama = "Our World Is Too Far", id = "139380427193851", genre = "Sad", pembuat = "DistrokidOfficial"},
    {nama = "Sad Love Songs That Make You Cry", id = "114888868295036", genre = "Sad", pembuat = "DistrokidOfficial"},
    {nama = "sad song (soua)", id = "138915385850637", genre = "Sad", pembuat = "DistrokidOfficial"},
}

local musicService = game:GetService("SoundService")
local oldMusicSound = musicService:FindFirstChild("ImporterHubMusicPlayer")
if oldMusicSound and oldMusicSound:IsA("Sound") then
    oldMusicSound:Stop()
    oldMusicSound:Destroy()
end
local musicSound = Instance.new("Sound")
musicSound.Name = "ImporterHubMusicPlayer"
musicSound.Volume = 0.5
musicSound.Looped = false
musicSound.Parent = musicService

halMusic = sudut(buat("Frame", {
    Name = "MusicPanel",
    Size = UDim2.new(0, MUSIC_WIDTH, 0, MUSIC_HEIGHT),
    Position = UDim2.new(0.5, 0, 0.5, -MUSIC_HEIGHT / 2),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
    Active = true,
    Visible = false,
    ZIndex = 2,
}, gui), 12)
buat("Frame", {
    Size = UDim2.new(0, 3, 1, -24),
    Position = UDim2.new(0, 0, 0, 12),
    BackgroundColor3 = C.aktif,
    BorderSizePixel = 0,
    ZIndex = 3,
}, halMusic)

local musicHeader = buat("Frame", {
    Size = UDim2.new(1, 0, 0, 42),
    BackgroundTransparency = 1,
}, halMusic)
label({
    Text = "Music Player",
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    Position = UDim2.new(0, 14, 0, 4),
    Size = UDim2.new(1, -64, 0, 18),
}, musicHeader)
label({
    Text = "Breakbeat, EDM, dan sad",
    TextColor3 = C.redup,
    TextSize = 10,
    Position = UDim2.new(0, 14, 0, 22),
    Size = UDim2.new(1, -64, 0, 14),
}, musicHeader)
local musicClose = tombol({
    Text = "X",
    Size = UDim2.new(0, 28, 0, 28),
    Position = UDim2.new(1, -38, 0, 6),
    BackgroundColor3 = C.kartu,
}, musicHeader)
buat("Frame", {
    Size = UDim2.new(1, -24, 0, 1),
    Position = UDim2.new(0, 12, 0, 41),
    BackgroundColor3 = C.redup,
    BackgroundTransparency = 0.55,
    BorderSizePixel = 0,
}, halMusic)

local nowPlaying = sudut(buat("Frame", {
    Name = "NowPlaying",
    Size = UDim2.new(1, -24, 0, 104),
    Position = UDim2.new(0, 12, 0, 50),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
}, halMusic), 10)
local nowPlayingLogo = sudut(buat("ImageLabel", {
    Name = "NowPlayingLogo",
    Size = UDim2.new(0, 76, 0, 76),
    Position = UDim2.new(0, 12, 0.5, -38),
    BackgroundColor3 = C.kartu,
    BorderSizePixel = 0,
    Image = MUSIC_LOGO,
    ScaleType = Enum.ScaleType.Fit,
}, nowPlaying), 8)
label({
    Text = "SEKARANG DIPUTAR",
    Font = Enum.Font.GothamBold,
    TextColor3 = C.redup,
    TextSize = 9,
    Position = UDim2.new(0, 100, 0, 10),
    Size = UDim2.new(1, -110, 0, 14),
}, nowPlaying)
local musicTitle = label({
    Text = "Pilih lagu",
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextWrapped = true,
    TextYAlignment = Enum.TextYAlignment.Top,
    Position = UDim2.new(0, 100, 0, 27),
    Size = UDim2.new(1, -110, 0, 34),
    TextTruncate = Enum.TextTruncate.AtEnd,
}, nowPlaying)
local musicCreator = label({
    Text = "Roblox Creator Store",
    TextColor3 = C.redup,
    TextSize = 10,
    Position = UDim2.new(0, 100, 0, 63),
    Size = UDim2.new(1, -110, 0, 16),
    TextTruncate = Enum.TextTruncate.AtEnd,
}, nowPlaying)
local musicId = label({
    Text = "ID: --",
    TextColor3 = C.teks,
    TextSize = 10,
    Position = UDim2.new(0, 100, 0, 81),
    Size = UDim2.new(1, -110, 0, 14),
    TextTruncate = Enum.TextTruncate.AtEnd,
}, nowPlaying)
local musicProgressTrack = sudut(buat("Frame", {
    Name = "PlaybackProgressTrack",
    Size = UDim2.new(1, -110, 0, 4),
    Position = UDim2.new(0, 100, 0, 98),
    BackgroundColor3 = C.kartu,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, nowPlaying), 2)
local musicProgressFill = sudut(buat("Frame", {
    Name = "PlaybackProgressFill",
    Size = UDim2.new(0, 0, 1, 0),
    BackgroundColor3 = C.aksen,
    BorderSizePixel = 0,
}, musicProgressTrack), 2)

local musicPrevious = tombol({
    Text = "PREV",
    TextSize = 9,
    Size = UDim2.new(0, 48, 0, 34),
    Position = UDim2.new(0, 32, 0, 164),
    BackgroundColor3 = C.kartu,
}, halMusic)
local musicPlay = tombol({
    Text = "PLAY",
    TextSize = 11,
    Size = UDim2.new(0, 112, 0, 34),
    Position = UDim2.new(0, 86, 0, 164),
    BackgroundColor3 = C.aktif,
}, halMusic)
local musicNext = tombol({
    Text = "NEXT",
    TextSize = 9,
    Size = UDim2.new(0, 48, 0, 34),
    Position = UDim2.new(0, 204, 0, 164),
    BackgroundColor3 = C.kartu,
}, halMusic)
local musicStop = tombol({
    Text = "STOP",
    TextSize = 9,
    Size = UDim2.new(0, 48, 0, 34),
    Position = UDim2.new(0, 258, 0, 164),
    BackgroundColor3 = C.kartu,
}, halMusic)

local volumeLevels = {0.25, 0.5, 0.75, 1}
local volumeIndex = 2
local musicVolume = tombol({
    Text = "VOL 50%",
    TextSize = 9,
    Size = UDim2.new(0, 82, 0, 24),
    Position = UDim2.new(0, 12, 0, 206),
    BackgroundColor3 = C.kartu,
}, halMusic)
local musicPlaybackState = label({
    Text = "Siap diputar",
    TextColor3 = C.redup,
    TextSize = 10,
    Position = UDim2.new(0, 104, 0, 206),
    Size = UDim2.new(1, -116, 0, 24),
    TextTruncate = Enum.TextTruncate.AtEnd,
}, halMusic)
local renderMusicList
local musicGenreAktif = "Semua"
local musicGenreButtons = {}
local musicFilterRow = buat("Frame", {
    Size = UDim2.new(1, -24, 0, 24),
    Position = UDim2.new(0, 12, 0, 238),
    BackgroundTransparency = 1,
}, halMusic)
buat("UIGridLayout", {
    CellSize = UDim2.new(0.2, -4, 1, 0),
    CellPadding = UDim2.new(0, 4, 0, 0),
    FillDirectionMaxCells = 5,
    SortOrder = Enum.SortOrder.LayoutOrder,
}, musicFilterRow)
local function perbaruiMusicGenre()
    for genre, button in pairs(musicGenreButtons) do
        local terpilih = genre == musicGenreAktif
        button.BackgroundColor3 = terpilih and C.aktif or C.kartu
        button.TextColor3 = terpilih and C.teks or C.redup
    end
end
for i, genre in ipairs({"Semua", "Breakbeat", "EDM", "DJ Mix", "Sad"}) do
    local namaGenre = genre
    local genreButton = tombol({
        Text = namaGenre,
        TextSize = 8,
        LayoutOrder = i,
        BackgroundColor3 = namaGenre == musicGenreAktif and C.aktif or C.kartu,
        TextColor3 = namaGenre == musicGenreAktif and C.teks or C.redup,
        AutoButtonColor = false,
    }, musicFilterRow)
    musicGenreButtons[namaGenre] = genreButton
    genreButton.Activated:Connect(function()
        musicGenreAktif = namaGenre
        perbaruiMusicGenre()
        if renderMusicList then renderMusicList() end
    end)
end
local musicSearch = kotakTeks({
    Size = UDim2.new(1, -24, 0, 30),
    Position = UDim2.new(0, 12, 0, 270),
    Text = "",
    PlaceholderText = "Cari judul, genre, atau ID...",
}, halMusic)
local musicList = buatDaftarScroll(
    halMusic,
    UDim2.new(0, 12, 0, 306),
    UDim2.new(1, -24, 1, -344),
    false
)
local musicCount = label({
    Text = "",
    TextColor3 = C.redup,
    TextSize = 9,
    Position = UDim2.new(0, 12, 1, -28),
    Size = UDim2.new(1, -24, 0, 18),
    TextTruncate = Enum.TextTruncate.AtEnd,
}, halMusic)

local musicSongIndex
local musicLoadToken = 0
local function playMusicTrack(index)
    local track = MUSIC_TRACKS[index]
    if not track then return end
    musicSongIndex = index
    musicTitle.Text = track.nama
    musicCreator.Text = track.pembuat .. " | " .. track.genre
    musicId.Text = "ID: " .. track.id
    musicSound:Stop()
    musicSound.SoundId = "rbxassetid://" .. track.id
    musicLoadToken += 1
    local loadToken = musicLoadToken
    musicPlaybackState.Text = "Memuat audio..."
    local okPlay, playError = pcall(function() musicSound:Play() end)
    if not okPlay then
        musicPlaybackState.Text = "Gagal memutar"
        setStatus("Gagal memutar audio: " .. tostring(playError), true)
        return
    end
    musicPlay.Text = "PAUSE"
    setStatus("Memuat: " .. track.nama)
    if renderMusicList then renderMusicList() end
    task.delay(12, function()
        if loadToken == musicLoadToken and musicSound.Parent and not musicSound.IsLoaded then
            musicPlaybackState.Text = "Audio belum dimuat"
            setStatus("Audio belum dimuat; periksa izin ID " .. track.id, true)
        end
    end)
end

local function daftarLaguTerfilter()
    local query = trim(musicSearch.Text):lower()
    local indices = {}
    for index, track in ipairs(MUSIC_TRACKS) do
        local haystack = (track.nama .. " " .. track.genre .. " " .. track.id .. " " .. track.pembuat):lower()
        local matchesGenre = musicGenreAktif == "Semua" or track.genre == musicGenreAktif
        if matchesGenre and (query == "" or haystack:find(query, 1, true)) then
            table.insert(indices, index)
        end
    end
    return indices
end

renderMusicList = function()
    for _, child in ipairs(musicList:GetChildren()) do
        if child.Name == "MusicTrackItem" or child.Name == "MusicEmpty" then
            child:Destroy()
        end
    end
    local matches = 0
    local filteredIndices = daftarLaguTerfilter()
    for _, index in ipairs(filteredIndices) do
        local track = MUSIC_TRACKS[index]
        matches += 1
        local row = sudut(buat("Frame", {
            Name = "MusicTrackItem",
            Size = UDim2.new(1, -8, 0, 58),
            BackgroundColor3 = C.kartu,
            BorderSizePixel = 0,
            LayoutOrder = matches,
        }, musicList), 8)
        sudut(buat("ImageLabel", {
            Size = UDim2.new(0, 34, 0, 34),
            Position = UDim2.new(0, 8, 0.5, -17),
            BackgroundColor3 = C.panel,
            BorderSizePixel = 0,
            Image = MUSIC_LOGO,
            ScaleType = Enum.ScaleType.Fit,
        }, row), 6)
        label({
            Text = track.nama,
            Font = Enum.Font.GothamBold,
            TextSize = 10,
            Position = UDim2.new(0, 50, 0, 8),
            Size = UDim2.new(1, -116, 0, 18),
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, row)
        label({
            Text = track.genre .. " | ID " .. track.id,
            TextColor3 = C.redup,
            TextSize = 8,
            Position = UDim2.new(0, 50, 0, 29),
            Size = UDim2.new(1, -116, 0, 16),
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, row)
        local playTrack = tombol({
            Text = musicSongIndex == index and musicSound.IsPlaying and "AKTIF" or "PUTAR",
            TextSize = 8,
            Size = UDim2.new(0, 54, 0, 28),
            Position = UDim2.new(1, -62, 0.5, -14),
            BackgroundColor3 = musicSongIndex == index and musicSound.IsPlaying and C.aktif or C.panel,
        }, row)
        playTrack.Activated:Connect(function() playMusicTrack(index) end)
    end
    if matches == 0 then
        label({
            Name = "MusicEmpty",
            Text = "Tidak ada lagu yang cocok. Coba kata kunci atau ID lain.",
            TextColor3 = C.redup,
            TextWrapped = true,
            Size = UDim2.new(1, -8, 0, 40),
            LayoutOrder = 1,
        }, musicList)
    end
    musicCount.Text = matches .. " / " .. #MUSIC_TRACKS .. " lagu publik"
end

musicSound.Loaded:Connect(function()
    if musicSongIndex and musicSound.IsPlaying then
        musicPlaybackState.Text = "Sedang diputar"
        setStatus("Memutar: " .. MUSIC_TRACKS[musicSongIndex].nama)
    end
end)
musicSound.Ended:Connect(function()
    musicPlay.Text = "PLAY"
    musicPlaybackState.Text = "Lagu selesai"
    if musicSongIndex then
        setStatus("Selesai: " .. MUSIC_TRACKS[musicSongIndex].nama)
    end
    renderMusicList()
end)
musicSearch:GetPropertyChangedSignal("Text"):Connect(renderMusicList)
musicVolume.Activated:Connect(function()
    volumeIndex = volumeIndex % #volumeLevels + 1
    musicSound.Volume = volumeLevels[volumeIndex]
    musicVolume.Text = "VOL " .. tostring(math.floor(musicSound.Volume * 100 + 0.5)) .. "%"
end)
musicPrevious.Activated:Connect(function()
    local filtered = daftarLaguTerfilter()
    if #filtered == 0 then return end
    local currentPosition = musicSongIndex and table.find(filtered, musicSongIndex)
    local index = filtered[currentPosition and (currentPosition - 2) % #filtered + 1 or #filtered]
    playMusicTrack(index)
end)
musicNext.Activated:Connect(function()
    local filtered = daftarLaguTerfilter()
    if #filtered == 0 then return end
    local currentPosition = musicSongIndex and table.find(filtered, musicSongIndex)
    local nextPosition = currentPosition and currentPosition % #filtered + 1 or 1
    playMusicTrack(filtered[nextPosition])
end)
musicPlay.Activated:Connect(function()
    if not musicSongIndex then
        local filtered = daftarLaguTerfilter()
        if #filtered > 0 then playMusicTrack(filtered[1]) else
            setStatus("Tidak ada lagu yang cocok untuk diputar", true)
        end
        return
    end
    if musicSound.IsPlaying then
        musicSound:Pause()
        musicPlay.Text = "PLAY"
        musicPlaybackState.Text = "Dijeda"
        setStatus("Dijeda: " .. MUSIC_TRACKS[musicSongIndex].nama)
    else
        if musicSound.TimeLength > 0 and musicSound.TimePosition >= musicSound.TimeLength then
            musicSound.TimePosition = 0
        end
        local okPlay, playError = pcall(function() musicSound:Play() end)
        if not okPlay then
            musicPlaybackState.Text = "Gagal memutar"
            setStatus("Gagal melanjutkan audio: " .. tostring(playError), true)
            return
        end
        musicPlay.Text = "PAUSE"
        musicPlaybackState.Text = "Sedang diputar"
        setStatus("Memutar: " .. MUSIC_TRACKS[musicSongIndex].nama)
    end
    renderMusicList()
end)
musicStop.Activated:Connect(function()
    musicLoadToken += 1
    musicSound:Stop()
    musicPlay.Text = "PLAY"
    musicPlaybackState.Text = "Dihentikan"
    setStatus("Audio dihentikan")
    renderMusicList()
end)

bukaMusicPanel = function()
    if musicTerbuka then return end
    musicTerbuka = true
    halMusic.Visible = true
    aturLayoutPanelSamping(true)
    if sorotMenu then sorotMenu("music") end
    jalankanSapuan()
end
tutupMusicPanel = function()
    if not musicTerbuka then return end
    musicTerbuka = false
    halMusic.Visible = false
    aturLayoutPanelSamping(true)
    if sorotMenu then sorotMenu(halamanAktif) end
end
musicClose.Activated:Connect(tutupMusicPanel)
renderMusicList()
task.spawn(function()
    while gui.Parent and musicSound.Parent do
        local duration = musicSound.TimeLength
        local progress = duration > 0 and math.clamp(musicSound.TimePosition / duration, 0, 1) or 0
        musicProgressFill.Size = UDim2.new(progress, 0, 1, 0)
        task.wait(0.2)
    end
end)

------------------------------------------------------------------
local function initHalamanAI()
-- HALAMAN: AI CHAT (OpenRouter)
------------------------------------------------------------------
local halAI = buat("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false}, isi)
halaman.ai = halAI

local aiList = sudut(buat("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, -38),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, halAI), 8)
buat("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, aiList)
buat("UIPadding", {PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6)}, aiList)

local aiInput = kotakTeks({
    Size = UDim2.new(1, -160, 0, 30), Position = UDim2.new(0, 0, 1, -30),
    Text = "", PlaceholderText = "Tulis pesan...",
}, halAI)
local aiKirim = tombol({Text = "KIRIM", Size = UDim2.new(0, 74, 0, 30),
    Position = UDim2.new(1, -154, 1, -30), BackgroundColor3 = C.aktif}, halAI)
local aiReset = tombol({Text = "RESET", Size = UDim2.new(0, 76, 0, 30),
    Position = UDim2.new(1, -76, 1, -30), BackgroundColor3 = C.kartu}, halAI)

local riwayat = {}
local urutPesan = 0
local aiSibuk = false
local AWALAN = {user = "Kamu: ", ai = "AI: ", sistem = ""}

local function tambahPesan(peran, teks)
    urutPesan = urutPesan + 1
    local warna = peran == "user" and C.aktif or (peran == "ai" and C.kartu or Color3.fromRGB(80, 56, 56))
    local lbl = sudut(buat("TextLabel", {
        Size = UDim2.new(1, -14, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = warna,
        BorderSizePixel = 0,
        Text = AWALAN[peran] .. teks,
        TextColor3 = C.teks,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        LayoutOrder = urutPesan,
    }, aiList), 8)
    buat("UIPadding", {PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, lbl)
    task.defer(function()
        task.wait()
        aiList.CanvasPosition = Vector2.new(0, 99999)
    end)
    return lbl
end

local function pesanUntukAPI()
    local hasil = {{role = "system",
        content = "Kamu asisten yang membantu soal Roblox, Luau, dan scripting. Jawab singkat dan jelas dalam bahasa Indonesia."}}
    local mulai = math.max(1, #riwayat - 19)
    for i = mulai, #riwayat do table.insert(hasil, riwayat[i]) end
    return hasil
end

local function redaksiAI(nilai)
    local teks = tostring(nilai)
    local key = trim(config.orKey)
    if key ~= "" then
        teks = teks:gsub(key:gsub("([^%w])", "%%%1"), "<REDACTED>")
    end
    return teks
end

local function formatAIError(statusCode, apiError)
    local detail = {}
    if statusCode ~= nil then
        table.insert(detail, "HTTP " .. redaksiAI(statusCode))
    end
    if type(apiError) == "table" then
        if apiError.code ~= nil then
            table.insert(detail, "kode " .. redaksiAI(apiError.code))
        end
        local metadata = apiError.metadata
        if type(metadata) == "table" and type(metadata.provider_name) == "string"
            and metadata.provider_name ~= "" then
            table.insert(detail, "provider " .. redaksiAI(metadata.provider_name))
        end
        if apiError.message ~= nil then
            table.insert(detail, redaksiAI(apiError.message))
        end
    elseif apiError ~= nil then
        table.insert(detail, redaksiAI(apiError))
    end
    if #detail == 0 then return "Respons tidak valid" end
    return table.concat(detail, " | ")
end

local function kirimAI()
    local teks = trim(aiInput.Text)
    if teks == "" or aiSibuk then return end
    if trim(config.orKey) == "" then
        tambahPesan("sistem", "Isi OpenRouter API Key di menu Pengaturan dulu.")
        return
    end
    if not httpReq then
        tambahPesan("sistem", "Executor kamu tidak support request / http_request.")
        return
    end

    aiSibuk = true
    aiInput.Text = ""
    tambahPesan("user", teks)
    table.insert(riwayat, {role = "user", content = teks})
    local tunggu = tambahPesan("ai", "...")

    task.spawn(function()
        local ok, res = pcall(httpReq, {
            Url = "https://openrouter.ai/api/v1/chat/completions",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Authorization"] = "Bearer " .. trim(config.orKey),
            },
            Body = HttpService:JSONEncode({model = trim(config.orModel), messages = pesanUntukAPI()}),
        })

        local jawaban, galat
        if ok and res then
            local d = decodeJson(res)
            if d and d.choices and d.choices[1] and d.choices[1].message then
                jawaban = tostring(d.choices[1].message.content or "")
            elseif d and d.error then
                galat = formatAIError(res.StatusCode, d.error)
            else
                galat = formatAIError(res.StatusCode)
            end
        else
            galat = redaksiAI(res)
        end

        if jawaban then
            tunggu.Text = AWALAN.ai .. jawaban
            table.insert(riwayat, {role = "assistant", content = jawaban})
        else
            tunggu.Text = "Gagal: " .. tostring(galat)
            tunggu.BackgroundColor3 = Color3.fromRGB(80, 56, 56)
            table.remove(riwayat)
        end
        aiSibuk = false
    end)
end

aiKirim.Activated:Connect(kirimAI)
aiInput.FocusLost:Connect(function(enter) if enter then kirimAI() end end)
aiReset.Activated:Connect(function()
    riwayat = {}
    for _, c in ipairs(aiList:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
    tambahPesan("sistem", "Percakapan direset.")
end)
tambahPesan("sistem", "Halo! Tanya apa saja soal Roblox/Luau. Isi API key OpenRouter di Pengaturan dulu.")

------------------------------------------------------------------
-- HALAMAN: PENGATURAN
------------------------------------------------------------------
------------------------------------------------------------------
end
initHalamanAI()

------------------------------------------------------------------
-- ENGINE SPOOFER & BYPASS IN-GAME (100% Mirror Bot DC Engine)
------------------------------------------------------------------
local function ambilDetailAset(aid)
    local name, creatorId, creatorType = nil, nil, nil

    -- 1. Economy API v2 (Endpoint Utama bot DC)
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

    -- 2. Fallback: Develop API
    if not name then
        local ok2, res2 = pcall(httpReq, {
            Url = "https://develop.roblox.com/v1/assets?assetIds=" .. aid,
            Method = "GET",
            Headers = {["User-Agent"] = "Roblox/WinInet"}
        })
        if ok2 and res2 and (res2.StatusCode == 200 or res2.Status == 200) then
            local d = decodeJson(res2)
            if d and d.data and d.data[1] then
                name = d.data[1].name
                local c = d.data[1].creator
                if c then
                    creatorId = c.id
                    creatorType = c.type
                end
            end
        end
    end

    local cleanName = name and name:gsub("[^%w%s%-_]", ""):sub(1, 35) or ("Asset_" .. aid)
    if cleanName == "" then cleanName = "Asset_" .. aid end
    return cleanName, creatorId, creatorType
end

local function spoofAssetSingleCore(assetId, targetType, speedVal)
    local apiKey = trim(config.ocKey)
    local creatorId = trim(config.creatorId):match("^%d+$")
    if apiKey == "" or not creatorId then
        return nil, "Isi Open Cloud API Key & Creator ID di Pengaturan!"
    end

    -- Ambil nama aset dan creator info
    local assetName, srcCId, srcCType = ambilDetailAset(assetId)

    -- Seed Place IDs untuk bypass (100% mirror bot DC)
    local placeIds = {
        game.PlaceId,
        6872265039, 5765186170, 3271915715, 4483381587,
        7415484388, 4924922222, 2788229376, 142823291,
        6516141723, 987229334, 13772394625, 2753915549,
        119031818630096, 76077593225337, 125981614068947
    }

    -- Lacak games creator asal seperti bot DC
    if srcCId and srcCType == "User" then
        local okG, resG = pcall(httpReq, {
            Url = "https://games.roblox.com/v2/users/" .. srcCId .. "/games?accessFilter=Public&limit=10&sortOrder=Asc",
            Method = "GET"
        })
        if okG and resG and (resG.StatusCode == 200 or resG.Status == 200) then
            local dG = decodeJson(resG)
            if dG and dG.data then
                for _, g in ipairs(dG.data) do
                    if g.rootPlace and g.rootPlace.id then
                        table.insert(placeIds, 1, g.rootPlace.id)
                    end
                end
            end
        end
    elseif srcCId and srcCType == "Group" then
        local okG, resG = pcall(httpReq, {
            Url = "https://games.roblox.com/v2/groups/" .. srcCId .. "/games?accessFilter=Public&limit=10&sortOrder=Asc",
            Method = "GET"
        })
        if okG and resG and (resG.StatusCode == 200 or resG.Status == 200) then
            local dG = decodeJson(resG)
            if dG and dG.data then
                for _, g in ipairs(dG.data) do
                    if g.rootPlace and g.rootPlace.id then
                        table.insert(placeIds, 1, g.rootPlace.id)
                    end
                end
            end
        end
    end

    local fileData = nil

    -- 1. v2 API + Place ID bypass (metode utama bot DC)
    for _, pid in ipairs(placeIds) do
        local ok, r = pcall(httpReq, {
            Url = "https://assetdelivery.roblox.com/v2/assetId/" .. assetId,
            Method = "GET",
            Headers = {
                ["User-Agent"] = "Roblox/WinInet",
                ["Roblox-Place-Id"] = tostring(pid)
            }
        })
        if ok and r and (r.StatusCode == 200 or r.Status == 200) then
            local d = decodeJson(r)
            if d and d.locations and d.locations[1] and d.locations[1].location then
                local cdnUrl = d.locations[1].location
                local ok2, r2 = pcall(httpReq, {
                    Url = cdnUrl,
                    Method = "GET",
                    Headers = {["User-Agent"] = "Roblox/WinInet"}
                })
                if ok2 and r2 and (r2.StatusCode == 200 or r2.Status == 200)
                    and type(r2.Body) == "string" and #r2.Body > 100 then
                    fileData = r2.Body
                    break
                end
            end
        end
        task.wait(0.05)
    end

    -- 2. Fallback v1 direct + Place ID bypass
    if not fileData then
        for _, pid in ipairs(placeIds) do
            local ok, r = pcall(httpReq, {
                Url = "https://assetdelivery.roblox.com/v1/asset/?id=" .. assetId,
                Method = "GET",
                Headers = {
                    ["User-Agent"] = "Roblox/WinInet",
                    ["Roblox-Place-Id"] = tostring(pid)
                }
            })
            if ok and r and (r.StatusCode == 200 or r.Status == 200)
                and type(r.Body) == "string" and #r.Body > 100 then
                local b = r.Body
                if not b:find('^{"errors"') and not b:find('^{"message"') and not b:find('^<') then
                    fileData = b
                    break
                end
            end
            task.wait(0.05)
        end
    end

    -- 3. Fallback game:HttpGet
    if not fileData and game.HttpGet then
        local okG, bodyG = pcall(function()
            return game:HttpGet("https://assetdelivery.roblox.com/v1/asset/?id=" .. assetId)
        end)
        if okG and type(bodyG) == "string" and #bodyG > 100 and not bodyG:find('^{"errors"') then
            fileData = bodyG
        end
    end

    if not fileData then
        return nil, "Asset tidak dapat diunduh (private/rate-limit)", assetName
    end

    local finalType = targetType or "Audio"
    local ext = "mp3"
    local mime = "audio/mpeg"
    if finalType == "Animation" then
        ext = "rbxm"
        mime = "model/x-rbxm"
    elseif finalType == "Decal" then
        ext = "png"
        mime = "image/png"
    else
        finalType = "Audio"
        if fileData:sub(1, 4) == "OggS" then
            ext = "ogg"
            mime = "audio/ogg"
        else
            ext = "mp3"
            mime = "audio/mpeg"
        end
    end

    local creatorObj = {}
    if config.creatorTipe == "Group" then
        creatorObj.groupId = creatorId
    else
        creatorObj.userId = creatorId
    end

    local speedLabel = (speedVal and speedVal ~= "1.0" and speedVal ~= "1") and (" (" .. speedVal .. "x)") or ""
    local displayName = (assetName .. speedLabel):sub(1, 45)

    local meta = HttpService:JSONEncode({
        assetType = finalType,
        displayName = displayName,
        description = "Spoofed via Importer Hub",
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

    if not okP or not res then
        return nil, "Koneksi upload Open Cloud gagal", assetName
    end

    local d = decodeJson(res)
    if not d or not d.path then
        local errPesan = d and (d.message or d.error) or ("HTTP " .. tostring(res.StatusCode))
        return nil, "Ditolak Roblox: " .. tostring(errPesan), assetName
    end

    local newAssetId = nil
    for _ = 1, 35 do
        task.wait(1.5)
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

    if not newAssetId then
        return nil, "Proses upload timeout di server Roblox", assetName
    end

    return newAssetId, assetName
end

local daftarSpeed = {"0.8", "1.0", "1.2", "1.5", "1.8", "2.0", "2.3", "2.5", "3.0"}

local function initHalamanSpoof()
------------------------------------------------------------------
-- HALAMAN: SPOOFER & SCRIPT ID REPLACER
------------------------------------------------------------------
local halSpoof = buat("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    Visible = false,
}, isi)
halaman.spoof = halSpoof
buat("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, halSpoof)
buat("UIPadding", {PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 20), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 10)}, halSpoof)

label({Text = "Spoofer & Bypass Asset Roblox", Font = Enum.Font.GothamBold, TextSize = 14,
    Size = UDim2.new(1, 0, 0, 20), LayoutOrder = 1}, halSpoof)
label({Text = "Duplikasi audio, animasi, decal & ganti semua ID di dalam script secara otomatis.",
    TextColor3 = C.redup, TextSize = 10, Size = UDim2.new(1, 0, 0, 14), LayoutOrder = 2}, halSpoof)

-- Card 1: Spoof Manual ID
local cardSpoofId = sudut(buat("Frame", {
    BackgroundColor3 = C.kartu,
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BorderSizePixel = 0,
    LayoutOrder = 3,
}, halSpoof), 8)
buat("UIPadding", {PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, cardSpoofId)
buat("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, cardSpoofId)

label({Text = "1. SPOOF ASSET ID (Bisa multi ID pisahkan koma/spasi/enter):", Font = Enum.Font.GothamBold, TextSize = 11,
    Size = UDim2.new(1, 0, 0, 16), LayoutOrder = 1}, cardSpoofId)

local inputSpoofId = kotakTeks({
    Size = UDim2.new(1, 0, 0, 36),
    PlaceholderText = "Contoh: 1839075254, 85837065623863...",
    LayoutOrder = 2,
}, cardSpoofId)

-- Pilihan Tipe
label({Text = "PILIH TIPE ASET:", TextColor3 = C.redup, TextSize = 10, Size = UDim2.new(1, 0, 0, 14), LayoutOrder = 3}, cardSpoofId)
local rowTipe = buat("Frame", {Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, LayoutOrder = 4}, cardSpoofId)
buat("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6)}, rowTipe)

local tipeTerpilih = "Audio"
local tombolTipeMap = {}
local daftarTipe = {
    {k = "Audio", nama = "🎵 Audio"},
    {k = "Animation", nama = "🎬 Animasi"},
    {k = "Decal", nama = "🖼️ Decal"}
}

local function updateTipeUI()
    for k, btn in pairs(tombolTipeMap) do
        local aktif = (k == tipeTerpilih)
        btn.BackgroundColor3 = aktif and C.aktif or C.panel
        btn.TextColor3 = aktif and C.teks or C.redup
    end
end

for _, item in ipairs(daftarTipe) do
    local btn = tombol({
        Text = item.nama,
        Size = UDim2.new(0.32, -4, 1, 0),
        BackgroundColor3 = C.panel,
    }, rowTipe)
    tombolTipeMap[item.k] = btn
    btn.Activated:Connect(function()
        tipeTerpilih = item.k
        updateTipeUI()
    end)
end
updateTipeUI()

-- Pilihan Speed
label({Text = "PILIH SPEED BYPASS (Untuk Audio / Musik):", TextColor3 = C.redup, TextSize = 10, Size = UDim2.new(1, 0, 0, 14), LayoutOrder = 5}, cardSpoofId)
local rowSpeed = buat("Frame", {Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, LayoutOrder = 6}, cardSpoofId)
buat("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4)}, rowSpeed)

-- Rekomendasi Sound.PlaybackSpeed Realtime Label
local lblRecSpeed = label({
    Text = "💡 Rekomendasi Sound.PlaybackSpeed: 1.00x",
    TextColor3 = C.redup,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    Size = UDim2.new(1, 0, 0, 16),
    LayoutOrder = 7,
}, cardSpoofId)

local function hitungRecPlayback(sp)
    local num = tonumber(sp)
    if not num or num <= 0 then return "1.00x" end
    return string.format("%.2f", 1.0 / num) .. "x"
end

local speedTerpilih = "1.0"
local tombolSpeedMap = {}

local function updateSpeedUI()
    for s, btn in pairs(tombolSpeedMap) do
        local aktif = (s == speedTerpilih)
        btn.BackgroundColor3 = aktif and C.aktif or C.panel
        btn.TextColor3 = aktif and C.teks or C.redup
    end
    if lblRecSpeed then
        lblRecSpeed.Text = "💡 Rekomendasi Sound.PlaybackSpeed In-Game: " .. hitungRecPlayback(speedTerpilih)
    end
end

for _, sp in ipairs(daftarSpeed) do
    local btn = tombol({
        Text = sp .. "x",
        Size = UDim2.new(0.1, 0, 1, 0),
        BackgroundColor3 = C.panel,
        TextSize = 10,
    }, rowSpeed)
    tombolSpeedMap[sp] = btn
    btn.Activated:Connect(function()
        speedTerpilih = sp
        updateSpeedUI()
    end)
end
updateSpeedUI()

-- Tombol Spoof Sekarang (Warna Abu Default C.aktif)
local btnSpoofNow = tombol({
    Text = "⚡ SPOOF SEKARANG",
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextColor3 = C.teks,
    BackgroundColor3 = C.aktif,
    Size = UDim2.new(1, 0, 0, 32),
    LayoutOrder = 8,
}, cardSpoofId)

local outSpoofId = kotakTeks({
    Size = UDim2.new(1, 0, 0, 75),
    PlaceholderText = "Hasil nama aset dan ID baru akan muncul di sini...",
    TextYAlignment = Enum.TextYAlignment.Top,
    MultiLine = true,
    ClearTextOnFocus = false,
    LayoutOrder = 9,
}, cardSpoofId)

local btnSalinHasilId = tombol({
    Text = "📋 Salin ID Hasil",
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    Size = UDim2.new(1, 0, 0, 26),
    BackgroundColor3 = C.panel,
    LayoutOrder = 10,
}, cardSpoofId)

local cleanOnlyIds = {}

btnSalinHasilId.Activated:Connect(function()
    if setclipboard then
        if #cleanOnlyIds > 0 then
            setclipboard(table.concat(cleanOnlyIds, ", "))
            btnSalinHasilId.Text = "✔ ID Berhasil Disalin!"
        elseif trim(outSpoofId.Text) ~= "" then
            setclipboard(outSpoofId.Text)
            btnSalinHasilId.Text = "✔ Berhasil Disalin!"
        end
        task.delay(1.5, function() btnSalinHasilId.Text = "📋 Salin ID Hasil" end)
    end
end)

btnSpoofNow.Activated:Connect(function()
    local raw = trim(inputSpoofId.Text)
    if raw == "" then
        setStatus("Masukkan Asset ID terlebih dahulu!", true)
        return
    end
    local ids = {}
    for id in raw:gmatch("%d+") do table.insert(ids, id) end
    if #ids == 0 then
        setStatus("Tidak ditemukan angka Asset ID yang valid!", true)
        return
    end

    btnSpoofNow.Text = "⏳ Sedang Memproses (0/" .. #ids .. ")..."
    btnSpoofNow.BackgroundColor3 = C.panel

    task.spawn(function()
        local hasilLines = {}
        cleanOnlyIds = {}
        local suksesCount = 0
        for idx, aid in ipairs(ids) do
            setStatus("Memproses ID " .. aid .. " (" .. idx .. "/" .. #ids .. ")...")
            local newId, optTitle = spoofAssetSingleCore(aid, tipeTerpilih, speedTerpilih)
            local titleClean = optTitle or ("Asset_" .. aid)
            if newId then
                table.insert(hasilLines, titleClean .. " | ID: " .. newId)
                table.insert(cleanOnlyIds, newId)
                suksesCount = suksesCount + 1
            else
                table.insert(hasilLines, "❌ " .. titleClean .. " | Gagal")
            end
            btnSpoofNow.Text = "⏳ Sedang Memproses (" .. idx .. "/" .. #ids .. ")..."
        end

        outSpoofId.Text = table.concat(hasilLines, "\n")
        btnSpoofNow.Text = "⚡ SPOOF SEKARANG"
        btnSpoofNow.BackgroundColor3 = C.aktif
        setStatus("Spoof selesai! " .. suksesCount .. "/" .. #ids .. " ID berhasil.")
        if setclipboard and #cleanOnlyIds > 0 then
            setclipboard(table.concat(cleanOnlyIds, ", "))
        end
    end)
end)

-- Card 2: Spoof & Replace ID di Script
local cardSpoofScript = sudut(buat("Frame", {
    BackgroundColor3 = C.kartu,
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BorderSizePixel = 0,
    LayoutOrder = 4,
}, halSpoof), 8)
buat("UIPadding", {PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, cardSpoofScript)
buat("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, cardSpoofScript)

label({Text = "2. SPOOF & REPLACE ID DI SCRIPT (Audio / Animasi)", Font = Enum.Font.GothamBold, TextSize = 11,
    Size = UDim2.new(1, 0, 0, 16), LayoutOrder = 1}, cardSpoofScript)
label({Text = "Tempel script Lua di bawah. Semua ID sound/animasi akan dispoof & diganti ke ID baru otomatis:",
    TextColor3 = C.redup, TextSize = 10, Size = UDim2.new(1, 0, 0, 14), LayoutOrder = 2}, cardSpoofScript)

local inputScriptBox = kotakTeks({
    Size = UDim2.new(1, 0, 0, 100),
    PlaceholderText = "Tempel script Lua kamu di sini... (contoh: sound.SoundId = 'rbxassetid://12345678')",
    TextYAlignment = Enum.TextYAlignment.Top,
    MultiLine = true,
    ClearTextOnFocus = false,
    LayoutOrder = 3,
}, cardSpoofScript)

local btnSpoofScriptNow = tombol({
    Text = "🔄 SPOOF & REPLACE SEMUA ID DI SCRIPT",
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextColor3 = C.teks,
    BackgroundColor3 = C.aktif,
    Size = UDim2.new(1, 0, 0, 32),
    LayoutOrder = 4,
}, cardSpoofScript)

local outScriptBox = kotakTeks({
    Size = UDim2.new(1, 0, 0, 100),
    PlaceholderText = "Hasil script dengan ID baru akan muncul di sini...",
    TextYAlignment = Enum.TextYAlignment.Top,
    MultiLine = true,
    ClearTextOnFocus = false,
    LayoutOrder = 5,
}, cardSpoofScript)

local btnSalinScript = tombol({
    Text = "📋 Salin Script Hasil",
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    Size = UDim2.new(1, 0, 0, 26),
    BackgroundColor3 = C.panel,
    LayoutOrder = 6,
}, cardSpoofScript)
btnSalinScript.Activated:Connect(function()
    if setclipboard and trim(outScriptBox.Text) ~= "" then
        setclipboard(outScriptBox.Text)
        btnSalinScript.Text = "✔ Script Berhasil Disalin!"
        task.delay(1.5, function() btnSalinScript.Text = "📋 Salin Script Hasil" end)
    end
end)

btnSpoofScriptNow.Activated:Connect(function()
    local scriptContent = inputScriptBox.Text
    if trim(scriptContent) == "" then
        setStatus("Tempel script yang ingin diganti ID-nya!", true)
        return
    end

    local idFound = {}
    for num in scriptContent:gmatch("%d%d%d%d%d%d%d+") do
        if #num >= 7 and #num <= 14 then
            idFound[num] = true
        end
    end

    local listIds = {}
    for id, _ in pairs(idFound) do table.insert(listIds, id) end
    if #listIds == 0 then
        setStatus("Tidak ditemukan nomor ID Roblox di dalam script!", true)
        return
    end

    btnSpoofScriptNow.Text = "⏳ Sedang Memproses ID (0/" .. #listIds .. ")..."
    btnSpoofScriptNow.BackgroundColor3 = C.panel

    task.spawn(function()
        local replacements = {}
        local suksesCount = 0
        for i, aid in ipairs(listIds) do
            setStatus("Spoofing ID script: " .. aid .. " (" .. i .. "/" .. #listIds .. ")...")
            local newId = spoofAssetSingleCore(aid, tipeTerpilih, speedTerpilih)
            if newId then
                replacements[aid] = newId
                suksesCount = suksesCount + 1
            end
            btnSpoofScriptNow.Text = "⏳ Sedang Memproses (" .. i .. "/" .. #listIds .. ")..."
        end

        local finalScript = scriptContent
        for oldId, newId in pairs(replacements) do
            finalScript = finalScript:gsub(oldId, newId)
        end

        outScriptBox.Text = finalScript
        btnSpoofScriptNow.Text = "🔄 SPOOF & REPLACE SEMUA ID DI SCRIPT"
        btnSpoofScriptNow.BackgroundColor3 = C.aktif
        setStatus("Script berhasil dispoof! " .. suksesCount .. "/" .. #listIds .. " ID diperbarui.")
        if setclipboard then setclipboard(finalScript) end
    end)
end)
end
initHalamanSpoof()

local function initHalamanYt()
------------------------------------------------------------------
-- HALAMAN: YOUTUBE UPLOADER & AUDIO BYPASS
------------------------------------------------------------------
local halYtUpload = buat("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    Visible = false,
}, isi)
halaman.ytupload = halYtUpload
buat("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, halYtUpload)
buat("UIPadding", {PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 20), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 10)}, halYtUpload)

label({Text = "Bypass Audio YouTube", Font = Enum.Font.GothamBold, TextSize = 14,
    Size = UDim2.new(1, 0, 0, 20), LayoutOrder = 1}, halYtUpload)
label({Text = "Unduh dan upload audio YouTube berkualitas tinggi langsung ke akun Roblox kamu.",
    TextColor3 = C.redup, TextSize = 10, Size = UDim2.new(1, 0, 0, 14), LayoutOrder = 2}, halYtUpload)

local cardYt = sudut(buat("Frame", {
    BackgroundColor3 = C.kartu,
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BorderSizePixel = 0,
    LayoutOrder = 3,
}, halYtUpload), 8)
buat("UIPadding", {PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, cardYt)
buat("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, cardYt)

label({Text = "MASUKKAN LINK YOUTUBE (Bisa multi link pisahkan koma):", Font = Enum.Font.GothamBold, TextSize = 11,
    Size = UDim2.new(1, 0, 0, 16), LayoutOrder = 1}, cardYt)

local inputYtLink = kotakTeks({
    Size = UDim2.new(1, 0, 0, 36),
    PlaceholderText = "https://www.youtube.com/watch?v=... atau https://youtu.be/...",
    LayoutOrder = 2,
}, cardYt)

label({Text = "PILIH SPEED BYPASS AUDIO:", TextColor3 = C.redup, TextSize = 10, Size = UDim2.new(1, 0, 0, 14), LayoutOrder = 3}, cardYt)
local rowSpeedYt = buat("Frame", {Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, LayoutOrder = 4}, cardYt)
buat("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4)}, rowSpeedYt)

-- Rekomendasi Sound.PlaybackSpeed Realtime Label untuk YT
local lblRecSpeedYt = label({
    Text = "💡 Rekomendasi Sound.PlaybackSpeed: 1.00x",
    TextColor3 = C.redup,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    Size = UDim2.new(1, 0, 0, 16),
    LayoutOrder = 5,
}, cardYt)

local function hitungRecPlaybackYt(sp)
    local num = tonumber(sp)
    if not num or num <= 0 then return "1.00x" end
    return string.format("%.2f", 1.0 / num) .. "x"
end

local speedYtTerpilih = "1.0"
local tombolSpeedYtMap = {}
local function updateSpeedYtUI()
    for s, btn in pairs(tombolSpeedYtMap) do
        local aktif = (s == speedYtTerpilih)
        btn.BackgroundColor3 = aktif and C.aktif or C.panel
        btn.TextColor3 = aktif and C.teks or C.redup
    end
    if lblRecSpeedYt then
        lblRecSpeedYt.Text = "💡 Rekomendasi Sound.PlaybackSpeed In-Game: " .. hitungRecPlaybackYt(speedYtTerpilih)
    end
end

for _, sp in ipairs(daftarSpeed) do
    local btn = tombol({
        Text = sp .. "x",
        Size = UDim2.new(0.1, 0, 1, 0),
        BackgroundColor3 = C.panel,
        TextSize = 10,
    }, rowSpeedYt)
    tombolSpeedYtMap[sp] = btn
    btn.Activated:Connect(function()
        speedYtTerpilih = sp
        updateSpeedYtUI()
    end)
end
updateSpeedYtUI()

local btnYtNow = tombol({
    Text = "🚀 UPLOAD & BYPASS SEKARANG",
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextColor3 = C.teks,
    BackgroundColor3 = C.aktif,
    Size = UDim2.new(1, 0, 0, 32),
    LayoutOrder = 6,
}, cardYt)

local outYtStatus = kotakTeks({
    Size = UDim2.new(1, 0, 0, 55),
    PlaceholderText = "Status dan hasil Asset ID audio akan muncul di sini...",
    TextYAlignment = Enum.TextYAlignment.Top,
    MultiLine = true,
    ClearTextOnFocus = false,
    LayoutOrder = 7,
}, cardYt)

local btnSalinYt = tombol({
    Text = "📋 Salin ID Audio",
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    Size = UDim2.new(1, 0, 0, 26),
    BackgroundColor3 = C.panel,
    LayoutOrder = 8,
}, cardYt)
btnSalinYt.Activated:Connect(function()
    if setclipboard and trim(outYtStatus.Text) ~= "" then
        local raw = outYtStatus.Text
        local idMatch = raw:match("(%d%d%d%d%d%d+)")
        setclipboard(idMatch or raw)
        btnSalinYt.Text = "✔ ID Berhasil Disalin!"
        task.delay(1.5, function() btnSalinYt.Text = "📋 Salin ID Audio" end)
    end
end)

btnYtNow.Activated:Connect(function()
    local urlInput = trim(inputYtLink.Text)
    if urlInput == "" then
        setStatus("Masukkan URL YouTube terlebih dahulu!", true)
        return
    end

    btnYtNow.Text = "⏳ Memproses Audio YouTube..."
    btnYtNow.BackgroundColor3 = C.panel
    setStatus("Memproses audio YouTube...")

    task.spawn(function()
        local bridgeOk = false
        local bridgeUrls = {"http://127.0.0.1:3000/ytupload", "http://localhost:3000/ytupload"}
        for _, bUrl in ipairs(bridgeUrls) do
            local ok, r = pcall(httpReq, {
                Url = bUrl,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode({url = urlInput, speed = speedYtTerpilih, ocKey = config.ocKey, creatorId = config.creatorId})
            })
            if ok and r and (r.StatusCode == 200 or r.Status == 200) then
                local resData = decodeJson(r)
                if resData and resData.assetId then
                    outYtStatus.Text = (resData.title or "YouTube Audio") .. " | ID: " .. tostring(resData.assetId)
                    bridgeOk = true
                    if setclipboard then setclipboard(tostring(resData.assetId)) end
                    break
                end
            end
        end

        btnYtNow.Text = "🚀 UPLOAD & BYPASS SEKARANG"
        btnYtNow.BackgroundColor3 = C.aktif

        if bridgeOk then
            setStatus("Upload YouTube berhasil! ID disalin.")
        else
            outYtStatus.Text = "Gunakan perintah /ytupload di Discord Bot untuk hasil instan, atau jalankan bridge di Termux. URL: " .. urlInput
            setStatus("Bypass YT siap. Gunakan /ytupload di bot Discord untuk instant upload!")
        end
    end)
end)
end
initHalamanYt()

local function initHalamanSetelan()
local halSetelan = buat("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    Visible = false,
}, isi)
halaman.setelan = halSetelan
buat("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, halSetelan)

local function buatField(urut, judul, nilai, ph)
    local baris = buat("Frame", {Size = UDim2.new(1, -8, 0, 48), BackgroundTransparency = 1,
        LayoutOrder = urut}, halSetelan)
    label({Text = judul, TextColor3 = C.redup, TextSize = 10, Size = UDim2.new(1, 0, 0, 14)}, baris)
    return kotakTeks({Size = UDim2.new(1, 0, 0, 28), Position = UDim2.new(0, 0, 0, 16),
        Text = nilai, PlaceholderText = ph}, baris)
end

label({Text = "Pengaturan  ·  API key & Creator ID", Font = Enum.Font.GothamBold, TextSize = 13,
    Size = UDim2.new(1, -8, 0, 20), LayoutOrder = 1}, halSetelan)
label({Text = "Tema warna", TextColor3 = C.redup, TextSize = 10,
    Size = UDim2.new(1, -8, 0, 14), LayoutOrder = 2}, halSetelan)

local tombolTema = {}
local function perbaruiTombolTema()
    for nama, button in pairs(tombolTema) do
        local palet = TEMA[nama]
        local dipilih = nama == temaAktif
        button.BackgroundColor3 = dipilih and palet.aksen or palet.kartu
        local warnaTeks = nama == "Putih" and palet.panel or palet.bg
        button.TextColor3 = dipilih and warnaTeks or palet.teks
        button.Text = (dipilih and "* " or "") .. nama
    end
end

local function terapkanTema(nama)
    local palet = TEMA[nama]
    if not palet then return false end
    if nama == temaAktif then return true end

    local temaLama = {}
    for peran, warna in pairs(C) do temaLama[peran] = warna end
    for _, object in ipairs(gui:GetDescendants()) do
        if object:IsA("GuiObject") then
            local properties = {"BackgroundColor3", "BorderColor3"}
            if object:IsA("ScrollingFrame") then
                table.insert(properties, "ScrollBarImageColor3")
            end
            if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
                table.insert(properties, "TextColor3")
            end
            if object:IsA("TextBox") then
                table.insert(properties, "PlaceholderColor3")
            end
            if object:IsA("ImageLabel") or object:IsA("ImageButton") then
                table.insert(properties, "ImageColor3")
            end
            for _, property in ipairs(properties) do
                local warnaAktual = object[property]
                for peran, warnaLama in pairs(temaLama) do
                    if warnaAktual == warnaLama then
                        local warnaBaru = palet[peran]
                        if warnaBaru then object[property] = warnaBaru end
                        break
                    end
                end
            end
        end
    end
    for peran, warna in pairs(palet) do C[peran] = warna end
    temaAktif = nama
    config.tema = nama
    perbaruiTombolTema()
    return true
end

local themeRow = buat("Frame", {
    Size = UDim2.new(1, -8, 0, 70),
    BackgroundTransparency = 1,
    LayoutOrder = 3,
}, halSetelan)
buat("UIGridLayout", {
    CellSize = UDim2.new(0.2, -4, 0.5, -3),
    CellPadding = UDim2.new(0, 4, 0, 4),
    FillDirectionMaxCells = 5,
    SortOrder = Enum.SortOrder.LayoutOrder,
}, themeRow)

for i, nama in ipairs({"Pink", "Putih", "Merah", "Biru", "Abu", "Ungu", "Toska", "Hijau", "Emas", "Midnight"}) do
    local namaTema = nama
    local palet = TEMA[nama]
    local button = tombol({
        Text = nama,
        TextSize = 9,
        Size = UDim2.new(0.2, -4, 1, 0),
        LayoutOrder = i,
        BackgroundColor3 = palet.kartu,
        TextColor3 = palet.teks,
        AutoButtonColor = false,
    }, themeRow)
    tombolTema[nama] = button
    button.Activated:Connect(function()
        if terapkanTema(namaTema) then
            setStatus("Tema " .. namaTema .. " diterapkan. Tekan SIMPAN untuk menyimpan.")
        end
    end)
end
perbaruiTombolTema()

local fOcKey = buatField(4, "OPEN CLOUD API KEY (untuk Upload, izin Assets)", config.ocKey, "Tempel API key Open Cloud")
local fCreator = buatField(5, "CREATOR ID (User ID atau Group ID)", config.creatorId, "Contoh: 123456789")
local btnTipe = tombol({Text = "Tipe pembuat: " .. config.creatorTipe, Size = UDim2.new(1, -8, 0, 30),
    BackgroundColor3 = C.kartu, LayoutOrder = 6}, halSetelan)
local fOrKey = buatField(7, "OPENROUTER API KEY (untuk AI Chat)", config.orKey, "Tempel API key OpenRouter")
local fOrModel = buatField(8, "MODEL OPENROUTER", config.orModel, "Contoh: openai/gpt-4o-mini")
local btnSimpan = tombol({Text = "SIMPAN KE FILE", Size = UDim2.new(1, -8, 0, 32),
    BackgroundColor3 = C.aktif, LayoutOrder = 9}, halSetelan)
label({Text = "API key disimpan sebagai teks biasa di importer_config.json (folder Workspace Delta). " ..
    "Kalau tidak mau tersimpan, isi saja dan jangan tekan SIMPAN: nilai berlaku sampai GUI ditutup.",
    TextColor3 = C.redup, TextSize = 10, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top,
    Size = UDim2.new(1, -8, 0, 44), LayoutOrder = 10}, halSetelan)

local function bacaSetelan()
    config.ocKey = trim(fOcKey.Text)
    config.creatorId = trim(fCreator.Text)
    config.orKey = trim(fOrKey.Text)
    config.orModel = trim(fOrModel.Text)
    if config.orModel == "" then config.orModel = "openai/gpt-4o-mini" end
end

for _, tb in ipairs({fOcKey, fCreator, fOrKey, fOrModel}) do
    tb.FocusLost:Connect(bacaSetelan)
end
btnTipe.Activated:Connect(function()
    config.creatorTipe = config.creatorTipe == "User" and "Group" or "User"
    btnTipe.Text = "Tipe pembuat: " .. config.creatorTipe
end)
btnSimpan.Activated:Connect(function()
    bacaSetelan()
    if simpanConfig() then
        setStatus("Pengaturan disimpan ke " .. FILE_CONFIG)
    else
        setStatus("Gagal menyimpan (executor tidak support writefile)", true)
    end
end)
end
initHalamanSetelan()

------------------------------------------------------------------
-- MENU SIDEBAR
------------------------------------------------------------------
local function initSidebar()
local sideScroll = buat("ScrollingFrame", {
    Size = UDim2.new(1, -8, 1, -48),
    Position = UDim2.new(0, 4, 0, 44),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, sidebar)
buat("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, sideScroll)

local MENU = {
    {seksi = "MENU"},
    {kunci = "dashboard", nama = "Dashboard"},
    {kunci = "toolbox", nama = "Toolbox"},
    {kunci = "music", nama = "Music"},
    {kunci = "ai", nama = "AI Chat"},
    {seksi = "IMPORT"},
    {kunci = "rbxm", nama = "RBXM", badge = true},
    {kunci = "rbxl", nama = "RBXL", badge = true},
    {kunci = "rbxlx", nama = "RBXLX", badge = true},
    {kunci = "rbxmx", nama = "RBXMX", badge = true},
    {seksi = "GENERAL"},
    {kunci = "spoof", nama = "Spoof & Bypass"},
    {kunci = "ytupload", nama = "Bypass Audio YT"},
    {kunci = "up_model", nama = "Upload RBXM"},
    {kunci = "setelan", nama = "Pengaturan"},
}

for i, m in ipairs(MENU) do
    if m.seksi then
        label({Text = "  " .. m.seksi, TextColor3 = C.redup, Font = Enum.Font.GothamBold, TextSize = 10,
            Size = UDim2.new(1, 0, 0, 16), LayoutOrder = i}, sideScroll)
    else
        local b = tombol({
            Text = "",
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, -4, 0, 28),
            BackgroundColor3 = C.kartu,
            LayoutOrder = i,
        }, sideScroll)
        label({
            Text = m.nama,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            Position = UDim2.new(0, 32, 0, 0),
            Size = UDim2.new(1, m.badge and -80 or -40, 1, 0),
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, b)
        local iconAsset = ICON_BY_KEY[m.kunci]
        if iconAsset then
            buat("ImageLabel", {
                BackgroundTransparency = 1,
                Image = "rbxassetid://" .. iconAsset,
                Position = UDim2.new(0, 7, 0.5, -9),
                Size = UDim2.new(0, 18, 0, 18),
                ScaleType = Enum.ScaleType.Fit,
            }, b)
        end
        menuBtn[m.kunci] = b
        if m.badge then
            badgeMenu[m.kunci] = label({
                Text = "0", TextColor3 = C.redup, TextXAlignment = Enum.TextXAlignment.Right,
                Position = UDim2.new(1, -40, 0, 0), Size = UDim2.new(0, 32, 1, 0),
            }, b)
        end
        b.Activated:Connect(function() bukaHalaman(m.kunci) end)
    end
end

sorotMenu = function(kunci)
    for k, b in pairs(menuBtn) do
        local aktif = k == kunci
            or (k == "toolbox" and toolboxTerbuka)
            or (k == "music" and musicTerbuka)
        b.BackgroundColor3 = aktif and C.aktif or C.kartu
    end
end
end
initSidebar()

------------------------------------------------------------------
-- NAVIGASI & SCAN
------------------------------------------------------------------
local function perbaruiHitungan()
    for _, j in ipairs(JENIS) do
        local n = tostring(#fileTersedia[j.kunci])
        if badgeKartu[j.kunci] then badgeKartu[j.kunci].Text = n end
        if badgeMenu[j.kunci] then badgeMenu[j.kunci].Text = n end
    end
    dashboardMetrics.rbxm.Text = tostring(#fileTersedia.rbxm)
    dashboardMetrics.rbxl.Text = tostring(#fileTersedia.rbxl)
    tambahSampelMetrik("rbxm", #fileTersedia.rbxm)
    tambahSampelMetrik("rbxl", #fileTersedia.rbxl)
end

local function bacaMetrikStats(grup, nama)
    local ok, value = pcall(function()
        local kategori = StatsService:FindFirstChild(grup)
        local item = kategori and kategori:FindFirstChild(nama)
        if not item then return nil end
        return item:GetValue()
    end)
    if ok and type(value) == "number" then return value end
    return nil
end

local function perbaruiMetrikKinerja()
    local cpu = bacaMetrikStats("PerformanceStats", "CPU")
    local fps = bacaMetrikStats("FrameRateManager", "AverageFPS")
    dashboardMetrics.cpu.Text = cpu and string.format("%.0f ms", cpu) or "N/A"
    dashboardMetrics.fps.Text = fps and string.format("%.0f", fps) or "N/A"
    if cpu then tambahSampelMetrik("cpu", cpu) end
    if fps then tambahSampelMetrik("fps", fps) end
end

bukaHalaman = function(kunci)
    if kunci == "toolbox" then
        if bukaToolboxPanel then bukaToolboxPanel() end
        return
    elseif kunci == "music" then
        if bukaMusicPanel then bukaMusicPanel() end
        return
    end
    local gantiTab = halamanAktif ~= nil and halamanAktif ~= kunci
    for _, f in pairs(halaman) do f.Visible = false end

    if JENIS_KUNCI[kunci] then
        local j = JENIS_KUNCI[kunci]
        panelImport.konteks = j
        panelImport.judul.Text = j.judul .. "  ·  " .. j.ket
        panelImport.search.PlaceholderText = "Cari file " .. kunci .. "..."
        panelImport.search.Text = ""
        panelImport.render()
        panelImport.frame.Visible = true
    elseif UPLOAD[kunci] then
        local u = UPLOAD[kunci]
        panelUpload.konteks = u
        panelUpload.judul.Text = u.judul .. "  ·  " .. u.ket
        panelUpload.search.PlaceholderText = "Cari file..."
        panelUpload.search.Text = ""
        panelUpload.render()
        panelUpload.frame.Visible = true
    elseif halaman[kunci] then
        halaman[kunci].Visible = true
    end
    sorotMenu(kunci)
    halamanAktif = kunci
    if gantiTab then jalankanSapuan() end
end

lakukanScan = function()
    scanSemua()
    perbaruiHitungan()
    if panelImport.frame.Visible then panelImport.render() end
    if panelUpload.frame.Visible then panelUpload.render() end
    local total = 0
    for _, e in ipairs(EXT_DICARI) do total = total + #fileTersedia[e] end
    if total == 0 then
        setStatus("SCAN selesai: tidak ada file yang cocok di folder Workspace", true)
    else
        setStatus("SCAN selesai: " .. total .. " file ditemukan")
    end
end

perbaruiTujuan()

------------------------------------------------------------------
local function initWindowEvents()
-- EVENT: TUTUP, KECILKAN, GESER
------------------------------------------------------------------
local koneksiGeser

local lamaToggle = parentGui:FindFirstChild("ImporterHubToggle")
if lamaToggle then lamaToggle:Destroy() end
local toggleGui = buat("ScreenGui", {
    Name = "ImporterHubToggle",
    ResetOnSpawn = false,
    Enabled = false,
}, parentGui)
local toggler = sudut(buat("ImageButton", {
    Name = "HubToggle",
    Size = UDim2.new(0, 64, 0, 64),
    Position = UDim2.new(0, 18, 0.5, -32),
    Image = TOGGLE_IMAGE,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Active = true,
}, toggleGui), 14)
toggler.Activated:Connect(function()
    toggleGui.Enabled = false
    gui.Enabled = true
    jalankanSapuan()
end)

btnTutup.Activated:Connect(function()
    tutupToolboxPanel()
    tutupMusicPanel()
    gui.Enabled = false
    if toggleGui then toggleGui.Enabled = true end
end)

local kecil = false
btnMin.Activated:Connect(function()
    if not kecil then
        tutupToolboxPanel()
        tutupMusicPanel()
    end
    kecil = not kecil
    body.Visible = not kecil
    frame.Size = UDim2.new(0, LEBAR, 0, kecil and 40 or TINGGI)
end)

local dragging, dragStart, startPos
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
koneksiGeser = UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y)
        posisikanPanelSamping(false)
    end
end)

------------------------------------------------------------------
end
initWindowEvents()

------------------------------------------------------------------
-- MULAI
------------------------------------------------------------------
lakukanScan()
bukaHalaman("dashboard")
perbaruiMetrikKinerja()

task.spawn(function()
    while gui.Parent do
        if gui.Enabled then perbaruiMetrikKinerja() end
        task.wait(0.5)
    end
end)
