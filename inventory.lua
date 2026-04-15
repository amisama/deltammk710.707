--[[
    COLLECT ALL AVAILABLE DATA
    Fire semua RemoteEvent yang bisa kasih data, listen responses.
    Hasil ke clipboard.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local output = {}
local function log(t) table.insert(output, t) end

local sg = Instance.new("ScreenGui")
sg.Name = "TestAllData"
sg.ResetOnSpawn = false
local lbl = Instance.new("TextLabel")
lbl.Size = UDim2.new(0.8, 0, 0, 50)
lbl.Position = UDim2.new(0.1, 0, 0.4, 0)
lbl.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
lbl.BorderSizePixel = 0
lbl.TextColor3 = Color3.fromRGB(255, 255, 0)
lbl.TextSize = 14
lbl.Font = Enum.Font.GothamBold
lbl.Text = "Collecting all data..."
lbl.Parent = sg
sg.Parent = PlayerGui

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
            if count > 40 then
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

log("=== ALL DATA COLLECTION ===")
log("Player: " .. LocalPlayer.Name)

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
local remoteFunctions = ReplicatedStorage:FindFirstChild("RemoteFunctions")

local allData = {}
local connections = {}

-- Listen to ALL data-related events
local eventsToListen = {}
if remoteEvents then
    for _, child in ipairs(remoteEvents:GetChildren()) do
        if child:IsA("RemoteEvent") then
            local name = child.Name
            if name:find("Data") or name:find("Update") or name:find("Sync") 
               or name:find("Progress") or name:find("Loaded") then
                table.insert(eventsToListen, {event = child, source = "RemoteEvents." .. name})
            end
        end
    end
end
if remotes then
    for _, child in ipairs(remotes:GetChildren()) do
        if child:IsA("RemoteEvent") then
            local name = child.Name
            if name:find("Data") or name:find("Update") or name:find("Sync") or name:find("Inventory") then
                table.insert(eventsToListen, {event = child, source = "Remotes." .. name})
            end
        end
    end
end

log("Listening to " .. #eventsToListen .. " events")
for _, info in ipairs(eventsToListen) do
    local conn = info.event.OnClientEvent:Connect(function(...)
        local args = {...}
        allData[info.source] = args
    end)
    table.insert(connections, conn)
end

-- Fire requests
log("\n--- Firing requests ---")

-- RequestInventory
pcall(function()
    if remotes then
        local r = remotes:FindFirstChild("RequestInventory")
        if r then r:FireServer(); log("Fired: RequestInventory") end
    end
end)

-- Now try RemoteFunctions that return data (with task.spawn to avoid hang)
local rfResults = {}

local functionsToTry = {}
if remoteEvents then
    for _, child in ipairs(remoteEvents:GetChildren()) do
        if child:IsA("RemoteFunction") then
            table.insert(functionsToTry, {func = child, source = "RemoteEvents." .. child.Name})
        end
    end
end
if remoteFunctions then
    for _, child in ipairs(remoteFunctions:GetChildren()) do
        if child:IsA("RemoteFunction") then
            table.insert(functionsToTry, {func = child, source = "RemoteFunctions." .. child.Name})
        end
    end
end

log("Trying " .. #functionsToTry .. " RemoteFunctions (5s timeout each)")

for _, info in ipairs(functionsToTry) do
    task.spawn(function()
        local done = false
        task.spawn(function()
            local ok, result = pcall(function()
                return info.func:InvokeServer()
            end)
            if ok and result ~= nil then
                rfResults[info.source] = result
            end
            done = true
        end)
        -- 5 second timeout
        local s = tick()
        while not done and (tick() - s) < 5 do
            task.wait(0.2)
        end
    end)
end

-- Wait for everything
lbl.Text = "Waiting 8 seconds for all data..."
task.wait(8)

-- Cleanup
for _, conn in ipairs(connections) do conn:Disconnect() end

-- Dump results
log("\n=== EVENT RESPONSES ===")
for source, args in pairs(allData) do
    log("\n>> " .. source)
    for i, arg in ipairs(args) do
        log("  Arg[" .. i .. "] = " .. serialize(arg, 1, 3))
    end
end

log("\n=== REMOTE FUNCTION RESULTS ===")
for source, result in pairs(rfResults) do
    log("\n>> " .. source)
    log("  " .. serialize(result, 1, 3))
end

-- Also dump what we already have locally
log("\n=== LOCAL DATA ===")
log("\n>> Player.Data folder")
local dataFolder = LocalPlayer:FindFirstChild("Data")
if dataFolder then
    for _, child in ipairs(dataFolder:GetChildren()) do
        if child:IsA("IntValue") or child:IsA("NumberValue") or child:IsA("StringValue") or child:IsA("BoolValue") then
            log("  " .. child.Name .. " = " .. tostring(child.Value))
        end
    end
end

log("\n>> leaderstats")
local ls = LocalPlayer:FindFirstChild("leaderstats")
if ls then
    for _, child in ipairs(ls:GetChildren()) do
        log("  " .. child.Name .. " = " .. tostring(child.Value))
    end
end

local totalKeys = 0
for _ in pairs(allData) do totalKeys = totalKeys + 1 end
for _ in pairs(rfResults) do totalKeys = totalKeys + 1 end
log("\n=== SUMMARY ===")
log("Event responses: " .. totalKeys)
log("RF results: " .. totalKeys)

lbl.Text = "Done! " .. totalKeys .. " data sources. Copied."
lbl.TextColor3 = Color3.fromRGB(0, 255, 100)

local finalText = table.concat(output, "\n")
pcall(function()
    if setclipboard then setclipboard(finalText)
    elseif toclipboard then toclipboard(finalText) end
end)
