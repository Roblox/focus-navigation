--!strict
local Packages = script.Parent.Parent.Parent
local JestGlobals = require(Packages.Dev.JestGlobals)

local jest = JestGlobals.jest
local it = JestGlobals.it
local describe = JestGlobals.describe
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach
local expect = JestGlobals.expect

local EventPropagationService
local makeMockEvent
local handleInput

local advanceTimersByTime, targetInstance, eventPropagationService
beforeEach(function()
	-- TODO: use only fake timers once they support Heartbeat
	-- FIXME jest: mock should not accept type 'string'
	jest.mock(script.Parent.Parent.Heartbeat :: any, function()
		local MockHeartbeat = require(script.Parent.MockHeartbeat)
		advanceTimersByTime = MockHeartbeat.advanceTimersByTime

		return MockHeartbeat
	end)

	jest.useFakeTimers()
	jest.resetModules()
	EventPropagationService = require(Packages.Dev.EventPropagation)
	makeMockEvent = require(script.Parent.makeMockEvent)
	handleInput = require(script.Parent.Parent.handleInput)

	targetInstance = Instance.new("TextButton")
	eventPropagationService = EventPropagationService.new()
end)

afterEach(function()
	jest.useRealTimers()
end)

describe("custom input handling", function()
	it("can combine onRelease and onLongPress behaviors", function()
		local onRelease = jest.fn()
		local onHoldComplete = jest.fn()
		eventPropagationService:registerEventHandler(
			targetInstance,
			"event",
			handleInput({
				onRelease = onRelease,
				hold = {
					durationSeconds = 1,
					onComplete = onHoldComplete,
				},
			})
		)

		eventPropagationService:propagateEvent(targetInstance, "event", makeMockEvent(Enum.UserInputState.Begin), false)
		expect(onRelease).toHaveBeenCalledTimes(0)
		expect(onHoldComplete).toHaveBeenCalledTimes(0)

		-- wait, but not enough, then release
		advanceTimersByTime(500)
		eventPropagationService:propagateEvent(targetInstance, "event", makeMockEvent(Enum.UserInputState.End), false)
		expect(onRelease).toHaveBeenCalledTimes(1)
		expect(onHoldComplete).toHaveBeenCalledTimes(0)

		-- start again
		eventPropagationService:propagateEvent(targetInstance, "event", makeMockEvent(Enum.UserInputState.Begin), false)
		advanceTimersByTime(1000)
		expect(onRelease).toHaveBeenCalledTimes(1)
		expect(onHoldComplete).toHaveBeenCalledTimes(1)

		-- release _after_ hold completion, shouldn't trigger new "release"
		eventPropagationService:propagateEvent(targetInstance, "event", makeMockEvent(Enum.UserInputState.End), false)
		expect(onRelease).toHaveBeenCalledTimes(1)
		expect(onHoldComplete).toHaveBeenCalledTimes(1)
	end)

	it("can describe custom 'hold' behavior via onPress and onRelease", function()
		local startHold, holdDuration
		local onPress = jest.fn(function()
			startHold = os.clock()
		end)
		local onRelease = jest.fn(function()
			holdDuration = os.clock() - startHold
		end)
		eventPropagationService:registerEventHandler(
			targetInstance,
			"event",
			handleInput({
				onPress = onPress,
				onRelease = onRelease,
			})
		)

		eventPropagationService:propagateEvent(targetInstance, "event", makeMockEvent(Enum.UserInputState.Begin), false)
		expect(onPress).toHaveBeenCalledTimes(1)
		expect(onRelease).toHaveBeenCalledTimes(0)

		advanceTimersByTime(500)
		eventPropagationService:propagateEvent(targetInstance, "event", makeMockEvent(Enum.UserInputState.End), false)
		expect(onPress).toHaveBeenCalledTimes(1)
		expect(onRelease).toHaveBeenCalledTimes(1)

		expect(holdDuration).toBeCloseTo(0.5, 0.01)

		eventPropagationService:propagateEvent(targetInstance, "event", makeMockEvent(Enum.UserInputState.Begin), false)
		advanceTimersByTime(1800)
		eventPropagationService:propagateEvent(targetInstance, "event", makeMockEvent(Enum.UserInputState.End), false)

		expect(onPress).toHaveBeenCalledTimes(2)
		expect(onRelease).toHaveBeenCalledTimes(2)
		expect(holdDuration).toBeCloseTo(1.8, 0.01)
	end)

	it("can use both hold and release logic when allowReleaseAfterHold is enabled", function()
		local onRelease = jest.fn()
		local onHoldComplete = jest.fn()
		eventPropagationService:registerEventHandler(
			targetInstance,
			"event",
			handleInput({
				onRelease = onRelease,
				hold = {
					durationSeconds = 1,
					onComplete = onHoldComplete,
					allowReleaseAfterHold = true,
				},
			})
		)

		eventPropagationService:propagateEvent(targetInstance, "event", makeMockEvent(Enum.UserInputState.Begin), false)
		expect(onRelease).toHaveBeenCalledTimes(0)
		expect(onHoldComplete).toHaveBeenCalledTimes(0)

		-- release without triggering hold
		advanceTimersByTime(500)
		eventPropagationService:propagateEvent(targetInstance, "event", makeMockEvent(Enum.UserInputState.End), false)
		expect(onRelease).toHaveBeenCalledTimes(1)
		expect(onHoldComplete).toHaveBeenCalledTimes(0)

		-- release after hold, both trigger
		eventPropagationService:propagateEvent(targetInstance, "event", makeMockEvent(Enum.UserInputState.Begin), false)
		advanceTimersByTime(1000)
		eventPropagationService:propagateEvent(targetInstance, "event", makeMockEvent(Enum.UserInputState.End), false)

		expect(onRelease).toHaveBeenCalledTimes(2)
		expect(onHoldComplete).toHaveBeenCalledTimes(1)
	end)
end)
