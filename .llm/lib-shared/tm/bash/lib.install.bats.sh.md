---
title: lib.prog.bats.sh
path: lib-shared/tm/bash/lib.prog.bats.sh
type: library
purpose: Manages the installation of the BATS testing framework and its common extensions.
dependencies:
  - lib-shared/tm/bash/lib.log.sh
  - lib-shared/tm/bash/lib.path.sh
tags:
  - test
  - bats
  - install
  - setup
  - framework
---

## Overview
This library provides a single function, `_tm::install::bats`, responsible for setting up the BATS (Bash Automated Testing System) framework. It ensures that `bats-core`, `bats-support`, and `bats-assert` are available for use in test scripts, installing them from their official GitHub repositories if they are not already present.

## Design Philosophy
The script is designed to be an on-demand installer and environment loader for the BATS testing ecosystem. It abstracts the setup process away from the actual test scripts. A test runner script can simply call this one function to guarantee that the necessary testing tools are installed and loaded into the current shell session. The components are installed into the tool manager's shared packages directory (`$TM_PACKAGES_DIR`), avoiding the need for global system-wide installation and potential version conflicts.

## Key Logic
1.  **Check for `bats-core`:** It first checks if the `bats` command is available. If not, it clones the `bats-core` repository from GitHub into `$TM_PACKAGES_DIR/bats-core` and adds its `bin` directory to the system `PATH`.
2.  **Check for `bats-support`:** It then checks for the `bats-support` library (by checking for the `bats` command again, which is a slight logic duplication). If not found, it clones the `bats-support` repository into `$TM_PACKAGES_DIR/bats-support` and then `source`s its `load.bash` file to make its helper functions available.
3.  **Check for `bats-assert`:** Finally, it checks for the `bats-assert` library by looking for the `assert_failure` function. If it's not available, it clones the `bats-assert` repository into `$TM_PACKAGES_DIR/bats-assert` and `source`s its `load.bash` file.

## Usage
This function is intended to be called from a test runner script or from the `setup_file` function within a BATS test suite.

```bash
#!/usr/bin/env tm-bash

# In a test runner script or setup_file function
_tm::source::include_once @tm/lib.invoke.sh
_tm::invoke::ensure_installed bats

# Now the test environment is ready, and you can run bats tests
# or use bats assertion functions.

@test "addition using bats-assert" {
  run bash -c "echo \$((2 + 2))"
  assert_success
  assert_output "4"
}
```

## Related
- This library is a key component of the `tm-dev-test` command, which uses it to prepare the environment before executing test suites.