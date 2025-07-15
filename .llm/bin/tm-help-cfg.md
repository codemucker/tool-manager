---
title: tm-help-cfg
path: bin/tm-help-cfg
type: script
purpose: Displays a detailed summary of the current tool-manager configuration, paths, and plugin status.
dependencies:
  - bin/.tm.script.sh
  - bin/.tm.plugins.sh
  - bin/tm-plugin-ls
tags:
  - help
  - configuration
  - debugging
  - cli
---

## Overview
This script provides a comprehensive, human-readable "dump" of the live tool-manager configuration. It is an essential diagnostic tool for users and developers to understand the current state of the environment, including all the key directory paths, logging settings, and a list of installed and enabled plugins.

## Design Philosophy
The script is designed to be a simple and effective diagnostic tool. It directly accesses and prints the values of the core `TM_*` environment variables that are set during the bootstrap process. This ensures that the output always reflects the actual, live configuration of the current shell session. For plugin information, it delegates to the `tm-plugin-ls` command, reusing existing logic rather than replicating it. The output is formatted with simple indentation for clarity.

## Key Logic
1.  **Sourcing Dependencies:** It sources `.tm.script.sh` for standard setup and `.tm.plugins.sh` to ensure the `_is_debug` and `_is_trace` functions are available.
2.  **Printing Core Variables:** It uses a series of `echo` statements to print the values of important environment variables like `$TM_HOME`, `$TM_BIN`, `$TM_BASE_STATE_DIR`, `$TM_PLUGINS_INSTALL_DIR`, etc. It also includes the name of the variable in parentheses for easy reference.
3.  **Printing Logging Status:** It calls the `_is_debug` and `_is_trace` functions to dynamically report whether the respective logging levels are active.
4.  **Delegating to `tm-plugin-ls`:**
    -   It calls `tm-plugin-ls --enabled --name` to get a list of all currently enabled plugins.
    -   It calls `tm-plugin-ls --installed --name` to get a list of all installed plugins.
    -   The output of these commands is piped to `sed 's|^|      |'` to indent the lists neatly under the appropriate headings.

## Usage
The script is run directly from the command line and takes no arguments.

```bash
tm-help-cfg
```

The output provides a detailed snapshot of the configuration, which is useful for debugging path issues or verifying which plugins are active.

## Related
-   `.llm/bin/.tm.boot.sh.md` (The script that defines and exports most of the variables displayed by this command)
-   `.llm/bin/tm-plugin-ls.md` (The command used to generate the lists of enabled and installed plugins)