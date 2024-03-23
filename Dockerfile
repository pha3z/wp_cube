FROM serversideup/php:8.2-fpm-apache

LABEL maintainer="James Houx (@pha3z)"
LABEL org.opencontainers.image.source https://github.com/pha3z/wp_cubix
LABEL org.opencontainers.image.description "Wordpress with SQLite and streamlined Wordpress version management."

RUN apt-get update && apt-get install -y \
	wget \
	curl \
	unzip \
	&& rm -rf /var/lib/apt/lists/*

# Install Composer globally
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Set the working directory to /var/www/html
WORKDIR /var/www/html

# Initialize a new Composer project (non-interactive mode)
RUN export COMPOSER_ROOT_VERSION=1.0.0
RUN composer init --no-interaction \
	--name pha3z/wp_cubix \
	--description "Wordpress with SQLite and streamlined WP version management." \
	--author "James Houx aka pha3z" \
	--type project \
	--homepage "https://github.com/pha3z/wp_cubix"

#install wordpress with composer
#johnpblock is the well-known/standardized composer repository for wordpress
RUN composer config allow-plugins.johnpbloch/wordpress-core-installer true
RUN composer require johnpbloch/wordpress-core-installer
RUN composer require johnpbloch/wordpress-core

#Add the wppackagist repository, which is where most published WordPress plugins are housed
#This command adds wpackagist to the repositories listing in the composer.json file
RUN composer config repositories.wpackagist composer https://wpackagist.org

#By default, Composer places installed dependencies in a vendor subdirectory.
#You can configure a different destination for your themes and plugins.
#If you want to put them in the normal wp-content folder, you can edit the composer.json
#file to specify "installer-paths".
#Here are some instructions: https://docs.platform.sh/guides/wordpress/composer/migrate.html

# Install WP-CLI globally
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Copy the startup script into the container
COPY startup.sh /usr/local/bin/startup.sh
RUN chmod +x /usr/local/bin/startup.sh

# Use the custom startup script
CMD ["/usr/local/bin/startup.sh"]