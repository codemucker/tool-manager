---
title: tm-space-ls
path: bin/tm-space-ls
type: script
purpose: Lists all configured Tool Manager spaces.
dependencies:
  - bin/.tm.script.sh
  - bin/.tm.space.sh
tags:
  - core
  - space
  - environment
  - list
---

## Overview
This script displays a list of all available Tool Manager spaces, showing detailed information for each one.

## Design Philosophy
The script is a simple discovery and reporting tool. It uses the `_tm::space::file::find_all` function from the `.tm.space.sh` library to get a list of all space definition files. It then iterates through this list, reading each file and printing its contents in a human-readable format using the `_tm::space::print_info` helper function. While it includes argument parsing for future filtering capabilities, the current implementation lists all spaces unconditionally.

## Key Logic
1.  **Find All Spaces:** The script calls `_tm::space::file::find_all` to get a list of every `.space.*.conf` file in the `$TM_SPACE_DIR`.
2.  **Iteration:** It loops through the list of found files.
3.  **Data Reading:** For each file, it calls `_tm::space::file::read_array` to parse its contents into an associative array.
4.  **Information Display:** It passes the data array to `_tm::space::print_info`, which formats and prints the details of the space to the console.

## Usage
```bash
# List all available spaces
tm-space-ls
```

## Related
- `.llm/bin/.tm.space.sh.md` (Contains the core logic for finding, reading, and printing space info)
- `bin/tm-space` (Switches to one of the listed spaces)
- `bin/tm-space-info` (Shows detailed information for a single space)