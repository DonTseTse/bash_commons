#! /bin/bash
### Configuration

### Preparation
commons_path="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && dirname "$(pwd)")"
. "$commons_path/logging.sh"
. "$commons_path/testing.sh"

initialize_test_session "logging.sh functions"

### Tests
echo "*** prepare_secret_for_logging() ***"
configure_test 1 ""
test prepare_secret_for_logging

configure_test 0 "[Secret - begins with 't']"
test prepare_secret_for_logging "test"

configure_test 0 "[Secret - begins with 'lo']"
test prepare_secret_for_logging "longer_secret" 2

configure_test 0 "[Secret - begins with 'lon']"
test prepare_secret_for_logging "longer_secret" 5

configure_test 0 "[Secret - begins with 'longe']"
stdout="$(prepare_secret_for_logging "longer_secret" 5 "0.5")"
check_test_results "prepare_secret_for_logging \"longer_secret\" 5 \"0.5\""  $? "$stdout"

configure_test 0 "[Secret - ends with 'et']"
test prepare_secret_for_logging "longer_secret" -2

echo "*** log() + launch_logging() ***"
configure_test 0 ""
test log "log message"

stdout_log_level=1
echo " - \$stdout_log_level set to 1"
configure_test 0 "log message"
test log "log message"

configure_test 0 "log message"
test log "log message" 1

configure_test 0 ""
test log "log message level 2" 2

stdout_log_level=2
echo " - \$stdout_log_level set to 2"
configure_test 0 "log message level 2"
test log "log message level 2" 2

stdout_log_pattern="Log: %s"
echo " - \$stdout_log_pattern set to 'Log: %s'"
configure_test 0 "Log: log message"
test log "log message"

log_filepath="$(mktemp)"
echo " - \$log_filepath set to $log_filepath"
configure_test 0 "Log: log message #1"
test log "log message #1"

echo "   The message is not logged because \$log_level is not a numeric value. Testing that..."
configure_test 0 ""
test cat "$log_filepath"

log_level=1
echo " - \$log_level set to 1"
configure_test 0 "Log: log message #2"
test log "log message #2"

configure_test 0 "log message #2"
test tail -n 1 "$log_filepath"

configure_test 0 "Log: log message level 1"
test log "log message level 1" 1

configure_test 0 "log message level 1"
test tail -n 1 "$log_filepath"

configure_test 0 "Log: log message level 2"
test log "log message level 2" 2

echo "   The log file entry should still be the same than on the previous check; the last message was not logged because the log() call had a level above \$log_level. Testing that..."
configure_test 0 "log message level 1"
test tail -n 1 "$log_filepath"

log_level=2
echo " - \$log_level set to 2"
configure_test 0 "Log: log message level 2"
test log "log message level 2" 2

configure_test 0 "log message level 2"
test tail -n 1 "$log_filepath"

log_pattern="[Log $log_filepath]: %s\n"
echo " - \$log_pattern set to '[Log $log_filepath]: %s'"

configure_test 0 ""
test log "log message for file" 1 file

configure_test 0 "[Log $log_filepath]: log message for file"
test tail -n 1 "$log_filepath"

configure_test 0 "Log: log message for stdout"
test log "log message for stdout" 1 stdout

echo "   The log file entry should still be the same than on the previous check; the last message was not logged because the log() call was restricted to stdout. Testing that..."
configure_test 0 "[Log $log_filepath]: log message for file"
test tail -n 1 "$log_filepath"

#logging_backlog=()
logging_available=0
echo " - \$logging_available set to 0 => logs go into a cache, ready to be processed once launch_logging() is called"
rm "$log_filepath"
log_filepath="$(mktemp)"
echo " - New \$log_filepath at $log_filepath"

# Note: log() has to be called on global level and not via test otherwise it doesn't operate on the global variables
log "backlog msg #1"
echo " - Running \$> log \"backlog msg #1\""
log "backlog msg level 2" 2
echo " - Running \$> log \"backlog msg level 2\" 2"
log "backlog msg stdout" 1 stdout
echo " - Running \$> log \"backlog msg stdout\" 1 stdout"
stdout_log_pattern="   Log: %s\n"
log_pattern="   File log: %s\n"
echo " - Set stdout_log_pattern to '   Log: %s\n' and log_pattern to '    File log: %s\n'. Calling launch_logging()"
launch_logging
echo " - cat $log_filepath"
cat "$log_filepath"

configure_test 0 ""
[ $logging_available -eq 1 ]
check_test_results "[ \$logging_available -eq 1 ]" $? ""

logging_available=2
echo " - Setting \$logging_available to 2 (forbidden). log() fails with status code 1"

configure_test 1 ""
test log "Logging status confusing"

logging_available=1
echo " - Setting \$logging_available to 1. Wrong log message level can also make log() fail with code 1"

test log "Message level confusing" a
echo "   A wrong output restriction is just ignored ('stdout' and 'file' excpected)"

configure_test 0 "   Log: Unknown output restriction, just ignored"
test log "Unknown output restriction, just ignored" 1 "unknown"

conclude_test_session
