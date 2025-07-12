---
title: tm-help-commands
path: bin/tm-help-commands
type: script
purpose: Generates and displays documentation for all available tool-manager commands, either in the console or as an interactive HTML page.
dependencies:
  - bin/.tm.script.sh
  - bin/.tm.plugins.sh
tags:
  - help
  - documentation
  - discovery
  - html
  - cli
---

## Overview
This script is a dynamic help system that discovers all available commands from the core tool-manager and all enabled plugins. It can display the extracted help information directly in the console or generate a self-contained, interactive HTML page and serve it via a local web server for a richer user experience.

## Design Philosophy
The script is designed to be a comprehensive and user-friendly discovery tool. It operates on the principle of "convention over configuration" for documentation, automatically parsing the comment block at the beginning of each script file to generate its help content.

-   **Dynamic Discovery:** It uses `_tm::plugins::find_all_scripts` to get a complete list of all executable scripts, ensuring that the help system is always up-to-date with the currently enabled plugins.
-   **Dual-Mode Output:** It can function as a simple console utility or, with the `--gui` flag, as a more advanced, interactive web-based tool. This provides flexibility for different user needs.
-   **Self-Contained HTML:** The generated HTML page includes all necessary CSS and JavaScript, making it a single, portable file that can be easily viewed and shared. The embedded JavaScript provides client-side filtering and expanding/collapsing of help sections for a better user experience.
-   **Automatic Grouping:** The HTML output automatically groups commands by their prefix (e.g., `tm-`, `git-`), making the list of commands easier to navigate.

## Key Logic
1.  **Argument Dispatch (`__tm_help`):** The main function checks for the `--gui` flag. If present, it calls `__tm_help_serve`; otherwise, it calls `__tm_help_console`.
2.  **Console Mode (`__tm_help_console`):**
    -   It calls `_tm::plugins::find_all_scripts` to get a list of all command files.
    -   It iterates through this list and calls `_tm::args::print_help_from_file_comment` for each file, which extracts and prints the header comment block.
3.  **GUI Mode (`__tm_help_serve`):**
    -   It creates a temporary directory and an `index.html` file within it.
    -   It calls `__tm_help_generate_help_page` and redirects its standard output to the `index.html` file.
    -   It uses a small Python snippet to find a free network port.
    -   It starts Python's built-in `http.server` in the background to serve the temporary directory.
    -   It uses `xdg-open` to launch the user's default web browser to the local server's URL.
4.  **HTML Generation (`__tm_help_generate_help_page`):**
    -   It prints a `heredoc` containing the HTML boilerplate, including CSS for styling and JavaScript for interactivity (filtering, expand/collapse).
    -   It finds all scripts and iterates through them, grouping them by their command prefix (e.g., `tm-plugin`, `tm-cfg`).
    -   For each script, it uses `awk` and `sed` to extract the header comments, escape any HTML-sensitive characters, and embed the result within the appropriate HTML structure (`<div class='command'>...</div>`).
    -   Finally, it prints the closing HTML tags.

## Usage
```bash
# Display help for all commands in the console
tm-help-commands

# Display help for commands starting with 'tm-plugin'
tm-help-commands tm-plugin

# Launch the interactive HTML help page in a browser
tm-help-commands --gui
```

## Related
-   `.llm/bin/.tm.plugins.sh.md` (Provides the `_tm::plugins::find_all_scripts` function for command discovery)
-   `.llm/lib-shared/tm/bash/lib.args.sh.md` (Provides the `_tm::args::print_help_from_file_comment` function for parsing help text)
-   `.llm/bin/tm-help-commands-gui.md` (An alias for `tm-help-commands --gui`)