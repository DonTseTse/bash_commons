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
		- <code>$test_error_county</code><br>
		- <code>$test_session_name</code>
	</td></tr>
</table>

### configure_test()

<table style="width=100%">
        <tr><td><em>Parametrization</em></td><td width="90%">
                <code>$1</code> expected return status<br>
		<code>$2</code> expected stdout
        </td></tr>
        <tr><td><em>Status</em></td><td>0</td></tr>
        <tr><td><em>Globals</em></td><td><ul>
                <li><code>$expected_return</code></li>
                <li><code>$expected_stdout</code></li>
        </ul></td></tr>
</table>

### test()
Run a test with results captured and compared to $expected_<return|stdout>, see [configure_test()](#configure_test)

Parametrization:
- `$1 ...` command to test (`$1` is the command)

Pipes: 
- stdin: ignored
- stdout: test results printed by check_test_results()

Status: 0

Globals: via [check_test_results()](#check_test_results)
- `$expected_return` 
- `$expected_stdout`
- `$test_counter`
- `$test_error_count`  

### check_test_results()
Checks if `$2` corresponds to `$expected_status` and `$3` to `$expect_stdout` and prints result

Parametrization:
- `$1` command, as a properly quoted string
- `$2` command return status
- `$3` command stdout

Pipes: 
- stdin: ignored
- stdout: test result

Status: 0

Globals: 
- `$expected_return`
- `$expected_stdout`
- `$test_counter`

### conclude_test_session()
Prints a summary and returns the status 0/success if all tests passed, 1 otherwise

Pipes: 
- stdin: ignored
- stdout: test session summary

Status: 
- 0 if all test succeeded or if there were no tests
- 1 if at least one of the tests failed

Globals: 
- `$test_counter` 
- `$test_error_count`


