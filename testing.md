Documentation for the functions from [testing.sh](testing.sh)

If the pipes are not documented, the default is:
- `stdin`: ignored
- `stdout`: empty

### initialize_test_session()

<table>
	<tr><td><b>Parametrization</b></td><td width="90%">- <code>$1</code> name of the test session</td></tr>
	<tr><td><b>Status</b></td><td>0</td></tr>
	<tr><td><b>Globals</b></td><td>
		- <code>$test_counter</code><br>
		- <code>$test_error_count</code><br>
		- <code>$test_session_name</code>
	</td></tr>
</table>

### configure_test()

<table>
        <tr><td><b>Parametrization</b></td><td width="90%">
		- <code>$1</code> expected return status<br>
                - <code>$2</code> expected stdout
        </td></tr>
        <tr><td><b>Status</b></td><td>0</td></tr>
        <tr><td><b>Globals</b></td><td>
		- <code>$expected_return</code><br>
                - <code>$expected_stdout</code>
        </td></tr>
</table>

### test()
Run a test with results captured and compared to $expected_<return|stdout>, see [configure_test()](#configure_test)

<table>
        <tr><td><b>Parametrization</b></td><td width="90%"><code>$1 ...</code> command to test (<code>$1</code> is the command)</td></tr>
	<tr><td><b>Pipes</b></td><td>
		- <code>stdin</code>: ignored<br>
		- <code>stdout</code>: test results printed by <a href="#check_test_results">check_test_results()</a>
	<tr><td><b>Status</b></td><td>0</td></tr>
	<tr><td><b>Globals</b></td><td>
		via <a href="#check_test_results">check_test_results()</a><br>
		- <code>$expected_return</code><br>
		- <code>$expected_stdout</code><br>
		- <code>$test_counter</code><br>
		- <code>$test_error_count</code>
	</td></tr>
</table>

### check_test_results()
Checks if `$2` corresponds to `$expected_status` and `$3` to `$expect_stdout` and prints result

<table>
	<tr><td><b>Parametrization</b></td><td width="90%">
		- <code>$1</code> command, as a properly quoted string<br>
		- <code>$2</code> command return status<br>
		- <code>$3</code> command stdout
	</td></tr>
	<tr><td><b>Pipes</b></td><td>
		- <code>stdin</code>: ignored<br>
		- <code>stdout</code>: test result
	<tr><td><b>Status</b></td><td>0</td></tr>
	<tr><td><b>Globals</b></td><td>
		- <code>$expected_return</code><br>
		- <code>$expected_stdout</code><br>
		- <code>$test_counter</code><br>
		- <code>$test_error_count</code>
	</td></tr>
</table>

### conclude_test_session()
Prints a summary and returns the status 0/success if all tests passed, 1 otherwise

<table>
        <tr><td><b>Parametrization</b></td><td width="90%"></td></tr>
        <tr><td><b>Pipes</b></td><td>
                - <code>stdin</code>: ignored<br>
                - <code>stdout</code>: test session summary
        <tr><td><b>Status</b></td><td>
		- 0 if all tests succeeded or if there were no tests<br>
		- 1 if at least one of the tests failed
	</td></tr>
        <tr><td><b>Globals</b></td><td>
                - <code>$test_counter</code><br>
                - <code>$test_error_count</code>
        </td></tr>
</table>


