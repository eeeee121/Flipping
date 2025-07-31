--// ESP Script Toggle with P
-- Put this in StarterPlayerScripts (LocalScript)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local espEnabled = false
local espFolder = Instance.new("Folder", game.CoreGui)
espFolder.Name = "ESP_Objects"

-- Function to create ESP for a character
local function createESP(character, player)
	if not character:FindFirstChild("HumanoidRootPart") then return end

	-- Highlight outline
	local highlight = Instance.new("Highlight")
	highlight.FillTransparency = 1
	highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
	highlight.OutlineTransparency = 0
	highlight.Adornee = character
	highlight.Parent = espFolder

	-- Billboard for DisplayName
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = character:FindFirstChild("Head")

	local nameLabel = Instance.new("TextLabel", billboard)
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = player.DisplayName
	nameLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.SourceSansBold

	character.AncestryChanged:Connect(function(_, parent)
		if not parent then
			highlight:Destroy()
			billboard:Destroy()
		end
	end)
end

-- Add ESP to all players except local player
local function addESP(player)
	if player == localPlayer then return end
	player.CharacterAdded:Connect(function(char)
		if espEnabled then
			task.wait(1) -- slight delay so character fully loads
			createESP(char, player)
		end
	end)
	if player.Character and espEnabled then
		createESP(player.Character, player)
	end
end

for _, player in ipairs(Players:GetPlayers()) do
	addESP(player)
end

Players.PlayerAdded:Connect(addESP)

-- Toggle ESP with P
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.P then
		espEnabled = not espEnabled
		if espEnabled then
			print("ESP Enabled")
			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= localPlayer and player.Character then
					createESP(player.Character, player)
				end
			end
		else
			print("ESP Disabled")
			espFolder:ClearAllChildren()
		end
	end
end)
