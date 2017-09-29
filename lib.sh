#!/bin/bash

user_email='rgabdulhakov@natera.com'
user_key='mV0DNRm3RFyFqd2lIvNp-z5nl5ZLIrC.B0LKyGy0z'
url='https://testrail.natera.com'

debug() {
  >&2 echo -e "\033[0;32m$@\033[0m"
}

warning() {
  >&2 echo -e "\033[1;33m$@\033[0m"
}

error() {
  >&2 echo -e "\033[0;31m$@\033[0m"
  exit 1
}

api_request() {
  curl -fs -H "Content-Type: application/json" -u "${user_email}:${user_key}" "$@"
}

get_case() {
  local id=${1:?Case ID is required}
  api_request "${url}/index.php?/api/v2/get_case/${id}" || error "Couldn't get case with ID $id"
}

get_cases_by_section() {
  local project=${1:?Project ID is required}
  local suite=${2:?Suite ID is required}
  local id=${3:?Section ID is required}
  api_request "${url}/index.php?/api/v2/get_cases/${project}&suite_id=${suite}&section_id=${id}" || error "Couldn't get cases by section ID $id"
}

update_case() {
  local id=${1:?Case ID is required}
  local body=${2:?Test body is required}
  api_request "${url}/index.php?/api/v2/update_case/${id}" -X POST -d "$body" || error "Couln't update case with ID $id"
}

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

edit_cases() {
  local cases_id="${1:?Cases ID are required}"
  local regexp="${2:?Regexp is required}"
  for id in $cases_id
  do
    edit_case $id "$regexp" &
  done
  wait
}

get_section() {
  local section_id=${1:?Section ID is required}
  api_request "${url}/index.php?/api/v2/get_section/${section_id}" || error "Couldn't get section $section"
}

get_sections() {
  local project=${1:?Project ID is required}
  local suite=${2:?Suite ID is required}
  api_request "${url}/index.php?/api/v2/get_sections/${project}&suite_id=${suite}" || error "Couldn't get sections for $project project and $suite suite"
}

update_section() {
  local id=${1:?Section ID is required}
  local body=${2:?Section body is required}
  api_request "${url}/index.php?/api/v2/update_section/${id}" -X POST -d "$body" || error "Couln't update case with ID $id"
}

edit_section() {
  local id=${1:?Section ID is required}
  local regexp="${2:? RegExp is required}"
  local body=$(sed "$regexp" <(get_case $id))
  update_section $id "$body" | jq -r '.id'
}

edit_sections() {
  local sections_id="${1:?Sections ID are required}"
  local regexp="${2:?Regexp is required}"
  for id in $sections_id
  do
    edit_section $id "$regexp" &
  done
  wait
}

get_nested_sections () {
  local sections="${1:?JSON sections are required}"
  local root_sections_ids="${2}"

  if [ -n "$root_sections_ids" ]
  then
    for root in $root_sections_ids
    do
      childron="$(echo "$sections" | jq -M ".[] | select(.parent_id == $root) | .id")"
      if [ -n "$childron" ]
      then
        echo $childron
        get_nested_sections "$sections" "$childron" &
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
    warning "There is no sections with name '$parent_section'"
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
  for nested_section_id in $nested_sections
  do
    get_cases_by_section $project $suite $nested_section_id | jq -M '.[] | .id' &
  done
  wait
}

get_nested_cases_by_section_id() {
  local project=${1:?Project ID is required}
  local suite=${2:?Suite ID is required}
  local section_id=${3:?Section ID is required}
  local nested_sections=$(get_nested_sections_by_id $project $suite $section_id)
  for nested_section_id in $nested_sections
  do
    get_cases_by_section $project $suite $nested_section_id | jq -M '.[] | .id' &
  done
  wait
}

_test() {
  get_nested_sections_by_name 4 19 'Activity logs'
  get_nested_sections_by_name 4 19 'Activity Log'
  get_nested_sections_by_id 4 19 21362
  get_nested_cases_by_section_id 4 19 21347 | wc -l
  get_nested_cases_by_section_name 4 19 EGG_DONOR | wc -l
  get_case 34534534
}

