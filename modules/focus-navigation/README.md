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

## Top-Level API

### FocusNavigationService

```lua
type FocusNavigationService = FocusNavigation.FocusNavigationService
```
Exports the FocusNavigationService object, which can be instantiated using the static [`new` function](#new) described below.

### EngineInterface

```lua
type EngineInterface = {
    CoreGui = FocusNavigation.EngineInterfaceType,
    PlayerGui = FocusNavigation.EngineInterfaceType,
}
```
Provides the two possible engine interface modes for the `FocusNavigationService`. These interfaces abstract over engine functionality that the `FocusNavigationService` needs to use under the hood, such as distinguishing between `GuiService.SelectedObject` and `GuiService.SelectedCoreObject`.

## FocusNavigationService API

### new

```lua
FocusNavigationService.new(engineInterface: FocusNavigation.EngineInterfaceType)
```
Create a new `FocusNavigationService`. Intended only to be called once. Provide the relevant [`EngineInterface`](#engineinterface) for the context:
* use `EngineInterface.CoreGui` to manage focus for UI mounted under the `CoreGui` service
* use `EngineInterface.PlayerGui` to manage focus for UI mounted under a Player instance's `PlayerGui` child

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
The `FocusNavigationService` also exposes observable properties 

#### activeEventMap
```lua
FocusNavigationService.activeEventMap: Observable<GuiObject?>
```

An observable property that provides the currently active mapping of input KeyCodes to focus navigation events. The active event map is composed from all events associated with the currently-focused `GuiObject` and its ancestors, where elements deeper in the tree will override events bound to their ancestors.

Subscribe to this value with an Observer object as per the [ZenObservable API](https://github.com/zenparsing/zen-observable#observablesubscribeobserver).
```lua
local subscription = FocusNavigation.activeEventMap:subscribe({
    next = function(evenMap)
        for keyCode, event in eventMap do
            print(string.format("trigger %s when pressing %s", event, tostring(keyCode))
        end
    end
})
```

#### focusedInstance
```lua
FocusNavigationService.focusedInstance: Observable<GuiObject?>
```

An observable property that tracks the currently focused instance. This is similar to connecting directly to the  `GuiService:GetPropertyChanged` signal for the relevant property, but provides a nicer interface and automatically connects to the right `GuiService` property.

Subscribe to this value with an Observer object as per the [ZenObservable API](https://github.com/zenparsing/zen-observable#observablesubscribeobserver).
```lua
local subscription = FocusNavigation.focusedInstance:subscribe({
    next = function(newFocus)
        print(if newFocus then newFocus.Name else "(None)")
    end
})
```

## Usage
🛠 *Under construction* 🛠
