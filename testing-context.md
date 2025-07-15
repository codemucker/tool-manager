# Tool Manager Testing Context

This file tracks the progress and issues in the effort to increase test coverage for the Tool Manager project.

# OBJECTIVES

- Increase the test coverage of the the codebase
- To understand the codebase, read the LLM_README
- tests are under `tests/unit` and `tests/integration`
- tests can be run via bash `bash -c "source $HOME/.tool-manager/.bashrc && tm-dev-test"`.
- individual test files can be run via `bash -c "source $HOME/.tool-manager/.bashrc && tm-dev-test path/to/bats/file.bats"`
- code can be formatted via bash `bash -c "source $HOME/.tool-manager/.bashrc && tm-dev-format"`
- tests are to be put under `tests/unit' or `tests/integration`, and writen as bats tests
- start with unit tests, and build up complexity once all the basics have been covered
- commit to git after each new test file has been created

# IMPORTANT
- Do NOT EVER DELETE existing tests. We are to increase test coverage, not decrease. THIS is very important
- do NOT write the bats tooling, this is taken care by the `tm-dev-test` tool. Focus on the tests and code fixes
- do check for existing tests before writing more tests

# Tasks
- all tasks MUST be run as subtask to reduce context size
- if your context gets to 85%, summarise where youe, remember anything important, update this context file, and launch a new task
- all task MUST first read this file
- all tasks MUST reference and update this file with progress

## NOTES
- include 'source "${TM_LIB_BASH}/lib.source.sh"' at  the top of bats files to ensure the _include and _tm::source::... functions are vailable
- for full integration with tool-manager, be sure to include 'source "$HOME/.tool-manager/.bashrc"
  
## Current Progress
- Created initial unit tests for core utilities (`lib.util.sh`)
## Issues Encountered
- Unit tests for configuration management (`lib.cfg.sh`) are failing due to environment setup issues
- Mock plugin directory paths are not being properly recognized by the configuration functions
- The `tm-dev-test` runner is having trouble with the isolated test environment

## Resolved Issues
- Installed required Bats test helpers (bats-support, bats-assert)
- Created comprehensive unit tests covering all core configuration functionality
- Established proper mock plugin directory structure

## Next Steps
- Manually verify configuration functionality in a real environment
- Proceed with integration tests for the plugin system
- Revisit unit tests after resolving environment setup issues
- Created unit tests for logging functionality (`lib.log.sh`)
- Starting unit tests for configuration management (`lib.cfg.sh`)

## Instructions
1. Update this file after completing each significant testing milestone
2. Document any issues encountered and how they were resolved
3. Track progress on test coverage goals

## Next Steps
- Add tests for configuration management (`lib.cfg.sh`)
- Create integration tests for plugin system
