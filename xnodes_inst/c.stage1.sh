#!/bin/bash

apt-get update
apt-get install -y ntp
apt-get install -y python-mysqldb
apt-get install -y python-software-properties
apt-get install -y crudini
apt-get update
apt-get dist-upgrade -y
reboot
