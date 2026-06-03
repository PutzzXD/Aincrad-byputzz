-- ╔══════════════════════════════════════════════╗
-- ║         PUTZZDEV | MURDER MYSTERY 2          ║
-- ║     ESP Murderer, Sheriff, Coins, Player     ║
-- ║          Teleport, Auto Collect              ║
-- ╚══════════════════════════════════════════════╝

local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local TweenService  = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Camera        = workspace.CurrentCamera
local LocalPlayer   = Players.LocalPlayer

-- ================== WARNA TEMA ==================
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
}

-- ================== STATE ==================
local espEnabled      = false
local coinESPEnabled  = false
local autoCollect     = false
local highlightMurder = false

-- ================== ESP TABLES ==================
local espLines    = {}
local espBoxes    = {}
local espNames    = {}
local coinLabels  = {}
local coinHighlights = {}

-- ================== FUNGSI ROLE ==================
local function getRole(player)
    -- Cek via StringValue "Role" di player
    local rv = player:FindFirstChild("Role")
    if rv and rv:IsA("StringValue") then
        return rv.Value
    end
    -- Cek via tool di karakter
    if player.Character then
        if player.Character:FindFirstChild("Knife") then return "Murderer" end
        if player.Character:FindFirstChild("Gun")   then return "Sheriff"  end
    end
    -- Cek via Backpack
    local bp = player:FindFirstChild("Backpack")
    if bp then
        if bp:FindFirstChild("Knife") then return "Murderer" end
        if bp:FindFirstChild("Gun")   then return "Sheriff"  end
    end
    return "Innocent"
end

local function getRoleColor(player)
    local role = getRole(player)
    if role == "Murderer" then return C.murderer, "☠ MURDERER"
    elseif role == "Sheriff" then return C.sheriff, "⭐ SHERIFF"
    else return C.innocent, ""
    end
end

-- ================== DRAWING HELPER ==================
local function newLine(color)
    local l = Drawing.new("Line")
    l.Thickness = 1.5
    l.Color     = color
    l.Visible   = false
    return l
end

local function newBox(color)
    local b = Drawing.new("Square")
    b.Thickness = 1.8
    b.Color     = color
    b.Filled    = false
    b.Visible   = false
    return b
end

local function newText(color, size)
    local t = Drawing.new("Text")
    t.Size         = size or 13
    t.Color        = color
    t.Center       = true
    t.Outline      = true
    t.OutlineColor = Color3.fromRGB(0, 0, 0)
    t.Visible      = false
    return t
end

-- ================== INIT ESP PLAYER ==================
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

-- ================== INIT COIN ESP ==================
local function initCoinESP()
    for _, v in pairs(coinHighlights) do
        pcall(function() if v and v.Parent then v:Destroy() end end)
    end
    coinHighlights = {}
    for _, l in pairs(coinLabels) do
        pcall(function() l:Remove() end)
    end
    coinLabels = {}

    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "Coin" or obj.Name == "coin" or
           (obj:IsA("BasePart") and obj.Name:lower():find("coin")) then
            -- Highlight hologram
            local hl = Instance.new("Highlight")
            hl.FillColor           = C.coin
            hl.FillTransparency    = 0.3
            hl.OutlineColor        = Color3.fromRGB(255, 255, 150)
            hl.OutlineTransparency = 0
            hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Enabled             = false
            hl.Parent              = obj
            table.insert(coinHighlights, hl)

            -- Label text
            local lbl = newText(C.coin, 12)
            table.insert(coinLabels, {drawing = lbl, obj = obj, hl = hl})
        end
    end
end

initCoinESP()

-- ================== AUTO COLLECT COINS ==================
local collectConn = nil

local function startAutoCollect()
    if collectConn then collectConn:Disconnect() end
    collectConn = RunService.Heartbeat:Connect(function()
        if not autoCollect then return end
        local myChar = LocalPlayer.Character
        local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end

        local nearest, nearestDist = nil, math.huge
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj.Name == "Coin" or obj.Name == "coin" or
               (obj:IsA("BasePart") and obj.Name:lower():find("coin")) then
                if obj:IsA("BasePart") then
                    local d = (myHRP.Position - obj.Position).Magnitude
                    if d < nearestDist then
                        nearestDist = d
                        nearest     = obj
                    end
                end
            end
        end

        if nearest and nearestDist > 2 then
            myHRP.CFrame = CFrame.new(nearest.Position + Vector3.new(0, 2, 0))
        end
    end)
end

-- ================== HIGHLIGHT MURDERER ==================
local murdererHighlights = {}

local function updateMurdererHighlight()
    for p, hl in pairs(murdererHighlights) do
        pcall(function() hl:Destroy() end)
    end
    murdererHighlights = {}

    if not highlightMurder then return end

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local role = getRole(p)
            if role == "Murderer" then
                local hl = Instance.new("Highlight")
                hl.FillColor           = C.murderer
                hl.FillTransparency    = 0.3
                hl.OutlineColor        = Color3.fromRGB(255, 100, 100)
                hl.OutlineTransparency = 0
                hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Enabled             = true
                hl.Parent              = p.Character
                murdererHighlights[p]  = hl
            elseif role == "Sheriff" then
                local hl = Instance.new("Highlight")
                hl.FillColor           = C.sheriff
                hl.FillTransparency    = 0.4
                hl.OutlineColor        = Color3.fromRGB(100, 180, 255)
                hl.OutlineTransparency = 0
                hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Enabled             = true
                hl.Parent              = p.Character
                murdererHighlights[p]  = hl
            end
        end
    end
end

-- ================== UPDATE ESP ==================
RunService.RenderStepped:Connect(function()
    local vp    = Camera.ViewportSize
    local myChar = LocalPlayer.Character
    local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myPos  = myHRP and myHRP.Position

    -- Update highlight murderer tiap frame biar selalu akurat
    if highlightMurder then
        updateMurdererHighlight()
    end

    -- Player ESP
    for player, line in pairs(espLines) do
        local char = player.Character
        local head = char and char:FindFirstChild("Head")
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")

        if espEnabled and head and hrp and myPos then
            local screenPos, vis = Camera:WorldToViewportPoint(head.Position)
            local dist = math.floor((myPos - hrp.Position).Magnitude)
            local roleColor, roleTag = getRoleColor(player)

            line.Color  = roleColor
            espBoxes[player].Color = roleColor

            if vis then
                line.From    = Vector2.new(vp.X / 2, vp.Y)
                line.To      = Vector2.new(screenPos.X, screenPos.Y)
                line.Visible = true

                local topSP    = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.7, 0))
                local botSP    = Camera:WorldToViewportPoint(hrp.Position  - Vector3.new(0, 3,   0))
                local height   = math.abs(topSP.Y - botSP.Y)
                local width    = height / 2
                local box      = espBoxes[player]
                box.Size       = Vector2.new(width, height)
                box.Position   = Vector2.new(screenPos.X - width/2, topSP.Y)
                box.Visible    = true

                local nameD    = espNames[player]
                local roleStr  = roleTag ~= "" and (" " .. roleTag) or ""
                nameD.Color    = roleColor
                nameD.Position = Vector2.new(screenPos.X, topSP.Y - 17)
                nameD.Text     = player.Name .. roleStr .. " [" .. dist .. "m]"
                nameD.Visible  = true
            else
                line.Visible                    = false
                espBoxes[player].Visible        = false
                espNames[player].Visible        = false
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
        local lbl = data.drawing
        local hl  = data.hl

        if obj and obj.Parent and coinESPEnabled then
            local pos = obj:IsA("BasePart") and obj.Position or nil
            if pos and myPos then
                local sp, vis = Camera:WorldToViewportPoint(pos)
                local dist    = math.floor((myPos - pos).Magnitude)
                if vis then
                    lbl.Position = Vector2.new(sp.X, sp.Y - 12)
                    lbl.Text     = "💰 [" .. dist .. "m]"
                    lbl.Visible  = true
                    if hl then hl.Enabled = true end
                else
                    lbl.Visible = false
                    if hl then hl.Enabled = false end
                end
            end
        else
            lbl.Visible = false
            if data.hl then data.hl.Enabled = false end
        end
    end
end)

-- ================== UI ==================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "PutzzdevMM2"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent         = game:GetService("CoreGui")

-- ========= MAIN FRAME =========
local Main = Instance.new("Frame")
Main.Name              = "Main"
Main.Size              = UDim2.new(0, 400, 0, 540)
Main.Position          = UDim2.new(0.5, -200, 0.5, -270)
Main.BackgroundColor3  = C.bg
Main.BorderSizePixel   = 0
Main.ClipsDescendants  = true
Main.Parent            = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)

local mainStroke = Instance.new("UIStroke", Main)
mainStroke.Color     = C.accent
mainStroke.Thickness = 1.5

-- Gradient background
local grad = Instance.new("UIGradient", Main)
grad.Color    = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(8,  10,  20)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(14, 12,  22)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(8,  10,  18)),
})
grad.Rotation = 135

-- ========= HEADER =========
local Header = Instance.new("Frame")
Header.Size             = UDim2.new(1, 0, 0, 52)
Header.BackgroundColor3 = Color3.fromRGB(12, 10, 20)
Header.BorderSizePixel  = 0
Header.Parent           = Main
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 14)

-- Red accent line di bawah header
local accentLine = Instance.new("Frame")
accentLine.Size             = UDim2.new(1, 0, 0, 2)
accentLine.Position         = UDim2.new(0, 0, 1, -2)
accentLine.BackgroundColor3 = C.accent
accentLine.BorderSizePixel  = 0
accentLine.Parent           = Header

local hGrad = Instance.new("UIGradient", accentLine)
hGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 50, 50)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 150, 50)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(255, 50, 50)),
})

-- Icon merah
local icon = Instance.new("Frame")
icon.Size             = UDim2.new(0, 32, 0, 32)
icon.Position         = UDim2.new(0, 12, 0.5, -16)
icon.BackgroundColor3 = C.accent
icon.BorderSizePixel  = 0
icon.Parent           = Header
Instance.new("UICorner", icon).CornerRadius = UDim.new(0, 8)

local iconLabel = Instance.new("TextLabel")
iconLabel.Size                = UDim2.new(1, 0, 1, 0)
iconLabel.BackgroundTransparency = 1
iconLabel.Text                = "🔪"
iconLabel.TextSize            = 18
iconLabel.Font                = Enum.Font.GothamBold
iconLabel.Parent              = icon

local titleLabel = Instance.new("TextLabel")
titleLabel.Size               = UDim2.new(0.6, 0, 1, 0)
titleLabel.Position           = UDim2.new(0, 54, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text               = "MURDER MYSTERY 2"
titleLabel.TextColor3         = C.white
titleLabel.Font               = Enum.Font.GothamBold
titleLabel.TextSize           = 14
titleLabel.TextXAlignment     = Enum.TextXAlignment.Left
titleLabel.Parent             = Header

local devLabel = Instance.new("TextLabel")
devLabel.Size                 = UDim2.new(0.6, 0, 0, 16)
devLabel.Position             = UDim2.new(0, 54, 1, -20)
devLabel.BackgroundTransparency = 1
devLabel.Text                 = "by Putzzdev"
devLabel.TextColor3           = C.accent
devLabel.Font                 = Enum.Font.Gotham
devLabel.TextSize             = 11
devLabel.TextXAlignment       = Enum.TextXAlignment.Left
devLabel.Parent               = Header

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size             = UDim2.new(0, 28, 0, 28)
closeBtn.Position         = UDim2.new(1, -38, 0.5, -14)
closeBtn.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
closeBtn.BorderSizePixel  = 0
closeBtn.Text             = "✕"
closeBtn.TextColor3       = C.accent
closeBtn.Font             = Enum.Font.GothamBold
closeBtn.TextSize         = 14
closeBtn.Parent           = Header
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
closeBtn.MouseButton1Click:Connect(function()
    TweenService:Create(Main, TweenInfo.new(0.2), {Size = UDim2.new(0, 0, 0, 0)}):Play()
    task.wait(0.25)
    Main.Visible = false
end)

-- ========= TABS =========
local tabNames   = {"ESP", "COINS", "PLAYERS"}
local tabBtns    = {}
local tabContents = {}
local activeTab  = "ESP"

local TabBar = Instance.new("Frame")
TabBar.Size             = UDim2.new(1, -24, 0, 34)
TabBar.Position         = UDim2.new(0, 12, 0, 58)
TabBar.BackgroundColor3 = C.card
TabBar.BorderSizePixel  = 0
TabBar.Parent           = Main
Instance.new("UICorner", TabBar).CornerRadius = UDim.new(0, 10)

local tabLayout = Instance.new("UIListLayout", TabBar)
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding       = UDim.new(0, 2)

local tabPad = Instance.new("UIPadding", TabBar)
tabPad.PaddingLeft   = UDim.new(0, 3)
tabPad.PaddingRight  = UDim.new(0, 3)
tabPad.PaddingTop    = UDim.new(0, 3)
tabPad.PaddingBottom = UDim.new(0, 3)

local function createContent(name)
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name                = name
    scroll.Size                = UDim2.new(1, -24, 1, -106)
    scroll.Position            = UDim2.new(0, 12, 0, 100)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel     = 0
    scroll.ScrollBarThickness  = 3
    scroll.ScrollBarImageColor3 = C.accent
    scroll.Visible             = (name == "ESP")
    scroll.Parent              = Main

    local l = Instance.new("UIListLayout", scroll)
    l.Padding               = UDim.new(0, 8)
    l.HorizontalAlignment   = Enum.HorizontalAlignment.Center

    local p = Instance.new("UIPadding", scroll)
    p.PaddingTop    = UDim.new(0, 8)
    p.PaddingBottom = UDim.new(0, 8)

    l:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, l.AbsoluteContentSize.Y + 20)
    end)
    return scroll
end

for _, name in ipairs(tabNames) do
    tabContents[name] = createContent(name)

    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(1/#tabNames, -2, 1, 0)
    btn.BackgroundColor3 = name == "ESP" and C.accent or Color3.fromRGB(0,0,0,0)
    btn.BackgroundTransparency = name == "ESP" and 0 or 1
    btn.BorderSizePixel  = 0
    btn.Text             = name
    btn.TextColor3       = name == "ESP" and C.white or C.subtext
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 12
    btn.Parent           = TabBar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    tabBtns[name] = btn

    btn.MouseButton1Click:Connect(function()
        activeTab = name
        for n, b in pairs(tabBtns) do
            local active = (n == name)
            TweenService:Create(b, TweenInfo.new(0.15), {
                BackgroundTransparency = active and 0 or 1,
                BackgroundColor3       = C.accent,
                TextColor3             = active and C.white or C.subtext
            }):Play()
            tabContents[n].Visible = active
        end
    end)
end

-- ========= HELPER UI =========
local function sectionLabel(parent, text)
    local f = Instance.new("Frame")
    f.Size             = UDim2.new(0.95, 0, 0, 20)
    f.BackgroundTransparency = 1
    f.Parent           = parent

    local l = Instance.new("TextLabel", f)
    l.Size              = UDim2.new(1, 0, 1, 0)
    l.BackgroundTransparency = 1
    l.Text              = text
    l.TextColor3        = C.subtext
    l.Font              = Enum.Font.GothamBold
    l.TextSize          = 10
    l.TextXAlignment    = Enum.TextXAlignment.Left
end

local function createToggle(parent, labelTxt, accentColor, callback)
    local card = Instance.new("Frame")
    card.Size             = UDim2.new(0.95, 0, 0, 48)
    card.BackgroundColor3 = C.card
    card.BorderSizePixel  = 0
    card.Parent           = parent
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke", card)
    stroke.Color     = C.border
    stroke.Thickness = 1

    local lbl = Instance.new("TextLabel", card)
    lbl.Size                = UDim2.new(0.65, 0, 1, 0)
    lbl.Position            = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text                = labelTxt
    lbl.TextColor3          = C.text
    lbl.Font                = Enum.Font.GothamBold
    lbl.TextSize            = 13
    lbl.TextXAlignment      = Enum.TextXAlignment.Left

    local sw = Instance.new("Frame", card)
    sw.Size             = UDim2.new(0, 46, 0, 24)
    sw.Position         = UDim2.new(1, -56, 0.5, -12)
    sw.BackgroundColor3 = C.border
    sw.BorderSizePixel  = 0
    Instance.new("UICorner", sw).CornerRadius = UDim.new(1, 0)

    local dot = Instance.new("Frame", sw)
    dot.Size             = UDim2.new(0, 18, 0, 18)
    dot.Position         = UDim2.new(0, 3, 0.5, -9)
    dot.BackgroundColor3 = C.white
    dot.BorderSizePixel  = 0
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local state = false
    local hit = Instance.new("TextButton", card)
    hit.Size                = UDim2.new(1, 0, 1, 0)
    hit.BackgroundTransparency = 1
    hit.Text                = ""

    hit.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(sw, TweenInfo.new(0.18), {
            BackgroundColor3 = state and accentColor or C.border
        }):Play()
        TweenService:Create(dot, TweenInfo.new(0.18), {
            Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.18), {
            Color = state and accentColor or C.border
        }):Play()
        callback(state)
    end)
end

local function createButton(parent, labelTxt, accentColor, callback)
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(0.95, 0, 0, 42)
    btn.BackgroundColor3 = C.card
    btn.BorderSizePixel  = 0
    btn.Text             = labelTxt
    btn.TextColor3       = accentColor
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 13
    btn.Parent           = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke", btn)
    stroke.Color     = accentColor
    stroke.Thickness = 1

    btn.MouseButton1Click:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = accentColor}):Play()
        TweenService:Create(btn, TweenInfo.new(0.1), {TextColor3 = C.bg}):Play()
        task.wait(0.1)
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = C.card}):Play()
        TweenService:Create(btn, TweenInfo.new(0.1), {TextColor3 = accentColor}):Play()
        callback()
    end)
end

-- ========= ESP TAB =========
sectionLabel(tabContents["ESP"], "  PLAYER ESP")
createToggle(tabContents["ESP"], "ESP Semua Player", C.innocent, function(s)
    espEnabled = s
end)
createToggle(tabContents["ESP"], "Highlight Murderer & Sheriff", C.murderer, function(s)
    highlightMurder = s
    if not s then
        for p, hl in pairs(murdererHighlights) do
            pcall(function() hl:Destroy() end)
        end
        murdererHighlights = {}
    end
end)

sectionLabel(tabContents["ESP"], "  INFO")

-- Role checker button
createButton(tabContents["ESP"], "🔍 CEK ROLE SEKARANG", C.accentY, function()
    local role = getRole(LocalPlayer)
    local myChar = LocalPlayer.Character
    local gui = Instance.new("ScreenGui")
    gui.Name            = "RoleNotif"
    gui.ResetOnSpawn    = false
    gui.Parent          = game:GetService("CoreGui")

    local f = Instance.new("Frame", gui)
    f.Size              = UDim2.new(0, 260, 0, 60)
    f.Position          = UDim2.new(0.5, -130, 0, 80)
    f.BackgroundColor3  = C.card
    f.BorderSizePixel   = 0
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 12)

    local roleColor = role == "Murderer" and C.murderer or role == "Sheriff" and C.sheriff or C.innocent
    local roleIcon  = role == "Murderer" and "☠" or role == "Sheriff" and "⭐" or "😇"

    local stroke = Instance.new("UIStroke", f)
    stroke.Color = roleColor; stroke.Thickness = 1.5

    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1
    lbl.Text = roleIcon .. "  Kamu adalah: " .. role
    lbl.TextColor3 = roleColor; lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 15

    TweenService:Create(f, TweenInfo.new(0.4, Enum.EasingStyle.Bounce), {Position = UDim2.new(0.5,-130,0,100)}):Play()
    task.delay(3, function() game:GetService("Debris"):AddItem(gui, 0) end)
end)

-- ========= COINS TAB =========
sectionLabel(tabContents["COINS"], "  KOIN")
createToggle(tabContents["COINS"], "ESP Koin (Hologram)", C.coin, function(s)
    coinESPEnabled = s
    initCoinESP()
end)
createToggle(tabContents["COINS"], "Auto Collect Koin", C.accentG, function(s)
    autoCollect = s
    if s then startAutoCollect()
    elseif collectConn then collectConn:Disconnect() end
end)
createButton(tabContents["COINS"], "🔄 Refresh ESP Koin", C.coin, function()
    initCoinESP()
end)

-- ========= PLAYERS TAB =========
sectionLabel(tabContents["PLAYERS"], "  TELEPORT KE PLAYER")

local playerListFrame = Instance.new("Frame")
playerListFrame.Size             = UDim2.new(0.95, 0, 0, 300)
playerListFrame.BackgroundColor3 = C.card
playerListFrame.BorderSizePixel  = 0
playerListFrame.Parent           = tabContents["PLAYERS"]
Instance.new("UICorner", playerListFrame).CornerRadius = UDim.new(0, 10)

local plStroke = Instance.new("UIStroke", playerListFrame)
plStroke.Color = C.border; plStroke.Thickness = 1

local plScroll = Instance.new("ScrollingFrame", playerListFrame)
plScroll.Size                 = UDim2.new(1, -10, 1, -10)
plScroll.Position             = UDim2.new(0, 5, 0, 5)
plScroll.BackgroundTransparency = 1
plScroll.BorderSizePixel      = 0
plScroll.ScrollBarThickness   = 3
plScroll.ScrollBarImageColor3 = C.accent

local plLayout = Instance.new("UIListLayout", plScroll)
plLayout.Padding             = UDim.new(0, 5)
plLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local plPad = Instance.new("UIPadding", plScroll)
plPad.PaddingTop = UDim.new(0, 5); plPad.PaddingBottom = UDim.new(0, 5)

plLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    plScroll.CanvasSize = UDim2.new(0, 0, 0, plLayout.AbsoluteContentSize.Y + 10)
end)

local function refreshPlayers()
    for _, c in pairs(plScroll:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end
    end

    -- Refresh btn
    local rb = Instance.new("TextButton", plScroll)
    rb.Size             = UDim2.new(0.9, 0, 0, 30)
    rb.BackgroundColor3 = Color3.fromRGB(0, 120, 80)
    rb.BorderSizePixel  = 0
    rb.Text             = "🔄 REFRESH"
    rb.TextColor3       = C.white
    rb.Font             = Enum.Font.GothamBold
    rb.TextSize         = 12
    Instance.new("UICorner", rb).CornerRadius = UDim.new(0, 8)
    rb.MouseButton1Click:Connect(refreshPlayers)

    local count = 0
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            count = count + 1
            local row = Instance.new("Frame", plScroll)
            row.Size             = UDim2.new(0.9, 0, 0, 46)
            row.BackgroundColor3 = C.bg
            row.BorderSizePixel  = 0
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

            local rowStroke = Instance.new("UIStroke", row)
            rowStroke.Color = C.border; rowStroke.Thickness = 1

            -- Role color
            local roleColor, roleTag = getRoleColor(p)
            local nameL = Instance.new("TextLabel", row)
            nameL.Size               = UDim2.new(0.58, 0, 1, 0)
            nameL.Position           = UDim2.new(0, 10, 0, 0)
            nameL.BackgroundTransparency = 1
            nameL.Text               = (roleTag ~= "" and roleTag .. "\n" or "") .. p.Name
            nameL.TextColor3         = roleColor
            nameL.Font               = Enum.Font.GothamBold
            nameL.TextSize           = 11
            nameL.TextXAlignment     = Enum.TextXAlignment.Left

            local tpBtn = Instance.new("TextButton", row)
            tpBtn.Size             = UDim2.new(0, 80, 0, 28)
            tpBtn.Position         = UDim2.new(1, -88, 0.5, -14)
            tpBtn.BackgroundColor3 = C.accent
            tpBtn.BorderSizePixel  = 0
            tpBtn.Text             = "TELEPORT"
            tpBtn.TextColor3       = C.white
            tpBtn.Font             = Enum.Font.GothamBold
            tpBtn.TextSize         = 11
            Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 6)

            local target = p
            tpBtn.MouseButton1Click:Connect(function()
                local mc  = LocalPlayer.Character
                local tc  = target.Character
                if mc and tc then
                    local mhrp = mc:FindFirstChild("HumanoidRootPart")
                    local thrp = tc:FindFirstChild("HumanoidRootPart")
                    if mhrp and thrp then
                        mhrp.CFrame = thrp.CFrame + Vector3.new(0, 4, 0)
                    end
                end
            end)
        end
    end

    if count == 0 then
        local empty = Instance.new("TextLabel", plScroll)
        empty.Size               = UDim2.new(0.9, 0, 0, 40)
        empty.BackgroundTransparency = 1
        empty.Text               = "Tidak ada player lain"
        empty.TextColor3         = C.subtext
        empty.Font               = Enum.Font.Gotham
        empty.TextSize           = 12
    end
end

refreshPlayers()
Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(refreshPlayers)

-- ========= FLOATING BUTTON =========
local FloatBtn = Instance.new("TextButton")
FloatBtn.Size             = UDim2.new(0, 48, 0, 48)
FloatBtn.Position         = UDim2.new(0, 12, 0.5, -24)
FloatBtn.BackgroundColor3 = C.accent
FloatBtn.BorderSizePixel  = 0
FloatBtn.Text             = "🔪"
FloatBtn.TextSize         = 22
FloatBtn.ZIndex           = 10
FloatBtn.Parent           = ScreenGui
Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(1, 0)

local fStroke = Instance.new("UIStroke", FloatBtn)
fStroke.Color = Color3.fromRGB(255, 150, 50); fStroke.Thickness = 2

-- Pulse animation float btn
local pulseTween = TweenService:Create(fStroke, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
    Thickness = 4
})
pulseTween:Play()

-- Drag float
local fDrag, fStart, fPos0 = false, nil, nil
FloatBtn.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        fDrag = true; fStart = inp.Position; fPos0 = FloatBtn.Position
    end
end)
FloatBtn.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        fDrag = false
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if fDrag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
        local d = inp.Position - fStart
        FloatBtn.Position = UDim2.new(0,
            math.clamp(fPos0.X.Offset + d.X, 0, Camera.ViewportSize.X - 48),
            0,
            math.clamp(fPos0.Y.Offset + d.Y, 0, Camera.ViewportSize.Y - 48)
        )
    end
end)

local menuOpen = true
FloatBtn.MouseButton1Click:Connect(function()
    menuOpen = not menuOpen
    if menuOpen then
        Main.Visible = true
        TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Back), {
            Size = UDim2.new(0, 400, 0, 540)
        }):Play()
    else
        TweenService:Create(Main, TweenInfo.new(0.2), {
            Size = UDim2.new(0, 0, 0, 0)
        }):Play()
        task.wait(0.25)
        Main.Visible = false
    end
end)

-- Drag main frame dari header
local mDrag, mStart, mPos0 = false, nil, nil
Header.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        mDrag = true; mStart = inp.Position; mPos0 = Main.Position
    end
end)
Header.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then mDrag = false end
end)
UserInputService.InputChanged:Connect(function(inp)
    if mDrag and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local d = inp.Position - mStart
        Main.Position = UDim2.new(mPos0.X.Scale, mPos0.X.Offset + d.X, mPos0.Y.Scale, mPos0.Y.Offset + d.Y)
    end
end)

print("[Putzzdev] MM2 Script loaded! 🔪")
