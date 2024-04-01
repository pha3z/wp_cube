# wp_cubix
A containerized WordPress build using composer for automatic updates and version management.

## Features & Benefits
- Uses ServerSideUp, a production-grade high-performance Apache & PHP & Composer image.  Read about it here: https://serversideup.net/open-source/docker-php/docs/getting-started/these-images-vs-others
- Includes WP CLI
- Lightweight backups -- only wp-content/uploads and composer.json need to be mounted to persistent volumes and backed up. Everything else is ephemeral.
- Built-in path for reverting wordpress core and plugin versions. If core or a plugin upgrade breaks your site, there is a sane path to reverting the stack: just modify composer.json to force a previous version and restart the container.

## Architecture
Dockerfile builds an image containing:
- ServerSideUp (Apache & PHP & Composer)
- WP CLI
- An initialized composer project in /var/www/html

## Usage
You first need a docker network with a mariadb (or mysql) running and configured.
https://hub.docker.com/_/mariadb

`docker pull mariadb`

`docker network create your-container-network`

`docker run -d \
	--name wp-mariadb \
	-p 3600:3600 \
	-v /path/to/your/datadir:/var/lib/mysql:Z \
	-e \
	MARIADB_ROOT_PASSWORD=my-secret-pw \
	--network your-container-network
	--mariadb`

Connect to the container. Then connect to mariadb to add a user and a database.

`docker exec -it wp-mariadb /bin/bash`

`mariadb -p`

`CREATE DATABASE my_wp_db DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
GRANT ALL ON my_wp_db.* TO 'database_user'@'localhost' IDENTIFIED BY 'password';
FLUSH PRIVILEGES;
EXIT;`

If you need to import an existing database from a dump file, do it now.

---

Setup your directory structure so that you can easily support multiple wordpress sites:
somepath/wp_cubix/git
somepath/wp_cubix/wpsite1
somepath/wp_cubix/wpsite2
somepath/wp_cubix/wpsite3

Use git clone to clone this repositor into somepath/wp_cubix/git

Build wp_cubix from that folder:

`docker build -t wp-cubix .`

Copy the contents of "your-live-operations-folder" from this repo into somepath/wp_cubix/wpsite1
Change directory to somepath/wp_cubix/wpsite1
Open docker-compose.yml and configure database environment vars.
To launch the container and site, execute ./start.sh

To stop the site, run 'docker compose down' in the same folder.

## Adding Published Wordpress Plugins
You can either edit the composer.json persisted volume file directly, or connect to the running container (bash shell login) and use composer commands.

For the running container method, connect to the container with docker exec -it containerName /bin/bash
Navigate to /var/www/html
Use composer to add plugins, like this:

'composer require wpackagist-plugin/some-plugin-name'

This command adds the plugin to composer.json, specifying the latest version as a minimum.

## Version Management
Every time the container is started, it automatically runs 'composer install', which will install wordpress core and all required plugins according to composer.json.

If you want to target a particular version of wordpress or a plugin, just edit composer.json.  Since you mounted composer.json to a persistent volume, the changes will stick and every start of the container will use your configuration.

## Backups
Make sure you retain backups of all your persistent volumes.

## Use Caddy
Caddy web server is a non-nonsense easy way to setup a reverse proxy to direct your server traffic to the various wordpress sites you have running.