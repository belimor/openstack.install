#!/bin/bash

echo -e "\n"
echo "===============> Configuring /etc/hosts"
sleep 5
echo -e "\n"

source ./openstack.config
echo " " >> /etc/hosts
echo 127.0.0.1 ${CONTROLLER_HOSTNAME}.${CONTROLLER_DOMAIN_NAME} ${CONTROLLER_HOSTNAME} >> /etc/hosts
echo ${MANAGEMETN_NETWORK_IP} ${CONTROLLER_HOSTNAME}.${CONTROLLER_DOMAIN_NAME} ${CONTROLLER_HOSTNAME} >> /etc/hosts
sed -i 's/127.0.1.1/#127.0.1.1/g' /etc/hosts
cat /etc/hosts

echo -e "\n"
echo "===============> Adding Openstack Juno repository. System upgrade"
sleep 5
echo -e "\n"

apt-get install -y ntp wget curl expect ubuntu-cloud-keyring
echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu" "trusty-updates/juno main" > /etc/apt/sources.list.d/cloudarchive-juno.list
apt-get update && apt-get dist-upgrade -y

echo -e "\n"
echo "===============> Rebboting"
sleep 5
echo -e "\n"
reboot
