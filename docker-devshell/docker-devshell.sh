#!/usr/bin/env bash
set -Eeuo pipefail

# host location of the project (use git root unless specified)
: "${PROJECT_ROOT:=$(git rev-parse --show-toplevel)}"

#the method to setup the dev environment
#MODE=plain
#MODE=nix-develop
MODE=direnv

# various settings for the container environment
# note: home is not mounted, but serves for persisting across sessions
HOME_DIR="$HOME"
NEW_UID="$(id -u)"
NEW_GID="$(id -g)"
PROJECT_DIR=/project

# Naming of the image
: "${DOCKERFILE:=../network-sandbox/Dockerfile.docker-devshell}"
IMAGE_NAME=docker-devshell
TAG=$(sha256sum "$DOCKERFILE" | awk '{print $1}')
IMAGE="$IMAGE_NAME:$TAG"

# Naming for the volums
slug() {
	printf '%s' "$1" | tr -c '[:alnum:]._-' '-'
}
HOME_VOLUME=docker-nix-$(slug "$HOME_DIR")
STORE_VOLUME=docker-nix-store

if [ "${DOCKER_DEVSHELL_RESET:-false}" == "true" ]; then
	echo "NOTE: Resetting docker volumes"
	set -x
	docker volume rm "$HOME_VOLUME" "$STORE_VOLUME" || echo "Issue in volume reset"
	set +x
fi

# Build image if necessary
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
	cat "$DOCKERFILE" | docker build -t "$IMAGE" -
fi

# Run the environment
docker run --rm -ti \
	-v "$STORE_VOLUME:/nix" \
	-e "UID=$NEW_UID" -e "GID=$NEW_GID" \
	-v "$HOME_VOLUME:$HOME_DIR" -e "HOME=$HOME_DIR" \
	-e "MODE=$MODE" \
	-v "$PROJECT_ROOT:$PROJECT_DIR" -w "$PROJECT_DIR" \
	"${DOCKER_RUN_ARGS[@]}" \
	"$IMAGE" "$@"
