-- [[ INJEKTOR RBXM & RBXL (XML BASED) ]] --
-- Dibuat untuk Delta Executor

local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

-- Hapus GUI lama jika ada
if CoreGui:FindFirstChild("InjektorRBX") then
    CoreGui.InjektorRBX:Destroy()
end

-- [[ MEMBUAT GUI ]] --
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "InjektorRBX"
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 400, 0, 500)
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
MainFrame.Active = true
MainFrame.Draggable = true -- Bisa didrag

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "Injektor rbxm dan rbxl"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20
Title.Parent = MainFrame

local SearchBar = Instance.new("TextBox")
SearchBar.Size = UDim2.new(1, -40, 0, 35)
SearchBar.Position = UDim2.new(0, 20, 0, 50)
SearchBar.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
SearchBar.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBar.PlaceholderText = "Cari file..."
SearchBar.Font = Enum.Font.Gotham
SearchBar.TextSize = 14
SearchBar.Parent = MainFrame

local SearchCorner = Instance.new("UICorner")
SearchCorner.CornerRadius = UDim.new(0, 6)
SearchCorner.Parent = SearchBar

local FileList = Instance.new("ScrollingFrame")
FileList.Size = UDim2.new(1, -40, 1, -120)
FileList.Position = UDim2.new(0, 20, 0, 100)
FileList.BackgroundTransparency = 1
FileList.ScrollBarThickness = 4
FileList.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Parent = FileList

-- [[ LOGIK PARSING (BACA FILE) ]] --

local function ExtractXML(fileContent)
    -- Logika dasar untuk mengekstrak Item dari XML
    -- Memprioritaskan Script terlebih dahulu
    local items = {}
    
    for className, content in string.gmatch(fileContent, '<Item class="([^"]+)".->(.-)</Item>') do
        table.insert(items, {
            ClassName = className,
            Content = content
        })
    end
    
    return items
end

local function InjectFile(fileName)
    local success, content = pcall(function()
        return readfile(fileName)
    end)
    
    if not success then
        warn("Gagal membaca file: " .. fileName)
        return
    end
    
    print("Mengekstrak file: " .. fileName)
    local items = ExtractXML(content)
    
    -- Pisahkan script dan non-script untuk prioritas
    local scripts = {}
    local others = {}
    
    for _, item in ipairs(items) do
        if item.ClassName == "Script" or item.ClassName == "LocalScript" or item.ClassName == "ModuleScript" then
            table.insert(scripts, item)
        else
            table.insert(others, item)
        end
    end
    
    local function CreateInstance(item)
        local inst
        local ok, err = pcall(function()
            inst = Instance.new(item.ClassName)
        end)
        
        if not ok or not inst then
            warn("[Injektor] Class tidak terpasang / tidak ditemukan: " .. tostring(item.ClassName))
            return nil
        end
        
        -- Jika ini script, coba cari source code-nya
        if item.ClassName == "Script" or item.ClassName == "LocalScript" or item.ClassName == "ModuleScript" then
            local sourceMatch = string.match(item.Content, '<ProtectedString name="Source"><!%[CDATA%[(.-)%]%]></ProtectedString>')
            if not sourceMatch then
                sourceMatch = string.match(item.Content, '<ProtectedString name="Source">(.-)</ProtectedString>')
            end
            
            -- Catatan: Executor biasanya memblokir pengubahan .Source pada script saat runtime
            pcall(function()
                inst.Source = sourceMatch or "-- Source tidak terbaca"
            end)
        end
        
        inst.Parent = Workspace
        return inst
    end
    
    print("Memproses Scripts...")
    for _, item in ipairs(scripts) do
        CreateInstance(item)
    end
    
    print("Memproses Instances lainnya...")
    for _, item in ipairs(others) do
        CreateInstance(item)
    end
    
    print("Injeksi selesai untuk: " .. fileName)
end

-- [[ LOGIK GUI & SCAN FOLDER ]] --

local fileButtons = {}

local function RefreshList()
    -- Bersihkan list
    for _, btn in pairs(fileButtons) do
        btn:Destroy()
    end
    table.clear(fileButtons)
    
    -- Scan folder Workspace Delta
    local files = {}
    pcall(function()
        files = listfiles("") -- Mengambil semua file di root workspace executor
    end)
    
    for _, filePath in ipairs(files) do
        -- Hanya ambil .rbxm, .rbxmx, .rbxl, .rbxlx
        if filePath:match("%.rbxm$") or filePath:match("%.rbxmx$") or filePath:match("%.rbxl$") or filePath:match("%.rbxlx$") then
            
            -- Ekstrak nama file dari path panjang
            local fileName = filePath:match("([^/\\]+)$") or filePath
            
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 35)
            btn.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Text = "  " .. fileName
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 14
            btn.Parent = FileList
            
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 6)
            btnCorner.Parent = btn
            
            btn.MouseButton1Click:Connect(function()
                InjectFile(filePath)
            end)
            
            table.insert(fileButtons, {Button = btn, Name = string.lower(fileName)})
        end
    end
end

-- Logika Search Bar
SearchBar:GetPropertyChangedSignal("Text"):Connect(function()
    local searchText = string.lower(SearchBar.Text)
    for _, data in ipairs(fileButtons) do
        if string.find(data.Name, searchText) then
            data.Button.Visible = true
        else
            data.Button.Visible = false
        end
    end
end)

-- Jalankan scan pertama kali
RefreshList()

print("GUI Injektor RBXM/RBXL Berhasil Diload!")
