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
<table>
        <tr><td rowspan="3"><b>Param.</b></td>
                <td align="center"><code>$1</code></td><td width="90%">repository URL</td></tr>
        <tr>    <td align="center"><code>$2</code></td><td>path to clone to</td></tr>
        <tr>    <td align="center">[<code>$3</code>]</td><td>"repository" exists action: value can be *update*</td></tr>
        <tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>URL of remote <code>$2</code> of the repository at <code>$1</code></td></tr>
        <tr><td rowspan="3"><b>Status</b></td>
                <td align="center"><em>0</em></td><td>git clone or git fetch operation suceeded</td></tr>
        <tr>    <td align="center"><em>1</em></td><td>git operation failed</td></tr>
        <tr>    <td align="center"><em>2</em></td><td>error detected by get_git_repository_remote_url</td></tr>
</table>
