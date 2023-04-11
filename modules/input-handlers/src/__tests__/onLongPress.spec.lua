--!strict
local Packages = script.Parent.Parent.Parent
local JestGlobals = require(Packages.Dev.JestGlobals)

local jest = JestGlobals.jest
local it = JestGlobals.it
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach
local expect = JestGlobals.expect

local EventPropagationService = require(Packages.Dev.EventPropagation)

local makeMockEvent = require(script.Parent.makeMockEvent)
local onLongPress = require(script.Parent.Parent.onLongPress)

local targetInstance, eventPropagationService
beforeEach(function()
	jest.useFakeTimers()
	targetInstance = Instance.new("TextButton")
	eventPropagationService = EventPropagationService.new()
end)

afterEach(function()
	jest.useRealTimers()
end)

it("should fire after press and hold", function()
	local callback = jest.fn()
	eventPropagationService:registerEventHandler(targetInstance, "event", onLongPress(callback, 2))

	eventPropagationService:propagateEvent(targetInstance, "event", makeMockEvent(Enum.UserInputState.Begin), false)
	expect(callback).toHaveBeenCalledTimes(0)

	-- wait, but not enough
	jest.advanceTimersByTime(1000)
	expect(callback).toHaveBeenCalledTimes(0)

	-- fire
	jest.advanceTimersByTime(1000)
	expect(callback).toHaveBeenCalledTimes(1)
	expect(callback).toHaveBeenCalledWith(expect.objectContaining({
		-- what goes here?
		placeholder = "hello",
	}))
end)

it("should not fire more than once", function()
	local callback = jest.fn()
	eventPropagationService:registerEventHandler(targetInstance, "event", onLongPress(callback, 2))

	eventPropagationService:propagateEvent(targetInstance, "event", makeMockEvent(Enum.UserInputState.Begin), false)
	expect(callback).toHaveBeenCalledTimes(0)

	jest.advanceTimersByTime(2000)
	expect(callback).toHaveBeenCalledTimes(1)

	jest.advanceTimersByTime(2000)
	expect(callback).toHaveBeenCalledTimes(1)
end)

-- fixme: task.cancel not implemented for mock timers!
it.skip("should not fire if the button was released", function()
	local callback = jest.fn()
	eventPropagationService:registerEventHandler(targetInstance, "event", onLongPress(callback, 2))

	eventPropagationService:propagateEvent(targetInstance, "event", makeMockEvent(Enum.UserInputState.Begin), false)
	expect(callback).toHaveBeenCalledTimes(0)

	-- wait, but not enough
	jest.advanceTimersByTime(1000)
	expect(callback).toHaveBeenCalledTimes(0)
	eventPropagationService:propagateEvent(targetInstance, "event", makeMockEvent(Enum.UserInputState.End), false)

	-- would fire, but the button was released
	jest.advanceTimersByTime(1000)
	expect(callback).toHaveBeenCalledTimes(0)
end)
