local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local player = Players.LocalPlayer

local function updateKitGiverVisibility()
	local character = player.Character or player.CharacterAdded:Wait()
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local equippedTool = character:FindFirstChildWhichIsA("Tool")

		-- Find all KitGiver ProximityPrompts using CollectionService
		for _, kitGiverPart in ipairs(CollectionService:GetTagged("KitGiver")) do
			local prompt = kitGiverPart:FindFirstChildWhichIsA("ProximityPrompt")
			if prompt then
				prompt.Enabled = not equippedTool  -- Enabled if NO tool is equipped
			end
		end
	end
end

-- Connect to CharacterAdded to handle initial character load and respawns
player.CharacterAdded:Connect(function(character)
	updateKitGiverVisibility() -- Initial check when character spawns
	local humanoid = character:WaitForChild("Humanoid") -- Use WaitForChild

	--Check for tools being added/removed from backpack.
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			updateKitGiverVisibility()
		end
	end)
	character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			updateKitGiverVisibility()
		end
	end)
end)

-- Initial check in case character already exists.
if player.Character then
	updateKitGiverVisibility()
end

-- Handle tag changes (in case a KitGiver is added/removed during the game)
CollectionService:GetInstanceAddedSignal("KitGiver"):Connect(updateKitGiverVisibility)
CollectionService:GetInstanceRemovedSignal("KitGiver"):Connect(updateKitGiverVisibility)