-- ================== DRIP CLIENT MAINTENANCE / UPDATE NOTICE ==================

-- Load Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Rayfield Library
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- ================== REAL-TIME TIMER CALCULATOR ==================
local startTime = os.time()
local targetTime = startTime + 27000 -- 7.5 Jam (27000 detik)
local kickTimeout = 20 -- Waktu tunggu sebelum di-kick otomatis (60 detik)

local function getRemainingTime()
    local currentTime = os.time()
    local timeLeft = targetTime - currentTime
    
    if timeLeft <= 0 then
        return "Selesai (Menunggu Perilisan)"
    end
    
    local hours = math.floor(timeLeft / 3600)
    local minutes = math.floor((timeLeft % 3600) / 60)
    local seconds = timeLeft % 60
    
    return string.format("%02d Jam %02d Menit %02d Detik", hours, minutes, seconds)
end

-- ================== INITIALIZATION ==================
local Window = Rayfield:CreateWindow({
    Name = "Putzzdev - Drip Client 📢",
    LoadingTitle = "Drip Client System",
    LoadingSubtitle = "Maintenance Mode",
    Theme = "Amethyst",
    DisableRayfieldPrompts = true,
    DisableBuildWarnings = true,
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

-- ================== UI TABS & ELEMENTS ==================
local TabInfo = Window:CreateTab("Update Notice 🛠️", 4483362458)

TabInfo:CreateLabel("🚨 PENGUMUMAN WAJIB / MAINTENANCE SISTEM 🚨")

TabInfo:CreateParagraph({
    Title = "STATUS SCRIPT: DISABLED / UNDER DEVELOPMENT", 
    Content = "Script Drip Client saat ini DI-NONAKTIFKAN SEMENTARA. Tindakan ini diambil demi keamanan akun pengguna karena sistem mendeteksi adanya celah keamanan yang wajib diperbaiki segera."
})

TabInfo:CreateDivider()

TabInfo:CreateParagraph({
    Title = "FOKUS UTAMA MAINTENANCE:", 
    Content = "1. Memperbaiki seluruh error script dan crash eksternal.\n2. Melakukan bypass total terhadap deteksi anti-cheat game terbaru.\n3. Optimalisasi kestabilan fitur dan penambahan fitur baru premium."
})

-- Label Info Timer & Auto Kick
local TimerLabel = TabInfo:CreateLabel("Sisa Waktu Update: Menghitung...")
local KickLabel = TabInfo:CreateLabel("Game akan ditutup otomatis dalam: " .. kickTimeout .. " detik")

TabInfo:CreateDivider()

-- Tombol Saluran WhatsApp Resmi
TabInfo:CreateButton({
    Name = "📢 MASUK SALURAN WHATSAPP (KLIK UNTUK SALIN LINK)",
    Callback = function()
        setclipboard("https://whatsapp.com/channel/0029VbD9AJ36rsQm4hMLqR1R")
        Rayfield:Notify({
            Title = "Drip Client Link",
            Content = "Link Saluran WhatsApp berhasil disalin ke clipboard!",
            Duration = 3,
            Image = 4483362458
        })
    end,
})

-- ================== LOOPS & AUTOMATION ==================

-- Loop 1: Update Waktu Maintenance (Setiap 1 Detik)
task.spawn(function()
    while true do
        task.wait(1)
        pcall(function()
            TimerLabel:Set("Sisa Waktu Update: " .. getRemainingTime())
        end)
    end
end)

-- Loop 2: Hitung Mundur Auto-Kick
task.spawn(function()
    while kickTimeout > 0 do
        task.wait(1)
        kickTimeout = kickTimeout - 1
        pcall(function()
            KickLabel:Set("Game akan ditutup otomatis dalam: " .. kickTimeout .. " detik")
        end)
    end
    
    -- Eksekusi Kick setelah waktu habis
    LocalPlayer:Kick("\n[KICK by Putzzdev,due to update]\n\nMaaf cuy, game ditutup otomatis karena script sedang dalam proses update besar-besaran oleh Putzzdev.\n\nSilakan pantau perkembangan dan info rilis terbaru di Saluran WhatsApp kami!")
end)

-- Notification Load
Rayfield:Notify({
    Title = "System Notice Loaded",
    Content = "Informasi maintenance & Auto-Kick aktif.",
    Duration = 3,
    Image = 4483362458
})