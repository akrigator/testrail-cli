#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/api.sh"
source "$(dirname "${BASH_SOURCE[0]}")/api_sections.sh"

get_case() {
  local id=${1:?Case ID is required}
  local responce=$(api_request "${url}/index.php?/api/v2/get_case/${id}") # || error "Couldn't get case with ID $id"
  if [ "$responce" == '{"error":"Field :case_id is not a valid test case."}' ]
  then
    error "Case $id: $(jq .error <<< $responce)"
    return $?
  else
    echo "$responce"
  fi
}
export -f get_case

get_cases_by_section() {
  local project=${1:?Project ID is required}
  local suite=${2:?Suite ID is required}
  local id=${3:?Section ID is required}
  api_request "${url}/index.php?/api/v2/get_cases/${project}&suite_id=${suite}&section_id=${id}" || error "Couldn't get cases by section ID $id"
}
export -f get_cases_by_section

get_nested_cases_by_section_name() {
  local project=${1:?Project ID is required}
  local suite=${2:?Suite ID is required}
  local section_name="${3:?Section name is required}"
  local nested_sections=$(get_nested_sections_by_name $project $suite "$section_name")
  tr ' ' '\n' <<< $nested_sections | parallel -q -j$threads get_cases_by_section $project $suite {} |  jq -M '.[] | .id'
}
export -f get_nested_cases_by_section_name

get_nested_cases_by_section_id() {
  local project=${1:?Project ID is required}
  local suite=${2:?Suite ID is required}
  local section_id=${3:?Section ID is required}
  local nested_sections=$(get_nested_sections_by_id $project $suite $section_id)
  tr ' ' '\n' <<< $nested_sections | parallel -q -j$threads get_cases_by_section $project $suite {} | jq -M '.[] | .id'
}
export -f get_nested_cases_by_section_id

update_case() {
  local id=${1:?Case ID is required}
  local body=${2:?Test body is required}
  api_request "${url}/index.php?/api/v2/update_case/${id}" -X POST -d "$body" || error "Couln't update case with ID $id"
}
export -f update_case

edit_case() {
  local id=${1:?Case ID is required}
  local regexp="${2:? RegExp is required}"
  local body="$(sed "$regexp" <(get_case $id))"
  if [ -n "$body" ]
  then
    update_case $id "$body" | jq -r '.id'
  else
    error "Failed to edit case $id with $regexp"
  fi
}
export -f edit_case

edit_cases() {
  local cases_id="${1:?Cases ID are required}"
  local regexp="${2:?Regexp is required}"
  tr ' ' '\n' <<< $cases_id | parallel -q -j$threads edit_case {} $"$regexp"
}
export -f edit_cases