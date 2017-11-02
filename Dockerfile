FROM php:7.1-apache

# install the PHP extensions we need
RUN set -ex; \
	\
	apt-get update; \
	apt-get install -y \
		libjpeg-dev \
		libpng-dev \
		libbz2-dev \
		zlib1g-dev \
		unzip \
	; \
	rm -rf /var/lib/apt/lists/*; \
	\
	docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr; \
	docker-php-ext-install gd mysqli opcache
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

ENV WORDPRESS_VERSION 4.8.3
ENV WORDPRESS_SHA1 8efc0b9f6146e143ed419b5419d7bb8400a696fc
ENV WOOCOMMERCE_VERSION 3.2.3
ENV STOREFRONT_VERSION 2.2.5

RUN set -ex; \
	curl -o wordpress.tar.gz -fSL "https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz"; \
	echo "$WORDPRESS_SHA1 *wordpress.tar.gz" | sha1sum -c -; \
# upstream tarballs include ./wordpress/ so this gives us /usr/src/wordpress
	tar -xzf wordpress.tar.gz -C /usr/src/; \
	rm wordpress.tar.gz; \
# Add WooCommerce plugin to the current container
	curl -o woocommerce.tar.gz -fSL "https://github.com/woocommerce/woocommerce/archive/${WOOCOMMERCE_VERSION}.tar.gz"; \
	tar -xzf woocommerce.tar.gz -C /usr/src/wordpress/wp-content/plugins/; \
	rm woocommerce.tar.gz; \
# Add Storefront plugin
	curl -o storefront.zip -fSL "https://github.com/woocommerce/storefront/releases/download/version%2F${STOREFRONT_VERSION}/storefront.zip"; \
	unzip storefront.zip -C /usr/src/wordpress/wp-content/themes/; \
	rm storefront.zip; \
	chown -R www-data:www-data /usr/src/wordpress;

COPY docker-entrypoint.sh /usr/local/bin/

RUN chmod 777 /usr/local/bin/docker-entrypoint.sh \
    && ln -s /usr/local/bin/docker-entrypoint.sh /

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]