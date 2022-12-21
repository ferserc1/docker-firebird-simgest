# docker Firebird

## About

This repository has been created based on jacobalberty's [docker Firebird](https://hub.docker.com/r/jacobalberty/firebird) container, and modified to fit the needs of our company.

See [https://github.com/jacobalberty/firebird-docker](https://github.com/jacobalberty/firebird-docker)

## Quick start

First, you need to create a directory in your host to hold the database files. You can put the databases in that directory. For example, we'll use `~/firebird`. Then, build the image and create the container with the following commands:

```sh
./create-docker-image.sh
./create-container.sh ~/firebird
```

If the base image has not been previously created, this process can take quite a long time depending on the power of your PC and the number of cores that Docker has configured, as it has to compile Firebird from source code.

When finished, the access information to the database (user and password) will be printed on the terminal.

```sh
./create-container.sh ~/firebird_db/data
Creating firebird docker container. Data path: '/Users/fernando/firebird_db/data'
ad7db9b65aa4cfefdeb62c4e85acaff55a7ff4c08914b0fdbe9876a0a3e594be
Container created with the following authentication data:
ISC_USER=sysdba
ISC_PASSWORD=qqYHFYG0IACNRGygB6hZ
```

## Build image

Firebird is compiled from source code, so it is advisable to configure Docker to have as many CPUs as possible, at least during compilation.

```sh
./create-docker-image.sh
```

## Launch container

To launch the container using `~/firebird_db/data` as database path, use:

```sh
docker run -d --name firebird-simgest -p 3050:3050 -v ~/firebird_db/data/:/firebird/data firebird-simgest
```

Or change the `-v` parameter to use another path. `-v /other/host/data/path/:/firebird/data`

You can also use the included script `create-container.sh`, specifying the database path as a parameter.

## Get the database password

The database password is randomly generated when the container is first created. It can be found in the file `/firebird/etc/SYSDBA.password`.

```sh
docker exec -t firebird-simgest cat /firebird/etc/SYSDBA.password
```

## Run interactive SQL tool

```sh
docker exec -i -t firebird-simgest /usr/local/firebird/bin/isql
```
