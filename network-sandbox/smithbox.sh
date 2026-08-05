#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2026 Alain Lehmann
#
# SPDX-License-Identifier: MIT

: "${DOCKER_BUILD_CONTEXT:=.}"
COMPOSE_ARGS=(-f "$DOCKER_BUILD_CONTEXT/docker-compose.yaml")

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")
GID=$(id -g)
export PROJECT_ROOT UID GID

while [[ $# -gt 0 ]]; do
  case "${1:-}" in
    claude)
      COMPOSE_ARGS+=(-f "$DOCKER_BUILD_CONTEXT/docker-compose.claude.yaml")
      shift
      ;;
    -f)
      COMPOSE_ARGS+=(-f "$2")
      shift 2
      ;;
    *)
      if [[ -f "$1" ]]; then
        COMPOSE_ARGS+=(-f "$1")
        shift
      else
        break
      fi
      ;;
  esac
done

docker-compose() {
	docker compose "${COMPOSE_ARGS[@]}" "$@"
}

trap 'docker-compose down --timeout 0' EXIT INT TERM HUP

# rebuild images
echo "building images (may take a while)" && docker-compose build -q
docker-compose run --rm -ti sandbox "$@"

