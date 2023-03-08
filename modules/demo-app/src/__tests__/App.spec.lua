--!strict
local Packages = script.Parent.Parent.Parent
local React = require(Packages.React)
local ReactFocusNavigation = require(Packages.ReactFocusNavigation)

local JestGlobals = require(Packages.Dev.JestGlobals)
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach

local Rhodium = require(Packages.Dev.Rhodium)

local ReactTestingLibrary = require(Packages.Dev.ReactTestingLibrary)
local render = ReactTestingLibrary.render
local cleanup = ReactTestingLibrary.cleanup

local Collections = require(Packages.Collections)
local Object = Collections.Object

local FocusNavigationContext = ReactFocusNavigation.FocusNavigationContext
local FocusNavigationService = ReactFocusNavigation.FocusNavigationService

local App = require(script.Parent.Parent.App)

local focusNavigationService
beforeEach(function()
	focusNavigationService = FocusNavigationService.new(ReactFocusNavigation.EngineInterface.CoreGui)
end)

afterEach(function()
	focusNavigationService:focusGuiObject(nil)
	focusNavigationService:teardown()
	cleanup()
end)

local function FocusNavigationServiceWrapper(props)
	return React.createElement(FocusNavigationContext.Provider, {
		value = focusNavigationService,
	}, props.children)
end

local function renderApp(options: any?)
	return render(
		React.createElement(App, { focusNav = focusNavigationService }),
		Object.assign({ wrapper = FocusNavigationServiceWrapper }, options or {})
	)
end

it("renders tab buttons", function()
	local result = renderApp()

	local homeButton = result.getByText("Home")
	expect(homeButton.Selectable).toBe(true)

	local gamesButton = result.getByText("Games")
	expect(gamesButton.Selectable).toBe(true)
end)

-- Something isn't right with RTL + Rhodium here and I can't figure it out;
-- inputs simply aren't firing. I'll have to revisit
it.skip("renders games tab content", function()
	local result = renderApp()

	local gamesButton = result.getByText("Games")
	local gamepad = Rhodium.VirtualInput.GamePad.new()

	focusNavigationService:focusGuiObject(gamesButton)

	gamepad:hitButton(Enum.KeyCode.ButtonA)
	Rhodium.VirtualInput.waitForInputEventsProcessed()

	local gamesContent = result.getByText("<placeholder>")
	expect(gamesContent).toBeDefined()
	expect(gamesContent.Selectable).toBe(true)
end)

-- other high level tests to round things out:

-- 1. home page renders some tiles and sort headers
-- 2. game details page can be navigated to (requires waiting)
-- 3. game details page can be returned from (requires waiting)
