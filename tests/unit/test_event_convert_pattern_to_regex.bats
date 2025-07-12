#!/usr/bin/env env-tm-bats

load '../../lib-shared/tm/bash/lib.event.sh'

setup() {
  : #set -x
}

teardown() {
  : #set +x
}

@test "_tm::event::__convert_pattern_to_regex converts literal dots" {
  read -r result <<< "$(_tm::event::__convert_pattern_to_regex "foo.bar.baz")"
  [ "$result" = "^foo\\.bar\\.baz$" ]
}

@test "_tm::event::__convert_pattern_to_regex converts single asterisks" {
  read -r result <<< "$(_tm::event::__convert_pattern_to_regex "foo.*.baz")"
  [ "$result" = "^foo\\.[^.]*\\.baz$" ]
}

@test "_tm::event::__convert_pattern_to_regex converts double asterisks" {
  read -r result <<< "$(_tm::event::__convert_pattern_to_regex "foo.**.baz")"
  [ "$result" = "^foo\\..*\\.baz$" ]
}

@test "_tm::event::__convert_pattern_to_regex handles mixed patterns" {
  read -r result <<< "$(_tm::event::__convert_pattern_to_regex "foo.*.**.baz")"
  [ "$result" = "^foo\\.[^.]*\\..*\\.baz$" ]
}

@test "_tm::event::__convert_pattern_to_regex handles leading and trailing asterisks" {
  read -r result <<< "$(_tm::event::__convert_pattern_to_regex "*.foo.**")"
  [ "$result" = "^[^.]*\\.foo\\..*$" ]
}

@test "_tm::event::__convert_pattern_to_regex handles only single asterisk" {
  read -r result <<< "$(_tm::event::__convert_pattern_to_regex "*")"
  [ "$result" = "^[^.]*$" ]
}

@test "_tm::event::__convert_pattern_to_regex handles only double asterisk" {
  read -r result <<< "$(_tm::event::__convert_pattern_to_regex "**")"
  [ "$result" = ".*" ]
}

@test "_tm::event::__convert_pattern_to_regex handles empty string" {
  read -r result <<< "$(_tm::event::__convert_pattern_to_regex "")"
  [ "$result" = "^$" ]
}

@test "_tm::event::__convert_pattern_to_regex handles pattern with no special characters" {
  read -r result <<< "$(_tm::event::__convert_pattern_to_regex "simplepattern")"
  [ "$result" = "^simplepattern$" ]
}

@test "_tm::event::__convert_pattern_to_regex handles multiple double asterisks" {
  read -r result <<< "$(_tm::event::__convert_pattern_to_regex "**.foo.**")"
  [ "$result" = "^.*\\.foo\\..*$" ]
}

@test "_tm::event::__convert_pattern_to_regex handles multiple single asterisks" {
  read -r result <<< "$(_tm::event::__convert_pattern_to_regex "*.foo.*")"
  [ "$result" = "^[^.]*\\.foo\\.[^.]*$" ]
}

@test "_tm::event::__convert_pattern_to_regex handles pattern with only dots" {
  read -r result <<< "$(_tm::event::__convert_pattern_to_regex "...")"
  [ "$result" = "^\\.\\.\\.$" ]
}