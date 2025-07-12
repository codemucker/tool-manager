---
title: lib.file.ini.sh
path: lib-shared/tm/bash/lib.file.ini.sh
type: library
purpose: Provides a set of functions for reading and parsing INI-style configuration files.
dependencies:
  - lib-shared/tm/bash/lib.log.sh
  - lib-shared/tm/bash/lib.util.sh
  - lib-shared/tm/bash/lib.source.sh
tags:
  - file
  - ini
  - config
  - parsing
---

## Overview
This library is a dedicated parser for the INI file format, a common standard for configuration files. It is used extensively within the tool manager, particularly for reading plugin registry files (e.g., `plugins.conf`). The library provides functions to read an entire INI file into a single associative array, read just a specific section, list all available section names, or simply check if a section exists.

## Design Philosophy
The library is designed as a pure Bash INI parser, avoiding external dependencies like `awk` or `sed` where possible for core logic, relying instead on Bash's built-in regular expressions and parameter expansion. This makes it portable and efficient. The functions are designed to be robust, handling whitespace and comments correctly. The main `read` function flattens the INI structure into a single-level associative array using the format `section_key`, which is a simple and effective way to represent the data in a Bash context.

## Key Logic
1.  **Core Parsing Loop:** All the main functions (`read`, `read_section`, etc.) are built around a `while IFS= read -r line` loop to process the INI file line by line.
2.  **Line Processing:** Inside the loop, each line is first trimmed of leading/trailing whitespace. The script then uses regex matching (`=~`) to differentiate between three types of lines:
    *   **Comments/Empty Lines:** Lines starting with `#` or `;`, or empty lines, are skipped.
    *   **Section Headers:** Lines matching `^\[(.*)\]$` are identified as section headers. The section name is extracted and stored in a `current_section` variable.
    *   **Key-Value Pairs:** Lines matching `^([^=]+)=(.*)$` are parsed into a key and a value.
3.  **`_tm::file::ini::read`:** Reads the whole file. When it parses a key-value pair, it constructs a new key for the output array by combining the `current_section` and the `key` (e.g., `mysection_mykey`). An optional prefix can be added.
4.  **`_tm::file::ini::read_section`:** This function is more targeted. It first loops until it finds the requested `target_section_name`. Once found, it starts populating the output array with the key-value pairs. When it encounters the *next* section header, it stops processing, making it efficient for large files. It also supports a `multiline` option to append values for duplicate keys.
5.  **`_tm::file::ini::read_sections`:** This function only cares about section headers. It extracts the name from each `[section]` line and adds it to an indexed array, ensuring uniqueness.
6.  **`_tm::file::ini::has_section`:** This is a simple boolean check that returns `0` (success) as soon as it finds a matching section header, and `1` (failure) if it reaches the end of the file without a match.

## Usage
```bash
# plugins.conf
# [plugin "git"]
# url = https://github.com/user/tm-git.git
#
# [plugin "docker"]
# url = https://github.com/user/tm-docker.git

# In a script:
declare -A plugin_details
_tm::file::ini::read_section plugin_details "plugins.conf" "plugin \"git\""

echo "Git plugin URL: ${plugin_details[url]}"

# Get a list of all defined plugins
declare -a all_plugins
_tm::file::ini::read_sections all_plugins "plugins.conf"
for plugin in "${all_plugins[@]}"; do
  echo "Found plugin definition: $plugin"
done
```

## Related
- `.llm/lib-shared/tm/bash/lib.log.sh.md` (For error reporting)
- `.llm/lib-shared/tm/bash/lib.util.sh.md` (For helper functions)