Documentation for the functions in [logging.sh](logging.sh). A general overview is given in
[the project documentation](https://github.com/DonTseTse/bash_commons#logging).

If the pipes are not documented, the default is:
- `stdin`: ignored
- `stdout`: empty

Parameters enclosed in brackets [ ] are optional.

## Function documentation
### log()
Logging helper with support for prefix-aware multi-line output and independent `stdout` and file output handling

**Important**: always call this function and `launch_logging()` directly on global level and not through `$(...)`, otherwise the global 
variables don't work (a subshell receives a copy of the parent shell's variable set and has no access to the "original" ones). To suppress
undesired `stdout` output set `stdout_log_level` to 0.
<table>
        <tr><td rowspan="3"><b>Param.</b></td>
                <td align="center"><code>$1</code></td><td width="90%">message to log</td></tr>
        <tr>    <td align="center">[<code>$2</code>]</td><td>log level - if omitted, it defaults to <em>1</em></td></tr>
        <tr>    <td align="center">[<code>$3</code>]</td><td>output channel restriction - if omitted, both `stdout` and file
		channels are addressed. Value can be <em>file</em> to avoid <code>stdout</code> write or <em>stdout</em> to avoid file logging. 
		This configuration only selects the addressed output channel(s), it does not overwrite the configurations which define whether logging 
		actually occurs (the logging levels of the channel(s) and the message and for file logging, whether a filepath is set)
	</td></tr>
        <tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>depending on the configuration, the message for the console</td></tr>
        <tr><td><b>Status</b></td><td align="center"><em>0</em></td><td></td></tr>
        <tr><td><b>Globals</b></td><td align="center"></td><td>
		- <code>$logging_available</code> (<em>optional</em>, defaults to 1/enabled internally if omitted)<br>
                - <code>$stdout_log_level</code> (<em>optional</em>, if omitted, the system doesn't print on <code>stdout</code>)<br>
                - <code>$stdout_log_pattern</code> (<em>optional</em>, defaults to <code>%s</code> ("just" the message))<br>
                - <code>$log_filepath</code> (<em>optional</em>, if empty, no file logging occurs)<br>
                - <code>$log_level</code> (<em>optional</em>, if it's not a numeric value, file logging is disabled)<br>
                - <code>$log_pattern</code> (<em>optional</em>, defaults to <code>%s</code> ("just" the message"))<br>
                - <code>$logging_backlog</code> array (<em>optional</em>, created internally)

	</td></tr>	
</table>

### launch_logging()
Processes the logging backlog and clears it
<table>
	<tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td width="90%">if stdout logging is enabled, the logs for <code>stdout</code>, 
	empty otherwise</td></tr>
	<tr><td><b>Status</b></td><td align="center"><em>0</em></td><td></td></tr>
	<tr><td><b>Globals</b></td><td></td><td>
		- <code>$logging_available</code><br>
                - <code>$logging_backlog</code>
	</td></tr>
</table>

### prepare_secret_for_logging()
Formats a secret for logging. The amount of characters can be configured through `$2` and the security factor `$3` (a value between 0 and 1) which 
guarantees that the amount shown is at most `<secret length> * <factor>`. If `$2` is negative, the characters are shown from the end of the secret, if it's positive, 
from the beginning. The message pattern is *[Secret - begins with <chars>]* respectively *[Secret - ends with <chars>]*. Examples:
```
prepare_secret_for_logging "longer_secret" 5 "0.5"
```
returns *[Secret - begins with 'longe']* (the secret has 13 characters => security factor: 0.5 * 13 = 6.5 => `$2` is lower => 5 chars shown). The default
security factor is *0.25*. 

Example with a negative `$2`:
```
test prepare_secret_for_logging "longer_secret" -2
```
returns *[Secret - ends with 'et']* (0.25 * 12 = 3.25 => abs(`$2`) is lower => secret's last 2 characters shown).
<table>
        <tr><td rowspan="3"><b>Param.</b></td>
                <td align="center"><code>$1</code></td><td width="90%">secret</td></tr>
        <tr>    <td align="center"><code>$2</code></td><td>amount of chars to show. If it's positive, the amount is shown from the beginning of the secret, if it's 
		negative, from the end</td></tr>
        <tr>    <td align="center">[<code>$3</code>]</td><td>security factor - a decimal value between 0 and 1 which decides how much of the secret can be shown at most 
		- overwrites the value set via <code>$2</code> if necessary. Defaults to *0.25*</td></tr>
        <tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>the formatted secret suited for logging</td></tr>
        <tr><td rowspan="2"><b>Status</b></td>
                <td align="center"><em>0</em></td><td>success</td></tr>
        <tr>    <td align="center"><em>1</em></td><td><code>$1</code> undefined or empty</td></tr>
</table>
