#! /bin/bash

### Configuration
# test_root_path: absolute path to the root directory of the filesystem tests
test_root_path="/tmp"
#
not_existing_file_name="unexistant.file"
not_existing_folder_name="unexistant_folder"
default_file_name="test.file"

# 
link_tests_folder_name="link_tests"
# at least for non root users
not_writable_folder_path="/proc"
#su -c "commons_path=$commons_path; . \"$commons_path/filesystem.sh\"; . \"$commons_path/testing.sh\"; test is_writeable \"/proc/file\"" -s /bin/bash man


### Preparation
# Refuse symlinks and get the absolute path of the commons directory (this file lies in ./tests/.), load dependancies
set -e
[ -h "${BASH_SOURCE[0]}" ] && echo "Error: called through symlink. Please call directly. Aborting..." && exit 1
commons_path="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && dirname "$(pwd)")"
. "$commons_path/testing.sh"
. "$commons_path/filesystem.sh"
set +e
initialize_test_session "filesystem.sh functions"

echo "*** Preparation ***"
pwd_before_tests="$(pwd)"
[ -z "test_root_path" ] && echo "Set a test root folder in the configuration. Aborting..." && exit 1
test_base_folder="$(mktemp -d -p "$test_root_path")"
cd "$test_base_folder"
echo " - test base folder $test_base_folder  created and set as current working directory"

not_existing_file_path="$test_base_folder/$not_existing_file_name"
[ -f "$not_existing_file_path" ] && echo "The file with the path $not_existing_file_path is not supposed to exist, tests will fail. Aborting..." && exit 1
not_existing_folder_path="$test_base_folder/$not_existing_folder_name"
multilevel_not_existing_path="$test_base_folder/$not_existing_folder_name/$not_existing_file_name"
[ -d "$not_existing_folder_path" ] && echo "The folder with the path $not_existing_folder_path is not supposed to exist, tests will fail. Aborting..." && exit 1
existing_file_path="$test_base_folder/$default_file_name"
not_existing_root_folder="/$not_existing_folder_name"
[ -d "$not_existing_root_folder" ] && echo "The folder with the path $not_existing_root_folder is not suppose to exist, tests will fail. Aborting..." && exit 1
touch "$existing_file_path"

# Symlinks
link_test_path="$test_base_folder/$link_tests_folder_name"
mkdir -p "$link_test_path/folder/subfolder" "$link_test_path/upper_links"
link_testfile_path="$link_test_path/$default_file_name"
link_folder_testfile_path="$link_test_path/folder/$default_file_name"
link_subfolder_testfile_path="$link_test_path/folder/subfolder$default_file_name"
touch "$link_testfile_path" "$link_folder_testfile_path" "$link_subfolder_testfile_path"
ln -s "$existing_file_path" "$link_test_path/abs_link"
ln -s "$not_existing_file_path" "$link_test_path/abs_link_broken"
ln -s "$default_file_name" "$link_test_path/rel_link"
ln -s "$not_existing_file_name" "$link_test_path/rel_link_broken"
ln -s "folder/$default_file_name" "$link_test_path/rel_link_inner"
ln -s "$link_test_path/folder" "$link_test_path/folder_link_abs"
ln -s "$not_existing_folder_path" "$link_test_path/folder_link_abs_broken"
ln -s "folder" "$link_test_path/folder_link_rel"
ln -s "$not_existing_folder_name" "$link_test_path/folder_link_rel_broken"
ln -s "folder/subfolder" "$link_test_path/folder_link_rel_inner"
ln -s "../$default_file_name" "$link_test_path/upper_links/file"
ln -s "../folder/$default_file_name" "$link_test_path/upper_links/file_multilvl"
ln -s "../folder" "$link_test_path/upper_links/folder"
ln -s "../folder/subfolder" "$link_test_path/upper_links/folder_multilvl"

# After settings up these links, the structure inside the base folder $link_test_path
# ($test_base_folder/$link_tests_folder_name) is:
# .../
#     folder/
#    .       subfolder/
#    .      .          test.file
#    .       test.file
#     abs_link                       -> $existing_file_path
#     abs_link_broken                -> $not_existing_file_path
#     rel_link                       -> test.file
#     rel_link_broken                -> $not_existing_file_name
#     rel_link_inner                 -> folder/test.file
#     folder_link_abs                -> $link_test_path/folder
#     folder_link_abs_broken         -> $link_test_path/folder
#     folder_link_rel                -> folder
#     folder_link_rel_broken         -> $not_existing_folder_name
#     folder_link_rel_inner          -> folder/subfolder
#     upper_links/
#    .            folder                        -> ../folder
#    .            folder_multilvl               -> ../folder/subfolder
#    .            file                          -> ../test.file
#    .            file_multilvl                 -> ../folder/test.file
#     test.file


############# Tests
echo " *** get_real_path() ***"
configure_test 1 ""
test get_real_path

configure_test 1 ""
test get_real_path ""

configure_test 0 "$existing_file_path"
test get_real_path "$existing_file_path"

echo " - Filesystem info: $(ls -l "$link_test_path/abs_link" | sed 's#^[^/]*##')"
configure_test 0 "$existing_file_path"
test get_real_path "$link_test_path/abs_link"

echo " - Filesystem info: $(ls -l "$link_test_path/abs_link_broken" | sed 's#^[^/]*##')"
configure_test 1 ""
test get_real_path "$link_test_path/abs_link_broken"

echo " - For relative symlinks, the current working directory counts (and not the one which was set when the link was created)"
cd "$link_test_path"
echo "   \$> cd \"$link_test_path\""

echo "   Filesystem info: $(ls -l "$link_test_path/rel_link" | sed 's#^[^/]*##')"
configure_test 0 "$link_test_path/$default_file_name"
test get_real_path "$link_test_path/rel_link"

echo " - Filesystem info: $(ls -l "$link_test_path/rel_link_broken" | sed 's#^[^/]*##')"
configure_test 1 ""
test get_real_path "$link_test_path/rel_link_broken"

echo " - Filesystem info: $(ls -l "$link_test_path/rel_link_inner" | sed 's#^[^/]*##')"
configure_test 0 "$link_test_path/folder/$default_file_name"
test get_real_path "$link_test_path/rel_link_inner"

echo " - Filesystem info: $(ls -l "$link_test_path/folder_link_abs" | sed 's#^[^/]*##')"
configure_test 0 "$link_test_path/folder"
test get_real_path "$link_test_path/folder_link_abs"

echo " - Filesystem info: $(ls -l "$link_test_path/folder_link_abs_broken" | sed 's#^[^/]*##')"
configure_test 1 ""
test get_real_path "$link_test_path/folder_link_abs_broken"

echo " - Filesystem info: $(ls -l "$link_test_path/folder_link_rel" | sed 's#^[^/]*##')"
configure_test 0 "$link_test_path/folder"
test get_real_path "$link_test_path/folder_link_rel"

echo " - Filesystem info: $(ls -l "$link_test_path/folder_link_rel_broken" | sed 's#^[^/]*##')"
configure_test 1 ""
test get_real_path "$link_test_path/folder_link_rel_broken"

echo " - Filesystem info: $(ls -l "$link_test_path/folder_link_rel_inner" | sed 's#^[^/]*##')"
configure_test 0 "$link_test_path/folder/subfolder"
test get_real_path "$link_test_path/folder_link_rel_inner"

cd "$link_test_path/upper_links"
echo " - \$> cd \"$link_test_path/upper_links\""

echo " - Filesystem info: $(ls -l "$link_test_path/upper_links/file" | sed 's#^[^/]*##')"
configure_test 0 "$link_test_path/$default_file_name"
test get_real_path "$link_test_path/upper_links/file"

echo " - Filesystem info: $(ls -l "$link_test_path/upper_links/file_multilvl" | sed 's#^[^/]*##')"
configure_test 0 "$link_test_path/folder/$default_file_name"
test get_real_path "$link_test_path/upper_links/file_multilvl"

echo " - Filesystem info: $(ls -l "$link_test_path/upper_links/folder" | sed 's#^[^/]*##')"
configure_test 0 "$link_test_path/folder"
test get_real_path "$link_test_path/upper_links/folder"

echo " - Filesystem info: $(ls -l "$link_test_path/upper_links/folder_multilvl" | sed 's#^[^/]*##')"
configure_test 0 "$link_test_path/folder/subfolder"
test get_real_path "$link_test_path/upper_links/folder_multilvl"

cd "$test_base_folder"
echo " - \$> cd \"$test_base_folder\""

###
echo "*** get_script_path() ***"
cd "$pwd_before_tests"
echo " - \$> cd $pwd_before_tests <\$ because get_script_path() always works with respect to the working directory at the moment the script was executed"
configure_test 0 "$commons_path/tests/filesystem.sh"
test get_script_path
cd "$test_base_folder"
echo " - \$> cd $test_base_folder"

###
echo "*** is_writeable() ***"
configure_test 0 "1"
test is_writeable "$test_base_folder"

configure_test 0 "1"
test is_writeable "$not_existing_file_path"

configure_test 0 "2"
test is_writeable "$multilevel_not_existing_path"

configure_test 0 "1"
test is_writeable "$multilevel_not_existing_path" 1

return_val=0
[ "$UID" -eq 0 ] && return_val=1 && echo " - is_writeable() can't be properly tested as root user because by default it has the write permission absolutely everywhere"
configure_test 0 "$return_val"
test is_writeable "$not_writable_folder_path"

configure_test 0 "$return_val"
test is_writeable "$not_writable_folder_path/$default_file_name"

configure_test 0 "2"
test is_writeable "$not_writable_folder_path/test/$default_file_name"

configure_test 0 "$return_val"
test is_writeable "$not_writable_folder_path/test/$default_file_name" 1

configure_test 1 ""
test is_writeable

###
echo "*** get_new_path_part() ***"
configure_test 0 "$not_existing_folder_name/$not_existing_file_name"
test get_new_path_part "$multilevel_not_existing_path"

configure_test 0 "$not_existing_root_folder/$default_filename"
test get_new_path_part "$not_existing_root_folder/$default_filename"

configure_test 0 ""
test get_new_path_part "$test_root_path"

###
echo "*** get_existing_path_part() ***"
configure_test 0 "$test_base_folder"
test get_existing_path_part "$multilevel_not_existing_path"

configure_test 0 "/"
test get_existing_path_part "$not_existing_root_folder"

###
echo "*** try_filepath_deduction() ***"

# preparation
filepath_deduction_test_folder="$test_base_folder/fp_infer"
mkdir "$filepath_deduction_test_folder"
touch "$filepath_deduction_test_folder/1.test" "$filepath_deduction_test_folder/2.test"
touch "/tmp/test.conf"
echo " - Created folder $filepath_deduction_test_folder with the files 1.test and 2.test inside"

configure_test 1 ""
test try_filepath_deduction "$not_existing_root_folder"

configure_test 3 ""
test try_filepath_deduction "$filepath_deduction_test_folder"

configure_test 2 ""
test try_filepath_deduction "$filepath_deduction_test_folder" "*.conf"

touch "$filepath_deduction_test_folder/test.conf"
echo " - \$> touch \"$filepath_deduction_test_folder/test.conf\""
configure_test 0 "$filepath_deduction_test_folder/test.conf"
test try_filepath_deduction "$filepath_deduction_test_folder" "*.conf"

touch "$filepath_deduction_test_folder/test2.conf"
echo " - \$> touch \"$filepath_deduction_test_folder/test2.conf\""
configure_test 3 ""
test try_filepath_deduction "$filepath_deduction_test_folder" "*.conf"

###
echo "*** create_folder() ***"
configure_test 0 ""
test create_folder "$test_base_folder/mkdir_test"

configure_test 2 ""
test create_folder ""

configure_test 3 ""
test create_folder "$filepath_deduction_test_folder"

configure_test 0 "0"
test create_folder "$test_base_folder/mkdir_test2" "status"

configure_test 0 "folder $test_base_folder/mkdir_test3 created\n"
test create_folder "$test_base_folder/mkdir_test3" "verbose"

configure_test 3 "folder creation error: $test_base_folder/mkdir_test3 exists\n"
test create_folder "$test_base_folder/mkdir_test3" "verbose"

mkdir_msgs=("Success %path" "Error %err_msg")
echo " - \$> mkdir_msgs=(\"Success %path\" \"Error %err_msg\")"

test create_folder "$test_base_folder/mkdir_test3" "verbose" "mkdir_msgs"

configure_test 0 "Success $test_base_folder/mkdir_test4"
test create_folder "$test_base_folder/mkdir_test4" "verbose" "mkdir_msgs"

return_val=4
if [ "$UID" -eq 0 ]; then
	return_val=1
	mkdir_err_msg="mkdir: cannot create directory ‘$not_writable_folder_path/mkdir_test’: No such file or directory"
	echo " - create_directory() includes a write permission check which gives a false positive for the root user because by convention it can write absolutely everywhere"
	echo "   However, in directories like $not_writable_folder_path, the operation fails"
fi
configure_test $return_val "$mkdir_err_msg"
test create_folder "$not_writable_folder_path/mkdir_test" "error_message"

configure_test $return_val ""
test create_folder "$not_writable_folder_path/mkdir_test"

###
echo "*** move_file() / move_folder() ***"
echo ' - touch "$test_base_folder/a'
mkdir "$test_base_folder/folder_to_move" "$test_base_folder/folder_to_copy"
touch "$test_base_folder/a" "$test_base_folder/folder_to_copy/a"
echo " - Created $test_base_folder/a , folders $test_base_folder/folder_to_move and $test_base_folder/folder_to_copy as well as $test_base_folder/folder_to_copy/a"
configure_test 0 ""
test "move_file" "$test_base_folder/a" "$test_base_folder/b"

return_val=6
if [ "$UID" -eq 0 ]; then
	return_val=1
	mv_err_msg="mv: cannot create regular file '$not_writable_folder_path/a': No such file or directory"
        echo " - move() includes a write permission check which gives a false positive for the root user because by convention it can write absolutely everywhere"
        echo "   However, in directories like $not_writable_folder_path, the operation fails"
fi

configure_test $return_val ""
test move_file "$test_base_folder/b" "$not_writable_folder_path/a"

configure_test $return_val "$return_val"
test move_file "$test_base_folder/b" "$not_writable_folder_path/a" '$?'

configure_test $return_val "$return_val"
test move_file "$test_base_folder/b" "$not_writable_folder_path/a" 'status'

configure_test $return_val "$mv_err_msg"
test move_file "$test_base_folder/b" "$not_writable_folder_path/a" "stderr"

echo ' - $> msg_defs=("My success message: moved %source to %destination")'
msg_defs=("My success message: moved %source to %destination")
configure_test 0 "My success message: moved $test_base_folder/b to $test_base_folder/a"
test move_file "$test_base_folder/b" "$test_base_folder/a" "verbose" "msg_defs"

configure_test 0 ""
test move_folder "$test_base_folder/folder_to_move" "$test_base_folder/moved_folder"

###
echo "*** copy_file() / copy_folder() ***"
touch "$test_base_folder/c"
echo ' - touch "$test_base_folder/c"'

configure_test 5 "copy error: $test_base_folder/a -> $test_base_folder/c failed because destination path exists (won't overwrite)\n"
test copy_file "$test_base_folder/a" "$test_base_folder/c" "verbose"

configure_test 0 "$test_base_folder/folder_to_copy copied to $test_base_folder/copied_folder\n"
test copy_folder "$test_base_folder/folder_to_copy" "$test_base_folder/copied_folder" "verbose"

configure_test 0 "0"
test copy_folder "$test_base_folder/folder_to_copy" "$test_base_folder/copied folder" "status"

msg_defs=("My success message: moved %source to %destination" "%err_msg" "Source empty" "Source %source doesn't exist")
configure_test 2 "Source empty"
test copy_folder "" "" "verbose" "msg_defs"

configure_test 3 "Source $not_existing_file_path doesn't exist"
test copy_file "$not_existing_file_path" "$test_base_folder/shouldntexist" "verbose" "msg_defs"

###
echo "*** remove_file() / remove_folder() ***"
configure_test 0 ""
test remove_file "$test_base_folder/c"

configure_test 2 ""
test remove_folder

configure_test 3 "removal error: $not_existing_file_path doesn't exist\n"
test remove_file "$not_existing_file_path" "verbose"

if [ "$UID" -ne 0 ]; then
	mkdir "$test_base_folder/non_writable_dir" && chmod -w "$test_base_folder/non_writable_dir"
	configure_test 4 "custom msg - removal error: no write permission on $test_base_folder/non_writable_dir"
	removal_msg_defs[4]="custom msg - removal error: no write permission on %path"
	test remove_folder "$test_base_folder/non_writable_dir" "verbose" "removal_msg_defs"
fi

###
test_file_path="$test_root_path/cfg_testfile"
cat > "$test_file_path"  << EOF
This line is not an assignment even if it uses contains the word variable
#another comment
variable="value"
numeric=1
    with_space = "value"
single_quotes = 'value'
#variable2=comment
variable2=value2
EOF

cp "$test_file_path" "$test_root_path/cfg_testfile_unreadable"
chmod -r "$test_root_path/cfg_testfile_unreadable"

echo "*** load_configuration_file_value() ***"
echo "------ Configuration file used for testing ------"
cat "$test_file_path"
echo "-------------------------------------------------"
configure_test 1 ""
test load_configuration_file_value "" ""
configure_test 2 ""
test load_configuration_file_value "$test_file_path" ""
configure_test 3 ""
test load_configuration_file_value "unknown" "whatever"
#configure_test 4 ""
#test su -s /bin/bash -c ". \"$commons_path/configuration_file_handling.sh\"; echo $?  load_value_from_file \"$test_root_path/cfg_testfile_unreadable\" \"variable\" echo $?"  man
#test load_value_from_file "$test_root_path/cfg_testfile_unreadable" "variable"
configure_test 5 ""
test load_configuration_file_value "$test_file_path" "undefined"
configure_test 0 "value"
test load_configuration_file_value "$test_file_path" "variable"
test load_configuration_file_value "$test_file_path" "with_space"
test load_configuration_file_value "$test_file_path" "single_quotes"

configure_test 0 "1"
test load_configuration_file_value "$test_file_path" "numeric"
configure_test 0 "value2"
test load_configuration_file_value "$test_file_path" "variable2"

#configure_test 0 "value"
#load_configuration_file_value "$test_file_path" "variable" "var"
#check_test_results "load_value_from_file_to_variable \"$test_file_path\" \"variable\" \"var_name\""  $? "$var"

#rm "/tmp/test.conf" "/tmp/test2.conf"
cd "$pwd_before_tests"

[ "$UID" -eq 0 ] && printf " - Note: If you want to run the test as normal user, try \$> su -c \"cd $commons_path; /bin/bash tests/filesystem.sh\" -s /bin/bash <user>\n   If <user> has no permissions on <commons_path>, create a copy f.ex. \$> cp -r <commons_path> /tmp/bash_commons <\$ and use /tmp/bash_commons as <commons_path>\n"
conclude_test_session
