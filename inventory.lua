--[[
    DIAGNOSE INVENTORY - OUTPUT TO CLIPBOARD
    
    INSTRUKSI:
    1. Buka INVENTORY/TAS di game dulu
    2. Execute script ini
    3. Hasil otomatis ke-copy ke clipboard
    4. Paste (Ctrl+V) ke chat
    
    Kalau clipboard gagal, hasil juga muncul di GUI.
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local output = {}
local function log(text)
    table.insert(output, text)
end

log("=== SAILOR PIECE INVENTORY SCAN ===")
log("Player: " .. LocalPlayer.Name)

-- Collect texts from a GUI
local function collectTexts(parent, path, maxDepth, depth)
    depth = depth or 0
    if depth > (maxDepth or 8) then return end
    for _, child in ipairs(parent:GetChildren()) do
        local childPath = path .. "." .. child.Name
        if (child:IsA("TextLabel") or child:IsA("TextButton")) then
            local text = child.Text or ""
            text = text:gsub("%s+", " "):sub(1, 100)
            if text ~= "" and text ~= " " and text ~= "0" and text ~= "x0" and #text > 1 then
                local vis = child.Visible and "V" or "H"
                log("[" .. vis .. "] " .. childPath .. ' = "' .. text .. '"')
            end
        end
        collectTexts(child, childPath, maxDepth, depth + 1)
    end
end

-- Scan InventoryPanelUI
log("\n--- InventoryPanelUI ---")
local invUI = PlayerGui:FindFirstChild("InventoryPanelUI")
if invUI then
    log("FOUND (" .. #invUI:GetDescendants() .. " descendants)")
    collectTexts(invUI, "Inv", 8)
else
    log("NOT FOUND")
end

-- Scan StorageUI
log("\n--- StorageUI ---")
local storageUI = PlayerGui:FindFirstChild("StorageUI")
if storageUI then
    log("FOUND (" .. #storageUI:GetDescendants() .. " descendants)")
    collectTexts(storageUI, "Storage", 8)
else
    log("NOT FOUND")
end

-- Scan BasicStatsCurrencyAndButtonsUI
log("\n--- BasicStatsCurrencyAndButtonsUI ---")
local statsUI = PlayerGui:FindFirstChild("BasicStatsCurrencyAndButtonsUI")
if statsUI then
    log("FOUND")
    collectTexts(statsUI, "Stats", 6)
else
    log("NOT FOUND")
end

-- Scan all player children (non-standard folders)
log("\n--- Player Extra Folders ---")
local skip = {PlayerGui=1, PlayerScripts=1, Backpack=1, StarterGear=1, leaderstats=1, Data=1}
for _, child in ipairs(LocalPlayer:GetChildren()) do
    if not skip[child.Name] then
        local info = child.Name .. " [" .. child.ClassName .. "]"
        if child:IsA("Folder") or child:IsA("Configuration") then
            info = info .. " (" .. #child:GetChildren() .. " children)"
            log(info)
            for _, sub in ipairs(child:GetChildren()) do
                local subInfo = "  " .. sub.Name .. " [" .. sub.ClassName .. "]"
                if sub:IsA("IntValue") or sub:IsA("StringValue") or sub:IsA("NumberValue") or sub:IsA("BoolValue") then
                    subInfo = subInfo .. " = " .. tostring(sub.Value)
                elseif sub:IsA("Folder") then
                    subInfo = subInfo .. " (" .. #sub:GetChildren() .. " children)"
                end
                log(subInfo)
            end
        else
            log(info)
        end
    end
end

-- Scan Backpack detail
log("\n--- Backpack ---")
local bp = LocalPlayer:FindFirstChild("Backpack")
if bp then
    for _, item in ipairs(bp:GetChildren()) do
        log(item.Name .. " [" .. item.ClassName .. "]")
    end
    if #bp:GetChildren() == 0 then log("(empty)") end
end

-- Scan Character
log("\n--- Character ---")
local char = LocalPlayer.Character
if char then
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") or item:IsA("Accessory") then
            log(item.Name .. " [" .. item.ClassName .. "]")
        end
    end
end

-- Build final string
local result = table.concat(output, "\n")

-- Try clipboard
local clipOk = false
pcall(function()
    if setclipboard then
        setclipboard(result)
        clipOk = true
    elseif toclipboard then
        toclipboard(result)
        clipOk = true
    end
end)

-- Also show in small GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DiagClipGui"
screenGui.ResetOnSpawn = false
local lbl = Instance.new("TextLabel")
lbl.Size = UDim2.new(0.6, 0, 0, 40)
lbl.Position = UDim2.new(0.2, 0, 0.05, 0)
lbl.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
lbl.BorderSizePixel = 0
lbl.TextColor3 = clipOk and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 200, 0)
lbl.TextSize = 14
lbl.Font = Enum.Font.GothamBold
lbl.Text = clipOk and "COPIED TO CLIPBOARD! Paste (Ctrl+V) ke chat." or "Clipboard gagal. Hasil di bawah:"
lbl.Parent = screenGui

if not clipOk then
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(0.9, 0, 0.8, 0)
    scroll.Position = UDim2.new(0.05, 0, 0.12, 0)
    scroll.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 6
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = screenGui

    local txtLbl = Instance.new("TextLabel")
    txtLbl.Size = UDim2.new(1, -10, 0, 0)
    txtLbl.AutomaticSize = Enum.AutomaticSize.Y
    txtLbl.BackgroundTransparency = 1
    txtLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    txtLbl.TextXAlignment = Enum.TextXAlignment.Left
    txtLbl.TextSize = 10
    txtLbl.Font = Enum.Font.RobotoMono
    txtLbl.TextWrapped = true
    txtLbl.Text = result
    txtLbl.Parent = scroll
end

screenGui.Parent = PlayerGui
