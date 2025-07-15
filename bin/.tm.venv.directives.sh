source "$TM_LIB_BASH/lib.log.sh"

#
# Parse a text file for directives
#
# Arguments
# $1 - path to file to parse
# $2 - (optional) the file to output the directives to. If not given, print to stdout
#
_tm::venv::extract_directives() {
  local file="${1:-}"
  local directives_file="${2:-}"

  if [[ -z ${file} ]]; then
    _fail "pass a file to parse for directives. <file> <optional_directives_output>"
  fi

  if [[ -n $directives_file ]]; then
    # remove the existing directives file
    if [[ -f $directives_file ]]; then
      rm "$directives_file" || true
    else
      mkdir -p "$(dirname "$directives_file")"
    fi
    __append() {
      echo "$*" >>"$directives_file"
    }
  else
    # echo to stdout
    __append() {
      echo "$*"
    }
  fi

  local -a directives
  if _tm::venv::__parse_directives "$file" directives; then
    local venv_provider_included=1
    local venv_provider='venv:provider=python'
    for directive in "${directives[@]}"; do
      if [[ $directive == "venv:provider="* ]]; then
        venv_provider_included=1
      fi
      if [[ -z $venv_provider ]] && [[ $directive == "hashbang="* ]]; then
        if [[ $directive == "hashbang=bash" ]] \
          || [[ $directive == "hashbang=env-tm-bash" ]] \
          || [[ $directive == "hashbang=python" ]] \
          || [[ $directive == "hashbang=env-tm-python" ]]; then
          venv_provider='venv:provider=python'
        elif [[ $directive == "hashbang=java" ]] \
          || [[ $directive == "hashbang=env-tm-java" ]]; then
          venv_provider='venv:provider=java'
        elif [[ $directive == "hashbang=kotlin" ]] \
          || [[ $directive == "hashbang=env-tm-kotlin" ]]; then
          venv_provider='venv:provider=kotlin'
        elif [[ $directive == "hashbang=node" ]] \
          || [[ $directive == "hashbang=env-tm-node" ]]; then
          venv_provider='venv:provider=node'
        fi
      fi
      __append "$directive"
    done

    if [[ $venv_provider_included != '1' ]]; then
      __append "$venv_provider"
    fi

    if [[ -n $directives_file ]]; then
      _debug "Wrote directives file '$directives_file'"
    fi
  fi
}

# Description: Extracts all '@require' directives from comments at the beginning of a file.
#              Parsing stops at the first non-comment, non-whitespace line (ignoring shebang).
#              It supports '//' and '#' as comment prefixes.
#              It will skip non text files
# Arguments:
#   $1: The path to the file to parse. This must exist
#   $2: The name of the bash array to populate with the extracted directives.
#       The array will be cleared before new directives are added.
# Returns:
#   0: Success (directives were parsed, array populated, only if not empty)
#   1: Failure (e.g., file not found, not a text file, no directives)
# Notes:
#   - This function requires Bash 4.3+ for `declare -n` (nameref).
#   - It reads line by line until a code line is encountered, a non-text file is detected, or EOF.
_tm::venv::__parse_directives() {
  local file="$1"
  local -n target_array="$2" # Use nameref to modify the array passed by name

  # Clear the target array before populating it
  target_array=()

  # actually seems to make it take little longer!
  #  # quick short circuit out of here if no requires
  #  if ! _tm::venv::__has_directives "$file"; then
  #      return 1
  #  fi

  # Basic check to see if it's a text file type (optional but good practice)
  if ! file --mime-type "$file" | grep -q 'text/'; then
    _debug "'$file' is not identified as a text file. Skipping directive parsing."
    return 1
  fi

  # Regular expression for comment lines containing '@require'
  # It captures the content after '@require' into BASH_REMATCH[2]
  #local regex_comment_require="^[[:space:]]*(\/\/|#)[[:space:]]*@require:([^#\/[:space:]]*)[[:space:]]*"
  local regex_comment_require="^[[:space:]]*(\/\/|#)[[:space:]]*@require:([^[:space:]]*)[[:space:]]+([^#\/[:space:]]+).*"
  local regex_comment="^[[:space:]]*(\/\/|#).*$"

  local hashbang_runner_extracted=0
  # Read the file line by line
  while IFS= read -r line || [[ -n $line ]]; do

    # Handle shebang first, but only if not already processed and it's a shebang line
    if [[ $hashbang_runner_extracted -eq 0 && $line =~ ^#\! ]]; then
      local hashbang_content="${line#\#\!}" # Remove '#!' prefix
      local runner_path=""
      local runner=""

      # Regex to extract the runner path from the hashbang content.
      # It specifically looks for the executable path, stopping at the first whitespace.
      # Group 1: captures the path after '/usr/bin/env ' (if present)
      # Group 2: captures the path directly after '#!' (if no 'env')
      if [[ $hashbang_content =~ ^[[:space:]]*/usr/bin/env[[:space:]]+([^[:space:]]+).*$ ]]; then
        runner_path="${BASH_REMATCH[1]}"
      elif [[ $hashbang_content =~ ^[[:space:]]*([^[:space:]]+).*$ ]]; then
        runner_path="${BASH_REMATCH[1]}"
      fi

      if [[ -n $runner_path ]]; then
        runner="${runner_path##*/}" # Get basename (e.g., 'bash' from '/bin/bash', 'python3' from '/usr/bin/python3')
        target_array+=("hashbang=$runner")
      fi
      hashbang_runner_extracted=1 # Mark shebang as processed
      continue                    # Move to the next line
    fi

    # Skip empty or whitespace-only lines
    if [[ $line =~ ^[[:space:]]*$ ]]; then
      continue
    fi

    # Check if it's a comment line containing '@require'
    if [[ $line =~ $regex_comment_require ]]; then
      local directive_key="${BASH_REMATCH[2]}"
      local directive_value="${BASH_REMATCH[3]}"
      if [[ -n ${directive_key} ]]; then
        local directive="${directive_key}=${directive_value}"
        target_array+=("${directive}") # Add the cleaned directive content
        _is_trace && _trace "directive='${directive}'"
      fi
    elif [[ ! $line =~ $regex_comment ]]; then
      # If the line is not empty, not a shebang, and not a recognized comment with @require,
      # then it's considered a "code" line or end of header. Stop parsing.
      break
    fi
  done <"$file"

  if [[ ${#target_array[@]} -gt 1 ]]; then # runner path is always added
    return 0                               # found, so success
  else
    return 1 # none found
  fi
}

# Description: Checks if a given file (assumed to be a text script)
#              contains the string '@require' in its first 100 lines.
# Arguments:
#   $1: The path to the file to check.
# Returns:
#   0: Success (file contains '@require')
#   1: Failure (file does not contain '@require' or is not a text file)
_tm::venv::__has_directives() {
  local file="$1"

  # Check if the file exists and is a regular file
  if [[ ! -f $file ]]; then
    >&2 echo "Error: File not found or is not a regular file: $file"
    return 1
  fi

  # Basic check to see if it's a text file type (optional but good practice)
  # This uses 'file --mime-type' to determine if it's a text-based file.
  if ! file --mime-type "$file" | grep -q 'text/'; then
    _trace "'$file' is not identified as a text file. Skipping."
    return 1
  fi

  # Check the first x lines for '@require'
  # `grep -q '@require'` searches quietly (no output) and sets exit status.
  if head -n 50 "$file" | grep -q '@require:'; then
    _finest "found directives in $file"
    return 0 # Success: '@require' found
  else
    return 1 # Failure: '@require' not found
  fi
}
