local Packages = script.Parent.Parent
local React = require(Packages.React)

local function Tile(props)
	return React.createElement(
		"ImageButton",
		{
			LayoutOrder = props.layoutOrder,
			Size = props.size,
			BackgroundColor3 = Color3.fromRGB(100, 100, 100),
			[React.Event.Activated] = props.onActivated,
		},
		React.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 6),
			PaddingTop = UDim.new(0, 6),
			PaddingBottom = UDim.new(0, 6),
		}),
		React.createElement("TextLabel", {
			Text = props.name,
			TextSize = props.textSize,
			TextWrapped = true,
			TextColor3 = Color3.fromRGB(200, 200, 200),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		})
	)
end

return Tile
