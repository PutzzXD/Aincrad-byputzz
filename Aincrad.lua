-- ================== VIOLENCE DISTRICT SCRIPT ==================
-- Fitur: ESP Player, ESP Generator, ESP Hook, ESP Exit,
-- Auto Repair Generator (stop jika Killer < 30m),
-- Auto Parry (jika player < 12m), Aim Assist Pistol,
-- List Player + Teleport + Refresh
-- Developer: Custom Script

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ================== WARNA ==================
local themeColor  = Color3.fromRGB(0, 255, 180)
local darkBg      = Color3.fromRGB(10, 14, 22)
local panelBg     = Color3.fromRGB(18, 22, 35)
local borderColor = Color3.fromRGB(0, 255, 180)

local colorKiller    = Color3.fromRGB(255, 60, 60)
local colorSurvivor  = Color3.fromRGB(60, 220, 255)
local colorGenerator = Color3.fromRGB(255, 220, 0)
local colorHook      = Color3.fromRGB(255, 100, 200)
local colorExit      = Color3.fromRGB(100, 255, 100)
local colorWhite     = Color3.fromRGB(255, 255, 255)

-- ================== ROLE DETECTION ==================
local myRole = "Survivor" -- default Survivor, akan diupdate dari chat
local killerPlayer = nil  -- simpan siapa killer nya

local function detectRoleFromChat()
    local TextChatService = game:GetService("TextChatService")
    -- Monitor chat system messages
    pcall(function()
        local chatGui = LocalPlayer.PlayerGui:WaitForChild("Chat", 5)
        -- fallback: monitor via Players.LocalPlayer.CharacterAdded juga
    end)
end

-- Deteksi role lewat chat message bawaan game
game:GetService("Players").LocalPlayer.Chatted:Connect(function() end) -- placeholder

-- Hook ke semua channel chat untuk deteksi "tim Survivors" / "tim Killer"
task.spawn(function()
    local success, TextChatService = pcall(function()
        return game:GetService("TextChatService")
    end)
    if not success then return end
    
    pcall(function()
        TextChatService.MessageReceived:Connect(function(msg)
            local txt = msg.Text or ""
            local lower = txt:lower()

            -- Deteksi role kita sendiri
            if lower:find("tim survivors") or lower:find("tim survivor") then
                myRole = "Survivor"
            elseif lower:find("tim killer") or lower:find("tim kill") then
                myRole = "Killer"
            end

            -- Coba deteksi siapa killer dari pengumuman game
            -- Contoh: "X is the Killer" atau "Killer: X"
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer then
                    local name = p.Name:lower()
                    if lower:find(name) and (lower:find("killer") or lower:find("pembunuh")) then
                        killerPlayer = p
                    end
                end
            end
        end)
    end)
end)

-- ================== TOGGLE STATE ====================
local espPlayersEnabled   = false
local espGeneratorEnabled = false
local espHookEnabled      = false
local espExitEnabled      = false
local autoRepairEnabled   = false
local autoRepairManual    = false
local autoParryEnabled    = false
local aimAssistEnabled    = false

-- ================== ESP TABLES ==================
local espPlayerLines  = {}
local espPlayerBoxes  = {}
local espPlayerNames  = {}
local espObjectLabels = {} -- untuk gen, hook, exit

-- ================== DRAWING HELPER ==================
local function newLine(color)
    local l = Drawing.new("Line")
    l.Thickness = 1.5
    l.Color = color
    l.Visible = false
    return l
end

local function newBox(color)
    local b = Drawing.new("Square")
    b.Thickness = 1.8
    b.Color = color
    b.Filled = false
    b.Visible = false
    return b
end

local function newText(color)
    local t = Drawing.new("Text")
    t.Size = 13
    t.Color = color
    t.Center = true
    t.Outline = true
    t.OutlineColor = Color3.fromRGB(0, 0, 0)
    t.Visible = false
    return t
end

-- ================== INIT ESP PLAYER ==================
local function initPlayerESP(player)
    if player == LocalPlayer then return end
    espPlayerLines[player]  = newLine(colorSurvivor)
    espPlayerBoxes[player]  = newBox(colorSurvivor)
    espPlayerNames[player]  = newText(colorWhite)
end

local function removePlayerESP(player)
    if espPlayerLines[player]  then espPlayerLines[player]:Remove();  espPlayerLines[player]  = nil end
    if espPlayerBoxes[player]  then espPlayerBoxes[player]:Remove();  espPlayerBoxes[player]  = nil end
    if espPlayerNames[player]  then espPlayerNames[player]:Remove();  espPlayerNames[player]  = nil end
end

for _, p in pairs(Players:GetPlayers()) do initPlayerESP(p) end
Players.PlayerAdded:Connect(initPlayerESP)
Players.PlayerRemoving:Connect(removePlayerESP)

-- ================== INIT ESP OBJECT ==================
local function initObjectESP()
    for _, v in pairs(espObjectLabels) do pcall(function() if v.highlight then v.highlight:Destroy() end end) end
    espObjectLabels = {}

    local function addHighlight(obj, fillColor, outlineColor, tag)
        local target = nil
        if obj:IsA("Model") or obj:IsA("BasePart") then
            target = obj
        end
        if not target then return end

        local old = target:FindFirstChildWhichIsA("Highlight")
        if old then old:Destroy() end

        local hl = Instance.new("Highlight")
        hl.FillColor           = fillColor
        hl.FillTransparency    = 0.4
        hl.OutlineColor        = outlineColor
        hl.OutlineTransparency = 0.1
        hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Enabled             = false
        hl.Parent              = target

        table.insert(espObjectLabels, {highlight = hl, object = target, tag = tag})
    end

    -- Generator
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "Generator" and (obj:IsA("Model") or obj:IsA("BasePart")) then
            addHighlight(obj, colorGenerator, Color3.fromRGB(255, 255, 100), "Generator")
        end
    end
    -- Hook
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "Hook" and (obj:IsA("Model") or obj:IsA("BasePart")) then
            addHighlight(obj, colorHook, Color3.fromRGB(255, 150, 220), "Hook")
        end
    end
    -- Exit
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "Exit" and (obj:IsA("Model") or obj:IsA("BasePart")) then
            addHighlight(obj, colorExit, Color3.fromRGB(150, 255, 150), "Exit")
        end
    end
end

initObjectESP()

-- ================== GET PART POSITION ==================
local function getPos(obj)
    if obj:IsA("Model") then
        local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
        if hrp then return hrp.Position end
        if obj.PrimaryPart then return obj.PrimaryPart.Position end
    elseif obj:IsA("BasePart") then
        return obj.Position
    end
    return nil
end

-- ================== UPDATE ESP ==================
local function updateESP()
    local myChar = LocalPlayer.Character
    local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myPos  = myHRP and myHRP.Position
    local vp     = Camera.ViewportSize

    -- Player ESP
    for player, line in pairs(espPlayerLines) do
        local char = player.Character
        local head = char and char:FindFirstChild("Head")
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")

        if espPlayersEnabled and head and hrp and myPos then
            local screenPos, vis = Camera:WorldToViewportPoint(head.Position)
            local dist = (myPos - hrp.Position).Magnitude

            -- Tentukan warna: jika kita Survivor, 1 orang = Killer (merah), sisanya Survivor (cyan)
            -- Jika kita Killer, semua orang = Survivor (cyan)
            -- Killer = player yang sendiri (hanya 1 dari semua player non-local)
            -- Deteksi: killer biasanya punya Highlight atau tag khusus, fallback: cek jumlah player
            local isKiller = false
            if myRole == "Survivor" then
                -- Cek apakah player ini punya highlight merah (tanda killer) atau cek via nama
                local hl = char:FindFirstChildWhichIsA("Highlight")
                if hl and hl.FillColor == Color3.fromRGB(255,0,0) then
                    isKiller = true
                end
                -- Fallback: jika hanya 1 non-local player, dia killer (solo mode)
                -- Atau simpan dari chat deteksi
                if killerPlayer == player then isKiller = true end
            end

            local espColor = isKiller and colorKiller or colorSurvivor
            line.Color                      = espColor
            espPlayerBoxes[player].Color    = espColor
            espPlayerNames[player].Color    = isKiller and colorKiller or colorWhite

            if vis then
                -- Line dari bawah layar
                line.From    = Vector2.new(vp.X / 2, vp.Y)
                line.To      = Vector2.new(screenPos.X, screenPos.Y)
                line.Visible = true

                -- Box
                local topPos    = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.6, 0))
                local bottomPos = Camera:WorldToViewportPoint(hrp.Position  - Vector3.new(0, 3,   0))
                local height    = math.abs(topPos.Y - bottomPos.Y)
                local width     = height / 2
                local box       = espPlayerBoxes[player]
                box.Size     = Vector2.new(width, height)
                box.Position = Vector2.new(screenPos.X - width / 2, topPos.Y)
                box.Visible  = true

                -- Name + dist + label role
                local nameD   = espPlayerNames[player]
                local roleTag = isKiller and " [KILLER]" or ""
                nameD.Position = Vector2.new(screenPos.X, topPos.Y - 16)
                nameD.Text     = player.Name .. roleTag .. " [" .. math.floor(dist) .. "m]"
                nameD.Visible  = true
            else
                line.Visible                   = false
                espPlayerBoxes[player].Visible = false
                espPlayerNames[player].Visible = false
            end
        else
            line.Visible                   = false
            espPlayerBoxes[player].Visible = false
            espPlayerNames[player].Visible = false
        end
    end

    -- Object ESP (Generator, Hook, Exit) - Highlight hologram
    for _, data in pairs(espObjectLabels) do
        local obj = data.object
        local hl  = data.highlight

        if obj and obj.Parent and hl then
            local enabled = false
            if data.tag == "Generator" and espGeneratorEnabled then enabled = true end
            if data.tag == "Hook"      and espHookEnabled      then enabled = true end
            if data.tag == "Exit"      and espExitEnabled      then enabled = true end
            hl.Enabled = enabled
        elseif hl then
            hl.Enabled = false
        end
    end
end

-- ================== CARI KILLER TERDEKAT ==================
local function getNearestPlayerDistance()
    local myChar = LocalPlayer.Character
    local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return math.huge end

    local nearest = math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local char = p.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (myHRP.Position - hrp.Position).Magnitude
                if d < nearest then nearest = d end
            end
        end
    end
    return nearest
end

-- ================== AUTO REPAIR GENERATOR ==================
local repairConn = nil

local function startAutoRepair()
    if repairConn then repairConn:Disconnect() end
    repairConn = RunService.Heartbeat:Connect(function()
        if not autoRepairEnabled then return end
        local dist = getNearestPlayerDistance()
        if dist < 30 then return end -- stop jika ada player < 30m

        local myChar = LocalPlayer.Character
        local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end

        -- Teleport ke generator terdekat dan repair
        local nearestGen  = nil
        local nearestDist = math.huge
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj.Name == "Generator" then
                local pos = getPos(obj)
                if pos then
                    local d = (myHRP.Position - pos).Magnitude
                    if d < nearestDist then
                        nearestDist = d
                        nearestGen  = obj
                    end
                end
            end
        end

        if nearestGen then
            local pos = getPos(nearestGen)
            if pos and nearestDist > 3 then
                myHRP.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
            end
            -- Simulasi interaksi repair (fire remote jika ada)
            pcall(function()
                local remote = nearestGen:FindFirstChildWhichIsA("RemoteEvent")
                    or nearestGen:FindFirstChildWhichIsA("RemoteFunction")
                if remote then remote:FireServer() end
            end)
        end
    end)
end

-- ================== AUTO REPAIR MANUAL (TANPA TP) ==================
local repairManualConn = nil

local function startAutoRepairManual()
    if repairManualConn then repairManualConn:Disconnect() end
    repairManualConn = RunService.Heartbeat:Connect(function()
        if not autoRepairManual then return end
        -- Cukup simulasi tombol repair tanpa teleport
        pcall(function()
            local myChar = LocalPlayer.Character
            local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if not myHRP then return end

            for _, obj in pairs(workspace:GetDescendants()) do
                if obj.Name == "Generator" then
                    local pos = getPos(obj)
                    if pos and (myHRP.Position - pos).Magnitude < 5 then
                        local remote = obj:FindFirstChildWhichIsA("RemoteEvent")
                            or obj:FindFirstChildWhichIsA("RemoteFunction")
                        if remote then remote:FireServer() end
                    end
                end
            end
        end)
    end)
end

-- ================== AUTO PARRY ==================
local parryConn = nil

local function startAutoParry()
    if parryConn then parryConn:Disconnect() end
    parryConn = RunService.Heartbeat:Connect(function()
        if not autoParryEnabled then return end
        local dist = getNearestPlayerDistance()
        if dist <= 12 then
            -- Simulasi tombol parry (E atau sejenisnya)
            pcall(function()
                local args = {[1] = "Parry"}
                local remote = LocalPlayer.Character
                    and LocalPlayer.Character:FindFirstChildWhichIsA("RemoteEvent")
                -- Coba fire event parry jika ada
                for _, v in pairs(game:GetDescendants()) do
                    if v:IsA("RemoteEvent") and (v.Name:lower():find("parry") or v.Name:lower():find("block")) then
                        v:FireServer()
                        break
                    end
                end
            end)
        end
    end)
end

-- ================== AIM ASSIST ==================
local aimConn = nil

local function startAimAssist()
    if aimConn then aimConn:Disconnect() end
    aimConn = RunService.RenderStepped:Connect(function()
        if not aimAssistEnabled then return end
        local myChar = LocalPlayer.Character
        local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end

        local nearest     = nil
        local nearestDist = math.huge

        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local char = p.Character
                local head = char and char:FindFirstChild("Head")
                if head then
                    local d = (myHRP.Position - head.Position).Magnitude
                    if d < nearestDist then
                        nearestDist = d
                        nearest     = head
                    end
                end
            end
        end

        if nearest then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, nearest.Position)
        end
    end)
end

-- ================== MAIN LOOP ==================
RunService.RenderStepped:Connect(updateESP)

-- ================== UI ==================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "VD_Script"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent         = game:GetService("CoreGui")

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name            = "MainFrame"
MainFrame.Size            = UDim2.new(0, 420, 0, 560)
MainFrame.Position        = UDim2.new(0.5, -210, 0.5, -280)
MainFrame.BackgroundColor3 = darkBg
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent          = ScreenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent       = MainFrame

-- Border glow
local border = Instance.new("UIStroke")
border.Color     = borderColor
border.Thickness = 1.5
border.Parent    = MainFrame

-- Header
local Header = Instance.new("Frame")
Header.Size              = UDim2.new(1, 0, 0, 48)
Header.BackgroundColor3  = Color3.fromRGB(12, 18, 30)
Header.BorderSizePixel   = 0
Header.Parent            = MainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent       = Header

local Title = Instance.new("TextLabel")
Title.Size                = UDim2.new(1, -60, 1, 0)
Title.Position            = UDim2.new(0, 16, 0, 0)
Title.BackgroundTransparency = 1
Title.Text                = "⚡ VIOLENCE DISTRICT"
Title.TextColor3          = themeColor
Title.Font                = Enum.Font.GothamBold
Title.TextSize            = 16
Title.TextXAlignment      = Enum.TextXAlignment.Left
Title.Parent              = Header

local SubTitle = Instance.new("TextLabel")
SubTitle.Size                = UDim2.new(1, -16, 0, 16)
SubTitle.Position            = UDim2.new(0, 16, 1, -18)
SubTitle.BackgroundTransparency = 1
SubTitle.Text                = "Custom Script"
SubTitle.TextColor3          = Color3.fromRGB(100, 140, 180)
SubTitle.Font                = Enum.Font.Gotham
SubTitle.TextSize            = 11
SubTitle.TextXAlignment      = Enum.TextXAlignment.Left
SubTitle.Parent              = Header

-- Tab Buttons
local tabNames    = {"ESP", "COMBAT", "PLAYERS"}
local tabButtons  = {}
local tabContents = {}
local activeTab   = "ESP"

local TabBar = Instance.new("Frame")
TabBar.Size             = UDim2.new(1, 0, 0, 38)
TabBar.Position         = UDim2.new(0, 0, 0, 48)
TabBar.BackgroundColor3 = Color3.fromRGB(14, 20, 32)
TabBar.BorderSizePixel  = 0
TabBar.Parent           = MainFrame

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding       = UDim.new(0, 0)
tabLayout.Parent        = TabBar

-- Content Area
local ContentArea = Instance.new("Frame")
ContentArea.Size              = UDim2.new(1, 0, 1, -86)
ContentArea.Position          = UDim2.new(0, 0, 0, 86)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent            = MainFrame

local function createTabContent(name)
    local f = Instance.new("ScrollingFrame")
    f.Name                  = name
    f.Size                  = UDim2.new(1, 0, 1, 0)
    f.BackgroundTransparency = 1
    f.BorderSizePixel       = 0
    f.ScrollBarThickness    = 3
    f.ScrollBarImageColor3  = themeColor
    f.Visible               = (name == "ESP")
    f.Parent                = ContentArea

    local layout = Instance.new("UIListLayout")
    layout.Padding         = UDim.new(0, 6)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Parent          = f

    local padding = Instance.new("UIPadding")
    padding.PaddingTop   = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.Parent       = f

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        f.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end)

    return f
end

local contentESP     = createTabContent("ESP")
local contentCombat  = createTabContent("COMBAT")
local contentPlayers = createTabContent("PLAYERS")

tabContents["ESP"]     = contentESP
tabContents["COMBAT"]  = contentCombat
tabContents["PLAYERS"] = contentPlayers

local function setTab(name)
    activeTab = name
    for tname, content in pairs(tabContents) do
        content.Visible = (tname == name)
    end
    for tname, btn in pairs(tabButtons) do
        if tname == name then
            btn.BackgroundColor3 = Color3.fromRGB(0, 200, 140)
            btn.TextColor3       = Color3.fromRGB(0, 0, 0)
        else
            btn.BackgroundColor3 = Color3.fromRGB(20, 26, 40)
            btn.TextColor3       = Color3.fromRGB(150, 170, 200)
        end
    end
end

for _, name in ipairs(tabNames) do
    local btn = Instance.new("TextButton")
    btn.Size                = UDim2.new(1/#tabNames, 0, 1, 0)
    btn.BackgroundColor3    = Color3.fromRGB(20, 26, 40)
    btn.BorderSizePixel     = 0
    btn.Text                = name
    btn.TextColor3          = Color3.fromRGB(150, 170, 200)
    btn.Font                = Enum.Font.GothamBold
    btn.TextSize            = 13
    btn.Parent              = TabBar
    tabButtons[name]        = btn
    btn.MouseButton1Click:Connect(function() setTab(name) end)
end
setTab("ESP")

-- ================== TOGGLE CREATOR ==================
local function createToggle(parent, labelText, color, callback, default)
    local frame = Instance.new("Frame")
    frame.Size              = UDim2.new(0.92, 0, 0, 44)
    frame.BackgroundColor3  = panelBg
    frame.BorderSizePixel   = 0
    frame.Parent            = parent

    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0, 8)
    fc.Parent       = frame

    local lbl = Instance.new("TextLabel")
    lbl.Size                = UDim2.new(0.65, 0, 1, 0)
    lbl.Position            = UDim2.new(0.04, 0, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text                = labelText
    lbl.TextColor3          = Color3.fromRGB(210, 225, 255)
    lbl.Font                = Enum.Font.GothamBold
    lbl.TextSize            = 13
    lbl.TextXAlignment      = Enum.TextXAlignment.Left
    lbl.Parent              = frame

    local sw = Instance.new("Frame")
    sw.Size             = UDim2.new(0, 48, 0, 24)
    sw.Position         = UDim2.new(1, -58, 0.5, -12)
    sw.BackgroundColor3 = default and color or Color3.fromRGB(55, 60, 78)
    sw.BorderSizePixel  = 0
    sw.Parent           = frame
    local swc = Instance.new("UICorner")
    swc.CornerRadius = UDim.new(0, 12)
    swc.Parent       = sw

    local circle = Instance.new("Frame")
    circle.Size             = UDim2.new(0, 20, 0, 20)
    circle.Position         = default and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
    circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    circle.BorderSizePixel  = 0
    circle.Parent           = sw
    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(1, 0)
    cc.Parent       = circle

    local state = default
    local hitbox = Instance.new("TextButton")
    hitbox.Size                = UDim2.new(1, 0, 1, 0)
    hitbox.BackgroundTransparency = 1
    hitbox.Text                = ""
    hitbox.Parent              = frame
    hitbox.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(sw, TweenInfo.new(0.15), {BackgroundColor3 = state and color or Color3.fromRGB(55, 60, 78)}):Play()
        TweenService:Create(circle, TweenInfo.new(0.15), {Position = state and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)}):Play()
        callback(state)
    end)
end

-- ================== SECTION LABEL ==================
local function createSection(parent, text)
    local lbl = Instance.new("TextLabel")
    lbl.Size                = UDim2.new(0.92, 0, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.Text                = "— " .. text .. " —"
    lbl.TextColor3          = themeColor
    lbl.Font                = Enum.Font.GothamBold
    lbl.TextSize            = 11
    lbl.Parent              = parent
end

-- ================== ESP TAB ==================
createSection(contentESP, "PLAYER")
createToggle(contentESP, "ESP SURVIVOR / KILLER", colorSurvivor, function(s)
    espPlayersEnabled = s
end, false)

createSection(contentESP, "OBJECTS")
createToggle(contentESP, "ESP GENERATOR", colorGenerator, function(s)
    espGeneratorEnabled = s
    initObjectESP()
end, false)
createToggle(contentESP, "ESP HOOK", colorHook, function(s)
    espHookEnabled = s
    initObjectESP()
end, false)
createToggle(contentESP, "ESP EXIT", colorExit, function(s)
    espExitEnabled = s
    initObjectESP()
end, false)

-- ================== COMBAT TAB ==================
createSection(contentCombat, "GENERATOR")
createToggle(contentCombat, "AUTO REPAIR (TP ke Gen)", colorGenerator, function(s)
    autoRepairEnabled = s
    if s then startAutoRepair() elseif repairConn then repairConn:Disconnect() end
end, false)
createToggle(contentCombat, "AUTO REPAIR MANUAL", themeColor, function(s)
    autoRepairManual = s
    if s then startAutoRepairManual() elseif repairManualConn then repairManualConn:Disconnect() end
end, false)

createSection(contentCombat, "FIGHT")
createToggle(contentCombat, "AUTO PARRY (< 12m)", colorKiller, function(s)
    autoParryEnabled = s
    if s then startAutoParry() elseif parryConn then parryConn:Disconnect() end
end, false)
createToggle(contentCombat, "AIM ASSIST PISTOL", colorSurvivor, function(s)
    aimAssistEnabled = s
    if s then startAimAssist() elseif aimConn then aimConn:Disconnect() end
end, false)

-- ================== PLAYERS TAB ==================
local playerListLayout = Instance.new("UIListLayout")
playerListLayout.Padding               = UDim.new(0, 5)
playerListLayout.HorizontalAlignment   = Enum.HorizontalAlignment.Center
playerListLayout.Parent                = contentPlayers

local playerListPadding = Instance.new("UIPadding")
playerListPadding.PaddingTop    = UDim.new(0, 8)
playerListPadding.PaddingBottom = UDim.new(0, 8)
playerListPadding.Parent        = contentPlayers

playerListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    contentPlayers.CanvasSize = UDim2.new(0, 0, 0, playerListLayout.AbsoluteContentSize.Y + 20)
end)

local function refreshPlayerList()
    -- Hapus semua child kecuali layout & padding
    for _, child in pairs(contentPlayers:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") then
            child:Destroy()
        end
    end

    -- Refresh button
    local refreshBtn = Instance.new("TextButton")
    refreshBtn.Size              = UDim2.new(0.92, 0, 0, 36)
    refreshBtn.BackgroundColor3  = Color3.fromRGB(0, 160, 110)
    refreshBtn.BorderSizePixel   = 0
    refreshBtn.Text              = "🔄 REFRESH"
    refreshBtn.TextColor3        = Color3.fromRGB(255, 255, 255)
    refreshBtn.Font              = Enum.Font.GothamBold
    refreshBtn.TextSize          = 13
    refreshBtn.Parent            = contentPlayers
    local rc = Instance.new("UICorner")
    rc.CornerRadius = UDim.new(0, 8)
    rc.Parent       = refreshBtn
    refreshBtn.MouseButton1Click:Connect(refreshPlayerList)

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local row = Instance.new("Frame")
            row.Size              = UDim2.new(0.92, 0, 0, 44)
            row.BackgroundColor3  = panelBg
            row.BorderSizePixel   = 0
            row.Parent            = contentPlayers
            local rowC = Instance.new("UICorner")
            rowC.CornerRadius = UDim.new(0, 8)
            rowC.Parent       = row

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size                = UDim2.new(0.6, 0, 1, 0)
            nameLabel.Position            = UDim2.new(0.03, 0, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text                = p.Name
            nameLabel.TextColor3          = Color3.fromRGB(220, 235, 255)
            nameLabel.Font                = Enum.Font.GothamBold
            nameLabel.TextSize            = 13
            nameLabel.TextXAlignment      = Enum.TextXAlignment.Left
            nameLabel.Parent              = row

            local tpBtn = Instance.new("TextButton")
            tpBtn.Size              = UDim2.new(0, 90, 0, 28)
            tpBtn.Position          = UDim2.new(1, -98, 0.5, -14)
            tpBtn.BackgroundColor3  = themeColor
            tpBtn.BorderSizePixel   = 0
            tpBtn.Text              = "TELEPORT"
            tpBtn.TextColor3        = Color3.fromRGB(0, 0, 0)
            tpBtn.Font              = Enum.Font.GothamBold
            tpBtn.TextSize          = 12
            tpBtn.Parent            = row
            local tpc = Instance.new("UICorner")
            tpc.CornerRadius = UDim.new(0, 6)
            tpc.Parent       = tpBtn

            local targetPlayer = p
            tpBtn.MouseButton1Click:Connect(function()
                local myChar    = LocalPlayer.Character
                local targetChar = targetPlayer.Character
                if not myChar or not targetChar then return end
                local myHRP  = myChar:FindFirstChild("HumanoidRootPart")
                local tgtHRP = targetChar:FindFirstChild("HumanoidRootPart")
                if myHRP and tgtHRP then
                    myHRP.CFrame = tgtHRP.CFrame + Vector3.new(0, 3, 0)
                end
            end)
        end
    end
end

refreshPlayerList()

-- Auto refresh ketika player join/leave
Players.PlayerAdded:Connect(function()
    if contentPlayers.Visible then refreshPlayerList() end
end)
Players.PlayerRemoving:Connect(function()
    if contentPlayers.Visible then refreshPlayerList() end
end)

-- ================== FLOATING TOGGLE BUTTON ==================
local FloatBtn = Instance.new("TextButton")
FloatBtn.Size              = UDim2.new(0, 50, 0, 50)
FloatBtn.Position          = UDim2.new(0, 10, 0.5, -25)
FloatBtn.BackgroundColor3  = Color3.fromRGB(0, 200, 140)
FloatBtn.BorderSizePixel   = 0
FloatBtn.Text              = "VD"
FloatBtn.TextColor3        = Color3.fromRGB(0, 0, 0)
FloatBtn.Font              = Enum.Font.GothamBold
FloatBtn.TextSize          = 14
FloatBtn.ZIndex            = 10
FloatBtn.Parent            = ScreenGui
local fbc = Instance.new("UICorner")
fbc.CornerRadius = UDim.new(1, 0)
fbc.Parent       = FloatBtn

-- Drag float button
local dragging, dragStart, startPos = false, nil, nil
FloatBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging  = true
        dragStart = input.Position
        startPos  = FloatBtn.Position
    end
end)
FloatBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        local nx    = math.clamp(startPos.X.Offset + delta.X, 0, Camera.ViewportSize.X - 50)
        local ny    = math.clamp(startPos.Y.Offset + delta.Y, 0, Camera.ViewportSize.Y - 50)
        FloatBtn.Position = UDim2.new(0, nx, 0, ny)
    end
end)

local menuVisible = true
FloatBtn.MouseButton1Click:Connect(function()
    menuVisible         = not menuVisible
    MainFrame.Visible   = menuVisible
end)

-- Drag MainFrame dari header
local mDragging, mDragStart, mStartPos = false, nil, nil
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        mDragging  = true
        mDragStart = input.Position
        mStartPos  = MainFrame.Position
    end
end)
Header.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then mDragging = false end
end)
UserInputService.InputChanged:Connect(function(input)
    if mDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - mDragStart
        MainFrame.Position = UDim2.new(
            mStartPos.X.Scale, mStartPos.X.Offset + delta.X,
            mStartPos.Y.Scale, mStartPos.Y.Offset + delta.Y
        )
    end
end)

print("[VD Script] Loaded! Klik tombol VD untuk toggle menu.")
