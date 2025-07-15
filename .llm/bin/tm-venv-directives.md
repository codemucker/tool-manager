---
title: tm-venv-directives
path: bin/tm-venv-directives
type: script
purpose: Parses a file to extract and process virtual environment (@) directives.
dependencies:
  - bin/.tm.script.sh
  - bin/.tm.venv.directives.sh
tags:
  - core
  - venv
  - development
  - parsing
---

## Overview
This script is a utility for working with the Tool Manager's virtual environment (venv) system. It reads a specified source file, extracts all lines containing `@` directives (e.g., `@python=3.9`, `@pip=requests`), and then outputs them. It can also optionally validate the found directives against a list of known, supported directive types.

## Design Philosophy
The script is a key component of the declarative virtual environment system. It allows other scripts to define their runtime requirements directly within their own source code as comments. This script provides the mechanism to parse these declarations. The core extraction logic is handled by `_tm::venv::extract_directives`, keeping this script focused on user-facing options like validation and output redirection.

## Key Logic
1.  **Argument Parsing:** The script takes a `--file` to parse, an optional `--dest` file to write the output to, and a `--validate` flag.
2.  **Directive Extraction:** It calls `_tm::venv::extract_directives`, passing the source file. This function reads the file and returns all lines that look like directives.
3.  **Validation (Optional):** If the `--validate` flag is present, the script iterates through the extracted directives.
    a. It splits each directive into a name and value (e.g., `python` and `3.9`).
    b. It checks if the name exists in a hardcoded list of supported directives (`hashbang`, `venv`, `python`, `pip`, etc.).
    c. If an unknown directive is found, it reports an error and exits.
4.  **Output:**
    *   If a `--dest` file is specified, it writes the extracted directives to that file, overwriting it if it exists.
    *   If no destination is given, it prints the directives to standard output.

## Usage
```bash
# Extract directives from a script and print them to the console
tm-venv-directives --file /path/to/my-script.sh

# Extract directives and validate them
tm-venv-directives --file /path/to/my-script.sh --validate

# Extract directives and save them to another file
tm-venv-directives --file /path/to/my-script.sh --dest /path/to/directives.txt
```

## Related
- `.llm/bin/.tm.venv.directives.sh.md` (Contains the core extraction logic)
- `bin/tm-venv-run` (A script that would consume the output of this script to build and run a venv)