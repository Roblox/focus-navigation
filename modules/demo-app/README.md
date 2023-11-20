# Demo App

A small skeleton app that demonstrates a few key features of the `ReactFocusNavigation` library. It has not yet been updated to make use of the `InputHandlers` and `FocusBehavior` libraries.

## How to Run

1. Check out this repo
2. Run `rotrieve install`
3. Open Roblox Studio
4. File -> Open from File... -> select "focus-navigation/modules/demo-app/demo.rbxp"

## What Does it Do?

The demo app is intended to:
* demonstrate the core functionalities of the `ReactFocusNavigation` library
* highlight any outstanding difficulties that may exist in this problem space in spite of what the library provides

### Functionality

Currently, it demonstrates a few key behaviors:

* A tabbed interface with buttons for different screens
* Shortcuts to move between tabs and move back in a StackNavigator
    * Shortcuts are bound to both keyboard and gamepad buttons for ease of use
* An overlay showing which options are currently bound
* Capturing and restoring focus when moving up and down a StackNavigator

### Challenges

The following pieces of core functionality are not implemented and are still not easily addressed by the focus navigation features:

* Generically capturing focus on a tab after navigation to it
* Input behaviors beyond simple presses (e.g. press-and-hold)
* Dropping and restoring focus when input type changes

Some of these have been addressed as we've iron out the feature set for the library, and others may remain the responsibility of downstream applications.