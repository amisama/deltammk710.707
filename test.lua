local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local lp = Players.LocalPlayer
-- Cleanup old GUI
local oldGui = lp.PlayerGui:FindFirstChild("AvatarClonerGUI")
if oldGui then oldGui:Destroy() end
-- Save original appearance
local originalDesc
do
    local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function() originalDesc = hum:GetAppliedDescription() end)
    end
end
----------------------------------------------------------------
-- GUI
----------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "AvatarClonerGUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = lp:WaitForChild("PlayerGui")
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 320, 0, 380)
main.Position = UDim2.new(0.5, -160, 0.5, -190)
main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = main
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(80, 120, 255)
stroke.Thickness = 1.5
stroke.Parent = main
-- Title bar
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 36)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
title.BorderSizePixel = 0
title.Text = "  Avatar Cloner"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Parent = main
local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = title
-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -33, 0, 3)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.BorderSizePixel = 0
closeBtn.Parent = main
local cbc = Instance.new("UICorner") cbc.CornerRadius = UDim.new(0, 6) cbc.Parent = closeBtn
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)
-- Username input
local input = Instance.new("TextBox")
input.Size = UDim2.new(1, -20, 0, 35)
input.Position = UDim2.new(0, 10, 0, 50)
input.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
input.PlaceholderText = "Paste username here..."
input.PlaceholderColor3 = Color3.fromRGB(140, 140, 150)
input.Text = ""
input.TextColor3 = Color3.fromRGB(255, 255, 255)
input.Font = Enum.Font.Gotham
input.TextSize = 13
input.BorderSizePixel = 0
input.ClearTextOnFocus = false
input.Parent = main
local ic = Instance.new("UICorner") ic.CornerRadius = UDim.new(0, 6) ic.Parent = input
-- Status label
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 20)
status.Position = UDim2.new(0, 10, 0, 90)
status.BackgroundTransparency = 1
status.Text = "Ready"
status.TextColor3 = Color3.fromRGB(180, 180, 200)
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = main
local function setStatus(msg, color)
    status.Text = msg
    status.TextColor3 = color or Color3.fromRGB(180, 180, 200)
end
-- Player list scroll
local listLabel = Instance.new("TextLabel")
listLabel.Size = UDim2.new(1, -20, 0, 18)
listLabel.Position = UDim2.new(0, 10, 0, 115)
listLabel.BackgroundTransparency = 1
listLabel.Text = "Players in server (tap to select):"
listLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
listLabel.Font = Enum.Font.Gotham
listLabel.TextSize = 11
listLabel.TextXAlignment = Enum.TextXAlignment.Left
listLabel.Parent = main
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 0, 150)
scroll.Position = UDim2.new(0, 10, 0, 138)
scroll.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 120, 255)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = main
local sc = Instance.new("UICorner") sc.CornerRadius = UDim.new(0, 6) sc.Parent = scroll
local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 2)
layout.Parent = scroll
local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 4)
padding.PaddingLeft = UDim.new(0, 4)
padding.PaddingRight = UDim.new(0, 4)
padding.Parent = scroll
-- Buttons
local cloneBtn = Instance.new("TextButton")
cloneBtn.Size = UDim2.new(0.5, -15, 0, 38)
cloneBtn.Position = UDim2.new(0, 10, 1, -48)
cloneBtn.BackgroundColor3 = Color3.fromRGB(80, 120, 255)
cloneBtn.Text = "CLONE"
cloneBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
cloneBtn.Font = Enum.Font.GothamBold
cloneBtn.TextSize = 13
cloneBtn.BorderSizePixel = 0
cloneBtn.Parent = main
local cbnc = Instance.new("UICorner") cbnc.CornerRadius = UDim.new(0, 6) cbnc.Parent = cloneBtn
local resetBtn = Instance.new("TextButton")
resetBtn.Size = UDim2.new(0.5, -15, 0, 38)
resetBtn.Position = UDim2.new(0.5, 5, 1, -48)
resetBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
resetBtn.Text = "RESET"
resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
resetBtn.Font = Enum.Font.GothamBold
resetBtn.TextSize = 13
resetBtn.BorderSizePixel = 0
resetBtn.Parent = main
local rbc = Instance.new("UICorner") rbc.CornerRadius = UDim.new(0, 6) rbc.Parent = resetBtn
----------------------------------------------------------------
-- Clone Logic
----------------------------------------------------------------
local function findTarget(name)
    if not name or name == "" then return nil end
    name = string.lower(name)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and (string.lower(p.Name) == name or string.lower(p.DisplayName) == name) then
            return p
        end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and (string.find(string.lower(p.Name), name) or string.find(string.lower(p.DisplayName), name)) then
            return p
        end
    end
    return nil
end
local function applyAvatar(targetChar, myChar)
    local myHum = myChar:FindFirstChildOfClass("Humanoid")
    local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
    if not myHum or not targetHum then return false, "Humanoid missing" end
    local ok, desc = pcall(function() return targetHum:GetAppliedDescription() end)
    if ok and desc then
        pcall(function() myHum:ApplyDescription(desc) end)
    end
    for _, a in ipairs(myChar:GetChildren()) do
        if a:IsA("Accessory") then a:Destroy() end
    end
    for _, a in ipairs(targetChar:GetChildren()) do
        if a:IsA("Accessory") then
            pcall(function() myHum:AddAccessory(a:Clone()) end)
        end
    end
    local oldBC = myChar:FindFirstChild("Body Colors")
    if oldBC then oldBC:Destroy() end
    local tBC = targetChar:FindFirstChild("Body Colors")
    if tBC then tBC:Clone().Parent = myChar end
    for _, item in ipairs(myChar:GetChildren()) do
        if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") or item:IsA("CharacterMesh") then
            item:Destroy()
        end
    end
    for _, item in ipairs(targetChar:GetChildren()) do
        if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") or item:IsA("CharacterMesh") then
            item:Clone().Parent = myChar
        end
    end
    local tHead, mHead = targetChar:FindFirstChild("Head"), myChar:FindFirstChild("Head")
    if tHead and mHead then
        local oldFace = mHead:FindFirstChild("face")
        if oldFace then oldFace:Destroy() end
        local tFace = tHead:FindFirstChild("face")
        if tFace then tFace:Clone().Parent = mHead end
    end
    pcall(function() myHum.DisplayName = targetHum.DisplayName end)
    return true
end
local function doClone(name)
    local target = findTarget(name)
    if not target then
        setStatus("Target not found: " .. name, Color3.fromRGB(255, 100, 100))
        return
    end
    local myChar = lp.Character or lp.CharacterAdded:Wait()
    local targetChar = target.Character
    if not targetChar then
        setStatus("Target has no character", Color3.fromRGB(255, 100, 100))
        return
    end
    setStatus("Cloning " .. target.Name .. "...", Color3.fromRGB(255, 220, 100))
    local ok, err = applyAvatar(targetChar, myChar)
    if ok then
        setStatus("Cloned: " .. target.DisplayName .. " (@" .. target.Name .. ")", Color3.fromRGB(100, 255, 150))
    else
        setStatus("Failed: " .. tostring(err), Color3.fromRGB(255, 100, 100))
    end
end
local function doReset()
    local myChar = lp.Character
    if not myChar then return end
    local hum = myChar:FindFirstChildOfClass("Humanoid")
    if hum and originalDesc then
        pcall(function() hum:ApplyDescription(originalDesc) end)
        setStatus("Avatar reset", Color3.fromRGB(100, 255, 150))
    else
        lp:LoadCharacter()
        setStatus("Respawned", Color3.fromRGB(100, 255, 150))
    end
end
cloneBtn.MouseButton1Click:Connect(function() doClone(input.Text) end)
resetBtn.MouseButton1Click:Connect(doReset)
input.FocusLost:Connect(function(enter)
    if enter then doClone(input.Text) end
end)
----------------------------------------------------------------
-- Player List
----------------------------------------------------------------
local function refreshList()
    for _, c in ipairs(scroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -8, 0, 28)
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
            btn.Text = "  " .. p.DisplayName .. "  (@" .. p.Name .. ")"
            btn.TextColor3 = Color3.fromRGB(230, 230, 240)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 12
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.BorderSizePixel = 0
            btn.Parent = scroll
            local bc = Instance.new("UICorner") bc.CornerRadius = UDim.new(0, 4) bc.Parent = btn
            btn.MouseButton1Click:Connect(function()
                input.Text = p.Name
                setStatus("Selected: " .. p.Name, Color3.fromRGB(180, 200, 255))
            end)
        end
    end
end
refreshList()
Players.PlayerAdded:Connect(refreshList)
Players.PlayerRemoving:Connect(refreshList)
setStatus("Ready - paste username or tap a player below", Color3.fromRGB(180, 200, 255))
print("[Avatar Cloner] GUI loaded")
