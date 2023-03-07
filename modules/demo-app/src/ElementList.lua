local Packages = script.Parent.Parent
local React = require(Packages.React)
local Array = require(Packages.Collections).Array

local function ElementList(props)
	local elements = Array.map(props.elements, function(element, i)
		return React.cloneElement(element, {
			LayoutOrder = i,
		})
	end)

	return React.createElement(
		"Frame",
		{
			Size = props.size,
			BorderSizePixel = 0,
			LayoutOrder = props.layoutOrder,
		},
		Array.concat(elements, {
			React.createElement("UIListLayout", {
				key = "_layout",
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = props.fillDirection,
				HorizontalAlignment = props.alignment,
				Padding = props.padding,
			}),
			React.createElement("UIPadding", {
				key = "_padding",
				PaddingLeft = props.padding,
				PaddingRight = props.padding,
				PaddingTop = props.padding,
				PaddingBottom = props.padding,
			}),
		})
	)
end

return ElementList
