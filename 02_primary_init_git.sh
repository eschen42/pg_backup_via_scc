#!/bin/bash
# Art Eschenlauer, May 2017 esch0041@umn.edu eschen@alumni.princeton.edu

set -eu

##### actions on the 'pg' container #####

# initialize the primary git repository only if
#   - it does not exist, and
#   - the postgresql database does exist 
#   ref: https://wiki.postgresql.org/wiki/Hot_Standby#Create_the_master_database
# Note well: The 'pg' container is started with -v ./var_lib_postgresql/pg:/var/lib/postgresql/data
if [ -f ./var_lib_postgresql/pg/postgresql.conf -a ! -d ./var_lib_postgresql/pg/.git ]; then
  docker exec -ti -u postgres `cat PROJECT`_pg_1 bash -c '
    MYIFADDR=$( python -c "import socket;print socket.gethostbyname('\''$HOSTNAME'\'')" )
    echo ---
    echo START initializing git repo for primary database on "pg" = $HOSTNAME = $MYIFADDR

    /usr/local/support/primary/init_git.sh

    echo END initializing git repo for primary database on "pg" = $HOSTNAME = $MYIFADDR
    echo ...
  '
else
  echo Cowardly not initializing database because file already exists - ./var_lib_postgresql/pg/postgresql.conf
fi

