_false=1
_true=0
_ok=0

## trap Ctrl+c to kill the sub processes. Ensures any background processes are killed
# Set up signal traps to clean up child processes
#
# Behavior:
#   - Traps SIGINT, SIGTERM and EXIT
#   - Kills all child processes when triggered
#
# Usage:
#   _trap_sigs
#
_trap_sigs() {
  trap "trap - SIGTERM && kill -- -$$ &>/dev/null" SIGINT SIGTERM EXIT
}

# Log an error message and exit with status 1
#
# Args:
#   $1 - Error message
#
# Behavior:
#   - Logs error message
#   - Exits script with status 1
#
# Usage:
#   _fail "Critical error occurred"
#
_fail() {
  # this function is early in the file, as the top most functions need access to it
  _err "$*"
  _is_trace && _trace "$(_tm::log::stacktrace)" || true
  exit 1
}

# Log an error message and exit with status 1
#
# Args:
#   $@ - Error message
#
# Behavior:
#   - Logs error message
#   - Exits script with status 1
#
# Usage:
#   _die "Fatal error occurred"
#
_die() {
  _err "$@"
  _is_trace && _trace "$(_tm::log::stacktrace)"
  exit 1
}

# Prompt user for a yes or no (yY* or nN*), and keep prompting until they choose one or the other (or ctrl+c).
#
# The exist code determines whether it was successful
#
# Args:
#   $1 - Prompt text ( ' [yn]: ' will appended to it)
#   $2 - Default value (optional). Can be [yYtT1]* or [nN]* (e.g. y, yes, YES, Yes,Y, true, 1, t ... same goes for no)
#
# Usage:
#   if _confirm "Eat pie?" yn; then
#       echo "pies are great!"
#   fi
#   if _confirm "Eat pie?" yn "n"; then # with a  default value
#       echo "pies are great!"
#   fi
#
_confirm(){
    local prompt="${1}"
    local default_val="${2:-}"
    local yn=''
    case "${default_val}" in
      [yYtT]*|1)
        prompt+=" [Yn]"
        default_val='y'
      ;;
      [nNFf]*|0)
        prompt+=" [yN]"
        default_val='n'
      ;;
      *)
        prompt+=" [yn]"
        default_val=''
      ;;
    esac
    _read_yn "$prompt" yn "${default_val}"
    if [[ "${yn}" == 'y' ]]; then
      return $_true
    else
      return $_false
    fi
}
# Prompt user for a yes or no ([yYtT]*|1) or [nNfF]*|0, and keep prompting until they choose one or the other (or ctrl+c)
#
# It will set the value to either 'y' or 'n' (lowercase)
#
# Args:
#   $1 - Prompt text
#   $2 - Variable name to store result
#   $3 - Default value (optional)
#
# Usage:
#   _read_yn "Eat pie? [yn]: " yn
#   _read_yn "Eat pie? [yN]: " yn "n"
#
_read_yn(){
    local prompt="${1}"
    local -n yn_ref="${2}"
    local default_val="${3:-}"

    while true; do
      _read "$prompt: " yn_ref "$default_val"
      case "${yn_ref}" in
        [yYtT]*|1)
          yn_ref='y'
          break
          ;;
        [nNFf]*|0)
          yn_ref='n'
          break
          ;;
      esac
    done
}

# Prompt user for input with a default value, and keep prompting until a non empty value is provided (or ctrl+c)
#
# Args:
#   $1 - Prompt text
#   $2 - Variable name to store result
#   $3 - Default value (optional)
#
# Usage:
#   _read_not_empty "Food" choice
#   _read_not_empty "Food" choice "pie"

_read_not_empty(){
    local prompt="${1}"
    local -n value_not_empty_ref="${2}"
    local default_val="${3:-}"

    while [[ -z "${value_not_empty_ref:-}"  ]]; do
        _read "$prompt:" value_not_empty_ref "${default_val}"
    done
}
# Prompt user for input with a default value
#
# Args:
#   $1 - Prompt text
#   $2 - Variable name to store result
#   $3 - Default value (optional)
#
# Behavior:
#   - Forces tty input to avoid conflicts with nested reads
#   - Sets specified variable with user input
#
# Usage:
#   _read "Continue? [Y/n]" choice "Y"
#
_read() {
  #  
  # args:
  #    $1 = the text to show. E.g. 'Launch rocket?'
  #    $2 = the variable to assign. E.g. yn
  #    $3 (optional) = the default value. E.g. 'n'
  #
  # We force a tty so it down't affect other read calls when nested
  # 
  # Example:
  #    _read "Do something?: [Yn]" choice
  #    case $choice in
  #       [Yy]* | '')
  #         ...run some command
  #      ;;
  #      [Nn]*)
  #         ... run some other command
  #      ;;
  #    esac
  read -e -p "$1" -i "${3:-}" $2 </dev/tty
}

# a silent pushd that doesn't print the dir to stdout
# Silent pushd that suppresses directory output
#
# Args:
#   $@ - Directory path(s) to push
#
# Behavior:
#   - Changes directory without printing to stdout
#
# Usage:
#   _pushd /path/to/dir
#
_pushd() {
  pushd "$@" >/dev/null
}

# a silent popd that doesn't print the dir to stdout
# Silent popd that suppresses directory output
#
# Behavior:
#   - Returns to previous directory without printing to stdout
#
# Usage:
#   _popd
#
_popd() {
  popd >/dev/null
}

# a grep which doesn't return a non-zero exit status on match failure
# Safe grep that always returns success
#
# Args:
#   $@ - Standard grep arguments
#
# Behavior:
#   - Runs grep but returns 0 even if no matches found
#
# Usage:
#   _grep pattern file.txt
#
_grep() {
    grep "$@" || true
}

# Enhanced touch that creates parent directories
#
# Args:
#   $1 - File path to create
#
# Behavior:
#   - Creates parent directories if needed
#   - Creates empty file
#
# Usage:
#   _touch /path/to/new/file.txt
#
_touch() {
  # a better touch, also creates any parent dirs
  mkdir -p "$(dirname "$1")" && touch "$1"
}

_realpath() {
  # TODO: Cache the realpath check result?
  if command -v realpath &> /dev/null; then
    # Attempt to resolve the path, suppress stderr, and check exit code
    local resolved_path
    resolved_path=$(realpath "$@" 2>/dev/null)
    if [[ $? -eq 0 && -n "$resolved_path" ]]; then
      echo "$resolved_path"
    else
      # realpath failed or returned empty (e.g. path doesn't exist), return original path
      echo "$1" # Return the first argument (original path)
    fi
  else
    # _warn "realpath command not found, using fallback implementation"
    local path="$1"

    # On macOS, use python as fallback
    if [[ "$OSTYPE" == "darwin"* ]]; then
      _warn "For better performance on macOS, install realpath using: brew install coreutils"
      _python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$path"
    # On Linux/Unix, try readlink -f
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
      readlink -f "$path"
    # On Windows (Git Bash/Cygwin), use cygpath if available
    elif [[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys" ]]; then
      if command -v cygpath &> /dev/null; then
        cygpath -w "$path"
      else
        _err "realpath not available. Please install it:"
        _err "  Linux: sudo apt-get install coreutils"
        _err "  macOS: brew install coreutils"
        _err "  Windows: Install Git for Windows or Cygwin"
        return 1
      fi
    else
      _err "Unsupported OS for realpath fallback"
      return 1
    fi
  fi
}

# Executes a python script, preferring python3 if available, otherwise python.
# Fails if neither is found.
# Args: $@ - Arguments to pass to the python interpreter.
_python(){
  if command -v python3 &> /dev/null; then
    python3 "$@"
  elif command -v python &> /dev/null; then
    python "$@"
  else
    _fail "python3/python is not installed"
  fi
}

# Executes a python script using python3.
# Fails if python3 is not found.
# Args: $@ - Arguments to pass to the python3 interpreter.
_python3(){
  if command -v python3 &> /dev/null; then
    python3 "$@"
  else
    _fail "python3 is not installed"
  fi
}

#
# Fails with an error message if the given command is not found
# 
# $1 - (required) the command to test for
# $2 - (optional) a help message appended to the end of the error message
#
_fail_if_not_installed(){
  local cmd="${1}"
  if [[ -n "$cmd" ]]; then
    if command -v $1 &> /dev/null; then
      return
    fi
  fi

  local help=""
  if [[ -n "${2:-}" ]]; then
    help=" $2."
  fi
  if _is_debug; then
    help+=" Looked in paths:$(echo $PATH)"
  fi
  _fail "Command '$1' not found.$help"      

}

_print_array(){
  _tm::util::array::print "$1"
}

# print normal or associative array
_tm::util::array::print(){
  local -n array_ref="$1"
  if [[ -z "${array_ref:-}" ]]; then
    return
  fi

  >&2 echo -n "${array_ref:-}( "
  for key in "${!array_ref[@]}"; do
    >&2 echo -n "['$key']='${array_ref["$key"]:-}' "
  done
  >&2 echo ")"
}

#
# Get the first value from the array with one of the provided keys
# Arguments:
# $1 - the associative array by reference
# $2... the keys to try. 
#
# If no key found, throws an exception
#
_tm::util::array::get_first(){
  local -n array_ref="$1"
  shift
  if [[ -z "${array_ref:-}" ]]; then
    return
  fi

  for key in "$@"; do
    if [[ -n "${array_ref["$key"]:-}" ]]; then
      echo "${array_ref["$key"]}"
      return
    fi
  done
   _fail "Could not find any values with keys matching one of ($@)"
}

# Safe remove function that checks if a directory is not root and not empty
#
# Args:
#   $1 - Path to remove
#   $@ - Additional arguments to pass to rm command
#
# Behavior:
#   - Checks if path is not root directory
#   - Checks if path is not empty (for directories)
#   - Removes the path if checks pass
#
# Usage:
#   _rm /path/to/remove
#   _rm -f /path/to/file
#   _rm -rf /path/to/directory
#
_rm() {
  local path=""
  local args=()

  # Parse arguments to separate path from rm options
  for arg in "$@"; do
    if [[ "$arg" == -* ]]; then
      # This is an option flag
      args+=("$arg")
    else
      # This is the path
      path="$arg"
    fi
  done

  # If no path was found, return error
  if [[ -z "$path" ]]; then
    _err "No path specified for removal"
    return 1
  fi

  # Check if path is root directory
  if [[ "$path" == "/" || "$path" == "~" || "$path" == "$HOME" || -z "$path" ]]; then
    _err "Cannot remove root or home directory: $path"
    return 1
  fi

  # For directories, check if empty (only when using recursive removal)
  if [[ -d "$path" && " ${args[*]} " == *" -r"* || " ${args[*]} " == *" -R"* ]]; then
    # Check if directory exists and is not empty
    if [[ -d "$path" && "$(ls -A "$path" 2>/dev/null)" ]]; then
      _debug "Removing non-empty directory: $path"
    else
      _debug "Directory is empty or doesn't exist: $path"
    fi
  fi

  # Execute the rm command with all arguments
  rm "${args[@]}" "$path"
  return $?
}
