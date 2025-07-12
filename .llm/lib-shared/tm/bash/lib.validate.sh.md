---
title: lib.validate.sh
path: lib-shared/tm/bash/lib.validate.sh
type: library
purpose: Provides a generic, extensible, regex-based validation framework.
dependencies:
  - lib-shared/tm/bash/lib.log.sh
tags:
  - validation
  - regex
  - utility
  - framework
---

## Overview
This library provides a flexible validation framework used primarily by the argument parser (`lib.args.sh`) but designed for general-purpose use. It allows scripts to validate values against a set of pre-defined or custom regular expressions. The framework is extensible, allowing new, named validators to be added at runtime.

## Design Philosophy
The library is designed to be data-driven and declarative. Instead of writing custom validation logic in every script, a developer can specify a comma-separated list of validator names (e.g., `alphanumeric,noslashes`). The library handles the rest. It supports both positive (`+`) and negative (`-`) validation, meaning you can assert that a value *must* match a pattern or *must not* match a pattern. This declarative approach makes the validation rules easy to read and maintain directly within the argument definitions of a script.

## Key Logic
1.  **Validator Registry:** A global associative array, `__tm_validators_by_name`, acts as a registry. It is initialized with a set of common validators like `alphanumeric`, `numbers`, `plugin-vendor`, etc. Each entry in the array stores a pipe-separated string containing the regular expression and a human-readable description of the rule.
2.  **`_tm::validate::add_validator`:** This function allows scripts to add new, custom validators to the registry at runtime, making the framework extensible.
3.  **`_tm::validate::key_value`:** This is the main entry point.
    a.  It takes a key name (for error messages), the value to validate, and a comma-separated string of validator names.
    b.  It splits the validator string and iterates through each validator.
    c.  It checks for a `+` or `-` prefix to determine if the validation should be positive (must match) or negative (must not match).
    d.  **Custom Regex:** If the validator starts with `re:`, it treats the rest of the string as a raw regular expression for a one-off validation.
    e.  **Registered Validator:** Otherwise, it looks up the validator name in the `__tm_validators_by_name` registry to get the corresponding regex and description.
    f.  It performs the regex comparison (`=~`) between the value and the pattern.
    g.  If the validation fails (e.g., a required match doesn't, or a forbidden match does), it calls `_fail` with a detailed error message, immediately halting the script.

## Usage
```bash
# This library is most often used indirectly via lib.args.sh,
# but can be called directly.

# Add a custom validator for a UUID
_tm::validate::add_validator "uuid" "^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$" "be a valid UUID"

# Direct validation
user_input="my-valid-name"
# The following will succeed silently
_tm::validate::key_value "username" "$user_input" "alphanumeric,-numbers"

invalid_input="not a uuid"
# The following will call _fail with an error message
_tm::validate::key_value "id" "$invalid_input" "+uuid"
```

## Related
-   `.llm/lib-shared/tm/bash/lib.args.sh.md`: This is the primary consumer of the validation library, using it to validate command-line arguments.
-   `.llm/lib-shared/tm/bash/lib.log.sh.md`: Used for logging warnings and failing on validation errors.