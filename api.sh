#!/bin/bash

api_request() {
  local url="${TESTRAIL_API_URL}/index.php?/api/v2/${1:?Endpoint is required}"
  local curl_argv=${*:2}
  local credential="$TESTRAIL_API_USER:$TESTRAIL_API_KEY"
  local command="curl -s -H 'Content-Type: application/json' -u '$credential' '$url' $curl_argv"
  local response
  local api_error

  response=$(eval "$command") \
  || ERROR "Curl return code is $?:\n" "$command" \
  || return 1

  api_error=$(jq -r ' if type =="object" and has("error") then .error else empty end' <<< "$response") \
  && test ! "$api_error" \
  || ERROR 'TestRail API returns error:\n' "$api_error" \
  || return 2

  jq -c '.' <<< "$response" \
  || ERROR "Response is not a json:" "$response" \
  || return 3
}

api_get_case() {
  local id=${1:?Case ID is required}
  api_request "get_case/${id}" \
  || ERROR "Couldn't get case with ID $id"
}
export -f api_get_case

api_update_case() {
  local id=${1:?Case ID is required}
  local case=${2:?Test case is required}
  api_request "update_case/${id}" -X POST -d "'$case'"  \
  || ERROR "Couldn't update case with ID $id:\n" "$case"
}
export -f api_update_case

api_get_test() {
  local test_id=${1:?Test ID is required}
  api_request "get_test/${test_id}" \
  || ERROR "Couldn't get test with ID $test_id"
}
export -f api_get_test

api_get_cases_from_section() {
  local section_id=${1:?Section ID is required}
  local suite
  local project
  suite="$(api_get_section "$section_id" | jq -r '.suite_id')" \
  && test "$suite" \
  && project="$(api_get_suite "$suite" | jq -r '.project_id')" \
  && test "$project" \
  && api_request "get_cases/${project}&suite_id=${suite}&section_id=${section_id}" \
  || ERROR "Couldn't get cases for section ID $section_id"
}
export -f api_get_cases_from_section

api_get_results() {
  local test=${1:?Test ID is required}
  api_request "get_results/${test}" \
  || ERROR "Couldn't get result for test $test"
}
export -f api_get_results

api_get_results_for_run() {
  local run_id=${1:?Run ID is required}
  api_request "get_results_for_run/${run_id}" \
  || ERROR "Couldn't get result for run $run_id"
}
export -f api_get_results_for_run

api_get_results_for_case() {
  local run=${1:?Run ID is required}
  local case=${2:?Case ID is required}
  api_request "get_results_for_case/${run}/${case}" \
  || ERROR "Couldn't get results for run $run and case $case"
}
export -f api_get_results_for_case

api_get_suite() {
  local suite_id=${1:?Suite ID is required}
  api_request "get_suite/${suite_id}" \
  || ERROR "Couldn't get suite $suite_id"
}
export -f api_get_suite

api_get_section() {
  local section_id=${1:?Section ID is required}
  api_request "get_section/${section_id}" \
  || ERROR "Couldn't get section $section_id"
}
export -f api_get_section

api_get_sections() {
  local \
    project=${1:?Project ID is required} \
    suite=${2:?Suite ID is required}
  api_request "get_sections/${project}&suite_id=${suite}" \
  || ERROR "Couldn't get sections for $project project and $suite suite"
}
export -f api_get_sections

api_update_section() {
  local id=${1:?Section ID is required}
  local body=${2:?Section body is required}
  api_request "update_section/${id}" -X POST -d "$body" \
  || ERROR "Couldn't update section with ID $id"
}
export -f api_update_section

api_delete_section() {
  local id=${1:?Section ID is required}
  api_request "delete_section/${id}" -X POST \
  || ERROR "Couldn't update section with ID $id"
}
export -f api_delete_section
