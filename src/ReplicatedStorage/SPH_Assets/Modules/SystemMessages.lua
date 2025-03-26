local module = {}

module.Messages = {
	Killed = {
		"was killed by",
		"was neutralized by",
		"was put out of action by",
		"had their life stolen by",
		"was oof'd by",
		"died of wounds inflicted by",
	},
	Falling = {
		"didn't stick the landing",
		"fell from a tall height",
		"shattered their legs",
		"forgot their parachute",
	},
	Death = {
		"died of mysterious circumstances..",
		"experienced a sudden heart attack",
		"was unable to be saved",
		"inexplicably died",
		"lost all motor functions",
		"met their creator",
		"took their last breath",
	}
}

module.GetMessage = function(msgType)
	local messageList = module.Messages[msgType]
	return messageList[math.random(#messageList)]
end

return module
