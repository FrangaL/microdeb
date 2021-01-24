#!/bin/sh -e

DISTRO=$1

for architecture in $ARCHS; do
  # Retrieve variables from former docker-build.sh
  # shellcheck source=/dev/null
 . ./"${architecture}"-"${DISTRO}".conf

  if [ -n "$CI_JOB_TOKEN" ]; then
    echo "$CI_JOB_TOKEN" | docker login -u "$CI_REGISTRY_USER" --password-stdin "$CI_REGISTRY"
    docker pull "$CI_REGISTRY_IMAGE/${IMAGE:=}:$VERSION"

    DOCKER_HUB_REGISTRY="docker.io"
    echo "$DOCKER_HUB_ACCESS_TOKEN" | docker login -u "$DOCKER_HUB_USER" --password-stdin "$DOCKER_HUB_REGISTRY"
    docker tag "$CI_REGISTRY_IMAGE/${IMAGE}:$VERSION" "$DOCKER_HUB_ORGANIZATION/${IMAGE}:$architecture"
    docker push "$DOCKER_HUB_ORGANIZATION/${IMAGE}:$architecture"
    docker rmi "$CI_REGISTRY_IMAGE/${IMAGE}:$VERSION"
  else
    docker tag "$CI_REGISTRY_IMAGE/$IMAGE:$VERSION" "$CI_REGISTRY_IMAGE/$IMAGE:latest"
  fi

done

if [ -n "$CI_JOB_TOKEN" ]; then
  IMAGES=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep "$DOCKER_HUB_ORGANIZATION" | tr '\n' ' ')
  # shellcheck disable=SC2086
  docker manifest create "$DOCKER_HUB_ORGANIZATION/${IMAGE}:latest" $IMAGES
  docker manifest push -p "$DOCKER_HUB_REGISTRY/$DOCKER_HUB_ORGANIZATION/${IMAGE}:latest"
  for img in $IMAGES; do
    docker rmi "$img"
  done
fi
