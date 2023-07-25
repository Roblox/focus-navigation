local Packages = script.Parent.Parent
local React = require(Packages.React)
local ReactFocusNavigation = require(Packages.ReactFocusNavigation)
local RoactNavigation = require(Packages.RoactNavigation)
local InputHandlers = require(Packages.InputHandlers)
local Array = require(Packages.Collections).Array

local ElementList = require(script.Parent.ElementList)

local EVENT_MAP = {
	[Enum.KeyCode.ButtonL1] = "PreviousTab",
	[Enum.KeyCode.ButtonR1] = "NextTab",
	[Enum.KeyCode.ButtonB] = "Back",

	[Enum.KeyCode.Z] = "PreviousTab",
	[Enum.KeyCode.X] = "NextTab",
	[Enum.KeyCode.Q] = "Back",
}

type Tab = {
	name: string,
	content: React.ReactElement<any>,
}
type Props = {
	tabs: { Tab },
}

local function createTabNavigator(routeConfig)
	local ContentNavigator = RoactNavigation.createRobloxSwitchNavigator(routeConfig, {
		defaultNavigationOptions = {
			absorbInput = false,
		},
	})

	local function TabView(props)
		local navigation = props.navigation

		local contentRef = React.useRef(nil)

		local tabIndex, setTabIndex = React.useState(1)
		local changeTab = React.useCallback(function(i)
			local key, _ = next(routeConfig[i])
			setTabIndex(i)
			navigation.navigate(key)
		end, { navigation })

		local eventHandlerMap = React.useMemo(function()
			return {
				NextTab = {
					handler = InputHandlers.onPress(function()
						if tabIndex < #routeConfig then
							changeTab(tabIndex + 1)
						end
					end),
				},
				PreviousTab = {
					handler = InputHandlers.onPress(function()
						if tabIndex > 1 then
							changeTab(tabIndex - 1)
						end
					end),
				},
			}
		end, { tabIndex, routeConfig, changeTab })

		local ref = ReactFocusNavigation.useEventMap(EVENT_MAP)
		ref = ReactFocusNavigation.useEventHandlerMap(eventHandlerMap, ref)

		return React.createElement("Frame", {
			ref = ref,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
		}, {
			TabButtonList = React.createElement(ElementList, {
				size = UDim2.new(1, 0, 0, 150),
				padding = UDim.new(0, 50),
				fillDirection = Enum.FillDirection.Horizontal,
				alignment = Enum.HorizontalAlignment.Center,
				elements = Array.map(routeConfig, function(tab, i)
					local key, _ = next(tab)
					return React.createElement("TextButton", {
						key = key,
						Size = UDim2.new(0, 150, 1, 0),
						Text = key,
						TextSize = if i == tabIndex then 16 else 12,
						[React.Event.Activated] = function()
							changeTab(i)
						end,
					})
				end),
			}),
			Content = React.createElement(
				"Frame",
				{
					Selectable = false,
					ref = contentRef,
					Position = UDim2.new(0.05, 0, 0, 150),
					Size = UDim2.new(0.9, 0, 1, -150),
					BackgroundTransparency = 1,
				},
				React.createElement(
					"Frame",
					{
						Selectable = false,
						Position = UDim2.fromScale(0.05, 0.05),
						Size = UDim2.fromScale(0.9, 0.9),
					},
					React.createElement(ContentNavigator, {
						navigation = navigation,
						detached = true,
					})
				)
			),
		})
	end

	local TabNavigator = React.Component:extend("TabNavigator")
	TabNavigator.router = ContentNavigator.router

	function TabNavigator:render()
		return React.createElement(TabView, {
			navigation = self.props.navigation,
		})
	end

	return TabNavigator
end

return createTabNavigator
