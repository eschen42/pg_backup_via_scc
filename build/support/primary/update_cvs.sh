#!/bin/bash
pushd /var/lib/postgresql/data
echo current directory `pwd` = /var/lib/postgresql/data
cvs commit -m "commit changed database files for backup - $(date)"
popd
