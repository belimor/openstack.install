#!/bin/bash

echo 1 > /proc/sys/net/ipv6/conf/all/forwarding
echo 0 > /proc/sys/net/ipv6/conf/all/accept_ra

nova network-create v6public --fixed-range-v6 1:::/64

# nova.conf => use_ipv6 = True
