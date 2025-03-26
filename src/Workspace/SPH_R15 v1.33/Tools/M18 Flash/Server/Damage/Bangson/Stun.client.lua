



local TweenService = game:GetService("TweenService")
 

if script.Parent.Parent.Parent.CurrentCamera:FindFirstChild("Stun") ~= nil then
	script.Parent.Parent.Parent.CurrentCamera:FindFirstChild("Stun"):Destroy()
end

local guiMain = Instance.new("ColorCorrectionEffect") 
			guiMain.Parent = script.Parent.Parent.Parent.CurrentCamera 
			guiMain.Brightness = script.Parent.Brightness.Value
			guiMain.Name = "Stun"
 
local tweenInfo = TweenInfo.new(
	script.Parent.Time.Value, -- Time
	Enum.EasingStyle.Linear, -- EasingStyle
	Enum.EasingDirection.InOut, -- EasingDirection
	0, -- RepeatCount (when less than zero the tween will loop indefinitely)
	false, -- Reverses (tween will reverse once reaching it's goal)
	0 -- DelayTime
)
 
local tween = TweenService:Create(guiMain, tweenInfo, {Brightness = 0})
tween:Play()

wait(script.Parent.Time.Value + .5)

guiMain:Destroy()
script.Parent:Destroy()