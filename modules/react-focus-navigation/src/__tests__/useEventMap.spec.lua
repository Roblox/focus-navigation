--!strict
local Packages = script.Parent.Parent.Parent
local React = require(Packages.React)
local FocusNavigation = require(Packages.FocusNavigation)
local FocusNavigationService = FocusNavigation.FocusNavigationService

local JestGlobals = require(Packages.Dev.JestGlobals)
local it = JestGlobals.it
local expect = JestGlobals.expect
local jest = JestGlobals.jest
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach

local ReactTestingLibrary = require(Packages.Dev.ReactTestingLibrary)
local render = ReactTestingLibrary.render
local cleanup = ReactTestingLibrary.cleanup

local Collections = require(Packages.Dev.Collections)
local Object = Collections.Object

local FocusNavigationContext = require(script.Parent.Parent.FocusNavigationContext)
local useEventMap = require(script.Parent.Parent.useEventMap)

local focusNavigationService
beforeEach(function()
	focusNavigationService = FocusNavigationService.new(FocusNavigation.EngineInterface.CoreGui)
end)

afterEach(function()
	focusNavigationService:focusGuiObject(nil)
	focusNavigationService:teardown()
	cleanup()
end)

local function SimpleButton(props)
	local ref = useEventMap(props.eventMap, props.innerRef)
	return React.createElement("TextButton", {
		Text = props.text,
		ref = ref,
	})
end

local function SimpleLabel(props)
	local ref = useEventMap(props.eventMap, props.innerRef)
	return React.createElement("TextLabel", {
		Text = props.text,
		ref = ref,
	})
end

local function FocusNavigationServiceWrapper(props)
	return React.createElement(FocusNavigationContext.Provider, {
		value = focusNavigationService,
	}, props.children)
end

local function renderWithFocusNav(ui, options: any?)
	return render(ui, Object.assign({ wrapper = FocusNavigationServiceWrapper }, options or {}))
end

it("should have no effect if no context is provided", function()
	local activeEventMapSpy, activeEventMapSpyFn = jest.fn()
	focusNavigationService.activeEventMap:subscribe(activeEventMapSpyFn)

	-- Use regular testing library `render` instead of the wrapper
	local result = render(React.createElement(SimpleButton, {
		eventMap = { [Enum.KeyCode.ButtonX] = "showMore" },
		text = "Show More",
	}))

	local instance = result.getByText("Show More")
	focusNavigationService:focusGuiObject(instance, false)

	expect(activeEventMapSpy).toHaveBeenCalledTimes(0)
end)

it("should register an event map when its ref is populated", function()
	local activeEventMapSpy, activeEventMapSpyFn = jest.fn()
	focusNavigationService.activeEventMap:subscribe(activeEventMapSpyFn)

	local result = renderWithFocusNav(React.createElement(SimpleButton, {
		eventMap = { [Enum.KeyCode.ButtonX] = "showMore" },
		text = "Show More",
	}))

	local instance = result.getByText("Show More")
	focusNavigationService:focusGuiObject(instance, false)

	expect(activeEventMapSpy).toHaveBeenCalledTimes(1)
	expect(activeEventMapSpy).toHaveBeenCalledWith({ [Enum.KeyCode.ButtonX] = "showMore" })
end)

it("should deregister an event map when it cleans up", function()
	local activeEventMapSpy, activeEventMapSpyFn = jest.fn()
	focusNavigationService.activeEventMap:subscribe(activeEventMapSpyFn)

	local result = renderWithFocusNav(React.createElement(SimpleButton, {
		eventMap = { [Enum.KeyCode.ButtonX] = "showMore" },
		text = "Show More",
	}))

	local instance = result.getByText("Show More")
	focusNavigationService:focusGuiObject(instance, false)

	expect(activeEventMapSpy).toHaveBeenCalledTimes(1)

	result.unmount()
	expect(activeEventMapSpy).toHaveBeenCalledTimes(2)
	expect(activeEventMapSpy).toHaveBeenCalledWith({})
end)

it("should update the event map if the value changes after it updates", function()
	local activeEventMapSpy, activeEventMapSpyFn = jest.fn()
	focusNavigationService.activeEventMap:subscribe(activeEventMapSpyFn)

	local result = renderWithFocusNav(React.createElement(SimpleButton, {
		eventMap = { [Enum.KeyCode.ButtonX] = "showMore" },
		text = "Show More",
	}))

	local instance = result.getByText("Show More")
	focusNavigationService:focusGuiObject(instance, false)

	expect(activeEventMapSpy).toHaveBeenCalledTimes(1)

	result.rerender(React.createElement(SimpleButton, {
		eventMap = { [Enum.KeyCode.ButtonY] = "showMore" },
		text = "Show More",
	}))

	-- unbinds, then binds
	expect(activeEventMapSpy).toHaveBeenCalledTimes(3)
	expect(activeEventMapSpy).toHaveBeenNthCalledWith(2, {})
	expect(activeEventMapSpy).toHaveBeenNthCalledWith(3, { [Enum.KeyCode.ButtonY] = "showMore" })
end)

it("should not re-register an existing map if the inputs haven't changed", function()
	local activeEventMapSpy, activeEventMapSpyFn = jest.fn()
	focusNavigationService.activeEventMap:subscribe(activeEventMapSpyFn)

	local eventMap = { [Enum.KeyCode.ButtonX] = "showMore" }
	local result = renderWithFocusNav(React.createElement(SimpleButton, {
		eventMap = eventMap,
		text = "Show More",
	}))

	local instance = result.getByText("Show More")
	focusNavigationService:focusGuiObject(instance, false)

	expect(activeEventMapSpy).toHaveBeenCalledTimes(1)
	expect(activeEventMapSpy).toHaveBeenCalledWith({ [Enum.KeyCode.ButtonX] = "showMore" })

	result.rerender(React.createElement(SimpleButton, {
		eventMap = eventMap,
		text = "Show More!",
	}))

	expect(activeEventMapSpy).toHaveBeenCalledTimes(1)
end)

it("should not do anything if the returned ref is not used", function()
	local function IgnoresRef(props)
		local _ref = useEventMap(props.eventMap)
		return React.createElement("TextButton", {
			Text = props.text,
		})
	end

	local activeEventMapSpy, activeEventMapSpyFn = jest.fn()
	focusNavigationService.activeEventMap:subscribe(activeEventMapSpyFn)

	local result = renderWithFocusNav(React.createElement(IgnoresRef, {
		eventMap = { [Enum.KeyCode.ButtonX] = "showMore" },
		text = "Show More",
	}))

	local instance = result.getByText("Show More")
	focusNavigationService:focusGuiObject(instance, false)

	expect(activeEventMapSpy).toHaveBeenCalledTimes(0)
end)

it("should update a function ref when the underlying value changes", function()
	local refSpy, refSpyFn = jest.fn()
	local eventMap = { [Enum.KeyCode.ButtonX] = "showMore" }
	local result = renderWithFocusNav(React.createElement(SimpleButton, {
		eventMap = eventMap,
		innerRef = refSpyFn,
		text = "Show More",
	}))

	local instance = result.getByText("Show More")
	expect(refSpy).toHaveBeenCalledTimes(1)
	expect(refSpy).toHaveBeenCalledWith(instance)

	result.rerender(React.createElement(SimpleLabel, {
		eventMap = eventMap,
		innerRef = refSpyFn,
		text = "Show More",
	}))

	local newInstance = result.getByText("Show More")
	expect(refSpy).toHaveBeenCalledTimes(3)
	-- Ref is first called with nil when Instance class changes
	expect(refSpy).toHaveBeenNthCalledWith(2, nil)
	expect(refSpy).toHaveBeenLastCalledWith(newInstance)
end)

it("should update an object ref when the underlying value changes", function()
	local ref = React.createRef()
	local eventMap = { [Enum.KeyCode.ButtonX] = "showMore" }
	local result = renderWithFocusNav(React.createElement(SimpleButton, {
		eventMap = eventMap,
		innerRef = ref,
		text = "Show More",
	}))

	local instance = result.getByText("Show More")
	expect(ref.current).toEqual(instance)

	result.rerender(React.createElement(SimpleLabel, {
		eventMap = eventMap,
		innerRef = ref,
		text = "Show More",
	}))

	local newInstance = result.getByText("Show More")
	expect(ref.current).toEqual(newInstance)
end)
