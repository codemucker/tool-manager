#!/usr/bin/env bash
#
# install.sh
#
# This script installs the Tool-Manager (tm).
# It checks for Bash version compatibility, clones the tm repository
# from GitHub (if not already installed or TM_HOME is not set),
# and adds a line to the user's ~/.bashrc to source the tm environment.
#

# --- Helper Functions ---
_err() {
  echo "[ERROR] [install.sh] $*" >&2
}

# Check if bash version is 5 or higher, or if we're running in zsh
# Returns 0 (success) if the shell is compatible, 1 (failure) otherwise
_is_compatible_shell() {
  # Check if we're running in zsh by checking ZSH_VERSION or SHELL
  if [[ -n "${ZSH_VERSION:-}" ]] || [[ "$SHELL" == *"zsh"* ]]; then
    # zsh is compatible with our scripts, no version check needed
    return 0
  # Check if we're running in bash
  elif [[ -n "${BASH_VERSION:-}" ]]; then
    # Check for minimum bash version 5
    if [[ "$(echo "${BASH_VERSION}" | grep -e '^[5-9]\..*')" ]]; then
      return 0
    else
      return 1
    fi
  else
    # Neither bash nor zsh detected
    echo "${log_prefix}WARNING: Unable to determine shell type. Neither BASH_VERSION nor ZSH_VERSION is set, and SHELL=$SHELL doesn't contain 'zsh'."
    echo "${log_prefix}This script is designed to work with bash 5+ or zsh. Continuing with caution..."
    return 1
  fi
}

# Configure shell config file to source tm_bashrc
_configure_shell_file() {
  local file_path="$1"
  local create_if_missing="${2:-0}"  # 0 or 1, default is 0
  local file_name=$(basename "$file_path")

  if [[ -f "$file_path" ]]; then
    if grep -q "source \".*\/\.tool-manager\/\.bashrc\"" "$file_path" || grep -qFx "source \"$tm_bashrc\"" "$file_path"; then
      echo "${log_prefix}tool-manager already sourced in '$file_path'. Skipping update"
    else
      echo "${log_prefix}Adding tool-manager source to '$file_path'..."
      cat << EOF >> "$file_path"

# Added by Tool Manager install script ($tm_git_repo/install.sh) on $(date)
# Source Tool Manager environment if the file exists
[[ -f "$tm_bashrc" ]] && source "$tm_bashrc"
EOF
      echo "${log_prefix}tool-manager (tm) configured in '$file_path'"
    fi
  elif [[ "$create_if_missing" == "1" ]]; then
    echo "${log_prefix}Creating '$file_path' with tool-manager source..."
    cat << EOF > "$file_path"
# Created by Tool Manager install script ($tm_git_repo/install.sh) on $(date)
# Source Tool Manager environment if the file exists
[[ -f "$tm_bashrc" ]] && source "$tm_bashrc"
EOF
    echo "${log_prefix}tool-manager (tm) configured in newly created '$file_path'"
  fi
}

# Add Homebrew's bin to PATH in the specified file
_add_homebrew_to_path() {
  local file_path="$1"
  local create_if_missing="$2"  # 0 or 1

  if [[ -f "$file_path" ]]; then
    if ! grep -q "export PATH=\"\$(brew --prefix)/bin:\$PATH\"" "$file_path"; then
      echo "${log_prefix}Adding Homebrew's bin to PATH in $file_path..."
      cat << EOF >> "$file_path"

# Added by Tool Manager install script to ensure Homebrew's Bash is used
export PATH="\$(brew --prefix)/bin:\$PATH"
EOF
    fi
  elif [[ "$create_if_missing" == "1" ]]; then
    echo "${log_prefix}Creating $file_path with Homebrew's bin in PATH..."
    cat << EOF > "$file_path"
# Added by Tool Manager install script to ensure Homebrew's Bash is used
export PATH="\$(brew --prefix)/bin:\$PATH"
EOF
  fi
}

# --- Configuration ---
log_prefix="[tool-manager install] "
tm_git_repo="git@github.com:codemucker/tool-manager.git"
tm_home="$HOME/.tool-manager"
git_clone=1
specified_version=""

# --- Parse Arguments ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      shift
      specified_version="$1"
      if [[ -z "$specified_version" ]]; then
        _err "--version requires an argument"
        exit 1
      fi
      shift
      ;;
    --version=*)
      specified_version="${1#*=}"
      shift
      ;;
    *)
      _err "Unknown argument: $1"
      exit 1
      ;;
  esac
done

# --- Shell Compatibility Check ---
if ! _is_compatible_shell; then
  # Check if we're on macOS
  if [[ "$OSTYPE" == "darwin"* ]]; then
    if [[ -n "${ZSH_VERSION:-}" ]]; then
      echo "${log_prefix}Detected macOS with ZSH version ${ZSH_VERSION}"
    else
      echo "${log_prefix}Detected macOS with Bash version ${BASH_VERSION:-0}"
    fi
    echo "${log_prefix}Attempting to install Bash 5+ via Homebrew..."

    # Check if Homebrew is installed
    if ! command -v brew &>/dev/null; then
      echo "${log_prefix}Homebrew not found. Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

      # Add Homebrew to PATH for the current session
      if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      elif [[ -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
      else
        _err "Homebrew installation failed or path not found"
        exit 1
      fi

      # Update user's bash_profile to add Homebrew's bin to PATH
      _add_homebrew_to_path "$HOME/.bash_profile" 1

      # Also update .bashrc to ensure PATH is set in both files
      _add_homebrew_to_path "$home_bashrc" 0
    fi

    # Install Bash 5+
    echo "${log_prefix}Installing Bash 5+ via Homebrew..."
    brew install bash

    # Get the path to the new Bash
    NEW_BASH="$(brew --prefix)/bin/bash"

    if [[ -x "$NEW_BASH" ]]; then
      echo "${log_prefix}Bash 5+ installed successfully."

      # Suggest changing the default login shell to Homebrew's bash
      current_shell=$(dscl . -read /Users/$USER UserShell | awk '{print $2}')
      if [[ "$current_shell" != "$NEW_BASH" ]]; then
        echo "${log_prefix}RECOMMENDATION: To use Bash 5+ for all interactive shells, change your default login shell:"
        echo "${log_prefix}Run this command: chsh -s $(brew --prefix)/bin/bash"
        echo "${log_prefix}This will ensure all interactive shells use Bash 5+ instead of the system default."
        echo "${log_prefix}Press Enter to continue with the installation..."
        read -r
      fi

      echo "${log_prefix}Re-executing script with new Bash..."
      exec "$NEW_BASH" "$0" "$@"
    else
      _err "Failed to find or execute the newly installed Bash"
      exit 1
    fi
  else
    if [[ -n "${ZSH_VERSION:-}" ]]; then
      _err "Incompatible shell configuration. This script requires zsh with proper configuration."
    else
      _err "Incompatible bash version, expect bash version 5 or later, installed is '${BASH_VERSION:-0}'"
      _err "On mac you can install bash(5) or later via homebrew"
    fi
    exit 1
  fi
fi

# --- Determine Installation Path ---
if [[ -n "$TM_HOME" ]] && [[ -d "$TM_HOME" ]]; then
  tm_home="$TM_HOME"
fi
tm_bashrc="$tm_home/.bashrc"
home_bashrc="$HOME/.bashrc"
home_zshrc="$HOME/.zshrc"
home_zprofile="$HOME/.zprofile"

# --- Check if already installed ---
if [[ -f "$tm_bashrc" ]]; then
  echo "${log_prefix}tool-manager (tm) is already installed at '$tm_home'. Skipping install"
  echo "${log_prefix} - to update, run 'git pull' from within '$tm_home' or call 'tm-update-self'"
  git_clone=0
fi

# --- Clone repository ---
if [[ "$git_clone" == "1" ]]; then
  if [[ -n "$specified_version" ]]; then
    version="$specified_version"
  else
    # Fetch tags and branches
    echo "Retrieving available versions..."
    git fetch --all --tags > /dev/null 2>&1
    available_tags=$(git tag --sort=-creatordate)
    available_branches="main\ndevelop"

    # Combine tags and branches, limit to top 9 tags & branches
    combined_options="$available_tags\n$available_branches"
    options_array=($(echo -e "$combined_options" | head -n 9))

    # Set default version to the latest tag
    default_version=${options_array[0]}

    # Display options to the user
    PS3="Select a version: "
    select version in "${options_array[@]}"; do
      if [[ -n "$version" ]]; then
        break
      else
        version=$default_version
        break
      fi
    done
  fi

  # Selected version will be cloned

  echo "${log_prefix}Cloning Tool Manager from '$tm_git_repo' to '$tm_home' (version: $version)..."
  git clone --branch "$version" "$tm_git_repo" "$tm_home" || { _err "Failed to clone repository from '$tm_git_repo' to '$tm_home' (version: $version). Aborting."; exit 1; }
  echo "${log_prefix}Clone successful."
fi

# --- Update user's .bashrc ---
# Use a slightly different format for .bashrc to maintain compatibility
if grep -q "source \".*\/\.tool-manager\/\.bashrc\"" "$home_bashrc" || grep -qFx "source \"$tm_bashrc\"" "$home_bashrc"; then
    echo "${log_prefix}tool-manager already sourced in '$home_bashrc'. Skipping update"
else
  echo "${log_prefix}Adding tool-manager source to '$home_bashrc'..."
  cat << EOF >> "$home_bashrc"

# Added by Tool Manager install script ($tm_git_repo/install.sh) on $(date)
# Source Tool Manager environment if the file exists
if [[ -f "$tm_bashrc" ]]; then
  source "$tm_bashrc"
fi
EOF
  echo "${log_prefix}tool-manager (tm) installed and configured at '$tm_home'"
fi

# --- Update user's .zshrc ---
_configure_shell_file "$home_zshrc" 1

# --- Update user's .zprofile ---
_configure_shell_file "$home_zprofile"

source "$tm_bashrc"
