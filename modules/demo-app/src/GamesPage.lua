local Packages = script.Parent.Parent
local React = require(Packages.React)

local CaptureFocus = require(script.Parent.CaptureFocus)

local function GamesPage()
	return React.createElement(
		"Frame",
		{
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromHex("EEDAAA"),
			Size = UDim2.fromScale(1, 1),
		},
		React.createElement("TextButton", {
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(300, 150),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Text = "<placeholder>",
		}, React.createElement(CaptureFocus))
	)
end

return GamesPage
