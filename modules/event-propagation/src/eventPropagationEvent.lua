--!strict
export type EventPhase = "Bubble" | "Capture" | "Target"

local Event = {}
Event.__index = Event

function Event.new(targetInstance: Instance, currentInstance: Instance, eventName: string, phase: EventPhase)
	local self = {
		cancelled = false,
		phase = phase,
		currentInstance = currentInstance,
		targetInstance = targetInstance,
		eventName = eventName,
	}
	setmetatable(self, Event)
	return self
end

function Event:cancel()
	self.cancelled = true
end

export type Event = typeof(Event.new(Instance.new("Frame"), Instance.new("Frame"), "", "Bubble"))

return Event
