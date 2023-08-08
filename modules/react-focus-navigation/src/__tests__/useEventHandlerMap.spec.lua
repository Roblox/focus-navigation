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
local act = ReactTestingLibrary.act
local cleanup = ReactTestingLibrary.cleanup

local Rhodium = require(Packages.Dev.Rhodium)
local GamePad = Rhodium.VirtualInput.GamePad

local Collections = require(Packages.Dev.Collections)
local Object = Collections.Object

local waitForEvents = require(Packages.Utils).waitForEvents

local FocusNavigationContext = require(script.Parent.Parent.FocusNavigationContext)
local useEventHandlerMap = require(script.Parent.Parent.useEventHandlerMap)

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
	local ref = useEventHandlerMap(props.handlerMap, props.innerRef)
	return React.createElement("TextButton", {
		Text = props.text,
		ref = ref,
	})
end

local function SimpleLabel(props)
	local ref = useEventHandlerMap(props.handlerMap, props.innerRef)
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
	local handler, handlerFn = jest.fn()
	-- Use regular testing library `render` instead of the wrapper
	local result = render(React.createElement(SimpleButton, {
		handlerMap = {
			focus = { handler = handlerFn },
		},
		text = "Confirm",
	}))

	local instance = result.getByText("Confirm")
	focusNavigationService:registerEventMap(instance, {
		[Enum.KeyCode.ButtonX] = "onXButton",
	})
	focusNavigationService:focusGuiObject(instance, false)
	waitForEvents()

	local gamepad = GamePad.new()
	act(function()
		gamepad:hitButton(Enum.KeyCode.ButtonX)
	end)
	expect(handler).toHaveBeenCalledTimes(0)
end)

it("should receive focus and blur events when registered", function()
	local focusHandler, focusHandlerFn = jest.fn()
	local blurHandler, blurHandlerFn = jest.fn()
	local result = renderWithFocusNav(React.createElement(SimpleButton, {
		handlerMap = {
			focus = { handler = focusHandlerFn },
			blur = { handler = blurHandlerFn },
		},
		text = "Confirm",
	}))

	local instance = result.getByText("Confirm")
	focusNavigationService:focusGuiObject(instance, false)
	waitForEvents()

	expect(focusHandler).toHaveBeenCalledTimes(1)
	expect(blurHandler).toHaveBeenCalledTimes(0)

	focusNavigationService:focusGuiObject(nil, false)
	waitForEvents()

	expect(focusHandler).toHaveBeenCalledTimes(1)
	expect(blurHandler).toHaveBeenCalledTimes(1)
end)

it("should deregister an event map on unmount", function()
	local handler, handlerFn = jest.fn()
	local result = renderWithFocusNav(React.createElement(SimpleButton, {
		handlerMap = {
			onXButton = { handler = handlerFn },
		},
		text = "Confirm",
	}))

	local instance = result.getByText("Confirm")
	focusNavigationService:registerEventMap(instance, {
		[Enum.KeyCode.ButtonX] = "onXButton",
	})
	focusNavigationService:focusGuiObject(instance, false)
	waitForEvents()

	local gamepad = GamePad.new()
	act(function()
		gamepad:hitButton(Enum.KeyCode.ButtonX)
	end)
	-- press + release
	expect(handler).toHaveBeenCalledTimes(2)
	expect(handler).toHaveBeenNthCalledWith(
		1,
		expect.objectContaining({
			eventData = expect.objectContaining({ UserInputState = Enum.UserInputState.Begin }),
		})
	)
	expect(handler).toHaveBeenNthCalledWith(
		2,
		expect.objectContaining({
			eventData = expect.objectContaining({ UserInputState = Enum.UserInputState.End }),
		})
	)

	result.unmount()
	expect(handler).toHaveBeenCalledTimes(3)
	expect(handler).toHaveBeenLastCalledWith(expect.objectContaining({
		eventData = expect.objectContaining({ UserInputState = Enum.UserInputState.Cancel }),
	}))

	act(function()
		gamepad:hitButton(Enum.KeyCode.ButtonX)
	end)
	expect(handler).toHaveBeenCalledTimes(3)
end)

it("should update the event map if the value changes after it updates", function()
	local handlerA, handlerAFn = jest.fn()
	local handlerB, handlerBFn = jest.fn()
	local result = renderWithFocusNav(React.createElement(SimpleButton, {
		handlerMap = {
			onXButton = { handler = handlerAFn },
		},
		text = "Confirm",
	}))

	local instance = result.getByText("Confirm")
	focusNavigationService:registerEventMap(instance, {
		[Enum.KeyCode.ButtonX] = "onXButton",
	})
	focusNavigationService:focusGuiObject(instance, false)
	waitForEvents()

	local gamepad = GamePad.new()
	act(function()
		gamepad:hitButton(Enum.KeyCode.ButtonX)
	end)
	expect(handlerA).toHaveBeenCalledTimes(2)
	expect(handlerB).toHaveBeenCalledTimes(0)

	result.rerender(React.createElement(SimpleButton, {
		handlerMap = {
			onXButton = { handler = handlerBFn },
		},
		text = "Confirm",
	}))
	expect(handlerA).toHaveBeenCalledTimes(3)
	expect(handlerB).toHaveBeenCalledTimes(0)

	act(function()
		gamepad:hitButton(Enum.KeyCode.ButtonX)
	end)

	expect(handlerA).toHaveBeenCalledTimes(3)
	expect(handlerB).toHaveBeenCalledTimes(2)
end)

it("should call the correct handler if the eventMap updates", function()
	local onXHandler, onXHandlerFn = jest.fn()
	local onYHandler, onYHandlerFn = jest.fn()
	local result = renderWithFocusNav(React.createElement(SimpleButton, {
		handlerMap = {
			onXButton = { handler = onXHandlerFn },
			onYButton = { handler = onYHandlerFn },
		},
		text = "Confirm",
	}))

	local instance = result.getByText("Confirm")
	focusNavigationService:registerEventMap(instance, {
		[Enum.KeyCode.ButtonX] = "onXButton",
	})
	focusNavigationService:focusGuiObject(instance, false)

	local gamepad = GamePad.new()
	act(function()
		gamepad:hitButton(Enum.KeyCode.ButtonX)
		gamepad:hitButton(Enum.KeyCode.ButtonY)
	end)
	expect(onXHandler).toHaveBeenCalledTimes(2)
	expect(onYHandler).toHaveBeenCalledTimes(0)

	focusNavigationService:registerEventMap(instance, {
		[Enum.KeyCode.ButtonY] = "onYButton",
	})
	focusNavigationService:deregisterEventMap(instance, {
		[Enum.KeyCode.ButtonX] = "onXButton",
	})
	-- cancellation event
	expect(onXHandler).toHaveBeenCalledTimes(3)

	act(function()
		gamepad:hitButton(Enum.KeyCode.ButtonX)
		gamepad:hitButton(Enum.KeyCode.ButtonY)
	end)

	expect(onXHandler).toHaveBeenCalledTimes(3)
	expect(onYHandler).toHaveBeenCalledTimes(2)
end)

-- TODO: Is there some way we can account for this? Warn if function ref not
-- called after some time? Maybe in dev mode?
it("should not do anything if the returned ref is not used", function()
	local function IgnoresRef(props)
		local _ref = useEventHandlerMap(props.handlerMap)
		return React.createElement("TextButton", {
			Text = props.text,
		})
	end

	local handler, handlerFn = jest.fn()
	local result = renderWithFocusNav(React.createElement(IgnoresRef, {
		handlerMap = {
			onXButton = { handler = handlerFn },
		},
		text = "Confirm",
	}))

	local instance = result.getByText("Confirm")
	focusNavigationService:registerEventMap(instance, {
		[Enum.KeyCode.ButtonX] = "onXButton",
	})
	focusNavigationService:focusGuiObject(instance, false)
	waitForEvents()
	local gamepad = GamePad.new()
	act(function()
		gamepad:hitButton(Enum.KeyCode.ButtonX)
	end)
	expect(handler).toHaveBeenCalledTimes(0)
end)

it("should update a function ref when the underlying value changes", function()
	local refSpy, refSpyFn = jest.fn()
	local result = renderWithFocusNav(React.createElement(SimpleButton, {
		handlerMap = {},
		innerRef = refSpyFn,
		text = "Confirm",
	}))

	local instance = result.getByText("Confirm")

	expect(refSpy).toHaveBeenCalledTimes(1)
	expect(refSpy).toHaveBeenCalledWith(instance)

	result.rerender(React.createElement(SimpleLabel, {
		handlerMap = {},
		innerRef = refSpyFn,
		text = "Confirm",
	}))

	local newInstance = result.getByText("Confirm")
	expect(refSpy).toHaveBeenCalledTimes(3)
	-- Ref is first called with nil when Instance class changes
	expect(refSpy).toHaveBeenNthCalledWith(2, nil)
	expect(refSpy).toHaveBeenLastCalledWith(newInstance)
end)

it("should update an object ref when the underlying value changes", function()
	local ref = React.createRef()
	local result = renderWithFocusNav(React.createElement(SimpleButton, {
		handlerMap = {},
		innerRef = ref,
		text = "Confirm",
	}))
	local instance = result.getByText("Confirm")
	expect(ref.current).toEqual(instance)

	result.rerender(React.createElement(SimpleLabel, {
		handlerMap = {},
		innerRef = ref,
		text = "Confirm",
	}))

	local newInstance = result.getByText("Confirm")
	expect(ref.current).toEqual(newInstance)
end)
