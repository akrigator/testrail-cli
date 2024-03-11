#!/bin/bash

apply_cmd() {
  local cmd=${1:?Command}
  local input=${2:?Input}
  eval "$cmd" <<< "$input" 2> /dev/null \
  || ERROR "Execution of the \`$cmd\` command is failed with input:\n" "$input"
  return $?
}

get_case() {
  local cases_ids=("${@:?Case IDs are required}")
  local rc=0
  local cases

  cases="$(xargs -I{} -n1 -P"$TESTRAIL_API_THREAD" tr_api get_case {} <<< "${cases_ids[*]}")"
  rc=$?

  jq -sc '. | select(length > 0)' <<< "$cases" || ERROR "Fails collect cases to json array"

  test $rc -ne 0 && ERROR 'Fails get some cases'
  return $rc
}

get_case_formatted() {
  get_case "${*:?Case id is required}" | jq -r '
    .[] |
    "C\(.id): \(.title)\n\n"+
    "Preconditions:\n\(.custom_preconds)\n\n"+
    "Steps:\n\(.custom_steps)\n\n"+
    "Expected Results:\n\(.custom_expected)\n\n"
  '
  return $?
}

get_cases_from_section() {
  local section_id=${1:?Section ID is required}
  local project_id
  local suite_id

  suite_id="$(tr_api get_section "$section_id" | jq -r '.suite_id')"
  test "$suite_id" \
  || ERROR "No suite ID $section_id for section ID" \
  || return $?

  project_id="$(get_suite "$suite_id" | jq -r '.project_id')"
  test "$project_id" \
  || ERROR "No project ID $suite_id for suite ID" \
  || return $?

  tr_api get_cases_from_section "$project_id" "$suite_id" "$section_id" \
  || ERROR "Couldn't get cases for section ID $section_id" \
  || return $?
}

edit_case() {
  local cmd=${1:?Comand is required}
  local cases_ids=${*:2}
  test "$cases_ids" \
  || ERROR "Case IDs are required" \
  && tr ' ' '\n' <<< "$cases_ids" | while IFS= read -r case_id
  do
    local case_before=''
    local case_after=''

    case_before="$(get_case "$case_id" | jq -c '.[]')"
    test "$case_before" \
    || ERROR "Fail on getting case $case_id" \
    || continue

    case_after="$(apply_cmd "$cmd" "$case_before")"
    test "$case_after" \
    || ERROR "Fail on editing case $case_id" \
    || break

    tr_api update_case "$case_id" "'$case_after'" | jq -c '.id' \
    || ERROR "Fail on uploading case $case_id update:\n" "$case_after"
  done
}

get_nested_cases_by_section_name() {
  local project=${1:?Project ID is required}
  local suite=${2:?Suite ID is required}
  local section_name="${3:?Section name is required}"
  get_nested_sections_by_name "$project" "$suite" "$section_name" | while IFS= read -r section
  do
    tr_api get_cases_from_section "$section" | jq -M '.[] | .id'
  done
}

get_nested_cases_by_section_id() {
  local section_id=${1:?Section ID is required}
  get_nested_sections "$section_id" | while IFS= read -r section
  do
    tr_api get_cases_from_section "$section" | jq -M '.[] | .id'
  done
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
  get_nested_cases_by_section_id "$section_id" | while IFS= read -r case_id
  do
    backup_case "$case_id" "$backup_dir"
  done
}
