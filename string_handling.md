Documentation for the functions in [string_handling.sh](string_handling.sh). A general overview is given in [the project documentation](README.md#string_handling).

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
prints *path\/to\/file*
<table>
	<tr><td rowspan="2"><b>Param.</b></td><td align="center"><code>$1</code></td><td width="90%">character to escape</td></tr>
	<tr>	<td align="center">[<code>$2...n</code>]</td><td>additional character(s) to escape</td></tr>
	<tr><td rowspan="2"><b>Pipes</b></td><td align="center"><code>stdin</code></td><td>read completely</td></tr>
	<tr>            <td align="center"><code>stdout</code></td><td><code>stdin</code> where <code>$1...n</code> were escaped</td></tr>
	<tr><td><b>Status</b></td><td align="center"><em>0</em></td><td></td></tr>
</table>

### sanitize_variable_quotes()
If a value is enclosed in quotes (i.e. literally, no related to bash syntax), this function removes them. It checks for single and double quotes.

Example:
	sanitize_variable_quotes "'quoted value'" 
prints *quoted value* (without quotes)
<table>
	<tr><td><b>Param.</b></td><td align="center">[<code>$1</code>]</td><td width="90%">string to sanitize, if omitted or empty <code>stdin</code> is read</td></tr>
	<tr><td rowspan="2"><b>Pipes</b></td><td align="center"><code>stdin</code></td><td>if <code>$1</code> is undefined or empty, read completely</td></tr>
	<tr>            <td align="center"><code>stdout</code></td><td>sanitized <code>$1</code> or <code>stdin</code></td></tr>
	<tr><td><b>Status</b></td><td align="center"><em>0</em></td><td></td></tr>
</table>

### trim()
Cut leading and trailing whitespace on either the provided parameter or the piped stdin

Use configurations:
- Input as parameter: `trimmed_string=$(trim "$string_to_trim")`
- Piped input: `trimmed_string=$(echo "$string_to_trim" | trim)`
<table>
	<tr><td><b>Param.</b></td><td align="center">[<code>$1</code>]</td><td width="90%">string to trim, if omitted or empty <code>stdin</code> is read</td></tr>
	<tr><td rowspan="2"><b>Pipes</b></td><td align="center"><code>stdin</code></td><td>if <code>$1</code> is undefined or empty, read completely</td></tr>
	<tr>		<td align="center"><code>stdout</code></td><td>trimmed <code>$1</code> or <code>stdin</code></td></tr>
	<tr><td><b>Status</b></td><td align="center"><em>0</em></td><td></td></tr>
</table>


### find_substring()
Finds the position of the first match of `$2` in `$1`

Inspired by this [StackOverflow thread](https://stackoverflow.com/questions/5031764/position-of-a-string-within-a-string-using-linux-shell-script)
<table>
	<tr><td rowspan="2"><b>Param.</b></td>
		<td align="center"><code>$1</code></td><td width="90%">string to search in</td></tr>
	<tr>    <td align="center"><code>$2</code></td><td>character/string to find - exact matching is used (bash's matching special characters are disabled)</td></tr>
	<tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>
		<ul>
			<li>the position of the first character of the first occurence of <code>$2</code> in <code>$1</code></li>
			<li><em>-1</em> if <code>$2</code> is not found in <code>$1</code></li>
		</ul>
	</td></tr>
	<tr><td><b>Status</b></td><td align="center"><em>0</em></td><td></td></tr>
</table>


### get_absolute_path()
Transforms `$1` in a absolute filepath if it's relative. Uses `$2` as directory if defined, the current working directory otherwise. 

The path `$1` and the optional root directory `$2` don't have to exist
<table>
	<tr><td rowspan="2"><b>Param.</b></td>
		<td align="center"><code>$1</code></td><td width="90%">path to "absolutify" if necessary</td></tr>
	<tr>    <td align="center">[<code>$2</code>]</td><td>root path - if omitted, the current working directory is used</td></tr>
	<tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>the computed absolute path</td></tr>
	<tr><td><b>Status</b></td><td align="center"><em>0</em></td><td></td></tr>
</table>

### is_string_a()
Checks if string `$1` is of a certain type `$2`, f.ex. if it's an absolute filepath or a integer. Tests types are listed in  `$2`'s 
documentation; the type may be inverted if it's preceeded by a *!*, f.ex. *!absolute_filepath* for a relative filepath. 

The function is able to work in 2 modes (depending on $3):
- in "status" mode it may be used easily in instruction chains (see examples below); all that matters is that it
  returns with status code 0 in case of success and a positive value in case of error. The error types "`$1` empty"
  "test type unknown" and "check failed" all have the same status code (*1*) and may hence not be distinguished by
  the caller
- in "stdout" mode the status code indicates only the execution success/error state, the result of the operation is
  on `stdout`. There's no ambiguity on the status code signification

Test types:
<table>
       <tr><th>Type</th><th>Description</th></tr>
       <tr><td><em>absolute_filepath</em></td><td>checks if the first non-whitespace character of <code>$1</code> is a <em>/</em></td></tr>
       <tr><td><em>integer</em></td><td>checks if the string only contains numbers</td></tr>
</table>

**Warning**: be careful with inverted checks if `$1` can be empty. One might consider that

	is_string_a "" "!absolute_filepath"
should return *0* (= success) since an empty string is not an absolute filepath but the function returns status *1* if 
`$1` is empty

Usage examples: the status mode allows to use it in statement chains easily
	
	is_string_a "$potential_int" "integer" && echo "This is a integer: $potential_int"
whereas the stdout mode gives a better control, adapted if $1 can't be trusted

	is_int=$(is_string_a "$unknown" "integer")
        [ $? -eq 0 ] && [ $is_int -eq 1 ] && echo "This is a integer: $unknown"

<table>
	<tr><td rowspan="3"><b>Param.</b></td>
	<td align="center"><code>$1</code></td><td width="90%">string to check</td></tr>
	<tr>    <td align="center"><code>$2</code></td><td>test type, see table above; can be inverted with a leading <em>!</em>, f.ex. <em>!integer</em></td></tr>
	<tr>    <td align="center">[<code>$3</code>]</td><td>stdout output flag (output mode):
		<ul>
			<li>if set to <em>1</em>, the function is in "stdout" mode</li>
			<li>if omitted or set to any other value, the function is in "status mode"</li>
		</ul>
	</td></tr>
	<tr><td colspan="3">pipes, status, etc. are given below depending on the mode the function is in</td></tr>
</table>

Pipes & status in "status mode":
<table>
	<tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td width="90%">empty</td></tr>
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
	<tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td width="90%">
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

### get_string_bytelength()
Gives the byte length of `$1`. Characters which are part of ASCII are encoded in 1 byte, hence, for strings which contain only
ASCII characters, the bytelength is also the string length. Characters from other sets like f.ex. é, à, å, etc. require 2 or more
bytes for encoding - string which contain them have a higher bytelength than string length
<table>
	<tr><td><b>Param.</b></td><td align="center"><code>$1</code></td><td width="90%">string to get the bytelength of</td></tr>
	<tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>the bytelength of <code>$1</code></td></tr>
	<tr><td><b>Status</b></td><td align="center"><em>0</em></td><td></td></tr>
</table>

### get_string_bytes()
Computes the byte representation of a string. Non-ascii chars like à,é,å,ê,etc. are transformed to their character code,
é f.ex. is \303\251

<table>
	<tr><td><b>Param.</b></td><td align="center"><code>$1</code></td><td width="90%">string to get the byte representation of</td></tr>
	<tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>the byte representation of <code>$1</code></td></tr>
	<tr><td><b>Status</b></td><td align="center"><em>0</em></td><td></td></tr>
</table>

### escape_sed_special_characters()
Escapes characters which have a special signification in sed expressions: `. + ? * [ ] ^ $`
<table>
	<tr><td><b>Param.</b></td><td align="center"><code>$1</code></td><td width="90%">string to escape</td></tr>
	<tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>escaped <code>$1</code></td></tr>
	<tr><td><b>Status</b></td><td align="center"><em>0</em></td><td></td></tr>
</table>

### get_sed_extract_expression()
Compute sed string extraction expression
<table>
	<tr><td rowspan="3"><b>Param.</b></td>
		<td align="center"><code>$1</code></td><td width="90%">marker</td></tr>
	<tr>    <td align="center"><code>$2</code></td><td>part to extract: can be <em>before</em> or <em>after</em>, with regard to the <code>$1</code occurence selected with
		<code>$3</code></td></tr>
	<tr>    <td align="center"><code>$3</code></td><td>occurence: can be <em>first</em> or <em>last</em></td></tr>
	<tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>the sed extraction expression, empty in case of error</td></tr>
	<tr><td rowspan="3"><b>Status</b></td>
		<td align="center"><em>0</em></td><td>success, expression was computed and written on `stdout`</td></tr>
	<tr>    <td align="center"><em>1</em></td><td>the function was unable to find a suitable sed separator character</td></tr>
	<tr>    <td align="center"><em>2</em></td><td>value of <code>$2</code> and/or <code>$3</code> is unknown</td></tr>
</table>

### get_sed_replace_expression()
Computes sed string replacement expression

Example: 

	echo "some string" | sed -e $(get_sed_replace_expression "some" "awesome")
The expression is *s/some/awesome/g* and the command prints *awesome string*
<table>
	<tr><td rowspan="3"><b>Param.</b></td>
		<td align="center"><code>$1</code></td><td width="90%">sed match regex/string</td></tr>
	<tr>    <td align="center"><code>$2</code></td><td>sed replace string</td></tr>
	<tr>    <td align="center">[<code>$3</code>]</td><td>occurence selection:
		<ul>
			<li>if omitted or empty, replace every occurence (aka global)</li>
			<li><em>first</em> to replace only the first occurence</li>
		</ul>
	</td></tr>
	<tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>the sed replace expression, empty if an error occur</td></tr>
	<tr><td rowspan="3"><b>Status</b></td>
		<td align="center"><em>0</em></td><td>success, the expression was computed and written on <code>stdout</code></td></tr>
	<tr>    <td align="center"><em>1</em></td><td>the function was unable to find a suitable separator character</td></tr>
	<tr>    <td align="center"><em>2</em></td><td>the occurence selection <code>$3</code> is unknown</td></tr>
</table>
