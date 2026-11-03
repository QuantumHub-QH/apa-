-- ============================================================
--  MOVEMENT RECORDER v1.0  |  by MCHLERN ENGINE
--  Standalone Delta Executor Script
--  Record gerakan, simpan banyak slot, play ulang kapan pun
-- ============================================================

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LP   = Players.LocalPlayer
local Mouse = LP:GetMouse()

-- Wait for character
local function getChar()
    local c = LP.Character
    if not c then c = LP.CharacterAdded:Wait() end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    local hum = c:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then
        c = LP.CharacterAdded:Wait()
        hrp = c:WaitForChild("HumanoidRootPart")
        hum = c:WaitForChild("Humanoid")
    end
    return c, hrp, hum
end

local Char, HRP, Hum = getChar()
LP.CharacterAdded:Connect(function(c)
    Char = c
    HRP  = c:WaitForChild("HumanoidRootPart")
    Hum  = c:WaitForChild("Humanoid")
end)

-- ============================================================
--  CONSTANTS
-- ============================================================
local RECORD_FPS      = 20
local RECORD_INTERVAL = 1 / RECORD_FPS
local INDEX_FILE      = "mvrec_index.dat"
local FILE_PREFIX     = "mvrec_"
local FILE_EXT        = ".dat"

-- ============================================================
--  STATE
-- ============================================================
local isRecording   = false
local isPlaying     = false
local recFrames     = {}
local recTimer      = 0
local playSpeed     = 1
local recConn       = nil
local playConn      = nil
local loadedRec     = nil   -- currently loaded recording for playback
local savedSlots    = {}    -- list of slot name strings
local selectedSlot  = nil   -- currently selected slot name in UI

-- ============================================================
--  FILE UTILITIES
-- ============================================================
local function sanitize(name)
    return (name:gsub("[^%w%-_]", "_"):sub(1, 28))
end

local function fname(name)
    return FILE_PREFIX .. sanitize(name) .. FILE_EXT
end

local function fileExists(path)
    local ok, _ = pcall(readfile, path)
    return ok
end

local function loadIndex()
    savedSlots = {}
    local ok, content = pcall(readfile, INDEX_FILE)
    if not ok or not content or content == "" then return end
    for line in content:gmatch("[^\n\r]+") do
        if line ~= "" then table.insert(savedSlots, line) end
    end
end

local function saveIndex()
    pcall(writefile, INDEX_FILE, table.concat(savedSlots, "\n"))
end

local function addToIndex(name)
    for _, v in ipairs(savedSlots) do
        if v == name then return end  -- already exists
    end
    table.insert(savedSlots, name)
    saveIndex()
end

local function removeFromIndex(name)
    for i, v in ipairs(savedSlots) do
        if v == name then
            table.remove(savedSlots, i)
            break
        end
    end
    saveIndex()
end

-- ============================================================
--  RECORDING ENCODE / DECODE
-- ============================================================
-- Frame format: px,py,pz,rx,ry,rz,ux,uy,uz  (9 floats)
-- Header: MVREC_V1|name|fps|framecount

local function encodeRecording(name, frames)
    local lines = {
        "MVREC_V1|" .. name .. "|" .. RECORD_FPS .. "|" .. #frames
    }
    for _, f in ipairs(frames) do
        lines[#lines + 1] = string.format(
            "%.3f,%.3f,%.3f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f",
            f[1],f[2],f[3],f[4],f[5],f[6],f[7],f[8],f[9]
        )
    end
    return table.concat(lines, "\n")
end

local function decodeRecording(content)
    if not content or content == "" then return nil end
    local lines = {}
    for line in content:gmatch("[^\n\r]+") do table.insert(lines, line) end
    if #lines < 2 then return nil end

    local ver, recName, fps, fcount = lines[1]:match("([^|]+)|([^|]+)|([^|]+)|([^|]+)")
    if ver ~= "MVREC_V1" then return nil end

    local rec = { name = recName, fps = tonumber(fps) or 20, frames = {} }
    for i = 2, #lines do
        local vals = {}
        for v in lines[i]:gmatch("[^,]+") do table.insert(vals, tonumber(v) or 0) end
        if #vals >= 9 then table.insert(rec.frames, vals) end
    end
    return rec
end

local function frameToCFrame(f)
    local pos   = Vector3.new(f[1], f[2], f[3])
    local right = Vector3.new(f[4], f[5], f[6])
    local up    = Vector3.new(f[7], f[8], f[9])
    return CFrame.fromMatrix(pos, right, up)
end

-- ============================================================
--  RECORD / PLAY LOGIC
-- ============================================================
local function startRecording()
    if isPlaying then return false end
    isRecording = true
    recFrames   = {}
    recTimer    = 0
    recConn = RunService.Heartbeat:Connect(function(dt)
        if not isRecording then return end
        recTimer = recTimer + dt
        if recTimer >= RECORD_INTERVAL then
            recTimer = recTimer - RECORD_INTERVAL
            if HRP and HRP.Parent then
                local cf = HRP.CFrame
                local p  = cf.Position
                local rv = cf.RightVector
                local uv = cf.UpVector
                table.insert(recFrames, {
                    p.X, p.Y, p.Z,
                    rv.X, rv.Y, rv.Z,
                    uv.X, uv.Y, uv.Z
                })
            end
        end
    end)
    return true
end

local function stopRecording()
    isRecording = false
    if recConn then recConn:Disconnect(); recConn = nil end
end

local function saveSlot(name)
    if #recFrames == 0 then return false, "Tidak ada rekaman!" end
    if name == "" then return false, "Nama tidak boleh kosong!" end
    local data = encodeRecording(name, recFrames)
    local ok, err = pcall(writefile, fname(name), data)
    if not ok then return false, "Gagal tulis file: " .. tostring(err) end
    addToIndex(name)
    return true, "Tersimpan: " .. name .. " (" .. #recFrames .. " frames)"
end

local function loadSlot(name)
    local ok, content = pcall(readfile, fname(name))
    if not ok or not content then return nil, "File tidak ditemukan!" end
    local rec = decodeRecording(content)
    if not rec then return nil, "Data rusak!" end
    return rec, "Loaded: " .. name .. " | " .. #rec.frames .. " frames | " ..
        string.format("%.1fs", #rec.frames / rec.fps)
end

local function deleteSlot(name)
    pcall(delfile, fname(name))
    removeFromIndex(name)
end

local function playRecording(rec, onDone)
    if isRecording or isPlaying then return false end
    if not rec or #rec.frames == 0 then return false end
    isPlaying = true
    loadedRec = rec

    -- Teleport to start position
    if HRP and HRP.Parent then
        HRP.CFrame = frameToCFrame(rec.frames[1])
    end

    local idx      = 1
    local ftimer   = 0
    local interval = 1 / (rec.fps * playSpeed)

    playConn = RunService.Heartbeat:Connect(function(dt)
        if not isPlaying then return end
        ftimer = ftimer + dt
        while ftimer >= interval do
            ftimer = ftimer - interval
            idx = idx + 1
            if idx > #rec.frames then
                isPlaying = false
                if playConn then playConn:Disconnect(); playConn = nil end
                if onDone then onDone() end
                return
            end
            if HRP and HRP.Parent then
                HRP.CFrame = frameToCFrame(rec.frames[idx])
            end
        end
    end)
    return true
end

local function stopPlayback()
    isPlaying = false
    if playConn then playConn:Disconnect(); playConn = nil end
end

-- ============================================================
--  GUI BUILDER HELPERS
-- ============================================================
local function makeInst(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    return inst
end

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
end

local function stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(255,255,255)
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.8
    s.Parent = parent
end

local function makeLbl(parent, text, size, pos, textSize, color, bold, align)
    local lbl = makeInst("TextLabel", {
        Size = size,
        Position = pos or UDim2.new(0,0,0,0),
        BackgroundTransparency = 1,
        Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextSize = textSize or 11,
        TextColor3 = color or Color3.fromRGB(220,220,230),
        TextXAlignment = align or Enum.TextXAlignment.Left,
        Text = text,
        Parent = parent,
    })
    return lbl
end

local function makeBtn(parent, text, size, pos, bgColor, textColor, textSize)
    local btn = makeInst("TextButton", {
        Size = size,
        Position = pos or UDim2.new(0,0,0,0),
        BackgroundColor3 = bgColor or Color3.fromRGB(50,50,60),
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        TextSize = textSize or 11,
        TextColor3 = textColor or Color3.fromRGB(255,255,255),
        Text = text,
        AutoButtonColor = false,
        Parent = parent,
    })
    corner(btn, 6)
    return btn
end

local function makeTBox(parent, placeholder, size, pos)
    local box = makeInst("TextBox", {
        Size = size,
        Position = pos or UDim2.new(0,0,0,0),
        BackgroundColor3 = Color3.fromRGB(25,25,32),
        BorderSizePixel = 0,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = Color3.fromRGB(220,220,235),
        PlaceholderText = placeholder,
        PlaceholderColor3 = Color3.fromRGB(100,100,115),
        Text = "",
        ClearTextOnFocus = false,
        Parent = parent,
    })
    corner(box, 6)
    stroke(box, Color3.fromRGB(255,255,255), 1, 0.85)
    return box
end

-- ============================================================
--  BUILD GUI
-- ============================================================
loadIndex()

-- Remove old GUI if exists
local oldGui = LP.PlayerGui:FindFirstChild("MovRecGUI")
if oldGui then oldGui:Destroy() end

local ScreenGui = makeInst("ScreenGui", {
    Name = "MovRecGUI",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = LP.PlayerGui,
})

-- Main Window
local Window = makeInst("Frame", {
    Name = "Window",
    Size = UDim2.new(0, 320, 0, 480),
    Position = UDim2.new(0.5, -160, 0.5, -240),
    BackgroundColor3 = Color3.fromRGB(12, 12, 18),
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Parent = ScreenGui,
})
corner(Window, 10)
stroke(Window, Color3.fromRGB(255,255,255), 1, 0.88)

-- Title Bar
local TitleBar = makeInst("Frame", {
    Size = UDim2.new(1, 0, 0, 36),
    BackgroundColor3 = Color3.fromRGB(18, 18, 26),
    BorderSizePixel = 0,
    Parent = Window,
})
corner(TitleBar, 10)

local TitleLbl = makeLbl(TitleBar, "MOVEMENT RECORDER v1.0",
    UDim2.new(1,-50,1,0), UDim2.new(0,12,0,0), 12,
    Color3.fromRGB(255,255,255), true, Enum.TextXAlignment.Left)

local CloseBtn = makeBtn(TitleBar, "X",
    UDim2.new(0,28,0,28), UDim2.new(1,-34,0,4),
    Color3.fromRGB(200,50,50), Color3.fromRGB(255,255,255), 12)

-- Content Frame (below title)
local Content = makeInst("Frame", {
    Size = UDim2.new(1, -12, 1, -44),
    Position = UDim2.new(0, 6, 0, 40),
    BackgroundTransparency = 1,
    Parent = Window,
})

-- ---- SECTION 1: STATUS ----
local StatusBox = makeInst("Frame", {
    Size = UDim2.new(1, 0, 0, 50),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = Color3.fromRGB(18, 18, 26),
    BorderSizePixel = 0,
    Parent = Content,
})
corner(StatusBox, 8)

local StatusLbl = makeLbl(StatusBox, "Status: Siap",
    UDim2.new(1,-12,0,18), UDim2.new(0,8,0,4),
    11, Color3.fromRGB(120,220,120), false, Enum.TextXAlignment.Left)

local FramesLbl = makeLbl(StatusBox, "Frames: 0  |  Durasi: 0.0s",
    UDim2.new(1,-12,0,16), UDim2.new(0,8,0,24),
    10, Color3.fromRGB(150,150,165), false, Enum.TextXAlignment.Left)

-- ---- SECTION 2: CONTROLS ----
local CtrlBox = makeInst("Frame", {
    Size = UDim2.new(1, 0, 0, 80),
    Position = UDim2.new(0, 0, 0, 56),
    BackgroundColor3 = Color3.fromRGB(18, 18, 26),
    BorderSizePixel = 0,
    Parent = Content,
})
corner(CtrlBox, 8)

makeLbl(CtrlBox, "KONTROL REKAMAN",
    UDim2.new(1,-12,0,14), UDim2.new(0,8,0,4),
    9, Color3.fromRGB(100,100,120), true)

-- Row 1: REC | STOP REC | PLAY | STOP PLAY
local RecBtn = makeBtn(CtrlBox, "● REC",
    UDim2.new(0, 68, 0, 26), UDim2.new(0, 4, 0, 20),
    Color3.fromRGB(200, 40, 40), Color3.fromRGB(255,255,255), 10)

local StopRecBtn = makeBtn(CtrlBox, "■ STOP REC",
    UDim2.new(0, 82, 0, 26), UDim2.new(0, 76, 0, 20),
    Color3.fromRGB(60, 60, 75), Color3.fromRGB(200,200,210), 10)

local PlayBtn = makeBtn(CtrlBox, "▶ PLAY",
    UDim2.new(0, 68, 0, 26), UDim2.new(0, 162, 0, 20),
    Color3.fromRGB(30, 140, 80), Color3.fromRGB(255,255,255), 10)

local StopPlayBtn = makeBtn(CtrlBox, "■ STOP",
    UDim2.new(0, 54, 0, 26), UDim2.new(0, 234, 0, 20),
    Color3.fromRGB(60, 60, 75), Color3.fromRGB(200,200,210), 10)

-- Row 2: Speed
makeLbl(CtrlBox, "Speed:",
    UDim2.new(0, 40, 0, 14), UDim2.new(0, 8, 0, 52),
    10, Color3.fromRGB(140,140,160), false)

local Sp05Btn = makeBtn(CtrlBox, "0.5x",
    UDim2.new(0, 44, 0, 20), UDim2.new(0, 52, 0, 50),
    Color3.fromRGB(40, 40, 55), Color3.fromRGB(200,200,215), 10)

local Sp1Btn  = makeBtn(CtrlBox, "1x",
    UDim2.new(0, 36, 0, 20), UDim2.new(0, 100, 0, 50),
    Color3.fromRGB(255, 200, 50), Color3.fromRGB(20,20,20), 10)  -- active default

local Sp2Btn  = makeBtn(CtrlBox, "2x",
    UDim2.new(0, 36, 0, 20), UDim2.new(0, 140, 0, 50),
    Color3.fromRGB(40, 40, 55), Color3.fromRGB(200,200,215), 10)

local Sp3Btn  = makeBtn(CtrlBox, "3x",
    UDim2.new(0, 36, 0, 20), UDim2.new(0, 180, 0, 50),
    Color3.fromRGB(40, 40, 55), Color3.fromRGB(200,200,215), 10)

-- ---- SECTION 3: SAVE ----
local SaveBox = makeInst("Frame", {
    Size = UDim2.new(1, 0, 0, 48),
    Position = UDim2.new(0, 0, 0, 142),
    BackgroundColor3 = Color3.fromRGB(18, 18, 26),
    BorderSizePixel = 0,
    Parent = Content,
})
corner(SaveBox, 8)

makeLbl(SaveBox, "SIMPAN REKAMAN",
    UDim2.new(1,-12,0,14), UDim2.new(0,8,0,4),
    9, Color3.fromRGB(100,100,120), true)

local NameBox = makeTBox(SaveBox, "Nama rekaman...",
    UDim2.new(1,-76,0,24), UDim2.new(0,4,0,20))

local SaveBtn = makeBtn(SaveBox, "SIMPAN",
    UDim2.new(0, 66, 0, 24), UDim2.new(1, -70, 0, 20),
    Color3.fromRGB(50, 120, 200), Color3.fromRGB(255,255,255), 10)

-- ---- SECTION 4: SLOTS LIST ----
local SlotsHeader = makeInst("Frame", {
    Size = UDim2.new(1, 0, 0, 20),
    Position = UDim2.new(0, 0, 0, 196),
    BackgroundTransparency = 1,
    Parent = Content,
})
makeLbl(SlotsHeader, "SLOT TERSIMPAN",
    UDim2.new(1,0,1,0), UDim2.new(0,0,0,0),
    9, Color3.fromRGB(100,100,120), true)

local SlotScroll = makeInst("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, -222),
    Position = UDim2.new(0, 0, 0, 218),
    BackgroundColor3 = Color3.fromRGB(14, 14, 20),
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = Color3.fromRGB(255,255,255),
    CanvasSize = UDim2.new(0,0,0,0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    Parent = Content,
})
corner(SlotScroll, 8)

local SlotLayout = Instance.new("UIListLayout")
SlotLayout.SortOrder = Enum.SortOrder.LayoutOrder
SlotLayout.Padding = UDim.new(0, 3)
SlotLayout.Parent = SlotScroll

local SlotPad = Instance.new("UIPadding")
SlotPad.PaddingTop = UDim.new(0, 4)
SlotPad.PaddingLeft = UDim.new(0, 4)
SlotPad.PaddingRight = UDim.new(0, 4)
SlotPad.Parent = SlotScroll

-- ============================================================
--  SLOT UI MANAGEMENT
-- ============================================================
local slotFrames = {}  -- name -> Frame

local function updateStatus(text, color)
    StatusLbl.Text = "Status: " .. text
    StatusLbl.TextColor3 = color or Color3.fromRGB(120,220,120)
end

local function updateFrameCount()
    local n = #recFrames
    local dur = n / RECORD_FPS
    FramesLbl.Text = string.format("Frames: %d  |  Durasi: %.1fs", n, dur)
end

local function setSpeedUI(speed)
    playSpeed = speed
    local map = {[0.5]=Sp05Btn, [1]=Sp1Btn, [2]=Sp2Btn, [3]=Sp3Btn}
    for spd, btn in pairs(map) do
        if spd == speed then
            btn.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
            btn.TextColor3 = Color3.fromRGB(20,20,20)
        else
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
            btn.TextColor3 = Color3.fromRGB(200,200,215)
        end
    end
end

local function buildSlotRow(name, order)
    -- Remove existing if any
    if slotFrames[name] then slotFrames[name]:Destroy() end

    local row = makeInst("Frame", {
        Name = "slot_" .. name,
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = Color3.fromRGB(22, 22, 30),
        BorderSizePixel = 0,
        LayoutOrder = order or 0,
        Parent = SlotScroll,
    })
    corner(row, 6)

    -- Highlight if selected
    local isSelected = (selectedSlot == name)
    if isSelected then
        stroke(row, Color3.fromRGB(255,200,50), 1.5, 0)
    else
        stroke(row, Color3.fromRGB(255,255,255), 1, 0.9)
    end

    -- Name label
    makeLbl(row, name,
        UDim2.new(1,-152,1,0), UDim2.new(0,8,0,0),
        11, isSelected and Color3.fromRGB(255,200,50) or Color3.fromRGB(210,210,225),
        isSelected)

    -- Buttons: LOAD | PLAY | DEL
    local LoadBtn = makeBtn(row, "LOAD",
        UDim2.new(0, 42, 0, 22), UDim2.new(1,-150,0,6),
        Color3.fromRGB(50,100,180), Color3.fromRGB(255,255,255), 9)

    local PlaySlotBtn = makeBtn(row, "PLAY",
        UDim2.new(0, 42, 0, 22), UDim2.new(1,-104,0,6),
        Color3.fromRGB(30,130,70), Color3.fromRGB(255,255,255), 9)

    local DelBtn = makeBtn(row, "DEL",
        UDim2.new(0, 36, 0, 22), UDim2.new(1,-58,0,6),
        Color3.fromRGB(150,30,30), Color3.fromRGB(255,255,255), 9)

    -- Load action
    LoadBtn.Activated:Connect(function()
        local rec, msg = loadSlot(name)
        if rec then
            loadedRec = rec
            recFrames = rec.frames
            selectedSlot = name
            updateStatus("Loaded: " .. name, Color3.fromRGB(100,180,255))
            FramesLbl.Text = string.format("Frames: %d  |  Durasi: %.1fs",
                #rec.frames, #rec.frames / rec.fps)
            -- Rebuild all rows to update highlight
            for _, sname in ipairs(savedSlots) do
                if slotFrames[sname] then
                    buildSlotRow(sname, _)
                end
            end
        else
            updateStatus(msg, Color3.fromRGB(255,80,80))
        end
    end)

    -- Play action (load + play immediately)
    PlaySlotBtn.Activated:Connect(function()
        if isRecording then
            updateStatus("Stop record dulu!", Color3.fromRGB(255,80,80)); return
        end
        local rec, msg = loadSlot(name)
        if not rec then
            updateStatus(msg, Color3.fromRGB(255,80,80)); return
        end
        loadedRec = rec
        selectedSlot = name
        local ok = playRecording(rec, function()
            updateStatus("Selesai: " .. name, Color3.fromRGB(120,220,120))
        end)
        if ok then
            updateStatus("Playing: " .. name, Color3.fromRGB(255,200,50))
        else
            updateStatus("Gagal play!", Color3.fromRGB(255,80,80))
        end
    end)

    -- Delete action
    DelBtn.Activated:Connect(function()
        deleteSlot(name)
        if slotFrames[name] then
            slotFrames[name]:Destroy()
            slotFrames[name] = nil
        end
        if selectedSlot == name then
            selectedSlot = nil
            loadedRec = nil
        end
        updateStatus("Dihapus: " .. name, Color3.fromRGB(255,150,50))
    end)

    slotFrames[name] = row
    return row
end

local function rebuildSlotList()
    -- Clear existing
    for _, f in pairs(slotFrames) do f:Destroy() end
    slotFrames = {}
    -- Rebuild
    for i, name in ipairs(savedSlots) do
        buildSlotRow(name, i)
    end
end

-- Initial build
rebuildSlotList()

-- ============================================================
--  BUTTON LOGIC
-- ============================================================

-- REC
RecBtn.Activated:Connect(function()
    if isPlaying then
        updateStatus("Stop play dulu!", Color3.fromRGB(255,80,80)); return
    end
    if isRecording then
        updateStatus("Sudah recording!", Color3.fromRGB(255,200,50)); return
    end
    startRecording()
    updateStatus("RECORDING...", Color3.fromRGB(255,80,80))
    RecBtn.BackgroundColor3 = Color3.fromRGB(255,50,50)
end)

-- STOP REC
StopRecBtn.Activated:Connect(function()
    if not isRecording then return end
    stopRecording()
    updateFrameCount()
    updateStatus(string.format("Selesai record: %d frames (%.1fs)",
        #recFrames, #recFrames / RECORD_FPS), Color3.fromRGB(120,220,120))
    RecBtn.BackgroundColor3 = Color3.fromRGB(200,40,40)
end)

-- PLAY
PlayBtn.Activated:Connect(function()
    if isRecording then
        updateStatus("Stop record dulu!", Color3.fromRGB(255,80,80)); return
    end
    if isPlaying then
        updateStatus("Sudah playing!", Color3.fromRGB(255,200,50)); return
    end
    -- Use loadedRec jika ada, else gunakan recFrames
    local recToPlay = loadedRec
    if not recToPlay and #recFrames > 0 then
        recToPlay = { frames = recFrames, fps = RECORD_FPS, name = "Current" }
    end
    if not recToPlay or #recToPlay.frames == 0 then
        updateStatus("Tidak ada rekaman! Record atau Load dulu.", Color3.fromRGB(255,80,80)); return
    end
    local ok = playRecording(recToPlay, function()
        updateStatus("Selesai playback!", Color3.fromRGB(120,220,120))
    end)
    if ok then
        updateStatus("Playing... " .. recToPlay.name, Color3.fromRGB(255,200,50))
    end
end)

-- STOP PLAY
StopPlayBtn.Activated:Connect(function()
    stopPlayback()
    updateStatus("Playback dihentikan", Color3.fromRGB(200,200,210))
end)

-- SAVE
SaveBtn.Activated:Connect(function()
    local name = NameBox.Text:match("^%s*(.-)%s*$")  -- trim
    if name == "" then
        updateStatus("Masukkan nama rekaman!", Color3.fromRGB(255,80,80)); return
    end
    if #recFrames == 0 then
        updateStatus("Belum ada rekaman!", Color3.fromRGB(255,80,80)); return
    end
    local ok, msg = saveSlot(name)
    if ok then
        updateStatus(msg, Color3.fromRGB(120,220,120))
        NameBox.Text = ""
        buildSlotRow(name, #savedSlots)  -- add to UI
    else
        updateStatus(msg, Color3.fromRGB(255,80,80))
    end
end)

-- SPEED BUTTONS
Sp05Btn.Activated:Connect(function() setSpeedUI(0.5) end)
Sp1Btn.Activated:Connect(function()  setSpeedUI(1)   end)
Sp2Btn.Activated:Connect(function()  setSpeedUI(2)   end)
Sp3Btn.Activated:Connect(function()  setSpeedUI(3)   end)

-- CLOSE
CloseBtn.Activated:Connect(function()
    stopRecording()
    stopPlayback()
    ScreenGui:Destroy()
end)

-- ============================================================
--  LIVE UPDATE (recording status ticker)
-- ============================================================
local tickConn = RunService.Heartbeat:Connect(function()
    if isRecording then
        updateFrameCount()
    end
end)

ScreenGui.Destroying:Connect(function()
    if tickConn then tickConn:Disconnect() end
end)

-- ============================================================
--  DRAG
-- ============================================================
do
    local dragging, dragInput, dragStart, startPos
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or
           input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = Window.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    TitleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or
           input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            Window.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

print("[MOVEMENT RECORDER] Loaded! Siap dipakai bro.")
