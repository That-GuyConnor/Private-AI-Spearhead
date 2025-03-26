local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local debris = game:GetService("Debris")
local players = game:GetService("Players")
local tweenService = game:GetService("TweenService")
local testService = game:GetService("TestService")
local httpService = game:GetService("HttpService")

local assets = replicatedStorage.SPH_Assets
local modules = assets.Modules
local animations = assets.Animations
local player = players.LocalPlayer

local character = script.Parent.Parent
local humanoid:Humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local rootJoint
local neckJoint
if humanoid.RigType == Enum.HumanoidRigType.R15 then
	neckJoint = character.Head.Neck
	rootJoint = character.LowerTorso.Root
else
	neckJoint = character.Torso.Neck
	rootJoint = humanoidRootPart:WaitForChild("RootJoint")
end
local camera = workspace.CurrentCamera
if camera:FindFirstChild("WeaponRig") then camera.WeaponRig:Destroy() end

local defaultFOV = camera.FieldOfView

local weldMod = require(modules.WeldMod)
local bridgeNet = require(modules.BridgeNet)
local viewMod = require(modules.ViewMod)
local springMod = require(modules.SpringModule)
local hitFX = require(modules.HitFX)
local shellEjection = require(modules.ShellEjection)
local bulletHandler = require(modules.BulletHandler)
local callbacks = require(assets.Mods)
bulletHandler.Initialize(player)

local config = require(assets.GameConfig)
local warnPrefix = "【 SPEARHEAD 】 "
humanoid.WalkSpeed = config.walkSpeed

local sphWorkspace = workspace:WaitForChild("SPH_Workspace")
local shellFolder = sphWorkspace:WaitForChild("Shells")

local rayParams = RaycastParams.new()
rayParams.IgnoreWater = true
rayParams.RespectCanCollide = true
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.FilterDescendantsInstances = {character,camera,shellFolder}

local swaySpring = springMod.new()
local moveSpring = springMod.new()
local recoilSpring = springMod.new()
local gunRecoilSpring = springMod.new()

local bodyAnimRequest = bridgeNet.CreateBridge("BodyAnimRequest")
local switchWeapon = bridgeNet.CreateBridge("SwitchWeapon")
local playerFire = bridgeNet.CreateBridge("PlayerFire")
local playSound = bridgeNet.CreateBridge("PlaySound")
local repReload = bridgeNet.CreateBridge("Reload")
--local bulletHit = bridgeNet.CreateBridge("BulletHit")
local repChamber = bridgeNet.CreateBridge("PlayerChamber")
local moveBolt = bridgeNet.CreateBridge("MoveBolt")
local switchFireMode = bridgeNet.CreateBridge("SwitchFireMode")
local playCharSound = bridgeNet.CreateBridge("PlayCharacterSound")
local playerDropGun = bridgeNet.CreateBridge("PlayerDropGun")
local playerToggleAttachment = bridgeNet.CreateBridge("PlayerToggleAttachment")
local repBoltOpen = bridgeNet.CreateBridge("RepBoltOpen")
local magGrab = bridgeNet.CreateBridge("MagGrab")
local playerLean = bridgeNet.CreateBridge("PlayerLean")

local fpThreshold = 0.6

local rollAngle = 0
local cameraRollAngle = 0
local targetWalkSpeed = config.walkSpeed
local tempWalkSpeed = targetWalkSpeed

local depthOfField = game.Lighting:FindFirstChild("SPH_DoF") or (config.blurEffects and Instance.new("DepthOfFieldEffect",game.Lighting))
if depthOfField then depthOfField.Name = "SPH_DoF" end

local holdingM1 = false
local cycled = true
local firstPerson = false
local equipping = false
local dead = false
local canFire = true
local viewmodelVisible = false
local blocked = false
local holdStance = 0
local holdAnim
local laserEnabled = false
local flashlightEnabled = false

-- SPH_R15: Gunsmith: Attachments
local AttModels     = assets.AttModels
local AttModules	= assets.AttModules
local SightData, BarrelData, UnderBarrelData, OtherData, AmmoData

local SightAtt		= nil
local BarrelAtt		= nil
local UnderBarrelAtt= nil
local OtherAtt		= nil
local AmmoAtt		= nil

local ModTable = require(modules.ModTable)

function resetMods()
	ModTable.aimFovMinMod		= 1
	ModTable.AimTimeMod			= 1 -- 1 = normal aim time, higher = faster, lower = slower

	ModTable.gunLengthMod	= 0
	ModTable.IsSuppressor	= false

	ModTable.EnableLaserAtt		= nil
	ModTable.EnableFlashlightAtt= nil
	ModTable.laserAtt			= nil
	ModTable.flashlightAtt		= nil
	ModTable.bipodAtt			= nil

	ModTable.isRangefinder	= nil --  SPH_R15: Rangefinder

	ModTable.recoilMod.vertical   = 1
	ModTable.recoilMod.horizontal = 1
	ModTable.recoilMod.camShake   = 1
	ModTable.recoilMod.damping 	  = 1
	ModTable.recoilMod.speed 	  = 1
	ModTable.recoilMod.aimReduction = 1

	ModTable.gunRecoilMod.vertical	= 1
	ModTable.gunRecoilMod.horizontal = 1
	ModTable.gunRecoilMod.damping		= 1
	ModTable.gunRecoilMod.speed		= 1
	ModTable.gunRecoilMod.punchMultiplier = 1

	ModTable.damage.Head	= 1
	ModTable.damage.Torso 	= 1
	ModTable.damage.Other 	= 1

	ModTable.fireRate 			= 1
	ModTable.muzzleChance 		= nil
	ModTable.muzzleVelocity 	= nil
	ModTable.bulletForce 		= nil
	ModTable.spread 			= 1
	ModTable.shotgun 			= nil 
	ModTable.shotgunPellets 	= nil

	ModTable.ammoType 			= nil
	ModTable.tracers			= nil
	ModTable.tracerTiming 		= nil
	ModTable.tracerColor 		= nil
	ModTable.magazineCapacity 	= nil
	ModTable.startAmmoPool 		= nil
	ModTable.maxAmmoPool 		= nil
	ModTable.reloadSpeedModifier = 1

end

function setMods(ModData, attachment)
	ModTable.aimFovMinMod				= ModTable.aimFovMinMod * ModData.aimFovMinMod
	ModTable.AimTimeMod					= ModTable.AimTimeMod * ModData.AimTimeMod

	ModTable.gunLengthMod				= ModTable.gunLengthMod + ModData.gunLength
	if ModData.IsSuppressor then		ModTable.IsSuppressor = ModData.IsSuppressor end

	if ModData.EnableLaser then			ModTable.EnableLaserAtt = ModData.EnableLaser			ModTable.laserAtt = attachment end
	if ModData.EnableFlashlight then	ModTable.EnableFlashlightAtt = ModData.EnableFlashlight ModTable.flashlightAtt = attachment end
	if ModData.IsBipod then				ModTable.bipodAtt = attachment end

	if ModData.isRangefinder then		ModTable.isRangefinder = ModData.isRangefinder end	--  SPH_R15: Rangefinder

	ModTable.recoilMod.vertical   		= ModTable.recoilMod.vertical * ModData.recoil.vertical
	ModTable.recoilMod.horizontal 		= ModTable.recoilMod.horizontal * ModData.recoil.horizontal
	ModTable.recoilMod.camShake   		= ModTable.recoilMod.camShake * ModData.recoil.camShake
	ModTable.recoilMod.damping 	  		= ModTable.recoilMod.damping * ModData.recoil.damping
	ModTable.recoilMod.speed 	  		= ModTable.recoilMod.speed * ModData.recoil.speed
	ModTable.recoilMod.aimReduction 	= ModTable.recoilMod.aimReduction * ModData.recoil.aimReduction

	ModTable.gunRecoilMod.vertical		= ModTable.gunRecoilMod.vertical * ModData.gunRecoil.vertical
	ModTable.gunRecoilMod.horizontal 	= ModTable.gunRecoilMod.horizontal * ModData.gunRecoil.horizontal
	ModTable.gunRecoilMod.damping		= ModTable.gunRecoilMod.damping * ModData.gunRecoil.damping
	ModTable.gunRecoilMod.speed			= ModTable.gunRecoilMod.speed * ModData.gunRecoil.speed
	ModTable.gunRecoilMod.punchMultiplier =ModTable.gunRecoilMod.punchMultiplier * ModData.gunRecoil.punchMultiplier

	ModTable.damage.Head				= ModTable.damage.Head * ModData.damage.Head
	ModTable.damage.Torso 				= ModTable.damage.Torso * ModData.damage.Torso
	ModTable.damage.Other 				= ModTable.damage.Other * ModData.damage.Other

	ModTable.spread 					= ModTable.spread * ModData.spread
	ModTable.fireRate					= ModTable.fireRate * ModData.fireRate

	if ModData.muzzleChance then ModTable.muzzleChance 					= ModData.muzzleChance end
	if ModData.muzzleVelocity then ModTable.muzzleVelocity 				= ModData.muzzleVelocity end
	if ModData.bulletForce then ModTable.bulletForce 					= ModData.bulletForce end
	if ModData.shotgun then ModTable.shotgun 							= ModData.shotgun end
	if ModData.shotgunPellets then ModTable.shotgunPellets				= ModData.shotgunPellets end

	if ModData.ammoType then ModTable.ammoType 							= ModData.ammoType 		end
	if ModData.tracers then ModTable.tracers							= ModData.tracers 		end
	if ModData.tracerTiming then ModTable.tracerTiming 					= ModData.tracerTiming 	end
	if ModData.tracerColor then ModTable.tracerColor 					= ModData.tracerColor 	end
	if ModData.magazineCapacity then ModTable.magazineCapacity 			= ModData.magazineCapacity end
	if ModData.startAmmoPool then ModTable.startAmmoPool 				= ModData.startAmmoPool end
	if ModData.maxAmmoPool then ModTable.maxAmmoPool 					= ModData.maxAmmoPool end

	ModTable.reloadSpeedModifier 		= ModTable.reloadSpeedModifier * ModData.reloadSpeedModifier
end

-- </SPH_R15>

-- SPH_R15: Bipods
local Bipod 		= false
local CanBipod 		= false
local bipodEnabled 	= false
local Ignore_Model = {character}

local BipodCF 		= CFrame.new()
-- </SPH_R15>

local emptyReload = false -- SPH_R15: Empty Reload


local vehicleSeated = false
local ejected = true
local cancelReload = false

local fireModes = {
	Safe = 0,
	Semi = 1,
	Auto = 2,
	Burst = 3,
	Manual = 4
}
local curFireMode
local bulletsCurrentlyFired = 0

local equipped, wepStats, sprinting, gunModel, gunAmmo, reloading, aiming, offset, freeLook, moving, falling -- SPH_R15: added falling
local freeLookOffset = CFrame.new()
local freeLookRotation = CFrame.new()
local aimingOffset = CFrame.new()
local aimTarget = CFrame.new()
local aimFOVTarget = camera.FieldOfView

local headRotationEventCooldown = 0

local pushbackOffset = 0

local hipRotation = Vector2.zero

local storageCFrame = CFrame.new(1000000,0,0) -- This is used for moving the viewmodel super far away.
-- Doing this to the viewmodel allows animations to be loaded, played, etc, while still having it out of view.

-- Preload movement animations
local stance = 0
local crouchIdleAnim:AnimationTrack = humanoid.Animator:LoadAnimation(assets.Animations.Crouch_Idle)
crouchIdleAnim.Looped = true
crouchIdleAnim.Priority = Enum.AnimationPriority.Idle

local crouchMoveAnim:AnimationTrack = humanoid.Animator:LoadAnimation(assets.Animations.Crouch_Move)
crouchMoveAnim.Looped = true
crouchMoveAnim.Priority = Enum.AnimationPriority.Movement

local proneIdleAnim:AnimationTrack = humanoid.Animator:LoadAnimation(assets.Animations.Prone_Idle)
proneIdleAnim.Looped = true
proneIdleAnim.Priority = Enum.AnimationPriority.Idle

local proneMoveAnim:AnimationTrack = humanoid.Animator:LoadAnimation(assets.Animations.Prone_Move)
proneMoveAnim.Looped = true
proneMoveAnim.Priority = Enum.AnimationPriority.Movement

---- SPH_R15: Walk and Sprint Cycles

local walkCycleAnim:AnimationTrack = humanoid.Animator:LoadAnimation(assets.Animations.Walk)
walkCycleAnim.Looped = true
walkCycleAnim.Priority = Enum.AnimationPriority.Movement

local sprintCycleAnim:AnimationTrack = humanoid.Animator:LoadAnimation(assets.Animations.Sprint)
sprintCycleAnim.Looped = true
sprintCycleAnim.Priority = Enum.AnimationPriority.Movement

local moveAnim = walkCycleAnim -- SPH_R15: Walk Cycle Animation!
-- </SPH_R15>
--local moveAnim

local loadedAnims = {}

local xHead, yHead, zHead
local cameraOffsetTarget = Vector3.zero

local defaultCameraMode = player.CameraMode

local sights = {}

local sightIndex = 1

local lean = 0
local cameraLeanRotation = 0
local aimSensitivity = 0
local proneViewmodelOffset = 0

local laserDotUI = assets.HUD.LaserDotUI:Clone()
local laserDotPoint = Instance.new("Attachment")
laserDotPoint.Parent = workspace.Terrain
laserDotUI.Enabled = false
laserDotUI.Parent = laserDotPoint
--laserDotUI.AlwaysOnTop = true

local laserBeamFP = Instance.new("Beam")
laserBeamFP.Attachment1 = laserDotPoint
laserBeamFP.LightInfluence = 0
laserBeamFP.Brightness = 3
laserBeamFP.Segments = 1
laserBeamFP.Width0 = 0.02
laserBeamFP.Width1 = 0.02
laserBeamFP.FaceCamera = true
laserBeamFP.Transparency = NumberSequence.new(0.5)
laserBeamFP.Name = "FirstPersonLaser"
laserBeamFP.Parent = laserDotPoint
laserBeamFP.Enabled = false

local laserBeamTP = laserBeamFP:Clone()
laserBeamTP.Name = "ThirdPersonLaser"
laserBeamTP.Parent = laserDotPoint
laserBeamTP.Enabled = false

-- Disable default death sound
if humanoidRootPart:FindFirstChild("Died") then
	humanoidRootPart.Died.Volume = 0
end

-- Unlock the camera if lock first person for guns is enabled
if config.lockFirstPerson then
	player.CameraMode = Enum.CameraMode.Classic
end

-- Create new viewmodel
rig = viewMod.RigModel(player)

-- Create fake arms
local armParts = {"LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand", "Left Arm", "Right Arm"}
local bodyparts = {}

for i = 1, #armParts do
	local charArm = character:FindFirstChild(armParts[i])
	local rigArm = rig:FindFirstChild(armParts[i])
	if not charArm or not rigArm then continue end

	rigArm.Color = character[armParts[i]].Color
	table.insert(bodyparts, rigArm)
end

for _, part in ipairs(rig:GetDescendants()) do
	if part.Name == "Skin" then
		if table.find(bodyparts, part.Parent.Name)~=nil then
			part.Color = character[part.Parent.Name].Color
		end
	end
end

-- Set up an animator
local vmHuman = Instance.new("Humanoid",rig)

vmHuman.RigType = player.Character:FindFirstChildOfClass("Humanoid").RigType -- SPH_R15: sets humanoid rigtype in rig to match player rigtype


for _, state in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
	if state == Enum.HumanoidStateType.None then continue end -- The 'None' state needs to be skipped because it cannot be disabled
	vmHuman:SetStateEnabled(state,false)
end

local vmAnimator = Instance.new("Animator",vmHuman)
local vmShirt = Instance.new("Shirt",rig)
local animBase = rig.AnimBase
animBase.CFrame = storageCFrame

rig.Parent = camera

local weaponRig = character:FindFirstChild("WeaponRig") or character:WaitForChild("WeaponRig")
local characterAnimator:Animator = weaponRig:WaitForChild("AnimationController").Animator

-- SPH_R15: Gunsmith: Attachments

function loadAttachment(weapon)
	if weapon ~= nil then
		--load sight Att
		if wepStats.SightAtt then
			if weapon:FindFirstChild("Node_Sight") ~= nil and wepStats.SightAtt and wepStats.SightAtt ~= "" then
				SightData =  require(AttModules[wepStats.SightAtt])
				SightAtt = AttModels[wepStats.SightAtt]:Clone()
				SightAtt.Parent = weapon
				SightAtt:SetPrimaryPartCFrame(weapon.Node_Sight.CFrame)
				weapon.AimPart.CFrame = SightAtt.AimPos.CFrame

				--if SightAtt:FindFirstChild("AimPos2") then
				--	-- still gotta implement this lol	
				--end

				if SightAtt:FindFirstChild("AimPos2") then -- does this sight have a secondary point of aim?
					-- still gotta implement this lol
					if weapon:FindFirstChild("AimPart2") then -- use what's already there
						weapon.AimPart2.CFrame = SightAtt.AimPos2.CFrame
					else -- make a new one
						local newAimPart = weapon.AimPart:Clone()
						newAimPart.Parent = weapon
						newAimPart.Name = "AimPart2"
						newAimPart.CFrame = SightAtt.AimPos2.CFrame
					end
				end

				if SightData.maxFOV then
					print(aimFOVTarget)
					if aimFOVTarget == wepStats.maxFOV or defaultFOV then
						aimFOVTarget = SightData.maxFOV -- SPH_R15: Zoom FOV by @EmeraldSTitanite
					end
				end

				if SightData.ADSEnabled then
					wepStats.ADSEnabled = SightData.ADSEnabled
				end

				setMods(SightData,wepStats.SightAtt)
				--if SightData.SightZoom > 0 then
				--	ModTable.ZoomValue = SightData.SightZoom
				--end
				--if SightData.SightZoom2 > 0 then
				--	ModTable.Zoom2Value = SightData.SightZoom2
				--end

				for index, key in pairs(weapon:GetChildren()) do
					if key.Name == "IS" then
						key.Transparency = 1
					end
					if key.Name == "ISF" then
						key.Transparency = 0
					end
					if key.Name == "RailMount" then
						key.Transparency = 0
					end	
				end
				weldMod.WeldModel(SightAtt,weapon.Node_Sight,false)

			end
		end
		--load Barrel Att
		if wepStats.BarrelAtt then
			if weapon:FindFirstChild("Node_Barrel") ~= nil and wepStats.BarrelAtt ~= "" then

				BarrelData =  require(AttModules[wepStats.BarrelAtt])

				BarrelAtt = AttModels[wepStats.BarrelAtt]:Clone()
				BarrelAtt.Parent = weapon
				BarrelAtt:SetPrimaryPartCFrame(weapon.Node_Barrel.CFrame)


				if BarrelAtt:FindFirstChild("BarrelPos") ~= nil then
					weapon.Grip.Muzzle.WorldCFrame = BarrelAtt.BarrelPos.CFrame
				end

				setMods(BarrelData,wepStats.BarrelAtt)

				weldMod.WeldModel(BarrelAtt,weapon.Node_Barrel,false)
			end
		end

		--load Under Barrel Att
		if wepStats.UnderBarrelAtt then
			if weapon:FindFirstChild("Node_UnderBarrel") ~= nil and wepStats.UnderBarrelAtt ~= "" then

				UnderBarrelData =  require(AttModules[wepStats.UnderBarrelAtt])

				UnderBarrelAtt = AttModels[wepStats.UnderBarrelAtt]:Clone()
				UnderBarrelAtt.Parent = weapon
				UnderBarrelAtt:SetPrimaryPartCFrame(weapon.Node_UnderBarrel.CFrame)


				setMods(UnderBarrelData,wepStats.UnderBarrelAtt)
				Bipod = UnderBarrelData.IsBipod

				weldMod.WeldModel(UnderBarrelAtt,weapon.Node_UnderBarrel,false)
			end
		end

		if wepStats.OtherAtt then
			if weapon:FindFirstChild("Node_Other") ~= nil and wepStats.OtherAtt ~= "" then

				OtherData =  require(AttModules[wepStats.OtherAtt])

				OtherAtt = AttModels[wepStats.OtherAtt]:Clone()
				OtherAtt.Parent = weapon
				OtherAtt:SetPrimaryPartCFrame(weapon.Node_Other.CFrame)


				setMods(OtherData,wepStats.OtherAtt)

				--if OtherData.InfraRed then
				--	IREnable = true
				--end

				weldMod.WeldModel(OtherAtt,weapon.Node_Other,false)
			end
		end

		if wepStats.AmmoAtt then
			if weapon:FindFirstChild("Node_Ammo") ~= nil and wepStats.AmmoAtt ~= "" then
				AmmoData =  require(AttModules[wepStats.AmmoAtt])

				weldMod.Weld(weapon.Mag,weapon.Node_Ammo)

				setMods(AmmoData,wepStats.AmmoAtt)

				--if OtherData.InfraRed then
				--	IREnable = true
				--end
				if AmmoData.ReplaceMag then
					weapon.Mag.Transparency = 1
					AmmoAtt = AttModels[wepStats.AmmoAtt]:Clone()
					AmmoAtt.Parent = weapon
					AmmoAtt:SetPrimaryPartCFrame(weapon.Node_Ammo.CFrame)
					weldMod.WeldModel(AmmoAtt,weapon.Node_Ammo,false)
				end
			end
		end
	end
end
-- </SPH_R15>

local function PlayRepSound(soundName)
	if not dead then
		local soundToPlay = gunModel.Grip:FindFirstChild(soundName)
		if soundToPlay and equipped then
			if firstPerson then
				soundToPlay:Play()
			else
				local soundToPlay = soundToPlay:Clone()
				soundToPlay.Parent = humanoidRootPart
				soundToPlay:Play()
				debris:AddItem(soundToPlay,soundToPlay.TimeLength)
			end
			playSound:Fire(soundName, firstPerson)
		end
	end
end

local function PlayCharSound(soundType)
	local soundFolder = assets.Sounds:FindFirstChild(soundType)
	if soundFolder then
		local soundList = soundFolder:GetChildren()
		local newSound = soundList[math.random(#soundList)]:Clone()
		newSound.Parent = humanoidRootPart
		newSound:Play()
		debris:AddItem(newSound,newSound.TimeLength)
		playCharSound:Fire(soundType)
	end
end

local function ChangeLean(newLean)
	if not config.canLean then return end -- Return if the player can't lean
	if newLean ~= lean then PlayCharSound("Lean") end
	lean = newLean
	playerLean:Fire(newLean)
end

local function MoveBolt(direction:CFrame,silent:boolean)
	bulletHandler.MoveBolt(gunModel,wepStats,direction,gunAmmo.MagAmmo.Value)
	bulletHandler.MoveBolt(weaponRig.Weapon:FindFirstChildWhichIsA("Model"),wepStats,direction,gunAmmo.MagAmmo.Value)
	if gunAmmo.MagAmmo.Value <= 0 and not silent then
		PlayRepSound("Empty")
	end
	moveBolt:Fire(wepStats,direction,gunAmmo.MagAmmo.Value)
end

local function ToggleADS(toggle)
	if wepStats and wepStats.ADSEnabled then
		local ADSTween
		local AT = wepStats.aimTime -- SPH_R15 Gunsmith: Added in modifications to aim time
		if AT then
			if ModTable.AimTimeMod then
				AT = ModTable.AimTimeMod
			end
			ADSTween = TweenInfo.new(AT / 20,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,false,AT / 20)
		else
			ADSTween = TweenInfo.new(0.2,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,false,0.2)
		end -- </SPH_R15>
		--if wepStats.aimTime then
		--	ADSTween = TweenInfo.new(wepStats.aimTime / 20,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,false,wepStats.aimTime / 20)
		--else
		--	ADSTween = TweenInfo.new(0.2,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,false,0.2)
		--end
		if not toggle then
			for _, child in pairs(gunModel:GetChildren()) do
				if child.Name == "REG" then
					tweenService:Create(child, ADSTween, {Transparency = 0}):Play()
				elseif child.Name == "ADS" then
					tweenService:Create(child, ADSTween, {Transparency = 1}):Play()
				end
			end
			if SightAtt then
				for _, child in pairs(gunModel[SightAtt.Name]:GetChildren()) do
					if child.Name == "REG" then
						tweenService:Create(child, ADSTween, {Transparency = 0}):Play()
					elseif child.Name == "ADS" then
						tweenService:Create(child, ADSTween, {Transparency = 1}):Play()
					end
				end				
			end
		elseif toggle then
			for _, child in pairs(gunModel:GetChildren()) do
				if child.Name == "REG" then
					tweenService:Create(child, ADSTween, {Transparency = 1}):Play()
				elseif child.Name == "ADS" then
					tweenService:Create(child, ADSTween, {Transparency = 0}):Play()
				end
			end
			if SightAtt then
				for _, child in pairs(gunModel[SightAtt.Name]:GetChildren()) do
					if child.Name == "REG" then
						tweenService:Create(child, ADSTween, {Transparency = 1}):Play()
					elseif child.Name == "ADS" then
						tweenService:Create(child, ADSTween, {Transparency = 0}):Play()
					end
				end				
			end
		end
	end
end

local function EjectShell()
	ejected = true
	if wepStats.shellEject then
		if firstPerson then
			shellEjection.ejectShell(player,equipped,gunModel)
		else
			shellEjection.ejectShell(player,equipped,weaponRig.Weapon:FindFirstChildWhichIsA("Model"))
		end
	end
end

local function GetThirdPersonGunModel()
	return weaponRig.Weapon:FindFirstChildWhichIsA("Model")
end

-- Stop an animation track that has already been loaded
local function StopAnimation(animName:string, transTime:number)
	if loadedAnims[animName] then
		if transTime then
			loadedAnims[animName]:Stop(transTime)
			loadedAnims[animName.."ThirdPerson"]:Stop(transTime)
		else
			loadedAnims[animName]:Stop()
			loadedAnims[animName.."ThirdPerson"]:Stop()
		end
	else
		--warn("Attempted to stop animation '".. animName.. "', animation has not been loaded.")
	end
end

local function SwitchFireMode()
	repeat
		curFireMode += 1
		if curFireMode > 4 then curFireMode = 0 break end
	until wepStats.fireSwitch[curFireMode]
	switchFireMode:Fire(curFireMode)
end

-- Play an animation or load it if it's not already
local function PlayAnimation(animName:string, parameters:table, animType:string, preload)	
	parameters = parameters or {}
	local animToPlay, tpAnim
	if loadedAnims[animName] then
		animToPlay = loadedAnims[animName]
		tpAnim = loadedAnims[animName.."ThirdPerson"]
	elseif animName and animations:FindFirstChild(animName) then
		local newAnim = vmAnimator:LoadAnimation(animations[animName])
		newAnim.Looped = parameters.looped or false
		newAnim.Priority = parameters.priority or Enum.AnimationPriority.Action
		loadedAnims[animName] = newAnim

		local thirdPersonAnim:AnimationTrack = characterAnimator:LoadAnimation(animations[animName])
		thirdPersonAnim.Looped = parameters.looped or false
		thirdPersonAnim.Priority = parameters.priority or Enum.AnimationPriority.Action
		loadedAnims[animName.."ThirdPerson"] = thirdPersonAnim

		-- Keyframe names
		newAnim.KeyframeReached:Connect(function(keyframeName)

			if gunModel.Grip:FindFirstChild(keyframeName) then
				PlayRepSound(keyframeName)
			end

			if keyframeName == "MagIn" then

				-- Auto chamber code
				--if equipped and not equipped.Chambered.Value and wepStats.autoChamber then
				if equipped and not equipped.Chambered.Value and wepStats.autoChamber and not emptyreload then -- SPH_R15: Empty Reload
					reloading = true
					local animNameToPlay
					if equipped.BoltReady.Value then
						animNameToPlay = wepStats.boltChamber
					else
						animNameToPlay = wepStats.boltClose
					end
					StopAnimation(animName,0.4)
					PlayAnimation(animNameToPlay,{priority = Enum.AnimationPriority.Action2,transSpeed = 0.05})
				end

				repReload:Fire()
				--reloading = false

				if wepStats.magType > 1 then
					newAnim.DidLoop:Once(function()
						StopAnimation(animName)
					end)
				end
			elseif keyframeName == "ShellInsert" then
				if cancelReload then
					newAnim.Looped = false
					newAnim.Stopped:Once(function()
						if not equipped then return end
						StopAnimation(newAnim.Name)
						if not equipped.BoltReady.Value then
							PlayAnimation(wepStats.boltClose,{priority = Enum.AnimationPriority.Action2})
						else
							reloading = false
						end
					end)
				elseif gunAmmo.MagAmmo.Value + 1 >= gunAmmo.MagAmmo.MaxValue then
					newAnim.DidLoop:Once(function()
						if not equipped then return end
						StopAnimation(newAnim.Name)
						if not equipped.BoltReady.Value then
							PlayAnimation(wepStats.boltClose,{priority = Enum.AnimationPriority.Action2})
						else
							reloading = false
						end
					end)
				end
				repReload:Fire()
			elseif keyframeName == "ClipInsertEnd" then
				local ammoNeeded = gunAmmo.MagAmmo.MaxValue - gunAmmo.MagAmmo.Value
				local clipSize = wepStats.clipSize or wepStats.magazineCapacity
				-- SPH_R15 Gunsmith: Respecting modded mag capacity
				if ModTable.magazineCapacity then
					clipSize = wepStats.clipSize or ModTable.magazineCapacity
				end
				-- </SPH_R15>

				if ammoNeeded > 0 then
					StopAnimation(newAnim.Name)
					if ammoNeeded >= clipSize then
						PlayAnimation(wepStats.clipReloadAnim,{looped = true,speed = wepStats.reloadSpeedModifier,priority = Enum.AnimationPriority.Action2,transSpeed = 0.17})
					else
						PlayAnimation(wepStats.reloadAnim,{speed = wepStats.reloadSpeedModifier,priority = Enum.AnimationPriority.Action2,transSpeed = 0.17},"Reload")
					end
				end

				--StopAnimation(newAnim.Name)
				--PlayAnimation(wepStats.reloadAnim,{speed = wepStats.reloadSpeedModifier,priority = Enum.AnimationPriority.Action2,transSpeed = 0.17},"Reload")
				--PlayAnimation(wepStats.clipReloadAnim,{looped = true,speed = wepStats.reloadSpeedModifier,priority = Enum.AnimationPriority.Action2,transSpeed = 0.17})
			elseif keyframeName == "ClipInsert" then
				repReload:Fire()
			elseif keyframeName == "SlideRelease" or keyframeName == "BoltClose" then
				repChamber:Fire()
				reloading = false
				emptyreload = false -- SPH_R15
				MoveBolt(CFrame.new(),true)
			elseif keyframeName == "SlidePull" and equipped.Chambered.Value then
				EjectShell()
			elseif keyframeName == "Equip" then
				equipping = false
				if firstPerson then viewmodelVisible = true end

				local projectile = gunModel:FindFirstChild(wepStats.projectile)
				if not equipped.Chambered.Value and projectile and wepStats.projectile ~= "Bullet" then
					projectile.LocalTransparencyModifier = 1
					for _, child in ipairs(projectile:GetDescendants()) do
						if child:IsA("BasePart") then
							child.LocalTransparencyModifier = 1
						end
					end
				end
			elseif keyframeName == "Switch" and not reloading then
				SwitchFireMode()
			elseif keyframeName == "MagGrab" then
				if gunModel and wepStats.projectile ~= "Bullet" and gunModel:FindFirstChild(wepStats.projectile) then
					local projectile = gunModel:FindFirstChild(wepStats.projectile)
					projectile.LocalTransparencyModifier = 0
					for _, child in ipairs(projectile:GetDescendants()) do
						if child:IsA("BasePart") then
							child.LocalTransparencyModifier = 0
						end
					end
					local thirdPersonGunModel = GetThirdPersonGunModel()
					local projectile = thirdPersonGunModel:FindFirstChild(wepStats.projectile)
					projectile.LocalTransparencyModifier = 0
					for _, child in ipairs(projectile:GetDescendants()) do
						if child:IsA("BasePart") then
							child.LocalTransparencyModifier = 0
						end
					end
					magGrab:Fire()
				end
			elseif keyframeName == "BoltOpen" then
				repBoltOpen:Fire()
				if not ejected then
					EjectShell()
				end
			end
		end)

		newAnim.Stopped:Connect(function()
			if animType == "Equip" then
				equipping = false
				if firstPerson then viewmodelVisible = true end
			elseif animType == "Reload" then
				reloading = false
				if wepStats and gunModel and gunModel:FindFirstChild(wepStats.projectile) and equipped.Chambered.Value then
					local projectile = gunModel:FindFirstChild(wepStats.projectile)
					projectile.LocalTransparencyModifier = 0
					for _, child in ipairs(projectile:GetDescendants()) do
						if child:IsA("BasePart") then
							child.LocalTransparencyModifier = 0
						end
					end
				end
			end
		end)

		--if string.find(animName, "Reload") and newAnim.Looped then
		--	newAnim.DidLoop:Connect(function()
		--		if 
		--	end)
		--end

		--repeat task.wait() until newAnim.Length > 0
		animToPlay = newAnim
		tpAnim = thirdPersonAnim
	end

	if animToPlay and not preload then
		animToPlay:Play(parameters.transSpeed or 0)
		animToPlay:AdjustSpeed(parameters.speed or 1)
		tpAnim:Play(parameters.transSpeed or 0)
		tpAnim:AdjustSpeed(parameters.speed or 1)
		return animToPlay
	end
end

local function ChangeHoldStance(newStance)
	if aiming then return end
	if holdStance == newStance and holdAnim then
		StopAnimation(holdAnim.Name, 0.3)
		holdAnim = nil
		holdStance = 0
	else
		holdStance = newStance

		if holdAnim then
			StopAnimation(holdAnim.Name, 0.3)
		end

		local animToPlay
		if holdStance == 1 and wepStats.holdUpAnim then
			animToPlay = wepStats.holdUpAnim
		elseif holdStance == 2 and wepStats.patrolAnim then
			animToPlay = wepStats.patrolAnim
		elseif holdStance == 3 and wepStats.holdDownAnim then
			animToPlay = wepStats.holdDownAnim
		end

		if animToPlay then
			holdAnim = PlayAnimation(animToPlay,{looped = true, priority = Enum.AnimationPriority.Action,transSpeed = 0.3})
			holdAnim:Play()
		elseif holdAnim then
			holdAnim = nil
		end
	end
end

local function ChamberAnim()
	local animNameToPlay
	if equipped.BoltReady.Value or curFireMode == fireModes.Manual then
		animNameToPlay = wepStats.boltChamber
	else
		animNameToPlay = wepStats.boltClose
	end

	if animNameToPlay then
		reloading = true
		ChangeHoldStance(0)

		local playingAnim:AnimationTrack = PlayAnimation(animNameToPlay,{priority = Enum.AnimationPriority.Action2,transSpeed = 0.05})
	end
end

local function IdleAnim()
	PlayAnimation(wepStats.idleAnim,{looped = true, priority = Enum.AnimationPriority.Idle})
end

local function EquipAnim()
	equipping = true
	PlayAnimation(wepStats.equipAnim,{priority = Enum.AnimationPriority.Action2},"Equip")
end

local function ReloadAnim()
	if not equipped then return end

	cancelReload = false

	ChangeHoldStance(0)
	reloading = true

	if wepStats.operationType == 3 or (wepStats.operationType == 2 and gunAmmo.MagAmmo.Value <= 0 and not equipped.Chambered.Value) then
		local boltOpenTrack = PlayAnimation(wepStats.boltOpen,{speed = wepStats.reloadSpeedModifier, priority = Enum.AnimationPriority.Action2, transSpeed = 0.17})
		if not boltOpenTrack then
			warn(warnPrefix.."To use operation type "..wepStats.operationType..", a 'boltOpen' animation is required.")
			reloading = false
			return
		end
		boltOpenTrack.Stopped:Once(function()
			if wepStats.magType == 3
				and (gunAmmo.MagAmmo.MaxValue - gunAmmo.MagAmmo.Value) >= (wepStats.clipSize or wepStats.magazineCapacity)
				and gunAmmo.ArcadeAmmoPool.Value >= (wepStats.clipSize or wepStats.magazineCapacity) then
				-- SPH_R15 Gunsmith: Respecting modified magazines
				if ModTable.magazineCapacity then
					if gunAmmo.ArcadeAmmoPool.Value >= (wepStats.clipSize or ModTable.magazineCapacity) then
						-- Clip insert
						local clipReloadTrack = PlayAnimation(wepStats.clipReloadAnim,{looped = true,speed = ModTable.reloadSpeedModifier,priority = Enum.AnimationPriority.Action2,transSpeed = 0.17})
					end
				else
					-- Clip insert
					local clipReloadTrack = PlayAnimation(wepStats.clipReloadAnim,{looped = true,speed = wepStats.reloadSpeedModifier,priority = Enum.AnimationPriority.Action2,transSpeed = 0.17})					
				end
				---- Clip insert
				--local clipReloadTrack = PlayAnimation(wepStats.clipReloadAnim,{looped = true,speed = wepStats.reloadSpeedModifier,priority = Enum.AnimationPriority.Action2,transSpeed = 0.17})

				--clipReloadTrack.Stopped:Once(function()
				--	if gunAmmo.MagAmmo.Value + 1 < gunAmmo.MagAmmo.MaxValue and gunAmmo.ArcadeAmmoPool.Value > 0 then
				--		ReloadAnim()
				--	end
				--end)
				--clipReloadTrack.Stopped:Connect(function()

				--end)
			else
				-- Bullet insert
				PlayAnimation(wepStats.reloadAnim,{speed = wepStats.reloadSpeedModifier,priority = Enum.AnimationPriority.Action2,transSpeed = 0.17},"Reload")
			end
		end)
	else
		-- SPH_R15: Empty Reload
		if wepStats.emptyReloadAnim then
			if gunAmmo.MagAmmo.Value == 0 and not equipped.Chambered.Value then
				emptyreload = true
				PlayAnimation(wepStats.emptyReloadAnim,{speed = wepStats.reloadSpeedModifier,priority = Enum.AnimationPriority.Action2, transSpeed = 0.17},"EmptyReload")
			else
				PlayAnimation(wepStats.reloadAnim,{speed = wepStats.reloadSpeedModifier,priority = Enum.AnimationPriority.Action2,transSpeed = 0.17},"Reload")
			end
		else
			PlayAnimation(wepStats.reloadAnim,{speed = wepStats.reloadSpeedModifier,priority = Enum.AnimationPriority.Action2,transSpeed = 0.17},"Reload")
		end
		-- </SPH_R15>
		--PlayAnimation(wepStats.reloadAnim,{speed = wepStats.reloadSpeedModifier,priority = Enum.AnimationPriority.Action2,transSpeed = 0.17},"Reload")
	end
end

-- Makes the viewmodel visible and refreshes its appearance
local function RefreshViewmodel()
	if firstPerson and not equipping then
		viewmodelVisible = true
	end

	local plrShirt = character:FindFirstChildWhichIsA("Shirt")
	if plrShirt then vmShirt.ShirtTemplate = plrShirt.ShirtTemplate end


	for i = 1, #bodyparts do
		bodyparts[i].Color = character[bodyparts[i].Name].Color
	end

	for _, part in ipairs(rig:GetDescendants()) do
		if part.Name == "Skin" then
			if table.find(bodyparts, part.Parent.Name)~=nil then
				part.Color = character[part.Parent.Name].Color
			end
		end
	end

	IdleAnim()

	if callbacks.onViewmodelRefresh then callbacks.onViewmodelRefresh(player,rig) end
end

-- Remove rig and reset head orientation
local function ResetHead()
	viewmodelVisible = false
end

local function GetSineOffset(addition:number)
	return math.sin(tick() * addition * 1.3) * 0.3
end

local function LerpNumber(number:number, target:number, speed:number)
	return number + (target-number) * speed
end

local function ToggleAiming(toggle)
	if toggle then
		ChangeHoldStance(0)
		aiming = true
		if wepStats.ADSEnabled and wepStats.ADSEnabled[sightIndex] then
			ToggleADS(true)
		else
			ToggleADS(false)
		end
		userInputService.MouseDeltaSensitivity = aimSensitivity
		PlayRepSound("AimUp")
		if not config.lockFirstPerson then
			player.CameraMode = Enum.CameraMode.LockFirstPerson
		end
	else
		aiming = false
		ToggleADS(false)
		userInputService.MouseDeltaSensitivity = 1
		PlayRepSound("AimDown")
		local aimOutTime
		if wepStats then
			aimOutTime = wepStats.aimTime / 2
			if ModTable.AimTimeMod then -- SPH_R15 Gunsmith
				aimOutTime = ModTable.AimTimeMod / 2
			end -- </SPH_R15>
		else
			aimOutTime = 0.3
		end
		tweenService:Create(camera,TweenInfo.new(aimOutTime),{FieldOfView = defaultFOV}):Play()
		if not config.lockFirstPerson then
			player.CameraMode = defaultCameraMode
		end
	end
end

humanoid.Died:Connect(function()
	dead = true
	switchWeapon:Fire()
	equipped = nil
	wepStats = nil
	userInputService.MouseIconEnabled = true
	ToggleAiming(false)
	viewmodelVisible = false
	animBase.CFrame = storageCFrame

	bodyAnimRequest:Destroy()
	repReload:Destroy()
	switchWeapon:Destroy()
	playerFire:Destroy()
	playSound:Destroy()
	--bulletHit:Destroy()
	repChamber:Destroy()
	moveBolt:Destroy()
	switchFireMode:Destroy()
	playCharSound:Destroy()
	playerDropGun:Destroy()
	playerToggleAttachment:Destroy()
	repBoltOpen:Destroy()
	magGrab:Destroy()
	playerLean:Destroy()

	if config.useDeathCameraSubject then
		repeat task.wait() until humanoid.Parent ~= character
		camera.CameraSubject = humanoid
	end

	if rig then rig:Destroy() end
end)

-- Update the viewmodel's CFrame
local function UpdateViewmodelPosition(dt:number)
	-- Move the viewmodel to the camera's CFrame position and add the gun's offset
	animBase.CFrame = CFrame.new((camera.CFrame * offset).Position)

	-- SPH_R15: Bipod TEST
	if bipodEnabled then
		animBase.CFrame *= BipodCF
	end

	-- Check if freelook is on and don't rotate the viewmodel if it is
	if not freeLook then
		animBase.CFrame *= camera.CFrame - camera.CFrame.Position
	else
		animBase.CFrame *= freeLookRotation
	end

	-- Move gunmodel up while prone
	if stance == 2 then
		proneViewmodelOffset = LerpNumber(proneViewmodelOffset,0.2,0.1)
	else
		proneViewmodelOffset = LerpNumber(proneViewmodelOffset,0,0.1)
	end
	animBase.CFrame *= CFrame.new(0,proneViewmodelOffset,0)

	-- Freelook recovery
	local freelookRecovery = 0.2
	freeLookOffset = freeLookOffset:Lerp(CFrame.new(),freelookRecovery * dt * 60)
	animBase.CFrame *= freeLookOffset:Inverse()

	-- Aiming
	local aimPart = gunModel:FindFirstChild("AimPart"..sightIndex) or gunModel.AimPart
	aimTarget = aimPart.CFrame:ToObjectSpace(camera.CFrame)
	-- SPH_R15 Gunsmith: Adjusting aimtime
	local AO = wepStats.AimTime
	if ModTable.AimTimeMod then
		AO = ModTable.AimTimeMod
	end
	if aiming then
		aimingOffset = aimingOffset:Lerp(aimTarget,(0.7 / AO) * 0.3 * dt * 60)
	else
		aimingOffset = aimingOffset:Lerp(CFrame.new(),(0.7 / AO) * 0.3 * dt * 60)
	end 
	--</SPH_R15>
	--if aiming then
	--	aimingOffset = aimingOffset:Lerp(aimTarget,(0.7 / wepStats.aimTime) * 0.3 * dt * 60)
	--else
	--	aimingOffset = aimingOffset:Lerp(CFrame.new(),(0.7 / wepStats.aimTime) * 0.3 * dt * 60)
	--end
	animBase.CFrame *= aimingOffset

	-- Check if gun is too close to a wall
	--local rayDistance = (animBase.CFrame.Position - gunModel.Grip.Muzzle.WorldCFrame.Position).Magnitude + 1
	local rayDistance = wepStats.gunLength
	--SPH_R15 Gunsmith: Added Gun Length
	if ModTable.gunLengthMod then
		rayDistance = wepStats.gunLength + ModTable.gunLengthMod
	end
	-- </SPH_R15>
	local originCFrame = firstPerson and animBase.CFrame or weaponRig.AnimBase.CFrame
	local newRay = workspace:Raycast(originCFrame.Position,originCFrame.LookVector * rayDistance,rayParams)
	if newRay then
		local distance = rayDistance - (animBase.CFrame.Position - newRay.Position).Magnitude
		if config.pushBackViewmodel and distance > 0 then
			local tempDist = distance
			if blocked then tempDist /= 2 end
			pushbackOffset = LerpNumber(pushbackOffset,tempDist,0.2 * 60 * dt)
		else
			pushbackOffset = LerpNumber(pushbackOffset,0,0.2 * 60 * dt)
		end

		if config.raiseGunAtWall then

			if distance >= wepStats.maxPushback then
				if not blocked then
					ChangeHoldStance(0)
					PlayAnimation(wepStats.holdUpAnim,{looped = true, priority = Enum.AnimationPriority.Action,transSpeed = 0.3})
					blocked = true
					if aiming then ToggleAiming(false) end
				end
			elseif blocked then
				StopAnimation(wepStats.holdUpAnim,0.3)
				blocked = false
				if userInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) and not aiming and firstPerson then
					ToggleAiming(true)
				end
			end
		end
	else
		if blocked then
			StopAnimation(wepStats.holdUpAnim,0.3)
		end
		blocked = false
		if userInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) and not aiming and firstPerson and not sprinting then
			ToggleAiming(true)
		end

		pushbackOffset = LerpNumber(pushbackOffset,0,0.2 * 60 * dt)
	end
	animBase.CFrame *= CFrame.new(0,0,pushbackOffset)

	-- Update strafing roll
	local relativeVelocity = humanoidRootPart.CFrame:VectorToObjectSpace(humanoidRootPart.Velocity)
	local targetRollAngle = 0
	if not aiming then targetRollAngle = math.clamp(-relativeVelocity.X, -20, 20) end
	if config.cameraTilting then targetRollAngle /= 2 end
	rollAngle = LerpNumber(rollAngle,targetRollAngle,0.07 * dt * 60)
	animBase.CFrame *= CFrame.Angles(0,0,math.rad(rollAngle))

	local mouseDelta = userInputService:GetMouseDelta()

	-- Update hipfire movement
	local tempHipRotation = hipRotation
	if config.hipfireMove and (not aiming or aiming and config.offCenterAiming) then
		local maxX = config.hipfireMoveX
		local maxY = config.hipfireMoveY
		if aiming then
			maxX /= 4
			maxY /= 4
		end
		local xRotation = math.clamp(tempHipRotation.X - mouseDelta.X * config.hipfireMoveSpeed * dt * 60,-maxX,maxX)
		local yRotation = math.clamp(tempHipRotation.Y - mouseDelta.Y * config.hipfireMoveSpeed * dt * 60,-maxY,maxY)
		tempHipRotation = Vector2.new(xRotation,yRotation)
		hipRotation = tempHipRotation
	else
		hipRotation = hipRotation:Lerp(Vector2.zero,0.3)
	end
	animBase.CFrame *= CFrame.Angles(math.rad(hipRotation.Y),math.rad(hipRotation.X),0)

	-- Update rotational sway
	swaySpring:shove(Vector3.new(-mouseDelta.X / 500, mouseDelta.Y / 200, 0))
	local updatedSway = swaySpring:update(dt)
	animBase.CFrame *= CFrame.new(updatedSway.X, updatedSway.Y, 0)

	-- Update breathing
	local tickTime = tick() * 0.15
	local tempDist = config.breathingDist
	if aiming then tempDist *= config.breathingAimMultiplier end
	animBase.CFrame *= CFrame.new(tempDist * math.sin(tickTime * config.breathingSpeed / 2), tempDist * math.sin(tickTime * config.breathingSpeed), 0)

	-- Update recoil
	local recoilStats = wepStats.recoil
	local gunRecoil = wepStats.gunRecoil
	local updatedRecoil = recoilSpring:update(dt)
	local updatedGunRecoil = gunRecoilSpring:update(dt)
	animBase.CFrame *= CFrame.Angles(math.rad(updatedGunRecoil.X), math.rad(updatedGunRecoil.Y), 0)
	animBase.CFrame *= CFrame.new(0,0,updatedGunRecoil.Z)
	camera.CFrame *= CFrame.Angles(math.rad(updatedRecoil.X),math.rad(updatedRecoil.Y),math.rad(updatedRecoil.Z))

	-- Viewmodel visibility
	if not viewmodelVisible then
		animBase.CFrame *= storageCFrame
	end
end

local function ChangeDoF(fInt,fDist,fRad,nInt)
	tweenService:Create(depthOfField,TweenInfo.new(0.2),{
		FarIntensity = fInt,
		FocusDistance = fDist,
		InFocusRadius = fRad,
		NearIntensity = nInt
	}):Play()
end

-- Toggle spring speed
local function ToggleSprint(toggle:boolean)
	sprinting = toggle
	-- SPH_R15: Sprint Animation
	if stance == 0 then
		if moveAnim then moveAnim:Stop(config.stanceChangeTime) end
		sprintCycleAnim:Stop(config.stanceChangeTime)
		moveAnim = walkCycleAnim
		if moving and not falling then moveAnim:Play(config.stanceChangeTime) end
	end
	-- </SPH_R15>
	if toggle then
		if aiming then ToggleAiming(false) end
		ChangeHoldStance(0)
		userInputService.MouseDeltaSensitivity = 1
		holdingM1 = false
		PlayAnimation(wepStats.sprintAnim,{looped = true, priority = Enum.AnimationPriority.Action, transSpeed = 0.2})

		if depthOfField then
			ChangeDoF(0,6,0,0.3)
		end
	elseif wepStats then
		StopAnimation(wepStats.sprintAnim,0.2)
		if depthOfField then
			ChangeDoF(0,0,0,0)
		end
	end
end

-- Update target walk speed
-- This function is here in case the speed needs to be modified for whatever reason
local function ChangeWalkSpeed(newSpeed)
	targetWalkSpeed = newSpeed
end

local baseCharacterHipHeight = player.Character:WaitForChild("Humanoid").HipHeight -- SPH_R15: Gets player's character's hipheight

local function ChangeStance(change)
	local number = stance + change

	-- Correct number if it's too low or too high
	if number < 0 then
		number = 0
	elseif number > 2 then
		number = 2
	end

	local preMove = false
	if moveAnim then
		preMove = moveAnim.IsPlaying
	end

	if number == 0 then -- Walking
		--script.Parent.MovementLeaning.DisableLean.Value = false
		if moveAnim then moveAnim:Stop(config.stanceChangeTime) end
		--moveAnim = nil
		-- SPH_R15: Walk Cycle Animation
		moveAnim = walkCycleAnim
		if moving then moveAnim:Play(config.stanceChangeTime) end
		-- </SPH_R15>
		crouchIdleAnim:Stop(config.stanceChangeTime)
		ChangeWalkSpeed(config.walkSpeed)
		tweenService:Create(humanoid,TweenInfo.new(config.stanceChangeTime),{HipHeight = (baseCharacterHipHeight)}):Play()
		PlayCharSound("Uncrouch")
	elseif number == 1 then -- Crouching
		--script.Parent.MovementLeaning.DisableLean.Value = false
		if moveAnim then moveAnim:Stop(config.stanceChangeTime) end
		moveAnim = crouchMoveAnim
		if moving then moveAnim:Play(config.stanceChangeTime) end
		proneIdleAnim:Stop(config.stanceChangeTime)
		crouchIdleAnim:Play(config.stanceChangeTime)
		ChangeWalkSpeed(config.crouchSpeed)
		tweenService:Create(humanoid,TweenInfo.new(config.stanceChangeTime),{HipHeight = (baseCharacterHipHeight)}):Play()
		if stance == 0 then
			PlayCharSound("Crouch")
		elseif stance == 2 then
			PlayCharSound("Unprone")
		end
	elseif number == 2 then -- Prone
		ChangeLean(0)
		--script.Parent.MovementLeaning.DisableLean.Value = true
		if moveAnim then moveAnim:Stop(config.stanceChangeTime) end
		moveAnim = proneMoveAnim
		crouchIdleAnim:Stop(config.stanceChangeTime)
		proneIdleAnim:Play(config.stanceChangeTime)
		ChangeWalkSpeed(config.proneSpeed)
		tweenService:Create(humanoid,TweenInfo.new(config.stanceChangeTime * 1.5),{HipHeight = (baseCharacterHipHeight * 0.5)}):Play()
		PlayCharSound("Prone")
	end

	if preMove and moveAnim then moveAnim:Play() end

	stance = number
end

local function Unequip(tool)
	animBase.CFrame = storageCFrame

	switchWeapon:Fire()
	if tool == equipped then
		equipped = nil
		wepStats = nil
	end
	userInputService.MouseIconEnabled = true
	ToggleAiming(false)
	viewmodelVisible = false

	-- Stop animations
	for _, track in ipairs(vmAnimator:GetPlayingAnimationTracks()) do
		track:Stop()
	end

	for _, track in ipairs(characterAnimator:GetPlayingAnimationTracks()) do
		track:Stop()
	end

	if config.lockFirstPerson then
		player.CameraMode = Enum.CameraMode.Classic
	end

	sights = {}

	freeLook = false
	freeLookOffset = freeLookRotation:ToObjectSpace(camera.CFrame)
	freeLookOffset = freeLookOffset - freeLookOffset.Position
	humanoid.AutoRotate = true

	if depthOfField then ChangeDoF(0,0,0,0) end

	holdStance = 0
	holdAnim = nil

	laserEnabled = false
	flashlightEnabled = false
	laserDotUI.Enabled = false

	laserBeamFP.Enabled = false
	laserBeamTP.Enabled = false

	BipodToggle(camera.WeaponRig,false) -- SPH_R15: Disabling bipod when unequipping
	Bipod = false -- SPH_R15 Bipod: Disables bipod on unequip

	-- SPH_R15 Gunsmith: Resets attachments for next gun
	SightAtt		= nil
	BarrelAtt		= nil
	UnderBarrelAtt	= nil
	OtherAtt		= nil
	AmmoAtt			= nil

	ModTable.laserAtt		= nil
	resetMods()
	-- </SPH_R15>
	player:SetAttribute("rangefinderActive",false) --  SPH_R15: Rangefinder
end

-- Equip function
character.ChildAdded:Connect(function(newChild)
	if newChild:FindFirstChild("SPH_Weapon") and not assets.WeaponModels:FindFirstChild(newChild.Name) then
		warn(warnPrefix.."No gun model could be found for '"..newChild.Name.."'")
		return
	end

	if newChild:FindFirstChild("SPH_Weapon") and not dead and (not humanoid.Sit or humanoid.Sit and not vehicleSeated) then
		-- Reset variables
		reloading = false
		userInputService.MouseIconEnabled = false
		hipRotation = Vector2.zero
		equipping = true
		blocked = false
		laserEnabled = false
		cycled = true

		switchWeapon:Fire(newChild)

		-- Setup new gun
		equipped = newChild
		wepStats = require(equipped.SPH_Weapon.WeaponStats)
		recoilSpring.Damping = wepStats.recoil.damping
		recoilSpring.Speed = wepStats.recoil.speed
		gunRecoilSpring.Damping = wepStats.gunRecoil.damping
		gunRecoilSpring.Speed = wepStats.gunRecoil.speed
		offset = wepStats.viewmodelOffset
		--aimFOVTarget = math.clamp(aimFOVTarget, wepStats.aimFovMin, defaultFOV)
		aimFOVTarget = wepStats.maxFOV or defaultFOV -- SPH_R15: Zoom FOV by @EmeraldSTitanite
		freeLookOffset = CFrame.new()
		aimSensitivity = wepStats.aimSpeed

		Bipod = wepStats.Bipod -- SPH_R15: Bipod enables if the weapon settings allow it

		if not wepStats.operationType then wepStats.operationType = 1 end

		if type(wepStats.operationType) == "string" then
			wepStats.operationType = 1
		end
		if not wepStats.magType then
			wepStats.magType = 1
		end

		-- Destroy old gun model
		local oldGun = rig.Weapon:FindFirstChildWhichIsA("Model")
		if oldGun then oldGun:Destroy() end

		-- New gun model
		local gun = assets.WeaponModels:FindFirstChild(newChild.Name)
		if not gun then warn(warnPrefix.."Could not find a gun model with the name: '".. newChild.Name.. "'!") return end
		gun = gun:Clone()
		--weldMod.AutoWeldModel(gun,gun.Grip,true)

		resetMods() -- SPH_R15 Gunsmith: Unload old gun attachments
		loadAttachment(gun) -- SPH_R15 Gunsmith: Load up gunsmith attachments

		weldMod.WeldModel(gun,gun.Grip,false)


		for _, partName in ipairs(wepStats.rigParts) do
			if gun:FindFirstChild(partName) then
				gun.Grip["Grip_"..partName]:Destroy()
				local newMotor = weldMod.M6D(gun.Grip,gun[partName])
				newMotor.Name = partName
				newMotor.Parent = gun.Grip
			end
		end

		-- Add sight parts
		for _, part in ipairs(gun:GetChildren()) do
			if part.Name == "SightReticle" then
				table.insert(sights,part)
			end
		end

		if SightAtt then -- SPH_R15 Gunsmith: Load up any reticles in sight attachments
			for _, part in ipairs(gun[SightAtt.Name]:GetChildren()) do
				if part.Name == "SightReticle" then
					table.insert(sights,part)
				end
			end
		end -- </SPH_R15>


		gun.Parent = rig.Weapon
		gunModel = gun

		weldMod.BlankM6D(rig.AnimBase,gun.Grip)

		if firstPerson then
			RefreshViewmodel()
		end
		ToggleSprint(userInputService:IsKeyDown(config.keySprint))
		EquipAnim()
		IdleAnim()

		gunAmmo = newChild:WaitForChild("Ammo")

		if not equipped.BoltReady.Value then
			MoveBolt(wepStats.boltDist,true)
		end

		if config.lockFirstPerson then
			player.CameraMode = Enum.CameraMode.LockFirstPerson
		end

		curFireMode = equipped.FireMode.Value

		if gunModel.Grip:FindFirstChild("Laser") then
			laserBeamFP.Attachment0 = gunModel.Grip.Laser
		end

		if ModTable.EnableLaserAtt then
			laserBeamFP.Attachment0 = gunModel[ModTable.laserAtt].Main.Laser
		end

		-- Preload animations
		local animSpeed = wepStats.reloadSpeedModifier
		if ModTable.reloadSpeedModifier then -- SPH_R15 Gunsmith: Reload Speed
			animSpeed = ModTable.reloadSpeedModifier
		end
		if wepStats.magType == 1 then
			PlayAnimation(wepStats.reloadAnim,{speed = animSpeed,priority = Enum.AnimationPriority.Action2,transSpeed = 0.17},"Reload",true)
		else
			PlayAnimation(wepStats.reloadAnim,{speed = animSpeed,priority = Enum.AnimationPriority.Action2,transSpeed = 0, looped = gunAmmo.MagAmmo.MaxValue > 1},"Reload",true)
			if wepStats.magType == 3 then
				PlayAnimation(wepStats.clipReloadAnim,{speed = animSpeed,priority = Enum.AnimationPriority.Action2,transSpeed = 0.17, looped = false},"Reload",true)
			end
		end -- </SPH_R15>
		--if wepStats.magType == 1 then
		--	PlayAnimation(wepStats.reloadAnim,{speed = wepStats.reloadSpeedModifier,priority = Enum.AnimationPriority.Action2,transSpeed = 0.17},"Reload",true)
		--else
		--	PlayAnimation(wepStats.reloadAnim,{speed = wepStats.reloadSpeedModifier,priority = Enum.AnimationPriority.Action2,transSpeed = 0, looped = gunAmmo.MagAmmo.MaxValue > 1},"Reload",true)
		--	if wepStats.magType == 3 then
		--		PlayAnimation(wepStats.clipReloadAnim,{speed = wepStats.reloadSpeedModifier,priority = Enum.AnimationPriority.Action2,transSpeed = 0.17, looped = false},"Reload",true)
		--	end
		--end

		PlayAnimation(wepStats.boltChamber,{priority = Enum.AnimationPriority.Action2,transSpeed = 0.05},"Chamber", true)

		if wepStats.operationType == 2 or wepStats.operationType == 3 then
			PlayAnimation(wepStats.boltOpen,{priority = Enum.AnimationPriority.Action2, transSpeed = 0},"BoltOpen", true)
			PlayAnimation(wepStats.boltClose,{priority = Enum.AnimationPriority.Action2},"BoltClose", true)
		end
	end
end)

-- Unequip function
character.ChildRemoved:Connect(function(oldChild)
	if equipped and oldChild:FindFirstChild("SPH_Weapon") and assets.WeaponModels:FindFirstChild(oldChild.Name) then
		Unequip(oldChild)
	end
end)

-- Input began
userInputService.InputBegan:Connect(function(input:InputObject, typing:boolean)
	if not typing and not dead then
		local key = input.KeyCode
		if config.keySprint and key == config.keySprint and stance < 2 and moving then -- Start sprinting
			if stance == 1 then ChangeStance(-1) end
			if equipped and moving then ToggleSprint(true) end
			ChangeWalkSpeed(config.sprintSpeed)
			ChangeLean(0)

			-- SPH_R15: Sprint Animation
			if moving and not falling and stance == 0 then
				if moveAnim then moveAnim:Stop(config.stanceChangeTime) end
				moveAnim = sprintCycleAnim
				if moving then moveAnim:Play(config.stanceChangeTime) end
			end
			-- </SPH_R15>
		elseif config.canCrouch and key == config.lowerStance and stance < 2 and not humanoid.Sit then -- Lower stance
			if not config.canProne and stance == 1 then return end -- If the player is crouched and unable to prone then return
			ChangeStance(1)
			if sprinting then ToggleSprint(false) end
		elseif key == config.raiseStance and stance > 0 then -- Raise stance
			ChangeStance(-1)
		elseif key == config.leanLeft and stance < 2 and not sprinting and not humanoid.Sit then -- Lean to the left
			if lean == -1 then
				ChangeLean(0)
			else
				ChangeLean(-1)
			end
		elseif key == config.leanRight and stance < 2 and not sprinting and not humanoid.Sit then -- Lean to the right
			if lean == 1 then
				ChangeLean(0)
			else
				ChangeLean(1)
			end
		elseif equipped then
			-- Gun must be equipped for these inputs
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				cancelReload = true
				if not (sprinting or reloading) then -- Detect mouse click
					holdingM1 = true

					if not equipped.Chambered.Value and not (curFireMode == fireModes.Manual and gunAmmo.MagAmmo.Value > 0) then
						PlayRepSound("Click")
					end
				end
			elseif key == config.dropKey then
				Unequip(equipped)
				playerDropGun:Fire()
			elseif key == config.keyReload and not reloading and cycled then -- Reload
				if wepStats.infiniteAmmo or gunAmmo.ArcadeAmmoPool.Value > 0 then
					if (wepStats.operationType == 4 and equipped.Chambered.Value)
						or (wepStats.operationType == 3 and gunAmmo.MagAmmo.Value + 1 >= gunAmmo.MagAmmo.MaxValue)
						or (wepStats.operationType == 2 and gunAmmo.MagAmmo.Value >= gunAmmo.MagAmmo.MaxValue) then
						return
					end
					ReloadAnim()
				end
			elseif input.UserInputType == Enum.UserInputType.MouseButton2 and firstPerson and not freeLook and not blocked then -- Aiming
				ToggleSprint(false)
				if stance == 0 then ChangeWalkSpeed(config.walkSpeed) end
				ToggleAiming(true)
			elseif key == config.keyChamber and not reloading and cycled then -- Chamber
				ChamberAnim()
			elseif key == config.sightSwitch and aiming and gunModel:FindFirstChild("AimPart2") then -- Switch sights
				local tempIndex = sightIndex
				tempIndex += 1
				if gunModel:FindFirstChild("AimPart"..tempIndex) then
					sightIndex = tempIndex
					PlayRepSound("AimUp")
				else
					sightIndex = 1
					PlayRepSound("AimDown")
				end
				if wepStats.ADSEnabled and wepStats.ADSEnabled[sightIndex] then
					ToggleADS(true)
				else
					ToggleADS(false)
				end
			elseif input.UserInputType == config.freeLook and equipped then -- Freelook
				freeLook = true
				humanoid.AutoRotate = false
				freeLookRotation = camera.CFrame - camera.CFrame.Position
			elseif key == config.holdUp and not reloading then -- Hold stance up
				ChangeHoldStance(1)
			elseif key == config.holdPatrol and not reloading then -- Hold stance patrol
				ChangeHoldStance(2)
			elseif key == config.holdDown and not reloading then -- Hold stance down
				ChangeHoldStance(3)
			elseif key == config.switchFireMode then -- Switch fire mode
				PlayAnimation(wepStats.switchAnim,{transSpeed = 0.2})
			elseif key == config.toggleLaser then -- SPH_R15 Gunsmith: Laser
				if gunModel.Grip:FindFirstChild("Laser") then
					laserEnabled = not laserEnabled
					if not firstPerson then laserBeamTP.Enabled = true end
					PlayRepSound("Button")
					playerToggleAttachment:Fire(1,laserEnabled, ModTable)
					laserDotUI.Dot.ImageColor3 = gunModel.Grip.Laser.Color.Value
				else
					if ModTable.laserAtt and gunModel[ModTable.laserAtt].Main:FindFirstChild("Laser") then
						laserEnabled = not laserEnabled
						if not firstPerson then laserBeamTP.Enabled = true end
						PlayRepSound("Button")
						playerToggleAttachment:Fire(1,laserEnabled, ModTable)
						laserDotUI.Dot.ImageColor3 = gunModel[ModTable.laserAtt].Main.Laser.Color.Value	
					end
				end -- </SPH_R15>
			elseif key == config.toggleFlashlight then -- SPH_R15 Gunsmith: Flashlight
				local flashlight = gunModel.Grip:FindFirstChild("Flashlight")
				if flashlight then
					local light = flashlight:FindFirstChildWhichIsA("Light")
					flashlightEnabled = not flashlightEnabled
					light.Enabled = flashlightEnabled
					PlayRepSound("Button")
					playerToggleAttachment:Fire(0,light.Enabled, ModTable)

					if not flashlightEnabled then
						weaponRig.Weapon:FindFirstChildWhichIsA("Model").Grip.Flashlight:FindFirstChildWhichIsA("Light").Enabled = false
					elseif not firstPerson then
						weaponRig.Weapon:FindFirstChildWhichIsA("Model").Grip.Flashlight:FindFirstChildWhichIsA("Light").Enabled = true
					end
				else
					if ModTable.flashlightAtt and gunModel:FindFirstChild(ModTable.flashlightAtt) then
						local light = gunModel[ModTable.flashlightAtt].Main.Flashlight:FindFirstChildWhichIsA("Light")
						flashlightEnabled = not flashlightEnabled
						light.Enabled = flashlightEnabled
						PlayRepSound("Button")
						playerToggleAttachment:Fire(0,light.Enabled, ModTable)

						if not flashlightEnabled then
							weaponRig.Weapon:FindFirstChildWhichIsA("Model")[ModTable.flashlightAtt].Main.Flashlight:FindFirstChildWhichIsA("Light").Enabled = false
						elseif not firstPerson then
							weaponRig.Weapon:FindFirstChildWhichIsA("Model")[ModTable.flashlightAtt].Main.Flashlight:FindFirstChildWhichIsA("Light").Enabled = true
						end					
					end
				end -- </SPH_R15>
			elseif key == config.ToggleBipod and CanBipod then -- SPH_R15: Processing bipod input
				bipodEnabled = not bipodEnabled
				BipodToggle(camera.WeaponRig,bipodEnabled) -- activate the bipod
				playerToggleAttachment:Fire(2, bipodEnabled, ModTable) -- tell other players you're activating bipod
			end	-- </SPH_R15>
		end
	end
end)

-- SPH_R15: Bipodology
function BipodToggle(target, enabled)
	if not CanBipod then return
	else
		local BipodTween = TweenInfo.new(0.01,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,false,0.025)
		if enabled == true then
			local bpod = target.Weapon:FindFirstChildWhichIsA("Model").Grip:FindFirstChild("Bipod")
			if UnderBarrelAtt then
				bpod = target.Weapon:FindFirstChildWhichIsA("Model")[UnderBarrelAtt.Name].Main.Bipod
			end
			local BipodRay = Ray.new(bpod.WorldPosition, Vector3.new(0,-1.5,0))
			local BipodHit, BipodPos, BipodNorm = workspace:FindPartOnRayWithIgnoreList(BipodRay, Ignore_Model, false, true)
			if BipodHit then
				if not aiming then
					BipodCF = BipodCF:Lerp(CFrame.new(0,(((bpod.WorldCFrame.Position - BipodPos).magnitude)-1) * (-1.5), 0),.2)
				else
					BipodCF = BipodCF:Lerp(CFrame.new(),.2)
				end
			else
				warn("NO WELD FOUND")
			end
			for _, child in pairs(gunModel:GetChildren()) do
				if child.Name == "Bipod_Active" then
					tweenService:Create(child, BipodTween, {Transparency = 0}):Play()
				elseif child.Name == "Bipod_Reg" then
					tweenService:Create(child, BipodTween, {Transparency = 1}):Play()
				end
			end
			if UnderBarrelAtt and Bipod then
				for _, child in pairs(gunModel[UnderBarrelAtt.Name]:GetChildren()) do
					if child.Name == "Bipod_Active" then
						tweenService:Create(child, BipodTween, {Transparency = 0}):Play()
					elseif child.Name == "Bipod_Reg" then
						tweenService:Create(child, BipodTween, {Transparency = 1}):Play()
					end
				end		
			end
		else
			for _, child in pairs(gunModel:GetChildren()) do
				if child.Name == "Bipod_Active" then
					tweenService:Create(child, BipodTween, {Transparency = 1}):Play()
				elseif child.Name == "Bipod_Reg" then
					tweenService:Create(child, BipodTween, {Transparency = 0}):Play()
				end
			end
			if UnderBarrelAtt and Bipod then
				for _, child in pairs(gunModel[UnderBarrelAtt.Name]:GetChildren()) do
					if child.Name == "Bipod_Active" then
						tweenService:Create(child, BipodTween, {Transparency = 1}):Play()
					elseif child.Name == "Bipod_Reg" then
						tweenService:Create(child, BipodTween, {Transparency = 0}):Play()
					end
				end		
			end
			BipodCF = BipodCF:Lerp(CFrame.new(),.2)
		end
	end
end
-- </SPH_R15>

-- Input ended
userInputService.InputEnded:Connect(function(input:InputObject, typing:boolean)
	if not typing then
		local key = input.KeyCode
		if config.keySprint and key == config.keySprint then
			if stance == 0 then
				ToggleSprint(false)
				ChangeWalkSpeed(config.walkSpeed)
			end
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			holdingM1 = false
			canFire = true
			bulletsCurrentlyFired = 0
			--gunModel.Grip.Fire:Stop()
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 and equipped and not sprinting and aiming then
			ToggleAiming(false)
		elseif input.UserInputType == config.freeLook then
			freeLook = false
			freeLookOffset = freeLookRotation:ToObjectSpace(camera.CFrame)
			freeLookOffset = freeLookOffset - freeLookOffset.Position
			humanoid.AutoRotate = true
		end
	end
end)


runService.Heartbeat:Connect(function(dt:number)
	-- Mouse click code
	if equipped and not dead and holdingM1 and cycled and not sprinting and not reloading then

		-- Can the player fire this gun?
		if canFire and not blocked and holdStance == 0 and equipped:FindFirstChild("Chambered") and equipped.Chambered.Value and curFireMode > 0 and (config.fireWithFreelook or (not config.fireWithFreelook and not freeLook)) then
			if not firstPerson and not config.thirdPersonFiring then return end
			-- Fire gun

			if wepStats.fireAnim then PlayAnimation(wepStats.fireAnim,{priority = Enum.AnimationPriority.Action2, looped = false}) end

			bulletsCurrentlyFired += 1
			ejected = false

			if curFireMode == fireModes.Semi or curFireMode == fireModes.Manual or (curFireMode == fireModes.Burst and bulletsCurrentlyFired >= wepStats.burstNumber) then
				canFire = false
				holdingM1 = false
			end
			cycled = false
			local curModel = weaponRig.Weapon:FindFirstChildWhichIsA("Model")
			curModel = gunModel
			local recoilStats = wepStats.recoil
			--local vertRecoil = recoilStats.vertical
			--local horzRecoil = recoilStats.horizontal
			-- SPH_R15 Gunsmith: Affecting the statistics
			local vertRecoil = recoilStats.vertical * ModTable.recoilMod.vertical
			local horzRecoil = recoilStats.horizontal * ModTable.recoilMod.horizontal
			if aiming then
				vertRecoil /= recoilStats.aimReduction * ModTable.recoilMod.aimReduction
				horzRecoil /= recoilStats.aimReduction * ModTable.recoilMod.aimReduction
			end
			-- </SPH_R15>
			if bipodEnabled then -- SPH_R15: Bipod affects recoil
				vertRecoil *= 0.25
				horzRecoil *= 0.25
			end

			if stance == 2 then
				vertRecoil /= 2
				horzRecoil /= 2
			end
			recoilSpring:shove(Vector3.new(vertRecoil, math.random(-horzRecoil,horzRecoil),recoilStats.camShake) * dt * 60)

			recoilStats = wepStats.gunRecoil
			--vertRecoil = recoilStats.vertical * ModTable.recoilMod.vertical
			--horzRecoil = recoilStats.horizontal * ModTable.recoilMod.horizontal
			-- SPH_R15 Gunsmith: Affecting the statistics			
			vertRecoil = recoilStats.vertical * ModTable.gunRecoilMod.vertical
			horzRecoil = recoilStats.horizontal * ModTable.gunRecoilMod.horizontal
			-- </SPH_R15>
			if stance == 2 then
				vertRecoil /= 1.5
				horzRecoil /= 1.5
			end
			if bipodEnabled then -- SPH_R15: Bipod affects recoil
				vertRecoil *= 0.5
				horzRecoil *= 0.5
			end
			gunRecoilSpring:shove(Vector3.new(vertRecoil, math.random(-horzRecoil,horzRecoil),recoilStats.punchMultiplier) * dt * 60)

			-- Shell ejection
			if curFireMode ~= fireModes.Manual then
				EjectShell()
			end

			local tempGunModel = gunModel
			if not firstPerson then tempGunModel = weaponRig.Weapon:FindFirstChildWhichIsA("Model") end
			if ModTable.muzzleChance then -- SPH_R15 Gunsmith: Modifying muzzle chance
				if ModTable.IsSuppressor then
					bulletHandler.FireFX(player,gunModel,ModTable.muzzleChance, true)
				else
					bulletHandler.FireFX(player,gunModel,ModTable.muzzleChance, false)
				end
			else
				bulletHandler.FireFX(player,tempGunModel,wepStats.muzzleChance)
			end

			-- Move bolt
			if gunModel:FindFirstChild("Bolt") then
				MoveBolt(wepStats.boltDist)
			end

			-- Fire bullet
			local shotCount = (wepStats.shotgun and wepStats.shotgunPellets) or 1
			if ModTable.shotgun then -- SPH_R15 Gunsmith: Shotgun time! :)
				shotCount = ModTable.shotgunPellets
			end -- </SPH_R15>
			repeat
				shotCount -= 1
				local bulletOrigin, bulletDirection
				--local spreadCFrame = CFrame.Angles(math.rad(math.random(-wepStats.spread,wepStats.spread)), math.rad(math.random(-wepStats.spread,wepStats.spread)), 0)
				-- SPH_R15 Gunsmith: Spread time
				local spreadInt = wepStats.spread
				if ModTable.spread then
					spreadInt *= ModTable.spread
				end
				local spreadCFrame = CFrame.Angles(math.rad(math.random(-spreadInt,spreadInt)), math.rad(math.random(-spreadInt,spreadInt)), 0)
				-- </SPH_R15>
				if firstPerson then
					bulletOrigin = curModel.Grip.Muzzle.WorldCFrame.Position
					bulletDirection = (curModel.Grip.Muzzle.WorldCFrame * spreadCFrame).LookVector
				else
					local muzzle = weaponRig.Weapon:FindFirstChildWhichIsA("Model").Grip.Muzzle
					bulletOrigin = muzzle.WorldCFrame.Position
					bulletDirection = (muzzle.WorldCFrame * spreadCFrame).LookVector
				end
				-- SPH_R15 Gunsmith: Muzzle Velocity time				
				local bv = wepStats.muzzleVelocity
				if ModTable.muzzleVelocity then
					bv = ModTable.muzzleVelocity
				end
				local bulletVelocity = (bulletDirection * bv * 3.5) -- 1 Meter = ~3.5 Studs (According to the dev forum)
				-- </SPH_R15>		

				--local bulletVelocity = (bulletDirection * wepStats.muzzleVelocity * 3.5) -- 1 Meter = ~3.5 Studs (According to the dev forum)

				-- SPH_R15 Gunsmith: Tracer Stuff
				local tracerColor = nil
				local tracers 	  = wepStats.tracers
				local timing	  = wepStats.tracerTiming
				local color		  = wepStats.tracerColor
				if ModTable.tracers then
					tracers = ModTable.tracers
					timing = ModTable.tracerTiming
					color  = ModTable.tracerColor
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
				bulletHandler.FireBullet(weaponRig,bulletOrigin,bulletDirection,bulletVelocity,equipped,player,tracerColor,false,ModTable) -- SPH_R15 Gunsmith: Added a TRUE for fake and ModTable to pass on information, if any, on effects to damage
			until shotCount <= 0

			playerFire:Fire(curModel.Grip.Muzzle.WorldCFrame, ModTable)

			local cycleTime = wepStats.fireRate
			cycleTime *= ModTable.fireRate -- SPH_R15 Gunsmith
			if curFireMode == fireModes.Burst and wepStats.burstFireRate then
				cycleTime = wepStats.burstFireRate
			end

			if gunModel and wepStats.projectile ~= "Bullet" and gunModel:FindFirstChild(wepStats.projectile) then
				local projectile = gunModel:FindFirstChild(wepStats.projectile)
				projectile.LocalTransparencyModifier = 1
				for _, child in ipairs(projectile:GetDescendants()) do
					if child:IsA("BasePart") then
						child.LocalTransparencyModifier = 1
					end
				end
			end

			task.wait(60 / cycleTime)

			if not equipped then return end

			if wepStats.autoChamber and curFireMode == fireModes.Manual then
				ChamberAnim()
			end

			cycled = true
		else
			-- Chamber gun
			if not equipped.Chambered.Value then
				if curFireMode == fireModes.Manual and gunAmmo.MagAmmo.Value > 0 then
					ChamberAnim()
					holdingM1 = false
				end
			elseif wepStats.emptyCloseBolt then
				repChamber:Fire()
				MoveBolt(CFrame.new())
			end
		end
	end
end)

local sidewaysFixed = false
runService.RenderStepped:Connect(function(dt:number)
	-- If fps is lower than 5, skip renderstepped
	if dt > 0.2 then
		warn(warnPrefix.."RenderStepped skipped due to low framerate.")
		return
	end

	-- SPH_R15: Bipod Checking
	if Bipod and equipped then
		if camera:WaitForChild("WeaponRig").Weapon:FindFirstChildWhichIsA("Model") then
			local bpod = ModTable.bipodAtt or camera.WeaponRig.Weapon:FindFirstChildWhichIsA("Model").Grip:FindFirstChild("Bipod")
			if bpod then
				if UnderBarrelAtt then
					bpod = camera.WeaponRig.Weapon:FindFirstChildWhichIsA("Model")[UnderBarrelAtt.Name].Main.Bipod
				end
				local BipodRay = Ray.new(bpod.WorldCFrame.Position, Vector3.new(0,-1.5,0))
				local BipodHit, BipodPos, BipodNorm = workspace:FindPartOnRayWithIgnoreList(BipodRay, Ignore_Model, false, true)

				-- emancipation proclamation
				if bipodEnabled and not CanBipod then -- SPH_R15: Bipod automatically deactivates if you move the rifle away from where it should be
					bipodEnabled = false
					BipodToggle(camera.WeaponRig,bipodEnabled)
					playerToggleAttachment:Fire(2, bipodEnabled, ModTable)
				end

				if BipodHit then
					CanBipod = true
				else
					CanBipod = false
				end
			end
		end
	end
	-- </SPH_R15>

	headRotationEventCooldown -= dt

	-- Limit camera rotation
	if humanoid.Sit and not vehicleSeated and firstPerson or freeLook then
		local cameraCFrame = humanoidRootPart.CFrame:ToObjectSpace(camera.CFrame)
		local x, y, z = cameraCFrame:ToOrientation()
		local a = camera.CFrame.Position.X
		local b = camera.CFrame.Position.Y
		local c = camera.CFrame.Position.Z

		local xlimit = math.rad(math.clamp(math.deg(x),-60,60))
		local ylimit = math.rad(math.clamp(math.deg(y),-60,60))
		local zlimit = math.rad(math.clamp(math.deg(z),-60,60))
		local limitedCFrame = humanoidRootPart.CFrame:ToWorldSpace(CFrame.new(a,b,c) * CFrame.fromOrientation(xlimit,ylimit,zlimit))
		camera.CFrame = CFrame.new(camera.CFrame.Position) * (limitedCFrame - limitedCFrame.Position)
	end

	if not dead and character:FindFirstChild("Head") then		
		if not dead then

			--Jarr's experimental horizontal fix
			if not sidewaysFixed then
				sidewaysFixed = true
				ChangeLean(1)
				ChangeLean(0)
			end

			local torsoDirection
			if humanoid.RigType == Enum.HumanoidRigType.R6 then
				torsoDirection = character.Torso.CFrame.LookVector
			else
				torsoDirection = character.UpperTorso.CFrame.LookVector
			end

			local lookDirection = camera.CFrame
			if (not config.headRotation or sprinting) and not firstPerson then
				lookDirection = humanoidRootPart.CFrame
			end

			local cameraDirection = humanoidRootPart.CFrame:ToObjectSpace(lookDirection).LookVector
			local rotationCFrame = CFrame.Angles(0, math.asin(cameraDirection.X)/1.15, 0) * CFrame.Angles(-math.asin(math.clamp(lookDirection.LookVector.Y,-.8,.15)) + math.asin(math.clamp(torsoDirection.Y, -.6,.6)), 0, 0) -- SPH_R15: clamped the Y direction so you can't roll your head into your body like a turtle.. as much.
			--local rotationCFrame = CFrame.Angles(0, math.asin(cameraDirection.X)/1.15, 0) * CFrame.Angles(-math.asin(lookDirection.LookVector.Y) + math.asin(torsoDirection.Y), 0, 0)
			local neckCFrame = CFrame.new(0, -.5, 0) * rotationCFrame * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)) --0, -0.5, 0,   90, 0, 180


			neckJoint.C1 = neckJoint.C1:Lerp(neckCFrame,1 - math.exp(-config.headRotationSpeed * dt))
			--neckJoint.C1 = neckCFrame

			if headRotationEventCooldown <= 0 and not dead and not config.disableHeadRotation then
				headRotationEventCooldown = config.headRotationEventRate
				local angleComponents = {neckJoint.C1:GetComponents()}
				local anglePackage = httpService:JSONEncode(angleComponents)
				bodyAnimRequest:Fire(anglePackage)
			end
		end

		-- Check if player is in first person
		if not firstPerson and character.Head.LocalTransparencyModifier >= fpThreshold then
			firstPerson = true
			if equipped then
				if flashlightEnabled then
					if gunModel.Grip:FindFirstChild("Flashlight") then
						gunModel.Grip.Flashlight:FindFirstChildWhichIsA("Light").Enabled = true
						weaponRig.Weapon:FindFirstChildWhichIsA("Model").Grip.Flashlight:FindFirstChildWhichIsA("Light").Enabled = false
					end
				end
				if laserEnabled then
					laserBeamTP.Enabled = false
					laserBeamFP.Enabled = true
				end
			end
		elseif firstPerson and character.Head.LocalTransparencyModifier <= fpThreshold then
			firstPerson = false
			if equipped then
				if laserEnabled then
					laserBeamTP.Enabled = true
					laserBeamFP.Enabled = false
					if not laserBeamTP.Attachment0 then -- SPH_R15 Gunsmith: Laser Attachment Gaming
						laserBeamTP.Attachment0 = GetThirdPersonGunModel().Grip.Laser or GetThirdPersonGunModel()[ModTable.laserAtt].Main.Laser
					end --</SPH_R15>
					--if not laserBeamTP.Attachment0 then
					--	laserBeamTP.Attachment0 = GetThirdPersonGunModel().Grip.Laser
					--end
				end
				if gunModel.Grip:FindFirstChild("Flashlight") then
					gunModel.Grip.Flashlight:FindFirstChildWhichIsA("Light").Enabled = false
					if weaponRig.Weapon:FindFirstChildWhichIsA("Model") and flashlightEnabled then
						weaponRig.Weapon:FindFirstChildWhichIsA("Model").Grip.Flashlight:FindFirstChildWhichIsA("Light").Enabled = true
					end
				end
			end
			ResetHead()
			cameraOffsetTarget = Vector3.zero
		end

		-- Check if player is moving
		if moveAnim then moveAnim:AdjustSpeed(humanoid.WalkSpeed / 6) end
		if humanoid.MoveDirection.Magnitude > 0 and not moving then
			moving = true
			if not humanoid.Sit then -- SPH_R15: Don't play the moving cycle if the player is seated!
				if moveAnim then moveAnim:Play(config.stanceChangeTime) end
			end
			--if moveAnim then moveAnim:Play(config.stanceChangeTime) end
		elseif humanoid.MoveDirection.Magnitude <= 0 then
			moving = false
			if sprinting then
				ToggleSprint(false)
				ChangeWalkSpeed(config.walkSpeed)
			end
			if moveAnim then moveAnim:Stop(config.stanceChangeTime) end
		end

		-- First person body offset
		if config.firstPersonBody and firstPerson then
			local xHead = character.HumanoidRootPart.CFrame:ToObjectSpace(camera.CFrame):ToEulerAngles()
			local rotationOffset = -1.6 + (xHead + 1.4) / 2.8
			cameraOffsetTarget = Vector3.new(0,0,rotationOffset)
		else
			cameraOffsetTarget = Vector3.zero
		end

		local xOffset = 0
		local yOffset = 0
		local zOffset = cameraOffsetTarget.Z

		if stance == 1 then -- SPH_R15: Adjusted camera positioning to reflect R15.
			yOffset = .5
			if firstPerson then zOffset -= 1.5 end --rev
		elseif stance == 2 then
			yOffset = 1.5
			if firstPerson then zOffset = -3 end --rev
		end

		-- Lean offset
		if lean < 0 then
			xOffset = -1
			yOffset += -0.2 --rev
		elseif lean > 0 then
			xOffset = 1
			yOffset += -0.2 --rev
		end

		--if not vehicleSeated and camera.CameraType == Enum.CameraType.Custom then
		--	-- Update camera offset
		--	cameraOffsetTarget = Vector3.new(xOffset,-yOffset,zOffset)
		--	humanoid.CameraOffset = humanoid.CameraOffset:Lerp(cameraOffsetTarget,0.1 * dt * 60)

		--	-- Update leaning offset
		--	rootJoint.C1 = rootJoint.C1:Lerp(CFrame.new(-xOffset / 2,1,0) * CFrame.Angles(math.rad(90),math.rad(180) + math.rad(17 * lean),0),0.1 * dt * 60)
		--	cameraLeanRotation = LerpNumber(cameraLeanRotation,15 * -lean, 0.1) --  2,0,0          90           180             17 * lean, 0, 0.1 * dt * 60
		--	camera.CFrame *= CFrame.Angles(0,0,math.rad(cameraLeanRotation))

		--	-- Camera tilt
		--	if config.cameraTilting and firstPerson then
		--		local maxTiltAngle = 2
		--		local relativeVelocity = humanoidRootPart.CFrame:VectorToObjectSpace(humanoidRootPart.Velocity)
		--		local mouseDelta = userInputService:GetMouseDelta()
		--		local targetRollAngle = math.clamp(-relativeVelocity.X, -maxTiltAngle, maxTiltAngle) + mouseDelta.X / 2
		--		cameraRollAngle = LerpNumber(cameraRollAngle,targetRollAngle,0.07 * dt * 60)
		--		camera.CFrame *= CFrame.Angles(0,0,math.rad(cameraRollAngle))
		--	end
		--end

		if not vehicleSeated and camera.CameraType == Enum.CameraType.Custom then -- SPH_R15: Fix by TACT1CALJ0KER: Reworked lean script
			-- Update camera offset
			cameraOffsetTarget = Vector3.new(xOffset,-yOffset,zOffset)
			humanoid.CameraOffset = humanoid.CameraOffset:Lerp(cameraOffsetTarget,0.1 * dt * 60)

			-- Update leaning offset
			--rootJoint.C1 = rootJoint.C1:Lerp(CFrame.new(-xOffset / 2,1,0) * CFrame.Angles(math.rad(90),math.rad(180) + math.rad(17 * lean),0),0.1 * dt * 60)
			--    cameraLeanRotation = LerpNumber(cameraLeanRotation,15 * -lean, 0.1) --  2,0,0          90           180             17 * lean, 0, 0.1 * dt * 60
			--camera.CFrame *= CFrame.Angles(0,0,math.rad(cameraLeanRotation))

			-- Camera tilt

		end -- </SPH_R15>

		-- Update viewmodel
		if equipped and camera.CameraType == Enum.CameraType.Custom then
			if firstPerson and not viewmodelVisible then
				-- Player switched to first person
				RefreshViewmodel()
				ToggleSprint(userInputService:IsKeyDown(config.keySprint))
			end

			-- Update recoil and movement springs
			UpdateViewmodelPosition(dt)

			-- Laser raycast
			if laserEnabled then -- SPH_R15 Gunsmith: Laser Gaming
				--  SPH_R15: Rangefinder
				if ModTable.isRangefinder then
				player:SetAttribute("rangefinderActive",true)
				end
				-- </SPH_R15>

				local laserRef = gunModel.Grip:FindFirstChild("Laser") or gunModel[ModTable.laserAtt].Main.Laser
				local serverRef = GetThirdPersonGunModel().Grip:FindFirstChild("Laser") or GetThirdPersonGunModel()[ModTable.laserAtt].Main.Laser
				if not laserDotUI.Enabled then
					laserDotUI.Enabled = true
					laserDotUI.Dot.ImageColor3 = laserRef.Color.Value

					if config.laserTrail then
						laserBeamFP.Color = ColorSequence.new(laserRef.Color.Value)
						laserBeamTP.Color = ColorSequence.new(laserRef.Color.Value)

						if firstPerson then
							laserBeamFP.Enabled = true
						else
							laserBeamTP.Enabled = true
							if not laserBeamTP.Attachment0 then
								laserBeamTP.Attachment0 = serverRef
							end
						end
					end
				end
				local laserPoint:Attachment = firstPerson and laserRef or serverRef
				local laserRayParams = RaycastParams.new()
				laserRayParams.FilterType = Enum.RaycastFilterType.Exclude
				laserRayParams.FilterDescendantsInstances = {gunModel, character}
				laserRayParams.RespectCanCollide = true
				local rayResult = workspace:Raycast(laserPoint.WorldPosition, laserPoint.WorldCFrame.LookVector * 600, laserRayParams)
				if rayResult then
					laserDotPoint.WorldPosition = rayResult.Position
					--  SPH_R15: Rangefinder
					if ModTable.isRangefinder then
						local tgtDistance = ( (character.Head.Position - rayResult.Position).Magnitude )*0.28
						player:SetAttribute("tgtDistance",tgtDistance)
					end
					-- </SPH_R15>
				else
					laserDotPoint.WorldPosition = laserPoint.WorldCFrame.LookVector * 600
					--  SPH_R15: Rangefinder
					player:SetAttribute("tgtDistance",nil)
					-- </SPH_R15>
				end -- </SPH_R15>

				--if laserEnabled then
				--	if not laserDotUI.Enabled then
				--		laserDotUI.Enabled = true
				--		laserDotUI.Dot.ImageColor3 = gunModel.Grip.Laser.Color.Value

				--		if config.laserTrail then
				--			laserBeamFP.Color = ColorSequence.new(gunModel.Grip.Laser.Color.Value)
				--			laserBeamTP.Color = ColorSequence.new(gunModel.Grip.Laser.Color.Value)

				--			if firstPerson then
				--				laserBeamFP.Enabled = true
				--			else
				--				laserBeamTP.Enabled = true
				--				if not laserBeamTP.Attachment0 then
				--					laserBeamTP.Attachment0 = GetThirdPersonGunModel().Grip.Laser
				--				end
				--			end
				--		end
				--	end
				--	local laserPoint:Attachment = firstPerson and gunModel.Grip.Laser or GetThirdPersonGunModel().Grip.Laser
				--	local laserRayParams = RaycastParams.new()
				--	laserRayParams.FilterType = Enum.RaycastFilterType.Exclude
				--	laserRayParams.FilterDescendantsInstances = {gunModel, character}
				--	laserRayParams.RespectCanCollide = true
				--	local rayResult = workspace:Raycast(laserPoint.WorldPosition, laserPoint.WorldCFrame.LookVector * 600, laserRayParams)
				--	if rayResult then
				--		laserDotPoint.WorldPosition = rayResult.Position
				--	else
				--		laserDotPoint.WorldPosition = laserPoint.WorldCFrame.LookVector * 600
				--	end
			elseif laserDotUI.Enabled then
				laserDotUI.Enabled = false
				laserBeamFP.Enabled = false
				laserBeamTP.Enabled = false
				--  SPH_R15: Rangefinder
				player:SetAttribute("rangefinderActive",false)
				-- </SPH_R15>
			end

		elseif viewmodelVisible and not equipping then
			viewmodelVisible = false
		end

		-- Update movement sway
		local tempDampening = config.bobDampening
		local difference = tempDampening - (tempDampening / (tempWalkSpeed / config.walkSpeed))
		difference /= 2
		tempDampening -= difference
		if aiming then tempDampening *= config.aimBobDampening end

		local tempBobSpeed = config.bobSpeed
		tempBobSpeed *= tempWalkSpeed / config.walkSpeed

		if not humanoid.Sit then
			local moveSway = Vector3.new(GetSineOffset(tempBobSpeed),GetSineOffset(tempBobSpeed / 2),GetSineOffset(tempBobSpeed / 2))
			moveSpring:shove(moveSway / tempDampening * humanoidRootPart.Velocity.Magnitude / tempDampening * dt * 60)
		end

		local updatedMoveSway = moveSpring:update(dt)
		animBase.CFrame = animBase.CFrame:ToWorldSpace(CFrame.new(updatedMoveSway.Y, updatedMoveSway.X, 0) * CFrame.Angles(updatedMoveSway.Y * 0.3,0,updatedMoveSway.Y * 0.8))

		-- Camera movement sway
		if config.cameraMovement and (firstPerson and not humanoid.Sit) and not vehicleSeated and camera.CameraType == Enum.CameraType.Custom then
			camera.CFrame *= CFrame.Angles(math.rad(updatedMoveSway.X / config.cameraBobDampening), math.rad(updatedMoveSway.Y / config.cameraBobDampening), 0)
		end

		-- Update sights
		for _, sight:BasePart in ipairs(sights) do
			local frame = sight.SurfaceGui.Frame
			local sightUI = frame:FindFirstChild("Reticle") or frame:FindFirstChild("Holo")

			local dist = sight.CFrame:PointToObjectSpace(camera.CFrame.Position)/sight.Size
			sightUI.Position = UDim2.fromScale(0.5 + dist.X, 0.5 - dist.Y)	

			if sightUI.Name == "Holo" then
				local newSize = camera.FieldOfView / 70
				sightUI.Size = UDim2.fromScale(newSize,newSize)
			end
		end

		if aiming then
			camera.FieldOfView = LerpNumber(camera.FieldOfView, aimFOVTarget, 0.3)
		end
	end

	tempWalkSpeed = targetWalkSpeed
	if humanoid.Health < 30 and config.lowHealthEffects then
		tempWalkSpeed *= humanoid.Health / 30
	end

	if reloading and wepStats.reloadWalkSpeed then	-- SPH_R15: Reduces reload walkspeed by given amount
		tempWalkSpeed *= wepStats.reloadWalkSpeed
	end
	
	humanoid.WalkSpeed = LerpNumber(humanoid.WalkSpeed, tempWalkSpeed, 0.2 * dt * 60)

	humanoid.JumpPower = config.jumpPower -- SPH_R15: Limited Jump Power
	humanoid.JumpHeight = config.jumpHeight -- SPH_R15: Limited Jump Height
end)

userInputService.InputChanged:Connect(function(input)
	if aiming and input.UserInputType == Enum.UserInputType.MouseWheel then
		if userInputService:IsKeyDown(config.holdForScollZoom) then
			-- Zoom
			local newFOV = aimFOVTarget - input.Position.Z * 3
			aimFOVTarget = math.clamp(newFOV, wepStats.aimFovMin, defaultFOV)
		else
			-- Sensitivity
			aimSensitivity = math.clamp(aimSensitivity - 0.01 * -input.Position.Z,0.005,1)
			userInputService.MouseDeltaSensitivity = aimSensitivity
			-- SPH_R15B
		end
	end
end)

humanoid.Seated:Connect(function(seated, seatPart)
	if seated then
		ToggleSprint(false)
		ChangeLean(0)
		if stance == 1 then
			ChangeStance(-1)
		elseif stance == 2 then
			ChangeStance(-1)
			ChangeStance(-1)
		end

		if seatPart:IsA("VehicleSeat") then
			vehicleSeated = true
			if equipped then
				humanoid:UnequipTools()
			end
		else
			vehicleSeated = false
		end
	else
		vehicleSeated = false
	end
end)

-- SPH_R15: Animation Time
falling = false
function playerFalling(active)
	falling = active
	if active then
		if moveAnim then moveAnim:Stop(config.stanceChangeTime) end
	else
		moveAnim:Play(config.stanceChangeTime)
	end
end
function playerLaboring(speed)
	if speed then
		if moveAnim then moveAnim:Stop(config.stanceChangeTime) end
		falling = true
	else
		falling = false
		moveAnim:Play(config.stanceChangeTime)
	end
end

humanoid.FallingDown:Connect(playerFalling) 
humanoid.FreeFalling:Connect(playerFalling)
humanoid.GettingUp:Connect(playerFalling)
humanoid.Climbing:connect(playerLaboring)
humanoid.Swimming:connect(playerLaboring)

-- </SPH_R15>