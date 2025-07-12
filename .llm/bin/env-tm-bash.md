---
title: env-tm-bash
path: bin/env-tm-bash
type: script
purpose: Executes a bash script within the initialized tool-manager environment, ensuring all core libraries and functions are available.
dependencies:
  - .bashrc_script
  - bin/.tm.venv.sh
tags:
  - environment
  - runner
  - bash
  - core
---

## Overview
This script acts as a wrapper to execute any bash script within a fully initialized `.tool-manager` environment. It ensures that core libraries (like logging, parsing, and utilities) and environment variables are loaded before the target script runs. This is the standard entrypoint for running standalone or user-provided scripts that need to interact with the `tm` ecosystem.

## Design Philosophy
The script is designed to be a lightweight and robust runner. Its primary goal is to provide a consistent execution context with minimal overhead. It avoids creating unnecessary subshells by `source`-ing the target script directly into the current process. This improves performance and allows errors and stack traces from the target script to be more easily debugged. It intelligently separates its own arguments from the arguments meant for the target script.

## Key Logic
1.  **Environment Bootstrap:** It begins by sourcing `$TM_HOME/.bashrc_script` and `$TM_BIN/.tm.venv.sh` to set up the minimal required `tm` environment.
2.  **Argument Parsing:** It iterates through the command-line arguments to locate the path to the target script. It uses the heuristic that the script path is the first argument that corresponds to an existing, executable file.
3.  **Argument Segregation:** All arguments before the identified script path are considered arguments for the `env-tm-bash` runner itself (though none are currently implemented). All arguments after the script path are collected as arguments for the target script.
4.  **Execution:**
    a. It sets the `TM_LOG_NAME` environment variable to the base name of the target script to standardize log output.
    b. It uses `set --` to overwrite the shell's positional parameters (`$@`) with the arguments intended for the target script.
    c. It `source`s the target script, which executes it within the current shell's context, giving it access to all the bootstrapped `tm` functions and variables.

## Usage
```bash
# Execute a custom script that relies on tool-manager functions
env-tm-bash /path/to/my/custom_script.sh --arg1 --arg2="some value"

# It can be used in a shebang line for standalone scripts
#!/home/bert-sbs/.tool-manager/bin/env-tm-bash
#
# _log "This script now has access to tm logging functions"
```

## Related
- `.llm/.bashrc_script.md` (Provides core functions like `_log` and `_fail`)
- `.llm/bin/.tm.venv.sh.md` (Manages virtual environments)