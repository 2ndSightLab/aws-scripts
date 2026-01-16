#!/usr/bin/env bash

# create wordpress and web server directories
sudo mkdir /wordpress
sudo mkdir -p cd /var/www/html
#sudo chmod -R 0777 /var/www/html

# Install Apache and autostart
sudo yum install httpd -y
sudo service httpd start
sudo chkconfig httpd on

# install nphp and mysql
sudo yum install php php-mysql -y

# restart web server
sudo service httpd restart

# MySQL in docker container
sudo cat > /docker-compose.yml <<EOF
version: '3.3'
services:
  db:
    image: mysql:5.7
    volumes:
      - db_data:/var/lib/mysql
    ports:
      - "3306:3306"
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: admin
      MYSQL_DATABASE: admin
      MYSQL_USER: admin
      MYSQL_PASSWORD: admin
volumes:
  db_data: 
EOF

cd /
docker-compose up -d

# Install Wordpress
cd /var/www/html
wget https://wordpress.org/wordpress-5.0.tar.gz
tar zxf wordpress-5.0.tar.gz
rm -rf wordpress-5.0.tar.gz

cd wordpress
cp -R * ../
cd ../

cat > /var/www/html/wp-config.php <<'EOF'
<?php
/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the
 * installation. You don't have to use the web site, you can
 * copy this file to "wp-config.php" and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * MySQL settings
 * * Secret keys
 * * Database table prefix
 * * ABSPATH
 *
 * @link https://codex.wordpress.org/Editing_wp-config.php
 *
 * @package WordPress
 */

define( 'WP_AUTO_UPDATE_CORE', false );

// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define('DB_NAME', 'wordpress');

/** MySQL database username */
define('DB_USER', 'wordpress');

/** MySQL database password */
define('DB_PASSWORD', 'wordpress');

/** MySQL hostname */
define('DB_HOST', '127.0.0.1');

/** Database Charset to use in creating database tables. */
define('DB_CHARSET', 'utf8');

/** The Database Collate type. Don't change this if in doubt. */
define('DB_COLLATE', '');

/**#@+
 * Authentication Unique Keys and Salts.
 *
 * Change these to different unique phrases!
 * You can generate these using the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}
 * You can change these at any point in time to invalidate all existing cookies. This will force all users to have to log in again.
 *
 * @since 2.6.0

define('AUTH_KEY',         ':{OBFYPwn}MBR8S$/54+/f4&C-&?F~8qT;|icI40:MMcL@5REde7=C+F8rE8 ]]t');
define('SECURE_AUTH_KEY',  'w:lm:nxiTV;UBT3n.M`@ 1l=G8f(m]_PBx@wZY]@3Bb%zdr81R!yToBUt(6WrPn)');
define('LOGGED_IN_KEY',    'bcJqC%[4L|d,+4+g+k5RJ)+oh2q>wsI(fk]`1SccTs,S-+ iAyOI/M$Gx N28:g0');
define('NONCE_KEY',        '9qrz9Xe9>|mM#WZLQBLX{/ZKAT:!0|H9^)TH$:Wc9$3_Iex#XEH!:0?S5_&O)e2a');
define('AUTH_SALT',        'i$9O|Z|C5^Jn+ C@qH6:rG4)+APlcmox^%~1i[o,D6BN(||Q >TUz.FC|tnE3J3C');
define('SECURE_AUTH_SALT', 'iv}:[-LeYs^b1Ch8pksLCn;Rk,s|a1Zag/t9O1-jmR+G$QH;:mUEE!=tg{Me$?ns');
define('LOGGED_IN_SALT',   '>mk:BB&iLFp?PBkTYfdi7LhOmoj|f2g.]7i3>nRJM-JI+ u)Y^Ha=,QYRT J5mY1');
define('NONCE_SALT',       ')k4!3rA8?w7dHudar><ohdx+@O&P!q+{6)@/)Cgo>S;LD#PqDr|BNU;<GkXTsXL-');
*/

/**#@-*/

/**
 * WordPress Database Table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
$table_prefix  = 'wp_';

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the Codex.
 *
 * @link https://codex.wordpress.org/Debugging_in_WordPress
 */
define('WP_DEBUG', false);

/* That's all, stop editing! Happy blogging. */

/** Absolute path to the WordPress directory. */
if ( !defined('ABSPATH') )
	define('ABSPATH', dirname(__FILE__) . '/');

/** Sets up WordPress vars and included files. */
require_once(ABSPATH . 'wp-settings.php');
EOF


# Download bad woocommerce
wget https://github.com/woocommerce/woocommerce/archive/3.4.6.zip
unzip 3.4.6.zip > /dev/null
sudo mv woocommerce-3.4.6 /var/www/html/wp-content/plugins/woocommerce
rm 3.4.6.zip

# Add new site url to wp-config
sudo cat > /wordpress/startup.sh <<EOF
#!/bin/sh
IP=\$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

ex -s -c "2i|define('WP_HOME','http://\$IP');" -c x /var/www/html/wp-config.php
ex -s -c "3i|define('WP_SITEURL','http://\$IP');" -c x /var/www/html/wp-config.php
EOF

sudo chmod +x /etc/rc.d/rc.local
sudo chmod +x /wordpress/startup.sh

echo "/wordpress/startup.sh" >> /etc/rc.d/rc.local
