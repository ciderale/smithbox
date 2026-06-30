#!/usr/bin/env bash

trap 'docker compose down -v --timeout 0' EXIT KILL

# rebuild images
#docker compose build squid && docker compose down -v

docker compose up -d squid dns-fw && docker compose run --rm -ti sandbox sh



