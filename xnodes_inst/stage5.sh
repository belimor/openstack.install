#!/bin/bash

apt-get install -y apache2 memcached libapache2-mod-wsgi openstack-dashboard
apt-get purge -y openstack-dashboard-ubuntu-theme

service apache2 restart
service memcached restart

