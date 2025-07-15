
_tm::install::shfmt(){
    if  command -v shfmt &> /dev/null; then
        return
    fi
    local OS_NAME=$(uname -s)

    if command -v go &> /dev/null; then
        echo "Go is installed. Attempting to install shfmt using 'go install'."
        go install mvdan.cc/sh/v3/cmd/shfmt@latest
        if command -v shfmt &> /dev/null; then
            echo "shfmt installed successfully via Go."
            return 0
        else
            _error "Failed to install shfmt via Go. Falling back to OS-specific package managers." >&2
        fi
    fi
    _tm::install::auto "shfmt"
}
