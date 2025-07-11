
#[[ -n "${__TM_PLUGIN_CFG_SH_SOURCED:-}" ]] && return 0; export __TM_PLUGIN_CFG_SH_SOURCED=1;

# This script provides functions for getting and setting global/tm/user/plugin-specific
# configuration values. Configuration is typically stored in per-plugin
# '.env' files within the $TM_PLUGINS_CFG_DIR.
# Functions support reading, writing, and interactively prompting for
# configuration keys.
#

_tm::source::include @tm/lib.util.sh @tm/lib.file.env.sh

_tm::cfg::get_cfg_editor(){
  [[ -n "${1:-}" ]] && local default="$1" || true
  local editor="$(_tm::cfg::get --tm --key TM_CFG_EDITOR --default ${default:-${EDITOR:-code}} --no-prompt)"
  if [[ "$editor" == "" ]]; then
        editor="${default:-code}"
  fi
  _fail_if_not_installed "$editor" "No suitable editor found. Please set your \$TM_CFG_EDITOR environment variable or specify an editor command. Provided default '${1:-}'"

  echo -n "$editor"
}

_tm::cfg::get_editor(){
  # Gets the configured editor, defaulting to TM_DIR_EDITOR, EDITOR, or 'code'.
  # Usage: _tm::cfg::get_editor [default_editor]
  #   default_editor: Optional. The editor to use if TM_DIR_EDITOR and EDITOR are not set.
  #
  # Behavior:
  #   Gets the configured editor, defaulting to TM_DIR_EDITOR, EDITOR, or 'code'.
  #
  # Returns: The name of the editor to use.
    [[ -n "${1:-}" ]] && local default="$1" || true
    #local editor_cmd="${1:-}"
    # Gets the configuration editor
    local editor="$(_tm::cfg::get --tm --key TM_DIR_EDITOR --default ${default:-${EDITOR:-code}})"
  if [[ "$editor" == "" ]]; then
        editor="${default:-code}"
  fi
  # Determine the editor to use
#   if [[ -z "$editor_cmd" ]]; then
#    while IFS=' ' read -r possible; do
#     _debug "trying editor:$possible"
#     if command -v "$possible" &>/dev/null; then
#         editor_cmd="$possible"
#         break
#     fi
#     done  < <(echo "$possible_editors")
#   fi

  _fail_if_not_installed "$editor" "No suitable editor found. Please set your \$TM_DIR_EDITOR environment variable or specify an editor command. Provided default '${1:-}'"

  echo -n "$editor" 
}

# Ensure envsubst is available, or provide a warning
if ! command -v envsubst &> /dev/null; then
    _warn "Warning: 'envsubst' not found. Environment variables will not be expanded."
    _warn "         Please install it (e.g., sudo apt-get install gettext-tools)."
    _warn "         Falling back to literal values."
    # If envsubst is not available, we'll just print the raw values.
    # You might want to exit or handle this differently based on your needs.
    ENV_SUBST_CMD="cat" # Use cat as a fallback to just pass through the raw string
else
    ENV_SUBST_CMD="envsubst"
fi

_tm::cfg2::plugin_init(){
  local cfg_file="$1"
  local expanded_default_val expanded_note_val
  _tm::prog::yq '.keys | to_entries[] | [.key, .value.default, .value.note, .value.required, .value.type] | @tsv' "$cfg_file" -r | \
  while IFS=$'\t' read -r key_name raw_default_val raw_note_val raw_required_val raw_type_val; do
    # Apply envsubst to the values that might contain environment variables
    expanded_default_val=$(echo "$raw_default_val" | $ENV_SUBST_CMD)
    expanded_note_val=$(echo "$raw_note_val" | $ENV_SUBST_CMD)

    if _is_trace; then
      _trace "--- Key: $key_name ---"
      _trace "  Raw Default:      $raw_default_val"
      _trace "  Expanded Default: $expanded_default_val"
      _trace "  Raw Note:         $raw_note_val"
      _trace "  Expanded Note:    $expanded_note_val"
      _trace "  Required:         $raw_required_val"
      _trace "  Type:             $raw_type_val"
      _trace ""
    fi
    _env_cfg_key --this --key "$key_name" --default "$expanded_default_val" --note "$expanded_note_val"
  done

}

#
# Generate a .sh file which is run before any plugin script, to ensure all the plugins config is available
#
# $1 - the plugin id or name
#
_tm::cfg2::plugin_generate_sh_cfg_file(){
  local -A plugin_details
  _tm::parse::plugin plugin_details "$1"

  # TODO: only if changed?
  _tm::cfg2::__generate_sh_from_plugin_yaml "${plugin_details[cfg_spec]}" "${plugin_details[cfg_sh]}"
}

_tm::cfg2::__generate_sh_from_plugin_yaml(){
  local cfg_file="$1"
  local target_file="$2"

  local expanded_default_val expanded_note_val
  _tm::prog::yq '.keys | to_entries[] | [.key, .value.default, .value.note, .value.required, .value.type] | @tsv' "$cfg_file" -r | \
  mkdir -p "$(dirname "$target_file")"
  echo "" > "$target_file"
  while IFS=$'\t' read -r key_name raw_default_val raw_note_val raw_required_val raw_type_val; do
    # Apply envsubst to the values that might contain environment variables
    expanded_default_val=$(echo "$raw_default_val" | $ENV_SUBST_CMD)
    expanded_note_val=$(echo "$raw_note_val" | $ENV_SUBST_CMD)

    if _is_trace; then
      _trace "--- Key: $key_name ---"
      _trace "  Raw Default:      $raw_default_val"
      _trace "  Expanded Default: $expanded_default_val"
      _trace "  Raw Note:         $raw_note_val"
      _trace "  Expanded Note:    $expanded_note_val"
      _trace "  Required:         $raw_required_val"
      _trace "  Type:             $raw_type_val"
      _trace ""
    fi

    echo "_env_cfg_key --this --key '$key_name' --default '$expanded_default_val' --note '$expanded_note_val'" >> "${target_file}"
  done

}
