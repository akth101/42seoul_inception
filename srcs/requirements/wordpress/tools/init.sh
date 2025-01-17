#!/bin/bash

INIT_FLAG="/var/www/html/initialization_done.flag"

setup_wordpress_files() {
    echo "[WordPress] Creating PHP directory..."
    mkdir -p /run/php

    echo "[WordPress] Setting permissions for PHP and web directories..."
    chown www-data:www-data /run/php6
    chown -R www-data:www-data /var/www/html

    echo "[WordPress] Copying WordPress files to /var/www/html..."
    cp -r wordpress/* /var/www/html
    rm -rf wordpress

    echo "[WordPress] Configuring wp-config.php..."
    mv /var/www/html/wp-config-sample.php wp-config.php
    sed -i "s/database_name_here/$DB_NAME/" wp-config.php
    sed -i "s/username_here/$DB_USER/" wp-config.php
    sed -i "s/password_here/$DB_PASSWORD/" wp-config.php
    sed -i "s/localhost/$DB_HOST/" wp-config.php

    echo "[WordPress] Moving config file to web root..."
    mv wp-config.php /var/www/html
}

check_mariadb_connection() {
   MAX_TRY=10
   TRY=0
   while ! mysqladmin -h $DB_HOST -u $DB_USER -p$DB_PASSWORD ping ; do
       TRY=$((TRY+1))
       sleep 1
       if [ $TRY -eq $MAX_TRY ]; then
           break
       fi
   done
}

wait_for_mariadb() {
    echo "[WordPress] waiting for mariadb connection..."
    check_mariadb_connection
    sleep 5;
    check_mariadb_connection
    echo "[WordPress] Database connection established."
}

install_wordpress() {
   echo "[WordPress] installing wordpress..."
   cd /var/www/html
   wp core install --url="$URL" --title="$TITLE" --admin_user="$ADMIN_ID" --admin_password="$ADMIN_PASSWORD" --admin_email="$ADMIN_EMAIL" --skip-email --locale=ko_KR --allow-root
   wp user create $USER_ID $USER_EMAIL --role=author --user_pass=$USER_PASSWORD --allow-root
   wp config shuffle-salts --allow-root
   touch "$INIT_FLAG"
}

main() {
    echo "[WordPress] Starting initialization..."
    setup_wordpress_files
    wait_for_mariadb
    install_wordpress
    echo "[WordPress] initialization completed."
}

main
exec "$@"