#!/usr/bin/env bash
cd "$(dirname "${BASH_SOURCE[0]}")"

source .bashrc
export PATH="$PATH:$TM_HOME/bin-dev"

tm-dev-llm-diagram
tm-dev-llm-document --lint
tm-dev-llm-index-functions
