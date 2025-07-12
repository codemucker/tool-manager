#
# Library to provide path related utilities
#

if command -v _tm::path::add_to_path &>/dev/null; then
  return
fi

#
# Add the passed in path to the PATH if it's not already added
#
# $@.. - [PATH]s to add
#
_tm::path::add_to_path() {  
  if [[ -z "${1:-}" ]]; then
    # no paths to add, skip all
    return
  fi
  _debug "adding paths $*"
  # TODO: handle different separator in different OS's?
  IFS=':' read -ra current_paths <<< "$PATH"
  local path_exists
  for new_path in "$@"; do
    path_exists=false
    local path
    for path in "${current_paths[@]}"; do
      if [[ "$path" == "$new_path" ]]; then
        path_exists=true
        break
      fi
    done
    if [[ "$path_exists" == false ]]; then
      PATH="$new_path:$PATH"
    fi
  done
  export PATH
}


_tree(){
    _tm::path::tree "$@"
}

# _tm::path::tree (dir_to_scan, callback_func_name)
# Implements a bash-only 'tree' command.
# dir_to_scan: The directory to scan. Defaults to '.'.
# callback_func_name: Optional. Name of a function to call for each found file.
_tm::path::tree(){
    local dir_to_scan="${1:-.}"
    local callback_func="${2:-}"

    # use the os one if possible
    if [[ -z "${callback_func}" ]] && command -v tree ; then
        tree "${dir_to_scan}"
        return
    fi
    # Check for color support
    local -g _TM_TREE_HAS_COLORS=false
    local _TM_TREE_DIR_COLOR=""
    local _TM_TREE_FILE_COLOR=""
    local _TM_TREE_NO_COLOR="\e[0m"

    if tput setaf 1 >/dev/null 2>&1; then # check if terminal supports colours
        _TM_TREE_HAS_COLORS=true
        _TM_TREE_DIR_COLOR="\e[1;34m" # Bold Blue
        _TM_TREE_FILE_COLOR="\e[0m"   # Default (no special color for files, just reset)
    fi

    if [[ ! -d "$dir_to_scan" ]]; then
        _error "Directory not found: $dir_to_scan"
        return 1
    fi

    # This recursive helper function builds the tree display.
    # Arguments: current_path, current_prefix, callback_function_name
    _tm::path::__tree_recursive() {
        local current_path="$1"
        local current_prefix="$2"
        local cb_func="$3"
        local entries=()

        # Get all entries (files and directories) in the current_path, excluding '.' and '..'.
        while IFS= read -r -d $'\0' entry; do
            entries+=( "$entry" )
        done < <(find "$current_path" -maxdepth 1 -mindepth 1 -print0 | sort -z)

        local num_entries=${#entries[@]}
        local i=0

        for full_path in "${entries[@]}"; do
            i=$((i + 1))
            local base_name="$(basename "$full_path")"
            local branch_prefix
            local child_prefix
            local display_name="${base_name}"

            if [[ "$i" -eq "$num_entries" ]]; then
                branch_prefix="└── "
                child_prefix="${current_prefix}    "
            else
                branch_prefix="├── "
                child_prefix="${current_prefix}│   "
            fi

            if [[ -d "$full_path" ]]; then
                if $_TM_TREE_HAS_COLORS; then
                    display_name="${_TM_TREE_DIR_COLOR}${base_name}${_TM_TREE_NO_COLOR}"
                fi
                echo -e "${current_prefix}${branch_prefix}${display_name}"
                _tm::path::__tree_recursive "$full_path" "$child_prefix" "$cb_func"
            elif [[ -f "$full_path" ]]; then
                if $_TM_TREE_HAS_COLORS; then
                    display_name="${_TM_TREE_FILE_COLOR}${base_name}${_TM_TREE_NO_COLOR}"
                fi
                echo -e "${current_prefix}${branch_prefix}${display_name}"
                if [[ -n "$cb_func" ]]; then
                    # Call the callback function with the full path of the file and the prefix
                    "$cb_func" "$full_path" "${child_prefix}"
                fi
            fi
        done
    }

    # Print the root directory itself with color if it's a directory
    if [[ -d "$dir_to_scan" ]]; then
        if $_TM_TREE_HAS_COLORS; then
            echo -e "${_TM_TREE_DIR_COLOR}${dir_to_scan}${_TM_TREE_NO_COLOR}"
        else
            echo "$dir_to_scan"
        fi
    else
        echo "$dir_to_scan" # Should not happen based on earlier check
    fi

    # Start the recursive traversal.
    _tm::path::__tree_recursive "$dir_to_scan" "" "$callback_func"
}