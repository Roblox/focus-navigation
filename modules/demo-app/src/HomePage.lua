local Packages = script.Parent.Parent
local React = require(Packages.React)
local Array = require(Packages.Collections).Array
local ReactFocusNavigation = require(Packages.ReactFocusNavigation)

local GameSort = require(script.Parent.GameSort)
local CaptureFocus = require(script.Parent.CaptureFocus)

local sortsData = require(script.Parent.data.sorts)

local function HomePage(props)
	local containerRef = ReactFocusNavigation.useMostRecentFocusBehavior()

	local sorts = Array.map(sortsData, function(item, i)
		return React.createElement(GameSort, {
			navigateToGameDetails = function(title)
				props.navigation.navigate("GameDetails", {
					gameTitle = title,
				})
			end,
			key = item.name,
			layoutOrder = i,
			data = item,
		})
	end)

	return React.createElement(
		"ScrollingFrame",
		{
			ref = containerRef,
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromHex("B4E4E0"),
			AutomaticCanvasSize = Enum.AutomaticSize.XY,
			BorderSizePixel = 0,
			Selectable = false,
		},
		Array.concat(sorts, {
			React.createElement(CaptureFocus, { key = "_captureFocus" }),
			React.createElement("UIPadding", {
				key = "_padding",
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
				PaddingTop = UDim.new(0, 12),
				PaddingBottom = UDim.new(0, 12),
			}),
			React.createElement("UIListLayout", {
				key = "_layout",
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				Padding = UDim.new(0, 12),
			}),
		})
	)
end

return HomePage
