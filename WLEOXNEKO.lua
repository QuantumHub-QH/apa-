--[[
============================================================
  WLEO x NEKO | ADD-ON GENERAL : AI CHAT • SPOOFER • UPLOADER
  CARA PASANG (cuma 1 tempat):
  Tempel seluruh isi file ini di script utama, tepat SETELAH
  fungsi `local function setTab(name) ... end` dan SEBELUM baris:
      for name, t in pairs(tabButtons) do
  Tidak ada bagian lain yang perlu diubah.
  Butuh: API KEY Open Cloud + akun terhubung di tab AKUN
  (dipakai Spoofer & Uploader).
============================================================
]]--
;(function()
    local WHITE = Color3.fromRGB(255, 255, 255)
    local DARK = Color3.fromRGB(10, 20, 50)
    local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request)
    local canFile = type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"

    local GEN = { names = { AI = true, SPOOF = true, UPLOAD = true }, pages = {} }

    -- ---------- tab di sidebar (kategori GENERAL, di bawah AKUN) ----------
    TAB_LABEL.AI = "AI CHAT"
    TAB_LABEL.SPOOF = "SPOOFER"
    TAB_LABEL.UPLOAD = "UPLOADER"
    makeTab("AI", 248)
    makeTab("SPOOF", 276)
    makeTab("UPLOAD", 304)
    for name in pairs(GEN.names) do
        local t = tabButtons[name]
        if t and t.badge then
            t.badge:Destroy()
            t.badge = nil
            t.lbl.Size = UDim2.new(1, -36, 1, 0)
        end
    end
    sideScroll.CanvasSize = UDim2.fromOffset(0, 340)

    -- ---------- sambungkan ke setTab ----------
    local baseSetTab = setTab
    setTab = function(name)
        baseSetTab(name)
        local isGen = GEN.names[name] == true
        for key, pg in pairs(GEN.pages) do pg.Visible = (key == name) end
        if isGen then
            searchBox.Visible = false
            list.Visible = false
            TB.list.Visible = false
            TB.chips.Visible = false
            TB.go.Visible = false
            emptyLbl.Visible = false
            contentTitle.Text = tabLabel(name) .. " • GENERAL"
            if DASH.mode == "panel" and hdrSub then hdrSub.Text = "PANEL • " .. tabLabel(name) end
        end
    end
    -- cegah label kosong milik daftar file muncul di atas halaman GENERAL
    emptyLbl:GetPropertyChangedSignal("Visible"):Connect(function()
        if GEN.names[currentTab] and emptyLbl.Visible then emptyLbl.Visible = false end
    end)

    -- ---------- helper UI ----------
    local function newPage(key)
        local f = Instance.new("Frame")
        f.Name = key .. "Page"
        f.BackgroundTransparency = 1
        f.Position = UDim2.fromOffset(6, 28)
        f.Size = UDim2.new(1, -12, 1, -34)
        f.ZIndex = 21
        f.Visible = false
        f.Parent = content
        GEN.pages[key] = f
        return f
    end
    local function makeBox(parent, pos, size, placeholder, multi)
        local tb = Instance.new("TextBox")
        tb.Position = pos
        tb.Size = size
        tb.BackgroundColor3 = WHITE
        tb.BackgroundTransparency = 0.82
        tb.Text = ""
        tb.PlaceholderText = placeholder
        tb.PlaceholderColor3 = C.muted
        tb.TextColor3 = C.text
        tb.TextSize = 11
        tb.Font = Enum.Font.GothamMedium
        tb.ClearTextOnFocus = false
        tb.TextXAlignment = Enum.TextXAlignment.Left
        tb.TextYAlignment = multi and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center
        tb.MultiLine = multi == true
        tb.TextWrapped = multi == true
        tb.ZIndex = 22
        tb.Parent = parent
        corner(tb, 9)
        glassStroke(tb, 1)
        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 8)
        pad.PaddingRight = UDim.new(0, 8)
        if multi then pad.PaddingTop = UDim.new(0, 6) end
        pad.Parent = tb
        return tb
    end
    local function makeBtn(parent, label, pos, size, color)
        local b = Instance.new("TextButton")
        b.Position = pos
        b.Size = size
        b.BackgroundColor3 = color
        b.BackgroundTransparency = 0.1
        b.BorderSizePixel = 0
        b.Text = label
        b.TextSize = 10
        b.Font = Enum.Font.GothamBold
        b.TextColor3 = DARK
        b.AutoButtonColor = false
        b.ZIndex = 23
        b.Parent = parent
        corner(b, 9)
        return b
    end
    local function makeOut(parent, pos, size, str)
        local l = text(parent, str, 10, Enum.Font.GothamMedium, C.soft)
        l.Position = pos
        l.Size = size
        l.TextWrapped = true
        l.TextYAlignment = Enum.TextYAlignment.Top
        l.ZIndex = 22
        return l
    end
    local function trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end
    local function jsonBody(res)
        if type(res) ~= "table" or type(res.Body) ~= "string" or #res.Body == 0 then return nil end
        local ok, d = pcall(function() return HttpService:JSONDecode(res.Body) end)
        return ok and d or nil
    end
    local function statusOk(res)
        return type(res) == "table" and (res.StatusCode == 200 or res.Status == 200)
    end

    -- =====================================================================
    --                              AI CHAT
    -- =====================================================================
    local AI_FILE = "WLEO_NEKO_AI.json"
    local AI = { key = nil, model = "meta-llama/llama-3.3-70b-instruct:free", history = {}, busy = false }
    do
        if canFile then
            local ok, t = pcall(function()
                if isfile(AI_FILE) then return HttpService:JSONDecode(readfile(AI_FILE)) end
            end)
            if ok and type(t) == "table" then
                if type(t.key) == "string" and t.key ~= "" then AI.key = t.key end
                if type(t.model) == "string" and t.model ~= "" then AI.model = t.model end
            end
        end
    end
    local function saveAI()
        if canFile then
            pcall(function() writefile(AI_FILE, HttpService:JSONEncode({ key = AI.key, model = AI.model })) end)
        end
    end

    local aiPage = newPage("AI")
    local chat = Instance.new("ScrollingFrame")
    chat.Position = UDim2.fromOffset(0, 0)
    chat.Size = UDim2.new(1, 0, 1, -34)
    chat.BackgroundTransparency = 1
    chat.BorderSizePixel = 0
    chat.ScrollBarThickness = 3
    chat.ScrollBarImageColor3 = C.accent
    chat.AutomaticCanvasSize = Enum.AutomaticSize.Y
    chat.CanvasSize = UDim2.new()
    chat.ZIndex = 21
    chat.Parent = aiPage
    do
        local l = Instance.new("UIListLayout")
        l.Padding = UDim.new(0, 6)
        l.SortOrder = Enum.SortOrder.LayoutOrder
        l.Parent = chat
    end
    local chatBox = makeBox(aiPage, UDim2.new(0, 0, 1, -28), UDim2.new(1, -58, 0, 28), "Tanya AI / buat script...", false)
    local sendBtn = makeBtn(aiPage, "KIRIM", UDim2.new(1, -52, 1, -28), UDim2.fromOffset(52, 28), C.accent)

    local msgOrder = 0
    local function addMsg(role, str)
        msgOrder += 1
        local card = Instance.new("Frame")
        card.LayoutOrder = msgOrder
        card.Size = UDim2.new(1, -6, 0, 0)
        card.AutomaticSize = Enum.AutomaticSize.Y
        card.BackgroundColor3 = WHITE
        card.BackgroundTransparency = (role == "user") and 0.8 or 0.9
        card.BorderSizePixel = 0
        card.ZIndex = 22
        card.Parent = chat
        corner(card, 10)
        glassStroke(card, 1)
        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 8); pad.PaddingRight = UDim.new(0, 8)
        pad.PaddingTop = UDim.new(0, 6); pad.PaddingBottom = UDim.new(0, 6)
        pad.Parent = card
        local lay = Instance.new("UIListLayout")
        lay.Padding = UDim.new(0, 4)
        lay.SortOrder = Enum.SortOrder.LayoutOrder
        lay.Parent = card

        local who = text(card, (role == "user") and LocalPlayer.DisplayName or "AI", 9, Enum.Font.GothamBold,
            (role == "user") and C.accent or C.ok)
        who.Size = UDim2.new(1, 0, 0, 12)
        who.LayoutOrder = 1
        who.ZIndex = 23
        local body = text(card, str, 11, Enum.Font.GothamMedium, C.text)
        body.Size = UDim2.new(1, 0, 0, 0)
        body.AutomaticSize = Enum.AutomaticSize.Y
        body.TextWrapped = true
        body.TextYAlignment = Enum.TextYAlignment.Top
        body.LayoutOrder = 2
        body.ZIndex = 23

        local code = str:match("```lua%s*(.-)%s*```") or str:match("```%s*(.-)%s*```")
        if code and code ~= "" then
            local cb = makeBtn(card, "SALIN SCRIPT", UDim2.new(), UDim2.new(1, 0, 0, 22), C.ok)
            cb.LayoutOrder = 3
            cb.MouseButton1Click:Connect(function()
                if copyText(code) then
                    setStatus("SCRIPT AI DISALIN", C.ok)
                    cb.Text = "TERSALIN"
                    task.delay(1.4, function() if cb.Parent then cb.Text = "SALIN SCRIPT" end end)
                else
                    setStatus("CLIPBOARD TIDAK TERSEDIA DI EXECUTOR", C.bad)
                end
            end)
        end
        task.delay(0.05, function()
            pcall(function() chat.CanvasPosition = Vector2.new(0, 1000000) end)
        end)
        return card
    end

    local AI_SYSTEM = "Kamu asisten scripting Luau untuk Roblox. Jawab ringkas dan jelas dalam bahasa pengguna. Kalau memberi script, bungkus dengan tiga backtick lua."
    local function askAI(prompt, cb)
        task.spawn(function()
            if not httpRequest then cb(false, "Fungsi request tidak ada di executor ini") return end
            local msgs = { { role = "system", content = AI_SYSTEM } }
            for _, m in ipairs(AI.history) do msgs[#msgs + 1] = m end
            msgs[#msgs + 1] = { role = "user", content = prompt }
            local ok, res = pcall(httpRequest, {
                Url = "https://openrouter.ai/api/v1/chat/completions",
                Method = "POST",
                Headers = {
                    ["Authorization"] = "Bearer " .. tostring(AI.key),
                    ["Content-Type"] = "application/json",
                    ["HTTP-Referer"] = "https://roblox.com",
                    ["X-Title"] = "WLEO x NEKO",
                },
                Body = HttpService:JSONEncode({ model = AI.model, messages = msgs, temperature = 0.7, max_tokens = 1500 }),
            })
            local d = ok and jsonBody(res) or nil
            if ok and statusOk(res) and d and d.choices and d.choices[1] and d.choices[1].message then
                cb(true, tostring(d.choices[1].message.content or ""))
                return
            end
            local err = "Gagal menghubungi server AI"
            if d and d.error and d.error.message then err = tostring(d.error.message) end
            cb(false, err)
        end)
    end

    local function sendChat()
        local prompt = trim(chatBox.Text)
        if prompt == "" or AI.busy then return end
        chatBox.Text = ""
        local newKey = prompt:match("^/key%s+(%S+)")
        if newKey then
            AI.key = newKey
            saveAI()
            addMsg("assistant", "API key OpenRouter tersimpan. Silakan mulai bertanya.")
            return
        end
        local newModel = prompt:match("^/model%s+(%S+)")
        if newModel then
            AI.model = newModel
            saveAI()
            addMsg("assistant", "Model diganti ke: " .. newModel)
            return
        end
        if prompt == "/clear" then
            AI.history = {}
            for _, c in ipairs(chat:GetChildren()) do
                if c:IsA("Frame") then c:Destroy() end
            end
            addMsg("assistant", "Riwayat chat dibersihkan.")
            return
        end
        if not AI.key then
            addMsg("assistant", "Belum ada API key. Buat key gratis di openrouter.ai lalu kirim:\n/key KEY_KAMU")
            return
        end
        addMsg("user", prompt)
        local pending = addMsg("assistant", "Mengetik...")
        AI.busy = true
        ind.busy = true
        askAI(prompt, function(success, reply)
            AI.busy = false
            ind.busy = false
            if pending then pending:Destroy() end
            if success then
                AI.history[#AI.history + 1] = { role = "user", content = prompt }
                AI.history[#AI.history + 1] = { role = "assistant", content = reply }
                while #AI.history > 12 do table.remove(AI.history, 1) end
                addMsg("assistant", reply)
            else
                addMsg("assistant", "Error: " .. tostring(reply))
            end
        end)
    end
    sendBtn.MouseButton1Click:Connect(sendChat)
    chatBox.FocusLost:Connect(function(enter) if enter then sendChat() end end)

    if AI.key then
        addMsg("assistant", "Halo " .. LocalPlayer.DisplayName .. ". Tanya apa saja soal script Roblox.\nPerintah: /clear, /model nama")
    else
        addMsg("assistant", "Halo " .. LocalPlayer.DisplayName .. ". Pasang API key OpenRouter dulu (gratis di openrouter.ai) dengan mengirim:\n/key KEY_KAMU")
    end

    -- =====================================================================
    --          UPLOAD AUDIO (dipakai Spoofer & Uploader)
    -- =====================================================================
    local function creatorInfo()
        local d = ACCT.data or {}
        if not ACCT.connected or type(d.apiKey) ~= "string" or d.apiKey == "" then
            return nil, "Buka tab AKUN, isi API KEY Open Cloud lalu KONEK dulu"
        end
        local gid = tonumber(d.groupId)
        if gid then return d.apiKey, { groupId = tostring(math.floor(gid)) } end
        return d.apiKey, { userId = tostring(math.floor(tonumber(d.userId) or 0)) }
    end

    local function buildMultipart(meta, fileName, mime, bytes)
        local boundary = "----WLEONEKO" .. tostring(math.random(100000000, 999999999))
        local crlf = "\r\n"
        local body = "--" .. boundary .. crlf
            .. 'Content-Disposition: form-data; name="request"' .. crlf
            .. "Content-Type: application/json" .. crlf .. crlf
            .. meta .. crlf
            .. "--" .. boundary .. crlf
            .. 'Content-Disposition: form-data; name="fileContent"; filename="' .. fileName .. '"' .. crlf
            .. "Content-Type: " .. mime .. crlf .. crlf
            .. bytes .. crlf
            .. "--" .. boundary .. "--" .. crlf
        return body, boundary
    end

    local function uploadAudio(bytes, baseName)
        if not httpRequest then return nil, "Fungsi request tidak tersedia" end
        local key, creator = creatorInfo()
        if not key then return nil, creator end
        if type(bytes) ~= "string" or #bytes < 80 then return nil, "Data audio kosong" end
        local ext, mime = "mp3", "audio/mpeg"
        if bytes:sub(1, 4) == "OggS" then ext, mime = "ogg", "audio/ogg" end
        local clean = tostring(baseName or "Audio"):gsub("[^%w%s%-_]", "")
        clean = clean:sub(1, 45)
        if clean == "" then clean = "Audio" end
        local meta = HttpService:JSONEncode({
            assetType = "Audio",
            displayName = clean,
            description = "Uploaded via WLEO x NEKO",
            creationContext = { creator = creator },
        })
        local body, boundary = buildMultipart(meta, clean .. "." .. ext, mime, bytes)
        local okP, res = pcall(httpRequest, {
            Url = "https://apis.roblox.com/assets/v1/assets",
            Method = "POST",
            Headers = { ["x-api-key"] = key, ["Content-Type"] = "multipart/form-data; boundary=" .. boundary },
            Body = body,
        })
        if not okP or not res then return nil, "Upload gagal terhubung" end
        local d = jsonBody(res)
        if not d or not d.path then
            local m = d and (d.message or d.error) or ("HTTP " .. tostring(res.StatusCode))
            return nil, "Ditolak: " .. tostring(m)
        end
        for _, delaySec in ipairs({ 0.4, 0.6, 0.8, 1, 1, 1.2, 1.5, 2, 2 }) do
            task.wait(delaySec)
            local okQ, r2 = pcall(httpRequest, {
                Url = "https://apis.roblox.com/assets/v1/" .. d.path,
                Method = "GET",
                Headers = { ["x-api-key"] = key },
            })
            local op = okQ and jsonBody(r2) or nil
            if op and op.done then
                if op.response and op.response.assetId then return tostring(op.response.assetId), clean end
                return nil, (op.error and op.error.message) or "Gagal diproses Roblox"
            end
        end
        return nil, "Timeout menunggu proses Roblox"
    end

    -- =====================================================================
    --                             SPOOFER
    -- =====================================================================
    local SEEDS = {
        119031818630096, 76077593225337, 131528987147518, 125981614068947, 112742012181598,
        6872265039, 5765186170, 3271915715, 4483381587, 7415484388,
    }
    local lastGoodPlace
    local spoofCache = {}

    local function assetName(aid)
        local name
        if httpRequest then
            local ok, res = pcall(httpRequest, {
                Url = "https://economy.roblox.com/v2/assets/" .. aid .. "/details",
                Method = "GET",
                Headers = { ["User-Agent"] = "Roblox/WinInet" },
            })
            if ok and statusOk(res) then
                local d = jsonBody(res)
                if d then name = d.Name or d.TargetName end
            end
        end
        local clean = name and tostring(name):gsub("[^%w%s%-_]", "") or ("Asset_" .. aid)
        clean = clean:sub(1, 35)
        if clean == "" then clean = "Asset_" .. aid end
        return clean
    end

    local function tryDownload(aid, placeId)
        local headers = { ["User-Agent"] = "Roblox/WinInet" }
        if placeId then headers["Roblox-Place-Id"] = tostring(placeId) end
        local ok, r = pcall(httpRequest, { Url = "https://assetdelivery.roblox.com/v2/assetId/" .. aid, Method = "GET", Headers = headers })
        if ok and statusOk(r) then
            local d = jsonBody(r)
            local loc = d and d.locations and d.locations[1] and d.locations[1].location
            if loc then
                local ok2, r2 = pcall(httpRequest, { Url = loc, Method = "GET", Headers = { ["User-Agent"] = "Roblox/WinInet" } })
                if ok2 and statusOk(r2) and type(r2.Body) == "string" and #r2.Body > 80 then return r2.Body end
            end
        end
        return nil
    end
    local function downloadAsset(aid)
        if game.PlaceId and game.PlaceId > 0 then
            local b = tryDownload(aid, game.PlaceId)
            if b then lastGoodPlace = game.PlaceId return b end
        end
        if lastGoodPlace and lastGoodPlace ~= game.PlaceId then
            local b = tryDownload(aid, lastGoodPlace)
            if b then return b end
        end
        local direct = tryDownload(aid, nil)
        if direct then return direct end
        for _, pid in ipairs(SEEDS) do
            local b = tryDownload(aid, pid)
            if b then lastGoodPlace = pid return b end
            task.wait(0.01)
        end
        return nil
    end

    local function spoofOne(aid)
        if spoofCache[aid] then return spoofCache[aid].id, spoofCache[aid].name end
        local key = creatorInfo()
        if not key then return nil, select(2, creatorInfo()) end
        local name = assetName(aid)
        local bytes = downloadAsset(aid)
        if not bytes then return nil, "Asset tidak bisa diunduh (private / rate limit)" end
        local newId, info = uploadAudio(bytes, name)
        if not newId then return nil, info end
        spoofCache[aid] = { id = newId, name = name }
        return newId, name
    end

    local sp = newPage("SPOOF")
    local spMode = "ID"
    local chipId = makeBtn(sp, "SATU ID", UDim2.fromOffset(0, 0), UDim2.fromOffset(78, 22), C.ok)
    local chipScr = makeBtn(sp, "ID DI SCRIPT", UDim2.fromOffset(84, 0), UDim2.fromOffset(96, 22), WHITE)
    local spBox = makeBox(sp, UDim2.fromOffset(0, 28), UDim2.new(1, 0, 0, 66), "Masukkan Audio Asset ID...", true)
    local spGo = makeBtn(sp, "SPOOF", UDim2.fromOffset(0, 100), UDim2.new(1, 0, 0, 28), C.accent)
    local spOut = makeOut(sp, UDim2.fromOffset(2, 134), UDim2.new(1, -4, 0, 70), "Audio di-download lalu di-upload ulang ke akunmu lewat Open Cloud. Isi API KEY & KONEK di tab AKUN dulu.")
    local spCopy = makeBtn(sp, "SALIN HASIL", UDim2.new(0, 0, 1, -26), UDim2.new(1, 0, 0, 26), C.ok)
    spCopy.AnchorPoint = Vector2.new(0, 0)
    local spLast = ""
    local spBusy = false

    local function setSpMode(m)
        spMode = m
        chipId.BackgroundColor3 = (m == "ID") and C.ok or WHITE
        chipScr.BackgroundColor3 = (m == "SCRIPT") and C.ok or WHITE
        spBox.PlaceholderText = (m == "ID") and "Masukkan Audio Asset ID..." or "Tempel script Lua, semua ID audio diganti..."
    end
    chipId.MouseButton1Click:Connect(function() setSpMode("ID") end)
    chipScr.MouseButton1Click:Connect(function() setSpMode("SCRIPT") end)

    spGo.MouseButton1Click:Connect(function()
        if spBusy then return end
        spBusy = true
        spGo.Text = "..."
        ind.busy = true
        task.spawn(function()
            if spMode == "ID" then
                local aid = spBox.Text:match("%d+")
                if not aid then
                    spOut.Text = "Masukkan ID audio yang valid."
                else
                    setStatus("SPOOF " .. aid .. "...", C.warn)
                    local newId, info = spoofOne(aid)
                    if newId then
                        spLast = newId
                        spOut.Text = "BERHASIL\nID baru: " .. newId .. "\n" .. tostring(info)
                        copyText(newId)
                        setStatus("SPOOF OK • ID BARU " .. newId, C.ok)
                        notify("WLEO x NEKO", "ID baru: " .. newId)
                    else
                        spOut.Text = "GAGAL: " .. tostring(info)
                        setStatus("SPOOF GAGAL", C.bad)
                    end
                end
            else
                local code = spBox.Text
                local ids, seen = {}, {}
                for id in code:gmatch("%d%d%d%d%d%d%d+") do
                    if not seen[id] then seen[id] = true; ids[#ids + 1] = id end
                end
                if #ids == 0 then
                    spOut.Text = "Tidak ada ID (7 digit ke atas) di script."
                elseif #ids > 40 then
                    spOut.Text = "Terlalu banyak ID (" .. #ids .. "). Maksimal 40 sekali proses."
                else
                    local map, okN, lastErr = {}, 0, nil
                    for i, id in ipairs(ids) do
                        setProgress((i - 1) / #ids, ("SPOOF %d / %d"):format(i, #ids))
                        local newId, info = spoofOne(id)
                        if newId then map[id] = newId; okN += 1 else lastErr = info end
                    end
                    local replaced = (code:gsub("%d%d%d%d%d%d%d+", function(id) return map[id] or id end))
                    spLast = replaced
                    copyText(replaced)
                    setProgress(1, "SPOOF SCRIPT SELESAI")
                    spOut.Text = ("%d dari %d ID berhasil diganti. Script sudah disalin."):format(okN, #ids)
                        .. (lastErr and ("\nError terakhir: " .. tostring(lastErr)) or "")
                end
            end
            ind.busy = false
            spGo.Text = "SPOOF"
            spBusy = false
        end)
    end)
    spCopy.MouseButton1Click:Connect(function()
        if spLast == "" then setStatus("BELUM ADA HASIL", C.warn) return end
        if copyText(spLast) then setStatus("HASIL DISALIN", C.ok) else setStatus("CLIPBOARD TIDAK TERSEDIA DI EXECUTOR", C.bad) end
    end)

    -- =====================================================================
    --                             UPLOADER
    -- =====================================================================
    local up = newPage("UPLOAD")
    local upSrc = makeBox(up, UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 28), "Nama file di workspace atau link langsung .mp3/.ogg", false)
    local upName = makeBox(up, UDim2.fromOffset(0, 32), UDim2.new(1, 0, 0, 28), "Nama audio (opsional)", false)
    local upGo = makeBtn(up, "UPLOAD", UDim2.fromOffset(0, 64), UDim2.new(0.5, -3, 0, 26), C.accent)
    local upScan = makeBtn(up, "SCAN AUDIO", UDim2.new(0.5, 3, 0, 64), UDim2.new(0.5, -3, 0, 26), WHITE)
    local upList = Instance.new("ScrollingFrame")
    upList.Position = UDim2.fromOffset(0, 96)
    upList.Size = UDim2.new(1, 0, 0, 68)
    upList.BackgroundTransparency = 1
    upList.BorderSizePixel = 0
    upList.ScrollBarThickness = 3
    upList.ScrollBarImageColor3 = C.accent
    upList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    upList.CanvasSize = UDim2.new()
    upList.ZIndex = 21
    upList.Parent = up
    do
        local l = Instance.new("UIListLayout")
        l.Padding = UDim.new(0, 3)
        l.SortOrder = Enum.SortOrder.LayoutOrder
        l.Parent = upList
    end
    local upOut = makeOut(up, UDim2.fromOffset(2, 168), UDim2.new(1, -4, 0, 34), "Link YouTube tidak bisa dikonversi langsung. Pakai file mp3/ogg atau link langsung ke file audio.")
    local upCopy = makeBtn(up, "SALIN ID", UDim2.new(0, 0, 1, -26), UDim2.new(1, 0, 0, 26), C.ok)
    local upLast = ""
    local upBusy = false

    local function scanAudio()
        local out, seenFiles, seenFolders = {}, {}, {}
        local function walk(folder, depth)
            if depth > 3 then return end
            local fk = canonicalWorkspacePath(folder)
            if fk == "" then fk = "__root__" end
            if seenFolders[fk] then return end
            seenFolders[fk] = true
            local files = safeListFiles(folder)
            if not files then return end
            for _, path in ipairs(files) do
                local nm = getFileName(path)
                local low = nm:lower()
                if low:match("%.mp3$") or low:match("%.ogg$") then
                    local key = canonicalWorkspacePath(path)
                    if not seenFiles[key] then
                        seenFiles[key] = true
                        out[#out + 1] = { name = nm, path = path }
                    end
                elseif looksFolder(path) then
                    walk(path, depth + 1)
                end
            end
        end
        for _, p in ipairs(SCAN_PATHS) do
            if safeListFiles(p) then walk(p, 0) end
        end
        table.sort(out, function(a, b) return a.name:lower() < b.name:lower() end)
        return out
    end

    local function renderAudio(files)
        for _, c in ipairs(upList:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for i, f in ipairs(files) do
            local b = Instance.new("TextButton")
            b.LayoutOrder = i
            b.Size = UDim2.new(1, -4, 0, 22)
            b.BackgroundColor3 = WHITE
            b.BackgroundTransparency = 0.86
            b.BorderSizePixel = 0
            b.Text = f.name
            b.TextSize = 10
            b.Font = Enum.Font.GothamMedium
            b.TextColor3 = C.text
            b.TextXAlignment = Enum.TextXAlignment.Left
            b.TextTruncate = Enum.TextTruncate.AtEnd
            b.AutoButtonColor = false
            b.ZIndex = 22
            b.Parent = upList
            corner(b, 7)
            local pad = Instance.new("UIPadding")
            pad.PaddingLeft = UDim.new(0, 8); pad.PaddingRight = UDim.new(0, 8)
            pad.Parent = b
            b.MouseButton1Click:Connect(function()
                upSrc.Text = f.path
                if trim(upName.Text) == "" then upName.Text = (f.name:gsub("%.[%w]+$", "")) end
            end)
        end
    end

    upScan.MouseButton1Click:Connect(function()
        upScan.Text = "..."
        task.spawn(function()
            local ok, files = pcall(scanAudio)
            if ok then
                renderAudio(files)
                upOut.Text = #files .. " file audio ditemukan. Tap salah satu untuk memilih."
            else
                upOut.Text = "Scan gagal: " .. tostring(files)
            end
            upScan.Text = "SCAN AUDIO"
        end)
    end)

    local function fetchBytes(src)
        if src:match("^https?://") then
            if not httpRequest then return nil, "Fungsi request tidak tersedia" end
            local ok, res = pcall(httpRequest, { Url = src, Method = "GET" })
            if ok and statusOk(res) and type(res.Body) == "string" and #res.Body > 0 then return res.Body end
            return nil, "Gagal mengunduh link"
        end
        if type(readfile) ~= "function" then return nil, "readfile tidak tersedia" end
        local ok, data = pcall(readfile, src)
        if ok and type(data) == "string" and #data > 0 then return data end
        return nil, "File tidak terbaca: " .. src
    end

    upGo.MouseButton1Click:Connect(function()
        if upBusy then return end
        local src = trim(upSrc.Text)
        if src == "" then upOut.Text = "Isi sumber audio dulu." return end
        if src:lower():find("youtu") then
            upOut.Text = "Link YouTube tidak bisa dikonversi di sini. Pakai file mp3/ogg atau link langsung ke file audio."
            return
        end
        upBusy = true
        upGo.Text = "..."
        ind.busy = true
        task.spawn(function()
            setProgress(0.1, "UPLOADER • MEMBACA AUDIO")
            local bytes, err = fetchBytes(src)
            if not bytes then
                upOut.Text = "GAGAL: " .. tostring(err)
                setStatus("UPLOADER GAGAL", C.bad)
            else
                local isOgg = bytes:sub(1, 4) == "OggS"
                local isMp3 = bytes:sub(1, 3) == "ID3" or bytes:byte(1) == 0xFF
                if not (isOgg or isMp3) then
                    upOut.Text = "GAGAL: format harus mp3 atau ogg."
                    setStatus("UPLOADER GAGAL", C.bad)
                else
                    local nm = trim(upName.Text)
                    if nm == "" then nm = (getFileName(src):gsub("%.[%w]+$", "")) end
                    setProgress(0.4, "UPLOADER • MENGUNGGAH")
                    local newId, info = uploadAudio(bytes, nm)
                    if newId then
                        upLast = newId
                        copyText(newId)
                        setProgress(1, "UPLOAD OK • ID " .. newId)
                        upOut.Text = "BERHASIL\nID: " .. newId .. " (" .. tostring(info) .. ")"
                        notify("WLEO x NEKO", "Audio terunggah. ID: " .. newId)
                    else
                        upOut.Text = "GAGAL: " .. tostring(info)
                        setStatus("UPLOADER GAGAL", C.bad)
                    end
                end
            end
            ind.busy = false
            upGo.Text = "UPLOAD"
            upBusy = false
        end)
    end)
    upCopy.MouseButton1Click:Connect(function()
        if upLast == "" then setStatus("BELUM ADA ID", C.warn) return end
        if copyText(upLast) then setStatus("ID DISALIN", C.ok) else setStatus("CLIPBOARD TIDAK TERSEDIA DI EXECUTOR", C.bad) end
    end)
end)()
