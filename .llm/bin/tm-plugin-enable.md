---
title: tm-plugin-enable
path: bin/tm-plugin-enable
type: script
purpose: Enables one or more installed plugins, making their scripts available in the shell.
dependencies:
  - bin/.tm.script.sh
  - bin/.tm.plugin.sh
  - bin/.tm.plugins.sh
tags:
  - plugin
  - management
---

## Overview
This script activates installed plugins. Activation involves creating a symlink in the `$TM_PLUGINS_ENABLED_DIR`, which makes the plugin's scripts and configurations available to the Tool Manager and the user's shell session.

## Design Philosophy
The script is the primary mechanism for turning on installed plugins. It delegates the core activation logic to the `_tm::plugin::enable` function from the `.tm.plugin.sh` library. This function handles the creation of the necessary symlinks and runs the plugin's `plugin-enable` hook script if it exists. The `tm-plugin-enable` script itself is responsible for parsing user input and iterating over the specified plugins. A `--force` option is provided to re-enable (i.e., disable then enable) an already active plugin, which can be useful for ensuring a clean state.

## Key Logic
1.  **Argument Parsing:** The script requires one or more plugin names to be provided as arguments.
2.  **Plugin Resolution:** For each name provided, it uses `_tm::plugins::installed::get_by_name` to find the corresponding installed plugin.
3.  **Prefix Prompt:** If a plugin is being enabled and it doesn't already have a script prefix defined, the script interactively prompts the user to add one. This is crucial for preventing script name collisions between different plugins.
4.  **Force Re-enabling:** If the `--force` flag is used, the script will first call `_tm::plugin::disable` to ensure the plugin is in a clean state before enabling it again.
5.  **Enabling:** It calls `_tm::plugin::enable`, which performs the main actions:
    a. Creates a symlink from the plugin's installation directory to the enabled directory.
    b. Executes the `plugin-enable` script inside the plugin's directory, if it exists.
6.  **Reload:** Although not explicitly called in the script, the user is expected to run `tm-reload` after enabling plugins to load the new commands into the current shell session.

## Usage
```bash
# Enable a single plugin
tm-plugin-enable my-vendor/my-plugin

# Enable multiple plugins at once
tm-plugin-enable my-plugin-1 my-plugin-2

# Force re-enabling a plugin that is already active
tm-plugin-enable --force my-vendor/my-plugin
```

## Related
- `.llm/bin/.tm.plugin.sh.md` (Contains the core `_tm::plugin::enable` logic)
- `bin/tm-plugin-disable` (The counterpart to this script)
- `bin/tm-reload` (Required to load the newly enabled commands)