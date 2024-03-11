#!/bin/bash

get_nested_sections () {
  local root_sections_ids="${1:?Multyline list of root sections}"
  local suite project sections children
  while IFS= read -r root
  do
    suite="$(tr_api get_section "$root" | jq -r '.suite_id')" \
    && test "$suite" \
    && project="$(tr_api get_suite "$suite" | jq -r '.project_id')" \
    && test "$project" \
    && sections="$(tr_api get_sections "$project" "$suite")" \
    && test "$sections" \
    && children="$(jq -M ".[] | select(.parent_id == $root) | .id" <<< "$sections")" && test "$children" \
    && echo "$root" "$children" \
    && get_nested_sections "$children"
  done <<< "$root_sections_ids" | tr ' ' '\n' | sort -u
}
export -f get_nested_sections

get_nested_sections_by_name() {
  local project=${1:?Project ID is required}
  local suite=${2:?Suite ID is required}
  local section_name="${3:?Parent section name required}"
  local sections
  local section_ids
  local section_ids_count
  sections=$(tr_api get_sections "$project" "$suite") \
  && section_ids="$(jq -M ".[] | select(.name == \"$section_name\") | .id" <<< "$sections")" \
  && section_ids_count="$(wc -w <<< "$section_ids")" \
  && test "$section_ids_count" -eq 1 \
  && get_nested_sections "$section_ids"  \
  || (test "$section_ids_count" -eq 0 \
      && ERROR "Project $project suite $suite doesn't have section with name '$section_name'") \
  || (test "$section_ids_count" -gt 1 \
      && WARNING "Multiple sections are available with the '$section_name' name: \n$section_ids")
}
export -f get_nested_sections_by_name

edit_section() {
  local \
    id=${1:?Section ID is required} \
    cmd=${2:?Comand is required} \
    body \
    new_body \
  && body=$(tr_api get_section "$id") \
  && new_body=$(eval "$cmd" <<< "$body") \
  && test "$new_body" \
  || ERROR "Fail apply the '$cmd' to:\n" "$body" \
  && tr_api update_section "$id" "$new_body" > /dev/null
}
export -f edit_section