#!/bin/bash

TESTRAIL_API_SOURCE=$(dirname "${BASH_SOURCE[0]-$0}")
export PATH="$PATH:$TESTRAIL_API_SOURCE"

source "${TESTRAIL_API_SOURCE}/output.sh"
source "${TESTRAIL_API_SOURCE}/cli_cases.sh"
source "${TESTRAIL_API_SOURCE}/cli_results.sh"
source "${TESTRAIL_API_SOURCE}/cli_sections.sh"

test "$TESTRAIL_API_USER" || ERROR "Specify user or email in TESTRAIL_API_USER env variable"
test "$TESTRAIL_API_KEY" || ERROR "Specify api-token TESTRAIL_API_KEY in env variable"
test "$TESTRAIL_API_URL" || ERROR "Specify url in TESTRAIL_API_URL env variable"
test "$TESTRAIL_API_THREAD" || ERROR "Specify threads count in TESTRAIL_API_THREAD env variable"
test "$TESTRAIL_API_DEBUG" && WARNING "TESTRAIL_API_DEBUG is set"

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
    "get_nested_sections_by_name 1 1 'Activity logs'"
  tr_test 'Check warning if multiple sections are available with same name' \
    "get_nested_sections_by_name 4 1 'Activity Log'"
  tr_test 'Check error if on exist id section is requested' \
    "get_nested_sections 9999999"
  tr_test 'Get nested sections for section with id: 1 2 3' \
    "get_nested_sections 1"
  tr_test 'Count of nested cases for the section id: 5' \
    "get_nested_cases_by_section_id 1 | wc -l"
  tr_test 'Count of nested cases for the section name: 5' \
    "get_nested_cases_by_section_name 1 1 Base | wc -l"
  tr_test 'Get failed tests in the section of plan: 1' \
    "get_formatted_results 1"
}

tr_test() {
  local description="${1:?Test description}"
  local command=${2?Test command}

  INFO "$description\n" "\$ $command"
  eval "$command"
}
