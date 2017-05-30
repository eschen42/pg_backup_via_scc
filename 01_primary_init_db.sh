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
if [ ! -f ./var_lib_postgresql/pg/postgresql.conf ]; then
  #  docker exec -ti -u postgres hotstandby_pg_1 bash -c '
  #    MYIFADDR=$( python -c "import socket;print socket.gethostbyname('\''$HOSTNAME'\'')" )
  #    echo ---
  #    echo START initializing primary database on "pg" = $HOSTNAME = $MYIFADDR
  # 
  #    set -e
  #    cd /var/lib/postgresql/data;
  #    initdb -D /var/lib/postgresql/data
  # 
  #    echo `pwd` @ $HOSTNAME
  #    ls -la | grep -E "(conf$)|(pid$)"
  # 
  #    if [ ! -f postmaster.pid ]; then
  #      # ensure permissions to start the DB
  #      chmod 700 /var/lib/postgresql/data
  #      echo starting the PostgreSQL database after "initialize the primary db if it does not exist"
  #      supervisorctl start postgres
  #      supervisorctl status postgres
  #    fi
  # 
  #    echo END initializing primary database on "pg" = $HOSTNAME = $MYIFADDR
  #    echo ...
  #  '
  docker exec -ti -u postgres hotstandby_pg_1 bash -c '
    MYIFADDR=$( python -c "import socket;print socket.gethostbyname('\''$HOSTNAME'\'')" )
    echo ---
    echo START initializing primary database on "pg" = $HOSTNAME = $MYIFADDR

    /usr/local/support/primary/init_db.sh

    echo END initializing primary database on "pg" = $HOSTNAME = $MYIFADDR
    echo ...
  '
else
  echo Cowardly not initializing database because file already exists - ./var_lib_postgresql/pg/postgresql.conf
fi

