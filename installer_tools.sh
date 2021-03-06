#! /bin/bash

# Installer tool functions
#
# Author: DonTseTse
# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/installer_tools.md
# Dependencies: chmod echo printf sed type

##### Commons dependencies
[ -z "$commons_path" ] && echo "Bash commons - Installer tools: \$commons_path not set or empty, unable to resolve internal dependencies. Aborting..." && exit 1
[ ! -r "$commons_path/filesystem.sh" ] && echo "Bash commons - Installer tools: unable to source filesystem functions at '$commons_path/filesystem.sh' - aborting..." && exit 1
. "$commons_path/filesystem.sh"		# for get_real_path()
[ ! -r "$commons_path/string_handling.sh" ] && echo "Bash commons - Installer tools: unable to source string handling functions at '$commons_path/string_handling.sh' - aborting..." && exit 1
. "$commons_path/string_handling.sh"	# for get_sed_replace_expression()
[ ! -r "$commons_path/helpers.sh" ] && echo "Bash commons - Installer tools: unable to source helper functions at '$commons_path/helpers.sh' - aborting..." && exit 1
. "$commons_path/helpers.sh"		# for get_array_element(), capture()


# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/installer_tools.md#get_package_manager
function get_package_manager()
{
	[ -n "$(type -t "apt-get")" ] && echo "apt" && return	# Debian, Ubuntu
	[ -n "$(type -t "yum")" ] && echo "yum" && return	# CentOS, Fedora (older)
	[ -n "$(type -t "dnf")" ] && echo "dnf" && return	# Fedora
	[ -n "$(type -t "apk")" ] && echo "apk" && return	# Alpine
}


# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/installer_tools.md#get_executable_status
function get_executable_status()
{
	[ -z "$1" ] && return 5
	local path_on_stdout="${2:-0}" exec_path which_avail=0 path_folder
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
			return 3
		fi
		[ ! -x "$exec_path" ] && return 1		# not executable
		[ $which_avail -eq 1 ] && return 4 || return 0	# if it reaches this point, either which is not installed or results conflict
	done <<< "$PATH:"	# note: append : to $PATH to avoid that the last folder listed in $PATH is skipped (because it's read -d)
	return 2		# not found
}

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/installer_tools.md#handle_dependency
function handle_dependency()
{
	if [ -n "$2" ]; then
		local temp_var
		handle_dependency "$1"
		local status=$?
		local default_msg_defs=([1]="%command (%path) already installed" "%command (%path) was not executable, applied chmod +x successfully" \
					[3]="%command installed successfully (package %package)" "Error: %command (%path) is not executable and chmod +x failed" \
					[5]="Error: %command installation failed (package %package)" "Error: %command not installed and no package manager found" \
					[7]="Error: %command exists in \\\$PATH at %path but it doesn't resolve to an existing filesystem location(broken symlink?)" \
					[8]="Error: %command exists but there's a incoherence with which (it can't find it)" "Error: command empty")
		local command_exp="$(get_sed_replace_expression "%command" "$1")" package_exp="$(get_sed_replace_expression "%package" "$temp_var")" \
		path_exp="$(get_sed_replace_expression "%path" "$temp_var")" output_pattern=${3:-'%s'}
		msg_def="$(get_array_element "$2" $status)" || msg_def="${default_msg_defs[$status]}"
		printf "$output_pattern" "$(echo "$msg_def" | sed -e "$command_exp" -e "$package_exp" -e "$path_exp")"
		return $status
	fi
	[ -z "$1" ] && return 9
	local exec_path="$(get_executable_status "$1" 1)" dep_status=$?
	temp_var="$exec_path"
	[ $dep_status -eq 0 ] && return 1
	if [ $dep_status -eq 1 ]; then		# not executable
		[ "$(type -t "handle_non_executable_dependency")" = "function" ] && handle_non_executable_dependency "$1" && return
		chmod +x "$exec_path" &> /dev/null && return 2 || return 4
	fi
	if [ $dep_status -eq 2 ]; then		# which returned an empty result
		local package_manager="$(get_package_manager)"
		[ "$(type -t "handle_dependency_installation")" = "function" ]  && handle_dependency_installation "$1" "$package_manager" && return
		[ -z "$package_manager" ] && return 6
		local package="$(get_array_element "${package_manager}_packages" "$1")" install_command install_status
		[ -z "$package" ] && package="$1"
		[ "$2" = "apt" ] && install_command="apt-get install"
		[ "$2" = "yum" ] && install_command="yum install"
		temp_var="$package"
		$install_command "$package" &> /dev/null && return 3 || return 5
	fi
	[ $dep_status -gt 2 ] && return $((($dep_status + 4)))
}

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/installer_tools.md#handle_dependencies
function handle_dependencies()
{
	local dependency dep_status err=0
	local dependencies=("$1")
	for dependency in ${dependencies[*]}; do  # $@ has to be unquoted otherwise everything is treated as a single string
		handle_dependency "$dependency" "$2" "$3"
		[ $? -gt 3 ] && ((err++))
	done
	return $err
}

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/installer_tools.md#reset_package_lists
function reset_package_lists()
{
	local package_manager="$(get_package_manager)" ret
	[ -z "$package_manager" ] && return 2
	[ "$package_manager" = "apt" ] && STDERR=1 capture apt-get update
	[ "$package_manager" = "yum" ] && STDERR=1 capture yum clean all
	return $status
}
