#!/bin/bash

# much of this was inspired by https://wiki.postgresql.org/wiki/Hot_Standby

set -eu

# initialize the primary db if it does not exist
#   ref: https://wiki.postgresql.org/wiki/Hot_Standby#Create_the_master_database
if [ ! -f var_lib_postgresql/pg/postgresql.conf ]; then
  docker exec -ti -u postgres hotstandby_pg_1 bash -c '
    echo START initializing primary database
    set -e
    cd /var/lib/postgresql/data;
    initdb -D /var/lib/postgresql/data
    pwd;
    ls -la;
    supervisorctl start postgres
    supervisorctl status postgres
    echo END initializing primary database
  '
fi

# set up configuration files to initialize the hot standby
#   ref: https://wiki.postgresql.org/wiki/Hot_Standby#Configure_the_master_for_WAL_archiving
if [ -f var_lib_postgresql/pg/postgresql.conf -a ! -f var_lib_postgresql/standby/postgresql.conf ]; then
  docker exec -ti -u postgres hotstandby_pg_1 bash -c '
    DOMAIN=$( python -c "import socket;print socket.getfqdn('\''barman'\'')" | sed -e "s/.*\([.][^.]*\)$/\1/" )
    echo START configuring primary database to support initialization of hot backup
    set -e

    echo stop the database to rewrite the configuration files
    supervisorctl stop postgres
    supervisorctl status postgres
    cd /var/lib/postgresql/data;

    echo delete and replace lines of pg_hba.conf necessary to seed the hot standby
    sed -i -n -e "/b506ea2f41e284465f06c2a7e7dcd561/,/7e9eb140fa111f4af6aae120c59845fc/ d; p" pg_hba.conf
    echo "## b506ea2f41e284465f06c2a7e7dcd561 please leave this line alone ##"   >> pg_hba.conf
    echo "host  all  postgres  $DOMAIN  trust"                                   >> pg_hba.conf
    echo "local  replication  postgres  trust"                                   >> pg_hba.conf
    echo "# replication cannot be specified in the last line of the file!"       >> pg_hba.conf
    echo "## 7e9eb140fa111f4af6aae120c59845fc please leave this line alone ##"   >> pg_hba.conf

    echo delete and replace lines of postgresql.conf necessary to seed the hot standby
    sed -i -n -e "/b506ea2f41e284465f06c2a7e7dcd561/,/7e9eb140fa111f4af6aae120c59845fc/ d; p" postgresql.conf
    echo "## b506ea2f41e284465f06c2a7e7dcd561 please leave this line alone ##"   >> postgresql.conf
    echo "wal_level = hot_standby"                                               >> postgresql.conf
    echo "archive_mode = on"                                                     >> postgresql.conf
    echo "max_wal_senders = 3"                                                   >> postgresql.conf
    echo "archive_command = '\''cp -i %p /var/lib/postgresql/archive/%f'\''"     >> postgresql.conf
    echo "## 7e9eb140fa111f4af6aae120c59845fc please leave this line alone ##"   >> postgresql.conf

    pwd;
    ls -la;
    echo start the database to read the rewritten configuration files
    supervisorctl start postgres
    supervisorctl status postgres

    echo END configuring primary database to support initialization of hot backup
  '
fi

# initialize the hot standby only if it does not exist
#   ref: https://wiki.postgresql.org/wiki/Hot_Standby#Use_pg_basebackup_to_copy_the_master_.289.1.2B.29
if [ ! -f var_lib_postgresql/standby/postgresql.conf ]; then
  docker exec -ti -u postgres hotstandby_pg_1 bash -c "
    echo START seeding standby
    set -e
    cd /var/lib/postgresql/data;
    ps ajxf;
    pg_basebackup -D ../standby --no-password --write-recovery-conf --xlog-method=stream --dbname='user=postgres'
    cd /var/lib/postgresql/standby;
    pwd;
    ls -la;
    supervisorctl status postgres
    echo END seeding standby
  "
fi
