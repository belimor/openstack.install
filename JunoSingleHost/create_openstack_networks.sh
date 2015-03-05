#!/bina/bash

source openstack.config

nova network-create flat-net --bridge ${BRIDGE_FLAT} --multi-host T --fixed-range-v4 ${OPENSTACK_INTERNAL_NETWORK}
nova-manage floating create --pool nova --ip_range ${PUBLIC_NETWORK}
