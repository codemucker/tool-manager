#
# Invoke a given program, ensuring it is installed first, or hard fail if it could not be installed
#
# Args:
# $1 - the program to invoke
#

__tm_exit_not_found=127

_tm::invoke(){
    local prog="$1"
    if ! command -v "$prog" &> /dev/null; then
      _tm::invoke::__install_or_fail "$prog"
    fi
    "$@"
}

#
# Invoke a given program, ensuring it is installed first, or return a non zero exit code if it could not be installed
#
# Args:
# $1 - the program to invoke
#
_tm::invoke_or(){
    local prog="$1"
    if ! command -v "$prog" &> /dev/null; then
      _tm::invoke::__install_or_false "$prog"
    fi
    "$@"
}

#
# Ensure all the required programs are installed
#
# Args
# $1... all the programs will be checked one at a time. Will fail if non could be installed
#
_tm::invoke::require(){
    local prog
    for prog in "$@"; do
        _tm::invoke::ensure_installed "$prog"
    done
}


#
# Ensure the given program is installed, or fail if it is not installed and we can't install it
#
# Args:
# $1 - the program you want to ensure is installed
#
_tm::invoke::ensure_installed(){
    local prog="$1"
    if ! command -v "$prog" &> /dev/null; then
      _tm::invoke::__install_or_fail "$prog"
    fi
}

# Try to ensure the given program is installed, or return a non zero exit code if it is not installed and we can't install it
#
# Args:
# $1 - the program you want to ensure is installed
#
_tm::invoke::is_installed(){
    local prog="$1"
    if ! command -v "$prog" &> /dev/null; then
      _tm::invoke::__install_or_false "$prog"
    fi
}

#
# Hard fail if it couldn't install the given program
#
# Args
# $1 - the program to ensure is installed
#
_tm::invoke::__install_or_fail(){
    local prog="$1"
    local installer_name="${2:-"$prog"}"
    if ! command -v "$prog" &> /dev/null; then
      _warn "Program '$prog' not found, looking for installer..."
      # dynamically load the installer
      local installer="$TM_LIB_BASH/install/lib.install.${installer_name}.sh"
      if [[ -f "$installer" ]]; then
        _info "running installer '_tm::install::${installer_name}' in '$installer'"
        _tm::log::push_child "lib.install.${installer_name}"
        source "$installer"
        "_tm::install::${installer_name}" # run the installer script
        _tm::log::pop
        if ! command -v "$prog" &> /dev/null; then
          _fail "failed to install '$prog' using installer '$installer'"
        fi
      elif ! _tm::invoke::__try_package_install "$prog"; then
           _fail "Program '$prog' is not installed and could not find installer script '$installer'"
      fi
    fi
}


#
# Return a non zero exit code if it could not install the given program
#
# Args
# $1 - the program to ensure is installed
#
_tm::invoke::__install_or_false(){
    local prog="$1"
    local installer_name="${2:-"$prog"}"
    if ! command -v "$prog" &> /dev/null; then
      _warn "Program '$prog' not found, looking for installer..."
      local installer="$TM_LIB_BASH/install/lib.install.${installer_name}.sh"
      if [[ -f "$installer" ]]; then
         _info "running installer '_tm::install::${installer_name}' in '$installer'"
         _tm::log::push_child "lib.install.${installer_name}"
        source "$installer"
        "_tm::install::${installer_name}" # run the installer script
        _tm::log::pop
        if ! command -v "$prog" &> /dev/null; then
          _warn "failed to install '$prog' using installer '$installer'"
          return $__tm_exit_not_found
        fi
      elif ! _tm::invoke::__try_package_install "$prog"; then
        _error "Program '$prog' is not installed, could not find installer script '$installer', and could not install via @tm/tm-install"
        return $__tm_exit_not_found
      fi
    fi
}


_tm::invoke::__try_package_install(){
    local program="$1"
    if ! command -v tm-install-tpkg &> /dev/null; then
      # todo: save the choice so as to not prompt again
      if _confirm "the tool-manager '@tm/tm-install' plugin is not installed. Install?"; then
        _tm::plugin::install @tm/tm-install
      fi
      if ! command -v tm-install-tpkg &> /dev/null; then
        _warn "the tool-manager install plugin is not installed, so can't install program '${program}' via this"
        return $__tm_exit_not_found
      fi
    fi
    tm-install-tpkg "$program" || _error "Error running 'tm-install-tpkg $program'"
   if ! command -v "$program" &> /dev/null; then
     _warn "Could not install program '${program}' via the '@tm/tm-install' plugin"
     return $__tm_exit_not_found
   else
      _info "Installed program '${program}' via the '@tm/tm-install' plugin"
   fi
}

_tm::invoke::__trye_auto_install(){
  local program="$1"
  local os
  os="$(uname -s)"

  local managers_to_try=()
  declare -A seen_managers=()
  local mgr

  # User-preferred managers from TM_USER_PACKAGES_MANAGERS
  if [[ -n "${TM_USER_PACKAGES_MANAGERS:-}" ]]; then
    local user_pms
    IFS=',' read -r -a user_pms <<< "${TM_USER_PACKAGES_MANAGERS}"
    for mgr in "${user_pms[@]}"; do
      if [[ -z "${seen_managers[$mgr]:-}" ]]; then
        managers_to_try+=("$mgr")
        seen_managers[$mgr]=1
      fi
    done
  fi

  # Default fallback managers
  local default_pms=()
  case "$os" in
    Linux)
      default_pms=(apt dnf yum pacman brew npm)
      ;;
    Darwin)
      default_pms=(brew npm)
      ;;
    *)
      # For other OSes like Windows (WSL), etc.
      default_pms=(npm)
      ;;
  esac

  for mgr in "${default_pms[@]}"; do
    if [[ -z "${seen_managers[$mgr]:-}" ]]; then
      managers_to_try+=("$mgr")
      seen_managers[$mgr]=1
    fi
  done

  _info "Will try to install '$program' using package managers: ${managers_to_try[*]}"

  for mgr in "${managers_to_try[@]}"; do
    case "$mgr" in
      apt)
        if command -v apt-get &>/dev/null; then
          _info "Checking for '$program' with apt..."
          if apt-cache show "$program" &>/dev/null; then
            if _confirm "Package '$program' found in apt repositories. Install with 'sudo apt-get install'?"; then
              sudo apt-get update && sudo apt-get install -y "$program"
              if command -v "$program" &>/dev/null; then
                _info "Successfully installed '$program' with apt."
                return 0
              else
                _warn "Installation of '$program' with apt failed."
              fi
            else
              _warn "User declined installation of '$program' with apt."
            fi
          fi
        fi
        ;;
      dnf)
        if command -v dnf &>/dev/null; then
          _info "Checking for '$program' with dnf..."
          if dnf -q list available "$program" | grep -q "^${program}\."; then
            if _confirm "Package '$program' found in dnf repositories. Install with 'sudo dnf install'?"; then
              sudo dnf install -y "$program"
              if command -v "$program" &>/dev/null; then
                _info "Successfully installed '$program' with dnf."
                return 0
              else
                _warn "Installation of '$program' with dnf failed."
              fi
            else
              _warn "User declined installation of '$program' with dnf."
            fi
          fi
        fi
        ;;
      yum)
        if command -v yum &>/dev/null; then
          _info "Checking for '$program' with yum..."
          if yum -q list available "$program" &>/dev/null; then
            if _confirm "Package '$program' found in yum repositories. Install with 'sudo yum install'?"; then
              sudo yum install -y "$program"
              if command -v "$program" &>/dev/null; then
                _info "Successfully installed '$program' with yum."
                return 0
              else
                _warn "Installation of '$program' with yum failed."
              fi
            else
              _warn "User declined installation of '$program' with yum."
            fi
          fi
        fi
        ;;
      pacman)
        if command -v pacman &>/dev/null; then
          _info "Checking for '$program' with pacman..."
          if [[ -n "$(pacman -Ssq "^${program}$")" ]]; then
            if _confirm "Package '$program' found in pacman repositories. Install with 'sudo pacman -S'?"; then
              sudo pacman -S --noconfirm "$program"
              if command -v "$program" &>/dev/null; then
                _info "Successfully installed '$program' with pacman."
                return 0
              else
                _warn "Installation of '$program' with pacman failed."
              fi
            else
              _warn "User declined installation of '$program' with pacman."
            fi
          fi
        fi
        ;;
      brew)
        if command -v brew &>/dev/null; then
          _info "Checking for '$program' with Homebrew..."
          if brew info "$program" &>/dev/null; then
            if _confirm "Package '$program' found with Homebrew. Install with 'brew install'?"; then
              brew install "$program"
              if command -v "$program" &>/dev/null; then
                _info "Successfully installed '$program' with Homebrew."
                return 0
              else
                _warn "Installation of '$program' with Homebrew failed."
              fi
            else
              _warn "User declined installation of '$program' with Homebrew."
            fi
          fi
        fi
        ;;
      npm)
        if command -v npm &>/dev/null; then
          _info "Checking for '$program' with npm..."
          if npm view "$program" >/dev/null 2>&1; then
            if _confirm "Package '$program' found in npm registry. Install with 'npm install -g'?"; then
              npm install -g "$program"
              if command -v "$program" &>/dev/null; then
                _info "Successfully installed '$program' with npm."
                return 0
              else
                _warn "Installation of '$program' with npm failed."
              fi
            else
              _warn "User declined installation of '$program' with npm."
            fi
          fi
        fi
        ;;
      *)
        _warn "Unknown or unsupported package manager '$mgr' in search list."
        ;;
    esac
  done

  if [[ "$os" == "Darwin" ]] && ! command -v brew &>/dev/null; then
      _warn "Homebrew not found. Cannot auto-install '$program' on macOS."
      _info "To install it, see https://brew.sh/"
  fi

  return "$__tm_exit_not_found"
}
