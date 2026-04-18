-- ================== DRIP CLIENT V1.3 ==================
-- Fitur: ESP line putih ke kepala, ESP box hijau tebal 2.2, health bar vertikal,
--        hologram (highlight merah tembus dinding), Noclip, God Mode, Speed 70,
--        Infinity Jump, Crosshair di tengah layar, Timer sisa waktu key di tab INFO,
--        Enemy counter di atas tengah layar (warna merah).
--        Sistem key expired menyimpan data di Firebase (masa berlaku tetap berjalan).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

-- Warna menu ungu
local ungu = Color3.fromRGB(128, 0, 255)
local dark = Color3.fromRGB(8, 8, 12)
local gray = Color3.fromRGB(25, 25, 35)
local hijau = Color3.fromRGB(0, 255, 0)
local putih = Color3.fromRGB(255, 255, 255)
local merah = Color3.fromRGB(255, 80, 80)

local DB_URL = "https://key-database-701af-default-rtdb.asia-southeast1.firebasedatabase.app/keys.json"
local WEB_URL = "https://putzzdevxit.github.io/KEY-GENERATOR-/"

local MAX_DIST = 115

-- Variabel key timer (disimpan per key)
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
local enemyCounterEnabled = true  -- selalu aktif, tidak perlu toggle

-- ================== FUNGSI CEK KEY (dengan penyimpanan waktu) ==================
-- Fungsi ini akan membaca/menyimpan data key ke Firebase
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
    
    -- Cari key di database
    local foundKeyData = nil
    for id, keyData in pairs(jsonData) do
        if keyData.key and string.upper(keyData.key) == string.upper(key) then
            foundKeyData = keyData
            break
        end
    end
    if not foundKeyData then
        return false, "KEY TIDAK TERDAFTAR!"
    end
    
    -- Tentukan masa berlaku (dalam hari)
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
    
    -- Cek apakah key sudah pernah digunakan (simpan firstUsed)
    local firstUsed = foundKeyData.firstUsed
    local currentTime = os.time()
    
    if not firstUsed then
        -- Key baru, simpan firstUsed ke database
        local keyId = nil
        for id, kd in pairs(jsonData) do
            if kd.key == foundKeyData.key then
                keyId = id
                break
            end
        end
        if keyId then
            local updateUrl = DB_URL:gsub(".json$", "/" .. keyId .. ".json")
            local updateData = {
                firstUsed = currentTime,
                expiryDays = expiryDays
            }
            pcall(function()
                game:HttpGet(updateUrl .. "?method=PATCH", true)
                -- Tidak perlu parsing response, kita asumsikan berhasil
            end)
        end
        firstUsed = currentTime
    end
    
    -- Hitung expiry time
    local expiryTime = firstUsed + (expiryDays * 86400)
    if expiryDays >= 999999 then
        expiryTime = math.huge
    end
    
    if currentTime > expiryTime and expiryTime ~= math.huge then
        return false, "KEY SUDAH EXPIRED!"
    end
    
    -- Simpan info ke variabel global
    keyValid = true
    keyExpiryTime = expiryTime
    keyType = jenis
    return true, "KEY VALID! (" .. jenis .. ")"
end

-- ================== HOLOGRAM (Highlight) ==================
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

-- ================== ESP LINE (putih, dari atas ke HEAD) ==================
local function createLine(player)
    if player == LocalPlayer then return end
    local line = Drawing.new("Line")
    line.Thickness = 2
    line.Color = putih
    line.Visible = false
    table.insert(espLines, {line, player})
end

-- ================== ESP BOX (hijau, ketebalan 2.2) ==================
local function createBox(player)
    if player == LocalPlayer then return end
    local box = Drawing.new("Square")
    box.Thickness = 2.2
    box.Color = hijau
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
    
    -- ESP LINE (ke HEAD player)
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
    
    -- ESP BOX (dari kepala ke kaki)
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
    
    -- NAME
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
    
    -- HEALTH BAR (vertikal di samping kanan box)
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

-- ================== SPEED BOOST ==================
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
    gui.Name = "DripCrosshair"
    gui.Parent = game.CoreGui
    gui.ResetOnSpawn = false
    local outer = Instance.new("Frame")
    outer.Parent = gui
    outer.Size = UDim2.new(0, 20, 0, 20)
    outer.Position = UDim2.new(0.5, -10, 0.5, -10)
    outer.BackgroundTransparency = 1
    outer.BorderSizePixel = 2
    outer.BorderColor3 = Color3.fromRGB(255, 255, 255)
    local outerCorner = Instance.new("UICorner")
    outerCorner.Parent = outer
    outerCorner.CornerRadius = UDim.new(1, 0)
    local dot = Instance.new("Frame")
    dot.Parent = gui
    dot.Size = UDim2.new(0, 4, 0, 4)
    dot.Position = UDim2.new(0.5, -2, 0.5, -2)
    dot.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    dot.BorderSizePixel = 0
    local dotCorner = Instance.new("UICorner")
    dotCorner.Parent = dot
    dotCorner.CornerRadius = UDim.new(1, 0)
    crosshairObject = gui
end

local function removeCrosshair()
    if crosshairObject then pcall(function() crosshairObject:Destroy() end) end
end

-- ================== ENEMY COUNTER (di atas tengah layar) ==================
local function createEnemyCounter()
    if enemyCounterText then pcall(function() enemyCounterText:Remove() end) end
    enemyCounterText = Drawing.new("Text")
    enemyCounterText.Size = 20
    enemyCounterText.Color = Color3.fromRGB(255, 0, 0)  -- Merah
    enemyCounterText.Center = true
    enemyCounterText.Outline = true
    enemyCounterText.OutlineColor = Color3.fromRGB(0, 0, 0)
    enemyCounterText.Position = Vector2.new(Camera.ViewportSize.X / 2, 30)
    enemyCounterText.Visible = true
    enemyCounterText.Text = "ENEMY: 0"
end

local function updateEnemyCounter()
    if not enemyCounterText then return end
    local count = 0
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Head") then
                -- Hitung semua player lain yang memiliki karakter lengkap
                count = count + 1
            end
        end
    end
    enemyCounterText.Text = "ENEMY: " .. count
    enemyCounterText.Position = Vector2.new(Camera.ViewportSize.X / 2, 30)
end

-- Update enemy counter setiap frame (atau setiap detik tidak masalah)
RunService.RenderStepped:Connect(function()
    updateEnemyCounter()
end)

-- ================== GUI KEY ==================
local KeyGui = Instance.new("ScreenGui")
KeyGui.Name = "DripClientKey"
KeyGui.Parent = game.CoreGui

local KeyFrame = Instance.new("Frame")
KeyFrame.Parent = KeyGui
KeyFrame.Size = UDim2.new(0, 380, 0, 400)
KeyFrame.Position = UDim2.new(0.5, -190, 0.5, -200)
KeyFrame.BackgroundColor3 = dark
KeyFrame.BackgroundTransparency = 0.1
KeyFrame.BorderSizePixel = 0
KeyFrame.Active = true
KeyFrame.Draggable = true

local KeyCorner = Instance.new("UICorner")
KeyCorner.Parent = KeyFrame
KeyCorner.CornerRadius = UDim.new(0, 20)

local KeyBorder = Instance.new("Frame")
KeyBorder.Parent = KeyFrame
KeyBorder.Size = UDim2.new(1, 0, 1, 0)
KeyBorder.BackgroundTransparency = 1
KeyBorder.BorderSizePixel = 2
KeyBorder.BorderColor3 = ungu
local KeyBorderCorner = Instance.new("UICorner")
KeyBorderCorner.Parent = KeyBorder
KeyBorderCorner.CornerRadius = UDim.new(0, 20)

local KeyIcon = Instance.new("TextLabel")
KeyIcon.Parent = KeyFrame
KeyIcon.Size = UDim2.new(1, 0, 0, 70)
KeyIcon.Position = UDim2.new(0, 0, 0, 15)
KeyIcon.BackgroundTransparency = 1
KeyIcon.Text = "🔐"
KeyIcon.TextColor3 = ungu
KeyIcon.Font = Enum.Font.GothamBlack
KeyIcon.TextSize = 45

local KeyTitle = Instance.new("TextLabel")
KeyTitle.Parent = KeyFrame
KeyTitle.Size = UDim2.new(1, 0, 0, 30)
KeyTitle.Position = UDim2.new(0, 0, 0, 75)
KeyTitle.BackgroundTransparency = 1
KeyTitle.Text = "DRIP CLIENT"
KeyTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyTitle.Font = Enum.Font.GothamBold
KeyTitle.TextSize = 20

local InfoFrame = Instance.new("Frame")
InfoFrame.Parent = KeyFrame
InfoFrame.Size = UDim2.new(0.9, 0, 0, 80)
InfoFrame.Position = UDim2.new(0.05, 0, 0.26, 0)
InfoFrame.BackgroundColor3 = gray
InfoFrame.BackgroundTransparency = 0.3
InfoFrame.BorderSizePixel = 0
local InfoCorner = Instance.new("UICorner")
InfoCorner.Parent = InfoFrame
InfoCorner.CornerRadius = UDim.new(0, 12)

local InfoText = Instance.new("TextLabel")
InfoText.Parent = InfoFrame
InfoText.Size = UDim2.new(1, -20, 1, -10)
InfoText.Position = UDim2.new(0, 10, 0, 5)
InfoText.BackgroundTransparency = 1
InfoText.Text = "Masukkan Key Anda\n\nTIPE KEY: 1 JAM | 1 HARI | PERMANEN"
InfoText.TextColor3 = Color3.fromRGB(200, 200, 200)
InfoText.Font = Enum.Font.Gotham
InfoText.TextSize = 11
InfoText.TextXAlignment = Enum.TextXAlignment.Left
InfoText.TextWrapped = true

local KeyLabel = Instance.new("TextLabel")
KeyLabel.Parent = KeyFrame
KeyLabel.Size = UDim2.new(0.8, 0, 0, 20)
KeyLabel.Position = UDim2.new(0.1, 0, 0.52, 0)
KeyLabel.BackgroundTransparency = 1
KeyLabel.Text = "MASUKAN KEY ANDA"
KeyLabel.TextColor3 = ungu
KeyLabel.Font = Enum.Font.GothamBold
KeyLabel.TextSize = 12

local KeyTextBox = Instance.new("TextBox")
KeyTextBox.Parent = KeyFrame
KeyTextBox.Size = UDim2.new(0.8, 0, 0, 45)
KeyTextBox.Position = UDim2.new(0.1, 0, 0.57, 0)
KeyTextBox.BackgroundColor3 = gray
KeyTextBox.BackgroundTransparency = 0.1
KeyTextBox.TextColor3 = Color3.new(1, 1, 1)
KeyTextBox.PlaceholderText = "Contoh: PutzzVIP"
KeyTextBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
KeyTextBox.Font = Enum.Font.Gotham
KeyTextBox.TextSize = 14
KeyTextBox.ClearTextOnFocus = true
local KeyBoxCorner = Instance.new("UICorner")
KeyBoxCorner.Parent = KeyTextBox
KeyBoxCorner.CornerRadius = UDim.new(0, 10)

local VerifyBtn = Instance.new("TextButton")
VerifyBtn.Parent = KeyFrame
VerifyBtn.Size = UDim2.new(0.8, 0, 0, 45)
VerifyBtn.Position = UDim2.new(0.1, 0, 0.72, 0)
VerifyBtn.BackgroundColor3 = ungu
VerifyBtn.BackgroundTransparency = 0.2
VerifyBtn.Text = "VERIFIKASI KEY"
VerifyBtn.TextColor3 = Color3.new(1, 1, 1)
VerifyBtn.Font = Enum.Font.GothamBold
VerifyBtn.TextSize = 16
local VerifyCorner = Instance.new("UICorner")
VerifyCorner.Parent = VerifyBtn
VerifyCorner.CornerRadius = UDim.new(0, 10)

local GetKeyBtn = Instance.new("TextButton")
GetKeyBtn.Parent = KeyFrame
GetKeyBtn.Size = UDim2.new(0.5, 0, 0, 35)
GetKeyBtn.Position = UDim2.new(0.25, 0, 0.86, 0)
GetKeyBtn.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
GetKeyBtn.BackgroundTransparency = 0.2
GetKeyBtn.Text = "🌐 GET KEY"
GetKeyBtn.TextColor3 = Color3.new(1, 1, 1)
GetKeyBtn.Font = Enum.Font.GothamBold
GetKeyBtn.TextSize = 14
local GetKeyCorner = Instance.new("UICorner")
GetKeyCorner.Parent = GetKeyBtn
GetKeyCorner.CornerRadius = UDim.new(0, 8)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Parent = KeyFrame
StatusLabel.Size = UDim2.new(0.9, 0, 0, 30)
StatusLabel.Position = UDim2.new(0.05, 0, 0.93, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "🔑 Masukkan key"
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 11

local LoadingCircle = Instance.new("Frame")
LoadingCircle.Parent = KeyFrame
LoadingCircle.Size = UDim2.new(0, 25, 0, 25)
LoadingCircle.Position = UDim2.new(0.5, -12, 0.96, -12)
LoadingCircle.BackgroundColor3 = ungu
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
            StatusLabel.Text = "✅ Link disalin!"
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            task.wait(2)
            StatusLabel.Text = "🔑 Masukkan key"
            StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    end)
end)

VerifyBtn.MouseButton1Click:Connect(function()
    local key = KeyTextBox.Text:gsub("%s+", "")
    if key == "" then
        StatusLabel.Text = "❌ Masukkan key!"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        return
    end
    showLoading(true)
    StatusLabel.Text = "⏳ Verifikasi..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    VerifyBtn.Text = "⏳ VERIFIKASI..."
    local valid, message = cekKey(key)  -- fungsi cekKey sudah mengembalikan (boolean, string)
    showLoading(false)
    VerifyBtn.Text = "VERIFIKASI KEY"
    if valid then
        StatusLabel.Text = "✅ " .. message
        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        TweenService:Create(KeyFrame, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 100, 0)}):Play()
        task.wait(0.3)
        for i = 3, 1, -1 do
            StatusLabel.Text = "Loading " .. i .. "..."
            task.wait(1)
        end
        KeyGui:Destroy()
        initESP()
        createEnemyCounter()  -- buat enemy counter
        
        local notif = Instance.new("ScreenGui")
        notif.Parent = game.CoreGui
        local nf = Instance.new("Frame")
        nf.Parent = notif
        nf.Size = UDim2.new(0, 300, 0, 50)
        nf.Position = UDim2.new(0.5, -150, 0.5, -25)
        nf.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        nf.BackgroundTransparency = 0.1
        local nc = Instance.new("UICorner")
        nc.Parent = nf
        nc.CornerRadius = UDim.new(0, 12)
        local nt = Instance.new("TextLabel")
        nt.Parent = nf
        nt.Size = UDim2.new(1, 0, 1, 0)
        nt.BackgroundTransparency = 1
        nt.Text = "✅ DRIP CLIENT ACTIVATED!"
        nt.TextColor3 = Color3.fromRGB(255, 255, 255)
        nt.Font = Enum.Font.GothamBold
        nt.TextSize = 16
        task.wait(2)
        notif:Destroy()
        
        -- ================== MENU UTAMA ==================
        local MenuGui = Instance.new("ScreenGui")
        MenuGui.Name = "DripClient"
        MenuGui.Parent = game.CoreGui
        
        local MainFrame = Instance.new("Frame")
        MainFrame.Parent = MenuGui
        MainFrame.Size = UDim2.new(0, 360, 0, 520)
        MainFrame.Position = UDim2.new(0.5, -180, 0.5, -260)
        MainFrame.BackgroundColor3 = dark
        MainFrame.BackgroundTransparency = 0.05
        MainFrame.BorderSizePixel = 0
        MainFrame.Active = true
        MainFrame.Draggable = true
        MainFrame.Visible = true
        
        local MainCorner = Instance.new("UICorner")
        MainCorner.Parent = MainFrame
        MainCorner.CornerRadius = UDim.new(0, 20)
        
        local Border = Instance.new("Frame")
        Border.Parent = MainFrame
        Border.Size = UDim2.new(1, 0, 1, 0)
        Border.BackgroundTransparency = 1
        Border.BorderSizePixel = 2
        Border.BorderColor3 = ungu
        local BorderCorner = Instance.new("UICorner")
        BorderCorner.Parent = Border
        BorderCorner.CornerRadius = UDim.new(0, 20)
        
        local Header = Instance.new("Frame")
        Header.Parent = MainFrame
        Header.Size = UDim2.new(1, 0, 0, 60)
        Header.BackgroundColor3 = ungu
        Header.BackgroundTransparency = 0.15
        Header.BorderSizePixel = 0
        local HeaderCorner = Instance.new("UICorner")
        HeaderCorner.Parent = Header
        HeaderCorner.CornerRadius = UDim.new(0, 20)
        
        local Title = Instance.new("TextLabel")
        Title.Parent = Header
        Title.Size = UDim2.new(1, 0, 1, 0)
        Title.BackgroundTransparency = 1
        Title.Text = "DRIP CLIENT"
        Title.TextColor3 = Color3.fromRGB(255, 255, 255)
        Title.Font = Enum.Font.GothamBlack
        Title.TextSize = 22
        
        -- Tombol minimize dengan image
        local minimizeBtn = Instance.new("ImageButton")
        minimizeBtn.Parent = Header
        minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
        minimizeBtn.Position = UDim2.new(1, -35, 0, 15)
        minimizeBtn.BackgroundTransparency = 1
        minimizeBtn.Image = "rbxassetid://72495850369898"
        minimizeBtn.ImageColor3 = Color3.fromRGB(255, 255, 255)
        minimizeBtn.ZIndex = 10
        
        local minimized = false
        minimizeBtn.MouseButton1Click:Connect(function()
            minimized = not minimized
            MainFrame.Visible = not minimized
            if minimized then
                MainFrame.Size = UDim2.new(0, 360, 0, 60)
            else
                MainFrame.Size = UDim2.new(0, 360, 0, 520)
            end
        end)
        
        local Subtitle = Instance.new("TextLabel")
        Subtitle.Parent = Header
        Subtitle.Size = UDim2.new(1, 0, 0, 20)
        Subtitle.Position = UDim2.new(0, 0, 0, 40)
        Subtitle.BackgroundTransparency = 1
        Subtitle.Text = ""
        Subtitle.TextColor3 = ungu
        Subtitle.Font = Enum.Font.Gotham
        Subtitle.TextSize = 11
        
        -- Tab Bar
        local TabBar = Instance.new("Frame")
        TabBar.Parent = MainFrame
        TabBar.Size = UDim2.new(0.96, 0, 0, 40)
        TabBar.Position = UDim2.new(0.02, 0, 0.13, 0)
        TabBar.BackgroundColor3 = gray
        TabBar.BackgroundTransparency = 0.3
        TabBar.BorderSizePixel = 0
        local TabBarCorner = Instance.new("UICorner")
        TabBarCorner.Parent = TabBar
        TabBarCorner.CornerRadius = UDim.new(0, 10)
        
        local tabMain = Instance.new("TextButton")
        tabMain.Parent = TabBar
        tabMain.Size = UDim2.new(0.33, -2, 1, -4)
        tabMain.Position = UDim2.new(0, 2, 0, 2)
        tabMain.BackgroundColor3 = ungu
        tabMain.BackgroundTransparency = 0.3
        tabMain.Text = "MAIN"
        tabMain.TextColor3 = Color3.fromRGB(255, 255, 255)
        tabMain.Font = Enum.Font.GothamBold
        tabMain.TextSize = 14
        local tabMainCorner = Instance.new("UICorner")
        tabMainCorner.Parent = tabMain
        tabMainCorner.CornerRadius = UDim.new(0, 8)
        
        local tabESP = Instance.new("TextButton")
        tabESP.Parent = TabBar
        tabESP.Size = UDim2.new(0.33, -2, 1, -4)
        tabESP.Position = UDim2.new(0.33, 2, 0, 2)
        tabESP.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        tabESP.BackgroundTransparency = 0.5
        tabESP.Text = "ESP"
        tabESP.TextColor3 = Color3.fromRGB(200, 200, 200)
        tabESP.Font = Enum.Font.GothamBold
        tabESP.TextSize = 14
        local tabESPCorner = Instance.new("UICorner")
        tabESPCorner.Parent = tabESP
        tabESPCorner.CornerRadius = UDim.new(0, 8)
        
        local tabInfo = Instance.new("TextButton")
        tabInfo.Parent = TabBar
        tabInfo.Size = UDim2.new(0.33, -2, 1, -4)
        tabInfo.Position = UDim2.new(0.66, 2, 0, 2)
        tabInfo.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        tabInfo.BackgroundTransparency = 0.5
        tabInfo.Text = "INFO"
        tabInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
        tabInfo.Font = Enum.Font.GothamBold
        tabInfo.TextSize = 14
        local tabInfoCorner = Instance.new("UICorner")
        tabInfoCorner.Parent = tabInfo
        tabInfoCorner.CornerRadius = UDim.new(0, 8)
        
        -- Content panels
        local contentMain = Instance.new("ScrollingFrame")
        contentMain.Parent = MainFrame
        contentMain.Size = UDim2.new(0.94, 0, 0.74, 0)
        contentMain.Position = UDim2.new(0.03, 0, 0.21, 0)
        contentMain.BackgroundColor3 = gray
        contentMain.BackgroundTransparency = 0.4
        contentMain.BorderSizePixel = 0
        contentMain.ScrollBarThickness = 5
        contentMain.ScrollBarImageColor3 = ungu
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
        contentESP.Size = UDim2.new(0.94, 0, 0.74, 0)
        contentESP.Position = UDim2.new(0.03, 0, 0.21, 0)
        contentESP.BackgroundColor3 = gray
        contentESP.BackgroundTransparency = 0.4
        contentESP.BorderSizePixel = 0
        contentESP.ScrollBarThickness = 5
        contentESP.ScrollBarImageColor3 = ungu
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
        
        local contentInfo = Instance.new("ScrollingFrame")
        contentInfo.Parent = MainFrame
        contentInfo.Size = UDim2.new(0.94, 0, 0.74, 0)
        contentInfo.Position = UDim2.new(0.03, 0, 0.21, 0)
        contentInfo.BackgroundColor3 = gray
        contentInfo.BackgroundTransparency = 0.4
        contentInfo.BorderSizePixel = 0
        contentInfo.ScrollBarThickness = 5
        contentInfo.ScrollBarImageColor3 = ungu
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
            tabMain.BackgroundColor3 = ungu
            tabMain.BackgroundTransparency = 0.3
            tabMain.TextColor3 = Color3.fromRGB(255, 255, 255)
            tabESP.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
            tabESP.BackgroundTransparency = 0.5
            tabESP.TextColor3 = Color3.fromRGB(200, 200, 200)
            tabInfo.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
            tabInfo.BackgroundTransparency = 0.5
            tabInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
            contentMain.Visible = true
            contentESP.Visible = false
            contentInfo.Visible = false
        end)
        tabESP.MouseButton1Click:Connect(function()
            tabESP.BackgroundColor3 = ungu
            tabESP.BackgroundTransparency = 0.3
            tabESP.TextColor3 = Color3.fromRGB(255, 255, 255)
            tabMain.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
            tabMain.BackgroundTransparency = 0.5
            tabMain.TextColor3 = Color3.fromRGB(200, 200, 200)
            tabInfo.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
            tabInfo.BackgroundTransparency = 0.5
            tabInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
            contentMain.Visible = false
            contentESP.Visible = true
            contentInfo.Visible = false
        end)
        tabInfo.MouseButton1Click:Connect(function()
            tabInfo.BackgroundColor3 = ungu
            tabInfo.BackgroundTransparency = 0.3
            tabInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
            tabMain.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
            tabMain.BackgroundTransparency = 0.5
            tabMain.TextColor3 = Color3.fromRGB(200, 200, 200)
            tabESP.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
            tabESP.BackgroundTransparency = 0.5
            tabESP.TextColor3 = Color3.fromRGB(200, 200, 200)
            contentMain.Visible = false
            contentESP.Visible = false
            contentInfo.Visible = true
        end)
        
        -- ================== FUNGSI TOGGLE ==================
        local function createToggle(parent, text, defaultColor, callback, defaultState)
            local frame = Instance.new("Frame")
            frame.Parent = parent
            frame.Size = UDim2.new(0.95, 0, 0, 50)
            frame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
            frame.BackgroundTransparency = 0.2
            frame.BorderSizePixel = 0
            local fc = Instance.new("UICorner")
            fc.Parent = frame
            fc.CornerRadius = UDim.new(0, 10)
            
            local lbl = Instance.new("TextLabel")
            lbl.Parent = frame
            lbl.Size = UDim2.new(0.7, 0, 1, 0)
            lbl.Position = UDim2.new(0.05, 0, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = text
            lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
            lbl.Font = Enum.Font.GothamBold
            lbl.TextSize = 14
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            
            local sw = Instance.new("Frame")
            sw.Parent = frame
            sw.Size = UDim2.new(0, 50, 0, 26)
            sw.Position = UDim2.new(0.82, 0, 0.5, -13)
            sw.BackgroundColor3 = defaultState and defaultColor or Color3.fromRGB(80, 80, 90)
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
                TweenService:Create(sw, TweenInfo.new(0.15), {BackgroundColor3 = state and defaultColor or Color3.fromRGB(80, 80, 90)}):Play()
                TweenService:Create(circle, TweenInfo.new(0.15), {Position = state and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0.05, 0, 0.5, -11)}):Play()
                callback(state)
            end)
        end
        
        -- MAIN tab
        createToggle(contentMain, "NOCLIP", ungu, function(s)
            noclipEnabled = s
            if s then updateNoclip() end
        end, false)
        
        createToggle(contentMain, "GOD MODE", ungu, function(s)
            godModeEnabled = s
            if s then updateGodMode() elseif godModeConn then godModeConn:Disconnect() end
        end, false)
        
        createToggle(contentMain, "SPEED 70", ungu, function(s)
            speedEnabled = s
            setSpeed(s)
        end, false)
        
        createToggle(contentMain, "INFINITY JUMP", ungu, function(s)
            infJumpEnabled = s
            if s then updateInfJump() elseif infJumpConn then infJumpConn:Disconnect() end
        end, false)
        
        createToggle(contentMain, "CROSSHAIR", ungu, function(s)
            crosshairEnabled = s
            if s then createCrosshair() else removeCrosshair() end
        end, false)
        
        -- ESP tab
        createToggle(contentESP, "ESP LINE", putih, function(s)
            espLineEnabled = s
            if not s then
                for _, v in pairs(espLines) do v[1].Visible = false end
            end
        end, false)
        
        createToggle(contentESP, "ESP BOX", hijau, function(s)
            espBoxEnabled = s
            if not s then
                for _, v in pairs(espBoxes) do v[1].Visible = false end
                for _, v in pairs(espNames) do v[1].Visible = false end
                for _, v in pairs(espHealthBars) do v[1].Visible = false end
            end
        end, false)
        
        createToggle(contentESP, "HOLOGRAM", merah, function(s)
            hologramEnabled = s
            if s then applyHologramToAll() else removeHologramFromAll() end
        end, false)
        
        -- ================== TAB INFO (dengan timer key) ==================
        local timerLabel = Instance.new("TextLabel")
        timerLabel.Parent = contentInfo
        timerLabel.Size = UDim2.new(0.95, 0, 0, 40)
        timerLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        timerLabel.BackgroundTransparency = 0.2
        timerLabel.Text = "Memuat sisa waktu..."
        timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        timerLabel.Font = Enum.Font.GothamBold
        timerLabel.TextSize = 14
        timerLabel.TextWrapped = true
        local timerCorner = Instance.new("UICorner")
        timerCorner.Parent = timerLabel
        timerCorner.CornerRadius = UDim.new(0, 10)
        
        local infoTextLabel = Instance.new("TextLabel")
        infoTextLabel.Parent = contentInfo
        infoTextLabel.Size = UDim2.new(0.95, 0, 0, 100)
        infoTextLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        infoTextLabel.BackgroundTransparency = 0.2
        infoTextLabel.Text = "DRIP CLIENT\n\nDeveloper: Putzzdev\nTikTok: Putzz_mvpp\nWhatsApp: 088976255131"
        infoTextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        infoTextLabel.Font = Enum.Font.Gotham
        infoTextLabel.TextSize = 14
        infoTextLabel.TextWrapped = true
        infoTextLabel.TextYAlignment = Enum.TextYAlignment.Center
        local infoCorner2 = Instance.new("UICorner")
        infoCorner2.Parent = infoTextLabel
        infoCorner2.CornerRadius = UDim.new(0, 10)
        
        -- Update timer setiap detik
        local function updateKeyTimer()
            if not keyValid then
                timerLabel.Text = "Key tidak valid"
                return
            end
            local remaining = keyExpiryTime - os.time()
            if remaining <= 0 and keyExpiryTime ~= math.huge then
                timerLabel.Text = "KEY EXPIRED!"
                return
            end
            if keyExpiryTime == math.huge then
                timerLabel.Text = "Sisa waktu: PERMANEN"
                return
            end
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
        
        -- ================== TOMBOL MENU (IMAGE, BISA DIGESER) ==================
        local menuBtn = Instance.new("ImageButton")
        menuBtn.Parent = MenuGui
        menuBtn.Size = UDim2.new(0, 50, 0, 50)
        menuBtn.Position = UDim2.new(0, 10, 0.5, -25)
        menuBtn.BackgroundTransparency = 1
        menuBtn.Image = "rbxassetid://72495850369898"
        menuBtn.ImageColor3 = Color3.fromRGB(255, 255, 255)
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
                newX = math.clamp(newX, 0, Camera.ViewportSize.X - menuBtn.AbsoluteSize.X)
                newY = math.clamp(newY, 0, Camera.ViewportSize.Y - menuBtn.AbsoluteSize.Y)
                menuBtn.Position = UDim2.new(0, newX, 0, newY)
            end
        end)
        
        local menuVisible = true
        menuBtn.MouseButton1Click:Connect(function()
            menuVisible = not menuVisible
            MainFrame.Visible = menuVisible
            if menuVisible then
                MainFrame.Size = UDim2.new(0, 360, 0, 520)
                TweenService:Create(MainFrame, TweenInfo.new(0.2), {Position = UDim2.new(0.5, -180, 0.5, -260)}):Play()
            else
                TweenService:Create(MainFrame, TweenInfo.new(0.2), {Position = UDim2.new(0.5, -180, 1, 0)}):Play()
            end
        end)
        
    else
        StatusLabel.Text = "❌ " .. message
        StatusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
        for i = 1, 3 do
            TweenService:Create(KeyFrame, TweenInfo.new(0.05), {BackgroundColor3 = Color3.fromRGB(100, 0, 0)}):Play()
            task.wait(0.05)
            TweenService:Create(KeyFrame, TweenInfo.new(0.05), {BackgroundColor3 = dark}):Play()
            task.wait(0.05)
        end
        task.wait(1.5)
        StatusLabel.Text = "🔑 Masukkan key"
        StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        KeyTextBox.Text = ""
    end
end)