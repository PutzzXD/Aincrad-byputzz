-- ====================================================================
-- CHIP BOM PREMIUM ADVANCED CLIENT (NATIVE RAYFIELD UI)
-- ====================================================================
-- Fitur: Auto ESP Bom Akurat Berdasarkan Data Player Board (1-25)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "DRIP CHIP BOM CLIENT",
   LoadingTitle = "Menginisialisasi Engine Chip Bom...",
   LoadingSubtitle = "by Putzzdev",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

-- Global States
local espBomEnabled = false
local createdAdornments = {}

-- ====================================================================
-- ENGINE LOGIKA ESP BOM
-- ====================================================================

-- Fungsi untuk membersihkan semua highlight ESP yang sedang aktif
local function clearAllESP()
    for _, adornment in ipairs(createdAdornments) do
        if adornment then pcall(function() adornment:Destroy() end) end
    end
    createdAdornments = {}
end

-- Fungsi utama untuk mendeteksi data board dan memberi highlight merah pada bom lawan
local function updateBomESP()
    if not espBomEnabled then return end
    clearAllESP()

    -- Cari semua player lain di dalam game (Lawan)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local boardFolder = player:FindFirstChild("Board")
            
            -- Pastikan folder board player tersebut ada dan valid
            if boardFolder then
                -- Scan slot 1 sampai 25 pada data player
                for i = 1, 25 do
                    local slot = boardFolder:FindFirstChild(tostring(i))
                    local slotType = slot and slot:FindFirstChild("Type")
                    
                    -- Jika tipenya adalah "Bomb", cari objek fisik 3D-nya untuk di-highlight
                    if slotType and slotType.Value == "Bomb" then
                        -- Jalur fisik 3D kotak keripik lawan di workspace
                        local targetBoard3D = Workspace:FindFirstChild("Boards") and Workspace.Boards:FindFirstChild(player.Name)
                        local chipModel = targetBoard3D and targetBoard3D:FindFirstChild("Chips") and targetBoard3D.Chips:FindFirstChild(tostring(i))
                        
                        -- Cari part utama di dalam model chip (biasanya BasePart/MeshPart/Part utama)
                        local targetPart = chipModel and (chipModel:IsA("BasePart") and chipModel or chipModel:FindFirstChildWhichIsA("BasePart"))
                        
                        if targetPart and not targetPart:FindFirstChild("DripBomVisual") then
                            -- Buat Box Highlighting Tembus Pandang Berwarna Merah menyala
                            local boxAdornment = Instance.new("BoxHandleAdornment")
                            boxAdornment.Name = "DripBomVisual"
                            boxAdornment.Size = targetPart.Size + Vector3.new(0.1, 0.2, 0.1)
                            boxAdornment.Color3 = Color3.fromRGB(255, 30, 30) -- Merah Bom
                            boxAdornment.AlwaysOnTop = true
                            boxAdornment.ZIndex = 10
                            boxAdornment.Transparency = 0.45
                            boxAdornment.Adornment = targetPart
                            boxAdornment.Parent = targetPart
                            
                            table.insert(createdAdornments, boxAdornment)
                        end
                    end
                end
            end
        end
    end
end

-- Loop dinamis menggunakan RenderStepped agar posisi ESP selalu realtime & responsif tanpa delay
RunService.RenderStepped:Connect(function()
    if espBomEnabled then
        updateBomESP()
    end
end)

-- ====================================================================
-- INTERFACE / STRUKTUR UI FORM REVENGE
-- ====================================================================

local MainTab = Window:CreateTab("Game Hacks", 4483362458)

MainTab:CreateToggle({
   Name = "ESP Reveal Bom",
   CurrentValue = false,
   Flag = "DripEspBomFlag",
   Callback = function(Value)
      espBomEnabled = Value
      if Value then
          Rayfield:Notify({Title = "ESP AKTIF", Content = "Membaca database kartu lawan... Kotak bom ditandai MERAH!", Duration = 3})
          updateBomESP()
       else
          clearAllESP()
          Rayfield:Notify({Title = "ESP NONAKTIF", Content = "Semua visual penanda bom telah dibersihkan.", Duration = 2})
       end
   end,
})

local CreditsTab = Window:CreateTab("Credits", 4483362458)
CreditsTab:CreateLabel("Developer: Putzzdev")
CreditsTab:CreateLabel("Script khusus project baru Chip Bom")

Rayfield:LoadConfiguration()