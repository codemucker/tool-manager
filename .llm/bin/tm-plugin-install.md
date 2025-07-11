---
title: tm-plugin-install
path: bin/tm-plugin-install
type: script
purpose: Installs one or more plugins from a registry or a direct Git URL.
dependencies:
  - bin/.tm.script.sh
  - bin/.tm.plugins.sh
tags:
  - plugin
  - management
  - install
  - git
---

## Overview
This script is the primary entry point for adding new plugins to the Tool Manager. It can resolve plugin names from the configured plugin registries or install directly from a Git repository URL.

## Design Philosophy
The script is designed to be flexible, supporting multiple ways to specify a plugin. The core installation logic is encapsulated within the `_tm::plugins::install` function in the `.tm.plugins.sh` library. This function handles resolving the plugin's source, cloning the repository, and placing it in the correct directory. The `tm-plugin-install` script acts as a user-friendly frontend to this logic, providing argument parsing and an interactive mode for users who don't provide arguments directly. It also includes a helpful fallback to try a direct GitHub installation if a plugin name isn't found in the registry.

## Key Logic
1.  **Argument Parsing:** The script accepts one or more plugin specifications as arguments. These can be simple names (e.g., `my-plugin`), qualified names (`vendor/my-plugin`), names with versions (`my-plugin@1.2.3`), or full Git URLs.
2.  **Direct Installation:** If plugin specifications are provided as arguments, the script iterates through them and calls `_tm::plugins::install` for each one.
3.  **GitHub Fallback:** If `_tm::plugins::install` fails (e.g., the plugin name is not in the registry), the script constructs a potential `github.com` URL based on the plugin's name and vendor and asks the user if they want to attempt to install from that URL directly.
4.  **Interactive Mode:** If no arguments are given, the script enters an interactive loop:
    a. It prompts the user to enter one or more space-separated plugin names or URLs.
    b. If the user presses Enter without input, it lists all available plugins from the configured registries by calling `tm-plugin-ls --available`.
    c. Once input is provided, it processes each entry for installation.
5.  **Reload:** If any plugin is successfully installed, the script sets a flag. After all installations are attempted, if the flag is set, it calls `tm-reload` to make the new plugins' commands available.

## Usage
```bash
# Install a plugin from the registry by name
tm-plugin-install my-cool-plugin

# Install a plugin from a specific vendor
tm-plugin-install my-vendor/my-cool-plugin

# Install a specific version of a plugin
tm-plugin-install my-vendor/my-cool-plugin@1.5.0

# Install directly from a Git repository URL
tm-plugin-install git@github.com:some-user/some-plugin.git

# Enter interactive mode to browse and select plugins
tm-plugin-install
```

## Related
- `.llm/bin/.tm.plugins.sh.md` (Contains the core `_tm::plugins::install` logic)
- `bin/tm-plugin-ls` (Used to list available plugins in interactive mode)
- `bin/tm-reload` (Called to refresh the environment after installation)