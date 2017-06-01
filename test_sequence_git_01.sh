#!/bin/bash
sudo ./stop.sh
./scorch.sh
set -e
sudo ./start.sh
sudo ./01_primary_init_db.sh
sudo ./02_primary_init_git.sh
sudo ./04_secondary_restore_from_git_backup.sh
sudo ls   ./var_lib_postgresql/standby                 ./var_lib_postgresql/pg
if [ ! -f ./var_lib_postgresql/standby/pg_restored.sql ]; then
  echo "ALERT pg_restored.sql is missing!"
fi
sudo wc   ./var_lib_postgresql/standby/pg_restored.sql ./var_lib_postgresql/pg/pg_dumpall.sql
sudo diff ./var_lib_postgresql/standby/pg_restored.sql ./var_lib_postgresql/pg/pg_dumpall.sql
