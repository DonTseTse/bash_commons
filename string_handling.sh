#! /bin/bash
# Written in 2018 by DonTseTse

# Dependencies: echo, grep, sed, printf
#               + bash modules: set
#
# Credits: get_string_bytelength() and get_string_bytes() are based on https://stackoverflow.com/questions/17368067/length-of-string-in-bash/31009961#31009961
#          find_substring() draws on explanations from https://stackoverflow.com/questions/5031764/position-of-a-string-within-a-string-using-linux-shell-script
#
# Note:
# - substring extraction: no specific functions for this since everything can be done with properly parametered variable expansion,
#                         see [TODO: fill URL]
#
# TODO: several distributed throughout the file
#
# Commons dependencies
. "$commons_path/helpers.sh" 		# for get_piped_input()

########### String transformation utilities
### escape
# Takes the piped input and escapes the char(s) given as parameter with backslashes
#
# Special care is taken to disable bash globbing to make sure that affected characters, typically '*', can be escaped properly
# At the end, the original globbing configuration is restored.
#
# Usage: - $> echo "path/to/file" | escape "/"
#          gives "path\/to\/file" on stdout
#
# Parametrization:
#  $1...n characters to escape
# Pipes: - stdin: read completely
#        - stdout: the escaped string
# Status: 0
function escape()
{
	local globbing_was_enabled=0
	is_globbing_enabled && set -f && globbing_was_enabled=1	# set -f adds the f (= no_glob) option = disables globbing
	local string="$(get_piped_input)" sep
	for escape_char in $@; do
		#[ "$escape_char" = '*' ] && $escape_char='\*'
		# direct injection is vital here because if the regex has double-quotes, the \ are interpreted here as well
		string="$(printf '%s' "$string" | sed -e $(get_sed_replace_expression "$escape_char" "$(printf '\\\\%s' "$escape_char")"))"
	done
	printf '%s' "$string"
	[ $globbing_was_enabled -eq 1 ] && set +f		# set +f removes the f option
}

### sanitize_variable_quotes
# In configuration files, if a definition is var="...", the loaded value is '"..."' (the double quotes are part of the value).
# This function removes them. It checks for single and double quotes.
#
# Parametrization:
#  $1 (optional) string to sanitize
# Pipes: - stdin: read completely if $1 is undefined/empty
#        - stdout: processed string
# Status: 0
function sanitize_variable_quotes()
{
        local input="${1:-$(get_piped_input)}"
	# 1st checks double quotes ", the 2nd checks simple/single quotes '
        [ -n "$(echo "$input" | grep "^\s*'" | grep "'\s*$")" ] && echo "$input" | sed -e "s/^\s*'//" -e "s/\(.*\)'\s*$/\1/" && return
        [ -n "$(echo "$input" | grep '^\s*"' | grep '"\s*$')" ] && echo "$input" | sed -e 's/^\s*"//' -e 's/\(.*\)"\s*$/\1/' && return
	echo "$input"
}

### trim
# Cut leading and trailing whitespace on either the provided parameter or the piped stdin
#
# Usage:
#  - Input as parameter: trimmed_string=$(trim "$string_to_trim")
#  - Piped input: trimmed_string=$(echo "$string_to_trim" | trim)
#
# Note: in the sed expressions, \s stands for [[:space:]]
#
# Parametrization:
#  $1 (optional) string to trim. If it's empty trim tries to get input from a eventual stdin pipe
# Pipes: - stdin: read completely if $1 is undefined/empty
#        - stdout: trimmed $1/stdin
# Status: 0 always, even if $1 and stdin are undefined/empty
function trim()
{
        local input="${1:-$(get_piped_input)}"
        [ -n "$input" ] && echo "$input" | sed -e 's/^\s*//' -e 's/\s*$//'
	return 0	# enforces status; otherwise if $input is an empty string, it would be 1 (from the failed [ -n ])
}

########### Misc string operatiors
### find_substring
# Finds the position of the first match of $2 in $1 (the start position of the match, to be precise)
# Returns -1 if $2 is not found inside $1.
#
# Inspired by https://stackoverflow.com/questions/5031764/position-of-a-string-within-a-string-using-linux-shell-script
#
# Parametrization:
#  $1 string to search in
#  $2 char/string to find
# Pipes: - stdin: ignored
#        - stdout: -1 if $2 is not found in $1
#                  the position of the first occurence of $2 in $1
# Status: 0
function find_substring()
{
	match="$(echo "$2" | escape '*' '?')"
	#DEBUG >&2 printf 'input: %s - match: %s - pattern: ${1%%%%%s*}\n' "$1" "$match" "$match"
	local substr="${1%%$match*}"
	[ ${#substr} -eq ${#1} ] && echo "-1" || echo ${#substr}
}

########### String property utilities
### is_string_a
# Checks string format
#
# The function is able to work in 2 modes depending on $3:
# - in "status" mode it may be used easily in instruction chains (see examples below); all that matters is that it
#   returns with status code 0 in case of success and a positive value in case of error. The error types "$1 empty"
#   "test type unknown" and "check failed" all have the same status code (1) and may hence not be distinguished by
#   the caller
# - in "stdout" mode the status code indicates only the execution success/error state, the result of the operation is
#   on stdout. There's hence no ambiguity on the status code signification
#
# Warning: be careful with inverted checks in combination with an empty $1. One might consider that
#                 is_string_a "" "!absolute_filepath"
#          should return success since an empty string is indeed not an absolute filepath, but because of the
#          protections it returns 1/error
#
# Usage examples: the status mode allows to use it in statement chains easily
#                       is_string_a "$potential_int" "integer" && echo "This is a integer: $potential_int"
#                 whereas the stdout mode gives a better control, adapted if $1 can't be trusted
#                       is_int=$(is_string_a "$unknown" "integer")
#			[ $? -eq 0 ] && [ $is_int -eq 1 ] && echo "This is a integer: $unknown"
#
# Parametrization:
#  $1 string to check
#  $2 check type: can be
#                 - 'absolute_filepath': checks if the first non-whitespace character of $1 is a '/'
#                                        No filesystem check is done. Works with inexistant filepaths
#                 - 'integer': checks if the string only contains numbers
#                 - TODO email etc
#                 Checks can be inverted using a prefixed ! => f.ex. to check for relative filepath,
#                 use '!absolute_filepath'
#  $3 output mode: - if omitted, set to an empty string or anything else than 1, the function is in "status mode"
#                    warning: use with care especially with inverted types! See the explanations above for details
#                  - 1 the function is in "stdout mode"
# Pipes: - stdin: ignored
#        - stdout: - empty in status mode
#                  - in stdout mode: the result of the check, if status is 0
#                    0 if the test type $2 failed on $1
#                    1 if the test type $2 passed for $1
# Status: - in status mode 0 if the test type $2 passed for $1
#                          1 used in 3 situations
#                            - if the test type $2 failed on $1
#                            - if $1 empty
#                            - if $2 is unknown
#                          2 if $2 is empty
#         - in stdout mode 0 if the check was performed (result is on stdout)
#                          1 if $1 is empty
#                          2 if $2 is empty
#                          3 if $2 is unknown
function is_string_a()
{
	[ -z "$1" ] && return 1
	[ -z "$2" ] && return 2
	local true_output=1 false_output=0 test_type="$2" test_exists=0
	# handle test inversion
	if [ "${test_type:0:1}" = "!" ]; then
		true_output=0 false_output=1
		test_type="${test_type:1}"
	fi
	local test_status=$true_output
	#  at this stage the value table is
	#                   |   true_output | false_output | return status (test_status)
	# non-inverted test |       1       |       0      | 1, becomes 0 if test passes
	#     inverted test |       0       |       1      | 0, becomes 1 if test passes

	# tests
	[ "$test_type" = "absolute_filepath" ] && test_exists=1 && [ -n "$(echo "$1" | grep "^\s*/")" ] && test_status=$false_output
	[ "$test_type" = "integer" ] && test_exists=1 && [[ "$1" =~ ^[0-9]*$ ]] && test_status=$false_output
	# TODO email etc

	# handle status based return
	[ -z "$3" ] || [ "$3" -ne "1" ] && return $test_status
	# not as status => verbose output. test succeeded?
	[ $test_status -eq $false_output ] && echo $true_output && return
	# reaching here = test failed or wrong test type
	[ $test_exists -eq 1 ] && echo $false_output && return
	[ $test_exists -eq 0 ] && return 3
}

### get_string_bytelength
#
# Parametrization:
#  $1 string to get the bytelength of
# Pipes: - stdin: ignored
#        - stdout: the bytelength
# Status: 0
function get_string_bytelength()
{
	# this is the shortest version found to work => if local is included to the assignment or if it's merged with the printf
	# the LC/LANG switch doesn't work
	local len
	LANG=C LC_ALL=C len="${#1}"
	printf "%d" "$len"
}

### get_string_bytes
# Returns byte representation of a string. Non-ascii chars like à,é,å,ê,etc. are transformed to their character code,
# é f.ex. is \303\251
#
# Parametrization:
#  $1 string to get the bytelength of
# Pipes: - stdin: ignored
#        - stdout: the bytelength
# Status: 0
function get_string_bytes()
{
	[ -n "$1" ] && LANG=C LC_ALL=C printf %q "$1"
	return 0	# enforces status; otherwise if $1 is an empty string, it would be 1 (from the failed [ -n ])
}

########### sed helpers
### get_sed_replace_expression
# Returns sed string replacement regex
#
# Usage: echo "some string" | sed -e $(get_sed_replace_expression "some" "awesome")
#        get_replace_regex() should provide the regex s/some/awesome/g => the command prints "awesome string"
#
# Parametrization:
#  $1 sed match regex/string
#  $2 sed replace string
#  $3 mode - if omitted, replace every occurence (aka global)
#          - "first" to replace only the first occurence
#          - "last" to replace the last occurence
# Pipes: - stdin: ignored
#        - stdout: if status is 0, the sed replace expression, empty otherwise
# Status: 0 if a regex was computed
#         1 if the function was unable to find a suitable separator character
#         2 if the mode $3 is unknown
function get_sed_replace_expression()
{
	local sep=$(find_sed_operation_separator "$1" "$2")
	[ -z "$sep" ] && return 1
        [ -z "$3" ] && echo "s${sep}${1}${sep}${2}${sep}g" && return		# returning here to make sure status is 0
        [ "$3" = "first" ] && echo "s${sep}${1}${sep}${2}${sep}" && return
	# TODO implement other regexes
	return 2
}

### find_sed_operation_separator
# Returns a separator character which is not in $1 and $2
#
# Parametrization:
#  $1 sed match pattern/string
#  $2 sed replace string
# Pipes: - stdin: ignored
#        - stdout: separator character if status is 0, empty otherwise
# Status: 0 found a separator character adapted to $1 and $2 found, returned on stdout
#         1 if none of the 23 characters available is suited
function find_sed_operation_separator()
{
        # eliminated alternatives: ` because of bash signification
        #                          § ° ç ¨ £ ≠ ¿ ´ ‘ ¶ – « ≤ because sed complains "delimiter character is not a single-byte character"
        #                          ^ $ . incompatible because of their "matching-everything" regex signification in grep, * because of the opposite
        #                          [ incompatible because alone & unescaped it leads to regex errors in grep
        local sep="/" sep_alternatives=("+" "%" "&" "(" ")" "=" "'" "?" "!" "-" "_" ":" "," ";" "<" ">" "#" "]" "|" "{" "}" "@") sep_alt_idx=0
        while [ -n "$(echo "$1" | grep "$sep")" ] || [ -n "$(echo "$2" | grep "$sep")" ]; do	# it's vital to quote $sep in the grep's here otherwise  <-|
		sep="${sep_alternatives[$sep_alt_idx]}"                                         # ? f.ex. is not matched (and may be others? not tested) <-|
		((sep_alt_idx++))
		[ $sep_alt_idx -eq ${#sep_alternatives[@]} ] && return 1
        done
        echo "$sep"
}
