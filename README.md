# Bash commons (bash_commons)
Library of bash functions. The functions are organized in several thematic collections; each collection is one source file. 

## Collections:
- Logging: [code](logging.sh) | [documentation](logging.md) | [tests](tests/logging.sh)
- Interaction: [code](interaction.sh) | [documentation](interaction.md)
- Filesystem: [code](filesystem.sh) | [documentation](filesystem.md) | [tests](tests/filesystem.sh)
- String handling: [code](string_handling.sh) | [documentation](string_handling.md) | [tests](tests/string_handling.sh)
- Testing: [code](testing.sh) | [documentation](testing.md)
- Helpers: [code](helpers.sh) | [documentation](helpers.md) | [tests](tests/helpers.sh)

### Filesystem
The filesystem collection provides: 
- wrappers for `mkdir` and `mv`, [create_directory()](filesystem.md#create_directory) and 
  [move()](filesystem.md#move) which provide permission checks, detailed status output and verbose variants 
  ([create_directory_verbose()](filesystem.md#create_directory_verbose) and [move_verbose()](filesystem.md#move_verbose)).
- utilities for path handling: [get_real_path()](filesystem.md#get_real_path) for any path and it special usecase 
  [get_script_path()](filesystem.md#get_script_path) which returns the "clean" path of the executed script as well 
  as the complementary [get_existing_path_part()](filesystem.md#get_existing_path_part) and 
  [get_new_path_part()](filesystem.md#get_new_path_part)
- a [is_writeable()](filesystem.md#is_writeable) utility which is able to check write permission also for "nested new
  paths"
- the [try_filepath_deduction()](filesystem.md#try_filepath_deduction) utility useful to handle "if there's only one file
  file of that type, use it" logic

#### Functions
[create_directory()](filesystem.md#create_directory)
[create_directory_verbose()](filesystem.md#create_directory_verbose)
[get_existing_path_part()](filesystem.md#get_existing_path_part)
[get_new_path_part()](filesystem.md#get_new_path_part)
[get_script_path()](filesystem.md#get_script_path)
[get_real_path()](filesystem.md#get_real_path)
[is_writeable()](filesystem.md#is_writeable)
[load_configuration_file_value()](filesystem.md#load_configuration_file_value)
[move()](filesystem.md#move)
[move_verbose()](filesystem.md#move_verbose)
[try_filepath_deduction()](filesystem.md#try_filepath_deduction)

### Interaction
The interaction function collection provides the basic building blocks for user interaction: [get_user_confirmation()](interaction.md#get_user_confirmation) 
for yes/no type questions, [get_user_choice()](interaction.md#get_user_choice) for multiple choice questions. Both use 
[read_and_validate()](interaction.md#read_and_validate) internally, which is the combination of a `read` and a regex check. 

#### Functions
- [read_and_validate()](interaction.md#read_and_validate)
- [get_user_confirmation()](interaction.md#get_user_confirmation)
- [get_user_choice()](interaction.md#get_user_choice)

### Logging
The logging function collection provides a range of features:
- distinct output chanels for `stdout` and file logging, each with their own logging level and message pattern 
- a log message buffer which allows to use [log()](logging.md#log) before the logger is configured. Applications can start logging 
  from the very beginning with logging "disabled" - in fact, messages go into the buffer, nothing is actually logged. Once the configuration 
  is known (usually, when the script parameters were processed - typically to handle that `-v` flag that should enable `stdout` logging), the 
  application calls [launch_logging()](logging.md#launch_logging) to "replay" the buffered messages and log them (or not) according to the 
  configuration in force when [launch_logging()](logging.md#launch_logging) is called
- a utility to shorten and hide secrets before they enter the logs: [prepare_secret_for_logging()](logging.md#prepare_secret_for_logging)

#### Functions
- [launch_logging()](logging.md#launch_logging)
- [log()](logging.md#log)
- [prepare_secret_for_logging()](logging.md#prepare_secret_for_logging)

### Testing
Testing is based on "sessions" which are sequences of test operations. A session begins with [initialize_test_session()](testing.md#initialize_test_session)
and ends with [conclude_test_session()](testing.md#conclude_test_session). Each test is the combination of 3 operations:

1. set the expected result in terms of status code, `stdout` content and `stderr` content with [configure_test()](testing.md#configure_test)
2. run the command capturing these values with [test()](testing.md#test)

To see examples of the test scripts, check out bash_commons' [tests](tests).

In some cases, f.ex. if the command uses piped input, it's not possible to use [test()](testing.md#test), the command has to be run in the testing script 
itself ([example](tests/helpers.sh#L81)). In this case the results can be evaluated using [check_test_results()](testing.md#check_test_results)
([test()](testing.md#test) calls it internally). 

#### Functions
- [check_test_results()](testing.md#check_test_results)
- [conclude_test_session()](testing.md#conclude_test_session)
- [configure_test()](testing.md#configure_test)
- [initialize_test_session()](testing.md#initialize_test_session)
- [test()](testing.md#test)

### Helpers
Utilities used by the other functions. 

#### Functions
- [calculate()](helpers.md#calculate)
- [capture()](helpers.md#capture)
- [conditional_exit()](helpers.md#conditional_exit)
- [get_random_string()](helpers.md#get_random_string)
- [get_piped_input()](helpers.md#get_piped_input)
- [is_function_defined()](helpers.md#is_function_defined)
- [is_globbing_enabled()](helpers.md#is_globbing_enabled)
- [set_global_variable()](helpers.md#set_global_variable)

# Snippets

Simplified script directory resolution (f.ex. in an installer before `bash_commons` are available)
```bash
# Exit with error message on file symlinks, set $script_folder to the directory in which the script is located (folder symlinks resolved)
symlink_error_msg="Error: Please don't call ... through file symlinks, this confuses the script about its own location. Call it directly. Aborting..."
if [ -h "${BASH_SOURCE[0]}" ]; then echo "$symlink_error_msg"; exit 1; fi
script_folder="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
```
**Important**: this code has to run before files are sourced, subshells are launched etc. because such operations affect `$BASH_SOURCE` (`get_script_path()` 
               from [filesystem.sh](filesystem.sh) is able to cope with that and file symlinks)
