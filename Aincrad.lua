-- ╔══════════════════════════════════════════════╗
-- ║         PUTZZDEV | MURDER MYSTERY 2          ║
-- ║   ESP, Coins, Survival, Info                 ║
-- ╚══════════════════════════════════════════════╝

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Camera           = workspace.CurrentCamera
local LocalPlayer      = Players.LocalPlayer

-- ================== WARNA ==================
local C = {
    bg       = Color3.fromRGB(8,   10,  18),
    panel    = Color3.fromRGB(14,  17,  28),
    card     = Color3.fromRGB(20,  24,  38),
    border   = Color3.fromRGB(40,  48,  70),
    text     = Color3.fromRGB(230, 230, 240),
    subtext  = Color3.fromRGB(120, 130, 160),
    white    = Color3.fromRGB(255, 255, 255),
    accent   = Color3.fromRGB(220, 50,  50),
    accentB  = Color3.fromRGB(50,  150, 255),
    accentG  = Color3.fromRGB(50,  220, 120),
    accentY  = Color3.fromRGB(255, 210, 50),
    murderer = Color3.fromRGB(255, 50,  50),
    sheriff  = Color3.fromRGB(50,  150, 255),
    innocent = Color3.fromRGB(50,  220, 120),
    coin     = Color3.fromRGB(255, 210, 50),
}

-- ================== STATE ==================
local espEnabled        = false
local gunESPEnabled     = false
local coinESPEnabled    = false
local autoCollect       = false
local highlightMurder   = false
local highlightSheriff  = false
local notifMurderer     = false
local autoDodge         = false
local autoPickupGun     = false
local lastNotifTime     = 0

local collectConn  = nil
local notifConn    = nil
local dodgeConn    = nil
local pickupConn   = nil
local gunESPConn   = nil

-- ================== ROLE DETECTION ==================
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

local function getRoleColor(player)
    local role = getRole(player)
    if role == "Murderer" then return C.murderer, "☠"
    elseif role == "Sheriff" then return C.sheriff, "⭐"
    else return C.innocent, "" end
end

-- ================== DRAWING HELPER ==================
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

-- ================== ESP PLAYER ==================
local espLines, espBoxes, espNames = {}, {}, {}

local function initESP(p)
    if p == LocalPlayer then return end
    espLines[p] = newLine(C.innocent)
    espBoxes[p] = newBox(C.innocent)
    espNames[p] = newText(C.white, 13)
end
local function removeESP(p)
    if espLines[p] then espLines[p]:Remove(); espLines[p] = nil end
    if espBoxes[p] then espBoxes[p]:Remove(); espBoxes[p] = nil end
    if espNames[p] then espNames[p]:Remove(); espNames[p] = nil end
end
for _, p in pairs(Players:GetPlayers()) do initESP(p) end
Players.PlayerAdded:Connect(initESP)
Players.PlayerRemoving:Connect(removeESP)

-- ================== HIGHLIGHT SYSTEM ==================
local playerHighlights = {}

local function clearHighlights()
    for _, hl in pairs(playerHighlights) do
        pcall(function() hl:Destroy() end)
    end
    playerHighlights = {}
end

local function updateHighlights()
    clearHighlights()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local role = getRole(p)
            local show = (role == "Murderer" and highlightMurder) or (role == "Sheriff" and highlightSheriff)
            if show then
                local hl = Instance.new("Highlight")
                hl.FillColor           = role == "Murderer" and C.murderer or C.sheriff
                hl.FillTransparency    = 0.35
                hl.OutlineColor        = role == "Murderer" and Color3.fromRGB(255,100,100) or Color3.fromRGB(100,180,255)
                hl.OutlineTransparency = 0
                hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Enabled             = true
                hl.Parent              = p.Character
                playerHighlights[p]    = hl
            end
        end
    end
end

-- ================== GUN ESP ==================
local gunHighlights = {}

local function updateGunESP(enabled)
    for _, hl in pairs(gunHighlights) do pcall(function() hl:Destroy() end) end
    gunHighlights = {}
    if not enabled then return end
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Tool") and (obj.Name == "Gun" or obj.Name:lower():find("gun")) then
            local hl = Instance.new("Highlight")
            hl.FillColor           = C.coin
            hl.FillTransparency    = 0.3
            hl.OutlineColor        = Color3.fromRGB(255,255,100)
            hl.OutlineTransparency = 0
            hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Enabled             = true
            hl.Parent              = obj
            table.insert(gunHighlights, hl)
        end
    end
end

-- ================== COIN ESP ==================
local coinData = {}

local function initCoinESP()
    for _, d in pairs(coinData) do
        pcall(function() d.label:Remove() end)
        pcall(function() if d.hl then d.hl:Destroy() end end)
    end
    coinData = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name == "Coin" or obj.Name:lower() == "coin") then
            local hl = Instance.new("Highlight")
            hl.FillColor = C.coin; hl.FillTransparency = 0.3
            hl.OutlineColor = Color3.fromRGB(255,255,100); hl.OutlineTransparency = 0
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Enabled = false; hl.Parent = obj
            local lbl = newText(C.coin, 12)
            table.insert(coinData, {obj = obj, hl = hl, label = lbl})
        end
    end
end
initCoinESP()

-- ================== AUTO FARM COIN ==================
local function startAutoCollect()
    if collectConn then collectConn:Disconnect() end
    task.spawn(function()
        while autoCollect do
            local myChar = LocalPlayer.Character
            local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local hum    = myChar and myChar:FindFirstChildOfClass("Humanoid")
            if myHRP and hum then
                local nearest, nearestDist = nil, math.huge
                for _, d in pairs(coinData) do
                    if d.obj and d.obj.Parent then
                        local dist = (myHRP.Position - d.obj.Position).Magnitude
                        if dist < nearestDist then nearestDist = dist; nearest = d.obj end
                    end
                end
                -- Fallback scan
                if not nearest then
                    for _, obj in pairs(workspace:GetDescendants()) do
                        if obj:IsA("BasePart") and (obj.Name == "Coin" or obj.Name:lower() == "coin") then
                            local dist = (myHRP.Position - obj.Position).Magnitude
                            if dist < nearestDist then nearestDist = dist; nearest = obj end
                        end
                    end
                end
                if nearest and nearestDist > 3 then
                    hum:MoveTo(nearest.Position)
                end
            end
            task.wait(0.6)
        end
    end)
end

-- ================== AUTO DODGE ==================
local function startAutoDodge()
    if dodgeConn then dodgeConn:Disconnect() end
    dodgeConn = RunService.Heartbeat:Connect(function()
        if not autoDodge then return end
        local myChar = LocalPlayer.Character
        local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not obj.Anchored then
                local name = obj.Name:lower()
                if name:find("knife") or name:find("throw") or name:find("blade") then
                    local vel  = obj.AssemblyLinearVelocity
                    local dist = (myHRP.Position - obj.Position).Magnitude
                    if vel.Magnitude > 5 and dist < 18 then
                        local toMe = (myHRP.Position - obj.Position).Unit
                        if vel.Unit:Dot(toMe) > 0.6 then
                            local dirs = {Vector3.new(10,2,0), Vector3.new(-10,2,0), Vector3.new(0,2,10), Vector3.new(0,2,-10)}
                            local pick = dirs[math.random(1,#dirs)]
                            myHRP.CFrame = CFrame.new(myHRP.Position + pick)
                        end
                    end
                end
            end
        end
        -- Dodge dari murderer throw
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and getRole(p) == "Murderer" then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local dist = (myHRP.Position - hrp.Position).Magnitude
                    if dist < 22 and not p.Character:FindFirstChild("Knife") then
                        local away = (myHRP.Position - hrp.Position).Unit
                        myHRP.CFrame = CFrame.new(myHRP.Position + Vector3.new(away.X*8, 2, away.Z*8))
                    end
                end
            end
        end
    end)
end

-- ================== AUTO PICKUP GUN ==================
local function startAutoPickup()
    if pickupConn then pickupConn:Disconnect() end
    task.spawn(function()
        while autoPickupGun do
            local myChar = LocalPlayer.Character
            local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local hum    = myChar and myChar:FindFirstChildOfClass("Humanoid")
            if myHRP and hum then
                local nearest, nearestDist = nil, math.huge
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj:IsA("Tool") and (obj.Name == "Gun" or obj.Name:lower():find("gun")) then
                        local bp = obj.Parent
                        if bp and not bp:IsA("Model") then
                            local part = obj:FindFirstChildWhichIsA("BasePart")
                            if part then
                                local dist = (myHRP.Position - part.Position).Magnitude
                                if dist < nearestDist then nearestDist = dist; nearest = part end
                            end
                        end
                    end
                end
                if nearest and nearestDist > 3 then
                    hum:MoveTo(nearest.Position)
                end
            end
            task.wait(0.5)
        end
    end)
end

-- ================== MURDER ALERT ==================
local function startMurderAlert()
    if notifConn then notifConn:Disconnect() end
    notifConn = RunService.Heartbeat:Connect(function()
        if not notifMurderer then return end
        local myChar = LocalPlayer.Character
        local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end
        local now = tick()
        if now - lastNotifTime < 3 then return end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and getRole(p) == "Murderer" then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp and (myHRP.Position - hrp.Position).Magnitude < 30 then
                    lastNotifTime = now
                    local gui = Instance.new("ScreenGui")
                    gui.Name = "MurderAlert"; gui.ResetOnSpawn = false
                    gui.Parent = game:GetService("CoreGui")
                    local f = Instance.new("Frame", gui)
                    f.Size = UDim2.new(0, 290, 0, 54)
                    f.Position = UDim2.new(0.5, -145, 0, 55)
                    f.BackgroundColor3 = Color3.fromRGB(35,8,8); f.BorderSizePixel = 0
                    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 12)
                    local fs = Instance.new("UIStroke", f); fs.Color = C.murderer; fs.Thickness = 2
                    local fl = Instance.new("TextLabel", f)
                    fl.Size = UDim2.new(1,0,1,0); fl.BackgroundTransparency = 1
                    fl.Text = "⚠  MURDERER MENDEKAT!"; fl.TextColor3 = C.murderer
                    fl.Font = Enum.Font.GothamBold; fl.TextSize = 16
                    TweenService:Create(f, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
                        Position = UDim2.new(0.5,-145,0,75)
                    }):Play()
                    task.delay(2.5, function() game:GetService("Debris"):AddItem(gui, 0) end)
                end
            end
        end
    end)
end

-- ================== MAIN RENDER LOOP ==================
RunService.RenderStepped:Connect(function()
    local vp     = Camera.ViewportSize
    local myChar = LocalPlayer.Character
    local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myPos  = myHRP and myHRP.Position

    -- Update highlights
    if highlightMurder or highlightSheriff then updateHighlights() end

    -- Player ESP
    for player, line in pairs(espLines) do
        local char = player.Character
        local head = char and char:FindFirstChild("Head")
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if espEnabled and head and hrp and myPos then
            local sp, vis = Camera:WorldToViewportPoint(head.Position)
            local dist    = math.floor((myPos - hrp.Position).Magnitude)
            local roleColor, roleIcon = getRoleColor(player)
            line.Color = roleColor; espBoxes[player].Color = roleColor
            if vis then
                line.From = Vector2.new(vp.X/2, vp.Y)
                line.To   = Vector2.new(sp.X, sp.Y)
                line.Visible = true
                local topSP = Camera:WorldToViewportPoint(head.Position + Vector3.new(0,0.7,0))
                local botSP = Camera:WorldToViewportPoint(hrp.Position  - Vector3.new(0,3,0))
                local h = math.abs(topSP.Y - botSP.Y); local w = h/2
                local box = espBoxes[player]
                box.Size = Vector2.new(w, h); box.Position = Vector2.new(sp.X - w/2, topSP.Y); box.Visible = true
                local nm = espNames[player]
                local tag = roleIcon ~= "" and (" " .. roleIcon) or ""
                nm.Color = roleColor; nm.Position = Vector2.new(sp.X, topSP.Y - 17)
                nm.Text = player.Name .. tag .. " [" .. dist .. "m]"; nm.Visible = true
            else
                line.Visible = false; espBoxes[player].Visible = false; espNames[player].Visible = false
            end
        else
            if espLines[player]  then espLines[player].Visible  = false end
            if espBoxes[player]  then espBoxes[player].Visible  = false end
            if espNames[player]  then espNames[player].Visible  = false end
        end
    end

    -- Coin ESP
    for _, d in pairs(coinData) do
        if d.obj and d.obj.Parent and coinESPEnabled and myPos then
            local sp, vis = Camera:WorldToViewportPoint(d.obj.Position)
            local dist    = math.floor((myPos - d.obj.Position).Magnitude)
            if vis then
                d.label.Position = Vector2.new(sp.X, sp.Y - 14)
                d.label.Text     = "💰 [" .. dist .. "m]"
                d.label.Visible  = true
                d.hl.Enabled     = true
            else
                d.label.Visible = false; d.hl.Enabled = false
            end
        else
            d.label.Visible = false
            if d.hl then d.hl.Enabled = false end
        end
    end
end)

-- ================== UI ==================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PutzzdevMM2"; ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

-- Main Frame
local Main = Instance.new("Frame")
Main.Name = "Main"; Main.Size = UDim2.new(0, 390, 0, 530)
Main.Position = UDim2.new(0.5, -195, 0.5, -265)
Main.BackgroundColor3 = C.bg; Main.BorderSizePixel = 0
Main.ClipsDescendants = true; Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)
local mainStroke = Instance.new("UIStroke", Main)
mainStroke.Color = C.accent; mainStroke.Thickness = 1.5

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 52); Header.BackgroundColor3 = Color3.fromRGB(12,10,20)
Header.BorderSizePixel = 0; Header.Parent = Main
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 14)

local accentLine = Instance.new("Frame", Header)
accentLine.Size = UDim2.new(1,0,0,2); accentLine.Position = UDim2.new(0,0,1,-2)
accentLine.BackgroundColor3 = C.accent; accentLine.BorderSizePixel = 0
local hg = Instance.new("UIGradient", accentLine)
hg.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255,50,50)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255,150,50)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255,50,50)),
})

local iconF = Instance.new("Frame", Header)
iconF.Size = UDim2.new(0,32,0,32); iconF.Position = UDim2.new(0,12,0.5,-16)
iconF.BackgroundColor3 = C.accent; iconF.BorderSizePixel = 0
Instance.new("UICorner", iconF).CornerRadius = UDim.new(0,8)
local iconL = Instance.new("TextLabel", iconF)
iconL.Size = UDim2.new(1,0,1,0); iconL.BackgroundTransparency = 1
iconL.Text = "🔪"; iconL.TextSize = 18; iconL.Font = Enum.Font.GothamBold

local titleL = Instance.new("TextLabel", Header)
titleL.Size = UDim2.new(0.6,0,0,22); titleL.Position = UDim2.new(0,54,0,7)
titleL.BackgroundTransparency = 1; titleL.Text = "MURDER MYSTERY 2"
titleL.TextColor3 = C.white; titleL.Font = Enum.Font.GothamBold
titleL.TextSize = 14; titleL.TextXAlignment = Enum.TextXAlignment.Left

local devL = Instance.new("TextLabel", Header)
devL.Size = UDim2.new(0.6,0,0,18); devL.Position = UDim2.new(0,54,1,-23)
devL.BackgroundTransparency = 1; devL.Text = "✦ Putzzdev"
devL.TextColor3 = Color3.fromRGB(255,160,60); devL.Font = Enum.Font.GothamBold
devL.TextSize = 13; devL.TextXAlignment = Enum.TextXAlignment.Left
TweenService:Create(devL, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
    TextColor3 = Color3.fromRGB(255,220,100)
}):Play()

local closeBtn = Instance.new("TextButton", Header)
closeBtn.Size = UDim2.new(0,28,0,28); closeBtn.Position = UDim2.new(1,-38,0.5,-14)
closeBtn.BackgroundColor3 = Color3.fromRGB(60,20,20); closeBtn.BorderSizePixel = 0
closeBtn.Text = "✕"; closeBtn.TextColor3 = C.accent
closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 14
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,6)
closeBtn.MouseButton1Click:Connect(function()
    TweenService:Create(Main, TweenInfo.new(0.2), {Size = UDim2.new(0,0,0,0)}):Play()
    task.wait(0.25); Main.Visible = false
end)

-- Tab Bar
local tabNames = {"ESP", "COINS", "SURVIVAL", "INFO"}
local tabBtns, tabContents = {}, {}
local activeTab = "ESP"

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1,-24,0,34); TabBar.Position = UDim2.new(0,12,0,58)
TabBar.BackgroundColor3 = C.card; TabBar.BorderSizePixel = 0; TabBar.Parent = Main
Instance.new("UICorner", TabBar).CornerRadius = UDim.new(0,10)
local tbl = Instance.new("UIListLayout", TabBar)
tbl.FillDirection = Enum.FillDirection.Horizontal; tbl.Padding = UDim.new(0,2)
local tbp = Instance.new("UIPadding", TabBar)
tbp.PaddingLeft = UDim.new(0,3); tbp.PaddingRight = UDim.new(0,3)
tbp.PaddingTop  = UDim.new(0,3); tbp.PaddingBottom = UDim.new(0,3)

local function makeContent(name)
    local s = Instance.new("ScrollingFrame")
    s.Name = name; s.Size = UDim2.new(1,-24,1,-106); s.Position = UDim2.new(0,12,0,100)
    s.BackgroundTransparency = 1; s.BorderSizePixel = 0
    s.ScrollBarThickness = 3; s.ScrollBarImageColor3 = C.accent
    s.Visible = (name == "ESP"); s.Parent = Main
    local l = Instance.new("UIListLayout", s)
    l.Padding = UDim.new(0,8); l.HorizontalAlignment = Enum.HorizontalAlignment.Center
    local p = Instance.new("UIPadding", s)
    p.PaddingTop = UDim.new(0,8); p.PaddingBottom = UDim.new(0,8)
    l:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        s.CanvasSize = UDim2.new(0,0,0, l.AbsoluteContentSize.Y + 20)
    end)
    return s
end

for _, name in ipairs(tabNames) do
    tabContents[name] = makeContent(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1/#tabNames, -2, 1, 0)
    btn.BackgroundColor3 = name == "ESP" and C.accent or C.card
    btn.BackgroundTransparency = name == "ESP" and 0 or 1
    btn.BorderSizePixel = 0; btn.Text = name
    btn.TextColor3 = name == "ESP" and C.white or C.subtext
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 11; btn.Parent = TabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
    tabBtns[name] = btn
    btn.MouseButton1Click:Connect(function()
        activeTab = name
        for n, b in pairs(tabBtns) do
            local active = n == name
            TweenService:Create(b, TweenInfo.new(0.15), {
                BackgroundTransparency = active and 0 or 1,
                BackgroundColor3 = C.accent,
                TextColor3 = active and C.white or C.subtext,
            }):Play()
            tabContents[n].Visible = active
        end
    end)
end

-- ================== UI HELPERS ==================
local function sectionLbl(parent, text)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(0.95,0,0,20); f.BackgroundTransparency = 1
    local l = Instance.new("TextLabel", f)
    l.Size = UDim2.new(1,0,1,0); l.BackgroundTransparency = 1
    l.Text = text; l.TextColor3 = C.subtext; l.Font = Enum.Font.GothamBold
    l.TextSize = 10; l.TextXAlignment = Enum.TextXAlignment.Left
end

local function createToggle(parent, label, color, callback)
    local card = Instance.new("Frame", parent)
    card.Size = UDim2.new(0.95,0,0,46); card.BackgroundColor3 = C.card; card.BorderSizePixel = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0,10)
    local stroke = Instance.new("UIStroke", card); stroke.Color = C.border; stroke.Thickness = 1
    local lbl = Instance.new("TextLabel", card)
    lbl.Size = UDim2.new(0.65,0,1,0); lbl.Position = UDim2.new(0,14,0,0)
    lbl.BackgroundTransparency = 1; lbl.Text = label; lbl.TextColor3 = C.text
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 13; lbl.TextXAlignment = Enum.TextXAlignment.Left
    local sw = Instance.new("Frame", card)
    sw.Size = UDim2.new(0,46,0,24); sw.Position = UDim2.new(1,-56,0.5,-12)
    sw.BackgroundColor3 = C.border; sw.BorderSizePixel = 0
    Instance.new("UICorner", sw).CornerRadius = UDim.new(1,0)
    local dot = Instance.new("Frame", sw)
    dot.Size = UDim2.new(0,18,0,18); dot.Position = UDim2.new(0,3,0.5,-9)
    dot.BackgroundColor3 = C.white; dot.BorderSizePixel = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)
    local state = false
    local hit = Instance.new("TextButton", card)
    hit.Size = UDim2.new(1,0,1,0); hit.BackgroundTransparency = 1; hit.Text = ""
    hit.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(sw, TweenInfo.new(0.18), {BackgroundColor3 = state and color or C.border}):Play()
        TweenService:Create(dot, TweenInfo.new(0.18), {
            Position = state and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9)
        }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.18), {Color = state and color or C.border}):Play()
        callback(state)
    end)
end

local function createButton(parent, label, color, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(0.95,0,0,42); btn.BackgroundColor3 = C.card
    btn.BorderSizePixel = 0; btn.Text = label; btn.TextColor3 = color
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 13
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,10)
    local stroke = Instance.new("UIStroke", btn); stroke.Color = color; stroke.Thickness = 1
    btn.MouseButton1Click:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = color, TextColor3 = C.bg}):Play()
        task.wait(0.12)
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = C.card, TextColor3 = color}):Play()
        callback()
    end)
end

-- ================== ESP TAB ==================
sectionLbl(tabContents["ESP"], "  PLAYER")
createToggle(tabContents["ESP"], "Player ESP", C.innocent, function(s) espEnabled = s end)
createToggle(tabContents["ESP"], "Murderer ESP (Highlight Merah)", C.murderer, function(s)
    highlightMurder = s
    if not s then clearHighlights() end
end)
createToggle(tabContents["ESP"], "Sheriff ESP (Highlight Biru)", C.sheriff, function(s)
    highlightSheriff = s
    if not s then clearHighlights() end
end)

sectionLbl(tabContents["ESP"], "  OBJECTS")
createToggle(tabContents["ESP"], "Gun ESP (Lokasi Gun di Map)", C.accentY, function(s)
    gunESPEnabled = s
    updateGunESP(s)
    if s then
        if gunESPConn then gunESPConn:Disconnect() end
        task.spawn(function()
            while gunESPEnabled do updateGunESP(true); task.wait(2) end
        end)
    end
end)

sectionLbl(tabContents["ESP"], "  ROLE")
createButton(tabContents["ESP"], "🔍 Role Detector", C.accentY, function()
    local role = getRole(LocalPlayer)
    local rc   = role == "Murderer" and C.murderer or role == "Sheriff" and C.sheriff or C.innocent
    local ri   = role == "Murderer" and "☠" or role == "Sheriff" and "⭐" or "😇"
    local gui  = Instance.new("ScreenGui"); gui.Name = "RoleNotif"; gui.ResetOnSpawn = false
    gui.Parent = game:GetService("CoreGui")
    local f = Instance.new("Frame", gui)
    f.Size = UDim2.new(0,270,0,60); f.Position = UDim2.new(0.5,-135,0,55)
    f.BackgroundColor3 = C.card; f.BorderSizePixel = 0
    Instance.new("UICorner", f).CornerRadius = UDim.new(0,12)
    local fs = Instance.new("UIStroke", f); fs.Color = rc; fs.Thickness = 2
    local fl = Instance.new("TextLabel", f)
    fl.Size = UDim2.new(1,0,1,0); fl.BackgroundTransparency = 1
    fl.Text = ri .. "  Role kamu: " .. role; fl.TextColor3 = rc
    fl.Font = Enum.Font.GothamBold; fl.TextSize = 16
    TweenService:Create(f, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Position = UDim2.new(0.5,-135,0,75)}):Play()
    task.delay(3, function() game:GetService("Debris"):AddItem(gui, 0) end)
end)

-- ================== COINS TAB ==================
sectionLbl(tabContents["COINS"], "  COIN")
createToggle(tabContents["COINS"], "Coin ESP (Hologram)", C.coin, function(s)
    coinESPEnabled = s; initCoinESP()
end)
createToggle(tabContents["COINS"], "Auto Farm Coin", C.accentG, function(s)
    autoCollect = s
    if s then startAutoCollect() end
end)
createButton(tabContents["COINS"], "🔄 Refresh Coin ESP", C.coin, function()
    initCoinESP()
end)

-- ================== SURVIVAL TAB ==================
sectionLbl(tabContents["SURVIVAL"], "  ALERT")
createToggle(tabContents["SURVIVAL"], "Murderer Alert (< 30m)", C.murderer, function(s)
    notifMurderer = s
    if s then startMurderAlert()
    elseif notifConn then notifConn:Disconnect(); notifConn = nil end
end)

sectionLbl(tabContents["SURVIVAL"], "  PICKUP & DODGE")
createToggle(tabContents["SURVIVAL"], "Auto Pickup Gun", C.sheriff, function(s)
    autoPickupGun = s
    if s then startAutoPickup()
    elseif pickupConn then pickupConn:Disconnect(); pickupConn = nil end
end)
createToggle(tabContents["SURVIVAL"], "Auto Dodge Pisau", C.accentY, function(s)
    autoDodge = s
    if s then startAutoDodge()
    elseif dodgeConn then dodgeConn:Disconnect(); dodgeConn = nil end
end)
createButton(tabContents["SURVIVAL"], "🏃 Kabur dari Murderer", C.accentG, function()
    local mc = LocalPlayer.Character
    local mh = mc and mc:FindFirstChild("HumanoidRootPart")
    if not mh then return end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and getRole(p) == "Murderer" then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dir = (mh.Position - hrp.Position).Unit
                mh.CFrame = CFrame.new(mh.Position + dir * 65)
            end; break
        end
    end
end)

-- ================== INFO TAB ==================
sectionLbl(tabContents["INFO"], "  ROUND INFO")

local infoCard = Instance.new("Frame", tabContents["INFO"])
infoCard.Size = UDim2.new(0.95,0,0,200); infoCard.BackgroundColor3 = C.card; infoCard.BorderSizePixel = 0
Instance.new("UICorner", infoCard).CornerRadius = UDim.new(0,10)
Instance.new("UIStroke", infoCard).Color = C.border
local infoLL = Instance.new("UIListLayout", infoCard); infoLL.Padding = UDim.new(0,4)
local infoP = Instance.new("UIPadding", infoCard)
infoP.PaddingTop = UDim.new(0,10); infoP.PaddingLeft = UDim.new(0,14)
infoP.PaddingRight = UDim.new(0,14); infoP.PaddingBottom = UDim.new(0,10)

local function infoRow(txt, color)
    local l = Instance.new("TextLabel", infoCard)
    l.Size = UDim2.new(1,0,0,26); l.BackgroundTransparency = 1
    l.Text = txt; l.TextColor3 = color or C.text
    l.Font = Enum.Font.GothamBold; l.TextSize = 13
    l.TextXAlignment = Enum.TextXAlignment.Left
    return l
end

local rRole    = infoRow("🎭 Role: —",      C.text)
local rAlive   = infoRow("💚 Alive: —",     C.innocent)
local rMurder  = infoRow("☠ Murderer: —",  C.murderer)
local rSheriff = infoRow("⭐ Sheriff: —",   C.sheriff)
local rMap     = infoRow("🗺 Map: —",       C.subtext)
local rPlayers = infoRow("👥 Players: —",   C.subtext)
local rAliveCount = infoRow("🔢 Alive Count: —", C.accentY)

infoLL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    infoCard.Size = UDim2.new(0.95, 0, 0, infoLL.AbsoluteContentSize.Y + 20)
end)

task.spawn(function()
    while true do
        pcall(function()
            local myRole   = getRole(LocalPlayer)
            local rc       = myRole == "Murderer" and C.murderer or myRole == "Sheriff" and C.sheriff or C.innocent
            local ri       = myRole == "Murderer" and "☠" or myRole == "Sheriff" and "⭐" or "😇"
            rRole.Text     = ri .. " Role: " .. myRole; rRole.TextColor3 = rc

            local alive = 0; local total = 0; local murderName = "?"; local sheriffName = "?"
            for _, p in pairs(Players:GetPlayers()) do
                total = total + 1
                if p.Character then
                    local h = p.Character:FindFirstChildOfClass("Humanoid")
                    if h and h.Health > 0 then alive = alive + 1 end
                end
                local r = getRole(p)
                if r == "Murderer" then murderName = p.Name end
                if r == "Sheriff"  then sheriffName = p.Name end
            end
            rAlive.Text     = "💚 Alive: " .. alive .. "/" .. total
            rAliveCount.Text = "🔢 Alive Count: " .. alive
            rMurder.Text    = "☠ Murderer: " .. murderName
            rSheriff.Text   = "⭐ Sheriff: " .. sheriffName
            rPlayers.Text   = "👥 Players: " .. total

            -- Deteksi map dari nama model terbesar di workspace
            local mapName = "?"
            for _, v in pairs(workspace:GetChildren()) do
                if v:IsA("Model") and v.Name ~= "Camera" and not Players:GetPlayerFromCharacter(v) then
                    mapName = v.Name; break
                end
            end
            rMap.Text = "🗺 Map: " .. mapName
        end)
        task.wait(1.5)
    end
end)

createButton(tabContents["INFO"], "🔄 Refresh Info", C.accentB, function() end)

-- ================== PLAYER LIST (bawah INFO) ==================
sectionLbl(tabContents["INFO"], "  TELEPORT KE PLAYER")

local plCard = Instance.new("Frame", tabContents["INFO"])
plCard.Size = UDim2.new(0.95,0,0,260); plCard.BackgroundColor3 = C.card; plCard.BorderSizePixel = 0
Instance.new("UICorner", plCard).CornerRadius = UDim.new(0,10)
Instance.new("UIStroke", plCard).Color = C.border

local plScroll = Instance.new("ScrollingFrame", plCard)
plScroll.Size = UDim2.new(1,-10,1,-10); plScroll.Position = UDim2.new(0,5,0,5)
plScroll.BackgroundTransparency = 1; plScroll.BorderSizePixel = 0
plScroll.ScrollBarThickness = 3; plScroll.ScrollBarImageColor3 = C.accent
local plL = Instance.new("UIListLayout", plScroll)
plL.Padding = UDim.new(0,5); plL.HorizontalAlignment = Enum.HorizontalAlignment.Center
local plP = Instance.new("UIPadding", plScroll)
plP.PaddingTop = UDim.new(0,5); plP.PaddingBottom = UDim.new(0,5)
plL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    plScroll.CanvasSize = UDim2.new(0,0,0, plL.AbsoluteContentSize.Y + 10)
end)

local function refreshPlayers()
    for _, c in pairs(plScroll:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end
    end
    local rb = Instance.new("TextButton", plScroll)
    rb.Size = UDim2.new(0.9,0,0,30); rb.BackgroundColor3 = Color3.fromRGB(0,120,80)
    rb.BorderSizePixel = 0; rb.Text = "🔄 REFRESH"; rb.TextColor3 = C.white
    rb.Font = Enum.Font.GothamBold; rb.TextSize = 12
    Instance.new("UICorner", rb).CornerRadius = UDim.new(0,8)
    rb.MouseButton1Click:Connect(refreshPlayers)

    local count = 0
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            count = count + 1
            local roleColor, roleIcon = getRoleColor(p)
            local row = Instance.new("Frame", plScroll)
            row.Size = UDim2.new(0.9,0,0,46); row.BackgroundColor3 = C.bg; row.BorderSizePixel = 0
            Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
            Instance.new("UIStroke", row).Color = C.border
            local nl = Instance.new("TextLabel", row)
            nl.Size = UDim2.new(0.55,0,1,0); nl.Position = UDim2.new(0,10,0,0)
            nl.BackgroundTransparency = 1
            nl.Text = (roleIcon ~= "" and roleIcon .. " " or "") .. p.Name
            nl.TextColor3 = roleColor; nl.Font = Enum.Font.GothamBold
            nl.TextSize = 12; nl.TextXAlignment = Enum.TextXAlignment.Left
            local tpBtn = Instance.new("TextButton", row)
            tpBtn.Size = UDim2.new(0,80,0,28); tpBtn.Position = UDim2.new(1,-88,0.5,-14)
            tpBtn.BackgroundColor3 = C.accent; tpBtn.BorderSizePixel = 0
            tpBtn.Text = "TELEPORT"; tpBtn.TextColor3 = C.white
            tpBtn.Font = Enum.Font.GothamBold; tpBtn.TextSize = 11
            Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0,6)
            local target = p
            tpBtn.MouseButton1Click:Connect(function()
                local mc = LocalPlayer.Character; local tc = target.Character
                if mc and tc then
                    local mh = mc:FindFirstChild("HumanoidRootPart")
                    local th = tc:FindFirstChild("HumanoidRootPart")
                    if mh and th then mh.CFrame = th.CFrame + Vector3.new(0,4,0) end
                end
            end)
        end
    end
    if count == 0 then
        local el = Instance.new("TextLabel", plScroll)
        el.Size = UDim2.new(0.9,0,0,36); el.BackgroundTransparency = 1
        el.Text = "Tidak ada player lain"; el.TextColor3 = C.subtext
        el.Font = Enum.Font.Gotham; el.TextSize = 12
    end
end

refreshPlayers()
Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(refreshPlayers)

-- ================== FLOATING BUTTON ==================
local FloatBtn = Instance.new("TextButton", ScreenGui)
FloatBtn.Size = UDim2.new(0,48,0,48); FloatBtn.Position = UDim2.new(0,12,0.5,-24)
FloatBtn.BackgroundColor3 = C.accent; FloatBtn.BorderSizePixel = 0
FloatBtn.Text = "🔪"; FloatBtn.TextSize = 22; FloatBtn.ZIndex = 10
Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(1,0)
local fStroke = Instance.new("UIStroke", FloatBtn); fStroke.Color = Color3.fromRGB(255,150,50); fStroke.Thickness = 2
TweenService:Create(fStroke, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Thickness = 4}):Play()

-- Drag float btn
do
    local drag = false; local sx, sy, px, py = 0, 0, 0, 0
    FloatBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            drag = true; sx = inp.Position.X; sy = inp.Position.Y
            px = FloatBtn.Position.X.Offset; py = FloatBtn.Position.Y.Offset
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then drag = false end
            end)
        end
    end)
    RunService.RenderStepped:Connect(function()
        if not drag then return end
        local m  = UserInputService:GetMouseLocation()
        local vp = Camera.ViewportSize
        FloatBtn.Position = UDim2.new(0,
            math.clamp(px + (m.X - sx), 0, vp.X - 48), 0,
            math.clamp(py + (m.Y - sy), 0, vp.Y - 48)
        )
    end)
end

local menuOpen = true
FloatBtn.MouseButton1Click:Connect(function()
    menuOpen = not menuOpen
    if menuOpen then
        Main.Visible = true
        TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Back), {Size = UDim2.new(0,390,0,530)}):Play()
    else
        TweenService:Create(Main, TweenInfo.new(0.2), {Size = UDim2.new(0,0,0,0)}):Play()
        task.wait(0.25); Main.Visible = false
    end
end)

-- Drag main menu dari header
do
    local drag = false; local sx, sy, px, py = 0, 0, 0, 0
    Header.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            drag = true; sx = inp.Position.X; sy = inp.Position.Y
            px = Main.Position.X.Offset; py = Main.Position.Y.Offset
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then drag = false end
            end)
        end
    end)
    RunService.RenderStepped:Connect(function()
        if not drag then return end
        local m  = UserInputService:GetMouseLocation()
        local vp = Camera.ViewportSize
        local sz = Main.AbsoluteSize
        Main.Position = UDim2.new(0,
            math.clamp(px + (m.X - sx), 0, vp.X - sz.X), 0,
            math.clamp(py + (m.Y - sy), 0, vp.Y - sz.Y)
        )
    end)
end

print("[Putzzdev] MM2 Script loaded! 🔪")
