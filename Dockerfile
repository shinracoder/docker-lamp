FROM debian:stretch
MAINTAINER Peter Alber Atkins "peter.atkins85@gmail.com"

ARG PHPVERSION=7.1
ARG	PHPCONF=/etc/php/7.1

RUN apt-get update
RUN apt-get install apt-transport-https lsb-release ca-certificates -y
RUN apt-get install wget -y
RUN wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
RUN sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'

RUN apt-get update && \
	apt-get -q --yes --force-yes install php${PHPVERSION}-xml php${PHPVERSION}-memcache php${PHPVERSION}-mysql php${PHPVERSION}-zip php${PHPVERSION}-redis php${PHPVERSION} php${PHPVERSION}-cli php${PHPVERSION}-curl curl git apache2 libapache2-mod-php${PHPVERSION} php${PHPVERSION}-gd imagemagick php${PHPVERSION}-imagick php${PHPVERSION}-intl php${PHPVERSION}-mcrypt php${PHPVERSION}-xdebug php${PHPVERSION}-apcu memcached php${PHPVERSION}-memcached

RUN apt-get install apache2 -y
RUN cd /etc/php/7.1/apache2/
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
	php /usr/local/bin/composer self-update

##Apache
RUN a2enmod rewrite && \
	a2dissite 000-default && \
	usermod  -u 1000 www-data && \
	groupmod -g 1000 www-data && \
	usermod -s /bin/bash www-data

##PHP date.timezone
RUN echo "date.timezone = UTC" >> ${PHPCONF}/cli/php.ini && \
	echo "date.timezone = UTC" >> ${PHPCONF}/apache2/php.ini

##in start.sh with conf on name and port
RUN sed -i 's/session.save_handler = files/session.save_handler = redis/g' ${PHPCONF}/apache2/php.ini &&\
	echo 'session.save_path = tcp://redis:6379' >> ${PHPCONF}/apache2/php.ini

RUN phpenmod xdebug

COPY start.sh /start.sh
RUN chmod +x /start.sh

WORKDIR /var/www

EXPOSE 80

CMD /start.sh
