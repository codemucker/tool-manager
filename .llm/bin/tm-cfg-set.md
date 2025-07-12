---
title: tm-cfg-set
path: bin/tm-cfg-set
type: script
purpose: Sets or updates a configuration value for the tool-manager or a specific plugin.
dependencies:
  - bin/.tm.script.sh
  - bin/.tm.cfg.sh
  - lib-shared/tm/bash/lib.parse.sh
tags:
  - configuration
  - cli
---

## Overview
This script is the primary command-line interface for writing configuration values to the `.tool-manager`'s settings. It serves as a user-friendly wrapper around the `_tm::cfg::set_value` function, providing argument parsing and logic to determine the correct scope (tool-manager vs. a specific plugin) for the configuration change.

## Design Philosophy
The script is designed to be a flexible and robust tool for configuration management. It uses a powerful argument parser (`_parse_args`) to handle various ways of specifying the target configuration scope. The core logic is minimal, focusing on correctly identifying the target plugin and the key/value pair, and then delegating the actual file I/O operation to the `.tm.cfg.sh` library. This separation of concerns keeps the script clean and focused on its role as a CLI entrypoint.

## Key Logic
1.  **Argument Parsing:** The script uses the `_parse_args` function to process command-line flags. It supports multiple ways to define the configuration scope:
    -   `--tm`: Targets the global tool-manager configuration.
    -   `--plugin <name>`: Targets the configuration for the specified plugin.
    -   `--this`: A special flag that automatically detects the current plugin's context by reading the `TM_PLUGIN_ID` environment variable. This is useful for scripts running within a plugin's own execution context.
    -   If no scope is specified, it defaults to the tool-manager scope.
2.  **Plugin Parsing:** Based on the parsed arguments, it calls the appropriate `_tm::parse::*` function to resolve the target into a full plugin associative array.
3.  **Delegation:** It calls `_tm::cfg::set_value`, passing the resolved plugin's qualified name, the configuration key, and the value to be set.
4.  **Error Handling:** If the `_tm::cfg::set_value` function returns a non-zero exit code, the script fails with a descriptive error message.

## Usage
```bash
# Set a global tool-manager configuration value
tm-cfg-set --tm TM_EDITOR "vim"

# Set a configuration value for a specific plugin
tm-cfg-set --plugin my-plugin-name API_KEY "12345"

# The key and value can also be specified with flags
tm-cfg-set --plugin my-plugin-name --key API_KEY --value "12345"

# From within a plugin script, you can set a value for the plugin itself
tm-cfg-set --this SOME_INTERNAL_SETTING "enabled"
```

## Related
-   `.llm/bin/.tm.cfg.sh.md` (Provides the `_tm::cfg::set_value` function that does the file writing)
-   `.llm/bin/tm-cfg-get.md` (The corresponding command for reading configuration values)
-   `.llm/lib-shared/tm/bash/lib.parse.sh.md` (Used to resolve plugin names and IDs)