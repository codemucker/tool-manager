---
title: "tm-dev-llm-document"
path: "bin-internal/tm-dev-llm-document"
type: "script"
purpose: "Manages in-code documentation (BashDoc) for shell functions."
dependencies: []
tags:
  - "llm"
  - "developer"
  - "documentation"
  - "linter"
---

## Overview

This script is a powerful utility for managing the inline documentation of shell functions, following a Javadoc-like convention called "BashDoc". It operates in several modes to lint, fix, and generate documentation, ensuring that the codebase remains well-documented and understandable.

## Design Philosophy

Good documentation is critical, but it's often tedious to write and maintain. This script automates as much of the process as possible. It provides a structured format (`BashDoc`) for consistency, a linter to enforce the standard, a fixer to bootstrap missing documentation, and a prompt generator to leverage an LLM for the actual writing. The goal is to lower the barrier to creating high-quality documentation, making it an integral part of the development workflow rather than an afterthought. The `@status` tag within the BashDoc is key, as it tracks the documentation's lifecycle from a `stub`, to `ai-generated`, to `human-reviewed`.

## Key Logic

The script is broken down into three main modes:

### --lint

1.  **Function Discovery:** It finds all shell functions in the codebase using `_get_all_functions`.
2.  **Status Check (`_get_doc_status`):** For each function, it inspects the source code to find the BashDoc block and reads the value of the `@status` tag. If no block is found, it reports "ERROR".
3.  **Reporting:** It prints the status of each function (`OK`, `WARN`, `ERROR`) and exits with a non-zero status code if any functions are missing documentation entirely.

### --fix

1.  **Function Discovery:** Same as lint mode.
2.  **Status Check:** It identifies functions whose status is "ERROR" (i.e., they have no BashDoc block).
3.  **Template Injection:** For each missing block, it uses `grep` to find the function's starting line number and then uses `sed -i` to insert a predefined BashDoc template (`_get_bashdoc_template`) directly above the function definition in the source file.

### --prompt `<function_name>`

1.  **Function Location:** It finds the file and exact name of the specified function.
2.  **Source Extraction (`_get_function_source`):** It extracts the full source code of the target function, from its definition line to its closing brace `}`.
3.  **Prompt Generation:** It constructs a detailed prompt for an LLM. This prompt includes:
    *   The function's name and file location.
    *   The full source code of the function, enclosed in a Markdown code block.
    *   The BashDoc template, with the `@status` pre-set to `ai-generated`.
    This generated prompt can be copied and pasted directly into an LLM to request documentation.

## Usage

### Linting
Check the documentation status of all functions.
```bash
tm-dev-llm-document --lint
```

### Fixing
Add placeholder documentation templates for all undocumented functions.
```bash
tm-dev-llm-document --fix
```

### Generating an LLM Prompt
Create a prompt to ask an LLM to document a specific function.
```bash
tm-dev-llm-document --prompt _my_function_name
```

## Related

-   [`tm-dev-llm-verify.md`](.llm/bin-internal/tm-dev-llm-verify.md)
-   [`tm-dev-llm-index-functions.md`](.llm/bin-internal/tm-dev-llm-index-functions.md)