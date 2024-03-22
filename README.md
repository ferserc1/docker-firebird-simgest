# docker Firebird

## About

This repository has been created based on jacobalberty's [docker Firebird](https://hub.docker.com/r/jacobalberty/firebird) container, and modified to fit the needs of our company.

See [https://github.com/jacobalberty/firebird-docker](https://github.com/jacobalberty/firebird-docker)

## Quick start

First, you need to create a directory in your host to hold the database files:

```sh
mkdir ~/firebird
```

You can customize the configuration file in this repo before creating the container:

`firebird.conf`

Create the container image:

```sh
./create-docker-image.sh
```

Then, create the docker container passing the path of the base `firebird` directory you use in the first step. It's important that you don't enter the last slash in the path:

```sh
./create-container.sh ~/firebird        << Do not enter the last slash in the path!!
```

If the base image has not been previously created, this process can take quite a long time depending on the power of your PC and the number of cores that Docker has configured, as it has to compile Firebird from source code.

## Database files

After the container creation, you can access the Firebird files, including the configuration files, at your `firebird` path. Using the previous path, the configuration file will be placed in:

`~/firebird/etc/firebird.conf`

You can place the database files in the directory:

`~/firebird/data/`

The `data` path in the docker container is `/firebird/data`. To connect to the database, you can place the database files in your `firebird` folder at the host, and use the following connection URL:

`/firebird/data/my_database_file`

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
