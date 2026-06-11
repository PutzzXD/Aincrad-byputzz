-- ================== DRIP CLIENT V8.2 PREMIUM (RAYFIELD MASTER EDITION) ==================
-- FULL RAYFIELD THEME: Tampilan Key System + Menu Utama Full Menggunakan Desain Mewah Rayfield
-- Perbaikan: Tombol Get Key & Verifikasi Input Key Berfungsi 100% Menggunakan Fungsi Native Rayfield

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
        {name = "Arceus X", check = function() return game:GetService("CoreGui"):FindFirstChild("Arceus X V2") or (identifyexecutor and identifyexecutor() == "Arceus X") end},
        {name = "CodeX", check = function() return CodeX and CodeX.Execute end},
        {name = "Hydrogen", check = function() return isfile and readfile and writefile and (not syn) end},
        {name = "Fluxus", check = function() return fluxus and fluxus.ismobile end},
        {name = "Krnl", check = function() return krnl and krnl.loadlibrary end},
        {name = "ScriptWare", check = function() return scriptware and scriptware.loader end},
        {name = "Synapse X", check = function() return syn and syn.crypt and syn.request end},
        {name = "Evon", check = function() return evon and evon.execute end},
        {name = "Vega X", check = function() return game:GetService("CoreGui"):FindFirstChild("Vega Hub") end},
        {name = "Swift", check = function() return Swift and Swift.Execute end},
        {name = "Nexus", check = function() return Nexus and Nexus.Load end}
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

-- ================== GLOBAL STATE & DATABASE SYSTEM ==================
local FIREBASE_URL = "https://key-database-701af-default-rtdb.asia-southeast1.firebasedatabase.app/keys.json"
local WEBSITE_URL = "https://drip-client-get-key.vercel.app/"
local SAVE_FILE = "drip_key_data.txt"

local activeKeys = {}
local currentUserKey = nil
local keyExpiryTime = 0
local keyJenis = "BELUM VERIFIKASI"
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
    
    return true, "VALID"
end

-- ================== VARIABEL FITUR CHEAT ==================
local espEnabled = false
local lineEnabled = false
local lineColor = Color3.fromRGB(156, 39, 176)
local skeletonEnabled = false
local boxColor = Color3.fromRGB(255, 255, 255)
local skeletonColor = Color3.fromRGB(0, 255, 120)
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

-- ================== ENGINE ACTIONS (CHEATS) ==================
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

local function stopNoclip() if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end end

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
                pcall(function() if data.part and data.part.Parent then data.part.Transparency = data.origTrans end end)
            end
            for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
                if v:IsA("BasePart") and v.Transparency == 0.5 then v.Transparency = 0 end
            end
        end
        invisibleParts = {} invisibleRootPart = nil invisibleHumanoid = nil
    end
end

local function setupAntiDamage()
    if antiDamageHeartbeat then pcall(function() antiDamageHeartbeat:Disconnect() end) antiDamageHeartbeat = nil end
    local connections = {}
    local function makeInvincible()
        local char = LocalPlayer.Character if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid") if not hum then return end
        hum.Health = hum.MaxHealth hum.BreakJointsOnDeath = false
        if hum._godHealthConn then hum._godHealthConn:Disconnect() hum._godHealthConn = nil end
        local healthConn = hum.HealthChanged:Connect(function(newHealth)
            if antiDamageEnabled and newHealth < hum.MaxHealth then hum.Health = hum.MaxHealth end
        end)
        hum._godHealthConn = healthConn table.insert(connections, healthConn)
    end
    local hbConn = RunService.Heartbeat:Connect(function()
        if antiDamageEnabled and LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
        end
    end)
    table.insert(connections, hbConn) makeInvincible()
    local charConn = LocalPlayer.CharacterAdded:Connect(function() task.wait(0.2) if antiDamageEnabled then makeInvincible() end end)
    table.insert(connections, charConn)
    local godModeObject = {}
    function godModeObject:Disconnect() for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end connections = {} end
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
        if hum and jumpPowerEnabled then hum.UseJumpPower = true hum.JumpPower = jumpPowerValue end
    end
end)

-- ================== ESP SYSTEM RENDERING ==================
local function createPlayerCounter()
    if enemyCountText then pcall(function() enemyCountText:Remove() end) end
    enemyCountText = Drawing.new("Text") enemyCountText.Size = 22 enemyCountText.Color = Color3.fromRGB(255,0,0) enemyCountText.Center = true enemyCountText.Outline = true enemyCountText.Position = Vector2.new(Camera.ViewportSize.X / 2, 55) enemyCountText.Visible = false enemyCountText.Text = "PLAYERS: 0"
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
        local l = Drawing.new("Line") l.Thickness = 2 l.Color = skeletonColor l.Visible = false
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
                    box.Size = Vector2.new(width, height) box.Position = Vector2.new(pos.X - width/2, top.Y) box.Color = boxColor box.Visible = true
                    name.Position = Vector2.new(pos.X, top.Y - 15) name.Text = player.DisplayName or player.Name name.Visible = true
                    distText.Text = math.floor(distance).."m" distText.Position = Vector2.new(pos.X, bottom.Y + 3) distText.Visible = true

                    if hum then
                        local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                        hBg.Size = Vector2.new(4, height) hBg.Position = Vector2.new(pos.X + width/2 + 3, top.Y) hBg.Color = Color3.fromRGB(40,40,40) hBg.Visible = true
                        hFg.Size = Vector2.new(4, height * pct) hFg.Position = Vector2.new(pos.X + width/2 + 3, bottom.Y - (height * pct)) hFg.Color = Color3.fromRGB(255 * (1-pct), 255 * pct, 0) hFg.Visible = true
                    end
                else
                    box.Visible = false name.Visible = false distText.Visible = false hBg.Visible = false hFg.Visible = false
                end
            else
                box.Visible = false name.Visible = false distText.Visible = false hBg.Visible = false hFg.Visible = false
            end

            if lineEnabled and visible then
                line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y) line.To = Vector2.new(pos.X, pos.Y) line.Color = lineColor line.Visible = true
            else line.Visible = false end
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
                        if vis1 and vis2 then l.From = Vector2.new(pos1.X, pos1.Y) l.To = Vector2.new(pos2.X, pos2.Y) l.Visible = true else l.Visible = false end
                    else l.Visible = false end
                end
            else for _, ld in pairs(lines) do ld[1].Visible = false end end
        end
    else
        for _, lines in pairs(SkeletonESP) do for _, ld in pairs(lines) do ld[1].Visible = false end end
    end

    if playerCounterEnabled and enemyCountText then enemyCountText.Text = "PLAYERS: " .. screenCount enemyCountText.Visible = true
    elseif enemyCountText then enemyCountText.Visible = false end
end)

-- ================== TOGGLE MOBILE FLOATING BUTTON ==================
local function createMobileToggle()
    if game.CoreGui:FindFirstChild("RayfieldMobileToggle") then 
        game.CoreGui.RayfieldMobileToggle:Destroy() 
    end

    local toggleGui = Instance.new("ScreenGui", game.CoreGui)
    toggleGui.Name = "RayfieldMobileToggle"
    
    local mBtn = Instance.new("TextButton", toggleGui)
    mBtn.Size = UDim2.new(0, 50, 0, 50)
    mBtn.Position = UDim2.new(0, 15, 0.5, -25)
    mBtn.BackgroundColor3 = Color3.fromRGB(156, 39, 176) 
    mBtn.BackgroundTransparency = 0.3
    mBtn.Text = "DRIP"
    mBtn.TextColor3 = Color3.new(1, 1, 1)
    mBtn.Font = Enum.Font.GothamBold
    mBtn.TextSize = 11
    mBtn.Active = true
    mBtn.Draggable = true 
    
    Instance.new("UICorner", mBtn).CornerRadius = UDim.new(1, 0)
    local btnStroke = Instance.new("UIStroke", mBtn)
    btnStroke.Color = Color3.new(1, 1, 1)
    btnStroke.Thickness = 1.5

    mBtn.MouseButton1Click:Connect(function()
        local rayfieldGui = game.CoreGui:FindFirstChild("Rayfield")
        if rayfieldGui then
            local main = rayfieldGui:FindFirstChild("Main")
            if main then main.Visible = not main.Visible end
        end
    end)
end

-- ================== LAUNCH MAIN SCRIPT ENGINE ==================
local function loadMainScript()
    createPlayerCounter()
    createMobileToggle()
    
    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    local Window = Rayfield:CreateWindow({
        Name = "DRIP CLIENT V8.2 PREMIUM",
        LoadingTitle = "Launching Drip Engine...",
        LoadingSubtitle = "by Putzzdev",
        ConfigurationSaving = { Enabled = false },
        KeySystem = false -- Dimatikan disini karena sudah sukses divalidasi di Window pertama!
    })
    
    -- TAB 1: MAIN CHEATS
    local TabMain = Window:CreateTab("Main Cheats", 4483362458)
    
    TabMain:CreateToggle({
        Name = "Fly Mode (Terbang)",
        CurrentValue = false,
        Callback = function(Value) flyEnabled = Value if Value then startFlyMode() else stopFlyMode() end end,
    })
    
    TabMain:CreateSlider({
        Name = "Fly Speed",
        Range = {20, 300},
        Increment = 5,
        Suffix = "Speed",
        CurrentValue = 100,
        Callback = function(Value) flySpeed = Value end,
    })
    
    TabMain:CreateToggle({
        Name = "Speed Boost",
        CurrentValue = false,
        Callback = function(Value)
            speedEnabled = Value
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = Value and fastSpeed or normalSpeed end
        end,
    })

    TabMain:CreateSlider({
        Name = "WalkSpeed Value",
        Range = {16, 250},
        Increment = 2,
        Suffix = "Speed",
        CurrentValue = 60,
        Callback = function(Value)
            fastSpeed = Value
            if speedEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = Value
            end
        end,
    })
    
    TabMain:CreateToggle({
        Name = "NoClip (Tembus Objek)",
        CurrentValue = false,
        Callback = function(Value) noclipEnabled = Value if Value then startNoclip() else stopNoclip() end end,
    })
    
    TabMain:CreateToggle({
        Name = "Infinity Jump",
        CurrentValue = false,
        Callback = function(Value) infinityJumpEnabled = Value end,
    })
    
    TabMain:CreateToggle({
        Name = "God Mode (Anti Damage)",
        CurrentValue = false,
        Callback = function(Value) antiDamageEnabled = Value if Value then setupAntiDamage() else if antiDamageHeartbeat then antiDamageHeartbeat:Disconnect() end antiDamageHeartbeat = nil end end,
    })
    
    TabMain:CreateToggle({
        Name = "Spin Bot",
        CurrentValue = false,
        Callback = function(Value) toggleSpin(Value) end,
    })
    
    TabMain:CreateToggle({
        Name = "Invisible Mode",
        CurrentValue = false,
        Callback = function(Value) toggleInvisible(Value) end,
    })
    
    -- TAB 2: ESP SYSTEM
    local TabESP = Window:CreateTab("ESP System", 4483362458)
    TabESP:CreateToggle({ Name = "ESP Box", CurrentValue = false, Callback = function(v) espEnabled = v end })
    TabESP:CreateToggle({ Name = "ESP Line", CurrentValue = false, Callback = function(v) lineEnabled = v end })
    TabESP:CreateToggle({ Name = "ESP Skeleton", CurrentValue = false, Callback = function(v) skeletonEnabled = v end })
    TabESP:CreateToggle({ Name = "Player Counter", CurrentValue = false, Callback = function(v) playerCounterEnabled = v end })
    
    -- TAB 3: UTILITY
    local TabUtil = Window:CreateTab("Utility", 4483362458)
    
    local playersList = {}
    local function updatePlayerList()
        playersList = {}
        for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(playersList, p.Name) end end
    end
    updatePlayerList()
    
    local TeleportDropdown = TabUtil:CreateDropdown({
        Name = "Teleport Ke Player",
        Options = playersList,
        CurrentOption = "",
        MultipleOptions = false,
        Callback = function(Options)
            local targetName = type(Options) == "table" and Options[1] or Options
            local targetPlr = Players:FindFirstChild(targetName)
            if targetPlr and targetPlr.Character and targetPlr.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = targetPlr.Character.HumanoidRootPart.CFrame * CFrame.new(0, 3, 0)
            end
        end,
    })
    
    Players.PlayerAdded:Connect(function() task.wait(1) updatePlayerList() TeleportDropdown:Refresh(playersList, "") end)
    Players.PlayerRemoving:Connect(function() task.wait(1) updatePlayerList() TeleportDropdown:Refresh(playersList, "") end)
    
    TabUtil:CreateToggle({
        Name = "Freeze All Player (Visual Only)",
        CurrentValue = false,
        Callback = function(Value)
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    for _, part in pairs(p.Character:GetDescendants()) do if part:IsA("BasePart") then pcall(function() part.Anchored = Value end) end end
                end
            end
        end,
    })
    
    -- TAB 4: LISENSI INFO
    local TabInfo = Window:CreateTab("Info Lisensi", 4483362458)
    TabInfo:CreateLabel("Executor Anda: " .. userExecutor)
    TabInfo:CreateLabel("Jenis Paket Key: " .. keyJenis)
    local CountdownLabel = TabInfo:CreateLabel("Sisa Durasi: Menghitung...")
    
    task.spawn(function()
        while true do
            task.wait(1)
            if keyValidGlobal and keyExpiryTime > 0 then
                local _, _, _, _, timeStr = getTimeRemaining(keyExpiryTime)
                CountdownLabel:Set(os.time() > keyExpiryTime and "Status Key: EXPIRED!" or "Sisa Durasi: " .. timeStr)
            end
        end
    end)
    
    TabInfo:CreateLabel("Developer: Putzzdev")
    TabInfo:CreateLabel("WhatsApp: 088976255131")
end

-- ================== INITIALIZE WITH NATIVE RAYFIELD KEY SYSTEM ==================
-- Perbaikan: Menggunakan struktur Callback bawaan Rayfield resmi untuk validasi Firebase secara akurat

local RayfieldLoader = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local WindowWithKey = RayfieldLoader:CreateWindow({
    Name = "DRIP CLIENT VERIFIKASI",
    LoadingTitle = "Memuat Sistem Keamanan...",
    LoadingSubtitle = "by Putzzdev",
    ConfigurationSaving = { Enabled = false },
    KeySystem = true, -- AKTIFKAN SISTEM KEY RAYFIELD
    KeySettings = {
        Title = "Sistem Lisensi Premium",
        Subtitle = "Hubungkan token server database anda",
        Note = "Salin link website untuk mengambil key secara gratis melalui linkvertise.",
        FileName = "drip_key_data", 
        SaveKey = true, -- Otomatis menyimpan key yang valid agar user tidak perlu mengetik ulang
        GrabKeyFromUrl = "", 
        Actions = {
            [1] = {
                Text = "Get Key (Ambil Link)",
                Callback = function()
                    if setclipboard then
                        setclipboard(WEBSITE_URL)
                        -- Memanfaatkan notifikasi internal Rayfield yang mewah
                        RayfieldLoader:Notify({Title = "BERHASIL", Content = "Link web key telah disalin ke clipboard!", Duration = 4})
                    else
                        print("Link Key Anda: " .. WEBSITE_URL)
                    end
                end
            }
        },
        -- Fungsi inti: Membaca teks yang diketik user di kotak Rayfield dan dicocokkan ke database Firebase secara real-time
        Key = { "AksesBypassDihandleFungsiManual" },
        Callback = function(InputKey)
            if InputKey == "" or not InputKey then return false end
            
            -- Panggil fungsi cek Firebase asli buatan kamu
            local isValid, message = checkKeyExpiry(InputKey)
            if isValid then
                RayfieldLoader:Notify({Title = "AKSES DISETUJUI", Content = "Key valid! Meluncurkan menu cheat utama...", Duration = 3})
                task.wait(1)
                return true -- Mengizinkan Rayfield menutup Key GUI dan lanjut
            else
                RayfieldLoader:Notify({Title = "AKSES DITOLAK", Content = message, Duration = 4})
                return false -- Menolak penutupan GUI karena key salah/expired
            end
        end
    }
})

-- Jika Key sudah pernah disimpan sebelumnya dan masih valid secara global, langsung eksekusi script utama
if keyValidGlobal or not WindowWithKey then
    pcall(loadMainScript)
else
    -- Loop pengecekan dinamis untuk mendeteksi kapan Window Key Rayfield dihancurkan setelah sukses verifikasi
    task.spawn(function()
        local rayfieldGui = game.CoreGui:FindFirstChild("Rayfield")
        if rayfieldGui then
            local keySystemGui = rayfieldGui:FindFirstChild("KeySystem")
            if keySystemGui then
                -- Tunggu hingga Key Gui bawaan Rayfield hilang (Tanda user berhasil memasukkan key yang benar)
                while keySystemGui and keySystemGui.Parent do
                    task.wait(0.5)
                end
                -- Jalankan menu cheat utama Drip Client
                pcall(loadMainScript)
            end
        end
    end)
end

-- Sinkronisasi Player Connectors untuk ESP System
for _, p in pairs(Players:GetPlayers()) do createESP(p) createSkeleton(p) end
Players.PlayerAdded:Connect(function(p) createESP(p) createSkeleton(p) end)
Players.PlayerRemoving:Connect(function(p)
    if ESPTable[p] then for _, d in pairs(ESPTable[p]) do pcall(function() d:Remove() end) end ESPTable[p] = nil end
    if SkeletonESP[p] then for _, ld in pairs(SkeletonESP[p]) do pcall(function() ld[1]:Remove() end) end SkeletonESP[p] = nil end
end)

-- Loop pemicu respawn agar tombol toggle melayang tidak hilang dari layer CoreGui HP
LocalPlayer.CharacterAdded:Connect(function() 
    task.wait(1.5) 
    if keyValidGlobal then createMobileToggle() end
    if noclipEnabled then startNoclip() end 
    if flyEnabled then startFlyMode() end 
end)