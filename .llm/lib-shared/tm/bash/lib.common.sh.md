---
title: lib.common.sh
path: lib-shared/tm/bash/lib.common.sh
type: library
purpose: A convenience script to source a standard set of commonly used libraries.
dependencies:
  - lib-shared/tm/bash/lib.log.sh
  - lib-shared/tm/bash/lib.util.sh
  - lib-shared/tm/bash/lib.parse.sh
  - lib-shared/tm/bash/lib.validate.sh
  - lib-shared/tm/bash/lib.args.sh
  - lib-shared/tm/bash/lib.cfg.sh
  - lib-shared/tm/bash/lib.source.sh
tags:
  - utility
  - convenience
  - source
---

## Overview
This script serves as a time-saving utility for developers. Its sole purpose is to load a pre-defined set of the most frequently used core libraries into the current shell session with a single `source` command.

## Design Philosophy
The script embodies the "Don't Repeat Yourself" (DRY) principle. Instead of having every script list the same six or seven core libraries to source, they can source this single file. This simplifies script setup, reduces boilerplate, and ensures that scripts are always working with the standard set of foundational tools.

## Key Logic
The script contains a single line of code that calls `_tm::source::include_once`. This function, from `lib.source.sh`, ensures that each of the specified libraries (`lib.log.sh`, `lib.util.sh`, etc.) is sourced only one time, preventing redundant loading and potential side effects.

## Usage
```bash
# At the top of your script, instead of sourcing multiple files:
_tm::source::include_once @tm/lib.common.sh

# Now you can use functions from any of the included libraries
_info "This message is from lib.log.sh"
_tm::util::is_command_installed "git"
```

## Related
- `.llm/lib-shared/tm/bash/lib.source.sh.md` (Provides the `_tm::source::include_once` function that this script relies on)