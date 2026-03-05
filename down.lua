local cyan, green, yellow, red, reset = "\27[36m", "\27[32m", "\27[33m", "\27[31m", "\27[0m"
local dl_path = "/sdcard/Download/"

-- ==========================================================
-- DATABASE APK
-- ==========================================================
local database = {
    ["Same HWID"] = {
        { name = "Same HWID 01", url = "https://github.com/mouchiell/d3lt4l1t3/releases/download/2.710.707-02/NO.MERCY.DELTA.LITE.SAME.HWID.01-2.710.707_2.apk" },
        { name = "Same HWID 02", url = "https://github.com/mouchiell/d3lt4l1t3/releases/download/2.710.707-02/NO.MERCY.DELTA.LITE.SAME.HWID.02-2.710.707_2.apk" },
        { name = "Same HWID 03", url = "https://github.com/mouchiell/d3lt4l1t3/releases/download/2.710.707-02/NO.MERCY.DELTA.LITE.SAME.HWID.03-2.710.707_2.apk" },
        { name = "Same HWID 04", url = "https://github.com/mouchiell/d3lt4l1t3/releases/download/2.710.707-02/NO.MERCY.DELTA.LITE.SAME.HWID.04-2.710.707_2.apk" },
        { name = "Same HWID 05", url = "https://github.com/mouchiell/d3lt4l1t3/releases/download/2.710.707-02/NO.MERCY.DELTA.LITE.SAME.HWID.05-2.710.707_2.apk" },
        { name = "Same HWID 06", url = "https://github.com/mouchiell/d3lt4l1t3/releases/download/2.710.707-02/NO.MERCY.DELTA.LITE.SAME.HWID.06-2.710.707.apk" },
    },
    ["Not Same HWID"] = {
        { name = "Not Same HWID 01", url = "https://github.com/mouchiell/d3lt4l1t3/releases/download/2.710.707-02/NO.MERCY.DELTA.LITE.01-2.710.707.apk" },
        { name = "Not Same HWID 02", url = "https://github.com/mouchiell/d3lt4l1t3/releases/download/2.710.707-02/NO.MERCY.DELTA.LITE.02-2.710.707.apk" },
        { name = "Not Same HWID 03", url = "https://github.com/mouchiell/d3lt4l1t3/releases/download/2.710.707-02/NO.MERCY.DELTA.LITE.03-2.710.707.apk" },
        { name = "Not Same HWID 04", url = "https://github.com/mouchiell/d3lt4l1t3/releases/download/2.710.707-02/NO.MERCY.DELTA.LITE.04-2.710.707.apk" },
        { name = "Not Same HWID 05", url = "https://github.com/mouchiell/d3lt4l1t3/releases/download/2.710.707-02/NO.MERCY.DELTA.LITE.05-2.710.707.apk" },
    }
}

local search_prefix = "com.roblox"

function exec(cmd)
    local h = io.popen(cmd)
    local r = h:read("*a")
    h:close()
    return r
end

function parse_input(input, max)
    local targets = {}
    if input == "all" then
        for i = 1, max do table.insert(targets, i) end
    else
        for part in input:gmatch("([^,%s]+)") do
            local s, e = part:match("(%d+)-(%d+)")
            if s and e then
                for i = tonumber(s), tonumber(e) do table.insert(targets, i) end
            else
                local n = tonumber(part)
                if n then table.insert(targets, n) end
            end
        end
    end
    return targets
end

function process_install(category_name)
    local list = database[category_name]
    os.execute("clear")
    print(cyan .. "=== [" .. category_name .. " MODE] ===" .. reset)
    for i, app in ipairs(list) do print(i .. ") " .. app.name) end
    print("0) Kembali ke Menu Utama")
    io.write(yellow .. "\nPilih APK (Contoh: 1-5 | 1,3 | 0): " .. reset)
    local input = io.read()
    if input == "0" then return end
    
    local targets = parse_input(input, #list)
    if #targets == 0 then return end

    print(yellow .. "\n[*] Tahap 1: Mendownload file ke " .. dl_path .. reset)
    local files = {}
    for _, idx in ipairs(targets) do
        local app = list[idx]
        local full_path = dl_path .. "temp_" .. idx .. ".apk"
        print(cyan .. "\nDownloading: " .. app.name .. reset)
        os.execute(string.format("curl -L -# -o '%s' '%s'", full_path, app.url))
        table.insert(files, full_path)
    end

    print(green .. "\n[*] Tahap 2: Menginstall semua file (Root)..." .. reset)
    for _, path in ipairs(files) do
        print(yellow .. "Installing: " .. path .. reset)
        os.execute("su -c 'pm install -r " .. path .. "'")
        os.execute("rm " .. path)
    end
    print(green .. "\n[ DONE ] Selesai! Tekan Enter...")
    io.read()
end

function menu_uninstall()
    os.execute("clear")
    print(red .. "=== [UNINSTALL MODE] ===" .. reset)
    print(yellow .. "[*] Scanning packages: " .. search_prefix .. "..." .. reset)
    local raw = exec("pm list packages | grep " .. search_prefix)
    local installed = {}
    for line in raw:gmatch("package:(%S+)") do table.insert(installed, line) end
    
    if #installed == 0 then 
        print(red .. "Gak ada package ditemukan. Tekan Enter..." .. reset)
        io.read()
        return 
    end

    for i, pkg in ipairs(installed) do print(i .. ") " .. pkg) end
    print("0) Kembali ke Menu Utama")
    io.write(yellow .. "\nPilih buat dihapus (1-5 | all | 0): " .. reset)
    local input = io.read()
    if input == "0" then return end

    local targets = parse_input(input, #installed)
    for _, idx in ipairs(targets) do
        if installed[idx] then
            print(red .. "Deleting: " .. installed[idx] .. reset)
            os.execute("su -c 'pm uninstall " .. installed[idx] .. "' > /dev/null 2>&1")
        end
    end
    print(green .. "\n[ DONE ] Bersih! Tekan Enter...")
    io.read()
end

-- ==========================================================
-- LOOP MENU UTAMA (Biar gak langsung close)
-- ==========================================================
while true do
    os.execute("clear")
    print(cyan .. "=== GITHUB MANAGER PRO ===" .. reset)
    print("1) Same HWID A10 (6 APK)")
    print("2) Not Same HWID A10 (5 APK)")
    print("3) Auto Uninstall (" .. search_prefix .. ")")
    print(red .. "0) Keluar (Exit)" .. reset)
    io.write(yellow .. "\nPilih Menu > " .. reset)
    local main_act = io.read()

    if main_act == "1" then 
        process_install("Same HWID")
    elseif main_act == "2" then 
        process_install("Not Same HWID")
    elseif main_act == "3" then 
        menu_uninstall()
    elseif main_act == "0" then 
        print(cyan .. "\nBabay Ami! 👋" .. reset)
        break -- Keluar dari perulangan
    else
        print(red .. "\nPilihan salah cok! Tekan Enter..." .. reset)
        io.read()
    end
end