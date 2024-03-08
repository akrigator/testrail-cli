#!/bin/bash

source "./api.sh"

apply_cmd() {
  local \
    cmd=${1:?Command} \
    input=${2:?Input}
  eval "$cmd" <<< "$input" 2> /dev/null \
  || ERROR "Execution of the \`$cmd\` command is failed with input:\n" "$input"
}

get_case() {
  local cases_ids="${*:?Case IDs are required}"
  local case_id=''
  tr ' ' '\n' <<< "$cases_ids" | while IFS= read -r case_id
  do
    api_get_case "$case_id"
  done | jq -s . | jq -c 'select(length > 0)'
}
export -f get_case

get_case_formatted() {
  get_case "${*:?Case id is required}" | jq -r '
    .[] |
    "C\(.id): \(.title)\n\n"+
    "Preconditions:\n\(.custom_preconds)\n\n"+
    "Steps:\n\(.custom_steps)\n\n"+
    "Expected Results:\n\(.custom_expected)\n\n"
  '
}
export -f get_case_formatted

edit_case() {
  local cmd=${1:?Comand is required}
  local cases_ids=${*:2}
  test "$cases_ids" \
  || ERROR "Case IDs are required" \
  && tr ' ' '\n' <<< "$cases_ids" | while IFS= read -r case_id
  do
    local case_before=''
    local case_after=''

    case_before="$(api_get_case "$case_id")"
    test "$case_before" \
    || ERROR "Fail on getting case $case_id" \
    || continue

    case_after="$(apply_cmd "$cmd" "$case_before")"
    test "$case_after" \
    || ERROR "Fail on editing case $case_id" \
    || break

    api_update_case "$case_id" "$case_after" | jq -c .id \
    || ERROR "Fail on uploading case $case_id update:\n" "$case_after"
  done
}
export -f edit_case

get_nested_cases_by_section_name() {
  local project=${1:?Project ID is required}
  local suite=${2:?Suite ID is required}
  local section_name="${3:?Section name is required}"
  get_nested_sections_by_name "$project" "$suite" "$section_name" | while IFS= read -r section
  do
    api_get_cases_from_section "$section" | jq -M '.[] | .id'
  done
}
export -f get_nested_cases_by_section_name

get_nested_cases_by_section_id() {
  local section_id=${1:?Section ID is required}
  get_nested_sections "$section_id" | while IFS= read -r section
  do
    api_get_cases_from_section "$section" | jq -M '.[] | .id'
  done
}
export -f get_nested_cases_by_section_id

backup_case() {
  local case_id="${1:?Case ID is required}"
  local backup_dir="${2:?Backup directory is required}"
  mkdir -p "$backup_dir"
  api_get_case "$case_id" | jq . > "${backup_dir}/${case_id}.json"
}
export -f backup_case

backup_nested_cases_from_section() {
  local project=${1:?Project ID is required}
  local suite=${2:?Suite ID is required}
  local section_id=${3:?Section ID is required}
  local backup_dir="${section_id}_backup_$(date "+%Y-%m-%d_%H:%M:%S")"
  local cases_id=$(get_nested_cases_by_section_id $section_id)
  INFO "$(dirname $backup_dir)"
  tr ' ' '\n' <<< $cases_id | parallel -j$threads backup_case {} "$backup_dir"
}
export -f backup_nested_cases_from_section
