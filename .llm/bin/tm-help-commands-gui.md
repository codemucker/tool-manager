---
title: tm-help-commands-gui
path: bin/tm-help-commands-gui
type: script
purpose: Acts as a convenient alias for `tm-help-commands --gui` to launch the interactive HTML help page.
dependencies:
  - bin/tm-help-commands
tags:
  - help
  - documentation
  - gui
  - alias
  - cli
---

## Overview
This script is a simple convenience wrapper. It provides a dedicated command for launching the graphical, web-based version of the command help system.

## Design Philosophy
The script follows the principle of providing user-friendly aliases for common combinations of command-line flags. It contains no logic of its own and simply calls the `tm-help-commands` script with the `--gui` flag.

## Key Logic
1.  **Delegation:** The script executes `tm-help-commands --gui`, which handles the generation and serving of the HTML help page.

## Usage
The script is run directly from the command line and takes no arguments.

```bash
tm-help-commands-gui
```

This is functionally identical to running `tm-help-commands --gui`.

## Related
-   `.llm/bin/tm-help-commands.md` (The script that this command is an alias for)