#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2026 Alain Lehmann
#
# SPDX-License-Identifier: MIT

: "${DOCKER_BUILD_CONTEXT:=.}"
COMPOSE_ARGS=(-f "$DOCKER_BUILD_CONTEXT/docker-compose.yaml")

docker-compose() {
	docker compose "${COMPOSE_ARGS[@]}" "$@"
}

usage() {
  cat <<EOF
Smithbox: (docker-)sandboxed nix environment

  provide your project specifics via additional
  docker-compose.yaml files. They are merged using
  sensible docker-compose yaml merging rules.

usage $(basename $0) [compose-file*] [command*]

  the first argument which does not qualify as
  docker-compose file (see below) and everything
  after that is treated as command run in the
  docker sandbox container.

treated as docker-compose files:
  <*.yaml>     : any yaml file
  -f <file>    : explicitly listed (possibly non-yaml) file

smithbox provides some sample docker-compose.yaml configuations:
  claude       : mounts current repo and run 'nixpks#claude-code'
  example      : runs some sandbox testing nslookup/curl requests

maintenance command:
  reset-volumes: deletes the sandbox nix store & home volumes

sandbox configuration variables:
  TCP_ALLOWED_HOSTS: allow arbitrary tcp connection to those hosts
  HTTP_DENY_ALL    : deny all http(s) request to theses hosts
  HTTP_ALLOW_ALL   : allow any http(s) request to listed hosts
  HTTP_SAFE_METHODS: allow http(s) with these methods to any host

example docker-compose.configuration:
  services:
    firewall:
      environemnt:
        TCP_ALLOWED_HOSTS: asdf.com jkl.com
    proxy:
      environemnt:
        HTTP_DENY_ALL: bad.com
        HTTP_ALLOW_ALL: my.web.com other.web.org
        HTTP_SAFE_METHODS: get head option
EOF
  exit 1
}

if [ $# = 0 ]; then
  usage
fi

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")
GID=$(id -g)
export PROJECT_ROOT UID GID


while [[ $# -gt 0 ]]; do
  case "${1:-}" in
    --help)
      usage
      ;;
    reset-volumes)
      docker-compose down --volumes
      exit
      ;;
    example|claude)
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

trap 'docker-compose down --timeout 0' EXIT INT TERM HUP

# rebuild images
echo "building images (may take a while)" && docker-compose build -q
docker-compose run --rm -ti sandbox "$@"

