if command -v shfmt &>/dev/null; then # already loaded
  return
fi

_tm::prog::shfmt::install(){
  if ! command -v shfmt &> /dev/null; then
    OS_NAME=$(uname -s)

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
            if command -v brew &> /dev/null; then
                brew install shfmt
            else
                echo "ERROR: Homebrew not found. Please install Homebrew (https://brew.sh/) to install shfmt on macOS." >&2
                return 1 # Indicate failure
            fi
            ;;
        *)
            echo "ERROR: Unsupported operating system: $OS_NAME for shfmt installation." >&2
            return 1 # Indicate failure
            ;;
    esac
  fi

}

_tm::prog::shfmt::install
