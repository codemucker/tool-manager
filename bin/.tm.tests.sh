#!/usr/bin/env env-tm-bash

_tm::source::include_once .tm.script.sh .tm.plugin.sh .tm.plugins.sh

#
# Find tests for a given plugin or for the tool-manager itself.
#
# Args:
# $1 - the associative array to put in the results
#    will contain the following keys. The values are newline separated
#     all_bats_files    - all the bats files
#     all_bash_files    - all bash executable files
#     test_bats_targets - test only files and directories which can be passed to bats
#     test_bash_files   - test only bash files
#     what              - what 'what' was identified as (aka what was it identified as?)
# $2 - where to find the tests. Can be blank (tool-manager), a plugin home dir, or a test file/dir
#
# Usage: _tm::tests::find_test_targets results_array [plugin_name|tool-manager]
#
_tm::tests::find() {
  local -n results_ref="$1"
  shift

  declare -A args
  _parse_args \
    --file "${BASH_SOURCE[0]}" \
    --opt-what "|remainder|short=w|desc=The plugin, 'tool-manager', dir to test. If empty, test the tool-manager. Can pass a path to the tests dir" \
    --opt-test "|short=t|desc=The name of the test to match on. Will have '*' pre/post appended, as in foo->'*foo*'" \
    --result args \
    -- "$@"

  results_ref=()
  results_ref[bats_targets]=''
  results_ref[bash_files]=''

  # all the files from the root dir, not just the test ones
  results_ref[all_bats_files]=''
  results_ref[all_bash_files]=''

  local what="${args[what]}"
  local target_name=""
  local -a test_targets=()
  local -a all_targets=()

  # collect targets
  if [[ -z $what ]] || [[ $what == "tool-manager" ]]; then
    target_name="tool-manager"
    _tm::tests::__add_test_dirs_in test_targets "$TM_HOME"
    all_targets+=("$TM_HOME/bin" "$TM_HOME/bin-defaults" "$TM_HOME/bin-internal" "$TM_HOME/lib-shared/tm/bash" "$TM_HOME/test" "$TM_HOME/tests")
  elif [[ $what == "."* ]] || [[ $what == "/"* ]]; then
    test_targets+=("$what")
  elif [[ -f $what ]]; then
    test_targets+=("$what")
    target_name="file '${what}'"
  elif [[ -d $what ]]; then
    target_name="dir '$what'"
    test_targets+=("$what")
    all_targets+=("$what")
  else
    local qname
    qname="$(_tm::plugins::installed::get_by_name "$what")"
    if [[ -z $qname ]]; then
      _fail "Plugin '$what' not found."
    fi
    local -A plugin
    _tm::parse::plugin plugin "$qname"

    target_name="${qname}"
    _tm::tests::__add_test_dirs_in test_targets "${plugin[install_dir]}"
    all_targets+=("${plugin_home}/bin" "${plugin_home}/bin-internal" "${plugin_home}/lib-shared/bash" "${plugin_home}/test" "$TM_HOME/tests")
  fi

  _debug "Finding tests for '$target_name'"

  # for the tests
  local -a test_files_sh=()
  local -a bats_targets=()
  for target in "${test_targets[@]}"; do
    if [[ -d ${target} ]]; then
      # Append found shell script files to test_files_sh
      mapfile -t -O "${#test_files_sh[@]}" test_files_sh < <(find "$target" -type f -name "*.sh")
      bats_targets+=("$target")
    elif [[ -f $target ]] && [[ $target == *'.sh' ]]; then
      test_files_sh+=("$target")
    elif [[ -f $target ]] && [[ $target == *'.bats' ]]; then
      bats_targets+=("$target")
    fi
  done
  # Ensure the test_files_sh is a unique list of values
  mapfile -t test_files_sh < <(printf "%s\n" "${test_files_sh[@]}" | sort -u)

  # all the files
  local -a all_files_sh=()
  local -a all_bats_files=()
  for target in "${all_targets[@]}"; do
    if [[ -d ${target} ]]; then
      local file
      # all scripts
      while IFS= read -r -d $'\0' file; do
        # Only check the first line for a shebang. `grep -I` on the output of `head`
        # helps to ignore binary files. This avoids false positives on eg markdown files.
        if head -n 1 "$file" 2>/dev/null | grep -qIE '^#!.*(bash|env-tm-bash)'; then
          all_files_sh+=("$file")
        fi
      done < <(find "${target}" -type f -name '*' -print0)
      # hidden shell files
      while IFS= read -r -d $'\0' file; do
        all_files_sh+=("$file")
      done < <(find "${target}" -type f -name ".*.sh" -print0)
      # bats files
      while IFS= read -r -d $'\0' file; do
        all_bats_files+=("$file")
      done < <(find "${target}" -type f -name "*.bats" -print0)
    elif [[ -f ${target} ]]; then
      if [[ $target == *".bats" ]]; then
        all_bats_files+=("${target}")
      else
        all_files_sh+=("${target}")
      fi
    fi
  done

  local old_ifs="$IFS"
  IFS=$'\n'
  results_ref[test_bash_files]="${test_files_sh[*]}"
  results_ref[test_bats_targets]="${bats_targets[*]}"
  results_ref[all_bash_files]="${all_files_sh[*]}"
  results_ref[all_bats_files]="${all_bats_files[*]}"
  results_ref[what]="${target_name}"
  IFS="$old_ifs"

}

_tm::tests::__add_test_dirs_in() {
  local -n test_dirs_ref="$1"
  local root_dir="$2"
  local -a found_dirs=()

  # Find directories named "test" or "tests" within root_dir, including subdirectories
  for sub_dir in "test" "tests"; do
    if [[ -d "$root_dir/$sub_dir" ]]; then
      mapfile -t found_dirs < <(find "$root_dir/$sub_dir" -type d 2>/dev/null)
      for dir in "${found_dirs[@]}"; do
        test_dirs_ref+=("$dir")
      done
    fi
  done

}
