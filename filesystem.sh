#! /bin/bash

. "$commons_path/string_handling.sh"  # sanitize_variable_quotes()

# TODO complete documentation of move and move_verbose

### get_real_path
# Resolves symlinks (file and folder) in a filepath and cleans it (removes "/../" "./" etc.).
#
# Works for both files and folders with the restriction that they must exist (not suited to
# sanitize "new folder input" in an installer f.ex.)
#
# Inspired by https://stackoverflow.com/questions/59895/getting-the-source-directory-of-a-bash-script-from-within/246128#246128
#
# Parametrization:
#  $1 path to resolve and clean
# Pipes: - stdin: ignored
#        - stdout: if status is 0, "real" path of $1, empty otherwise
# Status: 0 if file/folder $1 exists
#         1 otherwise
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

### get_script_path
# Rewritten from https://stackoverflow.com/questions/59895/getting-the-source-directory-of-a-bash-script-from-within/246128#246128
# Unlike the SO answer, this function returns the full path including the filename and it's able to work in any call
# constellation: sourced, called in a subshell etc. - all these operations affect $BASH_SOURCE, but one thing is guaranteed: the
# element in this array with the highest index is the originally called script
#
# Important: call get_script_path() before any directory changes in the script, otherwise it may provide wrong results.
#            This is due to the fact that the script's BASH_SOURCE entry depends on the way the script was called:
#              1. through bash: $> bash <path> <$ if the <path> is relative, it's with respect to the current directory
#              2. if the script is executable, directly:  $> <script_file> <$
#              3. if the script is located in/linked to a folder which is part of the $PATH, they can be called globally and
#                 there's no relationship between script location and current directory
#            If the script is executed in the bash method (#1) using a relative filepath, the function needs the "original"
#            working directory (original in the sense "when the execution was launched") => call before any cd, usually at
#            initialization
#
# Parametrization: -
# Pipes: - stdin: ignored
#        - stdout: "real" (folder + file symlink resolved and cleaned) absolute path of the executed script
# Status: 0
function get_script_path()
{
	#use source with highest index (see explanations above)
	get_real_path "${BASH_SOURCE[((${#BASH_SOURCE[@]}-1))]}"
}

# is_writeable
#
# Usage advice: since the function complies with the status code conventions, it's possible to use
#                       wr_err=$(is_writeable <path>) && ... do something with <path> ...
#               operation failure is signalled by $wr_err not empty
# "Check on existing path part" flag explanation:
# Let's imagine there's a directory /test which is empty and writeable to the user. The instruction
#         is_writeable /test/another_folder/test
# returns false because the flag is not raised, the logic is
#         $2 defaults to 0 => only the path of the direct parent folder is checked =>
#         /test/another_folder doesn't exist => false
# With the flag raised (instruction: is_writeable /test/another_folder/test 1), the logic is
# 	  find highest existing folder in $1 => that's /test => it's writeable => true
# This allows to adapt the function depending on the operation the check is about:
#  - file write, file/folder copy/move, and mkdir without the -p flag require the direct parent
#    folder of the "destination" to exist => if, continuing the example from above, there's the
#    instruction
#        echo "a message" > /test/another_folder/test
#    it's going to fail since /test/another_folder doesn't exist, so the appropriate check is
#        is_writeable /test/another_folder/test && echo "a message" > /test/another_folder/test
#  - other operations, f.ex. mkdir with the -p flag, don't care about the direct parent, but the
#    part of the path which exists at the time the command is executed.
#
# Parametrization:
#  $1 path
#  $2 (optional) "check on existing path part" flag - if $1 doesn't exist, it configures whether the
#     function checks only the direct parent or on the "highest existing" folder - see above
# Pipes: - stdin: ignored
#        - stdout: 0 path $1 not writeable
#                  1 path $1 writeable
#                  2 direct parent folder of path $1 doesn't exist (can only happen if $2 omitted
#                    or 0)
# Status: 0 success, result on stdout
#         1 $1 empty
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

### get_new_path_part
#
# Parametrization
#  $1 path to get new part of
# Pipes: - stdin: ignored
#        - stdout: part of $1 which does not yet exist on the filesystem
# Status: 0
function get_new_path_part
{
	local existing_part=$(get_existing_path_part "$1") relative_filepath_slash=-1
	# $relative_filepath_slash is -1 to cover the case where $existing_part is the root / => stdout must contain this
	# leading slash. If $existing_path is a folder, relative_filepath_slash is set to 1 to remove the trailing /
	[ ${#existing_part} -gt 1 ] && relative_filepath_slash=1
	echo "${1:${#existing_part}+$relative_filepath_slash}"
}

### get_existing_path_part
#
# Parametrization
#  $1 path to get new part of
# Pipes: - stdin: ignored
#        - stdout: part of $1 which exists on the filesystem - if not even the directory at the root
#                  exists, it returns /
# Status: 0
function get_existing_path_part
{
	local existing_dir="$1"
	while [ ! -d "$existing_dir" ]; do
		existing_dir="$(dirname "$existing_dir")"
	done
	echo "$existing_dir"
}

### move
#
# Advantages over simple mv:
# - additional return codes allow better error interpretation, not just the basic 0/success and 1/error
# - control over stdout and stderr: mv prints on stderr on failure. This function allows to be sure:
#   - that stdout returns either nothing, the mv status code or the mv stderr message, depending on $2
#   - that stderr remains silent, even in case of mv failure
#
# Examples:
#  - silent mode:
#       move "path/to/src "path/to/dest"
#  - status code:
#       status=$(move "/path/to/src" "/path/to/dest" "status")
#  - error message:
#       err_msg=$(move "/path/to/src" "path/to/dest"  "error_message")
#       status=$?
#  - verbose mode: calls move_verbose(), see its documentation for details
#       mv_msg_def=("Info: folder created\n" "Error in %err_msg\n" "Info: folder exists, nothing to do\n")
#       mv_msg_def[3]="Error: could not create directory, path not writeable\n"
#       move "path/to/src" "path/to/dest" "verbose"  "   "
#
# Parametrization:
#  $1 source path
#  $2 destination path
#  $3 (optional) stdout configuration - if omitted or an empty string, nothing is printed on stdout
#                                     - 'status' print the status
#                                     - 'error_message'
#                                     - 'verbose' move_verbose() internally
#  $4 (optional) prefix: if the 'verbose' stdout mode is used, the prefix
# Pipes: - stdin: ignored
#        - stdout: depending on $3
#                  - empty if $3 omitted or set to an empty string
#                  - the mv call status code if $3 is set to 'status'
#                  - eventual sterr output of the mv call, if $3 set to 'error_message'
#                  - the message if $3 set to 'verbose'
# Status: 0 moved successfully
#         1 mv error, if $3 = 'error_message', stdout contains the content of stderr
#         2 $1 is empty
#         3 $1 doesn't exist
#         4 $1 is not readable
#         5 $2 exists and won't be overwritten
#         6 $2 not writeable
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

# To overwrite these messages simply create a mkdir_msg_def variable before the call:
#     mkdir_msg_def=("Info: folder created\n" "Error in %err_msg\n" "Info: folder exists, nothing to do\n")
#     mkdir_msg_def[3]="Error: could not create directory, path not writeable\n"
#     create_directory_verbose "/new/test/dir" "   "
# The supported variables are %path and %err_msg
#
# Parametrization:
#  $1 path
#  $2 (optional) prefix, if omitted, defaults to a empty string
# Globals used: $mkdir_msg_def as an array with 4 keys corresponding to the 4 possible return states of create_directory
#               i.e. $mkdir_msg_def[0] success message, idx 1 error message, idx 2 "folder exists" message, idx 3
#               "$1 not writeable" message
# Returns: -status: create_directory()'s status
#          -stdout: the printed message
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

# create_directory
#
# Advantages over simple mkdir:
# - additional return codes allow better error interpretation, not just the basic 0/success and 1/error
# - control over stdout and stderr: mkdir prints on stderr on failure. This function allows to be sure:
#   - that stdout returns either nothing, the mkdir status code or the mkdir stderr message, depending
#     on $2
#   - that stderr remains silent, even in case of mkdir failure
#
# Examples:
#  - silent mode:
#       create_directory "path/to/new/dir"
#  - status code:
#       status=$(create_directory "/path/to/my_new_dir" "status")
#  - error message:
#       err_msg=$(create_directory "/path/to/my_new_dir" "error_message")
#       status=$?
#  - verbose mode: calls create_directory_verbose(), see its documentation for details
#       mkdir_msg_def=("Info: folder created\n" "Error in %err_msg\n" "Info: folder exists, nothing to do\n")
#       mkdir_msg_def[3]="Error: could not create directory, path not writeable\n"
#       create_directory "$1" "verbose"  "   "
#
# Parametrization:
#  $1 path
#  $2 (optional) stdout configuration - if omitted or an empty string, nothing is printed on stdout
#                                     - 'status' / '$?' for the status
#                                     - 'error_message' / 'err_msg' / 'stderr' for the eventual mkdir error
#                                        message
#                                     - 'verbose' calls create_directory_verbose() internally
#  $3 (optional) prefix: if the 'verbose' stdout mode is used, the prefix
# Pipes: - stdin: ignored
#        - stdout: mkdir error message if operation failed and $2 = 'error_message' (or alises)
# Status: 0 $1 created
#         1 mkdir error, stderr copied to fct_err_msg
#         2 $1 empty
#         3 $1 exists
#         4 $1 not writeable
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

### create_directory_verbose
# create_directory with configurable message output
##
# Default message if f.ex. path is new/test/dir:
# - 0/success pattern: "%path created\n" => "new/test/dir created\n"
# - 1/error   pattern: "%err_msg\n" => error message printed by mkdir, terminated by a newline
# - 2/"folder exists" pattern: "%path exists\n" => "new/test/dir exists\n"
# - 3/"path not writeable" pattern: "could not create %path, path is not writeable\n" => "could not create new/test/dir,
#   path is not writeable\n"
#
# To overwrite these messages simply create a mkdir_msg_def variable before the call:
#     mkdir_msg_def=("Info: folder created\n" "Error in %err_msg\n" "Info: folder exists, nothing to do\n")
#     mkdir_msg_def[3]="Error: could not create directory, path not writeable\n"
#     create_directory_verbose "/new/test/dir" "   "
# The supported variables are %path and %err_msg
#
# Parametrization:
#  $1 path
#  $2 (optional) prefix, if omitted, defaults to a empty string
# Globals used: $mkdir_msg_def as an array with 4 keys corresponding to the 4 possible return states of create_directory
#               i.e. $mkdir_msg_def[0] success message, idx 1 error message, idx 2 "folder exists" message, idx 3
#               "$1 not writeable" message
# Returns: -status: create_directory()'s status
#          -stdout: the printed message
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

### try_filepath_deduction
# If there's only a single file (match) in the folder $1, returns it
#
# Parametrization
#  $1 folder to search
#  $2 (optional) pattern - if omitted, defaults to * (= everything)
# Pipes: - stdin: ignored
#        - stdout: in case of success (status = 0), the absolute filepath of the single match
# Status: 0 in case of successful deduction
#         1 if $1 doesn't exist
#         2 if there's no match for $2 (fallback: *) in $1
#         3 if there's more than 1 match for $2 (fallback: *) in $1
function try_filepath_deduction()
{
	[ ! -d "$1" ] && return 1
        local pattern="${2:-*}" file_cnt=0 filepath
	for filepath in "$1/"$pattern; do
		if [ -f "$filepath" ]; then
			((file_cnt++))
			[ $file_cnt -eq 2  ] && return 3
			#if [ $file_cnt -eq 2 ]; then
			#	return 2
			#fi
		fi
	done
	[ $file_cnt -eq 0 ] && return 2
	#[ $file_cnt -gt 1 ] && return 3
	[ $file_cnt -eq 1 ] && echo "$filepath" && return
}


### load_configuration_file_value
#
# The variable definition should have the format:
# variable=value
# It should be on a single line, alone, with any number of whitespaces before the variable name and the variable name
# and the assignment '='
# Examples:
# cfg_filepath="/etc/test.conf"
#       cfg_filepath="/etc/test2.conf"
# timeout     = 25
#
# Parametrization:
#  $1 path of the configuration file
#  $2 name of the variable to load
# Pipes: - stdin: ignored
#        - stdout: in case of success (status = 0), the value of the variable called $2 in $1
# Status: 0 in case of successful load
#         1 if $1 is empty
#         2 if $2 is empty
#         3 if the file doesn't exist,
#         4 if there's no read permission on $1
#         5 if a variable with name $2 is not found/defined
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

