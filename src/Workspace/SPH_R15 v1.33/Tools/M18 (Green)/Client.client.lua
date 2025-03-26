local Player = game:GetService("Players").LocalPlayer
local UIS = game:GetService("UserInputService")
local Mouse = Player:GetMouse()
local Tool = script.Parent
local Remote = Tool:WaitForChild("Remote")
local Anim = Tool:WaitForChild("Anim")
--local Tracks = {}
local InputType = Enum.UserInputType
local IsEquipped = false
local BeganConnection, EndedConnectionl
local ThrowBeganConnection, ThrowEndedConnectionl
local Power = script.Parent.Config.Velocity.Value


--function playAnimation(animName)
--	if Tracks[animName] then
--		Tracks[animName]:Play()
--	else
--		local anim = Tool:FindFirstChild(animName)
--		if anim and Tool.Parent and Tool.Parent:FindFirstChild("Humanoid") then
--			Tracks[animName] = Tool.Parent.Humanoid:LoadAnimation(anim)
--			playAnimation(animName)
--		end
--	end
--end

--function stopAnimation(animName)
--	if Tracks[animName] then
--		Tracks[animName]:Stop()
--	end
--end

function inputBegan(input)
	if input.UserInputType == InputType.MouseButton1 then
		if Power == 150 then
			Anim:FireServer("Idle", false)
			Anim:FireServer("High", true)
			script.Parent.Handle.Pin:Play()
			wait(1.12)
			local lp = game.Players.LocalPlayer
			local ms = lp:GetMouse()
			if not IsEquipped then return end
			Remote:FireServer(ms.Hit)
			Player.PlayerGui.Menu:destroy()
			game.Players.LocalPlayer.CameraMode = Enum.CameraMode.Classic

		elseif Power == 100 then
			Anim:FireServer("Idle", false)
			Anim:FireServer("Med", true)
			script.Parent.Handle.Pin:Play()
			wait(1.12)
			local lp = game.Players.LocalPlayer
			local ms = lp:GetMouse()
			if not IsEquipped then return end
			Remote:FireServer(ms.Hit)
			Player.PlayerGui.Menu:destroy()
			game.Players.LocalPlayer.CameraMode = Enum.CameraMode.Classic

		elseif Power == 65 then
			Anim:FireServer("Idle", false)
			Anim:FireServer("Low", true)
			script.Parent.Handle.Pin:Play()
			wait(1.12)
			local lp = game.Players.LocalPlayer
			local ms = lp:GetMouse()
			if not IsEquipped then return end
			Remote:FireServer(ms.Hit)
			Player.PlayerGui.Menu:destroy()
			game.Players.LocalPlayer.CameraMode = Enum.CameraMode.Classic

		end
	elseif input.UserInputType == InputType.MouseButton2 then
		local textbox = Player.PlayerGui.Menu.Frame.Frame2.Frame3.Distance
		if Power < 65 then
			Power = 65
			script.Parent.Power:FireServer(Power)
			wait(0.1)
			textbox.Text = "Low Throw"
			Anim:FireServer("Idle", true)
		elseif Power == 65 then
			Power = 100
			script.Parent.Power:FireServer(Power)
			wait(0.1)
			textbox.Text = "Mid Throw"
		elseif Power == 100 then
			Power = 150
			script.Parent.Power:FireServer(Power)
			wait(0.1)
			textbox.Text = "High Throw"
		elseif Power == 150 then
			Power = 65
			script.Parent.Power:FireServer(Power)
			wait(0.1)
			textbox.Text = "Low Throw"
		end
	end
end

--function ThrowType(input, gameProcessed)
--	if input.UserInputType == Enum.UserInputType.Keyboard then
--		if input.KeyCode == Enum.KeyCode.F then
--			Power = 65
--			script.Parent.Power:FireServer(Power)
--			wait(0.1)
--			local textbox = Player.PlayerGui.Menu.Frame.Frame2.Frame3.Distance
--			textbox.Text = "Low Throw"
--		elseif input.KeyCode == Enum.KeyCode.G then
--			Power = 100
--			script.Parent.Power:FireServer(Power)
--			wait(0.1)
--			local textbox = Player.PlayerGui.Menu.Frame.Frame2.Frame3.Distance
--			textbox.Text = "Medium Throw"
--		elseif input.KeyCode == Enum.KeyCode.H then
--			Power = 150
--			script.Parent.Power:FireServer(Power)
--			wait(0.1)
--			local textbox = Player.PlayerGui.Menu.Frame.Frame2.Frame3.Distance
--			textbox.Text = "High Throw"
--		end
--	end
--end

function onEquip()
	BeganConnection = UIS.InputBegan:connect(inputBegan)

	--ThrowBeganConnection = UIS.InputBegan:Connect(ThrowType)
	IsEquipped = true

end

function onUnequip()
	if BeganConnection then
 
		Anim:FireServer("Idle", false)
 
		BeganConnection:disconnect()
		--ThrowBeganConnection:disconnect()
		BeganConnection = nil
		ThrowBeganConnection = nil
		IsEquipped = false
	end
end



Tool.Equipped:connect(onEquip)
Tool.Unequipped:connect(onUnequip)
--Player.Died:connect(onDeath)