#!/bin/bash

if [ -z "$1" ]
  then
    echo "Usage:"
    echo "./create-container.sh /path/to/database/folder"
    exit 1
fi

DBPATH=$1
CONTAINER=firebird-simgest

if [ -d "$DBPATH" ]; then
  ### Take action if $DIR exists ###
  echo "Creating firebird docker container. Data path: '${DBPATH}'"
else
  ###  Control will jump here if $DIR does NOT exists ###
  echo "Error: '${DBPATH}' not found. Can not continue."
  exit 1
fi

docker run -d --name $CONTAINER -p 3050:3050 -v "$DBPATH/data":/firebird firebird-simgest
