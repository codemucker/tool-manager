# Bash Scripting Conventions for the Tool Manager Project

This document outlines the specific Bash scripting conventions to be used for all new and modified code within this project. These rules are designed to ensure consistency, readability, and maintainability, and are optimized for AI-assisted development.

By default we use the Google script conventions.

## 1. File Structure & Shebang
- **Shebang:** All new executable scripts MUST start with `#!/usr/bin/env env-tm-bash` by default. This ensures they run within the Tool Manager's prepared environment.
- **Purpose Header:** A comment block explaining the script's purpose, arguments, and usage examples SHOULD be included at the top of every script.
- **Source Includes:** All `_include` or `source` statements MUST be placed immediately after the header, before any other code.

## 2. Naming Conventions
- **Functions:**
    - Core library functions MUST be namespaced with `_tm::` (e.g., `_tm::parse::plugin_id`).
    - Functions which are made available to plugins, are in the global namespace and start with a `_` (e.g. `_parse_args`). These should call the underlying `_tm::` functions
    - Private helper functions within a script (not intended for external use) SHOULD be prefixed with a double underscore (e.g., `__get_actual_deps`). Generally these should be within the `tm::` namespace such as `_tm::dep::__get_actual_deps`. 
    - The double underscore signals private; the single underscore denotes protected (so use with `tm`, but beware), and public functions have no underscores (except for the namespace prefix `_tm::`)
- **Variables:**
    - Global or script-level variables SHOULD be in `UPPER_SNAKE_CASE` (e.g., `PROJECT_ROOT`).
    - Global (but internal) variables should start with a double underscore (e.g., `__TM_SOMETHING`)
    - Local variables within functions MUST be declared with `local` and SHOULD be in `lower_snake_case` (e.g., `local file_dir`).
    - Associative arrays SHOULD be used for complex data structures (e.g., `declare -A plugin`).

## 3. Error Handling & Control Flow
- **Strict Mode:** All scripts SHOULD use `set -euo pipefail` to ensure robustness. The `env-tm-bash` environment enables this by default.
- **Error Reporting:** User-facing errors MUST be reported using the `_error` or `_fail` functions from the logging library. `_fail` should be used for fatal errors that must terminate the script.
- **Informational Output:** Non-error output intended for the user MUST use `_info` or `_warn`. `_log` should be used for debugging output.
- **Conditional logging:** Each log level has a check-enable function, e.g. `_is_info`, `_is_debug`, `_is_trace`, `_is_finest`. Use these before calling a log function if a lot of info, formatting, or calls need to be made for a log call

## 4. Code Style & Formatting
- **Indentation:** Use 2 spaces for indentation, not tabs.
- **Conditionals:** `[[ ... ]]` MUST be used in preference to `[ ... ]` for tests and conditionals.
- **Argument Parsing:** The `_parse_args` function from `lib.args.sh` MUST be used for parsing all non-trivial script arguments. This ensures consistency in help text generation and validation.
- **Quoting:** All variable expansions (`"$my_var"`) and command substitutions (`"$(my_command)"`) MUST be double-quoted to prevent word splitting and globbing issues.
- **Variables:**  Prefer using `${my_var}` from over `$my_var`, - and update existing code to use it whenever you touch those lines.

## 5. Code Reuse
- **Use libs**: prefer to use the libs in 'lib-shared/tm/bash', vs reinvention.

## 6. Documentation (BashDoc)
- All functions MUST be preceded by a "BashDoc" comment block. This will be checked algorithmically
- The `@status` tag MUST be used to indicate the documentation's state (`stub`, `ai-generated`, `human-reviewed`).
- The `tm-dev-llm-document` tool SHOULD be used to lint for and generate documentation stubs.

## 7. Tests
- Write tests where possible
- We use bats for testing by default (but support a bunch of test runners)
- Unit tests go into tests/unit
- Integration tests go into tests/integration
- Tests are run via `tm-dev-test` (run inside bash and be sure to `source TM_HOME/.bashrc`)
- A shell linter 'shellcheck', can be run via `tm-dev-shellcheck`. This will find all the files, or pass the path of the file to check as a singular arg `tm-dev-shellcheck <path/to/file>`
- New code **must** include tests. Retrofit tests where you can, or where there are bugs. Do NOT remove existing tests ever.

## 8. Focus
- Focus on the task at hand. Don't go re-write and re-implement or re-design existing code, unless explicitly instructed to by the user, or it's required for a feature.
