--[[
    DIAGNOSE GUI INVENTORY
    Scan PlayerGui untuk cari dimana items disimpan.
    TIDAK pakai InvokeServer - 100% local, tidak akan hang.
    
    INSTRUKSI: Buka inventory/tas di game DULU sebelum execute script ini!
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Simple GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DiagnoseGuiInv"
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

screenGui.Parent = PlayerGui

addHeader("GUI INVENTORY SCAN")
addLine("Player: " .. LocalPlayer.Name)

-- Step 1: Find InventoryPanelUI
addHeader("STEP 1: InventoryPanelUI")
local invUI = PlayerGui:FindFirstChild("InventoryPanelUI")
if not invUI then
    addLine("InventoryPanelUI NOT FOUND", Color3.fromRGB(255, 100, 100))
    addLine("Coba buka inventory di game dulu, lalu execute ulang", Color3.fromRGB(255, 255, 0))
else
    addLine("FOUND InventoryPanelUI!", Color3.fromRGB(0, 255, 0))
    
    -- Deep scan: find all TextLabels and TextButtons (item names)
    local function scanChildren(parent, depth, maxDepth)
        if depth > maxDepth then return end
        for _, child in ipairs(parent:GetChildren()) do
            local info = string.rep("  ", depth) .. child.Name .. " [" .. child.ClassName .. "]"
            
            -- Show text content for labels/buttons
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                local text = child.Text or ""
                if text ~= "" and text ~= " " then
                    info = info .. ' = "' .. string.sub(text, 1, 80) .. '"'
                    addLine(info, Color3.fromRGB(255, 255, 100))
                else
                    addLine(info, Color3.fromRGB(150, 150, 150))
                end
            elseif child:IsA("ImageLabel") or child:IsA("ImageButton") then
                local img = child.Image or ""
                if img ~= "" then
                    info = info .. " img=" .. string.sub(img, 1, 40)
                end
                addLine(info, Color3.fromRGB(150, 200, 255))
            elseif child:IsA("Frame") or child:IsA("ScrollingFrame") then
                local childCount = #child:GetChildren()
                info = info .. " (" .. childCount .. " children)"
                addLine(info, Color3.fromRGB(100, 255, 200))
                scanChildren(child, depth + 1, maxDepth)
            else
                addLine(info, Color3.fromRGB(150, 150, 150))
            end
        end
    end
    
    scanChildren(invUI, 1, 5)
end

-- Step 2: Find ShopUI (might have owned items)
addHeader("STEP 2: ShopUI")
local shopUI = PlayerGui:FindFirstChild("ShopUI")
if shopUI then
    addLine("FOUND ShopUI", Color3.fromRGB(0, 255, 0))
    local function findTexts(parent, depth)
        if depth > 3 then return end
        for _, child in ipairs(parent:GetChildren()) do
            if (child:IsA("TextLabel") or child:IsA("TextButton")) and child.Text ~= "" and child.Text ~= " " then
                addLine(string.rep("  ", depth) .. child.Name .. ' = "' .. string.sub(child.Text, 1, 60) .. '"', Color3.fromRGB(255, 200, 100))
            end
            findTexts(child, depth + 1)
        end
    end
    findTexts(shopUI, 1)
else
    addLine("ShopUI not found", Color3.fromRGB(150, 150, 150))
end

-- Step 3: Find StorageUI
addHeader("STEP 3: StorageUI")
local storageUI = PlayerGui:FindFirstChild("StorageUI")
if storageUI then
    addLine("FOUND StorageUI", Color3.fromRGB(0, 255, 0))
    local function findTexts(parent, depth)
        if depth > 4 then return end
        for _, child in ipairs(parent:GetChildren()) do
            if (child:IsA("TextLabel") or child:IsA("TextButton")) and child.Text ~= "" and child.Text ~= " " then
                addLine(string.rep("  ", depth) .. child.Name .. ' = "' .. string.sub(child.Text, 1, 60) .. '"', Color3.fromRGB(255, 200, 100))
            end
            findTexts(child, depth + 1)
        end
    end
    findTexts(storageUI, 1)
else
    addLine("StorageUI not found", Color3.fromRGB(150, 150, 150))
end

-- Step 4: Scan ALL ScreenGuis for anything with "item" or "inventory" in name
addHeader("STEP 4: All GUIs with item/inventory content")
for _, gui in ipairs(PlayerGui:GetChildren()) do
    if gui:IsA("ScreenGui") then
        local nameLower = gui.Name:lower()
        if nameLower:find("item") or nameLower:find("inventory") or nameLower:find("bag") 
           or nameLower:find("equip") or nameLower:find("weapon") or nameLower:find("storage") then
            local childCount = 0
            local function countAll(p)
                for _, c in ipairs(p:GetChildren()) do
                    childCount = childCount + 1
                    countAll(c)
                end
            end
            countAll(gui)
            addLine(gui.Name .. " (" .. childCount .. " total descendants)", Color3.fromRGB(100, 255, 200))
        end
    end
end

-- Step 5: Check for any Folder/ObjectValue under player that might store items
addHeader("STEP 5: Player children (non-standard)")
for _, child in ipairs(LocalPlayer:GetChildren()) do
    if not ({PlayerGui=1, PlayerScripts=1, Backpack=1, StarterGear=1, leaderstats=1, Data=1})[child.Name] then
        local desc = child.Name .. " [" .. child.ClassName .. "]"
        if child:IsA("Folder") or child:IsA("Configuration") then
            desc = desc .. " (" .. #child:GetChildren() .. " children)"
            addLine(desc, Color3.fromRGB(255, 150, 50))
            for _, sub in ipairs(child:GetChildren()) do
                local subInfo = "  " .. sub.Name .. " [" .. sub.ClassName .. "]"
                if sub:IsA("IntValue") or sub:IsA("StringValue") or sub:IsA("NumberValue") or sub:IsA("BoolValue") then
                    subInfo = subInfo .. " = " .. tostring(sub.Value)
                end
                addLine(subInfo, Color3.fromRGB(200, 200, 150))
            end
        else
            addLine(desc, Color3.fromRGB(200, 200, 200))
        end
    end
end

addHeader("DONE - Screenshot this!")
