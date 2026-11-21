local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- // Sound Effects
local function playSound(soundId)
	pcall(function()
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://" .. tostring(soundId)
		sound.Parent = SoundService
		sound:Play()
		sound.Ended:Connect(function()
			sound:Destroy()
		end)
	end)
end

playSound("2865227271")

-- // Config Save / Load
local CONFIG_FILE = "SuperRingPartsConfig.txt"
local config = {
	radius = 50,
	height = 100,
	rotationSpeed = 10,
	attractionStrength = 1000,
}

local function saveConfig()
	if typeof(writefile) == "function" then
		pcall(function()
			writefile(CONFIG_FILE, HttpService:JSONEncode(config))
		end)
	end
end

local function loadConfig()
	if typeof(isfile) == "function" and typeof(readfile) == "function" then
		pcall(function()
			if isfile(CONFIG_FILE) then
				local decoded = HttpService:JSONDecode(readfile(CONFIG_FILE))
				if typeof(decoded) == "table" then
					config.radius = tonumber(decoded.radius) or config.radius
					config.height = tonumber(decoded.height) or config.height
					config.rotationSpeed = tonumber(decoded.rotationSpeed) or config.rotationSpeed
					config.attractionStrength = tonumber(decoded.attractionStrength) or config.attractionStrength
				end
			end
		end)
	end
end

loadConfig()

-- // Cleanup Previous Instance
local guiParent = pcall(function() return CoreGui.Name end) and CoreGui or LocalPlayer:WaitForChild("PlayerGui")
if guiParent:FindFirstChild("SuperRingPartsGUI") then
	guiParent.SuperRingPartsGUI:Destroy()
end

-- // GUI Creation (CoreGui + Dark/Crimson Code Style)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SuperRingPartsGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = guiParent

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 320, 0, 520)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -260)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
MainFrame.BorderColor3 = Color3.fromRGB(220, 0, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -68, 0, 34)
Title.Position = UDim2.new(0, 6, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "SUPER RING PARTS V6"
Title.TextColor3 = Color3.fromRGB(255, 60, 60)
Title.Font = Enum.Font.Code
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

local TopBarDivider = Instance.new("Frame")
TopBarDivider.Size = UDim2.new(1, 0, 0, 34)
TopBarDivider.Position = UDim2.new(0, 0, 0, 0)
TopBarDivider.BackgroundColor3 = Color3.fromRGB(25, 10, 10)
TopBarDivider.BorderColor3 = Color3.fromRGB(180, 0, 0)
TopBarDivider.BorderSizePixel = 1
TopBarDivider.ZIndex = 0
TopBarDivider.Parent = MainFrame
Title.ZIndex = 2

-- Minimize & Close Buttons
local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Name = "MinimizeButton"
MinimizeButton.Size = UDim2.new(0, 32, 0, 32)
MinimizeButton.Position = UDim2.new(1, -66, 0, 1)
MinimizeButton.Text = "-"
MinimizeButton.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
MinimizeButton.BorderColor3 = Color3.fromRGB(180, 0, 0)
MinimizeButton.BorderSizePixel = 1
MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeButton.Font = Enum.Font.Code
MinimizeButton.TextSize = 15
MinimizeButton.ZIndex = 2
MinimizeButton.Parent = MainFrame

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 32, 0, 32)
CloseButton.Position = UDim2.new(1, -33, 0, 1)
CloseButton.Text = "X"
CloseButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseButton.BorderColor3 = Color3.fromRGB(255, 0, 0)
CloseButton.BorderSizePixel = 1
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.Code
CloseButton.TextSize = 15
CloseButton.ZIndex = 2
CloseButton.Parent = MainFrame

-- Toggle Ring Button
local ringPartsEnabled = false

local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(1, -20, 0, 36)
ToggleButton.Position = UDim2.new(0, 10, 0, 42)
ToggleButton.Text = "TORNADO: OFF"
ToggleButton.BackgroundColor3 = Color3.fromRGB(120, 20, 20)
ToggleButton.BorderColor3 = Color3.fromRGB(220, 0, 0)
ToggleButton.BorderSizePixel = 1
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.Code
ToggleButton.TextSize = 13
ToggleButton.Parent = MainFrame

-- Controls Container
local ControlsContainer = Instance.new("Frame")
ControlsContainer.Name = "ControlsContainer"
ControlsContainer.Size = UDim2.new(1, -20, 0, 330)
ControlsContainer.Position = UDim2.new(0, 10, 0, 84)
ControlsContainer.BackgroundTransparency = 1
ControlsContainer.Parent = MainFrame

local function createControl(name, yOffset, accentColor, labelText, defaultValue, callback)
	local row = Instance.new("Frame")
	row.Name = name .. "Row"
	row.Size = UDim2.new(1, 0, 0, 74)
	row.Position = UDim2.new(0, 0, 0, yOffset)
	row.BackgroundTransparency = 1
	row.Parent = ControlsContainer

	local DecreaseButton = Instance.new("TextButton")
	DecreaseButton.Size = UDim2.new(0, 38, 0, 34)
	DecreaseButton.Position = UDim2.new(0, 0, 0, 0)
	DecreaseButton.Text = "-"
	DecreaseButton.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
	DecreaseButton.BorderColor3 = accentColor
	DecreaseButton.BorderSizePixel = 1
	DecreaseButton.TextColor3 = Color3.fromRGB(255, 80, 80)
	DecreaseButton.Font = Enum.Font.Code
	DecreaseButton.TextSize = 15
	DecreaseButton.Parent = row

	local Display = Instance.new("TextLabel")
	Display.Size = UDim2.new(1, -84, 0, 34)
	Display.Position = UDim2.new(0, 42, 0, 0)
	Display.Text = labelText .. ": " .. tostring(defaultValue)
	Display.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
	Display.BorderColor3 = Color3.fromRGB(140, 0, 0)
	Display.BorderSizePixel = 1
	Display.TextColor3 = Color3.fromRGB(255, 255, 255)
	Display.Font = Enum.Font.Code
	Display.TextSize = 12
	Display.Parent = row

	local IncreaseButton = Instance.new("TextButton")
	IncreaseButton.Size = UDim2.new(0, 38, 0, 34)
	IncreaseButton.Position = UDim2.new(1, -38, 0, 0)
	IncreaseButton.Text = "+"
	IncreaseButton.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
	IncreaseButton.BorderColor3 = accentColor
	IncreaseButton.BorderSizePixel = 1
	IncreaseButton.TextColor3 = Color3.fromRGB(255, 80, 80)
	IncreaseButton.Font = Enum.Font.Code
	IncreaseButton.TextSize = 15
	IncreaseButton.Parent = row

	local TextBox = Instance.new("TextBox")
	TextBox.Size = UDim2.new(1, 0, 0, 32)
	TextBox.Position = UDim2.new(0, 0, 0, 38)
	TextBox.PlaceholderText = "Set " .. labelText .. " (0-10000)"
	TextBox.Text = ""
	TextBox.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
	TextBox.BorderColor3 = Color3.fromRGB(160, 0, 0)
	TextBox.BorderSizePixel = 1
	TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	TextBox.PlaceholderColor3 = Color3.fromRGB(140, 140, 150)
	TextBox.Font = Enum.Font.Code
	TextBox.TextSize = 12
	TextBox.Parent = row

	local function setVal(newVal)
		newVal = math.clamp(newVal, 0, 10000)
		Display.Text = labelText .. ": " .. tostring(newVal)
		callback(newVal)
		playSound("12221967")
		saveConfig()
	end

	DecreaseButton.MouseButton1Click:Connect(function()
		local current = tonumber(Display.Text:match("%-?%d+")) or defaultValue
		setVal(current - 10)
	end)

	IncreaseButton.MouseButton1Click:Connect(function()
		local current = tonumber(Display.Text:match("%-?%d+")) or defaultValue
		setVal(current + 10)
	end)

	TextBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			local parsed = tonumber(TextBox.Text)
			if parsed then
				setVal(parsed)
			end
			TextBox.Text = ""
		end
	end)
end

createControl("Radius", 0, Color3.fromRGB(200, 0, 0), "Radius", config.radius, function(v)
	config.radius = v
end)

createControl("Height", 80, Color3.fromRGB(200, 0, 0), "Height", config.height, function(v)
	config.height = v
end)

createControl("RotationSpeed", 160, Color3.fromRGB(200, 0, 0), "Rotation Speed", config.rotationSpeed, function(v)
	config.rotationSpeed = v
end)

createControl("AttractionStrength", 240, Color3.fromRGB(200, 0, 0), "Attraction", config.attractionStrength, function(v)
	config.attractionStrength = v
end)

-- // Extra Utility Buttons Grid
local ExtrasContainer = Instance.new("Frame")
ExtrasContainer.Name = "ExtrasContainer"
ExtrasContainer.Size = UDim2.new(1, -20, 0, 92)
ExtrasContainer.Position = UDim2.new(0, 10, 0, 418)
ExtrasContainer.BackgroundTransparency = 1
ExtrasContainer.Parent = MainFrame

local ExtrasGrid = Instance.new("UIGridLayout")
ExtrasGrid.CellSize = UDim2.new(0, 96, 0, 26)
ExtrasGrid.CellPadding = UDim2.new(0, 6, 0, 6)
ExtrasGrid.SortOrder = Enum.SortOrder.LayoutOrder
ExtrasGrid.Parent = ExtrasContainer

local function addExtraButton(text, callback)
	local btn = Instance.new("TextButton")
	btn.Text = text
	btn.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
	btn.BorderColor3 = Color3.fromRGB(180, 0, 0)
	btn.BorderSizePixel = 1
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.Code
	btn.TextSize = 11
	btn.Parent = ExtrasContainer
	btn.MouseButton1Click:Connect(function()
		playSound("12221967")
		callback(btn)
	end)
end

addExtraButton("Fly Gui", function()
	pcall(function()
		loadstring(game:HttpGet("https://pastebin.com/raw/YSL3xKYU"))()
	end)
end)

local noFallEnabled = false
addExtraButton("No Fall", function(btn)
	noFallEnabled = not noFallEnabled
	btn.Text = noFallEnabled and "No Fall: ON" or "No Fall"
	btn.TextColor3 = noFallEnabled and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 255, 255)
end)

local noclipEnabled = false
local noclipConn = nil
addExtraButton("Noclip", function(btn)
	noclipEnabled = not noclipEnabled
	btn.Text = noclipEnabled and "Noclip: ON" or "Noclip"
	btn.TextColor3 = noclipEnabled and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 255, 255)

	if noclipEnabled then
		if noclipConn then noclipConn:Disconnect() end
		noclipConn = RunService.Stepped:Connect(function()
			local char = LocalPlayer.Character
			if char then
				for _, part in ipairs(char:GetDescendants()) do
					if part:IsA("BasePart") and part.CanCollide then
						part.CanCollide = false
					end
				end
			end
		end)
	else
		if noclipConn then
			noclipConn:Disconnect()
			noclipConn = nil
		end
	end
end)

local infJumpEnabled = false
addExtraButton("Inf Jump", function(btn)
	infJumpEnabled = not infJumpEnabled
	btn.Text = infJumpEnabled and "Inf Jump: ON" or "Inf Jump"
	btn.TextColor3 = infJumpEnabled and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 255, 255)
end)

UserInputService.JumpRequest:Connect(function()
	if infJumpEnabled then
		local char = LocalPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end)

addExtraButton("Inf Yield", function()
	pcall(function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
	end)
end)

addExtraButton("Nameless", function()
	pcall(function()
		loadstring(game:HttpGet("https://scriptblox.com/raw/Universal-Script-Nameless-Admin-FE-11243"))()
	end)
end)

addExtraButton("FPS Boost", function()
	pcall(function()
		loadstring(game:HttpGet("https://pastebin.com/raw/ySHJdZpb", true))()
	end)
end)

-- // Minimize & Close Logic
local minimized = false
MinimizeButton.MouseButton1Click:Connect(function()
	minimized = not minimized
	MinimizeButton.Text = minimized and "+" or "-"
	ToggleButton.Visible = not minimized
	ControlsContainer.Visible = not minimized
	ExtrasContainer.Visible = not minimized
	MainFrame.Size = minimized and UDim2.new(0, 320, 0, 34) or UDim2.new(0, 320, 0, 520)
	playSound("12221967")
end)

CloseButton.MouseButton1Click:Connect(function()
	ringPartsEnabled = false
	if noclipConn then noclipConn:Disconnect() end
	ScreenGui:Destroy()
end)

-- // Draggable Logic
local dragging, dragInput, dragStart, startPos

MainFrame.InputBegan:Connect(function(input)
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

MainFrame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		MainFrame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

-- // Unanchored Parts Orbit / Tornado Logic
local parts = {}
local function isExcludedPart(part)
	local char = LocalPlayer.Character
	if char and (part == char or part:IsDescendantOf(char)) then
		return true
	end
	if part.Name == "Handle" then
		return true
	end
	local parent = part.Parent
	if parent and (parent:FindFirstChildOfClass("Humanoid") or parent:FindFirstChild("Head")) then
		return true
	end
	return false
end

local function addPart(part)
	if part:IsA("BasePart") and not part.Anchored and part:IsDescendantOf(Workspace) and not isExcludedPart(part) then
		pcall(function()
			part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
			part.CanCollide = false
		end)
		if not table.find(parts, part) then
			table.insert(parts, part)
		end
	end
end

local function removePart(part)
	local idx = table.find(parts, part)
	if idx then
		table.remove(parts, idx)
	end
end

for _, desc in ipairs(Workspace:GetDescendants()) do
	addPart(desc)
end

Workspace.DescendantAdded:Connect(addPart)
Workspace.DescendantRemoving:Connect(removePart)

ToggleButton.MouseButton1Click:Connect(function()
	ringPartsEnabled = not ringPartsEnabled
	ToggleButton.Text = ringPartsEnabled and "TORNADO: ON" or "TORNADO: OFF"
	ToggleButton.BackgroundColor3 = ringPartsEnabled and Color3.fromRGB(30, 130, 40) or Color3.fromRGB(120, 20, 20)
	playSound("12221967")
end)

-- // Single Unified Heartbeat Loop
local textHue = 0
RunService.Heartbeat:Connect(function()
	textHue = (textHue + 0.006) % 1
	Title.TextColor3 = Color3.fromHSV(textHue, 0.85, 1)

	if typeof(sethiddenproperty) == "function" then
		pcall(function()
			sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
		end)
	end

	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")

	if noFallEnabled and hrp and hrp.AssemblyLinearVelocity.Y < -25 then
		hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, -5, hrp.AssemblyLinearVelocity.Z)
	end

	if ringPartsEnabled and hrp then
		local center = hrp.Position
		local rotRad = math.rad(config.rotationSpeed)
		for i = #parts, 1, -1 do
			local part = parts[i]
			if not part or not part.Parent or part.Anchored or isExcludedPart(part) then
				table.remove(parts, i)
			else
				local pos = part.Position
				local radialDist = (Vector3.new(pos.X, center.Y, pos.Z) - center).Magnitude
				local angle = math.atan2(pos.Z - center.Z, pos.X - center.X) + rotRad
				local targetRadius = math.min(config.radius, math.max(4, radialDist))
				local heightRatio = (config.height > 0) and math.abs(math.sin((pos.Y - center.Y) / config.height)) or 0
				local targetPos = Vector3.new(
					center.X + math.cos(angle) * targetRadius,
					center.Y + (config.height * heightRatio),
					center.Z + math.sin(angle) * targetRadius
				)
				local dir = targetPos - pos
				if dir.Magnitude > 0.01 then
					part.AssemblyLinearVelocity = dir.Unit * config.attractionStrength
				end
			end
		end
	end
end)

-- // Startup Notification
pcall(function()
	local thumb = ""
	local ok, uid = pcall(function()
		return Players:GetUserIdFromNameAsync("Robloxlukasgames")
	end)
	if ok and uid then
		thumb = Players:GetUserThumbnailAsync(uid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	end
	StarterGui:SetCore("SendNotification", {
		Title = "Super Ring Parts V6",
		Text = "Loaded! Click textboxes or +/- to tune.",
		Icon = thumb,
		Duration = 4,
	})
end)
