#!/usr/bin/env bash

trap 'docker compose down --timeout 0' EXIT KILL

# rebuild images
docker compose build -q &&
	docker compose run --rm -ti sandbox sh



