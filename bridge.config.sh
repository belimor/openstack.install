#!/bin/bash

source openstack.config

echo -e "\n"
echo "===============> Configuring Bridge"
sleep 5
echo -e "\n"

apt-get install -y bridge-utils

sed -i 's/iface eth0 inet dhcp/iface eth0 inet manual/g' /etc/network/interfaces

cat >> /etc/network/interfaces <<EOF

auto br100
iface br100 inet dhcp
  bridge_ports eth0

auto br111
iface br111 inet manual
  bridge_ports eth0
EOF

echo -e "\n"
echo "===============> rebooting... (press ctr+c to stop)"
sleep 10
echo -e "\n"

reboot
