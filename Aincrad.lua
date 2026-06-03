-- ====================================================================
--          PUTZZDEV | MM2 PREMIUM MOBILE EDITION (WITH BUTTON)
-- ====================================================================

local KavoUi = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = KavoUi.CreateLib("Putzzdev | MM2", "DarkTheme")

-- --- SERVICES ---
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")

-- --- CONFIGURATION & STATES ---
local COLORS = {
    Murderer = Color3.fromRGB(255, 0, 0),
    Sheriff  = Color3.fromRGB(0, 255, 0),
    Innocent = Color3.fromRGB(0, 100, 255),
    GunDrop  = Color3.fromRGB(255, 255, 0)
}

local Toggles = {
    Chams = false,
    SilentAim = false,
    AutoCoin = false,
    KillAura = false,
    AutoGrabGun = false,
    AutoEscape = false,
    DodgeKnife = false
}

local SETTINGS = {
    EscapeDistance = 15,
    KillAuraRadius = 15,
    CoinTweenSpeed = 25
}

local isCollectingCoins = false
local lastGrabPosition = nil
local lastAlertTime = 0

-- --- FUNGSI DRAGGABLE & TOGGLE UNTUK TOMBOL MOBILE ---
local function createMobileButton()
    local sg = game.CoreGui:FindFirstChild("Putzzdev") or Instance.new("ScreenGui", game.CoreGui)
    sg.Name = "Putzzdev"
    
    local btn = Instance.new("TextButton", sg)
    btn.Size = UDim2.new(0, 55, 0, 55)
    btn.Position = UDim2.new(0, 15, 0, 15) -- Posisi awal di pojok kiri atas
    btn.BackgroundColor3 = Color3.fromRGB(255, 40, 40) -- Warna merah mencolok
    btn.Text = "P"
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 22
    btn.TextColor3 = Color3.new(1, 1, 1)
    
    -- Membuat tombol jadi bulat elegan
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(1, 0)
    
    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.new(1, 1, 1)
    stroke.Thickness = 2
    
    -- Logika Buka/Tutup Menu saat di-tap
    btn.MouseButton1Click:Connect(function()
        local coreGui = game.CoreGui
        local uiFrame = coreGui:FindFirstChild("Putzzdev | MM2") or coreGui:FindFirstChild("Putzzdev  MM2")
        if uiFrame then
            uiFrame.Enabled = not uiFrame.Enabled
        end
    end)
    
    -- Logika agar Tombol Bisa Digeser (Drag) di Layar HP
    local dragging, dragInput, dragStart, startPos
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = btn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    btn.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- --- UTILITY GAME FUNCTIONS ---
local function getPlayerRole(player)
    if not player then return "Innocent" end
    local character = player.Character
    local backpack = player:FindFirstChild("Backpack")
    
    if (backpack and backpack:FindFirstChild("Knife")) or (character and character:FindFirstChild("Knife")) then
        return "Murderer"
    end
    if (backpack and backpack:FindFirstChild("Gun")) or (character and character:FindFirstChild("Gun")) then
        return "Sheriff"
    end
    return "Innocent"
end

local function getMurdererPlayer()
    for _, p in pairs(Players:GetPlayers()) do
        if getPlayerRole(p) == "Murderer" then return p end
    end
    return nil
end

local function sendSideNotification(title, text, color)
    local sg = game.CoreGui:FindFirstChild("MM2_GodNotif") or Instance.new("ScreenGui", game.CoreGui)
    sg.Name = "MM2_GodNotif"
    
    local container = sg:FindFirstChild("Container") or Instance.new("Frame", sg)
    if not sg:FindFirstChild("Container") then
        container.Name = "Container"
        container.Size = UDim2.new(0, 250, 1, 0)
        container.Position = UDim2.new(1, -260, 0, 80) -- Diturunkan sedikit agar tidak ketutupan tombol atas HP
        container.BackgroundTransparency = 1
        local layout = Instance.new("UIListLayout", container)
        layout.Padding = UDim.new(0, 6)
        layout.VerticalAlignment = Enum.VerticalAlignment.Top
    end
    
    local f = Instance.new("Frame", container)
    f.Size = UDim2.new(1, 0, 0, 45)
    f.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    f.BorderSizePixel = 0
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", f).Color = color or Color3.new(1,1,1)
    
    local t = Instance.new("TextLabel", f)
    t.Size = UDim2.new(1, -15, 1, 0)
    t.Position = UDim2.new(0, 12, 0, 0)
    t.BackgroundTransparency = 1
    t.Text = "<b>" .. title .. "</b>\n" .. text
    t.RichText = true
    t.TextColor3 = Color3.new(1,1,1)
    t.Font = Enum.Font.GothamMedium
    t.TextSize = 11
    t.TextXAlignment = Enum.TextXAlignment.Left
    
    task.wait(3)
    f:Destroy()
end

-- --- UI TABS ---
local VisualTab = Window:NewTab("Visuals & ESP")
local VisualSec = VisualTab:NewSection("Player ESP")

local CombatTab = Window:NewTab("Combat & Role")
local CombatSec = CombatTab:NewSection("Sheriff & Murderer")

local AutomationTab = Window:NewTab("Automation")
local AutoSec = AutomationTab:NewSection("Farming & Grabber")

-- --- Toggles SETUP ---
VisualSec:NewToggle("Hologram Chams (All Roles)", "Warna tubuh tembus pandang sesuai role", function(state)
    Toggles.Chams = state
    if not state then
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("MM2_GodChams") then
                p.Character.MM2_GodChams:Destroy()
            end
        end
    end
end)

CombatSec:NewToggle("Silent Aim (Sheriff)", "", function(state)
    Toggles.SilentAim = state
end)

CombatSec:NewToggle("Kill Aura (Murderer)", "Otomatis tebas player terdekat", function(state)
    Toggles.KillAura = state
end)

CombatSec:NewToggle("Auto Dodge Knife", "", function(state)
    Toggles.DodgeKnife = state
end)

AutoSec:NewToggle("Auto Smooth Collect Coins", "", function(state)
    Toggles.AutoCoin = state
end)

AutoSec:NewToggle("Auto Grab Gun", "", function(state)
    Toggles.AutoGrabGun = state
end)

AutoSec:NewToggle("Auto Escape (15 Meter)", "", function(state)
    Toggles.AutoEscape = state
end)

-- --- CORE LOOPS SYSTEM ---

-- Hook Silent Aim
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    if method == "FireServer" and tostring(self) == "UseGun" and Toggles.SilentAim and getPlayerRole(LocalPlayer) == "Sheriff" then
        local targetMurd = getMurdererPlayer()
        if targetMurd and targetMurd.Character and targetMurd.Character:FindFirstChild("HumanoidRootPart") then
            args[1] = targetMurd.Character.HumanoidRootPart.Position
        end
    end
    return oldNamecall(self, unpack(args))
end)

-- Fungsi Koin
local function collectCoinsSystem()
    local myChar = LocalPlayer.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHrp or isCollectingCoins then return end
    
    local mainRoot = workspace:FindFirstChild("Normal") or workspace:FindFirstChild("Map")
    if not mainRoot then return end
    
    local targetCoin = nil
    local shortestDist = math.huge
    for _, obj in pairs(mainRoot:GetDescendants()) do
        if obj.Name == "Coin_Sub" or obj:FindFirstChild("CoinContainer") or (obj:IsA("BasePart") and obj.Name == "Coin") then
            local coinPart = obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
            if coinPart then
                local dist = (myHrp.Position - coinPart.Position).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    targetCoin = coinPart
                end
            end
        end
    end
    
    if targetCoin and getPlayerRole(LocalPlayer) == "Innocent" then
        isCollectingCoins = true
        local dist = (myHrp.Position - targetCoin.Position).Magnitude
        local duration = dist / SETTINGS.CoinTweenSpeed
        local tween = game:GetService("TweenService"):Create(myHrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = targetCoin.CFrame})
        tween:Play()
        tween.Completed:Wait()
        isCollectingCoins = false
    end
end

-- Heartbeat Loop Action
RunService.Heartbeat:Connect(function()
    local myChar = LocalPlayer.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myHrp or not myHum or myHum.Health <= 0 then return end
    
    local myRole = getPlayerRole(LocalPlayer)
    local murderer = getMurdererPlayer()
    
    if Toggles.Chams then
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character and player ~= LocalPlayer then
                pcall(function()
                    local highlight = player.Character:FindFirstChild("MM2_GodChams")
                    if not highlight then
                        highlight = Instance.new("Highlight", player.Character)
                        highlight.Name = "MM2_GodChams"
                        highlight.FillTransparency = 0.35
                        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    end
                    local r = getPlayerRole(player)
                    highlight.FillColor = COLORS[r]
                    highlight.OutlineColor = COLORS[r]
                end)
            end
        end
    end
    
    if murderer and murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart") and myRole ~= "Murderer" then
        local mudHrp = murderer.Character.HumanoidRootPart
        local distToMurderer = (myHrp.Position - mudHrp.Position).Magnitude
        
        if Toggles.AutoEscape and distToMurderer <= SETTINGS.EscapeDistance then
            if tick() - lastAlertTime > 3 then
                lastAlertTime = tick()
                task.spawn(function() sendSideNotification("Putzzdev | SISTEM", "Pembunuh mendekat tp aktif!", Color3.fromRGB(255,0,0)) end)
            end
            local escapeDirection = (myHrp.Position - mudHrp.Position).Unit
            myHrp.CFrame = CFrame.new(myHrp.Position + (escapeDirection * 25))
        end
        
        if Toggles.DodgeKnife and murderer.Character:FindFirstChild("Knife") and distToMurderer <= 25 then
            if murderer.Character.Knife:FindFirstChild("Effect") or myHum.MoveDirection.Magnitude > 0 then
                myHrp.Velocity = Vector3.new(0, 65, 0) + (Camera.CFrame.RightVector * 45)
            end
        end
    end
    
    if Toggles.KillAura and myRole == "Murderer" and myChar:FindFirstChild("Knife") then
        for _, victim in pairs(Players:GetPlayers()) do
            if victim ~= LocalPlayer and victim.Character and victim.Character:FindFirstChild("HumanoidRootPart") then
                local vicHrp = victim.Character.HumanoidRootPart
                if (myHrp.Position - vicHrp.Position).Magnitude <= SETTINGS.KillAuraRadius then
                    myChar.Knife:Activate()
                    firetouchinterest(myChar.Knife.Handle, vicHrp, 0)
                    firetouchinterest(myChar.Knife.Handle, vicHrp, 1)
                end
            end
        end
    end
    
    local gunDrop = workspace:FindFirstChild("GunDrop")
    if gunDrop and gunDrop:IsA("BasePart") and myRole == "Innocent" then
        if Toggles.AutoGrabGun then
            local distToGun = (myHrp.Position - gunDrop.Position).Magnitude
            if distToGun <= 300 and not lastGrabPosition then
                lastGrabPosition = myHrp.CFrame
                myHrp.CFrame = gunDrop.CFrame
                task.wait(0.15)
                myHrp.CFrame = lastGrabPosition
                lastGrabPosition = nil
            end
        end
    end
    
    if Toggles.AutoCoin and myRole == "Innocent" and not gunDrop then
        pcall(collectCoinsSystem)
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    isCollectingCoins = false
    lastGrabPosition = nil
end)

-- Jalankan pembuatan tombol mobile otomatis
createMobileButton()
sendSideNotification("Putzzdev  menu!", Color3.fromRGB(0, 255, 150))