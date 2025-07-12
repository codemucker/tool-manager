_tm::prog::brew(){
  if ! command -v brew &> /dev/null; then
    _tm::prog::brew::install
  fi
  brew "$@"
}

_tm::prog::brew::install(){
  if  command -v brew &> /dev/null; then
    return
  fi
  OS_NAME=$(uname -s)

  if [[ "$OS_NAME" == "Darwin" ]]; then
    echo "Homebrew is not installed."
    read -r -p "Do you want to install Homebrew? (y/N) " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            echo "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            ;;
        *)
            echo "Homebrew installation skipped."
            return 1 # Indicate failure
            ;;
    esac
  elif [[ "$OS_NAME" == "Linux" ]]; then
    echo "Homebrew is not installed."
    read -r -p "Do you want to install Homebrew on Linux? (y/N) " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            echo "Installing Homebrew for Linux..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            ;;
        *)
            echo "Homebrew installation skipped."
            return 1 # Indicate failure
            ;;
    esac
  else
    echo "ERROR: Unsupported operating system: $OS_NAME for Homebrew installation." >&2
    return 1 # Indicate failure
  fi
}
