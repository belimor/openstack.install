#!/bin/bash

apt-add-repository ppa:vbernat/haproxy-1.5
apt-get update
apt-get install haproxy

echo "ENABLED=1" > /etc/default/haproxy

# create certificate in cert+key in one file /etc/haproxy/haproxy

# vi /etc/haproxy/haproxy.cfg

# vi /etc/apache2/ports.conf - chagne listen port to 8088 f.exmpl


