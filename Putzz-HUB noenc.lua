-- ================== DRIP CLIENT V8.2 PREMIUM - RAYFIELD UI ==================

-- ================== LOAD SERVICES ==================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")

-- ================== DETEKSI NAMA EXECUTOR ==================
local function detectExecutor()
    local executorName = "Unknown Executor"
    local executors = {
        {name = "Delta", check = function() return syn and syn.request and syn.crypt end},
        {name = "Arceus X", check = function() return game:GetService("CoreGui"):FindFirstChild("Arceus X V2") or (identifyexecutor and identifyexecutor() == "Arceus X") end},
        {name = "CodeX", check = function() return CodeX and CodeX.Execute end},
        {name = "Hydrogen", check = function() return isfile and readfile and writefile and (not syn) end},
        {name = "Fluxus", check = function() return fluxus and fluxus.ismobile end},
        {name = "Krnl", check = function() return krnl and krnl.loadlibrary end},
        {name = "ScriptWare", check = function() return scriptware and scriptware.loader end},
        {name = "Synapse X", check = function() return syn and syn.crypt and syn.request end},
        {name = "Evon", check = function() return evon and evon.execute end},
        {name = "Vega X", check = function() return game:GetService("CoreGui"):FindFirstChild("Vega Hub") end},
        {name = "Swift", check = function() return Swift and Swift.Execute end},
        {name = "Nexus", check = function() return Nexus and Nexus.Load end}
    }
    for _, exec in ipairs(executors) do
        local success, result = pcall(exec.check)
        if success and result then executorName = exec.name break end
    end
    local success, idName = pcall(function() if identifyexecutor then return identifyexecutor() end return nil end)
    if success and idName and idName ~= "" then executorName = idName end
    return executorName
end

local userExecutor = detectExecutor()

-- ================== GLOBAL STATE & FILE SAVING SYSTEM ==================
local FIREBASE_URL = "https://key-database-701af-default-rtdb.asia-southeast1.firebasedatabase.app/keys.json"
local WEBSITE_URL = "https://drip-client-get-key.vercel.app/"
local SAVE_FILE = "drip_key_data.txt"

local activeKeys = {}
local currentUserKey = nil
local keyExpiryTime = 0
local keyJenis = ""
local keyValidGlobal = false
local infoKeyCountdownLabel = nil
local mainWindowLoaded = false
local keyWindowRef = nil

local function loadKeyData()
    if isfile and isfile(SAVE_FILE) then
        local success, content = pcall(function() return readfile(SAVE_FILE) end)
        if success and content and content ~= "" then
            local success2, data = pcall(function() return HttpService:JSONDecode(content) end)
            if success2 then activeKeys = data end
        end
    end
end

local function saveKeyData()
    if writefile then
        local success, json = pcall(function() return HttpService:JSONEncode(activeKeys) end)
        if success then writefile(SAVE_FILE, json) end
    end
end

local function getKeysFromFirebase()
    local success, data = pcall(function() return game:HttpGet(FIREBASE_URL) end)
    if success and data then
        local success2, jsonData = pcall(function() return HttpService:JSONDecode(data) end)
        if success2 and jsonData then
            local keysArray = {}
            for _, keyData in pairs(jsonData) do table.insert(keysArray, keyData) end
            return keysArray
        end
    end
    return nil
end

local function getTimeRemaining(expiryTimestamp)
    local currentTime = os.time()
    local remaining = expiryTimestamp - currentTime
    if remaining <= 0 then return 0, 0, 0, 0, "EXPIRED" end
    local days    = math.floor(remaining / 86400)
    local hours   = math.floor((remaining % 86400) / 3600)
    local minutes = math.floor((remaining % 3600) / 60)
    local seconds = remaining % 60
    return days, hours, minutes, seconds,
        string.format("%d Hari %02d Jam %02d Menit %02d Detik", days, hours, minutes, seconds)
end

local function checkKeyExpiry(inputKey)
    loadKeyData()
    local keysData = getKeysFromFirebase()
    if not keysData then return false, "Gagal mengambil data server" end

    local foundData = nil
    for _, keyData in ipairs(keysData) do
        if keyData.key == inputKey then
            foundData = keyData
            break
        end
    end

    if not foundData then return false, "KEY TIDAK TERDAFTAR!" end
    if foundData.status and foundData.status ~= "aktif" then
        return false, "KEY TIDAK AKTIF!"
    end

    local currentTime = os.time()
    local expiryTime  = nil
    local keyJenisData = foundData.jenis or "1 HARI"

    if foundData.expiry_timestamp and foundData.expiry_timestamp ~= nil then
        expiryTime = math.floor(foundData.expiry_timestamp / 1000)
        if currentTime > expiryTime then
            return false, "KEY SUDAH EXPIRED!"
        end
    elseif keyJenisData == "PERMANEN" then
        expiryTime = math.huge
    else
        if activeKeys[inputKey] and activeKeys[inputKey].expiryTime then
            expiryTime = activeKeys[inputKey].expiryTime
            if currentTime > expiryTime then
                return false, "KEY SUDAH EXPIRED!"
            end
        else
            local expiryDays = 1
            if keyJenisData == "1 JAM"   then expiryDays = 1/24
            elseif keyJenisData == "1 HARI"  then expiryDays = 1
            elseif keyJenisData == "2 HARI"  then expiryDays = 2
            elseif keyJenisData == "3 HARI"  then expiryDays = 3
            elseif keyJenisData == "7 HARI"  then expiryDays = 7
            elseif keyJenisData == "30 HARI" then expiryDays = 30
            end
            expiryTime = currentTime + math.floor(expiryDays * 86400)
        end
    end

    activeKeys[inputKey] = {
        firstUsed  = activeKeys[inputKey] and activeKeys[inputKey].firstUsed or currentTime,
        key        = inputKey,
        expiryTime = expiryTime,
        jenis      = keyJenisData,
        expiry_timestamp_ms = foundData.expiry_timestamp,
    }
    saveKeyData()

    keyExpiryTime    = expiryTime
    keyJenis         = keyJenisData
    currentUserKey   = inputKey
    keyValidGlobal   = true

    local _, _, _, _, timeStr = getTimeRemaining(expiryTime)
    return true, "VALID! Sisa: " .. timeStr
end

-- ================== AUTO RE-SYNC EXPIRY DARI FIREBASE ==================
task.spawn(function()
    while true do
        task.wait(60)
        if not keyValidGlobal or not currentUserKey then continue end

        local ok, keysData = pcall(function() return getKeysFromFirebase() end)
        if not (ok and keysData) then continue end

        for _, keyData in ipairs(keysData) do
            if keyData.key == currentUserKey then
                if keyData.expiry_timestamp and keyData.expiry_timestamp ~= nil then
                    local newExpiry = math.floor(keyData.expiry_timestamp / 1000)
                    if newExpiry ~= keyExpiryTime then
                        keyExpiryTime = newExpiry
                        if activeKeys[currentUserKey] then
                            activeKeys[currentUserKey].expiryTime = newExpiry
                            activeKeys[currentUserKey].expiry_timestamp_ms = keyData.expiry_timestamp
                            pcall(saveKeyData)
                        end
                    end
                end
                if keyData.status and keyData.status ~= "aktif" then
                    keyValidGlobal = false
                end
                break
            end
        end
    end
end)

local espEnabled = false
local lineEnabled = false
local lineColor = Color3.fromRGB(255, 255, 255)
local skeletonEnabled = false
local espNameEnabled = false
local espHealthEnabled = false
local ESPTable = {}
local SkeletonESP = {}

-- HOLOGRAM CHAMS
local chamsEnabled = false
local chamsColor = Color3.fromRGB(0, 255, 0)
local chamsTransparency = 0.2
local chamsParts = {}
local chamsConnections = {}

local playerCounterEnabled = false
local enemyCountText = nil

local autoParryEnabled = false
local parryDistance = 8
local parryCooldown = 0.5
local lastParryTime = 0
local parryConnection = nil

local noclipEnabled = false
local noclipConnection = nil

local speedEnabled = false
local normalSpeed = 16
local fastSpeed = 60

local jumpPowerEnabled = false
local jumpPowerValue = 50
local infinityJumpEnabled = false

local antiDamageEnabled = false
local antiDamageConnection = nil

local spinEnabled = false
local spinSpeed = 50
local spinConnection = nil
local spinDirection = 1

local invisibleEnabled = false
local invisibleConnection = nil
local invisibleParts = {}
local invisibleRootPart = nil
local invisibleHumanoid = nil

local skeletonColor = Color3.fromRGB(0, 255, 0)
local boxColor = Color3.fromRGB(255, 255, 255)
local MAX_ESP_DISTANCE = 200000

-- FITUR BYPASS
local fullBrightEnabled = false
local originalBrightness = Lighting.Brightness
local originalClockTime = Lighting.ClockTime
local originalAmbient = Lighting.Ambient
local originalColorShift_Bottom = Lighting.ColorShift_Bottom
local originalColorShift_Top = Lighting.ColorShift_Top
local originalOutdoorAmbient = Lighting.OutdoorAmbient

local noFogEnabled = false
local originalFogEnd = Lighting.FogEnd
local originalFogStart = Lighting.FogStart
local originalFogColor = Lighting.FogColor

-- ================== ENGINE ACTIONS ==================
local function startNoclip()
    if noclipConnection then noclipConnection:Disconnect() end
    noclipConnection = RunService.Stepped:Connect(function()
        if noclipEnabled and LocalPlayer.Character then
            for _, p in pairs(LocalPlayer.Character:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end)
end

local function stopNoclip()
    if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
end

local function toggleSpin(state)
    spinEnabled = state
    if spinConnection then spinConnection:Disconnect() spinConnection = nil end
    if state then
        spinConnection = RunService.Heartbeat:Connect(function()
            if spinEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame *= CFrame.Angles(0, math.rad(spinSpeed * spinDirection), 0)
            end
        end)
    end
end

local function toggleInvisible(state)
    invisibleEnabled = state
    if invisibleConnection then invisibleConnection:Disconnect() invisibleConnection = nil end
    if state and LocalPlayer.Character then
        invisibleParts = {}
        invisibleRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        invisibleHumanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") and v.Transparency == 0 then
                table.insert(invisibleParts, {part = v, origTrans = v.Transparency})
                v.Transparency = 0.5
            end
        end
        invisibleConnection = RunService.Heartbeat:Connect(function()
            if invisibleEnabled and invisibleRootPart and invisibleHumanoid then
                local oldCF = invisibleRootPart.CFrame
                local oldOffset = invisibleHumanoid.CameraOffset
                local hideCF = oldCF * CFrame.new(0, -500000, 0)
                invisibleRootPart.CFrame = hideCF
                invisibleHumanoid.CameraOffset = hideCF:ToObjectSpace(CFrame.new(oldCF.Position)).Position
                RunService.RenderStepped:Wait()
                invisibleRootPart.CFrame = oldCF
                invisibleHumanoid.CameraOffset = oldOffset
            end
        end)
    else
        if LocalPlayer.Character then
            for _, data in pairs(invisibleParts) do
                pcall(function()
                    if data.part and data.part.Parent then
                        data.part.Transparency = data.origTrans
                    end
                end)
            end
            for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
                if v:IsA("BasePart") and v.Transparency == 0.5 then v.Transparency = 0 end
            end
        end
        invisibleParts = {}
        invisibleRootPart = nil
        invisibleHumanoid = nil
    end
end

-- HOLOGRAM CHAMS
local function applyChams(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char then return end

    pcall(function()
        local old = char:FindFirstChild("ChamsHighlight")
        if old then old:Destroy() end

        local hl = Instance.new("Highlight")
        hl.Name = "ChamsHighlight"
        hl.FillColor = chamsColor
        hl.FillTransparency = chamsTransparency
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Adornee = char
        hl.Parent = char
        chamsParts[player] = hl
    end)
end

local function removeChams(player)
    if not player then return end
    local hl = chamsParts[player]
    if hl then pcall(function() hl:Destroy() end) end
    chamsParts[player] = nil
    if player.Character then
        local stray = player.Character:FindFirstChild("ChamsHighlight")
        if stray then pcall(function() stray:Destroy() end) end
    end
end

local function toggleChams(state)
    chamsEnabled = state
    if state then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then applyChams(player) end
        end
        local conn = Players.PlayerAdded:Connect(function(player)
            player.CharacterAdded:Connect(function()
                task.wait(0.5)
                if chamsEnabled and player ~= LocalPlayer then applyChams(player) end
            end)
            if chamsEnabled and player ~= LocalPlayer then
                task.wait(0.5)
                applyChams(player)
            end
        end)
        table.insert(chamsConnections, conn)
        local conn2 = Players.PlayerRemoving:Connect(function(player)
            removeChams(player)
        end)
        table.insert(chamsConnections, conn2)
    else
        for _, player in pairs(Players:GetPlayers()) do removeChams(player) end
        for _, conn in pairs(chamsConnections) do pcall(function() conn:Disconnect() end) end
        chamsConnections = {}
    end
end

-- FULL BRIGHT
local function toggleFullBright(state)
    fullBrightEnabled = state
    if state then
        originalBrightness = Lighting.Brightness
        originalClockTime = Lighting.ClockTime
        originalAmbient = Lighting.Ambient
        originalColorShift_Bottom = Lighting.ColorShift_Bottom
        originalColorShift_Top = Lighting.ColorShift_Top
        originalOutdoorAmbient = Lighting.OutdoorAmbient

        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.Ambient = Color3.fromRGB(178, 178, 178)
        Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
        Lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0)
        Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000

        for _, v in pairs(Lighting:GetChildren()) do
            if v:IsA("Atmosphere") or v:IsA("ColorCorrectionEffect") or v:IsA("BlurEffect") then
                v.Enabled = false
            end
        end
    else
        Lighting.Brightness = originalBrightness
        Lighting.ClockTime = originalClockTime
        Lighting.Ambient = originalAmbient
        Lighting.ColorShift_Bottom = originalColorShift_Bottom
        Lighting.ColorShift_Top = originalColorShift_Top
        Lighting.OutdoorAmbient = originalOutdoorAmbient
        Lighting.GlobalShadows = true
        Lighting.FogEnd = originalFogEnd or 1000
        for _, v in pairs(Lighting:GetChildren()) do
            if v:IsA("Atmosphere") or v:IsA("ColorCorrectionEffect") or v:IsA("BlurEffect") then
                v.Enabled = true
            end
        end
    end
end

-- NO FOG
local originalAtmosphereDensity = nil
local originalAtmosphereHaze = nil

local function toggleNoFog(state)
    noFogEnabled = state
    if state then
        originalFogEnd = Lighting.FogEnd
        originalFogStart = Lighting.FogStart
        originalFogColor = Lighting.FogColor
        Lighting.FogEnd = 10000000
        Lighting.FogStart = 10000000
        for _, v in pairs(Lighting:GetChildren()) do
            if v:IsA("Atmosphere") then
                originalAtmosphereDensity = v.Density
                originalAtmosphereHaze = v.Haze
                v.Density = 0
                v.Haze = 0
            end
        end
    else
        Lighting.FogEnd = originalFogEnd or 1000
        Lighting.FogStart = originalFogStart or 0
        Lighting.FogColor = originalFogColor or Color3.fromRGB(127, 127, 127)
        for _, v in pairs(Lighting:GetChildren()) do
            if v:IsA("Atmosphere") then
                v.Density = originalAtmosphereDensity or 0.3
                v.Haze = originalAtmosphereHaze or 0
            end
        end
    end
end

-- REJOIN SERVER
local function rejoinServer()
    if Rayfield then
        Rayfield:Notify({
            Title = "Rejoin",
            Content = "Sedang merejoin server...",
            Duration = 3,
            Image = 4483362458
        })
    end
    task.wait(1)
    if #Players:GetPlayers() <= 1 then
        LocalPlayer:Kick("\nRejoining...")
        task.wait(0.5)
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    else
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
end

-- SERVER HOP
local function serverHop()
    if Rayfield then
        Rayfield:Notify({
            Title = "Server Hop",
            Content = "Mencari server baru...",
            Duration = 3,
            Image = 4483362458
        })
    end
    task.wait(1)

    local success, err = pcall(function()
        local serverList = {}
        local req = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
        local decoded = HttpService:JSONDecode(req)

        if decoded and decoded.data then
            for _, server in ipairs(decoded.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    table.insert(serverList, server.id)
                end
            end
        end

        if #serverList > 0 then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, serverList[math.random(1, #serverList)], LocalPlayer)
        else
            error("Tidak menemukan server alternatif.")
        end
    end)

    if not success then
        if Rayfield then
            Rayfield:Notify({
                Title = "Server Hop",
                Content = "Mencoba metode alternatif...",
                Duration = 3,
                Image = 4483362458
            })
        end
        task.wait(1)
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
end

-- GOD MODE
local function toggleGodMode(state)
    antiDamageEnabled = state
    if antiDamageConnection then antiDamageConnection:Disconnect() antiDamageConnection = nil end

    if state then
        antiDamageConnection = RunService.Heartbeat:Connect(function()
            if antiDamageEnabled and LocalPlayer.Character then
                local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    if humanoid.Health > 0 and humanoid.Health < humanoid.MaxHealth then
                        humanoid.Health = humanoid.MaxHealth
                    end
                end
            end
        end)
    end
end

UserInputService.JumpRequest:Connect(function()
    if infinityJumpEnabled and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

RunService.Heartbeat:Connect(function()
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum and jumpPowerEnabled then
            hum.UseJumpPower = true
            hum.JumpPower = jumpPowerValue
        end
    end
end)

-- ================== ESP SYSTEM ==================
local function createPlayerCounter()
    if enemyCountText then pcall(function() enemyCountText:Remove() end) end
    enemyCountText = Drawing.new("Text")
    enemyCountText.Size = 22
    enemyCountText.Color = Color3.fromRGB(255, 255, 255)
    enemyCountText.Center = true
    enemyCountText.Outline = true
    enemyCountText.Position = Vector2.new(Camera.ViewportSize.X / 2, 55)
    enemyCountText.Visible = false
    enemyCountText.Text = "PLAYERS: 0"
end

local function createESP(player)
    if player == LocalPlayer then return end
    local box = Drawing.new("Square") box.Thickness = 1.8 box.Filled = false box.Visible = false
    box.Color = boxColor

    local name = Drawing.new("Text") name.Size = 15 name.Center = true name.Outline = true name.Visible = false
    name.Color = Color3.fromRGB(255, 0, 0)

    local dist = Drawing.new("Text") dist.Size = 12 dist.Center = true dist.Outline = true dist.Visible = false
    dist.Color = Color3.fromRGB(200, 200, 200)

    local line = Drawing.new("Line") line.Thickness = 1.8 line.Visible = false
    line.Color = lineColor

    local healthBg = Drawing.new("Square") healthBg.Filled = true healthBg.Visible = false
    local healthFg = Drawing.new("Square") healthFg.Filled = true healthFg.Visible = false

    ESPTable[player] = {box, name, dist, line, healthBg, healthFg}
end

local function createSkeleton(player)
    if player == LocalPlayer then return end
    local lines = {}
    local joints = {
        {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
        {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},
        {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},
        {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},
        {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"}
    }
    for i=1, #joints do
        local l = Drawing.new("Line") l.Thickness = 2 l.Color = Color3.fromRGB(255, 255, 255) l.Visible = false
        table.insert(lines, {l, joints[i][1], joints[i][2]})
    end
    SkeletonESP[player] = lines
end

-- ================== RAINBOW COLOR HELPER ==================
local rainbowHue = 0
local function getRainbowColor()
    rainbowHue = (rainbowHue + 0.005) % 1
    return Color3.fromHSV(rainbowHue, 1, 1)
end

RunService.RenderStepped:Connect(function()
    local myChar = LocalPlayer.Character
    local myPos = myChar and myChar:FindFirstChild("HumanoidRootPart") and myChar.HumanoidRootPart.Position
    local screenCount = 0
    local rainbowColor = getRainbowColor()

    for player, esp in pairs(ESPTable) do
        local box, name, distText, line, hBg, hFg = unpack(esp)
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Head") then
            local hrp = char.HumanoidRootPart
            local head = char.Head
            local hum = char:FindFirstChildOfClass("Humanoid")
            local pos, visible = Camera:WorldToViewportPoint(hrp.Position)
            local distance = myPos and (myPos - hrp.Position).Magnitude or 9999

            local vp = Camera.ViewportSize
            local screenX = math.clamp(pos.X, 10, vp.X - 10)
            local screenY = math.clamp(pos.Y, 10, vp.Y - 10)
            local isOnScreen = visible and pos.Z > 0

            if isOnScreen and distance <= MAX_ESP_DISTANCE then
                screenCount = screenCount + 1
                local top    = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local bottom = Camera:WorldToViewportPoint(hrp.Position  - Vector3.new(0, 3,   0))
                local height = math.abs(top.Y - bottom.Y)
                local width  = height / 2

                height = math.max(height, 10)
                width  = math.max(width,  5)

                local boxX = math.clamp(screenX - width/2, 2, vp.X - width - 2)
                local boxTopY = math.clamp(top.Y, 2, vp.Y - height - 2)

                if espEnabled then
                    box.Size     = Vector2.new(width, height)
                    box.Position = Vector2.new(boxX, boxTopY)
                    box.Color    = boxColor
                    box.Visible  = true

                    distText.Text     = math.floor(distance).."m"
                    distText.Position = Vector2.new(screenX, boxTopY + height + 4)
                    distText.Color    = Color3.fromRGB(200, 200, 200)
                    distText.Visible  = true

                    if espNameEnabled then
                        name.Position = Vector2.new(screenX, boxTopY - 18)
                        name.Text     = "Putzzdev Xit"
                        name.Color    = rainbowColor
                        name.Visible  = true
                    else
                        name.Visible = false
                    end

                    if espHealthEnabled and hum then
                        local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                        hBg.Size     = Vector2.new(4, height)
                        hBg.Position = Vector2.new(boxX + width + 3, boxTopY)
                        hBg.Color    = Color3.fromRGB(40, 40, 40)
                        hBg.Visible  = true
                        hFg.Size     = Vector2.new(4, height * pct)
                        hFg.Position = Vector2.new(boxX + width + 3, boxTopY + height - (height * pct))
                        hFg.Color    = Color3.fromRGB(255*(1-pct), 255*pct, 0)
                        hFg.Visible  = true
                    else
                        hBg.Visible = false
                        hFg.Visible = false
                    end
                else
                    box.Visible = false; name.Visible = false; distText.Visible = false
                    hBg.Visible = false; hFg.Visible = false
                end
            else
                box.Visible = false; name.Visible = false; distText.Visible = false
                hBg.Visible = false; hFg.Visible = false
            end

            if lineEnabled and visible and pos.Z > 0 and distance <= MAX_ESP_DISTANCE then
                local top2 = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local lineToX = math.clamp(top2.X, 2, vp.X - 2)
                local lineToY = math.clamp(top2.Y, 2, vp.Y - 2)
                line.From    = Vector2.new(vp.X / 2, 0)
                line.To      = Vector2.new(lineToX, lineToY)
                line.Color   = lineColor
                line.Visible = true
            else
                line.Visible = false
            end
        end
    end

    if skeletonEnabled then
        for player, lines in pairs(SkeletonESP) do
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") and myPos then
                for _, lData in pairs(lines) do
                    local l, p1, p2 = lData[1], char:FindFirstChild(lData[2]), char:FindFirstChild(lData[3])
                    if p1 and p2 then
                        local pos1, vis1 = Camera:WorldToViewportPoint(p1.Position)
                        local pos2, vis2 = Camera:WorldToViewportPoint(p2.Position)
                        if vis1 and vis2 then
                            l.From = Vector2.new(pos1.X, pos1.Y)
                            l.To = Vector2.new(pos2.X, pos2.Y)
                            l.Color = Color3.fromRGB(255, 255, 255)
                            l.Visible = true
                        else l.Visible = false end
                    else l.Visible = false end
                end
            else
                for _, ld in pairs(lines) do ld[1].Visible = false end
            end
        end
    else
        for _, lines in pairs(SkeletonESP) do for _, ld in pairs(lines) do ld[1].Visible = false end end
    end

    if playerCounterEnabled and enemyCountText then
        enemyCountText.Text = "PLAYERS: " .. screenCount
        enemyCountText.Visible = true
    elseif enemyCountText then
        enemyCountText.Visible = false
    end
end)

task.spawn(function()
    while true do
        task.wait(5)
        for part, _ in pairs(chamsParts) do
            if not part or not part.Parent then
                chamsParts[part] = nil
            end
        end
    end
end)

-- ================== MAIN RAYFIELD UI ==================
local function loadMainScript()
    if mainWindowLoaded then return end
    mainWindowLoaded = true

    createPlayerCounter()

    if not Rayfield then
        Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
    end

    local Window = Rayfield:CreateWindow({
        Name = "Putzzdev XIT",
        LoadingTitle = "Drip Client",
        LoadingSubtitle = "Premium v8.2",
        Theme = "Amethyst",
        DisableRayfieldPrompts = true,
        DisableBuildWarnings = true,
        ConfigurationSaving = {
            Enabled = false,
        },
        KeySystem = false,
    })

    -- ================== TAB MAIN ==================
    local TabMain = Window:CreateTab("Main", "zap")

    TabMain:CreateDivider()

    TabMain:CreateToggle({
        Name = "Speed Boost",
        CurrentValue = false,
        Flag = "SpeedBoost",
        Callback = function(state)
            speedEnabled = state
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = state and fastSpeed or normalSpeed end
        end,
    })

    TabMain:CreateSlider({
        Name = "Walk Speed",
        Range = {16, 500},
        Increment = 1,
        Suffix = "",
        CurrentValue = fastSpeed,
        Flag = "WalkSpeed",
        Callback = function(val)
            fastSpeed = val
            if speedEnabled then
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = val end
            end
        end,
    })

    TabMain:CreateDivider()

    TabMain:CreateToggle({
        Name = "NoClip",
        CurrentValue = false,
        Flag = "NoClip",
        Callback = function(state)
            noclipEnabled = state
            if state then startNoclip() else stopNoclip() end
        end,
    })

    TabMain:CreateToggle({
        Name = "Infinity Jump",
        CurrentValue = false,
        Flag = "InfJump",
        Callback = function(state)
            infinityJumpEnabled = state
        end,
    })

    TabMain:CreateToggle({
        Name = "God Mode",
        CurrentValue = false,
        Flag = "GodMode",
        Callback = function(state)
            toggleGodMode(state)
        end,
    })

    TabMain:CreateDivider()

    TabMain:CreateToggle({
        Name = "Spin Muter",
        CurrentValue = false,
        Flag = "Spin",
        Callback = function(state)
            toggleSpin(state)
        end,
    })

    TabMain:CreateSlider({
        Name = "Spin Speed",
        Range = {1, 200},
        Increment = 1,
        Suffix = "",
        CurrentValue = spinSpeed,
        Flag = "SpinSpeed",
        Callback = function(val)
            spinSpeed = val
        end,
    })

    TabMain:CreateToggle({
        Name = "Invisible Mode",
        CurrentValue = false,
        Flag = "Invisible",
        Callback = function(state)
            toggleInvisible(state)
        end,
    })

    -- ================== TAB ESP ==================
    local TabESP = Window:CreateTab("ESP", "eye")

    TabESP:CreateToggle({
        Name = "ESP Box",
        CurrentValue = false,
        Flag = "ESPBox",
        Callback = function(state)
            espEnabled = state
        end,
    })

    TabESP:CreateToggle({
        Name = "ESP Name",
        CurrentValue = false,
        Flag = "ESPName",
        Callback = function(state)
            espNameEnabled = state
        end,
    })

    TabESP:CreateToggle({
        Name = "ESP Health",
        CurrentValue = false,
        Flag = "ESPHealth",
        Callback = function(state)
            espHealthEnabled = state
        end,
    })

    TabESP:CreateToggle({
        Name = "ESP Line",
        CurrentValue = false,
        Flag = "ESPLine",
        Callback = function(state)
            lineEnabled = state
        end,
    })

    TabESP:CreateToggle({
        Name = "ESP Skeleton",
        CurrentValue = false,
        Flag = "ESPSkeleton",
        Callback = function(state)
            skeletonEnabled = state
        end,
    })

    TabESP:CreateToggle({
        Name = "Player Counter",
        CurrentValue = false,
        Flag = "PlayerCounter",
        Callback = function(state)
            playerCounterEnabled = state
        end,
    })

    TabESP:CreateToggle({
        Name = "HOLOGRAM",
        CurrentValue = false,
        Flag = "Hologram",
        Callback = function(state)
            toggleChams(state)
            if Rayfield then
                Rayfield:Notify({
                    Title = "Hologram",
                    Content = state and "Hologram DI-AKTIFKAN" or "Hologram Dinonaktifkan",
                    Duration = 2,
                    Image = 4483362458
                })
            end
        end,
    })

    -- ================== TAB SETTINGS ==================
    local TabSettings = Window:CreateTab("Settings", "settings")

    -- ================== AIMLOCK / AIMBOT ==================
    TabSettings:CreateSection("🎯 Aimlock / Aimbot")

    local aimlockEnabled  = false
    local aimlockTarget   = "Player"
    local aimlockFOV      = 100
    local aimlockConn     = nil
    local aimlockSmooth   = 0.1

    local function getNearestTarget()
        local myChar = LocalPlayer.Character
        local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return nil end

        local nearest, nearestDist = nil, math.huge
        local vp = Camera.ViewportSize
        local centerX, centerY = vp.X/2, vp.Y/2

        if aimlockTarget == "Player" or aimlockTarget == "Both" then
            for _, p in pairs(Players:GetPlayers()) do
                if p == LocalPlayer then continue end
                local char = p.Character
                local head = char and char:FindFirstChild("Head")
                if not head then continue end
                local sp, vis = Camera:WorldToViewportPoint(head.Position)
                if not vis then continue end
                local screenDist = math.sqrt((sp.X-centerX)^2 + (sp.Y-centerY)^2)
                if screenDist < aimlockFOV and screenDist < nearestDist then
                    nearestDist = screenDist
                    nearest = head
                end
            end
        end

        if aimlockTarget == "NPC" or aimlockTarget == "Both" then
            local playerChars = {}
            for _, p in pairs(Players:GetPlayers()) do
                if p.Character then playerChars[p.Character] = true end
            end
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("Model") and not playerChars[obj] then
                    local hum = obj:FindFirstChildOfClass("Humanoid")
                    local head = obj:FindFirstChild("Head")
                    if hum and head and hum.Health > 0 then
                        local sp, vis = Camera:WorldToViewportPoint(head.Position)
                        if not vis then continue end
                        local screenDist = math.sqrt((sp.X-centerX)^2 + (sp.Y-centerY)^2)
                        if screenDist < aimlockFOV and screenDist < nearestDist then
                            nearestDist = screenDist
                            nearest = head
                        end
                    end
                end
            end
        end

        return nearest
    end

    local function startAimlock()
        if aimlockConn then aimlockConn:Disconnect() end
        aimlockConn = RunService.RenderStepped:Connect(function()
            if not aimlockEnabled then return end
            local target = getNearestTarget()
            if not target then return end
            local targetCF = CFrame.new(Camera.CFrame.Position, target.Position)
            Camera.CFrame = Camera.CFrame:Lerp(targetCF, math.clamp(1 - aimlockSmooth, 0.01, 1))
        end)
    end

    TabSettings:CreateToggle({
        Name = "Aimlock Aktif",
        CurrentValue = false,
        Flag = "AimlockToggle",
        Callback = function(state)
            aimlockEnabled = state
            if state then
                startAimlock()
                Rayfield:Notify({Title="Aimlock", Content="Aktif! Target: "..aimlockTarget, Duration=2, Image=4483362458})
            else
                if aimlockConn then aimlockConn:Disconnect(); aimlockConn=nil end
                Rayfield:Notify({Title="Aimlock", Content="Dinonaktifkan.", Duration=2, Image=4483362458})
            end
        end,
    })

    TabSettings:CreateDropdown({
        Name = "Target Aimlock",
        Options = {"Player", "NPC", "Both"},
        CurrentOption = {"Player"},
        Flag = "AimlockTarget",
        Callback = function(selected)
            aimlockTarget = type(selected)=="table" and selected[1] or selected
        end,
    })

    TabSettings:CreateSlider({
        Name = "FOV Radius (pixel)",
        Range = {20, 400},
        Increment = 10,
        Suffix = "px",
        CurrentValue = 100,
        Flag = "AimlockFOV",
        Callback = function(v) aimlockFOV = v end,
    })

    TabSettings:CreateSlider({
        Name = "Smooth (0=Instant)",
        Range = {0, 90},
        Increment = 5,
        Suffix = "%",
        CurrentValue = 10,
        Flag = "AimlockSmooth",
        Callback = function(v) aimlockSmooth = v/100 end,
    })

    -- ================== ESP COLOR PICKER ==================
    TabSettings:CreateDivider()
    TabSettings:CreateSection("🎨 ESP Color (Line + Box)")

    TabSettings:CreateColorPicker({
        Name = "ESP Line & Box Color",
        Color = Color3.fromRGB(255, 255, 255),
        Flag = "ESPColorPicker",
        Callback = function(color)
            lineColor = color
            boxColor = color
        end,
    })

    -- ================== FULL BRIGHT ==================
    TabSettings:CreateDivider()
    TabSettings:CreateSection("🔆 Full Bright")

    TabSettings:CreateToggle({
        Name = "Full Bright",
        CurrentValue = false,
        Flag = "FullBright",
        Callback = function(state)
            toggleFullBright(state)
            if Rayfield then
                Rayfield:Notify({
                    Title = "Full Bright",
                    Content = state and "Full Bright diaktifkan" or "Full Bright dinonaktifkan",
                    Duration = 2,
                    Image = 4483362458
                })
            end
        end,
    })

    -- ================== NO FOG ==================
    TabSettings:CreateDivider()
    TabSettings:CreateSection("🌫️ No Fog")

    TabSettings:CreateToggle({
        Name = "No Fog",
        CurrentValue = false,
        Flag = "NoFog",
        Callback = function(state)
            toggleNoFog(state)
            if Rayfield then
                Rayfield:Notify({
                    Title = "No Fog",
                    Content = state and "No Fog diaktifkan" or "No Fog dinonaktifkan",
                    Duration = 2,
                    Image = 4483362458
                })
            end
        end,
    })

    -- ================== SERVER CONTROL ==================
    TabSettings:CreateDivider()
    TabSettings:CreateSection("🔄 Server Control")

    TabSettings:CreateButton({
        Name = "🔄 Rejoin Server",
        Callback = function()
            rejoinServer()
        end,
    })

    TabSettings:CreateButton({
        Name = "🚀 Server Hop",
        Callback = function()
            serverHop()
        end,
    })

    TabSettings:CreateDivider()
    TabSettings:CreateSection("⚠️ Informasi")
    TabSettings:CreateLabel("Bypass direkomendasikan diaktifkan")

    -- ================== TAB INFO ==================
    local TabInfo = Window:CreateTab("Info", "info")

    TabInfo:CreateSection("👤 Profil Akun")
    TabInfo:CreateLabel("Nama: " .. LocalPlayer.Name)
    TabInfo:CreateLabel("Display Name: " .. LocalPlayer.DisplayName)
    TabInfo:CreateLabel("User ID: " .. tostring(LocalPlayer.UserId))

    TabInfo:CreateDivider()

    TabInfo:CreateSection("Informasi Lisensi")
    TabInfo:CreateLabel("Executor: " .. userExecutor)
    local keyPaketStr = keyJenis ~= "" and keyJenis or "Tidak diketahui"
    TabInfo:CreateLabel("Paket: " .. keyPaketStr)

    local countdownElement = TabInfo:CreateLabel("Memuat waktu...")
    infoKeyCountdownLabel = countdownElement

    task.spawn(function()
        while true do
            task.wait(1)
            if keyValidGlobal and keyExpiryTime > 0 then
                local _, _, _, _, timeStr = getTimeRemaining(keyExpiryTime)
                local txt = os.time() > keyExpiryTime and "⛔ Key EXPIRED!" or ("⏳ Sisa: " .. timeStr)
                pcall(function()
                    if countdownElement and countdownElement.Set then
                        countdownElement:Set(txt)
                    end
                end)
            end
        end
    end)

    TabInfo:CreateDivider()
    TabInfo:CreateSection("Developer")
    TabInfo:CreateLabel("Developer: Putzzdev")
    TabInfo:CreateLabel("WhatsApp: 088976255131")

    TabInfo:CreateButton({
        Name = "Salin Link Get Key",
        Callback = function()
            if setclipboard then
                setclipboard(WEBSITE_URL)
                if Rayfield then
                    Rayfield:Notify({Title = "Berhasil", Content = "Link key berhasil disalin!", Duration = 3, Image = 4483362458})
                end
            else
                if Rayfield then
                    Rayfield:Notify({Title = "Info", Content = WEBSITE_URL, Duration = 5, Image = 4483362458})
                end
            end
        end,
    })

    TabInfo:CreateDivider()
    TabInfo:CreateParagraph({
        Title = "💜 Terima Kasih",
        Content = "Terima kasih telah menggunakan script Drip Client, jangan lupa support developer!",
    })
end

-- ================== KEY SYSTEM RAYFIELD ==================
local function startKeySystem()
    local TempRayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

    keyWindowRef = TempRayfield:CreateWindow({
        Name = "Drip Client - Verifikasi",
        LoadingTitle = "Drip Client",
        LoadingSubtitle = "Masukkan Key Anda",
        Theme = "Amethyst",
        DisableRayfieldPrompts = true,
        DisableBuildWarnings = true,
        ConfigurationSaving = { Enabled = false },
        KeySystem = false,
    })

    local KeyTab = keyWindowRef:CreateTab("Key System", "key-round")
    KeyTab:CreateSection("Autentikasi Key Server")

    local statusLabel = KeyTab:CreateLabel("Menunggu verifikasi lisensi...")
    local inputKeyValue = ""

    KeyTab:CreateInput({
        Name = "Masukkan Key Premium",
        PlaceholderText = "Input key server di sini...",
        RemoveTextAfterFocusLost = false,
        Flag = "KeyInput",
        Callback = function(text)
            inputKeyValue = text
        end,
    })

    KeyTab:CreateButton({
        Name = "AUTENTIKASI KEY",
        Callback = function()
            local inputKey = inputKeyValue
            inputKey = tostring(inputKey):gsub("%s+", "")

            if inputKey == "" then
                pcall(function() statusLabel:Set("❌ Key tidak boleh kosong!") end)
                TempRayfield:Notify({Title = "Error", Content = "Key tidak boleh kosong!", Duration = 3, Image = 4483362458})
                return
            end

            pcall(function() statusLabel:Set("🔄 Sedang verifikasi ke database server...") end)
            TempRayfield:Notify({Title = "Verifikasi", Content = "Mengecek key ke server...", Duration = 2, Image = 4483362458})

            local isValid, message = checkKeyExpiry(inputKey)

            if isValid then
                pcall(function() statusLabel:Set("✅ Key Valid! Memuat interface...") end)
                TempRayfield:Notify({Title = "Sukses!", Content = "Key valid! Interface sedang dimuat.", Duration = 3, Image = 4483362458})
                task.wait(1.5)
                pcall(function()
                    if keyWindowRef then
                        keyWindowRef:Destroy()
                        keyWindowRef = nil
                    end
                end)
                task.wait(0.3)
                loadMainScript()
            else
                pcall(function() statusLabel:Set("❌ " .. message) end)
                TempRayfield:Notify({Title = "Gagal", Content = message, Duration = 4, Image = 4483362458})
            end
        end,
    })

    KeyTab:CreateButton({
        Name = "Ambil Key (Salin Link)",
        Callback = function()
            if setclipboard then
                setclipboard(WEBSITE_URL)
                TempRayfield:Notify({Title = "Link Disalin", Content = "Buka browser dan paste link untuk mendapatkan key.", Duration = 4, Image = 4483362458})
            else
                TempRayfield:Notify({Title = "Link Key", Content = WEBSITE_URL, Duration = 6, Image = 4483362458})
            end
        end,
    })
end

-- ================== ESP PLAYER INIT ==================
for _, p in pairs(Players:GetPlayers()) do
    createESP(p)
    createSkeleton(p)
end

Players.PlayerAdded:Connect(function(p)
    createESP(p)
    createSkeleton(p)
    if chamsEnabled then
        task.wait(0.5)
        applyChams(p)
    end
end)

Players.PlayerRemoving:Connect(function(p)
    if ESPTable[p] then
        for _, d in pairs(ESPTable[p]) do
            pcall(function() d:Remove() end)
        end
        ESPTable[p] = nil
    end
    if SkeletonESP[p] then
        for _, ld in pairs(SkeletonESP[p]) do
            pcall(function() ld[1]:Remove() end)
        end
        SkeletonESP[p] = nil
    end
    removeChams(p)
end)

-- ================== START ==================
startKeySystem()