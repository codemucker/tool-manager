
_tm::prog::git(){
  if ! command -v git &> /dev/null; then
    _tm::prog::git::install
  fi
  git "$@"
}

_tm::prog::git::install(){
  if ! command -v git &> /dev/null; then
    _info "git not found, attempting to install it for you."
    if ! _confirm "Okay to install git?"; then
      _fail "User aborted. git is not installed. Please install it to continue."
    fi

    if [[ "$OSTYPE" == "darwin"* ]]; then
      if command -v brew &>/dev/null; then
        _info "Attempting to install git using 'brew'..."
        brew install git
      else
        _err "Homebrew not found. Please install brew to allow automatic installation of git."
      fi
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
      fi
    elif [[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys" ]]; then
      _err "Please install git manually for Windows/Cygwin/Msys from https://git-scm.com/"
    else
      _err "Unsupported OS for git installation: $OSTYPE. Please install git manually."
    fi

    if ! command -v git &>/dev/null; then
      _fail "git is not installed. Please install it to continue."
    fi
  fi
}
