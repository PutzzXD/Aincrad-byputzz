-- ====================================================================
-- CHIP BOM CUSTOM CLIENT - BASE SCRIPT
-- ====================================================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Membuat Window Utama UI
local Window = Rayfield:CreateWindow({
   Name = "Chip Bom Client v1.0",
   LoadingTitle = "Loading Custom Script...",
   LoadingSubtitle = "by Putzzdev",
   ConfigurationSaving = {
      Enabled = false
   },
   Discord = {
      Enabled = false
   },
   KeySystem = false
})

-- Variables untuk State Fitur
local espBomEnabled = false
local autoReadyEnabled = false
local espObjects = {}

-- ====================================================================
-- KANVAS LOGIKA / FUNGSI UTAMA (SISTEM ESP)
-- ====================================================================

-- Fungsi untuk membuat highlight visual pada objek bom
local function applyBomESP(object)
   if not object:IsA("BasePart") then return end
   
   -- Membuat Box Highlight merah di sekitar kotak bom lawan
   local highlight = Instance.new("BoxHandleAdornment")
   highlight.Name = "BomESP_Adornment"
   highlight.Size = object.Size + Vector3.new(0.1, 0.1, 0.1)
   highlight.Color3 = Color3.fromRGB(255, 0, 0) -- Warna Merah untuk Bom
   highlight.AlwaysOnTop = true
   highlight.ZIndex = 10
   highlight.Adornment = object
   highlight.Transparency = 0.4
   highlight.Parent = object
   
   table.insert(espObjects, highlight)
end

-- Fungsi untuk membersihkan semua visual ESP
local function clearBomESP()
   for _, obj in ipairs(espObjects) do
      if obj and obj.Parent then
         obj:Destroy()
      end
   end
   espObjects = {}
end

-- Fungsi Tracker untuk memantau perubahan folder permainan
-- Catatan: Kamu perlu menyesuaikan path folder dan nama "Bomb" sesuai struktur asli game
local function startBomTracker()
   task.spawn(function()
      while espBomEnabled do
         -- Contoh logika pemindaian: mencari objek bernama 'Bomb' di Workspace
         -- Pastikan untuk memeriksa Remote Spy atau Explorer game kamu terlebih dahulu
         for _, desc in ipairs(workspace:GetDescendants()) do
            if desc.Name == "Bomb" or desc:SetAttribute("IsBomb") == true then
               if not desc:FindFirstChild("BomESP_Adornment") then
                  applyBomESP(desc)
               end
            end
         end
         task.wait(1) -- Pemindaian berkala setiap 1 detik agar tidak lag
      end
   end)
end

-- ====================================================================
-- INTERFACE / TOMBOL UI (TAB & TOGGLES)
-- ====================================================================

-- Tab Utama untuk Fitur Hack Game
local MainTab = Window:CreateTab("Main Hacks", 4483362458) -- Icon ID

local EspToggle = MainTab:CreateToggle({
   Name = "ESP Bom (Revealer)",
   CurrentValue = false,
   Flag = "EspBomFlag",
   Callback = function(Value)
      espBomEnabled = Value
      if Value then
         Rayfield:Notify({Title = "ESP Aktif", Content = "Mulai melacak posisi bom lawan...", Duration = 2, Image = 4483362458})
         startBomTracker()
      else
         clearBomESP()
         Rayfield:Notify({Title = "ESP Nonaktif", Content = "Visual bom dibersihkan.", Duration = 2, Image = 4483362458})
      end
   end,
})

-- Tab Tambahan untuk Otomasi
local AutomationTab = Window:CreateTab("Automation", 4483362458)

local ReadyToggle = AutomationTab:CreateToggle({
   Name = "Auto Ready / Join Match",
   CurrentValue = false,
   Flag = "AutoReadyFlag",
   Callback = function(Value)
      autoReadyEnabled = Value
      
      -- Kerangka dasar loop untuk mengklik tombol Ready otomatis
      task.spawn(function()
         while autoReadyEnabled do
            -- Ganti path ini dengan RemoteEvent atau UI Button Klik milik game asli
            -- pcall(function() game:GetService("ReplicatedStorage").RemoteEvents.Ready:FireServer() end)
            task.wait(2)
         end
      end)
   end,
})

-- Tab Informasi Developer
local InfoTab = Window:CreateTab("Credits", 4483362458)
InfoTab:CreateLabel("Developer: Putzzdev")
InfoTab:CreateLabel("Dibuat khusus untuk Chip Bom Roblox")

Rayfield:LoadConfiguration()