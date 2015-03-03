#!/bin/bash

apt-get install -y ntp wget curl expect ubuntu-cloud-keyring
echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu" "trusty-updates/juno main" > /etc/apt/sources.list.d/cloudarchive-juno.list
apt-get update && apt-get dist-upgrade -y
reboot
