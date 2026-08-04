#!/usr/bin/env bash

: "${DOCKER_BUILD_CONTEXT:=.}"
COMPOSE_ARGS=(
    -f "$DOCKER_BUILD_CONTEXT/docker-compose.yaml"
    -f "$DOCKER_BUILD_CONTEXT/docker-compose.sandbox.yaml"
)

docker-compose() {
	docker compose "${COMPOSE_ARGS[@]}" "$@"
}

trap 'docker-compose down --timeout 0' EXIT INT TERM HUP

# rebuild images
docker-compose build -q &&
	docker-compose run --rm -ti sandbox "$@"

