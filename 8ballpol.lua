-- ============================================================
-- SCRIPT: 8 Ball Pool Duel - Full Feature Pack
-- Platform: Roblox
-- Executor: Delta
-- Fitur: Auto Aim, Perfect Shot, Aim Line, Draw Line + Reflection,
--        Wallhack, No Recoil, Auto Win, Auto Farm Coin
-- ============================================================

-- ================== SERVICES ==================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ================== KONFIGURASI ==================
local Config = {
    AutoAim = true,
    PerfectShot = true,
    AimLine = true,
    DrawLine = true,
    DrawReflection = true,
    MaxReflection = 3,
    LineLength = 200,
    LineColor = Color3.fromRGB(0, 255, 0),
    ReflectColor = Color3.fromRGB(255, 255, 0),
    Wallhack = true,
    NoRecoil = true,
    AutoWin = false,
    AutoFarmCoin = false,
    UIOpen = true,
}

-- ================== STATE ==================
local Cue = nil
local WhiteBall = nil
local TargetBalls = {}
local AimLineGui = nil
local DrawLines = {}
local LastRefresh = 0

-- ================== HELPER: CARI OBJEK ==================
local function findCue()
    local char = LocalPlayer.Character
    if not char then return nil end
    for _, obj in pairs(char:GetChildren()) do
        if obj:IsA("Tool") then
            local n = string.lower(obj.Name)
            if string.find(n, "cue") or string.find(n, "stick") then
                return obj
            end
        end
    end
    return nil
end

local function findWhiteBall()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = string.lower(obj.Name)
            if string.find(n, "white") or string.find(n, "cueball") or string.find(n, "cue_ball") then
                return obj
            end
        end
    end
    return nil
end

local function findTargetBalls()
    local balls = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = string.lower(obj.Name)
            if (string.find(n, "ball") or string.find(n, "billiard"))
               and not string.find(n, "white")
               and not string.find(n, "cueball") then
                table.insert(balls, obj)
            end
        end
    end
    return balls
end

-- ================== AIM LINE ==================
local function createAimLine()
    if AimLineGui then AimLineGui:Remove() end
    AimLineGui = Drawing.new("Line")
    AimLineGui.Thickness = 2
    AimLineGui.Color = Config.LineColor
    AimLineGui.Transparency = 1
    AimLineGui.Visible = false
end

local function updateAimLine()
    if not Config.AimLine then
        if AimLineGui then AimLineGui.Visible = false end
        return
    end
    if not WhiteBall or not Cue then
        if AimLineGui then AimLineGui.Visible = false end
        return
    end
    if not Cue:FindFirstChild("Handle") then return end

    local direction = Cue.Handle.CFrame.LookVector
    local startPos = WhiteBall.Position
    local endPos = startPos + (direction * Config.LineLength)

    local sp, vis1 = Camera:WorldToViewportPoint(startPos)
    local ep, vis2 = Camera:WorldToViewportPoint(endPos)

    if vis1 and vis2 then
        AimLineGui.From = Vector2.new(sp.X, sp.Y)
        AimLineGui.To = Vector2.new(ep.X, ep.Y)
        AimLineGui.Color = Config.LineColor
        AimLineGui.Visible = true
    else
        AimLineGui.Visible = false
    end
end

-- ================== DRAW LINE + REFLECTION ==================
local function createDrawLine(color)
    local line = Drawing.new("Line")
    line.Thickness = 2
    line.Color = color
    line.Transparency = 1
    line.Visible = false
    return line
end

local function clearDrawLines()
    for _, line in pairs(DrawLines) do
        pcall(function() line:Remove() end)
    end
    DrawLines = {}
end

local function getTableBounds()
    local minX, maxX = math.huge, -math.huge
    local minZ, maxZ = math.huge, -math.huge
    local minY, maxY = math.huge, -math.huge
    local found = false

    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = string.lower(obj.Name)
            if string.find(n, "table") or string.find(n, "meja") or string.find(n, "felt") or string.find(n, "board") then
                found = true
                local pos = obj.Position
                local size = obj.Size
                minX = math.min(minX, pos.X - size.X/2)
                maxX = math.max(maxX, pos.X + size.X/2)
                minZ = math.min(minZ, pos.Z - size.Z/2)
                maxZ = math.max(maxZ, pos.Z + size.Z/2)
                minY = math.min(minY, pos.Y - size.Y/2)
                maxY = math.max(maxY, pos.Y + size.Y/2)
            end
        end
    end

    if not found then return nil end
    return {minX = minX, maxX = maxX, minZ = minZ, maxZ = maxZ, minY = minY, maxY = maxY}
end

local function reflectDirection(dir, bounds)
    local newDir = dir
    -- Cek dinding X
    if newDir.X > 0 then
        -- cek nanti di hit
    end
    return newDir
end

local function calcReflectionPoint(pos, dir, bounds, maxDist)
    local t = maxDist
    if dir.X > 0 then
        local dt = (bounds.maxX - pos.X) / dir.X
        if dt > 0 and dt < t then t = dt end
    elseif dir.X < 0 then
        local dt = (bounds.minX - pos.X) / dir.X
        if dt > 0 and dt < t then t = dt end
    end
    if dir.Z > 0 then
        local dt = (bounds.maxZ - pos.Z) / dir.Z
        if dt > 0 and dt < t then t = dt end
    elseif dir.Z < 0 then
        local dt = (bounds.minZ - pos.Z) / dir.Z
        if dt > 0 and dt < t then t = dt end
    end
    return pos + dir * t
end

local function updateDrawLine()
    if not Config.DrawLine then
        for _, line in pairs(DrawLines) do line.Visible = false end
        return
    end
    if not WhiteBall or not Cue then
        for _, line in pairs(DrawLines) do line.Visible = false end
        return
    end
    if not Cue:FindFirstChild("Handle") then return end

    local totalLines = Config.DrawReflection and (Config.MaxReflection + 1) or 1
    if #DrawLines < totalLines then
        clearDrawLines()
        for i = 1, totalLines do
            table.insert(DrawLines, createDrawLine(i == 1 and Config.LineColor or Config.ReflectColor))
        end
    end

    local cueDir = Cue.Handle.CFrame.LookVector
    local startPos = WhiteBall.Position
    local bounds = getTableBounds()

    -- Line utama
    local endPos = startPos + cueDir * Config.LineLength
    local sp, vis1 = Camera:WorldToViewportPoint(startPos)
    local ep, vis2 = Camera:WorldToViewportPoint(endPos)

    if vis1 and vis2 and DrawLines[1] then
        DrawLines[1].From = Vector2.new(sp.X, sp.Y)
        DrawLines[1].To = Vector2.new(ep.X, ep.Y)
        DrawLines[1].Color = Config.LineColor
        DrawLines[1].Visible = true
    end

    if Config.DrawReflection and bounds then
        local currentPos = startPos
        local currentDir = cueDir
        for i = 2, #DrawLines do
            local reflectPoint = calcReflectionPoint(currentPos, currentDir, bounds, Config.LineLength)
            local newDir = currentDir
            -- Pantulkan
            if math.abs(reflectPoint.X - bounds.minX) < 1 or math.abs(reflectPoint.X - bounds.maxX) < 1 then
                newDir = Vector3.new(-newDir.X, newDir.Y, newDir.Z)
            end
            if math.abs(reflectPoint.Z - bounds.minZ) < 1 or math.abs(reflectPoint.Z - bounds.maxZ) < 1 then
                newDir = Vector3.new(newDir.X, newDir.Y, -newDir.Z)
            end

            local nextPos = reflectPoint + newDir * Config.LineLength
            local sp2, vis3 = Camera:WorldToViewportPoint(reflectPoint)
            local ep2, vis4 = Camera:WorldToViewportPoint(nextPos)

            if vis3 and vis4 and DrawLines[i] then
                DrawLines[i].From = Vector2.new(sp2.X, sp2.Y)
                DrawLines[i].To = Vector2.new(ep2.X, ep2.Y)
                DrawLines[i].Color = Config.ReflectColor
                DrawLines[i].Visible = true
            else
                if DrawLines[i] then DrawLines[i].Visible = false end
            end

            currentPos = reflectPoint
            currentDir = newDir
        end
    else
        for i = 2, #DrawLines do
            DrawLines[i].Visible = false
        end
    end
end

-- ================== AUTO AIM ==================
local function getNearestBall()
    if not WhiteBall then return nil end
    local nearest, shortest = nil, math.huge
    for _, ball in pairs(TargetBalls) do
        if ball and ball.Parent then
            local dist = (ball.Position - WhiteBall.Position).Magnitude
            if dist < shortest and dist > 0.1 then
                shortest = dist
                nearest = ball
            end
        end
    end
    return nearest
end

local function autoAim()
    if not Config.AutoAim then return end
    if not WhiteBall or not Cue then return end
    if not Cue:FindFirstChild("Handle") then return end

    local target = getNearestBall()
    if not target then return end

    local direction = (target.Position - WhiteBall.Position).Unit
    local newCFrame = CFrame.new(WhiteBall.Position, WhiteBall.Position + direction)
    Cue.Handle.CFrame = newCFrame
end

-- ================== PERFECT SHOT ==================
local function perfectShot()
    if not Config.PerfectShot then return end
    if not Cue then return end

    local remote = ReplicatedStorage:FindFirstChild("ShotEvent")
                or ReplicatedStorage:FindFirstChild("Shoot")
                or ReplicatedStorage:FindFirstChild("FireShot")
                or ReplicatedStorage:FindFirstChild("Hit")

    if remote and remote:IsA("RemoteEvent") then
        pcall(function()
            remote:FireServer(1)
        end)
    end
end

-- ================== AUTO WIN ==================
local function autoWin()
    if not Config.AutoWin then return end

    local remotes = {}
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            local n = string.lower(obj.Name)
            if string.find(n, "win") or string.find(n, "finish") or string.find(n, "surrender") or string.find(n, "forfeit") then
                table.insert(remotes, obj)
            end
        end
    end

    for _, remote in pairs(remotes) do
        pcall(function() remote:FireServer() end)
    end
end

-- ================== AUTO FARM COIN ==================
local function autoFarmCoin()
    if not Config.AutoFarmCoin then return end

    local remotes = {}
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            local n = string.lower(obj.Name)
            if string.find(n, "claim") or string.find(n, "reward") or string.find(n, "coin") then
                table.insert(remotes, obj)
            end
        end
    end

    for _, remote in pairs(remotes) do
        pcall(function() remote:FireServer() end)
    end
end

-- ================== WALLHACK ==================
local function applyWallhack()
    if not Config.Wallhack then return end
    for _, ball in pairs(TargetBalls) do
        if ball and ball.Parent then
            pcall(function()
                ball.Material = Enum.Material.Neon
                ball.Transparency = 0.3
                ball.CanCollide = false
            end)
        end
    end
end

-- ================== NO RECOIL ==================
local function noRecoil()
    if not Config.NoRecoil then return end
    if not Cue then return end
    local handle = Cue:FindFirstChild("Handle")
    if handle then
        pcall(function()
            handle.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0, 0, 0, 0)
        end)
    end
end

-- ================== MAIN LOOP ==================
RunService.RenderStepped:Connect(function()
    local now = tick()
    if now - LastRefresh > 1 then
        Cue = findCue()
        WhiteBall = findWhiteBall()
        TargetBalls = findTargetBalls()
        LastRefresh = now
    end

    pcall(function() autoAim() end)
    pcall(function() updateAimLine() end)
    pcall(function() updateDrawLine() end)
    pcall(function() noRecoil() end)
    pcall(function() applyWallhack() end)
    if Config.AutoWin then pcall(autoWin) end
    if Config.AutoFarmCoin then pcall(autoFarmCoin) end
end)

-- ================== INPUT ==================
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        Config.UIOpen = not Config.UIOpen
        if MainFrame then MainFrame.Visible = Config.UIOpen end
    end
    if input.KeyCode == Enum.KeyCode.F then perfectShot() end
    if input.KeyCode == Enum.KeyCode.G then Config.AutoWin = true; autoWin() end
end)

-- ================== INIT ==================
createAimLine()

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BilliardScript"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 220, 0, 340)
MainFrame.Position = UDim2.new(0, 20, 0, 80)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
Title.Text = "8 Ball Pool Script"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = Title

local function createToggle(name, yPos, initState, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 200, 0, 26)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = initState and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(45, 45, 60)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 11
    btn.Parent = MainFrame

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 5)
    c.Parent = btn

    local state = initState
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(45, 45, 60)
        callback(state)
    end)
end

createToggle("Auto Aim", 40, true, function(s) Config.AutoAim = s end)
createToggle("Perfect Shot (F)", 70, true, function(s) Config.PerfectShot = s end)
createToggle("Aim Line", 100, true, function(s) Config.AimLine = s end)
createToggle("Draw Line", 130, true, function(s) Config.DrawLine = s end)
createToggle("Reflection Line", 160, true, function(s) Config.DrawReflection = s end)
createToggle("Wallhack", 190, true, function(s) Config.Wallhack = s end)
createToggle("No Recoil", 220, true, function(s) Config.NoRecoil = s end)

local winBtn = Instance.new("TextButton")
winBtn.Size = UDim2.new(0, 200, 0, 28)
winBtn.Position = UDim2.new(0, 10, 0, 250)
winBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
winBtn.Text = "AUTO WIN (G)"
winBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
winBtn.Font = Enum.Font.GothamBold
winBtn.TextSize = 11
winBtn.Parent = MainFrame

local wc = Instance.new("UICorner")
wc.CornerRadius = UDim.new(0, 5)
wc.Parent = winBtn

winBtn.MouseButton1Click:Connect(function()
    Config.AutoWin = true
    autoWin()
end)

local farmBtn = Instance.new("TextButton")
farmBtn.Size = UDim2.new(0, 200, 0, 28)
farmBtn.Position = UDim2.new(0, 10, 0, 282)
farmBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 180)
farmBtn.Text = "AUTO FARM COIN"
farmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
farmBtn.Font = Enum.Font.GothamBold
farmBtn.TextSize = 11
farmBtn.Parent = MainFrame

local fc = Instance.new("UICorner")
fc.CornerRadius = UDim.new(0, 5)
fc.Parent = farmBtn

farmBtn.MouseButton1Click:Connect(function()
    Config.AutoFarmCoin = not Config.AutoFarmCoin
    farmBtn.BackgroundColor3 = Config.AutoFarmCoin and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(0, 100, 180)
end)

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, 0, 0, 20)
infoLabel.Position = UDim2.new(0, 0, 1, -22)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "RightShift=UI | F=Shot | G=Win"
infoLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 9
infoLabel.Parent = MainFrame

print("[8 Ball Pool Script] Loaded. RightShift = toggle UI")