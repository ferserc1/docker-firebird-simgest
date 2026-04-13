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

## Run interactive SQL tool

To execute the interactive SQL tool from the container, you don't need any user or password:

```sh
docker exec -i -t firebird-container-name /opt/firebird/bin/isql
```

## Set the password

To change or generate the password for the first time, connect to the isql tool with the security database:

```sh
docker exec -i -t firebird-container-name /opt/firebird/bin/isql /opt/firebird/security3.fdb
```

And set the SYSDBA password using:

```sql
CREATE OR ALTER USER SYSDBA PASSWORD 'masterkey';
COMMIT;
```

> NOTE: you must exit isql tool to apply the changes, because the security3.fdb database will be locked while the isql tool is running



