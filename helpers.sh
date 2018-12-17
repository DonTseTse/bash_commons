#! /bin/bash

# Miscellaneous helper functions
#
# Author: DonTseTse
# Documentation https://github.com/DonTseTse/bash_commons/blob/master/helpers.md
# Dependencies: mktemp, rm, echo, printf, grep, eval

##### Commons dependencies
# None

##### Functions
########### Command helpers
# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/helpers.md#capture
function capture()
{
	[ -z "$1" ] && return 1
	local status_capture stdout_capture stderr_capture_file varname_prefix param_array=("$@")
	[ -n "$VARNAME" ] && varname_prefix="${VARNAME}_" # interesting: $PREFIX has to be disambiguated with ${} in the assignment,
                                                	  # otherwise bash apparently thinks the variable continues because of the _
	if [ -n "$STDERR" ] && [ "$STDERR" = "1" ]; then
		stderr_capture_filepath=$(mktemp)
		stdout_capture="$(2>$stderr_capture_filepath "${param_array[@]}")"
		status_capture=$?
		printf -v "${varname_prefix}stderr" '%s' "$(< $stderr_capture_filepath)"
		rm "$stderr_capture_filepath"
	else
		stdout_capture="$("${param_array[@]}")"
		status_capture=$?
	fi
	printf -v "${varname_prefix}return" "$status_capture"
	printf -v "${varname_prefix}stdout" '%s' "$stdout_capture" 	# $> eval "${varname_prefix}stdout=\"$stdout_capture\"" <$ doesn't work in case of single quotes
	#DEBUG >&2 printf 'capture %s ... returns status: %i , stdout: %s\n' "${param_array[0]}" "$status_capture"  "$stdout_capture"
}

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/helpers.md#execute_working_directory_dependant_command
function execute_working_directory_dependant_command()
{
        local current_dir=$(pwd) status
        [ -d "$1" ] && cd "$1" || return 1
        $2 $3
        status=$?
        cd "$current_dir"
        return $status
}

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/helpers.md#conditional_exit
function conditional_exit()
{
        #if [[ ! "$1" =~ ^[0-9]*$ ]] || [ $1 -ne 0 ]; then
        if [ -z "$1" ] || [ ! "$1" = "0" ]; then
                local msg="${2:-\n}" code="${3:-1}"
                printf "$msg\n"
                [[ ! "$code" =~ ^[0-9]*$ ]] && code=1   # if code is non-numeric, exit complains
                exit $code
        fi
}

########### Variable handlers
# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/helpers.md#is_variable_defined
function is_variable_defined
{
	[ -z "$1" ] && return 2
	[ -v "$1" ] || eval "[ \${#$1[*]} -gt 0 ]" &> /dev/null
}

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/helpers.md#is_array_index
function is_array_index
{
	[ -z "$1" ] && return 2
	[ -z "$2" ] && return 3
	local array_indizes="$(printf '${!%s[@]}' "$1")"
        eval "echo \"$array_indizes\" | grep $2 &> /dev/null"
}

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/helpers.md#get_array_element
function get_array_element
{
	local is_array_error_map=([1]=1 [2]=3)
	is_variable_defined "$1" || return ${is_array_error_map[$?]}
	is_array_index_error_map=([1]=2 [3]=4)
	is_array_index "$1" "$2" || return ${is_array_index_error_map[$?]}
        eval "echo \"\${$1[$2]}\""
}

########### Misc
# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/helpers.md#calculate
function calculate()
{
        local res=$(echo "$1" | bc -l) ret=$? nb_decimals=${2:-3}
        [ $ret -ne 0 ] && return $ret
        [ "$nb_decimals" = "int" ] && nb_decimals=0
        local dot_char_idx="$(find_substring "$res" ".")"
        local char_idx=$((dot_char_idx + nb_decimals))          # can't be merged with previous line, idx wrong
        while [ "${res:$char_idx:1}" = "0" ] && [ "$nb_decimals" -gt 0 ]; do
                ((nb_decimals--))
                ((char_idx--))
        done
        printf "%.${nb_decimals}f" "$res"
}

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/helpers.md#is_globbing_enabled
function is_globbing_enabled()
{
        # why -z ? if the bash status contains f = no_glob is enabled. if the $(...) return is empty (= no f, globbing is enabled
        # since no no_glob disables it), -z makes the function return status 0/success
        [ -z "$(echo $- | grep f)" ]
}
