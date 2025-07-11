---
title: env-tm-shellspec
path: bin-defaults/env-tm-shellspec
type: script
purpose: A shebang runner that executes a ShellSpec test script within the tool-manager environment.
dependencies:
  - .bashrc_script
  - bin/.tm.venv.sh
tags:
  - testing
  - shellspec
  - runner
  - environment
---

## Overview
This script acts as a specialized shebang interpreter (`#!/usr/bin/env env-tm-shellspec`) for running tests written with the ShellSpec BDD testing framework. Its primary function is to ensure that the test script executes within a fully initialized tool-manager environment. It also automatically installs ShellSpec if it's not already present.

## Design Philosophy
The script is designed to provide a seamless testing experience for shell scripts within the tool-manager ecosystem using ShellSpec. It abstracts away the setup and dependency management for the framework, allowing developers to focus on writing BDD-style tests. By using this runner, test scripts can confidently use tool-manager functions (`_include`, `_log`, etc.) just as regular plugin scripts would.

## Key Logic
1.  **Environment Initialization:** It sources the tool-manager's `.bashrc_script` to set up the basic environment.
2.  **Argument Parsing:** The script intelligently parses its arguments to distinguish between arguments for the `shellspec` runner itself and arguments for the test script being executed. It identifies the test script's path by looking for the first argument that is an executable file.
3.  **ShellSpec Installation:** It checks if the `shellspec` command is available. If not, it downloads and installs it into the tool-manager's shared packages directory (`$TM_PACKAGES_DIR/shellspec`) and adds its `bin` directory to the `PATH`.
4.  **Execution:** It sets a specific log name for the test run based on the script's filename and then uses `exec` to replace itself with the `shellspec` command, passing the parsed runner arguments, the script path, and the script's own arguments.

## Usage
To use this runner, start your ShellSpec test script with the following shebang line:

```shell
#!/usr/bin/env env-tm-shellspec

Describe "my tool-manager script"
  It "can use tool-manager logging"
    When run _info "This is an info message from a ShellSpec test"
    The output should include "This is an info message"
  End
End
```

Then, make the script executable (`chmod +x my_spec.sh`) and run it directly:

```bash
./my_spec.sh
```

## Related
- [ShellSpec](https://shellspec.info/)