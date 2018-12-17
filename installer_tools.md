### get_package_manager()
<table>
	<tr><td><b>Pipes</b><td align="center"><code>stdout</code></td><td>in case of success, the package manager. Can be <em>apt</em> or <em>yum</em></td></tr>
        <tr><td rowspan="2"><b>Status</b></td><td align="center"><em>0</em></td><td>package manager written on <code>stdout</code></td></tr>
        <tr><td>	<td align="center"><em>1</em></td><td>no package manager found</td></tr>
</table>
TODO extend to the other package managers

### get_executable_status()
<table>
	<tr><td rowspan="2"><b>Param.</b></td><td align="center"><code>$1</code></td><td width="90%">executable name</td></tr>
        <tr>    <td align="center">[<code>$2</code>]</td><td>if it's set to <em>1</em>, the executable path is written on <code>stdout</code> if status is <em>0</em></td></tr>
        <tr><td><b>Pipes</b><td align="center"><code>stdout</code></td><td></td></tr>
        <tr><td rowspan="6"><b>Status</b></td>
		<td align="center"><em>0</em></td><td><code>$1</code> is executable</td></tr>
        <tr>    <td align="center"><em>1</em></td><td><code>$1</code> is not executable</td></tr>
	<tr>    <td align="center"><em>2</em></td><td><code>$1</code> not found in $PATH</td></tr>
        <tr>    <td align="center"><em>3</em></td><td>found <code>$1</code> in a $PATH folder but was unable to determine the actual path (usually broken symlinks)</td><$
        <tr>    <td align="center"><em>4</em></td><td>incoherence: everything seems fine (found $1 in a path folder, it's executable) but <code>which</code> didn't find 
		it</td></tr>
        <tr>    <td align="center"><em>5</em></td><td><code>$1</code> is empty</td></tr>
</table>

### handle_dependency()

Customization functions:
- handle_non_executable_dependency(): called if a path is found for the command but it's not executable. Receives that path as `$1`
- handle_dependency_installation(): called if a command is not defined. Receives the command as `$1` and the package manager (return value
  of [get_package_manager()](#get_package_manager)) as `$2`

" - $1: no package name specified for $1 (package manager: $2), trying with the name of the command itself"

**Verbose mode / message customization**

The variable placeholders `%command`, `%path` and `%package` are replaced with the corresponding values. `%path` and `%package` are
obtained via a  `$temp_var`, depending on the situation

| Status | `$temp_var` | Template
|:------:| ----------- | --------
|*1*| `%path` | `%command` (`%path`) already installed\n
|*2*| `%path` | `%command` (`%path`) was not executable, applied chmod +x successfully\n
|*3*| `%package` | `%command` installed successfully (package `%package`)\n
|*4*| `%path` | Error: `%command (`%path`) is not executable and chmod +x failed\n
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
                        <li>if omitted or an empty string, nothing is written on <code>stdout</code></li>
                        <li><em>status</em> or <em>$?</em>: status code</li>
                        <li><em>error_message</em> or <em>err_msg</em> or <em>stderr</em>: <code>mkdir</code> call <code>stderr</code> output</li>
                        <li><em>verbose</em>: status specific message, see explanations above</li>
                </ul>
        </td></tr>
        <tr><td><b>Pipes</b><td align="center"><code>stdout</code></td><td></td></tr>
        <tr><td rowspan="6"><b>Status</b></td>
        <tr>    <td align="center"><em>1</em></td><td><code>$1</code> already installed</td></tr>
        <tr>    <td align="center"><em>2</em></td><td>successfully applied <code>chmod +x</code> to <code>$1</code></td></tr>
        <tr>    <td align="center"><em>3</em></td><td><code>$1</code> installed successfully</td></tr>
        <tr>    <td align="center"><em>4</em></td><td><code>$1</code> not executable and <code>chmod +x</code> attempt failed</td></tr>
        <tr>    <td align="center"><em>5</em></td><td><code>$1</code> installation failed</td></tr>
        <tr>    <td align="center"><em>6</em></td><td><code>$1</code> not installed and no package manager found</td></tr>
        <tr>    <td align="center"><em>7</em></td><td><code>$1</code> not installed and no package found</td></tr>
        <tr>    <td align="center"><em>8</em></td><td>found <code>$1</code> in a $PATH folder but was unable to determine the actual path (usually broken symlinks)</td><$
        <tr>    <td align="center"><em>9</em></td><td>incoherence: everything seems fine (found $1 in a path folder, it's executable) but <code>which</code> didn't find
                it</td></tr>
        <tr>    <td align="center"><em>10</em></td><td><code>$1</code> is empty</td></tr>
</table>

### handle_dependencies()

