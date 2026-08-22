-- =====================================================
-- SAFE SAVER / COPIER SYSTEM (WORKSPACE COPY REMOVED)
-- =====================================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

local SafeCopier = {}

-- Daftar class yang aman untuk di-copy/save (Bypass protected objects)
local ALLOWED_CLASSES = {
    ["Model"] = true,
    ["Part"] = true,
    ["MeshPart"] = true,
    ["Folder"] = true,
    ["Tool"] = true,
    ["Decal"] = true,
    ["Texture"] = true,
    ["SpecialMesh"] = true
}

-- Fungsi terpisah untuk mengcopy spesifik target saja (Aman & Anti-Kick)
function SafeCopier.CopyTarget(targetInstance)
    if not targetInstance then 
        warn("[SafeCopier] Target tidak ditemukan!")
        return 
    end

    print("[SafeCopier] Memproses copy target: " .. targetInstance.Name)
    
    local clonedObjects = {}
    local counter = 0

    local function processObject(obj)
        -- Skip jika objek tidak aman atau protected
        local success, isA = pcall(function() return obj.ClassName end)
        if not success or not ALLOWED_CLASSES[isA] then return end

        counter = counter + 1
        -- Throttle/jeda tiap 100 objek agar tidak kena Script Execution Timeout / Kick
        if counter % 100 == 0 then
            task.wait()
        end

        -- Clone objek secara aman
        pcall(function()
            local clone = obj:Clone()
            if clone then
                table.insert(clonedObjects, clone)
            end
        end)
    end

    -- Iterasi hanya pada target terdeteksi
    processObject(targetInstance)
    for _, desc in ipairs(targetInstance:GetDescendants()) do
        processObject(desc)
    end

    print("[SafeCopier] Sukses memproses " .. #clonedObjects .. " object tanpa kick!")
    return clonedObjects
end

-- =====================================================
-- HAPUS TOTAL: CopyWorkspace / SaveWorkspace Only
-- (Fitur berbahaya telah dibuang permanen)
-- =====================================================

return SafeCopier