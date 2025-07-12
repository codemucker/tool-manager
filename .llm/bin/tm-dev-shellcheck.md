---
title: tm-dev-shellcheck
path: bin/tm-dev-shellcheck
type: script
purpose: Runs the ShellCheck static analysis tool on Tool Manager or plugin scripts.
dependencies:
  - bin/.tm.script.sh
  - bin/.tm.plugin.sh
  - bin/.tm.plugins.sh
tags:
  - core
  - plugin
  - test
  - development
  - lint
---

## Overview
This script provides a convenient wrapper around the `shellcheck` command-line tool to perform static analysis on shell scripts within the Tool Manager ecosystem. It can target the core `tool-manager` scripts, the scripts within a specific plugin, or any given directory.

## Design Philosophy
The script is designed to make it easy to maintain code quality and catch common shell scripting errors. It automates the process of finding all relevant script files and running `shellcheck` on them. It also includes a helper function to attempt to auto-install `shellcheck` if it's not found, lowering the barrier to entry for developers. The script acts as a transparent proxy for `shellcheck` options, allowing users to pass flags like `--format` or `--exclude` directly to the underlying tool.

## Key Logic
1.  **ShellCheck Installation:** The `__ensure_shellcheck_installed` function checks if the `shellcheck` command is available. If not, it attempts to install it using a common system package manager (e.g., `apt-get`, `brew`, `dnf`).
2.  **Target Resolution:** The script determines the directories to scan based on the command-line arguments:
    *   If no target is given or if it's `tool-manager`, it compiles a list of all core script directories (`$TM_HOME/bin`, `$TM_HOME/lib-shared/tm/bash`, etc.).
    *   If the target is a plugin name, it resolves the plugin's installation directory and targets its `bin`, `lib-shared`, and `test` subdirectories.
    *   If the target is a directory path, it uses that path directly.
3.  **File Discovery:** It uses `find` to recursively search the target directories for files. To avoid checking non-shell files, it specifically looks for files that have a `bash` or `env-tm-bash` shebang on the first line.
4.  **Command Execution:** It gathers all discovered file paths into an array and executes the `shellcheck` command, passing the file list and any user-provided `shellcheck` options (like `--format`, `--severity`, `--exclude`).

## Usage
```bash
# Run shellcheck on all core tool-manager scripts
tm-dev-shellcheck

# Run shellcheck on a specific plugin
tm-dev-shellcheck my-vendor/my-plugin

# Run shellcheck on a specific directory
tm-dev-shellcheck ./my-custom-scripts/

# Pass options directly to shellcheck, e.g., to get JSON output
tm-dev-shellcheck --format json
```

## Related
- `bin/tm-dev-tests` (For running functional/unit tests)