---
title: tm-space-info
path: bin/tm-space-info
type: script
purpose: Displays detailed information about a specific Tool Manager space.
dependencies:
  - bin/.tm.script.sh
  - bin/.tm.space.sh
tags:
  - core
  - space
  - environment
  - reporting
---

## Overview
This script provides a way to inspect the configuration and metadata of a specific space. It reads the space's definition file and prints a summary of its properties.

## Design Philosophy
The script is a straightforward information retrieval tool. It uses the same logic as `tm-space` to locate a space's definition file (via key or GUID) but instead of launching it, it reads the file's contents into an associative array and passes that data to a dedicated print function, `_tm::space::print_info`. This separates the data retrieval from the presentation, making the code clean and easy to maintain.

## Key Logic
1.  **Argument Parsing:** The script accepts either a `--key` or a `--guid` to identify the target space.
2.  **Space File Resolution:** The `__find_file` helper function is called to locate the space's definition file. It uses `_tm::space::file::get_by_guid` or `_tm::space::file::get_by_key` from the `.tm.space.sh` library to find the correct `.conf` file.
3.  **Data Reading:** The script calls `_tm::space::file::read_array` to parse the contents of the found `.conf` file into an associative array named `space`.
4.  **Information Display:** It passes the `space` array to the `_tm::space::print_info` function, which formats and prints the key-value pairs to the console.

## Usage
```bash
# Get information about a space using its key
tm-space-info my-work-space

# Get information about a space using its unique GUID
tm-space-info --guid "123e4567-e89b-12d3-a456-426614174000"
```

## Related
- `.llm/bin/.tm.space.sh.md` (Contains the core logic for finding, reading, and printing space info)
- `bin/tm-space-ls` (Lists all available spaces)