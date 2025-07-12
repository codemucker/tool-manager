---
title: tm-plugin-registry-add
path: bin/tm-plugin-registry-add
type: script
purpose: Adds a new plugin registry file to the Tool Manager configuration.
dependencies:
  - bin/.tm.script.sh
tags:
  - plugin
  - management
  - registry
  - configuration
---

## Overview
This script allows users to extend the list of available plugins by adding new registry files. A registry file is a `.conf` (INI-style) file that contains definitions for one or more plugins, including their names, repository URLs, and descriptions.

## Design Philosophy
The script provides a simple and direct way to manage plugin sources. It performs a straightforward copy operation, taking a user-provided file and placing it into the central `$TM_PLUGINS_REGISTRY_DIR`. It includes safety checks to prevent accidentally overwriting an existing registry file by prompting the user for confirmation.

## Key Logic
1.  **Argument Parsing:** The script requires a `--file` argument specifying the path to the registry file to be added. An optional `--name` argument allows the user to specify a different name for the file in the destination directory.
2.  **Destination Path Resolution:** It determines the destination path within the `$TM_PLUGINS_REGISTRY_DIR`. If no name is provided, it uses the basename of the source file. It also ensures the destination file has the correct `.conf` extension.
3.  **Overwrite Check:** It checks if a file with the same name already exists in the registry directory. If it does, it warns the user and asks for confirmation before proceeding.
4.  **File Copy:** It ensures the registry directory exists (`mkdir -p`) and then copies the specified file into it.

## Usage
```bash
# Add a registry file from a local path
tm-plugin-registry-add --file /path/to/my-custom-plugins.conf

# Add a registry file and give it a different name
tm-plugin-registry-add --file /path/to/my-custom-plugins.conf --name 02.my-plugins
```

## Related
- `bin/tm-plugin-install` (Uses the information from registry files to install plugins)
- `bin/tm-plugin-ls` (Can list available plugins from all registered `.conf` files)