#!/bin/bash

source openstack.config

CINDER_DEVICE="sdb"

#echo -e "o\nn\np\n1\n\n\nw" | fdisk /dev/sdb
echo -e "n\np\n1\n\n\nw" | fdisk /dev/sdb
