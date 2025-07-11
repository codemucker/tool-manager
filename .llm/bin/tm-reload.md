---
title: tm-reload
path: bin/tm-reload
type: script
purpose: Reloads the Tool Manager environment or specific plugins to apply changes.
dependencies:
  - bin/.tm.script.sh
  - bin/.tm.plugin.sh
  - bin/.tm.plugins.sh
  - bin/.tm.common.sh
tags:
  - core
  - environment
  - reload
---

## Overview
This is a critical script for applying configuration changes, newly installed plugins, or updates to existing plugin scripts. It can perform a full reload of the entire Tool Manager environment or target specific plugins.

## Design Philosophy
The script provides a centralized way to refresh the user's shell environment. When called without arguments, it triggers a full bootstrap reload (`_tm::boot::reload`), which re-sources all necessary files and regenerates all script wrappers. This ensures that any changes to the core system or any enabled plugin are reflected in the current session. It also offers more granular control, allowing a user to reload a single plugin or to simply regenerate the wrapper scripts without a full environment reload, which is faster.

## Key Logic
1.  **Argument Parsing:** The script checks for plugin names to target, or flags like `--scripts` (to only regenerate wrappers), `--clear` (to clear caches), and `--yes` (to skip confirmations).
2.  **Full Reload:** If no plugin names are provided, it defaults to a full reload.
    *   If `--scripts` is specified, it calls `_tm::plugins::regenerate_all_wrapper_scripts`.
    *   Otherwise, it calls `_tm::boot::reload` for a complete environment refresh.
3.  **Targeted Reload:** If one or more plugin names are given, it iterates through them.
    *   For each plugin, it calls `_tm::parse::plugin` to get its details.
    *   If `--scripts` is specified, it calls `_tm::plugin::regenerate_wrapper_scripts` for just that plugin.
    *   Otherwise, it calls `_tm::plugin::reload`, which re-sources the plugin's `.bashrc` and regenerates its scripts.
4.  **Cache Clearing:** If the `--clear` flag is present, it removes the `$TM_CACHE_DIR` before performing any reload operations.

## Usage
```bash
# Perform a full reload of the Tool Manager environment
tm-reload

# Reload only a specific plugin
tm-reload my-vendor/my-plugin

# Only regenerate the wrapper scripts for all plugins without a full reload
tm-reload --scripts

# Clear the cache and then do a full reload
tm-reload --clear
```

## Related
- `.llm/bin/.tm.boot.sh.md` (Contains the `_tm::boot::reload` function for full reloads)
- `.llm/bin/.tm.plugins.sh.md` (Contains functions for regenerating scripts)
- `.llm/bin/.tm.plugin.sh.md` (Contains the `_tm::plugin::reload` function for targeted reloads)