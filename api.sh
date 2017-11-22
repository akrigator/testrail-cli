#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/output.sh"
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

api_request() {
  curl -s -H "Content-Type: application/json" -u "${user_email:?User is empty}:${user_key:?Password or key is empty}" "$@"
}
export -f api_request
