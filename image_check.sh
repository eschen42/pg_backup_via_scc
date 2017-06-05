#!/bin/bash
# check that the image runs - hit control-C to kill it; --rm makes it clean itself up afterward
docker run --rm -ti -v `pwd`/var_log:/var/log -v `pwd`/build/support:/usr/local/support eschen42/standby-barman:latest
