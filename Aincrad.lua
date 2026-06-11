-- ================== DRIP CLIENT V9.0 - PREMIUM UI ==================
-- Developer: Putzzdev | WA: 088976255131
-- Fitur: Buka/Tutup UI, Anti Error, Drag & Drop

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

-- ================== ANTI ERROR ==================
local function safeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        warn("Error: ", result)
        return nil
    end
    return result
end

-- ================== DETEKSI EXECUTOR ==================
local function detectExecutor()
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
        local success, result = safeCall(exec.check)
        if success and result then return exec.name end
    end
    local success, idName = safeCall(function() if identifyexecutor then return identifyexecutor() end return nil end)
    if success and idName and idName ~= "" then return idName end
    return "Unknown Executor"
end

local userExecutor = detectExecutor()

-- ================== KEY SYSTEM ==================
local FIREBASE_URL = "https://key-database-701af-default-rtdb.asia-southeast1.firebasedatabase.app/keys.json"
local WEBSITE_URL = "https://drip-client-get-key.vercel.app/"
local SAVE_FILE = "drip_key_data.txt"

local activeKeys = {}
local currentUserKey = nil
local keyExpiryTime = 0
local keyJenis = ""
local keyValidGlobal = false

local function loadKeyData()
    safeCall(function()
        if isfile and isfile(SAVE_FILE) then
            local content = readfile(SAVE_FILE)
            if content and content ~= "" then
                local data = HttpService:JSONDecode(content)
                if data then activeKeys = data end
            end
        end
    end)
end

local function saveKeyData()
    safeCall(function()
        if writefile then
            local json = HttpService:JSONEncode(activeKeys)
            if json then writefile(SAVE_FILE, json) end
        end
    end)
end

local function getKeysFromFirebase()
    local success, data = safeCall(function() return game:HttpGet(FIREBASE_URL) end)
    if success and data then
        local success2, jsonData = safeCall(function() return HttpService:JSONDecode(data) end)
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
            local durationMap = {
                ["1 JAM"] = 1/24, ["1 HARI"] = 1, ["2 HARI"] = 2,
                ["3 HARI"] = 3, ["7 HARI"] = 7, ["30 HARI"] = 30,
                ["PERMANEN"] = 9999999
            }
            expiryDays = durationMap[keyJenisData] or 1
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
local lineColor = Color3.fromRGB(255, 0, 0)
local skeletonEnabled = false
local ESPTable = {}
local SkeletonESP = {}
local playerCounterEnabled = false
local enemyCountText = nil

local flyEnabled = false
local flyConnection = nil
local flySpeed = 100
local ctrl = {f = 0, b = 0, l = 0, r = 0}
local speed = 0
local flyTorso = nil

local noclipEnabled = false
local noclipConnection = nil

local speedEnabled = false
local normalSpeed = 16
local fastSpeed = 60

local infinityJumpEnabled = false
local jumpPowerEnabled = false
local jumpPowerValue = 50

local antiDamageEnabled = false
local antiDamageHeartbeat = nil

local spinEnabled = false
local spinSpeed = 50
local spinConnection = nil
local spinDirection = 1

local invisibleEnabled = false
local invisibleConnection = nil
local invisibleParts = {}

local themeColor = Color3.fromRGB(156, 39, 176)
local darkBg = Color3.fromRGB(20, 20, 28)
local MAX_ESP_DISTANCE = 200000

-- ================== FUNGSI FITUR ==================
local function startFlyMode()
    safeCall(function()
        local char = LocalPlayer.Character
        if not char then return end
        flyTorso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
        if not flyTorso then return end
        
        ctrl = {f = 0, b = 0, l = 0, r = 0}
        speed = 0
        
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = true end
        
        local bg = Instance.new("BodyGyro", flyTorso)
        bg.Name = "FlyBG"
        bg.P = 9e4
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        
        local bv = Instance.new("BodyVelocity", flyTorso)
        bv.Name = "FlyBV"
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        
        if flyConnection then flyConnection:Disconnect() end
        flyConnection = RunService.RenderStepped:Connect(function()
            if not flyEnabled or not LocalPlayer.Character or not flyTorso or not flyTorso.Parent then return end
            
            ctrl.f = UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0
            ctrl.b = UserInputService:IsKeyDown(Enum.KeyCode.S) and -1 or 0
            ctrl.l = UserInputService:IsKeyDown(Enum.KeyCode.A) and -1 or 0
            ctrl.r = UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0
            
            local forward = ctrl.f + ctrl.b
            if forward ~= 0 or ctrl.l + ctrl.r ~= 0 then
                speed = math.min(speed + 1.5, flySpeed)
                local camCF = Camera.CFrame
                bv.Velocity = ((camCF.LookVector * forward) + (camCF.RightVector * (ctrl.l + ctrl.r))).Unit * speed
            else
                speed = math.max(speed - 2, 0)
                bv.Velocity = Vector3.new(0, 0, 0)
            end
            bg.CFrame = Camera.CFrame
        end)
    end)
end

local function stopFlyMode()
    flyEnabled = false
    if flyConnection then safeCall(function() flyConnection:Disconnect() end) flyConnection = nil end
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
        local t = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
        if t then
            safeCall(function() if t:FindFirstChild("FlyBV") then t.FlyBV:Destroy() end end)
            safeCall(function() if t:FindFirstChild("FlyBG") then t.FlyBG:Destroy() end end)
        end
    end
end

local function startNoclip()
    if noclipConnection then noclipConnection:Disconnect() end
    noclipConnection = RunService.Stepped:Connect(function()
        if noclipEnabled and LocalPlayer.Character then
            safeCall(function()
                for _, p in pairs(LocalPlayer.Character:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end)
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
                safeCall(function()
                    LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(spinSpeed * spinDirection), 0)
                end)
            end
        end)
    end
end

local function toggleInvisible(state)
    invisibleEnabled = state
    if invisibleConnection then invisibleConnection:Disconnect() invisibleConnection = nil end
    
    if state and LocalPlayer.Character then
        invisibleParts = {}
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") and v.Transparency == 0 then
                table.insert(invisibleParts, {part = v, origTrans = v.Transparency})
                v.Transparency = 0.5
            end
        end
    else
        if LocalPlayer.Character then
            for _, data in pairs(invisibleParts) do
                safeCall(function()
                    if data.part and data.part.Parent then
                        data.part.Transparency = data.origTrans
                    end
                end)
            end
        end
        invisibleParts = {}
    end
end

local function setupAntiDamage()
    if antiDamageHeartbeat then
        safeCall(function() antiDamageHeartbeat:Disconnect() end)
        antiDamageHeartbeat = nil
    end
    
    local function makeInvincible()
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        hum.Health = hum.MaxHealth
        safeCall(function() hum:SetAttribute("MaxHealth", math.huge) end)
    end
    
    makeInvincible()
    antiDamageHeartbeat = RunService.Heartbeat:Connect(function()
        if antiDamageEnabled then makeInvincible() end
    end)
end

-- Infinity Jump
UserInputService.JumpRequest:Connect(function()
    if infinityJumpEnabled and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Jump Power
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
    if enemyCountText then safeCall(function() enemyCountText:Remove() end) end
    enemyCountText = Drawing.new("Text")
    enemyCountText.Size = 20
    enemyCountText.Color = Color3.fromRGB(255, 50, 50)
    enemyCountText.Center = true
    enemyCountText.Outline = true
    enemyCountText.Visible = false
end

local function createESP(player)
    if player == LocalPlayer then return end
    local box = Drawing.new("Square")
    box.Thickness = 1.5
    box.Filled = false
    box.Visible = false
    box.Color = Color3.fromRGB(0, 0, 0)
    
    local name = Drawing.new("Text")
    name.Size = 12
    name.Center = true
    name.Outline = true
    name.Visible = false
    name.Color = Color3.fromRGB(255, 255, 255)
    
    local dist = Drawing.new("Text")
    dist.Size = 10
    dist.Center = true
    dist.Outline = true
    dist.Visible = false
    dist.Color = Color3.fromRGB(200, 200, 200)
    
    local line = Drawing.new("Line")
    line.Thickness = 1.5
    line.Visible = false
    
    local healthBg = Drawing.new("Square")
    healthBg.Filled = true
    healthBg.Visible = false
    healthBg.Color = Color3.fromRGB(40, 40, 40)
    
    local healthFg = Drawing.new("Square")
    healthFg.Filled = true
    healthFg.Visible = false
    
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
    for _, joint in ipairs(joints) do
        local l = Drawing.new("Line")
        l.Thickness = 1.5
        l.Color = Color3.fromRGB(0, 255, 0)
        l.Visible = false
        table.insert(lines, {l, joint[1], joint[2]})
    end
    SkeletonESP[player] = lines
end

-- ESP Render Loop
createPlayerCounter()
for _, p in pairs(Players:GetPlayers()) do
    safeCall(function() createESP(p) createSkeleton(p) end)
end

Players.PlayerAdded:Connect(function(p) safeCall(function() createESP(p) createSkeleton(p) end) end)
Players.PlayerRemoving:Connect(function(p)
    safeCall(function()
        if ESPTable[p] then
            for _, d in pairs(ESPTable[p]) do d:Remove() end
            ESPTable[p] = nil
        end
        if SkeletonESP[p] then
            for _, ld in pairs(SkeletonESP[p]) do ld[1]:Remove() end
            SkeletonESP[p] = nil
        end
    end)
end)

RunService.RenderStepped:Connect(function()
    safeCall(function()
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
                        box.Visible = true
                        
                        name.Position = Vector2.new(pos.X, top.Y - 15)
                        name.Text = player.DisplayName or player.Name
                        name.Visible = true
                        
                        distText.Text = math.floor(distance) .. "m"
                        distText.Position = Vector2.new(pos.X, bottom.Y + 3)
                        distText.Visible = true
                        
                        if hum then
                            local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                            hBg.Size = Vector2.new(4, height)
                            hBg.Position = Vector2.new(pos.X + width/2 + 3, top.Y)
                            hBg.Visible = true
                            
                            hFg.Size = Vector2.new(4, height * pct)
                            hFg.Position = Vector2.new(pos.X + width/2 + 3, bottom.Y - (height * pct))
                            hFg.Color = Color3.fromRGB(255 * (1-pct), 255 * pct, 0)
                            hFg.Visible = true
                        end
                    else
                        box.Visible = false
                        name.Visible = false
                        distText.Visible = false
                        hBg.Visible = false
                        hFg.Visible = false
                    end
                    
                    if lineEnabled then
                        line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        line.To = Vector2.new(pos.X, pos.Y)
                        line.Color = lineColor
                        line.Visible = true
                    else
                        line.Visible = false
                    end
                else
                    box.Visible = false
                    name.Visible = false
                    distText.Visible = false
                    hBg.Visible = false
                    hFg.Visible = false
                    line.Visible = false
                end
            end
        end
        
        -- Skeleton Render
        if skeletonEnabled then
            for player, lines in pairs(SkeletonESP) do
                local char = player.Character
                if char and char:FindFirstChild("HumanoidRootPart") and myPos then
                    for _, lData in pairs(lines) do
                        local l, p1Name, p2Name = lData[1], lData[2], lData[3]
                        local p1 = char:FindFirstChild(p1Name)
                        local p2 = char:FindFirstChild(p2Name)
                        if p1 and p2 then
                            local pos1, vis1 = Camera:WorldToViewportPoint(p1.Position)
                            local pos2, vis2 = Camera:WorldToViewportPoint(p2.Position)
                            if vis1 and vis2 then
                                l.From = Vector2.new(pos1.X, pos1.Y)
                                l.To = Vector2.new(pos2.X, pos2.Y)
                                l.Visible = true
                            else
                                l.Visible = false
                            end
                        else
                            l.Visible = false
                        end
                    end
                else
                    for _, ld in pairs(lines) do ld[1].Visible = false end
                end
            end
        else
            for _, lines in pairs(SkeletonESP) do
                for _, ld in pairs(lines) do ld[1].Visible = false end
            end
        end
        
        -- Player Counter
        if playerCounterEnabled and enemyCountText then
            enemyCountText.Text = "👥 PLAYERS: " .. screenCount
            enemyCountText.Position = Vector2.new(Camera.ViewportSize.X / 2, 50)
            enemyCountText.Visible = true
        elseif enemyCountText then
            enemyCountText.Visible = false
        end
    end)
end)

-- ================== UI MODERN DENGAN TOMBOL MINIMIZE ==================
local function loadMainScript()
    -- Hapus GUI lama
    safeCall(function()
        if game.CoreGui:FindFirstChild("DripKeySystem") then game.CoreGui.DripKeySystem:Destroy() end
        if game.CoreGui:FindFirstChild("DripClientUI") then game.CoreGui.DripClientUI:Destroy() end
    end)
    
    createPlayerCounter()
    
    -- ScreenGui utama
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "DripClientUI"
    ScreenGui.Parent = game.CoreGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Parent = ScreenGui
    mainFrame.Size = UDim2.new(0, 380, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -190, 0.5, -250)
    mainFrame.BackgroundColor3 = darkBg
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)
    
    -- Outline
    local outline = Instance.new("UIStroke", mainFrame)
    outline.Color = themeColor
    outline.Thickness = 1.5
    
    -- Header
    local header = Instance.new("Frame")
    header.Parent = mainFrame
    header.Size = UDim2.new(1, 0, 0, 55)
    header.BackgroundColor3 = themeColor
    header.BackgroundTransparency = 0.2
    header.BorderSizePixel = 0
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 12)
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Parent = header
    title.Size = UDim2.new(1, -60, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "DRIP CLIENT PREMIUM"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Subtitle
    local subtitle = Instance.new("TextLabel")
    subtitle.Parent = header
    subtitle.Size = UDim2.new(1, -60, 0.4, 0)
    subtitle.Position = UDim2.new(0, 15, 0, 30)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "✓ Premium Active"
    subtitle.TextColor3 = Color3.fromRGB(0, 255, 120)
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 11
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Tombol Minimize/Collapse
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Parent = header
    minimizeBtn.Size = UDim2.new(0, 35, 0, 35)
    minimizeBtn.Position = UDim2.new(1, -45, 0, 10)
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    minimizeBtn.BackgroundTransparency = 0.9
    minimizeBtn.Text = "−"
    minimizeBtn.TextColor3 = Color3.new(1, 1, 1)
    minimizeBtn.TextSize = 24
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.BorderSizePixel = 0
    Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(1, 0)
    
    -- Tombol Close (Exit UI)
    local closeBtn = Instance.new("TextButton")
    closeBtn.Parent = header
    closeBtn.Size = UDim2.new(0, 35, 0, 35)
    closeBtn.Position = UDim2.new(1, -90, 0, 10)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
    closeBtn.BackgroundTransparency = 0.2
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.TextSize = 16
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)
    
    -- Content Container (yang bisa di-collapse)
    local contentContainer = Instance.new("Frame")
    contentContainer.Parent = mainFrame
    contentContainer.Size = UDim2.new(1, 0, 1, -55)
    contentContainer.Position = UDim2.new(0, 0, 0, 55)
    contentContainer.BackgroundTransparency = 1
    contentContainer.BorderSizePixel = 0
    contentContainer.ClipsDescendants = true
    
    -- Tab Bar
    local tabBar = Instance.new("Frame")
    tabBar.Parent = contentContainer
    tabBar.Size = UDim2.new(1, -20, 0, 40)
    tabBar.Position = UDim2.new(0, 10, 0, 5)
    tabBar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    tabBar.BorderSizePixel = 0
    Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 8)
    
    -- Tab Buttons & Contents
    local tabs = {}
    local tabContents = {}
    local tabNames = {"MAIN", "ESP", "UTILITY", "INFO"}
    
    for i, name in ipairs(tabNames) do
        local btn = Instance.new("TextButton")
        btn.Parent = tabBar
        btn.Size = UDim2.new(0.25, -4, 1, -6)
        btn.Position = UDim2.new((i-1) * 0.25, 2, 0, 3)
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        btn.BackgroundTransparency = 0.5
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(180, 180, 180)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        btn.BorderSizePixel = 0
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
        
        local content = Instance.new("ScrollingFrame")
        content.Parent = contentContainer
        content.Size = UDim2.new(1, -20, 1, -55)
        content.Position = UDim2.new(0, 10, 0, 50)
        content.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
        content.BackgroundTransparency = 0.3
        content.BorderSizePixel = 0
        content.ScrollBarThickness = 3
        content.ScrollBarImageColor3 = themeColor
        content.Visible = (i == 1)
        content.CanvasSize = UDim2.new(0, 0, 0, 0)
        content.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Instance.new("UICorner", content).CornerRadius = UDim.new(0, 8)
        
        local layout = Instance.new("UIListLayout", content)
        layout.Padding = UDim.new(0, 6)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        
        tabs[btn] = content
        tabContents[i] = content
        
        btn.MouseButton1Click:Connect(function()
            for b, c in pairs(tabs) do
                b.TextColor3 = Color3.fromRGB(180, 180, 180)
                b.BackgroundTransparency = 0.5
                c.Visible = false
            end
            btn.TextColor3 = Color3.new(1, 1, 1)
            btn.BackgroundTransparency = 0.1
            content.Visible = true
        end)
    end
    
    -- Fungsi membuat toggle button
    local function createToggle(parent, text, default, callback)
        local frame = Instance.new("Frame")
        frame.Parent = parent
        frame.Size = UDim2.new(0.96, 0, 0, 38)
        frame.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        frame.BorderSizePixel = 0
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
        
        local label = Instance.new("TextLabel")
        label.Parent = frame
        label.Size = UDim2.new(0.65, 0, 1, 0)
        label.Position = UDim2.new(0.05, 0, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.new(1, 1, 1)
        label.Font = Enum.Font.Gotham
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left
        
        local switch = Instance.new("Frame")
        switch.Parent = frame
        switch.Size = UDim2.new(0, 40, 0, 20)
        switch.Position = UDim2.new(0.85, 0, 0.5, -10)
        switch.BackgroundColor3 = default and themeColor or Color3.fromRGB(70, 70, 80)
        switch.BorderSizePixel = 0
        Instance.new("UICorner", switch).CornerRadius = UDim.new(0, 10)
        
        local circle = Instance.new("Frame")
        circle.Parent = switch
        circle.Size = UDim2.new(0, 16, 0, 16)
        circle.Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0.05, 0, 0.5, -8)
        circle.BackgroundColor3 = Color3.new(1, 1, 1)
        circle.BorderSizePixel = 0
        Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
        
        local state = default
        local button = Instance.new("TextButton")
        button.Parent = frame
        button.Size = UDim2.new(1, 0, 1, 0)
        button.BackgroundTransparency = 1
        button.Text = ""
        
        button.MouseButton1Click:Connect(function()
            state = not state
            TweenService:Create(switch, TweenInfo.new(0.15), {BackgroundColor3 = state and themeColor or Color3.fromRGB(70, 70, 80)}):Play()
            TweenService:Create(circle, TweenInfo.new(0.15), {Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0.05, 0, 0.5, -8)}):Play()
            safeCall(function() callback(state) end)
        end)
        
        return frame
    end
    
    -- Fungsi membuat slider
    local function createSlider(parent, text, min, max, default, callback)
        local frame = Instance.new("Frame")
        frame.Parent = parent
        frame.Size = UDim2.new(0.96, 0, 0, 55)
        frame.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        frame.BorderSizePixel = 0
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
        
        local label = Instance.new("TextLabel")
        label.Parent = frame
        label.Size = UDim2.new(0.7, 0, 0, 20)
        label.Position = UDim2.new(0.05, 0, 0, 5)
        label.BackgroundTransparency = 1
        label.Text = text .. " (" .. default .. ")"
        label.TextColor3 = Color3.new(1, 1, 1)
        label.Font = Enum.Font.Gotham
        label.TextSize = 11
        label.TextXAlignment = Enum.TextXAlignment.Left
        
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Parent = frame
        valueLabel.Size = UDim2.new(0.2, 0, 0, 20)
        valueLabel.Position = UDim2.new(0.75, 0, 0, 5)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = tostring(default)
        valueLabel.TextColor3 = themeColor
        valueLabel.Font = Enum.Font.GothamBold
        valueLabel.TextSize = 11
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        
        local sliderBar = Instance.new("Frame")
        sliderBar.Parent = frame
        sliderBar.Size = UDim2.new(0.9, 0, 0, 4)
        sliderBar.Position = UDim2.new(0.05, 0, 0, 30)
        sliderBar.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
        sliderBar.BorderSizePixel = 0
        Instance.new("UICorner", sliderBar).CornerRadius = UDim.new(0, 2)
        
        local fill = Instance.new("Frame")
        fill.Parent = sliderBar
        fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = themeColor
        fill.BorderSizePixel = 0
        Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 2)
        
        local value = default
        local dragging = false
        
        local function updateValue(inputPos)
            local relativeX = math.clamp((inputPos.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
            value = min + (relativeX * (max - min))
            value = math.floor(value)
            fill.Size = UDim2.new(relativeX, 0, 1, 0)
            valueLabel.Text = tostring(value)
            label.Text = text .. " (" .. value .. ")"
            safeCall(function() callback(value) end)
        end
        
        sliderBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                updateValue(input)
            end
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                updateValue(input)
            end
        end)
        
        return frame
    end
    
    -- Fungsi membuat button
    local function createButton(parent, text, callback)
        local btn = Instance.new("TextButton")
        btn.Parent = parent
        btn.Size = UDim2.new(0.96, 0, 0, 36)
        btn.BackgroundColor3 = themeColor
        btn.BackgroundTransparency = 0.2
        btn.Text = text
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.BorderSizePixel = 0
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        
        btn.MouseButton1Click:Connect(function()
            safeCall(function() callback() end)
        end)
        
        return btn
    end
    
    -- ================== BUILD MAIN TAB ==================
    local mainContent = tabContents[1]
    
    createToggle(mainContent, "✈ Fly Mode", false, function(s)
        flyEnabled = s
        if s then startFlyMode() else stopFlyMode() end
    end)
    
    createSlider(mainContent, "Fly Speed", 20, 200, 100, function(v)
        flySpeed = v
    end)
    
    createToggle(mainContent, "⚡ Speed Boost", false, function(s)
        speedEnabled = s
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = s and fastSpeed or normalSpeed end
    end)
    
    createToggle(mainContent, "🚪 NoClip", false, function(s)
        noclipEnabled = s
        if s then startNoclip() else stopNoclip() end
    end)
    
    createToggle(mainContent, "🦘 Infinity Jump", false, function(s)
        infinityJumpEnabled = s
    end)
    
    createSlider(mainContent, "Jump Power", 30, 150, 50, function(v)
        jumpPowerValue = v
        jumpPowerEnabled = true
    end)
    
    createToggle(mainContent, "🛡 God Mode", false, function(s)
        antiDamageEnabled = s
        if s then setupAntiDamage()
        elseif antiDamageHeartbeat then antiDamageHeartbeat:Disconnect() antiDamageHeartbeat = nil end
    end)
    
    createToggle(mainContent, "🔄 Spin Mode", false, function(s)
        toggleSpin(s)
    end)
    
    createSlider(mainContent, "Spin Speed", 10, 200, 50, function(v)
        spinSpeed = v
    end)
    
    createToggle(mainContent, "👻 Invisible Mode", false, function(s)
        toggleInvisible(s)
    end)
    
    -- ================== BUILD ESP TAB ==================
    local espContent = tabContents[2]
    
    createToggle(espContent, "📦 ESP Box", false, function(s)
        espEnabled = s
    end)
    
    createToggle(espContent, "📏 ESP Line", false, function(s)
        lineEnabled = s
    end)
    
    createToggle(espContent, "🦴 ESP Skeleton", false, function(s)
        skeletonEnabled = s
    end)
    
    createToggle(espContent, "👥 Player Counter", false, function(s)
        playerCounterEnabled = s
    end)
    
    -- Color Picker sederhana untuk line color
    local colorFrame = Instance.new("Frame")
    colorFrame.Parent = espContent
    colorFrame.Size = UDim2.new(0.96, 0, 0, 40)
    colorFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    colorFrame.BorderSizePixel = 0
    Instance.new("UICorner", colorFrame).CornerRadius = UDim.new(0, 8)
    
    local colorLabel = Instance.new("TextLabel")
    colorLabel.Parent = colorFrame
    colorLabel.Size = UDim2.new(0.5, 0, 1, 0)
    colorLabel.Position = UDim2.new(0.05, 0, 0, 0)
    colorLabel.BackgroundTransparency = 1
    colorLabel.Text = "Line Color"
    colorLabel.TextColor3 = Color3.new(1, 1, 1)
    colorLabel.Font = Enum.Font.Gotham
    colorLabel.TextSize = 12
    colorLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local colorPicker = Instance.new("TextButton")
    colorPicker.Parent = colorFrame
    colorPicker.Size = UDim2.new(0, 40, 0, 30)
    colorPicker.Position = UDim2.new(0.8, 0, 0.5, -15)
    colorPicker.BackgroundColor3 = lineColor
    colorPicker.BorderSizePixel = 0
    Instance.new("UICorner", colorPicker).CornerRadius = UDim.new(0, 6)
    
    local colors = {Color3.fromRGB(255,0,0), Color3.fromRGB(0,255,0), Color3.fromRGB(0,0,255), Color3.fromRGB(255,255,0), Color3.fromRGB(255,0,255), Color3.fromRGB(0,255,255)}
    local colorIndex = 1
    
    colorPicker.MouseButton1Click:Connect(function()
        colorIndex = colorIndex % #colors + 1
        lineColor = colors[colorIndex]
        colorPicker.BackgroundColor3 = lineColor
    end)
    
    -- ================== BUILD UTILITY TAB ==================
    local utilContent = tabContents[3]
    
    -- Teleport Dropdown
    local teleFrame = Instance.new("Frame")
    teleFrame.Parent = utilContent
    teleFrame.Size = UDim2.new(0.96, 0, 0, 38)
    teleFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    teleFrame.BorderSizePixel = 0
    teleFrame.ClipsDescendants = true
    Instance.new("UICorner", teleFrame).CornerRadius = UDim.new(0, 8)
    
    local teleBtn = Instance.new("TextButton")
    teleBtn.Parent = teleFrame
    teleBtn.Size = UDim2.new(1, 0, 0, 38)
    teleBtn.BackgroundTransparency = 1
    teleBtn.Text = "🎯 TELEPORT KE PLAYER ▼"
    teleBtn.TextColor3 = Color3.new(1, 1, 1)
    teleBtn.Font = Enum.Font.GothamBold
    teleBtn.TextSize = 12
    
    local playerList = Instance.new("ScrollingFrame")
    playerList.Parent = teleFrame
    playerList.Size = UDim2.new(1, 0, 0, 120)
    playerList.Position = UDim2.new(0, 0, 0, 38)
    playerList.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    playerList.BackgroundTransparency = 1
    playerList.ScrollBarThickness = 3
    playerList.Visible = false
    Instance.new("UICorner", playerList).CornerRadius = UDim.new(0, 8)
    
    local playerLayout = Instance.new("UIListLayout", playerList)
    playerLayout.Padding = UDim.new(0, 4)
    
    local isOpen = false
    
    local function updatePlayerList()
        for _, child in pairs(playerList:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local pBtn = Instance.new("TextButton")
                pBtn.Parent = playerList
                pBtn.Size = UDim2.new(0.96, 0, 0, 30)
                pBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
                pBtn.Text = plr.DisplayName or plr.Name
                pBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
                pBtn.Font = Enum.Font.Gotham
                pBtn.TextSize = 11
                Instance.new("UICorner", pBtn).CornerRadius = UDim.new(0, 5)
                
                pBtn.MouseButton1Click:Connect(function()
                    safeCall(function()
                        if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            LocalPlayer.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame * CFrame.new(0, 3, 0)
                        end
                    end)
                    isOpen = false
                    playerList.Visible = false
                    teleFrame.Size = UDim2.new(0.96, 0, 0, 38)
                end)
            end
        end
        
        playerList.CanvasSize = UDim2.new(0, 0, 0, playerLayout.AbsoluteContentSize.Y + 10)
    end
    
    teleBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            updatePlayerList()
            playerList.Visible = true
            teleFrame.Size = UDim2.new(0.96, 0, 0, 165)
        else
            playerList.Visible = false
            teleFrame.Size = UDim2.new(0.96, 0, 0, 38)
        end
    end)
    
    createToggle(utilContent, "❄ Freeze All Players (Visual)", false, function(s)
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                for _, part in pairs(p.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        safeCall(function() part.Anchored = s end)
                    end
                end
            end
        end
    end)
    
    local freezeSelfEnabled = false
    createToggle(utilContent, "❄ Freeze Diri Sendiri", false, function(s)
        freezeSelfEnabled = s
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.Anchored = s end
        end
    end)
    
    -- ================== BUILD INFO TAB ==================
    local infoContent = tabContents[4]
    
    local infoFrame = Instance.new("Frame")
    infoFrame.Parent = infoContent
    infoFrame.Size = UDim2.new(0.96, 0, 0, 180)
    infoFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    infoFrame.BorderSizePixel = 0
    Instance.new("UICorner", infoFrame).CornerRadius = UDim.new(0, 8)
    
    local labels = {
        {"👤 Developer", "Putzzdev"},
        {"📞 WhatsApp", "088976255131"},
        {"💻 Executor", userExecutor},
        {"🔑 Paket Key", keyJenis},
        {"📅 Status", keyValidGlobal and "✅ Premium Active" or "⚠ Not Activated"}
    }
    
    for i, data in ipairs(labels) do
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Parent = infoFrame
        titleLabel.Size = UDim2.new(0.4, 0, 0, 25)
        titleLabel.Position = UDim2.new(0.05, 0, 0, 8 + (i-1) * 28)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = data[1] .. ":"
        titleLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
        titleLabel.Font = Enum.Font.Gotham
        titleLabel.TextSize = 11
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Parent = infoFrame
        valueLabel.Size = UDim2.new(0.5, 0, 0, 25)
        valueLabel.Position = UDim2.new(0.45, 0, 0, 8 + (i-1) * 28)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = data[2]
        valueLabel.TextColor3 = Color3.new(1, 1, 1)
        valueLabel.Font = Enum.Font.GothamBold
        valueLabel.TextSize = 11
        valueLabel.TextXAlignment = Enum.TextXAlignment.Left
    end
    
    local countdownLabel = Instance.new("TextLabel")
    countdownLabel.Parent = infoFrame
    countdownLabel.Size = UDim2.new(0.9, 0, 0, 25)
    countdownLabel.Position = UDim2.new(0.05, 0, 0, 155)
    countdownLabel.BackgroundTransparency = 1
    countdownLabel.Text = "⏱ Menghitung sisa waktu..."
    countdownLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
    countdownLabel.Font = Enum.Font.GothamBold
    countdownLabel.TextSize = 11
    countdownLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Update countdown
    task.spawn(function()
        while true do
            task.wait(1)
            if keyValidGlobal and keyExpiryTime > 0 then
                local _, _, _, _, timeStr = getTimeRemaining(keyExpiryTime)
                safeCall(function()
                    countdownLabel.Text = "⏱ Sisa Durasi: " .. timeStr
                    if os.time() > keyExpiryTime then
                        countdownLabel.Text = "⚠ KEY EXPIRED! Silakan beli key baru"
                        countdownLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
                    end
                end)
            end
        end
    end)
    
    createButton(infoContent, "📋 Copy WhatsApp", function()
        safeCall(function() setclipboard("088976255131") end)
    end)
    
    createButton(infoContent, "🕐 Cek Sisa Waktu", function()
        if keyValidGlobal and keyExpiryTime > 0 then
            local _, _, _, _, timeStr = getTimeRemaining(keyExpiryTime)
            -- Notif
        end
    end)
    
    -- ================== FUNGSI BUKA/TUTUP UI ==================
    local isMinimized = false
    local originalHeight = 500
    
    minimizeBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
                Size = UDim2.new(0, 380, 0, 55)
            }):Play()
            contentContainer.Visible = false
            minimizeBtn.Text = "+"
        else
            contentContainer.Visible = true
            TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quart), {
                Size = UDim2.new(0, 380, 0, 500)
            }):Play()
            minimizeBtn.Text = "−"
        end
    end)
    
    closeBtn.MouseButton1Click:Connect(function()
        TweenService:Create(mainFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quart), {
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1
        }):Play()
        task.wait(0.15)
        ScreenGui:Destroy()
    end)
    
    -- Drag untuk memindahkan window (klik header)
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(0, startPos.X.Offset + delta.X, 0, startPos.Y.Offset + delta.Y)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    -- Tombol floating untuk membuka UI (jika UI ditutup)
    local openBtn = Instance.new("TextButton")
    openBtn.Parent = ScreenGui
    openBtn.Size = UDim2.new(0, 45, 0, 45)
    openBtn.Position = UDim2.new(0, 10, 0.5, -22)
    openBtn.BackgroundColor3 = themeColor
    openBtn.Text = "⚡"
    openBtn.TextColor3 = Color3.new(1, 1, 1)
    openBtn.TextSize = 24
    openBtn.Font = Enum.Font.GothamBold
    openBtn.BorderSizePixel = 0
    Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 12)
    Instance.new("UIStroke", openBtn).Color = Color3.new(1, 1, 1)
    
    openBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = true
        if isMinimized then
            mainFrame.Size = UDim2.new(0, 380, 0, 55)
            contentContainer.Visible = false
        else
            mainFrame.Size = UDim2.new(0, 380, 0, 500)
            contentContainer.Visible = true
        end
        TweenService:Create(mainFrame, TweenInfo.new(0.2), {
            Position = UDim2.new(0.5, -190, 0.5, -250)
        }):Play()
    end)
    
    -- Reconnect handlers
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        if noclipEnabled then startNoclip() end
        if flyEnabled then startFlyMode() end
        if freezeSelfEnabled then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.Anchored = true end
        end
        if speedEnabled then
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = fastSpeed end
        end
        if antiDamageEnabled then setupAntiDamage() end
    end)
end

-- ================== KEY AUTH SYSTEM ==================
local function showKeySystem()
    local KeyGui = Instance.new("ScreenGui")
    KeyGui.Name = "DripKeySystem"
    KeyGui.Parent = game.CoreGui
    KeyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local KeyFrame = Instance.new("Frame")
    KeyFrame.Parent = KeyGui
    KeyFrame.Size = UDim2.new(0, 350, 0, 320)
    KeyFrame.Position = UDim2.new(0.5, -175, 0.5, -160)
    KeyFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    KeyFrame.Active = true
    KeyFrame.Draggable = true
    Instance.new("UICorner", KeyFrame).CornerRadius = UDim.new(0, 12)
    Instance.new("UIStroke", KeyFrame).Color = themeColor
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Parent = KeyFrame
    title.Size = UDim2.new(1, 0, 0, 45)
    title.Position = UDim2.new(0, 0, 0, 15)
    title.BackgroundTransparency = 1
    title.Text = "🔐 DRIP CLIENT PREMIUM"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 16
    
    -- Subtitle
    local subtitle = Instance.new("TextLabel")
    subtitle.Parent = KeyFrame
    subtitle.Size = UDim2.new(1, -40, 0, 30)
    subtitle.Position = UDim2.new(0, 20, 0, 55)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Masukkan key premium untuk mengakses cheat"
    subtitle.TextColor3 = Color3.fromRGB(160, 160, 170)
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 11
    
    -- Input Box
    local keyBox = Instance.new("TextBox")
    keyBox.Parent = KeyFrame
    keyBox.Size = UDim2.new(0.9, 0, 0, 40)
    keyBox.Position = UDim2.new(0.05, 0, 0, 100)
    keyBox.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    keyBox.TextColor3 = Color3.new(1, 1, 1)
    keyBox.PlaceholderText = "Ketik atau paste key di sini..."
    keyBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 110)
    keyBox.Font = Enum.Font.Gotham
    keyBox.TextSize = 12
    keyBox.ClearTextOnFocus = true
    Instance.new("UICorner", keyBox).CornerRadius = UDim.new(0, 8)
    
    -- Verify Button
    local verifyBtn = Instance.new("TextButton")
    verifyBtn.Parent = KeyFrame
    verifyBtn.Size = UDim2.new(0.9, 0, 0, 40)
    verifyBtn.Position = UDim2.new(0.05, 0, 0, 150)
    verifyBtn.BackgroundColor3 = themeColor
    verifyBtn.Text = "✅ VERIFIKASI KEY"
    verifyBtn.TextColor3 = Color3.new(1, 1, 1)
    verifyBtn.Font = Enum.Font.GothamBold
    verifyBtn.TextSize = 13
    Instance.new("UICorner", verifyBtn).CornerRadius = UDim.new(0, 8)
    
    -- Get Key Button
    local getKeyBtn = Instance.new("TextButton")
    getKeyBtn.Parent = KeyFrame
    getKeyBtn.Size = UDim2.new(0.4, 0, 0, 30)
    getKeyBtn.Position = UDim2.new(0.3, 0, 0, 200)
    getKeyBtn.BackgroundColor3 = Color3.fromRGB(220, 120, 0)
    getKeyBtn.Text = "🔗 AMBIL KEY"
    getKeyBtn.TextColor3 = Color3.new(1, 1, 1)
    getKeyBtn.Font = Enum.Font.GothamBold
    getKeyBtn.TextSize = 11
    Instance.new("UICorner", getKeyBtn).CornerRadius = UDim.new(0, 6)
    
    -- Status
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Parent = KeyFrame
    statusLabel.Size = UDim2.new(0.9, 0, 0, 35)
    statusLabel.Position = UDim2.new(0.05, 0, 0, 245)
    statusLabel.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 10
    statusLabel.Text = "ℹ️ Menunggu verifikasi..."
    Instance.new("UICorner", statusLabel).CornerRadius = UDim.new(0, 6)
    
    getKeyBtn.MouseButton1Click:Connect(function()
        safeCall(function()
            setclipboard(WEBSITE_URL)
            statusLabel.Text = "✅ Link berhasil disalin ke clipboard!"
            statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        end)
    end)
    
    verifyBtn.MouseButton1Click:Connect(function()
        local inputKey = keyBox.Text:gsub("%s+", "")
        if inputKey == "" then
            statusLabel.Text = "❌ Key tidak boleh kosong!"
            statusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
            return
        end
        
        statusLabel.Text = "⏳ Memverifikasi ke server..."
        statusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
        
        local isValid, message = checkKeyExpiry(inputKey)
        
        if isValid then
            statusLabel.Text = "✅ " .. message
            statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            
            -- Animasi fade out
            TweenService:Create(KeyFrame, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            task.wait(0.3)
            KeyGui:Destroy()
            loadMainScript()
        else
            statusLabel.Text = "❌ " .. message
            statusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        end
    end)
end

-- Start the key system
showKeySystem()