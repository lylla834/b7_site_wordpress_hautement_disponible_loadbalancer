#!/bin/bash
echo "Install Lamp stack with bash"
sudo apt update && apt upgrade

#installation apache et php
sudo apt install apache2 -y
apache2 -v
sudo systemctl status apache2
echo "Install apache2 web server"


sudo apt install mariadb-client
echo "Install mariadb"

sudo apt install php php-mysql
php -v
echo "Install php"

vim /var/www/html/info.php
<?php
phpinfo();
?>

[echo "création base de donnée wordpress"
$ mysql -u root -p
CREATE DATABASE wordpress_db;
CREATE USER 'wp_user'@'localhost' IDENTIFIED BY 'password';
GRANT ALL ON wordpress_db.* TO 'wp_user'@'localhost' IDENTIFIED BY 'password';
FLUSH PRIVILEGES;
Exit;]

cd /tmp && wget https://wordpress.org/latest.tar.gz
tar -xvf latest.tar.gz
cp -R wordpress /var/www/html/
chown -R www-data:www-data /var/www/html/wordpress/
chmod -R 755 /var/www/html/wordpress/
$ mkdir /var/www/html/wordpress/wp-content/uploads
chown -R www-data:www-data /var/www/html/wordpress/wp-content/uploads/