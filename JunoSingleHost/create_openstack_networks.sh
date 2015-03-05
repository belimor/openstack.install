#!/bin/bash

source openstack.config
source admin-openrc.sh

sleep 2
nova network-create flat-net --bridge ${BRIDGE_FLAT} --multi-host T --fixed-range-v4 ${OPENSTACK_INTERNAL_NETWORK}
#nova-manage floating create --pool nova --ip_range ${PUBLIC_NETWORK}
