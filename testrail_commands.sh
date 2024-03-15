#!/bin/bash

export TESTRAIL_API_SOURCE=$(dirname "${BASH_SOURCE[0]-$0}")
export PATH="$PATH:$TESTRAIL_API_SOURCE"
export PATH="$PATH:$TESTRAIL_API_SOURCE/cli/cases"
export PATH="$PATH:$TESTRAIL_API_SOURCE/cli/results"
export PATH="$PATH:$TESTRAIL_API_SOURCE/cli/sections"
export PATH="$PATH:$TESTRAIL_API_SOURCE/cli/suites"

test "$TESTRAIL_API_USER" || ERROR "Specify user or email in TESTRAIL_API_USER env variable"
test "$TESTRAIL_API_KEY" || ERROR "Specify api-token TESTRAIL_API_KEY in env variable"
test "$TESTRAIL_API_URL" || ERROR "Specify url in TESTRAIL_API_URL env variable"
test "$TESTRAIL_API_THREAD" || ERROR "Specify threads count in TESTRAIL_API_THREAD env variable"
test "$TESTRAIL_API_DEBUG" && WARNING "TESTRAIL_API_DEBUG is set"

source "${TESTRAIL_API_SOURCE}/cli/output.sh"

tr_test() {
  local description="${1:?Test description}"
  local command=${2?Test command}

  INFO "$description\n" "\$ $command"
  eval "$command"
}

TESTRAIL_API_TEST() {
  tr_test 'Check error if non exist case is requested' \
    "get_case 0"
  tr_test 'Check multiple cases processing is not broken by non exist case: "0" reported to stderr, "1" reported to stdout' \
    "get_case 0 1"
  tr_test 'Check error if non exist case is edited' \
    "edit_case 'sed s/^//g' 0"
  tr_test 'Check case is edited' \
    "edit_case 'sed s/qwe/qqwe/g' 1"
  tr_test 'Check error if invalid command' \
    "edit_case 'fail' 2"
  tr_test 'Check error if non exist name section is requested' \
    "find_section 1 1 'NON EXIST' | get_nested_cases"
  tr_test 'Check warning if multiple sections are available with same name' \
    "find_section 1 1 Test | get_nested_cases"
  tr_test 'Check error if non exist id section is requested' \
    "get_nested_sections 9999999"
  tr_test 'Get nested sections for section with id: 1 2 3' \
    "get_nested_sections 1"
  tr_test 'Count of nested cases for the section id, root 1 for local TR, root 406 for production TR, both should provide 5' \
    "get_nested_cases 1 406 | wc -l"
  tr_test 'Count of nested cases for the section name: 5' \
    "find_section 1 1 Base | get_nested_cases | wc -l"
  tr_test 'Get failed tests in the section of plan: 1' \
    "get_results 1"
}