#!/bin/bash
# Art Eschenlauer, May 2017 esch0041@umn.edu eschen@alumni.princeton.edu  

# Much of this was inspired by https://wiki.postgresql.org/wiki/Hot_Standby
#   which in turn references https://www.postgresql.org/docs/current/static/hot-standby.html
# I am doing this to support PostgreSQL 9.3 and have made several decisions based on that fact.

# I don't know whether Galaxy can make any practical use of a hot standby.
# My purpose for implementing is to support barman, which requires exclusive access to a pg9.3 to back it up.

# From the first reference above:
#   A hot standby provides:
#   - the ability to connect to the server and run **read-only** queries while the master instance is in archive recovery or standby mode.
#     - This is useful for:
#       - replication purposes, and
#       - restoring a backup to a desired state with great precision.
#   - the ability of the server to move from recovery to normal operation while users continue running **read-only** queries or keep their connections open.

set -eu

##### actions on the 'pg' container #####

# initialize the primary db if it does not exist
#   ref: https://wiki.postgresql.org/wiki/Hot_Standby#Create_the_master_database
# Note well: The 'pg' container is started with -v ./var_lib_postgresql/pg:/var/lib/postgresql/data
if [ ! -f var_lib_postgresql/pg/postgresql.conf ]; then
  docker exec -ti -u postgres hotstandby_pg_1 bash -c '
    MYIFADDR=$( python -c "import socket;print socket.gethostbyname('\''$HOSTNAME'\'')" )
    echo ---
    echo START initializing primary database on "pg" = $HOSTNAME = $MYIFADDR

    set -e
    cd /var/lib/postgresql/data;
    initdb -D /var/lib/postgresql/data

    echo `pwd` @ $HOSTNAME
    ls -la | grep -E "(conf$)|(pid$)"

    if [ ! -f postmaster.pid ]; then 
      echo starting the PostgreSQL database
      supervisorctl start postgres
      supervisorctl status postgres
    fi

    echo END initializing primary database on "pg" = $HOSTNAME = $MYIFADDR
    echo ...
  '
fi

# set up configuration files to initialize the hot standby
#   ref: https://wiki.postgresql.org/wiki/Hot_Standby#Configure_the_master_for_WAL_archiving
if [ -f var_lib_postgresql/pg/postgresql.conf -a ! -f var_lib_postgresql/standby/postgresql.conf ]; then
  docker exec -ti -u postgres hotstandby_pg_1 bash -c '
    MYIFADDR=$( python -c "import socket;print socket.gethostbyname('\''$HOSTNAME'\'')" )
    echo ---
    echo START configuring primary database to support initialization of hot backup on "pg" = $HOSTNAME = $MYIFADDR

    set -e
    DOMAIN=$( python -c "import socket;print socket.getfqdn('\''barman'\'')" | sed -e "s/.*\([.][^.]*\)$/\1/" )

    cd /var/lib/postgresql/data;
    echo stop the database to rewrite the configuration files
    if [ -f postmaster.pid ]; then 
      supervisorctl stop postgres
      supervisorctl status postgres
    fi

    echo delete and replace lines of pg_hba.conf necessary to SEED the hot standby
    sed -i -n -e "/b506ea2f41e284465f06c2a7e7dcd561/,/7e9eb140fa111f4af6aae120c59845fc/ d; p" pg_hba.conf
    #
    echo "## b506ea2f41e284465f06c2a7e7dcd561 please leave this line alone ##"   >> pg_hba.conf
    echo "host  all  postgres  pg.$DOMAIN  trust"                                >> pg_hba.conf
    echo "host  all  postgres  barman.$DOMAIN  trust"                            >> pg_hba.conf
    echo "local  replication  postgres  trust"                                   >> pg_hba.conf
    echo "# N.B. Replication cannot be specified in the last line of the file!"  >> pg_hba.conf
    echo "## 7e9eb140fa111f4af6aae120c59845fc please leave this line alone ##"   >> pg_hba.conf

    echo delete and replace lines of postgresql.conf necessary to SEED the hot standby
    sed -i -n -e "/b506ea2f41e284465f06c2a7e7dcd561/,/7e9eb140fa111f4af6aae120c59845fc/ d; p" postgresql.conf
    #
    echo "## b506ea2f41e284465f06c2a7e7dcd561 please leave this line alone ##"   >> postgresql.conf
    echo "wal_level = hot_standby"                                               >> postgresql.conf
    echo "archive_mode = on"                                                     >> postgresql.conf
    echo "max_wal_senders = 3"                                                   >> postgresql.conf
    echo "archive_command = '\''cp -i %p /var/lib/postgresql/archive/%f'\''"     >> postgresql.conf
    echo "## 7e9eb140fa111f4af6aae120c59845fc please leave this line alone ##"   >> postgresql.conf

    echo `pwd` @ $HOSTNAME
    ls -la | grep -E "(conf$)|(pid$)"

    echo start the database to read the rewritten configuration files
    if [ ! -f postmaster.pid ]; then 
      echo starting the PostgreSQL database
      supervisorctl start postgres
      supervisorctl status postgres
    fi

    echo END configuring primary database to support initialization of hot backup on "pg" = $HOSTNAME = $MYIFADDR
    echo ...
  '
fi

# initialize the hot standby only if it does not exist
#   ref: https://wiki.postgresql.org/wiki/Hot_Standby#Use_pg_basebackup_to_copy_the_master_.289.1.2B.29
#        "pg_basebackup doesn't have to be run as the postgres user, that's just convention on unix/linux systems."
if [ ! -f var_lib_postgresql/standby/postgresql.conf ]; then
  docker exec -ti -u postgres hotstandby_pg_1 bash -c '
    MYIFADDR=$( python -c "import socket;print socket.gethostbyname('\''$HOSTNAME'\'')" )
    echo ---
    echo START seeding standby on "pg" = $HOSTNAME = $MYIFADDR

    set -e
    cd /var/lib/postgresql/data;

    echo `pwd` @ $HOSTNAME
    ls -la | grep -E "(conf$)|(pid$)"

    if [ ! -f postmaster.pid ]; then 
      echo starting the PostgreSQL database
      supervisorctl start postgres
      supervisorctl status postgres
    fi

    pg_basebackup -D ../standby --no-password --write-recovery-conf --xlog-method=stream --dbname='\''user=postgres'\''
    cd /var/lib/postgresql/standby

    echo `pwd` @ $HOSTNAME
    ls -la | grep -E "(conf$)|(pid$)"

    echo END seeding standby on "pg" = $HOSTNAME = $MYIFADDR
    echo ...
  '
fi

##### actions on the 'barman' container #####

# configure the hot standby instance to run as a hot standby
#   ref: https://wiki.postgresql.org/wiki/Hot_Standby#Configure_the_copy_of_the_master_to_run_as_a_hot_standby
# Note also: configure to accept connections from 'pg'
# Note well: The 'barman' container is started with -v ./var_lib_postgresql/standby:/var/lib/postgresql/data
if [ -f var_lib_postgresql/standby/postgresql.conf ]; then
  docker exec -ti -u postgres hotstandby_barman_1 bash -c '
    MYIFADDR=$( python -c "import socket;print socket.gethostbyname('\''$HOSTNAME'\'')" )
    echo ---
    echo START configuring standby on "barman" = $HOSTNAME = $MYIFADDR

    set -e
    DOMAIN=$( python -c "import socket;print socket.getfqdn('\''barman'\'')" | sed -e "s/.*\([.][^.]*\)$/\1/" )

    cd /var/lib/postgresql/data;
    echo stop the database to rewrite the configuration files
    if [ -f postmaster.pid ]; then 
      supervisorctl stop postgres
      supervisorctl status postgres
    fi

    echo delete and replace lines of postgresql.conf necessary to RUN the hot standby

    sed -i -n -e "/b506ea2f41e284465f06c2a7e7dcd561/,/7e9eb140fa111f4af6aae120c59845fc/ d; p" postgresql.conf
    #
    echo "## b506ea2f41e284465f06c2a7e7dcd561 please leave this line alone ##"             >> postgresql.conf
    echo "hot_standby = on"                                                                >> postgresql.conf
    echo "port = 5433"                                                                     >> postgresql.conf
    echo "## 7e9eb140fa111f4af6aae120c59845fc please leave this line alone ##"             >> postgresql.conf

    echo delete and replace lines of recovery.conf necessary to RUN the hot standby
    sed -i -n -e "/b506ea2f41e284465f06c2a7e7dcd561/,/7e9eb140fa111f4af6aae120c59845fc/ d; p" recovery.conf
    #
    echo "## b506ea2f41e284465f06c2a7e7dcd561 please leave this line alone ##"             >> recovery.conf
    echo "standby_mode = '\''on'\''"                                                       >> recovery.conf
    echo "restore_command = '\''cp -i /path/to/archive/%f %p'\''"                          >> recovery.conf
    echo "## 7e9eb140fa111f4af6aae120c59845fc please leave this line alone ##"             >> recovery.conf

    echo `pwd` @ $HOSTNAME
    echo delete and replace lines of pg_hba.conf necessary to accept connections from "pg"
    sed -i -n -e "/b506ea2f41e284465f06c2a7e7dcd561/,/7e9eb140fa111f4af6aae120c59845fc/ d; p" pg_hba.conf
    #
    echo "## b506ea2f41e284465f06c2a7e7dcd561 please leave this line alone ##"   >> pg_hba.conf
    echo "host  all  postgres  pg.$DOMAIN  trust"                                >> pg_hba.conf
    echo "host  all  postgres  barman.$DOMAIN  trust"                            >> pg_hba.conf
    echo "## 7e9eb140fa111f4af6aae120c59845fc please leave this line alone ##"   >> pg_hba.conf

    echo `pwd` @ $HOSTNAME
    ls -la | grep -E "(conf$)|(pid$)"

    if [ ! -f postmaster.pid ]; then 
      echo starting the PostgreSQL database
      supervisorctl start postgres
      supervisorctl status postgres
    fi

    echo END configuring standby on "barman" = $HOSTNAME = $MYIFADDR
    echo ...
  '
fi  
