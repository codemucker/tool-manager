_tm::install::brew(){
  if  command -v brew &> /dev/null; then
    return
  fi
  OS_NAME=$(uname -s)

  if [[ "$OS_NAME" == "Darwin" ]]; then
    _info "Homebrew is not installed."
    if _confirm "Do you want to install Homebrew?"; then
      _info "Installing Homebrew..."
      bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
      _warn "Homebrew installation skipped."
      return 1 # Indicate failure
    fi
  elif [[ "$OS_NAME" == "Linux" ]]; then
    _info "Homebrew is not installed."
    if _confirm "Do you want to install Homebrew on Linux?"; then
      _info "Installing Homebrew for Linux..."
      bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
      _warn "Homebrew installation skipped."
      return 1 # Indicate failure
    fi
  else
    _error "ERROR: Unsupported operating system: $OS_NAME for Homebrew installation." >&2
    return 1 # Indicate failure
  fi
}
