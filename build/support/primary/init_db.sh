#!/bin/bash

    MYIFADDR=$( python -c "import socket;print socket.gethostbyname('$HOSTNAME')" )

    echo ---
    echo START initializing primary database on "pg" = $HOSTNAME = $MYIFADDR
    echo "       running as $(whoami)"

    set -e
    cd /var/lib/postgresql/data;
    initdb -D /var/lib/postgresql/data

    echo "The contents of `pwd` @ $HOSTNAME are:"
    ls -la | grep -E "(conf$)|(pid$)"

    if [ ! -f postmaster.pid ]; then
      # ensure permissions to start the DB
      chmod 700 /var/lib/postgresql/data
      echo Starting the PostgreSQL database after "initialize the primary db if it does not exist"
      supervisorctl start postgres
      echo The status of the PostgreSQL database after "supervisorctl start postgres" is:
      supervisorctl status postgres
    fi

    echo END initializing primary database on "pg" = $HOSTNAME = $MYIFADDR
    echo ...

