local Packages = script.Parent.Parent
local React = require(Packages.React)
local RoactNavigation = require(Packages.RoactNavigation)
local ReactFocusNavigation = require(Packages.ReactFocusNavigation)
local useFocusGuiObject = ReactFocusNavigation.useFocusGuiObject
local useLastInputMethod = ReactFocusNavigation.useLastInputMethod

local function CaptureFocusOnMount()
	local ref = React.useRef(nil)
	local focusGuiObject = useFocusGuiObject()
	local lastInputMethod = useLastInputMethod()

	return React.createElement(
		"Folder",
		{ ref = ref },
		React.createElement(RoactNavigation.NavigationEvents, {
			onDidFocus = function()
				if lastInputMethod == "Keyboard" or lastInputMethod == "Gamepad" then
					if ref.current and ref.current.Parent then
						focusGuiObject(ref.current.Parent)
					end
				end
			end,
		})
	)
end

return CaptureFocusOnMount
