openstack.install
=================

OpenStack installation bash scripts

Juno Installation Doc:
http://docs.openstack.org/juno/install-guide/install/apt/content/ch_preface.html

Network Configuration:

             +-----------------------------+                              
             |                             |                              
             |   OpenStack Host            |                              
             |                             |                              
             |      VM0        VM1         |                              
             |   +-------+  +-------+      |                              
             |   |       |  |       |      |                              
             |   | vnet0 |  | vnet1 |      |                              
             |   |       |  |       |      |                              
             |   +---+---+  +---+---+      |                              
             |       |          |          |     +----------+ +----------+
             |   +---+----------+--------+ |     |          | |          |
        +----+--++ br111  VMNetwork      | |     | /dev/sda | | /dev/sdb |
        |       || 192.168.254.0/24      | |     |          | |          |
        |       ++-----------------------+ |     | HDD1     | | HDD2     |
        | eth0  |                          |     |          | |          |
        |       ++-----------------------+ |     |          | |          |
        |       || br100                 | |     |          | |          |
        +----+--++ Local/Public Network  | |     |          | |          |
             |   +-----------------------+ |     |          | |          |
             |                             |     |          | |          |
             +-----------------------------+     +----------+ +----------+


1. Edit openstac.config
2. run ./openstack.inst00.sh
3. rebbot
4. run ./ openstack.inst01.sh
5. run ./create.openstack.networks.sh 
6. create Floating IP pool: nova-manage floating create --pool nova --ip_range 10.0.1.0/24 (replace with your IP range)
7. open browser: http://you.ip/horizon


