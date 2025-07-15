---
title: env-tm-bats
path: bin-defaults/env-tm-bats
type: script
purpose: A shebang runner that executes a BATS test script within the tool-manager environment.
dependencies:
  - .bashrc_script
  - bin/.tm.venv.sh
  - lib-shared/tm/bash/lib.invoke.sh
tags:
  - testing
  - bats
  - runner
  - environment
---

## Overview
This script acts as a specialized shebang interpreter (`#!/usr/bin/env env-tm-bats`) for running tests written with the BATS (Bash Automated Testing System) framework. Its primary function is to ensure that the test script executes within a fully initialized tool-manager environment. It handles the automatic installation of BATS and its common support libraries (`bats-support`, `bats-assert`) if they are not already present.

## Design Philosophy
The script is designed to provide a seamless testing experience for bash scripts using BATS within the tool-manager ecosystem. It abstracts away the setup and dependency management for the BATS framework, allowing developers to focus on writing tests. By using this runner, test scripts can confidently use tool-manager functions (`_include`, `_log`, etc.) and are guaranteed to have a consistent BATS environment.

## Key Logic
1.  **Environment Initialization:** It sources the tool-manager's `.bashrc_script` and the invoke/installer library `lib.invoke.sh`.
2.  **Argument Parsing:** The script intelligently parses its arguments to distinguish between arguments for the `bats` runner itself (like `--tap`) and the path to the test script and its own arguments. It identifies the test script's path by looking for the first argument that is an executable file.
3.  **BATS Installation:** It calls the `_tm::invoke::ensure_installed bats` function (from `lib.invoke.sh`) which checks for the existence of `bats`, `bats-support`, and `bats-assert`, and installs them via `npm` if they are missing.
4.  **Execution:** It sets a specific log name for the test run based on the script's filename and then uses `exec` to replace itself with the `bats` command, passing the parsed runner arguments, the script path, and the script's own arguments.

## Usage
To use this runner, start your BATS test script with the following shebang line:

```bash
#!/usr/bin/env env-tm-bats

load 'lib/bats-support/load'
load 'lib/bats-assert/load'

@test "A test that uses tool-manager logging" {
  _info "This is an info message from a BATS test"
  run true
  assert_success
}
```

Then, make the script executable (`chmod +x my_test.bats`) and run it directly:

```bash
./my_test.bats
```

## Related
- [BATS (Bash Automated Testing System)](https://github.com/bats-core/bats-core)
- `.llm/lib-shared/tm/bash/lib.invoke.sh.md` (Provides the install logic for BATS installation)