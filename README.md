openstack.install
=================

OpenStack installation bash scripts

Juno Installation Doc:
http://docs.openstack.org/juno/install-guide/install/apt/content/ch_preface.html

Network Configuration:

      +------------------------------+
      |                              |
      |   OpenStack Host             |
      |                              |
      |      VM0        VM1          |
      |   +-------+  +-------+       |
      |   |       |  |       |       |
      |   | vnet0 |  | vnet1 |       |
      |   |       |  |       |       |
      |   +---+---+  +---+---+       |
      |       |          |           |
      |   +---+----------+--------+  |
   +----+--++ br111                 |  |
    |       || VM Network            |  |
     |       ++-----------------------+  |
      | eth0  |                           |
 |       ++-----------------------+  |
 |       || br100                 |  |
 +----+--++ Local/Public Network  |  |
      |   +-----------------------+  |
      |                              |
      +------------------------------+
 
HDD:
/dev/sda
/dev/sdb
