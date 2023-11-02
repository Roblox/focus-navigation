# ReactFocusNavigation

## FocusNavigation

### FocusNavigationService
```lua
type FocusNavigationService = FocusNavigation.FocusNavigationService
```
Re-exports the `FocusNavigationService` [from the focus-navigation package](../focus-navigation/README.md#focusnavigationservice).

### EngineInterface
```lua
type EngineInterface = FocusNavigation.EngineInterface
```
Re-exports the `EngineInterface` [from the focus-navigation package](../focus-navigation/README.md#engineinterface).

## Context

### FocusNavigationContext
```lua
type FocusNavigationContext = React.Context<FocusNavigation.FocusNavigationService?>
```
A context object to use for providing and consuming a `FocusNavigationService` instance.

Use `FocusNavigationContext.Provider` to include a `FocusNavigationService` instance in a React tree:
```lua
local focusNav = FocusNavigationService.new(EngineInterface.CoreGui)

React.createElement(FocusNavigationContext.Provider, {
  value = focusNav
}, children)
```

You should generally only need to consume the context-provided `FocusNavigationService` via the [hooks](#hooks) provided with this library. However, you can also use `FocusNavigationContext.Consumer` or `React.useContext(FocusNavigationContext)` if you need direct access to the `FocusNavigationService`.

## Hooks

### useEventMap
```lua
type useEventMap = (
  eventMap: FocusNavigation.EventMap,
  innerRef: React.Ref<GuiObject>?
) -> React.Ref<GuiObject>
```
Allows a React component to register an EventMap on the FocusNavigationService. Returns a ref that must be assigned to the host component that will be associated with the event map.

The `useEventMap` hook can optionally handle an inner ref, to which it will forward all updates. If you need to do something else with your ref in addition to assigning an event map, provide an inner ref.

When unmounting, changing the event map, or when the ref's value changes, the hook automatically handles de-registration and re-registration of the EventMap.

### useEventHandlerMap
```lua
type useEventHandlerMap = (
  eventHandlerMap: FocusNavigation.EventHandlerMap,
  innerRef: React.Ref<GuiObject>?
) -> React.Ref<GuiObject>
```
Allows a React component to register an EventHandlerMap on the FocusNavigationService. Returns a ref that must be assigned to the host component that will be associated with the event map.

The `useEventHandlerMap` hook can optionally handle an inner ref, to which it will forward all updates. If you need to do something else with your ref in addition to assigning an event map, provide an inner ref.

When unmounting, changing the event handler map, or when the ref's value changes, the hook automatically handles de-registration and re-registration of the EventHandlerMap.

### useEventHandler
```lua
type useEventHandler = (
  eventName: string,
  eventHandler: FocusNavigation.EventHandler,
  phase: FocusNavigation.EventPhase?,
  innerRef: React.Ref<GuiObject>?
) -> React.Ref<GuiObject>
```
Allows a React component to register an EventHandler on the FocusNavigationService. Returns a ref that must be assigned to the host component that will be associated with the event map.

The `useEventHandler` hook can optionally handle an inner ref, to which it will forward all updates. If you need to do something else with your ref in addition to assigning an event map, provide an inner ref.

When unmounting, changing the provided event handler data, or when the ref's value changes, the hook automatically handles de-registration and re-registration of the EventHandlerMap.

### useActiveEventMap
```lua
type useActiveEventMap = () -> FocusNavigation.EventMap
```
Returns a `FocusNavigation.EventMap` that describes the current active EventMap. The active EventMap describes all currently-bound events based on which GUI elements are focused, and what events are registered to it and its ancestors. Events bound to the same input as an ancestor will override the ancestor's bindings to those inputs.

### useFocusedGuiObject
```lua
type useFocusedGuiObject = () -> GuiObject?
```
Returns the currently-focused `GuiObject` via the `FocusNavigationService.focusedGuiObject` observable property. This hook triggers an update each time the focus changes.

### useLastInputMethod
```lua
type InputMethod = "Keyboard" | "Mouse" | "Gamepad" | "Touch" | "None"
type useLastInputMethod = () -> InputMethod
```
Returns a string representing the kind of input events that were last processed. This is useful for determining what to show in on-screen button-mapping hints, and may indicate whether or not focus should be hidden.

The "last input method" concept is a layer of reduction over the `UserInputService:GetLastInputType()` function, which returns an [`Enum.UserInputType`](https://create.roblox.com/docs/reference/engine/enums/UserInputType).

Inputs from the `UserInputType` enum are simplified to "Keyboard", "Mouse", "Gamepad", and "Touch" as follows:
| Enum Member | Maps To | Notes |
|--|--|--|
|MouseButton1..3|Mouse||
|MouseWheel|Mouse||
|MouseMovement|Mouse||
|Touch|Touch||
|Keyboard|Keyboard||
|Focus|_(ignored)_|Focusing the window can happen all sorts of ways, and shouldn't trigger a change to input method|
|Accelerometer|_(ignored)_|Accelerometer events shouldn't change input method|
|Gyro|_(ignored)_|Gyro events shouldn't change input method|
|Gamepad1..8|Gamepad||
|TextInput|_(ignored)_|Text input can come from various kinds of onscreen keyboards and fire at odd times when using other inputs, so we assume that they're superseded by other events and ignore them|
|InputMethod|_(ignored)_|This is sort of a meta input change, not a real change to the input method that's in use|
|None|_(ignored)_|Unknown inputs can be ignored for better clarity and resilience|

The "None" value is only used when the initial value does not map to one of the other four.

### useLastInputMode
```lua
type InputMode = "Focus" | "Cursor" | "None"
type useLastInputMode = () -> InputMode
```
Returns a string representing the kind of input modes that were last processed. It further digests the last input method and maps it to a more specific input mode. 
| Input Method | Maps To |
|--|--|
|Mouse|Cursor|
|Touch|Cursor|
|Keyboard|Focus|
|Gampad|Focus|
|None|None|

The "None" value is only used when the initial value is unknown.

### useFocusGuiObject
```lua
type FocusGuiObject = (GuiObject | nil) -> ()
type useFocusGuiObject = () -> FocusGuiObject
```
Returns a function that can be used for imperatively capturing focus. This is useful for adapting focus management to other complexities of application UI, including animations and app navigation transitions. Call this function with a `GuiObject` or an object ref to move focus to the target or one of its `Selectable` descendants.

You can also call this function with `nil` to unfocus the UI entirely. You may want to do this in response to inputs from non-gamepad peripherals.

### useContainerFocusBehavior
```lua
type useContainerFocusBehavior = (behavior: ContainerFocusBehavior, innerRef: React.Ref?) -> React.Ref
```
A hook responsible for providing the desired behavior for redirecting focus within a container. There are two general scenarios in which the assigned focus behavior will redirect focus:
* The container to which it is bound gains focus for the first time
* The container to which it is bound regains focus after navigating away and back

In these cases, a “container” typically refers to a screen within a RoactNavigation navigator, but could also be applied to a group of related buttons, an overlay, or any other group of elements that interact with focus.

### useDefaultFocusBehavior
```lua
type useDefaultFocusBehavior = () -> (defaultRef: React.Ref<Instance?>, containerRef: React.Ref<Instance?>)
```
Returns a `defaultRef` value to be assigned to the default focus target and a containerRef to be assigned to the container that will redirect focus to the default.

### useMostRecentFocusBehavior
```lua
type useMostRecentFocusBehavior = () -> containerRef: React.Ref<Instance?>
```
Returns a `containerRef` to be assigned to the container that will redirect focus to its last focused descendant.

### useMostRecentOrDefaultFocusBehavior
```lua
type useMostRecentOrDefaultFocusBehavior = () -> (defaultRef: React.Ref<Instance?>, containerRef: React.Ref<Instance?>)
```
Composes the above two behaviors, such that previous selection is restored with an assigned default as a fallback. Returns a `defaultRef` value to be assigned to the default focus target and a containerRef to be assigned to the container that will redirect focus.

If a valid last-focused descendant exists when refocusing, it will be redirected to, using [`isValidFocusTarget`](../focus-navigation/README.md#isvalidfocustarget) to determine validity. If no valid targets are found, the default will be used.
