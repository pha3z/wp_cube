FROM serversideup/php:8.2-fpm-apache

LABEL maintainer="James Houx (@pha3z)"
LABEL org.opencontainers.image.source https://github.com/pha3z/wp_cubix
LABEL org.opencontainers.image.description "Wordpress with SQLite and streamlined Wordpress version management."

RUN apt-get update && apt-get install -y \
	wget \
	curl \
	unzip \
	htop \
	&& rm -rf /var/lib/apt/lists/*

# Install Php Composer globally
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Set the working directory to /var/www/html
WORKDIR /var/www/html

# Initialize a new Php Composer project (non-interactive mode)
RUN export COMPOSER_ROOT_VERSION=1.0.0
RUN composer init --no-interaction \
	--name pha3z/wp_cubix \
	--description "Wordpress streamlined WP version management." \
	--author "James Houx aka pha3z" \
	--type project \
	--homepage "https://github.com/pha3z/wp_cubix"

#install wordpress with Php Composer
#johnpblock is the well-known/standardized composer repository for wordpress
RUN composer config allow-plugins.johnpbloch/wordpress-core-installer true
RUN composer require johnpbloch/wordpress-core-installer
RUN composer require johnpbloch/wordpress-core

#Add the wpackagist repository, which is where most published WordPress plugins are housed
#This command adds wpackagist to the repositories listing in the composer.json file
RUN composer config repositories.wpackagist composer https://wpackagist.org

#By default, Php Composer places installed dependencies in a vendor subdirectory.
#You can configure a different destination for your themes and plugins.
#If you want to put them in the normal wp-content folder, you can edit the composer.json
#file to specify "installer-paths".
#Here are some instructions: https://docs.platform.sh/guides/wordpress/composer/migrate.html

# Install WP-CLI globally
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# serversideup/php requires you to add custom startup script in specific manner
# https://serversideup.net/open-source/docker-php/docs/guide/adding-your-own-start-up-scripts
COPY --chmod=755 ./entrypoint.d/ /etc/entrypoint.d/