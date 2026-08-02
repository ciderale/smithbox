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
PROJECT_DIR=/data

# Naming of the image
IMAGE_NAME=docker-devshell
IMAGE="$IMAGE_NAME:latest"

# Naming for the volums
slug() {
	printf '%s' "$1" | tr -c '[:alnum:]._-' '-'
}
HOME_VOLUME=docker-nix-$(slug "$HOME_DIR")
STORE_VOLUME=docker-nix-store

# actual execution
docker build --quiet -t "$IMAGE" .

docker run --rm -ti \
	-v "$STORE_VOLUME:/nix" \
	-e "UID=$NEW_UID" -e "GID=$NEW_GID" \
	-v "$HOME_VOLUME:$HOME_DIR" -e "HOME=$HOME_DIR" \
	-e "MODE=$MODE" \
	-v "$PROJECT_ROOT:$PROJECT_DIR" -w "$PROJECT_DIR" \
	"${DOCKER_RUN_ARGS[@]}" \
	"$IMAGE" "$@"
