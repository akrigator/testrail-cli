#!/bin/bash

TESTRAIL_API_SOURCE=$(dirname "${BASH_SOURCE[0]-$0}")

source "${TESTRAIL_API_SOURCE}/output.sh"
#source "${TESTRAIL_API_SOURCE}/api.sh"
source "${TESTRAIL_API_SOURCE}/tr_cases.sh"
source "${TESTRAIL_API_SOURCE}/tr_results.sh"
source "${TESTRAIL_API_SOURCE}/tr_sections.sh"

test "$TESTRAIL_API_USER" || ERROR "Specify user or email in TESTRAIL_API_USER variable"
test "$TESTRAIL_API_KEY" || ERROR "Specify password or api-token TESTRAIL_API_KEY in variable"
test "$TESTRAIL_API_URL" || ERROR "Specify URL in TESTRAIL_API_URL variable"
test "$TESTRAIL_API_DEBUG" && WARNING "TESTRAIL_API_DEBUG is set"

TESTRAIL_API_TEST() {
  tr_test 'Check error if non exist case is requested' \
    "get_case 0"
  tr_test 'Check multiple cases processing is not broken by non exist case: "3" reported to stderr, "2" reported to stdout' \
    "get_case 3 2"
  tr_test 'Check error if non exist case is edited' \
    "edit_case 'sed s/^//g' 0"
  tr_test 'Check case is edited' \
    "edit_case 'sed s/qwe/qqwe/g' 10081841"
  tr_test 'Check error if invalid command' \
    "edit_case 'fail' 2"
  tr_test 'Check error if non exist name section is requested' \
    "get_nested_sections_by_name 4 19 'Activity logs'"
  tr_test 'Check warning if multiple sections are available with same name' \
    "get_nested_sections_by_name 4 19 'Activity Log'"
  tr_test 'Check error if on exist id section is requested' \
    "get_nested_sections 9999999"
  tr_test 'Get nested sections for section with id 983710: 983710 983711 983712 983713 983714 983715 983716 983717 983718 983719 985024' \
    "get_nested_sections 983710"
  tr_test 'Count of nested cases for the section id: 63' \
    "get_nested_cases_by_section_id 983710 | wc -l"
  tr_test 'Count of nested cases for the section name: 63' \
    "get_nested_cases_by_section_name 4 20 CTA2 | wc -l"
  tr_test 'Get failed tests in the section of plan: 39' \
    "get_formatted_results 1808 | jq '.[] | select((.status_id!=1) and (.comment |contains(\"Connection reset\") |not))' | jq -s length"
}

tr_test() {
  local description="${1:?Test description}"
  local command=${2?Test command}

  INFO "$description\n" "\$ $command"
  eval "$command"
}