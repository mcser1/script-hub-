-- // Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

-- // Cleanup Previous Instance
if CoreGui:FindFirstChild("c00lkidd_Aura_GUI") then
    CoreGui.c00lkidd_Aura_GUI:Destroy()
end

-- // Global Settings
getgenv().KillAura = false
getgenv().AuraRange = 25
getgenv().AuraCPS = 20
getgenv().TeamCheck = true
getgenv().AttackNPCs = false
getgenv().CheckFF = true
getgenv().AutoEquip = true
getgenv().ShowVisualizer = false
getgenv().RotateToTarget = false

-- // Internal Variables
local auraConnection
local rangeVisualizer
local lastAttack = 0

-- // Notifications
local function Notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 3
        })
    end)
end

-- // Draggable Helper
local function MakeDraggable(frame, dragHandle)
    local dragging, dragStart, startPos
    dragHandle = dragHandle or frame

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    connection:Disconnect()
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- // Get Equipped Tool & Handle
local function GetToolHandle()
    local char = LocalPlayer.Character
    if not char then return nil, nil end

    local tool = char:FindFirstChildOfClass("Tool")
    if not tool and getgenv().AutoEquip then
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
        if backpack then
            local backpackTool = backpack:FindFirstChildOfClass("Tool")
            if backpackTool then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid:EquipTool(backpackTool)
                    tool = backpackTool
                end
            end
        end
    end

    if tool then
        local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildOfClass("BasePart")
        return tool, handle
    end
    return nil, nil
end

-- // Visualizer Sphere
local function UpdateVisualizer(root)
    if getgenv().ShowVisualizer and getgenv().KillAura then
        if not rangeVisualizer or not rangeVisualizer.Parent then
            rangeVisualizer = Instance.new("Part")
            rangeVisualizer.Name = "c00lkidd_Visualizer"
            rangeVisualizer.Shape = Enum.PartType.Ball
            rangeVisualizer.Material = Enum.Material.ForceField
            rangeVisualizer.Color = Color3.fromRGB(220, 0, 0)
            rangeVisualizer.Transparency = 0.75
            rangeVisualizer.CanCollide = false
            rangeVisualizer.CanQuery = false
            rangeVisualizer.Anchored = true
            rangeVisualizer.Parent = workspace
        end
        local diameter = getgenv().AuraRange * 2
        rangeVisualizer.Size = Vector3.new(diameter, diameter, diameter)
        rangeVisualizer.CFrame = root.CFrame
    else
        if rangeVisualizer then
            rangeVisualizer:Destroy()
            rangeVisualizer = nil
        end
    end
end

-- // Safe Instant Touch Attack
local function AttackPart(handle, targetPart)
    if not handle or not targetPart then return end

    if firetouchinterest then
        firetouchinterest(handle, targetPart, 0)
        firetouchinterest(handle, targetPart, 1)
    else
        handle.CFrame = targetPart.CFrame
    end
end

-- // Optimized Target Collector
local function GetPotentialTargets()
    local targets = {}

    -- Collect Players
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            table.insert(targets, player.Character)
        end
    end

    -- Collect NPCs if enabled (Scans workspace children instead of GetDescendants)
    if getgenv().AttackNPCs then
        for _, child in ipairs(workspace:GetChildren()) do
            if child:IsA("Model") and child ~= LocalPlayer.Character and not Players:GetPlayerFromCharacter(child) then
                if child:FindFirstChildOfClass("Humanoid") then
                    table.insert(targets, child)
                end
            end
        end
    end

    return targets
end

-- // Core Loop Execution
local function StartAura()
    if auraConnection then auraConnection:Disconnect() end

    auraConnection = RunService.Heartbeat:Connect(function()
        if not getgenv().KillAura then return end

        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        UpdateVisualizer(root)

        local attackDelay = (getgenv().AuraCPS >= 100) and 0 or (1 / math.max(1, getgenv().AuraCPS))
        if os.clock() - lastAttack < attackDelay then return end

        local tool, handle = GetToolHandle()
        if not tool or not handle then return end

        local targets = GetPotentialTargets()

        for _, targetChar in ipairs(targets) do
            local targetHumanoid = targetChar:FindFirstChildOfClass("Humanoid")
            if targetHumanoid and targetHumanoid.Health > 0 then
                local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Torso") or targetChar:FindFirstChild("UpperTorso")

                if targetRoot then
                    local distance = (root.Position - targetRoot.Position).Magnitude
                    if distance <= getgenv().AuraRange then
                        local targetPlayer = Players:GetPlayerFromCharacter(targetChar)
                        local isAllowed = true

                        if targetPlayer then
                            if getgenv().TeamCheck and targetPlayer.Team ~= nil and targetPlayer.Team == LocalPlayer.Team then
                                isAllowed = false
                            end
                        end

                        if getgenv().CheckFF and targetChar:FindFirstChildOfClass("ForceField") then
                            isAllowed = false
                        end

                        if isAllowed then
                            if getgenv().RotateToTarget then
                                root.CFrame = CFrame.new(root.Position, Vector3.new(targetRoot.Position.X, root.Position.Y, targetRoot.Position.Z))
                            end

                            tool:Activate()
                            AttackPart(handle, targetRoot)

                            lastAttack = os.clock()
                            break -- Hit primary target per tick frame to prevent engine overload
                        end
                    end
                end
            end
        end
    end)
end

local function StopAura()
    if auraConnection then
        auraConnection:Disconnect()
        auraConnection = nil
    end
    if rangeVisualizer then
        rangeVisualizer:Destroy()
        rangeVisualizer = nil
    end
end

-- // UI Creation
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "c00lkidd_Aura_GUI"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Parent = ScreenGui
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
Main.BorderColor3 = Color3.fromRGB(220, 0, 0)
Main.BorderSizePixel = 2
Main.Position = UDim2.new(0.3, 0, 0.12, 0)
Main.Size = UDim2.new(0, 330, 0, 480)
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
Title.Position = UDim2.new(0, 10, 0, 0)
Title.Size = UDim2.new(1, -70, 1, 0)
Title.Font = Enum.Font.Code
Title.Text = "c00lkidd KILL AURA V2 [FIXED]"
Title.TextColor3 = Color3.fromRGB(255, 30, 30)
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Floating Open Button
local OpenBtn = Instance.new("TextButton")
OpenBtn.Name = "OpenBtn"
OpenBtn.Parent = ScreenGui
OpenBtn.Size = UDim2.new(0, 110, 0, 32)
OpenBtn.Position = UDim2.new(0.02, 0, 0.35, 0)
OpenBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
OpenBtn.BorderColor3 = Color3.fromRGB(220, 0, 0)
OpenBtn.BorderSizePixel = 2
OpenBtn.Font = Enum.Font.Code
OpenBtn.Text = "AURA [OPEN]"
OpenBtn.TextColor3 = Color3.fromRGB(255, 30, 30)
OpenBtn.TextSize = 12
OpenBtn.Visible = false

MakeDraggable(OpenBtn)

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Parent = Top
MinimizeBtn.Size = UDim2.new(0, 32, 0, 32)
MinimizeBtn.Position = UDim2.new(1, -64, 0, 0)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
MinimizeBtn.BorderColor3 = Color3.fromRGB(180, 0, 0)
MinimizeBtn.BorderSizePixel = 1
MinimizeBtn.Font = Enum.Font.Code
MinimizeBtn.Text = "_"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.TextSize = 15

MinimizeBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    OpenBtn.Visible = true
end)

OpenBtn.MouseButton1Click:Connect(function()
    Main.Visible = true
    OpenBtn.Visible = false
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
    getgenv().KillAura = false
    StopAura()
    ScreenGui:Destroy()
end)

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
    if callback then
        btn.MouseButton1Click:Connect(callback)
    end
    return btn
end

-- Main Toggle
local AuraBtn = CreateBtn("Toggle Aura (OFF) [K]", UDim2.new(0.05, 0, 0.08, 0), UDim2.new(0.9, 0, 0.07, 0))
AuraBtn.MouseButton1Click:Connect(function()
    getgenv().KillAura = not getgenv().KillAura
    AuraBtn.Text = getgenv().KillAura and "Toggle Aura (ON) [K]" or "Toggle Aura (OFF) [K]"
    AuraBtn.TextColor3 = getgenv().KillAura and Color3.fromRGB(255, 220, 0) or Color3.fromRGB(255, 50, 50)
    if getgenv().KillAura then StartAura() else StopAura() end
end)

-- Range Adjuster
local RangeLabel = Instance.new("TextLabel")
RangeLabel.Parent = Main
RangeLabel.BackgroundTransparency = 1
RangeLabel.Position = UDim2.new(0.05, 0, 0.16, 0)
RangeLabel.Size = UDim2.new(0.9, 0, 0.04, 0)
RangeLabel.Font = Enum.Font.Code
RangeLabel.Text = "Range: " .. tostring(getgenv().AuraRange) .. " Studs"
RangeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
RangeLabel.TextSize = 12

CreateBtn("-5 Range", UDim2.new(0.05, 0, 0.21, 0), UDim2.new(0.43, 0, 0.06, 0), nil, nil, function()
    getgenv().AuraRange = math.max(5, getgenv().AuraRange - 5)
    RangeLabel.Text = "Range: " .. tostring(getgenv().AuraRange) .. " Studs"
end)

CreateBtn("+5 Range", UDim2.new(0.52, 0, 0.21, 0), UDim2.new(0.43, 0, 0.06, 0), nil, nil, function()
    getgenv().AuraRange = math.min(150, getgenv().AuraRange + 5)
    RangeLabel.Text = "Range: " .. tostring(getgenv().AuraRange) .. " Studs"
end)

-- CPS Adjuster
local CPSLabel = Instance.new("TextLabel")
CPSLabel.Parent = Main
CPSLabel.BackgroundTransparency = 1
CPSLabel.Position = UDim2.new(0.05, 0, 0.28, 0)
CPSLabel.Size = UDim2.new(0.9, 0, 0.04, 0)
CPSLabel.Font = Enum.Font.Code
CPSLabel.Text = "CPS (Hit Speed): " .. tostring(getgenv().AuraCPS)
CPSLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
CPSLabel.TextSize = 12

CreateBtn("-5 CPS", UDim2.new(0.05, 0, 0.33, 0), UDim2.new(0.43, 0, 0.06, 0), nil, nil, function()
    getgenv().AuraCPS = math.max(1, getgenv().AuraCPS - 5)
    CPSLabel.Text = "CPS (Hit Speed): " .. tostring(getgenv().AuraCPS)
end)

CreateBtn("+5 CPS", UDim2.new(0.52, 0, 0.33, 0), UDim2.new(0.43, 0, 0.06, 0), nil, nil, function()
    getgenv().AuraCPS = math.min(100, getgenv().AuraCPS + 5)
    CPSLabel.Text = "CPS (Hit Speed): " .. tostring(getgenv().AuraCPS)
end)

-- Checks Toggles
local TeamBtn = CreateBtn("Team Check: ON", UDim2.new(0.05, 0, 0.41, 0), UDim2.new(0.43, 0, 0.07, 0), nil, Color3.fromRGB(255, 220, 0))
TeamBtn.MouseButton1Click:Connect(function()
    getgenv().TeamCheck = not getgenv().TeamCheck
    TeamBtn.Text = getgenv().TeamCheck and "Team Check: ON" or "Team Check: OFF"
    TeamBtn.TextColor3 = getgenv().TeamCheck and Color3.fromRGB(255, 220, 0) or Color3.fromRGB(255, 50, 50)
end)

local NPCBtn = CreateBtn("Target NPCs: OFF", UDim2.new(0.52, 0, 0.41, 0), UDim2.new(0.43, 0, 0.07, 0))
NPCBtn.MouseButton1Click:Connect(function()
    getgenv().AttackNPCs = not getgenv().AttackNPCs
    NPCBtn.Text = getgenv().AttackNPCs and "Target NPCs: ON" or "Target NPCs: OFF"
    NPCBtn.TextColor3 = getgenv().AttackNPCs and Color3.fromRGB(255, 220, 0) or Color3.fromRGB(255, 50, 50)
end)

local EquipBtn = CreateBtn("Auto Equip: ON", UDim2.new(0.05, 0, 0.49, 0), UDim2.new(0.43, 0, 0.07, 0), nil, Color3.fromRGB(255, 220, 0))
EquipBtn.MouseButton1Click:Connect(function()
    getgenv().AutoEquip = not getgenv().AutoEquip
    EquipBtn.Text = getgenv().AutoEquip and "Auto Equip: ON" or "Auto Equip: OFF"
    EquipBtn.TextColor3 = getgenv().AutoEquip and Color3.fromRGB(255, 220, 0) or Color3.fromRGB(255, 50, 50)
end)

local FFBtn = CreateBtn("Check FF: ON", UDim2.new(0.52, 0, 0.49, 0), UDim2.new(0.43, 0, 0.07, 0), nil, Color3.fromRGB(255, 220, 0))
FFBtn.MouseButton1Click:Connect(function()
    getgenv().CheckFF = not getgenv().CheckFF
    FFBtn.Text = getgenv().CheckFF and "Check FF: ON" or "Check FF: OFF"
    FFBtn.TextColor3 = getgenv().CheckFF and Color3.fromRGB(255, 220, 0) or Color3.fromRGB(255, 50, 50)
end)

local VisBtn = CreateBtn("Visual Sphere: OFF", UDim2.new(0.05, 0, 0.57, 0), UDim2.new(0.43, 0, 0.07, 0))
VisBtn.MouseButton1Click:Connect(function()
    getgenv().ShowVisualizer = not getgenv().ShowVisualizer
    VisBtn.Text = getgenv().ShowVisualizer and "Visual Sphere: ON" or "Visual Sphere: OFF"
    VisBtn.TextColor3 = getgenv().ShowVisualizer and Color3.fromRGB(255, 220, 0) or Color3.fromRGB(255, 50, 50)
end)

-- Target Rotation Toggle
local RotateBtn = CreateBtn("Face Target: OFF", UDim2.new(0.52, 0, 0.57, 0), UDim2.new(0.43, 0, 0.07, 0))
RotateBtn.MouseButton1Click:Connect(function()
    getgenv().RotateToTarget = not getgenv().RotateToTarget
    RotateBtn.Text = getgenv().RotateToTarget and "Face Target: ON" or "Face Target: OFF"
    RotateBtn.TextColor3 = getgenv().RotateToTarget and Color3.fromRGB(255, 220, 0) or Color3.fromRGB(255, 50, 50)
end)

-- Quick CPS Presets
CreateBtn("MAX CPS (100)", UDim2.new(0.05, 0, 0.66, 0), UDim2.new(0.43, 0, 0.07, 0), Color3.fromRGB(40, 10, 10), Color3.fromRGB(255, 150, 150), function()
    getgenv().AuraCPS = 100
    CPSLabel.Text = "CPS (Hit Speed): 100"
end)

CreateBtn("LEGIT CPS (15)", UDim2.new(0.52, 0, 0.66, 0), UDim2.new(0.43, 0, 0.07, 0), Color3.fromRGB(20, 20, 25), Color3.fromRGB(200, 200, 200), function()
    getgenv().AuraCPS = 15
    CPSLabel.Text = "CPS (Hit Speed): 15"
end)

-- PC Keybind Listener
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.K then
        getgenv().KillAura = not getgenv().KillAura
        AuraBtn.Text = getgenv().KillAura and "Toggle Aura (ON) [K]" or "Toggle Aura (OFF) [K]"
        AuraBtn.TextColor3 = getgenv().KillAura and Color3.fromRGB(255, 220, 0) or Color3.fromRGB(255, 50, 50)
        if getgenv().KillAura then StartAura() else StopAura() end
    end
end)

-- Character Respawn Handler
LocalPlayer.CharacterAdded:Connect(function()
    getgenv().KillAura = false
    StopAura()
    AuraBtn.Text = "Toggle Aura (OFF) [K]"
    AuraBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
end)

Notify("c00lkidd Kill Aura", "Loaded stably! Overhead scans eliminated.", 3)
