-- ============================================
-- SAILOR PIECE — FULL INVENTORY CAPTURE v2
-- Tangkap raw payload tiap kategori inventory
-- ============================================

local RS = game.ReplicatedStorage
local Remotes = RS.Remotes
local RemoteEvents = RS.RemoteEvents
local HTTP = game:GetService("HttpService")
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============ GUI SETUP ============

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "InvCapture"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 500, 0, 380)
frame.Position = UDim2.new(1, -515, 1, -400)
frame.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
frame.BorderSizePixel = 0
frame.Parent = screenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 32)
titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 45)
titleBar.BorderSizePixel = 0
titleBar.Parent = frame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Inventory Capture v2"
title.TextColor3 = Color3.fromRGB(160, 160, 255)
title.TextSize = 13
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 22)
closeBtn.Position = UDim2.new(1, -32, 0.5, -11)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.TextSize = 12
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 4)
closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)

-- Drag
local dragging, dragStart, startPos
titleBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = i.Position; startPos = frame.Position
    end
end)
game:GetService("UserInputService").InputChanged:Connect(function(i)
    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
game:GetService("UserInputService").InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

-- Scroll
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -10, 1, -80)
scroll.Position = UDim2.new(0, 5, 0, 36)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 200)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new(0,0,0,0)
scroll.Parent = frame
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 2)
layout.Parent = scroll

-- Buttons
local btnCopy = Instance.new("TextButton")
btnCopy.Size = UDim2.new(0.48, 0, 0, 28)
btnCopy.Position = UDim2.new(0, 5, 1, -34)
btnCopy.BackgroundColor3 = Color3.fromRGB(60, 100, 200)
btnCopy.Text = "Copy All"
btnCopy.TextColor3 = Color3.fromRGB(255,255,255)
btnCopy.TextSize = 11
btnCopy.Font = Enum.Font.Gotham
btnCopy.Parent = frame
Instance.new("UICorner", btnCopy).CornerRadius = UDim.new(0, 4)

local btnClear = Instance.new("TextButton")
btnClear.Size = UDim2.new(0.48, 0, 0, 28)
btnClear.Position = UDim2.new(0.52, 0, 1, -34)
btnClear.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
btnClear.Text = "Clear"
btnClear.TextColor3 = Color3.fromRGB(255,255,255)
btnClear.TextSize = 11
btnClear.Font = Enum.Font.Gotham
btnClear.Parent = frame
Instance.new("UICorner", btnClear).CornerRadius = UDim.new(0, 4)

-- ============ LOG SYSTEM ============

local allLogs = {}
local logIdx = 0

local COLORS = {
    ok   = Color3.fromRGB(80, 220, 100),
    err  = Color3.fromRGB(255, 70, 70),
    info = Color3.fromRGB(120, 160, 255),
    warn = Color3.fromRGB(255, 200, 50),
    data = Color3.fromRGB(190, 190, 190),
    cat  = Color3.fromRGB(255, 160, 60),
}

local function addLog(text, colorType)
    logIdx = logIdx + 1
    table.insert(allLogs, text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -8, 0, 0)
    lbl.AutomaticSize = Enum.AutomaticSize.Y
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = COLORS[colorType] or COLORS.data
    lbl.TextSize = 11
    lbl.Font = Enum.Font.Code
    lbl.TextWrapped = true
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = logIdx
    lbl.Parent = scroll
    task.defer(function()
        scroll.CanvasPosition = Vector2.new(0, scroll.AbsoluteCanvasSize.Y)
    end)
end

btnCopy.MouseButton1Click:Connect(function()
    local t = table.concat(allLogs, "\n")
    if setclipboard then setclipboard(t)
    elseif toclipboard then toclipboard(t) end
    btnCopy.Text = "Copied!"
    task.wait(1.5)
    btnCopy.Text = "Copy All"
end)

btnClear.MouseButton1Click:Connect(function()
    for _, v in ipairs(scroll:GetChildren()) do
        if v:IsA("TextLabel") then v:Destroy() end
    end
    allLogs = {}; logIdx = 0
end)

-- ============ CAPTURE LOGIC ============

-- Inventory storage per kategori
local inventoryData = {}

-- Kategori yang diketahui dari dump sebelumnya
local KNOWN_CATEGORIES = {
    "Items", "Cosmetics", "Melee", "Power",
    "Accessories", "Sword", "Runes", "Auras"
}

addLog("=== INVENTORY CAPTURE v2 ===", "info")
addLog("Monitoring UpdateInventory...", "info")

-- HOOK UTAMA: Tangkap SEMUA argumen dari UpdateInventory
Remotes.UpdateInventory.OnClientEvent:Connect(function(...)
    local args = {...}
    local category = args[1]  -- arg pertama = nama kategori
    local items    = args[2]  -- arg kedua = data items
    local extra    = args[3]  -- arg ketiga kalau ada

    addLog("\n[CATEGORY] " .. tostring(category), "cat")

    -- Simpan ke table
    inventoryData[tostring(category)] = {
        raw_arg1 = args[1],
        raw_arg2 = args[2],
        raw_arg3 = args[3],
    }

    -- Print arg2 (isi items)
    if items ~= nil then
        local ok, encoded = pcall(function()
            return game:GetService("HttpService"):JSONEncode(items)
        end)
        if ok then
            addLog("  Items: " .. encoded:sub(1, 400), "ok")
            if #encoded > 400 then
                addLog("  ... (" .. #encoded .. " total chars)", "warn")
            end
        else
            addLog("  Items (raw): " .. tostring(items), "data")
        end
    else
        addLog("  Items = nil (cek arg lain)", "warn")
        -- Print semua args
        for i, v in ipairs(args) do
            local ok2, enc2 = pcall(function()
                return game:GetService("HttpService"):JSONEncode(v)
            end)
            addLog("  arg[" .. i .. "] = " .. (ok2 and enc2 or tostring(v)), "data")
        end
    end
end)

-- Hook UpdateEquipped (sudah confirmed working)
Remotes.UpdateEquipped.OnClientEvent:Connect(function(...)
    local args = {...}
    addLog("\n[EQUIPPED]", "info")
    for i, v in ipairs(args) do
        local ok, enc = pcall(function()
            return game:GetService("HttpService"):JSONEncode(v)
        end)
        addLog("  arg[" .. i .. "] = " .. (ok and enc or tostring(v)), "ok")
    end
end)

-- Hook StorageDataUpdate
Remotes.StorageDataUpdate.OnClientEvent:Connect(function(...)
    local args = {...}
    addLog("\n[STORAGE]", "info")
    for i, v in ipairs(args) do
        local ok, enc = pcall(function()
            return game:GetService("HttpService"):JSONEncode(v)
        end)
        addLog("  arg[" .. i .. "] = " .. (ok and enc or tostring(v)), "ok")
    end
end)

-- Hook ArtifactDataSync
RemoteEvents.ArtifactDataSync.OnClientEvent:Connect(function(...)
    local args = {...}
    addLog("\n[ARTIFACT SYNC]", "info")
    for i, v in ipairs(args) do
        local ok, enc = pcall(function()
            return game:GetService("HttpService"):JSONEncode(v)
        end)
        addLog("  arg[" .. i .. "] = " .. (ok and enc or tostring(v)), "ok")
    end
end)

-- Hook DataChanged
RemoteEvents.DataChanged.OnClientEvent:Connect(function(...)
    local args = {...}
    addLog("\n[DATA CHANGED]", "warn")
    for i, v in ipairs(args) do
        local ok, enc = pcall(function()
            return game:GetService("HttpService"):JSONEncode(v)
        end)
        addLog("  arg[" .. i .. "] = " .. (ok and enc or tostring(v)), "data")
    end
end)

addLog("Hooks ready! Firing GetPlayerData in 1s...", "warn")
task.wait(1)

-- Fire GetPlayerData untuk trigger semua push
addLog(">> Firing GetPlayerData...", "info")
pcall(function()
    Remotes.GetPlayerData:InvokeServer()
end)

-- Juga fire RequestInventory
task.wait(0.5)
addLog(">> Firing RequestInventory...", "info")
pcall(function()
    Remotes.RequestInventory:FireServer()
end)

task.wait(4)

-- Summary
addLog("\n=== SUMMARY ===", "info")
addLog("Kategori tertangkap: " .. #inventoryData, "ok")
for cat, _ in pairs(inventoryData) do
    addLog("  - " .. cat, "cat")
end
addLog("Klik Copy All untuk export hasil!", "warn")
