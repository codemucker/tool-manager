_tm::install::conda() {
  if command -v conda &>/dev/null; then
    return
  fi

  _info "Attempting to install conda..."
  if ! _confirm "Okay to install Miniconda (a minimal installer for conda)?"; then
    _fail "User aborted. conda is not installed. Please install it to continue."
  fi

  local os_type
  os_type="$(uname -s)"
  local arch
  arch="$(uname -m)"
  local installer_file
  local installer_url

  case "$os_type" in
    Linux)
      case "$arch" in
        x86_64 | aarch64)
          installer_file="Miniconda3-latest-Linux-${arch}.sh"
          ;;
        *)
          _err "Unsupported architecture for Linux: $arch. Please install conda manually."
          return 1
          ;;
      esac
      ;;
    Darwin)
      local mac_os="MacOSX"
      local mac_arch
      case "$arch" in
        x86_64)
          mac_arch="x86_64"
          ;;
        arm64)
          mac_arch="arm64"
          ;;
        *)
          _err "Unsupported architecture for macOS: $arch. Please install conda manually."
          return 1
          ;;
      esac
      installer_file="Miniconda3-latest-${mac_os}-${mac_arch}.sh"
      ;;
    *)
      _err "Unsupported OS for conda installation: $os_type. Please install conda manually."
      return 1
      ;;
  esac

  installer_url="https://repo.anaconda.com/miniconda/${installer_file}"
  local install_dir="${TM_HOME}/.tm-conda"
  local tmp_installer_path="/tmp/${installer_file}"

  _info "Downloading Miniconda installer from ${installer_url}"
  if command -v curl &>/dev/null; then
    curl -# -L -o "${tmp_installer_path}" "${installer_url}"
  elif command -v wget &>/dev/null; then
    wget -q --show-progress -O "${tmp_installer_path}" "${installer_url}"
  else
    _fail "Neither curl nor wget is available. Cannot download Miniconda installer."
  fi

  if [[ ! -s "${tmp_installer_path}" ]]; then
    _fail "Failed to download Miniconda installer (or file is empty)."
  fi

  _info "Installing Miniconda to ${install_dir}..."
  bash "${tmp_installer_path}" -b -p "${install_dir}"

  rm "${tmp_installer_path}"

  if [[ ! -x "${install_dir}/bin/conda" ]]; then
    _fail "Miniconda installation failed. conda executable not found in ${install_dir}/bin."
  fi

  _info "Adding Miniconda to PATH for this session..."
  export PATH="${install_dir}/bin:$PATH"

  _info "Initializing conda for your shell (bash, zsh)..."
  if ! "${install_dir}/bin/conda" init bash zsh &>/dev/null; then
    _warn "conda init failed. You may need to manually configure your shell."
  fi

  _info "Miniconda installation complete. Please restart your shell or 'source ~/.bashrc' for changes to take effect permanently."
  _info "Conda is now available in the current shell session."

  if ! command -v conda &>/dev/null; then
    _fail "conda is not available on PATH after installation. Something went wrong."
  fi
}

