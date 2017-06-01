# pg_backup_via_scc - EXPERIMENTAL - WORK IN PROGRESS

This repository presents a working model for backing up and restoring [PostgreSQL 9.3](https://www.postgresql.org/docs/9.3/static/index.html) with git or cvs.  I ultimately want to use this to back up the database for [Galaxy](https://galaxyproject.org/).  **Please use this repository at your own risk;** while I would welcome pull requests, I'm not certain how quickly I can get to act on them.

My strategy in this project is to use [pg_dumpall](https://www.postgresql.org/docs/9.3/static/backup-dump.html#BACKUP-DUMP-ALL) to dump the database cluster, use git or cvs to back it up along with the .conf files, and to restore to a freshly created database.  This is what the `test_sequence_cvs_01.sh` and `test_sequence_git_01.sh` scripts do.

Provided that git or cvs has low enough overhead, one or both of them might help with backing up Galaxy "data sets" as well.  Otherwise, I may have to resort to one-way rsync without replication of deletions.  A more obvious long-term backup strategy for the Galaxy data sets themselves would be to use S3/Ceph or some other block storage implementation.

In this very specific case, cvs seems to me to have the edge over git because of the fact that cvs is oriented toward diffs in text-files.  While git is designed to address the shortcomings that this orientation presents for source code control, in this case its repository grows greatly even when there are minor differences between two copies of the output of pg_dumpall, whereas cvs merely stores a small diff.  This project allows you to compare them and decide for yourself; maybe you would like to add mercurial to the mix....

I imagine that it would be much more scalable to back up postgres with [barman](http://docs.pgbarman.org/release/2.1/).
For PostgreSQL 9.3, however, I got the impression (from an error message) that "exclusive access" may be required to back up the database, implying I would need to create a ["hot standby database"](https://www.postgresql.org/docs/9.3/static/hot-standby.html).  Implementation of backup with barman and hot_standby would likely be heavily influenced by [the hot standby article on the PostgreSQL wiki](https://wiki.postgresql.org/wiki/Hot_Standby), which of course says to read the docmentation for full understanding.

## HOW TO use this repository

```bash
### Clone the code
git clone ...

### Change to the repository directory
cd ...

### Build the docker containers
pushd build

#### You probably will only have to do this once
sudo ./base_build.sh

#### You have to do this the first time *and* 
#    each time you change the files to be included
sudo ./update_build.sh

### Run the suite of containers defined in docker-compose.xml
popd
sudo ./start.sh

### Run a sequence of test operations to demonstrate 
#   that the restored database reflects the one backed up when using cvs
sudo ./test_sequence_cvs_01.sh
#   that the restored database reflects the one backed up when using git
sudo ./test_sequence_git_01.sh

### When you are done, stop the containers
sudo ./stop.sh

### For a fresh start *after* you stop the containers
#   to delete the databases, etc. (this script calls sudo)
./scorch.sh
```
