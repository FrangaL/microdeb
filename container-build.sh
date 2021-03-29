#!/bin/bash -eu

DISTRO=$1
ARCHITECTURE=$2
TARBALL=$DISTRO-$ARCHITECTURE.minbase.tar.xz

CI_REGISTRY_IMAGE=${CI_REGISTRY_IMAGE:-microdeb}
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
BUILD_VERSION=$(date -u +"%Y-%m-%d")
VCS_URL=$(git config --get remote.origin.url)
VCS_REF=$(git rev-parse --short HEAD)

case "${ARCHITECTURE}" in
  amd64) platform="linux/amd64" ;;
  arm64) platform="linux/arm64" ;;
  armhf) platform="linux/arm/7" ;;
esac

IMAGE="$DISTRO"
VERSION="${BUILD_VERSION}"
RELEASE_DESCRIPTION="$DISTRO"
TAG="$VERSION-${ARCHITECTURE}"

export DOCKER_BUILDKIT=1
docker build \
  --push \
  --platform=$platform \
  --progress=plain \
  -t "$CI_REGISTRY_IMAGE/$IMAGE:$TAG" \
  --build-arg TARBALL="$TARBALL" \
  --build-arg BUILD_DATE="$BUILD_DATE" \
  --build-arg VERSION="$VERSION" \
  --build-arg VCS_URL="$VCS_URL" \
  --build-arg VCS_REF="$VCS_REF" \
  --build-arg RELEASE_DESCRIPTION="$RELEASE_DESCRIPTION" \
  .

cat >"${ARCHITECTURE}-$DISTRO.conf" <<END
CI_REGISTRY_IMAGE="$CI_REGISTRY_IMAGE"
IMAGE="$IMAGE"
TAG=$TAG
VERSION="$VERSION"
END
