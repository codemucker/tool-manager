_tm::prog::yq(){
  if ! commaqnd -v yq > /dev/null; then
    _tm::prog::__install_yq
  fi
}

_tm::prog::__install_yq(){
  _tm::log::info "Attempting to install yq..."
  if command -v brew >/dev/null 2>&1; then
    _tm::log::info "Using brew to install yq."
    brew install yq
  elif command -v snap >/dev/null 2>&1; then
    _tm::log::info "Using snap to install yq."
    sudo snap install yq
  elif command -v apt-get >/dev/null 2>&1; then
    _tm::log::info "Using apt-get to install yq."
    sudo apt-get update && sudo apt-get install -y yq
  elif command -v dnf >/dev/null 2>&1; then
    _tm::log::info "Using dnf to install yq."
    sudo dnf install -y yq
  elif command -v yum >/dev/null 2>&1; then
    _tm::log::info "Using yum to install yq."
    sudo yum install -y yq
  elif command -v pacman >/dev/null 2>&1; then
    _tm::log::info "Using pacman to install yq."
    sudo pacman -S --noconfirm yq
  else
    _tm::log::err "No supported package manager found (brew, snap, apt-get, dnf, yum, pacman)."
    _tm::log::err "Please install yq manually from https://github.com/mikefarah/yq/"
    return 1
  fi
}
