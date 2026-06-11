-- ================== DRIP CLIENT V8.2 PREMIUM (FLUENT MOBILE EDITION) ==================
-- Perbaikan Ekstrem: Anti-Crash setelah verifikasi Key sukses di Executor Mobile / HP
-- Semua fitur dari file asli dipertahankan 100% tanpa ada yang dihapus.

repeat task.wait() until game:IsLoaded()

-- ================== LOAD SERVICES AWAL ==================
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

local themeColor = Color3.fromRGB(156, 39, 176)
local darkPurple = Color3.fromRGB(18, 14, 24)
local boxColor = Color3.fromRGB(0, 0, 0)
local skeletonColor = Color3.fromRGB(0, 255, 0)
local redColor = Color3.fromRGB(255, 0, 0)
local MAX_ESP_DISTANCE = 200000

local function showNotification(title, text, duration, color)
    local parentGui = game.CoreGui:FindFirstChild("DripClient") or game.CoreGui:FindFirstChild("DripKeySystem")
    if not parentGui then return end
    local notif = Instance.new("Frame", parentGui)
    notif.Size = UDim2.new(0, 260, 0, 50)
    notif.Position = UDim2.new(0.5, -130, 0, -60)
    notif.BackgroundColor3 = color or Color3.fromRGB(30, 30, 40)
    notif.BorderSizePixel = 0
    notif.ZIndex = 9999
    Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 8)

    local notifTitle = Instance.new("TextLabel", notif)
    notifTitle.Size = UDim2.new(1, 0, 0.4, 0)
    notifTitle.Position = UDim2.new(0, 0, 0, 4)
    notifTitle.BackgroundTransparency = 1
    notifTitle.Text = title
    notifTitle.TextColor3 = Color3.new(1, 1, 1)
    notifTitle.Font = Enum.Font.GothamBold
    notifTitle.TextSize = 13

    local notifText = Instance.new("TextLabel", notif)
    notifText.Size = UDim2.new(1, -10, 0.5, 0)
    notifText.Position = UDim2.new(0, 5, 0, 22)
    notifText.BackgroundTransparency = 1
    notifText.Text = text
    notifText.TextColor3 = Color3.fromRGB(200, 200, 200)
    notifText.Font = Enum.Font.Gotham
    notifText.TextSize = 11

    TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Position = UDim2.new(0.5, -130, 0, 20)}):Play()
    task.wait(duration or 2)
    TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Position = UDim2.new(0.5, -130, 0, -60)}):Play()
    task.wait(0.3)
    notif:Destroy()
end

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

-- ================== GOD MODE PERMANEN ==================
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
    enemyCountText.Color = redColor
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

task.spawn(function()
    while true do
        task.wait(1)
        if keyValidGlobal and keyExpiryTime > 0 and infoKeyCountdownLabel then
            local _, _, _, _, timeStr = getTimeRemaining(keyExpiryTime)
            if os.time() > keyExpiryTime then
                infoKeyCountdownLabel.Text = "Status Key: EXPIRED! (Harap ganti key)"
                infoKeyCountdownLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
            else
                infoKeyCountdownLabel.Text = "Sisa Durasi: " .. timeStr
            end
        end
    end
end)

-- ================== LOAD MAIN CHEAT INTERFACE (FLUENT IMPLEMENTATION) ==================
local function loadMainScript()
    if game.CoreGui:FindFirstChild("DripKeySystem") then game.CoreGui.DripKeySystem:Destroy() end
    createPlayerCounter()

    -- Load Fluent UI Engine External secara Aman
    local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    
    local Window = Fluent:CreateWindow({
        Title = "DRIP CLIENT PREMIUM",
        SubTitle = "Status: Terautentikasi Aman Server",
        TabWidth = 140,
        Size = UDim2.fromOffset(450, 320), -- Ukuran ideal responsif layar HP
        Acrylic = false,
        Theme = "Dark",
        MinimizeKey = Enum.KeyCode.LeftControl
    })

    -- Pembuatan Tabs Fluent
    local Tabs = {
        Main = Window:AddTab({ Title = "MAIN", Icon = "settings" }),
        ESP = Window:AddTab({ Title = "ESP SYSTEM", Icon = "eye" }),
        Utility = Window:AddTab({ Title = "UTILITY", Icon = "box" }),
        Info = Window:AddTab({ Title = "INFO", Icon = "info" })
    }

    -- ---------------- TAB MAIN ----------------
    Tabs.Main:AddToggle("FlyToggle", {Title = "Fly Mode", Default = false, Callback = function(Value)
        flyEnabled = Value if Value then startFlyMode() else stopFlyMode() end
    end})

    Tabs.Main:AddToggle("SpeedToggle", {Title = "Speed Boost", Default = false, Callback = function(Value)
        speedEnabled = Value local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = Value and fastSpeed or normalSpeed end
    end})

    Tabs.Main:AddToggle("NoclipToggle", {Title = "NoClip", Default = false, Callback = function(Value)
        noclipEnabled = Value if Value then startNoclip() else stopNoclip() end
    end})

    Tabs.Main:AddToggle("InfJumpToggle", {Title = "Infinity Jump", Default = false, Callback = function(Value)
        infinityJumpEnabled = Value
    end})

    Tabs.Main:AddToggle("GodModeToggle", {Title = "God Mode", Default = false, Callback = function(Value)
        antiDamageEnabled = Value
        if Value then setupAntiDamage() else if antiDamageHeartbeat then antiDamageHeartbeat:Disconnect() end antiDamageHeartbeat = nil end
    end})

    Tabs.Main:AddToggle("SpinToggle", {Title = "Spin Muter", Default = false, Callback = function(Value)
        toggleSpin(Value)
    end})

    Tabs.Main:AddToggle("InvisToggle", {Title = "Invisible Mode", Default = false, Callback = function(Value)
        toggleInvisible(Value)
    end})

    -- ---------------- TAB ESP ----------------
    Tabs.ESP:AddToggle("ESPBoxToggle", {Title = "ESP Box (Hitam)", Default = false, Callback = function(Value) espEnabled = Value end})
    Tabs.ESP:AddToggle("ESPLineToggle", {Title = "ESP Line", Default = false, Callback = function(Value) lineEnabled = Value end})
    Tabs.ESP:AddToggle("ESPSkelToggle", {Title = "ESP Skeleton", Default = false, Callback = function(Value) skeletonEnabled = Value end})
    Tabs.ESP:AddToggle("CounterToggle", {Title = "Player Counter", Default = false, Callback = function(Value) playerCounterEnabled = Value end})

    -- ---------------- TAB UTILITY ----------------
    local function getPlayerNames()
        local list = {} for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(list, p.Name) end end return list
    end

    local TeleportDropdown = Tabs.Utility:AddDropdown("TeleportDropdown", {
        Title = "TELEPORT KE PLAYER",
        Values = getPlayerNames(),
        Multi = false,
        Default = nil,
        Callback = function(Value)
            if Value then
                local plr = Players:FindFirstChild(Value)
                if plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame * CFrame.new(0, 3, 0)
                    showNotification("TELEPORT", "Teleport ke " .. plr.Name, 2, Color3.fromRGB(0,140,0))
                end
            end
        end
    })

    Tabs.Utility:AddButton({
        Title = "🔄 Refresh Daftar Player",
        Callback = function()
            TeleportDropdown:SetValues(getPlayerNames())
        end
    })

    Tabs.Utility:AddToggle("FreezeAllToggle", {Title = "❄️ Freeze All Player (Visual)", Default = false, Callback = function(Value)
        freezeAllEnabled = Value
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                for _, part in pairs(p.Character:GetDescendants()) do if part:IsA("BasePart") then pcall(function() part.Anchored = Value end) end end
            end
        end
        showNotification("FREEZE", Value and "Semua player dibekukan!" or "Freeze dinonaktifkan", 2, Value and Color3.fromRGB(0,180,255) or Color3.fromRGB(200,200,200))
    end})

    -- FREEZE DIRI SENDIRI BUTTON TRIGGER INTEGRATION
    local freezeSelfEnabled = false
    local freezeSelfBtn = nil
    local ScreenGui = game.CoreGui:FindFirstChild("DripClient") or game.CoreGui:FindFirstChild("Fluent")

    local function applyFreezeSelf(state)
        freezeSelfEnabled = state
        local myChar = LocalPlayer.Character
        if myChar and myChar:FindFirstChild("HumanoidRootPart") then myChar.HumanoidRootPart.Anchored = state end
        if freezeSelfBtn then
            freezeSelfBtn.BackgroundColor3 = state and Color3.fromRGB(0, 180, 255) or Color3.fromRGB(30, 30, 50)
            freezeSelfBtn.Text = state and "❄ ON" or "❄ OFF"
        end
    end

    Tabs.Utility:AddToggle("FreezeSelfToggle", {Title = "❄️ Freeze Diri Sendiri (Tombol)", Default = false, Callback = function(state)
        if state then
            if not freezeSelfBtn and ScreenGui then
                freezeSelfBtn = Instance.new("TextButton")
                freezeSelfBtn.Parent = ScreenGui
                freezeSelfBtn.Size = UDim2.new(0, 75, 0, 38)
                freezeSelfBtn.Position = UDim2.new(1, -85, 0, 70)
                freezeSelfBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
                freezeSelfBtn.BorderSizePixel = 0
                freezeSelfBtn.Text = "❄ OFF"
                freezeSelfBtn.TextColor3 = Color3.fromRGB(0, 220, 255)
                freezeSelfBtn.Font = Enum.Font.GothamBold
                freezeSelfBtn.TextSize = 13
                freezeSelfBtn.ZIndex = 20
                Instance.new("UICorner", freezeSelfBtn).CornerRadius = UDim.new(0, 12)
                local stroke = Instance.new("UIStroke", freezeSelfBtn)
                stroke.Color = Color3.fromRGB(0, 200, 255)
                stroke.Thickness = 1.5
                
                local dragging, dragStart, startPos, clickStart = false, nil, nil, nil
                freezeSelfBtn.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true dragStart = input.Position startPos = freezeSelfBtn.Position clickStart = input.Position
                    end
                end)
                freezeSelfBtn.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                        if clickStart and dragStart then
                            local deltaX = math.abs(clickStart.X - dragStart.X)
                            local deltaY = math.abs(clickStart.Y - dragStart.Y)
                            if deltaX < 8 and deltaY < 8 then applyFreezeSelf(not freezeSelfEnabled) end
                        end
                    end
                end)
                freezeSelfBtn.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        local delta = input.Position - dragStart
                        freezeSelfBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                    end
                end)
            elseif freezeSelfBtn then
                freezeSelfBtn.Visible = true
            end
        else
            applyFreezeSelf(false)
            if freezeSelfBtn then freezeSelfBtn.Visible = false end
        end
    end})

    -- ---------------- TAB INFO ----------------
    local infoSection = Tabs.Info:AddSection("Informasi Lisensi")
    local ExecLabel = Tabs.Info:AddParagraph({Title = "Executor", Content = userExecutor})
    local PacketLabel = Tabs.Info:AddParagraph({Title = "Jenis Paket", Content = keyJenis})
    local DurationLabel = Tabs.Info:AddParagraph({Title = "Sisa Durasi Server", Content = "Menghubungkan..."})
    Tabs.Info:AddParagraph({Title = "Developer Contact", Content = "Developer: Putzzdev\nWhatsApp: 088976255131"})

    -- Runtime Sync Realtime Countdown Label ke Fluent
    infoKeyCountdownLabel = {
        SetText = function(_, text) pcall(function() DurationLabel:SetText(text) end) end
    }

    Window:SelectTab(1)
    LocalPlayer.CharacterAdded:Connect(function() task.wait(1) if noclipEnabled then startNoclip() end if flyEnabled then startFlyMode() end end)
end

-- ================== GUI LAYOUT AUTH KEY SYSTEM ==================
local KeyGui = Instance.new("ScreenGui", game.CoreGui)
KeyGui.Name = "DripKeySystem"
KeyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local KeyFrame = Instance.new("Frame", KeyGui)
KeyFrame.Size = UDim2.new(0, 340, 0, 320)
KeyFrame.Position = UDim2.new(0.5, -170, 0.5, -160)
KeyFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
KeyFrame.Active = true
KeyFrame.Draggable = true
Instance.new("UICorner", KeyFrame).CornerRadius = UDim.new(0, 12)

local KeyStroke = Instance.new("UIStroke", KeyFrame)
KeyStroke.Color = themeColor
KeyStroke.Thickness = 1.5

local KeyTitle = Instance.new("TextLabel", KeyFrame)
KeyTitle.Size = UDim2.new(1, 0, 0, 40)
KeyTitle.Position = UDim2.new(0, 0, 0, 15)
KeyTitle.BackgroundTransparency = 1
KeyTitle.Text = "DRIP CLIENT VERIFIKASI"
KeyTitle.TextColor3 = Color3.new(1, 1, 1)
KeyTitle.Font = Enum.Font.GothamBlack
KeyTitle.TextSize = 14

local InfoFrame = Instance.new("Frame", KeyFrame)
InfoFrame.Size = UDim2.new(0.9, 0, 0, 45)
InfoFrame.Position = UDim2.new(0.05, 0, 0.22, 0)
InfoFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
Instance.new("UICorner", InfoFrame).CornerRadius = UDim.new(0, 6)

local InfoText = Instance.new("TextLabel", InfoFrame)
InfoText.Size = UDim2.new(1, -20, 1, 0)
InfoText.Position = UDim2.new(0, 10, 0, 0)
InfoText.BackgroundTransparency = 1
InfoText.Text = "Silakan input key premium Anda di bawah ini"
InfoText.TextColor3 = Color3.fromRGB(160, 160, 170)
InfoText.Font = Enum.Font.Gotham
InfoText.TextSize = 11

local KeyTextBox = Instance.new("TextBox", KeyFrame)
KeyTextBox.Size = UDim2.new(0.85, 0, 0, 36)
KeyTextBox.Position = UDim2.new(0.075, 0, 0.42, 0)
KeyTextBox.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
KeyTextBox.TextColor3 = Color3.new(1, 1, 1)
KeyTextBox.PlaceholderText = "Input key server di sini..."
KeyTextBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 110)
KeyTextBox.Font = Enum.Font.Gotham
KeyTextBox.TextSize = 12
KeyTextBox.ClearTextOnFocus = true
Instance.new("UICorner", KeyTextBox).CornerRadius = UDim.new(0, 6)

local VerifyBtn = Instance.new("TextButton", KeyFrame)
VerifyBtn.Size = UDim2.new(0.85, 0, 0, 36)
VerifyBtn.Position = UDim2.new(0.075, 0, 0.57, 0)
VerifyBtn.BackgroundColor3 = themeColor
VerifyBtn.Text = "AUTENTIKASI KEY"
VerifyBtn.TextColor3 = Color3.new(1, 1, 1)
VerifyBtn.Font = Enum.Font.GothamBold
VerifyBtn.TextSize = 12
Instance.new("UICorner", VerifyBtn).CornerRadius = UDim.new(0, 6)

local WebsiteBtn = Instance.new("TextButton", KeyFrame)
WebsiteBtn.Size = UDim2.new(0.35, 0, 0, 26)
WebsiteBtn.Position = UDim2.new(0.325, 0, 0.71, 0)
WebsiteBtn.BackgroundColor3 = Color3.fromRGB(220, 120, 0)
WebsiteBtn.Text = "AMBIL KEY"
WebsiteBtn.TextColor3 = Color3.new(1, 1, 1)
WebsiteBtn.Font = Enum.Font.GothamBold
WebsiteBtn.TextSize = 11
Instance.new("UICorner", WebsiteBtn).CornerRadius = UDim.new(0, 5)

local StatusFrame = Instance.new("Frame", KeyFrame)
StatusFrame.Size = UDim2.new(0.9, 0, 0, 32)
StatusFrame.Position = UDim2.new(0.05, 0, 0.84, 0)
StatusFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
Instance.new("UICorner", StatusFrame).CornerRadius = UDim.new(0, 6)

local StatusIcon = Instance.new("TextLabel", StatusFrame)
StatusIcon.Size = UDim2.new(0, 30, 1, 0)
StatusIcon.Position = UDim2.new(0, 5, 0, 0)
StatusIcon.BackgroundTransparency = 1
StatusIcon.Text = "ℹ️"
StatusIcon.TextSize = 12

local StatusLabel = Instance.new("TextLabel", StatusFrame)
StatusLabel.Size = UDim2.new(1, -40, 1, 0)
StatusLabel.Position = UDim2.new(0, 35, 0, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Menunggu verifikasi lisensi..."
StatusLabel.TextColor3 = Color3.new(1, 1, 1)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 10
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left

WebsiteBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(WEBSITE_URL)
        StatusLabel.Text = "Link berhasil disalin ke clipboard!"
        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        showNotification("BERHASIL", "Link web key disalin!", 2, Color3.fromRGB(0, 120, 0))
    else
        StatusLabel.Text = WEBSITE_URL
    end
end)

local function runPremiumSuccessProgress()
    InfoFrame:Destroy()
    KeyTextBox:Destroy()
    VerifyBtn:Destroy()
    WebsiteBtn:Destroy()
    
    StatusFrame.Position = UDim2.new(0.05, 0, 0.65, 0)
    StatusLabel.Text = "Mengecek token validasi di database..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    
    local successBarBg = Instance.new("Frame", KeyFrame)
    successBarBg.Size = UDim2.new(0.9, 0, 0, 6)
    successBarBg.Position = UDim2.new(0.05, 0, 0.48, 0)
    successBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    Instance.new("UICorner", successBarBg).CornerRadius = UDim.new(0, 3)
    
    local successBar = Instance.new("Frame", successBarBg)
    successBar.Size = UDim2.new(0, 0, 1, 0)
    successBar.BackgroundColor3 = Color3.fromRGB(0, 255, 120)
    Instance.new("UICorner", successBar).CornerRadius = UDim.new(0, 3)
    
    local function setProgress(pct, text)
        StatusLabel.Text = text
        local tw = TweenService:Create(successBar, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {Size = UDim2.new(pct, 0, 1, 0)})
        tw:Play()
        tw.Completed:Wait()
    end
    
    setProgress(0.30, "Membuka enkripsi enkapsulasi data...")
    task.wait(0.4)
    setProgress(0.75, "Sinkronisasi waktu server terenkripsi...")
    task.wait(0.4)
    setProgress(1.00, "Sukses! Meluncurkan interface utama...")
    task.wait(0.5)

    TweenService:Create(KeyFrame, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
    for _, v in pairs(KeyFrame:GetDescendants()) do
        if v:IsA("TextLabel") or v:IsA("TextButton") then
            pcall(function() TweenService:Create(v, TweenInfo.new(0.25), {TextTransparency = 1}):Play() end)
        elseif v:IsA("Frame") then
            pcall(function() TweenService:Create(v, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play() end)
        end
    end
    task.wait(0.3)
    if game.CoreGui:FindFirstChild("DripKeySystem") then
        game.CoreGui.DripKeySystem:Destroy()
    end

    pcall(loadMainScript)
end

VerifyBtn.MouseButton1Click:Connect(function()
    local inputKey = KeyTextBox.Text:gsub("%s+", "")
    if inputKey == "" then 
        StatusLabel.Text = "Key tidak boleh kosong!"
        StatusLabel.TextColor3 = Color3.fromRGB(255,0,0) 
        return 
    end
    
    StatusLabel.Text = "Sedang verifikasi ke database server..." 
    StatusLabel.TextColor3 = Color3.fromRGB(255,255,0) 
    
    local isValid, message = checkKeyExpiry(inputKey)
    
    if isValid then
        StatusLabel.Text = "Key Valid!" 
        StatusLabel.TextColor3 = Color3.fromRGB(0,255,120) 
        task.wait(0.5)
        runPremiumSuccessProgress()
    else
        StatusLabel.Text = message 
        StatusLabel.TextColor3 = Color3.fromRGB(255,0,0) end
end)

for _, p in pairs(Players:GetPlayers()) do createESP(p) createSkeleton(p) end
Players.PlayerAdded:Connect(function(p) createESP(p) createSkeleton(p) end)
Players.PlayerRemoving:Connect(function(p)
    if ESPTable[p] then for _, d in pairs(ESPTable[p]) do pcall(function() d:Remove() end) end ESPTable[p] = nil end
    if SkeletonESP[p] then for _, ld in pairs(SkeletonESP[p]) do pcall(function() ld[1]:Remove() end) end SkeletonESP[p] = nil end
end)