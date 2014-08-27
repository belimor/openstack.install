#!/bin/bash
 
# scpecify controller IP address 
controller_ip=$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
 
controller_name=$(hostname)
 
sed -i '/127.0.1.1/d' /etc/hosts
 
domain="cybera.ca" 
#echo "Enter domain name: "
#read domain
#echo "Enter controller hostname: "
#read controller_name
#echo "Enter controller IPv4: "
#read controller_ip
 
#echo "Enter computenode hostname: "
#read computenode_name
#echo "Enter computenode IPv4: "
#read computenode_ip
 
#echo "Enter DNS IP address: "
#read dns_ip
#echo "Enter netmask: "
#read netmask
#echo "Enter gateway: "
#read gateway
 
echo "" >> /etc/hosts
echo "${controller_ip} ${controller_name} ${controller_name}.${domain}" >> /etc/hosts
#echo "${computenode_ip} ${computenode_name} ${computenode_name}.${domain}" >> /etc/hosts
echo "/etc/hosts has been updated..."
 
#sed -i 's/dhcp/static/' /etc/network/interfaces.d/eth0.cfg
#echo "  address ${controller_ip}" >> /etc/network/interfaces.d/eth0.cfg
#echo "  netmask ${netmask}" >> /etc/network/interfaces.d/eth0.cfg
#echo "  gateway ${gateway}" >> /etc/network/interfaces.d/eth0.cfg
#echo "  dns-nameserver ${dns_ip}" >> /etc/network/interfaces.d/eth0.cfg
#echo "/etc/network/interfaces.d/eth0.cfg has been updated..."
 
#reboot
