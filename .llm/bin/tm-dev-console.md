---
title: tm-dev-console
path: bin/tm-dev-console
type: script
purpose: Starts an interactive bash shell specifically for developing the tool-manager itself.
dependencies:
  - bin/.tm.boot.sh
tags:
  - development
  - console
  - debugging
  - internal
---

## Overview
This script is a convenience utility for developers working on the `.tool-manager` core. It launches a new, interactive bash session that is pre-configured with a development-centric environment. This includes adding the internal and development-specific binary directories to the `PATH`, giving the developer direct access to test scripts and internal functions.

## Design Philosophy
The script is designed to provide a quick and easy entry point into a fully-featured development "sandbox." Instead of requiring a developer to manually export `PATH` variables, this script handles the setup and then drops them into an interactive shell. Using `bash --init-file` is a clean way to ensure the `.tm.boot.sh` script is sourced for the new session, initializing the entire `tm` environment correctly.

## Key Logic
1.  **Shebang:** It uses `#!/usr/bin/env bash` as it's a standalone script for launching a new shell.
2.  **Path Extension:** It checks for the existence of `$TM_HOME/bin-internal` and `$TM_HOME/bin-dev` directories. If they exist, it prepends them to the current `PATH` environment variable.
3.  **Launch Interactive Shell:** It executes `bash --init-file "$TM_BIN/.tm.boot.sh" -i`.
    -   `--init-file`: This tells `bash` to source the specified file (`.tm.boot.sh`) upon startup, which loads the entire tool-manager ecosystem.
    -   `-i`: This flag ensures the new shell is interactive, providing the user with a command prompt.

## Usage
This script is intended to be run directly by a developer from their terminal.

```bash
# From the root of the .tool-manager project
./bin/tm-dev-console

# The user will now be in a new bash session.
# They can now directly run commands from bin-internal/ and bin-dev/
# and all tm-* functions will be available.
```

## Related
-   `.llm/bin/.tm.boot.sh.md` (The script that is sourced to initialize the development session)
-   `.llm/bin-dev/` (Directory containing development-specific scripts made available by this console)
-   `.llm/bin-internal/` (Directory containing internal scripts made available by this console)