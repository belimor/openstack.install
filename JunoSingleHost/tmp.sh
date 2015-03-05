#!/bin/bash

source ./openstack.config
source ./admin-openrc.sh

echo "===============> Installing Cinder"
sleep 10
apt-get install -y cinder-api cinder-scheduler python-cinderclient
mysql -u root -p${MYSQL_PWD} -e "CREATE DATABASE cinder;"
mysql -u root -p${MYSQL_PWD} -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY '${CINDER_DBPASS}';"
mysql -u root -p${MYSQL_PWD} -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY '${CINDER_DBPASS}';"

keystone user-create --name cinder --pass ${CINDER_PASS}
keystone user-role-add --user cinder --tenant service --role admin
keystone service-create --name cinder --type volume --description "OpenStack Block Storage"
keystone service-create --name cinderv2 --type volumev2 --description "OpenStack Block Storage"

keystone endpoint-create --service-id $(keystone service-list | awk '/ volume / {print $2}') --publicurl http://${CONTROLLER_HOSTNAME}:8776/v1/%\(tenant_id\)s --internalurl http://${CONTROLLER_HOSTNAME}:8776/v1/%\(tenant_id\)s --adminurl http://${CONTROLLER_HOSTNAME}:8776/v1/%\(tenant_id\)s --region regionOne
keystone endpoint-create --service-id $(keystone service-list | awk '/ volumev2 / {print $2}') --publicurl http://${CONTROLLER_HOSTNAME}:8776/v2/%\(tenant_id\)s --internalurl http://${CONTROLLER_HOSTNAME}:8776/v2/%\(tenant_id\)s --adminurl http://${CONTROLLER_HOSTNAME}:8776/v2/%\(tenant_id\)s --region regionOne

