#!/bin/bash

# do nothing if the git repository does not exist
if [ ! -d /var/lib/postgresql/data/.git ]; then
  echo "ERROR - git repository does not exist at /var/lib/postgresql/data/.git"
else
  echo ---
  echo before update, tail of /var/lib/postgresql/backup/data/pg_hba.conf is
  tail /var/lib/postgresql/backup/data/pg_hba.conf
  echo ...
  set -e
  pushd /var/lib/postgresql/data
  # this statement will fail and abort the script postgresql is not running
  pg_dumpall > pg_dumpall.sql
  git add pg_dumpall.sql
  git commit -m "update pg_dumpall.sql" pg_dumpall.sql *.conf
  cd          ../backup/data
  echo changing to `pwd` and calling git pull
  git pull ../../data
  git status
  popd
  echo ---
  echo after update, tail of /var/lib/postgresql/backup/data/pg_hba.conf is
  tail /var/lib/postgresql/backup/data/pg_hba.conf
  echo ...
fi
