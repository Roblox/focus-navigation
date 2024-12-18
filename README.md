<h1 align="center">Focus Navigation</h1>
<div align="center">
 <a href="https://github.com/Roblox/focus-navigation-internal-internal/actions/workflows/ci.yml">
  <img src="https://github.com/Roblox/focus-navigation-internal/actions/workflows/ci.yml/badge.svg" alt="CI Build Status" />
 </a>
 <!-- <a href="https://coveralls.io/github/Roblox/focus-navigation-internal?branch=main">
		<img src="https://coveralls.io/repos/github/Roblox/focus-navigation-internal/badge.svg?branch=main" alt="Coveralls Coverage" />
	</a> -->
 <a href="https://roblox.github.io/focus-navigation-internal">
  <img src="https://img.shields.io/badge/docs-website-green.svg" alt="Documentation" />
 </a>
</div>
<div>&nbsp;</div>

## Overview

Focus Navigation is a collection of libraries used to build UI that can be navigated using directional input, like a gamepad or keyboard, in a more feature-rich way. The word "focus" in this library can be thought of as an expansion upon the existing concept of "selection".

Some common uses include:

* Easier keybinds and callback mappings
* Custom behavior for containers when selection enters their UI tree
* Managing logic for the currently selected object
* Detecting what input method the user is utilizing

...and more!

## General Use

The primary public interface for this library is through [React](https://github.com/Roblox/react-lua) via [ReactFocusNavigation](https://roblox.github.io/focus-navigation-internal/api-reference/react-focus-navigation.md), but non-React helpers are also provided in [FocusNavigation](https://roblox.github.io/focus-navigation-internal/api-reference/focus-navigation-internal.md). Most features built using this library will use one of these options combined with [InputHandlers](https://roblox.github.io/focus-navigation-internal/api-reference/input-handlers.md) to manage keybinds and callbacks.

## Installation

The Focus Navigation library can be installed via [Rotriever](https://github.com/roblox/rotriever). Add the following to the `rotriever.toml` file for your project:

```toml
ReactFocusNavigation = "github.com/roblox/focus-navigation-internal@1.3.0"
```

Optionally, you may wish to include the [`InputHandlers`](https://roblox.github.io/focus-navigation-internal/api-reference/input-handlers.md) utility library as well:

```toml
InputHandlers = "github.com/roblox/focus-navigation-internal@1.3.0"
```

## Documentation

Documentation for Focus Navigation is available on [the official documentation website](https://roblox.github.io/focus-navigation-internal).

### Contribution

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in the work by you, as defined in the MIT license, shall be licensed as above, without any additional terms or conditions.

Take a look at the [contributing guide](CONTRIBUTING.md) for guidelines on how to contribute to Focus Navigation.
