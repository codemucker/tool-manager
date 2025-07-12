_tm::prog::bashcov(){
    if ! command -v bashcov &> /dev/null; then
        _tm::prog::bashcov::install
    fi
    bashcov "$@"
}

_tm::prog::bashcov::install() {
    if command -v bashcov &>/dev/null; then
        return
    fi
    _tm::log::info "bashcov not found. Attempting to install..."

    if [[ "$(uname)" == "Darwin" ]] && command -v brew &>/dev/null; then
        _tm::log::info "Attempting to install bashcov with Homebrew..."
        if brew install bashcov; then
            _tm::log::info "bashcov installed successfully via brew."
            return 0
        fi
        _tm::log::warning "'brew install bashcov' failed. Will try other methods."
    fi

    if command -v apt-get &>/dev/null; then
        _tm::log::info "Attempting to install bashcov with apt-get..."
        if sudo DEBIAN_FRONTEND=noninteractive apt-get -y install bashcov; then
            _tm::log::info "bashcov installed successfully via apt-get."
            return 0
        fi
        _tm::log::warning "'apt-get install bashcov' failed. Will try other methods."
    fi

    if command -v gem &>/dev/null; then
        _tm::log::info "Attempting to install bashcov with gem..."
        if (gem install bashcov || sudo gem install bashcov); then
            _tm::log::info "bashcov installed successfully via gem."
            return 0
        fi
        _tm::log::error "'gem install bashcov' failed."
    fi

    _tm::log::error "Could not install bashcov automatically. Please install it manually."
    _tm::log::info "On macOS: brew install bashcov"
    _tm::log::info "On Debian/Ubuntu: sudo apt-get install bashcov"
    _tm::log::info "Or via RubyGems: gem install bashcov"
    return 1
}
