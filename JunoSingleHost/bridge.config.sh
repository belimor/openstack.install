#!/bin/bash

source openstack.config

sed -i 's/iface eth0 inet dhcp/iface eth0 inet manual/g' /etc/network/interfaces

cat >> /etc/network/interfaces <<EOF

auto br100
iface br100 inet dhcp
  bridge_ports eth0

auto br111
iface br111 inet static
  bridge_ports eth0
  address ${OPENSTACK_INTERNAL_NETWORKIP}
  netmask ${OPENSTACK_INTERNAL_NETMASK}
EOF
