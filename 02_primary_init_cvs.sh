#!/bin/bash
# Art Eschenlauer, May 2017 esch0041@umn.edu eschen@alumni.princeton.edu

set -eu

##### actions on the 'pg' container #####

# initialize the CVS repository only if
#   - the sandbox does not exist on the primary, and
#   - the postgresql database does exist 
#   ref: https://wiki.postgresql.org/wiki/Hot_Standby#Create_the_master_database
# Note well: The 'pg' container is started with -v ./var_lib_postgresql/pg:/var/lib/postgresql/data
if [ -f ./var_lib_postgresql/pg/postgresql.conf -a ! -d ./var_lib_postgresql/pg/CVS ]; then
  docker exec -ti -u postgres `cat PROJECT`_pg_1 bash -c '
    MYIFADDR=$( python -c "import socket;print socket.gethostbyname('\''$HOSTNAME'\'')" )
    echo ---
    echo START initializing CVS repo for primary database on "pg" = $HOSTNAME = $MYIFADDR

    /usr/local/support/primary/init_cvs.sh

    echo check for resulting CVSROOT
    ls /var/lib/postgresql/backup
    ls /var/lib/postgresql/backup/data

    echo END initializing CVS repo for primary database on "pg" = $HOSTNAME = $MYIFADDR
    echo ...
  '
else
  echo Cowardly not initializing database because file already exists - ./var_lib_postgresql/pg/postgresql.conf
fi

