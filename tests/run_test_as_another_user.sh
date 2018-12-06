#! /bin/bash
# This script is not a test in itself but a wrapper to run any of the other tests under a specified user.
#
# It exists because some of the filesystem functions, f.ex. is_writeable(), deliver different results for a same test if the executing user is
# root or another account. The script allows, as root or via sudo, to run a test under another user account. To make sure there's no permission
# problems, it creates a copy of bash_commons in a folder in /tmp, gives write permission to the user and executes the test there. The
# bash_commons copy is then removed.
#
# Parametrization:
# $1: name of the collection to test, f.ex. "filesystem"
# $2: name of the user to run the test with, f.ex. "man"

# Refuse symlinks and get the absolute path of the commons directory (this file lies in ./tests/.), load dependancies
[ -h "${BASH_SOURCE[0]}" ] && echo "Error: called through symlink. Please call directly. Aborting..." && exit 1
commons_path="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && dirname "$(pwd)")"

# Check the parameters
[ -z "$1" ] && echo "Please provide the test name (filesystem, string_handling, etc) as 1st parameter" && exit 1
[ -z "$2" ] && echo "Please provide the name of the user account with which the test shall be run as 2nd parameter" && exit 1
[ ! -f "$commons_path/tests/$1.sh" ] && echo "Test '$1' unknown ($commons_path/tests/$1.sh doesn't exist)" && exit 1
[ -z "$(grep "$2" "/etc/passwd")" ] && echo "User '$2' unknown (no /etc/passwd entry)" && exit 1

set -e		# quit in case of error, if f.ex. mktemp is not installed
temp_dir=$(mktemp -d)
cp -r "$commons_path/." "$temp_dir"
chown $2: "$temp_dir"
set +e		# disable "error is fatal" mode
su -c "cd $temp_dir; bash tests/$1.sh" -s /bin/bash $2
rm -r "$temp_dir"
