---
title: tm-cfg-backup
path: bin/tm-cfg-backup
type: script
purpose: Backs up the user's tool-manager configuration directory to a remote Git repository.
dependencies:
  - bin/tm-cfg-get
tags:
  - configuration
  - backup
  - git
---

## Overview
This script provides a mechanism for users to back up their entire tool-manager configuration to a remote Git repository. It treats the main configuration directory (`$TM_PLUGINS_CFG_DIR`) as a Git repository, allowing all plugin and tool-manager settings to be version-controlled and stored securely off-site.

## Design Philosophy
The script is designed to be a simple, idempotent backup utility. It automates the process of initializing a Git repository (if one doesn't exist), adding all configuration files, committing them, and pushing to a remote origin. The remote repository URL is itself a configuration value, retrieved via `tm-cfg-get`, making the backup destination configurable by the user.

## Key Logic
1.  **Set Target Directory:** The script identifies the configuration directory to be backed up, which is `$TM_PLUGINS_CFG_DIR`.
2.  **Change Directory:** It navigates into the configuration directory to perform Git operations.
3.  **Git Ignore:** It ensures that the parent directory's `.gitignore` file is configured to *not* ignore the configuration directory itself, which is crucial if the entire user config (`~/.config`) is a Git repository.
4.  **Initialize Repository (if needed):**
    -   It checks for the existence of a `.git` subdirectory.
    -   If one does not exist, it initializes a new bare Git repository.
    -   It then retrieves the backup repository URL from the `TM_CFG_BACKUP_REPO` configuration key using `tm-cfg-get`.
    -   It adds this URL as the `origin` remote.
5.  **Commit and Push:**
    -   It stages all files in the directory using `git add .`.
    -   It creates a new commit with the static message "Save config".
    -   It pushes the commit to the `origin` remote. If the push fails, the script will exit with an error.

## Usage
To use this script, the user must first set the backup repository URL in their tool-manager configuration.

```bash
# 1. Configure the backup repository
tm-cfg-set --tm TM_CFG_BACKUP_REPO git@github.com:user/my-tm-config-backup.git

# 2. Run the backup command
tm-cfg-backup
```

## Related
-   `.llm/bin/tm-cfg-get.md` (Used to retrieve the backup repository URL)
-   `.llm/bin/tm-cfg-set.md` (Used to set the backup repository URL)
-   `.llm/bin/tm-cfg-restore.md` (The corresponding script to restore a backup)