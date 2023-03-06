# ReactFocusNavigation

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

### useCaptureFocus
```lua
type CaptureFocus = (React.Ref<GuiObject?> | GuiObject | nil) -> ()
type useCaptureFocus = () -> CaptureFocus
```
Returns a function that can be used for imperatively capturing focus. This is useful for adapting focus management to other complexities of application UI, including animations and app navigation transitions. Call this function with a `GuiObject` or an object ref to move focus to the target or one of its `Selectable` descendants.

You can also call this function with `nil` to unfocus the UI entirely. You may want to do this in response to inputs from non-gamepad peripherals.
