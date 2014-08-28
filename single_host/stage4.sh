#!/bin/bash

apt-get install -y nova-api nova-cert nova-conductor nova-consoleauth nova-novncproxy nova-scheduler python-novaclient

RABBIT_PASS=$(cat openstack_passwords.txt | grep rabbit | awk '{print $3}')
NOVA_DBPASS=$(openssl rand -hex 12)
NOVA_PASS=$(openssl rand -hex 12)
MYSQL_PWD=$(cat openstack_passwords.txt | grep mysql | awk '{print $3}')
NOVA_EMAIL="email@cybera.ca"
ADMIN_PASS=$(cat openstack_passwords.txt | grep ADMIN_PASS | awk '{print $3}')
#MGT_IP=$(cat openstack_passwords.txt | grep management.ip.address | awk '{print $3}')
MGT_IP="10.1.0.218"

echo "==== Stage 4 ==========" >> openstack_passwords.txt
echo "dbnova password: ${NOVA_DBPASS}" >> openstack_passwords.txt
echo "nova password: ${NOVA_PASS}" >> openstack_passwords.txt

export OS_USERNAME="admin"
export OS_PASSWORD="${ADMIN_PASS}"
export OS_TENANT_NAME="admin"
export OS_AUTH_URL="http://$(hostname):35357/v2.0"
sleep 5

echo ""
echo "### === script === ###" >> /etc/nova/nova.conf
echo ""
echo "network_api_class = nova.network.api.API" >> /etc/nova/nova.conf
echo "security_group_api = nova" >> /etc/nova/nova.conf
echo ""
echo "rpc_backend = rabbit" >> /etc/nova/nova.conf
echo "rabbit_host = $(hostname)" >> /etc/nova/nova.conf
echo "rabbit_password = ${RABBIT_PASS}" >> /etc/nova/nova.conf
echo "" >> /etc/nova/nova.conf
echo "my_ip = ${MGT_IP}" >> /etc/nova/nova.conf
echo "vncserver_listen = $(hostname)" >> /etc/nova/nova.conf
echo "vncserver_proxyclient_address = $(hostname)" >> /etc/nova/nova.conf
echo "" >> /etc/nova/nova.conf
echo "auth_strategy = keystone" >> /etc/nova/nova.conf
echo "" >> /etc/nova/nova.conf
echo "[database]" >> /etc/nova/nova.conf
echo "connection = mysql://nova:${NOVA_DBPASS}@$(hostname)/nova" >> /etc/nova/nova.conf
echo "" >> /etc/nova/nova.conf
echo "[keystone_authtoken]" >> /etc/nova/nova.conf
echo "auth_uri = http://$(hostname):5000" >> /etc/nova/nova.conf
echo "auth_host = $(hostname)" >> /etc/nova/nova.conf
echo "auth_port = 35357" >> /etc/nova/nova.conf
echo "auth_protocol = http" >> /etc/nova/nova.conf
echo "admin_tenant_name = service" >> /etc/nova/nova.conf
echo "admin_user = nova" >> /etc/nova/nova.conf
echo "admin_password = ${NOVA_PASS}" >> /etc/nova/nova.conf

rm /var/lib/nova/nova.sqlite

mysql -u root -p${MYSQL_PWD} -e "CREATE DATABASE nova;"
mysql -u root -p${MYSQL_PWD} -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY '${NOVA_DBPASS}';"
mysql -u root -p${MYSQL_PWD} -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY '${NOVA_DBPASS}';"

/bin/sh -c "nova-manage db sync" nova

keystone user-create --name=nova --pass=${NOVA_PASS} --email=i${NOVA_EMAIL}
keystone user-role-add --user=nova --tenant=service --role=admin

keystone service-create --name=nova --type=compute --description="OpenStack Compute"
keystone endpoint-create --service-id=$(keystone service-list | awk '/ compute / {print $2}') --publicurl=http://$(hostname):8774/v2/%\(tenant_id\)s --internalurl=http://$(hostname):8774/v2/%\(tenant_id\)s --adminurl=http://$(hostname):8774/v2/%\(tenant_id\)s

service nova-api restart
service nova-cert restart
service nova-consoleauth restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart

nova image-list

