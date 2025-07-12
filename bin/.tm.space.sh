_include @tm/lib.file.env

_tm::space::launch_by_file() {
  local space_file="${1}"
  if [[ -z ${space_file} ]]; then
    _fail "No space file provided"
  fi
  if [[ ! -f ${space_file} ]]; then
    _fail "Space file '${space_file}' does not exist"
  fi
  local -A space
  _tm::space::file::read_array space "${space_file}"
  _info "Launching space:"
  _tm::space::print_info space
  if [[ ${space[active]} != 'true' ]]; then
    _fail "space is not marked as active"
  fi
  _fail "implement _tm::space::launch"
}

_tm::space::file::find_all() {
  local -a space_files=()
  readarray -t space_files < <(find "$TM_SPACE_DIR" -maxdepth 1 -type f -name ".space.*.ini" -print0 | xargs --null grep "key" -l || true)
  for space_file in "${space_files[@]}"; do
    echo "${space_file}"
  done
}

_tm::space::file::get_by_guid_or_key() {
  local space_guid="${1}"
  if [[ -z $space_guid ]]; then
    _fail "No space guid provided"
  fi
  local space_file="$TM_SPACE_DIR/space.${space_guid}.${__TM_CONF_EXT}"
  if [[ ! -f $space_file ]]; then
    _error "No space with guid '${space_guid}'"
    false
  fi

  echo "$space_file"
}

_tm::space::file::get_by_guid() {
  local space_guid="${1}"
  if [[ -z $space_guid ]]; then
    _fail "No space guid provided"
  fi
  local space_file="$TM_SPACE_DIR/space.${space_guid}.${__TM_CONF_EXT}"
  if [[ ! -f $space_file ]]; then
    _error "No space with guid '${space_guid}'"
    false
  fi

  echo "$space_file"
}

_tm::space::file::get_by_key() {
  local space_key="${1}"
  if [[ -z $space_key ]]; then
    _fail "No space key provided"
  fi
  if [[ ! -d ${TM_SPACE_DIR} ]]; then
    _error "No space with key '${space_key}'"
    false
  fi

  local space_file="$(find "$TM_SPACE_DIR" -maxdepth 1 -type f -name ".space.*.${__TM_CONF_EXT}" | xargs grep -le "^key=${space_key}$" | head -n 1)"
  if [[ ! -f ${space_file} ]]; then
    _error "No space with key '${space_key}'"
    false
  fi

  echo "$space_file"
}

_tm::space::file::read_array() {
  local -n space_details_ref="${1}"
  local space_file="${2}"
  space_ref=() #clear

  if [[ -z ${space_file} ]]; then
    _error "No space file provided "
    false
  fi
  if [[ ! -f ${space_file} ]]; then
    _error "No space file '${space_file}'"
    false
  fi
  _tm::file::env::read space_details_ref "$space_file"

  space_details_ref[id]="${space_details_ref[guid]}"
  space_details_ref[space_file]="${space_file}"
  space_details_ref[space_zip]="${space_details_ref[guid]}.zip"
  if [[ -z ${space_details_ref[dir]:-} ]]; then
    space_details_ref[dir]="${TM_SPACE_DIR}/${space_details_ref[key]}"
  fi
}

_tm::space::print_info() {
  local -n space_details_ref="${1}"
  for key in "${!space_details_ref[@]}"; do
    echo "$(printf "%-12s" "${key}") : ${space_details_ref["$key"]}"
  done
}

_tm::space::parse_id() {
  local id="$1"
  _error "implement me"

}
