#!/bin/bash

# do nothing if the git repository does not exist
if [ ! -d /var/lib/postgresql/data/.git ]; then
  echo "ERROR - git repository does not exist at /var/lib/postgresql/data/.git"
else
  set -e
  pushd /var/lib/postgresql/data
  # this statement will fail and abort the script postgresql is not running
  pg_dumpall > pg_dumpall.sql
  git add pg_dumpall.sql
  git commit -m "update pg_dumpall.sql"
  cd          ../backup/data
  git pull ../../data
  pwd
  git status
  popd
fi
