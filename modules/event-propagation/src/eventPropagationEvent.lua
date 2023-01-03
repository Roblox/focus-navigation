--!strict
export type EventPhase = "Bubble" | "Capture" | "Target"

local Event = {}
Event.__index = Event

function Event.new(
	targetInstance: Instance,
	currentInstance: Instance,
	eventName: string,
	phase: EventPhase,
	eventInfo: any
)
	local self = {
		cancelled = false,
		phase = phase,
		currentInstance = currentInstance,
		targetInstance = targetInstance,
		eventName = eventName,
		eventInfo = eventInfo,
	}
	setmetatable(self, Event)
	return self
end

function Event:cancel()
	self.cancelled = true
end

export type Event = typeof(Event.new(Instance.new("Frame"), Instance.new("Frame"), "", "Bubble"))

local module = {}
module.Event = Event

return module
