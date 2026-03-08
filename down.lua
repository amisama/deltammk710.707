local c = {
    bold = "\27[1m", reset = "\27[0m", dim = "\27[2m",
    red = "\27[31m", green = "\27[32m", yellow = "\27[33m",
    blue = "\27[34m", magenta = "\27[35m", cyan = "\27[36m", white = "\27[37m"
}

local dl_path = "/sdcard/Download/"

local api_url = "https://gofile-clone.mrcy-25d.workers.dev"

function load_database()
    local raw = exec("curl -s " .. api_url .. "/api/cli/all")
    local db = {}
    local folders = {}
    if raw and raw ~= "EMPTY" and raw ~= "ERROR" then
        for line in raw:gmatch("[^\r\n]+") do
            local folder, name, url = line:match("([^|]+)|([^|]+)|([^|]+)")
            if folder and name and url then
                if not db[folder] then 
                    db[folder] = {}
                    table.insert(folders, folder)
                end
                table.insert(db[folder], { name = name, url = url })
            end
        end
    end
    return db, folders
end

local search_prefix = "com.roblox"

function exec(cmd)
    local h = io.popen(cmd)
    local r = h:read("*a")
    h:close()
    return r
end

function su_exec(cmd)
    local h = io.popen("su -c '" .. cmd .. "' 2>&1")
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

function clear_input_buffer()
    -- Drain any pending input safely using shell timeout
    os.execute("sh -c 'while read -r -t 0.1 -n 10000; do :; done'")
end

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

function process_install(folder_name, list)
    show_header()
    print("  " .. c.bold .. c.cyan .. "━━━ " .. folder_name .. " ━━━" .. c.reset .. "\n")
    
    if not list or #list == 0 then
        print("  " .. c.red .. "[!] Folder ini kosong atau server sedang sibuk. Tekan Enter..." .. c.reset)
        clear_input_buffer()
        io.read()
        return
    end

    local rows = {}
    for i, app in ipairs(list) do 
        table.insert(rows, {tostring(i), {color=c.green, text=app.name}, "Install APK dari Gofile"})
    end
    table.insert(rows, {"0", {color=c.red, text="Return"}, "Kembali ke Menu Utama"})
    
    draw_table("APK List", {"ID", "APK Name", "Description"}, rows)
    
    io.write("\n  " .. c.bold .. c.yellow .. "▶  Pilih APK (Contoh: 1-5 | 1,3 | 0): " .. c.reset)
    local input = io.read()
    if input == "0" then return end
    
    local targets = parse_input(input, #list)
    if #targets == 0 then 
        print("\n  " .. c.bold .. c.red .. "[!] Input tidak valid/typo! Tekan Enter..." .. c.reset)
        clear_input_buffer()
        io.read()
        return 
    end

    print("\n  " .. c.bold .. c.yellow .. "[*] Tahap 1: Mendownload file ke " .. c.reset .. c.cyan .. dl_path .. c.reset)
    local files = {}
    for _, idx in ipairs(targets) do
        local app = list[idx]
        local full_path = dl_path .. "temp_" .. idx .. ".apk"
        print("  " .. c.cyan .. "    Downloading: " .. app.name .. c.reset)
        local dl_cmd = string.format("curl -L -# -H 'Accept: application/octet-stream' -o '%s' '%s'", full_path, app.url)
        os.execute(dl_cmd)
        table.insert(files, full_path)
    end

    print("\n  " .. c.bold .. c.green .. "[*] Tahap 2: Menginstall semua file (Root)..." .. c.reset)
    for _, path in ipairs(files) do
        print("  " .. c.yellow .. "    Installing: " .. path .. " ..." .. c.reset)
        local out = su_exec("pm install -r " .. path)
        if out and out:match("Success") then
            print("  " .. c.green .. "    [✓] Success!" .. c.reset)
        else
            print("  " .. c.red .. "    [!] Failed/Info: " .. (out or "No output"):gsub("\n", " ") .. c.reset)
        end
        os.execute("rm " .. path)
    end
    print("\n  " .. c.bold .. c.green .. "[ ✓ ] Installasi Selesai! Tekan Enter..." .. c.reset)
    clear_input_buffer()
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
        clear_input_buffer()
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
        clear_input_buffer()
        io.read()
        return 
    end

    print("  " .. c.yellow .. "[?] Anda akan menghapus " .. #targets .. " package. Yakin? (y/n): " .. c.reset)
    io.write("  ")
    local confirm = io.read()
    if confirm:lower() ~= "y" then
        print("\n  " .. c.bold .. c.red .. "[!] Dibatalkan. Tekan Enter..." .. c.reset)
        clear_input_buffer()
        io.read()
        return
    end

    print("")
    for _, idx in ipairs(targets) do
        if installed[idx] then
            print("  " .. c.red .. "    Deleting: " .. installed[idx] .. " ..." .. c.reset)
            local out = su_exec("pm uninstall " .. installed[idx])
            if out and out:match("Success") then
                print("  " .. c.green .. "    [✓] Success!" .. c.reset)
            else
                print("  " .. c.yellow .. "    [!] Failed/Info: " .. (out or "No output"):gsub("\n", " ") .. c.reset)
            end
        end
    end
    print("\n  " .. c.bold .. c.green .. "[ ✓ ] Uninstall Bersih! Tekan Enter..." .. c.reset)
    clear_input_buffer()
    io.read()
end

-- ==========================================================
-- LOOP MENU UTAMA
-- ==========================================================
while true do
    show_header()
    print("  " .. c.yellow .. "[*] Sinkronisasi Database API..." .. c.reset)
    local db, folder_keys = load_database()
    
    if #folder_keys == 0 then
        print("  " .. c.red .. "\n  [!] Belum ada file APK di web Gofile atau server sibuk. Tekan Enter..." .. c.reset)
        io.read()
    else
        local rows = {}
        for i, folder_name in ipairs(folder_keys) do
            table.insert(rows, {tostring(i), {color=c.green, text=folder_name}, "Buka Folder Cloud (" .. #db[folder_name] .. " File)"})
        end
        
        local uninstall_idx = tostring(#folder_keys + 1)
        local exit_idx = "0"
        
        table.insert(rows, {uninstall_idx, {color=c.magenta, text="Auto Uninstall"}, "Hapus data / client (" .. search_prefix .. ")"})
        table.insert(rows, {exit_idx, {color=c.red, text="Exit"}, "Keluar dari installer"})
        
        show_header()
        draw_table("Gofile Cloud Menu", {"ID", "Folder/Feature", "Description"}, rows)

        io.write("\n  " .. c.bold .. c.yellow .. "▶  Pilih id: " .. c.reset)
        local main_act = io.read()
        local num = tonumber(main_act)

        if main_act == exit_idx then 
            print("\n  " .. c.bold .. c.red .. "Sayonara! — Tools ditutup." .. c.reset .. "\n")
            break
        elseif main_act == uninstall_idx then 
            menu_uninstall()
        elseif num and num >= 1 and num <= #folder_keys then 
            local fname = folder_keys[num]
            process_install(fname, db[fname])
        else
            print("\n  " .. c.red .. "  [!] Pilihan tidak valid." .. c.reset)
            os.execute("sleep 1")
        end
    end
end
