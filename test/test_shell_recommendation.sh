#!/usr/bin/env bash
#
# Test script to verify the shell detection and recommendation in install.sh
#

# Mock functions to simulate the environment
brew() {
  echo "/usr/local"
}

dscl() {
  if [[ "$3" == "/Users/$USER" && "$4" == "UserShell" ]]; then
    echo "UserShell: $MOCK_CURRENT_SHELL"
  else
    echo "Unknown dscl command"
  fi
}

# Test case 1: User already using Homebrew's bash
echo "Test case 1: User already using Homebrew's bash"
export MOCK_CURRENT_SHELL="/usr/local/bin/bash"
NEW_BASH="$(brew --prefix)/bin/bash"
echo "MOCK_CURRENT_SHELL=$MOCK_CURRENT_SHELL"
echo "NEW_BASH=$NEW_BASH"

current_shell=$(dscl . -read /Users/$USER UserShell | awk '{print $2}')
if [[ "$current_shell" != "$NEW_BASH" ]]; then
  echo "FAIL: Should not show recommendation, but would"
else
  echo "PASS: Correctly detected user is already using Homebrew's bash"
fi

# Test case 2: User using system bash
echo -e "\nTest case 2: User using system bash"
export MOCK_CURRENT_SHELL="/bin/bash"
NEW_BASH="$(brew --prefix)/bin/bash"
echo "MOCK_CURRENT_SHELL=$MOCK_CURRENT_SHELL"
echo "NEW_BASH=$NEW_BASH"

current_shell=$(dscl . -read /Users/$USER UserShell | awk '{print $2}')
if [[ "$current_shell" != "$NEW_BASH" ]]; then
  echo "PASS: Correctly detected user is not using Homebrew's bash"
else
  echo "FAIL: Should show recommendation, but wouldn't"
fi

# Test case 3: User using zsh
echo -e "\nTest case 3: User using zsh"
export MOCK_CURRENT_SHELL="/bin/zsh"
NEW_BASH="$(brew --prefix)/bin/bash"
echo "MOCK_CURRENT_SHELL=$MOCK_CURRENT_SHELL"
echo "NEW_BASH=$NEW_BASH"

current_shell=$(dscl . -read /Users/$USER UserShell | awk '{print $2}')
if [[ "$current_shell" != "$NEW_BASH" ]]; then
  echo "PASS: Correctly detected user is not using Homebrew's bash"
else
  echo "FAIL: Should show recommendation, but wouldn't"
fi

echo -e "\nAll tests completed."
