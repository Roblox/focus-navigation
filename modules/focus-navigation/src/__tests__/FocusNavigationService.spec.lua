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

local MockUserInputService = require(script.Parent.MockUserInputService)
local createGuiObjectTree = require(script.Parent.createGuiObjectTree)
local FocusNavigationService = require(script.Parent.Parent.FocusNavigationService)

type EventPhase = EventPropagation.EventPhase
type EventHandler = FocusNavigationService.EventHandler

local CoreGui = game:GetService("CoreGui")

local beginAEvent = {
	KeyCode = Enum.KeyCode.A,
	UserInputType = Enum.UserInputType.Gamepad1,
	UserInputState = Enum.UserInputState.Begin,
}

-- FIXME Luau: types don't play nicely with callable tables
type FIXME_ANALYZE = any
local describeEach = describe.each :: FIXME_ANALYZE

local coreUiModes = { { useCoreUi = false }, { useCoreUi = true } }
describeEach(coreUiModes)("FocusNavigationService (useCoreUi == $useCoreUi)", function(config: { useCoreUi: boolean })
	local mountTarget = if config.useCoreUi then CoreGui else (game:GetService("Players").LocalPlayer :: any).PlayerGui
	local mockUserInputService, focusNavigationService
	beforeEach(function()
		mockUserInputService = MockUserInputService.new()
		focusNavigationService = FocusNavigationService.new(config.useCoreUi, mockUserInputService :: any, GuiService)
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
				root = { "ScreenGui", mountTarget },
				leftButton = { "ImageButton", "root", { Size = UDim2.fromScale(0.5, 0.5) } },
				rightButton = { "ImageButton", "root", { Size = UDim2.fromScale(0.5, 0.5) } },
			})
		end)
		afterEach(function()
			tree.root:Destroy()
		end)

		it("should connect to input events and GuiService.", function()
			local disconnectPropertyChangedSignal = jest.fn()
			local guiServicePropertyChangeSignal = jest.fn(function()
				return { Disconnect = disconnectPropertyChangedSignal }
			end)

			local mockGuiService = {
				GetPropertyChangedSignal = function(_, property)
					expect(property).toBe("SelectedObject")
					return {
						Connect = guiServicePropertyChangeSignal,
					}
				end,
			}
			local mockInputService = MockUserInputService.new()
			local service = FocusNavigationService.new(false, mockInputService :: any, mockGuiService :: any)
			expect(mockInputService.InputBegan.Connect).toHaveBeenCalledTimes(1)
			expect(mockInputService.InputChanged.Connect).toHaveBeenCalledTimes(1)
			expect(mockInputService.InputEnded.Connect).toHaveBeenCalledTimes(1)
			expect(guiServicePropertyChangeSignal).toHaveBeenCalledTimes(1)

			service:teardown()
			expect(mockInputService.mock.InputBeganDisconnected).toHaveBeenCalledTimes(1)
			expect(mockInputService.mock.InputChangedDisconnected).toHaveBeenCalledTimes(1)
			expect(mockInputService.mock.InputEndedDisconnected).toHaveBeenCalledTimes(1)
			expect(disconnectPropertyChangedSignal).toHaveBeenCalledTimes(1)
		end)

		it("should be able to focus the correct input property", function()
			focusNavigationService:focusGuiObject(tree.leftButton, false)
			if config.useCoreUi then
				expect(GuiService.SelectedCoreObject).toEqual(tree.leftButton)
				expect(GuiService.SelectedObject).toBeNil()
			else
				expect(GuiService.SelectedObject).toEqual(tree.leftButton)
				expect(GuiService.SelectedCoreObject).toBeNil()
			end
		end)

		it("should allow input events to be registered on instances", function()
			focusNavigationService:registerEventMap(tree.leftButton, {
				[Enum.KeyCode.A] = "confirm",
			})
			local eventHandler = jest.fn()
			focusNavigationService:registerEventHandler(tree.leftButton, "confirm", eventHandler, "Target")

			focusNavigationService:focusGuiObject(tree.rightButton, true)
			mockUserInputService:simulateInput(beginAEvent)

			expect(eventHandler).toHaveBeenCalledTimes(0)

			focusNavigationService:focusGuiObject(tree.leftButton, true)
			mockUserInputService:simulateInput(beginAEvent)

			expect(eventHandler).toHaveBeenCalledTimes(1)
			expect(eventHandler).toHaveBeenCalledWith(expect.objectContaining({
				eventData = beginAEvent,
			}))

			focusNavigationService:deregisterEventHandler(tree.leftButton, "confirm", eventHandler, "Target")
			mockUserInputService:simulateInput(beginAEvent)
			expect(eventHandler).toHaveBeenCalledTimes(1)
		end)

		it("should only fire events for active event maps", function()
			local eventHandler = jest.fn()
			focusNavigationService:focusGuiObject(tree.leftButton, true)
			focusNavigationService:registerEventHandler(tree.leftButton, "confirm", eventHandler, "Target")

			mockUserInputService:simulateInput(beginAEvent)
			expect(eventHandler).toHaveBeenCalledTimes(0)

			focusNavigationService:registerEventMap(tree.leftButton, {
				[Enum.KeyCode.A] = "confirm",
			})

			mockUserInputService:simulateInput(beginAEvent)

			expect(eventHandler).toHaveBeenCalledTimes(1)
			expect(eventHandler).toHaveBeenCalledWith(expect.objectContaining({
				eventData = beginAEvent,
			}))

			focusNavigationService:deregisterEventMap(tree.leftButton, {
				[Enum.KeyCode.A] = "confirm",
			})
			mockUserInputService:simulateInput(beginAEvent)
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
			mockUserInputService:simulateInput(beginAEvent)

			expect(eventHandler).toHaveBeenCalledTimes(0)

			focusNavigationService:focusGuiObject(tree.leftButton, true)
			mockUserInputService:simulateInput(beginAEvent)

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
			mockUserInputService:simulateInput(cancelEvent)

			expect(eventHandler).toHaveBeenCalledTimes(0)

			mockUserInputService:simulateInput(beginAEvent)

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

				mockUserInputService:simulateInput(beginAEvent)

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

				mockUserInputService:simulateInput(beginAEvent)

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

				mockUserInputService:simulateInput(beginAEvent)

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

				mockUserInputService:simulateInput(beginAEvent)

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
				root = { "ScreenGui", mountTarget },
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

		it("should only send blur and focus events for the relevant GuiService property", function()
			focusNavigationService:focusGuiObject(tree.leftButton, false)

			local handlerMap = getHandlerMap(phaseConfig.phase)
			focusNavigationService:registerEventHandlers(tree.leftButton, handlerMap)
			focusNavigationService:registerEventHandlers(tree.rightButton, handlerMap)

			if config.useCoreUi then
				GuiService.SelectedCoreObject = tree.rightButton
			else
				GuiService.SelectedObject = tree.rightButton
			end

			expect(handlerMap.blur.handler).toHaveBeenCalledTimes(1)
			expect(handlerMap.focus.handler).toHaveBeenCalledTimes(1)

			if config.useCoreUi then
				-- move non-core focus
				GuiService.SelectedObject = tree.leftContainer
			else
				-- move core focus
				GuiService.SelectedCoreObject = tree.leftContainer
			end

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
end)

-- TODO: CLIPS-244
-- describe("observable properties", function()
-- 	it("should expose an observable representing currently-focused instance", function() end)
-- 	it("should expose an observable representing currently-active event map", function() end)
-- 	it("should expose an observable representing currently-active input paradigm", function() end)
-- end)
