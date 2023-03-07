local Packages = script.Parent.Parent
local React = require(Packages.React)
local Array = require(Packages.Collections).Array

local ElementList = require(script.Parent.ElementList)
local Tile = require(script.Parent.Tile)

local function GameSort(props)
	return React.createElement(React.Fragment, nil, {
		React.createElement("TextLabel", {
			key = props.data.name .. "-label",
			Text = props.data.name,
			LayoutOrder = props.layoutOrder * 2 - 1,
			Size = UDim2.new(0, 200, 0, 50),
		}),
		React.createElement(ElementList, {
			key = props.data.name,
			size = UDim2.new(1, 0, 0, 174),
			fillDirection = Enum.FillDirection.Horizontal,
			alignment = Enum.HorizontalAlignment.Left,
			padding = UDim.new(0, 12),
			layoutOrder = props.layoutOrder * 2,
			elements = Array.map(props.data.games, function(gameData, i)
				return React.createElement(Tile, {
					key = gameData.name,
					layoutOrder = i,
					size = UDim2.fromOffset(150, 150),
					name = gameData.name,
					textSize = 10,
					onActivated = function()
						props.navigateToGameDetails(gameData.name)
					end,
				})
			end),
		}),
	})
end

return GameSort
