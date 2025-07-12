---
title: tm-venv-run
path: bin-internal/tm-venv-run
type: script
purpose: Internal script to execute another script within a managed virtual environment.
dependencies:
  - bin/.tm.venv.sh
tags:
  - internal
  - venv
  - execution
  - python
  - docker
---

## Overview
This script is an internal utility for running other scripts inside a managed virtual environment (venv). It acts as a simple wrapper around the more complex logic defined in `.tm.venv.sh`. Its purpose is to provide a standardized entry point for executing scripts that have specific runtime dependencies (e.g., Python packages) which should be isolated from the global system.

## Design Philosophy
The script is intentionally minimal. It delegates all the heavy lifting of environment creation, dependency management, and execution to the `.tm.venv.sh` library. This keeps the `tm-venv-run` script itself clean and focused on a single task: initiating the venv execution process for a given script.

## Key Logic
1.  **Inclusion:** The script's first action is to include the `.tm.venv.sh` library, which contains all the necessary functions for venv management.
2.  **Delegation:** It calls the `_tm::venv::run` function from the included library.
3.  **Argument Passing:** It passes its own arguments directly to the `_tm::venv::run` function. The first argument is an empty string (as the runner is determined by the target script's directives), followed by the path to the script to execute and all subsequent arguments for that script.

## Usage
This script is not intended for direct user invocation. It is used internally by the tool-manager to run scripts that require a virtualized environment, based on directives found within those scripts.

## Related
- `.llm/bin/.tm.venv.sh.md` (Provides the core logic for creating, managing, and running commands within virtual environments)
- `.llm/bin/.tm.venv.directives.sh.md` (Handles the extraction of `require:` directives from scripts)