--[[
    Script: Survive the Killer! - Custom Feature Pack (FIXED)
    Target: Survive the Killer! (Place ID: 4580204640)
    Executor: Delta
    Fitur: ESP Killers (Merah), ESP Survivors (Biru), Auto Farm Loot,
           Auto Escape (Killer <20m), Kill All (Role Killer),
           Speed, JumpPower, Infinite Jump, Noclip
    Catatan: Deteksi killer diperbaiki dengan 5 metode.
]]

-- ============================================================
-- KONFIGURASI
-- ============================================================
local Config = {
    ESP_Killers = true,
    ESP_Survivors = true,
    ESP_Killer_Color = Color3.fromRGB(255, 0, 0),
    ESP_Survivor_Color = Color3.fromRGB(0, 0, 255),
    AutoFarmLoot = true,
    AutoEscape = true,
    EscapeRadius = 20,
    KillAll = false,
    Speed = 50,
    JumpPower = 100,
    InfiniteJump = true,
    Noclip = false,
    RefreshRate = 0.1
}

-- ============================================================
-- SERVICES
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- State
local ESPObjects = {}
local CurrentRole = "Unknown"

-- ============================================================
-- DETEKSI KILLER (5 METODE)
-- ============================================================
local function isKiller(player)
    if not player then return false end
    
    -- Metode 1: Atribut Role di Character/Player
    local char = player.Character
    if char then
        local roleAttr = char:GetAttribute("Role") or player:GetAttribute("Role")
        if roleAttr then
            local r = string.lower(tostring(roleAttr))
            if string.find(r, "killer") or string.find(r, "murder") then
                return true
            end
        end
        
        -- Metode 2: ObjectValue/StringValue/BoolValue di Character
        for _, obj in pairs(char:GetChildren()) do
            if obj:IsA("ObjectValue") or obj:IsA("StringValue") or obj:IsA("BoolValue") then
                local n = string.lower(obj.Name)
                if string.find(n, "role") or string.find(n, "killer") then
                    if obj:IsA("ObjectValue") and obj.Value == player then return true end
                    if obj:IsA("StringValue") and string.find(string.lower(obj.Value), "killer") then return true end
                    if obj:IsA("BoolValue") and obj.Value == true and string.find(n, "killer") then return true end
                end
            end
        end
        
        -- Metode 3: Tool name (fallback)
        for _, tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                local tn = string.lower(tool.Name)
                if string.find(tn, "knife") or string.find(tn, "weapon") or string.find(tn, "blade") or string.find(tn, "sword") then
                    return true
                end
            end
        end
    end
    
    -- Metode 4: Team name
    if player.Team then
        local tn = string.lower(player.Team.Name)
        if string.find(tn, "killer") or string.find(tn, "murder") then
            return true
        end
    end
    
    -- Metode 5: Folder "Killers" di Workspace
    local killerFolder = Workspace:FindFirstChild("Killers") or Workspace:FindFirstChild("Killer")
    if killerFolder then
        for _, obj in pairs(killerFolder:GetChildren()) do
            if obj.Name == player.Name or obj.Name == tostring(player.UserId) then
                return true
            end
        end
    end
    
    return false
end

local function detectMyRole()
    if isKiller(LocalPlayer) then
        return "Killer"
    end
    return "Survivor"
end

-- ============================================================
-- ESP SYSTEM
-- ============================================================
local function createESP(player, color)
    if player == LocalPlayer then return end
    
    local char = player.Character
    if not char then return end
    
    local head = char:FindFirstChild("Head")
    if not head then return end
    
    if ESPObjects[player] then
        ESPObjects[player]:Destroy()
    end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_" .. player.Name
    billboard.Size = UDim2.new(0, 120, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = head
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = player.Name
    label.TextColor3 = color
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.Parent = billboard
    
    ESPObjects[player] = billboard
end

local function removeESP(player)
    if ESPObjects[player] then
        ESPObjects[player]:Destroy()
        ESPObjects[player] = nil
    end
end

local function updateESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        
        local killer = isKiller(player)
        
        if killer and Config.ESP_Killers then
            createESP(player, Config.ESP_Killer_Color)
        elseif not killer and Config.ESP_Survivors then
            createESP(player, Config.ESP_Survivor_Color)
        else
            removeESP(player)
        end
    end
end

-- ============================================================
-- AUTO FARM LOOT
-- ============================================================
local ValuableLoot = {
    ["gold"] = true, ["diamond"] = true, ["ruby"] = true,
    ["emerald"] = true, ["crystal"] = true, ["artifact"] = true,
    ["relic"] = true, ["treasure"] = true, ["cash"] = true,
    ["coin"] = true, ["money"] = true, ["gem"] = true,
    ["candy"] = true, ["present"] = true, ["gift"] = true
}

local function isValuableLoot(obj)
    if not obj then return false end
    local name = string.lower(obj.Name)
    for valuable, _ in pairs(ValuableLoot) do
        if string.find(name, valuable) then return true end
    end
    return false
end

local lastFarmTime = 0
local function autoFarmLoot()
    if not Config.AutoFarmLoot then return end
    if CurrentRole == "Killer" then return end
    if tick() - lastFarmTime < 1 then return end
    lastFarmTime = tick()
    
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local currentMap = Workspace:FindFirstChild("CurrentMap") or Workspace
    local nearestLoot = nil
    local shortestDist = math.huge
    
    for _, obj in pairs(currentMap:GetDescendants()) do
        if isValuableLoot(obj) then
            local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
            if part and part.Parent then
                local dist = (part.Position - hrp.Position).Magnitude
                if dist < shortestDist and dist < 150 then
                    shortestDist = dist
                    nearestLoot = part
                end
            end
        end
    end
    
    if nearestLoot then
        hrp.CFrame = CFrame.new(nearestLoot.Position + Vector3.new(0, 3, 0))
    end
end

-- ============================================================
-- AUTO ESCAPE
-- ============================================================
local lastEscapeTime = 0
local function findSafeSpot()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    
    local currentMap = Workspace:FindFirstChild("CurrentMap")
    if not currentMap then
        return hrp.Position + Vector3.new(math.random(-200, 200), 50, math.random(-200, 200))
    end
    
    local safeParts = {}
    for _, obj in pairs(currentMap:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = string.lower(obj.Name)
            if string.find(name, "spawn") or string.find(name, "safe") or
               string.find(name, "exit") or string.find(name, "lobby") or
               string.find(name, "hide") or string.find(name, "closet") then
                table.insert(safeParts, obj)
            end
        end
    end
    
    if #safeParts > 0 then
        local chosen = safeParts[math.random(1, #safeParts)]
        return chosen.Position + Vector3.new(0, 5, 0)
    end
    
    return Vector3.new(math.random(-300, 300), 100, math.random(-300, 300))
end

local function autoEscape()
    if not Config.AutoEscape then return end
    if CurrentRole == "Killer" then return end
    if tick() - lastEscapeTime < 2 then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if isKiller(player) then
            local pChar = player.Character
            if pChar then
                local pHrp = pChar:FindFirstChild("HumanoidRootPart")
                if pHrp then
                    local dist = (pHrp.Position - hrp.Position).Magnitude
                    if dist <= Config.EscapeRadius then
                        local safePos = findSafeSpot()
                        if safePos then
                            hrp.CFrame = CFrame.new(safePos)
                            lastEscapeTime = tick()
                        end
                        break
                    end
                end
            end
        end
    end
end

-- ============================================================
-- KILL ALL (Killer)
-- ============================================================
local function killAll()
    if CurrentRole ~= "Killer" then return end
    
    local remotes = {}
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local name = string.lower(obj.Name)
            if string.find(name, "kill") or string.find(name, "attack") or
               string.find(name, "hit") or string.find(name, "damage") or
               string.find(name, "stab") then
                table.insert(remotes, obj)
            end
        end
    end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if isKiller(player) then continue end
        
        local pChar = player.Character
        if not pChar then continue end
        local pHumanoid = pChar:FindFirstChildOfClass("Humanoid")
        if not pHumanoid or pHumanoid.Health <= 0 then continue end
        
        for _, remote in pairs(remotes) do
            pcall(function()
                if remote:IsA("RemoteEvent") then
                    remote:FireServer(player)
                    remote:FireServer(pChar)
                elseif remote:IsA("RemoteFunction") then
                    remote:InvokeServer(player)
                end
            end)
        end
    end
    
    Config.KillAll = false
end

-- ============================================================
-- SPEED & JUMP
-- ============================================================
local function setSpeed(value)
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = value
    end
end

local function setJumpPower(value)
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.JumpPower = value
    end
end

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump and LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- Noclip
local function toggleNoclip(state)
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not state
        end
    end
end

-- ============================================================
-- MAIN LOOP
-- ============================================================
local lastUpdate = 0
local lastRoleCheck = 0

RunService.Heartbeat:Connect(function()
    local now = tick()
    
    if now - lastRoleCheck > 1 then
        CurrentRole = detectMyRole()
        lastRoleCheck = now
    end
    
    if now - lastUpdate > Config.RefreshRate then
        updateESP()
        lastUpdate = now
    end
    
    if Config.AutoFarmLoot then autoFarmLoot() end
    if Config.AutoEscape then autoEscape() end
    if Config.KillAll then killAll() end
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        updateESP()
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

-- ============================================================
-- GUI
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "STK_CustomGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 200, 0, 320)
MainFrame.Position = UDim2.new(0, 20, 0, 100)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 25)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Title.Text = "STK Custom FIXED"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Title.Parent = MainFrame

local function createToggle(name, yPos, initState, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 180, 0, 22)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = initState and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(40, 40, 40)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 11
    btn.Parent = MainFrame
    
    local state = initState
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(40, 40, 40)
        callback(state)
    end)
end

createToggle("ESP Killers (Merah)", 30, true, function(s) Config.ESP_Killers = s end)
createToggle("ESP Survivors (Biru)", 55, true, function(s) Config.ESP_Survivors = s end)
createToggle("Auto Farm Loot", 80, true, function(s) Config.AutoFarmLoot = s end)
createToggle("Auto Escape", 105, true, function(s) Config.AutoEscape = s end)
createToggle("Infinite Jump", 130, true, function(s) Config.InfiniteJump = s end)
createToggle("Noclip", 155, false, function(s) Config.Noclip = s; toggleNoclip(s) end)

-- Speed Box
local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.new(0, 180, 0, 20)
SpeedLabel.Position = UDim2.new(0, 10, 0, 185)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Text = "Speed: " .. Config.Speed
SpeedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedLabel.Font = Enum.Font.Gotham
SpeedLabel.TextSize = 11
SpeedLabel.Parent = MainFrame

local SpeedBox = Instance.new("TextBox")
SpeedBox.Size = UDim2.new(0, 180, 0, 22)
SpeedBox.Position = UDim2.new(0, 10, 0, 207)
SpeedBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
SpeedBox.Text = tostring(Config.Speed)
SpeedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedBox.Font = Enum.Font.Gotham
SpeedBox.TextSize = 11
SpeedBox.Parent = MainFrame

SpeedBox.FocusLost:Connect(function()
    local val = tonumber(SpeedBox.Text)
    if val then
        Config.Speed = val
        setSpeed(val)
        SpeedLabel.Text = "Speed: " .. val
    end
end)

-- Jump Box
local JumpLabel = Instance.new("TextLabel")
JumpLabel.Size = UDim2.new(0, 180, 0, 20)
JumpLabel.Position = UDim2.new(0, 10, 0, 235)
JumpLabel.BackgroundTransparency = 1
JumpLabel.Text = "JumpPower: " .. Config.JumpPower
JumpLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
JumpLabel.Font = Enum.Font.Gotham
JumpLabel.TextSize = 11
JumpLabel.Parent = MainFrame

local JumpBox = Instance.new("TextBox")
JumpBox.Size = UDim2.new(0, 180, 0, 22)
JumpBox.Position = UDim2.new(0, 10, 0, 257)
JumpBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
JumpBox.Text = tostring(Config.JumpPower)
JumpBox.TextColor3 = Color3.fromRGB(255, 255, 255)
JumpBox.Font = Enum.Font.Gotham
JumpBox.TextSize = 11
JumpBox.Parent = MainFrame

JumpBox.FocusLost:Connect(function()
    local val = tonumber(JumpBox.Text)
    if val then
        Config.JumpPower = val
        setJumpPower(val)
        JumpLabel.Text = "JumpPower: " .. val
    end
end)

-- Kill All Button
local killBtn = Instance.new("TextButton")
killBtn.Size = UDim2.new(0, 180, 0, 25)
killBtn.Position = UDim2.new(0, 10, 0, 285)
killBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
killBtn.Text = "KILL ALL (Killer)"
killBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
killBtn.Font = Enum.Font.GothamBold
killBtn.TextSize = 11
killBtn.Parent = MainFrame

killBtn.MouseButton1Click:Connect(function()
    Config.KillAll = true
end)

-- Role Label
local roleLabel = Instance.new("TextLabel")
roleLabel.Size = UDim2.new(1, 0, 0, 20)
roleLabel.Position = UDim2.new(0, 0, 1, -25)
roleLabel.BackgroundTransparency = 1
roleLabel.Text = "Role: Detecting..."
roleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
roleLabel.Font = Enum.Font.Gotham
roleLabel.TextSize = 10
roleLabel.Parent = MainFrame

task.spawn(function()
    while task.wait(1) do
        roleLabel.Text = "Role: " .. CurrentRole
    end
end)

print("[STK FIXED] Loaded. Role: " .. CurrentRole)