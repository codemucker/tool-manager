---
title: tm-plugin-each
path: bin/tm-plugin-each
type: script
purpose: Executes a specified command within the directory of each selected plugin.
dependencies:
  - lib-shared/tm/bash/lib.script.sh
  - lib-shared/tm/bash/lib.plugins.sh
  - lib-shared/tm/bash/lib.parse.sh
  - lib-shared/tm/bash/lib.log.sh
tags:
  - plugin
  - iteration
  - git
  - batch
---

## Overview
This script is a utility for performing batch operations across multiple plugins. It can iterate through all installed, all enabled, or all available plugins and run a user-provided command (like `git pull` or `npm install`) within each plugin's directory. This is essential for maintenance tasks like updating all plugins at once.

## Design Philosophy
The script is designed as a focused iterator. It adheres to the Unix philosophy by doing one thing well: looping through a list of directories and executing a command. The core logic for identifying plugins and parsing their details is delegated to the `lib.plugins.sh` and `lib.parse.sh` libraries, keeping this script clean and focused on its primary task. It also contains a small convenience feature to automatically prepend `git` for common Git commands.

## Key Logic
1.  **Argument Parsing:** The script first parses its command-line arguments to determine the filter mode (`--installed`, `--enabled`, `--available`), the command to execute, and any options like `--parallel` or `--quiet`.
2.  **Plugin Discovery:** Based on the filter, it calls the appropriate function from `lib.plugins.sh` to get a list of plugin IDs to process.
3.  **Iteration:** It loops through each plugin ID. For each one, it:
    a.  Resolves the plugin ID to its installation directory.
    b.  Verifies the directory exists and is a Git repository.
    c.  Changes into the directory.
    d.  Executes the user-provided command.
    e.  Changes back to the original directory.
4.  **Execution:** The `__invoke` helper function handles whether the command is run in the foreground (default) or background (`--parallel`).

## Usage
```bash
# Check the git status of all installed plugins
tm-plugin-each git status

# Pull the latest changes for all enabled plugins
tm-plugin-each -e git pull

# Run a command in parallel across all plugins
tm-plugin-each -p npm install
```

## Related
- `.llm/lib-shared/tm/bash/lib.plugins.sh.md` (Provides the plugin lists)
- `.llm/lib-shared/tm/bash/lib.parse.sh.md` (Handles plugin ID parsing)