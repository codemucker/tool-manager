---
title: tm-service
path: bin/tm-service
type: script
purpose: A general-purpose command to manage services defined by plugins.
dependencies:
  - bin/.tm.script.sh
  - bin/.tm.plugins.sh
  - bin/.tm.service.sh
tags:
  - service
  - management
---

## Overview
This script acts as a central dispatcher for managing services. Services are long-running processes defined in `.service` configuration files within a plugin. This script provides a unified interface to `start`, `stop`, `restart`, `pause`, and `list` these services.

## Design Philosophy
The script is designed as a simple command router. It parses the user's desired action (`--command`) and the target service (`--service` and `--plugin`) and then calls the appropriate function from the `.tm.service.sh` library to execute the request. This keeps the dispatcher script clean and delegates the complex logic of process management (handling PID files, logs, etc.) to the specialized library.

## Key Logic
1.  **Argument Parsing:** The script parses arguments to determine the command to execute (`start`, `stop`, etc.), the name of the service, and the plugin that owns the service.
2.  **Plugin Resolution:** It identifies the target plugin's unique ID. If a plugin is specified via the `--plugin` flag, it resolves it. If not, it defaults to the current plugin context (`$__TM_PLUGIN_ID`), which is useful when a plugin's own scripts are managing its services.
3.  **Command Dispatching:** It uses a `case` statement to route the specified command to the corresponding function in the `.tm.service.sh` library.
    *   `ls`: Calls `_tm::service::list_service_conf`.
    *   `start`: Calls `_tm::service::start`.
    *   `stop`: Calls `_tm::service::stop`.
    *   `restart`: Calls `_tm::service::stop` and then `_tm::service::start`.
    *   `pause`: Calls `_tm::service::pause`.
4.  **Execution:** The underlying functions in `.tm.service.sh` handle the actual process management, such as reading the `.service` file, executing the command, managing the PID file, and redirecting output to log files.

## Usage
```bash
# List all available services for a specific plugin
tm-service --plugin my-vendor/my-app --command ls

# Start a specific service
tm-service --plugin my-vendor/my-app --service web-server --command start

# Stop the 'api' service belonging to the 'my-vendor/my-app' plugin
tm-service -p my-vendor/my-app -s api -c stop

# Restart a service
tm-service -p my-vendor/my-app -s web-server -c restart
```

## Related
- `.llm/bin/.tm.service.sh.md` (Contains the core logic for starting, stopping, and managing services)
- `bin/tm-service-ls` (A shortcut for `tm-service --command ls`)
- `bin/tm-service-start` (A shortcut for `tm-service --command start`)
- `bin/tm-service-stop` (A shortcut for `tm-service --command stop`)