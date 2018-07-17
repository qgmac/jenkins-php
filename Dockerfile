FROM jenkins
MAINTAINER Alex Vo <qgmac1@gmail.com>

# Jenkins is using jenkins user, we need root to install things.
USER root

RUN mkdir -p /tmp/WEB-INF/plugins
RUN apt-get upgrade
RUN apt-get update && apt-get install -y zip apt-utils


RUN curl -L https://updates.jenkins-ci.org/latest/docker-build-publish.hpi -o /tmp/WEB-INF/plugins/docker-build-publish.hpi

RUN apt-get -y -f install php5.6 php-dev php-curl php-mbstring  curl php-pear ant

# Install php xdebug extension for code coverage
# Setup the Xdebug version to install
ENV XDEBUG_VERSION 2.6.0
#ENV XDEBUG_MD5 60e6fdf41840104a23debe16db15a2af

# Install Xdebug
RUN set -x \
     && curl -SL "http://www.xdebug.org/files/xdebug-$XDEBUG_VERSION.tgz" -o xdebug.tgz \
     #&& echo $XDEBUG_MD5 xdebug.tgz | md5sum -c - \
     && mkdir -p /usr/src/xdebug \
     && tar -xf xdebug.tgz -C /usr/src/xdebug --strip-components=1 \
     && rm xdebug.* \
     && cd /usr/src/xdebug \
     && phpize \
     && ./configure \
     && make -j"$(nproc)" \
     && make install \
     && make clean

COPY ext-xdebug.ini /etc/php5/mods-available/
COPY ext-xdebug.ini /etc/php5/cli/conf.d/


# Create a jenkins "HOME" for composer files.
RUN mkdir /home/jenkins
RUN chown jenkins:jenkins /home/jenkins



USER jenkins


# Install composer, yes we can't install it in $JENKINS_HOME :(
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/home/jenkins

# Install required php tools.

RUN /home/jenkins/composer.phar --working-dir="/home/jenkins"  config -g repo.packagist composer.phar https://packagist.phpcomposer.com
RUN /home/jenkins/composer.phar --working-dir="/home/jenkins" -n require --dev  phpunit/phpunit:~5.0 squizlabs/php_codesniffer:3.* phploc/phploc  pdepend/pdepend:2.5.0   phpmd/phpmd:~2.6.0  sebastian/phpcpd theseer/phpdox


USER root
RUN apt-get clean -y

# Go back to jenkins user.
USER jenkins