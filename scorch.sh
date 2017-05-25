#!/bin/sh
set -eu
if [ -z "$(sudo find var_lib_postgresql -name *.pid -print)" ]; then
  echo scorching var_lib_postgresql var_log
  sudo rm -rf var_lib_postgresql var_log
fi

