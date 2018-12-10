#! /bin/bash

# Miscellaneous helper functions
#
# Author: DonTseTse
# Documentation https://github.com/DonTseTse/bash_commons/blob/master/helpers.md
# Dependencies: mktemp, rm, type, echo, bc, printf, cat, grep, head, tr, eval

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
		set_global_variable "${varname_prefix}stderr" "$(< $stderr_capture_filepath)"
		rm "$stderr_capture_filepath"
	else
		stdout_capture="$("${param_array[@]}")"
		status_capture=$?
	fi
	set_global_variable "${varname_prefix}return" "$status_capture"
	set_global_variable "${varname_prefix}stdout" "$stdout_capture"
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
# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/helpers.md#set_global_variable
# Dev note: used to be done with $> IFS="" read $1 <<< "$2"  <$ but this created problems for multi-line $2
#           see https://stackoverflow.com/questions/9871458/declaring-global-variable-inside-a-function for details about this method
function set_global_variable()
{
	[ -z "$1" ] && return 1
	printf -v $1 %s "$2"
}

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/helpers.md#get_array_element
function get_array_element
{
	[ -z "$1" ] && return 2
	[ -z "$2" ] && return 3
	local var_syntax
	printf -v var_syntax '${%s[%s]}' "$1" "$2"
        eval "[ -n \"$var_syntax\" ] && echo \"$var_syntax\""
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
