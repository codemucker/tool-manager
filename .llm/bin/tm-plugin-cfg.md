---
title: tm-plugin-cfg
path: bin/tm-plugin-cfg
type: script
purpose: Opens an editor for a specific plugin's configuration file or the main plugin configuration directory.
dependencies:
  - bin/.tm.script.sh
  - bin/.tm.plugin.sh
  - bin/.tm.plugins.sh
  - bin/.tm.cfg.sh
tags:
  - plugin
  - configuration
  - editor
---

## Overview
This script provides a convenient way to edit the configuration files for installed plugins. It can target a specific plugin's `.env` file or open the entire central plugin configuration directory for broader changes.

## Design Philosophy
The script is designed for ease of use, providing a single command to access configuration that might otherwise be in various locations. It intelligently resolves the editor to use based on environment variables (`$TM_CFG_EDITOR`, `$EDITOR`) with sensible fallbacks (`vi`, `nano`). The core logic for resolving plugin details and configuration paths is delegated to the respective library scripts (`.tm.plugin.sh`, `.tm.cfg.sh`), keeping this script focused on the user-facing task of opening an editor.

## Key Logic
1.  **Argument Parsing:** The script parses command-line arguments to identify the target plugin (if any) and any explicit editor choice.
2.  **Editor Resolution:** It calls `_tm::cfg::get_cfg_editor` to determine which command-line editor to use, prioritizing user-defined environment variables.
3.  **Plugin Identification:** It determines which plugin's configuration to edit. This can be:
    a. A `QUAILIFIED-PLUGIN-NAME` provided as an argument.
    b. The current plugin, via the `--this` flag, which reads the `TM_PLUGIN_ID` environment variable (useful when called from other plugin scripts).
    c. The Tool Manager's own root configuration if no plugin is specified.
4.  **Path Resolution:** Based on the identified plugin, it determines the correct path. For a specific plugin, this is its dedicated `.env` file (`${plugin[cfg_sh]}`). For the root, it's the main `$TM_PLUGINS_CFG_DIR`.
5.  **File/Directory Handling:** The `__edit` helper function ensures the target configuration file or directory exists, creating it if necessary, before launching the editor.

## Usage
```bash
# Edit the configuration for a specific plugin
tm-plugin-cfg my-vendor:my-plugin

# Edit the configuration for the plugin calling this script
# (Assumes TM_PLUGIN_ID is set)
tm-plugin-cfg --this

# Open the entire plugin configuration directory in the default editor
tm-plugin-cfg

# Specify a different editor
tm-plugin-cfg --editor nano my-vendor:my-plugin
```

## Related
- `.llm/bin/.tm.plugin.sh.md` (Handles plugin data parsing)
- `.llm/bin/.tm.plugins.sh.md` (Handles plugin discovery)
- `.llm/bin/.tm.cfg.sh.md` (Handles configuration logic)