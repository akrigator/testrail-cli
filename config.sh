#!/bin/bash

export user_email="${TESTRAIL_API_USER:?Specify user email for TestRail}"
export user_key="${TESTRAIL_API_KEY:?Specify password or api-token for TestRail}"
export url="${TESTRAIL_API_URL:?Specify URL for TestRail}"
export threads="${TESTRAIL_API_TREADS:-16}"
export debug_output="${TESTRAIL_API_DEBUG:-}"