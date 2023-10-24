local Debris = game:GetService("Debris")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ragdollEvent = ReplicatedStorage.Ragdoll

local RagdollService = {}

local names = {
    "RagdollAttachment",
    "RagdollSocket",
    "Collider"
}

local COLLISION_GROUP_NAME = "RagdollColliders"

if not PhysicsService:IsCollisionGroupRegistered(COLLISION_GROUP_NAME) then
    PhysicsService:RegisterCollisionGroup(COLLISION_GROUP_NAME)
end

PhysicsService:CollisionGroupSetCollidable(COLLISION_GROUP_NAME, COLLISION_GROUP_NAME, false)

local function createCollider(part)
    if part.Name == "HumanoidRootPart" then
        return
    end
    local c = Instance.new("Part")
    c.Size = part.Size/1.7
    c.CFrame = part.CFrame
    c.Transparency = .5
    c.CollisionGroup = COLLISION_GROUP_NAME
    c.Massless = true
    c.Name = names[3]
    local weld = Instance.new("Weld")
    weld.Part0 = c
    weld.Part1 = part
    weld.Parent = c
    c.Parent = part
end

function RagdollService:Ragdoll(model)
    local player = Players:GetPlayerFromCharacter(model)
    if player then
        --client fire
        ragdollEvent:FireClient(player, true)
    end

    local folder = model:FindFirstChild("RagdollSockets")

    if not folder then
       folder = Instance.new("Folder")
       folder.Name = "RagdollSockets"
       folder.Parent = model
    end

    local humanoidRootPart = model:FindFirstChild("HumanoidRootPart")
    local humanoid :Humanoid = model:FindFirstChildWhichIsA("Humanoid")
    if not humanoid or not humanoidRootPart then
        return
    end

    humanoidRootPart.CanCollide = true
    humanoid.PlatformStand = true
    humanoid.AutoRotate = false
    humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)

    

    for _, joint in model:GetDescendants() do
        if joint:IsA("Motor6D") then
            local a1 = Instance.new("Attachment")
            local a2 = Instance.new("Attachment")
            local socket = Instance.new("BallSocketConstraint")

            a1.CFrame = joint.C0
            a2.CFrame = joint.C1

            a1.Name = names[1]
            a2.Name = names[1]
            socket.Name = names[2]

            socket.Attachment0 = a1
            socket.Attachment1 = a2

            a1.Parent = joint.Part0
            a2.Parent = joint.Part1
            socket.Parent = folder

            socket.TwistLimitsEnabled = true
			socket.LimitsEnabled = true
            socket.MaxFrictionTorque = 10
            socket.TwistLowerAngle = -25
            socket.TwistUpperAngle = 25
            socket.UpperAngle = 0

            joint.Enabled = false
      elseif joint:IsA("BasePart") and not joint.Parent:IsA("Accessory") and joint.Name ~= names[3] then
            createCollider(joint)
            joint.CollisionGroup = COLLISION_GROUP_NAME
        end
    end

    model:SetAttribute("Ragdolled", true)

    --[[
    task.defer(function()
        repeat
            humanoid.PlatformStand = true
            task.wait(.1)
        until not model:GetAttribute("Ragdolled") or not model or not humanoid
    end)
    ]]

    RagdollService:Force(model, humanoidRootPart.CFrame.LookVector * 3.5)
end

function RagdollService:UnRagdoll(model)
    local player = Players:GetPlayerFromCharacter(model)
    if player then
        --client fire
        ragdollEvent:FireClient(player, false)
    end

    local humanoid :Humanoid = model:FindFirstChildWhichIsA("Humanoid")
    if not humanoid then
        return
    end

    model.HumanoidRootPart.CanCollide = false
    humanoid.PlatformStand = false
    humanoid.AutoRotate = true

    for _, obj in model:GetDescendants() do
        if obj:IsA("Motor6D") then
           obj.Enabled = true
         elseif table.find(names, obj.Name) then
            obj:Destroy()
        end
    end

    model:SetAttribute("Ragdolled", false)
end

local function onRagdollEvent(player:Player, value:boolean)
    if value then
       RagdollService:Ragdoll(player.Character) 
     else
        RagdollService:UnRagdoll(player.Character)
    end
end

function RagdollService:Force(model:Model, force)
    local humanoidRootPart = model:FindFirstChild("HumanoidRootPart")
    local rootAttachment = humanoidRootPart:FindFirstChild("RootAttachment")
    if not humanoidRootPart and not rootAttachment then
        return
    end
    local v = Instance.new("VectorForce")
    v.RelativeTo = Enum.ActuatorRelativeTo.World
    v.Name = "Force"
    v.Attachment0 = rootAttachment
    v.Force = force * 100
    v.Parent = humanoidRootPart
    Debris:AddItem(v, .35)
end

function RagdollService:Init()
    ragdollEvent.OnServerEvent:Connect(onRagdollEvent) 
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character:Model)
            character.Humanoid.StateChanged:Connect(function(old, new)
                character.Humanoid:SetAttribute("OldState", old)
                character.Humanoid:SetAttribute("NewState", new)
            end)
        end)
    end)
end

return RagdollService