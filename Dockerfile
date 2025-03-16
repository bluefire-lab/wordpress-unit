FROM unit:1.34.2-php8.3

ARG USER="wpuser"
ARG GROUP="wpgroup"

ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

RUN set -ex \
  && apt-get update \
  && apt-get install --no-install-recommends --no-install-suggests -y gettext vim curl zip mariadb-client less htop procps \
  && apt-get purge -y --auto-remove \
  && rm -rf /var/lib/apt/lists/*

RUN chmod +x /usr/local/bin/install-php-extensions && \
  install-php-extensions igbinary \
  gd \
  redis \
  gettext \
  gmp \
  bcmath \
  bz2 \
  exif \
  imagick \
  intl \
  mysqli \
  pdo_mysql \
  opcache \
  soap \
  xsl \
  zip

RUN set -eux \
  # Fix php.ini settings for enabled extensions
  && chmod +x "$(php -r 'echo ini_get("extension_dir");')"/* \
  # Shrink binaries
  && (find /usr/local/bin -type f -print0 | xargs -n1 -0 strip --strip-all -p 2>/dev/null || true) \
  && (find /usr/local/lib -type f -print0 | xargs -n1 -0 strip --strip-all -p 2>/dev/null || true) \
  && (find /usr/local/sbin -type f -print0 | xargs -n1 -0 strip --strip-all -p 2>/dev/null || true) \
  && true

# Install Composer
RUN install-php-extensions @composer

# Install wpcli
RUN curl -o /bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
RUN chmod 755 /bin/wp

RUN mkdir -p /opt/

WORKDIR /opt/

# Create a new user and group to run the worker application
RUN useradd -M ${USER} && groupadd ${GROUP} && usermod -L ${USER} && usermod -a -G ${GROUP} ${USER} && usermod -a -G ${GROUP} unit

RUN set -eux; \
  version='6.7.2'; \
  sha1='ff727df89b694749e91e357dc2329fac620b3906'; \
  \
  curl -o wordpress.tar.gz -fL "https://wordpress.org/wordpress-$version.tar.gz"; \
  echo "$sha1 *wordpress.tar.gz" | sha1sum -c -; \
  \
  # upstream tarballs include ./wordpress/ so this gives us /usr/src/wordpress
  tar -xzf wordpress.tar.gz -C /opt/; \
  rm wordpress.tar.gz; \
  \
  chown -R ${USER}:${GROUP} /opt/wordpress; \
  # pre-create wp-content (and single-level children) for folks who want to bind-mount themes, etc so permissions are pre-created properly instead of root:root
  # wp-content/cache: https://github.com/docker-library/wordpress/issues/534#issuecomment-705733507
  mkdir wp-content; \
  for dir in /opt/wordpress/wp-content/*/ cache; do \
  dir="$(basename "${dir%/}")"; \
  mkdir "wp-content/$dir"; \
  done; \
  chown -R ${USER}:${GROUP} wp-content; \
  chmod -R 1755 wp-content

COPY --chown=${USER}:${GROUP} wp-config-docker.php /opt/wordpress/wp-config.php
COPY --chown=unit:unit ./entrypoint/* /docker-entrypoint.d/
COPY --chown=root:root ./php.tmpl.ini /var/data/default-php.tmpl.ini

RUN chmod +x /docker-entrypoint.d/*