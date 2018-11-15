#! /bin/bash
# dependencies: echo, grep, sed

### sanitize_variable_quotes
# In configuration files, if a definition is var="...", the loaded value is '"..."' (the double quotes are part of the value).
# This function removes them. It checks for single and double quotes.
#
# Parametrization:
#  $1 string to process
# Return: - status: always 0
#         - stdout: processed string
function sanitize_variable_quotes()
{
        if [ ! -z "$(echo "$1" | grep "^\s*[\"']" | grep "[\"']\s*$")" ]; then
                echo "$1" | sed "s/[^\"']*[\"']//" | sed "s/\(.*\)[\"'].*/\1/"
        else
                echo "$1"
        fi
}

### trim
# Cut leading and trailing whitespace on either the provided parameter or the piped stdin
#
# Parametrization:
#  $1 (optional) string to trim. If it's empty trim tries to get input from a eventual stdin pipe
# Returns: - status: always 0
#          - stdout: trimmed $1/stdin
# Usage:
#  - Input as parameter: trimmed_string=$(trim "$string_to_trim")
#  - Piped input: trimmed_string=$(echo "$string_to_trim" | trim)
function trim()
{
        local input
        if [ ! -z "$1" ]; then
                input="$1"
        else
                if [ -p /dev/stdin ]; then
                        input="$(cat)"
                fi
        fi
        echo "$input" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}
