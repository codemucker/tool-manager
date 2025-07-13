_tm::install::conda() {
  if command -v conda &>/dev/null; then
    return
  fi

  _info "Attempting to install conda..."
  if ! _confirm "Okay to install Miniconda (a minimal installer for conda)?"; then
    _fail "User aborted. conda is not installed. Please install it to continue."
  fi

  local os_type
  local arch
  local installer_url
  local installer_file

  os_type="$(uname -s)"
  arch="$(uname -m)"

  case "$os_type" in
    Linux)
      os_type="Linux"
      ;;
    Darwin)
      os_type="MacOSX"
      ;;
    *)
      _err "Unsupported OS for conda installation: $os_type. Please install conda manually."
      return 1
      ;;
  esac

  case "$arch" in
    x86_64)
      arch="x86_64"
      ;;
    arm64 | aarch64)
      if [[ "$os_type" == "MacOSX" ]]; then
        arch="arm64"
      else
        arch="aarch64"
      fi
      ;;
    *)
      _err "Unsupported architecture for conda installation: $arch. Please install conda manually."
      return 1
      ;;
  esac

  installer_file="Miniconda3-latest-${os_type}-${arch}.sh"
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

  if [[ ! -d "${install_dir}/bin" ]]; then
    _fail "Miniconda installation failed. Directory ${install_dir}/bin not found."
  fi

  _info "Adding Miniconda to PATH for this session..."
  export PATH="${install_dir}/bin:$PATH"

  _info "Initializing conda for your shell..."
  if ! "${install_dir}/bin/conda" init bash &>/dev/null; then
    _warn "conda init failed. You may need to manually configure your shell."
  fi

  _info "Miniconda installation complete. Please restart your shell or 'source ~/.bashrc' for changes to take effect permanently."
  _info "Conda is now available in the current shell session."

  if ! command -v conda &>/dev/null; then
    _fail "conda is not available on PATH after installation. Something went wrong."
  fi
}

