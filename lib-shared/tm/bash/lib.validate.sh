#
# Library to provide generic validation routines
#
if command -v _tm::validate::key_value &>/dev/null; then
  return
fi

#
# Validate a given key/value pair
#
# Arguments
#
# $1 - the key. Used for error messages
# $2 - the value. The value to validate.
# $3 - the validators to use, comma separated

_tm::validate::key_value(){
  _tm::validate::__init

  local key="$1"
  local value="$2"
  local validators_csv="$3"
  # run any provided validators
  if [[ -n "$value" ]] && [[ -n "${validators_csv}" ]]; then
    _is_finest && _finest "validating key '${key}' and value '${value}' with validators '${validators_csv}'"
    local -a validators
    IFS=',' read -ra validators <<< "$validators_csv"
    for validator in "${validators[@]}"; do
      local match=1
      case "${validator}" in
        +*)
          validator=${validator:1}
          ;;
        -*)
          validator=${validator:1}
          match=0
          ;;
      esac

      case "${validator}" in
        re:*)
          local custom_regexp="${validator#re:}"
          _finest "using re:${custom_regexp}"
          if [[ "$match" == "1" ]]; then
            if [[ ! "$value" =~ ${custom_regexp} ]]; then
                _fail "arg '${key}' with value '${value}' does not match pattern '${custom_regexp}' (re)"
            fi
          else
            if [[ "$value" =~ ${custom_regexp} ]]; then
                _fail "arg '${key}' with value '${value}' must not match pattern '${custom_regexp}' (re)"
            fi
          fi
          ;;
        *)
          # lookup the validators
          _trace "looking for validator '${validator}'"
          local validator_string="${__tm_validators_by_name["${validator}"]:-}"
          if [[ -z "${validator_string}" ]]; then
            _warn "Unknown validator '${validator}', skipping"
            continue
          fi

          # extract the regexp and desc
          local regexp=""
          local description=""
          IFS='|' read -r regexp description <<< "${validator_string}"
          if [[ -z "${regexp}" ]]; then # disabled, just skip
            continue
          fi

          if [[ "$match" == "1" ]]; then
            if [[ ! "${value}" =~ ${regexp} ]]; then
              _fail "arg '${key}' with value '${value}' must ${description} (${validator})" 
            fi
          else
            if [[ "$value" =~ ${regexp} ]]; then
                _fail "arg '${key}' with value '${value}' must not ${description} (-${validator})"
            fi
          fi
          ;;
      esac

    done
  fi
}

#
# Add a validator
#
# Arguments
#
# $1 - the validator name
# $2 - the regexp.
# $3 - the desc.
#
_tm::validate::add_validator(){
  local validator="$1"
  local regexp="$2"
  local desc="$3"
  
  _tm::validate::__init
  __tm_validators_by_name["${validator}"]="${regexp}|${desc}"
}


_tm::validate::__init(){
  if [[ ! -v __tm_validators_by_name ]]; then
    declare -g -A __tm_validators_by_name=( \
      [nowhitespace]=" |be whitespace" \
      [noslashes]="/ |contain forward or back slashes" \
      [alphanumeric]="^[a-zA-Z0-9]+$|be alphanumeric" \
      [letters]="^[a-zA-Z]+$|contain only letters" \
      [numbers]="^[0-9]+$|only numbers" \
      [plugin-vendor]="^[@a-zA-Z0-9][\.a-zA-Z0-9\-]*[a-zA-Z0-9]$|start with @ or alphanumeric, then alphanumeric, letters, dashes, dots" \
      [plugin-name]="|" \
      [plugin-prefix]="^[a-zA-Z0-9-]+$|be alphanumeric or dashes" \
      [space-key]="^[a-zA-Z0-9][\.a-zA-Z0-9-]+[a-zA-Z0-9]$|be alphanumeric, dashes, or dots. Must start with a alphanumeric" \
      [name]="^[\.a-zA-Z0-9-]+$|be alphanumeric, dashes, dots" \
      [boolean]="^(1|0|true|false|yes|no|enabled|disabled|yeah|nah)$|be a boolean" \
  )
  fi
}
