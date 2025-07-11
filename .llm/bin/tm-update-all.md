---
title: tm-update-all
path: bin/tm-update-all
type: script
purpose: Updates the Tool Manager core and all installed plugins.
dependencies:
  - bin/tm-update-self
  - bin/tm-plugin-each
tags:
  - core
  - plugin
  - management
  - update
---

## Overview
This script provides a single command to update the entire Tool Manager ecosystem. It first updates the core `tool-manager` scripts and then proceeds to update every installed plugin.

## Design Philosophy
The script is designed for simplicity and convenience, orchestrating two other specialized scripts to perform its task. It ensures that the core system is updated first before updating the plugins, which helps maintain a stable environment. It uses `tm-plugin-each` to efficiently iterate through all installed plugins.

## Key Logic
1.  **Update Self:** The script first executes `tm-update-self`. This command is responsible for pulling the latest changes for the Tool Manager's own Git repository. If this command fails, the script aborts to prevent updating plugins in a potentially broken core environment.
2.  **Update Plugins:** After the core has been successfully updated, the script calls `tm-plugin-each --installed git pull --ff-only`. This command iterates through every installed plugin and runs `git pull --ff-only` within its directory, updating it to the latest version from its remote repository. The `--ff-only` flag ensures that the update will only succeed if it is a fast-forward, preventing merges that could corrupt the plugin's state.

## Usage
```bash
# Update the tool-manager and all installed plugins
tm-update-all
```

## Related
- `bin/tm-update-self` (Updates the core Tool Manager)
- `bin/tm-plugin-each` (Used to iterate through and update each plugin)