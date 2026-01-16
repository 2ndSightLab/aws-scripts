#!/usr/bin/env bash

# Setup docker compose file
sudo mkdir -p /wordpress/{wp-content,config}
sudo chmod -R 0777 /wordpress

sudo cat > /wordpress/docker-compose.yml <<EOF
version: '3.3'

services:
  db:
    image: mysql:5.7
    volumes:
      - db_data:/var/lib/mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: somewordpress
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wordpress

  wordpress:
    depends_on:
      - db
    image: wordpress:5.1.1-php7.3-apache
    ports:
      - "80:80"
    restart: always
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: wordpress
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - wordpress:/var/www/html
volumes:
  db_data: 
  wordpress: 
EOF

cd /wordpress
docker-compose up -d

# Download bad woocommerce
wget https://github.com/woocommerce/woocommerce/archive/3.4.6.zip
unzip 3.4.6.zip > /dev/null
sudo mv woocommerce-3.4.6 /var/lib/docker/volumes/wordpress_wordpress/_data/wp-content/plugins/woocommerce
rm 3.4.6.zip


# Add new site url to wp-config
sudo cat > /wordpress/startup.sh <<EOF
#!/bin/sh
IP=\$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

ex -s -c "2i|define('WP_HOME','http://\$IP');" -c x /var/lib/docker/volumes/wordpress_wordpress/_data/wp-config.php
ex -s -c "3i|define('WP_SITEURL','http://\$IP');" -c x /var/lib/docker/volumes/wordpress_wordpress/_data/wp-config.php
ex -s -c "3i|define('WP_AUTO_UPDATE_CORE',false);" -c x /var/lib/docker/volumes/wordpress_wordpress/_data/wp-config.php
EOF

sudo chmod +x /etc/rc.d/rc.local
sudo chmod +x /wordpress/startup.sh

echo "/wordpress/startup.sh" >> /etc/rc.d/rc.local
