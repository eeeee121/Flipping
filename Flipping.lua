--[[ Info ]]--
local ver = "4.0"
local scriptname = "feFlip"

--[[ SETTINGS ]]--
local cooldown = 0                -- seconds between flips
local markerUpdateInterval = 0   -- how fast the marker updates
local freezeEnabled = false         -- freeze after flip?
local freezeTime = 0             -- seconds of freeze

--[[ Keybinds ]]--
local FrontflipKey = Enum.KeyCode.Z
local BackflipKey = Enum.KeyCode.X

--[[ Dependencies ]]--
local ca = game:GetService("ContextActionService")
local player = game:GetService("Players").LocalPlayer
local h = 0.0174533
local scriptActive = true

-- Cooldown state
local canFlip = true

-- UI setup
local playerGui = player:WaitForChild("PlayerGui")

-- Create UI if missing
local screenGui = playerGui:FindFirstChild("FlipCooldownUI")
if not screenGui then
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FlipCooldownUI"
    screenGui.ResetOnSpawn = false  
    screenGui.Parent = playerGui

    -- cooldown frame
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

    -- 🛑 Delete Script Button
    local deleteButton = Instance.new("TextButton", screenGui)
    deleteButton.Name = "DeleteButton"
    deleteButton.Size = UDim2.new(0, 200, 0, 30)
    deleteButton.Position = UDim2.new(1, -210, 1, -75)
    deleteButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    deleteButton.TextColor3 = Color3.new(1, 1, 1)
    deleteButton.Font = Enum.Font.SourceSansBold
    deleteButton.Text = "DELETE SCRIPT ENTIRELY"
    deleteButton.TextSize = 16
    deleteButton.MouseButton1Click:Connect(function()
        scriptActive = false
        if screenGui then screenGui:Destroy() end
        if landingMarker then landingMarker:Destroy() end
        script:Destroy()
    end)
end

-- Reference UI
local cooldownFrame = screenGui:WaitForChild("CooldownFrame")
local cooldownBar = cooldownFrame:WaitForChild("CooldownBar")
local cooldownText = cooldownFrame:WaitForChild("CooldownText")

-- Cooldown Function
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

-- Freeze AFTER flip (if enabled)
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

-- 🔴 Landing marker part
local landingMarker = Instance.new("Part")
landingMarker.Shape = Enum.PartType.Ball
landingMarker.Size = Vector3.new(2, 2, 2)
landingMarker.Transparency = 0.5
landingMarker.Color = Color3.fromRGB(255, 0, 0) -- start as red
landingMarker.Anchored = true
landingMarker.CanCollide = false
landingMarker.Material = Enum.Material.Neon
landingMarker.Parent = workspace

local markerLocked = false -- true only during flip
local invert = false       -- toggles marker color

-- 🔄 Update landing marker when NOT flipping
task.spawn(function()
	while scriptActive do
		task.wait(markerUpdateInterval)
		if not scriptActive then break end
		if not markerLocked then
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp then
				-- further prediction (35 studs ahead)
				local predictedPos = hrp.Position + hrp.CFrame.LookVector * 35
				
				-- Raycast ignoring the marker itself and player
				local ignoreList = {landingMarker, char}
				local ray = Ray.new(predictedPos, Vector3.new(0, -200, 0))
				local hit, pos = workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
				
				if hit then
					landingMarker.CFrame = CFrame.new(Vector3.new(predictedPos.X, pos.Y + 1, predictedPos.Z))
				else
					landingMarker.CFrame = CFrame.new(predictedPos)
				end
			end

			-- 🎨 Invert the marker's color each update
			invert = not invert
			if invert then
				landingMarker.Color = Color3.fromRGB(0, 255, 255) -- Cyan
			else
				landingMarker.Color = Color3.fromRGB(255, 0, 0)   -- Red
			end
		end
	end
end)

-- Core Flip Function
local function performFlip(direction)
	local char = player.Character
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")

	if hum and hrp then
		-- 🔒 Lock marker in place when flip starts
		markerLocked = true  

		-- 🏁 Unlock marker after landing
		local landedConn
		landedConn = hum:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
			if hum.FloorMaterial ~= Enum.Material.Air then
				markerLocked = false
				landedConn:Disconnect()
			end
		end)

		-- 🏃 Do flip movement
		hum:ChangeState("Jumping")
		hum.Sit = true

		local bv = Instance.new("BodyVelocity")
		bv.Velocity = hrp.CFrame.LookVector * direction * 50 + Vector3.new(0, 30, 0)
		bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		bv.P = 1250
		bv.Parent = hrp
		game:GetService("Debris"):AddItem(bv, 0.25)

		-- 🔄 Spin animation
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

-- Key Binds
function zeezyFrontflip(act, inp, obj)
	if inp == Enum.UserInputState.Begin and canFlip then
		performFlip(1)
		startCooldown()
	end
end

function zeezyBackflip(act, inp, obj)
	if inp == Enum.UserInputState.Begin and canFlip then
		performFlip(-1)
		startCooldown()
	end
end

ca:BindAction("zeezyFrontflip", zeezyFrontflip, false, FrontflipKey)
ca:BindAction("zeezyBackflip", zeezyBackflip, false, BackflipKey)

-- Notification
print(scriptname .. " " .. ver .. " loaded successfully")

local notifSound = Instance.new("Sound", workspace)
notifSound.PlaybackSpeed = 1.5
notifSound.Volume = 0.15
notifSound.SoundId = "rbxassetid://170765130"
notifSound.PlayOnRemove = true
notifSound:Destroy()

game.StarterGui:SetCore("SendNotification", {
	Title = "feFlip",
	Text = "feFlip loaded successfully!",
	Icon = "rbxassetid://505845268",
	Duration = 5,
	Button1 = "Okay"
})
