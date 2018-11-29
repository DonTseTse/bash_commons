Documentation for the functions in [string_handling.sh](string_handling.sh). A general overview is given in [the project documentation](README.md#string_handling).

If the pipes are not documented, the default is:
- `stdin`: piped input ignored
- `stdout`: empty

Parameters enclosed in brackets [ ] are optional.

### escape
# Takes the piped input and escapes the char(s) given as parameter with backslashes
#
# Special care is taken to disable bash globbing to make sure that affected characters, typically '*', can be escaped properly
# At the end, the original globbing configuration is restored.
#
# Usage: - $> echo "path/to/file" | escape "/"
#          gives "path\/to\/file" on stdout
#
# Parametrization:
#  $1...n characters to escape
# Pipes: - stdin: read completely
#        - stdout: the escaped string
# Status: 0

### sanitize_variable_quotes
# In configuration files, if a definition is var="...", the loaded value is '"..."' (the double quotes are part of the value).
# This function removes them. It checks for single and double quotes.
#
# Parametrization:
#  $1 (optional) string to sanitize
# Pipes: - stdin: read completely if $1 is undefined/empty
#        - stdout: processed string
# Status: 0


### trim
# Cut leading and trailing whitespace on either the provided parameter or the piped stdin
#
# Usage:
#  - Input as parameter: trimmed_string=$(trim "$string_to_trim")
#  - Piped input: trimmed_string=$(echo "$string_to_trim" | trim)
#
# Note: in the sed expressions, \s stands for [[:space:]]
#
# Parametrization:
#  $1 (optional) string to trim. If it's empty trim tries to get input from a eventual stdin pipe
# Pipes: - stdin: read completely if $1 is undefined/empty
#        - stdout: trimmed $1/stdin
# Status: 0 always, even if $1 and stdin are undefined/empty

### find_substring
# Finds the position of the first match of $2 in $1 (the start position of the match, to be precise)
# Returns -1 if $2 is not found inside $1.
#
# Inspired by https://stackoverflow.com/questions/5031764/position-of-a-string-within-a-string-using-linux-shell-script
#
# Parametrization:
#  $1 string to search in
#  $2 char/string to find - exact matching is used (bash's matching special chars are disabled by string escaping)
# Pipes: - stdin: ignored
#        - stdout: -1 if $2 is not found in $1
#                  the position of the first occurence of $2 in $1
# Status: 0

### get_absolute_path
# Prepends $1 with $2 if defined, or the current working directory
#
# The path $1 and the optional root directory $2 don't have to exist
#
# Dev note: that's the reason why this function is in string_handling.sh and not filesystem.sh
#
# Parametrization:
#  $1 path to "absolutify" if necessary
#  $2 (optional) root path - if omitted, the current working directory is used
# Pipes: - stdin: ignored
#        - stdout: the computed absolute path
# Status: 0 always

### is_string_a
The function is able to work in 2 modes depending on $3:
- in "status" mode it may be used easily in instruction chains (see examples below); all that matters is that it
  returns with status code 0 in case of success and a positive value in case of error. The error types "$1 empty"
  "test type unknown" and "check failed" all have the same status code (1) and may hence not be distinguished by
  the caller
- in "stdout" mode the status code indicates only the execution success/error state, the result of the operation is
  on stdout. There's hence no ambiguity on the status code signification

**Warning**: be careful with inverted checks in combination with an empty $1. One might consider that

	is_string_a "" "!absolute_filepath"
should return success since an empty string is indeed not an absolute filepath, but because of the
protections it returns 1/error

Usage examples: the status mode allows to use it in statement chains easily
	
	is_string_a "$potential_int" "integer" && echo "This is a integer: $potential_int"
whereas the stdout mode gives a better control, adapted if $1 can't be trusted

	is_int=$(is_string_a "$unknown" "integer")
        [ $? -eq 0 ] && [ $is_int -eq 1 ] && echo "This is a integer: $unknown"

#TODO email etc
#to check for relative filepath, use '!absolute_filepath'

<table>
        <tr><td rowspan="3"><b>Param.</b></td>
                <td align="center"><code>$1</code></td><td width="90%">string to check</td></tr>
        <tr>    <td align="center"><code>$2</code></td><td>test type:
		<ul>
			<li><em>absolute_filepath</em>: checks if the first non-whitespace character of <code>$1</code> is a <em>/</em>
                        No filesystem check is done. Works with inexistant filepaths</li>
			<li><em>integer</em>: checks if the string only contains numbers</li>
		</ul>
		Types can be inverted with a leading <em>!</em>, f.ex. <em>!integer</em>
	</td></tr>
        <tr>    <td align="center">[<code>$3</code>]</td><td>stdout output flag (output mode):
		<ul>
			<li>if omitted, set to an empty string or anything else than <em>1</em>, the function is in "status mode"
			warning: use with care especially with inverted types! See the explanations above for details</li>
			<li>if set to <em>1</em>, the function is in "stdout" mode
		</ul>
	</td></tr>
	<tr><td colspan="3">pipes, status, etc. are given below depending on the mode the function is in</td></tr>
</table>

Pipes & status in "status mode":
<table>
	<tr><td rowspan="2"><b>Pipes</b></td>
                <td align="center"><code>stdin</code></td><td>piped input ignored</td></tr>
        <tr>    <td align="center"><code>stdout</code></td><td>empty</td></tr>
        <tr><td rowspan="3"><b>Status</b></td>
                <td align="center"><em>0</em></td><td>the test type <code>$2</code> passed on <code>$1</code></td></tr>
        <tr>    <td align="center"><em>1</em></td><td>used in 3 situations:
			<ul>
				<li>the test type <code>$2</code> failed on <code>$1</code></li>
				<li><code>$1</code> is empty</li>
				<li><code>$2</code> is unknown</li>
			</ul>
	</td></tr>
	<tr>    <td align="center"><em>2</em></td><td><code>$2</code> is empty</td></tr>
</table>

Pipes & status in "stdout mode":
<table>
	<tr><td rowspan="2"><b>Pipes</b></td>
		<td align="center"><code>stdin</code></td><td>piped input ignored</td></tr>
	<tr>    <td align="center"><code>stdout</code></td><td>
		<ul>
			<li><em>0</em> the test of type <code>$2</code> failed on <code>$1</code></li>
			<li><em>1</em> the test of type <code>$2</code> passed on <code>$1</code></li>
		</ul>
	</td></tr>
	<tr><td rowspan="4"><b>Status</b></td>
		<td align="center"><em>0</em></td><td>the test was executed, the result is on <code>stdout</code></td></tr>
	<tr>    <td align="center"><em>1</em></td><td><code>$1</code> is empty</td></tr>
	<tr>    <td align="center"><em>2</em></td><td><code>$2</code> is empty</td></tr>
	<tr>    <td align="center"><em>3</em></td><td><code>$2</code> is unknown</td></tr>
</table>

### get_string_bytelength
<table>
        <tr><td><b>Param.</b></td><td align="center"><code>$1</code></td><td width="90%">string to get the bytelength of</td></tr>
        <tr><td rowspan="2"><b>Pipes</b></td>
                <td align="center"><code>stdin</code></td><td>piped input ignored</td></tr>
        <tr>    <td align="center"><code>stdout</code></td><td>the bytelength of <code>$1</code></td></tr>
        <tr><td><b>Status</b></td><td align="center"><em>0</em></td><td></td></tr>
</table>

### get_string_bytes
Returns byte representation of a string. Non-ascii chars like à,é,å,ê,etc. are transformed to their character code,
é f.ex. is \303\251

<table>
        <tr><td><b>Param.</b></td><td align="center"><code>$1</code></td><td width="90%">string to get the byte representation of</td></tr>
        <tr><td rowspan="2"><b>Pipes</b></td>
                <td align="center"><code>stdin</code></td><td>piped input ignored</td></tr>
        <tr>    <td align="center"><code>stdout</code></td><td>the byte representation of <code>$1</code></td></tr>
        <tr><td><b>Status</b></td><td align="center"><em>0</em></td><td></td></tr>
</table>

### escape_sed_special_characters
<table>
        <tr><td><b>Param.</b></td><td align="center"><code>$1</code></td><td width="90%">string to escape</td></tr>
        <tr><td rowspan="2"><b>Pipes</b></td>
                <td align="center"><code>stdin</code></td><td>piped input ignored</td></tr>
        <tr>    <td align="center"><code>stdout</code></td><td>escaped <code>$1</code></td></tr>
        <tr><td><b>Status</b></td><td align="center"><em>0</em></td><td></td></tr>
</table>

### get_sed_extract_expression
Compute sed string extraction expression
<table>
        <tr><td rowspan="2"><b>Param.</b></td>
                <td align="center"><code>$1</code></td><td width="90%">marker</td></tr>
        <tr>    <td align="center"><code>$2</code></td><td>part to extract: can be <em>before</em> or <em>after</em>, with regard to <code>$3</code></td></tr>
        <tr>    <td align="center"><code>$3</code></td><td>occurence: can be <em>first</em> or <em>last</em></td></tr>
        <tr><td rowspan="2"><b>Pipes</b></td>
                <td align="center"><code>stdin</code></td><td>piped input ignored</td></tr>
        <tr>    <td align="center"><code>stdout</code></td><td>the sed extract expression, empty in case of error</td></tr>
        <tr><td rowspan="2"><b>Status</b></td>
                <td align="center"><em>0</em></td><td>success, expression was computed and is on `stdout`</td></tr>
        <tr>    <td align="center"><em>1</em></td><td>function was unable to find a suitable sed separator character</td></tr>
        <tr>    <td align="center"><em>2</em></td><td>values for <code>$2</code> and/or <code>$3</code> are unknown</td></tr>
</table>

### get_sed_replace_expression
Computes sed string replacement expression

Example: 

	echo "some string" | sed -e $(get_sed_replace_expression "some" "awesome")
	get_sed_replace_expression() should provide the expression s/some/awesome/g => the
Prints *awesome string*
<table>
        <tr><td rowspan="2"><b>Param.</b></td>
                <td align="center"><code>$1</code></td><td width="90%">sed match regex/string</td></tr>
        <tr>    <td align="center"><code>$2</code></td><td>sed replace string</td></tr>
        <tr>    <td align="center">[<code>$3</code>]</td><td>mode: 
		<ul>
			<li>if omitted, replace every occurence (aka global)</li>
			<li>*first* to replace only the first occurence</li>
		</ul>
	</td></tr>
        <tr><td rowspan="2"><b>Pipes</b></td>
                <td align="center"><code>stdin</code></td><td>piped input ignored</td></tr>
        <tr>    <td align="center"><code>stdout</code></td><td>the sed replace expression, empty if an error occur</td></tr>
        <tr><td rowspan="2"><b>Status</b></td>
                <td align="center"><em>0</em></td><td>success, the expression was computed and printed on <code>stdout</code></td></tr>
        <tr>    <td align="center"><em>1</em></td><td>if the function was unable to find a suitable separator character</td></tr>
        <tr>    <td align="center"><em>2</em></td><td>if the mode <code>$3</code> is unknown</td></tr>
</table>


