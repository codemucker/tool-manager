#!/usr/bin/env bash
source .bashrc
if [ -d "$TM_HOME/bin-dev" ]; then
  export PATH="$PATH:$TM_HOME/bin-dev"
fi

tm-dev-llm-diagram
tm-dev-llm-document
tm-dev-llm-index-functions
