Documentation for the functions in [installer_tools.sh](installer_tools.sh). A general overview is given in [the project documentation](README.md#installer-tools).

## Function documentation
If the pipes are not documented, the default is:
- `stdin`: piped input ignored
- `stdout`: empty

### get_package_manager()
Tries to detect the installed package manager.
<table>
	<tr><td><b>Pipes</b><td align="center"><code>stdout</code></td><td>in case of success, the package manager. Can be <em>apt</em> or <em>yum</em></td></tr>
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
If a command misses, the function looks for a package list depending on the detected package manager: <code>$apt_packages</code>
for *apt*, <code>$yum_packages</code> for *yum*, etc. It looks for a element in the array with the name of the command. If no package list or
no corresponding entry is found, the function tries to use the command name (<code>$1</code>) itself.

**Customization functions**

- handle_non_executable_dependency(): called if a path is found for the command but it's not executable. Receives that path as `$1`
- handle_dependency_installation(): called if a command is not defined. Receives the command as `$1` and the package manager (return value
  of [get_package_manager()](#get_package_manager)) as `$2`

**Verbose mode / message customization**

The variable placeholders `%command`, `%path` and `%package` are replaced with the corresponding values. `%path` and `%package` are
obtained via a  `$temp_var`, depending on the situation

| Status | `$temp_var` | Template
|:------:| ----------- | --------
|*1*| `%path` | `%command` (`%path`) already installed\n
|*2*| `%path` | `%command` (`%path`) was not executable, applied chmod +x successfully\n
|*3*| `%package` | `%command` installed successfully (package `%package`)\n
|*4*| `%path` | Error: `%command` (`%path`) is not executable and chmod +x failed\n
|*5*| `%package` | Error: `%command` installation failed (package `%package`)\n
|*6*| | Error: `%command` not installed and no package manager found\n
|*7*| | Error: `%command` is not installed and no package found to install it\n
|*8*| `%path` | Error: `%command` exists in $PATH at `%path` but it doesn't resolve to an existing filesystem location(broken symlink?)\n
|*9*| | Error: `%command` exists but there's a incoherence with which (it can't find it)\n
|*10*| | Error: command empty\n

<table>
        <tr><td rowspan="2"><b>Param.</b></td><td align="center"><code>$1</code><td width="90%">command</td></tr>
        <tr>    <td align="center">[<code>$2</code>]</td><td>
		<ul>
			<li>if <code>$3</code> is omitted or empty, nothing is written on <code>stdout</code></li>
                        <li>if <code>$3</code> is set to a non-empty value, the system tries to find a array variable with that name. If such a variable
                        is defined it tries to load the element which is at the index corresponding to the return status. If either the array or the array element
                        is not defined, it uses the default messages given above</li>
                </ul>
        </td></tr>
        <tr><td><b>Pipes</b><td align="center"><code>stdout</code></td><td></td></tr>
        <tr><td rowspan="10"><b>Status</b></td>
		<td align="center"><em>1</em></td><td><code>$1</code> already installed</td></tr>
        <tr>    <td align="center"><em>2</em></td><td>successfully applied <code>chmod +x</code> to <code>$1</code></td></tr>
        <tr>    <td align="center"><em>3</em></td><td><code>$1</code> installed successfully</td></tr>
        <tr>    <td align="center"><em>4</em></td><td><code>$1</code> not executable and <code>chmod +x</code> attempt failed</td></tr>
        <tr>    <td align="center"><em>5</em></td><td><code>$1</code> installation failed</td></tr>
        <tr>    <td align="center"><em>6</em></td><td><code>$1</code> not installed and no package manager found</td></tr>
        <tr>    <td align="center"><em>7</em></td><td><code>$1</code> not installed and no package found</td></tr>
        <tr>    <td align="center"><em>8</em></td><td>found <code>$1</code> in a $PATH folder but was unable to determine the actual path (usually broken symlinks)</td></tr>
        <tr>    <td align="center"><em>9</em></td><td>incoherence: everything seems fine (found $1 in a path folder, it's executable) but <code>which</code> didn't find
                it</td></tr>
        <tr>    <td align="center"><em>10</em></td><td><code>$1</code> is empty</td></tr>
	<tr><td><b>Globals</b></td><td align="center"></td><td>
		<ul>
			<li><code>$apt_packages</code>: associative array which defines the package(s) to install if the package manager is <em>apt</em></li>
			<li><code>$yum_packages</code>: associative array which defines the package(s) to install if the package manager is <em>yum</em></li>
		</ul>
	</td></tr>
</table>

### handle_dependencies()
[handle_dependency()](#handle_dependency) wrapper to handle dependency list

<table>
        <tr><td rowspan="2"><b>Param.</b></td><td align="center"><code>$1</code><td width="90%">command</td></tr>
        <tr>    <td align="center">[<code>$2</code>]</td><td>
                <ul>
                        <li>if <code>$3</code> is omitted or empty, nothing is written on <code>stdout</code></li>
                        <li>if <code>$3</code> is set to a non-empty value, the system tries to find a array variable with that name. If such a variable
                        is defined it tries to load the element which is at the index corresponding to the return status. If either the array or the array element
                        is not defined, it uses the default messages given above</li>
                </ul>
        </td></tr>
</table>
