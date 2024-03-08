#!/bin/bash

caller_func_name() {
  test "$BASH_VERSION" && echo "${FUNCNAME[2]}" \
  || (test "$ZSH" && sed 's/ / < /g' <<< "${funcstack[@]:2}") \
  || >&2 ERROR "COULD NOT DETERMINE SHELL"
}

#read_stdin() {
#  local stdin
#
#  test ! -t 0 \
#  && while IFS= read -r line
#  do
#    stdin+=$line
#  done
#
#  printf "%s" "$stdin"
#}

color_to_stderr() {
  local color=${1:?Color}
  local message=${2:-}
  local preformatted=${3:-}

  >&2 printf "\033[0;$color$(caller_func_name) >>> %b%s\033[0m\n" "$message" "$preformatted"
}

DEBUG() {
  test "$TESTRAIL_API_DEBUG" \
  && color_to_stderr '36m' "${1}" "${2}"
}
export -f DEBUG

INFO() {
  color_to_stderr '32m' "${1}" "${2}"
}
export -f INFO

WARNING() {
  color_to_stderr '33m' "${1}" "${2}"
}
export -f WARNING

ERROR() {
  color_to_stderr '31m' "${1}" "${2}"
  return 1
}
export -f ERROR