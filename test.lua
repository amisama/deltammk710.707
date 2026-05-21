-- ============================================================
--  No Mercy Tools  |  Termux CLI  |  Simple & Robust
-- ============================================================

local DL_PATH    = "/sdcard/Download/"
local PKG_PREFIX = "com.roblox"

local GOFILE_FOLDERS = {
    { name = "Delta/A10/32bit/", url = "https://gofile.io/d/RNI0Jf" },
    { name = "Delta/A10/64bit/", url = "https://gofile.io/d/8KFxe0" },
    { name = "Delta/A12/", url = "https://gofile.io/d/s9o09M" },
    { name = "CODEX/A10/", url = "https://gofile.io/d/u2zTYS" },
    { name = "CODEX/A12/", url = "https://gofile.io/d/DTD7Fu" },
    { name = "ARCEUS/A10/", url = "https://gofile.io/d/JdTNI0" },
    { name = "ARCEUS/A12/", url = "https://gofile.io/d/UBXRNf" },





}

local GOFILE_LANG    = "en-US"
local GOFILE_SALT    = "5d4f7g8sd45fsd"
local GOFILE_UA      = "Mozilla/5.0 (Linux; Android 11) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36"
local GOFILE_TOKEN   = os.getenv("GOFILE_TOKEN") or ""
local GOFILE_RETRIES = 8
local GOFILE_WAIT    = 55



local function run(cmd)
    local h = io.popen(cmd .. " 2>/dev/null")
    if not h then return "" end
    local out = h:read("*a") or ""
    h:close()
    return out:match("^%s*(.-)%s*$")   
end


local function run_root(cmd)
    local h = io.popen("su -c '" .. cmd .. "' 2>&1")
    if not h then return "" end
    local out = h:read("*a") or ""
    h:close()
    return out:match("^%s*(.-)%s*$")
end

local function sh_quote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function url_encode(value)
    return tostring(value):gsub("([^%w%-_%.~])", function(c)
        return string.format("%%%02X", c:byte())
    end)
end

local function sha256(value)
    return run("printf %s " .. sh_quote(value) .. " | openssl dgst -sha256 -r | awk '{print $1}'")
end

local function extract_json_string(json, key)
    return json:match('"' .. key .. '"%s*:%s*"([^"]*)"')
end

local function extract_json_object(json, key)
    local key_pos = json:find('"' .. key .. '"%s*:', 1)
    if not key_pos then return nil end

    local start_pos = json:find("{", key_pos)
    if not start_pos then return nil end

    local depth = 0
    local in_string = false
    local escape = false

    for i = start_pos, #json do
        local c = json:sub(i, i)
        if in_string then
            if escape then
                escape = false
            elseif c == "\\" then
                escape = true
            elseif c == '"' then
                in_string = false
            end
        elseif c == '"' then
            in_string = true
        elseif c == "{" then
            depth = depth + 1
        elseif c == "}" then
            depth = depth - 1
            if depth == 0 then
                return json:sub(start_pos, i)
            end
        end
    end

    return nil
end


local function tty_read()
    local tty = io.open("/dev/tty", "r")
    if tty then
        local line = tty:read("*l") or ""
        tty:close()
        return line
    end
    return io.read("*l") or ""
end

local function pause(msg)
    io.write(msg or "\n  Tekan Enter untuk lanjut... ")
    io.flush()
    tty_read()
end


local SEP = string.rep("-", 66)

local function clear()
    os.execute("clear 2>/dev/null || printf '\\033c'")
end

local function header()
    clear()
    print("")
    print("  N O M E R C Y   T O O L S   B O X")
    print("  join discord executor lite free : https://discord.gg/G3ZFezQC6r")
    print("  thank to god for everything :)")
    print("  " .. SEP)
    print("")
end


local function list_menu(title, items, extra_rows)
    print("  [ " .. title .. " ]")
    print("  " .. string.rep("-", 40))
    for i, item in ipairs(items) do
        print(string.format("  %-4s %s", "[" .. i .. "]", item))
    end
    if extra_rows then
        for _, row in ipairs(extra_rows) do
            print(string.format("  %-4s %s", "[" .. row[1] .. "]", row[2]))
        end
    end
    print("  " .. string.rep("-", 40))
end



local function load_db()
    print("  Memuat daftar Gofile...")
    local db, keys = {}, {}

    for _, item in ipairs(GOFILE_FOLDERS) do
        if item.name and item.url and item.url ~= "" then
            db[item.name] = { { name = "Buka folder Gofile", url = item.url, gofile_folder = true } }
            keys[#keys+1] = item.name
        end
    end

    return db, keys
end


local function parse_input(input, max)
    local targets = {}
    if input == "all" then
        for i = 1, max do targets[#targets+1] = i end
        return targets
    end
    for part in input:gmatch("[^,%s]+") do
        local s, e = part:match("^(%d+)-(%d+)$")
        if s then
            for i = tonumber(s), tonumber(e) do
                if i >= 1 and i <= max then targets[#targets+1] = i end
            end
        else
            local n = tonumber(part)
            if n and n >= 1 and n <= max then targets[#targets+1] = n end
        end
    end
    return targets
end

local function gofile_content_id(url)
    return tostring(url):match("gofile%.io/d/([^/?#]+)")
        or tostring(url):match("gofile%.io/%?c=([^&?#]+)")
        or tostring(url):match("^gofile:([^%s]+)$")
end

local function gofile_create_account()
    local raw = run("curl -sS -X POST " ..
        "-H " .. sh_quote("User-Agent: " .. GOFILE_UA) .. " " ..
        "-H " .. sh_quote("X-BL: " .. GOFILE_LANG) .. " " ..
        "-H " .. sh_quote("Origin: https://gofile.io") .. " " ..
        "-H " .. sh_quote("Referer: https://gofile.io/") .. " " ..
        "https://api.gofile.io/accounts")

    local status = extract_json_string(raw, "status")
    local token = extract_json_string(raw, "token")
    if status == "ok" and token and token ~= "" then
        return token
    end
    return nil, status or "account-create-failed"
end

local function gofile_account_token()
    if GOFILE_TOKEN ~= "" then
        return GOFILE_TOKEN
    end

    local cache_path = DL_PATH .. ".gofile_token"
    local f = io.open(cache_path, "r")
    if f then
        local token = (f:read("*a") or ""):match("^%s*(.-)%s*$")
        f:close()
        if token ~= "" then return token end
    end

    local token, err = gofile_create_account()
    if not token then
        return nil, err
    end

    os.execute("mkdir -p " .. sh_quote(DL_PATH))
    f = io.open(cache_path, "w")
    if f then
        f:write(token)
        f:close()
    end

    return token
end

local function gofile_website_token(account_token)
    local raw = GOFILE_UA .. "::" .. GOFILE_LANG .. "::" .. account_token ..
        "::" .. tostring(math.floor(os.time() / 14400)) .. "::" .. GOFILE_SALT
    return sha256(raw)
end

local function gofile_api_headers(account_token)
    return "-H " .. sh_quote("User-Agent: " .. GOFILE_UA) .. " " ..
        "-H " .. sh_quote("Authorization: Bearer " .. account_token) .. " " ..
        "-H " .. sh_quote("X-Website-Token: " .. gofile_website_token(account_token)) .. " " ..
        "-H " .. sh_quote("X-BL: " .. GOFILE_LANG) .. " " ..
        "-H " .. sh_quote("Origin: https://gofile.io") .. " " ..
        "-H " .. sh_quote("Referer: https://gofile.io/")
end

local function gofile_each_file(data_json, callback)
    for object in data_json:gmatch('{[^{}]*"type"%s*:%s*"file"[^{}]*}') do
        local name = extract_json_string(object, "name")
        local link = extract_json_string(object, "link")
        if name and link then
            callback(name, link)
        end
    end
end

local function gofile_find_file(data_json, wanted_name)
    local wanted = tostring(wanted_name):lower()
    local first_link, first_name

    gofile_each_file(data_json, function(name, link)
        if not first_link then
            first_link, first_name = link, name
        end
        if not first_name or name:lower() == wanted or name:lower():find(wanted, 1, true) then
            first_link, first_name = link, name
        end
    end)

    return first_link, first_name
end

local function gofile_get_data(url)
    local content_id = gofile_content_id(url)
    if not content_id then
        return nil, nil, nil, "URL bukan folder Gofile"
    end

    local token, token_err = gofile_account_token()
    if not token then
        return nil, nil, nil, "Gagal membuat/membaca Gofile token: " .. tostring(token_err)
    end

    local api_url = "https://api.gofile.io/contents/" .. url_encode(content_id) ..
        "?cache=false&contentFilter=&page=1&pageSize=1000&sortField=name&sortDirection=1"

    for attempt = 1, GOFILE_RETRIES do
        local raw = run("curl -sS " .. gofile_api_headers(token) .. " " .. sh_quote(api_url))
        local status = extract_json_string(raw, "status")

        if status == "ok" then
            return extract_json_object(raw, "data") or raw, token, content_id
        end

        if status == "error-passwordRequired" then
            return nil, nil, nil, "Folder Gofile butuh password"
        end

        if attempt < GOFILE_RETRIES then
            print(string.format("     [!] Gofile limit/status %s, tunggu %ds (%d/%d)", tostring(status), GOFILE_WAIT, attempt, GOFILE_RETRIES))
            os.execute("sleep " .. tonumber(GOFILE_WAIT))
        else
            return nil, nil, nil, "Gofile gagal: " .. tostring(status or raw)
        end
    end

    return nil, nil, nil, "Gofile retry habis"
end

local function gofile_list_files(url)
    local data, token, _, err = gofile_get_data(url)
    if not data then
        return nil, err
    end

    local list = {}
    gofile_each_file(data, function(name, link)
        if name:lower():match("%.apk$") then
            list[#list+1] = { name = name, url = link, gofile_token = token }
        end
    end)

    if #list == 0 then
        return nil, "Tidak ada APK di folder Gofile"
    end
    return list
end

local function gofile_resolve(url, wanted_name)
    local content_id = gofile_content_id(url)
    if not content_id then
        return url
    end

    local data, token, _, err = gofile_get_data(url)
    if not data then
        return nil, err
    end

    local link, name = gofile_find_file(data, wanted_name)
    if link then
        return link, nil, token, name
    end
    return nil, "Tidak ada file APK di folder Gofile"
end


local function do_install(folder_name, list)
    header()
    print("  [ Install APK : " .. folder_name .. " ]")
    print("")

    if not list or #list == 0 then
        print("  [!] Folder kosong atau daftar tidak terbaca.")
        pause()
        return
    end

    if list[1] and list[1].gofile_folder then
        print("  Membaca isi folder Gofile...")
        local files, err = gofile_list_files(list[1].url)
        if not files then
            print("  [!] " .. tostring(err))
            pause()
            return
        end
        list = files
    end

    local item_names = {}
    for _, app in ipairs(list) do
        item_names[#item_names+1] = app.name
    end
    list_menu("Pilih APK", item_names, { {"0", "Kembali"} })

    io.write("  Pilih (contoh: 1  |  1,3  |  1-5  |  all  |  0): ")
    io.flush()
    local input = tty_read()
    if input == "0" or input == "" then return end

    local targets = parse_input(input, #list)
    if #targets == 0 then
        print("  [!] Input tidak valid.")
        pause()
        return
    end


    print("")
    print("  >> Mendownload " .. #targets .. " file ke " .. DL_PATH)
    local downloaded = {}
    for _, idx in ipairs(targets) do
        local app  = list[idx]
        local dest = DL_PATH .. "tmp_nm_" .. idx .. ".apk"
        print("     Downloading: " .. app.name)

        local download_url, err, gofile_token = app.url, nil, app.gofile_token
        if gofile_content_id(app.url) then
            download_url, err, gofile_token = gofile_resolve(app.url, app.name)
        end
        if not download_url then
            print("     [!] " .. err)
        else
            local extra_headers = "-H " .. sh_quote("Accept: application/octet-stream") .. " " ..
                "-H " .. sh_quote("User-Agent: " .. GOFILE_UA)
            if gofile_token then
                extra_headers = extra_headers .. " -H " .. sh_quote("Cookie: accountToken=" .. gofile_token)
            end

            local sh_cmd = string.format(
                "curl -L --fail -s %s -o %s %s & " ..
                "CPID=$!; T=0; FIRST=1; " ..
                "while kill -0 $CPID 2>/dev/null; do " ..
                "  sleep 1; T=$((T+1)); " ..
                "  SZ=$(du -h %s 2>/dev/null | cut -f1); " ..
                "  if [ \"$FIRST\" = 1 ]; then " ..
                "    printf '     [%%ds] %%s\n' $T \"$SZ\" > /dev/tty; FIRST=0; " ..
                "  else " ..
                "    printf '\033[1A\033[2K     [%%ds] %%s\n' $T \"$SZ\" > /dev/tty; " ..
                "  fi; " ..
                "done; " ..
                "wait $CPID; echo __DONE__",
                extra_headers, sh_quote(dest), sh_quote(download_url), sh_quote(dest)
            )

            local ok = false
            local h  = io.popen(sh_cmd)
            if h then
                for line in h:lines() do
                    if line == "__DONE__" then ok = true; break end
                    io.write("     ")
                    print(line)
                end
                local _, _, code = h:close()
                ok = ok and code == 0
            end

            if ok then
                local sz = run("du -h " .. sh_quote(dest) .. " 2>/dev/null | cut -f1")
                downloaded[#downloaded+1] = { path = dest, name = app.name }
                print("     [OK] Selesai! " .. sz)
            else
                print("     [!] GAGAL download: " .. app.name)
            end
        end
    end


    print("")
    print("  >> Menginstall ...")
    for _, f in ipairs(downloaded) do
        print("     Installing: " .. f.name)
        local out = run_root("pm install -r " .. f.path)
        if out:find("Success") then
            print("     [OK] Sukses!")
        else
           
            print("     [!] " .. out:gsub("[\r\n]+", " "))
        end
        os.execute("rm -f '" .. f.path .. "'")
    end

    print("")
    print("  >> Instalasi selesai.")

    pause()
end


local function do_uninstall()
    header()
    print("  [ Auto Uninstall : " .. PKG_PREFIX .. "* ]")
    print("")
    print("  Scanning packages...")

    local raw = run("pm list packages " .. PKG_PREFIX)
    local pkgs = {}
    for p in raw:gmatch("package:(%S+)") do
        pkgs[#pkgs+1] = p
    end

    if #pkgs == 0 then
        print("  [!] Tidak ada package yang cocok ditemukan.")
        pause()
        return
    end

    list_menu("Package Terinstal", pkgs, { {"0", "Kembali"} })
    io.write("  Pilih (1  |  1,3  |  all  |  0): ")
    io.flush()
    local input = tty_read()
    if input == "0" or input == "" then return end

    local targets = parse_input(input, #pkgs)
    if #targets == 0 then
        print("  [!] Input tidak valid.")
        pause()
        return
    end


    io.write("  Hapus " .. #targets .. " package? (y/n): ")
    io.flush()
    local confirm = tty_read()
    if confirm:lower() ~= "y" then
        print("  Dibatalkan.")
        pause()
        return
    end

    print("")
    for _, idx in ipairs(targets) do
        local pkg = pkgs[idx]
        if pkg then
            print("  Uninstalling: " .. pkg)
            local out = run_root("pm uninstall " .. pkg)
            if out:find("Success") then
                print("  [OK] Sukses!")
            else
                print("  [!] " .. out:gsub("[\r\n]+", " "))
            end
        end
    end

    print("")
    print("  >> Uninstall selesai.")
    pause()
end




local function do_nomercy()
    while true do
        header()
        local db, folder_keys = load_db()

        if #folder_keys == 0 then
            print("  [!] Belum ada daftar Gofile.")
            print("  Isi table GOFILE_FOLDERS di bagian atas script.")
            print("  Contoh: { name = \"ami ayam\", url = \"https://gofile.io/d/8KFxe0\" },")
            pause()
            return
        end

        local menu_labels = {}
        for _, k in ipairs(folder_keys) do
            menu_labels[#menu_labels+1] = k
        end

        list_menu("Gofile NoMercy", menu_labels, { { "0", "Kembali" } })
        io.write("  Pilih: ")
        io.flush()
        local choice = tty_read()
        if choice == "0" or choice == "" then return end

        local num = tonumber(choice)
        if num and num >= 1 and num <= #folder_keys then
            do_install(folder_keys[num], db[folder_keys[num]])
        else
            print("  [!] Pilihan tidak valid.")
            os.execute("sleep 1")
        end
    end
end

local function do_custom()
    header()
    print("  [ Custom Gofile Link ]")
    print("")
    print("  Paste link Gofile, contoh: https://gofile.io/d/UBXRNf")
    io.write("  Link: ")
    io.flush()
    local link = tty_read()
    if not link or link == "" then return end

    link = link:match("^%s*(.-)%s*$")
    if not gofile_content_id(link) then
        print("  [!] Bukan link folder Gofile yang valid.")
        pause()
        return
    end

    do_install("Custom", { { name = "Buka folder Gofile", url = link, gofile_folder = true } })
end


-- ============================================================
-- MAIN LOOP
-- ============================================================

while true do
    header()

    list_menu("T O O L S   B O X", {
        "Gofile NoMercy",
        "Custom Gofile Link",
        "Auto Uninstall  (hapus " .. PKG_PREFIX .. "*)",
    }, { { "0", "Exit" } })

    io.write("  Pilih: ")
    io.flush()
    local choice = tty_read()

    if choice == "0" or choice == "" then
        print("\n  Bye!\n")
        break
    elseif choice == "1" then
        do_nomercy()
    elseif choice == "2" then
        do_custom()
    elseif choice == "3" then
        do_uninstall()
    else
        print("  [!] Pilihan tidak valid.")
        os.execute("sleep 1")
    end
end
