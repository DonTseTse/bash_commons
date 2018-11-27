Documentation for the functions from [testing.sh](testing.sh)

If the pipes are not documented, the default is:
- stdin: ignored
- stdout: empty

### initialize_test_session()

<table>
	<tr><td><em>Parametrization</em></td><td>$1 name of the test session</td></tr>
	<tr><td><em>Pipes</em></td><td>-</td><tr>
	<tr><td><em>Status</em></td><td>0</td></tr>
	<tr><td><em>Globals</em></td><td><ul>
		<li>$test_counter</li>
		<li>$test_error_county</li>
		<li>$test_session_name</li>
	</ul></td></tr>
</table>

Parametrization:
- `$1` name of the test session

Status: 0

Globals: 
- `$test_counter`
- `$test_error_count`
- `$test_session_name`

### configure_test()

Parametrization:
- `$1` expected return status
- `$2` expected stdout

Status: 0

Globals: 
- `$expected_return`
- `$expected_stdout`

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


