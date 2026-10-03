-- // Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

-- // Cleanup Previous Instance
if CoreGui:FindFirstChild("c00lkidd_Fly_GUI") then
    CoreGui.c00lkidd_Fly_GUI:Destroy()
end

-- // Global Fly Settings
getgenv().Flying = false
getgenv().FlySpeed = 50
getgenv().Noclip = false
getgenv().UpPressed = false
getgenv().DownPressed = false

-- // Helper Functions
local function Notify(title, text, duration)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration or 3
    })
end

local function MakeDraggable(frame, dragHandle)
    local dragging, dragInput, dragStart, startPos
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

-- // Core Flying Logic
local bodyVel, bodyGyro
local renderConnection, noclipConnection

local function StartFlying()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then return end

    humanoid.PlatformStand = true

    bodyVel = Instance.new("BodyVelocity")
    bodyVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVel.Velocity = Vector3.zero
    bodyVel.Parent = root

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bodyGyro.P = 10000
    bodyGyro.CFrame = root.CFrame
    bodyGyro.Parent = root

    renderConnection = RunService.RenderStepped:Connect(function()
        if not getgenv().Flying or not root or not humanoid then
            if renderConnection then renderConnection:Disconnect() end
            return
        end

        local camera = workspace.CurrentCamera
        local moveDir = humanoid.MoveDirection
        local flyVel = Vector3.zero

        -- Forward / Directional Velocity
        if moveDir.Magnitude > 0 then
            flyVel = camera.CFrame:VectorToWorldSpace(camera.CFrame:VectorToObjectSpace(moveDir)) * getgenv().FlySpeed
        end

        -- Vertical Movements (E / Q keys or GUI Buttons)
        local verticalSpeed = getgenv().FlySpeed
        if UserInputService:IsKeyDown(Enum.KeyCode.E) or getgenv().UpPressed then
            flyVel = flyVel + Vector3.new(0, verticalSpeed, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Q) or getgenv().DownPressed then
            flyVel = flyVel - Vector3.new(0, verticalSpeed, 0)
        end

        bodyVel.Velocity = flyVel
        bodyGyro.CFrame = camera.CFrame
    end)

    -- Noclip Loop
    noclipConnection = RunService.Stepped:Connect(function()
        if getgenv().Flying and getgenv().Noclip and LocalPlayer.Character then
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
end

local function StopFlying()
    if renderConnection then renderConnection:Disconnect() end
    if noclipConnection then noclipConnection:Disconnect() end

    if bodyVel then bodyVel:Destroy() end
    if bodyGyro then bodyGyro:Destroy() end

    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
        end
    end
end

-- // UI Creation
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "c00lkidd_Fly_GUI"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Parent = ScreenGui
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
Main.BorderColor3 = Color3.fromRGB(220, 0, 0)
Main.BorderSizePixel = 2
Main.Position = UDim2.new(0.35, 0, 0.2, 0)
Main.Size = UDim2.new(0, 320, 0, 330)
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
Title.Text = "c00lkidd FLY V2"
Title.TextColor3 = Color3.fromRGB(255, 30, 30)
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Minimize Button
local OpenBtn = Instance.new("TextButton")
OpenBtn.Name = "OpenBtn"
OpenBtn.Parent = ScreenGui
OpenBtn.Size = UDim2.new(0, 110, 0, 32)
OpenBtn.Position = UDim2.new(0.02, 0, 0.25, 0)
OpenBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
OpenBtn.BorderColor3 = Color3.fromRGB(220, 0, 0)
OpenBtn.BorderSizePixel = 2
OpenBtn.Font = Enum.Font.Code
OpenBtn.Text = "FLY [OPEN]"
OpenBtn.TextColor3 = Color3.fromRGB(255, 30, 30)
OpenBtn.TextSize = 13
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
    getgenv().Flying = false
    StopFlying()
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
    btn.TextSize = 12
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Fly Toggle Button
local FlyBtn = CreateBtn("Toggle Fly (OFF)", UDim2.new(0.05, 0, 0.14, 0), UDim2.new(0.9, 0, 0.11, 0), nil, nil, function() end)
FlyBtn.MouseButton1Click:Connect(function()
    getgenv().Flying = not getgenv().Flying
    FlyBtn.Text = getgenv().Flying and "Toggle Fly (ON)" or "Toggle Fly (OFF)"
    FlyBtn.TextColor3 = getgenv().Flying and Color3.fromRGB(255, 220, 0) or Color3.fromRGB(255, 50, 50)
    
    if getgenv().Flying then
        StartFlying()
    else
        StopFlying()
    end
end)

-- Noclip Toggle Button
local NoclipBtn = CreateBtn("Toggle Noclip (OFF)", UDim2.new(0.05, 0, 0.28, 0), UDim2.new(0.9, 0, 0.11, 0), nil, nil, function() end)
NoclipBtn.MouseButton1Click:Connect(function()
    getgenv().Noclip = not getgenv().Noclip
    NoclipBtn.Text = getgenv().Noclip and "Toggle Noclip (ON)" or "Toggle Noclip (OFF)"
    NoclipBtn.TextColor3 = getgenv().Noclip and Color3.fromRGB(255, 220, 0) or Color3.fromRGB(255, 50, 50)
end)

-- Speed Controls
local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Parent = Main
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Position = UDim2.new(0.05, 0, 0.42, 0)
SpeedLabel.Size = UDim2.new(0.9, 0, 0.08, 0)
SpeedLabel.Font = Enum.Font.Code
SpeedLabel.Text = "Fly Speed: " .. tostring(getgenv().FlySpeed)
SpeedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedLabel.TextSize = 12

CreateBtn("-10 Speed", UDim2.new(0.05, 0, 0.52, 0), UDim2.new(0.43, 0, 0.1, 0), nil, nil, function()
    getgenv().FlySpeed = math.max(10, getgenv().FlySpeed - 10)
    SpeedLabel.Text = "Fly Speed: " .. tostring(getgenv().FlySpeed)
end)

CreateBtn("+10 Speed", UDim2.new(0.52, 0, 0.52, 0), UDim2.new(0.43, 0, 0.1, 0), nil, nil, function()
    getgenv().FlySpeed = math.min(300, getgenv().FlySpeed + 10)
    SpeedLabel.Text = "Fly Speed: " .. tostring(getgenv().FlySpeed)
end)

-- On-Screen Up & Down Controls (Great for Mobile Users)
local UpBtn = Instance.new("TextButton")
UpBtn.Parent = Main
UpBtn.BackgroundColor3 = Color3.fromRGB(35, 10, 10)
UpBtn.BorderColor3 = Color3.fromRGB(180, 0, 0)
UpBtn.BorderSizePixel = 1
UpBtn.Position = UDim2.new(0.05, 0, 0.66, 0)
UpBtn.Size = UDim2.new(0.43, 0, 0.13, 0)
UpBtn.Font = Enum.Font.Code
UpBtn.Text = "UP (E)"
UpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
UpBtn.TextSize = 13

UpBtn.MouseButton1Down:Connect(function() getgenv().UpPressed = true end)
UpBtn.MouseButton1Up:Connect(function() getgenv().UpPressed = false end)
UpBtn.TouchStarted:Connect(function() getgenv().UpPressed = true end)
UpBtn.TouchEnded:Connect(function() getgenv().UpPressed = false end)

local DownBtn = Instance.new("TextButton")
DownBtn.Parent = Main
DownBtn.BackgroundColor3 = Color3.fromRGB(35, 10, 10)
DownBtn.BorderColor3 = Color3.fromRGB(180, 0, 0)
DownBtn.BorderSizePixel = 1
DownBtn.Position = UDim2.new(0.52, 0, 0.66, 0)
DownBtn.Size = UDim2.new(0.43, 0, 0.13, 0)
DownBtn.Font = Enum.Font.Code
DownBtn.Text = "DOWN (Q)"
DownBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
DownBtn.TextSize = 13

DownBtn.MouseButton1Down:Connect(function() getgenv().DownPressed = true end)
DownBtn.MouseButton1Up:Connect(function() getgenv().DownPressed = false end)
DownBtn.TouchStarted:Connect(function() getgenv().DownPressed = true end)
DownBtn.TouchEnded:Connect(function() getgenv().DownPressed = false end)

-- Reset character when respawning
LocalPlayer.CharacterAdded:Connect(function()
    getgenv().Flying = false
    StopFlying()
    FlyBtn.Text = "Toggle Fly (OFF)"
    FlyBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
end)

Notify("c00lkidd Fly", "Loaded successfully!", 3)
