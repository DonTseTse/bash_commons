Documentation for the functions in [helpers.sh](helpers.sh).

If the pipes are not documented, the default is:
- `stdin`: ignored
- `stdout`: empty

### capture
Collects `stdout`, `stderr` (if `$STDERR` = 1) and the return status of a command and copies them into global variables

Example: capture status and stdout to the default global output variable names:

	`capture echo "Hello world"`

will define the global variables `return=0` and `stdout="Hello world"`
To prefix the variable names in case confusion might arise, use the global variable `$PREFIX`.
The easiest way is to set it in the call context (`$PREFIX` is only defined for that command):

	`PREFIX="echo" capture echo "Hello world"`

defines the global variable $echo_return=0 and $echo_stdout="Hello world"

To capture `stderr` use the global variable `$STDERR` and set it to 1. Like `$PREFIX`, the easiest
is to set it in the call context - let's take an example where there's some `stderr` for sure,
f.ex. the attempt to create a folder inside `/proc` which is never writeable, not even to root:

	`STDERR=1 capture mkdir /proc/test`
will define the global variables `$return`, `$stdout` and `$stderr` with the mkdir error message
If `$PREFIX` is defined, the global `stderr` variable has the name `$PREFIX_stderr`.

<table>
	<tr><td><b>Parametrization</b></td><td width="90%">
		<code>$1 ... n</code> Call to capture ($1 is the command)<br>
		+ some globals, see below
	</td></tr>
	<tr><td><b>Status</b></td><td>0</td></tr>
	<tr><td><b>Globals</b></td><td>
		Input: <ul>
		<li><code>$STDERR</code> if defined and set to 1, <code>stderr</code> is captured</li>
                <li><code>$PREFIX</code> if it's a non empty-string, the global output variables names are prefixed - see examples above</li>
		</ul>Output: <ul>
		<li>if $PREFIX is not defined or empty: $return, $stdout and $stderr (if $STDERR=1)</li>
                <li>if $PREFIX is a non-empty string: $PREFIX_return, $PREFIX_stdout and $PREFIX_stderr (if $STDERR=1)</li>
		</ul>
	</td></tr>
</table>

### is_function_defined
Usage example: use in instruction chains to avoid potential "command ... unknown" errors. Example:

	`is_function_defined "log" && log "..."`
will only call `log` if it's defined.

<table>
        <tr><td><b>Parametrization</b></td><td width="90%">- <code>$1</code> name of the function</td></tr>
        <tr><td><b>Status</b></td><td>
		- 0 if function exists<br>
		- 1 if function doesn't exist
	</td></tr>
</table>

### set_global_variable
Sets the variable called $1 with the value $2 on global level (i.e. accessible everywhere in the execution context)

<table>
        <tr><td><b>Parametrization</b></td><td width="90%">
		- <code>$1</code> variable name - the usual bash variable name restrictions apply<br>
		- <code>$2</code> value
	</td></tr>
        <tr><td><b>Status</b></td><td>
		- 0 in case of success
		- 1 if `$1` is empty
	</td></tr>
</table>

### calculate
Computes maths beyond <code>bash</code>'s <code>((  ))</code> using <code>bc</code>. Provides control over the amount of decimals and removes unsignificant
decimals (trailing 0s in the result). Unsignificant decimals are always removed, even if this implies that the number of decimals (if any) is below <code>$2</code>.
So if the result given by bc for $1 is f.ex. 3.0000000 the function returns 3, regardless of what <code>$2</code> is set to

<table>
        <tr><td><b>Parametrization</b></td><td width="90%">
		- <code>$1</code> calculus to do, f.ex. "(2*2.25)/7" <br>
		- <code>$2</code> *optional* maximal amount of decimals in the result. Defaults to 3 if omitted. Use 0 or 'int' to get a integer. 
		See the explanations above as to why this is a maximum, not a guaranteed amount
	</td></tr>
	<tr><td><b>Pipes</b></td><td>
		- stdin: ignored
		- stdout: if the bc execution was successful (status code 0), the calculus result with $2 amount of decimals. Empty otherwise
	</td></tr>
        <tr><td><b>Status</b></td><td>the <code>bc</code> call's status code</td></tr>
</table>


### get_piped_input
Usage example: usually used to get stdin to a variable, here f.ex. to $input

	`input="$(get_piped_input)"`

<table>
        <tr><td><b>Parametrization</b></td><td width="90%">*none*</td></tr>
	<tr><td><b>Pipes</b></td><td>
		- <code>stdin</code>: read completely<br>
		- <code>stdout</code>: stdin copy
	</td></tr>
        <tr><td><b>Status</b></td><td>0</td></tr>
</table>

## get_random_string

<table>
        <tr><td><b>Parametrization</b></td><td width="90%">- <code>$1</code> *optional* length of the random string, defaults to 16 if omitted</td></tr>
	<tr><td><b>Pipes</b></td><td>
		- <code>stdin</code>: ignored<br>
		- <code>stdout</code>: the random string
	</td></tr>
        <tr><td><b>Status</b></td><td>
		- 0 if <code>/dev/urandom</code> exists<br>
		- 1 if <code>/dev/urandom</code> doesn't exist
	</td></tr>
</table>

### is_globbing_enabled

Usage: one typical application is to "protect" an instruction which relies on globbing
	`is_globbing_enabled && do_something_with_globbing`
another is to check whether globbing needs to be turned off before an instruction where globbing is not desired
	`is_globbing_enabled && set -f`
set -f disables bash globbing (sets its 'no_glob' option to true). To restore it later on, use set +f
<table>
        <tr><td><b>Status</b></td><td>
		- 0 if globbing is enabled<br>
		- 1 if globbing is disabled
	</td></tr>
</table>
