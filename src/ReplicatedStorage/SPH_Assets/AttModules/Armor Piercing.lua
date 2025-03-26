local TS = game:GetService('TweenService')
local module = {}
module.AttachmentType = "Ammo"

--/Sight
module.aimFovMinMod		= 1
module.AimTimeMod		= 1 -- 1 = normal aim time, higher = faster, lower = slower

--/Barrel
module.gunLength		= 0		-- how much length does this attachment add to the gun?
module.IsSuppressor		= nil

--/UnderBarrel
module.IsBipod 			= false

--/Other
module.EnableLaser 		= nil
module.EnableFlashlight = nil
module.InfraRed 		= false
module.ADSEnabled = { -- Ignore this setting if not using an ADS Mesh
	true, -- Enabled for primary sight
	false -- Enabled for secondary sight (T)
}

--/Ammo -- if all these are nil, use gun's settings
module.ammoType 		= "AP" -- what type of ammo does it eject?
module.tracers			= true
module.tracerTiming 	= 2 -- Every x number of shots will be a tracer
module.tracerColor 		= Color3.new(0,255,0)

module.magazineCapacity = nil -- Max ammo that can go in a mag
module.startAmmoPool 	= nil -- How much ammo should the gun start with?
module.maxAmmoPool 		= nil -- How much ammo can this gun hold?
module.reloadSpeedModifier = 1 -- 1 = Normal speed, higher = faster, lower = slower

module.fireRate 		= 1 -- How much does this affect the fire rate? 1 = normal, higher = faster, lower = slower
module.muzzleChance 	= nil -- Number from 0-10 that determines how often the muzzle will flash when firing
module.muzzleVelocity 	= 1200 -- this stat uses meters per second
module.bulletForce 		= nil -- If a bullet hits something unanchored, this force is applied
module.spread 			= 1 -- Adds some random variation to the bullet direction

module.shotgun 			= nil -- Does this turn the gun into a shotgun? Leave nil if it doesn't
module.shotgunPellets 	= nil -- If shotgun is true, how many pellets should be fired at once?


--/Damage Modification
module.damage = { -- how much should equipping this attachment multiply damage by? higher than 1 = damage incresaed by percentage e.g. 1.1 = 10% damage increase, 0.9 = 10% damage reduction 
	Head = 0.75, 
	Torso = 1.25,
	Other = 1, -- Default damage if body part is not included
}

--/Recoil Modification
module.recoil = {
	vertical =	   1, -- Vertical recoil
	horizontal =   1, -- Horizontal recoil
	camShake = 	   1, -- Camera shake
	damping = 	   1, -- How "springy" should the recoil be
	speed = 	   1, -- How quickly the recoil force will be recovered from
	aimReduction = 1 -- Recoil is divided by this when aiming
}

module.gunRecoil = {
	vertical = 	   1, -- Vertical recoil
	horizontal =   1, -- Horizontal recoil
	damping = 	   1, -- How "springy" should the recoil be
	speed = 	   1, -- How quickly the recoil force will be recovered from
	punchMultiplier = 1, -- How much the gun moves back during recoil
}				

return module