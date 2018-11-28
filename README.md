# Bash commons (bash_commons)
Library of bash functions. The functions are organized in several thematic collections; each collection is one source file. 

## Collections:
- Logging: [code](logging.sh) | [documentation](logging.md) | [tests](tests/logging.sh)
- Interaction: [code](interaction.sh) | [documentation](interaction.md)
- Filesystem: [code](filesystem.sh) | [documentation](filesystem.md) | [tests](tests/filesystem.sh)
- String handling: [code](string_handling.sh) | [documentation](string_handling.md) | [tests](tests/string_handling.sh)
- Testing: [code](testing.sh) | [documentation](testing.md)
- Helpers: [code](helpers.sh) | [documentation](helpers.md) | [tests](tests/helpers.sh)

### Interaction
#### Functions
- [read_and_validate()](interaction.md#read_and_validate)
- [get_user_confirmation()](interaction.md#get_user_confirmation)
- [get_user_choice()](interaction.md#get_user_choice)
- [conditional_exit()](interaction.md#conditional_exit)

### Logging
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
