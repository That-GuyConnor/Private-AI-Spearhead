local Config = {}

-- lens distortion & limited PiP with glass material
-- warning : glass will not render transparent parts or any particle effect
--			 glass will only have zoom with 8+ graphics setting
-- 			 glass will have varying zoom depending on AimPart's distance from the scope
--			 high magnification glass will be low quality, and misalign reticles
--			 if your ACS has custom DOF effects i recommend setting the FarIntensity to 1, the glass will remove the blur
Config.useGlassEffect = false
Config.glassColor = Color3.fromRGB(255, 255, 255)
Config.glassTransparency = 0.6 -- lower will have more zoom
Config.glassOffset = .1 -- depth offset from scope part
Config.glassZoomFactor = .04 -- recommended 0.03 - 0.1

-- y = tan(x * focusSensitivity) / eyeboxCurve
-- https://www.desmos.com/calculator/z7r04qiqxm
Config.focusSensitivity = 15 -- sensitivity of lens focus/eye relief. higher magnification will be more sensitive
Config.eyeboxCurve = 5 -- exponential curve of which ocular lens shadow moves/increases

-- by default, eye relief/distance is perfectly centered from the AimPart's position. if you need to offset it change this
Config.eyeReliefOffset = 0
-- manual scale of each lens overlay. unrealistic
Config.ocularLensScale = 1
Config.objectiveLensScale = 1

-- CA = chromatic aberration, some scopes will have more or less
Config.ocularCASensitivity = 10
Config.ocularCADeadzone = 0
Config.objectiveCASensitivity = 10
Config.objectiveCADeadzone = 0

-- sensitivity of light when unfocused
Config.lightSensitivity = 3
Config.lightDeadzone = 0.4

return Config
