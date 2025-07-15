_tm::install::bats(){
  if ! command -v bats &> /dev/null; then
      local BATS_CORE_INSTALL_DIR="$TM_PACKAGES_DIR/bats-core"
      # tm-install tpkg:@bats/bats-core
      # tm-install tpkg:@bats/bats-support
      # tm-install tpkg:@bats/bats-assert

      if [[ ! -d "$BATS_CORE_INSTALL_DIR" ]]; then
          _info "bats (bats-core) not found. Cloning from git..."
          mkdir -p "$(dirname "$BATS_CORE_INSTALL_DIR")"
          git clone https://github.com/bats-core/bats-core "$BATS_CORE_INSTALL_DIR" &> /dev/null
          _info "installed bats-core"
      fi
      #_tm::path::add_path "${BATS_CORE_INSTALL_DIR}/bin"
      export PATH="$PATH:${BATS_CORE_INSTALL_DIR}/bin"
      _info "added 'bats' to PATH"
  fi

  if ! command -v batslib_err &> /dev/null; then
      local BATS_SUPPORT_INSTALL_DIR="$TM_PACKAGES_DIR/bats-support"
      if [ ! -d "$BATS_SUPPORT_INSTALL_DIR" ]; then
          _info "bats-support not found. Cloning from git..."
          mkdir -p "$(dirname "$BATS_SUPPORT_INSTALL_DIR")"
          git clone https://github.com/ztombol/bats-support.git "$BATS_SUPPORT_INSTALL_DIR" &> /dev/null
          _info "installed bats-support"
      fi
      source "${BATS_SUPPORT_INSTALL_DIR}/load.bash"
      if ! command -v batslib_err &> /dev/null;then
        _warn "Error installing or sourcing 'bats-support'"
      else
        _info "'bats-support' added"
      fi
  fi

  if ! command -v assert_failure &> /dev/null; then
      local BATS_ASSERT_INSTALL_DIR="$TM_PACKAGES_DIR/bats-assert"
      if [ ! -d "$BATS_ASSERT_INSTALL_DIR" ]; then
          _info "bats-assert not found. Cloning from git..."
          mkdir -p "$(dirname "$BATS_ASSERT_INSTALL_DIR")"
          git clone https://github.com/ztombol/bats-assert.git "$BATS_ASSERT_INSTALL_DIR" &> /dev/null
          _info "installed bats-assert"
      fi
      source "${BATS_ASSERT_INSTALL_DIR}/load.bash"
      if ! command -v assert_failure &> /dev/null;then
        _warn "Error installing or sourcing 'bats-assert'"
      else
        _info "'bats-assert' added"
      fi
  fi
}