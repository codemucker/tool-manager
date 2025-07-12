#!/usr/bin/env bash

# Common test helper functions for BATs tests

setup_suite() {
    # Setup common test environment
    TEST_ROOT="$(mktemp -d)"
    
    # Stub input functions to avoid blocking on user prompts
    _confirm() {
        echo "STUB _confirm. Override in your test"
        return 1
    }
    _read() {
        echo "STUB _read. Override in your test"
        return 1
    }
    _read_yn() {
        echo "STUB _read_yn. Override in your test"
        return 1
    }
    _read_not_empty() {
        echo "STUB _read_not_empty. Override in your test"
        return 1
    }
    export -f _confirm _read _read_yn _read_not_empty
}

teardown_suite() {
    # Clean up test environment
    rm -rf "$TEST_ROOT"
}

assert_success() {
    if [ "$status" -ne 0 ]; then
        echo "Command failed with exit status $status"
        return 1
    fi
}

assert_failure() {
    if [ "$status" -eq 0 ]; then
        echo "Command succeeded but expected failure"
        return 1
    fi
}

assert_output_contains() {
    local pattern="$1"
    if [[ ! "$output" =~ $pattern ]]; then
        echo "Output does not contain '$pattern'"
        echo "Actual output: $output"
        return 1
    fi
}