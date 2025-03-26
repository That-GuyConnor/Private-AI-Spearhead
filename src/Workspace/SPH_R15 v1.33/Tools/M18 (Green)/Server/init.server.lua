local Tool = script.Parent
local Remote = Tool:WaitForChild("Remote")
local Handle = Tool:WaitForChild("Handle")
local Anim = Tool:WaitForChild("Anim")
local DamageScript = script:WaitForChild("Damage")
local Config = Tool:WaitForChild("Config")
local Heartbeat = game:GetService("RunService").Heartbeat

local Tracks = {} -- animations are serverside now

local LeftDown = false

local AttackAble = true
local AttackVelocity = Config.Velocity.Value

local Character = nil
local Humanoid = nil

--returns the wielding player of this tool
function getPlayer()
	local char = Tool.Parent
	return game:GetService("Players"):GetPlayerFromCharacter(Character)
end

function playAnimation(animName)
	if Tracks[animName] then
		Tracks[animName]:Play()
	else
		local anim = Tool:FindFirstChild(animName)
		if anim and Tool.Parent and Tool.Parent:FindFirstChild("Humanoid") then
			Tracks[animName] = Tool.Parent.Humanoid:LoadAnimation(anim)
			playAnimation(animName)
		end
	end
end

function stopAnimation(animName)
	if Tracks[animName] then
		Tracks[animName]:Stop()
	end
end

function Toss(direction)
	local handlePos = Vector3.new(Tool.Handle.Position.X, 0, Tool.Handle.Position.Z)
	local spawnPos = Character.Head.Position
	spawnPos  = spawnPos + (direction * 5)
	Tool.Handle.Transparency = 1
	local Object = Tool.Handle:Clone()
	Object._Pin.Transparency = 1
	Object.Parent = workspace
	Object.Transparency = 1
	Object.Swing.Pitch = math.random(90, 110)/100
	Object.Swing:Play()
	Object.CanCollide = true
	Object.CFrame = Tool.Handle.CFrame
	Object.Velocity = (direction*AttackVelocity) + Vector3.new(0,AttackVelocity/7.5,0)
	Object.Trail.Enabled = true
	--Object.Fuse:Play()
	--Object.Sparks.Enabled = true
	local rand = 11.25
	Object.RotVelocity = Vector3.new(math.random(-rand,rand),math.random(-rand,rand),math.random(-rand,rand))
	Object:SetNetworkOwner(getPlayer())
	local ScriptClone = DamageScript:Clone()
	ScriptClone.Parent = Object
	ScriptClone.Disabled = false
	local tag = Instance.new("ObjectValue")
	tag.Value = getPlayer()
	tag.Name = "creator"
	tag.Parent = Object
	Tool:Destroy()
end


script.Parent.Power.OnServerEvent:Connect(function(player, Power)
	AttackVelocity = Power
end)

Anim.OnServerEvent:Connect(function(player, animation, play)
	if play == true then
		playAnimation(animation)
	else
		stopAnimation(animation)
	end
end)

Remote.OnServerEvent:Connect(function(player, mousePosition)
	if not AttackAble then return end
	AttackAble = false
	if Humanoid and Humanoid.RigType == Enum.HumanoidRigType.R15 then
		Remote:FireClient(getPlayer(), "PlayAnimation", "Animation")
	end
	local targetPos = mousePosition.p
	local lookAt = (targetPos - Character.Head.Position).unit
	Toss(lookAt)
	LeftDown = true
end)

function onLeftUp()
	LeftDown = false
end

Tool.Equipped:Connect(function()
	Character = Tool.Parent
	Humanoid = Character:FindFirstChildOfClass("Humanoid")
end)

Tool.Unequipped:Connect(function()
	Character = nil
	Humanoid = nil
end)