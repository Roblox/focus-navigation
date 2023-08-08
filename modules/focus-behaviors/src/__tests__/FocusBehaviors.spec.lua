--!strict
local Packages = script.Parent.Parent.Parent
local React = require(Packages.Dev.React)
local Object = require(Packages.Dev.Collections).Object

local FocusNavigation = require(Packages.FocusNavigation)
local FocusNavigationService = FocusNavigation.FocusNavigationService

local JestGlobals = require(Packages.Dev.JestGlobals)
local it = JestGlobals.it
local describe = JestGlobals.describe
local expect = JestGlobals.expect
local afterEach = JestGlobals.afterEach
local beforeEach = JestGlobals.beforeEach

local ReactTestingLibrary = require(Packages.Dev.ReactTestingLibrary)
local render = ReactTestingLibrary.render
local cleanup = ReactTestingLibrary.cleanup

local waitForEvents = require(Packages.Dev.Utils).waitForEvents

local FocusNavigationContext = require(Packages.Dev.ReactFocusNavigation).FocusNavigationContext
local FocusBehaviors = require(script.Parent.Parent)

local default = FocusBehaviors.default
local mostRecent = FocusBehaviors.mostRecent
local mostRecentOrDefault = FocusBehaviors.mostRecentOrDefault

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

local function moveFocus(target)
	focusNavigationService:focusGuiObject(target)
	waitForEvents() -- wait for focus change to be reacted to
	waitForEvents() -- allow for redirect if necessary
end

local function TestUI(
	props: {
		showThirdButton: boolean?,
		containerRef: React.Ref<Instance>?,
		firstButtonRef: React.Ref<Instance>?,
		secondButtonRef: React.Ref<Instance>?,
		thirdButtonRef: React.Ref<Instance>?,
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
					Size = UDim2.fromOffset(100, 100),
					ref = props.firstButtonRef,
				}),
				SecondButton = React.createElement("TextButton", {
					SelectionOrder = 2,
					Text = "SecondButton",
					Size = UDim2.fromOffset(100, 100),
					Position = UDim2.fromOffset(100, 0),
					ref = props.secondButtonRef,
				}),
				ThirdButton = if props.showThirdButton
					then React.createElement("TextButton", {
						SelectionOrder = 3,
						Text = "ThirdButton",
						Size = UDim2.fromOffset(100, 100),
						Position = UDim2.fromOffset(200, 0),
						ref = props.thirdButtonRef,
					})
					else nil,
			}),
		})
	)
end

describe("default", function()
	it("returns the provided default", function()
		local result = renderWithFocusNav(React.createElement(TestUI))
		local container = result.getByTestId("container")

		local secondButton = result.getByText("SecondButton")
		local behavior = default(secondButton)

		focusNavigationService:registerFocusBehavior(container, behavior)

		moveFocus(container)
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(secondButton)
	end)
end)

describe("mostRecent", function()
	it("uses the engine's default selection at first", function()
		local result = renderWithFocusNav(React.createElement(TestUI))
		local container = result.getByTestId("container")

		focusNavigationService:registerFocusBehavior(container, mostRecent())

		moveFocus(container)

		local firstButton = result.getByText("FirstButton")
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(firstButton)
	end)

	it("restores the last-focused child", function()
		local result = renderWithFocusNav(React.createElement(TestUI))
		local container = result.getByTestId("container")
		local firstButton = result.getByText("FirstButton")
		local secondButton = result.getByText("SecondButton")

		focusNavigationService:registerFocusBehavior(container, mostRecent())
		moveFocus(firstButton)
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(firstButton)

		moveFocus(secondButton)
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(secondButton)

		moveFocus(nil)

		moveFocus(container)
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(secondButton)
	end)

	it("udpates the last-focused child when focus moves internally", function()
		local result = renderWithFocusNav(React.createElement(TestUI))
		local container = result.getByTestId("container")
		local firstButton = result.getByText("FirstButton")
		local secondButton = result.getByText("SecondButton")

		focusNavigationService:registerFocusBehavior(container, mostRecent())
		moveFocus(firstButton)
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(firstButton)

		moveFocus(secondButton)
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(secondButton)

		moveFocus(nil)

		moveFocus(container)
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(secondButton)

		moveFocus(firstButton)
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(firstButton)

		moveFocus(nil)

		moveFocus(container)
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(firstButton)
	end)

	it("restores focus to a previously restored focus target", function()
		local result = renderWithFocusNav(React.createElement(TestUI))
		local container = result.getByTestId("container")
		local firstButton = result.getByText("FirstButton")
		local secondButton = result.getByText("SecondButton")

		focusNavigationService:registerFocusBehavior(container, mostRecent())
		moveFocus(firstButton)
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(firstButton)

		moveFocus(secondButton)
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(secondButton)

		moveFocus(nil)

		moveFocus(container)
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(secondButton)

		moveFocus(nil)

		moveFocus(firstButton)
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(secondButton)
	end)

	it("does not restore focus to a non-descendant", function()
		local result = renderWithFocusNav(React.createElement(TestUI))
		local container = result.getByTestId("container")
		local secondButton = result.getByText("SecondButton")
		local leftOuter = result.getByText("LeftOuterButton")

		focusNavigationService:registerFocusBehavior(container, mostRecent())
		moveFocus(secondButton)
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(secondButton)

		moveFocus(leftOuter)
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(leftOuter)

		moveFocus(nil)

		moveFocus(container)
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(secondButton)
	end)
end)

describe("mostRecentOrDefault", function()
	it("falls back to default when no selections have been made", function()
		local result = renderWithFocusNav(React.createElement(TestUI))
		local container = result.getByTestId("container")
		local secondButton = result.getByText("SecondButton")

		local behavior = mostRecentOrDefault(secondButton)
		focusNavigationService:registerFocusBehavior(container, behavior)

		moveFocus(container)
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(secondButton)
	end)

	it("restores last-focused descendant after first focus", function()
		local result = renderWithFocusNav(React.createElement(TestUI))
		local container = result.getByTestId("container")
		local firstButton = result.getByText("FirstButton")
		local secondButton = result.getByText("SecondButton")

		local behavior = mostRecentOrDefault(secondButton)
		focusNavigationService:registerFocusBehavior(container, behavior)

		moveFocus(container)
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(secondButton)

		moveFocus(firstButton)
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(firstButton)

		moveFocus(nil)

		moveFocus(container)
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(firstButton)
	end)
end)
