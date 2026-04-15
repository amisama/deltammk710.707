--[[
    ============================================
    ROBLOX STAT TRACKER v2.0 (GUI + Accurate)
    ============================================
    Tracker framework dengan GUI in-game.
    Sailor Piece adapter sudah di-tune dari explorer scan.
    
    Compatible: Codex, Delta, Fluxus, Synapse, dll
    ============================================
]]

-- ============================================
-- SERVICES
-- ============================================
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- ============================================
-- CONFIG - EDIT INI
-- ============================================
local CONFIG = {
    -- GANTI API_URL ke VPS nanti kalau sudah deploy
    -- Cloudflared tunnel URL (berubah tiap restart cloudflared!)
    API_URL = "https://partition-sas-xbox-dennis.trycloudflare.com/api",
    API_KEY = "cmo05eiyy0004iwtpnfcdw5ib",
    SEND_INTERVAL = 60,
    MAX_RETRIES = 3,
    RETRY_DELAY = 5,
    DEBUG = true,
}

-- ============================================
-- GUI
-- ============================================
local GUI = {}
local guiLog = {}

function GUI.create()
    local old = LocalPlayer.PlayerGui:FindFirstChild("TrackerGui")
    if old then old:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TrackerGui"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Small floating panel (bottom-right)
    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.new(0, 300, 0, 180)
    panel.Position = UDim2.new(1, -310, 1, -190)
    panel.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    panel.BackgroundTransparency = 0.15
    panel.BorderSizePixel = 0
    panel.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = panel

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(60, 200, 120)
    stroke.Thickness = 1.5
    stroke.Parent = panel

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 0, 24)
    title.Position = UDim2.new(0, 8, 0, 4)
    title.BackgroundTransparency = 1
    title.Text = "STAT TRACKER v2.0"
    title.TextColor3 = Color3.fromRGB(60, 200, 120)
    title.TextSize = 12
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = panel

    -- Status dot
    GUI.statusDot = Instance.new("Frame")
    GUI.statusDot.Size = UDim2.new(0, 8, 0, 8)
    GUI.statusDot.Position = UDim2.new(1, -50, 0, 12)
    GUI.statusDot.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
    GUI.statusDot.BorderSizePixel = 0
    GUI.statusDot.Parent = panel
    Instance.new("UICorner", GUI.statusDot).CornerRadius = UDim.new(1, 0)

    GUI.statusLabel = Instance.new("TextLabel")
    GUI.statusLabel.Size = UDim2.new(0, 40, 0, 24)
    GUI.statusLabel.Position = UDim2.new(1, -40, 0, 4)
    GUI.statusLabel.BackgroundTransparency = 1
    GUI.statusLabel.Text = "INIT"
    GUI.statusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    GUI.statusLabel.TextSize = 10
    GUI.statusLabel.Font = Enum.Font.GothamBold
    GUI.statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    GUI.statusLabel.Parent = panel

    -- Divider
    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, -16, 0, 1)
    divider.Position = UDim2.new(0, 8, 0, 28)
    divider.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    divider.BorderSizePixel = 0
    divider.Parent = panel

    -- Stats display area (scrolling)
    GUI.statsFrame = Instance.new("ScrollingFrame")
    GUI.statsFrame.Size = UDim2.new(1, -12, 1, -34)
    GUI.statsFrame.Position = UDim2.new(0, 6, 0, 32)
    GUI.statsFrame.BackgroundTransparency = 1
    GUI.statsFrame.BorderSizePixel = 0
    GUI.statsFrame.ScrollBarThickness = 3
    GUI.statsFrame.ScrollBarImageColor3 = Color3.fromRGB(60, 200, 120)
    GUI.statsFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    GUI.statsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    GUI.statsFrame.Parent = panel

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 2)
    layout.Parent = GUI.statsFrame

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 20, 0, 20)
    closeBtn.Position = UDim2.new(1, -24, 0, 4)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    closeBtn.TextSize = 12
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = panel
    closeBtn.MouseButton1Click:Connect(function()
        panel.Visible = not panel.Visible
    end)

    -- Draggable
    local dragging, dragStart, startPos
    panel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = panel.Position
        end
    end)
    panel.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    screenGui.Parent = LocalPlayer.PlayerGui
    GUI.panel = panel
    return screenGui
end

function GUI.setStatus(text, color)
    if GUI.statusLabel then
        GUI.statusLabel.Text = text
        GUI.statusLabel.TextColor3 = color
    end
    if GUI.statusDot then
        GUI.statusDot.BackgroundColor3 = color
    end
end

local lineOrder = 0
function GUI.setLine(key, text, color)
    color = color or Color3.fromRGB(200, 200, 200)

    if not GUI.statsFrame then return end

    -- Update existing or create new
    local existing = GUI.statsFrame:FindFirstChild("line_" .. key)
    if existing then
        existing.Text = text
        existing.TextColor3 = color
        return
    end

    lineOrder = lineOrder + 1
    local label = Instance.new("TextLabel")
    label.Name = "line_" .. key
    label.Size = UDim2.new(1, -4, 0, 16)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color
    label.TextSize = 11
    label.Font = Enum.Font.RobotoMono
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.LayoutOrder = lineOrder
    label.Parent = GUI.statsFrame
end

function GUI.clearLines()
    if not GUI.statsFrame then return end
    for _, child in ipairs(GUI.statsFrame:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    lineOrder = 0
end

-- ============================================
-- HTTP MODULE
-- ============================================
local Http = {}

function Http.post(endpoint, data)
    local url = CONFIG.API_URL .. endpoint
    local jsonData = HttpService:JSONEncode(data)

    -- Detect which HTTP function is available
    local httpFunc = nil
    local httpName = "none"
    if request then
        httpFunc = request; httpName = "request"
    elseif http_request then
        httpFunc = http_request; httpName = "http_request"
    elseif syn and syn.request then
        httpFunc = syn.request; httpName = "syn.request"
    elseif http and http.request then
        httpFunc = http.request; httpName = "http.request"
    elseif fluxus and fluxus.request then
        httpFunc = fluxus.request; httpName = "fluxus.request"
    end

    if not httpFunc then
        GUI.setLine("http_err", "ERROR: No HTTP function found!", Color3.fromRGB(255, 0, 0))
        GUI.setLine("http_avail", "request=" .. tostring(request ~= nil) .. " http_request=" .. tostring(http_request ~= nil), Color3.fromRGB(255, 100, 100))
        return false, nil
    end

    GUI.setLine("http_func", "HTTP: " .. httpName, Color3.fromRGB(150, 150, 150))
    GUI.setLine("http_url", "URL: " .. url, Color3.fromRGB(150, 150, 150))

    local lastErr = ""
    for attempt = 1, CONFIG.MAX_RETRIES do
        GUI.setLine("http_attempt", "Attempt " .. attempt .. "/" .. CONFIG.MAX_RETRIES .. "...", Color3.fromRGB(255, 200, 0))

        local success, response = pcall(function()
            return httpFunc({
                Url = url,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["Authorization"] = "Bearer " .. CONFIG.API_KEY,
                    ["X-Tracker-Version"] = "2.0",
                },
                Body = jsonData,
            })
        end)

        if success and response then
            local code = response.StatusCode or response.status_code or 0
            GUI.setLine("http_code", "Response: " .. tostring(code), Color3.fromRGB(150, 150, 150))
            if code == 200 or code == 201 then
                return true, response
            else
                lastErr = "HTTP " .. tostring(code) .. ": " .. tostring(response.Body or response.body or "")
            end
        elseif not success then
            lastErr = tostring(response)
            GUI.setLine("http_pcall_err", "pcall error: " .. string.sub(lastErr, 1, 80), Color3.fromRGB(255, 80, 80))
        end

        if attempt < CONFIG.MAX_RETRIES then
            task.wait(CONFIG.RETRY_DELAY)
        end
    end

    GUI.setLine("http_final_err", "FAILED: " .. string.sub(lastErr, 1, 100), Color3.fromRGB(255, 0, 0))
    return false, nil
end

-- ============================================
-- GAME DETECTOR
-- ============================================
local GameDetector = {}

GameDetector.GAME_MAP = {
    -- Sailor Piece (dari scan: PlaceId 77747658251236)
    [77747658251236] = "sailor_piece",

    -- Blox Fruits
    [2753915549] = "blox_fruits",

    -- Adopt Me
    [920587237] = "adopt_me",

    -- Pet Simulator X
    [6284583030] = "pet_sim_x",

    -- King Legacy
    [4520749081] = "king_legacy",
}

function GameDetector.detect()
    local placeId = game.PlaceId
    local gameName = GameDetector.GAME_MAP[placeId]

    if gameName then
        return gameName, placeId
    end

    -- Fallback
    local success, info = pcall(function()
        return MarketplaceService:GetProductInfo(placeId)
    end)

    return nil, placeId
end

-- ============================================
-- ADAPTER REGISTRY
-- ============================================
local AdapterRegistry = {}
AdapterRegistry.adapters = {}

function AdapterRegistry.register(name, adapter)
    AdapterRegistry.adapters[name] = adapter
end

function AdapterRegistry.get(name)
    return AdapterRegistry.adapters[name]
end

-- ============================================
-- BASE ADAPTER
-- ============================================
local BaseAdapter = {}
BaseAdapter.__index = BaseAdapter

function BaseAdapter.new(gameName)
    local self = setmetatable({}, BaseAdapter)
    self.gameName = gameName
    return self
end

function BaseAdapter:getStats() return {} end
function BaseAdapter:getInventory(_serverData) return {} end
function BaseAdapter:getCurrency() return {} end
function BaseAdapter:getProgress() return {} end
function BaseAdapter:getServerData() return nil end

function BaseAdapter:collectAll()
    local data = {stats = {}, inventory = {}, currency = {}, progress = {}, serverData = nil}

    local steps = {
        {"serverData", function() data.serverData = self:getServerData() end},
        {"stats",      function() data.stats = self:getStats() end},
        {"inventory",  function() data.inventory = self:getInventory(data.serverData) end},
        {"currency",   function() data.currency = self:getCurrency() end},
        {"progress",   function() data.progress = self:getProgress() end},
    }

    for i, step in ipairs(steps) do
        local stepName = step[1]
        local stepFn   = step[2]
        GUI.setLine("collect_step", "Collect [" .. i .. "/" .. #steps .. "] " .. stepName .. "...", Color3.fromRGB(255, 200, 0))
        local ok, err = pcall(stepFn)
        if not ok then
            GUI.setLine("collect_err_" .. stepName, "WARN: " .. stepName .. " failed: " .. string.sub(tostring(err), 1, 60), Color3.fromRGB(255, 150, 50))
        end
    end

    GUI.setLine("collect_step", "Collect done", Color3.fromRGB(60, 255, 120))
    return data
end

-- ============================================
-- SAILOR PIECE ADAPTER (ACCURATE - from scan)
-- ============================================
--[[
    Confirmed data paths from explorer scan:
    
    leaderstats/
      Bounty (IntValue) = 540007
    
    Data/
      Level (IntValue) = 13000
      Money (IntValue) = 220091798
      Gems (IntValue) = 40605
      Experience (IntValue) = 402710237
      StatPoints (IntValue) = 0
    
    Backpack/
      Combat (Tool)
    
    Character/
      Soul Reaper (Tool) - equipped
      Swordblessed (Accessory) - equipped
    
    Key RemoteFunctions:
      ReplicatedStorage.Remotes.GetPlayerData -> full player data
      ReplicatedStorage.Remotes.GetTotalStats -> stat totals
      ReplicatedStorage.Remotes.GetStorageData -> storage items
      ReplicatedStorage.RemoteFunctions.GetArtifactData -> artifacts
      ReplicatedStorage.RemoteEvents.GetPlayerStats -> player stats
]]

local SailorPieceAdapter = setmetatable({}, {__index = BaseAdapter})
SailorPieceAdapter.__index = SailorPieceAdapter

function SailorPieceAdapter.new()
    return setmetatable(BaseAdapter.new("sailor_piece"), SailorPieceAdapter)
end

function SailorPieceAdapter:getStats()
    local stats = {}

    -- Data folder (CONFIRMED: Player.Data.*)
    local dataFolder = LocalPlayer:FindFirstChild("Data")
    if dataFolder then
        for _, child in ipairs(dataFolder:GetChildren()) do
            if child:IsA("IntValue") or child:IsA("NumberValue") or child:IsA("StringValue") then
                stats[child.Name] = child.Value
            end
        end
    end

    -- leaderstats (CONFIRMED: leaderstats.Bounty)
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        for _, child in ipairs(leaderstats:GetChildren()) do
            if child:IsA("IntValue") or child:IsA("NumberValue") then
                stats[child.Name] = child.Value
            end
        end
    end

    return stats
end

function SailorPieceAdapter:getCurrency()
    local currency = {}

    -- From Data folder (CONFIRMED paths)
    local dataFolder = LocalPlayer:FindFirstChild("Data")
    if dataFolder then
        local money = dataFolder:FindFirstChild("Money")
        local gems = dataFolder:FindFirstChild("Gems")
        if money then currency.Money = money.Value end
        if gems then currency.Gems = gems.Value end
    end

    -- From leaderstats (CONFIRMED)
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        local bounty = leaderstats:FindFirstChild("Bounty")
        if bounty then currency.Bounty = bounty.Value end
    end

    return currency
end

function SailorPieceAdapter:getInventory(_serverData)
    local inventory = {}

    -- 1. Fire RequestInventory and listen for UpdateInventory responses
    --    This is how the game sends inventory data: FireServer -> OnClientEvent
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then return end

        local reqInv = remotes:FindFirstChild("RequestInventory")
        local updateInv = remotes:FindFirstChild("UpdateInventory")
        if not reqInv or not updateInv then return end

        local received = {}
        local conn = updateInv.OnClientEvent:Connect(function(category, items)
            if type(category) == "string" and type(items) == "table" then
                received[category] = items
            end
        end)

        -- Fire request
        reqInv:FireServer()

        -- Wait up to 5 seconds for all categories to arrive
        -- Game sends: Items, Melee, Sword, Power, Accessories, Runes, Auras, Cosmetics
        local start = tick()
        while (tick() - start) < 5 do
            task.wait(0.3)
            -- Stop early if we got the main categories
            if received["Items"] and received["Sword"] and received["Accessories"] then
                task.wait(0.5) -- small extra wait for stragglers
                break
            end
        end

        conn:Disconnect()

        -- Process all received categories
        for category, items in pairs(received) do
            for _, item in ipairs(items) do
                if type(item) == "table" and item.name then
                    local entry = {
                        name = item.name,
                        type = category:lower(),
                        equipped = false,
                        count = item.quantity or 1,
                    }
                    -- Sword blessing level
                    if item.blessingLevel and item.blessingLevel > 0 then
                        entry.blessing = item.blessingLevel
                    end
                    -- Accessory enchant level
                    if item.enchantLevel and item.enchantLevel > 0 then
                        entry.enchant = item.enchantLevel
                    end
                    table.insert(inventory, entry)
                end
            end
        end
    end)

    -- 2. Character equipped items (tools + accessories currently worn)
    local character = LocalPlayer.Character
    if character then
        for _, item in ipairs(character:GetChildren()) do
            if item:IsA("Tool") then
                table.insert(inventory, {name = item.Name, type = "equipped_weapon", equipped = true})
            elseif item:IsA("Accessory") then
                table.insert(inventory, {name = item.Name, type = "equipped_accessory", equipped = true})
            end
        end
    end

    -- 3. Title from BasicStatsCurrencyAndButtonsUI
    pcall(function()
        local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not PlayerGui then return end
        local statsUI = PlayerGui:FindFirstChild("BasicStatsCurrencyAndButtonsUI")
        if not statsUI then return end
        local mainFrame = statsUI:FindFirstChild("MainFrame")
        if not mainFrame then return end
        local levelInfo = mainFrame:FindFirstChild("LevelInfo")
        if not levelInfo then return end
        local titleLabel = levelInfo:FindFirstChild("Title")
        if titleLabel and titleLabel.Text and titleLabel.Text ~= "" then
            local title = titleLabel.Text:match("Title: (.+)") or titleLabel.Text
            table.insert(inventory, {name = title, type = "title", equipped = true})
        end
    end)

    return inventory
end

function SailorPieceAdapter:getServerData()
    -- DISABLED: InvokeServer() hangs indefinitely in this game.
    -- All data is scraped from local GUI elements instead.
    return nil
end

function SailorPieceAdapter:getProgress()
    local progress = {}

    -- Level & exp from Data (CONFIRMED - local, no yield)
    local dataFolder = LocalPlayer:FindFirstChild("Data")
    if dataFolder then
        local level = dataFolder:FindFirstChild("Level")
        local exp = dataFolder:FindFirstChild("Experience")
        local statPoints = dataFolder:FindFirstChild("StatPoints")
        if level then progress.Level = level.Value end
        if exp then progress.Experience = exp.Value end
        if statPoints then progress.StatPoints = statPoints.Value end
    end

    -- Scan ALL player children for extra data folders (safe, local only)
    -- This catches any hidden Value folders the game adds (Race, Clan, Fruit, etc.)
    local scannedFolders = {Data = true, leaderstats = true} -- already scanned above/in getStats
    for _, child in ipairs(LocalPlayer:GetChildren()) do
        if child:IsA("Folder") and not scannedFolders[child.Name] then
            for _, val in ipairs(child:GetChildren()) do
                if val:IsA("IntValue") or val:IsA("NumberValue") or val:IsA("StringValue") or val:IsA("BoolValue") then
                    progress[child.Name .. "_" .. val.Name] = val.Value
                end
            end
        end
    end

    -- Character humanoid stats (health, walkspeed)
    pcall(function()
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                progress.MaxHealth = humanoid.MaxHealth
                progress.WalkSpeed = humanoid.WalkSpeed
                progress.JumpPower = humanoid.JumpPower
            end
        end
    end)

    return progress
end

AdapterRegistry.register("sailor_piece", SailorPieceAdapter)

-- ============================================
-- GENERIC ADAPTER (fallback)
-- ============================================
local GenericAdapter = setmetatable({}, {__index = BaseAdapter})
GenericAdapter.__index = GenericAdapter

function GenericAdapter.new()
    return setmetatable(BaseAdapter.new("generic"), GenericAdapter)
end

function GenericAdapter:getStats()
    local stats = {}

    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        for _, s in ipairs(leaderstats:GetChildren()) do
            if s:IsA("ValueBase") then stats["leaderstats." .. s.Name] = s.Value end
        end
    end

    local commonFolders = {"Stats", "Data", "PlayerStats", "PlayerData", "Values"}
    for _, folderName in ipairs(commonFolders) do
        local folder = LocalPlayer:FindFirstChild(folderName)
        if folder then
            for _, child in ipairs(folder:GetChildren()) do
                if child:IsA("ValueBase") then
                    stats[folderName .. "." .. child.Name] = child.Value
                end
            end
        end
    end

    return stats
end

function GenericAdapter:getCurrency()
    return self:getStats()
end

function GenericAdapter:getInventory()
    local inventory = {}
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            table.insert(inventory, {name = item.Name, type = item.ClassName, equipped = false})
        end
    end
    return inventory
end

AdapterRegistry.register("generic", GenericAdapter)

-- ============================================
-- NUMBER FORMATTER
-- ============================================
local function formatNumber(n)
    if type(n) ~= "number" then return tostring(n) end
    if n >= 1e9 then
        return string.format("%.2fB", n / 1e9)
    elseif n >= 1e6 then
        return string.format("%.2fM", n / 1e6)
    elseif n >= 1e3 then
        return string.format("%.1fK", n / 1e3)
    end
    return tostring(n)
end

-- ============================================
-- MAIN TRACKER
-- ============================================
local Tracker = {}

function Tracker.buildPayload(adapter, gameName, placeId)
    local gameData = adapter:collectAll()

    return {
        player = {
            username = LocalPlayer.Name,
            displayName = LocalPlayer.DisplayName,
            userId = LocalPlayer.UserId,
        },
        game = {
            name = gameName,
            placeId = placeId,
            gameId = game.GameId,
            jobId = game.JobId,
        },
        data = gameData,
        meta = {
            timestamp = os.time(),
            trackerVersion = "2.0",
            executorName = identifyexecutor and identifyexecutor() or "unknown",
        }
    }
end

function Tracker.updateGUI(payload)
    GUI.clearLines()

    local data = payload.data
    local order = 0

    -- Player info
    GUI.setLine("player", "Player: " .. payload.player.username, Color3.fromRGB(255, 255, 255))

    -- Game
    GUI.setLine("game", "Game: " .. payload.game.name, Color3.fromRGB(120, 200, 255))

    -- Separator
    GUI.setLine("sep1", "---", Color3.fromRGB(50, 50, 60))

    -- Stats (sorted display)
    if data.stats then
        local statOrder = {"Level", "Experience", "Money", "Gems", "Bounty", "StatPoints"}
        for _, key in ipairs(statOrder) do
            if data.stats[key] then
                GUI.setLine("stat_" .. key, key .. ": " .. formatNumber(data.stats[key]), Color3.fromRGB(100, 255, 100))
            end
        end
        -- Any remaining stats not in the ordered list
        for key, val in pairs(data.stats) do
            local found = false
            for _, k in ipairs(statOrder) do
                if k == key then found = true; break end
            end
            if not found then
                GUI.setLine("stat_" .. key, key .. ": " .. formatNumber(val), Color3.fromRGB(180, 180, 180))
            end
        end
    end

    -- Currency
    if data.currency then
        for key, val in pairs(data.currency) do
            -- Skip if already shown in stats
            if not data.stats or not data.stats[key] then
                GUI.setLine("cur_" .. key, key .. ": " .. formatNumber(val), Color3.fromRGB(255, 220, 80))
            end
        end
    end

    -- Inventory count
    if data.inventory then
        local toolCount = 0
        local accCount = 0
        local equippedNames = {}
        for _, item in ipairs(data.inventory) do
            if item.type == "tool" then toolCount = toolCount + 1
            elseif item.type == "accessory" then accCount = accCount + 1 end
            if item.equipped then table.insert(equippedNames, item.name) end
        end
        GUI.setLine("sep2", "---", Color3.fromRGB(50, 50, 60))
        GUI.setLine("inv_tools", "Tools: " .. toolCount, Color3.fromRGB(180, 140, 255))
        GUI.setLine("inv_acc", "Accessories: " .. accCount, Color3.fromRGB(180, 140, 255))
        if #equippedNames > 0 then
            GUI.setLine("inv_equipped", "Equipped: " .. table.concat(equippedNames, ", "), Color3.fromRGB(255, 180, 100))
        end
    end

    -- API status
    GUI.setLine("sep3", "---", Color3.fromRGB(50, 50, 60))
    GUI.setLine("api_status", "API: " .. CONFIG.API_URL, Color3.fromRGB(100, 100, 110))
    GUI.setLine("last_update", "Updated: " .. os.date("%H:%M:%S"), Color3.fromRGB(100, 100, 110))
end

function Tracker.sendOnce(adapter, gameName, placeId)
    local payload = Tracker.buildPayload(adapter, gameName, placeId)

    -- Update GUI with latest data
    Tracker.updateGUI(payload)

    -- Send to API
    GUI.setStatus("SEND", Color3.fromRGB(255, 200, 0))
    local success, response = Http.post("/track", payload)

    if success then
        GUI.setStatus("LIVE", Color3.fromRGB(60, 255, 120))
        GUI.setLine("api_result", "Last send: OK", Color3.fromRGB(60, 255, 120))
    else
        GUI.setStatus("FAIL", Color3.fromRGB(255, 80, 80))
        GUI.setLine("api_result", "Last send: FAILED (retrying)", Color3.fromRGB(255, 80, 80))
    end

    return success
end

function Tracker.startLoop(adapter, gameName, placeId)
    -- Send immediately
    Tracker.sendOnce(adapter, gameName, placeId)

    -- Loop
    local tick = 0
    while true do
        task.wait(1)
        tick = tick + 1

        if not LocalPlayer or not LocalPlayer.Parent then
            GUI.setStatus("LEFT", Color3.fromRGB(150, 150, 150))
            break
        end

        -- Countdown display
        local remaining = CONFIG.SEND_INTERVAL - tick
        if remaining > 0 then
            GUI.setLine("next_send", "Next send: " .. remaining .. "s", Color3.fromRGB(100, 100, 110))
        end

        if tick >= CONFIG.SEND_INTERVAL then
            tick = 0
            Tracker.sendOnce(adapter, gameName, placeId)
        end
    end
end

-- ============================================
-- ENTRY POINT
-- ============================================
local function main()
    -- Create GUI
    GUI.create()
    task.wait(0.3)

    GUI.setStatus("INIT", Color3.fromRGB(255, 200, 0))
    GUI.setLine("init", "Initializing tracker...", Color3.fromRGB(200, 200, 200))

    -- Detect game
    local gameName, placeId = GameDetector.detect()

    -- Get adapter
    local adapterClass = nil
    if gameName then
        adapterClass = AdapterRegistry.get(gameName)
    end

    if not adapterClass then
        adapterClass = AdapterRegistry.get("generic")
        gameName = gameName or "unknown"
    end

    local adapter = adapterClass.new()

    GUI.setLine("init", "Game: " .. gameName .. " | Adapter: " .. adapter.gameName, Color3.fromRGB(120, 200, 255))
    task.wait(0.5)

    -- Step 1: Test data collection
    GUI.setLine("step1", "[1] Collecting data...", Color3.fromRGB(255, 200, 0))
    task.wait(0.2)

    local collectOk, collectErr = pcall(function()
        local testData = adapter:collectAll()
        local statCount = 0
        if testData and testData.stats then
            for _ in pairs(testData.stats) do statCount = statCount + 1 end
        end
        GUI.setLine("step1", "[1] Data OK - " .. statCount .. " stats found", Color3.fromRGB(60, 255, 120))
    end)
    if not collectOk then
        GUI.setLine("step1", "[1] COLLECT ERROR: " .. string.sub(tostring(collectErr), 1, 100), Color3.fromRGB(255, 0, 0))
        GUI.setStatus("ERR", Color3.fromRGB(255, 0, 0))
        return
    end
    task.wait(0.2)

    -- Step 2: Test payload build
    GUI.setLine("step2", "[2] Building payload...", Color3.fromRGB(255, 200, 0))
    task.wait(0.2)

    local payload = nil
    local buildOk, buildErr = pcall(function()
        payload = Tracker.buildPayload(adapter, gameName, placeId)
        GUI.setLine("step2", "[2] Payload OK - player: " .. tostring(payload.player.username), Color3.fromRGB(60, 255, 120))
    end)
    if not buildOk then
        GUI.setLine("step2", "[2] BUILD ERROR: " .. string.sub(tostring(buildErr), 1, 100), Color3.fromRGB(255, 0, 0))
        GUI.setStatus("ERR", Color3.fromRGB(255, 0, 0))
        return
    end
    task.wait(0.2)

    -- Step 3: Test JSON encode
    GUI.setLine("step3", "[3] Encoding JSON...", Color3.fromRGB(255, 200, 0))
    task.wait(0.2)

    local jsonOk, jsonErr = pcall(function()
        local json = HttpService:JSONEncode(payload)
        GUI.setLine("step3", "[3] JSON OK - " .. #json .. " bytes", Color3.fromRGB(60, 255, 120))
    end)
    if not jsonOk then
        GUI.setLine("step3", "[3] JSON ERROR: " .. string.sub(tostring(jsonErr), 1, 100), Color3.fromRGB(255, 0, 0))
        GUI.setStatus("ERR", Color3.fromRGB(255, 0, 0))
        return
    end
    task.wait(0.2)

    -- Step 4: Test HTTP
    GUI.setLine("step4", "[4] Testing HTTP...", Color3.fromRGB(255, 200, 0))
    task.wait(0.2)

    local httpAvail = request or http_request or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request)
    if httpAvail then
        GUI.setLine("step4", "[4] HTTP function available", Color3.fromRGB(60, 255, 120))
    else
        GUI.setLine("step4", "[4] NO HTTP FUNCTION!", Color3.fromRGB(255, 0, 0))
        GUI.setStatus("ERR", Color3.fromRGB(255, 0, 0))
        return
    end
    task.wait(0.3)

    -- All checks passed, start loop
    GUI.setLine("step5", "[5] Starting tracker loop...", Color3.fromRGB(60, 255, 120))
    task.wait(0.3)

    Tracker.startLoop(adapter, gameName, placeId)
end

local success, err = pcall(main)
if not success then
    -- Show error on GUI if it exists
    pcall(function()
        GUI.setStatus("CRASH", Color3.fromRGB(255, 0, 0))
        GUI.setLine("crash_err", "CRASH: " .. string.sub(tostring(err), 1, 150), Color3.fromRGB(255, 0, 0))
    end)
    -- Also show notification
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Tracker Error",
            Text = tostring(err),
            Duration = 15,
        })
    end)
end
