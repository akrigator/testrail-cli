#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

debug() {
  [[ "$debug_output" ]] && >&2 echo -e "\033[0;36m$(sed 's/^/DEBUG: /g' <<< "$@")\033[0m"
}
export -f debug

info() {
  >&2 echo -e "\033[0;32m$(sed 's/^/INFO: /g' <<< "$@")\033[0m"
}
export -f debug

warning() {
  >&2 echo -e "\033[0;33m$(sed 's/^/WARNING: /g' <<< "$@")\033[0m"
}
export -f warning

error() {
  >&2 echo -e "\033[0;31m$(sed 's/^/ERROR: /g' <<< "$@")\033[0m"
  return 1
}
export -f error
