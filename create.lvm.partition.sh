#!/bin/bash

source openstack.config

echo "===============> Configuring LVM partition"
sleep 5

#echo -e "o\nn\np\n1\n\n\nw" | fdisk /dev/sdb
echo -e "n\np\n1\n\n\nw" | fdisk /dev/${CINDER_DEVICE}

apt-get install -y lvm2
pvcreate /dev/${CINDER_DEVICE}1
vgcreate cinder-volumes /dev/${CINDER_DEVICE}1
sed -i 's/[ "a/.*/" ]/[ "a/${CINDER_DEVICE}/", "r/.*/"]/g' etc/lvm/lvm.conf

echo "===============> rebooting... (press ctr+c to stop)"
sleep 10
