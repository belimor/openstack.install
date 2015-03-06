#!/bin/bash

source openstack.config
source admin-openrc.sh

echo -e "\n\n\n"
echo "===============> Installing ZFS"
apt-add-repository --yes ppa:zfs-native/stable
apt-get update
apt-get install -y ubuntu-zfs
modprobe zfs
dmesg | grep ZFS
zpool create -f BOX raidz1 ${ZFS_DISKS}
zfs set compression=on BOX && zfs set atime=off BOX && zfs set exec=off BOX
zfs set xattr=sa BOX && zfs set dedup=on BOX
mkdir /BOX/glance
mkdir /BOX/cinder
mkdir /BOX/instances
touch /etc/modprobe.d/zfs.conf
echo "options zfs zfs_arc_max=536870912" >> /etc/modprobe.d/zfs.conf
zpool list
df -h

echo "===============> rebooting... (press ctr+c to stop)"
sleep 10

reboot

