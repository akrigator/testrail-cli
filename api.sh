#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/output.sh"
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

api_request() {
  curl -s -H "Content-Type: application/json" -u "${user_email:?User is empty}:${user_key:?Password or key is empty}" "$@"
}
export -f api_request

get_results() {
  local test=${1:?Test ID is required}
  api_request "${url}/index.php?/api/v2/get_results/${test}" || error "Couln't get result for test $test"
}
export -f get_results

get_results_for_case() {
  local run=${1:?Run ID is required}
  local case=${2:?Case ID is required}
  local responce=$(api_request "${url}/index.php?/api/v2/get_results_for_case/${run}/${case}")
  if [ "$responce" == '{"error":"Field :case_id is not a valid test case."}' ] || [ "$responce" == '{"error":"No (active) test found for the run\/case combination."}' ] 
  then
    error "Run $run case $case: $(jq .error <<< $responce)"
    return 1
  else
    echo "$responce"
  fi
}
export -f get_results_for_case

get_formated_results_for_case() {
  local run=${1:?Run ID is required}
  local case=${2:?Case ID is required}
  local format=${3:?Jq format is requred}
  get_results_for_case $run $case | jq "$format"
}
export -f get_formated_results_for_case

get_results_for_section() {
  local project=${1:?Project ID is required}
  local suite=${2:?Suite ID is required}
  local run=${3:?Run ID is required}
  local section=${4:?Section ID is requred}

  local cases=$(get_nested_cases_by_section_id "$project" "$suite" "$section")
  local format='[ .[] | {id, test_id, status_id, comment} | select(.status_id!=null)]'
  tr ' ' '\n' <<< $cases  | parallel -q -j$threads get_formated_results_for_case "$run" {} "$format" | jq -s add
}
export -f get_results_for_section

TESTRAIL_test() {
  debug 'Error Edit unexist case'
  edit_case 99999999999 's///g'
  debug "Check error if unexist case is requested"
  get_case 34534534
  debug "Check error if unexist name section is requested"
  get_nested_sections_by_name 4 19 'Activity logs'
  debug "Check warning if multiple sections are available with same name"
  get_nested_sections_by_name 4 19 'Activity Log'
  debug "Get nested sectios for section with id 21096: 21096, 21099, 21101, 21102, 21145, 21146, 21147, 21148, 21153, 21154, 21155, 21156, 21526"
  get_nested_sections_by_id 4 19 21096
  debug "Count of nested cases for the section id"
  get_nested_cases_by_section_id 4 19 21347 | wc -l
  debug "Count of nested cases for the section name"
  get_nested_cases_by_section_name 4 19 EGG_DONOR | wc -l
  debug "Get failed tests in the section of plan"
  get_results_for_section 4 19 1808 21064 | jq '.[] | select((.status_id!=1) and (.comment |contains("Connection reset") |not))'
}
