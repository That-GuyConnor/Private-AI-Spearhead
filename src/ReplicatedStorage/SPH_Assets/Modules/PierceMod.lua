-- This module handles bullet piercing

local players = game:GetService("Players")
local module = {}
local collectionService = game:GetService("CollectionService")

local function IsInHumanoid(Inst)
	while Inst.Parent do
		if Inst.Parent:FindFirstChild("Humanoid") then
			return Inst.Parent.Humanoid
		else
			Inst = Inst.Parent
		end
	end
	return false
end

module.CanPierce = function(cast, rayResult, segmentVelocity)
	local hitPart = rayResult.Instance
	local Humanoid = IsInHumanoid(hitPart)
	if cast.UserData.IgnoreModel and hitPart:IsDescendantOf(cast.UserData.IgnoreModel) then
		return true
	elseif Humanoid then
		local player = players:GetPlayerFromCharacter(Humanoid.Parent)
		if player and cast.UserData.Player == player then
			return true
		elseif hitPart.Parent:IsA("Accoutrement") or (hitPart.Parent:IsA("Model") and hitPart.Parent ~= Humanoid.Parent) then
			return true
		end
		return false
	elseif collectionService:HasTag(hitPart,"SPH_Collide") or collectionService:HasTag(hitPart,"Dragoon_Armor") then -- SPH_R15: Dragoon Tank System Compat
		return false
	elseif hitPart.Transparency == 1 or not hitPart.CanCollide or hitPart.Name == "Ignore" or collectionService:HasTag(hitPart,"SPH_NoCollide") then
		return true
	end
	return false
end

return module
