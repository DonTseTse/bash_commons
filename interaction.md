Documentation for the functions in [interaction.sh](interaction.sh). A general overview is given in [the project documentation](README.md#interaction).

If the pipes are not documented, the default is:
- `stdin`: piped input ignored
- `stdout`: empty

Parameters enclosed in brackets [ ] are optional. 

### read_and_validate()
Combined `read` and regex check.

Important `read` flags:
- `-n <nb_chars>` : `read` stops after `nb_chars`, which gives a "auto-return" UX
- `s` : `read` hides the user input
<table>
        <tr><td rowspan="2"><b>Param.</b></td>
		<td align="center"><code>$1</code></td><td width="90%">validation regex (if matched it leads to return status <em>0</em>)</td></tr>
	<tr>	<td align="center">[<code>$2</code>]</td><td>read flags, defaults to an empty string</td></tr>
        <tr><td rowspan="2"><b>Pipes</b></td>
		<td align="center"><code>stdin</code></td><td>piped input ignored; used via <code>read</code></td></tr>
	<tr>	<td align="center"><code>stdout</code></td><td>the user input</td></tr>
        <tr><td rowspan="2"><b>Status</b></td>
		<td align="center"><em>0</em></td><td>if the user entered a <code>$1</code> match</td></tr>
	<tr>	<td align="center"><em>1</em></td><td>of the user input doesn't match <code>$1</code></td></tr>
</table>


### get_user_confirmation()
Yes/no type questions. Blocks waiting for user input, returns as soon as one character is entered. 

<table>
        <tr><td><b>Param.</b></td><td align="center">[<code>$1</code>]</td><td width="90%">confirmation character, defaults to <em>y</em></td></tr>
        <tr><td rowspan="2"><b>Pipes</b></td>
                <td align="center"><code>stdin</code></td><td>piped input ignored; used via <a href="#read_and_validate">read_and_validate()</a></td></tr>
        <tr>    <td align="center"><code>stdout</code></td><td>a newline control sequence to reset the cursor which stands just after the user input</td></tr>
        <tr><td rowspan="2"><b>Status</b></td>
                <td align="center"><em>0</em></td><td>if the user enters <code>$1</code></td></tr>
        <tr>    <td align="center"><em>1</em></td><td>if the user enters something else</td></tr>
</table>


### get_user_choice()
The function behaves as if it ignores input as long as it doesn't match the regex `$1`. It may hence be used as "option selector". As soon as the input
matches `$1` the function returns with status *0* and provides the selected option on `stdout`. 

The way it works is that it uses `read`'s `-s` flag to keep the entered input hidden; if the input doesn't match `$1`, 
<a href="#read_and_validate">read_and_validate()</a> returns *1*, the function loops and calls 
<a href="#read_and_validate">read_and_validate()</a> again 

Example: the user is offered 3 choices numbered 1-3 - `$1` should be *^[1-3]$*

<table>
        <tr><td><b>Param.</b></td><td align="center"><code>$1</code></td><td width="90%">"acceptation" regex</td></tr>
        <tr><td rowspan="2"><b>Pipes</b></td>
                <td align="center"><code>stdin</code></td><td>piped input ignored; used via <a href="#read_and_validate">read_and_validate()</a></td></tr>
        <tr>    <td align="center"><code>stdout</code></td><td>the selection option</td></tr>
        <tr><td><b>Status</b></td><td align="center"><em>0</em></td><td></td></tr>
</table>

