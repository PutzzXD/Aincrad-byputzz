-- ================== DRIP CLIENT V8.2 PREMIUM - RAYFIELD UI ==================

-- ================== LOAD SERVICES ==================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")

-- Pindahkan atau deklarasikan Rayfield secara global agar bisa diakses oleh semua fungsi
local Rayfield = nil 

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

-- ================== GLOBAL STATE & FILE SAVING SYSTEM ==================
local FIREBASE_URL = "https://key-database-701af-default-rtdb.asia-southeast1.firebasedatabase.app/keys.json"
local WEBSITE_URL = "https://drip-client-get-key.vercel.app/"
local SAVE_FILE = "drip_key_data.txt"

local activeKeys = {}
local currentUserKey = nil
local keyExpiryTime = 0
local keyJenis = ""
local keyValidGlobal = false
local infoKeyCountdownLabel = nil
local mainWindowLoaded = false

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

-- ================== VARIABEL FITUR ==================
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

local skeletonColor = Color3.fromRGB(0, 255, 0)
local boxColor = Color3.fromRGB(0, 0, 0)
local MAX_ESP_DISTANCE = 200000

-- ================== FITUR BARU ==================
-- Full Bright
local fullBrightEnabled = false
local originalBrightness = Lighting.Brightness
local originalClockTime = Lighting.ClockTime
local originalAmbient = Lighting.Ambient
local originalColorShift_Bottom = Lighting.ColorShift_Bottom
local originalColorShift_Top = Lighting.ColorShift_Top
local originalOutdoorAmbient = Lighting.OutdoorAmbient

-- No Fog
local noFogEnabled = false
local originalFogEnd = Lighting.FogEnd
local originalFogStart = Lighting.FogStart
local originalFogColor = Lighting.FogColor

-- Server Hop
local serverHopConnections = {}

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
    if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
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
                if v:IsA("BasePart") and v.Transparency == 0.5 then v.Transparency = 0 end
            end
        end
        invisibleParts = {}
        invisibleRootPart = nil
        invisibleHumanoid = nil
    end
end

-- ================== FULL BRIGHT ==================
local function toggleFullBright(state)
    fullBrightEnabled = state
    if state then
        -- Simpan nilai asli
        originalBrightness = Lighting.Brightness
        originalClockTime = Lighting.ClockTime
        originalAmbient = Lighting.Ambient
        originalColorShift_Bottom = Lighting.ColorShift_Bottom
        originalColorShift_Top = Lighting.ColorShift_Top
        originalOutdoorAmbient = Lighting.OutdoorAmbient
        
        -- Set ke full bright
        Lighting.Brightness = 10
        Lighting.ClockTime = 14
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.ColorShift_Bottom = Color3.fromRGB(255, 255, 255)
        Lighting.ColorShift_Top = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
    else
        -- Kembalikan nilai asli
        Lighting.Brightness = originalBrightness
        Lighting.ClockTime = originalClockTime
        Lighting.Ambient = originalAmbient
        Lighting.ColorShift_Bottom = originalColorShift_Bottom
        Lighting.ColorShift_Top = originalColorShift_Top
        Lighting.OutdoorAmbient = originalOutdoorAmbient
        Lighting.GlobalShadows = true
        Lighting.FogEnd = originalFogEnd or 1000
    end
end

-- ================== NO FOG ==================
local function toggleNoFog(state)
    noFogEnabled = state
    if state then
        originalFogEnd = Lighting.FogEnd
        originalFogStart = Lighting.FogStart
        originalFogColor = Lighting.FogColor
        
        Lighting.FogEnd = 100000
        Lighting.FogStart = 100000
        Lighting.FogColor = Color3.fromRGB(0, 0, 0)
    else
        Lighting.FogEnd = originalFogEnd or 1000
        Lighting.FogStart = originalFogStart or 0
        Lighting.FogColor = originalFogColor or Color3.fromRGB(127, 127, 127)
    end
end

-- ================== REJOIN SERVER ==================
local function rejoinServer()
    if Rayfield then
        Rayfield:Notify({
            Title = "Rejoin",
            Content = "Sedang merejoin server...",
            Duration = 3,
            Image = 4483362458
        })
    end
    task.wait(1)
    if #Players:GetPlayers() <= 1 then
        LocalPlayer:Kick("\nRejoining...")
        task.wait(0.5)
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    else
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
end

-- ================== SERVER HOP ==================
local function serverHop()
    if Rayfield then
        Rayfield:Notify({
            Title = "Server Hop",
            Content = "Mencari server baru...",
            Duration = 3,
            Image = 4483362458
        })
    end
    task.wait(1)
    
    local success, err = pcall(function()
        local serverList = {}
        local req = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
        local decoded = HttpService:JSONDecode(req)
        
        if decoded and decoded.data then
            for _, server in ipairs(decoded.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    table.insert(serverList, server.id)
                end
            end
        end
        
        if #serverList > 0 then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, serverList[math.random(1, #serverList)], LocalPlayer)
        else
            error("Tidak menemukan server alternatif.")
        end
    end)
    
    if not success then
        if Rayfield then
            Rayfield:Notify({
                Title = "Server Hop",
                Content = "Mencoba metode alternatif...",
                Duration = 3,
                Image = 4483362458
            })
        end
        task.wait(1)
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
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
        if hum._godHealthConn then hum._godHealthConn:Disconnect() hum._godHealthConn = nil end
        local healthConn = hum.HealthChanged:Connect(function(newHealth)
            if antiDamageEnabled and newHealth < hum.MaxHealth then hum.Health = hum.MaxHealth end
        end)
        hum._godHealthConn = healthConn
        table.insert(connections, healthConn)
    end

    local hbConn = RunService.Heartbeat:Connect(function()
        if antiDamageEnabled and LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
        end
    end)
    table.insert(connections, hbConn)
    makeInvincible()

    local charConn = LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.2)
        if antiDamageEnabled then makeInvincible() end
    end)
    table.insert(connections, charConn)

    local godModeObject = {}
    function godModeObject:Disconnect()
        for _, conn in ipairs(connections) do pcall(function() conn:Disconnect() end) end
        connections = {}
        if LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum._godHealthConn then hum._godHealthConn:Disconnect() hum._godHealthConn = nil end
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

-- ================== ESP SYSTEM ==================
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
    local name = Drawing.new("Text") name.Size = 13 name.Center = true name.Outline = true name.Visible = false name.Color = Color3.fromRGB(255,255,255)
    local dist = Drawing.new("Text") dist.Size = 11 dist.Center = true dist.Outline = true dist.Visible = false dist.Color = Color3.fromRGB(255,255,255)
    local line = Drawing.new("Line") line.Thickness = 1.8 line.Visible = false
    local healthBg = Drawing.new("Square") healthBg.Filled = true healthBg.Visible = false
    local healthFg = Drawing.new("Square") healthFg.Filled = true healthFg.Visible = false
    ESPTable[player] = {box, name, dist, line, healthBg, healthFg}
end

local function createSkeleton(player)
    if player == LocalPlayer then return end
    local lines = {}
    local joints = {
        {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
        {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},
        {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},
        {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},
        {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"}
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
                    box.Size = Vector2.new(width, height)
                    box.Position = Vector2.new(pos.X - width/2, top.Y)
                    box.Color = boxColor
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
                        hFg.Color = Color3.fromRGB(255*(1-pct), 255*pct, 0)
                        hFg.Visible = true
                    end
                else
                    box.Visible = false name.Visible = false distText.Visible = false hBg.Visible = false hFg.Visible = false
                end
            else
                box.Visible = false name.Visible = false distText.Visible = false hBg.Visible = false hFg.Visible = false
            end

            if lineEnabled and visible then
                line.From = Vector2.new(Camera.ViewportSize.X / 2, 0)
                line.To = Vector2.new(pos.X, pos.Y)
                line.Color = lineColor
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

-- ================== MAIN RAYFIELD UI ==================
local function loadMainScript()
    if mainWindowLoaded then return end
    mainWindowLoaded = true
    
    createPlayerCounter()

    Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

    local Window = Rayfield:CreateWindow({
        Name = "Drip Client Premium",
        LoadingTitle = "Drip Client",
        LoadingSubtitle = "Premium v8.2",
        Theme = "Amethyst",
        DisableRayfieldPrompts = true,
        DisableBuildWarnings = true,
        ConfigurationSaving = {
            Enabled = false,
        },
        KeySystem = false,
    })

    -- ================== TAB MAIN ==================
    local TabMain = Window:CreateTab("Main", "zap")

    TabMain:CreateToggle({
        Name = "Fly Mode",
        CurrentValue = false,
        Flag = "FlyMode",
        Callback = function(state)
            flyEnabled = state
            if state then startFlyMode() else stopFlyMode() end
        end,
    })

    TabMain:CreateSlider({
        Name = "Fly Speed",
        Range = {10, 500},
        Increment = 10,
        Suffix = "",
        CurrentValue = flySpeed,
        Flag = "FlySpeed",
        Callback = function(val)
            flySpeed = val
        end,
    })

    TabMain:CreateToggle({
        Name = "Auto Forward (Fly)",
        CurrentValue = true,
        Flag = "FlyAutoFwd",
        Callback = function(state)
            flyAutoForward = state
        end,
    })

    TabMain:CreateDivider()

    TabMain:CreateToggle({
        Name = "Speed Boost",
        CurrentValue = false,
        Flag = "SpeedBoost",
        Callback = function(state)
            speedEnabled = state
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = state and fastSpeed or normalSpeed end
        end,
    })

    TabMain:CreateSlider({
        Name = "Walk Speed",
        Range = {16, 500},
        Increment = 1,
        Suffix = "",
        CurrentValue = fastSpeed,
        Flag = "WalkSpeed",
        Callback = function(val)
            fastSpeed = val
            if speedEnabled then
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = val end
            end
        end,
    })

    TabMain:CreateDivider()

    TabMain:CreateToggle({
        Name = "NoClip",
        CurrentValue = false,
        Flag = "NoClip",
        Callback = function(state)
            noclipEnabled = state
            if state then startNoclip() else stopNoclip() end
        end,
    })

    TabMain:CreateToggle({
        Name = "Infinity Jump",
        CurrentValue = false,
        Flag = "InfJump",
        Callback = function(state)
            infinityJumpEnabled = state
        end,
    })

    TabMain:CreateToggle({
        Name = "God Mode",
        CurrentValue = false,
        Flag = "GodMode",
        Callback = function(state)
            antiDamageEnabled = state
            if state then
                setupAntiDamage()
            else
                if antiDamageHeartbeat then antiDamageHeartbeat:Disconnect() end
                antiDamageHeartbeat = nil
            end
        end,
    })

    TabMain:CreateDivider()

    TabMain:CreateToggle({
        Name = "Spin Muter",
        CurrentValue = false,
        Flag = "Spin",
        Callback = function(state)
            toggleSpin(state)
        end,
    })

    TabMain:CreateSlider({
        Name = "Spin Speed",
        Range = {1, 200},
        Increment = 1,
        Suffix = "",
        CurrentValue = spinSpeed,
        Flag = "SpinSpeed",
        Callback = function(val)
            spinSpeed = val
        end,
    })

    TabMain:CreateToggle({
        Name = "Invisible Mode",
        CurrentValue = false,
        Flag = "Invisible",
        Callback = function(state)
            toggleInvisible(state)
        end,
    })

    -- ================== TAB ESP ==================
    local TabESP = Window:CreateTab("ESP", "eye")

    TabESP:CreateToggle({
        Name = "ESP Box",
        CurrentValue = false,
        Flag = "ESPBox",
        Callback = function(state)
            espEnabled = state
        end,
    })

    TabESP:CreateToggle({
        Name = "ESP Line",
        CurrentValue = false,
        Flag = "ESPLine",
        Callback = function(state)
            lineEnabled = state
        end,
    })

    TabESP:CreateToggle({
        Name = "ESP Skeleton",
        CurrentValue = false,
        Flag = "ESPSkeleton",
        Callback = function(state)
            skeletonEnabled = state
        end,
    })

    TabESP:CreateToggle({
        Name = "Player Counter",
        CurrentValue = false,
        Flag = "PlayerCounter",
        Callback = function(state)
            playerCounterEnabled = state
        end,
    })

    -- ================== TAB UTILITY ==================
    local TabUtil = Window:CreateTab("Utility", "settings")

    -- Teleport ke Player
    local playerNames = {}
    local function refreshPlayers()
        playerNames = {}
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                table.insert(playerNames, p.Name)
            end
        end
        if #playerNames == 0 then playerNames = {"(Tidak ada player lain)"} end
        return playerNames
    end
    refreshPlayers()

    TabUtil:CreateDropdown({
        Name = "Teleport ke Player",
        Options = playerNames,
        CurrentOption = {},
        MultipleOptions = false,
        Flag = "TeleportPlayer",
        Callback = function(selected)
            local targetName = selected
            if type(selected) == "table" then targetName = selected[1] end
            local target = Players:FindFirstChild(targetName)
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
               and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 3, 0)
                Rayfield:Notify({Title = "Teleport", Content = "Berhasil teleport ke " .. targetName, Duration = 2, Image = 4483362458})
            end
        end,
    })

    TabUtil:CreateButton({
        Name = "Refresh Daftar Player",
        Callback = function()
            refreshPlayers()
            Rayfield:Notify({Title = "Refresh", Content = "Daftar player diperbarui.", Duration = 2, Image = 4483362458})
        end,
    })

    TabUtil:CreateDivider()

    -- Freeze All
    local freezeAllEnabled = false
    TabUtil:CreateToggle({
        Name = "Freeze All Player (Visual)",
        CurrentValue = false,
        Flag = "FreezeAll",
        Callback = function(state)
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
        end,
    })

    -- Freeze Diri
    local freezeSelfEnabled = false
    TabUtil:CreateToggle({
        Name = "Freeze Diri Sendiri",
        CurrentValue = false,
        Flag = "FreezeSelf",
        Callback = function(state)
            freezeSelfEnabled = state
            local myChar = LocalPlayer.Character
            if myChar then
                local hrp = myChar:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.Anchored = state end
            end
        end,
    })

    LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        if freezeSelfEnabled then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.Anchored = true end
        end
        task.wait(1)
        if noclipEnabled then startNoclip() end
        if flyEnabled then startFlyMode() end
    end)

    TabUtil:CreateDivider()
    TabUtil:CreateSection("Spectator Player")

    -- ================== SPECTATOR SYSTEM ==================
    local spectateEnabled  = false
    local spectateTarget   = nil
    local spectateConn     = nil
    local originalCamType  = Enum.CameraType.Custom
    local spectateNames    = {}

    local function stopSpectate()
        spectateEnabled = false
        spectateTarget  = nil
        if spectateConn then spectateConn:Disconnect(); spectateConn = nil end
        pcall(function()
            Camera.CameraType = Enum.CameraType.Custom
            Camera.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") or nil
        end)
    end

    local function startSpectate(targetPlayer)
        if not targetPlayer or not targetPlayer.Character then
            Rayfield:Notify({Title="Spectator", Content="Karakter player tidak ditemukan!", Duration=2, Image=4483362458})
            return
        end
        spectateTarget  = targetPlayer
        spectateEnabled = true

        pcall(function()
            originalCamType        = Camera.CameraType
            Camera.CameraType      = Enum.CameraType.Custom
            local targetHum        = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
            if targetHum then Camera.CameraSubject = targetHum end
        end)

        if spectateConn then spectateConn:Disconnect() end
        spectateConn = RunService.RenderStepped:Connect(function()
            if not spectateEnabled or not spectateTarget then stopSpectate(); return end
            local char = spectateTarget.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hrp and hum then
                pcall(function()
                    Camera.CameraType    = Enum.CameraType.Custom
                    Camera.CameraSubject = hum
                end)
            end
        end)

        Rayfield:Notify({
            Title   = "Spectator",
            Content = "Sekarang menonton: " .. targetPlayer.Name,
            Duration= 3,
            Image   = 4483362458
        })
    end

    local function refreshSpectateList()
        spectateNames = {}
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                table.insert(spectateNames, p.Name)
            end
        end
        if #spectateNames == 0 then spectateNames = {"(Tidak ada player)"} end
        return spectateNames
    end
    refreshSpectateList()

    TabUtil:CreateDropdown({
        Name          = "Pilih Target Spectator",
        Options       = spectateNames,
        CurrentOption = {},
        MultipleOptions = false,
        Flag          = "SpectateTarget",
        Callback      = function(selected)
            local name = type(selected) == "table" and selected[1] or selected
            local target = Players:FindFirstChild(name)
            if spectateEnabled then
                if target and target.Character then
                    spectateTarget = target
                    local hum = target.Character:FindFirstChildOfClass("Humanoid")
                    if hum then Camera.CameraSubject = hum end
                    Rayfield:Notify({Title="Spectator", Content="Ganti target ke: "..name, Duration=2, Image=4483362458})
                end
            end
        end,
    })

    TabUtil:CreateButton({
        Name = "Refresh Daftar Spectator",
        Callback = function()
            refreshSpectateList()
            Rayfield:Notify({Title="Refresh", Content="Daftar spectator diperbarui.", Duration=2, Image=4483362458})
        end,
    })

    TabUtil:CreateToggle({
        Name         = "Aktifkan Spectator",
        CurrentValue = false,
        Flag         = "SpectateToggle",
        Callback     = function(state)
            if state then
                local sel = spectateNames[1]
                local target = Players:FindFirstChild(sel)
                if target and sel ~= "(Tidak ada player)" then
                    startSpectate(target)
                else
                    Rayfield:Notify({Title="Spectator", Content="Pilih player dulu dari dropdown!", Duration=3, Image=4483362458})
                end
            else
                stopSpectate()
                Rayfield:Notify({Title="Spectator", Content="Spectator dinonaktifkan.", Duration=2, Image=4483362458})
            end
        end,
    })

    Players.PlayerRemoving:Connect(function(p)
        if spectateTarget == p then
            stopSpectate()
            Rayfield:Notify({Title="Spectator", Content=p.Name.." keluar dari server!", Duration=3, Image=4483362458})
        end
    end)

    -- ================== TAB SETTINGS (FITUR BARU) ==================
    local TabSettings = Window:CreateTab("Settings", "settings")

    TabSettings:CreateSection("🔆 Full Bright")

    TabSettings:CreateToggle({
        Name = "Full Bright",
        CurrentValue = false,
        Flag = "FullBright",
        Callback = function(state)
            toggleFullBright(state)
            Rayfield:Notify({
                Title = "Full Bright",
                Content = state and "Full Bright diaktifkan" or "Full Bright dinonaktifkan",
                Duration = 2,
                Image = 4483362458
            })
        end,
    })

    TabSettings:CreateDivider()
    TabSettings:CreateSection("🌫️ No Fog")

    TabSettings:CreateToggle({
        Name = "No Fog",
        CurrentValue = false,
        Flag = "NoFog",
        Callback = function(state)
            toggleNoFog(state)
            Rayfield:Notify({
                Title = "No Fog",
                Content = state and "No Fog diaktifkan" or "No Fog dinonaktifkan",
                Duration = 2,
                Image = 4483362458
            })
        end,
    })

    TabSettings:CreateDivider()
    TabSettings:CreateSection("🔄 Server Control")

    TabSettings:CreateButton({
        Name = "🔄 Rejoin Server",
        Callback = function()
            rejoinServer()
        end,
    })

    TabSettings:CreateButton({
        Name = "🚀 Server Hop",
        Callback = function()
            serverHop()
        end,
    })

    TabSettings:CreateDivider()
    TabSettings:CreateSection("⚠️ Informasi")

    TabSettings:CreateLabel("Full Bright & No Fog akan otomatis reset saat matikan toggle.")
    TabSettings:CreateLabel("Rejoin & Server Hop akan memindahkanmu ke server baru.")

    -- ================== TAB INFO ==================
    local TabInfo = Window:CreateTab("Info", "info")

    TabInfo:CreateSection("Informasi Lisensi")

    TabInfo:CreateLabel("Executor: " .. userExecutor)
    local keyPaketStr = keyJenis ~= "" and keyJenis or "Tidak diketahui"
    TabInfo:CreateLabel("Paket: " .. keyPaketStr)

    local countdownElement = TabInfo:CreateLabel("Memuat waktu...")
    infoKeyCountdownLabel = countdownElement

    task.spawn(function()
        while true do
            task.wait(1)
            if keyValidGlobal and keyExpiryTime > 0 then
                local _, _, _, _, timeStr = getTimeRemaining(keyExpiryTime)
                local txt = os.time() > keyExpiryTime and "⛔ Key EXPIRED!" or ("⏳ Sisa: " .. timeStr)
                pcall(function()
                    if countdownElement and countdownElement.Set then
                        countdownElement:Set(txt)
                    end
                end)
            end
        end
    end)

    TabInfo:CreateDivider()
    TabInfo:CreateSection("Developer")
    TabInfo:CreateLabel("Developer: Putzzdev")
    TabInfo:CreateLabel("WhatsApp: 088976255131")

    TabInfo:CreateButton({
        Name = "Salin Link Get Key",
        Callback = function()
            if setclipboard then
                setclipboard(WEBSITE_URL)
                Rayfield:Notify({Title = "Berhasil", Content = "Link key berhasil disalin!", Duration = 3, Image = 4483362458})
            else
                Rayfield:Notify({Title = "Info", Content = WEBSITE_URL, Duration = 5, Image = 4483362458})
            end
        end,
    })
end

-- ================== KEY SYSTEM RAYFIELD ==================
local function startKeySystem()
    local TempRayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

    local KeyWindow = TempRayfield:CreateWindow({
        Name = "Drip Client - Verifikasi",
        LoadingTitle = "Drip Client",
        LoadingSubtitle = "Masukkan Key Premium Anda",
        Theme = "Amethyst",
        DisableRayfieldPrompts = true,
        DisableBuildWarnings = true,
        ConfigurationSaving = { Enabled = false },
        KeySystem = false,
    })

    local KeyTab = KeyWindow:CreateTab("Key System", "key-round")
    KeyTab:CreateSection("Autentikasi Key Server")

    local statusLabel = KeyTab:CreateLabel("Menunggu verifikasi lisensi...")

    local inputKeyValue = ""

    KeyTab:CreateInput({
        Name = "Masukkan Key Premium",
        PlaceholderText = "Input key server di sini...",
        RemoveTextAfterFocusLost = false,
        Flag = "KeyInput",
        Callback = function(text)
            inputKeyValue = text
        end,
    })

    KeyTab:CreateButton({
        Name = "AUTENTIKASI KEY",
        Callback = function()
            local inputKey = inputKeyValue
            inputKey = tostring(inputKey):gsub("%s+", "")

            if inputKey == "" then
                pcall(function() statusLabel:Set("❌ Key tidak boleh kosong!") end)
                TempRayfield:Notify({Title = "Error", Content = "Key tidak boleh kosong!", Duration = 3, Image = 4483362458})
                return
            end

            pcall(function() statusLabel:Set("🔄 Sedang verifikasi ke database server...") end)
            TempRayfield:Notify({Title = "Verifikasi", Content = "Mengecek key ke server...", Duration = 2, Image = 4483362458})

            local isValid, message = checkKeyExpiry(inputKey)

            if isValid then
                pcall(function() statusLabel:Set("✅ Key Valid! Memuat interface...") end)
                TempRayfield:Notify({Title = "Sukses!", Content = "Key valid! Interface sedang dimuat.", Duration = 3, Image = 4483362458})
                task.wait(1.5)
                pcall(function() KeyWindow:Destroy() end)
                task.wait(0.3)
                loadMainScript()
            else
                pcall(function() statusLabel:Set("❌ " .. message) end)
                TempRayfield:Notify({Title = "Gagal", Content = message, Duration = 4, Image = 4483362458})
            end
        end,
    })

    KeyTab:CreateButton({
        Name = "Ambil Key (Salin Link)",
        Callback = function()
            if setclipboard then
                setclipboard(WEBSITE_URL)
                TempRayfield:Notify({Title = "Link Disalin", Content = "Buka browser dan paste link untuk mendapatkan key.", Duration = 4, Image = 4483362458})
            else
                TempRayfield:Notify({Title = "Link Key", Content = WEBSITE_URL, Duration = 6, Image = 4483362458})
            end
        end,
    })
end

-- ================== ESP PLAYER INIT ==================
for _, p in pairs(Players:GetPlayers()) do createESP(p) createSkeleton(p) end
Players.PlayerAdded:Connect(function(p) createESP(p) createSkeleton(p) end)
Players.PlayerRemoving:Connect(function(p)
    if ESPTable[p] then for _, d in pairs(ESPTable[p]) do pcall(function() d:Remove() end) end ESPTable[p] = nil end
    if SkeletonESP[p] then for _, ld in pairs(SkeletonESP[p]) do pcall(function() ld[1]:Remove() end) end SkeletonESP[p] = nil end
end)

-- ================== START ==================
startKeySystem()