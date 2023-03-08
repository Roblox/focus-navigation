local Packages = script.Parent.Parent
local React = require(Packages.React)
local ReactFocusNavigation = require(Packages.ReactFocusNavigation)
local RoactNavigation = require(Packages.RoactNavigation)
local FocusNavigationService = ReactFocusNavigation.FocusNavigationService
local PlayerGuiInterface = ReactFocusNavigation.EngineInterface.PlayerGui

local createTabNavigator = require(script.Parent.createTabNavigator)
local HomePage = require(script.Parent.HomePage)
local GamesPage = require(script.Parent.GamesPage)
local GameDetailsPage = require(script.Parent.GameDetailsPage)
local ControllerContextBar = require(script.Parent.ControllerContextBar)

local HomeNavigator = RoactNavigation.createRobloxStackNavigator({
	{ Home = HomePage },
	{ GameDetails = GameDetailsPage },
}, {
	defaultNavigationOptions = {
		absorbInput = false,
	},
})

local routeConfig = {
	{ Home = HomeNavigator },
	{ Games = GamesPage },
}
local rootNavigator = createTabNavigator(routeConfig)

local appContainer = RoactNavigation.createAppContainer(rootNavigator)

local function App(props)
	local focusNav = React.useRef(nil)
	if not focusNav.current then
		if props.focusNav then
			focusNav.current = props.focusNav
		else
			focusNav.current = FocusNavigationService.new(PlayerGuiInterface)
		end
	end
	return React.createElement(
		ReactFocusNavigation.FocusNavigationContext.Provider,
		{
			value = focusNav.current,
		},
		React.createElement(
			"ScreenGui",
			{
				IgnoreGuiInset = true,
				ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			},
			React.createElement(appContainer, {
				detached = true,
			}),
			React.createElement(ControllerContextBar)
		)
	)
end

return App
