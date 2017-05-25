#!/bin/bash
set -eu
# initialize the primary db if it does not exist
if [ ! -f var_lib_postgresql/pg/postgresql.conf ]; then
  docker exec -ti -u postgres hotstandby_pg_1 bash -c '
    DOMAIN=$( python -c "import socket;print socket.getfqdn('\''barman'\'')" | sed -e "s/.*\([.][^.]*\)$/\1/" )
    echo START initializing primary database
    set -e
    cd /var/lib/postgresql/data;
    initdb -D /var/lib/postgresql/data
    echo "host   all          postgres  $DOMAIN  trust"                      >> pg_hba.conf
    echo "local  replication  postgres           trust"                      >> pg_hba.conf
    echo "# replication cannot be specified in the last line of the file!"   >> pg_hba.conf
    echo "wal_level = hot_standby"                                           >> postgresql.conf
    echo "archive_mode = on"                                                 >> postgresql.conf
    echo "max_wal_senders = 3"                                               >> postgresql.conf
    echo "archive_command = '\''cp -i %p /var/lib/postgresql/archive/%f'\''" >> postgresql.conf
    pwd;
    ls -la;
    supervisorctl start postgres
    supervisorctl status postgres
    echo END initializing primary database
  '
fi
# initialize the hot)standby if it does not exist
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
    echo END seeding standby
  "
fi
