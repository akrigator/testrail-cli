# TestRail API bash

Extend functions based on standart methods of [TestRail API](http://docs.gurock.com/testrail-api2/start).

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

What things you need to install the software and how to install them

```
$ brew install parallel jq
```

### Installing

Add to the bash_profile file and specify a correct path:

```
export TESTRAIL_API_USER="rgabdulhakov@natera.com"
export TESTRAIL_API_KEY="mV0DXXm3RFyFqd2lIvNp-z5nl5ZLIrC.B0LKyGy0z"
export TESTRAIL_API_URL="https://testrail.natera.com"
export TESTRAIL_API_TREADS="16"
#export TESTRAIL_API_DEBUG="yes"
source ~/Develop/testrail-api/testrail_commands.sh
```


## Running the tests

Explain how to run the automated tests for this system

```
$ TESTRAIL_test
```

## Deployment

Add additional notes about how to deploy this on a live system

## Examples of use

The most examples are list in the TESTRAIL_test function6 but here one more things:

```
$ source testrail_commands.sh
$ edit_cases "$(get_nested_cases_by_section_id 4 19 21065)" 's/di_george/di-george/g'
$ edit_cases "$(get_nested_cases_by_section_id 4 19 21066)" 's/                \\"AGE_BASED\\", *\\r\\n                \\"UNIFORM\\",\\r\\n/                \\"AGE_BASED\\",\\r\\n                \\"UNIFORM\\",\\r\\n/g'
$ edit_cases "181819 182423 182576 182607 183381 183411 183350 183356 183497 183527" 's/, \\r\\n                    \\"XY\\": 1//g; s/\\"X\\": null/\\"XY\\": null/g; s/\\"X\\": -0.00001/\\"XY\\": -0.00001/g; s/\\"X\\": 1.00001/\\"XY\\": 1.00001/g;'
```

## Authors

* **Renat Gabdulkhakov**


