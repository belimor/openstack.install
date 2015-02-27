#!/bin/bash

MYSQL_PWD="password"
RABBIT_PASS="password"
MANAGEMETN_NETWORK_IP="172.22.1.162"

echo "===============> Installing MySQL server"
debconf-set-selections <<< "mysql-server mysql-server/root_password password ${MYSQL_PWD}"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password ${MYSQL_PWD}"
apt-get install -y mysql-server python-mysqldb

SECURE_MYSQL=$(expect -c "
set timeout 10
spawn mysql_secure_installation
expect \"Enter current password for root (enter for none):\"
send \"${MYSQL_PWD}\r\"
expect \"Change the root password?\"
send \"n\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"y\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
")
echo "$SECURE_MYSQL"

echo "===============> Configurin MySQL server"
sed "s/MANAGEMETN_NETWORK_IP/${MANAGEMETN_NETWORK_IP}/g" ./my.cnf > /etc/mysql/my.cnf

echo "===============> Installing RabbitMQ"
apt-get install -y rabbitmq-server
rabbitmqctl change_password guest $RABBIT_PASS
#https://www.rabbitmq.com/man/rabbitmqctl.1.man.html
#http://docs.openstack.org/juno/install-guide/install/apt/content/ch_basic_environment.html#basics-messaging-server
service rabbitmq-server restart
