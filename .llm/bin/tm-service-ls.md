---
title: tm-service-ls
path: bin/tm-service-ls
type: script
purpose: Lists all available services, optionally filtered by plugin.
dependencies:
  - bin/tm-service
tags:
  - service
  - management
  - list
---

## Overview
This script is a convenient shortcut for listing services defined by plugins. It is a wrapper around the more general `tm-service` command.

## Design Philosophy
This script follows the principle of creating simple, focused commands for common operations. Instead of requiring users to type `tm-service --command ls`, this script provides a more intuitive, `ls`-style command specifically for listing services. It achieves this by simply calling `tm-service` with the `--command ls` argument preset, passing along any other arguments it receives.

## Key Logic
1.  **Execution:** The script executes `tm-service --command ls`.
2.  **Argument Forwarding:** It passes all of its own command-line arguments (`$@`) directly to the `tm-service` command. This allows users to use all the filtering options of `tm-service` (like `--plugin` or `--vendor`) with the `tm-service-ls` shortcut.

## Usage
```bash
# List all services from all plugins
tm-service-ls

# List all services for a specific plugin
tm-service-ls --plugin my-vendor/my-app
```

## Related
- `.llm/bin/tm-service.md` (The main script that this is a shortcut for)