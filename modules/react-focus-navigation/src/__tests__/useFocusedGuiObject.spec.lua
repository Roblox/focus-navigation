--!strict
local Packages = script.Parent.Parent.Parent
local React = require(Packages.React)
local FocusNavigation = require(Packages.FocusNavigation)
local FocusNavigationService = FocusNavigation.FocusNavigationService

local JestGlobals = require(Packages.Dev.JestGlobals)
local jest = JestGlobals.jest
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach

local ReactTestingLibrary = require(Packages.Dev.ReactTestingLibrary)
local render = ReactTestingLibrary.render
local cleanup = ReactTestingLibrary.cleanup

local Collections = require(Packages.Dev.Collections)
local Object = Collections.Object

local Utils = require(Packages.FocusNavigationUtils)
local waitForEvents = Utils.waitForEvents

local FocusNavigationContext = require(script.Parent.Parent.FocusNavigationContext)
local useFocusedGuiObject = require(script.Parent.Parent.useFocusedGuiObject)

local focusNavigationService
beforeEach(function()
	focusNavigationService = FocusNavigationService.new(FocusNavigation.EngineInterface.CoreGui)
end)

afterEach(function()
	focusNavigationService:focusGuiObject(nil)
	focusNavigationService:teardown()
	cleanup()
end)

local function FocusChange(props)
	local value = useFocusedGuiObject()
	props.updateCapturedFocus(value)

	return React.createElement(
		"Frame",
		{
			Size = UDim2.fromOffset(100, 300),
		},
		React.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirection = Enum.FillDirection.Vertical,
		}),
		React.createElement("TextButton", { Text = "one", Size = UDim2.fromOffset(100, 100), LayoutOrder = 1 }),
		React.createElement("TextButton", { Text = "two", Size = UDim2.fromOffset(100, 100), LayoutOrder = 2 }),
		React.createElement("TextButton", { Text = "three", Size = UDim2.fromOffset(100, 100), LayoutOrder = 3 })
	)
end

local function FocusNavigationServiceWrapper(props)
	return React.createElement(FocusNavigationContext.Provider, {
		value = focusNavigationService,
	}, props.children)
end

local function renderWithFocusNav(ui, options: any?)
	return render(ui, Object.assign({ wrapper = FocusNavigationServiceWrapper }, options or {}))
end

it("returns nil if there is no FocusNavigationService", function()
	local currentFocus, currentFocusFn = jest.fn()
	render(React.createElement(FocusChange, {
		updateCapturedFocus = currentFocusFn,
	}))
	expect(currentFocus).toHaveBeenLastCalledWith(nil)
end)

it("return the current focus", function()
	local currentFocus, currentFocusFn = jest.fn()
	local result = renderWithFocusNav(React.createElement(FocusChange, {
		updateCapturedFocus = currentFocusFn,
	}))
	expect(currentFocus).toHaveBeenLastCalledWith(nil)

	local one = result.getByText("one")
	focusNavigationService:focusGuiObject(one, false)
	waitForEvents()
	expect(currentFocus).toHaveBeenLastCalledWith(one)

	local two = result.getByText("two")
	focusNavigationService:focusGuiObject(two, false)
	waitForEvents()
	expect(currentFocus).toHaveBeenLastCalledWith(two)

	local three = result.getByText("three")
	focusNavigationService:focusGuiObject(three, false)
	waitForEvents()
	expect(currentFocus).toHaveBeenLastCalledWith(three)

	focusNavigationService:focusGuiObject(one, false)
	waitForEvents()
	expect(currentFocus).toHaveBeenLastCalledWith(one)
end)

it("does not update if the focus doesn't change", function()
	local currentFocus, currentFocusFn = jest.fn()
	local result = renderWithFocusNav(React.createElement(FocusChange, {
		updateCapturedFocus = currentFocusFn,
	}))
	expect(currentFocus).toHaveBeenLastCalledWith(nil)

	local one = result.getByText("one")
	focusNavigationService:focusGuiObject(one, false)
	waitForEvents()
	expect(currentFocus).toHaveBeenLastCalledWith(one)

	local callCount = #currentFocus.mock.calls
	focusNavigationService:focusGuiObject(one, false)
	waitForEvents()
	expect(#currentFocus.mock.calls).toEqual(callCount)
end)

it("returns nil when focus is lost", function()
	local currentFocus, currentFocusFn = jest.fn()
	local result = renderWithFocusNav(React.createElement(FocusChange, {
		updateCapturedFocus = currentFocusFn,
	}))
	expect(currentFocus).toHaveBeenLastCalledWith(nil)

	local one = result.getByText("one")
	focusNavigationService:focusGuiObject(one, false)
	waitForEvents()
	expect(currentFocus).toHaveBeenLastCalledWith(one)

	focusNavigationService:focusGuiObject(nil, false)
	waitForEvents()
	expect(currentFocus).toHaveBeenLastCalledWith(nil)
end)
