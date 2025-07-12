---
title: tm-service-start
path: bin/tm-service-start
type: script
purpose: Starts a service defined by a plugin.
dependencies:
  - bin/tm-service
tags:
  - service
  - management
---

## Overview
This script is a convenient shortcut for starting a service defined by a plugin. It is a wrapper around the more general `tm-service` command.

## Design Philosophy
This script follows the principle of creating simple, focused commands for common operations. Instead of requiring users to type `tm-service --command start`, this script provides a more intuitive command for starting a service. It achieves this by simply calling `tm-service` with the `--command start` argument preset, passing along any other arguments it receives.

## Key Logic
1.  **Execution:** The script executes `tm-service --command start`.
2.  **Argument Forwarding:** It passes all of its own command-line arguments (`$@`) directly to the `tm-service` command. This allows users to use all the targeting options of `tm-service` (like `--plugin` and `--service`) with the `tm-service-start` shortcut.

## Usage
```bash
# Start the 'web-server' service from the 'my-vendor/my-app' plugin
tm-service-start --plugin my-vendor/my-app --service web-server
```

## Related
- `.llm/bin/tm-service.md` (The main script that this is a shortcut for)
- `bin/tm-service-stop` (The counterpart to this script)