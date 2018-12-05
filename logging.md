Documentation for the functions in [logging.sh](logging.sh). A general overview is given in
[the project documentation](https://github.com/DonTseTse/bash_commons#logging).

## Module documentation
The logging module provides `stdout` and file logging at once, each with a individual pattern and log level. These levels follow a verbosity logic 
where a message with a lower level should be more important than one with a higher level. Through a configuration flag, the logger may be
put in a "delayed logging" mode where the messages go into a buffer a processing later on. That's useful f.ex. when application starts up and
the actual logging configuration is not yet fully determined. 

Since all these configurations have to persist between the [log()](#log) calls, the module relies on global variables:
- `$logging_available`: the "delayed logging" flag
	- if it's defined and set to *0*, [log()](#log) copies messages to `$logging_backlog`, the buffer
	- if it's undefined or set to *1*, [log()](#log) processes the messages immediately
- `$stdout_log_level`: defines the stdout channel verbosity filter threshold. Messages with a level above the threshold are discarded. If the variable 
   is undefined, not numeric or *0*, nothing is written
- `$stdout_log_pattern`: pattern of the message written on `stdout`, where a single `%s` represents the message. If the variable is undefined, *%s* is 
   used (i.e. "just the message")
- `$log_filepath`: absolute path of the logfile. If the variable is undefined or empty, no file logging occurs
- `$log_level`: defines the file logging channel verbosity filter threshold. Messages with a level above the threshold are discarded. If the variable is 
   undefined, not numeric or *0*, no file logging occurs
- `$log_pattern`: pattern of the message written to the logfile, where a single `%s` represents the message. If the variable is undefined, *%s* is used 
   (i.e. "just the message")
- `$logging_backlog` array: buffer for messages when `$logging_available` is set to *0*. Handled internally between [log()](#log) and 
  [launch_logging()](#launch_logging)

Example: [sendmail2mailgun](https://github.com/DonTseTse/sendmail2mailgun/blob/master/emulator.sh#L265) uses all module features

## Function documentation
If the pipes are not documented, the default is:
- `stdin`: ignored
- `stdout`: empty

Parameters enclosed in brackets [ ] are optional.

### log()
Central piece of the logging module. Supports prefix-aware multi-line output and independent `stdout` and file output handling. Copies messages
to `$logging_backlog` as long as `$logging_available` is set to *0*. See the [module documentation](#module-documentation) for details.

**Important**: always call this function and `launch_logging()` directly on global level and not through `$(...)`, otherwise the global 
variables don't work (a subshell receives a copy of the parent shell's variable set and has no access to the "original" ones).
<table>
        <tr><td rowspan="3"><b>Param.</b></td>
                <td align="center"><code>$1</code></td><td width="90%">message to log</td></tr>
        <tr>    <td align="center">[<code>$2</code>]</td><td>log level - if omitted, it defaults to <em>1</em></td></tr>
        <tr>    <td align="center">[<code>$3</code>]</td><td>output channel restriction:
			<ul>
				<li>if omitted, both stdout and file logging are addressed</li>
				<li><em>file</em>: file logging only</li>
				<li><em>stdout</em>: stdout logging only</li>
			</ul>
		This configuration selects the addressed output channel(s) but it does not overwrite the configurations which define whether logging 
		actually occurs (see <a href="#module-documentation">module documentation</a>) 
	</td></tr>
        <tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>depending on the configuration, the message for the console</td></tr>
        <tr><td><b>Status</b></td><td align="center"><em>0</em></td><td></td></tr>
        <tr><td><b>Globals</b></td><td align="center"></td><td>all globals listed in the <a href="#module-documentation">module documentation</a></td></tr>	
</table>

### launch_logging()
Processes the `$logging_backlog` by calling [log()](#log) for each entry and clears it. Sets `$logging_available` to *1*.
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
from the beginning. The message pattern is *[Secret - begins with ...]* respectively *[Secret - ends with ...]*. Examples:
```
prepare_secret_for_logging "longer_secret" 5 "0.5"
```
writes *[Secret - begins with 'longe']* on `stdout`. In this case the security factor doesn't intervene because 0.5 * 13 = 6.5, `$2` is lower. The default
security factor is *0.25*. Example with a negative `$2`:
```
test prepare_secret_for_logging "longer_secret" -5
```
writes *[Secret - ends with 'ret']* on `stdout`. It contains only 3 instead of the *5* characters requested because the default security factor sets the  
limit to 13*0.25=3.25.
<table>
        <tr><td rowspan="3"><b>Param.</b></td>
                <td align="center"><code>$1</code></td><td width="90%">secret</td></tr>
        <tr>    <td align="center"><code>[$2]</code></td><td>amount of chars to show. If it's positive, the amount is shown from the beginning of the secret, if it's 
		negative, from the end. If it's omitted, the first fourth of the secret will be shown.</td></tr>
        <tr>    <td align="center">[<code>$3</code>]</td><td>security factor: a value between 0 and 1 which configures how much of the secret can be shown at most.
                Defaults to <em>0.25</em>, which means that by default at most one fourth of the secret's characters will be shown. It's enforced as limit for the amount
                of characters which can be requested via <code>$2</code></td></tr>
        <tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>if status is <em>0</em>, a representation of the secret suited for logging, empty otherwise</td></tr>
        <tr><td rowspan="2"><b>Status</b></td>
                <td align="center"><em>0</em></td><td>success, the formatted secret was written on `stdout`</td></tr>
        <tr>    <td align="center"><em>1</em></td><td><code>$1</code> undefined or empty</td></tr>
</table>
