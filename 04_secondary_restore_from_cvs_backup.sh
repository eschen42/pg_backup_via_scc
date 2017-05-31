#!/bin/bash
# Art Eschenlauer, May 2017 esch0041@umn.edu eschen@alumni.princeton.edu

set -eu

##### actions on the 'barman' container #####

# recreate the database from scratch and seed from the backup CVS repo
# Note well: The 'barman' container is started with -v ./var_lib_postgresql/standby:/var/lib/postgresql/data
docker exec -ti -u postgres pggitpg_barman_1 bash -c '
  MYIFADDR=$( python -c "import socket;print socket.gethostbyname('\''$HOSTNAME'\'')" )
  echo ---
  echo START restoring DB from CVS repo for primary database on "barman" = $HOSTNAME = $MYIFADDR

  /usr/local/support/restore_db_from_cvs_backup.sh

  echo END restoring DB from CVS repo for primary database on "barman" = $HOSTNAME = $MYIFADDR
  echo ...
'

