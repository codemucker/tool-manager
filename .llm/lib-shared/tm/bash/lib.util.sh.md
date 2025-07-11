---
title: lib.util.sh
path: lib-shared/tm/bash/lib.util.sh
type: library
purpose: Provides a collection of general-purpose utility and helper functions.
dependencies:
  - lib-shared/tm/bash/lib.log.sh
tags:
  - utility
  - helper
  - core
  - interactive
  - filesystem
---

## Overview
This library is a toolbox of essential, general-purpose helper functions used throughout the tool manager ecosystem. It includes functions for handling script termination, interactive user prompts, safe file operations, command existence checks, and more. It serves as a foundational layer, providing reliable implementations of common tasks to avoid code duplication and ensure consistent behavior.

## Design Philosophy
The library is designed as a grab-bag of indispensable tools. Each function is self-contained and aims to solve a common scripting problem robustly. For example, `_fail` and `_die` provide a standard way to exit on error, `_confirm` and `_read` abstract the complexity of interactive prompts, and `_rm` adds a layer of safety to the standard `rm` command. The goal is to provide a set of reliable primitives that make higher-level scripts cleaner, safer, and more readable.

## Key Logic
-   **Error Handling & Termination:**
    *   `_fail` / `_die`: Log an error message and exit the script with a non-zero status code. They also print a stack trace if trace logging is enabled.
    *   `_trap_sigs`: Sets a `trap` to ensure that when a script is interrupted (e.g., with Ctrl+C), all of its child processes are killed, preventing orphaned processes.
-   **Interactive Prompts:**
    *   `_read`: A wrapper around the built-in `read` command that forces input from the TTY, preventing issues with nested reads or redirected input.
    *   `_read_not_empty`: A loop that uses `_read` to ensure the user provides a non-empty value.
    *   `_read_yn` / `_confirm`: Provide a robust way to ask for yes/no confirmation, handling various user inputs (`y`, `yes`, `t`, `1`, etc.) and returning a clear result or exit code.
-   **Filesystem & Command Wrappers:**
    *   `_pushd` / `_popd`: Silent versions of the built-in commands that don't print the directory stack to `stdout`.
    *   `_grep`: A wrapper around `grep` that always returns a `0` exit code, even if no match is found. This is useful in scripts using `set -e`.
    *   `_touch`: An enhanced `touch` that also creates parent directories (`mkdir -p`).
    *   `_rm`: A safer `rm` that prevents accidental deletion of the root or home directories.
    *   `_realpath`: A cross-platform function to resolve a path to its absolute, canonical form, with fallbacks for systems that don't have the `realpath` command.
-   **Command & Language Checks:**
    *   `_fail_if_not_installed`: Checks if a command exists in the `PATH` and fails with a helpful error message if it doesn't.
    *   `_python` / `_python3`: Wrappers for running Python scripts, preferring `python3` but falling back gracefully.
-   **Array Helpers:**
    *   `_tm::util::array::print`: A debug helper to print the contents of an associative or indexed array.
    *   `_tm::util::array::get_first`: Retrieves the first non-empty value from an associative array for a given list of keys.

## Usage
```bash
# Fail script with a message
_fail "Something critical went wrong."

# Ask for user confirmation
if _confirm "Do you want to proceed?"; then
  _info "Proceeding..."
else
  _info "Aborting."
  exit 0
fi

# Check for a required command
_fail_if_not_installed "jq" "Please install jq to continue."

# Safely remove a temporary directory
_rm -rf "/tmp/my-temp-dir"
```

## Related
- This is a foundational library with a primary dependency on `lib.log.sh` for error reporting. It is used by nearly every other script in the system.