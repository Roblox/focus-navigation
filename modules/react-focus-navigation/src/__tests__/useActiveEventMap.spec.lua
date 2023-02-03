--!strict
local Packages = script.Parent.Parent.Parent
local React = require(Packages.React)
local FocusNavigation = require(Packages.FocusNavigation)
local FocusNavigationService = FocusNavigation.FocusNavigationService

local JestGlobals = require(Packages.Dev.JestGlobals)
local it = JestGlobals.it
local expect = JestGlobals.expect
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach

local ReactTestingLibrary = require(Packages.Dev.ReactTestingLibrary)
local render = ReactTestingLibrary.render
local cleanup = ReactTestingLibrary.cleanup

local Collections = require(Packages.Dev.Collections)
local Object = Collections.Object

local FocusNavigationContext = require(script.Parent.Parent.FocusNavigationContext)
local useActiveEventMap = require(script.Parent.Parent.useActiveEventMap)

local focusNavigationService
beforeEach(function()
	focusNavigationService = FocusNavigationService.new(FocusNavigation.EngineInterface.CoreGui)
end)

afterEach(function()
	focusNavigationService:focusGuiObject(nil)
	focusNavigationService:teardown()
	cleanup()
end)

local function ActiveEventViewer(props)
	local eventMap = useActiveEventMap()
	local children = {}
	if eventMap and next(eventMap) then
		children.UIListLayout = React.createElement("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder })
		local i = 1
		for input, eventName in eventMap do
			children[tostring(i)] = React.createElement("TextLabel", {
				LayoutOrder = i,
				Text = input.Name .. ": " .. eventName,
				Size = UDim2.fromOffset(200, 50),
			})
			i += 1
		end
	else
		children.NoEventMap = React.createElement("TextLabel", {
			Text = "No Active Events",
		})
	end

	return React.createElement(
		"Frame",
		{ Selectable = true, Size = UDim2.fromScale(1, 1), ref = props.containerRef },
		children :: any
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
	local result = render(React.createElement(ActiveEventViewer))

	expect(result.queryByText("No Active Events")).toBeDefined()
end)

it("return the current active event map", function()
	local CoreGui = game:GetService("CoreGui")
	local screenGui = Instance.new("ScreenGui")
	screenGui.Parent = CoreGui
	local container = Instance.new("Frame")
	container.Selectable = true
	container.Parent = screenGui
	focusNavigationService:registerEventMap(container, {
		[Enum.KeyCode.W] = "Jump",
	})
	focusNavigationService:focusGuiObject(container, false)

	local result = renderWithFocusNav(React.createElement(ActiveEventViewer, { container = container } :: any))
	expect(result.queryByText("W: Jump")).toBeDefined()
end)

it("updates the active event map when it changes due to focus change", function()
	local ref = React.createRef()
	local result = renderWithFocusNav(React.createElement(ActiveEventViewer, { containerRef = ref }))
	focusNavigationService:registerEventMap(ref.current, {
		[Enum.KeyCode.Z] = "Attack",
		[Enum.KeyCode.X] = "Special",
	})

	expect(result.queryByText("No Active Events")).toBeDefined()

	focusNavigationService:focusGuiObject(ref.current, false)

	expect(result.queryByText("Z: Attack")).toBeDefined()
	expect(result.queryByText("X: Special")).toBeDefined()
end)

it("updates the active event map when event maps get reassigned", function()
	local ref = React.createRef()
	local result = renderWithFocusNav(React.createElement(ActiveEventViewer, { containerRef = ref }))
	focusNavigationService:registerEventMap(ref.current, {
		[Enum.KeyCode.Z] = "Attack",
	})

	expect(result.queryByText("No Active Events")).toBeDefined()

	focusNavigationService:focusGuiObject(ref.current, false)

	expect(result.queryByText("Z: Attack")).toBeDefined()
	expect(result.queryByText("X: Block")).toBeNil()
	focusNavigationService:registerEventMap(ref.current, {
		[Enum.KeyCode.X] = "Block",
	})

	expect(result.queryByText("Z: Attack")).toBeDefined()
	expect(result.queryByText("X: Block")).toBeDefined()

	focusNavigationService:deregisterEventMap(ref.current, {
		[Enum.KeyCode.Z] = "Attack",
	})
	expect(result.queryByText("Z: Attack")).toBeNil()
	expect(result.queryByText("X: Block")).toBeDefined()
end)

it("updates the active event map when the FocusNavigationService changes", function()
	local ref = React.createRef()
	local result = renderWithFocusNav(React.createElement(ActiveEventViewer, { containerRef = ref }))
	focusNavigationService:registerEventMap(ref.current, {
		[Enum.KeyCode.Z] = "Attack",
	})

	expect(result.queryByText("No Active Events")).toBeDefined()

	focusNavigationService:focusGuiObject(ref.current, false)

	expect(result.queryByText("Z: Attack")).toBeDefined()

	focusNavigationService:teardown()
	focusNavigationService = FocusNavigationService.new(FocusNavigation.EngineInterface.CoreGui)
	focusNavigationService:registerEventMap(ref.current, {
		[Enum.KeyCode.W] = "Jump",
	})

	-- Rerender to assign the new context value
	result.rerender(React.createElement(ActiveEventViewer, { containerRef = ref }))

	expect(result.queryByText("Z: Attack")).toBeNil()
	expect(result.queryByText("W: Jump")).toBeDefined()
end)
