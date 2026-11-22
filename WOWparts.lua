-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

--------------------------------------------------------------------------------
-- 1. DESTROY OLD SCRIPT INSTANCE & CLEAN EVERYTHING UP
--------------------------------------------------------------------------------
local env = (getgenv and getgenv()) or _G
if env.CleanupGrabTool then
	pcall(env.CleanupGrabTool)
end

--------------------------------------------------------------------------------
-- 2. CONFIGURATION
--------------------------------------------------------------------------------
local Config = {
	ToolName = "Grab",
	HoldDistance = 10,
	MinDistance = 3,
	MaxDistance = 80,
	DistanceStep = 3,
	AlwaysFlat = true,        -- Keeps grabbed parts/characters upright & level
	ShakeVelocity = false,    -- Off by default so carrying players stays smooth
	ShowGui = true
}

local connections = {}
local running = true

local tool = nil
local handle = nil
local targetAnchorPart = nil
local grabbedPart = nil
local grabbedModel = nil
local att0, att1, alignPos, alignOri = nil, nil, nil, nil
local selectionBox = nil
local screenGui = nil
local statusLabel = nil
local distanceLabel = nil
local sliderFill = nil

local function getCharacterParts()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	return char, hum, root
end

local function setModelCollidable(model, canCollide)
	if not model then return end
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("BasePart") and desc.Name ~= "HumanoidRootPart" then
			pcall(function()
				desc.CanCollide = canCollide
			end)
		end
	end
end

local function clearConstraints()
	if att0 then att0:Destroy() att0 = nil end
	if att1 then att1:Destroy() att1 = nil end
	if alignPos then alignPos:Destroy() alignPos = nil end
	if alignOri then alignOri:Destroy() alignOri = nil end

	if grabbedModel then
		setModelCollidable(grabbedModel, true)
	elseif grabbedPart and grabbedPart.Parent then
		pcall(function()
			grabbedPart.CanCollide = true
		end)
	end

	grabbedPart = nil
	grabbedModel = nil

	if selectionBox then
		selectionBox.Adornee = nil
	end
end

local function refreshGuiText()
	if distanceLabel then
		distanceLabel.Text = string.format("Hold Distance: %.0f studs", Config.HoldDistance)
	end
	if sliderFill then
		local ratio = (Config.HoldDistance - Config.MinDistance) / math.max(Config.MaxDistance - Config.MinDistance, 1)
		sliderFill.Size = UDim2.new(math.clamp(ratio, 0, 1), 0, 1, 0)
	end
	if statusLabel then
		local targetLabel = grabbedModel and grabbedModel.Name or (grabbedPart and grabbedPart.Name)
		if targetLabel then
			statusLabel.Text = "Holding: " .. targetLabel .. " (Click again to drop)"
		else
			statusLabel.Text = "Status: Ready  |  Scroll or [ / ] for distance"
		end
	end
end

local function setDistance(newDist)
	Config.HoldDistance = math.clamp(math.floor(newDist + 0.5), Config.MinDistance, Config.MaxDistance)
	refreshGuiText()
end

local function adjustDistance(delta)
	setDistance(Config.HoldDistance + delta)
end

--------------------------------------------------------------------------------
-- 3. TARGET RESOLUTION & FLAT ALIGN LOGIC
--------------------------------------------------------------------------------
local function resolveGrabbable(rawTarget)
	if not rawTarget or not rawTarget:IsA("BasePart") then return nil, nil end
	if rawTarget.Anchored then return nil, nil end
	if rawTarget:FindFirstChildOfClass("WeldConstraint") then return nil, nil end

	local myChar = player.Character
	if myChar and rawTarget:IsDescendantOf(myChar) then
		return nil, nil
	end

	-- If aiming at a player or humanoid character, grab its HumanoidRootPart so the whole body carries cleanly
	local ancestorModel = rawTarget:FindFirstAncestorWhichIsA("Model")
	if ancestorModel then
		local hum = ancestorModel:FindFirstChildOfClass("Humanoid")
		local hrp = ancestorModel:FindFirstChild("HumanoidRootPart")
		if hum and hrp and not hrp.Anchored then
			return hrp, ancestorModel
		end
	end

	return rawTarget, nil
end

local function attachGrab(rawTarget)
	local part, model = resolveGrabbable(rawTarget)
	if not part then return end

	clearConstraints()
	grabbedPart = part
	grabbedModel = model

	local a0 = Instance.new("Attachment")
	a0.Name = "GrabAttachment0"
	a0.Parent = grabbedPart

	local a1 = Instance.new("Attachment")
	a1.Name = "GrabAttachment1"
	a1.Parent = targetAnchorPart

	local ap = Instance.new("AlignPosition")
	ap.Name = "GrabAlignPosition"
	ap.Attachment0 = a0
	ap.Attachment1 = a1
	ap.RigidityEnabled = false
	ap.Responsiveness = 180
	ap.MaxForce = math.huge
	ap.MaxVelocity = math.huge
	ap.Parent = grabbedPart

	local ao = Instance.new("AlignOrientation")
	ao.Name = "GrabAlignOrientation"
	ao.Attachment0 = a0
	ao.Attachment1 = a1
	ao.RigidityEnabled = false
	ao.Responsiveness = 180
	ao.MaxTorque = math.huge
	ao.MaxAngularVelocity = math.huge
	ao.Parent = grabbedPart

	att0, att1, alignPos, alignOri = a0, a1, ap, ao

	if grabbedModel then
		setModelCollidable(grabbedModel, false)
	else
		grabbedPart.CanCollide = false
	end

	refreshGuiText()
end

local function isToolEquipped()
	local char = player.Character
	return tool ~= nil and char ~= nil and tool.Parent == char
end

local function toggleGrab()
	if not running or not isToolEquipped() then return end

	if grabbedPart then
		clearConstraints()
		refreshGuiText()
		return
	end

	local mouse = player:GetMouse()
	if mouse and mouse.Target then
		attachGrab(mouse.Target)
	end
end

--------------------------------------------------------------------------------
-- 4. TOOL & DARK-MODE GUI CONSTRUCTION
--------------------------------------------------------------------------------
local function buildTool()
	local backpack = player:FindFirstChildOfClass("Backpack") or player:WaitForChild("Backpack")

	if backpack:FindFirstChild(Config.ToolName) then
		backpack[Config.ToolName]:Destroy()
	end
	if player.Character and player.Character:FindFirstChild(Config.ToolName) then
		player.Character[Config.ToolName]:Destroy()
	end

	local newTool = Instance.new("Tool")
	newTool.Name = Config.ToolName
	newTool.RequiresHandle = true
	newTool.CanBeDropped = false
	newTool.Parent = backpack

	local newHandle = Instance.new("Part")
	newHandle.Name = "Handle"
	newHandle.Size = Vector3.new(1, 1, 1)
	newHandle.Transparency = 1
	newHandle.CanCollide = false
	newHandle.Massless = true
	newHandle.Parent = newTool

	local anchor = Instance.new("Part")
	anchor.Name = "GrabFlatAnchor"
	anchor.Size = Vector3.new(0.5, 0.5, 0.5)
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Transparency = 1
	anchor.Parent = Workspace

	local box = Instance.new("SelectionBox")
	box.Name = "GrabOwnerBox"
	box.Color3 = Color3.fromRGB(46, 204, 113)
	box.LineThickness = 0.02
	box.Parent = Workspace

	tool = newTool
	handle = newHandle
	targetAnchorPart = anchor
	selectionBox = box

	table.insert(connections, tool.Activated:Connect(function()
		toggleGrab()
	end))

	table.insert(connections, tool.Unequipped:Connect(function()
		clearConstraints()
		refreshGuiText()
	end))
end

local function buildGui()
	if not Config.ShowGui then return end

	local parentGui
	local okCore, core = pcall(function() return game:GetService("CoreGui") end)
	parentGui = (okCore and core) or player:WaitForChild("PlayerGui")

	if parentGui:FindFirstChild("FlatGrabHubGui") then
		parentGui.FlatGrabHubGui:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "FlatGrabHubGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = parentGui

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.new(0, 290, 0, 232)
	panel.Position = UDim2.new(1, -310, 0.5, -116)
	panel.BackgroundColor3 = Color3.fromRGB(16, 17, 22)
	panel.BorderSizePixel = 0
	panel.Parent = gui

	local pCorner = Instance.new("UICorner")
	pCorner.CornerRadius = UDim.new(0, 10)
	pCorner.Parent = panel

	local pStroke = Instance.new("UIStroke")
	pStroke.Color = Color3.fromRGB(45, 48, 65)
	pStroke.Thickness = 1.4
	pStroke.Parent = panel

	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 34)
	header.BackgroundColor3 = Color3.fromRGB(23, 25, 33)
	header.BorderSizePixel = 0
	header.Parent = panel

	local hCorner = Instance.new("UICorner")
	hCorner.CornerRadius = UDim.new(0, 10)
	hCorner.Parent = header

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -40, 1, 0)
	title.Position = UDim2.new(0, 10, 0, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 12
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Color3.fromRGB(240, 242, 250)
	title.Text = "FLAT CARRY GRAB // CONTROLS"
	title.Parent = header

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 24, 0, 24)
	closeBtn.Position = UDim2.new(1, -29, 0.5, -12)
	closeBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
	closeBtn.BorderSizePixel = 0
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 13
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Text = "×"
	closeBtn.Parent = header

	local cCorner = Instance.new("UICorner")
	cCorner.CornerRadius = UDim.new(0, 6)
	cCorner.Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		if env.CleanupGrabTool then
			env.CleanupGrabTool()
		end
	end)

	-- Dragging via header
	local dragging = false
	local dragStart = Vector2.zero
	local startPos = UDim2.new()

	header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = Vector2.new(input.Position.X, input.Position.Y)
			startPos = panel.Position
		end
	end)

	table.insert(connections, UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
			panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end))

	table.insert(connections, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))

	local body = Instance.new("Frame")
	body.Size = UDim2.new(1, -20, 1, -44)
	body.Position = UDim2.new(0, 10, 0, 40)
	body.BackgroundTransparency = 1
	body.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 7)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = body

	-- Status readout
	local stLbl = Instance.new("TextLabel")
	stLbl.Size = UDim2.new(1, 0, 0, 20)
	stLbl.BackgroundTransparency = 1
	stLbl.Font = Enum.Font.GothamMedium
	stLbl.TextSize = 11
	stLbl.TextXAlignment = Enum.TextXAlignment.Left
	stLbl.TextColor3 = Color3.fromRGB(170, 178, 198)
	stLbl.LayoutOrder = 1
	stLbl.Parent = body
	statusLabel = stLbl

	-- Distance Slider Card
	local sliderCard = Instance.new("Frame")
	sliderCard.Size = UDim2.new(1, 0, 0, 48)
	sliderCard.BackgroundColor3 = Color3.fromRGB(23, 25, 33)
	sliderCard.BorderSizePixel = 0
	sliderCard.LayoutOrder = 2
	sliderCard.Parent = body

	local sCorner = Instance.new("UICorner")
	sCorner.CornerRadius = UDim.new(0, 7)
	sCorner.Parent = sliderCard

	local dLbl = Instance.new("TextLabel")
	dLbl.Size = UDim2.new(1, -16, 0, 18)
	dLbl.Position = UDim2.new(0, 8, 0, 4)
	dLbl.BackgroundTransparency = 1
	dLbl.Font = Enum.Font.GothamMedium
	dLbl.TextSize = 11
	dLbl.TextXAlignment = Enum.TextXAlignment.Left
	dLbl.TextColor3 = Color3.fromRGB(230, 234, 245)
	dLbl.Parent = sliderCard
	distanceLabel = dLbl

	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, -16, 0, 8)
	track.Position = UDim2.new(0, 8, 0, 29)
	track.BackgroundColor3 = Color3.fromRGB(12, 13, 17)
	track.BorderSizePixel = 0
	track.Parent = sliderCard

	local tCorner = Instance.new("UICorner")
	tCorner.CornerRadius = UDim.new(1, 0)
	tCorner.Parent = track

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0.1, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
	fill.BorderSizePixel = 0
	fill.Parent = track
	sliderFill = fill

	local fCorner = Instance.new("UICorner")
	fCorner.CornerRadius = UDim.new(1, 0)
	fCorner.Parent = fill

	local draggingSlider = false
	local function updateFromInput(input)
		local ratio = math.clamp((input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		local val = Config.MinDistance + ratio * (Config.MaxDistance - Config.MinDistance)
		setDistance(val)
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingSlider = true
			updateFromInput(input)
		end
	end)

	table.insert(connections, UserInputService.InputChanged:Connect(function(input)
		if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromInput(input)
		end
	end))

	table.insert(connections, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingSlider = false
		end
	end))

	local function makeToggle(labelText, initial, order, callback)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 30)
		btn.BorderSizePixel = 0
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 11
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.LayoutOrder = order
		btn.Parent = body

		local bCorner = Instance.new("UICorner")
		bCorner.CornerRadius = UDim.new(0, 7)
		bCorner.Parent = btn

		local state = initial
		local function paint()
			btn.Text = labelText .. ": " .. (state and "ON" or "OFF")
			btn.BackgroundColor3 = state and Color3.fromRGB(46, 175, 105) or Color3.fromRGB(36, 39, 52)
		end
		paint()

		btn.MouseButton1Click:Connect(function()
			state = not state
			paint()
			callback(state)
		end)
	end

	makeToggle("Always Flat Carry", Config.AlwaysFlat, 3, function(v)
		Config.AlwaysFlat = v
	end)

	makeToggle("Shake / Push Velocity", Config.ShakeVelocity, 4, function(v)
		Config.ShakeVelocity = v
	end)

	local dropBtn = Instance.new("TextButton")
	dropBtn.Size = UDim2.new(1, 0, 0, 30)
	dropBtn.BackgroundColor3 = Color3.fromRGB(195, 65, 65)
	dropBtn.BorderSizePixel = 0
	dropBtn.Font = Enum.Font.GothamBold
	dropBtn.TextSize = 11
	dropBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	dropBtn.Text = "Drop Held Target"
	dropBtn.LayoutOrder = 5
	dropBtn.Parent = body

	local dCorner = Instance.new("UICorner")
	dCorner.CornerRadius = UDim.new(0, 7)
	dCorner.Parent = dropBtn

	dropBtn.MouseButton1Click:Connect(function()
		clearConstraints()
		refreshGuiText()
	end)

	screenGui = gui
	refreshGuiText()
end

buildTool()
buildGui()

--------------------------------------------------------------------------------
-- 5. CONTROLS, FLAT ANCHOR LOOP & FULL CLEANUP
--------------------------------------------------------------------------------
table.insert(connections, UserInputService.InputChanged:Connect(function(input, gameProcessed)
	if not running or gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseWheel and isToolEquipped() then
		if input.Position.Z > 0 then
			adjustDistance(Config.DistanceStep)
		elseif input.Position.Z < 0 then
			adjustDistance(-Config.DistanceStep)
		end
	end
end))

table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not running or gameProcessed or not isToolEquipped() then return end
	if input.KeyCode == Enum.KeyCode.LeftBracket then
		adjustDistance(-Config.DistanceStep)
	elseif input.KeyCode == Enum.KeyCode.RightBracket then
		adjustDistance(Config.DistanceStep)
	end
end))

table.insert(connections, player.CharacterAdded:Connect(function()
	clearConstraints()
	task.wait(0.25)
	if running then
		buildTool()
		refreshGuiText()
	end
end))

table.insert(connections, RunService.Heartbeat:Connect(function()
	if not running then return end

	local camera = Workspace.CurrentCamera
	local _, _, root = getCharacterParts()

	if targetAnchorPart and camera then
		local basePos = (root and root.Position) or camera.CFrame.Position
		local flatLook = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
		if flatLook.Magnitude < 0.001 then
			flatLook = Vector3.new(0, 0, -1)
		else
			flatLook = flatLook.Unit
		end

		local targetPos = Vector3.new(
			basePos.X + flatLook.X * Config.HoldDistance,
			basePos.Y + 1.2,
			basePos.Z + flatLook.Z * Config.HoldDistance
		)

		if Config.AlwaysFlat then
			-- Level horizontal CFrame (no roll/tilt) so carried players stay upright
			targetAnchorPart.CFrame = CFrame.lookAt(targetPos, targetPos + flatLook, Vector3.yAxis)
		else
			targetAnchorPart.CFrame = CFrame.new(targetPos, camera.CFrame.Position + camera.CFrame.LookVector * (Config.HoldDistance + 5))
		end
	end

	if grabbedPart then
		if not grabbedPart.Parent or grabbedPart.Anchored or not isToolEquipped() then
			clearConstraints()
			refreshGuiText()
			return
		end

		local owned = (grabbedPart.ReceiveAge == 0)
		if selectionBox then
			selectionBox.Adornee = owned and grabbedPart or nil
		end

		if Config.ShakeVelocity and owned then
			local sine = os.clock()
			grabbedPart.AssemblyLinearVelocity = Vector3.new(
				-25.1 + math.pi * math.sin(sine * 15),
				25.1 + math.pi * math.sin(sine * 15),
				25.1 + math.pi * math.sin(sine * 15)
			)
			grabbedPart.AssemblyAngularVelocity = Vector3.new(
				math.pi / 6 * math.sin(sine * 15),
				math.pi / 6 * math.sin(sine * 15),
				math.pi / 6 * math.sin(sine * 15)
			)
		end
	elseif selectionBox then
		selectionBox.Adornee = nil
	end
end))

env.CleanupGrabTool = function()
	running = false
	clearConstraints()
	for _, conn in ipairs(connections) do
		if conn.Connected then conn:Disconnect() end
	end
	table.clear(connections)

	if tool then tool:Destroy() tool = nil end
	if targetAnchorPart then targetAnchorPart:Destroy() targetAnchorPart = nil end
	if selectionBox then selectionBox:Destroy() selectionBox = nil end
	if screenGui then screenGui:Destroy() screenGui = nil end
end
