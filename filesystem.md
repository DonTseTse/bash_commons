Documentation for the functions in [filesystem.sh](filesystem.sh). A general overview is given in [the project documentation](README.md#filesystem)

If the pipes are not documented, the default is:
- `stdin`: ignored
- `stdout`: empty

Parameters enclosed in brackets [ ] are optional.

### get_real_path()
The function processes `$1` in 4 ways:
- if it's a relative path, it's transformed to the absolute equivalent
- it resolves symbolic file links, even if they are chained (i.e. a link pointing to a link pointing to a link etc.)
- it resolves symbolic folder links using `cd`'s `-P` flag
- it cleans up *../* and *./* components

It works for both file and folder paths with the restriction that they must exist. The [string handling collection's get_absolute_path()](string_handling.md#get_absolute_path)
works with paths that don't exist. 
<table>
	<tr><td><b>Param.</b></td><td align="center"><code>$1</code></td><td width="90%">path to resolve and clean</td></tr>
	<tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>if status is <em>0</em>, the "real" path of <code>$1</code>, empty otherwise</td></tr>
	<tr><td rowspan="2"><b>Status</b></td>
		<td align="center"><em>0</em></td><td>success</td></tr>
	<tr>    <td align="center"><em>1</em></td><td><code>$1</code> doesn't exist</td></tr>
</table>

### get_script_path()
Inspired by this [StackOverflow(SO) answer](https://stackoverflow.com/questions/59895/getting-the-source-directory-of-a-bash-script-from-within/246128#246128). 
The function returns the full path including the filename and it's able to work in any call constellation: sourced, called in a subshell etc. 
It relies on `$BASH_SOURCE` which changes depending on the constellation, however, the element in this array with the highest index is always the path of the script 
executed initially.

**Important**: call `get_script_path()` before any directory changes in the script. The `$BASH_SOURCE` entry depends on the way the script is called and one of the 
possibilities is that the script it's executed in a terminal using a relative filepath with respect to the shell's *current directory*; in that case the `$BASH_SOURCE` 
entry  only contains that relative filepath and if the current directory changes, the output of this function is wrong. 
<table>
	<tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td width="90%">"real" absolute path (folder + file symlink resolved, cleaned) of the executed script</td></tr>
	<tr><td><b>Status</b></td><td align="center"><em>0</em></td><td></td></tr>
</table>

### is_writeable()
Helper to avoid write permission errors. Since the function complies with the status code conventions, it's possible to use

	wr_err=$(is_writeable <path>) && ... do something with <path> ...

The function has a **check on existing path part** flag  which configures its behavior for filepaths that don't exist on the system (yet). In 
these cases the answer whether a write will succeed or not depends on the type of operation and whether it requires the direct parent folder to 
exist or not. `mkdir` is a good example - let's imagine there's a empty directory `/test` where the user has write permission and wants to create 
the path `/test/folder/subfolder`:

- `mkdir /test/folder/subfolder` will fail because `/test/folder` doesn't exist 
- `mkdir -p /test/folder/subfolder` works because the `-p` tells `mkdir` it's allowed to create multiple nested directories and since writing to 
   `/test` is permitted, the operation is successful

This function is able to cover both constellations: 

- if the **check on existing path part** flag is not raised it fails if the direct parent folder doesn't exist
- if the flag is raised, it does what its name indicates: it walks up the path until it finds an existing directory and checks the write permission on 
  that directory.

In the `mkdir` example above, `is_writeable /test/folder/subfolder` would return status 1 (= not writeable); with the flag, 
`is_writeable /test/folder/subfolder 1`, it would return status 0 (= is writeable).

<table>
        <tr><td><b>Parametrization</b></td><td width="90%">
		- <code>$1</code> path<br>
		- <code>$2</code> <em>optional</em> "check on existing path part" flag - if the parent directory of <code>$1</code> doesn't exist, it 
		  configures whether the function fails or if it walks up <code>$1</code> until it finds an existing folder on which it checks the write 
		  permission - see explanations above
        </td></tr>
        <tr><td><b>Pipes</b></td><td>
                - <code>stdin</code>: ignored<br>
                - <code>stdout</code>:<ul>
			<li><em>0</em> if path <code>$1</code> not writeable</li>
			<li><em>1</em> if path <code>$1</code> writeable</li>
			<li><em>2</em> if the direct parent folder of path <code>$1</code> doesn't exist (can only happen if <code>$2</code> is omitted or set to 0)</li>
	</ul></td></tr>
        <tr><td><b>Status</b></td><td>
		- <em>0</em> success, result on <code>stdout</code><br>
		- <em>1</em> if <code>$1</cod> empty
        </td></tr>
</table>

### get_new_path_part()
Extracts the part of `$1` which does not exist on the filesystem. 
<table>
	<tr><td><b>Param.</b></td><td align="center"><code>$1</code></td><td width="90%">path</td></tr>
	<tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>part of <code>$1</code> which does not exist on the filesystem</td></tr>
	<tr><td><b>Status</b></td><td align="center"><em>0</em></td><td></td></tr>
</table>

### get_existing_path_part()
Extracts the part of `$1` which exists on the filesystem. Returns "at least" */*
<table>
	<tr><td><b>Param.</b></td><td align="center"><code>$1</code></td><td width="90%">path</td></tr>
	<tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>part of <code>$1</code> which exists on the filesystem</td></tr>
	<tr><td><b>Status</b></td><td align="center"><em>0</em></td><td></td></tr>
</table>

### try_filepath_deduction()
If there's only a single file (match) in the folder $1, returns its path
<table>
        <tr><td rowspan="2"><b>Param.</b></td>
                <td align="center"><code>$1</code></td><td width="90%">path of the folder to search in</td></tr>
        <tr>    <td align="center">[<code>$2</code>]</td><td>search pattern, if omitted, defaults to <em>*</em> (= everything)</td></tr>
        <tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>if status is <em>0</em>, the absolute filepath of the single match, empty otherwise</td></tr>
        <tr><td rowspan="4"><b>Status</b></td>
                <td align="center"><em>0</em></td><td>successful deduction, path is written on <code>stdout</code></td></tr>
        <tr>    <td align="center"><em>1</em></td><td>folder <code>$1</code> doesn't exist</td></tr>
        <tr>    <td align="center"><em>2</em></td><td>there's no match for <code>$2</code> in <code>$1</code></td></tr>
        <tr>    <td align="center"><em>3</em></td><td>there's more than 1 match for <code>$2</code> in <code>$1</code></td></tr>
</table>

### create_directory()
Advantages over simple `mkdir`:
- additional return codes allow better error interpretation, not just the basic 0/success and 1/error
- control over stdout and stderr: mkdir prints on `stderr` on failure. This function allows to be sure:
	- that `stdout` returns either nothing, the `mkdir` status code or the `mkdir` `stderr` message, depending on `$2`
	- that `stderr` remains silent, even in case of `mkdir` failure

Examples:
- silent mode: `create_directory "path/to/new/dir"`
- status code: `status=$(create_directory "/path/to/my_new_dir" "status")`
- error message:
	```
	err_msg=$(create_directory "/path/to/my_new_dir" "error_message")
	status=$?
	```
- verbose mode: 
	```
	mkdir_msg_def=("Info: folder created\n" "Error in %err_msg\n" "Info: folder exists, nothing to do\n")
	mkdir_msg_def[3]="Error: could not create directory, path not writeable\n"
	create_directory "$1" "verbose"  "   "
	``` 

The supported variables are `%path` and `%err_msg`

<table>
        <tr><td rowspan="3"><b>Param.</b></td>
                <td align="center"><code>$1</code></td><td width="90%">path</td></tr>
        <tr>    <td align="center">[<code>$2</code>]</td><td><code>stdout</code> configuration:
                <ul>
                        <li>if omitted or an empty string, nothing is printed on <code>stdout</code></li>
			<li><em>status</em> / <em>$?</em> <code>mkdir</code> status code</li>
                        <li><em>error_message</em> / <em>err_msg</em> / <em>stderr</em> <code>mkdir</code> call <code>stderr</code> output</li>
                        <li><em>verbose</em> for a status specific message, see explanations above</li>
                </ul>
        </td></tr>
        <tr>    <td align="center">[<code>$3</code>]</td><td>if <code>$2</code> is set to <em>verbose</em>, the name of the array variable which contains
	the custom message templates - see explanations above</td></tr>
        <tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>depending on <code>$3</code>
                <ul>
                        <li>empty if <code>$3</code> omitted or set to an empty string
                        <li>the <code>mkdir</code> status code if <code>$3</code> is set to <em>status</em> or <em>$?</em></li>
                        <li>eventual <code>sterr</code> output of the <code>mkdir</code> call, if <code>$3</code> is set to <em>error_message</em> (or aliases)</li>
                        <li>the message if <code>$3</code> is set to <em>verbose</em></li>
                </ul>
        </td></tr>
        <tr><td rowspan="5"><b>Status</b></td>
                <td align="center"><em>0</em></td><td><code>$1</code> created</td></tr>
        <tr>    <td align="center"><em>1</em></td><td><code>mkdir</code> error, if <code>$3</code> is set to <em>error_message</em>, <code>stdout</code>
                contains the content of <code>mkdir</code>'s <code>stderr</code> output</td></tr>
        <tr>    <td align="center"><em>2</em></td><td><code>$1</code> is empty</td></tr>
        <tr>    <td align="center"><em>3</em></td><td><code>$1</code> exists</td></tr>
        <tr>    <td align="center"><em>4</em></td><td><code>$1</code> is not writeable</td></tr>
</table>

### handle_cp_or_mv()
Internal handler for file/folder copy/move, used by the wrapper functions <a href="#copy_file">copy_file()</a>, <a href="#copy_folder">copy_folder()</a>,
<a href="#move_file">move_file()</a> and <a href="#move_folder">move_folder()</a>. See their documentation for details.
<table>
        <tr><td rowspan="5"><b>Param.</b></td>
                <td align="center"><code>$1</code></td><td width="90%">mode, possible values:
		<ul>
			<li><em>copy</em> or <em>cp</em></li>
			<li><em>move</em> or <em>mv</em></li>
		</ul>
	</td></tr>
                <td align="center"><code>$2</code></td><td width="90%">source path</td></tr>
        <tr>    <td align="center"><code>$3</code></td><td>destination path</td></tr>
        <tr>    <td align="center">[<code>$4</code>]</td><td><code>stdout</code> configuration:
                <ul>
                        <li>if omitted or an empty string, nothing is printed on <code>stdout</code></li>
                        <li><em>status</em> or <em>$?</em> for the <code>mv</code> call's status code</li>
                        <li><em>error_message</em> or <em>err_msg</em> or <em>stderr</em> for the <code>mv</code> call's <code>stderr</code> output</li>
                        <li><em>verbose</em> calls <a href="#create_directory_verbose">create_directory_verbose()</a> internally</li>
                </ul>
        </td></tr>
        <tr>    <td align="center">[<code>$5</code>]</td><td>if <code>$4</code> is set to <em>verbose</em>, the name of the array variable which contains the 
		custom message patterns. If omitted, the default message patterns are used</td></tr>
        <tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>depending on <code>$3</code>
                <ul>
                        <li>empty if <code>$4</code> omitted or set to an empty string
                        <li>the status returned by the <code>mv</code> call if <code>$4</code> is set to <em>status</em></li>
                        <li>eventual <code>sterr</code> output of the <code>mv</code> respectively <code>cp</code> call if <code>$4</code> is set to <em>error_message</em></li>
                        <li>the message if <code>$4</code> is set to <em>verbose</em></li>
                </ul>
        </td></tr>
        <tr><td rowspan="8"><b>Status</b></td>
                <td align="center"><em>0</em></td><td>operation successful</td></tr>
        <tr>    <td align="center"><em>1</em></td><td>operation failure, if <code>$3</code> is set to <em>error_message</em> (or its aliases), <code>stdout</code>
                contains <code>mv</code>'s respectively <code>cp</code>'s <code>stderr</code> output</td></tr>
        <tr>    <td align="center"><em>2</em></td><td>the source path <code>$2</code> is empty</td></tr>
        <tr>    <td align="center"><em>3</em></td><td>the source path <code>$2</code> doesn't exist</td></tr>
        <tr>    <td align="center"><em>4</em></td><td>no read permission on source path <code>$2</code></td></tr>
        <tr>    <td align="center"><em>5</em></td><td>the destination path <code>$3</code> exists</td></tr>
        <tr>    <td align="center"><em>6</em></td><td>no write permission on destination path <code>$3</code></td></tr>
        <tr>    <td align="center"><em>7</em></td><td>mode <code>$1</code> unknown</td></tr>
</table>

<a name="copy_file"></a><a name="copy_folder"></a><a name="move_file"></a><a name="move_folder"></a>
### copy_file(), copy_folder(), move_file() and move_folder()
`cp` and `mv` wrapper with:
- several checks, f.ex. if source/destination exists or the required read/write permissions, which allow to get specific status codes for 
  all these error types
- control over `stdout` and `stderr`: `mv` and `cp` write on `stderr` in case of failure. The functions allows to be sure:
        - that `stdout` returns either nothing, the `mv`/`cp` status code or `stderr` message, or a custom message, depending on `$3`
        - that `stderr` remains silent, even in case of `mv`/`cp` failure
- the specific status codes and the stdout control allow to have a "verbose" mode with custom dynamic messages by status (i.e. templates 
  for each state, with variable placeholders that allow to inject the runtime parameters in the message)

**Stdout configuration**:
- silent mode: `move_file "path/to/src" "path/to/dest"`
- status code: `status=$(move_folder "/path/to/src" "/path/to/dest" "status")`
- error message:
        ```
        err_msg=$(copy_file "/path/to/src" "/path/to/dest"  "error_message")
        status=$?
        ```
- verbose mode: 
	```
        copy_file "/path/to/src" "/path/to/dest"  "verbose"
        status=$?
        ```

	Depending on the outcome, it would print one the default message template (shown below) corresponding to the status. To overwrite these
	templates create an array variable and pass it's name to the function as `$4`. If `$4` is defined, the function looks for an array element
	with the index of the status. If that element is undefined, it reverts to the default template. This allows to overwrite only certain states,
	f.ex. the success (0), as shown below:
	```
	my_msg_defs[0]="Success! %source copied to %destination"
	copy_file "/path/to/src" "/path/to/dest"  "verbose" "my_msg_defs"
	```

	would print *Success! /path/to/src copied to /path/to/dest* in case of success. 

**Verbose mode message templates**

These templates support 4 variable placeholders: 

- `%source`: `$2`
- `%destination`: `$3`
- `%stderr_msg`: the `stderr` output of the `mv` or `cp` call. Only relevant for status *1*.
- `%operation`: has the value *move* or *copy*

The default message template are:
 Status | Template
:------:| --------
0 | `%source` moved to `%destination`\n
1 | `%stderr_msg`\n
2 | error: `%operation` failed, source path empty\n 
3 | error: `%operation` from `%source` to `%destination` failed because `%source` doesn't exist\n
4 | error: `%operation` from `%source` to `%destination` failed because there's no read permission on `%source`\n
5 | error: `%operation` from `%source` to `%destination` failed because `%destination` exists (won't overwrite)\n
6 | error: `%operation` from `%source` to `%destination` failed because there's no write permission on `%destination`\n

<table>
<tr><th>Status</th><th width="90%">Template</th></tr>
<tr><td><em>0</em></td><td><code>%source</code> moved to <code>%destination</code>\n</td></tr>
<tr><td><em>1</em></td><td><code>%stderr_msg</code>\n</td></tr>
<tr><td><em>2</em></td><td>error: <code>%operation</code> failed, source path empty\n</td></tr>
<tr><td><em>3</em></td><td>error: <code>%operation</code> from <code>%source</code> to <code>%destination</code> failed because <code>%source</code> doesn't exist\n</td></tr>
<tr><td><em>4</em></td><td>error: <code>%operation</code> from <code>%source</code> to <code>%destination</code> failed because there's no read permission on <code>%source</code>\n</td></tr>
<tr><td><em>5</em></td><td>error: <code>%operation</code> from <code>%source</code> to <code>%destination</code> failed because <code>%destination</code> exists (won't overwrite)\n</td></tr>
<tr><td><em>6</em></td><td>error: <code>%operation</code> from <code>%source</code> to <code>%destination</code> failed because there's no write permission on <code>%destination</code>\n</td></tr>
</table>

<table>
        <tr><td rowspan="4"><b>Param.</b></td>
                <td align="center"><code>$1</code></td><td width="90%">source path</td></tr>
        <tr>    <td align="center"><code>$2</code></td><td>destination path</td></tr>
        <tr>    <td align="center">[<code>$3</code>]</td><td><code>stdout</code> configuration:
                <ul>
                        <li>if omitted or an empty string, nothing is printed on <code>stdout</code></li>
                        <li><em>status</em> or <em>$?</em> for the <code>mv</code> call's status code</li>
                        <li><em>error_message</em> or <em>err_msg</em> or <em>stderr</em> for the <code>mv</code> call's <code>stderr</code> output</li>
                        <li><em>verbose</em> calls <a href="#create_directory_verbose">create_directory_verbose()</a> internally</li>
                </ul>
        </td></tr>
        <tr>    <td align="center">[<code>$4</code>]</td><td>if <code>$3</code> is set to <em>verbose</em>, the name of the array variable which contains the
                custom message patterns. If omitted, the default message patterns are used</td></tr>
        <tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>depending on <code>$3</code>
                <ul>
                        <li>empty if <code>$3</code> omitted or set to an empty string
                        <li>the status returned by the <code>mv</code> call if <code>$3</code> is set to <em>status</em></li>
                        <li>eventual <code>sterr</code> output of the <code>mv</code> call if <code>$3</code> is set to <em>error_message</em></li>
                        <li>the message if <code>$3</code> is set to <em>verbose</em></li>
                </ul>
        </td></tr>
	<tr><td rowspan="7"><b>Status</b></td>
                <td align="center"><em>0</em></td><td>operation successful</td></tr>
        <tr>    <td align="center"><em>1</em></td><td>operation failure, if <code>$3</code> is set to <em>error_message</em> (or its aliases), <code>stdout</code>
                contains <code>mv</code>'s respectively <code>cp</code>'s <code>stderr</code> output</td></tr>
        <tr>    <td align="center"><em>2</em></td><td>the source path <code>$2</code> is empty</td></tr>
        <tr>    <td align="center"><em>3</em></td><td>the source path <code>$2</code> doesn't exist</td></tr>
        <tr>    <td align="center"><em>4</em></td><td>no read permission on source path <code>$2</code></td></tr>
        <tr>    <td align="center"><em>5</em></td><td>the destination path <code>$3</code> exists</td></tr>
        <tr>    <td align="center"><em>6</em></td><td>no write permission on destination path <code>$3</code></td></tr>
</table>

### load_configuration_file_value()
Bash allows to `source` (aka `.`) files which is a convenient way to load f.ex. configuration files, however, it has disadvantages as well:
- the files have to comply with the bash syntax of course, f.ex. regarding comments, the way the variables are defined, etc. 
- the calling application has no control which variables are defined (or not), which ones are overwritten, etc.

It's sometimes easier and more flexible to load values with a file content search and extraction method like this function which is based on a search with `grep` 
and the extraction of the value using string processing utilities. 

Variable definitions should have the format:

	<variable name>=value
Each definition has to be on a single line, with any number of whitespaces before the variable name, between the variable name and the assignment operator '=' or between 
the operator and the value. Inline comments are not allowed, they should be on their own lines. Examples of valid definitions:

	cfg_filepath="/etc/test.conf"
	I'm a comment
	   cfg_filepath="/etc/test2.conf"
	timeout     = 25
<table>
	<tr><td rowspan="2"><b>Param.</b></td>
		<td align="center"><code>$1</code></td><td width="90%">path of the configuration file</td></tr>
	<tr>    <td align="center"><code>$2</code></td><td>name of the variable to load</td></tr>
	<tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>if status is <em>0</em>, the loaded value, empty otherwise</td></tr>
	<tr><td rowspan="6"><b>Status</b></td>
                <td align="center"><em>0</em></td><td>successful, value is written on <code>stdout</code></td></tr>
        <tr>    <td align="center"><em>1</em></td><td><code>$1</code> is empty</td></tr>                                                    
        <tr>    <td align="center"><em>2</em></td><td><code>$2</code> is empty</td></tr>
        <tr>    <td align="center"><em>3</em></td><td><code>$1</code> doesn't exist</td></tr>
        <tr>    <td align="center"><em>4</em></td><td>no read permission on <code>$1</code></td></tr>
        <tr>    <td align="center"><em>5</em></td><td>a variable with name <code>$2</code> could not be found</td></tr>
</table>
