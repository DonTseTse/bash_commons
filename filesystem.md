Documentation for the functions in [filesystem.sh](filesystem.sh). A general overview is given in [the project documentation](README.md#filesystem)
If the pipes are not documented, the default is:
- `stdin`: ignored
- `stdout`: empty

Parameters enclosed in brackets [ ] are optional.

### get_real_path()
The function processes `$1` in 4 ways:
- if it's a relative path, it's transformed to it's absolute equivalent
- it resolves symbolic file links, even if they are chained (i.e. a link pointing to a link pointing to a link etc.)
- it resolves symbolic folder links using `cd`'s `-P` flag
- it cleans up `../` and `./` components in `$1`

It works for both file and folder paths with the restriction that they must exist. The [string handling collection's get_absolute_path()](string_handling.md#get_absolute_path)
works with paths that don't exist. 
<table>
	<tr><td><b>Param.</b></td><td align="center"><code>$1</code></td><td width="90%">path to resolve and clean</td></tr>
	<tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>if status is <em>0</em>, the "real" path of <code>$1</code>, empty otherwise</td></tr>
	<tr><td rowspan="2"><b>Status</b></td>
		<td align="center"><em>0</em></td><td><code>$1</code> exists</td></tr>
	<tr>    <td align="center"><em>1</em></td><td>otherwise</td></tr>
</table>

### get_script_path()
Inspired by this [StackOverflow(SO) answer](https://stackoverflow.com/questions/59895/getting-the-source-directory-of-a-bash-script-from-within/246128#246128). 
The function returns the full path including the filename and it's able to work in any call constellation: sourced, called in a subshell etc. 
It relies on `$BASH_SOURCE` which changes depending on the constellation, the element in this array with the highest index is always the path of the script 
executed initially.

**Important**: call `get_script_path()` before any directory changes in the script. This is due to the fact that the `$BASH_SOURCE` entry depends on the way 
the script is called: one of the possibilities is that the script is executed in a terminal using a relative filepath with respect to the shell's *current 
directory*. In that case the `$BASH_SOURCE` entry  only contains that relative filepath and if the current directory changes, the output of this function is 
wrong. 
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

### get_existing_path_part
Extracts the part of `$1` which exists on the filesystem. Returns "at least" /
<table>
	<tr><td><b>Param.</b></td><td align="center"><code>$1</code></td><td width="90%">path</td></tr>
	<tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>part of <code>$1</code> which exists on the filesystem</td></tr>
	<tr><td><b>Status</b></td><td align="center"><em>0</em></td><td></td></tr>
</table>

### move()
Advantages over `mv`:
- additional return codes allow better error interpretation, not just the basic 0/success and 1/error
- control over `stdout` and `stderr`: `mv` prints on `stderr` on failure. This function allows to be sure:
	- that `stdout` returns either nothing, the `mv` status code or the `mv` `stderr` message, depending on `$2`
	- that `stderr` remains silent, even in case of `mv` failure

Examples:
- silent mode: `move "path/to/src" "path/to/dest"`
- status code: `status=$(move "/path/to/src" "/path/to/dest" "status")`
- error message:
	```
	err_msg=$(move "/path/to/src" "path/to/dest"  "error_message")
	status=$?
	```
- verbose mode: calls <a href="#move_verbose">move_verbose()</a> internally, see its documentation for details
<table>
        <tr><td rowspan="4"><b>Param.</b></td>
                <td align="center"><code>$1</code></td><td width="90%">source path</td></tr>
        <tr>    <td align="center"><code>$2</code></td><td>destination path</td></tr>
        <tr>    <td align="center">[<code>$3</code>]</td><td><code>stdout</code> configuration:
		<ul>
			<li>if omitted or an empty string, nothing is printed on <code>stdout</code></li>
			<li><em>status</em> / <em>$?</em> for the <code>mv</code> status code</li>
                        <li><em>error_message</em> / <em>err_msg</em> / <em>stderr</em> <code>mv</code> call <code>stderr</code> output</li>
                        <li><em>verbose</em> calls <a href="#create_directory_verbose">create_directory_verbose()</a> internally</li>
		</ul>
	</td></tr>
        <tr>    <td align="center">[<code>$4</code>]</td><td>if <code>$3</code> is set to <em>verbose</em>, the prefix</td></tr>
        <tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>depending on <code>$3</code>
		<ul>
			<li>empty if <code>$3</code> omitted or set to an empty string
                        <li>the <code>mv<code> status code if <code>$3</code> is set to <em>status</em></li>
                        <li>eventual <code>sterr</code> output of the <code>mv</code> call, if <code>$3</code> is set to <em>error_message</em></li>
                        <li>the message if <code>$3</code> is set to <em>verbose</em></li>		
		</ul>
	</td></tr>
        <tr><td rowspan="7"><b>Status</b></td>
                <td align="center"><em>0</em></td><td>moved successfully</td></tr>
        <tr>    <td align="center"><em>1</em></td><td><code>mv</code> error, if <code>$3</code> is set to <em>error_message</em>, <code>stdout</code> 
		contains the content of <code>mv</code>'s <code>stderr</code> output</td></tr>
        <tr>    <td align="center"><em>2</em></td><td><code>$1</code> is empty</td></tr>
        <tr>    <td align="center"><em>3</em></td><td><code>$1</code> doesn't exist</td></tr>
        <tr>    <td align="center"><em>4</em></td><td><code>$1</code> is not readable</td></tr>
        <tr>    <td align="center"><em>5</em></td><td><code>$2</code> exists and won't be overwritten</td></tr>
        <tr>    <td align="center"><em>6</em></td><td><code>$2</code> is not writeable</td></tr>
</table>

### move_verbose()
To overwrite these messages simply create a mkdir_msg_def variable before the call:

	mkdir_msg_def=("Info: folder created\n" "Error in %err_msg\n" "Info: folder exists, nothing to do\n")
	mkdir_msg_def[3]="Error: could not create directory, path not writeable\n"
	move_directory_verbose "/new/test/dir" "   "
The supported variables are `%path` and `%err_msg`
<table>
        <tr><td rowspan="3"><b>Param.</b></td>
                <td align="center"><code>$1</code></td><td width="90%">source path</td></tr>
        <tr>    <td align="center"><code>$2</code></td><td>destination path</td></tr>
        <tr>    <td align="center">[<code>$3</code>]</td><td>prefix, if omitted, defaults to a empty string</td></tr>
        <tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>the printed message</td></tr>
        <tr><td><b>Status</b></td><td colspan="2"><a href="#move">move()</a>'s status</td></tr>
        <tr><td><b>Globals</b></td><td colspan="2">
		<code>$mv_msg_def</code> as an array with 6 keys corresponding to the possible return states 
		of <a href="#move">move()</a>.<code>$mv_msg_def[0]<code> for success, index 1 for a <code>mv</code> error, etc.
	</td></tr>	
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
- verbose mode: calls create_directory_verbose(), see its documentation for details
	```
	mkdir_msg_def=("Info: folder created\n" "Error in %err_msg\n" "Info: folder exists, nothing to do\n")
	mkdir_msg_def[3]="Error: could not create directory, path not writeable\n"
	create_directory "$1" "verbose"  "   "
	``` 

<table>
        <tr><td rowspan="3"><b>Param.</b></td>
                <td align="center"><code>$1</code></td><td width="90%">path</td></tr>
        <tr>    <td align="center">[<code>$2</code>]</td><td><code>stdout</code> configuration:
                <ul>
                        <li>if omitted or an empty string, nothing is printed on <code>stdout</code></li>
			<li><em>status</em> / <em>$?</em> for the <code>mkdir</code> status code</li>
                        <li><em>error_message</em> / <em>err_msg</em> / <em>stderr</em> <code>mkdir</code> call <code>stderr</code> output</li>
                        <li><em>verbose</em> calls <a href="#create_directory_verbose">create_directory_verbose()</a> internally</li>
                </ul>
        </td></tr>
        <tr>    <td align="center">[<code>$3</code>]</td><td>if <code>$2</code> is set to <em>verbose</em>, the prefix</td></tr>
        <tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>depending on <code>$3</code>
                <ul>
                        <li>empty if <code>$3</code> omitted or set to an empty string
                        <li>the <code>mkdir<code> status code if <code>$3</code> is set to <em>status</em></li>
                        <li>eventual <code>sterr</code> output of the <code>mkdir</code> call, if <code>$3</code> is set to <em>error_message</em></li>
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

### create_directory_verbose()
Variant of <a href="#create_directory">create_directory()</a> with configurable message output

Default message if f.ex. `path` is `new/test/dir`:
- 0/success pattern: "%path created\n" => "new/test/dir created\n"
- 1/error   pattern: "%err_msg\n" => error message printed by mkdir, terminated by a newline
- 2/"folder exists" pattern: "%path exists\n" => "new/test/dir exists\n"
- 3/"path not writeable" pattern: "could not create %path, path is not writeable\n" => "could not create new/test/dir,
path is not writeable\n"

To overwrite these messages simply create a mkdir_msg_def variable before the call:

	mkdir_msg_def=("Info: folder created\n" "Error in %err_msg\n" "Info: folder exists, nothing to do\n")
	mkdir_msg_def[3]="Error: could not create directory, path not writeable\n"
	create_directory_verbose "/new/test/dir" "   "
The supported variables are `%path` and `%err_msg`
<table>
        <tr><td rowspan="2"><b>Param.</b></td>
                <td align="center"><code>$1</code></td><td width="90%">path</td></tr>
        <tr>    <td align="center">[<code>$2</code>]</td><td>prefix, if omitted, defaults to a empty string</td></tr>
        <tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>the printed message</td></tr>
        <tr><td><b>Status</b></td><td colspan="2"><a href="#create_directory">create_directory()</a>'s status</td></tr>
        <tr><td><b>Globals</b></td><td colspan="2">
		<code>$create_directory_msg_def as an array with 5 keys corresponding to the 5 possible return states of <a href="#create_directory">create_directory()</a>.
                <code>$create_directory_msg_def[0]</code> success message, etc.
        </td></tr>
</table>

### try_filepath_deduction()
If there's only a single file (match) in the folder $1, returns its path
<table>
        <tr><td rowspan="3"><b>Param.</b></td>
                <td align="center"><code>$1</code></td><td width="90%">path of the folder to search in</td></tr>
        <tr>    <td align="center">[<code>$2</code>]</td><td>search pattern, if omitted, defaults to <em>*</em> (= everything)</td></tr>
        <tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>if status is <em>0</em>, the absolute filepath of the single match, empty otherwise</td></tr>
        <tr><td rowspan="4"><b>Status</b></td>
                <td align="center"><em>0</em></td><td>successful deduction, path is written on <code>stdout</code></td></tr>
        <tr>    <td align="center"><em>1</em></td><td>folder <code>$1</code> doesn't exist</td></tr>
        <tr>    <td align="center"><em>2</em></td><td>there's no match for <code>$2</code> in <code>$1</code></td></tr>
        <tr>    <td align="center"><em>3</em></td><td>there's more than 1 match for <code>$2</code> in <code>$1</code></td></tr>
</table>

### load_configuration_file_value()
The variable definition should have the format:

	variable=value
It should be on a single line, alone, with any number of whitespaces before the variable name or between the variable name
the assignment '=' and the value

Examples:

	cfg_filepath="/etc/test.conf"
	   cfg_filepath="/etc/test2.conf"
	timeout     = 25
<table>
        <tr><td rowspan="3"><b>Param.</b></td>
                <td align="center"><code>$1</code></td><td width="90%">path of the configuration file</td></tr>
        <tr>    <td align="center"><code>$2</code></td><td>name of the variable to load</td></tr>
        <tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>if status is <em>0</em>, the loaded value, empty otherwise</td></tr>
        <tr><td rowspan="5"><b>Status</b></td>
                <td align="center"><em>0</em></td><td>successful</td></tr>
        <tr>    <td align="center"><em>1</em></td><td><code>$1</code> is empty</td></tr>                                                    
        <tr>    <td align="center"><em>2</em></td><td><code>$2</code> is empty</td></tr>
        <tr>    <td align="center"><em>3</em></td><td><code>$1</code> doesn't exist</td></tr>
        <tr>    <td align="center"><em>4</em></td><td>no read permission on <code>$1</code></td></tr>
        <tr>    <td align="center"><em>5</em></td><td>a variable with name <code>$2</code> is not found/defined</td></tr>
</table>
