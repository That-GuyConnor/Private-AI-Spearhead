-- Main game settings

local config = {}



-- Game settings

config.thirdPersonFiring = false -- Allow the player to fire from third person (unfinished)
config.arcadeBullets = false -- Gives bullets a faint streak similar to FE Gun Kit, looks pretty bad with tracers enabled

config.leaderboard = false -- Creates a simple kill death leaderboard
config.rblxDamageTags = true -- Include Roblox built in damage tags when counting kills

config.systemChat = true -- Sends messages in chat when players join, leave, and die
config.deathScreen = true -- Displays a screen after death with a respawn counter

config.fallDamage = true -- Should there be fall damage?
config.fallDamageDist = 19 -- Minimum distance to take damage
config.fallDamageMultiplier = 3 -- Damage taken = (fallDist - fallDamageDist) * fallDamageMultiplier

config.teamKill = true
config.teamTracers = true

config.firstPersonBody = true -- Should the player's body be visible in first person?
config.headRotation = true -- Should the head rotate when in third person
config.headRotationSpeed = 15
config.disableHeadRotation = false -- Disables head rotation
config.headRotationEventRate = 0.5 -- How often should head rotation be replicated
config.replicatedHeadRotationSpeed = 0.6 -- How quickly should other player's head's be rotated

config.useDeathCameraSubject = true -- If this is true, your camera will follow your corpse when you die

config.explosionRaycast = true -- Check with a raycast if players should be damaged

config.lockFirstPerson = true -- Can the player exit first person with a gun equipped?
-- DO NOT enable this setting if you want players to always be locked to first person
-- To do that, go to StarterPlayer and change the default CameraMode



-- Gun dropping settings

config.gunDropping = false
config.dropOnDeath = false
config.dropOnLeave = false
config.dropDespawnTime = 60 -- How long should guns stay on the ground?
config.maxDroppedGuns = 15 -- How many can be on the ground at once?
config.pickupDistance = 7



-- Movement settings

config.walkSpeed = 12
config.sprintSpeed = 18
config.crouchSpeed = 8
config.proneSpeed = 4
config.jumpPower = 20 -- SPH_R15: Limiting Jump Power
config.jumpHeight = 4 -- SPH_R15: Limiting Jump Height
config.jumpCooldown = 1 -- SPH_R15: Jump cooldown

--config.movementLeaning = true -- Will players lean into the direction they're moving?
config.replicateMovementLeaning = true -- Replicate other players leaning?
config.maxLeanAngle = 5 -- How far can players lean while moving

config.stanceChangeTime = 0.25 -- How long it takes to transition between stances

config.canLean = true -- Can the player lean around corners
config.canCrouch = true -- Can the player crouch
config.canProne = true -- Can the player go prone (This setting doesn't matter if canCrouch is false)



-- Input settings

-- To disable a keybind, set it to nil
-- config.example = nil

config.keySprint = Enum.KeyCode.LeftShift
config.keyReload = Enum.KeyCode.R
config.keyChamber = Enum.KeyCode.F
config.sightSwitch = Enum.KeyCode.T
config.freeLook = Enum.UserInputType.MouseButton3
config.lowerStance = Enum.KeyCode.C
config.raiseStance = Enum.KeyCode.X
config.holdUp = nil -- SPH_R15: Disabled this cause bipod (originally B)
config.holdPatrol = nil -- SPH_R15: Disabled this cause NVG (originally N)
config.holdDown = nil -- SPH_R15: Disabled this cause Inspect Animation or Map (originally M)
config.switchFireMode = Enum.KeyCode.V
config.leanLeft = Enum.KeyCode.Q
config.leanRight = Enum.KeyCode.E
config.dropKey = Enum.KeyCode.Backspace
config.pickupKey = Enum.KeyCode.G
config.toggleLaser = Enum.KeyCode.J
config.toggleFlashlight = Enum.KeyCode.H
config.ToggleBipod = Enum.KeyCode.B 			-- SPH_R15: Bipod
config.holdForScollZoom = Enum.KeyCode.LeftControl



-- Performance settings

config.animDistance = 1000 -- Maximum distance to see a player's animations
config.fireEffectDistance = 4000 -- Maximum distance for firing effects to be replicated
config.maxBulletDistance = 6000 -- Bullets that fly further than this distance will be deleted
config.maxHitDistance = 1000 -- Maximum distance to see bullet hit effects

config.ragdolls = true -- Should players ragdoll on death?
config.bodyDespawn = 60 -- Bodies are removed after this time
config.bodyLimit = 15 -- Maximum number of bodies

config.shellEjection = true -- Game-wide override for shell ejection
config.shellDistance = 50 -- Shells won't be ejected beyond this distance
config.shellMaxCount = 30 -- Maximum that can be on the ground at once
config.shellDespawn = 3 -- Shells are auto deleted after this amount of time

config.firstPersonHolsters = false -- Should holsters be shown in first person? (Very laggy if you have too many holsters at once)
config.blurEffects = false -- Experimental stuff with depth of field

config.despawnEmptyAmmoBoxes = true -- Should empty ammo boxes be destroyed after some time?
config.ammoBoxDespawnTime = 10

config.maxBullets = 500 -- Maximum number of bullets that are cached (Cache size will temporarily increase if this is exceeded)



-- Physics settings

config.bulletAcceleration = Vector3.new(0, -workspace.Gravity, 0) -- This is used for the bullet drop force
config.useBulletForce = false -- Should bullet impacts be able to push things around?



-- Viewmodel settings

config.breathingSpeed = 0 -- Speed of the breathing cycle
config.breathingDist = 0.03 -- Distance the viewmodel will move while breathing
config.breathingAimMultiplier = 0.17 -- Breathing dist is multiplied by this when aiming, the closer this number is to 1 the more breathing there is

config.bobSpeed = 10 -- How quickly the viewmodel should move back and forth, this is scaled based on walk speed
config.bobDampening = 20 -- Higher number = less bobbing
config.aimBobDampening = 2 -- Higher number = less bobbing while aiming
config.cameraMovement = true -- Should the camera bob around?
config.cameraBobDampening = 2 -- Higher number = less bobbing
config.cameraTilting = false -- Should the camera tilt when looking and moving around?

config.hipfireMove = true -- Allows you to move your gun off center while hip firing
config.hipfireMoveX = 15 -- Max angle that the gun can move horizontally
config.hipfireMoveY = 10 -- Max angle that the gun can move vertically
config.hipfireMoveSpeed = 0.05
config.offCenterAiming = false -- Allow the player to move off center while aiming

config.pushBackViewmodel = true -- Should the gun move back when getting close to a wall?
config.raiseGunAtWall = true -- Should the gun be raised when too close to a wall? 

config.fireWithFreelook = false -- Can the player fire their gun while freelook is active?


-- Effects settings

config.lowHealthEffects = true -- Low health gui and reduced movement speed
config.suppressionEffects = true -- Tunnel vision and crack sounds
config.footstepSounds = true -- Replaces the default walk sound with material based sounds

config.tracerStartDistance = 15 -- Tracers and arcade bullets don't appear until they're this distance away from you
config.fireSoundVariation = 500 -- Lowering this number increases the variation in pitch (playback speed) of fire and echo sounds

config.firstPersonEcho = true -- If this is set to false other players will hear echo sounds, but not yourself

config.laserTrail = true -- Should lasers have a trail

config.hitMarkerSound = true -- SPH_R15: Sound plays when player scores a hit.
-- Version

config.version = "v1.1.3 - SPH_R15 v1.33"

return config