#! /bin/bash

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

