#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/api.sh"

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
export -f get_nested_sections

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
export -f get_nested_sections_by_name

get_nested_sections_by_id() {
  local project=${1:?Project ID is required}
  local suite=${2:?Suite ID is required}
  local parent_section_id=${3:?Parent section ID is required}
  local sections=$(get_sections $project $suite)
  echo $parent_section_id $(get_nested_sections "$sections" $parent_section_id) | tr ' ' '\n' | sort
}
export -f get_nested_sections_by_id

update_section() {
  local id=${1:?Section ID is required}
  local body=${2:?Section body is required}
  api_request "${url}/index.php?/api/v2/update_section/${id}" -X POST -d "$body" || error "Couln't update section with ID $id"
}
export -f update_section

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
  tr ' ' '\n' <<< $sections_id | parallel -q -j$threads edit_section {} $"$regexp"
}
