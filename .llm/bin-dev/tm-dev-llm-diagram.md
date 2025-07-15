---
title: "tm-dev-llm-diagram"
path: "bin-internal/tm-dev-llm-diagram"
type: "script"
purpose: "Generates a MermaidJS graph diagram of the codebase's dependency structure."
dependencies:
  - ".tm.common.sh"
tags:
  - "llm"
  - "developer"
  - "diagram"
  - "visualization"
---

## Overview

This script generates a visual representation of the script dependency hierarchy within the codebase. It traverses the `bin` and `lib-shared` directories, analyzes the `source`, `_include`, and `_include_once` statements in each script, and outputs a graph definition in the MermaidJS `graph TD` (Top-Down) format.

## Design Philosophy

A visual diagram is an invaluable tool for understanding the architecture of a complex system. While the `.llm` documentation provides detailed textual descriptions, a graph provides an immediate, high-level overview of how different components are interconnected. This helps developers (and the LLM) to quickly grasp the flow of control and data within the application. The output is intentionally in MermaidJS format, as it is a widely supported, text-based diagramming language that can be easily embedded in Markdown files and rendered by many platforms (like GitHub, GitLab, and VS Code extensions).

## Key Logic

1.  **Initialization:** The script starts by printing the MermaidJS graph header: `graph TD`.
2.  **File Traversal:** It uses `find` to iterate through all files in the `bin` and `lib-shared` directories.
3.  **Dependency Parsing:** For each file, it uses `grep` to find lines containing `source`, `_include`, or `_include_once`.
4.  **Path Resolution:**
    *   It extracts the dependency file path from the line.
    *   It uses `eval` to expand any environment variables (like `${TM_DIR}`).
    *   It uses `realpath` to resolve the path to its canonical, absolute form and then makes it relative to the project root.
5.  **Node Normalization (`normalize_path`):** Before printing the graph edge, it cleans up the "from" and "to" paths to create short, readable node identifiers. This involves:
    *   Removing `./` prefixes.
    *   Replacing `/`, `-`, `.`, and `.sh` with underscores (`_`).
    *   Prefixing `bin` paths with `B_` and `lib-shared` paths with `L_` for clarity in the diagram.
6.  **Output:** For each valid dependency found, it prints a MermaidJS edge definition, such as `B_tm_foo --> L_lib_bar;`.

## Usage

The script is run without arguments. Its output is the raw MermaidJS graph definition, which should be redirected to a file or piped to a rendering tool.

```bash
# Generate the diagram and save it to a file
tm-dev-llm-diagram > codebase.mermaid

# Or, on a Mac, pipe it directly to the clipboard
tm-dev-llm-diagram | pbcopy
```

The resulting text can then be pasted into any MermaidJS-compatible viewer.

## Related

-   [`tm-dev-llm-verify.md`](.llm/bin-internal/tm-dev-llm-verify.md)