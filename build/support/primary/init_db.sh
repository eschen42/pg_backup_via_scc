#!/bin/bash

    MYIFADDR=$( python -c "import socket;print socket.gethostbyname('$HOSTNAME')" )

    echo ---
    echo START initializing primary database on "pg" = $HOSTNAME = $MYIFADDR

    set -e
    cd /var/lib/postgresql/data;
    initdb -D /var/lib/postgresql/data

    echo `pwd` @ $HOSTNAME
    ls -la | grep -E "(conf$)|(pid$)"

    if [ ! -f postmaster.pid ]; then
      # ensure permissions to start the DB
      chmod 700 /var/lib/postgresql/data
      echo starting the PostgreSQL database after "initialize the primary db if it does not exist"
      supervisorctl start postgres
      supervisorctl status postgres
    fi

    echo END initializing primary database on "pg" = $HOSTNAME = $MYIFADDR
    echo ...
