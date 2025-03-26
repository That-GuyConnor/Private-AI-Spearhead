-- Movement leaning
local players = game:GetService("Players")
local config = require(game:GetService("ReplicatedStorage").SPH_Assets.GameConfig)
local runService = game:GetService("RunService")
local c0Ref = CFrame.new(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0)

local MaxTiltAngle = config.maxLeanAngle

--local Tilt = CFrame.new()
if config.movementLeaning then

	local function UpdateCharacterTilt(character,Delta)
		local humanoid = character:FindFirstChild("Humanoid")
		if not humanoid or humanoid.Health <= 0 then return end

		if humanoid.RigType == Enum.HumanoidRigType.R15 then
			--R15 Mode
			local rootPart = character:FindFirstChild("LowerTorso")
			local rootJoint = rootPart and rootPart:FindFirstChild("Root")
			if not rootPart or not rootJoint then return end

			local MoveDirection = rootPart.CFrame:VectorToObjectSpace(humanoid.MoveDirection)
			local tilt = c0Ref:Inverse() * rootJoint.C0
			local target = CFrame.Angles(math.rad(-MoveDirection.Z) * MaxTiltAngle, math.rad(-MoveDirection.X) * MaxTiltAngle, 0)
			if humanoid.Sit or humanoid.Health <= 0 or script.DisableLean.Value then target = CFrame.new() end
			tilt = tilt:Lerp(target, 0.2 ^ (1 / (Delta * 60)))
			rootJoint.C0 = c0Ref * tilt
		else
			--R6 Mode
			local rootPart = character:FindFirstChild("HumanoidRootPart")
			local rootJoint = rootPart and rootPart:FindFirstChild("RootJoint")
			if not rootPart or not rootJoint then return end

			local MoveDirection = rootPart.CFrame:VectorToObjectSpace(humanoid.MoveDirection)
			local tilt = c0Ref:Inverse() * rootJoint.C0
			local target = CFrame.Angles(math.rad(-MoveDirection.Z) * MaxTiltAngle, math.rad(-MoveDirection.X) * MaxTiltAngle, 0)
			if humanoid.Sit or humanoid.Health <= 0 or script.DisableLean.Value then target = CFrame.new() end
			tilt = tilt:Lerp(target, 0.2 ^ (1 / (Delta * 60)))
			rootJoint.C0 = c0Ref * tilt
		end
	end

	runService.RenderStepped:Connect(function(Delta)

		UpdateCharacterTilt(players.LocalPlayer.Character,Delta)

		if config.replicateMovementLeaning then
			for _, player in ipairs(players:GetPlayers()) do
				if player ~= players.LocalPlayer and player.Character then
					UpdateCharacterTilt(player.Character,Delta)
				end
			end
		end
	end)
end