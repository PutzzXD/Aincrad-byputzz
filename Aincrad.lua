--[[
    Script: Putzzdev | Murder Mystery 2 Complete
    Fitur:
    1. ESP Hologram (Merah=Murderer, Hijau=Gun, Biru=Innocent)
    2. Auto Collect Coin (Ngumpulin koin otomatis)
    3. Silent Aim (Tembak auto kena ke Murderer)
    4. Auto Grab Gun (Auto ambil gun kalo Sheriff mati)
--]]

-- Variables
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- Settings Toggles
local ESPEnabled = true
local AutoCoinEnabled = true
local SilentAimEnabled = true
local AutoGrabGunEnabled = true

-- ESP Colors Configuration
local ESPConfig = {
    Murderer = { Color = Color3.fromRGB(255, 0, 0), Name = "🔪 Murderer" },
    Sheriff = { Color = Color3.fromRGB(0, 255, 0), Name = "🔫 Sheriff/Gun" },
    Innocent = { Color = Color3.fromRGB(0, 150, 255), Name = "👤 Innocent" }
}

-- Storage
local espObjects = {}
local currentTarget = nil

-- ================================
-- 1. ESP HOLOGRAM (SAMA SEPERTI SEBELUMNYA)
-- ================================

local function getPlayerRole(player)
    if not player or not player.Character then return "Innocent" end
    
    local character = player.Character
    
    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") then
            local toolName = tool.Name:lower()
            if toolName:find("knife") or toolName:find("dagger") or toolName:find("blade") then
                return "Murderer"
            end
            if toolName:find("gun") or toolName:find("pistol") or toolName:find("revolver") then
                return "Sheriff"
            end
        end
    end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        local holdingItem = humanoid:FindFirstChild("HoldingItem")
        if holdingItem and (holdingItem.Name:lower():find("gun") or holdingItem.Name:lower():find("pistol")) then
            return "Sheriff"
        end
    end
    
    return "Innocent"
end

local function createHologramESP(player, roleType)
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    
    local config = ESPConfig[roleType] or ESPConfig.Innocent
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "Putzzdev_ESP_Hologram"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 250, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.Parent = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = config.Color
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = billboard
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local glow = Instance.new("Frame")
    glow.Size = UDim2.new(1.05, 0, 1.1, 0)
    glow.Position = UDim2.new(-0.025, 0, -0.05, 0)
    glow.BackgroundColor3 = config.Color
    glow.BackgroundTransparency = 0.7
    glow.BorderSizePixel = 0
    glow.Parent = frame
    
    local glowCorner = Instance.new("UICorner")
    glowCorner.CornerRadius = UDim.new(0, 10)
    glowCorner.Parent = glow
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.Position = UDim2.new(0, 0, 0.2, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = config.Name .. " | " .. player.Name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = frame
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "Putzzdev_ESP_Highlight"
    highlight.Adornee = character
    highlight.FillColor = config.Color
    highlight.FillTransparency = 0.6
    highlight.OutlineColor = config.Color
    highlight.OutlineTransparency = 0.2
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character
    
    espObjects[player] = {
        Billboard = billboard,
        Highlight = highlight,
        Role = roleType
    }
    
    return billboard
end

local function updateESPColor(player, newRole)
    if espObjects[player] and espObjects[player].Highlight and espObjects[player].Billboard then
        local config = ESPConfig[newRole] or ESPConfig.Innocent
        local highlight = espObjects[player].Highlight
        local billboard = espObjects[player].Billboard
        local frame = billboard:FindFirstChildWhichIsA("Frame")
        
        if frame then
            frame.BackgroundColor3 = config.Color
            local glowFrame = frame:FindFirstChildWhichIsA("Frame")
            if glowFrame then glowFrame.BackgroundColor3 = config.Color end
            local nameLabel = frame:FindFirstChildWhichIsA("TextLabel")
            if nameLabel then nameLabel.Text = config.Name .. " | " .. player.Name end
        end
        
        if highlight then
            highlight.FillColor = config.Color
            highlight.OutlineColor = config.Color
        end
        
        espObjects[player].Role = newRole
    end
end

local function removeESP(player)
    if espObjects[player] then
        if espObjects[player].Billboard then espObjects[player].Billboard:Destroy() end
        if espObjects[player].Highlight then espObjects[player].Highlight:Destroy() end
        espObjects[player] = nil
    end
end

local function refreshAllESP()
    if not ESPEnabled then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local role = getPlayerRole(player)
            if espObjects[player] then
                if player.Character then updateESPColor(player, role)
                else removeESP(player) end
            elseif player.Character then
                createHologramESP(player, role)
            end
        end
    end
end

-- ================================
-- 2. AUTO COLLECT COIN (NGUMPULIN KOIN OTOMATIS)
-- ================================

local function autoCollectCoin()
    while AutoCoinEnabled and task.wait(0.1) do
        if not AutoCoinEnabled then break end
        
        local character = LocalPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not rootPart then continue end
        
        -- Cari semua koin di workspace
        local coins = {}
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Name and (obj.Name:lower():find("coin") or obj.Name:lower():find("gem")) then
                table.insert(coins, obj)
            end
        end
        
        -- Cari yang terdekat
        local closestCoin = nil
        local closestDist = math.huge
        
        for _, coin in ipairs(coins) do
            local distance = (rootPart.Position - coin.Position).Magnitude
            if distance < closestDist then
                closestDist = distance
                closestCoin = coin
            end
        end
        
        -- Teleport ke koin terdekat
        if closestCoin then
            rootPart.CFrame = closestCoin.CFrame + Vector3.new(0, 2, 0)
            task.wait(0.05)
        end
    end
end

-- ================================
-- 3. SILENT AIM (TEMBAK AUTO KENA MURDERER)
-- ================================

local function getMurderer()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and getPlayerRole(player) == "Murderer" then
            return player
        end
    end
    return nil
end

local function silentAim()
    while SilentAimEnabled and task.wait(0.05) do
        if not SilentAimEnabled then break end
        
        local murderer = getMurderer()
        if not murderer or not murderer.Character then 
            currentTarget = nil
            continue 
        end
        
        local targetHead = murderer.Character:FindFirstChild("Head")
        if not targetHead then continue end
        
        currentTarget = targetHead
        
        -- Cek apakah player sedang megang gun
        local character = LocalPlayer.Character
        if not character then continue end
        
        local hasGun = false
        for _, tool in ipairs(character:GetChildren()) do
            if tool:IsA("Tool") and (tool.Name:lower():find("gun") or tool.Name:lower():find("pistol")) then
                hasGun = true
                break
            end
        end
        
        -- Kalo megang gun, arahkan camera ke target
        if hasGun and targetHead then
            local cameraOffset = targetHead.Position - Camera.CFrame.Position
            local newCFrame = CFrame.new(Camera.CFrame.Position, targetHead.Position)
            Camera.CFrame = newCFrame
            
            -- Auto shoot
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            task.wait(0.01)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            task.wait(0.3)
        end
    end
end

-- ================================
-- 4. AUTO GRAB GUN (AMBIL GUN KALO SHERIFF MATI)
-- ================================

local function autoGrabGun()
    while AutoGrabGunEnabled and task.wait(0.1) do
        if not AutoGrabGunEnabled then break end
        
        local character = LocalPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not rootPart then continue end
        
        -- Cari gun yang jatuh di lantai
        local droppedGun = nil
        local closestDist = math.huge
        
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Tool") or (obj:IsA("BasePart") and obj.Parent and obj.Parent:IsA("Tool")) then
                local tool = obj:IsA("Tool") and obj or obj.Parent
                if tool and tool.Name and (tool.Name:lower():find("gun") or tool.Name:lower():find("pistol") or tool.Name:lower():find("revolver")) then
                    local toolHandle = tool:FindFirstChild("Handle") or tool
                    local distance = (rootPart.Position - toolHandle.Position).Magnitude
                    if distance < closestDist and distance < 50 then
                        closestDist = distance
                        droppedGun = tool
                    end
                end
            end
        end
        
        -- Teleport ke gun dan ambil
        if droppedGun then
            local gunHandle = droppedGun:FindFirstChild("Handle") or droppedGun
            rootPart.CFrame = gunHandle.CFrame + Vector3.new(0, 2, 0)
            task.wait(0.1)
            
            -- Coba ambil gun
            local args = { gunHandle }
            if droppedGun:FindFirstChild("ClickDetector") then
                fireclickdetector(droppedGun.ClickDetector)
            end
            
            -- Simulasi grab
            firetouchinterest(rootPart, gunHandle, 0)
            task.wait(0.05)
            firetouchinterest(rootPart, gunHandle, 1)
            task.wait(0.3)
        end
    end
end

-- ================================
-- SETUP & EVENT LISTENERS
-- ================================

-- Watch for role changes
local function watchChanges()
    RunService.RenderStepped:Connect(function()
        if not ESPEnabled then return end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local currentRole = getPlayerRole(player)
                local storedRole = espObjects[player] and espObjects[player].Role
                if currentRole ~= storedRole then
                    updateESPColor(player, currentRole)
                end
            end
        end
    end)
end

-- Setup all event listeners
local function setupEventListeners()
    Players.PlayerAdded:Connect(function(player)
        if player ~= LocalPlayer then
            player.CharacterAdded:Connect(function()
                task.wait(0.5)
                if ESPEnabled then
                    local role = getPlayerRole(player)
                    createHologramESP(player, role)
                end
            end)
        end
    end)
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            player.CharacterAdded:Connect(function()
                task.wait(0.5)
                if ESPEnabled then
                    local role = getPlayerRole(player)
                    createHologramESP(player, role)
                end
            end)
        end
    end
    
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        refreshAllESP()
    end)
end

-- ================================
-- GUI TOGGLE (LENGKAP DENGAN 4 FITUR)
-- ================================

local function createGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "Putzzdev_MM2_GUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 220, 0, 200)
    mainFrame.Position = UDim2.new(0, 10, 0.5, -100)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    mainFrame.BackgroundTransparency = 0.15
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 12)
    frameCorner.Parent = mainFrame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 35)
    title.BackgroundTransparency = 1
    title.Text = "Putzzdev | MM2"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = mainFrame
    
    local buttons = {
        {Name = "ESP Hologram", toggle = "ESPEnabled", y = 45},
        {Name = "Auto Coin", toggle = "AutoCoinEnabled", y = 85},
        {Name = "Silent Aim", toggle = "SilentAimEnabled", y = 125},
        {Name = "Auto Grab Gun", toggle = "AutoGrabGunEnabled", y = 165}
    }
    
    for _, btn in ipairs(buttons) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0.9, 0, 0, 30)
        button.Position = UDim2.new(0.05, 0, 0, btn.y)
        button.BackgroundColor3 = Color3.fromRGB(btn.toggle == "ESPEnabled" and 0 or 50, btn.toggle == "AutoCoinEnabled" and 100 or 50, btn.toggle == "SilentAimEnabled" and 150 or 50)
        button.BackgroundTransparency = 0.3
        button.Text = btn.Name .. ": " .. (_G[btn.toggle] and "ON" or "OFF")
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.Font = Enum.Font.Gotham
        button.TextSize = 14
        button.Parent = mainFrame
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = button
        
        button.MouseButton1Click:Connect(function()
            _G[btn.toggle] = not _G[btn.toggle]
            button.Text = btn.Name .. ": " .. (_G[btn.toggle] and "ON" or "OFF")
            
            if btn.toggle == "ESPEnabled" then
                if _G.ESPEnabled then refreshAllESP() else
                    for p, _ in pairs(espObjects) do removeESP(p) end
                end
            elseif btn.toggle == "AutoCoinEnabled" then
                if _G.AutoCoinEnabled then task.spawn(autoCollectCoin) end
            elseif btn.toggle == "SilentAimEnabled" then
                if _G.SilentAimEnabled then task.spawn(silentAim) end
            elseif btn.toggle == "AutoGrabGunEnabled" then
                if _G.AutoGrabGunEnabled then task.spawn(autoGrabGun) end
            end
        end)
    end
end

-- ================================
-- INITIALIZATION
-- ================================

local function init()
    setupEventListeners()
    watchChanges()
    createGUI()
    
    -- Spawn all features
    task.spawn(autoCollectCoin)
    task.spawn(silentAim)
    task.spawn(autoGrabGun)
    
    print("=========================================")
    print("Putzzdev | Murder Mystery 2 Complete v1.0")
    print("Fitur yang tersedia:")
    print("🔴 ESP Hologram (Merah = Murderer)")
    print("🟢 ESP Hologram (Hijau = Sheriff/Gun)")
    print("🔵 ESP Hologram (Biru = Innocent)")
    print("🪙 Auto Collect Coin")
    print("🎯 Silent Aim (Auto tembak ke Murderer)")
    print("script by Putzzdev")
    print("=========================================")
end

-- Start
pcall(init)