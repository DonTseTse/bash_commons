Documentation for the functions in [testing.sh](testing.sh). A general overview is given in
[the project documentation](https://github.com/DonTseTse/bash_commons#testing).

## Module documentation
The module maintains a range of global variables to keep track of a test session in between function calls:
- `$test_counter` and `$test_error_count` are initialized to *0* by [initialize_test_session()](#initialize_test_session)
  and incremented for every test respectively every failed test by [check_test_results()](check_test_results#), which
  uses them inside its test result messages as well
- the expected results of a test are kept in `$expected_return` and `$expected_stdout`. They are set via 
  [configure_test()](#configure_test) and compared to the actual test outcome in 
  [check_test_results()](#check_test_results)
- `$test_session_name` stores the session name; it's used in the introduction and conclusion messages

## Function documentation
If the pipes are not documented, the default is:
- `stdin`: ignored
- `stdout`: empty

Parameters enclosed in brackets [ ] are optional.

### initialize_test_session()
Sets up the internals for a test session.
<table>
        <tr><td><b>Param.</b></td><td align="center"><code>$1</code></td><td width="90%">name of the session</td></tr>
        <tr><td><b>Status</b></td><td align="center"><em>0</em></td><td></td></tr>
        <tr><td><b>Globals</b></td><td colspan="2">
		<ul>
			<li><code>$test_counter</code></li>
			<li><code>$test_error_count</code></li>
			<li><code>$test_session_name</code></li>
		</ul>
	</td></tr>
</table>

### configure_test()
Sets up the expected test result values
<table>
        <tr><td rowspan="2"><b>Param.</b></td>
                <td align="center"><code>$1</code></td><td width="90%">expected return status</td></tr>
        <tr>    <td align="center">[<code>$2</code>]</td><td>expected <code>stdout</code>, default to n empty string if omitted</td></tr>
        <tr><td><b>Status</b></td><td align="center"><em>0</em></td><td></td></tr>
	<tr><td><b>Globals</b></td><td colspan="2">
		<ul>
			<li><code>$expected_return</code></li>
			<li><code>$expected_stdout</code></li>
		</ul>
        </td></tr>
</table>

### test()
Checks that the specified command exists, executes it using <a href="helpers.md#capture">capture()</a> and calls [check_test_results()](#check_test_results) with 
the captured status return and `stdout` output. 
<table>
        <tr><td><b>Param.</b></td><td align="center"><code>$1 ...</code></td><td width="90%">command to test (<code>$1</code> is the command)</td></tr>
        <tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>test results messages from <a href="#check_test_results">check_test_results()</a></td></tr>
	<tr><td><b>Status</b></td><td align="center"><em>0</em></td><td></td></tr>
        <tr><td><b>Globals</b></td><td colspan="2">see <a href="#check_test_results">check_test_results()</a></td></tr>
</table>

### check_test_results()
Checks if `$2` corresponds to `$expected_status` and `$3` to `$expect_stdout` and writes a message on `stdout`. Increments 
`$test_counter` and, if the check failed, `$test_error_count`. 

<table>
	<tr><td rowspan="3"><b>Param.</b></td>
		<td align="center"><code>$1</code></td><td width="90%">command, as a properly quoted string</td></tr>
	<tr>    <td align="center"><code>$2</code></td><td>command return status</td></tr>
	<tr>    <td align="center"><code>$3</code></td><td>command <code>stdout</code></td></tr>
        <tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td>test result message</a></td></tr>
        <tr><td><b>Status</b></td><td align="center"><em>0</em></td><td></td></tr>
        <tr><td><b>Globals</b></td><td colspan="2">
                <ul>
                        <li><code>$expected_return</code></li>
                        <li><code>$expected_stdout</code></li>
                        <li><code>$test_counter</code></li>
                        <li><code>$test_error_count</code></li>
                </ul>
        </td></tr>
</table>

### conclude_test_session()
Prints a summary and returns a session success status
<table>
        <tr><td><b>Pipes</b></td><td align="center"><code>stdout</code></td><td width="90%">test session summary</td></tr>
        <tr><td rowspan="2"><b>Status</b></td>
		<td align="center"><em>0</em></td><td>no test errors found, success</td></tr>
	<tr>	<td align="center"><em>1</em></td><td>at least one of the tests failed</td></tr>
        <tr><td><b>Globals</b></td><td colspan="2">
                <ul>
                        <li><code>$test_counter</code></li>
                        <li><code>$test_error_count</code></li>
			<li><code>$test_session_name</code></li>
                </ul>
        </td></tr>
</table>

