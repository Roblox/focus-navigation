# Focus Behaviors

Defines focus management behaviors that can be attached to containers via the FocusNavigationService.

!!! Info
    "Containers" typically refers to pages or modals. Registered focus behaviors will trigger whenever the container gains focus from outside -- in other words: when focus moves from _outside_ the container's hierarchy to _inside_ the container's hierarchy.

## Built-in FocusBehaviors

### default
```lua
function FocusBehaviors.default(descendant: GuiObject?): ContainerFocusBehavior
```

Creates a behavior that always focuses the provides default descendant.

### mostRecent
```lua
function FocusBehaviors.mostRecent(): ContainerFocusBehavior
```

Creates a behavior that always re-focuses the most recently focused descendant when the given container last lost focus. If no such descendant exists (usually when the container is being focused for the very first time), this behavior does not make any changes.

### mostRecentOrDefault
```lua
function FocusBehaviors.mostRecentOrDefault(defaultDescendant: GuiObject?): ContainerFocusBehavior
```

Creates a behavior that re-focuses the most recently focused descendant (as above), but falls back on the provided default descendant if no most-recently-focused descendant was found.

## composeFocusBehaviors
```lua
function FocusBehaviors.composeFocusBehaviors(...: ContainerFocusBehavior): ContainerFocusBehavior
```

Allows multiple [`ContainerFocusBehaviors`](focus-navigation.md#containerfocusbehavior) to be composed together in the order specified in the arguments. When using the composed behavior to restore focus, the composed behaviors' [`getTargets`](#gettargets) functions will be called one-by-one, starting with the first one provided, and aggregated into a new list of focus target candidates.