#!/bin/bash
# Test script to verify shell detection in install.sh

echo "=== Testing shell detection in bash ==="
# Define the _is_compatible_shell function from install.sh
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
    echo "WARNING: Unable to determine shell type. Neither BASH_VERSION nor ZSH_VERSION is set, and SHELL=$SHELL doesn't contain 'zsh'."
    echo "This script is designed to work with bash 5+ or zsh. Continuing with caution..."
    return 1
  fi
}

# Print shell information
echo "Shell detection test results:"
echo "----------------------------"
echo "Current shell: $SHELL"
echo "BASH_VERSION: ${BASH_VERSION:-not set}"
echo "ZSH_VERSION: ${ZSH_VERSION:-not set}"
echo "Shell type check:"
if [[ -n "${ZSH_VERSION:-}" ]]; then
  echo "ZSH_VERSION is set: ${ZSH_VERSION}"
else
  echo "ZSH_VERSION is not set"
fi
if [[ -n "${BASH_VERSION:-}" ]]; then
  echo "BASH_VERSION is set: ${BASH_VERSION}"
  if [[ "$(echo "${BASH_VERSION}" | grep -e '^[5-9]\..*')" ]]; then
    echo "BASH_VERSION is 5 or higher"
  else
    echo "BASH_VERSION is less than 5"
  fi
else
  echo "BASH_VERSION is not set"
fi
echo "----------------------------"

# Test the _is_compatible_shell function
if _is_compatible_shell; then
  echo "Shell compatibility check passed in bash"
else
  echo "Shell compatibility check failed in bash"
fi

echo "Bash test completed"

echo ""
echo "=== To test in zsh, run the following command: ==="
echo "zsh -c 'source $(pwd)/../install.sh && if _is_compatible_shell; then echo \"ZSH test successful: Shell compatibility check passed\"; else echo \"ZSH test failed: Shell compatibility check failed\"; fi'"
echo ""
echo "If you see 'ZSH test successful' without any error messages about bash version,"
echo "then the fix is working correctly."
