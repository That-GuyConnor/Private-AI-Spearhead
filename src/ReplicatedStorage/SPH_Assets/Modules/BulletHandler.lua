local module = {}

local debugMode = false

local debris = game:GetService("Debris")
local tweenService = game:GetService("TweenService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local modules = replicatedStorage.SPH_Assets.Modules
local config = require(modules.Parent.GameConfig)
local hitFX = require(modules.HitFX)

local bridgeNet = require(modules.BridgeNet)
local bulletHit

local sphWorkspace = workspace:WaitForChild("SPH_Workspace")
local bulletContainer = sphWorkspace:WaitForChild("Projectiles")
local cacheContainer = workspace.SPH_Workspace:WaitForChild("Cache")

local suppression = replicatedStorage:WaitForChild("Suppression",100)

local pierceMod = require(modules.PierceMod)
local partCache = require(modules.PartCache)

local baseBullet = script.Bullet
local bulletProvider = partCache.new(baseBullet:Clone(),config.maxBullets or 300,cacheContainer)

local fastCast = require(modules.FastCast)
local bulletBehavior
local rayParams = RaycastParams.new()
rayParams.IgnoreWater = true
rayParams.RespectCanCollide = true

bulletBehavior = fastCast.newBehavior()
bulletBehavior.RaycastParams = rayParams
bulletBehavior.MaxDistance = config.maxBulletDistance
bulletBehavior.AutoIgnoreContainer = true
bulletBehavior.CosmeticBulletContainer = bulletContainer
bulletBehavior.HighFidelityBehavior = fastCast.HighFidelityBehavior.Default
bulletBehavior.CosmeticBulletProvider = bulletProvider
bulletBehavior.CanPierceFunction = pierceMod.CanPierce

local caster = fastCast.new()
fastCast.VisualizeCasts = debugMode

local player, character
module.Initialize = function(newPlayer)
	player = newPlayer
	character = newPlayer.Character
	bulletHit = bridgeNet.CreateBridge("BulletHit")
end

local function ResetBullet(bulletPart)
	bulletPart.BulletSmoke.Enabled = false
	bulletPart.PointLight.Enabled = false
	bulletPart.Color = baseBullet.Color
	bulletPart.BeamLong.Color = baseBullet.BeamLong.Color
	bulletPart.BeamLong.Enabled = false
	bulletPart.Transparency = 1
	bulletPart.PointLight.Enabled = false
	bulletPart.PointLight.Color = baseBullet.PointLight.Color
	bulletPart.DistanceEffect.Enabled = false
	bulletPart.DistanceEffect.Dot.ImageColor3 = baseBullet.DistanceEffect.Dot.ImageColor3
	bulletPart.DistanceEffect.Flare.ImageColor3 = bulletPart.DistanceEffect.Flare.ImageColor3
	if bulletPart:FindFirstChild("FakeBullet") then
		bulletPart.FakeBullet:Destroy()
	end
end

module.FireBullet = function(rig,bulletOrigin,bulletDirection,bulletVelocity,tool,playerFired,tracerColor,fake, modTable)
	bulletBehavior.Acceleration = config.bulletAcceleration
	local wepStats = require(tool.SPH_Weapon.WeaponStats)
	if not wepStats.bulletDrop then bulletBehavior.Acceleration = Vector3.zero end

	local newBullet = caster:Fire(bulletOrigin,bulletDirection,bulletVelocity,bulletBehavior)
	local newData = {}
	newData.Player = playerFired
	newData.TracerColor = tracerColor
	newData.Tool = tool
	newData.IgnoreModel = rig
	newData.FakeBullet = fake
	newData.Visible = false
	newData.Origin = bulletOrigin
	newData.SuppressionLevel = wepStats.suppressionLevel or 1
	newData.ModTable = modTable

	local bullet = newBullet.RayInfo.CosmeticBulletObject
	if bullet and bullet.Transparency == 0 then
		ResetBullet(bullet)
	end
	local projectileModel = replicatedStorage.SPH_Assets.Projectiles:FindFirstChild(wepStats.projectile)
	if projectileModel then
		local fakeBullet = projectileModel:Clone()
		fakeBullet.Anchored = false
		fakeBullet.CanCollide = false
		fakeBullet.Name = "FakeBullet"
		fakeBullet.Parent = bullet
		newData.Visible = true
	end

	newBullet.UserData = newData

	-- Third person recoil animation
	rig.BaseWeld.C0 = wepStats.serverOffset * CFrame.new(0,0,0.17) * CFrame.Angles(math.rad(2),math.rad(math.random(-10,10) / 10),0)
	tweenService:Create(rig.BaseWeld,TweenInfo.new(0.3,Enum.EasingStyle.Back),{C0 = wepStats.serverOffset}):Play()

	-- Rocket stuff
	local gunModel = rig.Weapon:FindFirstChildWhichIsA("Model")
	if gunModel and gunModel:FindFirstChild(wepStats.projectile) then
		local projectile = gunModel:FindFirstChild(wepStats.projectile)
		projectile.LocalTransparencyModifier = 1
		for _, child in ipairs(projectile:GetDescendants()) do
			if child:IsA("BasePart") then
				child.LocalTransparencyModifier = 1
			end
		end
	end
end

module.FireFX = function(playerFired:Player, gunModel, muzzleChance, suppressed) -- SPH_R15 Gunsmith: Added variable for suppressor
	local humanoidRootPart = playerFired.Character:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart and player:DistanceFromCharacter(humanoidRootPart.Position) <= config.fireEffectDistance then

		-- Fire sound
		for _, child in ipairs(gunModel.Grip:GetChildren()) do
			if suppressed then
				if child:IsA("Sound") and (child.Name == "Suppressor") then
					if not child.Looped then
						local newFire = child:Clone()
						newFire.PlaybackSpeed += math.random(-10,10) / config.fireSoundVariation
						newFire.Name = newFire.Name.."_Playing"
						newFire.Parent = gunModel.Grip.Muzzle
						newFire:Play()
						debris:AddItem(newFire,newFire.TimeLength == 0 and 5 or newFire.TimeLength)
					else
						child:Play()
					end
				end				
			else
				if child:IsA("Sound") and (child.Name == "Fire" or (child.Name == "Echo" and (config.firstPersonEcho or playerFired ~= player))) then
					if not child.Looped then
						local newFire = child:Clone()
						newFire.PlaybackSpeed += math.random(-10,10) / config.fireSoundVariation
						newFire.Name = newFire.Name.."_Playing"
						newFire.Parent = gunModel.Grip.Muzzle
						newFire:Play()
						debris:AddItem(newFire,newFire.TimeLength == 0 and 5 or newFire.TimeLength)
					else
						child:Play()
					end
				end
			end
		end

		-- Fire effect
		local muzzleChance = math.random(10) <= muzzleChance
		for _, fx in ipairs(gunModel.Grip.Muzzle:GetChildren()) do
			if fx:IsA("ParticleEmitter") then
				if fx:FindFirstChild("Particles") then
					local canEmit = false
					if string.find(fx.Name,"Flash") then
						if muzzleChance then
							canEmit = true
						end
					else
						canEmit = true
					end
					if canEmit then
						fx:Emit(fx.Particles.Value)
					end
				elseif fx.Name == "Smoke" then
					fx:Emit(10)
				elseif fx.Name == "Flash" and muzzleChance then
					fx:Emit(5)
				end
			elseif fx:IsA("Light") and muzzleChance then
				fx.Enabled = true
				task.delay(0.01,function() fx.Enabled = false end)
			end
		end
	end
end

module.MoveBolt = function(gunModel,wepStats,direction,magAmmo)
	if not gunModel or not gunModel:FindFirstChild("Grip") then return end
	for _, constraint in ipairs(gunModel.Grip:GetChildren()) do
		for _, name in ipairs(wepStats.fireMoveParts) do
			if constraint.Name == name then
				local m6d = constraint
				m6d.C1 = CFrame.new()
				local tInfo = TweenInfo.new(60 / wepStats.fireRate / 2,
					Enum.EasingStyle.Linear,
					Enum.EasingDirection.In,
					0,
					not (magAmmo <= 0 and wepStats.emptyLockBolt))
				local distance
				if typeof(direction) == "CFrame" then
					distance = direction
				else
					distance = CFrame.new(0,0,-direction)
				end
				tweenService:Create(m6d, tInfo, {C1 = distance}):Play()
				break
			end
		end
	end
end


caster.LengthChanged:Connect(function(cast, segmentOrigin, segmentDirection, length, segmentVelocity, cosmeticBulletObject)
	if not cosmeticBulletObject then return end

	-- Suppression effects
	if config.suppressionEffects and player ~= cast.UserData.Player and not cast.UserData.Cracked and player:DistanceFromCharacter(cosmeticBulletObject.Position) <= 60 and player:DistanceFromCharacter(cast.UserData.Origin) >= 60 then
		suppression:Fire(cast.UserData.SuppressionLevel)
		cast.UserData.Cracked = true
	end

	-- Tracer effects
	if not cast.UserData.Visible and (config.arcadeBullets or cast.UserData.TracerColor)
		and (cast.UserData.Origin - cosmeticBulletObject.Position).Magnitude > config.tracerStartDistance then
		cast.UserData.Visible = true
		local bullet = cosmeticBulletObject
		bullet.Transparency = 0
		bullet.BeamLong.Enabled = true
		bullet.BulletSmoke.Enabled = true
		bullet.PointLight.Enabled = true
		bullet.DistanceEffect.Enabled = true
		if cast.UserData.TracerColor then
			local newColor = cast.UserData.TracerColor
			if config.teamTracers and cast.UserData.Player.Team then
				bullet.Color = cast.UserData.Player.Team.TeamColor.Color
			else
				bullet.Color = newColor
			end
			bullet.BeamLong.Enabled = true
			bullet.BeamLong.Color = ColorSequence.new(newColor)
			bullet.PointLight.Color = newColor
			bullet.BulletSmoke.Enabled = false
			bullet.DistanceEffect.Dot.ImageColor3 = newColor
			bullet.DistanceEffect.Flare.ImageColor3 = newColor
		end
	end

	-- Step bullet to new position
	local bulletLength = cosmeticBulletObject.Size.Z / 2
	local baseCFrame = CFrame.new(segmentOrigin, segmentOrigin + segmentDirection)
	cosmeticBulletObject.CFrame = baseCFrame * CFrame.new(0, 0, -(length - bulletLength))

	if cosmeticBulletObject:FindFirstChild("FakeBullet") then
		cosmeticBulletObject.FakeBullet.CFrame = cosmeticBulletObject.CFrame
	end
end)

caster.RayHit:Connect(function(cast, raycastResult, segmentVelocity, cosmeticBulletObject:BasePart)
	if not cast.UserData.FakeBullet then
		local hitPart = raycastResult.Instance
		local bulletStats = require(cast.UserData.Tool.SPH_Weapon.WeaponStats)
		if bulletStats.projectile == "Bullet" then
			hitFX.HitEffect(raycastResult.Position,hitPart,raycastResult.Normal)
		end
		local fakeRayResult = { -- Convert the RaycastResult into a generic dictionary, events don't like RaycastResults for some reason
			Position = raycastResult.Position,
			Normal = raycastResult.Normal,
			Instance = raycastResult.Instance
		}
		bulletHit:Fire(cast.UserData.Tool,fakeRayResult,cosmeticBulletObject.CFrame, cast.UserData.ModTable) -- SPH_R15: Passing on modData to the server

		-- Suppression effects
		if config.suppressionEffects and player ~= cast.UserData.Player and not cast.UserData.Cracked then
			suppression:Fire(cast.UserData.SuppressionLevel)
			cast.UserData.Cracked = true
		end
	end
end)

caster.CastTerminating:Connect(function(cast)
	if cast.UserData.Visible then
		local bulletPart = cast.RayInfo.CosmeticBulletObject
		ResetBullet(bulletPart)
	end
	bulletProvider:ReturnPart(cast.RayInfo.CosmeticBulletObject)
end)

return module