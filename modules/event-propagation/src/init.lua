--!strict
-- Generator information:
-- Human name: EventPropagation
-- Variable name: EventPropagation
-- Repo name: focus-navigation

local Event = require(script.eventPropagationEvent)
local EventPropagationService = require(script.eventPropagationService)

export type EventPhase = Event.EventPhase
export type Event = Event.Event

export type EventHandler = EventPropagationService.EventHandler
export type EventHandlerMap = EventPropagationService.EventHandlerMap
export type EventPropagationService = EventPropagationService.EventPropagationService

return EventPropagationService
