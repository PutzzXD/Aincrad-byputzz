-- ╔══════════════════════════════════════════════╗
-- ║         PUTZZDEV | MURDER MYSTERY 2          ║
-- ║   ESP | Auto Coin | Survival | Info          ║
-- ╚══════════════════════════════════════════════╝

local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local TweenService  = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Camera        = workspace.CurrentCamera
local LocalPlayer   = Players.LocalPlayer

-- ================== WARNA ==================
local C = {
    bg        = Color3.fromRGB(8,  10,  18),
    panel     = Color3.fromRGB(14, 17,  28),
    card      = Color3.fromRGB(20, 24,  38),
    accent    = Color3.fromRGB(220, 50, 50),
    accentB   = Color3.fromRGB(50, 150, 255),
    accentG   = Color3.fromRGB(50, 220, 120),
    accentY   = Color3.fromRGB(255, 210, 50),
    text      = Color3.fromRGB(230, 230, 240),
    subtext   = Color3.fromRGB(120, 130, 160),
    white     = Color3.fromRGB(255, 255, 255),
    border    = Color3.fromRGB(40,  48,  70),
    murderer  = Color3.fromRGB(255, 50,  50),
    sheriff   = Color3.fromRGB(50,  150, 255),
    innocent  = Color3.fromRGB(50,  220, 120),
    coin      = Color3.fromRGB(255, 210, 50),
    gun       = Color3.fromRGB(255, 140, 0),
}

-- ================== STATE ==================
local espEnabled        = false
local coinESPEnabled    = false
local autoCollect       = false
local highlightMurder   = false
local highlightSheriff  = false
local highlightGun      = false
local notifMurderer     = false
local autoDodgeEnabled  = false
local autoPickupGun     = false

local dodgeConn         = nil
local notifConn         = nil
local lastNotifTime     = 0
local pickupConn        = nil

-- ================== FUNGSI ROLE & GUN ==================
local function getRole(player)
    local rv = player:FindFirstChild("Role")
    if rv and rv:IsA("StringValue") then return rv.Value end
    if player.Character then
        if player.Character:FindFirstChild("Knife") then return "Murderer" end
        if player.Character:FindFirstChild("Gun")   then return "Sheriff"  end
    end
    local bp = player:FindFirstChild("Backpack")
    if bp then
        if bp:FindFirstChild("Knife") then return "Murderer" end
        if bp:FindFirstChild("Gun")   then return "Sheriff"  end
    end
    return "Innocent"
end

local function hasGun(player)
    if not player.Character then return false end
    return player.Character:FindFirstChild("Gun") ~= nil
end

local function getRoleColor(player)
    local role = getRole(player)
    if role == "Murderer" then return C.murderer, "☠ MURDERER"
    elseif role == "Sheriff" then return C.sheriff, "⭐ SHERIFF"
    else return C.innocent, ""
    end
end

-- ================== ESP DRAWING ==================
local espLines = {}
local espBoxes = {}
local espNames = {}
local coinLabels = {}
local coinHighlights = {}
local gunHighlights = {}

local function newLine(color)
    local l = Drawing.new("Line")
    l.Thickness = 1.5; l.Color = color; l.Visible = false
    return l
end
local function newBox(color)
    local b = Drawing.new("Square")
    b.Thickness = 1.8; b.Color = color; b.Filled = false; b.Visible = false
    return b
end
local function newText(color, size)
    local t = Drawing.new("Text")
    t.Size = size or 13; t.Color = color; t.Center = true
    t.Outline = true; t.OutlineColor = Color3.fromRGB(0,0,0); t.Visible = false
    return t
end

-- Init ESP Player
for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        espLines[p] = newLine(C.innocent)
        espBoxes[p] = newBox(C.innocent)
        espNames[p] = newText(C.white, 13)
    end
end
Players.PlayerAdded:Connect(function(p)
    if p == LocalPlayer then return end
    espLines[p] = newLine(C.innocent)
    espBoxes[p] = newBox(C.innocent)
    espNames[p] = newText(C.white, 13)
end)
Players.PlayerRemoving:Connect(function(p)
    if espLines[p] then espLines[p]:Remove(); espLines[p]=nil end
    if espBoxes[p] then espBoxes[p]:Remove(); espBoxes[p]=nil end
    if espNames[p] then espNames[p]:Remove(); espNames[p]=nil end
end)

-- ================== COIN ESP ==================
local function refreshCoinESP()
    for _, v in pairs(coinHighlights) do pcall(function() v:Destroy() end) end
    coinHighlights = {}
    for _, l in pairs(coinLabels) do pcall(function() l:Remove() end) end
    coinLabels = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "Coin" or (obj:IsA("BasePart") and obj.Name:lower():find("coin")) then
            local hl = Instance.new("Highlight")
            hl.FillColor = C.coin; hl.FillTransparency = 0.3
            hl.OutlineColor = Color3.fromRGB(255,255,150); hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Enabled = false; hl.Parent = obj
            table.insert(coinHighlights, hl)
            local lbl = newText(C.coin, 12)
            table.insert(coinLabels, {drawing=lbl, obj=obj, hl=hl})
        end
    end
end

-- ================== AUTO PICKUP GUN ==================
local function startAutoPickupGun()
    if pickupConn then pickupConn:Disconnect() end
    task.spawn(function()
        while autoPickupGun do
            local myChar = LocalPlayer.Character
            local hrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj.Name == "Gun" and obj:IsA("BasePart") and obj.Parent then
                        local dist = (hrp.Position - obj.Position).Magnitude
                        if dist < 5 then
                            -- Simulasi pickup (biasanya dengan touch atau click)
                            fireclickdetector(obj:FindFirstChildWhichIsA("ClickDetector"))
                        end
                    end
                end
            end
            task.wait(0.3)
        end
    end)
end

-- ================== AUTO DODGE ==================
local function startAutoDodge()
    if dodgeConn then dodgeConn:Disconnect() end
    dodgeConn = RunService.Heartbeat:Connect(function()
        if not autoDodgeEnabled then return end
        local myChar = LocalPlayer.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and (obj.Name:lower():find("knife") or obj.Name:lower():find("throw")) then
                local vel = obj.AssemblyLinearVelocity
                if vel.Magnitude > 10 then
                    local toMe = (myHRP.Position - obj.Position).Unit
                    if vel.Unit:Dot(toMe) > 0.6 and (myHRP.Position - obj.Position).Magnitude < 18 then
                        local dir = Vector3.new(math.random(-1,1), 0, math.random(-1,1)).Unit * 10
                        myHRP.CFrame = myHRP.CFrame + dir
                    end
                end
            end
        end
    end)
end

-- ================== UPDATE ESP & HIGHLIGHTS ==================
RunService.RenderStepped:Connect(function()
    local vp = Camera.ViewportSize
    local myChar = LocalPlayer.Character
    local myPos = myChar and myChar:FindFirstChild("HumanoidRootPart") and myChar.HumanoidRootPart.Position

    -- Update highlights (murderer, sheriff, gun)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local role = getRole(p)
            local hasGunNow = hasGun(p)
            local hl = p.Character:FindFirstChild("PutzzHighlight")
            if not hl then
                hl = Instance.new("Highlight")
                hl.Name = "PutzzHighlight"
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Parent = p.Character
            end
            if highlightMurder and role == "Murderer" then
                hl.FillColor = C.murderer; hl.FillTransparency = 0.4; hl.Enabled = true
            elseif highlightSheriff and role == "Sheriff" then
                hl.FillColor = C.sheriff; hl.FillTransparency = 0.4; hl.Enabled = true
            elseif highlightGun and hasGunNow then
                hl.FillColor = C.gun; hl.FillTransparency = 0.4; hl.Enabled = true
            else
                hl.Enabled = false
            end
        end
    end

    -- ESP Player
    for player, line in pairs(espLines) do
        local char = player.Character
        local head = char and char:FindFirstChild("Head")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if espEnabled and head and hrp and myPos then
            local screenPos, vis = Camera:WorldToViewportPoint(head.Position)
            local dist = math.floor((myPos - hrp.Position).Magnitude)
            local roleColor, roleTag = getRoleColor(player)
            line.Color = roleColor; espBoxes[player].Color = roleColor
            if vis then
                line.From = Vector2.new(vp.X/2, vp.Y)
                line.To = Vector2.new(screenPos.X, screenPos.Y)
                line.Visible = true
                local topSP = Camera:WorldToViewportPoint(head.Position + Vector3.new(0,0.7,0))
                local botSP = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0,3,0))
                local height = math.abs(topSP.Y - botSP.Y)
                local width = height/2
                espBoxes[player].Size = Vector2.new(width, height)
                espBoxes[player].Position = Vector2.new(screenPos.X - width/2, topSP.Y)
                espBoxes[player].Visible = true
                espNames[player].Color = roleColor
                espNames[player].Position = Vector2.new(screenPos.X, topSP.Y - 17)
                espNames[player].Text = player.Name .. " " .. roleTag .. " [" .. dist .. "m]"
                espNames[player].Visible = true
            else
                line.Visible = false; espBoxes[player].Visible = false; espNames[player].Visible = false
            end
        else
            if espLines[player] then espLines[player].Visible = false end
            if espBoxes[player] then espBoxes[player].Visible = false end
            if espNames[player] then espNames[player].Visible = false end
        end
    end

    -- Coin ESP
    for _, data in pairs(coinLabels) do
        local obj = data.obj
        if obj and obj.Parent and coinESPEnabled then
            local pos = obj.Position
            if pos and myPos then
                local sp, vis = Camera:WorldToViewportPoint(pos)
                if vis then
                    data.drawing.Position = Vector2.new(sp.X, sp.Y - 12)
                    data.drawing.Text = "💰 [" .. math.floor((myPos-pos).Magnitude) .. "m]"
                    data.drawing.Visible = true
                    if data.hl then data.hl.Enabled = true end
                else
                    data.drawing.Visible = false; if data.hl then data.hl.Enabled = false end
                end
            end
        else
            data.drawing.Visible = false
        end
    end
end)

-- ================== AUTO COLLECT COIN ==================
local collectConn = nil
local function startAutoCollect()
    if collectConn then collectConn:Disconnect() end
    task.spawn(function()
        while autoCollect do
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hrp and hum then
                local nearest, nearestDist = nil, math.huge
                for _, obj in pairs(workspace:GetDescendants()) do
                    if (obj.Name == "Coin" or (obj:IsA("BasePart") and obj.Name:lower():find("coin"))) and obj.Parent then
                        local d = (hrp.Position - obj.Position).Magnitude
                        if d < nearestDist then nearestDist = d; nearest = obj end
                    end
                end
                if nearest then
                    if nearestDist > 4 then
                        hum:MoveTo(nearest.Position)
                        task.wait(0.5)
                    else
                        task.wait(0.2)
                    end
                end
            end
            task.wait(0.2)
        end
    end)
end

-- ================== NOTIF MURDERER ==================
local function startMurdererNotif()
    if notifConn then notifConn:Disconnect() end
    notifConn = RunService.Heartbeat:Connect(function()
        if not notifMurderer then return end
        local myChar = LocalPlayer.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and getRole(p) == "Murderer" then
                local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                if hrp and (myHRP.Position - hrp.Position).Magnitude < 30 and tick() - lastNotifTime > 4 then
                    lastNotifTime = tick()
                    local gui = Instance.new("ScreenGui")
                    gui.Name = "MurderAlert"; gui.ResetOnSpawn = false; gui.Parent = game:GetService("CoreGui")
                    local f = Instance.new("Frame", gui)
                    f.Size = UDim2.new(0,280,0,52); f.Position = UDim2.new(0.5,-140,0,60)
                    f.BackgroundColor3 = Color3.fromRGB(40,10,10); f.BorderSizePixel = 0
                    Instance.new("UICorner", f).CornerRadius = UDim.new(0,12)
                    local fs = Instance.new("UIStroke", f); fs.Color = C.murderer; fs.Thickness = 2
                    local fl = Instance.new("TextLabel", f)
                    fl.Size = UDim2.new(1,0,1,0); fl.BackgroundTransparency = 1
                    fl.Text = "⚠ MURDERER MENDEKAT! ⚠"; fl.TextColor3 = C.murderer
                    fl.Font = Enum.Font.GothamBold; fl.TextSize = 16
                    TweenService:Create(f, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Position = UDim2.new(0.5,-140,0,80)}):Play()
                    task.delay(3, function() gui:Destroy() end)
                end
            end
        end
    end)
end

-- ================== INFO (ROUND & MAP) ==================
local function getRoundInfo()
    -- Coba ambil dari leaderstats atau game state
    local roundActive = true
    local timeLeft = "?"
    local alive = #Players:GetPlayers()
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health <= 0 then
            alive = alive - 1
        end
    end
    -- Estimasi waktu dari game lighting atau nilai default
    return string.format("Round: Aktif | Alive: %d | Waktu: ??", alive)
end

local function getMapName()
    local mapParts = workspace:FindFirstChild("Map") or workspace:FindFirstChild("Terrain")
    if mapParts then
        for _, child in pairs(workspace:GetChildren()) do
            if child.Name:lower():find("map") or child.Name:lower():find("lobby") then
                return child.Name
            end
        end
    end
    return "Unknown Map"
end

-- ================== UI ==================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PutzzdevMM2"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0,400,0,540); Main.Position = UDim2.new(0.5,-200,0.5,-270)
Main.BackgroundColor3 = C.bg; Main.BorderSizePixel = 0; Main.ClipsDescendants = true
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,14)
local mainStroke = Instance.new("UIStroke", Main); mainStroke.Color = C.accent; mainStroke.Thickness = 1.5

-- Header
local Header = Instance.new("Frame", Main)
Header.Size = UDim2.new(1,0,0,52); Header.BackgroundColor3 = Color3.fromRGB(12,10,20); Header.BorderSizePixel = 0
Instance.new("UICorner", Header).CornerRadius = UDim.new(0,14)
local accentLine = Instance.new("Frame", Header)
accentLine.Size = UDim2.new(1,0,0,2); accentLine.Position = UDim2.new(0,0,1,-2); accentLine.BackgroundColor3 = C.accent; accentLine.BorderSizePixel = 0
local titleLabel = Instance.new("TextLabel", Header)
titleLabel.Size = UDim2.new(1,0,1,0); titleLabel.BackgroundTransparency = 1; titleLabel.Text = "MURDER MYSTERY 2 | PUTZZDEV"
titleLabel.TextColor3 = C.white; titleLabel.Font = Enum.Font.GothamBold; titleLabel.TextSize = 14
local closeBtn = Instance.new("TextButton", Header)
closeBtn.Size = UDim2.new(0,28,0,28); closeBtn.Position = UDim2.new(1,-38,0.5,-14); closeBtn.BackgroundColor3 = Color3.fromRGB(60,20,20)
closeBtn.Text = "✕"; closeBtn.TextColor3 = C.accent; closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 14
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,6)
closeBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
end)

-- Tab Bar
local TabBar = Instance.new("Frame", Main)
TabBar.Size = UDim2.new(1,-24,0,34); TabBar.Position = UDim2.new(0,12,0,58); TabBar.BackgroundColor3 = C.card
Instance.new("UICorner", TabBar).CornerRadius = UDim.new(0,10)
local tabNames = {"ESP", "COINS", "SURVIVAL", "INFO"}
local tabBtns = {}
local tabContents = {}

local function createContent(name)
    local scroll = Instance.new("ScrollingFrame", Main)
    scroll.Name = name; scroll.Size = UDim2.new(1,-24,1,-106); scroll.Position = UDim2.new(0,12,0,100)
    scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0; scroll.ScrollBarThickness = 3
    scroll.Visible = (name == "ESP")
    local layout = Instance.new("UIListLayout", scroll)
    layout.Padding = UDim.new(0,8); layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 20)
    end)
    return scroll
end
for _, name in ipairs(tabNames) do
    tabContents[name] = createContent(name)
    local btn = Instance.new("TextButton", TabBar)
    btn.Size = UDim2.new(1/#tabNames, -2, 1, 0); btn.BackgroundColor3 = name == "ESP" and C.accent or Color3.fromRGB(0,0,0,0)
    btn.BackgroundTransparency = name == "ESP" and 0 or 1; btn.Text = name; btn.TextColor3 = name == "ESP" and C.white or C.subtext
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 12
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
    tabBtns[name] = btn
    btn.MouseButton1Click:Connect(function()
        for n, b in pairs(tabBtns) do
            local active = (n == name)
            b.BackgroundTransparency = active and 0 or 1
            b.BackgroundColor3 = C.accent
            b.TextColor3 = active and C.white or C.subtext
            tabContents[n].Visible = active
        end
    end)
end

-- Helper UI
local function sectionLabel(parent, text)
    local f = Instance.new("Frame", parent); f.Size = UDim2.new(0.95,0,0,20); f.BackgroundTransparency = 1
    local l = Instance.new("TextLabel", f); l.Size = UDim2.new(1,0,1,0); l.BackgroundTransparency = 1
    l.Text = text; l.TextColor3 = C.subtext; l.Font = Enum.Font.GothamBold; l.TextSize = 10; l.TextXAlignment = Enum.TextXAlignment.Left
end
local function createToggle(parent, labelTxt, accentColor, callback)
    local card = Instance.new("Frame", parent); card.Size = UDim2.new(0.95,0,0,48); card.BackgroundColor3 = C.card
    Instance.new("UICorner", card).CornerRadius = UDim.new(0,10)
    local stroke = Instance.new("UIStroke", card); stroke.Color = C.border; stroke.Thickness = 1
    local lbl = Instance.new("TextLabel", card); lbl.Size = UDim2.new(0.65,0,1,0); lbl.Position = UDim2.new(0,14,0,0)
    lbl.BackgroundTransparency = 1; lbl.Text = labelTxt; lbl.TextColor3 = C.text; lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 13; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local sw = Instance.new("Frame", card); sw.Size = UDim2.new(0,46,0,24); sw.Position = UDim2.new(1,-56,0.5,-12); sw.BackgroundColor3 = C.border
    Instance.new("UICorner", sw).CornerRadius = UDim.new(1,0)
    local dot = Instance.new("Frame", sw); dot.Size = UDim2.new(0,18,0,18); dot.Position = UDim2.new(0,3,0.5,-9); dot.BackgroundColor3 = C.white
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)
    local state = false
    local hit = Instance.new("TextButton", card); hit.Size = UDim2.new(1,0,1,0); hit.BackgroundTransparency = 1; hit.Text = ""
    hit.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(sw, TweenInfo.new(0.18), {BackgroundColor3 = state and accentColor or C.border}):Play()
        TweenService:Create(dot, TweenInfo.new(0.18), {Position = state and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9)}):Play()
        callback(state)
    end)
end
local function createButton(parent, labelTxt, accentColor, callback)
    local btn = Instance.new("TextButton", parent); btn.Size = UDim2.new(0.95,0,0,42); btn.BackgroundColor3 = C.card; btn.Text = labelTxt
    btn.TextColor3 = accentColor; btn.Font = Enum.Font.GothamBold; btn.TextSize = 13
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,10)
    local stroke = Instance.new("UIStroke", btn); stroke.Color = accentColor; stroke.Thickness = 1
    btn.MouseButton1Click:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = accentColor}):Play()
        TweenService:Create(btn, TweenInfo.new(0.1), {TextColor3 = C.bg}):Play()
        task.wait(0.1)
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = C.card}):Play()
        TweenService:Create(btn, TweenInfo.new(0.1), {TextColor3 = accentColor}):Play()
        callback()
    end)
end

-- ========= TAB ESP =========
sectionLabel(tabContents["ESP"], "  PLAYER ESP")
createToggle(tabContents["ESP"], "ESP Semua Player", C.innocent, function(s) espEnabled = s end)
sectionLabel(tabContents["ESP"], "  HIGHLIGHT KHUSUS")
createToggle(tabContents["ESP"], "Highlight Murderer", C.murderer, function(s) highlightMurder = s end)
createToggle(tabContents["ESP"], "Highlight Sheriff", C.sheriff, function(s) highlightSheriff = s end)
createToggle(tabContents["ESP"], "Highlight Gun (Pegang Gun)", C.gun, function(s) highlightGun = s end)
sectionLabel(tabContents["ESP"], "  INFO ROLE")
createButton(tabContents["ESP"], "🔍 Cek Role Sendiri", C.accentY, function()
    local role = getRole(LocalPlayer)
    local gui = Instance.new("ScreenGui"); gui.Name = "RoleNotif"; gui.ResetOnSpawn = false; gui.Parent = game:GetService("CoreGui")
    local f = Instance.new("Frame", gui); f.Size = UDim2.new(0,260,0,60); f.Position = UDim2.new(0.5,-130,0,80); f.BackgroundColor3 = C.card
    Instance.new("UICorner", f).CornerRadius = UDim.new(0,12)
    local color = role=="Murderer" and C.murderer or role=="Sheriff" and C.sheriff or C.innocent
    local icon = role=="Murderer" and "☠" or role=="Sheriff" and "⭐" or "😇"
    local lbl = Instance.new("TextLabel", f); lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1
    lbl.Text = icon .. "  Kamu adalah: " .. role; lbl.TextColor3 = color; lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 15
    task.delay(3, function() gui:Destroy() end)
end)

-- ========= TAB COINS =========
sectionLabel(tabContents["COINS"], "  KOIN")
createToggle(tabContents["COINS"], "Coin ESP (Hologram)", C.coin, function(s)
    coinESPEnabled = s; refreshCoinESP()
end)
createToggle(tabContents["COINS"], "Auto Farm Coin", C.accentG, function(s)
    autoCollect = s
    if s then startAutoCollect() elseif collectConn then collectConn:Disconnect() end
end)
createButton(tabContents["COINS"], "🔄 Refresh ESP Koin", C.coin, function() refreshCoinESP() end)

-- ========= TAB SURVIVAL =========
sectionLabel(tabContents["SURVIVAL"], "  PERINGATAN")
createToggle(tabContents["SURVIVAL"], "Murderer Alert (<30m)", C.accentY, function(s)
    notifMurderer = s
    if s then startMurdererNotif() elseif notifConn then notifConn:Disconnect() end
end)
sectionLabel(tabContents["SURVIVAL"], "  AUTO")
createToggle(tabContents["SURVIVAL"], "Auto Dodge Pisau", C.accent, function(s)
    autoDodgeEnabled = s
    if s then startAutoDodge() elseif dodgeConn then dodgeConn:Disconnect() end
end)
createToggle(tabContents["SURVIVAL"], "Auto Pickup Gun", C.gun, function(s)
    autoPickupGun = s
    if s then startAutoPickupGun() elseif pickupConn then pickupConn:Disconnect() end
end)

-- ========= TAB INFO =========
sectionLabel(tabContents["INFO"], "  INFORMASI ROUND")
local roundInfoLabel = Instance.new("TextLabel", tabContents["INFO"])
roundInfoLabel.Size = UDim2.new(0.95,0,0,40); roundInfoLabel.BackgroundColor3 = C.card; roundInfoLabel.TextColor3 = C.text
roundInfoLabel.Font = Enum.Font.Gotham; roundInfoLabel.TextSize = 12; roundInfoLabel.Text = "Memuat..."
Instance.new("UICorner", roundInfoLabel).CornerRadius = UDim.new(0,10)
sectionLabel(tabContents["INFO"], "  MAP DETECTOR")
local mapLabel = Instance.new("TextLabel", tabContents["INFO"])
mapLabel.Size = UDim2.new(0.95,0,0,40); mapLabel.BackgroundColor3 = C.card; mapLabel.TextColor3 = C.accentB
mapLabel.Font = Enum.Font.GothamBold; mapLabel.TextSize = 14
Instance.new("UICorner", mapLabel).CornerRadius = UDim.new(0,10)
sectionLabel(tabContents["INFO"], "  ROLE DETECTOR (Player lain)")
createButton(tabContents["INFO"], "📋 Lihat Role Semua Player", C.accent, function()
    local text = "Role Player:\n"
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            text = text .. p.Name .. " → " .. getRole(p) .. "\n"
        end
    end
    local gui = Instance.new("ScreenGui"); gui.Name = "RoleList"; gui.ResetOnSpawn = false; gui.Parent = game:GetService("CoreGui")
    local f = Instance.new("Frame", gui); f.Size = UDim2.new(0,300,0,400); f.Position = UDim2.new(0.5,-150,0.5,-200)
    f.BackgroundColor3 = C.bg; Instance.new("UICorner", f).CornerRadius = UDim.new(0,12)
    local txt = Instance.new("TextLabel", f); txt.Size = UDim2.new(1,0,1,0); txt.BackgroundTransparency = 1
    txt.Text = text; txt.TextColor3 = C.white; txt.Font = Enum.Font.Gotham; txt.TextSize = 12; txt.TextWrapped = true
    local close = Instance.new("TextButton", f); close.Size = UDim2.new(0,80,0,30); close.Position = UDim2.new(1,-90,1,-40)
    close.Text = "Tutup"; close.BackgroundColor3 = C.accent; close.TextColor3 = C.white; close.Font = Enum.Font.GothamBold
    close.MouseButton1Click:Connect(function() gui:Destroy() end)
end)

-- Update info setiap detik
task.spawn(function()
    while true do
        roundInfoLabel.Text = getRoundInfo()
        mapLabel.Text = "📍 Map: " .. getMapName()
        task.wait(1)
    end
end)

-- Floating Button
local FloatBtn = Instance.new("TextButton", ScreenGui)
FloatBtn.Size = UDim2.new(0,48,0,48); FloatBtn.Position = UDim2.new(0,12,0.5,-24)
FloatBtn.BackgroundColor3 = C.accent; FloatBtn.Text = "🔪"; FloatBtn.TextSize = 22
Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(1,0)
local dragging = false; local dragStart; local posStart
FloatBtn.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = inp.Position; posStart = FloatBtn.Position
    end
end)
FloatBtn.InputEnded:Connect(function() dragging = false end)
UserInputService.InputChanged:Connect(function(inp)
    if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = inp.Position - dragStart
        FloatBtn.Position = UDim2.new(0, math.clamp(posStart.X.Offset + delta.X, 0, Camera.ViewportSize.X - 48),
                                       0, math.clamp(posStart.Y.Offset + delta.Y, 0, Camera.ViewportSize.Y - 48))
    end
end)
FloatBtn.MouseButton1Click:Connect(function()
    Main.Visible = not Main.Visible
    if Main.Visible then
        TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Back), {Size = UDim2.new(0,400,0,540)}):Play()
    else
        TweenService:Create(Main, TweenInfo.new(0.2), {Size = UDim2.new(0,0,0,0)}):Play()
        task.wait(0.2)
    end
end)

-- Drag Main
do
    local dragMain = false; local dragStartM; local frameStart
    Header.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragMain = true; dragStartM = inp.Position; frameStart = Main.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then dragMain = false end
            end)
        end
    end)
    RunService.RenderStepped:Connect(function()
        if dragMain then
            local mouse = UserInputService:GetMouseLocation()
            local vp = Camera.ViewportSize; local sz = Main.AbsoluteSize
            Main.Position = UDim2.new(0, math.clamp(frameStart.X.Offset + (mouse.X - dragStartM.X), 0, vp.X - sz.X),
                                       0, math.clamp(frameStart.Y.Offset + (mouse.Y - dragStartM.Y), 0, vp.Y - sz.Y))
        end
    end)
end

print("[Putzzdev] MM2 Script Loaded - Fitur ESP, Auto Coin, Survival, Info")