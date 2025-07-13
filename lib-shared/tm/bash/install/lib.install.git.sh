_tm::install::git(){
  if ! command -v git &> /dev/null; then
    _info "git not found, attempting to install it for you."
    if ! _confirm "Do you want to install git?"; then
      _error "User aborted. git is not installed. Need to nstall it to continue."
      return 1
    fi

    if [[ "$OSTYPE" == "darwin"* ]]; then
      _tm::invoke brew install git
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
      if command -v apt-get &>/dev/null; then
        _info "Attempting to install git using 'apt-get'..."
        sudo apt-get update && sudo apt-get install -y git
      elif command -v yum &>/dev/null; then
        _info "Attempting to install git using 'yum'..."
        sudo yum install -y git
      elif command -v dnf &>/dev/null; then
        _info "Attempting to install git using 'dnf'..."
        sudo dnf install -y git
      else
        _err "Could not find a supported package manager (apt-get, yum, dnf). Please install git manually."
        return 1
      fi
    elif [[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys" ]]; then
      _err "Please install git manually for Windows/Cygwin/Msys from https://git-scm.com/"
      return 1
    else
      _err "Unsupported OS for git installation: $OSTYPE. Need to nstall git manually."
      return 1
    fi
  fi
}
