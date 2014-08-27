#!/bin/bash
 
# scpecify controller IP address 
controller_ip=$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
controller_name=$(hostname)
 
sed -i '/127.0.1.1/d' /etc/hosts
domain="cybera.ca" 
 
echo "" >> /etc/hosts
echo "${controller_ip} ${controller_name} ${controller_name}.${domain}" >> /etc/hosts
echo "/etc/hosts has been updated..."
 
