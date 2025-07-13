#!/usr/bin/env bash
source .bashrc
tm-dev-format --apply
tm-dev-test
tm-dev-llm-verify

