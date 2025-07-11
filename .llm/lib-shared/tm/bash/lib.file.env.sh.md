---
title: lib.file.env.sh
path: lib-shared/tm/bash/lib.file.env.sh
type: library
purpose: Provides robust functions for reading from and writing to `.env` style configuration files.
dependencies:
  - lib-shared/tm/bash/lib.util.sh
  - lib-shared/tm/bash/lib.source.sh
tags:
  - file
  - env
  - config
  - parsing
---

## Overview
This library offers a set of tools for interacting with `.env` files, a common format for storing environment variables and configuration. It provides a function to parse one or more `.env` files into a Bash associative array and another function to safely write or update key-value pairs in a `.env` file, preserving comments and formatting.

## Design Philosophy
The library is designed for robustness and safety. The `read` function is built to handle multiple input files, gracefully skipping those that don't exist, and correctly parsing lines while ignoring comments and empty space. The `set` function is particularly important; it operates on a temporary file to prevent corruption of the original `.env` file during the update process. It carefully replaces existing keys, appends new ones, and makes a best effort to preserve existing comments or add new ones, ensuring that the configuration files remain human-readable and well-documented.

## Key Logic
1.  **Reading (`_tm::file::env::read`):**
    a.  Takes an associative array name (by reference) and a list of `.env` files as input.
    b.  Clears the target array.
    c.  Iterates through each provided file.
    d.  Reads each file line-by-line, skipping empty lines and full-line comments.
    e.  For valid lines, it removes inline comments, splits the line at the first `=` into a key and value, trims whitespace, and removes quotes from the value.
    f.  The resulting key-value pair is stored in the associative array, with values from later files overwriting those from earlier ones.
2.  **Writing (`_tm::file::env::set`):**
    a.  Takes a file path, key, value, and an optional comment as input.
    b.  Validates the key to prevent invalid characters.
    c.  Creates a temporary file to build the new content.
    d.  If the original `.env` file exists, it reads it line-by-line.
    e.  If a line contains the target key, it replaces that line with the new key, value, and comment (if provided). It attempts to preserve an existing comment if a new one isn't given.
    f.  All other lines (including comments and blank lines) are written to the temporary file as-is.
    g.  If the key was not found in the file, the new key-value-comment line is appended to the end of the temporary file.
    h.  Finally, it atomically replaces the original `.env` file with the temporary file using `mv`.

## Usage
```bash
# Read two .env files into an associative array, with values in the second file taking precedence
declare -A my_config
_tm::file::env::read my_config "defaults.env" "user.env"

# Access a value
echo "The API key is: ${my_config[API_KEY]}"

# Set or update a value in a specific .env file
_tm::file::env::set "user.env" "THEME" "dark" "Sets the application theme"
```

## Related
- `.llm/lib-shared/tm/bash/lib.util.sh.md` (Provides utility functions used internally, like `_tm::util::array::print`).
- `.llm/lib-shared/tm/bash/lib.cfg.sh.md` (A higher-level library that uses this one to manage the underlying configuration files).