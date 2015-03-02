#!/bin/bash

MYSQL_PWD="password"
RABBIT_PASS="password"
KEYSTONE_DBPASS="password"
MANAGEMETN_NETWORK_IP="10.0.0.127"
KEYSTONE_HOSTNAME="myubuntu"
CONTROLLER_HOSTNAME="myubuntu"
SECRETE_ADMIN_TOKEN="password"
ADMIN_PASS="password"
EMAIL_ADDRESS="my@email.com"
GLANCE_DBPASS="password"
GLANCE_PASS="password"

echo "===============> Installing MySQL server"
sleep 5
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
sleep 10
apt-get install -y rabbitmq-server
rabbitmqctl change_password guest $RABBIT_PASS
#https://www.rabbitmq.com/man/rabbitmqctl.1.man.html
#http://docs.openstack.org/juno/install-guide/install/apt/content/ch_basic_environment.html#basics-messaging-server
service rabbitmq-server restart


echo "===============> Installing Keystone"
sleep 10
mysql -u root -p${MYSQL_PWD} -e "CREATE DATABASE keystone;"
mysql -u root -p${MYSQL_PWD} -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '${KEYSTONE_DBPASS}';"
mysql -u root -p${MYSQL_PWD} -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '${KEYSTONE_DBPASS}';"
apt-get install -y keystone python-keystoneclient
sed "s/SECRETE_ADMIN_TOKEN/${SECRETE_ADMIN_TOKEN}/g;s/KEYSTONE_HOSTNAME/${CONTROLLER_HOSTNAME}/g;s/KEYSTONE_DBPASS/${KEYSTONE_DBPASS}/g" ./keystone.conf > /etc/keystone/keystone.conf
su -s /bin/sh -c "keystone-manage db_sync" keystone
rm -f /var/lib/keystone/keystone.db
service keystone restart
(crontab -l -u keystone 2>&1 | grep -q token_flush) || echo '@hourly /usr/bin/keystone-manage token_flush >/var/log/keystone/keystone-tokenflush.log 2>&1' >> /var/spool/cron/crontabs/keystone

export OS_SERVICE_TOKEN=${SECRETE_ADMIN_TOKEN}
export OS_SERVICE_ENDPOINT=http://${CONTROLLER_HOSTNAME}:35357/v2.0
sleep 5
keystone tenant-create --name admin --description "Admin Tenant"
keystone user-create --name admin --pass ${ADMIN_PASS} --email ${EMAIL_ADDRESS}
keystone role-create --name admin
keystone user-role-add --user admin --tenant admin --role admin
keystone tenant-create --name service --description "Service Tenant"
keystone service-create --name keystone --type identity --description "OpenStack Identity"
keystone endpoint-create --service-id $(keystone service-list | awk '/ identity / {print $2}') --publicurl http://${CONTROLLER_HOSTNAME}:5000/v2.0 --internalurl http://${CONTROLLER_HOSTNAME}:5000/v2.0 --adminurl http://${CONTROLLER_HOSTNAME}:35357/v2.0 --region regionOne
unset OS_SERVICE_TOKEN 
unset OS_SERVICE_ENDPOINT

echo "===============> Keystone Verification"
sleep 10
keystone --os-tenant-name admin --os-username admin --os-password ${ADMIN_PASS} --os-auth-url http://${CONTROLLER_HOSTNAME}:35357/v2.0 token-get
keystone --os-tenant-name admin --os-username admin --os-password ${ADMIN_PASS} --os-auth-url http://${CONTROLLER_HOSTNAME}:35357/v2.0 tenant-list
keystone --os-tenant-name admin --os-username admin --os-password ${ADMIN_PASS} --os-auth-url http://${CONTROLLER_HOSTNAME}:35357/v2.0 user-list
keystone --os-tenant-name admin --os-username admin --os-password ${ADMIN_PASS} --os-auth-url http://${CONTROLLER_HOSTNAME}:35357/v2.0 role-list

echo "===============> Creating environment script admin-openrc.sh"
sleep 10
echo "export OS_TENANT_NAME=admin" > admin-openrc.sh
echo "export OS_USERNAME=admin" >> admin-openrc.sh
echo "export OS_PASSWORD=${ADMIN_PASS}" >> admin-openrc.sh
echo "export OS_AUTH_URL=http://${KEYSTONE_HOSTNAME}:35357/v2.0" >> admin-openrc.sh

echo "===============> Installing Glance"
apt-get install -y glance python-glanceclient

mysql -u root -p${MYSQL_PWD} -e "CREATE DATABASE glance;"
mysql -u root -p${MYSQL_PWD} -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '${GLANCE_DBPASS}';"
mysql -u root -p${MYSQL_PWD} -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '${GLANCE_DBPASS}';"
source admin-openrc.sh
keystone user-create --name glance --pass ${GLANCE_PASS}
keystone user-role-add --user glance --tenant service --role admin
keystone service-create --name glance --type image --description "OpenStack Image Service"
keystone endpoint-create --service-id $(keystone service-list | awk '/ image / {print $2}') --publicurl http://${CONTROLLER_HOSTNAME}:9292 --internalurl http://${CONTROLLER_HOSTNAME}:9292 --adminurl http://${CONTROLLER_HOSTNAME}:9292 --region regionOne

sed "s/GLANCE_DBPASS/${GLANCE_DBPASS}/g;s/CONTROLLER_HOSTNAME/${CONTROLLER_HOSTNAME}/g;s/GLANCE_PASS/${GLANCE_PASS}/g" ./glance-api.conf > /etc/glance/glance-api.conf
sed "s/GLANCE_DBPASS/${GLANCE_DBPASS}/g;s/CONTROLLER_HOSTNAME/${CONTROLLER_HOSTNAME}/g;s/GLANCE_PASS/${GLANCE_PASS}/g" ./glance-registry.conf > /etc/glance/glance-registry.conf

su -s /bin/sh -c "glance-manage db_sync" glance
rm -f /var/lib/glance/glance.sqlite
service glance-registry restart
service glance-api restart

echo "===============> Keystone Verification"
sleep 10
mkdir /tmp/images
wget -P /tmp/images http://cdn.download.cirros-cloud.net/0.3.3/cirros-0.3.3-x86_64-disk.img
glance image-create --name "cirros-0.3.3-x86_64" --file /tmp/images/cirros-0.3.3-x86_64-disk.img --disk-format qcow2 --container-format bare --is-public True --progress
glance image-list
rm -r /tmp/images




