#!/usr/bin/env env-tm-bash

_tm::source::include_once .tm.script.sh .tm.plugin.sh .tm.plugins.sh

#
# Find tests for a given plugin or for the tool-manager itself.
#
# Args:
# $1 - the associative array to put in the results
# $2 - where to find the tests. Can be blnak (tool-manager), a plugin home dir, or a test file/dir
#
# Usage: _tm::tests::find_test_targets results_array [plugin_name|tool-manager]
#
_tm::tests::find_test_targets() {
  local -n results_ref="$1"
  results_ref[bats_targets]=''
  results_ref[bash_files]=''
  results_ref[spec_targets]=''

  declare -A args
  _parse_args \
    --file "${BASH_SOURCE[0]}" \
    --opt-plugin "|remainder|short=p|desc=The plugin, 'tool-manager', dir to test. If empty, test the tool-manager. Can pass a path to the tests dir" \
    --opt-test "|short=t|desc=The name of the test to match on. Will have '*' pre/post appended, as in foo->'*foo*'" \
    --opt-fix "|short=f|default=1|allowed=0,1,true,false|default=1|validator=boolean|desc=Auto fix and script issues that can be fixed such as execute perms etc" \
    --result args \
    -- "$@"

  local what="${args[plugin]}"
  local auto_fix="$(_tm::parse::boolean "${args[fix]}")"
  local target_name=""
  local -a targets=()

  _tm::invoke::ensure_installed bats

  if [[ -z $what ]] || [[ $what == "tool-manager" ]]; then
    target_name="tool-manager"
    __add_test_dirs_in targets "$TM_HOME"
  elif [[ $what == "."* ]] || [[ $what == "/"* ]]; then
    targets+=("$what")
    target_name=""
  elif [[ -f $what ]]; then
    targets+=("$what")
    target_name="file '${what}'"
  else
    local qname
    qname="$(_tm::plugins::installed::get_by_name "$what")"
    if [[ -z $qname ]]; then
      _fail "Plugin '$what' not found."
    fi
    local -A plugin
    _tm::parse::plugin plugin "$qname"

    target_name="${qname}"
    __add_test_dirs_in targets "${plugin[install_dir]}"

    coverage_root_dir="${plugin[install_dir]}/bin"
  fi

  if [[ -n $target_name ]]; then
    _info "Finding tests for '$target_name'"
  else
    _debug "Finding tests using  '${targets[*]}'"
  fi

  local -a test_files_sh=()
  local -a bats_targets=()
  for target in "${targets[@]}"; do
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

  local old_ifs="$IFS"
  IFS=$'\n'
  results_ref['bash_files']="${test_files_sh[*]}"
  results_ref['bats_targets']="${bats_targets[*]}"
  IFS="$old_ifs"
}

__add_test_dirs_in() {
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

main "$@"
