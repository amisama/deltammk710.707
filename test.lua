local RS = game.ReplicatedStorage
local Remotes = RS.Remotes
local RemoteEvents = RS.RemoteEvents
local RemoteFunctions = RS.RemoteFunctions
local HTTP = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============ BUAT GUI ============

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "InventoryDumperGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Frame utama
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 480, 0, 340)
frame.Position = UDim2.new(1, -500, 1, -360)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 32)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
titleBar.BorderSizePixel = 0
titleBar.Parent = frame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -80, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Inventory Dumper Log"
titleLabel.TextColor3 = Color3.fromRGB(180, 180, 255)
titleLabel.TextSize = 13
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

-- Status badge
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0, 70, 0, 20)
statusLabel.Position = UDim2.new(1, -110, 0.5, -10)
statusLabel.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
statusLabel.Text = "RUNNING"
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.TextSize = 10
statusLabel.Font = Enum.Font.GothamBold
statusLabel.Parent = titleBar
local sc2 = Instance.new("UICorner")
sc2.CornerRadius = UDim.new(0, 4)
sc2.Parent = statusLabel

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 22)
closeBtn.Position = UDim2.new(1, -34, 0.5, -11)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 12
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = titleBar
local cc = Instance.new("UICorner")
cc.CornerRadius = UDim.new(0, 4)
cc.Parent = closeBtn
closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Scroll area
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -10, 1, -80)
scrollFrame.Position = UDim2.new(0, 5, 0, 36)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 4
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 180)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.Parent = frame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 2)
listLayout.Parent = scrollFrame

-- Bottom buttons
local btnCopy = Instance.new("TextButton")
btnCopy.Size = UDim2.new(0.48, 0, 0, 28)
btnCopy.Position = UDim2.new(0, 5, 1, -34)
btnCopy.BackgroundColor3 = Color3.fromRGB(60, 100, 200)
btnCopy.Text = "Copy to Clipboard"
btnCopy.TextColor3 = Color3.fromRGB(255, 255, 255)
btnCopy.TextSize = 11
btnCopy.Font = Enum.Font.Gotham
btnCopy.Parent = frame
local bc = Instance.new("UICorner")
bc.CornerRadius = UDim.new(0, 4)
bc.Parent = btnCopy

local btnClear = Instance.new("TextButton")
btnClear.Size = UDim2.new(0.48, 0, 0, 28)
btnClear.Position = UDim2.new(0.52, 0, 1, -34)
btnClear.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
btnClear.Text = "Clear Log"
btnClear.TextColor3 = Color3.fromRGB(255, 255, 255)
btnClear.TextSize = 11
btnClear.Font = Enum.Font.Gotham
btnClear.Parent = frame
local bcc = Instance.new("UICorner")
bcc.CornerRadius = UDim.new(0, 4)
bcc.Parent = btnClear

-- Drag support
local dragging, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)
game:GetService("UserInputService").InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)
game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- ============ LOG FUNCTION ============

local logCount = 0
local allLogs = {}

local COLOR = {
    ok      = Color3.fromRGB(100, 220, 120),  -- hijau
    err     = Color3.fromRGB(255, 80, 80),    -- merah
    info    = Color3.fromRGB(150, 180, 255),  -- biru
    warn    = Color3.fromRGB(255, 200, 60),   -- kuning
    data    = Color3.fromRGB(200, 200, 200),  -- putih
}

local function addLog(text, colorType)
    logCount = logCount + 1
    table.insert(allLogs, text)
    print(text)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -8, 0, 0)
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = COLOR[colorType] or COLOR.data
    label.TextSize = 11
    label.Font = Enum.Font.Code
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.LayoutOrder = logCount
    label.Parent = scrollFrame

    -- Auto scroll ke bawah
    task.defer(function()
        scrollFrame.CanvasPosition = Vector2.new(0, scrollFrame.AbsoluteCanvasSize.Y)
    end)
end

-- Copy & Clear buttons
btnCopy.MouseButton1Click:Connect(function()
    local text = table.concat(allLogs, "\n")
    if setclipboard then setclipboard(text)
    elseif toclipboard then toclipboard(text) end
    btnCopy.Text = "Copied!"
    task.wait(1.5)
    btnCopy.Text = "Copy to Clipboard"
end)

btnClear.MouseButton1Click:Connect(function()
    for _, v in ipairs(scrollFrame:GetChildren()) do
        if v:IsA("TextLabel") then v:Destroy() end
    end
    allLogs = {}
    logCount = 0
end)

-- ============ HELPER ============

local function prettyPrint(label, data)
    if data == nil then
        addLog("[" .. label .. "] = nil / no response", "warn")
        return
    end
    local ok, encoded = pcall(function()
        return HTTP:JSONEncode(data)
    end)
    if ok then
        addLog("[OK] " .. label .. " =>", "ok")
        -- Potong kalau terlalu panjang
        local preview = encoded:sub(1, 300)
        if #encoded > 300 then preview = preview .. "... (" .. #encoded .. " chars)" end
        addLog(preview, "data")
    else
        addLog("[" .. label .. "] = " .. tostring(data), "data")
    end
end

local function invoke(remote, label)
    addLog(">> Invoking: " .. label, "info")
    local ok, result = pcall(function()
        return remote:InvokeServer()
    end)
    if ok then
        prettyPrint(label, result)
    else
        addLog("[ERR] " .. label .. " => " .. tostring(result), "err")
    end
end

-- ============ HOOKS ============

addLog("=== SAILOR PIECE INVENTORY DUMPER ===", "info")
addLog("Setting up hooks...", "info")

Remotes.UpdateInventory.OnClientEvent:Connect(function(data)
    addLog("[PUSH] UpdateInventory received!", "ok")
    prettyPrint("UpdateInventory", data)
end)

Remotes.UpdateEquipped.OnClientEvent:Connect(function(data)
    addLog("[PUSH] UpdateEquipped received!", "ok")
    prettyPrint("UpdateEquipped", data)
end)

Remotes.SyncUntradeableItems.OnClientEvent:Connect(function(data)
    addLog("[PUSH] SyncUntradeableItems received!", "ok")
    prettyPrint("SyncUntradeableItems", data)
end)

Remotes.StorageDataUpdate.OnClientEvent:Connect(function(data)
    addLog("[PUSH] StorageDataUpdate received!", "ok")
    prettyPrint("StorageDataUpdate", data)
end)

Remotes.UpdateRuneUI.OnClientEvent:Connect(function(data)
    addLog("[PUSH] UpdateRuneUI received!", "ok")
    prettyPrint("UpdateRuneUI", data)
end)

addLog("Hooks ready! Starting invokes in 1s...", "warn")
task.wait(1)

-- ============ INVOKES ============

addLog("\n--- INVOKING REMOTES ---", "info")

invoke(Remotes.GetPlayerData,         "GetPlayerData")
invoke(Remotes.GetEquipped,           "GetEquipped")
invoke(Remotes.GetAccessoryEquipped,  "GetAccessoryEquipped")
invoke(Remotes.GetEquippedCosmetic,   "GetEquippedCosmetic")
invoke(Remotes.GetEquippedAura,       "GetEquippedAura")
invoke(Remotes.GetStorageData,        "GetStorageData")
invoke(Remotes.GetRuneData,           "GetRuneData")
invoke(Remotes.GetBlessingData,       "GetBlessingData")
invoke(Remotes.GetEnchantData,        "GetEnchantData")
invoke(Remotes.GetTotalStats,         "GetTotalStats")
invoke(RemoteFunctions.GetArtifactData,          "GetArtifactData")
invoke(RemoteFunctions.GetArtifactStats,         "GetArtifactStats")
invoke(RemoteFunctions.GetArtifactMilestoneData, "GetArtifactMilestoneData")

addLog("\n--- FIRING RequestInventory ---", "info")
pcall(function()
    Remotes.RequestInventory:FireServer()
    addLog("[FIRED] RequestInventory — waiting for push...", "warn")
end)

task.wait(3)

statusLabel.Text = "DONE"
statusLabel.BackgroundColor3 = Color3.fromRGB(100, 100, 200)
addLog("\n=== DUMP SELESAI — Klik Copy ===", "info")
