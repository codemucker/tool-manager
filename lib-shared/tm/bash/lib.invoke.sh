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
           _fail "Program '$prog' is not installed and found not find installer script '$installer'"
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
    if ! command -v tm-install-pkg &> /dev/null; then
      # todo: save the choice so as to not prompt again
      if _confirm "the tool-manager install plugin (@tm/tm-install) is not installed. Install?"; then
        _tm::plugin::install @tm/tm-install
      fi
      if ! command -v tm-install-pkg &> /dev/null; then
        _warn "the tool-manager install plugin is not installed, so can't install program '${program}' via this"
        return $__tm_exit_not_found
      fi
    fi
    tm-install-pkg "$pkg:$program" || _error "Error running 'tm-install-pkg $pkg:$program'"
   if ! command -v "$program" &> /dev/null; then
     _warn "Could not install program '${program}' via the '@tm/tm-install' plugin"
     return $__tm_exit_not_found
   else
      _info "Installed program '${program}' via the '@tm/tm-install' plugin"
   fi
}
