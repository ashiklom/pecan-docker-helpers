#!/bin/bash
V=${1:-$(git rev-parse --abbrev-ref HEAD)}
SERVER=172.20.234.6:5000/ TAGS=${V} IMAGE_VERSION=${V} ./release.sh
