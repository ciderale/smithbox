#!/usr/bin/env bash

PROJECT_ROOT="$PWD/.."
PROJECT_DIR=/data
HOME_DIR=/home/ale
NEW_UID=$(id -u)
NEW_GID=$(id -g)
#MODE=plain
#MODE=nix-develop
MODE=direnv

IMAGE_NAME=docker-devshell
IMAGE="$IMAGE_NAME:latest"

slug() {
	printf '%s' "$1" | tr -c '[:alnum:]._-' '-'
}
HOME_VOLUME=docker-nix-$(slug "$HOME_DIR")
STORE_VOLUME=docker-nix-store


docker build --quiet -t "$IMAGE" .

docker run --rm -ti \
	-v "$STORE_VOLUME:/nix" \
	-e UID=$NEW_UID -e GID=$NEW_GID \
	-v $HOME_VOLUME:$HOME_DIR -e HOME=$HOME_DIR\
	-e MODE=$MODE \
	-v "$PROJECT_ROOT:$PROJECT_DIR" -w "$PROJECT_DIR" \
	"$IMAGE" "$@"
