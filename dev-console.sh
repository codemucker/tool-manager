#!/usr/bin/env bash
source .bashrc

# Purpose: Starts an interactive bash shell with the TM environment configured for development.
# This script is intended for use by developers working on the TM project itself.
# It sets up the necessary environment variables and includes the TM internal and development binaries in the PATH.
# Example: bin/tm-dev-console
#
if [ -d "$TM_HOME/bin-internal" ]; then
  export PATH="$PATH:$TM_HOME/bin-internal"
fi
if [ -d "$TM_HOME/bin-dev" ]; then
  export PATH="$PATH:$TM_HOME/bin-dev"
fi
if [ -d "$TM_HOME/bin-experimental" ]; then
  export PATH="$PATH:$TM_HOME/bin-experimental"
fi
bash --init-file "$TM_BIN/.bashrc" -i
