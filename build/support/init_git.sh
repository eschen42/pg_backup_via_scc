#!/bin/bash

#set -e

git config --global user.email "postgress@backup.daemon"
git config --global user.name "postgres backup daemon"

#   # initialize a git repository if one does not exist
#   if [ ! -d /var/lib/postgresql/archive/dump ]; then
#     mkdir /var/lib/postgresql/archive/dump
#   fi
#   
#   cd /var/lib/postgresql/archive/dump
#   
#   if [ ! -d /var/lib/postgresql/archive/dump/.git ]; then
#     git init
#   fi

if [ ! -d /var/lib/postgresql/data/.git ]; then
  cd /var/lib/postgresql/data
  # this statement will fail and abort the script postgresql is not running
  pg_dumpall > pg_dumpall.sql
  git init
  git add *.conf pg_dumpall.sql
  git commit -m "first commit of database files for backup"
  echo foo
  if [ ! -d   ../backup/data ]; then
    echo bar
    mkdir     ../backup/data
    echo baz
    git init  ../backup/data
    cd        ../backup/data
    echo bat
    git pull  ../../data
    echo ban
  fi
fi
