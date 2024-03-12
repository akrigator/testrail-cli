#!/bin/bash

get_formatted_results_for_case() {
  local run=${1:?Run ID is required}
  local case=${2:?Case ID is required}
  local format=${3:?Jq format is requred}
  tr_api get_results_for_case "$run" "$case" | jq "$format"
}
export -f get_formatted_results_for_case

get_formatted_results() {
  local run=${1:?Run ID is required}
  local format='[ .[] | {id, test_id, status_id, comment} | select(.status_id!=null)]'

  tr_api get_results_for_run "$run" | jq -r '.[] | .test_id' \
  | parallel -n1 -I% -P"$TESTRAIL_API_THREAD" 'tr_api get_test %' \
  | jq -r '.case_id' \
  | env_parallel -n1 -I% -P"$TESTRAIL_API_THREAD" "get_formatted_results_for_case '$run' '%' '$format'" \
  | jq -s add
}
export -f get_formatted_results
