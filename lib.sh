#!/bin/bash

export user_email="${TESTRAIL_API_USER:?Specify user email for TestRail}"
export user_key="${TESTRAIL_API_KEY:?Specify password or api-token for TestRail}"
export url="${TESTRAIL_API_URL:?Specify URL for TestRail}"
export treads="${TESTRAIL_API_TREADS:-16}"

debug() {
  >&2 echo -e "\033[0;32m$(sed 's/^/DEBUG: /g' <<< "$@")\033[0m"
}
export -f debug

warning() {
  >&2 echo -e "\033[1;33m$(sed 's/^/WARNING: /g' <<< "$@")\033[0m"
}
export -f warning

error() {
  >&2 echo -e "\033[0;31m$(sed 's/^/ERROR: /g' <<< "$@")\033[0m"
  return 1
}
export -f error

api_request() {
  curl -fs -H "Content-Type: application/json" -u "${user_email:?User is empty}:${user_key:?Password or key is empty}" "$@"
}
export -f api_request

get_case() {
  local id=${1:?Case ID is required}
  api_request "${url}/index.php?/api/v2/get_case/${id}" || error "Couldn't get case with ID $id"
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
}

