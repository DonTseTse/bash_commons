#! /bin/bash

. "$commons_path/string_handling.sh"  # sanitize_variable_quotes()

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
# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/filesystem.md#move
function move()
{
	#DEBUG >&2 echo "move() called with \$1 $1 \$2 $2 \$3 $3"
	[ "$3" = '$?' ] || [ "$3" = "status" ] && local status="$(move "$1" "$2"; echo $?)" && echo "$status" && return $status
	[ "$3" = "verbose" ] && move_verbose "$1" "$2" "$4" && return
	[ -z "$1" ] && return 2
	[ ! -e "$1" ] && return 3
	[ ! -r "$1" ] && return 4
	[ -e "$2" ] && return 5
        # $1 is not empty => is_writeable() will always return status 0, no need to check
        [ "$(is_writeable "$2")" -ne 1 ] && return 6
        local mv_status mv_err_msg
        # when mv fails, it prints on stderr, captured here
	mv_err_msg=$(2>&1 mv -n "$1" "$2") 	# mv with -n forbids overwrites
	mv_status=$?
        [ "$3" = "stderr" ] || [ "$3" = "err_msg" ] || [ "$3" = "error_message" ] && echo "$mv_err_msg"
	return $mv_status
}

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/filesystem.md#move_verbose
function move_verbose()
{
        local status err_msg msg_def msg
        msg_def[0]="${mv_msg_def[0]:-%source moved to %destination\n}"
        msg_def[1]="${mv_msg_def[1]:-%err_msg\n}"
        msg_def[2]="${mv_msg_def[2]:-%source doesn't exist\n}"
        msg_def[3]="${mv_msg_def[3]:-%source is not readable\n}"
        msg_def[4]="${mv_msg_def[4]:-%destination exists, won't overwrite\n}"
        msg_def[5]="${mv_msg_def[5]:-could not create %destination, path is not writeable\n}"
        err_msg="$(move "$1" "$2" "stderr")"
        status=$?
        msg="$(echo "${msg_def[status]}" | sed -e "s^%source^$1^" -e "s^%destination^$2^" -e "s^%err_msg^$err_msg^")"
        printf "$(printf "$3%s" "$msg")"
        return $status
}

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/filesystem.md#create_directory
function create_directory()
{
	[ "$2" = '$?' ] || [ "$2" = "status" ] && local status="$(create_directory "$1"; echo $?)" && echo "$status" && return $status
	[ "$2" = "verbose" ] && create_directory_verbose "$1" "$3" && return
	[ -z "$1" ] && return 2
	[ -d "$1" ] && return 3
	[ "$(is_writeable "$1" 1)" -ne 1 ] && return 4
	local mkdir_status mkdir_err_msg
	# $1 is not empty => is_writeable will always return status 0, no need to check
	# is_writeable() is configured to check on the highest level *existing* directory (since it's mkdir with -p)
	# when mkdir fails, it prints on stderr, captured here
	mkdir_err_msg=$(2>&1 mkdir -p "$1")
	mkdir_status=$?
	#[ "$2" = '$?' ] || [ "$2" = "status" ] && echo "$mkdir_status"
	[ "$2" = "stderr" ] || [ "$2" = "err_msg" ] || [ "$2" = "error_message" ] && echo "$mkdir_err_msg"
	return $mkdir_status
}

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/filesystem.md#create_directory_verbose
function create_directory_verbose()
{
	local status err_msg msg_def msg
	msg_def[0]="${mkdir_msg_def[0]:-folder %path created\n}"
	msg_def[1]="${mkdir_msg_def[1]:-%err_msg\n}"
	msg_def[2]="${mkdir_msg_def[2]:-No path provided\n}"
	msg_def[3]="${mkdir_msg_def[3]:-%path exists\n}"
	msg_def[4]="${mkdir_msg_def[4]:-could not create %path, path is not writeable\n}"
	err_msg="$(create_directory "$1" "stderr")"
	status=$?
	msg="$(echo "${msg_def[status]}" | sed -e "s^%path^$1^" -e "s^%err_msg^$err_msg^")"
	printf "$(printf "$2%s" "$msg")"
	return $status
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

