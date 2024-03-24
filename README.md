# wp_cubix
A containerized WordPress build using composer for automatic updates and version management.

## Features & Benefits
- Uses ServerSideUp, a production-grade high-performance Apache & PHP image.  Read about it here: https://serversideup.net/open-source/docker-php/docs/getting-started/these-images-vs-others
- Includes WP CLI
- Composer is pre-initialized in the image.
- Lightweight backups -- only wp-content/uploads and composer.json need to be mounted to persistent volumes and backed up. Everything else is ephemeral.
- Built-in path for reverting wordpress core and plugin versions. If core or a plugin upgrade breaks your site, there is a sane path to reverting the stack: just modify composer.json and restart the container.

## Architecture
Dockerfile builds an image containing:
- ServerSideUp Apache & PHP
- WP CLI
- Composer
- An initialized composer project in /var/www/html

~~Docker startup script process:
Checks the env var "wp_run_mode" to determine if the container should run in "upgrade" or "normal".
In "upgrade" mode, the startup script runs composer update to update wordpress core and all plugins. Then it runs the wp upgrade script and terminates the container.
In "normal" mode, the container simply runs apache and hosts the site as normal.~~

~~Host OS Bash run script:
The host bash script will first run the container in 'upgrade' mode, and then rerun it in 'normal' mode as soon.
You can configure the script to run on a nightly cron job to ensure your wordpress installation is always up-to-date.~~

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

Now you can build and run wp_cubix.

`docker build -t wp-cubix .`

To run wp-cubix container, you'll need to specify the following:
- container network
- name of container running mariadb (or mysql)
- http and https port mapping
- persistent volume for /var/www/html/wp-content/uploads
- persistent volume for /var/www/html/composer.json
- log output for the startup script

Logging output for the startup script is important because it lets you keep a history of executions, including the results of 'composer install'. The log file allows you to know exactly what wp core and plugin versions were installed each time the container runs, which will help dramatically if you need to revert a version.

Example Run Command:
```
docker run -d \
  -p 80:80 \
  -p 443:443 \
  -v /path/to/your/uploads:/var/www/html/wp-content/uploads \
  -v /path/to/your/composer.json:/var/www/html/composer.json \
  --network your-container-network \
  -e WP_DB_NAME=db-name
  -e WP_DB_USER=db-user
  -e WP_DB_PASS=db-pwd
  -e WP_DB_HOST=db-container-name
  your-image-tag
 ```

 Instead of the complex Run command, you can use docker compose.  This repo includes a starter docker-compose.yml file. You should make a new copy for each wordpress site you want to run and configure the values in it. Make sure each docker-compose.yml file is in a separate directory. Within one of the directories, you can use 'docker-compose up -d' to launch it.

## Adding Published Wordpress Plugins
Connect to the running container (bash shell login).

Navigate to /var/www/html
Use composer to add plugins, like this:

'composer require wpackagist-plugin/some-plugin-name'

This command adds the plugin to composer.json, specifying the latest version as a minimum.

## Version Management
Every time the container is started, it automatically runs 'composer install', which will install wordpress core and all required plugins according to composer.json.

If you want to target a particular version of wordpress or a plugin, just edit composer.json.  Since you mounted composer.json to a persistent volume, the changes will stick and every start of the container will use your configuration.

## Backups
Make sure you retain backups of all your persistent volumes.
