--[[
    DEEP SCAN StorageUI + InventoryPanelUI
    
    INSTRUKSI:
    1. Buka INVENTORY di game (klik icon tas/inventory)
    2. Buka STORAGE juga kalau ada
    3. Baru execute script ini
    4. Screenshot hasilnya
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DeepScanGui"
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
    label.TextSize = 10
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

addHeader("DEEP SCAN - StorageUI + InventoryPanelUI")

-- Collect all TextLabels/TextButtons with non-empty text
local function collectTexts(parent, results, path, maxDepth, depth)
    depth = depth or 0
    if depth > (maxDepth or 8) then return end
    for _, child in ipairs(parent:GetChildren()) do
        local childPath = path .. "." .. child.Name
        if (child:IsA("TextLabel") or child:IsA("TextButton")) then
            local text = child.Text or ""
            text = text:gsub("%s+", " "):sub(1, 100)
            if text ~= "" and text ~= " " and text ~= "0" and text ~= "x0" then
                table.insert(results, {
                    path = childPath,
                    class = child.ClassName,
                    text = text,
                    visible = child.Visible,
                    parentVisible = child.Parent and child.Parent.Visible or true,
                })
            end
        end
        collectTexts(child, results, childPath, maxDepth, depth + 1)
    end
end

-- Collect all item-like frames (frames with ImageLabel + TextLabel children = item slot)
local function collectItemSlots(parent, results, path, maxDepth, depth)
    depth = depth or 0
    if depth > (maxDepth or 8) then return end
    for _, child in ipairs(parent:GetChildren()) do
        local childPath = path .. "." .. child.Name
        if child:IsA("Frame") or child:IsA("ImageButton") or child:IsA("TextButton") or child:IsA("ImageLabel") then
            -- Check if this looks like an item slot (has image + text children)
            local hasImage = false
            local hasText = false
            local textContent = ""
            local imageId = ""
            for _, sub in ipairs(child:GetChildren()) do
                if sub:IsA("ImageLabel") or sub:IsA("ImageButton") then
                    hasImage = true
                    if sub.Image ~= "" then imageId = sub.Image end
                end
                if sub:IsA("TextLabel") or sub:IsA("TextButton") then
                    if sub.Text ~= "" and sub.Text ~= " " then
                        hasText = true
                        textContent = textContent .. sub.Text .. " | "
                    end
                end
            end
            if hasText then
                table.insert(results, {
                    path = childPath,
                    class = child.ClassName,
                    text = textContent:sub(1, 120),
                    hasImage = hasImage,
                    childCount = #child:GetChildren(),
                })
            end
        end
        collectItemSlots(child, results, childPath, maxDepth, depth + 1)
    end
end

-- ========== SCAN StorageUI ==========
addHeader("STORAGE UI - All text content")
local storageUI = PlayerGui:FindFirstChild("StorageUI")
if storageUI then
    local texts = {}
    collectTexts(storageUI, texts, "StorageUI", 8)
    addLine("Found " .. #texts .. " text elements", Color3.fromRGB(255, 255, 0))
    for i, t in ipairs(texts) do
        if i > 100 then
            addLine("... truncated (" .. #texts .. " total)", Color3.fromRGB(255, 100, 100))
            break
        end
        local vis = t.visible and "V" or "H"
        addLine("[" .. vis .. "] " .. t.text, Color3.fromRGB(200, 255, 200))
        addLine("    @ " .. t.path, Color3.fromRGB(100, 100, 100))
    end
    
    addHeader("STORAGE UI - Item-like slots")
    local slots = {}
    collectItemSlots(storageUI, slots, "StorageUI", 8)
    addLine("Found " .. #slots .. " item-like elements", Color3.fromRGB(255, 255, 0))
    for i, s in ipairs(slots) do
        if i > 60 then
            addLine("... truncated (" .. #slots .. " total)", Color3.fromRGB(255, 100, 100))
            break
        end
        addLine(s.text, Color3.fromRGB(255, 200, 100))
        addLine("    @ " .. s.path .. " [" .. s.class .. "] children=" .. s.childCount, Color3.fromRGB(100, 100, 100))
    end
else
    addLine("StorageUI not found", Color3.fromRGB(255, 100, 100))
end

-- ========== SCAN InventoryPanelUI ==========
addHeader("INVENTORY PANEL UI - All text content")
local invUI = PlayerGui:FindFirstChild("InventoryPanelUI")
if invUI then
    local texts = {}
    collectTexts(invUI, texts, "InventoryPanelUI", 8)
    addLine("Found " .. #texts .. " text elements", Color3.fromRGB(255, 255, 0))
    for i, t in ipairs(texts) do
        if i > 100 then
            addLine("... truncated (" .. #texts .. " total)", Color3.fromRGB(255, 100, 100))
            break
        end
        local vis = t.visible and "V" or "H"
        addLine("[" .. vis .. "] " .. t.text, Color3.fromRGB(200, 255, 200))
        addLine("    @ " .. t.path, Color3.fromRGB(100, 100, 100))
    end
    
    addHeader("INVENTORY PANEL UI - Item-like slots")
    local slots = {}
    collectItemSlots(invUI, slots, "InventoryPanelUI", 8)
    addLine("Found " .. #slots .. " item-like elements", Color3.fromRGB(255, 255, 0))
    for i, s in ipairs(slots) do
        if i > 60 then
            addLine("... truncated (" .. #slots .. " total)", Color3.fromRGB(255, 100, 100))
            break
        end
        addLine(s.text, Color3.fromRGB(255, 200, 100))
        addLine("    @ " .. s.path .. " [" .. s.class .. "] children=" .. s.childCount, Color3.fromRGB(100, 100, 100))
    end
else
    addLine("InventoryPanelUI not found", Color3.fromRGB(255, 100, 100))
end

-- ========== SCAN BasicStatsCurrencyAndButtonsUI ==========
addHeader("STATS/CURRENCY UI")
local statsUI = PlayerGui:FindFirstChild("BasicStatsCurrencyAndButtonsUI")
if statsUI then
    local texts = {}
    collectTexts(statsUI, texts, "StatsUI", 6)
    addLine("Found " .. #texts .. " text elements", Color3.fromRGB(255, 255, 0))
    for i, t in ipairs(texts) do
        if i > 40 then break end
        addLine("[" .. (t.visible and "V" or "H") .. "] " .. t.text, Color3.fromRGB(200, 255, 200))
    end
end

addHeader("DONE - Screenshot semua halaman!")
addLine("Scroll ke bawah untuk lihat semua data", Color3.fromRGB(255, 255, 0))
