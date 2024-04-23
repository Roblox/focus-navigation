--!strict
local Packages = script.Parent.Parent.Parent
local React = require(Packages.React)
local Object = require(Packages.Dev.Collections).Object

local FocusNavigation = require(Packages.FocusNavigation)
local FocusNavigationService = FocusNavigation.FocusNavigationService

local JestGlobals = require(Packages.Dev.JestGlobals)
local it = JestGlobals.it
local expect = JestGlobals.expect
local afterEach = JestGlobals.afterEach
local beforeEach = JestGlobals.beforeEach

local ReactTestingLibrary = require(Packages.Dev.ReactTestingLibrary)
local render = ReactTestingLibrary.render
local cleanup = ReactTestingLibrary.cleanup

local Utils = require(Packages.FocusNavigationUtils)
local waitForEvents = Utils.waitForEvents

local FocusNavigationContext = require(script.Parent.Parent.FocusNavigationContext)
local useContainerFocusBehavior = require(script.Parent.Parent.useContainerFocusBehavior)

local focusNavigationService
beforeEach(function()
	focusNavigationService = FocusNavigationService.new(FocusNavigation.EngineInterface.CoreGui)
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

local function renderWithFocusNav(ui, options: any?)
	return render(ui, Object.assign({ wrapper = FocusNavigationServiceWrapper }, options or {}))
end

local function TestUI(
	props: {
		containerRef: React.Ref<Instance>?,
		firstButtonRef: React.Ref<Instance>?,
		secondButtonRef: React.Ref<Instance>?,
	}
)
	return React.createElement(
		"ScreenGui",
		nil,
		React.createElement("Frame", { Size = UDim2.fromScale(1, 1) }, {
			LeftOuterButton = React.createElement("TextButton", {
				Text = "LeftOuterButton",
				Size = UDim2.fromScale(0.5, 1),
			}),
			RightOuterButton = React.createElement("TextButton", {
				Text = "RightOuterButton",
				Size = UDim2.fromScale(0.5, 1),
				Position = UDim2.fromScale(0.5, 0),
			}),
			-- This lets us test hook cleanup by rerendering without the
			-- `behaviorFrame` prop to remove the hook
			BehaviorContainer = React.createElement("Frame", {
				Size = UDim2.new(1, 0, 0.5, 0),
				Position = UDim2.fromScale(0, 0.5),
				ref = props.containerRef,
				[React.Tag] = "data-testid=container",
			}, {
				FirstButton = React.createElement("TextButton", {
					SelectionOrder = 1,
					Text = "FirstButton",
					Size = UDim2.fromScale(0.5, 1),
					ref = props.firstButtonRef,
				}),
				SecondButton = React.createElement("TextButton", {
					SelectionOrder = 2,
					Text = "SecondButton",
					Size = UDim2.fromScale(0.5, 1),
					Position = UDim2.fromScale(0.5, 0),
					ref = props.secondButtonRef,
				}),
			}),
		})
	)
end

local function moveFocus(target)
	focusNavigationService:focusGuiObject(target)
	waitForEvents() -- wait for focus change to be reacted to
	waitForEvents() -- allow for redirect if necessary
end

it("should apply a simple focus behavior", function()
	local function WithBehavior()
		local targetRef = React.useRef(nil)
		local behavior = React.useMemo(function()
			return {
				onDescendantFocusChanged = nil,
				getTargets = function()
					return if targetRef.current then { targetRef.current } else {}
				end,
			}
		end, {})
		local containerRef = useContainerFocusBehavior(behavior)

		return React.createElement(TestUI, { containerRef = containerRef, secondButtonRef = targetRef })
	end

	local result = renderWithFocusNav(React.createElement(WithBehavior))

	local outerButton = result.getByText("LeftOuterButton")
	moveFocus(outerButton)

	expect(focusNavigationService.focusedGuiObject:getValue()).toBe(outerButton)

	-- Move focus to container...
	local container = result.getByTestId("container")
	local firstButton = result.getByText("FirstButton")
	local secondButton = result.getByText("SecondButton")
	moveFocus(container)

	-- ...and expect it to redirect to SecondButton
	expect(focusNavigationService.focusedGuiObject:getValue()).toBe(secondButton)

	-- Move focus back out of container...
	moveFocus(outerButton)

	-- ...and expect it not to redirect
	expect(focusNavigationService.focusedGuiObject:getValue()).toBe(outerButton)

	-- Move focus to non-default descendant...
	moveFocus(firstButton)

	-- ...and expect it to redirect to FirstButton
	expect(focusNavigationService.focusedGuiObject:getValue()).toBe(secondButton)
end)

it("should clean up the behavior on component unmount", function()
	local function WithBehavior()
		local targetRef = React.useRef(nil)
		local behavior = React.useMemo(function()
			return {
				onDescendantFocusChanged = nil,
				getTargets = function()
					return if targetRef.current then { targetRef.current } else {}
				end,
			}
		end, {})
		local containerRef = useContainerFocusBehavior(behavior)

		return React.createElement(TestUI, { containerRef = containerRef, secondButtonRef = targetRef })
	end

	local result = renderWithFocusNav(React.createElement(WithBehavior))

	local outerButton = result.getByText("LeftOuterButton")
	moveFocus(outerButton)

	expect(focusNavigationService.focusedGuiObject:getValue()).toBe(outerButton)

	-- Move focus to container...
	local container = result.getByTestId("container")
	local secondButton = result.getByText("SecondButton")
	moveFocus(container)

	-- ... and expect it to redirect
	expect(focusNavigationService.focusedGuiObject:getValue()).toBe(secondButton)

	-- Focus back out and then rerender without the special container frame,
	-- which will unmount the bound behavior
	moveFocus(outerButton)
	result.rerender(React.createElement(TestUI))

	-- Move focus to container...
	container = result.getByTestId("container")
	local firstButton = result.getByText("FirstButton")
	moveFocus(container)

	-- ... and expect it NOT to redirect (select the FirstButton button, which is
	-- the engine default via SelectionOrder)
	expect(focusNavigationService.focusedGuiObject:getValue()).toBe(firstButton)
end)
