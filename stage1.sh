#!/bin/bash
###############
# OpenStack Installation Script
# Part 1 
# Install ntp, crudini, mysql-server, openstack packages. Upgrade and reboot
#

function counter {
echo "$1"
echo " Press Ctrl+C if you want to cansel"
echo -ne '[.   ]\r' && sleep 1 && echo -ne '[..  ]\r' && sleep 1 
echo -ne '[... ]\r' && sleep 1 && echo -ne '[....]\r' && sleep 1
echo -ne '\n'
}

#########################
# VARIABLES DECLARATION #
#########################
MYSQL_PWD=$(openssl rand -hex 12)
CTRL_MGT_IP=$(/sbin/ifconfig eth1 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
CTRL_PUB_IP=$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
echo "controller public.ip.address ${CTRL_PUB_IP}" > openstack_passwords.txt
echo "controller management.ip.address ${CTRL_MGT_IP}" >> openstack_passwords.txt
echo "mysql password: ${MYSQL_PWD}" >> openstack_passwords.txt

apt-get update
apt-get install -y ntp
apt-get install -y crudini
counter "Ntp and Crudini have been installed. Next -> Mysql server installation"
######################## 
# install mysql server #
########################
debconf-set-selections <<< "mysql-server mysql-server/root_password password ${MYSQL_PWD}"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password ${MYSQL_PWD}"
apt-get install -y python-mysqldb mysql-server
counter "Mysql server has been installed. Next -> Updating /etc/mysql/my.cnf"
##########################
# edit /etc/mysql/my.cnf #
##########################
crudini --set /etc/mysql/my.cnf mysqld bind ${CONTROLLER_IP}
crudini --set /etc/mysql/my.cnf mysqld character-set-server 'utf8'
crudini --set /etc/mysql/my.cnf mysqld init-connect 'SET NAMES utf8'
crudini --set /etc/mysql/my.cnf mysqld collation-server 'utf8_general_ci'
crudini --set /etc/mysql/my.cnf mysqld innodb_file_per_table
crudini --set /etc/mysql/my.cnf mysqld default-storage-engine 'innodb'
service mysql restart
counter "/etc/mysql/my.cnf has been updated. Next -> mysql_secure_installation script"
######################################## 
# run mysql_secure_installation script #
########################################
apt-get install -y expect
SECURE_MYSQL=$(expect -c "
set timeout 10
spawn mysql_secure_installation
expect \"Enter current password for root (enter for none):\"
send \"${MYSQL_PWD}\r\"
expect \"Change the root password?\"
send \"n\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"y\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
")
echo "$SECURE_MYSQL"
apt-get purge expect
counter "mysql_secure_installation script has been completed. Next -> python-software-properties and system upgrade"
###################################### 
# install python-software-properties #
######################################
apt-get install -y python-software-properties
apt-get update
apt-get dist-upgrade -y
counter "Rebooting the system"
reboot

