---
title: tm-service-stop
path: bin/tm-service-stop
type: script
purpose: Stops a service defined by a plugin.
dependencies:
  - bin/tm-service
tags:
  - service
  - management
---

## Overview
This script is a convenient shortcut for stopping a running service defined by a plugin. It is a wrapper around the more general `tm-service` command.

## Design Philosophy
This script follows the principle of creating simple, focused commands for common operations. Instead of requiring users to type `tm-service --command stop`, this script provides a more intuitive command for stopping a service. It achieves this by simply calling `tm-service` with the `--command stop` argument preset, passing along any other arguments it receives.

## Key Logic
1.  **Execution:** The script executes `tm-service --command stop`.
2.  **Argument Forwarding:** It passes all of its own command-line arguments (`$@`) directly to the `tm-service` command. This allows users to use all the targeting options of `tm-service` (like `--plugin` and `--service`) with the `tm-service-stop` shortcut.

## Usage
```bash
# Stop the 'web-server' service from the 'my-vendor/my-app' plugin
tm-service-stop --plugin my-vendor/my-app --service web-server
```

## Related
- `.llm/bin/tm-service.md` (The main script that this is a shortcut for)
- `bin/tm-service-start` (The counterpart to this script)