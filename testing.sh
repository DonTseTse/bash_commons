#! /bin/bash
# Written in 2018 by DonTseTse
#
# Dependencies: echo, printf
#
# Commons dependencies
. "$commons_path/helpers.sh"    	# for capture()
. "$commons_path/string_handling.sh"    # for is_string_a()

### initialize_test_session
#
# Parametrization:
#  $1 name of the test session
# Pipes: - stdin: ignored
#        - stdout: empty
# Status: 0
# Globals: $test_counter, $test_error_count, $test_session_name
function initialize_test_session()
{
	test_counter=1
	test_error_count=0
	test_session_name="$1"
}

### configure_test
#
# Parametrization:
#  $1 expected return status
#  $2 expected stdout
# Pipes: - stdin: ignored
#        - stdout: empty
# Status: 0
# Globals: $expected_return, $expected_stdout
function configure_test()
{
	expected_return="$1"
	expected_stdout="$2"
}

### test
# Run a test with results captured and compared to $expected_<return|stdout>, see configure_test()
#
# Parametrization:
#  $1 ... command to test ($1 is the command)
# Pipes: - stdin: ignored
#        - stdout: test results printed by check_test_results()
# Status: 0
# Globals: $expected_return, $expected_stdout, $test_counter and $test_error_count  via check_test_results()
function test()
{
	local param_array=("$@") i logging_param_array=("${param_array[@]}")
	# Quote all parameters for logging to maintain eventual whitespace. Not required for numeric ones
	# no need to distinguish counter and idx here since it's fct params with the $1, $2, etc... => param_array elements have natural indexation
	for i in ${!param_array[*]}; do
		[ $i -eq 0 ] && continue	# don't quote the command
		is_string_a "${param_array[i]}" "!integer" && logging_param_array[i]="'${param_array[i]}'"
	done
	capture "${param_array[@]}"
	check_test_results "${logging_param_array[*]}" $return "$stdout"
}

### check_test_results
# Checks if $2 corresponds to $expected_status and $3 to $expect_stdout and prints result
#
# Parametrization:
#  $1 command, as a properly quoted string
#  $2 command return status
#  $3 command stdout
# Pipes: - stdin: ignored
#        - stdout: test result
# Status: 0
# Globals: $expected_return, $expected_stdout, $test_counter
function check_test_results()
{
	printf ' - Test %i: $> %s <$ should return status: %i, stdout: "%s" ' $test_counter "$1" $expected_return  "$expected_stdout"
	((test_counter++))
	[ "$2" -eq "$expected_return" ] && [ "$3" = "$expected_stdout" ] && echo "[OK]" && return
	((test_error_count++))
	printf "[Error]\n   It returned status $2, stdout '$3'\n"
}

### conclude_test_session
# Prints a summary and returns the status 0/success if all tests passed, 1 otherwise
#
# Parametrization: -
# Pipes: - stdin: ignored
#        - stdout: test session summary
# Status: 0 if all test succeeded or if there were no tests
#         1 if at least one of the tests failed
# Globals: $test_counter $test_error_count
function conclude_test_session()
{
	local nb_tests=$((test_counter - 1))
	[ $nb_tests -eq 0 ] && echo "No tests run" && return
	local res_msg="all passed"
	[ $test_error_count -gt 0 ] && res_msg="$test_error_count failed"
	echo "Session '$test_session_name': $nb_tests test(s) executed, $res_msg"
	[ "$test_error_count" -eq 0 ]
}
