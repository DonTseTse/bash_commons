#! /bin/bash

# Logging functions
#
# Author: DonTseTse
# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/logging.md
# Dependencies: echo, read, printf, sed

##### Commons dependencies
[ -z "$commons_path" ] && echo "Bash commons - Logging: \$commons_path not set or empty, unable to resolve internal dependencies. Aborting..." && exit 1
[ ! -r "$commons_path/string_handling.sh" ] && echo "Bash commons - Logging: unable to source string handling functions at '$commons_path/string_handling.sh' - aborting..." && exit 1
. "$commons_path/string_handling.sh"    # for get_sed_extract_expression()
[ ! -r "$commons_path/helpers.sh" ] && echo "Bash commons - Logging: unable to source helper functions at '$commons_path/helpers.sh' - aborting..." && exit 1
. "$commons_path/helpers.sh"    	# for calculate()

##### Functions
# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/logging.md#log
function log()
{
	local lc_logging_available="${logging_available:-1}" msg_log_level="${2:-1}" line
	# check that the necessary variables are numeric, otherwise -eq complains
	[[ ! "$lc_logging_available" =~ ^[0-1]+$ ]] || [[ ! "$msg_log_level" =~ ^[0-9]+$ ]] && return 1
	[ -n "$stdout_log_level" ] && [ "$stdout_log_level" -ge $msg_log_level ] && [ ! "$3" = "file" ] && local lc_stdout_pattern="${stdout_log_pattern:-%s\n}"
	[ -n "$log_filepath" ] && [[ "$log_level" =~ ^[0-9]+$ ]] && [ "$log_level" -ge $msg_log_level ] && [ ! "$3" = "stdout" ] && local lc_file_pattern="${log_pattern:-%s\n}"
	# IFS set to whitespace preservation
	while IFS='' read -r line; do
		if [ "$lc_logging_available" -eq 0 ]; then
			[ -n "$logging_backlog" ] && local idx=${#logging_backlog[*]} || local idx=0
			logging_backlog[$idx]="$line|$2|$3"
			continue
		fi
		[ -n "$lc_stdout_pattern" ] && printf "$lc_stdout_pattern" "${line}"
		#printf "$line\n" can lead to string interpretation. f.ex. if $line = '- a list item' it's going to complain printf: - : invalid option
		[ -n "$lc_file_pattern" ] && printf "$lc_file_pattern" "${line}" >> "$log_filepath"
	done <<< "$1"
	return 0	# enforcing status otherwise it's unknown depending on the order of internal operations
}

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/logging.md#launch_logging
function launch_logging()
{
	logging_available=1
	local idx backlog_entry output_restriction entry_log_level
	for idx in ${!logging_backlog[*]}; do
		backlog_entry="$(echo "${logging_backlog[$idx]}" | sed -e $(get_sed_extract_expression "|" "before" "last"))"
		output_restriction="${logging_backlog[$idx]:${#backlog_entry}+1}"
		backlog_entry="$(echo "$backlog_entry" | sed -e $(get_sed_extract_expression "|" "before" "last"))"
		entry_log_level="${logging_backlog[$idx]:${#backlog_entry}+1:-${#output_restriction}-1}"
		#DEBUG >&2 echo "Backlog entry: ${logging_backlog[$idx]} - message: $backlog_entry - log level: $entry_log_level - output restriction: $output_restriction"
		log "$backlog_entry" "$entry_log_level" "$output_restriction"
	done
	logging_backlog=()
}

# Documentation: https://github.com/DonTseTse/bash_commons/blob/master/logging.md#prepare_secret_for_logging
function prepare_secret_for_logging()
{
        [ -z "$1" ] && return 1
        local secret_size=${#1} secret_size_factor="${3:-0.25}" secret_size_limit nb_chars=$2 from_end=0 secret_hint
        secret_size_limit=$(calculate "$secret_size * $secret_size_factor" "int")
        [ -z "$2" ] && nb_chars=$secret_size_limit
        [[ "$2" =~ ^-[0-9]+$ ]] && nb_chars=$((nb_chars * -1)) && from_end=1
        [ $nb_chars -gt $secret_size_limit ] && nb_chars=$secret_size_limit
        [ $nb_chars -gt 0 ] && [ $from_end -eq 0 ] && secret_hint=" - begins with '${1:0:$nb_chars}'"
        [ $nb_chars -gt 0 ] && [ $from_end -eq 1 ] && secret_hint=" - ends with '${1: -$nb_chars}'"
        echo "[Secret$secret_hint]"
}
