local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- ============================================
-- CONFIG
-- ============================================
local MAX_DEPTH = 5          -- Seberapa dalam scan tree
local MAX_CHILDREN = 100     -- Max children per node (prevent lag)
local SCAN_DELAY = 0         -- Delay antar scan (0 = no delay)

-- Keywords yang menandakan data penting
local IMPORTANT_KEYWORDS = {
    -- Currency
    "coin", "coins", "gold", "money", "cash", "gem", "gems", "diamond",
    "diamonds", "ruby", "rubies", "beli", "berry", "berries", "bounty",
    "token", "tokens", "currency", "dollar", "yen", "pesos",
    
    -- Stats
    "level", "lvl", "exp", "xp", "experience", "stat", "stats",
    "strength", "str", "defense", "def", "health", "hp", "stamina",
    "power", "damage", "dmg", "speed", "spd", "rank",
    "melee", "sword", "gun", "blox", "fruit", "haki",
    
    -- Inventory
    "inventory", "backpack", "item", "items", "weapon", "weapons",
    "tool", "tools", "pet", "pets", "egg", "eggs", "sword", "swords",
    "accessory", "accessories", "fruit", "fruits", "ability",
    
    -- Progress
    "quest", "quests", "mission", "missions", "achievement",
    "progress", "stage", "floor", "area", "island", "sea",
    "world", "zone", "chapter",
    
    -- Player
    "leaderstats", "playerstats", "playerdata", "data", "save",
    "profile", "info", "status"
}

-- ============================================
-- UTILITIES
-- ============================================
local results = {}
local scannedPaths = {}

local function containsKeyword(name)
    local lower = string.lower(name)
    for _, keyword in ipairs(IMPORTANT_KEYWORDS) do
        if string.find(lower, keyword) then
            return true, keyword
        end
    end
    return false, nil
end

local function getValuePreview(obj)
    local success, result = pcall(function()
        if obj:IsA("IntValue") or obj:IsA("NumberValue") then
            return tostring(obj.Value)
        elseif obj:IsA("StringValue") then
            local val = obj.Value
            if #val > 50 then val = string.sub(val, 1, 50) .. "..." end
            return '"' .. val .. '"'
        elseif obj:IsA("BoolValue") then
            return tostring(obj.Value)
        elseif obj:IsA("ObjectValue") then
            if obj.Value then
                return "-> " .. obj.Value:GetFullName()
            end
            return "nil"
        end
        return nil
    end)
    if success then return result end
    return nil
end

local function addResult(category, path, className, value, keyword)
    table.insert(results, {
        category = category,
        path = path,
        className = className,
        value = value,
        keyword = keyword
    })
end

-- ============================================
-- SCANNER
-- ============================================
local function scanObject(obj, depth, category)
    if depth > MAX_DEPTH then return end
    
    local fullName = obj:GetFullName()
    if scannedPaths[fullName] then return end
    scannedPaths[fullName] = true
    
    local success, children = pcall(function()
        return obj:GetChildren()
    end)
    
    if not success then return end
    
    local count = 0
    for _, child in ipairs(children) do
        if count >= MAX_CHILDREN then break end
        count = count + 1
        
        local name = child.Name
        local isImportant, keyword = containsKeyword(name)
        local value = getValuePreview(child)
        
        if isImportant then
            addResult(
                category,
                child:GetFullName(),
                child.ClassName,
                value,
                keyword
            )
        end
        
        -- Juga scan children dari important nodes lebih dalam
        if isImportant or depth < 3 then
            scanObject(child, d
