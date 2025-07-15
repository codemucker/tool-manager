---
title: tm-gui
path: bin/tm-gui
type: script
purpose: Launches a graphical user interface for interacting with the tool-manager.
dependencies:
  - "Python 3.12+"
  - "pip: tk"
  - "pip: ttkbootstrap"
tags:
  - gui
  - python
  - tkinter
  - ttkbootstrap
  - cli
---

## Overview
This script provides a graphical front-end for the `.tool-manager`, offering a more visual and interactive way to manage plugins and view information compared to the command-line tools. It is built using Python's `tkinter` library and styled with the `ttkbootstrap` theme extension to provide a modern look and feel.

## Design Philosophy
The application is designed with a classic two-pane layout: a fixed navigation pane on the left and a dynamic content pane on the right. The core design principles are:
-   **Asynchronous Operations:** To keep the GUI responsive, shell commands (like `tm-plugin-ls`) are executed in separate background threads using Python's `asyncio` and `threading` libraries. This prevents the UI from freezing while waiting for long-running commands to complete.
-   **Lazy Loading:** Content for tabs (e.g., the list of installed plugins) is only loaded when the tab is first selected. This improves initial startup time and reduces unnecessary command executions.
-   **Modularity:** The application is structured as a class (`App`), with distinct methods for handling different UI sections and actions (e.g., `show_plugins`, `show_scripts`). This makes the code easier to manage and extend.
-   **Delegation to CLI:** The GUI does not replicate the core logic of the tool-manager. Instead, it acts as a front-end that calls the existing `tm-*` command-line scripts (`tm-plugin-ls`, `tm-help-cfg`, etc.) and displays their output. This ensures that the GUI always reflects the single source of truth defined by the CLI tools.

## Key Logic
1.  **Initialization (`__init__`):**
    -   Sets up the main `ttk.Window` with a title, size, and theme (`litera`).
    -   Creates the main menubar and a two-pane layout (navigation and editor).
    -   Populates the navigation pane with buttons that trigger different `show_*` methods.

2.  **Content Display (`show_*` methods):**
    -   Methods like `show_plugins` and `show_scripts` are responsible for changing the content of the main editor pane.
    -   `show_plugins` is the most complex, creating a `ttk.Notebook` widget with multiple tabs. Each tab is configured to display the output of a specific `tm-plugin-ls` command variant (e.g., `--installed`, `--enabled`).

3.  **Asynchronous Command Execution:**
    -   `populate_tab_with_command` is the central function for running a command and displaying its output.
    -   It starts a new `threading.Thread` to avoid blocking the main UI thread.
    -   Inside the thread, it uses `asyncio.run` to execute the `_populate_tab_content_async` coroutine.
    -   `_populate_tab_content_async` uses `asyncio.create_subprocess_exec` to run the shell command and capture its `stdout` and `stderr`.
    -   Once the command completes, the result is passed back to the main UI thread using `self.after(0, ...)` to update the appropriate text widget.

4.  **Lazy Tab Loading (`on_plugin_tab_selected`):**
    -   This method is bound to the `<<NotebookTabChanged>>` event.
    -   It checks if the content for the newly selected tab has already been loaded. If not, it calls `populate_tab_with_command` to fetch and display the content.

## Usage
The script is intended to be run directly from the command line.

```bash
tm-gui
```

This will launch the main application window. The user can then interact with the buttons and tabs to explore the tool-manager's state.

## Related
-   This script is a consumer of many other `tm-*` CLI scripts, such as `tm-plugin-ls` and `tm-help-cfg`.
-   `.llm/bin/.tm.venv.sh.md` (The virtual environment system that ensures `python`, `tk`, and `ttkbootstrap` are available when this script is run).