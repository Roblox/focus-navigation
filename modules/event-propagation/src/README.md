# EventPropagationService

The EventPropagationService is currently an implementation detail of the FocusNavigationService. It is primarily responsible for functionality related to propagating events registered and triggered by the consumer.

## Types

### EventPhase
```lua
type EventPhase = "Bubble" | "Capture" | "Target"
```
The EventPhase represents the phase of the event propagation cycle a given EventHandler should be registered to be called in.

*Capture* - The initial phase of event propagation. EventHandlers registered in this phase are called in order from the furthest ancestor of the target to the target itself.

*Target* - The second phase of event propagation. EventHandlers registered in this phase are called after the capture phase, and are only called when registered to the instance that the event is propagated from.

*Bubble* - This is the default phase that EventHandlers are registered to. EventHandlers registered in this phase are called in order from the target instance to the targets furthest ancestor.


### Event
```lua
type Event = {
    cancelled: boolean,
    phase: EventPhase,
    currentInstance: Instance,
    targetInstance: Instance,
    eventName: string,
    eventInfo: any,
    cancel: () -> ()
}
```
`Event`s are passed to `EventHandler`s with the appropriate information when the `EventHandler` is called during event propagation. Note that each `EventHandler` is called with it's own `Event`, mutations to the Event will not be picked up by subsequent handlers.

### EventHandler
```lua
type EventHandler = (e: Event) -> ()
```
`EventHandler`s are simple functions that take an event as an argument, and return nothing.

### EventHandlerMap
```lua
type EventHandlerMap = {
	[string]: {
		handler: EventHandler,
		phase: EventPhase?,
	},
}
```
An `EventHandlerMap` gets used to register an `EventHandler` to an event in a given phase (or `"Bubble"` if ommitted). The keys of the map are the names of the events that will be used when `EventPropagationService:propagateEvent` is called.

## API

### new

```lua
EventPropagationService.new()
```
Create a new `EventPropagationService`. Intended only to be called once.

### registerEventHandler

```lua
EventPropagationService:registerEventHandler(
    instance: Instance,
    eventName: string,
    eventHandler: EventHandler,
    phase: EventPhase?
)
```
Register an individual `EventHandler`, it requires an `Instance` to tie the handler to, the event handler itself, and the name of the event, which should be meaningful within the context of the application. An `EventPhase` optionally can be passed in to indicate which event propagation phase the handler should be triggered in, this defaults to `"Bubble"`.

### registerEventHandlers

```lua
EventPropagationService:registerEventHandlers(
    instance: Instance,
    map: EventHandlerMap
)
```
Register a map of `EventHandler`s using an `EventHandlerMap`.

### eRegisterEventHandler
```lua
EventPropagationService:deRegisterEventHandler(
    instance: Instance,
    eventName: string,
    phase: EventPhase?
)
```
De-register a single `EventHandler` from an `Instance` based on a phase. If phase is not passed in it defaults to `"Bubble"`.

### deRegisterEventHandlers
```lua
EventPropagationService:deRegisterEventHandlers(instance: Instance)
```
De-register all `EventHandler`s from an `Instance`, regardless of phase.

### propagateEvent
```lua
EventPropagationService:propagateEvent(
    instance: Instance,
    eventName: string,
    eventInfo: any,
    silent: boolean
)
```
Propagate an event on a given `Instance` by name. Optionally the event can be propagated with some additional information which will be available to all handlers that pick up the event. Additionally the event can be propagated in `silent` mode which will only call `EventHandler`s on the specified instance. behind the scenes it creates a list of ancestors with relevant registered eventHandlers is created. The list is then looped over from furthest ancestor to the target, calling all eventHandlers that are registered for the capture phase, the event handler for the target phase on the focused GuiObject is called, then the list is looped over from the target to the furthest ancestor to call all of the eventHandlers registered for the bubble phase. So in essence the phase order is Capture → Target → Bubble. It should be noted that the target phase is special in that the only handler that runs during the target phase is the handler on the currently focused element. These phases and their meaning are based on those from the Web API for event propagation. 