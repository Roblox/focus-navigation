local Packages = script.Parent.Parent
local React = require(Packages.React)
local RoactNavigation = require(Packages.RoactNavigation)
local ReactFocusNavigation = require(Packages.ReactFocusNavigation)

local useLastInputDevice = require(script.Parent.hooks.useLastInputDevice)

local function CaptureFocusOnMount()
	local ref = React.useRef(nil)
	local focusGuiObject = ReactFocusNavigation.useFocusGuiObject()
	local lastInputDevice = useLastInputDevice()

	return React.createElement(
		"Folder",
		{ ref = ref },
		React.createElement(RoactNavigation.NavigationEvents, {
			onDidFocus = function()
				if lastInputDevice == "Keyboard" or lastInputDevice == "Gamepad" then
					if ref.current and ref.current.Parent then
						focusGuiObject(ref.current.Parent)
					end
				end
			end,
		})
	)
end

return CaptureFocusOnMount
