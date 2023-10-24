local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local ragdollEvent = ReplicatedStorage.Ragdoll

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local camera = workspace.CurrentCamera

local isRagdolled = false

ragdollEvent.OnClientEvent:Connect(function(ragdolled)
    if ragdolled and character:FindFirstChild("Head") then
        camera.CameraSubject = character.Head
        humanoid.PlatformStand = true
    else
        camera.CameraSubject = character.Humanoid
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if input.KeyCode == Enum.KeyCode.R then
        ragdollEvent:FireServer(not isRagdolled)
        isRagdolled = not isRagdolled
    end
end)