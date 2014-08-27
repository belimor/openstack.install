#!/bin/bash
###############
# OpenStack Installation Script
# Part 1 
# Install ntp, mysql-server, python-software-properties. Upgrade and reboot
#

function counter {
echo " " && echo " " && echo "#############" && echo "$1" && echo "#############"
echo " Press Ctrl+C if you want to cansel"
echo -ne '[.     ]\r' && sleep 1 && echo -ne '[..    ]\r' && sleep 1 
echo -ne '[...   ]\r' && sleep 1 && echo -ne '[....  ]\r' && sleep 1
echo -ne '[..... ]\r' && sleep 1 && echo -ne '[......]\r' && sleep 1
echo -ne '\n'
}

#########################
# VARIABLES DECLARATION #
#########################
MYSQL_PWD=$(openssl rand -hex 12)
CTRL_PUB_IP=$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
echo "controller public.ip.address ${CTRL_PUB_IP}" > openstack_passwords.txt
echo "mysql password: ${MYSQL_PWD}" >> openstack_passwords.txt
#############################
# update system install ntp #
#############################
apt-get update
apt-get upgrade
apt-get install -y ntp
counter "System has been updated. Ntp has been installed. Next -> Mysql server installation"
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
cp my.cnf /etc/mysql/my.cnf
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
apt-get purge -y expect
counter "mysql_secure_installation script has been completed. Next -> python-software-properties"
###################################### 
# install python-software-properties #
######################################
apt-get install -y python-software-properties

echo "end of stage1"
