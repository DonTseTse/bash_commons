# Bash commons (bash_commons)
Library of bash functions organized in several thematic collections; each is one source file. 

## How to:
- Clone this repository
- Set up a global variable `$commons_path` set to the absolute path of the folder with the cloned code. The collections use it to load
their internal dependancies, most will complain if it's not set
- Source the collection file which contains the desired functions

Example:
```bash
commons_path="/path/to/bash_commons"
. "$commons_path/filesystem.sh"
# from here on, all functions from filesystem.sh can be used
```

The **tests** can be found in `/tests`. 

## Collections:
<table>
<tr><td><b>Filesystem</b></td><td><a href="#filesystem">Overview</a></td><td><a href="filesystem.md">Documentation</a></td><td><a href="filesystem.sh">Code</a></td>
	<td><a href="tests/filesystem.sh">Tests</a></td></tr>
<tr><td><b>String handling</b></td><td><a href="#string-handling">Overview</a></td><td><a href="string_handling.md">Documentation</a></td>
	<td><a href="string_handling.sh">Code</a></td><td><a href="tests/string_handling.sh">Tests</a></td></tr>
<tr><td><b>Logging</b></td><td><a href="#logging">Overview</a></td><td><a href="logging.md">Documentation</a></td>
	<td><a href="logging.sh">Code</a></td><td><a href="tests/logging.sh">Tests</a></td></tr>
<tr><td><b>Interaction</b></td><td><a href="#interaction">Overview</a></td><td><a href="interaction.md">Documentation</a></td><td><a href="interaction.sh">Code</a></td>
	<td></td></tr>
<tr><td><b>Helpers</b></td><td><a href="#helpers">Function index</a></td><td><a href="helpers.md">Documentation</a></td><td><a href="helpers.sh">Code</a></td>
	<td><a href="tests/helpers.sh">Tests</a></td></tr>
<tr><td><b>Testing</b></td><td><a href="#testing">Overview</a></td><td><a href="testing.md">Documentation</a></td><td><a href="testing.sh">Code</a></td>
	<td></td></tr>

### Filesystem
The filesystem collection provides: 
- wrappers for `mkdir`, `mv`/`cp` and `rm` with permission and existence checks that allow for detailed error status codes 
  combined with a parameter which controls the functions' `stdout` behavior and a verbose mode with configurable 
  message templates using runtime variable injection:
	- [create_folder()](filesystem.md#create_folder)
	- [move_file()](filesystem.md#move_file) and [move_folder()](filesystem.md#move_folder)
	- [copy_file()](filesystem.md#copy_file) and [copy_folder()](filesystem.md#copy_folder)
	- [remove_file()](filesystem.md#remove_file) and [remove_folder()](filesystem.md#remove_folder)
- [get_real_path()](filesystem.md#get_real_path) and the special application [get_script_path()](filesystem.md#get_script_path) 
  which return "clean" paths. Further path utilities include the complementary 
  [get_existing_path_part()](filesystem.md#get_existing_path_part) and [get_new_path_part()](filesystem.md#get_new_path_part)
- [is_writeable()](filesystem.md#is_writeable) which, on top of the classic write permission check, is able to handle permission 
  checks for filesystem operations involving nested folders, like `mkdir` with the `-p` flag
- [try_filepath_deduction()](filesystem.md#try_filepath_deduction) for a "if there's only one file matching, take that" logic
- [load_configuration_file_value()](filesystem.md#load_configuration_file_value) which allows to load values from files instead of
  sourcing them

### String handling
The string handling collections includes functions to modify strings and control certain properties as well as `sed` helpers:
- [escape()](string_handling.md#escape) adds backslashes to certain characters on a string provided as piped input
- [trim()](string_handling.md#trim) removes leading or trailing whitespaces
- [find_substring()](string_handling.md#find_substring) returns the position of the first match of a string inside of another string, 
  if there's any
- [sanitize_variable_quotes()](string_handling.md#sanitize_variable_quotes) allows to remove enclosing quotes in a string
- [is_string_a()](string_handling.md#is_string_a) check  whether a string complies to a certain type, f.ex. "absolute filepath" or "email"
- [get_absolute_path()](string_handling.md#get_absolute_path) is a helper to prepend relative paths with a root directory
- [get_string_bytes()](string_handling.md#get_string_bytes) and [get_string_bytelength()](string_handling.md#get_string_bytelength) 
  allow to work with strings that contain non-ASCII characters
- `sed` helpers: [get_sed_replace_expression()](string_handling.md#get_sed_replace_expression) and 
  [get_sed_extract_expression()](string_handling.md#get_sed_extract_expression) return "expressions" that can be directly
  passed to `sed` - the functions take care to select a collision-free separator character using 
  [find_sed_operation_separator()](string_handling.md#find_sed_operation_separator) and escape characters with special signification 
  using [escape_sed_special_characters()](string_handling.md#escape_sed_special_characters). 

### Interaction
The interaction collection provides the basic building blocks for interactive scripts, f.ex. installers:
[get_user_confirmation()](interaction.md#get_user_confirmation) for yes/no type questions,
[get_user_choice()](interaction.md#get_user_choice) for multiple choice questions. Both use
[read_and_validate()](interaction.md#read_and_validate) internally, which is simply the combination of a `read` and a regex check.

### Logging
The logging collection's functions work together as one module which provides several features:
- distinct output channels for `stdout` and file logging, each with their own logging level and message pattern
- a log message buffer which allows to use [log()](logging.md#log) before the logger is configured. Applications can start logging
  from the very beginning with logging "disabled" - in fact, messages go into the buffer, nothing is actually logged. Once the configuration
  is known (usually, when the script parameters were processed - typically to handle that `-v` flag that enables `stdout` logging), the
  application calls [launch_logging()](logging.md#launch_logging) to "replay" the buffered messages and log them (or not) according to the
  configuration in force when [launch_logging()](logging.md#launch_logging) is called
- a utility to shorten and hide secrets before they enter the logs: [prepare_secret_for_logging()](logging.md#prepare_secret_for_logging)

### Testing
Testing is based on "sessions" which are sequences of test operations. A session begins with [initialize_test_session()](testing.md#initialize_test_session)
and ends with [conclude_test_session()](testing.md#conclude_test_session). Each test follows the scheme:

1. set the expected result in terms of status code and `stdout` content with [configure_test()](testing.md#configure_test)
2. run the command capturing these values with [test()](testing.md#test)

In some cases, f.ex. if the command uses piped input, it's not possible to use [test()](testing.md#test), the command has to be run in the testing script
itself ([example](tests/helpers.sh#L99)). In this case the results shall be evaluated using [check_test_results()](testing.md#check_test_results)
([test()](testing.md#test) calls it internally).

For examples of test scripts, check out bash_commons' own [tests](tests).

### Helpers
Used by the other modules. Function index:

- [calculate()](helpers.md#calculate)
- [capture()](helpers.md#capture)
- [conditional_exit()](helpers.md#conditional_exit)
- [get_array_element()](helpers.md#get_array_element)
- [get_random_string()](helpers.md#get_random_string)
- [get_piped_input()](helpers.md#get_piped_input)
- [is_command_defined()](helpers.md#is_command_defined)
- [is_function_defined()](helpers.md#is_function_defined)
- [is_globbing_enabled()](helpers.md#is_globbing_enabled)
- [set_global_variable()](helpers.md#set_global_variable)

# TODO
- helpers/get_array_element() doc: add links to problem explanations
