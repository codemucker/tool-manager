---
title: tm-cfg-get
path: bin/tm-cfg-get
type: script
purpose: Retrieves a configuration value from the tool-manager or a specific plugin's settings.
dependencies:
  - bin/.tm.cfg.sh
tags:
  - configuration
  - cli
---

## Overview
This script is the primary command-line interface for reading configuration values from the `.tool-manager`'s settings. It acts as a simple wrapper around the `_tm::cfg::get` function provided by the `.tm.cfg.sh` library.

## Design Philosophy
The script is designed as a minimal, single-purpose command that adheres to the Unix philosophy. It does one thing: gets a configuration value. All the complex logic for finding the correct configuration file, parsing it, and handling different scopes (global, tool-manager, plugin) is delegated to the underlying `.tm.cfg.sh` library. This keeps the user-facing script extremely simple and maintainable.

## Key Logic
1.  **Shebang:** It uses `#!/usr/bin/env env-tm-bash` to ensure it runs within the fully initialized tool-manager environment, making all `tm` functions available.
2.  **Error Trapping:** It immediately calls `_trap_error` to enable the global error handler, ensuring that any failures in the underlying library will cause the script to exit with a non-zero status and a stack trace.
3.  **Delegation:** The script's entire functionality consists of calling `_tm::cfg::get` and passing all of its own command-line arguments (`$@`) directly to it. The `_tm::cfg::get` function handles the argument parsing and logic for retrieving the value.

## Usage
The script can be used to get a configuration value from the global tool-manager scope or from a specific plugin's scope.

```bash
# Get a global tool-manager configuration value
tm-cfg-get --tm TM_EDITOR

# Get a configuration value for a specific plugin
tm-cfg-get --plugin my-plugin-name SOME_PLUGIN_VARIABLE

# Get a value, providing a default if it's not set
tm-cfg-get --plugin my-plugin-name SOME_VAR --default "fallback_value"
```

## Related
-   `.llm/bin/.tm.cfg.sh.md` (Provides the `_tm::cfg::get` function that does all the work)
-   `.llm/bin/tm-cfg-set.md` (The corresponding command for writing configuration values)