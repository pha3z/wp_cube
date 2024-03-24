#!/command/with-contenv bash
# https://github.com/just-containers/s6-overlay#container-environment
# Exit on error
set -e

cd /var/www/html/public

yes | composer update
yes | composer install

#you can inject explicit PHP into the config file if necessary. see examples here:
#https://developer.wordpress.org/cli/commands/config/create/
if [ ! -f "config.php" ]; then
	echo "Generating wp-config.php..."
	wp config create /
		--dbname=$WP_DB_NAME /
		--dbuser=$WP_DB_USER /
		--dbpass=$WP_DB_PASS /
		--dbhost=$WP_DB_HOST /
		--locale=en_US-en_US 
else
	echo "Existing wp-config.php found. Using it."
fi

chmod 440 config.php

