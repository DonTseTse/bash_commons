#! /bin/bash

. "$commons_path/filesystem.sh"	# for is_readable()
. "$commons_path/helpers.sh"	# for is_command(), is_function_defined(), is_array_defined()

function get_package_manager()
{
	[ -n "$(type -t "apt-get")" ] && echo "apt" && return
	[ -n "$(type -t "yum")" ] && echo "yum" && return
}

# Param:
# $1 executable name
# $2 optional flag for executable path on stdout
# Status:
#  0 $1 is executable
#  1 $1 is not executable
#  2 $1 not found in $PATH
#  3 $1 empty
#  4 found $1 in a $PATH folder but was unable to determine the actual path (usually broken symlinks)
#  5 incoherence: everything seems fine (found $1 in a path folder, it's executable) but which didn't find it
function get_executable_status()
{
        [ -z "$1" ] && return 3
	local path_on_stdout="${2:-0}" exec_path which_avail=0 path_folder
	#if is_command_defined "which"; then
	if [ -n "$(type -t "which")" ]; then
		which_avail=1
		# which does only return a path if the resolved destination exists (i.e. broken symlinks are ignored) and is executable
		if exec_path="$(which "$1")"; then
			[ "$path_on_stdout" = "1" ] && echo "$exec_path"
			return 0
		fi
	fi
	while read -d ":" path_folder; do
		[ ! -f "$path_folder/$1" ] && [ ! -h "$path_folder/$1" ] && continue
		if exec_path="$(get_real_path "$path_folder/$1")"; then
			[ "$path_on_stdout" = "1" ] && echo "$exec_path"
		else
			[ "$path_on_stdout" = "1" ] && echo "$path_folder/$1"
			return 4
		fi
		[ ! -x "$exec_path" ] && return 1		# not executable
		[ $which_avail -eq 1 ] && return 5 || return 0	# if it reaches this point, either which is not installed or results conflict
	done <<< "$PATH:"	# note: append : to $PATH to avoid that the last folder listed in $PATH is skipped (because it's read -d)
	return 2		# not found
}

# Param:
# $1 dependency name
# $2 package manager
function handle_dependency()
{
	[ -z "$1" ] && return 1
	local exec_path="$(get_executable_status "$1" 1)" dep_status=$?
	[ $dep_status -eq 0 ] && echo " - $1: $exec_path [OK]" && return
	if [ $dep_status -eq 1 ]; then		# not executable
		#is_function_defined "handle_non_executable_dependency" && handle_non_executable_dependency "$1" && return
		[ "$(type -t "handle_non_executable_dependency")" = "function" ] && handle_non_executable_dependency "$1" && return
		chmod +x "$exec_path" > /dev/null && local mod_ret=0 || local mod_ret=1
		[ $mod_ret -eq 0 ] && echo " - $1: $exec_path was not executable, applied chmod +x [OK]" || echo " - $1: $exec_path not executable, chmod +x failed [Error]"
		return $mod_ret
	fi
        if [ $dep_status -eq 2 ]; then		# which returned an empty result
		#is_function_defined "handle_dependency_installation" && handle_dependency_installation "$1" "$2" && return
		[ "$(type -t "handle_dependency_installation")" = "function" ]  && handle_dependency_installation "$1" "$2" && return
		#[ -z "$2" ] || ! is_array_defined "${2}_packages" && echo " - $1: not found, please install [Error]" && return 1
		[ -z "$2" ] || [ ! -v "${2}_packages" ] && echo " - $1: not found, please install [Error]" && return 1
		local package="$(get_array_element "${2}_packages" "$1")" install_command install_status
		[ -z "$package" ] && echo " - $1: no package name specified for $1 (package manager: $2), trying with the name of the command itself" && package="$1"
		[ "$2" = "apt" ] && install_command="apt-get install"
		[ "$2" = "yum" ] && install_command="yum install"
		printf " - $1: attempt to install package $package with $2" && $install_command "$package" &> /dev/null
		install_status=$?
		#>&2 echo "package manager: $2 - install_status: $install_status"
		[ $install_status -eq 0 ] && echo " [OK]" || echo " [Error]"
	fi
	# state 3 can't occur since it's $1 empty - if $1 is empty, the get_executable_status() call is never reached
	[ $dep_status -eq 4 ] && echo " - $1: found a correponding element in \$PATH but $exec_path doesn't resolve to a existing location (broken folder or file symlink?) [Error]" && return 1
	[ $dep_status -eq 5 ] && echo " - $1: incoherence - found $exec_path and it seems to be fine but the which command doesn't find it [Error]" && return 1
}

function handle_dependencies()
{
	local dependency dep_status err=0
	local package_manager="$(get_package_manager)"
	[ -n "$package_manager" ] && echo "Package manager: $package_manager" || echo "Package manager unknown"
	[ "$package_manager" = "apt" ] && echo "Updating package list" && apt-get update > /dev/null
	#handle_dependency "which" "$package_manager"
        for dependency in $@; do  # $@ has to be unquoted otherwise everything is treated as a single string
		handle_dependency "$dependency" "$package_manager"
		[ $? -ne 0 ] && err=1
	done
	return $err
}
