#! /bin/bash
# Filesystem function tests
#
# Author: DonTseTse

############# Configuration
test_root_path="/tmp"

############# Preparation
# Refuse symlinks and get the absolute path of the commons directory (this file lies in ./tests/.), load dependancies
set -e
[ -h "${BASH_SOURCE[0]}" ] && echo "Error: called through symlink. Please call directly. Aborting..." && exit 1
commons_path="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && dirname "$(pwd)")"
. "$commons_path/testing.sh"
. "$commons_path/installer_tools.sh"
set +e
initialize_test_session "installer_tools.sh functions"

echo "*** get_executable_status() ***"
ln -s "/tmp/exec_test" "/usr/bin/exec_test"
echo " - \$> ln -s \"/tmp/exec_test\" \"/usr/bin/exec_test\""
configure_test 4 "/usr/bin/exec_test"
test get_executable_status "exec_test" 1
touch "/tmp/exec_test"
echo " - \$> touch \"/tmp/exec_test\""
configure_test 1 "/tmp/exec_test"
test get_executable_status "exec_test" 1
chmod +x "/tmp/exec_test"
echo " - \$> chmod +x \"/tmp/exec_test\""
configure_test 0 ""
test get_executable_status "exec_test"

configure_test 2 ""
test get_executable_status "unexistant"
configure_test 3 ""
test get_executable_status

rm "/usr/bin/exec_test" "/tmp/exec_test"
echo " - \$> rm \"/usr/bin/exec_test\" \"/tmp/exec_test\""
echo "*** handle_dependency() ***"
configure_test 1 " - exec_test: not found, please install [Error]"
test handle_dependency "exec_test"
ln -s "/tmp/exec_test" "/usr/bin/exec_test"
echo " - \$> ln -s \"/tmp/exec_test\" \"/usr/bin/exec_test\""
configure_test 1 " - exec_test: found a correponding element in \$PATH but /usr/bin/exec_test doesn't resolve to a existing location (broken folder or file symlink?) [Error]"
test handle_dependency "exec_test"
touch "/tmp/exec_test"
echo " - \$> touch \"/tmp/exec_test\""
configure_test 0 " - exec_test: /tmp/exec_test was not executable, applied chmod +x [OK]"
test handle_dependency "exec_test"
#chmod +x "/tmp/exec_test"
#echo " - \$> chmod +x \"/tmp/exec_test\""
configure_test 0 " - exec_test: /usr/bin/exec_test [OK]"
test handle_dependency "exec_test"

rm "/tmp/exec_test" "/usr/bin/exec_test"

echo "*** get_git_repository_remote_url() ***"
configure_test 0 "https://github.com/DonTseTse/bash_commons.git"
test get_git_repository_remote_url "$commons_path"

configure_test 1 ""
test get_git_repository_remote_url "/tmp/unexistant"
touch "/tmp/test.file"
echo " - \$> touch \"/tmp/test.file\""
configure_test 2 ""
test get_git_repository_remote_url "/tmp/test.file"

configure_test 4 ""
test get_git_repository_remote_url "/tmp"

configure_test 6 ""
test get_git_repository_remote_url

rm "/tmp/test.file"

echo "*** get_git_repository() ***"
configure_test 0 ""
test get_git_repository "https://github.com/DonTseTse/sendmail2mailgun" "/tmp/sendmail2mailgun"

configure_test 0 ""
test get_git_repository "https://github.com/DonTseTse/sendmail2mailgun" "/tmp/sendmail2mailgun" "update"

[ -d "/tmp/sendmail2mailgun" ] && rm -r "/tmp/sendmail2mailgun"
conclude_test_session
