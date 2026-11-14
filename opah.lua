-- ================== MALAM SAMA OPAH - ITEM & CODE ESP ==================
-- ================== BY PUTZZDEV ==================
-- Fokus: Menampilkan lokasi Kunci (Key) dan Kode (Code) secara langsung
-- UI: Custom Draggable & Minimize (Bukan AI Slop)

-- ================== LOAD SERVICES ==================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ================== KONFIGURASI ITEM & KODE ==================
local TargetKeywords = {
    ["Key"] = {Color = Color3.fromRGB(255, 215, 0), Name = "KUNCI"}, -- Emas
    ["Keycard"] = {Color = Color3.fromRGB(0, 191, 255), Name = "KARTU"}, -- Biru
    ["Code"] = {Color = Color3.fromRGB(255, 0, 0), Name = "KODE"}, -- Merah
    ["Note"] = {Color = Color3.fromRGB(255, 255, 255), Name = "CATATAN"}, -- Putih
    ["Password"] = {Color = Color3.fromRGB(255, 105, 180), Name = "PASSWORD"} -- Pink
}

-- ================== STATE ==================
local ESPObjects = {}
local IsESPActive = false
local UI_Active = false

-- ================== FUNGSI SCAN ITEM ==================
local function ClearESP()
    for _, obj in pairs(ESPObjects) do
        pcall(function() obj:Destroy() end)
    end
    ESPObjects = {}
end

local function ScanForItems()
    ClearESP()
    if not IsESPActive then return end

    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local objName = obj.Name:lower()
            for keyword, data in pairs(TargetKeywords) do
                if objName:find(keyword:lower()) then
                    -- Buat Highlight pada objek
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "PutzzESP_Target"
                    highlight.Adornee = obj
                    highlight.FillColor = data.Color
                    highlight.FillTransparency = 0.5
                    highlight.OutlineColor = data.Color
                    highlight.OutlineTransparency = 0
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.Parent = CoreGui
                    table.insert(ESPObjects, highlight)
                    
                    -- Buat Text melayang (BillboardGui)
                    local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                    if part then
                        local billboard = Instance.new("BillboardGui")
                        billboard.Name = "PutzzESP_Label"
                        billboard.Adornee = part
                        billboard.Size = UDim2.new(0, 150, 0, 50)
                        billboard.StudsOffset = Vector3.new(0, 2, 0)
                        billboard.AlwaysOnTop = true
                        billboard.Parent = CoreGui
                        
                        local textLabel = Instance.new("TextLabel")
                        textLabel.Size = UDim2.new(1, 0, 1, 0)
                        textLabel.BackgroundTransparency = 1
                        textLabel.Text = data.Name .. " [" .. obj.Name .. "]"
                        textLabel.TextColor3 = data.Color
                        textLabel.TextStrokeTransparency = 0
                        textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
                        textLabel.TextScaled = true
                        textLabel.Font = Enum.Font.GothamBold
                        textLabel.Parent = billboard
                        
                        table.insert(ESPObjects, billboard)
                    end
                    break
                end
            end
        end
    end
end

-- ================== CUSTOM UI SYSTEM ==================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PutzzDev_CustomUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 240, 0, 160)
MainFrame.Position = UDim2.new(0, 20, 0, 20)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BackgroundTransparency = 0.1
MainFrame.BorderSizePixel = 0
MainFrame.Visible = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(0, 255, 136)
UIStroke.Thickness = 1.5
UIStroke.Transparency = 0.5
UIStroke.Parent = MainFrame

-- Top Bar (Drag & Minimize)
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 30)
TopBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
TopBar.BackgroundTransparency = 0.2
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 8)
TopCorner.Parent = TopBar

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -60, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Putzzdev | Opah"
Title.TextColor3 = Color3.fromRGB(0, 255, 136)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Title.Parent = TopBar

-- Minimize Button
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -60, 0, 0)
MinBtn.BackgroundTransparency = 1
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 14
MinBtn.Parent = TopBar

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.Parent = TopBar

-- Content Area
local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, 0, 1, -30)
Content.Position = UDim2.new(0, 0, 0, 30)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

-- Toggle Button (ESP)
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, -20, 0, 35)
ToggleBtn.Position = UDim2.new(0, 10, 0, 10)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 136)
ToggleBtn.BackgroundTransparency = 0.8
ToggleBtn.Text = "TAMPILKAN LOKASI KUNCI"
ToggleBtn.TextColor3 = Color3.fromRGB(0, 255, 136)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 12
ToggleBtn.Parent = Content

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 6)
ToggleCorner.Parent = ToggleBtn

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = Color3.fromRGB(0, 255, 136)
ToggleStroke.Parent = ToggleBtn

-- Status Text
local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(1, -20, 0, 20)
StatusText.Position = UDim2.new(0, 10, 0, 55)
StatusText.BackgroundTransparency = 1
StatusText.Text = "Status: Menunggu..."
StatusText.TextColor3 = Color3.fromRGB(150, 150, 150)
StatusText.Font = Enum.Font.Gotham
StatusText.TextSize = 10
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.Parent = Content

-- Refresh Button
local RefreshBtn = Instance.new("TextButton")
RefreshBtn.Size = UDim2.new(1, -20, 0, 30)
RefreshBtn.Position = UDim2.new(0, 10, 0, 80)
RefreshBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
RefreshBtn.Text = "SCAN ULANG MAP"
RefreshBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
RefreshBtn.Font = Enum.Font.GothamBold
RefreshBtn.TextSize = 11
RefreshBtn.Parent = Content

local RefreshCorner = Instance.new("UICorner")
RefreshCorner.CornerRadius = UDim.new(0, 6)
RefreshCorner.Parent = RefreshBtn

-- ================== FUNGSI UI ==================
local function ToggleESP()
    IsESPActive = not IsESPActive
    if IsESPActive then
        ToggleBtn.Text = "SEMBUNYIKAN LOKASI KUNCI"
        ToggleBtn.BackgroundTransparency = 0.2
        ToggleBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        StatusText.Text = "Status: Aktif (Scanning...)"
        StatusText.TextColor3 = Color3.fromRGB(0, 255, 136)
        ScanForItems()
    else
        ToggleBtn.Text = "TAMPILKAN LOKASI KUNCI"
        ToggleBtn.BackgroundTransparency = 0.8
        ToggleBtn.TextColor3 = Color3.fromRGB(0, 255, 136)
        StatusText.Text = "Status: Nonaktif"
        StatusText.TextColor3 = Color3.fromRGB(150, 150, 150)
        ClearESP()
    end
end

ToggleBtn.MouseButton1Click:Connect(ToggleESP)

RefreshBtn.MouseButton1Click:Connect(function()
    if IsESPActive then
        StatusText.Text = "Status: Re-scanning..."
        ClearESP()
        task.wait(0.1)
        ScanForItems()
        StatusText.Text = "Status: Selesai Re-scan!"
    end
end)

-- ================== DRAG SYSTEM ==================
local dragging = false
local dragInput, dragStart, startPos

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TopBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- ================== MINIMIZE / CLOSE ==================
local isMinimized = false
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        Content.Visible = false
        MainFrame.Size = UDim2.new(0, 240, 0, 30)
        MinBtn.Text = "+"
    else
        Content.Visible = true
        MainFrame.Size = UDim2.new(0, 240, 0, 160)
        MinBtn.Text = "—"
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    ClearESP()
    IsESPActive = false
end)

-- ================== AUTO UPDATE SCAN ==================
task.spawn(function()
    while task.wait(5) do
        if IsESPActive then
            ScanForItems()
        end
    end
end)

print("[PUTZZDEV] Script Item & Code Finder Loaded.")