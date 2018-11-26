Documentation for the functions from [testing.sh](testing.sh)

### initialize_test_session()

Parametrization:
- `$1` name of the test session

Pipes: 
- stdin: ignored
- stdout: empty

Status: 0

Globals: 
- `$test_counter`
- `$test_error_count`
- `$test_session_name`

### configure_test()

Parametrization:
- `$1` expected return status
- `$2` expected stdout

Pipes: 
- stdin: ignored
- stdout: empty

Status: 0

Globals: 
- `$expected_return`
- `$expected_stdout`
