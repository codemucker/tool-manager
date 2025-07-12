---
title: tm-edit-console
path: bin/tm-edit-console
type: script
purpose: Acts as an alias for `tm-edit --console` to open an interactive shell in a plugin's source directory.
dependencies:
  - bin/tm-edit
tags:
  - editing
  - plugin
  - development
  - console
  - alias
  - cli
---

## Overview
This script is a simple convenience wrapper. It provides a dedicated command for the common task of opening a terminal session directly within a plugin's source code directory.

## Design Philosophy
The script follows the principle of providing user-friendly aliases for common combinations of command-line flags. It contains no logic of its own and simply calls the `tm-edit` script with the `--console` flag prepended to the argument list.

## Key Logic
1.  **Delegation:** The script executes `tm-edit --console "$@"` a, passing along all arguments it received to the `tm-edit` script, ensuring the `--console` flag is always present.

## Usage
The usage is identical to `tm-edit`, but it will always open a bash console instead of a graphical editor.

```bash
# Open a console in the 'my-plugin' directory
tm-edit-console my-plugin

# Open a console in the core tool-manager project directory
tm-edit-console --tm
```

## Related
-   `.llm/bin/tm-edit.md` (The script that this command is an alias for)