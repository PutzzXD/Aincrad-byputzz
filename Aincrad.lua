-- ================== DRIP CLIENT V9 - LINORIA UI ==================
-- Developer: Putzzdev | WA: 088976255131

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Camera           = workspace.CurrentCamera
local LocalPlayer      = Players.LocalPlayer
local HttpService      = game:GetService("HttpService")

-- ================== DETEKSI EXECUTOR ==================
local function detectExecutor()
    local executors = {
        {name="Delta",    check=function() return syn and syn.request and syn.crypt end},
        {name="Arceus X", check=function() return game:GetService("CoreGui"):FindFirstChild("Arceus X V2") end},
        {name="Hydrogen", check=function() return isfile and readfile and writefile and not syn end},
        {name="Fluxus",   check=function() return fluxus and fluxus.ismobile end},
        {name="Krnl",     check=function() return krnl and krnl.loadlibrary end},
        {name="Synapse X",check=function() return syn and syn.crypt and syn.request end},
    }
    for _, e in ipairs(executors) do
        local ok, res = pcall(e.check)
        if ok and res then return e.name end
    end
    local ok, id = pcall(function() if identifyexecutor then return identifyexecutor() end end)
    if ok and id and id ~= "" then return id end
    return "Unknown"
end
local userExecutor = detectExecutor()

-- ================== KEY SYSTEM ==================
local FIREBASE_URL = "https://key-database-701af-default-rtdb.asia-southeast1.firebasedatabase.app/keys.json"
local SAVE_FILE    = "drip_key_data.txt"
local activeKeys   = {}
local currentUserKey, keyExpiryTime, keyJenis = nil, 0, ""
local keyValidGlobal = false

local function loadKeyData()
    if isfile and isfile(SAVE_FILE) then
        local ok, c = pcall(readfile, SAVE_FILE)
        if ok and c and c ~= "" then
            local ok2, d = pcall(HttpService.JSONDecode, HttpService, c)
            if ok2 then activeKeys = d end
        end
    end
end

local function saveKeyData()
    if writefile then
        local ok, j = pcall(HttpService.JSONEncode, HttpService, activeKeys)
        if ok then writefile(SAVE_FILE, j) end
    end
end

local function getKeysFromFirebase()
    local ok, data = pcall(game.HttpGet, game, FIREBASE_URL)
    if ok and data then
        local ok2, j = pcall(HttpService.JSONDecode, HttpService, data)
        if ok2 and j then
            local arr = {}
            for _, v in pairs(j) do table.insert(arr, v) end
            return arr
        end
    end
end

local function getTimeRemaining(exp)
    local rem = exp - os.time()
    if rem <= 0 then return 0,0,0,0,"EXPIRED" end
    local d = math.floor(rem/86400)
    local h = math.floor((rem%86400)/3600)
    local m = math.floor((rem%3600)/60)
    local s = rem%60
    return d,h,m,s,string.format("%dd %02dh %02dm %02ds",d,h,m,s)
end

local function checkKeyExpiry(inputKey)
    loadKeyData()
    local keys = getKeysFromFirebase()
    if not keys then return false,"Gagal mengambil data server" end
    local found, exDays, jenis = nil, nil, nil
    for _, k in ipairs(keys) do
        if k.key == inputKey then
            found = k.key; jenis = k.jenis or "1 HARI"
            local t = {["1 JAM"]=1/24,["1 HARI"]=1,["2 HARI"]=2,["3 HARI"]=3,["7 HARI"]=7,["30 HARI"]=30,["PERMANEN"]=9999999}
            exDays = t[jenis] or 1; break
        end
    end
    if not found then return false,"KEY TIDAK TERDAFTAR!" end
    local now = os.time()
    local expTime
    if activeKeys[inputKey] and activeKeys[inputKey].expiryTime then
        expTime = activeKeys[inputKey].expiryTime
        if now > expTime then return false,"KEY SUDAH EXPIRED!" end
    else
        expTime = now + (exDays*86400)
        activeKeys[inputKey] = {firstUsed=now,key=inputKey,expiryTime=expTime,jenis=jenis}
        saveKeyData()
    end
    keyExpiryTime=expTime; keyJenis=jenis; currentUserKey=inputKey; keyValidGlobal=true
    local _,_,_,_,ts = getTimeRemaining(expTime)
    return true,"VALID! Sisa: "..ts
end

-- ================== VARIABEL FITUR ==================
local espEnabled=false; local lineEnabled=false; local lineColor=Color3.fromRGB(0,0,0)
local skeletonEnabled=false; local ESPTable={}; local SkeletonESP={}
local playerCounterEnabled=false; local enemyCountText=nil
local flyEnabled=false; local flyConnection=nil; local flySpeed=100; local flyAutoForward=true
local ctrl={f=0,b=0,l=0,r=0}; local speed=0; local flyTorso=nil
local noclipEnabled=false; local noclipConnection=nil
local speedEnabled=false; local normalSpeed=16; local fastSpeed=60
local infinityJumpEnabled=false
local antiDamageEnabled=false; local antiDamageHeartbeat=nil
local spinEnabled=false; local spinSpeed=50; local spinConnection=nil; local spinDirection=1
local invisibleEnabled=false; local invisibleConnection=nil
local invisibleParts={}; local invisibleRootPart=nil; local invisibleHumanoid=nil
local themeColor=Color3.fromRGB(156,39,176)
local MAX_ESP_DISTANCE=200000

-- ================== FUNGSI FITUR ==================
local function startFlyMode()
    local char = LocalPlayer.Character; if not char then return end
    flyTorso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart"); if not flyTorso then return end
    ctrl={f=0,b=0,l=0,r=0}; speed=0
    local hum = char:FindFirstChildOfClass("Humanoid"); if hum then hum.PlatformStand=true end
    local bg=Instance.new("BodyGyro",flyTorso); bg.Name="FlyBG"; bg.P=9e4; bg.MaxTorque=Vector3.new(9e9,9e9,9e9)
    local bv=Instance.new("BodyVelocity",flyTorso); bv.Name="FlyBV"; bv.MaxForce=Vector3.new(9e9,9e9,9e9)
    flyConnection = RunService.RenderStepped:Connect(function()
        if not flyEnabled or not LocalPlayer.Character then return end
        ctrl.f=UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0
        ctrl.b=UserInputService:IsKeyDown(Enum.KeyCode.S) and -1 or 0
        ctrl.l=UserInputService:IsKeyDown(Enum.KeyCode.A) and -1 or 0
        ctrl.r=UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0
        local fwd=(flyAutoForward and ctrl.f==0 and ctrl.b==0) and 1 or (ctrl.f+ctrl.b)
        if fwd~=0 or ctrl.l+ctrl.r~=0 then
            speed=math.min(speed+1.5,flySpeed)
            local c=Camera.CFrame
            bv.Velocity=((c.LookVector*fwd)+(c.RightVector*(ctrl.l+ctrl.r))).Unit*speed
        else speed=math.max(speed-2,0); bv.Velocity=Vector3.new(0,0,0) end
        bg.CFrame=Camera.CFrame
    end)
end

local function stopFlyMode()
    flyEnabled=false
    if flyConnection then flyConnection:Disconnect(); flyConnection=nil end
    local char=LocalPlayer.Character; if not char then return end
    local hum=char:FindFirstChildOfClass("Humanoid"); if hum then hum.PlatformStand=false end
    local t=char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart"); if not t then return end
    if t:FindFirstChild("FlyBV") then t.FlyBV:Destroy() end
    if t:FindFirstChild("FlyBG") then t.FlyBG:Destroy() end
end

local function startNoclip()
    if noclipConnection then noclipConnection:Disconnect() end
    noclipConnection=RunService.Stepped:Connect(function()
        if noclipEnabled and LocalPlayer.Character then
            for _,p in pairs(LocalPlayer.Character:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide=false end
            end
        end
    end)
end
local function stopNoclip() if noclipConnection then noclipConnection:Disconnect(); noclipConnection=nil end end

local function toggleSpin(state)
    spinEnabled=state
    if spinConnection then spinConnection:Disconnect(); spinConnection=nil end
    if state then
        spinConnection=RunService.Heartbeat:Connect(function()
            if spinEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame*=CFrame.Angles(0,math.rad(spinSpeed*spinDirection),0)
            end
        end)
    end
end

local function toggleInvisible(state)
    invisibleEnabled=state
    if invisibleConnection then invisibleConnection:Disconnect(); invisibleConnection=nil end
    if state and LocalPlayer.Character then
        invisibleParts={}
        invisibleRootPart=LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        invisibleHumanoid=LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        for _,v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") and v.Transparency==0 then
                table.insert(invisibleParts,{part=v,origTrans=0}); v.Transparency=0.5
            end
        end
        invisibleConnection=RunService.Heartbeat:Connect(function()
            if invisibleEnabled and invisibleRootPart and invisibleHumanoid then
                local cf=invisibleRootPart.CFrame; local off=invisibleHumanoid.CameraOffset
                invisibleRootPart.CFrame=cf*CFrame.new(0,-500000,0)
                invisibleHumanoid.CameraOffset=Vector3.new(0,0,0)
                RunService.RenderStepped:Wait()
                invisibleRootPart.CFrame=cf; invisibleHumanoid.CameraOffset=off
            end
        end)
    else
        if LocalPlayer.Character then
            for _,d in pairs(invisibleParts) do
                pcall(function() if d.part and d.part.Parent then d.part.Transparency=d.origTrans end end)
            end
            for _,v in pairs(LocalPlayer.Character:GetDescendants()) do
                if v:IsA("BasePart") and v.Transparency==0.5 then v.Transparency=0 end
            end
        end
        invisibleParts={}; invisibleRootPart=nil; invisibleHumanoid=nil
    end
end

local function setupAntiDamage()
    if antiDamageHeartbeat then pcall(function() antiDamageHeartbeat:Disconnect() end); antiDamageHeartbeat=nil end
    local function makeInvincible()
        local char=LocalPlayer.Character; if not char then return end
        local hum=char:FindFirstChildOfClass("Humanoid"); if not hum then return end
        hum.Health=hum.MaxHealth
        pcall(function() hum:SetAttribute("MaxHealth",math.huge) end)
    end
    makeInvincible()
    antiDamageHeartbeat=RunService.Heartbeat:Connect(function()
        if antiDamageEnabled then makeInvincible() end
    end)
end

-- ================== ESP SETUP ==================
local function createESPforPlayer(player)
    if player==LocalPlayer then return end
    local box=Drawing.new("Square"); box.Visible=false; box.Color=Color3.fromRGB(0,0,0)
    box.Thickness=1.5; box.Filled=false
    local nameTag=Drawing.new("Text"); nameTag.Visible=false; nameTag.Size=13
    nameTag.Color=Color3.fromRGB(255,255,255); nameTag.Outline=true; nameTag.Center=true
    local healthBar=Drawing.new("Square"); healthBar.Visible=false; healthBar.Color=Color3.fromRGB(0,255,0)
    healthBar.Thickness=2; healthBar.Filled=false
    local line=Drawing.new("Line"); line.Visible=false; line.Thickness=1.5
    line.Color=Color3.fromRGB(0,0,0)
    ESPTable[player]={box=box,nameTag=nameTag,healthBar=healthBar,line=line}
    local skeletonBones={{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},
        {"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},
        {"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"LowerTorso","LeftUpperLeg"},
        {"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},
        {"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}}
    SkeletonESP[player]={}
    for _,b in ipairs(skeletonBones) do
        local l=Drawing.new("Line"); l.Color=Color3.fromRGB(0,255,0); l.Thickness=1; l.Visible=false
        table.insert(SkeletonESP[player],{l,b[1],b[2]})
    end
end

local function removeESPforPlayer(player)
    if ESPTable[player] then
        for _,d in pairs(ESPTable[player]) do d:Remove() end
        ESPTable[player]=nil
    end
    if SkeletonESP[player] then
        for _,ld in pairs(SkeletonESP[player]) do ld[1]:Remove() end
        SkeletonESP[player]=nil
    end
end

local function createPlayerCounter()
    if not enemyCountText then
        enemyCountText=Drawing.new("Text"); enemyCountText.Size=18
        enemyCountText.Color=Color3.fromRGB(255,255,255); enemyCountText.Outline=true
        enemyCountText.Center=true; enemyCountText.Visible=false
    end
end
createPlayerCounter()

for _,p in pairs(Players:GetPlayers()) do createESPforPlayer(p) end
Players.PlayerAdded:Connect(createESPforPlayer)
Players.PlayerRemoving:Connect(removeESPforPlayer)

-- Infinity jump
UserInputService.JumpRequest:Connect(function()
    if infinityJumpEnabled and LocalPlayer.Character then
        local hum=LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ================== RENDER LOOP ESP ==================
local screenCount=0
RunService.RenderStepped:Connect(function()
    local myChar=LocalPlayer.Character
    local myHRP=myChar and myChar:FindFirstChild("HumanoidRootPart")
    local myPos=myHRP and myHRP.Position
    screenCount=0
    for player,esp in pairs(ESPTable) do
        local char=player.Character
        local hrp=char and char:FindFirstChild("HumanoidRootPart")
        local head=char and char:FindFirstChild("Head")
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        if char and hrp and head and myPos then
            local dist=(myPos-hrp.Position).Magnitude
            if dist<=MAX_ESP_DISTANCE then
                local sp,onScreen=Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    screenCount=screenCount+1
                    if espEnabled then
                        local topSP=Camera:WorldToViewportPoint(head.Position+Vector3.new(0,0.7,0))
                        local botSP=Camera:WorldToViewportPoint(hrp.Position-Vector3.new(0,3,0))
                        local h=math.abs(topSP.Y-botSP.Y); local w=h/2
                        esp.box.Size=Vector2.new(w,h); esp.box.Position=Vector2.new(sp.X-w/2,topSP.Y)
                        esp.box.Visible=true
                        esp.nameTag.Position=Vector2.new(sp.X,topSP.Y-16)
                        esp.nameTag.Text=player.Name.." ["..math.floor(dist).."m]"; esp.nameTag.Visible=true
                    else esp.box.Visible=false; esp.nameTag.Visible=false end
                    if lineEnabled then
                        esp.line.From=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y)
                        esp.line.To=Vector2.new(sp.X,sp.Y); esp.line.Color=lineColor; esp.line.Visible=true
                    else esp.line.Visible=false end
                else
                    esp.box.Visible=false; esp.nameTag.Visible=false; esp.line.Visible=false
                end
            else esp.box.Visible=false; esp.nameTag.Visible=false; esp.line.Visible=false end
        else esp.box.Visible=false; esp.nameTag.Visible=false; esp.line.Visible=false end
    end
    if skeletonEnabled then
        for player,lines in pairs(SkeletonESP) do
            local char=player.Character
            if char and char:FindFirstChild("HumanoidRootPart") and myPos then
                for _,ld in pairs(lines) do
                    local p1=char:FindFirstChild(ld[2]); local p2=char:FindFirstChild(ld[3])
                    if p1 and p2 then
                        local s1,v1=Camera:WorldToViewportPoint(p1.Position)
                        local s2,v2=Camera:WorldToViewportPoint(p2.Position)
                        if v1 and v2 then ld[1].From=Vector2.new(s1.X,s1.Y); ld[1].To=Vector2.new(s2.X,s2.Y); ld[1].Visible=true
                        else ld[1].Visible=false end
                    else ld[1].Visible=false end
                end
            else for _,ld in pairs(lines) do ld[1].Visible=false end end
        end
    else for _,lines in pairs(SkeletonESP) do for _,ld in pairs(lines) do ld[1].Visible=false end end end
    if playerCounterEnabled and enemyCountText then
        enemyCountText.Text="PLAYERS: "..screenCount
        enemyCountText.Position=Vector2.new(Camera.ViewportSize.X/2,50); enemyCountText.Visible=true
    elseif enemyCountText then enemyCountText.Visible=false end
end)

-- ================== KEY SYSTEM GUI ==================
task.spawn(function()
    local KeyGui=Instance.new("ScreenGui",game.CoreGui)
    KeyGui.Name="DripKeySystem"; KeyGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling

    local KeyFrame=Instance.new("Frame",KeyGui)
    KeyFrame.Size=UDim2.new(0,340,0,300); KeyFrame.Position=UDim2.new(0.5,-170,0.5,-150)
    KeyFrame.BackgroundColor3=Color3.fromRGB(18,18,24); KeyFrame.Active=true; KeyFrame.Draggable=true
    Instance.new("UICorner",KeyFrame).CornerRadius=UDim.new(0,14)
    local ks=Instance.new("UIStroke",KeyFrame); ks.Color=themeColor; ks.Thickness=1.8

    local kTitle=Instance.new("TextLabel",KeyFrame)
    kTitle.Size=UDim2.new(1,0,0,40); kTitle.Position=UDim2.new(0,0,0,14)
    kTitle.BackgroundTransparency=1; kTitle.Text="DRIP CLIENT VERIFIKASI"
    kTitle.TextColor3=Color3.new(1,1,1); kTitle.Font=Enum.Font.GothamBlack; kTitle.TextSize=15

    local devSub=Instance.new("TextLabel",KeyFrame)
    devSub.Size=UDim2.new(1,0,0,20); devSub.Position=UDim2.new(0,0,0,50)
    devSub.BackgroundTransparency=1; devSub.Text="✦ Putzzdev"
    devSub.TextColor3=Color3.fromRGB(255,160,60); devSub.Font=Enum.Font.GothamBold; devSub.TextSize=12

    local keyBox=Instance.new("TextBox",KeyFrame)
    keyBox.Size=UDim2.new(0.85,0,0,38); keyBox.Position=UDim2.new(0.075,0,0,90)
    keyBox.BackgroundColor3=Color3.fromRGB(28,28,38); keyBox.TextColor3=Color3.new(1,1,1)
    keyBox.PlaceholderText="Input key server di sini..."
    keyBox.Font=Enum.Font.Gotham; keyBox.TextSize=12; keyBox.ClearTextOnFocus=false
    Instance.new("UICorner",keyBox).CornerRadius=UDim.new(0,8)

    local getKeyBtn=Instance.new("TextButton",KeyFrame)
    getKeyBtn.Size=UDim2.new(0.85,0,0,34); getKeyBtn.Position=UDim2.new(0.075,0,0,140)
    getKeyBtn.BackgroundColor3=Color3.fromRGB(30,30,45); getKeyBtn.TextColor3=Color3.fromRGB(0,200,255)
    getKeyBtn.Font=Enum.Font.GothamBold; getKeyBtn.TextSize=12; getKeyBtn.Text="🌐 Dapatkan Key"
    Instance.new("UICorner",getKeyBtn).CornerRadius=UDim.new(0,8)
    Instance.new("UIStroke",getKeyBtn).Color=Color3.fromRGB(0,180,255)
    getKeyBtn.MouseButton1Click:Connect(function()
        setclipboard("https://drip-client-get-key.vercel.app/")
    end)

    local submitBtn=Instance.new("TextButton",KeyFrame)
    submitBtn.Size=UDim2.new(0.85,0,0,38); submitBtn.Position=UDim2.new(0.075,0,0,186)
    submitBtn.BackgroundColor3=themeColor; submitBtn.TextColor3=Color3.new(1,1,1)
    submitBtn.Font=Enum.Font.GothamBold; submitBtn.TextSize=13; submitBtn.Text="VERIFIKASI KEY"
    Instance.new("UICorner",submitBtn).CornerRadius=UDim.new(0,8)

    local statusLabel=Instance.new("TextLabel",KeyFrame)
    statusLabel.Size=UDim2.new(0.9,0,0,22); statusLabel.Position=UDim2.new(0.05,0,0,232)
    statusLabel.BackgroundTransparency=1; statusLabel.Text=""
    statusLabel.TextColor3=Color3.fromRGB(255,100,100); statusLabel.Font=Enum.Font.GothamBold; statusLabel.TextSize=11

    local progBg=Instance.new("Frame",KeyFrame)
    progBg.Size=UDim2.new(0.85,0,0,6); progBg.Position=UDim2.new(0.075,0,0,258)
    progBg.BackgroundColor3=Color3.fromRGB(35,35,45); progBg.Visible=false; progBg.BorderSizePixel=0
    Instance.new("UICorner",progBg).CornerRadius=UDim.new(0,3)
    local progBar=Instance.new("Frame",progBg)
    progBar.Size=UDim2.new(0,0,1,0); progBar.BackgroundColor3=themeColor; progBar.BorderSizePixel=0
    Instance.new("UICorner",progBar).CornerRadius=UDim.new(0,3)

    submitBtn.MouseButton1Click:Connect(function()
        local inputKey=keyBox.Text:gsub("%s","")
        if inputKey=="" then statusLabel.Text="⚠ Key tidak boleh kosong!"; statusLabel.TextColor3=Color3.fromRGB(255,80,80); return end
        statusLabel.Text="⏳ Memverifikasi..."; statusLabel.TextColor3=Color3.fromRGB(200,200,200)
        task.spawn(function()
            local ok,msg=checkKeyExpiry(inputKey)
            if ok then
                statusLabel.Text="✅ "..msg; statusLabel.TextColor3=Color3.fromRGB(0,255,120)
                submitBtn.Text="✅ TERVERIFIKASI!"; submitBtn.BackgroundColor3=Color3.fromRGB(0,160,80)
                keyBox.Visible=false; getKeyBtn.Visible=false
                progBg.Visible=true
                local function setP(p,t) TweenService:Create(progBar,TweenInfo.new(0.35,Enum.EasingStyle.Quart),{Size=UDim2.new(p,0,1,0)}):Play(); statusLabel.Text=t end
                setP(0.3,"⚙ Memuat modul..."); task.wait(0.5)
                setP(0.65,"🔒 Mengautentikasi..."); task.wait(0.5)
                setP(1.0,"✅ Siap!"); task.wait(0.4)
                TweenService:Create(KeyFrame,TweenInfo.new(0.25),{BackgroundTransparency=1}):Play()
                for _,v in pairs(KeyFrame:GetDescendants()) do
                    if v:IsA("TextLabel") or v:IsA("TextButton") or v:IsA("TextBox") then
                        pcall(function() TweenService:Create(v,TweenInfo.new(0.25),{TextTransparency=1,BackgroundTransparency=1}):Play() end)
                    elseif v:IsA("Frame") then
                        pcall(function() TweenService:Create(v,TweenInfo.new(0.25),{BackgroundTransparency=1}):Play() end)
                    end
                end
                task.wait(0.3); KeyGui:Destroy()
                loadMainScript()
            else
                statusLabel.Text="❌ "..msg; statusLabel.TextColor3=Color3.fromRGB(255,60,60)
            end
        end)
    end)
end)

-- ================== MAIN SCRIPT (LINORIA UI) ==================
function loadMainScript()
    local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
    local Window = Library:CreateWindow("Drip Client | Putzzdev", {
        Resizable = true,
        Size = Vector2.new(450, 520),
        Center = true,
        ShowCustomCursor = true,
    })

    -- ======= TAB MAIN =======
    local MainTab = Window:AddTab("Main")
    
    -- Movement Section
    local MovementSection = MainTab:AddLeftGroupbox("Movement")
    
    MovementSection:AddToggle("FlyMode", {
        Text = "Fly Mode",
        Description = "Terbang bebas di sekitar peta",
        Default = false,
        Callback = function(s)
            flyEnabled = s
            if s then startFlyMode() else stopFlyMode() end
        end
    })
    
    MovementSection:AddToggle("SpeedBoost", {
        Text = "Speed Boost",
        Description = "Kecepatan jalan x4",
        Default = false,
        Callback = function(s)
            speedEnabled = s
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = s and fastSpeed or normalSpeed end
        end
    })
    
    MovementSection:AddSlider("FlySpeed", {
        Text = "Fly Speed",
        Description = "Atur kecepatan terbang",
        Default = 100,
        Min = 20,
        Max = 200,
        Rounding = 1,
        Callback = function(v)
            flySpeed = v
        end
    })
    
    MovementSection:AddToggle("NoClip", {
        Text = "NoClip",
        Description = "Tembus dinding",
        Default = false,
        Callback = function(s)
            noclipEnabled = s
            if s then startNoclip() else stopNoclip() end
        end
    })
    
    MovementSection:AddToggle("InfinityJump", {
        Text = "Infinity Jump",
        Description = "Lompat tanpa batas",
        Default = false,
        Callback = function(s)
            infinityJumpEnabled = s
        end
    })
    
    -- Combat & Misc Section
    local CombatSection = MainTab:AddRightGroupbox("Combat & Misc")
    
    CombatSection:AddToggle("GodMode", {
        Text = "God Mode",
        Description = "Tidak bisa mati",
        Default = false,
        Callback = function(s)
            antiDamageEnabled = s
            if s then setupAntiDamage()
            else if antiDamageHeartbeat then antiDamageHeartbeat:Disconnect(); antiDamageHeartbeat = nil end end
        end
    })
    
    CombatSection:AddToggle("SpinMode", {
        Text = "Spin Muter",
        Description = "Karakter berputar terus",
        Default = false,
        Callback = function(s)
            toggleSpin(s)
        end
    })
    
    CombatSection:AddSlider("SpinSpeed", {
        Text = "Spin Speed",
        Description = "Atur kecepatan spin",
        Default = 50,
        Min = 10,
        Max = 200,
        Rounding = 1,
        Callback = function(v)
            spinSpeed = v
        end
    })
    
    CombatSection:AddToggle("InvisibleMode", {
        Text = "Invisible Mode",
        Description = "Membuat karakter tidak terlihat (eksperimental)",
        Default = false,
        Callback = function(s)
            toggleInvisible(s)
        end
    })

    -- ======= TAB ESP =======
    local ESPTab = Window:AddTab("ESP System")
    
    local ESPLeftSection = ESPTab:AddLeftGroupbox("ESP Options")
    
    ESPLeftSection:AddToggle("ESPBox", {
        Text = "ESP Box",
        Description = "Menampilkan kotak di sekitar player",
        Default = false,
        Callback = function(s)
            espEnabled = s
        end
    })
    
    ESPLeftSection:AddToggle("ESPLine", {
        Text = "ESP Line",
        Description = "Garis dari bawah layar ke player",
        Default = false,
        Callback = function(s)
            lineEnabled = s
        end
    })
    
    ESPLeftSection:AddToggle("ESPSkeleton", {
        Text = "ESP Skeleton",
        Description = "Menampilkan rangka tulang player",
        Default = false,
        Callback = function(s)
            skeletonEnabled = s
        end
    })
    
    ESPLeftSection:AddToggle("PlayerCounter", {
        Text = "Player Counter",
        Description = "Menghitung player di layar",
        Default = false,
        Callback = function(s)
            playerCounterEnabled = s
        end
    })
    
    -- ESP Color Section
    local ESPRightSection = ESPTab:AddRightGroupbox("ESP Colors")
    
    ESPRightSection:AddLabel("Line Color")
    ESPRightSection:AddColorPicker("LineColor", {
        Text = "Warna Garis ESP",
        Default = Color3.fromRGB(255, 0, 0),
        Callback = function(c)
            lineColor = c
        end
    })

    -- ======= TAB UTILITY =======
    local UtilTab = Window:AddTab("Utility")
    
    -- Teleport Section
    local TeleportSection = UtilTab:AddLeftGroupbox("Teleport")
    
    TeleportSection:AddButton("Teleport ke Player", function()
        local pList = {}
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then table.insert(pList, p) end
        end
        if #pList == 0 then
            Library:Notification("Teleport", "Tidak ada player lain di server!", 3)
            return
        end
        Library:Notification("Teleport", "Gunakan dropdown di bawah untuk teleport", 3)
    end)
    
    -- Dropdown Teleport
    local function getPlayerList()
        local list = {}
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                table.insert(list, p.Name)
            end
        end
        return list
    end
    
    TeleportSection:AddDropdown("TeleportDropdown", {
        Text = "Pilih Player",
        Description = "Pilih player tujuan teleport",
        Values = getPlayerList(),
        Default = 1,
        Callback = function(v)
            local target = Players:FindFirstChild(v)
            if target and target.Character then
                local mc = LocalPlayer.Character
                local tc = target.Character
                if mc and tc then
                    local mh = mc:FindFirstChild("HumanoidRootPart")
                    local th = tc:FindFirstChild("HumanoidRootPart")
                    if mh and th then
                        mh.CFrame = th.CFrame + Vector3.new(0, 3, 0)
                        Library:Notification("Teleport", "Berhasil TP ke " .. v, 2)
                    end
                end
            end
        end
    })
    
    TeleportSection:AddButton("Refresh Player List", function()
        TeleportSection:RemoveDropdown("TeleportDropdown")
        task.wait(0.1)
        TeleportSection:AddDropdown("TeleportDropdown", {
            Text = "Pilih Player",
            Description = "Pilih player tujuan teleport",
            Values = getPlayerList(),
            Default = 1,
            Callback = function(v)
                local target = Players:FindFirstChild(v)
                if target and target.Character then
                    local mc = LocalPlayer.Character
                    local tc = target.Character
                    if mc and tc then
                        local mh = mc:FindFirstChild("HumanoidRootPart")
                        local th = tc:FindFirstChild("HumanoidRootPart")
                        if mh and th then
                            mh.CFrame = th.CFrame + Vector3.new(0, 3, 0)
                            Library:Notification("Teleport", "Berhasil TP ke " .. v, 2)
                        end
                    end
                end
            end
        })
        Library:Notification("Refresh", "List player diperbarui!", 2)
    end)
    
    -- Freeze Section
    local FreezeSection = UtilTab:AddRightGroupbox("Freeze")
    
    FreezeSection:AddToggle("FreezeAll", {
        Text = "Freeze All Player (Visual)",
        Description = "Bekukan semua player di layar kamu",
        Default = false,
        Callback = function(s)
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    for _, part in pairs(p.Character:GetDescendants()) do
                        if part:IsA("BasePart") then pcall(function() part.Anchored = s end) end
                    end
                end
            end
            Library:Notification("Freeze", s and "Semua player dibekukan!" or "Freeze dinonaktifkan", 2)
        end
    })
    
    -- Freeze Self Section
    local freezeSelfEnabled = false
    
    FreezeSection:AddToggle("FreezeSelf", {
        Text = "Freeze Diri",
        Description = "Bekukan karakter sendiri",
        Default = false,
        Callback = function(s)
            freezeSelfEnabled = s
            local mc = LocalPlayer.Character
            if mc then
                local hrp = mc:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.Anchored = s end
            end
        end
    })
    
    LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        if freezeSelfEnabled then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.Anchored = true end
        end
    end)

    -- ======= TAB INFO =======
    local InfoTab = Window:AddTab("Info")
    
    local InfoLeftSection = InfoTab:AddLeftGroupbox("Informasi Lisensi")
    
    InfoLeftSection:AddLabel("Developer: Putzzdev")
    InfoLeftSection:AddLabel("WhatsApp: 088976255131")
    InfoLeftSection:AddLabel("Executor: " .. userExecutor)
    InfoLeftSection:AddLabel("Jenis Paket: " .. keyJenis)
    
    local timeLabel = InfoLeftSection:AddLabel("Sisa Durasi: Menghitung...")
    
    InfoLeftSection:AddButton("Cek Sisa Waktu Key", function()
        if keyValidGlobal and keyExpiryTime > 0 then
            local _,_,_,_,ts = getTimeRemaining(keyExpiryTime)
            Library:Notification("Sisa Durasi", ts, 5)
        else
            Library:Notification("Info", "Key belum terverifikasi", 3)
        end
    end)
    
    InfoLeftSection:AddButton("Copy WA Developer", function()
        pcall(function() setclipboard("088976255131") end)
        Library:Notification("Copied!", "Nomor WA berhasil disalin", 2)
    end)
    
    -- Info Right Section
    local InfoRightSection = InfoTab:AddRightGroupbox("Status")
    
    InfoRightSection:AddLabel("✅ Key Active: " .. tostring(keyValidGlobal))
    if keyJenis and keyJenis ~= "" then
        InfoRightSection:AddLabel("📦 Paket: " .. keyJenis)
    end
    
    -- Countdown updater
    task.spawn(function()
        while true do
            task.wait(1)
            if keyValidGlobal and keyExpiryTime > 0 then
                local _,_,_,_,ts = getTimeRemaining(keyExpiryTime)
                pcall(function() timeLabel:SetText("Sisa Durasi: " .. ts) end)
            end
        end
    end)
    
    -- Reconnect handlers
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        if noclipEnabled then startNoclip() end
        if flyEnabled then startFlyMode() end
        if freezeSelfEnabled then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.Anchored = true end
        end
        if speedEnabled then
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = fastSpeed end
        end
    end)
end