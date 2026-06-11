-- ================== ELEMENT ARENA - ADVANCED EXPLOIT ==================
-- Berdasarkan struktur game yang ditemukan via Delta Console
-- By: Berdasarkan analisis screenshot

-- ================== LOAD RAYFIELD ==================
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua'))()

-- ================== SERVICES ==================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ================== VARIABLES ==================
-- Combat
local AutoFarmEnabled = false
local AimbotEnabled = false
local HitBoxExpanderEnabled = false
local AttackRange = 30
local FollowDistance = 10
local lastAttack = 0
local AttackDelay = 0.3
local targetPlayer = nil

-- Movement
local SpeedHackEnabled = false
local JumpHackEnabled = false
local FlyEnabled = false
local NoClipEnabled = false
local WalkSpeedValue = 50
local JumpPowerValue = 100

-- Visual
local ESPEnabled = false
local ShowHitBoxes = false

-- God Mode
local GodModeEnabled = false
local godModeConn = nil

-- Storage
local ESPObjects = {}
local HitBoxParts = {}

-- ================== CARI HITBOX PLAYER ==================
local function GetPlayerHitBox(player)
    local char = player.Character
    if not char then return nil end
    
    -- Cari HitBox (dari console terlihat ada banyak "HitBox | Part")
    local hitbox = char:FindFirstChild("HitBox")
    if not hitbox then
        -- Cari part yang namanya mengandung "HitBox"
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") and string.find(string.lower(part.Name), "hitbox") then
                return part
            end
        end
        -- Fallback ke HumanoidRootPart
        return char:FindFirstChild("HumanoidRootPart")
    end
    return hitbox
end

-- ================== CARI SEMUA HITBOX DI MAP ==================
local function FindAllHitBoxes()
    local hitboxes = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and string.find(string.lower(obj.Name), "hitbox") then
            table.insert(hitboxes, obj)
        end
    end
    return hitboxes
end

-- ================== EXPAND HITBOX (Bikin gampang kena serangan) ==================
local function ExpandHitBoxes(state)
    HitBoxExpanderEnabled = state
    
    if state then
        local hitboxes = FindAllHitBoxes()
        for _, hitbox in pairs(hitboxes) do
            -- Perbesar hitbox
            hitbox.Size = hitbox.Size * 2
            -- Bikin transparan biar ga ganggu visual
            hitbox.Transparency = 0.8
        end
        Rayfield:Notify({Title = "HitBox Expander", Content = "All hitboxes enlarged!", Duration = 2})
    else
        local hitboxes = FindAllHitBoxes()
        for _, hitbox in pairs(hitboxes) do
            hitbox.Size = hitbox.Size / 2
        end
    end
end

-- ================== GOD MODE ==================
local function SetupGodMode(state)
    GodModeEnabled = state
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    
    if state then
        hum.BreakJointsOnDeath = false
        local maxHealth = hum.MaxHealth
        
        if godModeConn then godModeConn:Disconnect() end
        godModeConn = hum.HealthChanged:Connect(function()
            if GodModeEnabled and hum and hum.Parent and hum.Health < maxHealth then
                hum.Health = maxHealth
            end
        end)
        
        Rayfield:Notify({Title = "God Mode", Content = "Activated!", Duration = 2})
    else
        if godModeConn then godModeConn:Disconnect() end
        godModeConn = nil
    end
end

-- ================== GET ALIVE PLAYERS ==================
local function GetAlivePlayers()
    local players = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    table.insert(players, player)
                end
            end
        end
    end
    return players
end

-- ================== GET CLOSEST PLAYER ==================
local function GetClosestPlayer()
    local closest = nil
    local closestDist = AttackRange
    local myChar = LocalPlayer.Character
    if not myChar then return nil end
    
    local myPos = myChar:FindFirstChild("HumanoidRootPart")
    if not myPos then return nil end
    
    for _, player in pairs(GetAlivePlayers()) do
        local hitbox = GetPlayerHitBox(player)
        if hitbox then
            local dist = (myPos.Position - hitbox.Position).Magnitude
            if dist < closestDist then
                closestDist = dist
                closest = player
            end
        end
    end
    return closest, closestDist
end

-- ================== AIMBOT (AUTO AIM KE HITBOX) ==================
local function DoAimbot(target)
    if not AimbotEnabled then return end
    if not target then return end
    
    local hitbox = GetPlayerHitBox(target)
    if not hitbox then return end
    
    -- Arahkan kamera ke hitbox target
    local cameraCF = CFrame.new(Camera.CFrame.Position, hitbox.Position)
    Camera.CFrame = cameraCF
end

-- ================== AUTO ATTACK ==================
local function DoAttack(target)
    if not target then return end
    if tick() - lastAttack < AttackDelay then return end
    
    local hitbox = GetPlayerHitBox(target)
    if not hitbox then return end
    
    local myChar = LocalPlayer.Character
    if not myChar then return end
    
    local myHrp = myChar:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end
    
    local distance = (myHrp.Position - hitbox.Position).Magnitude
    
    if distance <= AttackRange then
        -- Method 1: Fire remote events
        local replicatedStorage = game:GetService("ReplicatedStorage")
        for _, remote in pairs(replicatedStorage:GetDescendants()) do
            if remote:IsA("RemoteEvent") then
                pcall(function() remote:FireServer(hitbox) end)
            end
        end
        
        -- Method 2: Simulate click on hitbox
        local mouse = LocalPlayer:GetMouse()
        local oldTarget = mouse.Target
        mouse.Target = hitbox
        pcall(function()
            local VirtualUser = game:GetService("VirtualUser")
            VirtualUser:CaptureController()
            VirtualUser:ClickButton1(Vector2.new(0,0))
        end)
        mouse.Target = oldTarget
        
        -- Method 3: Activate tool
        for _, tool in pairs(myChar:GetChildren()) do
            if tool:IsA("Tool") then
                pcall(function() tool:Activate() end)
            end
        end
        
        lastAttack = tick()
    end
end

-- ================== AUTO FOLLOW ==================
local function FollowTarget(target)
    if not AutoFarmEnabled then return end
    if not target then return end
    
    local myChar = LocalPlayer.Character
    local targetHitbox = GetPlayerHitBox(target)
    
    if not myChar or not targetHitbox then return end
    
    local myHrp = myChar:FindFirstChild("HumanoidRootPart")
    if not myHrp then return end
    
    local distance = (myHrp.Position - targetHitbox.Position).Magnitude
    
    -- Teleport kalau terlalu jauh
    if distance > FollowDistance + 15 then
        myHrp.CFrame = CFrame.new(targetHitbox.Position) * CFrame.new(0, 0, FollowDistance)
    else
        -- Gerak ke arah target
        local direction = (targetHitbox.Position - myHrp.Position).Unit
        local hum = myChar:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:MoveTo(myHrp.Position + direction * 5)
        end
    end
end

-- ================== AUTO FARM LOOP ==================
local function AutoFarmLoop()
    if not (AutoFarmEnabled or AimbotEnabled) then return end
    
    local target, dist = GetClosestPlayer()
    
    if target then
        targetPlayer = target
        
        if AutoFarmEnabled then
            FollowTarget(target)
            if dist <= AttackRange then
                DoAttack(target)
            end
        end
        
        if AimbotEnabled then
            DoAimbot(target)
        end
    end
end

-- ================== MOVEMENT HACKS ==================
local function ApplyMovementHacks()
    local char = LocalPlayer.Character
    if not char then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        if SpeedHackEnabled then
            hum.WalkSpeed = WalkSpeedValue
        end
        
        if JumpHackEnabled then
            hum.JumpPower = JumpPowerValue
            hum.UseJumpPower = true
        end
    end
end

-- ================== FLY FUNCTION ==================
local flyConnection = nil
local function StartFly()
    local char = LocalPlayer.Character
    if not char then return end
    
    local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
    if not torso then return end
    
    local bodyGyro = Instance.new("BodyGyro", torso)
    bodyGyro.P = 9e4
    bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    
    local bodyVelocity = Instance.new("BodyVelocity", torso)
    bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    
    flyConnection = RunService.RenderStepped:Connect(function()
        if not FlyEnabled then return end
        
        local moveDirection = Vector3.zero
        local uis = UserInputService
        if uis:IsKeyDown(Enum.KeyCode.W) then moveDirection = moveDirection + Camera.CFrame.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.S) then moveDirection = moveDirection - Camera.CFrame.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.A) then moveDirection = moveDirection - Camera.CFrame.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.D) then moveDirection = moveDirection + Camera.CFrame.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.Space) then moveDirection = moveDirection + Vector3.new(0, 1, 0) end
        if uis:IsKeyDown(Enum.KeyCode.LeftShift) then moveDirection = moveDirection - Vector3.new(0, 1, 0) end
        
        if moveDirection.Magnitude > 0 then
            moveDirection = moveDirection.Unit
            bodyVelocity.Velocity = moveDirection * 100
            bodyGyro.CFrame = CFrame.new(torso.Position, torso.Position + moveDirection)
        else
            bodyVelocity.Velocity = Vector3.zero
        end
    end)
end

local function StopFly()
    if flyConnection then flyConnection:Disconnect() end
    flyConnection = nil
end

-- ================== ESP ==================
local function CreateESP(player)
    if player == LocalPlayer or ESPObjects[player] then return end
    
    local box = Drawing.new("Square")
    box.Thickness = 1.5
    box.Filled = false
    box.Color = Color3.fromRGB(255, 0, 0)
    box.Visible = false
    
    local nameText = Drawing.new("Text")
    nameText.Size = 12
    nameText.Center = true
    nameText.Outline = true
    nameText.Color = Color3.fromRGB(255, 255, 255)
    nameText.Visible = false
    
    local healthText = Drawing.new("Text")
    healthText.Size = 10
    healthText.Center = true
    healthText.Outline = true
    healthText.Color = Color3.fromRGB(0, 255, 0)
    healthText.Visible = false
    
    ESPObjects[player] = {box, nameText, healthText}
end

local function UpdateESP()
    if not ESPEnabled then return end
    
    for player, objects in pairs(ESPObjects) do
        local box, nameText, healthText = unpack(objects)
        local hitbox = GetPlayerHitBox(player)
        local char = player.Character
        
        if hitbox and char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            local pos, onScreen = Camera:WorldToViewportPoint(hitbox.Position)
            
            if onScreen and hum and hum.Health > 0 then
                box.Size = Vector2.new(40, 60)
                box.Position = Vector2.new(pos.X - 20, pos.Y - 30)
                box.Visible = true
                
                nameText.Position = Vector2.new(pos.X, pos.Y - 40)
                nameText.Text = player.DisplayName or player.Name
                nameText.Visible = true
                
                healthText.Position = Vector2.new(pos.X, pos.Y + 35)
                healthText.Text = math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)
                healthText.Visible = true
            else
                box.Visible = false
                nameText.Visible = false
                healthText.Visible = false
            end
        end
    end
end

-- ================== SHOW HITBOXES VISUAL ==================
local function ToggleShowHitBoxes(state)
    ShowHitBoxes = state
    
    for _, hitbox in pairs(FindAllHitBoxes()) do
        if state then
            hitbox.Transparency = 0.5
            hitbox.Color = Color3.fromRGB(255, 0, 0)
        else
            hitbox.Transparency = 1
        end
    end
end

-- ================== CREATE RAYFIELD UI ==================
local Window = Rayfield:CreateWindow({
    Name = "ELEMENT ARENA | ADVANCED",
    Icon = 0,
    LoadingTitle = "Element Arena",
    LoadingSubtitle = "Based on Console Analysis",
    Theme = "Default",
    ConfigurationSaving = {Enabled = true, FolderName = "ElementArena", FileName = "Settings"}
})

-- Combat Tab
local CombatTab = Window:CreateTab("Combat", 0)

CombatTab:CreateSection("Auto Farm")
CombatTab:CreateToggle({Name = "Auto Farm (Follow & Attack)", CurrentValue = false, Flag = "AutoFarm", Callback = function(v) AutoFarmEnabled = v end})
CombatTab:CreateToggle({Name = "Aimbot (Auto Aim to HitBox)", CurrentValue = false, Flag = "Aimbot", Callback = function(v) AimbotEnabled = v end})
CombatTab:CreateSlider({Name = "Attack Range", Range = {5, 50}, Increment = 1, Suffix = "studs", CurrentValue = AttackRange, Flag = "AttackRange", Callback = function(v) AttackRange = v end})
CombatTab:CreateSlider({Name = "Follow Distance", Range = {3, 20}, Increment = 1, Suffix = "studs", CurrentValue = FollowDistance, Flag = "FollowDistance", Callback = function(v) FollowDistance = v end})
CombatTab:CreateSlider({Name = "Attack Delay", Range = {0.1, 1}, Increment = 0.05, Suffix = "sec", CurrentValue = AttackDelay, Flag = "AttackDelay", Callback = function(v) AttackDelay = v end})

CombatTab:CreateSection("HitBox")
CombatTab:CreateToggle({Name = "Expand HitBoxes (Easy to Hit)", CurrentValue = false, Flag = "ExpandHitBox", Callback = function(v) ExpandHitBoxes(v) end})
CombatTab:CreateToggle({Name = "Show HitBoxes Visual", CurrentValue = false, Flag = "ShowHitBox", Callback = function(v) ToggleShowHitBoxes(v) end})

CombatTab:CreateSection("God Mode")
CombatTab:CreateToggle({Name = "God Mode (Infinite Health)", CurrentValue = false, Flag = "GodMode", Callback = function(v) SetupGodMode(v) end})

-- Movement Tab
local MovementTab = Window:CreateTab("Movement", 1)

MovementTab:CreateSection("Speed & Jump")
MovementTab:CreateToggle({Name = "Speed Hack", CurrentValue = false, Flag = "SpeedHack", Callback = function(v) SpeedHackEnabled = v; ApplyMovementHacks() end})
MovementTab:CreateSlider({Name = "Walk Speed", Range = {16, 250}, Increment = 1, Suffix = "speed", CurrentValue = WalkSpeedValue, Flag = "WalkSpeed", Callback = function(v) WalkSpeedValue = v; if SpeedHackEnabled then ApplyMovementHacks() end end})
MovementTab:CreateToggle({Name = "Jump Hack", CurrentValue = false, Flag = "JumpHack", Callback = function(v) JumpHackEnabled = v; ApplyMovementHacks() end})
MovementTab:CreateSlider({Name = "Jump Power", Range = {50, 300}, Increment = 5, Suffix = "power", CurrentValue = JumpPowerValue, Flag = "JumpPower", Callback = function(v) JumpPowerValue = v; if JumpHackEnabled then ApplyMovementHacks() end end})

MovementTab:CreateSection("Flight")
MovementTab:CreateToggle({Name = "Fly Mode", CurrentValue = false, Flag = "FlyMode", Callback = function(v) FlyEnabled = v; if v then StartFly() else StopFly() end end})

-- Visual Tab
local VisualTab = Window:CreateTab("Visual", 2)

VisualTab:CreateSection("ESP")
VisualTab:CreateToggle({Name = "ESP Player", CurrentValue = false, Flag = "ESP", Callback = function(v) 
    ESPEnabled = v
    if v then for _, p in pairs(Players:GetPlayers()) do if not ESPObjects[p] then CreateESP(p) end end end
end})

-- Info Tab
local InfoTab = Window:CreateTab("Info", 3)

InfoTab:CreateSection("Game Structure Info")
InfoTab:CreateParagraph({Title = "Found in Console", Content = "- HitBox Parts detected\n- HumanoidRootPart\n- Head, Torso, Arms, Legs\n- Handle (Weapon parts)\n- UnionOperation"})
InfoTab:CreateParagraph({Title = "Credits", Content = "Element Arena Exploit\nBased on Delta Console Analysis"})

-- ================== INIT ==================
for _, player in pairs(Players:GetPlayers()) do CreateESP(player) end

Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(function(p) if ESPObjects[p] then for _, o in pairs(ESPObjects[p]) do o:Remove() end ESPObjects[p] = nil end end)

-- Main Loop
RunService.RenderStepped:Connect(function()
    UpdateESP()
    AutoFarmLoop()
    ApplyMovementHacks()
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    ApplyMovementHacks()
    if GodModeEnabled then SetupGodMode(true) end
    if FlyEnabled then StartFly() end
end)

print("========================================")
print("ELEMENT ARENA EXPLOIT LOADED!")
print("Based on Console Analysis:")
print("- HitBox System Found")
print("- HumanoidRootPart & Body Parts")
print("========================================")