_tm::install::conda() {
  if command -v conda >/dev/null]]; then
    return
  fi

  _info "Attempting to install conda..."
  # install conda (or anaconda) in a way best suited to the currently running OS. Falling back where it can.  ai!
}

