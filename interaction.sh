#! /bin/bash

# User interaction functions
#
# Author: DonTseTse
# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/interaction.md
# Dependancies: echo printf read

##### Commons dependencies
# None

##### Functions

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/interaction.md#read_and_validate
function read_and_validate()
{
	[ -z "$1" ] && return 2
	local answer read_flag="$2"
	read $read_flag answer
	echo "$answer"
	# line below: shorthand for if [[ "$answer" =~ "$1" ]]; then return 0; else return 1; fi
	[[ "$answer" =~ $1 ]] 	# $1 can't be enclosed in "..." here, otherwise the regex doesn't work
}

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/interaction.md#get_user_confirmation
function get_user_confirmation()
{
	local char="${1:-y}" valid=1
	read_and_validate "^[$char]\$" "-n 1" > /dev/null && valid=0
	echo ""
	return $valid
}

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/interaction.md#get_user_choice
function get_user_choice()
{
	local answer
	(exit 1)
	while [ $? -eq 1 ]; do  # checking -eq 1 and not -ne 0 because if $1 is empty => $? == 2 => perpetual loop
		answer=$(read_and_validate "$1" "-n 1 -s")
	done
	echo "$answer"
}
