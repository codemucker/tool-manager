if command -v brew &>/dev/null; then # already loaded
  return
fi

_tm::prog::brew::install(){
  if ! command -v brew &> /dev/null; then
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
    else
      echo "ERROR: Homebrew is primarily for macOS. Current OS: $OS_NAME." >&2
      return 1 # Indicate failure
    fi
  fi


}

_tm::prog::brew::install
