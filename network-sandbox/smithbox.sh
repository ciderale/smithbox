#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2026 Alain Lehmann
#
# SPDX-License-Identifier: MIT

: "${DOCKER_BUILD_CONTEXT:=.}"
COMPOSE_ARGS=(
    -f "$DOCKER_BUILD_CONTEXT/docker-compose.yaml"
)
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")
GID=$(id -g)
export PROJECT_ROOT UID GID

while [[ "${1:-}" == "-f" ]]; do
    shift
    if [[ -z "${1:-}" ]]; then
        echo "missing argument for -f" >&2
        exit 1
    fi
    COMPOSE_ARGS+=(-f "$1")
    shift
done

docker-compose() {
	docker compose "${COMPOSE_ARGS[@]}" "$@"
}

trap 'docker-compose down --timeout 0' EXIT INT TERM HUP

# rebuild images
docker-compose build -q &&
	docker-compose run --rm -ti sandbox "$@"

