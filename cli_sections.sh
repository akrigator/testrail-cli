#!/bin/bash

get_section() {
  local sections_ids=("${@}")
  sections_ids+=("$(read_stdin)")
  env_parallel -t -n1 -I% -d " " -r -P"$TESTRAIL_API_THREAD" './api get_section %' ::: "${sections_ids[@]}" \
  | jq -s | jq -c 'select(length > 0)'
}

get_sections() {
  local project_id=${1:?Project ID is required}
  local suite_id=${2:?Suite ID is required}
  ./api get_sections "$project_id" "$suite_id" \
  || ERROR "Fail to get sections for suite $suite_id in project $project_id" \
  || return $?
}

resolve_subsections() {
    local section_id="${1:?Section IS is required}"
    local suite
    local project

    suite=$(get_section "$section_id" | jq -r .suite_id)
    test "$suite" || return 1
    project=$(get_suite "$suite" | jq -r .project_id)
    test "$project" || return 2
    sections=$(get_sections "$project" "$suite")
    test "$sections" || return 3
    jq ".[] | select(.parent_id==$section_id) | .id" <<< "$sections"
}

get_subsections() {
  local root_ids=("${@}")

  root_ids+=( "$(read_stdin)" )

  env_parallel -n1 -I% -d" " -r -P"$TESTRAIL_API_THREAD" resolve_subsections % ::: "${root_ids[*]}"
}

get_nested_sections() {
  local sections_ids=("${@}")
  local roots
  sections_ids+=( "$(read_stdin)" )

  test "${#sections_ids[@]}" -le 1 && ERROR empty && return 1

  roots="$(env_parallel -n1 -I% -d" " -r -P"$TESTRAIL_API_THREAD" get_section % ::: "${sections_ids[@]}" | jq .id)"

  echo "$roots"

  get_subsections <<< "$roots" | env_parallel -r -n1 -I% -P"$TESTRAIL_API_THREAD" get_nested_sections %
}

find_section() {
  local project=${1:?Project ID is required}
  local suite=${2:?Suite ID is required}
  local section_name="${3:?Parent section name required}"
  local section_ids=()
  local rc=0

  section_ids=("$(get_sections "$project" "$suite" | jq -M ".[] | select(.name == \"$section_name\") | .id")")

  test "$(wc -w <<< "${section_ids[@]}")" -eq 0 \
  && ERROR "No section with name '$section_name'" \
  && return 1

  echo "${section_ids[@]}"

  test "$(wc -w <<< "${section_ids[@]}")" -gt 1 \
  && WARNING "Found multiple sections with name '$section_name'" \
  && rc=2

  return "$rc"
}

edit_section() {
  local \
    id=${1:?Section ID is required} \
    cmd=${2:?Comand is required} \
    body \
    new_body \
  && body=$(./api get_section "$id") \
  && new_body=$(eval "$cmd" <<< "$body") \
  && test "$new_body" \
  || ERROR "Fail apply the '$cmd' to:\n" "$body" \
  && ./api update_section "$id" "$new_body" > /dev/null
}
