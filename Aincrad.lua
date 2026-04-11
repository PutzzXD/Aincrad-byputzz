-- ================== AINCRAD V1.1 ==================
-- By Putzzdev

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

-- Warna
local cyan = Color3.fromRGB(0, 255, 255)
local dark = Color3.fromRGB(8, 8, 12)
local gray = Color3.fromRGB(25, 25, 35)
local hijau = Color3.fromRGB(0, 200, 0)
local merah = Color3.fromRGB(180, 40, 40)

-- Database
local DB_URL = "https://key-database-701af-default-rtdb.asia-southeast1.firebasedatabase.app/keys.json"
local WEB_URL = "https://putzzdevxit.github.io/KEY-GENERATOR-/"

local MAX_DIST = 150

-- ================== VARIABEL ==================
local espLineEnabled = false
local espBoxEnabled = false
local hologramEnabled = false

local espLines = {}
local espBoxes = {}
local espNames = {}

local hologramParts = {}
local hologramConnections = {}
local originalHologramData = {}

-- ================== FUNGSI CEK KEY ==================
local function cekKey(key)
    local success, data = pcall(function()
        return game:HttpGet(DB_URL, true)
    end)
    if success and data then
        local success2, json = pcall(function()
            return HttpService:JSONDecode(data)
        end)
        if success2 and json then
            for _, k in pairs(json) do
                if k.key and string.upper(k.key) == string.upper(key) then
                    return true
                end
            end
        end
    end
    return false
end

-- ================== PERBAIKAN HOLOGRAM ==================
-- HOLOGRAM (lebih cerah)
local function applyHologram(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char then return end
    
    if hologramConnections[player] then
        hologramConnections[player]:Disconnect()
        hologramConnections[player] = nil
    end
    
    if not originalHologramData[player] then
        originalHologramData[player] = {}
    end
    
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if not originalHologramData[player][part] then
                originalHologramData[player][part] = {
                    Material = part.Material,
                    Transparency = part.Transparency,
                    Color = part.Color
                }
            end
            part.Material = Enum.Material.Neon
            part.Transparency = 0.25
            part.Color = Color3.fromRGB(255, 50, 50)
        end
    end
    
    local conn = RunService.RenderStepped:Connect(function()
        if not hologramEnabled then return end
        if not player or not player.Parent then conn:Disconnect() return end
        local char = player.Character
        if not char then return end
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function()
                    part.Material = Enum.Material.Neon
                    part.Transparency = 0.25
                    part.Color = Color3.fromRGB(255, 50, 50)
                end)
            end
        end
    end)
    
    hologramConnections[player] = conn
end

-- ================== ESP LINE ==================
local function createLine(player)
    if player == LocalPlayer then return end
    local line = Drawing.new("Line")
    line.Thickness = 2
    line.Color = cyan
    line.Visible = false
    table.insert(espLines, {line, player})
end

-- ================== ESP BOX ==================
local function createBox(player)
    if player == LocalPlayer then return end
    local box = Drawing.new("Square")
    box.Thickness = 2
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
end

local function clearESP()
    for _, v in pairs(espLines) do pcall(function() v[1]:Remove() end) end
    for _, v in pairs(espBoxes) do pcall(function() v[1]:Remove() end) end
    for _, v in pairs(espNames) do pcall(function() v[1]:Remove() end) end
    espLines = {}
    espBoxes = {}
    espNames = {}
end

local function updateESP()
    local myChar = LocalPlayer.Character
    local myPos = myChar and myChar:FindFirstChild("HumanoidRootPart") and myChar.HumanoidRootPart.Position
    
    -- Update LINE (toggle sendiri)
    for _, data in pairs(espLines) do
        local line, player = data[1], data[2]
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") and myPos and espLineEnabled then
            local hrp = char.HumanoidRootPart
            local pos, vis = Camera:WorldToViewportPoint(hrp.Position)
            local dist = (myPos - hrp.Position).Magnitude
            if vis and dist <= MAX_DIST then
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
    
    -- Update BOX (toggle sendiri)
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
    
    -- Update NAME (ngikut BOX)
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
    if hologramEnabled then
        task.wait(0.5)
        applyHologram(p)
    end
end)

Players.PlayerRemoving:Connect(function(p)
    removeHologram(p)
end)

RunService.RenderStepped:Connect(updateESP)

-- ================== GUI KEY ==================
local KeyGui = Instance.new("ScreenGui")
KeyGui.Name = "AincradKey"
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
KeyBorder.BorderColor3 = cyan
local KeyBorderCorner = Instance.new("UICorner")
KeyBorderCorner.Parent = KeyBorder
KeyBorderCorner.CornerRadius = UDim.new(0, 20)

local KeyIcon = Instance.new("TextLabel")
KeyIcon.Parent = KeyFrame
KeyIcon.Size = UDim2.new(1, 0, 0, 70)
KeyIcon.Position = UDim2.new(0, 0, 0, 15)
KeyIcon.BackgroundTransparency = 1
KeyIcon.Text = "🔐"
KeyIcon.TextColor3 = cyan
KeyIcon.Font = Enum.Font.GothamBlack
KeyIcon.TextSize = 45

local KeyTitle = Instance.new("TextLabel")
KeyTitle.Parent = KeyFrame
KeyTitle.Size = UDim2.new(1, 0, 0, 30)
KeyTitle.Position = UDim2.new(0, 0, 0, 75)
KeyTitle.BackgroundTransparency = 1
KeyTitle.Text = "AINCRAD"
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
KeyLabel.TextColor3 = cyan
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
VerifyBtn.BackgroundColor3 = cyan
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
LoadingCircle.BackgroundColor3 = cyan
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

-- ================== VERIFIKASI ==================
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
    
    local valid = cekKey(key)
    
    showLoading(false)
    VerifyBtn.Text = "VERIFIKASI KEY"
    
    if valid then
        StatusLabel.Text = "✅ KEY VALID!"
        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        TweenService:Create(KeyFrame, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 100, 0)}):Play()
        task.wait(0.3)
        
        for i = 3, 1, -1 do
            StatusLabel.Text = "Loading " .. i .. "..."
            task.wait(1)
        end
        
        KeyGui:Destroy()
        initESP()
        
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
        nt.Text = "✅ AINCRAD ACTIVATED!"
        nt.TextColor3 = Color3.fromRGB(255, 255, 255)
        nt.Font = Enum.Font.GothamBold
        nt.TextSize = 16
        task.wait(2)
        notif:Destroy()
        
        -- ================== MENU UTAMA ==================
        local MenuGui = Instance.new("ScreenGui")
        MenuGui.Name = "Aincrad"
        MenuGui.Parent = game.CoreGui
        
        local MainFrame = Instance.new("Frame")
        MainFrame.Parent = MenuGui
        MainFrame.Size = UDim2.new(0, 340, 0, 520)
        MainFrame.Position = UDim2.new(0.5, -170, 0.5, -260)
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
        Border.BorderColor3 = cyan
        local BorderCorner = Instance.new("UICorner")
        BorderCorner.Parent = Border
        BorderCorner.CornerRadius = UDim.new(0, 20)
        
        local Header = Instance.new("Frame")
        Header.Parent = MainFrame
        Header.Size = UDim2.new(1, 0, 0, 60)
        Header.BackgroundColor3 = cyan
        Header.BackgroundTransparency = 0.15
        Header.BorderSizePixel = 0
        local HeaderCorner = Instance.new("UICorner")
        HeaderCorner.Parent = Header
        HeaderCorner.CornerRadius = UDim.new(0, 20)
        
        local Title = Instance.new("TextLabel")
        Title.Parent = Header
        Title.Size = UDim2.new(1, 0, 1, 0)
        Title.BackgroundTransparency = 1
        Title.Text = "AINCRAD"
        Title.TextColor3 = Color3.fromRGB(255, 255, 255)
        Title.Font = Enum.Font.GothamBlack
        Title.TextSize = 22
        
        local Subtitle = Instance.new("TextLabel")
        Subtitle.Parent = Header
        Subtitle.Size = UDim2.new(1, 0, 0, 20)
        Subtitle.Position = UDim2.new(0, 0, 0, 40)
        Subtitle.BackgroundTransparency = 1
        Subtitle.Text = "ESP + HOLOGRAM"
        Subtitle.TextColor3 = cyan
        Subtitle.Font = Enum.Font.Gotham
        Subtitle.TextSize = 11
        
        local Content = Instance.new("ScrollingFrame")
        Content.Parent = MainFrame
        Content.Size = UDim2.new(0.94, 0, 0.76, 0)
        Content.Position = UDim2.new(0.03, 0, 0.16, 0)
        Content.BackgroundColor3 = gray
        Content.BackgroundTransparency = 0.4
        Content.BorderSizePixel = 0
        Content.ScrollBarThickness = 5
        Content.ScrollBarImageColor3 = cyan
        Content.CanvasSize = UDim2.new(0, 0, 0, 0)
        Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
        local ContentCorner = Instance.new("UICorner")
        ContentCorner.Parent = Content
        ContentCorner.CornerRadius = UDim.new(0, 12)
        
        local Layout = Instance.new("UIListLayout")
        Layout.Parent = Content
        Layout.Padding = UDim.new(0, 10)
        Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        
        -- ================== FUNGSI TOGGLE ==================
        local function createToggle(text, desc, defaultColor, callback)
            local frame = Instance.new("Frame")
            frame.Parent = Content
            frame.Size = UDim2.new(0.95, 0, 0, 65)
            frame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
            frame.BackgroundTransparency = 0.2
            frame.BorderSizePixel = 0
            local fc = Instance.new("UICorner")
            fc.Parent = frame
            fc.CornerRadius = UDim.new(0, 10)
            
            local lbl = Instance.new("TextLabel")
            lbl.Parent = frame
            lbl.Size = UDim2.new(0.7, 0, 0.5, 0)
            lbl.Position = UDim2.new(0.05, 0, 0, 5)
            lbl.BackgroundTransparency = 1
            lbl.Text = text
            lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
            lbl.Font = Enum.Font.GothamBold
            lbl.TextSize = 14
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            
            local descLbl = Instance.new("TextLabel")
            descLbl.Parent = frame
            descLbl.Size = UDim2.new(0.7, 0, 0.4, 0)
            descLbl.Position = UDim2.new(0.05, 0, 0.5, 0)
            descLbl.BackgroundTransparency = 1
            descLbl.Text = desc
            descLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
            descLbl.Font = Enum.Font.Gotham
            descLbl.TextSize = 10
            descLbl.TextXAlignment = Enum.TextXAlignment.Left
            
            local sw = Instance.new("Frame")
            sw.Parent = frame
            sw.Size = UDim2.new(0, 50, 0, 26)
            sw.Position = UDim2.new(0.82, 0, 0.5, -13)
            sw.BackgroundColor3 = defaultColor
            sw.BorderSizePixel = 0
            local swc = Instance.new("UICorner")
            swc.Parent = sw
            swc.CornerRadius = UDim.new(0, 13)
            
            local circle = Instance.new("Frame")
            circle.Parent = sw
            circle.Size = UDim2.new(0, 22, 0, 22)
            circle.Position = UDim2.new(1, -24, 0.5, -11)
            circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            circle.BorderSizePixel = 0
            local circ = Instance.new("UICorner")
            circ.Parent = circle
            circ.CornerRadius = UDim.new(1, 0)
            
            local state = true
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
        
        -- ================== TOGGLE ESP LINE ==================
        local lineState = true
        local lineFrame = Instance.new("Frame")
        lineFrame.Parent = Content
        lineFrame.Size = UDim2.new(0.95, 0, 0, 65)
        lineFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        lineFrame.BackgroundTransparency = 0.2
        lineFrame.BorderSizePixel = 0
        local lineFc = Instance.new("UICorner")
        lineFc.Parent = lineFrame
        lineFc.CornerRadius = UDim.new(0, 10)
        
        local lineLbl = Instance.new("TextLabel")
        lineLbl.Parent = lineFrame
        lineLbl.Size = UDim2.new(0.7, 0, 0.5, 0)
        lineLbl.Position = UDim2.new(0.05, 0, 0, 5)
        lineLbl.BackgroundTransparency = 1
        lineLbl.Text = "📏 ESP LINE"
        lineLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        lineLbl.Font = Enum.Font.GothamBold
        lineLbl.TextSize = 14
        lineLbl.TextXAlignment = Enum.TextXAlignment.Left
        
        local lineDesc = Instance.new("TextLabel")
        lineDesc.Parent = lineFrame
        lineDesc.Size = UDim2.new(0.7, 0, 0.4, 0)
        lineDesc.Position = UDim2.new(0.05, 0, 0.5, 0)
        lineDesc.BackgroundTransparency = 1
        lineDesc.Text = "Garis dari atas ke player (Cyan)"
        lineDesc.TextColor3 = Color3.fromRGB(150, 150, 150)
        lineDesc.Font = Enum.Font.Gotham
        lineDesc.TextSize = 10
        lineDesc.TextXAlignment = Enum.TextXAlignment.Left
        
        local lineSw = Instance.new("Frame")
        lineSw.Parent = lineFrame
        lineSw.Size = UDim2.new(0, 50, 0, 26)
        lineSw.Position = UDim2.new(0.82, 0, 0.5, -13)
        lineSw.BackgroundColor3 = cyan
        lineSw.BorderSizePixel = 0
        local lineSwc = Instance.new("UICorner")
        lineSwc.Parent = lineSw
        lineSwc.CornerRadius = UDim.new(0, 13)
        
        local lineCircle = Instance.new("Frame")
        lineCircle.Parent = lineSw
        lineCircle.Size = UDim2.new(0, 22, 0, 22)
        lineCircle.Position = UDim2.new(1, -24, 0.5, -11)
        lineCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        lineCircle.BorderSizePixel = 0
        local lineCirc = Instance.new("UICorner")
        lineCirc.Parent = lineCircle
        lineCirc.CornerRadius = UDim.new(1, 0)
        
        local lineBtn = Instance.new("TextButton")
        lineBtn.Parent = lineFrame
        lineBtn.Size = UDim2.new(1, 0, 1, 0)
        lineBtn.BackgroundTransparency = 1
        lineBtn.Text = ""
        lineBtn.MouseButton1Click:Connect(function()
            lineState = not lineState
            espLineEnabled = lineState
            if lineState then
                TweenService:Create(lineSw, TweenInfo.new(0.15), {BackgroundColor3 = cyan}):Play()
                TweenService:Create(lineCircle, TweenInfo.new(0.15), {Position = UDim2.new(1, -24, 0.5, -11)}):Play()
            else
                TweenService:Create(lineSw, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(80, 80, 90)}):Play()
                TweenService:Create(lineCircle, TweenInfo.new(0.15), {Position = UDim2.new(0.05, 0, 0.5, -11)}):Play()
                for _, v in pairs(espLines) do v[1].Visible = false end
            end
        end)
        
        -- ================== TOGGLE ESP BOX ==================
        local boxState = true
        local boxFrame = Instance.new("Frame")
        boxFrame.Parent = Content
        boxFrame.Size = UDim2.new(0.95, 0, 0, 65)
        boxFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        boxFrame.BackgroundTransparency = 0.2
        boxFrame.BorderSizePixel = 0
        local boxFc = Instance.new("UICorner")
        boxFc.Parent = boxFrame
        boxFc.CornerRadius = UDim.new(0, 10)
        
        local boxLbl = Instance.new("TextLabel")
        boxLbl.Parent = boxFrame
        boxLbl.Size = UDim2.new(0.7, 0, 0.5, 0)
        boxLbl.Position = UDim2.new(0.05, 0, 0, 5)
        boxLbl.BackgroundTransparency = 1
        boxLbl.Text = "📦 ESP BOX"
        boxLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        boxLbl.Font = Enum.Font.GothamBold
        boxLbl.TextSize = 14
        boxLbl.TextXAlignment = Enum.TextXAlignment.Left
        
        local boxDesc = Instance.new("TextLabel")
        boxDesc.Parent = boxFrame
        boxDesc.Size = UDim2.new(0.7, 0, 0.4, 0)
        boxDesc.Position = UDim2.new(0.05, 0, 0.5, 0)
        boxDesc.BackgroundTransparency = 1
        boxDesc.Text = "Kotak + Nama player (Hijau)"
        boxDesc.TextColor3 = Color3.fromRGB(150, 150, 150)
        boxDesc.Font = Enum.Font.Gotham
        boxDesc.TextSize = 10
        boxDesc.TextXAlignment = Enum.TextXAlignment.Left
        
        local boxSw = Instance.new("Frame")
        boxSw.Parent = boxFrame
        boxSw.Size = UDim2.new(0, 50, 0, 26)
        boxSw.Position = UDim2.new(0.82, 0, 0.5, -13)
        boxSw.BackgroundColor3 = hijau
        boxSw.BorderSizePixel = 0
        local boxSwc = Instance.new("UICorner")
        boxSwc.Parent = boxSw
        boxSwc.CornerRadius = UDim.new(0, 13)
        
        local boxCircle = Instance.new("Frame")
        boxCircle.Parent = boxSw
        boxCircle.Size = UDim2.new(0, 22, 0, 22)
        boxCircle.Position = UDim2.new(1, -24, 0.5, -11)
        boxCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        boxCircle.BorderSizePixel = 0
        local boxCirc = Instance.new("UICorner")
        boxCirc.Parent = boxCircle
        boxCirc.CornerRadius = UDim.new(1, 0)
        
        local boxBtn = Instance.new("TextButton")
        boxBtn.Parent = boxFrame
        boxBtn.Size = UDim2.new(1, 0, 1, 0)
        boxBtn.BackgroundTransparency = 1
        boxBtn.Text = ""
        boxBtn.MouseButton1Click:Connect(function()
            boxState = not boxState
            espBoxEnabled = boxState
            if boxState then
                TweenService:Create(boxSw, TweenInfo.new(0.15), {BackgroundColor3 = hijau}):Play()
                TweenService:Create(boxCircle, TweenInfo.new(0.15), {Position = UDim2.new(1, -24, 0.5, -11)}):Play()
            else
                TweenService:Create(boxSw, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(80, 80, 90)}):Play()
                TweenService:Create(boxCircle, TweenInfo.new(0.15), {Position = UDim2.new(0.05, 0, 0.5, -11)}):Play()
                for _, v in pairs(espBoxes) do v[1].Visible = false end
                for _, v in pairs(espNames) do v[1].Visible = false end
            end
        end)
        
        -- ================== TOGGLE HOLOGRAM ==================
        local holoState = false
        local holoFrame = Instance.new("Frame")
        holoFrame.Parent = Content
        holoFrame.Size = UDim2.new(0.95, 0, 0, 65)
        holoFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        holoFrame.BackgroundTransparency = 0.2
        holoFrame.BorderSizePixel = 0
        local holoFc = Instance.new("UICorner")
        holoFc.Parent = holoFrame
        holoFc.CornerRadius = UDim.new(0, 10)
        
        local holoLbl = Instance.new("TextLabel")
        holoLbl.Parent = holoFrame
        holoLbl.Size = UDim2.new(0.7, 0, 0.5, 0)
        holoLbl.Position = UDim2.new(0.05, 0, 0, 5)
        holoLbl.BackgroundTransparency = 1
        holoLbl.Text = "✨ HOLOGRAM"
        holoLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        holoLbl.Font = Enum.Font.GothamBold
        holoLbl.TextSize = 14
        holoLbl.TextXAlignment = Enum.TextXAlignment.Left
        
        local holoDesc = Instance.new("TextLabel")
        holoDesc.Parent = holoFrame
        holoDesc.Size = UDim2.new(0.7, 0, 0.4, 0)
        holoDesc.Position = UDim2.new(0.05, 0, 0.5, 0)
        holoDesc.BackgroundTransparency = 1
        holoDesc.Text = "Tembus dinding (Merah transparan)"
        holoDesc.TextColor3 = Color3.fromRGB(150, 150, 150)
        holoDesc.Font = Enum.Font.Gotham
        holoDesc.TextSize = 10
        holoDesc.TextXAlignment = Enum.TextXAlignment.Left
        
        local holoSw = Instance.new("Frame")
        holoSw.Parent = holoFrame
        holoSw.Size = UDim2.new(0, 50, 0, 26)
        holoSw.Position = UDim2.new(0.82, 0, 0.5, -13)
        holoSw.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
        holoSw.BorderSizePixel = 0
        local holoSwc = Instance.new("UICorner")
        holoSwc.Parent = holoSw
        holoSwc.CornerRadius = UDim.new(0, 13)
        
        local holoCircle = Instance.new("Frame")
        holoCircle.Parent = holoSw
        holoCircle.Size = UDim2.new(0, 22, 0, 22)
        holoCircle.Position = UDim2.new(0.05, 0, 0.5, -11)
        holoCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        holoCircle.BorderSizePixel = 0
        local holoCirc = Instance.new("UICorner")
        holoCirc.Parent = holoCircle
        holoCirc.CornerRadius = UDim.new(1, 0)
        
        local holoBtn = Instance.new("TextButton")
        holoBtn.Parent = holoFrame
        holoBtn.Size = UDim2.new(1, 0, 1, 0)
        holoBtn.BackgroundTransparency = 1
        holoBtn.Text = ""
        holoBtn.MouseButton1Click:Connect(function()
            holoState = not holoState
            hologramEnabled = holoState
            if holoState then
                TweenService:Create(holoSw, TweenInfo.new(0.15), {BackgroundColor3 = merah}):Play()
                TweenService:Create(holoCircle, TweenInfo.new(0.15), {Position = UDim2.new(1, -24, 0.5, -11)}):Play()
                applyHologramToAll()
            else
                TweenService:Create(holoSw, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(80, 80, 90)}):Play()
                TweenService:Create(holoCircle, TweenInfo.new(0.15), {Position = UDim2.new(0.05, 0, 0.5, -11)}):Play()
                removeHologramFromAll()
            end
        end)
        
        -- Info Panel
        local infoFrame = Instance.new("Frame")
        infoFrame.Parent = Content
        infoFrame.Size = UDim2.new(0.95, 0, 0, 100)
        infoFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        infoFrame.BackgroundTransparency = 0.2
        infoFrame.BorderSizePixel = 0
        local infoCorner = Instance.new("UICorner")
        infoCorner.Parent = infoFrame
        infoCorner.CornerRadius = UDim.new(0, 10)
        
        local infoText = Instance.new("TextLabel")
        infoText.Parent = infoFrame
        infoText.Size = UDim2.new(1, 0, 1, 0)
        infoText.BackgroundTransparency = 1
        infoText.Text = "👨‍💻 DEVELOPER: Putzzdev\n📱 TIKTOK: @Putzz_mvpp\n📞 WA: 088976255131"
        infoText.TextColor3 = Color3.fromRGB(255, 255, 255)
        infoText.Font = Enum.Font.Gotham
        infoText.TextSize = 11
        infoText.TextWrapped = true
        infoText.TextYAlignment = Enum.TextYAlignment.Center
        
        -- Tombol toggle menu
        local menuBtn = Instance.new("TextButton")
        menuBtn.Parent = MenuGui
        menuBtn.Size = UDim2.new(0, 90, 0, 40)
        menuBtn.Position = UDim2.new(0, 10, 0.5, -20)
        menuBtn.BackgroundColor3 = cyan
        menuBtn.BackgroundTransparency = 0.2
        menuBtn.Text = "🔓 AINCRAD"
        menuBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        menuBtn.Font = Enum.Font.GothamBlack
        menuBtn.TextSize = 13
        menuBtn.Draggable = true
        local menuCorner = Instance.new("UICorner")
        menuCorner.Parent = menuBtn
        menuCorner.CornerRadius = UDim.new(0, 12)
        
        local menuVisible = true
        menuBtn.MouseButton1Click:Connect(function()
            menuVisible = not menuVisible
            MainFrame.Visible = menuVisible
            if menuVisible then
                TweenService:Create(MainFrame, TweenInfo.new(0.2), {Position = UDim2.new(0.5, -170, 0.5, -260)}):Play()
            else
                TweenService:Create(MainFrame, TweenInfo.new(0.2), {Position = UDim2.new(0.5, -170, 1, 0)}):Play()
            end
        end)
        
    else
        StatusLabel.Text = "❌ KEY INVALID!"
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

print("🔐 AINCRAD V1.1 - Masukkan key: PutzzVIP")