#! /bin/bash
#
# Written in 2018 by DonTseTse
#
# Dependencies: printf, echo, sed
#

. "$commons_path/string_handling.sh"

### log
# Logging helper with support for prefix-aware multi-line output and independent stdout and file output handling
#
# Important: always call this function and launch_logging() directly on global level and not through $(...), otherwise
#            the global variables don't work (a subshell receives a copy of the parent shell's variable set and has
#            no access to the "original" ones)
#
#
# Parametrization:
#  $1 message to log
#  $2 (optional) log level - if omitted, defaults to 1
#  $3 (optional) output restriction - if omitted, both output channels are used
#     - "file" avoids stdout write even if $stdout_logging is enabled
#     - "stdout" avoid file logging even is $log_filepath is set
# Pipes: - stdin: ignored
#        - stdout: depending on configuration, the message for the console => log should never be called in a subshell
# Status: 0 on success,
#         1 is used in several error configurations:
#           - if $logging_available is set to something else than 0 or 1
#           - if the message log level $2 is set to something else than a single numeric digit
# Globals used: - $logging_available (optional, defaults to 1/enabled internally if omitted)
#               - $stdout_log_level (optional, if omitted, the system doesn't print on stdout)
#               - $stdout_log_pattern (optional, defaults to %s ("just" the message))
#               - $log_filepath (optional, if empty, no file logging occurs)
#               - $log_level (optional, if it's not a numeric value, file logging is disabled)
#		- $log_pattern (optional, defaults to %s ("just" the message"))
#               - $logging_backlog array (optional, created internally)
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
		#if [ -n "$lc_file_pattern" ]; then
		#	printf "$lc_file_pattern" "${line}" >> "$log_filepath"
		#fi
		[ -n "$lc_file_pattern" ] && printf "$lc_file_pattern" "${line}" >> "$log_filepath"
	done <<< "$1"
	return 0	# enforcing status otherwise it's unknown depending on the order of internal operations
}

### launch_logging
# Processes the logging backlog and clears it
#
# Parametrization: -
# Pipes: - stdin: ignored
#        - stdout: if stdout logging is enabled, the logs for stdout, empty otherwise
# Status: 0
# Globals: $logging_available, $logging_backlog
function launch_logging()
{
	logging_available=1
	local idx backlog_entry output_restriction entry_log_level
	for idx in ${!logging_backlog[*]}; do
		backlog_entry="$(echo "${logging_backlog[$idx]}" | sed -e $(get_sed_extract_expression "|" "before" "last"))"
		output_restriction="${logging_backlog[$idx]:${#backlog_entry}+1}"
		backlog_entry="$(echo "$backlog_entry" | sed -e $(get_sed_extract_expression "|" "before" "last"))"
		entry_log_level="${logging_backlog[$idx]:${#backlog_entry}+1:-${#output_restriction}-1}"
		#>&2 echo "Backlog entry: ${logging_backlog[$idx]} - message: $backlog_entry - log level: $entry_log_level - output restriction: $output_restriction"
		log "$backlog_entry" "$entry_log_level" "$output_restriction"
	done
	logging_backlog=()
}

### prepare_secret_for_logging
#
# Parametrization:
#  $1 secret
#  $2 amount of chars to show. If > 0, the amount is shown from the beginning of the secret, if < 0, from the end
#  $3 security factor - a decimal value between 0 and 1 which decides how much of the secret can be shown at most - overwrites
#                       $2 if necessary
# Pipes: - stdin: ignored
#        - stdout: the log-formatted secret
# Status: 0 in case of success
#         1 if $1 is undefined or empty
function prepare_secret_for_logging()
{
        [ -z "$1" ] && return 1
        local secret_size=${#1} secret_size_factor="${3:-0.25}" secret_size_limit nb_chars=$2 from_end=0 secret_hint
        secret_size_limit=$(calculate "$secret_size * $secret_size_factor" "int")
        [ -z "$2" ] && nb_chars=$secret_size_limit
        [[ "$2" =~ ^-[1-9]+$ ]] && nb_chars=$((nb_chars * -1)) && from_end=1
        [ $nb_chars -gt $secret_size_limit ] && nb_chars=$secret_size_limit
        [ $nb_chars -gt 0 ] && [ $from_end -eq 0 ] && secret_hint=" - begins with '${1:0:$nb_chars}'"
        [ $nb_chars -gt 0 ] && [ $from_end -eq 1 ] && secret_hint=" - ends with '${1: -$nb_chars}'"
        echo "[Secret$secret_hint]"
}
