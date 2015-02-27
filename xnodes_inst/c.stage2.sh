#!/bin/bash

controller="192.168.1.1"
my_ip="192.168.1.2"
NOVA_DBPASS="$(cat openstack_passwords.txt | grep dbnova | awk '{print $3}')"
NOVA_PASS="$(cat openstack_passwords.txt | grep nova | awk '{print $3}')"
RABBIT_PASS="$(cat openstack_passwords.txt | grep rabbit | awk '{print $3}')"

apt-get install -y nova-compute-kvm 
#python-guestfs
dpkg-statoverride  --update --add root root 0644 /boot/vmlinuz-$(uname -r)

echo "#!/bin/sh" > /etc/kernel/postinst.d/statoverride
echo "version="$1"" >> /etc/kernel/postinst.d/statoverride
echo "# passing the kernel version is required" >> /etc/kernel/postinst.d/statoverride
echo "[ -z "${version}" ] && exit 0" >> /etc/kernel/postinst.d/statoverride
echo "dpkg-statoverride --update --add root root 0644 /boot/vmlinuz-${version}" >> /etc/kernel/postinst.d/statoverride
chmod +x /etc/kernel/postinst.d/statoverride

crudini --set /etc/nova/nova.conf DEFAULT auth_strategy keystone
crudini --set /etc/nova/nova.conf DEFAULT rpc_backend rabbit
crudini --set /etc/nova/nova.conf DEFAULT rabbit_host ${controller}
crudini --set /etc/nova/nova.conf DEFAULT rabbit_password ${RABBIT_PASS}
crudini --set /etc/nova/nova.conf DEFAULT my_ip ${my_ip}
crudini --set /etc/nova/nova.conf DEFAULT vnc_enabled True
crudini --set /etc/nova/nova.conf DEFAULT vncserver_listen 0.0.0.0
crudini --set /etc/nova/nova.conf DEFAULT vncserver_proxyclient_address ${my_ip}
crudini --set /etc/nova/nova.conf DEFAULT novncproxy_base_url http://${controller}:6080/vnc_auto.html
crudini --set /etc/nova/nova.conf DEFAULT glance_host ${controller}

crudini --set /etc/nova/nova.conf database connection mysql://nova:${NOVA_DBPASS}@${controller}/nova

crudini --set /etc/nova/nova.conf keystone_authtoken auth_uri http://${controller}:5000
crudini --set /etc/nova/nova.conf keystone_authtoken auth_host ${controller}
crudini --set /etc/nova/nova.conf keystone_authtoken auth_port 35357
crudini --set /etc/nova/nova.conf keystone_authtoken auth_protocol http
crudini --set /etc/nova/nova.conf keystone_authtoken admin_tenant_name service
crudini --set /etc/nova/nova.conf keystone_authtoken admin_user nova
crudini --set /etc/nova/nova.conf keystone_authtoken admin_password ${NOVA_PASS}

rm /var/lib/nova/nova.sqlite
service nova-compute restart

