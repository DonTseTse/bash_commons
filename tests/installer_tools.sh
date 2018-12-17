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
configure_test 3 "/usr/bin/exec_test"
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
configure_test 5 ""
test get_executable_status

rm "/usr/bin/exec_test" "/tmp/exec_test"
echo " - \$> rm \"/usr/bin/exec_test\" \"/tmp/exec_test\""

echo "*** handle_dependency() ***"
configure_test 5 ""
test handle_dependency "exec_test"

ln -s "/tmp/exec_test" "/usr/bin/exec_test"
echo " - \$> ln -s \"/tmp/exec_test\" \"/usr/bin/exec_test\""
configure_test 8 ""
test handle_dependency "exec_test"

touch "/tmp/exec_test"
echo " - \$> touch \"/tmp/exec_test\""
configure_test 2 ""
test handle_dependency "exec_test"

configure_test 1 "exec_test (/usr/bin/exec_test) already installed\n"
test handle_dependency "exec_test" 1

msg_defs=([1]=" - %command already installed, found under %path\n")
configure_test 1 " - exec_test already installed, found under /usr/bin/exec_test\n"
test handle_dependency "exec_test" "msg_defs"

rm "/tmp/exec_test" "/usr/bin/exec_test"
echo " - \$> rm \"/tmp/exec_test\" \"/usr/bin/exec_test\""

function handle_dependency_installation()
{
	echo "I'm the installer for $1"
}
echo "Defined function handle_dependency_installation() which prints the message \"I'm the installer for \$1\""

configure_test 0 "I'm the installer for exec_test"
test handle_dependency "exec_test"

configure_test 10 ""
test handle_dependency

[ -d "/tmp/sendmail2mailgun" ] && rm -r "/tmp/sendmail2mailgun"
conclude_test_session
