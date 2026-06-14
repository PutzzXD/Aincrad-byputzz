-- ╔══════════════════════════════════════════════╗
-- ║        PUTZZDEV | CHIP BOM SCRIPT            ║
-- ║   ESP Bomb, Auto Play, Speed, Utility        ║
-- ╚══════════════════════════════════════════════╝

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Camera           = workspace.CurrentCamera
local LocalPlayer      = Players.LocalPlayer

-- ================== WARNA ==================
local C = {
    bg      = Color3.fromRGB(8,   10,  18),
    card    = Color3.fromRGB(20,  24,  38),
    border  = Color3.fromRGB(40,  48,  70),
    text    = Color3.fromRGB(230, 230, 240),
    subtext = Color3.fromRGB(120, 130, 160),
    white   = Color3.fromRGB(255, 255, 255),
    red     = Color3.fromRGB(255, 60,  60),
    green   = Color3.fromRGB(60,  220, 120),
    yellow  = Color3.fromRGB(255, 210, 50),
    blue    = Color3.fromRGB(60,  150, 255),
    purple  = Color3.fromRGB(180, 80,  255),
    orange  = Color3.fromRGB(255, 140, 40),
}

-- ================== STATE ==================
local espBomb       = false
local espSafe       = false
local espMushroom   = false
local espPlayer     = false
local autoAvoid     = false
local speedEnabled  = false
local flyEnabled    = false
local flyConn       = nil
local flySpeed      = 40
local normalSpeed   = 16

-- ================== ESP DRAWINGS ==================
local bombLabels    = {}
local safeLabels    = {}
local mushroomLabels= {}
local playerESP     = {}

-- ================== HELPER DRAWING ==================
local function newText(color, size)
    local t = Drawing.new("Text")
    t.Size = size or 14; t.Color = color; t.Center = true
    t.Outline = true; t.OutlineColor = Color3.fromRGB(0,0,0); t.Visible = false
    return t
end
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

-- ================== INIT OBJECT ESP ==================
local function initObjectESP()
    -- Clear lama
    for _, d in pairs(bombLabels)     do pcall(function() d.label:Remove(); d.hl:Destroy() end) end
    for _, d in pairs(safeLabels)     do pcall(function() d.label:Remove(); d.hl:Destroy() end) end
    for _, d in pairs(mushroomLabels) do pcall(function() d.label:Remove(); d.hl:Destroy() end) end
    bombLabels = {}; safeLabels = {}; mushroomLabels = {}

    for _, obj in pairs(workspace:GetDescendants()) do
        local name = obj.Name

        -- Bomb Candy → merah
        if name == "Bomb Candy" and obj:IsA("Model") then
            local hl = Instance.new("Highlight")
            hl.FillColor = C.red; hl.FillTransparency = 0.35
            hl.OutlineColor = Color3.fromRGB(255,100,100); hl.OutlineTransparency = 0
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Enabled = false; hl.Parent = obj
            local lbl = newText(C.red, 13)
            table.insert(bombLabels, {obj=obj, hl=hl, label=lbl})
        end

        -- bombCrate → orange
        if name == "bombCrate" and obj:IsA("Model") then
            local hl = Instance.new("Highlight")
            hl.FillColor = C.orange; hl.FillTransparency = 0.35
            hl.OutlineColor = Color3.fromRGB(255,180,50); hl.OutlineTransparency = 0
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Enabled = false; hl.Parent = obj
            local lbl = newText(C.orange, 13)
            table.insert(safeLabels, {obj=obj, hl=hl, label=lbl})
        end

        -- Rainbow Mushroom → ungu
        if name == "Rainbow Mushroom" and obj:IsA("Model") then
            local hl = Instance.new("Highlight")
            hl.FillColor = C.purple; hl.FillTransparency = 0.3
            hl.OutlineColor = Color3.fromRGB(220,120,255); hl.OutlineTransparency = 0
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Enabled = false; hl.Parent = obj
            local lbl = newText(C.purple, 13)
            table.insert(mushroomLabels, {obj=obj, hl=hl, label=lbl})
        end
    end
end

initObjectESP()

-- ================== PLAYER ESP ==================
local function initPlayerESP(p)
    if p == LocalPlayer then return end
    playerESP[p] = {
        box  = newBox(C.blue),
        name = newText(C.white, 13),
        line = newLine(C.blue),
    }
end
local function removePlayerESP(p)
    if playerESP[p] then
        for _, d in pairs(playerESP[p]) do d:Remove() end
        playerESP[p] = nil
    end
end
for _, p in pairs(Players:GetPlayers()) do initPlayerESP(p) end
Players.PlayerAdded:Connect(initPlayerESP)
Players.PlayerRemoving:Connect(removePlayerESP)

-- ================== FLY ==================
local function startFly()
    local char = LocalPlayer.Character; if not char then return end
    local hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local hum  = char:FindFirstChildOfClass("Humanoid"); if hum then hum.PlatformStand=true end
    local bg = Instance.new("BodyGyro", hrp); bg.Name="FlyBG"; bg.P=9e4; bg.MaxTorque=Vector3.new(9e9,9e9,9e9)
    local bv = Instance.new("BodyVelocity", hrp); bv.Name="FlyBV"; bv.MaxForce=Vector3.new(9e9,9e9,9e9)
    flyConn = RunService.RenderStepped:Connect(function()
        if not flyEnabled or not LocalPlayer.Character then return end
        local f = UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0
        local b = UserInputService:IsKeyDown(Enum.KeyCode.S) and -1 or 0
        local l = UserInputService:IsKeyDown(Enum.KeyCode.A) and -1 or 0
        local r = UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0
        local fwd = f+b; local lr = l+r
        if fwd~=0 or lr~=0 then
            local c = Camera.CFrame
            bv.Velocity = ((c.LookVector*fwd)+(c.RightVector*lr)).Unit*flySpeed
        else bv.Velocity=Vector3.new(0,0,0) end
        bg.CFrame = Camera.CFrame
    end)
end
local function stopFly()
    flyEnabled = false
    if flyConn then flyConn:Disconnect(); flyConn=nil end
    local char = LocalPlayer.Character; if not char then return end
    local hum  = char:FindFirstChildOfClass("Humanoid"); if hum then hum.PlatformStand=false end
    local hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    if hrp:FindFirstChild("FlyBV") then hrp.FlyBV:Destroy() end
    if hrp:FindFirstChild("FlyBG") then hrp.FlyBG:Destroy() end
end

-- ================== AUTO AVOID BOMB ==================
local avoidConn = nil
local function startAutoAvoid()
    if avoidConn then avoidConn:Disconnect() end
    avoidConn = RunService.Heartbeat:Connect(function()
        if not autoAvoid then return end
        local myChar = LocalPlayer.Character
        local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local hum    = myChar and myChar:FindFirstChildOfClass("Humanoid")
        if not myHRP or not hum then return end

        -- Cari Bomb Candy terdekat
        local nearest, nearestDist = nil, math.huge
        for _, d in pairs(bombLabels) do
            if d.obj and d.obj.Parent then
                local pp = d.obj.PrimaryPart
                if pp then
                    local dist = (myHRP.Position - pp.Position).Magnitude
                    if dist < nearestDist then nearestDist=dist; nearest=pp end
                end
            end
        end

        -- Kalau ada bomb < 8 studs, gerak menjauh
        if nearest and nearestDist < 8 then
            local awayDir = (myHRP.Position - nearest.Position).Unit
            local newPos  = myHRP.Position + Vector3.new(awayDir.X*6, 0, awayDir.Z*6)
            hum:MoveTo(newPos)
        end
    end)
end

-- ================== RENDER LOOP ==================
RunService.RenderStepped:Connect(function()
    local vp    = Camera.ViewportSize
    local myChar = LocalPlayer.Character
    local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myPos  = myHRP and myHRP.Position

    -- Bomb Candy ESP
    for _, d in pairs(bombLabels) do
        local obj = d.obj
        if obj and obj.Parent and espBomb then
            local pp = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if pp and myPos then
                local sp, vis = Camera:WorldToViewportPoint(pp.Position)
                local dist    = math.floor((myPos - pp.Position).Magnitude)
                if vis then
                    d.label.Position = Vector2.new(sp.X, sp.Y - 14)
                    d.label.Text     = "💣 BOMB [" .. dist .. "m]"
                    d.label.Visible  = true
                    d.hl.Enabled     = true
                else d.label.Visible=false; d.hl.Enabled=false end
            end
        else d.label.Visible=false; if d.hl then d.hl.Enabled=false end end
    end

    -- bombCrate ESP
    for _, d in pairs(safeLabels) do
        local obj = d.obj
        if obj and obj.Parent and espSafe then
            local pp = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if pp and myPos then
                local sp, vis = Camera:WorldToViewportPoint(pp.Position)
                local dist    = math.floor((myPos - pp.Position).Magnitude)
                if vis then
                    d.label.Position = Vector2.new(sp.X, sp.Y - 14)
                    d.label.Text     = "📦 CRATE [" .. dist .. "m]"
                    d.label.Visible  = true
                    d.hl.Enabled     = true
                else d.label.Visible=false; d.hl.Enabled=false end
            end
        else d.label.Visible=false; if d.hl then d.hl.Enabled=false end end
    end

    -- Rainbow Mushroom ESP
    for _, d in pairs(mushroomLabels) do
        local obj = d.obj
        if obj and obj.Parent and espMushroom then
            local pp = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            if pp and myPos then
                local sp, vis = Camera:WorldToViewportPoint(pp.Position)
                local dist    = math.floor((myPos - pp.Position).Magnitude)
                if vis then
                    d.label.Position = Vector2.new(sp.X, sp.Y - 14)
                    d.label.Text     = "🍄 MUSHROOM [" .. dist .. "m]"
                    d.label.Visible  = true
                    d.hl.Enabled     = true
                else d.label.Visible=false; d.hl.Enabled=false end
            end
        else d.label.Visible=false; if d.hl then d.hl.Enabled=false end end
    end

    -- Player ESP
    for player, esp in pairs(playerESP) do
        local char = player.Character
        local head = char and char:FindFirstChild("Head")
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if espPlayer and head and hrp and myPos then
            local sp, vis = Camera:WorldToViewportPoint(head.Position)
            local dist    = math.floor((myPos - hrp.Position).Magnitude)
            if vis then
                esp.line.From = Vector2.new(vp.X/2, vp.Y)
                esp.line.To   = Vector2.new(sp.X, sp.Y)
                esp.line.Visible = true
                local topSP = Camera:WorldToViewportPoint(head.Position + Vector3.new(0,0.7,0))
                local botSP = Camera:WorldToViewportPoint(hrp.Position  - Vector3.new(0,3,0))
                local h = math.abs(topSP.Y - botSP.Y); local w = h/2
                esp.box.Size     = Vector2.new(w, h)
                esp.box.Position = Vector2.new(sp.X - w/2, topSP.Y)
                esp.box.Visible  = true
                esp.name.Position = Vector2.new(sp.X, topSP.Y - 17)
                esp.name.Text    = player.Name .. " [" .. dist .. "m]"
                esp.name.Visible = true
            else
                esp.line.Visible=false; esp.box.Visible=false; esp.name.Visible=false
            end
        else
            if esp.line then esp.line.Visible=false end
            if esp.box  then esp.box.Visible=false  end
            if esp.name then esp.name.Visible=false  end
        end
    end
end)

-- ================== UI ==================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ChipBomScript"; ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

-- Main Frame
local Main = Instance.new("Frame")
Main.Name = "Main"; Main.Size = UDim2.new(0, 360, 0, 500)
Main.Position = UDim2.new(0.5,-180,0.5,-250)
Main.BackgroundColor3 = C.bg; Main.BorderSizePixel = 0
Main.ClipsDescendants = true; Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,14)
local mainS = Instance.new("UIStroke", Main); mainS.Color=C.red; mainS.Thickness=1.5

-- Header
local Header = Instance.new("Frame", Main)
Header.Size = UDim2.new(1,0,0,52); Header.BackgroundColor3=Color3.fromRGB(14,8,8); Header.BorderSizePixel=0
Instance.new("UICorner", Header).CornerRadius=UDim.new(0,14)
local acL = Instance.new("Frame", Header)
acL.Size=UDim2.new(1,0,0,2); acL.Position=UDim2.new(0,0,1,-2); acL.BackgroundColor3=C.red; acL.BorderSizePixel=0
local hg=Instance.new("UIGradient",acL); hg.Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,C.red),
    ColorSequenceKeypoint.new(0.5,C.orange),
    ColorSequenceKeypoint.new(1,C.red),
})

local iconF=Instance.new("Frame",Header); iconF.Size=UDim2.new(0,32,0,32); iconF.Position=UDim2.new(0,12,0.5,-16)
iconF.BackgroundColor3=C.red; iconF.BorderSizePixel=0
Instance.new("UICorner",iconF).CornerRadius=UDim.new(0,8)
local iconL=Instance.new("TextLabel",iconF); iconL.Size=UDim2.new(1,0,1,0); iconL.BackgroundTransparency=1
iconL.Text="💣"; iconL.TextSize=18; iconL.Font=Enum.Font.GothamBold

local titleL=Instance.new("TextLabel",Header); titleL.Size=UDim2.new(0.6,0,0,22); titleL.Position=UDim2.new(0,54,0,7)
titleL.BackgroundTransparency=1; titleL.Text="CHIP BOM"; titleL.TextColor3=C.white
titleL.Font=Enum.Font.GothamBold; titleL.TextSize=15; titleL.TextXAlignment=Enum.TextXAlignment.Left

local devL=Instance.new("TextLabel",Header); devL.Size=UDim2.new(0.6,0,0,18); devL.Position=UDim2.new(0,54,1,-23)
devL.BackgroundTransparency=1; devL.Text="✦ Putzzdev"; devL.Font=Enum.Font.GothamBold; devL.TextSize=12
devL.TextXAlignment=Enum.TextXAlignment.Left
TweenService:Create(devL,TweenInfo.new(1.2,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{
    TextColor3=Color3.fromRGB(255,220,100)
}):Play()
devL.TextColor3=Color3.fromRGB(255,160,60)

local closeBtn=Instance.new("TextButton",Header)
closeBtn.Size=UDim2.new(0,28,0,28); closeBtn.Position=UDim2.new(1,-38,0.5,-14)
closeBtn.BackgroundColor3=Color3.fromRGB(60,15,15); closeBtn.BorderSizePixel=0
closeBtn.Text="✕"; closeBtn.TextColor3=C.red; closeBtn.Font=Enum.Font.GothamBold; closeBtn.TextSize=14
Instance.new("UICorner",closeBtn).CornerRadius=UDim.new(0,6)
closeBtn.MouseButton1Click:Connect(function()
    TweenService:Create(Main,TweenInfo.new(0.2),{Size=UDim2.new(0,0,0,0)}):Play()
    task.wait(0.22); Main.Visible=false
end)

-- Tabs
local tabNames = {"ESP","PLAY","INFO"}
local tabBtns,tabContents = {},{}

local TabBar=Instance.new("Frame",Main)
TabBar.Size=UDim2.new(1,-24,0,34); TabBar.Position=UDim2.new(0,12,0,58)
TabBar.BackgroundColor3=C.card; TabBar.BorderSizePixel=0
Instance.new("UICorner",TabBar).CornerRadius=UDim.new(0,10)
local tl=Instance.new("UIListLayout",TabBar); tl.FillDirection=Enum.FillDirection.Horizontal; tl.Padding=UDim.new(0,2)
local tp=Instance.new("UIPadding",TabBar); tp.PaddingLeft=UDim.new(0,3); tp.PaddingRight=UDim.new(0,3)
tp.PaddingTop=UDim.new(0,3); tp.PaddingBottom=UDim.new(0,3)

local function makeContent(name)
    local s=Instance.new("ScrollingFrame",Main)
    s.Name=name; s.Size=UDim2.new(1,-24,1,-106); s.Position=UDim2.new(0,12,0,100)
    s.BackgroundTransparency=1; s.BorderSizePixel=0; s.ScrollBarThickness=3
    s.ScrollBarImageColor3=C.red; s.Visible=(name=="ESP")
    local l=Instance.new("UIListLayout",s); l.Padding=UDim.new(0,8); l.HorizontalAlignment=Enum.HorizontalAlignment.Center
    local p=Instance.new("UIPadding",s); p.PaddingTop=UDim.new(0,8); p.PaddingBottom=UDim.new(0,8)
    l:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        s.CanvasSize=UDim2.new(0,0,0,l.AbsoluteContentSize.Y+20)
    end)
    return s
end

for _,name in ipairs(tabNames) do
    tabContents[name]=makeContent(name)
    local btn=Instance.new("TextButton",TabBar)
    btn.Size=UDim2.new(1/#tabNames,-2,1,0)
    btn.BackgroundColor3=name=="ESP" and C.red or C.card
    btn.BackgroundTransparency=name=="ESP" and 0 or 1
    btn.BorderSizePixel=0; btn.Text=name; btn.TextColor3=name=="ESP" and C.white or C.subtext
    btn.Font=Enum.Font.GothamBold; btn.TextSize=12
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,8)
    tabBtns[name]=btn
    btn.MouseButton1Click:Connect(function()
        for n,b in pairs(tabBtns) do
            local active=n==name
            TweenService:Create(b,TweenInfo.new(0.15),{
                BackgroundTransparency=active and 0 or 1,
                BackgroundColor3=C.red,
                TextColor3=active and C.white or C.subtext,
            }):Play()
            tabContents[n].Visible=active
        end
    end)
end

-- ================== UI HELPERS ==================
local function secLbl(parent,text)
    local f=Instance.new("Frame",parent); f.Size=UDim2.new(0.95,0,0,20); f.BackgroundTransparency=1
    local l=Instance.new("TextLabel",f); l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1
    l.Text=text; l.TextColor3=C.subtext; l.Font=Enum.Font.GothamBold; l.TextSize=10
    l.TextXAlignment=Enum.TextXAlignment.Left
end

local function createToggle(parent,label,color,cb)
    local card=Instance.new("Frame",parent); card.Size=UDim2.new(0.95,0,0,46); card.BackgroundColor3=C.card; card.BorderSizePixel=0
    Instance.new("UICorner",card).CornerRadius=UDim.new(0,10)
    local stroke=Instance.new("UIStroke",card); stroke.Color=C.border; stroke.Thickness=1
    local lbl=Instance.new("TextLabel",card); lbl.Size=UDim2.new(0.65,0,1,0); lbl.Position=UDim2.new(0,14,0,0)
    lbl.BackgroundTransparency=1; lbl.Text=label; lbl.TextColor3=C.text
    lbl.Font=Enum.Font.GothamBold; lbl.TextSize=13; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local sw=Instance.new("Frame",card); sw.Size=UDim2.new(0,46,0,24); sw.Position=UDim2.new(1,-56,0.5,-12)
    sw.BackgroundColor3=C.border; sw.BorderSizePixel=0
    Instance.new("UICorner",sw).CornerRadius=UDim.new(1,0)
    local dot=Instance.new("Frame",sw); dot.Size=UDim2.new(0,18,0,18); dot.Position=UDim2.new(0,3,0.5,-9)
    dot.BackgroundColor3=C.white; dot.BorderSizePixel=0
    Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
    local state=false
    local hit=Instance.new("TextButton",card); hit.Size=UDim2.new(1,0,1,0); hit.BackgroundTransparency=1; hit.Text=""
    hit.MouseButton1Click:Connect(function()
        state=not state
        TweenService:Create(sw,TweenInfo.new(0.18),{BackgroundColor3=state and color or C.border}):Play()
        TweenService:Create(dot,TweenInfo.new(0.18),{Position=state and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9)}):Play()
        TweenService:Create(stroke,TweenInfo.new(0.18),{Color=state and color or C.border}):Play()
        cb(state)
    end)
end

local function createButton(parent,label,color,cb)
    local btn=Instance.new("TextButton",parent); btn.Size=UDim2.new(0.95,0,0,42); btn.BackgroundColor3=C.card
    btn.BorderSizePixel=0; btn.Text=label; btn.TextColor3=color; btn.Font=Enum.Font.GothamBold; btn.TextSize=13
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,10)
    local stroke=Instance.new("UIStroke",btn); stroke.Color=color; stroke.Thickness=1
    btn.MouseButton1Click:Connect(function()
        TweenService:Create(btn,TweenInfo.new(0.1),{BackgroundColor3=color,TextColor3=C.bg}):Play()
        task.wait(0.12); TweenService:Create(btn,TweenInfo.new(0.1),{BackgroundColor3=C.card,TextColor3=color}):Play()
        cb()
    end)
end

-- ================== ESP TAB ==================
secLbl(tabContents["ESP"], "  💣 BOMB")
createToggle(tabContents["ESP"], "ESP Bomb Candy (Merah)", C.red, function(s)
    espBomb = s
end)
createToggle(tabContents["ESP"], "ESP Bomb Crate (Orange)", C.orange, function(s)
    espSafe = s
end)

secLbl(tabContents["ESP"], "  🍄 COLLECTIBLE")
createToggle(tabContents["ESP"], "ESP Rainbow Mushroom (Ungu)", C.purple, function(s)
    espMushroom = s
end)

secLbl(tabContents["ESP"], "  👤 PLAYER")
createToggle(tabContents["ESP"], "ESP Player (Box + Line)", C.blue, function(s)
    espPlayer = s
end)

createButton(tabContents["ESP"], "🔄 Refresh ESP Objects", C.yellow, function()
    initObjectESP()
end)

-- ================== PLAY TAB ==================
secLbl(tabContents["PLAY"], "  🏃 MOVEMENT")
createToggle(tabContents["PLAY"], "Speed Boost", C.green, function(s)
    speedEnabled = s
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = s and 80 or normalSpeed end
end)
createToggle(tabContents["PLAY"], "Fly Mode", C.blue, function(s)
    flyEnabled = s; if s then startFly() else stopFly() end
end)

secLbl(tabContents["PLAY"], "  🤖 AUTO")
createToggle(tabContents["PLAY"], "Auto Avoid Bomb (< 8m)", C.red, function(s)
    autoAvoid = s
    if s then startAutoAvoid()
    elseif avoidConn then avoidConn:Disconnect(); avoidConn=nil end
end)
createButton(tabContents["PLAY"], "🏠 Teleport ke Spawn", C.yellow, function()
    local mc = LocalPlayer.Character
    local hrp = mc and mc:FindFirstChild("HumanoidRootPart")
    local sp  = workspace:FindFirstChild("StaterPack")
    if hrp and sp then
        local pp = sp:FindFirstChildWhichIsA("BasePart")
        if pp then hrp.CFrame = CFrame.new(pp.Position + Vector3.new(0,5,0)) end
    end
end)

-- ================== INFO TAB ==================
local infoCard=Instance.new("Frame",tabContents["INFO"])
infoCard.Size=UDim2.new(0.95,0,0,200); infoCard.BackgroundColor3=C.card; infoCard.BorderSizePixel=0
Instance.new("UICorner",infoCard).CornerRadius=UDim.new(0,10)
Instance.new("UIStroke",infoCard).Color=C.border
local infoL=Instance.new("UIListLayout",infoCard); infoL.Padding=UDim.new(0,5)
local infoP=Instance.new("UIPadding",infoCard)
infoP.PaddingTop=UDim.new(0,10); infoP.PaddingLeft=UDim.new(0,14)

local function iRow(txt,color)
    local l=Instance.new("TextLabel",infoCard); l.Size=UDim2.new(1,0,0,26); l.BackgroundTransparency=1
    l.Text=txt; l.TextColor3=color or C.text; l.Font=Enum.Font.GothamBold; l.TextSize=13
    l.TextXAlignment=Enum.TextXAlignment.Left; return l
end

iRow("🎮 Game: Chip Bom", C.yellow)
iRow("👨‍💻 Dev: Putzzdev", C.orange)
local rBombs  = iRow("💣 Bomb Candy: scanning...", C.red)
local rCrates = iRow("📦 Bomb Crate: scanning...", C.orange)
local rMush   = iRow("🍄 Rainbow Mushroom: scanning...", C.purple)
local rPlayers= iRow("👥 Players: —", C.blue)

infoL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    infoCard.Size=UDim2.new(0.95,0,0,infoL.AbsoluteContentSize.Y+20)
end)

task.spawn(function()
    while true do
        pcall(function()
            local bombs=0; local crates=0; local mush=0
            for _,d in pairs(bombLabels)     do if d.obj and d.obj.Parent then bombs=bombs+1 end end
            for _,d in pairs(safeLabels)     do if d.obj and d.obj.Parent then crates=crates+1 end end
            for _,d in pairs(mushroomLabels) do if d.obj and d.obj.Parent then mush=mush+1 end end
            rBombs.Text  = "💣 Bomb Candy: " .. bombs
            rCrates.Text = "📦 Bomb Crate: " .. crates
            rMush.Text   = "🍄 Rainbow Mushroom: " .. mush
            rPlayers.Text= "👥 Players: " .. #Players:GetPlayers()
        end)
        task.wait(2)
    end
end)

-- ================== FLOATING BUTTON ==================
local FloatBtn=Instance.new("TextButton",ScreenGui)
FloatBtn.Size=UDim2.new(0,48,0,48); FloatBtn.Position=UDim2.new(0,12,0.5,-24)
FloatBtn.BackgroundColor3=C.red; FloatBtn.BorderSizePixel=0
FloatBtn.Text="💣"; FloatBtn.TextSize=22; FloatBtn.ZIndex=10
Instance.new("UICorner",FloatBtn).CornerRadius=UDim.new(1,0)
local fS=Instance.new("UIStroke",FloatBtn); fS.Color=C.orange; fS.Thickness=2
TweenService:Create(fS,TweenInfo.new(1,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Thickness=4}):Play()

-- Drag float + click threshold
do
    local drag=false; local moved=false; local sx,sy,px,py=0,0,0,0; local THRESH=6
    FloatBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            drag=true; moved=false; sx=inp.Position.X; sy=inp.Position.Y
            px=FloatBtn.Position.X.Offset; py=FloatBtn.Position.Y.Offset
        end
    end)
    FloatBtn.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            if not moved then
                local open = Main.Visible
                if not open then
                    Main.Visible=true; Main.Size=UDim2.new(0,0,0,0)
                    TweenService:Create(Main,TweenInfo.new(0.25,Enum.EasingStyle.Back),{Size=UDim2.new(0,360,0,500)}):Play()
                else
                    TweenService:Create(Main,TweenInfo.new(0.2),{Size=UDim2.new(0,0,0,0)}):Play()
                    task.delay(0.22,function() Main.Visible=false end)
                end
            end
            drag=false; moved=false
        end
    end)
    RunService.RenderStepped:Connect(function()
        if not drag then return end
        local m=UserInputService:GetMouseLocation(); local dx=m.X-sx; local dy=m.Y-sy
        if math.abs(dx)>THRESH or math.abs(dy)>THRESH then moved=true end
        if moved then
            local vp=Camera.ViewportSize
            FloatBtn.Position=UDim2.new(0,math.clamp(px+dx,0,vp.X-48),0,math.clamp(py+dy,0,vp.Y-48))
        end
    end)
end

-- Drag header menu
do
    local drag=false; local moved=false; local sx,sy,px,py=0,0,0,0; local THRESH=6
    Header.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            drag=true; moved=false; sx=inp.Position.X; sy=inp.Position.Y
            px=Main.Position.X.Offset; py=Main.Position.Y.Offset
        end
    end)
    Header.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            drag=false; moved=false
        end
    end)
    RunService.RenderStepped:Connect(function()
        if not drag then return end
        local m=UserInputService:GetMouseLocation(); local dx=m.X-sx; local dy=m.Y-sy
        if math.abs(dx)>THRESH or math.abs(dy)>THRESH then moved=true end
        if moved then
            local vp=Camera.ViewportSize; local sz=Main.AbsoluteSize
            Main.Position=UDim2.new(0,math.clamp(px+dx,0,vp.X-sz.X),0,math.clamp(py+dy,0,vp.Y-sz.Y))
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if flyEnabled then startFly() end
    if speedEnabled then
        local hum=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed=80 end
    end
end)

print("[Putzzdev] Chip Bom Script loaded! 💣")
