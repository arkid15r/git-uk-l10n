#!/bin/sh

test_description='checkout must not overwrite an untracked objects'

TEST_PASSES_SANITIZE_LEAK=true
. ./test-lib.sh

test_expect_success 'setup' '

	mkdir -p a/b/c &&
	>a/b/c/d &&
	git add -A &&
	git commit -m base &&
	git tag start
'

test_expect_success 'create a commit where dir a/b changed to file' '

	git checkout -b file &&
	rm -rf a/b &&
	>a/b &&
	git add -A &&
	git commit -m "dir to file"
'

test_expect_success 'checkout commit with dir must not remove untracked a/b' '

	git rm --cached a/b &&
	git commit -m "un-track the file" &&
	test_must_fail git checkout start &&
	test -f a/b
'

test_expect_success 'create a commit where dir a/b changed to symlink' '

	rm -rf a/b &&	# cleanup if previous test failed
	git checkout -f -b symlink start &&
	rm -rf a/b &&
	git add -A &&
	test_ln_s_add foo a/b &&
	git commit -m "dir to symlink"
'

test_expect_success 'checkout commit with dir must not remove untracked a/b' '

	git rm --cached a/b &&
	git commit -m "un-track the symlink" &&
	test_must_fail git checkout start
'

test_expect_success SYMLINKS 'the symlink remained' '

	test -h a/b
'

test_expect_success 'cleanup after previous symlink tests' '
	rm a/b
'

test_expect_success SYMLINKS 'checkout -f must not follow symlinks when removing entries' '
	git checkout -f start &&
	mkdir dir &&
	>dir/f &&
	git add dir/f &&
	git commit -m "add dir/f" &&
	mv dir untracked &&
	ln -s untracked dir &&
	git checkout -f HEAD~ &&
	test_path_is_file untracked/f
'

test_expect_success 'checkout --overwrite-ignore should succeed if only ignored files in the way' '
	git checkout -b df_conflict &&
	test_commit contents some_dir &&
	git checkout start &&
	mkdir some_dir &&
	echo autogenerated information >some_dir/ignore &&
	echo ignore >.git/info/exclude &&
	git checkout --overwrite-ignore df_conflict &&
	! test_path_is_dir some_dir
'

test_done
