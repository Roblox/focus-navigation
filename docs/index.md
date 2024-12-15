# Focus Navigation

## Overview
Focus Navigation is a collection of libraries used to build UI that can be navigated using directional input, like a gamepad or keyboard, in a more feature-rich way. The word "focus" in this library can be thought of as an expansion upon the existing concept of "selection".

Some common uses include:

* Easier keybinds and callback mappings
* Custom behavior for containers when selection enters their UI tree
* Managing logic for the currently selected object
* Detecting what input method the user is utilizing

...and more!

## General Use

The primary public interface for this library is through [React](https://github.com/Roblox/react-lua) via [ReactFocusNavigation](api-reference/react-focus-navigation.md), but non-React helpers are also provided in [FocusNavigation](api-reference/focus-navigation.md). Most features built using this library will use one of these options combined with [InputHandlers](api-reference/input-handlers.md) to manage keybinds and callbacks.

Here is a quick overview of these modules:

* [ReactFocusNavigation](api-reference/react-focus-navigation.md) - Provides useful hooks and providers that interface with the generic `FocusNavigationService` within React components. This includes mapping keybinds, setting focus behaviors, etc.

* [FocusNavigation](api-reference/focus-navigation.md) - The core, unwrapped logic undearneath `ReactFocusNavigation`; this interface may be useful for more complex custom behavior, or for developers who do not wish to use React.

* [InputHandlers](api-reference/input-handlers.md) - A utility package that defines input handling callbacks which can be used with either `ReactFocusNavigation` or `FocusNavigation` directly. Breaks down callbacks by input state (ie. press, release, hold).

## Internal Packages

Focus Navigation is driven by these generic under-the-hood libraries. Most users should be unconcerned with these details, but non-React users or library developer may have interest in using their capabilities directly:

* [EventPropagation](api-reference/event-propagation.md) - Allows events to be propagated down and back up the tree of UI descendants; used under the hood by FocusNavigation
* [FocusBehaviors](api-reference/focus-behaviors.md) - Defines some default container focus behaviors, which can be used to support app navigation concerns like restoring focus properly when returning to a page from a modal

## Supplementary Resources

This library expands upon the existing concept of "selection" in the Roblox game engine. These resources for selection may also be useful:

* `GuiObject`'s selection-related properties:
    * [Selectable](https://create.roblox.com/docs/reference/engine/classes/GuiObject#Selectable)
    * [NextSelectionUp](https://create.roblox.com/docs/reference/engine/classes/GuiObject#NextSelectionUp)
    * [NextSelectionDown](https://create.roblox.com/docs/reference/engine/classes/GuiObject#NextSelectionDown)
    * [NextSelectionLeft](https://create.roblox.com/docs/reference/engine/classes/GuiObject#NextSelectionLeft)
    * [NextSelectionRight](https://create.roblox.com/docs/reference/engine/classes/GuiObject#NextSelectionRight)
    * [SelectionOrder](https://create.roblox.com/docs/reference/engine/classes/GuiObject#SelectionOrder)
    * [SelectionImageObject](https://create.roblox.com/docs/reference/engine/classes/GuiObject#SelectionImageObject)
* `GuiBase2d`'s selection-related properties and events:
    * [SelectionGroup](https://create.roblox.com/docs/reference/engine/classes/GuiBase2d#SelectionGroup)
    * [SelectionBehaviorUp](https://create.roblox.com/docs/reference/engine/classes/GuiBase2d#SelectionBehaviorUp)
    * [SelectionBehaviorDown](https://create.roblox.com/docs/reference/engine/classes/GuiBase2d#SelectionBehaviorDown)
    * [SelectionBehaviorLeft](https://create.roblox.com/docs/reference/engine/classes/GuiBase2d#SelectionBehaviorLeft)
    * [SelectionBehaviorRight](https://create.roblox.com/docs/reference/engine/classes/GuiBase2d#SelectionBehaviorRight)
    * [SelectionChanged](https://create.roblox.com/docs/reference/engine/classes/GuiBase2d#SelectionChanged)
* `GuiService`'s [SelectedObject](https://create.roblox.com/docs/reference/engine/classes/GuiService#SelectedObject)
