#
# Provides a function to automatically install a program using available system
# package managers. It detects the operating system and cycles
# through a list of supported package managers to find and install the requested
# program.
#
# Usage:
#   _tm::install::auto <program_name>
#
# Behavior:
# - The function first checks for user-defined package manager preferences.
# - It then falls back to a default, OS-specific list of managers.
# - Before any installation, it will always prompt the user for confirmation.
# - If a program is not found and Homebrew is not installed on a compatible
#   OS (Linux or macOS), it will offer to install Homebrew first.
#
# Configuration:
#
# The primary way to configure this script is through the
# `TM_USER_PACKAGES_MANAGERS` environment variable.
#
# This variable takes a comma-separated list of package manager names.
#
# Example:
#   export TM_USER_PACKAGES_MANAGERS="brew,npm,apt"
#
# The order in the variable defines the priority. In the example above, it will
# try to use 'brew' first, then 'npm', then 'apt', before trying any other
# default managers.
#
# To *exclude* a package manager from being used, prefix its name with a
# hyphen ('-').
#
# Example (to prioritize npm and exclude apt):
#   export TM_USER_PACKAGES_MANAGERS="npm,-apt"
#
# Supported Package Managers:
# - apt: Debian, Ubuntu, etc.
# - dnf: Fedora, RHEL, etc.
# - yum: CentOS, etc.
# - pacman: Arch Linux, etc.
# - brew: Homebrew (macOS and Linux)
# - nix: Nix package manager
# - choco: Chocolatey (Windows)
# - sdkman: SDKMAN!
# - go: Go install
# - npm: Node Package Manager
# - gem: RubyGems
#
# Args:
#   $1 - The name of the program to install.
#
# Returns:
#   0 on successful installation.
#   A non-zero exit code (127) if the program could not be installed.
#
__tm_exit_not_found=127

_tm::install::auto(){
  local program="$1"
  local os
  os="$(uname -s)"

  local managers_to_try=()
  declare -A seen_managers=()
  declare -A excluded_managers=()
  local mgr

  # User-preferred managers from TM_USER_PACKAGES_MANAGERS
  if [[ -n "${TM_USER_PACKAGES_MANAGERS:-}" ]]; then
    local user_pms
    IFS=',' read -r -a user_pms <<< "${TM_USER_PACKAGES_MANAGERS}"
    # First pass: find all exclusions
    for mgr in "${user_pms[@]}"; do
      if [[ "$mgr" == -* ]]; then
        local real_mgr=${mgr:1}
        excluded_managers["$real_mgr"]=1
      fi
    done
    # Second pass: find all inclusions
    for mgr in "${user_pms[@]}"; do
      if [[ "$mgr" != -* ]]; then
        if [[ -z "${seen_managers[$mgr]:-}" && -z "${excluded_managers[$mgr]:-}" ]]; then
          managers_to_try+=("$mgr")
          seen_managers[$mgr]=1
        fi
      fi
    done
  fi
  # Default fallback managers
  local default_pms=()
  case "$os" in
    Linux)
      default_pms=(apt dnf yum pacman brew nix sdkman go npm gem)
      ;;
    Darwin)
      default_pms=(brew nix sdkman go npm gem)
      ;;
    *CYGWIN* | *MINGW* | *MSYS*)
      default_pms=(choco sdkman go npm gem)
      ;;
    *)
      # For other OSes like Windows (WSL), etc.
      default_pms=(sdkman go npm gem)
      ;;
  esac

  for mgr in "${default_pms[@]}"; do
    if [[ -z "${seen_managers[$mgr]:-}" && -z "${excluded_managers[$mgr]:-}" ]]; then
      managers_to_try+=("$mgr")
      seen_managers[$mgr]=1
    fi
  done

  _info "Will try to install '$program' using package managers: ${managers_to_try[*]}"

  for mgr in "${managers_to_try[@]}"; do
    case "$mgr" in
      apt)
        if command -v apt-get &>/dev/null; then
          _info "Checking for '$program' with apt..."
          if apt-cache show "$program" &>/dev/null; then
            if _confirm "Package '$program' found in apt repositories. Install with 'sudo apt-get install'?"; then
              sudo apt-get update && sudo apt-get install -y "$program"
              if command -v "$program" &>/dev/null; then
                _info "Successfully installed '$program' with apt."
                return 0
              else
                _warn "Installation of '$program' with apt failed."
              fi
            else
              _warn "User declined installation of '$program' with apt."
            fi
          fi
        fi
        ;;
      dnf)
        if command -v dnf &>/dev/null; then
          _info "Checking for '$program' with dnf..."
          if dnf -q list available "$program" | grep -q "^${program}\."; then
            if _confirm "Package '$program' found in dnf repositories. Install with 'sudo dnf install'?"; then
              sudo dnf install -y "$program"
              if command -v "$program" &>/dev/null; then
                _info "Successfully installed '$program' with dnf."
                return 0
              else
                _warn "Installation of '$program' with dnf failed."
              fi
            else
              _warn "User declined installation of '$program' with dnf."
            fi
          fi
        fi
        ;;
      yum)
        if command -v yum &>/dev/null; then
          _info "Checking for '$program' with yum..."
          if yum -q list available "$program" &>/dev/null; then
            if _confirm "Package '$program' found in yum repositories. Install with 'sudo yum install'?"; then
              sudo yum install -y "$program"
              if command -v "$program" &>/dev/null; then
                _info "Successfully installed '$program' with yum."
                return 0
              else
                _warn "Installation of '$program' with yum failed."
              fi
            else
              _warn "User declined installation of '$program' with yum."
            fi
          fi
        fi
        ;;
      pacman)
        if command -v pacman &>/dev/null; then
          _info "Checking for '$program' with pacman..."
          if [[ -n "$(pacman -Ssq "^${program}$")" ]]; then
            if _confirm "Package '$program' found in pacman repositories. Install with 'sudo pacman -S'?"; then
              sudo pacman -S --noconfirm "$program"
              if command -v "$program" &>/dev/null; then
                _info "Successfully installed '$program' with pacman."
                return 0
              else
                _warn "Installation of '$program' with pacman failed."
              fi
            else
              _warn "User declined installation of '$program' with pacman."
            fi
          fi
        fi
        ;;
      brew)
        if command -v brew &>/dev/null; then
          _info "Checking for '$program' with Homebrew..."
          if brew info "$program" &>/dev/null; then
            if _confirm "Package '$program' found with Homebrew. Install with 'brew install'?"; then
              brew install "$program"
              if command -v "$program" &>/dev/null; then
                _info "Successfully installed '$program' with Homebrew."
                return 0
              else
                _warn "Installation of '$program' with Homebrew failed."
              fi
            else
              _warn "User declined installation of '$program' with Homebrew."
            fi
          fi
        fi
        ;;
      nix)
        if command -v nix-env &>/dev/null && command -v nix-instantiate &>/dev/null; then
          _info "Checking for '$program' with Nix..."
          if nix-instantiate --eval -A "nixpkgs.${program}" &> /dev/null; then
            if _confirm "Package '$program' found in nixpkgs. Install with 'nix-env -iA nixpkgs.$program'?"; then
              if nix-env -iA "nixpkgs.${program}"; then
                _info "Successfully installed '$program' with Nix. You may need to start a new shell for it to be available."
                return 0
              else
                _warn "Installation of '$program' with Nix failed."
              fi
            else
              _warn "User declined installation of '$program' with Nix."
            fi
          fi
        fi
        ;;
      choco)
        if command -v choco &>/dev/null; then
          _info "Checking for '$program' with Chocolatey..."
          if choco search --exact --limit-output "$program" &>/dev/null; then
            if _confirm "Package '$program' found with Chocolatey. Install with 'choco install'?"; then
              choco install -y "$program"
              if command -v "$program" &>/dev/null; then
                _info "Successfully installed '$program' with Chocolatey."
                return 0
              else
                _warn "Installation of '$program' with Chocolatey failed."
              fi
            else
              _warn "User declined installation of '$program' with Chocolatey."
            fi
          fi
        fi
        ;;
      sdkman)
        local sdkman_init="${HOME}/.sdkman/bin/sdkman-init.sh"
        (
          if [[ -f "${sdkman_init}" ]]; then
            # shellcheck source=/dev/null
            source "${sdkman_init}"
          fi
          if command -v sdk &>/dev/null; then
            _info "Checking for '$program' with SDKMAN!..."
            if sdk list | grep -q -w "$program"; then
              if _confirm "Package (candidate) '$program' found with SDKMAN!. Install with 'sdk install $program'?"; then
                sdk install "$program"
                if command -v "$program" &>/dev/null; then
                  _info "Successfully installed '$program' with SDKMAN!."
                  return 0
                else
                  _warn "Installation of '$program' with SDKMAN! failed. You may need to resource your shell."
                fi
              else
                _warn "User declined installation of '$program' with SDKMAN!."
              fi
            fi
          fi
        ) || _warn "could not install using sdkman"
        ;;
      go)
        if command -v go &>/dev/null; then
          _info "Attempting to install '$program' with 'go install'..."
          if _confirm "Attempt to install '$program' via 'go install ${program}@latest'?\nThis assumes the program name is a valid Go package path."; then
            if go install "${program}@latest"; then
              if command -v "$program" &>/dev/null; then
                _info "Successfully installed '$program' with 'go install'."
                return 0
              else
                _warn "'go install' seemed to succeed, but '$program' could not be found in your PATH."
                _warn "Please ensure your Go bin directory (e.g., \$HOME/go/bin) is in your PATH."
              fi
            else
              _warn "'go install ${program}@latest' failed."
            fi
          else
            _warn "User declined installation of '$program' with 'go install'."
          fi
        fi
        ;;
      npm)
        if command -v npm &>/dev/null; then
          _info "Checking for '$program' with npm..."
          if npm view "$program" >/dev/null 2>&1; then
            if _confirm "Package '$program' found in npm registry. Install with 'npm install -g'?"; then
              npm install -g "$program"
              if command -v "$program" &>/dev/null; then
                _info "Successfully installed '$program' with npm."
                return 0
              else
                _warn "Installation of '$program' with npm failed."
              fi
            else
              _warn "User declined installation of '$program' with npm."
            fi
          fi
        fi
        ;;
      gem)
        if command -v gem &>/dev/null; then
          _info "Checking for '$program' with RubyGems..."
          # The -r flag is to search remote gems, and we use regex for an exact match
          if gem search -r "^${program}$" | grep -q "^${program} "; then
            if _confirm "Package (gem) '$program' found in RubyGems. Install with 'gem install'?"; then
              if gem install "$program"; then
                if command -v "$program" &>/dev/null; then
                  _info "Successfully installed '$program' with RubyGems."
                  return 0
                else
                  _warn "'gem install' seemed to succeed, but '$program' could not be found in your PATH."
                  _warn "You may need to add Ruby's bin directory to your PATH."
                fi
              else
                _warn "Installation of '$program' with RubyGems failed."
              fi
            else
              _warn "User declined installation of '$program' with RubyGems."
            fi
          fi
        fi
        ;;
      *)
        _warn "Unknown or unsupported package manager '$mgr' in search list."
        ;;
    esac
  done

  if ! command -v "$program" &>/dev/null && [[ "$program" != "brew" ]]; then
    if ! command -v brew &>/dev/null && { [[ "$os" == "Linux" ]] || [[ "$os" == "Darwin" ]]; }; then
      local brew_installer_path="$TM_LIB_BASH/install/lib.install.brew.sh"
      if [[ -f "$brew_installer_path" ]]; then
        if _confirm "Homebrew is not installed, but might be able to install '$program'. Install Homebrew now?"; then
           #TODO: just use teh auto installer for brew too?
          source "$brew_installer_path"
          if _tm::install::brew; then
            _info "Homebrew installed. Now trying to install '$program' with it."
            if brew info "$program" &>/dev/null; then
              if _confirm "Package '$program' found with Homebrew. Install with 'brew install'?"; then
                brew install "$program"
                if command -v "$program" &>/dev/null; then
                  _info "Successfully installed '$program' with Homebrew."
                  return 0
                else
                   _warn "Installation of '$program' with Homebrew failed."
                fi
              else
                _warn "User declined installation of '$program' with Homebrew."
              fi
            else
              _warn "Package '$program' not found with Homebrew."
            fi
          else
            _warn "Homebrew installation failed."
          fi
        fi
      fi
    fi
  fi

  if { [[ "$os" == "Darwin" ]] || [[ "$os" == "Linux" ]]; } && ! command -v brew &>/dev/null; then
      _warn "Homebrew not found, which may be required to auto-install '$program'."
      _info "To install it, see https://brew.sh/"
  fi

  return "$__tm_exit_not_found"
}
