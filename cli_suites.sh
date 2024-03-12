#!/bin/bash

get_suite() {
  local suite_id=${1:?Suite ID is required}
  ./api get_suite "$suite_id" \
  || ERROR "Fail to get suite for ID $suite_id" \
  || return $?
}