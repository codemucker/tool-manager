---
title: tm-space-create
path: bin/tm-space-create
type: script
purpose: Creates a new, isolated Tool Manager "space".
dependencies:
  - bin/.tm.script.sh
  - bin/.tm.space.sh
tags:
  - core
  - space
  - environment
  - management
---

## Overview
This script creates a new Tool Manager space. A space is an independent environment with its own configuration, plugins, and services, allowing users to maintain separate contexts for different projects or workflows.

## Design Philosophy
The script is designed to be an interactive and user-friendly way to bootstrap a new space. It prompts the user for essential information like a unique `key` and a human-readable `label` if they are not provided as arguments. It then creates the necessary directory structure and configuration files that define the new space, ensuring it is correctly registered with the Tool Manager.

## Key Logic
1.  **Argument Parsing & Interactive Prompts:** The script parses command-line arguments for the space's `key`, `label`, `guid`, and other configuration options. If the key or label are missing, it interactively prompts the user for them using the `__prompt_value` helper function.
2.  **File and Directory Path Generation:** It constructs the paths for the space's main definition file (e.g., `$TM_SPACE_DIR/.space.my-key.conf`) and its dedicated configuration directory (e.g., `$TM_SPACE_DIR/my-key`).
3.  **Conflict Check:** It checks if a space with the same key already exists. If a file or directory is found, it prompts the user for confirmation before deleting the old space to make way for the new one.
4.  **File Creation:**
    *   It creates the main space definition file (`.space.my-key.conf`), which stores the key, GUID, label, and the path to its directory. This file is used by `tm-space` and `tm-space-ls` to find and identify the space.
    *   It creates the space's dedicated directory.
    *   Inside the space's directory, it creates another configuration file (`.space.conf`) that contains the same identifying information, to be used by processes running within that space's context.
5.  **UUID Generation:** If a GUID is not provided via the `--guid` flag, it automatically generates a new one using `uuidgen`.

## Usage
```bash
# Create a new space interactively
tm-space-create

# Create a new space with a specified key and label
tm-space-create --key my-project --label "My Awesome Project"
```

## Related
- `.llm/bin/.tm.space.sh.md` (Contains the core logic for managing spaces)
- `bin/tm-space` (Switches to a created space)
- `bin/tm-space-ls` (Lists all created spaces)