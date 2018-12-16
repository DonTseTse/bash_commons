#! /bin/bash
# Filesystem function tests
#
# Author: DonTseTse

############# Configuration
#

############# Preparation
# Refuse symlinks and get the absolute path of the commons directory (this file lies in ./tests/.), load dependancies
set -e
[ -h "${BASH_SOURCE[0]}" ] && echo "Error: called through symlink. Please call directly. Aborting..." && exit 1
commons_path="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && dirname "$(pwd)")"
. "$commons_path/testing.sh"
. "$commons_path/git_handling.sh"
set +e
initialize_test_session "git_handling.sh functions"

echo "*** get_git_repository_remote_url() ***"
configure_test 0 "https://github.com/DonTseTse/bash_commons.git"
test get_git_repository_remote_url "$commons_path"

configure_test 1 ""
test get_git_repository_remote_url "/tmp/unexistant"
touch "/tmp/test.file"
echo " - \$> touch \"/tmp/test.file\""
configure_test 2 ""
test get_git_repository_remote_url "/tmp/test.file"
# status 3 is read permission
configure_test 4 ""
test get_git_repository_remote_url "/tmp"
# status 5 is "git config" failed
configure_test 6 ""
test get_git_repository_remote_url

rm "/tmp/test.file"

echo "*** get_git_repository() ***"
configure_test 0 "https://github.com/DonTseTse/sendmail2mailgun cloned to /tmp/sendmail2mailgun\n"
test get_git_repository "https://github.com/DonTseTse/sendmail2mailgun" "/tmp/sendmail2mailgun" 1
# status 1 is git clone failed
configure_test 2 ""
test get_git_repository "https://github.com/DonTseTse/sendmail2mailgun" "/tmp/sendmail2mailgun"
# states 3-6 are the ones of get_git_repository_remote_url()

configure_test 7 "/tmp/sendmail2mailgun exists and it's a git repository but the remote URL is not https://github.com/DonTseTse/bash_commons\n"
test get_git_repository "https://github.com/DonTseTse/bash_commons" "/tmp/sendmail2mailgun" 1
msg_defs=([7]="      %path has another repo URL than %url\n")
echo " - \$> msg_defs=([7]=\"      %path has another repo URL than %url\")"
configure_test 7 "      /tmp/sendmail2mailgun has another repo URL than https://github.com/DonTseTse/bash_commons\n"
test get_git_repository "https://github.com/DonTseTse/bash_commons" "/tmp/sendmail2mailgun" "msg_defs"

configure_test 8 ""
test get_git_repository "" "/tmp/sendmail2mailgun"
configure_test 9 ""
test get_git_repository "https://github.com/DonTseTse/sendmail2mailgun" ""

rm -r "/tmp/sendmail2mailgun"

conclude_test_session
