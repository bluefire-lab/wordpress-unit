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

RUN mkdir -p /opt/tools

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
  tar -xzf wordpress.tar.gz -C /opt/tools/; \
  rm wordpress.tar.gz; \
  chown -R ${USER}:${GROUP} /opt/tools/wordpress;

COPY --chown=${USER}:${GROUP} wp-config-docker.php /opt/tools/wordpress/wp-config.php
COPY --chown=root:root ./entrypoint/* /docker-entrypoint.d/
COPY --chown=root:root ./php.tmpl.ini /var/data/default-php.tmpl.ini
COPY --chown=root:root ./wordpress-entrypoint.sh /usr/local/bin/wordpress-entrypoint.sh

WORKDIR /opt/wordpress

RUN chmod +x /docker-entrypoint.d/*
RUN chmod +x /usr/local/bin/wordpress-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/wordpress-entrypoint.sh"]
CMD ["unitd", "--no-daemon", "--control", "unix:/var/run/control.unit.sock"]