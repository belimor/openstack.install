#!/bin/bash

echo -e "\n"
echo "===============> Configuring NFS shares"
echo -e "\n"

source openstack.config

apt-get install -y nfs-kernel-server

sed "s/MANAGEMETN_NETWORK_IP/${MANAGEMETN_NETWORK_IP}/g;s/CONTROLLER_HOSTNAME/${CONTROLLER_HOSTNAME}/g" ./exports > /etc/exports

exportfs -a
service nfs-kernel-server start

cp nfsshares /etc/cinder/nfsshares
chown root:cinder /etc/cinder/nfsshares
chmod 0640 /etc/cinder/nfsshares

# vi /etc/cinder/cinder.conf
mkdir /BOX/cinder.mount

service cinder-scheduler restart
service cinder-api restart
service tgt restart
service cinder-volume restart

echo -e "\n"
echo "===============> rebooting... (press ctr+c to stop)"
echo -e "\n"
