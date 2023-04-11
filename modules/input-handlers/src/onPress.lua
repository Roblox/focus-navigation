--!strict
local Packages = script.Parent.Parent
local FocusNavigation = require(Packages.FocusNavigation)

local function onPress(callback: FocusNavigation.EventHandler): FocusNavigation.EventHandler
	return function(event)
		local inputState = if event.eventData then event.eventData.UserInputState else nil
		if inputState == Enum.UserInputState.Begin then
			callback(event)
			return true
		end
		return false
	end
end

return onPress
