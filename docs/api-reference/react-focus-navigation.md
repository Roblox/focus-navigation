## React Focus Navigation

A library for handling UI interactions with directional input, like gamepad or keyboard, in React applications. This is intended to be the primary API surface for the `focus-navigation` workspace.

## Re-Exported

### FocusNavigationService

```lua
type FocusNavigationService = FocusNavigation.FocusNavigationService
```

Re-exports the [FocusNavigationService](../api-reference/focus-navigation.md#focusnavigationservice) from `FocusNavigation`.

### EngineInterface

```lua
type EngineInterface = FocusNavigation.EngineInterface
```

Re-exports the [EngineInterface](../api-reference/focus-navigation.md#engineinterface) from `FocusNavigation`.

## Context

### FocusNavigationContext

```lua
type FocusNavigationContext = React.Context<FocusNavigation.FocusNavigationService?>
```

A [context](https://react.dev/learn/passing-data-deeply-with-context) object to use for providing and consuming a [FocusNavigationService](../api-reference/focus-navigation.md#focusnavigationservice) instance.

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
function useEventMap(
  eventMap: FocusNavigation.EventMap,
  innerRef: React.Ref<GuiObject>?
): React.Ref<GuiObject>
```

Allows a React component to register an [EventMap](../api-reference/focus-navigation.md/#eventmap) on the [FocusNavigationService](../api-reference/focus-navigation.md#focusnavigationservice). Returns a ref that must be assigned to the host component that will be associated with the event map.

The `useEventMap` hook can optionally handle an inner ref, to which it will forward all updates. If you need to do something else with your ref in addition to assigning an event map, provide an inner ref.

When unmounting, changing the event map, or when the ref's value changes, the hook automatically handles de-registration and re-registration of the EventMap.

!!! Warning
    If you would like to compose the refs created by `useEventMap` and `useEventHandlerMap`, `useEventMap`'s ref should be used as the `innerRef` for `useEventHandlerMap` rather than the other way around.

<details><summary>Sample Code</summary>

```lua
local EVENT_MAP: EventMap = {
 [Enum.KeyCode.ButtonX] = "ToggleItemDetails",
 [Enum.KeyCode.ButtonY] = "SearchInventory",
 [Enum.KeyCode.ButtonR1] = "ViewNextItem",
 [Enum.KeyCode.ButtonL1] = "ViewPreviousItem",
}

local TestComponent = function(props)
  local eventMapRef = useEventMap(EVENT_MAP)

  -- Let's assume we receive our event handlers as a map from a parent component
  local eventHandlerMapRef = useEventHandlerMap(props.eventHandlers)

  return React.createElement("Frame", {
    Size = UDim2.fromScale(1, 1),
    ref = eventMapRef,
  }, {
    ItemInventoryContainer = React.createElement("Frame", {
      Size = UDim2.fromScale(0.5, 0.5),
      Position = UDim2.fromScale(0.5, 0.5),
      AnchorPoint = Vector2.new(0.5, 0.5),
      ref = eventHandlerMapRef,
    }, {
      -- Pretend there are multiple selectable elements here
    }),
  })
end
```

In this example, whenever focus is within ItemInventoryContainer, if a user presses one of the keys mapped in EVENT_MAP, any handler from props.eventHandlers that was mapped to the corresponding event name will be triggered.

</details>

### useEventHandlerMap

```lua
function useEventHandlerMap(
  eventHandlerMap: FocusNavigation.EventHandlerMap,
  innerRef: React.Ref<GuiObject>?
): React.Ref<GuiObject>
```

Allows a React component to register an [EventHandlerMap](../api-reference/event-propagation.md/#eventhandlermap) on the [FocusNavigationService](../api-reference/focus-navigation.md#focusnavigationservice). Returns a ref that must be assigned to the host component that will be associated with the event map.

The `useEventHandlerMap` hook can optionally handle an inner ref, to which it will forward all updates. If you need to do something else with your ref in addition to assigning an event map, provide an inner ref.

When unmounting, changing the event handler map, or when the ref's value changes, the hook automatically handles de-registration and re-registration of the EventHandlerMap.

!!! Info
    Event handler callbacks **MUST** be created using `InputHandler`s. Like all callbacks, these functions should be declared in a static or memoized location, as they will otherwise be recreated during render cycles, which can cause them to miss events or lose input state.

<details><summary>Sample Code</summary>

```lua
local TestComponent = function(props)
  -- Event handlers should always be memoized so that event state is not lost between renders
  local eventHandlerMap = React.useMemo(function()
    local map = {}

    map["HideItemDetails"] = InputHandlers.OnRelease(function()
      props.onHideDetails()
    end)

    map["SearchInventory"] = InputHandlers.OnRelease(function()
      props.onSearchInventory()
    end)

    map["ToggleMenu"] = InputHandlers.OnRelease(function()
      props.onToggleMenu()
    end)

    return map
  end, {})


  local eventHandlerRef = useEventHandlerMap(eventHandlerMap)

  return React.createElement("Frame", {
    Size = UDim2.fromScale(1, 1),
    ref = eventHandlerMapRef,
  }, {
    -- Pretend there are multiple selectable elements here
  })
end
```

In this example, whenever focus is within TestComponent's Frame, if the user presses any key that eventHandlerMap maps to event names in the current ActiveEventMap, the callback within the event's corresponding handler will be triggered.

</details>

### useEventHandler

```lua
function useEventHandler(
  eventName: string,
  eventHandler: FocusNavigation.EventHandler,
  phase: FocusNavigation.EventPhase?,
  innerRef: React.Ref<GuiObject>?
): React.Ref<GuiObject>
```

Allows a React component to register an [EventHandler](../api-reference/event-propagation.md/#eventhandler) on the [FocusNavigationService](../api-reference/focus-navigation.md#focusnavigationservice). Returns a ref that must be assigned to the host component that will be associated with the event map.

The `useEventHandler` hook can optionally handle an inner ref, to which it will forward all updates. If you need to do something else with your ref in addition to assigning an event map, provide an inner ref.

When unmounting, changing the provided event handler data, or when the ref's value changes, the hook automatically handles de-registration and re-registration of the EventHandlerMap.

!!! Info
    Event handler callbacks **MUST** be created using `InputHandler`s. Like all callbacks, these functions should be declared in a static or memoized location, as they will otherwise be recreated during render cycles, which can cause them to miss events or lose input state.

<details><summary>Sample Code</summary>

```lua
local TestComponent = function(props)
  -- The event handler should always be memoized so that event state is not lost between renders
  local eventHandler = React.useMemo(function()
    return InputHandlers.OnRelease(function()
      props.onCloseMenu()
    end)
  end, {})

  local eventHandlerRef = useEventHandler("CloseMenu", eventHandler)

  return React.createElement("Frame", {
    Size = UDim2.fromScale(1, 1),
    ref = eventHandlerRef,
  }, {
    -- Pretend there are multiple selectable elements here
  })
end
```

In this example, whenever focus is within TestComponent's Frame, if the user presses any key mapped to the "CloseMenu" action in the current ActiveEventMap, the callback within our eventHandler will be triggered.

</details>

### useActiveEventMap

```lua
function useActiveEventMap(): FocusNavigation.EventMap
```

Returns an [EventMap](../api-reference/focus-navigation.md/#eventmap) that describes the current active `EventMap`. The active EventMap describes all currently-bound events based on which GUI elements are focused, and what events are registered to it and its ancestors. Events bound to the same input that an ancestor is will override the ancestor's bindings to those inputs.

<details><summary>Sample Code</summary>

```lua
local KEYCODE_FILTER = { Enum.KeyCode.Escape, Enum.KeyCode.Tab }

local useFilteredActiveEvents = function()
  local activeEventMap = useActiveEventMap()
  local filteredEventMap = {}

  for _, keyCode in KEYCODE_FILTER do
    local eventName = activeEventMap[keyCode]
    filteredEventMap[keyCode] = eventName
  end

  return filteredEventMap
end
```

This hook reads the active event map and then filters the available actions for events that correspond to certain [KeyCodes](https://create.roblox.com/docs/reference/engine/enums/KeyCode).

This could be used to, for example, determine which icons to display in a shortcut bar which only wants to render a subset of the currently active key binds.
</details>

### useFocusedGuiObject

```lua
function useFocusedGuiObject(): GuiObject?
```

Returns the currently-focused `GuiObject` via `FocusNavigationService`'s [focusedGuiObject](../api-reference/focus-navigation.md/#focusedguiobject) observable property. This hook triggers an update each time the focus changes.

See [useFocusGuiObject](../api-reference/react-focus-navigation.md/#usefocusguiobject)'s code sample for usage.

### useFocusGuiObject

```lua
type FocusGuiObject = (GuiObject | nil) -> ()
function useFocusGuiObject(): FocusGuiObject
```

Returns a function that can be used for imperatively capturing focus. This is useful for adapting focus management to other complexities of application UI, including animations and app navigation transitions. Call this function with a `GuiObject` or an object ref to move focus to the target or one of its `Selectable` descendants.

You can also call this function with `nil` to unfocus the UI entirely. You may want to do this in response to inputs that are not directional, like touch or mouse input.

<details><summary>Sample Code</summary>

```lua
local UserInputService = game:GetService("UserInputService")
local React = require(Packages.React)

function useToggleFocusOnTap(object)
  local focusGuiObject = useFocusGuiObject()
  local currentlyFocused = useFocusedGuiObject()

  React.useEffect(function()
    local tapConnection = UserInputService.TouchTap:Connect(function(position, gameProcessedEvent)
      if currentlyFocused == nil then
        focusGuiObject(object)
      else
        focusGuiObject(nil)
      end
    end)

    return function()
      tapConnection:Disconnect()
    end
  end, {})
end
```

This hook toggles focus on and off a provided GuiObject every time a mobile user taps their screen.
</details>

### useContainerFocusBehavior

```lua
function useContainerFocusBehavior(behavior: ContainerFocusBehavior, innerRef: React.Ref?): React.Ref
```

A hook responsible for providing the desired behavior for redirecting focus within a container. There are two general scenarios in which the assigned focus behavior will redirect focus:

* The container to which it is bound gains focus for the first time
* The container to which it is bound regains focus after navigating away and back

For more information on these behaviors and what is defined as "containers", see [FocusBehaviors](../api-reference/focus-behaviors.md).

### useDefaultFocusBehavior

```lua
function useDefaultFocusBehavior(): (defaultRef: React.Ref<Instance?>, containerRef: React.Ref<Instance?>)
```

Returns a `defaultRef` which can be assigned to the `GuiObject` that focus should default to when selection enters the container, which is similarly defined by assigning `containerRef` to another `GuiObject`. The element which `defaultRef` is assigned to should be a descendant of the element which `containerRef` is assigned to.

See [default](../api-reference/focus-behaviors.md/#default) from [FocusBehavior](../api-reference/focus-behaviors.md).

<details><summary>Sample Code</summary>

```lua
function DefaultTestComponent(props)
  local defaultRef, containerRef = useDefaultFocusBehavior()

  return React.createElement("Frame", {
    Size = UDim2.fromScale(1, 1),
    ref = containerRef,
  }, {
    DecoyButton = React.createElement("TextButton", {
      Text = "I will NOT be selected when selection enters this frame!",
    }),
    DefaultButton = React.createElement("TextButton", {
      Text = "I will be selected when selection enters this frame!",
      ref = defaultRef,
    }),
  })
end
```

</details>

### useMostRecentFocusBehavior

```lua
function useMostRecentFocusBehavior(): containerRef: React.Ref<Instance?>
```

Returns a `containerRef` to be assigned to the `GuiObject` that will redirect focus to its most recently focused descendant. This has no effect the first time focus enters the container.

See [mostRecent](../api-reference/focus-behaviors.md/#mostrecent) from [FocusBehavior](../api-reference/focus-behaviors.md).

<details><summary>Sample Code</summary>

```lua
function MostRecentTestComponent(props)
  local containerRef = useMostRecentFocusBehavior()

  return React.createElement("Frame", {
    Size = UDim2.fromScale(1, 1),
    ref = containerRef,
  }, {
    Button1 = React.createElement("TextButton", {
      Text = "",
    }),
    Button2 = React.createElement("TextButton", {
      Text = "",
    }),
    Button2 = React.createElement("TextButton", {
      Text = "",
    }),
  })
end
```

If the user moves focus to any of the buttons within Frame, moves their selection to another element on the page, and then attempts to focus any of the three buttons, focus will be restored to whichever of Button1, Button2, or Button3 was last selected by before selection left the frame
</details>

### useMostRecentOrDefaultFocusBehavior

```lua
function useMostRecentOrDefaultFocusBehavior(): (defaultRef: React.Ref<Instance?>, containerRef: React.Ref<Instance?>)
```

Composes the above two behaviors from `useDefaultFocusBehavior` and `useMostRecentFocusBehavior`, such that previous selection is restored but there is a default to fall back on.

As with `useDefaultFocusBehavior`, the element which `defaultRef` is assigned to should be a descendant of the element which `containerRef` is assigned to.

If a valid last-focused descendant exists when refocusing, it will be redirected to, using [`isValidFocusTarget`](../api-reference/focus-navigation.md#isvalidfocustarget) to determine validity. If no valid targets are found, the default will be used.

See [mostRecentOrDefault](../api-reference/focus-behaviors.md/#mostrecentordefault) from [FocusBehavior](../api-reference/focus-behaviors.md).

<details><summary>Sample Code</summary>

```lua
function MostRecentTestComponent(props)
  local defaultRef, containerRef = useMostRecentOrDefaultFocusBehavior()

  return React.createElement("Frame", {
    Size = UDim2.fromScale(1, 1),
    ref = containerRef,
  }, {
    Button1 = React.createElement("TextButton", {
      Text = "",
      ref = defaultRef,
    }),
    Button2 = React.createElement("TextButton", {
      Text = "",
    }),
    Button2 = React.createElement("TextButton", {
      Text = "",
    }),
  })
end
```

When selection first enters the frame, Button1 will be selected. If the user moves selection to Button3, then selects something elsewhere on the page (outside of Frame), then moves focus toward any of the three buttons, Button3 will be reselected.

</details>
