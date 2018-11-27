# bash_commons
Collection of bash functions for common tasks

# Function collections:
- Testing: [code](testing.sh) | [documentation](testing.md)
	- [initialize_test_session()](testing.md#initialize_test_session)
	- [configure_test()](testing.md#configure_test)
	- [test()](testing.md#test)
	- [check_test_results()](testing.md#check_test_results)
	- [conclude_test_session()](testing.md#conclude_test_session)
- Helpers: [code](helpers.sh) | [documentation](helpers.md) | [unit tests](tests/helpers.sh
	- [capture()](helpers.md#capture)
	- [is_function_defined()](helpers.md#is_function_defined)
	- [set_global_variable()](helpers.md#set_global_variable)
	- [calculate()](helpers.md#calculate)
	- [get_piped_input()](helpers.md#get_piped_input)
	- [get_random_string()](helpers.md#get_random_string)
	- [is_globbing_enabled()](helpers.md#is_globbing_enabled)
- Logging: [code](logging.sh) | [documentation](logging.md) | [unit tests](tests/logging.sh)
	- [log()](logging.md#log)
	- [launch_logging()](logging.md#launch_logging)
	- [prepare_secret_for_logging()](logging.md#prepare_secret_for_logging)
- Interaction: [code](interaction.sh) | [documentation](interaction.md)
	- [read_and_validate()](interaction.md#read_and_validate)
	- [get_user_confirmation()](interaction.md#get_user_confirmation)
	- [get_user_choice()](interaction.md#get_user_choice)
	- [conditional_exit()](interaction.md#conditional_exit)

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
