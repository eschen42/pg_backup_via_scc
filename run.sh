#!/bin/bash
set -eu
 # start the suite of docker containers for the Galaxy instance
echo running docker-compose up in blocking mode
(
  docker-compose -f docker-compose.yml up
) && (
  echo docker-compose up succeeded
)

