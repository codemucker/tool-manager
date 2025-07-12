---
title: "tm-dev-llm-verify"
path: "bin-internal/tm-dev-llm-verify"
type: "script"
purpose: "Scans the codebase to find discrepancies between actual script dependencies and documented dependencies."
dependencies:
  - "lib-shared/tm/bash/lib.log.sh"
tags:
  - "llm"
  - "developer"
  - "validation"
---

## Overview

This script is a developer utility designed to maintain the integrity of the `.llm` documentation system. It systematically scans shell scripts within the repository, extracts their `source`, `_include`, and `_include_once` dependencies, and compares this list against the `dependencies` documented in the corresponding `.llm/*.md` file's YAML frontmatter.

## Design Philosophy

The documentation system must be self-describing and, more importantly, accurate. Stale or missing dependency information can mislead the LLM, leading it to make incorrect assumptions about the codebase. This script enforces consistency by automating the verification process, ensuring that the documentation remains a reliable map of the actual code.

## Key Logic

1.  **File Discovery:** The script begins by using `find` to locate all script files within the `bin`, `bin-internal`, `bin-defaults`, and `lib-shared` directories.
2.  **Actual Dependency Extraction (`_get_actual_deps`):** For each script found, it uses `grep` and `sed` to find all lines containing `source`, `_include`, or `_include_once`. It extracts the file paths, normalizes them to be relative to the project root, and sorts them.
3.  **Documented Dependency Extraction (`_get_documented_deps`):** It constructs the path to the corresponding `.llm/*.md` file (e.g., `bin/tm-foo` -> `.llm/bin/tm-foo.md`). It then uses `awk` to parse the YAML frontmatter and extract the list of dependencies.
4.  **Comparison:** The script uses the `comm` utility to compare the two lists (actual vs. documented).
    *   `comm -23`: Shows lines unique to the first file (dependencies in code but not in docs).
    *   `comm -13`: Shows lines unique to the second file (dependencies in docs but not in code).
5.  **Reporting:** If any discrepancies are found, it prints a detailed error message listing the missing or stale entries for each affected file and exits with a non-zero status code. If all files are consistent, it prints a success message.

## Usage

The script is intended to be run from the project root without any arguments.

```bash
# Run the verification process
tm-dev-llm-verify
```

It is typically used as part of a pre-commit hook or a CI/CD pipeline to ensure that documentation stays in sync with the code.

## Related

-   [`tm-dev-llm-document.md`](.llm/bin-internal/tm-dev-llm-document.md)