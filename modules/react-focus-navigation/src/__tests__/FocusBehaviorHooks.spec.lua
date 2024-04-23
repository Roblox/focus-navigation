--!strict
local Packages = script.Parent.Parent.Parent
local React = require(Packages.React)
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

local FocusNavigationContext = require(script.Parent.Parent.FocusNavigationContext)
local FocusBehaviorHooks = require(script.Parent.Parent.FocusBehaviorHooks)

local Utils = require(Packages.FocusNavigationUtils)
local waitForEvents = Utils.waitForEvents

local useDefaultFocusBehavior = FocusBehaviorHooks.useDefaultFocusBehavior
local useMostRecentFocusBehavior = FocusBehaviorHooks.useMostRecentFocusBehavior
local useMostRecentOrDefaultFocusBehavior = FocusBehaviorHooks.useMostRecentOrDefaultFocusBehavior

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

local function moveFocus(target)
	focusNavigationService:focusGuiObject(target)
	waitForEvents() -- wait for focus change to be reacted to
	waitForEvents() -- allow for redirect if necessary
end

describe("useDefaultFocusBehavior", function()
	it("accepts and wraps an existing ref", function()
		local innerRef = React.createRef()
		local function HooksContainer()
			local defaultRef, containerRef = useDefaultFocusBehavior(innerRef)
			return React.createElement(TestUI, { containerRef = containerRef, secondButtonRef = defaultRef })
		end

		renderWithFocusNav(React.createElement(HooksContainer))
		expect(innerRef.current).toEqual(expect.any("Instance"))
	end)

	it("overrides the engine default when used as a hook", function()
		local function HooksContainer()
			local defaultRef, containerRef = useDefaultFocusBehavior()
			return React.createElement(TestUI, { containerRef = containerRef, secondButtonRef = defaultRef })
		end

		local result = renderWithFocusNav(React.createElement(HooksContainer))
		local container = result.getByTestId("container")
		local firstButton = result.getByText("FirstButton")
		local secondButton = result.getByText("SecondButton")

		moveFocus(container)
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(secondButton)

		moveFocus(firstButton)
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(firstButton)

		moveFocus(nil)

		moveFocus(container)
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(secondButton)
	end)

	it("selects the most recently assigned ref value", function()
		local function HooksContainer(props)
			local defaultRef, containerRef = useDefaultFocusBehavior()
			return React.createElement(TestUI, {
				containerRef = containerRef,
				firstButtonRef = if props.defaultFirst then defaultRef else nil,
				secondButtonRef = if not props.defaultFirst then defaultRef else nil,
			})
		end

		local result = renderWithFocusNav(React.createElement(HooksContainer, { defaultFirst = false }))
		local container = result.getByTestId("container")
		local firstButton = result.getByText("FirstButton")
		local secondButton = result.getByText("SecondButton")

		moveFocus(container)
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(secondButton)

		moveFocus(nil)
		result.rerender(React.createElement(HooksContainer, { defaultFirst = true }))

		moveFocus(container)
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(firstButton)
	end)
end)

describe("useMostRecentFocusBehavior", function()
	it("accepts and wraps an existing ref", function()
		local innerRef = React.createRef()
		local function HooksContainer()
			local containerRef = useMostRecentFocusBehavior(innerRef)
			return React.createElement(TestUI, { containerRef = containerRef })
		end

		renderWithFocusNav(React.createElement(HooksContainer))
		expect(innerRef.current).toEqual(expect.any("Instance"))
	end)

	it("lets engine defaults dictate initial selection", function()
		local function HooksContainer()
			local containerRef = useMostRecentFocusBehavior()
			return React.createElement(TestUI, { containerRef = containerRef })
		end

		local result = renderWithFocusNav(React.createElement(HooksContainer))
		local container = result.getByTestId("container")
		local firstButton = result.getByText("FirstButton")

		moveFocus(container)
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(firstButton)
	end)

	it("restores the last-focused child", function()
		local function HooksContainer()
			local containerRef = useMostRecentFocusBehavior()
			return React.createElement(TestUI, { containerRef = containerRef })
		end

		local result = renderWithFocusNav(React.createElement(HooksContainer))
		local container = result.getByTestId("container")
		local firstButton = result.getByText("FirstButton")
		local secondButton = result.getByText("SecondButton")

		moveFocus(container)
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(firstButton)

		moveFocus(secondButton)
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(secondButton)

		moveFocus(nil)

		moveFocus(container)
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(secondButton)
	end)
end)

describe("useMostRecentOrDefaultFocusBehavior", function()
	it("accepts and wraps an existing ref", function()
		local innerRef = React.createRef()
		local function HooksContainer()
			local defaultRef, containerRef = useMostRecentOrDefaultFocusBehavior(innerRef)
			return React.createElement(TestUI, { containerRef = containerRef, secondButtonRef = defaultRef })
		end

		renderWithFocusNav(React.createElement(HooksContainer))
		expect(innerRef.current).toEqual(expect.any("Instance"))
	end)

	it("overrides the engine default", function()
		local function HooksContainer()
			local defaultRef, containerRef = useMostRecentOrDefaultFocusBehavior()
			return React.createElement(TestUI, { containerRef = containerRef, secondButtonRef = defaultRef })
		end

		local result = renderWithFocusNav(React.createElement(HooksContainer))
		local container = result.getByTestId("container")
		local secondButton = result.getByText("SecondButton")

		moveFocus(container)
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(secondButton)
	end)

	it("selects the last-focused child on subsequent focuses", function()
		local function HooksContainer()
			local defaultRef, containerRef = useMostRecentOrDefaultFocusBehavior()
			return React.createElement(TestUI, { containerRef = containerRef, secondButtonRef = defaultRef })
		end

		local result = renderWithFocusNav(React.createElement(HooksContainer))
		local container = result.getByTestId("container")
		local firstButton = result.getByText("FirstButton")
		local secondButton = result.getByText("SecondButton")

		moveFocus(container)
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(secondButton)

		moveFocus(firstButton)
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(firstButton)

		moveFocus(nil)

		moveFocus(container)
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(firstButton)

		moveFocus(secondButton)
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(secondButton)

		moveFocus(nil)

		moveFocus(firstButton)
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(secondButton)
	end)

	it("falls back on default if last focused is invalid", function()
		local function HooksContainer(props)
			local defaultRef, containerRef = useMostRecentOrDefaultFocusBehavior()
			return React.createElement(TestUI, {
				containerRef = containerRef,
				secondButtonRef = if props.assignDefault then defaultRef else nil,
				showThirdButton = props.showThirdButton,
			})
		end

		local result = renderWithFocusNav(
			React.createElement(HooksContainer, { showThirdButton = true, assignDefault = true })
		)
		local container = result.getByTestId("container")
		local firstButton = result.getByText("FirstButton")
		local secondButton = result.getByText("SecondButton")
		local thirdButton = result.getByText("ThirdButton")

		moveFocus(container)
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(secondButton)

		moveFocus(thirdButton)
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(thirdButton)

		moveFocus(nil)

		result.rerender(React.createElement(HooksContainer, { showThirdButton = false, assignDefault = true }))

		-- thirdButton is no longer valid, so select the default child
		-- (secondButton) instead
		moveFocus(container)
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(secondButton)

		-- Select the third button again
		result.rerender(React.createElement(HooksContainer, { showThirdButton = true, assignDefault = true }))

		thirdButton = result.getByText("ThirdButton")
		moveFocus(thirdButton)
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(thirdButton)

		moveFocus(nil)

		-- Rerender with no third button and no default focus ref assigned
		-- to the second button
		result.rerender(React.createElement(HooksContainer, { showThirdButton = false, assignDefault = false }))

		-- Refocusing should now select the engine default, the first button
		moveFocus(container)
		expect(focusNavigationService.focusedGuiObject:getValue()).toBe(firstButton)
	end)
end)
