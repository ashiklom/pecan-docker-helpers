#!/bin/bash
docker-compose -p pecanswarm up -d postgres
#docker run -it --rm --network pecanswarm_pecan pecan/bety:latest initialize
#docker run -it --rm --network pecanswarm_pecan pecan/bety:develop migrate
docker run -it --rm --network pecanswarm_pecan --volume pecanswarm_pecan:/data --env FQDN=docker pecan/data:develop
docker-compose -p pecanswarm down
