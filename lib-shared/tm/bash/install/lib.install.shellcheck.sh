_tm::install::shellcheck(){
  if  command -v shellcheck &> /dev/null; then
    return
  fi
    _info "shellcheck not found. Attempting to install..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y shellcheck
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y ShellCheck
    elif command -v yum &> /dev/null; then
        sudo yum install -y ShellCheck
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm shellcheck
    elif command -v apk &> /dev/null; then
        sudo apk add shellcheck
    elif command -v brew &> /dev/null; then
        brew install shellcheck
    else
        _warn "Could not find a supported package manager (apt-get, dnf, yum, pacman, apk, brew) to install shellcheck."
        _warn "Need to install shellcheck manually."
        return 1
    fi
}
