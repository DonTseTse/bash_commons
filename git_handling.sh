#! /bin/bash

# Git helper functions
#
# Author: DonTseTse
# Documentation:
# Dependencies:

##### Commons dependencies
[ -z "$commons_path" ] && echo "Bash commons - Logging: \$commons_path not set or empty, unable to resolve internal dependencies. Aborting..." && exit 1
[ ! -r "$commons_path/string_handling.sh" ] && echo "Bash commons - Git handling: unable to source string handling function at '$commons_path/string_handling.sh' - aborting..." && exit 1
. "$commons_path/filesystem.sh"    # for is_readable()

##### Functions
########### Command helpers
# Documentation: https://github.com/DonTseTse/bash_commons/git_handling.md#execute_git_command_in_repository
function execute_git_command_in_repository()
{
        execute_working_directory_dependant_command "$1" "git" "$2"
}

# Documentation: https://github.com/DonTseTse/bash_commons/git_handling.md#get_git_repository_remote_url
function get_git_repository_remote_url()
{
        local current_dir=$(pwd) repo_url remote_name="${2:-origin}" error_status_map=([1]=3 [2]=1 [3]=2 [4]=6)
        is_readable "$1" "folder" || return ${error_status_map[$?]}
        [ ! -d "$1/.git" ] && return 4
        repo_url="$(execute_git_command_in_repository "$1" "config --get remote.$remote_name.url")" && echo "$repo_url" || return 5
}

#       split tests
#       other git operations
# Documentation: https://github.com/DonTseTse/bash_commons/git_handling.md#get_git_repository
function get_git_repository()
{
	if [ -n "$3" ]; then
		local default_msg_defs=("%url cloned to %path\n" "Git clone error: could not clone %url to %path\n" "%url already cloned to %path - nothing to do\n" \
			[3]="%path exists and it's not a folder\n" "%path exists but it's not readable\n" \
			[5]="%path exist but it doesn't seem to be a git repository (no .git folder inside)\n" \
			[6]="%path exists but the attempt to run git config to get the remote URL failed\n" \
			[7]="%path exists and it's a git repository but the remote URL is not %url\n" \
			[8]="Repository URL is empty\n" "Repository path empty\n")
		get_git_repository "$1" "$2"
		local status=$?
		[ -n "$3" ] && msg_def="$(get_array_element "$3" $status)"
                [ -z "$msg_def" ] && msg_def="${default_msg_defs[$status]}"
		local url_exp="$(get_sed_replace_expression "%url" "$1")" path_exp="$(get_sed_replace_expression "%path" "$2")"
                printf '%s' "$(echo "$msg_def" | sed -e "$url_exp" -e "$path_exp")" && return $status
	fi
	[ -z "$1" ] && return 8
        local remote_url="$(get_git_repository_remote_url "$2")" ret=$?
	[ $ret -eq 6 ] && return 9		# $2 empty
	[ $ret -gt 2 ] && return $ret
	[ -n "$remote_url" ] && [ "$remote_url" != "$1" ] && return 7
	if [ $ret -eq 1 ]; then			# $2 doesn't exist
		git clone -q "$1" "$2"
                return $?
        fi
	return 2
}

#[ "$3" = "update" ] && execute_git_command_in_repository "$2" "fetch"
