#! /bin/bash
# Helper function tests
#
# Author: DonTseTse

############# Configuration
#

############# Preparation
# Refuse symlinks and get the absolute path of the commons directory (this file lies in ./tests/.), load dependancies
if [ -h "${BASH_SOURCE[0]}" ]; then echo "Error: called through symlink. Please call directly. Aborting..."; exit 1; fi
commons_path="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && dirname "$(pwd)")"
set -e
. "$commons_path/testing.sh"
. "$commons_path/helpers.sh"
set +e
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
VARNAME="echo" capture echo "test"
configure_test 0 "test"
check_test_results "#Checking \$echo_return and \$echo_stdout"  "$echo_return" "$echo_stdout"

echo "*** execute_working_directory_dependant_command() ***"
configure_test 0 "/tmp"
test execute_working_directory_dependant_command "/tmp" "pwd"

configure_test 1 ""
test execute_working_directory_dependant_command "/unexistant" "pwd"

configure_test 127 ""
test execute_working_directory_dependant_command "/tmp" "unknown"

echo "*** conditional_exit() ***"
stdout="$(conditional_exit 1 "Dead!" 22)"
check_test_results "\$(conditional_exit 1 \"Dead!\" 22)" 22 "$stdout"

###
echo "*** is_command_defined() ***"
configure_test 0 ""
test is_command_defined "tail"

configure_test 1 ""
test is_command_defined "unknown"

###
echo "*** is_function_defined() ***"
echo "The function test() is defined in the testing commons"
configure_test 0 ""
test is_function_defined "test"

configure_test 1 ""
test is_function_defined "unknown"

configure_test 1 ""
test is_function_defined ""

configure_test 1 ""
test is_function_defined "tail"

###
echo "*** is_array_defined() ***"
arr=("1st" "2nd")
echo " - \$> arr=(\"1st\" \"2nd\") <\$"
configure_test 0 ""
test is_array_defined "arr"

configure_test 1 ""
test is_array_defined "unexistant"

configure_test 2 ""
test is_array_defined ""

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


###
echo "*** set_global_variable() ***"
echo "set_global_variable() is used in capture(), just checking the error case here"
configure_test 1 ""
test set_global_variable

echo "*** get_array_element() ***"
echo ' - $> arr=("1st" "2nd" "3rd")'
arr=("idx0" "idx1" "idx2")
configure_test 0 "idx1"
test get_array_element "arr" 1

configure_test 1 ""
test get_array_element "arr" 5

configure_test 1 ""
test get_array_element "unexistant" 1

configure_test 2 ""
test get_array_element ""

configure_test 3 ""
test get_array_element "arr"

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

configure_test 0 "0.000"
test calculate ""

###
echo "*** get_piped_input() ***"
configure_test 0 "test piped input"
stdout="$(echo "test piped input" | get_piped_input)"
check_test_results "\$(echo \"test piped input\" | get_piped_input)" $? "$stdout"

configure_test 0 ""
stdout="$(echo "" | get_piped_input)"
check_test_results "\$(echo \"\" | get_piped_input)" $? "$stdout"

conclude_test_session
