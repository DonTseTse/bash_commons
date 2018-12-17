Documentation for the functions in [git_handling.sh](git_handling.sh). A general overview is given in [the project documentation](README.md#git-handling).

## Function documentation
If the pipes are not documented, the default is:
- `stdin`: piped input ignored
- `stdout`: empty

Parameters enclosed in brackets [ ] are optional.

### execute_git_command_in_repository()

<table>
        <tr><td rowspan="2"><b>Param.</b></td>
                <td align="center"><code>$1</code></td><td width="90%">repository path</td></tr>
        <tr>    <td align="center"><code>$2</code></td><td>git command (f.ex. <em>clone</em>, <em>fetch</em>, etc.)</td></tr>
        <tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td><code>stdout</code> output of the executed command</td></tr>
        <tr><td><b>Status</b></td><td colspan="2">the return status of the 
		<a href="helpers.md#execute_working_directory_dependant_command">helper collection's execute_working_directory_dependant_command()</a>
	</td></tr>
</table>

### get_git_repository_remote_url()
Inspired by this [SO answer](https://stackoverflow.com/questions/4089430/how-can-i-determine-the-url-that-a-local-git-repository-was-originally-cloned-fr)

<table>
        <tr><td rowspan="2"><b>Param.</b></td>
                <td align="center"><code>$1</code></td><td width="90%">repository path</td></tr>
        <tr>    <td align="center"><code>$2</code></td><td>name of the remote - defaults to <em>origin</em> (<code>git</code>'s default) if omitted</td></tr>
        <tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>URL of remote <code>$2</code> of the repository at <code>$1</code></td></tr>
	<tr><td rowspan="7"><b>Status</b></td>
                <td align="center"><em>0</em></td><td>success, URL written on <code>stdout</code></td></tr>
        <tr>    <td align="center"><em>1</em></td><td>path <code>$1</code> doesn't exist</td></tr>
        <tr>    <td align="center"><em>2</em></td><td>path <code>$1</code> is not a folder</td></tr>	
        <tr>    <td align="center"><em>3</em></td><td>no read permission on path <code>$1</code></td></tr>	
        <tr>    <td align="center"><em>4</em></td><td>folder <code>$1</code> doesn't seem to be a git repository (no ./.git folder inside)</td></tr>	
        <tr>    <td align="center"><em>5</em></td><td><code>git config</code> call failed</td></tr>	
        <tr>    <td align="center"><em>6</em></td><td><code>$1</code> is empty</td></tr>	
</table>

### get_git_repository()
Default messages:

| Status | Template
|:------:| --------
|*0*| `$1` cloned to `$2`\n
|*1*| Git clone error: could not clone `$1` to `$2`\n
|*2*| `$1` already cloned to `$2` - nothing to do\n
|*3*| `$2` exists and it's not a folder\n
|*4*| `$2` exists but it's not readable\n
|*5*| `$2` exist but it doesn't seem to be a git repository (no .git folder inside)\n
|*6*| `$2` exists but the attempt to run git config to get the remote URL failed\n
|*7*| `$2` exists and it's a git repository but the remote URL is not $1\n
|*8*| Repository URL is empty\n
|*9*| Repository path empty\n

<table>
        <tr><td rowspan="3"><b>Param.</b></td>
                <td align="center"><code>$1</code></td><td width="90%">repository URL</td></tr>
        <tr>    <td align="center"><code>$2</code></td><td>path to clone to</td></tr>
        <tr>    <td align="center">[<code>$3</code>]</td><td><code>stdout</code> configuration: 
		<ul>
			<li>if <code>$3</code> is omitted or empty, nothing is written on <code>stdout</code></li>
			<li>if <code>$3</code> is set to a non-empty value, the system tries to find a array variable with that name. If such a variable
                        is defined it tries to load the element which is at the index corresponding to the return status. If either the array or the array element 
			is not defined, it uses the default messages given above</li>
		</ul>
	</td></tr>
        <tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>if <code>$3</code> is non-empty, the message</td></tr>
        <tr><td rowspan="10"><b>Status</b></td>
                <td align="center"><em>0</em></td><td>git clone suceeded</td></tr>
        <tr>    <td align="center"><em>1</em></td><td>git clone failed</td></tr>
        <tr>    <td align="center"><em>2</em></td><td><code>$1</code> already cloned to <code>$2</code></td></tr>
        <tr>    <td align="center"><em>3</em></td><td><code>$2</code> exists but it's not a folder</td></tr>
        <tr>    <td align="center"><em>4</em></td><td><code>$2</code> is not readable</td></tr>
        <tr>    <td align="center"><em>5</em></td><td><code>$2</code> exists but it doesn't seem to be a repository</td></tr>
        <tr>    <td align="center"><em>6</em></td><td><code>$2</code> seems to be a repository but the attempt to run <code>git config</code> failed</td></tr>
        <tr>    <td align="center"><em>7</em></td><td><code>$2</code> exists but it has another URL than $1</td></tr>
        <tr>    <td align="center"><em>8</em></td><td><code>$1</code> emtpy</td></tr>
        <tr>    <td align="center"><em>9</em></td><td><code>$2</code> empty</td></tr>
</table>
