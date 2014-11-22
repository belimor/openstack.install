#!/bin/bash

# Set up acng client
#echo "Acquire::http { Proxy \"http://acng-yyc.cloud.cybera.ca:3142\"; };"  > /etc/apt/apt.conf.d/01-acng

# Set up proper hostname
echo 127.0.1.1 $(hostname).cybera.ca $(hostname) >> /etc/hosts

# Installing curl and wget
apt-get update
apt-get install -y curl wget

cd /root
wget https://apt.puppetlabs.com/puppetlabs-release-trusty.deb
dpkg -i puppetlabs-release-trusty.deb
rm puppetlabs-release-trusty.deb
apt-get update

echo "Installing Git & Puppet"
apt-get install -y git puppet=3.6.2-1puppetlabs1 puppet-common=3.6.2-1puppetlabs1

mkdir -p /etc/facter/facts.d

echo "Initial changes to puppet.conf"
sed -i '/templatedir/d' /etc/puppet/puppet.conf
puppet config set --section main parser future
puppet config set --section main evaluator current
puppet config set --section main ordering manifest

echo "Starting Puppet Master to generate certs"
puppet master --verbose
sleep 5
echo "Killing Puppet Master"
pkill -9 puppet

echo "Installing PuppetDB"
cd /etc/puppet/modules
puppet module install puppetlabs/puppetdb
cd /root
echo include puppetdb > pdb.pp
echo include puppetdb::master::config >> pdb.pp
puppet apply --verbose pdb.pp
echo "===> sleep 5"
sleep 5
echo "===========>"
puppet apply --verbose pdb.pp

rm -rf /etc/puppet/modules/*
rm /root/pdb.pp

echo "Setting up Directory Environments"
PROD="/etc/puppet"
SITE="${PROD}/modules/site"
#puppet config set --section main environmentpath \$confdir/environments
#mkdir -p $PROD/{modules,manifests}
mkdir $PROD/modules/site
mkdir -p $SITE/{files,templates,manifests,ext,data}
mkdir -p $SITE/manifests/{roles,profiles}

mv /etc/puppet/puppet.conf $SITE/ext
ln -s $SITE/ext/puppet.conf /etc/puppet/

#echo "Installing r10k"
#gem install deep_merge
#gem install r10k
### ??? ###

echo "Configuring Hiera"
cat > $SITE/ext/hiera.yaml <<EOF
---
:backends:
  - yaml

:hierarchy:
  - "nodes/%{::fqdn}"
  - "osfamily/%{::osfamily}"
  - "locations/%{::location}"
  - "common"

:yaml:
  :datadir: "/etc/puppet/modules/site/data"
EOF

mkdir $SITE/data/nodes
mkdir $SITE/data/locations

ln -s $SITE/ext/hiera.yaml /etc/puppet
rm /etc/hiera.yaml
ln -s $SITE/ext/hiera.yaml /etc/

echo "Creating a module script"
cat > $SITE/ext/modules.sh <<EOF

cd $PROD/modules

git clone https://github.com/puppetlabs/puppetlabs-apache apache
cd apache
git checkout tags/1.2.0
cd ..

git clone https://github.com/puppetlabs/puppetlabs-apt apt
cd apt
git checkout tags/1.5.0
cd ..

git clone https://github.com/puppetlabs/puppetlabs-vcsrepo vcsrepo
cd vcsrepo
git checkout tags/1.0.0
cd ..

git clone https://github.com/puppetlabs/puppetlabs-concat concat
cd concat
git checkout tags/1.1.0
cd ..

git clone https://github.com/puppetlabs/puppetlabs-firewall firewall
cd firewall
git checkout tags/1.1.3
cd ..

git clone https://github.com/puppetlabs/puppetlabs-ntp ntp
cd ntp
git checkout tags/3.1.0
cd ..

git clone https://github.com/puppetlabs/puppetlabs-puppetdb puppetdb
cd puppetdb
git checkout tags/3.0.1
cd ..

git clone https://github.com/puppetlabs/puppetlabs-postgresql postgresql
cd postgresql
git checkout tags/3.3.3
cd ..

git clone https://github.com/puppetlabs/puppetlabs-stdlib stdlib
cd stdlib
git checkout tags/4.2.2
cd ..

git clone https://github.com/puppetlabs/puppetlabs-inifile inifile
cd inifile
git checkout tags/1.0.4
cd ..

git clone https://github.com/jtopjian/puppet-puppet puppet

EOF
ln -s $SITE/ext/modules.sh $PROD

echo "Downloading the modules"
cd $PROD
bash modules.sh

echo "Configuring the Puppet Master"

cat > $SITE/manifests/roles/base.pp <<EOF
class site::roles::base {
}
EOF

mkdir -p $SITE/manifests/roles/puppet

cat > $SITE/manifests/roles/puppet/master.pp <<EOF
class site::roles::puppet::master {
  include ::apache
  include ::apache::mod::ssl
  include ::apache::mod::passenger
  include ::puppet
  include ::puppet::master
  include ::puppetdb
  include ::puppetdb::master::config
}
EOF

fqdn=$(facter fqdn)
cat > $SITE/data/common.yaml <<EOF
puppet::settings:
  server: '${fqdn}'
  parser: 'future'
  evaluator: 'current'
  ordering: 'manifest'
  pluginsync: true
  logdir: '/var/log/puppet'
  vardir: '/var/lib/puppet'
  ssldir: '/var/lib/puppet/ssl'
  rundir: '/var/run/puppet'
puppet::agent::settings:
  certname: "%{::fqdn}"
  show_diff: true
  splay: false
  configtimeout: 360
  usecacheonfailure: true
  report: true
EOF

cat > $SITE/data/nodes/${fqdn}.yaml <<EOF
puppet::master::servertype: 'passenger'
puppet::master::settings:
  ca: true
EOF

cat > $SITE/ext/site.pp <<EOF
node base {
  include site::roles::base
}

node '${fqdn}' {
  include site::roles::base
  include site::roles::puppet::master
}
EOF
ln -s $SITE/ext/site.pp $PROD/manifests/

echo "===> puppet apply --verbose /etc/puppet/manifests/site.pp"
puppet apply --verbose /etc/puppet/manifests/site.pp
