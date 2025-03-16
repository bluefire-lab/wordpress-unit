#!/bin/bash

WP_FOLDER="/opt/wordpress"
GROUP="wpgroup"
USER="wpuser"

# Once the wp-content folder is mounted as a volume, check if it's empty
if [ "$(ls -A $WP_FOLDER/wp-content)" ]; then
    echo "wp-content folder is not empty, skipping..."
else
    echo "wp-content folder is empty, copying default content..."
    cp -r /opt/wp-content/* $WP_FOLDER/wp-content/
    # Fix the permissions
    chown -R $USER:$GROUP $WP_FOLDER/wp-content
fi