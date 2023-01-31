# ReactFocusNavigation

## Hooks

### useEventMap
```lua
type useEventMap = (
  eventMap: FocusNavigation.EventMap,
  innerRef: React.Ref<GuiObject> | (node: React.Ref<GuiObject>) -> ()?
) -> (node: React.Ref<GuiObject>) -> ()
```
Allows a React component to register a FocusNavigationEventMap on the FocusNavigationService. Returns a ref that must be assigned to the host component that will be associated with the event map.

The `useEventMap` hook can optionally handle an inner ref, to which it will forward all updates. If you need to do something else with your ref in addition to assigning an event map, provide an inner ref.

When unmounting, changing the event map, or when the ref's value changes, the hook automatically handles de-registration and re-registration of the EventMap.

