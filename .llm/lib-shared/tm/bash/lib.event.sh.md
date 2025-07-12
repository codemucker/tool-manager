---
title: lib.event.sh
path: lib-shared/tm/bash/lib.event.sh
type: library
purpose: Provides a publish-subscribe event system for decoupled communication between scripts.
dependencies: []
tags:
  - events
  - pubsub
  - hooks
  - decoupled
---

## Overview
This library implements a simple yet powerful event-driven architecture for the tool manager. It allows different parts of the system to communicate with each other without having direct dependencies. Scripts can "fire" named events, and other scripts can register "listeners" (callback functions) that are executed when a matching event is fired.

## Design Philosophy
The event library is designed to promote loose coupling and extensibility. Instead of one script needing to know about and call another script directly, it can simply fire an event (e.g., `plugin.installed`). Any other script or plugin that cares about this event can subscribe to it and react accordingly. This makes it easy to add new functionality and logging, or to trigger workflows based on system activities, without modifying the original source code that fires the event.

## Key Logic
1.  **Event Listeners Storage:** A global associative array, `__tm_events_listeners`, stores the registered listeners. The keys of the array are regular expressions derived from the event patterns, and the values are space-separated strings of callback function names.
2.  **Pattern to Regex Conversion:** The `__convert_pattern_to_regex` function is a crucial piece of the logic. It translates simple wildcard patterns (e.g., `plugin.install.*`, `**.start`) into valid Bash regular expressions. This allows for flexible event subscriptions.
3.  **Registering Listeners (`_tm::event::on`):** When a listener is registered, its event pattern is converted to a regex, which is then used as the key to add the callback function to the `__tm_events_listeners` array.
4.  **Firing Events (`_tm::event::fire`):** When an event is fired, the function iterates through all the registered regex patterns in `__tm_events_listeners`. If the fired event name matches a regex, it invokes all the associated callback functions in a subshell, passing the event name, a unique event ID, a timestamp, and any additional arguments.
5.  **Once Listeners (`_tm::event::on::once`):** This is a convenience function that dynamically creates a temporary wrapper function. The wrapper calls the user's original callback and then immediately de-registers itself using `_tm::event::off`, ensuring it only runs once.

## Usage
```bash
# In a listener script (e.g., a logger plugin)
_my_logger() {
  local event_name="$1"
  local event_id="$2"
  local event_ts="$3"
  shift 3
  echo "EVENT [${event_name}] at ${event_ts}: $@" >> /tmp/tm_events.log
}

# Listen to all events fired by any plugin script
_tm::event::on "plugin.*" "_my_logger"

# In another script
_install_plugin() {
  # ... installation logic ...
  _tm::event::fire "plugin.install.success" "my-plugin"
}
```

## Related
- This is a foundational library and does not have direct dependencies, but it is used by many other scripts to enable decoupled communication.