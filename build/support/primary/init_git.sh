#!/bin/bash

git config --global user.email "postgress@backup.daemon"
git config --global user.name "postgres backup daemon"

# initialize a git repository if one does not exist
if [ ! -d /var/lib/postgresql/data/.git ]; then
  echo current directory original-unknown
  pushd /var/lib/postgresql/data
  echo current directory /var/lib/postgresql/data
  set -e
  # this statement will fail and abort the script postgresql is not connectable
  psql -c "select 1" | cat
  pg_dumpall > pg_dumpall.sql
  git init
  git add *.conf pg_dumpall.sql
  git commit -m "first commit of database files for backup"
  set +e
  if [ ! -d   ../backup/data ]; then
    set -e
    mkdir     ../backup/data
    pushd     ../backup/data
    echo current directory /var/lib/postgresql/backup/data
    git init
    git remote add backup ../../data
    popd
    echo current directory /var/lib/postgresql/data
  fi
  set -e
  cd          ../backup/data
  echo current directory /var/lib/postgresql/backup/data
  git pull ../../data
  git remote -v
  pwd
  git status
  popd
  echo current directory original-unknown
fi
