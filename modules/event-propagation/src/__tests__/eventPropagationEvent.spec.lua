local Packages = script.Parent.Parent.Parent
local JestGlobals = require(Packages.Dev.JestGlobals)

local it = JestGlobals.it
local expect = JestGlobals.expect
local describe = JestGlobals.describe

local eventPropagationEvent = require(script.Parent.Parent.eventPropagationEvent)
local Event = eventPropagationEvent.Event

describe("EventPropagationEvent", function()
	it("should have the expected properties when instantiated", function()
		local targetInstance = Instance.new("Frame")
		local currentInstance = Instance.new("Frame")
		local eventName = "testEvent"
		local phase = "Bubble"
		local eventInfo = {}
		local event = Event.new(targetInstance, currentInstance, eventName, phase, eventInfo)
		local expected = expect.objectContaining({
			targetInstance = targetInstance,
			currentInstance = currentInstance,
			eventName = eventName,
			phase = phase,
			eventInfo = eventInfo,
            cancelled = false
		})
		expect(event).toEqual(expected)
	end)

    describe("when cancel is called", function()
        it("should have the cancelled property set to true", function()
            local targetInstance = Instance.new("Frame")
            local currentInstance = Instance.new("Frame")
            local eventName = "testEvent"
            local phase = "Bubble"
            local eventInfo = {}
            local event = Event.new(targetInstance, currentInstance, eventName, phase, eventInfo)
            event:cancel()
            local expected = expect.objectContaining({
                cancelled = true
            })
            expect(event).toEqual(expected)
        end)
    end)
end)

return {}
