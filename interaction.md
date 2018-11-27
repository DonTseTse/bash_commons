Documentation for the functions in [interaction.sh](interaction.sh).

If the pipes are not documented, the default is:
- `stdin`: ignored
- `stdout`: empty

### read_and_validate()

Important `read` flags:
- `-n <nb_chars>` : `read` stops after `nb_chars`, which gives a "auto-return" UX. Suited for a single char, for longer entries, a explicit [Enter] is usually better

<table>
        <tr><td><b>Parametrization</b></td><td width="90%">
		- <code>$1</code> validation regex (if matched it leads to return status 0)<br>
		- <code>$2</code> <em>optional</em> read flags
        </td></tr>
        <tr><td><b>Pipes</b></td><td>
                - <code>stdin</code>: input ignored; used via <code>read</code><br>
                - <code>stdout</code>: the user input
	</td></tr>
        <tr><td><b>Status</b></td><td>
		- 0 if the user entered a <code>$1</code> match<br>
		- 1 otherwise
	</td></tr>
</table>


### get_user_confirmation()

<table>
        <tr><td><b>Parametrization</b></td><td width="90%">
		- <code>$1</code> <em>optional</em> confirmation character, defaults to 'y'
        </td></tr>
        <tr><td><b>Pipes</b></td><td>
                - <code>stdin</code>: input ignored; used via <a href="#read_and_validate">read_and_validate()</a><br>
                - <code>stdout</code>: prints a newline because cursor stands just after the user input
        </td></tr>
        <tr><td><b>Status</b></td><td>
                - 0 if the user enters <code>$1</code> (or 'y' if <code>$1</code> omitted)<br>
		- 1 if the user enters something else
        </td></tr>
</table>


### get_user_choice()
The function behaves as if it ignores input as long as it doesn't match the regex `$1`. This makes it suitable as "option selector".
The way it works is that it uses `read`'s `-s` flag to keep the entered input hidden => if the input doesn't match `$1`, <a href="#read_and_validate">read_and_validate</a> 
returns a status code $? != 0, the function loops and `read`s again 

Example: the user is offered 3 choices numbered 1-3, the regex is `^[1-3]$`.

<table>
        <tr><td><b>Parametrization</b></td><td width="90%">
		- <code>$1</code> "acceptation" regex
        </td></tr>
        <tr><td><b>Pipes</b></td><td>
                - <code>stdin</code>: input ignored; used via <a href="#read_and_validate">read_and_validate()</a><br>
                - <code>stdout</code>: the selected option
        </td></tr>
        <tr><td><b>Status</b></td><td>0</td></tr>
</table>

### conditional_exit()
Example:
```
important_fct_call     # an important function which can fail
conditional_exit $? "Damn! it failed. Aborting..." 20
````
If `important_fct_call` returns with a status code other than 0, the script prints the "Damn! ..." message and exits with status code 20

<table>
        <tr><td><b>Parametrization</b></td><td width="90%">
		- <code>$1</code> condition, if it's different than 0, the exit is triggered<br>
		- <code>$2</code> <em>optional</em> exit message, defaults to a empty string if omitted (it still prints a newline to reset 
		  the terminal)<br>
		- <code>$3</code> <em>optional</em> exit code, defaults to 1
        </td></tr>
        <tr><td><b>Pipes</b></td><td>
                - <code>stdin</code>: ignored<br>
                - <code>stdout</code>: if the exist is triggered, <code>$2</code> followed by a newline
        </td></tr>
        <tr><td><b>Status</b></td><td>0 if the exit is not triggered</td></tr>
	<tr><td><b>Exit</b></td><td><code>$3</code>, defaults to 1</td></tr>
</table>

