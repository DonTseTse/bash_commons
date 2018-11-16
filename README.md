# bash_commons
Collection of bash functions for common tasks

# Snippets

Script directory resolution (f.ex. in an installer before `bash_commons` are available)
```bash
# This snippet refuses file symlinks (folders are OK) and sets script_folder to the directory the script lies in
if [ -h "${BASH_SOURCE[0]}" ]; then echo "Please call ... directly. The call through a symlink gives the wrong working directory. Aborting..."; exit 1; fi
script_folder="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
```
**Important**: this code has to run before files are sourced, subshells are launched etc. because such operations affect `$BASH_SOURCE` (`get_script_path()` 
               from [filesystem.sh](filesystem.sh) is able to cope with that and file symlinks)
