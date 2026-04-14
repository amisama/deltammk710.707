local DumpedData = {}
local MaxRecursionDepth = 7 -- Batasi kedalaman rekursi untuk mencegah output yang terlalu besar dan loop tak terbatas.
local VisitedInstances = {} -- Digunakan untuk melacak instance yang sudah dikunjungi agar tidak terjadi loop rekursi tak terbatas.

-- Fungsi pembantu untuk mendapatkan nilai properti dengan aman, menghindari error untuk properti yang tidak ada atau dilindungi.
local function safeGetProperty(instance, propName)
    local success, value = pcall(function() return instance[propName] end)
    if success then
        -- Filter tipe kompleks yang sulit diserialisasi atau dibaca.
        if type(value) ~= "table" and type(value) ~= "userdata" and type(value) ~= "function" then
            return tostring(value) -- Konversi ke string untuk output yang konsisten.
        else
            return "[Tipe Kompleks]"
        end
    end
    return nil -- Properti tidak dapat diakses atau tidak ada.
end

-- Fungsi rekursif untuk menjelajahi dan mengumpulkan data dari instance.
local function DumpInstanceRecursive(instance, currentPath, currentDepth)
    -- Hentikan rekursi jika instance tidak valid, kedalaman maksimum tercapai, atau sudah dikunjungi.
    if not instance or currentDepth > MaxRecursionDepth or VisitedInstances[instance] then
        return
    end

    VisitedInstances[instance] = true -- Tandai instance ini sebagai sudah dikunjungi.

    local instanceInfo = {
        Path = currentPath,
        ClassName = instance.ClassName,
        Name = instance.Name,
        Properties = {}
    }

    -- Coba dapatkan properti umum yang berguna.
    instanceInfo.Properties.Parent = safeGetProperty(instance, "Parent")
    instanceInfo.Properties.Archivable = safeGetProperty(instance, "Archivable")

    -- Penanganan khusus untuk ValueObjects (IntValue, StringValue, NumberValue, dll.)
    if instance:IsA("ValueBase") then
        instanceInfo.Properties.Value = safeGetProperty(instance, "Value")
    end

    -- Penanganan khusus untuk LocalScript (untuk mendapatkan kode sumbernya).
    if instance:IsA("LocalScript") then
        local success, source = pcall(function() return instance.Source end)
        if success and source then
            instanceInfo.ScriptSource = source
        else
            instanceInfo.ScriptSource = "[Sumber tidak dapat diakses atau kosong]"
        end
    end

    -- Tambahkan informasi yang terkumpul ke tabel dump utama.
    table.insert(DumpedData, instanceInfo)

    -- Proses anak-anak (children) secara rekursif.
    for _, child in ipairs(instance:GetChildren()) do
        local childPath = currentPath .. "." .. child.Name
        DumpInstanceRecursive(child, childPath, currentDepth + 1)
    end
end

-- Mulai proses dumping dari layanan game utama.
print("KRY5.2 Dump Initiated: Mengumpulkan data game yang dapat diakses sisi klien...")

-- Layanan yang biasanya relevan dan dapat diakses dari sisi klien.
local servicesToScan = {
    game.Workspace,
    game:GetService("Players").LocalPlayer, -- Fokus pada data pemain lokal.
    game:GetService("ReplicatedStorage"),
    game:GetService("StarterGui"),
    game:GetService("Lighting"),
    game:GetService("SoundService"),
    game:GetService("Teams"), -- Jika game menggunakan tim.
    game:GetService("CoreGui"), -- Terkadang berisi hal-hal yang berguna untuk exploit.
    game:GetService("Debris"), -- Mungkin berisi objek sementara.
    game:GetService("CollectionService") -- Berguna untuk tag, meskipun mendapatkan tag langsung lebih sulit.
}

for _, service in ipairs(servicesToScan) do
    if service then -- Pastikan layanan ada sebelum mencoba dump.
        DumpInstanceRecursive(service, "game." .. service.Name, 1)
    end
end

-- Konversi data yang terkumpul ke string JSON.
local HttpService = game:GetService("HttpService")
local jsonOutput = HttpService:JSONEncode(DumpedData)

-- Cetak hasilnya ke konsol exploit.
print("\n--- KRY5.2 DUMP SELESAI ---")
print("Total instance dan skrip yang di-dump: " .. #DumpedData)
print("\nOutput JSON (salin seluruh blok ini):")
print(jsonOutput)
print("\n-- Akhir Dump --")
print("Output ini bisa sangat besar. Tempelkan ke editor teks atau penampil JSON untuk analisis lebih mudah.")

-- Opsional: Jika exploit Anda memiliki fungsi clipboard, Anda bisa menggunakannya.
-- Contoh untuk Synapse X:
-- setclipboard(jsonOutput)
-- print("\nOutput JSON berhasil disalin ke clipboard!")
