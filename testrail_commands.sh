#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/api_cases.sh"
source "$(dirname "${BASH_SOURCE[0]}")/api_sections.sh"
source "$(dirname "${BASH_SOURCE[0]}")/api_results.sh"

TESTRAIL_test() {
  info 'Check error if unexist case is edited'
  edit_case 0 's///g'
  info "Check error if unexist case is requested"
  get_case 34534534
  info "Check error if unexist name section is requested"
  get_nested_sections_by_name 4 19 'Activity logs'
  info "Check warning if multiple sections are available with same name"
  get_nested_sections_by_name 4 19 'Activity Log'
  info "Check error if unexist name section is requested"
  get_nested_sections_by_id 4 19 9999999
  info "Get nested sectios for section with id 21096: 21096, 21099, 21101, 21102, 21145, 21146, 21147, 21148, 21153, 21154, 21155, 21156, 21526"
  get_nested_sections_by_id 4 19 21096
  info "Count of nested cases for the section id"
  get_nested_cases_by_section_id 4 19 21347 | wc -l
  info "Count of nested cases for the section name"
  get_nested_cases_by_section_name 4 19 EGG_DONOR | wc -l
  info "Get failed tests in the section of plan"
  get_results_for_section 4 19 1808 21064 | jq '.[] | select((.status_id!=1) and (.comment |contains("Connection reset") |not))'
}