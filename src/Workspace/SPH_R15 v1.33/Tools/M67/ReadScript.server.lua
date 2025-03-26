local tool = script.Parent ---Leave these alone.
local gui

local function readBook()
	local player = game.Players:getPlayerFromCharacter(tool.Parent)
	if player.PlayerGui:findFirstChild("Menu") == nil then --- Change "Menu" to the Gui you named.
		gui = tool.Menu:Clone()
		gui.Parent = player.PlayerGui
	elseif player.PlayerGui:findFirstChild("Menu") ~= nil then
		player.PlayerGui:findFirstChild("Menu"):destroy()
		gui = tool.Menu:Clone()
		gui.Parent = player.PlayerGui
	end
end

local function closeBook()
	wait()
	if gui then gui:Destroy() end
end

tool.Equipped:connect(readBook)
tool.Unequipped:connect(closeBook)