_tm::install::yq() {
  if command -v yq >/dev/null]]; then
    return
  fi

  _info "Attempting to install yq..."
  if command -v brew >/dev/null 2>&1; then
    _info "Using brew to install yq."
    brew install yq
  elif command -v apt-get >/dev/null 2>&1; then
    _info "Using apt-get to install yq."
    sudo apt-get update && sudo apt-get install -y yq
  elif command -v snap >/dev/null 2>&1; then
    _info "Using snap to install yq."
    sudo snap install yq
  elif command -v dnf >/dev/null 2>&1; then
    _info "Using dnf to install yq."
    sudo dnf install -y yq
  elif command -v yum >/dev/null 2>&1; then
    _info "Using yum to install yq."
    sudo yum install -y yq
  elif command -v pacman >/dev/null 2>&1; then
    _info "Using pacman to install yq."
    sudo pacman -S --noconfirm yq
  else
    if _tm::invoke::is_installed brew; then
        _info "Using brew to install yq."
        brew install yq
        return
    fi
    _tm::log::err "No supported package manager found (brew, snap, apt-get, dnf, yum, pacman)."
    _tm::log::err "Please install yq manually from https://github.com/mikefarah/yq/"
    return 1
  fi
}

