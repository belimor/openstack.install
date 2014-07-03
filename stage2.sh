#!/bin/bash

# * VARIABLES
#
RABBIT_PWD=$(openssl rand -hex 12)
KEYSTONE_DBPASS=$(openssl rand -hex 12)
ADMIN_TOKEN=$(openssl rand -hex 12)
MY_HOSTNAME=$(hostname)
MYSQL_PWD=$(cat openstack_passwords.txt | grep mysql | awk '{print $3}')
### !!!! CHANGE PASSWORDS !!!! ###
ADMIN_PASS="password"
ADMIN_EMAIL="email@cybera.ca"
DEMO_PASS="password"
DEMO_EMAIL="email@cybera.ca"

echo "rabbit password: ${RABBIT_PWD}" >> openstack_passwords.txt
echo "keystone password: ${KEYSTONE_DBPASS}" >> openstack_passwords.txt
echo "ADMIN_TOKEN password: ${ADMIN_TOKEN}" >> openstack_passwords.txt
echo "ADMIN_PASS password: ${ADMIN_PASS}" >> openstack_passwords.txt
echo "ADMIN_EMAIL password: ${ADMIN_EMAIL}" >> openstack_passwords.txt
echo "DEMO_PASS password: ${DEMO_PASS}" >> openstack_passwords.txt
echo "DEMO_EMAIL password: ${DEMO_EMAIL}" >> openstack_passwords.txt
 
# rabbit message server installation
apt-get install -y rabbitmq-server
rabbitmqctl change_password guest ${RABBIT_PWD}
 
# keystone service installation
apt-get install -y keystone
sed -i '/connection = sqlite/d' /etc/keystone/keystone.conf
sed -i '/\[database\]/a connection = mysql://keystone:'"${KEYSTONE_DBPASS}"'@'"${MY_HOSTNAME}"'/keystone' /etc/keystone/keystone.conf
 
rm /var/lib/keystone/keystone.db
mysql -u root -p${MYSQL_PWD} -e "CREATE DATABASE keystone;"
mysql -u root -p${MYSQL_PWD} -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '${KEYSTONE_DBPASS}';"
mysql -u root -p${MYSQL_PWD} -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '${KEYSTONE_DBPASS}';"
 
/bin/sh -c "keystone-manage db_sync" keystone
sed -i '/admin_token=ADMIN/a log_dir = /var/log/keystone' /etc/keystone/keystone.conf
sed -i '/admin_token=ADMIN/a admin_token = '"${ADMIN_TOKEN}"'' /etc/keystone/keystone.conf
service keystone restart
 
(crontab -l -u keystone 2>&1 | grep -q token_flush) || echo '@hourly /usr/bin/keystone-manage token_flush >/var/log/keystone/keystone-tokenflush.log 2>&1' >> /var/spool/cron/crontabs/keystone
 
export OS_SERVICE_TOKEN="${ADMIN_TOKEN}"
export OS_SERVICE_ENDPOINT="http://${MY_HOSTNAME}:35357/v2.0"
sleep 5
keystone user-create --name=admin --pass=${ADMIN_PASS} --email=${ADMIN_EMAIL}
keystone role-create --name=admin
keystone tenant-create --name=admin --description="Admin Tenant"
keystone user-role-add --user=admin --tenant=admin --role=admin
keystone user-role-add --user=admin --role=_member_ --tenant=admin
 
keystone user-create --name=demo --pass=${DEMO_PASS} --email=${DEMO_EMAIL}
keystone tenant-create --name=demo --description="Demo Tenant"
keystone tenant-create --name=service --description="Service Tenant"
 
keystone service-create --name=keystone --type=identity --description="OpenStack Identity"
keystone endpoint-create --service-id=$(keystone service-list | awk '/ identity / {print $2}') --publicurl=http://${MY_HOSTNAME}:5000/v2.0 --internalurl=http://${MY_HOSTNAME}:5000/v2.0 --adminurl=http://${MY_HOSTNAME}:35357/v2.0

