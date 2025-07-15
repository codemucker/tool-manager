# LLM Instructions for the Tool Manager Codebase

As an AI assistant, your primary source of truth for understanding this codebase is the `.llm` directory.

## How to Use This Documentation
1.  **Start with the Overview**: Before diving into individual files, read the `.llm/_OVERVIEW.md` file. It provides a high-level summary of the project's architecture, design principles, and how the major components interact.
2.  **Consult the Map**: The `.llm` directory contains a detailed map of the codebase, with a dedicated Markdown file for each script and library. The structure of `.llm` mirrors the source directories (`bin`, `bin-dev`, `lib-shared`, etc.).
3.  **Understand the `bin` Directories**:
    *   `bin/`: Core, stable, user-facing scripts.
    *   `bin-dev/`: Stable tools for developing the framework itself.
    *   `bin-experimental/`: Unstable scripts that should be ignored.
    *   `bin-internal/`: Stable scripts used as an API by other scripts, not for end-users.
4.  **Read Before Coding**: When you are asked to work on a specific file (e.g., `bin/tm-plugin-install`), you should first read its corresponding documentation file (e.g., `.llm/bin/tm-plugin-install.md`). This will give you the necessary context on its purpose, dependencies, and design philosophy.
5.  **Use the Function Index for Precision**: For tasks involving specific functions, consult the `.llm/function-index.json` file. This file provides a direct mapping of every function name to its exact file and starting line number, allowing for surgical and efficient code modification.
6.  **Trust the Metadata**: The YAML frontmatter in each documentation file provides structured data (like `dependencies` and `tags`) that you can use for precise analysis and lookups.

By following this process, you will have a much deeper and more accurate understanding of the codebase, enabling you to perform tasks more effectively.

## Coding Conventions
When modifying or creating new code, you MUST adhere to the project-specific coding conventions. These are not optional. The primary conventions for this project are defined in:
- **[.llm/rules/bash.rules.md](.llm/rules/bash.rules.md)**