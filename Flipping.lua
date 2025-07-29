local ver = "4.3"
local scriptname = "KivFLIPP"

local cooldown = 0
local markerUpdateInterval = 0.
local freezeEnabled = true
local freezeTime = 0.
local colliderHighlight = true

local FrontflipKey = Enum.KeyCode.Z
local BackflipKey = Enum.KeyCode.X

local ca = game:GetService("ContextActionService")
local player = game:GetService("Players").LocalPlayer
local h = 0.0174533
local scriptActive = true

local canFlip = true
local highlightBlocks = {}

local playerGui = player:WaitForChild("PlayerGui")

local screenGui = playerGui:FindFirstChild("FlipCooldownUI")
if not screenGui then
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FlipCooldownUI"
    screenGui.ResetOnSpawn = false  
    screenGui.Parent = playerGui

    local cooldownFrame = Instance.new("Frame", screenGui)
    cooldownFrame.Name = "CooldownFrame"
    cooldownFrame.Size = UDim2.new(0, 200, 0, 20)
    cooldownFrame.Position = UDim2.new(1, -210, 1, -40)
    cooldownFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    cooldownFrame.BorderSizePixel = 0

    local cooldownBar = Instance.new("Frame", cooldownFrame)
    cooldownBar.Name = "CooldownBar"
    cooldownBar.Size = UDim2.new(1, 0, 1, 0)
    cooldownBar.BackgroundColor3 = Color3.fromRGB(0, 200, 255)

    local cooldownText = Instance.new("TextLabel", cooldownFrame)
    cooldownText.Name = "CooldownText"
    cooldownText.Size = UDim2.new(1, 0, 1, 0)
    cooldownText.BackgroundTransparency = 1
    cooldownText.TextColor3 = Color3.new(1,1,1)
    cooldownText.Font = Enum.Font.SourceSansBold
    cooldownText.Text = "Ready"
    cooldownText.TextSize = 18

    local deleteButton = Instance.new("TextButton", screenGui)
    deleteButton.Name = "DeleteButton"
    deleteButton.Size = UDim2.new(0, 200, 0, 30)
    deleteButton.Position = UDim2.new(1, -210, 1, -75)
    deleteButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    deleteButton.TextColor3 = Color3.new(1, 1, 1)
    deleteButton.Font = Enum.Font.SourceSansBold
    deleteButton.Text = "DELETE SCRIPT ENTIRELY"
    deleteButton.TextSize = 16

    -- UPDATED DELETE BUTTON FUNCTION:
    deleteButton.MouseButton1Click:Connect(function()
        scriptActive = false
        canFlip = false  -- stop any future flips immediately

        -- Destroy any active BodyVelocity on the player to stop flips in progress
        local char = player.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, bv in ipairs(hrp:GetChildren()) do
                    if bv:IsA("BodyVelocity") then
                        bv:Destroy()
                    end
                end
            end
        end

        -- Step 1: Remove ESP things first
        if espFolder then
            for _, espItem in ipairs(espFolder:GetChildren()) do
                espItem:Destroy()
                task.wait(0.1)
            end
            espFolder:Destroy()
        end

        -- Step 2: Remove Highlight blocks
        for _, block in ipairs(highlightBlocks) do
            if block and block.Parent then 
                block:Destroy() 
                task.wait(0.1)
            end
        end
        highlightBlocks = {}

        -- Step 3: Remove landing marker
        if landingMarker then 
            landingMarker:Destroy() 
            task.wait(0.1)
        end

        -- Step 4: Remove UI elements except deleteButton
        for _, uiItem in ipairs(screenGui:GetChildren()) do
            if uiItem ~= deleteButton then
                uiItem:Destroy()
                task.wait(0.1)
            end
        end

        -- Step 5: Remove delete button itself
        deleteButton:Destroy()

        -- Step 6: Remove the ScreenGui itself
        if screenGui then
            screenGui:Destroy()
        end

        -- Step 7: Finally destroy this script
        task.wait(0.2)
        script:Destroy()
    end)
end

local cooldownFrame = screenGui:WaitForChild("CooldownFrame")
local cooldownBar = cooldownFrame:WaitForChild("CooldownBar")
local cooldownText = cooldownFrame:WaitForChild("CooldownText")

local function startCooldown()
	canFlip = false
	cooldownText.Text = "Cooldown"
	cooldownText.TextColor3 = Color3.fromRGB(255, 50, 50)
	for i = cooldown, 1, -1 do
		cooldownBar.Size = UDim2.new(i/cooldown, 0, 1, 0)
		wait(1)
	end
	cooldownBar.Size = UDim2.new(1, 0, 1, 0)
	cooldownText.Text = "Ready"
	cooldownText.TextColor3 = Color3.new(1,1,1)
	canFlip = true
end

local function freezeCharacterAfterFlip(humanoid)
    if not freezeEnabled then return end
	local oldWalk = humanoid.WalkSpeed
	local oldJump = humanoid.JumpPower
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	wait(freezeTime)
	humanoid.WalkSpeed = oldWalk
	humanoid.JumpPower = oldJump
end

local landingMarker = Instance.new("Part")
landingMarker.Shape = Enum.PartType.Ball
landingMarker.Size = Vector3.new(2, 2, 2)
landingMarker.Transparency = 0.5
landingMarker.Color = Color3.fromRGB(255, 0, 0)
landingMarker.Anchored = true
landingMarker.CanCollide = false
landingMarker.Material = Enum.Material.Neon
landingMarker.Parent = workspace

local markerLocked = false
local invert = false

task.spawn(function()
	while scriptActive do
		task.wait(markerUpdateInterval)
		if not scriptActive then break end
		if not markerLocked then
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local predictedPos = hrp.Position + hrp.CFrame.LookVector * 35
				local ignoreList = {landingMarker, char}
				local ray = Ray.new(predictedPos, Vector3.new(0, -200, 0))
				local hit, pos = workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
				if hit then
					landingMarker.CFrame = CFrame.new(Vector3.new(predictedPos.X, pos.Y + 1, predictedPos.Z))
				else
					landingMarker.CFrame = CFrame.new(predictedPos)
				end
			end
			invert = not invert
			if invert then
				landingMarker.Color = Color3.fromRGB(0, 255, 255)
			else
				landingMarker.Color = Color3.fromRGB(255, 0, 0)
			end
		end
	end
end)

if colliderHighlight then
	task.spawn(function()
		while scriptActive do
			task.wait(2)
			for _, obj in pairs(workspace:GetDescendants()) do
				if obj:IsA("BasePart") and obj.CanCollide and obj.Transparency > 0.5 then
					if not obj:FindFirstChild("ColliderHighlightBlock") then
						local block = Instance.new("Part")
						block.Name = "ColliderHighlightBlock"
						block.Anchored = true
						block.CanCollide = false
						block.Transparency = 0.5
						block.Color = Color3.fromRGB(255, 0, 0)
						block.Size = obj.Size + Vector3.new(0.2, 0.2, 0.2)
						block.CFrame = obj.CFrame
						block.Material = Enum.Material.ForceField
						block.Parent = workspace

						local tag = Instance.new("BoolValue")
						tag.Name = "ColliderHighlightBlock"
						tag.Parent = obj

						table.insert(highlightBlocks, block)

						task.spawn(function()
							while scriptActive and obj.Parent and block.Parent do
								task.wait(0.5)
								block.CFrame = obj.CFrame
							end
							if block.Parent then block:Destroy() end
						end)
					end
				end
			end
		end
	end)
end

local function performFlip(direction)
	local char = player.Character
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum and hrp then
		markerLocked = true  
		local landedConn
		landedConn = hum:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
			if hum.FloorMaterial ~= Enum.Material.Air then
				markerLocked = false
				landedConn:Disconnect()
			end
		end)
		hum:ChangeState("Jumping")
		hum.Sit = true
		local bv = Instance.new("BodyVelocity")
		bv.Velocity = hrp.CFrame.LookVector * direction * 50 + Vector3.new(0, 30, 0)
		bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		bv.P = 1250
		bv.Parent = hrp
		game:GetService("Debris"):AddItem(bv, 0.25)
		for i = 1, 360 do
			delay(i/720, function()
				hum.Sit = true
				if direction == 1 then
					hrp.CFrame = hrp.CFrame * CFrame.Angles(-h, 0, 0)
				else
					hrp.CFrame = hrp.CFrame * CFrame.Angles(h, 0, 0)
				end
			end)
		end
		wait(0.55)
		hum.Sit = false
		freezeCharacterAfterFlip(hum)
	end
end

function zeezyFrontflip(_, inp)
	if inp == Enum.UserInputState.Begin and canFlip then
		performFlip(1)
		startCooldown()
	end
end

function zeezyBackflip(_, inp)
	if inp == Enum.UserInputState.Begin and canFlip then
		performFlip(-1)
		startCooldown()
	end
end

ca:BindAction("zeezyFrontflip", zeezyFrontflip, false, FrontflipKey)
ca:BindAction("zeezyBackflip", zeezyBackflip, false, BackflipKey)

print(scriptname .. " " .. ver .. " loaded successfully")

local notifSound = Instance.new("Sound", workspace)
notifSound.PlaybackSpeed = 1.5
notifSound.Volume = 0.15
notifSound.SoundId = "rbxassetid://170765130"
notifSound.PlayOnRemove = true
notifSound:Destroy()

game.StarterGui:SetCore("SendNotification", {
	Title = "KivFLIPP",
	Text = "KivFLIPP loaded successfully!",
	Icon = "rbxassetid://505845268",
	Duration = 5,
	Button1 = "Okay"
})

--------------------------------------------------------------------
-- 📦 ESP SYSTEM - Press P to toggle
--------------------------------------------------------------------
local ESPKey = Enum.KeyCode.P
local espEnabled = false
local espFolder = Instance.new("Folder", workspace)
espFolder.Name = "KivFLIPP_ESP"

-- Function to create ESP for a character
local function createESP(character, playerName)
    if not character:FindFirstChild("HumanoidRootPart") then return end

    -- Billboard GUI for name
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

    -- Highlight outline
    local highlight = Instance.new("Highlight")
    highlight.Name = "KivESP_Outline"
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
    highlight.Parent = character

    return {billboard = billboard, highlight = highlight}
end

-- Function to remove ESP
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

-- Toggle ESP
game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
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
