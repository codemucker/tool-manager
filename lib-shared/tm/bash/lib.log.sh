#
# Library to provide logging (and stacktrace) related functionality
#

if command -v _tm::log::set_opts &>/dev/null; then
  return
fi

#
# helper scripts and bashrc scripts should source this for all the common setup and config
#
# Can be sourced multiple times, but will only execute its definitions once per session due to a sourcing guard.
#

__tm_log_starttime=${__tm_log_starttime:-$(date +%s%N)}

# ANSI Color Codes for logging
COLOR_BLACK='\033[0;30m'
COLOR_BLACK_BOLD='\033[1;30m'
COLOR_BLUE='\033[0;34m'
COLOR_GREEN='\033[0;32m'
COLOR_GREEN_BOLD='\033[1;32m'
COLOR_GREY='\033[0;37m'
COLOR_GREY_BOLD='\033[1;37m'
COLOR_ORANGE='\033[0;33m'
COLOR_ORANGE_BOLD='\033[1;33m'
COLOR_RED='\033[0;31m'
COLOR_RED_BOLD='\033[1;31m'
COLOR_YELLOW='\033[0;33m'
COLOR_NONE='\033[0m' # No Color
BOLD=$(tput bold 2>/dev/null || echo '')

TM_LOG_NAME="${TM_LOG_NAME:-$(basename ${BASH_SOURCE[${#BASH_SOURCE[@]}-1]})}"
if ([[ "$TM_LOG_NAME" == ".bashrc" ]] || [[ "$TM_LOG_NAME" == "bash" ]]); then
  TM_LOG_NAME="tool-manager"
fi

TM_LOG_CONSOLE="${TM_LOG_CONSOLE:-1}" # whether to log to console
TM_LOG_SYSLOG="${TM_LOG_SYSLOG:-1}" # whether to log to the system logger
TM_LOG_FILE="${TM_LOG_FILE:-}" # path to the file to log. Only log to file if set
TM_LOG_FILE_MAX_BYTES="${TM_LOG_FILE_MAX_BYTES:-10000000}" # 10mb
TM_LOG_FILE_ROTATE="${TM_LOG_FILE_ROTATE:-1}"
TM_LOG="${TM_LOG:-info}" # all the various logging options

__tm_log="${__tm_log:-unset}" # to detect log name changes
__tm_log_names=()
__tm_log_filters=()
__tm_log_next_file_rotate_check=0

_tm::log::init(){
  if [[ "$TM_LOG" != "$__tm_log" ]]; then
    __tm_log="$TM_LOG"
    _tm::log::set_opts "$TM_LOG"
  fi
}

#
# Set the various logging options.
# $1: csv string of options. Can contain any of the log levels, caller, timings. Case and space insensitive
#
_tm::log::set_opts(){
  local log_opts="$1"
  #>&2 echo "tm::log::set_opts log_opts=$log_opts"
  local opts
  local level

  local LEV_FINEST=0 LEV_TRACE=1 LEV_DEBUG=2 LEV_INFO=3 LEV_WARN=4 LEV_ERR=5
  local log_pid=0
  local log_duration=0
  local log_call_file=0 log_call_func=0
  local log_timestamp=0 log_datestamp=0 log_epoch=0
  local log_user=0
  local log_stack=0
  local -a loggers=()
  local help=0

  _tm::log::__stack(){
    :
  }

  IFS=',' read -ra opts <<< "$log_opts"
  for opt in "${opts[@]}"; do
    case "$opt" in
      w|warn|WARN)
        level=$LEV_WARN
        ;;
      i|info|INFO)
        level=$LEV_INFO
        ;;
      d|debug|DEBUG)
        level=$LEV_DEBUG
        ;;
      t|trace|TRACE)
        level=$LEV_TRACE
        ;;
      f|finest|FINEST)
        level=$LEV_FINEST
        ;;
      proc|pid)
        log_pid=true
        ;;
      du|duration)
        log_duration=true
        ;;
      ts|timestamp)
        log_timestamp=true
        ;;
      ds|datestamp)
        log_datestamp=true
        ;;
      epoch)
        log_epoch=true
        ;;
      cfunc|caller-func)
        log_call_func=true
        ;;
      cfile|caller-file)
        log_call_file=true
        ;;      
      call|caller)
        log_call_file=true
        log_call_func=true
        ;;  
      user)
        log_user=true
        ;;
      stack|stacktrace)
        _tm::log::__stack(){ _tm::log::stacktrace '...' ; }
        ;;
      '-console')
        LOG_CONSOLE=0
        ;;
      +console|console)
        LOG_CONSOLE=1
        ;;
      '-syslog')
        TM_LOG_SYSLOG=0
        ;;
      +syslog|syslog)
        TM_LOG_SYSLOG=1
        ;;
      '-rotate')
        TM_LOG_FILE_ROTATE=0
        ;;
      +rotate|rotate)
        TM_LOG_FILE_ROTATE=1
        ;;
      -file)
        LOG_FILE=''
        ;;
      +file|file)
        if [[ -z "${LOG_FILE:-}" ]]; then
          LOG_FILE="$(pwd)/tm.log"          
          >&2 echo "Logging to file '$LOG_FILE'"
        fi
        ;;
      help)
        help=1
        ;;  
      all)
        log_call_file=true
        log_call_func=true
        log_datestamp=true
        log_pid=true
        log_duration=true
        log_user=true
        ;;
      @*)
        logger="${opt:1}"
        __tm_log_filters+=("${logger}")
        ;;
      *)
        >&2 echo "WARN [_tm::log::opt_level] unknown log option '$opt', ignoring. Options are comma separated. Include 'help' in the TM_LOG for all options. [finest,trace,debug,info,warn,help,all,caller,cfile,cfunc,datestamp,epoch,pid,timestamp,duration,user,stack]'"
        ;;
    esac
  done

  if [[ $help == 1 ]]; then
    >&2 cat << EOF
_tm::log::set_opts \$TM_LOG (provided: $TM_LOG)

Log options are comma separated options. E.g. 'trace,all,stack,@foo*,@*bar*'

LEVEL OPTIONS:
 - finest|f
 - trace|t
 - debug|d
 - info|i   (default)
 - warn|w

INCLUDE OPTIONS:  (by default, all are off)
  - all          : shortcut for 'datestamp,pid,caller,user,duration'
  - cfile        : include the caller file
  - cfunc        : include the caller function
  - caller|call  : shortcut for 'cfile,cfunc'
  - proc|pid     : include the process id
  - duration|du  : include the length of time since the logger was started
  - user         : include the current user

TIME STAMPS:
  - datestamp|ds : include the datestamp (implies timestamp)
  - epoch        : include the epoch
  - timestamp|ts : include the timestamp 

FILTERING OPTIONS:
  - @<logger-name> : the logger name to filter on. Can have multiple e.g. 
        @foobar* will only match any loggers starting with 'foobar'
        @*foobar* will only match any loggers containing 'foobar'

OUTPUT
  - +file/file : enable logging to file. Used the 'TM_LOG_FILE' env var, or defaults to 'tm.log'
  - -file : disable logging to file.
  - +console/console : enable console logging
  - -console : disable console logging
  - +syslog/syslog : enable syslog logging
  - -syslog : disable syslog logging
  - +rotate/rotate : enable log file rotation. Use TM_LOG_FILE_MAX_BYTES
  - -rotate : disable log file rotation.
OTHER OPTIONS:  
  -stack : include the stacktrace to all the log calls

  -help  : print this help

Options are processed in order, so subsequent options could override previous ones

This help was run as '\$TM_LOG'($TM_LOG) contained 'help'
EOF
  fi

  if [[ -z ${level:-} ]]; then
    level=$LEV_INFO
  fi

  local log_details=()
  if [[ $log_datestamp == true ]]; then
    # date+time
    log_details+=("\$(date +'%Y-%m-%d.%H:%M:%S.%3N')")
  elif [[ $log_timestamp == true ]]; then
    # just time
    log_details+=("\$(date +'%H:%M:%S.%3N')")
  elif [[ $log_epoch == true ]]; then
    log_details+=("\${EPOCHREALTIME}")
  fi
  if [[ $log_duration == true ]]; then
    log_details+=("\$(_tm::log::__elapsed_time)")
  fi
  if [[ $log_call_file == true ]] && [[ $log_call_func == true ]]; then
    log_details+=("\$(_tm::log::__caller_file_func)")
  elif [[ $log_call_file == true ]]; then
    log_details+=("\$(_tm::log::__caller_file)")
  elif [[ $log_call_func == true ]]; then
    log_details+=("\$(_tm::log::__caller_func)")
  fi
  if [[ $log_user == true ]]; then
    log_details+=("\$USER")
  fi
  if [[ $log_pid == true ]]; then
    log_details+=("p\$BASHPID")
  fi

  if [[ ${#log_details[@]} -ne 0 ]]; then
    local details="${log_details[@]}"
    local func_def="_tm::log::__details() {
        echo -n \"$details \" || true
    }"
    eval "$func_def"
  else # no-op
    _tm::log::__details(){ :; }
  fi

  if [[ $level -le $LEV_FINEST ]]; then
    _finest(){ _tm::log::finest "$@"; }
    _is_finest(){ true; }
  else
    _finest(){ :; }
    _is_finest(){ false; }
  fi
  if [[ $level -le $LEV_TRACE ]]; then
    _trace(){ _tm::log::trace "$@"; }
    _is_trace(){ true; }
  else
    _trace(){ :; }
    _is_trace(){ false; }
  fi
  if [[ $level -le $LEV_DEBUG ]]; then
    _debug(){ _tm::log::debug "$@" ; }
    _is_debug(){ true; }
  else
    _debug(){ :; }
    _is_debug(){ false; }
  fi
  if [[ $level -le $LEV_INFO ]]; then
    _info(){ _tm::log::info "$@"; }
    _is_info(){ true; }
  else
    _info(){ :; }
    _is_info(){ false; }
  fi
  if [[ $level -le $LEV_WARN ]]; then
    _warn(){ _tm::log::warn "$@"; }
    _is_warn(){ true; }
  else
    _warn(){ :; }
    _is_warn(){ false; }
  fi

  if [[ ${#__tm_log_filters[@]} -ne 0 ]]; then
    # only include matching loggers
    _tm::log::__filter() {
        local log_name="$1"
        for logger in "${__tm_log_filters[@]}"; do
          if [[ "$log_name" == $logger ]]; then
             true
             return
          fi
        done
        false
    }
  else # no-op
  _tm::log::__filter() {
     true
  }
  fi
  if [[ -n "$TM_LOG_FILE" ]]; then
      mkdir -p "$(dirname "$TM_LOG_FILE")"
      touch "$TM_LOG_FILE"
  fi
}

#
# Print to console with no prefix. To stderr so it won't be used in function returns
#
_tm::log::println(){
  >&2 echo -e "$1"
}

_tm::log::print(){
  >&2 echo -n -e "$1"
}

_tm::log::__print(){
    >&2 echo -e "$1"
}

if [[ -n "$TM_LOG_FILE" ]]; then
  mkdir -p "$(dirname "$TM_LOG_FILE")"
  touch "$TM_LOG_FILE"

  _tm::log::__print(){
    echo -e "$1" >> "$TM_LOG_FILE"
    >&2 echo -e "$1"
  }
fi

########## Logging ###########

# Log an error message (red text)
#
# Args:
#   $@ - Error message to log
#
# Output:
#   Writes formatted error message to stderr
#
# Usage:
#   _err "Something went wrong"
#
_err() {
    _tm::log::error "$*"
}

_error() {
    _tm::log::error "$*"
}

_todo() {
  _tm::log::__msg "TODO" "$COLOR_YELLOW" "$COLOR_YELLOW" "$*"
}

# Log a standard message (green text)
#
# Args:
#   $1 - log level finest|trace|debug|info|warn|error/err
#   $2+ - Message to log
#
# Output:
#   Writes formatted message to stderr
#
# Usage:
#   _log "Processing complete"
#
_log() {
  # we go through the _<level> scripts as these are swapped out by the log options
  case "${1:-}" in
    finest)
      shift
      _finest "$*"
      ;;
    trace)
      shift
      _trace "$*"
      ;;
    debug)
      shift
      _debug "$*"
      ;;
    info)
      shift
      _info "$*"
      ;;
    warn)
      shift
      _warn "$*"
      ;;
    error|err)
      shift
      _error "$*"
      ;;
    *)
      # assume user just wants to log to info
      _info "$*"
      ;;
  esac  
}


_tm::log::error() {
    _tm::log::__msg "ERR" "$COLOR_RED_BOLD" "$COLOR_RED" "$@"
}

# Log a warning message (red text)
#
# Args:
#   $@ - Warning message to log
#
# Output:
#   Writes formatted warning message to stderr
#
# Usage:
#   _warn "This might cause issues"
#
_tm::log::warn() {
  _tm::log::__msg "WRN" "$COLOR_ORANGE_BOLD" "$COLOR_ORANGE_BOLD" "$@"
}


# Log an informational message (green text)
#
# Args:
#   $@ - Info message to log
#
# Output:
#   Writes formatted info message to stderr
#
# Usage:
#   _info "Operation completed successfully"
#
_tm::log::info() {
  _tm::log::__msg "INF" "$BOLD" "" "$@"
}

# Log a debug message (grey text) if debug mode is enabled
#
# Args:
#   $@ - Debug message to log
#
# Output:
#   Writes formatted debug message to stderr if TM_LOG_DEBUG=1
#
# Usage:
#   _debug "Debug information"
#
_tm::log::debug() {
  _tm::log::__msg "DBG" "$COLOR_GREEN_BOLD" "$COLOR_GREEN" "$@"
}

#
# if debug is enabled
#
# _is_debug(){
#   [[ $TM_LOG_LEVEL -le $LEV_DEBUG ]] && return 0 || return 1
# }

_tm::log::trace() {
  _tm::log::__msg "TRC" "$COLOR_GREY_BOLD" "$COLOR_GREY" "$@"
}

#
# if trace is enabled
#
# _is_trace(){
#   [[ $TM_LOG_LEVEL -le $LEV_TRACE ]] && return 0 || return 1
# }

_tm::log::finest() {
  _tm::log::__msg "FINEST" "$COLOR_GREY" "$COLOR_GREY" "$@"
}

# _is_finest(){
#   [[ $TM_LOG_LEVEL -le $LEV_FINEST ]] && return 0 || return 1
# }

_tm::log::is_console(){
  [[ "$TM_LOG_CONSOLE" == '1' ]] && return 0 || return 1
}

# Log a message with color formatting
#
# Args:
#   $1 - Color code (e.g. $COLOR_RED, $COLOR_GREEN)
#   $@ - Message to log
#
# Output:
#   Writes formatted log message to stderr
#
# Usage:
#   _tm::log::__msg "$COLOR_RED" "Error message"
#
_tm::log::__msg() {
  # No need for the level check, as we replace the functions with no-op funcs in _tm::log::set_opts
  local level_name="$1"
  local color_details="$2"
  local color_text="$3"
  shift 3

  # the filter function might be set to only look for certain logs
  if ! _tm::log::__filter "$TM_LOG_NAME"; then
    return
  fi

  local logger_details="$(printf "%-12s" "$(_tm::log::__details)${TM_LOG_NAME}")"
  if [[ "${TM_LOG_CONSOLE:-}" == "1" ]]; then
    _tm::log::__to_console "$level_name" "$logger_details" "$color_details" "$color_text" "$*"
  fi
  if [[ -n "${TM_LOG_SYSLOG:-}" ]]; then
    _tm::log::__to_syslog "$level_name" "$logger_details" "$*"
  fi
  if [[ -n "${TM_LOG_FILE:-}" ]]; then
    _tm::log::__to_file "$level_name" "$TM_LOG_NAME" "$*"
  fi
}

_tm::log::__to_console(){
  local level_name="$1"
  local logger_details="$2"
  local color="$3"
  shift 3

  >&2 echo -e "${color}${level_name} [${logger_details}] ${*}${COLOR_NONE}"

  _tm::log::__stack
}

_tm::log::__to_syslog(){
  local level_name="$1"
  local log_name="$2"
  shift 2

  # TODO: only info and up?

  logger "${level_name} [${log_name}] ${*}"
}

_tm::log::__to_file(){
  local level_name="$1"
  local logger_details="$2"
  shift 2
  if [[ -f "$TM_LOG_FILE" ]] && [[ "${EPOCHSECONDS}" -gt "${__tm_log_next_file_rotate_check:-0}" ]]; then
    local file_size
    local MAX_BYTES=
    if [[ "$(uname)" == "Darwin" ]]; then
      file_size="$(stat -f %z "$TM_LOG_FILE")"
    else
      file_size="$(stat -c %s "$TM_LOG_FILE")"
    fi
    if [[ "${file_size}" -gt "${TM_LOG_FILE_MAX_BYTES:-10000000}" ]]; then # 10mb
      _tm::log::_rotate_log_file "${TM_LOG_FILE}"
      __tm_log_next_file_rotate_check=$(($EPOCHSECONDS + 30)) # when to check next
    fi
  fi
  echo "${level_name} [${logger_details}] ${*}" >> "$TM_LOG_FILE" || true
  _tm::log::__stack >> "$TM_LOG_FILE" || true
}

_tm::log::_rotate_log_file(){
    local log_file="$1"
    local counter=0
    local max_counter=0

    # Find all files that start with the base name and end with a dot followed by digits
    for file in "${log_file}."*; do
        if [[ "$file" =~ ^"${log_file}"\.[0-9]+$ ]]; then
            # Extract the counter part (e.g., "1" from "app.log.1")
            local counter_str="${file##*.}"
            # Convert to integer
            counter=$((10#$counter_str))
            if (( counter > max_counter )); then
                max_counter=$counter
            fi
        fi
    done
    # calculate the rotated file name
    local log_file_dest
    # If no numbered files were found, start with 1, otherwise increment the max
    if (( max_counter == 0 )); then
        log_file_dest="$(echo "${log_file}.1")"
    else
        log_file_dest="$(echo "${log_file}.$((max_counter + 1))")"
    fi
    #move the old log file (we copy then clear to more robustly handle failure)
    cp "${log_file}" "${log_file_dest}" || >&2 echo "WRN: error rotating log file"
    echo "" > "${log_file}"
}


# setup by _tm::log:set_opts
_tm::log::__stack(){
  :
}

# set by the the _tm::log::set_opts
_tm::log::__details(){
  :
}

# set by the the _tm::log::set_opts
_tm::log::__filter(){
  :
}

#
# Replace the current log name with the given name
#
# Call '_tm::log::pop' to restore to the previous log name
#
# Arguments:
# $1 - the log name
#
_tm::log::push_name(){
  if [[ "$1" != "$TM_LOG_NAME" ]]; then
    #_tm::log::finest "setting logname to '$1'"
    __tm_log_names+=("$TM_LOG_NAME")
    TM_LOG_NAME="$1"
  fi
}

#
# Append the given name to the end of the current log name, using a ':' separator
#
# Call '_tm::log::pop' to restore to the previous log name
#
# Arguments:
# $1 - the log name
#
_tm::log::push_child(){
  if [[ "$1" != "$TM_LOG_NAME" ]]; then
    local new_name="$TM_LOG_NAME:$1"
    __tm_log_names+=("$TM_LOG_NAME")
    TM_LOG_NAME="$new_name"
  fi
}

#
# Restore the log name to the previous log name, if it has previously been pushed with
# '_tm::log::push_name' or '_tm::log::push_child'
#
# If no pushed names, does nothing
#
# Arguments:none
#
_tm::log::pop(){
  if [[ ${#__tm_log_names[@]} -gt 0 ]]; then

    TM_LOG_NAME="${__tm_log_names[-1]}"
    unset '__tm_log_names[-1]'
  fi
}

_tm::log::stacktrace(){
  local indent="${1:-}"
  >&2  echo "${indent}^^stacktrace^^:"
  local i=1 line file func
  # Loop through the call stack (excluding the stack_trace function itself)
  while IFS=' ' read -r line func file < <(caller $i); do
      # Print each frame of the stack: [frame_number] file:line function_name
    if [[ "$file" != *"/lib.log.sh" ]]; then # first non logger file
      >&2 echo "${indent}   [${i}]  ${file}:${line} ${func}()"
    fi
      ((i++))
  done
}

_tm::log::stacktrace::on_error(){
   trap _tm::log::stacktrace ERR
}


######## internal methods ##########

# Calculate elapsed time since script start
#
# Output:
#   Prints elapsed time
#
# Usage:
#   _tm::log::__elapsed_time
#
_tm::log::__elapsed_time() {
    echo "$(((`date +%s%N`-${__tm_log_starttime:-0})/1000000))ms"
}

_tm::log::__caller_file_func(){
  local i=0
  local line file func
  while IFS=' ' read -r line func file < <(caller $i); do         
    if [[ "$file" != *"/lib.log.sh" ]] && ([[ "$file" != *"/lib.util.sh" ]] && [[ "$func" != "_fail" ]]); then # first non logger file
      echo -n "($(_tm::log::__safe_basename "${file}"):${line} ${func})"
      return
    fi    
    ((i++))
  done
}

_tm::log::__caller_file(){
  local i=0
  local line file func
  while IFS=' ' read -r line func file < <(caller $i); do         
    if [[ "$file" != *"/lib.log.sh" ]] && ([[ "$file" != *"/lib.util.sh" ]] && [[ "$func" != "_fail" ]]); then # first non logger file
      echo -n "($(_tm::log::__safe_basename "${file}"):${line})"
      return
    fi
    ((i++))
  done
}

_tm::log::__caller_func(){
  local i=0
  local line file func
  while IFS=' ' read -r line func file < <(caller $i); do         
    if [[ "$file" != *"/lib.log.sh" ]] && ([[ "$file" != *"/lib.util.sh" ]] && [[ "$func" != "_fail" ]]); then # first non logger file
      echo -n "(#${func})"
      return
    fi
    ((i++))
  done
}

_tm::log::__safe_basename(){
  local file="${1:-}"
  if [[ -z "${file}" ]]; then
    echo "?"
  else
    basename "${file}"
  fi
}


_tm::log::init
