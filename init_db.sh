#!/bin/bash
set -eu
# initialize the primary db if it does not exist
if [ ! -f var_lib_postgresql/pg/postgresql.conf ]; then
  docker exec -ti -u postgres hotstandby_pg_1 bash -c "initdb -D /var/lib/postgresql/data; supervisorctl start pg_data"
fi
# initialize the hot)standby if it does not exist
if [ ! -f var_lib_postgresql/standby/postgresql.conf ]; then
  docker exec -ti -u postgres hotstandby_pg_1 bash -c "cd /var/lib/postgresql/data; \
    supervisorctl stop pg_data; \
    echo 'host    replication     postgres       trust' >> pg_hba.conf \
    echo '# replication cannot be specified in the last line of the file!' >> pg_hba.conf \
    echo 'wal_level = hot_standby' >> postgresql.conf \
    echo 'archive_mode = on' >> postgresql.conf \
    echo 'max_wal_senders = 3' >> postgresql.conf \
    echo 'archive_command = '\''cp -i %p /export/postgresql/9.3/archive/%f'\' >> postgresql.conf \
    supervisorctl start pg_data; \
    pg_basebackup -D ../archive --no-password --write-recovery-conf --xlog-method=stream --dbname='user=postgres' \
    "
fi
