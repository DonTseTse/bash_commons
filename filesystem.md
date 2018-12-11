Documentation for the functions in [filesystem.sh](filesystem.sh). A general overview is given in [the project documentation](README.md#filesystem).

## Quick access
- [copy_file()](#copy_file), [copy_folder()](#copy_folder) (+ the internal handler [handle_cp_or_mv()](#handle_cp_or_mv))
- [create_folder()](#create_folder)
- [get_real_path()](#get_real_path)
- [get_existing_path_part()](#get_existing_path_part)
- [get_new_path_part()](#get_new_path_part)
- [get_script_path()](#get_script_path)
- [is_path_a()](#is_path_a)
- [is_readable()](#is_readable)
- [is_writeable()](#is_writeable)
- [load_configuration_file_value()](#load_configuration_file_value)
- [move_file()](#move_file) and [move_folder()](#move_folder) (+ the internal handler [handle_cp_or_mv()](#handle_cp_or_mv))
- [remove_file()](#remove_file) and [remove_folder()](#remove_folder) (+ the internal handler - [handle_rm()](#handle_rm))
- [try_filepath_deduction()](#try_filepath_deduction)

## Function documentation
If the pipes are not documented, the default is:
- `stdin`: ignored
- `stdout`: empty

Parameters enclosed in brackets [ ] are optional.

### get_real_path()
The function processes the path `$1` in 4 ways:
- if it's a relative path, it's transformed to the absolute equivalent
- symbolic file links are resolved, even if they are chained (i.e. a link pointing to a link pointing to a link etc.)
- symbolic folder links are resolved using `cd`'s `-P` flag
- it cleans up *../* and *./* components

It works for files and folders with the restriction that they must exist. Use the [string handling collection's get_absolute_path()](string_handling.md#get_absolute_path)
for paths that don't exist. 
<table>
	<tr><td><b>Param.</b></td><td align="center"><code>$1</code></td><td width="90%">path to resolve and clean</td></tr>
	<tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>if status is <em>0</em>, the "real" path of <code>$1</code>, empty otherwise</td></tr>
	<tr><td rowspan="2"><b>Status</b></td>
		<td align="center"><em>0</em></td><td>success, "real" path written on <code>stdout</code></td></tr>
	<tr>    <td align="center"><em>1</em></td><td><code>$1</code> doesn't exist</td></tr>
</table>

### get_script_path()
Inspired by this [StackOverflow(SO) answer](https://stackoverflow.com/questions/59895/getting-the-source-directory-of-a-bash-script-from-within/246128#246128). 
The function returns the full path including the filename and it's able to work in any call constellation: sourced, called in a subshell etc. 
It relies on `$BASH_SOURCE` which changes depending on the constellation, however, the element in this array with the highest index is always the path of the script 
executed initially.

**Important**: call this function as early as possible; before any directory changes in the script. The `$BASH_SOURCE` entry depends on the way the script is called and one of the 
possibilities is that the script is executed in a terminal using a relative filepath with respect to the shell's current directory; in that case the `$BASH_SOURCE` 
entry  only contains that relative filepath and if the current directory changes, the output of this function is wrong. 
<table>
	<tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td width="90%">"real" absolute path (folder + file symlink resolved, cleaned) of the executed script</td></tr>
	<tr><td><b>Status</b></td><td align="center"><em>0</em></td><td></td></tr>
</table>

### is_path_a()
Combined existence and type check. Example:
```bash
is_path_a "$path" "file" || echo "$path is not a file" && return
# do something with the file at $path...
```
<table>
        <tr><td rowspan="2"><b>Param.</b></td>
                <td align="center"><code>$1</code></td><td width="90%">path</td></tr>
        <tr>    <td align="center"><code>$2</code></td><td>inode type: accepted values are <em>folder</em>, <em>file</em> or <em>symlink</em></td></tr>
        <tr><td rowspan="6"><b>Status</b></td>
                <td align="center"><em>0</em></td><td>path <code>$1</code> is of type <code>$2</code></td></tr>
        <tr>    <td align="center"><em>1</em></td><td>path <code>$1</code> is not of type <code>$2</code></td></tr>
        <tr>    <td align="center"><em>2</em></td><td>path <code>$1</code> doesn't exist</td></tr>
        <tr>    <td align="center"><em>3</em></td><td><code>$1</code> is empty</td></tr>
        <tr>    <td align="center"><em>4</em></td><td><code>$2</code> is empty</td></tr>
        <tr>    <td align="center"><em>5</em></td><td><code>$2</code> is unknown</td></tr>
</table>

### is_readable()
Helpers to avoid read permission errors, with an optional additional internal <a href="#is_path_a">is_path_a()</a> type check. A typical use example is:
```bash
is_readable "$path" || echo "Path $path is not readable. Aborting..." && exit
```
<table>
        <tr><td rowspan="2"><b>Param.</b></td>
                <td align="center"><code>$1</code></td><td width="90%">path</td></tr>
        <tr>    <td align="center">[<code>$2</code>]</td><td>inode type: accepted values are <em>folder</em>, <em>file</em> or <em>symlink</em>. If the value is 
		omitted or empty, no type check is performed.</td></tr>
        <tr><td rowspan="6"><b>Status</b></td>
                <td align="center"><em>0</em></td><td>path <code>$1</code> is readable</td></tr>
        <tr>    <td align="center"><em>1</em></td><td>path <code>$1</code> is not readable</td></tr>
        <tr>    <td align="center"><em>2</em></td><td>path <code>$1</code> doesn't exist</td></tr>
        <tr>    <td align="center"><em>3</em></td><td><code>$1</code> doesn't have type <code>$2</code></td></tr>
        <tr>    <td align="center"><em>4</em></td><td><code>$1</code> is empty</td></tr>
        <tr>    <td align="center"><em>5</em></td><td><code>$2</code> is unknown</td></tr>
</table>

### is_writeable()
Helper to avoid write permission errors. Example:
```bash
is_writeable "$path" || echo "Path $path is not writeable. Aborting..." && exit
```
The function has a "check on existing path part" flag  which configures the behavior for filepaths that don't exist on the system (yet). In 
these cases the answer whether a write will succeed or not depends on the type of operation and whether it requires the direct parent folder to 
exist or not. `mkdir` is a good example - let's imagine there's a empty directory `/test` where the user has write permission and wants to create 
the path `/test/folder/subfolder`:

- `mkdir /test/folder/subfolder` will fail because `/test/folder` doesn't exist 
- `mkdir -p /test/folder/subfolder` works because the `-p` tells `mkdir` it's allowed to create multiple nested directories and since writing to 
   `/test` is permitted, the operation is successful

This function is able to take this into account: 

- if the "check on existing path part" flag `$2` is not raised it fails if the direct parent folder doesn't exist
- if the flag is raised (`$2` set to *1*), it does what its name indicates: it walks up the path until it finds an existing directory and checks the write permission on 
  that directory.

In the `mkdir` example above, `is_writeable /test/folder/subfolder` would return status *2* (= not writeable, parent missing); with the flag (`$2` set to *1*), 
that switches to status *0* (= writeable).
<table>
        <tr><td rowspan="2"><b>Param.</b></td>
                <td align="center"><code>$1</code></td><td width="90%">path</td></tr>
        <tr>    <td align="center">[<code>$2</code>]</td><td>"check on existing path part" flag - if the parent directory of <code>$1</code> doesn't exist, it
                  configures whether the function fails or if it walks up <code>$1</code> until it finds an existing folder on which it checks the write
                  permission - see explanations above
	</td></tr>
        <tr><td rowspan="4"><b>Status</b></td>
                <td align="center"><em>0</em></td><td>path <code>$1</code> can be written</</td></tr>
	<tr>	<td align="center"><em>1</em></td><td>there's no write permission on path <code>$1</code></td></tr>
	<tr>	<td align="center"><em>2</em></td><td>the direct parent folder of path <code>$1</code> doesn't exist (can only happen if <code>$2</code> is omitted or set to <em>0</em>)</li>
        <tr>    <td align="center"><em>3</em></td><td>if <code>$1</code> is empty</td></tr>
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
If there's only a single file (match) in the folder `$1`, returns its path
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

### create_folder()
`mkdir` wrapper with:
- several checks before the actual creation attempt which allow to get specific status codes for any possible error type:
  if the path is empty (status *2*), exists (*3*) or if the user has no write permission (*4*)
- control over `stdout` and `stderr`: `mkdir` writes on `stderr` in case of failure. This function allows to be sure:
	- that `stdout` contains either nothing, the `mkdir` status code or `stderr` message, or a custom message, depending on the 
	  the stdout configuration `$2`
	- that `stderr` remains silent, even in case of `mkdir` failure
- a system for the message customization: one template by status, with variable placeholders to inject the runtime parameters

**Verbose mode / message customization**:

The variable placeholders `%path` and `%stderr_msg` are replaced by the path `$1` and the `mkdir` error message. Latter is only relevant if 
status is *1* (`mkdir` error), otherwise it should be empty. The default message templates are:

| Status | Template
|:------:| --------
|*0*| folder `%path` created\n
|*1*| `%stderr_msg`\n
|*2*| folder creation error: no path provided\n
|*3*| folder creation error: `%path` exists\n
|*4*| folder creation error: no write permission for `%path`\n

`%stderr_msg` is empty if status is not *1*.

`create_folder "/new/folder/path" "verbose"` prints *folder /new/folder/path created\n* in case of success. The messages can
be customized by setting up an array variable where the indizes are the states and the values the corresponding templates (i.e. the success message
template is at index *0*, etc.). The name of the array variable - and not the variable itself - has to be provided as 3rd call parameter.
It's perfectly valid to customize a subset of states/templates, the function falls back to the default templates where it can't find a
customization.

Example: `create_folder "/new/folder/path" "verbose"` would print *folder /new/folder/path created\n* in case of success. These messages can
be customized by creating an array variable with elements that have the status as index. The name of the array variable has to be provided
as 3rd call parameter. In the next example, the success message template is overwritten:
```
msg_defs[0]="custom message: folder %path created\n"
create_folder "new/folder/path" "verbose" "msg_defs"
``` 
prints *custom message: folder /new/folder/path/ created\n* if it's successful.

**Examples**:

- `stdout` silent: `create_folder "path/to/new/dir"`
- status code captured to variable: `status=$(create_folder "/path/to/my_new_dir" "status")`
- `mkdir` error message captured to variable: `error_msg=$(create_folder "/path/to/my_new_dir" "error_message")`

<table>
        <tr><td rowspan="3"><b>Param.</b></td>
                <td align="center"><code>$1</code></td><td width="90%">path</td></tr>
        <tr>    <td align="center">[<code>$2</code>]</td><td><code>stdout</code> configuration:
                <ul>
                        <li>if omitted or an empty string, nothing is written on <code>stdout</code></li>
			<li><em>status</em> or <em>$?</em>: status code</li>
                        <li><em>error_message</em> or <em>err_msg</em> or <em>stderr</em>: <code>mkdir</code> call <code>stderr</code> output</li>
                        <li><em>verbose</em>: status specific message, see explanations above</li>
                </ul>
        </td></tr>
        <tr>    <td align="center">[<code>$3</code>]</td><td>if <code>$2</code> is set to <em>verbose</em>, the name of the array variable which contains
	the custom message templates - if omitted, the default templates are used; see explanations above</td></tr>
        <tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>
                <ul>
			<li>empty if <code>$2</code> omitted or set to an empty string
                        <li>the status returned by the <code>mkdir</code> call if <code>$2</code> is set to <em>status</em></li>
                        <li>eventual <code>sterr</code> output of the <code>mkdir</code> call if <code>$2</code> is set to <em>error_message</em></li>
                        <li>the status specific message if <code>$2</code> is set to <em>verbose</em></li>
                </ul>
        </td></tr>
        <tr><td rowspan="5"><b>Status</b></td>
                <td align="center"><em>0</em></td><td>folder <code>$1</code> created</td></tr>
        <tr>    <td align="center"><em>1</em></td><td><code>mkdir</code> error, if <code>$2</code> is set to <em>error_message</em>, <code>stdout</code>
                contains the content of <code>mkdir</code>'s <code>stderr</code> output</td></tr>
        <tr>    <td align="center"><em>2</em></td><td>path <code>$1</code> exists</td></tr>
        <tr>    <td align="center"><em>3</em></td><td>path <code>$1</code> is not writeable</td></tr>
        <tr>    <td align="center"><em>4</em></td><td><code>$1</code> is empty</td></tr>
</table>

### handle_cp_or_mv()
Internal handler for file/folder copy/move, used by the wrapper functions <a href="#copy_file">copy_file()</a>, <a href="#copy_folder">copy_folder()</a>,
<a href="#move_file">move_file()</a> and <a href="#move_folder">move_folder()</a>. See their documentation for details.
<table>
        <tr><td rowspan="5"><b>Param.</b></td>
                <td align="center"><code>$1</code></td><td width="90%">mode, possible values: <em>copy</em>, <em>cp</em>, <em>move</em> or <em>mv</em></td></tr>
                <td align="center"><code>$2</code></td><td width="90%">source path</td></tr>
        <tr>    <td align="center"><code>$3</code></td><td>destination path</td></tr>
        <tr>    <td align="center">[<code>$4</code>]</td><td><code>stdout</code> configuration:
                <ul>
                        <li>if omitted or an empty string, nothing is written on <code>stdout</code></li>
                        <li><em>status</em> or <em>$?</em>: the status code</li>
                        <li><em>error_message</em> or <em>err_msg</em> or <em>stderr</em>: <code>mv</code>/<code>cp</code> call <code>stderr</code> output</li>
                        <li><em>verbose</em>: status specific message, see explanations in the wrapper functions</li>
                </ul>
        </td></tr>
        <tr>    <td align="center">[<code>$5</code>]</td><td>if <code>$4</code> is set to <em>verbose</em>, the name of the array variable which contains the 
		custom message templates - if omitted, the default templates are used, see exaplanation in the wrapper functions</td></tr>
	<tr><td colspan="3">Pipes and status are documented below for the wrapper functions. handle_cp_or_mv() has just one additional status which will 
	never occur if the wrapper functions are used: status <em>7</em> to signal mode <code>$1</code> is unknown</td></tr>
</table>

<a name="copy_file"></a><a name="copy_folder"></a><a name="move_file"></a><a name="move_folder"></a>
### copy_file(), copy_folder(), move_file() and move_folder()
`cp` and `mv` wrapper with:
- several checks before the actual copy/move attempt which allow to get specific status codes for any possible error type:
	- if the source path is empty (status *2*), doesn't exist (*3*) or if the user has no read permission (*4*)
	- if the destination path exists (status *5*) or if the user has no write permission (*6*)
- control over `stdout` and `stderr`: `mv` and `cp` write on `stderr` in case of failure. The functions allows to be sure:
	- that `stdout` either contains nothing, the `mv`/`cp` status code or `stderr` message, or a custom message, depending on the
	  the `stdout`configuration `$3`
	- that `stderr` remains silent, even in case of `mv`/`cp` failure
- a system for the message customization: one template by status, with variable placeholders to inject the runtime parameters

**Verbose mode / message customization**:

The templates support 4 variable placeholders:

- `%src`: set to `$2`
- `%dest`: set to `$3`
- `%stderr_msg`: the `stderr` output of the `mv` or `cp` call. Only relevant for status *1*.
- `%op`: has the value *move* or *copy*

The default message templates are:

| Status | Template
|:------:| --------
|*0*|- `%src` moved to `%dest`\n (for *move*/*mv*)<br>- `%src` copied to `%dest`\n (for *copy*/*cp*) 
|*1*|`%stderr_msg`\n
|*2*|error: `%op` failed, source path empty\n
|*3*|error: `%op` from `%src` to `%dest` failed because `%src` doesn't exist\n
|*4*|error: `%op` from `%src` to `%dest` failed because there's no read permission on `%src`\n
|*5*|error: `%op` from `%src` to `%dest` failed because `%dest` exists (won't overwrite)\n
|*6*|error: `%op` from `%src` to `%dest` failed because there's no write permission on `%dest`\n

`copy_file "/path/to/src" "path/to/dest" "verbose"` prints */path/to/src copied to /path/to/dest\n* in case of success. The messages can
be customized by setting up an array variable where the indizes are the states and the values the corresponding templates (i.e. the success message
template is at index *0*, etc.). The name of the array variable - and not the variable itself - has to be provided as 4th call parameter.
It's perfectly valid to customize a subset of states/templates, the function falls back to the default templates where it can't find a
customization. In the next example, the success message template is overwritten:
```bash
msg_defs[0]="custom message: %source copied to %destination"
copy_file "/path/to/src" "/path/to/dest"  "verbose" "msg_defs"
```
prints *custom message: /path/to/src copied to /path/to/dest* if it's successful.

**Examples**:
- `stdout` silent: `move_file "path/to/src" "path/to/dest"`
- status code captured to variable: `status=$(move_folder "/path/to/src" "/path/to/dest" "status")`
- `cp` error message captured to variable: `err_msg=$(copy_file "/path/to/src" "/path/to/dest"  "error_message")`
<table>
        <tr><td rowspan="4"><b>Param.</b></td>
                <td align="center"><code>$1</code></td><td width="90%">source path</td></tr>
        <tr>    <td align="center"><code>$2</code></td><td>destination path</td></tr>
        <tr>    <td align="center">[<code>$3</code>]</td><td><code>stdout</code> configuration:
                <ul>
                        <li>if omitted or an empty string, nothing is written on <code>stdout</code></li>
                        <li><em>status</em> or <em>$?</em>: <code>mv</code> respectively <code>cp</code> call status code</li>
                        <li><em>error_message</em> or <em>err_msg</em> or <em>stderr</em>: the <code>mv</code> respectively <code>cp</code> call <code>stderr</code> output</li>
                        <li><em>verbose</em>: status specific message - see explanations above</li>
                </ul>
        </td></tr>
        <tr>    <td align="center">[<code>$4</code>]</td><td>if <code>$3</code> is set to <em>verbose</em>, the name of the array variable which contains the
                custom message patterns. If omitted, the default message patterns are used; see explanations above</td></tr>
        <tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>
                <ul>
                        <li>empty if <code>$3</code> omitted or set to an empty string
                        <li>the status returned by the <code>mv</code>/<code>cp</code> call if <code>$3</code> is set to <em>status</em></li>
                        <li>eventual <code>sterr</code> output of the <code>mv</code>/<code>cp</code> call if <code>$3</code> is set to <em>error_message</em></li>
                        <li>the status specific message if <code>$3</code> is set to <em>verbose</em></li>
                </ul>
        </td></tr>
	<tr><td rowspan="8"><b>Status</b></td>
                <td align="center"><em>0</em></td><td>operation successful</td></tr>
        <tr>    <td align="center"><em>1</em></td><td>operation failure, if <code>$3</code> is set to <em>error_message</em> (or its aliases), <code>stdout</code>
                contains <code>mv</code>'s respectively <code>cp</code>'s <code>stderr</code> output</td></tr>
        <tr>    <td align="center"><em>2</em></td><td>the source path <code>$2</code> doesn't exist</td></tr>
        <tr>    <td align="center"><em>3</em></td><td>no read permission on source path <code>$2</code></td></tr>
        <tr>    <td align="center"><em>4</em></td><td>the destination path <code>$3</code> exists</td></tr>
        <tr>    <td align="center"><em>5</em></td><td>no write permission on destination path <code>$3</code></td></tr>
        <tr>    <td align="center"><em>6</em></td><td>the source path <code>$2</code> is empty</td></tr>
        <tr>    <td align="center"><em>7</em></td><td>the destination path <code>$3</code> is empty</td></tr>
</table>

### handle_rm()
Internal handler for file/folder removal, used by the wrapper functions <a href="#remove_file">remove_file()</a>, <a href="#remove_folder">remove_folder()</a>,
see their documentation for details.
<table>
        <tr><td rowspan="3"><b>Param.</b></td>
                <td align="center"><code>$1</code></td><td width="90%">path</td></tr>
        <tr>	<td align="center">[<code>$2</code>]</td><td> <code>stdout</code> configuration:
			<ul>
				<li>if omitted or an empty string, nothing is written on <code>stdout</code></li>
				<li><em>status</em> or <em>$?</em>: <code>rm</code> call status code</li>
				<li><em>error_message</em> or <em>err_msg</em> or <em>stderr</em>: <code>rm</code> call <code>stderr</code> output</li>
				<li><em>verbose</em>: status specific message, see explanations in the wrapper functions</li>
			</ul>
		</td></tr>
        <tr>    <td align="center">[<code>$3</code>]</td><td>if <code>$2</code> is set to <em>verbose</em>, the name of the array variable which contains the
                custom message patterns. If omitted, the default message patterns are used</td></tr>
        <tr><td colspan="3">Pipes and status are documented below for the wrapper functions.</td></tr>
</table>

<a name="remove_file"></a><a name="remove_folder"></a>
### remove_file() and remove_folder()
`rm` wrapper with:
- several checks before the actual removal attempt which allow to get specific status codes for any possible error type:
  if the path is empty (status *2*), doesn't exist (*3*) or if the user has no write permission (*4*)
- control over `stdout` and `stderr`: `rm` writes on `stderr` in case of failure. This functions allows to be sure:
	- that `stdout` either contains nothing, the `rm` status code or `stderr` message, or a custom message, depending on the `stdout`
	  configuration `$2`
	- that `stderr` remains silent, even in case of `rm` failure
- a system for the message customization: one template by status, with variable placeholders to inject the runtime parameters

**Verbose mode / message customization**:

The variable placeholders `%path` and `%stderr_msg` are replaced by the path `$1` and the `mkdir` error message. The default message templates are:

  | Status | Template
  |:------:| --------
  |*0*| `%path` removed\n
  |*1*| `%stderr_msg`\n
  |*2*| removal error: path is empty\n
  |*3*| removal error: `%path` doesn't exist\n
  |*4*| emoval error: no write permission on `%path`\n

`%stderr_msg` is empty if status is not *1*.

`remove_file "/path/to/remove" "verbose"` prints */path/to/remove removed\n* in case of success. The messages can
be customized by setting up an array variable where the indizes are the states and the values the corresponding templates (i.e. the success message
template is at index *0*, etc.). The name of the array variable - and not the variable itself - has to be provided as 3rd call parameter. 
It's perfectly valid to customize a subset of states/templates, the function falls back to the default templates where it can't find a 
customization. In the next example, the success message template is overwritten:
```bash
msg_defs[0]="custom message: %path removed\n"
remove_folder "/path/to/remove" "verbose"  "msg_defs"
```
prints *custom message: /path/to/remove removed* if it's successful.  

**Examples**:

- `stdout` silent: `remove_folder "path/to/new/dir"`
- status code captured to a variable: `status=$(remove_file "/path/to/file_to_remove" "status")`
- `rm` error message captured to a variable: 
```bash
err_msg=$(remove_folder "/path/to/my_new_dir" "error_message")
```
<table>
        <tr><td rowspan="4"><b>Param.</b></td>
                <td align="center"><code>$1</code></td><td width="90%">path</td></tr>
        <tr>    <td align="center">[<code>$2</code>]</td><td><code>stdout</code> configuration:
                <ul>
                        <li>if omitted or an empty string, nothing is printed on <code>stdout</code></li>
                        <li><em>status</em> / <em>$?</em>: <code>mkdir</code> status code</li>
                        <li><em>error_message</em> / <em>err_msg</em>: / <em>stderr</em> <code>mkdir</code> call <code>stderr</code> output</li>
                        <li><em>verbose</em>: for a status specific message, see explanations above</li>
                </ul>
        </td></tr>
        <tr>    <td align="center">[<code>$3</code>]</td><td>if <code>$2</code> is set to <em>verbose</em>, the name of the array variable which contains
        the custom message templates - see explanations above</td></tr>
	<tr>	<td align="center">[<code>$4</code>]</td><td>"return error if <code>$1</code> doesn't exist" flag:
		<ul>
			<li><em>1</em>: the function returns with status <em>2</em> if <code>$1</code> doesn't exist
			<li>omitted or any other value: the function returns with status <em>0</em> if <code>$1</code> doesn't exist
		</ul>
	</td></tr>
	<tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>
                <ul>
                        <li>empty if <code>$2</code> omitted or set to an empty string
                        <li>the <code>rm</code> status code if <code>$2</code> is set to <em>status</em> or <em>$?</em></li>
                        <li>eventual <code>sterr</code> output of the <code>rm</code> call, if <code>$2</code> is set to <em>error_message</em> (or aliases)</li>
                        <li>the message if <code>$2</code> is set to <em>verbose</em></li>
                </ul>
        </td></tr>
        <tr><td rowspan="5"><b>Status</b></td>
                <td align="center"><em>0</em></td><td><code>$1</code> removed or doesn't exist (if <code>$4</code> is omitted or set to something else than <em>1</em>)</td></tr>
        <tr>    <td align="center"><em>1</em></td><td><code>rm</code> error, if <code>$2</code> is set to <em>error_message</em> (or aliases), <code>stdout</code>
                contains the content of <code>rm</code>'s <code>stderr</code> output</td></tr>
        <tr>    <td align="center"><em>2</em></td><td>path <code>$1</code> is not writeable</td></tr>
        <tr>    <td align="center"><em>3</em></td><td>path <code>$1</code> doesn't exist (only if <code>$4</code> is set to <em>1</em>)</td></tr>
        <tr>    <td align="center"><em>4</em></td><td><code>$1</code> is empty</td></tr>
</table>

### load_configuration_file_value()
Bash allows to `source` (aka `.`) files which is a convenient way to load f.ex. configuration files, however, it has disadvantages as well:
- the files have to comply with the bash syntax of course, f.ex. regarding comments, the way the variables are defined, etc. 
- the calling application has no control which variables are defined (or not), which ones are overwritten, etc.

It's sometimes easier and more flexible to load values with a file content search and extraction method like this function which is based on a search with `grep` 
and the extraction of the value using string processing utilities. 

Variable definitions should have the assignment format:

	<variable name>=<value>
Each definition has to be on a single line, with any number of whitespaces before the variable name, between the variable name and the assignment operator '=' or between 
the operator and the value. Inline comments are not allowed, they should be on their own lines. Examples of valid definitions:

	cfg_filepath="/etc/test.conf"
	I'm a comment
	   cfg_filepath="/etc/test2.conf"
	timeout     = 25

If the variable is enclosed in quotes (i.e. the quotes are loaded as part of the value) they are removed with the
[string handling collection's sanitize_variable_quotes()](string_handling.md#sanitize_variable_quotes)
<table>
	<tr><td rowspan="2"><b>Param.</b></td>
		<td align="center"><code>$1</code></td><td width="90%">path of the configuration file</td></tr>
	<tr>    <td align="center"><code>$2</code></td><td>name of the variable to load</td></tr>
	<tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>if status is <em>0</em>, the loaded value, empty otherwise</td></tr>
	<tr><td rowspan="7"><b>Status</b></td>
                <td align="center"><em>0</em></td><td>successful, value is written on <code>stdout</code></td></tr>
        <tr>    <td align="center"><em>1</em></td><td>file <code>$1</code> doesn't exist</td></tr>
        <tr>    <td align="center"><em>2</em></td><td>path <code>$1</code> is not a file</td></tr>
        <tr>    <td align="center"><em>3</em></td><td>no read permission on file <code>$1</code></td></tr>
        <tr>    <td align="center"><em>4</em></td><td>no variable definition for the name <code>$2</code></td></tr>
        <tr>    <td align="center"><em>5</em></td><td><code>$1</code> is empty</td></tr>                                                    
        <tr>    <td align="center"><em>6</em></td><td><code>$2</code> is empty</td></tr>
</table>
