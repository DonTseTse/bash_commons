Documentation for the functions in [logging.sh](logging.sh).

If the pipes are not documented, the default is:
- `stdin`: ignored
- `stdout`: empty

### log()
Logging helper with support for prefix-aware multi-line output and independent `stdout` and file output handling

**Important**: always call this function and `launch_logging()` directly on global level and not through `$(...)`, otherwise the global 
variables don't work (a subshell receives a copy of the parent shell's variable set and has no access to the "original" ones). To suppress
undesired `stdout` output set `stdout_log_level` to 0.

<table>
        <tr><td><b>Parametrization</b></td><td width="90%">
		- <code>$1</code> message to log<br>
		- <code>$2</code> <em>optional</em> log level - if omitted, defaults to 1<br>
		- <code>$3</code> <em>optional</em> output restriction - if omitted, both output channels are addressed. Value can be <code>file</code>
                  to avoid <code>stdout</code> write or <code>stdout</code> to avoid file logging. This configuration only selects the addressed output
                  channel(s), it does not overwrite the configurations which define whether logging actually occurs (the logging levels of the channel(s) 
                  and the message and for file logging, whether a filepath is set)
	</td></tr>
        <tr><td><b>Pipes</b></td><td>
                - <code>stdin</code>: ignored<br>
                - <code>stdout</code>: depending on configuration, the message for the console
	</td></tr>
        <tr><td><b>Status</b></td><td>0</td></tr>
        <tr><td><b>Globals</b></td><td>
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
	<tr><td rowspan="2"><b>Pipes</b></td>
		<td align="center"><code>stdin</code></td><td>piped input ignored</td></tr>
	<tr>    <td align="center"><code>stdout</code></td><td>the logs for <code>stdout</code>, empty otherwise</td></tr>
	<tr><td><b>Status</b></td><td align="center"><em>0</em></td><td>success</td></tr>
</table>

<table>
        <tr><td><b>Parametrization</b></td><td width="90%"><em>none</em></td></tr>
        <tr><td><b>Pipes</b></td><td>
                - <code>stdin</code>: ignored<br>
                - <code>stdout</code>: if stdout logging is enabled, the logs for stdout, empty otherwise                                                                        
	</td></tr>
        <tr><td><b>Status</b></td><td>0</td></tr>
        <tr><td><b>Globals</b></td><td>
		- <code>$logging_available</code><br>
		- <code>$logging_backlog</code>
        </td></tr>
</table>

### prepare_secret_for_logging()
Formats a secret for logging.

<table>
        <tr><td rowspan="2"><b>Param.</b></td>
                <td align="center"><code>$1</code></td><td width="90%">secret</td></tr>
        <tr>    <td align="center"><code>$2</code></td><td>amount of chars to show. If it's positive, the amount is shown from the beginning of the secret, if it's 
		negative, from the end</td></tr>
        <tr>    <td align="center"><code>$3</code></td><td>security factor - a decimal value between 0 and 1 which decides how much of the secret can be shown at most 
		- overwrites <code>$2</code> if necessary</td></tr>
        <tr><td rowspan="2"><b>Pipes</b></td>
                <td align="center"><code>stdin</code></td><td>piped input ignored</td></tr>
        <tr>    <td align="center"><code>stdout</code></td><td>the formatted secret suited for logging</td></tr>
        <tr><td rowspan="2"><b>Status</b></td>
                <td align="center"><em>0</em></td><td>success</td></tr>
        <tr>    <td align="center"><em>1</em></td><td><code>$1</code> undefined or empty</td></tr>
</table>
