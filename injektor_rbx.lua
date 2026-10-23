-- =======================================================
-- BLUExCrown ENGINE v5.6 - PERFECT MOBILE EDITION
-- Fix 1: Menu Card Hitbox 100% Responsif (Tombol Toolbox & RBXM PASTI Kebuka)
-- Fix 2: Togle Anti-Geser (Kunci permanen di sisi layar, aman dari swipe kamera)
-- Fix 3: In-Game Code Editor (Bisa ketik, edit, save & execute script di HP)
-- Fix 4: Studio Lite Toolbar [EDIT CODE], [SAVE], [RUN], [COPY]
-- Fix 5: Dual Layer Source Recovery (0% Script Not Found)
-- Toggle Image Asset ID: 102337382069600
-- =======================================================

local HttpService        = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local CoreGui            = game:GetService("CoreGui")
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

local LP = Players.LocalPlayer
local ParentGui = (gethui and gethui()) or CoreGui or LP:WaitForChild("PlayerGui")

local httpRequest  = request or http_request or (syn and syn.request) or (http and http.request)
local clipFn       = setclipboard or toclipboard or (Clipboard and Clipboard.set)
local customAsset  = getcustomasset or getsynasset or nil
local listfilesFn  = listfiles or nil

-- Memory penyimpanan source code script
_G.BLUE_RAW_SOURCES  = _G.BLUE_RAW_SOURCES or {}
_G.LANGZ_RAW_SOURCES = _G.LANGZ_RAW_SOURCES or {}

local function storeScriptSource(key, src)
    if not key or not src then return end
    _G.BLUE_RAW_SOURCES[key] = src
    _G.LANGZ_RAW_SOURCES[key] = src
    if typeof(key) == "Instance" then
        _G.BLUE_RAW_SOURCES[key.Name] = src
        _G.LANGZ_RAW_SOURCES[key.Name] = src
        _G.BLUE_RAW_SOURCES[key.ClassName .. key.Name] = src
        _G.LANGZ_RAW_SOURCES[key.ClassName .. key.Name] = src
    end
end

local function lookupScriptSource(searchKey)
    if not searchKey or searchKey == "" then return nil end
    local sKey = tostring(searchKey):lower():gsub("%s+", "")

    for k, v in pairs(_G.BLUE_RAW_SOURCES) do
        local kname = typeof(k) == "Instance" and (k.ClassName .. k.Name) or tostring(k)
        if kname:lower():gsub("%s+", "") == sKey or kname:lower():find(sKey, 1, true) or sKey:find(kname:lower(), 1, true) then
            if type(v) == "string" and #v > 0 then return v end
        end
    end
    for k, v in pairs(_G.LANGZ_RAW_SOURCES) do
        local kname = typeof(k) == "Instance" and (k.ClassName .. k.Name) or tostring(k)
        if kname:lower():gsub("%s+", "") == sKey or kname:lower():find(sKey, 1, true) or sKey:find(kname:lower(), 1, true) then
            if type(v) == "string" and #v > 0 then return v end
        end
    end
    for _, v in pairs(_G.BLUE_RAW_SOURCES) do
        if type(v) == "string" and #v > 15 then return v end
    end
    for _, v in pairs(_G.LANGZ_RAW_SOURCES) do
        if type(v) == "string" and #v > 15 then return v end
    end
    return nil
end

-- =====================================================
-- STUDIO LITE INTEGRATION & HOOKS
-- =====================================================
local slFolder    = ReplicatedStorage:FindFirstChild("StudioLiteFolder")
local serverFuncs = slFolder and slFolder:FindFirstChild("ServerFunctions")

local function triggerServerLoad(idStr)
    if not serverFuncs or not idStr or idStr == "" then return end
    local id = tostring(idStr):match("%d+")
    if id and tonumber(id) and tonumber(id) > 0 then
        task.spawn(function()
            pcall(function()
                serverFuncs:InvokeServer("LoadMeshToRuntimeMeshes", tonumber(id))
            end)
        end)
    end
end

local function applyStudioLiteProps(obj)
    if not obj then return end
    pcall(function()
        if obj:IsA("BasePart") then
            local origAnchor  = obj.Anchored
            local origCollide = obj.CanCollide
            obj.Anchored = true
            if obj:GetAttribute("SL_Anchored") == nil then obj:SetAttribute("SL_Anchored", origAnchor) end
            if obj:GetAttribute("SL_CanCollide") == nil then obj:SetAttribute("SL_CanCollide", origCollide) end
        end
    end)
    for _, child in ipairs(obj:GetChildren()) do applyStudioLiteProps(child) end
end

local function loadAssetsToSLServer(obj)
    task.spawn(function()
        pcall(function()
            for _, node in ipairs(obj:GetDescendants()) do
                if node:IsA("MeshPart") then
                    triggerServerLoad(node.MeshId); triggerServerLoad(node.TextureID)
                elseif node:IsA("Decal") or node:IsA("Texture") then
                    triggerServerLoad(node.Texture)
                elseif node:IsA("SpecialMesh") then
                    triggerServerLoad(node.MeshId); triggerServerLoad(node.TextureId)
                elseif node:IsA("UnionOperation") or node:IsA("PartOperation") then
                    triggerServerLoad(node.AssetId)
                end
            end
        end)
    end)
end

-- Safe Metamethod Hook
task.spawn(function()
    pcall(function()
        if hookmetamethod then
            local oldNamecall
            oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                local method = getnamecallmethod()
                local args = {...}

                if not checkcaller() and method == "InvokeServer" then
                    if self.Name == "GetScriptSourceServerFunction" then
                        local target = tostring(args[1])
                        local found = lookupScriptSource(target)
                        if found then return found end
                    elseif self.Name == "SaveScriptSourceServerFunction" then
                        local target = tostring(args[1])
                        local newSource = tostring(args[2])
                        storeScriptSource(target, newSource)
                    end
                end
                return oldNamecall(self, ...)
            end)
        end
    end)
end)

-- =====================================================
-- GUI CREATION
-- =====================================================
if ParentGui:FindFirstChild("BLUExCrownV5") then
    ParentGui.BLUExCrownV5:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BLUExCrownV5"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = ParentGui

local function makeCorner(parent, radius)
    local c = Instance.new("UICorner", parent)
    c.CornerRadius = UDim.new(0, radius or 8)
    return c
end

local function makeStroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke", parent)
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Color = color or Color3.fromRGB(255,255,255)
    s.Thickness = thickness or 1.2
    s.Transparency = transparency or 0
    return s
end

-- Simple and Reliable Click Handler for Mobile
local function bindBtn(btn, callback)
    btn.Activated:Connect(callback)
end

-- =====================================================
-- 1. TOGGLE BUTTON (PATEN DI KIRI - TIDAK GESER KARENA KAMERA)
-- =====================================================
local ToggleBtn = Instance.new("ImageButton")
ToggleBtn.Name = "BLUExToggleBtn"
ToggleBtn.Size = UDim2.new(0, 44, 0, 44)
ToggleBtn.Position = UDim2.new(0.015, 0, 0.45, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(14, 14, 16)
ToggleBtn.Image = "rbxassetid://102337382069600"
ToggleBtn.ScaleType = Enum.ScaleType.Fit
ToggleBtn.Active = true
ToggleBtn.ZIndex = 100
ToggleBtn.Parent = ScreenGui
makeCorner(ToggleBtn, 8)
makeStroke(ToggleBtn, Color3.fromRGB(255,255,255), 1.4)

-- =====================================================
-- 2. MAIN WINDOW
-- =====================================================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.fromScale(0.5, 0.5)
MainFrame.Size = UDim2.new(0, 640, 0, 360)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Active = true
MainFrame.ZIndex = 10
MainFrame.Parent = ScreenGui
makeCorner(MainFrame, 10)
makeStroke(MainFrame, Color3.fromRGB(255,255,255), 1.4)

-- TOP BAR
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, -12, 0, 32)
TopBar.Position = UDim2.new(0, 6, 0, 6)
TopBar.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
TopBar.BorderSizePixel = 0
TopBar.Active = true
TopBar.ZIndex = 11
TopBar.Parent = MainFrame
makeCorner(TopBar, 7)
makeStroke(TopBar, Color3.fromRGB(255,255,255), 1, 0.75)

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size = UDim2.new(1, -70, 1, 0)
TitleLbl.Position = UDim2.new(0, 12, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text = "BLUExCrown ENGINE v5.6"
TitleLbl.Font = Enum.Font.GothamBold
TitleLbl.TextSize = 11
TitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TitleLbl.ZIndex = 12
TitleLbl.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 26, 0, 24)
CloseBtn.Position = UDim2.new(1, -30, 0, 4)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
CloseBtn.ZIndex = 20
CloseBtn.Active = true
CloseBtn.Parent = TopBar
makeCorner(CloseBtn, 5)

-- Draggable Hanya untuk TopBar
local function makeSafeTopBarDraggable(frame, handle)
    local dragInput = nil
    local dragStart = nil
    local startPos = nil

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
            dragStart = input.Position
            startPos = frame.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragStart and startPos then
            local delta = input.Position - dragStart
            local vp = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(800, 450)
            local newX = math.clamp(startPos.X.Offset + delta.X, -vp.X/2 + 200, vp.X/2 - 200)
            local newY = math.clamp(startPos.Y.Offset + delta.Y, -vp.Y/2 + 100, vp.Y/2 - 100)
            frame.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input == dragInput then
            dragInput = nil
            dragStart = nil
            startPos = nil
        end
    end)
end

makeSafeTopBarDraggable(MainFrame, TopBar)

-- TOGGLE & CLOSE BEHAVIOR
local isOpen = true
local toggleDebounce = false

local function toggleWindow()
    if toggleDebounce then return end
    toggleDebounce = true
    isOpen = not isOpen
    MainFrame.Visible = isOpen
    task.delay(0.2, function() toggleDebounce = false end)
end

bindBtn(ToggleBtn, toggleWindow)
bindBtn(CloseBtn, toggleWindow)

-- =====================================================
-- 3. IN-GAME CODE EDITOR MODAL
-- =====================================================
local EditorModal = Instance.new("Frame")
EditorModal.Name = "BLUExEditorModal"
EditorModal.AnchorPoint = Vector2.new(0.5, 0.5)
EditorModal.Position = UDim2.fromScale(0.5, 0.5)
EditorModal.Size = UDim2.new(0, 680, 0, 380)
EditorModal.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
EditorModal.BorderSizePixel = 0
EditorModal.ClipsDescendants = true
EditorModal.Visible = false
EditorModal.Active = false
EditorModal.ZIndex = 200
EditorModal.Parent = ScreenGui
makeCorner(EditorModal, 10)
makeStroke(EditorModal, Color3.fromRGB(255, 255, 255), 1.5)

local EdTopBar = Instance.new("Frame")
EdTopBar.Size = UDim2.new(1, -12, 0, 32)
EdTopBar.Position = UDim2.new(0, 6, 0, 6)
EdTopBar.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
EdTopBar.ZIndex = 201
EdTopBar.Parent = EditorModal
makeCorner(EdTopBar, 6)
makeStroke(EdTopBar, Color3.fromRGB(255,255,255), 1, 0.8)

local EdTitleLbl = Instance.new("TextLabel")
EdTitleLbl.Size = UDim2.new(0.38, 0, 1, 0)
EdTitleLbl.Position = UDim2.new(0, 10, 0, 0)
EdTitleLbl.BackgroundTransparency = 1
EdTitleLbl.Text = "EDITOR: Script"
EdTitleLbl.Font = Enum.Font.GothamBold
EdTitleLbl.TextSize = 11
EdTitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
EdTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
EdTitleLbl.ZIndex = 202
EdTitleLbl.Parent = EdTopBar

local EdBtnRow = Instance.new("Frame")
EdBtnRow.Size = UDim2.new(0.62, -10, 1, -6)
EdBtnRow.Position = UDim2.new(0.38, 5, 0, 3)
EdBtnRow.BackgroundTransparency = 1
EdBtnRow.ZIndex = 202
EdBtnRow.Parent = EdTopBar

local edLayout = Instance.new("UIListLayout")
edLayout.FillDirection = Enum.FillDirection.Horizontal
edLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
edLayout.Padding = UDim.new(0, 6)
edLayout.Parent = EdBtnRow

local function makeEdBtn(text, width, onClick)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, width, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 9
    btn.TextColor3 = Color3.fromRGB(0, 0, 0)
    btn.ZIndex = 203
    btn.Parent = EdBtnRow
    makeCorner(btn, 5)
    bindBtn(btn, onClick)
    return btn
end

local activeEditingScript = ""

local EdSaveBtn = makeEdBtn("SAVE & APPLY", 90, function() end)
local EdRunBtn  = makeEdBtn("RUN SCRIPT", 75, function() end)
local EdCopyBtn = makeEdBtn("COPY ALL", 65, function() end)
local EdCloseBtn = makeEdBtn("X", 26, function()
    EditorModal.Visible = false
    EditorModal.Active = false
end)

local EdScroll = Instance.new("ScrollingFrame")
EdScroll.Size = UDim2.new(1, -12, 1, -48)
EdScroll.Position = UDim2.new(0, 6, 0, 42)
EdScroll.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
EdScroll.BorderSizePixel = 0
EdScroll.ScrollBarThickness = 4
EdScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
EdScroll.ZIndex = 201
EdScroll.Parent = EditorModal
makeCorner(EdScroll, 6)
makeStroke(EdScroll, Color3.fromRGB(255,255,255), 1, 0.8)

local EdTextBox = Instance.new("TextBox")
EdTextBox.Size = UDim2.new(1, -16, 1, -10)
EdTextBox.Position = UDim2.new(0, 8, 0, 5)
EdTextBox.BackgroundTransparency = 1
EdTextBox.Font = Enum.Font.Code
EdTextBox.TextSize = 11
EdTextBox.TextColor3 = Color3.fromRGB(235, 235, 240)
EdTextBox.TextXAlignment = Enum.TextXAlignment.Left
EdTextBox.TextYAlignment = Enum.TextYAlignment.Top
EdTextBox.ClearTextOnFocus = false
EdTextBox.TextEditable = true
EdTextBox.MultiLine = true
EdTextBox.Active = true
EdTextBox.ZIndex = 202
EdTextBox.Text = ""
EdTextBox.Parent = EdScroll

EdTextBox:GetPropertyChangedSignal("Text"):Connect(function()
    local lines = #EdTextBox.Text:split("\n")
    EdScroll.CanvasSize = UDim2.new(0, 0, 0, math.max(340, lines * 18 + 40))
end)

local function openInEditor(scriptName, code)
    activeEditingScript = scriptName or "Script"
    EdTitleLbl.Text = "EDITOR: " .. activeEditingScript
    EdTextBox.Text = code or lookupScriptSource(scriptName) or "-- Ketik code di sini..."
    EditorModal.Active = true
    EditorModal.Visible = true
end

bindBtn(EdSaveBtn, function()
    local newCode = EdTextBox.Text
    storeScriptSource(activeEditingScript, newCode)
    pcall(function()
        for _, inst in ipairs(workspace:GetDescendants()) do
            if inst:IsA("LuaSourceContainer") and inst.Name:lower() == activeEditingScript:lower() then
                storeScriptSource(inst, newCode)
                pcall(function() inst.Source = newCode end)
            end
        end
    end)
    if serverFuncs then
        pcall(function() serverFuncs:InvokeServer("SaveScriptSourceServerFunction", activeEditingScript, newCode) end)
    end
    EdSaveBtn.Text = "SAVED!"
    task.delay(1.2, function() EdSaveBtn.Text = "SAVE & APPLY" end)
end)

bindBtn(EdRunBtn, function()
    if EdTextBox.Text ~= "" then
        local fn, err = loadstring(EdTextBox.Text)
        if fn then
            task.spawn(fn)
            EdRunBtn.Text = "RUNNING!"
        else
            EdRunBtn.Text = "ERROR!"
            warn("[BLUExCrown] Code Error: " .. tostring(err))
        end
        task.delay(1.5, function() EdRunBtn.Text = "RUN SCRIPT" end)
    end
end)

bindBtn(EdCopyBtn, function()
    if clipFn and EdTextBox.Text ~= "" then
        pcall(clipFn, EdTextBox.Text)
        EdCopyBtn.Text = "COPIED!"
        task.delay(1.2, function() EdCopyBtn.Text = "COPY ALL" end)
    end
end)

-- =====================================================
-- 4. STUDIO LITE REAL-TIME UI WATCHER & INJECTOR
-- =====================================================
local function fixEditorUI(desc)
    if not desc then return end

    if desc:IsA("TextBox") or desc:IsA("TextLabel") then
        local t = desc.Text
        if t == "Not found." or t == "Not found" or t:find("Not found") or t == "-- [LANGZ] Source tidak ditemukan." then
            local win = desc:FindFirstAncestorWhichIsA("Frame") or desc.Parent
            local scriptName = ""
            if win then
                for _, wChild in ipairs(win:GetDescendants()) do
                    if (wChild:IsA("TextLabel") or wChild:IsA("TextBox")) and wChild ~= desc then
                        local wt = wChild.Text
                        if wt:find("%(read only%)") or wt:find("%[EDITABLE%]") or #wt > 1 then
                            scriptName = wt:gsub("%s*%(read only%)%s*", ""):gsub("%s*%[EDITABLE%]%s*", ""):gsub("%s+", "")
                            if wChild:IsA("TextLabel") then
                                wChild.Text = scriptName .. " [EDITABLE]"
                                wChild.TextColor3 = Color3.fromRGB(180, 255, 180)
                            end
                            break
                        end
                    end
                end
            end

            local source = lookupScriptSource(scriptName)
            if source then desc.Text = source end
        end

        if desc:IsA("TextBox") then
            desc.TextEditable = true
            desc.ClearTextOnFocus = false
            desc.Active = true
        end

        if desc:IsA("TextLabel") and desc.Text:find("%(read only%)") then
            desc.Text = desc.Text:gsub("%s*%(read only%)%s*", "") .. " [EDITABLE]"
            desc.TextColor3 = Color3.fromRGB(180, 255, 180)
        end
    end

    if desc:IsA("Frame") then
        local titleLbl = nil
        local codeBox  = nil
        local hasReadOnly = false

        for _, d in ipairs(desc:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("TextBox") then
                local txt = d.Text
                if txt:find("%(read only%)") or txt:find("%[EDITABLE%]") then
                    titleLbl = d
                    hasReadOnly = true
                elseif txt == "Not found." or txt == "Not found" or txt:find("Not found") or #txt > 15 then
                    codeBox = d
                end
            end
        end

        if hasReadOnly and titleLbl then
            local cleanTitle = titleLbl.Text:gsub("%s*%(read only%)%s*", ""):gsub("%s*%[EDITABLE%]%s*", ""):gsub("%s+", "")
            titleLbl.Text = cleanTitle .. " [EDITABLE]"
            titleLbl.TextColor3 = Color3.fromRGB(180, 255, 180)

            if codeBox then
                if codeBox.Text == "Not found." or codeBox.Text == "Not found" or codeBox.Text:find("Not found") then
                    local s = lookupScriptSource(cleanTitle)
                    if s then codeBox.Text = s end
                end
                if codeBox:IsA("TextBox") then
                    codeBox.TextEditable = true
                    codeBox.ClearTextOnFocus = false
                    codeBox.Active = true
                end
            end

            if not desc:FindFirstChild("BLUExToolbar") then
                local toolbar = Instance.new("Frame")
                toolbar.Name = "BLUExToolbar"
                toolbar.Size = UDim2.new(0, 260, 0, 24)
                toolbar.Position = UDim2.new(1, -295, 0, 4)
                toolbar.BackgroundTransparency = 1
                toolbar.ZIndex = 60
                toolbar.Parent = desc

                local function makeToolBtn(text, posX, width, onClick)
                    local btn = Instance.new("TextButton")
                    btn.Size = UDim2.new(0, width, 1, 0)
                    btn.Position = UDim2.new(0, posX, 0, 0)
                    btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    btn.Text = text
                    btn.Font = Enum.Font.GothamBold
                    btn.TextSize = 8
                    btn.TextColor3 = Color3.fromRGB(0, 0, 0)
                    btn.ZIndex = 61
                    btn.Parent = toolbar
                    local c = Instance.new("UICorner", btn); c.CornerRadius = UDim.new(0, 4)
                    btn.Activated:Connect(onClick)
                    return btn
                end

                makeToolBtn("EDIT CODE", 0, 70, function()
                    local currentCode = (codeBox and codeBox.Text) or lookupScriptSource(cleanTitle) or ""
                    openInEditor(cleanTitle, currentCode)
                end)

                local saveBtn = makeToolBtn("SAVE", 74, 55, function()
                    local newCode = (codeBox and codeBox.Text) or lookupScriptSource(cleanTitle) or ""
                    storeScriptSource(cleanTitle, newCode)
                    pcall(function()
                        for _, inst in ipairs(workspace:GetDescendants()) do
                            if inst:IsA("LuaSourceContainer") and inst.Name:lower() == cleanTitle:lower() then
                                storeScriptSource(inst, newCode)
                                pcall(function() inst.Source = newCode end)
                            end
                        end
                    end)
                    if serverFuncs then
                        pcall(function() serverFuncs:InvokeServer("SaveScriptSourceServerFunction", cleanTitle, newCode) end)
                    end
                    saveBtn.Text = "SAVED!"
                    task.delay(1.2, function() if saveBtn and saveBtn.Parent then saveBtn.Text = "SAVE" end end)
                end)

                local runBtn = makeToolBtn("RUN", 133, 55, function()
                    local codeToRun = (codeBox and codeBox.Text) or lookupScriptSource(cleanTitle)
                    if codeToRun and codeToRun ~= "" then
                        local fn, err = loadstring(codeToRun)
                        if fn then
                            task.spawn(fn)
                            runBtn.Text = "RUNNING!"
                        else
                            runBtn.Text = "ERR!"
                            warn("[BLUExCrown] Compile error: " .. tostring(err))
                        end
                        task.delay(1.5, function() if runBtn and runBtn.Parent then runBtn.Text = "RUN" end end)
                    end
                end)

                local copyBtn = makeToolBtn("COPY", 192, 60, function()
                    local codeToCopy = (codeBox and codeBox.Text) or lookupScriptSource(cleanTitle)
                    if codeToCopy and clipFn then
                        pcall(clipFn, codeToCopy)
                        copyBtn.Text = "COPIED!"
                        task.delay(1.2, function() if copyBtn and copyBtn.Parent then copyBtn.Text = "COPY" end end)
                    end
                end)
            end
        end
    end
end

task.spawn(function()
    pcall(function()
        local pg = LP:WaitForChild("PlayerGui", 5)
        if pg then
            pg.DescendantAdded:Connect(function(desc)
                task.delay(0.05, function() fixEditorUI(desc) end)
            end)
            for _, d in ipairs(pg:GetDescendants()) do fixEditorUI(d) end
        end
    end)
end)

task.spawn(function()
    while task.wait(0.6) do
        pcall(function()
            local pg = LP:FindFirstChild("PlayerGui")
            if pg then
                for _, d in ipairs(pg:GetDescendants()) do
                    if (d:IsA("TextBox") or d:IsA("TextLabel")) and (d.Text == "Not found." or d.Text:find("%(read only%)")) then
                        fixEditorUI(d)
                    end
                end
            end
        end)
    end
end)

-- =====================================================
-- 5. PAGES & NAVIGATION (100% INSTANT HITBOX)
-- =====================================================
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -12, 1, -46)
Content.Position = UDim2.new(0, 6, 0, 42)
Content.BackgroundTransparency = 1
Content.ZIndex = 11
Content.Parent = MainFrame

local PageSplash  = Instance.new("Frame")
local PageToolbox = Instance.new("Frame")
local PageRBXM    = Instance.new("Frame")

for _, pg in ipairs({PageSplash, PageToolbox, PageRBXM}) do
    pg.Size = UDim2.fromScale(1, 1)
    pg.BackgroundTransparency = 1
    pg.Visible = false
    pg.ZIndex = 12
    pg.Parent = Content
end
PageSplash.Visible = true

local function showPage(target)
    PageSplash.Visible  = false
    PageToolbox.Visible = false
    PageRBXM.Visible    = false
    target.Visible = true
end

-- =====================================================
-- PAGE 1: SPLASH SCREEN (HOME)
-- =====================================================
local ProfileCard = Instance.new("Frame")
ProfileCard.Size = UDim2.new(0, 175, 1, 0)
ProfileCard.BackgroundColor3 = Color3.fromRGB(17, 17, 22)
ProfileCard.BorderSizePixel = 0
ProfileCard.ZIndex = 13
ProfileCard.Parent = PageSplash
makeCorner(ProfileCard, 8)
makeStroke(ProfileCard, Color3.fromRGB(255,255,255), 1, 0.75)

local AvatarImg = Instance.new("ImageLabel")
AvatarImg.Size = UDim2.new(0, 70, 0, 70)
AvatarImg.AnchorPoint = Vector2.new(0.5, 0)
AvatarImg.Position = UDim2.new(0.5, 0, 0, 14)
AvatarImg.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
AvatarImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LP.UserId) .. "&w=150&h=150"
AvatarImg.ZIndex = 14
AvatarImg.Parent = ProfileCard
makeCorner(AvatarImg, 35)
makeStroke(AvatarImg, Color3.fromRGB(255,255,255), 1.5, 0.5)

local DispName = Instance.new("TextLabel")
DispName.Size = UDim2.new(1, -16, 0, 20)
DispName.Position = UDim2.new(0, 8, 0, 90)
DispName.BackgroundTransparency = 1
DispName.Text = LP.DisplayName or LP.Name or "Player"
DispName.Font = Enum.Font.GothamBold
DispName.TextSize = 13
DispName.TextColor3 = Color3.fromRGB(255, 255, 255)
DispName.TextXAlignment = Enum.TextXAlignment.Center
DispName.TextTruncate = Enum.TextTruncate.AtEnd
DispName.ZIndex = 14
DispName.Parent = ProfileCard

local UsernLabel = Instance.new("TextLabel")
UsernLabel.Size = UDim2.new(1, -16, 0, 16)
UsernLabel.Position = UDim2.new(0, 8, 0, 112)
UsernLabel.BackgroundTransparency = 1
UsernLabel.Text = "@" .. (LP.Name or "username")
UsernLabel.Font = Enum.Font.Gotham
UsernLabel.TextSize = 10
UsernLabel.TextColor3 = Color3.fromRGB(160, 160, 170)
UsernLabel.TextXAlignment = Enum.TextXAlignment.Center
UsernLabel.ZIndex = 14
UsernLabel.Parent = ProfileCard

local SepLine = Instance.new("Frame")
SepLine.Size = UDim2.new(1, -20, 0, 1)
SepLine.Position = UDim2.new(0, 10, 0, 136)
SepLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SepLine.BackgroundTransparency = 0.85
SepLine.BorderSizePixel = 0
SepLine.ZIndex = 14
SepLine.Parent = ProfileCard

local SLStatusLbl = Instance.new("TextLabel")
SLStatusLbl.Size = UDim2.new(1, -16, 0, 14)
SLStatusLbl.Position = UDim2.new(0, 8, 0, 144)
SLStatusLbl.BackgroundTransparency = 1
SLStatusLbl.Text = "[OK] Studio Lite Auto-Unlock"
SLStatusLbl.Font = Enum.Font.Gotham
SLStatusLbl.TextSize = 8
SLStatusLbl.TextColor3 = Color3.fromRGB(120, 220, 120)
SLStatusLbl.TextXAlignment = Enum.TextXAlignment.Center
SLStatusLbl.ZIndex = 14
SLStatusLbl.Parent = ProfileCard

local StatsLbl = Instance.new("TextLabel")
StatsLbl.Size = UDim2.new(1, -16, 1, -168)
StatsLbl.Position = UDim2.new(0, 8, 0, 162)
StatsLbl.BackgroundTransparency = 1
StatsLbl.Text = "UserID: "..tostring(LP.UserId).."\nBLUExCrown ENGINE\nv5.6 — Perfect Edition"
StatsLbl.Font = Enum.Font.Gotham
StatsLbl.TextSize = 9
StatsLbl.TextColor3 = Color3.fromRGB(130, 130, 140)
StatsLbl.TextXAlignment = Enum.TextXAlignment.Center
StatsLbl.TextWrapped = true
StatsLbl.ZIndex = 14
StatsLbl.Parent = ProfileCard

-- KANAN: Menu Cards
local MenuArea = Instance.new("Frame")
MenuArea.Size = UDim2.new(1, -183, 1, 0)
MenuArea.Position = UDim2.new(0, 183, 0, 0)
MenuArea.BackgroundTransparency = 1
MenuArea.ZIndex = 13
MenuArea.Parent = PageSplash

local MenuTitle = Instance.new("TextLabel")
MenuTitle.Size = UDim2.new(1, 0, 0, 24)
MenuTitle.BackgroundTransparency = 1
MenuTitle.Text = "PILIH MENU"
MenuTitle.Font = Enum.Font.GothamBold
MenuTitle.TextSize = 10
MenuTitle.TextColor3 = Color3.fromRGB(180, 180, 190)
MenuTitle.TextXAlignment = Enum.TextXAlignment.Left
MenuTitle.ZIndex = 14
MenuTitle.Parent = MenuArea

-- MENU CARD DENGAN TRANSPARENT FULL HITBOX (100% RESPONSIF)
local function makeMenuCard(parent, posY, icon, title, subtitle, onClick)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 72)
    card.Position = UDim2.new(0, 0, 0, posY)
    card.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    card.ZIndex = 14
    card.Parent = parent
    makeCorner(card, 8)
    makeStroke(card, Color3.fromRGB(255,255,255), 1, 0.78)

    local iconLbl = Instance.new("TextLabel")
    iconLbl.Size = UDim2.new(0, 44, 0, 44)
    iconLbl.Position = UDim2.new(0, 14, 0.5, -22)
    iconLbl.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
    iconLbl.Text = icon
    iconLbl.Font = Enum.Font.GothamBold
    iconLbl.TextSize = 18
    iconLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    iconLbl.ZIndex = 15
    iconLbl.Parent = card
    makeCorner(iconLbl, 8)

    local titleL = Instance.new("TextLabel")
    titleL.Size = UDim2.new(1, -80, 0, 20)
    titleL.Position = UDim2.new(0, 68, 0, 16)
    titleL.BackgroundTransparency = 1
    titleL.Text = title
    titleL.Font = Enum.Font.GothamBold
    titleL.TextSize = 13
    titleL.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleL.TextXAlignment = Enum.TextXAlignment.Left
    titleL.ZIndex = 15
    titleL.Parent = card

    local subL = Instance.new("TextLabel")
    subL.Size = UDim2.new(1, -80, 0, 16)
    subL.Position = UDim2.new(0, 68, 0, 37)
    subL.BackgroundTransparency = 1
    subL.Text = subtitle
    subL.Font = Enum.Font.Gotham
    subL.TextSize = 9
    subL.TextColor3 = Color3.fromRGB(150, 150, 160)
    subL.TextXAlignment = Enum.TextXAlignment.Left
    subL.ZIndex = 15
    subL.Parent = card

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 20, 0, 20)
    arrow.Position = UDim2.new(1, -28, 0.5, -10)
    arrow.BackgroundTransparency = 1
    arrow.Text = ">"
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 18
    arrow.TextColor3 = Color3.fromRGB(200, 200, 210)
    arrow.ZIndex = 15
    arrow.Parent = card

    -- Full Top Transparent Hitbox
    local hit = Instance.new("TextButton")
    hit.Size = UDim2.fromScale(1, 1)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.ZIndex = 30
    hit.Active = true
    hit.Parent = card

    hit.Activated:Connect(function()
        pcall(onClick)
    end)

    return card
end

makeMenuCard(MenuArea, 28,  "[T]", "TOOLBOX ASET",     "Cari & insert model dari Creator Store", function()
    showPage(PageToolbox)
end)

makeMenuCard(MenuArea, 108, "[R]", "INSERT RBXM FILE", "Scan & insert file .rbxm dengan Source Script", function()
    showPage(PageRBXM)
end)

local function makeBackBtn(parent, onBack)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 64, 0, 22)
    b.Position = UDim2.new(1, -68, 0, 0)
    b.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    b.Text = "< BACK"
    b.Font = Enum.Font.GothamBold
    b.TextSize = 9
    b.TextColor3 = Color3.fromRGB(0, 0, 0)
    b.Active = true
    b.ZIndex = 25
    b.Parent = parent
    makeCorner(b, 5)
    b.Activated:Connect(onBack)
    return b
end

-- =====================================================
-- PAGE 2: TOOLBOX ASSET
-- =====================================================
local TbHeader = Instance.new("Frame")
TbHeader.Size = UDim2.new(1, 0, 0, 28)
TbHeader.BackgroundTransparency = 1
TbHeader.ZIndex = 13
TbHeader.Parent = PageToolbox

local TbTitleLbl = Instance.new("TextLabel")
TbTitleLbl.Size = UDim2.new(1, -80, 1, 0)
TbTitleLbl.BackgroundTransparency = 1
TbTitleLbl.Text = "TOOLBOX ASET"
TbTitleLbl.Font = Enum.Font.GothamBold
TbTitleLbl.TextSize = 11
TbTitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
TbTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TbTitleLbl.ZIndex = 14
TbTitleLbl.Parent = TbHeader

makeBackBtn(TbHeader, function() showPage(PageSplash) end)

local TbContent = Instance.new("Frame")
TbContent.Size = UDim2.new(1, 0, 1, -34)
TbContent.Position = UDim2.new(0, 0, 0, 34)
TbContent.BackgroundTransparency = 1
TbContent.ZIndex = 13
TbContent.Parent = PageToolbox

local TbLeft = Instance.new("Frame")
TbLeft.Size = UDim2.new(0, 220, 1, 0)
TbLeft.BackgroundTransparency = 1
TbLeft.ZIndex = 14
TbLeft.Parent = TbContent

local TbSearchSec = Instance.new("Frame")
TbSearchSec.Size = UDim2.new(1, 0, 0, 118)
TbSearchSec.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
TbSearchSec.ZIndex = 14
TbSearchSec.Parent = TbLeft
makeCorner(TbSearchSec, 8)
makeStroke(TbSearchSec, Color3.fromRGB(255,255,255), 1, 0.78)

local TbIdBox = Instance.new("TextBox")
TbIdBox.Size = UDim2.new(1, -70, 0, 24)
TbIdBox.Position = UDim2.new(0, 6, 0, 8)
TbIdBox.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
TbIdBox.PlaceholderText = "Asset ID langsung..."
TbIdBox.PlaceholderColor3 = Color3.fromRGB(110, 110, 120)
TbIdBox.Text = ""
TbIdBox.Font = Enum.Font.Gotham
TbIdBox.TextSize = 10
TbIdBox.TextColor3 = Color3.fromRGB(255, 255, 255)
TbIdBox.ClearTextOnFocus = false
TbIdBox.ZIndex = 15
TbIdBox.Parent = TbSearchSec
makeCorner(TbIdBox, 5)

local TbInsertIdBtn = Instance.new("TextButton")
TbInsertIdBtn.Size = UDim2.new(0, 54, 0, 24)
TbInsertIdBtn.Position = UDim2.new(1, -60, 0, 8)
TbInsertIdBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TbInsertIdBtn.Text = "INSERT"
TbInsertIdBtn.Font = Enum.Font.GothamBold
TbInsertIdBtn.TextSize = 9
TbInsertIdBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
TbInsertIdBtn.Active = true
TbInsertIdBtn.ZIndex = 15
TbInsertIdBtn.Parent = TbSearchSec
makeCorner(TbInsertIdBtn, 5)

local TbSearchBox = Instance.new("TextBox")
TbSearchBox.Size = UDim2.new(1, -70, 0, 24)
TbSearchBox.Position = UDim2.new(0, 6, 0, 36)
TbSearchBox.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
TbSearchBox.PlaceholderText = "Cari kata kunci..."
TbSearchBox.PlaceholderColor3 = Color3.fromRGB(110, 110, 120)
TbSearchBox.Text = ""
TbSearchBox.Font = Enum.Font.Gotham
TbSearchBox.TextSize = 10
TbSearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
TbSearchBox.ClearTextOnFocus = false
TbSearchBox.ZIndex = 15
TbSearchBox.Parent = TbSearchSec
makeCorner(TbSearchBox, 5)

local TbSearchBtn = Instance.new("TextButton")
TbSearchBtn.Size = UDim2.new(0, 54, 0, 24)
TbSearchBtn.Position = UDim2.new(1, -60, 0, 36)
TbSearchBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TbSearchBtn.Text = "CARI"
TbSearchBtn.Font = Enum.Font.GothamBold
TbSearchBtn.TextSize = 9
TbSearchBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
TbSearchBtn.Active = true
TbSearchBtn.ZIndex = 15
TbSearchBtn.Parent = TbSearchSec
makeCorner(TbSearchBtn, 5)

local selectedCat = 10
local catBtns = {}
local cats = {{n="MODEL",id=10},{n="DECAL",id=13},{n="AUDIO",id=3},{n="MESH",id=11}}
local TbCatRow = Instance.new("Frame")
TbCatRow.Size = UDim2.new(1, -12, 0, 20)
TbCatRow.Position = UDim2.new(0, 6, 0, 65)
TbCatRow.BackgroundTransparency = 1
TbCatRow.ZIndex = 14
TbCatRow.Parent = TbSearchSec
local catUL = Instance.new("UIListLayout")
catUL.FillDirection = Enum.FillDirection.Horizontal
catUL.Padding = UDim.new(0, 4)
catUL.Parent = TbCatRow

local function updateCatTabs()
    for id, btn in pairs(catBtns) do
        if id == selectedCat then
            btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            btn.TextColor3 = Color3.fromRGB(0, 0, 0)
        else
            btn.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
            btn.TextColor3 = Color3.fromRGB(160, 160, 170)
        end
    end
end

for _, c in ipairs(cats) do
    local cb = Instance.new("TextButton")
    cb.Size = UDim2.new(0.25, -3, 1, 0)
    cb.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
    cb.Text = c.n; cb.Font = Enum.Font.GothamBold; cb.TextSize = 8
    cb.TextColor3 = Color3.fromRGB(160, 160, 170)
    cb.Active = true
    cb.ZIndex = 15
    cb.Parent = TbCatRow
    makeCorner(cb, 4); makeStroke(cb, Color3.fromRGB(255,255,255), 1, 0.82)
    catBtns[c.id] = cb
    cb.Activated:Connect(function() selectedCat = c.id; updateCatTabs() end)
end
updateCatTabs()

local TbStatusLbl = Instance.new("TextLabel")
TbStatusLbl.Size = UDim2.new(1, -12, 0, 16)
TbStatusLbl.Position = UDim2.new(0, 6, 0, 90)
TbStatusLbl.BackgroundTransparency = 1
TbStatusLbl.Text = "[.] Siap"
TbStatusLbl.Font = Enum.Font.Gotham; TbStatusLbl.TextSize = 9
TbStatusLbl.TextColor3 = Color3.fromRGB(140, 140, 150)
TbStatusLbl.TextXAlignment = Enum.TextXAlignment.Left
TbStatusLbl.ZIndex = 15
TbStatusLbl.Parent = TbSearchSec

local TbDetailBox = Instance.new("Frame")
TbDetailBox.Size = UDim2.new(1, 0, 1, -124)
TbDetailBox.Position = UDim2.new(0, 0, 0, 124)
TbDetailBox.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
TbDetailBox.ZIndex = 14
TbDetailBox.Parent = TbLeft
makeCorner(TbDetailBox, 8); makeStroke(TbDetailBox, Color3.fromRGB(255,255,255), 1, 0.78)

local TbDetTitleLbl = Instance.new("TextLabel")
TbDetTitleLbl.Size = UDim2.new(1, -12, 0, 18); TbDetTitleLbl.Position = UDim2.new(0, 8, 0, 4)
TbDetTitleLbl.BackgroundTransparency = 1; TbDetTitleLbl.Text = "DETAIL ASSET"
TbDetTitleLbl.Font = Enum.Font.GothamBold; TbDetTitleLbl.TextSize = 9
TbDetTitleLbl.TextColor3 = Color3.fromRGB(200, 200, 210)
TbDetTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TbDetTitleLbl.ZIndex = 15
TbDetTitleLbl.Parent = TbDetailBox

local TbDetThumb = Instance.new("ImageLabel")
TbDetThumb.Size = UDim2.new(0, 52, 0, 52); TbDetThumb.Position = UDim2.new(0, 8, 0, 24)
TbDetThumb.BackgroundColor3 = Color3.fromRGB(26, 26, 30); TbDetThumb.Image = ""
TbDetThumb.ZIndex = 15
TbDetThumb.Parent = TbDetailBox; makeCorner(TbDetThumb, 6); makeStroke(TbDetThumb, Color3.fromRGB(255,255,255), 1, 0.82)

local TbDetName = Instance.new("TextLabel")
TbDetName.Size = UDim2.new(1, -70, 0, 26); TbDetName.Position = UDim2.new(0, 66, 0, 22)
TbDetName.BackgroundTransparency = 1; TbDetName.Text = "Pilih aset dari grid"
TbDetName.Font = Enum.Font.GothamBold; TbDetName.TextSize = 10
TbDetName.TextColor3 = Color3.fromRGB(255, 255, 255)
TbDetName.TextXAlignment = Enum.TextXAlignment.Left; TbDetName.TextWrapped = true
TbDetName.ZIndex = 15
TbDetName.Parent = TbDetailBox

local TbDetCreator = Instance.new("TextLabel")
TbDetCreator.Size = UDim2.new(1, -70, 0, 14); TbDetCreator.Position = UDim2.new(0, 66, 0, 46)
TbDetCreator.BackgroundTransparency = 1; TbDetCreator.Text = "By: -"
TbDetCreator.Font = Enum.Font.Gotham; TbDetCreator.TextSize = 8
TbDetCreator.TextColor3 = Color3.fromRGB(150, 150, 160)
TbDetCreator.TextXAlignment = Enum.TextXAlignment.Left
TbDetCreator.ZIndex = 15
TbDetCreator.Parent = TbDetailBox

local TbDetId = Instance.new("TextLabel")
TbDetId.Size = UDim2.new(1, -70, 0, 14); TbDetId.Position = UDim2.new(0, 66, 0, 60)
TbDetId.BackgroundTransparency = 1; TbDetId.Text = "ID: -"
TbDetId.Font = Enum.Font.Gotham; TbDetId.TextSize = 8
TbDetId.TextColor3 = Color3.fromRGB(150, 150, 160)
TbDetId.TextXAlignment = Enum.TextXAlignment.Left
TbDetId.ZIndex = 15
TbDetId.Parent = TbDetailBox

local currentInspId = ""
local TbDetRow = Instance.new("Frame")
TbDetRow.Size = UDim2.new(1, -16, 0, 26); TbDetRow.Position = UDim2.new(0, 8, 1, -32)
TbDetRow.BackgroundTransparency = 1
TbDetRow.ZIndex = 14
TbDetRow.Parent = TbDetailBox

local TbDetInsert = Instance.new("TextButton")
TbDetInsert.Size = UDim2.new(0.5, -3, 1, 0); TbDetInsert.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TbDetInsert.Text = "INSERT"; TbDetInsert.Font = Enum.Font.GothamBold; TbDetInsert.TextSize = 9
TbDetInsert.TextColor3 = Color3.fromRGB(0, 0, 0); TbDetInsert.Active = true; TbDetInsert.ZIndex = 15
TbDetInsert.Parent = TbDetRow; makeCorner(TbDetInsert, 5)

local TbDetCopy = Instance.new("TextButton")
TbDetCopy.Size = UDim2.new(0.5, -3, 1, 0); TbDetCopy.Position = UDim2.new(0.5, 3, 0, 0)
TbDetCopy.BackgroundColor3 = Color3.fromRGB(255, 255, 255); TbDetCopy.Text = "COPY ID"
TbDetCopy.Font = Enum.Font.GothamBold; TbDetCopy.TextSize = 9
TbDetCopy.TextColor3 = Color3.fromRGB(0, 0, 0); TbDetCopy.Active = true; TbDetCopy.ZIndex = 15
TbDetCopy.Parent = TbDetRow; makeCorner(TbDetCopy, 5)

local TbRight = Instance.new("Frame")
TbRight.Size = UDim2.new(1, -228, 1, 0); TbRight.Position = UDim2.new(0, 228, 0, 0)
TbRight.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
TbRight.ZIndex = 14
TbRight.Parent = TbContent
makeCorner(TbRight, 8); makeStroke(TbRight, Color3.fromRGB(255,255,255), 1, 0.78)

local TbBrowserLbl = Instance.new("TextLabel")
TbBrowserLbl.Size = UDim2.new(1, -16, 0, 24); TbBrowserLbl.Position = UDim2.new(0, 8, 0, 4)
TbBrowserLbl.BackgroundTransparency = 1; TbBrowserLbl.Text = "ASSET BROWSER"
TbBrowserLbl.Font = Enum.Font.GothamBold; TbBrowserLbl.TextSize = 10
TbBrowserLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
TbBrowserLbl.TextXAlignment = Enum.TextXAlignment.Left
TbBrowserLbl.ZIndex = 15
TbBrowserLbl.Parent = TbRight

local TbGridScroll = Instance.new("ScrollingFrame")
TbGridScroll.Size = UDim2.new(1, -12, 1, -34); TbGridScroll.Position = UDim2.new(0, 6, 0, 28)
TbGridScroll.BackgroundTransparency = 1; TbGridScroll.ScrollBarThickness = 3
TbGridScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
TbGridScroll.ZIndex = 15
TbGridScroll.Parent = TbRight

local TbGrid = Instance.new("UIGridLayout")
TbGrid.CellSize = UDim2.new(0, 104, 0, 115); TbGrid.CellPadding = UDim2.new(0, 6, 0, 6)
TbGrid.SortOrder = Enum.SortOrder.LayoutOrder; TbGrid.Parent = TbGridScroll

local TbGridStatus = Instance.new("TextLabel")
TbGridStatus.Size = UDim2.new(1, 0, 0, 40); TbGridStatus.BackgroundTransparency = 1
TbGridStatus.Text = "Ketik kata kunci & klik CARI"
TbGridStatus.Font = Enum.Font.Gotham; TbGridStatus.TextSize = 10
TbGridStatus.TextColor3 = Color3.fromRGB(140, 140, 150)
TbGridStatus.ZIndex = 16
TbGridStatus.Parent = TbGridScroll

-- =====================================================
-- PAGE 3: INSERT RBXM FILE
-- =====================================================
local RbxmHeader = Instance.new("Frame")
RbxmHeader.Size = UDim2.new(1, 0, 0, 28); RbxmHeader.BackgroundTransparency = 1; RbxmHeader.ZIndex = 13; RbxmHeader.Parent = PageRBXM

local RbxmTitleLbl = Instance.new("TextLabel")
RbxmTitleLbl.Size = UDim2.new(1, -80, 1, 0); RbxmTitleLbl.BackgroundTransparency = 1
RbxmTitleLbl.Text = "INSERT RBXM FILE"; RbxmTitleLbl.Font = Enum.Font.GothamBold; RbxmTitleLbl.TextSize = 11
RbxmTitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
RbxmTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
RbxmTitleLbl.ZIndex = 14
RbxmTitleLbl.Parent = RbxmHeader

makeBackBtn(RbxmHeader, function() showPage(PageSplash) end)

local RbxmToolbar = Instance.new("Frame")
RbxmToolbar.Size = UDim2.new(1, 0, 0, 28); RbxmToolbar.Position = UDim2.new(0, 0, 0, 32)
RbxmToolbar.BackgroundTransparency = 1; RbxmToolbar.ZIndex = 13; RbxmToolbar.Parent = PageRBXM

local RbxmScanBtn = Instance.new("TextButton")
RbxmScanBtn.Size = UDim2.new(0, 90, 0, 24); RbxmScanBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
RbxmScanBtn.Text = "SCAN FILES"; RbxmScanBtn.Font = Enum.Font.GothamBold; RbxmScanBtn.TextSize = 10
RbxmScanBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
RbxmScanBtn.Active = true; RbxmScanBtn.ZIndex = 15; RbxmScanBtn.Parent = RbxmToolbar; makeCorner(RbxmScanBtn, 6)

local RbxmSLStatus = Instance.new("TextLabel")
RbxmSLStatus.Size = UDim2.new(0, 120, 1, 0); RbxmSLStatus.Position = UDim2.new(0, 96, 0, 0)
RbxmSLStatus.BackgroundTransparency = 1
RbxmSLStatus.Text = "[AUTO-SOURCE: ON]"
RbxmSLStatus.Font = Enum.Font.GothamBold; RbxmSLStatus.TextSize = 9
RbxmSLStatus.TextColor3 = Color3.fromRGB(120, 220, 120)
RbxmSLStatus.TextXAlignment = Enum.TextXAlignment.Left
RbxmSLStatus.ZIndex = 14
RbxmSLStatus.Parent = RbxmToolbar

local RbxmCountLbl = Instance.new("TextLabel")
RbxmCountLbl.Size = UDim2.new(1, -230, 1, 0); RbxmCountLbl.Position = UDim2.new(0, 220, 0, 0)
RbxmCountLbl.BackgroundTransparency = 1
RbxmCountLbl.Text = "[.] Klik SCAN untuk mencari file .rbxm"
RbxmCountLbl.Font = Enum.Font.Gotham; RbxmCountLbl.TextSize = 9
RbxmCountLbl.TextColor3 = Color3.fromRGB(140, 140, 150)
RbxmCountLbl.TextXAlignment = Enum.TextXAlignment.Left
RbxmCountLbl.ZIndex = 14
RbxmCountLbl.Parent = RbxmToolbar

local RbxmScroll = Instance.new("ScrollingFrame")
RbxmScroll.Size = UDim2.new(1, -12, 1, -66); RbxmScroll.Position = UDim2.new(0, 6, 0, 62)
RbxmScroll.BackgroundColor3 = Color3.fromRGB(17, 17, 22); RbxmScroll.BorderSizePixel = 0
RbxmScroll.ScrollBarThickness = 3; RbxmScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
RbxmScroll.ZIndex = 14
RbxmScroll.Parent = PageRBXM; makeCorner(RbxmScroll, 8); makeStroke(RbxmScroll, Color3.fromRGB(255,255,255), 1, 0.78)

local RbxmList = Instance.new("UIListLayout")
RbxmList.Padding = UDim.new(0, 5); RbxmList.SortOrder = Enum.SortOrder.LayoutOrder; RbxmList.Parent = RbxmScroll
local RbxmPad = Instance.new("UIPadding")
RbxmPad.PaddingTop = UDim.new(0, 6); RbxmPad.PaddingLeft = UDim.new(0, 6); RbxmPad.PaddingRight = UDim.new(0, 6); RbxmPad.Parent = RbxmScroll

local RbxmEmpty = Instance.new("TextLabel")
RbxmEmpty.Size = UDim2.new(1, 0, 0, 40); RbxmEmpty.BackgroundTransparency = 1
RbxmEmpty.Text = "Belum ada file .rbxm ditemukan. Klik SCAN FILES."
RbxmEmpty.Font = Enum.Font.Gotham; RbxmEmpty.TextSize = 10
RbxmEmpty.TextColor3 = Color3.fromRGB(140, 140, 150)
RbxmEmpty.ZIndex = 15
RbxmEmpty.Parent = RbxmScroll

-- =====================================================
-- LOGIC: SMART INSERT ASSET ID
-- =====================================================
local function smartInsert(assetId)
    local numId = tonumber(assetId)
    if not numId then return false, "ID tidak valid" end
    if clipFn then pcall(clipFn, tostring(numId)) end
    local insertOk, method = false, ""

    pcall(function()
        local objs = game:GetObjects("rbxassetid://"..tostring(numId))
        if objs and #objs > 0 then
            for _, o in ipairs(objs) do
                o.Parent = workspace
                applyStudioLiteProps(o)
                loadAssetsToSLServer(o)
                if o:IsA("Model") and LP.Character then
                    local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then pcall(function() o:MoveTo(hrp.Position + hrp.CFrame.LookVector * 7) end) end
                end
            end
            insertOk = true; method = "GetObjects + SL Props"
        end
    end)

    if serverFuncs then
        pcall(function()
            serverFuncs:InvokeServer("LoadMeshToRuntimeMeshes", numId)
            if not insertOk then insertOk = true; method = "SL ServerFunctions"
            else method = method .. " + SL Server" end
        end)
    end

    return insertOk, (method ~= "" and method or "ID Disalin ke Clipboard")
end

-- =====================================================
-- LOGIC: SMART INSERT RBXM DENGAN AUTO-EXTRACT
-- =====================================================
local SCAN_PATHS = {
    "workspace",
    "Delta/workspace",
    "delta/workspace",
    "Android/Delta/workspace",
    "/sdcard/Delta/workspace",
    "../workspace",
    "."
}

local function safeReadFile(p)
    if not readfile then return nil end
    local ok, d = pcall(readfile, p)
    return ok and d or nil
end

local function parseRBXMSources(raw)
    local sources = {}
    if not raw or #raw < 30 then return sources end
    for src in raw:gmatch("([^\0\r\n][^\0]+[\r\n]+[^\0]+)") do
        if src:find("function") or src:find("local ") or src:find("return") or src:find("require") then
            local nameMatch = src:match("([%a_][%w_]*)%s*=%s*function") or src:match("local%s+([%a_][%w_]*)") or "Script"
            sources[nameMatch] = src
        end
    end
    for name, code in raw:gmatch('<Item class="[%w]+" referent="[^"]+">%s*<Properties>%s*<string name="Name">([^<]+)</string>.-<ProtectedString name="Source"><%!%[CDATA%[(.-)%]%]></ProtectedString>') do
        sources[name] = code
    end
    return sources
end

local function smartInsertRbxm(filePath, fileName)
    local insertOk, statusMsg = false, ""
    local data = safeReadFile(filePath)

    if data and #data > 0 then
        task.spawn(function()
            local sources = parseRBXMSources(data)
            for k, v in pairs(sources) do
                storeScriptSource(k, v)
            end
            local baseName = fileName:gsub("%.rbxm.*", "")
            for _, v in pairs(sources) do
                storeScriptSource(baseName, v)
                break
            end
        end)
    end

    local function setupObjects(objs)
        for _, o in ipairs(objs) do
            o.Parent = workspace
            applyStudioLiteProps(o)
            loadAssetsToSLServer(o)

            for _, s in ipairs(o:GetDescendants()) do
                if s:IsA("LuaSourceContainer") then
                    pcall(function()
                        if s.Source and #s.Source > 0 then
                            storeScriptSource(s, s.Source)
                        end
                    end)
                end
            end

            if o:IsA("Model") and LP.Character then
                local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
                if hrp then pcall(function() o:MoveTo(hrp.Position + hrp.CFrame.LookVector * 6) end) end
            end
        end
    end

    if customAsset then
        pcall(function()
            local url = customAsset(filePath)
            if url then
                local objs = game:GetObjects(url)
                if objs and #objs > 0 then
                    setupObjects(objs)
                    insertOk = true; statusMsg = "customAsset OK"
                end
            end
        end)
    end

    if not insertOk then
        pcall(function()
            local objs = game:GetObjects("rbxasset://" .. filePath)
            if objs and #objs > 0 then
                setupObjects(objs)
                insertOk = true; statusMsg = "rbxasset:// OK"
            end
        end)
    end

    if not insertOk and data and writefile and customAsset then
        pcall(function()
            local tmpName = "bce_tmp_" .. fileName
            writefile(tmpName, data)
            local url2 = customAsset(tmpName)
            if url2 then
                local objs2 = game:GetObjects(url2)
                if objs2 and #objs2 > 0 then
                    setupObjects(objs2)
                    insertOk = true; statusMsg = "readfile+tmp OK"
                end
            end
            pcall(function() if delfile then delfile(tmpName) end end)
        end)
    end

    return insertOk, statusMsg
end

local function safeListFiles(p)
    if not listfilesFn then return nil end
    local ok, f = pcall(listfilesFn, p); return ok and f or nil
end
local function getFileName(p) return p:match("([^/\\]+)$") or p end

local function getAllRbxmFiles()
    local result, seen = {}, {}
    if not listfilesFn then return result end
    local function scanDeep(folder, depth)
        if depth > 4 or seen[folder] then return end
        seen[folder] = true
        local files = safeListFiles(folder)
        if not files then return end
        for _, path in ipairs(files) do
            local lp = path:lower()
            if (lp:sub(-5) == ".rbxm" or lp:sub(-6) == ".rbxmx") and not seen[path] then
                seen[path] = true; table.insert(result, {path=path, name=getFileName(path)})
            elseif not path:lower():match("%.[%a%d]+$") then
                scanDeep(path, depth + 1)
            end
        end
    end
    for _, p in ipairs(SCAN_PATHS) do if safeListFiles(p) then scanDeep(p, 0) end end
    return result
end

local function renderRbxmCards()
    for _, c in ipairs(RbxmScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    RbxmCountLbl.Text = "[.] Scanning..."
    local files = getAllRbxmFiles()
    RbxmEmpty.Visible = (#files == 0)
    if #files == 0 then
        RbxmCountLbl.Text = not listfilesFn and "[!] listfiles() tidak support" or "[!] Tidak ada file .rbxm"
        return
    end
    RbxmCountLbl.Text = string.format("[OK] %d file ditemukan", #files)
    for _, file in ipairs(files) do
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -12, 0, 50); card.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        card.BorderSizePixel = 0; card.Parent = RbxmScroll; makeCorner(card, 7); makeStroke(card, Color3.fromRGB(255,255,255), 1, 0.85)

        local fileIcon = Instance.new("TextLabel")
        fileIcon.Size = UDim2.new(0, 36, 0, 36); fileIcon.Position = UDim2.new(0, 5, 0.5, -18)
        fileIcon.BackgroundColor3 = Color3.fromRGB(28, 28, 34); fileIcon.Text = ".rbxm"
        fileIcon.Font = Enum.Font.GothamBold; fileIcon.TextSize = 7
        fileIcon.TextColor3 = Color3.fromRGB(200, 200, 210); fileIcon.Parent = card; makeCorner(fileIcon, 6)

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(1, -195, 0, 18); nameLbl.Position = UDim2.new(0, 48, 0, 7)
        nameLbl.BackgroundTransparency = 1; nameLbl.Text = file.name
        nameLbl.Font = Enum.Font.GothamBold; nameLbl.TextSize = 11
        nameLbl.TextColor3 = Color3.fromRGB(240, 240, 245)
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left; nameLbl.TextTruncate = Enum.TextTruncate.AtEnd; nameLbl.Parent = card

        local pathLbl = Instance.new("TextLabel")
        pathLbl.Size = UDim2.new(1, -195, 0, 13); pathLbl.Position = UDim2.new(0, 48, 0, 28)
        pathLbl.BackgroundTransparency = 1; pathLbl.Text = file.path
        pathLbl.Font = Enum.Font.Gotham; pathLbl.TextSize = 8
        pathLbl.TextColor3 = Color3.fromRGB(130, 130, 140)
        pathLbl.TextXAlignment = Enum.TextXAlignment.Left; pathLbl.TextTruncate = Enum.TextTruncate.AtEnd; pathLbl.Parent = card

        -- Tombol Edit Langsung
        local edBtn = Instance.new("TextButton")
        edBtn.Size = UDim2.new(0, 50, 0, 30); edBtn.Position = UDim2.new(1, -135, 0.5, -15)
        edBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
        edBtn.Text = "EDIT"
        edBtn.Font = Enum.Font.GothamBold
        edBtn.TextSize = 9
        edBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        edBtn.Active = true
        edBtn.ZIndex = 16
        edBtn.Parent = card
        makeCorner(edBtn, 6)
        makeStroke(edBtn, Color3.fromRGB(255,255,255), 1, 0.7)

        edBtn.Activated:Connect(function()
            local code = lookupScriptSource(file.name:gsub("%.rbxm.*", ""))
            if not code or code == "" then
                local d = safeReadFile(file.path)
                if d then
                    local s = parseRBXMSources(d)
                    for _, v in pairs(s) do code = v; break end
                end
            end
            openInEditor(file.name:gsub("%.rbxm.*", ""), code or "-- Script tidak ditemukan")
        end)

        local insertBtn = Instance.new("TextButton")
        insertBtn.Size = UDim2.new(0, 70, 0, 30); insertBtn.Position = UDim2.new(1, -76, 0.5, -15)
        insertBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        insertBtn.Text = "INSERT"
        insertBtn.Font = Enum.Font.GothamBold
        insertBtn.TextSize = 9
        insertBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        insertBtn.Active = true
        insertBtn.ZIndex = 16
        insertBtn.Parent = card
        makeCorner(insertBtn, 6)

        insertBtn.Activated:Connect(function()
            if insertBtn.Text == "..." then return end
            insertBtn.Text = "..."
            task.spawn(function()
                local ok, msg = smartInsertRbxm(file.path, file.name)
                if insertBtn and insertBtn.Parent then
                    if ok then
                        insertBtn.Text = "OK!"; insertBtn.BackgroundColor3 = Color3.fromRGB(180, 255, 180)
                        RbxmCountLbl.Text = "[OK] "..file.name.." ("..msg..")"
                    else
                        insertBtn.Text = "GAGAL"; insertBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 180)
                        RbxmCountLbl.Text = "[!] Gagal load RBXM"
                    end
                    task.delay(2.5, function()
                        if insertBtn and insertBtn.Parent then
                            insertBtn.Text = "INSERT"; insertBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        end
                    end)
                end
            end)
        end)
    end
    RbxmScroll.CanvasSize = UDim2.new(0, 0, 0, RbxmList.AbsoluteContentSize.Y + 20)
end

RbxmScanBtn.Activated:Connect(renderRbxmCards)

local function inspectAsset(id, name, creator)
    currentInspId = tostring(id)
    TbDetThumb.Image = "rbxthumb://type=Asset&id="..currentInspId.."&w=150&h=150"
    TbDetName.Text = name or "Memuat..."; TbDetCreator.Text = "By: @"..(creator or "?"); TbDetId.Text = "ID: "..currentInspId
    local num = tonumber(currentInspId)
    if num and num > 0 then
        task.spawn(function()
            local s, info = pcall(function() return MarketplaceService:GetProductInfo(num) end)
            if s and info and info.Name and TbDetName and TbDetName.Parent then
                TbDetName.Text = info.Name
                TbDetCreator.Text = "By: @"..((info.Creator and info.Creator.Name) or creator or "?")
            end
        end)
    end
end

TbDetCopy.Activated:Connect(function()
    if currentInspId ~= "" and clipFn then
        pcall(clipFn, currentInspId); TbDetCopy.Text = "COPIED!"
        task.delay(1.2, function() if TbDetCopy and TbDetCopy.Parent then TbDetCopy.Text = "COPY ID" end end)
    end
end)

TbDetInsert.Activated:Connect(function()
    if currentInspId ~= "" then
        TbDetInsert.Text = "..."
        task.spawn(function()
            local ok, m = smartInsert(currentInspId)
            TbStatusLbl.Text = "[.] "..m
            if TbDetInsert and TbDetInsert.Parent then
                TbDetInsert.Text = ok and "OK!" or "COPIED"
                task.delay(1.5, function() if TbDetInsert and TbDetInsert.Parent then TbDetInsert.Text = "INSERT" end end)
            end
        end)
    end
end)

local function queryMarketplace(catId, query)
    local enc = HttpService:UrlEncode(query)
    local urls = {
        ("https://apis.roproxy.com/toolbox-service/v1/marketplace/%d?keyword=%s&limit=30"):format(catId, enc),
        ("https://apis.roblox.com/toolbox-service/v1/marketplace/%d?keyword=%s&limit=30"):format(catId, enc),
    }
    for _, url in ipairs(urls) do
        local s, r = pcall(function() return httpRequest({Url=url,Method="GET",Headers={["User-Agent"]="RobloxStudio/WinInet"}}) end)
        if s and r and r.StatusCode == 200 then
            local ds, parsed = pcall(function() return HttpService:JSONDecode(r.Body) end)
            if ds and parsed and parsed.data and #parsed.data > 0 then return parsed.data end
        end
    end
    return nil
end

local function renderGrid(data)
    for _, c in ipairs(TbGridScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    if not data or #data == 0 then TbGridStatus.Visible = true; TbGridStatus.Text = "Tidak ada aset ditemukan."; return end
    TbGridStatus.Visible = false
    local first = data[1]
    if first then inspectAsset(first.id or (first.asset and first.asset.id) or "0", first.name or (first.asset and first.asset.name) or "Asset", (first.creator and first.creator.name) or "?") end
    for _, item in ipairs(data) do
        local assetId = tostring(item.id or (item.asset and item.asset.id) or "0")
        local assetName = item.name or (item.asset and item.asset.name) or "Asset"
        local creator = (item.creator and item.creator.name) or "?"
        local card = Instance.new("Frame")
        card.BackgroundColor3 = Color3.fromRGB(22, 22, 27); card.BorderSizePixel = 0; card.Parent = TbGridScroll
        makeCorner(card, 6); makeStroke(card, Color3.fromRGB(255,255,255), 1, 0.88)
        local thumb = Instance.new("ImageLabel")
        thumb.Size = UDim2.new(1, -8, 0, 50); thumb.Position = UDim2.new(0, 4, 0, 4)
        thumb.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
        thumb.Image = "rbxthumb://type=Asset&id="..assetId.."&w=150&h=150"; thumb.Parent = card; makeCorner(thumb, 5)
        local nameL = Instance.new("TextLabel")
        nameL.Size = UDim2.new(1, -8, 0, 14); nameL.Position = UDim2.new(0, 4, 0, 56)
        nameL.BackgroundTransparency = 1; nameL.Text = assetName
        nameL.Font = Enum.Font.GothamBold; nameL.TextSize = 8; nameL.TextColor3 = Color3.fromRGB(240, 240, 240)
        nameL.TextXAlignment = Enum.TextXAlignment.Left; nameL.TextTruncate = Enum.TextTruncate.AtEnd; nameL.Parent = card
        local subL = Instance.new("TextLabel")
        subL.Size = UDim2.new(1, -8, 0, 12); subL.Position = UDim2.new(0, 4, 0, 70)
        subL.BackgroundTransparency = 1; subL.Text = "@"..creator
        subL.Font = Enum.Font.Gotham; subL.TextSize = 7; subL.TextColor3 = Color3.fromRGB(140, 140, 150)
        subL.TextXAlignment = Enum.TextXAlignment.Left; subL.TextTruncate = Enum.TextTruncate.AtEnd; subL.Parent = card
        local btnRow = Instance.new("Frame")
        btnRow.Size = UDim2.new(1, -8, 0, 17); btnRow.Position = UDim2.new(0, 4, 1, -21); btnRow.BackgroundTransparency = 1; btnRow.Parent = card
        local iBtn = Instance.new("TextButton")
        iBtn.Size = UDim2.new(0.5, -2, 1, 0); iBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        iBtn.Text = "INSERT"; iBtn.Font = Enum.Font.GothamBold; iBtn.TextSize = 8
        iBtn.TextColor3 = Color3.fromRGB(0, 0, 0); iBtn.Active = true; iBtn.Parent = btnRow; makeCorner(iBtn, 4)
        local cBtn = Instance.new("TextButton")
        cBtn.Size = UDim2.new(0.5, -2, 1, 0); cBtn.Position = UDim2.new(0.5, 2, 0, 0)
        cBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255); cBtn.Text = "COPY"
        cBtn.Font = Enum.Font.GothamBold; cBtn.TextSize = 8
        cBtn.TextColor3 = Color3.fromRGB(0, 0, 0); cBtn.Active = true; cBtn.Parent = btnRow; makeCorner(cBtn, 4)

        cBtn.Activated:Connect(function()
            if clipFn then pcall(clipFn, assetId); cBtn.Text = "OK!"
                task.delay(1.2, function() if cBtn and cBtn.Parent then cBtn.Text = "COPY" end end) end
        end)
        iBtn.Activated:Connect(function()
            iBtn.Text = "..."; TbStatusLbl.Text = "[.] Inserting "..assetId
            task.spawn(function()
                local ok, m = smartInsert(assetId); TbStatusLbl.Text = "[.] "..m
                if iBtn and iBtn.Parent then
                    iBtn.Text = ok and "OK!" or "COPY"
                    task.delay(1.2, function() if iBtn and iBtn.Parent then iBtn.Text = "INSERT" end end)
                end
            end)
        end)

        local hitbox = Instance.new("TextButton")
        hitbox.Size = UDim2.new(1, 0, 0, 86); hitbox.BackgroundTransparency = 1; hitbox.Text = ""; hitbox.Active = true; hitbox.Parent = card
        hitbox.Activated:Connect(function() inspectAsset(assetId, nameL.Text, creator) end)

        task.spawn(function()
            local num = tonumber(assetId); if not num then return end
            local s, info = pcall(function() return MarketplaceService:GetProductInfo(num) end)
            if s and info and info.Name and nameL and nameL.Parent then
                nameL.Text = info.Name; subL.Text = "@"..((info.Creator and info.Creator.Name) or creator)
            end
        end)
    end
    TbGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TbGridScroll.CanvasSize = UDim2.new(0, 0, 0, TbGrid.AbsoluteContentSize.Y + 10)
    end)
    TbGridScroll.CanvasSize = UDim2.new(0, 0, 0, TbGrid.AbsoluteContentSize.Y + 10)
end

local function execSearch()
    if TbSearchBox.Text ~= "" then
        TbGridStatus.Visible = true; TbGridStatus.Text = "Searching..."
        TbStatusLbl.Text = "[.] Mencari: "..TbSearchBox.Text
        task.spawn(function()
            local data = queryMarketplace(selectedCat, TbSearchBox.Text)
            renderGrid(data); TbStatusLbl.Text = "[.] Selesai"
        end)
    end
end
TbSearchBtn.Activated:Connect(execSearch)
TbSearchBox.FocusLost:Connect(function(enter) if enter then execSearch() end end)

TbInsertIdBtn.Activated:Connect(function()
    local id = TbIdBox.Text:gsub("%D+", "")
    if id ~= "" then
        inspectAsset(id, "Memuat...", "?"); TbInsertIdBtn.Text = "..."
        task.spawn(function()
            local ok, m = smartInsert(id); TbStatusLbl.Text = "[.] "..m
            if TbInsertIdBtn and TbInsertIdBtn.Parent then
                TbInsertIdBtn.Text = ok and "OK!" or "COPIED"
                task.delay(1.5, function() if TbInsertIdBtn and TbInsertIdBtn.Parent then TbInsertIdBtn.Text = "INSERT" end end)
            end
        end)
    end
end)

print("[BLUExCrown] ENGINE v5.6 PERFECT LOADED")
