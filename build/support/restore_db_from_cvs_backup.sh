#!/bin/bash

supervisorctl stop postgres

set -e

# start in the database directory
cd /var/lib/postgresql/data

# for this test, scorch the DB directory; this is a DB restore test, so that's okay
rm -rf * CVS

# instantiate an new database cluster
initdb -D /var/lib/postgresql/data

#  # squash the files that we will overwrite
#  echo rm -rf *.conf
#  rm -rf *.conf

set +e
# get the backed up files; overwriting files as needed
## this does the checkout and removes any conflicting files
echo 'cvs -d `pwd`/../backup/data checkout -d . pg_backup  | grep "^C " | sed -e "s/^C /rm /" | sh'
cvs -d `pwd`/../backup/data checkout -d . pg_backup  | grep "^C " | sed -e "s/^C /rm /" | sh
## this fetches files that conflicted, not mentioning files that are not under CVS version control
echo 'cvs update | grep -v "^? "'
cvs update | grep -v "^? "

# restore the database using pg_dumpall.sql
supervisorctl start postgres
psql < pg_dumpall.sql

# validate the results of the restoration
pg_dumpall > pg_restored.sql
diff pg_restored.sql pg_dumpall.sql 

