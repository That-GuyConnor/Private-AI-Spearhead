local debugMode = false

local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local tweenService = game:GetService("TweenService")
local runService = game:GetService("RunService")
local debris = game:GetService("Debris")
local httpService = game:GetService("HttpService")
local assets = replicatedStorage.SPH_Assets
local animations = assets.Animations
local modules = assets.Modules

local player = players.LocalPlayer

local config = require(assets.GameConfig)
local warnPrefix = "【 SPEARHEAD 】 "
warn(warnPrefix.."Loading Client "..config.version)
local hitFX = require(modules.HitFX)
local shellEjection = require(modules.ShellEjection)
local bulletHandler = require(modules.BulletHandler)

local bridgeNet = require(modules.BridgeNet)
local bodyAnimCommand = bridgeNet.CreateBridge("BodyAnimCommand")
local repFire = bridgeNet.CreateBridge("ReplicateFire")
local repSound = bridgeNet.CreateBridge("ReplicateSound")
local repHit = bridgeNet.CreateBridge("ReplicateHit")
local repBolt = bridgeNet.CreateBridge("ReplicateBolt")
local repCharSound = bridgeNet.CreateBridge("ReplicateCharacterSound")
local repToggleAttachment = bridgeNet.CreateBridge("ReplicateToggleAttachment")
local repMagGrab = bridgeNet.CreateBridge("ReplicateMagGrab")
local repLean = bridgeNet.CreateBridge("ReplicateLean")

local repHitMarker = bridgeNet.CreateBridge("ReplicateHitMarker") -- SPH_R15: Hitmarker Sound
local repBipodSound = bridgeNet.CreateBridge("ReplicateBipodSound") -- SPH_R15: Hitmarker Sound

local animLoadStorage = {}
local lasers = {}

local function AddRig(rig:Model, name:string)
	local newData = {
		animator = rig.AnimationController.Animator,
		LoadedAnimations = {}
	}
	animLoadStorage[name] = newData
end

local function FireBullet(player:Player, firePoint:CFrame, tracer:boolean, modTable) -- SPH_R15 Gunsmith: Added modtable to check for velocity and tracers and such
	local tool = player.Character:FindFirstChildWhichIsA("Tool")
	if tool and tool:FindFirstChild("SPH_Weapon") then
		local rig = player.Character.WeaponRig
		local gunModel = rig.Weapon:FindFirstChildWhichIsA("Model")
		local wepStats = require(tool.SPH_Weapon.WeaponStats)
		local muzzle = gunModel.Grip.Muzzle
		local gunAmmo = tool.Ammo

		-- Fire effects
		if modTable.muzzleChance then -- SPH_R15 Gunsmith: Added muzzlechance modification (if you want a suppressor to have no muzzle flash, set muzzleChance to 0 in that suppressor's AttModule)
			if modTable.IsSuppressor then
				bulletHandler.FireFX(player,gunModel,modTable.muzzleChance, true)
			else
				bulletHandler.FireFX(player,gunModel,modTable.muzzleChance, false)
			end
		else
			bulletHandler.FireFX(player,gunModel,wepStats.muzzleChance)
		end

		-- Fire bullet
		local muzzle = gunModel.Grip.Muzzle
		local bulletOrigin = muzzle.WorldCFrame.Position
		local bulletDirection = muzzle.WorldCFrame.LookVector
		-- SPH_R15 Gunsmith: Muzzle Velocity time
		local bv = wepStats.muzzleVelocity
		if modTable.muzzleVelocity then
			bv = modTable.muzzleVelocity
		end
		local bulletVelocity = (bulletDirection * bv * 3.5) -- 1 Meter = ~3.5 Studs (According to the dev forum)
		-- </SPH_R15>		

		--local bulletVelocity = (bulletDirection * wepStats.muzzleVelocity * 3.5) -- 1 Meter = ~3.5 Studs (According to the dev forum)

		-- SPH_R15 Gunsmith: Tracer Stuff
		local tracerColor = nil
		local tracers 	  = wepStats.tracers
		local timing	  = wepStats.tracerTiming
		local color		  = wepStats.tracerColor
		if modTable.tracers then
			tracers = modTable.tracers
			timing = modTable.tracerTiming
			color  = modTable.tracerColor
		end			
		if tracers and gunAmmo.MagAmmo.Value % timing == 0 then
			tracerColor = color
		end			
		-- </SPH_R15>
		--if wepStats.tracers and gunAmmo.MagAmmo.Value % wepStats.tracerTiming == 0 then
		--	tracerColor = wepStats.tracerColor
		--end
		if tracerColor == "Random" then -- SPH_R15: Rainbow Tracers
			tracerColor = Color3.fromRGB(math.random(0,255),math.random(0,255),math.random(0,255))
		end -- </SPH_R15>
		bulletHandler.FireBullet(rig,bulletOrigin,bulletDirection,bulletVelocity,tool,player,tracerColor,true, modTable) -- SPH_R15 Gunsmith: Added a ModTable to pass on information, if any, on effects to damage

		-- Shell ejection
		if wepStats.fireMode ~= "Manual" and wepStats.shellEject then
			shellEjection.ejectShell(player,tool,gunModel)
		end
	end 
end

-- Update character stuff
bodyAnimCommand:Connect(function(character:Model, angle)
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 or (not character:FindFirstChild("Torso") and not character:FindFirstChild("UpperTorso")) then return end

	-- Head movement
	local avatarType = character.Humanoid.RigType
	local joint
	if avatarType == Enum.HumanoidRigType.R6 then -- SPH_R15: Note that the Neck Motor6D is stored in different places depending on rig.
		joint = character.Torso.Neck
	else
		joint = character.Head.Neck
	end

	local receivedComponents = httpService:JSONDecode(angle)
	local newAngle = CFrame.new(unpack(receivedComponents))

	local moveSpeed = config.replicatedHeadRotationSpeed

	tweenService:Create(joint,TweenInfo.new(moveSpeed,Enum.EasingStyle.Quad),{C1 = newAngle}):Play()
end)

--repLean:Connect(function(character:Model, leanDirection)
--	-- Update leaning
--	local targetCFrame = CFrame.new(-leanDirection / 2,1,0) * CFrame.Angles(math.rad(90),math.rad(180) + math.rad(17 * leanDirection),0)
--	local baseJoint = character.HumanoidRootPart:FindFirstChild("RootJoint")
--	local lowerTorso = character:FindFirstChild("LowerTorso")

--	if baseJoint then
--		--R6
--		tweenService:Create(baseJoint,TweenInfo.new(0.5),{C1 = targetCFrame}):Play()
--	elseif lowerTorso then
--		local baseJointR15 = lowerTorso:FindFirstChild("Root")
--		if not baseJointR15 then return end
--		--R15
--		tweenService:Create(baseJointR15,TweenInfo.new(0.5),{C1 = targetCFrame}):Play()
--	end
--end)

repLean:Connect(function(character:Model, leanDirection)
	---- Update leaning
	--local targetCFrame = CFrame.new(-leanDirection / 2,1,0) * CFrame.Angles(math.rad(90),math.rad(180) + math.rad(17 * leanDirection),0)
	--local baseJoint = character.UpperTorso:FindFirstChild("Waist")
	--local lowerTorso = character:FindFirstChild("LowerTorso")

	--if baseJoint then
	--	--R6
	--	tweenService:Create(baseJoint,TweenInfo.new(0.5),{C1 = targetCFrame}):Play()
	--elseif lowerTorso then
	--	local baseJointR15 = lowerTorso:FindFirstChild("Root")
	--	if not baseJointR15 then return end
	--	--R15
	--	tweenService:Create(baseJointR15,TweenInfo.new(0.5),{C1 = targetCFrame}):Play()
	--end
	-- SPH_R15: New Leaning
	-- Update leaning
	
	local baseJoint = character.UpperTorso:FindFirstChild("Waist")
	local targetCFrame
	if baseJoint then
		targetCFrame = CFrame.new(baseJoint.C1.Position.X,baseJoint.C1.Position.Y,baseJoint.C1.Position.Z) * CFrame.Angles(math.rad(0),math.rad(0),math.rad(0) + math.rad(17 * leanDirection))
		--R6
		tweenService:Create(baseJoint,TweenInfo.new(0.5),{C1 = targetCFrame}):Play()
	end
	-- </SPH_R15>
end)

repFire:Connect(FireBullet)

repSound:Connect(function(player:Player, soundToPlay:Sound, dupeSound:boolean)
	if not dupeSound then
		soundToPlay:Play()
	else
		if not player.Character:FindFirstChild("Torso") or not player.Character:FindFirstChild("UpperTorso") then return end
		local newSound = soundToPlay:Clone()
		if not soundToPlay.Parent or not soundToPlay.Parent:IsA("BasePart") then
			newSound.Parent = player.Character.HumanoidRootPart
		end
		newSound.Parent = soundToPlay.Parent
		newSound:Play()
		--print(newSound.Name)
		local soundLength = newSound.TimeLength
		if soundLength < 1 then soundLength = 1 end
		debris:AddItem(newSound,soundLength)
	end
end)

repHit:Connect(function(tool:Tool, raycastResult:RaycastResult)
	local hitPart = raycastResult.Instance
	local bulletStats = require(tool.SPH_Weapon.WeaponStats)
	if raycastResult.Instance and bulletStats.projectile == "Bullet" then
		hitFX.HitEffect(raycastResult.Position,hitPart,raycastResult.Normal)
	end
end)

repBolt:Connect(function(player, wepStats, direction, magAmmo)
	local gunModel = player.Character.WeaponRig.Weapon:FindFirstChildWhichIsA("Model")
	bulletHandler.MoveBolt(gunModel,wepStats,direction,magAmmo)
end)

repCharSound:Connect(function(player, soundType)
	local humanoidRootPart = player.Character:WaitForChild("HumanoidRootPart")
	if humanoidRootPart then
		local soundList = assets.Sounds[soundType]:GetChildren()
		local newSound = soundList[math.random(#soundList)]:Clone()
		newSound.Parent = humanoidRootPart
		newSound:Play()
		debris:AddItem(newSound,newSound.TimeLength)
	end
end)

repToggleAttachment:Connect(function(attachment,toggle,character) -- SPH_R15 Gunsmith: Modified to support attachments
	if attachment.Name == "Flashlight" then
		attachment:FindFirstChildWhichIsA("Light").Enabled = toggle
	elseif attachment.Name == "Laser" then
		if toggle then -- Make new laser object
			local laserDot = Instance.new("Attachment",workspace.Terrain)
			laserDot.Name = "ReplicatedLaser"

			local laserDotUI = assets.HUD.LaserDotUI:Clone()
			laserDotUI.Enabled = true
			laserDotUI.Dot.ImageColor3 = attachment.Color.Value
			laserDotUI.Parent = laserDot

			local newLaser = {}
			newLaser.laserDot = laserDot
			newLaser.attachment = attachment
			newLaser.ignoreModel = character
			table.insert(lasers,newLaser)
		else
			for i, laserObject in ipairs(lasers) do
				if laserObject.attachment == attachment then
					laserObject.laserDot:Destroy()
					table.remove(lasers,i)
					break
				end
			end
		end
	elseif attachment.Name == "Bipod" then -- SPH_R15: toggling bipod
		local BipodTween = TweenInfo.new(0.01,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,false,0.025)
		if toggle then
			for _, child in pairs(attachment.Parent.Parent:GetChildren()) do
				if child.Name == "Bipod_Active" then
					tweenService:Create(child, BipodTween, {Transparency = 0}):Play()
				elseif child.Name == "Bipod_Reg" then
					tweenService:Create(child, BipodTween, {Transparency = 1}):Play()
				end
			end			
		else
			for _, child in pairs(attachment.Parent.Parent:GetChildren()) do
				if child.Name == "Bipod_Active" then
					tweenService:Create(child, BipodTween, {Transparency = 1}):Play()
				elseif child.Name == "Bipod_Reg" then
					tweenService:Create(child, BipodTween, {Transparency = 0}):Play()
				end
			end
		end
	end -- </SPH_R15>
end) -- </SPH_R15>

runService.RenderStepped:Connect(function()
	for i, laserObject in ipairs(lasers) do
		local laserPoint = laserObject.attachment
		if laserPoint and laserPoint.Parent then
			local laserRayParams = RaycastParams.new()
			laserRayParams.FilterType = Enum.RaycastFilterType.Exclude
			laserRayParams.FilterDescendantsInstances = {laserObject.ignoreModel}
			local laserDotPoint = laserObject.laserDot
			local rayResult = workspace:Raycast(laserPoint.WorldPosition, laserPoint.WorldCFrame.LookVector * 600, laserRayParams)
			if rayResult then
				laserObject.laserDot.LaserDotUI.Enabled = true
				laserDotPoint.WorldPosition = rayResult.Position
			else
				laserObject.laserDot.LaserDotUI.Enabled = false
			end
		else
			laserObject.laserDot:Destroy()
			table.remove(lasers,i)
		end
	end
end)

repMagGrab:Connect(function(magPart)
	if magPart then
		magPart.LocalTransparencyModifier = 0
		for _, part in ipairs(magPart:GetDescendants()) do
			if part:IsA("BasePart") then part.LocalTransparencyModifier = 0 end
		end
	end
end)

repHitMarker:Connect(function() -- SPH_R15: Hitmarker Sound
	local hitSounds = assets.Sounds.Hit:GetChildren()
	local newSound = hitSounds[math.random(#hitSounds)]:Clone()
	newSound.Parent = workspace
	newSound:Play()
	debris:AddItem(newSound,newSound.TimeLength)
end)

repBipodSound:Connect(function() -- SPH_R15: Bipod Deploy Sound
	local newSound = assets.Sounds.Bipod:Clone()
	newSound.Parent = workspace
	newSound:Play()
	debris:AddItem(newSound,newSound.TimeLength)
end)

warn(warnPrefix.."Main Client loaded successfully!")