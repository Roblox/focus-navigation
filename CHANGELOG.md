# Focus Navigation Changelog

## 1.4.0 (12-16-2024)

* Remove `useLastInputMode` and `useLastInputMethod` hooks from exports
* Update documentation to include code samples, better warnings, and more usage information

## 1.3.0 (9-27-2023)

* Add `isValidFocusTarget` utility, add focus behavior hooks `useContainerFocusBehavior`, `useDefaultFocusBehavior`, `useMostRecentFocusBehavior`, `useMostRecentOrDefaultFocusBehavior` ([#29](https://github.com/Roblox/focus-navigation-internal/pull/29))

## 1.2.0 (7-25-2023)

* Add `useLastInputMode` hook ([#27](https://github.com/Roblox/focus-navigation-internal/pull/27))
* Add the `registerFocusBehavior` and `deregisterFocusBehavior` API members to the `FocusNavigationService` ([#25](https://github.com/Roblox/focus-navigation-internal/pull/25))

## 1.1.0 (6-20-2023)

* An event having been processed by the engine will no longer prevent event propagation ([#23](https://github.com/Roblox/focus-navigation-internal/pull/23))
* Events propagated through the FocusNavigationService will now have an attribute indicating that the event was processed ([#23](https://github.com/Roblox/focus-navigation-internal/pull/23))

## 1.0.0 (6-5-2023)

* Fix `Event:cancel()` typing ([#19](https://github.com/Roblox/focus-navigation-internal/pull/19))
* Add input handling module for easier use of engine input events ([#18](https://github.com/Roblox/focus-navigation-internal/pull/18))

## 0.2.1 (5-1-2023)

* Add some dev mode warnings for subtle misuses or unexpected inputs ([#16](https://github.com/Roblox/focus-navigation-internal/pull/16))
* Introduce the `useLastInputMethod` hook ([#15](https://github.com/Roblox/focus-navigation-internal/pull/15))

## 0.1.0 (3-7-2023)

* Refactor to expose context directly ([#14](https://github.com/Roblox/focus-navigation-internal/pull/14))
* Add demo app ([#10](https://github.com/Roblox/focus-navigation-internal/pull/10))
* Add `useFocusedGuiObject` hook ([#13](https://github.com/Roblox/focus-navigation-internal/pull/13))
* Fix an issue with active event map not filtering based on which events have registered handlers ([#12](https://github.com/Roblox/focus-navigation-internal/pull/12))
* Introduce `useFocusGuiObject` ([#11](https://github.com/Roblox/focus-navigation-internal/pull/11))
* Introduce `useEventHandler` ([#8](https://github.com/Roblox/focus-navigation-internal/pull/8))
* Introduce `useActiveEventMap` ([#9](https://github.com/Roblox/focus-navigation-internal/pull/9))
* Introduce `useEventHandlerMap` ([#7](https://github.com/Roblox/focus-navigation-internal/pull/7))
* Introduce `useEventMap` and some utility hooks underneath it ([#6](https://github.com/Roblox/focus-navigation-internal/pull/6))
* Added observable properties to focus-navigation module ([#5](https://github.com/Roblox/focus-navigation-internal/pull/5))
* Added core functionality of focus-navigation module ([#4](https://github.com/Roblox/focus-navigation-internal/pull/4))
* Added event-propagation module ([#2](https://github.com/Roblox/focus-navigation-internal/pull/2))
