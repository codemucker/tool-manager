---
title: lib.args.sh
path: lib-shared/tm/bash/lib.args.sh
type: library
purpose: Provides robust command-line argument parsing and validation functionality.
dependencies:
  - lib-shared/tm/bash/lib.validate.sh
  - lib-shared/tm/bash/lib.source.sh
tags:
  - parsing
  - arguments
  - validation
  - cli
---

## Overview
This library is a powerful and flexible command-line argument parser for Bash scripts. It allows script developers to define a complex set of expected arguments, including short and long options, flags, required arguments, default values, and validation rules. It automatically generates help messages and handles user input errors gracefully.

## Design Philosophy
The library is designed to be a comprehensive, self-contained solution for argument parsing, removing the need for boilerplate `getopts` or manual `case` statements in every script. It centralizes parsing logic, making scripts cleaner and more maintainable. The core function, `_tm::args::parse`, takes a declarative specification of the expected arguments and populates an associative array with the parsed values, abstracting the complex parsing logic away from the script's main purpose.

## Key Logic
1.  **Option Specification:** The calling script defines its arguments using `--opt-<key>` parameters. Each specification is a pipe-delimited string defining attributes like `short`, `long`, `desc`, `required`, `flag`, `default`, `allowed` values, and `validators`.
2.  **Parser Configuration:** The caller also provides a `--result` array name to store the output, an optional `--help` function or string, and other configuration flags.
3.  **Internal Parsing:** The `_tm::args::parse` function first parses these specification arguments to build an internal model of the expected command-line interface.
4.  **User Argument Parsing:** After encountering a `--` separator, the function processes the user-provided arguments (`$@`). It matches them against the specification, handles value assignment, and validates input against the defined rules.
5.  **Help Generation:** If the user passes `-h` or `--help`, or if a validation error occurs, the `__print_help` internal function dynamically generates a formatted usage message based on the option specifications.
6.  **Result Population:** The final parsed values are stored in the associative array specified by the `--result` parameter, which the calling script can then use.

## Usage
```bash
# In your script:
_tm::source::include_once @tm/lib.args.sh

__help() {
  echo "This is a custom help message for my script."
}

main() {
  declare -A args
  _tm::args::parse \
    --help __help \
    --opt-plain   '|short=p|long=plain|required|flag|desc=A simple flag.' \
    --opt-env     '|short=e|long=environment|desc=The target environment.|default=dev|allowed=dev,prod,test' \
    --opt-files   '|remainder|desc=Input files to process.' \
    --result args \
    -- "$@"

  # Now use the parsed arguments
  if [[ "${args[plain]}" == "1" ]]; then
    echo "Plain mode is enabled."
  fi
  echo "Environment is: ${args[env]}"
  echo "Files to process: ${args[files]}"
}

main "$@"
```

## Related
- `.llm/lib-shared/tm/bash/lib.validate.sh.md` (Provides the validation logic used by this library)
- `.llm/lib-shared/tm/bash/lib.source.sh.md` (Used for dependency inclusion)