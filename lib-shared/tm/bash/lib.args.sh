# 
# Library to provide argument parsing and validation functionality
#

if command -v _tm::args::parse &>/dev/null; then # already loaded
  return
fi

_tm::source::include_once @tm/lib.validate.sh

#
# Parses command-line arguments according to a specified options string and populates an associative array.
#
# Usage:
#   _parse_args <options_string> <array_name>  <helpf_func> <args...>
#
# Parameters:
#   --ignore-spec-errors  : (optional) if set, ignore any parse args errors due to invalid option specs. It will still validate user input. Only affects options given after this option. Default 0
#                       This can be useful if your scripts might encounter older versions of tool-manager
#   --opt-<key> name/value pairs: '|name=value|name2=value2'.  The option specification. Used to tell the args parser what the user supplied options can be
#                     First char is the value separator (non alphanumeric, e.g '|' or ';' etc). Recommended to use '|'. This caters for 'special chars' in any of the values which
#                     might clash with the separator if it were fixed. By forcing  it's use,it's clear
#
#                     e.g. ';short=x;desc=The value for 'x' can be a|b'
#
#                     Option spec:
#                    - short         (optional) short option (e.g., "p"). Can be provided multiple times
#                    - long          (optional) long option (e.g., "plain"). Defaults to the '<key>' if no short option provided. Can be provided multiple times
#                    - flag          (optional) (flag) if no value to be taken, false by default (0)
#                    - multi         (optional) (flag) if multiple values are supported, false by default (0)
#                    - multi-sep     (optional) the multi value sep. Useful if there are whitespaces in the values. Default is a space
#                    - required      (optional) (flag) if option is required, false by default (0)
#                    - remainder     (optional) (flag) if set, then all the remaining args are set on this variable. No options are read after. Only one option can have this set
#                    - greedy        (optional) (flag) if this is a 'remainder' option, and this flag is set, then collect _all_ the args and options after this value. If not set, allow options afterwards. Default is false (0)
#                    - desc          (optional) help text
#                    - example       (optional) example text
#                    - default       (optional) default value. The default is an empty string
#                    - allowed       (optional) allowed values. First char is the value separator if non alphanumeric. Default is ','. E.g. ,foo,bar or |foo|bar
#                    - validators|validator    (optional) comma separated validators
#                                    (+alphanumeric,+numbers,+letters,+nowhitespace,+noslash,+re:<pattern>,plugin-vendor,plugin-name,plugin-prefix).
#
#                                    If prefixed with  a '+' (or no prefix), must pass (default), if prefixed with a '-', must fail validator
#
#                                    Additional validators can be added by calling the validation lib '_tm::validate::add_validator <validator-name> <validator-regex>'
#
#   --unknown-args-key <key> : (optional) if set, allow unknown args. Useful if you only want to capture some of the options, and the pass the rest through to some other program
#                             unknown args will be added as the value of the provided <key>, or 'unknown' if not provided. Disabled by default
#   --error-key    <key>     : (optional) if set, then parse args does not return an error on failure, instead returning the error message via this key . If no key is provided,
#                             it defaults to 'error'. Disabled by default
#   --result                 : (required) Name of the associative array to populate (passed by reference)
#   --help <function/string> : (optional) function to run for help, or if a string, echo as is. If empty not enabled
#   --help-tip               : (flag) if set, then always print a small help tip. Default is false
#   --help-on-error          : (flag) if set, then print the help on validation error. Default is false
#   --                       : Important! the separator to differentiate between the parser options and the caller args. User supplied args must come after this
#   <user supplied args...>  : User supplied command-line arguments to parse (using the above provided option specs as the rules)
#
# Example:
#   declare -A args
#   _parse_args --help _help \
#               --opt-plain   ",short=p,long=plain,required,flag,desc=some-help" \
#               --opt-env     '|short=e|long=environment|desc=set an environment variable \   # can change the name of 'long' env argument, else would default to 'env'
#               --opt-plugin  '|remainder|short=p|desc=the plugin \                           # this captures any non named args
#               ...more options ...
#               --result args \   # the associative array to put the parse results in
#               -- "$@"           # note the '--' to indicate the start of user supplied args
#
# Notes:
#   - The associative array is populated with the option name.
#   - The associative array is first cleared.
#   - For required options, missing values trigger an error (unless a default is supplied).
#   - Flag options (no value) are set to "0" in the array, or 1 when available. 
#   - When a non flag option is set with no value, the value is set to empty.
#
_parse_args() {
  _tm::args::parse "$@"
}

_tm::args::parse() {
    if _is_finest; then
      _finest "args: '$*'"
    fi
    local process_args=0
    local caller_help=
    local help_tip=0 # whether to show a help tip always
    local help_on_error=0 # whether to show full help on error
    
    # parse this if no help provided
    local calling_script=""
    local remaining_args=""

    local keys=( "help" )
    local required_keys=()
    local -A spec_by_key=( ["help"]="|short=h|long=help|desc=Show this help|flag" )
    local -A keys_by_arg=()
    # flags by key
    local -A flags_by_key=()
    local -A defaults_by_key=()
    local -A multi_by_key=() # 0/1 flag to determine if a key can have multiple values
    local -A multi_sep_by_key=() # separators used to separate multi values values, by key
    local -A allowed_by_key=() # allowed values for a given key
    local -A validators_by_key=() # list of validators to apply to a value, by key
    local remainder_key=''
    local ignore_spec_errors=0
    local user_args=''
    local allow_unknown=0
    local unknown_key
    local capture_error=0
    local error_key
    #
    # Parses an option spec string given in "key=value;key2=value2" format.
    #
    # Arguments
    # $1 - the key to use for the option
    # $2 - the provided option spec string
    # $3 - the associative array to put the parse results in
    #
    local __parse_option_spec
    __parse_option_spec(){
      local option_key="$1"
      local option_spec="$2"
      local -n ref_array="$3" # assign this array to point to the given named array (by reference)
      # set defaults
      ref_array=( \
          [allowed]="" \
          [default]='' \
          [desc]='' \
          [example]='' \
          [flag]=0 \
          [greedy]=0 \
          [group]='' \
          [key]="$option_key" \
          [long]="$option_key" \
          [multi]=0 \
          [multi_sep]=' ' \
          [remainder]=0 \
          [required]=0 \
          [short]='' \
          [value]='value' \
          [validators]='' \
      )

      local old_ifs="$IFS"
      local separator="${option_spec:0:1}"
      if [[ "$separator" =~ [^[:alnum:]] ]]; then
        IFS="$separator"
      else
        _fail "In option spec '$option_spec', first char should be the options separator (non alphanumeric, e.g. '|,/;' etc), Recommend '|' as default"
      fi
      local -a options_array
      # Use 'read -ra' to split the string into an array based on the current IFS
      read -ra options_array <<< "$option_spec"

      local pair
      # Process each part from the array
      for pair in "${options_array[@]}"; do
          # Trim leading/trailing whitespace from pair
          pair="${pair#"${pair%%[![:space:]]*}"}" 
          pair="${pair%"${pair##*[![:space:]]}"}"

          if [[ -z "$pair" ]]; then
            continue # skip empty pairs
          fi

          local key
          local value
          
          if [[ "$pair" == *"="* ]]; then # have a name=value
              key="${pair%%=*}"
              value="${pair#*=}"
          else # only the name
              # Assume it's a flag if no '=' (e.g., "required")
              key="$pair"
              value="1"
          fi

          # Trim leading/trailing whitespace from key and value
          key="${key#"${key%%[![:space:]]*}"}"
          key="${key%"${key##*[![:space:]]}"}"
          value="${value#"${value%%[![:space:]]*}"}"
          value="${value%"${value##*[![:space:]]}"}"

          case "$key" in
              allowed) # valid allowed values. FIrst char can be the value separator used
                  ref_array[allowed]="$value"                  
                  ;;
              default) # default value to use
                  ref_array[default]="$value"
                  ;;                  
              desc) # help desc
                  ref_array[desc]="$value"
                  ;;
              example)
                  ref_array[example]="$value"
                  ;;     
              flag) # if this is a flah arg only
                  ref_array[flag]=1
                  ;;                               
              greedy) # if this is a remainder arg, and this is set, then eact all the remainings args and options
                  ref_array[greedy]=1
                  ;;
              group)
                  ref_array[group]="$value"
                  ;;
              required) # if the args is required
                  ref_array[required]=1
                  ;;
              long) # the args long name version (double dash)
                  ref_array[long]="$value"                
                  ;;
              multi)
                  ref_array[multi]=1
                  ;;
              multi_sep|'multi-sep') 
                  # separator to use when passing back multiple values
                  ref_array[multi_sep]="$value"
                  ;;
              remainder) # if set, then this key takes all the remainings args
                  ref_array[remainder]=1
                  ;;
              short) # the args short name version (single dash)
                  ref_array[short]="$value"
                  ;;        
              value) # the name of the help option 'value'
                  ref_array[value]="$value"
                  ;;
              validators|validator) # the validation options
                  ref_array[validators]="$value"
                  ;;
              ignore-spec-errors)
                  ignore_spec_errors=1
                  ;;
              *)
                if [[ "${ignore_spec_errors}" == "1" ]]; then
                  _warn "Unknown command args spec option '$key', for option '$option_key', in option spec '$option_spec'"
                else
                  _fail "Unknown command args spec option '$key', for option '$option_key', in option spec '$option_spec'"
                fi
                ;;
          esac
      done

      IFS="$old_ifs" # Restore original IFS
    } # end parse options spec line

    #
    # Prints the help/usage message based on parsed option specs.
    #
    # No args
    #
    local __print_help
    __print_help() {
        local bold=$(tput bold)
        local normal=$(tput sgr0)
        # show the args passed if it's not just the help. This is helpful in case commands are called from within another program
        # and there is a failure
        if [[ ! "${user_args}" == '--help' ]] && [[ ! "${user_args}" == '-h' ]]; then
          __println "${bold}PROVIDED ARGS${normal}"
          __println "  ${user_args}"
          __println
        fi
        __println "${bold}USAGE${normal}"
        local script=''
        if [[ -n "$calling_script" ]] && [[ -f "$calling_script" ]]; then
          script="$(basename "$calling_script")"
        fi

        if [[ -n "$remainder_key" ]]; then # we have a remainder option
            local -A spec
            __parse_option_spec "$remainder_key" "${spec_by_key["$remainder_key"]}" spec
            __print "  $script [OPTIONS] <${spec[value]^^}>"
            if [[ -n "${multi_by_key["$remainder_key"]:-}" ]]; then
              __print " <${spec[value]^^}> ..."
            fi
            __println 
        else
            __println "  $script [OPTIONS]"
        fi
        
        __println
        if [[ -n "$caller_help" ]]; then
          __println "${bold}DESCRIPTION${normal}" 
          if [[ "$(type -t "$caller_help")" == "function" ]]; then
            "$caller_help"
          else
            echo "$caller_help"
          fi
        elif [[ -n "$calling_script" ]] && [[ -f "$calling_script" ]]; then
          __println "${bold}DESCRIPTION${normal}"
          __println "   (auto generated from $calling_script)"
          __println
          _tm::args::print_help_from_file_comment "$calling_script"
        fi

        __println
        __println "${bold}OPTIONS${normal}"
        # non grouped
        for key in "${keys[@]}"; do
            local -A spec
            __parse_option_spec "$key" "${spec_by_key[$key]:-}" spec
            local group="${spec[group]}"
            if [[ -z "$group" ]]; then # no group
              __print_option spec
            fi
        done | sort
        # grouped output
        local last_group=""
        for key in "${keys[@]}"; do
            local -A spec
            __parse_option_spec "$key" "${spec_by_key[$key]:-}" spec
            local group="${spec[group]}"
            if [[ -n "$group" ]]; then # this key belongs to a grouping
              if [[ "$last_group" != "$group" ]]; then # only print group if it changes
                __println 
                __println "  $group options"           
              fi
              last_group="$group"
              __print_option spec
            fi
        done | sort
    } # end print options
    
    #
    # Print a single option
    #
    # $1 - the option spec array
    #
    local __print_option
    __print_option() {
    # grab a reference to the parsed option spec
        local -n print_spec="$1"
        local short_name="${print_spec[short]}"
        local long_name="${print_spec[long]}"
        local required="${print_spec[required]}"
        local group="${print_spec[group]}"
        local desc="${print_spec[desc]}"
        local value_name="${print_spec[value]}"
        local flag="${print_spec[flag]}"
        local example="${print_spec[example]}"
        local multi="${print_spec[multi]}"
        local allowed="${print_spec[allowed]}"
        local default="${print_spec[default]}"

        local line="  "
        if [[ -n "$short_name" ]]; then
          line+="-${bold}$short_name${normal}"
        fi
        if [[ -n "$long_name" ]]; then
          if [[ -n "$short_name" ]]; then
            line+=", "
          fi
          line+="--${bold}$long_name${normal}"
        fi
        line+=": "
        if [[ "$flag" == '1' ]]; then # no value to set
          line+=" (flag)"
        else
          line+=" <${value_name}>"
          if [[ -n "$default" ]]; then
              line+=" (default '${default}')"
          fi
        fi

        if [[ "$required" == '1' ]]; then
          line+=" (required)"
        fi        
        if [[ "$multi" == '1' ]]; then
          line+=" (multi-valued)"
        fi
        __println "$line"
        
        if [[ -n "$allowed" ]]; then
          local allowed_values=()
          __parse_allowed_values "$allowed" allowed_values
          line="        one of: "
          local sep=0
          local sep_char=',' # Default separator for allowed values
          local first_char="${allowed:0:1}"
          if [[ "$first_char" =~ [^[:alnum:]] ]]; then
            # If the first char is a non-alphanumeric, it's the custom separator
            sep_char="$first_char"
          fi

          for valid_val in "${allowed_values[@]}"; do
            if [[ $sep == 1 ]]; then
                line+="${sep_char}"
            fi
            sep=1
            line+="$valid_val"
          done
          __println "$line"
        fi

        if [[ -n "$desc" ]]; then
          __println "        $desc"
        fi
        if [[ -n "$example" ]]; then
          __println "        E.g. $example"
        fi
    } # end print option

    local __println
    __println(){
      >&2 echo "$@"
    }

    local __print
    __print(){
      >&2 echo "$@"
    }

    local __validate_arg
    __validate_arg(){
      local key="$1"
      local value="$2"

      # check the value is valid if enabled
      local allowed="${allowed_by_key["$key"]:-}"
      if [[ -n "$allowed" ]]; then
        local allowed_values=()
        __parse_allowed_values "$allowed" allowed_values
        local valid=0
        for valid_val in "${allowed_values[@]}"; do
          if [[ "$valid_val" == "$value" ]]; then
            valid=1
            break
          fi
        done
        if [[ $valid == 0 ]]; then
          _fail "invalid value '$value' for '$key'. Valid values are: $allowed"
        fi
      fi


      # run any provided validators
      local validators_csv="${validators_by_key["$key"]}"
      _tm::validate::key_value "${key}" "${value}" "${validators_csv}"
    }

    local __parse_allowed_values
    __parse_allowed_values(){
      local allowed="$1"
      local -n array_ref="$2"
      local separator=',' # Default separator for allowed values
      local first_char="${allowed:0:1}"
      if [[ "$first_char" =~ [^[:alnum:]] ]]; then
        # If the first char is a non-alphanumeric, it's the custom separator
        separator="$first_char"
      fi
      IFS="$separator" read -ra array_ref <<< "$allowed"
    }

    __arg_error(){
        local msg="$1"
        if [[ "${capture_error}" == "1" ]]; then
          # the caller will handle it
          if [[ "$help_on_error" == "1" ]]; then
            _error "$msg" # before the help, so we know why help was printed
            __print_help
          fi
          results["${error_key}"]="$msg" # make the error available to callers
        else # terminate the script         
          if [[ "$help_on_error" == "1" ]]; then
            _error "$msg" # before the help, so we know why help was printed
            __print_help
            _fail "$msg" # fail hard
          else
            _error "$msg"
            _fail "Run again with '-h' or '--help' for available options" # fail hard, but let caller know how to get the options
          fi
        fi
    }
    local remaining_args=()
    local collect_remaining=0
    # if enabled, then all the remaining args and options are collected as is
    local remainder_is_greedy=0
    local result_name=""
    # ======= args parser options parsing ==========
    # parse the options (Args spec) for this parser. Terminate this part when we see a '--' on it's own
    while [[ $# -gt 0 && "$process_args" -eq 0 ]]; do
       case "$1" in 
        '--result') 
          # array we put the parse results in
          result_name="$2"
          shift 2
          ;;
        '--help')
          caller_help="$2"
          shift 2
          ;;
        '--help-on-error')
          help_on_error=1
          shift
          ;;
        '--help-tip')
          help_tip=1
          shift
          ;;
        '--file')
          calling_script="$2"
          shift 2
          ;;
        '--unknown-args-key') 
          # what captures unknown args
          allow_unknown="1"
          if [[ -n "${2:-}" ]] && [[ ! "${2}" == "-"* ]]; then # only if set and not the next option
            unknown_key="$2"
            shift 2
          else
            unknown_key='unknown'
            shift
          fi
          ;;
        '--error-key') 
          # what captures the error (otherwise we fail)
          capture_error="1"
          if [[ -n "${2:-}" ]] && [[ ! "${2}" == "-"* ]]; then # only if set and not the next option
            error_key="$2"
            shift 2
          else
            error_key='error'
            shift
          fi
          ;;          
        '--opt-'*) 
          # an option spec
          local key="${1#--opt-}"  # Remove leading '--opt-'
          local spec="$2"
          #_trace "found arg option '$key' with spec '$spec'"
          shift 2
          local -A parts
          __parse_option_spec "$key" "$spec" parts
          local short_name="${parts[short]}"
          local long_name="${parts[long]}"
          
          defaults_by_key["$key"]="${parts[default]:-}"

          if [[ "${parts[remainder]}" == '1' ]]; then
            if [[ -n "$remainder_key" ]]; then
                _fail "Duplicate remainder (option spec flag 'remainder') keys '$remainder_key' and '$key' "
            fi
            remainder_key="$key"
            # if greedy, just takes all the remaining args, and doesn't allow options afterwards
            if [[ ${parts[greedy]} == '1' ]]; then
                remainder_is_greedy=1
            fi
          fi

          keys+=("$key")
          spec_by_key["$key"]="$spec"
          if [[ -n "$short_name" ]]; then
              if [[ -n "${keys_by_arg["-$short_name"]:-}" ]]; then
                _fail "Duplicate short option '-${short_name}' for option keys '$key' and '${keys_by_arg["-$short_name"]}', with specs '${spec_by_key["$key"]}' and '${spec_by_key["${keys_by_arg["-$short_name"]}"]}' respectively"
              fi
              keys_by_arg["-$short_name"]="$key"
          fi
          if [[ -n "$long_name" ]]; then
              if [[ -n "${keys_by_arg["--$long_name"]:-}" ]]; then
                _fail "Duplicate long option '--${long_name}' for option keys '$key' and '${keys_by_arg["--$long_name"]}', with specs '${spec_by_key["$key"]}' and '${spec_by_key["${keys_by_arg["--$long_name"]}"]}' respectively"
              fi
            keys_by_arg["--$long_name"]="$key"
          fi
          [[ "${parts[required]}" == '1' ]] && required_keys+=("$key") || true
          [[ "${parts[multi]}" == '1' ]] && multi_by_key["$key"]="1" || true
          flags_by_key["$key"]="${parts[flag]}"
          validators_by_key["$key"]="${parts[validators]}"
        ;;
        '--') 
          # args parser options terminal. Anything after this is now the user args
          shift
          process_args=1
          break
          ;;
        *)
          _fail "Unknown option '$1'. Expected to find a '--' to delimit the user supplied args "
      esac
    done
    # Now $@ contains the user supplied arguments to parse (not the args spec)
    local -n parse_results="$result_name"  # reference the args array passed in by the caller
    # Clear the array. We can't set the default values here, as the option with the 'remainder' would append
    # to the end of the default value. We only set defaults at the end when done
    for key in "${keys[@]}"; do
      parse_results["$key"]=""
    done

    # ============= user args parsing ==============
    # now parse the user command-line arguments
    user_args="$@" # also capture for the help
    if [[ -n "$user_args" ]]; then # handle the empty case, of no args
      while [[ $# -gt 0 ]]; do
          local arg_full="$1"
          local arg="$1"
          if [[ -z "$arg" ]]; then
             continue
          fi
          #if we are just collecting the last args for the remainder key now (no more options)
          if [[ $collect_remaining == 1 ]]; then 
            remaining_args+=("$1")
          else # we are still parsing user provided args here
            # Check for --help or -h in args
            if [[ "$arg" == "-h" ]] || [[ "$arg" == "--help" ]]; then
              __print_help
              exit 1
            fi

            # Check if arg is a valid short or long option
            local found=0
            _trace  "reading arg: '$arg'"
            local key="${keys_by_arg["$arg"]:-}"
            if [[ -n "$key" ]]; then # found a valid arg to process             
                local value=""
                if [[ "${flags_by_key["$key"]}" == '1' ]]; then # only a flag option, don't read the value
                  value="1"
                else # we have a value option
                  if [[ "${2:-}" != -* && $# -gt 1 ]]; then # next value isn't an option and there are more args
                       value="$2"
                       shift # consume the value
                   else # no value provided or next is an option
                       value=""
                   fi
                fi
                # run any validation
                __validate_arg "$key" "$value"
                # set arg value. Check if a single value option, or a multiple value option
                if [[ "${multi_by_key["$key"]:-}" == "1" ]]; then # append if set
                  local value_sep="${multi_sep_by_key["$key"]:-' '}"
                  # set or append the value
                  [[ -z "${parse_results["$key"]:-}" ]] && parse_results["$key"]="$value" || parse_results["$key"]+="${value_sep}${value}"
                else # replace
                  parse_results["$key"]="$value"
                fi
                # finished processing this arg
            elif [[ ! "$arg_full" == -* ]] && [[ -n "$remainder_key" ]] && [[ "${allow_unknown}" == "0"  ]]; then
              # next arg is not an option, and we have a remainder option, and we are not allowing unknown options (to be passed along)
              # we should add this to the 'remainder' option if enabled

              remaining_args+=("$1")
              # check if the remainder arg can have more options after?
              if [[ "$remainder_is_greedy" == "1" ]]; then
                collect_remaining=1
              fi
              # finished processing this arg
              shift
              continue
            elif [[ "${allow_unknown}" == "1" ]]; then
                # ignore args. Just collect in to the 'unknown' bucket
                # If the current argument is a flag (starts with -), add it directly.
                # Otherwise, it's a value for the previous unknown argument.
                if [[ "$arg" == -* ]]; then # It's an unknown option/flag
                  if [[ -n "${parse_results["$unknown_key"]:-}" ]]; then
                    parse_results["$unknown_key"]+="\t$arg"
                  else
                    parse_results["$unknown_key"]="$arg"
                  fi
                else # It's a value for the previous unknown option
                  # Append to the last added unknown argument
                  if [[ -n "${parse_results["$unknown_key"]:-}" ]]; then
                    parse_results["$unknown_key"]+="\t$arg"
                  else
                    parse_results["$unknown_key"]="$arg"
                  fi
                fi
                # finished processing this arg
            else
              # user supplied args -> error
              __arg_error "Unknown option: '$1' for args '$user_args'"
              return
            fi
          fi
          shift # process next arg
      done
    fi

    # ===== final processing and validation =======

    # pass back all the additional args to the option key with the flag 'remainder'
    if [[ ! ${#remaining_args[@]} == 0 ]]; then # if we have remaining args
      # handle multi key support. If multiple values, then append, otherwise replace
      local value_sep="${multi_sep_by_key["$remainder_key"]:-' '}"
      if [[ "${multi_by_key["$remainder_key"]:-}" == "1" ]] && [[ -n "${parse_results["$remainder_key"]:-}" ]]; then # append 
        IFS="$value_sep" parse_results["$remainder_key"]+=" ${remaining_args[@]}"
      else # set
        IFS="$value_sep" parse_results["$remainder_key"]="${remaining_args[@]}"
      fi
    fi

    # set default values if no value was provided. We do this at the end, as setting
    # default values at the start results in args supporting accumulation would otherwise
    # append to the end of the value
    for key in "${keys[@]}"; do
        if [[ -z "${parse_results["$key"]}" ]]; then
          parse_results["$key"]="${defaults_by_key["$key"]:-}"
        fi
    done
    # Check required options are set
    local print_help=0
    for key in "${required_keys[@]}"; do
        if [[ -z "${parse_results["$key"]:-}" ]]; then
            local -A parts
            __parse_option_spec "$key" "${spec_by_key["$key"]}" parts
            local short_name="${parts[short]}"
            local long_name="${parts[long]}"
            local required="${parts[required]}"
            local help="${parts[desc]}"

            # user supplied args error
            _error "$(printf "ERROR! Required option '-%s%s' is missing\n" "$short_name" "${long_name:+ (--${long_name})}")"

            # don't fails on first one, print the other missing args too.
            print_help=1
        fi
    done

    if [[ $print_help == 1 ]]; then
       _die "Run again with '-h' or '--help' for available options"
    fi

    # print optional help tip
    if [[ "$help_tip" == '1' ]]; then
        local script=''
        if [[ -n "$calling_script" ]] && [[ -f "$calling_script" ]]; then
          script="$(basename "$calling_script") "
        fi
        _info "tip: run ${script}with --help for options"
    fi

    return 0
}

# Print help documentation for a specific script fileAdd commentMore actions
#
# Purpose:
#   Extract and display help documentation from a script's header comments
#
# Arguments:
#   $1 - Path to script file
#
# Usage:
#   _tm::args::print_help_from_file_comment "/path/to/script"
#
# Output:
#   Prints formatted help text to stdout
_tm::args::print_help_from_file_comment() {
  local file="$1"

  # Check if the file exists and has a shebang
  if [[ -f "$file" ]] && head -n 1 "$file" | grep -q "^#!"; then
    # Extract and print just the filename (no path or prefix)
    echo "$(basename "$file")"
    # Parse and print comments (lines starting with #), skipping shebang and stopping at first empty line
    awk '
      /^#!/{next}  # Skip shebang line
      /^#/ {printf "    %s\n", substr($0, 3)}  # Print comment lines without the #, indented by 4 spaces
      /^[^#]/ && NR > 1 {exit}    # Stop at first non-comment line after shebang
    ' "$file"
  else
    echo "File '$file' not found or does not have a shebang."
  fi
}
