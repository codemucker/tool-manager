---
title: env-tm-python
path: bin-defaults/env-tm-python
type: script
purpose: A shebang runner that executes a Python script within a managed virtual environment.
dependencies:
  - bin/.tm.boot.sh
  - bin/.tm.venv.sh
tags:
  - python
  - venv
  - runner
  - environment
---

## Overview
This script acts as a specialized shebang interpreter (`#!/usr/bin/env env-tm-python`) for running Python scripts. Its primary purpose is to automatically create and manage a Python virtual environment (venv) for the script, based on directives found in the script's comments. This ensures that Python dependencies are isolated and managed on a per-script or per-plugin basis.

## Design Philosophy
The script is designed to make writing and running Python scripts within the tool-manager ecosystem as simple as possible. It abstracts the complexity of venv creation and dependency installation. A developer can simply list their required `pip` packages in the script's header, and this runner will handle the rest, providing a seamless and reproducible execution environment.

## Key Logic
1.  **Environment Initialization:** It sources the core `.tm.boot.sh` and `.tm.venv.sh` scripts to bring in the necessary framework functions.
2.  **Argument Parsing:** The script parses its arguments to find the path to the Python script to be executed.
3.  **Delegation to Venv:** It calls the `__tm::venv::run` function from the `.tm.venv.sh` library.
4.  **Execution:** It passes `"python3"` as the desired runner, the script path, and all remaining arguments to the `__tm::venv::run` function. This function then handles the logic of checking for directives, creating/updating the venv, installing dependencies, and finally executing the Python script within that activated environment.

## Usage
To use this runner, start your Python script with the following shebang line and add any `pip` dependencies as `@require` directives:

```python
#!/usr/bin/env env-tm-python
#
# @require:pip=requests
# @require:pip=beautifulsoup4

import requests
from bs4 import BeautifulSoup

print("Requests and BeautifulSoup are installed and available!")
```

Then, make the script executable (`chmod +x my_script.py`) and run it directly:

```bash
./my_script.py
```

## Related
- `.llm/bin/.tm.venv.sh.md` (Provides the core logic for creating, managing, and running commands within virtual environments)
- `.llm/bin/.tm.venv.directives.sh.md` (Handles the extraction of `@require` directives from scripts)