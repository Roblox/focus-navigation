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

local Utils = require(Packages.FocusNavigationUtils)
local waitForEvents = Utils.waitForEvents

local FocusNavigationContext = require(script.Parent.Parent.FocusNavigationContext)
local useEventHandler = require(script.Parent.Parent.useEventHandler)

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
	local ref = useEventHandler(props.eventName, props.eventHandler, props.eventPhase, props.innerRef)
	return React.createElement("TextButton", {
		Text = props.text,
		ref = ref,
	})
end

local function SimpleLabel(props)
	local ref = useEventHandler(props.eventName, props.eventHandler, props.eventPhase, props.innerRef)
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
		eventName = "onXButton",
		eventHandler = handlerFn,
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
	local leftFocusHandler, focusHandlerFn = jest.fn()
	local rightBlurHandler, blurHandlerFn = jest.fn()
	local result = renderWithFocusNav(React.createElement(React.Fragment, nil, {
		LeftButton = React.createElement(SimpleButton, {
			eventName = "focus",
			eventHandler = focusHandlerFn,
			text = "Confirm",
		}),
		RightButton = React.createElement(SimpleButton, {
			eventName = "blur",
			eventHandler = blurHandlerFn,
			text = "Cancel",
		}),
	}))

	local leftButton = result.getByText("Confirm")
	focusNavigationService:focusGuiObject(leftButton, false)
	waitForEvents()

	expect(leftFocusHandler).toHaveBeenCalledTimes(1)
	expect(rightBlurHandler).toHaveBeenCalledTimes(0)

	local rightButton = result.getByText("Cancel")
	focusNavigationService:focusGuiObject(rightButton, false)
	waitForEvents()

	expect(leftFocusHandler).toHaveBeenCalledTimes(1)
	expect(rightBlurHandler).toHaveBeenCalledTimes(0)

	focusNavigationService:focusGuiObject(leftButton, false)
	waitForEvents()

	expect(leftFocusHandler).toHaveBeenCalledTimes(2)
	expect(rightBlurHandler).toHaveBeenCalledTimes(1)
end)

it("should deregister an event map on unmount", function()
	local handler, handlerFn = jest.fn()
	local result = renderWithFocusNav(React.createElement(SimpleButton, {
		eventName = "onXButton",
		eventHandler = handlerFn,
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

it("should deregister old and register new handlers when they change", function()
	local handler, handlerFn = jest.fn()
	local result = renderWithFocusNav(React.createElement(SimpleButton, {
		eventName = "onXButton",
		eventHandler = handlerFn,
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

	local newHandler, newHandlerFn = jest.fn()
	result.rerender(React.createElement(SimpleButton, {
		eventName = "onXButton",
		eventHandler = newHandlerFn,
		text = "Confirm",
	}))
	expect(handler).toHaveBeenCalledTimes(3)
	expect(handler).toHaveBeenLastCalledWith(expect.objectContaining({
		eventData = expect.objectContaining({ UserInputState = Enum.UserInputState.Cancel }),
	}))

	act(function()
		gamepad:hitButton(Enum.KeyCode.ButtonX)
	end)
	expect(handler).toHaveBeenCalledTimes(3)
	expect(newHandler).toHaveBeenCalledTimes(2)
end)

it("should update the event map if the value changes after it updates", function()
	local handlerA, handlerAFn = jest.fn()
	local handlerB, handlerBFn = jest.fn()
	local result = renderWithFocusNav(React.createElement(SimpleButton, {
		eventName = "onXButton",
		eventHandler = handlerAFn,
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
		eventName = "onXButton",
		eventHandler = handlerBFn,
		text = "Confirm",
	}))
	expect(handlerA).toHaveBeenCalledTimes(3)
	expect(handlerA).toHaveBeenLastCalledWith(expect.objectContaining({
		eventData = expect.objectContaining({ UserInputState = Enum.UserInputState.Cancel }),
	}))
	act(function()
		gamepad:hitButton(Enum.KeyCode.ButtonX)
	end)

	expect(handlerA).toHaveBeenCalledTimes(3)
	expect(handlerB).toHaveBeenCalledTimes(2)
end)

it("should call the correct handler if the eventMap updates", function()
	local onXHandler, onXHandlerFn = jest.fn()
	local onYHandler, onYHandlerFn = jest.fn()
	local function TwoHandlersButton(_props)
		local innerRef = useEventHandler("onXButton", onXHandlerFn)
		local ref = useEventHandler("onYButton", onYHandlerFn, nil, innerRef)
		return React.createElement("TextButton", { ref = ref, Text = "Hello" })
	end

	local result = renderWithFocusNav(React.createElement(TwoHandlersButton))

	local instance = result.getByText("Hello")
	focusNavigationService:registerEventMap(instance, {
		[Enum.KeyCode.ButtonX] = "onXButton",
	})
	focusNavigationService:focusGuiObject(instance, false)
	waitForEvents()

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
		local _ref = useEventHandler(props.eventName, props.eventHandler)
		return React.createElement("TextButton", {
			Text = props.text,
		})
	end

	local handler, handlerFn = jest.fn()
	local result = renderWithFocusNav(React.createElement(IgnoresRef, {
		eventName = "onXButton",
		eventHandler = handlerFn,
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
	local mockHandler = function() end
	local result = renderWithFocusNav(React.createElement(SimpleButton, {
		eventName = "someEvent",
		eventHandler = mockHandler,
		innerRef = refSpyFn,
		text = "Confirm",
	}))

	local instance = result.getByText("Confirm")

	expect(refSpy).toHaveBeenCalledTimes(1)
	expect(refSpy).toHaveBeenCalledWith(instance)

	result.rerender(React.createElement(SimpleLabel, {
		eventName = "someEvent",
		eventHandler = mockHandler,
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
	local mockHandler = function() end
	local result = renderWithFocusNav(React.createElement(SimpleButton, {
		eventName = "someEvent",
		eventHandler = mockHandler,
		innerRef = ref,
		text = "Confirm",
	}))
	local instance = result.getByText("Confirm")
	expect(ref.current).toEqual(instance)

	result.rerender(React.createElement(SimpleLabel, {
		eventName = "someEvent",
		eventHandler = mockHandler,
		innerRef = ref,
		text = "Confirm",
	}))

	local newInstance = result.getByText("Confirm")
	expect(ref.current).toEqual(newInstance)
end)

it("binds to the correct phase", function()
	local captureFocusHandler, captureFocusHandlerFn = jest.fn()
	local bubbleFocusHandler, bubbleFocusHandlerFn = jest.fn()
	local result = renderWithFocusNav(React.createElement(React.Fragment, nil, {
		LeftButton = React.createElement(SimpleButton, {
			eventName = "focus",
			eventHandler = captureFocusHandlerFn,
			eventPhase = "Capture" :: FocusNavigation.EventPhase,
			text = "Confirm",
		}),
		RightButton = React.createElement(SimpleButton, {
			eventName = "focus",
			eventHandler = bubbleFocusHandlerFn,
			eventPhase = "Bubble" :: FocusNavigation.EventPhase,
			text = "Cancel",
		}),
	}))

	local leftButton = result.getByText("Confirm")
	focusNavigationService:focusGuiObject(leftButton, false)
	waitForEvents()

	expect(captureFocusHandler).toHaveBeenCalledTimes(1)
	expect(captureFocusHandler).toHaveBeenCalledWith(expect.objectContaining({
		phase = "Capture",
	}))
	expect(bubbleFocusHandler).toHaveBeenCalledTimes(0)

	local rightButton = result.getByText("Cancel")
	focusNavigationService:focusGuiObject(rightButton, false)
	waitForEvents()

	expect(captureFocusHandler).toHaveBeenCalledTimes(1)
	expect(bubbleFocusHandler).toHaveBeenCalledTimes(1)
	expect(bubbleFocusHandler).toHaveBeenCalledWith(expect.objectContaining({
		phase = "Bubble",
	}))
end)
