#!/bin/bash

apply_cmd() {
  local cmd=${1:?Command}
  eval "$cmd" 2> /dev/null \
  || ERROR "Execution of the \`$cmd\` command is failed" \
  || return $?
}

get_case() {
  local cases_ids=("${@:?Case IDs are required}")
  local rc=0
  local cases

  cases_ids+=("$(read_stdin)")

  cases="$(parallel -n1 -I% -d" " -r -P"$TESTRAIL_API_THREAD" 'tr_api get_case %' ::: "${cases_ids[@]}")"
  rc=$?

  jq -sc 'select(length > 0)' <<< "$cases" || ERROR "Fails collect cases to json array"

  test $rc -ne 0 && ERROR 'Fail to get some cases'
  return $rc
}

get_case_formatted() {
  local cases_ids=("${@}")

  cases_ids+=("$(read_stdin)")

  get_case "${cases_ids[@]}" | jq -r '
    .[] |
    "C\(.id): \(.title)\n\n"+
    "Preconditions:\n\(.custom_preconds)\n\n"+
    "Steps:\n\(.custom_steps)\n\n"+
    "Expected Results:\n\(.custom_expected)\n\n"
  '
  return $?
}

get_cases_from_section_single() {
  section_id="${1:?Section ID is required}"

  suite_id=$(get_section "$section_id" | jq -r .suite_id)
  test -n "$suite_id" || return 1

  project_id=$(get_suite "$suite_id" | jq -r .project_id)
  test -n "$project_id" || return 2

  tr_api get_cases_from_section "$project_id" "$suite_id" "$section_id"
}

get_cases_from_section() {
  local section_id=("${@}")

  section_id+=( "$(read_stdin)" )

  env_parallel -t -n1 -I% -d" " -r -P"$TESTRAIL_API_THREAD" get_cases_from_section_single % ::: "${section_id[@]}" \
  | jq -c '.[]' | jq -sc | jq -c 'select(length > 0)'
}

#  local project_id
#  local suite_id
#  suite_id="$(tr_api get_section "$section_id" | jq -r '.suite_id')"
#  test "$suite_id" \
#  || ERROR "No suite ID $section_id for section ID" \
#  || return $?
#
#  project_id="$(get_suite "$suite_id" | jq -r '.project_id')"
#  test "$project_id" \
#  || ERROR "No project ID $suite_id for suite ID" \
#  || return $?

  tr_api get_cases_from_section "$project_id" "$suite_id" "$section_id" \
  || ERROR "Couldn't get cases for section ID $section_id" \
  || return $?
}

edit_case() {
  local cmd=${1:?Comand is required}
  local cases_ids=("${@:2}")
  local cases_ids_std=()
  local rc=0
  local json_before
  local json_after

  cases_ids_std=("$(read_stdin)") \
  && cases_ids+=( "${cases_ids_std[@]}" )

  test ${#cases_ids[@]} -eq 0 \
  && ERROR "Cases IDs are required" \
  && return 1

  json_before=$(get_case "${cases_ids[@]}") || return $?
  json_after=$(apply_cmd "$cmd" <<< "$json_before") || return $?

  #vimdiff -c 'windo set wrap'  <(jq -r <<< "$json_before") <(jq -r <<< "$json_after")
  #diff --color=always  <(jq -r <<< "$json_before") <(jq -r <<< "$json_after")

  update_case <<< "$json_after" || return $?
}

get_nested_cases() {
  local sections_ids=("${@}")

  sections_ids+=( "$(read_stdin)" )

  test "${#sections_ids[@]}" -le 1 && ERROR "Nothing to get" && return 1

  get_nested_sections "${sections_ids[@]}" | get_cases_from_section | jq -M '.[] | .id'
}

backup_case() {
  local case_id="${1:?Case ID is required}"
  local backup_dir="${2:?Backup directory is required}"
  mkdir -p "$backup_dir"
  get_case "$case_id" | jq . > "${backup_dir}/${case_id}.json"
}

backup_nested_cases_from_section() {
  local project=${1:?Project ID is required}
  local suite=${2:?Suite ID is required}
  local section_id=${3:?Section ID is required}
  local backup_dir

  ERROR "NOT IMPLEMENTED" || return 1

  backup_dir="$(realpath)/${section_id}_backup_$(date "+%Y-%m-%d_%H:%M:%S")"
  get_nested_cases "$section_id" | while IFS= read -r case_id
  do
    backup_case "$case_id" "$backup_dir"
  done
}
