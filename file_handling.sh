#! /bin/bash

. "$commons_path/string_handling.sh"

### load_value_from_file
#
# Parametrization:
#  $1 path of the configuration file
#  $2 name of the variable to load
# Returns: value of the variable in the file, if it exits and is defined
function load_value_from_file()
{
        local val="$(grep "^\s*$2\s*\=" "$1" | awk -F = '{print $2}')"
        if [ -z "$val" ]; then
                return 1
        fi
        echo "$(sanitize_variable_quotes "$val")"
}

### load_value_from_file_to_variable
#
# Parametrization
#  $1 path of the configuration file
#  $2 variable name in file
#  $3 (optional) variable name in script - if omitted, $2 is used
#  $4 (optional) secret mode, how many characters of the secret are shown
function load_value_from_file_to_variable()
{
        local script_varname="${3:-$2}"
        local val="$(load_value_from_file "$1" "$2")"
        if [ ! -z "$val" ]; then
                # This bit weird cmd is required to force the creation of a global variable, not a local one (like "declare") 
                # See https://stackoverflow.com/questions/9871458/declaring-global-variable-inside-a-function
                IFS="" read $script_varname <<< "$val"
		if [ "$(type -t log)" = "function" ]; then
			local logval="$val"
			if [ ! -z "$4" ]; then
				logval="[Secret - begins with $(echo "$val" | cut -c1-5)]"
			fi
                	log " - $script_varname set to '$logval' (applying '$1', field '$2')" 2
        	fi
	fi
}
