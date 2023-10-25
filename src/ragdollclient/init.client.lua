local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local ragdollEvent = ReplicatedStorage.Ragdoll

local character = script.Parent
local humanoid : Humanoid = character:WaitForChild("Humanoid")
local camera = workspace.CurrentCamera

local isRagdolled = false

ragdollEvent.OnClientEvent:Connect(function(ragdolled)
    isRagdolled = ragdolled
    if ragdolled and character:FindFirstChild("Head") then
        camera.CameraSubject = character.Head
        -- humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false) --
        task.wait(.5)
            humanoid.PlatformStand = true
    else
        camera.CameraSubject = character.Humanoid
       humanoid.PlatformStand = false
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then
        return
    end
    if input.KeyCode == Enum.KeyCode.R then
        ragdollEvent:FireServer(not isRagdolled)
        isRagdolled = not isRagdolled
    end
end)