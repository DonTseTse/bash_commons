#! /bin/bash

############# Configuration

############# Preparation
# Refuse symlinks and get the absolute path of the commons directory (this file lies in ./tests/.), load dependancies
if [ -h "${BASH_SOURCE[0]}" ]; then echo "Error: called through symlink. Please call directly. Aborting..."; exit 1; fi
commons_path="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && dirname "$(pwd)")"

. "$commons_path/testing.sh"
. "$commons_path/helpers.sh"

initialize_test_session "helpers.sh functions"

############# Tests
echo "*** capture() ***"
echo "Since capture() is used in test(), successful tests imply it runs as intended"
configure_test 0 "A string"
test echo "A string"

echo "Test capture() stderr feature - running $> STDERR=1 capture mkdir /proc/test"
STDERR=1 capture mkdir /proc/test
configure_test 0 ""
[ "$stderr" = "mkdir: cannot create directory ‘/proc/test’: No such file or directory" ]
check_test_results "[ \"\$stderr\" = \"mkdir: cannot create directory ‘/proc/test’: No such file or directory\" ]" $? ""

echo "Test capture() variable name prefixes - running $> PREFIX=\"echo\" capture echo \"test\""
PREFIX="echo" capture echo "test"
configure_test 0 "test"
check_test_results "#Checking \$echo_return and \$echo_stdout"  "$echo_return" "$echo_stdout"

###
echo "*** is_function_defined() ***"
echo "The function test() is defined in the testing commons"
configure_test 0 ""
test is_function_defined "test"

configure_test 1 ""
test is_function_defined "unknown"

configure_test 1 ""
test is_function_defined ""

###
echo "*** set_global_variable() ***"
echo "set_global_variable() is used in capture(), just checking the error case here"
configure_test 1 ""
test set_global_variable

###
echo "*** calculate() ***"
echo "If no precision is specified, calculate() defaults to 3 decimals"
configure_test 0 "2.527"
test calculate "(2.5 * 2 * 4) / 10 + 0.52728888888"

configure_test 0 "2.527289"
test calculate "(2.5 * 2 * 4) / 10 + 0.52728888888" 6

echo "Unsignificant decimals are removed (otherwise the call below would return 5.000)"
configure_test 0 "5"
test calculate "(250 * 2) / 100"

echo "This applies likewise if an amount of decimals is specified"
configure_test 0 "5"
test calculate "(250 * 2) / 100" 10

configure_test 0 "5.72"
test calculate "(250 * 2) / 100 + 0.72" 10

echo "A number of decimals (2nd parameter) set to 0 or int returns a integer"
configure_test 0 "5"
test calculate "(250 * 2 + 0.22278999921) / 100" 0

configure_test 0 "5"
test calculate "(250 * 2 + 0.22278999921) / 100" "int"

###
echo "*** get_piped_input() ***"
configure_test 0 "test piped input"
stdout="$(echo "test piped input" | get_piped_input)"
check_test_results "\$(echo \"test piped input\" | get_piped_input)" $? "$stdout"

configure_test 0 ""
stdout="$(echo "" | get_piped_input)"
check_test_results "\$(echo \"\" | get_piped_input)" $? "$stdout"

###
echo "*** get_random_string() ***"
if [ -c /dev/urandom ]; then
	echo "/dev/urandom exists and is used. On machines without urandom get_random_string() should return status: 1, stdout: \"\" but this can't be tested here"
	# we have to cheat here, since it's random and hence unknown in advance
	stdout="$(get_random_string 30)"
	configure_test 0 "$stdout"
	[ ${#stdout} -eq 30 ]
	check_test_results "get_random_string 30" $? "$stdout"

	echo "If a length is not specified, get_random_string() defaults to 16"
	stdout="$(get_random_string)"
	configure_test 0 "$stdout"
	[ ${#stdout} -eq 16 ]
	check_test_results "get_random_string" $? "$stdout"
else
	echo "/dev/urandom not found, get_random_string() should always return status: 1, stdout: \"\". No need to test the other cases, they'd fail anyway."
	configure_test 1 ""
	test get_random_string
fi

###
echo "*** is_globbing_enabled() ***"
[ -z "$(echo $- | grep f)" ]
prev_glob_status=$?

set -f
echo " - Globbing disabled"
configure_test 1 ""
test is_globbing_enabled

set +f
echo " - Globbing enabled"
configure_test 0 ""
test is_globbing_enabled

[ $prev_glob_status -eq 1 ] && set -f
echo " - Globbing reset"

conclude_test_session
