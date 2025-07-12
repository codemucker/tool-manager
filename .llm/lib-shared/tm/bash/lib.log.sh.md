---
title: lib.log.sh
path: lib-shared/tm/bash/lib.log.sh
type: library
purpose: Provides a comprehensive, configurable, and feature-rich logging framework.
dependencies: []
tags:
  - logging
  - debugging
  - tracing
  - utility
  - framework
---

## Overview
This library is the standard logging framework for the entire tool manager ecosystem. It offers a highly configurable system with multiple log levels (finest, trace, debug, info, warn, error), various output channels (console, file, syslog), and rich context formatting (timestamps, PID, caller info, etc.). It is designed to be both powerful for developers during debugging and quiet for end-users in production.

## Design Philosophy
The core design is centered around dynamic reconfiguration and performance. The logging functions (`_info`, `_debug`, etc.) are dynamically redefined based on the configuration provided in the `TM_LOG` environment variable. If a log level is disabled, its corresponding function is replaced with a no-op (`:`), meaning there is virtually zero performance overhead for disabled log levels. This allows for verbose logging during development without impacting production performance. The framework is controlled entirely by a single CSV string in `TM_LOG`, making it easy to configure from the command line for specific debugging sessions.

## Key Logic
1.  **Configuration (`_tm::log::set_opts`):** This is the central function. It parses the comma-separated value from the `$TM_LOG` variable. Based on the options, it redefines the logging functions (`_finest`, `_trace`, etc.) to either call the main `__msg` function or to be an empty function. It also dynamically builds a `__details` function to prepend contextual information (like timestamps, caller file/function) to each log message.
2.  **Main Message Handler (`_tm::log::__msg`):** All active logging functions call this internal handler. It checks against any configured name filters (`@logger_name`), constructs the final log string by calling `__details`, and then dispatches the message to the enabled output channels.
3.  **Output Channels:**
    *   `__to_console`: Prints the colored log message to `stderr`.
    *   `__to_syslog`: Sends the uncolored message to the system's `logger` command.
    *   `__to_file`: Appends the uncolored message to the file specified by `$TM_LOG_FILE`. It also handles log rotation when the file exceeds `$TM_LOG_FILE_MAX_BYTES`.
4.  **Logger Name Management:** The library supports a hierarchical logger name system. `_tm::log::push_name` and `_tm::log::push_child` allow scripts to temporarily change or append to the `TM_LOG_NAME` for a block of code, and `_tm::log::pop` restores it. This is useful for identifying the source of logs in complex scripts.
5.  **Stack Tracing:** The `_tm::log::stacktrace` function can be called directly or enabled via the `stack` option in `TM_LOG` to print a stack trace with every log message. `_tm::log::stacktrace::on_error` sets a `trap` to automatically print a stack trace on any script error.

## Usage
```bash
# Basic logging (assuming default TM_LOG="info")
_info "This is an info message."
_warn "This is a warning."
_error "This is an error."
_debug "This message will not appear."

# Enable trace logging with caller info for a single run
TM_LOG="trace,caller" tm-some-command

# Enable finest logging, with all context, stack traces, and file output
export TM_LOG="finest,all,stack,file"
export TM_LOG_FILE="/tmp/tm-debug.log"
tm-another-command

# Use hierarchical loggers
_tm::log::push_name "installer"
_info "Starting installation."
_tm::log::push_child "download"
_debug "Downloading from $URL"
# ...
_tm::log::pop
_info "Download complete."
_tm::log::pop
```

## Related
- This is a foundational library with no dependencies on other `tm` libraries. It is a core component used by almost every other script in the system.