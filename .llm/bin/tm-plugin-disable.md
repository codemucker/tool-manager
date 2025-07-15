---
title: tm-plugin-disable
path: bin/tm-plugin-disable
type: script
purpose: Disables one or more currently enabled plugins.
dependencies:
  - bin/.tm.script.sh
  - bin/.tm.plugin.sh
  - bin/.tm.plugins.sh
tags:
  - plugin
  - management
---

## Overview
This script deactivates one or more plugins, preventing their scripts and configurations from being loaded into the environment. It's a non-destructive way to turn off a plugin without deleting its files.

## Design Philosophy
The script provides a straightforward mechanism for managing active plugins. The core logic is delegated to the `_tm::plugin::disable` function in the `.tm.plugin.sh` library, which handles the removal of the plugin's symlink from the `$TM_PLUGINS_ENABLED_DIR`. This keeps the `tm-plugin-disable` script itself simple and focused on parsing user input. The script automatically calls `tm-reload` after a successful operation to ensure the user's shell session reflects the change immediately.

## Key Logic
1.  **Argument Parsing:** The script accepts one or more qualified plugin names as arguments. It also has an `--all` flag to disable every currently enabled plugin.
2.  **Disabling Specific Plugins:** If plugin names are provided, the script iterates through them:
    a. It finds the exact qualified name of the enabled plugin using `_tm::plugins::enabled::get_by_name`.
    b. It calls the `_tm::plugin::disable` helper function, which removes the symlink from the enabled directory and runs the plugin's `plugin-disable` hook script if it exists.
3.  **Disabling All Plugins:** If the `--all` flag is used, the script takes a more direct approach by simply deleting the entire `$TM_PLUGINS_ENABLED_DIR`. This is a fast and effective way to deactivate everything at once.
4.  **Reload:** After successfully disabling one or more plugins, the script executes `tm-reload` to unload the associated functions and aliases from the current shell session.

## Usage
```bash
# Disable a specific plugin
tm-plugin-disable my-vendor/my-plugin

# Disable multiple plugins
tm-plugin-disable my-plugin-1 my-plugin-2

# Disable all currently enabled plugins
tm-plugin-disable --all
```

## Related
- `.llm/bin/.tm.plugin.sh.md` (Contains the core `_tm::plugin::disable` logic)
- `bin/tm-plugin-enable` (The counterpart to this script)
- `bin/tm-reload` (Called to refresh the environment after disabling)