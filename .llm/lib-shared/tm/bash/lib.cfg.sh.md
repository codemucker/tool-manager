---
title: lib.cfg.sh
path: lib-shared/tm/bash/lib.cfg.sh
type: library
purpose: Manages hierarchical configuration for the tool manager and its plugins.
dependencies:
  - lib-shared/tm/bash/lib.util.sh
  - lib-shared/tm/bash/lib.file.env.sh
  - lib-shared/tm/bash/lib.args.sh
  - lib-shared/tm/bash/lib.parse.sh
  - lib-shared/tm/bash/lib.log.sh
tags:
  - config
  - settings
  - environment
  - plugin
---

## Overview
This library provides a comprehensive system for managing configuration variables for the core tool manager and its plugins. It handles loading configuration from multiple sources, caching for performance, and interactively prompting the user for missing values. It establishes a clear hierarchy for configuration, allowing for global, per-plugin, and user-specific overrides.

## Design Philosophy
The core design is centered around a lazy-loading, hierarchical configuration model. Configuration is not loaded until a script explicitly requests it via `_tm::cfg::get` or `_tm::cfg::load`. This minimizes startup overhead. The system merges multiple configuration files (`.sh`, `.bashrc`, `.env`, `.conf`) into a single, cached script for the relevant plugin. This merged script is only regenerated if the source files change, ensuring high performance for subsequent calls. When a required configuration is missing, the library can interactively prompt the user and save the value, simplifying initial setup.

## Key Logic
1.  **Entry Points:** The library exposes `_tm::cfg::get` (to retrieve and echo a value) and `_tm::cfg::load` (to load variables into the environment). Both are wrappers around the internal `__process` function.
2.  **Fast Path:** The `__process` function first performs a quick check to see if the requested variable is already set in the environment. If so, it returns immediately to maximize speed.
3.  **Argument Parsing:** If the variable isn't set, it uses `lib.args.sh` to parse options, determining which plugin's config to load, the key(s) to retrieve, and the behavior (e.g., `--prompt`, `--required`).
4.  **Config Loading (`__load_cfg`):**
    a.  It identifies all relevant config files for a plugin, from the plugin's own defaults to user-specific overrides in `$TM_PLUGINS_CFG_DIR`.
    b.  It generates a unique hash based on the modification times and paths of these source files.
    c.  It looks for a cached, merged config file at `$TM_CACHE_DIR/merged-config/<plugin_qpath>.config.sh.<hash>`.
    d.  If the cached file exists, it's sourced directly.
    e.  If not, it calls `__generate_merged_sh_file` to create a new merged config, sources it, and cleans up any old cached versions.
5.  **Value Prompting:** If after loading, a required key is still missing and the shell is interactive, `__prompt_for_key` is called to ask the user for the value.
6.  **Setting Values:** The `_tm::cfg::set_value` function provides a way to programmatically or interactively set a config value. It writes the key-value pair to the user's custom config file for the plugin (`$TM_PLUGINS_CFG_DIR/<plugin_qpath>/config.sh`), creating the file and directories if necessary.

## Usage
```bash
# In your script, get a required config value, prompting if not set
API_KEY=$(_tm::cfg::get --key "MY_PLUGIN_API_KEY" --required --note "API key for accessing the service.")

# Load all config for the current plugin into the environment
_tm::cfg::load

# Get a value with a default if it's not configured
DB_HOST=$(_tm::cfg::get --key "DB_HOST" --default "localhost")

# Set a value for another plugin
_tm::cfg::set_value "other-vendor:other-plugin" "SETTING_NAME" "new-value"
```

## Related
- `.llm/lib-shared/tm/bash/lib.args.sh.md` (Used for parsing the get/load commands)
- `.llm/lib-shared/tm/bash/lib.file.env.sh.md` (Contains logic for generating the merged config file)
- `.llm/lib-shared/tm/bash/lib.parse.sh.md` (Used to resolve plugin identifiers)