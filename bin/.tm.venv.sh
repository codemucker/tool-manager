#
# Run a script in a given env
#
# Arguments:
# $1 - the interpreter or runner to use (e.g. bash, java, python etc). Empty if no runner, so run script directly
# $2 - the script to run
# $3.. - the args to pass to the script
#
__tm::venv::run() {
  local script_runner="$1" # eg. python, bash etc
  local script_path="$2"
  shift 2 # remaining are what to run in the env with the given runner. First arg is typically the script

  local -A env
  __tm::venv::__calc_env env "$script_runner" "$script_path"
  __tm::venv::__invoke env "$@"
}

__tm::venv::__calc_env() {
  local -n env_details="$1" #associative array
  local script_runner="$2"
  local script_path="$3"

  env_details=() # clear the array

  #
  # We cache the results of the parse, and only regenerate an environment if changes detected. This makes
  # script invocation much faster

  # Get a hash of the file, only regenerate if things changed, or the env needs updating (e.g. removed)
  local current_checksum=$(stat -c %Y "$script_path" | md5sum | awk '{print $1}') # Hash concatenated mtimes. Probably good enough for now
  local path_hash=$(echo "$script_path" | md5sum | awk '{print $1}')              # Consistent cache file name
  local cache_base_path="$TM_CACHE_DIR/env-tm-python/script-${path_hash}"

  # a file that has cached our previous analysis of this file. It includes a checksum of the file we analysed, so that we can detect when
  # it needs regeneration
  # we want to do as little work as possible once we have a script env setup, so lazy load as much as we can
  local cache_file="${cache_base_path}.cache"
  if [[ -f $cache_file ]]; then # load from cache
    local saved_checksum venv_type venv_provider venv_path
    IFS=',' read -r saved_checksum venv_type venv_provider venv_path < <(cat "${cache_file}")

    _is_finest && _finest "cache_file '${cache_file}', contents: $(cat "${cache_file}")"
    _is_trace && _trace "venv_type='${venv_type}' venv_provider='${venv_provider}' venv_path='${venv_path}'"
    env_details[venv_type]="${venv_type}"
    env_details[venv_provider]="${venv_provider}"
    env_details[venv_path]="${venv_path}"
  fi

  # analyse file if we have no cache, or the file checksum has changed
  if [[ ! -f ${cache_file} ]] || [[ $current_checksum != "${saved_checksum:-}" ]]; then
    rm "${cache_base_path}."* || true
    # extract all the directives from the script
    local directives_file="${cache_base_path}.${current_checksum}.tm.requires.txt"
    if [[ ! -f $directives_file ]]; then
      _source_once "$TM_BIN/.tm.venv.directives.sh"
      _tm::venv::extract_directives "${script_path}" "${directives_file}"
    fi
    _is_finest && _finest "directives_file '$directives_file', contents: $(cat "$directives_file")"

    # clear the env details
    env_details=()

    # Use mapfile (or readarray) to read lines into an array
    # -t option removes the trailing newline character from each line
    mapfile -t directives < <(cat "$directives_file")

    local pip_requirements_file="${cache_base_path}.${current_checksum}.pip.requirements.txt"
    if [[ -f ${pip_requirements_file} ]]; then
      rm "${pip_requirements_file}" || true
    fi
    mkdir -p "$(dirname "${pip_requirements_file}")"

    for directive in "${directives[@]}"; do
      echo "directive: '$directive'" # Using quotes around $line is crucial to preserve spaces
      # Perform actions with "$line" here
      if [[ -n ${directive} ]]; then
        _debug "  - '${directive}'" # Log the full directive
        if [[ ${directive} == "pip="* ]]; then
          # Extract the package spec after "pip"
          local pip_package="${directive#pip=}"
          echo "${pip_package}" >>"${pip_requirements_file}"
          if [[ -z ${env_details[pip]:-} ]]; then
            env_details[pip]="${pip_package}"
          else
            env_details[pip]+=",${pip_package}"
          fi
        elif [[ ${directive} == "apt="* ]]; then
          # Extract the package spec after "apt"
          local apt_package="${directive#apt=}"
          if [[ -z ${env_details[apt]:-} ]]; then
            env_details[apt]="${apt_package}"
          else
            env_details[apt]+=",${apt_package}"
          fi
        elif [[ ${directive} == "mvn="* ]]; then
          # Extract the package spec after "mvn"
          local mvn_package="${directive#mvn=}"
          if [[ -z ${env_details[mvn]:-} ]]; then
            env_details[mvn]="${mvn_package}"
          else
            env_details[mvn]+=",${mvn_package}"
          fi
        elif [[ ${directive} == "python="* ]]; then
          env_details[python_version]="${directive#python=}"
        elif [[ ${directive} == "venv:provider="* ]]; then
          env_details[venv_provider]="${directive#venv:provider=}"
        elif [[ ${directive} == "venv="* ]]; then
          env_details[venv_type]="${directive#venv=}"
        elif [[ ${directive} == "hashbang="* ]]; then
          env_details[script_runner]="${directive#hashbang=}"
        elif [[ ${directive} == "docker:file="* ]]; then
          env_details[docker_file]="${directive#docker:file=}"
        elif [[ ${directive} == "docker:container="* ]]; then
          env_details[docker_container]="${directive#docker:container=}"
        else
          : #_debug "    (Note: Non-pip/non-python directive captured: $req_line)"
        fi
      fi
    done
    local venv_path=''
    if [[ ${env_details[venv_type]:-} != "none" ]]; then
      _debug "pip requirements file ${pip_requirements_file}"

      # list requirements if any
      if [[ -f ${pip_requirements_file} ]]; then
        _is_debug && _debug "Script 'pip' require directives found: $(cat "${pip_requirements_file}")" || true
      fi
      venv_path="$(__tm::venv::__calc_venv_dir "${script_path}" "${env_details[venv_type]:-}")"
    fi
    mkdir -p "$(dirname "${cache_file}")"
    echo -e "$current_checksum,${env_details[venv_type]:-},${env_details[venv_provider]:-},$venv_path" >"${cache_file}"

    env_details[venv_path]="${venv_path}"
  fi

  # file out missing fields
  if [[ -z ${env_details[venv_type]:-} ]]; then
    env_details[venv_type]="plugin"
  fi
  if [[ -z ${env_details[venv_provider]:-} ]]; then
    env_details[venv_provider]="python"
  fi
  if [[ -z ${env_details[python_version]:-} ]]; then
    env_details[python_version]="3.13"
  fi
  if [[ -z ${env_details[script_runner]:-} ]]; then
    env_details[script_runner]="${script_runner}"
  fi

  env_details[pip_requirements_file]="${pip_requirements_file:-}"
}

__tm::venv::__invoke() {
  local -n env_details="$1" #associative array
  shift                     # remaining args are script args

  local venv_type="${env_details[venv_type]}"
  local script_runner="${env_details[script_runner]:-}"

  if [[ $venv_type == "none" ]]; then
    # run directly
    case "${script_runner}" in
      python | python3) _python3 "$@" ;;
      python2) _python2 "$@" ;;
      bash) bash "$@" ;;
      node) node "$@" ;;
      *) "$@" ;;
    esac
  else
    local venv_path="${env_details[venv_path]}"
    local venv_provider="${env_details[venv_provider]}"
    local pip_requirements_file="${env_details[pip_requirements_file]:-}"

    _debug "Target venv path: ${venv_path}"
    # Ensure the parent directory for the venv exists
    mkdir -p "$(dirname "${venv_path}")"
    case "${venv_provider}" in
      uv)
        case "${script_runner}" in
          python | python2 | python3) __tm::venv::__invoke_in_uv_env env_details uv run --no-project "$@" ;;
          node) __tm::venv::__invoke_in_uv_env "${venv_path}" env_details uv run --no-project node "$@" ;; # todo: install node deps?
          *) __tm::venv::__invoke_in_uv_env env_details uv run --no-project "$@" ;;
        esac
        ;;
      python)
        case "${script_runner}" in
          python | python2 | python3) __tm::venv::__invoke_in_python_venv env_details python "$@" ;;
          node) __tm::venv::__invoke_in_python_venv env_details node run "$@" ;; # todo: install node deps?
          *) __tm::venv::__invoke_in_python_venv env_details "$@" ;;
        esac
        ;;
      conda)
        _fail "unsupported venv_provider '${venv_provider}'"
        ;;
      docker)
        case "${script_runner}" in
          python | python2 | python3) __tm::venv::__invoke_in_docker env_details /bin/python "$@" ;;
          bash) __tm::venv::__invoke_in_docker env_details /bin/bash "$@" ;;
          node) __tm::venv::__invoke_in_docker env_details /bin/node run "$@" ;; # todo: install node deps?
          *) __tm::venv::__invoke_in_docker env_details /bin/bash "$@" ;;
        esac
        ;;
      docker+uv)
        _fail "unsupported venv_provider '${venv_provider}'"
        ;;
      docker+venv)
        _fail "unsupported venv_provider '${venv_provider}'"
        ;;
      *)
        _fail "unknown venv_provider '${venv_provider}'"
        ;;
    esac
  fi
}

__tm::venv::__calc_venv_dir() {
  local script_file="${1}"
  local venv_type="${2:-}"

  __calc_plugin_venv_dir() {
    local script_path="$1"
    local dir="$2"
    _trace "args: $*"

    local remove_prefix="${dir}/"
    local script_rel_path="${script_path#$remove_prefix}"
    local plugin_dir_name="${script_rel_path%%/*}"
    local -A plugin=()
    _tm::parse::plugin_name plugin "$plugin_dir_name"
    echo -n "${TM_PLUGINS_VENV_DIR}/plugin-${plugin['key']}"
  }

  if [[ ${venv_type} == 'script' ]]; then
    echo -n "${TM_PLUGINS_VENV_DIR}/script-$(echo -n "${script_file}" | base64 | md5sum | cut -d ' ' -f1)"
  elif [[ ${script_file} == "$TM_HOME/"* ]]; then
    echo -n "${TM_PLUGINS_VENV_DIR}/tool-manager"
  elif [[ -n ${TM_PLUGINS_INSTALL_DIR} && ${script_file} == "${TM_PLUGINS_INSTALL_DIR}/"* ]]; then
    __calc_plugin_venv_dir "${script_file}" "${TM_PLUGINS_INSTALL_DIR}"
  elif [[ -n $TM_PLUGINS_ENABLED_DIR && ${script_file} == "${TM_PLUGINS_ENABLED_DIR}/"* ]]; then
    __calc_plugin_venv_dir "${script_file}" "${TM_PLUGINS_ENABLED_DIR}"
  else
    # per script venv atm, to improve isolation
    echo -n "${TM_PLUGINS_VENV_DIR}/script-$(echo -n "${script_file}" | base64 | md5sum | cut -d ' ' -f1)"
  fi
}

__tm::venv::__invoke_in_uv_env() {
  local -n uv_env="$1" # associative array
  shift
  local venv_path="${uv_env[venv_path]}"
  local venv_provider="${uv_env[venv_provider]}"
  local pip_requirements_file="${uv_env[pip_requirements_file]:-}"
  local python_version="${uv_env[python_version]}"

  # Create/update the virtual environment using uv
  _fail_if_not_installed uv 'Please install uv (https://github.com/astral-sh/uv)"'

  _debug "Ensuring venv exists at $venv_path..."
  if ! uv venv --python "${python_version}" --quiet "$venv_path"; then
    _fail "Error: Failed to create or validate venv at $venv_path using uv."
  fi
  if [[ -f ${pip_requirements_file} ]]; then
    _debug "Installing dependencies:"
    # Install all requirements at once using uv, targeting the venv's Python
    local python_in_venv="$venv_path/bin/python"
    if [[ ! -x $python_in_venv ]]; then
      _error "Error: Python executable not found or not executable in venv: $python_in_venv"
      _warn "Warning: Skipping dependency installation."
    elif ! uv pip install --quiet --python "$python_in_venv" -r "${pip_requirements_file}"; then
      _warn "Warning: Failed to install some/all dependencies into $venv_path using 'uv pip install --python ...' from '${pip_requirements_file}'"
      # Decide if this should be a fatal error. For now, a warning.
    else
      _debug "Dependencies installed/updated successfully."
    fi
  else
    _debug "No 'require:' lines found in script header. Skipping dependency installation."
  fi

  # activate env
  source "$venv_path/bin/activate"

  _debug "Invoking in python uv venv: $*"
  # finally run it
  "$@"
}

__tm::venv::__invoke_in_python_venv() {
  local -n uv_env="$1" # associative array
  shift
  local venv_path="${uv_env[venv_path]}"
  local pip_requirements_file="${uv_env[pip_requirements_file]:-}"

  _debug "invoking via python venv ($venv_path)"

  if [[ ! -f "$venv_path/bin/activate" ]]; then
    _debug "no venv, creating '$venv_path'"
    python3 -m venv "$venv_path"
    source "$venv_path/bin/activate"
    # python3 -m pip install --upgrade pip
    # python3 -m pip --version
    whereis python
    _debug "ensuring pip installed"
    python -m ensurepip --upgrade
    #python pip install --upgrade pip
    python -m pip --version
  else
    source "$venv_path/bin/activate"
  fi
  if [[ -f ${pip_requirements_file} ]]; then
    _debug "Installing pip dependencies:"
    # Install all requirements at once using uv, targeting the venv's Python
    if ! python -m pip install -r "${pip_requirements_file}"; then
      _warn "Warning: Failed to install some/all dependencies into $venv_path using 'python3 -m pip install ...' from '${pip_requirements_file}'"
      # Decide if this should be a fatal error. For now, a warning.
    else
      _debug "Dependencies installed/updated successfully."
    fi
  fi
  _debug "invoking in python venv: $*"
  "$@"
}

__tm::venv::__invoke_in_docker() {
  local -n uv_env="$1" # associative array
  local script_runner="$2"
  local script_path="$3"
  shift 3

  local default_container="???"

  local venv_path="${uv_env[venv_path]}"
  local venv_provider="${uv_env[venv_provider]}"
  local pip_requirements_file="${uv_env[pip_requirements_file]:-}"
  local docker_container="${uv_env[docker_container]:-"${default_container}"}"
  local docker_file="${uv_env[docker_file]:-}"
  #local script_runner="${uv_env[script_runner]}"

  local plugin_id="${TM_PLUGIN_ID:-${__TM_PLUGIN_ID}}"
  local -A plugin
  _tm::parse::plugin_id plugin

  mkdir -p "${venv_path}"
  if [[ -n ${docker_file} ]]; then
    _debug "using docker file '${docker_file}'"

    local env_dockerfile="${venv_path}/Dockerfile"
    docker_container="tm-runner-$(echo "${venv_path}" | md5sum | awk '{print $1}')"

    if [[ ! -f ${env_dockerfile} ]]; then
      cp "${docker_file}" "${env_dockerfile}"
      _pushd "${venv_path}"
      # todo: or select podman
      docker build "${env_dockerfile}" -t "${docker_container}"
      _popd
    fi
  else
    _debug "using docker container '${docker_container}'"
    docker pull "${docker_container}"
  fi

  # todo: handle script runner

  local docker_args="run --rm"
  # file mounts
  docker_args+=" -v '${script_path}:/run/script:ro'"
  docker_args+=" -v '${TM_HOME}:/run/tm-home:ro'"
  docker_args+=" -v '${TM_PLUGIN_HOME}:/run/plugin-home:ro'"
  docker_args+=" -v '${TM_PLUGIN_CFG_DIR}:/run/plugin-cfg:ro'"
  docker_args+=" -v '${HOME}:/run/user-home:ro'"
  # env variables
  docker_args+=" -e HOME='/run/user-home:ro'"
  docker_args+=" -e TM_HOME='/run/tm-home:ro'"
  docker_args+=" -e TM_PLUGIN_ID='${plugin_id}'"
  docker_args+=" -e TM_PLUGIN_HOME='/run/plugin-home'"
  docker_args+=" -e TM_PLUGIN_CFG_DIR='/run/plugin-cfg'"
  # what to run
  docker_args+=" ${docker_container} ${script_runner} /run/script $@"

  _trace "Running docker ${docker_args}"
  eval "docker ${docker_args}"
}

__tm::venv::__invoke_in_docker_venv() {
  local -n uv_env="$1" # associative array
  shift
  local dockerfile="${uv_env[dockerfile]:-}"

  _fail "not currently implemented"
}
