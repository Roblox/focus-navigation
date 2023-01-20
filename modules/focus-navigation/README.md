# FocusNavigationService

The EventPropagationService is currently an implementation detail of the FocusNavigationService. It is primarily responsible for functionality related to propagating events registered and triggered by the consumer.

## Types

### EventPhase
```lua
type EventPhase = "Bubble" | "Capture" | "Target"
```
Re-exported from the [EventPropagation module](../event-propagation/src/README.md#eventphase).

### Event
```lua
type Event<T> = {
    cancelled: boolean,
    phase: EventPhase,
    currentInstance: Instance,
    targetInstance: Instance,
    eventName: string,
    eventData: T,
    cancel: () -> ()
}
```
Re-exported from the [EventPropagation module](../event-propagation/src/README.md#event).

### EventHandler
```lua
type EventHandler<T> = (e: Event<T>) -> ()
```
Re-exported from the [EventPropagation module](../event-propagation/src/README.md#eventhandler).

### EventHandlerMap
```lua
type EventHandlerMap<T> = {
	[string]: {
		handler: EventHandler<T>,
		phase: EventPhase?,
	},
}
```
Re-exported from the [EventPropagation module](../event-propagation/src/README.md#eventhandlermap).

### EventMap
```lua
type EventMap = {
	[Enum.KeyCode]: string,
}
```
A mapping of input KeyCodes to event names. When an `EventMap` is registered on a `GuiObject` via `FocusNavigationService:registerEventMap`, the named events will be fired and propagated when the given input is observed.

Data on the [`InputObject`](https://create.roblox.com/docs/reference/engine/classes/InputObject) provided to the input event callback will be copied into the `eventData` field of the `Event` passed to the handler.

## API

### new

```lua
FocusNavigationService.new()
```
Create a new `FocusNavigationService`. Intended only to be called once.

### registerEventMap

```lua
FocusNavigationService:registerEventMap(
    guiObject: GuiObject,
    eventMap: EventMap,
)
```
Register a mapping of input KeyCodes to event names for a given `GuiObject`. Event names can be tied to event handlers with `registerEventHandler` or `registerEventHandlers`.

Using semantic event names means that inputs can have generalized meanings that apply contextually via handlers for various parts of the application.

### deregisterEventMap

```lua
FocusNavigationService:deregisterEventMap(
    guiObject: GuiObject,
    eventMap: EventMap,
)
```
Deregister a set of event mappings for the given `GuiObject`.

### registerEventHandler

```lua
FocusNavigationService:registerEventHandler(
    guiObject: GuiObject,
    eventName: string,
    eventHandler: EventHandler,
    phase: EventPhase?
)
```
Register an individual `EventHandler`. This requires a `GuiObject` (the event will only fire when that `GuiObject` is focused), the event handler itself, and the name of the event. The event's name will be meaningful within the context of the application. An `EventPhase` optionally can be passed in to indicate which event propagation phase the handler should be triggered in, this defaults to `"Bubble"`.

### registerEventHandlers

```lua
FocusNavigationService:registerEventHandlers(
    guiObject: GuiObject,
    map: EventHandlerMap
)
```
Register multiple `EventHandler`s from an instance using an `EventHandlerMap`.

### deRegisterEventHandler
```lua
FocusNavigationService:deRegisterEventHandler(
    guiObject: GuiObject,
    eventName: string,
    eventHandler: EventHandler,
    phase: EventPhase?
)
```
De-register a single `EventHandler` from an `GuiObject` based on a phase. If phase is not passed in it defaults to `"Bubble"`.

### deRegisterEventHandlers
```lua
FocusNavigationService:deRegisterEventHandlers(
    guiObject: GuiObject,
    map: EventHandlerMap
)
```
De-register multiple `EventHandler`s from an instance using an `EventHandlerMap`.

### focusGuiObject
```lua
FocusNavigationService:focusGuiObject(
    guiObject: GuiObject,
    silent: boolean
)
```
Move focus to the target GuiObject. Providing a value of `true` for the `silent` argument will suppress event capturing and bubbling, triggering registered events only for the target guiObjects themselves (both the previous focus and the new one).

### Observable Fields
🛠 *Under construction* 🛠

#### activeInputDevice

#### activeEventMap

#### focusedInstance

## Usage
🛠 *Under construction* 🛠
