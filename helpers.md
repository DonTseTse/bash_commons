Documentation for the functions in [helpers.sh](helpers.sh).

## Quick access
- [calculate()](#calculate)
- [capture()](#capture)
- [conditional_exit()](#conditional_exit)
- [get_array_element()](#get_array_element)
- [get_random_string()](#get_random_string)
- [get_piped_input()](#get_piped_input)
- [is_command_defined()](#is_command_defined)
- [is_function_defined()](#is_function_defined)
- [is_globbing_enabled()](#is_globbing_enabled)
- [set_global_variable()](#set_global_variable)

## Function documentation
If the pipes are not documented, the default is:
- `stdin`: ignored
- `stdout`: empty

Parameters enclosed in brackets [ ] are optional.

### capture()
Collects `stdout`, `stderr` and the return status of a command and copies them into global variables.

Example: `capture echo "Hello world"` defines the global variables `$return` set to *0* and `$stdout` with the value 
*Hello world*. The global variable `$VARNAME` allows to obtain less generic variable names:

	VARNAME="echo" capture echo "Hello world"
makes capture define the global variables `$echo_return` and `$echo_stdout` with the same values as `$return` and `$stdout` above.

To enable the capture of `stderr` which is disabled by default, use the global variable `$STDERR` and set it to *1*: 

	STDERR=1 capture mkdir /proc/test
defines the global variables `$return`, `$stdout` and `$stderr` (with the `mkdir` call `stderr` output). If `$VARNAME` is 
defined the `stderr` capture variable has the name `$VARNAME_stderr`.
<table>
        <tr><td><b>Param.</b></td><td align="center"><code>$1 ... n</code></td><td width="75%">call to capture (<code>$1</code> is the command)</td></tr>
        <tr><td rowspan="2"><b>Status</b></td>
		<td align="center"><em>0</em></td><td>success</td></tr>
	<tr>	<td align="center"><em>1</em></td><td><code>$1</code> undefined or empty</td></tr>
	<tr><td rowspan="2"><b>Globals</b></td>
                <td align="center">Input</td><td>
			<ul>
		                <li><code>$STDERR</code>: if it's set to <em>1</em>, <code>stderr</code> is captured</li>
				<li><code>$VARNAME</code>: if it's a non empty-string, the capture variables names are prepended as shown below</li>
			</ul>
	</td></tr>
        <tr>    <td align="center">Output</td><td>
		The captured status return, <code>stdout</code> and eventually <code>stderr</code>> are stored in variables called:
		<ul>
			<li>if <code>$VARNAME</code> is not defined or empty: <code>$return</code> and <code>$stdout</code></li>
			<li>if <code>$VARNAME</code> is a non-empty string: <code>$VARNAME_return</code>, <code>$VARNAME_stdout</code></li>
			<li>if <code>$STDERR</code> is set to <em>1</em>, <code>$stderr</code> respectively <code>$VARNAME_stderr</code> on top</li>
		</ul>
	</td></tr>
</table>

### is_command_defined()
Returns with status *0* if the shell has a "definition" for the command `$1`, regardless what type it is (function, built-in, 
file, etc.). It's similar to `which` but may also be used for bash functions and helps avoid "command ... unknown" errors. It 
may be used in instruction chains:

        is_command_defined "tail" && tail "..."
will only call `tail` if it's defined (aka installed). The example shows an essential difference with 
<a href="#is_function_defined">is_function_defined()</a> which will always return status *1* (not defined) for `tail` because it 
has the type *file*, not *function*. 
<table>
        <tr><td><b>Param.</b></td><td align="center"><code>$1</code></td><td width="90%">name of the function</td></tr>
        <tr><td rowspan="2"><b>Status</b></td>
                <td align="center"><em>0</em></td><td>function <code>$1</code> is defined</td></tr>
        <tr>    <td align="center"><em>1</em></td><td>function <code>$1</code> is not defined</td></tr>
</table>

### is_function_defined()
Returns with status *0* if a bash function with the name `$1` exists. Useful to avoid "command ... unknown" errors.

**Important**: do not use this function to check for the availability of standard shell utilities like `echo` or `tail` f.ex. - these
are not considered functions by bash (types *builtin* and *file*, respectively). Even if they are defined, this function returns 
status *1* (not defined) - use <a href="#is_command_defined">is_command_defined()</a> instead.

Example of the use in an instruction chain:

	is_function_defined "log" && log "..."
will only call `log` if it's defined. 
<table>
        <tr><td><b>Param.</b></td><td align="center"><code>$1</code></td><td width="90%">name of the function</td></tr>
        <tr><td rowspan="2"><b>Status</b></td>
                <td align="center"><em>0</em></td><td>function <code>$1</code> is defined</td></tr>
        <tr>    <td align="center"><em>1</em></td><td>function <code>$1</code> is not defined</td></tr>
</table>

### set_global_variable()
Sets up a variable called `$1` with the value `$2`, on global level (i.e. accessible everywhere in the execution context)

<table>
        <tr><td rowspan="2"><b>Param.</b></td>
		<td align="center"><code>$1</code></td><td width="90%">variable name - the usual bash variable name restrictions apply</td></tr>
	<tr>	<td align="center"><code>$2</code></td><td>value</td></tr>
        <tr><td rowspan="2"><b>Status</b></td>
                <td align="center"><em>0</em></td><td>success</td></tr>
        <tr>    <td align="center"><em>1</em></td><td><code>$1</code> is empty</td></tr>
</table>

### get_array_element()
The usual bash syntax to access array elements is `${<array_name>[<index>]}` where index can be a variable, however, if `<array_name>` is a variable, 
things get complex, a syntax like `${$var_name[$index]}` fails. The variable name expansion syntax with `!` works but it expands to the first and only 
the first array element, and all attemps to use both syntaxes combined don't seem to work, see []()

This function uses `printf` to "inject" the variable name and index into a code snippet which is then eval'd, this works, at least for numeric
indizes. **Warning**: for associative arrays (string indizes) it misbehaves if the element with the required index doesn't exist - it will not 
return an empty string, but the value of the first element in the array. 
<table>
        <tr><td rowspan="2"><b>Param.</b></td>
                <td align="center"><code>$1</code></td><td width="90%">array variable name</td></tr>
        <tr>    <td align="center"><code>$2</code></td><td>index</td></tr>
	<tr><td><b>Pipes</b></td><td><code>stdout</code></td><td>the value at index <code>$2</code> in the array with the name <code>$1</code></td></tr>
	<tr><td rowspan="3"><b>Status</b></td>
                <td align="center"><em>0</em></td><td>success, value is written on <code>stdout</code></td></tr>
		<td align="center"><em>1</em></td><td><code>$1</code> is undefined or empty</td></tr>
		<td align="center"><em>2</em></td><td><code>$2</code> is undefined or empty</td></tr>
        <tr>
</table>

### calculate()
Computes algebraic operations beyond `bash`'s `((  ))` using `bc`. Provides control over the maximal amount of decimals in the result and removes 
unsignificant decimals (trailing *0*s). 

The amount of decimals may be limited to a maximum using `$2` (defaults to *3*). `$2` is a maximum because
unsignificant decimals are always removed, even if this implies that the number of decimals (if any) is below `$2`.
If f.ex. `bc` returned  *3.00000* the function writes *3* on `stdout`, regardless of `$2`'s value. 
<table>
        <tr><td rowspan="2"><b>Param.</b></td>
                <td align="center"><code>$1</code></td><td width="90%">expression to compute, f.ex. <em>(2*2.25)/7</em></td></tr>
        <tr>    <td align="center">[<code>$2</code>]</td><td>maximal amount of decimals in the result. Defaults to <em>3</em> if omitted. 
		Use <em>0</em> or <em>int</em> to get an integer</td></tr>
        <tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>if the <code>bc</code> execution was successful (status code <em>0</em>),
	 the calculus result with at most <code>$2</code> decimals. Empty if <code>bc</code> failed</td></tr>
        <tr><td><b>Status</b></td><td colspan="2">the status returned by the <code>bc</code> call</td></tr>
</table>

### get_piped_input()
Returns the piped `stdin` content on `stdout`, which allows to capture it into a variable, here f.ex. to `$input`:

	input="$(get_piped_input)"
<table>
        <tr><td rowspan="2"><b>Pipes</b></td>
                <td align="center"><code>stdin</code></td><td width="90%">read completely</td></tr>
        <tr>    <td align="center"><code>stdout</code></td><td>copy of <code>stdin</code>'s piped input</td></tr>
        <tr><td><b>Status</b></td><td align="center"><em>0</em></td><td></td></tr>
</table>

### get_random_string()
Provides a string composed of `$1` alphanumeric characters taken from `/dev/urandom`. 

**Important: it's not suited for critical security applications like cryptography**. However, it's useful to get unique strings for non-critical usecases, 
f.ex. "run IDs" which may be used to distinguish interleaving log entries from several instances of the same script running in parallel. 

<table>
        <tr><td><b>Param.</b></td><td align="center">[<code>$1</code>]</td><td width="90%">length of the random string, defaults to <em>16</em> if omitted</td></tr>
        <tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>the random string</td></tr>
        <tr><td rowspan="2"><b>Status</b></td>
                <td align="center"><em>0</em></td><td>success, the random string is on <code>stdout</code></td></tr>
        <tr>    <td align="center"><em>1</em></td><td><code>/dev/urandom</code> doesn't exist</td></tr>
</table>

### is_globbing_enabled()
Returns with status *0* if bash globbing is enabled. One typical usecase is to "protect" an instruction which relies on globbing:

	is_globbing_enabled && command_which_requires_globbing
Another is to check whether globbing needs to be turned off before an instruction where it is not desired:

	is_globbing_enabled && set -f
`set -f` disables bash globbing; it sets its `no_glob` option to true. To (re)enable globbing, use `set +f`

<table>
        <tr><td rowspan="2"><b>Status</b></td>
                <td align="center"><em>0</em></td><td width="90%">globbing is enabled</td></tr>
        <tr>    <td align="center"><em>1</em></td><td>globbing is disabled</td></tr>
</table>

### conditional_exit()
Example:
```
important_fct_call
conditional_exit $? "important_fct_call failed! Aborting..." 20
````
If `important_fct_call` returns with a status code other than *0*, the script prints the "... failed! ..." message and exits with status code *20*

<table>
        <tr><td rowspan="3"><b>Param.</b></td>
		<td align="center"><code>$1</code></td><td width="90%">condition, if it's different than <em>0</em>, the exit is triggered</td></tr>
	<tr>	<td align="center">[<code>$2</code>]</td><td>exit message, defaults to a empty string if omitted (it always prints a newline to reset
                  the terminal)</td></tr>
	<tr>	<td align="center">[<code>$3</code>]</td><td>exit code, defaults to <em>1</em></td></tr>
        <tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>if the exit is triggered, <code>$2</code> followed by a newline</td></tr>
        <tr><td><b>Status</b></td><td align="center"><em>0</em></td><td>only applicable if the exit is not triggered</td></tr>
        <tr><td><b>Exit</b></td><td colspan="2"><code>$3</code> - defaults to <em>1</em> if <code>$3</code> is omitted, empty or non numeric</td></tr>
</table>
