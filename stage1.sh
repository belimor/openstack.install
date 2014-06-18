#!/bin/bash
 
apt-get update
apt-get install -y ntp
 
# generate mysql password
MYSQL_PWD=$(openssl rand -hex 12)
echo "mysql password: ${MYSQL_PWD}" > openstack_passwords.txt
 
# install mysql server
debconf-set-selections <<< "mysql-server mysql-server/root_password password ${MYSQL_PWD}"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password ${MYSQL_PWD}"
apt-get install -y python-mysqldb mysql-server
 
# scpecify controller IP address 
controller_ip=$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
 
# edit /etc/mysql/my.cnf
sed -i 's/127.0.0.1/'"$(hostname)"'/' /etc/mysql/my.cnf
sed -i '/\[mysqld\]/a character-set-server = utf8' /etc/mysql/my.cnf
sed -i '/\[mysqld\]/a init-connect = '"'"'SET NAMES utf8'"'"'' /etc/mysql/my.cnf
sed -i '/\[mysqld\]/a collation-server = utf8_general_ci' /etc/mysql/my.cnf
sed -i '/\[mysqld\]/a innodb_file_per_table' /etc/mysql/my.cnf
sed -i '/\[mysqld\]/a default-storage-engine = innodb' /etc/mysql/my.cnf
 
service mysql restart
 
# run mysql_secure_installation script
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
 
# install openstack packages
apt-get install -y python-software-properties
apt-get update
apt-get dist-upgrade -y
reboot

