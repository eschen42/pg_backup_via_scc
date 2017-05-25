#!/bin/bash
set -eu

# stop the suite of docker containers for the Galaxy instance
echo running docker-compose down
(
  docker-compose -f docker-compose.yml down
) && (
  echo docker-compose down succeeded
)


echo cleaning up volumes that will never be used again
docker volume rm $( docker volume ls -q -f 'dangling=true' )

echo clean-up completed

