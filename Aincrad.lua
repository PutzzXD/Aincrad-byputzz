-- ================== ELEMENT ARENA EXPLOIT SCRIPT ==================
-- Game: Element Arena
-- Fitur: Auto Farm, ESP Player, Kill Aura, Speed, Jump, dll

-- ================== LOAD SERVICES ==================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ================== VARIABLES ==================
local PlayersList = {}
local ESPEnabled = false
local KillAuraEnabled = false
local SpeedHackEnabled = false
local JumpHackEnabled = false
local AutoFarmEnabled = false
local WalkSpeedValue = 50
local JumpPowerValue = 100
local KillAuraRange = 30
local AttackDelay = 0.5
local lastAttack = 0

-- Storage for ESP
local ESPObjects = {}

-- ================== GET ALL PLAYERS ==================
local function GetAllPlayers()
    local players = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(players, player)
        end
    end
    return players
end

-- ================== FIND CLOSEST PLAYER ==================
local function GetClosestPlayer()
    local closest = nil
    local closestDist = KillAuraRange
    local myChar = LocalPlayer.Character
    if not myChar then return nil end
    local myPos = myChar:FindFirstChild("HumanoidRootPart")
    if not myPos then return nil end
    
    for _, player in pairs(GetAllPlayers()) do
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid") then
            local hrp = char.HumanoidRootPart
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local dist = (myPos.Position - hrp.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = player
                end
            end
        end
    end
    return closest
end

-- ================== ATTACK PLAYER ==================
local function AttackPlayer(target)
    if not target then return end
    local char = target.Character
    if not char then return end
    
    -- Cari tool/weapon yang bisa digunakan
    local backpack = LocalPlayer.Backpack
    local charTools = LocalPlayer.Character:GetChildren()
    
    -- Equip weapon if available
    for _, tool in pairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            tool.Parent = LocalPlayer.Character
        end
    end
    
    -- Attack dengan tool pertama yang ada
    for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
        if tool:IsA("Tool") and tool:FindFirstChild("Handle") then
            local mouse = LocalPlayer:GetMouse()
            local args = {
                [1] = char.HumanoidRootPart.CFrame.p
            }
            -- Kirim remote event (sesuaikan dengan game)
            game:GetService("ReplicatedStorage"):FindFirstChild("Attack"):FireServer(unpack(args))
        end
    end
end

-- ================== AUTO FARM / AUTO BATTLE ==================
local function AutoFarm()
    if not AutoFarmEnabled then return end
    local target = GetClosestPlayer()
    if target and tick() - lastAttack >= AttackDelay then
        AttackPlayer(target)
        lastAttack = tick()
    end
end

-- ================== ESP SYSTEM ==================
local function CreateESP(player)
    if player == LocalPlayer then return end
    
    local box = Drawing.new("Square")
    box.Thickness = 1.5
    box.Filled = false
    box.Color = Color3.fromRGB(255, 0, 0)
    box.Visible = false
    
    local nameText = Drawing.new("Text")
    nameText.Size = 12
    nameText.Center = true
    nameText.Outline = true
    nameText.Color = Color3.fromRGB(255, 255, 255)
    nameText.Visible = false
    
    local distText = Drawing.new("Text")
    distText.Size = 10
    distText.Center = true
    distText.Outline = true
    distText.Color = Color3.fromRGB(200, 200, 200)
    distText.Visible = false
    
    local healthBar = Drawing.new("Square")
    healthBar.Thickness = 0
    healthBar.Filled = true
    healthBar.Color = Color3.fromRGB(0, 255, 0)
    healthBar.Visible = false
    
    ESPObjects[player] = {box, nameText, distText, healthBar}
end

local function UpdateESP()
    if not ESPEnabled then return end
    
    for player, objects in pairs(ESPObjects) do
        local box, nameText, distText, healthBar = unpack(objects)
        local char = player.Character
        
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Head") then
            local hrp = char.HumanoidRootPart
            local head = char.Head
            local hum = char:FindFirstChildOfClass("Humanoid")
            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            
            if onScreen and hum and hum.Health > 0 then
                -- Hitung posisi box
                local top = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1, 0))
                local bottom = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                local height = math.abs(top.Y - bottom.Y)
                local width = height * 0.6
                
                -- Box
                box.Size = Vector2.new(width, height)
                box.Position = Vector2.new(pos.X - width/2, top.Y)
                box.Visible = true
                
                -- Nama
                nameText.Position = Vector2.new(pos.X, top.Y - 12)
                nameText.Text = player.DisplayName or player.Name
                nameText.Visible = true
                
                -- Jarak
                local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
                distText.Position = Vector2.new(pos.X, bottom.Y + 12)
                distText.Text = math.floor(distance) .. "m"
                distText.Visible = true
                
                -- Health Bar
                if hum then
                    local healthPercent = hum.Health / hum.MaxHealth
                    healthBar.Size = Vector2.new(width * healthPercent, 4)
                    healthBar.Position = Vector2.new(pos.X - width/2, bottom.Y + 2)
                    healthBar.Color = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
                    healthBar.Visible = true
                end
            else
                box.Visible = false
                nameText.Visible = false
                distText.Visible = false
                healthBar.Visible = false
            end
        end
    end
end

-- ================== SPEED & JUMP HACK ==================
local function ApplyMovementHacks()
    local char = LocalPlayer.Character
    if not char then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        if SpeedHackEnabled then
            hum.WalkSpeed = WalkSpeedValue
        else
            hum.WalkSpeed = 16
        end
        
        if JumpHackEnabled then
            hum.JumpPower = JumpPowerValue
            hum.UseJumpPower = true
        else
            hum.JumpPower = 50
        end
    end
end

-- ================== CREATE GUI ==================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game.CoreGui
ScreenGui.Name = "ElementArenaGUI"

local function CreateMainGUI()
    -- Main Frame
    local MainFrame = Instance.new("Frame", ScreenGui)
    MainFrame.Size = UDim2.new(0, 250, 0, 350)
    MainFrame.Position = UDim2.new(0.02, 0, 0.1, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    MainFrame.BackgroundTransparency = 0.05
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
    
    -- Title
    local Title = Instance.new("TextLabel", MainFrame)
    Title.Size = UDim2.new(1, 0, 0, 35)
    Title.Position = UDim2.new(0, 0, 0, 0)
    Title.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    Title.Text = "ELEMENT ARENA | EXPLOIT"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 14
    Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 8)
    
    -- Scrolling Frame untuk buttons
    local ScrollFrame = Instance.new("ScrollingFrame", MainFrame)
    ScrollFrame.Size = UDim2.new(1, -10, 1, -45)
    ScrollFrame.Position = UDim2.new(0, 5, 0, 40)
    ScrollFrame.BackgroundTransparency = 1
    ScrollFrame.ScrollBarThickness = 4
    ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    
    local UILayout = Instance.new("UIListLayout", ScrollFrame)
    UILayout.Padding = UDim.new(0, 5)
    UILayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    -- Function to create toggle button
    local function CreateToggle(parent, text, color, defaultValue, callback)
        local frame = Instance.new("Frame", parent)
        frame.Size = UDim2.new(0.95, 0, 0, 35)
        frame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 5)
        
        local label = Instance.new("TextLabel", frame)
        label.Size = UDim2.new(0.7, 0, 1, 0)
        label.Position = UDim2.new(0.05, 0, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = color
        label.Font = Enum.Font.Gotham
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left
        
        local toggle = Instance.new("TextButton", frame)
        toggle.Size = UDim2.new(0, 60, 0, 25)
        toggle.Position = UDim2.new(0.75, 0, 0.5, -12.5)
        toggle.BackgroundColor3 = defaultValue and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(100, 100, 100)
        toggle.Text = defaultValue and "ON" or "OFF"
        toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggle.Font = Enum.Font.GothamBold
        toggle.TextSize = 11
        Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 4)
        
        local state = defaultValue
        toggle.MouseButton1Click:Connect(function()
            state = not state
            toggle.BackgroundColor3 = state and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(100, 100, 100)
            toggle.Text = state and "ON" or "OFF"
            callback(state)
        end)
        
        return frame
    end
    
    -- Create buttons
    CreateToggle(ScrollFrame, "ESP Player", Color3.fromRGB(255, 100, 100), false, function(v)
        ESPEnabled = v
        if v then
            for _, player in pairs(Players:GetPlayers()) do
                if not ESPObjects[player] then
                    CreateESP(player)
                end
            end
        else
            for _, objects in pairs(ESPObjects) do
                for _, obj in pairs(objects) do
                    obj.Visible = false
                end
            end
        end
    end)
    
    CreateToggle(ScrollFrame, "Kill Aura", Color3.fromRGB(255, 50, 50), false, function(v)
        KillAuraEnabled = v
    end)
    
    local speedSliderLabel = nil
    CreateToggle(ScrollFrame, "Speed Hack", Color3.fromRGB(100, 200, 255), false, function(v)
        SpeedHackEnabled = v
        ApplyMovementHacks()
    end)
    
    CreateToggle(ScrollFrame, "Jump Hack", Color3.fromRGB(100, 200, 255), false, function(v)
        JumpHackEnabled = v
        ApplyMovementHacks()
    end)
    
    CreateToggle(ScrollFrame, "Auto Farm", Color3.fromRGB(255, 200, 100), false, function(v)
        AutoFarmEnabled = v
    end)
    
    -- Slider untuk Kill Aura Range
    local rangeFrame = Instance.new("Frame", ScrollFrame)
    rangeFrame.Size = UDim2.new(0.95, 0, 0, 50)
    rangeFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    Instance.new("UICorner", rangeFrame).CornerRadius = UDim.new(0, 5)
    
    local rangeLabel = Instance.new("TextLabel", rangeFrame)
    rangeLabel.Size = UDim2.new(1, 0, 0, 20)
    rangeLabel.Position = UDim2.new(0.05, 0, 0, 5)
    rangeLabel.BackgroundTransparency = 1
    rangeLabel.Text = "Kill Aura Range: " .. KillAuraRange
    rangeLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    rangeLabel.Font = Enum.Font.Gotham
    rangeLabel.TextSize = 11
    rangeLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local slider = Instance.new("TextBox", rangeFrame)
    slider.Size = UDim2.new(0.8, 0, 0, 22)
    slider.Position = UDim2.new(0.1, 0, 0, 25)
    slider.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    slider.Text = tostring(KillAuraRange)
    slider.TextColor3 = Color3.fromRGB(255, 255, 255)
    slider.Font = Enum.Font.Gotham
    slider.TextSize = 12
    Instance.new("UICorner", slider).CornerRadius = UDim.new(0, 4)
    
    slider.FocusLost:Connect(function()
        local value = tonumber(slider.Text)
        if value then
            KillAuraRange = math.clamp(value, 10, 100)
            slider.Text = tostring(KillAuraRange)
            rangeLabel.Text = "Kill Aura Range: " .. KillAuraRange
        else
            slider.Text = tostring(KillAuraRange)
        end
    end)
    
    -- Close button
    local CloseBtn = Instance.new("TextButton", MainFrame)
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -35, 0, 3)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 14
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
    
    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)
end

-- ================== INITIALIZE ESP FOR EXISTING PLAYERS ==================
for _, player in pairs(Players:GetPlayers()) do
    CreateESP(player)
end

Players.PlayerAdded:Connect(function(player)
    CreateESP(player)
end)

Players.PlayerRemoving:Connect(function(player)
    if ESPObjects[player] then
        for _, obj in pairs(ESPObjects[player]) do
            obj:Remove()
        end
        ESPObjects[player] = nil
    end
end)

-- ================== MAIN LOOP ==================
RunService.RenderStepped:Connect(function()
    if ESPEnabled then
        UpdateESP()
    end
    
    if KillAuraEnabled or AutoFarmEnabled then
        AutoFarm()
    end
    
    ApplyMovementHacks()
end)

-- Reset movement ketika character respawn
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    ApplyMovementHacks()
end)

-- ================== SHOW GUI ==================
CreateMainGUI()

-- Print status
print("========================================")
print("ELEMENT ARENA EXPLOIT LOADED!")
print("Fitur: ESP, Kill Aura, Speed, Jump, Auto Farm")
print("========================================")