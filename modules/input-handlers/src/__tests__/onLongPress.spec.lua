--!strict
local Packages = script.Parent.Parent.Parent
local JestGlobals = require(Packages.Dev.JestGlobals)

local jest = JestGlobals.jest
local it = JestGlobals.it
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach
local expect = JestGlobals.expect

local EventPropagationService
local makeMockEvent
local onLongPress

local FRAME_DURATION_MS, advanceTimersByTime
local targetInstance, eventPropagationService
beforeEach(function()
	-- TODO: use fake timers exclusively once they have support for Heartbeat
	jest.mock(script.Parent.Parent.Heartbeat, function()
		local MockHeartbeat = require(script.Parent.MockHeartbeat)
		FRAME_DURATION_MS = MockHeartbeat.FRAME_DURATION_MS
		advanceTimersByTime = MockHeartbeat.advanceTimersByTime

		return MockHeartbeat
	end)

	jest.useFakeTimers()
	jest.resetModules()
	EventPropagationService = require(Packages.Dev.EventPropagation)
	makeMockEvent = require(script.Parent.makeMockEvent)
	onLongPress = require(script.Parent.Parent.onLongPress)

	targetInstance = Instance.new("TextButton")
	eventPropagationService = EventPropagationService.new()
end)

afterEach(function()
	jest.useRealTimers()
end)

it("should fire after press and hold", function()
	local callback = jest.fn()
	eventPropagationService:registerEventHandler(targetInstance, "event", onLongPress(1, callback))

	eventPropagationService:propagateEvent(targetInstance, "event", makeMockEvent(Enum.UserInputState.Begin), false)
	expect(callback).toHaveBeenCalledTimes(0)

	-- wait, but not enough
	advanceTimersByTime(500)
	expect(callback).toHaveBeenCalledTimes(0)

	-- fire
	advanceTimersByTime(500)
	expect(callback).toHaveBeenCalledTimes(1)
end)

it("should not fire more than once", function()
	local callback = jest.fn()
	eventPropagationService:registerEventHandler(targetInstance, "event", onLongPress(1, callback))

	eventPropagationService:propagateEvent(targetInstance, "event", makeMockEvent(Enum.UserInputState.Begin), false)
	expect(callback).toHaveBeenCalledTimes(0)

	advanceTimersByTime(1000)
	expect(callback).toHaveBeenCalledTimes(1)

	advanceTimersByTime(1000)
	expect(callback).toHaveBeenCalledTimes(1)
end)

it("should not fire if the button was released", function()
	local callback = jest.fn()
	eventPropagationService:registerEventHandler(targetInstance, "event", onLongPress(1, callback))

	eventPropagationService:propagateEvent(targetInstance, "event", makeMockEvent(Enum.UserInputState.Begin), false)
	expect(callback).toHaveBeenCalledTimes(0)

	-- wait, but not enough
	advanceTimersByTime(500)
	expect(callback).toHaveBeenCalledTimes(0)
	eventPropagationService:propagateEvent(targetInstance, "event", makeMockEvent(Enum.UserInputState.End), false)

	-- would fire, but the button was released
	advanceTimersByTime(500)
	expect(callback).toHaveBeenCalledTimes(0)
end)

it("should update the onStep function each frame while held", function()
	local onHoldStep = jest.fn()
	local onHoldComplete = jest.fn()
	eventPropagationService:registerEventHandler(targetInstance, "event", onLongPress(1, onHoldComplete, onHoldStep))

	eventPropagationService:propagateEvent(targetInstance, "event", makeMockEvent(Enum.UserInputState.Begin), false)
	expect(onHoldStep).toHaveBeenCalledTimes(0)
	expect(onHoldComplete).toHaveBeenCalledTimes(0)

	-- wait, but not enough
	advanceTimersByTime(FRAME_DURATION_MS * 6)
	expect(onHoldStep).toHaveBeenCalledTimes(6)
	expect(onHoldComplete).toHaveBeenCalledTimes(0)

	advanceTimersByTime(1000)
	expect(onHoldComplete).toHaveBeenCalledTimes(1)
	expect(onHoldStep).toHaveBeenCalledTimes(math.floor(1000 / FRAME_DURATION_MS))

	-- onHoldStep callback disconnected after hold completes
	advanceTimersByTime(1000)
	expect(onHoldStep).toHaveBeenCalledTimes(math.floor(1000 / FRAME_DURATION_MS))
end)

it("should only fires onStep function frame while held", function()
	local onHoldStep = jest.fn()
	local onHoldComplete = jest.fn()
	eventPropagationService:registerEventHandler(targetInstance, "event", onLongPress(1, onHoldComplete, onHoldStep))

	eventPropagationService:propagateEvent(targetInstance, "event", makeMockEvent(Enum.UserInputState.Begin), false)
	expect(onHoldStep).toHaveBeenCalledTimes(0)
	expect(onHoldComplete).toHaveBeenCalledTimes(0)

	-- wait, but not enough
	advanceTimersByTime(FRAME_DURATION_MS * 6)
	expect(onHoldStep).toHaveBeenCalledTimes(6)
	expect(onHoldComplete).toHaveBeenCalledTimes(0)

	eventPropagationService:propagateEvent(targetInstance, "event", makeMockEvent(Enum.UserInputState.End), false)
	advanceTimersByTime(1000)
	expect(onHoldStep).toHaveBeenCalledTimes(6)

	eventPropagationService:propagateEvent(targetInstance, "event", makeMockEvent(Enum.UserInputState.Begin), false)
	advanceTimersByTime(1000)

	expect(onHoldStep).toHaveBeenCalledTimes(math.floor(1000 / FRAME_DURATION_MS) + 6)
end)
