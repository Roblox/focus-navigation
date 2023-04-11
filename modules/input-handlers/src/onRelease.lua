--!strict
local Packages = script.Parent.Parent
local FocusNavigation = require(Packages.FocusNavigation)

local function onRelease(callback: FocusNavigation.EventHandler): FocusNavigation.EventHandler
	local hasStarted = false

	return function(event)
		local inputState = if event.eventData then event.eventData.UserInputState else nil

		if inputState == Enum.UserInputState.End and hasStarted then
			hasStarted = false
			callback(event)
			return true
		end

		if inputState == Enum.UserInputState.Begin then
			hasStarted = true
		end
		return false
	end
end

return onRelease
