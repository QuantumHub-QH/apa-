-- [[ AI STUDIO LITE - UNIVERSAL FIX ENGINE ]] --

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- 1. SAFE HTTP REQUEST HANDLER (Cegah Nil Value Error)
local function safeHttpRequest(options)
    -- Cek fungsi bawaan executor
    local executorReq = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
    
    if type(executorReq) == "function" then
        return executorReq(options)
    else
        -- Fallback jika dijalankan di dalam Roblox Studio / Studio Lite game
        local responseBody = HttpService:PostAsync(options.Url, options.Body, Enum.HttpContentType.ApplicationJson)
        return { Body = responseBody, StatusCode = 200 }
    end
end

-- 2. SAFE GUI PARENT HANDLER
local function getSafeParent()
    if type(gethui) == "function" then
        return gethui()
    end
    local success = pcall(function() local _ = CoreGui.Name end)
    if success and CoreGui then
        return CoreGui
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- ScreenGui Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AI_Studio_Universal"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = getSafeParent()

-- Toggle Button (Tombol Melayang)
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Size = UDim2.new(0, 45, 0, 45)
ToggleBtn.Position = UDim2.new(0.02, 0, 0.4, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
ToggleBtn.Text = "🤖"
ToggleBtn.TextSize = 22
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Active = true
ToggleBtn.Draggable = true
ToggleBtn.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 12)
ToggleCorner.Parent = ToggleBtn

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = Color3.fromRGB(0, 170, 255)
ToggleStroke.Thickness = 2
ToggleStroke.Parent = ToggleBtn

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 320, 0, 230)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -115)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(45, 45, 60)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 0, 35)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🤖 AI Studio Lite (Fix)"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 15
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -30, 0, 5)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
CloseBtn.TextSize = 16
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = MainFrame

-- Prompt Box
local PromptBox = Instance.new("TextBox")
PromptBox.Size = UDim2.new(1, -20, 0, 95)
PromptBox.Position = UDim2.new(0, 10, 0, 40)
PromptBox.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
PromptBox.PlaceholderText = "Ketik ide kamu... (cth: Buat rumah kayu, buat part berputar, buat GUI)"
PromptBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 140)
PromptBox.Text = ""
PromptBox.TextColor3 = Color3.fromRGB(255, 255, 255)
PromptBox.TextSize = 12
PromptBox.Font = Enum.Font.Gotham
PromptBox.TextWrapped = true
PromptBox.TextYAlignment = Enum.TextYAlignment.Top
PromptBox.Parent = MainFrame

local BoxCorner = Instance.new("UICorner")
BoxCorner.CornerRadius = UDim.new(0, 6)
BoxCorner.Parent = PromptBox

-- Generate Button
local GenerateBtn = Instance.new("TextButton")
GenerateBtn.Size = UDim2.new(1, -20, 0, 35)
GenerateBtn.Position = UDim2.new(0, 10, 0, 145)
GenerateBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
GenerateBtn.Text = "✨ Generate Sekarang"
GenerateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
GenerateBtn.TextSize = 13
GenerateBtn.Font = Enum.Font.GothamBold
GenerateBtn.Parent = MainFrame

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 6)
BtnCorner.Parent = GenerateBtn

-- Status Label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 25)
StatusLabel.Position = UDim2.new(0, 10, 0, 190)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Status: Siap dipanggil!"
StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
StatusLabel.TextSize = 11
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Parent = MainFrame

-- UI Events
ToggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

-- AI Execution Engine
local function ProcessAI(userPrompt)
    StatusLabel.Text = "Status: 🧠 AI sedang memproses..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)

    local systemPrompt = [[
    You are a Roblox Lua Script Generator. 
    Output ONLY executable Roblox Lua code without markdown formatting or