#!/bin/bash

apt-get install -y glance python-glanceclient

echo "==== Stage 3 ==========" >> openstack_passwords.txt
GLANCE_DBPASS=$(openssl rand -hex 12)
echo "dbglance password: ${GLANCE_DBPASS}" >> openstack_passwords.txt
GLANCE_PASS=$(openssl rand -hex 12)
echo "glance password: ${GLANCE_PASS}" >> openstack_passwords.txt

RABBIT_PASS=$(cat openstack_passwords.txt | grep rabbit | awk '{print $3}')
MYSQL_PWD=$(cat openstack_passwords.txt | grep mysql | awk '{print $3}')
GLANCE_EMAIL="13@cybera.ca"
echo "glance emai: ${GLANCE_EMAIL}" >> openstack_passwords.txt

ADMIN_PASS=$(cat openstack_passwords.txt | grep ADMIN_PASS | awk '{print $3}')

sed -i '/connection = <None>/a connection = mysql://glance:'"${GLANCE_DBPASS}"'@'"$(hostname)"'/glance' /etc/glance/glance-api.conf
sed -i '/rabbit_host = localhost/a rpc_backend = rabbit' /etc/glance/glance-api.conf
sed -i 's/rabbit_host = localhost/rabbit_host = '"$(hostname)"'/' /etc/glance/glance-api.conf
sed -i 's/rabbit_password = guest/rabbit_password = '"${RABBIT_PASS}"'/' /etc/glance/glance-api.conf
sed -i '/\[keystone_authtoken\]/a auth_uri = http://'"$(hostname)"':5000' /etc/glance/glance-api.conf
sed -i 's/auth_host = 127.0.0.1/auth_host = '"$(hostname)"'/' /etc/glance/glance-api.conf
sed -i 's/admin_tenant_name = %SERVICE_TENANT_NAME%/admin_tenant_name = service/' /etc/glance/glance-api.conf
sed -i 's/admin_user = %SERVICE_USER%/admin_user = glance/' /etc/glance/glance-api.conf
sed -i 's/admin_password = %SERVICE_PASSWORD%/admin_password = '"${GLANCE_PASS}"'/' /etc/glance/glance-api.conf
sed -i '/flavor=/a flavor = keystone' /etc/glance/glance-api.conf

sed -i '/connection = <None>/a connection = mysql://glance:'"${GLANCE_DBPASS}"'@'"$(hostname)"'/glance' /etc/glance/glance-registry.conf
sed -i '/\[keystone_authtoken\]/a auth_uri = http://'"$(hostname)"':5000' /etc/glance/glance-registry.conf
sed -i 's/auth_host = 127.0.0.1/auth_host = '"$(hostname)"'/' /etc/glance/glance-registry.conf
sed -i 's/admin_tenant_name = %SERVICE_TENANT_NAME%/admin_tenant_name = service/' /etc/glance/glance-registry.conf
sed -i 's/admin_user = %SERVICE_USER%/admin_user = glance/' /etc/glance/glance-registry.conf
sed -i 's/admin_password = %SERVICE_PASSWORD%/admin_password = '"${GLANCE_PASS}"'/' /etc/glance/glance-registry.conf
sed -i '/flavor=/a flavor = keystone' /etc/glance/glance-registry.conf

rm /var/lib/glance/glance.sqlite
mysql -u root -p${MYSQL_PWD} -e "CREATE DATABASE glance;"
mysql -u root -p${MYSQL_PWD} -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '${GLANCE_DBPASS}';"
mysql -u root -p${MYSQL_PWD} -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '${GLANCE_DBPASS}';"

export OS_USERNAME="admin"
export OS_PASSWORD="${ADMIN_PASS}"
export OS_TENANT_NAME="admin"
export OS_AUTH_URL="http://$(hostname):35357/v2.0"
sleep 5

/bin/sh -c "glance-manage db_sync" glance
keystone user-create --name=glance --pass=${GLANCE_PASS} --email=${GLANCE_EMAIL}
keystone user-role-add --user=glance --tenant=service --role=admin

keystone service-create --name=glance --type=image --description="OpenStack Image Service"
keystone endpoint-create --service-id=$(keystone service-list | awk '/ image / {print $2}') --publicurl=http://$(hostname):9292 --internalurl=http://$(hostname):9292 --adminurl=http://$(hostname):9292

sleep 10

service glance-registry restart
service glance-api restart

 
