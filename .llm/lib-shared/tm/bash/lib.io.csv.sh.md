---
title: lib.io.csv.sh
path: lib-shared/tm/bash/lib.io.csv.sh
type: library
purpose: A simple utility to parse a key-value CSV string into an associative array.
dependencies: []
tags:
  - io
  - csv
  - parsing
  - utility
---

## Overview
This library provides a single, focused function, `_tm::io::csv::to_array`, for parsing a comma-separated string of key-value pairs (e.g., `key1=val1,key2=val2`) and loading them into a Bash associative array.

## Design Philosophy
The script is a minimalist utility designed to do one specific task efficiently using standard Bash built-ins. It avoids complexity by targeting a simple, common format. The use of `eval` is a key design choice that allows the function to populate an array whose name is passed as an argument, providing dynamic assignment capabilities.

## Key Logic
1.  **Input:** The function takes two arguments: the CSV string to parse and the name of the associative array to populate.
2.  **Pair Splitting:** It temporarily sets the Internal Field Separator (`IFS`) to a comma (`,`) and uses `read -ra` to split the input string into an indexed array of `key=value` pairs.
3.  **Key-Value Splitting:** It then iterates through this array of pairs. For each pair, it sets `IFS` to an equals sign (`=`) to separate the key from the value.
4.  **Dynamic Assignment:** The core of the function is the `eval` command. It dynamically constructs a string representing the array assignment (e.g., `my_array["key"]="value"`) and executes it, populating the caller's specified array.

## Usage
```bash
# The CSV string to parse
my_csv="name=plugin-A,version=1.2.3,author=Roo"

# Declare the associative array
declare -A plugin_data

# Call the function to parse the string into the array
_tm::io::csv::to_array "$my_csv" "plugin_data"

# Access the parsed data
echo "Plugin Name: ${plugin_data[name]}"
echo "Version: ${plugin_data[version]}"
```

## Related
- This is a low-level utility function. It is often used as a building block by higher-level parsing or configuration libraries that need to handle simple key-value list formats within a larger file structure.