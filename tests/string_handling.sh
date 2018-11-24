#! /bin/bash

############# Configuration

############# Preparation
# Refuse symlinks and get the absolute path of the commons directory (this file lies in ./tests/.), load dependancies
if [ -h "${BASH_SOURCE[0]}" ]; then echo "Error: called through symlink. Please call directly. Aborting..."; exit 1; fi
commons_path="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && dirname "$(pwd)")"

. "$commons_path/testing.sh"
. "$commons_path/string_handling.sh"

initialize_test_session "string_handling.sh functions"

############# Tests
echo "*** find_sed_operation_separator() ***"
configure_test 0 "/"
test find_sed_operation_separator "a" "b"

configure_test 0 "("
test find_sed_operation_separator "+%&" "/b"

configure_test 0 "_"
test find_sed_operation_separator "+%&" "/()='?!-"

configure_test 1 ""
test find_sed_operation_separator "+%&()='/?!-" "_:,;<>#]|{}@"

###
echo "*** get_sed_replace_regex() + sed ***"
configure_test 0 "s/some/awesome/g"
test get_sed_replace_expression "some" "awesome"

configure_test 0 "awesome string"
regex_res="$(echo "some string" | sed -e "$stdout")"
check_test_results "\$(echo \"some string\" | sed -e \"$stdout\")" $? "$regex_res"

configure_test 0 "s/some/replacement with space in/g"
test get_sed_replace_expression "some" 'replacement with space in'

configure_test 0 "replacement with space in string"
regex_res="$(echo "some string" | sed -e "$stdout")"
check_test_results "\$(echo \"some string\" | sed -e \"$stdout\")" $? "$regex_res"

configure_test 0 "s+input/path+modified/path+g"
test get_sed_replace_expression "input/path" "modified/path"

configure_test 0 "/modified/path/file"
regex_res="$(echo "/input/path/file" | sed -e "$stdout")"
check_test_results "\$(echo \"/input/path/file\" | sed -e \"$stdout\")" $? "$regex_res"

configure_test 0 "s/many/more/g"
test get_sed_replace_expression "many" "more"

configure_test 0 "more more more!"
regex_res="$(echo "many many many!" | sed -e "$stdout")"
check_test_results "\$(echo \"many many many\" | sed -e \"$stdout\")" $? "$regex_res"

configure_test 0 "s/many/more/"
test get_sed_replace_expression "many" "more" "first"

configure_test 0 "more many many!"
regex_res="$(echo "many many many!" | sed -e "$stdout")"
check_test_results "\$(echo \"many many many\" | sed -e \"$stdout\")" $? "$regex_res"

configure_test 0 "s/, others are removed//g"
test get_sed_replace_expression ", others are removed" ""

configure_test 0 "parts of this stay!"
regex_res="$(echo "parts of this stay, others are removed!" | sed -e "$stdout")"
check_test_results "\$(echo \"parts of this stay, others are removed!\" | sed -e \"$stdout\")" $? "$regex_res"

configure_test 0 "s/ /_/g"
test get_sed_replace_expression " " "_"

configure_test 0 "blanks_become_underscores"
regex_res="$(echo "blanks become underscores" | sed -e "$stdout")"
check_test_results "\$(echo \"blanks become underscores\" | sed -e \"$stdout\")" $? "$regex_res"

configure_test 1 ""
test get_sed_replace_expression "+%&()='/?!-" "_:,;<>#]|{}@" "awesome"

configure_test 2 ""
test get_sed_replace_expression "many" "more" "unknown"

###
echo "*** find_substring_index() ***"
configure_test 0 "1"
test find_substring "test string" "e"

configure_test 0 "2"
test find_substring "test string" "st"

configure_test 0 "-1"
test find_substring "test string" "f"

configure_test 0 "1"
test find_substring "2.345" "."

configure_test 0 "3"
test find_substring "2.3*45" '*'

configure_test 0 "3"
test find_substring "2.3?45" "?"

configure_test 0 "2"
test find_substring "22.27" "."

configure_test 0 "-1"
test find_substring "2227" "."

configure_test 0 "2"
test find_substring "22[27" "["

###
echo "*** is_string_a() ***"
relative_filepath="folder/file"
absolute_filepath="/tmp/test"

configure_test 0 "0"
test is_string_a "$relative_filepath" "absolute_filepath" 1

configure_test 0 "1"
test is_string_a "$relative_filepath" "!absolute_filepath" 1

configure_test 0 "1"
test is_string_a "$absolute_filepath" "absolute_filepath" 1

configure_test 0 "1"
test is_string_a "    $absolute_filepath" "absolute_filepath" 1

configure_test 0 "1"
test is_string_a "1" "integer" 1

configure_test 0 "0"
test is_string_a "1.2" "integer" 1

configure_test 0 "1"
test is_string_a "1.2" "!integer" 1

configure_test 0 "0"
test is_string_a "string" "integer" 1

configure_test 0 "0"
test is_string_a " 1" "integer" 1

configure_test 1 ""
test is_string_a

configure_test 2 ""
stdout="$(is_string_a "input" && echo "Never reached")"
check_test_results "\$(is_string_a \"input\" && echo \"Never reached\")" $? "$stdout"

configure_test 3 ""
test is_string_a "$relative_filepath" "unknown_test" 1

configure_test 0 "This is a integer: 2"
stdout="$(is_string_a "2" "integer" && echo "This is a integer: 2")"
check_test_results "\$(is_string_a \"2\" \"integer\" && echo \"This is a integer: 2\")" $? "$stdout"

configure_test 1 ""
stdout="$(is_string_a "text" "integer" && echo "This is a integer: 2")"
check_test_results "\$(is_string_a \"text\" \"integer\" && echo \"This is a integer: 2\")" $? "$stdout"

###
echo "*** get_string_bytelength() ***"
special_char_string="àla"
configure_test 0 "4"
test get_string_bytelength "$special_char_string"

configure_test 0 "3"
test get_string_bytelength "ala"

configure_test 0 "0"
test get_string_bytelength ""

###
echo "*** get_string_bytes() ***"
configure_test 0 "la"
test get_string_bytes "la"

configure_test 0 "$'303240la'"
test get_string_bytes "$special_char_string"

configure_test 0 ""
test get_string_bytes ""

configure_test 0 "  "
test get_string_bytes "  "

###
echo "*** sanitize_variable_quotes() ***"
configure_test 0 "test"
test sanitize_variable_quotes "\"test\""

configure_test 0 "test"
test sanitize_variable_quotes "'test'"

configure_test 0 "with space"
test sanitize_variable_quotes "'with space'"

configure_test 0 "te'st"
test sanitize_variable_quotes "'te'st'"

configure_test 0 "te\"'st"
test sanitize_variable_quotes "'te\"'st'"

configure_test 0 "te\"\'s t"
stdout="$(echo "'te\"\'s t'" | sanitize_variable_quotes)"
check_test_results "\$(echo \"'te\"\'s t'\" | sanitize_variable_quotes)" $? "$stdout"

configure_test 0 ""
test sanitize_variable_quotes

configure_test 0 ""
test sanitize_variable_quotes ""

configure_test 0 "   "
test sanitize_variable_quotes "   "

###
echo "*** trim() ***"
configure_test 0 "test"
test trim "   test   "

configure_test 0 "test"
stdout="$(echo "   test   " | trim)"
check_test_results "\$(echo \"   test   \" | trim)" $? "$stdout"

configure_test 0 ""
test trim ""

configure_test 0 ""
test trim "   "

###
echo "*** escape() ***"
configure_test 0 'escaped\/path\/to\/file'
stdout="$(echo 'escaped/path/to/file' | escape '/')"
check_test_results "\$(echo 'escaped/path/to/file' | escape '/')" $? "$stdout"

configure_test 0 'esc\aped\/p\ath\/to\/file'
stdout="$(echo 'escaped/path/to/file' | escape '/' 'a')"
check_test_results "\$(echo 'escaped/path/to/file' | escape '/' 'a')" $? "$stdout"

configure_test 0 ""
stdout="$(echo '' | escape '/')"
check_test_results "\$(echo '' | escape '/')" $? "$stdout"

configure_test 0 "   "
stdout="$(echo '   ' | escape '/')"
check_test_results "\$(echo '   ' | escape '/')" $? "$stdout"

conclude_test_session
