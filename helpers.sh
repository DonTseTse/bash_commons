#! /bin/bash
# Written in 2018 by DonTseTse
#
# Dependencies: mktemp, rm, type, read, echo, bc, printf, grep, head, tr

### capture
# Collects stdout, stderr (if $STDERR = 1) and the return status of a command and copies them into
# global variables
#
# Capture status and stdout to the default global output variable names:
#	capture echo "Hello world"
# will define the global variables $return=0 and $stdout="Hello world"
# To prefix the variable names in case confusion might arise, use the global variable $PREFIX.
# The easiest way is to set it in the call context (PREFIX is only defined for that command):
#       PREFIX="echo" capture echo "Hello world"
# defines the global variable $echo_return=0 and $echo_stdout="Hello world"
#
# To capture stderr use the global variable $STDERR and set it to 1. Like $PREFIX, the easiest
# is to set it in the call context - let's take an example where there's some stderr for sure,
# f.ex. the attempt to create a folder inside /proc which is never writeable, not even to root:
#      STDERR=1 capture mkdir /proc/test
# will define the global variables $return, $stdout and $stderr with the mkdir error message
# If a $PREFIX is defined, the global stderr variable is called $PREFIX_stderr.
#
# Parametrization:
#  $1 ... n Call to capture ($1 is the command)
#  $STDERR if defined and = 1, stderr is captured
#  $PREFIX if it's a non empty-string, the global output variables names are prefixed - see examples above
# Pipes: - stdin: input ignored, used internally via set_global_variable()
#        - stdout: empty
# Return: - status: always 0, stdout is empty
# Globals: -if $PREFIX is not defined or empty: $return, $stdout and $stderr (if $STDERR=1)
#          -if $PREFIX is a non-empty string: $PREFIX_return, $PREFIX_stdout and $PREFIX_stderr (if $STDERR=1)
function capture()
{
	local status_capture stdout_capture stderr_capture_file prefix param_array=("$@")
	[ -n "$PREFIX" ] && prefix="${PREFIX}_" # interesting: $PREFIX has to be disambiguated with ${} in the assignment,
                                                # otherwise bash apparently thinks the variable continues because of the _
	if [ -n "$STDERR" ] && [ "$STDERR" = "1" ]; then
		stderr_capture_filepath=$(mktemp)
		stdout_capture="$(2>$stderr_capture_filepath "${param_array[@]}")"
		status_capture=$?
		set_global_variable "${prefix}stderr" "$(< $stderr_capture_filepath)"
		rm "$stderr_capture_filepath"
	else
		stdout_capture="$("${param_array[@]}")"
		status_capture=$?
	fi
	set_global_variable "${prefix}return" "$status_capture"
	set_global_variable "${prefix}stdout" "$stdout_capture"
	#>&2 printf 'capture %s ... returns status: %i , stdout: %s\n' "${param_array[0]}" "$status_capture"  "$stdout_capture"
}

### is_function_defined
#
# Usage example: use in instruction chains to avoid potential "command ... unknown" errors, like f.ex.
#                       is_function_defined "log" && log "..."
#                will only call log if it's defined
#
# Parametrization:
#  $1 name of the function
# Pipes: - stdin: ignored
#        - stdout: empty
# Status: 0 if function exists
#         1 if function doesn't exist
function is_function_defined()
{
	[ "$(type -t $1)" = "function" ]
}

### set_global_variable
# Sets the variable called $1 with the value $2 on global level (i.e. accessible everywhere in the execution context)
# Parametrization:
#  $1 variable name - the usual bash variable name restrictions apply
#  $2 value
# Pipes: - stdin: ignored, used internally in closed loop via read
#        - stdout: empty
# Status: 0 in case of success
#         1 if $1 is empty or if read failed
function set_global_variable()
{
	# This bit weird cmd is required to force the creation of a global variable, not a local one (like "declare") 
	# See https://stackoverflow.com/questions/9871458/declaring-global-variable-inside-a-function
	[ -z "$1" ] && return 1
	#IFS="" read $1 <<< "$2"
	printf -v $1 %s "$2"

}

### calculate
# Computes maths beyond bash's ((  )) using bc. Provides control over the amount of decimals and removes unsignificant
# decimals (trailing 0s in the result). Unsignificant decimals are always removed, even if this implies that the number
# of decimals (if any) is below $2.
# So if the result given by bc for $1 is f.ex. 3.0000000 the function returns 3, regardless of what $2 is set to
#
# Parametrization:
#  $1 calculus to do, f.ex. "(2*2.25)/7"
#  $2 (optional) maximal amount of decimals in the result. Defaults to 3 if omitted. Use 0 or 'int' to get a integer
#                see the explanations above as to why this is a maximum, not a guaranteed amount
# Pipes: - stdin: ignored
#        - stdout: if the bc execution was succesful (status code 0), the calculus result with $2 amount of decimals
#		   empty otherwise
# Status: 0 in case bc command succeeded
#         in case of bc error, the error code
function calculate()
{
	local res=$(echo "$1" | bc -l) ret=$? nb_decimals=${2:-3}
	[ $ret -ne 0 ] && return $ret
	[ "$nb_decimals" = "int" ] && nb_decimals=0
	local dot_char_idx="$(find_substring "$res" ".")"
	local char_idx=$((dot_char_idx + nb_decimals))		# can't be merged with previous line, idx wrong
	while [ "${res:$char_idx:1}" = "0" ] && [ "$nb_decimals" -gt 0 ]; do
		((nb_decimals--))
		((char_idx--))
	done
	printf "%.${nb_decimals}f" "$res"
}

### get_piped_input
#
# Usage example: usually used to get stdin to a variable, here f.ex. to $input
#         input="$(get_piped_input)"
#
# Parametrization: none
# Pipes: - stdin: read completely
#        - stdout: stdin copy
# Status: 0
function get_piped_input()
{
	[ -p /dev/stdin ] && echo "$(cat)"
}

### get_random_string
#
# Parametrization:
#  $1 (optional) length of the random string, defaults to 16 if omitted
# Pipes: - stdin: ignored
#        - stdout: the random string
# Status: 0 if /dev/urandom exists
#         1 if /dev/urandom doesn't exist
function get_random_string()
{
	[ ! -c "/dev/urandom" ] && return 1
	local length="${1:-16}"
	echo "$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c $length)"
}

### is_globbing_enabled
#
# Usage: one typical application is to "protect" an instruction which relies on globbing
#              is_globbing_enabled && do_something_with_globbing
#        another is to check whether globbing needs to be turned off before an instruction where globbing is not desired
#              is_globbing_enabled && set -f
#        set -f disables bash globbing (sets its 'no_glob' option to true). To restore it later on, use set +f
#
# Parametrization: -
# Pipes: - stdin: ignored
#        - stdout: empty
# Status: 0 if globbing is enabled
#         1 if globbing is disabled
function is_globbing_enabled()
{
	# why -z ? if the bash status contains f = no_glob is enabled. if the $(...) return is empty (= no f, globbing is enabled
	# since no no_glob disables it), -z makes the function return status 0/success
	[ -z "$(echo $- | grep f)" ]
}
