---
title: tm-dev-tests
path: bin/tm-dev-tests
type: script
purpose: Runs automated tests for the Tool Manager core or a specified plugin.
dependencies:
  - bin/.tm.script.sh
  - bin/.tm.plugin.sh
  - bin/.tm.plugins.sh
  - lib-shared/tm/bash/lib.prog.bats.sh
tags:
  - core
  - plugin
  - test
  - development
---

## Overview
This script is the primary test runner for the Tool Manager ecosystem. It can execute test suites for the core `tool-manager` project itself or for any installed plugin that has a `test` or `tests` directory. It supports standard shell script tests and tests written for the BATS (Bash Automated Testing System) framework.

## Design Philosophy
The script is designed to be a flexible and easy-to-use test harness. It automatically locates the correct test directory based on the specified target (a plugin name, a path, or the default 'tool-manager'). It uses `find` to discover all executable test files (`*.sh` and `*.bats`) and runs them sequentially or in parallel. The integration with BATS is handled by the `lib.prog.bats.sh` library, which ensures BATS is available before attempting to run `.bats` files.

## Key Logic
1.  **Argument Parsing:** The script parses arguments to determine the test target (`--plugin`), a pattern to filter specific test files (`--test`), and whether to run in parallel (`--parallel`).
2.  **BATS Installation Check:** It calls `_tm::prog::bats::install` to ensure the BATS testing framework is installed, cloning it if necessary.
3.  **Target Resolution:** It determines the directory containing the tests to be run:
    *   If no target is given or if it's `tool-manager`, it uses the core test directory (`$TM_HOME/tests`).
    *   If the target is a path, it uses that path directly.
    *   If the target is a plugin name, it resolves the plugin's installation directory and looks for a `test` or `tests` subdirectory within it.
4.  **Test File Discovery:** It uses `find` to create two lists of test files: one for `.sh` files and one for `.bats` files.
5.  **Test Execution:** It iterates through the lists of found test files.
    *   For `.sh` files, it executes them directly.
    *   For `.bats` files, it executes them using the `bats` command.
    *   If `--parallel` is specified, it runs each test file in a background subshell.
6.  **Result Aggregation:** It keeps track of failures. If running in parallel, it uses `wait` to ensure all background tests complete before exiting. If any test fails, the script exits with a non-zero status code.

## Usage
```bash
# Run all tests for the core tool-manager project
tm-dev-tests

# Run all tests for a specific plugin
tm-dev-tests my-vendor/my-plugin

# Run tests from a specific directory
tm-dev-tests ./path/to/some/tests

# Run tests in parallel
tm-dev-tests --parallel my-vendor/my-plugin
```

## Related
- `.llm/lib-shared/tm/bash/lib.prog.bats.sh.md` (Handles BATS framework dependency)
- `bin/tm-dev-shellcheck` (A related script for static analysis)