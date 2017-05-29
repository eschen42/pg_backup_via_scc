#!/bin/bash

git config --global user.email "postgress@backup.daemon"
git config --global user.name "postgres backup daemon"

# initialize a git repository if one does not exist
if [ ! -d /var/lib/postgresql/data/.git ]; then
  pushd /var/lib/postgresql/data
  set -e
  # this statement will fail and abort the script postgresql is not running
  pg_dumpall > pg_dumpall.sql
  git init
  git add *.conf pg_dumpall.sql
  git commit -m "first commit of database files for backup"
  set +e
  if [ ! -d   ../backup/data ]; then
    set -e
    mkdir     ../backup/data
    git init  ../backup/data
  fi
  set -e
  cd          ../backup/data
  git pull ../../data
  pwd
  git status
  popd
fi
