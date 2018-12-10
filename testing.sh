#! /bin/bash

# Testing functions
#
# Author: DonTseTse
# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/testing.md
# Dependencies: echo, printf

##### Commons dependencies
[ -z "$commons_path" ] && echo "Bash commons - Testing: \$commons_path not set or empty, unable to resolve internal dependencies. Aborting..." && exit 1
[ ! -r "$commons_path/helpers.sh" ] && echo "Bash commons - Testing: unable to source helper functions at '$commons_path/helpers.sh' - aborting..." && exit 1
. "$commons_path/helpers.sh"    	# for capture()
[ ! -r "$commons_path/string_handling.sh" ] && echo "Bash commons - Testing: unable to source string handling function at '$commons_path/string_handling.sh' - aborting..." && exit 1
. "$commons_path/string_handling.sh"    # for is_string_a()

##### Functions
# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/testing.md#initialize_test_session
function initialize_test_session()
{
	test_counter=1
	test_error_count=0
	test_session_name="$1"
}

#Documentation: https://github.com/DonTseTse/bash_commons/blob/master/testing.md#configure_test
function configure_test()
{
	expected_return="$1"
	expected_stdout="$2"
}

#Documentation: https://github.com/DonTseTse/bash_commons/blob/master/testing.md#test
function test()
{
	local param_array=("$@") i logging_param_array=("${param_array[@]}")
	# Quote all parameters for logging to maintain eventual whitespace. Not required for numeric ones
	# no need to distinguish counter and idx here since it's fct params with the $1, $2, etc... => param_array elements have natural indexation
	for i in ${!param_array[*]}; do
		[ $i -eq 0 ] && continue	# don't quote the command
		is_string_a "${param_array[i]}" "!integer" && logging_param_array[i]="\"${param_array[i]}\""
	done
	[ -z "$(type -t ${param_array[0]})" ] && check_test_results "" > /dev/null && echo " - test() error: command ${logging_param_array[0]} unknown" && return
	capture "${param_array[@]}"
	check_test_results "${logging_param_array[*]}" $return "$stdout"
}

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/testing.md#check_test_results
function check_test_results()
{
	printf ' - Test %i: $> %s <$ should return status: %i, stdout: "%s" ' $test_counter "$1" $expected_return  "$expected_stdout"
	((test_counter++))
	[ -n "$2" ] && [[ "$2" =~ ^[0-9]*$ ]] && [ "$2" -eq "$expected_return" ] && [ "$3" = "$expected_stdout" ] && echo "[OK]" && return
	((test_error_count++))
	printf '[Error]\n   It returned status %s, stdout "%s"\n' "$2" "$3"
}

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/testing.md#conclude_test_session
function conclude_test_session()
{
	local nb_tests=$((test_counter - 1))
	[ $nb_tests -eq 0 ] && echo "No tests run" && return
	local res_msg="all passed"
	[ $test_error_count -gt 0 ] && res_msg="$test_error_count failed"
	echo "Session '$test_session_name': $nb_tests test(s) executed, $res_msg"
	[ "$test_error_count" -eq 0 ]
}
