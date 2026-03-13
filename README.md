# docker Firebird

## Quick start

First, you need to create a directory in your host to hold the database files:

```sh
mkdir ~/firebird
```

You can customize the configuration file in this repo before creating the container:

`resources/firebird.conf`

Create the container image:

```sh
./create-docker-image.sh
```

Then, create the docker container passing the path of the base `firebird` directory you use in the first step and the container name. It's important that you don't enter the last slash in the path.

```sh
./create-container.sh ~/firebird  my-firebird       << Do not enter the last slash in the path!!
```

Optionally, you can specify the Firebird port to be used in the container. By default, it will be `3050`, but you can change it to any other port if you want by specifying it as the third argument.

```sh
./create-container.sh ~/firebird  my-firebird 3051
```

The process will generate a docker image from almalinux:9.

## Database files

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
