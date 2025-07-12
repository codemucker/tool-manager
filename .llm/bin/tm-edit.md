---
title: tm-edit
path: bin/tm-edit
type: script
purpose: Opens a plugin's source directory in a preferred editor, optionally generating a VS Code workspace for a better development experience.
dependencies:
  - bin/.tm.script.sh
  - bin/.tm.cfg.sh
  - bin/.tm.plugins.sh
tags:
  - editing
  - plugin
  - development
  - vscode
  - cli
---

## Overview
This script is a developer-focused utility that streamlines the process of editing a plugin's source code. It can be pointed at any installed plugin (or the core tool-manager itself) and will open the plugin's installation directory in the user's configured editor. It has special integration for Visual Studio Code, allowing it to generate a `.code-workspace` file on the fly.

## Design Philosophy
The script is designed for convenience and to provide a rich development context. The core idea is to abstract away the need for a developer to know the exact installation path of a plugin. They can simply refer to it by name.

The VS Code workspace generation is a key feature. Instead of just opening a single folder, it creates a multi-root workspace that includes not only the plugin's source code but also its configuration, state, and cache directories, as well as the main tool-manager directories. This gives the developer a holistic view of all the relevant files for that plugin, which is invaluable for debugging and understanding how the plugin interacts with the broader `tm` ecosystem.

## Key Logic
1.  **Argument Parsing:** The script uses `_parse_args` to determine the target plugin, the desired editor, and whether to open a console (`bash`) instead of a graphical editor.
2.  **Target Resolution:**
    -   If the `--tm` flag is used or no plugin name is given, it targets the main tool-manager project.
    -   Otherwise, it uses `_tm::plugins::enabled::get_by_name` to find the fully qualified name of the plugin, supporting partial matches.
    -   It then uses `_tm::parse::plugin` to load the full details of the target into an associative array.
3.  **Directory Navigation:** It changes the current directory to the plugin's installation path (`install_dir`).
4.  **Editor Invocation:**
    -   If the editor is `bash`, it simply starts a new interactive shell in that directory.
    -   If the editor is `code` (and the workspace feature is enabled via `TM_VSCODE_EDIT_USING_WORKSPACE`), it calls `__generate_vscode_workspace_file`.
    -   Otherwise, it invokes the specified editor command, telling it to open the current directory (`.`).
5.  **`__generate_vscode_workspace_file()`:**
    -   This internal function writes a JSON `.code-workspace` file to a cache directory.
    -   The JSON content defines a multi-root workspace, adding entries for the plugin's home, config, state, and cache, as well as the global `tm` directories.
    -   It also configures workspace settings to exclude volatile directories (like cache and state) from search results, improving performance.

## Usage
```bash
# Open the 'my-plugin' directory in the default editor (e.g., code)
tm-edit my-plugin

# Open the core tool-manager project in vim
tm-edit --tm --editor vim

# Open a bash console in the 'other-plugin' directory
tm-edit other-plugin --console
```

## Related
-   `.llm/bin/.tm.plugins.sh.md` (Used to find and resolve plugin names)
-   `.llm/bin/.tm.cfg.sh.md` (Used to get the configured default editor)
-   `.llm/bin/tm-edit-cfg.md` (A similar script focused specifically on configuration files)