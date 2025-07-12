#
# Scripts should generally source this script by default to include the common setup
#

# make the scripts fail fast
set -Eeuo pipefail

STARTTIME=0
_tm::source::include_once @tm/lib.common.sh
