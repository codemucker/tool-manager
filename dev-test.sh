#!/usr/bin/env bash
cd "$(dirname "${BASH_SOURCE[0]}")"

source .bashrc
export PATH="$PATH:$TM_HOME/bin-dev"

tm-dev-format --apply
tm-dev-shellcheck --severity error
tm-dev-test
tm-dev-llm-document --lint