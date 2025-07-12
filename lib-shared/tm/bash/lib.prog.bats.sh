
_tm::prog::bats(){
  if ! command -v bats &> /dev/null; then
    _tm::prog::bats::install
  fi
  bats "$@"
}

_tm::prog::bats::install(){
  if ! command -v bats &> /dev/null; then
      BATS_CORE_INSTALL_DIR="$TM_PACKAGES_DIR/bats-core"
      # tm-install tpkg:@bats/bats-core
      # tm-install tpkg:@bats/bats-support
      # tm-install tpkg:@bats/bats-assert

      if [ ! -d "$BATS_CORE_INSTALL_DIR" ]; then
          _info "bats (bats-core) not found. Cloning from git..."
          mkdir -p "$(dirname "$BATS_CORE_INSTALL_DIR")"
          git clone https://github.com/bats-core/bats-core "$BATS_CORE_INSTALL_DIR" &> /dev/null
          _info "installed bats-core"
      fi
      #_tm::path::add_path "${BATS_CORE_INSTALL_DIR}/bin"
      export PATH="$PATH:${BATS_CORE_INSTALL_DIR}/bin"
  fi

  if ! command -v batslib_err &> /dev/null; then
      BATS_SUPPORT_INSTALL_DIR="$TM_PACKAGES_DIR/bats-support"
      if [ ! -d "$BATS_SUPPORT_INSTALL_DIR" ]; then
          _info "bats-support not found. Cloning from git..."
          mkdir -p "$(dirname "$BATS_SUPPORT_INSTALL_DIR")"
          git clone https://github.com/ztombol/bats-support.git "$BATS_SUPPORT_INSTALL_DIR" &> /dev/null
          _info "installed bats-support"
      fi
      source "${BATS_SUPPORT_INSTALL_DIR}/load.bash"
  fi

  if ! command -v assert_failure &> /dev/null; then
      BATS_ASSERT_INSTALL_DIR="$TM_PACKAGES_DIR/bats-assert"
      if [ ! -d "$BATS_ASSERT_INSTALL_DIR" ]; then
          _info "bats-assert not found. Cloning from git..."
          mkdir -p "$(dirname "$BATS_ASSERT_INSTALL_DIR")"
          git clone https://github.com/ztombol/bats-assert.git "$BATS_ASSERT_INSTALL_DIR" &> /dev/null
          _info "installed bats-assert"
      fi
      source "${BATS_ASSERT_INSTALL_DIR}/load.bash"
  fi
}