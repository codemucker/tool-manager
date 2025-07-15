---
title: lib.path.sh
path: lib-shared/tm/bash/lib.path.sh
type: library
purpose: Provides utility functions for manipulating the system PATH and displaying file system trees.
dependencies:
  - lib-shared/tm/bash/lib.log.sh
tags:
  - path
  - tree
  - filesystem
  - utility
---

## Overview
This library contains helper functions related to file system paths. It includes a function to safely add one or more directories to the system's `PATH` environment variable, preventing duplicates. It also provides a pure Bash implementation of the `tree` command, which can visually display a directory structure and optionally execute a callback function for each file it finds.

## Design Philosophy
The library is designed to provide common, OS-agnostic path-related functionality. The `add_to_path` function is a crucial utility for plugins that need to expose their own binaries, ensuring they can be called from anywhere without requiring manual `PATH` manipulation by the user. The `tree` function is a notable piece of design, as it reimplements a common system command in pure Bash. This avoids a dependency on the `tree` package being installed on the user's system, making scripts that use it more portable and self-contained.

## Key Logic
1.  **`_tm::path::add_to_path`:**
    *   Accepts one or more directory paths as arguments.
    *   It splits the current `$PATH` variable by the colon (`:`) delimiter into an array.
    *   For each new path provided, it iterates through the existing paths to check if it's already present.
    *   If the new path does not exist in the current `$PATH`, it is prepended to the `PATH` variable.
    *   Finally, it exports the modified `PATH`.
2.  **`_tm::path::tree`:**
    *   This is the public-facing function that initializes the tree traversal. It checks for terminal color support and sets color variables accordingly.
    *   It calls the internal recursive helper function, `__tree_recursive`, to do the actual work.
3.  **`__tree_recursive` (Internal Helper):**
    *   This function takes the current directory, a prefix string for indentation (e.g., `├── `), and an optional callback function name.
    *   It uses `find` to get a sorted list of all files and directories in the current path (at a max depth of 1).
    *   It iterates through the entries, determining the correct branch prefix (`├── ` for intermediate entries, `└── ` for the last one).
    *   If an entry is a directory, it prints its name and calls itself recursively, passing the new path and an updated indentation prefix.
    *   If an entry is a file, it prints its name. If a callback function was provided, it executes the callback, passing the full file path as an argument.

## Usage
```bash
# Add a plugin's bin directory to the path
_tm::path::add_to_path "/path/to/my/plugin/bin"

# Display a tree of the current directory
_tm::path::tree

# Display a tree of a specific directory and run a callback for each file
_file_callback() {
  local file_path="$1"
  local prefix="$2"
  echo -e "${prefix}  -> Found file: ${file_path}"
}

_tm::path::tree "/some/other/dir" "_file_callback"
```

## Related
- This library is a foundational utility, often used during the bootstrap process or by plugin installation scripts to modify the environment.