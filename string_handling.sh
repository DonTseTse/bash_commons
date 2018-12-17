#! /bin/bash

# String handling functions
#
# Author: DonTseTse
# Dependencies: echo, grep, sed, printf + bash modules: set
#
# Credits: get_string_bytelength() and get_string_bytes() are based on https://stackoverflow.com/questions/17368067/length-of-string-in-bash/31009961#31009961
#          find_substring() draws on explanations from https://stackoverflow.com/questions/5031764/position-of-a-string-within-a-string-using-linux-shell-script
#
# Note:
# - substring extraction: no specific functions for this since everything can be done with properly parametered variable expansion,
#                         see https://github.com/DonTseTse/bash_misc/blob/master/documentation/string_variable_extraction.md
#
# Commons dependencies
[ -z "$commons_path" ] && echo "Bash commons - String handling: \$commons_path not set or empty, unable to resolve internal dependencies. Aborting..." && exit 1
[ ! -r "$commons_path/helpers.sh" ] && echo "Bash commons - String handling: unable to source helper functions at '$commons_path/helpers.sh' - aborting..." && exit 1
. "$commons_path/helpers.sh"                    # is_globbing_enabled()

########### String transformation utilities
# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/string_handling.md#escape
function escape()
{
	local globbing_was_enabled=0
	is_globbing_enabled && set -f && globbing_was_enabled=1		# set -f adds the f (= no_glob) option = disables globbing
	local string="$([ -p /dev/stdin ] && echo "$(cat)")" sep
	for escape_char in $@; do
		# to get "normal" escaping, the sed special chars have to be "disabled"
		escape_char=$(escape_sed_special_characters "$escape_char")
		# direct injection is vital here because if the regex has double-quotes, the \ are interpreted here as well
		string="$(printf '%s' "$string" | sed -e $(get_sed_replace_expression "$escape_char" "$(printf '\\\\%s' "$escape_char")"))"
	done
	printf '%s' "$string"
	[ $globbing_was_enabled -eq 1 ] && set +f			# set +f removes the f option
}

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/string_handling.md#sanitize_variable_quotes
function sanitize_variable_quotes()
{
	local input="${1:-$([ -p /dev/stdin ] && echo "$(cat)")}"
	# 1st checks double quotes ", the 2nd checks simple/single quotes '
	[ -n "$(echo "$input" | grep "^\s*'" | grep "'\s*$")" ] && echo "$input" | sed -e "s/^\s*'//" -e "s/\(.*\)'\s*$/\1/" && return
	[ -n "$(echo "$input" | grep '^\s*"' | grep '"\s*$')" ] && echo "$input" | sed -e 's/^\s*"//' -e 's/\(.*\)"\s*$/\1/' && return
	echo "$input"
}

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/string_handling.md#trim
# Note: in the sed expressions, \s stands for [[:space:]]
function trim()
{
        local input="${1:-$([ -p /dev/stdin ] && echo "$(cat)")}"
        [ -n "$input" ] && echo "$input" | sed -e 's/^\s*//' -e 's/\s*$//'
	return 0	# enforces status; otherwise if $input is an empty string, it would be 1 (from the failed [ -n ])
}

########### Misc string operators
# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/string_handling.md#find_substring
function find_substring()
{
	[ -z "$1" ] && return 1
        [ -z "$2" ] && return 2
	# escape bash's string expansion pattern special chars to get "normal" matching
	local match="$(echo "$2" | escape '*' '?' )" search_string="$1" offset="${3:-0}"
	#DEBUG >&2 printf 'input: %s - match: %s - pattern: ${1%%%%%s*}\n' "$1" "$match" "$match"
	[[ "$offset" =~ ^[0-9]+$ ]] && [ "$offset" -gt 0 ] && [ "$offset" -lt ${#1} ] && search_string="${1:$offset}"
	local substr="${search_string%%$match*}"
	[ ${#substr} -eq ${#search_string} ] && echo "-1" || echo "$(calculate "$offset + ${#substr}" "int")"
}

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/string_handling.md#get_absolute_path
# Dev note: this function is here and not in the filesystem collection because it doesn't require the provided paths to exist
function get_absolute_path()
{
        [ -z "$1" ] && return 1
        local folder="${2:-$(pwd)}" path="$1"
        is_string_a "$path" "!absolute_filepath" && path="$folder/$path"
        echo "$path"
}

########### String property utilities
# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/string_handling.md#is_string_a
function is_string_a()
{
	[ -z "$1" ] && return 2
        [ -z "$2" ] && return 3
	local type="$2" exists=0 passed=0 inversion=0
	if [ "${type:0:1}" = "!" ]; then
                inversion=1
                type="${type:1}"
        fi
	[ "$type" = "absolute_filepath" ] && exists=1 && [ -n "$(echo "$1" | grep "^\s*/")" ] && passed=1
        [ "$type" = "integer" ] && exists=1 && [[ "$1" =~ ^[0-9]*$ ]] && passed=1
        [ "$type" = "email" ] && exists=1 && [[ "$1" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$ ]] && passed=1      	# Credit: https://stackoverflow.com/questions/32291127/bash-regex-email
	local url_regex='^\s*(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]\s*$'				# Credit: https://stackoverflow.com/questions/3183444/check-for-valid-link-url
	[ "$type" = "url" ] && exists=1 && [[ "$1" =~ $url_regex ]] && passed=1
	[ $exists -eq 0 ] && return 4
	# inversion | test_passed | desired return status + explanation
 	#     0     |     0       | 1 | the test failed => error
	#     0     |     1       | 0 | the test succeeded => success
	#     1     |     0       | 0 | the test failed but that's the desired result => success
	#     1     |     1       | 1 | the test succeeded but since the opposite is desired => failure
	# this logic table corresponds to:
	[ $passed -ne $inversion ]
}

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/string_handling.md#get_string_bytelength
function get_string_bytelength()
{
	# this is the shortest version found to work => if local is included to the assignment or if it's merged with the printf
	# the LC/LANG switch doesn't work
	local len
	LANG=C LC_ALL=C len="${#1}"
	printf "%d" "$len"
}

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/string_handling.md#get_string_bytes
function get_string_bytes()
{
	[ -n "$1" ] && LANG=C LC_ALL=C printf %q "$1"
	return 0	# enforces status; otherwise if $1 is an empty string, it would be 1 (from the failed [ -n ])
}

########### sed helpers
# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/string_handling.md#get_sed_extract_expression
function get_sed_extract_expression()
{
	local sep=$(find_sed_operation_separator "$1") marker="$1"
        [ -z "$sep" ] && return 1
	[ "$2" = "before" ] && [ "$3" = "first" ] && echo "s${sep}${marker}.*${sep}${sep}" && return
	[ "$2" = "before" ] && [ "$3" = "last" ] && echo "s${sep}\\(.*\\)${marker}.*${sep}\\1${sep}" && return
	[ "$2" = "after" ] && [ "$3" = "first" ] && echo "s${sep}^[^${marker}]*${marker}${sep}${sep}" && return
	[ "$2" = "after" ] && [ "$3" = "last" ] && echo "s${sep}.*${marker}${sep}${sep}" && return
	return 2
}

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/string_handling.md#get_sed_replace_expression
function get_sed_replace_expression()
{
	local sep=$(find_sed_operation_separator "$1" "$2")
	[ -z "$sep" ] && return 1
        [ -z "$3" ] && echo "s${sep}${1}${sep}${2}${sep}g" && return		# returning here to make sure status is 0
        [ "$3" = "first" ] && echo "s${sep}${1}${sep}${2}${sep}" && return
        [ "$3" = "last" ] && echo "s${sep}\\(.*\\)${1}${sep}\1${2}${sep}" && return
	return 2
}

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/string_handling.md#find_sed_operation_separator
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

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/string_handling.md#escape_sed_special_characters
function escape_sed_special_characters()
{
        echo "$1" | sed -e 's/\./\\\./' -e 's/\+/\\\+/' -e 's/\?/\\\?/' -e 's/\*/\\\*/' -e 's/\[/\\\[/' -e 's/\]/\\\]/' -e 's/\^/\\\^/' -e 's/\$/\\\$/'
}

########### misc
# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/string_handling.md#get_random_string
function get_random_string()
{
        [ ! -c "/dev/urandom" ] && return 1
        local length="${1:-16}"
        echo "$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c $length)"
}
