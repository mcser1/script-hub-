-- Send notification
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Notice",
    Text = "Yup, it's useless.",
    Duration = 3
})

-- Reset character
local player = game:GetService("Players").LocalPlayer
if player and player.Character then
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Health = 0
    end
end

-- Script self-destructs after execution completes
