local player = game.Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local teleportKey = Enum.KeyCode.T
local teleportDistance = 35

-- 🔵 Marker setup
local marker = Instance.new("Part")
marker.Size = Vector3.new(1, 1, 1)
marker.Shape = Enum.PartType.Ball
marker.Material = Enum.Material.Neon
marker.Color = Color3.fromRGB(0, 255, 0)
marker.Anchored = true
marker.CanCollide = false
marker.Transparency = 0.3
marker.Parent = workspace

-- 🟠 Particle setup
local function createParticles(position)
    local p = Instance.new("ParticleEmitter")
    p.Texture = "rbxassetid://241876229" -- Spark particle
    p.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
    p.Size = NumberSequence.new(1)
    p.Lifetime = NumberRange.new(0.3)
    p.Rate = 200
    p.Speed = NumberRange.new(5)
    p.Rotation = NumberRange.new(0, 360)
    p.RotSpeed = NumberRange.new(-200, 200)

    local tempPart = Instance.new("Part")
    tempPart.Size = Vector3.new(1, 1, 1)
    tempPart.Anchored = true
    tempPart.CanCollide = false
    tempPart.Transparency = 1
    tempPart.CFrame = CFrame.new(position)
    tempPart.Parent = workspace

    p.Parent = tempPart

    -- Remove after effect finishes
    game.Debris:AddItem(tempPart, 1)
end

-- 🔄 Update marker position constantly
RunService.RenderStepped:Connect(function()
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = player.Character.HumanoidRootPart
        local targetPos = hrp.Position + (hrp.CFrame.LookVector * teleportDistance)
        marker.Position = targetPos
    end
end)

-- 🚀 Teleport on key press
UserInputService.InputBegan:Connect(function(input, isProcessed)
    if isProcessed then return end
    if input.KeyCode == teleportKey then
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            local startPos = hrp.Position
            local endPos = hrp.Position + (hrp.CFrame.LookVector * teleportDistance)

            -- Spawn particles at start and end
            createParticles(startPos)
            createParticles(endPos)

            -- Teleport
            hrp.CFrame = CFrame.new(endPos, hrp.Position + hrp.CFrame.LookVector)
        end
    end
end)
