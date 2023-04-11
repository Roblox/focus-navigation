--!strict
local Packages = script.Parent.Parent
local FocusNavigation = require(Packages.FocusNavigation)

-- TODO: figure out type for the completion callback
type Callback = ({ [any]: any }) -> ()

local function onLongPress(callback: Callback, durationSeconds: number): FocusNavigation.EventHandler
	local queuedCallback: thread? = nil

	return function(event)
		local inputState = if event.eventData then event.eventData.UserInputState else nil

		-- TODO: what about `Change`?
		if inputState == Enum.UserInputState.End then
			if queuedCallback then
				task.cancel(queuedCallback)
				queuedCallback = nil
			end
		end

		if inputState == Enum.UserInputState.Begin then
			if queuedCallback then
				if queuedCallback then
					task.cancel(queuedCallback)
					queuedCallback = nil
				end
			end
			queuedCallback = task.delay(durationSeconds, function()
				callback({ placeholder = "hello" })
			end)
		end

		-- TODO: should we return something about having sunk an input so that
		-- composition can simply handle inputs in sequence?

		-- TODO: should we accept a parameter for something like an onStep
		-- callback to trigger for animations?
	end
end

return onLongPress
