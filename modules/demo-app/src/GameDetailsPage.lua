local Packages = script.Parent.Parent
local React = require(Packages.React)
local ReactFocusNavigation = require(Packages.ReactFocusNavigation)

local CaptureFocus = require(script.Parent.CaptureFocus)

return function(props)
	local navigation = props.navigation
	local screenRef = ReactFocusNavigation.useEventHandler("Back", function(event)
		if event.eventData.UserInputState == Enum.UserInputState.Begin then
			navigation.goBack()
		end
	end)

	return React.createElement(
		"Frame",
		{
			ref = screenRef,
			Selectable = false,
			Size = UDim2.fromScale(1, 1),
		},
		React.createElement(CaptureFocus),
		React.createElement("TextButton", {
			Position = UDim2.fromScale(0.1, 0.1),
			Size = UDim2.fromOffset(80, 40),
			Text = "Back",
			[React.Event.Activated] = function()
				navigation.goBack()
			end,
		}),
		React.createElement("TextButton", {
			SelectionOrder = -1,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(300, 150),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Text = string.format("Details content for %s", navigation.getParam("gameTitle", "<not found>")),
		})
	)
end
