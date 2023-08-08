# FocusBehaviors

## Built-in FocusBehaviors

### default
```
FocusBehaviors.default(ref: ObjectRef) -> ContainerFocusBehavior
```

Creates a behavior that always focuses the provides default descendant.

### mostRecent

### mostRecentOrDefault

## composeFocusBehaviors
```lua
FocusBehaviors.composeFocusBehaviors(...: ContainerFocusBehavior) -> ContainerFocusBehavior
```

Allows multiple [`ContainerFocusBehaviors`](../focus-navigation/README.md#containerfocusbehavior) to be composed together in the order specified in the arguments. When using the composed behavior to restore focus, the composed behaviors' [`getTargets`](#gettargets) functions will be called one-by-one, starting with the first one provided, and aggregated into a new list of focus target candidates.