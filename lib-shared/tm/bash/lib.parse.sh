#
# Library to provide various parsing util methods
#

if command -v _tm::parse::plugin &>/dev/null; then
  return
fi

#
# Parse git URL. Supports URLs for GitHub, GitLab, and Bitbucket.
# URLs can be of the form 'git@host.com:...' or 'http[s]://host.com/....'.
# The version can be set by appending '#<version>' or '@<version>' to the end, e.g., '#main'.
#
# Arguments
#  $1 - associative array to put the results in
#  $2 - the git URL
#
# Populates the associative array with the following keys:
#   - `url`: The cleaned 'git@host.com:owner/name.git' URL.
#   - `web_url`: The cleaned 'https://host.com/owner/name' URL.
#   - `owner`: The repository owner (GitHub), namespace (GitLab), or workspace (Bitbucket).
#   - `name`: The repository name.
#   - `repo`: The repository name with '.git' suffix.
#   - `version`: The version to checkout. Blank if not set or to use the default.
#   - `host`: The detected git host (e.g., 'github.com', 'gitlab.com', 'bitbucket.org').
#
_tm::parse::git_url(){
  local -n repo_info="$1"
  local git_url="$(echo "$2" | xargs)" # Trim leading/trailing whitespace
  repo_info=() #clear the data

  local host=""
  local lower_git_url="${git_url,,}" # Convert to lowercase for host matching
  if [[ "$lower_git_url" =~ "github.com" ]]; then
    host="github.com"
  elif [[ "$lower_git_url" =~ "gitlab.com" ]]; then
    host="gitlab.com"
  elif [[ "$lower_git_url" =~ "bitbucket.org" ]]; then
    host="bitbucket.org"
  else
    _fail "Unsupported git host in URL: $git_url"
  fi

  # Use lower_git_url for sed to handle case-insensitivity
  local path_with_version="$(echo "$lower_git_url" | sed -E "s|.*${host}[:/]?||")" # Remove host part, keep .git and version
  local path_without_version=""
  local repo_name version owner

  # Extract version if present using regex
  local temp_repo_name_part="${path_with_version}"
  version="" # Initialize version to empty

  # Extract version if present using regex
  local temp_repo_name_part="${path_with_version}"
  version="" # Initialize version to empty

  if [[ "${temp_repo_name_part}" =~ ^(.*)[#@](.*)$ ]]; then
    path_without_version="${BASH_REMATCH[1]}"
    version="${BASH_REMATCH[2]}"
  else
    path_without_version="${temp_repo_name_part}"
  fi

  # Remove .git suffix from path_without_version if present
  path_without_version="${path_without_version%.git}"

  # Ensure path_without_version does not contain any version separators
  path_without_version="${path_without_version%%[#@]*}"

  # Extract repo_name and owner from the path without version
  repo_name="${path_without_version##*/}"
  if [[ "$path_without_version" == *"/"* ]]; then
    owner="${path_without_version%/*}"
  else
    owner="" # No owner if no slash
  fi

  if [[ -z "$owner" ]]; then
    _fail "Git URL must contain an owner/namespace/workspace: $git_url"
  fi

  if [[ -z "$repo_name" ]]; then
    _fail "Git URL must contain a repository name: $git_url"
  fi

  # Construct the output URLs and fields
  local git_clone_path=""
  if [[ -n "$owner" ]]; then
    git_clone_path="${owner}/${repo_name}"
  else
    git_clone_path="${repo_name}"
  fi

  repo_info[url]="git@${host}:${git_clone_path}.git"
  repo_info[web_url]="https://${host}/${git_clone_path}"
  repo_info[owner]="${owner}"
  repo_info[repo]="${repo_name}.git"
  repo_info[name]="${repo_name}"
  repo_info[version]="${version}"
  repo_info[host]="${host}"
}


#
# _tm::parse::plugin
#
# Parses a plugin identifier string (either a qualified name or a full ID) into an
# associative array containing its components (vendor, name, version, prefix, etc.).
# This function acts as a dispatcher, calling either `_tm::parse::plugin_id`
# or `_tm::parse::plugin_name` based on the format of the input string.
#
# Arguments:
#   $1 - result_array_name: The name of the associative array to populate with parsed plugin details.
#   $2 - plugin_identifier: The string to parse. This can be:
#                           - A full plugin ID (e.g., "tm:plugin:<vendor>:<name>:<version>:<prefix>")
#                           - A qualified plugin name (e.g., "prefix:bar", "vendor/bar@123", "prefix__bar")
#
# Populates the `result_array_name` with the following keys:
#   - `vendor`: The plugin's vendor.
#   - `name`: The plugin's base name.
#   - `version`: The plugin's version.
#   - `prefix`: The plugin's prefix.
#   - `qname`: The qualified name (e.g., "prefix:vendor/name@version").
#   - `qpath`: The qualified file system path segment (e.g., "vendor/name__prefix").
#   - `key`: A unique key for caching.
#   - `id`: The full plugin ID string.
#   - `install_dir`: The absolute path to the plugin's installation directory.
#   - `enabled_dir`: The absolute path to the plugin's enabled symlink directory.
#   - `cfg_spec`: Path to the plugin's configuration specification file.
#   - `cfg_dir`: Path to the plugin's configuration directory.
#   - `cfg_sh`: Path to the plugin's merged shell configuration file (to apply all the config)
#   - `state_dir`: Path to the plugin's state dir (where it can save persistent state)
#   - `cache_dir`: Path to the plugin's cache dir (where it can save cached data)
#   - `packages_dir`: Path to the plugin's packages dir (where it can install things to)
#   - `tm`: Boolean, true if this is the tool-manager plugin itself.
#
# Usage:
#   declare -A my_plugin_info
#   _tm::parse::plugin my_plugin_info "myvendor/myplugin@1.0.0__myprefix"
#   _tm::parse::plugin my_plugin_info "tm:plugin:myvendor:myplugin:1.0.0:myprefix"
#
_tm::parse::plugin(){
  _finest "_tm::parse::plugin: '$2'"
  if [[ "$2" == "tm:plugin:"* ]]; then
    _tm::parse::plugin_id "$@"
  else
    _tm::parse::plugin_name "$@"
  fi
}

#
# Parse a qualified plugin name into an associative array
#
# Arguments:
# $1 - the name of the associative array to put the results in
# $2 - the plugin name
#
# Usage:
#  _tm::parse::plugin_name parts "prefix:bar"
#  _tm::parse::plugin_name parts "prefix:vendor/bar@123"
#  _tm::parse::plugin_name parts "prefix__bar"
_tm::parse::plugin_name(){
  local -n result_ref="$1" # expect it to be an associative array
  result_ref=()
  local parse_name="$2"
  _finest "_tm::parse::plugin_name: '$parse_name'"

  local prefix name version vendor
  prefix=''
  name=''
  version=''
  vendor=''
  # Determine the separator used in the plugin name to correctly parse it.
  # The order of checks is important: first check for the primary prefix-name separator,
  # then the directory-based separator.
  if [[ "$parse_name" == *"$__TM_SEP_PREFIX_NAME"* ]]; then
    IFS="$__TM_SEP_PREFIX_NAME" read -r prefix name <<< "$parse_name"
  elif [[ "$parse_name" == *"$__TM_SEP_PREFIX_DIR"* ]]; then
    IFS="$__TM_SEP_PREFIX_DIR" read -r prefix name <<< "$parse_name"
    # If the directory separator was used, and the name starts with an underscore,
    # remove that underscore. This handles a specific naming convention.
    if [[ "$name" == '_'* ]]; then
      name="${name##_}"
    fi
  else
    # If no prefix separator is found, the entire string is considered the name,
    # and there is no prefix.
    name="$parse_name"
    prefix=""
  fi

  # If after parsing, the 'name' is empty, it means the original 'prefix' was
  # actually the name, and there was no prefix.
  if [[ -z "$name" ]]; then
    _fail "Invalid plugin name format. Missing name after prefix separator. From input name '${parse_name}'"
  fi

  # Check for vendor information (indicated by a slash '/').
  # If found, split into vendor and name.
  if [[ "$name" == *'/'* ]]; then
    IFS="/" read -r vendor name <<< "$name"
    if [[ -z "$name" ]]; then
      _fail "Invalid plugin name format. Missing name after vendor slash. From input name '${parse_name}'"
    fi
  fi

  # Check for version information (indicated by an '@' symbol).
  # If found, split into name and version.
  if [[ "$name" == *'@'* ]]; then
    IFS="@" read -r name version <<< "$name"
    if [[ -z "$name" ]]; then
      _fail "Invalid plugin name format. Missing name after version '@'. From input name '${parse_name}'"
    fi
  fi

  if [[ -z "$name" ]]; then
    _fail "Invalid plugin name format. Is empty. From input name'${parse_name}'"
  fi

  # Validate name, vendor, and version formats
  # Name: Must start with a lowercase letter or number, followed by lowercase letters, numbers, or hyphens.
  if [[ -n "$name" && ! "$name" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
    _fail "Invalid plugin name format. Use lowercase letters, numbers, hyphens. Start with letter/number. Instead got '${name}' from input '${parse_name}'"
  fi

  # Vendor: Must start with a @ or lowercase letter or number, followed by lowercase letters, numbers, or hyphens.
  if [[ -n "$vendor" && ! "$vendor" =~ ^[@a-z0-9][a-z0-9-]*$ ]]; then
    _fail "Invalid plugin vendor format. Use lowercase letters, numbers, hyphens. Start with @/letter/number. Instead got '${vendor}' from input '${parse_name}'"
  fi

  # Version: Must start with a lowercase letter or number, followed by lowercase letters, numbers, hyphens, or dots.
  if [[ -n "$version" && ! "$version" =~ ^[a-z0-9][a-z0-9.-]*$ ]]; then
    _fail "Invalid plugin version format. Use lowercase letters, numbers, hyphens, dots. Start with letter/number. Instead got '${version}' from input '${parse_name}'"
  fi

  result_ref[vendor]="$vendor"
  result_ref[name]="$name"
  result_ref[version]="$version"
  result_ref[prefix]="$prefix"

  # Call derived vars AFTER all validation checks
  _tm::parse::__set_plugin_derived_vars result_ref

  _is_finest && _finest "parsed to $(_tm::util::array::print result_ref)" || true
}


# Parses a plugin id string into an associative array
#
# Arguments:
# $1 - the name of the associative array to put the results in
# $2 - the plugin id
#
# Behavior:
#   Parses a plugin id string into an associative array.
#
# Usage:
#  _tm::parse::plugin_id parts "tm:plugin:<space>:<vendor>:<name>:<version>:<prefix>"
#
_tm::parse::plugin_id(){
  local -n result_ref="$1" # expect it to be an associative array
  result_ref=()
  local parse_id="$2"
  _finest "_tm::parse::plugin_id: '$parse_id'"
  # Read the id into an array, respecting empty fields
  local -a id_parts=()
  IFS=':' read -r -a id_parts <<< "$parse_id"

  if [[ "${id_parts[0]:-}" != "tm" ]]; then
    _fail "Not a valid plugin id. expected 'tm:plugin:<space>:<vendor>:<name>:<version>:<prefix>', but got '$parse_id'"
  fi
  if [[ "${id_parts[1]:-}" != "plugin" ]]; then
    _fail "Not a valid plugin id. expected 'tm:plugin:<space>:<vendor>:<name>:<version>:<prefix>', but got '$parse_id'"
  fi
  local space="${id_parts[2]:-}"
  local vendor="${id_parts[3]:-}"
  local name="${id_parts[4]}"
  local version="${id_parts[5]:-}"
  local prefix="${id_parts[6]:-}"
  result_ref[space]="$space" # Fix: Set space in result_ref

  if [[ -z "$name" ]]; then
    _fail "Invalid plugin name format. Is empty. From id '${parse_id}'"
  fi

  # Validate name, vendor, and version formats
  # Name: Must start with a lowercase letter or number, followed by lowercase letters, numbers, or hyphens.
  if [[ -n "$name" && ! "$name" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
    _fail "Invalid plugin name format. Use lowercase letters, numbers, hyphens. Start with letter/number. Instead got '${name}' from id '${parse_id}'"
  fi

  # Vendor: Must start with a lowercase letter or number, followed by lowercase letters, numbers, hyphens or dots.
  if [[ -n "$vendor" && ! "$vendor" =~ ^[a-z0-9][\.a-z0-9-]*$ ]]; then
    _fail "Invalid plugin vendor format. Use lowercase letters, numbers, hyphens. Start with letter/number. Instead got '${vendor}' from id '${parse_id}'"
  fi

  # Version: Must start with a lowercase letter or number, followed by lowercase letters, numbers, hyphens, or dots.
  if [[ -n "$version" && ! "$version" =~ ^[a-z0-9][a-z0-9.-]*$ ]]; then
    _fail "Invalid plugin version format. Use lowercase letters, numbers, hyphens, dots. Start with letter/number. Instead got '${version}' from id '${parse_id}'"
  fi

  result_ref[vendor]="$vendor"
  result_ref[name]="$name"
  result_ref[version]="$version"
  result_ref[prefix]="$prefix"

  _tm::parse::__set_plugin_derived_vars result_ref

  _is_finest && _finest "$(_tm::util::array::print result_ref)" || true
}


#
# Parse the qpath into a plugin associative array
#
# Arguments:
# $1 - the plugin associative array
# $2 - the qpath (qualified path)
#
_tm::parse::plugin_enabled_dir(){
  local -n result_ref="$1" # expect it to be an associative array
  result_ref=()

  local dir_name="$2"
  # IFD can't do multiple chars, so convert '__' to newlines and then parse
  # the format is vendor__name__prefix, where prefix is optional
   IFS=$'\n' read -d '' -r vendor name prefix <<< "${dir_name//__/$'\n'}" || true

  # The version is not part of the enabled directory name, so it should be empty
  local version=""

  result_ref[vendor]="$vendor"
  result_ref[name]="$name"
  result_ref[version]="$version"
  result_ref[prefix]="$prefix"

  _tm::parse::__set_plugin_derived_vars result_ref

  _is_finest && _finest "$(_tm::util::array::print result_ref)" || true
}

#
# Set the calculated derived array variables
#
# Arguments:
# $1 - the plugin associative array
#
_tm::parse::__set_plugin_derived_vars(){
  local -n result_ref_derived="$1" # expect it to be an associative array

  local name="${result_ref_derived[name]}"
  local prefix="${result_ref_derived[prefix]}"
  local vendor="${result_ref_derived[vendor]}"
  local space="${result_ref_derived[space]:-}"
  local version="${result_ref_derived[version]:-}" # Added version here for key calculation

    # qname (qualified name)
  local qname=""
  if [[ -n "$prefix" ]]; then
    qname+="${prefix}:"
  fi
  if [[ -n "$vendor" ]]; then
    qname+="${vendor}/"
  fi
  qname+="${name}"
  if [[ -n "$version" ]]; then
    qname+="@${version}"
  fi
  result_ref_derived[qname]="$qname"

  # qpath (qualified file system path)
  local qpath
  if [[ "${name}" == "$__TM_NAME" ]] && [[ -z "${vendor:-}" ]]; then
    result_ref_derived[is_tm]=true
    result_ref_derived[qname]="$__TM_NAME"
    result_ref_derived[key]="$__TM_NAME"
    result_ref_derived[enabled_dir]="$TM_HOME"
    result_ref_derived[install_dir]="$TM_HOME"
    result_ref_derived[enabled_conf]="$TM_STATE_DIR/tool-manager/self.enabled.conf" # something, not used
    result_ref_derived[install_conf]="$TM_STATE_DIR/tool-manager/self.installed.conf" # something, not used
    result_ref_derived[qpath_flat]="tool-manager"
    qpath="$__TM_NAME"
  else
    result_ref_derived[is_tm]=false
    qpath="${vendor:-${__TM_NO_VENDOR}}/${name}"
    if [[ -n "${prefix}" ]]; then
      qpath+="__${prefix}"
    fi
    local qpath_flat="${vendor:-${__TM_NO_VENDOR}}__${name}"
    if [[ -n "${prefix}" ]]; then
      qpath_flat+="__${prefix}"
    fi
    result_ref_derived[qpath_flat]="${qpath_flat}"
    result_ref_derived[enabled_dir]="$TM_PLUGINS_ENABLED_DIR/${qpath_flat}"
    result_ref_derived[enabled_conf]="$TM_PLUGINS_ENABLED_DIR/${qpath_flat}.conf"
    result_ref_derived[install_conf]="$TM_PLUGINS_INSTALLED_CONF_DIR/${qpath_flat}.conf"
    result_ref_derived[install_dir]="$TM_PLUGINS_INSTALL_DIR/${vendor:-${__TM_NO_VENDOR}}/${name}"

    # a key which can be used for caching things
    local key=""
    if [[ -n "$vendor" ]]; then
      key+="${vendor}__"
    else
      key+="${__TM_NO_VENDOR}__"
    fi
    key+="${name}"
    if [[ -n ${version} ]]; then
      key+="__v${version}"
    else
      key+="__vmain"
    fi
    if [[ -n "$prefix" ]]; then
      key+="__${prefix}"
    fi
    result_ref_derived[key]="$key"
  fi
  result_ref_derived[qpath]="$qpath"

  result_ref_derived[id]="tm:plugin:$space:$vendor:$name:$version:$prefix"

  result_ref_derived[cfg_spec]="${result_ref_derived[install_dir]}/plugin.cfg.yaml"
  result_ref_derived[cfg_dir]="$TM_PLUGINS_CFG_DIR/${qpath}"
  result_ref_derived[cfg_sh]="$TM_PLUGINS_CFG_DIR/${qpath}/config.sh" # plugin specific main config file
  result_ref_derived[state_dir]="$TM_PLUGINS_STATE_DIR/${qpath}" # where the plugin should store persistent state
  result_ref_derived[cache_dir]="$TM_PLUGINS_CACHE_DIR/${qpath}" # the plugins cache dir, for data that can be lost and regenerated
  result_ref_derived[packages_dir]="$TM_PLUGINS_PACKAGES_DIR/${qpath}" # where to install plugin specific deps/progs
}

_to_boolean(){
  _tm::parse::boolean "${1:-}"
}
#
# Convert a boolean value to 1 or 0
#
# Arguments:
# $1 - the value to parse. Case insensitive. Converts true|t|yes|enabled|1|yeah into '1', '0' in all other cases
#
_tm::parse::boolean(){
  local value="${1:-}}"
  case "${value,,}" in # bash lowercase
    true|t|1|yes|enabled|yeah|yeah-but-nah)
        echo "1";;
    *)
      echo "0";;
  esac
}
