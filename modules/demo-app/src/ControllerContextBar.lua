local Packages = script.Parent.Parent
local React = require(Packages.React)
local ReactFocusNavigation = require(Packages.ReactFocusNavigation)

local useLastInputDevice = require(script.Parent.hooks.useLastInputDevice)

local function ControllerContextBar()
	local lastInputDevice = useLastInputDevice()

	local eventMap = ReactFocusNavigation.useActiveEventMap()
	local eventMapText = React.useMemo(function()
		if lastInputDevice == "None" or lastInputDevice == "Mouse" then
			return "{}"
		end

		local labelText = "{ "
		for k, v in eventMap do
			if string.match(k.Name, "Button") then
				if lastInputDevice == "Keyboard" then
					continue
				end
			else
				if lastInputDevice == "Gamepad" then
					continue
				end
			end
			labelText ..= tostring(k.Name) .. " - " .. tostring(v) .. "; "
		end
		labelText ..= "}"

		return labelText
	end, { eventMap, lastInputDevice })

	if eventMapText == "{}" then
		return nil
	end

	return React.createElement("TextLabel", {
		ZIndex = 5,
		BackgroundColor3 = Color3.new(0.8, 0.8, 0.8),
		Size = UDim2.new(0.7, 0, 0, 50),
		Position = UDim2.new(0.5, 0, 1, -75),
		AnchorPoint = Vector2.new(0.5, 1),
		TextSize = 10,
		Text = eventMapText,
	})
end

return ControllerContextBar
