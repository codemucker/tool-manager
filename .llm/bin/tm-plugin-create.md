---
title: tm-plugin-create
path: bin/tm-plugin-create
type: script
purpose: Creates a new Tool Manager plugin skeleton from a template.
dependencies:
  - bin/.tm.script.sh
tags:
  - plugin
  - generator
  - development
---

## Overview
This script is a developer tool for bootstrapping a new Tool Manager plugin. It interactively prompts the user for necessary details like the plugin's name, vendor, and Git repository URL, and then generates a complete directory structure with template files.

## Design Philosophy
The script is designed to accelerate plugin development by automating the creation of boilerplate code and configuration. It uses a series of internal helper functions (e.g., `_tm::plugin::create::__readme_template`) to generate the content for each file, ensuring consistency and adherence to the Tool Manager plugin structure. The process is interactive, guiding the user through the required inputs with validation to prevent common errors.

## Key Logic
1.  **Argument Parsing & Interactive Prompts:** The script first checks for command-line arguments for the plugin name, repo, description, etc. If any are missing, it interactively prompts the user for the required information, providing sensible defaults and validation (e.g., for the plugin name format).
2.  **Path and Name Resolution:** It uses `_tm::parse::plugin_name` to derive the fully qualified name, installation directory, and other variables from the user's input.
3.  **Directory Creation:** It creates the main plugin directory (e.g., `$TM_PLUGINS_DIR/vendor/my-plugin`) and a `bin` subdirectory.
4.  **Template Generation:** It calls a series of internal `__*_template` functions to create the following files with placeholder content:
    *   `README.md`: Basic documentation.
    *   `.bashrc`: For exporting environment variables.
    *   `plugin-enable` / `plugin-disable`: Hook scripts.
    *   `bin/.common.sh`: A shared library for the plugin's scripts.
    *   `bin/<plugin-name>-helloworld`: An example script.
5.  **Git Initialization:** It initializes a new Git repository in the created directory, adds the generated files, and creates an initial commit. If a repository URL was provided, it adds it as the `origin` remote.
6.  **Enable Prompt:** After creation, it asks the user if they want to enable the new plugin immediately.

## Usage
```bash
# Run interactively, the script will prompt for all details
tm-plugin-create

# Provide the name and have the script prompt for the rest
tm-plugin-create my-vendor/my-new-plugin

# Provide all details via flags
tm-plugin-create --name my-new-plugin --vendor my-vendor --repo "git@github.com:my-vendor/my-new-plugin.git" --desc "Does amazing things."
```

## Related
- `.llm/bin/.tm.plugin.sh.md` (Provides parsing and path logic)