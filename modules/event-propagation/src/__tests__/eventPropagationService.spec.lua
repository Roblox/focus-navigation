local Packages = script.Parent.Parent.Parent
local JestGlobals = require(Packages.Dev.JestGlobals)

local it = JestGlobals.it
local expect = JestGlobals.expect
local describe = JestGlobals.describe
local jest = JestGlobals.jest

local EventPropagationService = require(script.Parent.Parent.eventPropagationService)

describe("EventPropagationService", function()
	describe("registerEventHandlers", function()
		it("should register a map of eventHandlers for an Instance", function()
			local eventPropagationService = EventPropagationService.new()
			local instance = Instance.new("Frame")
			local function functionOne() end
			local function functionTwo() end
			local eventHandlers = {
				eventType1 = {
					phase = "Capture",
					handler = functionOne,
				},
				eventType2 = {
					phase = "Bubble",
					handler = functionTwo,
				},
			}
			eventPropagationService:registerEventHandlers(instance, eventHandlers)
			local expected = {
				__mode = "k",
				[instance] = {
					eventType1 = {
						Capture = functionOne,
					},
					eventType2 = {
						Bubble = functionTwo,
					},
				},
			}
			expect(eventPropagationService.eventHandlerRegistry).toEqual(expected)
		end)
		it("should use the Bubble phase as the default phase for handlers that do not specify phase", function()
			local eventPropagationService = EventPropagationService.new()
			local instance = Instance.new("Frame")
			local function functionOne() end
			local eventHandlers = {
				eventType = {
					handler = functionOne,
				},
			}
			eventPropagationService:registerEventHandlers(instance, eventHandlers)
			local expected = {
				__mode = "k",
				[instance] = {
					eventType = {
						Bubble = functionOne,
					},
				},
			}
			expect(eventPropagationService.eventHandlerRegistry).toEqual(expected)
		end)
		it("should register multiple eventHandlerMaps by Instance", function()
			local eventPropagationService = EventPropagationService.new()
			local instance1 = Instance.new("Frame")
			local instance2 = Instance.new("Frame")
			local function functionOne() end
			local function functionTwo() end
			local function functionThree() end
			local function functionFour() end
			local eventHandlers1 = {
				eventType1 = {
					phase = "Capture",
					handler = functionOne,
				},
				eventType2 = {
					handler = functionTwo,
				},
			}
			local eventHandlers2 = {
				eventType1 = {
					handler = functionThree,
				},
				eventType2 = {
					handler = functionFour,
				},
			}
			eventPropagationService:registerEventHandlers(instance1, eventHandlers1)
			eventPropagationService:registerEventHandlers(instance2, eventHandlers2)
			local expected = {
				__mode = "k",
				[instance1] = {
					eventType1 = {
						Capture = functionOne,
					},
					eventType2 = {
						Bubble = functionTwo,
					},
				},
				[instance2] = {
					eventType1 = {
						Bubble = functionThree,
					},
					eventType2 = {
						Bubble = functionFour,
					},
				},
			}
			expect(eventPropagationService.eventHandlerRegistry).toEqual(expected)
		end)
		it("should overwrite eventHandlers in phases that already exist", function()
			local eventPropagationService = EventPropagationService.new()
			local instance = Instance.new("Frame")
			local function functionOne() end
			local function functionTwo() end
			local function functionThree() end
			local eventHandlers = {
				eventType1 = {
					phase = "Capture",
					handler = functionOne,
				},
				eventType2 = {
					handler = functionTwo,
				},
			}
			eventPropagationService:registerEventHandlers(instance, eventHandlers)
			local eventHandlers2 = {
				eventType2 = {
					handler = functionThree,
				},
			}
			eventPropagationService:registerEventHandlers(instance, eventHandlers2)
			local expected = {
				__mode = "k",
				[instance] = {
					eventType1 = {
						Capture = functionOne,
					},
					eventType2 = {
						Bubble = functionThree,
					},
				},
			}
			expect(eventPropagationService.eventHandlerRegistry).toEqual(expected)
		end)
	end)
	describe("deRegisterEventHandlers", function()
		it("should remove the eventHandlers for a Instance", function()
			local eventPropagationService = EventPropagationService.new()
			local instance = Instance.new("Frame")
			local function handler() end
			local eventHandlers = {
				eventType = {
					handler = handler,
				},
			}
			eventPropagationService:registerEventHandlers(instance, eventHandlers)
			local expectedRegistryWithHandler = {
				__mode = "k",
				[instance] = {
					eventType = {
						Bubble = handler,
					},
				},
			}
			expect(eventPropagationService.eventHandlerRegistry).toEqual(expectedRegistryWithHandler)
			eventPropagationService:deRegisterEventHandlers(instance)
			local expectedRegistryWithoutHandler = {
				__mode = "k",
			}
			expect(eventPropagationService.eventHandlerRegistry).toEqual(expectedRegistryWithoutHandler)
		end)
		it("should leave unrelated eventHandlers in the registry", function()
			local eventPropagationService = EventPropagationService.new()
			local instance = Instance.new("Frame")
			local function handler() end
			local eventHandlers = {
				eventType = {
					handler = handler,
				},
			}
			eventPropagationService:registerEventHandlers(instance, eventHandlers)
			local instance2 = Instance.new("Frame")
			eventPropagationService:registerEventHandlers(instance2, eventHandlers)
			local expectedRegistryWithHandlers = {
				__mode = "k",
				[instance] = {
					eventType = {
						Bubble = handler,
					},
				},
				[instance2] = {
					eventType = {
						Bubble = handler,
					},
				},
			}
			expect(eventPropagationService.eventHandlerRegistry).toEqual(expectedRegistryWithHandlers)
			eventPropagationService:deRegisterEventHandlers(instance)
			local expectedRegistryWithoutHandlers = {
				__mode = "k",
				[instance2] = {
					eventType = {
						Bubble = handler,
					},
				},
			}
			expect(eventPropagationService.eventHandlerRegistry).toEqual(expectedRegistryWithoutHandlers)
		end)
	end)
	describe("registerEventHandler", function()
		it.each({
			{ phase = "Bubble" },
			{ phase = "Capture" },
			{ phase = "Target" },
		})("should register an eventHandler of a given eventName for a Instance in the $phase phase", function(args)
			local eventPropagationService = EventPropagationService.new()
			local instance = Instance.new("Frame")
			local function handler() end
			local eventName = "eventName"
			eventPropagationService:registerEventHandler(instance, eventName, handler, args.phase)
			local expected = {
				__mode = "k",
				[instance] = {
					[eventName] = {
						[args.phase] = handler,
					},
				},
			}
			expect(eventPropagationService.eventHandlerRegistry).toEqual(expected)
		end)
		it(
			"should register an eventHandler of a given eventName for an instance in the Bubble phase by default",
			function()
				local eventPropagationService = EventPropagationService.new()
				local instance = Instance.new("Frame")
				local function handler() end
				local eventName = "eventName"
				eventPropagationService:registerEventHandler(instance, eventName, handler)
				local expected = {
					__mode = "k",
					[instance] = {
						[eventName] = {
							Bubble = handler,
						},
					},
				}
				expect(eventPropagationService.eventHandlerRegistry).toEqual(expected)
			end
		)

		it.each({
			{ phase = "Bubble" },
			{ phase = "Capture" },
			{ phase = "Target" },
		})(
			"should leave other eventHandlers intact while registering an eventHandler of a given eventName for an Instance in the $phase phase",
			function(args)
				local eventPropagationService = EventPropagationService.new()
				local instanceOne = Instance.new("Frame")
				local function handlerOne() end
				local eventNameOne = "eventNameOne"
				local instanceTwo = Instance.new("Frame")
				local function handlerTwo() end
				local eventNameTwo = "eventNameTwo"
				local eventMap = {
					[eventNameOne] = {
						phase = "Capture",
						handler = handlerOne,
					},
					[eventNameTwo] = {
						handler = handlerTwo,
					},
				}
				eventPropagationService:registerEventHandlers(instanceOne, eventMap)
				eventPropagationService:registerEventHandlers(instanceTwo, eventMap)
				local eventNameThree = "eventNameThree"
				eventPropagationService:registerEventHandler(instanceOne, eventNameThree, handlerOne, args.phase)
				local expected = {
					__mode = "k",
					[instanceOne] = {
						[eventNameOne] = {
							Capture = handlerOne,
						},
						[eventNameTwo] = {
							Bubble = handlerTwo,
						},
						[eventNameThree] = {
							[args.phase] = handlerOne,
						},
					},
					[instanceTwo] = {
						[eventNameOne] = {
							Capture = handlerOne,
						},
						[eventNameTwo] = {
							Bubble = handlerTwo,
						},
					},
				}
				expect(eventPropagationService.eventHandlerRegistry).toEqual(expected)
			end
		)
	end)
	describe("deRegisterEventHandler", function()
		it.each({
			{ phase = "Bubble" },
			{ phase = "Capture" },
			{ phase = "Target" },
		})(
			"should deregister all eventHandlers of a given eventName for an Instance in the $phase phase",
			function(args)
				local eventPropagationService = EventPropagationService.new()
				local instance = Instance.new("Frame")
				local function handler() end
				local eventName = "eventName"
				eventPropagationService:registerEventHandler(instance, eventName, handler, args.phase)
				local expectedRegistryWithHandler = {
					__mode = "k",
					[instance] = {
						[eventName] = {
							[args.phase] = handler,
						},
					},
				}
				expect(eventPropagationService.eventHandlerRegistry).toEqual(expectedRegistryWithHandler)
				eventPropagationService:deRegisterEventHandler(instance, eventName, args.phase)
				local expectedRegistryWithoutHandler = {
					__mode = "k",
					[instance] = {
						[eventName] = {},
					},
				}
				expect(eventPropagationService.eventHandlerRegistry).toEqual(expectedRegistryWithoutHandler)
			end
		)

		it(
			"should deregister all eventHandlers of a given eventName for a Instance in the Bubble phase by default",
			function()
				local eventPropagationService = EventPropagationService.new()
				local instance = Instance.new("Frame")
				local function handler() end
				local eventName = "eventName"
				eventPropagationService:registerEventHandler(instance, eventName, handler)
				local expectedRegistryWithHandlers = {
					__mode = "k",
					[instance] = {
						[eventName] = {
							Bubble = handler,
						},
					},
				}
				expect(eventPropagationService.eventHandlerRegistry).toEqual(expectedRegistryWithHandlers)
				eventPropagationService:deRegisterEventHandler(instance, eventName)
				local expectedRegistryWithoutHandlers = {
					__mode = "k",
					[instance] = {
						[eventName] = {},
					},
				}
				expect(eventPropagationService.eventHandlerRegistry).toEqual(expectedRegistryWithoutHandlers)
			end
		)

		it.each({
			{ phase = "Bubble" },
			{ phase = "Capture" },
			{ phase = "Target" },
		})(
			"should leave other eventHandlers intact while deRegistering an event handler of a given eventName for a Instance in the $phase phase",
			function(args)
				local eventPropagationService = EventPropagationService.new()
				local instanceOne = Instance.new("Frame")
				local function handlerOne() end
				local eventNameOne = "eventNameOne"
				local instanceTwo = Instance.new("Frame")
				local function handlerTwo() end
				local eventNameTwo = "eventNameTwo"
				local eventMap = {
					[eventNameOne] = {
						phase = args.phase,
						handler = handlerOne,
					},
					[eventNameTwo] = {
						handler = handlerTwo,
					},
				}
				eventPropagationService:registerEventHandlers(instanceOne, eventMap)
				eventPropagationService:registerEventHandlers(instanceTwo, eventMap)
				eventPropagationService:deRegisterEventHandler(instanceOne, eventNameOne, args.phase)
				local expected = {
					__mode = "k",
					[instanceOne] = {
						[eventNameOne] = {},
						[eventNameTwo] = {
							Bubble = handlerTwo,
						},
					},
					[instanceTwo] = {
						[eventNameOne] = {
							[args.phase] = handlerOne,
						},
						[eventNameTwo] = {
							Bubble = handlerTwo,
						},
					},
				}
				expect(eventPropagationService.eventHandlerRegistry).toEqual(expected)
			end
		)
	end)
	describe("propagateEvent", function()
		it("should call eventHandlers in the correct order", function()
			local eventPropagationService = EventPropagationService.new()
			local instanceOne = Instance.new("Frame")
			local instanceTwo = Instance.new("Frame")
			instanceTwo.Parent = instanceOne
			local instanceThree = Instance.new("Frame")
			instanceThree.Parent = instanceTwo
			local eventName = "eventName"
			local handler = jest.fn()
			local eventHandlerMapOne = {
				[eventName] = {
					phase = "Bubble",
					handler = handler,
				},
			}
			local eventHandlerMapTwo = {
				[eventName] = {
					phase = "Capture",
					handler = handler,
				},
			}
			local eventHandlerMapThree = {
				[eventName] = {
					phase = "Target",
					handler = handler,
				},
			}
			eventPropagationService:registerEventHandlers(instanceOne, eventHandlerMapOne)
			eventPropagationService:registerEventHandlers(instanceTwo, eventHandlerMapTwo)
			eventPropagationService:registerEventHandlers(instanceThree, eventHandlerMapThree)
			eventPropagationService:propagateEvent(instanceThree, eventName)
			expect(handler.mock.calls).toEqual({
				{
					expect.objectContaining({
						phase = "Capture",
						currentInstance = instanceTwo,
					}),
				},
				{
					expect.objectContaining({
						phase = "Target",
						currentInstance = instanceThree,
					}),
				},
				{
					expect.objectContaining({
						phase = "Bubble",
						currentInstance = instanceOne,
					}),
				},
			})
		end)
		it("should call eventHandlers with an appropriate Event", function()
			local eventPropagationService = EventPropagationService.new()
			local instanceOne = Instance.new("Frame")
			local eventName = "eventName"
			local handler = jest.fn()
			local eventHandlerMapOne = {
				[eventName] = {
					phase = "Bubble",
					handler = handler,
				},
			}
			eventPropagationService:registerEventHandlers(instanceOne, eventHandlerMapOne)
			eventPropagationService:propagateEvent(instanceOne, eventName)
			expect(handler.mock.calls).toEqual({
				{

					{
						cancelled = false,
						phase = "Bubble",
						currentInstance = instanceOne,
						targetInstance = instanceOne,
						eventName = eventName,
					},
				},
			})
		end)
		it("should be able to cancel the event during the bubble phase", function()
			local handler = jest.fn()
				.mockImplementationOnce(function() end)
				.mockImplementationOnce(function() end)
				.mockImplementationOnce(function(event)
					event:cancel()
				end)
			local eventPropagationService = EventPropagationService.new()
			local instanceOne = Instance.new("Frame")
			local instanceTwo = Instance.new("Frame")
			instanceTwo.Parent = instanceOne
			local instanceThree = Instance.new("Frame")
			instanceThree.Parent = instanceTwo
			local eventName = "eventName"
			local eventHandlerMapOne = {
				[eventName] = {
					phase = "Bubble",
					handler = handler,
				},
			}
			local eventHandlerMapTwo = {
				[eventName] = {
					phase = "Capture",
					handler = handler,
				},
			}
			local eventHandlerMapThree = {
				[eventName] = {
					phase = "Target",
					handler = handler,
				},
			}
			local eventHandlerMapThreeBubble = {
				[eventName] = {
					phase = "Bubble",
					handler = handler,
				},
			}
			eventPropagationService:registerEventHandlers(instanceOne, eventHandlerMapOne)
			eventPropagationService:registerEventHandlers(instanceTwo, eventHandlerMapTwo)
			eventPropagationService:registerEventHandlers(instanceThree, eventHandlerMapThree)
			eventPropagationService:registerEventHandlers(instanceThree, eventHandlerMapThreeBubble)
			eventPropagationService:propagateEvent(instanceThree, eventName)
			expect(handler.mock.calls).toEqual({
				{
					expect.objectContaining({
						phase = "Capture",
						currentInstance = instanceTwo,
					}),
				},
				{
					expect.objectContaining({
						phase = "Target",
						currentInstance = instanceThree,
					}),
				},
				{
					expect.objectContaining({
						phase = "Bubble",
						currentInstance = instanceThree,
					}),
				},
			})
		end)
		it("should be able to cancel the event during the target phase", function()
			local handler = jest.fn().mockImplementationOnce(function() end).mockImplementationOnce(function(event)
				event:cancel()
			end)
			local eventPropagationService = EventPropagationService.new()
			local instanceOne = Instance.new("Frame")
			local instanceTwo = Instance.new("Frame")
			instanceTwo.Parent = instanceOne
			local instanceThree = Instance.new("Frame")
			instanceThree.Parent = instanceTwo
			local eventName = "eventName"
			local eventHandlerMapOne = {
				[eventName] = {
					phase = "Bubble",
					handler = handler,
				},
			}
			local eventHandlerMapTwo = {
				[eventName] = {
					phase = "Capture",
					handler = handler,
				},
			}
			local eventHandlerMapThree = {
				[eventName] = {
					phase = "Target",
					handler = handler,
				},
			}
			eventPropagationService:registerEventHandlers(instanceOne, eventHandlerMapOne)
			eventPropagationService:registerEventHandlers(instanceTwo, eventHandlerMapTwo)
			eventPropagationService:registerEventHandlers(instanceThree, eventHandlerMapThree)
			eventPropagationService:propagateEvent(instanceThree, eventName)
			expect(handler.mock.calls).toEqual({
				{
					expect.objectContaining({
						phase = "Capture",
						currentInstance = instanceTwo,
					}),
				},
				{
					expect.objectContaining({
						phase = "Target",
						currentInstance = instanceThree,
					}),
				},
			})
		end)
		it("should be able to cancel the event during the capture phase", function()
			local handler = jest.fn().mockImplementationOnce(function(event)
				event:cancel()
			end)
			local eventPropagationService = EventPropagationService.new()
			local instanceOne = Instance.new("Frame")
			local instanceTwo = Instance.new("Frame")
			instanceTwo.Parent = instanceOne
			local instanceThree = Instance.new("Frame")
			instanceThree.Parent = instanceTwo
			local eventName = "eventName"
			local eventHandlerMapOne = {
				[eventName] = {
					phase = "Bubble",
					handler = handler,
				},
			}
			local eventHandlerMapTwo = {
				[eventName] = {
					phase = "Capture",
					handler = handler,
				},
			}
			local eventHandlerMapThree = {
				[eventName] = {
					phase = "Capture",
					handler = handler,
				},
			}
			eventPropagationService:registerEventHandlers(instanceOne, eventHandlerMapOne)
			eventPropagationService:registerEventHandlers(instanceTwo, eventHandlerMapTwo)
			eventPropagationService:registerEventHandlers(instanceThree, eventHandlerMapThree)
			eventPropagationService:propagateEvent(instanceThree, eventName)
			expect(handler.mock.calls).toEqual({
				{
					expect.objectContaining({
						phase = "Capture",
						currentInstance = instanceTwo,
					}),
				},
			})
		end)
		it("should call eventHandlers in the target phase if the eventHandler is registered on the target", function()
			local handler = jest.fn()
			local eventPropagationService = EventPropagationService.new()
			local instanceOne = Instance.new("Frame")
			local eventName = "eventName"
			local eventHandlerMapOne = {
				[eventName] = {
					phase = "Target",
					handler = handler,
				},
			}

			eventPropagationService:registerEventHandlers(instanceOne, eventHandlerMapOne)
			eventPropagationService:propagateEvent(instanceOne, eventName)
			expect(handler.mock.calls).toEqual({
				{
					expect.objectContaining({
						phase = "Target",
						currentInstance = instanceOne,
					}),
				},
			})
		end)
		it(
			"should not call eventHandlers in the target phase if the eventHandler is not registered on the target",
			function()
				local handler = jest.fn()
				local eventPropagationService = EventPropagationService.new()
				local instanceOne = Instance.new("Frame")
				local instanceTwo = Instance.new("Frame")
				instanceTwo.Parent = instanceOne
				local eventName = "eventName"
				local eventHandlerMapOne = {
					[eventName] = {
						phase = "Target",
						handler = handler,
					},
				}

				eventPropagationService:registerEventHandlers(instanceOne, eventHandlerMapOne)
				eventPropagationService:propagateEvent(instanceTwo, eventName)
				expect(handler).toHaveBeenCalledTimes(0)
			end
		)
		describe("when silent is true", function()
			it.each({ { phase = "Bubble" }, { phase = "Capture" }, { phase = "Target" } })(
				"should call eventHandlers in the $phase phase only on the target instance",
				function(args)
					local handler = jest.fn()
					local eventPropagationService = EventPropagationService.new()
					local instanceOne = Instance.new("Frame")
					local instanceTwo = Instance.new("Frame")
					instanceTwo.Parent = instanceOne
					local instanceThree = Instance.new("Frame")
					instanceThree.Parent = instanceTwo
					local eventName = "eventName"
					local eventHandlerMapOne = {
						[eventName] = {
							phase = "Bubble",
							handler = handler,
						},
					}
					local eventHandlerMapTwo = {
						[eventName] = {
							phase = "Capture",
							handler = handler,
						},
					}
					local eventHandlerMapThree = {
						[eventName] = {
							phase = args.phase,
							handler = handler,
						},
					}
					eventPropagationService:registerEventHandlers(instanceOne, eventHandlerMapOne)
					eventPropagationService:registerEventHandlers(instanceTwo, eventHandlerMapTwo)
					eventPropagationService:registerEventHandlers(instanceThree, eventHandlerMapThree)
					eventPropagationService:propagateEvent(instanceThree, eventName, nil, true)
					expect(handler.mock.calls).toEqual({
						{
							expect.objectContaining({
								phase = args.phase,
								currentInstance = instanceThree,
							}),
						},
					})
				end
			)
		end)
		describe("when event info is present", function()
			it.each({ { phase = "Bubble" }, { phase = "Capture" }, { phase = "Target" } })(
				"should pass the provided event info to handlers registered for the $phase phase",
				function(args)
					local handler = jest.fn()
					local eventPropagationService = EventPropagationService.new()
					local instanceOne = Instance.new("Frame")
					local eventName = "eventName"
					local eventHandlerMapOne = {
						[eventName] = {
							phase = args.phase,
							handler = handler,
						},
					}
					eventPropagationService:registerEventHandlers(instanceOne, eventHandlerMapOne)
					local eventInfo = { itemA = "1", itemB = "2" }
					eventPropagationService:propagateEvent(instanceOne, eventName, eventInfo, true)
					expect(handler.mock.calls).toEqual({
						{
							expect.objectContaining({
								phase = args.phase,
								currentInstance = instanceOne,
								eventInfo = eventInfo,
							}),
						},
					})
				end
			)
		end)
	end)
end)

return {}
