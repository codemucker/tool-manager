#!/usr/bin/env bash
cd "$(dirname "${BASH_SOURCE[0]}")"

source .bashrc
tm-dev-format --apply
tm-dev-shellcheck --severity error
tm-dev-test