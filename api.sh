#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/output.sh"
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

api_request() {
  curl -s -H "Content-Type: application/json" -u "${user_email:?User is empty}:${user_key:?Password or key is empty}" "$@"
}
export -f api_request

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

get_section() {
  local section_id=${1:?Section ID is required}
  api_request "${url}/index.php?/api/v2/get_section/${section_id}" || error "Couldn't get section $section"
}
export -f get_section

get_sections() {
  local project=${1:?Project ID is required}
  local suite=${2:?Suite ID is required}
  api_request "${url}/index.php?/api/v2/get_sections/${project}&suite_id=${suite}" || error "Couldn't get sections for $project project and $suite suite"
}
export -f get_sections

update_case() {
  local id=${1:?Case ID is required}
  local body=${2:?Test body is required}
  api_request "${url}/index.php?/api/v2/update_case/${id}" -X POST -d "$body" || error "Couln't update case with ID $id"
}
export -f update_case

update_section() {
  local id=${1:?Section ID is required}
  local body=${2:?Section body is required}
  api_request "${url}/index.php?/api/v2/update_section/${id}" -X POST -d "$body" || error "Couln't update case with ID $id"
}
export -f update_section

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
  tr ' ' '\n' <<< $cases  | parallel -q -j$treads get_formated_results_for_case "$run" {} "$format" | jq -s add
}
export -f get_results_for_section

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
  tr ' ' '\n' <<< $cases_id | parallel -q -j$treads edit_case {} $"$regexp"
}
export -f edit_cases

edit_section() {
  local id=${1:?Section ID is required}
  local regexp="${2:?RegExp is required}"
  local body=$(sed "$regexp" <(get_section $id))
  update_section $id "${body:?Body is empty}" | jq -r '.id'
}
export -f edit_section

edit_sections() {
  local sections_id="${1:?Sections ID are required}"
  local regexp="${2:?Regexp is required}"
  tr ' ' '\n' <<< $sections_id | parallel -q -j$treads edit_section {} $"$regexp"
}

get_nested_sections () {
  local sections="${1:?JSON sections are required}"
  local root_sections_ids="${2}"

  if [ -n "$root_sections_ids" ]
  then
    for root in $root_sections_ids
    do
      children="$(echo "$sections" | jq -M ".[] | select(.parent_id == $root) | .id")"
      if [ -n "$children" ]
      then
        echo $children
        get_nested_sections "$sections" "$children" &
      fi
    done

    wait
  fi
}

get_nested_sections_by_name() {
  local project=${1:?Project ID is required}
  local suite=${2:?Suite ID is required}
  local parent_section="${3:?Parent section name ID required}"

  local sections=$(get_sections $project $suite)
  local parent_section_id="$(jq -M ".[] | select(.name == \"$parent_section\") | .id" <<< $sections)"
 
  if [ `wc -w <<< $parent_section_id` -eq 0 ]
  then
    error "There is no sections with name '$parent_section'"
  elif [ `wc -w <<< $parent_section_id` -eq 1 ]
  then
    get_nested_sections_by_id  $project $suite $parent_section_id
  else
    warning "Multiple sections are available with the '$parent_section' name:"
    warning "$parent_section_id"
  fi
}

get_nested_sections_by_id() {
  local project=${1:?Project ID is required}
  local suite=${2:?Suite ID is required}
  local parent_section_id=${3:?Parent section ID is required}

  local sections=$(get_sections $project $suite)
  echo $parent_section_id $(get_nested_sections "$sections" $parent_section_id) | tr ' ' '\n' | sort
}

get_nested_cases_by_section_name() {
  local project=${1:?Project ID is required}
  local suite=${2:?Suite ID is required}
  local section_name="${3:?Section name is required}"

  local nested_sections=$(get_nested_sections_by_name $project $suite "$section_name")
  tr ' ' '\n' <<< $nested_sections | parallel -q -j$treads get_cases_by_section $project $suite {} |  jq -M '.[] | .id'
}

get_nested_cases_by_section_id() {
  local project=${1:?Project ID is required}
  local suite=${2:?Suite ID is required}
  local section_id=${3:?Section ID is required}

  local nested_sections=$(get_nested_sections_by_id $project $suite $section_id)
  tr ' ' '\n' <<< $nested_sections | parallel -q -j$treads get_cases_by_section $project $suite {} | jq -M '.[] | .id'
}

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