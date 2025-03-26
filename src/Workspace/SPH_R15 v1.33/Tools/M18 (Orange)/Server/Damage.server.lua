local Object = script.Parent
local Used = false

local Debris = game:GetService("Debris")


function Explode()
	wait(3)
	Object.Emitter.Sparks:Emit(40)
	Object.Fuse.Playing = true
	Object.Emitter.Smoke1.Enabled = true
	Object.Emitter.Smoke2.Enabled = true
	Object.Emitter.Smoke3.Enabled = true
	wait(1)
	Object.Emitter.Smoke1.Enabled = false
	wait(69)
	Object:Destroy()
end


--use this to determine if you want this human to be harmed or not, returns boolean
Explode()