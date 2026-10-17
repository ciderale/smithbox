#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2026 Alain Lehmann
#
# SPDX-License-Identifier: MIT

: "${DOCKER_BUILD_CONTEXT:=.}"
COMPOSE_ARGS=(-f "$DOCKER_BUILD_CONTEXT/docker-compose.base.yaml")

docker-compose() {
	docker compose "${COMPOSE_ARGS[@]}" "$@"
}

usage() {
  cat $DOCKER_BUILD_CONTEXT/usage.txt
  exit 1
}

if [ $# = 0 ]; then
  usage
fi

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")
PROJECT_NAME=$(basename "$PROJECT_ROOT")
GID=$(id -g)
export PROJECT_ROOT PROJECT_NAME UID GID

while [[ $# -gt 0 ]]; do
  case "${1:-}" in
    --help)
      usage
      ;;
    shutdown)
      docker-compose down --timeout 0
      exit
      ;;
    reset-volumes)
      docker-compose down --volumes
      exit
      ;;
    project|sandbox|allowget|claude|testing)
      COMPOSE_ARGS+=(-f "$DOCKER_BUILD_CONTEXT/docker-compose.$1.yaml")
      shift
      ;;
    -f)
      COMPOSE_ARGS+=(-f "$2")
      shift 2
      ;;
    *.yaml)
      COMPOSE_ARGS+=(-f "$1")
      shift
      ;;
    *)
      break
      ;;
  esac
done

function cleanup() {
  project=$(docker-compose config --format json | jq -r '.name')
  if docker ps -q \
      --filter "label=com.docker.compose.project=$project" \
      --filter "label=com.docker.compose.service=sandbox" |
      grep -q .; then
      echo "keep environemnt running due to active sandboxes"
  else
      echo "no more sandbox running. shutting down"
      $0 "${COMPOSE_ARGS[@]}" shutdown
  fi
}

trap cleanup EXIT INT TERM HUP

# rebuild images
echo "building docker images (may take a while)" && docker-compose build -q
docker-compose run --rm -ti sandbox "$@"

