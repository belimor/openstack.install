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

function ini_has_option() {
    local file=$1
    local section=$2
    local option=$3
    local line
    line=$(sed -ne "/^\[$section\]/,/^\[.*\]/ { /^$option[ \t]*=/ p; }" "$file")
    [ -n "$line" ]
}

function iniset() {
    local file=$1
    local section=$2
    local option=$3
    local value=$4
 
    [[ -z $section || -z $option ]] && return
 
    if ! grep -q "^\[$section\]" "$file" 2>/dev/null; then
        # Add section at the end
        echo -e "\n[$section]" >>"$file"
    fi
    if ! ini_has_option "$file" "$section" "$option"; then
        # Add it
        sed -i -e "/^\[$section\]/ a\\
$option = $value
" "$file"
    else
        local sep=$(echo -ne "\x01")
        # Replace it
        sed -i -e '/^\['${section}'\]/,/^\[.*\]/ s'${sep}'^\('${option}'[ \t]*=[ \t]*\).*$'${sep}'\1'"${value}"${sep} "$file"
    fi
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
counter "Ntp has been installed. Next -> Mysql server installation"
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
iniset /etc/mysql/my.cnf mysqld bind-address ${CTRL_MGT_IP}
iniset /etc/mysql/my.cnf mysqld character-set-server 'utf8'
iniset /etc/mysql/my.cnf mysqld init-connect 'SET NAMES utf8'
iniset /etc/mysql/my.cnf mysqld collation-server 'utf8_general_ci'
iniset /etc/mysql/my.cnf mysqld innodb_file_per_table
iniset /etc/mysql/my.cnf mysqld default-storage-engine 'innodb'
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

