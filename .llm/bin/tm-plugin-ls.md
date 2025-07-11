---
title: tm-plugin-ls
path: bin/tm-plugin-ls
type: script
purpose: Lists Tool Manager plugins with flexible filtering and formatting options.
dependencies:
  - bin/.tm.script.sh
  - bin/.tm.plugins.sh
  - lib-shared/tm/bash/lib.file.ini.sh
tags:
  - plugin
  - management
  - list
  - reporting
---

## Overview
This script is a comprehensive tool for querying and displaying information about plugins. It can filter plugins by their status (available, installed, enabled, disabled) and present the output in various formats, from simple name lists to detailed, human-readable reports or machine-readable formats like JSON and CSV.

## Design Philosophy
The script is designed around a modular system of filters and formatters. The core logic is separated into distinct phases: argument parsing, data retrieval (filtering), and data presentation (formatting). This is achieved using a callback mechanism. The main `main` function determines which filter functions to call (e.g., `_list_enabled_plugins`) and which formatting function (e.g., `__callback_format_pretty`) to use based on the command-line arguments. This makes the script highly extensible, as new filters and formats can be added by simply creating new functions that adhere to the established callback pattern.

## Key Logic
1.  **Argument Parsing:** The script parses a rich set of command-line options to determine how to filter the plugins and how to format the output.
2.  **Filter Selection:** Based on flags like `--enabled`, `--installed`, `--available`, or `--disabled`, the `main` function calls the corresponding `_list_*_plugins` function. If no filter is specified, it defaults to listing installed plugins.
3.  **Data Retrieval:** Each `_list_*_plugins` function is responsible for getting a list of plugin IDs that match its criteria (e.g., by reading the contents of the `$TM_PLUGINS_ENABLED_DIR` or by parsing registry INI files).
4.  **Formatting Callback:** For each plugin found, the script gathers detailed information (repo URL, commit hash, description, etc.) and passes it as an associative array to the selected formatting function (e.g., `__callback_format_pretty`, `__callback_format_json`).
5.  **Output Generation:** The formatting function takes the plugin data and prints it to standard output in the desired format. The script ensures that duplicate plugins are not listed, even if they match multiple filter criteria (e.g., a plugin that is both installed and enabled).

## Usage
```bash
# List full details for all installed plugins (default behavior)
tm-plugin-ls

# List only the names of enabled plugins
tm-plugin-ls --enabled --name

# List all plugins available in the registry in a plain, machine-readable format
tm-plugin-ls --available --format plain

# List installed plugins that are currently disabled
tm-plugin-ls --disabled

# List all known plugins in JSON format
tm-plugin-ls --all --format json
```

## Related
- `.llm/bin/.tm.plugins.sh.md` (Provides the functions for finding plugins by status)
- `.llm/lib-shared/tm/bash/lib.file.ini.sh.md` (Used to parse the plugin registry files)