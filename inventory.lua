--[[
    TEST: Fire RequestInventory dan listen UpdateInventory
    Juga listen DataChanged dan ProfileLoaded
    
    Cara kerja:
    1. Pasang listener di semua RemoteEvent yang relevan
    2. Fire RequestInventory ke server
    3. Tunggu response max 10 detik
    4. Dump semua data yang diterima ke clipboard
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local output = {}
local function log(t) table.insert(output, t) end

-- Status GUI
local sg = Instance.new("ScreenGui")
sg.Name = "TestFireInv"
sg.ResetOnSpawn = false
local lbl = Instance.new("TextLabel")
lbl.Size = UDim2.new(0.8, 0, 0, 50)
lbl.Position = UDim2.new(0.1, 0, 0.4, 0)
lbl.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
lbl.BorderSizePixel = 0
lbl.TextColor3 = Color3.fromRGB(255, 255, 0)
lbl.TextSize = 14
lbl.Font = Enum.Font.GothamBold
lbl.Text = "Setting up listeners..."
lbl.Parent = sg
sg.Parent = PlayerGui

log("=== TEST FIRE INVENTORY ===")
log("Player: " .. LocalPlayer.Name)

-- Helper: serialize table
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
            if count > 30 then
                table.insert(lines, indent .. "  ... (+" .. count .. " more)")
                break
            end
            table.insert(lines, indent .. "  [" .. tostring(k) .. "] = " .. serialize(v, depth + 1, maxDepth))
        end
        if #lines == 0 then return "{}" end
        return "{\n" .. table.concat(lines, "\n") .. "\n" .. indent .. "}"
    else
        return tostring(val) .. " (" .. type(val) .. ")"
    end
end

local receivedData = {}
local connections = {}

-- Find remotes
local remotes = ReplicatedStorage:FindFirstChild("Remotes")
local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")

-- Listen to ALL relevant events
local eventsToListen = {}

if remotes then
    local names = {"UpdateInventory", "DataUpdated", "SyncUntradeableItems", "StorageDataUpdate"}
    for _, name in ipairs(names) do
        local ev = remotes:FindFirstChild(name)
        if ev and ev:IsA("RemoteEvent") then
            table.insert(eventsToListen, {event = ev, source = "Remotes." .. name})
        end
    end
end

if remoteEvents then
    local names = {"DataChanged", "ProfileLoaded", "QuestUIUpdate", "TitleDataSync", 
                   "TraitDataUpdate", "ArtifactDataSync", "SpecPassiveDataUpdate",
                   "PowerDataUpdate", "AscendDataUpdate"}
    for _, name in ipairs(names) do
        local ev = remoteEvents:FindFirstChild(name)
        if ev and ev:IsA("RemoteEvent") then
            table.insert(eventsToListen, {event = ev, source = "RemoteEvents." .. name})
        end
    end
end

log("Listening to " .. #eventsToListen .. " events:")
for _, info in ipairs(eventsToListen) do
    log("  - " .. info.source)
    local conn = info.event.OnClientEvent:Connect(function(...)
        local args = {...}
        log("\n>> RECEIVED: " .. info.source)
        log("   Args count: " .. #args)
        for i, arg in ipairs(args) do
            log("   Arg[" .. i .. "] type=" .. type(arg))
            if type(arg) == "table" then
                log(serialize(arg, 1, 3))
            else
                log("   = " .. tostring(arg))
            end
        end
        table.insert(receivedData, {source = info.source, args = args})
    end)
    table.insert(connections, conn)
end

-- Now fire RequestInventory
log("\n--- Firing events ---")
lbl.Text = "Firing RequestInventory..."

if remotes then
    local reqInv = remotes:FindFirstChild("RequestInventory")
    if reqInv and reqInv:IsA("RemoteEvent") then
        log("Firing: Remotes.RequestInventory")
        pcall(function() reqInv:FireServer() end)
    else
        log("RequestInventory not found or not RemoteEvent")
    end
    
    -- Also try RequestOpenUIFromInventory
    local reqOpen = remotes:FindFirstChild("RequestOpenUIFromInventory")
    if reqOpen and reqOpen:IsA("RemoteEvent") then
        log("Firing: Remotes.RequestOpenUIFromInventory")
        pcall(function() reqOpen:FireServer() end)
    end
end

-- Wait for responses
lbl.Text = "Waiting for responses... 0s"
local start = tick()
while (tick() - start) < 10 do
    lbl.Text = "Waiting... " .. math.floor(tick() - start) .. "s | Received: " .. #receivedData .. " events"
    task.wait(0.5)
end

-- Cleanup connections
for _, conn in ipairs(connections) do
    conn:Disconnect()
end

-- Report
log("\n=== RESULTS ===")
log("Total events received: " .. #receivedData)

if #receivedData == 0 then
    log("No events received! Server might not respond to these fires.")
    lbl.Text = "No response received in 10s"
    lbl.TextColor3 = Color3.fromRGB(255, 100, 0)
else
    lbl.Text = "Got " .. #receivedData .. " events! Copied."
    lbl.TextColor3 = Color3.fromRGB(0, 255, 100)
end

local finalText = table.concat(output, "\n")
pcall(function()
    if setclipboard then setclipboard(finalText)
    elseif toclipboard then toclipboard(finalText) end
end)
