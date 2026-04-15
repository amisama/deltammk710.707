--[[
    DIAGNOSE INVENTORY
    Execute ini di Sailor Piece untuk lihat struktur data dari GetPlayerData.
    Hasilnya muncul di GUI dan juga di console.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Simple GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DiagnoseGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local frame = Instance.new("ScrollingFrame")
frame.Size = UDim2.new(0.9, 0, 0.8, 0)
frame.Position = UDim2.new(0.05, 0, 0.1, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
frame.BorderSizePixel = 0
frame.ScrollBarThickness = 6
frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
frame.CanvasSize = UDim2.new(0, 0, 0, 0)
frame.Parent = screenGui

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 2)
layout.Parent = frame

local lineCount = 0

local function addLine(text, color)
    lineCount = lineCount + 1
    color = color or Color3.fromRGB(200, 200, 200)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 0)
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.BackgroundTransparency = 1
    label.TextColor3 = color
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextSize = 11
    label.Font = Enum.Font.RobotoMono
    label.TextWrapped = true
    label.Text = text
    label.LayoutOrder = lineCount
    label.Parent = frame
end

local function addHeader(text)
    addLine("\n=== " .. text .. " ===", Color3.fromRGB(0, 255, 150))
end

-- Serialize a value for display (max depth)
local function serialize(val, depth, maxDepth)
    depth = depth or 0
    maxDepth = maxDepth or 3
    if depth > maxDepth then return "..." end

    local indent = string.rep("  ", depth)

    if type(val) == "table" then
        local lines = {}
        local count = 0
        for k, v in pairs(val) do
            count = count + 1
            if count > 50 then
                table.insert(lines, indent .. "  ... (" .. (count) .. "+ more)")
                break
            end
            local keyStr = tostring(k)
            local valStr = serialize(v, depth + 1, maxDepth)
            table.insert(lines, indent .. "  [" .. keyStr .. "] = " .. valStr)
        end
        if #lines == 0 then return "{}" end
        return "{\n" .. table.concat(lines, "\n") .. "\n" .. indent .. "}"
    else
        return tostring(val) .. " (" .. type(val) .. ")"
    end
end

screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

addHeader("DIAGNOSE INVENTORY - Sailor Piece")
addLine("Player: " .. LocalPlayer.Name)

-- Step 1: Try GetPlayerData
addHeader("STEP 1: GetPlayerData")
local playerData = nil
local pdOk, pdErr = pcall(function()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotes then
        addLine("ERROR: ReplicatedStorage.Remotes not found!", Color3.fromRGB(255, 0, 0))
        return
    end
    local gpd = remotes:FindFirstChild("GetPlayerData")
    if not gpd then
        addLine("ERROR: Remotes.GetPlayerData not found!", Color3.fromRGB(255, 0, 0))
        return
    end
    addLine("Found GetPlayerData, calling InvokeServer()...", Color3.fromRGB(255, 255, 0))
    playerData = gpd:InvokeServer()
    addLine("InvokeServer returned!", Color3.fromRGB(0, 255, 0))
end)

if not pdOk then
    addLine("PCALL ERROR: " .. tostring(pdErr), Color3.fromRGB(255, 0, 0))
end

if playerData == nil then
    addLine("playerData is nil", Color3.fromRGB(255, 100, 100))
elseif type(playerData) ~= "table" then
    addLine("playerData type: " .. type(playerData) .. " = " .. tostring(playerData), Color3.fromRGB(255, 200, 0))
else
    -- Show all top-level keys
    addHeader("STEP 2: Top-level keys in playerData")
    local keys = {}
    for k, v in pairs(playerData) do
        table.insert(keys, k)
        local valType = type(v)
        local preview = ""
        if valType == "table" then
            local count = 0
            for _ in pairs(v) do count = count + 1 end
            preview = "table (" .. count .. " entries)"
        else
            preview = tostring(v) .. " (" .. valType .. ")"
        end
        addLine("  " .. tostring(k) .. " = " .. preview, Color3.fromRGB(100, 200, 255))
    end

    -- Show inventory-related keys in detail
    local inventoryKeys = {"Inventory", "inventory", "Items", "items", "Weapons", "weapons",
        "Accessories", "accessories", "Fruit", "fruit", "Fruits", "fruits",
        "Storage", "storage", "Equipment", "equipment", "Bag", "bag",
        "OwnedWeapons", "ownedWeapons", "OwnedItems", "ownedItems",
        "WeaponInventory", "weaponInventory", "ItemInventory", "itemInventory"}

    addHeader("STEP 3: Inventory-related data (detail)")
    local foundAny = false
    for _, key in ipairs(inventoryKeys) do
        if playerData[key] ~= nil then
            foundAny = true
            addLine("FOUND: playerData." .. key, Color3.fromRGB(0, 255, 0))
            addLine(serialize(playerData[key], 0, 2), Color3.fromRGB(200, 200, 150))
        end
    end

    if not foundAny then
        addLine("No standard inventory keys found!", Color3.fromRGB(255, 200, 0))
        addLine("Dumping ALL keys with table values:", Color3.fromRGB(255, 200, 0))
        for k, v in pairs(playerData) do
            if type(v) == "table" then
                addLine("\nplayerData." .. tostring(k) .. ":", Color3.fromRGB(255, 150, 50))
                addLine(serialize(v, 0, 2), Color3.fromRGB(200, 200, 150))
            end
        end
    end
end

-- Step 4: Also check RequestInventory event
addHeader("STEP 4: Other inventory sources")

-- Check if there's a GetStorageData
pcall(function()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local gsd = remotes:FindFirstChild("GetStorageData")
        if gsd and gsd:IsA("RemoteFunction") then
            addLine("Found GetStorageData, trying...", Color3.fromRGB(255, 255, 0))
            local storageData = gsd:InvokeServer()
            if storageData then
                addLine("GetStorageData returned:", Color3.fromRGB(0, 255, 0))
                addLine(serialize(storageData, 0, 2), Color3.fromRGB(200, 200, 150))
            else
                addLine("GetStorageData returned nil", Color3.fromRGB(255, 100, 100))
            end
        end
    end
end)

addHeader("DONE")
addLine("Screenshot this and send it!", Color3.fromRGB(255, 255, 0))
