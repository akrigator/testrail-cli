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
  | while read -r test
  do
    tr_api get_test "$test"
  done | jq -r '.case_id' \
  | while read -r case
  do
    get_formatted_results_for_case "$run" "$case" "$format"
  done | jq -s add
}
export -f get_formatted_results
