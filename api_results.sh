#!/bin/bash

get_results() {
  local test=${1:?Test ID is required}
  api_request "${url}/index.php?/api/v2/get_results/${test}" || error "Couln't get result for test $test"
}
export -f get_results

get_results_for_case() {
  local run=${1:?Run ID is required}
  local case=${2:?Case ID is required}
  local responce=$(api_request "${url}/index.php?/api/v2/get_results_for_case/${run}/${case}")
  if [ "$responce" == '{"error":"No (active) test found for the run\/case combination."}' ]
  then
    debug "Run $run case $case: $(jq .error <<< $responce)"
    return 1
  fi
  if [ "$responce" == '{"error":"Field :case_id is not a valid test case."}' ]
  then
    error "Run $run case $case: $(jq .error <<< $responce)"
    return 1
  fi
  echo "$responce"
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
  tr ' ' '\n' <<< $cases | parallel -q -j$threads get_formated_results_for_case "$run" {} "$format" | jq -s add
}
export -f get_results_for_section
