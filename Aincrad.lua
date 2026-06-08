-- ================== DRIP CLIENT V8.2 PREMIUM (PERFECT KEY SYSTEM) ==================
-- Perbaikan: Ukuran loading awal diperkecil & warna hitam sedeng elegan
-- Perbaikan: Hitung mundur setelah key sukses diganti dengan Progress Bar animasi mulus
-- Penambahan: Sistem key hitung mundur real-time server permanen (Anti-Reset walau keluar game)

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
local infoKeyCountdownLabel = nil -- Digunakan untuk update text di tab info secara real-time

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
    
    -- SYSTEM ANTI-RESET PERMANEN: Cek apakah key ini pernah dipakai sebelumnya di device ini
    if activeKeys[inputKey] and activeKeys[inputKey].expiryTime then
        expiryTime = activeKeys[inputKey].expiryTime
        if currentTime > expiryTime then return false, "KEY SUDAH EXPIRED!" end
    else
        -- Jika pemakaian pertama kali, hitung waktu kedaluwarsa mutlak dari sekarang dan simpan permanen
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

-- Loading screen dihapus

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
local darkPurple = Color3.fromRGB(18, 14, 24) -- Disesuaikan agar warna tidak terlalu terang mencolok
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

-- ================== ENGINE ACTIONS (FLY, SPEED, DLL) ==================
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

    local lastctrl = {f = 0, b = 0, l = 0, r = 0}

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
        -- Reset dulu invisibleParts sebelum isi ulang
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
        -- Kembalikan transparency ke nilai asli masing-masing part
        if LocalPlayer.Character then
            for _, data in pairs(invisibleParts) do
                pcall(function()
                    if data.part and data.part.Parent then
                        data.part.Transparency = data.origTrans
                    end
                end)
            end
            -- Fallback: semua part yang masih transparan dikembalikan ke 0
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

-- ================== GOD MODE PERMANEN (BENERAN KEBAL) ==================
-- Fungsi setupAntiDamage yang ditingkatkan dengan multiple connections dan custom Disconnect
local function setupAntiDamage()
    -- Hapus semua koneksi sebelumnya jika ada
    if antiDamageHeartbeat then
        if type(antiDamageHeartbeat) == "table" and antiDamageHeartbeat._disconnect then
            antiDamageHeartbeat:_disconnect()
        elseif antiDamageHeartbeat.Disconnect then
            antiDamageHeartbeat:Disconnect()
        end
        antiDamageHeartbeat = nil
    end
    
    -- Kumpulan koneksi yang akan dikelola
    local connections = {}
    
    -- Fungsi untuk membuat karakter kebal
    local function makeInvincible()
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        
        hum.Health = hum.MaxHealth
        hum.BreakJointsOnDeath = false
        
        -- Hentikan koneksi HealthChanged sebelumnya jika ada
        if hum._godHealthConn then
            hum._godHealthConn:Disconnect()
            hum._godHealthConn = nil
        end
        
        -- Pasang HealthChanged untuk respon instan
        local healthConn = hum.HealthChanged:Connect(function(newHealth)
            if antiDamageEnabled and newHealth < hum.MaxHealth then
                hum.Health = hum.MaxHealth
            end
        end)
        hum._godHealthConn = healthConn
        table.insert(connections, healthConn)
    end
    
    -- Heartbeat untuk cadangan (jika HealthChanged gagal)
    local hbConn = RunService.Heartbeat:Connect(function()
        if antiDamageEnabled and LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health < hum.MaxHealth then
                hum.Health = hum.MaxHealth
            end
        end
    end)
    table.insert(connections, hbConn)
    
    -- Terapkan ke karakter saat ini
    makeInvincible()
    
    -- Event ketika karakter berganti (respawn)
    local charConn = LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.2) -- tunggu humanoid tersedia
        if antiDamageEnabled then
            makeInvincible()
        end
    end)
    table.insert(connections, charConn)
    
    -- Buat objek dengan metode Disconnect untuk kompatibilitas dengan toggle lama
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

-- LOOP PERMANEN UPDATE COUNTDOWN KEY DI TAB INFORMASI
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

-- ================== LOAD MAIN CHEAT INTERFACE ==================
local function loadMainScript()
    if game.CoreGui:FindFirstChild("DripKeySystem") then game.CoreGui.DripKeySystem:Destroy() end
    createPlayerCounter()
    
    local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
    ScreenGui.Name = "DripClient"
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local mainFrame = Instance.new("Frame", ScreenGui)
    mainFrame.Size = UDim2.new(0, 390, 0, 480)
    mainFrame.Position = UDim2.new(0.5, -195, 0.5, -240)
    mainFrame.BackgroundColor3 = darkPurple
    mainFrame.Active = true
    mainFrame.Draggable = true
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 16)
    
    local mainStroke = Instance.new("UIStroke", mainFrame)
    mainStroke.Color = themeColor
    mainStroke.Thickness = 2

    local header = Instance.new("Frame", mainFrame)
    header.Size = UDim2.new(1, 0, 0, 60)
    header.BackgroundColor3 = themeColor
    header.BackgroundTransparency = 0.3
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 16)
    
    local title = Instance.new("TextLabel", header)
    title.Size = UDim2.new(1, -30, 0.5, 0)
    title.Position = UDim2.new(0, 20, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "DRIP CLIENT PREMIUM"
    title.TextColor3 = Color3.new(1,1,1)
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    
    local subtitle = Instance.new("TextLabel", header)
    subtitle.Size = UDim2.new(1, -30, 0.3, 0)
    subtitle.Position = UDim2.new(0, 20, 0, 34)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Status: Terautentikasi Aman Server"
    subtitle.TextColor3 = Color3.fromRGB(0, 255, 120)
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 11
    subtitle.TextXAlignment = Enum.TextXAlignment.Left

    local tabBar = Instance.new("Frame", mainFrame)
    tabBar.Size = UDim2.new(0.94, 0, 0, 35)
    tabBar.Position = UDim2.new(0.03, 0, 0, 70)
    tabBar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 6)

    local tabs, contents = {}, {}
    local function createTab(name, idx)
        local btn = Instance.new("TextButton", tabBar)
        btn.Size = UDim2.new(0.25, -2, 1, -6)
        btn.Position = UDim2.new((idx-1)*0.25, 2, 0, 3)
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        btn.BackgroundTransparency = 0.5
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(180, 180, 180)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
        
        local content = Instance.new("ScrollingFrame", mainFrame)
        content.Size = UDim2.new(0.94, 0, 0, 350)
        content.Position = UDim2.new(0.03, 0, 0, 115)
        content.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
        content.BackgroundTransparency = 0.4
        content.BorderSizePixel = 0
        content.ScrollBarThickness = 4
        content.ScrollBarImageColor3 = themeColor
        content.Visible = false
        content.AutomaticCanvasSize = Enum.AutomaticSize.Y
        content.ScrollingDirection = Enum.ScrollingDirection.Y
        
        local layout = Instance.new("UIListLayout", content)
        layout.Padding = UDim.new(0, 6)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        
        table.insert(tabs, btn) table.insert(contents, content)
        
        btn.MouseButton1Click:Connect(function()
            for i, b in ipairs(tabs) do b.TextColor3 = Color3.fromRGB(180, 180, 180) b.BackgroundTransparency = 0.5 contents[i].Visible = false end
            btn.TextColor3 = Color3.new(1,1,1) btn.BackgroundTransparency = 0.1 content.Visible = true
        end)
        return content
    end
    
    local tabMain = createTab("MAIN", 1)
    local tabESP = createTab("ESP SYSTEM", 2)
    local tabUtility = createTab("UTILITY", 3)
    local tabInfo = createTab("INFO", 4)

    local function createToggle(parent, text, default, callback)
        local frame = Instance.new("Frame", parent) frame.Size = UDim2.new(0.95, 0, 0, 38) frame.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
        local label = Instance.new("TextLabel", frame) label.Size = UDim2.new(0.65, 0, 1, 0) label.Position = UDim2.new(0.05, 0, 0, 0) label.BackgroundTransparency = 1 label.Text = text label.TextColor3 = Color3.new(1,1,1) label.Font = Enum.Font.Gotham label.TextSize = 12 label.TextXAlignment = Enum.TextXAlignment.Left
        
        local switch = Instance.new("Frame", frame) switch.Size = UDim2.new(0, 40, 0, 20) switch.Position = UDim2.new(0.83, 0, 0.5, -10) switch.BackgroundColor3 = default and themeColor or Color3.fromRGB(70, 70, 80)
        Instance.new("UICorner", switch).CornerRadius = UDim.new(0, 10)
        local circle = Instance.new("Frame", switch) circle.Size = UDim2.new(0, 16, 0, 16) circle.Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0.05, 0, 0.5, -8) circle.BackgroundColor3 = Color3.new(1,1,1)
        Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
        
        local state = default
        local click = Instance.new("TextButton", frame) click.Size = UDim2.new(1, 0, 1, 0) click.BackgroundTransparency = 1 click.Text = ""
        click.MouseButton1Click:Connect(function()
            state = not state
            TweenService:Create(switch, TweenInfo.new(0.18), {BackgroundColor3 = state and themeColor or Color3.fromRGB(70, 70, 80)}):Play()
            TweenService:Create(circle, TweenInfo.new(0.18), {Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0.05, 0, 0.5, -8)}):Play()
            callback(state)
        end)
    end

    createToggle(tabMain, "Fly Mode", false, function(s) flyEnabled = s if s then startFlyMode() else stopFlyMode() end end)
    createToggle(tabMain, "Speed Boost", false, function(s) speedEnabled = s local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") if hum then hum.WalkSpeed = s and fastSpeed or normalSpeed end end)
    createToggle(tabMain, "NoClip", false, function(s) noclipEnabled = s if s then startNoclip() else stopNoclip() end end)
    createToggle(tabMain, "Infinity Jump", false, function(s) infinityJumpEnabled = s end)
    createToggle(tabMain, "God Mode", false, function(s)
        antiDamageEnabled = s
        if s then
            setupAntiDamage()
        else
            if antiDamageHeartbeat then antiDamageHeartbeat:Disconnect() end
            antiDamageHeartbeat = nil
        end
    end)
    createToggle(tabMain, "Spin Muter", false, function(s) toggleSpin(s) end)
    createToggle(tabMain, "Invisible Mode", false, function(s) toggleInvisible(s) end)

    createToggle(tabESP, "ESP Box (Hitam)", false, function(s) espEnabled = s end)
    createToggle(tabESP, "ESP Line", false, function(s) lineEnabled = s end)
    createToggle(tabESP, "ESP Skeleton", false, function(s) skeletonEnabled = s end)
    createToggle(tabESP, "Player Counter", false, function(s) playerCounterEnabled = s end)

    -- TAB UTILITY DROPDOWN TELEPORT
    local function createTeleportDropdown(parent)
        local baseFrame = Instance.new("Frame", parent) baseFrame.Size = UDim2.new(0.95, 0, 0, 38) baseFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 55) baseFrame.ClipsDescendants = true
        Instance.new("UICorner", baseFrame).CornerRadius = UDim.new(0, 6)
        local mainButton = Instance.new("TextButton", baseFrame) mainButton.Size = UDim2.new(1, 0, 0, 38) mainButton.BackgroundTransparency = 1 mainButton.Text = "TELEPORT KE PLAYER" mainButton.TextColor3 = Color3.new(1,1,1) mainButton.Font = Enum.Font.GothamBold mainButton.TextSize = 12
        local scrollList = Instance.new("ScrollingFrame", baseFrame) scrollList.Size = UDim2.new(1, 0, 0, 120) scrollList.Position = UDim2.new(0, 0, 0, 38) scrollList.BackgroundTransparency = 1 scrollList.ScrollBarThickness = 4 scrollList.ScrollBarImageColor3 = themeColor
        local listLayout = Instance.new("UIListLayout", scrollList) listLayout.Padding = UDim.new(0, 4) listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        
        local isOpen = false
        mainButton.MouseButton1Click:Connect(function()
            isOpen = not isOpen
            if isOpen then
                for _, c in pairs(scrollList:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
                for _, plr in pairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer then
                        local pBtn = Instance.new("TextButton", scrollList) pBtn.Size = UDim2.new(0.92, 0, 0, 26) pBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40) pBtn.TextColor3 = Color3.fromRGB(230, 230, 230) pBtn.Font = Enum.Font.Gotham pBtn.TextSize = 11 pBtn.Text = plr.DisplayName or plr.Name
                        Instance.new("UICorner", pBtn).CornerRadius = UDim.new(0, 4)
                        pBtn.MouseButton1Click:Connect(function()
                            if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                LocalPlayer.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame * CFrame.new(0, 3, 0)
                                showNotification("TELEPORT", "Teleport ke " .. plr.Name, 2, Color3.fromRGB(0,140,0))
                            end
                            isOpen = false TweenService:Create(baseFrame, TweenInfo.new(0.2), {Size = UDim2.new(0.95, 0, 0, 38)}):Play()
                        end)
                    end
                end
                scrollList.CanvasSize = UDim2.new(0,0,0, listLayout.AbsoluteContentSize.Y + 10)
                TweenService:Create(baseFrame, TweenInfo.new(0.2), {Size = UDim2.new(0.95, 0, 0, 165)}):Play()
            else
                TweenService:Create(baseFrame, TweenInfo.new(0.2), {Size = UDim2.new(0.95, 0, 0, 38)}):Play()
            end
        end)
    end
    createTeleportDropdown(tabUtility)

    -- ================== FREEZE ALL PLAYERS (VISUAL ONLY) ==================
    local freezeAllEnabled = false
    local frozenConnections = {}

    local function freezeAllPlayers(state)
        freezeAllEnabled = state
        -- Unfreeze dulu semua
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                for _, part in pairs(p.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        pcall(function() part.Anchored = false end)
                    end
                end
            end
        end
        if state then
            -- Freeze semua player lain secara client-side
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    for _, part in pairs(p.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            pcall(function() part.Anchored = true end)
                        end
                    end
                end
            end
            -- Freeze karakter baru yang spawn
            Players.PlayerAdded:Connect(function(p)
                p.CharacterAdded:Connect(function(char)
                    if freezeAllEnabled then
                        task.wait(0.5)
                        for _, part in pairs(char:GetDescendants()) do
                            if part:IsA("BasePart") then
                                pcall(function() part.Anchored = true end)
                            end
                        end
                    end
                end)
            end)
        end
    end

    createToggle(tabUtility, "❄️ Freeze All Player (Visual)", false, function(s)
        freezeAllPlayers(s)
        showNotification("FREEZE", s and "Semua player dibekukan!" or "Freeze dinonaktifkan", 2, s and Color3.fromRGB(0,180,255) or Color3.fromRGB(200,200,200))
    end)

    -- ================== FREEZE DIRI SENDIRI ==================
    local freezeSelfEnabled = false
    local freezeSelfBtn = nil
    local freezeSelfBtnVisible = false

    local function applyFreezeSelf(state)
        freezeSelfEnabled = state
        local myChar = LocalPlayer.Character
        if myChar then
            local hrp = myChar:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Anchored = state
            end
        end
        -- Update warna tombol float freeze
        if freezeSelfBtn then
            TweenService:Create(freezeSelfBtn, TweenInfo.new(0.15), {
                BackgroundColor3 = state and Color3.fromRGB(0, 180, 255) or Color3.fromRGB(30, 30, 45)
            }):Play()
            freezeSelfBtn.Text = state and "❄ ON" or "❄ OFF"
        end
    end

    -- Re-anchor saat respawn
    LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        if freezeSelfEnabled then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.Anchored = true end
        end
    end)

    createToggle(tabUtility, "❄️ Freeze Diri Sendiri (Tombol Luar)", false, function(s)
        -- Munculkan/sembunyikan tombol float freeze diri
        freezeSelfBtnVisible = s
        if s then
            if not freezeSelfBtn then
                -- Buat tombol float khusus freeze diri
                freezeSelfBtn = Instance.new("TextButton", ScreenGui)
                freezeSelfBtn.Size             = UDim2.new(0, 72, 0, 36)
                freezeSelfBtn.Position         = UDim2.new(0, 15, 0.5, 40)
                freezeSelfBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
                freezeSelfBtn.BorderSizePixel  = 0
                freezeSelfBtn.Text             = "❄ OFF"
                freezeSelfBtn.TextColor3       = Color3.fromRGB(0, 220, 255)
                freezeSelfBtn.Font             = Enum.Font.GothamBold
                freezeSelfBtn.TextSize         = 13
                freezeSelfBtn.ZIndex           = 20
                Instance.new("UICorner", freezeSelfBtn).CornerRadius = UDim.new(0, 10)
                local fss = Instance.new("UIStroke", freezeSelfBtn)
                fss.Color = Color3.fromRGB(0, 200, 255); fss.Thickness = 1.5

                -- Drag + Click sistem threshold (sama kayak tombol menu utama)
                local fsDrag   = false
                local fsMoved  = false
                local fsX, fsY = 0, 0
                local fsPX, fsPY = 0, 0
                local THRESHOLD = 6

                freezeSelfBtn.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1
                    or inp.UserInputType == Enum.UserInputType.Touch then
                        fsDrag  = true
                        fsMoved = false
                        fsX     = inp.Position.X
                        fsY     = inp.Position.Y
                        fsPX    = freezeSelfBtn.Position.X.Offset
                        fsPY    = freezeSelfBtn.Position.Y.Offset
                    end
                end)

                freezeSelfBtn.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1
                    or inp.UserInputType == Enum.UserInputType.Touch then
                        -- Kalau tidak gerak = klik biasa → toggle freeze
                        if not fsMoved then
                            applyFreezeSelf(not freezeSelfEnabled)
                        end
                        fsDrag  = false
                        fsMoved = false
                    end
                end)

                RunService.RenderStepped:Connect(function()
                    if not fsDrag then return end
                    local UIS = game:GetService("UserInputService")
                    local m   = UIS:GetMouseLocation()
                    local dx  = m.X - fsX
                    local dy  = m.Y - fsY
                    -- Anggap drag kalau geser lebih dari threshold
                    if math.abs(dx) > THRESHOLD or math.abs(dy) > THRESHOLD then
                        fsMoved = true
                    end
                    if fsMoved then
                        local vp = workspace.CurrentCamera.ViewportSize
                        freezeSelfBtn.Position = UDim2.new(0,
                            math.clamp(fsPX + dx, 0, vp.X - 72), 0,
                            math.clamp(fsPY + dy, 0, vp.Y - 36)
                        )
                    end
                end)

                -- Animasi masuk
                freezeSelfBtn.Size = UDim2.new(0, 0, 0, 36)
                TweenService:Create(freezeSelfBtn, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
                    Size = UDim2.new(0, 72, 0, 36)
                }):Play()
            else
                freezeSelfBtn.Visible = true
            end
        else
            -- Sembunyikan tombol dan matikan freeze
            applyFreezeSelf(false)
            if freezeSelfBtn then
                TweenService:Create(freezeSelfBtn, TweenInfo.new(0.15), {
                    Size = UDim2.new(0, 0, 0, 36)
                }):Play()
                task.delay(0.2, function()
                    if freezeSelfBtn then
                        freezeSelfBtn.Visible = false
                    end
                end)
            end
        end
    end)

    -- TAB INFO DENGAN SISTEM KEY COUNTDOWN DARI SERVER
    local infoBox = Instance.new("Frame", tabInfo) infoBox.Size = UDim2.new(0.95, 0, 0, 150) infoBox.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    Instance.new("UICorner", infoBox).CornerRadius = UDim.new(0, 8)
    
    local iLabel = Instance.new("TextLabel", infoBox) iLabel.Size = UDim2.new(1, 0, 0, 25) iLabel.BackgroundTransparency = 1 iLabel.Text = "INFORMASI LISENSI" iLabel.TextColor3 = themeColor iLabel.Font = Enum.Font.GothamBold iLabel.TextSize = 12

    local executorText = Instance.new("TextLabel", infoBox) executorText.Size = UDim2.new(0.92, 0, 0, 22) executorText.Position = UDim2.new(0.04, 0, 0, 30) executorText.BackgroundTransparency = 1 executorText.TextColor3 = Color3.fromRGB(200, 210, 255) executorText.Font = Enum.Font.Gotham executorText.TextSize = 11 executorText.Text = "Executor: " .. userExecutor executorText.TextXAlignment = Enum.TextXAlignment.Left

    local keyTypeText = Instance.new("TextLabel", infoBox) keyTypeText.Size = UDim2.new(0.92, 0, 0, 22) keyTypeText.Position = UDim2.new(0.04, 0, 0, 52) keyTypeText.BackgroundTransparency = 1 keyTypeText.TextColor3 = Color3.fromRGB(200, 210, 255) keyTypeText.Font = Enum.Font.Gotham executorText.TextSize = 11 keyTypeText.Text = "Jenis Paket: " .. keyJenis keyTypeText.TextXAlignment = Enum.TextXAlignment.Left

    -- Label Hitung Mundur yang diupdate tiap detik secara real-time
    infoKeyCountdownLabel = Instance.new("TextLabel", infoBox)
    infoKeyCountdownLabel.Size = UDim2.new(0.92, 0, 0, 22)
    infoKeyCountdownLabel.Position = UDim2.new(0.04, 0, 0, 74)
    infoKeyCountdownLabel.BackgroundTransparency = 1
    infoKeyCountdownLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
    infoKeyCountdownLabel.Font = Enum.Font.GothamBold
    infoKeyCountdownLabel.TextSize = 11
    infoKeyCountdownLabel.Text = "Menghubungkan sisa durasi server..."
    infoKeyCountdownLabel.TextXAlignment = Enum.TextXAlignment.Left

    local infoDevLabel = Instance.new("TextLabel", infoBox) infoDevLabel.Size = UDim2.new(0.92, 0, 0, 45) infoDevLabel.Position = UDim2.new(0.04, 0, 0, 100) infoDevLabel.BackgroundTransparency = 1 infoDevLabel.TextColor3 = Color3.fromRGB(160, 160, 170) infoDevLabel.Font = Enum.Font.Gotham infoDevLabel.TextSize = 10 infoDevLabel.Text = "Developer: Putzzdev\nWhatsApp: 088976255131" infoDevLabel.TextXAlignment = Enum.TextXAlignment.Left

    tabs[1].TextColor3 = Color3.new(1,1,1) tabs[1].BackgroundTransparency = 0.1 contents[1].Visible = true
    
    local openBtn = Instance.new("ImageButton", ScreenGui) openBtn.Size = UDim2.new(0, 50, 0, 50) openBtn.Position = UDim2.new(0, 15, 0.5, -25) openBtn.BackgroundTransparency = 1 openBtn.Image = "rbxassetid://72495850369898" openBtn.Active = true openBtn.Draggable = true
    Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 10)
    local obs = Instance.new("UIStroke", openBtn) obs.Color = Color3.new(1,1,1) obs.Thickness = 1.2

    local menuOpen = true
    openBtn.MouseButton1Click:Connect(function()
        menuOpen = not menuOpen
        if menuOpen then mainFrame.Visible = true TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {Position = UDim2.new(0.5, -195, 0.5, -240)}):Play()
        else TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {Position = UDim2.new(0.5, -195, 1, 10)}):Play() task.wait(0.2) mainFrame.Visible = false end
    end)
    
    LocalPlayer.CharacterAdded:Connect(function() task.wait(1) if noclipEnabled then startNoclip() end if flyEnabled then startFlyMode() end end)
end

-- ================== GUI LAYOUT AUTH KEY SYSTEM ==================
local KeyGui = Instance.new("ScreenGui", game.CoreGui)
KeyGui.Name = "DripKeySystem"
KeyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local KeyFrame = Instance.new("Frame", KeyGui)
KeyFrame.Size = UDim2.new(0, 340, 0, 320) -- Diperkecil agar sedeng dan tidak kebesaran di HP
KeyFrame.Position = UDim2.new(0.5, -170, 0.5, -160)
KeyFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24) -- Warna gelap kalem
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

-- ANIMASI MULTI PROGRESS BAR BARU SETELAH KEY VALIDI (MENGGANTIKAN TEKS 1,2,3)
local function runPremiumSuccessProgress()
    -- Hilangkan semua isi input GUI Key untuk proses transisi
    InfoFrame:Destroy()
    KeyTextBox:Destroy()
    VerifyBtn:Destroy()
    WebsiteBtn:Destroy()
    
    StatusFrame.Position = UDim2.new(0.05, 0, 0.65, 0)
    StatusLabel.Text = "Mengecek token validasi di database..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    
    -- Membuat progress bar kesuksesan di dalam UI Key
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

    -- Fade out dan destroy seluruh Key GUI sebelum buka main menu
    TweenService:Create(KeyFrame, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
    for _, v in pairs(KeyFrame:GetDescendants()) do
        if v:IsA("TextLabel") or v:IsA("TextButton") then
            pcall(function() TweenService:Create(v, TweenInfo.new(0.25), {TextTransparency = 1}):Play() end)
        elseif v:IsA("Frame") then
            pcall(function() TweenService:Create(v, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play() end)
        end
    end
    task.wait(0.3)
    -- Destroy seluruh KeyGui biar bersih
    if game.CoreGui:FindFirstChild("DripKeySystem") then
        game.CoreGui.DripKeySystem:Destroy()
    end

    pcall(loadMainScript)
end

-- EVENT KLIK AUTENTIKASI KEY
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
        runPremiumSuccessProgress() -- Menjalankan progress bar animasi pengganti teks hitung mundur
    else
        StatusLabel.Text = message 
        StatusLabel.TextColor3 = Color3.fromRGB(255,0,0) 
    end
end)

-- ================== INITIAL RUN ESP GRAPHICS ==================
for _, p in pairs(Players:GetPlayers()) do createESP(p) createSkeleton(p) end
Players.PlayerAdded:Connect(function(p) createESP(p) createSkeleton(p) end)
Players.PlayerRemoving:Connect(function(p)
    if ESPTable[p] then for _, d in pairs(ESPTable[p]) do pcall(function() d:Remove() end) end ESPTable[p] = nil end
    if SkeletonESP[p] then for _, ld in pairs(SkeletonESP[p]) do pcall(function() ld[1]:Remove() end) end SkeletonESP[p] = nil end
end)