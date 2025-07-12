if command -v _tm::service::add &>/dev/null; then # already loaded
  return
fi

_tm::source::include_once @tm/lib.path.sh @tm/lib.parse.sh @tm/lib.io.conf.sh "$TM_BIN/.tm.venv.directives.sh"

#
# Register a service
#
# Arguments:
# $1 - the service config file
# $2 - the plugin associative array
#
_tm::service::add() {
  local -n plugin_ref="$1"
  local service_conf="$2"

  local qpath="${plugin_ref[qpath]}"
  local plugin_id="${plugin_ref[id]}"

  local service_name="$(basename "$service_conf" .sh)" # handles .sh extension
  service_name="${service_name%.conf}"                 # handles .conf extension

  local -A service
  _tm::service::parse_service_conf "${plugin_id}" "$service_conf}" service

  # write to disk

  # TODO: write a sanitised file
  local link_file="${TM_PLUGINS_SERVICES_DIR}/${qpath}/${service_name}.sh"
  mkdir -p "$(dirname "${link_file}")"
  ln -fs "${service_conf}" "${link_file}"
  _tm::event::fire "tm.service.add" "" "${plugin_id}" "${service_name}" "${service_conf}"
}

#
# Start a service
#
# Arguments:
# $1 - the service config file
# $2 - the plugin name or id
#
_tm::service::start() {
  local plugin_name="$1"
  local service_conf="$2"

  local -A service_plugin
  _tm::parse::plugin service_plugin "$plugin_name"
  local qpath="${service_plugin[qpath]}"
  local plugin_id="${service_plugin[id]}"
  local plugin_cfg_sh="${service_plugin[cfg_sh]}"
  local plugin_id="${service_plugin[id]}"

  local service_name="$(basename "$service_conf" .sh)" # handles .sh extension
  service_name="${service_name%.conf}"                 # handles .conf extension

  _tm::event::fire "tm.service.start.start" "${plugin_id}" "${service_name}" "${service_conf}"

  # Track PID in the central TM_PLUGINS_PID_DIR
  if [[ -f $service_conf ]]; then
    _info "found service definition: $service_conf"
    local plugin_pid_base="$TM_PLUGINS_PID_DIR/${qpath}"
    mkdir -p "${plugin_pid_base}"
    local service_name
    service_name=$(basename "$service_conf" .conf)
    local pid_file="${plugin_pid_base}/service.${service_name}.pid"
    if [[ -f ${pid_file} ]]; then
      local -A service_details
      _tm::io::conf::read_file service_details "${service_conf}"
      local service_pid="${service_details[pid]}"
      if [[ -n ${service_pid} ]]; then
        # todo: check if running, if so, kill it?
        kill "${service_pid}" || _debug "Error killing service '${service_name}' with pid '${service_pid}'"
      fi
    fi
    # TODO: wrap in a wrapper script to restart on failer?
    "$file" &
    local pid="$!"
    mkdir -p "$(dirname "$pid_file")"
    echo "pid=$pid"
    echo "started_date=$(date +'%Y-%m-%d.%H:%M:%S.%3N')"
    echo "path=$service_conf"
    echo "name=$service_name"
    echo "plugin_id=${plugin_id}"
    echo "plugin_cfg=${plugin_cfg_sh}" >"$pid_file"
    _debug "service '$service_name' started with PID $pid (PID file: $pid_file)"

    _tm::event::fire "tm.service.start.finish" "${plugin_id}" "${service_conf}"
  fi
}

_tm::service::stop() {
  local plugin_name="$1"
  local service_conf="$2"

  local -A service_plugin
  _tm::parse::plugin service_plugin "$plugin_name"
  local qpath="${service_plugin[qpath]}"
  local plugin_id="${service_plugin[id]}"

  local service_name="$(basename "$service_conf" .sh)" # handles .sh extension
  service_name="${service_name%.conf}"                 # handles .conf extension

  _tm::event::fire "tm.service.stop" "${plugin_id}" "${service_name}" "${service_conf}"
  _todo "implement '_tm::service::stop' for '${qpath}'"
}

_tm::service::pause() {
  local plugin_name="$1"
  local service_conf="$2"

  local -A service_plugin
  _tm::parse::plugin service_plugin "$plugin_name"
  local qpath="${service_plugin[qpath]}"
  local plugin_id="${service_plugin[id]}"

  local service_name="$(basename "$service_conf" .sh)" # handles .sh extension
  service_name="${service_name%.conf}"                 # handles .conf extension

  _tm::event::fire "tm.service.pause" "${plugin_id}" "${service_name}" "${service_conf}"

  _todo "implement '_tm::service::pause' for '${qpath}'"
}

#
# List the services for the given plugin
#
# $1 - the plugin or tool-manager to list the service for. If not provided, defautls to all the services
#
_tm::service::list_service_conf() {
  local plugin_name="${1:-"${__TM_PLUGIN_ID}"}"
  local -A plugin
  _tm::parse::plugin plugin "${plugin_name}"

  local is_tm="${plugin[is_tm]}"
  if [[ $is_tm == true ]]; then
    _tm::service::list_all
  else
    _todo "list plugins services for plugin '${plugin[qname]}'"
  fi
}

#
# List all the current services
#
#
_tm::service::list_all() {
  local _print_file
  _print_file() {
    local file="$1"
    local indent="$2"
    #echo -e "${indent}  contents:"
    sed "s/^/${indent}   | /" "$1"
  }

  if [[ -d $TM_PLUGINS_SERVICES_DIR ]]; then
    _tm::path::tree "$TM_PLUGINS_SERVICES_DIR" _tm::service::__print_service_conf
  fi

  # list all the servicess
  if [[ -d $TM_PLUGINS_PID_DIR ]]; then
    _tm::path::tree "$TM_PLUGINS_PID_DIR" _print_file
  fi
}

#
# Print the service config in a user friendly way
#
# Arguments:
# $1 - the service conf to read
# $2 - an optional indent, used when echoing the output
#
_tm::service::__print_service_conf() {
  local file="$1"
  local indent="${2:-}"
  local -A details
  _tm::io::conf::read_file details "${file}" requires
  local all_keys=()
  for key in "${!details[@]}"; do
    all_keys+=("$key")
  done
  # Sort all keys alphabetically once
  IFS=$'\n' sorted_all_keys=($(sort <<<"${all_keys[*]}"))
  unset IFS

  indent="${indent}   | "

  # Print non-function keys first
  for key in "${sorted_all_keys[@]}"; do
    if [[ $key != *"()" ]]; then
      echo -e "${key}=${details[$key]:-}" | sed "s/^/${indent}    /"
    fi
  done

  # Print function keys second
  local has_func_keys=false
  for key in "${sorted_all_keys[@]}"; do
    if [[ $key == *"()" ]]; then
      has_func_keys=true
      break
    fi
  done

  if ${has_func_keys}; then
    echo -e "${indent}Operations:"
    for key in "${sorted_all_keys[@]}"; do
      if [[ $key == *"()" ]]; then
        echo -e "${indent}   ${key}"
      fi
    done
  fi
}

#
# Read a service conf file and populate the associative array
#
# Arguments:
# $1 - the plugin name or id
# $2 - the service conf file to read
# $3 - the associative array to populate
#
_tm::service::parse_service_conf() {
  local plugin_name="$1"
  local service_conf="$2"
  local -n service_array_ref="$3" # the associative array of service details

  local -A service_plugin
  _tm::parse::plugin service_plugin "$plugin_name"
  _tm::io::conf::read_file service_array_ref "${file}" requires
  local qname="${service_plugin[qname]}"

  local service_name
  service_name="$(basename "$service_conf" .sh)" # handles .sh extension

  # set calculated values
  service_array_ref[service_name]="${service_name}"
  #service_array_ref[name]="${service_name}"
  service_array_ref[service_conf]="${service_conf}"
  service_array_ref[plugin_id]="${service_plugin[id]}"
  service_array_ref[plugin_cfg_sh]="${service_plugin[cfg_sh]}"
  service_array_ref[service_cfg_sh]="${service_plugin[cfg_sh]}"

  if [[ -z ${service_array_ref[label]:-} ]]; then
    service_array_ref[label]="${service_name}"
  fi
  if [[ -z ${service_array_ref[desc]:-} ]]; then
    service_array_ref[desc]="Service '${service_name}' for plugin '${qname}'"
  fi

  if [[ -z ${service_array_ref['start()']:-} ]]; then
    # eek! we need a start function
    :
  fi

  service_array_ref[restart]="$(_tm::parse::boolean "${service_array_ref[restart]:-}")"
  service_array_ref[auto_start]="$(_tm::parse::boolean "${service_array_ref[auto_start]:-}")"
  service_array_ref[enabled]="$(_tm::parse::boolean "${service_array_ref[enabled]:-1}")"

  # todo: parse directives

}
