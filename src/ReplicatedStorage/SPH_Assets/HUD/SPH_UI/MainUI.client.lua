local players = game:GetService("Players")
local runService = game:GetService("RunService")
local assets = game:GetService("ReplicatedStorage").SPH_Assets
local player = players.LocalPlayer
local character = player.Character or player.CharacterAppearanceLoaded:Wait()
local tool, magAmmo, ammoPool
local dead = false
local wepStats

local ammoUI = script.Parent.Ammo

script.Parent.Version.Text = "Spearhead "..require(assets.GameConfig).version

local ammoCounter = ammoUI.Ammo.Ammo.AmmoLabel
local ammoPoolUI = ammoUI.Ammo.Ammo.MagazineLabel
local bulletType = ammoUI.Other.AmmoType
local fireMode = ammoUI.Firemode.Firemode
local chambered = ammoUI.Ammo.Ammo.Chambered

-- SPH_R15 Modification: Text flashes to notify you of your aim sensitivity
local TweenService = game:GetService("TweenService")
local userInputService = game:GetService("UserInputService")
local tween   = TweenInfo.new(0.25, Enum.EasingStyle.Quart)
local aimSens = ammoUI.Firemode.Sens
-- </SPH_R15>

local fireModeNames = {"SAFE", "[SEMI]", "[AUTO]", "[BURST]", "[MANUAL]"}

-- Jarr's edited UI
function splitNumber(number) --thanks AI for doing the stuff im too lazy for
	local numberStr = tostring(number)
	local leadingZeros = ""
	local restOfNumber = numberStr

	-- Calculate the number of leading zeros needed
	local totalLength = 3
	local leadingZerosCount = totalLength - #numberStr

	-- Add leading zeros if necessary
	if leadingZerosCount > 0 then
		for i = 1, leadingZerosCount do
			leadingZeros = leadingZeros .. "0"
		end
	end

	-- If the number is longer than 3 digits, take the last 3 digits only
	if #numberStr > totalLength then
		restOfNumber = numberStr:sub(-totalLength)
		leadingZeros = ""
	end

	return {leadingZeros, restOfNumber}
end
-- </Jarr's edited UI>

character.ChildAdded:Connect(function(newChild)
	if newChild:FindFirstChild("SPH_Weapon") and assets.WeaponModels:FindFirstChild(newChild.Name) and not dead then
		tool = newChild
		magAmmo = tool:WaitForChild("Ammo").MagAmmo
		ammoPool = tool.Ammo.ArcadeAmmoPool
		wepStats = require(tool.SPH_Weapon.WeaponStats)
		bulletType.Text = wepStats.ammoType
		if wepStats.AmmoAtt and wepStats.AmmoAtt ~= "" then
			local aData = require(assets.AttModules[wepStats.AmmoAtt])
			if aData.ammoType then
				bulletType.Text = wepStats.ammoType.." "..aData.ammoType
			end
		end
	end
end)

character.ChildRemoved:Connect(function(oldChild)
	if oldChild == tool then
		tool = nil
	end
end)

runService.Heartbeat:Connect(function()
	if tool and tool:FindFirstChild("Chambered") and magAmmo and not dead then
		if character.Humanoid.SeatPart ~= nil and character.Humanoid.SeatPart.ClassName == "VehicleSeat" then return end -- SPH_R15: UI automatically hides while driving a vehicle
		ammoUI.Visible = true
		if not wepStats.operationType or type(wepStats.operationType) == "string" then wepStats.operationType = 1 end
		if wepStats.operationType == 4 and tool.Chambered.Value then
			local digits = splitNumber(magAmmo.Value+1)
			ammoCounter.Text = [[<font transparency="0.5">]]..digits[1]..[[</font>]]..digits[2]
		else
			local digits = splitNumber(magAmmo.Value)
			ammoCounter.Text = [[<font transparency="0.5">]]..digits[1]..[[</font>]]..digits[2]
		end
		ammoPoolUI.Text = "/"
		if wepStats.infiniteAmmo then
			ammoPoolUI.Text = ammoPoolUI.Text.."INF"
		else
			--ammoPoolUI.Text = ammoPoolUI.Text..ammoPool.Value
			local digits = splitNumber(ammoPool.Value)
			ammoPoolUI.Text = ammoPoolUI.Text..[[<font transparency="0.5">]]..digits[1]..[[</font>]]..digits[2]
			if ammoPool.Value > 0 then
				ammoPoolUI.TextColor3 = Color3.fromRGB(157,235,164)
			else
				ammoPoolUI.TextColor3 = Color3.new(1,0,0)				
			end
		end
		if tool.FireMode.Value == 0 then
			ammoCounter.TextColor3 = Color3.new(0.5,0.5,0.5)
		elseif tool.Chambered.Value then
			if wepStats.operationType < 4 then
				chambered.TextTransparency = 0
			end
			ammoCounter.TextColor3 = Color3.fromRGB(157, 235, 164)
		else
			chambered.TextTransparency = 1
			ammoCounter.TextColor3 = Color3.new(1, 0, 0)
		end
		fireMode.Text = fireModeNames[tool.FireMode.Value + 1]
		aimSens.Text = string.format("%.2f", userInputService.MouseDeltaSensitivity)


		-- SPH_R15: Rangefinder
		local physicalRangefinder = nil
		local sight = nil
		if wepStats.SightAtt then
			sight = game.Workspace.Camera.WeaponRig.Weapon[tool.Name]:FindFirstChild(wepStats.SightAtt)
		else
			sight = game.Workspace.Camera.WeaponRig.Weapon[tool.Name]
		end
		if sight and sight:FindFirstChild("SightReticle") then
			if sight.SightReticle.SurfaceGui.Frame.Reticle:FindFirstChild("Frame") then
				if sight.SightReticle.SurfaceGui.Frame.Reticle.Frame:FindFirstChild("Range") then
					physicalRangefinder = sight.SightReticle.SurfaceGui.Frame.Reticle.Frame.Range
				end
			end
		end
		if player:GetAttribute("rangefinderActive") then
			ammoUI.TargetRange.Visible = true
			if physicalRangefinder then
				physicalRangefinder.Visible = true
			end
			if player:GetAttribute("tgtDistance") then
				ammoUI.TargetRange.Text = "Distance: "..math.floor(player:GetAttribute("tgtDistance")).." m"
				if physicalRangefinder then
					physicalRangefinder.Text = math.floor(player:GetAttribute("tgtDistance"))
				end
			else
				ammoUI.TargetRange.Text = "Distance: --- m"
				if physicalRangefinder then
					physicalRangefinder.Text = "--"
				end
			end
		else
			ammoUI.TargetRange.Visible = false
			if physicalRangefinder then
				physicalRangefinder.Visible = false
			end
		end
		-- </SPH_R15>

		-- WATCHMOD II: Gun Screen
		local screen = game.workspace.Camera.WeaponRig.Weapon[tool.Name]:FindFirstChild("GunScreen")
		if screen then
			local frame = screen.ScreenUI.sFrame
			frame.Visible = true
			frame.Ammo.Text = magAmmo.Value
			frame.AmmoBar.Size = UDim2.new(((magAmmo.Value / magAmmo.MaxValue) * frame.AmmoBar.OriginalXScale.Value), 0, frame.AmmoBar.Size.Y.Scale, 0)
			if magAmmo.Value > 5 then
				frame.Ammo.TextColor3 = frame.BackgroundColor3
			else
				frame.Ammo.TextColor3 = frame.BorderColor3
			end
			frame.FireMode.Text = fireModeNames[tool.FireMode.Value + 1]
			frame.FireMode.TextColor = frame.BackgroundColor
			if tool.Chambered.Value then
				frame.Chamber.Visible = true
			else
				frame.Chamber.Visible = false
			end
			--</WATCHMOD_II>
		end
	else
		ammoUI.Visible = false
	end
end)

character.Humanoid.Died:Connect(function()
	dead = true
end)