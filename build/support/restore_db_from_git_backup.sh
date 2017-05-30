#!/bin/bash

supervisorctl stop postgres

set -e

git config --global user.email "postgress@restore.daemon"
git config --global user.name "postgres restore daemon"

# start in the database directory
cd /var/lib/postgresql/data

# for this test, scorch the DB directory; this is a DB restore test, so that's okay
rm -rf * .git

# instantiate an new database cluster
initdb -D /var/lib/postgresql/data

# instantiate a git repo in /var/lib/postgresql/data
git init

# add the default conf files that were created by initdb
git add *.conf

# show the status for those following along
git status

# commit the conf files to the new git repo
git commit -m "prime repo"

# show the status for those following along
echo --- status of /var/lib/postgresql/data
git status
echo ... status of /var/lib/postgresql/data

# show the status of the data-to-be-backed-up
pushd ../backup/data
echo --- status of backup/data
git status
echo ... status of backup/data

# return to /var/lib/postgresql/data
popd

# declare the relationship - this repo pulls from ../backup/data, nicnamed 'backup'
git remote add backup ../backup/data

# git pull will fail when merge is required; it will be required for the first pull
set +e
git pull backup master
set -e

# show how things look after the pull
echo --- status of merged restored data
git status
echo ... status of merged restored data

# Force resolution of merge-conflicts to accept changes from pull;
# (Inspired by https://git-scm.com/book/en/v2/Git-Tools-Advanced-Merging#_manual_remerge.)
#   Note that lines produced by 'git ls-files -u' have the floowing form
#     ^100644 9455a96dccf05071bbd2075fdaae326722c67284 2\tpg_hba.conf$
#     ^100644 98b34b02c06af56edfba9fd4279850848ce60e8b 3\tpg_hba.conf$
#   Where #1 is the original file, #2 is our branch's; and #3 is their branch's
#   In this case, we always want theirs, #3
#     git ls-files -u | sed -n -e '
#       # ignore lines that don't have '3' after the hash
#       /^[^ ]\+ [^ ]\+ [12]\t/ d
#       # transmogrify the line to
#       #   git show 98b34b02c06af56edfba9fd4279850848ce60e8b > pg_hba.conf; git add pg_hba.conf;
#       s/^[^ ]\+ \([^ ]\+\) 3\t\(.*\)$/git show \1 > \2; git add \2; /
#       # pass the result to stdout
#       p
#     ' | grep 'git show .* git add ' | bash
git ls-files -u | sed -n -e '
  /^[^ ]\+ [^ ]\+ [12]\t/ d
  s/^[^ ]\+ \([^ ]\+\) 3\t\(.*\)$/git show \1 > \2; git add \2; /
  p
' | grep 'git show .* git add ' | bash

# show repo prepped to commit the merge
echo --- status of added restored data
git status
echo ... status of added restored data

# do the merge and show the result
git commit -m "merge restored files"
echo --- status of committed restored data
git status
echo ... status of committed restored data

# restore the database using pg_dumpall.sql
supervisorctl start postgres
psql < pg_dumpall.sql

# validate the results of the restoration
pg_dumpall > pg_restored.sql
diff pg_restored.sql pg_dumpall.sql 

