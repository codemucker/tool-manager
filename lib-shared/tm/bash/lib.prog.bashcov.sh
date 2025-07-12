_tm::prog::bashcov(){
    if ! command -v bashcov &> /dev/null; then
        _tm::prog::bashcov::install
    fi
    bashcov "$@"
}

_tm::prog::bashcov::install(){
    if  command -v bashcov &> /dev/null; then
        return
    fi

    _tm::log::info "bashcov not found. Attempting to install..."
    # On macOS, prefer Homebrew
    if [[ "$(uname)" == "Darwin" ]] && command -v brew &>/dev/null; then
        _tm::log::info "Attempting to install bashcov with Homebrew..."
        if brew install bashcov; then
            _tm::log::info "bashcov installed successfully."
            return 0
        else
            _tm::log::warning "'brew install bashcov' failed. Will try with 'gem'."
        fi
    fi

    # Fallback to gem for non-macOS or if brew fails
    if command -v gem &>/dev/null; then
        _tm::log::info "Attempting to install bashcov with gem. This may ask for your password."
        if sudo gem install bashcov; then
            _tm::log::info "bashcov installed successfully."
            return 0
        else
            _tm::log::error "'sudo gem install bashcov' failed."
        fi
    fi

    _tm::log::error "Could not install bashcov automatically. Please install it manually."
    _tm::log::info "On macOS, you can try: brew install bashcov"
    _tm::log::info "On other systems, install Ruby and then run: sudo gem install bashcov"
    return 1
}
