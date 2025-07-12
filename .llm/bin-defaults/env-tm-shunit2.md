---
title: env-tm-shunit2
path: bin-defaults/env-tm-shunit2
type: script
purpose: A shebang runner that executes a shUnit2 test script within the tool-manager environment.
dependencies:
  - .bashrc_script
  - bin/.tm.venv.sh
tags:
  - testing
  - shunit2
  - runner
  - environment
---

## Overview
This script acts as a specialized shebang interpreter (`#!/usr/bin/env env-tm-shunit2`) for running tests written with the shUnit2 test framework. Its primary function is to ensure that the test script executes within a fully initialized tool-manager environment. It also automatically downloads and installs shUnit2 if it's not already present.

## Design Philosophy
The script is designed to provide a seamless testing experience for shell scripts using shUnit2. It abstracts away the setup and dependency management for the framework, allowing developers to focus on writing xUnit-style tests for their shell scripts. By using this runner, test scripts can confidently use tool-manager functions (`_include`, `_log`, etc.) and are guaranteed to have shUnit2 available.

## Key Logic
1.  **Environment Initialization:** It sources the tool-manager's `.bashrc_script` to set up the basic environment.
2.  **Argument Parsing:** The script intelligently parses its arguments to find the path to the test script.
3.  **shUnit2 Installation:** It checks if the `shunit2` script exists in the tool-manager's shared packages directory. If not, it downloads the official tarball from GitHub, extracts it, and makes it available on the `PATH`.
4.  **Execution:** Unlike other test runners, this script executes the test script directly using `bash`. It is the responsibility of the test script itself to `source` the `shunit2` script. This runner simply ensures it's available to be sourced.

## Usage
To use this runner, start your shUnit2 test script with the following shebang line. Crucially, your script must then source the `shunit2` script.

```shell
#!/usr/bin/env env-tm-shunit2

test_my_function() {
  _info "This is a log message from a test"
  assertEquals "The strings should be equal" "a" "a"
}

# Source shunit2 to run the tests
. shunit2
```

Then, make the script executable (`chmod +x my_test.sh`) and run it directly:

```bash
./my_test.sh
```

## Related
- [shUnit2](https://github.com/kward/shunit2)