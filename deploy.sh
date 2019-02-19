#!/bin/bash

env $(cat .env | grep ^[A-Z] | xargs) docker stack deploy --compose-file helpers/production.yml ${1:-pecanswarm}
