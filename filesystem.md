Documentation for the functions in [filesystem.sh](filesystem.sh).

If the pipes are not documented, the default is:
- `stdin`: ignored
- `stdout`: empty

### get_real_path
Resolves symlinks (file and folder) in a filepath and cleans it (removes "/../" "./" etc.).

Works for both files and folders with the restriction that they must exist (not suited to sanitize "new folder input" in an installer f.ex.)

Inspired by (https://stackoverflow.com/questions/59895/getting-the-source-directory-of-a-bash-script-from-within/246128#246128)

<table>
        <tr><td><b>Parametrization</b></td><td width="90%">- <code>$1</code> path to resolve and clean</td></tr>
        <tr><td><b>Pipes</b></td><td>
                - <code>stdin</code>: ignored<br>
                - <code>stdout</code>: if status is 0, "real" path of <code>$1</code>, empty otherwise
	</td></tr>
        <tr><td><b>Status</b></td><td>
		- 0 if <code>$1</code> exists<br>
		- 1 otherwise
	</td></tr>
</table>

### get_script_path
Inspired by this [StackOverflow(SO) answer](https://stackoverflow.com/questions/59895/getting-the-source-directory-of-a-bash-script-from-within/246128#246128). 
Unlike the SO answer, this function returns the full path including the filename and it's able to work in any call constellation: sourced, called 
in a subshell etc. - all these operations affect $BASH_SOURCE, but one thing is guaranteed: the element in this array with the highest index is the path of
the script executed by the command.

**Important**: call `get_script_path()` before any directory changes in the script, otherwise it may provide wrong results.
This is due to the fact that the BASH_SOURCE entry depends on the way the script is called: one of the possibilities is that, in a terminal, the script is called
using a relative filepath with respect to the shell's *current directory*. In that case BASH_SOURCE only contains that relative filepath and if the current directory
changes, the output of this function is wrong. 

<table>
        <tr><td><b>Parametrization</b></td><td width="90%"><em>none</em></td></tr>
        <tr><td><b>Pipes</b></td><td>
                - <code>stdin</code>: ignored<br>
                - <code>stdout</code>: "real" absolute path (folder + file symlink resolved, cleaned) of the executed script
        <tr><td><b>Status</b></td><td>0</td></tr>
</table>

### is_writeable
Helper to avoid write permission errors. Since the function complies with the status code conventions, it's possible to use

	wr_err=$(is_writeable <path>) && ... do something with <path> ...

*Check on existing path part* flag explanation: this function is often used with filepaths that don't exist on the system (yet). In these cases
the answer whether a write will succeed or not depends on the type of operation and whether it requires the direct parent folder to exist 
or not. `mkdir` is a good example, let's imagine there's a empty directory `/test` where the user has write permission and wants to create 
the path `/test/folder/subfolder`:

- `mkdir /test/folder/subfolder` will fail because `/test/folder` doesn't exist 
- `mkdir -p /test/folder/subfolder` works because the `-p` tells `mkdir` it's allowed to create multiple nested directories and since writing to 
   `/test` is permitted, the operation is successful

This function is able to cover both constellations - when the *check on existing path part* is not raised it fails if the direct parent 
doesn't exist, if the flag is raised, it does what its name indicates: it walks up the path until it finds an existing directory and 
checks the write permission on that directory. 

In the `mkdir` example above, `is_writeable /test/folder/subfolder <flag>` would return status 0 (= is writeable) if the flag is raised (<flag> = 1), 
status 1 (= not writeable) if the flag is not raised.

<table>
        <tr><td><b>Parametrization</b></td><td width="90%">
		- <code>$1</code> path<br>
		- <code>$2</code> <em>optional</em> "check on existing path part" flag - if the parent directory of <code>$1</code> doesn't exist, it 
		  configures whether the function fails or if it walks up `$1` until it finds an existing folder on which it checks the write permission 
		  - see explanations above
        </td></tr>
        <tr><td><b>Pipes</b></td><td>
                - <code>stdin</code>: ignored<br>
                - <code>stdout</code>:<ul>
			<li>0 if path <code>$1</code> not writeable</li>
			<li>1 if path <code>$1</code> writeable</li>
			<li>2 if the direct parent folder of path <code>$1</code> doesn't exist (can only happen if <code>$2</code> is omitted or set to 0)</li>
	</ul></td></tr>
        <tr><td><b>Status</b></td><td>
		0 success, result on stdout<br>
		1 if <code>$1</cod> empty
        </td></tr>
</table>

### get_new_path_part
<table>
        <tr><td><b>Parametrization</b></td><td width="90%">
		- <code>$1</code> path to get the new part of
        </td></tr>
        <tr><td><b>Pipes</b></td><td>
                - <code>stdin</code>: ignored<br>
                - <code>stdout</code>: part of <code>$1</code> which does not exist on the filesystem
	</td></tr>
        <tr><td><b>Status</b></td><td>0</td></tr>
</table>

### get_existing_path_part
<table>
        <tr><td><b>Parametrization</b></td><td width="90%">
		- <code>$1</code> path to get the existing part of
        </td></tr>
        <tr><td><b>Pipes</b></td><td>
                - <code>stdin</code>: ignored<br>
                - <code>stdout</code>: part of $1 which exists on the filesystem. Returns "at least" /
	</td></tr>
        <tr><td><b>Status</b></td><td>0</td></tr>
</table>

### move

Advantages over simple mv:
- additional return codes allow better error interpretation, not just the basic 0/success and 1/error
- control over stdout and stderr: mv prints on stderr on failure. This function allows to be sure:
	- that stdout returns either nothing, the mv status code or the mv stderr message, depending on $2
	- that stderr remains silent, even in case of mv failure

Examples:
- silent mode:

	move "path/to/src "path/to/dest"
- status code:

	status=$(move "/path/to/src" "/path/to/dest" "status")
- error message:

	err_msg=$(move "/path/to/src" "path/to/dest"  "error_message")
	status=$?
- verbose mode: calls move_verbose(), see its documentation for details

	mv_msg_def=("Info: folder created\n" "Error in %err_msg\n" "Info: folder exists, nothing to do\n")
	mv_msg_def[3]="Error: could not create directory, path not writeable\n"
	move "path/to/src" "path/to/dest" "verbose"  "   "

<table>
        <tr><td><b>Parametrization</b></td><td width="90%">
		- <code>$1</code> source path<br>
		- <code>$2</code> destination path<br>
		- <code>$3</code> <em>optional</em> <code>stdout</code> configuration - if omitted or an empty string, nothing is printed 
                  on <code>stdout</code><ul>
			<li>code>status</code> print the status</li>
			<li><code>error_message</code></li>
			<li><code>verbose</code> calls <a href="#move_verbose">move_verbose()</a> internally</li>
			</ul><br>
		- <code>$4</code> <em>optional</em> prefix: if the <code>verbose</code> <code>stdout</code> mode is used, the prefix
        </td></tr>
        <tr><td><b>Pipes</b></td><td>
                - <code>stdin</code>: ignored<br>
                - <code>stdout</code>: depending on <code>$3</code><ul>
			<li>empty if <code>$3</code> omitted or set to an empty string
			<li>the mv call status code if <code>$3</code> is set to <code>status</code></li>
			<li>eventual <code>sterr</code> output of the <code>mv</code> call, if <code>$3</code> set to <code>error_message</code></li>
			<li>the message if <code>$3</code> set to <code>verbose</code></li>
	</ul></td></tr>
        <tr><td><b>Status</b></td><td>
		0 moved successfully<br>
		1 mv error, if <code>$3</code> is set to <code>error_message</code>, <code>stdout</code> contains the content of <code>mv</code>'s <code>stderr</code><br>
		2 <code>$1</code> is empty<br>
		3 <code>$1</code> doesn't exist<br>
		4 <code>$1</code> is not readable<br>
		5 <code>$2</code> exists and won't be overwritten<br>
		6 <code>$2</code> is not writeable
        </td></tr>
</table>

### move_verbose()
To overwrite these messages simply create a mkdir_msg_def variable before the call:

	mkdir_msg_def=("Info: folder created\n" "Error in %err_msg\n" "Info: folder exists, nothing to do\n")
	mkdir_msg_def[3]="Error: could not create directory, path not writeable\n"
	move_directory_verbose "/new/test/dir" "   "
The supported variables are `%path` and `%err_msg`
<table>
        <tr><td><b>Parametrization</b></td><td width="90%">
		- <code>$1</code> path<br>
		- <code>$2</code> <em>optional</em> prefix, if omitted, defaults to a empty string
        </td></tr>
        <tr><td><b>Pipes</b></td><td>
                - <code>stdin</code>: ignored<br>
                - <code>stdout</code>: the printed message
        <tr><td><b>Status</b></td><td><a href="#move">move()</a>'s status</td></tr>
	<tr><td><b>Globals</b></td><td>
		- <code>$mv_msg_def</code> as an array with 6 keys corresponding to the possible return states of <a href="#move">move()</a>. 
		<code>$mv_msg_def[0]<code> for success, index 1 for a <code>mv</code> error, etc. 
	</td></tr>
</table>

### create_directory

Advantages over simple mkdir:
- additional return codes allow better error interpretation, not just the basic 0/success and 1/error
- control over stdout and stderr: mkdir prints on stderr on failure. This function allows to be sure:
	- that stdout returns either nothing, the mkdir status code or the mkdir stderr message, depending on $2
	- that stderr remains silent, even in case of mkdir failure

Examples:
- silent mode:

	create_directory "path/to/new/dir"
- status code:

	status=$(create_directory "/path/to/my_new_dir" "status")
- error message:

	err_msg=$(create_directory "/path/to/my_new_dir" "error_message")
	status=$?
- verbose mode: calls create_directory_verbose(), see its documentation for details

	mkdir_msg_def=("Info: folder created\n" "Error in %err_msg\n" "Info: folder exists, nothing to do\n")
	mkdir_msg_def[3]="Error: could not create directory, path not writeable\n"
	create_directory "$1" "verbose"  "   "

<table>
        <tr><td><b>Parametrization</b></td><td width="90%">
		- <code>$1</code> path<br>
		- <code>$2</code> <em>optional</em> <code>stdout</code> configuration - if omitted or an empty string, nothing is printed on stdout<ul>
			<li><code>status</code> / <code>$?</code> for the status</li>
			<li><code>error_message</code> / <code>err_msg</code> / <code>stderr</code> for the eventual <code>mkdir</code> error message</li>
			<li><code>verbose</code> calls <a href="#create_directory_verbose">create_directory_verbose()</a> internally</li>
		</ul><br>
		- <code>$3</code> <em>optional</em> prefix: if the <code>verbose</code> <code>stdout</code> mode is used, the prefix
        </td></tr>
        <tr><td><b>Pipes</b></td><td>
                - <code>stdin</code>: ignored<br>
                - <code>stdout</code>: <code>mkdir</code> error message if the operation failed and <code>$2</code> is set to <code>error_message</code> (or aliases)
        <tr><td><b>Status</b></td><td>
		0 <code>$1</code> created<br>
		1 <code>mkdir</code> error, <code>stderr</code> copied to fct_err_msg<br>
		2 <code>$1</code> empty<br>
		3 <code>$1</code> exists<br>
		4 <code>$1</code> not writeable
        </td></tr>
</table>

### create_directory_verbose
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
The supported variables are %path and %err_msg

<table>
        <tr><td><b>Parametrization</b></td><td width="90%">
		- <code>$1</code> path<br>
		- <code>$2</code> <em>optional</em> prefix, if omitted, defaults to a empty string
        </td></tr>
        <tr><td><b>Pipes</b></td><td>
                - <code>stdin</code>: ignored<br>
                - <code>stdout</code>: the printed message
        <tr><td><b>Status</b></td><td><a href="#create_directory">>create_directory()</a>'s status</td></tr>
	<tr><td><b>Globals</b></td><td>
		<code>$create_directory_msg_def as an array with 5 keys corresponding to the 5 possible return states of <a href="#create_directory>create_directory()</a>.
		<code>$create_directory_msg_def[0]</code> success message, etc.
	</td></tr>
</table>

### try_filepath_deduction
If there's only a single file (match) in the folder $1, returns it
<table>
        <tr><td><b>Parametrization</b></td><td width="90%">
		- <code>$1</code> folder to search<br>
		- <code>$2</code> <em>optional</em> pattern - if omitted, defaults to * (= everything)
        </td></tr>
        <tr><td><b>Pipes</b></td><td>
                - <code>stdin</code>: ignored<br>
                - <code>stdout</code>: in case of success (status = 0), the absolute filepath of the single match
        <tr><td><b>Status</b></td><td>
		0 in case of successful deduction<br>
		1 if <code>$1</code> doesn't exist
		2 if there's no match for <code>$2</code> (fallback: *) in <code>$1</code>
		3 if there's more than 1 match for <code>$2</code> (fallback: *) in <code>$1</code>
        </td></tr>
</table>


### load_configuration_file_value
The variable definition should have the format:

	variable=value
It should be on a single line, alone, with any number of whitespaces before the variable name and the variable name
and the assignment '='
Examples:

	cfg_filepath="/etc/test.conf"
	   cfg_filepath="/etc/test2.conf"
	timeout     = 25

<table>
        <tr><td><b>Parametrization</b></td><td width="90%">
		- <code>$1</code> path of the configuration file<br>
		- <code>$2</code> name of the variable to load
        </td></tr>
        <tr><td><b>Pipes</b></td><td>
                - <code>stdin</code>: ignored<br>
                - <code>stdout</code>: in case of success (status = 0), the value of the variable called <code>$2</code> in <code>$1</code>
        <tr><td><b>Status</b></td><td>
		0 in case of successful load<br>
		1 if <code>$1</code> is empty
		2 if <code>$2</code> is empty
		3 if the file doesn't exist
		4 if there's no read permission on <code>$1</code>
		5 if a variable with name <code>$2</code> is not found/defined
        </td></tr>
</table>
