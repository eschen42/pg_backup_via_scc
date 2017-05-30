#!/bin/bash

# do nothing if the git repository does not exist
if [ ! -d /var/lib/postgresql/data/pg_hba.conf ]; then
  echo "ERROR - configuration file does not exist at /var/lib/postgresql/data/pg_hba.conf"
else
  echo ---
  echo before update, tail of /var/lib/postgresql/backup/data/pg_hba.conf is
  tail /var/lib/postgresql/backup/data/pg_hba.conf
  echo ...
  set -e
  pushd /var/lib/postgresql/data
  # this statement will fail and abort the script postgresql is not running

    MYIFADDR=$( python -c "import socket;print socket.gethostbyname('$HOSTNAME')" )

    echo START grant host-based access on "pg" = $HOSTNAME = $MYIFADDR

    set -e
    DOMAIN=$( python -c "import socket;print socket.getfqdn('barman')" | sed -e "s/.*\([.][^.]*\)$/\1/" )

    cd /var/lib/postgresql/data;
    echo stop the main database to rewrite the configuration files
    if [ -f postmaster.pid ]; then
      supervisorctl stop postgres
      supervisorctl status postgres
    fi

    echo delete and replace lines of pg_hba.conf necessary to SEED the hot standby
    sed -i -n -e "/b506ea2f41e284465f06c2a7e7dcd561/,/7e9eb140fa111f4af6aae120c59845fc/ d; p" pg_hba.conf
    #
    echo "## b506ea2f41e284465f06c2a7e7dcd561 please leave this line alone ##"  >> pg_hba.conf
    echo "host  all  postgres  pg$DOMAIN  trust"                                >> pg_hba.conf
    echo "host  all  postgres  barman$DOMAIN  trust"                            >> pg_hba.conf
    echo "## `date` ##"                                                         >> pg_hba.conf
    echo "## 7e9eb140fa111f4af6aae120c59845fc please leave this line alone ##"  >> pg_hba.conf

    echo `pwd` @ $HOSTNAME
    ls -la | grep -E "(conf$)|(pid$)"

    echo start the database to read the rewritten configuration files
    if [ ! -f postmaster.pid ]; then
      # ensure permissions to start the DB
      chmod 700 /var/lib/postgresql/data
      echo starting the PostgreSQL database after "set up configuration files to initialize the hot standby"
      supervisorctl start postgres
      supervisorctl status postgres
    else
      # this must be exeuted running as 'postgres' or another DB superuser
      psql -c "SELECT pg_reload_conf()"
    fi

    echo END grant host-based access on "pg" = $HOSTNAME = $MYIFADDR

fi
