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


echo "===============> Creating environment script admin-openrc.sh"
sleep 10
echo "export OS_TENANT_NAME=admin" > admin-openrc.sh
echo "export OS_USERNAME=admin" >> admin-openrc.sh
echo "export OS_PASSWORD=${ADMIN_PASS}" >> admin-openrc.sh
echo "export OS_AUTH_URL=http://${KEYSTONE_HOSTNAME}:35357/v2.0" >> admin-openrc.sh

echo "===============> Installing Glance"

mysql -u root -p${MYSQL_PWD} -e "CREATE DATABASE glance;"
mysql -u root -p${MYSQL_PWD} -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '${GLANCE_DBPASS}';"
mysql -u root -p${MYSQL_PWD} -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '${GLANCE_DBPASS}';"
source admin-openrc.sh
keystone user-create --name glance --pass ${GLANCE_PASS}
keystone user-role-add --user glance --tenant service --role admin
keystone service-create --name glance --type image --description "OpenStack Image Service"
keystone endpoint-create --service-id $(keystone service-list | awk '/ image / {print $2}') --publicurl http://${CONTROLLER_HOSTNAME}:9292 --internalurl http://${CONTROLLER_HOSTNAME}:9292 --adminurl http://${CONTROLLER_HOSTNAME}:9292 --region regionOne
apt-get install -y glance python-glanceclient

