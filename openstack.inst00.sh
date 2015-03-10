#!/bin/bash

source ./openstack.config

echo "===============> Configuring /etc/hosts"
sleep 10

echo " " >> /etc/hosts
echo 127.0.0.1 ${CONTROLLER_HOSTNAME}.${CONTROLLER_DOMAIN_NAME} ${CONTROLLER_HOSTNAME} >> /etc/hosts
echo ${MANAGEMETN_NETWORK_IP} ${CONTROLLER_HOSTNAME}.${CONTROLLER_DOMAIN_NAME} ${CONTROLLER_HOSTNAME} >> /etc/hosts
sed -i 's/127.0.1.1/#127.0.1.1/g' /etc/hosts

echo "===============> Configuring Bridge"
sleep 10

apt-get install -y bridge-utils

sed -i 's/iface eth0 inet dhcp/iface eth0 inet manual/g' /etc/network/interfaces

cat >> /etc/network/interfaces <<EOF

auto br100
iface br100 inet dhcp
  bridge_ports eth0

auto br111
iface br111 inet static
  bridge_ports eth0
  address ${OPENSTACK_INTERNAL_NETWORK_GW}
  netmask ${OPENSTACK_INTERNAL_NETMASK}
EOF

echo "===============> Configuring LVM partition"
sleep 10

#echo -e "o\nn\np\n1\n\n\nw" | fdisk /dev/sdb
echo -e "n\np\n1\n\n\nw" | fdisk /dev/${CINDER_DEVICE}

apt-get install -y lvm2
pvcreate /dev/${CINDER_DEVICE}1
vgcreate cinder-volumes /dev/${CINDER_DEVICE}1
sed -i 's/[ "a/.*/" ]/[ "a/${CINDER_DEVICE}/", "r/.*/"]/g' etc/lvm/lvm.conf

echo "===============> Configuring Juno Repository"
sleep 10

apt-get install -y ntp wget curl expect ubuntu-cloud-keyring
echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu" "trusty-updates/juno main" > /etc/apt/sources.list.d/cloudarchive-juno.list
apt-get update && apt-get dist-upgrade -y

echo "===============> rebooting... (press ctr+c to stop)"
sleep 10

reboot

