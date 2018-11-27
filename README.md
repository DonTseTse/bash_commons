# bash_commons
Collection of bash functions for common tasks

# Function collections:
- (testing.sh)[testing.sh] | Documentation: (testing.md)[testing.md]
	- (initialize_test_session)[testing.md#initialize_test_session]
- (helpers.sh)[helpers.sh]

# Snippets

Simplified script directory resolution (f.ex. in an installer before `bash_commons` are available)
```bash
# Exit with error message on file symlinks, set $script_folder to the directory in which the script is located (folder symlinks resolved)
symlink_error_msg="Error: Please don't call ... through file symlinks, this confuses the script about its own location. Call it directly. Aborting..."
if [ -h "${BASH_SOURCE[0]}" ]; then echo "$symlink_error_msg"; exit 1; fi
script_folder="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
```
**Important**: this code has to run before files are sourced, subshells are launched etc. because such operations affect `$BASH_SOURCE` (`get_script_path()` 
               from [filesystem.sh](filesystem.sh) is able to cope with that and file symlinks)
