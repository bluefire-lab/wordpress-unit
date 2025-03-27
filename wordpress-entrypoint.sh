#!/bin/bash

set -x

WP_BASE_FOLDER="/opt/tools/wordpress"
WP_FOLDER="/opt/wordpress"
GROUP="wpgroup"
USER="wpuser"

# Check if wordpress folder exists
echo $PWD
ls -las $WP_FOLDER

# Check if wordpress folder is empty
if [ ! -e index.php ] && [ ! -e wp-includes/version.php ]; then
    echo "$0: WordPress folder is empty, copying default content..."
    cp -r $WP_BASE_FOLDER/* $WP_FOLDER/    
else
    echo "$0: WordPress folder is not empty, skipping..."
fi

# pre-create wp-content (and single-level children) for folks who want to bind-mount themes, etc so permissions are pre-created properly instead of root:root
# wp-content/cache: https://github.com/docker-library/wordpress/issues/534#issuecomment-705733507
mkdir -p wp-content
for dir in $WP_BASE_FOLDER/wp-content/*/ cache; do
    dir="$(basename "${dir%/}")"
    mkdir -p "wp-content/$dir"
done

# Copy wp-config.php:
echo "$0: Copying wp-config.php..."
cp /opt/tools/wordpress/wp-config.php $WP_FOLDER/wp-config.php

# Set permissions
echo "$0: Setting permissions..."
chown -R $USER:$GROUP $WP_FOLDER
chmod -R 1755 wp-content

# Is the DEBUG env var set?
if [ "$UNITD_DEBUG" = "true" ]; then
    echo "$0: Running original entrypoint with DEBUG enabled..."
    /usr/local/bin/docker-entrypoint.sh "unitd-debug --no-daemon --control unix:/var/run/control.unit.sock"
else
    echo "$0: Running original entrypoint..."
    /usr/local/bin/docker-entrypoint.sh "$@"
fi

