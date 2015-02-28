#!/bin/bash

MYSQL_PWD="password"
RABBIT_PASS="password"
KEYSTONE_DBPASS="password"
MANAGEMETN_NETWORK_IP="172.22.1.162"
KEYSTONE_HOSTNAME="myubuntu"
SECRETE_ADMIN_TOKEN="password"

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
sed "s/MANAGEMETN_NETWORK_IP/${MANAGEMETN_NETWORK_IP}/g" ./my.cnf > /etc/mysql/my.cnf


echo "===============> Installing RabbitMQ"
apt-get install -y rabbitmq-server
rabbitmqctl change_password guest $RABBIT_PASS
#https://www.rabbitmq.com/man/rabbitmqctl.1.man.html
#http://docs.openstack.org/juno/install-guide/install/apt/content/ch_basic_environment.html#basics-messaging-server
service rabbitmq-server restart


echo "===============> Installing Keystone"
mysql -u root -p${MYSQL_PWD} -e "CREATE DATABASE keystone;"
mysql -u root -p${MYSQL_PWD} -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '${KEYSTONE_DBPASS}';"
mysql -u root -p${MYSQL_PWD} -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '${KEYSTONE_DBPASS}';"
apt-get install -y keystone python-keystoneclient
sed "s/SECRETE_ADMIN_TOKEN/${SECRETE_ADMIN_TOKEN}/g;s/KEYSTONE_HOSTNAME/${KEYSTONE_HOSTNAME}/g;s/KEYSTONE_DBPASS/${KEYSTONE_DBPASS}/g" ./keystone.conf > /etc/keystone/keystone.conf
su -s /bin/sh -c "keystone-manage db_sync" keystone
rm -f /var/lib/keystone/keystone.db
service keystone restart
(crontab -l -u keystone 2>&1 | grep -q token_flush) || echo '@hourly /usr/bin/keystone-manage token_flush >/var/log/keystone/keystone-tokenflush.log 2>&1' >> /var/spool/cron/crontabs/keystone

export OS_SERVICE_TOKEN=${SECRETE_ADMIN_TOKEN}
export OS_SERVICE_ENDPOINT=http://${KEYSTONE_HOSTNAME}:35357/v2.0
keystone tenant-create --name admin --description "Admin Tenant"
keystone user-create --name admin --pass ${ADMIN_PASS} --email ${EMAIL_ADDRESS}
keystone role-create --name admin
keystone user-role-add --user admin --tenant admin --role admin
keystone tenant-create --name service --description "Service Tenant"
keystone service-create --name keystone --type identity --description "OpenStack Identity"
keystone endpoint-create --service-id $(keystone service-list | awk '/ identity / {print $2}') --publicurl http://controller:5000/v2.0 --internalurl http://controller:5000/v2.0 --adminurl http://controller:35357/v2.0 --region regionOne




