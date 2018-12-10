#! /bin/bash

# Git helper functions
#
# Author: DonTseTse
# Documentation:
# Dependencies:

##### Commons dependencies
# None

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

# TODO: find a way to customize messages
#       split tests
#       silence git operations
#       other git operations
# Documentation: https://github.com/DonTseTse/bash_commons/git_handling.md#get_git_repository
function get_git_repository()
{
        local remote_url="$(get_git_repository_remote_url "$2")" ret=$?
	local default_msg_defs=("$1 cloned to $2" "$1 already cloned to $2 - nothing to do"  "Git clone error: path $2 exists" \
				"Git clone error: could not clone $1 to $2" "$2 exists but the attempt to run git config to get the remote URL failed with code $ret" \
				"Repository path empty")

#"Repository path $2 is not a directory" "Repository path '$2' is not readable" "Repository path '$2' exists but it's not a git repository (no .git subfolder found)" \
	local fct_error_status_map=([0]=1 )
        #[ -n "$remote_url" ] && [ "$remote_url" != "$1" ] && echo "The repository path '$2' contains another repository with the URL $remote_url" && return 2
	[ -n "$remote_url" ] && [ "$remote_url" != "$1" ] && return 2
	if [ $ret -eq 1 ]; then
                git clone "$1" "$2"
                return $?
        fi
        #[ "$3" = "update" ] && execute_git_command_in_repository "$2" "fetch"
}
