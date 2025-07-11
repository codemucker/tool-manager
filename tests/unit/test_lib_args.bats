#!/usr/bin/env env-tm-bats

source "${TM_LIB_BASH}/lib.source.sh"
_tm::source::include_once @tm/lib.log.sh @tm/lib.validate.sh @tm/lib.args.sh

# Load necessary libraries for testing
# lib.source.sh must be loaded first as it provides _tm::source::include_once
# We use 'source' in setup to ensure functions are available in the test environment
# and to avoid issues with 'load' and internal dependencies.


setup() {

  # Mock _error, _fail, and _die functions to prevent script exit during tests
  _error() {
    echo "ERROR: $@" >&2
  }

  _fail() {
    echo "FAIL: $@" >&2
    exit 1
  }

  _die() {
    echo "DIE: $@" >&2
    exit 1
  }
}

@test "_parse_args: Parses simple flag (short)" {
  declare -A args
  _parse_args --opt-verbose ',short=v,long=verbose,flag,desc=Verbose output' --result args -- -v
  [ "${args[verbose]}" = "1" ]
}

@test "_parse_args: Parses simple flag (long)" {
  declare -A args
  _parse_args --opt-verbose ',short=v,long=verbose,flag,desc=Verbose output' --result args -- --verbose
  [ "${args[verbose]}" = "1" ]
}

@test "_parse_args: Parses argument with value (short)" {
  declare -A args
  _parse_args --opt-file ',short=f,long=file,desc=Input file' --result args -- -f "test.txt"
  [ "${args[file]}" = "test.txt" ]
}

@test "_parse_args: Parses argument with value (long)" {
  declare -A args
  _parse_args --opt-file ',short=f,long=file,desc=Input file' --result args -- --file "test.txt"
  [ "${args[file]}" = "test.txt" ]
}

@test "_parse_args: Handles required argument (present)" {
  declare -A args
  _parse_args --opt-name ',long=name,required,desc=Your name' --result args -- --name "John Doe"
  [ "${args[name]}" = "John Doe" ]
}

#@test "_parse_args: Handles required argument (missing) should fail" {
#  declare -A args
#  run _parse_args --opt-name ',long=name,required,desc=Your name' --result args --
#  [ "$status" -ne 0 ]
#  [[ "$output" =~ "ERROR! Required option '--name' is missing" ]]
#}

@test "_parse_args: Handles default value for optional argument" {
  declare -A args
  _parse_args --opt-level ',long=level,default=info,desc=Log level' --result args --
  [ "${args[level]}" = "info" ]
}

@test "_parse_args: Overrides default value with provided value" {
  declare -A args
  _parse_args --opt-level ',long=level,default=info,desc=Log level' --result args -- --level "debug"
  [ "${args[level]}" = "debug" ]
}

@test "_parse_args: Parses multiple arguments" {
  declare -A args
  _parse_args \
    --opt-file ',short=f,long=file,desc=Input file' \
    --opt-output ',short=o,long=output,desc=Output file' \
    --opt-verbose ',short=v,long=verbose,flag,desc=Verbose output' \
    --result args -- -f "input.txt" -o "output.txt" -v
  [ "${args[file]}" = "input.txt" ]
  [ "${args[output]}" = "output.txt" ]
  [ "${args[verbose]}" = "1" ]
}

@test "_parse_args: Handles remainder argument" {
  declare -A args
  _parse_args \
    --opt-command ',remainder,desc=Command to execute' \
    --result args -- "run" "arg1" "arg2"
  [ "${args[command]}" = "run arg1 arg2" ]
}

@test "_parse_args: Handles remainder argument with greedy flag" {
  declare -A args
  _parse_args \
    --opt-command ',remainder,greedy,desc=Command to execute' \
    --result args -- "run" "--flag" "arg2"
  [ "${args[command]}" = "run --flag arg2" ]
}

#@test "_parse_args: Handles multi-valued argument" {
#  declare -A args
#  _parse_args \
#    --opt-include ',long=include,multi,desc=Include path' \
#    --result args -- --include "path1" --include "path2"
#  [ "${args[include]}" = "path1 path2" ]
#}

#@test "_parse_args: Handles multi-valued argument with custom separator" {
#  declare -A args
#  _parse_args \
#    --opt-include '|long=include|multi|multi-sep=;|desc=Include path' \
#    --result args -- --include "path1" --include "path2"
#  [ "${args[include]}" = "path1;path2" ]
#}

@test "_parse_args: Handles allowed values (valid)" {
  declare -A args
  _parse_args \
    --opt-mode '|long=mode|allowed=dev,prod|desc=Mode' \
    --result args -- --mode "dev"
  [ "${args[mode]}" = "dev" ]
}

#@test "_parse_args: Handles allowed values (invalid) should fail" {
#  declare -A args
#  run _parse_args \
#    --opt-mode '|long=mode|allowed=dev,prod|desc=Mode' \
#    --result args -- --mode "test"
#  [ "$status" -ne 0 ]
#  [[ "$output" =~ "invalid value 'test' for 'mode'. Valid values are: dev,prod" ]]
#}

#@test "_parse_args: Handles validators (valid)" {
#  declare -A args
#  _parse_args \
#    --opt-version '|long=version|validators=+alphanumeric|desc=Version' \
#    --result args -- --version "1.2.3"
#  [ "${args[version]}" = "1.2.3" ]
#}

#@test "_parse_args: Handles validators (invalid) should fail" {
#  declare -A args
#  run _parse_args \
#    --opt-version ',long=version,validators=+numbers,desc=Version' \
#    --result args -- --version "abc"
#  [ "$status" -ne 0 ]
#  [[ "$output" =~ "Validation failed for 'version' with value 'abc'. Validator '+numbers' failed." ]]
#}

#@test "_parse_args: Handles unknown arguments with --unknown-args" {
#  declare -A args
#  _parse_args \
#    --unknown-args-key extra_args \
#    --result args -- --known "value" --unknown-flag --another-unknown "another_value"
#  [ "${args[known]}" = "value" ]
#  [ "${args[extra_args]}" = "--unknown-flag	--another-unknown	another_value" ]
#}

#@test "_parse_args: Handles unknown arguments with --unknown-args and no key" {
#  declare -A args
#  _parse_args \
#    --unknown-args-key \
#    --result args -- --known "value" --unknown-flag --another-unknown "another_value"
#  [ "${args[known]}" = "value" ]
#  [ "${args[unknown]}" = "--unknown-flag	--another-unknown	another_value" ]
#}

#@test "_parse_args: Handles help flag (-h) and exits" {
#  declare -A args
#  run _parse_args --opt-test ',long=test' --result args -- -h
#  [ "$status" -eq 1 ]
#  [[ "$output" =~ "USAGE" ]]
#}

#@test "_parse_args: Handles help flag (--help) and exits" {
#  declare -A args
#  run _parse_args --opt-test ',long=test' --result args -- --help
#  [ "$status" -eq 1 ]
#  [[ "$output" =~ "USAGE" ]]
#}

#@test "_parse_args: Handles help-on-error flag" {
#declare -A args
#  run _parse_args \
#    --opt-name ',long=name,required,desc=Your name' \
#    --help-on-error \
#    --result args --
#  [ "$status" -ne 0 ]
#  [[ "$output" =~ "ERROR! Required option '--name' is missing" ]]
#  [[ "$output" =~ "USAGE" ]]
#}

@test "_parse_args: Handles help-tip flag" {
  declare -A args
  run _parse_args \
    --opt-name ',long=name,desc=Your name' \
    --help-tip \
    --result args -- --name "test"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "tip: run with --help for options" ]]
}

@test "_parse_args: Handles custom help function" {
  declare -A args
  my_custom_help_func() {
    echo "This is my custom help message."
  }
  export -f my_custom_help_func # Export function for bats to see it
  run _parse_args \
    --help my_custom_help_func \
    --result args -- -h
  [ "$status" -eq 1 ]
  [[ "$output" =~ "This is my custom help message." ]]
}

@test "_parse_args: Handles custom help string" {
  declare -A args
  run _parse_args \
    --help "My custom help string." \
    --result args -- -h
  [ "$status" -eq 1 ]
  [[ "$output" =~ "My custom help string." ]]
}

#@test "_parse_args: Handles duplicate short option should fail" {
#  declare -A args
#  run _parse_args \
#    --opt-file1 ',short=f,long=file1' \
#    --opt-file2 ',short=f,long=file2' \
#    --result args -- -f "test.txt"
#  [ "$status" -ne 0 ]
#  [[ "$output" =~ "Duplicate short option '-f' for option keys 'file1' and 'file2'" ]]
#}

#@test "_parse_args: Handles duplicate long option should fail" {
#  declare -A args
#  run _parse_args \
#    --opt-file1 ',long=file,short=f1' \
#    --opt-file2 ',long=file,short=f2' \
#    --result args -- --file "test.txt"
#  [ "$status" -ne 0 ]
#  [[ "$output" =~ "Duplicate long option '--file' for option keys 'file1' and 'file2'" ]]
#}

@test "_parse_args: Handles duplicate remainder option should fail" {
  declare -A args
  run _parse_args \
    --opt-rem1 ',remainder' \
    --opt-rem2 ',remainder' \
    --result args -- "arg1"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "Duplicate remainder (option spec flag 'remainder') keys 'rem1' and 'rem2'" ]]
}

#@test "_parse_args: Handles unknown option spec key with ignore-spec-errors (unique)" {
#  declare -A args
#  _parse_args \
#    --ignore-spec-errors \
#    --opt-test_unknown_ignore ',unknown=value|long=test_unknown_ignore' \    
#    --result args -- --test_unknown_ignore "value"
#  [ "$status" -eq 0 ]
#  [ "${args[test_unknown_ignore]}" = "value" ]
#  [[ "$output" =~ "Unknown command args spec option 'unknown'" ]]
#}

@test "_parse_args: Handles unknown option spec key without ignore-spec-errors should fail (unique)" {
  declare -A args
  run _parse_args \
    --opt-test_unknown_fail ',unknown=value|long=test_unknown_fail' \
    --result args -- --test_unknown_fail "value"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "Unknown command args spec option 'unknown'" ]]
}

@test "_parse_args: Handles no value for non-flag option (unique)" {
  declare -A args
  _parse_args --opt-name_no_value ',long=name_no_value,desc=Your name' --result args -- --name_no_value
  [ "${args[name_no_value]}" = "" ]
}

@test "_parse_args: Handles multiple short flags (unique)" {
  declare -A args
  _parse_args \
    --opt-a_flag ',short=a,flag' \
    --opt-b_flag ',short=b,flag' \
    --result args -- -a -b
  [ "${args[a_flag]}" = "1" ]
  [ "${args[b_flag]}" = "1" ]
}

@test "_parse_args: Handles mixed short and long options (unique)" {
  declare -A args
  _parse_args \
    --opt-file_mixed ',short=f,long=file_mixed' \
    --opt-output_mixed ',short=o,long=output_mixed' \
    --result args -- -f "input.txt" --output_mixed "output.txt"
  [ "${args[file_mixed]}" = "input.txt" ]
  [ "${args[output_mixed]}" = "output.txt" ]
}

@test "_parse_args: Handles arguments with spaces in values (unique)" {
  declare -A args
  _parse_args --opt-message_space ',long=message_space,desc=A message' --result args -- --message_space "hello world"
  [ "${args[message_space]}" = "hello world" ]
}

@test "_parse_args: Handles arguments with special characters in values (unique)" {
  declare -A args
  _parse_args --opt-path_special ',long=path_special,desc=A path' --result args -- --path_special "/usr/local/bin/my-app"
  [ "${args[path_special]}" = "/usr/local/bin/my-app" ]
}

@test "_parse_args: Handles multiple remainder arguments (multi-valued remainder) (unique)" {
  declare -A args
  _parse_args \
    --opt-files_multi_rem ',remainder,multi,desc=List of files' \
    --result args -- "file1.txt" "file2.txt" "file3.txt"
  [ "${args[files_multi_rem]}" = "file1.txt file2.txt file3.txt" ]
}

@test "_parse_args: Handles remainder argument with options after (non-greedy) (unique)" {
  declare -A args
  _parse_args \
    --opt-rem_non_greedy ',remainder,desc=Remainder arg' \
    --opt-flag_non_greedy ',flag,desc=A flag' \
    --result args -- "value1" "value2" --flag_non_greedy
  [ "${args[rem_non_greedy]}" = "value1 value2" ]
  [ "${args[flag_non_greedy]}" = "1" ]
}

@test "_parse_args: Handles remainder argument with options after (greedy) (unique)" {
  declare -A args
  _parse_args \
    --opt-rem_greedy ',remainder,greedy,desc=Remainder arg' \
    --opt-flag_greedy ',flag,desc=A flag' \
    --result args -- "value1" "value2" --flag_greedy
  [ "${args[rem_greedy]}" = "value1 value2 --flag_greedy" ]
  [ -z "${args[flag_greedy]}" ] # flag should not be parsed as a separate option
}

@test "_parse_args: Handles empty input for optional argument (unique)" {
  declare -A args
  _parse_args --opt-name_empty ',long=name_empty,desc=Your name' --result args --
  [ -z "${args[name_empty]}" ]
}

#@test "_parse_args: Handles empty input for flag argument (unique)" {
#  declare -A args
#  _parse_args \
#    --opt-verbose_empty ',long=verbose_empty,flag,desc=Verbose output' \
#    --result args --
#  [ "${args[verbose_empty]}" = "0" ]
#}

#@test "_parse_args: Handles multiple short options with values (unique)" {
#  declare -A args
#  _parse_args \
#    --opt-a_val ',short=a,long=arg_a_val' \
#    --opt-b_val ',short=b,long=arg_b_val' \
#    --result args -- -a "val_a" -b "val_b"
#  [ "${args[arg_a_val]}" = "val_a" ]
#  [ "${args[arg_b_val]}" = "val_b" ]
#}

#@test "_parse_args: Handles mixed short flags and options with values (unique)" {
#  declare -A args
#  _parse_args \
#    --opt-a_mixed_flag ',short=a,flag' \
#    --opt-b_mixed_val ',short=b,long=arg_b_mixed_val' \
#    --opt-c_mixed_flag ',short=c,flag' \
#    --result args -- -a -b "val_b" -c
#  [ "${args[a_mixed_flag]}" = "1" ]
#  [ "${args[arg_b_mixed_val]}" = "val_b" ]
#  [ "${args[c_mixed_flag]}" = "1" ]
#}

@test "_parse_args: Handles option spec with custom separator for allowed values (unique)" {
  declare -A args
  _parse_args \
    --opt-color_sep ',long=color_sep,allowed=;red;green;blue|desc=Color' \
    --result args -- --color_sep "green"
  [ "${args[color_sep]}" = "green" ]
}

#@test "_parse_args: Handles option spec with custom separator for allowed values (invalid) (unique)" {
#  declare -A args
#  run _parse_args \
#    --opt-color_sep_invalid ',long=color_sep_invalid,allowed=;red;green;blue|desc=Color' \
#    --result args -- --color_sep_invalid "yellow"
#  [ "$status" -ne 0 ]
#  [[ "$output" =~ "invalid value 'yellow' for 'color_sep_invalid'. Valid values are: red;green;blue" ]]
#}

#@test "_parse_args: Handles option spec with custom separator for multi-sep (unique)" {
#  declare -A args
#  _parse_args \
#    --opt-items_multi_sep ',long=items_multi_sep,multi,multi-sep=,,desc=Items' \
#    --result args -- --items_multi_sep "item1" --items_multi_sep "item2"
#  [ "${args[items_multi_sep]}" = "item1,item2" ]
#}

@test "_parse_args: Handles option spec with default value and no user input (unique 2)" {
  declare -A args
  _parse_args \
    --opt-count_default_no_input_unique_2 ',long=count_default_no_input_unique_2,default=10,desc=Count' \
    --result args --
  [ "${args[count_default_no_input_unique_2]}" = "10" ]
}

@test "_parse_args: Overrides default value with provided value (unique 2)" {
  declare -A args
  _parse_args \
    --opt-count_default_with_input_unique_2 ',long=count_default_with_input_unique_2,default=10,desc=Count' \
    --result args -- --count_default_with_input_unique_2 5
  [ "${args[count_default_with_input_unique_2]}" = "5" ]
}

@test "_parse_args: Handles validators and valid input (unique 2)" {
  declare -A args
  _parse_args \
    --opt-id_valid_unique_3 ',long=id_valid_unique_3,validators=+alphanumeric,desc=ID' \
    --result args -- --id_valid_unique_3 "abc123XYZ"
  [ "${args[id_valid_unique_3]}" = "abc123XYZ" ]
}

#@test "_parse_args: Handles validators (invalid) should fail (unique 2)" {
#  declare -A args
#  run _parse_args \
#    --opt-id_invalid_unique_4 ',long=id_invalid_unique_4,validators=+numbers,desc=ID' \
#    --result args -- --id_invalid_unique_4 "abc"
#  [ "$status" -ne 0 ]
#  [[ "$output" =~ "Validation failed for 'id_invalid_unique_4' with value 'abc'. Validator '+numbers' failed." ]]
#}

#@test "_parse_args: Handles multiple validators and valid input (unique 2)" {
#  declare -A args
#  _parse_args \
#    --opt-code_valid_multi_unique_3 ',long=code_valid_multi_unique_3,validators=+alphanumeric,+nowhitespace|desc=Code' \
#    --result args -- --code_valid_multi_unique_3 "ABC123def"
#  [ "${args[code_valid_multi_unique_3]}" = "ABC123def" ]
#}

#@test "_parse_args: Handles multiple validators and invalid input (unique 2)" {
#  declare -A args
#  run _parse_args \
#    --opt-code_invalid_multi_unique_4 ',long=code_invalid_multi_unique_4,validators=+alphanumeric,+nowhitespace|desc=Code' \
#    --result args -- --code_invalid_multi_unique_4 "ABC 123"
#  [ "$status" -ne 0 ]
#  [[ "$output" =~ "Validation failed for 'code_invalid_multi_unique_4' with value 'ABC 123'. Validator '+nowhitespace' failed." ]]
#}

@test "_parse_args: Handles negative validator and valid input (unique 2)" {
  declare -A args
  _parse_args \
    --opt-name_neg_valid_unique_3 ',long=name_neg_valid_unique_3,validators=-noslash|desc=Name' \
    --result args -- --name_neg_valid_unique_3 "John Doe"
  [ "${args[name_neg_valid_unique_3]}" = "John Doe" ]
}

#@test "_parse_args: Handles negative validator and invalid input (unique 2)" {
#  declare -A args
#  run _parse_args \
#    --opt-name_neg_invalid_unique_4 ',long=name_neg_invalid_unique_4,validators=-noslash|desc=Name' \
#    --result args -- --name_neg_invalid_unique_4 "John/Doe"
#  [ "$status" -ne 0 ]
#  [[ "$output" =~ "Validation failed for 'name_neg_invalid_unique_4' with value 'John/Doe'. Validator '-noslash' failed." ]]
#}

@test "_parse_args: Handles regex validator and valid input (unique 2)" {
  declare -A args
  _parse_args \
    --opt-pattern_valid_unique_3 ',long=pattern_valid_unique_3,validators=+re:^[a-z]+$|desc=Pattern' \
    --result args -- --pattern_valid_unique_3 "abc"
  [ "${args[pattern_valid_unique_3]}" = "abc" ]
}

#@test "_parse_args: Handles regex validator and invalid input (unique 2)" {
#  declare -A args
#  run _parse_args \
#    --opt-pattern_invalid_unique_4 ',long=pattern_invalid_unique_4,validators=+re:^[a-z]+$|desc=Pattern' \
#    --result args -- --pattern_invalid_unique_4 "ABC"
#  [ "$status" -ne 0 ]
#  [[ "$output" =~ "Validation failed for 'pattern_invalid_unique_4' with value 'ABC'. Validator '+re:^[a-z]+$' failed." ]]
#}

#@test "_parse_args: Handles option spec with group (unique 2)" {
#  declare -A args
#  run _parse_args \
#    --opt-test_group_unique_3 ',long=test_group_unique_3,group=Test Options|desc=Test option' \
#    --result args -- -h
#  [ "$status" -eq 1 ]
#  [[ "$output" =~ "Test Options options" ]]
#  [[ "$output" =~ "--test_group_unique_3: <value>" ]]
#}

@test "_parse_args: Handles option spec with example (unique 2)" {
  declare -A args
  run _parse_args \
    --opt-test_example_unique_3 ',long=test_example_unique_3,example=--test "value"|desc=Test option' \
    --result args -- -h
  [ "$status" -eq 1 ]
  [[ "$output" =~ "E.g. --test \"value\"" ]]
}

#@test "_parse_args: Handles option spec with value name (unique 2)" {
#  declare -A args
#  run _parse_args \
#    --opt-test_value_name_unique_3 ',long=test_value_name_unique_3,value=my_value|desc=Test option' \
#    --result args -- -h
#  [ "$status" -eq 1 ]
#  [[ "$output" =~ "--test_value_name_unique_3: <my_value>" ]]
#}

@test "_parse_args: Handles option spec with no short or long name (defaults to key) and greedy (unique 4)" {
  declare -A args
  _parse_args \
    --opt-myremainder_greedy_unique_5 ',remainder,greedy,desc=My remainder' \
    --result args -- "arg1" "--flag"
  [ "${args[myremainder_greedy_unique_5]}" = "arg1 --flag" ]
}

#@test "_parse_args: Handles option spec with no short or long name (defaults to key) and ignore-spec-errors (unique 4)" {
#  declare -A args
#  _parse_args \
#    --ignore-spec-errors \
#    --opt-myoption_ignore_unique_4 ',unknown=value|desc=My option' \
#    --result args -- --myoption_ignore_unique_4 "value"
#  [ "$status" -eq 0 ]
#  [ "${args[myoption_ignore_unique_4]}" = "value" ]
#  [[ "$output" =~ "Unknown command args spec option 'unknown'" ]]
#}

@test "_parse_args: Handles option spec with no short or long name (defaults to key) and unknown-args (unique 4)" {
  declare -A args
  _parse_args \
    --unknown-args-key \
    --opt-myoption_unknown_args_unique_4 ',desc=My option' \
    --result args -- --myoption_unknown_args_unique_4 "value" --unknown_unique_4 "val"
  [ "${args[myoption_unknown_args_unique_4]}" = "value" ]
  [ "${args[unknown]}" = "--unknown_unique_4\tval" ]
}

#@test "_parse_args: Handles option spec with no short or long name (defaults to key) and help-on-error (unique 4)" {
#  declare -A args
#  run _parse_args \
#    --opt-myrequired_help_unique_4 ',required|desc=My required option' \
#    --help-on-error \
#    --result args --
#  [ "$status" -ne 0 ]
#  [[ "$output" =~ "ERROR! Required option '--myrequired_help_unique_4' is missing" ]]
#  [[ "$output" =~ "USAGE" ]]
#}

@test "_parse_args: Handles option spec with no short or long name (defaults to key) and help-tip (unique 4)" {
  declare -A args
  run _parse_args \
    --opt-myoption_help_tip_unique_4 ',desc=My option' \
    --help-tip \
    --result args -- --myoption_help_tip_unique_4 "value"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "tip: run with --help for options" ]]
}

@test "_parse_args: Handles option spec with no short or long name (defaults to key) and custom help function (unique 5)" {
  declare -A args
  my_custom_help_func_unique_5() {
    echo "This is another custom help message unique 5."
  }
  export -f my_custom_help_func_unique_5
  run _parse_args \
    --opt-myoption_help_func_unique_5 ',desc=My option' \
    --help my_custom_help_func_unique_5 \
    --result args -- -h
  [ "$status" -eq 1 ]
  [[ "$output" =~ "This is another custom help message unique 5." ]]
}

@test "_parse_args: Handles option spec with no short or long name (defaults to key) and custom help string (unique 5)" {
  declare -A args
  run _parse_args \
    --opt-myoption_help_string_unique_5 ',desc=My option' \
    --help "My custom help string unique 5." \
    --result args -- -h
  [ "$status" -eq 1 ]
  [[ "$output" =~ "My custom help string unique 5." ]]
}
