# wp_cube
A containerized WordPress build using composer for automatic updates and version management.

## Features & Benefits
- Uses ServerSideUp, a production-grade high-performance Apache & PHP image
- Includes WP CLI
- Composer is pre-initialized in the image.
- Lightweight backups -- because only wp-content/uploads, composer.json, and sqlite database need to be mounted to persistent volumes and backed up. Everything else is ephemeral.
- Built-in path for reverting wordpress core and plugin versions. If core or a plugin upgrade breaks your site, there is a sane path to reverting the stack: just modify composer.json and restart the container.

## Architecture
Dockerfile builds an image containing:
- ServerSideUp Apache & PHP
- WP CLI
- Composer
- An initialized composer project in /var/www/html

Docker startup script process:
Checks the env var "wp_run_mode" to determine if the container should run in "upgrade" or "normal".
In "upgrade" mode, the startup script runs composer update to update wordpress core and all plugins. Then it runs the wp upgrade script and terminates the container.
In "normal" mode, the container simply runs apache and hosts the site as normal.

Host OS Bash run script:
The host bash script will first run the container in 'upgrade' mode, and then rerun it in 'normal' mode as soon.
You can configure the script to run on a nightly cron job to ensure your wordpress installation is always up-to-date.
