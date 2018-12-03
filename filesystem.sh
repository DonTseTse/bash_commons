#! /bin/bash

# Filesystem functions
#
# Author: DonTseTse
# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/filesystem.md
# Dependencies: awk, basename, cd, dirname, echo, grep, printf, pwd, readlink, sed

##### Commons dependencies
. "$commons_path/helpers.sh"           		# for get_array_element(), is_globbing_enabled()
. "$commons_path/string_handling.sh"  		# for sanitize_variable_quotes()

##### Functions
########### Path handling utilities
# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/filesystem.md#get_real_path
function get_real_path()
{
	[ ! -e "$1" ] && return 1
	local path="$1"
	while [ -h "$path" ]; do 	# as long as $path is a symlink, resolve
		path="$(readlink "$path")"
		# if $path is a relative symlink, the path needs to be treated with respect to the symlink's location
		[[ "$path" != /* ]] && path="$(cd -P "$(dirname "$path")" &>/dev/null && pwd)/$(basename "$path")"
		[ ! -e "$path" ] && return 1
		#DEBUG >&2 echo "Path after resolution: $path"
	done
	path="$(cd -P "$(dirname "$path")" &>/dev/null && pwd)/$(basename "$path")"
	[ -e "$path" ] && echo "$path"
}

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/filesystem.md#get_script_path
function get_script_path()
{	#use source with highest index (explanations in the docs)
	get_real_path "${BASH_SOURCE[((${#BASH_SOURCE[@]}-1))]}"
}

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/filesystem.md#is_writeable
function is_writeable()
{
	[ -z "$1" ] && return 1
	local check_on_existing_path_part="${2:-0}" path_to_check
	[ -e "$1" ] && [ ! -w "$1" ] && echo 0 && return
	[ -e "$1" ] && [ -w "$1" ] && echo 1 && return
	[ $check_on_existing_path_part -eq 0 ] && path_to_check="$(dirname "$1")"
	[ $check_on_existing_path_part -eq 0 ] && [ ! -d "$path_to_check" ] && echo 2 && return
	[ $check_on_existing_path_part -eq 1 ] && path_to_check="$(get_existing_path_part "$1")"
	[ -w "$path_to_check" ] && echo 1 || echo 0
}

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/filesystem.md#get_new_path_part
function get_new_path_part
{
	local existing_part=$(get_existing_path_part "$1") relative_filepath_slash=-1
	# $relative_filepath_slash is -1 to cover the case where $existing_part is the root / => stdout must contain this
	# leading slash. If $existing_path is a folder, $relative_filepath_slash is set to 1 to remove the trailing /
	[ ${#existing_part} -gt 1 ] && relative_filepath_slash=1
	echo "${1:${#existing_part}+$relative_filepath_slash}"
}

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/filesystem.md#get_existing_path_part
function get_existing_path_part
{
	local existing_dir="$1"
	while [ ! -d "$existing_dir" ]; do
		existing_dir="$(dirname "$existing_dir")"
	done
	echo "$existing_dir"
}

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/filesystem.md#try_filepath_deduction
function try_filepath_deduction()
{
	[ ! -d "$1" ] && return 1
	is_globbing_enabled || set +f && local disable_globbing=1
	local pattern="${2:-*}" file_cnt=0 filepath
	for filepath in "$1/"$pattern; do
		if [ -f "$filepath" ]; then
			((file_cnt++))
			[ $file_cnt -eq 2  ] && break	# not return here to be able to handle disable_globbing
		fi
	done
	[ -n $disable_globbing ] && set -f
	[ $file_cnt -eq 2  ] && return 3
	[ $file_cnt -eq 0 ] && return 2
	[ $file_cnt -eq 1 ] && echo "$filepath" && return
}

########### Filesystem operations
# - status & verbose modes are handled with recursion to be able to cope with all the returns statuses
#   => the recursed call happens in silent mode, collects the status, and print accordingly

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/filesystem.md#create_folder
function create_folder()
{
	# recursion on status and verbose modes: see dev note above
	[ "$2" = '$?' ] || [ "$2" = "status" ] && local status="$(create_folder "$1"; echo $?)" && echo "$status" && return $status
	if [ "$2" = "verbose" ]; then
		local default_msg_defs[0]="folder %path created\n"
		default_msg_defs[1]="%stderr_msg\n"
		default_msg_defs[2]="folder creation error: no path provided\n"
		default_msg_defs[3]="folder creation error: %path exists\n"
		default_msg_defs[4]="folder creation error: no write permission for %path\n"
		local stderr_msg="$(create_folder "$1" "stderr")" status=$? msg_def
		[ -n "$3" ] && msg_def="$(get_array_element "$3" $status)"
		[ -z "$msg_def" ] && msg_def="${default_msg_defs[$status]}"
		local path_exp="$(get_sed_replace_expression "%path" "$1")" stderr_msg_exp="$(get_sed_replace_expression "%stderr_msg" "$stderr_msg")"
		printf '%s' "$(echo "$msg_def" | sed -e "$path_exp" -e "$stderr_msg_exp")"
		return $status
	fi
	[ -z "$1" ] && return 2
	[ -d "$1" ] && return 3
	# $1 is not empty => is_writeable will always return status 0, no need to check
	# is_writeable() is configured to check on the highest level *existing* directory (since it's mkdir with -p)
	[ "$(is_writeable "$1" 1)" -ne 1 ] && return 4
	# when mkdir fails, it prints on stderr, captured here
	local err_msg="$(2>&1 mkdir -p "$1")" status=$?
	[ "$2" = "stderr" ] || [ "$2" = "err_msg" ] || [ "$2" = "error_message" ] && echo "$err_msg"
	return $status
}

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/filesystem.md#handle_cp_or_mv
function handle_cp_or_mv()
{
	#DEBUG >&2 echo "do_filesystem_operation() called with \$1 $1 \$2 $2 \$3 $3 \$4 $4 \$5 $5"
	# recursion for status and verbose modes: see dev note at the beginning of the "filesystem operations" section
	[ "$4" = '$?' ] || [ "$4" = "status" ] && local status="$(handle_cp_or_mv "$1" "$2" "$3"; echo $?)" && echo "$status" && return $status
	if [ "$4" = "verbose" ]; then
		local default_msg_defs[0]="%src moved to %dest\n"
		[ "$1" = "cp" ] || [ "$1" = "copy" ] && default_msg_defs[0]="%src copied to %dest\n"
		default_msg_defs[1]="%stderr_msg\n"
		default_msg_defs[2]="%op error: source path empty\n"
		default_msg_defs[3]="%op error: %src -> %dest failed because source path doesn't exist\n"
		default_msg_defs[4]="%op error: %src -> %dest failed because of a lack of read permission on the source path\n"
		default_msg_defs[5]="%op error: %src -> %dest failed because destination path exists (won't overwrite)\n"
		default_msg_defs[6]="%op error: %src -> %dest failed because of a lack of write permission on the destination path\n"
		default_msg_defs[7]="handle_cp_or_mv error: mode '$1' unknown\n"
		local stderr_msg="$(handle_cp_or_mv "$1" "$2" "$3" "stderr")" status=$? msg_def
		[ -n "$5" ] && local msg_def="$(get_array_element "$5" $status)"
		[ -z "$msg_def" ] && msg_def="${default_msg_defs[$status]}"
		local op_exp="$(get_sed_replace_expression "%op" "$1")" src_exp="$(get_sed_replace_expression "%src" "$2")" \
		dest_exp="$(get_sed_replace_expression "%dest" $3)" stderr_exp="$(get_sed_replace_expression "%stderr" "$stderr_msg")"
		printf '%s' "$(echo "$msg_def" | sed -e "$op_exp" -e "$src_exp" -e "$dest_exp" -e "$stderr_exp")"
		return $status
	fi
	[ "$1" = "mv" ] || [ "$1" = "move" ] && local operation="mv -n"	# mv with -n forbids overwrites
	[ "$1" = "cp" ] || [ "$1" = "copy" ] && local operation="cp -r"
	[ -z "$operation" ] && return 7
	[ -z "$2" ] && return 2
	[ ! -e "$2" ] && return 3
	[ ! -r "$2" ] && return 4
	[ -e "$3" ] && return 5
	# at this stage it's sure $3 is not empty => is_writeable() will always return status 0, no need to check
	# cp and mv for both files and folder always need the direct parent folder of the the destination path to exist => is_writeable() configured to check that
	[ "$(is_writeable "$3")" -ne 1 ] && return 6
	# when mv/cp fails, it prints on stderr, captured here
	local err_msg="$(2>&1 $operation "$2" "$3")" status=$?
	[ "$4" = "stderr" ] || [ "$4" = "err_msg" ] || [ "$4" = "error_message" ] && echo "$err_msg"
	return $status
}

# Dev note: the copy/move file/folder functions seem good usecases for aliases but it's better to have actual functions
#           see https://unix.stackexchange.com/questions/1496/why-doesnt-my-bash-script-recognize-aliases
# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/filesystem.md#copy_file
function copy_file(){
handle_cp_or_mv "copy" "$@"
}

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/filesystem.md#copy_folder
function copy_folder(){
handle_cp_or_mv "copy" "$@"
}

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/filesystem.md#move_file
function move_file(){
handle_cp_or_mv "move" "$@"
}

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/filesystem.md#move_folder
function move_folder(){
handle_cp_or_mv "move" "$@"
}

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/filesystem.md#handle_rm
function handle_rm()
{
	# recursion for status and verbose modes: see dev note at the beginning of the "filesystem operations" section
	[ "$2" = '$?' ] || [ "$2" = "status" ] && local status="$(handle_rm "$1"; echo $?)" && echo "$status" && return $status
	if [ "$2" = "verbose" ]; then
		local default_msg_defs[0]="%path removed\n"
		default_msg_defs[1]="%stderr_msg\n"
		default_msg_defs[2]="removal error: path is empty\n"
		default_msg_defs[3]="removal error: %path doesn't exist\n"
		default_msg_defs[4]="removal error: no write permission on %path\n"
		local stderr_msg="$(handle_rm "$1" "stderr")" status=$? msg_def
		[ -n "$3" ] && local msg_def="$(get_array_element "$3" $status)"
		[ -z "$msg_def" ] && msg_def="${default_msg_defs[$status]}"
		local path_exp="$(get_sed_replace_expression "%path" "$1")" stderr_msg_exp="$(get_sed_replace_expression "%stderr_msg" "$stderr_msg")"
		printf '%s' "$(echo "$msg_def" | sed -e "$path_exp" -e "$stderr_msg_exp")"
		return $status
	fi
	[ -z "$1" ] && return 2
	[ ! -e "$1" ] && return 3
	[ ! -w "$1" ] && return 4
	local operation="rm"
	[ -d "$1" ] && local operation="rm -r"
	# when rm fails, it prints on stderr, captured here
	local err_msg="$(2>&1 $operation $1)" status=$?
	[ "$2" = "stderr" ] || [ "$2" = "err_msg" ] || [ "$2" = "error_message" ] && echo "$err_msg"
	return $status
}

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/filesystem.md#remove_file
function remove_file(){
handle_rm "$@"
}

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/filesystem.md#remove_folder
function remove_folder(){
handle_rm "$@"
}

########### File operations
# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/filesystem.md#load_configuration_file_value
function load_configuration_file_value()
{
	[ -z "$1" ] && return 1
	[ -z "$2" ] && return 2
	[ ! -f "$1" ] && return 3
	[ ! -r "$1" ] && return 4
	local val="$(grep "^\s*$2\s*\=" "$1" | awk -F = '{print $2}')"
	[ -z "$val" ] && return 5
	echo "$(sanitize_variable_quotes "$val")"
}
