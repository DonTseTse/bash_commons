#! /bin/bash

. "$commons_path/string_handling.sh"  		# for sanitize_variable_quotes()
. "$commons_path/helpers.sh"           		# for get_array_element()

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
		#>&2 echo "Path after resolution: $path"
	done
	path="$(cd -P "$(dirname "$path")" &>/dev/null && pwd)/$(basename "$path")"
	[ -e "$path" ] && echo "$path"
}

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/filesystem.md#get_script_path
function get_script_path()
{
	#use source with highest index (see explanations above)
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
	# leading slash. If $existing_path is a folder, relative_filepath_slash is set to 1 to remove the trailing /
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
        local pattern="${2:-*}" file_cnt=0 filepath
        for filepath in "$1/"$pattern; do
                if [ -f "$filepath" ]; then
                        ((file_cnt++))
                        [ $file_cnt -eq 2  ] && return 3
                        #if [ $file_cnt -eq 2 ]; then
                        #       return 2
                        #fi
                fi
        done
        [ $file_cnt -eq 0 ] && return 2
        #[ $file_cnt -gt 1 ] && return 3
        [ $file_cnt -eq 1 ] && echo "$filepath" && return
}


########### Filesystem operations
# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/filesystem.md#create_directory
function create_directory()
{
	# status & verbose mode handled with recursion to be able to cope with all the returns before the processing
        [ "$2" = '$?' ] || [ "$2" = "status" ] && local status="$(create_directory "$1"; echo $?)" && echo "$status" && return $status
	if [ "$2" = "verbose" ]; then
		local default_msg_defs=("folder %path created\n" "%err_msg\n" "No path provided\n" "%path exists\n" "could not create %path, path is not writeable\n")
		local err_msg="$(create_directory "$1" "stderr")" status=$? msg_def
		[ -n "$3" ] && msg_def="$(get_array_element "$3" $status)"
                [ -z "$msg_def" ] && msg_def="${default_msg_defs[$status]}"
		#>&2 echo "prefix: $(get_array_element "$3" "prefix")"
                printf '%s' "$(echo "$msg_def" | sed -e "s^%path^$1^g" -e "s^%err_msg^$err_msg^g")"
		return $status
        fi
        local mkdir_status mkdir_err_msg
        [ -z "$1" ] && return 2
        [ -d "$1" ] && return 3
        # $1 is not empty => is_writeable will always return status 0, no need to check
        # is_writeable() is configured to check on the highest level *existing* directory (since it's mkdir with -p)
        [ "$(is_writeable "$1" 1)" -ne 1 ] && return 4
        # when mkdir fails, it prints on stderr, captured here
        mkdir_err_msg="$(2>&1 mkdir -p "$1")"
        mkdir_status=$?
        [ "$2" = "stderr" ] || [ "$2" = "err_msg" ] || [ "$2" = "error_message" ] && echo "$mkdir_err_msg"
        return $mkdir_status
}

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/filesystem.md#filesystem_operation
function do_filesystem_operation()
{
	#DEBUG >&2 echo "do_filesystem_operation() called with \$1 $1 \$2 $2 \$3 $3 \$4 $4 \$5 $5"
	# status collected with a little trick to be able to echo it
        [ "$4" = '$?' ] || [ "$4" = "status" ] && local status="$(do_filesystem_operation "$1" "$2" "$3"; echo $?)" && echo "$status" && return $status
	if [ "$4" = "verbose" ]; then
                local default_msg_defs[0]="%source moved to %destination\n"
		default_msg_defs[1]="%stderr_msg\n"
		default_msg_defs[2]="error: %operation failed, source path empty\n"
		default_msg_defs[3]="error: %operation from %source to %destination failed because %source doesn't exist\n"
		default_msg_defs[4]="error: %operation from %source to %destination failed because there's no read permission on %source\n"
                default_msg_defs[5]="error: %operation from %source to %destination failed because %destination exists (won't overwrite)\n"
                default_msg_defs[6]="error: %operation from %source to %destination failed because there's no write permission on %destination\n"
		default_msg_defs[7]="error: mode '$1' unknown\n"
                [ "$1" = "cp" ] || [ "$1" = "copy" ] && default_msg_defs[0]="%source copied to %destination\n"
                local stderr_msg="$(do_filesystem_operation "$1" "$2" "$3" "stderr")" status=$? msg_def
                [ -n "$5" ] && local msg_def="$(get_array_element "$5" $status)"
		[ -z "$msg_def" ] && msg_def="${default_msg_defs[$status]}"
                #>&2 echo "msg_def: $msg_def"
                printf '%s' "$(echo "$msg_def" | sed -e "s^%source^$2^g" -e "s^%destination^$3^g" -e "s^%stderr_msg^$stderr_msg^g" -e "s^%operation^$1^g")"
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
        [ "$(is_writeable "$3")" -ne 1 ] && return 6
        local status err_msg
        # when mv/cp fails, it prints on stderr, captured here
	err_msg="$(2>&1 $operation "$2" "$3")"
	status=$?
        [ "$4" = "stderr" ] || [ "$4" = "err_msg" ] || [ "$4" = "error_message" ] && echo "$err_msg"
	return $status
}

# Dev note: the copy/move file/folder functions seem good usecases for aliases but it's better to have actual functions
#           see https://unix.stackexchange.com/questions/1496/why-doesnt-my-bash-script-recognize-aliases

function copy_file()
{
	do_filesystem_operation "copy" "$@"
}

function copy_folder()
{
	do_filesystem_operation "copy" "$@"
}

function move_file()
{
	do_filesystem_operation "move" "$@"
}

function move_folder()
{
	do_filesystem_operation "move" "$@"
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

