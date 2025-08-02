local player = game.Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local mouse = player:GetMouse()

-- 🔀 Mode switching setup
local mode = "forward" -- starts in forward teleport mode
local switchKey = Enum.KeyCode.M -- "\" key
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

-- 🟠 Particle function
local function createParticles(position)
    local p = Instance.new("ParticleEmitter")
    p.Texture = "rbxassetid://241876229"
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
    game.Debris:AddItem(tempPart, 1)
end

-- 🔄 Marker updater (changes behavior depending on mode)
RunService.RenderStepped:Connect(function()
    if mode == "forward" then
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            local targetPos = hrp.Position + (hrp.CFrame.LookVector * teleportDistance)
            marker.Position = targetPos
        end
    else
        if mouse.Target then
            marker.Position = mouse.Hit.p + Vector3.new(0, 2, 0)
        end
    end
end)

-- 🚀 Teleport action (depends on mode)
local function doTeleport()
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    local hrp = char.HumanoidRootPart
    local startPos = hrp.Position
    local endPos

    if mode == "forward" then
        endPos = hrp.Position + (hrp.CFrame.LookVector * teleportDistance)
    else
        if not mouse.Target then return end
        endPos = mouse.Hit.p + Vector3.new(0, 3, 0)
    end

    createParticles(startPos)
    createParticles(endPos)

    hrp.CFrame = CFrame.new(endPos, endPos + hrp.CFrame.LookVector)
end

-- 🎛 Mode toggle (switch between forward & click teleport)
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == switchKey then
        if mode == "forward" then
            mode = "click"
            print("[Teleport Mode] Click teleport enabled")
        else
            mode = "forward"
            print("[Teleport Mode] Forward teleport enabled")
        end
    end
end)

-- 🎯 Teleport trigger
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end

    -- Forward mode → T key
    if mode == "forward" and input.KeyCode == Enum.KeyCode.T then
        doTeleport()
    end

    -- Click mode → Mouse Button 1
    if mode == "click" and input.UserInputType == Enum.UserInputType.MouseButton1 then
        doTeleport()
    end
end)

--------------------------------------------------------------------
-- 📦 ESP SYSTEM - Press P to toggle
--------------------------------------------------------------------
local ESPKey = Enum.KeyCode.P
local espEnabled = false
local espFolder = Instance.new("Folder", workspace)
espFolder.Name = "KivFLIPP_ESP"

local function createESP(character, playerName)
    if not character:FindFirstChild("HumanoidRootPart") then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "KivESP_Name"
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.AlwaysOnTop = true
    billboard.Adornee = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
    billboard.Parent = espFolder

    local nameLabel = Instance.new("TextLabel", billboard)
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = playerName
    nameLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextSize = 16

    local highlight = Instance.new("Highlight")
    highlight.Name = "KivESP_Outline"
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
    highlight.Parent = character

    return {billboard = billboard, highlight = highlight}
end

local function clearESP()
    for _, item in ipairs(espFolder:GetChildren()) do
        item:Destroy()
    end
    for _, plr in ipairs(game.Players:GetPlayers()) do
        if plr.Character and plr.Character:FindFirstChild("KivESP_Outline") then
            plr.Character:FindFirstChild("KivESP_Outline"):Destroy()
        end
    end
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == ESPKey then
        espEnabled = not espEnabled
        if espEnabled then
            clearESP()
            for _, plr in ipairs(game.Players:GetPlayers()) do
                if plr ~= player and plr.Character then
                    createESP(plr.Character, plr.Name)
                end
                plr.CharacterAdded:Connect(function(char)
                    if espEnabled then
                        task.wait(1)
                        createESP(char, plr.Name)
                    end
                end)
            end
        else
            clearESP()
        end
    end
end)
