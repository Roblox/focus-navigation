--!strict
local CoreGui = game:GetService("CoreGui")
local PlayerGui = (game:GetService("Players").LocalPlayer :: any).PlayerGui

local Packages = script.Parent.Parent.Parent
local React = require(Packages.React)
local FocusNavigation = require(Packages.FocusNavigation)
local FocusNavigationService = FocusNavigation.FocusNavigationService

local JestGlobals = require(Packages.Dev.JestGlobals)
local jest = JestGlobals.jest
local it = JestGlobals.it
local describe = JestGlobals.describe
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
local useFocusGuiObject = require(script.Parent.Parent.useFocusGuiObject)
local useEventHandlerMap = require(script.Parent.Parent.useEventHandlerMap)

local focusNavigationService
local function FocusNavigationServiceWrapper(props)
	return React.createElement(FocusNavigationContext.Provider, {
		value = focusNavigationService,
	}, React.createElement("ScreenGui", nil, props.children))
end

local function renderWithFocusNav(ui, options: any?)
	return render(
		ui,
		Object.assign({
			wrapper = FocusNavigationServiceWrapper,
		}, options or {})
	)
end

afterEach(function()
	cleanup()
end)

describe("Basic functionality", function()
	afterEach(function()
		if focusNavigationService then
			focusNavigationService:focusGuiObject(nil)
			focusNavigationService:teardown()
		end
	end)

	it("still returns a function if no FocusNavigationService is provided", function()
		local recordHookResult = jest.fn()
		local function Component()
			recordHookResult(useFocusGuiObject())
			return nil
		end

		render(React.createElement(Component))
		expect(recordHookResult).toHaveBeenCalled()
		expect(recordHookResult).toHaveBeenLastCalledWith(expect.any("function"))
	end)

	it("returns the same function on re-renders", function()
		focusNavigationService = FocusNavigationService.new(FocusNavigation.EngineInterface.CoreGui)
		local recordHookResult = jest.fn()
		local function Component()
			recordHookResult(useFocusGuiObject())
			return nil
		end

		local result = renderWithFocusNav(React.createElement(Component))
		expect(recordHookResult).toHaveBeenCalled()

		local prevCaptureFocus = recordHookResult.mock.results[1].value
		local prevCallCount = #recordHookResult.mock.calls
		result.rerender(React.createElement(Component))

		-- make sure it was called at least once more than before; we're being
		-- imprecise here to account for DEV mode's extra steps
		expect(#recordHookResult.mock.calls).toBeGreaterThan(prevCallCount)
		-- Check that it's the same function
		expect(recordHookResult).toHaveLastReturnedWith(prevCaptureFocus)
	end)
end)

local CoreConfig = {
	interface = FocusNavigation.EngineInterface.CoreGui,
	root = CoreGui :: any,
}
local PlayerConfig = {
	interface = FocusNavigation.EngineInterface.PlayerGui,
	root = PlayerGui :: any,
}

local describeEach: any = describe.each

describeEach({ CoreConfig, PlayerConfig })("$root", function(config)
	beforeEach(function()
		focusNavigationService = FocusNavigationService.new(config.interface)
	end)
	afterEach(function()
		focusNavigationService:focusGuiObject(nil)
		focusNavigationService:teardown()
	end)

	local function renderUnderRoot(ui)
		return renderWithFocusNav(ui, {
			baseElement = config.root,
		})
	end

	it("returns a function that captures focus on an instance", function()
		local focusGuiObject
		local function Component()
			focusGuiObject = useFocusGuiObject()

			return React.createElement("TextButton", {
				Size = UDim2.fromScale(1, 1),
				Text = "Foo",
			})
		end

		local result = renderUnderRoot(React.createElement(Component))

		expect(config.interface.getSelection()).toBe(nil)
		local instance = result.getByText("Foo")
		focusGuiObject(instance)
		waitForEvents()
		expect(config.interface.getSelection()).toBe(instance)
	end)

	it("focuses nearest focusable target from instance", function()
		local focusGuiObject
		local function Component()
			focusGuiObject = useFocusGuiObject()

			return React.createElement(
				"TextLabel",
				{
					Size = UDim2.fromScale(1, 1),
					Selectable = false,
					Text = "Not Selectable",
				},
				React.createElement("TextButton", {
					Size = UDim2.fromScale(0.8, 0.8),
					Text = "Selectable Button",
				})
			)
		end

		local result = renderUnderRoot(React.createElement(Component))

		expect(config.interface.getSelection()).toBe(nil)
		local nonSelectableInstance = result.getByText("Not Selectable")
		focusGuiObject(nonSelectableInstance)
		waitForEvents()

		local selectableDescendant = result.getByText("Selectable Button")
		expect(config.interface.getSelection()).toBe(selectableDescendant)
	end)

	it("can be used to clear focus", function()
		local focusGuiObject
		local function Component()
			focusGuiObject = useFocusGuiObject()

			return React.createElement("TextButton", {
				Size = UDim2.fromScale(1, 1),
				Text = "Foo",
			})
		end

		local result = renderUnderRoot(React.createElement(Component))

		local instance = result.getByText("Foo")
		config.interface.setSelection(instance)
		expect(config.interface.getSelection()).never.toBe(nil)

		focusGuiObject(nil)
		expect(config.interface.getSelection()).toBe(nil)
	end)

	it("accepts an argument to silence event propagation", function()
		local focusGuiObject
		local eventCallback, eventCallbackFn = jest.fn()
		local function Component()
			focusGuiObject = useFocusGuiObject()
			local eventRef = useEventHandlerMap({
				blur = { handler = eventCallbackFn },
				focus = { handler = eventCallbackFn },
			})

			return React.createElement(
				"Frame",
				{
					ref = eventRef,
					Size = UDim2.fromScale(1, 1),
				},
				React.createElement("TextButton", {
					Size = UDim2.fromScale(1, 1),
					Text = "Foo",
				})
			)
		end

		local result = renderUnderRoot(React.createElement(Component))
		local instance = result.getByText("Foo")
		focusGuiObject(instance)
		waitForEvents()

		expect(config.interface.getSelection()).toBe(instance)
		expect(eventCallback).toHaveBeenCalledTimes(1)
		expect(eventCallback).toHaveBeenLastCalledWith(expect.objectContaining({
			eventName = "focus",
		}))

		focusGuiObject(nil, true)
		waitForEvents()
		expect(eventCallback).toHaveBeenCalledTimes(1)

		focusGuiObject(instance, true)
		waitForEvents()
		expect(eventCallback).toHaveBeenCalledTimes(1)

		focusGuiObject(nil, false)
		waitForEvents()
		expect(eventCallback).toHaveBeenCalledTimes(2)
		expect(eventCallback).toHaveBeenLastCalledWith(expect.objectContaining({
			eventName = "blur",
		}))
	end)

	it("warns when used with no FocusNavigationService in tree", function()
		local focusGuiObject
		local function Component()
			focusGuiObject = useFocusGuiObject()

			return React.createElement("TextButton", {
				Size = UDim2.fromScale(1, 1),
				Text = "Foo",
			})
		end

		render(React.createElement(Component))
		expect(focusGuiObject).toWarnDev({
			"Could not capture focus with no FocusNavigationService",
		})
	end)
end)
