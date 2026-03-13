#!/bin/bash

if [ -z "$1" ] || [ -z "$2" ]
then
  echo "Usage:"
  echo "./create-container.sh /path/to/database/folder container-name [port]"
  exit 1
fi

DBPATH=$1
CONTAINER=$2
PORT=${3:-3050}

if [ -d "$DBPATH" ]; then
  echo "Creating firebird docker container '${CONTAINER}'. Data path: '${DBPATH}'"
else
  echo "Error: '${DBPATH}' not found. Can not continue."
  exit 1
fi

docker run -d --name "$CONTAINER" -p "$PORT":3050 -v "$DBPATH":/firebird firebird-simgest