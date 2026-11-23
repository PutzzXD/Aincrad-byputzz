
if not game:IsLoaded() then
	game.Loaded:Wait()
end

local MarketplaceService = game:GetService("MarketplaceService")
local LobbyPlaceId = 77900175935766

local okLobby, lobbyInfo = pcall(function()
	return MarketplaceService:GetProductInfo(LobbyPlaceId)
end)

local okCurrent, currentInfo = pcall(function()
	return MarketplaceService:GetProductInfo(game.PlaceId)
end)

local isSameCreator = okLobby
	and okCurrent
	and lobbyInfo.Creator
	and currentInfo.Creator
	and lobbyInfo.Creator.Id == currentInfo.Creator.Id

local isSameGame =
	game.PlaceId == LobbyPlaceId
	or game.GameId == 9085869747
	or isSameCreator

if not isSameGame then
	return
end

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local TargetParent = (gethui and gethui()) or CoreGui

for _, old in ipairs(TargetParent:GetChildren()) do
	if old.Name == "SYI_CleanAutoWrite" then
		old:Destroy()
	end
end

local WordList = {
	"Minigun", "Airstrike", "Tank", "Laser", "Bankai", "Time Stop", "Infinity",
	"Nuke", "Bomb", "Missile", "Wizard", "Sword", "Shotgun", "Rocket", "AWP",
	"Flamethrower", "Grenade", "Dynamite", "Cannon", "Landmine", "Orbital Strike",
	"Tactical Nuke", "Railgun", "Sniper", "Katana", "Hammer", "Bazooka", "Turret",
	"Slenderman", "Skeleton", "Pirate", "Invisible", "Zombie", "Giant", "Angel",
	"Kaiju", "Mummy", "Robot", "Beast", "Dragon", "Vampire", "Ghost", "Alien",
	"Jeff the Killer", "Monster", "Noob", "Guest 666", "Titan", "Kraken", "Demon",
	"Clown", "Witch", "Reaper", "Golem", "Werewolf", "Yeti", "Ninja", "Samurai",
	"Spider", "Crab", "Monkey", "Octopus", "Elephant", "Dinosaur", "Bee", "Shark",
	"Bear", "Capybara", "Wolf", "Snake", "Crocodile", "Gorilla", "Tiger", "Lion",
	"Frog", "Penguin", "Chicken", "Cow", "Pig", "Cat", "Dog", "Horse", "Whale",
	"Tsunami", "Flood", "Flash Flood", "Satellite", "Volcano", "Supernova",
	"Blackhole", "Meteor", "Tornado", "Earthquake", "Lava", "Acid Rain", "Blizzard",
	"Lightning", "Fire", "Wildfire", "Avalanche", "Hurricane", "Sandstorm", "Sinkhole",
	"Eclipse", "Solar Flare", "Zone", "Star", "Sun", "Moon", "Asteroid", "Void",
	"Acid", "Poison", "Ice", "Quicksand", "Spikes", "Darkness", "Fog", "Mud", "Desert",
	"School", "Roblox HQ", "Pyramid", "Church", "Backrooms", "Maze", "Prison",
	"Castle", "Tower", "Bunker", "Safehouse", "Hospital", "City", "Island", "Bridge",
	"Launchpad", "Medkit", "Car", "Lucky Block", "Boat", "Helicopter", "Titanic",
	"Spaceship", "Train", "Plane", "UFO", "Trampoline", "Platform", "Wall", "Shield",
	"Forcefield", "Jetpack", "Wings", "Snowball", "Hot Potato", "Fireworks", "Legos",
	"Oil", "Falling Blocks", "Slot Machine", "Super Star", "Taco", "Pizza", "Burger",
	"Apple", "Banana", "Cake", "Cookie", "Donut", "Ice Cream", "Sushi", "Ramen",
	"Walk", "Teleport", "Skibidi", "Cry", "Sneeze", "Dance", "Jump", "Speed",
	"Gravity", "Low Gravity", "High Gravity", "Fly", "Push", "Sleep", "Troll",
	"Upside Down", "Hero", "Domain", "Kill", "MrBeast", "Gojo", "Luffy", "Snap",
	"Jesus", "Immortal", "God", "Heal", "Clone", "Shrink", "Big", "Invisible"
}

local AutoWrite = false
local RandomGenerator = Random.new()
local RetryDelay = 3
local LoopDelay = 1
local LastWord = nil
local TriedWords = {}

local Gui = Instance.new("ScreenGui")
Gui.Name = "SYI_CleanAutoWrite"
Gui.ResetOnSpawn = false
Gui.Parent = TargetParent

local Frame = Instance.new("Frame")
Frame.Parent = Gui
Frame.Size = UDim2.new(0, 250, 0, 160)
Frame.Position = UDim2.new(0.5, -125, 0.25, 0)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
Frame.Active = true

Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel")
Title.Parent = Frame
Title.Size = UDim2.new(0.75, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
Title.BackgroundTransparency = 1
Title.Text = "Survive Your Ideas - Auto Write"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.Active = true

local Minimize = Instance.new("TextButton")
Minimize.Parent = Frame
Minimize.Size = UDim2.new(0, 27, 0, 25)
Minimize.Position = UDim2.new(1, -58, 0, 2)
Minimize.BackgroundColor3 = Color3.fromRGB(65, 65, 78)
Minimize.Text = "−"
Minimize.TextColor3 = Color3.new(1, 1, 1)
Minimize.Font = Enum.Font.GothamBold
Minimize.TextSize = 18

Instance.new("UICorner", Minimize).CornerRadius = UDim.new(0, 5)

local Close = Instance.new("TextButton")
Close.Parent = Frame
Close.Size = UDim2.new(0, 27, 0, 25)
Close.Position = UDim2.new(1, -29, 0, 2)
Close.BackgroundColor3 = Color3.fromRGB(190, 55, 55)
Close.Text = "X"
Close.TextColor3 = Color3.new(1, 1, 1)
Close.Font = Enum.Font.GothamBold
Close.TextSize = 13

Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 8)

local Toggle = Instance.new("TextButton")
Toggle.Parent = Frame
Toggle.Size = UDim2.new(0.9, 0, 0, 40)
Toggle.Position = UDim2.new(0.05, 0, 0.26, 0)
Toggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
Toggle.Text = "Auto Write: OFF"
Toggle.TextColor3 = Color3.new(1, 1, 1)
Toggle.Font = Enum.Font.GothamBold
Toggle.TextSize = 14

Instance.new("UICorner", Toggle).CornerRadius = UDim.new(0, 6)

local Info = Instance.new("TextLabel")
Info.Parent = Frame
Info.Size = UDim2.new(0.9, 0, 0, 28)
Info.Position = UDim2.new(0.05, 0, 0.56, 0)
Info.BackgroundTransparency = 1
Info.Text = "Status: Waiting for input..."
Info.TextColor3 = Color3.fromRGB(180, 220, 255)
Info.Font = Enum.Font.Gotham
Info.TextSize = 11
Info.TextWrapped = true

local Credit = Instance.new("TextLabel")
Credit.Parent = Frame
Credit.Size = UDim2.new(0.9, 0, 0, 20)
Credit.Position = UDim2.new(0.05, 0, 0.80, 0)
Credit.BackgroundTransparency = 1
Credit.Text = "Credit: NP20K12"
Credit.TextColor3 = Color3.fromRGB(140, 140, 155)
Credit.Font = Enum.Font.GothamBold
Credit.TextSize = 11

local Dragging = false
local DragInput
local DragStart
local StartPosition

local function UpdateDrag(input)
	local Delta = input.Position - DragStart

	Frame.Position = UDim2.new(
		StartPosition.X.Scale,
		StartPosition.X.Offset + Delta.X,
		StartPosition.Y.Scale,
		StartPosition.Y.Offset + Delta.Y
	)
end

Title.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		Dragging = true
		DragStart = input.Position
		StartPosition = Frame.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				Dragging = false
			end
		end)
	end
end)

Title.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then
		DragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if Dragging and input == DragInput then
		UpdateDrag(input)
	end
end)

local Minimized = false

Minimize.MouseButton1Click:Connect(function()
	Minimized = not Minimized

	if Minimized then
		Frame:TweenSize(
			UDim2.new(0, 250, 0, 30),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Quad,
			0.2,
			true
		)
		Minimize.Text = "+"
		Toggle.Visible = false
		Info.Visible = false
		Credit.Visible = false
	else
		Frame:TweenSize(
			UDim2.new(0, 250, 0, 160),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Quad,
			0.2,
			true
		)
		Minimize.Text = "−"
		Toggle.Visible = true
		Info.Visible = true
		Credit.Visible = true
	end
end)

Close.MouseButton1Click:Connect(function()
	AutoWrite = false
	Gui:Destroy()
end)

local function RandomWord()
	if #TriedWords >= #WordList then
		table.clear(TriedWords)
	end

	local Available = {}

	for _, word in ipairs(WordList) do
		if not TriedWords[word] and word ~= LastWord then
			table.insert(Available, word)
		end
	end

	if #Available == 0 then
		table.clear(TriedWords)

		for _, word in ipairs(WordList) do
			if word ~= LastWord then
				table.insert(Available, word)
			end
		end
	end

	local word = Available[RandomGenerator:NextInteger(1, #Available)]

	TriedWords[word] = true
	LastWord = word

	return word
end

local function GetGameUI()
	local boxes = {}
	local buttons = {}

	for _, obj in ipairs(PlayerGui:GetDescendants()) do
		if obj:IsA("TextBox") and obj.Visible then
			table.insert(boxes, obj)
		elseif (obj:IsA("TextButton") or obj:IsA("ImageButton"))
			and obj.Visible then

			local nameLower = obj.Name:lower()
			local textLower = obj:IsA("TextButton") and obj.Text:lower() or ""

			if nameLower:find("submit")
				or nameLower:find("send")
				or textLower:find("submit")
				or textLower:find("send")
				or textLower:find("write") then

				table.insert(buttons, obj)
			end
		end
	end

	return boxes, buttons
end

local function SubmitWord(boxes, buttons, word)
	local box = boxes[1]

	if not box or not box.Parent then
		return false
	end

	local oldText = box.Text

	box:CaptureFocus()
	task.wait(0.1)

	if not AutoWrite then
		return false
	end

	box.Text = word
	task.wait(0.2)

	if not AutoWrite then
		return false
	end

	box:ReleaseFocus(true)
	task.wait(0.2)

	local submitted = false

	for _, btn in ipairs(buttons) do
		if btn.Parent and btn.Visible and not submitted then
			if firesignal then
				local success = pcall(function()
					firesignal(btn.Activated)
				end)

				if success then
					submitted = true
				end
			end
		end
	end

	if not submitted then
		pcall(function()
			VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
			task.wait(0.05)
			VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
		end)
	end

	local startTime = os.clock()

	while AutoWrite and os.clock() - startTime < RetryDelay do
		task.wait(0.1)

		if not box.Parent then
			return false
		end

		if box.Text ~= word then
			if box.Text == "" or box.Text == oldText then
				Info.Text = "Written: " .. word
				return true
			end
		end
	end

	return false
end

Toggle.MouseButton1Click:Connect(function()
	AutoWrite = not AutoWrite

	Toggle.Text = AutoWrite and "Auto Write: ON" or "Auto Write: OFF"

	Toggle.BackgroundColor3 = AutoWrite
		and Color3.fromRGB(45, 180, 85)
		or Color3.fromRGB(200, 50, 50)

	if not AutoWrite then
		Info.Text = "Status: Waiting for input..."

		for _, obj in ipairs(PlayerGui:GetDescendants()) do
			if obj:IsA("TextBox") and obj:IsFocused() then
				obj:ReleaseFocus()
			end
		end
	end
end)

task.spawn(function()
	while Gui.Parent do
		if not AutoWrite then
			task.wait(0.2)
			continue
		end

		local boxes, buttons = GetGameUI()

		if #boxes == 0 then
			Info.Text = "Status: Waiting for input..."
			task.wait(0.5)
			continue
		end

		local word = RandomWord()
		local success = SubmitWord(boxes, buttons, word)

		if AutoWrite then
			if success then
				task.wait(LoopDelay)
			else
				task.wait(RetryDelay)
			end
		end
	end
end)
