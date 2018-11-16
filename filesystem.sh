#! /bin/bash

### get_script_path
# Rewritten from https://stackoverflow.com/questions/59895/getting-the-source-directory-of-a-bash-script-from-within/246128#246128
# Unlike the SO answer, this function returns the full path including the filename and it's able to work in any call
# constellation: sourced, called in a subshell etc. - all things that affect $BASH_SOURCE, but one thing is guaranteed: the element
# in this array with the highest index is the originally called script
#
# Returns - status: always 0
#         - stdout: "real" (symlink resolved) absolute path of the executed script
function get_script_path()
{
	#use source with highest index (see explanations above)
	local src="${BASH_SOURCE[((${#BASH_SOURCE[@]}-1))]}"
	local dir
	# resolve eventual symlinks in $src
	while [ -h "$src" ]; do
  		src="$(readlink "$src")"
		# if $src is a relative symlink, the path needs to be treated with respect to the symlink's location
  		if [[ $src != /* ]]; then
			src="$(cd -P "$(dirname "$src")" >/dev/null && pwd)/$src"
		fi
	done
	echo "$(cd -P "$(dirname "$src")" >/dev/null && pwd)/$(basename "$src")"
}

### try_filepath_deduction
# If there's only a single file (match) in the folder $1, returns it
#
# Parametrization
#  $1 folder to search
#  $2 (optional) pattern - if omitted, defaults to * (= everything)
# Returns: - status: always 0
#          - stdout: filepath of the single match, if any
function try_filepath_deduction()
{
        local pattern="${2:-*}"
        local file_cnt=0
        if [ -d "$1" ]; then
                for filepath in "$1/"$pattern; do
                        if [ -f "$filepath" ]; then
                                single_file_path="$filepath"
                                ((file_cnt++))
                        fi
                        if [ $file_cnt -eq 2 ]; then
                                return
                        fi
                done
                echo "$single_file_path"
        fi
}

