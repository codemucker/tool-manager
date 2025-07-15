---
title: lib.source.sh
path: lib-shared/tm/bash/lib.source.sh
type: library
purpose: Provides a robust and intelligent system for sourcing shell scripts and libraries.
dependencies:
  - lib-shared/tm/bash/lib.log.sh
tags:
  - source
  - include
  - dependency
  - bootstrap
  - library
---

## Overview
This library provides a sophisticated replacement for Bash's built-in `source` command. It is the backbone of the tool manager's dependency management system. It allows scripts to include other scripts using various pathing strategies (absolute, relative, and a special `@` notation for libraries) and ensures that files are only sourced once per session to prevent re-definition errors and improve performance.

## Design Philosophy
The core philosophy is to create a reliable and developer-friendly dependency inclusion mechanism. It abstracts away the complexity of path resolution. A developer can simply `_include_once @tm/lib.args.sh` without needing to know the absolute path to that library. The "once" functionality is critical, as it allows complex dependency graphs (where script A includes B and C, and B also includes C) to be resolved safely and efficiently. The library is also designed to be self-bootstrapping; if it detects that its own dependencies (like the logger) are not yet loaded, it will load them itself.

## Key Logic
1.  **Sourcing Guards:** The library maintains a global associative array, `__tm_sourced`, which tracks the full paths of all files that have been sourced. The `_tm::__source` function checks this array before sourcing a file if the `once` flag is set.
2.  **Path Resolution (`__include`):** This is the most complex part of the library. It interprets the path provided by the developer:
    *   **`@tm/...`:** Identifies a core tool manager library. It resolves this to `$TM_LIB_BASH/<lib_name>`.
    *   **`@vendor/...`:** Identifies a plugin-provided library. It resolves this to `$TM_PLUGINS_LIB_DIR/<vendor>/bash/<lib_name>`.
    *   **`@this/...`:** A special case for a library including another library from the *same* plugin. This requires more complex logic to determine the original plugin's home directory.
    *   **`/path/to/file`:** An absolute path is used as-is.
    *   **`relative/path.sh`:** A relative path is resolved relative to the location of the *calling script* (`BASH_SOURCE[1]`), not the current working directory. This is a key feature that makes includes reliable regardless of where a script is executed from.
3.  **Path Caching:** To avoid repeatedly calculating the directory of the calling script (`dirname`), it caches the result in another associative array, `__tm_source_to_dir`.
4.  **Core Sourcing (`__source`):** This internal function is the final step. It checks the "once" guard, marks the file as sourced in the `__tm_sourced` array, and then uses the `builtin source` command to actually load the file. It also includes robust error handling to report exactly which script failed to source a dependency and from where it was called.
5.  **Public Functions:** The library exposes four simple, public functions: `_source`, `_source_once`, `_include`, and `_include_once`. The `include` variants are generally preferred as they handle the relative and `@` path logic.

## Usage
```bash
# In a script, include the core argument parsing library only once.
_tm::source::include_once @tm/lib.args.sh

# Include a script relative to the current script's location.
_tm::source::include_once "./my-helper-script.sh"

# Include a library provided by an installed plugin from another vendor.
_tm::source::include_once @other-vendor/lib.api.sh
```

## Related
- This is a foundational library that is a dependency for almost every other script in the system, as it is the primary mechanism for loading them.