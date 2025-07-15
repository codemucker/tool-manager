---
title: tm-edit-cfg
path: bin/tm-edit-cfg
type: script
purpose: Acts as an alias for the `tm-plugin-cfg` command to open a plugin's configuration file in an editor.
dependencies:
  - bin/tm-plugin-cfg
tags:
  - configuration
  - editing
  - alias
  - cli
---

## Overview
This script is a simple convenience wrapper. It provides an alternative, more intuitive name (`tm-edit-cfg`) for the `tm-plugin-cfg` command. Its sole purpose is to improve user experience by offering a command name that clearly describes its action.

## Design Philosophy
The script follows the principle of providing user-friendly aliases for more complex or less intuitively named commands. It contains no logic of its own and simply passes all of its command-line arguments directly to the `tm-plugin-cfg` script.

## Key Logic
1.  **Delegation:** The script executes `tm-plugin-cfg "$@"` a, passing along all arguments it received to the target script.

## Usage
The usage is identical to `tm-plugin-cfg`.

```bash
# Edit the configuration for 'my-plugin'
tm-edit-cfg my-plugin

# Edit the tool-manager's global configuration
tm-edit-cfg --tm
```

## Related
-   `.llm/bin/tm-plugin-cfg.md` (The script that this command is an alias for)