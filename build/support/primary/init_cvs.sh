#!/bin/bash
echo initial directory `pwd`

pushd /var/lib/postgresql/data
echo current directory `pwd` = /var/lib/postgresql/data
set +e

# abort if database files do not exist
if [ ! -f /var/lib/postgresql/data/postgresql.conf ]; then
  echo /var/lib/postgresql/data contains
  ls /var/lib/postgresql/data
  exit 0
fi

NO_EXISTING_BACKUP=FALSE
# initialize a CVS sandbox if one does not exist
if [ ! -d /var/lib/postgresql/data/CVS ]; then

  echo current directory `pwd` = original
  if [ ! -d   ../backup/data ]; then

    set -e
    mkdir     ../backup/data
  fi

  set +e
  # initialize a CVS repository if one does not exist
  if [ ! -d   ../backup/data/CVSROOT ]; then
    NO_EXISTING_BACKUP=TRUE
    set -e
    pushd     ../backup/data
    echo current directory `pwd` = /var/lib/postgresql/backup/data
    cvs -d `pwd` init
    popd
    echo current directory `pwd` = /var/lib/postgresql/data
  fi
  echo current directory `pwd` = /var/lib/postgresql/data
  
  set +e
  # initialize a pg_backup module *in the CVS repository* if one does not exist
  if [ ! -d   ../backup/data/pg_backup ]; then
    set -e
    mkdir     ../backup/data/pg_backup
  fi

  set -e
  # initialize the sandbox
  cvs -d `pwd`/../backup/data co -d . pg_backup
fi

if [ "$NO_EXISTING_BACKUP" == "TRUE" ]; then
  set -e
  # this statement will fail and abort the script postgresql is not connectable
  psql -c "select 1" | cat
  pg_dumpall > pg_dumpall.sql
  cvs add *.conf pg_dumpall.sql
  cvs commit -m "first commit of database files for backup - $(date)"
fi

popd

echo final directory `pwd`
