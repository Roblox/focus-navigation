# Focus Navigation

The FocusNavigation package contains [Luau](https://luau.org/)-based helpers intended to support more complex directional navigation, like with a keyboard or gamepad, in a generic way.

## Types

### Events

FocusNavigation re-exports these event types from the [EventPropogation](../api-reference/event-propagation.md/) module:

- [EventPhase](event-propagation.md#eventphase)

- [Event](event-propagation.md#event)

- [EventHandler](event-propagation.md#event)

- [EventHandlerMap](event-propagation.md#event)

### EventMap

```lua
type EventMap = {
    [Enum.KeyCode]: string,
}
```

A mapping of input [KeyCodes](https://create.roblox.com/docs/reference/engine/enums/KeyCode) to event names. When an `EventMap` is registered on a `GuiObject` via `FocusNavigationService:registerEventMap`, the named events will be fired and propagated when the given input is observed.

### EventData

```lua
type EventData = {
    Delta: Vector3,
    KeyCode: Enum.KeyCode,
    Position: Vector3,
    UserInputState: Enum.UserInputState,
    UserInputType: Enum.UserInputType,
    wasProcessed: boolean?,
}
```

`EventData` is a combination of properties from the input [`InputObject`](https://create.roblox.com/docs/reference/engine/classes/InputObject) provided to the input event callback and other information related to the event. `EventData` is accessed through the `eventData` field of the [Event](event-propagation.md#event) passed to an [EventHandler](event-propagation.md#event).

### ContainerFocusBehavior

```lua
type ContainerFocusBehavior = {
    onDescendantFocusChanged: (GuiObject?) -> (),
    getTarget: () -> GuiObject?,
}
```

The `ContainerFocusBehavior` type represents a set of [FocusBehavior](../api-reference/focus-behaviors.md) rules that will be applied to a container `GuiObject`. The two functions are callbacks triggered by the `FocusNavigationService` to help redirect selection when a container gains focus.

This is useful for things like declaring a default descendant to be focused when a page gains focus, or tracking the most recently focused descendant and restoring it when returning from a modal.

#### onDescendantFocusChanged

```lua
function onDescendantFocusChanged(focusedDescendant: GuiObject?)
```

This function will be called any time focus changes within a given container. It can be used to track focus history within a container so that it can be restored in the future.

If the focus is redirected from its initial target, this callback will only be fired with the _most recent_ focus target, not the one that was redirected away from.

#### getTargets

```lua
function getTargets(): { GuiObject }
```

Returns an array of `GuiObject` candidates that should gain focus when focus moves from _outside_ of the container to _into_ it. This function's return dictates the initial or restored focus state that the `ContainerFocusBehavior` will redirect to. The `FocusNavigationService` will attempt to validate each member in the provided order, using [`isValidFocusTarget`](#isvalidfocustarget), and redirect focus to the first valid one. If the list is empty or no members are valid, focus will not be redirected.

## Package API

### FocusNavigationService

```lua
type FocusNavigationService = FocusNavigation.FocusNavigationService
```

Exports the [FocusNavigationService](../api-reference/focus-navigation.md/#service-api) object, which can be instantiated using the static [`new` function](#new) described below.

### EngineInterface

```lua
type EngineInterface = {
    CoreGui = FocusNavigation.EngineInterfaceType,
    PlayerGui = FocusNavigation.EngineInterfaceType,
}
```

Provides the two possible engine interface modes for the `FocusNavigationService`. These interfaces abstract over engine functionality that the `FocusNavigationService` needs to use under the hood, such as distinguishing between `GuiService.SelectedObject` and `GuiService.SelectedCoreObject`.

### isValidFocusTarget

```lua
function FocusNavigation.isValidFocusTarget(target: Instance?) -> (boolean, string?)
```

Returns a boolean representing whether or not the target is capable of receiving focus via Roblox engine selection (i.e. "Can GuiService.Selected(Core)Object be set to this value?").

If the function returns `false`, the second return value will contain an error string explaining why the `target` was not a valid focus target. This can be ignored or escalated as a warning or error message if needed.

## Service API

As mentioned above, the focus-navigation package exports `FocusNavigationService`, which is the workhorse of this library. It contains all the public methods which are used to build other focus utilities, like the ones in [react-focus-navigation](../api-reference/react-focus-navigation.md).

### new

```lua
function FocusNavigationService.new(engineInterface: FocusNavigation.EngineInterfaceType)
```

Create a new `FocusNavigationService`. Intended only to be called once. Provide the relevant [`EngineInterface`](#engineinterface) for the context:

- use `EngineInterface.CoreGui` to manage focus for UI mounted under the `CoreGui` service
- use `EngineInterface.PlayerGui` to manage focus for UI mounted under a Player instance's `PlayerGui` child

### registerEventMap

```lua
function FocusNavigationService:registerEventMap(
    guiObject: GuiObject,
    eventMap: EventMap,
)
```

Register a mapping of input [KeyCodes](https://create.roblox.com/docs/reference/engine/enums/KeyCode) to event names for a given `GuiObject`. Event names can be tied to event handlers with `registerEventHandler` or `registerEventHandlers`.

Using semantic event names means that inputs can have generalized meanings that apply contextually via handlers for various parts of the application.

### deregisterEventMap

```lua
function FocusNavigationService:deregisterEventMap(
    guiObject: GuiObject,
    eventMap: EventMap,
)
```

Deregister a set of event mappings for the given `GuiObject`.

### registerEventHandler

```lua
function FocusNavigationService:registerEventHandler(
    guiObject: GuiObject,
    eventName: string,
    eventHandler: EventHandler<FocusNavigationEventData>,
    phase: EventPhase?
)
```

Register an individual `EventHandler`. This requires a `GuiObject` (the event will only fire when that `GuiObject` is focused), the event handler itself, and the name of the event. The event's name will be meaningful within the context of the application. An `EventPhase` optionally can be passed in to indicate which event propagation phase the handler should be triggered in, this defaults to `"Bubble"`.

### registerEventHandlers

```lua
function FocusNavigationService:registerEventHandlers(
    guiObject: GuiObject,
    map: EventHandlerMap<FocusNavigationEventData>
)
```

Register multiple `EventHandler`s from an instance using an `EventHandlerMap`.

### deregisterEventHandler

```lua
function FocusNavigationService:deregisterEventHandler(
    guiObject: GuiObject,
    eventName: string,
    eventHandler: EventHandler<FocusNavigationEventData>,
    phase: EventPhase?
)
```

Deregister a single `EventHandler` from an `GuiObject` based on a phase. If phase is not passed in it defaults to `"Bubble"`.

### deregisterEventHandlers

```lua
function FocusNavigationService:deregisterEventHandlers(
    guiObject: GuiObject,
    map: EventHandlerMap<FocusNavigationEventData>
)
```

Deregister multiple `EventHandler`s from an instance using an `EventHandlerMap`.

### registerFocusBehavior

```lua
function FocusNavigationService:registerFocusBehavior(
    guiObject: GuiObject,
    containerFocusBehavior: ContainerFocusBehavior,
)
```

Register a [ContainerFocusBehavior](../api-reference/focus-navigation.md/#containerfocusbehavior) on the given `GuiObject` container. Whenever focus moves from _outside_ of that container to _inside_ of that container, the behavior will trigger and redirect focus if a new target is provided.

Additionally, the `onDescendantFocusChanged` callback on the provided behavior will be fired every time focus changes _to_ a descendant, either from outside the container, `nil` (nothing focused at all), or from another descendant inside the container. It will not be fired when focus moves _out_ of the container.

Only one behavior can be registered on a given container object, so registering a new behavior without deregistering the old one will overwrite the old one (and issue a warning in DEV mode). If multiple behaviors should be combined, use the [`composeFocusBehaviors`](focus-behaviors.md#composefocusbehaviors) utility to order them appropriately.

### deregisterEventHandler

```lua
function FocusNavigationService:deregisterFocusBehavior(
    guiObject: GuiObject,
    containerFocusBehavior: ContainerFocusBehavior,
)
```

Deregisters a [ContainerFocusBehavior](../api-reference/focus-navigation.md/#containerfocusbehavior) from a given `GuiObject` container. This means that no additional processing will occur when focus moves into the container, and focus will otherwise behave as dictated by the engine and any relevant `Instance` properties.

### focusGuiObject

```lua
function FocusNavigationService:focusGuiObject(
    guiObject: GuiObject,
    silent: boolean
)
```

Move focus to the target GuiObject. Providing a value of `true` for the `silent` argument will suppress event capturing and bubbling, triggering registered events only for the target guiObjects themselves (both the previous focus and the new one).

### Observable Fields

`FocusNavigationService` exposes two important observable properties.

#### activeEventMap

```lua
FocusNavigationService.activeEventMap: Signal<GuiObject?>
```

An observable property that provides the currently active mapping of input [KeyCodes](https://create.roblox.com/docs/reference/engine/enums/KeyCode) to focus navigation events. The active event map is composed from all events associated with the currently-focused `GuiObject` and its ancestors, where elements deeper in the tree will override events bound to their ancestors.

Subscribe to this value with a function as per the [Signal API](https://roblox.github.io/signal-lua-internal/api-reference/#types).

```lua
local subscription = FocusNavigation.activeEventMap:subscribe({
    next = function(evenMap)
        for keyCode, event in eventMap do
            print(string.format("trigger %s when pressing %s", event, tostring(keyCode))
        end
    end
})
```

#### focusedGuiObject

```lua
FocusNavigationService.focusedGuiObject: Signal<GuiObject?>
```

An observable property that tracks the currently focused instance. This is similar to connecting directly to the  `GuiService:GetPropertyChanged` signal for the relevant property, but provides a nicer interface and automatically connects to the right `GuiService` property.

Subscribe to this value with a function as per the [Signal API](https://roblox.github.io/signal-lua-internal/api-reference/#types).

```lua
local subscription = FocusNavigation.focusedGuiObject:subscribe({
    next = function(newFocus)
        print(if newFocus then newFocus.Name else "(None)")
    end
})
```

## Advanced Usage

For more advanced / systemic usage examples of the focus-navigation module, check out the focus navigation [DemoApp](https://github.com/Roblox/focus-navigation/tree/main/modules/demo-app) in this library's GitHub repo.
