-- [[ AI STUDIO LITE v2 - SCRIPT & REMOTE EVENT ENGINE ]] --
-- Supported Executors: Delta, Fluxus, Hydrogen, Wave, Codex, etc.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

-- ScreenGui Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AI_Studio_Advanced"
ScreenGui.ResetOnSpawn = false

if gethui then
    ScreenGui.Parent = gethui()
elseif syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = CoreGui
else
    ScreenGui.Parent = CoreGui
end

-- Toggle Button
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Size = UDim2.new(0, 45, 0, 45)
ToggleBtn.Position = UDim2.new(0.02, 0, 0.4, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
ToggleBtn.Text = "⚡"
ToggleBtn.TextSize = 22
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Active = true
ToggleBtn.Draggable = true
ToggleBtn.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 12)
ToggleCorner.Parent = ToggleBtn

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = Color3.fromRGB(0, 200, 255)
ToggleStroke.Thickness = 2
ToggleStroke.Parent = ToggleBtn

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 330, 0, 240)
MainFrame.Position = UDim2.new(0.5, -165, 0.5, -120)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(40, 40, 55)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

-- Title Bar
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 0, 35)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "⚡ AI Studio Script Engine"
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

-- Prompt TextBox
local PromptBox = Instance.new("TextBox")
PromptBox.Size = UDim2.new(1, -20, 0, 100)
PromptBox.Position = UDim2.new(0, 10, 0, 40)
PromptBox.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
PromptBox.PlaceholderText = "Contoh: Bikin tombol teleport jika disentuh, atau buat GUI yang memicu RemoteEvent saat diklik..."
PromptBox.PlaceholderColor3 = Color3.fromRGB(110, 110, 130)
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
GenerateBtn.Position = UDim2.new(0, 10, 0, 150)
GenerateBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 255)
GenerateBtn.Text = "🚀 Generate & Execute Script"
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
StatusLabel.Position = UDim2.new(0, 10, 0, 195)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Status: Siap membuat objek & script!"
StatusLabel.TextColor3 = Color3.fromRGB(140, 140, 160)
StatusLabel.TextSize = 11
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Parent = MainFrame

-- Events
ToggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

-- Advanced AI Generator
local function GenerateWithAI(userPrompt)
    StatusLabel.Text = "Status: 🧠 AI merancang Script & Remote..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    
    local systemPrompt = [[
    You are an expert Roblox Lua Script Developer. The user wants you to build objects, models, GUIs, AND working Lua scripts/RemoteEvents.
    Output ONLY executable Roblox Lua Code without any explanation or markdown formatting (no