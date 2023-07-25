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
local waitForEvents = require(script.Parent.waitForEvents)

local FocusNavigationService = require(script.Parent.Parent.FocusNavigationService)
local EngineInterface = require(script.Parent.Parent.EngineInterface)

type EventPhase = EventPropagation.EventPhase
type EventHandler = FocusNavigationService.EventHandler

local types = require(script.Parent.Parent.types)

local CoreGui = game:GetService("CoreGui")
local PlayerGui = (game:GetService("Players").LocalPlayer :: any).PlayerGui

local beginAEvent = {
	KeyCode = Enum.KeyCode.A,
	UserInputType = Enum.UserInputType.Gamepad1,
	UserInputState = Enum.UserInputState.Begin,
}

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

describe("engine interface", function()
	local mountedTree, service
	afterEach(function()
		if mountedTree then
			mountedTree.root:Destroy()
			mountedTree = nil :: any
		end
		if service then
			service:teardown()
			service = nil :: any
		end
	end)

	local function getMountedGui(mountTarget)
		return createGuiObjectTree({
			root = { "ScreenGui", mountTarget },
			container = { "Frame", "root", { Size = UDim2.fromScale(0.5, 0.5) } },
			button = { "ImageButton", "container", { SelectionOrder = 1, Size = UDim2.fromScale(0.5, 0.5) } },
		})
	end

	it("should be able to focus the correct input property under CoreGui", function()
		mountedTree = getMountedGui(CoreGui)
		service = FocusNavigationService.new(EngineInterface.CoreGui)
		service:focusGuiObject(mountedTree.button, false)
		expect(GuiService.SelectedCoreObject).toEqual(mountedTree.button)
		expect(GuiService.SelectedObject).toBeNil()
	end)

	it("should be able to focus the correct input property under PlayerGui", function()
		mountedTree = getMountedGui(PlayerGui)
		service = FocusNavigationService.new(EngineInterface.PlayerGui)
		service:focusGuiObject(mountedTree.button, false)
		expect(GuiService.SelectedObject).toEqual(mountedTree.button)
		expect(GuiService.SelectedCoreObject).toBeNil()
	end)

	it("should be able to focus child of non-Selectable CoreGui descendant", function()
		mountedTree = getMountedGui(CoreGui)
		service = FocusNavigationService.new(EngineInterface.CoreGui)
		service:focusGuiObject(mountedTree.container, false)
		expect(GuiService.SelectedCoreObject).toEqual(mountedTree.button)
		expect(GuiService.SelectedObject).toBeNil()
	end)

	it("should be able to focus child of non-Selectable Player descendant", function()
		mountedTree = getMountedGui(PlayerGui)
		service = FocusNavigationService.new(EngineInterface.PlayerGui)
		service:focusGuiObject(mountedTree.container, false)
		expect(GuiService.SelectedObject).toEqual(mountedTree.button)
		expect(GuiService.SelectedCoreObject).toBeNil()
	end)
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
		-- cancellation event fires for deregistered handler
		expect(eventHandler).toHaveBeenCalledTimes(2)

		mockEngineInterface.simulateInput(beginAEvent)
		expect(eventHandler).toHaveBeenCalledTimes(2)
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
		-- cancellation event fires for deregistered handler
		expect(eventHandler).toHaveBeenCalledTimes(2)

		mockEngineInterface.simulateInput(beginAEvent)
		expect(eventHandler).toHaveBeenCalledTimes(2)
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

		it("should handle events that have already been processed by the engine", function()
			local handlerMap = getConfirmHandlerMap()

			focusNavigationService:registerEventHandlers(tree.leftButton, handlerMap)
			focusNavigationService:registerEventMap(tree.leftButton, {
				[Enum.KeyCode.ButtonA] = "confirm",
			})

			focusNavigationService:focusGuiObject(tree.leftButton, true)
			expect(handlerMap.confirm.handler).toHaveBeenCalledTimes(0)

			mockEngineInterface.simulateInput({
				KeyCode = Enum.KeyCode.ButtonA,
				UserInputType = Enum.UserInputType.Gamepad1,
				UserInputState = Enum.UserInputState.Begin,
			}, true)
			expect(handlerMap.confirm.handler).toHaveBeenCalledWith(expect.objectContaining({
				targetInstance = tree.leftButton,
				eventData = expect.objectContaining({
					wasProcessed = true,
				}),
			}))
		end)

		it("should capture events through parents", function()
			local handlerMap = getConfirmHandlerMap("Capture")

			focusNavigationService:registerEventHandlers(tree.root, handlerMap)
			focusNavigationService:registerEventHandlers(tree.leftButton, handlerMap)
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

		describe("handler cancellation", function()
			local handlerMap
			beforeEach(function()
				handlerMap = getConfirmHandlerMap("Target")
				focusNavigationService:registerEventHandlers(tree.leftButton, handlerMap)
				focusNavigationService:registerEventMap(tree.root, {
					[Enum.KeyCode.A] = "confirm",
				})
			end)

			it("should cancel bound input events when moving focus", function()
				focusNavigationService:focusGuiObject(tree.leftButton, true)
				expect(handlerMap.confirm.handler).toHaveBeenCalledTimes(0)

				mockEngineInterface.simulateInput(beginAEvent)
				expect(handlerMap.confirm.handler).toHaveBeenCalledTimes(1)

				focusNavigationService:focusGuiObject(tree.rightButton, true)
				expect(handlerMap.confirm.handler).toHaveBeenCalledTimes(2)
				expect(handlerMap.confirm.handler).toHaveBeenLastCalledWith(expect.objectContaining({
					currentInstance = tree.leftButton,
					targetInstance = tree.leftButton,
					eventData = {
						KeyCode = Enum.KeyCode.Unknown,
						UserInputType = Enum.UserInputType.None,
						UserInputState = Enum.UserInputState.Cancel,
					},
				}))
			end)

			it("should cancel bound input events when deregistering event handlers", function()
				focusNavigationService:focusGuiObject(tree.leftButton, true)
				expect(handlerMap.confirm.handler).toHaveBeenCalledTimes(0)

				mockEngineInterface.simulateInput(beginAEvent)
				expect(handlerMap.confirm.handler).toHaveBeenCalledTimes(1)

				focusNavigationService:deregisterEventHandler(
					tree.leftButton,
					"confirm",
					handlerMap.confirm.handler,
					handlerMap.confirm.phase
				)
				expect(handlerMap.confirm.handler).toHaveBeenCalledTimes(2)
				expect(handlerMap.confirm.handler).toHaveBeenLastCalledWith(expect.objectContaining({
					currentInstance = tree.leftButton,
					targetInstance = tree.leftButton,
					eventName = "confirm",
					eventData = {
						KeyCode = Enum.KeyCode.Unknown,
						UserInputType = Enum.UserInputType.None,
						UserInputState = Enum.UserInputState.Cancel,
					},
				}))
			end)

			it("should cancel bound input events when deregistering event handler maps", function()
				focusNavigationService:focusGuiObject(tree.leftButton, true)
				expect(handlerMap.confirm.handler).toHaveBeenCalledTimes(0)

				mockEngineInterface.simulateInput(beginAEvent)
				expect(handlerMap.confirm.handler).toHaveBeenCalledTimes(1)

				focusNavigationService:deregisterEventHandlers(tree.leftButton, handlerMap)
				expect(handlerMap.confirm.handler).toHaveBeenCalledTimes(2)
				expect(handlerMap.confirm.handler).toHaveBeenLastCalledWith(expect.objectContaining({
					currentInstance = tree.leftButton,
					targetInstance = tree.leftButton,
					eventData = {
						KeyCode = Enum.KeyCode.Unknown,
						UserInputType = Enum.UserInputType.None,
						UserInputState = Enum.UserInputState.Cancel,
					},
				}))
			end)

			it("should cancel bound input events when deregistering event maps", function()
				focusNavigationService:focusGuiObject(tree.leftButton, true)
				expect(handlerMap.confirm.handler).toHaveBeenCalledTimes(0)

				mockEngineInterface.simulateInput(beginAEvent)
				expect(handlerMap.confirm.handler).toHaveBeenCalledTimes(1)

				focusNavigationService:deregisterEventMap(tree.root, {
					[Enum.KeyCode.A] = "confirm",
				})
				expect(handlerMap.confirm.handler).toHaveBeenCalledTimes(2)
				expect(handlerMap.confirm.handler).toHaveBeenLastCalledWith(expect.objectContaining({
					currentInstance = tree.leftButton,
					targetInstance = tree.leftButton,
					eventData = {
						KeyCode = Enum.KeyCode.Unknown,
						UserInputType = Enum.UserInputType.None,
						UserInputState = Enum.UserInputState.Cancel,
					},
				}))
			end)

			it("should not cancel focus and blur events", function()
				local focusHandler = jest.fn()
				local blurHandler = jest.fn()
				focusNavigationService:registerEventHandler(tree.leftButton, "focus", focusHandler)
				focusNavigationService:registerEventHandler(tree.leftButton, "blur", blurHandler)

				focusNavigationService:focusGuiObject(tree.leftButton, true)
				expect(focusHandler).toHaveBeenCalledTimes(1)
				expect(blurHandler).toHaveBeenCalledTimes(0)

				focusNavigationService:focusGuiObject(nil, true)
				expect(focusHandler).toHaveBeenCalledTimes(1)
				expect(blurHandler).toHaveBeenCalledTimes(1)

				focusNavigationService:deregisterEventHandler(tree.leftButton, "focus", focusHandler)
				focusNavigationService:deregisterEventHandler(tree.leftButton, "blur", blurHandler)

				-- blur and focus events don't handle user input, so they don't
				-- receive "cancel" events
				expect(focusHandler).toHaveBeenCalledTimes(1)
				expect(blurHandler).toHaveBeenCalledTimes(1)
			end)
		end)
	end)
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

	local function getGuiMountedTo(mountTarget)
		return createGuiObjectTree({
			root = { "ScreenGui", mountTarget },
			leftButton = { "ImageButton", "root", { Size = UDim2.fromScale(0.5, 0.5) } },
			rightButton = { "ImageButton", "root", { Size = UDim2.fromScale(0.5, 0.5) } },
		})
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
		local mountedTree = getGuiMountedTo(CoreGui)
		local service = FocusNavigationService.new(EngineInterface.CoreGui)
		service:focusGuiObject(mountedTree.leftButton, false)
		waitForEvents()

		local handlerMap = getHandlerMap(phaseConfig.phase)
		service:registerEventHandlers(mountedTree.leftButton, handlerMap)
		service:registerEventHandlers(mountedTree.rightButton, handlerMap)

		GuiService.SelectedCoreObject = mountedTree.rightButton
		waitForEvents()

		expect(handlerMap.blur.handler).toHaveBeenCalledTimes(1)
		expect(handlerMap.focus.handler).toHaveBeenCalledTimes(1)

		-- move non-core focus
		GuiService.SelectedObject = mountedTree.leftButton
		waitForEvents()

		-- No new callbacks should have happened
		expect(handlerMap.blur.handler).toHaveBeenCalledTimes(1)
		expect(handlerMap.focus.handler).toHaveBeenCalledTimes(1)
	end)

	it("should only send events for the SelectedObject under PlayerGui", function()
		local mountedTree = getGuiMountedTo(PlayerGui)
		local service = FocusNavigationService.new(EngineInterface.PlayerGui)
		service:focusGuiObject(mountedTree.leftButton, false)
		waitForEvents()

		local handlerMap = getHandlerMap(phaseConfig.phase)
		service:registerEventHandlers(mountedTree.leftButton, handlerMap)
		service:registerEventHandlers(mountedTree.rightButton, handlerMap)

		GuiService.SelectedObject = mountedTree.rightButton
		waitForEvents()

		expect(handlerMap.blur.handler).toHaveBeenCalledTimes(1)
		expect(handlerMap.focus.handler).toHaveBeenCalledTimes(1)

		-- move core focus
		GuiService.SelectedCoreObject = mountedTree.leftContainer
		waitForEvents()

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

describe("container focus behaviors", function()
	local tree
	beforeEach(function()
		-- This functionality only works with real engine behavior, so override
		-- the mocked service
		focusNavigationService = FocusNavigationService.new(EngineInterface.PlayerGui)

		tree = createGuiObjectTree({
			root = { "ScreenGui", PlayerGui },
			outerButton1 = { "TextButton", "root", { Size = UDim2.new(0.5, 0, 0, 100) } },
			outerButton2 = {
				"TextButton",
				"root",
				{ Size = UDim2.new(0.5, 0, 0, 100), Position = UDim2.fromScale(0.5, 0) },
			},
			container = { "Frame", "root", { Size = UDim2.fromScale(0.5, 0.5), Position = UDim2.fromOffset(0, 100) } },
			innerButton1 = { "ImageButton", "container", { SelectionOrder = 1, Size = UDim2.fromScale(0.5, 0.5) } },
			innerButton2 = {
				"ImageButton",
				"container",
				{ SelectionOrder = 2, Size = UDim2.fromScale(0.5, 0.5), Position = UDim2.fromScale(0.5, 0) },
			},
		})
	end)
	afterEach(function()
		tree.root:Destroy()
	end)

	local redirectTo2: types.ContainerFocusBehavior = {
		getTarget = function()
			return tree.innerButton2
		end,
	}

	local function behaviorWithFocusChanged(fn): types.ContainerFocusBehavior
		return {
			onDescendantFocusChanged = fn,
			getTarget = function()
				return nil
			end,
		}
	end

	it("should allow registering and deregistering of focus behaviors", function()
		local spy, spyFn = jest.fn()
		local behavior = { getTarget = spyFn }

		GuiService.SelectedObject = nil
		focusNavigationService:registerFocusBehavior(tree.container, behavior)

		GuiService.SelectedObject = tree.innerButton1
		waitForEvents()
		expect(spy).toHaveBeenCalledTimes(1)

		GuiService.SelectedObject = nil
		focusNavigationService:deregisterFocusBehavior(tree.container, behavior)

		GuiService.SelectedObject = tree.innerButton1
		waitForEvents()
		expect(spy).toHaveBeenCalledTimes(1)
	end)

	it("should clean up focus behaviors on teardown", function()
		local spy, spyFn = jest.fn()
		local behavior = { getTarget = spyFn }

		GuiService.SelectedObject = nil
		focusNavigationService:registerFocusBehavior(tree.container, behavior)

		GuiService.SelectedObject = tree.innerButton1
		waitForEvents()
		expect(spy).toHaveBeenCalledTimes(1)

		GuiService.SelectedObject = nil
		focusNavigationService:teardown()

		GuiService.SelectedObject = tree.innerButton1
		waitForEvents()
		expect(spy).toHaveBeenCalledTimes(1)
	end)

	describe("should redirect focus", function()
		it("when focus is gained from outside container", function()
			GuiService.SelectedObject = tree.outerButton1

			focusNavigationService:registerFocusBehavior(tree.container, redirectTo2)

			GuiService.SelectedObject = tree.innerButton1
			waitForEvents()
			expect(GuiService.SelectedObject).toBe(tree.innerButton2)
		end)

		it("when focus is captured from nil", function()
			GuiService.SelectedObject = nil

			focusNavigationService:registerFocusBehavior(tree.container, redirectTo2)

			GuiService.SelectedObject = tree.innerButton1
			waitForEvents()
			expect(GuiService.SelectedObject).toBe(tree.innerButton2)
		end)
	end)

	describe("should not redirect focus", function()
		it("when focus moves within the container", function()
			focusNavigationService:registerFocusBehavior(tree.container, redirectTo2)

			GuiService.SelectedObject = tree.innerButton2
			waitForEvents()
			expect(GuiService.SelectedObject).toBe(tree.innerButton2)

			GuiService.SelectedObject = tree.innerButton1
			waitForEvents()
			expect(GuiService.SelectedObject).toBe(tree.innerButton1)
		end)

		it("when focus moves out of the container", function()
			focusNavigationService:registerFocusBehavior(tree.container, redirectTo2)

			GuiService.SelectedObject = tree.innerButton2
			waitForEvents()
			expect(GuiService.SelectedObject).toBe(tree.innerButton2)

			GuiService.SelectedObject = tree.outerButton1
			waitForEvents()
			expect(GuiService.SelectedObject).toBe(tree.outerButton1)
		end)

		it("when focus moves between elements oustide of the container", function()
			focusNavigationService:registerFocusBehavior(tree.container, redirectTo2)

			GuiService.SelectedObject = tree.outerButton1
			waitForEvents()
			expect(GuiService.SelectedObject).toBe(tree.outerButton1)

			GuiService.SelectedObject = tree.outerButton2
			waitForEvents()
			expect(GuiService.SelectedObject).toBe(tree.outerButton2)
		end)
	end)

	describe("should trigger onDescendantFocusChanged", function()
		it("when focus is gained from outside container", function()
			local spy, spyFn = jest.fn()
			local behavior = behaviorWithFocusChanged(spyFn)

			GuiService.SelectedObject = tree.outerButton1
			focusNavigationService:registerFocusBehavior(tree.container, behavior)

			GuiService.SelectedObject = tree.innerButton1
			waitForEvents()
			expect(spy).toHaveBeenCalledTimes(1)
			expect(spy).toHaveBeenCalledWith(tree.innerButton1)
		end)

		it("when focus is captured from nil", function()
			local spy, spyFn = jest.fn()
			local behavior = behaviorWithFocusChanged(spyFn)

			GuiService.SelectedObject = nil
			focusNavigationService:registerFocusBehavior(tree.container, behavior)

			GuiService.SelectedObject = tree.innerButton1
			waitForEvents()
			expect(spy).toHaveBeenCalledTimes(1)
			expect(spy).toHaveBeenCalledWith(tree.innerButton1)
		end)

		it("when focus between elements inside of the container", function()
			local spy, spyFn = jest.fn()
			local behavior = behaviorWithFocusChanged(spyFn)

			GuiService.SelectedObject = tree.innerButton1
			focusNavigationService:registerFocusBehavior(tree.container, behavior)

			GuiService.SelectedObject = tree.innerButton2
			waitForEvents()
			expect(spy).toHaveBeenCalledTimes(1)
			expect(spy).toHaveBeenCalledWith(tree.innerButton2)
		end)

		it("with the new value when focus is redirected", function()
			local spy, spyFn = jest.fn()
			local behavior = behaviorWithFocusChanged(spyFn)
			behavior.getTarget = function()
				return tree.innerButton2
			end

			GuiService.SelectedObject = nil
			focusNavigationService:registerFocusBehavior(tree.container, behavior)

			GuiService.SelectedObject = tree.innerButton1
			-- wait for initial focus
			waitForEvents()
			-- wait for redirect to be observed
			waitForEvents()
			expect(spy).toHaveBeenCalledTimes(1)
			expect(spy).toHaveBeenCalledWith(tree.innerButton2)
		end)
	end)

	describe("should not trigger onDescendantFocusChanged", function()
		it("when focus moves outside the container", function()
			local spy, spyFn = jest.fn()
			local behavior = behaviorWithFocusChanged(spyFn)

			GuiService.SelectedObject = tree.innerButton1
			focusNavigationService:registerFocusBehavior(tree.container, behavior)

			GuiService.SelectedObject = tree.outerButton1
			-- wait for initial focus
			waitForEvents()
			-- wait in case there was an erroneous redirect
			waitForEvents()
			expect(spy).toHaveBeenCalledTimes(0)
		end)

		it("with a focus target that was redirected away from", function()
			local spy, spyFn = jest.fn()
			local behavior = behaviorWithFocusChanged(spyFn)
			behavior.getTarget = function()
				return tree.innerButton2
			end

			GuiService.SelectedObject = nil
			focusNavigationService:registerFocusBehavior(tree.container, behavior)

			GuiService.SelectedObject = tree.innerButton1
			-- wait for initial focus
			waitForEvents()
			-- wait for redirect to be observed
			waitForEvents()
			expect(spy).toHaveBeenCalledTimes(1)
			expect(spy).never.toHaveBeenCalledWith(tree.innerButton1)
		end)

		it("when focus is set to nil", function()
			local spy, spyFn = jest.fn()
			local behavior = behaviorWithFocusChanged(spyFn)

			GuiService.SelectedObject = tree.innerButton1
			focusNavigationService:registerFocusBehavior(tree.container, behavior)

			GuiService.SelectedObject = nil
			-- wait for initial focus
			waitForEvents()
			-- wait in case there was an erroneous redirect
			waitForEvents()
			expect(spy).toHaveBeenCalledTimes(0)
		end)
	end)
end)

describe("observable properties", function()
	type NoopHandler = { handler: (any) -> (), phase: nil }

	local function noop(_: any)
		-- used to register handlers for active event tracking
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

	it("should expose a signal for currently-focused GuiObject", function()
		focusNavigationService:focusGuiObject(tree.leftButton, false)

		local onChange, onChangeFn = jest.fn()
		local subscription = focusNavigationService.focusedGuiObject:subscribe(onChangeFn)

		expect(onChange).toHaveBeenCalledTimes(0)

		focusNavigationService:focusGuiObject(tree.rightButton, false)

		expect(onChange).toHaveBeenCalledTimes(1)
		expect(onChange).toHaveBeenLastCalledWith(tree.rightButton)

		focusNavigationService:focusGuiObject(tree.leftButton, false)
		expect(onChange).toHaveBeenCalledTimes(2)
		expect(onChange).toHaveBeenLastCalledWith(tree.leftButton)

		subscription:unsubscribe()
		focusNavigationService:focusGuiObject(tree.rightButton, false)
		expect(onChange).toHaveBeenCalledTimes(2)
	end)

	it("should allow multiple subscribers to currently-focused object", function()
		focusNavigationService:focusGuiObject(tree.leftButton, false)

		local onChange1, onChange1Fn = jest.fn()
		local onChange2, onChange2Fn = jest.fn()
		local subscription1 = focusNavigationService.focusedGuiObject:subscribe(onChange1Fn)
		local subscription2 = focusNavigationService.focusedGuiObject:subscribe(onChange2Fn)

		expect(onChange1).toHaveBeenCalledTimes(0)
		expect(onChange2).toHaveBeenCalledTimes(0)

		focusNavigationService:focusGuiObject(tree.rightButton, false)

		expect(onChange1).toHaveBeenCalledTimes(1)
		expect(onChange2).toHaveBeenCalledTimes(1)

		subscription1:unsubscribe()
		focusNavigationService:focusGuiObject(tree.leftButton, false)
		expect(onChange1).toHaveBeenCalledTimes(1)
		expect(onChange2).toHaveBeenCalledTimes(2)

		local onChange3, onChange3Fn = jest.fn()
		local subscription3 = focusNavigationService.focusedGuiObject:subscribe(onChange3Fn)

		focusNavigationService:focusGuiObject(tree.rightButton, false)
		expect(onChange1).toHaveBeenCalledTimes(1)
		expect(onChange2).toHaveBeenCalledTimes(3)
		expect(onChange3).toHaveBeenCalledTimes(1)

		subscription2:unsubscribe()
		subscription3:unsubscribe()

		focusNavigationService:focusGuiObject(tree.leftButton, false)
		expect(onChange1).toHaveBeenCalledTimes(1)
		expect(onChange2).toHaveBeenCalledTimes(3)
		expect(onChange3).toHaveBeenCalledTimes(1)
	end)

	it("should expose an observable for currently-active event map", function()
		local onChange, onChangeFn = jest.fn()
		local subscription = focusNavigationService.activeEventMap:subscribe(onChangeFn)

		expect(onChange).toHaveBeenCalledTimes(0)
		focusNavigationService:registerEventMap(tree.leftButton, {
			[Enum.KeyCode.ButtonX] = "foo",
			[Enum.KeyCode.ButtonY] = "bar",
		})
		focusNavigationService:registerEventHandlers(tree.leftButton, {
			foo = { handler = noop },
			bar = { handler = noop },
		})

		focusNavigationService:focusGuiObject(tree.leftButton, false)
		expect(onChange).toHaveBeenCalledTimes(1)
		expect(onChange).toHaveBeenLastCalledWith({
			[Enum.KeyCode.ButtonX] = "foo",
			[Enum.KeyCode.ButtonY] = "bar",
		})

		focusNavigationService:focusGuiObject(tree.rightButton, false)
		expect(onChange).toHaveBeenCalledTimes(2)
		expect(onChange).toHaveBeenLastCalledWith({})

		subscription:unsubscribe()
		focusNavigationService:focusGuiObject(tree.leftButton, false)
		expect(onChange).toHaveBeenCalledTimes(2)
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
		-- register all events on each button, so we're only dealing with the
		-- changes in the EventMap
		local handlers: { [string]: NoopHandler } = {
			rootEvent = { handler = noop },
			overrideRootEvent = { handler = noop },
			containerEvent = { handler = noop },
			overrideRootAndContainerEvent = { handler = noop },
			button = { handler = noop },
		}
		-- register all events on all instances so that we're only dealing with
		-- the changes in the EventMap
		focusNavigationService:registerEventHandlers(tree.root, handlers)
		focusNavigationService:registerEventHandlers(tree.leftContainer, handlers)
		focusNavigationService:registerEventHandlers(tree.rightContainer, handlers)
		focusNavigationService:registerEventHandlers(tree.leftButton, handlers)
		focusNavigationService:registerEventHandlers(tree.rightButton, handlers)
		local onChange, onChangeFn = jest.fn()
		local subscription = focusNavigationService.activeEventMap:subscribe(onChangeFn)
		expect(onChange).toHaveBeenCalledTimes(0)

		focusNavigationService:focusGuiObject(tree.leftButton, false)
		expect(onChange).toHaveBeenCalledTimes(1)
		expect(onChange).toHaveBeenLastCalledWith({
			[Enum.KeyCode.ButtonX] = "rootEvent",
		})

		focusNavigationService:focusGuiObject(tree.rightContainer, false)
		expect(onChange).toHaveBeenCalledTimes(2)
		expect(onChange).toHaveBeenLastCalledWith({
			[Enum.KeyCode.ButtonX] = "overrideRootEvent",
			[Enum.KeyCode.ButtonY] = "containerEvent",
		})

		focusNavigationService:focusGuiObject(tree.rightButton, false)
		expect(onChange).toHaveBeenCalledTimes(3)
		expect(onChange).toHaveBeenLastCalledWith({
			[Enum.KeyCode.ButtonX] = "overrideRootAndContainerEvent",
			[Enum.KeyCode.ButtonY] = "containerEvent",
			[Enum.KeyCode.ButtonB] = "button",
		})

		subscription:unsubscribe()
		focusNavigationService:focusGuiObject(tree.leftButton, false)
		expect(onChange).toHaveBeenCalledTimes(3)
	end)

	it("should update active event map on registering/deregistering", function()
		local onChange, onChangeFn = jest.fn()
		local subscription = focusNavigationService.activeEventMap:subscribe(onChangeFn)

		expect(onChange).toHaveBeenCalledTimes(0)
		focusNavigationService:registerEventMap(tree.leftButton, {
			[Enum.KeyCode.ButtonX] = "foo",
		})
		focusNavigationService:registerEventHandlers(tree.leftButton, {
			foo = { handler = noop },
			bar = { handler = noop },
			baz = { handler = noop },
		})

		focusNavigationService:focusGuiObject(tree.leftButton, false)
		expect(onChange).toHaveBeenCalledTimes(1)
		expect(onChange).toHaveBeenLastCalledWith({
			[Enum.KeyCode.ButtonX] = "foo",
		})

		focusNavigationService:registerEventMap(tree.leftButton, {
			[Enum.KeyCode.ButtonX] = "foo",
			[Enum.KeyCode.ButtonY] = "bar",
		})
		expect(onChange).toHaveBeenCalledTimes(2)
		expect(onChange).toHaveBeenLastCalledWith({
			[Enum.KeyCode.ButtonX] = "foo",
			[Enum.KeyCode.ButtonY] = "bar",
		})

		focusNavigationService:registerEventMap(tree.leftContainer, {
			[Enum.KeyCode.ButtonB] = "baz",
		})
		expect(onChange).toHaveBeenCalledTimes(3)
		expect(onChange).toHaveBeenLastCalledWith({
			[Enum.KeyCode.ButtonX] = "foo",
			[Enum.KeyCode.ButtonY] = "bar",
			[Enum.KeyCode.ButtonB] = "baz",
		})

		focusNavigationService:deregisterEventMap(tree.leftButton, {
			[Enum.KeyCode.ButtonY] = "bar",
		})
		expect(onChange).toHaveBeenCalledTimes(4)
		expect(onChange).toHaveBeenLastCalledWith({
			[Enum.KeyCode.ButtonX] = "foo",
			[Enum.KeyCode.ButtonB] = "baz",
		})

		subscription:unsubscribe()
		focusNavigationService:deregisterEventMap(tree.leftButton, {
			[Enum.KeyCode.ButtonX] = "foo",
		})
		expect(onChange).toHaveBeenCalledTimes(4)
	end)

	it("should update activeEventMap when switching back to empty after a subscription was added", function()
		local onChange, onChangeFn = jest.fn()

		local eventMap = { [Enum.KeyCode.ButtonX] = "foo" }
		focusNavigationService:registerEventMap(tree.leftButton, eventMap)
		focusNavigationService:registerEventHandler(tree.leftButton, "foo", noop)
		focusNavigationService:focusGuiObject(tree.leftButton, false)
		-- not subscribed yet
		expect(onChange).toHaveBeenCalledTimes(0)

		local subscription = focusNavigationService.activeEventMap:subscribe(onChangeFn)
		focusNavigationService:deregisterEventMap(tree.leftButton, eventMap)

		expect(onChange).toHaveBeenCalledTimes(1)
		expect(onChange).toHaveBeenCalledWith({})

		subscription:unsubscribe()
		focusNavigationService:registerEventMap(tree.leftButton, eventMap)
		expect(onChange).toHaveBeenCalledTimes(1)
	end)

	describe("active event filtering", function()
		it("should update when handlers are registered and deregistered", function()
			local eventMap = {
				[Enum.KeyCode.ButtonX] = "foo",
				[Enum.KeyCode.ButtonY] = "bar",
			}
			focusNavigationService:registerEventMap(tree.root, eventMap)
			focusNavigationService:focusGuiObject(tree.leftButton, false)

			local activeEventMap = focusNavigationService.activeEventMap
			expect(activeEventMap:getValue()).toEqual({})

			focusNavigationService:registerEventHandler(tree.root, "foo", noop)
			expect(activeEventMap:getValue()).toEqual({ [Enum.KeyCode.ButtonX] = "foo" })
			focusNavigationService:registerEventHandler(tree.leftButton, "bar", noop)
			expect(activeEventMap:getValue()).toEqual(eventMap)

			focusNavigationService:deregisterEventHandler(tree.root, "foo", noop)
			expect(activeEventMap:getValue()).toEqual({ [Enum.KeyCode.ButtonY] = "bar" })
			focusNavigationService:deregisterEventHandler(tree.leftButton, "bar", noop)
			expect(activeEventMap:getValue()).toEqual({})
		end)

		it("should update when mappings are registered and deregistered", function()
			focusNavigationService:registerEventHandlers(tree.leftButton, {
				foo = { handler = noop },
				bar = { handler = noop },
			})
			focusNavigationService:focusGuiObject(tree.leftButton, false)

			local activeEventMap = focusNavigationService.activeEventMap
			expect(activeEventMap:getValue()).toEqual({})

			focusNavigationService:registerEventMap(tree.root, { [Enum.KeyCode.ButtonA] = "foo" })
			expect(activeEventMap:getValue()).toEqual({ [Enum.KeyCode.ButtonA] = "foo" })
			focusNavigationService:registerEventMap(tree.leftButton, { [Enum.KeyCode.ButtonB] = "bar" })
			expect(activeEventMap:getValue()).toEqual({
				[Enum.KeyCode.ButtonA] = "foo",
				[Enum.KeyCode.ButtonB] = "bar",
			})

			focusNavigationService:deregisterEventMap(tree.root, { [Enum.KeyCode.ButtonA] = "foo" })
			expect(activeEventMap:getValue()).toEqual({ [Enum.KeyCode.ButtonB] = "bar" })
			focusNavigationService:deregisterEventMap(tree.leftButton, { [Enum.KeyCode.ButtonB] = "bar" })
			expect(activeEventMap:getValue()).toEqual({})
		end)

		it("should update when moving focus", function()
			focusNavigationService:registerEventMap(tree.leftContainer, { [Enum.KeyCode.ButtonX] = "foo" })
			focusNavigationService:registerEventHandler(tree.leftButton, "bar", noop)
			focusNavigationService:registerEventMap(tree.rightContainer, { [Enum.KeyCode.ButtonY] = "baz" })
			focusNavigationService:registerEventHandler(tree.rightButton, "baz", noop)

			focusNavigationService:focusGuiObject(tree.root, false)

			local activeEventMap = focusNavigationService.activeEventMap
			expect(activeEventMap:getValue()).toEqual({})

			-- no events mapped or registered on root
			focusNavigationService:focusGuiObject(tree.root, false)
			expect(activeEventMap:getValue()).toEqual({})

			-- "foo" is mapped but not registered
			focusNavigationService:focusGuiObject(tree.leftContainer, false)
			expect(activeEventMap:getValue()).toEqual({})

			-- "bar" is registered but not mapped
			focusNavigationService:focusGuiObject(tree.leftButton, false)
			expect(activeEventMap:getValue()).toEqual({})

			-- "baz" is both mapped and registered
			focusNavigationService:focusGuiObject(tree.rightButton, false)
			expect(activeEventMap:getValue()).toEqual({ [Enum.KeyCode.ButtonY] = "baz" })
		end)

		it("should reflect events that have been overridden", function()
			focusNavigationService:registerEventMap(tree.root, { [Enum.KeyCode.ButtonX] = "foo" })
			focusNavigationService:registerEventHandler(tree.leftContainer, "foo", noop)
			focusNavigationService:registerEventMap(tree.leftButton, { [Enum.KeyCode.ButtonX] = "fooOverride" })

			focusNavigationService:focusGuiObject(tree.root, false)

			local activeEventMap = focusNavigationService.activeEventMap
			expect(activeEventMap:getValue()).toEqual({})

			focusNavigationService:focusGuiObject(tree.leftContainer, false)
			expect(activeEventMap:getValue()).toEqual({ [Enum.KeyCode.ButtonX] = "foo" })

			-- map overrides bound event to unbound event
			focusNavigationService:focusGuiObject(tree.leftButton, false)
			expect(activeEventMap:getValue()).toEqual({})

			-- register a handler for the overridden event and it becomes active
			focusNavigationService:registerEventHandler(tree.leftButton, "fooOverride", noop)
			expect(activeEventMap:getValue()).toEqual({ [Enum.KeyCode.ButtonX] = "fooOverride" })
		end)
	end)
end)

describe("improper usage warnings", function()
	it("warns on registering over existing event", function()
		local instance = Instance.new("Frame")

		focusNavigationService:registerEventMap(instance, {
			[Enum.KeyCode.ButtonA] = "Foo",
		})
		expect(function()
			focusNavigationService:registerEventMap(instance, {
				[Enum.KeyCode.ButtonA] = "Bar",
			})
		end).toWarnDev({
			"New event will replace existing registered event mapped to Enum%.KeyCode%.ButtonA:\n.*Bar\n.*Foo",
		})
	end)

	it("warns on deregistering non-registered event", function()
		local instance = Instance.new("Frame")

		focusNavigationService:registerEventMap(instance, {
			[Enum.KeyCode.ButtonB] = "Foo",
		})
		expect(function()
			focusNavigationService:deregisterEventMap(instance, {
				[Enum.KeyCode.ButtonB] = "Bar",
			})
		end).toWarnDev({
			"Cannot deregister non%-matching event input Enum%.KeyCode%.ButtonB:.*Bar.*Foo",
		})
	end)

	describe("Focus Behavior", function()
		local behaviorA = (
			setmetatable({
				onDescendantFocusChanged = nil,
				getTarget = function()
					return nil
				end,
			}, {
				__tostring = function()
					return "BehaviorA"
				end,
			}) :: any
		) :: types.ContainerFocusBehavior
		local behaviorB = (
			setmetatable({
				onDescendantFocusChanged = nil,
				getTarget = function()
					return nil
				end,
			}, {
				__tostring = function()
					return "BehaviorB"
				end,
			}) :: any
		) :: types.ContainerFocusBehavior

		it("warns on overwriting a registered focus behavior", function()
			local instance = Instance.new("Frame")

			focusNavigationService:registerFocusBehavior(instance, behaviorA)

			expect(function()
				focusNavigationService:registerFocusBehavior(instance, behaviorB)
			end).toWarnDev({
				"New focus behavior will replace existing registered focus behavior:.*BehaviorB.*BehaviorA",
			})
		end)

		it("warns on deregistering an un registered focus behavior", function()
			local instance = Instance.new("Frame")

			expect(function()
				focusNavigationService:deregisterFocusBehavior(instance, behaviorA)
			end).toWarnDev({
				"Cannot deregister an unregistered focus behavior:.*BehaviorA",
			})
		end)

		it("warns on deregistering a focus behavior that does not match the registered one", function()
			local instance = Instance.new("Frame")

			focusNavigationService:registerFocusBehavior(instance, behaviorA)

			expect(function()
				focusNavigationService:deregisterFocusBehavior(instance, behaviorB)
			end).toWarnDev({
				"Cannot deregister non%-matching focus behavior:.*BehaviorB.*BehaviorA",
			})
		end)
	end)
end)
