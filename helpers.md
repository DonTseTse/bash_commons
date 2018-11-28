Documentation for the functions in [helpers.sh](helpers.sh).

If the pipes are not documented, the default is:
- `stdin`: ignored
- `stdout`: empty

### capture()
Collects `stdout`, `stderr` (if `$STDERR` = 1) and the return status of a command and copies them into global variables.

Example: `capture echo "Hello world"` defines the global variables `return=0` and `stdout="Hello world"`.
To prefix the variable names in case confusion might arise, use the global variable `$PREFIX`.
The easiest way is to set it in the call context (`$PREFIX` is only defined for that command):

	PREFIX="echo" capture echo "Hello world"
defines the global variables `echo_return=0` and `echo_stdout="Hello world"`.

To capture `stderr` use the global variable `$STDERR` and set it to 1. Let's take an example where there's some `stderr` 
for sure, f.ex. the attempt to create a folder inside `/proc` which is never writeable, not even to root:

	STDERR=1 capture mkdir /proc/test
will define the global variables `$return`, `$stdout` and `$stderr` (with the `mkdir` error message). If `$PREFIX` is 
defined, the `stderr` variable has the name `$PREFIX_stderr`.

<table>
	<tr><td><b>Parametrization</b></td><td width="90%">
		<code>$1 ... n</code> call to capture ($1 is the command)<br>
		<em> and via globals, see examples above</em>
	</td></tr>
	<tr><td><b>Status</b></td><td>0</td></tr>
	<tr><td><b>Globals</b></td><td>
		Input: <ul>
		<li><code>$STDERR</code> if it's set to 1, <code>stderr</code> is captured</li>
                <li><code>$PREFIX</code> if it's a non empty-string, the capture variables names are prefixed - see examples above</li>
		</ul>Output: <ul>
		<li>if <code>$PREFIX</code> is not defined or empty: <code>$return</code>, <code>$stdout</code> and <code>$stderr</code> (if <code>$STDERR</code> is set to <em>1</em>)</li>
                <li>if <code>$PREFIX</code> is a non-empty string: <code>$PREFIX_return</code>, <code>$PREFIX_stdout</code> and <code>$PREFIX_stderr</code> (if <code>$STDERR</code> set to <em>1</em>)</li>
		</ul>
	</td></tr>
</table>

### is_function_defined()
Usage example: use in instruction chains to avoid potential "command ... unknown" errors. Example:

	is_function_defined "log" && log "..."
will only call `log` if it's defined.

<table>
        <tr><td><b>Parametrization</b></td><td width="90%">- <code>$1</code> name of the function</td></tr>
        <tr><td><b>Status</b></td><td>
		- <em>0</em> function exists<br>
		- <em>1</em> function doesn't exist
	</td></tr>
</table>

### set_global_variable()
Sets the variable called `$1` with the value `$2` on global level (i.e. accessible everywhere in the execution context)

<table>
        <tr><td><b>Parametrization</b></td><td width="90%">
		- <code>$1</code> variable name - the usual bash variable name restrictions apply<br>
		- <code>$2</code> value
	</td></tr>
        <tr><td><b>Status</b></td><td>
		- <em>0</em> success<br>
		- <em>1</em> if <code>$1</code> is empty
	</td></tr>
</table>

### calculate()
Computes maths beyond `bash`'s `((  ))` using `bc`. Provides control over the amount of decimals and removes unsignificant
decimals (trailing 0s in the result). Unsignificant decimals are always removed, even if this implies that the number of decimals (if any) is below `$2`.
If the result given by bc for `$1` is f.ex. 3.000... the function returns 3, regardless of what `$2` is set to. 

<table>
        <tr><td><b>Parametrization</b></td><td width="90%">
		- <code>$1</code> calculus to do, f.ex. <em>(2*2.25)/7</em> <br>
		- <code>$2</code> (optional) maximal amount of decimals in the result. Defaults to <em>3</em> if omitted. Use <em>0</em> or <em>int</em> to get an integer.
		See the explanations above as to why this is a maximum, not a guaranteed amount
	</td></tr>
	<tr><td><b>Pipes</b></td><td>
		- <code>stdin</code>: ignored<br>
		- <code>stdout</code>: if the <code>bc</code> execution was successful (status code <em>0</em>), the calculus result with at most 
                  <code>$2</code> amount of decimals. Empty if <code>bc</code> failed
	</td></tr>
        <tr><td><b>Status</b></td><td>the <code>bc</code> call's status code</td></tr>
</table>


### get_piped_input()
Usually used to capture `stdin` input to a variable, here f.ex. to `$input`

	input="$(get_piped_input)"

<table>
        <tr><td><b>Parametrization</b></td><td width="90%"><em>none</em></td></tr>
	<tr><td><b>Pipes</b></td><td>
		- <code>stdin</code>: read completely<br>
		- <code>stdout</code>: <code>stdin</code> copy
	</td></tr>
        <tr><td><b>Status</b></td><td><em>0</em></td></tr>
</table>

### get_random_string()
Gets a random alphanumeric string from `/dev/urandom`. 

**Important: it's not suited for critical security applications like cryptography**. However, it's useful to get unique strings for non-critical usecases, 
f.ex. *run IDs* which may be used to distinguish interleaving log entries from several instances of the same script running in parallel. 

<table>
        <tr><td><b>Parametrization</b></td><td width="90%">- <code>$1</code> <em>optional</em> length of the random string, defaults to 16 if omitted</td></tr>
	<tr><td><b>Pipes</b></td><td>
		- <code>stdin</code>: ignored<br>
		- <code>stdout</code>: the random string
	</td></tr>
        <tr><td><b>Status</b></td><td>
		- 0 if <code>/dev/urandom</code> exists<br>
		- 1 if <code>/dev/urandom</code> doesn't exist
	</td></tr>
</table>

### is_globbing_enabled()

Returns with status 0/success if bash globbing is enabled. One typical application is to "protect" an instruction which relies on globbing

	is_globbing_enabled && do_something_requiring_globbing
another is to check whether globbing needs to be turned off before an instruction where it is not desired

	is_globbing_enabled && set -f
`set -f` disables bash globbing (sets its `no_glob` option to true). To (re)enable globbing, use `set +f`
<table>
        <tr><td><b>Parametrization</b></td><td width="90%"><em>none</em></td></tr>
        <tr><td><b>Status</b></td><td>
		- <em>0</em> if globbing is enabled<br>
		- <em>1</em> if globbing is disabled
	</td></tr>
</table>

### conditional_exit()
Example:
```
important_fct_call
conditional_exit $? "important_fct_call failed! Aborting..." 20
````
If `important_fct_call` returns with a status code other than 0, the script prints the "... failed! ..." message and exits with status code 20

<table>
        <tr><td><b>Parametrization</b></td><td width="90%">
                - <code>$1</code> condition, if it's different than <em>0</em>, the exit is triggered<br>
                - <code>$2</code> (optional) exit message, defaults to a empty string if omitted (it still prints a newline to reset
                  the terminal)<br>
                - <code>$3</code> (optional) exit code, defaults to <em>1</em>
        </td></tr>
        <tr><td><b>Pipes</b></td><td>
                - <code>stdin</code>: ignored<br>
                - <code>stdout</code>: if the exit is triggered, <code>$2</code> followed by a newline
        </td></tr>
        <tr><td><b>Status</b></td><td><em>0</em> if the exit is not triggered</td></tr>
        <tr><td><b>Exit status</b></td><td><code>$3</code>, defaults to <em>1</em></td></tr>
</table>
