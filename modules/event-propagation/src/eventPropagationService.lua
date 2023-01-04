--!strict
local eventPropagationEvent = require(script.Parent.eventPropagationEvent)
local Event = eventPropagationEvent
type EventPhase = eventPropagationEvent.EventPhase
type Event = eventPropagationEvent.Event

export type EventHandler = (e: Event) -> ()

export type EventHandlerMap = {
	[string]: {
		handler: EventHandler,
		phase: EventPhase?,
	},
}

type EventHandlerRegistry = {
	[Instance]: {
		[string]: {
			[EventPhase]: EventHandler?,
		}?,
	}?,
}

local DEFAULT_PHASE: EventPhase = "Bubble"

local function getAncestors(instance: Instance)
	local ancestors = { instance }
	while ancestors[#ancestors].Parent do
		table.insert(ancestors, ancestors[#ancestors].Parent :: Instance)
	end
	return ancestors
end

local function getEventsFromRegistry(registry: EventHandlerRegistry, instance: Instance)
	return registry[instance]
end

local function getEventPhasesFromRegistry(registry: EventHandlerRegistry, instance: Instance, eventName: string)
	local events = getEventsFromRegistry(registry, instance)
	return if events then events[eventName] else nil
end

local function getEventHandler(registry: EventHandlerRegistry, instance: Instance, eventName: string, phase: EventPhase)
	local eventPhases = getEventPhasesFromRegistry(registry, instance, eventName)
	return if eventPhases then eventPhases[phase] else nil
end

local EventPropagationService = {}
EventPropagationService.__index = EventPropagationService

function EventPropagationService:registerEventHandler(
	instance: Instance,
	eventName: string,
	eventHandler: EventHandler,
	phase: EventPhase?
)
	local resolvedPhase: EventPhase = phase or DEFAULT_PHASE
	self.eventHandlerRegistry[instance] = self.eventHandlerRegistry[instance] or {}
	self.eventHandlerRegistry[instance][eventName] = self.eventHandlerRegistry[instance][eventName] or {}
	self.eventHandlerRegistry[instance][eventName][resolvedPhase] = eventHandler
end

function EventPropagationService:registerEventHandlers(instance: Instance, map: EventHandlerMap)
	if not self.eventHandlerRegistry[instance] then
		self.eventHandlerRegistry[instance] = {}
	end
	for eventName, v in pairs(map) do
		self:registerEventHandler(instance, eventName, v.handler, v.phase)
	end
end

function EventPropagationService:deRegisterEventHandlers(instance: Instance)
	self.eventHandlerRegistry[instance] = nil
end

function EventPropagationService:deRegisterEventHandler(instance: Instance, eventName: string, phase: EventPhase?)
	local resolvedPhase: EventPhase = phase or DEFAULT_PHASE
	local eventPhases = getEventPhasesFromRegistry(self.eventHandlerRegistry, instance, eventName)
	if eventPhases and eventPhases[resolvedPhase] then
		eventPhases[resolvedPhase] = nil
	end
end

function EventPropagationService:propagateEvent(instance: Instance, eventName: string, silent: boolean)
	local function runEventHandler(currentAncestor: Instance, phase: EventPhase)
		local eventHandler = getEventHandler(self.eventHandlerRegistry, currentAncestor, eventName, phase)
		if eventHandler then
			local event = Event.new(instance, currentAncestor, eventName, phase)
			eventHandler(event)
			return event.cancelled
		end
		return false
	end
	local cancelled = false
	local ancestors: {[number]: Instance} = if silent then { instance } else getAncestors(instance)
	for i = #ancestors, 1, -1 do
		local ancestor = ancestors[i]
		cancelled = runEventHandler(ancestor, "Capture")
		if cancelled then
			return
		end
	end
	cancelled = runEventHandler(instance, "Target")
	if cancelled then
		return
	end
	for i = 1, #ancestors do
		local ancestor = ancestors[i]
		cancelled = runEventHandler(ancestor, "Bubble")
		if cancelled then
			return
		end
	end
end

function EventPropagationService.new()
	local eventHandlerRegistry = {}
	eventHandlerRegistry.__mode = "k"

	local self = {
		eventHandlerRegistry = eventHandlerRegistry,
	}
	setmetatable(self, EventPropagationService)
	return self
end

export type EventPropagationService = typeof(EventPropagationService.new())

return EventPropagationService
