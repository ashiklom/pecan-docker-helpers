#!/bin/bash
STACK=${1:-pecanswarm}
docker-compose -p ${STACK} config | docker stack deploy --compose-file - ${STACK}
