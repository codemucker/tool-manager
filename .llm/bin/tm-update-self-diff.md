---
title: tm-update-self-diff
path: bin/tm-update-self-diff
type: script
purpose: Shows the file differences between the local and remote Tool Manager repository.
dependencies:
  - bin/.tm.script.sh
tags:
  - core
  - management
  - update
  - git
---

## Overview
This script provides a "dry run" for `tm-update-self`. It shows a list of files that have been changed on the remote `origin/main` branch since the last local update, allowing the user to see what changes an update would apply before running it.

## Design Philosophy
The script is a simple and safe informational tool. It uses standard Git commands to compare the local and remote states without making any changes to the local working directory. This gives the user confidence and transparency about the update process.

## Key Logic
1.  **Change Directory:** The script navigates into the root directory of the Tool Manager installation (`$TM_HOME`).
2.  **Git Fetch:** It runs `git fetch origin` to download the latest information from the remote repository without merging any changes.
3.  **Git Diff:** It executes `git diff --name-only origin/main` to compare the current local `HEAD` with the newly fetched state of the `origin/main` branch. The `--name-only` flag ensures that only the filenames of changed files are printed, providing a concise summary.

## Usage
```bash
# See what files have changed on the remote before updating
tm-update-self-diff
```

## Related
- `bin/tm-update-self` (Applies the changes that this script previews)