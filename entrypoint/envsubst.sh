#!/bin/sh
set -e

# 3. PHP default settings (default-php.ini)
# 3.1 [PHP]
XMEMORY_LIMIT=512M
XEXPOSE_PHP=On
# 3.2 [Session]
XGC_MAXLIFETIME=1440

if [ -z "$PHP_MEMORY_LIMIT" ]; then export PHP_MEMORY_LIMIT=$XMEMORY_LIMIT; fi
if [ -z "$PHP_EXPOSE_PHP" ]; then export PHP_EXPOSE_PHP=$XEXPOSE_PHP; fi
if [ -z "$PHP_SESSION_GC_MAXLIFETIME" ]; then export PHP_SESSION_GC_MAXLIFETIME=$XGC_MAXLIFETIME; fi

envsubst <"/var/data/default-php.tmpl.ini" >"/usr/local/etc/php/conf.d/wordpress.ini"
