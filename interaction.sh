#! /bin/bash

### read_and_validate
#
# Important read flags:
# -n <nb_chars> : read stops after nb_chars, which gives a "auto-return" UX. Suited for
#                 single char, for longer entries, a explicit [Enter] is usually better
#
# Parametrization:
#  $1 validation regex (match leads to status return 0)
#  $2 (optional) read flags
# Pipes: - stdin: ignored, used via read
#        - stdout: the user input
# Status: 0 if the user entered a $1 match
#         1 otherwise
function read_and_validate()
{
	local answer read_flag="$2"
	read $read_flag answer
	echo "$answer"
	# 2 lines below: shorthand for if [[ "$answer" =~ "$1" ]]; then return 0; else return 1; fi
	[[ "$answer" =~ $1 ]] 	# $1 can't be enclosed in "..." here, otherwise the regex doesn't work
	return $?
}

### get_user_confirmation
#
# Parametrization:
#  $1 (optional) confirmation character, defaults to 'y'
# Pipes: - stdin: ignored on start, used via read_and_validate()
#        - stdout: prints a newline because cursor stands just after the user input
# Status: 0 if the user enters $1 (or 'y' if $1 omitted)
#         1 if the user enters something else
function get_user_confirmation()
{
	local char="${1:-y}" valid=1
	read_and_validate "^[$char]\$" "-n 1" > /dev/null && valid=0
	echo ""
	return $valid
}

# get_user_choice
#
# The fct behaves as if it ignores input as long as it doesn't match regex $1. This makes it suitable as
# "option selector".
# Detail: read's -s flag keeps the entered input hidden => if it doesn't match $1, read_and_validate returns
#         a status code $? != 0, the while loops
#
# Example: the user is offered 3 choices numbered 1-3, the regex is ^[1-3]$.
#
# Parametrization:
#  $1 "acceptation" regex
# Pipes: - stdin: ignored on start, used via read_and_validate()
#        - stdout: the selected option
# Status: 0 always 0
function get_user_choice()
{
	local answer
	(exit 1)	#the (exit 1) just ensures that $? != 0 on the first iteration
	while [ $? -ne 0 ]; do
		answer=$(read_and_validate "$1" "-n 1 -s")
	done
	echo "$answer"
}

### conditional_exit
#
# Example:
#    important_fct_call     # an important function which can fail
#    conditional_exit $? "Damn! it failed. Aborting..." 20
# If important_fct_call returns with a status code other than 0, the main script prints the "Damn! ..."
# message and exits with status code 20
#
# Parametrization:
#  $1 condition, if it's different than 0, the exit is triggered
#  $2 (optional) exit message, defaults to a empty string if omitted (it still prints a newline which
#     is good to reset the terminal)
#  $3 (optional) exit code, defaults to 1
# Pipes: - stdin: ignored
#        - stdout: if the exit is triggered, $2 followed by a newline
# Status: 0 if the exit is not triggered
# Exit code: $3, defaults to 1
function conditional_exit()
{
	if [[ ! "$1" =~ ^[0-1]$ ]] || [ $1 -ne 0 ]; then
		local msg="${2:-\n}" code="${3:-1}"
		printf "$msg\n"
		exit $code
	fi
}
