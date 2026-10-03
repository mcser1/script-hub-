-- // Services
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- // Screen Protection Target
local TargetParent = (gethui and gethui()) or CoreGui:FindFirstChild("RobloxGui") or LocalPlayer:WaitForChild("PlayerGui")

-- // Cleanup Previous Instance
if TargetParent:FindFirstChild("c00lkidd_TouchFling_GUI") then
    TargetParent.c00lkidd_TouchFling_GUI:Destroy()
end

-- // Global State
getgenv().TouchFlingEnabled = false

-- // Create GUI Elements
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "c00lkidd_TouchFling_GUI"
ScreenGui.Parent = TargetParent
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
MainFrame.BorderColor3 = Color3.fromRGB(220, 0, 0)
MainFrame.BorderSizePixel = 2
MainFrame.Position = UDim2.new(0.4, 0, 0.4, 0)
MainFrame.Size = UDim2.new(0, 220, 0, 130)
MainFrame.Active = true

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Parent = MainFrame
TopBar.BackgroundColor3 = Color3.fromRGB(25, 5, 5)
TopBar.BorderColor3 = Color3.fromRGB(180, 0, 0)
TopBar.BorderSizePixel = 1
TopBar.Size = UDim2.new(1, 0, 0, 28)

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Parent = TopBar
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 8, 0, 0)
Title.Size = UDim2.new(1, -38, 1, 0)
Title.Font = Enum.Font.Code
Title.Text = "c00lkidd TOUCH FLING"
Title.TextColor3 = Color3.fromRGB(255, 30, 30)
Title.TextSize = 12
Title.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Parent = TopBar
CloseBtn.Position = UDim2.new(1, -28, 0, 0)
CloseBtn.Size = UDim2.new(0, 28, 1, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseBtn.BorderSizePixel = 0
CloseBtn.Font = Enum.Font.Code
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 13

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Parent = MainFrame
ToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
ToggleBtn.BorderColor3 = Color3.fromRGB(180, 0, 0)
ToggleBtn.BorderSizePixel = 1
ToggleBtn.Position = UDim2.new(0.08, 0, 0.32, 0)
ToggleBtn.Size = UDim2.new(0.84, 0, 0.38, 0)
ToggleBtn.Font = Enum.Font.Code
ToggleBtn.Text = "FLING: [OFF]"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
ToggleBtn.TextSize = 13

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0.08, 0, 0.74, 0)
StatusLabel.Size = UDim2.new(0.84, 0, 0.2, 0)
StatusLabel.Font = Enum.Font.Code
StatusLabel.Text = "Status: Idle"
StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
StatusLabel.TextSize = 10

-- // Touch & PC Draggable Handler
local function MakeDraggable(frame, handle)
    local dragging, dragStart, startPos
    handle = handle or frame

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    conn:Disconnect()
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

MakeDraggable(MainFrame, TopBar)

-- // Fling Engine
local flingLoop
local function StartFling()
    if flingLoop then return end
    
    flingLoop = task.spawn(function()
        local movel = 0.1
        while getgenv().TouchFlingEnabled do
            RunService.Heartbeat:Wait()
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")

            if hrp then
                -- Modern Assembly Velocity handling
                local currentVel = hrp.AssemblyLinearVelocity
                
                -- High-impulse physics phase
                hrp.AssemblyLinearVelocity = currentVel * 10000 + Vector3.new(0, 10000, 0)
                RunService.RenderStepped:Wait()
                
                -- Restoration phase
                hrp.AssemblyLinearVelocity = currentVel
                RunService.Stepped:Wait()
                
                -- Micro-jitter phase to bypass anti-cheat checks
                hrp.AssemblyLinearVelocity = currentVel + Vector3.new(0, movel, 0)
                movel = -movel
            end
        end
        flingLoop = nil
    end)
end

local function StopFling()
    getgenv().TouchFlingEnabled = false
    if flingLoop then
        task.cancel(flingLoop)
        flingLoop = nil
    end
    
    -- Reset character velocity
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.zero
    end
end

-- // Button Connections
ToggleBtn.MouseButton1Click:Connect(function()
    getgenv().TouchFlingEnabled = not getgenv().TouchFlingEnabled
    
    if getgenv().TouchFlingEnabled then
        ToggleBtn.Text = "FLING: [ON]"
        ToggleBtn.TextColor3 = Color3.fromRGB(255, 220, 0)
        StatusLabel.Text = "Status: Active (Touch players)"
        StatusLabel.TextColor3 = Color3.fromRGB(50, 255, 50)
        StartFling()
    else
        ToggleBtn.Text = "FLING: [OFF]"
        ToggleBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
        StatusLabel.Text = "Status: Idle"
        StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        StopFling()
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    StopFling()
    ScreenGui:Destroy()
end)

-- // Respawn Cleanup
LocalPlayer.CharacterAdded:Connect(function()
    if getgenv().TouchFlingEnabled then
        StopFling()
        ToggleBtn.Text = "FLING: [OFF]"
        ToggleBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
        StatusLabel.Text = "Status: Idle"
        StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
end)
