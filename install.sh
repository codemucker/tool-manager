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

# --- Bash Version Check ---
if [[ ! "$(echo "${BASH_VERSION:-0}" | grep -e '^[5-9]\..*' )" ]]; then
  # Check if we're on macOS
  if [[ "$(uname)" == "Darwin" ]]; then
    echo "${log_prefix}Detected macOS with Bash version ${BASH_VERSION:-0}"
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
    fi

    # Install Bash 5+
    echo "${log_prefix}Installing Bash 5+ via Homebrew..."
    brew install bash

    # Get the path to the new Bash
    NEW_BASH="$(brew --prefix)/bin/bash"

    if [[ -x "$NEW_BASH" ]]; then
      echo "${log_prefix}Bash 5+ installed successfully. Re-executing script with new Bash..."
      exec "$NEW_BASH" "$0" "$@"
    else
      _err "Failed to find or execute the newly installed Bash"
      exit 1
    fi
  else
    _err "Incompatible bash version, expect bash version 5 or later, installed is '${BASH_VERSION:-0}'"
    _err "On mac you can install bash(5) or later via homebrew"
    exit 1
  fi
fi

# --- Determine Installation Path ---
if [[ -n "$TM_HOME" ]] && [[ -d "$TM_HOME" ]]; then
  tm_home="$TM_HOME"
fi
tm_bashrc="$tm_home/.bashrc"
home_bashrc="$HOME/.bashrc"

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
# Check if tm_bashrc is already sourced.
# This pattern looks for a line starting with "source" followed by a path ending with "/tool-manager/.bashrc"
# or the specific $tm_bashrc path.
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

source "$tm_bashrc"
