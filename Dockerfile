FROM php:7.1-apache

# install the PHP extensions we need
RUN set -ex; \
	\
	apt-get update; \
	apt-get install -y \
		libjpeg-dev \
		libpng-dev \
	; \
	rm -rf /var/lib/apt/lists/*; \
	\
	docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr; \
	docker-php-ext-install gd mysqli opcache
# install unzip
RUN apt-get update \
	&& apt-get install -y \
	libbz2-dev \
	zlib1g-dev \
	&& docker-php-ext-install \
		zip \
		bz2
# TODO consider removing the *-dev deps and only keeping the necessary lib* packages

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=2'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN a2enmod rewrite expires

VOLUME /var/www/html

ENV WORDPRESS_VERSION 4.8.2
ENV WORDPRESS_SHA1 a99115b3b6d6d7a1eb6c5617d4e8e704ed50f450
ENV WOOCOMMERCE_URL https://github.com/woocommerce/woocommerce/archive/3.2.2.tar.gz
ENV STOREFRONT_URL https://github.com/woocommerce/storefront/archive/version/2.2.5.tar.gz

RUN set -ex; \
	curl -o wordpress.tar.gz -fSL "https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz"; \
	echo "$WORDPRESS_SHA1 *wordpress.tar.gz" | sha1sum -c -; \
# upstream tarballs include ./wordpress/ so this gives us /usr/src/wordpress
	tar -xzf wordpress.tar.gz -C /usr/src/; \
	rm wordpress.tar.gz; \
# Add WooCommerce plugin to the current container
	curl -o woocommerce.tar.gz -fSL "${WOOCOMMERCE_URL}"; \
	tar -xzf woocommerce.tar.gz -C /usr/src/wordpress/wp-content/plugins/; \
	rm woocommerce.tar.gz; \
# Add Storefront plugin
	curl -o storefront.tar.gz -fSL "${STOREFRONT_URL}"; \
	tar -xzf storefront.tar.gz -C /usr/src/wordpress/wp-content/themes/; \
	rm storefront.tar.gz; \
	chown -R www-data:www-data /usr/src/wordpress;

COPY docker-entrypoint.sh /usr/local/bin/

RUN chmod 777 /usr/local/bin/docker-entrypoint.sh \
    && ln -s /usr/local/bin/docker-entrypoint.sh /

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]