---
title: tm-space
path: bin/tm-space
type: script
purpose: Switches the active Tool Manager "space" to another.
dependencies:
  - bin/.tm.script.sh
  - bin/.tm.space.sh
tags:
  - core
  - space
  - environment
---

## Overview
This script is the primary command for switching between different Tool Manager "spaces". A space is a self-contained environment with its own set of plugins, configurations, and services. This allows a user to have separate, isolated setups for different projects or tasks (e.g., a "work" space and a "personal" space).

## Design Philosophy
The script acts as a simple frontend for the more complex logic contained within the `.tm.space.sh` library. It provides a user-friendly way to identify a space (either by its short `key` or its unique `guid`) and then triggers the launch process. The core `_tm::space::launch_by_file` function handles the heavy lifting of changing the environment, which typically involves modifying the main `.tm.conf` symlink and then reloading the environment.

## Key Logic
1.  **Argument Parsing:** The script accepts either a `--key` or a `--guid` to identify the target space. One of these is required.
2.  **Space File Resolution:**
    *   If a `--guid` is provided, it calls `_tm::space::file::get_by_guid` to find the absolute path to the corresponding space configuration file.
    *   If a `--key` is provided, it calls `_tm::space::file::get_by_key`.
3.  **Launch:** Once the space's configuration file is located, the script calls `_tm::space::launch_by_file`, passing the file path. This function in the `.tm.space.sh` library is responsible for performing the actual switch.

## Usage
```bash
# Switch to a space using its key
tm-space my-work-space

# Switch to a space using its unique GUID
tm-space --guid "123e4567-e89b-12d3-a456-426614174000"
```

## Related
- `.llm/bin/.tm.space.sh.md` (Contains the core logic for managing and launching spaces)
- `bin/tm-space-ls` (Lists all available spaces)
- `bin/tm-space-create` (Creates a new space)