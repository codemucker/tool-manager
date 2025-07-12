---
title: tm-uninstall
path: bin/tm-uninstall
type: script
purpose: Completely removes the Tool Manager and all related files from the system.
dependencies:
  - uninstall.sh
tags:
  - core
  - uninstall
  - management
---

## Overview
This script is a simple wrapper that executes the main `uninstall.sh` script located in the Tool Manager's home directory (`$TM_HOME`). It is the designated command for completely removing the entire Tool Manager installation, including all plugins, configurations, and the core scripts themselves.

## Design Philosophy
The script provides a consistent and discoverable command within the `tm-*` namespace for performing the uninstallation. Rather than requiring the user to know the location of the main `uninstall.sh` script, `tm-uninstall` acts as a simple and memorable alias. It directly passes any arguments it receives to the underlying script, allowing for options like `--force` to be used.

## Key Logic
1.  **Execution:** The script calls the `uninstall.sh` script located at the root of the Tool Manager installation (`${TM_HOME:-$HOME/.tool-manager}/uninstall.sh`).
2.  **Argument Forwarding:** It passes all of its own command-line arguments (`$@`) directly to the `uninstall.sh` script.

## Usage
```bash
# Run the uninstaller, which will prompt for confirmation
tm-uninstall

# Run the uninstaller and skip all confirmation prompts
tm-uninstall --force
```

## Related
- `uninstall.sh` (The core script that performs the uninstallation logic)
- `install.sh` (The script used for the initial installation)