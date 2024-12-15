# Focus Behaviors

Defines focus management behaviors that can be attached to containers via the FocusNavigationService.

!!! Info
    "Containers" typically refers to pages, modals, scroll views, or other UI where various elements are laid out. Registered focus behaviors will trigger whenever the container gains focus from outside — in other words: when focus moves from _outside_ the container's hierarchy to _inside_ the container's hierarchy.
    
    An example would be when a user moves their selection from a side bar, like the Roblox app's navigation bar, to the contents of a page; in this case, any behaviors associated with the current page (our container) would be triggered.

## Built-in FocusBehaviors

### default
```lua
function FocusBehaviors.default(descendant: GuiObject?): ContainerFocusBehavior
```

Creates a behavior that always focuses the provided `GuiObject` when selection moves into the container.

This is useful in cases where new UI is created that is unlikely to be returned to and has a high priority element, eg. a dialogue with a "confirm" button that disappears permanently when dismissed.

### mostRecent
```lua
function FocusBehaviors.mostRecent(): ContainerFocusBehavior
```

Creates a behavior that always re-focuses the most recently focused descendant when the given container last lost focus. If no such descendant exists (usually when the container is being focused for the very first time), this behavior does not make any changes.

This is useful in cases where a user may leave and return to the same container many times, but is not opinionated about which object focus should begin on, eg. a carousel of items.

### mostRecentOrDefault
```lua
function FocusBehaviors.mostRecentOrDefault(defaultDescendant: GuiObject?): ContainerFocusBehavior
```

Creates a behavior that re-focuses the most recently focused descendant (as above), but falls back on the provided default descendant if no most-recently-focused descendant was found.

This is useful in cases where a user may leave and return to the same container many times, and the container is opinionated about where focus should go when it is first captured, eg. the home page of an app.

## composeFocusBehaviors
```lua
function FocusBehaviors.composeFocusBehaviors(...: ContainerFocusBehavior): ContainerFocusBehavior
```

Allows multiple [`ContainerFocusBehaviors`](focus-navigation.md#containerfocusbehavior) to be composed together in the order specified in the arguments. When using the composed behavior to restore focus, the composed behaviors' [`getTargets`](#gettargets) functions will be called one-by-one, starting with the first one provided, and aggregated into a new list of focus target candidates.