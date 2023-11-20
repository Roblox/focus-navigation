# Input Handlers

Input handling utility functions that simplify the process of authoring event handlers. These handlers are intended to be provided to a `FocusNavigationService` instance via its `registerEventHandler`/`registerEventHandlers` methods.

## onPress
```lua
function onPress(callback: FocusNavigation.EventHandler): FocusNavigation.EventHandler
```

Fires when a relevant input is pressed (`InputObject.UserInputState == Enum.UserInputState.Begin`). You can think of this as a wrapper around your event handler that filters for only `Enum.UserInputState.Begin` events.

When this handler triggers, its `FocusNavigation.Event` will be passed along to the callback as an argument.

## onRelease
```lua
function onRelease(callback: FocusNavigation.EventHandler): FocusNavigation.EventHandler
```

Fires when a relevant input is pressed and then released. While this event handler is bound, it must receive an input event with `InputObject.UserInputState == Enum.UserInputState.Begin` _followed by_ an input event with `InputObject.UserInputState == Enum.UserInputState.End`. When a press -> release sequence is detected, the provided callback will fire.

When this handler triggers, its `FocusNavigation.Event` received from the `UserInputState.End` event will be passed along to the callback as an argument.

## onLongPress
```lua
function onLongPress(
    durationSeconds: number,
    onHoldForDuration: () -> (),
    onHoldStep: nil | (number) -> ()
): FocusNavigation.EventHandler
```

Fires after an input is pressed and held for the specified duration. The `onHoldForDuration` callback fires once the hold duration is reached and takes no arguments, since there are no relevant input events to forward to it.

The `onHoldStep` callback is called on each Heartbeat while the input is held and the hold duration has not yet been reached. It receives a time delta in seconds since the last step (forwarded from a connection to `RunService.Heartbeat`). This argument is intended as a convenience for displaying progress animations during a long press.


## handleInput
```lua
type InputConfig = {
    onPress: FocusNavigation.EventHandler?,
    onRelease: FocusNavigation.EventHandler?,

    hold: {
        durationSeconds: number,
        onComplete: () -> (),
        onStep: nil | (number) -> (),
        allowReleaseAfterHold: boolean?,
    }?,
}
function handleInput(config: InputConfig): FocusNavigation.EventHandler
```

Configurable function for creating custom input handlers not covered by `onPress`, `onRelease`, and `onLongPress`.

* `InputConfig.onPress` - Callback that will fire when a press event is received (see `onPress` input handler)
* `InputConfig.onRelease` - Callback that will fire when a press -> release sequence is received (see `onRelease` input handler)
* `InputConfig.hold` - When this config is present, listens for when an input is held for a duration (see `onLongPress` input handler)
    * `durationSeconds` - The number of seconds for which the input must be held to trigger the `onComplete` callback
    * `onComplete` - Fires when the hold duration is reached
    * `onStep` - Optional function that will be called each heartbeat while the input is held
    * `allowReleaseAfterHold` - Determines whether or not an `onRelease` callback will be triggered after a _completed_ long press. Disabled by default.

The `handleInput` function can be used to implement more complex behaviors like different behaviors for the same input on hold vs. press and release, or custom hold logic using the onPress and onRelease callbacks.
