---
title: lib.io.conf.sh
path: lib-shared/tm/bash/lib.io.conf.sh
type: library
purpose: Provides a parser for `.conf` files, which are shell scripts with specific formatting rules.
dependencies:
  - lib-shared/tm/bash/lib.util.sh
  - lib-shared/tm/bash/lib.source.sh
tags:
  - file
  - conf
  - parsing
  - shell
---

## Overview
This library is designed to parse `.conf` files used within the tool manager ecosystem. These `.conf` files are not simple key-value stores; they are essentially Bash scripts that follow a specific structure. This parser can extract both variable assignments (`KEY=VALUE`) and entire function definitions from these files, storing them in an associative array for later use.

## Design Philosophy
The library provides a way to read configuration and executable code from the same file without actually `source`-ing the file, which could have unintended side effects. It treats the `.conf` file as plain text and uses regular expressions and state management to parse its contents. This approach allows a controlling script to inspect the contents of a `.conf` file, read its variables, and even retrieve the text of its functions before deciding whether to execute any of it. The parser is stateful, capable of correctly reading multi-line function definitions.

## Key Logic
1.  **State Management:** The parser uses a state machine with two main states: either it's parsing normal lines, or it's inside a multi-line function body. The `collecting_function_body` variable tracks this state.
2.  **Line-by-Line Processing:** The script reads the `.conf` file line by line. Each line is cleaned by trimming whitespace and removing comments.
3.  **Function Detection:** It uses a regular expression to detect lines that look like a function definition (e.g., `my_func() { ... }`).
    *   When a function is detected, the function name (with `()` appended) becomes the key in the output array.
    *   It checks if the function definition is on a single line (ends with `}`).
    *   If it's a multi-line function (doesn't end with `}`), it sets `collecting_function_body` to `true` and stores the function name in `current_multi_line_function_key`.
4.  **Multi-line Function Body Collection:** While `collecting_function_body` is `true`, all subsequent lines are appended to the value associated with `current_multi_line_function_key` in the output array. When a line containing the closing brace `}` is found, the state is reset.
5.  **Variable Assignment Parsing:** If the parser is not in a function body and the line contains an `=`, it's treated as a key-value pair. The key and value are extracted and stored in the output array. It also supports an `append_keys` option to concatenate values for specific keys instead of overwriting them.
6.  **Output:** The final result is an associative array where keys are either variable names or function names, and values are the corresponding variable values or the full text of the function bodies.

## Usage
```bash
# my_plugin.conf
#
# PLUGIN_VERSION="1.0"
#
# my_plugin_main() {
#   echo "Hello from my plugin!"
#   echo "Version: $PLUGIN_VERSION"
# }

# In a controlling script:
declare -A conf_data
_tm::io::conf::read_file conf_data "my_plugin.conf"

# Access the variable
echo "Plugin version is: ${conf_data[PLUGIN_VERSION]}"

# Access the function body
function_body="${conf_data['my_plugin_main()']}"
echo "The main function is:"
echo "$function_body"

# You could then choose to 'eval' the function body to execute it
eval "$function_body"
my_plugin_main
```

## Related
- `.llm/lib-shared/tm/bash/lib.util.sh.md` (Provides helper functions).