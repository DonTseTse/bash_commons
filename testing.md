Documentation for the functions in [testing.sh](testing.sh).

If the pipes are not documented, the default is:
- `stdin`: ignored
- `stdout`: empty

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
Sets up the expected result for a test
<table>
        <tr><td rowspan="2"><b>Param.</b></td>
                <td align="center"><code>$1</code></td><td width="90%">expected return status</td></tr>
        <tr>    <td align="center">[<code>$2</code>]</td><td>expected <code>stdout</code></td></tr>
        <tr><td><b>Status</b></td><td align="center"><em>0</em></td><td></td></tr>
	<tr><td><b>Globals</b></td><td colspan="2">
		<ul>
			<li><code>$expected_return</code></li>
			<li><code>$expected_stdout</code></li>
		</ul>
        </td></tr>
</table>

### test()
Run a test with results captured and compared to <code>$expected_<return|stdout></code>, see [configure_test()](#configure_test)
<table>
        <tr><td><b>Param.</b></td><td align="center"><code>$1 ...</code></td><td width="90%">command to test (<code>$1</code> is the command)</td></tr>
        <tr><td rowspan="2"><b>Pipes</b></td>
                <td align="center"><code>stdin</code></td><td>piped input ignored</td></tr>
        <tr>    <td align="center"><code>stdout</code></td><td>test results printed by <a href="#check_test_results">check_test_results()</a></td></tr>
	<tr><td><b>Status</b></td><td align="center"><em>0</em></td><td></td></tr>
        <tr><td><b>Globals</b></td><td colspan="2">
		via <a href="#check_test_results">check_test_results()</a><br>
                <ul>
			<li><code>$expected_return</code></li>
			<li><code>$expected_stdout</code></li>
			<li><code>$test_counter</code></li>
			<li><code>$test_error_count</code></li>
                </ul>
        </td></tr>
</table>

### check_test_results()
Checks if `$2` corresponds to `$expected_status` and `$3` to `$expect_stdout` and prints result
<table>
	<tr><td rowspan="2"><b>Param.</b></td>
		<td align="center"><code>$1</code></td><td width="90%">command, as a properly quoted string</td></tr>
	<tr>    <td align="center"><code>$2</code></td><td>command return status</td></tr>
	<tr>    <td align="center"><code>$3</code></td><td>command <code>stdout</code></td></tr>
        <tr><td rowspan="2"><b>Pipes</b></td>
                <td align="center"><code>stdin</code></td><td>piped input ignored</td></tr>
        <tr>    <td align="center"><code>stdout</code></td><td>test result message</a></td></tr>
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
        <tr><td rowspan="2"><b>Pipes</b></td>
                <td align="center"><code>stdin</code></td><td>piped input ignored</td></tr>
        <tr>    <td align="center"><code>stdout</code></td><td>test session summary</td></tr>
        <tr><td rowspan="2"><b>Status</b></td>
		<td align="center"><em>0</em></td><td>no test errors found, success</td></tr>
	<tr>	<td align="center"><em>1</em></td><td>at least one of the tests failed</td></tr>
        <tr><td><b>Globals</b></td><td colspan="2">
                <ul>
                        <li><code>$test_counter</code></li>
                        <li><code>$test_error_count</code></li>
                </ul>
        </td></tr>
</table>

