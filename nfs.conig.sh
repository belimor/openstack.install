#!/bin/bash

apt-get install -y nfs-kernel-server

# vi /etc/exports
exportfs -a
service nfs-kernel-server start
touch /etc/cinder/nfsshares
chown root:cinder /etc/cinder/nfsshares

# vi nfsshares
chmod 0640 /etc/cinder/nfsshares

# vi /etc/cinder/cinder.conf

service cinder-scheduler restart
service cinder-api restart
service tgt restart
service cinder-volume restart

# mkdir /BOX/cindermnt

