# end early if already setup
if command -v _tm::source &>/dev/null; then
  return
fi

#
# For users
#
_source() { 
  _tm::source::__init
  _tm::__source 0 "$@"
}

_source_once() { 
  _tm::source::__init
  _tm::__source 1 "$@"
}

_include() {
  _tm::source::__init
  _tm::source::__include 0 "${BASH_SOURCE[1]}" "$@"
}

_include_once() {
  _tm::source::__init
  _tm::source::__include 1 "${BASH_SOURCE[1]}" "$@"
}

#
# Called internally by all the user facing functions, to ensure the arrays are setup. These functions could be called
# by user scripts, in which case the entry point is the function, not the 'source path/to/this/script'
# and hence we need to check the init was carried out.
#
# This is more magic than most other functions, as it is assumed in other cases that the lib.log.sh and lib.source.sh
# are loaded. However lib.source.sh can be invoked before everything has been setup, so needs to be more aware of boot
# strapping sequencing and the like, and handle the case where not everything has been setup yet.
#
#
_tm::source::__init(){
    if [[ ! -v __tm_source_inited ]]; then
      __tm_source_inited=1

      # associative arrays are buggy. We need to declare them in a special way to ensure they work
      # see https://stackoverflow.com/questions/10806357/associative-arrays-are-local-by-default
      declare -gA __tm_source_to_dir
      declare -gA __tm_sourced
      __tm_source_to_dir=() # cache so we don't need to 'cd .. and pwd...' each time a script makes an include/source call
      __tm_sourced=() # track what has already been sourced

      # we have most likely been called via an exported function. The tool-manager has not loaded in the current process
      if [[ ! $(type -t _trace) == function ]]; then
        # ensure all the functions we depend on are loaded
        __tm_sourced+=( "$TM_LIB_BASH/lib.source.sh")
        builtin source "$TM_LIB_BASH/lib.source.sh"
      fi
   fi
   # ensure the logging functions are loaded
   if ! command -v _tm::log::init &>/dev/null; then
      __tm_sourced+=( "$TM_LIB_BASH/lib.log.sh" )
      builtin source "$TM_LIB_BASH/lib.log.sh"
   fi
}

_tm::source::include(){
  _tm::source::__init
  _tm::source::__include 0 "${BASH_SOURCE[1]}" "$@"
}

_tm::source::include_once(){
  _tm::source::__init
  _tm::source::__include 1 "${BASH_SOURCE[1]}" "$@"
}

#
# Sources a script relative to a calling script, or if a lib script (in the form '@<vendor>/<lib-name>.sh', e.g. '@tm/lib.args.sh'),
# sources the lib
#
# $1     - 0/1, whether to only source this once, or reload
# $2     - the calling script. Used to determine relative paths
# $3...  - the files to source. Can be libs, relative paths etc
#
# It is most efficient to source multiple relative paths in one line as then we only need to calculate the script dir once
#
_tm::source::__include(){
  local once="$1"
  local calling_script="$2"
  shift 2 # the next args become the files to source
  local script_dir=''
  for file in "$@"; do
    if _is_finest; then
      if [[ "$once" == '1' ]]; then
        _finest "include once '$file' (from $calling_script)"
      else
        _finest "include '$file' (from $calling_script)"
      fi
    fi
    if [[ "$file" == "@tm/"* ]]; then  # built-in tool-manager lib
      local lib_name="${file:4}"
      if [[ "${lib_name}" != *".sh" ]]; then
        lib_name+=".sh"
      fi
      _tm::__source "$once" "${TM_LIB_BASH}/${lib_name}"
    elif [[ "$file" == "@"* ]]; then  # vendor (plugin) provided lib (linked to a plugin's 'lib' directory)
      local lib_name="${file##*/}"
      if [[ "${lib_name}" != *".sh" ]]; then
        lib_name+=".sh"
      fi
      local temp_vendor="${file#@}" # Remove the leading '@'
      local vendor="${temp_vendor%%/*}" # Remove everything from '/' onwards
      if [[ "$vendor" == 'this' ]]; then
          # need to get the caller, as the calling codemay be a shared lib, and 'this' would mean it's plugin dir
        # TODO: find the scripts home
        calling_script="${BASH_SOURCE[1]}"
        if [[ -n "$TM_PLUGIN_HOME" ]] && [[ "${calling_script}" == "${TM_PLUGINS_INSTALL_DIR}"/* ]]; then
          # todo: use the script wrapper set 'TM_PLUGIN_HOME' to point to the current dir?
          # it could point to the shared libs, or the internal libs
          for lib_path in "lib/bash/${lib_name}" "lib-shared/bash/${lib_name}" "lib/${lib_name}"; do
            local lib_file="$TM_PLUGIN_HOME/${lib_path}"
            if [[ -f "${lib_file}" ]]; then
              _tm::__source "$once" "${lib_file}" # TM_PLUGIN_HOME should be set by the wrapper scripts
              break
            fi
          done
          _fail "Could not source '$file'. Not found. Looked for 'lib/bash/${lib_name}', 'lib/shared/bash/${lib_name}', and 'lib/${lib_name}"
        elif [[ "${calling_script}" == "${TM_PLUGINS_LIB_DIR}"/* ]]; then
          # we are being called by a shared lib script, so the lib name should be relative to the lib's home bin dir
          # shared scripts live in '<plugin-home>/lib-shared/bash' So we go up two, then head into the 'bin dir
          _tm::__source "$once" "$(cd "$(dirname "${calling_script}" )/../../bin" && pwd)/${lib_name}"
        else
          # relative to callers scripts dir
          _tm::__source "$once" "$(cd "$(dirname "${calling_script}" )" && pwd)/${lib_name}"
        fi
      else
        _tm::__source "$once" "$TM_PLUGINS_LIB_DIR/${vendor}/bash/${lib_name}"
      fi
    elif [[ "$file" == "/"* ]]; then  # absolute path
      _tm::__source "$once" "$file"
    else # a relative script
      if [[ -z "${script_dir}" ]]; then # lazy calc once for this include
        # get the cached script dir
        script_dir="${__tm_source_to_dir["$calling_script"]:-}"
        if [[ -z "$script_dir" ]]; then # calc and cache the scripts dir
          script_dir="$( cd "$( dirname "$calling_script" )" &> /dev/null && pwd )"
          __tm_source_to_dir["$script_dir"]="$script_dir"
        fi
      fi
      _tm::__source "$once" "${script_dir}/${file}"
    fi

  done
}

# Sources a given Bash script file only if it has not already been sourced
# in the current shell session. This prevents redundant loading and potential errors.
#
# Args:
#   $1 - file: The full path to the script file to be sourced.
#
_tm::source::once(){
  _tm::source::__init
  _tm::__source 1 "$@"
}

# Sources a given Bash script file
#
# Args:
#   $1 - file: The full path to the script file to be sourced.
#
_tm::source(){
  _tm::source::__init
  _tm::__source 0 "$@"
}

_tm::__source(){
  local once="$1"
  local file="$2"

  if [[ "$once" == '1' ]]; then
      if [[ -n "${__tm_sourced["$file"]:-}" ]]; then
        _finest "already sourced: '$file'"
        return
      fi
      _trace "sourcing once '$file'"
  else
    _trace "sourcing '$file'"
  fi

  __tm_sourced["$file"]='1' # flag as sourced
  if [[ -f "$file" ]]; then
    builtin source "$file"
  else
    # find the caller of the source
    local msg="Can't source '$file'"
    local i=1
    local calls_func=''
    local add_location=0
    while read -r line func func_file < <(caller $i); do
        if [[ "$func_file" != *"/lib.source.sh" ]]; then # first non lib source stack (ignore all the the _tm::source and _tm::include etc)
          msg+=" at ${func_file}:${line}#${calls_func}()"
          add_location=1
        fi
        if [[ $add_location == 1 ]] && [[ "$func_file" != *"/lib." ]]; then # first non lib stack (so user call)
          break
        fi
        calls_func="$func"
        ((i++))
    done

    _fail "$msg"
  fi

}

_tm::source::__init