#
# bin/.tm.plugins.sh
#
# This script provides functions for managing collections of Tool Manager plugins.
# Responsibilities include:
#   - Loading all enabled plugins (_tm::plugins::load_all_enabled).
#   - Reloading plugin configurations (_tm::plugins::reload_all_enabled).
#   - Finding all enabled or installed plugins.
#   - Installing new plugins from INI file definitions (_tm::plugins::install).
#   - Iterating over available plugins defined in INI files (_tm::plugins::__available_foreach_call).
# It depends on .tm.util.sh for INI parsing and .tm.plugin.sh for individual plugin operations.
#

_tm::source::include_once @tm/lib.file.ini.sh
_tm::source::once "$TM_BIN/.tm.plugin.sh" "$TM_BIN/.tm.venv.directives.sh"

#
# _tm::plugins::regenerate_all_wrapper_scripts
#
# Regenerates all wrapper scripts for currently enabled plugins.
# This involves removing existing wrappers and then creating new ones for each enabled plugin.
#
# Usage:
#   _tm::plugins::regenerate_all_wrapper_scripts
#
_tm::plugins::regenerate_all_wrapper_scripts() {
  _info "Regenerating plugin wrapper scripts..."
  _tm::plugins::remove_all_wrappers

  local -a plugin_ids
  mapfile -t plugin_ids < <(_tm::plugins::find_all_enabled_plugin_ids)
  local -A parsed_plugin
  for plugin_id in "${plugin_ids[@]}"; do
    #_info "plugin_id=$plugin_id"
    _tm::parse::plugin_id parsed_plugin "$plugin_id"
    _tm::plugin::regenerate_wrapper_scripts parsed_plugin
  done

  _info "...wrapper scripts regenerated"
}

# Reloads all enabled plugins by resetting the loaded flag,
# removing all plugin command wrappers, and then loading them again.
_tm::plugins::reload_all_enabled() {
  __TM_PLUGINS_LOADED=0
  _tm::plugins::remove_all_wrappers
  _tm::plugins::load_all_enabled
}

# Loads all enabled plugins.
# Ensures the main tool-manager plugin ($TM_HOME) is loaded first.
# Uses __TM_PLUGINS_LOADED flag to ensure plugins are loaded only once per session/reload.
_tm::plugins::load_all_enabled() {

  # # the tools plugin must always be the first to load, as other plugins might depend on it
  # # It should only be loaded once, so trying again later results in a no-op
  # _tm::plugin::load "$TM_HOME"

  local -a plugins_enabled_dirs
  mapfile -t plugins_enabled_dirs < <(_tm::plugins::find_all_enabled_dirs)

  local enabled_dir
  local -A enabled_plugin
  for enabled_dir in "${plugins_enabled_dirs[@]}"; do
    _trace "loading from enabled dir: '${enabled_dir}'"
    _tm::parse::plugin_enabled_dir enabled_plugin "$(basename "$enabled_dir")"
    _tm::plugin::load enabled_plugin || _warn "Couldn't load plugin '${enabled_plugin[qname]}'"
  done
  export PATH
  _trace "PATH=$PATH"
}

# Removes the entire directory containing plugin command wrapper scripts ($TM_PLUGINS_BIN_DIR).
# This is typically done before regenerating them during a reload.
_tm::plugins::remove_all_wrappers() {
  # TODO: check not root or home dir or something
  if [[ -d $TM_PLUGINS_BIN_DIR ]]; then
    rm -rf "$TM_PLUGINS_BIN_DIR"
  fi
}

# Recursively find all executable scripts in a directory that match an optional filter
#
# This will ignore any 'hidden' dir starting with '.', though the passed in dir can be a hidden one
#
# Arguments:
#   $1 - Optional command name filter (prefix)
#
# Usage:
#   _tm::plugins::find_all_scripts "prefix_filter"
#
# Output:
#   List of matching script files, one per line
_tm::plugins::find_all_scripts() {
  local plugin_dirs
  plugin_dirs="$(_tm::plugins::find_all_enabled_dirs)"

  local scripts
  local file
  local plugin_dir

  scripts="$(_tm::plugin::__find_scripts_in "$TM_HOME/bin")"
  for file in $scripts; do
    echo "$file"
  done

  for plugin_dir in $plugin_dirs; do
    _debug "finding scripts in $plugin_dir"
    scripts="$(_tm::plugin::__find_scripts_in "$plugin_dir/bin")"
    for file in $scripts; do
      echo "$file"
    done
  done
}

_tm::plugins::find_all_disabled_plugin_ids() {
  local -a ids
  _tm::plugins::find_all_installed_plugin_ids ids

  local -a enabled_ids
  _tm::plugins::find_all_enabled_plugin_ids enabled_ids

  # remove the enabled ones
  for id in "${ids[@]}"; do
    unset ids[id]
  done
  for id in "${ids[@]}"; do
    echo "$id"
  done
}
#
# Return all the enabled plugin ids
#
_tm::plugins::find_all_enabled_plugin_ids() {
  local -a plugins_enabled_dirs
  mapfile -t plugins_enabled_dirs < <(_tm::plugins::find_all_enabled_dirs | sort)
  #_trace "plugins_enabled_dirs=${plugins_enabled_dirs[@]}"
  local enabled_dir
  local -A plugin_details
  for enabled_dir in "${plugins_enabled_dirs[@]}"; do
    _tm::parse::plugin_enabled_dir plugin_details "$(basename "$enabled_dir")"
    echo "${plugin_details[id]}"
  done
}

#
# Return all the plugin dirs that are enabled
#
_tm::plugins::find_all_enabled_dirs() {
  _debug "Looking for plugins in: '$TM_PLUGINS_ENABLED_DIR'"
  find "$TM_PLUGINS_ENABLED_DIR" -maxdepth 1 -mindepth 1 -type l \( -name ".*" -prune -o -print \) | sort
}

_tm::plugins::find_all_installed_plugin_ids() {
  local -a dirs=()
  mapfile -t dirs < <(_tm::plugins::find_all_installed_dirs)
  #_trace "plugins_enabled_dirs=${plugins_enabled_dirs[@]}"
  local installed_dir vendor name
  local -a parts=()
  local -A plugin_details
  for dir in "${dirs[@]}"; do
    IFS="/" read -r -a parts <<<"$(echo "$dir")"
    vendor="${parts[-2]}"
    name="${parts[-1]}"
    _tm::parse::plugin_name plugin_details "${vendor}/${name}"
    echo "${plugin_details[id]}"
  done
}

#
# Return all the installed plugin dirs
#
_tm::plugins::find_all_installed_dirs() {
  # TODO: convert to plugin ids
  find "$TM_PLUGINS_INSTALL_DIR" -maxdepth 2 -mindepth 2 -type d \( -name ".*" -prune -o -print \) | sort
}

#
# List all the available plugin ids
#
_tm::plugins::find_all_available_plugin_ids() {
  # TODO: scan the plugin files
  _todo "find available plugin ids"
  local -a plugin_conf_files=()
  _tm::plugins::__plugin_files_to_array plugin_conf_files

  if [[ ${#plugin_conf_files[@]} -eq 0 ]]; then
    _warn "No plugin install files found"
    return 1
  fi

  local conf_file
  declare -A plugin_details # plugin dtails from the ini file
  declare -A plugin         # plugin details from the parsed name

  for conf_file in "${plugin_conf_files[@]}"; do
    if [[ ! -f $conf_file || ! -r $conf_file ]]; then
      _warn "INI file not found or not readable: '$conf_file'. Skipping"
      continue
    fi

    local section_names_in_file=()
    _tm::file::ini::read_sections section_names_in_file "$conf_file"

    for vendor_slash_name in "${section_names_in_file[@]}"; do
      plugin_details=() # Clear for each section
      _tm::file::ini::read_section plugin_details "$conf_file" "$vendor_slash_name"
      if [[ -n ${plugin_details[repo]} ]]; then
        _tm::parse::plugin_name plugin "$vendor_slash_name"
        echo "${plugin[id]}"
      else
        _warn "Plugin '$vendor_slash_name' in '$conf_file' is missing the 'repo' attribute. Skipping"
      fi
    done
  done
}

# --- Get all unique plugin 'dir' values from all INI files ---
# This function reads all configured plugin INI files, extracts the 'dir'
# attribute from every plugin section, and outputs a unique, sorted list
# of these directory names. These names are relative to $TM_PLUGINS_INSTALL_DIR.
#
# Output:
#   A newline-separated list of unique plugin directory names.
#
# Example usage in another script:
#   local available_dirs
#   mapfile -t available_dirs < <(_tm::plugins::__get_all_available_dirs)
#   for dir_name in "${available_dirs[@]}"; do
#     echo "Available plugin dir: $TM_PLUGINS_INSTALL_DIR/$dir_name"
#   done
#
_tm::plugins::__get_all_available_dirs() {
  local plugin_files_array=()
  _tm::plugins::__plugin_files_to_array plugin_files_array

  if [[ ${#plugin_files_array[@]} -eq 0 ]]; then
    _warn "Cannot find available plugin dirs."
    return 1
  fi

  local all_dirs=()
  local conf_file
  local plugin_name
  declare -A plugin_details

  for conf_file in "${plugin_files_array[@]}"; do
    if [[ ! -f $conf_file || ! -r $conf_file ]]; then
      _warn "INI file not found or not readable: '$conf_file'. Skipping for available dirs."
      continue
    fi

    local section_names_in_file=()
    _tm::file::ini::read_sections section_names_in_file "$conf_file"

    for vendor_slash_name in "${section_names_in_file[@]}"; do
      plugin_details=() # Clear for each section
      _tm::file::ini::read_section plugin_details "$conf_file" "$vendor_slash_name"
      if [[ -n ${plugin_details[repo]} ]]; then
        all_dirs+=("${TM_PLUGINS_INSTALL_DIR}/${vendor_slash_name}")
      else
        _warn "Plugin '$vendor_slash_name' in '$conf_file' is missing the 'repo' attribute.."
      fi
    done
  done

  # Output unique, sorted directory names
  if [[ ${#all_dirs[@]} -gt 0 ]]; then
    printf '%s\n' "${all_dirs[@]}" | sort -u
  fi
  return 0
}

# --- Reads the plugin files in TM_PLUGINS_REGISTRY_DIR  TM_PLUGINS_REGISTRY_DIR string into a specified array ---
# Arguments:
#   $1: Name of the array to populate (passed by reference)
#
_tm::plugins::__plugin_files_to_array() {
  if [[ -z $1 ]]; then
    _error "Usage: $FUNCNAME <array_name_ref>"
    return 1
  fi
  local -n _target_plugins_array="$1" # Use nameref for the output array
  # Use space and newline as delimiters
  # shellcheck disable=SC2226 # We want word splitting here for read -a
  readarray -d '' _target_plugins_array < <(_tm::plugins::find_conf_files)

  _is_trace && _trace "plugin ini files: [${_target_plugins_array[*]}]'" || true
}

_tm::plugins::find_conf_files() {
  # user provided one stakes precedence
  if [[ -n $TM_PLUGINS_REGISTRY_DIR ]] && [[ -d $TM_PLUGINS_REGISTRY_DIR ]]; then
    find "$TM_PLUGINS_REGISTRY_DIR" -type f -name "*.${__TM_CONF_EXT}" -print0 | sort -z
  fi
  if [[ -n $TM_PLUGINS_DEFAULT_REGISTRY_DIR ]] && [[ -d $TM_PLUGINS_DEFAULT_REGISTRY_DIR ]]; then
    find "$TM_PLUGINS_DEFAULT_REGISTRY_DIR" -type f -name "*.${__TM_CONF_EXT}" -print0 | sort -z
  fi
}

# _tm::plugins::uninstall
#
# Uninstalls a Tool Manager plugin. This involves disabling the plugin
# and then removing its installation directory.
#
# Arguments:
#   $1 - plugin_identifier: The identifier of the plugin to uninstall.
#                           This should be a qualified plugin name (e.g., "myplugin", "myns:myplugin").
#
# Returns:
#   0 if the plugin was successfully uninstalled or the user chose not to proceed.
#   1 if the uninstallation failed.
#
# Usage:
#   _tm::plugins::uninstall "myplugin"
#   _tm::plugins::uninstall "myns:myplugin"
#
_tm::plugins::uninstall() {
  local plugin="$1"

  _info "Uninstalling plugin '$plugin'"
  local -A plugin_to_disable
  _tm::parse::plugin plugin_to_disable "$plugin"

  local qname="${plugin_to_disable[qname]}"
  local plugin_dir="${plugin_to_disable[install_dir]}"
  local plugin_id="${plugin_to_disable[id]}"

  if [[ -d "${plugin_dir}/.git" ]]; then
    _info "plugin git status:"
    _pushd "$plugin_dir"
    git status || true
    _popd
  fi
  local yn=''
  if _confirm "Really uninstall plugin ${qname} in ${plugin_dir}?"; then
    _tm::event::fire "tm.plugin.uninstall.start" "${plugin_id}"

    if _tm::plugin::disable plugin_to_disable; then
      _info "Plugin '${qname}' disabled successfully."
    else
      _warn "Failed to disable plugin '${qname}'. Proceeding with directory removal."
    fi
    local install_conf="${plugin[install_conf]}"
    if [[ -f ${install_conf} ]]; then
      rm "${install_conf}" || _warn "Couldn't remove '${install_conf}'"
    fi
    if rm -fR "$plugin_dir"; then
      _info "Plugin directory '${plugin_dir}' removed successfully."
      _tm::event::fire "tm.plugin.uninstall.finish" "${plugin_id}"
      return 0
    else
      _error "Failed to remove plugin directory '${plugin_dir}'."
      _tm::event::fire "tm.plugin.uninstall.error" "${plugin_id}"
      return 1
    fi
  else
    _info "Not removing plugin '${qname}'."
    return 0
  fi
}

# _tm::plugins::install
#
# Installs a Tool Manager plugin. This function acts as a dispatcher, determining
# whether to install from a Git repository directly or from the configured plugin registry
# based on the format of the provided plugin identifier.
#
# Args:
#   $1 - plugin_identifier: The identifier of the plugin to install. This can be:
#                           - A Git repository URL (e.g., "git@github.com:user/repo.git", "https://github.com/user/repo")
#                           - A qualified plugin name (e.g., "myplugin", "myns:myplugin", "myplugin@v1.2")
#
# Behavior:
#   - If `plugin_identifier` starts with "git@", "https://github.com/", "http://github.com/", or "github.com/",
#     it delegates to `_tm::plugins::install_from_git`.
#   - Otherwise, it delegates to `_tm::plugins::install_from_registry`.
#   - Both delegated functions handle the actual installation, including cloning the repository
#     (if not already installed) and enabling the plugin.
#   - Prompts the user for confirmation before proceeding with the installation.
#
# Returns:
#   0 if the plugin was successfully installed or was already installed and enabled.
#   1 if the installation failed or the user chose not to proceed.
#   Exits the script via `_fail` if a critical error occurs during the installation process.
#
# Usage:
#   _tm::plugins::install "myplugin"
#   _tm::plugins::install "git@github.com:myorg/myplugin.git"
#
_tm::plugins::install() {
  local plugin_identifier="$1"
  _info "Attempting to install plugin: '$plugin_identifier'"
  if [[ $plugin_identifier == "git@"* ]] || [[ $plugin_identifier == "https://github.com/"* ]] || [[ $plugin_identifier == "http://github.com/"* ]] || [[ $plugin_identifier == "github.com/"* ]]; then
    _tm::plugins::install_from_git "$plugin_identifier"
  else
    _tm::plugins::install_from_registry "$plugin_identifier"
  fi
}

_tm::plugins::install_from_git() {
  local git_repo="$1"
  _trace "Installing from raw repo '$git_repo'"

  local -A repo
  _tm::parse::github_url repo "${git_repo}"

  # extract out the vendor path and use the package name as the plugin name
  local plugin_name="${repo[name]}"
  local vendor="${repo[owner]}"
  local version="${repo[version]}"
  git_repo="${repo[url]}"

  _debug "extracted plugin details: vendor '$vendor' plugin_name '$plugin_name' version '$version' repo '$git_repo'"

  local -A plugin_details
  _tm::parse::plugin_name plugin_details "${vendor}/${plugin_name}@${version}"

  local qname="${plugin_details[qname]}"
  local install_dir="${plugin_details[install_dir]}"

  if _confirm "really install '${qname}' into '${install_dir}' from '${git_repo}', version '${version}'?"; then
    if _tm::plugins::__clone_and_install plugin_details "${git_repo}" "${version}"; then
      _info "successfully installed"
      return $_true
    else
      _error "error installing plugin"
      return $_false
    fi
  else
    _info "skipping install"
    return $_false
  fi
}

#
# Install a plugin from the plugin registry
#
# $1 - the plugin name or id
#
_tm::plugins::install_from_registry() {
  local qualified_name="$1"

  if [[ -z $qualified_name ]]; then
    _error "Plugin name is required. Input: '$qualified_name'"
    return $_false
  fi

  local -A plugin=()
  _tm::parse::plugin plugin "$qualified_name"
  local plugin_name="${plugin[name]}"
  local prefix="${plugin[prefix]}"
  local vendor="${plugin[vendor]}"
  local version="${plugin[version]:-main}"
  local qname="${plugin[qname]}"
  local plugin_dir="${plugin[install_dir]}"
  # what section we are looking for
  local vendor_and_name="${vendor}/${plugin_name}"

  _info "Attempting to install plugin: vendor='${vendor}', name='${plugin_name}', version='${version}', prefix='${prefix:-none}' (from input '$qualified_name')"

  local -a plugin_files=()
  _tm::plugins::__plugin_files_to_array plugin_files

  local plugin_conf_file
  # TODO: read the registry files and cache the processed output
  # find the first matching plugin definition
  for plugin_conf_file in "${plugin_files[@]}"; do
    # Check if the INI file exists
    if [[ ! -f $plugin_conf_file ]]; then
      _warn "Plugin configuration file '$plugin_conf_file' not found."
      continue # read next file
    fi

    # Check if the plugin section exists in the INI file
    if ! _tm::file::ini::has_section "$plugin_conf_file" "$vendor_and_name"; then
      _debug "Plugin section '$plugin_name' not found in '$plugin_conf_file'."
      continue # next file
    fi

    _debug "Plugin section '$vendor_and_name' found in '$plugin_conf_file'."

    # Read plugin details from the INI file
    declare -A plugin_details
    if _tm::file::ini::read_section plugin_details "$plugin_conf_file" "$vendor_and_name"; then
      local plugin_cfg_repo="${plugin_details[repo]:-}"
      local plugin_cfg_commit="${plugin_details[commit]:-}" # Commit from INI is default
    else
      _error "Could not find plugin details in '$plugin_conf_file'"
      return $_false
    fi

    # If a version was specified in the input, it overrides the commit from INI
    if [[ -n $version ]]; then
      _debug "Using specified version '$version' to override INI commit ('${plugin_cfg_commit:-none}')."
      plugin_cfg_commit="$version"
    elif [[ -z $plugin_cfg_commit ]]; then # If no version in input AND no commit in INI
      _warn "No commit/branch/tag specified in INI for '$vendor_and_name' and no version in input. Defaulting to 'main' or 'master' if common, but git clone might fail or pick default."
    fi
    # local plugin_cfg_desc="${plugin_details[desc]}" # desc is available if needed
    if _tm::plugins::__clone_and_install plugin "${plugin_cfg_repo}" "${plugin_cfg_commit}"; then
      return $_true
    fi
  done
  _error "Could not install plugin '$plugin_name' (from input '$qualified_name')"
  return $_false
}

#
# $1 - plugin array
# $2 - repo
# $3 - commit

_tm::plugins::__clone_and_install() {
  local -n plugin_to_clone="$1"
  local repo="$2"
  local commit="${3:-main}"

  local plugin_name="${plugin_to_clone[name]}"
  local prefix="${plugin_to_clone[prefix]}"
  local vendor="${plugin_to_clone[vendor]}"
  local version="${plugin_to_clone[version]:-main}"
  local qname="${plugin_to_clone[qname]}"
  local plugin_dir="${plugin_to_clone[install_dir]}"
  local vendor_and_name="${vendor}/${plugin_name}"

  if [[ -d $plugin_dir ]]; then
    _info "plugin '$qname' is already installed in '$plugin_dir'"
    _info "ensuring it is enabled as '${qname}'..."
    if ! tm-plugin-enable --plugin "${qname}"; then
      _warn "Failed to ensure already installed plugin '$vendor_and_name' is enabled as '${qname}'."
    else
      _info "Plugin '${qname}' is installed and enabled."
    fi
    return 0 # Successfully handled (already installed)
  else
    _info "Installing plugin '$vendor_and_name' from '$repo' (commit/branch: '${commit}') to '$plugin_dir'"
    local clone_cmd="git clone"
    if [[ -n $commit ]]; then
      clone_cmd="$clone_cmd --branch \"$commit\""
    fi
    # Using eval for clone_cmd to correctly handle quoted branch name if it contains spaces (unlikely but possible)
    # However, direct expansion is safer if branch names are simple.
    # For simplicity and common case, direct expansion:
    if [[ -n $commit ]]; then
      git clone --branch "$commit" "$repo" "$plugin_dir"
    else
      git clone "$repo" "$plugin_dir" # Let Git use default branch
    fi

    if [[ $? -eq 0 ]]; then
      _info "Plugin '$plugin_name' installed successfully into '$plugin_dir'."
      local install_conf="${plugin_to_clone[install_conf]}"
      mkdir -p "$(dirname "$install_conf")"
      echo "install_date='$(date +'%Y-%m-%d.%H:%M:%S.%3N')'" >"$install_conf"
      echo "plugin_home='${plugin_dir}'" >>"$install_conf"
      echo "git_repo='${repo}'" >>"$install_conf"
      echo "git_commit='${commit}'" >>"$install_conf"
      echo "plugin_id='${plugin_to_clone[id]}'" >>"$install_conf"

      # Attempt to enable the plugin after successful installation using the original qualified name
      if _confirm "enable plugin? (no prefix)"; then
        if tm-plugin-enable "${qname}"; then # Use original full name for enabling
          _info "Plugin '${qname}' enabled successfully."
        else
          _warn "Plugin '${qname}' installed but failed to enable."
        fi
      else
        _info "Not enabling"
      fi
      return 0 # Successful installation
    else
      _error "Failed to clone plugin '$plugin_name' from '$repo' (commit/branch: '${commit}')."
      return 1
    fi
  fi
}

# Arguments:
#   $1: Name of the callback function to execute for each available plugin.
#       callback <plugin assoc array>
#
_tm::plugins::foreach_available_callback() {

  # --- Argument Parsing ---
  local -A args
  _parse_args \
    --help "${FUNCNAME[0]}: For each available plugin, invoke the given function with the plugin associative array" \
    --opt-match "|short=m|desc=the plugin name match" \
    --opt-default-commit "|short=c|default=main|desc=the default commit/branch to use if none provided" \
    --opt-function "|short=f|required|remainder|desc=the callback function" \
    --result args \
    -- "$@"

  local callback_func="${args[function]}"
  shift # next args are filter options

  local match_name="${args[match]:-}"
  local default_commit="${args[default - commit]}"

  local -a plugin_files=()
  _tm::plugins::__plugin_files_to_array plugin_files

  if [[ ${#plugin_files[@]} -eq 0 ]]; then
    _warn "No installable plugin files found"
    return 1
  fi

  _trace "Reading available plugins config..."
  _trace "Callback Function: $callback_func"
  _trace "Plugin registry files ${plugin_files[*]}"

  [[ -n $match_name ]] && _debug "Matching Plugin Name: '$match_name' (first occurrence)"
  _debug "Default branch/commit (if not specified in INI): $default_commit"

  declare -A plugin_section_details # Reusable associative array for plugin data
  declare -A plugin_details         # Reusable associative array for plugin data

  local __process_plugin_from_file
  __process_plugin_from_file() {
    local current_conf_file="$1"
    local current_plugin_name="$2"

    _tm::parse::plugin_name plugin_details "$current_plugin_name"
    _tm::file::ini::read_section plugin_section_details "$current_conf_file" "$current_plugin_name"

    local conf_repo="${plugin_section_details[repo]}"
    local conf_commit="${plugin_section_details[commit]}"
    local plugin_desc="${plugin_section_details[desc]}"
    local run_mode="${plugin_section_details[run - mode]:-direct}"

    if [[ -z $conf_commit ]]; then
      conf_commit="$default_commit"
    fi

    if [[ -z $conf_repo ]]; then
      _warn "Plugin '$current_plugin_name' from '$current_conf_file' has incomplete configuration (repo). Skipping."
      return
    fi

    # make the details from the config file available
    plugin_details[repo]="$conf_repo"
    plugin_details[commit]="$conf_commit"
    plugin_details[branch]="$conf_commit"
    plugin_details[desc]="$plugin_desc"
    plugin_details[run_mode]="$run_mode"

    _trace "Calling callback '$callback_func' for: '${plugin_details[qname]}' (dir: '${plugin_details[install_dir]}', repo: $conf_repo, commit: $conf_commit, desc: $plugin_desc)"
    "$callback_func" plugin_details
  }

  local found_match=0
  for conf_file in "${plugin_files[@]}"; do
    _debug "Processing config file: $conf_file"
    if [[ ! -f $conf_file || ! -r $conf_file ]]; then
      _warn "Config file not found or not readable: '$conf_file'. Skipping."
      continue
    fi

    if [[ -n $match_name ]]; then
      if _tm::file::ini::has_section "$conf_file" "$match_name"; then
        _debug "Found matched plugin '$match_name' in '$conf_file'."
        __process_plugin_from_file "$conf_file" "$match_name"
        found_match=1
        break # Stop after first match
      else
        _debug "No match for '$match_name' in '$conf_file'."
      fi
    else
      # No match name, process all plugins in this file
      declare -a all_plugin_names_in_file
      _tm::file::ini::read_sections all_plugin_names_in_file "$conf_file"
      _debug "Found ${#all_plugin_names_in_file[@]} plugins in '$conf_file'."
      for name_in_file in "${all_plugin_names_in_file[@]}"; do
        __process_plugin_from_file "$conf_file" "$name_in_file"
      done
    fi
  done

  if [[ -n $match_name && $found_match -eq 0 ]]; then
    _warn "Matched plugin '$match_name' not found in any of the specified configuration files."
  fi

  _debug "...finished reading plugins."
  return 0
}

#
# Find a plugin by name or match. An exact match is performed first, if nothing found, it will search
# for plugins with a matching name. Success if only one with the given name found, error if none, and user
# is prompted to choose if multiple matches
#
# Fails if no plugin could be found
#
# Arguments
# $1 - the plugin name (simple, qname, partial match)
#
# Returns the qname
#
_tm::plugins::installed::get_by_name() {
  _tm::plugins::__get_by_name "${1}" --installed
}

_tm::plugins::enabled::get_by_name() {
  _tm::plugins::__get_by_name "${1}" --enabled
}

_tm::plugins::__get_by_name() {
  local name="${1}"
  local find_args="${2}"

  local -A plugin
  _tm::parse::plugin plugin "$name"
  plugin_dir="${plugin[install_dir]}"
  if [[ ! -d $plugin_dir ]]; then
    local matches
    mapfile -t matches < <(tm-plugin-ls "${find_args}" --name --match "${name}" || true)

    num_matches="${#matches[@]}"
    case "${num_matches}" in
      "0")
        _fail "Could not find plugin matching *${name}*"
        ;;
      "1")
        _tm::parse::plugin plugin "${matches[*]}"
        if _confirm "Found plugin '${plugin[qname]}', is this correct?" 'y'; then
          echo "${plugin[qname]}"
        else
          _fail "Could not find plugin matching *${name}*"
        fi
        ;;
      *)
        _error "Multiple plugins matching name *${name}*. Found ${matches[*]}:"
        local num=0
        for match in "${matches[@]}"; do
          num=$((num + 1))
          >&2 echo "${num}. ${match}"
        done

        local max_num=$num
        while true; do
          local choice
          _read_not_empty "Which plugin? [1-${max_num}]" choice
          match="${matches[$((choice - 1))]:-}" || true
          if [[ ${choice} -gt 0 ]] && [[ ${choice} -le $max_num ]] && [[ -n ${match} ]]; then
            echo "${match}"
            return $_true
          else
            >&2 echo "invalid choice"
            choice=''
          fi
        done
        ;;
    esac
  else
    echo "${plugin[qname]}"
  fi
}
