#!/bin/bash
docker-compose -f helpers/production.yml --project-directory . -p pecanswarm "$@"
