#!/bin/bash
# Test script to verify shell detection in .tm.boot.sh

echo "=== Testing shell detection in bash ==="
# Source the bootstrap script
source ../bin/.tm.boot.sh

# Print shell information
echo "Shell detection test results:"
echo "----------------------------"
echo "Current shell: $SHELL"
echo "BASH_VERSION: ${BASH_VERSION:-not set}"
echo "ZSH_VERSION: ${ZSH_VERSION:-not set}"
echo "----------------------------"
echo "Bash test completed"

echo ""
echo "=== To test in zsh, run the following command: ==="
echo "zsh -c 'source $(pwd)/../bin/.tm.boot.sh && echo \"ZSH test successful: ZSH_VERSION=$ZSH_VERSION\"'"
echo ""
echo "If you see 'ZSH test successful' without any error messages about bash version,"
echo "then the fix is working correctly."
