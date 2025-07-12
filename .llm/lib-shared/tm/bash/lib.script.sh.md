---
title: lib.script.sh
path: lib-shared/tm/bash/lib.script.sh
type: library
purpose: Provides a standard, robust starting point for all executable scripts.
dependencies:
  - lib-shared/tm/bash/lib.common.sh
tags:
  - bootstrap
  - boilerplate
  - setup
  - script
---

## Overview
This script is intended to be the first thing sourced by almost every executable script in the tool manager ecosystem. It establishes a safe and consistent execution environment by setting shell options and loading all the common library functions.

## Design Philosophy
The script's purpose is to eliminate boilerplate and enforce best practices from the very first line of any script. By sourcing this single file, a script developer immediately gets:
1.  **Safety:** `set -Eeuo pipefail` is enabled, which makes scripts more robust by causing them to exit immediately on errors or unset variables.
2.  **Consistency:** A standard set of foundational libraries is loaded via `lib.common.sh`, ensuring that core utilities like logging and argument parsing are always available.
This approach simplifies script creation and reduces the likelihood of common Bash scripting errors.

## Key Logic
1.  **Set Shell Options:** It executes `set -Eeuo pipefail`.
    *   `-E`: Ensures `ERR` traps are inherited by shell functions.
    *   `-e`: Exits immediately if a command exits with a non-zero status.
    *   `-u`: Treats unset variables as an error when substituting.
    *   `-o pipefail`: The return value of a pipeline is the status of the last command to exit with a non-zero status, or zero if no command exited with a non-zero status.
2.  **Include Common Libraries:** It calls `_tm::source::include_once @tm/lib.common.sh`, which in turn loads the entire suite of core libraries (`lib.log.sh`, `lib.args.sh`, `lib.parse.sh`, etc.).

## Usage
This script is not meant to be called directly. Instead, it should be sourced at the beginning of other scripts.

```bash
#!/usr/bin/env tm-bash
#
# My new tool manager script

# Source the standard script setup
_tm::source::include_once @tm/lib.script.sh

# Now the script can safely begin, with all common functions available.
_info "My script has started."
# ... rest of the script logic ...
```

## Related
- `.llm/lib-shared/tm/bash/lib.common.sh.md` (This is the main dependency, which pulls in all other core libraries).