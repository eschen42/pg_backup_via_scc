#!/bin/bash
set -eu
 # start the suite of docker containers for the Galaxy instance
echo running docker-compose up in blocking mode
(
  docker-compose -f docker-compose.yml up
) && (
  echo docker-compose up succeeded
)

echo cleaning up volumes that will never be used again
docker volume rm $( docker volume ls -q -f 'dangling=true' )

echo clean-up completed
