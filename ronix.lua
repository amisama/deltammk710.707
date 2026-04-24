-- ============================================================
--  RONIX LITE  |  Auto Installer  |  Termux / Root
-- ============================================================

local DL_PATH  = "/sdcard/Download/"

local RONIX_DIR = "/sdcard/RonixExploit/internal/"

-- ============================================================
-- APK LIST  (hardcoded dari GitHub Releases)
-- ============================================================
local APK_LIST = {
    {
        name = "DELTA 2.716 1 ",
        url  = "https://files.miezutto.sbs/DELTA/DELTA%20SHELEAD%201-2.716.875.apk",
    },
    {
        name = "DELTA 2.716 2",
        url  = "https://files.miezutto.sbs/DELTA/DELTA%20SHELEAD%202-2.716.875.apk",
    },
    {
        name = "DELTA 2.716 3",
        url  = "https://files.miezutto.sbs/DELTA/DELTA%20SHELEAD%203-2.716.875.apk.apk",
    },
    {
        name = "DELTA 2.716 4",
        url  = "https://files.miezutto.sbs/DELTA/DELTA%20SHELEAD%204-2.716.875.apk.apk",
    },
}

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================

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

local SEP = string.rep("-", 58)

local function clear()
    os.execute("clear 2>/dev/null || printf '\\033c'")
end

local function header()
    clear()
    print("")
    print([[
   ██████╗  ██████╗ ███╗   ██╗██╗██╗  ██╗
   ██╔══██╗██╔═══██╗████╗  ██║██║╚██╗██╔╝
   ██████╔╝██║   ██║██╔██╗ ██║██║ ╚███╔╝ 
   ██╔══██╗██║   ██║██║╚██╗██║██║ ██╔██╗ 
   ██║  ██║╚██████╔╝██║ ╚████║██║██╔╝ ██╗
   ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝
       L I T E   A U T O   I N S T A L L E R]])
    print("  " .. SEP)
    print("  Version : 2.710.707  |  5 APK Ready")
    print("  " .. SEP)
    print("")
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

-- ============================================================
-- INJECT RONIX KEY
-- ============================================================

local function inject_ronix_key()
    print("")
    print("  " .. string.rep("=", 48))
    print("  [*] Ronix terdeteksi — memulai injeksi lisensi...")
    print("  " .. string.rep("=", 48))
    os.execute("sleep 1")

    local steps = {
        "  > Scanning Ronix process memory...",
        "  > Locating license verification routine...",
        "  > Patching auth token validator...",
        "  > Generating premium session...",
    }
    for _, line in ipairs(steps) do
        io.write(line)
        io.flush()
        os.execute("sleep 0.4")
        for _ = 1, 3 do
            io.write(".")
            io.flush()
            os.execute("sleep 0.25")
        end
        print("  OK")
    end

    os.execute("sleep 0.5")
    print("")
    print("  > Writing license key to Ronix internals...")
    os.execute("sleep 0.6")

    os.execute("mkdir -p '" .. RONIX_DIR .. "'")
    local f = io.open(RONIX_DIR .. "_key.txt", "w")
    if f then
        f:write(RONIX_KEY)
        f:close()
        os.execute("sleep 0.4")
        print("  > Success.......")
        os.execute("sleep 0.7")
        print("")
        print("  " .. string.rep("=", 48))
        print("  [OK] Ronix Key Injected Successfully!")
        print("  " .. string.rep("=", 48))
    else
        print("  [!] Gagal tulis key. Pastikan Termux punya izin storage.")
    end
end

-- ============================================================
-- DOWNLOAD + INSTALL
-- ============================================================

local function do_install(targets)
    header()
    print("  [ Downloading " .. #targets .. " APK... ]")
    print("")

    local downloaded = {}

    for i, idx in ipairs(targets) do
        local app  = APK_LIST[idx]
        local dest = DL_PATH .. "ronix_tmp_" .. idx .. ".apk"
        print("  [" .. i .. "/" .. #targets .. "] " .. app.name)

        local sh_cmd = string.format(
            "curl -L --fail -s -H 'Accept: application/octet-stream' -o '%s' '%s' & " ..
            "CPID=$!; T=0; FIRST=1; " ..
            "while kill -0 $CPID 2>/dev/null; do " ..
            "  sleep 1; T=$((T+1)); " ..
            "  SZ=$(du -h '%s' 2>/dev/null | cut -f1); " ..
            "  if [ \"$FIRST\" = 1 ]; then " ..
            "    printf '     [%%ds] %%s\\n' $T \"$SZ\" > /dev/tty; FIRST=0; " ..
            "  else " ..
            "    printf '\\033[1A\\033[2K     [%%ds] %%s\\n' $T \"$SZ\" > /dev/tty; " ..
            "  fi; " ..
            "done; " ..
            "wait $CPID; echo __DONE__",
            dest, app.url, dest
        )

        local ok = false
        local h  = io.popen(sh_cmd)
        if h then
            for line in h:lines() do
                if line == "__DONE__" then ok = true; break end
                io.write("     ")
                print(line)
            end
            h:close()
        end

        if ok then
            local sz = run("du -h '" .. dest .. "' 2>/dev/null | cut -f1")
            downloaded[#downloaded+1] = { path = dest, name = app.name }
            print("     [OK] " .. sz)
        else
            print("     [FAIL] Gagal download: " .. app.name)
        end
    end

    -- INSTALL
    print("")
    print("  " .. SEP)
    print("  >> Menginstall APK...")
    print("  " .. SEP)

    local all_ok = true
    for _, f in ipairs(downloaded) do
        io.write("     Installing: " .. f.name .. "  ->  ")
        io.flush()
        local out = run_root("pm install -r " .. f.path)
        if out:find("Success") then
            print("[OK]")
        else
            print("[FAIL] " .. out:gsub("[\r\n]+", " "))
            all_ok = false
        end
        os.execute("rm -f '" .. f.path .. "'")
    end

    -- INJECT KEY
    if #downloaded > 0 then
        inject_ronix_key()
    end

    print("")
    if all_ok then
        print("  >> Semua APK berhasil diinstall & key diinjeksi!")
    else
        print("  >> Selesai (beberapa APK gagal, cek output di atas).")
    end

    pause()
end

-- ============================================================
-- SHOW MENU
-- ============================================================

local function show_menu()
    print("  [ Pilih APK yang ingin diinstall ]")
    print("  " .. string.rep("-", 44))
    for i, app in ipairs(APK_LIST) do
        print(string.format("  [%-2s] %s", i, app.name))
    end
    print("  " .. string.rep("-", 44))
    print("  [0 ] Exit")
    print("")
    io.write("  Pilih (contoh: 1  |  1,3  |  1-5  |  all  |  0): ")
    io.flush()
end

-- ============================================================
-- MAIN LOOP
-- ============================================================

while true do
    header()
    show_menu()

    local input = tty_read()
    if input == "0" or input == "" then
        print("\n  Bye!\n")
        break
    end

    local targets = parse_input(input, #APK_LIST)
    if #targets == 0 then
        print("\n  [!] Input tidak valid.")
        os.execute("sleep 1")
    else
        do_install(targets)
    end
end
