# Dependencies: - bash: arrays, local, [], [[]], &&, <<<
#               - fcts: printf, echo, sed

### log
# Logging helper with support for prefix-aware multi-line output and independent stdout and file output handling
#
# Parametrization:
#  $1 message to log
#  $2 (optional) log level - if omitted, defaults to 1
#  $3 (optional) output restriction - if omitted, both output channels are used
#     - "file" avoids stdout write even if $stdout_logging is enabled
#     - "stdout" avoid file logging even is $log_filepath is set
# Returns: - status: 0 on success, 1 if $logging_available is set to something else than 0 or 1 and if $2 is set to something else than
#                    a single numeric digit
#          - stdout: depending on configuration, the message for the console => log should never be called in a subshell
# Globals used: - $logging_available (optional, defaults to 1/enabled internally if omitted)
#               - $stdout_log_level (optional, if omitted, the system doesn't print on stdout)
#               - $stdout_log_pattern (optional, default to ?)
#               - $log_filepath (optional, if empty, no file logging occurs)
#               - $log_level (optional, defaults to 1 internally if omitted)
#		- $log_pattern (optional, default to ?)
#               - $logging_backlog array (optional, created internally)
function log()
{
	local lc_logging_available="${logging_available:-1}"
	local msg_log_level="${2:-1}"
	local line
	# check that the necessary variables are numeric, otherwise -eq complains
	if [[ ! "$lc_logging_available" =~ ^[0-1]+$ ]] || [[ ! "$msg_log_level" =~ ^[0-9]+$ ]]; then
		return 1
	fi
	if [ ! -z "$stdout_log_level" ] && [ "$stdout_log_level" -ge $msg_log_level ] && [ ! "$3" = "file" ]; then
		local lc_stdout_pattern="${stdout_log_pattern:-%s\n}"
	fi
	if [ ! -z "$log_filepath" ] && [[ "$log_level" =~ ^[0-9]+$ ]] && [ "$log_level" -ge $msg_log_level ] && [ ! "$3" = "stdout" ]; then
		local lc_file_pattern="${log_pattern:-%s\n}"
	fi
	# IFS set to whitespace preservation
	while IFS='' read -r line; do
	# log caching if logging is not available
		if [ "$lc_logging_available" -eq 0 ]; then
			if [ ! -z "$logging_backlog" ]; then
				logging_backlog[${#logging_backlog[*]}]="$line|$2|$3"
			else
				logging_backlog[0]="$line|$2|$3"
			fi
			continue
		fi
		if [ ! -z "$lc_stdout_pattern" ]; then
			printf $lc_stdout_pattern "${line}"
			#printf "$line\n" can lead to string interpretation. f.ex. if $line = '- a list item' it's going to complain printf: - : invalid option
		fi
		if [ ! -z "$lc_file_pattern" ]; then
			printf "$lc_file_pattern" "${line}" >> "$log_filepath"
		fi
	done <<< "$1"
}

### launchLogging
# Processes the logging backlog and clears it
#
# Returns: status always 0
# Globals used: - $logging_available
#               - $logging_backlog
function launchLogging()
{
	logging_available=1
	local idx
	local backlog_entry
	local entry_output_restriction
	local entry_log_level
	for idx in ${!logging_backlog[*]}; do
		backlog_entry="${logging_backlog[$idx]}"
		entry_output_restriction=$(echo "$backlog_entry" | sed 's/.*|//')
		backlog_entry=$(echo "$backlog_entry" | sed 's/\(.*\)|.*/\1/')
		entry_log_level=$(echo "$backlog_entry" | sed 's/.*|//')
		backlog_entry=$(echo "$backlog_entry" | sed 's/\(.*\)|.*/\1/')
		log "$backlog_entry" "$entry_log_level" "$entry_output_restriction"
	done
	logging_backlog=()
}
