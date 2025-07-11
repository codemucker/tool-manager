---
title: tm-update-self
path: bin/tm-update-self
type: script
purpose: Updates the core Tool Manager installation from its Git repository.
dependencies:
  - bin/.tm.script.sh
tags:
  - core
  - management
  - update
---

## Overview
This script updates the core Tool Manager installation by pulling the latest changes from its upstream Git repository.

## Design Philosophy
The script is a simple, focused utility for self-updating. It performs a single, critical task: changing to the `$TM_HOME` directory and running `git pull`. It uses the `--ff-only` (fast-forward only) flag to ensure that the update is clean and does not attempt to create a merge commit, which could lead to an unstable state. This makes the update process safe and predictable.

## Key Logic
1.  **Change Directory:** The script navigates into the root directory of the Tool Manager installation (`$TM_HOME`).
2.  **Git Pull:** It executes `git pull --ff-only` to fetch and apply the latest changes from the remote `origin` repository.

## Usage
```bash
# Update the core tool-manager scripts
tm-update-self
```

## Related
- `bin/tm-update-all` (A wrapper script that calls this script first, then updates all plugins)
- `bin/tm-update-self-diff` (Shows the changes that a self-update would apply)