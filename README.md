# hot_standby

A working model for backing up [PostgreSQL 9.3](https://www.postgresql.org/docs/9.3/static/index.html) with [barman 2.1](http://docs.pgbarman.org/release/2.1/).

For PostgreSQL 9.3, it seems that I need to create a ["hot standby database"](https://www.postgresql.org/docs/9.3/static/hot-standby.html).

This implementation is heavily influenced by [the hot standby article on the PostgreSQL wiki](https://wiki.postgresql.org/wiki/Hot_Standby), which of course says to read the docmentation for full understanding.

## HOW TO use this repository

```bash
# get the code
git clone git@github.umn.edu:esch0041/hot_standby.gitp

# build the docker containers
cd hot_standby/build
# you probably will only have to do this once
sudo ./base_build.sh
# you have to do this the first time each time you change the files to be included
sudo ./update_build.sh

cd ..

# run the suite of containers defined in docker-compose.xml
sudo ./start.sh

# initialize the database, then create the hot standby database
sudo ./init_db.sh

# eventually I will configure barman, but I have not gotten that far yet.
# probably I will put it into a separate script, e.g., init_barman.sh

# when you are done, stop the container
sudo ./stop.sh

# to delete the databases, etc. for a fresh start (this script calls sudo)
./scorch.sh
```
