#!/bin/bash
set -eu
PG_UID=1550
PG_GID=1550
if [ ! -d var_lib_postgresql ]; then mkdir var_lib_postgresql; fi
chown $PG_UID:$PG_GID var_lib_postgresql
if [ ! -d var_lib_postgresql/archive ]; then mkdir var_lib_postgresql/archive; fi
chown $PG_UID:$PG_GID var_lib_postgresql/archive
 # start the suite of docker containers for the Galaxy instance
echo running docker-compose up in daemon mode
(
  docker-compose -p pggitpg -f docker-compose.yml up -d
) && (
  echo docker-compose up succeeded
)

