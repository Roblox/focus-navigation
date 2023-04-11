--!strict
local Packages = script.Parent.Parent.Parent
local JestGlobals = require(Packages.Dev.JestGlobals)

local jest = JestGlobals.jest
local it = JestGlobals.it
local beforeEach = JestGlobals.beforeEach
local expect = JestGlobals.expect

local EventPropagationService = require(Packages.Dev.EventPropagation)

local makeMockEvent = require(script.Parent.makeMockEvent)
local onPress = require(script.Parent.Parent.onPress)

local targetInstance, eventPropagationService
beforeEach(function()
	targetInstance = Instance.new("TextButton")
	eventPropagationService = EventPropagationService.new()
end)

it("should fire on press", function()
	local callback = jest.fn()
	eventPropagationService:registerEventHandler(targetInstance, "event", onPress(callback))

	local event = makeMockEvent(Enum.UserInputState.Begin)
	eventPropagationService:propagateEvent(targetInstance, "event", event, false)
	expect(callback).toHaveBeenCalledTimes(1)
	expect(callback).toHaveBeenCalledWith(expect.objectContaining({
		eventData = event,
	}))
end)

it("should fire on every press", function()
	local callback = jest.fn()
	eventPropagationService:registerEventHandler(targetInstance, "event", onPress(callback))

	local event = makeMockEvent(Enum.UserInputState.Begin)
	eventPropagationService:propagateEvent(targetInstance, "event", event, false)
	eventPropagationService:propagateEvent(targetInstance, "event", event, false)
	eventPropagationService:propagateEvent(targetInstance, "event", event, false)

	expect(callback).toHaveBeenCalledTimes(3)
end)

it("should not fire on a non-press", function()
	local callback = jest.fn()
	eventPropagationService:registerEventHandler(targetInstance, "event", onPress(callback))

	local event = makeMockEvent(Enum.UserInputState.End)
	eventPropagationService:propagateEvent(targetInstance, "event", event, false)
	expect(callback).never.toHaveBeenCalled()

	event = makeMockEvent(Enum.UserInputState.Cancel)
	eventPropagationService:propagateEvent(targetInstance, "event", event, false)
	expect(callback).never.toHaveBeenCalled()

	event = makeMockEvent(Enum.UserInputState.Begin)
	eventPropagationService:propagateEvent(targetInstance, "event", event, false)
	expect(callback).toHaveBeenCalledTimes(1)
end)
