-- ================== DRIP CLIENT V8.2 PREMIUM - CUSTOM UI ==================

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

local mainWindowLoaded = false


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

-- ================== CUSTOM UI (buatan sendiri, tanpa library eksternal) ==================
local UI = {}
do
    local T = {
        Bg      = Color3.fromRGB(15, 13, 25),
        Panel   = Color3.fromRGB(23, 20, 38),
        Item    = Color3.fromRGB(32, 28, 52),
        Accent  = Color3.fromRGB(150, 90, 255),
        Accent2 = Color3.fromRGB(90, 150, 255),
        Text    = Color3.fromRGB(240, 238, 255),
        Sub     = Color3.fromRGB(150, 144, 185),
        Off     = Color3.fromRGB(56, 52, 84),
        Stroke  = Color3.fromRGB(66, 58, 105),
        White   = Color3.new(1, 1, 1),
    }
    local FOLDER = "PutzzdevXIT"
    UI.ConfigPath = FOLDER .. "/PutzzConfig.json"

    -- ---------- helper ----------
    local function new(class, props)
        local o = Instance.new(class)
        local parent = nil
        for k, v in pairs(props or {}) do
            if k == "Parent" then parent = v else o[k] = v end
        end
        if parent then o.Parent = parent end
        return o
    end
    local function tween(obj, t, props)
        TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
    end
    local function round(obj, r)
        new("UICorner", {CornerRadius = UDim.new(0, r), Parent = obj})
    end
    local function stroke(obj, col, th, tr)
        return new("UIStroke", {
            Color = col or T.Stroke, Thickness = th or 1, Transparency = tr or 0.3,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = obj,
        })
    end
    local function padding(obj, l, t, r, b)
        new("UIPadding", {
            PaddingLeft = UDim.new(0, l), PaddingTop = UDim.new(0, t),
            PaddingRight = UDim.new(0, r), PaddingBottom = UDim.new(0, b), Parent = obj,
        })
    end
    local function gradient(obj, c0, c1, rot)
        new("UIGradient", {Color = ColorSequence.new(c0, c1), Rotation = rot or 0, Parent = obj})
    end
    local function isPress(i)
        return i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1
    end
    local function fire(cb, ...)
        if cb then
            local ok, err = pcall(cb, ...)
            if not ok then warn("[UI] " .. tostring(err)) end
        end
    end

    local function makeDraggable(handle, target, onClick)
        local dragging, moved, dragStart, startPos, dragInput = false, false, nil, nil, nil
        handle.InputBegan:Connect(function(input)
            if isPress(input) then
                dragging, moved = true, false
                dragStart, startPos, dragInput = input.Position, target.Position, input
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        if onClick and not moved then onClick() end
                    end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input == dragInput or input.UserInputType == Enum.UserInputType.MouseMovement) then
                local d = input.Position - dragStart
                if d.Magnitude > 6 then moved = true end
                if moved then
                    target.Position = UDim2.new(
                        startPos.X.Scale, startPos.X.Offset + d.X,
                        startPos.Y.Scale, startPos.Y.Offset + d.Y
                    )
                end
            end
        end)
    end

    local function guiParent()
        local ok, h = pcall(function() return gethui and gethui() end)
        if ok and typeof(h) == "Instance" then return h end
        local ok2, cg = pcall(function() return game:GetService("CoreGui") end)
        if ok2 and cg then
            local probe = Instance.new("ScreenGui")
            local ok3 = pcall(function() probe.Parent = cg end)
            probe:Destroy()
            if ok3 then return cg end
        end
        return LocalPlayer:WaitForChild("PlayerGui")
    end

    -- ---------- config (simpan otomatis) ----------
    local Flags, loading, savePending = {}, false, false

    local function encodeVal(v)
        if typeof(v) == "Color3" then
            return {r = math.floor(v.R * 255 + 0.5), g = math.floor(v.G * 255 + 0.5), b = math.floor(v.B * 255 + 0.5)}
        end
        return v
    end
    local function saveNow()
        pcall(function()
            if not writefile then return end
            if makefolder and isfolder and not isfolder(FOLDER) then makefolder(FOLDER) end
            local data = {}
            for k, f in pairs(Flags) do data[k] = encodeVal(f.Get()) end
            writefile(UI.ConfigPath, HttpService:JSONEncode(data))
        end)
    end
    local function queueSave()
        if loading or savePending then return end
        savePending = true
        task.delay(0.6, function()
            savePending = false
            saveNow()
        end)
    end

    function UI:LoadConfiguration()
        local ok, raw = pcall(function()
            if isfile and readfile and isfile(UI.ConfigPath) then return readfile(UI.ConfigPath) end
        end)
        if not ok or not raw then return end
        local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
        if not ok2 or type(data) ~= "table" then return end
        loading = true
        for k, v in pairs(data) do
            local f = Flags[k]
            if f then
                if type(v) == "table" and v.r then v = Color3.fromRGB(v.r, v.g, v.b) end
                pcall(f.Set, v)
            end
        end
        loading = false
    end

    -- ---------- state GUI ----------
    local gui, toastHolder = nil, nil

    function UI:Destroy()
        if gui then gui:Destroy() gui = nil toastHolder = nil end
    end

    -- ---------- notifikasi ----------
    function UI:Notify(o)
        if not toastHolder then return end
        o = o or {}
        local toast = new("CanvasGroup", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = T.Panel, BorderSizePixel = 0, GroupTransparency = 1, Parent = toastHolder,
        })
        round(toast, 8)
        stroke(toast, T.Accent, 1, 0.2)
        padding(toast, 10, 8, 10, 8)
        new("UIListLayout", {Padding = UDim.new(0, 2), Parent = toast})
        new("TextLabel", {
            Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 13,
            TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left, Text = tostring(o.Title or ""), Parent = toast,
        })
        new("TextLabel", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
            Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = T.Sub, TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left, Text = tostring(o.Content or ""), Parent = toast,
        })
        tween(toast, 0.2, {GroupTransparency = 0})
        task.delay(o.Duration or 3, function()
            if toast and toast.Parent then
                tween(toast, 0.25, {GroupTransparency = 1})
                task.wait(0.3)
                toast:Destroy()
            end
        end)
    end

    -- ---------- window ----------
    function UI:CreateWindow(cfg)
        cfg = cfg or {}
        local parent = guiParent()
        local old = parent:FindFirstChild("PutzzdevXIT_UI")
        if old then old:Destroy() end

        gui = new("ScreenGui", {
            Name = "PutzzdevXIT_UI", ResetOnSpawn = false, DisplayOrder = 999,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        })
        pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
        gui.Parent = parent

        local vp = Camera.ViewportSize
        local W = math.clamp(math.floor(vp.X * 0.86), 300, 540)
        local H = math.clamp(math.floor(vp.Y * 0.80), 220, 330)

        local main = new("Frame", {
            Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, W, 0, H), BackgroundColor3 = T.Bg, BorderSizePixel = 0, ClipsDescendants = true, Parent = gui,
        })
        round(main, 12)
        stroke(main, T.Stroke, 1.5, 0.1)
        local scale = new("UIScale", {Scale = 1, Parent = main})

        -- header
        local header = new("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = T.Panel, BorderSizePixel = 0, Parent = main})
        round(header, 12)
        new("Frame", {Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 1, -12), BackgroundColor3 = T.Panel, BorderSizePixel = 0, Parent = header})
        local accentLine = new("Frame", {Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 0, 40), BackgroundColor3 = T.White, BorderSizePixel = 0, Parent = main})
        gradient(accentLine, T.Accent, T.Accent2, 0)

        new("TextLabel", {
            Position = UDim2.new(0, 14, 0, 4), Size = UDim2.new(1, -110, 0, 18), BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left,
            Text = tostring(cfg.Name or "Hub"), Parent = header,
        })
        local subText = ""
        if cfg.LoadingTitle then subText = tostring(cfg.LoadingTitle) end
        if cfg.LoadingSubtitle then subText = subText .. "  •  " .. tostring(cfg.LoadingSubtitle) end
        new("TextLabel", {
            Position = UDim2.new(0, 14, 0, 21), Size = UDim2.new(1, -110, 0, 14), BackgroundTransparency = 1,
            Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = T.Sub, TextXAlignment = Enum.TextXAlignment.Left,
            Text = subText, Parent = header,
        })

        local function headerBtn(text, xOff)
            local b = new("TextButton", {
                Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(1, xOff, 0, 6), BackgroundColor3 = T.Item,
                AutoButtonColor = false, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = T.Text, Text = text, Parent = header,
            })
            round(b, 8)
            return b
        end
        local minBtn = headerBtn("–", -68)
        local closeBtn = headerBtn("✕", -36)

        makeDraggable(header, main)

        -- tombol melayang (buka/tutup menu)
        local float = new("Frame", {
            Name = "Float", Size = UDim2.new(0, 44, 0, 44), Position = UDim2.new(0, 14, 0.5, -22),
            BackgroundColor3 = T.White, BorderSizePixel = 0, Parent = gui,
        })
        round(float, 22)
        gradient(float, T.Accent, T.Accent2, 45)
        stroke(float, T.White, 1.5, 0.6)
        new("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack,
            TextSize = 22, TextColor3 = T.White, Text = "P", Parent = float,
        })

        local visible = true
        local function setVisible(v)
            visible = v
            if v then
                main.Visible = true
                scale.Scale = 0.85
                tween(scale, 0.18, {Scale = 1})
            else
                tween(scale, 0.15, {Scale = 0.85})
                task.delay(0.15, function()
                    if not visible and main.Parent then main.Visible = false end
                end)
            end
        end
        makeDraggable(float, float, function() setVisible(not visible) end)
        minBtn.MouseButton1Click:Connect(function() setVisible(false) end)
        UserInputService.InputBegan:Connect(function(i, gp)
            if not gp and i.KeyCode == Enum.KeyCode.RightShift then setVisible(not visible) end
        end)

        local closing = false
        closeBtn.MouseButton1Click:Connect(function()
            if closing then UI:Destroy() return end
            closing = true
            closeBtn.Text = "?"
            closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 80)
            UI:Notify({Title = "Tutup UI", Content = "Tekan sekali lagi untuk menutup UI. Fitur yang aktif tetap jalan.", Duration = 2.5})
            task.delay(2.5, function()
                closing = false
                if closeBtn.Parent then
                    closeBtn.Text = "✕"
                    closeBtn.BackgroundColor3 = T.Item
                end
            end)
        end)

        -- toast holder
        toastHolder = new("Frame", {
            AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10),
            Size = UDim2.new(0, 230, 1, -20), BackgroundTransparency = 1, Parent = gui,
        })
        new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = toastHolder})

        -- sidebar + konten
        local side = new("Frame", {Position = UDim2.new(0, 0, 0, 42), Size = UDim2.new(0, 94, 1, -42), BackgroundTransparency = 1, Parent = main})
        padding(side, 6, 8, 6, 6)
        new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = side})
        new("Frame", {
            Position = UDim2.new(0, 94, 0, 52), Size = UDim2.new(0, 1, 1, -62), BackgroundColor3 = T.Stroke,
            BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = main,
        })
        local content = new("Frame", {Position = UDim2.new(0, 100, 0, 44), Size = UDim2.new(1, -106, 1, -50), BackgroundTransparency = 1, Parent = main})

        local Window = {}
        local tabs = {}
        local tabCount = 0

        local function selectTab(t)
            for _, x in ipairs(tabs) do
                local on = (x == t)
                x.page.Visible = on
                x.bar.Visible = on
                tween(x.btn, 0.15, {BackgroundTransparency = on and 0 or 1})
                tween(x.lbl, 0.15, {TextColor3 = on and T.Text or T.Sub})
            end
        end

        local ICONS = {zap = "⚡", eye = "👁", settings = "⚙", info = "ℹ"}

        function Window:CreateTab(name, icon)
            tabCount = tabCount + 1
            local btn = new("TextButton", {
                Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = T.Item, BackgroundTransparency = 1,
                AutoButtonColor = false, Text = "", LayoutOrder = tabCount, Parent = side,
            })
            round(btn, 8)
            local bar = new("Frame", {
                Size = UDim2.new(0, 3, 0, 16), Position = UDim2.new(0, 0, 0.5, -8), BackgroundColor3 = T.Accent,
                BorderSizePixel = 0, Visible = false, Parent = btn,
            })
            round(bar, 2)
            local lbl = new("TextLabel", {
                Size = UDim2.new(1, -12, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1,
                Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = T.Sub, TextXAlignment = Enum.TextXAlignment.Left,
                Text = (ICONS[icon] or "•") .. "  " .. tostring(name), Parent = btn,
            })
            local page = new("ScrollingFrame", {
                Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
                ScrollBarImageColor3 = T.Accent, CanvasSize = UDim2.new(0, 0, 0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false, Parent = content,
            })
            padding(page, 2, 2, 6, 8)
            new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page})

            local tabData = {btn = btn, bar = bar, lbl = lbl, page = page}
            table.insert(tabs, tabData)
            btn.MouseButton1Click:Connect(function() selectTab(tabData) end)
            if #tabs == 1 then selectTab(tabData) end

            local Tab = {}
            local order = 0
            local function nextOrder() order = order + 1 return order end

            local function item(h)
                local f = new("Frame", {
                    Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = T.Item, BorderSizePixel = 0,
                    LayoutOrder = nextOrder(), Parent = page,
                })
                round(f, 8)
                stroke(f, T.Stroke, 1, 0.65)
                return f
            end
            local function itemLabel(parentObj, text)
                return new("TextLabel", {
                    Size = UDim2.new(1, -70, 0, 40), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1,
                    Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd, Text = tostring(text), Parent = parentObj,
                })
            end

            function Tab:CreateDivider()
                new("Frame", {
                    Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.Stroke, BackgroundTransparency = 0.6,
                    BorderSizePixel = 0, LayoutOrder = nextOrder(), Parent = page,
                })
            end

            function Tab:CreateSection(text)
                local l = new("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12,
                    TextColor3 = T.Accent, TextXAlignment = Enum.TextXAlignment.Left, Text = tostring(text),
                    LayoutOrder = nextOrder(), Parent = page,
                })
                padding(l, 4, 0, 0, 0)
            end

            function Tab:CreateLabel(text)
                local l = new("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = T.Sub, TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left, Text = tostring(text), LayoutOrder = nextOrder(), Parent = page,
                })
                padding(l, 4, 2, 4, 2)
                return {Set = function(_, t) l.Text = tostring(t) end}
            end

            function Tab:CreateParagraph(o)
                local f = new("Frame", {
                    Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.Item,
                    BorderSizePixel = 0, LayoutOrder = nextOrder(), Parent = page,
                })
                round(f, 8)
                stroke(f, T.Stroke, 1, 0.65)
                padding(f, 12, 10, 12, 10)
                new("UIListLayout", {Padding = UDim.new(0, 4), Parent = f})
                new("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 13,
                    TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left, Text = tostring(o.Title or ""), Parent = f,
                })
                new("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
                    Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = T.Sub, TextWrapped = true,
                    TextXAlignment = Enum.TextXAlignment.Left, Text = tostring(o.Content or ""), Parent = f,
                })
            end

            function Tab:CreateButton(o)
                local row = item(38)
                local b = new("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium,
                    TextSize = 13, TextColor3 = T.Text, Text = tostring(o.Name), Parent = row,
                })
                local function up() tween(row, 0.2, {BackgroundColor3 = T.Item}) end
                b.MouseButton1Down:Connect(function() tween(row, 0.08, {BackgroundColor3 = T.Accent}) end)
                b.MouseButton1Up:Connect(up)
                b.MouseLeave:Connect(up)
                b.MouseButton1Click:Connect(function() fire(o.Callback) end)
            end

            function Tab:CreateToggle(o)
                local state = (o.CurrentValue == true)
                local row = item(40)
                itemLabel(row, o.Name)
                local sw = new("Frame", {
                    Size = UDim2.new(0, 40, 0, 22), Position = UDim2.new(1, -52, 0.5, -11),
                    BackgroundColor3 = state and T.Accent or T.Off, BorderSizePixel = 0, Parent = row,
                })
                round(sw, 11)
                local knob = new("Frame", {
                    Size = UDim2.new(0, 18, 0, 18),
                    Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9),
                    BackgroundColor3 = T.White, BorderSizePixel = 0, Parent = sw,
                })
                round(knob, 9)
                local hit = new("TextButton", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", Parent = row})

                local function set(v, silent)
                    v = (v == true)
                    if v == state then return end
                    state = v
                    tween(sw, 0.15, {BackgroundColor3 = state and T.Accent or T.Off})
                    tween(knob, 0.15, {Position = state and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)})
                    if not silent then fire(o.Callback, state) end
                    queueSave()
                end
                hit.MouseButton1Click:Connect(function() set(not state) end)
                if o.Flag then Flags[o.Flag] = {Get = function() return state end, Set = set} end
                return {Set = function(_, v) set(v) end, Get = function() return state end}
            end

            function Tab:CreateSlider(o)
                local min, max = o.Range[1], o.Range[2]
                local inc = o.Increment or 1
                local value = math.clamp(o.CurrentValue or min, min, max)
                local suffix = o.Suffix or ""
                local row = item(54)
                new("TextLabel", {
                    Size = UDim2.new(1, -100, 0, 28), Position = UDim2.new(0, 12, 0, 2), BackgroundTransparency = 1,
                    Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = T.Text, TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd, Text = tostring(o.Name), Parent = row,
                })
                local valLbl = new("TextLabel", {
                    Size = UDim2.new(0, 76, 0, 28), Position = UDim2.new(1, -88, 0, 2), BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = T.Accent, TextXAlignment = Enum.TextXAlignment.Right,
                    Text = "", Parent = row,
                })
                local bar = new("Frame", {
                    Size = UDim2.new(1, -24, 0, 6), Position = UDim2.new(0, 12, 0, 36),
                    BackgroundColor3 = T.Off, BorderSizePixel = 0, Parent = row,
                })
                round(bar, 3)
                local fill = new("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = T.White, BorderSizePixel = 0, Parent = bar})
                round(fill, 3)
                gradient(fill, T.Accent, T.Accent2, 0)
                local knob = new("Frame", {
                    Size = UDim2.new(0, 14, 0, 14), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
                    BackgroundColor3 = T.White, BorderSizePixel = 0, Parent = bar,
                })
                round(knob, 7)
                stroke(knob, T.Accent, 2, 0)
                local hit = new("TextButton", {
                    Size = UDim2.new(1, 0, 0, 26), Position = UDim2.new(0, 0, 0, 26),
                    BackgroundTransparency = 1, Text = "", Parent = row,
                })

                local function render()
                    local rel = (max > min) and ((value - min) / (max - min)) or 0
                    fill.Size = UDim2.new(rel, 0, 1, 0)
                    knob.Position = UDim2.new(rel, 0, 0.5, 0)
                    valLbl.Text = tostring(value) .. suffix
                end
                local function set(v, silent)
                    v = math.clamp(math.floor(v / inc + 0.5) * inc, min, max)
                    v = math.floor(v * 100 + 0.5) / 100
                    if v == value then return end
                    value = v
                    render()
                    if not silent then fire(o.Callback, v) end
                    queueSave()
                end
                render()

                local sliding, dragInput = false, nil
                local function fromX(x)
                    local w = bar.AbsoluteSize.X
                    if w <= 0 then return end
                    local rel = math.clamp((x - bar.AbsolutePosition.X) / w, 0, 1)
                    set(min + (max - min) * rel)
                end
                hit.InputBegan:Connect(function(i)
                    if isPress(i) then
                        sliding, dragInput = true, i
                        page.ScrollingEnabled = false
                        fromX(i.Position.X)
                        i.Changed:Connect(function()
                            if i.UserInputState == Enum.UserInputState.End then
                                sliding = false
                                page.ScrollingEnabled = true
                            end
                        end)
                    end
                end)
                UserInputService.InputChanged:Connect(function(i)
                    if sliding and (i == dragInput or i.UserInputType == Enum.UserInputType.MouseMovement) then
                        fromX(i.Position.X)
                    end
                end)

                if o.Flag then Flags[o.Flag] = {Get = function() return value end, Set = set} end
                return {Set = function(_, v) set(v) end, Get = function() return value end}
            end

            function Tab:CreateColorPicker(o)
                local color = o.Color or T.White
                local hue = 0
                do
                    local hh, ss = color:ToHSV()
                    if ss > 0.05 then hue = hh end
                end
                local row = item(40)
                row.ClipsDescendants = true
                itemLabel(row, o.Name)
                local sw = new("Frame", {
                    Size = UDim2.new(0, 34, 0, 20), Position = UDim2.new(1, -46, 0, 10),
                    BackgroundColor3 = color, BorderSizePixel = 0, Parent = row,
                })
                round(sw, 6)
                stroke(sw, T.White, 1, 0.5)
                local hit = new("TextButton", {Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Text = "", Parent = row})

                local panel = new("Frame", {Position = UDim2.new(0, 12, 0, 46), Size = UDim2.new(1, -24, 0, 56), BackgroundTransparency = 1, Parent = row})
                local presets = new("Frame", {Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Parent = panel})
                new("UIGridLayout", {
                    CellSize = UDim2.new(0.11, 0, 0, 22), CellPadding = UDim2.new(0.0171, 0, 0, 0),
                    SortOrder = Enum.SortOrder.LayoutOrder, Parent = presets,
                })
                local hueBar = new("Frame", {
                    Position = UDim2.new(0, 0, 0, 38), Size = UDim2.new(1, 0, 0, 12),
                    BackgroundColor3 = T.White, BorderSizePixel = 0, Parent = panel,
                })
                round(hueBar, 6)
                new("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
                        ColorSequenceKeypoint.new(1 / 6, Color3.fromHSV(1 / 6, 1, 1)),
                        ColorSequenceKeypoint.new(2 / 6, Color3.fromHSV(2 / 6, 1, 1)),
                        ColorSequenceKeypoint.new(3 / 6, Color3.fromHSV(3 / 6, 1, 1)),
                        ColorSequenceKeypoint.new(4 / 6, Color3.fromHSV(4 / 6, 1, 1)),
                        ColorSequenceKeypoint.new(5 / 6, Color3.fromHSV(5 / 6, 1, 1)),
                        ColorSequenceKeypoint.new(1, Color3.fromHSV(0, 1, 1)),
                    }),
                    Parent = hueBar,
                })
                local hueKnob = new("Frame", {
                    Size = UDim2.new(0, 6, 1, 6), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(hue, 0, 0.5, 0),
                    BackgroundColor3 = T.White, BorderSizePixel = 0, Parent = hueBar,
                })
                round(hueKnob, 3)
                stroke(hueKnob, Color3.new(0, 0, 0), 1, 0.3)
                local hueHit = new("TextButton", {
                    Size = UDim2.new(1, 0, 0, 26), Position = UDim2.new(0, 0, 0, 31),
                    BackgroundTransparency = 1, Text = "", Parent = panel,
                })

                local function apply(c, silent)
                    if c == color then return end
                    color = c
                    sw.BackgroundColor3 = c
                    local hh, ss = c:ToHSV()
                    if ss > 0.05 then
                        hue = hh
                        hueKnob.Position = UDim2.new(hue, 0, 0.5, 0)
                    end
                    if not silent then fire(o.Callback, c) end
                    queueSave()
                end

                local PRESETS = {
                    Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 70, 70), Color3.fromRGB(255, 150, 40),
                    Color3.fromRGB(255, 230, 60), Color3.fromRGB(60, 255, 100), Color3.fromRGB(60, 230, 255),
                    Color3.fromRGB(80, 120, 255), Color3.fromRGB(190, 90, 255),
                }
                for idx, pc in ipairs(PRESETS) do
                    local s = new("TextButton", {
                        BackgroundColor3 = pc, Text = "", AutoButtonColor = false, BorderSizePixel = 0,
                        LayoutOrder = idx, Parent = presets,
                    })
                    round(s, 6)
                    s.MouseButton1Click:Connect(function() apply(pc) end)
                end

                local sliding, dragInput = false, nil
                local function fromX(x)
                    local w = hueBar.AbsoluteSize.X
                    if w <= 0 then return end
                    local rel = math.clamp((x - hueBar.AbsolutePosition.X) / w, 0, 1)
                    hue = rel
                    hueKnob.Position = UDim2.new(rel, 0, 0.5, 0)
                    apply(Color3.fromHSV(rel, 1, 1))
                end
                hueHit.InputBegan:Connect(function(i)
                    if isPress(i) then
                        sliding, dragInput = true, i
                        page.ScrollingEnabled = false
                        fromX(i.Position.X)
                        i.Changed:Connect(function()
                            if i.UserInputState == Enum.UserInputState.End then
                                sliding = false
                                page.ScrollingEnabled = true
                            end
                        end)
                    end
                end)
                UserInputService.InputChanged:Connect(function(i)
                    if sliding and (i == dragInput or i.UserInputType == Enum.UserInputType.MouseMovement) then
                        fromX(i.Position.X)
                    end
                end)

                local open = false
                hit.MouseButton1Click:Connect(function()
                    open = not open
                    tween(row, 0.2, {Size = UDim2.new(1, 0, 0, open and 108 or 40)})
                end)

                if o.Flag then Flags[o.Flag] = {Get = function() return color end, Set = apply} end
                return {Set = function(_, c) apply(c) end, Get = function() return color end}
            end

            return Tab
        end

        return Window
    end
end

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

local invisibleHidden = false
local invisibleOldCF = nil
local invisibleOldOffset = nil

local function restoreInvisiblePosition()
    if invisibleHidden and invisibleRootPart and invisibleRootPart.Parent then
        pcall(function()
            invisibleRootPart.CFrame = invisibleOldCF
            if invisibleHumanoid then invisibleHumanoid.CameraOffset = invisibleOldOffset end
        end)
    end
    invisibleHidden = false
end

local function toggleInvisible(state)
    invisibleEnabled = state
    if invisibleConnection then invisibleConnection:Disconnect() invisibleConnection = nil end
    -- kembalikan posisi dulu kalau lagi "disembunyikan", biar karakter ga jatuh/mati
    restoreInvisiblePosition()

    local char = LocalPlayer.Character
    if state and char then
        invisibleParts = {}
        invisibleRootPart = char:FindFirstChild("HumanoidRootPart")
        invisibleHumanoid = char:FindFirstChildOfClass("Humanoid")
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") and v.Transparency == 0 then
                table.insert(invisibleParts, {part = v, origTrans = v.Transparency})
                v.Transparency = 0.5
            end
        end
        invisibleConnection = RunService.Heartbeat:Connect(function()
            if not invisibleEnabled or invisibleHidden then return end
            local root, hum = invisibleRootPart, invisibleHumanoid
            if not (root and root.Parent and hum and hum.Parent and hum.Health > 0) then return end
            invisibleHidden = true
            invisibleOldCF = root.CFrame
            invisibleOldOffset = hum.CameraOffset
            -- sembunyi ke atas (bukan ke bawah) supaya ga kena batas void / FallenPartsDestroyHeight
            local hideCF = invisibleOldCF * CFrame.new(0, 30000, 0)
            pcall(function()
                root.CFrame = hideCF
                hum.CameraOffset = hideCF:ToObjectSpace(CFrame.new(invisibleOldCF.Position)).Position
            end)
            RunService.RenderStepped:Wait()
            restoreInvisiblePosition()
        end)
    else
        if char then
            for _, data in pairs(invisibleParts) do
                pcall(function()
                    if data.part and data.part.Parent then
                        data.part.Transparency = data.origTrans
                    end
                end)
            end
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") and v.Transparency == 0.5 then v.Transparency = 0 end
            end
        end
        invisibleParts = {}
        invisibleRootPart = nil
        invisibleHumanoid = nil
    end
end

-- aktifkan ulang invisible otomatis setelah respawn
LocalPlayer.CharacterAdded:Connect(function()
    if invisibleEnabled then
        task.wait(1)
        if invisibleEnabled then toggleInvisible(true) end
    end
end)

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
    if UI then
        UI:Notify({
            Title = "Rejoin",
            Content = "Sedang merejoin server...",
            Duration = 3
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
    if UI then
        UI:Notify({
            Title = "Server Hop",
            Content = "Mencari server baru...",
            Duration = 3
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
        if UI then
            UI:Notify({
                Title = "Server Hop",
                Content = "Mencoba metode alternatif...",
                Duration = 3
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

-- ================== MAIN UI (custom) ==================
local function loadMainScript()
    if mainWindowLoaded then return end
    mainWindowLoaded = true

    createPlayerCounter()

    local Window = UI:CreateWindow({
        Name = "Putzzdev XIT",
        LoadingTitle = "Drip Client",
        LoadingSubtitle = "Premium v8.2",
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

    -- ================== AIMLOCK (JARAK MAKS 100 STUD) ==================
    TabMain:CreateDivider()
    TabMain:CreateSection("🎯 Aimlock")

    local AIMLOCK_RANGE  = 100   -- jarak maksimal (stud)
    local AIMLOCK_SMOOTH = 0.3   -- 0.01 = pelan, 1 = instan
    local aimlockEnabled = false
    local aimlockConn    = nil
    local aimlockCurrent = nil   -- target yang sedang dikunci

    local function isValidAimTarget(p, myPos)
        if not p or p == LocalPlayer then return nil end
        if LocalPlayer.Team and p.Team == LocalPlayer.Team then return nil end -- skip teman satu tim
        local char = p.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        local head = char and char:FindFirstChild("Head")
        if not (hum and head) or hum.Health <= 0 then return nil end
        local dist = (head.Position - myPos).Magnitude
        if dist > AIMLOCK_RANGE then return nil end
        -- wall check: jangan kunci target yang ketutup tembok
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {LocalPlayer.Character, char}
        params.IgnoreWater = true
        local origin = Camera.CFrame.Position
        if workspace:Raycast(origin, head.Position - origin, params) then return nil end
        return head, dist
    end

    local function getAimTarget()
        local myChar = LocalPlayer.Character
        local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return nil end
        local myPos = myHRP.Position

        -- tetap kunci target lama selama masih valid (ga loncat-loncat)
        if aimlockCurrent then
            local head = isValidAimTarget(aimlockCurrent, myPos)
            if head then return head end
            aimlockCurrent = nil
        end

        -- cari yang paling dekat ke crosshair (layar), dalam jarak 100 stud
        local vp = Camera.ViewportSize
        local cx, cy = vp.X/2, vp.Y/2
        local bestHead, bestPlayer, bestScore = nil, nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            local head, dist = isValidAimTarget(p, myPos)
            if head then
                local sp, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local score = math.sqrt((sp.X-cx)^2 + (sp.Y-cy)^2) + dist * 0.5
                    if score < bestScore then
                        bestScore, bestHead, bestPlayer = score, head, p
                    end
                end
            end
        end
        aimlockCurrent = bestPlayer
        return bestHead
    end

    local function startAimlock()
        if aimlockConn then aimlockConn:Disconnect() end
        aimlockConn = RunService.RenderStepped:Connect(function()
            if not aimlockEnabled then return end
            local head = getAimTarget()
            if not head then return end
            local camPos = Camera.CFrame.Position
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(camPos, head.Position), AIMLOCK_SMOOTH)
        end)
    end

    TabMain:CreateToggle({
        Name = "Aimlock (maks 100 stud)",
        CurrentValue = false,
        Flag = "AimlockToggle",
        Callback = function(state)
            aimlockEnabled = state
            aimlockCurrent = nil
            if state then
                startAimlock()
                UI:Notify({Title="Aimlock", Content="Aktif! Jarak maks 100 stud.", Duration=2})
            else
                if aimlockConn then aimlockConn:Disconnect(); aimlockConn = nil end
                UI:Notify({Title="Aimlock", Content="Dinonaktifkan.", Duration=2})
            end
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
            if UI then
                UI:Notify({
                    Title = "Hologram",
                    Content = state and "Hologram DI-AKTIFKAN" or "Hologram Dinonaktifkan",
                    Duration = 2
                })
            end
        end,
    })

    -- ================== TAB SETTINGS ==================
    local TabSettings = Window:CreateTab("Settings", "settings")

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
            if UI then
                UI:Notify({
                    Title = "Full Bright",
                    Content = state and "Full Bright diaktifkan" or "Full Bright dinonaktifkan",
                    Duration = 2
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
            if UI then
                UI:Notify({
                    Title = "No Fog",
                    Content = state and "No Fog diaktifkan" or "No Fog dinonaktifkan",
                    Duration = 2
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
    TabSettings:CreateSection("💾 Config")
    TabSettings:CreateLabel("Pengaturan tersimpan otomatis & dimuat saat execute")

    TabSettings:CreateButton({
        Name = "🗑️ Reset Config",
        Callback = function()
            local ok = pcall(function()
                if delfile and isfile and isfile(UI.ConfigPath) then
                    delfile(UI.ConfigPath)
                end
            end)
            UI:Notify({Title = "Config", Content = ok and "Config direset. Execute ulang script." or "Gagal reset config.", Duration = 3})
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

    TabInfo:CreateSection("Informasi")
    TabInfo:CreateLabel("Executor: " .. userExecutor)

    TabInfo:CreateDivider()
    TabInfo:CreateSection("Developer")
    TabInfo:CreateLabel("Developer: Putzzdev")
    TabInfo:CreateLabel("WhatsApp: 088976255131")

    TabInfo:CreateDivider()
    TabInfo:CreateParagraph({
        Title = "💜 Terima Kasih",
        Content = "Terima kasih telah menggunakan script Drip Client, jangan lupa support developer!",
    })

    -- ================== LOAD CONFIG TERSIMPAN ==================
    task.wait(0.5)
    pcall(function() UI:LoadConfiguration() end)
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
loadMainScript()