# Focus Navigation

Focus Navigation is a collection libraries 

The primary public interface is the [ReactFocusNavigation](modules/react-focus-navigation/README.md) package, which provides useful hooks and providers for using the generic FocusNavigationService within React components.

Common use cases may also utilize the [InputHandlers](modules/input-handlers/README.md) package, a utility package that defines input handling callbacks that can be used with `ReactFocusNavigation` (or with `FocusNavigation` directly).

## Internal Packages

Focus Navigation is driven by these generic under-the-hood libraries. Most users should be unconcerned with these details, but non-React users or library developer may have interest in using their capabilities directly:

* [EventPropagation](api-reference/event-propagation.md) - Allows events to be propagated down and back up the tree of UI descendants; used under the hood by FocusNavigation
* [FocusNavigation](api-reference/focus-navigation.md) - Handles the internal UI-library-agnostic focus management logic; this interface may be useful for handling focus navigation outside of React UIs
* [FocusBehaviors](api-reference/focus-behaviors.md) - Defines some default container focus behaviors, which can be used to support app navigation concerns like restoring focus properly when returning to a page from a modal
