#!/usr/bin/env env-tm-bats

load '../../lib-shared/tm/bash/lib.parse.sh'

# Mock _fail to prevent script exit on expected failures
_fail() {
  echo "MOCKED_FAIL: $1" >&2
  exit 1 # Exit the current test, not the entire suite
}

# Mock _finest and _is_finest to prevent debug output
_finest() {
  : # Do nothing
}

_is_finest() {
  return 1 # Always return false
}

# Define these variables as they are used in lib.parse.sh
# Assuming common default values if not explicitly set by env-tm-bats
__TM_SEP_PREFIX_NAME=":"
__TM_SEP_PREFIX_DIR="__"
__TM_NO_VENDOR="no-vendor"
__TM_NAME="tool-manager" # Used in _tm::parse::__set_plugin_derived_vars

# Mock _tm::util::array::print as it's used in _tm::parse::plugin_name and _tm::parse::plugin_id
_tm::util::array::print() {
  local -n arr="$1"
  local key
  local output=""
  for key in "${!arr[@]}"; do
    output+="[$key]='${arr[$key]}' " # Quote the value
  done
  echo "$output"
}

@test "_tm::parse::plugin_name - basic name" {
  declare -A result
  _tm::parse::plugin_name result "myplugin"
  [ "${result[vendor]}" = "" ]
  [ "${result[name]}" = "myplugin" ]
  [ "${result[version]}" = "" ]
  [ "${result[prefix]}" = "" ]
  [ "${result[qname]}" = "myplugin" ]
  [ "${result[qpath]}" = "no-vendor/myplugin" ]
  [[ "${result[key]}" =~ "no-vendor__myplugin__vmain" ]]
}

@test "_tm::parse::plugin_name - name with version" {
  declare -A result
  _tm::parse::plugin_name result "myplugin@1.0.0"
  [ "${result[vendor]}" = "" ]
  [ "${result[name]}" = "myplugin" ]
  [ "${result[version]}" = "1.0.0" ]
  [ "${result[prefix]}" = "" ]
  [ "${result[qname]}" = "myplugin@1.0.0" ]
  [ "${result[qpath]}" = "no-vendor/myplugin" ]
  [[ "${result[key]}" =~ "no-vendor__myplugin__v1.0.0" ]]
}

@test "_tm::parse::plugin_name - vendor/name" {
  declare -A result
  _tm::parse::plugin_name result "myvendor/myplugin"
  [ "${result[vendor]}" = "myvendor" ]
  [ "${result[name]}" = "myplugin" ]
  [ "${result[version]}" = "" ]
  [ "${result[prefix]}" = "" ]
  [ "${result[qname]}" = "myvendor/myplugin" ]
  [ "${result[qpath]}" = "myvendor/myplugin" ]
  [[ "${result[key]}" =~ "myvendor__myplugin__vmain" ]]
}

@test "_tm::parse::plugin_name - vendor/name@version" {
  declare -A result
  _tm::parse::plugin_name result "myvendor/myplugin@2.0"
  [ "${result[vendor]}" = "myvendor" ]
  [ "${result[name]}" = "myplugin" ]
  [ "${result[version]}" = "2.0" ]
  [ "${result[prefix]}" = "" ]
  [ "${result[qname]}" = "myvendor/myplugin@2.0" ]
  [ "${result[qpath]}" = "myvendor/myplugin" ]
  [[ "${result[key]}" =~ "myvendor__myplugin__v2.0" ]]
}

@test "_tm::parse::plugin_name - prefix:name" {
  declare -A result
  _tm::parse::plugin_name result "myprefix:myplugin"
  [ "${result[vendor]}" = "" ]
  [ "${result[name]}" = "myplugin" ]
  [ "${result[version]}" = "" ]
  [ "${result[prefix]}" = "myprefix" ]
  [ "${result[qname]}" = "myprefix:myplugin" ]
  [ "${result[qpath]}" = "no-vendor/myplugin__myprefix" ]
  [[ "${result[key]}" =~ "no-vendor__myplugin__vmain__myprefix" ]]
}

@test "_tm::parse::plugin_name - prefix:vendor/name@version" {
  declare -A result
  _tm::parse::plugin_name result "myprefix:myvendor/myplugin@3.0"
  [ "${result[vendor]}" = "myvendor" ]
  [ "${result[name]}" = "myplugin" ]
  [ "${result[version]}" = "3.0" ]
  [ "${result[prefix]}" = "myprefix" ]
  [ "${result[qname]}" = "myprefix:myvendor/myplugin@3.0" ]
  [ "${result[qpath]}" = "myvendor/myplugin__myprefix" ]
  [[ "${result[key]}" =~ "myvendor__myplugin__v3.0__myprefix" ]]
}

@test "_tm::parse::plugin_name - prefix__name (dir separator)" {
  declare -A result
  _tm::parse::plugin_name result "myprefix__myplugin"
  [ "${result[vendor]}" = "" ]
  [ "${result[name]}" = "myplugin" ]
  [ "${result[version]}" = "" ]
  [ "${result[prefix]}" = "myprefix" ]
  [ "${result[qname]}" = "myprefix:myplugin" ]
  [ "${result[qpath]}" = "no-vendor/myplugin__myprefix" ]
  [[ "${result[key]}" =~ "no-vendor__myplugin__vmain__myprefix" ]]
}

@test "_tm::parse::plugin_name - invalid name format (empty)" {
  run _tm::parse::plugin_name result ""
  [ "$status" -ne 0 ]
  [[ "$output" =~ "MOCKED_FAIL: Invalid plugin name format. Missing name after prefix separator. From input name ''" ]]
}

@test "_tm::parse::plugin_name - invalid name format (uppercase)" {
  run _tm::parse::plugin_name result "MyPlugin"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "MOCKED_FAIL: Invalid plugin name format. Use lowercase letters, numbers, hyphens. Start with letter/number. Instead got 'MyPlugin' from input 'MyPlugin'" ]]
}

@test "_tm::parse::plugin_name - missing name after vendor slash should fail" {
  run _tm::parse::plugin_name result "myvendor/"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "MOCKED_FAIL: Invalid plugin name format. Missing name after vendor slash. From input name 'myvendor/'" ]]
}

@test "_tm::parse::plugin_name - missing name after prefix colon should fail" {
  run _tm::parse::plugin_name result "myprefix:"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "MOCKED_FAIL: Invalid plugin name format. Missing name after prefix separator. From input name 'myprefix:'" ]]
}

@test "_tm::parse::plugin_id - full ID" {
  declare -A result
  _tm::parse::plugin_id result "tm:plugin:myspace:myvendor:myplugin:1.0.0:myprefix"
  [ "${result[vendor]}" = "myvendor" ]
  [ "${result[name]}" = "myplugin" ]
  [ "${result[version]}" = "1.0.0" ]
  [ "${result[prefix]}" = "myprefix" ]
  [ "${result[qname]}" = "myprefix:myvendor/myplugin@1.0.0" ]
  [ "${result[qpath]}" = "myvendor/myplugin__myprefix" ]
  [[ "${result[key]}" =~ "myvendor__myplugin__v1.0.0__myprefix" ]]
  [ "${result[id]}" = "tm:plugin:myspace:myvendor:myplugin:1.0.0:myprefix" ]
}

@test "_tm::parse::plugin_id - ID with empty space, version, prefix" {
  declare -A result
  _tm::parse::plugin_id result "tm:plugin::myvendor:myplugin::"
  [ "${result[vendor]}" = "myvendor" ]
  [ "${result[name]}" = "myplugin" ]
  [ "${result[version]}" = "" ]
  [ "${result[prefix]}" = "" ]
  [ "${result[qname]}" = "myvendor/myplugin" ]
  [ "${result[qpath]}" = "myvendor/myplugin" ]
  [[ "${result[key]}" =~ "myvendor__myplugin__vmain" ]]
  [ "${result[id]}" = "tm:plugin::myvendor:myplugin::" ]
}

@test "_tm::parse::plugin_id - invalid ID (missing name)" {
  run _tm::parse::plugin_id result "tm:plugin:myspace:myvendor::1.0.0:myprefix"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "MOCKED_FAIL: Invalid plugin name format.Is empty. From id 'tm:plugin:myspace:myvendor::1.0.0:myprefix'" ]]
}

@test "_tm::parse::plugin_id - invalid ID (missing tm prefix)" {
  run _tm::parse::plugin_id result "plugin:myspace:myvendor:myplugin:1.0.0:myprefix"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "MOCKED_FAIL: Not a valid plugin id. expected 'tm:plugin:<space>:<vendor>:<name>:<version>:<prefix>', but got 'plugin:myspace:myvendor:myplugin:1.0.0:myprefix'" ]]
}

@test "_tm::parse::plugin - dispatch to plugin_id" {
  declare -A result
  _tm::parse::plugin result "tm:plugin:myspace:myvendor:myplugin:1.0.0:myprefix"
  [ "${result[name]}" = "myplugin" ]
  [ "${result[id]}" = "tm:plugin:myspace:myvendor:myplugin:1.0.0:myprefix" ]
}

@test "_tm::parse::plugin - dispatch to plugin_name" {
  declare -A result
  _tm::parse::plugin result "myvendor/myplugin@1.0.0"
  [ "${result[name]}" = "myplugin" ]
  [ "${result[version]}" = "1.0.0" ]
  [ "${result[qname]}" = "myvendor/myplugin@1.0.0" ]
}
@test "_tm::parse::plugin - tool-manager plugin" {
  declare -A result
  _tm::parse::plugin result "tool-manager"
  [ "${result[is_tm]}" = "true" ]
  [ "${result[name]}" = "tool-manager" ]
  [ "${result[qname]}" = "tool-manager" ]
  [ "${result[key]}" = "tool-manager" ]
  [ "${result[id]}" = "tm:plugin:::tool-manager::" ]
}