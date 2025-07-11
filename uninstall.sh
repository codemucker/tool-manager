#!/usr/bin/env bash
#
# uninstall.sh - remove Tool Manager and all plugins
#
# This script deletes the Tool Manager directories and
# removes any sourcing lines from ~/.bashrc and ~/.profile
# that were added by the installer.

set -e

log_prefix="[tool-manager uninstall]"

# Parse command line arguments
FORCE_MODE=false
for arg in "$@"; do
    case $arg in
        --force)
            FORCE_MODE=true
            shift
            ;;
    esac
done

if [[ "$FORCE_MODE" == true ]]; then
    echo "${log_prefix} Force mode enabled. All confirmations will be skipped."
fi

# Determine installation directory
TM_HOME="${TM_HOME:-$HOME/.tool-manager}"

# Source .tm.boot.sh to get the correct paths
if [[ -f "$TM_HOME/bin/.tm.boot.sh" ]]; then
    source "$TM_HOME/bin/.tm.boot.sh"
else
    echo "${log_prefix} Error: Could not find .tm.boot.sh. Using default paths."
    # Define default paths if .tm.boot.sh is not available
    user_config_dir="${XDG_CONFIG_HOME:-"$HOME/.config"}"
    user_state_dir="${XDG_STATE_HOME:-"$HOME/.local/share"}"
    user_cache_dir="${XDG_CACHE_HOME:-"$HOME/.cache"}"

    TM_BASE_CACHE_DIR="${TM_BASE_CACHE_DIR:-"${user_cache_dir}/tool-manager"}"
    TM_BASE_CFG_DIR="${TM_BASE_CFG_DIR:-"$user_config_dir/tool-manager"}"
    TM_BASE_STATE_DIR="${TM_BASE_STATE_DIR:-"$user_state_dir/tool-manager"}"
fi

# Source utility functions
if [[ -f "$TM_HOME/lib-shared/tm/bash/lib.util.sh" ]]; then
    source "$TM_HOME/lib-shared/tm/bash/lib.util.sh"
    if type  _confirm &>/dev/null; then
        _uninstall_confirm() {
            if [[ "$FORCE_MODE" == true ]]; then
                return 0
            else
                _confirm "$@"
            fi
        }
    fi
fi
if ! type _uninstall_confirm &>/dev/null; then
    # Define a simple confirm function if the library is not available
    _uninstall_confirm() {
        # Skip confirmation if force mode is enabled
        if [[ "$FORCE_MODE" == true ]]; then
            return 0
        fi

        local prompt="${1}"
        local yn=""
        while true; do
            read -p "$prompt [y/n]: " yn
            case $yn in
                [Yy]* ) return 0;;
                [Nn]* ) return 1;;
                * ) echo "Please answer yes or no.";;
            esac
        done
    }
fi

_remove_tm_lines() {
    local file="$1"
    if [[ -f "$file" ]]; then
        echo "${log_prefix} Removing Tool Manager lines from $file"
        # Remove block added by the installer
        sed -i '' '/# Added by Tool Manager install script/,/fi$/d' "$file"
        # Remove any remaining references to the tm bashrc
        sed -i '' '/\.tool-manager\/\.bashrc/d' "$file"
    fi
}

if [[ -z "$TM_HOME" || "$TM_HOME" == "/" ]]; then
    echo "${log_prefix} Error: TM_HOME is empty or root directory. Aborting uninstall."
    exit 1
elif [[ -d "$TM_HOME" ]]; then
    if _uninstall_confirm "Are you sure you want to remove tool-manager? This will delete all of the code"; then
        echo "${log_prefix} Removing '$TM_HOME'"

        # Remove the cache directory without asking questions
        if [[ -d "$TM_BASE_CACHE_DIR" ]]; then
            echo "${log_prefix} Removing cache directory '$TM_BASE_CACHE_DIR'"
            _rm -rf "$TM_BASE_CACHE_DIR"
        fi

        # Check for config directory
        if [[ -d "$TM_BASE_CFG_DIR" ]]; then
            # Check if the config directory is empty
            if [ -z "$(ls -A "$TM_BASE_CFG_DIR" 2>/dev/null)" ]; then
                echo "${log_prefix} Config directory is empty, removing it"
                _rm -rf "$TM_BASE_CFG_DIR"
            else
                # TODO: check if config has been recently backed up (no pending changes)
                if _uninstall_confirm "Do you also want to delete all the config?"; then
                    # TODO: maybe run a config backup first
                    echo "${log_prefix} Removing config directory"
                    _rm -rf "$TM_BASE_CFG_DIR"
                else
                    echo "${log_prefix} Keeping config directory"
                    # Move config to a backup location
                    CONFIG_BACKUP="$HOME/tool-manager-config-backup-$(date +%Y%m%d%H%M%S)"
                    echo "${log_prefix} Moving config to $CONFIG_BACKUP"
                    mkdir -p "$CONFIG_BACKUP"
                    cp -r "$TM_BASE_CFG_DIR"/* "$CONFIG_BACKUP"
                fi
            fi
        fi

        # Check for state directory
        if [[ -d "$TM_BASE_STATE_DIR" ]]; then
            # Check if the state directory is empty
            if [ -z "$(ls -A "$TM_BASE_STATE_DIR" 2>/dev/null)" ]; then
                echo "${log_prefix} State directory is empty, removing it"
                _rm -rf "$TM_BASE_STATE_DIR"
            else
                if _uninstall_confirm "Do you also want to delete the state directory?"; then
                    echo "${log_prefix} Removing state directory"
                    _rm -rf "$TM_BASE_STATE_DIR"
                else
                    echo "${log_prefix} Keeping state directory"
                    # Move state to a backup location
                    STATE_BACKUP="$HOME/tool-manager-state-backup-$(date +%Y%m%d%H%M%S)"
                    echo "${log_prefix} Moving state to $STATE_BACKUP"
                    mkdir -p "$STATE_BACKUP"
                    cp -r "$TM_BASE_STATE_DIR"/* "$STATE_BACKUP"
                fi
            fi
        fi

        # Remove the main directory
        _rm -rf "$TM_HOME"
        echo "${log_prefix} Install directory removed"
    else
        echo "${log_prefix} Uninstall cancelled by user"
        exit 0
    fi
else
    echo "${log_prefix} No install directory found at '$TM_HOME'"
fi

_remove_tm_lines "$HOME/.bashrc"
_remove_tm_lines "$HOME/.zshrc"
_remove_tm_lines "$HOME/.zprofile"

# Unset all environment variables that start with TM_ or __TM
for var in $(env | grep -E "^(TM_|__TM)" | cut -d= -f1); do
    echo "${log_prefix} Unsetting $var"
    unset "$var"
done

echo "${log_prefix} Uninstall complete"
