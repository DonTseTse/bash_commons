Documentation for the functions in [string_handling.sh](string_handling.sh). A general overview is given in [the project documentation](README.md#string-handling).

## Quick access
- [escape()](#escape)
- [escape_sed_special_characters()](#escape_sed_special_characters)
- [find_sed_operation_separator()](#find_sed_operation_separator)
- [find_substring()](#find_substring) 
- [get_absolute_path()](#get_absolute_path) 
- [get_sed_extract_expression()](#get_sed_extract_expression)
- [get_sed_replace_expression()](#get_sed_replace_expression)
- [get_string_bytelength()](#get_string_bytelength)
- [get_string_bytes()](#get_string_bytes)
- [is_string_a()](#is_string_a)
- [sanitize_variable_quotes()](#sanitize_variable_quotes) 
- [trim()](#trim)

## Function documentation
If the pipes are not documented, the default is:
- `stdin`: piped input ignored
- `stdout`: empty

Parameters enclosed in brackets [ ] are optional.

### escape()
Takes the piped input and escapes specified character(s) with backslashes

Special care is taken to disable bash globbing to make sure that affected characters, typically <em>*</em>, can be escaped properly. 
At the end, the original globbing configuration is restored.

Example:

	echo "path/to/file" | escape "/"
prints *path\\/to\\/file*
<table>
	<tr><td rowspan="2"><b>Param.</b></td><td align="center"><code>$1</code></td><td width="90%">character to escape</td></tr>
	<tr>	<td align="center">[<code>$2...n</code>]</td><td>additional character(s) to escape</td></tr>
	<tr><td rowspan="2"><b>Pipes</b></td><td align="center"><code>stdin</code></td><td>read completely</td></tr>
	<tr>            <td align="center"><code>stdout</code></td><td><code>stdin</code> where <code>$1...n</code> were escaped</td></tr>
	<tr><td><b>Status</b></td><td align="center"><em>0</em></td><td></td></tr>
</table>

### sanitize_variable_quotes()
If a string contains a value enclosed in quotes (the quotes are part of string), this function removes them. It checks for single and double quotes.

Examples: 
- Input as parameter: `sanitize_variable_quotes "'quoted value'"` 
- Piped input `$(echo "'quoted value'" | sanitize_variable_quotes)`

both print *quoted value*
<table>
	<tr><td><b>Param.</b></td><td align="center">[<code>$1</code>]</td><td width="90%">string to sanitize, if omitted or empty <code>stdin</code> is read</td></tr>
	<tr><td rowspan="2"><b>Pipes</b></td><td align="center"><code>stdin</code></td><td>if <code>$1</code> is undefined or empty, read completely</td></tr>
	<tr>            <td align="center"><code>stdout</code></td><td>sanitized <code>$1</code> or <code>stdin</code></td></tr>
	<tr><td><b>Status</b></td><td align="center"><em>0</em></td><td></td></tr>
</table>

### trim()
Cut leading and trailing whitespace on either the provided parameter or the piped stdin

Examples:
- Input as parameter: `trimmed_string=$(trim "$string_to_trim")`
- Piped input: `trimmed_string=$(echo "$string_to_trim" | trim)`
<table>
	<tr><td><b>Param.</b></td><td align="center">[<code>$1</code>]</td><td width="90%">string to trim, if omitted or empty <code>stdin</code> is read</td></tr>
	<tr><td rowspan="2"><b>Pipes</b></td><td align="center"><code>stdin</code></td><td>if <code>$1</code> is undefined or empty, read completely</td></tr>
	<tr>		<td align="center"><code>stdout</code></td><td>trimmed <code>$1</code> or <code>stdin</code></td></tr>
	<tr><td><b>Status</b></td><td align="center"><em>0</em></td><td></td></tr>
</table>

### find_substring()
Finds the position of the first instance of `$2` in `$1`. If `$3` is omitted the search begins at the beginning of `$1`, otherwise it begins after `$3` characters. 

Inspired by this [StackOverflow thread](https://stackoverflow.com/questions/5031764/position-of-a-string-within-a-string-using-linux-shell-script)
<table>
	<tr><td rowspan="3"><b>Param.</b></td>
		<td align="center"><code>$1</code></td><td width="90%">string to search in</td></tr>
	<tr>    <td align="center"><code>$2</code></td><td>character/string to find - exact matching is used (bash's matching special characters are disabled)</td></tr>
	<tr>    <td align="center">[<code>$3</code>]</td><td>search start position inside <code>$1</code> - if it's omitted, search starts at the beginning</td></tr>
	<tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>
		<ul>
			<li>the position of the first character of the first occurence of <code>$2</code> in the considered part of <code>$1</code></li>
			<li><em>-1</em> if <code>$2</code> is not found in <code>$1</code></li>
		</ul>
	</td></tr>
	<tr><td rowspan="3"><b>Status</b></td>
		<td align="center"><em>0</em></td><td>success, search executed and result written on <code>stdout</code></td></tr>
	<tr>	<td align="center"><em>1</em></td><td><code>$1</code> undefined or empty</td></tr>
	<tr>	<td align="center"><em>2</em></td><td><code>$2</code> undefined or empty</td></tr>
</table>


### get_absolute_path()
Transforms `$1` in a absolute filepath if it's relative. Uses `$2` as base directory if it's defined, the current working directory otherwise. 

The path `$1` and the directory `$2` don't have to exist.
<table>
	<tr><td rowspan="2"><b>Param.</b></td>
		<td align="center"><code>$1</code></td><td width="90%">path to "absolutify" if necessary</td></tr>
	<tr>    <td align="center">[<code>$2</code>]</td><td>root path - if omitted, the current working directory is used</td></tr>
	<tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>the computed absolute path</td></tr>
	<tr><td><b>Status</b></td><td align="center"><em>0</em></td><td></td></tr>
</table>

### is_string_a()
Checks if string `$1` is of a certain type `$2`:
<table>
       <tr><th>Type</th><th>Test condition</th></tr>
       <tr><td><em>absolute_filepath</em></td><td>the first non-whitespace character of <code>$1</code> is a <em>/</em></td></tr>
       <tr><td><em>integer</em></td><td><code>$1</code> contains only numbers</td></tr>
</table>

The test may be inverted if the type is prepended with a *!*, f.ex. *!absolute_filepath*. 

Example: 

	is_string_a "$potential_int" "integer" && echo "This is a integer: $potential_int"
<table>
	<tr><td rowspan="2"><b>Param.</b></td>
	<td align="center"><code>$1</code></td><td width="90%">string to check</td></tr>
	<tr>    <td align="center"><code>$2</code></td><td>test type, see table above; can be inverted with a leading <em>!</em>, f.ex. <em>!integer</em></td></tr>
	<tr><td rowspan="5"><b>Status</b></td>
                <td align="center"><em>0</em></td><td>the test was executed and succeeded</td></tr>
        <tr>    <td align="center"><em>1</em></td><td>the test was executed, but failed</td></tr>
        <tr>    <td align="center"><em>2</em></td><td><code>$1</code> is empty</td></tr>
        <tr>    <td align="center"><em>3</em></td><td><code>$2</code> is empty</td></tr>
        <tr>    <td align="center"><em>4</em></td><td><code>$2</code> is unknown</td></tr>
</table>

### get_string_bytelength()
Gives the byte length of `$1`. Characters which are part of the ASCII set are encoded on 1 byte, hence, for strings which contain only
ASCII characters, the byte length and the string length correspond. Characters from other sets like f.ex. é, à, å, etc. require 2 or more
bytes and lead to a higher byte length than string length. Uses the *C* locale internally.
<table>
	<tr><td><b>Param.</b></td><td align="center"><code>$1</code></td><td width="90%">string to get the bytelength of</td></tr>
	<tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>the bytelength of <code>$1</code></td></tr>
	<tr><td><b>Status</b></td><td align="center"><em>0</em></td><td></td></tr>
</table>

### get_string_bytes()
Computes the byte representation of a string. Non-ASCII chars like à,é,å,ê,etc. are transformed to their character code,
é f.ex. is \303\251. Uses the *C* locale internally. 

<table>
	<tr><td><b>Param.</b></td><td align="center"><code>$1</code></td><td width="90%">string to get the byte representation of</td></tr>
	<tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>the byte representation of <code>$1</code></td></tr>
	<tr><td><b>Status</b></td><td align="center"><em>0</em></td><td></td></tr>
</table>

### get_sed_extract_expression()
Generates `sed` string extraction expression.
Example:

        echo "first|second|third" | sed -e $(get_sed_extract_expression "|" "before" "first")
prints *first* (the `sed` expression is <em>s/|.*//g</em>).
<table>
	<tr><td rowspan="3"><b>Param.</b></td>
		<td align="center"><code>$1</code></td><td width="90%">marker</td></tr>
	<tr>    <td align="center"><code>$2</code></td><td>part to extract: can be <em>before</em> or <em>after</em>, with regard to the occurence of 
		<code>$1</code> selected with <code>$3</code></td></tr>
	<tr>    <td align="center"><code>$3</code></td><td>occurence: can be <em>first</em> or <em>last</em></td></tr>
	<tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>the sed extraction expression, empty in case of error</td></tr>
	<tr><td rowspan="3"><b>Status</b></td>
		<td align="center"><em>0</em></td><td>success, expression was computed and written on <code>stdout</code></td></tr>
	<tr>    <td align="center"><em>1</em></td><td>the function was unable to find a suitable <code>sed</code> operation separator character</td></tr>
	<tr>    <td align="center"><em>2</em></td><td>the value of <code>$2</code> and/or <code>$3</code> is unknown</td></tr>
</table>

### get_sed_replace_expression()
Generates `sed` string replacement expression.

Example: 

	echo "some string" | sed -e $(get_sed_replace_expression "some" "awesome")
print *awesome string* (the `sed` expression is *s/some/awesome/g*).
<table>
	<tr><td rowspan="3"><b>Param.</b></td>
		<td align="center"><code>$1</code></td><td width="90%">sed match regex/string</td></tr>
	<tr>    <td align="center"><code>$2</code></td><td>sed replace string</td></tr>
	<tr>    <td align="center">[<code>$3</code>]</td><td>occurence selection:
		<ul>
			<li>if omitted or empty, replace every occurence (aka global)</li>
			<li><em>first</em> to replace only the first occurence</li>
			<li><em>last</em> to replace only the last occurence</li>
		</ul>
	</td></tr>
	<tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>the sed replace expression, empty in case of error</td></tr>
	<tr><td rowspan="3"><b>Status</b></td>
		<td align="center"><em>0</em></td><td>success, the expression was computed and written on <code>stdout</code></td></tr>
	<tr>    <td align="center"><em>1</em></td><td>the function was unable to find a suitable separator character</td></tr>
	<tr>    <td align="center"><em>2</em></td><td>the occurence selection <code>$3</code> is unknown</td></tr>
</table>

### find_sed_operation_separator()
Provides a sed separator character which doesn't occur in `$1` and `$2`.
<table>
        <tr><td rowspan="2"><b>Param.</b></td>
                <td align="center"><code>$1</code></td><td width="90%">sed match regex/string</td></tr>
        <tr>    <td align="center">[<code>$2</code>]</td><td>2nd sed argument</td></tr>
        <tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>the sed operation separator character, empty in case of error</td></tr>
        <tr><td rowspan="2"><b>Status</b></td>
                <td align="center"><em>0</em></td><td>found a suitable separator character, written on <code>stdout</code></td></tr>
        <tr>    <td align="center"><em>1</em></td><td>none of the 23 characters available is suited</td></tr>
</table>

### escape_sed_special_characters()
Adds a backslash to every occurence of a character which has a special signification in sed expressions: 

	. + ? * [ ] ^ $
<table>
        <tr><td><b>Param.</b></td><td align="center"><code>$1</code></td><td width="90%">string to escape</td></tr>
        <tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>escaped <code>$1</code></td></tr>
        <tr><td><b>Status</b></td><td align="center"><em>0</em></td><td></td></tr>
</table>
