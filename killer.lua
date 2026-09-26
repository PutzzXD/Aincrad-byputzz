--[[
    Script: Survive the Killer! - Custom Feature Pack
    Target: Survive the Killer! (Place ID: 4580204640)
    Executor: Delta Executor
    Fitur: ESP Killers (Merah), ESP Survivors (Biru), Auto Farm Loot Mahal,
           Auto Escape (Killer <20m), Kill All (Role Killer)
    Catatan: Kill All bergantung pada RemoteEvent internal game.
             Jika struktur berubah, fungsi ini mungkin gagal.
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
    RefreshRate = 0.1,
    MaxSafeDistance = 500
}

-- ============================================================
-- SERVICES & VARIABEL
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- State
local ESPObjects = {}
local CurrentRole = "Unknown"
local LootCache = {}

-- ============================================================
-- DETEKSI ROLE
-- ============================================================
local function detectRole()
    local char = LocalPlayer.Character
    if not char then return "Unknown" end
    
    -- Cek berdasarkan nama tool/tag
    for _, obj in pairs(char:GetChildren()) do
        if obj:IsA("Tool") then
            if string.find(string.lower(obj.Name), "knife") or 
               string.find(string.lower(obj.Name), "weapon") then
                return "Killer"
            end
        end
    end
    
    -- Cek via atribut game
    local matchInfo = ReplicatedStorage:FindFirstChild("MatchInfo")
    if matchInfo then
        local killer = matchInfo:FindFirstChild("Killer")
        if killer and killer.Value == LocalPlayer then
            return "Killer"
        end
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
    
    -- Hapus ESP lama jika ada
    if ESPObjects[player] then
        ESPObjects[player]:Destroy()
    end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_" .. player.Name
    billboard.Size = UDim2.new(0, 100, 0, 40)
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
    local role = CurrentRole
    
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        
        local playerRole = "Survivor"
        
        -- Deteksi role player lain
        local char = player.Character
        if char then
            for _, obj in pairs(char:GetChildren()) do
                if obj:IsA("Tool") then
                    if string.find(string.lower(obj.Name), "knife") or 
                       string.find(string.lower(obj.Name), "weapon") then
                        playerRole = "Killer"
                        break
                    end
                end
            end
        end
        
        -- Cek via MatchInfo
        local matchInfo = ReplicatedStorage:FindFirstChild("MatchInfo")
        if matchInfo then
            local killer = matchInfo:FindFirstChild("Killer")
            if killer and killer.Value == player then
                playerRole = "Killer"
            end
        end
        
        if playerRole == "Killer" and Config.ESP_Killers then
            createESP(player, Config.ESP_Killer_Color)
        elseif playerRole == "Survivor" and Config.ESP_Survivors then
            createESP(player, Config.ESP_Survivor_Color)
        else
            removeESP(player)
        end
    end
end

-- ============================================================
-- AUTO FARM LOOT MAHAL
-- ============================================================
-- Daftar loot mahal (nilai tinggi)
local ValuableLoot = {
    ["Gold"] = true,
    ["Diamond"] = true,
    ["Ruby"] = true,
    ["Emerald"] = true,
    ["Crystal"] = true,
    ["Artifact"] = true,
    ["Relic"] = true,
    ["Treasure"] = true,
    ["Cash"] = true,
    ["Coin"] = true,
    ["Money"] = true
}

local function isValuableLoot(obj)
    if not obj then return false end
    local name = string.lower(obj.Name)
    
    for valuable, _ in pairs(ValuableLoot) do
        if string.find(name, string.lower(valuable)) then
            return true
        end
    end
    
    return false
end

local function autoFarmLoot()
    if not Config.AutoFarmLoot then return end
    if CurrentRole == "Killer" then return end -- Killer tidak farm loot
    
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- Cari loot di workspace
    local currentMap = Workspace:FindFirstChild("CurrentMap")
    if not currentMap then return end
    
    local nearestLoot = nil
    local shortestDist = math.huge
    
    for _, obj in pairs(currentMap:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            if isValuableLoot(obj) then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                if part then
                    local dist = (part.Position - hrp.Position).Magnitude
                    if dist < shortestDist and dist < 100 then
                        shortestDist = dist
                        nearestLoot = part
                    end
                end
            end
        end
    end
    
    if nearestLoot then
        hrp.CFrame = CFrame.new(nearestLoot.Position + Vector3.new(0, 3, 0))
    end
end

-- ============================================================
-- AUTO ESCAPE (Killer < 20m → Teleport Random)
-- ============================================================
local function findSafeSpot()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    
    -- Coba ambil spawn points atau area aman dari map
    local currentMap = Workspace:FindFirstChild("CurrentMap")
    if not currentMap then
        -- Fallback: offset random di sekitar posisi
        local offset = Vector3.new(
            math.random(-200, 200),
            50,
            math.random(-200, 200)
        )
        return hrp.Position + offset
    end
    
    -- Cari bagian bernama "Spawn", "Safe", "Exit", "Lobby"
    local safeParts = {}
    for _, obj in pairs(currentMap:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = string.lower(obj.Name)
            if string.find(name, "spawn") or 
               string.find(name, "safe") or
               string.find(name, "exit") or
               string.find(name, "lobby") or
               string.find(name, "hide") then
                table.insert(safeParts, obj)
            end
        end
    end
    
    if #safeParts > 0 then
        local chosen = safeParts[math.random(1, #safeParts)]
        return chosen.Position + Vector3.new(0, 5, 0)
    end
    
    -- Fallback terakhir: posisi acak dalam radius map
    return Vector3.new(
        math.random(-300, 300),
        100,
        math.random(-300, 300)
    )
end

local function autoEscape()
    if not Config.AutoEscape then return end
    if CurrentRole == "Killer" then return end -- Killer tidak perlu escape
    
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end
    
    -- Cari killer terdekat
    local nearestKiller = nil
    local shortestDist = math.huge
    
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        
        local pChar = player.Character
        if not pChar then continue end
        
        local pRole = "Survivor"
        for _, obj in pairs(pChar:GetChildren()) do
            if obj:IsA("Tool") then
                if string.find(string.lower(obj.Name), "knife") or 
                   string.find(string.lower(obj.Name), "weapon") then
                    pRole = "Killer"
                    break
                end
            end
        end
        
        -- Cek MatchInfo
        local matchInfo = ReplicatedStorage:FindFirstChild("MatchInfo")
        if matchInfo then
            local killer = matchInfo:FindFirstChild("Killer")
            if killer and killer.Value == player then
                pRole = "Killer"
            end
        end
        
        if pRole == "Killer" then
            local pHrp = pChar:FindFirstChild("HumanoidRootPart")
            if pHrp then
                local dist = (pHrp.Position - hrp.Position).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    nearestKiller = pHrp
                end
            end
        end
    end
    
    -- Jika killer dalam radius 20m, teleport ke tempat aman
    if nearestKiller and shortestDist <= Config.EscapeRadius then
        local safePos = findSafeSpot()
        if safePos then
            hrp.CFrame = CFrame.new(safePos)
        end
    end
end

-- ============================================================
-- KILL ALL (Role: Killer)
-- ============================================================
local function killAll()
    if not Config.KillAll then return end
    if CurrentRole ~= "Killer" then return end
    
    -- Cari RemoteEvent untuk kill
    local remotes = {}
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local name = string.lower(obj.Name)
            if string.find(name, "kill") or 
               string.find(name, "attack") or
               string.find(name, "hit") or
               string.find(name, "damage") then
                table.insert(remotes, obj)
            end
        end
    end
    
    -- Eksekusi kill pada semua survivor
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        
        local pChar = player.Character
        if not pChar then continue end
        
        local pHumanoid = pChar:FindFirstChildOfClass("Humanoid")
        if not pHumanoid or pHumanoid.Health <= 0 then continue end
        
        -- Coba semua remote yang ditemukan
        for _, remote in pairs(remotes) do
            pcall(function()
                if remote:IsA("RemoteEvent") then
                    remote:FireServer(player)
                elseif remote:IsA("RemoteFunction") then
                    remote:InvokeServer(player)
                end
            end)
        end
        
        -- Fallback: coba tool-based kill
        local char = LocalPlayer.Character
        if char then
            for _, tool in pairs(char:GetChildren()) do
                if tool:IsA("Tool") then
                    pcall(function()
                        tool:Activate()
                    end)
                end
            end
        end
    end
    
    -- Reset flag setelah eksekusi
    Config.KillAll = false
end

-- ============================================================
-- MAIN LOOP
-- ============================================================
local lastUpdate = 0
local lastRoleCheck = 0

RunService.Heartbeat:Connect(function()
    local now = tick()
    
    -- Update role setiap 1 detik
    if now - lastRoleCheck > 1 then
        CurrentRole = detectRole()
        lastRoleCheck = now
    end
    
    -- Update ESP
    if now - lastUpdate > Config.RefreshRate then
        updateESP()
        lastUpdate = now
    end
    
    -- Auto Farm
    if Config.AutoFarmLoot then
        autoFarmLoot()
    end
    
    -- Auto Escape
    if Config.AutoEscape then
        autoEscape()
    end
    
    -- Kill All
    if Config.KillAll then
        killAll()
    end
end)

-- ============================================================
-- EVENT HANDLERS
-- ============================================================
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        wait(1)
        updateESP()
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

-- ============================================================
-- GUI SEDERHANA
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "STK_CustomGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 180, 0, 200)
MainFrame.Position = UDim2.new(0, 20, 0, 100)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 25)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Title.Text = "STK Custom"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Title.Parent = MainFrame

local function createToggle(name, yPos, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 160, 0, 22)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 11
    btn.Parent = MainFrame
    
    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(40, 40, 40)
        callback(state)
    end)
end

createToggle("ESP Killers", 30, function(s) Config.ESP_Killers = s end)
createToggle("ESP Survivors", 55, function(s) Config.ESP_Survivors = s end)
createToggle("Auto Farm Loot", 80, function(s) Config.AutoFarmLoot = s end)
createToggle("Auto Escape", 105, function(s) Config.AutoEscape = s end)

-- Tombol Kill All terpisah
local killBtn = Instance.new("TextButton")
killBtn.Size = UDim2.new(0, 160, 0, 25)
killBtn.Position = UDim2.new(0, 10, 0, 135)
killBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
killBtn.Text = "KILL ALL (Killer)"
killBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
killBtn.Font = Enum.Font.GothamBold
killBtn.TextSize = 11
killBtn.Parent = MainFrame

killBtn.MouseButton1Click:Connect(function()
    Config.KillAll = true
end)

-- Info role
local roleLabel = Instance.new("TextLabel")
roleLabel.Size = UDim2.new(1, 0, 0, 20)
roleLabel.Position = UDim2.new(0, 0, 1, -25)
roleLabel.BackgroundTransparency = 1
roleLabel.Text = "Role: Detecting..."
roleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
roleLabel.Font = Enum.Font.Gotham
roleLabel.TextSize = 10
roleLabel.Parent = MainFrame

-- Update role label
spawn(function()
    while wait(1) do
        roleLabel.Text = "Role: " .. CurrentRole
    end
end)

print("[STK Custom] Script loaded. Role: " .. CurrentRole)