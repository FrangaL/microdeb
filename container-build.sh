#!/bin/bash -e

DISTRO=$1

CI_REGISTRY_IMAGE=${CI_REGISTRY_IMAGE:-microdeb}
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
BUILD_VERSION=$(date -u +"%Y-%m-%d")
VCS_URL=$(git config --get remote.origin.url)
VCS_REF=$(git rev-parse --short HEAD)

for architecture in $ARCHS; do
  TARBALL=${architecture}.${1}.minbase.tar.xz
  case "${architecture}" in
    amd64) plataform="linux/amd64" ;;
    arm64) plataform="linux/arm64" ;;
    armhf) plataform="linux/arm/7" ;;
  esac

  IMAGE="$DISTRO"
  VERSION="${BUILD_VERSION}"
  RELEASE_DESCRIPTION="$DISTRO"

  if [ -n "$CI_JOB_TOKEN" ]; then
    DOCKER_BUILD="docker buildx build --push --platform=$plataform"
  fi

  $DOCKER_BUILD --progress=plain \
    -t "$CI_REGISTRY_IMAGE"/"$IMAGE":"$VERSION"-"${architecture}" \
    --build-arg TARBALL="$TARBALL" \
    --build-arg BUILD_DATE="$BUILD_DATE" \
    --build-arg VERSION="$VERSION" \
    --build-arg VCS_URL="$VCS_URL" \
    --build-arg VCS_REF="$VCS_REF" \
    --build-arg RELEASE_DESCRIPTION="$RELEASE_DESCRIPTION" \
    .

  cat >"${architecture}-$DISTRO.conf" <<END
CI_REGISTRY_IMAGE="$CI_REGISTRY_IMAGE"
IMAGE="$IMAGE"
VERSION="$VERSION-${architecture}"
END

done
