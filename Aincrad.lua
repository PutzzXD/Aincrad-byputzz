-- ================== AINCRAD V2.0 (FULL RECODE - NEW UI) ==================
-- Fitur: ESP line putih ke kepala, ESP box cyan tebal 2.2, health bar vertikal,
-- hologram (highlight merah tembus dinding), Noclip, God Mode, Speed 70, Infinity Jump,
-- Crosshair di tengah layar, Enemy counter, Timer sisa waktu key.
-- TAMBAHAN: Tab PLAYERS -> daftar semua player + tombol Teleport
-- UI Baru - Warna Cyan/Chan - Nama Aincrad

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

-- Warna baru (Tema Chan/Cyan)
local themeColor = Color3.fromRGB(0, 255, 255) -- CYAN / CHAN
local darkBg = Color3.fromRGB(10, 15, 25)     -- Biru gelap kehitaman
local grayBg = Color3.fromRGB(20, 25, 40)     -- Abu-abu kebiruan
local boxColor = Color3.fromRGB(0, 255, 255)   -- Cyan untuk ESP box
local putih = Color3.fromRGB(255, 255, 255)    -- Putih
local merah = Color3.fromRGB(255, 80, 80)      -- Merah untuk hologram

local DB_URL = "https://key-database-701af-default-rtdb.asia-southeast1.firebasedatabase.app/keys.json"
local WEB_URL = "https://putzzdevxit.github.io/KEY-GENERATOR-/"

local MAX_DIST = 115

-- Variabel key timer
local keyValid = false
local keyExpiryTime = 0
local keyType = ""

-- ESP vars
local espLineEnabled = false
local espBoxEnabled = false
local hologramEnabled = false

local espLines = {}
local espBoxes = {}
local espNames = {}
local espHealthBars = {}

local hologramHighlights = {}

local noclipEnabled = false
local noclipConn = nil

local godModeEnabled = false
local godModeConn = nil

local speedEnabled = false
local defaultSpeed = 16
local boostSpeed = 70

local infJumpEnabled = false
local infJumpConn = nil

-- Crosshair
local crosshairEnabled = false
local crosshairObject = nil

-- Enemy counter
local enemyCounterText = nil

-- ================== FUNGSI CEK KEY ==================
local function cekKey(key)
    local success, data = pcall(function()
        return game:HttpGet(DB_URL, true)
    end)
    if not success or not data then
        return false, "Gagal koneksi ke database!"
    end
    local success2, jsonData = pcall(function()
        return HttpService:JSONDecode(data)
    end)
    if not success2 or not jsonData then
        return false, "Gagal membaca database!"
    end
    
    local foundKeyData = nil
    local keyId = nil
    for id, keyData in pairs(jsonData) do
        if keyData.key and string.upper(keyData.key) == string.upper(key) then
            foundKeyData = keyData
            keyId = id
            break
        end
    end
    if not foundKeyData then
        return false, "KEY TIDAK TERDAFTAR!"
    end
    
    local jenis = foundKeyData.jenis or "PERMANEN"
    local expiryDays = 0
    if jenis == "1 JAM" then
        expiryDays = 1/24
    elseif jenis == "1 HARI" then
        expiryDays = 1
    elseif jenis == "PERMANEN" then
        expiryDays = 999999
    else
        expiryDays = 1
    end
    
    local firstUsed = foundKeyData.firstUsed
    local currentTime = os.time()
    
    if not firstUsed then
        firstUsed = currentTime
        local updateUrl = DB_URL:gsub(".json$", "/" .. keyId .. ".json")
        local updateData = {
            firstUsed = firstUsed,
            expiryDays = expiryDays
        }
        local body = HttpService:JSONEncode(updateData)
        pcall(function()
            if syn and syn.request then
                syn.request({Url = updateUrl, Method = "PATCH", Headers = {["Content-Type"] = "application/json"}, Body = body})
            elseif http and http.request then
                http.request({Url = updateUrl, Method = "PATCH", Headers = {["Content-Type"] = "application/json"}, Body = body})
            end
        end)
    end
    
    local expiryTime = firstUsed + (expiryDays * 86400)
    if expiryDays >= 999999 then expiryTime = math.huge end
    
    if currentTime > expiryTime and expiryTime ~= math.huge then
        return false, "KEY SUDAH EXPIRED!"
    end
    
    keyValid = true
    keyExpiryTime = expiryTime
    keyType = jenis
    return true, "KEY VALID! (" .. jenis .. ")"
end

-- ================== TELEPORT FUNCTION ==================
local function teleportToPlayer(targetPlayer)
    local myChar = LocalPlayer.Character
    local targetChar = targetPlayer.Character
    if not myChar or not targetChar then return end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
    if myHRP and targetHRP then
        myHRP.CFrame = targetHRP.CFrame + Vector3.new(0, 2, 0)
    end
end

-- ================== HOLOGRAM ==================
local function applyHologram(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char then return end
    if hologramHighlights[player] then
        hologramHighlights[player]:Destroy()
        hologramHighlights[player] = nil
    end
    local hl = Instance.new("Highlight")
    hl.Parent = char
    hl.FillColor = merah
    hl.FillTransparency = 0.4
    hl.OutlineColor = Color3.fromRGB(255, 200, 200)
    hl.OutlineTransparency = 0.2
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled = true
    hologramHighlights[player] = hl
end

local function removeHologram(player)
    if hologramHighlights[player] then
        hologramHighlights[player]:Destroy()
        hologramHighlights[player] = nil
    end
end

local function applyHologramToAll()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            applyHologram(p)
        end
    end
end

local function removeHologramFromAll()
    for p, _ in pairs(hologramHighlights) do
        removeHologram(p)
    end
end

local function onCharacterAdded(player, character)
    if hologramEnabled and player ~= LocalPlayer then
        task.wait(0.2)
        applyHologram(player)
    end
end

-- ================== ESP ==================
local function createLine(player)
    if player == LocalPlayer then return end
    local line = Drawing.new("Line")
    line.Thickness = 2
    line.Color = putih
    line.Visible = false
    table.insert(espLines, {line, player})
end

local function createBox(player)
    if player == LocalPlayer then return end
    local box = Drawing.new("Square")
    box.Thickness = 2.2
    box.Color = boxColor
    box.Filled = false
    box.Visible = false
    table.insert(espBoxes, {box, player})
    
    local name = Drawing.new("Text")
    name.Size = 13
    name.Color = Color3.fromRGB(255, 255, 255)
    name.Center = true
    name.Outline = true
    name.OutlineColor = Color3.fromRGB(0, 0, 0)
    name.Visible = false
    table.insert(espNames, {name, player})
    
    local healthBar = Drawing.new("Square")
    healthBar.Thickness = 0
    healthBar.Color = Color3.fromRGB(0, 255, 0)
    healthBar.Filled = true
    healthBar.Visible = false
    table.insert(espHealthBars, {healthBar, player})
end

local function clearESP()
    for _, v in pairs(espLines) do pcall(function() v[1]:Remove() end) end
    for _, v in pairs(espBoxes) do pcall(function() v[1]:Remove() end) end
    for _, v in pairs(espNames) do pcall(function() v[1]:Remove() end) end
    for _, v in pairs(espHealthBars) do pcall(function() v[1]:Remove() end) end
    espLines = {}
    espBoxes = {}
    espNames = {}
    espHealthBars = {}
end

local function updateESP()
    local myChar = LocalPlayer.Character
    local myPos = myChar and myChar:FindFirstChild("HumanoidRootPart") and myChar.HumanoidRootPart.Position
    
    for _, data in pairs(espLines) do
        local line, player = data[1], data[2]
        local char = player.Character
        if char and char:FindFirstChild("Head") and myPos and espLineEnabled then
            local head = char.Head
            local pos, vis = Camera:WorldToViewportPoint(head.Position)
            if vis then
                line.From = Vector2.new(Camera.ViewportSize.X / 2, 0)
                line.To = Vector2.new(pos.X, pos.Y)
                line.Visible = true
            else
                line.Visible = false
            end
        else
            line.Visible = false
        end
    end
    
    for _, data in pairs(espBoxes) do
        local box, player = data[1], data[2]
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Head") and myPos and espBoxEnabled then
            local hrp = char.HumanoidRootPart
            local head = char.Head
            local pos, vis = Camera:WorldToViewportPoint(hrp.Position)
            local dist = (myPos - hrp.Position).Magnitude
            if vis and dist <= MAX_DIST then
                local top = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local bottom = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                local height = math.abs(top.Y - bottom.Y)
                local width = height / 2
                box.Size = Vector2.new(width, height)
                box.Position = Vector2.new(pos.X - width/2, top.Y)
                box.Visible = true
            else
                box.Visible = false
            end
        else
            box.Visible = false
        end
    end
    
    for _, data in pairs(espNames) do
        local name, player = data[1], data[2]
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Head") and myPos and espBoxEnabled then
            local hrp = char.HumanoidRootPart
            local head = char.Head
            local pos, vis = Camera:WorldToViewportPoint(hrp.Position)
            local dist = (myPos - hrp.Position).Magnitude
            if vis and dist <= MAX_DIST then
                local top = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                name.Position = Vector2.new(pos.X, top.Y - 16)
                name.Text = player.Name .. " [" .. math.floor(dist) .. "m]"
                name.Visible = true
            else
                name.Visible = false
            end
        else
            name.Visible = false
        end
    end
    
    for _, data in pairs(espHealthBars) do
        local healthBar, player = data[1], data[2]
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Head") and myPos and espBoxEnabled then
            local hrp = char.HumanoidRootPart
            local head = char.Head
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            local pos, vis = Camera:WorldToViewportPoint(hrp.Position)
            local dist = (myPos - hrp.Position).Magnitude
            if vis and dist <= MAX_DIST and humanoid then
                local top = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local bottom = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                local height = math.abs(top.Y - bottom.Y)
                local width = height / 2
                local healthPercent = humanoid.Health / humanoid.MaxHealth
                local barWidth = 6
                local barHeight = height * healthPercent
                local barX = pos.X + width/2 + 2
                local barY = bottom.Y - (height * healthPercent)
                healthBar.Size = Vector2.new(barWidth, barHeight)
                healthBar.Position = Vector2.new(barX, barY)
                healthBar.Color = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
                healthBar.Visible = true
            else
                healthBar.Visible = false
            end
        else
            healthBar.Visible = false
        end
    end
end

local function initESP()
    clearESP()
    for _, p in pairs(Players:GetPlayers()) do
        createLine(p)
        createBox(p)
    end
end

Players.PlayerAdded:Connect(function(p)
    task.wait(0.5)
    createLine(p)
    createBox(p)
    p.CharacterAdded:Connect(function(char)
        onCharacterAdded(p, char)
    end)
    if hologramEnabled and p.Character then
        task.wait(0.5)
        applyHologram(p)
    end
end)

Players.PlayerRemoving:Connect(function(p)
    removeHologram(p)
end)

RunService.RenderStepped:Connect(updateESP)

-- ================== NOCLIP ==================
local function updateNoclip()
    if noclipConn then noclipConn:Disconnect() end
    noclipConn = RunService.Stepped:Connect(function()
        if noclipEnabled and LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
end

-- ================== GOD MODE ==================
local function updateGodMode()
    if godModeConn then godModeConn:Disconnect() end
    godModeConn = RunService.Heartbeat:Connect(function()
        if godModeEnabled and LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health < hum.MaxHealth then
                hum.Health = hum.MaxHealth
            end
        end
    end)
end

-- ================== SPEED ==================
local function setSpeed(enabled)
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = enabled and boostSpeed or defaultSpeed
    end
end

-- ================== INFINITY JUMP ==================
local function updateInfJump()
    if infJumpConn then infJumpConn:Disconnect() end
    infJumpConn = UserInputService.JumpRequest:Connect(function()
        if infJumpEnabled then
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end
    end)
end

-- ================== CROSSHAIR ==================
local function createCrosshair()
    if crosshairObject then pcall(function() crosshairObject:Destroy() end) end
    local gui = Instance.new("ScreenGui")
    gui.Name = "AincradCrosshair"
    gui.Parent = game.CoreGui
    gui.ResetOnSpawn = false
    local outer = Instance.new("Frame")
    outer.Parent = gui
    outer.Size = UDim2.new(0, 20, 0, 20)
    outer.Position = UDim2.new(0.5, -10, 0.5, -10)
    outer.BackgroundTransparency = 1
    outer.BorderSizePixel = 2
    outer.BorderColor3 = themeColor
    local outerCorner = Instance.new("UICorner")
    outerCorner.Parent = outer
    outerCorner.CornerRadius = UDim.new(1, 0)
    local dot = Instance.new("Frame")
    dot.Parent = gui
    dot.Size = UDim2.new(0, 4, 0, 4)
    dot.Position = UDim2.new(0.5, -2, 0.5, -2)
    dot.BackgroundColor3 = themeColor
    dot.BorderSizePixel = 0
    local dotCorner = Instance.new("UICorner")
    dotCorner.Parent = dot
    dotCorner.CornerRadius = UDim.new(1, 0)
    crosshairObject = gui
end

local function removeCrosshair()
    if crosshairObject then pcall(function() crosshairObject:Destroy() end) end
end

-- ================== ENEMY COUNTER ==================
local function createEnemyCounter()
    if enemyCounterText then pcall(function() enemyCounterText:Remove() end) end
    local success, err = pcall(function()
        enemyCounterText = Drawing.new("Text")
        enemyCounterText.Size = 22
        enemyCounterText.Color = themeColor
        enemyCounterText.Center = true
        enemyCounterText.Outline = true
        enemyCounterText.OutlineColor = Color3.fromRGB(0, 0, 0)
        enemyCounterText.Position = Vector2.new(Camera.ViewportSize.X / 2, 35)
        enemyCounterText.Visible = true
        enemyCounterText.Text = "⚔️ ENEMIES: 0 ⚔️"
    end)
    if not success then
        enemyCounterText = nil
    end
end

local function updateEnemyCounter()
    if not enemyCounterText then return end
    local count = 0
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Head") then
                count = count + 1
            end
        end
    end
    pcall(function()
        enemyCounterText.Text = "⚔️ ENEMIES: " .. count .. " ⚔️"
        enemyCounterText.Position = Vector2.new(Camera.ViewportSize.X / 2, 35)
    end)
end

-- ================== PLAYER LIST (REFRESH OTOMATIS) ==================
local function refreshPlayerList(scrollingFrame, layout)
    for _, child in pairs(scrollingFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local btn = Instance.new("TextButton")
            btn.Parent = scrollingFrame
            btn.Size = UDim2.new(0.95, 0, 0, 42)
            btn.BackgroundColor3 = Color3.fromRGB(30, 35, 50)
            btn.Text = "⚡ " .. player.Name .. " ⚡"
            btn.TextColor3 = themeColor
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 14
            local btnCorner = Instance.new("UICorner")
            btnCorner.Parent = btn
            btnCorner.CornerRadius = UDim.new(0, 10)
            
            btn.MouseButton1Click:Connect(function()
                teleportToPlayer(player)
            end)
        end
    end
end

-- ================== GUI KEY (NEW UI) ==================
local KeyGui = Instance.new("ScreenGui")
KeyGui.Name = "AincradKey"
KeyGui.Parent = game.CoreGui

local KeyFrame = Instance.new("Frame")
KeyFrame.Parent = KeyGui
KeyFrame.Size = UDim2.new(0, 400, 0, 420)
KeyFrame.Position = UDim2.new(0.5, -200, 0.5, -210)
KeyFrame.BackgroundColor3 = darkBg
KeyFrame.BackgroundTransparency = 0.05
KeyFrame.BorderSizePixel = 0
KeyFrame.Active = true
KeyFrame.Draggable = true

local KeyCorner = Instance.new("UICorner")
KeyCorner.Parent = KeyFrame
KeyCorner.CornerRadius = UDim.new(0, 24)

local KeyBorder = Instance.new("Frame")
KeyBorder.Parent = KeyFrame
KeyBorder.Size = UDim2.new(1, 0, 1, 0)
KeyBorder.BackgroundTransparency = 1
KeyBorder.BorderSizePixel = 2
KeyBorder.BorderColor3 = themeColor
local KeyBorderCorner = Instance.new("UICorner")
KeyBorderCorner.Parent = KeyBorder
KeyBorderCorner.CornerRadius = UDim.new(0, 24)

local KeyHeader = Instance.new("Frame")
KeyHeader.Parent = KeyFrame
KeyHeader.Size = UDim2.new(1, 0, 0, 90)
KeyHeader.BackgroundTransparency = 1

local KeyIcon = Instance.new("TextLabel")
KeyIcon.Parent = KeyHeader
KeyIcon.Size = UDim2.new(1, 0, 0.5, 0)
KeyIcon.Position = UDim2.new(0, 0, 0, 15)
KeyIcon.BackgroundTransparency = 1
KeyIcon.Text = "⚔️"
KeyIcon.TextColor3 = themeColor
KeyIcon.Font = Enum.Font.GothamBlack
KeyIcon.TextSize = 55

local KeyTitle = Instance.new("TextLabel")
KeyTitle.Parent = KeyHeader
KeyTitle.Size = UDim2.new(1, 0, 0.4, 0)
KeyTitle.Position = UDim2.new(0, 0, 0, 60)
KeyTitle.BackgroundTransparency = 1
KeyTitle.Text = "AINCRAD SYSTEM"
KeyTitle.TextColor3 = themeColor
KeyTitle.Font = Enum.Font.GothamBlack
KeyTitle.TextSize = 20
KeyTitle.TextStrokeTransparency = 0

local InfoFrame = Instance.new("Frame")
InfoFrame.Parent = KeyFrame
InfoFrame.Size = UDim2.new(0.9, 0, 0, 70)
InfoFrame.Position = UDim2.new(0.05, 0, 0.24, 0)
InfoFrame.BackgroundColor3 = grayBg
InfoFrame.BackgroundTransparency = 0.3
InfoFrame.BorderSizePixel = 0

local InfoCorner = Instance.new("UICorner")
InfoCorner.Parent = InfoFrame
InfoCorner.CornerRadius = UDim.new(0, 14)

local InfoText = Instance.new("TextLabel")
InfoText.Parent = InfoFrame
InfoText.Size = UDim2.new(1, -20, 1, -10)
InfoText.Position = UDim2.new(0, 10, 0, 5)
InfoText.BackgroundTransparency = 1
InfoText.Text = "Masukkan Key Akses\n\n1 JAM | 1 HARI"
InfoText.TextColor3 = Color3.fromRGB(180, 190, 220)
InfoText.Font = Enum.Font.Gotham
InfoText.TextSize = 13
InfoText.TextXAlignment = Enum.TextXAlignment.Left
InfoText.TextWrapped = true

local KeyLabel = Instance.new("TextLabel")
KeyLabel.Parent = KeyFrame
KeyLabel.Size = UDim2.new(0.8, 0, 0, 20)
KeyLabel.Position = UDim2.new(0.1, 0, 0.4, 0)
KeyLabel.BackgroundTransparency = 1
KeyLabel.Text = "INPUT KEY"
KeyLabel.TextColor3 = themeColor
KeyLabel.Font = Enum.Font.GothamBold
KeyLabel.TextSize = 12
KeyLabel.TextXAlignment = Enum.TextXAlignment.Left

local KeyTextBox = Instance.new("TextBox")
KeyTextBox.Parent = KeyFrame
KeyTextBox.Size = UDim2.new(0.8, 0, 0, 45)
KeyTextBox.Position = UDim2.new(0.1, 0, 0.44, 0)
KeyTextBox.BackgroundColor3 = grayBg
KeyTextBox.BackgroundTransparency = 0.1
KeyTextBox.TextColor3 = Color3.new(1, 1, 1)
KeyTextBox.PlaceholderText = "Masukkan Key..."
KeyTextBox.PlaceholderColor3 = Color3.fromRGB(120, 130, 160)
KeyTextBox.Font = Enum.Font.Gotham
KeyTextBox.TextSize = 14
KeyTextBox.ClearTextOnFocus = true
local KeyBoxCorner = Instance.new("UICorner")
KeyBoxCorner.Parent = KeyTextBox
KeyBoxCorner.CornerRadius = UDim.new(0, 12)

local VerifyBtn = Instance.new("TextButton")
VerifyBtn.Parent = KeyFrame
VerifyBtn.Size = UDim2.new(0.8, 0, 0, 45)
VerifyBtn.Position = UDim2.new(0.1, 0, 0.56, 0)
VerifyBtn.BackgroundColor3 = themeColor
VerifyBtn.BackgroundTransparency = 0.2
VerifyBtn.Text = "VERIFIKASI"
VerifyBtn.TextColor3 = Color3.new(1, 1, 1)
VerifyBtn.Font = Enum.Font.GothamBold
VerifyBtn.TextSize = 16
local VerifyCorner = Instance.new("UICorner")
VerifyCorner.Parent = VerifyBtn
VerifyCorner.CornerRadius = UDim.new(0, 12)

local GetKeyBtn = Instance.new("TextButton")
GetKeyBtn.Parent = KeyFrame
GetKeyBtn.Size = UDim2.new(0.5, 0, 0, 35)
GetKeyBtn.Position = UDim2.new(0.25, 0, 0.68, 0)
GetKeyBtn.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
GetKeyBtn.BackgroundTransparency = 0.2
GetKeyBtn.Text = "GET KEY"
GetKeyBtn.TextColor3 = Color3.new(1, 1, 1)
GetKeyBtn.Font = Enum.Font.GothamBold
GetKeyBtn.TextSize = 14
local GetKeyCorner = Instance.new("UICorner")
GetKeyCorner.Parent = GetKeyBtn
GetKeyCorner.CornerRadius = UDim.new(0, 10)

local StatusFrame = Instance.new("Frame")
StatusFrame.Parent = KeyFrame
StatusFrame.Size = UDim2.new(0.9, 0, 0, 40)
StatusFrame.Position = UDim2.new(0.05, 0, 0.77, 0)
StatusFrame.BackgroundColor3 = grayBg
StatusFrame.BackgroundTransparency = 0.3
StatusFrame.BorderSizePixel = 0
local StatusCorner = Instance.new("UICorner")
StatusCorner.Parent = StatusFrame
StatusCorner.CornerRadius = UDim.new(0, 10)

local StatusIcon = Instance.new("TextLabel")
StatusIcon.Parent = StatusFrame
StatusIcon.Size = UDim2.new(0, 30, 1, 0)
StatusIcon.Position = UDim2.new(0, 5, 0, 0)
StatusIcon.BackgroundTransparency = 1
StatusIcon.Text = "🔒"
StatusIcon.TextColor3 = Color3.fromRGB(255, 255, 0)
StatusIcon.Font = Enum.Font.GothamBold
StatusIcon.TextSize = 18

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Parent = StatusFrame
StatusLabel.Size = UDim2.new(1, -40, 1, 0)
StatusLabel.Position = UDim2.new(0, 35, 0, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Waiting for key..."
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 12
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left

local LoadingCircle = Instance.new("Frame")
LoadingCircle.Parent = KeyFrame
LoadingCircle.Size = UDim2.new(0, 30, 0, 30)
LoadingCircle.Position = UDim2.new(0.5, -15, 0.9, -15)
LoadingCircle.BackgroundColor3 = themeColor
LoadingCircle.BackgroundTransparency = 1
LoadingCircle.Visible = false
local CircleCorner = Instance.new("UICorner")
CircleCorner.Parent = LoadingCircle
CircleCorner.CornerRadius = UDim.new(1, 0)

local function showLoading(show)
    LoadingCircle.Visible = show
    if show then
        task.spawn(function()
            local r = 0
            while LoadingCircle and LoadingCircle.Visible do
                r = (r + 5) % 360
                LoadingCircle.Rotation = r
                task.wait(0.01)
            end
        end)
    end
end

GetKeyBtn.MouseButton1Click:Connect(function()
    pcall(function()
        if setclipboard then
            setclipboard(WEB_URL)
            StatusLabel.Text = "✓ Link copied!"
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            StatusIcon.Text = "✅"
            task.wait(2)
            StatusLabel.Text = "Waiting for key..."
            StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            StatusIcon.Text = "🔒"
        end
    end)
end)

VerifyBtn.MouseButton1Click:Connect(function()
    local key = KeyTextBox.Text:gsub("%s+", "")
    if key == "" then
        StatusLabel.Text = "Enter your key!"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        StatusIcon.Text = "❌"
        return
    end
    showLoading(true)
    StatusLabel.Text = "Verifying..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    StatusIcon.Text = "⏳"
    VerifyBtn.Text = "⏳ VERIFYING..."
    local valid, message = cekKey(key)
    showLoading(false)
    VerifyBtn.Text = "VERIFY KEY"
    if valid then
        StatusLabel.Text = "✓ " .. message
        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        StatusIcon.Text = "✅"
        TweenService:Create(KeyFrame, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 80, 80)}):Play()
        task.wait(0.3)
        for i = 3, 1, -1 do
            StatusLabel.Text = "Loading " .. i .. "..."
            task.wait(1)
        end
        KeyGui:Destroy()
        
        pcall(initESP)
        pcall(createEnemyCounter)
        
        local notif = Instance.new("ScreenGui")
        notif.Parent = game.CoreGui
        local nf = Instance.new("Frame")
        nf.Parent = notif
        nf.Size = UDim2.new(0, 300, 0, 50)
        nf.Position = UDim2.new(0.5, -150, 0.5, -25)
        nf.BackgroundColor3 = Color3.fromRGB(0, 150, 150)
        nf.BackgroundTransparency = 0.1
        local nc = Instance.new("UICorner")
        nc.Parent = nf
        nc.CornerRadius = UDim.new(0, 12)
        local nt = Instance.new("TextLabel")
        nt.Parent = nf
        nt.Size = UDim2.new(1, 0, 1, 0)
        nt.BackgroundTransparency = 1
        nt.Text = "⚔️ AINCRAD ACTIVATED ⚔️"
        nt.TextColor3 = themeColor
        nt.Font = Enum.Font.GothamBlack
        nt.TextSize = 18
        task.wait(2)
        notif:Destroy()
        
        -- ================== MENU UTAMA (NEW UI) ==================
        local MenuGui = Instance.new("ScreenGui")
        MenuGui.Name = "AincradMenu"
        MenuGui.Parent = game.CoreGui
        
        local MainFrame = Instance.new("Frame")
        MainFrame.Parent = MenuGui
        MainFrame.Size = UDim2.new(0, 440, 0, 580)
        MainFrame.Position = UDim2.new(0.5, -220, 0.5, -290)
        MainFrame.BackgroundColor3 = darkBg
        MainFrame.BackgroundTransparency = 0.05
        MainFrame.BorderSizePixel = 0
        MainFrame.Active = true
        MainFrame.Draggable = true
        MainFrame.Visible = true
        
        local MainCorner = Instance.new("UICorner")
        MainCorner.Parent = MainFrame
        MainCorner.CornerRadius = UDim.new(0, 24)
        
        local Border = Instance.new("Frame")
        Border.Parent = MainFrame
        Border.Size = UDim2.new(1, 0, 1, 0)
        Border.BackgroundTransparency = 1
        Border.BorderSizePixel = 2
        Border.BorderColor3 = themeColor
        local BorderCorner = Instance.new("UICorner")
        BorderCorner.Parent = Border
        BorderCorner.CornerRadius = UDim.new(0, 24)
        
        local Header = Instance.new("Frame")
        Header.Parent = MainFrame
        Header.Size = UDim2.new(1, 0, 0, 70)
        Header.Position = UDim2.new(0, 0, 0, 0)
        Header.BackgroundColor3 = themeColor
        Header.BackgroundTransparency = 0.1
        Header.BorderSizePixel = 0
        local HeaderCorner = Instance.new("UICorner")
        HeaderCorner.Parent = Header
        HeaderCorner.CornerRadius = UDim.new(0, 24)
        
        local Title = Instance.new("TextLabel")
        Title.Parent = Header
        Title.Size = UDim2.new(1, 0, 1, 0)
        Title.BackgroundTransparency = 1
        Title.Text = "⚔️ AINCRAD ⚔️"
        Title.TextColor3 = Color3.fromRGB(255, 255, 255)
        Title.Font = Enum.Font.GothamBlack
        Title.TextSize = 24
        
        local Subtitle = Instance.new("TextLabel")
        Subtitle.Parent = Header
        Subtitle.Size = UDim2.new(1, 0, 0, 20)
        Subtitle.Position = UDim2.new(0, 0, 0, 45)
        Subtitle.BackgroundTransparency = 1
        Subtitle.Text = "NEXT-GEN CHEAT SYSTEM"
        Subtitle.TextColor3 = Color3.fromRGB(200, 200, 255)
        Subtitle.Font = Enum.Font.Gotham
        Subtitle.TextSize = 10
        
        local minimizeBtn = Instance.new("ImageButton")
        minimizeBtn.Parent = Header
        minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
        minimizeBtn.Position = UDim2.new(1, -38, 0, 20)
        minimizeBtn.BackgroundTransparency = 1
        minimizeBtn.Image = "rbxassetid://72495850369898"
        minimizeBtn.ImageColor3 = Color3.fromRGB(255, 255, 255)
        minimizeBtn.ZIndex = 10
        
        local minimized = false
        minimizeBtn.MouseButton1Click:Connect(function()
            minimized = not minimized
            MainFrame.Visible = not minimized
            if minimized then
                MainFrame.Size = UDim2.new(0, 440, 0, 70)
            else
                MainFrame.Size = UDim2.new(0, 440, 0, 580)
            end
        end)
        
        -- Tab Bar
        local TabBar = Instance.new("Frame")
        TabBar.Parent = MainFrame
        TabBar.Size = UDim2.new(0.96, 0, 0, 42)
        TabBar.Position = UDim2.new(0.02, 0, 0.13, 0)
        TabBar.BackgroundColor3 = grayBg
        TabBar.BackgroundTransparency = 0.3
        TabBar.BorderSizePixel = 0
        local TabBarCorner = Instance.new("UICorner")
        TabBarCorner.Parent = TabBar
        TabBarCorner.CornerRadius = UDim.new(0, 12)
        
        local tabMain = Instance.new("TextButton")
        tabMain.Parent = TabBar
        tabMain.Size = UDim2.new(0.25, -2, 1, -4)
        tabMain.Position = UDim2.new(0, 2, 0, 2)
        tabMain.BackgroundColor3 = themeColor
        tabMain.BackgroundTransparency = 0.3
        tabMain.Text = "MAIN"
        tabMain.TextColor3 = Color3.fromRGB(255, 255, 255)
        tabMain.Font = Enum.Font.GothamBold
        tabMain.TextSize = 12
        local tabMainCorner = Instance.new("UICorner")
        tabMainCorner.Parent = tabMain
        tabMainCorner.CornerRadius = UDim.new(0, 8)
        
        local tabESP = Instance.new("TextButton")
        tabESP.Parent = TabBar
        tabESP.Size = UDim2.new(0.25, -2, 1, -4)
        tabESP.Position = UDim2.new(0.25, 2, 0, 2)
        tabESP.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
        tabESP.BackgroundTransparency = 0.5
        tabESP.Text = "ESP"
        tabESP.TextColor3 = Color3.fromRGB(180, 190, 220)
        tabESP.Font = Enum.Font.GothamBold
        tabESP.TextSize = 12
        local tabESPCorner = Instance.new("UICorner")
        tabESPCorner.Parent = tabESP
        tabESPCorner.CornerRadius = UDim.new(0, 8)
        
        local tabPlayers = Instance.new("TextButton")
        tabPlayers.Parent = TabBar
        tabPlayers.Size = UDim2.new(0.25, -2, 1, -4)
        tabPlayers.Position = UDim2.new(0.5, 2, 0, 2)
        tabPlayers.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
        tabPlayers.BackgroundTransparency = 0.5
        tabPlayers.Text = "PLAYERS"
        tabPlayers.TextColor3 = Color3.fromRGB(180, 190, 220)
        tabPlayers.Font = Enum.Font.GothamBold
        tabPlayers.TextSize = 12
        local tabPlayersCorner = Instance.new("UICorner")
        tabPlayersCorner.Parent = tabPlayers
        tabPlayersCorner.CornerRadius = UDim.new(0, 8)
        
        local tabInfo = Instance.new("TextButton")
        tabInfo.Parent = TabBar
        tabInfo.Size = UDim2.new(0.25, -2, 1, -4)
        tabInfo.Position = UDim2.new(0.75, 2, 0, 2)
        tabInfo.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
        tabInfo.BackgroundTransparency = 0.5
        tabInfo.Text = "INFO"
        tabInfo.TextColor3 = Color3.fromRGB(180, 190, 220)
        tabInfo.Font = Enum.Font.GothamBold
        tabInfo.TextSize = 12
        local tabInfoCorner = Instance.new("UICorner")
        tabInfoCorner.Parent = tabInfo
        tabInfoCorner.CornerRadius = UDim.new(0, 8)
        
        -- Content panels
        local contentMain = Instance.new("ScrollingFrame")
        contentMain.Parent = MainFrame
        contentMain.Size = UDim2.new(0.94, 0, 0.72, 0)
        contentMain.Position = UDim2.new(0.03, 0, 0.2, 0)
        contentMain.BackgroundColor3 = grayBg
        contentMain.BackgroundTransparency = 0.4
        contentMain.BorderSizePixel = 0
        contentMain.ScrollBarThickness = 5
        contentMain.ScrollBarImageColor3 = themeColor
        contentMain.CanvasSize = UDim2.new(0, 0, 0, 0)
        contentMain.AutomaticCanvasSize = Enum.AutomaticSize.Y
        local contentMainCorner = Instance.new("UICorner")
        contentMainCorner.Parent = contentMain
        contentMainCorner.CornerRadius = UDim.new(0, 12)
        local layoutMain = Instance.new("UIListLayout")
        layoutMain.Parent = contentMain
        layoutMain.Padding = UDim.new(0, 10)
        layoutMain.HorizontalAlignment = Enum.HorizontalAlignment.Center
        
        local contentESP = Instance.new("ScrollingFrame")
        contentESP.Parent = MainFrame
        contentESP.Size = UDim2.new(0.94, 0, 0.72, 0)
        contentESP.Position = UDim2.new(0.03, 0, 0.2, 0)
        contentESP.BackgroundColor3 = grayBg
        contentESP.BackgroundTransparency = 0.4
        contentESP.BorderSizePixel = 0
        contentESP.ScrollBarThickness = 5
        contentESP.ScrollBarImageColor3 = themeColor
        contentESP.CanvasSize = UDim2.new(0, 0, 0, 0)
        contentESP.AutomaticCanvasSize = Enum.AutomaticSize.Y
        contentESP.Visible = false
        local contentESPCorner = Instance.new("UICorner")
        contentESPCorner.Parent = contentESP
        contentESPCorner.CornerRadius = UDim.new(0, 12)
        local layoutESP = Instance.new("UIListLayout")
        layoutESP.Parent = contentESP
        layoutESP.Padding = UDim.new(0, 10)
        layoutESP.HorizontalAlignment = Enum.HorizontalAlignment.Center
        
        local contentPlayers = Instance.new("ScrollingFrame")
        contentPlayers.Parent = MainFrame
        contentPlayers.Size = UDim2.new(0.94, 0, 0.72, 0)
        contentPlayers.Position = UDim2.new(0.03, 0, 0.2, 0)
        contentPlayers.BackgroundColor3 = grayBg
        contentPlayers.BackgroundTransparency = 0.4
        contentPlayers.BorderSizePixel = 0
        contentPlayers.ScrollBarThickness = 5
        contentPlayers.ScrollBarImageColor3 = themeColor
        contentPlayers.CanvasSize = UDim2.new(0, 0, 0, 0)
        contentPlayers.AutomaticCanvasSize = Enum.AutomaticSize.Y
        contentPlayers.Visible = false
        local contentPlayersCorner = Instance.new("UICorner")
        contentPlayersCorner.Parent = contentPlayers
        contentPlayersCorner.CornerRadius = UDim.new(0, 12)
        local layoutPlayers = Instance.new("UIListLayout")
        layoutPlayers.Parent = contentPlayers
        layoutPlayers.Padding = UDim.new(0, 8)
        layoutPlayers.HorizontalAlignment = Enum.HorizontalAlignment.Center
        
        local contentInfo = Instance.new("ScrollingFrame")
        contentInfo.Parent = MainFrame
        contentInfo.Size = UDim2.new(0.94, 0, 0.72, 0)
        contentInfo.Position = UDim2.new(0.03, 0, 0.2, 0)
        contentInfo.BackgroundColor3 = grayBg
        contentInfo.BackgroundTransparency = 0.4
        contentInfo.BorderSizePixel = 0
        contentInfo.ScrollBarThickness = 5
        contentInfo.ScrollBarImageColor3 = themeColor
        contentInfo.CanvasSize = UDim2.new(0, 0, 0, 0)
        contentInfo.AutomaticCanvasSize = Enum.AutomaticSize.Y
        contentInfo.Visible = false
        local contentInfoCorner = Instance.new("UICorner")
        contentInfoCorner.Parent = contentInfo
        contentInfoCorner.CornerRadius = UDim.new(0, 12)
        local layoutInfo = Instance.new("UIListLayout")
        layoutInfo.Parent = contentInfo
        layoutInfo.Padding = UDim.new(0, 10)
        layoutInfo.HorizontalAlignment = Enum.HorizontalAlignment.Center
        
        -- Tab switching
        tabMain.MouseButton1Click:Connect(function()
            tabMain.BackgroundColor3 = themeColor
            tabMain.BackgroundTransparency = 0.3
            tabMain.TextColor3 = Color3.fromRGB(255, 255, 255)
            tabESP.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
            tabESP.BackgroundTransparency = 0.5
            tabESP.TextColor3 = Color3.fromRGB(180, 190, 220)
            tabPlayers.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
            tabPlayers.BackgroundTransparency = 0.5
            tabPlayers.TextColor3 = Color3.fromRGB(180, 190, 220)
            tabInfo.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
            tabInfo.BackgroundTransparency = 0.5
            tabInfo.TextColor3 = Color3.fromRGB(180, 190, 220)
            contentMain.Visible = true
            contentESP.Visible = false
            contentPlayers.Visible = false
            contentInfo.Visible = false
        end)
        tabESP.MouseButton1Click:Connect(function()
            tabESP.BackgroundColor3 = themeColor
            tabESP.BackgroundTransparency = 0.3
            tabESP.TextColor3 = Color3.fromRGB(255, 255, 255)
            tabMain.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
            tabMain.BackgroundTransparency = 0.5
            tabMain.TextColor3 = Color3.fromRGB(180, 190, 220)
            tabPlayers.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
            tabPlayers.BackgroundTransparency = 0.5
            tabPlayers.TextColor3 = Color3.fromRGB(180, 190, 220)
            tabInfo.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
            tabInfo.BackgroundTransparency = 0.5
            tabInfo.TextColor3 = Color3.fromRGB(180, 190, 220)
            contentMain.Visible = false
            contentESP.Visible = true
            contentPlayers.Visible = false
            contentInfo.Visible = false
        end)
        tabPlayers.MouseButton1Click:Connect(function()
            tabPlayers.BackgroundColor3 = themeColor
            tabPlayers.BackgroundTransparency = 0.3
            tabPlayers.TextColor3 = Color3.fromRGB(255, 255, 255)
            tabMain.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
            tabMain.BackgroundTransparency = 0.5
            tabMain.TextColor3 = Color3.fromRGB(180, 190, 220)
            tabESP.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
            tabESP.BackgroundTransparency = 0.5
            tabESP.TextColor3 = Color3.fromRGB(180, 190, 220)
            tabInfo.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
            tabInfo.BackgroundTransparency = 0.5
            tabInfo.TextColor3 = Color3.fromRGB(180, 190, 220)
            contentMain.Visible = false
            contentESP.Visible = false
            contentPlayers.Visible = true
            contentInfo.Visible = false
            refreshPlayerList(contentPlayers, layoutPlayers)
        end)
        tabInfo.MouseButton1Click:Connect(function()
            tabInfo.BackgroundColor3 = themeColor
            tabInfo.BackgroundTransparency = 0.3
            tabInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
            tabMain.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
            tabMain.BackgroundTransparency = 0.5
            tabMain.TextColor3 = Color3.fromRGB(180, 190, 220)
            tabESP.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
            tabESP.BackgroundTransparency = 0.5
            tabESP.TextColor3 = Color3.fromRGB(180, 190, 220)
            tabPlayers.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
            tabPlayers.BackgroundTransparency = 0.5
            tabPlayers.TextColor3 = Color3.fromRGB(180, 190, 220)
            contentMain.Visible = false
            contentESP.Visible = false
            contentPlayers.Visible = false
            contentInfo.Visible = true
        end)
        
        -- ================== FUNGSI TOGGLE ==================
        local function createToggle(parent, text, defaultColor, callback, defaultState)
            local frame = Instance.new("Frame")
            frame.Parent = parent
            frame.Size = UDim2.new(0.95, 0, 0, 48)
            frame.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
            frame.BackgroundTransparency = 0.2
            frame.BorderSizePixel = 0
            local fc = Instance.new("UICorner")
            fc.Parent = frame
            fc.CornerRadius = UDim.new(0, 10)
            
            local lbl = Instance.new("TextLabel")
            lbl.Parent = frame
            lbl.Size = UDim2.new(0.65, 0, 1, 0)
            lbl.Position = UDim2.new(0.05, 0, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = text
            lbl.TextColor3 = Color3.fromRGB(220, 230, 255)
            lbl.Font = Enum.Font.GothamBold
            lbl.TextSize = 13
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            
            local sw = Instance.new("Frame")
            sw.Parent = frame
            sw.Size = UDim2.new(0, 50, 0, 26)
            sw.Position = UDim2.new(0.8, 0, 0.5, -13)
            sw.BackgroundColor3 = defaultState and defaultColor or Color3.fromRGB(60, 65, 80)
            sw.BorderSizePixel = 0
            local swc = Instance.new("UICorner")
            swc.Parent = sw
            swc.CornerRadius = UDim.new(0, 13)
            
            local circle = Instance.new("Frame")
            circle.Parent = sw
            circle.Size = UDim2.new(0, 22, 0, 22)
            circle.Position = defaultState and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0.05, 0, 0.5, -11)
            circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            circle.BorderSizePixel = 0
            local circ = Instance.new("UICorner")
            circ.Parent = circle
            circ.CornerRadius = UDim.new(1, 0)
            
            local state = defaultState
            local btn = Instance.new("TextButton")
            btn.Parent = frame
            btn.Size = UDim2.new(1, 0, 1, 0)
            btn.BackgroundTransparency = 1
            btn.Text = ""
            btn.MouseButton1Click:Connect(function()
                state = not state
                TweenService:Create(sw, TweenInfo.new(0.15), {BackgroundColor3 = state and defaultColor or Color3.fromRGB(60, 65, 80)}):Play()
                TweenService:Create(circle, TweenInfo.new(0.15), {Position = state and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0.05, 0, 0.5, -11)}):Play()
                callback(state)
            end)
        end
        
        -- MAIN tab
        createToggle(contentMain, "NOCLIP", themeColor, function(s) noclipEnabled = s; if s then updateNoclip() end end, false)
        createToggle(contentMain, "GOD MODE", themeColor, function(s) godModeEnabled = s; if s then updateGodMode() elseif godModeConn then godModeConn:Disconnect() end end, false)
        createToggle(contentMain, "SPEED 70", themeColor, function(s) speedEnabled = s; setSpeed(s) end, false)
        createToggle(contentMain, "INFINITY JUMP", themeColor, function(s) infJumpEnabled = s; if s then updateInfJump() elseif infJumpConn then infJumpConn:Disconnect() end end, false)
        createToggle(contentMain, "CROSSHAIR", themeColor, function(s) crosshairEnabled = s; if s then createCrosshair() else removeCrosshair() end end, false)
        
        -- ESP tab
        createToggle(contentESP, "ESP LINE", putih, function(s) espLineEnabled = s; if not s then for _, v in pairs(espLines) do v[1].Visible = false end end end, false)
        createToggle(contentESP, "ESP BOX + HEALTH", themeColor, function(s) espBoxEnabled = s; if not s then 
            for _, v in pairs(espBoxes) do v[1].Visible = false end
            for _, v in pairs(espNames) do v[1].Visible = false end
            for _, v in pairs(espHealthBars) do v[1].Visible = false end
        end end, false)
        createToggle(contentESP, "HOLOGRAM", merah, function(s) hologramEnabled = s; if s then applyHologramToAll() else removeHologramFromAll() end end, false)
        
        -- ================== TAB INFO ==================
        local timerLabel = Instance.new("TextLabel")
        timerLabel.Parent = contentInfo
        timerLabel.Size = UDim2.new(0.95, 0, 0, 45)
        timerLabel.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
        timerLabel.BackgroundTransparency = 0.2
        timerLabel.Text = "Memuat sisa waktu..."
        timerLabel.TextColor3 = themeColor
        timerLabel.Font = Enum.Font.GothamBold
        timerLabel.TextSize = 14
        timerLabel.TextWrapped = true
        local timerCorner = Instance.new("UICorner")
        timerCorner.Parent = timerLabel
        timerCorner.CornerRadius = UDim.new(0, 10)
        
        local infoTextLabel = Instance.new("TextLabel")
        infoTextLabel.Parent = contentInfo
        infoTextLabel.Size = UDim2.new(0.95, 0, 0, 110)
        infoTextLabel.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
        infoTextLabel.BackgroundTransparency = 0.2
        infoTextLabel.Text = "AINCRAD SYSTEM\n\nDeveloper: Putzzdev\nTikTok: @putzz_mvpp\nWhatsApp: 088976255131"
        infoTextLabel.TextColor3 = Color3.fromRGB(220, 230, 255)
        infoTextLabel.Font = Enum.Font.Gotham
        infoTextLabel.TextSize = 13
        infoTextLabel.TextWrapped = true
        infoTextLabel.TextYAlignment = Enum.TextYAlignment.Center
        local infoCorner2 = Instance.new("UICorner")
        infoCorner2.Parent = infoTextLabel
        infoCorner2.CornerRadius = UDim.new(0, 10)
        
        local function updateKeyTimer()
            if not keyValid then timerLabel.Text = "Key tidak valid" return end
            local remaining = keyExpiryTime - os.time()
            if remaining <= 0 and keyExpiryTime ~= math.huge then timerLabel.Text = "KEY EXPIRED!" return end
            if keyExpiryTime == math.huge then timerLabel.Text = "Sisa waktu: PERMANEN" return end
            local hours = math.floor(remaining / 3600)
            local minutes = math.floor((remaining % 3600) / 60)
            local seconds = remaining % 60
            if keyType == "1 JAM" then
                timerLabel.Text = string.format("Sisa waktu: %02d:%02d:%02d (1 Jam)", hours, minutes, seconds)
            elseif keyType == "1 HARI" then
                local days = math.floor(remaining / 86400)
                hours = math.floor((remaining % 86400) / 3600)
                timerLabel.Text = string.format("Sisa waktu: %d hari %02d jam %02d menit", days, hours, minutes)
            else
                timerLabel.Text = "Sisa waktu: PERMANEN"
            end
        end
        
        task.spawn(function()
            while keyValid and MainFrame and MainFrame.Parent do
                updateKeyTimer()
                task.wait(1)
            end
        end)
        updateKeyTimer()
        
        -- Refresh player list
        Players.PlayerAdded:Connect(function()
            if contentPlayers.Visible then
                refreshPlayerList(contentPlayers, layoutPlayers)
            end
        end)
        Players.PlayerRemoving:Connect(function()
            if contentPlayers.Visible then
                refreshPlayerList(contentPlayers, layoutPlayers)
            end
        end)
        
        -- ================== FLOATING MENU BUTTON ==================
        local menuBtn = Instance.new("ImageButton")
        menuBtn.Parent = MenuGui
        menuBtn.Size = UDim2.new(0, 55, 0, 55)
        menuBtn.Position = UDim2.new(0, 10, 0.5, -27)
        menuBtn.BackgroundTransparency = 1
        menuBtn.Image = "rbxassetid://72495850369898"
        menuBtn.ImageColor3 = themeColor
        menuBtn.ZIndex = 10
        
        local dragging = false
        local dragStart = nil
        local startPos = nil
        
        menuBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = menuBtn.Position
            end
        end)
        
        menuBtn.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        
        menuBtn.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                local newX = startPos.X.Offset + delta.X
                local newY = startPos.Y.Offset + delta.Y
                newX = math.clamp(newX, 0, Camera.ViewportSize.X - 55)
                newY = math.clamp(newY, 0, Camera.ViewportSize.Y - 55)
                menuBtn.Position = UDim2.new(0, newX, 0, newY)
            end
        end)
        
        local menuVisible = true
        menuBtn.MouseButton1Click:Connect(function()
            menuVisible = not menuVisible
            MainFrame.Visible = menuVisible
            if menuVisible then
                MainFrame.Size = UDim2.new(0, 440, 0, 580)
                TweenService:Create(MainFrame, TweenInfo.new(0.2), {Position = UDim2.new(0.5, -220, 0.5, -290)}):Play()
            else
                TweenService:Create(MainFrame, TweenInfo.new(0.2), {Position = UDim2.new(0.5, -220, 1, 0)}):Play()
            end
        end)
        
        RunService.RenderStepped:Connect(updateEnemyCounter)
        
    else
        StatusLabel.Text = "✗ " .. message
        StatusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        StatusIcon.Text = "❌"
        for i = 1, 3 do
            TweenService:Create(KeyFrame, TweenInfo.new(0.05), {BackgroundColor3 = Color3.fromRGB(80, 0, 0)}):Play()
            task.wait(0.05)
            TweenService:Create(KeyFrame, TweenInfo.new(0.05), {BackgroundColor3 = darkBg}):Play()
            task.wait(0.05)
        end
        task.wait(1.5)
        StatusLabel.Text = "Waiting for key..."
        StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        StatusIcon.Text = "🔒"
        KeyTextBox.Text = ""
    end
end)