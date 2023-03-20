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

local Rhodium = require(Packages.Dev.Rhodium)

local useLastInputMethod = require(script.Parent.Parent.useLastInputMethod)

local focusNavigationService
beforeEach(function()
	focusNavigationService = FocusNavigationService.new(FocusNavigation.EngineInterface.CoreGui)
end)

afterEach(function()
	focusNavigationService:focusGuiObject(nil)
	focusNavigationService:teardown()
	cleanup()
end)

type Props = {
	onLastInputMethod: (string) -> (),
	children: any?,
}

local function TrackLastInputMethod(props: Props)
	local lastInputMethod = useLastInputMethod()
	props.onLastInputMethod(lastInputMethod)

	return props.children
end

it("should capture the most recent input method when first run", function()
	Rhodium.VirtualInput.Mouse.click(Vector2.new(1, 1))

	local spy = jest.fn()
	render(React.createElement(TrackLastInputMethod, { onLastInputMethod = spy }))

	expect(spy).toHaveBeenCalled()
	expect(spy).toHaveBeenLastCalledWith("Mouse")
end)

it("should trigger updates when the input method changes", function()
	Rhodium.VirtualInput.Mouse.click(Vector2.new(1, 1))

	local spy = jest.fn()
	render(React.createElement(TrackLastInputMethod, { onLastInputMethod = spy }))
	expect(spy).toHaveBeenLastCalledWith("Mouse")

	Rhodium.VirtualInput.Keyboard.hitKey(Enum.KeyCode.A)
	expect(spy).toHaveBeenLastCalledWith("Keyboard")

	Rhodium.VirtualInput.Touch.tap(Vector2.new(1, 1))
	expect(spy).toHaveBeenLastCalledWith("Touch")

	Rhodium.VirtualInput.GamePad.new():hitButton(Enum.KeyCode.ButtonA)
	expect(spy).toHaveBeenLastCalledWith("Gamepad")
end)

it("should not trigger updates when receiving inputs using the same method", function()
	Rhodium.VirtualInput.Mouse.click(Vector2.new(1, 1))

	local spy = jest.fn()
	render(React.createElement(TrackLastInputMethod, { onLastInputMethod = spy }))
	expect(spy).toHaveBeenLastCalledWith("Mouse")

	Rhodium.VirtualInput.Keyboard.hitKey(Enum.KeyCode.A)
	expect(spy).toHaveBeenLastCalledWith("Keyboard")

	local callCount = #spy.mock.calls
	Rhodium.VirtualInput.Keyboard.hitKey(Enum.KeyCode.S)
	Rhodium.VirtualInput.Keyboard.hitKey(Enum.KeyCode.D)
	Rhodium.VirtualInput.Keyboard.hitKey(Enum.KeyCode.F)

	expect(spy).toHaveBeenCalledTimes(callCount)

	local gamepad = Rhodium.VirtualInput.GamePad.new()
	gamepad:hitButton(Enum.KeyCode.ButtonA)
	expect(spy).toHaveBeenLastCalledWith("Gamepad")

	callCount = #spy.mock.calls
	gamepad:hitButton(Enum.KeyCode.ButtonB)
	gamepad:hitButton(Enum.KeyCode.ButtonX)
	gamepad:hitButton(Enum.KeyCode.ButtonY)

	expect(spy).toHaveBeenCalledTimes(callCount)
end)

it("should not change in response to TextInput", function()
	local ref: { current: TextBox? } = React.createRef()
	local spy = jest.fn()
	render(React.createElement(
		TrackLastInputMethod,
		{ onLastInputMethod = spy },
		React.createElement("TextBox", {
			ref = ref,
			Size = UDim2.fromOffset(100, 100),
		})
	))

	Rhodium.VirtualInput.Mouse.click(Vector2.new(1, 1))
	expect(spy).toHaveBeenLastCalledWith("Mouse")

	assert(ref.current, "expected test to create a TextBox to focus")
	ref.current:CaptureFocus()
	Rhodium.VirtualInput.Text.sendText("Hello")
	Rhodium.VirtualInput.waitForInputEventsProcessed()

	expect(spy).toHaveBeenLastCalledWith("Mouse")
end)
