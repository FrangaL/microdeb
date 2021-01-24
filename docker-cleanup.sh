#!/bin/sh -e

REPO=$1
REPOSITORY="$DOCKER_HUB_ORGANIZATION/${REPO}"
API_DOCKER_HUB="https://hub.docker.com/v2"

if [ -z "$DOCKER_HUB_USER" ] || [ -z "$DOCKER_HUB_PASS" ]; then
  echo "WARNING: Doing nothing as DOCKER_HUB_USER and/or DOCKER_HUB_PASS are not set"
  exit 0
fi

TOKEN=$(curl -s -H "Content-Type: application/json" -X POST -d '{"username": "'"${DOCKER_HUB_USER}"'", "password": "'"${DOCKER_HUB_PASS}"'"}' $API_DOCKER_HUB/users/login/ | jq -r .token)

for tag in $ARCHS; do
  echo "Trying to delete $REPOSITORY:$tag"
  curl -s -X DELETE -H "Accept: application/json" -H "Authorization: JWT $TOKEN" "$API_DOCKER_HUB/repositories/$REPOSITORY/tags/$tag/"
done
