# docker Firebird

## About

This repository has been created based on jacobalberty's [docker Firebird](https://hub.docker.com/r/jacobalberty/firebird) container, and modified to fit the needs of our company.

See [https://github.com/jacobalberty/firebird-docker](https://github.com/jacobalberty/firebird-docker)

## Quick start

First, you need to create a directory in your host to hold the database files and configuration files:

```sh
mkdir ~/firebird
mkdir ~/firebird/data
mkdir ~/firebird/config
```

Put the configuration file in `~/firebird/config/firebird.conf`. You can use the example configuration file in this repository.

Create the container image:

```sh
./create-docker-image.sh
```

Then, create the docker container passing the path of the base `firebird` directory you use in the first step. It's important that you don't enter the last slash in the path:

```sh
./create-container.sh ~/firebird        << Do not enter the last slash in the path!!
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

## Get the database password

The database password is randomly generated when the container is first created. It can be found in the file `/firebird/etc/SYSDBA.password`.

```sh
docker exec -t firebird-simgest cat /firebird/etc/SYSDBA.password
  # Firebird generated password for user SYSDBA is:
  #
  ISC_USER=sysdba
  ISC_PASSWORD=d99a0e73dfa740aeb3d4
  #
  # Also set legacy variable though it can't be exported directly
  #
  ISC_PASSWD=d99a0e73dfa740aeb3d4
  #
  # generated at time Tue Oct 10 08:20:18 UTC 2023
  #
  # Your password can be changed to a more suitable one using
  # SQL operator ALTER USER.
  #

```

## Run interactive SQL tool

```sh
docker exec -i -t firebird-simgest /usr/local/firebird/bin/isql
```
