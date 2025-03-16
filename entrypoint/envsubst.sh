#!/bin/sh
set -e

export PHP_POST_MAX_SIZE=${PHP_POST_MAX_SIZE:-72M}
export PHP_UPLOAD_MAX_FILESIZE=${PHP_UPLOAD_MAX_FILESIZE:-64M}
export PHP_MEMORY_LIMIT=${PHP_MEMORY_LIMIT:-512M}
export PHP_EXPOSE_PHP=${PHP_EXPOSE_PHP:-On}
export PHP_SESSION_GC_MAXLIFETIME=${PHP_SESSION_GC_MAXLIFETIME:-1440}
export PHP_OPCACHE_MEMORY_CONSUMPTION=${PHP_OPCACHE_MEMORY_CONSUMPTION:-256}

envsubst <"/var/data/default-php.tmpl.ini" >"/usr/local/etc/php/conf.d/wordpress.ini"
