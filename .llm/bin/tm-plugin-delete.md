---
title: tm-plugin-delete
path: bin/tm-plugin-delete
type: script
purpose: Deletes one or more installed plugins from the filesystem.
dependencies:
  - bin/.tm.script.sh
  - bin/.tm.plugins.sh
tags:
  - plugin
  - management
  - delete
---

## Overview
This script is responsible for the complete removal of one or more plugins. It deletes the plugin's directory from the filesystem, effectively uninstalling it.

## Design Philosophy
The script provides both a direct and an interactive way to delete plugins. It prioritizes safety by ensuring that the core deletion logic is handled by the `_tm::plugins::uninstall` function from the `.tm.plugins.sh` library, which contains the necessary checks and cleanup procedures. If a plugin is successfully deleted, the script automatically triggers `tm-reload` to ensure the system's state is consistent.

## Key Logic
1.  **Argument Parsing:** The script accepts one or more plugin names as command-line arguments.
2.  **Direct Deletion:** If plugin names are provided as arguments, the script iterates through them:
    a. It resolves the plugin name to its fully qualified name using `_tm::plugins::installed::get_by_name`.
    b. It calls `_tm::plugins::uninstall` to perform the deletion.
    c. It sets a flag to run `tm-reload` later.
3.  **Interactive Mode:** If no arguments are given, the script enters an interactive loop:
    a. It prompts the user to enter one or more space-separated plugin names.
    b. If the user presses Enter without typing a name, it lists all currently installed plugins to help the user choose.
    c. Once names are entered, it processes them for deletion as in the direct mode.
4.  **Reload:** After all specified plugins have been processed, if at least one was successfully deleted, the script calls `tm-reload` to update the shell environment and remove any aliases or functions associated with the deleted plugins.

## Usage
```bash
# Delete a single plugin
tm-plugin-delete my-vendor/my-plugin

# Delete multiple plugins at once
tm-plugin-delete my-plugin-1 my-plugin-2

# Enter interactive mode to choose which plugin to delete
tm-plugin-delete
```

## Related
- `.llm/bin/.tm.plugins.sh.md` (Contains the core `_tm::plugins::uninstall` logic)
- `bin/tm-reload` (Called to refresh the environment after deletion)
- `bin/tm-plugin-disable` (A less permanent way to deactivate a plugin without deleting its files)