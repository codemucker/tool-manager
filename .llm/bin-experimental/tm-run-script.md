---
title: tm-run-script
path: bin-internal/tm-run-script
type: script
purpose: Internal script that sets up the plugin environment and executes the target script.
dependencies:
  - bin/.tm.boot.sh
tags:
  - internal
  - plugin
  - execution
  - environment
---

## Overview
This script is a core internal component of the tool-manager's plugin execution system. It is not intended for direct user interaction. Its primary role is to act as an intermediary, invoked by a plugin's wrapper script, to establish a consistent execution environment for the actual plugin script. It sets up essential environment variables and provides a lazy-loading mechanism for the main tool-manager libraries.

## Design Philosophy
The script is optimized for speed to minimize any overhead during plugin script execution. It performs the minimum necessary setup to ensure the plugin script has access to its directories, ID, and a way to load the wider tool-manager framework if needed. It avoids loading the full tool-manager environment by default, allowing simple, standalone scripts to run without unnecessary dependencies.

## Key Logic
1.  **Argument Parsing:** It receives a fixed set of arguments from the wrapper script, including the plugin ID, directories, and the path to the real script to be executed.
2.  **Environment Setup:** It exports several `TM_PLUGIN_*` environment variables (`TM_PLUGIN_HOME`, `TM_PLUGIN_ID`, `TM_PLUGIN_CFG_DIR`, `TM_PLUGIN_STATE_DIR`) so the target script can understand its own context.
3.  **Path Modification:** It prepends the plugin's `bin` and `bin-internal` directories to the `PATH`. This allows a plugin's scripts to call each other directly without needing to know their absolute paths.
4.  **Lazy Loading:** It defines and exports the `_tm_load` bash function. A plugin script can call this function if it needs to access the full suite of tool-manager libraries (logging, parsing, etc.). This function sources `.tm.boot.sh` on demand.
5.  **Execution:** Finally, it uses `exec` to replace itself with the `real_script`, passing along all remaining user-provided arguments. This is efficient as it avoids creating a new process.

## Usage
This script is not called directly by the user. It is invoked by the wrapper scripts generated for each plugin command.

## Related
- `.llm/bin/.tm.plugin.sh.md` (The script that generates the wrappers that call this script)
- `.llm/bin/.tm.boot.sh.md` (The script that `_tm_load` will source to initialize the full environment)