---
title: "tm-dev-llm-index-functions"
path: "bin-internal/tm-dev-llm-index-functions"
type: "script"
purpose: "Generates a JSON index of all shell functions in the codebase."
dependencies: []
tags:
  - "llm"
  - "developer"
  - "index"
  - "json"
---

## Overview

This script creates a comprehensive JSON index of every shell function defined across the entire codebase. It scans all executable files in the standard binary and library directories, identifies function definitions, and outputs a single JSON file (`.llm/function-index.json`) that maps each function name to its source file and starting line number.

## Design Philosophy

For an LLM to effectively understand and modify the codebase, it needs a quick way to locate the definition of any given function. Searching the entire file system for a function name is slow and inefficient. This script provides a pre-computed index, a "phone book" for functions, that allows for near-instantaneous lookups. By maintaining this index, we significantly improve the LLM's ability to navigate the code, understand call hierarchies, and find relevant context.

## Key Logic

The script operates as a single, powerful pipeline:

1.  **File Discovery (`find`):** It searches the `bin`, `bin-internal`, `bin-defaults`, and `lib-shared` directories for all executable files, filtering out common non-script files (`.md`, `.json`, etc.).
2.  **Function Grepping (`grep`):** The list of files is piped to `grep`, which searches for lines that look like shell function definitions. The regex `^\s*(function\s+)?[a-zA-Z0-9_:]+\s*\(\s*\)` is used to find both `function foo` and `foo()` style declarations. The `-H` (with-filename) and `-n` (line-number) flags are crucial for providing context.
3.  **Initial Parsing (`awk` #1):** The output from `grep` (e.g., `bin/tm-foo:12:function foo() {`) is processed by a first `awk` script. This script's job is to clean up the line, extract the pure function name, the file path, and the line number, and print them as a simple tab-separated line (e.g., `foo\tbin/tm-foo\t12`). It also normalizes the file path to be relative to the project root.
4.  **Sorting (`sort`):** The tab-separated lines are sorted uniquely by function name. This is important for ensuring a consistent order in the final JSON and for handling any potential duplicate function definitions (the last one found will be kept).
5.  **JSON Generation (`awk` #2):** The final, sorted list is piped to a second `awk` script. This script reads the tab-separated values and formats them into a clean, pretty-printed JSON object, which is then written to the output file.

## Usage

The script is run without arguments. It will overwrite the existing function index file.

```bash
# Generate or update the function index
tm-dev-llm-index-functions
```

This script should be run whenever function definitions are added, removed, or renamed.

## Related

-   [`tm-dev-llm-document.md`](.llm/bin-internal/tm-dev-llm-document.md)