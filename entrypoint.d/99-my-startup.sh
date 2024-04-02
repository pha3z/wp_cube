#!/bin/sh
# Exit on error
set -e

echo "Executing wp-cubix startup script..."

echo "DOC_ROOT (HTML Directory / Document Root): $DOC_ROOT"
echo "WP_DIR (Wordpress Directory): $WP_DIR"

cd $DOC_ROOT
export COMPOSER_PROCESS_TIMEOUT=1200
echo "composer update"
yes | composer update
echo "composer innstall"
yes | composer install

#wp cli must be run from the wordpress folder
#moreover, the wp-settings.php and wp-config.php files must both be visible to wp cli within that folder.
#--allow-root is necessary because the container startup script runs as root. wp cli will throw a big warning/failure if you don't have --allow-root
alias wp='wp --allow-root --path=$WP_DIR'

#about wordpress salts (in wp-config.php): https://kinsta.com/knowledgebase/wordpress-salts/
#about relocating wp-config.php: https://wordpress.stackexchange.com/questions/58391/is-moving-wp-config-outside-the-web-root-really-beneficial

#we re-generate wp-config.php *every time* we launch the container.
#this is because wp-config.php contains the salts and good practice is to regenerate salts periodically.
#the salts do not need to persist! :D

#additionally, it is possible to inject explicit PHP into the config file if necessary. See examples here:
#https://developer.wordpress.org/cli/commands/config/create/
#this means if we need to add custom defines() or other code for any reason, we could drop it into the environment variable so its injected here
#there are many ways to inject PHP. see here for more thorough coverage: https://github.com/wp-cli/wp-cli/issues/1046
#1) You can rely on STDIN.  eek?
#2) You can pipe it in like this: echo "your php" | wp config create ...
#3) You can pass it as a string following equals sign like this: --extra-php="your string"
#4) You can pipe it in from a file: tail -n+2 path/to/file.php | wp core config --extra-php --dbname="lorem" ...
#So for our case shown below, just add your PHP to WP_CONFIG_EXTRA_PHP as a one-liner in the docker-compose.yml file

cd $WP_DIR

echo "Generating wp-config.php..."
echo "WP_DB_NAME: $WP_DB_NAME"
echo "WP_DB_USER: $WP_DB_USER"
echo "WP_DB_HOST: $WP_DB_HOST"

wp config create \
	--dbname="$WP_DB_NAME" \
	--dbuser="$WP_DB_USER" \
	--dbpass="$WP_DB_PASS" \
	--dbhost="$WP_DB_HOST" \
	--locale="en_US-en_US" \
	--extra-php="$WP_CONFIG_EXTRA_PHP"

chmod 440 wp-config.php
chown www-data:www-data wp-config.php
mv wp-config.php ../../wp-config-super-secret-location.php #renaming the file isn't the point, but we do it cuz we might as well. Moving the file is the point.

#Create a proxy wp-config.php file to process the real wp-config.php
cat << 'EOF' > wp-config.php
<?php
/** Absolute path to the WordPress directory. */
if ( !defined('MY_WP_PATH') )
    define('MY_WP_PATH', dirname(__FILE__) . '/');

/** Location of your WordPress configuration. */
require_once(MY_WP_PATH . '../../wp-config-super-secret-location.php');
?>
EOF

chmod 440 wp-config.php

echo "WP_UPLOADS_EXTERNAL_DIR: $WP_UPLOADS_EXTERNAL_DIR"
echo "Creating symlink: $WP_DIR/wp-content/uploads  TARGET: $WP_UPLOADS_EXTERNAL_DIR"
ln -s $WP_UPLOADS_EXTERNAL_DIR $WP_DIR/wp-content/uploads 

echo "Setting www-data:www-data as owner on $WP_DIR/wp-content/uploads"
chown www-data:www-data $WP_DIR/wp-content/uploads
echo "Setting CHMOD to 755 on $WP_DIR/wp-content/uploads"
chmod 755 $WP_DIR/wp-content/uploads

echo "Setting www-data:www-data as owner on $DOC_ROOT (recursively)"
chown -R www-data:www-data $DOC_ROOT