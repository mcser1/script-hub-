-- // Services
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

-- // Cleanup Previous Instance
if CoreGui:FindFirstChild("GameScriptLoader") then
    CoreGui.GameScriptLoader:Destroy()
end

-- // Helper Functions
local function Notify(title, text, duration)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration or 3
    })
end

local function LoadScript(url)
    Notify("Script Loader", "Executing script...", 2)
    
    -- Destroy loader UI upon use
    if CoreGui:FindFirstChild("GameScriptLoader") then
        CoreGui.GameScriptLoader:Destroy()
    end
    
    -- Execute script
    task.spawn(function()
        local success, err = pcall(function()
            loadstring(game:HttpGet(url))()
        end)
        if not success then
            Notify("Loader Error", "Failed to load script: " .. tostring(err), 5)
        end
    end)
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

-- // UI Creation
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GameScriptLoader"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Parent = ScreenGui
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
Main.BorderColor3 = Color3.fromRGB(220, 0, 0)
Main.BorderSizePixel = 2
Main.Position = UDim2.new(0.4, 0, 0.3, 0)
Main.Size = UDim2.new(0, 300, 0, 320)
Main.Active = true

local Top = Instance.new("Frame")
Top.Name = "Top"
Top.Parent = Main
Top.BackgroundColor3 = Color3.fromRGB(25, 10, 10)
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
Title.Text = "SCRIPT HUB LOADER"
Title.TextColor3 = Color3.fromRGB(255, 50, 50)
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Minimize Button
local OpenBtn = Instance.new("TextButton")
OpenBtn.Name = "OpenBtn"
OpenBtn.Parent = ScreenGui
OpenBtn.Size = UDim2.new(0, 100, 0, 30)
OpenBtn.Position = UDim2.new(0.02, 0, 0.2, 0)
OpenBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
OpenBtn.BorderColor3 = Color3.fromRGB(220, 0, 0)
OpenBtn.BorderSizePixel = 2
OpenBtn.Font = Enum.Font.Code
OpenBtn.Text = "[OPEN]"
OpenBtn.TextColor3 = Color3.fromRGB(255, 50, 50)
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

-- Close Button
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
    ScreenGui:Destroy()
end)

-- Container for buttons
local Container = Instance.new("ScrollingFrame")
Container.Parent = Main
Container.BackgroundTransparency = 1
Container.Position = UDim2.new(0, 10, 0, 42)
Container.Size = UDim2.new(1, -20, 1, -52)
Container.CanvasSize = UDim2.new(0, 0, 0, 0)
Container.ScrollBarThickness = 4

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = Container
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 8)

UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Container.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 10)
end)

-- Function to add game script buttons
local function CreateScriptButton(gameName, scriptUrl)
    local btn = Instance.new("TextButton")
    btn.Parent = Container
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
    btn.BorderColor3 = Color3.fromRGB(180, 0, 0)
    btn.BorderSizePixel = 1
    btn.Font = Enum.Font.Code
    btn.Text = gameName
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12

    btn.MouseButton1Click:Connect(function()
        LoadScript(scriptUrl)
    end)
end

-- // Add Game Buttons Here
CreateScriptButton("Fling Gui", "https://raw.githubusercontent.com/mcser1/script-hub-/refs/heads/main/nds.lua")
CreateScriptButton("Fly Gui", "https://raw.githubusercontent.com/mcser1/script-hub-/refs/heads/main/fly.lua")
CreateScriptButton("dropkick (NDS)", "https://raw.githubusercontent.com/mcser1/script-hub-/refs/heads/main/dropkick.lua")
CreateScriptButton("infiniteyield", "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source")
CreateScriptButton("Killaura", "https://raw.githubusercontent.com/mcser1/script-hub-/refs/heads/main/killaura.lua")
CreateScriptButton("walk fling", "https://raw.githubusercontent.com/mcser1/script-hub-/refs/heads/main/tuchfling.lua")
-- CreateScriptButton("Game Name 5", "https://raw.githubusercontent.com/.../script5.lua")
-- CreateScriptButton("Game Name 5", "https://raw.githubusercontent.com/.../script5.lua")
-- CreateScriptButton("Game Name 5", "https://raw.githubusercontent.com/.../script5.lua")
-- CreateScriptButton("Game Name 5", "https://raw.githubusercontent.com/.../script5.lua")
-- CreateScriptButton("Game Name 5", "https://raw.githubusercontent.com/.../script5.lua")
-- CreateScriptButton("Game Name 5", "https://raw.githubusercontent.com/.../script5.lua")
-- CreateScriptButton("Game Name 5", "https://raw.githubusercontent.com/.../script5.lua")
-- CreateScriptButton("Game Name 5", "https://raw.githubusercontent.com/.../script5.lua")
-- CreateScriptButton("Game Name 5", "https://raw.githubusercontent.com/.../script5.lua")
-- CreateScriptButton("Game Name 5", "https://raw.githubusercontent.com/.../script5.lua")
-- CreateScriptButton("Game Name 5", "https://raw.githubusercontent.com/.../script5.lua")
CreateScriptButton("Useless (DONT)", "https://raw.githubusercontent.com/mcser1/script-hub-/refs/heads/main/useless.lua")


Notify("Loader Loaded", "Select a game script to load.", 3)
