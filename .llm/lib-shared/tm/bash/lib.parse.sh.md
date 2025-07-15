---
title: lib.parse.sh
path: lib-shared/tm/bash/lib.parse.sh
type: library
purpose: Provides specialized parsing functions for git URLs and tool-manager plugin identifiers.
dependencies:
  - lib-shared/tm/bash/lib.log.sh
  - lib-shared/tm/bash/lib.util.sh
tags:
  - parsing
  - utility
  - git
  - plugin
  - identifier
---

## Overview
This library is a collection of specialized parsing utilities that are fundamental to the operation of the tool manager. It contains functions to deconstruct complex strings like Git repository URLs and various plugin identifier formats into their constituent parts (e.g., host, owner, name, version, vendor, prefix). This allows other scripts to work with these components in a structured way.

## Design Philosophy
The library is designed to be a central authority for interpreting common but complex string formats used throughout the system. By centralizing this logic, it ensures that all parts of the tool manager parse these identifiers consistently. The functions are robust, handling multiple formats (e.g., `git@`, `https://`, `prefix:name`, `vendor/name@version`) and performing validation to fail early if the input is malformed. The output is always a populated associative array, providing a clean and predictable interface for the calling script.

## Key Logic
1.  **`_tm::parse::git_url`:**
    *   Takes a Git URL and an associative array name as input.
    *   It first identifies the host (`github.com`, `gitlab.com`, etc.).
    *   It then uses a series of parameter expansions and regex matches to strip the protocol and host, separate the version tag (if present), and isolate the owner and repository name.
    *   Finally, it populates the output array with canonical `git@` and `https://` URLs, as well as the individual `owner`, `name`, `version`, and `host` components.
2.  **`_tm::parse::plugin` (Dispatcher):**
    *   This is the main entry point for parsing plugin identifiers.
    *   It inspects the input string and acts as a dispatcher, calling either `_tm::parse::plugin_id` if the string starts with `tm:plugin:`, or `_tm::parse::plugin_name` otherwise.
3.  **`_tm::parse::plugin_name`:**
    *   Parses "human-friendly" qualified names like `prefix:vendor/name@version`.
    *   It uses `IFS` (Internal Field Separator) to split the string based on the separators (`:`, `/`, `@`) to extract the `prefix`, `vendor`, `name`, and `version`.
    *   It performs validation to ensure the components adhere to the expected naming conventions (e.g., lowercase, no invalid characters).
    *   After parsing, it calls `__set_plugin_derived_vars`.
4.  **`_tm::parse::plugin_id`:**
    *   Parses the formal, machine-readable ID string: `tm:plugin:<space>:<vendor>:<name>:<version>:<prefix>`.
    *   It splits the string by the colon (`:`) delimiter into an array and assigns the parts to the appropriate variables.
    *   It performs similar validation to `plugin_name` and then calls `__set_plugin_derived_vars`.
5.  **`__set_plugin_derived_vars` (Internal Helper):**
    *   This is a crucial internal function called by both `plugin_name` and `plugin_id`.
    *   Using the basic parsed components (vendor, name, etc.), it constructs all the other necessary computed values: `qname` (qualified name), `qpath` (filesystem path), `install_dir`, `cfg_dir`, `cache_dir`, and more. This ensures all path and name logic is consistent and centralized.
6.  **`_tm::parse::boolean`:**
    *   A simple utility to convert various string representations of truth (`true`, `yes`, `1`, `t`) into a canonical `1` or `0`.

## Usage
```bash
# Parse a Git URL
declare -A git_info
_tm::parse::git_url git_info "https://github.com/some-user/my-repo.git#v2.1"
echo "Owner: ${git_info[owner]}, Repo: ${git_info[name]}, Version: ${git_info[version]}"

# Parse a human-friendly plugin name
declare -A plugin_info
_tm::parse::plugin plugin_info "my-prefix:my-vendor/my-plugin@1.0.0"
echo "Plugin Install Dir: ${plugin_info[install_dir]}"
echo "Plugin Config File: ${plugin_info[cfg_sh]}"

# Parse a formal plugin ID
_tm::parse::plugin plugin_info "tm:plugin::my-vendor:my-plugin:1.0.0:my-prefix"
echo "Plugin Qualified Path: ${plugin_info[qpath]}"
```

## Related
- This library is a foundational dependency for almost any script that deals with plugins, including `lib.cfg.sh`, and many of the `tm-plugin-*` scripts.