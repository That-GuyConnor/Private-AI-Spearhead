local playerServer = game:GetService("Players")
local starterGui = game:GetService("StarterGui")
local replicatedStorage = game:GetService("ReplicatedStorage")

local bridgeNet = require(replicatedStorage.SPH_Assets.Modules.BridgeNet)
local sysMessage = bridgeNet.CreateBridge("SystemMessage")

local config = require(replicatedStorage.SPH_Assets.GameConfig)
if config.systemChat then
	sysMessage:Connect(function(message,color)
		starterGui:SetCore("ChatMakeSystemMessage",{
			Text = message,
			Color = color,
		})
	end)
end