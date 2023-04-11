--!strict
local Packages = script.Parent.Parent.Parent
local JestGlobals = require(Packages.Dev.JestGlobals)

local jest = JestGlobals.jest
local it = JestGlobals.it
local beforeEach = JestGlobals.beforeEach
local expect = JestGlobals.expect

local EventPropagationService = require(Packages.Dev.EventPropagation)

local makeMockEvent = require(script.Parent.makeMockEvent)
local onRelease = require(script.Parent.Parent.onRelease)

local targetInstance, eventPropagationService
beforeEach(function()
	targetInstance = Instance.new("TextButton")
	eventPropagationService = EventPropagationService.new()
end)

it("should fire after press and release", function()
	local callback = jest.fn()
	eventPropagationService:registerEventHandler(targetInstance, "event", onRelease(callback))

	eventPropagationService:propagateEvent(targetInstance, "event", makeMockEvent(Enum.UserInputState.Begin), false)
	expect(callback).toHaveBeenCalledTimes(0)

	eventPropagationService:propagateEvent(targetInstance, "event", makeMockEvent(Enum.UserInputState.End), false)
	expect(callback).toHaveBeenCalledTimes(1)
	expect(callback).toHaveBeenCalledWith(expect.objectContaining({
		eventData = expect.objectContaining({
			UserInputState = Enum.UserInputState.End,
		}),
	}))
end)

it("should fire after multiple presses and releases", function()
	local callback = jest.fn()
	eventPropagationService:registerEventHandler(targetInstance, "event", onRelease(callback))

	eventPropagationService:propagateEvent(targetInstance, "event", makeMockEvent(Enum.UserInputState.Begin), false)
	eventPropagationService:propagateEvent(targetInstance, "event", makeMockEvent(Enum.UserInputState.End), false)

	eventPropagationService:propagateEvent(targetInstance, "event", makeMockEvent(Enum.UserInputState.Begin), false)
	eventPropagationService:propagateEvent(targetInstance, "event", makeMockEvent(Enum.UserInputState.End), false)

	expect(callback).toHaveBeenCalledTimes(2)
end)

it("should not fire with only a release", function()
	local callback = jest.fn()
	eventPropagationService:registerEventHandler(targetInstance, "event", onRelease(callback))

	eventPropagationService:propagateEvent(targetInstance, "event", makeMockEvent(Enum.UserInputState.End), false)
	expect(callback).toHaveBeenCalledTimes(0)

	eventPropagationService:propagateEvent(targetInstance, "event", makeMockEvent(Enum.UserInputState.Begin), false)
	eventPropagationService:propagateEvent(targetInstance, "event", makeMockEvent(Enum.UserInputState.End), false)
	expect(callback).toHaveBeenCalledTimes(1)

	eventPropagationService:propagateEvent(targetInstance, "event", makeMockEvent(Enum.UserInputState.End), false)
	expect(callback).toHaveBeenCalledTimes(1)
end)
