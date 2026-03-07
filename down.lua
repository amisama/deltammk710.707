local c = {
    bold = "\27[1m", reset = "\27[0m", dim = "\27[2m",
    red = "\27[31m", green = "\27[32m", yellow = "\27[33m",
    blue = "\27[34m", magenta = "\27[35m", cyan = "\27[36m", white = "\27[37m"
}

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
                for i = tonumber(s), tonumber(e) do 
                    if i >= 1 and i <= max then table.insert(targets, i) end
                end
            else
                local n = tonumber(part)
                if n and n >= 1 and n <= max then table.insert(targets, n) end
            end
        end
    end
    return targets
end

-- ==========================================================
-- UI HELPERS (Hachitool Rich-style)
-- ==========================================================
function pad(str, target_len)
    if #str > target_len then
        return str:sub(1, target_len - 3) .. "..."
    end
    return str .. string.rep(" ", math.max(0, target_len - #str))
end

function draw_table(title, headers, rows)
    local w1, w2, w3 = 4, 30, 36
    
    print("  " .. c.bold .. c.white .. "╭" .. string.rep("─", w1+2) .. "┬" .. string.rep("─", w2+2) .. "┬" .. string.rep("─", w3+2) .. "╮" .. c.reset)
    print("  " .. c.bold .. c.white .. "│ " .. c.cyan .. pad(headers[1], w1) .. c.reset .. c.bold .. c.white .. " │ " .. c.white .. pad(headers[2], w2) .. c.reset .. c.bold .. c.white .. " │ " .. c.dim .. pad(headers[3], w3) .. c.reset .. c.bold .. c.white .. " │" .. c.reset)
    print("  " .. c.bold .. c.white .. "├" .. string.rep("─", w1+2) .. "┼" .. string.rep("─", w2+2) .. "┼" .. string.rep("─", w3+2) .. "┤" .. c.reset)
    for _, row in ipairs(rows) do
        local id_text = row[1]
        local feat_color = row[2].color
        local feat_text = row[2].text
        local desc_text = row[3]
        
        print("  " .. c.bold .. c.white .. "│ " .. c.reset .. c.cyan .. pad(id_text, w1) .. c.reset .. c.bold .. c.white .. " │ " .. feat_color .. pad(feat_text, w2) .. c.reset .. c.bold .. c.white .. " │ " .. c.dim .. pad(desc_text, w3) .. c.reset .. c.bold .. c.white .. " │" .. c.reset)
    end
    print("  " .. c.bold .. c.white .. "╰" .. string.rep("─", w1+2) .. "┴" .. string.rep("─", w2+2) .. "┴" .. string.rep("─", w3+2) .. "╯" .. c.reset)
end

function show_header()
    os.execute("clear")
    local banner = c.bold .. c.cyan .. [[
  _   _         __  __                     
 | \ | | ___   |  \/  | ___ _ __ ___ _   _ 
 |  \| |/ _ \  | |\/| |/ _ \ '__/ __| | | |
 | |\  | (_) | | |  | |  __/ | | (__| |_| |
 |_| \_|\___/  |_|  |_|\___|_|  \___|\__, |
                                     |___/ ]] .. c.reset

    for line in banner:gmatch("([^\n]*)\n?") do
        if line ~= "" then print("    " .. line) end
    end
    print("")
    print("  ╭─────────────────────────────────────────────────────────────────╮")
    print("  │ " .. c.bold .. c.yellow .. "No Mercy Tools v1.0" .. c.reset .. "   " .. c.green .. "Status: Active" .. c.reset .. "     " .. c.magenta .. "Termux Mode: Target" .. c.reset .. " │")
    print("  ╰─────────────────────────────────────────────────────────────────╯\n")
end

-- ==========================================================
-- CORE LOGIC
-- ==========================================================

function process_install(category_name)
    local list = database[category_name]
    show_header()
    print("  " .. c.bold .. c.cyan .. "━━━ " .. category_name .. " Mode ━━━" .. c.reset .. "\n")
    
    local rows = {}
    for i, app in ipairs(list) do 
        table.insert(rows, {tostring(i), {color=c.green, text=app.name}, "Install APK file via curl"})
    end
    table.insert(rows, {"0", {color=c.red, text="Return"}, "Kembali ke Menu Utama"})
    
    draw_table("APK List", {"ID", "APK Name", "Description"}, rows)
    
    io.write("\n  " .. c.bold .. c.yellow .. "▶  Pilih APK (Contoh: 1-5 | 1,3 | 0): " .. c.reset)
    local input = io.read()
    if input == "0" then return end
    
    local targets = parse_input(input, #list)
    if #targets == 0 then 
        print("\n  " .. c.bold .. c.red .. "[!] Input tidak valid/typo! Tekan Enter..." .. c.reset)
        io.read()
        return 
    end

    print("\n  " .. c.bold .. c.yellow .. "[*] Tahap 1: Mendownload file ke " .. c.reset .. c.cyan .. dl_path .. c.reset)
    local files = {}
    for _, idx in ipairs(targets) do
        local app = list[idx]
        local full_path = dl_path .. "temp_" .. idx .. ".apk"
        print("  " .. c.cyan .. "    Downloading: " .. app.name .. c.reset)
        os.execute(string.format("curl -L -# -o '%s' '%s'", full_path, app.url))
        table.insert(files, full_path)
    end

    print("\n  " .. c.bold .. c.green .. "[*] Tahap 2: Menginstall semua file (Root)..." .. c.reset)
    for _, path in ipairs(files) do
        print("  " .. c.yellow .. "    Installing: " .. path .. c.reset)
        os.execute("su -c 'pm install -r " .. path .. "' < /dev/null")
        os.execute("rm " .. path)
    end
    os.execute("stty sane")
    print("\n  " .. c.bold .. c.green .. "[ ✓ ] Installasi Selesai! Tekan Enter..." .. c.reset)
    io.read()
end

function menu_uninstall()
    show_header()
    print("  " .. c.bold .. c.cyan .. "━━━ Uninstall Mode ━━━" .. c.reset .. "\n")
    print("  " .. c.yellow .. "[*] Scanning packages (" .. search_prefix .. ")..." .. c.reset)
    
    local raw = exec("pm list packages | grep " .. search_prefix)
    local installed = {}
    for line in raw:gmatch("package:(%S+)") do table.insert(installed, line) end
    
    if #installed == 0 then 
        print("  " .. c.bold .. c.red .. "[!] Tidak ada package ditemukan. Tekan Enter..." .. c.reset)
        io.read()
        return 
    end

    local rows = {}
    for i, pkg in ipairs(installed) do
        table.insert(rows, {tostring(i), {color=c.magenta, text=pkg}, "Package Terinstal"})
    end
    table.insert(rows, {"0", {color=c.red, text="Return"}, "Kembali ke Menu Utama"})
    
    draw_table("Uninstall Packages", {"ID", "Package Name", "Description"}, rows)

    io.write("\n  " .. c.bold .. c.yellow .. "▶  Pilih buat dihapus (1-5 | all | 0): " .. c.reset)
    local input = io.read()
    if input == "0" then return end

    local targets = parse_input(input, #installed)
    if #targets == 0 then 
        print("\n  " .. c.bold .. c.red .. "[!] Input tidak valid/typo! Tekan Enter..." .. c.reset)
        io.read()
        return 
    end

    for _, idx in ipairs(targets) do
        if installed[idx] then
            print("  " .. c.red .. "    Deleting: " .. installed[idx] .. c.reset)
            os.execute("su -c 'pm uninstall " .. installed[idx] .. "' < /dev/null > /dev/null 2>&1")
        end
    end
    os.execute("stty sane")
    print("\n  " .. c.bold .. c.green .. "[ ✓ ] Uninstall Bersih! Tekan Enter..." .. c.reset)
    io.read()
end

-- ==========================================================
-- LOOP MENU UTAMA
-- ==========================================================
while true do
    show_header()
    
    local rows = {
        {"1", {color=c.green, text="Same HWID A10"}, "Koleksi Same HWID (6 APK)"},
        {"2", {color=c.green, text="Not Same HWID A10"}, "Koleksi Not Same HWID (5 APK)"},
        {"3", {color=c.magenta, text="Auto Uninstall"}, "Hapus data / client (" .. search_prefix .. ")"},
        {"0", {color=c.red, text="Exit"}, "Keluar dari installer"}
    }
    draw_table("Main Functions", {"ID", "Feature", "Description"}, rows)

    io.write("\n  " .. c.bold .. c.yellow .. "▶  Pilih menu: " .. c.reset)
    local main_act = io.read()

    if main_act == "1" then 
        process_install("Same HWID")
    elseif main_act == "2" then 
        process_install("Not Same HWID")
    elseif main_act == "3" then 
        menu_uninstall()
    elseif main_act == "0" then 
        print("\n  " .. c.bold .. c.red .. "Sayonara! — Tools ditutup." .. c.reset .. "\n")
        break
    else
        print("\n  " .. c.red .. "  [!] Pilihan tidak valid." .. c.reset)
        os.execute("sleep 1")
    end
end
