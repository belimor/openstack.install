#!/bin/bash
###############
# OpenStack Installation Script
# Part 5 
# Install nova-compute-kvm
# 

function counter {
echo " " && echo " " && echo "#############" && echo "$1" && echo "#############"
echo " Press Ctrl+C if you want to cancel"
echo -ne '[.     ]\r' && sleep 1 && echo -ne '[..    ]\r' && sleep 1
echo -ne '[...   ]\r' && sleep 1 && echo -ne '[....  ]\r' && sleep 1
echo -ne '[..... ]\r' && sleep 1 && echo -ne '[......]\r' && sleep 1
echo -ne '\n'
}

#########################
# VARIABLES DECLARATION #
#########################
controller=$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
my_ip=$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
NOVA_DBPASS="$(cat openstack_passwords.txt | grep dbnova | awk '{print $3}')"
NOVA_PASS="$(cat openstack_passwords.txt | grep nova | awk '{print $3}')"
RABBIT_PASS="$(cat openstack_passwords.txt | grep rabbit | awk '{print $3}')"

counter "Passwords have been generated. Next -> nova-compute-kvm installation"
#########################
#   nova installation   #
#########################
apt-get install -y crudini
apt-get install -y nova-compute-kvm
dpkg-statoverride  --update --add root root 0644 /boot/vmlinuz-$(uname -r)

echo "#!/bin/sh" > /etc/kernel/postinst.d/statoverride
echo "version="$1"" >> /etc/kernel/postinst.d/statoverride
echo "# passing the kernel version is required" >> /etc/kernel/postinst.d/statoverride
echo "[ -z "${version}" ] && exit 0" >> /etc/kernel/postinst.d/statoverride
echo "dpkg-statoverride --update --add root root 0644 /boot/vmlinuz-${version}" >> /etc/kernel/postinst.d/statoverride
chmod +x /etc/kernel/postinst.d/statoverride


counter "nova-compute-kvm has been installed. Next -> update nova.conf"
#########################
#   nova.conf update    #
#########################
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

