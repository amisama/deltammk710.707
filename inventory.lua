--[[
    READ ItemImageConfig - get real image IDs per item
    Hasil ke clipboard.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local output = {}
local function log(t) table.insert(output, t) end

log("=== ITEM IMAGE CONFIG ===")

-- Try to require the ModuleScript
local configs = {
    "Modules.ItemImageConfig",
    "Modules.ItemRarityConfig",
    "Modules.WeaponClassification",
    "Modules.AccessoryConfig",
    "Modules.HakiConfig",
    "Modules.HakiColorConfig",
    "Modules.PowerConfig",
    "Modules.UsableItemConfig",
}

for _, path in ipairs(configs) do
    log("\n--- " .. path .. " ---")
    pcall(function()
        local parts = path:split(".")
        local current = ReplicatedStorage
        for _, part in ipairs(parts) do
            current = current:FindFirstChild(part)
            if not current then
                log("NOT FOUND at: " .. part)
                return
            end
        end

        if current:IsA("ModuleScript") then
            local ok, data = pcall(require, current)
            if ok and type(data) == "table" then
                local count = 0
                for k, v in pairs(data) do
                    count = count + 1
                    if count > 80 then
                        log("  ... (truncated, " .. count .. "+ entries)")
                        break
                    end
                    if type(v) == "table" then
                        -- Show key fields
                        local fields = {}
                        for fk, fv in pairs(v) do
                            if type(fv) ~= "table" then
                                table.insert(fields, tostring(fk) .. "=" .. tostring(fv))
                            else
                                local subCount = 0
                                for _ in pairs(fv) do subCount = subCount + 1 end
                                table.insert(fields, tostring(fk) .. "=table(" .. subCount .. ")")
                            end
                        end
                        log("  [" .. tostring(k) .. "] " .. table.concat(fields, " | "))
                    else
                        log("  [" .. tostring(k) .. "] = " .. tostring(v))
                    end
                end
                log("  TOTAL: " .. count .. " entries")
            elseif ok then
                log("  Returned: " .. type(data) .. " = " .. tostring(data))
            else
                log("  REQUIRE FAILED: " .. tostring(data))
            end
        else
            log("  Not a ModuleScript: " .. current.ClassName)
        end
    end)
end

local result = table.concat(output, "\n")
pcall(function()
    if setclipboard then setclipboard(result)
    elseif toclipboard then toclipboard(result) end
end)

local sg = Instance.new("ScreenGui")
sg.Name = "ImgConfigGui"
sg.ResetOnSpawn = false
local lbl = Instance.new("TextLabel")
lbl.Size = UDim2.new(0.6, 0, 0, 40)
lbl.Position = UDim2.new(0.2, 0, 0.05, 0)
lbl.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
lbl.BorderSizePixel = 0
lbl.TextColor3 = Color3.fromRGB(0, 255, 100)
lbl.TextSize = 14
lbl.Font = Enum.Font.GothamBold
lbl.Text = "Done! Copied to clipboard. Paste ke chat."
lbl.Parent = sg
sg.Parent = PlayerGui
