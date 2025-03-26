local Object = script.Parent
local Used = false

--local Engine = game.ReplicatedStorage:WaitForChild("ACS_Engine")
--local Evt = Engine:WaitForChild("Events")

local IgnoreModel = {Object}

local SplashDamage = 5
local Radius = 90
local GrenadeArmorFactor = 0

local Debris = game:GetService("Debris")

function OnExplosionHit(Character, hitDistance, blastCenter)
	local Humanoid = Character:FindFirstChild("Humanoid")
	if hitDistance and blastCenter then
		local DistanceFactor = hitDistance/Radius
		DistanceFactor = 1-DistanceFactor

		if Humanoid then
			if Humanoid.Health > 0 then
				local guiMain = script.Bangson:Clone()
				guiMain.Time.Value = .1 * DistanceFactor
				guiMain.Brightness.Value = 5 * DistanceFactor
				guiMain.Parent = Character
				guiMain.Stun.Disabled = false
			end
		end
	end
end



fpor = game.Workspace.FindPartOnRay
seen_dist = 90
function canSee(subject,viewer)
	if (not subject) or (not viewer) then return false end
	local sh = subject
	local vh = viewer:findFirstChild("Head")
	if (not sh) or (not vh) then return false end
	local vec = sh.Position - vh.Position
	local isInFOV = (vec:Dot(vh.CFrame.lookVector) > 0)
	if (isInFOV) and (vec.magnitude < seen_dist) then
		local ray = Ray.new(vh.Position,vec.unit*200)
		local por = fpor(workspace,ray,viewer,false)
		return (por == nil) or (por:IsDescendantOf(subject))
	end
	return false
end

function CheckForHumanoid(L_225_arg1)
	local L_226_ = false
	local L_227_ = nil
	if L_225_arg1 then
		if (L_225_arg1.Parent:FindFirstChildOfClass("Humanoid") or L_225_arg1.Parent.Parent:FindFirstChildOfClass("Humanoid")) then
			L_226_ = true
			if L_225_arg1.Parent:FindFirstChildOfClass('Humanoid') then
				L_227_ = L_225_arg1.Parent:FindFirstChildOfClass('Humanoid')
			elseif L_225_arg1.Parent.Parent:FindFirstChildOfClass('Humanoid') then
				L_227_ = L_225_arg1.Parent.Parent:FindFirstChildOfClass('Humanoid')
			end
		else
			L_226_ = false
		end	
	end
	return L_226_, L_227_
end

function Explode()
	Object.Sparks2:Emit(5)
	Object.Sparks3:Emit(5)
	Object.Sparks4:Emit(5)
	Object.Sparks5:Emit(5)
	
	local Light = Instance.new("PointLight")
	Light.Color = Color3.fromRGB(255, 255, 255)
	Light.Brightness = 100
	Light.Range = Radius
	Light.Shadows = true
	Light.Parent = Object

	local Explosion = Instance.new("Explosion")
	Explosion.BlastRadius = Radius*.875
	Explosion.BlastPressure = 0
	Explosion.Position = Object.Position
	Explosion.Parent = Object
	Explosion.Visible = false

	Explosion.Hit:Connect(function(hit, distance)
		if hit.Name == "HumanoidRootPart" and hit.Parent:FindFirstChild("Humanoid") then
			OnExplosionHit(hit.Parent, distance, Object.Position)
		end
	end)


	for i,v in pairs(game.Players:GetPlayers())do
		if v.Character then
			if v.Character:FindFirstChild("HumanoidRootPart") then
				local HM = v.Character:FindFirstChild("HumanoidRootPart")
				if (HM.Position - Object.Position).magnitude <= Radius then

					local ray = Ray.new(Object.Position, (HM.Position - Object.Position).unit * 1000)
					local part, position = workspace:FindPartOnRay(ray, Object, false, true)
					
					if part then
						local FoundHuman,VitimaHuman = CheckForHumanoid(part)
						if FoundHuman and VitimaHuman.Health > 0 then
							local guiMain = script.Bangson:Clone()
							guiMain.Time.Value = 10 * (((((HM.Position - Object.Position).magnitude)/Radius) - 1) *-1)
							guiMain.Brightness.Value = 5 * (((((HM.Position - Object.Position).magnitude)/Radius) - 1) *-1)
							guiMain.Parent = VitimaHuman.Parent
							guiMain.Bang.Disabled = false
							--Evt.Suppression:FireClient(v,3,0,10)
						end
					end
				end
			end
		end
	end



	wait(.05)
	Light:Destroy()
	wait(3)
	Object:Destroy()
end

--helpfully checks a table for a specific value
function contains(t, v)
	for _, val in pairs(t) do
		if val == v then
			return true
		end
	end
	return false
end

--used by checkTeams

--use this to determine if you want this human to be harmed or not, returns boolean

function boom()
	wait(1.5)
	Used = true
	Object.Anchored = true
	Object.Transparency = 1
	Object.CanCollide = false
	Object.Explode:Play()

	Explode()
end

boom()