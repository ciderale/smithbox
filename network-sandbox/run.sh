#!/usr/bin/env bash

COMPOSE_ARGS=(
		-f docker-compose.yaml
		-f docker-compose.sandbox.yaml
	)

docker-compose() {
	docker compose "${COMPOSE_ARGS[@]}" "$@"
}

trap 'docker-compose down --timeout 0' EXIT KILL

# rebuild images
docker-compose build -q &&
	docker-compose run --rm -ti sandbox "$@"

