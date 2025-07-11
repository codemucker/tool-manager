---
title: env-tm-bashunit
path: bin-defaults/env-tm-bashunit
type: script
purpose: A shebang runner that executes a bashunit test script within the tool-manager environment.
dependencies:
  - .bashrc_script
  - bin/.tm.venv.sh
tags:
  - testing
  - bashunit
  - runner
  - environment
---

## Overview
This script acts as a specialized shebang interpreter (`#!/usr/bin/env env-tm-bashunit`) for running tests written with the `bashunit` testing framework. Its primary function is to ensure that the test script executes within a fully initialized tool-manager environment, with access to all its libraries and utilities. It also automatically installs `bashunit` if it's not already present.

## Design Philosophy
The script is designed to provide a seamless testing experience for bash scripts within the tool-manager ecosystem. It abstracts away the setup and dependency management for `bashunit`, allowing developers to focus on writing tests. By using this runner, test scripts can confidently use tool-manager functions (`_include`, `_log`, etc.) just as regular plugin scripts would.

## Key Logic
1.  **Environment Initialization:** It sources the tool-manager's `.bashrc_script` to set up the basic environment and make core functions available.
2.  **Argument Parsing:** The script intelligently parses its arguments to distinguish between arguments for the `bashunit` runner itself and arguments for the test script being executed. It identifies the test script's path by looking for the first argument that is an executable file.
3.  **Bashunit Installation:** It checks if the `bashunit` command is available. If not, it downloads and installs it into the tool-manager's shared packages directory (`$TM_PACKAGES_DIR/bashunit`) and adds it to the `PATH`.
4.  **Execution:** It sets a specific log name for the test run based on the script's filename and then uses `exec` to replace itself with the `bashunit` command, passing the parsed runner arguments, the script path, and the script's own arguments.

## Usage
To use this runner, start your `bashunit` test script with the following shebang line:

```bash
#!/usr/bin/env env-tm-bashunit

# Your bashunit tests go here
test_example() {
  assert_true 0 -eq 0
}
```

Then, make the script executable (`chmod +x my_test.sh`) and run it directly:

```bash
./my_test.sh
```

## Related
- `bashunit` (The testing framework: https://bashunit.typeddevs.com/)