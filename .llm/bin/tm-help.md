---
title: tm-help
path: bin/tm-help
type: script
purpose: Displays a static, high-level overview of the main tool-manager commands.
dependencies: []
tags:
  - help
  - documentation
  - cli
---

## Overview
This script provides a quick reference guide for the most common and important `.tool-manager` commands. It serves as a starting point for users to discover the system's core functionalities.

## Design Philosophy
The script is designed to be a simple and static "cheat sheet." It uses a `cat` command with a `heredoc` to print a pre-formatted block of text to the console. This approach is extremely simple and requires no complex logic, making it a reliable and low-maintenance way to provide basic help information. It intentionally points to more dynamic help commands (like `tm-help-commands`) for comprehensive details.

## Key Logic
1.  **Heredoc:** The script uses `cat << EOF` to start a "here document."
2.  **Static Text:** All lines between the initial `EOF` and the final `EOF` are printed verbatim to standard output. This text includes a curated list of key commands and brief descriptions of their purpose.

## Usage
The script is intended to be run directly by the user from the command line.

```bash
tm-help
```

The output will be a simple list of commands like:
```
tm-help-commands                      # all available commands.
tm-plugin-install             # install a plugin from the registry or direct from github
...
```

## Related
-   `.llm/bin/tm-help-commands.md` (A more dynamic help command that this script points to)
-   `.llm/bin/tm-help-cfg.md` (Provides help specifically for configuration)