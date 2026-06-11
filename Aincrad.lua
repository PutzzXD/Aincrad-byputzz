-- ================== DRIP CLIENT V8.2 RAYFIELD UI (FIXED) ==================
-- ================== LOAD RAYFIELD ==================
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua'))()

-- ================== LOAD SERVICES ==================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

-- ================== DETEKSI NAMA EXECUTOR ==================
local function detectExecutor()
    local executorName = "Unknown Executor"
    local executors = {
        {name = "Delta", check = function() return syn and syn.request and syn.crypt end},
        {name = "Arceus X", check = function() return game:GetService("CoreGui"):FindFirstChild("Arceus X V2") end},
        {name = "CodeX", check = function() return CodeX and CodeX.Execute end},
        {name = "Hydrogen", check = function() return isfile and readfile and writefile and (not syn) end},
        {name = "Fluxus", check = function() return fluxus and fluxus.ismobile end},
        {name = "Krnl", check = function() return krnl and krnl.loadlibrary end},
        {name = "ScriptWare", check = function() return scriptware and scriptware.loader end},
        {name = "Synapse X", check = function() return syn and syn.crypt and syn.request end},
        {name = "Evon", check = function() return evon and evon.execute end},
    }
    for _, exec in ipairs(executors) do
        local success, result = pcall(exec.check)
        if success and result then executorName = exec.name break end
    end
    local success, idName = pcall(function() if identifyexecutor then return identifyexecutor() end return nil end)
    if success and idName and idName ~= "" then executorName = idName end
    return executorName
end

local userExecutor = detectExecutor()

-- ================== GLOBAL STATE & FILE SAVING SYSTEM ==================
local FIREBASE_URL = "https://key-database-701af-default-rtdb.asia-southeast1.firebasedatabase.app/keys.json"
local WEBSITE_URL = "https://drip-client-get-key.vercel.app/"
local SAVE_FILE = "drip_key_data.txt"

local activeKeys = {}
local currentUserKey = nil
local keyExpiryTime = 0
local keyJenis = ""
local keyValidGlobal = false

local function loadKeyData()
    if isfile and isfile(SAVE_FILE) then
        local success, content = pcall(function() return readfile(SAVE_FILE) end)
        if success and content and content ~= "" then
            local success2, data = pcall(function() return HttpService:JSONDecode(content) end)
            if success2 then activeKeys = data end
        end
    end
end

local function saveKeyData()
    if writefile then
        local success, json = pcall(function() return HttpService:JSONEncode(activeKeys) end)
        if success then writefile(SAVE_FILE, json) end
    end
end

local function getKeysFromFirebase()
    local success, data = pcall(function() return game:HttpGet(FIREBASE_URL) end)
    if success and data then
        local success2, jsonData = pcall(function() return HttpService:JSONDecode(data) end)
        if success2 and jsonData then
            local keysArray = {}
            for _, keyData in pairs(jsonData) do table.insert(keysArray, keyData) end
            return keysArray
        end
    end
    return nil
end

local function getTimeRemaining(expiryTimestamp)
    local currentTime = os.time()
    local remaining = expiryTimestamp - currentTime
    if remaining <= 0 then return 0, 0, 0, 0, "EXPIRED" end
    local days = math.floor(remaining / 86400)
    local hours = math.floor((remaining % 86400) / 3600)
    local minutes = math.floor((remaining % 3600) / 60)
    local seconds = remaining % 60
    return days, hours, minutes, seconds, string.format("%d Hari %02d Jam %02d Menit %02d Detik", days, hours, minutes, seconds)
end

local function checkKeyExpiry(inputKey)
    loadKeyData()
    local keysData = getKeysFromFirebase()
    if not keysData then return false, "Gagal mengambil data server" end
    
    local foundKey, expiryDays, keyJenisData = nil, nil, nil
    for _, keyData in ipairs(keysData) do
        if keyData.key == inputKey then
            foundKey = keyData.key
            keyJenisData = keyData.jenis or "1 HARI"
            if keyData.jenis == "1 JAM" then expiryDays = 1/24
            elseif keyData.jenis == "1 HARI" then expiryDays = 1
            elseif keyData.jenis == "2 HARI" then expiryDays = 2
            elseif keyData.jenis == "3 HARI" then expiryDays = 3
            elseif keyData.jenis == "7 HARI" then expiryDays = 7
            elseif keyData.jenis == "30 HARI" then expiryDays = 30
            elseif keyData.jenis == "PERMANEN" then expiryDays = 9999999
            else expiryDays = 1 end
            break
        end
    end
    
    if not foundKey then return false, "KEY TIDAK TERDAFTAR!" end
    local currentTime = os.time()
    local expiryTime = nil
    
    if activeKeys[inputKey] and activeKeys[inputKey].expiryTime then
        expiryTime = activeKeys[inputKey].expiryTime
        if currentTime > expiryTime then return false, "KEY SUDAH EXPIRED!" end
    else
        expiryTime = currentTime + (expiryDays * 86400)
        activeKeys[inputKey] = {
            firstUsed = currentTime, key = inputKey, expiryDays = expiryDays,
            expiryTime = expiryTime, jenis = keyJenisData
        }
        saveKeyData()
    end
    
    keyExpiryTime = expiryTime
    keyJenis = keyJenisData
    currentUserKey = inputKey
    keyValidGlobal = true
    
    local _, _, _, _, timeStr = getTimeRemaining(expiryTime)
    return true, "VALID! Sisa: " .. timeStr
end

-- ================== VARIABEL FITUR CHEAT ==================
local espEnabled = false
local lineEnabled = false
local lineColor = Color3.fromRGB(0, 0, 0)
local skeletonEnabled = false
local ESPTable = {}
local SkeletonESP = {}

local playerCounterEnabled = false
local enemyCountText = nil

local flyEnabled = false
local flyConnection = nil
local flySpeed = 100
local flyAutoForward = true
local ctrl = {f = 0, b = 0, l = 0, r = 0}
local speed = 0
local flyTorso = nil

local noclipEnabled = false
local noclipConnection = nil

local speedEnabled = false
local normalSpeed = 16
local fastSpeed = 60

local jumpPowerEnabled = false
local jumpPowerValue = 50 
local infinityJumpEnabled = false

local antiDamageEnabled = false
local antiDamageHeartbeat = nil

local spinEnabled = false
local spinSpeed = 50
local spinConnection = nil
local spinDirection = 1

local invisibleEnabled = false
local invisibleConnection = nil
local invisibleParts = {}
local invisibleRootPart = nil
local invisibleHumanoid = nil

local MAX_ESP_DISTANCE = 200000

-- ================== ENGINE ACTIONS ==================
local function startFlyMode()
    local plr = LocalPlayer
    if not plr.Character then return end
    flyTorso = plr.Character:FindFirstChild("UpperTorso") or plr.Character:FindFirstChild("Torso") or plr.Character:FindFirstChild("HumanoidRootPart")
    if not flyTorso then return end
    ctrl = {f = 0, b = 0, l = 0, r = 0}
    speed = 0
    if plr.Character:FindFirstChildOfClass("Humanoid") then plr.Character:FindFirstChildOfClass("Humanoid").PlatformStand = true end
    
    local flyBodyGyro = Instance.new("BodyGyro", flyTorso)
    flyBodyGyro.Name = "FlyBG"
    flyBodyGyro.P = 9e4
    flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)

    local flyBodyVelocity = Instance.new("BodyVelocity", flyTorso)
    flyBodyVelocity.Name = "FlyBV"
    flyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)

    flyConnection = RunService.RenderStepped:Connect(function()
        if not flyEnabled or not plr.Character or not flyTorso:IsDescendantOf(workspace) then return end
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then ctrl.f = 1 else ctrl.f = 0 end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then ctrl.b = -1 else ctrl.b = 0 end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then ctrl.l = -1 else ctrl.l = 0 end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then ctrl.r = 1 else ctrl.r = 0 end
        
        local forwardInput = (flyAutoForward and ctrl.f == 0 and ctrl.b == 0) and 1 or (ctrl.f + ctrl.b)
        if forwardInput ~= 0 or ctrl.l + ctrl.r ~= 0 then
            speed = math.min(speed + 1.5, flySpeed)
            local camCF = Camera.CFrame
            flyBodyVelocity.Velocity = ((camCF.LookVector * forwardInput) + (camCF.RightVector * (ctrl.l + ctrl.r))).Unit * speed
        else
            speed = math.max(speed - 2, 0)
            flyBodyVelocity.Velocity = Vector3.new(0,0,0)
        end
        flyBodyGyro.CFrame = Camera.CFrame
    end)
end

local function stopFlyMode()
    flyEnabled = false
    if flyConnection then flyConnection:Disconnect() flyConnection = nil end
    local char = LocalPlayer.Character
    if char then
        if char:FindFirstChildOfClass("Humanoid") then char:FindFirstChildOfClass("Humanoid").PlatformStand = false end
        local t = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
        if t then
            if t:FindFirstChild("FlyBV") then t.FlyBV:Destroy() end
            if t:FindFirstChild("FlyBG") then t.FlyBG:Destroy() end
        end
    end
end

local function startNoclip()
    if noclipConnection then noclipConnection:Disconnect() end
    noclipConnection = RunService.Stepped:Connect(function()
        if noclipEnabled and LocalPlayer.Character then
            for _, p in pairs(LocalPlayer.Character:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end)
end

local function stopNoclip() 
    if noclipConnection then 
        noclipConnection:Disconnect() 
        noclipConnection = nil 
    end 
end

local function toggleSpin(state)
    spinEnabled = state
    if spinConnection then spinConnection:Disconnect() spinConnection = nil end
    if state then
        spinConnection = RunService.Heartbeat:Connect(function()
            if spinEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame *= CFrame.Angles(0, math.rad(spinSpeed * spinDirection), 0)
            end
        end)
    end
end

local function toggleInvisible(state)
    invisibleEnabled = state
    if invisibleConnection then invisibleConnection:Disconnect() invisibleConnection = nil end
    if state and LocalPlayer.Character then
        invisibleParts = {}
        invisibleRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        invisibleHumanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") and v.Transparency == 0 then
                table.insert(invisibleParts, {part = v, origTrans = v.Transparency})
                v.Transparency = 0.5
            end
        end
        invisibleConnection = RunService.Heartbeat:Connect(function()
            if invisibleEnabled and invisibleRootPart and invisibleHumanoid then
                local oldCF = invisibleRootPart.CFrame
                local oldOffset = invisibleHumanoid.CameraOffset
                local hideCF = oldCF * CFrame.new(0, -500000, 0)
                invisibleRootPart.CFrame = hideCF
                invisibleHumanoid.CameraOffset = hideCF:ToObjectSpace(CFrame.new(oldCF.Position)).Position
                RunService.RenderStepped:Wait()
                invisibleRootPart.CFrame = oldCF
                invisibleHumanoid.CameraOffset = oldOffset
            end
        end)
    else
        if LocalPlayer.Character then
            for _, data in pairs(invisibleParts) do
                pcall(function()
                    if data.part and data.part.Parent then
                        data.part.Transparency = data.origTrans
                    end
                end)
            end
            for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
                if v:IsA("BasePart") and v.Transparency == 0.5 then
                    v.Transparency = 0
                end
            end
        end
        invisibleParts = {}
        invisibleRootPart = nil
        invisibleHumanoid = nil
    end
end

-- ================== GOD MODE ==================
local function setupAntiDamage()
    if antiDamageHeartbeat then
        if type(antiDamageHeartbeat) == "table" and antiDamageHeartbeat._disconnect then
            antiDamageHeartbeat:_disconnect()
        elseif antiDamageHeartbeat.Disconnect then
            antiDamageHeartbeat:Disconnect()
        end
        antiDamageHeartbeat = nil
    end
    
    local connections = {}
    
    local function makeInvincible()
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        
        hum.Health = hum.MaxHealth
        hum.BreakJointsOnDeath = false
        
        if hum._godHealthConn then
            hum._godHealthConn:Disconnect()
            hum._godHealthConn = nil
        end
        
        local healthConn = hum.HealthChanged:Connect(function(newHealth)
            if antiDamageEnabled and newHealth < hum.MaxHealth then
                hum.Health = hum.MaxHealth
            end
        end)
        hum._godHealthConn = healthConn
        table.insert(connections, healthConn)
    end
    
    local hbConn = RunService.Heartbeat:Connect(function()
        if antiDamageEnabled and LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health < hum.MaxHealth then
                hum.Health = hum.MaxHealth
            end
        end
    end)
    table.insert(connections, hbConn)
    
    makeInvincible()
    
    local charConn = LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.2)
        if antiDamageEnabled then
            makeInvincible()
        end
    end)
    table.insert(connections, charConn)
    
    local godModeObject = {}
    function godModeObject:Disconnect()
        for _, conn in ipairs(connections) do
            pcall(function() conn:Disconnect() end)
        end
        connections = {}
        if LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum._godHealthConn then
                hum._godHealthConn:Disconnect()
                hum._godHealthConn = nil
            end
        end
    end
    function godModeObject:_disconnect() self:Disconnect() end
    
    antiDamageHeartbeat = godModeObject
end

UserInputService.JumpRequest:Connect(function()
    if infinityJumpEnabled and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

RunService.Heartbeat:Connect(function()
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum and jumpPowerEnabled then
            hum.UseJumpPower = true
            hum.JumpPower = jumpPowerValue
        end
    end
end)

-- ================== ESP SYSTEM DRAWINGS ==================
local function createPlayerCounter()
    if enemyCountText then pcall(function() enemyCountText:Remove() end) end
    enemyCountText = Drawing.new("Text")
    enemyCountText.Size = 22
    enemyCountText.Color = Color3.fromRGB(255, 0, 0)
    enemyCountText.Center = true
    enemyCountText.Outline = true
    enemyCountText.Position = Vector2.new(Camera.ViewportSize.X / 2, 55)
    enemyCountText.Visible = false
    enemyCountText.Text = "PLAYERS: 0"
end

local function createESP(player)
    if player == LocalPlayer then return end
    local box = Drawing.new("Square") box.Thickness = 1.8 box.Filled = false box.Visible = false
    local name = Drawing.new("Text") name.Size = 13 name.Center = true name.Outline = true name.Visible = false
    local dist = Drawing.new("Text") dist.Size = 11 dist.Center = true dist.Outline = true dist.Visible = false
    local line = Drawing.new("Line") line.Thickness = 1.8 line.Visible = false
    local healthBg = Drawing.new("Square") healthBg.Filled = true healthBg.Visible = false
    local healthFg = Drawing.new("Square") healthFg.Filled = true healthFg.Visible = false
    ESPTable[player] = {box, name, dist, line, healthBg, healthFg}
end

local function createSkeleton(player)
    if player == LocalPlayer then return end
    local lines = {}
    local joints = {
        {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
        {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"},
        {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"},
        {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"},
        {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}
    }
    for i=1, #joints do
        local l = Drawing.new("Line") l.Thickness = 2 l.Color = Color3.fromRGB(0, 255, 0) l.Visible = false
        table.insert(lines, {l, joints[i][1], joints[i][2]})
    end
    SkeletonESP[player] = lines
end

RunService.RenderStepped:Connect(function()
    local myChar = LocalPlayer.Character
    local myPos = myChar and myChar:FindFirstChild("HumanoidRootPart") and myChar.HumanoidRootPart.Position
    local screenCount = 0

    for player, esp in pairs(ESPTable) do
        local box, name, distText, line, hBg, hFg = unpack(esp)
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Head") then
            local hrp = char.HumanoidRootPart
            local head = char.Head
            local hum = char:FindFirstChildOfClass("Humanoid")
            local pos, visible = Camera:WorldToViewportPoint(hrp.Position)
            local distance = myPos and (myPos - hrp.Position).Magnitude or 9999
            
            if visible and distance <= MAX_ESP_DISTANCE then
                screenCount = screenCount + 1
                local top = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local bottom = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                local height = math.abs(top.Y - bottom.Y)
                local width = height / 2

                if espEnabled then
                    box.Size = Vector2.new(width, height)
                    box.Position = Vector2.new(pos.X - width/2, top.Y)
                    box.Color = Color3.fromRGB(0, 0, 0)
                    box.Visible = true

                    name.Position = Vector2.new(pos.X, top.Y - 15)
                    name.Text = player.DisplayName or player.Name
                    name.Visible = true

                    distText.Text = math.floor(distance).."m"
                    distText.Position = Vector2.new(pos.X, bottom.Y + 3)
                    distText.Visible = true

                    if hum then
                        local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                        hBg.Size = Vector2.new(4, height)
                        hBg.Position = Vector2.new(pos.X + width/2 + 3, top.Y)
                        hBg.Color = Color3.fromRGB(40,40,40)
                        hBg.Visible = true

                        hFg.Size = Vector2.new(4, height * pct)
                        hFg.Position = Vector2.new(pos.X + width/2 + 3, bottom.Y - (height * pct))
                        hFg.Color = Color3.fromRGB(255 * (1-pct), 255 * pct, 0)
                        hFg.Visible = true
                    end
                else
                    box.Visible = false name.Visible = false distText.Visible = false hBg.Visible = false hFg.Visible = false
                end
            else
                box.Visible = false name.Visible = false distText.Visible = false hBg.Visible = false hFg.Visible = false
            end

            if lineEnabled and visible then
                line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                line.To = Vector2.new(pos.X, pos.Y)
                line.Color = Color3.fromRGB(0, 0, 0)
                line.Visible = true
            else
                line.Visible = false
            end
        end
    end

    if skeletonEnabled then
        for player, lines in pairs(SkeletonESP) do
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") and myPos then
                for _, lData in pairs(lines) do
                    local l, p1, p2 = lData[1], char:FindFirstChild(lData[2]), char:FindFirstChild(lData[3])
                    if p1 and p2 then
                        local pos1, vis1 = Camera:WorldToViewportPoint(p1.Position)
                        local pos2, vis2 = Camera:WorldToViewportPoint(p2.Position)
                        if vis1 and vis2 then
                            l.From = Vector2.new(pos1.X, pos1.Y)
                            l.To = Vector2.new(pos2.X, pos2.Y)
                            l.Visible = true
                        else l.Visible = false end
                    else l.Visible = false end
                end
            else
                for _, ld in pairs(lines) do ld[1].Visible = false end
            end
        end
    else
        for _, lines in pairs(SkeletonESP) do for _, ld in pairs(lines) do ld[1].Visible = false end end
    end

    if playerCounterEnabled and enemyCountText then
        enemyCountText.Text = "PLAYERS: " .. screenCount
        enemyCountText.Visible = true
    elseif enemyCountText then
        enemyCountText.Visible = false
    end
end)

-- ================== FREEZE FUNCTION ==================
local freezeAllEnabled = false
local freezeSelfEnabled = false

local function freezeAllPlayers(state)
    freezeAllEnabled = state
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            for _, part in pairs(p.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    pcall(function() part.Anchored = state end)
                end
            end
        end
    end
end

local function applyFreezeSelf(state)
    freezeSelfEnabled = state
    local myChar = LocalPlayer.Character
    if myChar then
        local hrp = myChar:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Anchored = state
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if freezeSelfEnabled then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.Anchored = true end
    end
end)

-- ================== TELEPORT FUNCTION ==================
local function teleportToPlayer(targetPlayer)
    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 3, 0)
        if Rayfield and Rayfield.Notify then
            Rayfield:Notify({
                Title = "Teleport",
                Content = "Teleported to " .. targetPlayer.Name,
                Duration = 2,
            })
        end
    end
end

-- ================== MAIN CHEAT INTERFACE DENGAN RAYFIELD ==================
local mainWindowLoaded = false

local function loadMainScript()
    if mainWindowLoaded then return end
    mainWindowLoaded = true
    
    -- Hapus key system GUI jika ada
    pcall(function()
        if game.CoreGui:FindFirstChild("DripKeySystem") then
            game.CoreGui.DripKeySystem:Destroy()
        end
    end)
    
    pcall(createPlayerCounter)
    
    -- Buat window utama
    local Window = Rayfield:CreateWindow({
        Name = "DRIP CLIENT PREMIUM",
        Icon = 0,
        LoadingTitle = "DRIP CLIENT",
        LoadingSubtitle = "by Putzzdev",
        Theme = "Default",
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "DripClient",
            FileName = "DripConfig"
        },
        KeySystem = false,
    })
    
    -- TAB MAIN
    local MainTab = Window:CreateTab("Main", 0)
    
    MainTab:CreateSection("Movement")
    
    MainTab:CreateToggle({
        Name = "Fly Mode",
        CurrentValue = false,
        Flag = "FlyMode",
        Callback = function(Value)
            flyEnabled = Value
            if Value then startFlyMode() else stopFlyMode() end
        end,
    })
    
    MainTab:CreateToggle({
        Name = "Speed Boost",
        CurrentValue = false,
        Flag = "SpeedBoost",
        Callback = function(Value)
            speedEnabled = Value
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = Value and fastSpeed or normalSpeed end
        end,
    })
    
    MainTab:CreateSlider({
        Name = "Speed Value",
        Range = {16, 120},
        Increment = 1,
        Suffix = "WalkSpeed",
        CurrentValue = fastSpeed,
        Flag = "SpeedValue",
        Callback = function(Value)
            fastSpeed = Value
            if speedEnabled then
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = Value end
            end
        end,
    })
    
    MainTab:CreateToggle({
        Name = "NoClip",
        CurrentValue = false,
        Flag = "NoClip",
        Callback = function(Value)
            noclipEnabled = Value
            if Value then startNoclip() else stopNoclip() end
        end,
    })
    
    MainTab:CreateToggle({
        Name = "Infinity Jump",
        CurrentValue = false,
        Flag = "InfinityJump",
        Callback = function(Value)
            infinityJumpEnabled = Value
        end,
    })
    
    MainTab:CreateToggle({
        Name = "Jump Power",
        CurrentValue = false,
        Flag = "JumpPower",
        Callback = function(Value)
            jumpPowerEnabled = Value
        end,
    })
    
    MainTab:CreateSlider({
        Name = "Jump Power Value",
        Range = {0, 200},
        Increment = 5,
        Suffix = "Power",
        CurrentValue = jumpPowerValue,
        Flag = "JumpPowerValue",
        Callback = function(Value)
            jumpPowerValue = Value
        end,
    })
    
    MainTab:CreateSection("Combat")
    
    MainTab:CreateToggle({
        Name = "God Mode",
        CurrentValue = false,
        Flag = "GodMode",
        Callback = function(Value)
            antiDamageEnabled = Value
            if Value then
                setupAntiDamage()
            else
                if antiDamageHeartbeat then antiDamageHeartbeat:Disconnect() end
                antiDamageHeartbeat = nil
            end
        end,
    })
    
    MainTab:CreateToggle({
        Name = "Spin Muter",
        CurrentValue = false,
        Flag = "SpinMode",
        Callback = function(Value)
            toggleSpin(Value)
        end,
    })
    
    MainTab:CreateSlider({
        Name = "Spin Speed",
        Range = {10, 200},
        Increment = 5,
        Suffix = "deg/s",
        CurrentValue = spinSpeed,
        Flag = "SpinSpeed",
        Callback = function(Value)
            spinSpeed = Value
        end,
    })
    
    MainTab:CreateToggle({
        Name = "Invisible Mode",
        CurrentValue = false,
        Flag = "InvisibleMode",
        Callback = function(Value)
            toggleInvisible(Value)
        end,
    })
    
    -- TAB ESP
    local ESPTab = Window:CreateTab("ESP", 1)
    
    ESPTab:CreateSection("Visuals")
    
    ESPTab:CreateToggle({
        Name = "ESP Box (Hitam)",
        CurrentValue = false,
        Flag = "ESPBox",
        Callback = function(Value)
            espEnabled = Value
        end,
    })
    
    ESPTab:CreateToggle({
        Name = "ESP Line",
        CurrentValue = false,
        Flag = "ESPLine",
        Callback = function(Value)
            lineEnabled = Value
        end,
    })
    
    ESPTab:CreateToggle({
        Name = "ESP Skeleton",
        CurrentValue = false,
        Flag = "ESPSkeleton",
        Callback = function(Value)
            skeletonEnabled = Value
        end,
    })
    
    ESPTab:CreateToggle({
        Name = "Player Counter",
        CurrentValue = false,
        Flag = "PlayerCounter",
        Callback = function(Value)
            playerCounterEnabled = Value
        end,
    })
    
    -- TAB UTILITY
    local UtilityTab = Window:CreateTab("Utility", 2)
    
    UtilityTab:CreateSection("Teleport")
    
    -- Dropdown untuk teleport ke player
    local teleportDropdown = UtilityTab:CreateDropdown({
        Name = "Teleport ke Player",
        Options = {},
        CurrentOption = "",
        Flag = "TeleportPlayer",
        Callback = function(Option)
            for _, plr in pairs(Players:GetPlayers()) do
                if (plr.DisplayName or plr.Name) == Option then
                    teleportToPlayer(plr)
                    break
                end
            end
        end,
    })
    
    -- Update dropdown options setiap kali player list berubah
    local function updateTeleportDropdown()
        local options = {}
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                table.insert(options, plr.DisplayName or plr.Name)
            end
        end
        pcall(function() teleportDropdown:SetOptions(options) end)
    end
    
    updateTeleportDropdown()
    Players.PlayerAdded:Connect(updateTeleportDropdown)
    Players.PlayerRemoving:Connect(updateTeleportDropdown)
    
    UtilityTab:CreateSection("Freeze")
    
    UtilityTab:CreateToggle({
        Name = "Freeze All Player (Visual)",
        CurrentValue = false,
        Flag = "FreezeAll",
        Callback = function(Value)
            freezeAllPlayers(Value)
            if Rayfield and Rayfield.Notify then
                Rayfield:Notify({
                    Title = "Freeze",
                    Content = Value and "Semua player dibekukan!" or "Freeze dinonaktifkan",
                    Duration = 2,
                })
            end
        end,
    })
    
    UtilityTab:CreateToggle({
        Name = "Freeze Diri Sendiri",
        CurrentValue = false,
        Flag = "FreezeSelf",
        Callback = function(Value)
            applyFreezeSelf(Value)
        end,
    })
    
    -- TAB INFO
    local InfoTab = Window:CreateTab("Info", 3)
    
    InfoTab:CreateSection("Lisensi")
    
    InfoTab:CreateParagraph({
        Title = "Executor",
        Content = userExecutor,
    })
    
    InfoTab:CreateParagraph({
        Title = "Jenis Paket",
        Content = keyJenis,
    })
    
    -- Label untuk countdown key
    local keyCountdownLabel = InfoTab:CreateParagraph({
        Title = "Sisa Durasi",
        Content = "Memuat...",
    })
    
    InfoTab:CreateParagraph({
        Title = "Developer",
        Content = "Putzzdev\nWhatsApp: 088976255131",
    })
    
    -- Update countdown setiap detik
    task.spawn(function()
        while mainWindowLoaded do
            task.wait(1)
            if keyValidGlobal and keyExpiryTime > 0 then
                local _, _, _, _, timeStr = getTimeRemaining(keyExpiryTime)
                if os.time() > keyExpiryTime then
                    pcall(function() keyCountdownLabel:Set("Sisa Durasi", "EXPIRED! (Harap ganti key)") end)
                else
                    pcall(function() keyCountdownLabel:Set("Sisa Durasi", timeStr) end)
                end
            end
        end
    end)
    
    -- Update ESP untuk player baru/keluar
    for _, p in pairs(Players:GetPlayers()) do 
        pcall(function() createESP(p) end)
        pcall(function() createSkeleton(p) end)
    end
    
    Players.PlayerAdded:Connect(function(p) 
        pcall(function() createESP(p) end)
        pcall(function() createSkeleton(p) end)
    end)
    
    Players.PlayerRemoving:Connect(function(p)
        if ESPTable[p] then 
            for _, d in pairs(ESPTable[p]) do 
                pcall(function() d:Remove() end) 
            end 
            ESPTable[p] = nil 
        end
        if SkeletonESP[p] then 
            for _, ld in pairs(SkeletonESP[p]) do 
                pcall(function() ld[1]:Remove() end) 
            end 
            SkeletonESP[p] = nil 
        end
        pcall(updateTeleportDropdown)
    end)
end

-- ================== KEY SYSTEM UI DENGAN RAYFIELD ==================
local keyWindowCreated = false

local function showKeySystem()
    if keyWindowCreated then return end
    keyWindowCreated = true
    
    local KeyWindow = Rayfield:CreateWindow({
        Name = "DRIP CLIENT - VERIFIKASI KEY",
        Icon = 0,
        LoadingTitle = "DRIP CLIENT",
        LoadingSubtitle = "Verifikasi Lisensi",
        Theme = "Default",
        ConfigurationSaving = {
            Enabled = false,
        },
        KeySystem = false,
    })
    
    local KeyTab = KeyWindow:CreateTab("Verifikasi", 0)
    
    KeyTab:CreateParagraph({
        Title = "Selamat Datang di DRIP CLIENT",
        Content = "Silakan masukkan key premium Anda untuk mengakses fitur lengkap.",
    })
    
    local keyInput = KeyTab:CreateInput({
        Name = "Key Premium",
        PlaceholderText = "Masukkan key di sini...",
        RemoveTextAfterFocusLost = false,
        Flag = "PremiumKey",
        Callback = function(Text)
        end,
    })
    
    local statusParagraph = KeyTab:CreateParagraph({
        Title = "Status",
        Content = "Menunggu verifikasi...",
    })
    
    KeyTab:CreateButton({
        Name = "Ambil Key",
        Callback = function()
            if setclipboard then
                setclipboard(WEBSITE_URL)
                pcall(function() statusParagraph:Set("Status", "Link berhasil disalin ke clipboard!") end)
                if Rayfield and Rayfield.Notify then
                    Rayfield:Notify({
                        Title = "Berhasil",
                        Content = "Link web key disalin!",
                        Duration = 2,
                    })
                end
            else
                pcall(function() statusParagraph:Set("Status", WEBSITE_URL) end)
            end
        end,
    })
    
    KeyTab:CreateButton({
        Name = "Verifikasi Key",
        Callback = function()
            local inputKey = keyInput:GetValue():gsub("%s+", "")
            if inputKey == "" then 
                pcall(function() statusParagraph:Set("Status", "Key tidak boleh kosong!") end)
                return 
            end
            
            pcall(function() statusParagraph:Set("Status", "Sedang verifikasi ke database server...") end)
            
            local isValid, message = checkKeyExpiry(inputKey)
            
            if isValid then
                pcall(function() statusParagraph:Set("Status", "✓ Key Valid! Loading menu...") end)
                if Rayfield and Rayfield.Notify then
                    Rayfield:Notify({
                        Title = "Sukses",
                        Content = "Key berhasil diverifikasi!",
                        Duration = 2,
                    })
                end
                task.wait(1)
                pcall(function() KeyWindow:Destroy() end)
                pcall(loadMainScript)
            else
                pcall(function() statusParagraph:Set("Status", "✗ " .. message) end)
                if Rayfield and Rayfield.Notify then
                    Rayfield:Notify({
                        Title = "Gagal",
                        Content = message,
                        Duration = 3,
                    })
                end
            end
        end,
    })
end

-- Start the key system with error handling
local success, err = pcall(showKeySystem)
if not success then
    warn("Error loading key system: " .. tostring(err))
    -- Fallback: langsung load main script tanpa key system
    pcall(loadMainScript)
end