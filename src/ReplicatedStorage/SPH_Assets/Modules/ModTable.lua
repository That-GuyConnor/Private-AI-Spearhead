local ModTable = {}


ModTable = {
	aimFovMinMod		= 1
	,AimTimeMod			= 1 -- 1 = normal aim time, higher = faster, lower = slower

	,gunLengthMod		= 0
	,IsSuppressor		= false

	,EnableLaserAtt		= nil
	,EnableFlashlightAtt= nil
	,laserAtt			= nil
	,flashlightAtt 		= nil
	,bipodAtt			= nil
	
	,isRangefinder		= false --  SPH_R15: Rangefinder

	,recoilMod = {
		vertical =	   1, -- Vertical recoil
		horizontal =   1, -- Horizontal recoil
		camShake = 	   1, -- Camera shake
		damping = 	   1, -- How "springy" should the recoil be
		speed = 	   1, -- How quickly the recoil force will be recovered from
		aimReduction = 1 -- Recoil is divided by this when aiming
	}

	,gunRecoilMod = {
		vertical = 	   1, -- Vertical recoil
		horizontal =   1, -- Horizontal recoil
		damping = 	   1, -- How "springy" should the recoil be
		speed = 	   1, -- How quickly the recoil force will be recovered from
		punchMultiplier = 1, -- How much the gun moves back during recoil
	}	

	,damage = {
		Head = 1,
		Torso = 1,
		Other = 1, -- Default damage if body part is not included
	}

	,ammoType 			= nil -- what type of ammo does it eject?
	,tracers			= nil
	,tracerTiming 		= nil -- Every x number of shots will be a tracer
	,tracerColor 		= nil

	,magazineCapacity 	= nil -- Max ammo that can go in a mag
	,startAmmoPool 		= nil -- How much ammo should the gun start with?
	,maxAmmoPool 		= nil -- How much ammo can this gun hold?
	,reloadSpeedModifier = 1 -- 1 = Normal speed, higher = faster, lower = slower

	,fireRate 			= 1
	,muzzleChance 		= nil -- Number from 0-10 that determines how often the muzzle will flash when firing
	,muzzleVelocity 	= nil -- this stat uses meters per second
	,bulletForce 		= nil -- If a bullet hits something unanchored, this force is applied
	,spread 			= 1 -- Adds some random variation to the bullet direction
	,shotgun 			= nil 
	,shotgunPellets 	= nil -- If shotgun is true, how many pellets should be fired at once?
} 

return ModTable