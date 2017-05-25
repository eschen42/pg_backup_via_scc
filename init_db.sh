#!/bin/bash
set -eu
# initialize the primary db if it does not exist
if [ ! -f var_lib_postgresql/pg/postgresql.conf ]; then
  docker exec -ti -u postgres hotstandby_pg_1 bash -c "initdb -D /var/lib/postgresql/data"
fi
# initialize the hot)standby if it does not exist
if [ ! -f var_lib_postgresql/standby/postgresql.conf ]; then
  docker exec -ti -u postgres hotstandby_pg_1 bash -c "initdb -D /var/lib/postgresql/data"
fi
