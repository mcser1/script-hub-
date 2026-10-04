-- // Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- // Global States
getgenv().AntiFallDamage = true
getgenv().Spinning = false
getgenv().FlingActive = false
getgenv().RingActive = false
getgenv().ESPActive = false

-- // Anti Fall Damage (Natural Disaster Survival Specific)
local z = Vector3.zero
local function SetupAntiFallDamage(c)
    if not c then return end
    local r = c:WaitForChild("HumanoidRootPart", 5)
    if r then
        local con
        con = RunService.Heartbeat:Connect(function()
            if not r.Parent or not getgenv().AntiFallDamage then
                if not r.Parent then con:Disconnect() end
                return
            end
            local v = r.AssemblyLinearVelocity
            r.AssemblyLinearVelocity = z
            RunService.RenderStepped:Wait()
            r.AssemblyLinearVelocity = v
        end)
    end
end

if LocalPlayer.Character then
    SetupAntiFallDamage(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(SetupAntiFallDamage)

-- // Helper Functions
local function Notify(title, text, duration)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration or 3
    })
end

local function GetTargetPlayers(input)
    local found = {}
    local str = input:lower():gsub("%s+", "")
    local allPlayers = Players:GetPlayers()

    if str == "" then return found end

    if str == "all" or str == "others" then
        for _, v in ipairs(allPlayers) do
            if v ~= LocalPlayer then table.insert(found, v) end
        end
        return found
    elseif str == "random" then
        local others = {}
        for _, v in ipairs(allPlayers) do
            if v ~= LocalPlayer then table.insert(others, v) end
        end
        if #others > 0 then
            table.insert(found, others[math.random(1, #others)])
        end
        return found
    elseif str == "me" then
        return {LocalPlayer}
    end

    for _, v in ipairs(allPlayers) do
        if v.Name:lower():sub(1, #str) == str or v.DisplayName:lower():sub(1, #str) == str then
            table.insert(found, v)
        end
    end
    return found
end

local function GetNearestPlayer()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local nearestPlr = nil
    local nearestDist = math.huge

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local tRoot = plr.Character:FindFirstChild("HumanoidRootPart")
            if tRoot then
                local dist = (root.Position - tRoot.Position).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearestPlr = plr
                end
            end
        end
    end
    return nearestPlr
end

-- // Visual Ring Generator
local RingFolder = workspace:FindFirstChild("FlingRingParts") or Instance.new("Folder", workspace)
RingFolder.Name = "FlingRingParts"

local function ToggleRingParts(enable)
    getgenv().RingActive = enable
    RingFolder:ClearAllChildren()

    if not enable then return end

    task.spawn(function()
        local partCount = 12
        local radius = 5
        local parts = {}

        for i = 1, partCount do
            local p = Instance.new("Part")
            p.Size = Vector3.new(0.6, 0.6, 0.6)
            p.Material = Enum.Material.Neon
            p.Color = Color3.fromRGB(255, 0, 0)
            p.CanCollide = false
            p.Anchored = true
            p.Parent = RingFolder
            table.insert(parts, p)
        end

        local angle = 0
        while getgenv().RingActive do
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                angle = angle + 0.05
                for i, p in ipairs(parts) do
                    local currentAngle = angle + (i * (math.pi * 2 / partCount))
                    local offset = Vector3.new(math.cos(currentAngle) * radius, 0, math.sin(currentAngle) * radius)
                    p.CFrame = CFrame.new(root.Position + offset) * CFrame.Angles(angle, angle, 0)
                end
            end
            RunService.RenderStepped:Wait()
        end
        RingFolder:ClearAllChildren()
    end)
end

-- // Player ESP System (Fixed Cleanup)
local ESPConnections = {}

local function RemoveESPFromChar(char)
    if not char then return end
    for _, item in ipairs(char:GetDescendants()) do
        if item.Name == "c00lkidd_HL" or item.Name == "c00lkidd_Tag" then
            item:Destroy()
        end
    end
end

local function ApplyESP(plr)
    if plr == LocalPlayer then return end

    local function CreateHighlight(char)
        if not char or not getgenv().ESPActive then return end
        RemoveESPFromChar(char)

        local hl = Instance.new("Highlight")
        hl.Name = "c00lkidd_HL"
        hl.Adornee = char
        hl.FillColor = Color3.fromRGB(255, 0, 0)
        hl.FillTransparency = 0.5
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.OutlineTransparency = 0
        hl.Parent = char

        local head = char:WaitForChild("Head", 5)
        if head and getgenv().ESPActive and not head:FindFirstChild("c00lkidd_Tag") then
            local bb = Instance.new("BillboardGui")
            bb.Name = "c00lkidd_Tag"
            bb.Adornee = head
            bb.Size = UDim2.new(0, 100, 0, 30)
            bb.StudsOffset = Vector3.new(0, 2.5, 0)
            bb.AlwaysOnTop = true

            local txt = Instance.new("TextLabel")
            txt.Parent = bb
            txt.Size = UDim2.new(1, 0, 1, 0)
            txt.BackgroundTransparency = 1
            txt.Font = Enum.Font.Code
            txt.Text = plr.DisplayName
            txt.TextColor3 = Color3.fromRGB(255, 30, 30)
            txt.TextScaled = true
            txt.TextStrokeTransparency = 0
            bb.Parent = head
        end
    end

    if plr.Character then CreateHighlight(plr.Character) end
    if not ESPConnections[plr] then
        ESPConnections[plr] = plr.CharacterAdded:Connect(CreateHighlight)
    end
end

local function ToggleESP(enable)
    getgenv().ESPActive = enable
    if not enable then
        for plr, conn in pairs(ESPConnections) do
            if conn then conn:Disconnect() end
        end
        ESPConnections = {}

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character then
                RemoveESPFromChar(plr.Character)
            end
        end
    else
        for _, plr in ipairs(Players:GetPlayers()) do
            ApplyESP(plr)
        end
    end
end

Players.PlayerAdded:Connect(function(plr)
    if getgenv().ESPActive then ApplyESP(plr) end
end)

Players.PlayerRemoving:Connect(function(plr)
    if ESPConnections[plr] then
        ESPConnections[plr]:Disconnect()
        ESPConnections[plr] = nil
    end
end)

-- // High-Velocity Fling Engine
local function StopAllFlings()
    getgenv().FlingActive = false
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if humanoid then
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
            workspace.CurrentCamera.CameraSubject = humanoid
        end
        if root then
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
    end
    Notify("c00lkidd Fling", "All active fling threads terminated.", 3)
end

local function ExecuteFling(targetPlayer, flingMode)
    if not targetPlayer or targetPlayer == LocalPlayer then return end

    local char = LocalPlayer.Character
    local targetChar = targetPlayer.Character
    if not char or not targetChar then return end

    local root = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local tRoot = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Head")
    local tHumanoid = targetChar:FindFirstChildOfClass("Humanoid")

    if not root or not tRoot or not humanoid or (tHumanoid and tHumanoid.Health <= 0) then return end

    getgenv().FlingActive = true
    local oldPos = root.CFrame
    local oldFPDH = workspace.FallenPartsDestroyHeight
    workspace.FallenPartsDestroyHeight = 0/0

    workspace.CurrentCamera.CameraSubject = tRoot
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end

    local bv = Instance.new("BodyVelocity")
    bv.Name = "EpixVel"
    bv.Velocity = Vector3.new(9000000000, 9000000000, 9000000000)
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Parent = root

    local startTime = tick()
    local angle = 0

    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not getgenv().FlingActive or not root or not tRoot or not tRoot.Parent then
            if connection then connection:Disconnect() end
            return
        end

        angle = angle + 120
        
        if flingMode == "IY" then
            -- // Ultimate Fling GUI Step Calculation Engine
            local function StepFling(targetPart, offsetCFrame, angleCFrame)
                if not root or not char then return end
                root.CFrame = (CFrame.new(targetPart.Position)) * offsetCFrame * angleCFrame
                char:SetPrimaryPartCFrame((CFrame.new(targetPart.Position)) * offsetCFrame * angleCFrame)

                root.Velocity = Vector3.new(9000000000, 900000000000, 9000000000)
                root.RotVelocity = Vector3.new(9000000000, 9000000000, 9000000000)
            end

            local targetVel = tRoot.Velocity.Magnitude
            local moveDir = tHumanoid and tHumanoid.MoveDirection or Vector3.zero

            if targetVel < 50 then
                angle = angle + 150
                StepFling(tRoot, (CFrame.new(0, 1.5, 0)) + moveDir * targetVel / 1.25, CFrame.Angles(math.rad(angle), 0, 0))
                task.wait()
                StepFling(tRoot, (CFrame.new(0, -1.5, 0)) + moveDir * targetVel / 1.25, CFrame.Angles(math.rad(angle), 0, 0))
                task.wait()
                StepFling(tRoot, (CFrame.new(3.5, 2.5, -3.5)) + moveDir * targetVel / 1.25, CFrame.Angles(math.rad(angle), 0, 0))
                task.wait()
                StepFling(tRoot, (-3.5, -2.5, 3.5) + moveDir * targetVel / 1.25, CFrame.Angles(math.rad(angle), 0, 0))
                task.wait()
                StepFling(tRoot, (CFrame.new(0, 2, 0)) + moveDir * 2, CFrame.Angles(math.rad(angle), 0, 0))
                task.wait()
                StepFling(tRoot, (CFrame.new(0, -2, 0)) + moveDir * 2, CFrame.Angles(math.rad(angle), 0, 0))
                task.wait()
            else
                local walkSpeed = tHumanoid and tHumanoid.WalkSpeed or 16
                StepFling(tRoot, CFrame.new(0, 2, walkSpeed * 2), CFrame.Angles(math.rad(90), 0, 0))
                task.wait()
                StepFling(tRoot, CFrame.new(0, -2, -walkSpeed * 2), CFrame.Angles(0, 0, 0))
                task.wait()
                StepFling(tRoot, CFrame.new(0, 2, walkSpeed * 2), CFrame.Angles(math.rad(90), 0, 0))
                task.wait()
                StepFling(tRoot, CFrame.new(0, 2, targetVel), CFrame.Angles(math.rad(90), 0, 0))
                task.wait()
                StepFling(tRoot, CFrame.new(0, -2, -targetVel), CFrame.Angles(0, 0, 0))
                task.wait()
                StepFling(tRoot, CFrame.new(0, 2, targetVel), CFrame.Angles(math.rad(90), 0, 0))
                task.wait()
                StepFling(tRoot, CFrame.new(0, -2, 0), CFrame.Angles(math.rad(90), 0, 0))
                task.wait()
                StepFling(tRoot, CFrame.new(0, -2, 0), CFrame.Angles(0, 0, 0))
                task.wait()
                StepFling(tRoot, CFrame.new(0, -2, 0), CFrame.Angles(math.rad(-90), 0, 0))
                task.wait()
                StepFling(tRoot, CFrame.new(0, -2, 0), CFrame.Angles(0, 0, 0))
                task.wait()
            end
        else
            root.AssemblyLinearVelocity = Vector3.new(9e9, 9e9, 9e9)
            root.AssemblyAngularVelocity = Vector3.new(1e12, 1e12, 1e12)

            if flingMode == "Super" then
                local rndOffset = Vector3.new(math.random(-0.5, 0.5), 0, math.random(-0.5, 0.5))
                root.CFrame = tRoot.CFrame * CFrame.new(rndOffset) * CFrame.Angles(math.rad(angle * 3), math.rad(angle), math.rad(angle * 2))
            elseif flingMode == "Orbit" then
                local orbitRadius = 2.5
                local rad = math.rad(angle)
                local offset = Vector3.new(math.cos(rad) * orbitRadius, math.sin(rad * 2), math.sin(rad) * orbitRadius)
                root.CFrame = CFrame.new(tRoot.Position + offset, tRoot.Position) * CFrame.Angles(math.rad(angle), 0, 0)
            elseif flingMode == "Skid" then
                local rndOffset = Vector3.new(math.random(-3, 3), math.random(-2, 2), math.random(-3, 3))
                root.CFrame = CFrame.new(tRoot.Position + rndOffset) * CFrame.Angles(math.rad(math.random(0, 360)), math.rad(math.random(0, 360)), 0)
            end
        end
    end)

    repeat
        task.wait()
    until not getgenv().FlingActive or not tRoot or not tRoot.Parent or (tHumanoid and tHumanoid.Health <= 0) or tick() - startTime > 3.0

    if connection then connection:Disconnect() end
    bv:Destroy()

    humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    workspace.CurrentCamera.CameraSubject = humanoid

    -- // Teleport back to original CFrame and clear residual velocity
    if root and char then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        char:PivotTo(oldPos)
        
        for _ = 1, 6 do
            root.CFrame = oldPos
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            RunService.RenderStepped:Wait()
        end
    end

    workspace.FallenPartsDestroyHeight = oldFPDH
    getgenv().FlingActive = false
end

-- // Cross-Platform Dragging Handler (PC + Mobile Support)
local function MakeDraggable(frame, dragHandle)
    local dragging = false
    local dragInput, dragStart, startPos

    dragHandle = dragHandle or frame

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- // Interface Build (c00lkidd Red / Black Aesthetic)
if CoreGui:FindFirstChild("c00lkidd_Fling_GUI") then
    CoreGui.c00lkidd_Fling_GUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "c00lkidd_Fling_GUI"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Parent = ScreenGui
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
Main.BorderColor3 = Color3.fromRGB(220, 0, 0)
Main.BorderSizePixel = 2
Main.Position = UDim2.new(0.35, 0, 0.15, 0)
Main.Size = UDim2.new(0, 340, 0, 480)
Main.Active = true

local Top = Instance.new("Frame")
Top.Name = "Top"
Top.Parent = Main
Top.BackgroundColor3 = Color3.fromRGB(25, 5, 5)
Top.BorderColor3 = Color3.fromRGB(180, 0, 0)
Top.BorderSizePixel = 1
Top.Size = UDim2.new(1, 0, 0, 32)

MakeDraggable(Main, Top)

local Title = Instance.new("TextLabel")
Title.Parent = Top
Title.BackgroundTransparency = 1
Title.Size = UDim2.new(1, -70, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.Font = Enum.Font.Code
Title.Text = "c00lkidd FLING GUI v3"
Title.TextColor3 = Color3.fromRGB(255, 30, 30)
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left

-- // Minimize / Open Toggle Button
local MiniToggleBtn = Instance.new("TextButton")
MiniToggleBtn.Name = "c00lkidd_OpenBtn"
MiniToggleBtn.Parent = ScreenGui
MiniToggleBtn.Size = UDim2.new(0, 130, 0, 32)
MiniToggleBtn.Position = UDim2.new(0.02, 0, 0.2, 0)
MiniToggleBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
MiniToggleBtn.BorderColor3 = Color3.fromRGB(220, 0, 0)
MiniToggleBtn.BorderSizePixel = 2
MiniToggleBtn.Font = Enum.Font.Code
MiniToggleBtn.Text = "c00lkidd [OPEN]"
MiniToggleBtn.TextColor3 = Color3.fromRGB(255, 30, 30)
MiniToggleBtn.TextSize = 13
MiniToggleBtn.Visible = false
MiniToggleBtn.Active = true

MakeDraggable(MiniToggleBtn, MiniToggleBtn)

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Parent = Top
MinimizeBtn.Size = UDim2.new(0, 32, 0, 32)
MinimizeBtn.Position = UDim2.new(1, -64, 0, 0)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
MinimizeBtn.BorderColor3 = Color3.fromRGB(180, 0, 0)
MinimizeBtn.BorderSizePixel = 1
MinimizeBtn.Font = Enum.Font.Code
MinimizeBtn.Text = "_"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.TextSize = 15

MinimizeBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    MiniToggleBtn.Visible = true
end)

MiniToggleBtn.MouseButton1Click:Connect(function()
    Main.Visible = true
    MiniToggleBtn.Visible = false
end)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = Top
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -32, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.BorderColor3 = Color3.fromRGB(255, 0, 0)
CloseBtn.BorderSizePixel = 1
CloseBtn.Font = Enum.Font.Code
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 15
CloseBtn.MouseButton1Click:Connect(function()
    ToggleRingParts(false)
    ToggleESP(false)
    ScreenGui:Destroy()
end)

local TextBox = Instance.new("TextBox")
TextBox.Parent = Main
TextBox.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
TextBox.BorderColor3 = Color3.fromRGB(150, 0, 0)
TextBox.BorderSizePixel = 1
TextBox.Position = UDim2.new(0.05, 0, 0.08, 0)
TextBox.Size = UDim2.new(0.9, 0, 0.07, 0)
TextBox.Font = Enum.Font.Code
TextBox.PlaceholderText = "[Target: User / Display / all / others]"
TextBox.PlaceholderColor3 = Color3.fromRGB(120, 50, 50)
TextBox.Text = ""
TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
TextBox.TextSize = 12

local function CreateBtn(text, pos, size, bgColor, textColor, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = Main
    btn.BackgroundColor3 = bgColor or Color3.fromRGB(25, 25, 30)
    btn.BorderColor3 = Color3.fromRGB(180, 0, 0)
    btn.BorderSizePixel = 1
    btn.Position = pos
    btn.Size = size
    btn.Font = Enum.Font.Code
    btn.Text = text
    btn.TextColor3 = textColor or Color3.fromRGB(255, 50, 50)
    btn.TextSize = 11
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- // Action Handlers
local function RunFlingBatch(mode)
    local targets = GetTargetPlayers(TextBox.Text)
    if #targets == 0 then return Notify("c00lkidd Error", "No targets found.", 3) end
    task.spawn(function()
        for _, plr in ipairs(targets) do
            ExecuteFling(plr, mode)
            task.wait(0.1)
        end
    end)
end

CreateBtn("IY Fling", UDim2.new(0.05, 0, 0.17, 0), UDim2.new(0.43, 0, 0.07, 0), nil, nil, function() RunFlingBatch("IY") end)
CreateBtn("Super Fling", UDim2.new(0.52, 0, 0.17, 0), UDim2.new(0.43, 0, 0.07, 0), nil, nil, function() RunFlingBatch("Super") end)
CreateBtn("Orbit Fling", UDim2.new(0.05, 0, 0.25, 0), UDim2.new(0.43, 0, 0.07, 0), nil, nil, function() RunFlingBatch("Orbit") end)
CreateBtn("Skid Fling", UDim2.new(0.52, 0, 0.25, 0), UDim2.new(0.43, 0, 0.07, 0), nil, nil, function() RunFlingBatch("Skid") end)

-- // Fling Nearest Action
CreateBtn("FLING NEAREST PLAYER", UDim2.new(0.05, 0, 0.33, 0), UDim2.new(0.9, 0, 0.07, 0), Color3.fromRGB(70, 0, 0), Color3.fromRGB(255, 200, 200), function()
    local target = GetNearestPlayer()
    if target then
        Notify("c00lkidd Fling", "Targeting Nearest: " .. target.DisplayName, 3)
        task.spawn(function()
            ExecuteFling(target, "Super")
        end)
    else
        Notify("c00lkidd Error", "No nearby player found.", 3)
    end
end)

CreateBtn("STOP ALL FLINGS", UDim2.new(0.05, 0, 0.41, 0), UDim2.new(0.9, 0, 0.07, 0), Color3.fromRGB(120, 0, 0), Color3.fromRGB(255, 255, 255), function()
    StopAllFlings()
end)

-- // Toggle Controls
local SpinBtn = CreateBtn("Toggle Spin (OFF)", UDim2.new(0.05, 0, 0.49, 0), UDim2.new(0.9, 0, 0.07, 0), nil, nil, function() end)
SpinBtn.MouseButton1Click:Connect(function()
    getgenv().Spinning = not getgenv().Spinning
    SpinBtn.Text = getgenv().Spinning and "Toggle Spin (ON)" or "Toggle Spin (OFF)"
    SpinBtn.TextColor3 = getgenv().Spinning and Color3.fromRGB(255, 220, 0) or Color3.fromRGB(255, 50, 50)

    task.spawn(function()
        while getgenv().Spinning do
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(50), 0)
            end
            RunService.RenderStepped:Wait()
        end
    end)
end)

local RingBtn = CreateBtn("Toggle Red Ring (OFF)", UDim2.new(0.05, 0, 0.57, 0), UDim2.new(0.9, 0, 0.07, 0), nil, nil, function() end)
RingBtn.MouseButton1Click:Connect(function()
    local newState = not getgenv().RingActive
    ToggleRingParts(newState)
    RingBtn.Text = newState and "Toggle Red Ring (ON)" or "Toggle Red Ring (OFF)"
    RingBtn.TextColor3 = newState and Color3.fromRGB(255, 220, 0) or Color3.fromRGB(255, 50, 50)
end)

local ESPBtn = CreateBtn("Toggle ESP (OFF)", UDim2.new(0.05, 0, 0.65, 0), UDim2.new(0.9, 0, 0.07, 0), nil, nil, function() end)
ESPBtn.MouseButton1Click:Connect(function()
    local newState = not getgenv().ESPActive
    ToggleESP(newState)
    ESPBtn.Text = newState and "Toggle ESP (ON)" or "Toggle ESP (OFF)"
    ESPBtn.TextColor3 = newState and Color3.fromRGB(255, 220, 0) or Color3.fromRGB(255, 50, 50)
end)

local AntiFallBtn = CreateBtn("NDS Anti-Fall (ON)", UDim2.new(0.05, 0, 0.73, 0), UDim2.new(0.9, 0, 0.07, 0), nil, Color3.fromRGB(255, 50, 50), function() end)
AntiFallBtn.MouseButton1Click:Connect(function()
    getgenv().AntiFallDamage = not getgenv().AntiFallDamage
    AntiFallBtn.Text = getgenv().AntiFallDamage and "NDS Anti-Fall (ON)" or "NDS Anti-Fall (OFF)"
    AntiFallBtn.TextColor3 = getgenv().AntiFallDamage and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(120, 120, 120)
end)

-- // External Loader Button
CreateBtn("LOAD INFINITE YIELD", UDim2.new(0.05, 0, 0.82, 0), UDim2.new(0.9, 0, 0.08, 0), Color3.fromRGB(40, 10, 10), Color3.fromRGB(255, 180, 0), function()
    Notify("c00lkidd Loader", "Executing Infinite Yield...", 3)
    task.spawn(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
    end)
end)

Notify("c00lkidd GUI", "System initialized successfully.", 3)
