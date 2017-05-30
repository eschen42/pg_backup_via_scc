# pg_backup_via_git

A working model for backing up [PostgreSQL 9.3](https://www.postgresql.org/docs/9.3/static/index.html) with git.  I want this to back up the Galaxy database.

My strategy here is to use [pg_dumpall](https://www.postgresql.org/docs/9.3/static/backup-dump.html#BACKUP-DUMP-ALL) to dump the database cluster, use git to back it up along with the .conf files, and to restore to a freshly created database.  This is what the `test_sequence_01.sh` script does.

Provided that git has low enough overhead, it might help with backing up Galaxy "data sets" as well.  Otherwise, I may have to resort to one-way rsync without replication of deletions.  A more obvious long-term backup strategy for Galaxy data sets would be to use S3/Ceph or some other block storage implementation.

I imagine that it would be much more scalable to back up postgres with [barman](http://docs.pgbarman.org/release/2.1/).
For PostgreSQL 9.3, however, it seems that "exclusive access" may be required to back up the database, implying I would need to create a ["hot standby database"](https://www.postgresql.org/docs/9.3/static/hot-standby.html).  Implementation could be heavily influenced by [the hot standby article on the PostgreSQL wiki](https://wiki.postgresql.org/wiki/Hot_Standby), which of course says to read the docmentation for full understanding.

## HOW TO use this repository

```bash
### Get the code
git clone git@github.umn.edu:esch0041/pg_backup_via_git.gitp

### Build the docker containers
cd pg_backup_via_git/build

#### You probably will only have to do this once
sudo ./base_build.sh

#### You have to do this the first time *and* 
#    each time you change the files to be included
sudo ./update_build.sh

cd ..

### Run the suite of containers defined in docker-compose.xml
sudo ./start.sh

### Run a sequence of test operations to demonstrate 
#   that the restored database reflects the one backed up
sudo ./test_sequence_01.sh

### When you are done, stop the containers
sudo ./stop.sh

### For a fresh start *after* you stop the containers
#   to delete the databases, etc. (this script calls sudo)
./scorch.sh
```
