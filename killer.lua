--[[
    Script: Survive the Killer! - Custom Feature Pack v2
    Target: Survive the Killer! (Place ID: 4580204640)
    Executor: Delta
    Update: UI panel toggle, Auto Escape 30m, Auto Farm Loot fix,
            Auto Kabur saat pintu terbuka
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
    EscapeRadius = 30,
    AutoKabur = true,
    KillAll = false,
    Speed = 50,
    JumpPower = 100,
    InfiniteJump = true,
    Noclip = false,
    RefreshRate = 0.1,
    UIOpen = true
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

local ESPObjects = {}
local CurrentRole = "Unknown"
local LastFarmTime = 0
local LastEscapeTime = 0
local LastKaburTime = 0
local DoorOpened = false
local UIOpen = true

-- ============================================================
-- DETEKSI KILLER
-- ============================================================
local function isKiller(player)
    if not player then return false end
    local char = player.Character
    if char then
        local roleAttr = char:GetAttribute("Role") or player:GetAttribute("Role")
        if roleAttr then
            local r = string.lower(tostring(roleAttr))
            if string.find(r, "killer") or string.find(r, "murder") then return true end
        end
        for _, obj in pairs(char:GetChildren()) do
            if obj:IsA("ObjectValue") or obj:IsA("StringValue") or obj:IsA("BoolValue") then
                local n = string.lower(obj.Name)
                if string.find(n, "role") or string.find(n, "killer") then
                    if obj:IsA("ObjectValue") and obj.Value == player then return true end
                    if obj:IsA("StringValue") and string.find(string.lower(obj.Value), "killer") then return true end
                    if obj:IsA("BoolValue") and obj.Value and string.find(n, "killer") then return true end
                end
            end
        end
        for _, tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                local tn = string.lower(tool.Name)
                if string.find(tn, "knife") or string.find(tn, "weapon") or string.find(tn, "blade") or string.find(tn, "sword") then return true end
            end
        end
    end
    if player.Team then
        local tn = string.lower(player.Team.Name)
        if string.find(tn, "killer") or string.find(tn, "murder") then return true end
    end
    local killerFolder = Workspace:FindFirstChild("Killers") or Workspace:FindFirstChild("Killer")
    if killerFolder then
        for _, obj in pairs(killerFolder:GetChildren()) do
            if obj.Name == player.Name or obj.Name == tostring(player.UserId) then return true end
        end
    end
    return false
end

local function detectMyRole()
    if isKiller(LocalPlayer) then return "Killer" end
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
    if ESPObjects[player] then ESPObjects[player]:Destroy() end
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
-- AUTO FARM LOOT (FIXED)
-- ============================================================
-- Scan semua objek yang bisa di-collect, bukan cuma nama
local function isCollectible(obj)
    if not obj then return false end
    if not obj:IsA("BasePart") and not obj:IsA("Model") then return false end
    local name = string.lower(obj.Name)
    -- Filter umum loot STK
    if string.find(name, "loot") or string.find(name, "coin") or
       string.find(name, "cash") or string.find(name, "money") or
       string.find(name, "gem") or string.find(name, "gold") or
       string.find(name, "diamond") or string.find(name, "crystal") or
       string.find(name, "candy") or string.find(name, "present") or
       string.find(name, "gift") or string.find(name, "artifact") or
       string.find(name, "relic") or string.find(name, "treasure") or
       string.find(name, "ruby") or string.find(name, "emerald") then
        return true
    end
    -- Cek atribut umum loot
    if obj:GetAttribute("Value") or obj:GetAttribute("Worth") or obj:GetAttribute("Price") then
        return true
    end
    return false
end

local function findNearestLoot()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    
    local best, bestDist = nil, math.huge
    local searchRoots = {}
    local cm = Workspace:FindFirstChild("CurrentMap")
    if cm then table.insert(searchRoots, cm) end
    table.insert(searchRoots, Workspace)
    
    for _, root in pairs(searchRoots) do
        for _, obj in pairs(root:GetDescendants()) do
            if isCollectible(obj) then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                if part and part.Parent then
                    local dist = (part.Position - hrp.Position).Magnitude
                    if dist < bestDist and dist < 300 then
                        bestDist = dist
                        best = part
                    end
                end
            end
        end
    end
    return best
end

local function autoFarmLoot()
    if not Config.AutoFarmLoot then return end
    if CurrentRole == "Killer" then return end
    if tick() - LastFarmTime < 0.5 then return end
    LastFarmTime = tick()
    
    local target = findNearestLoot()
    if not target then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    hrp.CFrame = CFrame.new(target.Position + Vector3.new(0, 3, 0))
end

-- ============================================================
-- AUTO ESCAPE (Killer < 30m)
-- ============================================================
local function findSafeSpot()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    
    local cm = Workspace:FindFirstChild("CurrentMap")
    if not cm then
        return hrp.Position + Vector3.new(math.random(-250, 250), 50, math.random(-250, 250))
    end
    
    local safeParts = {}
    for _, obj in pairs(cm:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = string.lower(obj.Name)
            if string.find(name, "spawn") or string.find(name, "safe") or
               string.find(name, "exit") or string.find(name, "lobby") or
               string.find(name, "hide") or string.find(name, "closet") or
               string.find(name, "locker") or string.find(name, "cabinet") then
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
    if tick() - LastEscapeTime < 1.5 then return end
    
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
                            LastEscapeTime = tick()
                        end
                        break
                    end
                end
            end
        end
    end
end

-- ============================================================
-- AUTO KABUR SAAT PINTU TERBUKA
-- ============================================================
-- Deteksi pintu terbuka: cari objek bernama "Door"/"Exit"/"Gate" yang CanCollide=false
-- atau atribut "Open"=true, atau CFrame berubah (terbuka)
local function isDoorOpen()
    local cm = Workspace:FindFirstChild("CurrentMap") or Workspace
    for _, obj in pairs(cm:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = string.lower(obj.Name)
            if string.find(name, "door") or string.find(name, "exit") or
               string.find(name, "gate") or string.find(name, "escape") or
               string.find(name, "open") then
                -- Cek berbagai kondisi pintu terbuka
                if obj:GetAttribute("Open") == true then return obj end
                if obj:GetAttribute("IsOpen") == true then return obj end
                if obj:GetAttribute("Opened") == true then return obj end
                if obj.CanCollide == false and obj.Transparency > 0.5 then return obj end
                if obj:GetAttribute("Value") == true then return obj end
            end
        end
    end
    return nil
end

-- Cari pintu keluar utama sebagai target kabur
local function findEscapeDoor()
    local cm = Workspace:FindFirstChild("CurrentMap") or Workspace
    local candidates = {}
    for _, obj in pairs(cm:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = string.lower(obj.Name)
            if string.find(name, "exit") or string.find(name, "escape") or
               string.find(name, "door") or string.find(name, "gate") then
                table.insert(candidates, obj)
            end
        end
    end
    return candidates
end

local function autoKabur()
    if not Config.AutoKabur then return end
    if CurrentRole == "Killer" then return end
    if tick() - LastKaburTime < 1 then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end
    
    -- Cek apakah pintu terbuka
    local openDoor = isDoorOpen()
    if not openDoor then
        DoorOpened = false
        return
    end
    
    DoorOpened = true
    LastKaburTime = tick()
    
    -- Teleport ke pintu keluar
    local doors = findEscapeDoor()
    if #doors > 0 then
        -- Pilih pintu terdekat dari hrp
        local best, bestDist = nil, math.huge
        for _, d in pairs(doors) do
            local dist = (d.Position - hrp.Position).Magnitude
            if dist < bestDist then
                bestDist = dist
                best = d
            end
        end
        if best then
            hrp.CFrame = CFrame.new(best.Position + Vector3.new(0, 5, 0))
        end
    end
end

-- ============================================================
-- KILL ALL
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
-- SPEED / JUMP / NOCLIP
-- ============================================================
local function setSpeed(value)
    local char = LocalPlayer.Character
    if not char then return end
    local h = char:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed = value end
end

local function setJumpPower(value)
    local char = LocalPlayer.Character
    if not char then return end
    local h = char:FindFirstChildOfClass("Humanoid")
    if h then h.JumpPower = value end
end

UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump and LocalPlayer.Character then
        local h = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

local function toggleNoclip(state)
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = not state end
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
    if Config.AutoKabur then autoKabur() end
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
-- UI PANEL (BUKA/TUTUP)
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "STK_CustomGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Tombol toggle utama (lingkaran kecil)
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 45, 0, 45)
ToggleBtn.Position = UDim2.new(0, 20, 0, 100)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Text = "STK"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 11
ToggleBtn.Parent = ScreenGui
ToggleBtn.Active = true
ToggleBtn.Draggable = true

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0)
ToggleCorner.Parent = ToggleBtn

-- Frame utama
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 200, 0, 360)
MainFrame.Position = UDim2.new(0, 75, 0, 100)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = true
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 8)
FrameCorner.Parent = MainFrame

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 30)
Header.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Header.BorderSizePixel = 0
Header.Parent = MainFrame
local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 8)
HeaderCorner.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "STK Custom v2"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

-- Tombol close di header
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -30, 0, 2)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.Parent = Header
local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(1, 0)
CloseCorner.Parent = CloseBtn

-- Container scroll
local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -10, 1, -40)
Content.Position = UDim2.new(0, 5, 0, 35)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 4
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.Parent = MainFrame

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 5)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = Content

-- Toggle handler
CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

ToggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Fungsi bikin toggle
local function createToggle(name, initState, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 26)
    btn.BackgroundColor3 = initState and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(40, 40, 40)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 11
    btn.Parent = Content
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 5)
    c.Parent = btn
    
    local state = initState
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(40, 40, 40)
        callback(state)
    end)
end

-- Fungsi bikin label + textbox
local function createInput(labelText, initVal, callback)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 18)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText .. ": " .. tostring(initVal)
    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = Content
    
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, 0, 0, 24)
    box.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    box.Text = tostring(initVal)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Font = Enum.Font.Gotham
    box.TextSize = 11
    box.ClearTextOnFocus = false
    box.Parent = Content
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 5)
    bc.Parent = box
    
    box.FocusLost:Connect(function()
        local v = tonumber(box.Text)
        if v then
            lbl.Text = labelText .. ": " .. v
            callback(v)
        end
    end)
end

-- Isi konten UI
createToggle("ESP Killers (Merah)", true, function(s) Config.ESP_Killers = s end)
createToggle("ESP Survivors (Biru)", true, function(s) Config.ESP_Survivors = s end)
createToggle("Auto Farm Loot", true, function(s) Config.AutoFarmLoot = s end)
createToggle("Auto Escape (30m)", true, function(s) Config.AutoEscape = s end)
createToggle("Auto Kabur (Pintu Buka)", true, function(s) Config.AutoKabur = s end)
createToggle("Infinite Jump", true, function(s) Config.InfiniteJump = s end)
createToggle("Noclip", false, function(s) Config.Noclip = s; toggleNoclip(s) end)

createInput("Speed", Config.Speed, function(v) Config.Speed = v; setSpeed(v) end)
createInput("JumpPower", Config.JumpPower, function(v) Config.JumpPower = v; setJumpPower(v) end)

-- Tombol Kill All
local killBtn = Instance.new("TextButton")
killBtn.Size = UDim2.new(1, 0, 0, 28)
killBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
killBtn.Text = "KILL ALL (Killer)"
killBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
killBtn.Font = Enum.Font.GothamBold
killBtn.TextSize = 11
killBtn.Parent = Content
local kc = Instance.new("UICorner")
kc.CornerRadius = UDim.new(0, 5)
kc.Parent = killBtn
killBtn.MouseButton1Click:Connect(function()
    Config.KillAll = true
end)

-- Status label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Role: Detecting..."
StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 10
StatusLabel.Parent = Content

task.spawn(function()
    while task.wait(1) do
        local doorStatus = DoorOpened and " | Pintu: TERBUKA" or " | Pintu: tertutup"
        StatusLabel.Text = "Role: " .. CurrentRole .. doorStatus
    end
end)

print("[STK Custom v2] Loaded. Role: " .. CurrentRole)