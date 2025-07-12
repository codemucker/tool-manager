---
title: tm-cfg-restore
path: bin/tm-cfg-restore
type: script
purpose: Restores the user's tool-manager configuration from a remote Git repository.
dependencies:
  - bin/tm-cfg-get
tags:
  - configuration
  - backup
  - restore
  - git
---

## Overview
This script is the counterpart to `tm-cfg-backup`. It is responsible for restoring a user's entire tool-manager configuration by cloning or pulling from a pre-configured remote Git repository. This allows users to easily synchronize their settings across multiple machines or recover their configuration after a fresh installation.

## Design Philosophy
The script is designed to handle two primary scenarios intelligently:
1.  **Fresh Restore:** If the local configuration directory (`$TM_PLUGINS_CFG_DIR`) is empty, the script assumes a fresh restore is needed. It retrieves the backup repository URL from the `TM_CFG_BACKUP_REPO` setting and performs a `git clone` to populate the directory.
2.  **Update/Sync:** If the local configuration directory already exists and contains files, the script assumes the user wants to update their local settings with the latest from the remote. It navigates into the directory and performs a `git pull` to synchronize the changes.

This dual-purpose logic makes the command flexible and safe to run, as it avoids overwriting existing files unintentionally.

## Key Logic
1.  **Check for Existing Config:** The script first checks if the `$TM_PLUGINS_CFG_DIR` exists and if it contains any files (`ls -A`).
2.  **Update Logic:**
    -   If the directory is not empty, it navigates into it and runs `git pull --ff-only`. The `--ff-only` flag ensures that the pull will only succeed if it is a fast-forward, preventing accidental merges and keeping the history clean.
3.  **Clone Logic:**
    -   If the directory is empty, it first retrieves the backup repository URL by calling `tm-cfg-get --tm TM_CFG_BACKUP_REPO`.
    -   It validates that the URL is a valid Git URL.
    -   It removes the now-empty configuration directory (`rmdir`) to allow `git clone` to create it.
    -   It then executes `git clone` to download the repository content into the configuration directory path.
4.  **Git Ignore:** Similar to the backup script, it ensures that the parent directory's `.gitignore` is configured correctly.

## Usage
To restore a configuration, the user must have previously set the `TM_CFG_BACKUP_REPO` variable.

```bash
# 1. (If on a new machine) Configure the backup repository URL
tm-cfg-set --tm TM_CFG_BACKUP_REPO git@github.com:user/my-tm-config-backup.git

# 2. Run the restore command
tm-cfg-restore
```

## Related
-   `.llm/bin/tm-cfg-backup.md` (The corresponding script to create a backup)
-   `.llm/bin/tm-cfg-get.md` (Used to retrieve the backup repository URL)
-   `.llm/bin/tm-cfg-set.md` (Used to set the backup repository URL)