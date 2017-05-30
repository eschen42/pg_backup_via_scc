#!/bin/bash
sudo ./stop.sh 
./scorch.sh 
set -e
sudo ./start.sh 
sudo ./01_primary_init_db.sh 
sudo ./02_primary_init_git.sh 
sudo ./03_secondary_restore_from_backup.sh 
sudo ls   ./var_lib_postgresql/standby                 ./var_lib_postgresql/pg
sudo wc   ./var_lib_postgresql/standby/pg_restored.sql ./var_lib_postgresql/pg/pg_dumpall.sql 
sudo diff ./var_lib_postgresql/standby/pg_restored.sql ./var_lib_postgresql/pg/pg_dumpall.sql 
