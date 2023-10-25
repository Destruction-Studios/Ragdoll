local Debris = game:GetService("Debris")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ragdollEvent = ReplicatedStorage.Ragdoll

local RagdollService = {}

local names = {
    "RagdollAttachment",
    "RagdollSocket",
    "RagdollCollider"
}

local socketProperties = {
    ["Neck"] = {-45, 45},
    ["Right Shoulder"] = {-30, 30},
    ["Left Shoulder"] = {-30, 30},
    ["Left Hip"] = {-20, 20},
    ["Right Hip"] = {-20, 20}
}

local COLLISION_GROUP_NAME = "RagdollColliders"
local ATTRIBUTE_NAME = "Ragdolled"

local MIN_ANGLE = -15
local MAX_ANGLE = 15

if not PhysicsService:IsCollisionGroupRegistered(COLLISION_GROUP_NAME) then
    PhysicsService:RegisterCollisionGroup(COLLISION_GROUP_NAME)
end

PhysicsService:CollisionGroupSetCollidable(COLLISION_GROUP_NAME, COLLISION_GROUP_NAME, false)

local function createCollider(part, player)
    if part.Name == "HumanoidRootPart" then
        return
    end
    local c = Instance.new("Part")
    c.Size = part.Size/1.5
    c.CFrame = part.CFrame
    c.Transparency = 1
    if player then
        c.CollisionGroup = COLLISION_GROUP_NAME
    end
    c.Name = names[3]
    local weld = Instance.new("Weld")
    weld.Part0 = c
    weld.Part1 = part
    weld.Parent = c
    c.Parent = part
end

function RagdollService:Ragdoll(model)
    --V remove later?
    if typeof(model) == "table" then --checking if the obj passed was a table
        for _,obj in model do
            RagdollService:Ragdoll(obj)--if it was we ragdoll each character/rig
        end
    end
    --^ 
    if typeof(model) ~= "Instance" or (typeof(model) == "Instance" and not model:IsA("Model")) then--make sure its a model
        return
    end

    if model:GetAttribute(ATTRIBUTE_NAME) then --an extra check
        return
    end

    local player = Players:GetPlayerFromCharacter(model) --gets the player from the rig/character
    if player then --if its a player then do stuff
        --client fire
        ragdollEvent:FireClient(player, true)
    end

    local folder = model:FindFirstChild("RagdollSockets") --finds the folder.

    if not folder then --checks if the folder exists for the BallSockets
       folder = Instance.new("Folder") --if not then we create one
       folder.Name = "RagdollSockets"
       folder.Parent = model
    end

    local humanoidRootPart = model:FindFirstChild("HumanoidRootPart") --gets the HumanoidRootPart
    local humanoid :Humanoid = model:FindFirstChildWhichIsA("Humanoid") --gets the Humanoid
    if not humanoid or not humanoidRootPart then --makes sure it has a Humanoid and a HumanoidRootPart
        return
    end

    humanoidRootPart.CanCollide = true
    humanoid.PlatformStand = true
    humanoid.AutoRotate = false
    -- ^ sets stuff

    for _, obj in model:GetDescendants() do
        if obj:IsA("Motor6D") and obj.Name ~= "RootJoint" then
            local a1 = Instance.new("Attachment")
            local a2 = Instance.new("Attachment")
            local socket = Instance.new("BallSocketConstraint")

            a1.CFrame = obj.C0
            a2.CFrame = obj.C1

            a1.Name = names[1]
            a2.Name = names[1]
            socket.Name = names[2]

            socket.Attachment0 = a1
            socket.Attachment1 = a2

            a1.Parent = obj.Part0
            a2.Parent = obj.Part1
            socket.Parent = folder

            socket.TwistLimitsEnabled = true
			socket.LimitsEnabled = true
            socket.MaxFrictionTorque = 10
            print(obj.Name)
            -- if player then --checks if its a player bc a player needs differant properties than a rig/NPC
            socket.TwistLowerAngle = socketProperties[obj.Name][1]
            socket.TwistUpperAngle = socketProperties[obj.Name][2]
            socket.UpperAngle = 0

            obj.Enabled = false
      elseif obj:IsA("BasePart") and not obj.Parent:IsA("Accessory") and obj.Name ~= names[3] then
            createCollider(obj, player) --creates a collider for the Part for a more accurate physics
            obj.CollisionGroup = COLLISION_GROUP_NAME --sets the collision group for part
        end
    end

    model:SetAttribute(ATTRIBUTE_NAME, true) --sets the Attribute
end

function RagdollService:UnRagdoll(model)
    -- V remove? probably not
    if typeof(model) == "table" then --checking if the obj passed was a table
        for _,obj in model do
            RagdollService:UnRagdoll(obj) --unragdolls the rig/character
        end
    end
    -- ^ remove?
    if typeof(model) ~= "Instance" or (typeof(model) == "Instance" and not model:IsA("Model"))  then --makes sure its a model
        return
    end
    local player = Players:GetPlayerFromCharacter(model) --gets the player
    if player then
        --client fire
        ragdollEvent:FireClient(player, false)
    end

    if not model:GetAttribute(ATTRIBUTE_NAME) then --an extra check
        return
    end

    --same stuff as before. 

    local humanoid :Humanoid = model:FindFirstChildWhichIsA("Humanoid")
    local humanoidRootPart = model:FindFirstChild("HumanoidRootPart")
    if not humanoid or not humanoidRootPart then
        return
    end

    for _, obj in model:GetDescendants() do
        if obj:IsA("Motor6D") then
           obj.Enabled = true --ReEnables the motor6D
         elseif table.find(names, obj.Name) then
            obj:Destroy() --if the object was create for the ragdoll then destroys it
         elseif obj:IsA("BasePart") then
            obj.CollisionGroup = "Default" --reseting the collision group
        end
    end

    model:SetAttribute(ATTRIBUTE_NAME, false)

    if player then
        -- task.wait(.035) --if it is a player then we wait a bit before we turn PlatformStand off so the character doesnt fling 
    end

    humanoidRootPart.CanCollide = false
    humanoid.AutoRotate = true
    humanoid.PlatformStand = false
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