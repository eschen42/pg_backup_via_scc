#!/bin/sh
set -eu
if [ -d var_lib_postgresql ]; then
  echo scorching var_lib_postgresql
  sudo rm -rf var_lib_postgresql
fi
if [ -d var_log ]; then
  echo scorching var_log
  sudo rm -rf var_log
fi

