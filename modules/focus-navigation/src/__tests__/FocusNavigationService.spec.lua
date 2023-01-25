--!strict
local GuiService = game:GetService("GuiService")

local Packages = script.Parent.Parent.Parent
local JestGlobals = require(Packages.Dev.JestGlobals)
local EventPropagation = require(Packages.EventPropagation)

local jest = JestGlobals.jest
local it = JestGlobals.it
local expect = JestGlobals.expect
local describe = JestGlobals.describe
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach

local MockEngineInterface = require(script.Parent.MockEngineInterface)
local createGuiObjectTree = require(script.Parent.createGuiObjectTree)

local FocusNavigationService = require(script.Parent.Parent.FocusNavigationService)
local EngineInterface = require(script.Parent.Parent.EngineInterface)

type EventPhase = EventPropagation.EventPhase
type EventHandler = FocusNavigationService.EventHandler

local CoreGui = game:GetService("CoreGui")
local PlayerGui = (game:GetService("Players").LocalPlayer :: any).PlayerGui

local beginAEvent = {
	KeyCode = Enum.KeyCode.A,
	UserInputType = Enum.UserInputType.Gamepad1,
	UserInputState = Enum.UserInputState.Begin,
}

local function getMountedGui(mountTarget)
	return createGuiObjectTree({
		root = { "ScreenGui", mountTarget },
		leftButton = { "ImageButton", "root", { Size = UDim2.fromScale(0.5, 0.5) } },
		rightButton = { "ImageButton", "root", { Size = UDim2.fromScale(0.5, 0.5) } },
	})
end

local mockEngineInterface, focusNavigationService
beforeEach(function()
	mockEngineInterface = MockEngineInterface.new()
	focusNavigationService = FocusNavigationService.new(mockEngineInterface)
end)
afterEach(function()
	focusNavigationService:teardown()
	GuiService.SelectedObject = nil
	GuiService.SelectedCoreObject = nil
end)

describe("Basic functionality", function()
	local tree
	beforeEach(function()
		tree = createGuiObjectTree({
			root = { "ScreenGui", PlayerGui },
			leftButton = { "ImageButton", "root", { Size = UDim2.fromScale(0.5, 0.5) } },
			rightButton = { "ImageButton", "root", { Size = UDim2.fromScale(0.5, 0.5) } },
		})
	end)
	afterEach(function()
		tree.root:Destroy()
	end)

	it("should connect to input events and GuiService", function()
		local interface = MockEngineInterface.new()
		local service = FocusNavigationService.new(interface)
		expect(interface.InputBegan.Connect).toHaveBeenCalledTimes(1)
		expect(interface.InputChanged.Connect).toHaveBeenCalledTimes(1)
		expect(interface.InputEnded.Connect).toHaveBeenCalledTimes(1)
		expect(interface.SelectionChanged.Connect).toHaveBeenCalledTimes(1)

		service:teardown()
		expect(interface.mock.InputBeganDisconnected).toHaveBeenCalledTimes(1)
		expect(interface.mock.InputChangedDisconnected).toHaveBeenCalledTimes(1)
		expect(interface.mock.InputEndedDisconnected).toHaveBeenCalledTimes(1)
		expect(interface.mock.SelectionChangedDisconnected).toHaveBeenCalledTimes(1)
	end)

	it("should be able to focus the correct input property under CoreGui", function()
		local mountedTree = getMountedGui(CoreGui)
		local service = FocusNavigationService.new(EngineInterface.CoreGui)
		service:focusGuiObject(mountedTree.leftButton, false)
		expect(GuiService.SelectedCoreObject).toEqual(mountedTree.leftButton)
		expect(GuiService.SelectedObject).toBeNil()
	end)

	it("should be able to focus the correct input property under PlayerGui", function()
		local mountedTree = getMountedGui(PlayerGui)
		local service = FocusNavigationService.new(EngineInterface.PlayerGui)
		service:focusGuiObject(mountedTree.leftButton, false)
		expect(GuiService.SelectedObject).toEqual(mountedTree.leftButton)
		expect(GuiService.SelectedCoreObject).toBeNil()
	end)

	it("should allow input events to be registered on instances", function()
		focusNavigationService:registerEventMap(tree.leftButton, {
			[Enum.KeyCode.A] = "confirm",
		})
		local eventHandler = jest.fn()
		focusNavigationService:registerEventHandler(tree.leftButton, "confirm", eventHandler, "Target")

		focusNavigationService:focusGuiObject(tree.rightButton, true)
		mockEngineInterface.simulateInput(beginAEvent)

		expect(eventHandler).toHaveBeenCalledTimes(0)

		focusNavigationService:focusGuiObject(tree.leftButton, true)
		mockEngineInterface.simulateInput(beginAEvent)

		expect(eventHandler).toHaveBeenCalledTimes(1)
		expect(eventHandler).toHaveBeenCalledWith(expect.objectContaining({
			eventData = beginAEvent,
		}))

		focusNavigationService:deregisterEventHandler(tree.leftButton, "confirm", eventHandler, "Target")
		mockEngineInterface.simulateInput(beginAEvent)
		expect(eventHandler).toHaveBeenCalledTimes(1)
	end)

	it("should only fire events for active event maps", function()
		local eventHandler = jest.fn()
		focusNavigationService:focusGuiObject(tree.leftButton, true)
		focusNavigationService:registerEventHandler(tree.leftButton, "confirm", eventHandler, "Target")

		mockEngineInterface.simulateInput(beginAEvent)
		expect(eventHandler).toHaveBeenCalledTimes(0)

		focusNavigationService:registerEventMap(tree.leftButton, {
			[Enum.KeyCode.A] = "confirm",
		})

		mockEngineInterface.simulateInput(beginAEvent)

		expect(eventHandler).toHaveBeenCalledTimes(1)
		expect(eventHandler).toHaveBeenCalledWith(expect.objectContaining({
			eventData = beginAEvent,
		}))

		focusNavigationService:deregisterEventMap(tree.leftButton, {
			[Enum.KeyCode.A] = "confirm",
		})
		mockEngineInterface.simulateInput(beginAEvent)
		expect(eventHandler).toHaveBeenCalledTimes(1)
	end)

	it("should allow handlers to be registered before event maps", function()
		local eventHandler = jest.fn()
		focusNavigationService:registerEventHandlers(tree.leftButton, {
			confirm = {
				phase = "Target",
				handler = eventHandler,
			},
		})
		focusNavigationService:registerEventMap(tree.leftButton, {
			[Enum.KeyCode.A] = "confirm",
		})

		focusNavigationService:focusGuiObject(tree.rightButton, true)
		mockEngineInterface.simulateInput(beginAEvent)

		expect(eventHandler).toHaveBeenCalledTimes(0)

		focusNavigationService:focusGuiObject(tree.leftButton, true)
		mockEngineInterface.simulateInput(beginAEvent)

		expect(eventHandler).toHaveBeenCalledTimes(1)
		expect(eventHandler).toHaveBeenCalledWith(expect.objectContaining({
			eventData = beginAEvent,
		}))
	end)

	it("should only invoke events that match registered names", function()
		local eventHandler = jest.fn()
		focusNavigationService:registerEventHandlers(tree.leftButton, {
			confirm = {
				phase = "Target",
				handler = eventHandler,
			},
		})
		focusNavigationService:registerEventMap(tree.leftButton, {
			[Enum.KeyCode.A] = "confirm",
			[Enum.KeyCode.B] = "cancel",
		})

		focusNavigationService:focusGuiObject(tree.leftButton, true)
		local cancelEvent = table.clone(beginAEvent)
		cancelEvent.KeyCode = Enum.KeyCode.B
		mockEngineInterface.simulateInput(cancelEvent)

		expect(eventHandler).toHaveBeenCalledTimes(0)

		mockEngineInterface.simulateInput(beginAEvent)

		expect(eventHandler).toHaveBeenCalledTimes(1)
		expect(eventHandler).toHaveBeenCalledWith(expect.objectContaining({
			eventData = beginAEvent,
		}))
	end)

	describe("input event propagation", function()
		local function getConfirmHandlerMap(phase: EventPhase?, handler)
			return {
				confirm = {
					phase = phase,
					handler = jest.fn(handler) :: EventHandler,
				},
			}
		end

		it("should capture events through parents", function()
			local handlerMap = getConfirmHandlerMap("Capture")

			focusNavigationService:registerEventHandlers(tree.root, handlerMap)
			focusNavigationService:registerEventHandlers(tree.leftButton, handlerMap)
			focusNavigationService:registerEventMap(tree.leftButton, {
				[Enum.KeyCode.A] = "confirm",
			})
			focusNavigationService:registerEventMap(tree.root, {
				[Enum.KeyCode.A] = "confirm",
			})

			focusNavigationService:focusGuiObject(tree.leftButton, true)
			expect(handlerMap.confirm.handler).toHaveBeenCalledTimes(0)

			mockEngineInterface.simulateInput(beginAEvent)

			expect(handlerMap.confirm.handler).toHaveBeenCalledTimes(2)
			expect(handlerMap.confirm.handler).toHaveBeenNthCalledWith(
				1,
				expect.objectContaining({
					currentInstance = tree.root,
					targetInstance = tree.leftButton,
					eventData = beginAEvent,
				})
			)
			expect(handlerMap.confirm.handler).toHaveBeenNthCalledWith(
				2,
				expect.objectContaining({
					currentInstance = tree.leftButton,
					targetInstance = tree.leftButton,
					eventData = beginAEvent,
				})
			)
		end)

		it("should allow cancelling at the capture phase", function()
			local handlerMap = getConfirmHandlerMap("Capture", function(event)
				event:cancel()
			end)
			focusNavigationService:registerEventHandlers(tree.root, handlerMap)
			focusNavigationService:registerEventHandlers(tree.leftButton, handlerMap)
			focusNavigationService:registerEventMap(tree.leftButton, {
				[Enum.KeyCode.A] = "confirm",
			})
			focusNavigationService:registerEventMap(tree.root, {
				[Enum.KeyCode.A] = "confirm",
			})

			focusNavigationService:focusGuiObject(tree.leftButton, true)
			expect(handlerMap.confirm.handler).toHaveBeenCalledTimes(0)

			mockEngineInterface.simulateInput(beginAEvent)

			expect(handlerMap.confirm.handler).toHaveBeenCalledTimes(1)
			expect(handlerMap.confirm.handler).toHaveBeenLastCalledWith(expect.objectContaining({
				currentInstance = tree.root,
				targetInstance = tree.leftButton,
				eventData = beginAEvent,
			}))
		end)

		it("should bubble events through parents", function()
			local handlerMap = getConfirmHandlerMap("Bubble")
			focusNavigationService:registerEventHandlers(tree.root, handlerMap)
			focusNavigationService:registerEventHandlers(tree.leftButton, handlerMap)
			focusNavigationService:registerEventMap(tree.leftButton, {
				[Enum.KeyCode.A] = "confirm",
			})
			focusNavigationService:registerEventMap(tree.root, {
				[Enum.KeyCode.A] = "confirm",
			})

			focusNavigationService:focusGuiObject(tree.leftButton, true)
			expect(handlerMap.confirm.handler).toHaveBeenCalledTimes(0)

			mockEngineInterface.simulateInput(beginAEvent)

			expect(handlerMap.confirm.handler).toHaveBeenCalledTimes(2)
			expect(handlerMap.confirm.handler).toHaveBeenNthCalledWith(
				1,
				expect.objectContaining({
					currentInstance = tree.leftButton,
					targetInstance = tree.leftButton,
					eventData = beginAEvent,
				})
			)
			expect(handlerMap.confirm.handler).toHaveBeenNthCalledWith(
				2,
				expect.objectContaining({
					currentInstance = tree.root,
					targetInstance = tree.leftButton,
					eventData = beginAEvent,
				})
			)
		end)

		it("should allow cancelling at the bubble phase", function()
			local handlerMap = getConfirmHandlerMap("Bubble", function(event)
				event:cancel()
			end)
			focusNavigationService:registerEventHandlers(tree.root, handlerMap)
			focusNavigationService:registerEventHandlers(tree.leftButton, handlerMap)
			focusNavigationService:registerEventMap(tree.leftButton, {
				[Enum.KeyCode.A] = "confirm",
			})
			focusNavigationService:registerEventMap(tree.root, {
				[Enum.KeyCode.A] = "confirm",
			})

			focusNavigationService:focusGuiObject(tree.leftButton, true)
			expect(handlerMap.confirm.handler).toHaveBeenCalledTimes(0)

			mockEngineInterface.simulateInput(beginAEvent)

			expect(handlerMap.confirm.handler).toHaveBeenCalledTimes(1)
			expect(handlerMap.confirm.handler).toHaveBeenLastCalledWith(expect.objectContaining({
				currentInstance = tree.leftButton,
				targetInstance = tree.leftButton,
				eventData = beginAEvent,
			}))
		end)
	end)

	-- TODO: What sort of warnings/failure modes should we have here?
	-- it("should warn when invoking an undefined event", function() end)
end)

-- FIXME Luau: types don't play nicely with callable tables
type FIXME_ANALYZE = any
local describeEach = describe.each :: FIXME_ANALYZE
describeEach({ { phase = "Capture" }, { phase = "Bubble" } })("focus and blur: $phase phase", function(phaseConfig)
	local function getHandlerMap(phase, onBlur, onFocus)
		return {
			blur = {
				phase = phase,
				handler = jest.fn(onBlur) :: EventHandler,
			},
			focus = {
				phase = phase,
				handler = jest.fn(onFocus) :: EventHandler,
			},
		}
	end

	local tree
	beforeEach(function()
		tree = createGuiObjectTree({
			root = { "ScreenGui", PlayerGui },
			leftContainer = { "Frame", "root", { Size = UDim2.fromScale(1, 1) } },
			leftButton = { "ImageButton", "leftContainer", { Size = UDim2.fromScale(0.5, 0.5) } },
			rightContainer = { "Frame", "root", { Size = UDim2.fromScale(1, 1) } },
			rightButton = { "ImageButton", "rightContainer", { Size = UDim2.fromScale(0.5, 0.5) } },
		})
	end)
	afterEach(function()
		tree.root:Destroy()
	end)

	it("should send blur and focus events when changing focus", function()
		focusNavigationService:focusGuiObject(tree.leftButton, false)

		local handlerMap = getHandlerMap(phaseConfig.phase)
		focusNavigationService:registerEventHandlers(tree.leftButton, handlerMap)
		focusNavigationService:registerEventHandlers(tree.rightButton, handlerMap)

		focusNavigationService:focusGuiObject(tree.rightButton, false)

		expect(handlerMap.blur.handler).toHaveBeenCalledTimes(1)
		expect((handlerMap.blur.handler :: any).mock.calls).toEqual({
			{ expect.objectContaining({ currentInstance = tree.leftButton }) },
		})
		expect(handlerMap.focus.handler).toHaveBeenCalledTimes(1)
		expect((handlerMap.focus.handler :: any).mock.calls).toEqual({
			{ expect.objectContaining({ currentInstance = tree.rightButton }) },
		})
	end)

	it("should not send blur and focus events unless they're registered", function()
		focusNavigationService:focusGuiObject(tree.rightButton, false)
		local handlerMap = getHandlerMap(phaseConfig.phase)

		focusNavigationService:focusGuiObject(tree.leftButton, false)
		expect(handlerMap.blur.handler).toHaveBeenCalledTimes(0)
		expect(handlerMap.focus.handler).toHaveBeenCalledTimes(0)

		focusNavigationService:registerEventHandlers(tree.leftButton, handlerMap)
		focusNavigationService:registerEventHandlers(tree.rightButton, handlerMap)

		focusNavigationService:focusGuiObject(tree.rightButton, false)

		expect(handlerMap.blur.handler).toHaveBeenCalledTimes(1)
		expect((handlerMap.blur.handler :: any).mock.calls).toEqual({
			{ expect.objectContaining({ currentInstance = tree.leftButton }) },
		})
		expect(handlerMap.focus.handler).toHaveBeenCalledTimes(1)
		expect((handlerMap.focus.handler :: any).mock.calls).toEqual({
			{ expect.objectContaining({ currentInstance = tree.rightButton }) },
		})

		focusNavigationService:deregisterEventHandlers(tree.leftButton, handlerMap)
		focusNavigationService:deregisterEventHandlers(tree.rightButton, handlerMap)

		expect(handlerMap.blur.handler).toHaveBeenCalledTimes(1)
		expect(handlerMap.focus.handler).toHaveBeenCalledTimes(1)
	end)

	it("should only send events for the SelectedCoreObject under CoreGui", function()
		local mountedTree = getMountedGui(CoreGui)
		local service = FocusNavigationService.new(EngineInterface.CoreGui)
		service:focusGuiObject(mountedTree.leftButton, false)

		local handlerMap = getHandlerMap(phaseConfig.phase)
		service:registerEventHandlers(mountedTree.leftButton, handlerMap)
		service:registerEventHandlers(mountedTree.rightButton, handlerMap)

		GuiService.SelectedCoreObject = mountedTree.rightButton

		expect(handlerMap.blur.handler).toHaveBeenCalledTimes(1)
		expect(handlerMap.focus.handler).toHaveBeenCalledTimes(1)

		-- move non-core focus
		GuiService.SelectedObject = mountedTree.leftButton

		-- No new callbacks should have happened
		expect(handlerMap.blur.handler).toHaveBeenCalledTimes(1)
		expect(handlerMap.focus.handler).toHaveBeenCalledTimes(1)
	end)

	it("should only send events for the SelectedObject under PlayerGui", function()
		local mountedTree = getMountedGui(PlayerGui)
		local service = FocusNavigationService.new(EngineInterface.PlayerGui)
		service:focusGuiObject(mountedTree.leftButton, false)

		local handlerMap = getHandlerMap(phaseConfig.phase)
		service:registerEventHandlers(mountedTree.leftButton, handlerMap)
		service:registerEventHandlers(mountedTree.rightButton, handlerMap)

		GuiService.SelectedObject = mountedTree.rightButton

		expect(handlerMap.blur.handler).toHaveBeenCalledTimes(1)
		expect(handlerMap.focus.handler).toHaveBeenCalledTimes(1)

		-- move core focus
		GuiService.SelectedCoreObject = mountedTree.leftContainer

		-- No new callbacks should have happened
		expect(handlerMap.blur.handler).toHaveBeenCalledTimes(1)
		expect(handlerMap.focus.handler).toHaveBeenCalledTimes(1)
	end)

	it("should propagate blur events", function()
		focusNavigationService:focusGuiObject(tree.leftButton, false)

		local handlerMap = getHandlerMap(phaseConfig.phase)
		focusNavigationService:registerEventHandlers(tree.root, handlerMap)
		focusNavigationService:registerEventHandlers(tree.leftContainer, handlerMap)
		focusNavigationService:registerEventHandlers(tree.leftButton, handlerMap)
		focusNavigationService:focusGuiObject(tree.rightButton, false)

		expect(handlerMap.blur.handler).toHaveBeenCalledTimes(3)
		if phaseConfig.phase == "Capture" then
			expect((handlerMap.blur.handler :: any).mock.calls).toEqual({
				{ expect.objectContaining({ currentInstance = tree.root }) },
				{ expect.objectContaining({ currentInstance = tree.leftContainer }) },
				{ expect.objectContaining({ currentInstance = tree.leftButton }) },
			})
		else
			expect((handlerMap.blur.handler :: any).mock.calls).toEqual({
				{ expect.objectContaining({ currentInstance = tree.leftButton }) },
				{ expect.objectContaining({ currentInstance = tree.leftContainer }) },
				{ expect.objectContaining({ currentInstance = tree.root }) },
			})
		end
	end)

	it("should not propagate blur events when silent == true", function()
		focusNavigationService:focusGuiObject(tree.leftButton, false)

		local handlerMap = getHandlerMap(phaseConfig.phase)
		focusNavigationService:registerEventHandlers(tree.root, handlerMap)
		focusNavigationService:registerEventHandlers(tree.leftContainer, handlerMap)
		focusNavigationService:registerEventHandlers(tree.leftButton, handlerMap)
		focusNavigationService:focusGuiObject(tree.rightButton, true)

		expect(handlerMap.blur.handler).toHaveBeenCalledTimes(1)
		expect((handlerMap.blur.handler :: any).mock.calls).toEqual({
			{ expect.objectContaining({ currentInstance = tree.leftButton }) },
		})
	end)

	it("should propagate focus events", function()
		focusNavigationService:focusGuiObject(tree.leftButton, false)

		local handlerMap = getHandlerMap(phaseConfig.phase)
		focusNavigationService:registerEventHandlers(tree.root, handlerMap)
		focusNavigationService:registerEventHandlers(tree.rightContainer, handlerMap)
		focusNavigationService:registerEventHandlers(tree.rightButton, handlerMap)

		focusNavigationService:focusGuiObject(tree.rightButton, false)

		expect(handlerMap.focus.handler).toHaveBeenCalledTimes(3)
		if phaseConfig.phase == "Capture" then
			expect((handlerMap.focus.handler :: any).mock.calls).toEqual({
				{ expect.objectContaining({ currentInstance = tree.root }) },
				{ expect.objectContaining({ currentInstance = tree.rightContainer }) },
				{ expect.objectContaining({ currentInstance = tree.rightButton }) },
			})
		else
			expect((handlerMap.focus.handler :: any).mock.calls).toEqual({
				{ expect.objectContaining({ currentInstance = tree.rightButton }) },
				{ expect.objectContaining({ currentInstance = tree.rightContainer }) },
				{ expect.objectContaining({ currentInstance = tree.root }) },
			})
		end
	end)

	it("should not propagate focus events when silent == true", function()
		focusNavigationService:focusGuiObject(tree.leftButton, false)

		local handlerMap = getHandlerMap(phaseConfig.phase)
		focusNavigationService:registerEventHandlers(tree.root, handlerMap)
		focusNavigationService:registerEventHandlers(tree.rightContainer, handlerMap)
		focusNavigationService:registerEventHandlers(tree.rightButton, handlerMap)

		focusNavigationService:focusGuiObject(tree.rightButton, true)

		expect(handlerMap.focus.handler).toHaveBeenCalledTimes(1)
		expect((handlerMap.focus.handler :: any).mock.calls).toEqual({
			{ expect.objectContaining({ currentInstance = tree.rightButton }) },
		})
	end)
end)

describe("observable properties", function()
	local tree
	beforeEach(function()
		tree = createGuiObjectTree({
			root = { "ScreenGui", PlayerGui },
			leftContainer = { "Frame", "root", { Size = UDim2.fromScale(1, 1) } },
			leftButton = { "ImageButton", "leftContainer", { Size = UDim2.fromScale(0.5, 0.5) } },
			rightContainer = { "Frame", "root", { Size = UDim2.fromScale(1, 1) } },
			rightButton = { "ImageButton", "rightContainer", { Size = UDim2.fromScale(0.5, 0.5) } },
		})
	end)
	afterEach(function()
		tree.root:Destroy()
	end)

	it("should expose an observable for currently-focused GuiObject", function()
		focusNavigationService:focusGuiObject(tree.leftButton, false)

		local observer = {
			next = jest.fn(),
		}
		local subscription = focusNavigationService.focusedGuiObject:subscribe(observer)

		expect(observer.next).toHaveBeenCalledTimes(0)

		focusNavigationService:focusGuiObject(tree.rightButton, false)

		expect(observer.next).toHaveBeenCalledTimes(1)
		expect(observer.next).toHaveBeenLastCalledWith(expect.anything(), tree.rightButton)

		focusNavigationService:focusGuiObject(tree.leftButton, false)
		expect(observer.next).toHaveBeenCalledTimes(2)
		expect(observer.next).toHaveBeenLastCalledWith(expect.anything(), tree.leftButton)

		subscription:unsubscribe()
		focusNavigationService:focusGuiObject(tree.rightButton, false)
		expect(observer.next).toHaveBeenCalledTimes(2)
	end)

	it("should allow multiple subscribers to currently-focused object", function()
		focusNavigationService:focusGuiObject(tree.leftButton, false)

		local observer = {
			next = jest.fn(),
		}
		local subscription1 = focusNavigationService.focusedGuiObject:subscribe(observer)
		local subscription2 = focusNavigationService.focusedGuiObject:subscribe(observer)

		expect(observer.next).toHaveBeenCalledTimes(0)

		focusNavigationService:focusGuiObject(tree.rightButton, false)

		expect(observer.next).toHaveBeenCalledTimes(2)

		subscription1:unsubscribe()
		focusNavigationService:focusGuiObject(tree.leftButton, false)
		expect(observer.next).toHaveBeenCalledTimes(3)

		local subscription3 = focusNavigationService.focusedGuiObject:subscribe(observer)

		focusNavigationService:focusGuiObject(tree.rightButton, false)
		expect(observer.next).toHaveBeenCalledTimes(5)

		subscription2:unsubscribe()
		subscription3:unsubscribe()

		focusNavigationService:focusGuiObject(tree.leftButton, false)
		expect(observer.next).toHaveBeenCalledTimes(5)
	end)

	it("should expose an observable for currently-active event map", function()
		local observer = {
			next = jest.fn(),
		}
		local subscription = focusNavigationService.activeEventMap:subscribe(observer)

		expect(observer.next).toHaveBeenCalledTimes(0)
		focusNavigationService:registerEventMap(tree.leftButton, {
			[Enum.KeyCode.ButtonX] = "foo",
			[Enum.KeyCode.ButtonY] = "bar",
		})

		focusNavigationService:focusGuiObject(tree.leftButton, false)
		expect(observer.next).toHaveBeenCalledTimes(1)
		expect(observer.next).toHaveBeenLastCalledWith(expect.anything(), {
			[Enum.KeyCode.ButtonX] = "foo",
			[Enum.KeyCode.ButtonY] = "bar",
		})

		focusNavigationService:focusGuiObject(tree.rightButton, false)
		expect(observer.next).toHaveBeenCalledTimes(2)
		expect(observer.next).toHaveBeenLastCalledWith(expect.anything(), {})

		subscription:unsubscribe()
		focusNavigationService:focusGuiObject(tree.leftButton, false)
		expect(observer.next).toHaveBeenCalledTimes(2)
	end)

	it("should overlay event maps down the tree", function()
		focusNavigationService:registerEventMap(tree.root, {
			[Enum.KeyCode.ButtonX] = "rootEvent",
		})
		focusNavigationService:registerEventMap(tree.rightContainer, {
			[Enum.KeyCode.ButtonX] = "overrideRootEvent",
			[Enum.KeyCode.ButtonY] = "containerEvent",
		})
		focusNavigationService:registerEventMap(tree.rightButton, {
			[Enum.KeyCode.ButtonX] = "overrideRootAndContainerEvent",
			[Enum.KeyCode.ButtonB] = "button",
		})
		local observer = {
			next = jest.fn(),
		}
		local subscription = focusNavigationService.activeEventMap:subscribe(observer)
		expect(observer.next).toHaveBeenCalledTimes(0)

		focusNavigationService:focusGuiObject(tree.leftButton, false)
		expect(observer.next).toHaveBeenCalledTimes(1)
		expect(observer.next).toHaveBeenLastCalledWith(expect.anything(), {
			[Enum.KeyCode.ButtonX] = "rootEvent",
		})

		focusNavigationService:focusGuiObject(tree.rightContainer, false)
		expect(observer.next).toHaveBeenCalledTimes(2)
		expect(observer.next).toHaveBeenLastCalledWith(expect.anything(), {
			[Enum.KeyCode.ButtonX] = "overrideRootEvent",
			[Enum.KeyCode.ButtonY] = "containerEvent",
		})

		focusNavigationService:focusGuiObject(tree.rightButton, false)
		expect(observer.next).toHaveBeenCalledTimes(3)
		expect(observer.next).toHaveBeenLastCalledWith(expect.anything(), {
			[Enum.KeyCode.ButtonX] = "overrideRootAndContainerEvent",
			[Enum.KeyCode.ButtonY] = "containerEvent",
			[Enum.KeyCode.ButtonB] = "button",
		})

		subscription:unsubscribe()
		focusNavigationService:focusGuiObject(tree.leftButton, false)
		expect(observer.next).toHaveBeenCalledTimes(3)
	end)

	it("should update active event map on registering/deregistering", function()
		local observer = {
			next = jest.fn(),
		}
		local subscription = focusNavigationService.activeEventMap:subscribe(observer)

		expect(observer.next).toHaveBeenCalledTimes(0)
		focusNavigationService:registerEventMap(tree.leftButton, {
			[Enum.KeyCode.ButtonX] = "foo",
		})

		focusNavigationService:focusGuiObject(tree.leftButton, false)
		expect(observer.next).toHaveBeenCalledTimes(1)
		expect(observer.next).toHaveBeenLastCalledWith(expect.anything(), {
			[Enum.KeyCode.ButtonX] = "foo",
		})

		focusNavigationService:registerEventMap(tree.leftButton, {
			[Enum.KeyCode.ButtonX] = "foo",
			[Enum.KeyCode.ButtonY] = "bar",
		})
		expect(observer.next).toHaveBeenCalledTimes(2)
		expect(observer.next).toHaveBeenLastCalledWith(expect.anything(), {
			[Enum.KeyCode.ButtonX] = "foo",
			[Enum.KeyCode.ButtonY] = "bar",
		})

		focusNavigationService:registerEventMap(tree.leftContainer, {
			[Enum.KeyCode.ButtonB] = "baz",
		})
		expect(observer.next).toHaveBeenCalledTimes(3)
		expect(observer.next).toHaveBeenLastCalledWith(expect.anything(), {
			[Enum.KeyCode.ButtonX] = "foo",
			[Enum.KeyCode.ButtonY] = "bar",
			[Enum.KeyCode.ButtonB] = "baz",
		})

		focusNavigationService:deregisterEventMap(tree.leftButton, {
			[Enum.KeyCode.ButtonY] = "bar",
		})
		expect(observer.next).toHaveBeenCalledTimes(4)
		expect(observer.next).toHaveBeenLastCalledWith(expect.anything(), {
			[Enum.KeyCode.ButtonX] = "foo",
			[Enum.KeyCode.ButtonB] = "baz",
		})

		subscription:unsubscribe()
		focusNavigationService:deregisterEventMap(tree.leftButton, {
			[Enum.KeyCode.ButtonX] = "foo",
		})
		expect(observer.next).toHaveBeenCalledTimes(4)
	end)
end)
