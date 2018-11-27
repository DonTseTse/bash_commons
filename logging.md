Documentation for the functions in [logging.sh](logging.sh).

If the pipes are not documented, the default is:
- `stdin`: ignored
- `stdout`: empty

### log()
Logging helper with support for prefix-aware multi-line output and independent stdout and file output handling

Important: always call this function and `launch_logging()` directly on global level and not through `$(...)`, otherwise the global 
variables don't work (a subshell receives a copy of the parent shell's variable set and has no access to the "original" ones)

<table>
        <tr><td><b>Parametrization</b></td><td width="90%">
		- <code>$1</code> message to log
		- <code>$2</code> <em>optional</em> log level - if omitted, defaults to 1
		- <code>$3</code> <em>optional</em> output restriction - if omitted, both output channels are used. "file" avoids stdout 
		write even if $stdout_logging is enabled. "stdout" disables file logging even is $log_filepath is set
	</td></tr>
        <tr><td><b>Pipes</b></td><td>
                - <code>stdin</code>: ignored<br>
                - <code>stdout</code>: depending on configuration, the message for the console. log() should never be called in a subshell                                                                        
        <tr><td><b>Status</b></td><td>0</td></tr>
        <tr><td><b>Globals</b></td><td>
		- <code>$logging_available</code> (<em>optional</em>, defaults to 1/enabled internally if omitted)<br>
		- <code>$stdout_log_level</code> (<em>optional</em>, if omitted, the system doesn't print on stdout)<br>
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
        <tr><td><b>Parametrization</b></td><td width="90%"><em>none</em></td></tr>
        <tr><td><b>Pipes</b></td><td>
                - <code>stdin</code>: ignored<br>
                - <code>stdout</code>: if stdout logging is enabled, the logs for stdout, empty otherwise                                                                        
        <tr><td><b>Status</b></td><td>0</td></tr>
        <tr><td><b>Globals</b></td><td>
		- <code>$logging_available</code><br>
		- <code>$logging_backlog</code>
        </td></tr>
</table>

### prepare_secret_for_logging()

<table>
        <tr><td><b>Parametrization</b></td><td width="90%">
		- <code>$1</code> secret<br>
		- <code>$2</code> amount of chars to show. If > 0, the amount is shown from the beginning of the secret, if < 0, from the end<br>
		- <code>$3</code> security factor - a decimal value between 0 and 1 which decides how much of the secret can be shown at most - overwrites
		  <code>$2</code> if necessary
	</td></tr>
        <tr><td><b>Pipes</b></td><td>
                - <code>stdin</code>: ignored<br>
                - <code>stdout</code>: the reduced variant of the secret suited for logging
        <tr><td><b>Status</b></td><td>
		- 0 in case of success<br>
		- 1 if <code>$1</code> is undefined or empty
	</td></tr>
</table>

