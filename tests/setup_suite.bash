#!/usr/bin/env bash

setup_suite() {
    # Source core libraries in correct dependency order
    source "${BATS_TEST_DIRNAME}/../lib-shared/tm/bash/lib.source.sh"
    source "${BATS_TEST_DIRNAME}/../lib-shared/tm/bash/lib.log.sh"
    source "${BATS_TEST_DIRNAME}/../lib-shared/tm/bash/lib.util.sh"
    source "${BATS_TEST_DIRNAME}/../lib-shared/tm/bash/lib.path.sh"
    source "${BATS_TEST_DIRNAME}/../lib-shared/tm/bash/lib.validate.sh"
    source "${BATS_TEST_DIRNAME}/../lib-shared/tm/bash/lib.common.sh"
    
    # Setup common test environment
    TEST_ROOT="$(mktemp -d)"
    
    # Initialize logging with minimal output
    TM_LOG="error"
    _tm::log::init
}

teardown_suite() {
    # Clean up test environment
    rm -rf "$TEST_ROOT"
}