#!/bin/bash

source openstack.config

CINDER_DEVICE="sdb"

#echo -e "o\nn\np\n1\n\n\nw" | fdisk /dev/sdb
echo -e "n\np\n1\n\n\nw" | fdisk /dev/sdb

apt-get install -y lvm2
pvcreate /dev/sdb1
vgcreate cinder-volumes /dev/sdb1
sed -i 's/[ "a/.*/" ]/[ "a/sdb/", "r/.*/"]/g' etc/lvm/lvm.conf
