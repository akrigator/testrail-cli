# TestRail API bash

Extend functions based on standart methods of [TestRail API](http://docs.gurock.com/testrail-api2/start).

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

What things you need to install the software and how to install them

```
$ brew install jq
```

### Installing

Add to the bash_profile file and specify a correct path:

```shell
export TESTRAIL_API_USER="akrigator@gmail.com"
export TESTRAIL_API_KEY="mV0DXXm3RFyFqd2lIvNp-z5nl5ZLIrC.B0LKyGy0z"
export TESTRAIL_API_URL="http://localhost:8000"
export TESTRAIL_API_TREADS="16"
#export TESTRAIL_API_DEBUG="yes"
source ~/Develop/testrail-api/testrail_commands.sh
```


## Running the tests

Explain how to run the automated tests for this system

```shell
$ TESTRAIL_API_TEST
```

## Examples of use

The most examples are list in the TESTRAIL_API_TEST function, but here is one more things:

```shell
# Get case:
$ get_case 10081841
# Preview regex modifier before update:
$ get_case 10081841 | sed "s/ewq/EWQ/g" | jq -r .
# Preview json query modifier before update:
$ get_case 10081841 | jq '.[] | .custom_expected="ASD"'
# If new case looks good for you, now you may update case. The `get_case` return array, how ever `edit_case` process by one. Don't forget trim `.[] |` from your debugging script and escape characters: 
$ edit_case "jq  '.custom_expected=\"ASD\"'" 10081841
# Both get_case and edit_case may process several cases. If there is issue to get some case then the error is pushed to dedicated output, all succeed cases print out to standard output.
$ get_case 1 2 3

$ edit_cases 'sed s/di_george/di-george/g' "$(get_nested_cases_by_section_id 21065)" 
$ edit_cases 'sed s/                \\"AGE_BASED\\", *\\r\\n                \\"UNIFORM\\",\\r\\n/                \\"AGE_BASED\\",\\r\\n                \\"UNIFORM\\",\\r\\n/g' \
    "$(get_nested_cases_by_section_id 21066)" 
$ edit_cases 'sed s/, \\r\\n                    \\"XY\\": 1//g; s/\\"X\\": null/\\"XY\\": null/g; s/\\"X\\": -0.00001/\\"XY\\": -0.00001/g; s/\\"X\\": 1.00001/\\"XY\\": 1.00001/g;' "181819 182423 182576 182607 183381 183411 183350 183356 183497 183527" 
```

## Authors

* **Renat Gabdulkhakov**


