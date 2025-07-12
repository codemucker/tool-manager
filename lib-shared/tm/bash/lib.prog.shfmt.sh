_tm::prog::shfmt(){
    if ! command -v shfmt &> /dev/null; then
        _tm::prog::shfmt::install
    fi
    shfmt "$@"
}

_tm::prog::shfmt::install(){
    local OS_NAME=$(uname -s)
    # we can also install shfmt using 'go install mvdan.cc/sh/v3/cmd/shfmt@latest' if go is available. ai!
    case "$OS_NAME" in
        Linux*)
            if command -v apt-get &> /dev/null; then
                sudo apt-get update && sudo apt-get install -y shfmt
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y shfmt
            elif command -v yum &> /dev/null; then
                sudo yum install -y shfmt
            elif command -v pacman &> /dev/null; then
                sudo pacman -S --noconfirm shfmt
            else
                echo "ERROR: No supported package manager found for shfmt installation on Linux." >&2
                return 1 # Indicate failure
            fi
            ;;
        Darwin*)
            _include_once @tm/lib.prog.brew.sh
            _tm::prog::brew install shfmt
            ;;
        *)
            echo "ERROR: Unsupported operating system: $OS_NAME for shfmt installation." >&2
            return 1 # Indicate failure
            ;;
    esac

}
