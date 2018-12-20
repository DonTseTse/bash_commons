Documentation for the functions in [installer_tools.sh](installer_tools.sh). A general overview is given in [the project documentation](README.md#installer-tools).

## Function documentation
If the pipes are not documented, the default is:
- `stdin`: piped input ignored
- `stdout`: empty

### get_package_manager()
Tries to detect the installed package manager.
<table>
	<tr><td><b>Pipes</b><td align="center"><code>stdout</code></td><td width="90%">in case of success, the package manager. Can be <em>apt</em> or <em>yum</em></td></tr>
        <tr><td rowspan="2"><b>Status</b></td><td align="center"><em>0</em></td><td>package manager written on <code>stdout</code></td></tr>
        <tr>	<td align="center"><em>1</em></td><td>no package manager found</td></tr>
</table>

### get_executable_status()
Get a detailed executable status about a path. 
<table>
	<tr><td rowspan="2"><b>Param.</b></td><td align="center"><code>$1</code></td><td width="90%">executable name</td></tr>
        <tr>    <td align="center">[<code>$2</code>]</td><td>if it's set to <em>1</em>, the executable path is written on <code>stdout</code> if status is <em>0</em></td></tr>
        <tr><td><b>Pipes</b><td align="center"><code>stdout</code></td><td></td></tr>
        <tr><td rowspan="6"><b>Status</b></td>
		<td align="center"><em>0</em></td><td><code>$1</code> is executable</td></tr>
        <tr>    <td align="center"><em>1</em></td><td><code>$1</code> is not executable</td></tr>
	<tr>    <td align="center"><em>2</em></td><td><code>$1</code> not found in $PATH</td></tr>
        <tr>    <td align="center"><em>3</em></td><td>found <code>$1</code> in a $PATH folder but was unable to determine the actual path (usually broken symlinks)</td></tr>
        <tr>    <td align="center"><em>4</em></td><td>incoherence: everything seems fine (found $1 in a path folder, it's executable) but <code>which</code> didn't find 
		it</td></tr>
        <tr>    <td align="center"><em>5</em></td><td><code>$1</code> is empty</td></tr>
</table>

### handle_dependency()
If the command `$1` is not found or not executable, this function tries to install it, respectively make it executable. Both operations may be customized through callback
functions. 

To start, <a href="#get_executable_status">get_executable_status()</a> is called on `$1`. It returns:
- *1*: `$1` is not executable
- *2*: `$1` is not installed
- above *2*: non-recoverable error, abort
- *0*: `$1` is installed & executable, there's nothing to do

To customize the handling callback functions may be defined: 
- `handle_dependency_installation()`: receives the command and the package manager (`stdout` of [get_package_manager()](#get_package_manager)) as parameters
- `handle_non_executable_dependency()`: called with the path as parameter

The default handling is simply a `chmod +x` if it's not executable; if it's not installed, the function looks for a package list depending on to 
the detected package manager: <code>$apt_packages</code> for *apt*, <code>$yum_packages</code> for *yum*, etc. 
Inside this list, it looks for a element with the name of the command. If no package list or no corresponding entry is found, the function tries 
to use the command name (`$1`) itself.

Examples:
```bash
# on a apt based system
declare -A apt_packages
apt_packages[my_command]="my_command_package"
# other command package relationship definitions, also for other package managers ...
handle_dependency "my_command"
```
Calls `apt-get install "my_command_package"` if `my_command` is not found.

**Verbose mode / message customization**

The variable placeholders `%command`, `%path` and `%package` are replaced with the corresponding values. `%path` and `%package` are
obtained via a  `$temp_var`, depending on the status: 

| Status | `$temp_var` | Template
|:------:| ----------- | --------
|*1*| `%path` | `%command` (`%path`) already installed
|*2*| `%path` | `%command` (`%path`) was not executable, applied chmod +x successfully
|*3*| `%package` | `%command` installed successfully (package `%package`)
|*4*| `%path` | Error: `%command` (`%path`) is not executable and chmod +x failed
|*5*| `%package` | Error: `%command` installation failed (package `%package`)
|*6*| | Error: `%command` not installed and no package manager found
|*7*| | Error: `%command` is not installed and no package found to install it
|*8*| `%path` | Error: `%command` exists in $PATH at `%path` but it doesn't resolve to an existing filesystem location(broken symlink?)
|*9*| | Error: `%command` exists but there's a incoherence with which (it can't find it)
|*10*| | Error: command empty

The messages can be customized by setting up an array variable where the indizes are the states and the values the corresponding templates (i.e. "already 
installed" message template is at index *0*, etc.). The name of the array variable - and not the variable itself - has to be provided as 2nd call parameter.
It's perfectly valid to customize a subset of states/templates, the function falls back to the default templates where it can't find a
customization. In the next example, the "installed successfully" message template is overwritten:
```
# on a apt based system
declare -A apt_packages && apt_packages[sshd]="openssh-server"
msg_defs[3]="%package installed for %cmd"
handle_dependency "sshd" "msg_defs"
```
prints *openssh-server installed for sshd* if `sshd` misses. The message templates don't support text flow control sequences like *\t*
or *\n*. In fact, the message is a string input to a `printf`; these sequences are hence escaped and appear in the final message. The default
output pattern is "just the message" (no newline): *%s*. To add f.ex. a newline at the end of each printed message, set `$3` to *%s\n*.

<table>
        <tr><td rowspan="3"><b>Param.</b></td><td align="center"><code>$1</code><td width="90%">command</td></tr>
        <tr>    <td align="center">[<code>$2</code>]</td><td>
		<ul>
			<li>if <code>$2</code> is omitted or empty, nothing is written on <code>stdout</code></li>
                        <li>if <code>$2</code> is set to a non-empty value, the system tries to find a array variable with that name. If such a variable
                        is defined it tries to load the element which is at the index corresponding to the return status. If either the array or the array element
                        is not defined, it uses the default messages given above</li>
                </ul>
        </td></tr>
	<tr><td></td><td align="center">[<code>$3</code>]</td><td><code>printf</code> pattern for messages, default to <em>%s<em> ("just the message") if 
		omitted. Look at the explanation above.	</td></tr>
        <tr><td><b>Pipes</b><td align="center"><code>stdout</code></td><td>the message if <code>$2</code> is not omitted or empty</td></tr>
        <tr><td rowspan="10"><b>Status</b></td>
		<td align="center"><em>1</em></td><td><code>$1</code> already installed</td></tr>
        <tr>    <td align="center"><em>2</em></td><td>successfully applied <code>chmod +x</code> to <code>$1</code></td></tr>
        <tr>    <td align="center"><em>3</em></td><td><code>$1</code> installed successfully</td></tr>
        <tr>    <td align="center"><em>4</em></td><td><code>$1</code> not executable and <code>chmod +x</code> attempt failed</td></tr>
        <tr>    <td align="center"><em>5</em></td><td><code>$1</code> installation failed</td></tr>
        <tr>    <td align="center"><em>6</em></td><td><code>$1</code> not installed and no package manager found</td></tr>
        <tr>    <td align="center"><em>7</em></td><td>found <code>$1</code> in a $PATH folder but was unable to determine the actual path (usually broken symlinks)</td></tr>
        <tr>    <td align="center"><em>8</em></td><td>incoherence: everything seems fine (found $1 in a path folder, it's executable) but <code>which</code> didn't find
                it</td></tr>
        <tr>    <td align="center"><em>9</em></td><td><code>$1</code> is empty</td></tr>
	<tr><td><b>Globals</b></td><td align="center"></td><td>
		<ul>
			<li><code>$apt_packages</code>: associative array which defines the package(s) to install if the package manager is <em>apt</em></li>
			<li><code>$yum_packages</code>: associative array which defines the package(s) to install if the package manager is <em>yum</em></li>
		</ul>
	</td></tr>
</table>

### handle_dependencies()
[handle_dependency()](#handle_dependency) wrapper to handle dependency list. Its return status is the amount of failed dependencies. 

<table>
        <tr><td rowspan="3"><b>Param.</b></td><td align="center"><code>$1</code><td width="90%">list of dependencies separated with spaces, f.ex. *docker sshd mysql*</td></tr>
        <tr>    <td align="center">[<code>$2</code>]</td><td rowspan="2">Stdout output control directly passed through to [handle_dependency()](#handle_dependency)</td></tr>
	<tr><td></td><td align="center">[<code>$3</code>]</td></tr>
	<tr><td><b>Status</b></td><td>*0* if all dependencies in <code>$1</code> are installed and executable, the amount of failed dependencies otherwise. 
	A dependency is considered failed if [handle_dependency()](#handle_dependency) returns a status above *3*</td></tr>
</table>

### reset_package_lists()
Reset package manager cache. 

<table>
	<tr><td><b>Status</b></td><td><em>2</em> if the no package manager is found, the return status of the package manager operation otherwise</td></tr>
</table>

